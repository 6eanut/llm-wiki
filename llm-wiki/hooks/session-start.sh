#!/bin/bash
# session-start.sh — SessionStart hook for LLM Wiki
# Outputs wiki context and PROACTIVE WIKI RULE for Claude.
#
# Configured as a SessionStart hook in settings.json (via setup-project.sh --with-hooks).
# The output of this script becomes part of Claude's session context.

set -euo pipefail

find_wiki_root() {
    if [ -n "${LLM_WIKI_ROOT:-}" ] && [ -d "$LLM_WIKI_ROOT/.llm-wiki" ]; then
        echo "$LLM_WIKI_ROOT"
    elif [ -d "./wiki/.llm-wiki" ]; then
        echo "./wiki"
    else
        echo ""
    fi
}

WIKI_ROOT=$(find_wiki_root)
[ -z "$WIKI_ROOT" ] && exit 0

HOT_CACHE="$WIKI_ROOT/.llm-wiki/cache/hot-cache.md"
INDEX="$WIKI_ROOT/.llm-wiki/index.md"
STATE_HASH_FILE="$WIKI_ROOT/.llm-wiki/cache/state-hash.txt"
REVIEW_JSON="$WIKI_ROOT/.llm-wiki/review.json"

# Compute current state hash from all wiki pages
CURRENT_HASH=$(find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -name "index.md" -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
if [ -d "$WIKI_ROOT/topics" ]; then
    TOPIC_HASH=$(find "$WIKI_ROOT/topics" -name "*.md" -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    CURRENT_HASH=$(echo "$CURRENT_HASH$TOPIC_HASH" | sha256sum | cut -d' ' -f1)
fi

cat << HEADER
---
## LLM Wiki — Session Context
**Wiki root:** $WIKI_ROOT
**Skill:** Use \`Skill("llm-wiki")\` to load full wiki capabilities
---

HEADER

# === PROACTIVE WIKI RULE (most important) ===
cat << RULES
### PROACTIVE WIKI RULE — ALWAYS FOLLOW THIS

1. **Check the wiki before answering** — When the user asks any factual, conceptual, or knowledge-based question, FIRST read \`$WIKI_ROOT/.llm-wiki/index.md\` to check if the wiki has relevant information. Do NOT answer from your training data without checking the wiki.

2. **How to use the wiki**:
   - Read the index to find relevant pages (by tags, titles, summaries)
   - Read 3-5 most relevant pages
   - Synthesize answer with citations: \`[[page-slug]]\`
   - Report confidence, contradictions, and knowledge gaps

3. **When the wiki lacks knowledge**: Tell the user what's missing and suggest sources to ingest. Use \`/wiki-ingest\` to add knowledge.

RULES

# Compare with stored hash
if [ -f "$STATE_HASH_FILE" ]; then
    STORED_HASH=$(cat "$STATE_HASH_FILE")
    if [ "$CURRENT_HASH" != "$STORED_HASH" ]; then
        echo "⚠️  **Wiki state has changed** since last session. Run /wiki-lint to check health."
        echo ""
    fi
fi
echo "$CURRENT_HASH" > "$STATE_HASH_FILE"

# Quick stats from index
if [ -f "$INDEX" ]; then
    PAGE_COUNT=$(grep -c '^| \[' "$INDEX" 2>/dev/null || echo "0")
    LAST_GEN=$(grep "Last generated" "$INDEX" 2>/dev/null | sed 's/.*\*\*//;s/\*\*//' || echo "unknown")
    echo "**Wiki pages:** $PAGE_COUNT | **Index:** $LAST_GEN"
    echo ""

    # Tag cloud
    TAGS=$(grep '^### ' "$INDEX" 2>/dev/null | sed 's/^### //' | sed 's/ ([0-9]* pages)//' || true)
    if [ -n "$TAGS" ]; then
        echo "### Available Topics / 可用主题"
        echo "$TAGS" | while read -r tag; do
            echo "- \`$tag\`"
        done
        echo ""
    fi
else
    echo "**Wiki:** Empty — ingest some sources first!"
    echo ""
fi

# Pending reviews
if [ -f "$REVIEW_JSON" ]; then
    PENDING=$(python3 -c "
import json
try:
    with open('$REVIEW_JSON') as f:
        data = json.load(f)
    pending = data.get('pending', [])
    print(len(pending))
except: print(0)
" 2>/dev/null || echo "0")

    if [ "$PENDING" -gt 0 ]; then
        echo "🔔 **$PENDING pending review(s)** — run /wiki-review to process"
        echo ""
    fi
fi

# Hot cache from previous session
if [ -f "$HOT_CACHE" ]; then
    echo "### Context from Previous Session / 上次会话上下文"
    cat "$HOT_CACHE"
    echo ""
fi

# Reminder
cat << REMINDER
---
**Commands:** /wiki, /wiki-ingest, /wiki-query, /wiki-lint, /wiki-save, /wiki-graph, /wiki-review
**Skill:** Use \`Skill("llm-wiki")\` for advanced wiki operations
REMINDER
