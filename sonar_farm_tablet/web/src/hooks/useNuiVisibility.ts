// ============================================================
// Farm Sonar — useNuiVisibility.
// ============================================================
//
// State machine for the NUI shell visibility + active mode + route.
// Invariants:
//   - In FiveM: starts hidden. Only `sonar:farm:nui:open` flips visible.
//   - In Vite dev: starts visible (manager / /dashboard) for browser
//     productivity; respects subsequent close messages all the same.
//   - `close()` is the only way to flip back to hidden from React.
//   - Idempotent: repeated open with same payload does not trigger
//     unnecessary re-renders thanks to useReducer + structural eq.
// ============================================================

import { useCallback, useMemo, useReducer } from 'react';

import { isDev } from '@/lib/env';
import { fetchNui } from '@/lib/nui';
import type { NuiCloseCallbackResponse, NuiInboundMessage, NuiMode, NuiRoute } from '@/types/nui';

import { useNuiMessages } from './useNuiMessages';

interface ShellState {
    visible: boolean;
    mode: NuiMode;
    route: NuiRoute;
}

type Action = { type: 'open'; mode: NuiMode; route: NuiRoute } | { type: 'close' };

function reducer(state: ShellState, action: Action): ShellState {
    switch (action.type) {
        case 'open':
            if (state.visible && state.mode === action.mode && state.route === action.route) {
                return state;
            }
            return { visible: true, mode: action.mode, route: action.route };
        case 'close':
            if (!state.visible) return state;
            return { ...state, visible: false };
        default:
            return state;
    }
}

interface UseNuiVisibilityResult {
    visible: boolean;
    mode: NuiMode;
    route: NuiRoute;
    close: () => Promise<void>;
}

const DEFAULT_ROUTE: NuiRoute = '/dashboard';

export function useNuiVisibility(): UseNuiVisibilityResult {
    const initial = useMemo<ShellState>(
        () => ({
            visible: isDev(),
            mode: 'manager',
            route: DEFAULT_ROUTE,
        }),
        []
    );

    const [state, dispatch] = useReducer(reducer, initial);

    const handleMessage = useCallback((message: NuiInboundMessage) => {
        if (message.action === 'sonar:farm:nui:open') {
            dispatch({
                type: 'open',
                mode: message.payload.mode,
                route: message.payload.route ?? DEFAULT_ROUTE,
            });
            return;
        }
        if (message.action === 'sonar:farm:nui:close') {
            dispatch({ type: 'close' });
        }
    }, []);

    useNuiMessages(handleMessage);

    const close = useCallback(async () => {
        dispatch({ type: 'close' });
        await fetchNui<NuiCloseCallbackResponse>('close', {}, { ok: true });
    }, []);

    return {
        visible: state.visible,
        mode: state.mode,
        route: state.route,
        close,
    };
}
