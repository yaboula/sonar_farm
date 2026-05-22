# Guía runtime QA — B3 Factor Activation

## Objetivo

Esta guía sirve para ejecutar y verificar manualmente el bundle **B3 — Factor Activation**:

- S13 — Irrigation
- S14 — Fertilization
- S15 — Pests

Incluye:

- pasos exactos de smoke test,
- comandos y SQL necesarios,
- datos que debes preparar antes,
- referencias reales del proyecto para validar que `peds`, `props`, `particles`, `plots` y demás IDs estén correctos.

---

## 1. Qué necesitas antes de empezar

## 1.1 Recursos que deben estar arrancados

Asegúrate de tener activos al menos estos recursos:

- `oxmysql`
- `ox_lib`
- `ox_inventory`
- `ox_target`
- `sonar_farm_core`

## 1.2 Config mínima necesaria

Archivo: `sonar_farm_core/config.lua`

Valores importantes:

```lua
Config.Farm.Debug = true
Config.Farm.Scheduler = { TickSeconds = 30 }
```

## 1.3 Comandos debug disponibles

Debes poder usar:

- `/sonarfarm:debug:fastforward <plot_id> <hours>`
- `/sonarfarm:debug:pest <plot_id> <pest_type>`

Y normalmente necesitarás también comandos del framework/inventario como:

- `/giveitem <src> sonar_water_tank 1`
- `/giveitem <src> sonar_fertilizer_npk 1`
- `/giveitem <src> sonar_fertilizer_k 1`
- `/giveitem <src> sonar_pesticide_contact 1`
- `/giveitem <src> sonar_pesticide_systemic 1`

## 1.4 Permisos

Necesitas ACE admin para los comandos debug.

Ejemplo en `server.cfg`:

```cfg
add_ace group.admin sonar.farm.admin allow
```

---

## 2. Datos que necesitas tener a mano

## 2.1 Tu `source`

Necesitas saber tu `source` para usar `/giveitem <src> ...`.

## 2.2 Un plot válido

Para B3 lo más simple es usar un plot extensivo de trigo.

Plots extensivos definidos en `sonar_farm_core/config/plots.lua`:

- `mlo_field_extensive_01`
- `mlo_field_extensive_02`
- `mlo_field_extensive_03`
- `mlo_field_extensive_04`

El más útil para smoke inicial:

- `mlo_field_extensive_01`

## 2.3 Acceso a la base de datos

Necesitas poder ejecutar consultas SQL sobre:

- `sonar_farm_migrations`
- `sonar_farm_crops`
- `sonar_farm_quality_tracking`
- `sonar_farm_batches`
- `sonar_farm_plots`

---

## 3. Checklist de boot antes del smoke

Cuando arranca `sonar_farm_core`, revisa consola y confirma estas líneas:

- `[sonar_farm_core] Farm Sonar core booted (v...)`
- `[sonar_farm_core] DB connectivity check and migrations starting`
- `[sonar_farm_core] DB boot ready: ...`
- `[sonar_farm_core] Finance layer ready → adapter: ...`
- `[sonar_farm_core] Plot registry ready: ...`
- `[sonar_farm_core][quality] ready`
- `[sonar_farm_core] [lifecycle] Crop lifecycle ready: ...`
- `[sonar_farm_core] [lifecycle] Scheduler started (tick: 30s)`
- `[sonar_farm_core][pests] ready: 3 pest-susceptible crops configured`
- `[sonar_farm_core] debug mode ENABLED`

Además, verifica migración B3:

```sql
SELECT `id`, `name`, `filename`
  FROM `sonar_farm_migrations`
 WHERE `id` = '011';
```

Esperado:

- una fila para `011_pest_severity.sql`

---

## 4. Smoke test completo B3

## 4.1 Preparación del cultivo

1. Planta trigo en un plot extensivo.
2. Usa preferiblemente:

```text
plot_id = mlo_field_extensive_01
```

3. Verifica que el cultivo existe:

```sql
SELECT `plot_id`, `crop_type`, `stage`, `next_stage_ts`
  FROM `sonar_farm_crops`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

4. Verifica fila de quality tracking:

```sql
SELECT `plot_id`, `soil_score`, `irrigation`, `pest_impact`, `weather_match`, `seed_quality`, `fertilization`, `harvest_timing`, `next_irrigation_due_ts`, `pest_detected_ts`, `pest_severity`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

---

## 4.2 S13 — Irrigation

## Paso A — Dar tanque

```text
/giveitem <src> sonar_water_tank 1
```

## Paso B — Regar una vez

En mundo:

- `ox_target` sobre el plot
- opción: `Water crop`

## Paso C — Verificar SQL

```sql
SELECT `plot_id`, `irrigation`, `next_irrigation_due_ts`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- `irrigation` sube por encima de `70`
- `next_irrigation_due_ts` queda sincronizado con `sonar_farm_crops.next_stage_ts`

## Paso D — Overwater

Riega dos veces más en la misma stage.

Vuelve a consultar:

```sql
SELECT `plot_id`, `irrigation`, `next_irrigation_due_ts`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- el score deja de subir y debe penalizar por `overwater`

## Paso E — Refill

Ve al punto de refill y usa:

- `Refill tank`

No siempre verás esto directo en SQL, porque la carga vive en metadata del item.

Lo que debes validar:

- el target aparece,
- la acción termina,
- el tanque vuelve a `charges = 5`.

---

## 4.3 S14 — Fertilization

## Paso A — Dar fertilizantes

```text
/giveitem <src> sonar_fertilizer_npk 2
/giveitem <src> sonar_fertilizer_k 1
```

## Paso B — Aplicar el correcto

En trigo, aplica:

- `sonar_fertilizer_npk`

Consulta:

```sql
SELECT `plot_id`, `fertilization`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- `fertilization > 70`

## Paso C — Aplicar el incorrecto

Aplica:

- `sonar_fertilizer_k`

Consulta de nuevo la misma fila.

Esperado:

- pequeña penalización o caída respecto al caso correcto

## Paso D — Over-fertilize

Aplica otra vez un fertilizante correcto en la misma stage.

Consulta:

```sql
SELECT `plot_id`, `fertilization`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- el valor cae al `overfertilize_floor`

---

## 4.4 S15 — Pests

## Paso A — Llevar el cultivo a stage válida

B3 evalúa plagas entre stage `1` y `3`.

Si hace falta:

```text
/sonarfarm:debug:fastforward mlo_field_extensive_01 12
```

Luego revisa:

```sql
SELECT `plot_id`, `stage`, `next_stage_ts`
  FROM `sonar_farm_crops`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

## Paso B — Spawnear plaga

```text
/sonarfarm:debug:pest mlo_field_extensive_01 blight
```

Consulta:

```sql
SELECT `plot_id`, `pest_detected_ts`, `pest_severity`, `pest_impact`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- `pest_detected_ts` no es `NULL`
- `pest_severity = 'detected'`

Y visualmente:

- debe aparecer el efecto de plaga sobre el plot

## Paso C — Tratar plaga

```text
/giveitem <src> sonar_pesticide_contact 1
```

En mundo:

- `ox_target` sobre el plot
- opción: `Treat pest`

Consulta:

```sql
SELECT `plot_id`, `pest_detected_ts`, `pest_severity`, `pest_impact`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- `pest_detected_ts = NULL`
- `pest_severity = 'none'`
- `pest_impact` sube
- el efecto visual desaparece

## Paso D — Severe pest

1. Spawnea otra vez la plaga.
2. No la trates.
3. Deja pasar el tiempo necesario o fuerza el escenario para superar `severity_hours`.

Consulta:

```sql
SELECT `plot_id`, `pest_detected_ts`, `pest_severity`, `pest_impact`
  FROM `sonar_farm_quality_tracking`
 WHERE `plot_id` = 'mlo_field_extensive_01';
```

Esperado:

- `pest_severity = 'severe'`

---

## 4.5 Quality integration check

## Bad run

Haz este flujo:

- no regar,
- fertilizante incorrecto,
- plaga sin tratar,
- cosechar.

Consulta batch final:

```sql
SELECT `batch_id`, `plot_id`, `quality`, `quality_score`, `weight_g`, `freshness`
  FROM `sonar_farm_batches`
 WHERE `plot_id` = 'mlo_field_extensive_01'
 ORDER BY `harvested_ts` DESC
 LIMIT 1;
```

## Good run

Haz este flujo:

- riego correcto,
- fertilizante correcto,
- plaga tratada,
- cosechar.

Misma consulta SQL.

## Nota importante

Con la config actual hay un riesgo real:

- los pesos de calidad están uniformes,
- entonces el `bad run` puede terminar todavía en `B`,
- especialmente si no entra también la degradación offline de S11.

Pesos actuales en `sonar_farm_core/config.lua`:

```lua
soil = 1.0,
irrigation = 1.0,
pest_impact = 1.0,
weather_match = 1.0,
seed_quality = 1.0,
fertilization = 1.0,
harvest_timing = 1.0,
```

---

## 5. Referencias reales para verificar IDs

## 5.1 Peds

### Buyer NPC configurado

Archivo: `sonar_farm_core/config/npcs.lua`

- **buyer_id:** `pedro`
- **ped_model:** `a_m_m_farmer_01`
- **coords:** `1682.15, 4840.8, 42.06`
- **heading:** `96.43`
- **interaction_radius:** `5.0`

## Qué validar en runtime

- el ped aparece,
- no aparece invisible,
- no aparece en T-pose,
- tiene target de venta,
- la referencia del modelo carga sin error en consola.

## Nota

En `tests/server/sale_spec.lua` aparece `s_m_m_farmer_01`, pero eso es test fixture, no canon runtime.

El valor canónico runtime actual es:

- `a_m_m_farmer_01`

---

## 5.2 Props de cultivos verificados

Archivo canónico: `sonar_farm_core/config/verified_props.lua`

### Wheat

- Stage 0: `prop_veg_grass_01_a`
- Stage 1: `prop_veg_grass_01_b`
- Stage 2: `prop_veg_grass_01_c`
- Stage 3: `prop_veg_crop_06`
- Stage 4: `prop_veg_crop_06`
- Cooldown: `prop_veg_crop_04`

### Corn

- Stage 0: `prop_veg_corn_01`
- Stage 1: `prop_veg_corn_01`
- Stage 2: `prop_veg_corn_01`
- Stage 3: `prop_veg_corn_01`
- Stage 4: `prop_veg_corn_01`
- Cooldown: `prop_veg_crop_04`

### Barley

- Stage 0: `prop_plant_cane_01a`
- Stage 1: `prop_plant_cane_01a`
- Stage 2: `prop_plant_cane_01b`
- Stage 3: `prop_plant_cane_01b`
- Stage 4: `prop_plant_cane_01b`
- Cooldown: `prop_veg_crop_04`

## Qué validar

- que el prop realmente existe en juego,
- que no flota,
- que no queda enterrado,
- que el cambio de stage cambia visualmente el prop correcto,
- que el cooldown usa `prop_veg_crop_04`.

---

## 5.3 Particle FX de plagas

Archivo: `sonar_farm_core/client/pest_interactions.lua`

- **PARTICLE_DICT:** `core`
- **PARTICLE_EFFECT:** `exp_grd_bzgas_cloud`
- **offset Z:** `+0.2`
- **scale:** `0.8`

## Qué validar

- aparece al detectar plaga,
- desaparece al tratar,
- no duplica handles,
- no queda permanente tras reinicio del recurso,
- no está demasiado alto o demasiado bajo.

---

## 5.4 Wells / refill points

Archivo: `sonar_farm_core/config/irrigation.lua`

Punto actual:

- `x = 1670.0`
- `y = 4815.0`
- `z = 42.0`
- `radius = 2.5`

## Importante

Ahora mismo hay **coords de well**, pero no hay un `prop_model` configurado para el pozo en B3.

Eso significa:

- sí puedes validar la zona de interacción,
- pero **no existe todavía una referencia canónica de prop para el well** en este bundle.

---

## 5.5 Plots y anchors

Archivo: `sonar_farm_core/config/plots.lua`

### Extensivos

- `mlo_field_extensive_01` → `1952.91, 4770.65, 42.76`, radius `1.5`
- `mlo_field_extensive_02` → `2080.0, 4790.0, 41.0`, radius `28.0`
- `mlo_field_extensive_03` → `2010.0, 4860.0, 41.0`, radius `28.0`
- `mlo_field_extensive_04` → `2080.0, 4860.0, 41.0`, radius `28.0`

### Horticultural

- `mlo_plot_horticultural_01` → `1960.0, 4920.0, 41.0`, radius `10.0`
- `mlo_plot_horticultural_02` → `1980.0, 4920.0, 41.0`, radius `10.0`
- `mlo_plot_horticultural_03` → `2000.0, 4920.0, 41.0`, radius `10.0`

### Greenhouse

- `mlo_greenhouse_01` → `1930.0, 4960.0, 41.0`, radius `12.0`

## Qué validar

- la zona de `ox_target` cae donde toca,
- no está desalineada con el suelo,
- el radius no es demasiado pequeño ni demasiado grande,
- el particle de pest cae sobre el anchor correcto.

---

## 5.6 Ítems B3

Archivo: `sonar_farm_core/config/items.lua`

### Irrigation

- `sonar_water_tank`
  - weight: `2000`
  - stack: `false`
  - metadata inicial: `{ charges = 5 }`

### Fertilization

- `sonar_fertilizer_n`
- `sonar_fertilizer_p`
- `sonar_fertilizer_k`
- `sonar_fertilizer_npk`

Todos:

- weight: `1000`
- stack: `true`

### Pesticides

- `sonar_pesticide_contact`
- `sonar_pesticide_systemic`

Ambos:

- weight: `500`
- stack: `true`

## Qué validar

- existen en inventario,
- tienen label correcto,
- el tanque guarda `charges`,
- fertilizantes y pesticidas se consumen al usar,
- el tanque no se consume, solo muta metadata.

---

## 5.7 Animaciones B3

Archivo: `sonar_farm_core/config.lua`

Todas las acciones B3 usan actualmente:

- **dict:** `amb@world_human_gardener_plant@male@base`
- **clip:** `base`
- **flag:** `49`

Duraciones:

- `water = 10000`
- `refill = 5000`
- `fertilize = 8000`
- `treat_pest = 12000`

## Qué validar

- la animación carga,
- no se corta incorrectamente,
- se puede cancelar,
- al cancelar no queda el ped bloqueado.

---

## 5.8 Vehículos

## Estado actual en B3

En el código runtime de `sonar_farm_core` para B3:

- **no hay vehículos específicos configurados o usados directamente** para el bundle B3.
- El riego en B3 usa item `sonar_water_tank`, no vehículo cisterna.

## Referencias de catálogo útiles para futuro

Del catálogo de assets (`docs/Catálogo-de-Assets-y-Referencias/CATALOGO_COMPLETO.md`), los más relevantes para futuro agrícola/logístico son:

### Tractores

- `tractor`
- `tractor2`
- `tractor3`

### Pickups / utilitarios

- `sadler`
- `sadler2`
- `bison`
- `bison3`
- `bobcatxl`
- `utillitruck`
- `utillitruck2`

### Trailers / cisternas

- `baletrailer`
- `raketrailer`
- `trailersmall`
- `flat`
- `trailers`
- `trailers2`
- `armytanker`
- `tanker`
- `docktrailer`

### Aéreo / fumigación

- `duster`
- `maverick`
- `frogger`
- `rcbandito`

## Importante

Estos vehículos están en el catálogo documental, pero **no forman parte del wiring runtime actual de B3**.

---

## 6. Tabla rápida de validación visual

| Tipo | Referencia canónica | Estado esperado |
| ---- | ------------------- | --------------- |
| Ped buyer | `a_m_m_farmer_01` | Spawnea correctamente |
| Particle pest dict | `core` | Carga sin error |
| Particle pest effect | `exp_grd_bzgas_cloud` | Visible al aparecer plaga |
| Well coords | `1670.0, 4815.0, 42.0` | Zona interactiva funcional |
| Wheat stage 0 | `prop_veg_grass_01_a` | Visible en planted |
| Wheat cooldown | `prop_veg_crop_04` | Visible tras harvest/cooldown |
| Corn prop | `prop_veg_corn_01` | Visible en stages de maíz |
| Barley prop | `prop_plant_cane_01a/b` | Visible en stages de cebada |
| Water tank item | `sonar_water_tank` | Metadata `charges` correcta |
| Correct wheat fertilizer | `sonar_fertilizer_npk` / `sonar_fertilizer_n` | Mejora score |
| Pest treatment item | `sonar_pesticide_contact` | Limpia plaga |

---

## 7. Gaps detectados ahora mismo

Estos son gaps reales para que no pierdas tiempo buscando algo que aún no existe:

- **No hay `prop_model` canónico para el well** en B3. Solo hay coordenadas de refill.
- **No hay vehículos configurados en runtime para B3**. Todo el bundle opera con item/tooling e interacciones físicas sobre plot.
- **El quality bad run no está garantizado en `C/D`** con los pesos actuales uniformes; eso hay que verificar en runtime con SQL.

---

## 8. Recomendación práctica para tu validación

Haz las pruebas en este orden:

1. boot + migración `011`
2. irrigación
3. fertilización
4. pest detect / treat / severe
5. quality integration bad run
6. quality integration good run
7. buyer ped `pedro`
8. verificación visual final de props/particle/zones

---

## 9. Resultado que deberías registrar

Cuando termines, guarda para cada prueba:

- screenshot o clip corto,
- 1 query SQL antes,
- 1 query SQL después,
- resultado esperado,
- resultado real,
- PASS / FAIL.

Si quieres, el siguiente paso te lo puedo dejar también en otro `.md` como **plantilla rellenable de reporte QA** para que solo vayas copiando resultados durante la prueba.
