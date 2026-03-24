# Assistant Starter Kit

A pre-built configuration that gives Claude Code or OpenCode persistent memory, security guardrails, and structured workflows. Clone, run `setup.sh`, and your next session picks up where the last one left off.

## Table of Contents

- [How It Works](#how-it-works)
- [What's Included](#whats-included)
- [Requirements](#requirements)
- [Setup (5 minutes)](#setup-5-minutes)
- [Directory Structure](#directory-structure)
  - [Global Config (~/.claude/)](#global-config-claude)
  - [Shared Skills & Agents (~/.agents/)](#shared-skills--agents-agents)
  - [OpenCode Config (~/.config/opencode/)](#opencode-config-opencodeconfigopencode)
  - [Workspace (~/claude-assistant/)](#workspace-claude-assistant)
- [Security Guard (Claude Code only)](#security-guard-claude-code-only)
- [Rules System](#rules-system)
- [Agent Definitions](#agent-definitions)
- [Self-Improvement Loop](#self-improvement-loop)
- [Growing the System](#growing-the-system)
- [Customization](#customization)
- [Credits](#credits)

## How It Works

Claude Code reads `~/.claude/` at startup. OpenCode reads `~/.config/opencode/`. This kit installs minimal global config to both locations — rules, security hooks, and a pointer to your workspace. Shared skills and agents live in `~/.agents/`. The workspace (`~/claude-assistant/`) holds everything else: knowledge, tasks, state, and session history.

```
You run setup.sh ──> Phase 1: Config to ~/.claude/ + ~/.agents/
                     Phase 2: Full workspace at ~/claude-assistant/

~/.claude/ (global, Claude Code)       ~/.agents/ (shared)
├── CLAUDE.md (pointer)                ├── skills/ (9 skills)
├── settings.json (hooks, Claude Code only) └── agents/ (5 definitions)
├── rules/ (behavioral)
├── scripts/ (4 hook scripts)
├── statusline.sh
└── workspace.conf

~/.config/opencode/ (OpenCode only)    ~/claude-assistant/ (workspace)
├── AGENTS.md (global standards)       ├── .claude/CLAUDE.md (detailed)
└── opencode.json (permissions)        ├── .claude/skills/ -> ~/.agents/skills/
                                       ├── .claude/agents/ -> ~/.agents/agents/
                                       ├── .opencode/ (OpenCode symlinks)
                                       ├── knowledge/ (on-demand)
                                       ├── scripts/ (db, learnings)
                                       ├── state/ (sessions, backlog)
                                       ├── MEMORY.md (200 lines)
                                       └── tasks.db (SQLite)
```

**Why the split?** `~/.claude/` is Claude Code's config directory — it should stay lean. Rules and hooks load every session regardless of project. Knowledge, tasks, and state live in the workspace, loaded only when you're working there. Skills and agents are shared via `~/.agents/`, symlinked into each workspace. This keeps config directories clean and your assistant data in a proper, version-controlled workspace.

**On-demand loading is how this avoids context bloat.** The workspace CLAUDE.md contains a table of file paths and one-line descriptions. Claude sees the table at startup (~20-30 lines), then uses `Read` to open specific files when relevant. A typical session loads 3-5 files out of however many you have.

## What's Included

| Component                              | What It Does                                                                                                        |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `/onboard`                             | 20-30 min guided setup: profile, 12 Favorite Problems, goals, tasks                                                 |
| `/tasks`                               | SQLite-backed task management. Tasks connect to your goals and problems                                             |
| `/plan`                                | 6-phase gated workflow: explore, discover tools, design, approve, implement, verify                                 |
| `/reflect`                             | Extracts corrections and preferences from sessions, routes them to the right files                                  |
| `/bootstrap`                           | Sets up any project's `.claude/` for agentic development                                                            |
| `/create-skill`                        | Scaffolds new skills with validation — extend the system with your own workflows                                    |
| `/deploy`                              | Deployment workflow for production and staging environments                                                         |
| `/security-review`                     | Comprehensive security audit — SQL injection, credentials, auth gaps                                                |
| Security guard (Claude Code only)      | Blocks secrets access, force-push, writes outside `$HOME`, `rm -rf`. Audit log at `~/.claude/state/guard-log.jsonl` |
| Permission system (OpenCode only)      | Declarative allow/deny rules for bash, edit, read in `opencode.json`                                                |
| Session persistence (Claude Code only) | Pre-compact hook saves state, post-compact hook re-injects critical rules. Session reminders after 10 min           |
| Delegation rules                       | Subagent orchestration: authority boundaries, knowledge flow, quality control                                       |
| Agent definitions                      | 5 pre-built agents: code-reviewer, bug-fixer, implementer, researcher, refactor                                     |
| Development standards                  | Code quality limits, testing philosophy, commit conventions                                                         |
| Radical honesty                        | No flattery, no hype — specific praise when earned, problems first                                                  |

## Requirements

| Dependency                                                                                           | Minimum | Why                                                  | Install                                                                                                                              |
| ---------------------------------------------------------------------------------------------------- | ------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) or [OpenCode](https://opencode.ai) | latest  | Core runtime                                         | Claude: `npm i -g @anthropic-ai/claude-code` or `brew install claude-code`. OpenCode: `npm i -g opencode` or `brew install opencode` |
| Git                                                                                                  | 2.x     | Version control for config and workspace             | Pre-installed on macOS; `apt install git` on Linux                                                                                   |
| Python                                                                                               | 3.10+   | Security guard, task database, learning extractor    | Pre-installed on macOS; `apt install python3` on Linux                                                                               |
| jq                                                                                                   | 1.6+    | Statusline and hook scripts                          | `brew install jq` / `apt install jq`                                                                                                 |
| SQLite                                                                                               | 3.x     | Task database — CLI used in rules/skills for queries | Pre-installed on macOS; `apt install sqlite3` on Linux                                                                               |
| Bash                                                                                                 | 4.x+    | Hook scripts                                         | Pre-installed                                                                                                                        |

**Optional:** `trash` (`brew install trash` on macOS, `apt install trash-cli` on Linux) — safe alternative to `rm -rf`, recommended by the security guard.

**Note:** Python's built-in `sqlite3` module handles database operations via `db.py`. The `sqlite3` CLI is used in rules and skills for quick inline queries.

**Supported platforms:** macOS, Linux. Windows via WSL should work but is untested.

## Setup (5 minutes)

```bash
git clone https://github.com/mp-web3/assistant-starter-kit.git
cd assistant-starter-kit
./setup.sh
```

The script:

1. Detects your OS and package manager
2. Asks which agent you're setting up (Claude Code or OpenCode)
3. Checks and installs dependencies
4. Asks for your name, bio, and workspace directory (default: `~/claude-assistant`)
5. Installs files in two phases: global config + workspace bootstrap

Then start your first session:

```bash
cd ~/claude-assistant
claude   # or: opencode
```

Type `/onboard` — your assistant walks you through defining your profile, problems, goals, and tasks. Takes 20-30 minutes. Saves progress after every step, so you can disconnect and resume anytime.

## Directory Structure

### Global Config (`~/.claude/`)

```
~/.claude/
├── CLAUDE.md                  # Minimal global instructions (points to workspace)
├── settings.json              # Hooks, permissions, security config
├── workspace.conf             # Path to workspace directory
├── rules/
│   ├── communication.md       # Radical honesty, verification, review protocol
│   ├── security.md            # Path boundaries, secrets, git discipline
│   ├── sessions.md            # Session start/end protocols, content routing
│   ├── tasks.md               # Task alignment, completion verification, operational rules
│   ├── delegation.md          # Subagent orchestration patterns
│   ├── development.md         # Code quality, testing, commits
│   └── research.md            # Source priority, endpoint verification, output format
├── scripts/
│   ├── global-guard.py        # Security: path boundaries, secrets blocking
│   ├── pre-compact.sh         # Saves state before context compression
│   ├── post-compact-reinject.sh # Re-injects critical rules after compaction
│   └── session-save-reminder.sh
└── statusline.sh              # Context %, cost, branch info
```

### Shared Skills & Agents (`~/.agents/`)

```
~/.agents/
├── skills/
│   ├── onboard/               # Guided first-session setup
│   ├── tasks/                 # SQLite-backed task management
│   ├── plan-and-implement/    # Structured build workflow
│   ├── reflect/               # Session learning extraction
│   ├── bootstrap/             # Project .claude/ setup
│   ├── create-skill/          # Skill scaffolding + validation
│   ├── deploy/                # Deployment workflow
│   └── security-review/       # Security audit
├── agents/
│   ├── code-reviewer.md       # Reviews diffs for bugs, security, style
│   ├── bug-fixer.md           # Investigates, reproduces, fixes bugs + writes tests
│   ├── implementer.md         # Implements features from a plan/spec
│   ├── researcher.md          # Explores codebases and docs, returns structured findings
│   └── refactor.md            # Safe, incremental code refactoring
```

### OpenCode Config (`~/.config/opencode/`)

```
~/.config/opencode/
├── AGENTS.md                  # Global standards (philosophy, communication style, user context)
└── opencode.json              # Permission rules: bash allow/deny, edit guards, read blocks
```

The `opencode.json` file provides declarative permission control:

- **Bash:** Denies `rm -rf`, `sudo`, `git push --force`, `git reset --hard`
- **Edit:** Blocks writes to `~/.bashrc`, `~/.zshrc`, `~/.ssh/*`
- **Read:** Blocks `.env`, SSH keys, cloud credentials, npm/pip/gem configs

### Workspace (`~/claude-assistant/`)

The `.claude/` directory inside the workspace is standard Claude Code project config — it holds the project-level CLAUDE.md and symlinks to global skills/agents. For OpenCode, the `.opencode/` directory mirrors this. Claude Code discovers skills from `<project>/.claude/skills/` automatically.

```
~/claude-assistant/
├── .claude/                   # Project-level Claude Code config
│   ├── CLAUDE.md              # Detailed workspace instructions
│   ├── skills/ -> ~/.agents/skills/   # Symlink to global skills
│   └── agents/ -> ~/.agents/agents/   # Symlink to global agents
├── .opencode/                 # Project-level OpenCode config (if using OpenCode)
│   ├── skills/ -> ~/.agents/skills/
│   └── agents/ -> ~/.agents/agents/
├── knowledge/                 # Claude reads these on demand
│   ├── self/identity.md       # AI self-knowledge (created by /onboard)
│   ├── user/profile.md        # Your profile (created by /onboard)
│   ├── user/goals.md          # Goals and subgoals (created by /onboard)
│   ├── problems/              # Your 12 problems (created by /onboard)
│   └── projects/              # Project-specific knowledge (grows over time)
├── scripts/
│   ├── db.py                  # SQLite task database
│   └── extract-learnings.py   # Session JSONL parser for /reflect
├── state/
│   ├── sessions/              # Session logs
│   ├── backlog.md             # Task backlog (auto-exported from SQLite)
│   └── rule-feedback.json     # Rule health counters (from /reflect)
├── MEMORY.md                  # Cross-session index (first 200 lines auto-loaded)
└── tasks.db                   # SQLite task store (gitignored)
```

## Security Guard (Claude Code only)

OpenCode does not support hooks yet, so the security guard only works with Claude Code. OpenCode users should rely on the `opencode.json` permission system instead (see [OpenCode Config](#opencode-config-opencodeconfigopencode)).

The guard script (`scripts/global-guard.py`) hooks into Claude Code's `PreToolUse` event — it runs before every tool call and can block dangerous operations.

| Category          | What's Blocked                                | Why                                   |
| ----------------- | --------------------------------------------- | ------------------------------------- |
| Path boundaries   | Reads/writes outside `$HOME` and `/tmp`       | Prevents system file modification     |
| Secrets           | `.env`, `.key`, `.pem`, `.secret` files       | Prevents accidental exposure          |
| Git safety        | `git push --force`, `git add` on secret files | Prevents data loss and secret commits |
| Destructive ops   | `rm -rf`                                      | Use `trash` instead (recoverable)     |
| Branch protection | Direct push to `main`/`master`                | Forces feature branch workflow        |

**How it works:** The guard is configured in `settings.json` as a `PreToolUse` hook. Claude Code sends the tool name and input as JSON to stdin. The script checks against its rules and returns `{"allow": true}` or `{"blocked": true, "reason": "..."}`. Claude sees the reason and adjusts.

Every blocked action is logged to `~/.claude/state/guard-log.jsonl` with timestamp, tool name, reason, and context. Review with:

```bash
cat ~/.claude/state/guard-log.jsonl | python3 -m json.tool
```

Customize by editing `~/.claude/scripts/global-guard.py` — add directory blocks, file extension rules, or stricter rules for company repos.

## Rules System

Rules in `~/.claude/rules/` are loaded every session, from every project. They constrain behavior across both Claude Code and OpenCode:

| Rule               | What It Does                                                           |
| ------------------ | ---------------------------------------------------------------------- |
| `communication.md` | Radical honesty, verify-before-assuming, review=revise, audit=fix      |
| `security.md`      | Hard blocks, git discipline, secrets management, project isolation     |
| `sessions.md`      | Start/end protocols, content routing table, context management         |
| `tasks.md`         | Task alignment checks, completion verification, operational guidelines |
| `delegation.md`    | Subagent authority boundaries, knowledge flow, quality control         |
| `development.md`   | Code quality limits, testing philosophy, commit conventions            |
| `research.md`      | Source priority, endpoint verification, synthesis rules                |

## Agent Definitions

The `agents/` directory (installed to `~/.agents/agents/`, symlinked into the workspace) contains pre-built agent definitions for common development tasks. These work with the Agent tool for delegating work to subagents.

| Agent           | Purpose                                                              | Writes Code?       |
| --------------- | -------------------------------------------------------------------- | ------------------ |
| `code-reviewer` | Reviews diffs for bugs, security issues, style violations, test gaps | No (read-only)     |
| `bug-fixer`     | Takes a symptom, reproduces, finds root cause, fixes + tests         | Yes                |
| `implementer`   | Implements features from a plan/spec in dependency order             | Yes                |
| `researcher`    | Explores codebases, reads docs, answers technical questions          | No (research only) |
| `refactor`      | Safe, incremental code refactoring — smells, risks, quality gates    | Yes                |

All agents follow the delegation rules: they can read, write, and test, but cannot commit, push, or make architectural decisions. Each agent produces structured output (status, summary, files changed, next steps) for the main session to review.

## Self-Improvement Loop

```
Session work -> Assistant notices correction -> Writes to knowledge file -> Commits
Next session -> Assistant reads the file -> Doesn't repeat the mistake
```

Same correction twice -> gets promoted to a rule (always-loaded, every session).

Run `/reflect` periodically to formalize this. It reads your session transcript, detects corrections and preferences, checks for contradictions with existing rules, and tracks which rules are helping vs hurting via feedback counters.

## Growing the System

The starter kit is minimal on purpose. As you use it:

- Your assistant creates knowledge files as it learns about your projects and preferences
- Session notes accumulate in `state/sessions/`, creating searchable history
- Rules evolve — corrections become rules, unhealthy rules get flagged by `/reflect`
- New skills can be added with `/create-skill` for workflows worth repeating
- `LEARNINGS.md` files in each skill capture what worked and what didn't
- Use `/bootstrap` to set up any project for agentic development
- Use `/deploy` and `/security-review` for deployment and audit workflows

The `knowledge/` directory is your assistant's brain. Commit and push it regularly.

## Customization

**Workspace location:** Set during `setup.sh`. Stored in `~/.claude/workspace.conf`. Default: `~/claude-assistant`.

**Project-specific rules:** Create `.claude/rules/my-rule.md` in any project directory. Loads only for that project.

**Deny rules (Claude Code):** Edit `~/.claude/settings.json` -> `permissions.deny` to block specific tools or commands globally.

**Permission rules (OpenCode):** Edit `~/.config/opencode/opencode.json` to adjust bash/edit/read allow/deny rules.

**Session reminder timing (Claude Code only):** Edit `~/.claude/scripts/session-save-reminder.sh` — change `600` (seconds) to adjust the threshold.

**Compaction prompt (Claude Code only):** Edit the PreCompact prompt hook in `~/.claude/settings.json` to customize what your assistant preserves during context compression.

**Development standards:** Edit `~/.claude/rules/development.md` to add your language-specific conventions, preferred linters, or stricter limits.

**Company repo protection:** Edit `~/.claude/rules/security.md` to add company-specific blocks (read-only repos, no autonomous push, etc.).

## Credits

Forked from [mp-web3/claude-starter-kit](https://github.com/mp-web3/claude-starter-kit) by [Mattia Papa](https://mattiapapa.dev/).

## License

MIT
