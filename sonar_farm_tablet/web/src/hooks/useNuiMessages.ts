// ============================================================
// Farm Sonar — useNuiMessages.
// ============================================================
//
// Typed `window.message` listener. Calls the supplied handler ONLY
// when the incoming payload passes the discriminated-union guard.
// Cleans the listener on unmount; safe for StrictMode double-invoke.
// ============================================================

import { useEffect } from 'react';

import { isNuiInboundMessage, type NuiInboundMessage } from '@/types/nui';

export function useNuiMessages(handler: (message: NuiInboundMessage) => void): void {
    useEffect(() => {
        function onMessage(event: MessageEvent<unknown>) {
            const data = event.data;
            if (!isNuiInboundMessage(data)) return;
            handler(data);
        }

        window.addEventListener('message', onMessage);
        return () => {
            window.removeEventListener('message', onMessage);
        };
    }, [handler]);
}
