#!/usr/bin/env bash
# git-commit.sh - Create a ticket-scoped commit message
# Usage: ./scripts/git-commit.sh "<COMMIT_MESSAGE>"

set -euo pipefail

MESSAGE="${1:-}"
if [ -z "$MESSAGE" ]; then
  echo "Error: Commit message cannot be empty." >&2
  exit 1
fi

echo "Staged files:"
git diff --cached --name-only

echo "Creating commit..."
git commit -m "$MESSAGE"
