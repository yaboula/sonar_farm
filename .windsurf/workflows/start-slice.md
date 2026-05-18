---
description: Arranca un slice nuevo del Roadmap. Lee contexto, crea mini-brief, planifica.
---

# Start Slice — `/start-slice <SXX>`

Use this workflow at the beginning of every slice implementation session.

## Inputs

- `<SXX>` — slice ID (e.g. `S5`, `S28`).

## Steps

1. **Read foundation context** if not already loaded in this session:
   - `docs/00_BIBLE.md` (full).
   - `docs/01_ROADMAP.md` (full).
   - `docs/03_AI_PLAYBOOK.md` (sections relevant to current sub-agent role, if applicable).

2. **Locate the slice** in `docs/01_ROADMAP.md`. Confirm:
   - Scope.
   - Dependencies (verify they are `DONE` in the Roadmap; if any is `PLANNED` or `BLOCKED`, halt and report).
   - Complexity estimate.
   - Slice-specific DoD.
   - Whether it is marked ⭐ (marketing) or 🚨 (risk).

3. **Check if mini-brief already exists** at `docs/slices/<SXX>_<name>.md`:
   - If yes → load it, confirm with user we are continuing existing work.
   - If no → continue to step 4.

4. **Create mini-brief** by copying `docs/slices/_TEMPLATE.md` to `docs/slices/<SXX>_<name>.md`. Fill it with:
   - Slice ID + name from Roadmap.
   - Status: `ACTIVE`.
   - Phase reference.
   - Complexity from Roadmap.
   - Dependencies list with status verified.
   - Scope summary (copy from Roadmap, expand if needed).
   - Deliverables checklist (copy from Roadmap).
   - Universal DoD (copy from `.windsurf/rules/04_dod_universal.md`).
   - Slice-specific DoD (copy from Roadmap).

5. **Build a todo list** in the IDE with:
   - One item per deliverable.
   - One item per slice-specific DoD criterion.
   - One item: "Run `/end-slice <SXX>`".
   - Mark the first item as `in_progress`.

6. **Update Roadmap state** for this slice from `PLANNED` → `ACTIVE` (edit `docs/01_ROADMAP.md`).

7. **Decide if `/spawn-pm` is needed** based on slice complexity:
   - Complexity **S** or **M** → typically a single agent session is enough. Skip PM.
   - Complexity **L** → 2-3 sub-agents recommended. Run `/spawn-pm`.
   - Complexity **XL** → 3-4 sub-agents recommended. Run `/spawn-pm`.

8. **Report to user** a one-paragraph summary:
   - Slice + complexity + estimated duration.
   - Dependencies status.
   - Next action (start coding directly, OR run `/spawn-pm` first).

## Notes

- Never start coding before steps 1-6 are complete.
- If dependencies are not `DONE`, halt and ask the user how to proceed (push the slice out, or unblock the dependency first).
