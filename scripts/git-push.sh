#!/usr/bin/env bash
# git-push.sh - Push active branch to origin upstream
# Usage: ./scripts/git-push.sh

set -euo pipefail

BRANCH_NAME=$(git symbolic-ref --short HEAD)

if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "master" ]; then
  echo "Error: Directly pushing to protected branch $BRANCH_NAME is forbidden." >&2
  exit 1
fi

echo "Pushing branch $BRANCH_NAME to origin upstream..."
git push -u origin "$BRANCH_NAME"
