#!/bin/bash
# find-orphans.sh — Find wiki pages with zero incoming [[wikilinks]]
# Usage: find-orphans.sh <wiki_root>
# Output: one line per orphan page
# Exit: 0 on success (even if orphans found), 1 on error

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: find-orphans.sh [wiki_root]"
    echo "Find wiki pages with zero incoming [[wikilinks]]."
    echo "  wiki_root   Wiki directory (default: ./wiki)"
    exit 0
fi

WIKI_ROOT="${1:-./wiki}"

if [ ! -d "$WIKI_ROOT" ]; then
    echo "ERROR: Wiki root '$WIKI_ROOT' does not exist" >&2
    exit 1
fi

# Collect all page slugs (filenames without .md) in wiki root and topics/
SLUGS=$(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" ! -name "index.md" -exec basename {} .md \; 2>/dev/null)
if [ -d "$WIKI_ROOT/topics" ]; then
    TOPIC_SLUGS=$(find "$WIKI_ROOT/topics" -name "*.md" -exec basename {} .md \; 2>/dev/null)
    SLUGS="$SLUGS"$'\n'"$TOPIC_SLUGS"
fi

# Collect all wikilink targets across all wiki pages
ALL_LINKS=$(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" -exec sed -n 's/.*\[\[\([^]|#]*\)\(|[^]]*\)*\]\].*/\1/p' {} \; 2>/dev/null | sort -u)
if [ -d "$WIKI_ROOT/topics" ]; then
    TOPIC_LINKS=$(find "$WIKI_ROOT/topics" -name "*.md" -exec sed -n 's/.*\[\[\([^]|#]*\)\(|[^]]*\)*\]\].*/\1/p' {} \; 2>/dev/null | sort -u)
    ALL_LINKS="$ALL_LINKS"$'\n'"$TOPIC_LINKS"
fi

# For each slug, check if it appears as a link target
ORPHANS_FOUND=0
while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    if ! echo "$ALL_LINKS" | grep -qFx "$slug"; then
        echo "ORPHAN: $slug"
        ORPHANS_FOUND=1
    fi
done <<< "$SLUGS"

if [ "$ORPHANS_FOUND" -eq 0 ]; then
    echo "OK: No orphan pages found."
fi
