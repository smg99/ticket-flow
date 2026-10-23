# Skill: Ticket Flow Workflow

An automated workflow for retrieving issues, branching, implementing changes, verifying with tests, seeking human confirmation, staging, committing, opening a PR, and posting chat updates.

**Companion before tickets exist:** [AI-Assisted SDLC Playbook](https://smg99.github.io/engineering-ai-playbook/) — especially [Develop one story](https://smg99.github.io/engineering-ai-playbook/#stage/develop).

## Trigger Phrases
This skill is triggered when the user requests actions such as:
- `work on ticket PROJ-123`
- `fix bug PROJ-123`
- `implement feature PROJ-123`
- `run ticket-flow`
- `process morning queue`

## Naming glossary (customize per org)

| User says | Means |
|-----------|--------|
| **Primary app** | The main product repo only |
| **Product suite** | Primary app + sibling product repos in the same family |
| **Suite + shared UI** | Those products **plus** the shared UI/component package |

The shared UI package is **not** “the primary app” and **not** “the suite.” When the skill says “shared UI first,” change the package there, then bump consumers.

## Hard Rules (DO NOT DEVIATE)
1. **Confirm before every commit and before every PR.** Present the validation summary and wait for explicit approval. **Never treat silence as Confirm.**
2. **Never mention AI, Cursor, or agents** in commits, PR titles, or descriptions.
3. **Stage only ticket-relevant files.** Use path-scoped staging instead of blanket commands like `git add -A`.
4. **Reproduce UI bugs in the running app** before considering the task complete.
5. **Prefer root-cause fixes** over cosmetic rearrangements; **assert failure modes in tests**.
6. **Always add or update tests** for changes unless the user explicitly waives them.
7. **Ask before posting chat notifications.** Show the draft message and ask which channel to notify — never invent a default channel.
8. **Never force-push** to default protected branches (`main`, `master`, etc.). Never push secrets.
9. **On script failure:** report the error, offer documented recovery options, do not invent workarounds or fake success.

---

## Workflow Checklist

Process **one ticket at a time** unless the user asks otherwise. Execute steps in sequence.

### 0. Queue & Progress Board
1. Check for `.local/progress.md`. If it does not exist, copy `docs/progress-template.md` to `.local/progress.md`.
2. Mark the ticket status as **In progress** in `.local/progress.md`.
3. Morning list: parse all IDs; work serially.

### 1. Fetch Issue
1. Run `./scripts/issue-get.sh <TICKET_ID>` to retrieve ticket summary, description, and criteria.
2. If the script exits with a configure/error message, stop and help the user wire their tracker CLI — do not invent ticket content.
3. Classify the ticket as `bug` or `feature` based on issue metadata or user request (`fix bug` → bugfix).

### 2. Branching
1. Prefer the primary change surface first (often the shared UI package). Do not branch unrelated dirty repos.
2. Check out the latest base branch (`main` or `master`).
3. Run `./scripts/git-branch.sh <TICKET_ID> <bug|feature>` to create and check out the correct branch:
   - Bug: `bugfix/<TICKET_ID>`
   - Feature: `feature/<TICKET_ID>`

### 3. Implement & Test
1. Make code modifications adhering to project rules / `AGENTS.md`.
2. Write unit, integration, or regression tests demonstrating the change or bug fix.
3. Execute tests using appropriate run commands.
4. If a UI bug is involved: reproduce in the running app (exact route + step or screenshot); verify create **and** edit and every wizard step; assert the failure mode in tests.

### 4. Validation Gate — Commit (STOP)
1. Present the human gate with an **Impact Area** summary:
   ```text
   Please validate the changes for <TICKET_ID>.
   Summary: <what changed>
   Impact Area:
   - App: <e.g., frontend, backend>
   - Surfaces: <e.g., page, modal, API endpoint>
   - Components / APIs: <names of files/functions affected>
   - Regression Risk: <low/med/high with reasoning>
   - Tests: <added/updated paths, or "waived by user">

   Reply 'Confirm' to commit with message `<TICKET_ID>: <reason>`, or specify adjustments.
   ```
2. Wait for the user's **explicit** approval. DO NOT proceed without approval. Silence is not Confirm.

### 5. Stage & Commit
1. Stage ONLY the modified source and test files relevant to this ticket.
2. Commit changes using: `./scripts/git-commit.sh "<TICKET_ID>: <why-focused message>"`.

### 6. Validation Gate — Pull Request (STOP)
1. Present the proposed PR title, body (Impact Area + test plan), and base branch.
2. Wait for explicit **Confirm** before push/PR. Silence is not Confirm.

### 7. Push & Pull Request
1. Run `./scripts/git-push.sh` to push the branch to the remote repository.
2. Run `./scripts/git-pr.sh` to open a pull request against the default branch (body includes Impact Area).
3. Display the pull request URL.
4. PR title/description: human summary + test plan; **never** mention AI, Cursor, agents, or automation tooling.

### 8. Chat Notification
1. Prompt the user: "Would you like to notify the team on chat? (Yes/No)".
2. Ask for the channel/group to notify (or present options if known). Never invent a default.
3. Show the proposed message. Post only after channel chosen + explicit yes.
4. If confirmed, run `./scripts/notify-chat.sh "<PR_URL>" "<TICKET_ID>" "<CHANNEL>"`.
5. If notify fails, still offer copy-paste text when they opt in.

### 9. Consumer package bump (if needed)
When the change landed in a shared package:
1. Wait until merge/publish path is clear.
2. Branch the same `bugfix/<TICKET_ID>` or `feature/<TICKET_ID>` in the consumer.
3. Bump dependency (registry version or interim local artifact per your workflow).
4. Update tests if needed.
5. Same **Confirm** → commit → **Confirm** → push → PR → ask chat again.

### 10. Close Out
1. Mark the ticket as **Done** in `.local/progress.md`.
2. Report completion and ask for the next ticket.
