# S4 — NUI shell + design system

> **Status:** ACTIVE
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** L (7-14 days)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S4](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** —
> **Author:** PM Agent (Cascade) + Frontend / Integration / QA sub-agents

---

## 1. Scope

S4 ships the first real Farm Sonar NUI shell for both signed surfaces from Bible §15: the fixed office Laptop (`manager` mode) and the field Tablet (`field` mode). This replaces the inert S0 splash with an app shell, route placeholders and a minimal but real NUI open/close lifecycle.

The slice must follow Bible §1.1, Bible §15, `docs/04_UI_PLAYBOOK.md` and ADR-006. The visual contract is AgriSphere-inspired Light Mode / Calm-Tech / iPad-like, flat minimalista surfaces, Bento-first layout, Geist Sans + JetBrains Mono, and `#B6FB63` as the only saturated accent.

S4 is foundation UI, not gameplay. It must not invent plot/batch/company backend data. It may use fake/demo data only inside clearly isolated UI fixtures/placeholders so later slices can replace them with real NUI messages.

S4 also establishes typed NUI message contracts and a minimal React i18n path. Since user-facing strings become visible in this slice, hardcoded final strings in JSX are not acceptable at close.

## 2. Goal (Wooow Test outcome)

A player can open the office Laptop via `ox_target` and see a polished manager shell with a dashboard placeholder, and can open the field Tablet with a configurable keybind and see a field shell. ESC closes the NUI and returns control to the game.

## 3. Dependencies

| Slice          | Reason                                                                    | Status  |
| -------------- | ------------------------------------------------------------------------- | ------- |
| S0             | Workspace skeleton, NUI resource, Vite/Tailwind baseline, inert S0 splash | DONE ✅ |
| UI Playbook v1 | Canonical visual tokens, Bento rules and allowed components               | DONE ✅ |

If S0 regresses from `DONE`, do not implement S4 — escalate to founder.

## 4. Deliverables

### React / NUI shell

- [ ] `sonar_farm_tablet/web/src/main.tsx` — still mounts the React app cleanly.
- [ ] `sonar_farm_tablet/web/src/App.tsx` — replace S0 splash with NUI shell lifecycle and app mode rendering.
- [ ] `sonar_farm_tablet/web/src/router/AppRouter.tsx` — routes/placeholders: `/dashboard`, `/plots`, `/batches`, `/market`, `/contracts`, `/personnel`, `/finance`, `/log`, `/tasks`, `/messages`.
- [ ] `sonar_farm_tablet/web/src/types/nui.ts` — typed NUI inbound/outbound message contracts.
- [ ] `sonar_farm_tablet/web/src/hooks/useNuiMessages.ts` — receive `sonar:farm:nui:open` / `sonar:farm:nui:close` style messages.
- [ ] `sonar_farm_tablet/web/src/i18n/*` or equivalent lightweight i18n module — `t('key.path')` available to components.
- [ ] `sonar_farm_tablet/web/src/locales/en.json` and `sonar_farm_tablet/web/src/locales/es.json` — shell and placeholder strings.

### Design system components

- [ ] `sonar_farm_tablet/web/src/components/layout/BentoGrid.tsx` — `BentoGrid` + `BentoGrid.Item` API signed in this slice.
- [ ] `sonar_farm_tablet/web/src/components/ui/Card.tsx` or equivalent local primitive — flat minimalista card style per ADR-006.
- [ ] `sonar_farm_tablet/web/src/components/ui/BatchChip.tsx` — future-ready batch chip using mono typography.
- [ ] `sonar_farm_tablet/web/src/components/ui/LimePulse.tsx` — calm lime pulse, respects reduced motion.
- [ ] `sonar_farm_tablet/web/src/components/typography/Heading.tsx`.
- [ ] `sonar_farm_tablet/web/src/components/typography/Body.tsx`.
- [ ] `sonar_farm_tablet/web/src/components/typography/Mono.tsx`.
- [ ] `sonar_farm_tablet/web/src/styles/theme.css` — verify tokens still match Bible §1.1 and UI Playbook v1; add only justified shell tokens.

### Client / FiveM integration

- [ ] `sonar_farm_tablet/client/main.lua` — NUI lifecycle coordinator or imports new client modules.
- [ ] `sonar_farm_tablet/client/laptop_interaction.lua` — office laptop `ox_target` entrypoint opens NUI mode `manager`.
- [ ] `sonar_farm_tablet/client/tablet_interaction.lua` — configurable keybind opens NUI mode `field`.
- [ ] `sonar_farm_tablet/config.lua` — interaction/keybind settings if needed; no magic values in client code.
- [ ] `sonar_farm_tablet/fxmanifest.lua` — load new client/config files and include NUI build files correctly.
- [ ] NUI close callback or message bridge — ESC closes UI, calls Lua, clears focus.

### Demo / placeholders

- [ ] `/dashboard` includes one premium demo card with fake data and visible but restrained `#B6FB63` accent.
- [ ] `manager` mode shows manager-appropriate nav placeholders.
- [ ] `field` mode shows field/tablet-appropriate nav placeholders.
- [ ] Empty/loading/error placeholder states exist for the shell level.

### Tests / verification

- [ ] `pnpm lint` passes.
- [ ] `pnpm build` passes.
- [ ] Manual browser smoke via Vite dev mode.
- [ ] QBox in-game smoke for laptop/tablet open/close.
- [ ] QBCore in-game smoke before close, or explicit blocker/ADR if unavailable.

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests where they make sense.
- [ ] No hardcoded user-facing strings — React strings via `t('key.path')`, locales EN/ES complete.
- [ ] No hardcoded magic numbers — config/CSS tokens used.
- [ ] Respects the 5 Pillars of Bible §3.
- [ ] Respects Bible §9.4 anti-patterns.
- [ ] Respects naming conventions (rule `02_naming_conventions.md`).
- [ ] DB migration versioned + rollbackable, if DB was touched.
- [ ] Mini-brief updated with what was actually built.
- [ ] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [ ] Bible §18 changelog updated if product canon changed.

## 6. Slice-specific DoD

- [ ] Open Laptop with `ox_target` → NUI fullscreen/manager mode → dashboard placeholder uses Farm Sonar visual identity.
- [ ] Open Tablet with configurable keybind → NUI field mode → field placeholder uses Farm Sonar visual identity.
- [ ] ESC closes NUI, clears focus and returns player control.
- [ ] Shell uses signed palette and flat minimalista cards per ADR-006; no glassmorphism, no dark default, no heavy shadows.
- [ ] `BentoGrid`, `BatchChip` and `LimePulse` have stable typed APIs documented in §8.
- [ ] NUI messages are typed in TypeScript and documented in §8.
- [ ] React shell has a minimal i18n mechanism and no final hardcoded user-facing strings.
- [ ] No direct client trust for gameplay state; S4 renders placeholders only.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                     | Prompt block in `.prompts.md` |
| ----------------- | -------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Not needed; S4 should not create server gameplay state or DB                           | no                            |
| Frontend Agent    | Owns React shell, design system components, routing, i18n and visual fidelity          | yes                           |
| Integration Agent | Owns FiveM client entrypoints, NUI focus/close lifecycle, config and fxmanifest wiring | yes                           |
| QA Agent          | Owns browser/in-game smoke, lint/build verification and DoD audit                      | yes                           |

Prompts file: `docs/slices/S4_nui_shell_design_system.prompts.md`.

## 8. Architecture notes

Initial PM guidance before implementation:

- Authoritative visual sources: Bible §1.1, Bible §15, UI Playbook v1, ADR-006.
- S4 should not add gameplay backend, DB migrations or real plot/batch/company state.
- Frontend and Integration must agree on the NUI message contract before coding deeply.
- Suggested inbound NUI messages:
  - `{ action: 'sonar:farm:nui:open', payload: { mode: 'manager' | 'field', route?: string } }`
  - `{ action: 'sonar:farm:nui:close' }`
- Suggested NUI callback from React to Lua:
  - `sonar_farm_tablet:close` or equivalent fetch callback, then Lua calls `SetNuiFocus(false, false)`.
- Keep existing S0 safety invariant: NUI must render nothing in-game until explicitly opened.
- Browser dev mode may default visible for designer productivity, but in FiveM the UI must stay hidden until Lua opens it.
- If shadcn/ui is not physically installed yet, implement local minimal primitives with shadcn-compatible styling. Do not add a large component catalog in S4.
- Do not install Framer Motion by default. Use CSS transitions/pulse only unless the founder explicitly approves motion scope.

Contracts to fill during implementation:

- `BentoGrid` props.
- `BatchChip` props.
- `LimePulse` props and reduced-motion behavior.
- NUI message interfaces.
- Locale key namespaces.
- Config keys for keybind and laptop target coordinates/model.

## 9. ADRs created

- None yet. ADR-006 already covers flat minimalista surfaces.

## 10. Smoke test (happy path)

### Browser / Vite smoke

1. From repo root, run `pnpm lint`.
2. Run `pnpm --filter @sonar/farm-tablet-web build`.
3. Run the Vite dev server for `sonar_farm_tablet/web`.
4. Open the browser preview.
5. Verify the shell uses `#D9EAE3` background, `#FFFFFF` cards, `#050505` nav, `#B6FB63` accent, Geist/JetBrains typography.
6. Verify route placeholders are navigable for manager apps and field apps.
7. Verify browser dev mode does not rely on FiveM-only globals.

### QBox in-game smoke

1. Build the NUI bundle.
2. Start a QBox dev server with `ox_lib`, `ox_target`, `sonar_farm_core`, `sonar_farm_tablet`.
3. Confirm the UI is hidden on join.
4. Use `ox_target` on the configured laptop target.
5. Verify manager mode opens, NUI has focus, dashboard placeholder is visible.
6. Press ESC.
7. Verify NUI closes, focus is released, player movement/camera returns.
8. Press configured tablet keybind.
9. Verify field mode opens and shows tablet/field placeholder.
10. Press ESC again and verify focus release.

### QBCore in-game smoke

Repeat the same procedure on QBCore before S4 closure. If no QBCore environment exists, this must be documented explicitly and handled with `/end-slice` rules.

## 11. Closing summary (filled at /end-slice)

### What shipped

- TBD

### Deviations from plan

- TBD

### Discoveries / lessons

- TBD

### Unblocks

- S5 — Plot registry / persistent plots can render into the shell later.
- S10 — NPC vendor sale UI/payment confirmation can use the shell conventions.
- S26/S27 — Manager Panel and Tablet apps build on this shell/design system.

### Commit message

```text
feat(nui): S4 — NUI shell and design system

- add Farm Sonar manager/tablet NUI shell
- add Bento design system primitives and typed NUI messages
- wire laptop/tablet entrypoints and close lifecycle
- document smoke coverage for QBox and QBCore

Closes S4.
```
