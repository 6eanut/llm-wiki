# /wiki-review — Process the Review Queue

**Purpose**: Walk through `review.json` items needing human attention — contradictions, quality issues, stale pages, knowledge gaps.

**Invoked by**: `/wiki-review` → SKILL.md routes here

---

## Procedure

### Step 1: Read Review Queue

Read `$WIKI_ROOT/.llm-wiki/review.json`:
```json
{"pending": [{"id": "...", "type": "contradiction|quality|staleness|gap|naming", "pages": ["slug"], "description": "...", "severity": "error|warning|info", "detected": "YYYY-MM-DD", "context": "..."}]}
```

### Step 2: Show Overview

```
# Review Queue / 审核队列
**Total:** {N} | **Errors:** {N} | **Warnings:** {N} | **Info:** {N}
| # | Type | Severity | Pages | Description |
```

### Step 3: Process Items One at a Time

For each item:
1. Present full context (type, pages, description, severity)
2. Read referenced pages for context
3. Suggest resolution options
4. Ask user: "Resolve" | "Dismiss" | "Skip" | "Edit"

### Step 4: Apply Resolution

- **Resolve contradiction**: fix less-reliable page, or add context note; remove callout
- **Resolve quality**: make edits, update `modified` date
- **Resolve staleness**: review accuracy, update `modified`, add "Reviewed: YYYY-MM-DD"
- **Resolve gap**: create stub page or note gap in existing page
- **Dismiss**: remove from queue; optionally note "Reviewed — no action"
- **Skip**: leave in queue

### Step 5: Update review.json

Move resolved items to `resolved` array; write back.

### Step 6: Show Summary

```
# Review Complete / 审核完成
**Processed:** {N} | **Resolved:** {N} | **Skipped:** {N}
```

---

## Common Resolution Patterns

- **One page clearly wrong**: Correct it with dated note; remove contradiction callout
- **Both right, different contexts**: Add context note to both pages
- **Stub page**: Ask keep-or-delete; if keep, add "⚠️ Stub" marker
- **Old but accurate**: Update `modified` + "Reviewed" note
- **Missing concept**: Create stub from mentions in existing pages; mark `confidence: low`

---

## Edge Cases

- **Empty queue**: "No pending reviews — wiki is healthy!"
- **>20 items**: Process in chunks of 5-10; prioritize errors
- **Cascade issues**: Note new issues; add to queue; don't resolve cascades unless asked
- **Deleted page referenced**: Auto-dismiss with note
