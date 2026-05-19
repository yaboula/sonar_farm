# S1 — Bridge layer (QBox + QBCore)

> **Status:** DONE
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** M (3-7 días)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S1](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** 2026-05-19
> **Author:** Cascade (single-agent session, no `/spawn-pm` because complexity = M)

---

## 1. Scope

Capa **`shared/bridge/`** que abstrae las diferencias entre QBox y QBCore detrás de una interfaz uniforme. Cualquier slice posterior consume `Bridge.<Method>(...)` sin tener que conocer el framework activo. Detección automática del framework en boot via dependency presence + export availability.

Es el **slice 🔓 unlock más importante de Fase 0**: sin él, cada slice que toque dinero, jugador o trabajo tendría que duplicar código framework-specific. Con él, los slices viven sobre una API estable y testeable.

**Alcance explícito** (lo que SÍ entra):

- Detección de framework activo.
- Acceso a `Player` (citizenid, charinfo, money, job).
- Mutación de dinero (`AddMoney`, `RemoveMoney`, `GetMoney`).
- Notificaciones server→client (`Notify`).
- Registro de usable items queda diferido per ADR-005 (YAGNI; futuros slices lo añaden si lo necesitan).
- Comando admin de prueba `/sonarfarm:bridgetest`.
- Documentación exhaustiva de la interfaz en `INTERFACE.md`.

**Fuera de scope** (delegado a slice futuro o resource externo):

- Inventario → se usa `ox_inventory` directamente, NO va por el bridge.
- Targeting → `ox_target` directamente.
- UI → `ox_lib` directamente.
- ESX bridge → diferido a wave 2+ (Bible §11.4). Cuando un servidor sin QBox/QBCore arranca el resource, log claro y resource permanece inerte.

## 2. Goal (Wooow Test outcome)

**Developer-visible** (S1 es Foundation, sin valor jugable):

> Un dev puede ejecutar `/sonarfarm:bridgetest` en consola admin y recibir un resumen completo del jugador (citizen id, nombre completo, job, dinero cash/bank). El mismo comando funciona idéntico en un server QBox y en uno QBCore. El log de boot indica claramente qué framework fue detectado: `[sonar_farm_core] Bridge initialized → framework: qbox`.

## 3. Dependencies

| Slice | Reason                                                                            | Status  |
| ----- | --------------------------------------------------------------------------------- | ------- |
| S0    | Workspace skeleton + `sonar_farm_core` resource skeleton donde se monta el bridge | DONE ✅ |

## 4. Deliverables

### Lua

- [x] `sonar_farm_core/shared/bridge/init.lua` — autodetect + adapter binding.
- [x] `sonar_farm_core/shared/bridge/qbox.lua` — adapter para QBox.
- [x] `sonar_farm_core/shared/bridge/qbcore.lua` — adapter para QBCore.
- [x] `sonar_farm_core/shared/bridge/INTERFACE.md` — documentación exhaustiva pública.
- [x] `sonar_farm_core/shared/bridge/_unsupported.lua` — adapter de fallback que loggea el mensaje solo cuando se selecciona y deja el bridge inerte.

### Server

- [x] `sonar_farm_core/server/admin/bridge_test_command.lua` — comando `/sonarfarm:bridgetest`.

### Locales

- [x] `boot.bridge_initialized` (en + es).
- [x] `boot.framework_unsupported` (en + es).
- [x] `bridge.test.<...>` (en + es) para output del comando.
- [x] `ui.brand_name` (en + es) para título de notificaciones.

### Manifest

- [x] `sonar_farm_core/fxmanifest.lua` — añadir los nuevos archivos a `shared_scripts` y `server_scripts` con orden correcto (bridge antes de cualquier consumer) + `ox_lib 'locale'`.

### Tests

> **Decisión informada**: tests automatizados Lua se difieren a un spike de "Lua testing infrastructure" antes de S3 (Banca, complejidad L) donde sí son obligatorios. Razón: el bridge es 100% delegación a APIs externas (QBox/QBCore); el valor real de mockearlas es bajo comparado con un smoke test ejecutado en server real. El comando `/sonarfarm:bridgetest` ES el integration test ejecutable. Documentado en §11 deviations + backlog spike "lua-testing-infra".

- [x] Smoke test ejecutable: `/sonarfarm:bridgetest` documentado en §10. Reemplaza unit tests para esta capa de delegación pura.

## 5. Universal DoD checklist

(de `.windsurf/rules/04_dod_universal.md`)

- [x] Funciona en QBox (smoke §10; validado por founder durante S1).
- [x] Funciona en QBCore (smoke §10; validado por founder durante S1).
- [x] Smoke test del happy path documentado en §10.
- [x] Tests automatizados: N/A para esta capa de delegación pura; reemplazado por smoke executable `/sonarfarm:bridgetest` per §4 Tests.
- [x] Cero strings hardcoded user-facing (locales `boot.*`, `bridge.*`, `ui.brand_name` completos en en + es).
- [x] Cero magic numbers (chat brand color centralizado en `Config.Farm.Chat.BrandColor`; bridge sin tunables económicos).
- [x] Respeta 5 Pilares Bible §3 (no viola ninguno; refuerza Server-Authoritative).
- [x] Respeta anti-patrones §9.4 (server-authoritative, sin tight coupling fuera del bridge).
- [x] Respeta naming conventions: `Sonar.Farm.Bridge.PascalCase(args)`, archivos `snake_case.lua`.
- [x] DB migration: N/A (bridge no toca DB).
- [x] Mini-brief actualizado con lo construido.
- [x] ADR creado: ADR-005.
- [x] Bible §18 changelog: N/A (bridge no cambia producto canon).

## 6. Slice-specific DoD

(del Roadmap S1)

- [x] `/sonarfarm:bridgetest` devuelve datos correctamente en QBox.
- [x] Mismo comando funciona idéntico en QBCore.
- [x] Si detecta framework no soportado, log claro: _"Farm Sonar requires QBox or QBCore. ESX bridge planned for wave 2+."_ y el resource entra en estado `INERT` (no crashea).

## 7. Sub-agents involved

| Agent               | Role in this slice                                 | Prompt block in `.prompts.md` |
| ------------------- | -------------------------------------------------- | ----------------------------- |
| Cascade (PM + impl) | Single-agent session: diseño + impl + tests + docs | no — complexity M             |

`/spawn-pm` **NOT used** — complexity M, single Cascade session per AI Playbook §16.2.

## 8. Architecture notes

Settled during implementation (all 4 design questions answered by founder before any code was written; see ADR-005):

- **Namespace**: `Sonar.Farm.Bridge.*` (anidado, no global plano). Coherente con `Sonar.Farm.Version`. La rule `02_naming_conventions.md` se actualizó en consecuencia, y la rule `05_anti_patterns.md` también (anti-pattern §7 "tight coupling to QBox-only or QBCore-only APIs" ahora referencia `Sonar.Farm.Bridge.GetMoney(src, 'bank')`).
- **Detection**: híbrida. `init.lua` lee primero `GetConvar('sonar:framework', 'auto')`. Si `auto`, autodetecta por `GetResourceState('qbx_core')` y `GetResourceState('qb-core')`. Si nada matchea, carga `_unsupported.lua` que loggea el error canónico y desactiva métodos.
- **Player POJO**: tabla congelada de 9 campos `{ src, citizen_id, name, job_name, job_grade, cash, bank, framework }`. Las mutaciones SIEMPRE pasan por funciones globales `Sonar.Farm.Bridge.AddMoney/RemoveMoney/Notify`. Stateless = testeable + server-authoritative refuerzo.
- **Coverage**: 5 métodos imprescindibles (YAGNI). Slices futuros añaden lo que necesiten via PR + mini-ADR.
- **Adapter loading pattern**: cada adapter (`qbox.lua`, `qbcore.lua`, `_unsupported.lua`) registra una tabla local en `Sonar.Farm.Bridge.__<name>_adapter` durante su carga `shared_script`. `init.lua` selecciona uno y bindea sus métodos al namespace público. Esto permite: (a) los 3 adapters cargan SIEMPRE pero solo uno se usa, (b) `init.lua` no necesita `require()` (que FiveM Lua no soporta out-of-the-box), (c) testing manual posible inyectando `Sonar.Farm.Bridge.__qbox_adapter = <mock>` antes de cargar `init.lua`.
- **Locale initialization**: `fxmanifest.lua` usa el metadata directive `ox_lib 'locale'`, que inicializa el módulo de locale de ox_lib y expone `locale(...)` de forma canónica. Los fallbacks hardcoded fueron eliminados para que un fallo de locale sea visible durante boot.
- **Argument order para mutaciones de dinero**: `(src, account, amount, reason)` invariante. Documentado en INTERFACE.md §3 + en la rule `02_naming_conventions.md`. `reason` es OBLIGATORIO (no opcional) para preparar el audit trail de S3 Banca.
- **Server-authoritative en RemoveMoney**: el bridge NUNCA delega ciegamente a `Player.Functions.RemoveMoney` que en QBox/QBCore puede fallar silenciosamente con saldo insuficiente. Verifica `GetMoney(src, account) >= amount` ANTES de delegar.
- **`is_server()` guard en cada método**: `IsDuplicityVersion()` early-return en cada método público para que llamadas client-side no hagan crash al intentar usar `exports.qbx_core:GetPlayer()` que no existe en client.
- **ACE permission `sonar.farm.admin`**: el comando `/sonarfarm:bridgetest` requiere ACE. Server admin debe añadir `add_ace group.admin sonar.farm.admin allow` a `server.cfg`. Documentado en el header del comando + en smoke test §10.
- **Version bump 0.0.1 → 0.1.0**: S1 introduce la primera capa pública consumible, justifica un minor bump pre-1.0 (semver). Tres archivos updated atómicamente: `version.lua`, `version.ts`, ambos `fxmanifest.lua`.

## 9. ADRs created

- **ADR-005** — Diseño del Bridge layer (namespace + detección + Player shape + cobertura). Las 4 sub-decisiones están consolidadas en un único ADR porque son interdependientes y se firmaron en bloque. Ver `docs/02_DECISIONS.md`.

## 10. Smoke test (happy path)

### A) QBox

1. Server FiveM con QBox + ox_lib + ox_inventory + ox_target + oxmysql ya iniciados.
2. `ensure sonar_farm_core` en `server.cfg`.
3. Boot: ver en consola → `[sonar_farm_core] Farm Sonar core booted (v0.1.0)` + `[sonar_farm_core] Bridge initialized → framework: qbox`.
4. Como admin, ejecutar `/sonarfarm:bridgetest` con un jugador conectado.
5. Output esperado en consola del jugador: tabla con `citizen_id`, `name`, `job_name`, `job_grade`, `cash`, `bank`.

### B) QBCore

6. Cambiar a server QBCore. Repetir 2-5.
7. Output esperado: idéntico al anterior.

### C) Framework no soportado

8. Server con ESX activo (sin QBox/QBCore).
9. Boot: ver en consola → `[sonar_farm_core][ERROR] Farm Sonar requires QBox or QBCore. ESX bridge planned for wave 2+.`
10. Resource sigue cargado pero todos sus comandos quedan inertes (no crashean, devuelven mensaje "bridge not initialized").

## 11. Closing summary (filled at /end-slice)

### What shipped

- `Sonar.Farm.Bridge` namespace with QBox, QBCore and unsupported adapters.
- 5-method baseline per ADR-005: `GetPlayer`, `GetMoney`, `AddMoney`, `RemoveMoney`, `Notify`.
- Framework detection via `sonar:framework` convar override + QBox/QBCore autodetect.
- `/sonarfarm:bridgetest` admin smoke command with localized output.
- `INTERFACE.md` as the public bridge contract.
- Version bump to `0.1.0`.
- Follow-up fixes before close: canonical `ox_lib 'locale'` initialization, unsupported adapter logs only when selected, NUI splash defaults invisible in-game.

### Deviations from plan

- `RegisterUsableItem` was removed from S1 baseline by ADR-005 Decision 4. It is explicitly deferred until a future slice needs it.
- Automated unit tests were deferred because this bridge is delegation over live QBox/QBCore APIs; `/sonarfarm:bridgetest` is the S1 integration smoke.
- The NUI splash invisibility fix landed during S1 as a small foundation correction even though UI shell work remains S4.

### Discoveries / lessons

- `ox_lib 'locale'` is the correct fxmanifest metadata directive for loading the locale module; manual `lib.locale()` wiring was unnecessary and error-prone.
- Unsupported adapters must not log at top-level because all adapters load before `init.lua` selects one.
- Bridge methods should stay minimal; every future method must be justified by a slice and added to both QBox and QBCore adapters.

### Pointers for next slices

- S2 can use the bridge only for player context if needed; DB/migrations remain independent.
- S3 Banca can build money audit semantics on top of the existing `AddMoney`/`RemoveMoney` reason invariant.
- S4 should keep the NUI invisible by default in-game and only open through explicit Lua messages.
