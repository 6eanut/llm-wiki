#!/bin/bash
# install.sh — Install LLM Wiki skill to Claude Code
# Usage: install.sh [--force]
# Copies the skill directory to ~/.claude/skills/llm-wiki/
# Exit: 0 on success, 1 on error

set -euo pipefail

FORCE=false
VERBOSE=false
UPDATE=false
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: install.sh [--force] [--update] [--verbose]"
            echo "Install the LLM Wiki skill to ~/.claude/skills/llm-wiki/"
            echo "  --force     Overwrite existing installation"
            echo "  --update    Update from the source repository (git pull)"
            echo "  --verbose   Print detailed progress information"
            echo "  --help, -h  Show this help message"
            exit 0 ;;
        --force)   FORCE=true ;;
        --verbose) VERBOSE=true ;;
        --update)  UPDATE=true ;;
        *)         echo "Unknown option: $arg (use --help for usage)" >&2; exit 1 ;;
    esac
done

log()  { if [ "$VERBOSE" = true ]; then echo "  [verbose] $*"; fi }
vlog() { echo "  $*"; }

SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DST="$HOME/.claude/skills/llm-wiki"

# ── Update mode ─────────────────────────────────────────────────────────────

if [ "$UPDATE" = true ]; then
    log "Update mode: pulling latest changes from source repository..."

    if [ -d "$SKILL_SRC/.git" ]; then
        vlog "Updating source repository..."
        (cd "$SKILL_SRC" && git pull --ff-only) || {
            echo "ERROR: Failed to update source repository" >&2
            exit 1
        }
    else
        echo "WARNING: Not a git repository — cannot auto-update." >&2
        echo "Please re-clone from https://github.com/6eanut/llm-wiki" >&2
        exit 1
    fi

    # Re-run install with force to apply updates
    log "Re-installing from updated source..."
    bash "$SKILL_SRC/install.sh" --force
    echo ""
    echo "LLM Wiki skill updated successfully!"
    exit 0
fi

# ── Main install flow ────────────────────────────────────────────────────────

if [ -d "$SKILL_DST" ] && [ "$FORCE" != true ]; then
    echo "LLM Wiki skill is already installed at: $SKILL_DST"
    echo "Use --force to overwrite."
    exit 1
fi

echo "Installing LLM Wiki skill..."
echo "  Source: $SKILL_SRC"
echo "  Target: $SKILL_DST"

log "Skill source contains $(find "$SKILL_SRC" -type f | wc -l) files"

if [ -d "$SKILL_DST" ]; then
    log "Removing existing installation at $SKILL_DST"
    rm -rf "$SKILL_DST"
fi

mkdir -p "$(dirname "$SKILL_DST")"
cp -r "$SKILL_SRC" "$SKILL_DST"
log "Copied skill files to $SKILL_DST"

# Make scripts executable
log "Setting executable permissions on scripts and hooks"
chmod +x "$SKILL_DST/scripts/"*.sh 2>/dev/null || true
chmod +x "$SKILL_DST/hooks/"*.sh 2>/dev/null || true

# Install command files to ~/.claude/commands/
echo ""
echo "Installing slash commands..."
COMMANDS_DST="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DST"
log "Commands destination: $COMMANDS_DST"
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
REQUIRED_FILES=(
    "SKILL.md"
    "WIKI.md"
    "WIKI_SCHEMA.md"
    "scripts/init-wiki.sh"
    "scripts/setup-project.sh"
    "commands/wiki-ingest.md"
    "commands/wiki-query.md"
    "hooks/session-start.sh"
    "hooks/session-stop.sh"
    "workflows/ingest.md"
    "workflows/query.md"
    "workflows/lint.md"
    "workflows/save-synthesis.md"
    "workflows/graph.md"
    "workflows/review.md"
    "templates/article.md"
    "templates/concept.md"
    "templates/person.md"
    "templates/synthesis.md"
)
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
