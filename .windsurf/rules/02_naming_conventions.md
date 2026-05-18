---
trigger: always_on
---

# Naming Conventions (always-on)

## Database

- Tables: `sonar_farm_*` (e.g. `sonar_farm_plots`, `sonar_farm_batches`).
- Columns: `snake_case`.
- Migrations: `database/migrations/NNN_<description>.sql` (3-digit zero-padded).

## Events (FiveM event bus)

- Format: `sonar:farm:<domain>:<action>` (e.g. `sonar:farm:plot:planted`).
- Domains: `plot`, `crop`, `batch`, `quality`, `pest`, `climate`, `storage`, `sale`, `contract`, `banca`, `company`, `drone`.

## Resources

- `sonar_farm_core` — server logic + config + migrations.
- `sonar_farm_tablet` — NUI (React app).
- Future verticals (wave 2+): `sonar_<vertical>_core`, `sonar_<vertical>_tablet`.

## Items (`ox_inventory` data)

- Seeds: `sonar_seed_<crop>` (e.g. `sonar_seed_wheat`).
- Batches: `sonar_batch_<crop>`.
- Tools: `sonar_<tool>` (e.g. `sonar_water_tank`, `sonar_soil_probe`, `sonar_drone_recon`).
- Fertilizers: `sonar_fertilizer_<type>`.
- Pesticides: `sonar_pesticide_<type>`.

## Files

- Lua: `snake_case.lua` (e.g. `plot_service.lua`, `bridge_qbox.lua`).
- React components: `PascalCase.tsx` (e.g. `BentoGrid.tsx`, `MarketApp.tsx`).
- TS types/interfaces: `PascalCase`.
- TS hooks: `useCamelCase.ts` (e.g. `useBatch.ts`).

## Variables

- Lua: `snake_case` (e.g. `local plot_id = ...`).
- TypeScript/JavaScript: `camelCase` (e.g. `const plotId = ...`).
- Constants (both): `UPPER_SNAKE_CASE` (e.g. `MAX_OFFLINE_HOURS`).

## Bridge interface

- Methods: `Bridge.PascalCase(args)` (e.g. `Bridge.GetPlayer(src)`, `Bridge.AddMoney(src, amount, account)`).

## Service modules (server)

- Pattern: `<domain>_service.lua` exposing a single table `<Domain>Service`.
- Example: `plot_service.lua` exposes `PlotService` with methods.

## Anti-naming rules

- Never `sonar_farm_*` for events (events use colons, tables use underscores).
- Never `Farm.*` or `farm_*` without the `sonar_` prefix in production code.
- Never English/Spanish mix in identifiers (`plot_parcela_id` is forbidden — use `plot_id`).
