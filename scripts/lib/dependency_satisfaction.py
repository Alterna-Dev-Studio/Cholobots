#!/usr/bin/env python3
# ABOUTME: Decides whether an out-of-run epic dependency is satisfied: Done, or merged into the base branch.
# ABOUTME: Used by /implement-epic Step 2a-bis; claims are read with taiga-sync's own parser.
"""Out-of-run dependency satisfaction for /implement-epic.

A prerequisite outside the run is satisfied when its code is already in the
run's base branch. Taiga ``Done`` says so, but a merged story can stay at
Ready for review / Ready for test (no ``mark-done-on-merge``, or ``## Gate``
human tasks still open). So a dependency is satisfied when:

1. its story is ``Done``; or
2. at least one *merged* PR into the base branch claims it, and no *open* PR
   (into any base) still claims it.

It is never satisfied when the story is ``Archived``, cannot be found, or a
lookup fails; the reason is reported. "Claims" uses
``scripts/taiga_closing_refs.py``, the parser ``taiga-sync.yml`` runs, so a
bare ``#ref`` mention in prose never counts.

CLI::

    python3 scripts/lib/dependency_satisfaction.py [--base <branch>] [<ref>...]

prints ``{"satisfied_refs": [...], "dependencies": {"<ref>": {...}}}``.
``--base`` defaults to ``$BASE_BRANCH``, then ``main``.
"""
import argparse
import json
import os
import re
import subprocess
import sys

LIB_DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR = os.path.dirname(LIB_DIR)
REPO_ROOT = os.path.dirname(SCRIPTS_DIR)
sys.path.insert(0, SCRIPTS_DIR)

from taiga_closing_refs import extract_closing_refs  # noqa: E402

GH_REPO = os.environ.get("GH_REPO", "MrsBohemian/Cholobots")
PROJECT_ID = 39
TAIGA_NOT_FOUND_EXIT = 44
PR_LIST_LIMIT = 1000
GATE_HEADING = re.compile(r"^##\s+Gate\b", re.MULTILINE)


class LookupFailed(Exception):
    """A Taiga or GitHub lookup failed; the dependency counts as not satisfied."""


def claimed_refs(pr):
    """Taiga refs a PR claims, by the same rules as taiga-sync.yml."""
    return extract_closing_refs(pr.get("headRefName", ""), pr.get("title", ""), pr.get("body", ""))


def _status_name(story):
    info = story.get("status_extra_info") or {}
    return info.get("name") or str(story.get("status", "unknown"))


def _open_tasks(story):
    tasks = []
    for t in story.get("tasks") or []:
        info = t.get("status_extra_info") or {}
        if not info.get("is_closed", t.get("is_closed", False)):
            tasks.append({"id": t.get("id"), "ref": t.get("ref"), "subject": t.get("subject", "")})
    return tasks


def classify_dependency(ref, story, prs, base_branch="main", story_error=None, prs_error=None):
    """Classify one out-of-run dependency.

    ``story`` is the ``scripts/taiga-story.sh <ref> 39 --with-tasks`` JSON, or
    None with ``story_error`` set. ``prs`` is the ``gh pr list --state all``
    JSON list, or None with ``prs_error`` set. Returns a dict with
    ``satisfied``, ``via`` ("done" | "merged" | None), ``reason``, ``status``,
    ``merged_prs``, ``open_prs`` and ``open_tasks``.
    """
    result = {
        "ref": ref,
        "satisfied": False,
        "via": None,
        "reason": "",
        "status": None,
        "merged_prs": [],
        "open_prs": [],
        "open_tasks": [],
    }

    if story is None:
        result["reason"] = f"Taiga lookup failed: {story_error or 'no story returned'}"
        return result

    status = _status_name(story)
    result["status"] = status
    result["open_tasks"] = _open_tasks(story)

    if status == "Archived":
        result["reason"] = "story is Archived"
        return result

    if status == "Done":
        result["satisfied"] = True
        result["via"] = "done"
        result["reason"] = "story is Done"
        return result

    if prs is None:
        result["reason"] = f"story is {status} and the GitHub lookup failed: {prs_error or 'no PR list'}"
        return result

    claiming = [p for p in prs if ref in claimed_refs(p)]
    result["open_prs"] = sorted(p["number"] for p in claiming if p.get("state") == "OPEN")
    result["merged_prs"] = sorted(
        p["number"] for p in claiming if p.get("state") == "MERGED" and p.get("baseRefName") == base_branch
    )

    if result["open_prs"]:
        opened = ", ".join(f"#{n}" for n in result["open_prs"])
        result["reason"] = f"story is {status} and PR {opened} still claims it"
    elif not result["merged_prs"]:
        result["reason"] = f"story is {status} and no merged PR into {base_branch} claims it"
    else:
        merged = ", ".join(f"#{n}" for n in result["merged_prs"])
        result["satisfied"] = True
        result["via"] = "merged"
        result["reason"] = f"story is {status}; merged into {base_branch} by PR {merged}, no open PR claims it"
    return result


def _run(cmd):
    return subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True, check=False)


def fetch_story(ref):
    """The story JSON from scripts/taiga-story.sh, with its tasks."""
    proc = _run(["scripts/taiga-story.sh", str(ref), str(PROJECT_ID), "--with-tasks"])
    if proc.returncode == TAIGA_NOT_FOUND_EXIT:
        raise LookupFailed(f"story #{ref} not found in project {PROJECT_ID}")
    if proc.returncode != 0:
        raise LookupFailed(f"taiga-story.sh exited {proc.returncode}: {proc.stderr.strip()[:200]}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise LookupFailed(f"taiga-story.sh printed invalid JSON: {exc}") from exc


def fetch_prs(limit=PR_LIST_LIMIT):
    """Every PR on the upstream repo, open, closed or merged."""
    proc = _run([
        "env", "-u", "GH_TOKEN", "gh", "pr", "list",
        "--repo", GH_REPO,
        "--state", "all",
        "--limit", str(limit),
        "--json", "number,title,body,headRefName,baseRefName,state",
    ])
    if proc.returncode != 0:
        raise LookupFailed(f"gh pr list exited {proc.returncode}: {proc.stderr.strip()[:200]}")
    try:
        prs = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise LookupFailed(f"gh pr list printed invalid JSON: {exc}") from exc
    if not isinstance(prs, list):
        raise LookupFailed("gh pr list did not return a list")
    if len(prs) >= limit:
        raise LookupFailed(f"gh pr list returned {len(prs)} PRs, the limit; the list may be truncated")
    return prs


def fetch_gated_tasks(open_tasks):
    """Open tasks whose description has a ``## Gate`` section (human or live steps)."""
    from taiga_client import TaigaClient, TaigaError

    try:
        client = TaigaClient.from_env()
        gated = []
        for t in open_tasks:
            detail = client.get(f"/api/v1/tasks/{t['id']}")
            if GATE_HEADING.search((detail or {}).get("description") or ""):
                gated.append({"ref": t["ref"], "subject": t["subject"]})
        return gated
    except TaigaError as exc:
        raise LookupFailed(f"task lookup failed: {exc}") from exc


def resolve(refs, base_branch="main", fetch_story=fetch_story, fetch_prs=fetch_prs, gated_tasks=fetch_gated_tasks):
    """Classify every ref. The PR list is fetched at most once, and only when needed."""
    stories = {}
    for ref in refs:
        try:
            stories[ref] = (fetch_story(ref), None)
        except LookupFailed as exc:
            stories[ref] = (None, str(exc))

    needs_prs = any(s is not None and _status_name(s) not in ("Done", "Archived") for s, _ in stories.values())
    prs, prs_error = None, None
    if needs_prs:
        try:
            prs = fetch_prs()
        except LookupFailed as exc:
            prs_error = str(exc)

    dependencies = {}
    satisfied = []
    for ref in refs:
        story, story_error = stories[ref]
        result = classify_dependency(
            ref, story, prs, base_branch=base_branch, story_error=story_error, prs_error=prs_error
        )
        result["gated_tasks"] = []
        if result["via"] == "merged" and result["open_tasks"]:
            try:
                result["gated_tasks"] = gated_tasks(result["open_tasks"])
            except LookupFailed as exc:
                result["gated_tasks_error"] = str(exc)
        if result["satisfied"]:
            satisfied.append(ref)
        dependencies[str(ref)] = result

    return {"base_branch": base_branch, "satisfied_refs": satisfied, "dependencies": dependencies}


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", default=os.environ.get("BASE_BRANCH") or "main",
                        help="base branch a merged PR must target (default: $BASE_BRANCH or main)")
    parser.add_argument("refs", nargs="*", type=int,
                        help="out-of-run dependency refs; none prints an empty result")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    print(json.dumps(resolve(args.refs, base_branch=args.base), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
