#!/usr/bin/env bash
# git-branch.sh - Create and checkout a branch with correct prefix
# Usage: ./scripts/git-branch.sh <TICKET_ID> <bug|feature>

set -euo pipefail

TICKET_ID="${1:-}"
TYPE="${2:-feature}"

if [ -z "$TICKET_ID" ]; then
  echo "Error: No Ticket ID provided." >&2
  exit 1
fi

PREFIX="feature"
if [ "$TYPE" = "bug" ] || [ "$TYPE" = "bugfix" ]; then
  PREFIX="bugfix"
fi

BRANCH_NAME="${PREFIX}/${TICKET_ID}"

echo "Checking out latest main branch..."
git checkout main || git checkout master
git pull origin main || git pull origin master || true

echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"
