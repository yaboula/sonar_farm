---
description: Cierra un slice. Verifica DoD universal + DoD específico, actualiza Roadmap, registra ADR si aplica, actualiza changelog.
---

# End Slice — `/end-slice <SXX>`

Use this workflow at the end of every slice implementation, before declaring it `DONE`.

## Inputs

- `<SXX>` — slice ID being closed.

## Steps

1. **Locate the slice mini-brief** at `docs/slices/<SXX>_<name>.md`. Refuse to continue if it does not exist (means `/start-slice` was skipped).

2. **Verify Universal DoD (12 items from rule `04_dod_universal.md`).** For each item, confirm or block:

   - [ ] Works end-to-end on QBox (smoke test passed).
   - [ ] Works end-to-end on QBCore (smoke test passed).
   - [ ] Smoke test of happy path documented in mini-brief.
   - [ ] Automated tests where they make sense.
   - [ ] No hardcoded user-facing strings (locales/{es,en}.lua complete).
   - [ ] No hardcoded magic numbers (config files used).
   - [ ] Respects 5 Pillars of Bible §3.
   - [ ] Respects Bible §9.4 anti-patterns.
   - [ ] Respects naming conventions (rule `02_naming_conventions.md`).
   - [ ] DB migration versioned + rollbackable (if DB was touched).
   - [ ] Mini-brief updated with what was actually built.
   - [ ] ADR created if non-obvious architectural decision was taken.
   - [ ] Bible §18 changelog updated if product canon changed.

   If ANY item fails, halt. Report which items fail. Do not mark the slice as `DONE`.

3. **Verify slice-specific DoD** as documented in the mini-brief. Same rule: any failure blocks closure.

4. **Update Roadmap** at `docs/01_ROADMAP.md`:
   - Slice state: `IN_REVIEW` → `DONE`.
   - Add a one-line completion note next to the slice header (date + commit ref if available).

5. **ADR check**: if the slice took an architectural decision not already covered by the Bible (e.g. chose a specific FSM library, picked a particular animation approach, decided on a cache strategy), create a new ADR in `docs/02_DECISIONS.md` following the template at the top of that file.

6. **Bible changelog**: if the slice changed product canon (added a new pillar nuance, refined a quality factor, changed an anti-feature), update `docs/00_BIBLE.md` §18 with a new row.

7. **Mini-brief closing summary**: update the "Closing summary" section of `docs/slices/<SXX>_<name>.md` with:
   - What shipped (deliverables actually completed).
   - What deviated from plan (if anything).
   - Discoveries / lessons (1-3 bullets).
   - Pointers for next slices that depend on this one.

8. **Suggest commit message** (English, conventional commits style):

   ```
   feat(<domain>): <SXX> — <slice name>

   - <key deliverable 1>
   - <key deliverable 2>

   Closes <SXX>.
   ```

9. **Report to user**: a 3-line summary — slice closed, what shipped, what is unblocked next.

## Notes

- This workflow is the only legitimate way to mark a slice `DONE`.
- A failed DoD item is not a reason to lower the bar; it is a reason to keep working OR to renegotiate the slice's scope explicitly with the founder.
- If the founder insists on closing despite a failed item, document the exception in the mini-brief's closing summary AND in an ADR.
