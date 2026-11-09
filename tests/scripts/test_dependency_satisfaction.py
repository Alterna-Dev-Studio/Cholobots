# ABOUTME: Pytest tests for scripts/lib/dependency_satisfaction.py.
# ABOUTME: An out-of-run dependency is satisfied when Done, or merged into the base with no open claiming PR.
import json
import os
import subprocess
import sys

import pytest

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
sys.path.insert(0, os.path.join(REPO_ROOT, "scripts", "lib"))

import dependency_satisfaction as ds
from dependency_satisfaction import (
    LookupFailed,
    classify_dependency,
    claimed_refs,
    fetch_prs,
    fetch_story,
    resolve,
)


def story(ref, status, tasks=()):
    """The shape `scripts/taiga-story.sh <ref> 39 --with-tasks` prints."""
    return {
        "id": 1000 + ref,
        "ref": ref,
        "status": 0,
        "status_extra_info": {"name": status, "is_closed": status in ("Done", "Archived")},
        "is_closed": status in ("Done", "Archived"),
        "tasks": list(tasks),
    }


def task(ref, subject, closed=False):
    return {
        "id": 5000 + ref,
        "ref": ref,
        "subject": subject,
        "status_extra_info": {"name": "Closed" if closed else "New", "is_closed": closed},
        "is_closed": closed,
    }


def pr(number, state, title="", branch="", base="main", body=""):
    """The shape `gh pr list --json number,title,body,headRefName,baseRefName,state` prints."""
    return {
        "number": number,
        "state": state,
        "title": title,
        "body": body,
        "headRefName": branch,
        "baseRefName": base,
    }


class TestClaimedRefs:
    def test_claim_via_title_prefix(self):
        assert claimed_refs(pr(1, "MERGED", title="#31: Test Discord server", branch="docs-only")) == [31]

    def test_claim_via_branch_name(self):
        assert claimed_refs(pr(2, "MERGED", title="Add seed fixtures", branch="feature/48-seed")) == [48]

    def test_bare_mention_is_not_a_claim(self):
        assert claimed_refs(pr(3, "MERGED", title="docs: mention #31 and #48", branch="docs/x")) == []

    def test_fixes_body_line_claims(self):
        body = "Fixes bug [#12](https://backlog.growthgarage.org/project/cholo-bots/issue/12)"
        assert claimed_refs(pr(4, "MERGED", title="Some fix", branch="hotfix", body=body)) == [12]


class TestClassifyDependency:
    def test_done_is_satisfied(self):
        result = classify_dependency(31, story(31, "Done"), [])
        assert result["satisfied"] is True
        assert result["via"] == "done"

    def test_done_is_satisfied_even_when_gh_failed(self):
        result = classify_dependency(31, story(31, "Done"), None, prs_error="gh exited 1")
        assert result["satisfied"] is True
        assert result["via"] == "done"

    def test_merged_not_done_is_satisfied(self):
        prs = [pr(10, "MERGED", title="#48: Seed fixtures", branch="feature/48-seed")]
        result = classify_dependency(48, story(48, "Ready for test"), prs)
        assert result["satisfied"] is True
        assert result["via"] == "merged"
        assert result["merged_prs"] == [10]
        assert result["open_prs"] == []

    def test_merged_with_other_pr_still_open_is_not_satisfied(self):
        prs = [
            pr(20, "MERGED", title="#58: Contribution agreement, part 1", branch="feature/58-part-1"),
            pr(21, "OPEN", title="#58: Contribution agreement, part 2", branch="feature/58-part-2"),
        ]
        result = classify_dependency(58, story(58, "Ready for review"), prs)
        assert result["satisfied"] is False
        assert result["merged_prs"] == [20]
        assert result["open_prs"] == [21]
        assert "#21" in result["reason"]

    def test_open_pr_into_a_feature_branch_still_blocks(self):
        prs = [
            pr(20, "MERGED", title="#58: part 1", branch="feature/58-part-1"),
            pr(22, "OPEN", title="#58: stacked part", branch="feature/58-stacked", base="feature/58-part-1"),
        ]
        assert classify_dependency(58, story(58, "Ready for review"), prs)["satisfied"] is False

    def test_open_pr_only_is_not_satisfied(self):
        prs = [pr(30, "OPEN", title="#47: Local Supabase stack", branch="feature/47-local-stack")]
        result = classify_dependency(47, story(47, "Ready for review"), prs)
        assert result["satisfied"] is False
        assert result["open_prs"] == [30]

    def test_no_pr_and_not_done_is_not_satisfied(self):
        result = classify_dependency(47, story(47, "In progress"), [])
        assert result["satisfied"] is False
        assert "no merged PR" in result["reason"]

    def test_closed_unmerged_pr_does_not_count(self):
        prs = [pr(31, "CLOSED", title="#47: abandoned attempt", branch="feature/47-old")]
        assert classify_dependency(47, story(47, "Ready"), prs)["satisfied"] is False

    def test_merged_into_other_base_does_not_count(self):
        prs = [pr(40, "MERGED", title="#47: stack", branch="feature/47-stack", base="epic/46-integration-31")]
        result = classify_dependency(47, story(47, "Ready for test"), prs)
        assert result["satisfied"] is False

    def test_honours_a_non_main_base_branch(self):
        prs = [pr(41, "MERGED", title="#47: stack", branch="feature/47-stack", base="release")]
        result = classify_dependency(47, story(47, "Ready for test"), prs, base_branch="release")
        assert result["satisfied"] is True

    def test_archived_is_never_satisfied(self):
        prs = [pr(50, "MERGED", title="#40: Profiles", branch="feature/40-profiles")]
        result = classify_dependency(40, story(40, "Archived"), prs)
        assert result["satisfied"] is False
        assert "Archived" in result["reason"]

    def test_gh_failure_is_not_satisfied_and_reason_says_why(self):
        result = classify_dependency(48, story(48, "Ready for test"), None, prs_error="gh exited 4: auth")
        assert result["satisfied"] is False
        assert result["via"] is None
        assert "gh exited 4: auth" in result["reason"]

    def test_taiga_lookup_failure_is_not_satisfied(self):
        prs = [pr(10, "MERGED", title="#48: Seed fixtures", branch="feature/48-seed")]
        result = classify_dependency(48, None, prs, story_error="taiga-story.sh exited 1")
        assert result["satisfied"] is False
        assert "taiga-story.sh exited 1" in result["reason"]

    def test_other_refs_prs_are_ignored(self):
        prs = [
            pr(60, "MERGED", title="#31: Test server", branch="feature/31-server"),
            pr(61, "OPEN", title="#48: Seed", branch="feature/48-seed"),
        ]
        result = classify_dependency(31, story(31, "Ready for test"), prs)
        assert result["satisfied"] is True
        assert result["open_prs"] == []

    def test_reports_open_tasks(self):
        tasks = [task(90, "Jon checks the live server"), task(91, "Write docs", closed=True)]
        prs = [pr(10, "MERGED", title="#31: Test server", branch="feature/31-server")]
        result = classify_dependency(31, story(31, "Ready for test", tasks), prs)
        assert [t["ref"] for t in result["open_tasks"]] == [90]


class FakeRun:
    """Stand-in for subprocess.run: returns canned results keyed on argv[0]-ish matching."""

    def __init__(self, results):
        self.results = results
        self.calls = []

    def __call__(self, cmd, **kwargs):
        self.calls.append(cmd)
        for key, (rc, out, err) in self.results.items():
            if key in " ".join(cmd):
                return subprocess.CompletedProcess(cmd, rc, out, err)
        raise AssertionError(f"unexpected command: {cmd}")


class TestFetchers:
    def test_fetch_prs_uses_gh_without_gh_token_against_upstream(self, monkeypatch):
        fake = FakeRun({"gh pr list": (0, json.dumps([pr(1, "OPEN", title="#5: x")]), "")})
        monkeypatch.setattr(ds.subprocess, "run", fake)
        prs = fetch_prs()
        assert prs[0]["number"] == 1
        cmd = fake.calls[0]
        assert cmd[:3] == ["env", "-u", "GH_TOKEN"]
        assert "--repo" in cmd and cmd[cmd.index("--repo") + 1] == "MrsBohemian/Cholobots"
        assert "--state" in cmd and cmd[cmd.index("--state") + 1] == "all"

    def test_fetch_prs_gh_nonzero_exit_is_failure(self, monkeypatch):
        monkeypatch.setattr(ds.subprocess, "run", FakeRun({"gh pr list": (1, "", "HTTP 401")}))
        with pytest.raises(LookupFailed, match="HTTP 401"):
            fetch_prs()

    def test_fetch_prs_truncated_list_is_failure(self, monkeypatch):
        full = [pr(n, "MERGED") for n in range(3)]
        monkeypatch.setattr(ds.subprocess, "run", FakeRun({"gh pr list": (0, json.dumps(full), "")}))
        with pytest.raises(LookupFailed, match="truncated"):
            fetch_prs(limit=3)

    def test_fetch_prs_bad_json_is_failure(self, monkeypatch):
        monkeypatch.setattr(ds.subprocess, "run", FakeRun({"gh pr list": (0, "not json", "")}))
        with pytest.raises(LookupFailed):
            fetch_prs()

    def test_fetch_story_not_found_is_failure(self, monkeypatch):
        monkeypatch.setattr(ds.subprocess, "run", FakeRun({"taiga-story.sh": (44, "", "404")}))
        with pytest.raises(LookupFailed, match="not found"):
            fetch_story(999)

    def test_fetch_story_parses_json(self, monkeypatch):
        monkeypatch.setattr(
            ds.subprocess, "run", FakeRun({"taiga-story.sh": (0, json.dumps(story(31, "Done")), "")})
        )
        assert fetch_story(31)["ref"] == 31


class TestResolve:
    def test_satisfied_refs_and_details(self):
        stories = {31: story(31, "Done"), 48: story(48, "Ready for test"), 47: story(47, "In progress")}
        prs = [pr(10, "MERGED", title="#48: Seed", branch="feature/48-seed")]
        result = resolve(
            [31, 48, 47],
            fetch_story=lambda ref: stories[ref],
            fetch_prs=lambda: prs,
            gated_tasks=lambda tasks: [],
        )
        assert result["satisfied_refs"] == [31, 48]
        assert result["dependencies"]["48"]["via"] == "merged"
        assert result["dependencies"]["47"]["satisfied"] is False

    def test_gh_failure_leaves_only_done_refs_satisfied(self):
        stories = {31: story(31, "Done"), 48: story(48, "Ready for test")}

        def broken():
            raise LookupFailed("gh exited 1: boom")

        result = resolve(
            [31, 48], fetch_story=lambda ref: stories[ref], fetch_prs=broken, gated_tasks=lambda t: []
        )
        assert result["satisfied_refs"] == [31]
        assert "gh exited 1: boom" in result["dependencies"]["48"]["reason"]

    def test_gh_is_not_called_when_every_dep_is_done(self):
        def unexpected():
            raise AssertionError("gh should not be called")

        result = resolve(
            [31], fetch_story=lambda ref: story(31, "Done"), fetch_prs=unexpected, gated_tasks=lambda t: []
        )
        assert result["satisfied_refs"] == [31]

    def test_taiga_failure_is_reported(self):
        def broken(ref):
            raise LookupFailed("taiga-story.sh exited 1: timeout")

        result = resolve([48], fetch_story=broken, fetch_prs=lambda: [], gated_tasks=lambda t: [])
        assert result["satisfied_refs"] == []
        assert "timeout" in result["dependencies"]["48"]["reason"]

    def test_gated_tasks_listed_only_for_the_merged_path(self):
        tasks = [task(90, "Jon checks the live server")]
        stories = {48: story(48, "Ready for test", tasks), 47: story(47, "In progress", tasks)}
        prs = [pr(10, "MERGED", title="#48: Seed", branch="feature/48-seed")]
        seen = []

        def gated(open_tasks):
            seen.append([t["ref"] for t in open_tasks])
            return [{"ref": 90, "subject": "Jon checks the live server"}]

        result = resolve([48, 47], fetch_story=lambda ref: stories[ref], fetch_prs=lambda: prs, gated_tasks=gated)
        assert result["dependencies"]["48"]["gated_tasks"] == [{"ref": 90, "subject": "Jon checks the live server"}]
        assert result["dependencies"]["47"]["gated_tasks"] == []
        assert seen == [[90]]

    def test_gated_task_lookup_failure_does_not_change_satisfaction(self):
        stories = {48: story(48, "Ready for test", [task(90, "Jon checks")])}
        prs = [pr(10, "MERGED", title="#48: Seed", branch="feature/48-seed")]

        def broken(open_tasks):
            raise LookupFailed("task fetch failed")

        result = resolve([48], fetch_story=lambda ref: stories[ref], fetch_prs=lambda: prs, gated_tasks=broken)
        assert result["satisfied_refs"] == [48]
        assert "task fetch failed" in result["dependencies"]["48"]["gated_tasks_error"]


class TestCli:
    def test_base_defaults_to_env(self, monkeypatch):
        monkeypatch.setenv("BASE_BRANCH", "release")
        assert ds.parse_args(["48"]).base == "release"

    def test_base_defaults_to_main(self, monkeypatch):
        monkeypatch.delenv("BASE_BRANCH", raising=False)
        args = ds.parse_args(["48", "31"])
        assert args.base == "main"
        assert args.refs == [48, 31]

    def test_explicit_base_wins(self, monkeypatch):
        monkeypatch.setenv("BASE_BRANCH", "release")
        assert ds.parse_args(["--base", "main", "48"]).base == "main"

    def test_no_refs_prints_an_empty_result(self, monkeypatch, capsys):
        def unexpected(*args, **kwargs):
            raise AssertionError("no lookup should run without refs")

        monkeypatch.setattr(ds.subprocess, "run", unexpected)
        assert ds.main(["--base", "main"]) == 0
        assert json.loads(capsys.readouterr().out) == {
            "base_branch": "main", "satisfied_refs": [], "dependencies": {},
        }
