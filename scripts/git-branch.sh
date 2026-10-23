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

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Working tree is dirty. Commit, stash, or discard unrelated changes before branching." >&2
  git status --short >&2
  exit 1
fi

PREFIX="feature"
if [ "$TYPE" = "bug" ] || [ "$TYPE" = "bugfix" ]; then
  PREFIX="bugfix"
fi

BRANCH_NAME="${PREFIX}/${TICKET_ID}"

BASE="main"
if git show-ref --verify --quiet refs/heads/main || git show-ref --verify --quiet refs/remotes/origin/main; then
  BASE="main"
elif git show-ref --verify --quiet refs/heads/master || git show-ref --verify --quiet refs/remotes/origin/master; then
  BASE="master"
else
  echo "Error: Neither main nor master found." >&2
  exit 1
fi

echo "Checking out latest $BASE..."
git checkout "$BASE"
if git rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1 || git ls-remote --exit-code origin "$BASE" >/dev/null 2>&1; then
  git pull --ff-only origin "$BASE"
else
  echo "Warning: No origin/$BASE to pull; continuing with local $BASE." >&2
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  echo "Branch $BRANCH_NAME already exists. Checking it out."
  git checkout "$BRANCH_NAME"
  exit 0
fi

echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"
