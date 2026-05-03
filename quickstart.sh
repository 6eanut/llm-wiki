#!/bin/bash
# quickstart.sh — One-command LLM Wiki setup with demo content
# Usage: ./quickstart.sh [--with-hooks] [--no-demo]
#   --with-hooks   Enable SessionStart/SessionStop hooks for richer experience
#   --no-demo      Skip creating demo source files
# Exit: 0 on success, 1 on error

set -euo pipefail

# ── Colour helpers ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

success() { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}!${NC} %s\n" "$*"; }
error()   { printf "${RED}✗${NC} %s\n" "$*" >&2; }
info()    { printf "${CYAN}→${NC} %s\n" "$*"; }

# ── Argument parsing ────────────────────────────────────────────────────────

WITH_HOOKS=false
NO_DEMO=false

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            cat << 'USAGE'
Usage: ./quickstart.sh [--with-hooks] [--no-demo]

Set up LLM Wiki in ONE command.

What it does:
  1. Installs the llm-wiki skill globally (~/.claude/skills/llm-wiki/)
  2. Initializes the wiki directory (./wiki/)
  3. Sets up CLAUDE.md with wiki instructions
  4. Optionally creates demo source files (Greek mythology)

Options:
  --with-hooks   Enable SessionStart/SessionStop hooks
  --no-demo      Skip creating demo source files
  --help, -h     Show this help message

After running, start Claude Code and run:
  /wiki-ingest .raw/greek-olympians.md
USAGE
            exit 0 ;;
        --with-hooks) WITH_HOOKS=true ;;
        --no-demo)    NO_DEMO=true ;;
        *)            error "Unknown option: $arg (use --help for usage)"; exit 1 ;;
    esac
done

# ── Find the skill source directory ─────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/llm-wiki"

if [ ! -f "$SKILL_SRC/SKILL.md" ]; then
    error "Cannot find llm-wiki skill at: $SKILL_SRC"
    error "Make sure you run quickstart.sh from the llm-wiki project root."
    exit 1
fi

# ── Banner ──────────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo "${BOLD}║${NC}   ${BOLD}LLM Wiki — Quick Start${NC}                      ${BOLD}║${NC}"
echo "${BOLD}║${NC}   Compounding Knowledge Base for Claude Code  ${BOLD}║${NC}"
echo "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Install the skill globally ──────────────────────────────────────

echo "${BOLD}Step 1/4:${NC} Installing skill globally..."
if [ -d "$HOME/.claude/skills/llm-wiki" ]; then
    warn "Skill already installed — updating..."
    rm -rf "$HOME/.claude/skills/llm-wiki"
fi
mkdir -p "$(dirname "$HOME/.claude/skills/llm-wiki")"
cp -r "$SKILL_SRC" "$HOME/.claude/skills/llm-wiki"
chmod +x "$HOME/.claude/skills/llm-wiki/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/skills/llm-wiki/hooks/"*.sh 2>/dev/null || true

# Install slash commands
COMMANDS_DST="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DST"
for cmd in "$HOME/.claude/skills/llm-wiki/commands"/*.md; do
    if [ -f "$cmd" ]; then
        cp "$cmd" "$COMMANDS_DST/"
    fi
done
success "Skill installed globally"

# ── Step 2: Initialize wiki ─────────────────────────────────────────────────

echo ""
echo "${BOLD}Step 2/4:${NC} Initializing wiki..."
HOOK_FLAG=""
if [ "$WITH_HOOKS" = true ]; then
    HOOK_FLAG="--with-hooks"
fi

bash "$HOME/.claude/skills/llm-wiki/scripts/setup-project.sh" ./wiki $HOOK_FLAG
success "Wiki initialized at ./wiki/"

# ── Step 3: Create .raw/ with demo sources ──────────────────────────────────

echo ""
echo "${BOLD}Step 3/4:${NC} Creating .raw/ directory..."

mkdir -p ./.raw

if [ "$NO_DEMO" = false ]; then
    DEMO_SRC="$SCRIPT_DIR/.raw"
    if [ "$DEMO_SRC" -ef "./.raw" ]; then
        # Already in the project directory — files are already in place
        if [ -f "./.raw/greek-olympians.md" ] && [ -f "./.raw/perseus-medusa.md" ]; then
            success "Demo source files already in place"
        else
            warn "Demo source files missing from .raw/ — skipping"
        fi
    elif [ -f "$DEMO_SRC/greek-olympians.md" ] && [ -f "$DEMO_SRC/perseus-medusa.md" ]; then
        cp "$DEMO_SRC/greek-olympians.md" ./.raw/
        cp "$DEMO_SRC/perseus-medusa.md" ./.raw/
        success "Demo source files copied to .raw/"
    else
        warn "Demo source files not found at $DEMO_SRC — skipping"
    fi
else
    info "Skipped demo files (--no-demo)"
fi

# ── Step 4: Verify ──────────────────────────────────────────────────────────

echo ""
echo "${BOLD}Step 4/4:${NC} Verification..."

ALL_OK=true

# Check skill installation
if [ -f "$HOME/.claude/skills/llm-wiki/SKILL.md" ]; then
    success "Skill verified"
else
    error "Skill installation failed"
    ALL_OK=false
fi

# Check wiki directory
if [ -d "./wiki/.llm-wiki" ]; then
    success "Wiki directory verified"
else
    error "Wiki directory not found"
    ALL_OK=false
fi

# Check CLAUDE.md
if grep -q "LLM Wiki" ./CLAUDE.md 2>/dev/null; then
    success "CLAUDE.md verified"
else
    warn "CLAUDE.md may not have wiki instructions"
fi

# Check hooks
if [ "$WITH_HOOKS" = true ]; then
    if [ -f "./.claude/settings.local.json" ]; then
        success "Hooks configured"
    else
        warn "Hooks file not found"
    fi
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo "${BOLD}║${NC}   ${GREEN}Setup Complete!${NC}                           ${BOLD}║${NC}"
echo "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

if [ "$NO_DEMO" = false ] && [ -f "./.raw/greek-olympians.md" ]; then
    echo "${BOLD}Try it now:${NC}"
    echo ""
    echo "  ${CYAN}1.${NC} Start Claude Code in this directory"
    echo "  ${CYAN}2.${NC} Run: ${BOLD}/wiki-ingest .raw/greek-olympians.md${NC}"
    echo "  ${CYAN}3.${NC} Ask: ${BOLD}\"What is the relationship between Zeus and Athena?\"${NC}"
    echo "  ${CYAN}4.${NC} Then ingest the second file and watch your knowledge compound!"
    echo ""
    echo "  ${CYAN}5.${NC} Run: ${BOLD}/wiki-ingest .raw/perseus-medusa.md${NC}"
    echo "  ${CYAN}6.${NC} Ask: ${BOLD}\"Why was Medusa cursed?\"${NC}"
    echo "  ${CYAN}7.${NC} Run: ${BOLD}/wiki-graph${NC} to see your knowledge network"
    echo ""
else
    echo "${BOLD}Next steps:${NC}"
    echo "  - Drop source files in ./.raw/"
    echo "  - Run /wiki-ingest <file>"
    echo "  - Ask questions naturally — Claude checks the wiki first!"
    echo ""
fi

echo "${BOLD}Commands:${NC} /wiki, /wiki-ingest, /wiki-query, /wiki-lint, /wiki-save, /wiki-graph, /wiki-review"
echo ""

if [ "$ALL_OK" = false ]; then
    exit 1
fi
