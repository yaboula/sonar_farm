# S19 — Catálogo completo NPCs + UI Mercado

> **Status:** ACTIVE
> **Phase:** Phase 3 — Economy Alive
> **Complexity:** L
> **Roadmap reference:** [docs/01_ROADMAP.md#s19](../01_ROADMAP.md)
> **Started:** 2026-05-23
> **Closed:** TBD
> **Author:** PM Agent + Backend Agent + Frontend Agent

---

## 1. Scope

Expandir el sistema de venta de Farm Sonar de un solo NPC genérico (Pedro de B2) a un catálogo completo de 6-10 NPCs únicos. Cada NPC define su propia personalidad económica: qué cultivos compra, qué calidad mínima exige, su rango de precio, su volumen máximo de compra diaria y su disponibilidad para firmar contratos B2B (en S21).
A nivel cliente, los NPCs se ubican físicamente en la ciudad cerca de la zona agrícola con `ped` model único, blip en el mapa y `ox_target` para iniciar venta o ver detalles.
A nivel UI, la nueva app **Market** en el Laptop permite al jugador ver de un vistazo qué paga cada NPC hoy por cada cultivo × calidad, su threshold, y si tiene contratos disponibles.

## 2. Goal (Wooow Test outcome)

El jugador abre su laptop por la mañana, entra a la app Market, y de un vistazo Bento ve 8 cards de NPCs: uno paga premium por trigo calidad A, otro acepta hortícolas en volumen pero a precio menor. Decide qué cultivar y a quién venderle. Va físicamente al NPC (blip en el mapa) e interactúa con `ox_target` para vender directamente. Siente que opera un negocio real con clientes reales.

## 3. Dependencies

| Slice | Reason                                                  | Status |
| ----- | ------------------------------------------------------- | ------ |
| S3    | Banca para cobros                                       | DONE   |
| S4    | NUI shell (Laptop + design system)                      | DONE   |
| S10   | NPC vendor inicial (Pedro) — refactorizable a múltiples | DONE   |

## 4. Deliverables

- [ ] Refactor `config/npcs.lua` a catálogo expandido con 6-10 NPCs (modelo ped, coords, heading, blip sprite/color, accepted_crops, calidad mínima, range price multiplier, volumen diario, contracts_enabled flag).
- [ ] Migration `010_npc_buyers.sql` (precio actual cacheado + volumen restante hoy + last_reset_ts).
- [ ] Refactor `server/npcs/npc_buyer_service.lua` para soportar múltiples NPCs y aplicar quality/volume/personality logic.
- [ ] `client/npcs/npc_spawner.lua` que spawnea peds + blips + ox_target zones desde el config.
- [ ] UI: nueva app **Market** en `sonar_farm_tablet/web/src/apps/Market/MarketApp.tsx` con grid Bento por NPC.
- [ ] Callback NUI `sonar:farm:market:get_catalog` que devuelve estado actual del mercado.
- [ ] Locales EN/ES para nombres de NPCs y textos UI.
- [ ] Mockup v0.dev validado (ver `S19_npc_catalog_market_ui.ui_brief.md`).
- [ ] Tests del servicio (volume tracking, personality enforcement, price calculation).

## 5. Universal DoD checklist

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests where they make sense.
- [ ] No hardcoded user-facing strings — `locales/{es,en}.json` complete.
- [ ] No hardcoded magic numbers — config files used.
- [ ] Respects 5 Pillars of Bible §3.
- [ ] Respects Bible §9.4 anti-patterns.
- [ ] Respects naming conventions (rule `02_naming_conventions.md`).
- [ ] DB migration versioned + rollbackable (if DB was touched).
- [ ] Mini-brief updated with what was actually built (this file).
- [ ] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [ ] Bible §18 changelog updated if product canon changed.

## 6. Slice-specific DoD

- [ ] Los 6-10 NPCs aparecen físicamente en el mundo con sus peds, blips y interacciones ox_target.
- [ ] Cada NPC respeta su personalidad: rechaza cultivos no aceptados, calidades menores a su threshold, y compras que excedan su volumen diario.
- [ ] La app Market muestra el catálogo en tiempo real y se refresca al abrirla.
- [ ] El refactor no rompe la venta a Pedro (compatibilidad hacia atrás).

## 7. Sub-agents involved

| Agent             | Role in this slice                                    | Prompt block in `.prompts.md` |
| ----------------- | ----------------------------------------------------- | ----------------------------- |
| Backend Agent     | DB, refactor service, validación de personalidad NPC. | yes                           |
| Integration Agent | Spawner de peds, blips, ox_target zones.              | yes                           |
| Frontend Agent    | App React Market con Bento Grid.                      | yes                           |

## 8. Architecture notes

_(To be filled during execution)_

## 9. ADRs created

_(To be filled during execution)_

## 10. Smoke test (happy path)

_(To be filled during execution)_

## 11. Closing summary (filled at /end-slice)

_(To be filled at the end)_
