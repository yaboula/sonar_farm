# 🎨 Farm Sonar — UI Playbook

> **Estado:** v1.0 — Foundation UI canon  
> **Fecha:** 2026-05-19  
> **Fuente canónica:** `00_BIBLE.md §1.1` + `02_DECISIONS.md ADR-006`  
> **Scope:** identidad visual, paleta, tipografía, Bento system, componentes base, proceso v0.dev  
> **No scope v1:** motion canon completo, sound design final, componentes de apps futuras no necesarias todavía

---

## 0. Para qué existe este documento

Este documento convierte la identidad visual de Farm Sonar en reglas operables para Cascade, v0.dev, Opus y futuros sub-agents.

No sustituye al Bible. El orden de autoridad es:

1. `docs/00_BIBLE.md` — producto, pilares, identidad, anti-features. **Autoridad máxima.**
2. `docs/02_DECISIONS.md` — ADRs de decisiones no obvias. Para UI, ver **ADR-006**.
3. `docs/04_UI_PLAYBOOK.md` — cómo ejecutar la UI sin reinterpretar el canon.
4. Mini-brief del slice activo — scope puntual de implementación.

Si una decisión visual contradice el Bible, se debe parar y abrir ADR antes de programar.

---

## 1. Principio visual rector

Farm Sonar no debe parecer un script FiveM. Debe parecer un producto SaaS agritech premium incrustado en FiveM.

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

Justificación del descarte de glassmorphism: `ADR-006`.

---

## 2. Paleta canónica — AgriSphere Light Mode

Esta paleta está firmada en `00_BIBLE.md §1.1`.

| Token           |                     Hex | Uso                                               |
| --------------- | ----------------------: | ------------------------------------------------- |
| `--fs-bg`       |               `#D9EAE3` | Fondo principal. Menta/salvia claro.              |
| `--fs-surface`  |               `#FFFFFF` | Tarjetas, paneles, Bento cards. Blanco puro.      |
| `--fs-nav`      |               `#050505` | Menú principal, pills oscuras, contraste extremo. |
| `--fs-accent`   |               `#B6FB63` | Único acento. Lima Calm-Tech.                     |
| `--fs-fg`       |               `#050505` | Texto principal sobre superficies claras.         |
| `--fs-fg-muted` |               `#969C9C` | Texto secundario, labels, iconos inactivos.       |
| `--fs-border`   | `#969C9C` con alpha 20% | Bordes 1px ultra sutiles.                         |

### 2.1 Regla del acento único

`#B6FB63` es el único color saturado de identidad.

Se usa para:

- CTA principal.
- Estados positivos de alta importancia.
- Harvest ready.
- Calidad A/S.
- Indicadores de actividad.
- `<LimePulse>`.

No se añade acento secundario. Si una pantalla parece necesitar otro acento, primero se debe resolver con jerarquía, tamaño, spacing o contraste con `--fs-nav`.

### 2.2 Status colors

Los estados usan estilo pastel/translúcido. Nunca compiten visualmente con el lima.

| Estado  | Dirección visual                                           | Uso                                     |
| ------- | ---------------------------------------------------------- | --------------------------------------- |
| Success | Fondo verde pastel translúcido + texto verde oscuro        | Completado, OK, calidad buena.          |
| Warning | Fondo ámbar pastel translúcido + texto marrón/ámbar oscuro | Riesgo, cosecha tardía, plaga probable. |
| Danger  | Fondo rojo pastel translúcido + texto rojo oscuro          | Error, contrato roto, calidad D.        |
| Info    | Fondo gris/menta translúcido + texto oscuro                | Mensajes neutrales.                     |

Los hex exactos de status se pueden ajustar en v0.dev, pero deben cumplir:

- Contraste AA mínimo para texto.
- Saturación baja.
- Ningún status puede parecer más importante que `--fs-accent`.

---

## 3. Superficies y acabado

Decisión firmada por `ADR-006`:

> Farm Sonar usa **Flat Minimalista**, no Glassmorphism.

### 3.1 Cards

Las cards estándar son:

- Fondo: `#FFFFFF`.
- Sombra: `shadow-none`.
- Borde: 1px, `#969C9C` con alpha 20%.
- Radius: `rounded-2xl`.
- Padding: comfortable.

Queda prohibido por defecto:

- `backdrop-blur`.
- `bg-white/70` como superficie principal.
- Sombras grandes tipo dashboard template.
- Cards con fondos translúcidos sobre el menta.

### 3.2 Nav / Pill menu

El nav principal usa `#050505` para crear contraste extremo contra el background menta.

Debe sentirse como una cápsula premium:

- Fondo negro casi puro.
- Texto claro.
- Acento lima solo para estado activo o acción primaria.
- Radius alto.
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

Queda prohibido:

- `700+` salvo ADR futuro.
- Jerarquía basada en bold agresivo.
- Títulos enormes sin función.

La jerarquía visual se construye con:

- Tamaño.
- Whitespace.
- Contraste entre `--fs-surface` y `--fs-nav`.
- Ubicación dentro del Bento.
- Peso máximo `600`.

---

## 5. Bento System

El Bento Grid es el paradigma de layout firmado en `00_BIBLE.md §1`.

### 5.1 Regla de oro

La interfaz debe respirar. Farm Sonar no es un panel administrativo barato.

Queda prohibido comprimir iconos, KPIs y textos para meter "más cosas" en pantalla.

### 5.2 Geometría firmada

| Variable          | Valor firmado               |
| ----------------- | --------------------------- |
| Gap entre cards   | `16px`                      |
| Radius            | `16px–20px` (`rounded-2xl`) |
| Densidad          | Comfortable                 |
| Padding base card | Generoso, no compacto       |
| Estilo            | Calm-Tech / iPad-like       |

### 5.3 Layout

El layout debe preferir:

- Cards con propósito único.
- KPIs grandes y silenciosos.
- Agrupación por tareas, no por tablas gigantes.
- Grids de 12 columnas cuando la pantalla lo justifique.
- Composición asimétrica controlada.

Evitar:

- Tablas masivas antes de ser necesarias.
- Lists infinitas sin agrupación.
- Cards idénticas repetidas sin jerarquía.
- Microtextos apretados.

### 5.4 Densidad NUI

Target primario v1:

- Tablet/Laptop in-game.
- Viewport FiveM limitado.
- Legibilidad inmediata durante gameplay.

Responsive web/admin panel queda TBD para futuro. No se optimiza antes de necesitarlo.

---

## 6. Catálogo shadcn/ui v1

Política YAGNI estricta: solo se instalan componentes necesarios para Fases 1 y 2.

### 6.1 Componentes aprobados

| Componente         | Uso esperado                                      |
| ------------------ | ------------------------------------------------- |
| `Card`             | Base de Bento cards.                              |
| `Button`           | Acciones primarias/secundarias/ghost/destructive. |
| `Badge`            | Estados, calidad, tags.                           |
| `Dialog`           | Confirmaciones y acciones importantes.            |
| `Tabs`             | Apps o secciones con navegación local.            |
| `Toast` / `sonner` | Feedback transitorio.                             |
| `Skeleton`         | Loading states.                                   |
| `Progress`         | Progreso de cosecha, contratos, readiness.        |
| `Tooltip`          | Metadata compacta, lineage hints.                 |
| `DropdownMenu`     | Acciones secundarias.                             |
| `Select`           | Filtros simples.                                  |
| `Input`            | Búsqueda o edición simple.                        |

### 6.2 En reserva

No se instalan hasta que el slice lo exija:

- `Form` + Zod.
- `Table`.
- Date pickers.
- Calendar.
- Data grid pesado.

### 6.3 Componentes restringidos

`Carousel` y `Accordion` solo se usan si no existe alternativa mejor dentro del paradigma Bento.

Por defecto, si alguien propone carousel para esconder contenido, se rediseña la composición.

---

## 7. Signature Components Sonar

Estos componentes definen la identidad Farm Sonar. Se crean ad-hoc cuando el slice los necesite.

### 7.1 `<BentoGrid>` y `<BentoGrid.Item>`

Responsabilidad:

- Layout de cards.
- Gap 16px por defecto.
- API tipada.
- Soporte para spans controlados.

Dirección API esperada:

```tsx
<BentoGrid>
  <BentoGrid.Item span="lg:col-span-6">
    <Card>...</Card>
  </BentoGrid.Item>
</BentoGrid>
```

La API exacta se firma en S4 cuando se implemente el shell NUI.

### 7.2 `<BatchChip>`

Responsabilidad:

- Mostrar `batch_id` con JetBrains Mono.
- Incluir dot de estado pastel.
- Mostrar tooltip con origen/lineage.
- Mantener trazabilidad visible sin ocupar mucho espacio.

Usos futuros:

- Inventario de lotes.
- Contratos B2B.
- Storage.
- Quality reports.

### 7.3 `<LimePulse>`

Responsabilidad:

- Punto lima `#B6FB63` con pulso sutil.
- Indicar actividad, conexión, atención requerida o readiness.

API esperada:

```tsx
<LimePulse size="sm" />
<LimePulse size="md" />
<LimePulse size="lg" />
```

Regla: el pulso debe ser elegante, no arcade. Nada de parpadeos agresivos.

### 7.4 Componentes descartados

`<GlassCard>` queda descartado por ADR-006.

No se debe recrear indirectamente con `backdrop-blur` o surfaces translúcidas salvo ADR futuro.

---

## 8. Motion canon — TBD controlado

Motion NO se firma en v1 para evitar especulación.

Se definirá cuando exista UI real en S4 o cuando un slice lo requiera.

Dirección provisional:

- Micro-motion calm.
- Entradas suaves.
- Hover mínimo.
- Nada de animaciones arcade.
- `prefers-reduced-motion` respetado.

No se instala Framer Motion hasta que un slice lo justifique.

---

## 9. Sound moments — TBD controlado

Sound design NO se firma en v1.

Se documentan candidatos, pero no se implementan todavía:

| Momento               | Slice probable | Dirección                          |
| --------------------- | -------------- | ---------------------------------- |
| Banca / transferencia | S3             | Click financiero sutil, no casino. |
| Drone                 | Wave 2+        | Whoosh tecnológico suave.          |
| Cosecha ready         | Crop lifecycle | Confirmación orgánica, corta.      |
| Harvest success       | Harvest slice  | Recompensa ligera, no arcade.      |

Regla: ningún sonido se añade sin toggle/config y sin respetar UX in-game.

---

## 10. Proceso v0.dev

El proceso operativo sigue `03_AI_PLAYBOOK.md §3` y `Bible §16`.

### 10.1 Antes de pedir diseño a v0.dev

El prompt debe incluir:

- Paleta exacta de `Bible §1.1`.
- Flat minimalista por ADR-006.
- Geist Sans + JetBrains Mono.
- Bento gap 16px.
- Radius rounded-2xl.
- Densidad comfortable.
- shadcn/ui catalog permitido.
- Componentes signature vivos.
- Restricción: no Glassmorphism.
- Restricción: no dark mode por defecto.
- Restricción: no colores secundarios saturados.

### 10.2 Prompt base para v0.dev

```text
Design a premium agritech SaaS dashboard for Farm Sonar, a FiveM farming simulation product.

Visual canon:
- AgriSphere-inspired light mode.
- Background #D9EAE3.
- Surface cards #FFFFFF, flat, no shadow, 1px subtle border #969C9C/20.
- Navigation / pill menu #050505.
- Single accent #B6FB63 lime Calm-Tech.
- Muted text #969C9C.
- Geist Sans for UI, JetBrains Mono for IDs/financial/metadata.
- Font weights only 400/500/600.
- Bento grid layout, 16px gap, rounded-2xl cards, comfortable density.
- Use shadcn/ui components only when needed: Card, Button, Badge, Dialog, Tabs, Toast, Skeleton, Progress, Tooltip, DropdownMenu, Select, Input.
- Signature components: BentoGrid, BatchChip, LimePulse.

Avoid:
- Dark mode as default.
- Glassmorphism.
- Heavy shadows.
- Admin-panel compression.
- Neon colors other than #B6FB63.
- Carousel unless absolutely necessary.

Output React + Tailwind v4 compatible structure. Keep user-facing strings ready for i18n extraction.
```

### 10.3 Review checklist antes de implementar

Antes de traer código de v0.dev al repo, revisar:

- ¿Respeta la paleta exacta?
- ¿No usa glass/blur/shadow pesada?
- ¿Usa solo componentes aprobados?
- ¿No hardcodea strings finales sin plan i18n?
- ¿Mantiene density comfortable?
- ¿El lima aparece solo como acento?
- ¿La UI se entiende a primera vista en viewport in-game?
- ¿No introduce dependencias no aprobadas?

Si falla 2 o más checks, se regenera el diseño en v0.dev antes de implementar.

---

## 11. Implementación en React/Tailwind

### 11.1 Tokens

Los tokens viven en:

- `sonar_farm_tablet/web/src/styles/theme.css`

No duplicar hex en componentes salvo prototipo temporal aprobado.

### 11.2 Strings

Regla de i18n del proyecto:

- Nunca hardcodear strings user-facing finales.
- React debe usar `t('key.path')` cuando i18n esté instalado.
- Si el slice aún no tiene i18n React, el mini-brief debe declarar cómo se extraerán antes del cierre.

### 11.3 Estilo de componentes

Preferir:

- Props simples.
- Variants claras.
- Composición shadcn/ui.
- Tokens CSS.
- Componentes pequeños.

Evitar:

- Mega components.
- Lógica de negocio en UI.
- Direct calls a FiveM desde componentes profundos.
- Hardcoded magic numbers fuera de tokens/config.

---

## 12. DoD visual para slices con UI

Un slice con UI no puede cerrarse si:

- Rompe la paleta del Bible §1.1.
- Introduce dark mode por defecto.
- Usa glassmorphism sin ADR.
- Usa un componente shadcn no aprobado sin justificarlo.
- Mete un color saturado secundario.
- Usa pesos 700+.
- Comprime la UI en contra de density comfortable.
- Deja strings user-facing sin ruta de i18n.
- No documenta smoke visual en el mini-brief.

---

## 13. Changelog

| Versión | Fecha      | Cambios                                                                                                                                                                                                                                                                                             |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.0** | 2026-05-19 | Primer UI Playbook. Firma AgriSphere Light Mode, paleta hex final, Flat Minimalista por ADR-006, tipografía Geist/JetBrains, Bento geometry, shadcn/ui catalog v1, signature components (`BentoGrid`, `BatchChip`, `LimePulse`), proceso v0.dev y DoD visual. Motion y sound quedan TBD controlado. |
