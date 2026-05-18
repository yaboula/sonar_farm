# Farm Sonar

> Premium farming simulation script para FiveM — QBox + QBCore.
> Parte de la familia de productos **Sonar**.

[![Status](https://img.shields.io/badge/status-foundation%20phase-CCFF00)]()
[![Stack](https://img.shields.io/badge/stack-Lua%205.4%20%2B%20React%2018-0A0E0A)]()
[![License](https://img.shields.io/badge/license-proprietary-555555)]()

---

## Visión

Farm Sonar es un nodo agrícola completo y vendible para servidores de roleplay FiveM, construido con la filosofía **"trabajo físico en campo, gestión digital premium"**:

- **8 cultivos** end-to-end (trigo, maíz, cebada, tomate, pimiento, lechuga, cebolla, patata).
- **MLO completo** ajustado: 4 campos extensivos + 3 parcelas hortícolas + 1 invernadero industrial.
- **Flota completa** (~12 vehículos especializados).
- **Sistema de empresa** con 4 roles + 5 toggles macro.
- **Calidad propagada S/A/B/C/D** + **lineage por `batch_id`** (preparado para verticales futuras Mill Sonar / Bakery Sonar).
- **Mundo vivo**: 6-10 NPCs compradores con personalidad, random walk de precios, contratos B2B, reputación.
- **Tecnología wooow**: drones de monitorización + drones autónomos de fumigación + soil analyzer físico + market intelligence dashboard.

---

## Stack técnico

| Capa | Tecnología |
|---|---|
| **Server** | Lua 5.4 sobre FiveM, QBox primary + QBCore compat (ESX bridge wave 2+) |
| **Database** | MySQL/MariaDB vía `oxmysql` |
| **Inventory / Targeting / UI Lua** | `ox_inventory` + `ox_target` + `ox_lib` |
| **NUI** | React 18 + Vite + TypeScript strict + Tailwind v4 + shadcn/ui + Framer Motion 11 + Lucide + Recharts |
| **Estado NUI** | React Context + useReducer (sin Zustand/Redux) |

---

## Identidad visual

- **Estilo**: SaaS Agritech moderno · Bento Grid · glassmorphism.
- **Inspiración**: Linear · Vercel · Arc · Climate FieldView.
- **Paleta**: bg menta `#EEF4EB` · nav carbón `#0A0E0A` · acento lima neón `#CCFF00` · cards `rgba(255,255,255,0.7)`.
- **Tipografía**: Geist Sans (UI) + JetBrains Mono (datos / IDs).

---

## Estructura del repositorio

```
.
├── .windsurf/             Cascade AI rules + workflows operacionales
│   ├── rules/             5 reglas always_on (context, naming, languages, DoD, anti-patterns)
│   └── workflows/         6 slash commands (/start-slice, /spawn-pm, /end-slice, /spike, /research, /ui-design)
└── docs/                  Toda la documentación canónica del producto
    ├── 00_BIBLE.md        Producto canon — 17 decisiones fundacionales
    ├── 01_ROADMAP.md      6 fases · 36 vertical slices con DoD
    ├── 02_DECISIONS.md    ADR log
    ├── 03_AI_PLAYBOOK.md  Sistema operativo AI (PM Agent + 4 sub-agents)
    └── slices/            Mini-briefs por slice (just-in-time)
```

> Cuando empiece la implementación, se añadirán: `sonar_farm_core/` (Lua server-side) y `sonar_farm_tablet/` (NUI React).

---

## Cómo trabajamos

Farm Sonar se desarrolla con un sistema operativo AI canónico:

- **Cascade** como agente principal en el IDE (con rules `always_on` y workflows slash).
- **PM Agent + 4 sub-agents** (Backend / Frontend / Integration / QA) para slices grandes.
- **v0.dev** para mockups de UI.
- **Claude Opus** (sesión separada) para implementación profunda en slices XL.
- **Sesiones frescas por slice** — no se arrastra contexto rancio.

Detalle completo: [`docs/03_AI_PLAYBOOK.md`](./docs/03_AI_PLAYBOOK.md).

---

## Roadmap resumido

| Fase | Slices | Descripción |
|---|---|---|
| **0 — Foundation** | S0-S4 | Workspace, bridges, DB, Banca core, NUI shell |
| **1 — First Crop End-to-End** | S5-S11 | Trigo plantable + lifecycle + venta. Milestone "clip 15s". |
| **2 — Depth & Scale** | S12-S18 | Cereales restantes, riego, fertilización, plagas, clima, hortícolas, maquinaria |
| **3 — Economy Alive** | S19-S22 | Catálogo NPCs, random walk, contratos B2B, reputación |
| **4 — Empresa multi-rol** | S23-S27 | Empresa core + roles + salarios + Manager Panel + Tablet de campo |
| **5 — WOOOW Tech Stack** | S28-S31 | Drones, soil analyzer, market intelligence dashboard |
| **6 — Polish & Launch** | S32-S35 | i18n, tests, beta cerrada, Tebex packaging |

Detalle completo: [`docs/01_ROADMAP.md`](./docs/01_ROADMAP.md).

---

## Convenciones (resumen)

- **Tablas DB**: `sonar_farm_*` (snake_case).
- **Eventos FiveM**: `sonar:farm:<domain>:<action>`.
- **Recursos**: `sonar_farm_core` + `sonar_farm_tablet`.
- **Items `ox_inventory`**: `sonar_seed_*` / `sonar_batch_*` / `sonar_<tool>` / `sonar_fertilizer_*` / `sonar_pesticide_*`.
- **Idioma**: código en inglés · docs founder-facing en español · UI strings vía i18n (`locales/{es,en}.lua`).

Detalle: [`.windsurf/rules/02_naming_conventions.md`](./.windsurf/rules/02_naming_conventions.md) + [`03_languages.md`](./.windsurf/rules/03_languages.md).

---

## Licencia

Propietaria — todos los derechos reservados. Distribución comercial vía Tebex con Asset Escrow (a partir de Fase 6).

---

## Estado

**Foundation phase** · v0.0.1-pre — documentación canónica firmada, sistema operativo AI activo, listo para arrancar Slice 0.
