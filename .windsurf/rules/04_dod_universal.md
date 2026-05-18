---
trigger: always_on
---

# Definition of Done — Universal Checklist

Every slice must pass ALL of these before being marked `DONE`. No exceptions.

## Behavior

1. Works end-to-end on **QBox** (smoke test passed).
2. Works end-to-end on **QBCore** (smoke test passed).
3. Smoke test of the happy path is documented in the slice mini-brief.

## Quality

4. Automated tests where they make sense (economic logic, server validations, formulas, FSMs). Pure visual UI is exempt.
5. No hardcoded user-facing strings — everything in `locales/{es,en}.lua`.
6. No hardcoded magic numbers — everything in `config.lua` or per-domain config files.

## Architecture

7. Respects the **5 Pillars** of Bible §3.
8. Respects the **technical anti-patterns** of Bible §9.4 (no direct calls between resources, server-authoritative, no client-side trust).
9. Respects naming conventions (rule `02_naming_conventions.md`).

## Persistence

10. DB migration is versioned (`database/migrations/NNN_<desc>.sql`) and rollbackable, if the slice touched the DB.

## Documentation

11. Slice mini-brief updated with what was actually built (not the original plan).
12. ADR created in `docs/02_DECISIONS.md` if the slice took a non-obvious architectural decision.
13. Bible §18 changelog updated if the slice changed product canon.

## How to enforce

- The `/end-slice <SXX>` workflow runs this checklist programmatically and refuses to close if any item is missing.
- No `DONE` mark in the Roadmap until all items pass.
