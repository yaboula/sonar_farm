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

## v0 review outcome (2026-05-23)

Mockup approved as implementation baseline. Reference repo: `https://github.com/yaboula/sonar_farm_market` (local clone in `_v0_review_market/`).

Adjustments to apply during implementation (no second v0 round):

- **CTA rename for Pilar 1 compliance.** Buttons currently labelled "Plan delivery" must read **"Set on map"** (or its i18n key equivalent). The action only drops a waypoint on the player's FiveM map; selling stays physical at the NPC ped.
- **Lime usage as designed.** Founder approved the v0 lime distribution (live tick, day pill, top-match stamp, featured CTA, best-price chip, plan-arrow). Treat it as canon for this slice.
- **Server-derived "Top match today".** The server returns buyers pre-sorted by `today_top_price` and flags the #1 as featured. No client-side ranking heuristics.
- **Unit mapping.** v0 shows prices `€/kg` and capacity `t / kg`. Backend stores `€/g` and volume in grams. Convert at the catalog callback boundary, not in components.

## v0.dev prompt to copy / paste

```text
You are designing a single screen of a premium product called **Farm Sonar**, a calm-tech management OS for farmers in a roleplay world. Think of the visual quality bar as: an iOS native app, a Vercel dashboard, a Linear project view, a Climate FieldView pro panel. Quiet, confident, intentional. NOT a "generic AI dashboard" with random gradients, glassy cards, neon stats and emoji.

# THE PRODUCT IN ONE PARAGRAPH

Farm Sonar is the management OS a serious farmer opens on their laptop at 7am with their coffee. It tracks plots, crops, climate, machinery, sales, and contracts. The product feels like Apple-Notes-meets-Bloomberg-for-agriculture: minimalist, dense when it needs to be, beautiful in stillness. The farmer trusts it the way they trust their tractor.

# THIS SCREEN

The "Market" view. The farmer's morning check-in. They want to answer ONE question in under 5 seconds: "where should I sell my harvest today, and to whom?".

There are roughly 6 to 10 NPC buyers in the city (a mill, a supermarket chain, a fine-dining restaurant, a regional distributor, a cannery, etc.). Each buyer has its own personality: which crops it accepts, the minimum quality it tolerates, the price it pays today, how much volume it can absorb today, and whether it offers recurring contracts.

The farmer compares them, picks one, mentally commits, closes the laptop, and walks out to the field. They will physically drive to the NPC to sell (that happens out of this screen). So this view is purely informational + planning. No selling, no signing, no charts (those come in later product iterations).

# WHO THIS SCREEN SERVES

A 30-something player who already has muscle memory for SaaS products. They appreciate restraint. They will use this screen every single in-game day for hundreds of hours. It must hold up under repetition. It must reward a second look.

# BRAND (NON-NEGOTIABLE)

Use these tokens exactly. Do not invent colors, do not "improve" them, do not add gradients.

- Background canvas: #D9EAE3 (a soft sage green, our signature).
- Surface (cards, panels): #FFFFFF.
- Foreground text: #050505. Muted text: #969C9C.
- Borders: rgba(150, 156, 156, 0.2) at 1px. No shadows. No glass. No blur.
- Single accent: lime #B6FB63. Use it ONCE or TWICE on the whole screen, on the single most important affordance or the single live signal. Never as decoration.
- Quality grade chips (when a quality letter appears): S and A use #E8F7E0 background with #2F6B1F text. B uses #FFF4D6 / #7A5200. C and D use #FDE3E3 / #8A1F1F.

Typography:
- UI: Geist Sans. Weights 400, 500, 600 only. Never 700+.
- IDs, numbers, prices, timestamps, batch codes: JetBrains Mono.

Geometry:
- Generous whitespace. Comfortable density, not cramped, not airy-empty.
- Corner radius 16 to 20px on surfaces.
- Icons: Lucide React, stroke 1.5, size 16 or 20.

# WHAT THE SCREEN MUST COMMUNICATE

It must let the farmer:
1. Sense the overall state of the market today, in one glance. Is the day busy? Are there premium opportunities?
2. Scan buyers and find the best fit for what they have in their silo right now.
3. Get a feel for each buyer's personality: are they picky? generous? high volume? premium?
4. Notice changes since the last time they checked (something updated, something is new).

Per buyer the farmer eventually needs to see: name, what kind of business they are, where they are, which crops they accept with which minimum quality and at which price today, how much they can still buy today, and whether contracts are offered. How you compose that is your call.

# THREE STATES

Design all three:
1. Loaded — populated with 8 buyers (mix of types).
2. Loading — your interpretation of a calm, on-brand skeleton.
3. Empty — when no buyer is online right now (it can happen between in-game days).

# CREATIVE FREEDOM

I am NOT prescribing the layout. Surprise me.

- You can use a grid, a list, a hybrid, a mosaic — whatever serves the farmer best.
- You can introduce one signature visual element (a subtle texture, a hairline, a typographic move, a way of laying out numbers) that becomes the screen's identity. Make it feel like a screen designed by a senior product designer who cares.
- You can vary card sizes if it helps hierarchy (some buyers may deserve more space, e.g. the top match today).
- You can introduce a single ambient micro-detail (a tiny live tick, a discreet pulse) — but only one, and only on the lime accent.

# AVOID THE "AI DASHBOARD" LOOK

Do not produce:
- Big rainbow gradient hero blocks.
- Glass-morphism / frosted blur cards.
- Card grids where every card looks identical and dead.
- "Insight cards" with giant numbers and emojis.
- Decorative dotted backgrounds, decorative arrows, decorative anything.
- Two competing accent colors. There is exactly one (lime), used once.

# DELIVERABLE

React + Tailwind, using shadcn/ui primitives where they earn their place (Card, Badge, Button, Progress, Skeleton, Tooltip, Drawer). Use realistic Spanish/English-mixed placeholder buyer names that sound like a roleplay city (Molino Pedro, Supermercado Casals, Restaurante La Plaza, Distribuidora Vega, Conservera del Sur, etc.). Realistic crop names: wheat, corn, barley, tomato, pepper, lettuce, onion, potato.

Make me want to use this screen every morning.
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
