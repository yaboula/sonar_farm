# S3 — Finance compatibility layer

> **Status:** ACTIVE
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** L (7-14 days)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S3](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** —
> **Author:** PM Agent (Cascade) + Backend / Integration / QA sub-agents

---

## 1. Scope

S3 creates Farm Sonar's foundational finance compatibility layer. Farm Sonar must remain standalone and must not require `sonar_bank`, `sonar_bank_app`, Renewed Banking, okokBanking, qs banking or any other external bank resource. This is mandated by Bible §2.3 (plug-and-play promise), Bible §8.1 (standalone mode) and ADR-008.

The slice provides a server-side finance adapter contract used by later gameplay slices when they need to read balances, credit sale payouts, debit costs or create an audit trail. The baseline adapter delegates to `Sonar.Farm.Bridge` so QBox and QBCore native money work without any bank script installed.

Farm Sonar keeps an internal append-only finance movement ledger for agricultural audit/idempotency only. It is not a mandatory replacement for the server's bank. External bank integrations are adapter-only and must be optional.

Escrow is intentionally deferred out of the default S3 implementation. S3 may define the interface notes needed for future escrow, but production escrow FSM belongs to a later slice before S21 contracts need it. This keeps S3 focused on compatibility and avoids over-engineering.

## 2. Goal (Wooow Test outcome)

Developer-visible outcome: on a clean QBox server, Farm Sonar can select a finance adapter on boot, credit/debit a player's bank account through the Bridge, and persist an idempotent `sonar_farm_finance_movements` audit row for every money mutation.

## 3. Dependencies

| Slice | Reason                                                               | Status  |
| ----- | -------------------------------------------------------------------- | ------- |
| S0    | Workspace/resource skeleton and config conventions                   | DONE ✅ |
| S1    | `Sonar.Farm.Bridge` exposes player and money methods for QBox/QBCore | DONE ✅ |
| S2    | DB wrapper and migration runner required for finance tables          | DONE ✅ |

If any dependency regresses from `DONE`, do not implement S3 — escalate to founder.

## 4. Deliverables

### DB / migrations

- [ ] `sonar_farm_core/database/migrations/003_finance_core.sql` — creates `sonar_farm_finance_movements` and `sonar_farm_finance_idempotency`; removes or supersedes the S2 smoke table if appropriate.
- [ ] `sonar_farm_core/database/README.md` — update with rollback notes for migration 003.
- [ ] `sonar_farm_core/fxmanifest.lua` — register migration 003 in `files` / `sonar_farm_migration` metadata.

### Lua server

- [ ] `sonar_farm_core/server/finance/money_adapter.lua` — public interface: `GetBalance`, `Credit`, `Debit`, `Transfer`, `CanAfford`, `GetActiveAdapter`.
- [ ] `sonar_farm_core/server/finance/adapters/native_bridge.lua` — baseline adapter using `Sonar.Farm.Bridge.GetMoney/AddMoney/RemoveMoney`.
- [ ] `sonar_farm_core/server/finance/adapters/qbox.lua` — optional adapter shell if it adds value beyond `native_bridge`; otherwise document why `native_bridge` is enough for QBox.
- [ ] `sonar_farm_core/server/finance/adapters/qbcore.lua` — optional adapter shell if it adds value beyond `native_bridge`; otherwise document why `native_bridge` is enough for QBCore.
- [ ] `sonar_farm_core/server/finance/movement_service.lua` — append-only audit/idempotency service for Farm money mutations.
- [ ] `sonar_farm_core/server/finance/init.lua` — boot adapter selection, validation and event publication.
- [ ] `sonar_farm_core/config/finance.lua` — adapter mode/config only if needed; no hardcoded tunables in code.

### External-bank compatibility documentation

- [ ] Document adapter extension points for future `sonar_bank`, Renewed Banking, okokBanking and qs-style banking.
- [ ] Do not implement external adapters without verified APIs.
- [ ] No direct production dependency on any bank resource outside `sonar_farm_core`.

### Locales / docs

- [ ] `sonar_farm_core/locales/en.json` and `sonar_farm_core/locales/es.json` — admin-visible finance boot / error strings if added.
- [ ] `sonar_farm_core/server/finance/INTERFACE.md` — adapter contract and error codes.
- [ ] This mini-brief updated with actual implementation notes.

### Tests / verification

- [ ] Automated/static tests for adapter selection, idempotency and movement append-only behavior where feasible.
- [ ] QBox smoke: credit/debit/can-afford through `native_bridge` and verify movement rows.
- [ ] QBCore smoke before Phase 0 closure, unless blocked and documented.

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests where they make sense.
- [ ] No hardcoded user-facing strings — `locales/{es,en}.json` complete for any admin-visible strings.
- [ ] No hardcoded magic numbers — config files used for tunables.
- [ ] Respects 5 Pillars of Bible §3.
- [ ] Respects Bible §9.4 anti-patterns.
- [ ] Respects naming conventions (rule `02_naming_conventions.md`).
- [ ] DB migration versioned + rollbackable.
- [ ] Mini-brief updated with what was actually built.
- [ ] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [ ] Bible §18 changelog updated if product canon changed.

## 6. Slice-specific DoD

- [ ] No direct call to `sonar_bank`, `sonar_bank_app`, Renewed, okok, qs or another external bank resource outside explicit optional adapters.
- [ ] QBox/QBCore native money works through `Sonar.Farm.Bridge` with no additional bank installed.
- [ ] Adapter selection is configurable or autodetected and visible in boot logs.
- [ ] Every successful money mutation is idempotent and leaves an append-only audit row in `sonar_farm_finance_movements`.
- [ ] Failed debits do not create misleading successful movement rows.
- [ ] S3 does not implement production escrow unless founder explicitly reopens scope; future escrow requirements are documented for S21/S3b.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                      | Prompt block in `.prompts.md` |
| ----------------- | --------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Owns migration 003, finance services, adapter contract, idempotency and movement ledger | yes                           |
| Frontend Agent    | Not needed; S3 has no NUI deliverable                                                   | no                            |
| Integration Agent | Owns fxmanifest wiring, config/locales boot glue and Bridge-facing adapter integration  | yes                           |
| QA Agent          | Owns test matrix, smoke procedures, DoD audit and regression checks                     | yes                           |

Prompts file: `docs/slices/S3_finance_compatibility_layer.prompts.md`.

## 8. Architecture notes

Initial PM guidance before implementation:

- ADR-008 is authoritative: S3 is a finance compatibility layer, not a mandatory bank replacement.
- Baseline money flow: gameplay service → `Sonar.Farm.Finance` / money adapter → `Sonar.Farm.Bridge` → QBox/QBCore framework money.
- Movement ledger records Farm Sonar business events, reason, actor, amount, direction, adapter, idempotency key and status. It must be append-only.
- External bank support must be adapter-only. If a future adapter needs `exports['some_bank']`, that export call must live only inside the adapter and be optional/config-gated.
- No external-bank adapter should be implemented from guesses. Renewed/okok/qs APIs require verified research or local code before production support.
- Escrow is deferred from S3 default scope to avoid mixing compatibility foundation with contract/vending FSMs.

Suggested movement fields for Backend to validate:

- `id` or `movement_id` primary key.
- `idempotency_key` unique for successful logical operations.
- `citizen_id`, `src` if available, `account` (`cash`/`bank`).
- `direction` (`credit`/`debit`/`transfer_in`/`transfer_out`).
- `amount`, `reason`, `adapter_name`, `status`, `error_code`.
- `metadata_json` for future sale/contract references.
- `created_at` timestamp.

Suggested event payloads:

- `sonar:farm:banca:adapter_selected`: `{ adapter_name, mode, reason }`.
- `sonar:farm:banca:movement_created`: `{ movement_id, citizen_id, direction, amount, account, reason, adapter_name, status }`.

## 9. ADRs created

- ADR-008 — Design Farm finance as a compatibility adapter layer, not a hard bank dependency — see `docs/02_DECISIONS.md`.

## 10. Smoke test (happy path)

### QBox baseline smoke

1. Start a QBox dev server with `ox_lib`, `oxmysql`, `ox_inventory`, `ox_target`, `sonar_farm_core`.
2. Ensure the active finance adapter is `native_bridge` or the configured QBox-compatible adapter.
3. Run the S3 test command or smoke harness created by QA to credit a small configured test amount to an online player.
4. Verify the player's framework bank balance increases through `Sonar.Farm.Bridge`.
5. Verify `sonar_farm_finance_movements` has one append-only `credit` row with the expected idempotency key.
6. Repeat the same logical operation with the same idempotency key.
7. Verify no duplicate money mutation and no duplicate successful movement row are created.
8. Run a debit that the player can afford and verify balance decreases + movement row exists.
9. Run a debit above balance and verify it fails safely with no successful movement row.

### QBCore baseline smoke

Repeat the same procedure on QBCore before Phase 0 closure. If a QBCore environment is not available during S3, document the blocker explicitly in §11 and do not hide it.

## 11. Closing summary (filled at /end-slice)

### What shipped

- TBD

### Deviations from plan

- TBD

### Discoveries / lessons

- TBD

### Unblocks

- S10 — NPC buyer sale payout through the finance adapter.
- S21 — future contracts/escrow work, after escrow scope is implemented or explicitly reintroduced.
- S23 — company finance can build on the same adapter/ledger pattern.

### Commit message

```text
feat(finance): S3 — finance compatibility layer

- add Farm finance adapter contract and native Bridge adapter
- add finance movement/idempotency migration
- document external bank adapter extension points
- add smoke coverage for credit/debit/idempotency

Closes S3.
```
