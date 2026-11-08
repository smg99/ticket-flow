# Execution evidence (lean)

Private per-ticket record so a human or another agent can **resume without guessing**.

Store entries in `.local/progress.md` (gitignored) or your approved project system—**never** in this public workflow repo with real client data.

## Required fields

| Field | Notes |
|-------|--------|
| Ticket ID | e.g. `PROJ-101` |
| Repo / branch / base | Observed values |
| Commit SHA | After commit; empty before |
| PR URL | After open; empty before |
| Status | `queued` \| `in_progress` \| `awaiting_review` \| `merged` \| `done` |
| Checks | Commands + `pass` / `fail` / `skip` / `unrun` — never silently mark passed |
| Blockers | Free text or `none` |
| Approvals | commit Confirm? · PR Confirm? |
| Next action | Single concrete next step |

## Rules

1. Distinguish **observed** vs **guessed** (especially merge and QA).
2. Failed, skipped, or unrun checks stay explicit.
3. On resume: recheck branch, diff, commit SHA, and evidence before editing.
4. Synthetic examples only in docs (see `docs/progress-template.md`).

## Optional machine shape

If you need YAML/JSON for tooling, mirror the same keys. A formal schema is optional; keep the vocabulary compatible with Ticket Flow and the companion Playbook.
