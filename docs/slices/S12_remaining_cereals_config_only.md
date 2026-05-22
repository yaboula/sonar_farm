# S12 — Remaining cereals via config-driven system

## 1. Canon

- Bible §3 Pillar 5: new crops must be added via config/assets, not hardcoded gameplay logic.
- Bible §13 crop family canon includes wheat, corn, and barley in cereals.
- Roadmap S12: add corn + barley config, items, stages, and prove the system is truly reusable.

## 2. What was built

### Config-only crop additions

- `sonar_farm_core/config/crops/corn.lua`
- `sonar_farm_core/config/crops/barley.lua`
- `sonar_farm_core/config/verified_props.lua`
  - verified stage props for corn and barley

### Minimal upstream de-hardcoding required to satisfy Pillar 5

The existing B1 flow still hardcoded wheat in multiple integration points, so S12 required a minimal upstream fix to restore the intended config-driven contract instead of shipping a fake “config-only” slice.

Updated files:

- `sonar_farm_core/shared/items/item_registry.lua`
  - registry now builds seed + batch items from all configured crops
- `sonar_farm_core/server/main.lua`
  - plant/harvest callbacks now use dynamic `crop_type`
- `sonar_farm_core/client/plot_interactions.lua`
  - plant options now render per configured crop
- `sonar_farm_core/client/plot_renderer.lua`
  - plot prop rendering now works for any configured crop type
- `sonar_farm_core/client/npc_vendor_interaction.lua`
  - generic sale label for multi-crop buyers
- `sonar_farm_core/config/npcs.lua`
  - Pedro accepts wheat, barley, and corn
- `sonar_farm_core/locales/{en,es}.json`
  - crop names, items, plant labels, generic sale label
- `sonar_farm_core/server/admin/debug_plant.lua`
  - optional crop type for smoke/debug

## 3. Validation

Automated validation passed:

- `lua sonar_farm_core/tests/server/crop_config_spec.lua`
- `pnpm run lint:lua`
- Regression specs:
  - `quality_spec.lua`
  - `physical_item_spec.lua`
  - `lifecycle_spec.lua`
  - `storage_spec.lua`
  - `sale_spec.lua`

## 4. Happy-path smoke script

1. Give yourself `sonar_seed_corn` and plant corn on an extensive plot.
2. Give yourself `sonar_seed_barley` and plant barley on another extensive plot.
3. Fast-forward both plots until harvest-ready.
4. Harvest both and confirm:
   - correct prop progression,
   - correct batch item (`sonar_batch_corn` / `sonar_batch_barley`),
   - metadata uses the correct `crop_type`.
5. Sell one batch to Pedro and verify sale succeeds.

## 5. Current status

- **Code:** implemented.
- **Automated tests:** pass.
- **QBox smoke:** pending founder runtime verification.
- **QBCore smoke:** pending founder runtime verification.
