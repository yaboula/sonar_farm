# 📘 Farm Sonar — Product Bible

> **Versión:** 1.0 (firmada, living document).
> **Fecha:** 2026-05-04.
> **Estado:** documento fundacional. Si algo no está aquí, no es parte del producto. Si quieres añadir algo al producto, primero se añade aquí.
> **Audiencia:** founder + cualquier AI agent (Cascade, Opus, Claude, GPT) o humano que trabaje en Farm Sonar.

---

## 0. Cómo se usa este documento

Este es **el contrato fundacional** de Farm Sonar.

- Cualquier feature propuesto se mide contra los **Pilares (§3)** y los **Anti-features (§5)**.
- Cualquier decisión técnica se mide contra las **Fundaciones técnicas (§9)**.
- Cualquier número económico se mide contra los **Principios económicos (§14)**.
- Si surge una decisión nueva que contradice esta Bible, se **discute, se decide, y se actualiza esta Bible** — nunca se ignora silenciosamente.

**Cualquier AI agent que se incorpore al proyecto debe leer este documento entero antes de tocar nada.** Sin esto, cada sesión empieza desde cero.

---

## 1. Identidad

| Campo                     | Valor                                                                                                                                                                                                                                                                                                  |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Nombre del producto**   | **Farm Sonar**                                                                                                                                                                                                                                                                                         |
| **Brand family**          | **Sonar** (producto pertenece a una familia futura: Mill Sonar, Bakery Sonar, etc. — esos son productos separados, no parte de este release)                                                                                                                                                           |
| **Posicionamiento**       | Producto FiveM standalone-capable de **simulación agrícola profunda** para servidores RP serios.                                                                                                                                                                                                       |
| **Tagline operacional**   | _Premium-grade farming infrastructure for FiveM._                                                                                                                                                                                                                                                      |
| **Tagline ES**            | _La granja que vive cuando no estás._                                                                                                                                                                                                                                                                  |
| **Tono de marca**         | Profesional, fresco, tecnológico, ultra-limpio. Estilo dashboard SaaS Silicon Valley aplicado a agricultura premium. Cero "amigo", cero exclamaciones, cero gen-Z. Datos en primer plano, chrome mínimo.                                                                                               |
| **Inspiración visual**    | Linear · Vercel · Stripe · AgriSphere · Climate FieldView · John Deere Operations Center · laboratorio agrícola premium. **Bento Grid** como paradigma de layout. **Flat minimalista** cards (white `#FFFFFF`, 1px border). Tono Calm-Tech / iPad-like. Ver ADR-006 para el descarte de Glassmorphism. |
| **Inspiración funcional** | John Deere Ops + Climate FieldView (gestión agrícola pro) + Stripe Dashboard (densidad de datos legible) + Linear (flujos de trabajo limpios).                                                                                                                                                         |
| **Tipografía UI**         | **Geist Sans** (display + body, fallback Inter).                                                                                                                                                                                                                                                       |
| **Tipografía monospace**  | **JetBrains Mono** (batch IDs, IBANs, datos técnicos, monospace tables).                                                                                                                                                                                                                               |
| **Idioma código**         | Inglés. No negociable.                                                                                                                                                                                                                                                                                 |
| **Idioma producto**       | i18n desde commit 0. Locales target lanzamiento: ES, EN. Posteriores: FR, DE, PT-BR.                                                                                                                                                                                                                   |

### 1.1 Paleta canónica firmada (v1.2)

> **Firmada** en sesión UI dedicada (2026-05-19) usando AgriSphere como ancla visual. Valores hex finales, no más "propuesto". Justificación completa en `04_UI_PLAYBOOK.md`. Cambio de acabado (glass → flat) en ADR-006.

| Token           | Hex firmado                             | Uso                                                                    |
| --------------- | --------------------------------------- | ---------------------------------------------------------------------- |
| `--fs-bg`       | `#D9EAE3` (menta/salvia claro)          | Background base de toda surface NUI                                    |
| `--fs-surface`  | `#FFFFFF` (blanco puro, flat, sin blur) | Cards Bento, panels, tarjetas                                          |
| `--fs-nav`      | `#050505` (negro casi puro)             | Navegación, pill menu, contraste extremo                               |
| `--fs-accent`   | **`#B6FB63`** (lima Calm-Tech) ⭐       | Signal único: CTAs, success, harvest ready, calidad A/S, `<LimePulse>` |
| `--fs-fg`       | `#050505` (negro casi puro)             | Texto principal sobre surface clara                                    |
| `--fs-fg-muted` | `#969C9C` (gris verdoso)                | Texto secundario, labels, iconos inactivos                             |
| `--fs-border`   | `#969C9C` (alpha 20%)                   | Borde 1px de tarjetas flat                                             |
| `--fs-success`  | pastel verde translúcido                | Badges "Task Completed", calidad alta                                  |
| `--fs-warning`  | pastel ámbar translúcido                | Cosecha tardía, plaga detectada                                        |
| `--fs-danger`   | pastel rojo translúcido                 | Errores, calidad D, contrato breached                                  |

> **Status colors** se especifican como pares (fondo translúcido pastel + texto oscuro legible) en el `04_UI_PLAYBOOK.md`. La regla del único acento (`--fs-accent` lima) se mantiene innegociable: ningún otro color satura.

---

## 2. Visión y misión

### 2.1 Visión (a 12 meses post-launch)

> Que cuando un operador FiveM piense en "el script de granja serio", piense en **Farm Sonar**. Que el primer dashboard que vea en su laptop de oficina le haga decir _"esto no parece un script, parece un producto SaaS premium"_.

### 2.2 Misión (cada decisión que tomamos)

> Diseñar y construir **una granja que vive sola pero brilla con un equipo**. Donde cada acción tiene peso físico, cada lote tiene historia, y cada decisión económica importa. Premium-grade desde el primer commit.

### 2.3 Promesa al servidor (cliente comercial)

> _"Compras Farm Sonar y te llevas una vertical agrícola completa funcionando como un solo organismo. Cero integración de 5 scripts. Cero debugging de conflictos. Lo enchufas, lo configuras, y tu servidor sube de tier."_

### 2.4 Promesa al operador (jugador final)

> _"Tu granja existe aunque tú no estés. Tus cultivos crecen, tus contratos vencen, tu reputación pesa. Cuando vuelves, el Laptop de la oficina te enseña exactamente qué pasó y qué decisión tomar a continuación. Premium-grade. Bento. Lime neón. Cero fricción."_

---

## 3. Los 5 Pilares innegociables

> Cualquier feature, asset o decisión que viole uno de estos pilares se descarta. Sin debate.

### Pilar 1 — Físico en campo, digital en gestión

> Si una acción ocurre **en el campo** (sembrar, regar, cosechar, transportar, descargar, alimentar, podar), pasa con **animación + prop + colisión**. Sin menús flotantes, sin atajos abstractos.
> Si es **gestión administrativa** (firmar contrato, ver finanzas, asignar tareas, gestionar empleados, consultar bitácora, configurar empresa), pasa en el **Laptop de la oficina** o la **Tablet de campo**. Sin hibridaciones.
> **Excepción única**: pequeñas interacciones contextuales con `ox_target` sobre props físicos (ej. "abrir saco para inspeccionar") pueden disparar mini-UI inline sin abrir la Tablet entera.

### Pilar 2 — Calidad y trazabilidad propagadas

> **Todo lote** tiene `batch_id`, **calidad S/A/B/C/D** calculada por fórmula auditable de 7 factores, **frescura con caducidad**, **peso real**, **origen sellado** (parcela + empresa + jugador + timestamp).
> La calidad **nunca mejora** en la cadena: mal grano → como mucho harina B, nunca harina A. Esta regla aplica internamente (entre sub-nodos de Farm Sonar) y se preserva para que un futuro Molino Sonar continúe el lineage sin tocar nuestro código.
> Cada acción que altera un lote (cosechar, almacenar, transportar, vender) emite un evento al bus `sonar:farm:*` con el `batch_id` para auditoría.

### Pilar 3 — Mundo vivo cuando estás solo

> Farm Sonar es **producto comercial completo en single-player simulado**, no demo de un ecosistema futuro.
> Cuando el jugador está solo en el servidor: NPCs compradores con personalidad, precios que oscilan diariamente con random walk acotado, contratos B2B recurrentes, eventos de demanda. La granja **se siente como un negocio real**, no como un sandbox vacío.
> Cooperación con otros jugadores escala las recompensas pero nunca es requisito.

### Pilar 4 — Libertad de producción + presión de calidad

> El jugador **decide qué planta, cuánto, dónde y cuándo**. No hay quests obligatorias, no hay tutorial dirigista, no hay "cosecha 100 unidades de X para desbloquear Y".
> Pero la **calidad del output limita los clientes accesibles y el precio pagado**, y la **reputación con cada NPC** abre tiers de contratos premium.
> **Profundidad opt-in**: el casual planta, cosecha y vende a quien le pague hoy. El hardcore optimiza rotación de suelo, calidad de semilla, fertilización NPK, timing de cosecha, mantenimiento de maquinaria, contratos B2B recurrentes, gestión de empleados con permisos delegados.

### Pilar 5 — Configurable, no hardcoded

> **Todo número del producto** (precios canon por cultivo, multiplicador de tiempo, duración del ciclo de cada cultivo, costes de mantenimiento, salarios base, oscilación diaria de mercado, severidad de plagas, parámetros climáticos por estación, pesos de la fórmula de calidad) vive en **`config.lua`** o tabla DB de configuración.
> **Cada cultivo nuevo se añade como archivo de config + assets**, sin tocar código.
> Cero strings hardcoded (i18n desde commit 0). Cero magic numbers.

---

## 4. Estándar de calidad ("Wooow Test")

Una feature está terminada cuando:

- [ ] Se puede grabar un clip de 15 segundos que funciona como anuncio sin editar.
- [ ] Un jugador que nunca ha jugado FiveM entiende qué hacer en menos de 10 segundos.
- [ ] No hay ningún menú flotante que sustituya una acción física posible.
- [ ] El sonido refuerza la acción (no es genérico).
- [ ] La animación es específica (no la genérica del framework).
- [ ] Hay al menos un detalle que el jugador descubre la 5ª vez (recompensa de descubrimiento).
- [ ] La UI asociada (si la hay) respeta el design system definido en §1.1 (paleta + tipografía + Bento + glassmorphism).
- [ ] El feature respeta los 5 pilares de §3.
- [ ] Tiene tests donde tenga sentido (lógica económica + validaciones server = sí; UI puramente visual = no).

---

## 5. Anti-features (lo que NUNCA hacemos)

- ❌ **Menús flotantes genéricos que reemplazan acciones físicas posibles** (excepción única: mini-UI inline contextual con `ox_target` sobre props).
- ❌ **Items que aparecen en inventario sin proceso físico** (rompe Pilar 1).
- ❌ **Calidad que mejora downstream** (rompe Pilar 2).
- ❌ **Quests obligatorias o tutorial dirigista** (rompe Pilar 4).
- ❌ **Hardcoding de precios, idiomas, tiempos, ubicaciones** (rompe Pilar 5).
- ❌ **Llamadas directas entre resources** (todo va por bus `sonar:farm:*`).
- ❌ **Confianza en datos del cliente** sin validación server (server-authoritative absoluto).
- ❌ **Assets robados o comprados a terceros revendibles**.
- ❌ **Features "porque la competencia las tiene"** sin pasar el Wooow Test.
- ❌ **IA dentro del script como diferenciador comercial** (la IA es nuestra herramienta de desarrollo, no parte del producto).
- ❌ **Macroeconomía política/bolsa/gobierno**. Foco: cadena productiva agrícola.
- ❌ **Soporte multi-framework infinito**. QBox primary + QBCore compat. ESX vía bridge en oleada 2+. Resto fuera.
- ❌ **Dependencias de pago de terceros**. El cliente compra Farm Sonar y todo lo que necesita está dentro (excepto gratuitos universales: ox_lib, ox_target, ox_inventory, oxmysql).
- ❌ **Modelos 3D propios de devices** (laptops, tablets). Usamos props GTA V nativos. El wooow vive en el React UI.
- ❌ **PvP combat dentro del script**. Disputas → governance + reputación, no violencia.

---

## 6. Alcance del primer release vendible ("Imperio reducido")

> **Calidad desde día 1, no concepto MVP-light.** Lo que sale a Tebex es producto cerrado y AAA.
> **Duración estimada**: ~5-6 meses de desarrollo desde commit 0.

### 6.1 Cultivos jugables (8 hero crops)

| Categoría (sub-nodo)    | Cultivos              |
| ----------------------- | --------------------- |
| **Cereales**            | Trigo · Maíz · Cebada |
| **Hortalizas frutales** | Tomate · Pimiento     |
| **Hojas**               | Lechuga               |
| **Bulbos**              | Cebolla               |
| **Tubérculos**          | Patata                |

Cada cultivo tiene variantes **común / premium** (precio, rendimiento y demanda diferenciados) y stages 3D visibles durante el ciclo (germinación → crecimiento → maduración → cosecha).

### 6.2 MLO completo ajustado

- 4 campos extensivos (cereales).
- 3 parcelas hortícolas (rotación libre de hortalizas/hojas/bulbos/tubérculos).
- 1 invernadero (cristal industrial, no polietileno).
- 1 silo + 1 cámara frigorífica + 1 almacén seco.
- Casa de 2 plantas + oficina (laptop) + granero (parking flota).

### 6.3 Flota (~12 vehículos)

- 3 tractores (grande / mediano / pequeño con remolques).
- 1 cosechadora con 1 cabezal intercambiable.
- 2 sembradoras (cereal + hortícola).
- 1 arado + 1 cultivador.
- 1 fertilizadora + 1 fumigadora + 1 cisterna.
- 1 camión de transporte + 1 pickup.

### 6.4 Sistemas core del release

- Sistema empresa con 4 roles + 5 toggles (§11).
- Sistema de calidad de 7 factores (§10).
- Lineage por `batch_id`.
- Clima dinámico con eventos meteorológicos.
- 4 estaciones agrícolas.
- Sistema de plagas selectivo.
- NPC compradores con catálogo (§12).
- Contratos B2B recurrentes.
- Reputación por NPC.
- Banca Sonar (cuentas personales + empresa, IBAN, movimientos).
- Persistencia real-time absoluta con cap de daño (§13).

### 6.5 Fuera de scope (oleadas posteriores)

- Ganadería, lácteos, apicultura → **otros productos Sonar** (Livestock Sonar, Dairy Sonar, etc.), no este.
- NPC workers (trabajadores NPC contratables) → oleada 3.
- Mill Sonar (Molino), Bakery Sonar (Panadería), Retail Sonar (Tienda) → productos separados futuros.
- ESX bridge → oleada 2+.
- Compra/venta de empresas entre jugadores → versión posterior.

---

## 7. Sub-nodos internos de Farm Sonar

Farm Sonar es un producto, **NO un nodo único**. Internamente está organizado en **5 sub-nodos arquitectónicos** que son módulos del mismo producto:

```
Farm Sonar
├── Cereales       (campos extensivos + sembradora cereal + cosechadora + silo)
├── Hortalizas     (parcelas + invernadero + riego goteo + cajas)
├── Hojas          (parcelas + invernadero + bandejas)
├── Bulbos         (parcelas + sacador específico)
└── Tubérculos     (parcelas + sacador específico + almacén seco)
```

Cada sub-nodo:

- Define sus propios cultivos en `config/crops/<categoria>.lua`.
- Comparte el sistema de calidad, lineage, empresa, contratos, NPCs y UI con los demás.
- Se puede activar/desactivar individualmente desde `config.lua` (server admin puede vender una variante "solo cereales" si quisiera, aunque el release default los activa todos).

---

## 8. Modos de operación

### 8.1 Modo standalone (default)

El servidor activa Farm Sonar **sin ningún otro producto Sonar**.

- NPCs compradores son la única demanda: molinos, distribuidoras, supermercados, restaurantes, conserveras (catálogo de 6-10 entidades NPC con personalidad, §12).
- El mundo se siente vivo gracias al random walk diario + contratos B2B + reputación.
- **Es el modo comercial principal**, completo y autocontenido.

### 8.2 Modo ecosistema-ready (preparado, no activo)

Cuando un futuro **Mill Sonar** (Molino) se publique, podrá consumir el output de Farm Sonar **sin requerir refactor** gracias a:

- `batch_id` universal preservado en lineage.
- Eventos `sonar:farm:batch:harvested`, `sonar:farm:batch:sold` documentables.
- Item Físico con schema compartido.

**Importante**: no documentamos API pública en oleada 1. La interfaz queda "preparada pero no firmada como estable". Cuando saquemos Mill Sonar, formalizamos.

---

## 9. Fundaciones técnicas

### 9.1 Stack obligatorio

| Componente              | Decisión                                                                                                 | Justificación                                      |
| ----------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| **Framework primary**   | **QBox**                                                                                                 | Moderno, mantenido.                                |
| **Framework compat**    | **QBCore**                                                                                               | Cuota de mercado actual.                           |
| **Framework oleada 2+** | **ESX** vía bridge limitado                                                                              | Cobertura.                                         |
| **Excluidos**           | vRP, custom                                                                                              | Foco, no diluimos.                                 |
| **DB**                  | MySQL 8 / MariaDB 10.6+ con `oxmysql`                                                                    | Async, prepared statements.                        |
| **Inventario**          | `ox_inventory` (obligatorio)                                                                             | Estándar premium, pesos/volumen.                   |
| **Targeting**           | `ox_target`                                                                                              | Estándar moderno.                                  |
| **Library Lua**         | `ox_lib`                                                                                                 | Utils, notificaciones fallback, callbacks.         |
| **Lenguaje server**     | Lua 5.4 (FiveM nativo)                                                                                   | Sin alternativa.                                   |
| **UI / NUI**            | **React 18 + TypeScript strict + Vite + Tailwind v4 + shadcn/ui + Framer Motion 11 + Lucide + Recharts** | Stack frozen, calidad AAA.                         |
| **Estado NUI**          | **React Context + useReducer** (NO Zustand)                                                              | Suficiente para nuestro scope, menos dependencias. |
| **Build NUI**           | Vite + esbuild                                                                                           | Rapidez de iteración.                              |
| **Validación**          | Zod (NUI) + validación manual server-side                                                                | Schemas TypeScript runtime.                        |

### 9.2 Principios arquitectónicos

1. **Server-authoritative absoluto.** El cliente solo renderiza y envía intenciones. La DB es la única fuente de verdad.
2. **Event-driven, bus único `sonar:farm:*`.** Resources hablan solo por el bus, jamás se llaman directamente entre sí.
3. **Modular por sub-nodo.** Cada sub-nodo es un módulo dentro del resource principal, con activación/desactivación por config.
4. **Item Físico universal.** Todo item productivo hereda el schema `{ id, weight, volume, quality, freshness, origin, batch_id, lineage_chain, created_at }`.
5. **Bridges al framework aislados.** Toda interacción con QBox/QBCore/ESX pasa por `bridge_*` modules. El resto del código nunca toca el framework directamente.
6. **Configurable, no hardcoded** (Pilar 5).
7. **DDD + EDA + Vertical Slices** como metodología.
8. **Performance: experiencia primero.** No perseguimos 0.00ms; perseguimos que el jugador no note nada raro. Budgets de frame y DB cost se definen por feature.

### 9.3 Naming técnico (firmado)

| Espacio             | Convención      | Ejemplo                                                                                                                                     |
| ------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **DB tables**       | `sonar_farm_*`  | `sonar_farm_companies`, `sonar_farm_batches`, `sonar_farm_contracts`, `sonar_farm_plots`, `sonar_farm_npc_buyers`                           |
| **Event bus**       | `sonar:farm:*`  | `sonar:farm:batch:harvested`, `sonar:farm:contract:signed`, `sonar:farm:plot:planted`                                                       |
| **Resources FiveM** | `sonar_farm_*`  | `sonar_farm_core` (lógica), `sonar_farm_tablet` (NUI). Posibles módulos: `sonar_farm_npcs`, `sonar_farm_weather` (decidir en arquitectura). |
| **Configs Lua**     | `Config.Farm.*` | `Config.Farm.Crops.wheat`, `Config.Farm.NPCs.molino_pedro`                                                                                  |
| **Locales**         | `locale.farm.*` | `locale.farm.notification.harvest_ready`                                                                                                    |

### 9.4 Anti-patrones técnicos prohibidos

- ❌ Llamadas directas entre resources (solo bus).
- ❌ Polling cada N ms en client. Todo event-driven.
- ❌ Confianza en datos del cliente sin validación server.
- ❌ Tablas DB sin prefijo `sonar_farm_*`.
- ❌ UI fuera del Laptop / Tablet (Pilar 1).
- ❌ Hardcoding (Pilar 5).
- ❌ Migrations que rompen DB existentes sin script de upgrade documentado.

---

## 10. Sistema de calidad

### 10.1 Escala canónica

```
S = perfecto (95-100)   premium absoluto, raro, paga máximo
A = excelente (80-94)   producto top, contratos premium
B = bueno (60-79)       calidad estándar, mayoría de mercado
C = aceptable (40-59)   solo NPCs sin exigencia, precio bajo
D = mal (0-39)          rechazado por la mayoría, venta de desecho
```

### 10.2 Los 7 factores

La calidad final del lote se calcula como **media ponderada** de:

| #   | Factor                  | Rango | Qué representa                                                               |
| --- | ----------------------- | ----- | ---------------------------------------------------------------------------- |
| 1   | **Soil score**          | 0-100 | Estado del suelo: rotación de cultivos, descanso entre ciclos, abono previo. |
| 2   | **Irrigation score**    | 0-100 | % de riego óptimo recibido durante el ciclo.                                 |
| 3   | **Pest impact**         | 0-100 | Penalización por plagas no tratadas (100 = sin plaga).                       |
| 4   | **Weather match**       | 0-100 | Bonus/penaliz según afinidad clima-cultivo durante el ciclo.                 |
| 5   | **Seed quality**        | 0-100 | Calidad de la semilla usada (comprada o reservada de cosecha anterior).      |
| 6   | **Fertilization score** | 0-100 | NPK aplicado vs recomendado para el cultivo.                                 |
| 7   | **Harvest timing**      | 0-100 | Penaliza cosecha tardía (sobremaduro) o temprana (inmadura).                 |

**Pesos exactos + mapping numérico → S/A/B/C/D** se decide en el slice de implementación con balance y playtesting. Los pesos viven en `config.lua` por cultivo.

### 10.3 Machinery state (sistema paralelo)

El estado de la maquinaria **NO entra en la fórmula de calidad del lote**. Afecta:

- Velocidad de operación (cosechadora lenta = más tiempo en el campo).
- Probabilidad de avería durante operación.
- Coste de mantenimiento periódico.

Razón: separar preocupaciones. La calidad del cultivo es propiedad del lote en sí; el estado de la maquinaria es propiedad del proceso.

---

## 11. Sistema empresa

### 11.1 Roles (4 fijos)

| Rol                   | Permisos predefinidos                                                                                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Dueño**             | Todo. Vende/cierra la empresa. No revocable.                                                                                                                                               |
| **Gerente**           | Contrata/despide empleados (no al dueño). Fija salarios bajo límite. Firma contratos B2B bajo límite. Accede a finanzas read+write. Asigna tareas. Accede a Laptop oficina + Tablet campo. |
| **Empleado fijo**     | Ejecuta tareas asignadas. Accede a Tablet de campo (mapa parcelas + tareas + tiempo). Sin acceso a finanzas por defecto.                                                                   |
| **Empleado temporal** | Contrato por tarea/jornada (8h juego). Pago al cerrar tarea. Sin acceso a la oficina. Tablet de campo en modo limitado.                                                                    |

### 11.2 Los 5 toggles macro (override por dueño)

Para cada **empleado fijo individualmente**, el dueño puede activar/desactivar:

1. **Capital**: puede mover fondos de caja (sí/no, hasta L€/día configurable).
2. **B2B**: puede firmar contratos en nombre de la empresa (sí/no, hasta L€ por contrato).
3. **Personal**: puede contratar/despedir empleados temporales (sí/no).
4. **Operativa**: puede asignar tareas a otros empleados (sí/no).
5. **Acceso físico**: tiene llaves del Laptop de oficina (sí/no).

UI: pestaña **"Personnel"** en Laptop oficina, cards por empleado con 5 toggles iOS-style.

### 11.3 Reputación

Cada jugador acumula reputación:

- **Reputación personal** (cross-empresa, por jugador).
- **Reputación con cada NPC** (Molino Pedro, Supermercado Casals, etc.).
- **Reputación de la empresa** (agregada del equipo).

La reputación abre tiers de contratos premium y mejora precios pagados.

---

## 12. NPCs compradores

### 12.1 Catálogo (6-10 entidades NPC)

Ejemplos (nombres definitivos + valores en slice de implementación):

| NPC NPC ejemplo      | Cultivos preferidos                | Calidad mínima | Volumen típico | Frecuencia | Personalidad                       |
| -------------------- | ---------------------------------- | -------------- | -------------- | ---------- | ---------------------------------- |
| Molino Pedro         | trigo, cebada, maíz                | A              | 200-500 kg     | semanal    | exigente, leal si entregas calidad |
| Supermercado Casals  | todo (mix)                         | B              | 50-200 kg      | 2 días     | volumen alto, precio justo         |
| Restaurante La Plaza | tomate, lechuga, cebolla, pimiento | A              | 30-80 kg       | diario     | calidad obsesiva, paga premium     |
| Distribuidora Vega   | todo (bulk)                        | C              | 500-1500 kg    | semanal    | volumen, precio bajo               |
| Conservera del Sur   | tomate, pimiento, cebolla          | B              | 200-600 kg     | bisemanal  | estacionalidad fuerte              |

Cada NPC tiene fila propia en `sonar_farm_npc_buyers` con: cultivos preferidos, quality threshold, volumen rango, frecuencia base, rango de precio, personalidad (modificadores).

### 12.2 Precios dinámicos (random walk acotado)

- Cada cultivo tiene un **precio canon** por kg/unidad (config).
- Diariamente (al boot del día in-game) se aplica un **random walk acotado a ±10%** del precio canon.
- El precio diario es el mismo para todos los NPCs del catálogo (es el "precio de mercado del día") pero cada NPC tiene **modificadores propios** (premium por calidad alta, penalización si está por debajo de su threshold, bonus por volumen alto, bonus por contrato recurrente vs venta spot, bonus por lineage trazable, bonus por reputación del jugador).

### 12.3 Fórmula de precio final pagado (delegada a slice de implementación)

```
final_price_per_unit =
    base_price_canon[crop]
  × daily_market_multiplier        (random walk ±10%)
  × quality_tier_multiplier         (S/A/B/C/D → curva config)
  × npc_quality_threshold_mod       (premium/penalty según threshold del NPC)
  × volume_mod                      (descuento si poco / bonus si bulk)
  × freshness_mod                   (penalty si frescura baja)
  × lineage_traceability_mod        (bonus si origen sellado completo)
  × player_reputation_mod[npc]      (bonus por historial con ese NPC)
  × contract_type_mod               (spot < contrato recurrente < licitación premium)
```

Cada modificador es un float ~`0.7-1.3`. Valores exactos en `config.lua` y se balancean en playtesting.

### 12.4 Contratos B2B recurrentes

- Un NPC puede ofrecer un **contrato recurrente** (ej. "Molino Pedro: 200 kg trigo calidad A o superior cada 7 días, por 12 ciclos").
- El jugador acepta desde la app Mercado del Laptop.
- Si cumple → reputación sube, precio bonus, posibles ofertas premium futuras.
- Si incumple (no entrega, entrega menos cantidad, entrega calidad inferior) → penalty reputacional, posible pérdida del NPC como cliente.

---

## 13. Modelo de tiempo y persistencia

### 13.1 Tiempo in-game

- **Default**: 1 día real = 1 estación in-game (4 días reales = 1 año agrícola).
- **Trigo cycle** ≈ 24h reales en default.
- **Multiplicador admin global** en `config.lua`: `0.25x` (arcade, ciclos cortos) | `1x` (default) | `2x` (realista, ciclos largos).
- Eventos como cosecha, plagas, estaciones se evalúan con el multiplicador aplicado.

### 13.2 Persistencia offline (server downtime)

- **Real-time absoluto**: cada cultivo tiene `last_update_ts` (UNIX). Avanza según delta sin importar quién esté online o si el server estuvo caído.
- **Cap de daño**: si el server estuvo caído > 6h (configurable), los eventos negativos acumulados (sequía por falta de riego, plagas sin tratar) se **congelan al máximo permitido** (default -30% calidad sobre el factor afectado, NUNCA muerte total del lote).
- Al server boot: para cada cultivo activo, se calcula el delta y se aplican avances + caps. Idempotente.
- Servidores con mantenimientos largos no penalizan brutalmente a los jugadores.

### 13.3 Estaciones (4)

Cada estación dura el equivalente de 1 día real en default. Afectan:

- **Weather match** (factor 4 de calidad).
- **Disponibilidad de cultivos** (algunos cultivos solo se pueden plantar en ciertas estaciones).
- **Severidad de plagas** (más plagas en verano cálido, menos en invierno).
- **Demanda NPC** (Conservera del Sur pide más tomate en verano).

---

## 14. Principios económicos

### 14.1 Sumideros (money sinks)

- Compra de semillas (más caro = mejor calidad inicial).
- Compra de fertilizantes (NPK).
- Compra de pesticidas / tratamientos contra plagas.
- Mantenimiento de maquinaria (preventivo evita averías costosas).
- Salarios de empleados (fijos + temporales).
- Combustible de vehículos.
- Alquiler de parcelas adicionales (oleada 2+).
- Auto-care services (oleada 2+, opcional).

### 14.2 Inflación

- **Random walk del mercado** acotado a ±10% por día evita inflación descontrolada.
- **Reputación capada a 100** evita escalado infinito de precios.
- **Sumideros recurrentes** (mantenimiento + salarios + insumos) drenan capital constantemente.

### 14.3 Balance básico

Ratio target para sesión casual (~2h de juego activo): ingreso bruto por venta cubre **120-140%** de gastos recurrentes. El margen del 20-40% se invierte en upgrades / scale-up. Sin grindeo brutal, sin dinero infinito.

> **Pesos exactos + valores canon de cada cultivo, NPC, sumidero, salario** se diseñan en el slice de **economía** con tabla canónica auditable.

---

## 15. Paradigma de UI

### 15.1 Dos surfaces, sin 3D custom

- **Laptop fijo en la oficina del MLO**: prop GTA V nativo (anim sentarse + `ox_target`) → abre **Manager Panel completo** (estrategia profunda, finanzas, contratos, personnel, dashboards Recharts).
- **Tablet de campo**: prop GTA V nativo (tablet vanilla en mano) → abre **apps reducidas útiles en el campo** (mapa parcelas, estado de cultivos en vivo, asignar tarea rápida, ver contratos pendientes, mensajes).

Foco total en el **React UI**. **NO modelamos devices propios en 3D.**

### 15.2 Apps incluidas en oleada 1

| App           | Surface         | Función                                                                                     |
| ------------- | --------------- | ------------------------------------------------------------------------------------------- |
| **Dashboard** | Laptop          | Vista general empresa: ingresos, lotes activos, contratos vencen, alertas.                  |
| **Plots**     | Laptop + Tablet | Mapa parcelas + estado cultivo + acciones rápidas (regar/fertilizar contratado a empleado). |
| **Batches**   | Laptop          | Lotes en almacén, filtrados por cultivo/calidad, lineage drill-down.                        |
| **Market**    | Laptop          | Catálogo de NPCs, precios del día, contratos disponibles, contratos firmados.               |
| **Contracts** | Laptop          | Gestión de contratos B2B (firmar, cumplir, archivo, historial).                             |
| **Personnel** | Laptop          | Roster empleados, roles, 5 toggles, salarios, productividad.                                |
| **Finance**   | Laptop          | Banca Sonar empresa (IBAN, movimientos, transferencias) + caja física.                      |
| **Bitácora**  | Laptop          | Audit trail de toda acción crítica (firmas, ventas, contrataciones).                        |
| **Tasks**     | Tablet          | Tareas asignadas al jugador, próximas, completadas (para empleados).                        |
| **Messages**  | Tablet + Laptop | Chat empresa + mensajes con NPCs.                                                           |

### 15.3 Layout: Bento Grid

- Cards modulares de distintos tamaños, flat minimalista (`#FFFFFF`, sin sombra, borde 1px sutil) per ADR-006.
- Datos densos pero legibles (mucho aire blanco, jerarquía clara).
- Datos numéricos en **JetBrains Mono**, UI en **Geist Sans**.
- Animaciones sutiles (transitions ≤300ms, ease-out). Framer Motion solo si el slice lo justifica.
- Lime Calm-Tech `#B6FB63` como **único color de signal** (CTAs, success states, harvest ready, calidad A/S). Resto en escala negro/menta/blanco.

---

## 16. Metodología de trabajo

> **Detalle operativo completo:** `docs/03_AI_PLAYBOOK.md`. Esta sección resume el contrato canónico.

### 16.1 Cadena de herramientas AI

| Herramienta                                | Función                                                                                     |
| ------------------------------------------ | ------------------------------------------------------------------------------------------- |
| **Cascade** (IDE, esta sesión y sucesivas) | Sesión PM + sub-agents, lógica, arquitectura, ADRs, briefs, ejecución.                      |
| **v0.dev**                                 | Mockups de UI por app/pantalla, coordinados por workflow `/ui-design`.                      |
| **Claude Opus** (sesión separada)          | Implementación profunda en sub-agents para slices XL cuando se requiere modelo más potente. |
| **Figma** (opcional, fase 2+)              | Wireframes de flujos completos multi-pantalla.                                              |

### 16.2 Sistema PM Agent + Sub-agents (4 especialidades fijas)

Cada slice de complejidad **L** o **XL** se descompone vía workflow `/spawn-pm`. Cascade adopta el rol **PM Agent** y genera prompts para 2-4 sub-agents que el founder ejecuta en sesiones frescas paralelas:

| Sub-agent             | Owns                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Backend Agent**     | Lua server-side, DB migrations, services, FSMs, eventos `sonar:farm:*`, server-authoritative validations.    |
| **Frontend Agent**    | React 18 + TS + Tailwind v4 + shadcn + Framer Motion, NUI Bento apps, Recharts.                              |
| **Integration Agent** | `Bridge.*`, `ox_inventory`/`ox_target`/`ox_lib`/`oxmysql`, anims, props, vehículos, `fxmanifest.lua`.        |
| **QA Agent**          | Tests automatizados (lua-test server, Vitest NUI), smoke tests manuales, balance numérico, DoD verification. |

Slices **S** (1-3 días) y **M** (3-7 días) típicamente no requieren PM — sesión Cascade única basta.

### 16.3 Cascade activado al máximo

| Capacidad                      | Ubicación                  | Función                                                                                                          |
| ------------------------------ | -------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Rules** (always-on)          | `.windsurf/rules/*.md`     | 5 reglas globales aplicadas en cada sesión: project context, naming, languages, DoD universal, anti-patterns.    |
| **Workflows** (slash commands) | `.windsurf/workflows/*.md` | 6 flujos: `/start-slice`, `/spawn-pm`, `/end-slice`, `/spike`, `/research`, `/ui-design`.                        |
| **Tools nativos**              | Cascade core               | `code_search`, `grep_search`, `search_web`, `read_url_content`, `run_command`, `browser_preview`, memory system. |

### 16.4 Cadena de docs

- **`docs/00_BIBLE.md`** (este doc) — vivo, se actualiza con cada decisión estratégica.
- **`docs/01_ROADMAP.md`** — 6 fases · 36 slices con DoD.
- **`docs/02_DECISIONS.md`** — ADRs cortos (~20 líneas) cuando una decisión sea no-obvia.
- **`docs/03_AI_PLAYBOOK.md`** — sistema operativo del proyecto (PM + sub-agents + workflows + best practices).
- **`docs/04_UI_PLAYBOOK.md`** — UI canon (a redactar en sesión dedicada).
- **`docs/slices/SXX_<nombre>.md`** — mini-brief por slice (just-in-time, generado por `/start-slice`).
- **`docs/slices/SXX_<nombre>.prompts.md`** — prompts a sub-agents (generado por `/spawn-pm`).
- **`docs/slices/_TEMPLATE.md`** — plantilla canónica para mini-briefs.
- **`docs/spikes/<topic>.md`** — reportes de investigación técnica time-boxed.
- **`docs/research/<topic>.md`** — reportes de investigación documental con citas.
- **NO escribimos** docs técnicos profundos antes del slice que los implementa. Just-in-time.

### 16.5 Vertical Slices — definición

Un slice es un **corte fino y vertical** del producto que:

1. Toca todas las capas (DB → server → cliente → UI).
2. Aporta **una capacidad completa y demostrable** al final.
3. Cierra con tests + mini-brief actualizado.
4. Genera ADR si tomó decisiones de arquitectura.

### 16.6 Definition of Done universal por slice

12 checks obligatorios antes de marcar `DONE` (enforced por workflow `/end-slice`):

- [ ] Funciona end-to-end en QBox **y** QBCore (smoke test en ambos, documentado).
- [ ] Tests automatizados donde tenga sentido (lógica económica, FSMs, fórmulas).
- [ ] Respeta los 5 Pilares (§3) y los anti-patrones técnicos (§9.4).
- [ ] Respeta naming técnico (§9.3).
- [ ] UI (si la hay) sigue paleta + Bento + glassmorphism + tipografía Geist/Mono (§1.1, §15).
- [ ] i18n: cero strings hardcoded (`locales/{es,en}.lua`).
- [ ] Cero magic numbers (`config/*` siempre).
- [ ] Migración DB versionada y rollbackeable si tocó DB.
- [ ] Mini-brief del slice actualizado con lo realmente hecho.
- [ ] ADR creado si tomó decisión arquitectónica no obvia.
- [ ] Bible §18 changelog actualizado si cambió el producto canon.
- [ ] Smoke test manual del happy path documentado en mini-brief §10.

### 16.7 Sesión fresca por slice

- No se arrastran sesiones eternas. Cuando cambia el slice, sesión nueva.
- Las rules `always_on` + memorias persistentes recuperan contexto al instante.
- PM session, Backend session, Frontend session, Integration session, QA session = sesiones distintas y limpias.

---

## 17. Glosario

| Término                  | Definición                                                                                                                                      |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Lote (batch)**         | Conjunto de output de un mismo ciclo de cultivo en una misma parcela. Tiene `batch_id` único.                                                   |
| **Lineage chain**        | Cadena de transformaciones de un lote (en oleada 1 internas; preparada para Mill Sonar futuro).                                                 |
| **Frescura**             | Decay temporal de un lote desde cosecha. Algunos NPCs penalizan frescura baja.                                                                  |
| **Sub-nodo**             | Módulo arquitectónico de Farm Sonar (Cereales, Hortalizas, Hojas, Bulbos, Tubérculos).                                                          |
| **Parcela (plot)**       | Unidad de terreno cultivable. Tiene tipo (extensivo / hortícola / invernadero) y soil score persistente.                                        |
| **Stage**                | Estado visible del cultivo (germinación, crecimiento, maduración, cosecha).                                                                     |
| **Reputación**           | 0-100 por jugador con cada NPC. Afecta tier de contratos y multiplicador de precio.                                                             |
| **Contrato B2B**         | Acuerdo recurrente entre jugador y NPC para entregas periódicas.                                                                                |
| **Manager Panel**        | UI del Laptop oficina. Gestión profunda.                                                                                                        |
| **Tablet de campo**      | UI portable. Apps reducidas operativas.                                                                                                         |
| **Slice**                | Corte vertical del producto que aporta una capacidad completa demostrable.                                                                      |
| **Sonar (brand family)** | Familia de productos Sonar (Farm es uno; Mill, Bakery, etc. son productos futuros separados).                                                   |
| **PM Agent**             | Rol que adopta Cascade en una sesión específica (vía `/spawn-pm`) para descomponer un slice en prompts para sub-agents. No programa producción. |
| **Sub-agent**            | Agente especializado (Backend / Frontend / Integration / QA) que ejecuta una porción del slice en sesión fresca propia.                         |
| **Workflow** (Cascade)   | Comando slash invocable definido en `.windsurf/workflows/*.md` que automatiza un proceso recurrente.                                            |
| **Rule** (Cascade)       | Política `always-on` definida en `.windsurf/rules/*.md` que aplica a toda sesión del proyecto.                                                  |
| **Spike**                | Investigación técnica time-boxed (max 2 días) sobre incógnita o riesgo. Output: reporte con verdict + recomendación.                            |
| **Mini-brief**           | Documento corto por slice (`docs/slices/SXX_*.md`) que captura scope, deliverables, DoD, decisiones, smoke test.                                |
| **DoD universal**        | 12 checks obligatorios para cerrar un slice. Enforced por workflow `/end-slice`.                                                                |

---

## 18. Changelog

| Versión | Fecha      | Cambios                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1.0** | 2026-05-04 | Primera versión firmada. 17 decisiones fundacionales documentadas tras sesión de pivot Granja Sonar → Farm Sonar. Stack heredado del bigproject SONAR, identidad visual + voz fresca, alcance "imperio reducido" (8 cultivos + MLO completo ajustado + flota completa), 5 pilares, arquitectura híbrida pragmática, naming `sonar_farm_*`, sistema de calidad de 7 factores, sistema empresa 4 roles + 5 toggles, NPCs compradores con random walk + contratos B2B, persistencia real-time + cap de daño 6h, UI laptop + tablet sin 3D custom, identidad SaaS Agritech Bento `#CCFF00`.                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **1.1** | 2026-05-18 | §16 Metodología refundida con sistema operativo AI canónico: PM Agent + 4 sub-agents fijos (Backend / Frontend / Integration / QA), sesiones frescas por slice, Cascade activado al máximo (5 rules `always_on`, 6 workflows slash, tools nativos). Cadena de docs ampliada con `03_AI_PLAYBOOK.md`, `04_UI_PLAYBOOK.md` (pendiente), `slices/_TEMPLATE.md`, `spikes/`, `research/`. DoD universal expandido de 8 → 12 checks. §17 glosario ampliado con términos del sistema AI (PM Agent, Sub-agent, Workflow, Rule, Spike, Mini-brief, DoD universal). Sin cambios en producto canon (pillars, anti-features, stack, pricing).                                                                                                                                                                                                                                                                                                                                                                                                          |
| **1.3** | 2026-05-22 | §10 Sistema de calidad operativo en producción: 7 factores implementados (soil + harvest_timing vivos; 5 stubs neutros para slices S13–S16); fórmula media ponderada configurable; grades S/A/B/C/D con umbrales en `config.lua`. §13 Lifecycle real: ciclo físico trigo completo (plant → 4 stages → harvest) con scheduler configurable (default 30 s, no per-frame). §7 Item Físico universal: schema `batch_id` + `lineage_chain` + `freshness` + `origin` en `ox_inventory` metadata. Props nativos de GTA V ratificados como estándar visual para cultivos extensivos (Catálogo §1.2: `prop_veg_grass_01_a/b/c/d`). Bundle B1 (S6+S7+S8) cerrado: primer uso del Slice Bundle pattern (ADR-014), ~35-45% ahorro en tokens de setup vs. 3 slices separados. 4 ADRs nuevos firmados: ADR-011 (batch_id), ADR-012 (scheduler), ADR-013 (surrogate PK crops), ADR-014 (bundle pattern). Sin cambios en pilares, anti-features, stack ni pricing. |
| **1.2** | 2026-05-19 | §1.1 Paleta canónica firmada (cierra el "a refinar en v0.dev" pendiente desde v1.0). Hex finales: bg `#D9EAE3` menta, surface `#FFFFFF` blanco puro flat, nav `#050505` negro, accent `#B6FB63` lima Calm-Tech, muted `#969C9C` gris verdoso. §1 línea de inspiración visual actualizada: "Glassmorphism cards" → "Flat minimalista cards" (justificado por ADR-006: legibilidad en NUI 960×540 + tono Calm-Tech AgriSphere). Anclas visuales firmadas: AgriSphere como referencia primaria, Linear/Stripe/Vercel como secundarias. Componente custom `<GlassCard>` descartado; signatures vivos: `<BentoGrid>`, `<BentoGrid.Item>`, `<BatchChip>`, `<LimePulse>`. Tipografía Geist Sans + JetBrains Mono confirmada, pesos restringidos a 400/500/600 (700+ proscritos para preservar estética premium aireada). Bento system: gap 16px, rounded-2xl, padding comfortable. shadcn/ui catalog v1 firmado (12 componentes esenciales; Form+Zod y Table en reserva). Sin cambios en producto canon (pillars, anti-features, stack, pricing). |

---

> **UI canon externo**: `docs/04_UI_PLAYBOOK.md` v1 materializa §1.1 para ejecución diaria (paleta, Bento system, tipografía, shadcn/ui catalog, signature components, proceso v0.dev). Motion y sound quedan como refinamiento v2 cuando S4 o slices posteriores los necesiten.
