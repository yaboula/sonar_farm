---
name: cascade-file-operations-best-practices
description: lee este archivo antes de realizar operaciones de archivos en Cascade
---

# Consejos para operaciones de archivos en Cascade

## Principales causas de errores

1. **No leer el archivo antes de editar**
   - Siempre usa `read_file` antes de `edit` o `multi_edit`
   - El sistema rechaza ediciones sin lectura previa

2. **Strings no únicos en `edit`**
   - El `old_string` debe ser único en el archivo
   - Si hay duplicados, usa más contexto alrededor para hacerlo único
   - O usa `replace_all: true` si es intencional

3. **Modificar archivos que no existen**
   - `edit` falla si el archivo no existe
   - Para archivos nuevos, usa `write_to_file` con `EmptyFile: false`

4. **Rutas relativas vs absolutas**
   - `edit` y `read_file` requieren **rutas absolutas**
   - `write_to_file` también requiere ruta absoluta
   - El workspace es `d:\Granja_Sonar`

5. **Bloques multi-línea como ancla**
   - Evita usar bloques de 10+ líneas como `old_string`
   - Si una sola línea vacía o espacio no coincide exactamente, todo falla
   - El patcher es estricto con whitespace (espacios, tabs, líneas vacías)

6. **Líneas vacías como ancla**
   - Nunca uses líneas vacías como parte del ancla
   - Son frágiles porque el patcher es estricto con formato
   - Ancla en código real, no en whitespace

7. **Cambios grandes en un solo edit**
   - Para ediciones >300 líneas, divide en múltiples `edit` pequeños
   - Los cambios grandes tienen más riesgo de fallar por contexto insuficiente

## Patrones que funcionan bien

**Para cambios pequeños (1-2 líneas):**

1. `read_file` (ver el contenido exacto)
2. `edit` (con `old_string` único y contexto suficiente)

**Para cambios múltiples en un archivo:**

1. `read_file`
2. `multi_edit` (varios edits en una operación)

**Para archivos nuevos:**

- `write_to_file` con ruta absoluta completa

**Para reemplazar una variable en todo el archivo:**

- `edit` con `replace_all: true`

## Cómo pedirme cambios

**Bien:**

- "En sonar_farm_core/config.lua, cambia MAX_PLOTS de 50 a 100"

**Mejor:**

- "Lee sonar_farm_core/config.lua, luego cambia MAX_PLOTS de 50 a 100"

**Evita:**

- Pedir cambios en múltiples archivos sin especificar cuál primero
- Pedir "arregla todo este archivo" sin contexto
- Cambios que requieren entender lógica compleja sin que lea el archivo primero
