# Growing the System & Customization

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
