# 📋 Farm Sonar — Architecture Decision Records (ADRs)

> **Propósito.** Registro append-only de decisiones de arquitectura no obvias o que afecten futuros slices.
>
> **Cuándo crear un ADR.** Cuando un slice tome una decisión que:
> - No esté ya cubierta por el `00_BIBLE.md`.
> - Tenga alternativas razonables que se descartaron.
> - Afecte a slices futuros (no es local al slice actual).
> - Sería costosa de revertir.
>
> **Formato corto.** Cada ADR ~20 líneas. Si necesitas más, probablemente debe ir al Bible.

---

## Plantilla

```markdown
## ADR-NNN — Título corto en infinitivo

**Fecha:** YYYY-MM-DD
**Estado:** PROPOSED | ACCEPTED | DEPRECATED | SUPERSEDED-BY-ADR-NNN
**Slice origen:** SXX
**Contexto:** 2-3 líneas. ¿Qué situación nos forzó a decidir?
**Opciones consideradas:**
- A — descripción · pros · contras
- B — descripción · pros · contras
**Decisión:** opción X. Razón principal en 1 línea.
**Consecuencias:** qué cambia en el código / docs / futuros slices.
```

---

<!-- ADRs se añaden a continuación en orden cronológico -->
