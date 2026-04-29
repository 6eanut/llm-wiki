#!/bin/bash
# init-wiki.sh — Bootstrap a new LLM Wiki directory structure
# Usage: init-wiki.sh [wiki_root] [--force]
# Default wiki_root: ./wiki
# Creates the full .llm-wiki/ directory tree, schema, config, index, cache, etc.

set -euo pipefail

WIKI_ROOT="./wiki"
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: init-wiki.sh [wiki_root] [--force]"
            echo "Bootstraps a new LLM Wiki directory structure."
            echo "  wiki_root   Target directory (default: ./wiki)"
            echo "  --force     Overwrite existing config/index files"
            echo "  --help, -h  Show this help message"
            exit 0 ;;
        --force) FORCE=true ;;
        *)       WIKI_ROOT="$arg" ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA_SRC="$SCRIPT_DIR/WIKI_SCHEMA.md"

if [ ! -f "$SCHEMA_SRC" ]; then
    echo "ERROR: Schema source not found at $SCHEMA_SRC" >&2
    exit 1
fi

echo "Initializing LLM Wiki at: $WIKI_ROOT"

# Create directory tree
mkdir -p "$WIKI_ROOT"
mkdir -p "$WIKI_ROOT/.llm-wiki/cache/ingests"
mkdir -p "$WIKI_ROOT/.llm-wiki/inbox"

# Copy schema
cp "$SCHEMA_SRC" "$WIKI_ROOT/.llm-wiki/schema.md"
echo "  ✓ schema.md"

# Create config.md if it doesn't exist
if [ ! -f "$WIKI_ROOT/.llm-wiki/config.md" ] || [ "$FORCE" = true ]; then
    cat > "$WIKI_ROOT/.llm-wiki/config.md" << 'CONFEOF'
# Wiki Configuration

## Wiki Settings
wiki_name: "My Wiki"
wiki_root: "./wiki"
language: "bilingual"       # en | zh | bilingual

## Ingest Settings
auto_index: true             # Auto-regenerate index after each change
two_phase: true              # Use two-phase ingest (Phase 1 analysis, Phase 2 generation)
require_review: true         # Require user review of Phase 1 analysis before Phase 2

## Query Settings
max_pages_to_read: 5         # Maximum pages to read per query
prefer_language_match: true  # Prefer pages in query language

## Lint Settings
lint_on_startup: false       # Run quick lint on session start
full_lint_frequency: 10      # Suggest full lint every N ingests
CONFEOF
    echo "  ✓ config.md"
fi

# Create initial index.md if it doesn't exist
if [ ! -f "$WIKI_ROOT/.llm-wiki/index.md" ] || [ "$FORCE" = true ]; then
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$WIKI_ROOT/.llm-wiki/index.md" << INDEXEOF
# Wiki Index
<!-- AUTO-GENERATED — DO NOT EDIT BY HAND -->
**Generated:** $NOW
**Total pages:** 0

## All Pages
*No pages yet — use /wiki-ingest to add your first source.*

## By Tag
*No pages yet.*

## Orphan Pages / 孤立页面
*No pages yet.*

## Review Queue / 审核队列
*No pending reviews.*
INDEXEOF
    echo "  ✓ index.md"
fi

# Create initial hot-cache.md if it doesn't exist
if [ ! -f "$WIKI_ROOT/.llm-wiki/cache/hot-cache.md" ] || [ "$FORCE" = true ]; then
    cat > "$WIKI_ROOT/.llm-wiki/cache/hot-cache.md" << 'HOTEOF'
# Hot Cache / 热缓存
**Last session:** (none)

## Recent Activity / 最近活动
*First session — no activity yet.*

## Pending Review / 待审核
*No pending reviews.*
HOTEOF
    echo "  ✓ cache/hot-cache.md"
fi

# Create source manifest if it doesn't exist
if [ ! -f "$WIKI_ROOT/.llm-wiki/cache/source-manifest.json" ] || [ "$FORCE" = true ]; then
    echo '{}' > "$WIKI_ROOT/.llm-wiki/cache/source-manifest.json"
    echo "  ✓ cache/source-manifest.json"
fi

# Create review.json if it doesn't exist
if [ ! -f "$WIKI_ROOT/.llm-wiki/review.json" ] || [ "$FORCE" = true ]; then
    echo '{"pending":[]}' > "$WIKI_ROOT/.llm-wiki/review.json"
    echo "  ✓ review.json"
fi

# Create graph.json if it doesn't exist
if [ ! -f "$WIKI_ROOT/.llm-wiki/graph.json" ] || [ "$FORCE" = true ]; then
    echo '{"nodes":[],"edges":[]}' > "$WIKI_ROOT/.llm-wiki/graph.json"
    echo "  ✓ graph.json"
fi

# Create symlink: wiki/index.md → .llm-wiki/index.md
if [ -L "$WIKI_ROOT/index.md" ]; then
    rm "$WIKI_ROOT/index.md"
    ln -s ".llm-wiki/index.md" "$WIKI_ROOT/index.md"
elif [ -f "$WIKI_ROOT/index.md" ]; then
    if [ "$FORCE" = true ]; then
        rm "$WIKI_ROOT/index.md"
        ln -s ".llm-wiki/index.md" "$WIKI_ROOT/index.md"
        echo "  ✓ index.md (symlink, replaced existing file)"
    else
        echo "  ⚠ index.md already exists as a regular file (use --force to replace with symlink)"
    fi
else
    ln -s ".llm-wiki/index.md" "$WIKI_ROOT/index.md"
    echo "  ✓ index.md → .llm-wiki/index.md (symlink)"
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/scripts/"*.sh 2>/dev/null || true

echo ""
echo "Wiki initialized at $WIKI_ROOT"
echo ""
echo "Next steps:"
echo "  1. Drop source documents into .raw/"
echo "  2. Use /wiki-ingest <source> to start building your wiki"
echo "  3. Use /wiki to see your dashboard"
