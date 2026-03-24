# Directory Structure

## Global Config (`~/.claude/`)

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

## Shared Skills & Agents (`~/.agents/`)

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

## OpenCode Config (`~/.config/opencode/`)

```
~/.config/opencode/
├── AGENTS.md                  # Global standards (philosophy, communication style, user context)
└── opencode.json              # Permission rules: bash allow/deny, edit guards, read blocks
```

The `opencode.json` file provides declarative permission control:

- **Bash:** Denies `rm -rf`, `sudo`, `git push --force`, `git reset --hard`
- **Edit:** Blocks writes to `~/.bashrc`, `~/.zshrc`, `~/.ssh/*`
- **Read:** Blocks `.env`, SSH keys, cloud credentials, npm/pip/gem configs

## Workspace (`~/claude-assistant/`)

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
