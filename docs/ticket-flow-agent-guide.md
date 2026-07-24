# Ticket Flow Agent — Fast-track guide for developers

A practical pattern for turning “work this ticket” into a repeatable Cursor agent workflow: fetch the issue, branch, implement with tests, stop for a human **Confirm**, then commit, open a PR, and optionally notify chat — without building a platform.

Share this with other eng teams that want the same discipline in their own repos and trackers.

---

## 1. What this is

**Ticket Flow** is a thin orchestration layer, not a product:

| Piece | Role |
|-------|------|
| **Cursor skill** (`SKILL.md`) | The checklist: steps, gates, wording, branch naming |
| **Always-on rule** (`.mdc`) | Routes trigger phrases to that skill so the agent does not freestyle |
| **Thin script wrappers** | Call existing git / issue-tracker / chat CLIs — no duplicated business logic |
| **Human gates** | Mandatory stop before commit/PR ship and before chat notify |
| **Local progress board** | Gitignored markdown queue for morning multi-ticket runs |

You keep product standards in each app’s own rules. Ticket Flow only sequences *how* work moves from ticket ID → merged change.

```text
User phrase  →  rule loads skill  →  scripts + product repos  →  Confirm  →  commit/PR  →  ask before chat
```

---

## 2. Why bother (vs ad-hoc Plan/Build chat)

Ad-hoc chat (“plan then build ticket X”) often burns retries: wrong branch, forgotten tests, premature commit, PR text that mentions tools, Slack spam, or a consumer bump before the shared package is ready. Each recovery costs more turns and tokens.

A Ticket Flow skill front-loads the path once:

- Same fetch → branch → implement+tests → **Confirm** → commit → push/PR → ask chat → optional consumer bump
- Fewer “what should I do next?” loops
- Safer defaults (stage only ticket paths; no silent notify; no AI mentions in PR copy)

Conceptual comparison (effort / retries / tokens):

![Ad-hoc agent chat vs ticket-flow cost](assets/agent-chat-vs-ticket-flow-cost.png)

And the day-to-day shape of the agent once the checklist is in place:

![Ticket flow agent — easy path](assets/ticket-flow-agent-easy.png)

You are not automating judgment away — you are automating *sequence and gates* so judgment happens at the right moments.

---

## 3. Building blocks

### Cursor skill

One `SKILL.md` with:

- Trigger phrases (`fix bug PROJ-123`, `work on PROJ-123`, morning task lists with IDs)
- Hard rules (Confirm, PR tone, staging discipline, tests)
- Numbered checklist the agent copies and ticks
- Stop-and-wait table for every human gate

### Always-on rule triggers

A short always-applied rule that says: when the user uses those phrases, **load and follow** the skill. Keep naming glossary and “never skip Confirm” in the rule so even a partial skill load stays safe.

Optional companion rule for handoff: pasteable **Impact Area** + “tests required with the change.”

### Script wrappers

Prefer `scripts/` in a workflow repo (or monorepo tooling folder) that forward to your existing CLIs:

| Step | Wrapper idea |
|------|----------------|
| Fetch issue | `issue-get` → Jira/Linear/GitHub Issues CLI |
| Branch | `git-branch` (multi-repo if needed) |
| Commit / push / PR | thin forwards to your git host CLI |
| Chat notify | webhook or MCP — **only after explicit yes + channel** |

Do not reimplement pack/CLI logic inside the skill. On script failure: report the error envelope, offer documented recovery options, do not invent workarounds.

### Progress board (local, gitignored)

Copy a template → `.local/progress.md` (or similar). Update as tickets move In progress → Done. Enough for a morning queue without a dashboard.

---

## 4. Naming glossary pattern

Teams confuse “the app,” “the suite,” and “the shared UI package.” Put a **user glossary** in the skill so chat language maps to repos:

| User says | Means |
|-----------|--------|
| **Primary app** | The main product repo only |
| **Product suite** | Primary app + sibling product repos in the same family |
| **Suite + shared UI** | Those products **plus** the shared UI/component package |

Rule of thumb: the shared UI package is **not** “the primary app” and **not** “the suite,” but when the skill says “shared UI first,” prefer changing the package there, then bump consumers.

Customize the table to your org’s nicknames — the pattern matters more than the labels.

---

## 5. Checklist workflow

Process **one ticket at a time** unless the user asks otherwise.

### 0. Queue / progress

- Record the ticket on the progress board as **In progress**
- Morning list: parse all IDs; work serially

### 1. Fetch issue

- Pull summary, description, type, status, acceptance criteria
- Classify **bug** vs **feature** (issue type + user wording; “fix bug” → bugfix)

### 2. Branch from latest main

| Classification | Branch |
|----------------|--------|
| Bug | `bugfix/PROJ-123` |
| Feature / story / task | `feature/PROJ-123` |

Prefer the primary change surface first (often the shared UI package). Do not branch unrelated dirty repos.

### 3. Implement + tests

- Follow that product’s Cursor rules / `AGENTS.md`
- Implement the fix or feature
- **Add or update tests** for every behavior / selector / API change in the same change set
- Run relevant unit/typecheck tests when practical
- Keep scope tied to the ticket — no drive-by refactors

**UI layout / wizard bugs:** reproduce in the running app (exact route + step or screenshot); verify create **and** edit and every wizard step; prefer root-cause over cosmetic icon shuffles; assert the failure mode in tests.

### 4. Validation gate (STOP)

Do **not** commit yet. Present summary + Impact Area, then ask for **Confirm** (prefer Yes/No choice UI when available):

```text
Please validate the changes for PROJ-123 in <repos>.
Summary: <what changed>
Impact Area:
- App: …
- Surfaces: … (pages / flows / nav)
- Components / APIs: …
- Regression risk: … (optional)
Reply Confirm to commit with `PROJ-123: <proposed message>`, or tell me what to adjust.
```

Never treat silence as Confirm.

### 5. Commit (after Confirm only)

- Message format: `PROJ-123: <short why-focused message>`
- Stage **only** ticket-relevant product/test paths
- No secrets; no local-only helpers unless the user explicitly asks

### 6. Push, PR, ask before chat

- Push and open PR vs `main` (or your default base)
- PR title/description: human summary + test plan; **never** mention AI, Cursor, agents, or automation tooling
- After PR URL is known: **STOP** — ask whether to post to chat (**Yes/No**) **and which channel/group** (multi-choice if known, else free text). Show the proposed message. Post only after channel chosen + explicit yes. If notify fails, still offer copy-paste text when they opt in.

Example chat shape:

```text
HI Devs - Can you please review this PR? <PR_URL> about <ISSUE_URL>
```

### 7. Consumer package bump (if needed)

When the change landed in a shared package:

1. Wait until merge/publish path is clear
2. Branch the same `bugfix/PROJ-123` or `feature/PROJ-123` in the consumer
3. Bump dependency (registry version or interim local artifact per your workflow)
4. Update tests if needed
5. Same **Confirm** → commit → push → PR → ask chat again

### 8. Close out

- Mark **Done** on the progress board
- Start the next queued ticket or ask the user

---

## 6. Hard rules

1. **Confirm before every commit and every PR that ships code.** Prefer choice UI for yes/no gates; else chat text.
2. **No AI / agent / Cursor mentions in PR titles or descriptions.**
3. **Stage only ticket-relevant files.** Leave unstaged: seed/sample scripts, one-off validate/measure harnesses, local tarball pins, personal notes, unrelated WIP. Prefer path-scoped staging over `git add -A`.
4. **Reproduce UI bugs in the running app** before calling the fix done — do not rely only on the ticket wording.
5. **Prefer root-cause fixes** (layout systems, wrong-step visibility, overflow) over surface-level rearrangements.
6. **Assert failure modes in tests** so regressions cannot slip quietly.
7. **Always include Impact Area** at validation and PR/story handoff (pasteable into the tracker).
8. **Tests ship with the change** unless the user explicitly waives them.
9. **Ask before chat notify** — never auto-post; never invent a default channel.
10. **Never force-push** protected defaults (`main` / `master`). Never push secrets.
