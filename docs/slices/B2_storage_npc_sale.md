# B2 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Physical Storage + NPC Sale

> **Type:** Slice Bundle (B1 pattern, ADR-014 rules verified below).
> **Slices bundled:** S9 ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· S10
> **Status:** DONE
> **Phase:** Phase 1 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â First Crop End-to-End ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ‚Â­Ãƒâ€šÃ‚Â
> **Complexity:** L (S9 M + S10 L ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ aggregated L; within tope)
> **Roadmap reference:** [`docs/01_ROADMAP.md`](../01_ROADMAP.md) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â S9/S10
> **Started:** 2026-05-22
> **Closed:** 2026-05-22
> **Author:** PM Agent + Backend / Integration / QA sub-agents

---

## Why a bundle?

ADR-014 bundle eligibility check:

1. **Contrato compartido:** S10 sale flow directly reads `sonar_farm_storage_units` rows to validate
   the batch being sold (batch_id, weight_g, quality). S10 DoD item "sell 100 kg wheat B ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ payment ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢
   batch_id leaves inventory" **cannot close without S9 stash mechanics working**. The
   `sonar:farm:sale:completed` event references the `storage_unit_id` the batch came from.
2. **Misma superficie:** Both slices touch `server/storage/`, `server/npcs/`, `client/` interactions,
   and the same Finance adapter (`Sonar.Farm.Finance`). One Backend Agent, one Integration Agent.
3. **DoD sincronizable:** S10 is an explicit Roadmap dependency on S9. Selling from inventory
   (bypassing the silo) is out of scope for both slices; the silo is the canonical flow.
4. **Complexity ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°Ãƒâ€šÃ‚Â¤ XL:** M + L = L. Well within tope.

---

## 1. Scope

### S9 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â AlmacÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©n fÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­sico (silo) (M)

Physical silo at the MLO. Players deposit harvested batches; batches live in an `ox_inventory`
stash (server-side, named per storage unit) while their metadata is also mirrored to
`sonar_farm_storage_units` DB for audit and freshness tracking.

1. `ox_target` on the silo prop ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ "Deposit batch" ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ opens ox_inventory stash UI (player
   side-by-side with silo stash).
2. Player drags `sonar_batch_*` item into silo stash. Server hook validates + mirrors to DB.
3. `ox_target` on same prop ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ "Withdraw batch" ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ same stash UI; player drags back.
4. Freshness continues decaying inside (same `freshness_decay_rate_per_h` as in field ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â silo
   refrigeration is a Wave 2 feature; for now silo = dry storage, same decay rate).
5. Capacity limit: configurable `max_slots` and `max_weight_kg` per storage unit in config.
6. Events: `sonar:farm:storage:deposited`, `sonar:farm:storage:withdrawn`.

### S10 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â NPC comprador ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âºnico + venta fÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­sica (L) ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ‚Â­Ãƒâ€šÃ‚Â

First NPC buyer: **Molino Pedro** (stub ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â a flour mill buyer). Physical vendor marker: a
`prop_ped_*` spawned at a fixed world coordinate (configurable). Player arrives, drives up with
batches in inventory **or** previously staged in silo, and sells via `ox_target` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ "Sell wheat".

1. `ox_target` on Pedro's marker zone ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ "Sell wheat" (visible when player has `sonar_batch_wheat`
   in inventory or has an accessible silo with wheat batches).
2. Server shows price preview: `base_price ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â quality_multiplier` (SÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â2.0, AÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â1.6, BÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â1.0,
   CÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â0.6, DÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â0.3) ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â `weight_kg`. All multipliers in `config/npcs.lua`.
3. Player confirms ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ server validates batch ownership ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ calls `Sonar.Farm.Finance.Credit` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢
   removes `sonar_batch_wheat` from inventory (or marks DB row `sold_ts`) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ updates
   `sonar_farm_batches.sold_ts`.
4. Visual confirmation: ox_lib notify lime `+ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬XXX ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Molino Pedro`.
5. `lineage_chain` of the batch is preserved in `sonar_farm_batches` row (not mutated on sale).
6. Events: `sonar:farm:sale:initiated`, `sonar:farm:sale:completed`.

**Price formula (B2 scope):**

```
payout = base_price_per_kg ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â quality_multiplier[grade] ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â weight_kg
```

Where `base_price_per_kg` and `quality_multiplier` live in `Config.Farm.NPCs.buyers.pedro`.
All other multipliers (freshness, contracts, reputation) are stub ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â 1.0 until S19/S21.

---

## 2. Goal (Wooow Test outcome)

> Player harvests wheat ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ walks to Molino Pedro ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ sells 2.5 kg batch quality B ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ console shows
> `[sale] pedro: sf-xxxxxxxx sold, payout ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬X.XX` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ ox_lib notification appears lime `+ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬X.XX` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢
> `sonar_farm_batches.sold_ts` is populated in DB.

This is the **money shot** of Phase 1. Phase 1 is not "done" until money flows.

---

## 3. Dependencies

| Slice | Reason | Status |
|-------|--------|--------|
| S7 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Physical item | `batch_id`, `BatchMetadata` schema, `sonar_farm_batches` table | DONE |
| S2 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â DB foundation | Migration runner, `Sonar.Farm.DB` | DONE |
| S3 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Finance compat | `Sonar.Farm.Finance.Credit(src, amount, reason)` for sale payout | DONE |
| B1 (S6) | `sonar_batch_wheat` item registered; lifecycle events | DONE |

No blocking dependency is open.

---

## 4. Deliverables

### Backend (S9 + S10)

- [x] Migration `sonar_farm_core/database/migrations/008_storage.sql`
  - `sonar_farm_storage_units` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â one row per physical storage unit (silo, barn, etc.).
  - `sonar_farm_storage_contents` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â one row per batch currently in storage (mirrors ox_inventory stash; source of truth for freshness + audit).
- [x] `sonar_farm_core/config/storage.lua` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â seed config for the initial storage units (1 silo at Grapeseed MLO); `max_slots`, `max_weight_kg`, `storage_type` (`dry`|`cold`), `decay_multiplier` (1.0 for dry).
- [x] `sonar_farm_core/config/npcs.lua` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Molino Pedro config: `world_coords`, `ped_model`, `heading`, `accepted_crops` (`{'wheat'}`), `base_price_per_kg`, `quality_multipliers`, `daily_quota_kg` (stub: 99999).
- [x] `sonar_farm_core/server/storage/storage_service.lua` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â `Sonar.Farm.StorageService` with:
  - `Boot()` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â seeds storage units from config; idempotent (mirrors PlotService pattern).
  - `Deposit(storage_id, player_cid, batch_id, item_name, metadata) -> ok, error` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â validates capacity, inserts `sonar_farm_storage_contents` row, mirrors metadata.
  - `Withdraw(storage_id, player_cid, batch_id) -> ok, metadata, error` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â removes row, returns metadata.
  - `GetUnit(storage_id) -> unit | nil`.
  - `ListContents(storage_id) -> content[]`.
- [x] `sonar_farm_core/server/npcs/npc_buyer_service.lua` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â `Sonar.Farm.NPCBuyerService` with:
  - `Boot()` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â registers NPC buyer configs from `Config.Farm.NPCs.buyers`.
  - `GetBuyer(buyer_id) -> buyer_config | nil`.
  - `CalculatePayout(buyer_id, crop_type, quality_grade, weight_kg) -> amount, breakdown`.
  - `ExecuteSale(src, buyer_id, batch_id) -> ok, payout, error` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â validates batch ownership in player inventory, calculates payout, calls `Sonar.Farm.Finance.Credit`, removes item, stamps `sonar_farm_batches.sold_ts`, emits events.
- [x] `sonar_farm_core/server/admin/storage_reload_command.lua` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â `/sonarfarm:storage:reload` ACE-gated; calls `StorageService.Boot()` (idempotent reseed).
- [x] Tests: `sonar_farm_core/tests/server/storage_spec.lua` + `sale_spec.lua`.

### Integration (S9 + S10)

- [x] `sonar_farm_core/client/silo_interactions.lua` - `ox_target` sphere zone per storage unit; localized "Deposit batch" + "Check storage" options; opens `exports.ox_inventory:openInventory('stash', stash_name)`; unregisters zones on resource stop.
- [x] `sonar_farm_core/client/npc_vendor_interaction.lua` - spawns buyer peds on resource start with `RequestModel` + await loop; registers `ox_target` local-entity option; checks `sonar_batch_wheat` presence client-side; runs ~3 s `lib.progressBar`; calls `lib.callback.await('sonar:farm:sale:sell', ...)`; localized success/error notifications; deletes peds on resource stop.
- [x] `sonar_farm_core/server/main.lua` - boots storage after lifecycle, exposes `sonar:farm:storage:list_units` + `sonar:farm:sale:preview`, and wires `ox_inventory` `swapItems` post-hook audit for silo deposit/withdraw state changes.
- [x] `sonar_farm_core/fxmanifest.lua` - add `config/storage.lua`, `config/npcs.lua` to `shared_scripts`; storage + NPC server files; silo + vendor client files; migration `008_storage.sql` metadata.
- [x] `sonar_farm_core/locales/en.json` + `es.json` - backend + integration locale keys for silo interactions, sale notifications, sale errors, and storage hook logging.

### QA

- [x] `tests/server/storage_spec.lua` - deposit (ok + capacity exceeded); withdraw (ok + not found); idempotent boot.
- [x] `tests/server/sale_spec.lua` - payout formula all grades; ExecuteSale happy path; ExecuteSale batch not in inventory rejected; Finance.Credit called with correct amount.
- [x] Smoke procedure documented in Section 10.
- [x] DoD audit Section 11.

> **No Frontend Agent needed for B2.** S9 uses native `ox_inventory` stash UI. S10 uses ox_lib notify. No new React components required - `QualityBadge` + `FreshnessBar` already exist for future sale screen (S27/S19).

---

## 5. Universal DoD checklist

- [ ] Works end-to-end on QBox (smoke documented in ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§10).
- [ ] Works end-to-end on QBCore (smoke documented in ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§10).
- [ ] Smoke test of happy path documented in ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§10.
- [ ] Automated tests ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â storage capacity, payout formula, sale execution.
- [ ] No hardcoded user-facing strings ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â `locales/{es,en}.json` complete.
- [ ] No hardcoded magic numbers ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prices, multipliers, capacity in `config/storage.lua` + `config/npcs.lua`.
- [ ] Respects 5 Pillars of Bible ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§3.
- [ ] Respects Bible ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§9.4 anti-patterns.
- [ ] Respects naming conventions (`02_naming_conventions.md`).
- [ ] DB migration `008` versioned + rollbackable.
- [ ] Mini-brief updated with what was actually built.
- [ ] ADR created if non-obvious decision taken.
- [ ] Bible ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§18 changelog updated if product canon changed.

---

## 6. Slice-specific DoD

### S9 specific

- [ ] Deposit `sonar_batch_wheat` into silo ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ `sonar_farm_storage_contents` row inserted ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ `batch_id` preserved.
- [ ] Withdraw same batch ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ row deleted ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ `batch_id` back in player inventory unchanged.
- [ ] Capacity exceeded ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ deposit rejected with localized error.
- [ ] Boot idempotent: re-`ensure` does not duplicate storage unit rows.

### S10 specific

- [ ] Sell 2.5 kg wheat quality B ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ payout = `base_price_per_kg ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â 1.0 ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â 2.5` credited to player bank.
- [ ] `sonar_farm_batches.sold_ts` populated after sale.
- [ ] `lineage_chain` of batch unchanged after sale.
- [ ] Batch removed from player inventory after successful sale.
- [ ] ox_lib lime notification shows correct `+ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬X.XX` amount.
- [ ] Selling a batch the player does not own ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ rejected server-side.

---

## 7. Sub-agents involved

| Agent | Role | Prompt block |
|-------|------|--------------|
| Backend Agent | Migrations, StorageService, NPCBuyerService, payout formula, tests | yes |
| Integration Agent | Client zones, ped spawn, fxmanifest, server/main.lua wiring, locales | yes |
| Frontend Agent | **Not needed** ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â no new React components | no |
| QA Agent | Tests, smoke procedure, DoD audit | yes |

Execution order: **Backend first ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Integration (depends on service API) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ QA (depends on both)**.

---

## 8. Architecture notes

### 8.1 Shared contracts (defined before sub-agents start)

#### `sonar_farm_storage_units` schema

| Column | Type | Notes |
|--------|------|-------|
| `storage_id` | `VARCHAR(64) PRIMARY KEY` | Config-owned natural key (same pattern as `plot_id`, ADR-010) |
| `storage_type` | `VARCHAR(32) NOT NULL` | `dry` \| `cold` (cold = Wave 2) |
| `display_name_key` | `VARCHAR(191) NOT NULL` | Locale key |
| `coords_x/y/z` | `DOUBLE NOT NULL` | World anchor for `ox_target` zone |
| `radius` | `DOUBLE NOT NULL DEFAULT 2.0` | Interaction radius |
| `max_slots` | `SMALLINT UNSIGNED NOT NULL` | ox_inventory stash slot count |
| `max_weight_kg` | `DOUBLE NOT NULL` | Total weight cap in kg |
| `decay_multiplier` | `FLOAT NOT NULL DEFAULT 1.0` | Freshness decay modifier (1.0 = same as field) |
| `created_at` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | |

#### `sonar_farm_storage_contents` schema

| Column | Type | Notes |
|--------|------|-------|
| `id` | `INT UNSIGNED AUTO_INCREMENT PRIMARY KEY` | Surrogate (same rationale as `sonar_farm_crops`, ADR-013) |
| `storage_id` | `VARCHAR(64) NOT NULL` | FK ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ `sonar_farm_storage_units.storage_id` |
| `batch_id` | `VARCHAR(32) NOT NULL UNIQUE` | FK ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ `sonar_farm_batches.batch_id`; one row per batch |
| `player_cid` | `VARCHAR(64) NOT NULL` | Who deposited |
| `item_name` | `VARCHAR(64) NOT NULL` | `sonar_batch_wheat` etc. |
| `deposited_ts` | `BIGINT UNSIGNED NOT NULL` | UNIX seconds |
| `created_at` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | |

Index: `KEY idx_sfsc_storage (storage_id)`.

**Note on ox_inventory stash:** The stash name is `sonar_farm_silo_<storage_id>`. ox_inventory
manages the actual item slot/weight; `sonar_farm_storage_contents` is the Farm Sonar audit layer.
On deposit, both are written atomically (server-side item add + DB insert). On withdraw, both are
cleared. If they diverge (e.g. server crash mid-deposit), the stash is authoritative for item
presence; the DB row is the audit trail. Reconciliation is out of scope for B2.

#### Events emitted (B2)

| Event | Emitter | Payload |
|-------|---------|---------|
| `sonar:farm:storage:deposited` | `StorageService.Deposit` | `{ storage_id, batch_id, player_cid, item_name, deposited_ts }` |
| `sonar:farm:storage:withdrawn` | `StorageService.Withdraw` | `{ storage_id, batch_id, player_cid, withdrawn_ts }` |
| `sonar:farm:sale:initiated` | `NPCBuyerService.ExecuteSale` | `{ buyer_id, batch_id, player_cid, crop_type, quality, weight_kg, payout_preview }` |
| `sonar:farm:sale:completed` | `NPCBuyerService.ExecuteSale` | `{ buyer_id, batch_id, player_cid, payout, sold_ts }` |

#### `config/npcs.lua` shape

```lua
Config.Farm.NPCs = Config.Farm.NPCs or {}
Config.Farm.NPCs.buyers = {
    pedro = {
        display_name_key     = 'npcs.pedro.name',
        ped_model            = 's_m_m_farmer_01',
        world_coords         = { x = 1695.0, y = 4825.0, z = 42.0 },
        heading              = 215.0,
        interaction_radius   = 5.0,
        accepted_crops       = { 'wheat' },
        base_price_per_kg    = 0.80,  -- ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬/kg base (quality B)
        quality_multipliers  = { S = 2.0, A = 1.6, B = 1.0, C = 0.6, D = 0.3 },
        freshness_multiplier = 1.0,   -- stub ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â 1.0 until S19
        daily_quota_kg       = 99999, -- stub unlimited until S19/S20
    },
}
```

#### `config/storage.lua` shape

```lua
Config.Farm.Storage = Config.Farm.Storage or {}
Config.Farm.Storage.units = {
    {
        storage_id       = 'silo_grapeseed_01',
        display_name_key = 'storage.silo_grapeseed_01.name',
        storage_type     = 'dry',
        coords           = { x = 1680.0, y = 4820.0, z = 42.0 },
        radius           = 3.0,
        max_slots        = 50,
        max_weight_kg    = 5000,
        decay_multiplier = 1.0,
    },
}
```

#### `lib.callback` registrations (server-side, in `server/main.lua`)

| Callback | Handler |
|----------|---------|
| `sonar:farm:sale:sell` | `NPCBuyerService.ExecuteSale(src, buyer_id, batch_id)` |
| `sonar:farm:storage:list` | `StorageService.ListContents(storage_id)` |

ox_inventory stash open/close is handled client-side via
`exports.ox_inventory:openInventory('stash', stash_name)` ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â no callback needed.

#### `sonar_farm_batches.sold_ts` update

On `ExecuteSale` success, stamp `sold_ts = UNIX_TIMESTAMP()` on the existing row:
```sql
UPDATE `sonar_farm_batches` SET `sold_ts` = ? WHERE `batch_id` = ?
```
`lineage_chain` is **never modified** on sale (append-only per anti-pattern ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§8).

#### Next migration number

B1 Backend Agent split the planned `005_crops_and_batches` into three files:
`005_crops.sql`, `006_batches.sql`, `007_quality_tracking.sql`. The next available number is
**`008`**. B2 migration filename: `008_storage.sql`.

### 8.2 Load order additions to `fxmanifest.lua`

```lua
shared_scripts {
    -- (existing) ...
    'config/storage.lua',
    'config/npcs.lua',
}

server_scripts {
    -- (existing, after lifecycle/scheduler.lua, before server/main.lua) ...
    'server/storage/storage_service.lua',
    'server/npcs/npc_buyer_service.lua',
    'server/main.lua',
    -- (existing admin commands) ...
    'server/admin/storage_reload_command.lua',
}

client_scripts {
    -- (existing) ...
    'client/silo_interactions.lua',
    'client/npc_vendor_interaction.lua',
}

sonar_farm_migration 'database/migrations/008_storage.sql'
```

### 8.3 Boot sequence additions (`server/main.lua`)

After `run_lifecycle_boot()`:
```lua
run_storage_boot()     -- Sonar.Farm.StorageService.Boot() ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â non-fatal
run_npc_buyer_boot()   -- Sonar.Farm.NPCBuyerService.Boot() ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â non-fatal
```

### 8.4 ox_inventory stash pattern

`ox_inventory` stashes are server-side inventories identified by a string name. They persist items
in the `ox_inventory` DB automatically. Farm Sonar uses them as the physical container; we do NOT
duplicate item weight/slot tracking ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â we only track `batch_id` presence for audit in
`sonar_farm_storage_contents`.

Register stash on boot (server):
```lua
exports.ox_inventory:RegisterStash(stash_name, {
    label   = locale('storage.silo_grapeseed_01.name'),
    slots   = unit.max_slots,
    weight  = unit.max_weight_kg * 1000,  -- ox_inventory uses grams
})
```

Open stash client-side on interaction:
```lua
exports.ox_inventory:openInventory('stash', stash_name)
```

Integration implementation note: the client opens the stash directly, and server-side audit is synchronized through `exports.ox_inventory:registerHook('swapItems', nil, { inventoryFilter = { '^sonar_farm_silo_' } })` plus the post-hook event `AddEventHandler(hookId, function(success, payload) ... end)`. This keeps DB writes out of the validation hook and only records deposit/withdraw after the inventory move succeeds.

**Anti-pattern 1 note:** `exports.ox_inventory` calls are allowed (declared `dependency`, not a
cross-Farm-Sonar-resource call). Document with a comment in the code.

### 8.5 Payout formula and audit

The sale payout is calculated server-side only (anti-pattern 2). Client sends intent
(`buyer_id`, `batch_id`); server re-reads batch metadata from ox_inventory, never trusts client
values.

Finance credit uses `Sonar.Farm.Finance.Credit(src, 'bank', payout, 'sale:pedro:<batch_id>', idempotency_key, metadata)` - the
reason string is structured for future audit queries.

Backend implementation note: B2 also adds `009_finance_amount_decimal.sql` and relaxes the
finance/bridge amount validation to 2-decimal precision so the Roadmap payout contract `EUR X.XX`
is preserved end-to-end without integer truncation.

### 8.6 Runtime integration notes

- Buyer peds are spawned from `Config.Farm.NPCs.buyers` on resource start, frozen/invincible, registered via `exports.ox_target:addLocalEntity`, and deleted on resource stop.
- Sale UI remains native `ox_lib` only for B2: no React/NUI changes, all player-facing text comes from `locales/{en,es}.json`.

---

## 9. ADRs created

_(to be filled during implementation)_

- Candidate: stash name convention (`sonar_farm_silo_<storage_id>`) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â may need ADR if it
  affects ox_inventory upgrades.
- Candidate: `sonar_farm_storage_contents` as audit layer alongside ox_inventory stash (why
  dual-write instead of stash-only).

---

## 10. Smoke test (happy path)

Document final runtime results at `/end-slice B2`. Executable target procedure:

### 10.1 Pre-conditions

- Dependencies running: `oxmysql`, `ox_lib`, `ox_inventory`, `ox_target`, QBox or QBCore stack.
- B1 foundation available: at least one unsold `sonar_batch_wheat` exists in player inventory and in `sonar_farm_batches`.
- `Config.Farm.Debug = true` on the test server.
- Admin ACE is granted for `/sonarfarm:storage:reload`.
- Clean boot path preferred: either a fresh DB with migrations `001`-`009` pending, or an existing DB where `008_storage` is already registered.

### 10.2 QBox smoke

1. Start `sonar_farm_core`. Server console must show, in order:
   - `[sonar_farm_core] Farm Sonar core booted (v...)`
   - `[sonar_farm_core] DB connectivity check and migrations starting`
   - `[sonar_farm_core][db] applying migration 008_storage` (first run only)
   - `[sonar_farm_core][db] applied migration 008_storage` (first run only)
   - `[sonar_farm_core] DB boot ready: <applied> migrations applied, <already_applied> already applied, <registered> registered`
   - `[sonar_farm_core] Finance layer ready -> adapter: <adapter> (mode: <mode>)`
   - `[sonar_farm_core] Storage registry boot starting`
   - `[sonar_farm_core] Storage registry ready: 1 created, 0 updated, 0 unchanged, 0 skipped, 1 total` (fresh boot) OR `0 created, 0 updated, 1 unchanged, 0 skipped, 1 total` (restart)
   - `[sonar_farm_core][npcs] NPC buyer boot ready: 1 buyers registered`
   - `[sonar_farm_core] NPC buyers ready: 1 registered`
2. SQL verification after boot:
   ```sql
   SELECT `id`, `name`, `filename`
   FROM `sonar_farm_migrations`
   WHERE `id` = '008';

   SELECT COUNT(*) AS total
   FROM `sonar_farm_storage_units`;

   SELECT `storage_id`, `storage_type`, `max_slots`, `max_weight_kg`
   FROM `sonar_farm_storage_units`
   ORDER BY `storage_id` ASC;
   ```
   Expect: migration row present, `total = 1`, and one unit `silo_grapeseed_01` with `storage_type = 'dry'`.
3. Run `/sonarfarm:storage:reload` as admin. Expect localized output:
   - `═══ Farm Sonar Storage Reload ═══`
   - `Created: 0, Updated: 0, Unchanged: 1, Skipped: 0 (Total: 1)`
   - `════════════════════════════════`
4. Approach `silo_grapeseed_01` and use `Deposit Batch`. Confirm the stash opens and is backed by ID `sonar_farm_silo_silo_grapeseed_01`.
5. Move one `sonar_batch_wheat` from player inventory into the stash. Verify:
   ```sql
   SELECT `storage_id`, `batch_id`, `player_cid`, `item_name`
   FROM `sonar_farm_storage_contents`
   WHERE `storage_id` = 'silo_grapeseed_01';

   SELECT `batch_id`, `sold_ts`, `lineage_chain`, `quality`, `weight_g`
   FROM `sonar_farm_batches`
   WHERE `batch_id` = '<batch_id>';
   ```
   Expect: exactly one storage row with the moved `batch_id`; `sold_ts IS NULL`; `lineage_chain` unchanged.
6. Withdraw the same batch back to player inventory. Verify:
   ```sql
   SELECT COUNT(*) AS total
   FROM `sonar_farm_storage_contents`
   WHERE `batch_id` = '<batch_id>';
   ```
   Expect: `total = 0` and the exact same batch metadata is back in the player inventory.
7. Approach Molino Pedro. `Sell Wheat` must only be visible while the player holds an accepted batch.
8. Trigger the sale. Expect a 3 s progress bar with label `Unloading...`, then a success notify `+€X.XX — Molino Pedro`.
9. SQL verification after sale:
   ```sql
   SELECT `batch_id`, `sold_ts`, `lineage_chain`, `quality`, `weight_g`
   FROM `sonar_farm_batches`
   WHERE `batch_id` = '<batch_id>';

   SELECT `movement_id`, `account`, `amount`, `reason`, `status`
   FROM `sonar_farm_finance_movements`
   WHERE `reason` = 'sale:pedro:<batch_id>'
   ORDER BY `created_at` DESC
   LIMIT 1;
   ```
   Expect: `sold_ts IS NOT NULL`, `lineage_chain` unchanged, finance row present with `account = 'bank'`, `status = 'completed'`, and the expected amount.
10. Confirm `sonar_batch_wheat` is removed from the player inventory and there is no remaining `sonar_farm_storage_contents` row for that `batch_id`.
11. Negative path: fill the silo to capacity, attempt one extra deposit, and verify no additional `sonar_farm_storage_contents` row is created for the rejected batch.

### 10.3 QBCore smoke

Repeat steps 1-11 with `Sonar.Farm.Bridge` resolved to QBCore. B2 has no direct framework calls outside the bridge, so any failure here points to bridge/load-order regression rather than B2 domain logic.

### 10.4 Static checks (QA Agent — 2026-05-22)

| Check | Result | Evidence |
| --- | --- | --- |
| `pnpm run lint:lua` | **PASS** | 0 errors, 0 warnings, 0 parse errors. Selene still prints the known `lua52` standard-library notice, but the run exits successfully. |
| `git diff --check` | **PASS** | CRLF warnings only; no conflict markers and no diff-check errors. |
| `storage_spec.lua` | **PASS** | Runtime executed locally: `storage_spec.lua: OK (deposit, withdraw, capacity, idempotent boot)` |
| `sale_spec.lua` | **PASS** | Runtime executed locally: `sale_spec.lua: OK (payout formula, happy path, failure paths)` |
| No `MySQL.Sync` in B2 Lua | **PASS** | `grep MySQL.Sync` across `sonar_farm_core/**/*.lua` returned 0 matches. |
| `ExecuteSale` is server-authoritative | **PASS** | `server/npcs/npc_buyer_service.lua` re-reads the batch row, re-reads inventory metadata, calculates payout server-side, and only then credits finance. |
| `sold_ts` update / inventory mutation safety | **PASS (documented limitation)** | Cross-system ACID is impossible across `ox_inventory` + MySQL, but B2 restores the item on DB failure and rolls back both `sold_ts` and inventory item if finance credit fails after the DB stamp. |
| Locale parity EN <-> ES for B2 keys | **PASS** | Verified `storage.interaction.*`, `storage.hook.*`, `sale.interaction.*`, `sale.notify.*`, `sale.errors.*`, and `npcs.pedro.name` in both locale files. |
| `008_storage.sql` registered in `fxmanifest.lua` | **PASS** | `fxmanifest.lua` includes `sonar_farm_migration 'database/migrations/008_storage.sql'`. |
| Stash name convention `sonar_farm_silo_<storage_id>` | **PASS** | Verified in `config/storage.lua`, `server/storage/storage_service.lua`, `server/main.lua`, and `client/silo_interactions.lua`. |
| No direct QBox/QBCore calls in B2 code | **PASS** | B2 server/client files use bridge/config/export abstractions only; no framework-specific money or player access is embedded in slice code. |

### 10.5 QBox smoke (Founder — 2026-05-22)

**Results: PASS**

| Step | Result | Evidence |
| --- | --- | --- |
| Migration `008_storage` applied / already registered | **PASS** | Boot console shows `[sonar_farm_core][db] applied migration 008_storage`; migration row present in `sonar_farm_migrations` |
| Storage unit seeded | **PASS** | `sonar_farm_storage_units.total = 1`, `storage_id = 'silo_grapeseed_01'` |
| `/sonarfarm:storage:reload` localized output | **PASS** | Command executed (evidence not captured but confirmed by founder) |
| Deposit to silo inserts audit row | **PASS** | `sonar_farm_storage_contents` row with `batch_id = 'sf-49725c9e'` inserted |
| Withdraw removes audit row | **PASS** | `COUNT(*) = 0` for withdrawn `batch_id` |
| Molino Pedro sale option visible only with inventory batch | **PASS** | In-game interaction confirmed; ped spawned at updated coords `vector4(1682.15, 4840.8, 42.06, 96.43)` |
| Sale stamps `sold_ts` and preserves `lineage_chain` | **PASS** | `sonar_farm_batches.sold_ts = 1779414473`; `lineage_chain = []` (intact) |
| Finance movement created with correct payout | **PASS** | `sonar_farm_finance_movements.reason = 'sale:pedro:sf-49725c9e'`, `amount = 2.00`, `status = 'completed'` |
| Success notify amount | **PASS** | Notification shows `+€ 2.00 — Molino Pedro` |
| Capacity rejection leaves no extra audit row | **PASS** | Test not explicitly captured but confirmed by founder |

### 10.6 QBCore smoke

**Results: PENDING**

> Repeat the same evidence capture as §10.5 with `Bridge.framework == 'qbcore'`. Any divergence from QBox indicates a bridge/runtime issue, not a B2 domain-model issue.

---

## 11. Closing summary

> **QA status (2026-05-22):** static audit completed, automated B2 specs are green, technical blockers (magic numbers + ADR) are resolved, and QBox runtime smoke PASS. QBCore runtime smoke is postponed by founder decision (B2 code uses bridge abstraction only, no framework-specific calls). B2 is **ready to close**.

### DoD verification report (QA Agent — 2026-05-22)

#### Universal DoD (12 items)

| # | Item | Result | Justification |
| --- | --- | --- | --- |
| 1 | Works end-to-end on QBox | **PASS** | Founder/runtime smoke in §10.5 completed with full evidence: storage deposit/withdraw, NPC sale, finance movement, and notify all working. |
| 2 | Works end-to-end on QBCore | **POSTPONED** | Founder decision to postpone QBCore smoke. B2 uses bridge abstraction with no framework-specific calls; QBCore smoke deferred to future session. |
| 3 | Smoke test of happy path documented | **PASS** | §10 now contains executable steps, exact boot/reload log lines, SQL checkpoints, and an evidence table. |
| 4 | Automated tests where they make sense | **PASS** | `storage_spec.lua` and `sale_spec.lua` executed successfully; storage capacity / idempotent boot / payout formula / sale failure paths are covered. |
| 5 | No hardcoded user-facing strings | **PASS** | B2 user-facing labels and notifications route through `locales/{en,es}.json`; EN/ES parity verified. |
| 6 | No hardcoded magic numbers | **PASS** | B2 client timings/retries moved to `Config.Farm.Client.Startup` (RetryCount, RetryWaitMs) and `Config.Farm.Client.NPCVendor` (ModelLoadDeadlineMs, SaleProgressDurationMs, SuccessNotifyDurationMs) in `config.lua`. |
| 7 | Respects the 5 Pillars of Bible §3 | **PASS** | B2 keeps sales/storage server-authoritative, stays inside native GTA/FiveM interaction surfaces, and reuses the universal batch model from B1. |
| 8 | Respects Bible §9.4 anti-patterns | **PASS** | No `MySQL.Sync`; no direct resource-to-resource calls; no client trust for payout or sale ownership; no per-frame polling loops. |
| 9 | Respects naming conventions | **PASS** | Tables, events, items, files, and stash IDs follow the `sonar_*` / `sonar_farm_*` conventions. |
| 10 | DB migration is versioned and rollbackable | **PASS** | `008_storage.sql` is registered in `fxmanifest.lua` and includes rollback SQL. |
| 11 | Mini-brief updated with what was actually built | **PASS** | §4, §8, §10, and §11 reflect the current backend + integration + QA state. |
| 12 | ADR / canon follow-up handled | **PASS** | ADR-015 added to `docs/02_DECISIONS.md` documenting the ox_inventory post-hook/dual-write pattern for storage audit. Bible changelog update remains N/A because product canon did not change. |

#### Slice-specific DoD (10 current items in §6)

##### S9 — Physical storage

| # | Item | Result | Justification |
| --- | --- | --- | --- |
| 1 | Deposit `sonar_batch_wheat` into silo inserts `sonar_farm_storage_contents` row and preserves `batch_id` | **PASS (QBox)** | QBox smoke confirms deposit inserts audit row with `batch_id = 'sf-49725c9e'`. QBCore smoke pending. |
| 2 | Withdraw same batch deletes audit row and restores the unchanged batch | **PASS (QBox)** | QBox smoke confirms `COUNT(*) = 0` after withdraw. QBCore smoke pending. |
| 3 | Capacity exceeded rejects deposit with localized error | **PASS (QBox)** | QBox smoke confirmed capacity rejection works (evidence not explicitly captured but confirmed by founder). QBCore smoke pending. |
| 4 | Boot idempotent on re-ensure | **PASS** | `storage_spec.lua` covers first boot + second boot idempotency; `/sonarfarm:storage:reload` path is defined and documented in §10.2 step 3. |

##### S10 — NPC sale

| # | Item | Result | Justification |
| --- | --- | --- | --- |
| 5 | Sell 2.5 kg wheat quality B credits `base_price_per_kg * 1.0 * 2.5` to bank | **PASS** | `sale_spec.lua` asserts payout `2.0` and verifies `Finance.Credit(... account='bank', amount=2.0 ...)`. |
| 6 | `sonar_farm_batches.sold_ts` populated after sale | **PASS (QBox)** | QBox smoke confirms `sold_ts = 1779414473`. QBCore smoke pending. |
| 7 | `lineage_chain` unchanged after sale | **PASS (QBox)** | QBox smoke confirms `lineage_chain = []` (intact). QBCore smoke pending. |
| 8 | Batch removed from player inventory after successful sale | **PASS** | `sale_spec.lua` verifies the inventory count decreases after the happy path. |
| 9 | ox_lib lime notification shows correct `+€X.XX` amount | **PASS (QBox)** | QBox smoke shows notification `+€ 2.00 — Molino Pedro`. QBCore smoke pending. |
| 10 | Selling a batch the player does not own is rejected server-side | **PASS** | `sale_spec.lua` now covers a batch that exists in DB but is absent from player inventory and expects `batch_not_in_inventory`. |

### Remaining blockers to close B2

- None. QBCore smoke postponed by founder decision; B2 uses bridge abstraction with no framework-specific calls, so QBCore compatibility is expected to work without changes.
