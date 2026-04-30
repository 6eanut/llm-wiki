# WIKI_SCHEMA.md — LLM Wiki Schema Reference

This file defines all page types, required fields, naming conventions, and structural rules for the LLM Wiki. It is the canonical reference for how the wiki is organized.

Read this file when you need to understand:

- What page types exist and their purposes
- What frontmatter fields are required/optional for each type
- How pages are named and structured
- How to format cross-references, contradictions, and evidence

---

## Page Types Overview

| Type | File Pattern | Purpose |
|------|-------------|---------|
| `concept` | `{slug}.md` | Define a term, idea, methodology, framework, or tool |
| `article` | `{YYYY-MM-DD}-{slug}.md` | Research notes, blog drafts, meeting notes, diary entries, imported documents |
| `person` | `{slug}.md` | Author, researcher, historical figure, notable individual |
| `synthesis` | `synth-{YYYY-MM-DD}-{slug}.md` | Saved query answer — a synthesized page from existing knowledge |

---

## 1. Concept Page (`type: concept`)

**Purpose**: Define a term, idea, methodology, framework, tool, or entity.

**File naming**: `{slug}.md` — lowercase kebab-case, ASCII-safe. Examples:

- `transformer-architecture.md`
- `retrieval-augmented-generation.md`
- `gradient-descent.md`

**Required frontmatter**:

```yaml
---
title: "Display Title"              # Can be bilingual: "Quantum Computing / 量子计算"
type: concept
language: en | zh | bilingual       # Primary language of the page body
created: YYYY-MM-DD
modified: YYYY-MM-DD
tags: []                            # Lowercase kebab-case: [machine-learning, nlp]
aliases: []                         # Alternative names, include translations
summary: ""                         # One-sentence definition (used in index)
---
```

**Optional frontmatter**:

```yaml
source_url: ""                      # URL of original source material
source_hash: ""                     # SHA-256 of source material
confidence: high | medium | low     # Confidence in the synthesized page
related_concepts: []                # Explicit related slugs (beyond wikilinks)
```

**Body structure**:

```markdown
# {Title}

## Definition / 定义
[Clear, concise definition. 2-4 sentences.]

## Key Properties / 关键特性
- Property 1
- Property 2

## Examples / 示例
[Concrete examples or use cases.]

## Related Concepts / 相关概念
- [[related-slug]] — brief description of relationship
- [[another-slug]] — brief description of relationship

## References / 参考资料
- Source material used to construct this page
```

---

## 2. Article Page (`type: article`)

**Purpose**: Research notes, blog drafts, meeting notes, diary entries, imported web articles, PDF summaries.

**File naming**: `{YYYY-MM-DD}-{slug}.md` — date-prefixed for chronological sorting. Examples:

- `2026-04-28-weekly-review.md`
- `2026-04-27-transformer-paper-notes.md`

**Required frontmatter**:

```yaml
---
title: "Display Title"
type: article
language: en | zh | bilingual
created: YYYY-MM-DD
modified: YYYY-MM-DD
tags: []
summary: ""                         # One-sentence description
---
```

**Optional frontmatter**:

```yaml
source_url: ""                      # Original URL if a web article
source_hash: ""                     # SHA-256 of original source
status: draft | published | archived
meeting_date: YYYY-MM-DD            # For meeting notes
diary_date: YYYY-MM-DD              # For diary entries
```

**Body structure**:

```markdown
# {Title}

## Summary / 摘要
[2-4 sentence overview.]

## Content / 内容
[Main body — flexible format depending on content type.]

## Key Takeaways / 关键收获
- Takeaway 1
- Takeaway 2

## Related / 关联
- [[related-slug]] — connection
```

---

## 3. Person Page (`type: person`)

**Purpose**: Author, researcher, historical figure, notable individual.

**File naming**: `{slug}.md` — lowercase kebab-case of the person's name. Examples:

- `alan-turing.md`
- `andrej-karpathy.md`

**Required frontmatter**:

```yaml
---
title: "Display Name"
type: person
language: en | zh | bilingual
created: YYYY-MM-DD
modified: YYYY-MM-DD
tags: []
aliases: []                         # Alternative name forms
summary: ""                         # One-line: who they are, why notable
---
```

**Optional frontmatter**:

```yaml
birth: YYYY-MM-DD
death: YYYY-MM-DD                   # Omit if still living
nationality: ""
fields: []                          # Areas of work: [computer-science, ai]
affiliations: []                    # Organizations they're associated with
```

**Body structure**:

```markdown
# {Name}

## Bio / 简介
[Brief biography — 3-5 sentences.]

## Key Contributions / 主要贡献
- Contribution 1
- Contribution 2

## Related Work / 相关工作
- [[related-concept]] — their role
- [[related-person]] — collaboration or influence

## Links / 链接
- [Personal site](url)
- [Wikipedia](url)
```

---

## 4. Synthesis Page (`type: synthesis`)

**Purpose**: A saved query answer — synthesized from existing wiki pages. These are the "compounding" part of the wiki: explorations that become permanent knowledge.

**File naming**: `synth-{YYYY-MM-DD}-{slug}.md`. Examples:

- `synth-2026-04-28-quantum-vs-classical.md`

**Required frontmatter**:

```yaml
---
title: "Display Title"
type: synthesis
language: en | zh | bilingual
created: YYYY-MM-DD
modified: YYYY-MM-DD
tags: []
summary: ""                         # One-sentence answer summary
query: ""                           # The original question asked
based_on: []                        # Slugs of wiki pages used as sources
confidence: high | medium | low
---
```

**Optional frontmatter**:

```yaml
contradictions_found: []            # Slugs of pages with contradictory info
gaps_noted: []                      # Knowledge gaps identified
```

**Body structure**:

```markdown
# {Title}

## Question / 问题
> Original question

## Answer / 回答
[Direct answer, synthesized from evidence.]

## Evidence / 证据
| Source Page | Key Point | Relevance |
|-------------|-----------|-----------|
| [[slug-a]] | ... | high |
| [[slug-b]] | ... | medium |

## Contradictions / 矛盾
> ⚠️ **Contradiction / 矛盾**: [description]
>
> | Page | Claim |
> |------|-------|
> | [[page-a]] | Claim X |
> | [[page-b]] | Claim Y (conflicts with X) |

## Gaps / 知识缺口
- What the wiki doesn't cover on this topic

## Confidence / 置信度: {high|medium|low}
[Reasoning for confidence level.]
```

---

## Cross-Referencing Conventions

### Wikilinks

```
[[page-slug]]              → Link to another wiki page
[[page-slug|display text]] → Link with custom text
```

### Rules for Wikilinks

- **Link liberally**: Every mention of another wiki page's topic should be a wikilink.
- **Bidirectional**: When you add a link from Page A to Page B, check if Page B should link back.
- **No paths in wikilinks**: Use just the slug (filename minus `.md`), not the full path. All pages are in the same flat namespace.
- **Resolve aliases**: Check `aliases` in frontmatter when looking up wikilink targets.

### Contradiction Callouts

When a contradiction is detected between pages, format as:

```markdown
> ⚠️ **Contradiction / 矛盾**: [description of what conflicts]
>
> | Page | Claim / 主张 |
> |------|-------------|
> | [[page-a]] | "Claim A from this page" |
> | [[page-b]] | "Claim B — contradicts A" |
>
> *Detected: YYYY-MM-DD | Status: unresolved*
```

Place contradiction callouts on **both** conflicting pages.

---

## Index Format

The index at `.llm-wiki/index.md` is **auto-generated** and follows this format:

```markdown
# Wiki Index
<!-- AUTO-GENERATED — DO NOT EDIT BY HAND -->
**Last generated:** {ISO timestamp}
**Source hash:** {sha256 of concatenated frontmatter}
**Total pages:** {N}

## All Pages
| Slug | Title | Type | Lang | Tags | Summary | Modified |
|------|-------|------|------|------|---------|----------|
| ... | ... | ... | ... | ... | ... | ... |

## By Tag
### {tag-name} ({N} pages)
- [[slug]] — summary

## Orphan Pages / 孤立页面
- [[slug]] — summary (no incoming links)

## Review Queue / 审核队列
- [[slug]] — ⚠️ issue description
```

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Page slugs | lowercase kebab-case | `machine-learning.md` |
| Tags | lowercase kebab-case | `deep-learning`, `nlp` |
| Display titles | Title Case, can include non-ASCII | `Machine Learning`, `机器学习` |
| Date format | YYYY-MM-DD | `2026-04-28` |
| Bilingual titles | "English / 中文" | `Quantum Computing / 量子计算` |

### Slug Derivation

When deriving a slug from a title:

1. Convert to lowercase
2. Replace spaces and special chars with hyphens
3. Remove non-ASCII characters (use English equivalent or transliteration)
4. Trim to reasonable length (< 60 chars)
5. If the slug already exists, append a numeric suffix: `-2`, `-3`

---

## Language Handling

### Page Language (`language` field)

- `en` — Page body is primarily English
- `zh` — Page body is primarily Chinese
- `bilingual` — Page has substantial content in both languages

### Source Language Detection (during ingest)

- Count CJK characters (Unicode range U+4E00–U+9FFF) vs Latin characters
- If >70% CJK → `zh`
- If >70% Latin → `en`
- If 30-70% mix → `bilingual`

### Bilingual Page Convention

Bilingual pages use this section heading pattern:

```markdown
## Section Name / 中文标题
```

### Query Language Matching

When answering a query:

- Detect the query language
- Prefer pages with matching `language` field
- Fall back to other-language pages if needed
- Use `aliases` for cross-language wikilink resolution

---

## Health Check Categories

### Structural (Quick Lint — bash-assisted, zero cost)

| Check | Script | Severity if fails |
|-------|--------|-------------------|
| Missing/invalid frontmatter | `validate-frontmatter.sh` | ❌ Error |
| Broken wikilinks | `find-broken-links.sh` | ❌ Error |
| Orphan pages | `find-orphans.sh` | ⚠️ Warning |
| Stale index | `check-stale.sh` | ⚠️ Warning |

### Semantic (Full Lint — LLM-intensive, token cost)

| Check | Severity if fails |
|-------|-------------------|
| Contradictions between pages | ❌ Error |
| Quality (empty sections, boilerplate) | ⚠️ Warning |
| Language consistency (tagged zh but English body) | ⚠️ Warning |
| Drift (not updated in 30+ days) | ℹ️ Info |
| Knowledge gaps (mentioned but undefined) | ℹ️ Info |
