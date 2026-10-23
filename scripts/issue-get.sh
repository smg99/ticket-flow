#!/usr/bin/env bash
# issue-get.sh - Fetch ticket details from tracker CLI (e.g. Jira, Linear, GitHub Issues)
# Usage: ./scripts/issue-get.sh <TICKET_ID>
#
# Configure by uncommenting ONE implementation below and removing the CONFIGURE ME block.

set -euo pipefail

TICKET_ID="${1:-}"
if [ -z "$TICKET_ID" ]; then
  echo "Error: No Ticket ID provided." >&2
  echo "Usage: $0 <TICKET_ID>" >&2
  exit 1
fi

echo "=== Fetching Issue: $TICKET_ID ===" >&2

# --- GitHub Issues ---
# if command -v gh >/dev/null 2>&1; then
#   gh issue view "$TICKET_ID" --json number,title,body,state,labels
#   exit 0
# fi

# --- Linear (requires linear CLI) ---
# if command -v linear >/dev/null 2>&1; then
#   linear issue:show "$TICKET_ID"
#   exit 0
# fi

# --- Jira (requires jira CLI) ---
# if command -v jira >/dev/null 2>&1; then
#   jira issue view "$TICKET_ID"
#   exit 0
# fi

cat >&2 <<'EOF'
Error: issue-get.sh is not configured for your tracker.

Edit scripts/issue-get.sh and enable one CLI integration (gh / linear / jira),
or replace this script with a wrapper that prints title, body, state, and acceptance criteria.

Do not invent ticket content. Wire the tracker, then re-run.
EOF
exit 2
