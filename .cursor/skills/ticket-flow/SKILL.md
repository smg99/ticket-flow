# Skill: Ticket Flow Workflow

An automated workflow for retrieving issues, branching, implementing changes, verifying with tests, seeking human confirmation, staging, committing, opening a PR, and posting chat updates.

## Trigger Phrases
This skill is triggered when the user requests actions such as:
- `work on ticket PROJ-123`
- `fix bug PROJ-123`
- `implement feature PROJ-123`
- `run ticket-flow`
- `process morning queue`

## Hard Rules (DO NOT DEVIATE)
1. **Confirm before every commit and every PR.** Present the validation summary and wait for user confirmation.
2. **Never mention AI, Cursor, or agents** in commits, PR titles, or descriptions.
3. **Stage only ticket-relevant files.** Use path-scoped staging instead of blanket commands like `git add -A`.
4. **Reproduce UI bugs in the running app** before considering the task complete.
5. **Always add or update tests** for changes unless the user explicitly waives them.
6. **Ask before posting chat notifications.** Show the draft message and ask which channel to notify.
7. **Never force-push** to default protected branches (`main`, `master`, etc.).

---

## Workflow Checklist

The agent must execute the following steps in sequence:

### 0. Queue & Progress Board
1. Check for `.local/progress.md`. If it does not exist, copy `docs/progress-template.md` to `.local/progress.md`.
2. Mark the ticket status as **In progress** in `.local/progress.md`.

### 1. Fetch Issue
1. Run `./scripts/issue-get.sh <TICKET_ID>` to retrieve ticket summary, description, and criteria.
2. Classify the ticket as `bug` or `feature` based on issue metadata or user request.

### 2. Branching
1. Check out the latest base branch (`main` or `master`).
2. Run `./scripts/git-branch.sh <TICKET_ID> <bug|feature>` to create and check out the correct branch:
   - Bug: `bugfix/<TICKET_ID>`
   - Feature: `feature/<TICKET_ID>`

### 3. Implement & Test
1. Make code modifications adhering to project rules.
2. Write unit, integration, or regression tests demonstrating the change or bug fix.
3. Execute tests using appropriate run commands.
4. If a UI bug is involved, run the app and visually confirm the fix.

### 4. Validation Gate (STOP)
1. Present the human gate dialog with an **Impact Area** summary:
   ```text
   Please validate the changes for <TICKET_ID>.
   Summary: <what changed>
   Impact Area:
   - App: <e.g., frontend, backend>
   - Surfaces: <e.g., page, modal, API endpoint>
   - Components / APIs: <names of files/functions affected>
   - Regression Risk: <low/med/high with reasoning>
   
   Reply 'Confirm' to commit with message `<TICKET_ID>: <reason>`, or specify adjustments.
   ```
2. Wait for the user's explicit approval. DO NOT proceed without approval.

### 5. Stage & Commit
1. Stage ONLY the modified source and test files relevant to this ticket.
2. Commit changes using the script: `./scripts/git-commit.sh "<TICKET_ID>: <why-focused message>"`.

### 6. Push & Pull Request
1. Run `./scripts/git-push.sh` to push the branch to the remote repository.
2. Run `./scripts/git-pr.sh` to open a pull request against the default branch.
3. Display the pull request URL.

### 7. Chat Notification
1. Prompt the user: "Would you like to notify the team on chat? (Yes/No)".
2. Ask for the channel/group to notify (or present options if known).
3. If confirmed, run `./scripts/notify-chat.sh "<PR_URL>" "<TICKET_ID>" "<CHANNEL>"`.

### 8. Close Out
1. Mark the ticket as **Done** in `.local/progress.md`.
2. Report completion and ask for the next ticket.
