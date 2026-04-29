# /wiki-save — Save Answer as Synthesis Page

**Purpose**: Persist a query answer (from `/wiki-query` or any Q&A exchange) as a permanent synthesis page in the wiki. This is how the wiki compounds — good answers become part of the knowledge base.

**Invoked by**: `/wiki-save` (after a query) or user saying "save" → SKILL.md routes here

---

## Procedure

### Step 1: Collect Context

Gather from the recent conversation:

| Element | Source | Required? |
|---------|--------|-----------|
| Question | The original query text | Yes |
| Answer | The synthesized answer | Yes |
| Evidence | Pages consulted during query | Recommended |
| Contradictions | Any contradictions found | If applicable |
| Gaps | Knowledge gaps identified | If applicable |
| Confidence | Confidence assessment | Yes |

If there was no recent query: ask "What question and answer should I save?"

### Step 2: Derive Slug and Filename

1. Extract key terms from the question
2. Convert to lowercase kebab-case
3. Remove question words (what, how, why, 什么, 怎么, 为什么)
4. Keep under 60 characters
5. Prefix: `synth-{YYYY-MM-DD}-{slug}`

Examples: "What is the difference between RISC-V and ARM?" → `synth-2026-04-28-riscv-vs-arm.md`

### Step 3: Read Template

Read `templates/synthesis.md` from the skill directory.

### Step 4: Determine Language

- `>70% CJK` → `zh`, `>70% Latin` → `en`, otherwise → `bilingual`

### Step 5: Write the Synthesis Page

Create `$WIKI_ROOT/synth-{YYYY-MM-DD}-{slug}.md`:

```yaml
---
title: "{Descriptive title}"
type: synthesis
language: {en|zh|bilingual}
created: YYYY-MM-DD
modified: YYYY-MM-DD
tags: [derived from topics]
summary: "{One-sentence answer summary}"
query: "{Exact original question}"
based_on: [list of page slugs consulted]
confidence: {high|medium|low}
---
```

Body: Question / 问题 → Answer / 回答 → Evidence / 证据 (table) → Contradictions / 矛盾 → Gaps / 知识缺口 → Confidence / 置信度

### Step 6: Cross-Link

1. Add [[wikilinks]] from synthesis to all `based_on` pages
2. Add backlinks from source pages where the synthesis adds insight
3. Link to any mentioned concepts that have wiki pages

### Step 7: Update Graph

Add node + edges to `$WIKI_ROOT/.llm-wiki/graph.json`.

### Step 8: Regenerate Index

Follow `workflows/ingest.md` Step 15 index regeneration procedure.

### Step 9: Confirm

```
# Synthesis Saved / 综合页面已保存
**File:** synth-{date}-{slug}.md
**Title:** {title}
**Based on:** {N} wiki pages
**Confidence:** {high|medium|low}
```

---

## Edge Cases

- **Already exists**: Show existing, ask: update or new version?
- **Empty based_on**: Mark `based_on: []`, note "from general knowledge, not wiki pages", cap confidence at "medium"
- **Low confidence**: Still save, title "Preliminary: {title}", add "⚠️ Low confidence" notice
- **No recent query**: Ask user to describe Q&A pair
