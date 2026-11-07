#!/usr/bin/env bash
# ABOUTME: Fetch a Taiga item (user story, issue, or epic) by ref number using the REST API directly.
# ABOUTME: Uses /by_ref endpoint for O(1) lookup — no pagination needed.

set -euo pipefail

usage() {
    echo "Usage: $0 <ref> [project_id] [--issue] [--epic] [--with-tasks]"
    echo "  ref          Item ref number (as shown in Taiga UI)"
    echo "  project_id   Taiga project ID (default: 39)"
    echo "  --issue      Look up an issue instead of a user story"
    echo "  --epic       Look up an epic instead of a user story"
    echo "  --with-tasks Also fetch and include the task list (user stories only)"
    echo ""
    echo "Env vars required: TAIGA_API_URL, TAIGA_USERNAME, TAIGA_PASSWORD"
    echo ""
    echo "Output: compact JSON with id, ref, subject, description, status, status_extra_info, milestone, milestone_name, milestone_slug, tags, is_closed,"
    echo "        created_date, modified_date, version (every item type)"
    echo "        (plus 'tasks' array when --with-tasks is used)"
    echo ""
    echo "Exit codes: 0 success, 44 item not found (404), 1 any other error"
    exit 1
}

REF="${1:-}"
# The project id is positional but optional: `taiga-story.sh 21 --with-tasks`
# must not read `--with-tasks` as the project.
if [[ -n "${2:-}" && "${2}" != --* ]]; then
    PROJECT_ID="$2"
else
    PROJECT_ID="39"
fi
ITEM_TYPE="userstories"
WITH_TASKS=false

for arg in "$@"; do
    if [[ "$arg" == "--issue" ]]; then
        ITEM_TYPE="issues"
    elif [[ "$arg" == "--epic" ]]; then
        ITEM_TYPE="epics"
    elif [[ "$arg" == "--with-tasks" ]]; then
        WITH_TASKS=true
    fi
done

[[ -z "$REF" ]] && usage

: "${TAIGA_API_URL:?TAIGA_API_URL is required}"
: "${TAIGA_USERNAME:?TAIGA_USERNAME is required}"
: "${TAIGA_PASSWORD:?TAIGA_PASSWORD is required}"

# Authenticate
AUTH_RESPONSE=$(curl -sf -X POST "${TAIGA_API_URL}/api/v1/auth" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"normal\", \"username\": \"$TAIGA_USERNAME\", \"password\": \"$TAIGA_PASSWORD\"}")

TOKEN=$(echo "$AUTH_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['auth_token'])")

# Fetch item by ref using dedicated by_ref endpoint (O(1), no pagination)
HTTP_CODE=$(curl -s -o /tmp/taiga_item_response.json -w "%{http_code}" \
    "${TAIGA_API_URL}/api/v1/${ITEM_TYPE}/by_ref?project=${PROJECT_ID}&ref=${REF}" \
    -H "Authorization: Bearer $TOKEN")

if [[ "$HTTP_CODE" -eq 404 ]]; then
    ITEM_LABEL="user story"
    [[ "$ITEM_TYPE" == "issues" ]] && ITEM_LABEL="issue"
    [[ "$ITEM_TYPE" == "epics" ]] && ITEM_LABEL="epic"
    echo "No ${ITEM_LABEL} found with ref #${REF} in project ${PROJECT_ID}" >&2
    exit 44
fi

if [[ "$HTTP_CODE" -ne 200 ]]; then
    echo "Taiga API error: HTTP $HTTP_CODE" >&2
    cat /tmp/taiga_item_response.json >&2
    exit 1
fi

STORY_ID=$(python3 -c "import json; print(json.load(open('/tmp/taiga_item_response.json'))['id'])")

# Optionally fetch tasks (user stories only)
echo "null" > /tmp/taiga_tasks_compact.json
if [[ "$WITH_TASKS" == true && "$ITEM_TYPE" == "userstories" ]]; then
    curl -s "${TAIGA_API_URL}/api/v1/tasks?project=${PROJECT_ID}&user_story=${STORY_ID}" \
        -H "Authorization: Bearer $TOKEN" -o /tmp/taiga_tasks_response.json
    python3 -c "
import json
tasks = json.load(open('/tmp/taiga_tasks_response.json'))
compact = [{
    'id': t['id'],
    'ref': t['ref'],
    'subject': t['subject'],
    'status': t['status'],
    'status_extra_info': t['status_extra_info'],
    'is_closed': t['is_closed'],
} for t in tasks]
open('/tmp/taiga_tasks_compact.json', 'w').write(json.dumps(compact))
"
fi

python3 -c "
import json
d = json.load(open('/tmp/taiga_item_response.json'))
tasks = json.load(open('/tmp/taiga_tasks_compact.json'))
out = {
    'id': d.get('id'),
    'ref': d.get('ref'),
    'subject': d.get('subject'),
    'description': d.get('description'),
    'status': d.get('status'),
    'status_extra_info': d.get('status_extra_info'),
    'milestone': d.get('milestone'),
    'milestone_name': d.get('milestone_name'),
    'milestone_slug': d.get('milestone_slug'),
    'tags': d.get('tags'),
    'is_closed': d.get('is_closed'),
    'created_date': d.get('created_date'),
    'modified_date': d.get('modified_date'),
    'version': d.get('version'),
}
if tasks is not None:
    out['tasks'] = tasks
print(json.dumps(out, indent=2))
"
