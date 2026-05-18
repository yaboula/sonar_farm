---
description: Investigación técnica time-boxed (max 2 días) sobre un riesgo o incógnita. Output reporte con recomendación.
---

# Spike — `/spike <topic>`

Use this workflow when a slice depends on a technical unknown that must be resolved before scoping (e.g. R2 in the Risk Register: "Drones NUI render-to-texture viability").

## Inputs

- `<topic>` — short slug (e.g. `drone-nui-render`, `oxmysql-perf`, `framer-nui-overhead`).

## Constraints

- **Time-boxed**: max 2 working days. If after 2 days there is no clear answer, that itself is the answer (recommendation: defer or pivot the dependent slice).
- **No production code**: spikes produce throwaway prototypes only, in a `/spikes/<topic>/` sandbox folder, NOT in `sonar_farm_core/` or `sonar_farm_tablet/`.
- **One artifact required**: `docs/spikes/<topic>.md` (in English) with findings + recommendation.

## Steps

1. **Frame the question.** Write at the top of `docs/spikes/<topic>.md`:
   - **Question**: 1-2 lines, sharp.
   - **Why it matters**: which slice(s) depend on this.
   - **Time budget**: planned start + end date.
   - **Decision criteria**: what answer would unblock vs block.

2. **Survey existing knowledge.**
   - Run `/research <topic>` (web search docs + community).
   - Search `docs/_archive/sonar_legacy/` for prior art.
   - Search the codebase for related patterns.

3. **Build minimal prototype.** In `/spikes/<topic>/`:
   - Smallest possible code that proves or disproves the question.
   - No test coverage required.
   - No production-quality polish.

4. **Run the experiment.** Document:
   - What was tried.
   - What worked.
   - What did not.
   - Performance numbers if applicable.

5. **Write the recommendation.** In `docs/spikes/<topic>.md`, conclude with:
   - **Verdict**: `VIABLE` | `VIABLE_WITH_CAVEATS` | `NOT_VIABLE` | `INCONCLUSIVE`.
   - **Recommendation**: 1 paragraph telling future-you exactly what to do in the dependent slice.
   - **Caveats**: what limitations or risks remain.
   - **References**: links to docs/forum threads/repos consulted.

6. **If verdict triggers an architectural decision** → create an ADR in `docs/02_DECISIONS.md` linking to the spike report.

7. **Cleanup**: spikes folder can stay for reference, but flag it as throwaway (`/spikes/<topic>/README.md` saying "throwaway prototype, see docs/spikes/<topic>.md").

8. **Report to user**: 3-line summary with verdict + next action.

## Common spike triggers

- Risk Register entries marked 🚨 (R2 drones, R10 weather sync, etc.).
- Founder request: "before we commit to slice X, let's check Y is feasible".
- During a slice, an unexpected technical question that would balloon the slice if explored inline.
