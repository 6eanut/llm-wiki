# /wiki-query — Index-First Knowledge Retrieval

**Purpose**: Answer a question using the wiki's accumulated knowledge. Read the minimum number of pages needed by consulting the index first.

**Invoked by**: `/wiki-query <question>` → SKILL.md routes here

---

## Design Rationale

`★ Insight ─────────────────────────────────────`

- The "index-first" pattern is the key optimization: instead of reading every potentially-relevant page (O(n) reads), you read a single index file (O(1)) to narrow down to ~3-5 pages. This keeps query latency low even as the wiki grows to hundreds of pages.
- Evidence tables with explicit confidence ratings make the reasoning auditable. A user can trace every claim back to its source page, which is essential for trust — unlike a black-box RAG system.
- The `/wiki-save` prompt at the end closes the compounding loop: good answers become permanent synthesis pages, preventing the same synthesis work from being repeated.
`─────────────────────────────────────────────────`

---

## Procedure

### Step 0: Resolve Wiki Root

Same as ingest — check `$LLM_WIKI_ROOT`, then `wiki/`, then ask.

### Step 1: Read the Index

Read `$WIKI_ROOT/.llm-wiki/index.md`.

This gives you:

- All page slugs, titles, types, languages, tags, and summaries
- Tag groupings for topical navigation
- Orphan pages and review queue items

**If the index is stale** (run `scripts/check-stale.sh`; exit code 1 or 2):

- Warn the user: "Index may be out of date. Consider running /wiki-lint first."
- Proceed anyway (the index is still useful even if slightly stale)

### Step 2: (Optional) Check Hot Cache

If `$WIKI_ROOT/.llm-wiki/cache/hot-cache.md` exists, read it:

- It may contain context about what the user was working on recently
- If the question relates to recent activity, this saves you from re-reading pages

### Step 3: Detect Query Language

Analyze the query text:

- `>70% CJK` → query language is `zh`
- `>70% Latin` → query language is `en`
- Otherwise → `bilingual`

### Step 4: Identify Relevant Pages

From the index, find pages relevant to the query:

1. **Tag matching**: Match query terms against tag names
2. **Title/summary matching**: Search for keywords in titles and summaries
3. **Semantic matching**: Use your understanding to identify conceptually related pages

**Language preference** (if `prefer_language_match: true` in config):

- Prefer pages whose `language` matches the query language
- Fall back to pages in the other language if needed
- Use `aliases` for cross-language matching

**Selection strategy:**

- Target 3-5 pages (configurable: `max_pages_to_read`)
- Prefer higher-confidence pages
- Include at least one from each relevant tag cluster
- If fewer than 3 pages seem relevant, note this as a knowledge gap

### Step 5: Read the Selected Pages

Read each selected page in full:

- Extract all factual claims relevant to the query
- Note the source of each claim (which page, which section)
- Track confidence indicators

**For each page read, note:**

- Key claims relevant to the query
- Evidence quality (is it sourced? speculative?)
- Relationships to other pages (wikilinks)
- Any contradiction callouts present

### Step 6: Synthesize the Answer

Combine evidence from all read pages into a coherent answer:

1. **Direct answer first**: Start with a clear, direct response to the question
2. **Supporting evidence**: Provide the factual basis from wiki pages
3. **Confidence assessment**: Rate your confidence based on:
   - Number of corroborating pages
   - Quality of source material
   - Presence of contradictions
   - Age of pages (recently modified = higher confidence)
4. **Contradictions**: If pages disagree, present both sides explicitly
5. **Knowledge gaps**: Identify what the wiki doesn't cover

### Step 7: Format the Response

Present the answer in this structure:

```markdown
## Answer / 回答

[Direct, concise answer to the question.]

## Evidence / 证据

| Source Page | Key Point | Relevance | Confidence |
|-------------|-----------|-----------|------------|
| [[page-a]] | Key claim from this page | high | high |
| [[page-b]] | Supporting detail | medium | medium |

## Contradictions / 矛盾

*(If applicable)*

> ⚠️ The wiki contains conflicting information on this:
> | Page | Claim |
> |------|-------|
> | [[page-x]] | "Claim X" |
> | [[page-y]] | "Claim Y (conflicts)" |
>
> *Recommendation: [which seems more reliable and why]*

## Knowledge Gaps / 知识缺口

- [What the wiki doesn't know about this topic]
- [Suggestions for sources that could fill the gap]

## Confidence / 置信度: {high|medium|low}

[1-2 sentence rationale.]

## Pages Consulted / 查阅的页面

- [[page-a]]
- [[page-b]]
- ...
```

### Step 8: Offer to Save

After presenting the answer:

> Would you like me to save this as a synthesis page? Use `/wiki-save` or reply "save".

If the user says yes (or runs `/wiki-save`), follow the `workflows/save-synthesis.md` workflow.

---

## Edge Cases

### No Relevant Pages Found

- Report: "The wiki doesn't have information on this topic yet."
- Suggest related topics that do exist
- Suggest sources that could be ingested to cover this gap
- Offer to do a web search as a fallback (but note that the answer won't be wikified)

### Index Is Empty (Brand New Wiki)

- Report: "The wiki is empty. Ingest some sources first with /wiki-ingest."
- Show how to use `/wiki-ingest`

### Query Is Ambiguous

- If the question could refer to multiple concepts, ask a clarifying question
- Show both interpretations and let the user choose

### Contradictions Found

- Always present contradictions transparently
- If you can resolve the contradiction from the evidence (one page is more recent / better sourced), say so
- If unresolvable, flag it for review and note it as reducing confidence

### Very Broad Question ("Tell me about AI")

- Narrow with a clarifying question
- Suggest browsing the index by tag instead: "Here are the tags in the wiki: [list]. Which topic interests you?"

### Question in Different Language Than Wiki Content

- If the user asks in Chinese but all relevant pages are in English (or vice versa):
  - Answer in the user's language
  - Note: "These pages are in English; I've translated the key points"
  - Suggest creating bilingual aliases for future queries
