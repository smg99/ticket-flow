# AGENTS.md — Ticket Flow

Thin ticket-to-PR execution layer for IDE coding agents. Not a framework, hosted runner, or issue tracker.

## Purpose

Sequence: fetch issue → branch → implement + tests → **Confirm** → commit → **Confirm** → push/PR → ask before chat. Preserve human approval gates. One ticket at a time unless the user asks otherwise.

## Skills

| Location | Role |
|----------|------|
| `skills/ticket-flow/SKILL.md` | **Canonical** portable skill (edit here) |
| `.cursor/skills/ticket-flow/SKILL.md` | Cursor adapter (symlink/copy of canonical) |
| `.cursor/rules/ticket-flow.mdc` | Trigger phrases → load skill; Confirm gates |
| `.cursor/rules/ticket-handoff.mdc` | Impact Area handoff format |

Other agents: point at `skills/ticket-flow/SKILL.md` and this file. Presence of instruction files does **not** grant automatic tool use or implied approval.

## Scripts (`scripts/`)

Wrappers must fail loudly when unconfigured or inputs are incomplete. They never invent ticket text or claim a chat send / PR create succeeded on failure.

| Script | Notes |
|--------|--------|
| `issue-get.sh` | Requires tracker CLI wiring |
| `git-branch.sh` | Dirty-tree refuse; base via arg / `TICKET_FLOW_BASE` / main\|master |
| `git-commit.sh` | Nonempty staged diff; refuse protected branch + sensitive paths |
| `git-push.sh` | Refuse push to main/master |
| `git-pr.sh` | Requires `--title`, `--body-file`, resolved `--base`; supports `--dry-run` |
| `notify-chat.sh` | Requires channel; no default channel |

Run wrapper tests: `./tests/run.sh`

## Approval gates

- Explicit **Confirm** before every commit and every PR. Silence is not Confirm.
- After PR open, local progress = `awaiting_review`, not `done`.
- Chat notify only after Yes + channel + draft shown.

## Local progress / evidence

Copy `docs/progress-template.md` → `.local/progress.md` (gitignored). Store commit SHA, PR URL, check results, blockers, and next action there. Do not commit client tickets or secrets to this public repo.

## Out of scope

No autonomous merge/deploy, no mandatory MCP/database, no storing client code or credentials here.
