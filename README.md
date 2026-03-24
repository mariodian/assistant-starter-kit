# Assistant Starter Kit

A pre-built configuration that gives Claude Code or OpenCode persistent memory, security guardrails, and structured workflows. Clone, run `setup.sh`, and your next session picks up where the last one left off.

## How It Works

Claude Code reads `~/.claude/` at startup. OpenCode reads `~/.config/opencode/`. This kit installs minimal global config to both locations — rules, security hooks, and a pointer to your workspace. Shared skills and agents live in `~/.agents/`. The workspace (`~/claude-assistant/`) holds everything else: knowledge, tasks, state, and session history.

```
~/.claude/ (global, Claude Code)       ~/.agents/ (shared)
├── CLAUDE.md (pointer)                ├── skills/ (9 skills)
├── settings.json (hooks)              └── agents/ (5 definitions)
├── rules/ (behavioral)
├── scripts/ (4 hook scripts)
└── statusline.sh

~/claude-assistant/ (workspace)
├── .claude/CLAUDE.md (detailed)
├── .claude/skills/ -> ~/.agents/skills/
├── .claude/agents/ -> ~/.agents/agents/
├── knowledge/ (on-demand)
├── scripts/ (db, learnings)
├── state/ (sessions, backlog)
├── MEMORY.md (200 lines)
└── tasks.db (SQLite)
```

**On-demand loading avoids context bloat.** The workspace CLAUDE.md contains a table of file paths and one-line descriptions. Claude sees the table at startup (~20-30 lines), then opens specific files when relevant. A typical session loads 3-5 files.

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

## Setup (5 minutes)

```bash
git clone https://github.com/mp-web3/assistant-starter-kit.git
cd assistant-starter-kit
./setup.sh
```

The script detects your OS, asks which agent (Claude Code or OpenCode), installs dependencies, collects your name/bio/workspace path, and installs files in two phases: global config + workspace bootstrap.

Then start your first session:

```bash
cd ~/claude-assistant
claude   # or: opencode
```

Type `/onboard` — your assistant walks you through defining your profile, problems, goals, and tasks. Takes 20-30 minutes. Saves progress after every step, so you can disconnect and resume anytime.

## Self-Improvement Loop

```
Session work -> Assistant notices correction -> Writes to knowledge file -> Commits
Next session -> Assistant reads the file -> Doesn't repeat the mistake
```

Same correction twice -> gets promoted to a rule (always-loaded, every session). Run `/reflect` periodically to formalize this.

## Documentation

- [Requirements](docs/requirements.md) — dependencies, platform support
- [Directory Structure](docs/directory-structure.md) — full file tree with descriptions
- [Security Guard](docs/security-guard.md) — how the Claude Code safety hooks work
- [Rules & Agents](docs/rules-and-agents.md) — behavioral rules and pre-built agent definitions
- [Customization](docs/customization.md) — growing the system, tuning settings, project-specific rules

## Credits

Forked from [mp-web3/claude-starter-kit](https://github.com/mp-web3/claude-starter-kit) by [Mattia Papa](https://mattiapapa.dev/).

## License

MIT
