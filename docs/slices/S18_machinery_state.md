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

- [ ] `013_machinery.sql` (tabla `sonar_farm_machinery_state` por `plate` o identificador de red).
- [ ] `config/machinery.lua` con modelos de tractores/vehículos, ratios de desgaste y configs de avería.
- [ ] `server/machinery/machinery_service.lua` (tracking de uso, persistencia).
- [ ] Ítem físico: `sonar_machinery_kit` registrado en DB/inventario y logic para aplicarlo.
- [ ] Eventos: `sonar:farm:machinery:broke_down`, `sonar:farm:machinery:repaired`.
- [ ] (Opcional en backend puro, pero requerido en client) Interacción para reparar con el kit y animación de avería.

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

- [ ] La durabilidad de los vehículos decae con su uso y se persiste.
- [ ] Vehículos con durabilidad baja tienen probabilidad de averiarse.
- [ ] Las averías frenan el uso del vehículo (bloquean motor).
- [ ] El uso del kit restaura durabilidad y arregla el motor.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                              | Prompt block in `.prompts.md` |
| ----------------- | ----------------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Base de datos de maquinaria, tracking service, registro del kit de mantenimiento.               | yes                           |
| Integration Agent | Loops de desgaste (client-side dist), averías (nativos de vehículo), interacción de reparación. | yes                           |

## 8. Architecture notes

_(To be filled during execution)_

## 9. ADRs created

_(To be filled during execution)_

## 10. Smoke test (happy path)

_(To be filled during execution)_

## 11. Closing summary (filled at /end-slice)

_(To be filled at the end)_
