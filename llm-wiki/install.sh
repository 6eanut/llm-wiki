#!/bin/bash
# install.sh — Install LLM Wiki skill to Claude Code
# Usage: install.sh [--force]
# Copies the skill directory to ~/.claude/skills/llm-wiki/
# Exit: 0 on success, 1 on error

set -euo pipefail

FORCE=false
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: install.sh [--force]"
            echo "Install the LLM Wiki skill to ~/.claude/skills/llm-wiki/"
            echo "  --force     Overwrite existing installation"
            echo "  --help, -h  Show this help message"
            exit 0 ;;
        --force) FORCE=true ;;
        *)       echo "Unknown option: $arg (use --help for usage)" >&2; exit 1 ;;
    esac
done

SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DST="$HOME/.claude/skills/llm-wiki"

if [ -d "$SKILL_DST" ] && [ "$FORCE" != true ]; then
    echo "LLM Wiki skill is already installed at: $SKILL_DST"
    echo "Use --force to overwrite."
    exit 1
fi

echo "Installing LLM Wiki skill..."
echo "  Source: $SKILL_SRC"
echo "  Target: $SKILL_DST"

if [ -d "$SKILL_DST" ]; then
    rm -rf "$SKILL_DST"
fi

mkdir -p "$(dirname "$SKILL_DST")"
cp -r "$SKILL_SRC" "$SKILL_DST"

# Make scripts executable
chmod +x "$SKILL_DST/scripts/"*.sh 2>/dev/null || true
chmod +x "$SKILL_DST/hooks/"*.sh 2>/dev/null || true

# Install command files to ~/.claude/commands/
echo ""
echo "Installing slash commands..."
COMMANDS_DST="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DST"
COMMAND_COUNT=0
for cmd in "$SKILL_DST/commands"/*.md; do
    if [ -f "$cmd" ]; then
        cp "$cmd" "$COMMANDS_DST/"
        echo "  ✓ command: $(basename "$cmd" .md)"
        COMMAND_COUNT=$((COMMAND_COUNT + 1))
    fi
done
echo "  Installed $COMMAND_COUNT wiki commands"

# Verify installation
REQUIRED_FILES=("SKILL.md" "WIKI.md" "WIKI_SCHEMA.md" "scripts/init-wiki.sh" "scripts/setup-project.sh" "commands/wiki-ingest.md" "commands/wiki-query.md")
ALL_OK=true
for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SKILL_DST/$f" ]; then
        echo "  ✗ ERROR: Missing $f" >&2
        ALL_OK=false
    else
        echo "  ✓ $f"
    fi
done

if [ "$ALL_OK" = true ]; then
    echo ""
    echo "LLM Wiki skill installed successfully!"
    echo ""
    echo "Next: Set up wiki in your project:"
    echo "  ~/.claude/skills/llm-wiki/scripts/setup-project.sh ./wiki"
    echo "  (add --with-hooks for richer session context)"
else
    echo ""
    echo "Installation incomplete — some files are missing." >&2
    exit 1
fi
