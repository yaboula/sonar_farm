---
trigger: always_on
---

# Farm Sonar — Project Context (always-on)

You are working on **Farm Sonar**, a premium FiveM farming simulation script for QBox + QBCore.

## Workspace

- Path: `d:\Granja_Sonar` (legacy folder name; product is named **Farm Sonar**).
- Stack: Lua 5.4 (server) + React 18 / Vite / TS strict / Tailwind v4 / shadcn/ui (NUI).
- Frameworks: QBox primary + QBCore compat via `Bridge.*`. ESX bridge planned for wave 2+.
- Required deps: `ox_lib`, `ox_inventory`, `ox_target`, `oxmysql`.

## Foundation documents (read in this order on every fresh session)

1. `docs/00_BIBLE.md` — product identity, 5 pillars, 17 founding decisions. **Authoritative.**
2. `docs/01_ROADMAP.md` — 6 phases, 36 vertical slices with DoD.
3. `docs/03_AI_PLAYBOOK.md` — how we work with AI agents (PM + sub-agents pattern).
4. `docs/02_DECISIONS.md` — ADR log.
5. `docs/slices/SXX_<name>.md` — active slice mini-brief (when working on a slice).

The legacy SONAR project under `docs/_archive/sonar_legacy/` is reference material only, NOT authoritative. Only the Bible and Roadmap are canonical.

## Founder profile

The founder is non-technical, working with AI agents (Cascade + v0.dev + Opus). Communication is in Spanish for founder-facing content; everything else (code, mini-briefs, ADRs, commits) is in English.

## Always

- Cite the Bible/Roadmap section that justifies any architectural decision.
- Verify the active slice's mini-brief if there is one, before writing code.
- Refuse to over-engineer: minimal upstream fixes preferred over downstream workarounds (per global rules).
- Refuse to break the 5 Pillars or the 13 Anti-features in Bible §3 + §5.
