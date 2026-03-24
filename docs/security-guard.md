# Security Guard (Claude Code only)

OpenCode does not support hooks yet, so the security guard only works with Claude Code. OpenCode users should rely on the `opencode.json` permission system instead (see [Directory Structure — OpenCode Config](directory-structure.md#opencode-config-opencodeconfigopencode)).

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
