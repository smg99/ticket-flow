/* Ticket Flow stages. No client context is collected by the site. */
const playbookUrl = 'https://smg99.github.io/engineering-ai-playbook/';
const flowStages = [
  {
    id: 'queue',
    title: 'Queue & progress',
    when: 'You have one or more ticket IDs to work today.',
    input: 'Ticket IDs, optional morning list, local .local/progress.md.',
    output: 'Current ticket marked In progress on the private progress board.',
    gate: [
      'Progress board exists (copy docs/progress-template.md → .local/progress.md if needed).',
      'Exactly one ticket is In progress unless the user asked otherwise.'
    ],
    prompts: [
      {
        title: 'Start the queue',
        text: 'Run Ticket Flow for [TICKET_IDS]. Use .local/progress.md (create from docs/progress-template.md if missing). Mark the first ticket In progress. Process one ticket at a time. Load .cursor/skills/ticket-flow/SKILL.md and follow it without freestyling.'
      }
    ]
  },
  {
    id: 'fetch',
    title: 'Fetch issue',
    when: 'You have a ticket ID and need the real description and criteria.',
    input: '[TICKET_ID], configured ./scripts/issue-get.sh (or equivalent CLI).',
    output: 'Summary, description, acceptance criteria, and bug vs feature classification.',
    gate: [
      'Issue content came from the tracker (or the user pasted it)—not invented.',
      'Ticket classified as bugfix/* or feature/*.'
    ],
    prompts: [
      {
        title: 'Fetch and classify',
        text: 'Fetch [TICKET_ID] with ./scripts/issue-get.sh [TICKET_ID]. If the script is unconfigured or errors, stop and help wire the tracker—do not invent ticket content. Summarize title, description, AC, and classify as bug or feature from metadata or user wording (“fix bug” → bugfix).'
      }
    ]
  },
  {
    id: 'branch',
    title: 'Branch from main',
    when: 'The issue is understood and you are ready to change code.',
    input: 'Clean working tree on the primary change surface; latest main/master.',
    output: 'Branch bugfix/[TICKET_ID] or feature/[TICKET_ID] checked out.',
    gate: [
      'Working tree was clean before branching (or user explicitly handled dirty state).',
      'Branch name matches classification; base is updated main/master.'
    ],
    prompts: [
      {
        title: 'Create the branch',
        text: 'On the primary change surface (often shared UI first), ensure a clean tree. Run ./scripts/git-branch.sh [TICKET_ID] [bug|feature]. Prefer shared package changes before consumer bumps. Do not branch unrelated dirty repos.'
      }
    ]
  },
  {
    id: 'implement',
    title: 'Implement & test',
    when: 'You are on the ticket branch and ready to change behavior.',
    input: '[TICKET_ID] AC, project rules / AGENTS.md, test commands.',
    output: 'Scoped implementation plus tests (or an explicit user waiver).',
    gate: [
      'Behavior matches AC; UI bugs reproduced and verified in the running app.',
      'Tests added/updated asserting failure modes, or user waived tests explicitly.',
      'No drive-by refactors outside the ticket.'
    ],
    prompts: [
      {
        title: 'Implement with tests',
        text: 'Implement only [TICKET_ID] against its AC. Prefer root-cause fixes over cosmetics. Add or update tests for expected, negative, and boundary behavior. Run project test commands. For UI bugs: reproduce on the exact route/step, verify create and edit paths, assert the failure mode. Keep scope tied to the ticket.'
      }
    ]
  },
  {
    id: 'confirm-commit',
    title: 'Confirm before commit',
    when: 'Implementation and tests look ready to stage.',
    input: 'Diff of ticket-relevant files, test results, Impact Area draft.',
    output: 'Explicit user Confirm (or requested adjustments). Silence is not Confirm.',
    gate: [
      'User replied Confirm (or equivalent explicit yes) to the commit gate.',
      'Impact Area and proposed commit message were shown first.'
    ],
    prompts: [
      {
        title: 'Present commit gate',
        text: 'Do not commit yet. Present:\n\nPlease validate the changes for [TICKET_ID].\nSummary: [WHAT_CHANGED]\nImpact Area:\n- App: …\n- Surfaces: …\n- Components / APIs: …\n- Regression Risk: …\n- Tests: …\n\nReply Confirm to commit with `[TICKET_ID]: [WHY_MESSAGE]`, or tell me what to adjust.\n\nWait for explicit Confirm. Never treat silence as Confirm.'
      }
    ]
  },
  {
    id: 'commit',
    title: 'Stage & commit',
    when: 'The user confirmed the commit gate.',
    input: 'Confirmed message; ticket-relevant paths only.',
    output: 'One commit: [TICKET_ID]: why-focused message.',
    gate: [
      'Only ticket-relevant source/test paths were staged (no git add -A).',
      'Commit message has no AI/Cursor/agent mentions.'
    ],
    prompts: [
      {
        title: 'Commit scoped paths',
        text: 'Stage only ticket-relevant files. Run ./scripts/git-commit.sh "[TICKET_ID]: [WHY_MESSAGE]". Leave unstaged: local helpers, secrets, unrelated WIP. Never mention AI, Cursor, or agents in the message.'
      }
    ]
  },
  {
    id: 'confirm-pr',
    title: 'Confirm before PR',
    when: 'Commit exists and you are ready to push and open a PR.',
    input: 'Proposed PR title, Impact Area body, test plan, base branch.',
    output: 'Explicit user Confirm for push/PR. Silence is not Confirm.',
    gate: [
      'User explicitly confirmed the PR title and body.',
      'Body includes Impact Area and test plan; no AI tooling mentions.'
    ],
    prompts: [
      {
        title: 'Present PR gate',
        text: 'Before push/PR, show title, base branch, and body with Impact Area + test plan. Ask for Confirm. On Confirm only, continue to push and open the PR. Never treat silence as Confirm. Never mention AI, Cursor, or agents in the PR.'
      }
    ]
  },
  {
    id: 'push-pr',
    title: 'Push & open PR',
    when: 'The user confirmed the PR gate.',
    input: 'Feature/bugfix branch; gh or host CLI.',
    output: 'Remote branch + PR URL.',
    gate: [
      'Branch pushed (not main/master directly).',
      'PR opened with Impact Area body; URL shown to the user.'
    ],
    prompts: [
      {
        title: 'Push and create PR',
        text: 'Run ./scripts/git-push.sh then ./scripts/git-pr.sh (pass a body file if prepared). Show the PR URL. On script failure, report the error and stop—do not invent a PR.'
      }
    ]
  },
  {
    id: 'chat',
    title: 'Ask before chat notify',
    when: 'PR URL exists and the team might want a chat ping.',
    input: 'PR URL, ticket ID, user choice of channel.',
    output: 'Optional notify after Yes + channel; or skipped.',
    gate: [
      'User chose Yes/No; if Yes, they chose a channel (never invent a default).',
      'Draft message shown before send; failures still offer copy-paste.'
    ],
    prompts: [
      {
        title: 'Optional chat notify',
        text: 'Ask: notify the team on chat? (Yes/No). If Yes, ask which channel/group and show: “Hi Devs - Can you please review this PR? [PR_URL] about [TICKET_ID]”. Only then run ./scripts/notify-chat.sh "[PR_URL]" "[TICKET_ID]" "[CHANNEL]". If the script is unconfigured, offer the draft for copy-paste—do not claim it was sent.'
      }
    ]
  },
  {
    id: 'close',
    title: 'Close out / consumer bump',
    when: 'PR is open (and optional chat done).',
    input: 'Progress board; whether a shared package needs a consumer bump.',
    output: 'Ticket marked Done; next ticket asked—or consumer bump loop started.',
    gate: [
      'Progress board updated to Done for this ticket.',
      'If shared package changed: consumer bump uses the same branch name and Confirm gates.'
    ],
    prompts: [
      {
        title: 'Close or bump consumers',
        text: 'Mark [TICKET_ID] Done in .local/progress.md. If a shared package changed, wait for merge/publish clarity, then in each consumer: same bugfix|feature/[TICKET_ID], bump dependency, tests, Confirm→commit→Confirm→PR→ask chat. Otherwise ask for the next queued ticket.'
      }
    ]
  }
];

const hardRules = [
  'Confirm before every commit and before every PR. Silence is not Confirm.',
  'Never mention AI, Cursor, or agents in commits or PR copy.',
  'Stage only ticket-relevant files (no git add -A).',
  'Reproduce UI bugs in the running app before calling the fix done.',
  'Prefer root-cause fixes; assert failure modes in tests.',
  'Tests ship with the change unless the user explicitly waives them.',
  'Ask before chat notify; never invent a default channel.',
  'Never force-push protected defaults; never push secrets.',
  'On script failure: report the error—do not invent workarounds or fake success.'
];

const impactAreaTemplate = `## Impact Area
- **App:**
- **Surfaces:**
- **Components / APIs:**
- **Regression Risk:**
- **Tests:**

## Test plan
- [ ] Unit/integration tests pass
- [ ] Manual / UI verification (if applicable)
- [ ] No unrelated files in the diff`;

const glossary = [
  { term: 'Primary app', def: 'The main product repository only.' },
  { term: 'Product suite', def: 'Primary app plus sibling product repos in the same family.' },
  { term: 'Suite + shared UI', def: 'Those products plus the shared UI/component package. Shared UI is not “the app” and not “the suite.”' },
  { term: 'Confirm', def: 'Explicit human approval at a gate. Silence never counts.' },
  { term: 'Impact Area', def: 'Pasteable handoff: App, Surfaces, Components/APIs, Regression Risk, Tests.' }
];
