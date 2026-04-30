#!/bin/bash
# find-broken-links.sh — Find [[wikilinks]] pointing to missing pages
# Usage: find-broken-links.sh <wiki_root>
# Output: one line per broken link
# Exit: 0 = no broken links, 1 = broken links found, 2 = error

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: find-broken-links.sh [wiki_root]"
    echo "Find [[wikilinks]] pointing to missing pages."
    echo "  wiki_root   Wiki directory (default: ./wiki)"
    echo "Exit: 0 = no broken links, 1 = broken links found, 2 = error"
    exit 0
fi

WIKI_ROOT="${1:-./wiki}"

if [ ! -d "$WIKI_ROOT" ]; then
    echo "ERROR: Wiki root '$WIKI_ROOT' does not exist" >&2
    exit 2
fi

# Collect all valid targets: page slugs + all aliases from frontmatter
VALID_TARGETS=""

# All page slugs in wiki root (skip index.md symlink)
while IFS= read -r -d '' file; do
    slug=$(basename "$file" .md)
    VALID_TARGETS="$VALID_TARGETS"$'\n'"$slug"
done < <(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" ! -name "index.md" -print0 2>/dev/null)

# All page slugs in topics/
if [ -d "$WIKI_ROOT/topics" ]; then
    while IFS= read -r -d '' file; do
        slug=$(basename "$file" .md)
        VALID_TARGETS="$VALID_TARGETS"$'\n'"$slug"
    done < <(find "$WIKI_ROOT/topics" -name "*.md" -print0 2>/dev/null)
fi

# Collect aliases from all pages using awk for robust YAML parsing
collect_aliases() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | awk '
        /^aliases:/ {
            in_aliases=1
            sub(/^aliases:[[:space:]]*/,"")
            if ($0 ~ /^\[/) {
                # Inline array: aliases: [a, b] or aliases: ["a", "b"]
                gsub(/[\[\]]/,"")
                n = split($0, arr, /,[[:space:]]*/)
                for (i=1; i<=n; i++) {
                    gsub(/^"|"$/, "", arr[i])
                    if (arr[i] != "") print arr[i]
                }
                in_aliases=0
            } else if ($0 != "") {
                # Bare value: aliases: value or aliases: "value"
                gsub(/^"|"$/, "", $0)
                if ($0 != "") print $0
                in_aliases=0
            }
            next
        }
        in_aliases && /^[a-z]/ { in_aliases=0; next }
        in_aliases {
            # Multi-line: - value or - "value"
            gsub(/^[[:space:]]*-[[:space:]]*"?|"$|[\[\],]/,"")
            if ($0 != "") print $0
        }
    ' || true
}

while IFS= read -r -d '' file; do
    while IFS= read -r alias; do
        [ -n "$alias" ] && VALID_TARGETS="$VALID_TARGETS"$'\n'"$alias"
    done < <(collect_aliases "$file")
done < <(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" -print0 2>/dev/null)

# Deduplicate valid targets
VALID_TARGETS=$(echo "$VALID_TARGETS" | sort -u)

BROKEN_FOUND=0

check_page() {
    local file="$1"
    local rel="${file#"$WIKI_ROOT"/}"

    local links
    links=$(sed -n 's/.*\[\[\([^]|#]*\)\(|[^]]*\)*\]\].*/\1/p' "$file" 2>/dev/null | sort -u)

    while IFS= read -r link; do
        [ -z "$link" ] && continue
        echo "$link" | grep -q '://' && continue
        [[ "$link" =~ ^# ]] && continue
        if ! echo "$VALID_TARGETS" | grep -qFx "$link"; then
            echo "BROKEN: $rel → [[$link]]"
            BROKEN_FOUND=1
        fi
    done <<< "$links"
}

while IFS= read -r -d '' file; do
    check_page "$file"
done < <(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" -print0 2>/dev/null)

if [ -d "$WIKI_ROOT/topics" ]; then
    while IFS= read -r -d '' file; do
        check_page "$file"
    done < <(find "$WIKI_ROOT/topics" -name "*.md" -print0 2>/dev/null)
fi

if [ "$BROKEN_FOUND" -eq 0 ]; then
    echo "OK: No broken wikilinks found."
fi

exit "$BROKEN_FOUND"
