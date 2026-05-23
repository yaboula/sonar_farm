# UI Brief — S19 · MarketApp

## Context

La MarketApp es el mini-Bloomberg de Farm Sonar. Permite al granjero abrir el Laptop, entrar al Mercado y ver instantáneamente qué NPCs están comprando, a qué precio están cotizando los cultivos hoy, y cuáles son sus requisitos de calidad.

## Surface type

- [x] Manager Panel (Laptop, fullscreen, dense data)
- [ ] Tablet field (overlay, glanceable, action-oriented)
- [ ] Modal / Drawer / Sheet
- [ ] Inline component

## Data shown

- Lista de NPCs compradores (ej. Molino Pedro, Supermercado Casals).
- Avatar o icono genérico por cada NPC.
- Cultivos que acepta cada NPC (iconos o nombres).
- Calidad mínima exigida (ej. "Sólo A o B", o "Acepta C").
- Precio actual que están pagando por cada cultivo.
- Distancia o ubicación aproximada (opcional/roleplay, ej. "Paleto Bay").
- _Nota: Los datos históricos de precio y contratos B2B se añadirán a estas cards en S20 y S21._

## Actions available

- (Por ahora en S19): Sólo visualización de datos en tiempo real ("Read-only").
- Hover en los cultivos aceptados para ver tooltips con el precio exacto × calidad.

## Layout intent

- **Bento Grid**. Múltiples cards, una por cada NPC comprador.
- Dentro de cada card, un header con la info del NPC y un cuerpo con los badges/chips de los cultivos que compra.
- Sidebar de navegación del Laptop a la izquierda (ya provista por el shell S4).

## Components needed

- `BentoGrid`, `BentoGrid.Item` (ya en S4).
- `Card`, `Badge`, `Tooltip` de shadcn/ui.
- `BatchChip` (para mostrar los crops que compra).

## Motion intent

- Hover suave en las cards (scale 1.01 o brillo sutil en el borde) para indicar interactividad futura.
- Staggered fade-in al cargar la grid (cada card entra unos milisegundos después de la otra).

## Inspirations

- Tarjetas de contacto de Linear.
- Dashboards de commodities agrícolas o exchanges simples.

## Out of scope

- Gráficas de histórico de precios (viene en S20).
- Firmar contratos o progreso de entregas (viene en S21).
- Venta remota (el jugador DEBE conducir físicamente al NPC para vender, la app es solo de información).
