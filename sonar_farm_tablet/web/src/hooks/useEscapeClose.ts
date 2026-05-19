// ============================================================
// Farm Sonar — useEscapeClose.
// ============================================================
//
// Global keydown listener that fires the supplied `close` callback
// when the user presses Escape. Intentionally scoped to the document
// (not a specific element) so the user can hit Esc at any moment
// to release NUI focus and return control to the game.
//
// Skips closing when `enabled` is false (e.g. shell hidden anyway).
// ============================================================

import { useEffect } from 'react';

export function useEscapeClose(close: () => void, enabled: boolean): void {
    useEffect(() => {
        if (!enabled) return;

        function onKeyDown(event: KeyboardEvent) {
            if (event.key === 'Escape') {
                event.preventDefault();
                close();
            }
        }

        window.addEventListener('keydown', onKeyDown);
        return () => {
            window.removeEventListener('keydown', onKeyDown);
        };
    }, [close, enabled]);
}
