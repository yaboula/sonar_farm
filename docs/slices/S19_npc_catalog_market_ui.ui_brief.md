# UI Brief — S19 · MarketApp (Laptop)

## Context

The **Market** app is the player's first daily check-in. It lives in the Laptop (Manager Panel) shell shipped in S4. It tells the farmer, at a glance, which of the 6-10 NPC buyers in the city is paying the most today for each crop and quality grade, and which of them have contracts available. The player uses this screen to plan the day's harvest and decide where to ship.

## Surface type

- [x] Manager Panel (Laptop, fullscreen, dense data)
- [ ] Tablet field (overlay, glanceable, action-oriented)
- [ ] Modal / Drawer / Sheet
- [ ] Inline component

## Data shown

For each NPC card (6-10 cards total in a Bento grid):

- **NPC name** (e.g. "Molino Pedro", "Supermercado Casals") — from `Config.Farm.NPCs.buyers[id].display_name_key` (i18n).
- **NPC role/type tag** (e.g. "Mill", "Supermarket", "Restaurant", "Distributor", "Cannery") — from `Config.Farm.NPCs.buyers[id].type`.
- **Distance / coords hint** ("Sandy Shores · 320m") — from `Config.Farm.NPCs.buyers[id].coords` + player position (client-computed).
- **Accepted crops list** with: crop icon, quality minimum (S/A/B/C/D color-coded), today's price per gram. Source: `sonar:farm:market:get_catalog` callback returning a snapshot of the in-memory buyer state.
- **Volume capacity today** — progress bar (e.g. "1240g / 5000g today"). Source: `sonar_farm_npc_buyer_state.volume_remaining_today`.
- **Contract availability** — small Badge: "Open" / "Locked at Rep X" / "Coming in S21". For S19 keep static "Coming Soon".
- **Last update timestamp** in mono font (e.g. `12:42:08`). Source: market service tick.

Header strip across the top:

- **Day** (in-game day number) + season icon (from S16 climate).
- **Market summary**: total buyers active / total buyers offline.
- **Refresh button** (mono icon, ghost button).

## Actions available

- **Card click** → opens a `Drawer` with the full price matrix (every crop × every quality grade) for that NPC. Drawer is read-only in S19; "Open Contracts" CTA is disabled and shows tooltip "Available in S21".
- **Refresh button** → re-fires `sonar:farm:market:get_catalog`, animates a `LimePulse` on the freshly-updated cards.
- **Quality letter chip in card** → tooltip with explanation ("A = Premium, ≥85 quality_score") — pulled from i18n.
- No write actions in S19. Selling still happens physically at the NPC ped via `ox_target` (Integration Agent path), not via this UI.

## Layout intent

- **BentoGrid** at 12-col with NPC cards spanning 3 or 4 columns each, so the grid breaks into 3-4 cards per row on Laptop 1920×1080.
- Top header strip is a single full-width Card (`span={12}`).
- Empty state when no NPCs are online: full-grid EmptyState with "All buyers are offline right now. Try again at next in-game day." plus an inline icon.
- Drawer slides in from the right at ~480px width.

## Components needed

shadcn primitives:

- `Card`, `Badge`, `Button`, `Drawer`, `Tooltip`, `Skeleton`, `Progress`, `Separator`.

Farm Sonar signature:

- `BentoGrid`, `BentoGrid.Item`, `LimePulse` (on refresh), `Heading`, `Body`, `Mono`, `Icon`, `EmptyState`, `ErrorState`.

Custom one-off:

- `<QualityChip grade="A" />` — S/A/B/C/D colored letter chip (color tokens from Bible §1.1).
- `<NpcCard npc={...} />` — composition of the items above.

## Motion intent

- Card entrance: staged fade-up, 16ms stagger per card, 220ms duration, CSS only (per UI Playbook v2 hybrid staged decision).
- Refresh: `LimePulse` ring around updated cards for 600ms.
- Drawer: shadcn default slide-in.
- No motion for hover beyond shadcn defaults.

## Inspirations

- **Linear** issue board cards (dense info, calm hierarchy).
- **Stripe** Connect dashboard for partner cards.
- **Climate FieldView** "Buyer Insights" panel for the agronomic feel.

## Out of scope

- Price history line charts → S20.
- Contract listing and signing UI → S21.
- Reputation badges → S22.
- Selling action from the UI → never (Farm Sonar Pilar 1: physical, the sale happens at the NPC ped).
- Tablet/field counterpart of this view → out of scope, Market is Laptop-only.

## v0.dev prompt to copy / paste

```text
Design a "Market" dashboard screen for a FiveM farming management app called Farm Sonar.

VIEWPORT: 1920x1080 laptop fullscreen, with a fixed left sidebar (240px) and topbar (64px) already provided by the shell — design only the inner content area.

VISUAL CANON (mandatory):
- AgriSphere Light Mode, calm-tech, iPad-like.
- Background: #D9EAE3. Surface (card bg): #FFFFFF.
- Foreground text: #050505. Muted: #969C9C. Border: rgba(150,156,156,0.2) at 1px.
- The ONLY saturated accent is lime #B6FB63 — use it sparingly, only on the refresh button and the LimePulse refresh ring.
- Surfaces are flat minimalist: NO shadows, NO glassmorphism, NO blur. Subtle 1px border only.
- Typography: Geist Sans for UI, JetBrains Mono for IDs and timestamps. Weights 400/500/600 only. Never 700+.
- Bento layout: 12-col grid, 16px gap, rounded-2xl corners (16-20px).
- Quality letters S/A/B/C/D color-coded as paired bg+text: S #E8F7E0/#2F6B1F, A #E8F7E0/#2F6B1F, B #FFF4D6/#7A5200, C #FDE3E3/#8A1F1F, D #FDE3E3/#8A1F1F. Use them as small chips.
- Icons: Lucide React, stroke-width 1.5, size 16 or 20.

CONTENT:
- Top strip: full-width card showing "Day 47 · Spring" with a small leaf icon, plus "8 buyers active · 2 offline" right-aligned, plus a refresh button on the far right (ghost button with refresh-cw icon, lime accent on hover).
- Bento grid of 8 NPC cards (3 columns at 1920px). Each card shows:
  - Top row: NPC name in 16px semibold + role tag chip ("Mill", "Supermarket", "Restaurant", "Distributor", "Cannery") + a small distance hint in mono ("Sandy Shores · 320m").
  - Middle: list of up to 3 accepted crops, each row = crop icon (Lucide wheat/leaf/etc) + crop name + quality min chip + today's price in mono right-aligned ("$0.42/g").
  - Bottom: a thin Progress bar labelled "Volume today" with mono numbers "1240g / 5000g" and a "Contracts: Coming Soon" disabled badge.
- Inside the card, last-update mono timestamp tucked bottom-right ("12:42:08").

STATES TO SHOW (3 separate frames):
1. Loaded state with 8 NPC cards populated.
2. Loading state with 8 Skeleton cards.
3. Empty state: full-grid centered illustration + "All buyers are offline right now" + "Check back at next in-game day".

OUT OF SCOPE: do not design contract listing, no charts, no Tablet variant.

Output: a clean v0.dev React + Tailwind component using shadcn/ui primitives where possible (Card, Badge, Button, Progress, Skeleton, Tooltip). Use placeholder data.
```

## Review checklist (before approving v0 mockup)

- [ ] Uses Farm Sonar palette tokens (no random hex).
- [ ] Uses Geist Sans + JetBrains Mono only.
- [ ] Uses shadcn primitives where applicable (no reinvented buttons/inputs).
- [ ] Bento grid where multiple data clusters coexist.
- [ ] Flat minimalist surfaces (no shadow / no glass).
- [ ] Lime `#B6FB63` used sparingly, only on key actions / focal data.
- [ ] Quality letters S/A/B/C/D color-coded per Bible §1.1.
- [ ] Mono font for IDs (timestamps, prices, volume numbers).
- [ ] No string is hardcoded — all reference i18n keys (will be wired during impl).
- [ ] Loading + empty + error states designed.
- [ ] Laptop 1920×1080 aspect respected.
