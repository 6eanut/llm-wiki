# /wiki-graph — Knowledge Graph Visualization

**Purpose**: Generate an interactive D3.js force-directed graph showing the wiki's page network.

**Invoked by**: `/wiki-graph` → SKILL.md routes here

---

## Procedure

### Step 1: Extract Graph Data

List all pages and extract node/edge data:

```bash
find "$WIKI_ROOT" -maxdepth 1 -name "*.md" ! -path "*/.llm-wiki/*" ! -name "index.md"
```

Build structure:
```json
{
  "nodes": [{"id": "slug", "title": "Display Title", "type": "concept|article|person|synthesis", "language": "en|zh|bilingual", "tags": ["tag1"], "incomingLinks": N, "outgoingLinks": N}],
  "edges": [{"source": "page-a", "target": "page-b"}]
}
```

### Step 2: Compute Derived Metrics

- `incomingLinks`, `outgoingLinks`, `isOrphan`, `isHub` (outgoingLinks > 5), `centrality`

### Step 3: Write graph.json

Write to `$WIKI_ROOT/.llm-wiki/graph.json`.

### Step 4: Generate graph.html

Create a self-contained HTML file at `$WIKI_ROOT/.llm-wiki/graph.html` with:

- Dark-themed D3.js v7 force-directed graph (CDN: `d3js.org/d3.v7.min.js`)
- Color-coded nodes: concept=#5b9bd5, article=#ed7d31, person=#70ad47, synthesis=#ffc000
- Node radius: `5 + min(incomingLinks, 15)` px
- Tooltips on hover: title, type, language, link counts, tags
- Draggable nodes, zoom/pan on SVG
- Legend for type colors
- Graph data embedded as inline JavaScript variable

### Step 5: Present

```
# Knowledge Graph / 知识图谱
**Nodes:** {N} | **Edges:** {N} | **Orphans:** {N} | **Hubs:** {N}
Graph: wiki/.llm-wiki/graph.html | Data: wiki/.llm-wiki/graph.json
```

Offer to open with `xdg-open` or `open`.

---

## Edge Cases

- **Empty wiki**: "No pages to graph. Ingest sources first."
- **Single page**: Generate single-node graph; suggest adding more pages
- **>50 pages**: Offer tag filtering; warn about simulation performance
- **Stale graph.json**: Always regenerate from live data, never reuse
