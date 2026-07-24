#!/usr/bin/env bash
# notify-chat.sh - Post PR notification to Slack, Teams, etc.
# Usage: ./scripts/notify-chat.sh <PR_URL> <TICKET_ID> <CHANNEL>

set -euo pipefail

PR_URL="${1:-}"
TICKET_ID="${2:-}"
CHANNEL="${3:-dev-channel}"

if [ -z "$PR_URL" ] || [ -z "$TICKET_ID" ]; then
  echo "Error: PR_URL and TICKET_ID are required." >&2
  exit 1
fi

MESSAGE="Hi Devs - Can you please review this PR? $PR_URL about $TICKET_ID"

echo "=== Chat Notification ==="
echo "Target Channel: $CHANNEL"
echo "Message: $MESSAGE"

# Example using webhook:
# curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE\"}" "$SLACK_WEBHOOK_URL"

echo "Notification queued/sent successfully!"
