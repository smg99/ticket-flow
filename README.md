# Ticket Flow Agent

This repository contains the Ticket Flow agent workflow configurations, rules, scripts, and documentation. It is designed to establish a repeatable, high-discipline workflow for Cursor (and other agentic IDEs) inside your development team.

## Overview

**Ticket Flow** is a thin orchestration layer, not a product. It sequences *how* work moves from ticket ID → merged change with human gates at the right moments.

```text
User phrase  →  rule loads skill  →  scripts + product repos  →  Confirm  →  commit/PR  →  ask before chat
```

### Why use a structured workflow?

Ad-hoc chat ("plan then build ticket X") often burns retries: wrong branch, forgotten tests, premature commit, or Slack spam. A Ticket Flow skill front-loads the path once, reducing loops and tokens.

#### Ad-Hoc Agent Chat vs. Ticket Flow Cost
![Ad-hoc agent chat vs ticket-flow cost](docs/assets/agent-chat-vs-ticket-flow-cost.png)

#### Day-to-Day Agent Shape with Checklist
![Ticket flow agent — easy path](docs/assets/ticket-flow-agent-easy.png)

---

## Directory Structure

```text
ticket-flow/
├── README.md                   # Setup, overview and diagrams (this file)
├── .gitignore                  # Local progress tracker gitignore
├── .cursor/
│   ├── skills/
│   │   └── ticket-flow/
│   │       └── SKILL.md        # The step-by-step checklist the agent follows
│   └── rules/
│       ├── ticket-flow.mdc     # Rule that triggers the Ticket Flow skill
│       └── ticket-handoff.mdc  # Standard format for ticket handoff and tests
├── docs/
│   ├── ticket-flow-agent-guide.md   # Detailed team developer guide
│   ├── progress-template.md         # Template for morning multi-ticket queues
│   └── assets/                      # Guide diagrams and visual assets
└── scripts/                         # Wrapper scripts forwarding to your CLI tools
    ├── issue-get.sh                 # Fetch ticket description
    ├── git-branch.sh                # Create scoped branch
    ├── git-commit.sh                # Standardized commits
    ├── git-push.sh                  # Push code
    ├── git-pr.sh                    # Open pull request
    └── notify-chat.sh               # Post update to chat
```

## Quick Start (30-Minute Team Setup)

1. **Copy Rules to App Root (Optional):**
   If you want these rules to apply to the main app repository, copy `.cursor/rules/*.mdc` and `.cursor/skills/` to the root `.cursor` directory of your project repository, or configure your editor to point to this directory.
   
2. **Configure Script Wrappers:**
   Customize the helper scripts in `scripts/` to integrate with your project's issue tracker (e.g., Jira, Linear, GitHub Issues) and chat server (e.g., Slack, Discord, MS Teams).

3. **Initialize the Progress Board:**
   Copy `docs/progress-template.md` to `.local/progress.md` (which is already in the `.gitignore`) to track your daily active tickets locally without cluttering Git logs.

4. **Detailed Guide:**
   Read the full guide in [ticket-flow-agent-guide.md](docs/ticket-flow-agent-guide.md) to understand the workflow theory, glossary, and rules.
