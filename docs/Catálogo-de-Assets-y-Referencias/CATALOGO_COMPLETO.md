# 🚜 Catálogo de Assets y Referencias (Farm Sonar)

**Documento Vivo:** Este catálogo contiene todos los identificadores nativos (Hashes y Spawn Names) del motor de GTA V / FiveM seleccionados para el ecosistema de Farm Sonar. Los datos aquí listados se utilizan directamente en los archivos de configuración (`config/vehicles.lua`, `config/crops.lua`, etc.).

---

## Índice de Contenidos

- [CAPÍTULO 1 — La Tierra y las Plantas](#capítulo-1--la-tierra-y-las-plantas)
  - [1.1 — Terreno y Abono](#11--terreno-y-abono-preparación-de-parcelas)
  - [1.2 — Cultivos Extensivos](#12--cultivos-extensivos-cereales-y-forraje)
  - [1.3 — Cultivos Hortícolas](#13--cultivos-hortícolas-verduras-bulbos-y-frutos)
  - [1.4 — Malezas, Plagas y Decaimiento](#14--malezas-plagas-y-decaimiento)
- [CAPÍTULO 2 — Maquinaria y Vehículos](#capítulo-2--maquinaria-y-vehículos)
  - [2.1 — Tractores y Vehículos de Trabajo Pesado](#21--tractores-y-vehículos-de-trabajo-pesado)
  - [2.2 — Remolques y Cisternas](#22--remolques-y-cisternas-trailers)
  - [2.3 — Maquinaria Industrial y Logística](#23--maquinaria-industrial-y-logística)
  - [2.4 — Aplicaciones Aéreas](#24--aplicaciones-aéreas-drones-y-fumigación)
  - [2.5 — Add-ons Comunitarios](#25--add-ons-comunitarios-recomendados)
- [CAPÍTULO 3 — Infraestructura, Procesamiento y Almacenamiento](#capítulo-3--infraestructura-procesamiento-y-almacenamiento)
  - [3.1 — Estructuras de Almacenamiento](#31--estructuras-de-almacenamiento-silos-y-bodegas)
  - [3.2 — Estaciones de Procesamiento](#32--estaciones-de-procesamiento)
  - [3.3 — Logística de Carga](#33--logística-de-carga-pallets-y-contenedores)
  - [3.4 — Infraestructura de Riego y Servicios](#34--infraestructura-de-riego-y-servicios)
  - [3.5 — Props Especiales](#35--props-especiales-altamente-recomendados)
  - [3.6 — Recomendaciones Técnicas FiveM](#36--recomendaciones-técnicas-five-m)
  - [3.7 — Herramientas de Datamining](#37--herramientas-de-datamining-recomendadas)
- [CAPÍTULO 4 — Infraestructura de Servicios](#capítulo-4--infraestructura-de-servicios-energía-riego-y-automatización)
  - [4.1 — Red de Agua e Irrigación](#41--red-de-agua-e-irrigación)
  - [4.2 — Infraestructura Eléctrica](#42--infraestructura-eléctrica)
  - [4.3 — Iluminación Agrícola](#43--iluminación-agrícola)
  - [4.4 — Efectos de Partículas](#44--efectos-de-partículas-ptfx-de-servicio)
- [CAPÍTULO 5 — Locaciones y MLOs](#capítulo-5--locaciones-y-mlos-foco-principal-grapeseed)
  - [5.1 — Parcelas Nativas](#51--parcelas-nativas-campos-abiertos)
  - [5.2 — Zonas Logísticas](#52--zonas-logísticas-y-almacenaje-nativo)
  - [5.3 — Interiores (MLOs)](#53--interiores-mlos-para-la-sede-central)
  - [5.4 — Puntos de Venta](#54--puntos-de-venta-npc-vendors)

---

# CAPÍTULO 1 — LA TIERRA Y LAS PLANTAS

Colección de props estáticos y trucos de manipulación espacial (Z-offset, escalas) para simular el ciclo de vida agrícola usando assets nativos de GTA V.

## 1.1 — TERRENO Y ABONO (Preparación de parcelas)

| Nombre | Spawn Name | Hash Numérico | Notas Técnicas y Ajustes Espaciales |
|--------|------------|---------------|--------------------------------------|
| Tierra removida pequeña | prop_veg_crop_01 | -1007446468 | Colisión blanda. Perfecto como surco inicial si se hunde Z -0.15. |
| Tierra removida mediana | prop_veg_crop_02 | 649223100 | Colisión leve. Buena para filas agrícolas visibles desde distancia. |
| Tierra madura / grande | prop_veg_crop_04 | -383623015 | Colisión parcial. LOD estable. |
| Hojas separadas (Filler) | prop_veg_crop_04_leaf | -1163697832 | Usar overlay sobre tierra. Sin colisión relevante. |
| Parcela húmeda / Barro | prop_veg_crop_05 | -83295126 | Ideal como barro húmedo o tierra recién regada. |
| Tierra irregular (Ruptura) | prop_veg_crop_06 | 955777091 | Mezclar con barro. Buena ruptura visual. |
| Saco de abono roto | prop_conc_sacks_02a | N/D | Hundir Z -0.8 para dejar visible solo polvo/tierra. |
| Charco barro agrícola | prop_mud_wash_01 | N/D | Sin colisión. Excelente para simular riego excesivo. |
| Montículo de compost | prop_rub_pile_01 | N/D | Escalar 0.6. Funciona como compost orgánico improvisado. |
| Tierra seca agrietada | prop_grass_dry_02 | N/D | Excelente overlay para representar sequía. |
| Tierra seca avanzada | prop_grass_dry_03 | N/D | Mezclar con weeds muertos para campos marchitos. |

## 1.2 — CULTIVOS EXTENSIVOS (Cereales y Forraje)

| Cultivo / Etapa | Spawn Name | Hash Numérico | Notas Técnicas y Ajustes Espaciales |
|-----------------|------------|---------------|--------------------------------------|
| Trigo (Brote pequeño) | prop_veg_grass_01_a | -62459927 | Sin colisión. Excelente densidad. |
| Trigo (Crecimiento medio) | prop_veg_grass_01_b | -1634847635 | Buen volumen lateral. |
| Trigo (Cultivo alto) | prop_veg_grass_01_c | -1933078304 | Puede tapar piernas del jugador. |
| Trigo (Maduro / Seco) | prop_veg_grass_01_d | 52002182 | Ideal para cosecha final. |
| Pasto disperso (Filler) | prop_veg_grass_02_a | -1180346286 | Excelente filler entre filas. |
| Maíz (Pequeño) | prop_veg_corn_01 | -2098052468 | Colisión ligera. Escalar 0.7 para brote. |
| Maíz (Mediano) | prop_veg_corn_01 | -2098052468 | Escala 1.0 estándar. |
| Maíz (Maduro / Alto) | prop_veg_corn_01 | -2098052468 | Escala 1.25–1.4. Puede bloquear visión. |
| Maíz (Campo Seco) | prop_grass_dry_03 | N/D | Mezclar 20% con maíz maduro. |
| Cebada / Forraje Fino | prop_plant_cane_01a | N/D | Excelente como forraje fino. |
| Cebada (Densa) | prop_plant_cane_01b | N/D | Variante más densa. |
| Hierba Alta (Salvaje) | prop_plant_cane_02a | N/D | Buena para campos salvajes. |
| Forraje para Zanjas | prop_cat_tail_01 | N/D | Ideal para zonas húmedas. |

## 1.3 — CULTIVOS HORTÍCOLAS (Verduras, Bulbos y Frutos)

| Cultivo | Spawn Name | Hash Numérico | Notas Técnicas y Ajustes Espaciales |
|---------|------------|---------------|--------------------------------------|
| Repollo pequeño | prop_veg_crop_02 | 649223100 | Escalar 0.55. |
| Repollo maduro | prop_veg_crop_04_leaf | -1163697832 | Mezclar varias rotaciones para naturalidad. |
| Lechuga compacta | prop_plant_clover_01 | N/D | Hundir Z -0.05. |
| Lechuga abierta | prop_plant_clover_02 | N/D | Buena variación visual. |
| Calabaza pequeña | prop_veg_crop_05 | -83295126 | Añadir pumpkin prop encima. |
| Calabaza madura | prop_veg_crop_orange | 2007502834 | Excelente asset nativo agrícola. |
| Tomatera pequeña | prop_bush_med_01 | N/D | Base estructural. Escalar 0.45. |
| Tomates (Fruto rojo) | prop_plant_flower_02 | N/D | Insertar parcialmente dentro del arbusto base. |
| Pimientos verdes | prop_plant_flower_01 | N/D | Escala 0.7 sobre arbusto base. |
| Pimientos rojos | prop_plant_flower_03 | N/D | Rotación aleatoria recomendada sobre base. |
| Patatas (Enterradas) | h4_prop_weed_01_plant | N/D | Hundir Z -0.45. Solo hojas visibles a ras de suelo. |
| Cebollas pequeñas | prop_plant_01a | N/D | Hundir Z -0.35. |
| Cebollas maduras | prop_plant_01b | N/D | Buen volumen para cultivo denso. |
| Tubérculo seco | prop_bush_dead_02 | N/D | Excelente para cosecha olvidada o arruinada. |

## 1.4 — MALEZAS, PLAGAS Y DECAIMIENTO

| Efecto Visual | Spawn Name | Hash Numérico | Notas Técnicas y Ajustes Espaciales |
|----------------|------------|---------------|--------------------------------------|
| Helecho pequeño (Maleza) | prop_plant_fern_01a | N/D | Sin colisión. |
| Helecho denso (Maleza) | prop_plant_fern_01b | N/D | Excelente para ensuciar bordes de parcelas. |
| Maleza húmeda | prop_plant_fern_02a | N/D | Mezclar con barro. |
| Maleza invasiva | prop_plant_fern_02b | N/D | Escalar aleatoriamente. |
| Hierbajo seco | prop_bush_dead_02 | N/D | Perfecto para abandono agrícola. |
| Planta seca (Necrosis) | prop_coral_kelp_03d | N/D | Entrelazar dentro del cultivo vivo (efecto alga enferma). |
| Alga seca quebrada | prop_coral_sweed_01 | N/D | Excelente overlay de enfermedad mortal. |
| Hojas podridas | prop_coral_sweed_02 | N/D | Escalar 0.5–0.8. |
| Sequía extrema | prop_grass_dry_03 | N/D | Mezclar con malezas muertas. |

---

# CAPÍTULO 2 — MAQUINARIA Y VEHÍCULOS

Flota de vehículos funcionales, remolques y maquinaria pesada pre-aprobada para la simulación agrícola y logística.

## 2.1 — TRACTORES Y VEHÍCULOS DE TRABAJO PESADO

| Vehículo | Spawn Name | Hash Numérico | Enganche (Tow Hitch) | Asientos | Notas Técnicas |
|----------|------------|---------------|----------------------|----------|-----------------|
| Tractor oxidado clásico | tractor | 1641462412 | ❌ Limitado | 1 | Muy lento. Alto torque. Suspensión rígida. Tiende a perder estabilidad cuesta abajo. |
| Fieldmaster agrícola | tractor2 | 218488798 | ✅ Completo | 1 | Mejor tractor agrícola vanilla. Compatible nativamente con graintrailer, baletrailer, raketrailer. Muy estable. |
| Fieldmaster nieve | tractor3 | 1445631933 | ✅ Completo | 1 | Variante rural desgastada. Excelente torque. Suspensión alta. Menos estable en curvas rápidas. |
| Pickup agrícola | sadler | -599568815 | ✅ Parcial | 2 | Muy usada en mapas rurales RP. Buena tracción. Ideal para trailers pequeños. |
| Pickup agrícola (herramientas) | sadler2 | 734217681 | ✅ Parcial | 2 | Variante con equipamiento en caja trasera. |
| Pickup ranchera | bison | -16948145 | ✅ Parcial | 4 | Buena suspensión off-road. Remolca trailers ligeros sin problemas. |
| Pickup ranchera doble | bison3 | 22072156101 | ✅ Parcial | 4 | Más estable que bison. Buena para logística agrícola en cuadrillas. |
| Pickup utilitaria | bobcatxl | 1069929536 | ✅ Parcial | 2 | Compacta. Ideal para granjas pequeñas y movimiento rápido en almacenes. |
| Camión utilitario | utillitruck | 516990260 | ❌ No | 2 | Excelente para mantenimiento eléctrico (WOOOW Tech) y zonas de cultivo técnico. |
| Camión utilitario variante | utillitruck2 | 887537515 | ❌ No | 2 | Variante landscaping. Muy buena estética rural. |
| Vehículo portuario arrastre | docktug | 3410276810 | ✅ Industrial | 1 | Puede mover trailers pesados. Muy corto y maniobrable. Excelente para almacenes y silos. |
| Grúa compacta | towtruck | 23852654278 | ✅ Especial | 2 | Estable en caminos rurales. Útil para mecánicas de recuperación de maquinaria. |

## 2.2 — REMOLQUES Y CISTERNAS (TRAILERS)

| Remolque | Spawn Name | Hash Numérico | Compatible con | Notas Técnicas |
|----------|------------|---------------|----------------|-----------------|
| Remolque de fardos | baletrailer | 3895125590 | tractor2, pickups | Mejor trailer vanilla agrícola. Perfecto para cargar fardos de heno y pallets. |
| Remolque de rastrillo | raketrailer | 390902130 | tractor2 | Muy útil visualmente para roleplay de arado/cosecha base. |
| Remolque pequeño obra | trailersmall | 712162987 | Pickups | Excelente para transportar semillas, cajas o herramientas manuales. |
| Remolque plano | flat | 2942498482 | Camiones, pickups | Ideal para pallets industriales, fertilizantes en masa y maquinaria pequeña. |
| Trailer comercial lona | trailers | 3417488910 | Camiones | Útil para transportar productos agrícolas empaquetados hacia el NPC vendedor. |
| Trailer comercial caja | trailers2 | 2715434129 | Camiones | Buena opción para logística alimentaria y contratos B2B. |
| Cisterna militar | armytanker | 3087536137 | Camiones | Excelente para simular transporte de fertilizante líquido masivo o agua para riego. |
| Cisterna civil | tanker | 3564062519 | Camiones | Ideal para sistemas de agua pura o derivados. |
| Trailer contenedor puerto | docktrailer | 2154757102 | docktug | Perfecto para operaciones de logística intensiva en el almacén de la granja. |

## 2.3 — MAQUINARIA INDUSTRIAL Y LOGÍSTICA

| Vehículo | Spawn Name | Hash Numérico | Funcionalidad | Notas Técnicas |
|----------|------------|---------------|---------------|-----------------|
| Carretilla elevadora | forklift | 1491375716 | Elevación funcional | Forks funcionales reales. Obligatoria para manejo de pallets en almacenes y silos. |
| Bulldozer (Dozer) | dozer | -1006919392 | Empuje físico | Muy pesado. Excelente para simular preparación extrema de terrenos rurales. |
| Excavadora túnel | cutter | 3288047904 | Decorativa | Ideal visualmente para zonas de procesamiento técnico. |
| Camión volquete (Dump) | dump | 2164484578 | Volcado | Capacidad inmensa. Muy útil para mover toneladas de tierra, grava o fertilizante base. |
| Camión escombros | rubble | -1705304628 | Carga pesada | Excelente para movimiento de tierras sin el tamaño extremo del Dump. |
| Tractor industrial | airtug | 1560980623 | Arrastre ligero | Muy útil para interiores de invernaderos o almacenes compactos (cero emisiones visuales). |

## 2.4 — APLICACIONES AÉREAS (DRONES Y FUMIGACIÓN)

| Aeronave | Spawn Name | Hash Numérico | Aplicación (S28-S29) | Notas Técnicas |
|----------|------------|---------------|----------------------|-----------------|
| Avión fumigador | duster | 970356638 | Fumigación aérea | El mejor vehículo vanilla para WOOOW Tech aéreo. Vuelo excepcionalmente lento y estable para aspersión. |
| Helicóptero ligero | maverick | -1660661558 | Supervisión | Muy útil para transporte de agrónomos o monitoreo a gran escala. |
| Helicóptero compacto | frogger | 744705981 | Patrulla agrícola | Perfil de aterrizaje estrecho, fácil de posar en granjas pequeñas o caminos de tierra. |
| Drone Terrestre RC | rcbandito | -286046740 | Escaneo / Inspección | Utilizable lógicamente como sonda terrestre para análisis de suelos (probe variant). |
| Drone Aéreo Funcional | [Requiere Add-on] | — | Escaneo Térmico/Plagas | GTA V vanilla NO incluye drones aéreos de libre vuelto funcionales; requiere implementación de cámara custom o script. |

## 2.5 — ADD-ONS COMUNITARIOS (RECOMENDADOS)

Para cubrir deficiencias en las mecánicas nativas (opcional según servidor):

- **John Deere Tractor Pack:** Cubre la falta de maquinaria de última generación.
- **Realistic Combine Harvester:** Para añadir cosechadoras masivas (inexistentes en vanilla).
- **FS19 Trailer Pack / PJ Gooseneck:** Para colisiones perfectas al cargar tractores en remolques.
- **Drone Camera Script:** Imprescindible si no se usa scaleform custom para WOOOW Tech (S28).

---

# CAPÍTULO 3 — INFRAESTRUCTURA, PROCESAMIENTO Y ALMACENAMIENTO

### Farm Sonar — Catálogo Técnico de Assets Nativos GTA V / FiveM

> Objetivo: construir un pipeline agrícola completo usando únicamente props nativos de GTA V para minimizar streaming, consumo RAM y carga de red.

## 3.1 — ESTRUCTURAS DE ALMACENAMIENTO (SILOS Y BODEGAS)

### SILOS INDUSTRIALES

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Silo metálico grande | prop_silo_01 | N/D | SÍ | Excelente para farms grandes tipo Grapeseed. Escala correcta para trailers y maquinaria pesada. Hundir Z -0.08 para evitar "floating edge". Funciona bien como almacenamiento de trigo/maíz. Ideal combinar con decals de polvo y grain spill. |
| Silo industrial alto | prop_silo_02 | N/D | SÍ | Muy visible a distancia → buen landmark. LOD eficiente. Recomendado usar en grupos de 2-4. Añadir pipes laterales para mayor realismo. |
| Silo pequeño rural | prop_wheat_sack_01 | N/D | NO | Fake silo visual para interiores. Usar como detalle decorativo en graneros. |

### GRANEROS Y COBERTIZOS

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Cobertizo rural abierto | prop_farm_shed_01 | N/D | PARCIAL | Vehículos pequeños pueden entrar parcialmente. Ideal para guardar tractores. Elevar Z +0.02 si atraviesa terreno irregular. |
| Granero de madera | prop_barn_01 | N/D | SÍ | Excelente para roleplay de almacenamiento manual. Compatible con pallets interactivos. Interior oscuro → usar focos externos. |
| Almacén industrial | prop_warehouse_01 | N/D | SÍ | Recomendado como "processing hub". Perfecto para scripts de crafting/refinado. Vehículos medianos pueden entrar. |

### BODEGAS AGRÍCOLAS

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Bodega metálica | prop_ind_warehouse_01 | N/D | SÍ | Buen asset para empaquetado industrial. Añadir pallets + forklifts. Muy eficiente en rendimiento. |
| Hangar rural | prop_airport_hangar_01 | N/D | SÍ | Puede reutilizarse como almacén agrícola premium. Excelente para maquinaria gigante. |

## 3.2 — ESTACIONES DE PROCESAMIENTO

### ÁREA DE LIMPIEZA / LAVADO

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Mesa industrial | prop_worklight_03b | N/D | NO | Usar junto a mesas metálicas. Simula estación de clasificación. |
| Depósito de agua | prop_water_tank | N/D | SÍ | Excelente para lavado de verduras. Añadir partículas de agua para realismo. |
| Generador agrícola | prop_generator_03b | N/D | SÍ | Ideal para alimentar maquinaria. Añadir sonido loop ambiental. |

> **Nota:** HVY Mixer también puede reutilizarse visualmente como tanque móvil de agua para irrigación RP.

### SECADO Y PROCESADO

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Cinta transportadora | prop_conveyor_01a | N/D | PARCIAL | Fundamental para pipeline agrícola visual. Excelente para scripts animados. Recomendado freeze entity. |
| Secador industrial | prop_air_blower_01 | N/D | SÍ | Funciona visualmente como secador de grano. Añadir efectos de polvo. |
| Mesa de empaquetado | prop_tool_bench02 | N/D | SÍ | Excelente para crafting stations. Compatible con progress bars RP. |

### BÁSCULAS Y CONTROL

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Báscula industrial | prop_weight_rack_01 | N/D | SÍ | Reutilizable como estación de pesado agrícola. |
| Panel eléctrico | prop_elecbox_12 | N/D | SÍ | Añade credibilidad técnica al complejo. |

## 3.3 — LOGÍSTICA DE CARGA (PALLETS Y CONTENEDORES)

### PALLETS

| Prop | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------|------------|---------------|----------|-----------------|
| Pallet vacío | prop_pallet_01a | N/D | SÍ | Base universal para stacking. Muy ligero en rendimiento. |
| Pallet con cajas | prop_pallet_pile_01 | N/D | SÍ | Perfecto para representar cosecha empaquetada. |
| Pallet con sacos | prop_sacktruck_01 | N/D | PARCIAL | Excelente para trigo/patatas/fertilizante. |

### CAJAS Y CONTENEDORES

| Prop | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------|------------|---------------|----------|-----------------|
| Caja de madera pequeña | prop_crate_11a | N/D | SÍ | Ideal para frutas premium. |
| Caja industrial grande | prop_cratepile_07a | N/D | SÍ | Excelente para almacenes. |
| Contenedor metálico | prop_container_05a | N/D | SÍ | Puede actuar como storage persistente. Muy usado en GTA Online. |
| Contenedor refrigerado | prop_container_ld2 | N/D | SÍ | Perfecto para productos perecederos RP. |

### INTERACTIVIDAD RECOMENDADA

**Método recomendado:**
- Spawn pallet vacío base.
- AttachEntityToEntity:
  - sacos
  - cajas
  - vegetales
  - props de cultivo
- Permite:
  - estados visuales dinámicos
  - sincronización de producción
  - upgrades visuales

**Pipeline recomendado:**
```lua
EMPTY PALLET → LOW LOAD → MEDIUM LOAD → FULL LOAD → SHIPPING STATE
```

## 3.4 — INFRAESTRUCTURA DE RIEGO Y SERVICIOS

### TUBERÍAS Y AGUA

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Tubería industrial | prop_pipe_stack_01 | N/D | SÍ | Excelente para irrigation networks. |
| Bomba de agua | prop_waterpump | N/D | SÍ | Perfecta para pozos agrícolas. |
| Tanque cilíndrico | prop_water_tower_01 | N/D | SÍ | Landmark visual enorme. Recomendado en farms grandes. |

### ILUMINACIÓN AGRÍCOLA

| Estructura | Spawn Name | Hash Numérico | Colisión | Notas Técnicas |
|------------|------------|---------------|----------|-----------------|
| Foco exterior | prop_worklight_04a | N/D | SÍ | Ideal para farms nocturnas. Añadir emissive lights vía script. |
| Torre de luz | prop_lightmast_01 | N/D | SÍ | Cobertura amplia. Excelente para almacenes. |

## 3.5 — PROPS ESPECIALES ALTAMENTE RECOMENDADOS

### TRAILERS AGRÍCOLAS NATIVOS

Rockstar ya incluye trailers agrícolas reutilizables en el juego. ([GTA Wiki][1])

| Prop | Spawn Name | Colisión | Uso |
|------|------------|----------|-----|
| Sprayer trailer | prop_sprayer | SÍ | fumigación, fertilizante líquido, herbicidas RP |
| Grain trailer | prop_trailer01 | SÍ | transporte de cosecha, logística bulk |
| Water reel | prop_waterwheela | SÍ | sistema de irrigación visual |
| Hay baler | prop_haybailer_01 | SÍ | procesamiento de heno |

## 3.6 — RECOMENDACIONES TÉCNICAS FIVE M

### OPTIMIZACIÓN

**Distancias recomendadas:**
```lua
SetEntityDistanceCullingRadius(entity, 250.0)
```

**Freeze recomendado:**
```lua
FreezeEntityPosition(entity, true)
```

**LOD Strategy:**
- Props gigantes: máximo 6-10 visibles simultáneamente.
- Props pequeños: usar batching por zonas.

## 3.7 — HERRAMIENTAS DE DATAMINING RECOMENDADAS

Para hashes exactos y validación:

- [CodeWalker GTA V](https://github.com/dexyfex/CodeWalker)
- [GTAMods Prop Database](https://gtamods.com/wiki/Prop_Models)
- [OpenIV](https://openiv.com/)
- [GTA V Prop List GitHub](https://gist.github.com/zerface/fddfb43867985060a4f65583918b7361)

CodeWalker es especialmente útil para:
- verificar colisiones reales
- descubrir YMAP rurales
- inspeccionar offsets correctos
- obtener hashes exactos vía model viewer

Referencias de infraestructura agrícola y props rurales observables en mapas nativos de GTA V/GTA Online: ([GTA Wiki][2])

[1]: https://gta.fandom.com/wiki/Static_Trailers
[2]: https://gta.fandom.com/wiki/Union_Grain_Farm

---

# CAPÍTULO 4 — INFRAESTRUCTURA DE SERVICIOS (ENERGÍA, RIEGO Y AUTOMATIZACIÓN)

### Farm Sonar — Catálogo Técnico de Assets Nativos GTA V / FiveM

> Objetivo: construir un pipeline agrícola completo usando únicamente props nativos de GTA V para minimizar streaming, consumo RAM y carga de red.

La arquitectura de software de "Farm Sonar", concebida como un sistema de agricultura premium para entornos multijugador, exige una topología de red virtual optimizada y un catálogo preciso de entidades (props). La instanciación de infraestructura de servicios estáticos y dinámicos requiere la utilización de identificadores exactos (hashes) y nombres de aparición (spawn names) extraídos directamente de los diccionarios nativos del juego.

## 4.1 — RED DE AGUA E IRRIGACIÓN

La simulación de sistemas hidrológicos requiere la definición espacial de nodos de extracción, contenedores de almacenamiento volumétrico y redes de distribución vectorial. La geometría de colisión de estos elementos debe ser analizada rigurosamente para prevenir interferencias con las mallas de navegación (navmeshes) de los vehículos agrícolas.

### 4.1.1 Extracción y Almacenamiento

El subsistema de extracción y almacenamiento define los puntos de origen del recurso hídrico. Los modelos nativos seleccionados poseen mallas de colisión complejas que requieren hundimiento en el eje Z al ser emplazados sobre topografías irregulares.

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Bomba de Agua Industrial | prop_waterpump_01 | -1842835319 | 2452131977 | Colisión cilíndrica dura. Requiere desplazamiento Z (Z-offset) de -0.15 para anclar la base al suelo. |
| Depósito Metálico Pequeño | prop_water_tank_01 | 1342637254 | 1342637254 | Superficie transitable. Carece de LOD a distancias mayores a 300 metros. |
| Tanque de Fermentación | prop_ind_watertank_01 | -2053164923 | 2241802373 | Geometría compleja con escaleras perimetrales. Colisión de malla estricta. |
| Torre de Agua Cilíndrica | prop_water_tower_01 | 468305011 | 468305011 | Estructura rural masiva. Eje Z debe coincidir con el terreno. Proyecta sombras de alta densidad. |
| Cisterna Plástica (IBC) | prop_ind_water_04a | -824362145 | 3470605151 | Colisión cúbica perfecta (bounding box). Ideal para almacenamiento dinámico en almacenes. |

### 4.1.2 Distribución (Tuberías y Canalizaciones)

El transporte algorítmico del agua exige la instanciación secuencial de entidades cilíndricas. El acoplamiento matemático de estos props requiere el cálculo de cuaterniones para evitar brechas visuales en las uniones cuando se despliegan sobre terrenos inclinados.

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Tubería de Superficie | prop_pipes_03a | 2099682835 | 2099682835 | Estructura cilíndrica. Óptima para concatenación de rutas de distribución largas. |
| Sección de Tubo Concreto | prop_pipes_conc_01 | 63237339 | 63237339 | Diámetro masivo. Uso recomendado para alcantarillado agrícola principal. |
| Apilamiento de Tuberías | prop_pipe_stack_01 | 1668676931 | 1668676931 | Entidad precompuesta. Útil como infraestructura decorativa en construcción. |
| Tubería Industrial Múltiple | prop_ind_pipe_01 | -809562867 | 3485404429 | Múltiples conductos paralelos. Colisión de caja delimitadora compleja. |
| Canalización de Drenaje | prop_drain_pipe_01 | 1145802117 | 1145802117 | Elemento de salida con textura de desgaste ambiental predeterminada. |

### 4.1.3 Aspersores Fijos y Difusores de Riego

La micro-infraestructura de riego se compone de objetos anclados a nivel de suelo. La gestión de colisión de estos elementos es crítica: los objetos de pequeña estatura inducen reacciones físicas desproporcionadas en vehículos con suspensión rígida. La configuración debe establecer la bandera de colisión en false para permitir el paso de tractores sin interferencia geométrica.

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Válvula de Aspersor A | prop_fire_driser_1a | -1185606320 | 3109360976 | Elemento vertical. Requiere hundimiento de malla al 80%. Desactivar colisión obligatoriamente. |
| Válvula de Aspersor B | prop_fire_driser_1b | -1405158620 | 2889808676 | Variante oxidada del modelo 1a. |
| Válvula de Riego Rígida | prop_fire_driser_2b | -680963984 | 3614003312 | Propiedad de anclaje superficial con volante de control. |
| Distribuidor Multidireccional | prop_fire_driser_4b | 210058467 | 210058467 | Múltiples salidas. Insertar en el terreno ajustando el Pitch a 90 grados. |
| Difusor Base Pequeño | prop_fire_hosereel | -1490157684 | 280459528 | Uso alternativo de carrete enterrado. |
| Boquilla de Fuente | prop_w_fountain_01 | 1504162505 | 1504162505 | Emisor estático anillado. Útil como aspersor central de pivote. |
| Cabezal de Riego (ADD-ON) | prop_farm_sprinkler | N/A | N/A | Sugerido: Importar .ydr personalizado sin colisión si los nativos resultan voluminosos. |

## 4.2 — INFRAESTRUCTURA ELÉCTRICA

El diseño de la simulación energética dicta la instanciación de elementos que soporten el cálculo interactivo (raycasting para interacciones locales) y la propagación lógica de estados (encendido/apagado). El catálogo extraído revela una amplia biblioteca de elementos industriales y rurales idóneos para este propósito.

### 4.2.1 Generadores Diésel (Generación de Energía)

Los generadores extraídos de las tablas del motor comparten geometría con objetos dinámicos. Su instanciación exige cálculos precisos del radio de exclusión para evitar la alteración de trayectorias de NPCs. El emplazamiento de generadores grandes (como prop_generator_03b) requiere validación estricta de las normales del terreno, ya que rotaciones asimétricas pueden desencadenar ciclos de física no deseados.

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Generador Diésel Grande | prop_generator_03b | -572159834 | 4237751313 | Estructura montada en bloque masivo. Ideal para nodo energético central. |
| Generador Industrial Base | prop_generator_01a | -415509317 | 3879457979 | Formato rectangular clásico. Superficie transitable plana. |
| Generador Compacto | prop_generator_02a | -1775229459 | 2519737837 | Unidad portátil con ruedas. Óptima para estaciones de bombeo periféricos. |
| Generador Tipo 3A | prop_generator_03a | 136645433 | 136645433 | Variante visual del 03b con diferente mapeo de desgaste de texturas. |
| Grupo Auxiliar Cerrado | prop_generator_04 | -1001828301 | 3293138995 | Carcasa metálica lisa. Alto índice de reflectividad especular (materiales PBR). |

### 4.2.2 Cajas de Fusibles y Cuadros Eléctricos

Los paneles de control constituyen las interfaces físicas del sistema. Para la implementación de librerías de interacción (como ox_target o qb-target), se debe considerar el desfase de origen (origin offset) de las cajas murales. El identificador prop_elecbox_12, extraído recurrentemente en el datamining, posiciona su punto de origen en la cara posterior de la malla, facilitando su adosamiento matemático a superficies planas sin generar Z-fighting.

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Cuadro Eléctrico Estándar | prop_elecbox_12 | 1756664253 | 1756664253 | Caja doble de pared. Anclaje perfecto en muros de graneros. |
| Gabinete Fusibles Industrial | prop_elecbox_10 | -686494084 | 3608473212 | Dimensiones superiores. Incluye conductos en base. |
| Estación de Alta Tensión | prop_elecbox_14 | -1944495994 | 2350471302 | Estructura autónoma (Standalone) de suelo. Requiere espacio radial libre. |
| Panel Metálico Expuesto | prop_elecbox_25 | -692524020 | 3602443276 | Variante de una sola puerta. |
| Cuadro Cables Abierto | prop_elecbox_08b | -259008966 | 4035958330 | Puerta entreabierta con cableado expuesto. Uso sugerido: averías. |

> **Nota adicional:** La base de datos arroja secuencialmente los modelos prop_elecbox_13 hasta prop_elecbox_24b. Todos comparten banderas de colisión mural, variando únicamente en dimensiones de ancho y texturas de advertencia de voltaje.

### 4.2.3 Infraestructura de Red de Tránsito y Combustible

La coherencia de la red eléctrica externa requiere tensores de líneas aéreas (postes), y el subsistema de generación requiere almacenamiento de hidrocarburos.

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Poste Eléctrico Rural | prop_telegraph_06b | -1600276187 | 2694691109 | Poste de madera cilíndrico básico. Colisión estricta. |
| Poste Transformador | prop_telegraph_06c | -1898474087 | 2396493209 | Poste que incluye un transformador cilíndrico en su ápice. |
| Mástil Corto de Tránsito | prop_roadpole_01b | -223271354 | 4071695942 | Soporte bajo para tendido periférico. |
| Surtidor Diésel Fijo | prop_gas_pump_1c | 1933174915 | 1933174915 | Surtidor industrial antiguo. Advertencia: Reactivo a explosiones si no se mitiga el flag de material. |
| Bidón de Combustible | prop_barrel_02a | N/A (Sugerido) | N/A | Bidón estático. Sustituto óptimo frente a latas de consumo menores extraídas (ej. prop_ecola_can). |

## 4.3 — ILUMINACIÓN AGRÍCOLA

El pipeline de renderizado diferido procesa la fotometría dinámicamente. El análisis de entidades identifica una discrepancia fundamental en la matriz nativa: los objetos de iluminación se dividen entre mallas inertes (que requieren inyección lógica de emisores mediante DrawLightWithRange) y mallas autoluminiscentes.

Los identificadores terminados en el sufijo _l1 (ej. prop_worklight_04b_l1) están preconfigurados en las tablas .ytyp del motor para activar focos cónicos volumétricos en sincronía con el ciclo día/noche (timecycle) del servidor. El control arquitectónico de estos recursos debe limitar su densidad para prevenir el parpadeo fotométrico (light flickering) originado por la saturación del G-Buffer.

### 4.3.1 Focos de Obra y Torres de Iluminación

| Nombre Descriptivo | Spawn Name | Hash Numérico (Decimal / Int32) | Hash (uInt32) | Notas Técnicas de Implementación |
|-------------------|------------|-------------------------------|---------------|-----------------------------------|
| Foco Halógeno (Inactivo) | prop_worklight_04a | -1208490064 | 3086477232 | Trípode de doble foco. No emite luz nativamente, útil como decoración estática diurna. |
| Foco Halógeno (Noche Auto) | prop_worklight_04b_l1 | 765603833 | 765603833 | Emisor volumétrico nocturno automático. Excelente para nodos activos. |
| Foco Halógeno (Cabeza Única) | prop_worklight_04c_l1 | -1580136567 | 2714830729 | Foco individual automático. Menor radio de cobertura (cone angle). |
| Foco Halógeno Alto | prop_worklight_04d_l1 | -1009522972 | 3285444324 | Mástil extendido. Ideal para proyección perimetral de corrales. |
| Foco Auxiliar Ancho | prop_worklight_01a | 145818549 | 145818549 | Pantalla masiva de suelo. Proyecta sombra dinámica pesada. |
| Luminaria de Muro Exterior | prop_ld_cont_light_01 | 1197489041 | 1197489041 | Foco enjaulado. Anclaje recomendado sobre puertas de graneros. |
| Torre de Iluminación | prop_lightmast_01 | N/A (Add-on recomendado) | N/A | El equivalente directo extraído es prop_worklight_01a. Para remolques altos usar mod prop_lightmast_01. |

## 4.4 — EFECTOS DE PARTÍCULAS (PTFX) DE SERVICIO

La representación mecánica de los recursos de la granja (agua a presión, humo térmico, fallas de panel) reposa sobre el subsistema de Asset Dictionaries (PTFX). Los identificadores listados han sido seleccionados rigurosamente del núcleo base (core) para garantizar que la solicitud de streaming (RequestNamedPtfxAsset) no dispare retrasos (lag spikes) al cargar en memoria.

El disparo de efectos continuos sobre infraestructuras persistentes exige el uso imperativo de la primitiva de red para bucles (StartNetworkedParticleFxLoopedOnEntity). Los desplazamientos posicionales (Offsets) respecto al centroide de la malla deben ser calculados vectorialmente.

### 4.4.1 Diccionarios y Nombres de Partículas (PTFX)

| Función de Simulación | Diccionario (Dict) | Nombre Partícula (Name) | Notas Técnicas de Implementación |
|----------------------|-------------------|------------------------|-----------------------------------|
| Chorro de Agua (Aspersor) | core | water_splash_veh_out | Dispersión cónica. Aplicar escala de 0.5 a 0.8 en el aspersor para evitar refracción excesiva. |
| Ruptura de Tubería Mayor | core | ent_dst_water | Efecto de alta presión. Emite partículas poligonales con gravedad. Culling agresivo en el cliente. |
| Humo de Escape (Diésel) | core | exp_grd_bzgas_smoke | Humo volumétrico negro/gris. Aplicar offset exacto al caño de escape del prop_generator_03b. |
| Humo Aceleración Pesada | core | veh_exhaust_truck_heavy | Volumen denso oscuro. Óptimo para simular inyección inicial del generador. |
| Avería Panel (Chispas) | core | ent_dst_elec_fire_sp | Ráfagas eléctricas intermitentes. Incluye un nodo destellador (flash node) que ilumina la geometría vecina. |
| Cortocircuito Aislado | core | sparks | Chispas lineales unidireccionales. Aplicación sutil, ideal para interactuar durante el ciclo de reparación de prop_elecbox_12. |

> **Nota técnica:** La administración del puntero (handle) devuelto por estas invocaciones es absolutamente necesaria; todo identificador lógico debe alojarse en rutinas de limpieza (Garbage Collection scripts) para forzar la detención de las partículas mediante StopParticleFxLooped o RemoveParticleFx cuando el estado interactivo del cuadro eléctrico cambia a inactivo. La ausencia de este manejador inducirá de forma expedita fugas de memoria volumétrica en los clientes (memory leaks) de Farm Sonar.

---

# CAPÍTULO 5 — LOCACIONES Y MLOs (Foco principal: GRAPESEED)

### Farm Sonar — Catálogo Técnico de Assets Nativos GTA V / FiveM

> Objetivo: construir un pipeline agrícola completo usando únicamente props nativos de GTA V para minimizar streaming, consumo RAM y carga de red.

La implementación de un sistema de agricultura intensiva y premium dentro de la arquitectura del motor Rockstar Advanced Game Engine (RAGE) requiere una precisión matemática absoluta en la definición de coordenadas, zonas poligonales y puntos de interacción. La región de Grapeseed, modelada a partir de las comunidades agrícolas topográficamente complejas de California como Bakersfield, proporciona un entorno excepcional para operaciones de cultivo masivo. Sin embargo, la inyección de cientos de entidades dinámicas (props de plantas, sistemas de riego, tractores) en el entorno nativo exige una gestión rigurosa de la memoria del cliente, los límites de oclusión y la sincronización de red mediante OneSync.

## 5.1 — PARCELAS NATIVAS (Campos Abiertos)

La delimitación de "Zonas de Cultivo" (Plots) en Grapeseed debe basarse en la identificación de mallas de terreno (terrain meshes) que ofrezcan una planimetría óptima y texturas de material compatibles con la física de tracción de la maquinaria agrícola. Las zonas seleccionadas a continuación han sido mapeadas para evitar colisiones estáticas inamovibles, como cercas nativas, rocas y sistemas de riego preexistentes incrustados en el archivo .ymap nativo.

Para que el script "Farm Sonar" funcione correctamente, las coordenadas no solo deben definir el punto central del campo, sino también los vértices espaciales de la zona poligonal y los límites en el eje Z (minZ y maxZ). Esto garantiza que los algoritmos de interacción del jugador y la generación de "props" se mantengan estrictamente dentro de los límites visuales del campo arado.

| Nombre Descriptivo | Coordenadas Centrales vector3(X, Y, Z) | Dimensiones (Largo x Ancho) | Z-Offset (minZ / maxZ) | Notas Topográficas y de Colisión |
|-------------------|----------------------------------------|---------------------------|-----------------------|----------------------------------|
| Campo Grande Grapeseed Norte | vector3(2447.90, 4973.40, 47.70) | 150.0 x 80.0 | 45.00 / 50.00 | Totalmente plano y amplio. Ubicado al norte de la granja de O'Neil. Material del suelo óptimo para tracción. Ideal para tractores y generación masiva de cultivos sin interrupción. |
| Parcela Búnker Grapeseed | vector3(1823.96, 4708.14, 42.49) | 100.0 x 60.0 | 40.00 / 45.00 | Ligera pendiente orientada al sur. Requiere el uso de cultivos con Z-offset flexible mediante raycasting para evitar que las entidades queden flotando sobre la topografía. |
| Sector Agrícola Cow Farm | vector3(2506.16, 4100.68, 37.53) | 90.0 x 70.0 | 35.00 / 40.00 | Terreno irregular mixto. Excelente para cultivos fragmentados. Alta proximidad a establos nativos, lo que requiere precaución con el enrutamiento de la IA de vacas. |
| Parcela McKenzie Airfield | vector3(2141.60, 4823.04, 40.26) | 120.0 x 50.0 | 38.00 / 42.00 | Área plana de transición adyacente a la pista de aterrizaje. Superficie compacta y nivelada. Riesgo de intrusión si los jugadores fallan aterrizajes. |
| Campo Secano Farmhouse | vector3(1570.37, 2254.54, 78.89) | 85.0 x 85.0 | 75.00 / 82.00 | Ubicado más al sur hacia el Grand Senora Desert. Suelo seco y arcilloso con alta elevación Z. Perfecto para simular cultivos de secano o viñedos secundarios. |

### Análisis Topológico y Geometría de Colisiones

La implementación de estas coordenadas trasciende la simple inserción de puntos en el mapa. El motor de físicas de GTA V calcula la interacción de los vehículos agrícolas basándose en el material asignado a la malla de colisión subyacente. En el "Campo Grande Grapeseed Norte" (vector3(2447.90, 4973.40, 47.70)), el material predominante está codificado como mud y dirt. Esta asignación nativa reduce el coeficiente de fricción estática, lo que significa que los tractores programados en Farm Sonar experimentarán pérdida de tracción si el torque aplicado a las ruedas motrices supera el límite de agarre. Este comportamiento es altamente deseable para un simulador agrícola premium, pero requiere que el desarrollador ajuste los valores TractionCurveMax y TractionCurveMin en los metadatos de los vehículos personalizados para evitar que queden inmovilizados perpetuamente.

Adicionalmente, la "Parcela Búnker Grapeseed" (vector3(1823.96, 4708.14, 42.49)) presenta una declinación topográfica constante hacia el Alamo Sea. Si el script itera sobre esta zona poligonal para generar una cuadrícula de plantas, el uso de un valor Z estático (ej. 42.49) provocará que las plantas en el extremo norte queden enterradas bajo la malla de colisión, mientras que las del extremo sur levitarán visiblemente en el aire. Para mitigar este defecto visual que destruye la inmersión, el parámetro requiresDynamicZ = true en el código Lua debe activar una rutina de raycasting. Por cada entidad de cultivo generada, el cliente debe disparar un rayo vertical utilizando la función nativa GetGroundZFor_3dCoord o GetTargetlessObjectRaycast desde Z + 50.0 hacia Z - 50.0. La intersección devuelta proporcionará la altura exacta de la topografía local, permitiendo que el script fije la coordenada Z del prop con un ajuste milimétrico (ej. Z - 0.1 para simular el enterramiento de las raíces).

En el "Sector Agrícola Cow Farm" (vector3(2506.16, 4100.68, 37.53)), la complejidad aumenta debido a la red de navegación de la inteligencia artificial (NavMesh). Esta área nativa de Grapeseed está programada para generar rebaños de vacas de las razas Holstein y Braunvieh. Estas entidades controladas por el motor deambulan libremente y responden a estímulos de colisión y ruido. Si el script no gestiona correctamente la exclusión espacial, las vacas nativas atravesarán los cultivos, provocando cálculos físicos innecesarios y posibles desincronizaciones de red. Se recomienda implementar un hilo de ejecución (thread) que purgue periódicamente a los NPCs animales dentro del radio del BoxZone utilizando ClearAreaOfPeds o interceptando la generación nativa a través de los administradores de población de FiveM.

## 5.2 — ZONAS LOGÍSTICAS Y ALMACENAJE NATIVO

La viabilidad macroeconómica de una explotación agrícola a escala industrial depende de su infraestructura logística. Los jugadores requerirán zonas de estacionamiento de gran capacidad para cosechadoras, tractores con remolques articulados y puntos fijos para la colocación de silos interactivos. El diseño del mapa de Grapeseed ya alberga múltiples complejos industriales y graneros que pueden ser reaprovechados sin necesidad de consumir recursos adicionales del servidor en la carga de mapeos externos.

El Rancho O'Neil y el McKenzie Airfield representan los núcleos logísticos terrestres y aéreos más formidables de la región norte del condado de Blaine. La ubicación de silos (Capítulo 3) requiere de plataformas planas de concreto o tierra compactada, de modo que las colisiones estáticas de los accesorios masivos no intersecten de manera anómala con el terreno, previniendo el temido "clipping" y explosiones vehiculares.

| Nombre de la Instalación | Coordenadas Centrales vector3(X, Y, Z) | Vector4 de Estacionamiento (con Heading) | Notas Logísticas y Estados de IPL |
|-------------------------|----------------------------------------|------------------------------------------|-----------------------------------|
| O'Neil Ranch (Plataforma de Silos y Granero) | vector3(2447.90, 4973.40, 47.70) | vector4(2455.00, 4960.00, 47.00, 45.0) | Epicentro logístico natural. Amplio espacio para giro de remolques (turning radius). Crítico: Requiere validación del estado del IPL de la casa principal para evitar el modelo destruido. |
| McKenzie Airfield (Hangar y Pista) | vector3(2141.60, 4823.04, 40.26) | vector4(2130.50, 4810.20, 40.00, 100.0) | Instalación óptima para el almacenamiento del avión fumigador Duster. Acceso ininterrumpido a la pista de despegue. Libre de oclusión de vegetación alta. |
| Shady Tree Farm (Almacenes Abiertos) | vector3(1880.50, 4920.10, 45.50) | vector4(1875.20, 4915.80, 45.00, 180.0) | Estructuras de madera nativas a lo largo de Grapeseed Avenue. Ideal para salvaguardar tractores y maquinaria de fertilización. Espacio cerrado que reduce la exposición visual. |
| Grapeseed Train Depot (Zona de Carga) | vector3(2600.00, 4500.00, 35.00) | vector4(2605.00, 4495.00, 35.00, 270.0) | Patio ferroviario nativo. Aunque el script no controle trenes, las vías de apartadero proveen una estética inmejorable para puntos de recolección de maquinaria o carga mayorista. |

### Gestión de IPLs y Físicas de Vehículos Pesados

La utilización del Rancho O'Neil como centro logístico (vector3(2447.90, 4973.40, 47.70)) conlleva una peculiaridad nativa del código de Grand Theft Auto V que todo diseñador de niveles en FiveM debe abordar. Durante los eventos de la campaña principal del juego (la misión "Crystal Maze"), el rancho es incendiado y destruido por Trevor Philips. El motor gráfico gestiona estas dos variaciones visuales a través del sistema IPL (Item Placement Layout). Si el servidor carga por defecto la versión destruida, las mallas de colisión de los escombros bloquearán físicamente las rutas de acceso de los tractores y crearán barreras invisibles.

Para garantizar un entorno prístino digno de un script premium, el código de inicialización del lado del cliente (client.lua) debe invocar la función nativa RequestIpl para el hash correspondiente al edificio intacto. La investigación confirma que los IPLs relacionados con esta locación incluyen farm, farmint, farm_lod, y des_farmhouse. El script debe asegurar que RequestIpl("farm") y RequestIpl("farmint") se ejecuten, mientras que simultáneamente ejecuta RemoveIpl("des_farmhouse") para eliminar explícitamente el modelo destruido de la memoria gráfica.

Por otro lado, el Hangar de McKenzie Airfield (vector3(2141.60, 4823.04, 40.26)) presenta sus propios desafíos volumétricos. La envergadura del avión fumigador Duster es considerable y el modelo de colisión de las alas (wing hitboxes) es notoriamente intolerante a los roces con estructuras estáticas. El punto de generación vector4(2130.50, 4810.20, 40.00, 100.0) ha sido calculado para posicionar la aeronave exactamente en la línea central de la plataforma de rodaje exterior del hangar, apuntando el morro a 100 grados (este-sureste) hacia la pista principal. Esto permite operaciones de rodaje y despegue corto (STOL - Short Take-Off and Landing) seguras y eficientes, mitigando la probabilidad de que los jugadores destruyan la aeronave inmediatamente después de interactuar con el punto de generación.

En términos de ruteo logístico, la interconexión entre la zona de Silos en O'Neil y la zona de almacenaje en Shady Tree Farm (vector3(1880.50, 4920.10, 45.50)) obliga a los jugadores a navegar por caminos de tierra secundarios como Joad Lane y Seaview Road. La topografía ondulada de estas vías, combinada con la física del remolque articulado (Trailer Physics) de GTA V, puede generar un comportamiento errático a altas velocidades debido al desfase de red (desync) entre el camión tractor y el remolque. Se recomienda implementar un limitador de velocidad condicional en el script cuando un jugador tiene un remolque de carga lleno acoplado, garantizando que el peso de la mercancía penalice la velocidad máxima de manera realista y evite catástrofes físicas (jackknifing) durante el tránsito a través del mapa.

## 5.3 — INTERIORES (MLOs) PARA LA SEDE CENTRAL

El diseño de sistemas complejos en plataformas de rol requiere anclas tangibles. Los jugadores de Farm Sonar necesitan un recinto físico inmersivo que actúe como Sede Central. Este entorno servirá como el punto de acceso exclusivo para interactuar con la computadora portátil que despliega el "Manager Panel", un área para almacenar herramientas de cultivo (como fertilizantes raros, semillas y llaves de maquinaria pesada), y un espacio arquitectónico para sostener reuniones corporativas o cerrar contratos de venta.

El entorno nativo de Grapeseed presenta severas limitaciones para albergar una sede de estas características. La mayoría de los edificios son modelos "huecos" sin interiores funcionales. Los pocos interiores accesibles, como los cobertizos en McKenzie Airfield, carecen de portales de oclusión. En la terminología del motor RAGE, un edificio sin portales (Portals) no instruye al cliente a dejar de renderizar el mundo exterior, lo que significa que la lluvia nativa atravesará el techo, el viento sonará a pleno volumen y las luces de los vehículos en la carretera seguirán calculando sombras dentro del recinto, destruyendo la inmersión y malgastando ciclos de la GPU.

Para resolver este vacío arquitectónico, la base de datos de la comunidad proporciona MLOs (Map Load Objects) gratuitos que modifican los archivos .ytyp y .ymap del juego, abriendo fachadas previamente cerradas y definiendo habitaciones herméticas.

| Origen del Interior | Nombre de la Sede / MLO | Coordenadas Interacción (Laptop) vector3(X,Y,Z) | Análisis de Renderizado y Características |
|---------------------|-------------------------|-----------------------------------------------|-------------------------------------------|
| Nativo (Subterráneo) | Sótano Rancho O'Neil | vector3(2444.10, 4974.50, -42.80) (Subnivel Z) | Accesible nativamente. Físicamente aislado. Originalmente usado para operaciones ilícitas en el "lore" del juego, requiere modificación visual de "props" para darle una estética de oficina corporativa agrícola. |
| Nativo (Exterior Techado) | Oficina McKenzie Hangar | vector3(2126.80, 4795.50, 41.10) | Pequeña área techada lateral en el hangar. Expuesta al clima ambiental y sin aislamiento acústico. Viable únicamente si se busca una sede improvisada y económica. |
| Comunidad | Grapeseed House 1 (por racingfreddie) | vector3(2425.30, 4985.10, 46.50) (Aprox. según MLO) | MLO gratuito y altamente reconocido en la comunidad. Incorpora espacio de oficina dedicado, áreas residenciales y un enorme garaje anexo. Operado mediante YMAP no destructivo. Excelente partición de portales. |
| Comunidad | The Black Lantern (por Prentiss) | vector3(1690.50, 4925.20, 43.10) (Oficina 2do Piso) | Inspirado en "Life is Strange". Situado en Grapeseed Main Street. Proporciona un bar en el nivel inferior y oficinas en el superior. Ideal si la estructura del servidor promueve la venta directa a los consumidores locales. |
| Comunidad | Grapeseed Alive Map | Variable según la estructura elegida dentro del pack | Expansión ambiental masiva. Añade interiores mejorados en McKenzie y nuevas fortalezas. Altamente detallado, pero incrementa significativamente el peso de los polígonos del área. |

### Optimización de VRAM y Culling de Portales en MLOs

La elección entre utilizar el "Sótano Rancho O'Neil" o un MLO externo como "Grapeseed House 1" tiene consecuencias directas sobre el rendimiento de red y procesamiento. El sótano nativo del rancho se encuentra en una cota Z extremadamente negativa (-42.80). Esta posición en el inframundo del mapa actúa como una forma rudimentaria de oclusión; la lejanía del eje Z del mundo de la superficie garantiza que los accesorios agrícolas renderizados arriba no consuman memoria de video mientras el jugador esté en la oficina administrando el panel.

Sin embargo, si se implementa "Grapeseed House 1" o "The Black Lantern", estas estructuras coexisten en el mismo plano Y/Z que los campos de cultivo de Grapeseed. Un MLO de alta calidad técnica define un archivo .ytyp con métricas exactas de volumen interior (Rooms). Cuando el jugador entra físicamente por la puerta principal, el motor gráfico ejecuta un algoritmo de oclusión basado en portales (Portal Culling). Este algoritmo corta abruptamente la renderización de las entidades exteriores, incluyendo los cientos de props de repollo, trigo o fertilizante que Farm Sonar ha generado en los campos circundantes.

Es de suma importancia que al insertar el prop_laptop_01a usando el script, el modelo de la laptop esté matemáticamente dentro del cuboide (Bounding Box) definido por la "Room" del MLO en el archivo de metadatos del mapeo. Si la coordenada Z o XY de la laptop empuja el centro geométrico del objeto (Origin Point) fuera de la delimitación de la pared del MLO, el motor de GTA V lo clasificará como un objeto exterior y no lo renderizará mientras el jugador esté dentro de la oficina, lo que resultará en un punto de interacción invisible o la imposibilidad de abrir el panel administrativo.

## 5.4 — PUNTOS DE VENTA (NPC VENDORS)

El flujo sistémico y macroeconómico de Farm Sonar requiere que el ciclo de juego no permanezca estático en la sección norte del mapa. Si los jugadores cosechan y venden sus productos a unos pocos metros de distancia, la economía colapsará por la falta de inversión de tiempo y riesgo. Para incentivar dinámicas de conducción, el uso de remolques pesados y la justificación del desgaste del combustible, los Puntos de Venta (materializados como NPCs o Peds compradores) deben estar estratégicamente descentralizados en San Andreas.

La arquitectura comercial y las fachadas industriales ya presentes en el motor base proporcionan excusas narrativas y logísticas perfectas para ubicar a los vendedores. Al definir puntos de venta para cereales al por mayor (molinos y fábricas), productos frescos para minoristas (supermercados) y contratos B2B exclusivos (restaurantes locales), se crea un modelo de demanda multifacético. Las distancias de viaje introducen orgánicamente la posibilidad de interceptaciones por facciones rivales, fomentando el rol de escolta de seguridad y convoys.

| Perfil del Comprador | Fachada Nativa | Coordenadas Centrales vector3(X, Y, Z) | Vector4 de Ped (Heading) | Racionalización Logística y Económica |
|---------------------|----------------|----------------------------------------|--------------------------|--------------------------------------|
| Molino Procesador (Venta Masiva/Trigo) | Clucking Bell Farms (Paleto Bay) | vector3(-83.55, 6237.34, 50.73) | vector4(-85.20, 6235.10, 50.73, 220.0) | Fábrica masiva. Ubicada al final de la autopista Great Ocean. Viaje de longitud media, bajo riesgo. Margen de beneficio moderado. Gran capacidad para estacionar tráileres. |
| Silo Industrial (Exportación a Granel) | Cypress Flats Warehouse | vector3(965.83, -986.95, 40.20) | vector4(965.83, -986.95, 40.20, 90.0) | Zona industrial en el profundo East Los Santos. Ruta de máxima distancia desde Grapeseed. Alto riesgo debido a la actividad urbana. Rendimiento económico máximo. |
| Minorista Frescos (Verduras/Frutas) | Harmony 24/7 Supermarket | vector3(1178.98, 2653.98, 37.86) | vector4(1180.50, 2651.20, 37.86, 180.0) | Ubicación céntrica (Route 68). Acceso intermedio perfecto para camionetas ligeras (Mule o Benson). Tráfico de paso constante, ideal para productos de ciclo rápido. |
| Venta Local (Subsistencia/Venta Rápida) | Grapeseed LTD / Wonderama | vector3(-552.66, -190.80, 37.22) | vector4(-552.66, -190.80, 37.22, 270.0) | Venta a nivel hiper-local. Tiempos de viaje casi nulos desde las parcelas, pero los algoritmos de oferta y demanda deben castigar severamente los precios de compra aquí para evitar el farmeo abusivo. |
| Contrato B2B Premium (Restaurante) | Yellow Jack Inn (Senora Desert) | vector3(2005.01, 3056.44, 47.04) | vector4(2003.50, 3058.10, 47.04, 150.0) | Entorno rústico clásico. Ubicación inmersiva para contratos de suministro limitados (ej. cultivos artesanales de alto valor). Espacio de estacionamiento limitado. |
| Contrato B2B Premium (Restaurante) | Pop's Diner (Paleto/Grapeseed) | vector3(2675.85, 4344.32, 45.72) | vector4(2678.00, 4342.10, 45.72, 45.0) | Diner con fachada retro. Requiere una integración de menú minuciosa. Excepcional para entregas cortas de cultivos especiales empaquetados. |

### Persistencia de Entidades de Red y Comportamiento de NPCs

La inserción física de entidades NPC (Peds) en los vectores delimitados en Cypress Flats (vector4(965.83, -986.95, 40.20, 90.0)) y Paleto Bay (vector4(-85.20, 6235.10, 50.73, 220.0)) presenta riesgos graves de estabilidad funcional si no se emplean los parámetros correctos del motor RAGE.

Cypress Flats está clasificado como una zona industrial y de bandas en el mapa de NavMesh nativo, con alta circulación de tráfico de vehículos de carga (Mule, Phantom) y comportamiento agresivo de la IA ambiental (Vagos y facciones Cypress). Si el pedModel de nuestro comprador de silos es generado nativamente a través de la función CreatePed, el servidor de FiveM asignará la propiedad de la entidad (Network Ownership) al primer jugador que se acerque a la zona.

Sin las mitigaciones escritas en las configuraciones Lua (freezeEntity = true, invincible = true, blockEvents = true), el motor de la IA someterá al NPC a las reglas ambientales globales. Un choque entre vehículos manejados por la IA en Popular Street, o un tiroteo esporádico entre jugadores cercanos, desencadenará la máquina de estados de pánico del Ped (Flee Behavior). El comprador romperá su animación en bucle (animDict) y escapará aleatoriamente por la ciudad, destruyendo por completo la capacidad de los agricultores de interactuar con el punto de venta.

El uso de la nativa SetBlockingOfNonTemporaryEvents(ped, true) aislará la psique artificial de la entidad, impidiendo que procese eventos auditivos de disparos, alarmas de vehículos o colisiones inminentes. Adicionalmente, invocar FreezeEntityPosition(ped, true) desvincula físicamente la malla del NPC del sistema de fuerzas gravitacionales y colisiones de Havok (el motor físico base de GTA V). Si el remolque de un camión pesado choca accidentalmente contra el vendedor congelado en el muelle de carga de Cypress Flats, el camión sufrirá el daño del impacto estático y el NPC no será arrojado bajo el mapa, preservando el ancla comercial intacta.

El alineamiento angular definido por la variable Heading en el vector4 (el último valor) es igualmente crucial. En el caso del Supermercado Harmony 24/7 (1180.50, 2651.20, 37.86, 180.0), un Heading de 180 grados asegura que el NPC esté encarando físicamente al jugador que se aproxima desde la zona de estacionamiento principal de la Ruta 68, permitiendo que las rutinas de Interfaz de Usuario (como qb-target) intersecten el hitbox del NPC limpiamente frontalmente en lugar de requerir que el jugador busque interacciones defectuosas en la espalda geométrica del modelo.

Esta precisión vectorial, complementada con el manejo robusto de los estados de IPLs para los centros logísticos, el trazado de rayos para anular los deltas topográficos en las parcelas nativas, y el control de oclusión en los interiores de MLOs recomendados, conforma la totalidad del entramado técnico e infraestructural que Farm Sonar requiere para operar de manera óptima y fluida sobre el código heredado de Grand Theft Auto V.
