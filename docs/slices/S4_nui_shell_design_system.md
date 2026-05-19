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

### React / NUI shell (Frontend — Phase B, shipped 2026-05-19)

- [x] `sonar_farm_tablet/web/src/main.tsx` — mounts React app, loads `theme.css` + `globals.css`.
- [x] `sonar_farm_tablet/web/src/App.tsx` — replaces S0 splash with hidden-by-default NUI shell lifecycle, mode-aware (`manager` ↔ `field`).
- [x] `sonar_farm_tablet/web/src/router/AppRouter.tsx` — `MemoryRouter` (CEF has no URL bar) hosting `/dashboard`, `/plots`, `/batches`, `/market`, `/contracts`, `/personnel`, `/finance`, `/log`, `/tasks`, `/messages`.
- [x] `sonar_farm_tablet/web/src/router/routes.ts` — typed route catalog with per-mode visibility and Lucide icon mapping.
- [x] `sonar_farm_tablet/web/src/types/nui.ts` — typed NUI inbound/outbound message contracts + type guards.
- [x] `sonar_farm_tablet/web/src/hooks/useNuiMessages.ts` — typed `window.message` listener.
- [x] `sonar_farm_tablet/web/src/hooks/useNuiVisibility.ts` — visibility/mode/route state machine (`useReducer`).
- [x] `sonar_farm_tablet/web/src/hooks/useEscapeClose.ts` — global Escape→close binding gated by shell visibility.
- [x] `sonar_farm_tablet/web/src/lib/env.ts` — `isFiveM()`, `isDev()`, `getResourceName()`.
- [x] `sonar_farm_tablet/web/src/lib/nui.ts` — safe `fetchNui<TResponse, TPayload>(callback, data, fallback)`.
- [x] `sonar_farm_tablet/web/src/i18n/` — `I18nProvider`, `useI18n`, separate `context.ts` for HMR safety.
- [x] `sonar_farm_tablet/web/src/locales/en.json` + `es.json` — shell + nav + page + state + demo namespaces.

### Design system primitives (Frontend — Phase B)

- [x] `sonar_farm_tablet/web/src/styles/theme.css` — v2 tokens: status `-bg/-fg` pairs, spacing scale `fs-1..fs-16`, focus ring token, viewport/shell chrome tokens, typography scale.
- [x] `sonar_farm_tablet/web/src/styles/globals.css` — focus-visible canon, `prefers-reduced-motion`/`prefers-contrast` guards, motion keyframes (`fs-pulse`, `fs-fade-in`, `fs-slide-up`, `fs-skeleton`).
- [x] `sonar_farm_tablet/web/src/components/typography/{Heading,Body,Mono}.tsx` — Playbook v2 §4.2 scale.
- [x] `sonar_farm_tablet/web/src/components/ui/Card.tsx` — flat minimalista (ADR-006) with `Card.Header/Body/Footer`.
- [x] `sonar_farm_tablet/web/src/components/ui/Button.tsx` — 4 variants × 3 sizes, loading state, focus ring.
- [x] `sonar_farm_tablet/web/src/components/ui/Icon.tsx` — Lucide wrapper enforcing stroke 1.5 + canonical size scale.
- [x] `sonar_farm_tablet/web/src/components/ui/Skeleton.tsx` — `text/card/circle/rect` variants, reduced-motion safe.
- [x] `sonar_farm_tablet/web/src/components/ui/EmptyState.tsx` — Playbook v2 §11.2.
- [x] `sonar_farm_tablet/web/src/components/ui/ErrorState.tsx` — Playbook v2 §11.3.
- [x] `sonar_farm_tablet/web/src/components/ui/BatchChip.tsx` — quality dot + mono ID + freshness tag, truncates IDs > 12 chars.
- [x] `sonar_farm_tablet/web/src/components/ui/LimePulse.tsx` — calm lime, CSS-only, respects reduced motion.
- [x] `sonar_farm_tablet/web/src/components/layout/BentoGrid.tsx` — `BentoGrid` + `BentoGrid.Item` (gap sm/md/lg, columns 8|12, span number).

### Shell layouts (Frontend — Phase B)

- [x] `sonar_farm_tablet/web/src/shell/ShellTopBar.tsx` — 64px (manager) / 56px (tablet) variants.
- [x] `sonar_farm_tablet/web/src/shell/ShellSidebar.tsx` — 240px Manager sidebar driven by route catalog.
- [x] `sonar_farm_tablet/web/src/shell/ShellContent.tsx` — padded scroll container, max-width per viewport.
- [x] `sonar_farm_tablet/web/src/shell/ManagerShell.tsx` — Laptop fullscreen (TopBar + Sidebar + Content).
- [x] `sonar_farm_tablet/web/src/shell/TabletShell.tsx` — 1280×800 centered overlay with inline tab nav.

### Pages (Frontend — Phase B)

- [x] `sonar_farm_tablet/web/src/pages/DashboardPage.tsx` — only page with demo data (KPI bento + BatchChip showcase). Demo strings under `demo.dashboard.*`.
- [x] 9 placeholder pages (`Plots/Batches/Market/Contracts/Personnel/Finance/Log/Tasks/Messages`) backed by a shared `_PagePlaceholder` consuming `EmptyState`.

### Client / FiveM integration (Integration Agent — pending)

- [ ] `sonar_farm_tablet/client/main.lua` — NUI lifecycle coordinator or imports new client modules.
- [ ] `sonar_farm_tablet/client/laptop_interaction.lua` — office laptop `ox_target` entrypoint opens NUI mode `manager`.
- [ ] `sonar_farm_tablet/client/tablet_interaction.lua` — configurable keybind opens NUI mode `field`.
- [ ] `sonar_farm_tablet/config.lua` — interaction/keybind settings; no magic values in client code.
- [ ] `sonar_farm_tablet/fxmanifest.lua` — load new client/config files and include NUI build files correctly.
- [ ] NUI close callback wiring on the Lua side (`RegisterNUICallback('close', ...)` → `SetNuiFocus(false, false)`).

### Tests / verification

- [x] `pnpm --filter @sonar/farm-tablet-web lint` passes (0 warnings, 0 errors).
- [x] `pnpm --filter @sonar/farm-tablet-web type-check` passes (strict + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`).
- [x] `pnpm --filter @sonar/farm-tablet-web build` passes (208 KB JS / 67 KB gzip, 17 KB CSS / 4.4 KB gzip).
- [x] Manual browser smoke via Vite dev mode (shell visible by default; route nav works; close button returns to hidden).
- [ ] QBox in-game smoke for laptop/tablet open/close (blocked on Integration Agent).
- [ ] QBCore in-game smoke (blocked on Integration Agent).

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

Authoritative visual sources: Bible §1.1, Bible §15, **UI Playbook v2** (signed 2026-05-19), ADR-006.

### 8.1 Signed NUI message contracts

Inbound (Lua → React, via `SendNUIMessage`):

```ts
type NuiInboundMessage =
  | { action: 'sonar:farm:nui:open'; payload: { mode: 'manager' | 'field'; route?: NuiRoute } }
  | { action: 'sonar:farm:nui:close' };

type NuiRoute =
  | '/dashboard'
  | '/plots'
  | '/batches'
  | '/market'
  | '/contracts'
  | '/personnel'
  | '/finance'
  | '/log'
  | '/tasks'
  | '/messages';
```

Both sides defensively parse incoming messages: React via `isNuiInboundMessage()` in `src/types/nui.ts`; Lua MUST mirror the same guard before any side effect.

Outbound (React → Lua, via `fetch('https://${resource}/<callback>')`):

| Endpoint | Payload | Expected response                              | When                                                                                                                        |
| -------- | ------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `close`  | `{}`    | `{ ok: true } \| { ok: false, error: string }` | User presses Escape or clicks the topbar close button. Lua must call `SetNuiFocus(false, false)` and return `{ ok: true }`. |

In browser dev (`isFiveM() === false`), `fetchNui` short-circuits to the supplied fallback and never hits the network, so designers can preview the shell in a Vite tab.

### 8.2 Signed component APIs (Playbook v2 §10)

#### BentoGrid (`components/layout/BentoGrid.tsx`)

```ts
<BentoGrid gap="sm" | "md" | "lg" columns={8 | 12}>
  <BentoGrid.Item span={number | { laptop: number; tablet?: number }}>...</BentoGrid.Item>
</BentoGrid>
```

- Default: `gap="md"` (16 px), `columns=12`.
- Item default `span={12}`.
- Spans rendered via inline `grid-column: span N / span N` so `noUncheckedIndexedAccess` cannot bite.
- Items expose `data-fs-bento-span` for QA tooling.

#### Card (`components/ui/Card.tsx`)

```ts
<Card padding="compact" | "comfortable" | "lg" interactive={boolean}>
  <Card.Header>…</Card.Header>
  <Card.Body>…</Card.Body>
  <Card.Footer>…</Card.Footer>
</Card>
```

- `interactive` adds `role="button" tabIndex={0}` plus focus ring (inherited from global `:focus-visible`).
- Style canon: `bg-fs-surface`, `border border-fs-border`, `rounded-2xl`, `shadow-none`.

#### BatchChip (`components/ui/BatchChip.tsx`)

```ts
<BatchChip
  batchId="b_8f3a4e2c91d0"
  quality?={'S' | 'A' | 'B' | 'C' | 'D' | null}
  freshness?={number | null}   // 0..100 — < 30 shows a danger marker
  onClick?={() => void}
  aria-label?={string}
/>
```

- IDs > 12 chars truncate to `b_8f3a4e…` (mono).
- Quality dot uses `--color-fs-quality-*` tokens.
- When clickable, renders as a `<button>` for keyboard accessibility.

#### LimePulse (`components/ui/LimePulse.tsx`)

```ts
<LimePulse size="sm" | "md" | "lg" label?={string} />
```

- Drives `.fs-pulse` from `globals.css`; goes static automatically under `prefers-reduced-motion`.
- When `label` is supplied, sets `role="status"` + `aria-label` for screen readers; otherwise `aria-hidden`.

#### Other primitives

- `Heading` (level: display/h1/h2/h3, optional `as`: h1-h4|span).
- `Body` (size: default/small/micro, `muted` boolean, optional `as`: p/span/div).
- `Mono` (size: default/small) — uses `.fs-mono` for `tnum`/`zero` features.
- `Button` (variant: primary/secondary/ghost/destructive, size: sm/md/lg, `loading`, `leftIcon`, `rightIcon`).
- `Icon` (Lucide wrapper, sizes xs/sm/md/lg/xl, stroke 1.5, auto `aria-hidden` when no label).
- `Skeleton` (variant: text/card/circle/rect, `lines` for text, reduced-motion safe).
- `EmptyState` / `ErrorState` (icon + heading + body + optional action button).

### 8.3 Shell anatomy (Playbook v2 §12)

- Manager: `--fs-topbar-h-manager` (64 px) + `--fs-sidebar-w-manager` (240 px).
- Tablet: `--fs-topbar-h-tablet` (56 px), no sidebar; tab nav inline on top of content.
- Both shells render the `AppRouter` mounted with `initialRoute` so Lua-driven deep-links land on the right page on open.
- Switching mode remounts the active shell (React `key="manager"` vs `key="field"`), which resets the in-memory router history.

### 8.4 i18n key namespaces

- `shell.*` — brand, tagline, close, loading.
- `mode.*` — `manager`, `field` labels.
- `nav.*` — one key per route (matches `routes.ts:labelKey`).
- `page.<route-key>.title` / `.subtitle` — per-page chrome.
- `page.dashboard.greeting` — hero greeting on dashboard.
- `state.loading.*`, `state.empty.*`, `state.error.*` — canonical UI states.
- `demo.dashboard.*` — placeholder strings used ONLY by `DashboardPage`. Will be deleted slice-by-slice as real data lights up.

### 8.5 Invariants preserved from S0

- React renders `null` when shell is hidden; body/html stay `background: transparent` so the FiveM canvas shows through.
- In Vite dev (`import.meta.env.DEV`), the shell starts visible in manager mode for designer productivity.
- In FiveM CEF (detected via `window.GetParentResourceName`), shell starts hidden and only `sonar:farm:nui:open` flips it visible.

### 8.6 Pending Integration contracts

Integration Agent owns:

- Choosing the laptop prop model + target coordinates → `Config.LaptopTarget` (no magic numbers).
- Choosing the tablet keybind → `Config.TabletKeybind` (`ox_lib` `lib.addKeybind` recommended).
- Lua `SendNUIMessage` payloads MUST match the contracts in §8.1 byte-for-byte.
- `RegisterNUICallback('close', ...)` MUST respond with `{ ok = true }` and call `SetNuiFocus(false, false)`.

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
