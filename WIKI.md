# LLM Wiki — Schema & Conventions

This file is the schema for the LLM Wiki system. It tells the LLM how the wiki
is structured, what conventions to follow, and what workflows to use.

Co-evolve this file as the wiki grows. Add rules when recurring problems appear.

---

## Directory Structure

```
raw/                    # Immutable source material. Never modified by the LLM.
wiki/                   # LLM-owned. All files created and maintained by the LLM.
  index.md              # Content catalog — read this first on any query.
  log.md                # Append-only chronological record.
  entities/             # Pages about specific things (people, orgs, tools, etc.)
  concepts/             # Pages about ideas, patterns, frameworks.
  decisions/            # Reflection pages — why the wiki changed.
  analyses/             # Filed query results — comparisons, syntheses, deep dives.
```

## Page Format

Every wiki page uses YAML frontmatter:

```yaml
---
title: "Page Title"
tags: [tag1, tag2]
sources:
  - file: "raw/filename.md"
    hash: "sha256-first-8-chars"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

- `sources` tracks which raw files contributed to this page and their content
  hash at the time of compilation. This enables staleness detection.
- `updated` changes every time the page is modified.
- Use `[[Page Title]]` wikilink syntax for cross-references (Obsidian-compatible).

## Workflows

### Ingest

Trigger: User drops a file into `raw/` and asks the LLM to process it.

Steps:
1. Read the source file. Compute its SHA-256 hash (first 8 chars).
2. Create or update a **summary page** in `wiki/` (e.g., `wiki/entities/` or
   `wiki/concepts/` depending on content).
3. Update **index.md** — add or update the entry with link, one-line summary,
   and category.
4. Scan existing wiki pages for related content. Update cross-references
   on any page that now connects to the new material.
5. If the source contradicts existing wiki content, note the contradiction
   explicitly on the affected page(s) with `> [!warning] Contradiction` callouts.
6. Append to **log.md**:
   `## [YYYY-MM-DD] ingest | Source Title`
   with a brief summary of what was created/updated.
7. If significant enough, create a **decision page** in `wiki/decisions/`.

Process sources one at a time. Stay involved at first.

### Query

Trigger: User asks a question.

Steps:
1. Read `wiki/index.md` to identify relevant pages.
2. Read those pages. Synthesize an answer with citations to wiki pages
   and underlying sources.
3. Check provenance: for each cited source, verify the hash still matches
   the file on disk. Flag any stale citations.
4. If the answer is substantive (comparison, analysis, new connection),
   file it as a new page in `wiki/analyses/` and update the index.

### Reflect

Trigger: After significant ingests or queries, or on user request.

Steps:
1. Write a decision page in `wiki/decisions/` documenting:
   - What changed in the wiki
   - What it replaced or contradicted
   - What reasoning held
2. Update index.md with the new decision page.
3. Append to log.md.

### Lint

Trigger: Periodically, or on user request.

Checklist:
- [ ] Contradictions between pages
- [ ] Stale claims (source hash mismatch)
- [ ] Orphan pages (not linked from index or any other page)
- [ ] Important concepts mentioned but lacking their own page
- [ ] Missing cross-references between related pages
- [ ] Data gaps — topics partially covered
- [ ] Frontmatter completeness (all pages have required fields)

Report findings and suggest specific actions.

## Provenance

Every proposition records its source file and that file's content hash.

To check freshness:
```bash
# Compute current hash of a source file
sha256sum raw/filename.md | cut -c1-8
```

- **Match** = the wiki content derived from this source is still valid.
- **Mismatch** = the source has changed; wiki content is stale and needs re-ingestion.

## Conventions

- One concept per page. Split if a page covers multiple distinct ideas.
- Prefer specific, descriptive filenames: `wiki/concepts/rag-vs-wiki-pattern.md`
  not `wiki/concepts/comparison.md`.
- Use Obsidian callouts for special notes:
  - `> [!warning] Contradiction` — conflicting information between sources
  - `> [!info] Gap` — known missing information
  - `> [!note] Stale` — source hash mismatch detected
- Keep index.md sorted by category, then alphabetically.
- Log entries use consistent prefixes: `ingest`, `query`, `reflect`, `lint`.
