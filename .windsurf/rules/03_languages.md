---
trigger: always_on
---

# Language Policy (always-on)

## English (no exceptions)

- All code (Lua, TypeScript, React, SQL).
- All variable names, function names, file names, class names.
- All code comments and docstrings.
- All commit messages.
- Mini-briefs (`docs/slices/SXX_*.md`) — consumed by AI agents.
- ADRs (`docs/02_DECISIONS.md`) — consumed by AI agents.
- Spike reports (`docs/spikes/*.md`).
- Research reports (`docs/research/*.md`).
- Sub-agent prompts (`docs/slices/SXX_*.prompts.md`).
- Internal API documentation.

## Spanish (founder-facing only)

- `docs/00_BIBLE.md`.
- `docs/01_ROADMAP.md`.
- `docs/03_AI_PLAYBOOK.md`.
- `docs/04_UI_PLAYBOOK.md` (when created).
- README.md (top-level).
- Communication with the founder in chat.

## i18n (user-facing UI strings)

- Never hardcoded in code.
- Always via `locales/es.lua` + `locales/en.lua` keys.
- React: via `t('key.path')` (react-i18next or custom hook).
- Lua: via `Locale('key.path')`.
- Default fallback locale: `en`.
- New strings added: BOTH `es.lua` AND `en.lua` updated in same commit.

## Mixing rules

- Code blocks inside Spanish docs are written in English (no translation of code).
- Diagrams and ASCII art use English labels even inside Spanish docs.
- Acronyms (NPK, IBAN, FSM, MLO, NUI, DoD) are universal.

## Forbidden mixing

- Mixed-language identifiers (`get_parcela`, `companyEmpresa`).
- Spanish strings hardcoded in JSX/Lua bypassing i18n.
- English commit messages translating Spanish code (code must already be English).
