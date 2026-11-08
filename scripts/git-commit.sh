#!/usr/bin/env bash
# git-commit.sh - Create a ticket-scoped commit after deterministic safety checks
# Usage: ./scripts/git-commit.sh "<COMMIT_MESSAGE>"
#
# Human Confirm remains in the agent/UI. This script only enforces checks a
# shell can prove: nonempty staged diff, not on a protected branch, and no
# obviously sensitive paths in the index.

set -euo pipefail

MESSAGE="${1:-}"
if [ -z "$MESSAGE" ]; then
  echo "Error: Commit message cannot be empty." >&2
  echo "Usage: $0 \"<COMMIT_MESSAGE>\"" >&2
  exit 1
fi

BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || true)
PROTECTED_DEFAULTS="main master"
for protected in $PROTECTED_DEFAULTS; do
  if [ "$BRANCH_NAME" = "$protected" ]; then
    echo "Error: Refusing to commit directly on protected branch '$BRANCH_NAME'." >&2
    echo "Create a ticket branch first (./scripts/git-branch.sh), then commit there." >&2
    exit 1
  fi
done

STAGED=$(git diff --cached --name-only)
if [ -z "$STAGED" ]; then
  echo "Error: No staged changes. Stage ticket-relevant paths first (path-scoped; no git add -A)." >&2
  exit 1
fi

echo "Staged files:"
printf '%s\n' "$STAGED"

# Surface sensitive paths for human review; refuse by default.
SENSITIVE_PATTERN='(^|/)\.env($|\.|/)|(^|/)credentials\.json$|\.pem$|(^|/)id_rsa|(^|/)id_ed25519|\.p12$|\.keystore$|(^|/)secrets?(/|$)'
SENSITIVE_HITS=$(printf '%s\n' "$STAGED" | grep -E "$SENSITIVE_PATTERN" || true)
if [ -n "$SENSITIVE_HITS" ]; then
  echo "Error: Staged paths look sensitive. Unstage them or re-confirm with a human before committing:" >&2
  printf '%s\n' "$SENSITIVE_HITS" >&2
  exit 1
fi

echo "Creating commit..."
git commit -m "$MESSAGE"
