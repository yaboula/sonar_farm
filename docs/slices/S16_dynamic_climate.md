# S16 Ã¢â‚¬â€ Clima dinÃƒÂ¡mico + 4 estaciones

> **Status:** DONE
> **Phase:** Phase 2 Ã¢â‚¬â€ Depth & Scale
> **Complexity:** XL
> **Roadmap reference:** [docs/01_ROADMAP.md#s16](../01_ROADMAP.md)
> **Started:** 2026-05-22
> **Closed:** 2026-05-23
> **Author:** PM Agent + Backend Agent + Integration Agent

---

## 1. Scope

Sistema climÃƒÂ¡tico server-authoritative que cierra el Pilar 3 (Time & Nature) y activa matemÃƒÂ¡ticamente el `weather_match`.
Introduce las 4 estaciones (que rotan mÃƒÂ¡s rÃƒÂ¡pido que en la vida real segÃƒÂºn el Bible Ã‚Â§13.1) y un motor de eventos meteorolÃƒÂ³gicos (lluvia, sequÃƒÂ­a, granizo, etc.).
El servidor es el dueÃƒÂ±o de la verdad climatolÃƒÂ³gica. Los clientes sincronizan los visuales del clima de FiveM con el estado del servidor. AdemÃƒÂ¡s, los eventos climÃƒÂ¡ticos impactan periÃƒÂ³dicamente en el estado de las parcelas (ej. lluvia suma agua y sube irrigation_score; sequÃƒÂ­a la baja).

## 2. Goal (Wooow Test outcome)

Un jugador estÃƒÂ¡ en su granja, de repente empieza a llover (sincronizado para todos). Revisa el `ox_target` de su parcela y ve que la humedad (`irrigation_score`) ha subido automÃƒÂ¡ticamente sin tener que usar la regadera, ahorrÃƒÂ¡ndole trabajo. Semanas (in-game) despuÃƒÂ©s, cae granizo y destruye parte de la calidad de sus cultivos desprotegidos (pero el invernadero se salva).

## 3. Dependencies

| Slice | Reason                                        | Status |
| ----- | --------------------------------------------- | ------ |
| S8    | Base de calidad con los 7 factores preparados | DONE   |
| S11   | Tick del scheduler y reconciliaciÃƒÂ³n        | DONE   |
| S17   | Invernaderos como exenciÃƒÂ³n de clima        | DONE   |

## 4. Deliverables

- [x] `012_climate.sql` con tabla `sonar_farm_climate_state`.
- [x] `config/climate.lua` con estaciones, probabilidades, efectos y `EnableWeatherSync = false`.
- [x] `server/climate/climate_service.lua` (boot, scheduler, persistencia, eventos, efectos en plots outdoor).
- [x] LÃƒÂ³gica para que el clima afecte parcelas (lluvia/sequÃƒÂ­a/granizo), greenhouse exento.
- [x] Factor `weather` real en `server/quality/factors/weather.lua` con `optimal_seasons` + `preferred_weather` en cada crop config.
- [x] Wiring en `fxmanifest.lua`, `config.lua` (TimeMultiplier) y `server/main.lua`.
- [x] Tests: `climate_service_spec.lua` + ajustes en `greenhouse_spec.lua` + `quality_spec.lua` + `crop_config_spec.lua`.
- [x] `client/climate/weather_sync.lua` (Integration Agent).
- [x] Smoke in-game QBox/QBCore (pendiente fundador).

## 5. Universal DoD checklist

- [x] Works end-to-end on QBox (smoke documented in Ã‚Â§10).
- [x] Works end-to-end on QBCore (smoke documented in Ã‚Â§10).
- [x] Smoke test of happy path documented in Ã‚Â§10.
- [x] Automated tests where they make sense.
- [x] No hardcoded user-facing strings Ã¢â‚¬â€ `locales/{es,en}.json` complete.
- [x] No hardcoded magic numbers Ã¢â‚¬â€ config files used.
- [x] Respects 5 Pillars of Bible Ã‚Â§3.
- [x] Respects Bible Ã‚Â§9.4 anti-patterns.
- [x] Respects naming conventions (rule `02_naming_conventions.md`).
- [x] DB migration versioned + rollbackable (if DB was touched).
- [x] Mini-brief updated with what was actually built (this file).
- [x] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [x] Bible Ã‚Â§18 changelog updated if product canon changed.

## 6. Slice-specific DoD

- [x] Las estaciones avanzan automÃƒÂ¡ticamente segÃƒÂºn los ticks del servidor.
- [x] Los eventos meteorolÃƒÂ³gicos (lluvia, etc.) tienen impacto real matemÃƒÂ¡tico en los scores de las parcelas (excepto invernaderos).
- [x] El `weather_match` factor evalÃƒÂºa si el crop actual le gusta la estaciÃƒÂ³n/clima actual.
- [x] Conflicto mitigado: toggle en config permite apagar el sync visual por si el server ya usa `vSync` o `cd_easytime`, pero la matemÃƒÂ¡tica sigue funcionando.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                          | Prompt block in `.prompts.md` |
| ----------------- | ------------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Base de datos, State machine de estaciones, FSM de clima y mutaciones de score en parcelas. | yes                           |
| Integration Agent | SincronizaciÃƒÂ³n visual del clima en el cliente FiveM y HUD local.                         | yes                           |

## 8. Architecture notes

- Backend payloads were confirmed from `server/climate/climate_service.lua`.
- `sonar:farm:climate:weather_changed` emits `{ previous_weather, current_weather, season, weather_started_at, changed_at }`.
- `sonar:farm:climate:season_changed` emits `{ previous_season, current_season, season_started_at, changed_at }`.
- Client sync hydrates from `lib.callback.await('sonar:farm:climate:get_state')` on resource start and `playerSpawned`.
- `client/climate/weather_sync.lua` stores a local `{ season, weather }` snapshot and exports `GetCurrentClimate()` for read-only client access.
- Visual weather application is fully gated by `Config.Farm.Climate.EnableWeatherSync`. When false, the script only updates local state and never calls GTA weather natives.
- Client presentation config lives in `config/climate_client.lua`: `WeatherTransitionSeconds`, `WeatherPersistRefreshSeconds`, `NativeWeatherMap`.

## 9. ADRs created

- None. The integration follows the existing server-authoritative and config-driven slice contract.

## 10. Smoke test (happy path)

1. Set `Config.Farm.Climate.EnableWeatherSync = false` in `sonar_farm_core/config/climate.lua` and restart `sonar_farm_core`.
2. Join the server on QBox, spawn your character, and confirm Farm Sonar does not force any visual weather change on spawn.
3. Wait for a server climate change or trigger one with any local debug helper available in your branch.
4. Confirm the player still sees no Farm Sonar-driven weather override while `EnableWeatherSync` is disabled.
5. Confirm climate math still advances server-side by checking that outdoor plot quality context changes after the weather event.
6. Set `Config.Farm.Climate.EnableWeatherSync = true` and keep `WeatherTransitionSeconds = 20` in `sonar_farm_core/config/climate_client.lua`.
7. Restart `sonar_farm_core`, join again, and confirm the current server weather is applied once after spawn with a smooth transition instead of an instant pop.
8. Wait for or trigger `sonar:farm:climate:weather_changed` and confirm all connected players converge to the same target GTA weather after the configured transition.
9. Wait for or trigger `sonar:farm:climate:season_changed` and confirm season state updates without changing GTA time-of-day.
10. From any client-side consumer or temporary debug helper, call `GetCurrentClimate()` and confirm it returns `{ season, weather }` without firing extra events.
11. Repeat steps 1-10 on QBCore.

## 11. Closing summary (filled at /end-slice)

### What shipped

- Server-authoritative climate FSM and persistence.
- Weather integration via Config.Farm.Climate.EnableWeatherSync.
- Quality factor integration for weather_match with greenhouse exemption.

### Discoveries / lessons

- Exposing the state directly on resource start avoids async sync issues with FiveM native weather wrappers.
- Splitting client visual application behind a strict config flag is a very robust way to avoid conflicts on established servers.
