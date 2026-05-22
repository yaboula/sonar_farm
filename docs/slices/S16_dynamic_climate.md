# S16 — Clima dinámico + 4 estaciones

> **Status:** ACTIVE
> **Phase:** Phase 2 — Depth & Scale
> **Complexity:** XL
> **Roadmap reference:** [docs/01_ROADMAP.md#s16](../01_ROADMAP.md)
> **Started:** 2026-05-22
> **Closed:** TBD
> **Author:** PM Agent + Backend Agent + Integration Agent

---

## 1. Scope

Sistema climático server-authoritative que cierra el Pilar 3 (Time & Nature) y activa matemáticamente el `weather_match`.
Introduce las 4 estaciones (que rotan más rápido que en la vida real según el Bible §13.1) y un motor de eventos meteorológicos (lluvia, sequía, granizo, etc.).
El servidor es el dueño de la verdad climatológica. Los clientes sincronizan los visuales del clima de FiveM con el estado del servidor. Además, los eventos climáticos impactan periódicamente en el estado de las parcelas (ej. lluvia suma agua y sube irrigation_score; sequía la baja).

## 2. Goal (Wooow Test outcome)

Un jugador está en su granja, de repente empieza a llover (sincronizado para todos). Revisa el `ox_target` de su parcela y ve que la humedad (`irrigation_score`) ha subido automáticamente sin tener que usar la regadera, ahorrándole trabajo. Semanas (in-game) después, cae granizo y destruye parte de la calidad de sus cultivos desprotegidos (pero el invernadero se salva).

## 3. Dependencies

| Slice | Reason                                        | Status |
| ----- | --------------------------------------------- | ------ |
| S8    | Base de calidad con los 7 factores preparados | DONE   |
| S11   | Tick del scheduler y reconciliación           | DONE   |
| S17   | Invernaderos como exención de clima           | DONE   |

## 4. Deliverables

- [ ] `012_climate.sql` para guardar la estación actual y evento activo (si queremos persistirlo entre reinicios).
- [ ] `config/climate.lua` con duraciones de estación, probabilidades de eventos, y toggle visual (`Config.Farm.Climate.EnableWeatherSync`).
- [ ] `server/climate/climate_service.lua` (scheduler de estaciones y eventos).
- [ ] Lógica para que el clima afecte parcelas (ej. lluvia sube `irrigation_score`, granizo baja `quality`).
- [ ] Conexión del factor `weather` en `server/quality/factors/weather.lua` según la estación y el cultivo (óptimo vs actual).
- [ ] `client/climate/weather_sync.lua` para forzar los nativos de clima de FiveM (solo si `EnableWeatherSync` está activo).
- [ ] Eventos: `sonar:farm:climate:season_changed`, `sonar:farm:climate:event_started`.

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

- [ ] Las estaciones avanzan automáticamente según los ticks del servidor.
- [ ] Los eventos meteorológicos (lluvia, etc.) tienen impacto real matemático en los scores de las parcelas (excepto invernaderos).
- [ ] El `weather_match` factor evalúa si el crop actual le gusta la estación/clima actual.
- [ ] Conflicto mitigado: toggle en config permite apagar el sync visual por si el server ya usa `vSync` o `cd_easytime`, pero la matemática sigue funcionando.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                          | Prompt block in `.prompts.md` |
| ----------------- | ------------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Base de datos, State machine de estaciones, FSM de clima y mutaciones de score en parcelas. | yes                           |
| Integration Agent | Sincronización visual del clima en el cliente FiveM y HUD local.                            | yes                           |

## 8. Architecture notes

_(To be filled during execution)_

## 9. ADRs created

_(To be filled during execution)_

## 10. Smoke test (happy path)

_(To be filled during execution)_

## 11. Closing summary (filled at /end-slice)

_(To be filled at the end)_
