# S18 — Maquinaria estado + mantenimiento

> **Status:** ACTIVE
> **Phase:** Phase 2 — Depth & Scale
> **Complexity:** L
> **Roadmap reference:** [docs/01_ROADMAP.md#s18](../01_ROADMAP.md)
> **Started:** 2026-05-23
> **Closed:** TBD
> **Author:** PM Agent + Backend Agent

---

## 1. Scope

Sistema paralelo de "machinery state" (Bible §10.3). Cada vehículo agrícola tiene una durabilidad de 0-100 que decae con el uso (distancia recorrida o tiempo operando en parcelas).
A menor durabilidad (<30), mayor es la probabilidad de sufrir averías durante una operación. Las averías implican animaciones de rotura, tiempos muertos (pause) y requerimiento de reparación.
El mantenimiento preventivo (usando el ítem `sonar_machinery_kit` o interactuando con un NPC mecánico) restaura la durabilidad.
Si un vehículo llega a 0, queda inoperativo hasta ser reparado.

## 2. Goal (Wooow Test outcome)

Un jugador está usando un tractor. De repente, el tractor echa humo y el motor se apaga (durabilidad crítica o evento de avería). El jugador tiene que bajarse, abrir el capó, usar un `sonar_machinery_kit` (con un minijuego o barra de progreso) para repararlo antes de poder seguir trabajando.

## 3. Dependencies

| Slice | Reason                                                                  | Status |
| ----- | ----------------------------------------------------------------------- | ------ |
| S16   | Fin de la lógica principal de simulación de cultivos (para no bloquear) | DONE   |

## 4. Deliverables

- [x] `013_machinery.sql` (tabla `sonar_farm_machinery_state` por `plate` o identificador de red).
- [x] `config/machinery.lua` con modelos de tractores/vehículos, ratios de desgaste y configs de avería.
- [x] `server/machinery/machinery_service.lua` (tracking de uso, persistencia).
- [x] Ítem físico: `sonar_machinery_kit` registrado en DB/inventario y logic para aplicarlo.
- [x] Eventos: `sonar:farm:machinery:broke_down`, `sonar:farm:machinery:repaired`.
- [x] (Opcional en backend puro, pero requerido en client) Interacción para reparar con el kit y animación de avería.

## 5. Universal DoD checklist

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [x] Automated tests where they make sense.
- [x] No hardcoded user-facing strings — `locales/{es,en}.json` complete.
- [x] No hardcoded magic numbers — config files used.
- [x] Respects 5 Pillars of Bible §3.
- [x] Respects Bible §9.4 anti-patterns.
- [x] Respects naming conventions (rule `02_naming_conventions.md`).
- [x] DB migration versioned + rollbackable (if DB was touched).
- [x] Mini-brief updated with what was actually built (this file).
- [x] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [ ] Bible §18 changelog updated if product canon changed.

## 6. Slice-specific DoD

- [x] La durabilidad de los vehículos decae con su uso y se persiste.
- [x] Vehículos con durabilidad baja tienen probabilidad de averiarse.
- [x] Las averías frenan el uso del vehículo (bloquean motor).
- [x] El uso del kit restaura durabilidad y arregla el motor.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                              | Prompt block in `.prompts.md` |
| ----------------- | ----------------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Base de datos de maquinaria, tracking service, registro del kit de mantenimiento.               | yes                           |
| Integration Agent | Loops de desgaste (client-side dist), averías (nativos de vehículo), interacción de reparación. | yes                           |

## 8. Architecture notes

- Backend implemented as a dedicated machinery domain with `config/machinery.lua`, `server/machinery/machinery_service.lua`, and `server/machinery/init.lua`, wired in `fxmanifest.lua` and `server/main.lua`.
- Persistence uses `sonar_farm_machinery_state` keyed by `plate`, matching the slice brief and keeping server state authoritative per Bible §3 Pillar 1.
- Wear is config-driven and applied from integration-reported usage batches, not a per-frame or global polling loop, to respect Bible §9.4 anti-pattern §4.
- `sonar_machinery_kit` was added to `config/items.lua`; a separate `Config.Farm.NPCs.vendors.mechanic` catalog entry was added in `config/npcs.lua` without changing the existing B2 buyer contract.
- Server wiring includes `sonar:farm:machinery:report_usage` and `sonar:farm:server:repair_machinery`, plus event relay for `sonar:farm:machinery:broke_down` and `sonar:farm:machinery:repaired`.
- The repair handler is backend-ready but still depends on the Integration Agent for ox_target, progress bar, hood interaction, and native engine failure/recovery effects.

## 9. ADRs created

- ADR-020 — Machinery wear uses integration-reported usage batches with server clamps.

## 10. Smoke test (happy path)

- Automated backend validation completed with `tests/server/machinery_spec.lua` covering seeded state, wear persistence, critical-threshold breakdown, and repair reset.
- In-game happy-path smoke remains pending until the Integration Agent wires the vehicle target interaction, progress bar, and native engine breakdown effects on QBox and QBCore.

## 11. Closing summary (filled at /end-slice)

_(To be filled at the end)_
