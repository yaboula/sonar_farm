# B2 Smoke Runtime — Guía de Ejecución

> **Propósito:** Guía paso a paso para ejecutar el smoke test de B2 (Storage + NPC Sale) en QBox y QBCore.
> **Fecha:** 2026-05-22
> **Estado:** Pendiente de ejecución por founder

---

## Pre-condiciones

Antes de empezar, verifica:

- [ ] `oxmysql`, `ox_lib`, `ox_inventory`, `ox_target` están corriendo
- [ ] QBox o QBCore stack está activo
- [ ] Tienes al menos un `sonar_batch_wheat` en tu inventario (de B1)
- [ ] `Config.Farm.Debug = true` en `sonar_farm_core/config.lua`
- [ ] Tienes permisos admin para `/sonarfarm:storage:reload`
- [ ] La DB tiene las migraciones 001-009 aplicadas o pendientes

---

## Datos de Configuración

### Silo Grapeseed (S9)

- **Storage ID:** `silo_grapeseed_01`
- **Coords:** `x = 1680.0, y = 4820.0, z = 42.0`
- **Radio de interacción:** 3.0 metros
- **Stash name:** `sonar_farm_silo_silo_grapeseed_01`
- **Capacidad:** 50 slots, 5000 kg

### Molino Pedro (S10)

- **Buyer ID:** `pedro`
- **Coords:** `x = 1682.15, y = 4840.8, z = 42.06`
- **Heading:** 96.43
- **Radio de interacción:** 5.0 metros
- **Ped model:** `s_m_m_farmer_01`
- **Precio base:** €0.80/kg (calidad B)
- **Multiplicadores de calidad:**
  - S: 2.0x
  - A: 1.6x
  - B: 1.0x
  - C: 0.6x
  - D: 0.3x

---

## Pasos QBox Smoke

### Paso 1: Boot del servidor

Inicia `sonar_farm_core` y captura las siguientes líneas del console:

```
[sonar_farm_core] Farm Sonar core booted (v...)
[sonar_farm_core] DB connectivity check and migrations starting
[sonar_farm_core][db] applying migration 008_storage  <-- solo primer boot
[sonar_farm_core][db] applied migration 008_storage   <-- solo primer boot
[sonar_farm_core] DB boot ready: <applied> migrations applied, <already_applied> already applied, <registered> registered
[sonar_farm_core] Finance layer ready -> adapter: <adapter> (mode: <mode>)
[sonar_farm_core] Storage registry boot starting
[sonar_farm_core] Storage registry ready: 1 created, 0 updated, 0 unchanged, 0 skipped, 1 total  <-- fresh boot
[sonar_farm_core][npcs] NPC buyer boot ready: 1 buyers registered
[sonar_farm_core] NPC buyers ready: 1 registered
```

**Evidencia:** Copia estas líneas aquí:
```
[script:sonar_farm_co] [sonar_farm_core] shutting down
[           resources] Stopping resource sonar_farm_core
[    c-scripting-core] Creating script environments for sonar_farm_core
[script:sonar_farm_co] [sonar_farm_core] Bridge initialized → framework: qbox
[script:sonar_farm_co] [sonar_farm_core] Farm Sonar core booted (v0.1.0)
[script:sonar_farm_co] [sonar_farm_core] DB connectivity check and migrations starting
[           resources] Started resource sonar_farm_core
[      script:monitor] [txAdmin] Sending resources list to txAdmin.
[script:sonar_farm_co] [sonar_farm_core][db] applying migration 008_storage
[script:sonar_farm_co] [sonar_farm_core][db] applied migration 008_storage
[script:sonar_farm_co] [sonar_farm_core][db] migrations complete: 1 applied, 8 already applied
[script:sonar_farm_co] [sonar_farm_core] DB boot ready: 1 migrations applied, 8 already applied, 9 registered
[script:sonar_farm_co] [sonar_farm_core] Finance layer ready → adapter: native_bridge (mode: bridge)
[script:sonar_farm_co] [sonar_farm_core] Plot registry boot starting
[script:sonar_farm_co] [sonar_farm_core] Plot registry ready: 0 created, 0 updated, 8 unchanged, 0 skipped, 8 total
[script:sonar_farm_co] [sonar_farm_core][quality] ready
[script:sonar_farm_co] [sonar_farm_core][lifecycle] ready
[script:sonar_farm_co] [sonar_farm_core] [lifecycle] Crop lifecycle ready: 0 active crops
[script:sonar_farm_co] [sonar_farm_core] [lifecycle] Scheduler started (tick: 30s)
[script:sonar_farm_co] [sonar_farm_core] Storage registry boot starting
[script:sonar_farm_co] [sonar_farm_core] Storage registry ready: 1 created, 0 updated, 0 unchanged, 0 skipped, 1 total
[script:sonar_farm_co] [sonar_farm_core][npcs] NPC buyer boot ready: 1 buyers registered
[script:sonar_farm_co] [sonar_farm_core] NPC buyers ready: 1 registered
[script:sonar_farm_co] [sonar_farm_core] debug mode ENABLED
---

### Paso 2: Verificación SQL post-boot

Ejecuta estas queries en tu DB:

```sql
-- Verificar migración 008
SELECT `id`, `name`, `filename`
FROM `sonar_farm_migrations`
WHERE `id` = '008';

-- Verificar storage units
SELECT COUNT(*) AS total
FROM `sonar_farm_storage_units`;

-- Verificar datos del silo
SELECT `storage_id`, `storage_type`, `max_slots`, `max_weight_kg`
FROM `sonar_farm_storage_units`
ORDER BY `storage_id` ASC;
```

**Evidencia esperada:**
- Migration 008 presente
- `total = 1`
- Una fila con `storage_id = 'silo_grapeseed_01'`, `storage_type = 'dry'`

**Evidencia actual:**
```
[PEGAR AQUÍ EL RESULTADO DE LAS QUERIES]
```

---

### Paso 3: Reload command

Ejecuta en chat: `/sonarfarm:storage:reload`

**Output esperado:**
```
═══ Farm Sonar Storage Reload ═══
Created: 0, Updated: 0, Unchanged: 1, Skipped: 0 (Total: 1)
════════════════════════════════
```

**Evidencia actual:**
```
[PEGAR AQUÍ EL OUTPUT DEL COMANDO]
```

---

### Paso 4: Depositar batch en silo

1. Ve a las coords del silo: `1680.0, 4820.0, 42.0`
2. Usa la opción `Deposit Batch` en ox_target
3. Confirma que el stash se abre con ID: `sonar_farm_silo_silo_grapeseed_01`
4. Mueve un `sonar_batch_wheat` desde tu inventario al stash
5. Anota el `batch_id` del item movido (lo ves en el metadata del item)

**Batch ID usado:** `5C9E`

---

### Paso 5: Verificar deposit en DB

Ejecuta estas queries (reemplaza `<batch_id>` con el ID real):

```sql
-- Verificar fila en storage_contents
SELECT `storage_id`, `batch_id`, `player_cid`, `item_name`
FROM `sonar_farm_storage_contents`
WHERE `storage_id` = 'silo_grapeseed_01';

-- Verificar que el batch sigue intacto
SELECT `batch_id`, `sold_ts`, `lineage_chain`, `quality`, `weight_g`
FROM `sonar_farm_batches`
WHERE `batch_id` = '5C9E';
```

**Evidencia esperada:**
- Exactamente 1 fila en `storage_contents` con tu `batch_id`
- `sold_ts IS NULL`
- `lineage_chain` sin cambios

**Evidencia actual:**
```
Batch_id
plot_id
crop_id
player_cid
crop_type
quality
quality_score
weight_g
freshness
lineage_chain
harvested_ts
sold_ts
created_at

Editar Editar
Copiar Copiar
Borrar Borrar
sf-49725c9e
mlo_field_extensive_01
5
QQ4RRAV6
wheat
B
77
2500
100
[]
1779364799
NULL
2026-05-21 13:59:59```

---

### Paso 6: Retirar batch del silo

1. Abre el stash de nuevo
2. Mueve el mismo batch de vuelta a tu inventario
3. Ejecuta esta query:

```sql
SELECT COUNT(*) AS total
FROM `sonar_farm_storage_contents`
WHERE `batch_id` = 'sf-49725c9e';
```

**Evidencia esperada:**
- `total = 0`
- El batch está de vuelta en tu inventario con metadata intacta

**Evidencia actual:**
```
total
0```

---

### Paso 7: Venta a Molino Pedro

1. Ve a las coords de Molino Pedro: `vector4(1682.15, 4840.8, 42.06, 96.43)`
2. Verifica que la opción `Sell Wheat` solo aparece cuando tienes un batch en inventario
3. Usa `Sell Wheat`
4. Espera la progress bar de 3 segundos con label `Unloading...`
5. Captura la notificación de éxito: `+€X.XX — Molino Pedro`

**Evidencia:**
- Screenshot o texto de la notificación: `_________________`
- Monto mostrado: `€ 2.00`

---

### Paso 8: Verificar venta en DB

Ejecuta estas queries:

```sql
-- Verificar sold_ts y lineage
SELECT `batch_id`, `sold_ts`, `lineage_chain`, `quality`, `weight_g`
FROM `sonar_farm_batches`
WHERE `batch_id` = '<batch_id>';

-- Verificar movimiento financiero
SELECT `movement_id`, `account`, `amount`, `reason`, `status`
FROM `sonar_farm_finance_movements`
WHERE `reason` = 'sale:pedro:<batch_id>'
ORDER BY `created_at` DESC
LIMIT 1;
```

**Evidencia esperada:**
- `sold_ts IS NOT NULL`
- `lineage_chain` sin cambios
- Fila en `finance_movements` con:
  - `account = 'bank'`
  - `status = 'completed'`
  - `amount` = payout esperado (base_price × quality_mult × weight_kg)

**Evidencia actual:**
```
batch_id
sold_ts
lineage_chain
quality
weight_g

Editar Editar
Copiar Copiar
Borrar Borrar
sf-49725c9e
1779414473
[]
B
2500

```
movement_id
account
amount
reason
status

Editar Editar
Copiar Copiar
Borrar Borrar
sfm_c000c82a_f11b6b58
bank
2.00
sale:pedro:sf-49725c9e
completed

---

### Paso 9: Verificar inventario post-venta

- [ ] El `sonar_batch_wheat` ya no está en tu inventario
- [ ] No hay fila en `sonar_farm_storage_contents` para ese `batch_id`

---
confirmo 

### Paso 10: Test negativo (capacidad)

1. Llena el silo hasta su capacidad (50 slots o 5000 kg)
2. Intenta depositar un batch extra
3. Ejecuta:

```sql
SELECT COUNT(*) AS total
FROM `sonar_farm_storage_contents`
WHERE `storage_id` = 'silo_grapeseed_01';
```

**Evidencia esperada:**
- El deposito es rechazado
- `total` no aumenta después del intento

**Evidencia actual:**
```
[PEGAR AQUÍ EL RESULTADO]
```

---

## Pasos QBCore Smoke

Repite los pasos 1-10 con el stack QBCore activo.

**Framework detectado:** `_________________`

**Nota:** B2 no tiene llamadas directas a QBCore, todo va por el bridge. Si falla, es un problema del bridge o load-order, no de B2.

---

## Checklist Final

### QBox

- [ ] Boot console lines capturadas
- [ ] Migration 008 aplicada/registrada
- [ ] Storage unit seeded (1 total, silo_grapeseed_01)
- [ ] `/sonarfarm:storage:reload` output correcto
- [ ] Deposit inserta audit row
- [ ] Withdraw elimina audit row
- [ ] Molino Pedro visible solo con batch
- [ ] Sale stamps sold_ts, preserva lineage
- [ ] Finance movement creado con amount correcto
- [ ] Success notify muestra monto correcto
- [ ] Capacity rejection funciona

### QBCore

- [ ] Mismos 11 checks que QBox

---

## Reporte de Resultados

**Framework:** QBox / QBCore
**Fecha:** _______________
**Resultado global:** PASS / FAIL

**Observaciones:**
```
[ESCRIBIR AQUÍ CUALQUIER PROBLEMA O ANOMALÍA]
```
