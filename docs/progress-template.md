# Ticket Flow Progress Board

Use this file to queue and track active tickets locally. This file is gitignored (`.local/progress.md`) so your morning workqueue remains private.

**Not authoritative:** the issue tracker (Jira/GitHub/Bitbucket/etc.) is the source of truth for ticket completion. This board only records local execution state.

## Status vocabulary

| Status | When to use |
|--------|-------------|
| `queued` | Listed but not started |
| `in_progress` | Actively implementing |
| `awaiting_review` | PR opened; review/merge still outstanding |
| `merged` | Merge observed (host/tracker)—not guessed |
| `done` | Product definition of done met (often QA accepted / released). **Never** solely because a PR was opened. |

Queue checkboxes: `[ ]` = still queued, `[x]` = left the queue (moved to Active / Awaiting review / Done sections).

## Queue

- [ ] PROJ-101: Fix payment gateway timeout error
- [ ] PROJ-102: Implement user profile avatar upload feature
- [ ] PROJ-103: Resolve layout overflow in navigation header

## Active Work

### PROJ-101: Fix payment gateway timeout error
- **Status:** in_progress
- **Branch:** `bugfix/PROJ-101`
- **Base:** `main`  <!-- or develop / release — set per product; or $TICKET_FLOW_BASE -->
- **Evidence:**
  - Commit SHA: _(none yet)_
  - PR URL: _(none yet)_
  - Checks: _(list commands + pass/fail/skip — never mark unrun as passed)_
  - Blockers: _(none)_
  - Approvals: commit Confirm? no · PR Confirm? no
  - Next action: implement fix + regression tests
- **Steps:**
  - [x] Fetch issue description
  - [x] Branch from base
  - [ ] Implement fix
  - [ ] Add regression tests
  - [ ] Human validation gate (Confirm commit)
  - [ ] Commit
  - [ ] Human validation gate (Confirm PR)
  - [ ] Push & open Pull Request
  - [ ] Chat notification

## Awaiting review

### PROJ-100: Fix button padding on checkout screen
- **Status:** awaiting_review
- **Branch:** `bugfix/PROJ-100`
- **Base:** `main`
- **Evidence:**
  - Commit SHA: `abc1234` _(example)_
  - PR URL: https://github.com/example/app/pull/42 _(example)_
  - Checks: unit tests pass; UI reproduce skipped (not a UI ticket)
  - Blockers: none
  - Approvals: commit Confirm yes · PR Confirm yes
  - Next action: wait for review / merge
- **Note:** Closed-without-merge ≠ merged. Do not move to Done until product DoD is met.

## Done

- [x] PROJ-099: Example completed ticket (DoD: merged + QA accepted)
