# Rules System & Agent Definitions

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
