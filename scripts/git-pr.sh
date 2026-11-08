#!/usr/bin/env bash
# git-pr.sh - Open a Pull Request using GitHub CLI (gh) or print instructions
# Usage:
#   ./scripts/git-pr.sh --title "<title>" --body-file <path> [--base <branch>] [--dry-run]
#
# Requires a meaningful title and a completed PR body (Impact Area + test plan).
# Prefer a body that includes Impact Area + test plan (see ticket-handoff rule).
# Base defaults to $TICKET_FLOW_BASE, else main/master if present.

set -euo pipefail

TITLE=""
BODY_FILE=""
BASE="${TICKET_FLOW_BASE:-}"
DRY_RUN=0

usage() {
  cat >&2 <<'EOF'
Usage: ./scripts/git-pr.sh --title "<title>" --body-file <path> [--base <branch>] [--dry-run]

  --title       Required. Must include a short summary after the ticket id
                (not just "PROJ-123:" with a blank reason).
  --body-file   Required. Markdown body with filled Impact Area fields.
  --base        Target branch (or set TICKET_FLOW_BASE). Required when neither
                main nor master exists locally/remotely.
  --dry-run     Validate and print the PR plan; do not create a PR.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --body-file)
      BODY_FILE="${2:-}"
      shift 2
      ;;
    --base)
      BASE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

BRANCH_NAME=$(git symbolic-ref --short HEAD)
TICKET_ID="${BRANCH_NAME##*/}"

if [ -z "$TITLE" ]; then
  echo "Error: --title is required. Do not open a PR with a placeholder title." >&2
  usage
  exit 1
fi

# Reject blank / ticket-only titles like "PROJ-123:" or "PROJ-123:   "
TITLE_TRIMMED=$(printf '%s' "$TITLE" | sed -e 's/[[:space:]]*$//')
if printf '%s' "$TITLE_TRIMMED" | grep -Eq "^[^:]+:[[:space:]]*$"; then
  echo "Error: Title is incomplete: \"$TITLE\"" >&2
  echo "Provide a short why-focused summary after the ticket id, e.g. \"$TICKET_ID: fix timeout on checkout\"." >&2
  exit 1
fi
if [ "${#TITLE_TRIMMED}" -lt 8 ]; then
  echo "Error: Title is too short to be meaningful: \"$TITLE\"" >&2
  exit 1
fi

if [ -z "$BODY_FILE" ]; then
  echo "Error: --body-file is required. Pass a completed Impact Area + test plan body." >&2
  usage
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "Error: Body file not found: $BODY_FILE" >&2
  exit 1
fi

BODY_CONTENT=$(cat "$BODY_FILE")
if [ -z "$(printf '%s' "$BODY_CONTENT" | tr -d '[:space:]')" ]; then
  echo "Error: Body file is empty: $BODY_FILE" >&2
  exit 1
fi

# Require Impact Area fields to have non-empty values (not just labels).
# Labels are often written as "- **App:**" — trailing ** must not count as a value.
field_value_nonempty() {
  local field="$1"
  local line rest
  line=$(printf '%s\n' "$BODY_CONTENT" | grep -Ei -e "^[[:space:]]*-[[:space:]].*${field}.*:" | head -1) || return 1
  rest="${line#*:}"
  # Strip markdown bold markers and whitespace; anything left is the value.
  rest=$(printf '%s' "$rest" | tr -d '*' | tr -d '[:space:]')
  [ -n "$rest" ]
}

missing_fields=()
while IFS= read -r field; do
  if ! field_value_nonempty "$field"; then
    missing_fields+=("$field")
  fi
done <<'EOF'
App
Surfaces
Components / APIs
Regression Risk
Tests
EOF

if [ "${#missing_fields[@]}" -gt 0 ]; then
  echo "Error: PR body is incomplete. Fill these Impact Area fields before creating a PR:" >&2
  for f in "${missing_fields[@]}"; do
    echo "  - $f" >&2
  done
  echo "Edit $BODY_FILE and re-run. A PR was not created." >&2
  exit 1
fi

if ! printf '%s\n' "$BODY_CONTENT" | grep -Eiq -e 'Test plan'; then
  echo "Error: PR body must include a Test plan section." >&2
  echo "A PR was not created." >&2
  exit 1
fi

resolve_base() {
  if [ -n "$BASE" ]; then
    printf '%s\n' "$BASE"
    return 0
  fi
  if git show-ref --verify --quiet refs/heads/main || git show-ref --verify --quiet refs/remotes/origin/main; then
    printf '%s\n' "main"
    return 0
  fi
  if git show-ref --verify --quiet refs/heads/master || git show-ref --verify --quiet refs/remotes/origin/master; then
    printf '%s\n' "master"
    return 0
  fi
  return 1
}

if ! BASE=$(resolve_base); then
  echo "Error: Could not determine base branch. Pass --base <branch> or set TICKET_FLOW_BASE." >&2
  echo "A PR was not created." >&2
  exit 1
fi

echo "=== Opening Pull Request for $BRANCH_NAME ==="
echo "Title: $TITLE"
echo "Base:  $BASE"
echo "Body:  $BODY_FILE"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run OK — validation passed; no PR created."
  exit 0
fi

if command -v gh >/dev/null 2>&1; then
  if ! gh pr create --title "$TITLE" --body-file "$BODY_FILE" --base "$BASE"; then
    echo "Error: gh pr create failed. A PR was not created." >&2
    exit 1
  fi
else
  REPO_URL=$(git config --get remote.origin.url || echo "https://github.com/your-org/your-repo")
  CLEAN_URL=$(echo "$REPO_URL" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
  echo "GitHub CLI 'gh' is not installed. Open the PR manually with this validated content:"
  echo "$CLEAN_URL/compare/$BASE...$BRANCH_NAME?expand=1"
  echo
  echo "Title: $TITLE"
  echo
  echo "Body:"
  cat "$BODY_FILE"
  echo
  echo "Note: No PR was created by this script (gh missing)."
  exit 0
fi
