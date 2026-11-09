#!/usr/bin/env python3
# ABOUTME: Run the post-merge Taiga sync for a push to the fork's main: each pushed commit -> its merged upstream PR.
# ABOUTME: Applies the PR-number floor and de-duplication, then drives taiga_closing_refs and taiga-update-on-merge.sh.
import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPTS_DIR)

from taiga_closing_refs import extract_closing_refs  # noqa: E402

UPSTREAM_REPO = "MrsBohemian/Cholobots"
UPDATE_SCRIPT = os.path.join(SCRIPTS_DIR, "taiga-update-on-merge.sh")
MIN_PR_ENV = "TAIGA_SYNC_MIN_UPSTREAM_PR"
# Upstream PRs below #8 are never synced. PR #7 is #32's dump-only PR and #32
# carries close-tasks-on-merge, so processing it would close #93/#96/#101
# unfinished; #1 to #6 predate the merge-side-effect conventions.
DEFAULT_MIN_PR = 8
ZERO_SHA = "0" * 40
GITHUB_API = "https://api.github.com"


class GitHubError(Exception):
    """A GitHub API read failed; the message names the HTTP status or cause."""


def min_pr_from_env(environ):
    """The PR-number floor; a missing or empty value never lowers it below the default."""
    raw = (environ.get(MIN_PR_ENV) or "").strip()
    if not raw:
        return DEFAULT_MIN_PR
    try:
        return int(raw)
    except ValueError:
        raise ValueError(f"{MIN_PR_ENV} must be an integer, got {raw!r}") from None


def default_run_git(args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    return result.returncode, result.stdout


def commits_in_push(before, after, run_git, log=print):
    """Pushed commits, oldest first. Without a usable `before`, only `after`."""
    if before == ZERO_SHA:
        log(f"Push created the branch (before is all zeros); processing only {after}")
        return [after]
    rc, _ = run_git(["cat-file", "-e", f"{before}^{{commit}}"])
    if rc != 0:
        log(f"Push base {before} is not in the local clone; processing only {after}")
        return [after]
    rc, out = run_git(["rev-list", "--reverse", f"{before}..{after}"])
    if rc != 0:
        raise RuntimeError(f"git rev-list {before}..{after} failed")
    return [line.strip() for line in out.splitlines() if line.strip()]


def fetch_pulls(sha, token, repo=UPSTREAM_REPO):
    """The PRs GitHub associates with a commit (both a merge commit and a PR's own commits resolve)."""
    url = f"{GITHUB_API}/repos/{repo}/commits/{sha}/pulls"
    request = urllib.request.Request(url, headers={
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "cholobots-taiga-sync",
    })
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        raise GitHubError(f"GET {url} failed: HTTP {exc.code}") from None
    except urllib.error.URLError as exc:
        raise GitHubError(f"GET {url} failed: {exc.reason}") from None


def upstream_prs_for_commits(shas, fetch, min_pr, base="main", log=print):
    """Merged PRs into `base` at or above `min_pr`, each once, in first-seen order."""
    selected = []
    seen = set()
    for sha in shas:
        pulls = fetch(sha)
        if not pulls:
            log(f"commit {sha} has no upstream PR, skipped")
            continue
        for pr in pulls:
            number = pr["number"]
            if number in seen:
                continue
            seen.add(number)
            if not pr.get("merged_at"):
                log(f"PR #{number} is not merged, skipped")
            elif pr["base"]["ref"] != base:
                # A stacked sub-PR reaches main through its parent PR, which claims the work.
                log(f"PR #{number} targets {pr['base']['ref']}, not {base}, skipped")
            elif number < min_pr:
                log(f"PR #{number} is below {MIN_PR_ENV}={min_pr}, skipped")
            else:
                selected.append({
                    "number": number,
                    "title": pr.get("title") or "",
                    "body": pr.get("body") or "",
                    "branch": (pr.get("head") or {}).get("ref") or "",
                    "labels": [label["name"] for label in pr.get("labels") or []],
                    "url": pr["html_url"],
                })
    return selected


def default_run_update(argv, env_extra):
    # TAIGA_* come from the inherited environment; no secret is ever on argv.
    return subprocess.run(argv, env={**os.environ, **env_extra}).returncode


def sync_pr(pr, run_update, dry_run=False, log=print):
    """Run the update script for every ref the PR claims. True when every call succeeded."""
    refs = extract_closing_refs(pr["branch"], pr["title"], pr["body"])
    if not refs:
        log(f"PR #{pr['number']} claims no Taiga item")
        return True
    flags = ["--dry-run"] if dry_run else []
    env_extra = {"PR_LABELS": " ".join(pr["labels"])}
    ok = True
    for ref in refs:
        log(f"PR #{pr['number']}: syncing Taiga #{ref} (labels: {env_extra['PR_LABELS'] or 'none'})")
        argv = [UPDATE_SCRIPT, *flags, "--skip-if-synced", str(ref), str(pr["number"]), pr["url"]]
        if run_update(argv, env_extra) != 0:
            log(f"PR #{pr['number']}: update for Taiga #{ref} failed")
            ok = False
    return ok


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Sync Taiga for the upstream PRs merged in a push to the fork's main.")
    parser.add_argument("--before", default=os.environ.get("PUSH_BEFORE", ""),
                        help="SHA before the push (default: $PUSH_BEFORE)")
    parser.add_argument("--after", default=os.environ.get("PUSH_AFTER", ""),
                        help="SHA after the push (default: $PUSH_AFTER)")
    parser.add_argument("--dry-run", action="store_true",
                        help="pass --dry-run to taiga-update-on-merge.sh")
    return parser.parse_args(argv)


def main(argv=None, run_git=default_run_git, fetch=fetch_pulls, run_update=default_run_update):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        print("ERROR: GITHUB_TOKEN is required", file=sys.stderr)
        return 2
    if not args.after:
        print("ERROR: --after (or PUSH_AFTER) is required", file=sys.stderr)
        return 2
    try:
        min_pr = min_pr_from_env(os.environ)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    try:
        shas = commits_in_push(args.before or ZERO_SHA, args.after, run_git)
        print(f"{len(shas)} commit(s) in push; {MIN_PR_ENV}={min_pr}")
        prs = upstream_prs_for_commits(shas, lambda sha: fetch(sha, token), min_pr)
    except (GitHubError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    failed = [pr["number"] for pr in prs if not sync_pr(pr, run_update, dry_run=args.dry_run)]
    if failed:
        print(f"ERROR: Taiga update failed for PR(s) {', '.join(f'#{n}' for n in failed)}",
              file=sys.stderr)
        return 1
    print(f"Synced {len(prs)} upstream PR(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
