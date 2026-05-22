# Prompts para S16 (Clima dinámico + 4 estaciones)

Copia y pega el bloque correspondiente a cada agente en un nuevo hilo según corresponda.

---

## 1. Backend Agent (Core & State Machine)

```markdown
Eres el Backend Agent de Farm Sonar. Tu objetivo es implementar la parte lógica del **Slice S16: Clima dinámico + 4 estaciones**.

**Contexto:**

1. Lee `docs/slices/S16_dynamic_climate.md` para entender el scope.
2. Lee `docs/00_BIBLE.md` §13.1 (Time & Seasons) para entender el ratio de tiempo de Farm Sonar.

**Tareas principales:**

1. **Configuración (`config/climate.lua`):**
   - Define las 4 estaciones (`spring`, `summer`, `autumn`, `winter`) y sus duraciones en segundos (o ticks).
   - Define los eventos meteorológicos (`clear`, `light_rain`, `torrential_rain`, `drought`, `hail`, `frost`) y sus probabilidades según la estación.
   - Añade un flag `Config.Farm.Climate.EnableWeatherSync = false` (por defecto false para no romper servidores que ya tengan vSync, pero la matemática siempre funciona).
2. **Persistencia (`012_climate.sql`):**
   - Crea una tabla pequeña `sonar_farm_climate_state` de 1 sola fila para guardar `current_season`, `current_weather`, `season_started_at`, `weather_started_at`.
3. **Servicio y Scheduler (`server/climate/climate_service.lua`):**
   - Crea un servicio que cargue el estado al iniciar.
   - Crea un scheduler (o engánchate al existente si aplica) que rote las estaciones cuando pase el tiempo.
   - Cada X tiempo (o tick), evalúa si cambia el clima dentro de la estación actual.
   - Dispara eventos net `sonar:farm:climate:season_changed` y `sonar:farm:climate:weather_changed` hacia los clientes.
4. **Impacto en Parcelas:**
   - La lluvia suave (`light_rain`) debe incrementar el `irrigation_score` de las parcelas que estén al aire libre.
   - La lluvia torrencial (`torrential_rain`) o granizo (`hail`) debe reducir el `irrigation_score` (exceso de agua) o directamente la calidad general.
   - Esto puedes hacerlo iterando parcelas en memoria o usando consultas bulk a DB, idealmente enganchado en el mismo loop que avanza los cultivos para ser eficientes. Ignora las parcelas tipo `greenhouse`.
5. **Factor de Calidad (`server/quality/factors/weather.lua`):**
   - Completa el factor `weather` real. Hasta ahora era un mock que devolvía 100 o neutro.
   - Debe comparar el clima actual (y estación) con las preferencias del cultivo (`crop_config.optimal_seasons` o similar que deberás añadir a los configs de crops).
   - Recuerda que para parcelas `greenhouse`, el weather_match siempre es neutro/fijo y no se ve afectado.

**Reglas:** Todo en inglés, respeta las convenciones de nombres, no rompas dependencias y actualiza pruebas.
Escribe tests de la lógica (ej. `climate_service_spec.lua`). Notifica cuando termines.
```

---

## 2. Integration Agent (Client Weather Sync & HUD)

_Nota: Pásale esto al Integration Agent una vez que el Backend Agent haya terminado la lógica y los eventos._

```markdown
Eres el Integration Agent de Farm Sonar. Tu objetivo es conectar el cliente de FiveM con el estado climático del servidor para el **Slice S16**.

**Contexto:**
El Backend Agent acaba de implementar `server/climate/climate_service.lua` que emite `sonar:farm:climate:weather_changed(new_weather)` y `sonar:farm:climate:season_changed(new_season)`.

**Tareas principales:**

1. **Sincronización de Clima (`client/climate/weather_sync.lua`):**
   - Escucha los eventos del servidor (y un callback inicial al conectar para obtener el estado actual).
   - Comprueba `Config.Farm.Climate.EnableWeatherSync`. **Si es false, no hagas NADA visualmente (esto evita guerras con scripts de clima como vSync).**
   - Si es true, usa los nativos de FiveM (ej. `SetWeatherTypeOverTime`, `SetWeatherTypePersist`, `SetWeatherTypeNow`, `ClearOverrideWeather`, etc.) para aplicar el clima correspondiente de GTA V (ej. `CLEAR`, `RAIN`, `THUNDER`, `XMAS` para nieve/helada).
2. **HUD / Notificaciones:**
   - Opcional pero recomendado: usa notificaciones de `ox_lib` o envía un mensaje al NUI (a evaluar si tenemos un rincón para esto) cuando cambia drásticamente la estación o viene un temporal grave (granizo).

**Reglas:** Todo en inglés. Maneja la transición suave del clima si es posible. No sobreescribas la hora (solo el clima, la hora de GTA suele ser otra guerra aparte, céntrate en el _weather type_).
Notifica cuando termines.
```
