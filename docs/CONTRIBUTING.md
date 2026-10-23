# Contributing

Thank you for improving Ticket Flow.

## What belongs here

- Generic workflow guidance, Cursor skill/rules, and thin script wrappers
- Synthetic examples only — no client tickets, code, credentials, or proprietary designs

## Local site

Open `index.html` in a browser, or serve the repo root with any static server. No build step.

## Checklist before a PR

1. Keep `.cursor/skills/ticket-flow/SKILL.md` aligned with the site’s `assets/flow-data.js` steps and hard rules.
2. Keep `docs/ticket-flow-agent-guide.md` aligned with the skill (guide may be longer; skill must not contradict it).
3. Scripts must fail loudly when unconfigured — never print fake ticket data or claim a chat send succeeded.
4. Verify keyboard focus and narrow-screen layout on the public site.
5. Do not mention AI tooling in sample commit/PR copy used as examples for agents to ship.

## Hosting

GitHub Pages publishes the repository root from `main`. The `.nojekyll` file skips Jekyll processing.
