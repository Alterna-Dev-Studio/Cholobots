#!/usr/bin/env bash
# ABOUTME: Unit tests for the taiga-sync.yml workflow definition itself.
# ABOUTME: Guards the fork-only push trigger, the self-hosted runner, the PR floor, and that a failed sync turns the run red.
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; FAILURES=$((FAILURES + 1)); }
info() { echo -e "${YELLOW}→ $1${NC}"; }

FAILURES=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/taiga-sync.yml"

info "Testing $WORKFLOW"

if [ ! -f "$WORKFLOW" ]; then
    fail "workflow file exists"
    exit 1
fi
pass "workflow file exists"

# Comments are dropped before the structural checks so prose about what the
# workflow must never do cannot satisfy or trip them.
BODY=$(sed -E 's/[[:space:]]+#.*$//; /^[[:space:]]*#/d' "$WORKFLOW")

# Checks one literal line (indentation ignored) is present in the workflow body.
has_line() {
    grep -qxF "$1" <<< "$(sed -E 's/^[[:space:]]+//' <<< "$BODY")"
}

expect_line() {
    local line="$1" what="$2"
    if has_line "$line"; then
        pass "$what"
    else
        fail "$what (missing line: $line)"
    fi
}

# A sync that cannot sync must not look green: continue-on-error at any level
# would mask a failed login or a failed item update as a successful run.
if grep -qE '^[[:space:]]*continue-on-error:' <<< "$BODY"; then
    fail "taiga-sync.yml has no continue-on-error (a failed step must fail the run)"
    grep -nE '^[[:space:]]*continue-on-error:' "$WORKFLOW"
else
    pass "taiga-sync.yml has no continue-on-error (a failed step must fail the run)"
fi

# The fork is public and its runners are self-hosted: any trigger a fork PR can
# fire would let outside code onto the homelab runners.
for trigger in pull_request pull_request_target workflow_run issue_comment; do
    if grep -qE "(^|[^a-z_])${trigger}([^a-z_]|$)" <<< "$BODY"; then
        fail "taiga-sync.yml has no '$trigger' trigger"
    else
        pass "taiga-sync.yml has no '$trigger' trigger"
    fi
done

ON_BLOCK=$(sed -n '/^on:/,/^[a-z]/p' <<< "$BODY")
if grep -qE '^[[:space:]]+push:' <<< "$ON_BLOCK" && grep -qE '^[[:space:]]+branches: \[main\]' <<< "$ON_BLOCK"; then
    pass "triggered by push to main"
else
    fail "triggered by push to main"
fi

# Upstream (MrsBohemian/Cholobots) carries the same file; the guard keeps its
# copy inert so a push there never waits for a runner it does not have.
expect_line "if: github.repository == 'Alterna-Dev-Studio/Cholobots'" "job is guarded to the fork"
expect_line "runs-on: [self-hosted, Linux, X64, small]" "runs on the homelab self-hosted runners"
expect_line "TAIGA_SYNC_MIN_UPSTREAM_PR: 8" "PR floor TAIGA_SYNC_MIN_UPSTREAM_PR is 8"
expect_line "contents: read" "permissions are contents: read"
expect_line "cancel-in-progress: false" "concurrent pushes queue instead of cancelling"
expect_line "fetch-depth: 0" "checkout has full history for the push range"

# A script the workflow calls but never checks out only fails at runtime, on
# a real merge -- the sparse-checkout list must carry all three.
SPARSE=$(sed -n '/sparse-checkout: |/,/sparse-checkout-cone-mode/p' <<< "$BODY")
for script in scripts/taiga-update-on-merge.sh scripts/taiga_closing_refs.py scripts/taiga_sync_from_push.py; do
    if grep -qF "$script" <<< "$SPARSE"; then
        pass "sparse-checkout lists $script"
    else
        fail "sparse-checkout lists $script"
    fi
done

# The inline extractor treated any bare #ref mention as a claim (bug #2237).
# It must not creep back in -- extraction goes through taiga_closing_refs.py,
# which the driver imports.
if grep -qE "grep -oP '#\\\\K\\\\d\\+'" "$WORKFLOW"; then
    fail "taiga-sync.yml has no inline bare-#ref extractor"
    grep -nE "grep -oP '#\\\\K\\\\d\\+'" "$WORKFLOW"
else
    pass "taiga-sync.yml has no inline bare-#ref extractor"
fi

SYNC_STEP=$(sed -n '/name: Sync merged upstream PRs/,$p' <<< "$BODY")
if grep -qF 'PUSH_BEFORE: ${{ github.event.before }}' <<< "$SYNC_STEP" \
    && grep -qF 'PUSH_AFTER: ${{ github.event.after }}' <<< "$SYNC_STEP"; then
    pass "sync step passes the push range from github.event.before/after"
else
    fail "sync step passes the push range from github.event.before/after"
fi
if grep -qF 'python3 scripts/taiga_sync_from_push.py' <<< "$SYNC_STEP"; then
    pass "sync step runs scripts/taiga_sync_from_push.py"
else
    fail "sync step runs scripts/taiga_sync_from_push.py"
fi
if grep -qF 'GITHUB_TOKEN: ${{ github.token }}' <<< "$SYNC_STEP"; then
    pass "sync step passes GITHUB_TOKEN for the upstream PR lookup"
else
    fail "sync step passes GITHUB_TOKEN for the upstream PR lookup"
fi

# A pre-HTTP curl failure is ambiguous on its own -- DNS, TLS, and a malformed
# URL all look identical without the exit code, which sent a real investigation
# after the wrong cause. The message must name it.
if grep -q 'curl exit \$CURL_EXIT_CODE' "$WORKFLOW"; then
    pass "connectivity error names the curl exit code"
else
    fail "connectivity error names the curl exit code"
fi

# Case labels are literal text, and one of them ('35|60') contains a regex
# metacharacter -- so normalize the indentation away and match literally rather
# than building a pattern out of the label.
NORMALIZED=$(sed -E 's/^[[:space:]]+//; s/\)[[:space:]]+DIAGNOSIS=/) DIAGNOSIS=/' "$WORKFLOW")

for label in '6' '7' '28' '35|60'; do
    # Here-strings, not echo-to-grep pipes: under pipefail, grep -q's early exit can SIGPIPE the writer (bug #2791).
    if grep -qF "${label}) DIAGNOSIS=" <<< "$NORMALIZED"; then
        pass "curl exit '$label' is translated to a diagnosis"
    else
        fail "curl exit '$label' is translated to a diagnosis"
    fi
done

# Structural check when PyYAML is available; the greps above stand alone without it.
if python3 -c 'import yaml' 2>/dev/null; then
    if python3 - "$WORKFLOW" <<'PY'
import sys
import yaml

doc = yaml.safe_load(open(sys.argv[1]))
on = doc.get("on", doc.get(True))  # PyYAML reads a bare `on` key as True
assert set(on) == {"push"}, on
assert on["push"] == {"branches": ["main"]}, on
job = doc["jobs"]["update-taiga"]
assert job["if"] == "github.repository == 'Alterna-Dev-Studio/Cholobots'", job["if"]
assert job["runs-on"] == ["self-hosted", "Linux", "X64", "small"], job["runs-on"]
assert str(job["env"]["TAIGA_SYNC_MIN_UPSTREAM_PR"]) == "8"
assert doc["permissions"] == {"contents": "read"}, doc["permissions"]
assert doc["concurrency"]["cancel-in-progress"] is False
PY
    then
        pass "YAML parses and has the expected trigger, guard, runner, floor and permissions"
    else
        fail "YAML parses and has the expected trigger, guard, runner, floor and permissions"
    fi
else
    info "PyYAML not installed; structural YAML check skipped"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo -e "${GREEN}All tests passed${NC}"
    exit 0
else
    echo -e "${RED}$FAILURES test(s) failed${NC}"
    exit 1
fi
