# S19 — Sub-agent prompts

All three agents must first read, in order:

1. `docs/slices/S19_npc_catalog_market_ui.md` (slice mini-brief + DoD).
2. `docs/slices/S19_npc_catalog_market_ui.ui_brief.md` (UI canon + v0 review outcome).
3. `docs/00_BIBLE.md` §3 (Pillars), §9.4 (anti-patterns), §12 (NPC catalogue), §15 (UI paradigm).
4. `docs/handoff/PM_AGENT.md` if missing context.
5. Their own surface: existing files in `sonar_farm_core/config/npcs.lua`, `sonar_farm_core/server/npcs/*`, `sonar_farm_tablet/web/src/`, plus the v0 reference clone at `_v0_review_market/`.

Do not restate what is in those documents in your output. Cite the section that justifies a non-obvious decision and move on.

---

## Backend Agent

You own the data and rules layer of the multi-buyer catalogue.

Deliverables, in priority order:

1. Migration `010_npc_buyers.sql` creating `sonar_farm_npc_buyer_state` keyed by `buyer_id`. Columns at minimum: `volume_remaining_today_g`, `today_top_price_eur_per_g`, `last_reset_ts`, `updated_ts`. Idempotent boot reconciliation against `config/npcs.lua`.
2. Expand `config/npcs.lua` from the single legacy Pedro entry to 6-10 buyers honouring Bible §12. Each entry must include: `id`, `display_name_key`, `kind`, `district_key`, `ped_model`, `coords` (vec4), `blip` (sprite + color + scale), `accepted_crops` (crop → `min_quality`, `base_price_eur_per_g`, `daily_capacity_g`), `contracts_enabled`, `personality_modifier` (price multiplier hint for S20). Pedro becomes `byr_molino_pedro` to keep B2 sales working; do not break existing sale flow.
3. Refactor `server/npcs/npc_buyer_service.lua` to operate per-buyer (no global "Pedro" hardcoded). Reuse the existing sale callback signature so B2 smoke still passes. Reject offers that fail `accepted_crops`, `min_quality`, or remaining `volume_remaining_today_g`.
4. New NUI lib callback `sonar:farm:market:get_catalog` returning a snapshot ready for the Market app. Shape (the Frontend Agent depends on this contract):

   ```lua
   {
     day = number,                -- from climate service
     season_key = string,
     server_now_ts = number,
     buyers = {
       {
         id = string,
         display_name_key = string,
         kind_key = string,
         district_key = string,
         coords = { x, y, z, w },
         distance_m = number,     -- computed per-player on the server
         contracts_open = boolean,
         featured = boolean,      -- exactly one true
         updated_ts = number,
         top_price_eur_per_g = number,
         capacity_remaining_g = number,
         capacity_total_g = number,
         delta_since_last_check = "price_up" | "price_down" | "volume_up" | "volume_down" | "new_contract" | "stable",
         crops = {
           { crop = string, min_quality = "S"|"A"|"B"|"C"|"D", price_eur_per_g = number, capacity_total_g = number, capacity_taken_g = number }
         }
       }
     }
   }
   ```

   `featured` is the buyer with the highest `top_price_eur_per_g`. Ties broken by lowest `distance_m`.

5. Tests (`tests/server/npc_buyer_spec.lua` extended): personality enforcement (rejects), volume tracking (decrements), daily reset, sale path unchanged for the legacy Pedro mapping.
6. Locales: keys for buyer display names, kinds, districts, and "set on map" CTA in `sonar_farm_core/locales/{en,es}.json`.

Hard rules:

- No direct calls to other resources. Use `Bridge.*` only.
- No magic numbers in service code; everything tunable lives in `config/npcs.lua`.
- Audit deltas go through the existing event bus, not new ad-hoc tables.

Stop conditions: when `pnpm run lint:lua` is 0/0, all specs green, and the catalog callback returns the documented shape against a seeded DB.

---

## Integration Agent

You own the physical presence of buyers in the FiveM world.

Deliverables:

1. `sonar_farm_core/client/npcs/npc_spawner.lua` that on resource start reads `Config.Farm.NPCs.buyers`, spawns each ped at its `coords` + `heading`, adds a `blip` per the config, and registers an `ox_target` zone on the ped exposing **two** options: "Sell harvest" (existing flow, must keep working for legacy `byr_molino_pedro`) and "Show route" (sets a FiveM waypoint to the buyer's coords; this is the Pilar-1-compliant counterpart to the Market app's "Set on map" CTA).
2. Anchor the spawn layout on the founder-provided origin `vec4(2123.58, 4805.15, 40.2, 115.22)`. Distribute the remaining 7-9 buyers in a staggered line in front of that anchor along its heading vector (115.22°), with spacing the Backend Agent put in `Config.Farm.NPCs.spawn_layout.spacing_m`. Default spacing 6.0m if absent. Compute each subsequent buyer's coords + heading server-side or in shared config, never hardcoded in the spawner.
3. Bridge between Market app and waypoint: net event `sonar:farm:market:set_waypoint` (server → client → `SetNewWaypoint`). The Market UI sends a NUI message that the Lua client receives and forwards.
4. Cleanup on resource stop: delete peds, remove blips, remove targets. No leaks.
5. Respect Bible §9.4: no per-frame polling, no client-authoritative state. The ped/blip set is built once at boot and on `sonar:farm:npc:catalog_reloaded`.

Hard rules:

- Do not duplicate the existing Pedro spawn if it lives elsewhere; consolidate into this spawner.
- Heading and coords come from config, never the client.

Stop conditions: walk to any buyer, both `ox_target` options appear, "Show route" plants a blip at the buyer location, blips visible on the pause menu map, and resource restart leaves zero orphan peds.

---

## Frontend Agent

You own the Market app on the Laptop NUI.

Source of truth for visuals: the v0 reference clone at `_v0_review_market/frontend/src/`. Treat it as a baseline you port and refine, not invent again.

Deliverables:

1. New app at `sonar_farm_tablet/web/src/apps/Market/` containing `MarketApp.tsx` plus a `components/` subfolder mirroring the v0 split (`PulseBar`, `MarketHeader`, `FeaturedBuyerCard`, `BuyerCard`, `CropFilterBar`, `QualityChip`, `SkeletonState`, `EmptyState`). Convert JSX → TSX, type the buyer catalog using the contract documented in the Backend Agent's section.
2. Wire data through the existing NUI fetch hook (look at how `Plots` consumes its callback in `sonar_farm_tablet`). Call `sonar:farm:market:get_catalog` on mount and on the user's refresh action. While the callback resolves, render `SkeletonState`; on empty list, render `EmptyState`; otherwise the loaded layout.
3. **CTA rename:** every "Plan delivery" / "Plan" label becomes "Set on map" (i18n key `market.cta.set_on_map`). On click, post a NUI message `{ type: 'sonar:farm:market:set_waypoint', buyer_id }` consumed by the Integration Agent's client script.
4. Keep the founder-approved lime distribution from the v0 mockup; do not prune it.
5. Convert all hardcoded strings (including the buyer-domain copy) to i18n keys. Spanish + English in the same PR.
6. Unit conversion at the data-layer boundary only: display `€/kg` and `t`/`kg`, but the payload carries `€/g` and grams.
7. Register the Market app in the Laptop shell router shipped in S4 and add its sidebar entry (icon: Lucide `bar-chart-3` or designer's pick, must match S4 sidebar conventions).
8. Lint, typecheck, build: `pnpm -F @farm/tablet lint && pnpm -F @farm/tablet typecheck && pnpm -F @farm/tablet build` must all be clean.

Hard rules:

- No new design system primitives unless the v0 mockup already introduced them. Reuse the S4 shell.
- No state in components beyond local UI state (filter, drawer open). Server state goes through the callback.
- Do not import from `_v0_review_market/`; copy the files into the workspace, adapt, and delete the clone after the PR lands.

Stop conditions: opening the Laptop in-game, navigating to Market, seeing the live catalog with the founder's 8+ buyers, clicking "Set on map" on any buyer plants the FiveM waypoint, and all three states (loaded, loading, empty) render correctly under simulated server responses.

---

## PM Agent hand-back

Each agent reports back with: files touched, contracts honoured, smoke evidence, and any deviation from this prompt with justification citing the Bible/Roadmap.
