# Requirements

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
