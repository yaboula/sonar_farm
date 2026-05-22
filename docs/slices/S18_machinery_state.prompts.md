# Prompts para S18 (Maquinaria estado + mantenimiento)

Copia y pega el bloque correspondiente a cada agente en un nuevo hilo según corresponda.

---

## 1. Backend Agent (DB, Service & Item)

```markdown
Eres el Backend Agent de Farm Sonar. Tu objetivo es implementar la base del **Slice S18: Maquinaria estado + mantenimiento**.

**Contexto:**
Lee `docs/slices/S18_machinery_state.md` para entender el scope. El objetivo principal es tener un tracking de la "durabilidad" de los tractores y herramientas rodantes.

**Tareas principales:**

1. **Configuración (`config/machinery.lua`):**
   - Crea un registro de modelos de vehículos agrícolas válidos (usa el catálogo: `tractor`, `tractor2`, `tractor3`, `fieldmaster`, `bison`, etc.).
   - Define un ratio de desgaste (ej. -1 durabilidad por cada X segundos de uso o distancia, tú decides si es tiempo-based o reportado por el cliente, lo más seguro en FiveM suele ser que el cliente reporte distancia o uso periódico y el servidor descuente).
   - Configura un umbral crítico de rotura (ej. 30/100).
2. **Persistencia (`013_machinery.sql`):**
   - Crea `sonar_farm_machinery_state` guardando `plate` (VARCHAR 16, Primary Key), `model` (opcional), `durability` (INT 0-100), `is_broken` (BOOLEAN).
3. **Servicio (`server/machinery/machinery_service.lua`):**
   - Crea un servicio con métodos: `GetState(plate)`, `RecordUsage(plate, amount)`, `Repair(plate)`.
   - Si `durability` baja del umbral, evalúa si debe romperse (`is_broken = true`) y emite evento `sonar:farm:machinery:broke_down(plate)`.
   - `Repair` pone `durability = 100`, `is_broken = false` y emite `sonar:farm:machinery:repaired(plate)`.
4. **Ítem de Mantenimiento (`sonar_machinery_kit`):**
   - Regístralo en `config/items.lua` (usa el prop del repairkit de GTA).
   - Añádelo al NPC Vendor (`config/npcs.lua`).
   - Registra su callback en `server/items/physical_item.lua` o en un `server/machinery/interactions.lua`. Al usarse, debe verificar si el jugador está mirando un vehículo agrícola, consumir 1 charge/item y llamar a `Repair(plate)`. (Nota: el ox_target de mirar el vehículo lo hará el Integration Agent, pero tú puedes dejar preparado el event handler `sonar:farm:server:repair_machinery` que recibe la matrícula).

**Reglas:** Todo en inglés, convenciones de siempre. Añade un test básico y notifica al terminar.
```

---

## 2. Integration Agent (Wear loop & Breakdown nativos)

```markdown
Eres el Integration Agent de Farm Sonar. Tu objetivo es conectar el cliente de FiveM con el estado de maquinaria para el **Slice S18**.

**Contexto:**
El Backend ya preparó el tracking de durabilidad por matrícula (`plate`) y los eventos de avería.

**Tareas principales:**

1. **Tracking Loop (`client/machinery/wear_tracker.lua`):**
   - Cuando el jugador conduce un vehículo válido de granja (chequea el config), usa un thread lento (ej. Wait 10000) para medir distancia o tiempo conducido, y reportarlo al servidor (ej. un net event o callback `sonar:farm:machinery:report_usage` que baje la durabilidad).
   - Para no saturar la red, haz un batch (envía el update de desgaste cada 1 minuto de conducción).
2. **Efectos de Rotura (`client/machinery/breakdown.lua`):**
   - Escucha el evento `sonar:farm:machinery:broke_down(plate)`.
   - Si el vehículo con esa matrícula existe localmente, aplica nativos de GTA para simular avería (ej. `SetVehicleEngineHealth(veh, -4000)`, `SetVehicleEngineOn(veh, false, true, true)`, partículas de humo).
   - Escucha `sonar:farm:machinery:repaired(plate)` para limpiarlo y encenderlo de nuevo.
3. **Interacción del Kit (`client/machinery/repair_interaction.lua`):**
   - Agrega una opción de `ox_target` a los vehículos agrícolas (global o zone vinculada al capó) para "Repair Machinery".
   - Al darle, reproduce una animación (ej. `lib.progressBar` de 10s con anim de mecánico). Si tiene éxito, llama al servidor para consumir el kit y reparar la base de datos.

**Reglas:**

- Cuidado con la propiedad de red (`NetworkHasControlOfEntity`) antes de tocar la salud del motor. Si otro conduce, el servidor debe decirle al conductor que aplique el efecto.
- Manejo limpio de errores.
  Notifica al terminar y documenta el smoke test.
```
