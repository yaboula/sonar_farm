# Prompts para S17 (Hortícolas + invernadero)

Copia y pega este bloque al Backend Agent en un nuevo hilo:

```markdown
Eres el Backend Agent de Farm Sonar. Tu objetivo es implementar el **Slice S17: Hortícolas + invernadero**.

**Contexto del Slice S17:**

1. Lee `docs/slices/S17_horticultural_greenhouse.md` para entender el scope y DoD.
2. Lee `docs/Catálogo-de-Assets-y-Referencias/CATALOGO_COMPLETO.md` para obtener los props (modelos 3D) de los cultivos hortícolas (tomate, pimiento, lechuga, cebolla, patata).
3. Revisa `sonar_farm_core/config/crops/wheat.lua` (o corn/barley) como referencia de la estructura `config-only` de Pilar 5.

**Tareas principales:**

1. **Modelos 3D:** Añade a `config/verified_props.lua` las definiciones para `tomato`, `pepper`, `lettuce`, `onion`, `potato`. Necesitarás 4 etapas (`planted`, `germinating`, `growing`, `maturing/harvest_ready`) basándote en el catálogo. Usa las escalas y offsets Z adecuados para que no floten.
2. **Archivos de Cultivo:** Crea `config/crops/tomato.lua`, `config/crops/pepper.lua`, `config/crops/lettuce.lua`, `config/crops/onion.lua`, `config/crops/potato.lua`.
   - Define sus tiempos de crecimiento (puedes inventar valores balanceados, menores que cereales, ej. 4-6h por fase).
   - Sus `plot_types_allowed` deben incluir `'horticultural'` y `'greenhouse'` (o los correspondientes, según su tipo, pero tomate/pimiento/lechuga/cebolla/patata son típicamente de campo hortícola e invernadero).
   - Configura un NPK óptimo distinto para cada uno.
3. **Inventario y Traducciones:**
   - Añade las semillas y los ítems de cosecha (ej. `sonar_seed_tomato`, `sonar_item_tomato`) a `config/items.lua`.
   - Añádelos al vendedor NPC en `config/npcs.lua`.
   - Añade los nombres al `locales/es.lua` y `locales/en.lua`.
4. **Lógica de Invernadero:**
   - Revisa cómo se definen las parcelas en `config/plots.lua`. Hay una de tipo `greenhouse`.
   - La lógica de calidad del clima (S16) no existe aún, pero deja preparado en `crop_lifecycle_service.lua` o en el servicio pertinente un hook o comentario claro sobre cómo el tipo `greenhouse` ignorará el `weather_match`.
   - Revisa si `plot_lifecycle_service.lua` valida los tipos de parcela (el atributo `plot_types_allowed` de los crops ya restringe la plantación, verifica que funcione con `greenhouse`).
   - El roadmap indica: "weather_match neutro siempre... pero con coste operativo de mantenimiento y sin bonus". Implementa un bosquejo (stub) o sistema básico para que los invernaderos cobren coste operativo por ciclo (si aplica, o indícalo en un ADR si prefieres aplazarlo a S16).

**Reglas de oro (no negociables):**

- Todo en inglés en el código.
- Naming conventions (`snake_case` para lua, nombres de eventos, etc.).
- Sin magic numbers fuera de `config`.

Cuando termines, escribe pruebas unitarias simples o de integración (si aplica) y notifica al fundador.
```
