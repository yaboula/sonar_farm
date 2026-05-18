---
description: Investigación documental sobre un topic. Web search en docs oficiales + comunidad. Output reporte con citas.
---

# Research — `/research <topic>`

Use this workflow when you need to gather external knowledge on a topic before designing or coding (e.g. how `ox_inventory` metadata works, how QBox handles vehicle keys, what shadcn components exist for a Bento layout).

## Inputs

- `<topic>` — short query (e.g. `ox_inventory metadata`, `framer motion nui performance`, `qbcore vehicle persistence`).

## Trusted source domains

Prioritize results from:

- **Official docs**:
  - `overextended.dev` (ox_lib, ox_inventory, ox_target, oxmysql).
  - `docs.fivem.net` (FiveM natives + scripting reference).
  - `docs.qbox.re` (QBox).
  - `qbcore.org` / GitHub `qbcore-framework` (QBCore).
  - `react.dev`, `tailwindcss.com`, `ui.shadcn.com`, `motion.dev` (Framer Motion).
  - `recharts.org`.
- **Community**:
  - `forum.cfx.re` (CFX-RE forum, official FiveM community).
  - `github.com/overextended/*` (ox repos issues + discussions).
  - `github.com/qbcore-framework/*`.
  - `github.com/Qbox-project/*`.

## Steps

1. **Frame the query.** What exact question are we answering? Write it at the top of `docs/research/<topic>.md`.

2. **Run web searches.**
   - 1 query targeted at official docs (use `domain` filter).
   - 1 query targeted at the CFX-RE forum.
   - 1 query targeted at GitHub (issues/discussions).
   - Additional queries as needed for edge cases.

3. **Read top results.** Use `read_url_content` for the most relevant URLs. Skim, do not read fully unless directly answering the question.

4. **Synthesize findings** in `docs/research/<topic>.md` (in English):

   ```markdown
   # Research — <topic>

   **Date:** <date>
   **Question:** <1-2 line question>
   **Triggered by:** <slice / spike / general curiosity>

   ## Summary

   <2-3 paragraph synthesis answering the question>

   ## Key findings

   - <finding 1> — source: <URL>
   - <finding 2> — source: <URL>
   - ...

   ## Code/config snippets

   <if any, with attribution>

   ## Caveats / open questions

   <what remains unclear or version-dependent>

   ## References

   1. <URL> — <1-line description>
   2. <URL> — <1-line description>
   ```

5. **Cite everything.** No claim without a URL or repo file reference. If a claim has no source, mark it `(unverified)`.

6. **If the research surfaces a decision-worthy fact** (e.g. "ox_inventory metadata supports nested objects up to depth 3"), reference the research file from the relevant slice mini-brief or ADR.

7. **Report to user**: 3-line summary with key answer + path to research file.

## When NOT to use this workflow

- For things already documented in Bible / Roadmap / existing ADRs: read those instead.
- For things only knowable by reading our own codebase: use `code_search` instead.
- For things that need empirical testing: use `/spike` instead.
