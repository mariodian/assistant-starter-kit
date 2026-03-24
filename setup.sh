#!/bin/bash
set -euo pipefail

# Assistant Starter Kit — Setup Script
# Phase 1: Install minimal config to ~/.claude/ (rules, hooks, guard) and ~/.agents/ (skills + agents)
# Phase 2: Bootstrap ~/claude-assistant/ workspace (knowledge, skills, tasks, agents)

APP_NAME="Assistant Starter Kit"
APP_REPO=assistant-starter-kit

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_NAME=$(basename "$0")

DEFAULT_AGENT=claude
AVAILABLE_AGENTS=($DEFAULT_AGENT "opencode")

MEMORY_FILE=MEMORY.md

# Git
EXAMPLE_REPO_URL=https://github.com/YOUR_USERNAME/dotagents-assistant.git
INIT_GIT=0

# Claude Code specifig
CLAUDE_DIR_NAME=.claude
CLAUDE_DIR=$HOME/$CLAUDE_DIR_NAME
CLAUDE_CONFIG=settings.json

# OpenCode specifig
AGENT_DIR_NAME=.opencode
OPENCODE_DIR=$HOME/.config/opencode
OPENCODE_CONFIG=opencode.json

# Global agents and skills directory
DOTAGENTS_DIR=$HOME/.agents

echo "=== $APP_NAME ==="
echo ""

# -----------------------------------------------
# Step 1: Detect OS and package manager
# -----------------------------------------------

OS="unknown"
PKG_INSTALL=""

if [[ "$(uname)" == "Darwin" ]]; then
  OS="macos"
  if command -v brew >/dev/null 2>&1; then
    PKG_INSTALL="brew install"
  fi
elif [[ "$(uname)" == "Linux" ]]; then
  OS="linux"
  if command -v apt-get >/dev/null 2>&1; then
    PKG_INSTALL="sudo apt-get install -y"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_INSTALL="sudo dnf install -y"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_INSTALL="sudo pacman -S --noconfirm"
  fi
fi

echo "Detected: $OS"
echo ""

install_with_prompt() {
  local name="$1"
  local pkg="${2:-$1}"
  local install_cmd="${3:-}"

  if [[ -z "$install_cmd" && -z "$PKG_INSTALL" ]]; then
    echo "  x $name — not found. Install it manually and re-run setup."
    return 1
  fi

  local cmd="${install_cmd:-$PKG_INSTALL $pkg}"
  read -ep "  Install $name? ($cmd) [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    eval "$cmd"
    return $?
  else
    echo "  Skipped $name."
    return 1
  fi
}

read_with_default() {
  local prompt="$1"
  local default_value="$2"
  local output_var="$3"
  local input_value=""

  # macOS ships Bash 3.2 by default, which does not support `read -i`.
  if [[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]; then
    read -ep "$prompt" -i "$default_value" input_value
  else
    read -ep "$prompt" input_value
  fi

  printf -v "$output_var" '%s' "${input_value:-$default_value}"
}

is_agent_claude() {
  [[ "$AGENT_NAME" == "claude" ]]
}
is_agent_opencode() {
  [[ "$AGENT_NAME" == "opencode" ]]
}

# -----------------------------------------------
# Step 2: Choose assistant
# -----------------------------------------------
echo "Welcome to the $APP_NAME setup!"
echo ""
read_with_default "Which agentic tool are you setting up? (default: $DEFAULT_AGENT) " "$DEFAULT_AGENT" AGENT_NAME

# Validate agent choice
while [[ ! " ${AVAILABLE_AGENTS[*]} " =~ " $AGENT_NAME " ]]; do
  echo "Invalid choice. Available options: ${AVAILABLE_AGENTS[*]}"
  read_with_default "Which agentic tool are you setting up? (default: $DEFAULT_AGENT) " "$DEFAULT_AGENT" AGENT_NAME
done

if is_agent_claude; then
  echo "Setting up for Claude Code..."
  AGENT_DIR=$CLAUDE_DIR
elif is_agent_opencode; then
  echo "Setting up for OpenCode..."
  echo ""
  echo "Note: Claude configuration is a source of truth for scripts and rules."
  echo "      We'll still use $CLAUDE_DIR for config, but you'll run OpenCode CLI instead of Claude CLI."
  echo ""
  AGENT_DIR=$OPENCODE_DIR
fi

DEFAULT_ASSISTANT="$AGENT_NAME-assistant"

# -----------------------------------------------
# Step 3: Check and install dependencies
# -----------------------------------------------

echo "Checking dependencies..."
echo ""
MISSING=0

# --- Homebrew (macOS only) ---
if [[ "$OS" == "macos" ]] && ! command -v brew >/dev/null 2>&1; then
  echo "  x Homebrew — not found (needed to install other tools on macOS)"
  read -ep "  Install Homebrew? [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    PKG_INSTALL="brew install"
  else
    echo "  Without Homebrew, you'll need to install dependencies manually."
  fi
fi

# --- Git ---
if command -v git >/dev/null 2>&1; then
  echo "  ok git ($(git --version | head -c 20))"
else
  echo "  x git — not found"
  install_with_prompt "git" || MISSING=1
fi

# --- Python 3 ---
if command -v python3 >/dev/null 2>&1; then
  PY_VER=$(python3 --version 2>&1)
  echo "  ok python3 ($PY_VER)"
else
  echo "  x python3 — not found (needed for security guard and task database)"
  install_with_prompt "python3" "python3" || MISSING=1
fi

# --- jq ---
if command -v jq >/dev/null 2>&1; then
  echo "  ok jq ($(jq --version 2>&1))"
else
  echo "  x jq — not found (needed for statusline and hooks)"
  install_with_prompt "jq" || MISSING=1
fi

# --- trash (safe rm replacement) ---
if command -v trash >/dev/null 2>&1; then
  echo "  ok trash"
elif [[ "$OS" == "macos" ]]; then
  echo "  x trash — not found (safe alternative to rm -rf, moves to Trash)"
  install_with_prompt "trash" "trash" || true
elif [[ "$OS" == "linux" ]]; then
  echo "  x trash-cli — not found (safe alternative to rm -rf)"
  install_with_prompt "trash-cli" "trash-cli" || true
fi

# --- Claude Code CLI ---
if command -v $AGENT_NAME >/dev/null 2>&1; then
  echo "  ok $AGENT_NAME CLI"
else
  echo "  x $AGENT_NAME CLI — not found"
  if command -v brew >/dev/null 2>&1; then
    install_with_prompt "$AGENT_NAME" "" "brew install $AGENT_NAME" || MISSING=1
  elif command -v npm >/dev/null 2>&1; then
    if is_agent_claude; then
      install_with_prompt "$AGENT_NAME" "" "npm install -g @anthropic-ai/claude" || MISSING=1
    fi
    if is_agent_opencode; then
      install_with_prompt "$AGENT_NAME" "" "npm install -g $AGENT_NAME" || MISSING=1
    fi
  else
    if is_agent_claude; then
      echo "    Install Node.js first, then: npm install -g @anthropic-ai/claude-code"
      echo "    Or see: https://docs.anthropic.com/en/docs/claude-code"
      MISSING=1
    elif is_agent_opencode; then
      echo "    Install Node.js first, then: npm install -g $AGENT_NAME"
      echo "    Or see: https://opencode.ai/docs#install"
      MISSING=1
    fi
  fi
fi

echo ""

if [[ $MISSING -eq 1 ]]; then
  echo "Some required tools are missing. Install them and re-run ./$SCRIPT_NAME"
  exit 1
fi

echo "All dependencies OK."
echo ""

# -----------------------------------------------
# Step 4: Personalize
# -----------------------------------------------

echo "Let's personalize your assistant."
echo ""
read -ep "Your first name: " USER_NAME
read -ep "One-line bio (e.g., 'Python dev, building SaaS tools'): " USER_BIO

if [[ -z "$USER_NAME" || ${#USER_NAME} -lt 2 ]]; then
  echo "Error: name is required (at least 2 characters)"
  exit 1
fi

# --- Workspace directory ---
echo ""
read -ep "Workspace directory [~/$DEFAULT_ASSISTANT]: " WORKSPACE_INPUT
WORKSPACE_NAME="${WORKSPACE_INPUT:-$DEFAULT_ASSISTANT}"
# Strip leading ~/
WORKSPACE_NAME="${WORKSPACE_NAME#\~/}"
WORKSPACE_DIR="$HOME/$WORKSPACE_NAME"

# --- Workspace repo config ---
echo ""
read -ep "Initialize a git repository for your workspace? (recommended) [Y/n] " -n 1 -r
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  INIT_GIT=1
fi

if [[ $INIT_GIT -eq 1 ]]; then
  read -ep "What's your git repository URL? (e.g., $EXAMPLE_REPO_URL) " GIT_REPO_URL
  if [[ -n "$GIT_REPO_URL" ]]; then
    echo "Your workspace will be initialized with this remote: $GIT_REPO_URL"
  else
    echo "No remote URL provided. You can add it later with: git remote add origin $EXAMPLE_REPO_URL"
  fi
else
  echo "Git will not be initialized. You can add it later with: git init"
fi

echo ""

# -----------------------------------------------
# Step 5: Check for existing config
# -----------------------------------------------

if [[ -f "$CLAUDE_DIR/$CLAUDE_CONFIG" ]]; then
  echo "Warning: $CLAUDE_DIR/$CLAUDE_CONFIG already exists."
  read -ep "Merge? This will merge your current config with new settings. (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

if is_agent_opencode; then
  if [[ -f "$AGENT_DIR/$OPENCODE_CONFIG" ]]; then
    echo "Warning: $AGENT_DIR/$OPENCODE_CONFIG already exists."
    read -ep "Merge? This will merge your current config with new settings. (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
  fi
fi

if [[ -d "$WORKSPACE_DIR" ]]; then
  echo "Warning: $WORKSPACE_DIR already exists."
  read -ep "Overwrite? This will replace your workspace files. (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

echo "Setting up..."
echo ""

# ===============================================
# PHASE 1: Install minimal config to ~/.claude/ and ~/.agents/
# ===============================================

echo "Phase 1: Installing global config to $CLAUDE_DIR ..."

# Create directory structure
mkdir -p "$CLAUDE_DIR"/{rules,scripts,state}
mkdir -p "$DOTAGENTS_DIR"/{skills,agents}

# --- Copy scripts (hook scripts only) ---
cp "$SCRIPT_DIR/scripts/global-guard.py" "$CLAUDE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/pre-compact.sh" "$CLAUDE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/session-save-reminder.sh" "$CLAUDE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/post-compact-reinject.sh" "$CLAUDE_DIR/scripts/"
chmod +x "$CLAUDE_DIR/scripts/"*.sh "$CLAUDE_DIR/scripts/"*.py

# --- Copy rules ---
cp -r "$SCRIPT_DIR/rules/" "$CLAUDE_DIR/rules/"

# --- Merge or Copy settings.json ---
if [[ -f "$CLAUDE_DIR/$CLAUDE_CONFIG" ]]; then
  TEMP_SETTINGS=$(mktemp)
  jq -s '.[0] * .[1]' "$SCRIPT_DIR/templates/$CLAUDE_CONFIG" "$CLAUDE_DIR/$CLAUDE_CONFIG" > "$TEMP_SETTINGS"
  mv "$TEMP_SETTINGS" "$CLAUDE_DIR/$CLAUDE_CONFIG"
  echo "Settings merged."
else
  cp "$SCRIPT_DIR/templates/$CLAUDE_CONFIG" "$CLAUDE_DIR/$CLAUDE_CONFIG"
fi

if is_agent_opencode; then
  if [[ -f "$AGENT_DIR/$OPENCODE_CONFIG" ]]; then
    TEMP_SETTINGS=$(mktemp)
    jq -s '.[0] * .[1]' "$SCRIPT_DIR/templates/$OPENCODE_CONFIG" "$AGENT_DIR/$OPENCODE_CONFIG" > "$TEMP_SETTINGS"
    mv "$TEMP_SETTINGS" "$AGENT_DIR/$OPENCODE_CONFIG"
    echo "OpenCode settings merged."
  else
    cp "$SCRIPT_DIR/templates/$OPENCODE_CONFIG" "$AGENT_DIR/$OPENCODE_CONFIG"
  fi
fi

# --- Copy .gitignore ---
cp "$SCRIPT_DIR/templates/gitignore" "$CLAUDE_DIR/.gitignore"

# --- Copy statusline ---
cp "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/statusline.sh"

# --- Generate global CLAUDE.md ---
sed -e "s/{{USER_NAME}}/$USER_NAME/g" \
  -e "s|{{USER_BIO}}|$USER_BIO|g" \
  "$SCRIPT_DIR/templates/global-CLAUDE.md" > "$CLAUDE_DIR/CLAUDE.md"

if is_agent_opencode; then
  # --- Generate global AGENTS.md ---
  sed -e "s/{{USER_NAME}}/$USER_NAME/g" \
    -e "s|{{USER_BIO}}|$USER_BIO|g" \
    "$SCRIPT_DIR/templates/global-AGENTS.md" > "$AGENT_DIR/AGENTS.md"
fi

# --- Write workspace.conf ---
echo "$WORKSPACE_DIR" > "$CLAUDE_DIR/workspace.conf"

# --- Substitute workspace path in rules (replace ~/claude-assistant with actual) ---
if [[ "$WORKSPACE_NAME" != "$DEFAULT_AGENT-assistant" ]]; then
  for f in "$CLAUDE_DIR/rules/"*.md; do
    sed -i '' "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" "$f" 2>/dev/null || \
    sed -i "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" "$f"
  done

  # Also update global CLAUDE.md
  sed -i '' "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || \
  sed -i "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" "$CLAUDE_DIR/CLAUDE.md"

  # Also update global AGENT.md
  if ! is_agent_claude; then
    sed -i '' "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" "$AGENT_DIR/AGENTS.md" 2>/dev/null || \
    sed -i "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" "$AGENT_DIR/AGENTS.md"
  fi
fi

echo "  Global config installed."
echo ""

# ===============================================
# PHASE 2: Bootstrap workspace
# ===============================================

echo "Phase 2: Bootstrapping workspace at $WORKSPACE_DIR ..."

# Create directory structure
mkdir -p "$WORKSPACE_DIR"/{$CLAUDE_DIR_NAME,knowledge/self,knowledge/user,knowledge/problems,knowledge/projects,scripts,state/sessions}

if is_agent_opencode; then
  mkdir -p "$WORKSPACE_DIR/$AGENT_DIR_NAME"
fi

# --- Generate workspace CLAUDE.md ---
# No need to create one for opencode since it can read it automatically
sed -e "s/{{USER_NAME}}/$USER_NAME/g" \
  -e "s|{{USER_BIO}}|$USER_BIO|g" \
  "$SCRIPT_DIR/templates/workspace-CLAUDE.md" > "$WORKSPACE_DIR/$CLAUDE_DIR_NAME/CLAUDE.md"

# --- Copy agents ---
cp -r "$SCRIPT_DIR/agents/" "$DOTAGENTS_DIR/agents/"

# --- Copy workspace scripts ---
cp "$SCRIPT_DIR/scripts/db.py" "$WORKSPACE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/extract-learnings.py" "$WORKSPACE_DIR/scripts/"
chmod +x "$WORKSPACE_DIR/scripts/"*.py

# --- Copy skills ---
cp -r "$SCRIPT_DIR/skills/" "$DOTAGENTS_DIR/skills/"
chmod +x "$DOTAGENTS_DIR/skills/create-skill/scripts/"*.py

# --- Symlinks to .agents/ ---
ln -sf "$DOTAGENTS_DIR/skills" "$WORKSPACE_DIR/$CLAUDE_DIR_NAME"
ln -sf "$DOTAGENTS_DIR/agents" "$WORKSPACE_DIR/$CLAUDE_DIR_NAME"

if is_agent_opencode; then
  ln -sf "$DOTAGENTS_DIR/skills" "$WORKSPACE_DIR/$AGENT_DIR_NAME"
  ln -sf "$DOTAGENTS_DIR/agents" "$WORKSPACE_DIR/$AGENT_DIR_NAME"
fi

# --- Copy workspace .gitignore ---
cp "$SCRIPT_DIR/templates/workspace-gitignore" "$WORKSPACE_DIR/.gitignore"

# --- Substitute workspace path in skills (if non-default) ---
if [[ "$WORKSPACE_NAME" != "$DEFAULT_AGENT-assistant" ]]; then
  find "$WORKSPACE_DIR/$CLAUDE_DIR_NAME/skills" -name "SKILL.md" -exec \
    sed -i '' "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" {} \; 2>/dev/null || \
  find "$WORKSPACE_DIR/$CLAUDE_DIR_NAME/skills" -name "SKILL.md" -exec \
    sed -i "s|~/$DEFAULT_AGENT-assistant|~/$WORKSPACE_NAME|g" {} \;
fi

# --- Initialize task database and export backlog ---
python3 "$WORKSPACE_DIR/scripts/db.py" init
python3 "$WORKSPACE_DIR/scripts/db.py" export

# --- Create starter MEMORY.md ---
cat > "$WORKSPACE_DIR/$MEMORY_FILE" << 'MEMEOF'
# Auto-Memory

## Active Tasks

(Run `/tasks` or `/onboard` to populate)

## Active Projects

(Will grow as you work on projects)

## Next Up

1. Run `/onboard` to set up your profile, problems, goals, and tasks

## File Map

| Path | Content |
|---|---|
| `knowledge/user/profile.md` | Your profile (created by /onboard) |
| `knowledge/user/goals.md` | Goals and subgoals (created by /onboard) |
| `knowledge/problems/00-overview.md` | 12 problems overview (created by /onboard) |
| `knowledge/self/identity.md` | AI self-knowledge (created by /onboard) |
MEMEOF

echo "  Workspace created."
echo ""

# -----------------------------------------------
# Step 5: Initialize git repos
# -----------------------------------------------

if [[ $INIT_GIT -eq 1 ]]; then
   echo "Initializing git repositories..."

  # --- Global ~/.claude/ git ---
  if [[ ! -d "$CLAUDE_DIR/.git" ]]; then
    cd "$CLAUDE_DIR"
    git init
    git add \
      CLAUDE.md settings.json statusline.sh .gitignore workspace.conf \
      rules/ scripts/
    git commit -m "initial setup from $APP_REPO"
    echo ""
    echo "Git repo initialized at $CLAUDE_DIR"
  fi

  # --- Workspace git ---
  if [[ ! -d "$WORKSPACE_DIR/.git" ]]; then
      cd "$WORKSPACE_DIR"
      git init
      git add \
        "$CLAUDE_DIR_NAME/" .gitignore "$MEMORY_FILE" \
        scripts/ state/backlog.md \
        knowledge/
      git commit -m "initial setup from $APP_REPO"
      echo ""
      echo "Git repo initialized at $WORKSPACE_DIR"
  fi
fi

if [[ $INIT_GIT -eq 1 && -n "$GIT_REPO_URL" ]]; then
  echo "To back up your workspace, create a private repo and run:"
  echo "  cd $WORKSPACE_DIR && git remote add origin $GIT_REPO_URL && git push -u origin main"
fi

# -----------------------------------------------
# Done
# -----------------------------------------------
echo ""
echo "=== Setup complete ==="
echo ""
echo "Global config ($CLAUDE_DIR):"
echo "  CLAUDE.md      — global instructions (points to workspace)"
echo "  settings.json    — hooks + security"
echo "  rules/       — communication, security, sessions, tasks, delegation, development, research"
echo "  scripts/       — security guard, pre-compact, post-compact, session reminder"
echo "  statusline.sh    — context/cost display"
echo ""
echo "Agent config ($DOTAGENTS_DIR):"
echo "  skills/        — reusable skills (onboard, tasks, plan, reflect, bootstrap, create-skill)"
echo "  agents/        — agent definitions (code-reviewer, bug-fixer, implementer, researcher)"
echo ""
echo "Workspace ($WORKSPACE_DIR):"
echo "  $CLAUDE_DIR_NAME/CLAUDE.md  — workspace instructions"
echo "  $CLAUDE_DIR_NAME/skills/    — symlinks to global skills (onboard, tasks, plan, reflect, bootstrap, create-skill)"
echo "  $CLAUDE_DIR_NAME/agents/      — symlinks to global agents (code-reviewer, bug-fixer, implementer, researcher)"
if is_agent_opencode; then
echo "  $AGENT_DIR_NAME/skills/    — (OpenCode only) symlinks to global skills"
echo "  $AGENT_DIR_NAME/agents/      — (OpenCode only) symlinks to global agents"
fi
echo "  knowledge/       — your assistant's growing brain"
echo "  scripts/       — task database, learning extractor"
echo "  state/       — sessions, backlog"
echo "  $MEMORY_FILE      — cross-session index"
echo ""
echo "=== Next: Start your first session ==="
echo ""
echo "  cd ~/$WORKSPACE_NAME"
echo "  $AGENT_NAME"
echo ""
echo "Then type:"
echo "  /onboard"
echo ""
echo "This will walk you through a 20-30 minute guided setup:"
echo "  1. Build your user profile"
echo "  2. Define your 12 Favorite Problems (Feynman method)"
echo "  3. Set your end goal and subgoals"
echo "  4. Create initial tasks"
echo "  5. Set up the AI's self-knowledge"
echo ""
echo "You can pause anytime and resume later with: /onboard resume"
echo ""
