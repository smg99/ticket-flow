#!/usr/bin/env bash
# git-pr.sh - Open a Pull Request using GitHub CLI (gh) or print instructions
# Usage: ./scripts/git-pr.sh [optional path to body file]
#
# Prefer a body that includes Impact Area + test plan (see ticket-handoff rule).

set -euo pipefail

BRANCH_NAME=$(git symbolic-ref --short HEAD)
TICKET_ID="${BRANCH_NAME##*/}"
BODY_FILE="${1:-}"

echo "=== Opening Pull Request for $BRANCH_NAME ==="

DEFAULT_BODY=$(cat <<EOF
## Summary
<!-- What changed and why -->

## Impact Area
- **App:**
- **Surfaces:**
- **Components / APIs:**
- **Regression Risk:**
- **Tests:**

## Test plan
- [ ] Unit/integration tests pass
- [ ] Manual / UI verification (if applicable)
- [ ] No unrelated files in the diff

Ticket: $TICKET_ID
EOF
)

if command -v gh &> /dev/null; then
  if [ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ]; then
    gh pr create --title "${TICKET_ID}: " --body-file "$BODY_FILE"
  else
    TMP=$(mktemp)
    printf '%s\n' "$DEFAULT_BODY" > "$TMP"
    gh pr create --title "${TICKET_ID}: " --body-file "$TMP"
    rm -f "$TMP"
  fi
else
  REPO_URL=$(git config --get remote.origin.url || echo "https://github.com/your-org/your-repo")
  CLEAN_URL=$(echo "$REPO_URL" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
  echo "GitHub CLI 'gh' is not installed. Open the PR manually:"
  echo "$CLEAN_URL/compare/$BRANCH_NAME?expand=1"
  echo
  echo "Suggested body:"
  echo "$DEFAULT_BODY"
fi
