#!/usr/bin/env bash
# issue-get.sh - Fetch ticket details from tracker CLI (e.g. Jira, Linear, GitHub Issues)
# Usage: ./scripts/issue-get.sh <TICKET_ID>

set -euo pipefail

TICKET_ID="${1:-}"
if [ -z "$TICKET_ID" ]; then
  echo "Error: No Ticket ID provided." >&2
  echo "Usage: $0 <TICKET_ID>" >&2
  exit 1
fi

echo "=== Fetching Issue: $TICKET_ID ==="

# Example GitHub Issues implementation:
# gh issue view "$TICKET_ID" --json title,body,state,labels

# Example Linear implementation:
# linear issue:show "$TICKET_ID"

# Placeholder implementation:
echo "Status: IN_PROGRESS"
echo "Title: Example issue description for $TICKET_ID"
echo "Description: As a developer, I want a standardized way to fetch ticket info so that my Cursor agent can understand the context automatically."
echo "Acceptance Criteria:"
echo "1. Script runs successfully with a ticket ID."
echo "2. Script outputs mock description that can be parsed."
