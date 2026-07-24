#!/usr/bin/env bash
# git-pr.sh - Open a Pull Request using GitHub CLI (gh) or print instructions
# Usage: ./scripts/git-pr.sh

set -euo pipefail

BRANCH_NAME=$(git symbolic-ref --short HEAD)

echo "=== Opening Pull Request for $BRANCH_NAME ==="

if command -v gh &> /dev/null; then
  # Automatically create a PR using GitHub CLI if available
  gh pr create --fill
else
  # Fallback: display URL for manual creation
  # Assume GitHub web interface fallback
  REPO_URL=$(git config --get remote.origin.url || echo "https://github.com/your-org/your-repo")
  # Convert git@github.com:org/repo.git to https://github.com/org/repo
  CLEAN_URL=$(echo "$REPO_URL" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
  
  echo "GitHub CLI 'gh' is not installed. You can manually open the PR here:"
  echo "$CLEAN_URL/compare/$BRANCH_NAME?expand=1"
fi
