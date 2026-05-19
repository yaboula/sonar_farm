# S4 — NUI shell + design system

> **Status:** DONE
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** L (7-14 days)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S4](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** 2026-05-19
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

### Client / FiveM integration (Integration Agent — shipped 2026-05-19)

- [x] `sonar_farm_tablet/config.lua` — `Config.Farm.Laptop.*` (target model/label/icon/distance), `Config.Farm.Tablet.*` (keybind/label/default route), `Config.Farm.Nui.ResourceName`.
- [x] `sonar_farm_tablet/client/main.lua` — NUI lifecycle coordinator: `SonarFarmTablet.OpenNui(mode, route)`, `SonarFarmTablet.IsOpen()`, `RegisterNUICallback('close', ...)` → `SetNuiFocus(false, false)` + `SendNUIMessage({ action = 'sonar:farm:nui:close' })`.
- [x] `sonar_farm_tablet/client/laptop_interaction.lua` — `exports.ox_target:addModel` on `Config.Farm.Laptop.TargetModel`, opens NUI mode `manager` route `/dashboard`. Cleanup via `onResourceStop`.
- [x] `sonar_farm_tablet/client/tablet_interaction.lua` — `lib.addKeybind` with `Config.Farm.Tablet.Keybind` (default `F6`), opens NUI mode `field` route `/plots`.
- [x] `sonar_farm_tablet/locales/{en,es}.json` — localized Lua interaction labels for laptop target and tablet keybind.
- [x] `sonar_farm_tablet/fxmanifest.lua` — added `ox_target` dependency, `ox_lib 'locale'`, `config.lua` in shared_scripts, locales in `files`, three client files in deterministic order (`main.lua` → `laptop_interaction.lua` → `tablet_interaction.lua`).

### Tests / verification

- [x] `pnpm --filter @sonar/farm-tablet-web lint` passes (0 warnings, 0 errors).
- [x] `pnpm --filter @sonar/farm-tablet-web type-check` passes (strict + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`).
- [x] `pnpm --filter @sonar/farm-tablet-web build` passes (208 KB JS / 67 KB gzip, 17 KB CSS / 4.4 KB gzip).
- [x] Manual browser smoke via Vite dev mode (shell visible by default; route nav works; close button returns to hidden) — QA PASS 2026-05-19.
- [x] QBox in-game smoke for laptop/tablet open/close — **PASS** 2026-05-19.
- [x] QBCore in-game smoke — **PASS** via QBCore bridge (`qbx:enableBridge true`).

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [x] Works end-to-end on QBox (smoke documented in §10).
- [x] Works end-to-end on QBCore (smoke documented in §10).
- [x] Smoke test of happy path documented in §10.
- [x] Automated tests where they make sense (static lint/type/build; no runtime test harness added for shell-only UI).
- [x] No hardcoded user-facing strings — React strings via `t('key.path')`, locales EN/ES complete; Lua interaction labels via `locale()`.
- [x] No hardcoded magic numbers — config/CSS tokens used.
- [x] Respects the 5 Pillars of Bible §3.
- [x] Respects Bible §9.4 anti-patterns.
- [x] Respects naming conventions (rule `02_naming_conventions.md`).
- [x] DB migration versioned + rollbackable, if DB was touched (N/A — S4 touched no DB).
- [x] Mini-brief updated with what was actually built.
- [x] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken (N/A — ADR-006 already covered the UI surface decision).
- [x] Bible §18 changelog updated if product canon changed (N/A — no new product canon beyond UI Playbook v2).

## 6. Slice-specific DoD

- [x] Open Laptop with `ox_target` → NUI fullscreen/manager mode → dashboard placeholder uses Farm Sonar visual identity.
- [x] Open Tablet with configurable keybind → NUI field mode → field placeholder uses Farm Sonar visual identity.
- [x] ESC closes NUI, clears focus and returns player control.
- [x] Shell uses signed palette and flat minimalista cards per ADR-006; no glassmorphism, no dark default, no heavy shadows.
- [x] `BentoGrid`, `BatchChip` and `LimePulse` have stable typed APIs documented in §8.
- [x] NUI messages are typed in TypeScript and documented in §8.
- [x] React shell has a minimal i18n mechanism and no final hardcoded user-facing strings.
- [x] No direct client trust for gameplay state; S4 renders placeholders only.

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

- `shell.*` — brand, tagline, close, loading, navigation a11y labels.
- `mode.*` — `manager`, `field` labels.
- `nav.*` — one key per route (matches `routes.ts:labelKey`).
- `page.<route-key>.title` / `.subtitle` — per-page chrome.
- `page.dashboard.greeting` — hero greeting on dashboard.
- `state.loading.*`, `state.empty.*`, `state.error.*` — canonical UI states.
- `demo.dashboard.*` — placeholder strings used ONLY by `DashboardPage`. Will be deleted slice-by-slice as real data lights up.
- `component.batchChip.*` — `BatchChip` default aria label and freshness tooltip.
- `interaction.*` — Lua-side interaction labels in `sonar_farm_tablet/locales/{en,es}.json`.

### 8.5 Invariants preserved from S0

- React renders `null` when shell is hidden; body/html stay `background: transparent` so the FiveM canvas shows through.
- In Vite dev (`import.meta.env.DEV`), the shell starts visible in manager mode for designer productivity.
- In FiveM CEF (detected via `window.GetParentResourceName`), shell starts hidden and only `sonar:farm:nui:open` flips it visible.

### 8.6 Integration contracts (shipped)

#### Config keys (see `sonar_farm_tablet/config.lua`)

```lua
Config.Farm.Laptop.TargetModel    = 'prop_laptop_01a'   -- native GTA V laptop prop
Config.Farm.Laptop.TargetLabel    = locale('interaction.laptop.target_label')
Config.Farm.Laptop.TargetIcon     = 'fa-solid fa-laptop'
Config.Farm.Laptop.TargetDistance = 2.0

Config.Farm.Tablet.Keybind      = 'F6'
Config.Farm.Tablet.KeybindLabel = locale('interaction.tablet.keybind_label')
Config.Farm.Tablet.DefaultRoute = '/plots'

Config.Farm.Nui.ResourceName = 'sonar_farm_tablet'
```

#### NUI lifecycle

1. **Resource start**: NUI is hidden (no `SetNuiFocus` call on boot). React renders `null` until first `sonar:farm:nui:open`.
2. **Laptop open**: `ox_target` → `SonarFarmTablet.OpenNui('manager', '/dashboard')` → `SetNuiFocus(true, true)` + `SendNUIMessage`.
3. **Tablet open**: keybind `F6` → `SonarFarmTablet.OpenNui('field', '/plots')` → same focus + message path.
4. **Re-open while open**: sends a new `sonar:farm:nui:open` message without toggling focus (idempotent). React shell reacts to mode/route changes.
5. **ESC / close button**: React calls `fetch('https://sonar_farm_tablet/close', {})` → Lua `RegisterNUICallback('close')` → `SetNuiFocus(false, false)` + `SendNUIMessage({ action = 'sonar:farm:nui:close' })` → responds `{ ok = true }`.
6. **Resource stop**: `laptop_interaction.lua` unregisters `ox_target` model via `onResourceStop`.

#### Intra-resource communication

Client modules share state via the `SonarFarmTablet` global table:

- `SonarFarmTablet.OpenNui(mode, route)` — entrypoint called by interaction scripts.
- `SonarFarmTablet.IsOpen()` — returns `boolean`.

Load order in `fxmanifest.lua` ensures `main.lua` (defines `SonarFarmTablet`) runs before `laptop_interaction.lua` and `tablet_interaction.lua` (consume it).

## 9. ADRs created

- None yet. ADR-006 already covers flat minimalista surfaces.

## 10. Smoke test (happy path)

### Browser / Vite smoke (QA Agent — 2026-05-19)

**Procedure**

1. `pnpm --filter @sonar/farm-tablet-web lint` — from repo root.
2. `pnpm --filter @sonar/farm-tablet-web type-check`.
3. `pnpm --filter @sonar/farm-tablet-web build`.
4. `pnpm dev` in `sonar_farm_tablet/web` → open `http://127.0.0.1:3000/`.
5. Confirm manager shell visible by default (dev invariant in `useNuiVisibility`).
6. Click sidebar routes → placeholders render `EmptyState`.
7. Dashboard → `BentoGrid`, `BatchChip`, `LimePulse` visible with demo KPI cards.
8. Topbar close → shell hides (simulates ESC/close callback via `fetchNui` fallback).
9. Confirm no runtime dependency on `GetParentResourceName` in dev (`isFiveM()` false).

**Results: PASS**

| Check                            | Result | Evidence                                                                                               |
| -------------------------------- | ------ | ------------------------------------------------------------------------------------------------------ |
| lint                             | PASS   | 0 errors, 0 warnings                                                                                   |
| type-check                       | PASS   | strict + `noUncheckedIndexedAccess`                                                                    |
| build                            | PASS   | 208 KB JS / 67 KB gzip; 17 KB CSS                                                                      |
| Dev server boots                 | PASS   | Vite 6.4.2 @ `127.0.0.1:3000`                                                                          |
| Palette tokens                   | PASS   | `theme.css` defines `#d9eae3`, `#ffffff`, `#050505`, `#b6fb63`; bundled CSS contains `fs-bg` utilities |
| No glassmorphism / heavy shadows | PASS   | grep: no `backdrop-blur`, no `shadow-xl/2xl` in `web/src`                                              |
| No `font-bold` (700+) in shell   | PASS   | shell components use `font-medium` only; headings use `font-semibold` (600) outside shell              |
| Route placeholders               | PASS   | 10 routes + `_PagePlaceholder` + `EmptyState`                                                          |
| Demo components                  | PASS   | `DashboardPage` renders Bento + BatchChip + LimePulse                                                  |
| FiveM globals in dev             | PASS   | `env.ts` branches on `GetParentResourceName`; dev starts visible without it                            |

**Minor notes (non-blocking for browser smoke):**

- `web/index.html` `theme-color` meta is `#0A0E0A` (dark) — browser chrome only, not shell UI.
- Five hardcoded English a11y/tooltip strings remain (see §11 i18n audit).

### QBox in-game smoke (QA Agent — 2026-05-19)

**Procedure** (reproducible by founder — Integration Agent handoff):

1. `pnpm --filter @sonar/farm-tablet-web build`
2. Start QBox server: `ox_lib`, `ox_target`, `sonar_farm_core`, `sonar_farm_tablet`
3. Join → NUI hidden, no focus
4. `ox_target` on `prop_laptop_01a` → "Open Farm Sonar Manager" → manager `/dashboard`
5. ESC → close, focus released
6. F6 → field mode `/plots`
7. ESC → close
8. Repeat steps 4–7 three times
9. Check client/server console for errors

**Results: PASS (Founder smoke — 2026-05-19)**

| Check                              | Result                                                                                          | Notes                                                                                     |
| ---------------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| NUI hidden on join                 | PASS                                                                                            | No UI visible at spawn                                                                    |
| F6 → field mode `/plots`           | PASS                                                                                            | Tablet opens, nav tabs visible, placeholder correct                                       |
| ESC closes tablet                  | PASS                                                                                            | Focus released, player control returns                                                    |
| `ox_target` on `prop_laptop_01a`   | PASS                                                                                            | Prop spawned at `vec3(2455.16, 4972.49, 45.81)`, option "Open Farm Sonar Manager" appears |
| Laptop → manager mode `/dashboard` | PASS                                                                                            | Shell opens fullscreen, Farm Sonar branding visible                                       |
| ESC closes manager                 | PASS                                                                                            | Focus released                                                                            |
| Repeated open/close cycles         | PASS                                                                                            | No focus stuck across multiple cycles                                                     |
| F8 console errors                  | **Fixed** — `useLocation() outside Router` bug fixed by moving `MemoryRouter` up to shell level |

**Bug found and fixed during smoke:**
`NavLink` components in `ShellSidebar` (manager) and the tablet nav bar were outside the `MemoryRouter` context. Fixed by exporting `AppRoutes` separately and having each shell own its `MemoryRouter`.

### QBCore in-game smoke

**Results: PASS by bridge** — `setr qbx:enableBridge "true"` is active in `server.cfg`; the server runs QBox with the QBCore bridge enabled. No separate QBCore server needed.

## 11. Closing summary

> **QA Agent report — 2026-05-19.** S4 is closed after founder smoke passed on QBox and QBCore bridge mode. Minor i18n/a11y gaps found during QA were fixed before closure rather than accepted as debt, preserving the universal DoD.

### DoD verification report (QA Agent)

#### Static / build

| Item                                               | Result                             |
| -------------------------------------------------- | ---------------------------------- |
| `pnpm --filter @sonar/farm-tablet-web lint`        | **PASS**                           |
| `pnpm --filter @sonar/farm-tablet-web type-check`  | **PASS**                           |
| `pnpm --filter @sonar/farm-tablet-web build`       | **PASS**                           |
| `pnpm lint:lua` (selene on `sonar_farm_tablet`)    | **PASS** (0 errors, 0 warnings)    |
| No TypeScript `any` drift                          | **PASS** (grep: none in `web/src`) |
| No random hex in components                        | **PASS** (hex only in `theme.css`) |
| No glassmorphism / heavy shadows / dark default UI | **PASS**                           |
| No `font-bold` / 700+ in shell components          | **PASS**                           |

#### Browser visual smoke

| Item                                                | Result                                                                    |
| --------------------------------------------------- | ------------------------------------------------------------------------- |
| Vite dev without FiveM globals                      | **PASS**                                                                  |
| Shell palette matches Playbook                      | **PASS** (token audit)                                                    |
| Manager + field route placeholders                  | **PASS** (code + dev server)                                              |
| `BentoGrid`, `BatchChip`, `LimePulse` in demo state | **PASS** (`DashboardPage`)                                                |
| Loading / empty / error placeholders                | **PASS** (`Skeleton`, `EmptyState`, `ErrorState`; pages use `EmptyState`) |

#### i18n audit

| Item                               | Result                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------ |
| Primary UI copy via `t()`          | **PASS** (nav, pages, shell, states, demo namespaces)                                      |
| `en.json` / `es.json` in sync      | **PASS** (matching key trees)                                                              |
| Zero hardcoded user-facing strings | **PASS** — remaining a11y/interaction labels moved to React locales and tablet Lua locales |

**Hardcoded string gaps found during QA and fixed before close:**

| Location           | String                                        | Severity                                                        |
| ------------------ | --------------------------------------------- | --------------------------------------------------------------- |
| `BatchChip.tsx`    | `title="Low freshness"`                       | Fixed via `component.batchChip.lowFreshness`                    |
| `BatchChip.tsx`    | `` `Batch ${batchId}` `` default `aria-label` | Fixed via `component.batchChip.ariaLabel` interpolation         |
| `ShellSidebar.tsx` | `aria-label="Primary navigation"`             | Fixed via `shell.primaryNavigation`                             |
| `TabletShell.tsx`  | `aria-label="Tablet apps"`                    | Fixed via `shell.tabletApps`                                    |
| `Skeleton.tsx`     | default `aria-label = 'Loading'`              | Fixed via `state.loading.title`                                 |
| `config.lua`       | `TargetLabel`, `KeybindLabel` in English      | Fixed via `sonar_farm_tablet/locales/{en,es}.json` + `locale()` |

#### Slice-specific DoD (§6)

| Item                                                     | Result                                   |
| -------------------------------------------------------- | ---------------------------------------- |
| Laptop `ox_target` → manager dashboard                   | **PASS** — founder smoke 2026-05-19      |
| Tablet keybind → field placeholder                       | **PASS** — founder smoke 2026-05-19      |
| ESC closes NUI + releases focus                          | **PASS** — founder smoke 2026-05-19      |
| Signed palette + flat cards (ADR-006)                    | **PASS**                                 |
| `BentoGrid` / `BatchChip` / `LimePulse` typed APIs in §8 | **PASS**                                 |
| NUI messages typed + documented §8.1                     | **PASS**                                 |
| React i18n, no final hardcoded strings                   | **PASS** — gaps above fixed before close |
| No client-trust gameplay state                           | **PASS** (placeholders only)             |

#### Universal DoD (§5)

| Item                               | Result                                                               |
| ---------------------------------- | -------------------------------------------------------------------- |
| QBox end-to-end                    | **PASS** — founder smoke 2026-05-19                                  |
| QBCore end-to-end                  | **PASS** — QBCore bridge active                                      |
| Happy-path smoke documented        | **PASS** (§10 updated)                                               |
| Automated tests                    | **N/A** — no Vitest/Jest harness in repo; per QA scope, not invented |
| No hardcoded UI strings            | **PASS**                                                             |
| No magic numbers in client Lua     | **PASS** (`config.lua`)                                              |
| 5 Pillars / anti-patterns / naming | **PASS** (static review)                                             |
| DB migration                       | **N/A**                                                              |
| Mini-brief updated                 | **PASS** (this section)                                              |
| ADR for non-obvious decisions      | **N/A**                                                              |
| Bible §18 changelog                | **N/A**                                                              |

### What shipped

- Full React NUI shell (manager + field), design system primitives, typed NUI contracts, i18n EN/ES, Integration Agent Lua lifecycle (see §4).
- Laptop prop auto-spawn at `vec3(2455.16, 4972.49, 45.81)` heading `131.47` via `Config.Farm.Laptop.SpawnProp/SpawnCoords/SpawnHeading`.
- Router bug fixed: `MemoryRouter` moved up to shell level so `NavLink` in sidebar/tab-nav is always inside Router context.
- `fivem.yml` extended with object/model native declarations (`vector3/4`, `CreateObject`, `RequestModel`, etc.).

### Deviations from plan

- `MemoryRouter` was initially scoped too low (inside `AppRouter` only); fixed during QA smoke.
- Minor a11y/i18n strings were initially found during QA; they were fixed before close instead of accepted as debt.

### Discoveries / lessons

- `pnpm lint:lua` prints `ERROR: lua version lua52 in standard library, but feature for it is not enabled` yet exits 0 — cosmetic selene quirk, not a failure.
- `SonarFarmTablet` global required `sonar.yml` selene stdlib update (Integration Agent note confirmed).
- Browser dev correctly starts shell visible; FiveM CEF starts hidden — dual invariant works as designed.
- `NavLink` / `useLocation` crash silently in CEF if rendered outside a Router context — always wrap the full shell tree in `MemoryRouter`, not just the `<Routes>` subtree.

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
