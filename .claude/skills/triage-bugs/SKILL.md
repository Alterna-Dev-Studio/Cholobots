---
name: triage-bugs
description: Sweep untriaged Taiga bugs - validate severity and priority against docs/bug-triage.md, set surface/source tags, route to Needs Info or Rejected, report Urgent bugs
argument-hint: "[--dry-run] [--refs <ref,ref,...>]"
disable-model-invocation: true  # human-only or scheduled: an unattended sweep - a model spawning this mid-task creates two owners for the same bugs
allowed-tools:
  - mcp__taiga-py__*
  - Bash(python3 scripts/taiga_select_issues.py *)
  - Bash(python3 scripts/taiga_project_setup.py --check)
  - Bash(env -u GH_TOKEN gh pr list *)
  - Read(//tmp/**)
  - Edit(//tmp/**)
  - Read
  - Grep
  - Glob
---

# Triage Bugs $ARGUMENTS

Apply the rubric in `docs/bug-triage.md` to every open bug in Taiga project 39 (`cholo-bots`) that is not yet `triaged`. This skill is a thin wrapper: the rules, the definition of triaged, the sweep steps, and the report format are all in that document. Read it in full before starting and follow its "Triage sweep" section step by step. Nothing below repeats the rubric. The canonical status, severity, priority and tag names are in `.claude/skills/shared/taiga-project.md`.

**THIS SKILL DOES NOT FIX BUGS.** It only reads and updates Taiga issues.

Names this project uses (the workflow server resolves them, so no id lookups):

- Severities: `Wishlist`, `Minor`, `Normal`, `Important`, `Critical`
- Priorities: `Low`, `Normal`, `High`, `Urgent`
- Statuses used here: `New`, `Needs Info`, `Rejected`, `Closed`
- Tags: exactly one surface (`product`, `devx`, `pipeline`, `ci`), exactly one source (`src:user`, `src:monitor`, `src:manual-test`, `src:pr-review`, `src:agent`, `src:jon`), then `triaged`. Keep any existing per-bot tag (`metichebot`, `chismebot`, `crudobot`, `obijuan`, `vueltabot`, `guardabot`, `mobile`) and keep other topic tags. If no per-bot tag is present and the subject or description makes the bot obvious, add that one; if it is not obvious, do not guess. A bot command or dashboard behaviour is surface `product`.

## Step 1: Preflight and parse arguments

Run `python3 scripts/taiga_project_setup.py --check` once. Exit 0: proceed. Exit 2: stop and print `Run: python3 scripts/taiga_project_setup.py --env-file scripts/taiga-auth.env --apply` for Jon (the project is missing statuses, the `Urgent` priority or pipeline tags this skill relies on).

- `--dry-run`: compute every decision and print the report, but make no Taiga writes.
- `--refs <ref,ref,...>`: limit the sweep to those refs (still skips any that already carry `triaged` unless the ref is listed explicitly, in which case re-triage it and comment on what changed).
- No arguments: full sweep.

## Step 2: Fetch candidates

Follow "Triage sweep" steps 1 and 2 in `docs/bug-triage.md`. Select the candidates with `python3 scripts/taiga_select_issues.py --purpose triage` (read-only; it prints the same JSON shape as the other purposes). Its `selected` list is the open Bug-type issues that lack the `triaged` tag; with `--refs <ref,...>` it narrows to those refs. Exit 2 is a bad option (show stderr and stop), exit 1 is a Taiga error (report and stop). Question and Enhancement issues are never selected. A ref listed with `--refs` that already carries `triaged` shows up in `skippedRefs`; add it to the candidates anyway (explicit refs are re-triaged, per Step 1).

Write the candidate list to `/tmp/triage-bugs.json` so a re-run after an interruption can resume:

```json
{"phase": "triaging", "dryRun": false, "bugs": [{"ref": 0, "id": 0, "subject": "", "status": "pending", "decision": null}]}
```

## Step 3: Triage each candidate

For each bug, in ref order, fetch it with `get_issue(project=39, ref=<ref>)` (never rely on a list payload for the description) and apply "Triage sweep" step 3 from `docs/bug-triage.md`: completeness check, duplicate search (`search(project=39, query="<key terms>")`), surface, source, severity, priority, single write.

Before deciding a bug is a duplicate or already fixed, also check GitHub: `env -u GH_TOKEN gh pr list --repo MrsBohemian/Cholobots --search "<ref>" --state all --json number,state,title,body`. Apply the claim rule from the doc (ref in the title or a `Fixes`/`Closes`/`Resolves #N` body line; a mention is not a claim). Closing is `update_issue(project=39, ref=<ref>, status="Closed")` plus a `Closed by PR #N` comment, with no tags added. Read the issue's comments only on bugs where a merged or open PR was found or the analysis mentions one, to look for `PR:` / `Sub-PR:` markers.

Write with one call: `update_issue(project=39, ref=<ref>, severity="<name>", priority="<name>", tags=[...], status="Needs Info" | "Rejected" (only when routing))`, then post the rationale with `add_comment(project=39, ref=<ref>, text="<comment>", entity_type="issue")`. `tags` replaces the whole list, so always send every tag you keep plus the surface, source and `triaged` tags. In dry-run mode, record the decision in the state file instead of writing.

Record each decision in `/tmp/triage-bugs.json` as you go.

## Step 4: Expire stale Needs Info

"Triage sweep" step 4 in `docs/bug-triage.md`. In dry-run mode, list them instead.

## Step 5: Report

Produce the report exactly as "Triage sweep" step 5 in `docs/bug-triage.md` orders it. `Urgent` bugs come first, each with the line:

> Run `/fix-single-bug <ref>` now.

Set `phase` to `"complete"` in the state file. In dry-run mode, end the report with the count of writes that would have been made and the command to apply them (`/triage-bugs` with the same `--refs`, without `--dry-run`).
