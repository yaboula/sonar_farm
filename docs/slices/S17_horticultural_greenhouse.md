# S17 — Hortícolas + invernadero

> **Status:** ACTIVE
> **Phase:** Phase 2 — Expansión de Cultivos y Factores
> **Complexity:** L
> **Roadmap reference:** [docs/01_ROADMAP.md#s17](../01_ROADMAP.md)
> **Started:** 2026-05-22
> **Closed:** TBD
> **Author:** PM Agent + Backend Agent + QA Agent

---

## 1. Scope

Los 5 cultivos hortícolas (tomate, pimiento, lechuga, cebolla, patata) vía config-only siguiendo el Pilar 5. Esto activa plenamente los sub-nodos Hortalizas/Hojas/Bulbos/Tubérculos.
Además, se introduce el **Invernadero (cristal industrial)** como tipo especial de parcela: `weather_match` será neutro siempre (cuando se implemente el clima, los climas externos no afectan dentro), pero con un coste operativo de mantenimiento y sin el bonus de "optimal weather".

## 2. Goal (Wooow Test outcome)

Un jugador puede ir a una parcela tipo `horticultural` o `greenhouse`, plantar semillas de tomate, pimiento, lechuga, cebolla o patata, ver crecer sus modelos 3D y cosechar sus ítems físicos correctamente.

## 3. Dependencies

| Slice | Reason                                                   | Status |
| ----- | -------------------------------------------------------- | ------ |
| S6    | Cereal lifecycle base para plantar/cosechar              | DONE   |
| S12   | Arquitectura config-only demostrada para añadir cultivos | DONE   |

## 4. Deliverables

- [ ] `config/crops/tomato.lua`
- [ ] `config/crops/pepper.lua`
- [ ] `config/crops/lettuce.lua`
- [ ] `config/crops/onion.lua`
- [ ] `config/crops/potato.lua`
- [ ] Añadir 5x4 = 20 modelos 3D en `config/verified_props.lua` extraídos del catálogo
- [ ] Lógica especial de tipo `greenhouse` en `plot_lifecycle_service` o similar
- [ ] Semillas añadidas en `config/items.lua`
- [ ] Plantilla de locales en `locales/es.lua` y `locales/en.lua`
- [ ] Semillas en `config/npcs.lua` (vendor)
- [ ] Nuevas parcelas `horticultural` y `greenhouse` en `config/plots.lua` (ya existen, solo asegurar que funcionan)

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

- [ ] Los 5 cultivos hortícolas pueden ser plantados.
- [ ] La validación de `plot_type` permite plantar en parcelas `horticultural` e `invernadero` (según se defina en config, aunque el invernadero requiere lógica especial).
- [ ] El Invernadero restringe o permite ciertos cultivos según su naturaleza, y anula el efecto de clima externo (preparación para S16).

## 7. Sub-agents involved

| Agent         | Role in this slice                                                    | Prompt block in `.prompts.md` |
| ------------- | --------------------------------------------------------------------- | ----------------------------- |
| Backend Agent | Añadir cultivos config-only, lógica de invernadero y assets.          | yes                           |
| QA Agent      | Verificar modelos 3D, ítems, traducciones y restricciones de parcela. | yes                           |

## 8. Architecture notes

_(To be filled during execution)_

## 9. ADRs created

_(To be filled during execution)_

## 10. Smoke test (happy path)

_(To be filled during execution)_

## 11. Closing summary (filled at /end-slice)

_(To be filled at the end)_
