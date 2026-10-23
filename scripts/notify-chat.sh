#!/usr/bin/env bash
# notify-chat.sh - Post PR notification to Slack, Teams, etc.
# Usage: ./scripts/notify-chat.sh <PR_URL> <TICKET_ID> <CHANNEL>
#
# CHANNEL is required. Never invent a default.
# Configure by setting SLACK_WEBHOOK_URL (or similar) and enabling the curl block.

set -euo pipefail

PR_URL="${1:-}"
TICKET_ID="${2:-}"
CHANNEL="${3:-}"

if [ -z "$PR_URL" ] || [ -z "$TICKET_ID" ]; then
  echo "Error: PR_URL and TICKET_ID are required." >&2
  echo "Usage: $0 <PR_URL> <TICKET_ID> <CHANNEL>" >&2
  exit 1
fi

if [ -z "$CHANNEL" ]; then
  echo "Error: CHANNEL is required. Ask the user which channel to notify; do not invent a default." >&2
  exit 1
fi

MESSAGE="Hi Devs - Can you please review this PR? $PR_URL about $TICKET_ID"

echo "=== Chat Notification (draft) ===" >&2
echo "Target Channel: $CHANNEL" >&2
echo "Message: $MESSAGE" >&2

# --- Slack incoming webhook example ---
# if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
#   curl -fsS -X POST -H 'Content-type: application/json' \
#     --data "{\"text\":\"$MESSAGE\"}" \
#     "$SLACK_WEBHOOK_URL"
#   echo "Notification sent to $CHANNEL."
#   exit 0
# fi

cat >&2 <<EOF
Error: notify-chat.sh is not configured to send messages.

Draft for copy-paste:
$MESSAGE
(channel: $CHANNEL)

Edit scripts/notify-chat.sh to enable your webhook/CLI, then re-run.
Do not claim the notification was sent until a real send succeeds.
EOF
exit 2
