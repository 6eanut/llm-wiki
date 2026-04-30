#!/bin/bash
# validate-frontmatter.sh — Check required frontmatter fields in wiki pages
# Usage: validate-frontmatter.sh <wiki_root>
# Output: one line per issue found
# Exit: 0 = all valid, 1 = issues found, 2 = error

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: validate-frontmatter.sh [wiki_root]"
    echo "Check required frontmatter fields in all wiki pages."
    echo "  wiki_root   Wiki directory (default: ./wiki)"
    echo "Exit: 0 = all valid, 1 = issues found, 2 = error"
    exit 0
fi

WIKI_ROOT="${1:-./wiki}"

if [ ! -d "$WIKI_ROOT" ]; then
    echo "ERROR: Wiki root '$WIKI_ROOT' does not exist" >&2
    exit 2
fi

REQUIRED_FIELDS=("title" "type" "language" "created" "modified" "tags" "summary")
VALID_TYPES=("concept" "article" "person" "synthesis")
VALID_LANGUAGES=("en" "zh" "bilingual")

ISSUES_FOUND=0

check_page() {
    local file="$1"
    local rel="${file#"$WIKI_ROOT"/}"
    local frontmatter

    # Extract frontmatter between --- markers
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null)

    if [ -z "$frontmatter" ]; then
        echo "ERROR: $rel — No frontmatter found (missing --- delimiters)"
        ISSUES_FOUND=1
        return
    fi

    # Extract YAML field values
    extract_field() {
        echo "$frontmatter" | grep -E "^${1}:" | sed "s/^${1}:[[:space:]]*//" | sed 's/^"//;s/"$//' | head -1
    }

    # Check required fields exist
    for field in "${REQUIRED_FIELDS[@]}"; do
        local val
        val=$(extract_field "$field")
        if [ -z "$val" ] || [ "$val" = "[]" ] && [ "$field" != "tags" ]; then
            echo "ERROR: $rel — Missing required field '$field'"
            ISSUES_FOUND=1
        fi
    done

    # Validate type
    local ptype
    ptype=$(extract_field "type")
    if [ -n "$ptype" ]; then
        local valid=0
        for vt in "${VALID_TYPES[@]}"; do
            [ "$ptype" = "$vt" ] && valid=1
        done
        if [ "$valid" -eq 0 ]; then
            echo "ERROR: $rel — Invalid type '$ptype' (must be one of: ${VALID_TYPES[*]})"
            ISSUES_FOUND=1
        fi
    fi

    # Validate language
    local lang
    lang=$(extract_field "language")
    if [ -n "$lang" ]; then
        local valid=0
        for vl in "${VALID_LANGUAGES[@]}"; do
            [ "$lang" = "$vl" ] && valid=1
        done
        if [ "$valid" -eq 0 ]; then
            echo "ERROR: $rel — Invalid language '$lang' (must be one of: ${VALID_LANGUAGES[*]})"
            ISSUES_FOUND=1
        fi
    fi

    # Validate date formats
    local created modified
    created=$(extract_field "created")
    modified=$(extract_field "modified")
    for date_val in "$created" "$modified"; do
        if [ -n "$date_val" ] && ! echo "$date_val" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
            echo "ERROR: $rel — Invalid date format '$date_val' (must be YYYY-MM-DD)"
            ISSUES_FOUND=1
            break
        fi
    done
}

# Check all wiki pages
while IFS= read -r -d '' file; do
    check_page "$file"
done < <(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" ! -name "index.md" -print0 2>/dev/null)

# Check nested topics directory if it exists
if [ -d "$WIKI_ROOT/topics" ]; then
    while IFS= read -r -d '' file; do
        check_page "$file"
    done < <(find "$WIKI_ROOT/topics" -name "*.md" -print0 2>/dev/null)
fi

if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo "OK: All pages have valid frontmatter."
fi

exit "$ISSUES_FOUND"
