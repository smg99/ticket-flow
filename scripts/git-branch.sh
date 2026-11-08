#!/usr/bin/env bash
# git-branch.sh - Create and checkout a branch with correct prefix
# Usage: ./scripts/git-branch.sh <TICKET_ID> <bug|feature> [base-branch]
#
# Base branch resolution order:
#   1. Optional third argument
#   2. $TICKET_FLOW_BASE
#   3. main, then master (if present)

set -euo pipefail

TICKET_ID="${1:-}"
TYPE="${2:-feature}"
BASE_ARG="${3:-}"

if [ -z "$TICKET_ID" ]; then
  echo "Error: No Ticket ID provided." >&2
  echo "Usage: $0 <TICKET_ID> <bug|feature> [base-branch]" >&2
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

resolve_base() {
  if [ -n "$BASE_ARG" ]; then
    printf '%s\n' "$BASE_ARG"
    return 0
  fi
  if [ -n "${TICKET_FLOW_BASE:-}" ]; then
    printf '%s\n' "$TICKET_FLOW_BASE"
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
  echo "Error: Neither main nor master found. Pass a base branch or set TICKET_FLOW_BASE." >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/$BASE" \
  && ! git show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
  echo "Error: Base branch '$BASE' not found locally or on origin." >&2
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

echo "Creating branch: $BRANCH_NAME (from $BASE)"
git checkout -b "$BRANCH_NAME"
