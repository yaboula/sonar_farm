// ============================================================
// Farm Sonar — NUI message contracts (typed).
// ============================================================
//
// Source of truth for messages exchanged between the FiveM Lua
// client and this React NUI app. Both sides MUST agree on this
// shape; Integration Agent imports the equivalent contract on
// the Lua side via `sonar_farm_tablet/client/*`.
//
// Names follow rule .windsurf/rules/02_naming_conventions.md:
//   - Inbound action: `sonar:farm:nui:<verb>`.
//   - Outbound callback endpoint: `close` (POST to
//     `https://sonar_farm_tablet/close`).
//
// Coordination contract: see
//   docs/slices/S4_nui_shell_design_system.prompts.md §Coordination.
// ============================================================

/** Operating modes of the shell. Bible §15 firmas dos surfaces. */
export type NuiMode = 'manager' | 'field';

/** Canonical route catalog firmado en S4. */
export type NuiRoute =
    | '/dashboard'
    | '/plots'
    | '/batches'
    | '/market'
    | '/contracts'
    | '/personnel'
    | '/finance'
    | '/log'
    | '/tasks'
    | '/messages';

/** Discriminated union of all messages this NUI accepts from Lua. */
export type NuiInboundMessage =
    | {
          action: 'sonar:farm:nui:open';
          payload: {
              mode: NuiMode;
              route?: NuiRoute;
          };
      }
    | {
          action: 'sonar:farm:nui:close';
      };

/** Response shape of the `close` callback that the NUI invokes on ESC. */
export type NuiCloseCallbackResponse = { ok: true } | { ok: false; error: string };

// ------------------------------------------------------------
// Type guards — defensive parsing of `window.message` data.
// FiveM may deliver malformed payloads when other resources
// share the NUI iframe; we never trust them blindly.
// ------------------------------------------------------------

export function isNuiMode(value: unknown): value is NuiMode {
    return value === 'manager' || value === 'field';
}

export function isNuiRoute(value: unknown): value is NuiRoute {
    return (
        typeof value === 'string' &&
        [
            '/dashboard',
            '/plots',
            '/batches',
            '/market',
            '/contracts',
            '/personnel',
            '/finance',
            '/log',
            '/tasks',
            '/messages',
        ].includes(value)
    );
}

export function isNuiInboundMessage(value: unknown): value is NuiInboundMessage {
    if (!value || typeof value !== 'object') return false;
    const candidate = value as { action?: unknown; payload?: unknown };

    if (candidate.action === 'sonar:farm:nui:close') return true;

    if (candidate.action === 'sonar:farm:nui:open') {
        if (!candidate.payload || typeof candidate.payload !== 'object') return false;
        const payload = candidate.payload as { mode?: unknown; route?: unknown };
        if (!isNuiMode(payload.mode)) return false;
        if (payload.route !== undefined && !isNuiRoute(payload.route)) return false;
        return true;
    }

    return false;
}
