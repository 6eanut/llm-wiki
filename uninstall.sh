#!/bin/bash
# uninstall.sh — Uninstall LLM Wiki skill from Claude Code
# Usage: uninstall.sh [--force]
# Removes the skill directory and wiki slash commands
# Exit: 0 on success, 1 on error

set -euo pipefail

# ── Colour helpers ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

success() { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}!${NC} %s\n" "$*"; }
error()   { printf "${RED}✗${NC} %s\n" "$*" >&2; }

# ── Argument parsing ────────────────────────────────────────────────────────

FORCE=false

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            cat <<'USAGE'
Usage: uninstall.sh [--force]

Uninstall the LLM Wiki skill from Claude Code.

Removes:
  • ~/.claude/skills/llm-wiki/     (skill directory)
  • ~/.claude/commands/wiki-*.md   (slash commands)

Options:
  --force     Skip confirmation prompt
  --help, -h  Show this help message
USAGE
            exit 0 ;;
        --force) FORCE=true ;;
        *)       error "Unknown option: $arg (use --help for usage)"; exit 1 ;;
    esac
done

# ── Paths ───────────────────────────────────────────────────────────────────

SKILL_DIR="$HOME/.claude/skills/llm-wiki"
COMMANDS_DIR="$HOME/.claude/commands"

# ── Pre-flight check ────────────────────────────────────────────────────────

FOUND_ANYTHING=false

if [ -d "$SKILL_DIR" ]; then
    FOUND_ANYTHING=true
fi

if ls "$COMMANDS_DIR"/wiki-*.md >/dev/null 2>&1; then
    FOUND_ANYTHING=true
fi

if [ "$FOUND_ANYTHING" = false ]; then
    echo ""
    warn "No LLM Wiki installation found. Nothing to uninstall."
    exit 0
fi

# ── What will be removed ────────────────────────────────────────────────────

echo ""
echo "${BOLD}LLM Wiki — Uninstall${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "$SKILL_DIR" ]; then
    echo "  Skill directory:"
    echo "    ${YELLOW}$SKILL_DIR${NC}"
fi

if ls "$COMMANDS_DIR"/wiki-*.md >/dev/null 2>&1; then
    echo "  Slash commands:"
    for f in "$COMMANDS_DIR"/wiki-*.md; do
        if [ -f "$f" ]; then
            echo "    ${YELLOW}$f${NC}"
        fi
    done
fi

echo ""

# ── Confirmation ────────────────────────────────────────────────────────────

if [ "$FORCE" != true ]; then
    read -r -p "Remove the above? [y/N] " CONFIRM
    case "$CONFIRM" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

# ── Removal ─────────────────────────────────────────────────────────────────

echo ""

REMOVED_ITEMS=0

# 1. Remove skill directory
if [ -d "$SKILL_DIR" ]; then
    rm -rf "$SKILL_DIR"
    success "Removed skill directory"
    REMOVED_ITEMS=$((REMOVED_ITEMS + 1))
else
    warn "Skill directory not found (already removed?)"
fi

# 2. Remove wiki command files
if ls "$COMMANDS_DIR"/wiki-*.md >/dev/null 2>&1; then
    for f in "$COMMANDS_DIR"/wiki-*.md; do
        if [ -f "$f" ]; then
            rm -f "$f"
            success "Removed $(basename "$f")"
            REMOVED_ITEMS=$((REMOVED_ITEMS + 1))
        fi
    done
else
    warn "No wiki command files found (already removed?)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}Uninstall complete${NC}"
printf "  ${GREEN}%d item(s) removed${NC}\n" "$REMOVED_ITEMS"
echo ""
echo "The LLM Wiki skill and its slash commands have been removed."
echo "Your project wiki directories (./wiki/) are untouched."
exit 0
