# Farm Sonar — UI Playbook

> **Versión:** v2.0 — Production canon (AAA from commit 0).
> **Fecha:** 2026-05-19.
> **Estado:** living document. Reemplaza v1.0 (foundation). Las decisiones de v1 quedan en §21 Changelog.
> **Fuente canónica:** `docs/00_BIBLE.md §1.1`, `docs/00_BIBLE.md §15`, `docs/02_DECISIONS.md ADR-006`.
> **Scope v2:** identidad visual + paleta + tipografía + escala de spacing + viewports + iconografía + Bento system + signature components + estados + shell anatomy + page templates + motion canon + accesibilidad + data viz tokens + proceso v0.dev + DoD visual.
> **No scope v2:** tipos de chart Recharts firmados (se difieren a S20), sound design final (sigue TBD a propósito), componentes de apps específicas que no existen todavía (Personnel toggles, Drone scaleform, etc.).

---

## 0. Para qué existe este documento

Este Playbook convierte la identidad visual de Farm Sonar en reglas operables para Cascade, v0.dev, Opus y futuros sub-agents.

La v2 no es un experimento de diseño: es el **canon AAA** sobre el que se construye toda UI de Farm Sonar desde el primer commit. Cierra todos los "TBD controlados" de v1 con decisiones firmadas, para que ningún slice futuro tenga que re-decidir paleta, escala, motion o patrones de pantalla.

No sustituye al Bible. El orden de autoridad es:

1. `docs/00_BIBLE.md` — producto, pilares, identidad, anti-features. **Autoridad máxima.**
2. `docs/02_DECISIONS.md` — ADRs de decisiones no obvias. Para UI, ver **ADR-006**.
3. `docs/04_UI_PLAYBOOK.md` — cómo ejecutar la UI sin reinterpretar el canon.
4. Mini-brief del slice activo — scope puntual de implementación.

Si una decisión visual contradice el Bible, se debe parar y abrir ADR antes de programar.

---

## 1. Principio visual rector

Farm Sonar no debe parecer un script FiveM. Debe parecer un **producto SaaS agritech premium** incrustado en FiveM.

La referencia primaria firmada es:

- **AgriSphere** — light mode fresco, limpio, agrícola, táctil, moderno.

Referencias secundarias:

- **Linear** — jerarquía silenciosa, flujos limpios.
- **Stripe Dashboard** — datos densos pero legibles.
- **Vercel** — precisión visual, espacio, calma.
- **Climate FieldView / John Deere Operations Center** — credibilidad agrícola profesional.

El tono es:

- **Calm-Tech**
- **iPad-like**
- **SaaS premium**
- **Agritech limpio**
- **Bento-first**

Queda prohibido:

- UI oscura genérica tipo hacker.
- Panel administrativo barato comprimido.
- Gradientes agresivos.
- Sombras pesadas.
- Cards glassmorphism borrosas.
- Colores saturados secundarios compitiendo con el lima.
- Emojis decorativos en la UI (Lucide React es la única iconografía permitida, ver §8).

Justificación del descarte de glassmorphism: ADR-006.

---

## 2. Paleta canónica

### 2.1 Surface palette (firmada en `00_BIBLE.md §1.1`)

| Token           |                     Hex | Uso                                               |
| --------------- | ----------------------: | ------------------------------------------------- |
| `--fs-bg`       |               `#D9EAE3` | Fondo principal. Menta/salvia claro.              |
| `--fs-surface`  |               `#FFFFFF` | Cards, paneles, Bento. Blanco puro.               |
| `--fs-nav`      |               `#050505` | Menú principal, pills oscuras, contraste extremo. |
| `--fs-accent`   |               `#B6FB63` | Único acento. Lima Calm-Tech.                     |
| `--fs-fg`       |               `#050505` | Texto principal sobre superficies claras.         |
| `--fs-fg-muted` |               `#969C9C` | Texto secundario, labels, iconos inactivos.       |
| `--fs-border`   | `#969C9C` con alpha 20% | Bordes 1px ultra sutiles.                         |

### 2.2 Regla del acento único

`#B6FB63` es el único color saturado de identidad.

Se usa para:

- CTA principal (un único primary por pantalla).
- Estados positivos de alta importancia (harvest ready, calidad A/S).
- Indicadores de actividad (`<LimePulse>`).
- Focus ring de elementos interactivos (§15.3).

No se añade acento secundario. Si una pantalla parece necesitar otro acento, primero se debe resolver con jerarquía, tamaño, spacing o contraste con `--fs-nav`.

### 2.3 Status colors firmados (v2)

Estados semánticos. Pares fondo pastel + texto oscuro con contraste AA (≥4.5:1) verificado. Nunca compiten visualmente con el lima.

| Estado  | Token fondo       | Hex fondo | Token texto       | Hex texto | Uso                                     |
| ------- | ----------------- | --------- | ----------------- | --------- | --------------------------------------- |
| Success | `--fs-success-bg` | `#E8F7E0` | `--fs-success-fg` | `#2F6B1F` | Completado, OK, entrega cumplida.       |
| Warning | `--fs-warning-bg` | `#FFF4D6` | `--fs-warning-fg` | `#7A5200` | Riesgo, cosecha tardía, plaga probable. |
| Danger  | `--fs-danger-bg`  | `#FDE3E3` | `--fs-danger-fg`  | `#8A1F1F` | Error, contrato roto, calidad D.        |
| Info    | `--fs-info-bg`    | `#E3EEF9` | `--fs-info-fg`    | `#1F3F6B` | Mensajes neutrales, contextual.         |

Reglas:

- Saturación baja en ambos tonos.
- Border opcional en color `text` con alpha 20% si la card status necesita más definición.
- Iconografía dentro del badge: hereda `text` con stroke 1.5.
- Nunca usar status colors como CTA primario; el primary siempre es `--fs-accent`.

### 2.4 Quality tier colors (S/A/B/C/D)

Los lotes muestran su calidad con la siguiente paleta. Firmada como subset de §2.1 + §2.3 para evitar saturación.

| Tier | Color visual              | Hex sugerido | Uso                             |
| ---- | ------------------------- | ------------ | ------------------------------- |
| S    | Lima Calm-Tech (acento)   | `#B6FB63`    | Premium absoluto. Raro. Pulsa.  |
| A    | Lima Calm-Tech (acento)   | `#B6FB63`    | Excelente. Estático, sin pulso. |
| B    | Verde pastel suave        | `#EEF7EF`    | Calidad estándar.               |
| C    | Ámbar pastel (warning bg) | `#FFF4D6`    | Aceptable, atención.            |
| D    | Rojo pastel (danger bg)   | `#FDE3E3`    | Rechazado.                      |

Las letras del tier siempre van en `text-fs-fg` (negro) sobre el chip de color, en Geist Sans 600.

---

## 3. Superficies y acabado

Decisión firmada por ADR-006:

> Farm Sonar usa **Flat Minimalista**, no Glassmorphism.

### 3.1 Cards

Las cards estándar son:

- Fondo: `#FFFFFF`.
- Sombra: `shadow-none`.
- Borde: 1px, `--fs-border` (#969C9C con alpha 20%).
- Radius: `rounded-2xl`.
- Padding: comfortable (ver §7 spacing scale).

Queda prohibido por defecto:

- `backdrop-blur`.
- `bg-white/70` como superficie principal.
- Sombras grandes tipo dashboard template.
- Cards con fondos translúcidos sobre el menta.

### 3.2 Elevation tokens (v2)

Para coherencia futura, firmamos 3 niveles. Solo `--fs-elevation-0` se usa por defecto. Los niveles 1-2 quedan reservados para hover/modal y requerirán ADR antes de activarse en producción.

| Token              | Definición                 | Uso                                     |
| ------------------ | -------------------------- | --------------------------------------- |
| `--fs-elevation-0` | `shadow-none` + 1px border | Default. Toda card Bento.               |
| `--fs-elevation-1` | reservado                  | Hover sutil. Requiere ADR para activar. |
| `--fs-elevation-2` | reservado                  | Modal/Dialog elevado. Requiere ADR.     |

Hoy todas las superficies usan `--fs-elevation-0`. La uniformidad refuerza el tono Calm-Tech.

### 3.3 Nav / Pill menu

El nav principal usa `#050505` para crear contraste extremo contra el background menta.

Debe sentirse como una cápsula premium:

- Fondo negro casi puro.
- Texto claro (`#FFFFFF` o `rgb(255 255 255 / 0.7)` para inactivos).
- Acento lima solo para estado activo o acción primaria.
- Radius alto (rounded-2xl o pill completo).
- Espaciado generoso.

---

## 4. Tipografía

La tipografía está firmada en `00_BIBLE.md §1`.

| Uso                                                   | Familia        |
| ----------------------------------------------------- | -------------- |
| UI, texto base, títulos, display                      | Geist Sans     |
| IDs, IBANs, timestamps, coordenadas, metadata técnica | JetBrains Mono |

### 4.1 Pesos permitidos

Solo se cargan y usan:

- `400` — regular. Texto base, contenido estándar.
- `500` — medium. Botones, labels, pares key/value, énfasis suave.
- `600` — semibold. Títulos de sección, KPIs, greeting hero.

Queda prohibido `700+` salvo ADR futuro. La jerarquía visual se construye con tamaño, whitespace y contraste, no con bold agresivo.

### 4.2 Escala tipográfica firmada (v2)

Escala única por viewport. El root `font-size` cambia entre Laptop (16px) y Tablet (15px) — ver §6.

| Token             | Tamaño (rem) | Px @16 root | Line-height | Letter-spacing | Peso default | Uso                                         |
| ----------------- | -----------: | ----------: | ----------: | -------------: | ------------ | ------------------------------------------- |
| `text-fs-display` |       2.5rem |        40px |         1.1 |        -0.02em | 600          | Hero greeting (rare).                       |
| `text-fs-h1`      |         2rem |        32px |        1.15 |       -0.015em | 600          | Page title (DashboardPage).                 |
| `text-fs-h2`      |       1.5rem |        24px |         1.2 |        -0.01em | 600          | Section heading (Bento card title).         |
| `text-fs-h3`      |      1.25rem |        20px |         1.3 |              0 | 500          | Sub-section, KPI label.                     |
| `text-fs-body`    |         1rem |        16px |        1.55 |              0 | 400          | Body text default.                          |
| `text-fs-small`   |     0.875rem |        14px |        1.45 |              0 | 400          | Captions, hints, footer.                    |
| `text-fs-micro`   |      0.75rem |        12px |         1.4 |         0.01em | 500          | Badges, labels uppercase, table headers.    |
| `text-fs-mono`    |         1rem |        16px |        1.45 |         0.01em | 500          | IDs / IBANs / timestamps (font: JetBrains). |

Reglas:

- Para batch_id, IBAN, dates, coords: SIEMPRE `text-fs-mono` (que aplica `font-family: var(--font-mono)`).
- Para KPIs grandes (Dashboard): `text-fs-display` o `text-fs-h1`, peso 600.
- Para body: nunca por debajo de 14px (`text-fs-small`). 12px solo para metadata accesoria.

---

## 5. Bento System

El Bento Grid es el paradigma de layout firmado en `00_BIBLE.md §1`.

### 5.1 Regla de oro

La interfaz debe respirar. Farm Sonar no es un panel administrativo barato.

Queda prohibido comprimir iconos, KPIs y textos para meter "más cosas" en pantalla.

### 5.2 Geometría firmada

| Variable          | Valor firmado             |
| ----------------- | ------------------------- |
| Gap entre cards   | `16px` (`--spacing-fs-4`) |
| Radius            | `rounded-2xl` (16px)      |
| Densidad          | Comfortable               |
| Padding base card | `24px` (`--spacing-fs-6`) |
| Estilo            | Calm-Tech / iPad-like     |

### 5.3 Grid base por viewport

| Viewport | Columnas base | Container max-width | Gap horizontal/vertical |
| -------- | ------------: | ------------------: | ----------------------- |
| Laptop   |            12 |              1440px | 16px / 16px             |
| Tablet   |             8 |              1248px | 16px / 16px             |

### 5.4 Spans canónicos

Ejemplos de composición Bento Laptop (12 cols):

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Dashboard (manager)                                                     │
│ ┌────────────────┐  ┌────────────────┐  ┌────────────────┐              │
│ │ KPI 1   col-4  │  │ KPI 2   col-4  │  │ KPI 3   col-4  │              │
│ └────────────────┘  └────────────────┘  └────────────────┘              │
│ ┌────────────────────────────────┐  ┌────────────────────────────────┐  │
│ │ Chart 30d         col-8        │  │ Recent batches    col-4        │  │
│ │                                │  │                                │  │
│ └────────────────────────────────┘  └────────────────────────────────┘  │
│ ┌─────────────────────────────────────────────────────────────────┐     │
│ │ Alerts feed                                            col-12   │     │
│ └─────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

Reglas:

- Spans válidos en Laptop: `col-span-3`, `col-span-4`, `col-span-6`, `col-span-8`, `col-span-9`, `col-span-12`.
- Spans válidos en Tablet: `col-span-2`, `col-span-4`, `col-span-6`, `col-span-8`.
- Evitar más de 4 cards en una fila (pierde jerarquía).
- Composición asimétrica controlada > grid simétrico repetido.

### 5.5 Layout

El layout debe preferir:

- Cards con propósito único.
- KPIs grandes y silenciosos.
- Agrupación por tareas, no por tablas gigantes.
- Composición asimétrica controlada.

Evitar:

- Tablas masivas antes de ser necesarias.
- Lists infinitas sin agrupación.
- Cards idénticas repetidas sin jerarquía.
- Microtextos apretados.

---

## 6. Viewports y densidades

Bible §15 firma dos surfaces distintos: **Laptop** (oficina, gestión profunda) y **Tablet** (campo, apps reducidas). El UI Playbook v2 firma sus viewports operativos.

### 6.1 Viewports canónicos

| Surface | Resolución target | Modo                             | Root font-size | Container max-width |
| ------- | ----------------: | -------------------------------- | -------------: | ------------------: |
| Laptop  |       1920 × 1080 | Fullscreen NUI (sin overlay HUD) |           16px |              1440px |
| Tablet  |        1280 × 800 | Overlay centrado sobre el juego  |           15px |              1248px |

Notas:

- **Laptop fullscreen**: el NUI cubre el viewport completo del navegador CEF. Se asume que FiveM oculta el HUD nativo cuando la UI tiene focus.
- **Tablet overlay**: el NUI se renderiza como ventana centrada de 1280 × 800 sobre el juego activo. El resto del viewport queda transparente (canvas FiveM visible).
- Ambos viewports comparten paleta, tipografía y componentes; solo cambian densidad de grid, font-size root y dimensiones de chrome (top-bar/sidebar).

### 6.2 Resoluciones no-target

- < 1280 × 800: degrade graceful — la Tablet usa `width: min(1280px, 100vw)` + `height: min(800px, 100vh)`. Si el viewport es menor, se ajusta y el contenido scrollea verticalmente.
- > 1920 × 1080: el container `max-width` (1440px Laptop, 1248px Tablet) evita que el contenido se estire. El fondo `--fs-bg` rellena el sobrante.
- 4K (3840 × 2160): se renderiza centrado dentro del max-width. Tipografía no escala (lectura óptima a 16-18px).

### 6.3 Safe areas frente al HUD FiveM

Cuando la NUI es overlay (Tablet), reservar 16px de padding interno mínimo en los bordes para evitar tocar el HUD del juego que pueda asomar por debajo. El Laptop, al ser fullscreen, no necesita safe areas.

---

## 7. Spacing scale

Escala única firmada, base 4px. Todos los componentes consumen estos tokens; no se usan valores arbitrarios (`p-[13px]`, `gap-[27px]`, etc.).

| Token             | rem     | Px @16 root | Uso típico                                  |
| ----------------- | ------- | ----------: | ------------------------------------------- |
| `--spacing-fs-1`  | 0.25rem |         4px | Hairline gaps, inline icon spacing.         |
| `--spacing-fs-2`  | 0.5rem  |         8px | Padding interno de chips/badges.            |
| `--spacing-fs-3`  | 0.75rem |        12px | Gap entre icon + texto en botón.            |
| `--spacing-fs-4`  | 1rem    |        16px | **Bento gap canónico**. Padding compacto.   |
| `--spacing-fs-6`  | 1.5rem  |        24px | **Padding card comfortable**.               |
| `--spacing-fs-8`  | 2rem    |        32px | Gap entre secciones dentro de una page.     |
| `--spacing-fs-12` | 3rem    |        48px | Padding vertical de hero/dashboard heading. |
| `--spacing-fs-16` | 4rem    |        64px | **Altura del top-bar Manager** (§12).       |

Reglas:

- Valores intermedios (5, 10, 14...) están prohibidos salvo ADR.
- Para componentes de chrome (top-bar, sidebar), usar tokens nominativos (`--fs-topbar-h-manager: 64px;`) no los `--spacing-*` directamente, para legibilidad.

---

## 8. Iconografía

### 8.1 Librería firmada: Lucide React

`lucide-react` es la **única librería de iconos** permitida en Farm Sonar.

Razones:

- Tree-shaking nativo (imports nombrados generan bundles pequeños).
- Stroke-based, ajustable, encaja con el tono Calm-Tech.
- ~1500 iconos, cubre todo el catálogo agrícola/financiero/UI.
- API React nativa, sin wrapper extra.

Queda prohibido:

- Emoji en UI.
- SVG inline en JSX (mantenibilidad cero).
- Otras librerías de iconos (FontAwesome, Heroicons, Material Icons, etc.).
- Imports tipo `import * as Icons from 'lucide-react'` (rompe tree-shaking).

Forma canónica de import:

```tsx
import { LayoutDashboard, Sprout, Package } from 'lucide-react';
```

### 8.2 Escala de tamaños firmada

| Tamaño | Px  | Uso                                          |
| ------ | --- | -------------------------------------------- |
| xs     | 12  | Inline metadata (timestamps, hints).         |
| sm     | 16  | Default body, badges, chips.                 |
| md     | 20  | Buttons, nav items.                          |
| lg     | 24  | Section headers, KPI accents.                |
| xl     | 32  | Hero icons, empty/error state illustrations. |

### 8.3 Stroke-width canónico

`stroke-width: 1.5` para todos los iconos por defecto. El default de Lucide es 2 (más pesado). 1.5 lee como Calm-Tech.

Wrapper `<Icon>` (firmado en §10) aplica el stroke-width automáticamente.

### 8.4 Color

- Iconos heredan `currentColor` por defecto.
- Iconos activos en nav: `text-fs-accent`.
- Iconos inactivos: `text-fs-fg-muted`.
- Iconos en status badges: heredan el `fg` del status (success/warning/danger/info).

### 8.5 Catálogo inicial sugerido por app

| App        | Icono Lucide              |
| ---------- | ------------------------- |
| Dashboard  | `LayoutDashboard`         |
| Plots      | `Sprout`                  |
| Batches    | `Package`                 |
| Market     | `Store`                   |
| Contracts  | `FileSignature`           |
| Personnel  | `Users`                   |
| Finance    | `Wallet`                  |
| Log        | `ScrollText`              |
| Tasks      | `ListChecks`              |
| Messages   | `MessageSquare`           |
| Close      | `X`                       |
| Search     | `Search`                  |
| Filter     | `SlidersHorizontal`       |
| Add/Create | `Plus`                    |
| Loading    | `LoaderCircle` (spin CSS) |
| Empty      | `Inbox` (xl, muted)       |
| Error      | `TriangleAlert`           |

---

## 9. Catálogo shadcn/ui v1

Política YAGNI estricta: solo se instalan componentes necesarios para las Fases 1 y 2.

**Nota S4**: en S4 no se instala `shadcn-cli`. Los primitivos se implementan localmente con estilo shadcn-compatible (clases Tailwind + tokens v2). Cuando un slice futuro (S19, S26) necesite primitivos más sofisticados (Tabs, DropdownMenu, Select complejos), se puede instalar `shadcn-cli` y migrar los locales gradualmente sin ruptura visual.

### 9.1 Componentes aprobados (cuando se instale shadcn)

| Componente         | Uso esperado                                      |
| ------------------ | ------------------------------------------------- |
| `Card`             | Base de Bento cards (S4 lo implementa local).     |
| `Button`           | Acciones primarias/secundarias/ghost/destructive. |
| `Badge`            | Estados, calidad, tags.                           |
| `Dialog`           | Confirmaciones y acciones importantes.            |
| `Tabs`             | Apps o secciones con navegación local.            |
| `Toast` / `sonner` | Feedback transitorio.                             |
| `Skeleton`         | Loading states (S4 lo implementa local).          |
| `Progress`         | Progreso de cosecha, contratos, readiness.        |
| `Tooltip`          | Metadata compacta, lineage hints.                 |
| `DropdownMenu`     | Acciones secundarias.                             |
| `Select`           | Filtros simples.                                  |
| `Input`            | Búsqueda o edición simple.                        |

### 9.2 En reserva

No se instalan hasta que el slice lo exija:

- `Form` + Zod.
- `Table`.
- Date pickers.
- Calendar.
- Data grid pesado.

### 9.3 Componentes restringidos

`Carousel` y `Accordion` solo se usan si no existe alternativa mejor dentro del paradigma Bento.

Por defecto, si alguien propone carousel para esconder contenido, se rediseña la composición.

---

## 10. Signature components (APIs firmadas)

Estos componentes definen la identidad Farm Sonar. APIs firmadas en v2 para que S4 los implemente sin ambigüedad y slices posteriores los consuman sin cambios disruptivos.

### 10.1 `<BentoGrid>` y `<BentoGrid.Item>`

```tsx
<BentoGrid gap="md" columns={12}>
  <BentoGrid.Item span={4}>
    <Card>...</Card>
  </BentoGrid.Item>
  <BentoGrid.Item span={{ laptop: 8, tablet: 4 }}>
    <Card>...</Card>
  </BentoGrid.Item>
</BentoGrid>
```

| Prop      | Tipo                                            | Default | Notas                                  |
| --------- | ----------------------------------------------- | ------- | -------------------------------------- |
| `gap`     | `'sm'\|'md'\|'lg'`                              | `'md'`  | sm=8, md=16 (canónico), lg=24.         |
| `columns` | `8 \| 12`                                       | `12`    | 8 para Tablet, 12 para Laptop.         |
| `span`    | `number \| { laptop: number; tablet: number; }` | `12`    | Permite spans responsive por viewport. |

### 10.2 `<Card>`

Card primitiva flat minimalista (per ADR-006).

```tsx
<Card padding="comfortable" interactive={false}>
  <Card.Header>
    <Heading level="h2">Title</Heading>
  </Card.Header>
  <Card.Body>
    <Body>Content</Body>
  </Card.Body>
  <Card.Footer>...</Card.Footer>
</Card>
```

| Prop          | Tipo                                 | Default         | Notas                               |
| ------------- | ------------------------------------ | --------------- | ----------------------------------- |
| `padding`     | `'compact' \| 'comfortable' \| 'lg'` | `'comfortable'` | 16 / 24 / 32.                       |
| `interactive` | `boolean`                            | `false`         | Si true, añade focus ring + cursor. |

`Card.Header`, `Card.Body`, `Card.Footer` son compound components opcionales (slots).

### 10.3 `<BatchChip>`

Muestra `batch_id` en mono con dot de estado.

```tsx
<BatchChip batchId="b_8f3a..." quality="A" freshness={87} />
```

| Prop        | Tipo                             | Default | Notas                                              |
| ----------- | -------------------------------- | ------- | -------------------------------------------------- |
| `batchId`   | `string`                         | —       | Se muestra truncado (primeros 8 chars + ellipsis). |
| `quality`   | `'S'\|'A'\|'B'\|'C'\|'D'\| null` | `null`  | Color del chip según §2.4.                         |
| `freshness` | `number` (0-100)                 | `null`  | Opcional. Si <30 → tooltip de warning.             |
| `onClick`   | `() => void`                     | —       | Opcional. Si presente, chip es interactivo.        |

Renderiza: `[Dot quality color] [b_8f3a...]` en `text-fs-mono`.

### 10.4 `<LimePulse>`

Punto lima con pulso sutil (CSS keyframes, no Framer).

```tsx
<LimePulse size="md" label="Harvest ready" />
```

| Prop    | Tipo                   | Default | Notas                      |
| ------- | ---------------------- | ------- | -------------------------- |
| `size`  | `'sm' \| 'md' \| 'lg'` | `'md'`  | sm=8, md=12, lg=16 (px).   |
| `label` | `string`               | —       | Opcional, accessible name. |

Regla: respeta `prefers-reduced-motion` → si activo, el dot NO pulsa (queda estático en color accent).

### 10.5 `<Heading>` / `<Body>` / `<Mono>`

```tsx
<Heading level="h1">Page title</Heading>
<Body size="default">Body text</Body>
<Body size="small">Caption</Body>
<Mono>b_8f3a4e2c</Mono>
```

| Componente | Props clave                          | Notas                                                   |
| ---------- | ------------------------------------ | ------------------------------------------------------- |
| `Heading`  | `level: 'display'\|'h1'\|'h2'\|'h3'` | Mapea a escala §4.2.                                    |
| `Body`     | `size: 'default'\|'small'\|'micro'`  | Mapea a `text-fs-body`/`text-fs-small`/`text-fs-micro`. |
| `Mono`     | `size?: 'default'\|'small'`          | Force `font-family: var(--font-mono)`.                  |

### 10.6 `<Button>`

Primitivo local. shadcn-compatible para migración futura.

```tsx
<Button variant="primary" size="md" onClick={...}>Sign contract</Button>
<Button variant="ghost" size="sm" leftIcon={<Plus size={16} />}>Add</Button>
```

| Prop        | Tipo                                             | Default     | Notas                                     |
| ----------- | ------------------------------------------------ | ----------- | ----------------------------------------- |
| `variant`   | `'primary'\|'secondary'\|'ghost'\|'destructive'` | `'primary'` | Primary = lima, secondary = outline.      |
| `size`      | `'sm'\|'md'\|'lg'`                               | `'md'`      | sm=32, md=40, lg=48 (height px).          |
| `leftIcon`  | `ReactNode`                                      | —           | Lucide icon a la izquierda.               |
| `rightIcon` | `ReactNode`                                      | —           | Lucide icon a la derecha.                 |
| `disabled`  | `boolean`                                        | `false`     | Aplica opacity 0.5 + cursor not-allowed.  |
| `loading`   | `boolean`                                        | `false`     | Reemplaza children por LoaderCircle spin. |

### 10.7 `<Icon>`

Wrapper sobre lucide-react que aplica stroke-width canónico.

```tsx
<Icon as={LayoutDashboard} size="md" />
```

| Prop    | Tipo                           | Default | Notas                                |
| ------- | ------------------------------ | ------- | ------------------------------------ |
| `as`    | `LucideIcon`                   | —       | Componente Lucide importado.         |
| `size`  | `'xs'\|'sm'\|'md'\|'lg'\|'xl'` | `'sm'`  | Mapea a §8.2.                        |
| `color` | `string \| undefined`          | —       | Override opcional; default heredado. |

### 10.8 `<Skeleton>`

Loading state primitivo.

```tsx
<Skeleton variant="text" lines={3} />
<Skeleton variant="card" />
<Skeleton variant="circle" size="lg" />
```

| Prop      | Tipo                               | Default  | Notas                  |
| --------- | ---------------------------------- | -------- | ---------------------- |
| `variant` | `'text'\|'card'\|'circle'\|'rect'` | `'text'` | Forma base.            |
| `lines`   | `number`                           | `1`      | Para variant='text'.   |
| `size`    | `'sm'\|'md'\|'lg'`                 | `'md'`   | Para variant='circle'. |

CSS animation: `--fs-skeleton-pulse` (shimmer sutil, 1.5s ease-in-out infinite). Respeta `prefers-reduced-motion` (queda estático).

### 10.9 `<EmptyState>` / `<ErrorState>`

```tsx
<EmptyState
  icon={<Inbox size={32} />}
  title={t('state.empty.title')}
  body={t('state.empty.body')}
  action={{ label: t('state.empty.cta'), onClick: handleAdd }}
/>

<ErrorState
  icon={<TriangleAlert size={32} />}
  title={t('state.error.title')}
  body={String(error.message)}
  retry={() => refetch()}
/>
```

Reglas en §11.

### 10.10 Componentes descartados

`<GlassCard>` queda descartado por ADR-006.

No se debe recrear indirectamente con `backdrop-blur` o surfaces translúcidas salvo ADR futuro.

---

## 11. Estados — Loading / Empty / Error

Tres patrones canónicos firmados. Todo route placeholder y toda app debe implementar los tres.

### 11.1 Loading

- Usa `<Skeleton>` (§10.8), no spinners centrados (excepto en botones via `loading` prop).
- Skeletons replican la silueta del contenido final (cards con header + body + footer).
- Duración mínima de skeleton: 200ms (evita flashes). Si el fetch resuelve antes, no se muestra skeleton.
- Si fetch >2s sin resolver, opcional: añadir hint "Taking longer than expected…" en `text-fs-small text-fs-fg-muted`.

### 11.2 Empty

Composición canónica:

```
        ┌─────────────────┐
        │   [Icon xl]     │   Lucide, 32px, text-fs-fg-muted
        │                 │
        │  Heading h3     │   "Nothing here yet"
        │  Body default   │   "This area lights up when…"
        │                 │
        │  [Button ghost] │   Optional CTA, lima accent
        └─────────────────┘
```

- Icono Lucide siempre `text-fs-fg-muted`.
- Body suave, tono optimista, no apologético.
- CTA opcional; cuando existe, es `variant="ghost"` y abre el flujo de creación.

### 11.3 Error

Composición canónica:

```
        ┌─────────────────┐
        │ [TriangleAlert] │   Lucide, 32px, text-fs-danger-fg
        │                 │
        │  Heading h3     │   "Something went sideways"
        │  Body default   │   error.message (técnico OK si breve)
        │                 │
        │  [Button retry] │   "Try again", variant="secondary"
        └─────────────────┘
```

- Icono siempre con color danger (`text-fs-danger-fg`).
- El body puede incluir tecnicismos cortos, pero nunca un stack trace bruto.
- Retry CTA opcional pero recomendado.

---

## 12. Shell anatomy

Bible §15 firma dos surfaces: Manager (Laptop) y Field (Tablet). El v2 firma la anatomía de cada shell.

### 12.1 Manager shell (Laptop, 1920 × 1080)

```
┌────────────────────────────────────────────────────────────────────────┐
│ TopBar (64px)                                                          │
│ [Brand]  [Clock + Date]              [IBAN mono]  [Notif]  [Close X]   │
├──────────────┬─────────────────────────────────────────────────────────┤
│              │                                                         │
│ Sidebar      │  Content (Bento Grid 12 cols)                           │
│ (240px)      │  max-width: 1440px                                      │
│              │  padding: 32px                                          │
│ [Dashboard]  │  gap: 16px                                              │
│ [Plots]      │                                                         │
│ [Batches]    │  ┌────────┐ ┌────────┐ ┌────────┐                       │
│ [Market]     │  │ Card 1 │ │ Card 2 │ │ Card 3 │                       │
│ [Contracts]  │  └────────┘ └────────┘ └────────┘                       │
│ [Personnel]  │                                                         │
│ [Finance]    │                                                         │
│ [Log]        │                                                         │
│              │                                                         │
└──────────────┴─────────────────────────────────────────────────────────┘
```

| Slot    | Dimensión    | Token                            |
| ------- | ------------ | -------------------------------- |
| TopBar  | full × 64px  | `--fs-topbar-h-manager: 64px;`   |
| Sidebar | 240px × full | `--fs-sidebar-w-manager: 240px;` |
| Content | resto        | padding `--spacing-fs-8` (32px). |

Reglas:

- TopBar: fondo `--fs-nav` (negro), texto blanco, border-bottom transparente.
- Sidebar: fondo `--fs-surface` (blanco), nav items pill, item activo con `bg-fs-accent text-fs-fg`.
- Content area: fondo `--fs-bg` (menta), scroll vertical interno cuando excede viewport.

### 12.2 Tablet shell (overlay 1280 × 800)

```
┌──────────────────────────────────────────────────────────┐
│ TopBar (56px)                                            │
│ [Brand mini]  [Mode badge]              [Close X]        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Content (Bento Grid 8 cols)                             │
│  max-width: 1248px                                       │
│  padding: 24px                                           │
│  gap: 16px                                               │
│                                                          │
│  Tab nav inline (no sidebar):                            │
│  [Plots] [Tasks] [Messages]                              │
│                                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ KPI      │ │ KPI      │ │ KPI      │ │ KPI      │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

| Slot    | Dimensión         | Token                            |
| ------- | ----------------- | -------------------------------- |
| TopBar  | full × 56px       | `--fs-topbar-h-tablet: 56px;`    |
| Tab nav | inline en content | no token dedicado.               |
| Content | resto             | padding `--spacing-fs-6` (24px). |

Reglas:

- El overlay tiene `border-radius: 16px` y border 1px (`--fs-border`).
- Fondo del overlay: `--fs-bg` (menta), no transparente.
- Fuera del overlay: transparente (canvas FiveM visible).
- Sin sidebar — Tablet usa tab nav inline para navegación entre apps reducidas (Plots / Tasks / Messages).

---

## 13. Page templates

4 templates canónicos firmados. Toda app NUI usa uno de los 4.

### 13.1 DashboardPage (KPI bento)

```
┌─────────────────────────────────────────────────────┐
│ <Heading h1>{page.dashboard.title}</Heading>        │
│ <Body small text-muted>{page.dashboard.subtitle}    │
│                                                     │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ │ KPI 1    │ │ KPI 2    │ │ KPI 3    │ │ KPI 4    │ │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
│ ┌──────────────────────┐ ┌──────────────────────┐   │
│ │ Chart 30d (col-8)    │ │ Activity (col-4)     │   │
│ └──────────────────────┘ └──────────────────────┘   │
│ ┌─────────────────────────────────────────────────┐ │
│ │ Alerts (col-12)                                 │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

Slots:

- Header: H1 + subtitle.
- KPI row: 3-4 cards `col-span-3` o `col-span-4`.
- Detail row: charts + recent feed.
- Alerts row: full-width.

Uso típico: `/dashboard`, `/finance`.

### 13.2 ListPage (toolbar + lista)

```
┌─────────────────────────────────────────────────────┐
│ <Heading h1>{page.batches.title}</Heading>          │
│                                                     │
│ Toolbar: [Search] [Filter] [Sort]     [+ New]       │
│                                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ Item card 1                                     │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ Item card 2                                     │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ Item card 3                                     │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ Pagination:  ← 1 2 3 ... N →                        │
└─────────────────────────────────────────────────────┘
```

Slots:

- Header: H1.
- Toolbar: Search input + Filter dropdown + Sort dropdown + primary CTA (right-aligned).
- List: cards verticales con divisores (`--fs-border`).
- Pagination: bottom-centered si la lista lo requiere.

Uso típico: `/plots`, `/batches`, `/contracts`, `/personnel`, `/log`, `/messages`.

### 13.3 DetailPage (header + secciones)

```
┌─────────────────────────────────────────────────────┐
│ ← Back                                              │
│                                                     │
│ <Heading h1>Batch b_8f3a...</Heading>               │
│ <BatchChip /> <Badge quality />                     │
│                                                     │
│ ─── Origin ────────────────────────────────────     │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐              │
│ │ Plot     │ │ Player   │ │ Date     │              │
│ └──────────┘ └──────────┘ └──────────┘              │
│                                                     │
│ ─── Lineage ──────────────────────────────────      │
│ [BatchChip] → [BatchChip] → [BatchChip]             │
│                                                     │
│ ─── Quality breakdown ────────────────────────      │
│ Soil 78 / Irrigation 82 / Pest 95 / ...             │
└─────────────────────────────────────────────────────┘
```

Slots:

- Back link (top-left).
- Header: H1 + chips/badges identificativos.
- Sections con divider + H2 + body.

Uso típico: detalle de un batch, de un contrato, de un empleado.

### 13.4 EmptyPage (placeholder vacío)

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                                                     │
│                  [Icon xl muted]                    │
│                                                     │
│                  Heading h2                         │
│                  Body default muted                 │
│                                                     │
│                  [Button ghost]                     │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Slots: ver §11.2 Empty.

Uso típico: en S4, todas las routes excepto `/dashboard` arrancan como EmptyPage hasta que su slice las implementa.

### 13.5 Notas operativas para el router

- El **AppRouter** del NUI usa **MemoryRouter** (no HashRouter ni BrowserRouter). Razón: CEF no muestra URL al jugador y no necesita back/forward del navegador. MemoryRouter mantiene el estado de ruta en memoria, no contamina el history del CEF FiveM. Decisión firmada por el founder durante la sesión PM v2.
- Route catalog firmado en S4: `/dashboard`, `/plots`, `/batches`, `/market`, `/contracts`, `/personnel`, `/finance`, `/log`, `/tasks`, `/messages`.
- Cada route declara su `mode` permitido (`'manager' | 'field' | 'both'`); el shell renderiza la ruta solo si coincide con el mode activo.

---

## 14. Motion canon

### 14.1 Strategy v2: Hybrid staged

- **S4 y slices Fase 0-1**: solo CSS transitions y CSS keyframes. Sin Framer Motion. Las animaciones son sutiles, calm, contenidas.
- **Slices Fase 2+ (S19 / S26 / S28+)**: Framer Motion 11 puede activarse cuando una app concreta lo justifique (charts animados, drone scaleform, transición de vistas). La decisión de activar Framer se toma por slice, no globalmente.

Razón: Bible §1 lista Framer en el stack disponible, pero v2 difiere su instalación hasta tener apps que la necesiten. Mantiene el bundle ligero en Fase 0.

### 14.2 Durations firmadas

| Token                | Valor | Uso                                               |
| -------------------- | ----- | ------------------------------------------------- |
| `--duration-fs-fast` | 150ms | Hover, focus ring, color transitions.             |
| `--duration-fs-base` | 250ms | Entrada/salida de modales, fade-in de contenido.  |
| `--duration-fs-slow` | 400ms | Layout shifts, page transitions (cuando aplique). |

### 14.3 Easings firmadas

| Token              | Curva                            | Uso                                |
| ------------------ | -------------------------------- | ---------------------------------- |
| `--ease-out-fs`    | `cubic-bezier(0.22, 1, 0.36, 1)` | Default. Out (decelera al llegar). |
| `--ease-in-out-fs` | `cubic-bezier(0.65, 0, 0.35, 1)` | Reservado para layout shifts.      |

### 14.4 Presets CSS firmados (S4 implementa)

| Preset         | Definición                                                | Uso                                  |
| -------------- | --------------------------------------------------------- | ------------------------------------ |
| `.fs-fade-in`  | `opacity 0→1` en `--duration-fs-base` con `--ease-out-fs` | Aparición de cards, modales.         |
| `.fs-slide-up` | `translateY(8px)→0 + opacity 0→1` en `--duration-fs-base` | Entrada de páginas.                  |
| `.fs-pulse`    | keyframes opacity+scale (ya en globals.css desde S0).     | LimePulse dot, harvest-ready badges. |
| `.fs-skeleton` | keyframes shimmer (background-position 0%→200%).          | Skeleton primitivo.                  |

### 14.5 Prefers-reduced-motion

**Obligatorio respetar `prefers-reduced-motion: reduce`** en TODOS los presets:

```css
@media (prefers-reduced-motion: reduce) {
  .fs-fade-in,
  .fs-slide-up,
  .fs-pulse,
  .fs-skeleton {
    animation: none !important;
    transition: none !important;
  }
}
```

LimePulse, Skeleton y demás señalan presencia con color/opacidad estática cuando se reducen las animaciones.

### 14.6 Anti-patrones de motion

- Bouncy springs (overshoot >5%): rompen el tono Calm-Tech.
- Easings linear: industriales/baratos.
- Durations >500ms: aburren al usuario.
- Animaciones permanentes en multiples elementos (>2 LimePulse en pantalla simultáneos).

---

## 15. Accesibilidad

### 15.1 Filosofía

Pragmatic AA. La NUI no es una web pública, pero debe ser legible y operable para jugadores con visión limitada, daltonismo o sensibilidad al movimiento. AAA es opcional; AA es mínimo.

### 15.2 Contrast ratios

- Texto sobre `--fs-bg` (#D9EAE3): usar `--fs-fg` (#050505) → ratio ~13.5:1. AAA.
- Texto sobre `--fs-surface` (#FFFFFF): usar `--fs-fg` → ratio ~20:1. AAA.
- Texto sobre `--fs-nav` (#050505): usar `#FFFFFF` → ratio ~20:1. AAA.
- Texto muted (`--fs-fg-muted` #969C9C) sobre surface: ratio ~3.3:1. **Solo válido para texto >18px o bold**, no para body small.
- Texto sobre status backgrounds: cada par §2.3 verificado AA (≥4.5:1).

### 15.3 Focus ring canónico

Toda interacción (botones, links, inputs, tabs, cards interactive) DEBE tener focus visible:

```css
:focus-visible {
  outline: 2px solid var(--color-fs-focus);
  outline-offset: 2px;
  border-radius: inherit;
}
```

- Color: `--fs-focus` (= `--fs-accent`, lima Calm-Tech).
- Grosor: 2px.
- Offset: 2px (separa del componente, evita confusión con borde).
- Nunca usar `outline: none` sin reemplazo equivalente.

### 15.4 ARIA en componentes interactivos clave

| Componente   | Atributo aria mínimo                                        |
| ------------ | ----------------------------------------------------------- |
| `Button`     | `aria-label` si el botón solo tiene icono.                  |
| `Tabs`       | `role="tablist"` + `role="tab"` + `aria-selected`.          |
| `Dialog`     | `role="dialog"` + `aria-labelledby` + focus trap.           |
| `IconButton` | `aria-label` SIEMPRE (no hay texto visible).                |
| `LimePulse`  | `aria-label` si tiene significado semántico (e.g., "Live"). |
| `Skeleton`   | `aria-busy="true"` en el contenedor.                        |

### 15.5 Prefers-contrast

Opcional, pero recomendado:

```css
@media (prefers-contrast: more) {
  :root {
    --fs-border: rgb(150 156 156 / 0.5); /* border más visible */
  }
}
```

### 15.6 Anti-patrones a11y

- `outline: none` sin reemplazo.
- Color solo como señal (e.g., calidad solo por color sin letra S/A/B/C/D).
- Texto <14px sin justificación.
- Hover-only para acciones críticas (operar con teclado/tap debe ser igual de viable).

---

## 16. Data viz tokens

Stack incluye Recharts (Bible §9.1). Slices S20, S26, S31 dependerán de él. El v2 firma tokens, no tipos de chart.

### 16.1 Paleta de series

| Slot    | Color hex | Uso                             |
| ------- | --------- | ------------------------------- |
| Serie 1 | `#B6FB63` | Serie primaria, dato central.   |
| Serie 2 | `#050505` | Serie comparativa principal.    |
| Serie 3 | `#969C9C` | Serie secundaria muted.         |
| Serie 4 | `#C4C8C8` | Serie tertiaria, fondo.         |
| Serie 5 | `#E0E3E3` | Background banda, low priority. |

Regla: **NUNCA usar colores arcoiris** ni paletas categóricas saturadas. La escala de grises (#050505 → #969C9C → #C4C8C8 → #E0E3E3) + el lima cubren cualquier serie comparativa. Status colors (§2.3) pueden usarse para resaltar valores específicos (e.g., barras danger para precios mínimos), no como serie completa.

### 16.2 Grid + axis tokens

| Token             | Valor           | Uso                          |
| ----------------- | --------------- | ---------------------------- |
| `--fs-chart-grid` | `--fs-border`   | Líneas de grid horizontales. |
| `--fs-chart-axis` | `--fs-fg-muted` | Color de ejes y labels.      |

Axis labels: `text-fs-micro` peso 500.
Tick labels: `text-fs-mono` peso 400 (números) o `text-fs-micro` (categorías).

### 16.3 Tooltip surface

- Background: `--fs-surface` (#FFFFFF) flat.
- Border: 1px `--fs-border`.
- Shadow: none (consistente con cards).
- Padding: `--spacing-fs-3` (12px).
- Texto: `text-fs-small` peso 500.

### 16.4 Estados de chart

- Loading: usar `<Skeleton variant="rect" />` con la altura del chart.
- Empty: usar `<EmptyState>` con icono `BarChart3` xl muted.
- Error: usar `<ErrorState>` con retry CTA.

### 16.5 Tipos de chart firmados (diferido)

Se difiere a S20 (Market histórico). Cuando se firmen, vivirán aquí. Hasta entonces, cada slice consume tokens §16.1-16.4 sin asumir tipos canónicos.

---

## 17. Sound moments — TBD controlado

Sound design NO se firma en v2. Se documentan candidatos para slices futuros:

| Momento               | Slice probable | Dirección                          |
| --------------------- | -------------- | ---------------------------------- |
| Banca / transferencia | S3 (DONE)      | Click financiero sutil, no casino. |
| Drone                 | S28+           | Whoosh tecnológico suave.          |
| Cosecha ready         | S6             | Confirmación orgánica, corta.      |
| Harvest success       | S6             | Recompensa ligera, no arcade.      |

Regla: ningún sonido se añade sin toggle en config y sin respetar UX in-game.

---

## 18. Proceso v0.dev

El proceso operativo sigue `03_AI_PLAYBOOK.md §3` y `Bible §16`.

### 18.1 Antes de pedir diseño a v0.dev

El prompt debe incluir (v2 enriquecido):

- Paleta exacta §2 (surface + status + quality).
- Flat minimalista por ADR-006.
- Geist Sans + JetBrains Mono.
- Escala tipográfica §4.2.
- Escala spacing §7.
- Bento gap 16px, radius rounded-2xl, densidad comfortable.
- Viewports §6 (Laptop 1920×1080 fullscreen / Tablet 1280×800 overlay).
- Lucide React con escala §8.2 y stroke 1.5 (no emoji, no SVG inline).
- shadcn/ui catalog permitido §9.
- Signature components §10 firmados.
- Restricción: no Glassmorphism, no dark default, no colores secundarios saturados.
- Router: MemoryRouter (no HashRouter, no BrowserRouter).
- Motion: CSS-only para v2, sin Framer Motion salvo aprobación.

### 18.2 Prompt base actualizado para v0.dev

```text
Design a premium agritech SaaS dashboard for Farm Sonar, a FiveM farming simulation product.

Visual canon (UI Playbook v2):
- AgriSphere-inspired Light Mode, Calm-Tech, iPad-like.
- Background #D9EAE3 mint.
- Surface cards #FFFFFF, flat, no shadow, 1px subtle border #969C9C/20, rounded-2xl.
- Navigation / sidebar #050505 near-black.
- Single accent #B6FB63 lime Calm-Tech (CTA, success, focus ring).
- Muted text #969C9C.
- Status pastel pairs: success #E8F7E0/#2F6B1F, warning #FFF4D6/#7A5200, danger #FDE3E3/#8A1F1F, info #E3EEF9/#1F3F6B.
- Geist Sans for UI, JetBrains Mono for IDs/IBAN/timestamps.
- Font weights only 400/500/600.
- Bento grid 16px gap, 12 cols Laptop or 8 cols Tablet, comfortable density.
- Lucide React icons stroke 1.5, scale 12/16/20/24/32.
- Targets: Laptop fullscreen 1920×1080, Tablet overlay 1280×800.

Components allowed (shadcn-compatible):
Card, Button, Badge, Dialog, Tabs, Toast, Skeleton, Progress, Tooltip, DropdownMenu, Select, Input.
Signature: BentoGrid, BentoGrid.Item, BatchChip, LimePulse, Icon.

Avoid:
- Dark mode as default.
- Glassmorphism / backdrop-blur.
- Heavy shadows.
- Admin-panel compression.
- Neon colors other than #B6FB63.
- Emoji in UI.
- Carousel unless absolutely necessary.

Output React + Tailwind v4 compatible structure. Use t('key.path') placeholders for user-facing strings (i18n).
```

### 18.3 Review checklist antes de implementar

Antes de traer código de v0.dev al repo, revisar:

- ¿Respeta la paleta exacta (surface + status + quality)?
- ¿Respeta la escala tipográfica y de spacing?
- ¿Usa Lucide React con stroke 1.5, sin emoji ni SVG inline?
- ¿No usa glass/blur/shadow pesada?
- ¿Usa solo componentes aprobados?
- ¿No hardcodea strings finales sin plan i18n (`t('key.path')`)?
- ¿Mantiene density comfortable?
- ¿El lima aparece solo como acento?
- ¿La UI se entiende a primera vista en viewport in-game?
- ¿Incluye estados loading / empty / error per §11?
- ¿Respeta focus ring lima §15.3?
- ¿No introduce dependencias no aprobadas?

Si falla 2 o más checks, se regenera el diseño en v0.dev antes de implementar.

---

## 19. Implementación en React / Tailwind

### 19.1 Tokens

Los tokens v2 viven (o vivirán) en:

- [sonar_farm_tablet/web/src/styles/theme.css](sonar_farm_tablet/web/src/styles/theme.css).

Estado actual:

- **Ya presentes** (firmados desde v1 / S0): surface (`--color-fs-bg`, `--color-fs-surface`, `--color-fs-nav`, `--color-fs-fg`, `--color-fs-fg-muted`, `--color-fs-border`), accent (`--color-fs-accent`, `--color-fs-accent-hover`), quality tiers (`--color-fs-quality-s/a/b/c/d`), motion (`--ease-out-fs`, `--duration-fs-fast/base/slow`), radii (`--radius-fs-sm/md/lg/xl`), shadows (`--shadow-fs-card`, `--shadow-fs-glow`).
- **Pendientes de cablear en S4 Fase B**: pares status `-bg`/`-fg` exactos §2.3, spacing scale `--spacing-fs-1..16` §7, focus token `--color-fs-focus`, presets de motion CSS `.fs-fade-in` / `.fs-slide-up` / `.fs-skeleton` §14.4, query `prefers-reduced-motion` §14.5, query `prefers-contrast` §15.5.

No duplicar hex en componentes salvo prototipo temporal aprobado. Los tokens status `--color-fs-success/warning/danger/info` existentes desde v1 se mantienen como aliases del par `-bg` durante la migración S4, sin romper código previo.

### 19.2 Strings (i18n)

Regla de i18n del proyecto (`.windsurf/rules/03_languages.md`):

- Nunca hardcodear strings user-facing finales.
- React: `t('key.path')` (hook minimal o react-i18next según slice).
- Locales: `sonar_farm_tablet/web/src/locales/en.json` + `es.json`, fallback `en`.
- Si el slice aún no tiene i18n React, el mini-brief debe declarar cómo se extraerán antes del cierre.

### 19.3 Router NUI

- **MemoryRouter** de `react-router-dom` v6 (no HashRouter, no BrowserRouter).
- CEF no muestra URL ni necesita back/forward.
- Route catalog en `sonar_farm_tablet/web/src/router/routes.ts` con `path`, `mode` permitido, `element`.

### 19.4 Estilo de componentes

Preferir:

- Props simples, tipadas estricto.
- Variants claras (no boolean flags acumulables).
- Composición shadcn-compatible.
- Tokens CSS (`bg-fs-surface`, `text-fs-accent`).
- Componentes pequeños y compuestos (Card.Header / Card.Body / Card.Footer).

Evitar:

- Mega components con 20+ props.
- Lógica de negocio en UI (mover a hooks).
- Direct calls a FiveM desde componentes profundos (siempre via `lib/nui.ts`).
- Hardcoded magic numbers fuera de tokens/config.
- Estado global en Context si solo lo usa un subárbol pequeño (local primero).

---

## 20. DoD visual para slices con UI

Un slice con UI **no puede cerrarse** si:

- Rompe la paleta del Bible §1.1 o de v2 §2.
- Introduce dark mode por defecto.
- Usa glassmorphism / backdrop-blur sin ADR.
- Usa un componente shadcn no aprobado sin justificarlo.
- Mete un color saturado secundario.
- Usa pesos 700+.
- Comprime la UI en contra de density comfortable.
- Deja strings user-facing sin ruta de i18n.
- No documenta smoke visual en el mini-brief.
- Rompe el viewport target (Laptop 1920×1080 / Tablet 1280×800).
- Usa valores spacing arbitrarios fuera de la escala §7.
- Inyecta SVG inline o emoji en lugar de Lucide React.
- Omite focus ring lima §15.3 en interactivos.
- Omite estados loading / empty / error per §11.
- Rompe `prefers-reduced-motion` con animaciones forzadas.

---

## 21. Changelog

| Versión | Fecha      | Cambios                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.0** | 2026-05-19 | Primer UI Playbook básico/fundacional. Firma AgriSphere Light Mode, paleta hex final, Flat Minimalista por ADR-006, tipografía Geist/JetBrains, Bento geometry, shadcn/ui catalog v1, signature components (`BentoGrid`, `BatchChip`, `LimePulse`), proceso v0.dev y DoD visual. Responsive fino, motion, sound, componentes de datos avanzados y patrones de pantalla quedan TBD controlado para S4 o versiones futuras.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **2.0** | 2026-05-19 | Production canon AAA antes de S4. Reescritura completa cerrando todos los TBD de v1. Decisiones firmadas en sesión PM con founder: (1) Motion hybrid staged — CSS-only para S4, Framer Motion diferido. (2) Dos viewports firmados — Laptop 1920×1080 fullscreen + Tablet 1280×800 overlay centrado. (3) Status colors hex firmados con pares fondo+texto AA (#E8F7E0/#2F6B1F, #FFF4D6/#7A5200, #FDE3E3/#8A1F1F, #E3EEF9/#1F3F6B). (4) Iconografía firmada — Lucide React con escala 12/16/20/24/32, stroke-width 1.5, prohibido emoji y SVG inline. (5) Spacing scale 4px-base firmada (fs-1..fs-16). (6) Shell anatomy firmada — Manager (topbar 64px + sidebar 240px) + Tablet (topbar 56px overlay). (7) 4 page templates firmados — DashboardPage / ListPage / DetailPage / EmptyPage. (8) Escala tipográfica completa por viewport (display/h1/h2/h3/body/small/micro/mono). (9) Estados Loading/Empty/Error canónicos. (10) Accesibilidad pragmatic — AA contrast, focus ring lima 2px offset, aria en interactivos clave, prefers-reduced-motion respetado. (11) Data viz tokens — paleta de series escala de grises + lima, grid color, tooltip surface (tipos de chart diferidos a S20). (12) Router NUI — MemoryRouter (no HashRouter, evita contaminar history CEF). Signature components APIs firmadas: BentoGrid, BentoGrid.Item, Card, BatchChip, LimePulse, Heading, Body, Mono, Button, Icon, Skeleton, EmptyState, ErrorState. Sin cambios en producto canon (Bible §1, §15) ni ADRs nuevos; v2 expande lo que Bible delega al Playbook. |
