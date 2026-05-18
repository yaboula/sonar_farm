# SXX — <slice name>

> **Status:** PLANNED | ACTIVE | IN_REVIEW | DONE | BLOCKED
> **Phase:** Phase N — <phase name>
> **Complexity:** S | M | L | XL
> **Roadmap reference:** [docs/01_ROADMAP.md#sxx](../01_ROADMAP.md)
> **Started:** YYYY-MM-DD
> **Closed:** YYYY-MM-DD (filled at /end-slice)
> **Author:** PM Agent + <sub-agents>

---

## 1. Scope

<2-4 paragraphs. What this slice ships. Copy from Roadmap and expand if useful.>

## 2. Goal (Wooow Test outcome)

<1-2 lines describing the user-visible outcome a player or admin would observe when this slice is DONE. If it is a Foundation slice with no user-visible value, describe the developer-visible outcome instead.>

## 3. Dependencies

| Slice | Reason | Status |
|---|---|---|
| SXX | <why this slice depends on it> | DONE / ACTIVE / PLANNED |

If any dependency is not `DONE`, do not start this slice — escalate to founder.

## 4. Deliverables

Copy from Roadmap, expand as you discover details:

- [ ] `<file path>` — <description>
- [ ] Migration `NNN_<desc>.sql`
- [ ] Service `<domain>_service.lua` exposing `<MethodList>`
- [ ] Event(s) emitted: `sonar:farm:<domain>:<action>`
- [ ] Event(s) consumed: `sonar:farm:<domain>:<action>`
- [ ] Items registered in ox_inventory data
- [ ] Config keys added: `Config.Farm.<...>`
- [ ] Locale keys added in `locales/{es,en}.lua`
- [ ] React components: `<List.tsx>`
- [ ] Tests: `<test file paths>`

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests where they make sense.
- [ ] No hardcoded user-facing strings — `locales/{es,en}.lua` complete.
- [ ] No hardcoded magic numbers — config files used.
- [ ] Respects 5 Pillars of Bible §3.
- [ ] Respects Bible §9.4 anti-patterns.
- [ ] Respects naming conventions (rule `02_naming_conventions.md`).
- [ ] DB migration versioned + rollbackable (if DB was touched).
- [ ] Mini-brief updated with what was actually built (this file).
- [ ] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [ ] Bible §18 changelog updated if product canon changed.

## 6. Slice-specific DoD

<copy from Roadmap. These are the criteria UNIQUE to this slice that the universal DoD does not cover>

- [ ] <criterion 1>
- [ ] <criterion 2>

## 7. Sub-agents involved

| Agent | Role in this slice | Prompt block in `.prompts.md` |
|---|---|---|
| Backend Agent | <1-line role> | yes/no |
| Frontend Agent | <1-line role> | yes/no |
| Integration Agent | <1-line role> | yes/no |
| QA Agent | <1-line role> | yes/no |

If `/spawn-pm` was run, the prompts file is at `docs/slices/<SXX>_<name>.prompts.md`.

## 8. Architecture notes

<discoveries during impl that future slices should know:
- chosen DB schema rationale
- chosen FSM states
- chosen event payload shapes
- chosen UI component contracts
- chosen caching strategy
- anything non-obvious>

## 9. ADRs created

- ADR-NNN — <title> — see `docs/02_DECISIONS.md`.
(or "none" if no ADR was needed)

## 10. Smoke test (happy path)

Documented step-by-step procedure to verify this slice end-to-end on a clean server:

1. Start `sonar_farm_core` and `sonar_farm_tablet` on a QBox dev server.
2. <step>
3. <step>
4. <expected observable result>

Repeat the same procedure on a QBCore dev server.

## 11. Closing summary (filled at /end-slice)

### What shipped

- <list of deliverables actually completed>

### Deviations from plan

- <if any: what was added, removed, or refactored from the original scope>

### Discoveries / lessons

- <1-3 bullets useful for future slices>

### Unblocks

- <list of slices that this one unblocks per Roadmap dependency graph>

### Commit message

```
feat(<domain>): SXX — <slice name>

- <key deliverable 1>
- <key deliverable 2>

Closes SXX.
```
