#!/bin/bash
# session-stop.sh — SessionStop hook for LLM Wiki
# Writes hot-cache template for the next session.
# Claude should fill in activity details during the session via /wiki operations.
#
# Configured as a SessionStop hook in settings.json.

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/_utils.sh"

WIKI_ROOT=$(find_wiki_root)
[ -z "$WIKI_ROOT" ] && exit 0

HOT_CACHE="$WIKI_ROOT/.llm-wiki/cache/hot-cache.md"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$HOT_CACHE" << HOTEOF
# Hot Cache / 热缓存
**Last session:** $NOW

## Recent Activity / 最近活动
<!-- Populated during session by /wiki operations -->

## Pages Read / 已读页面
<!-- Pages consulted during queries -->

## Pages Written / 已写页面
<!-- Pages created or updated -->

## Queries Asked / 查询记录
<!-- Queries asked via /wiki-query -->

## Pending / 待处理
<!-- Items needing follow-up next session -->

## Notes / 备注
<!-- Free-form notes -->
HOTEOF

echo "Hot cache written to $HOT_CACHE"
