import { useEffect, useState } from 'react';

import { VERSION } from '@/lib/version';

// ============================================================
// S0 splash screen.
//
// This is the FIRST visible artifact of Farm Sonar. It exists to
// validate the toolchain end-to-end (Vite + React + Tailwind v4 +
// theme tokens). It is NOT the final UI shell — that lives in S4.
//
// Wooow Test (Bible §4): when the founder runs `pnpm dev` they
// must immediately recognize the brand language: charcoal canvas,
// Geist Sans wordmark, lima neón #CCFF00 pulsing dot, mono footer.
//
// IN-GAME VISIBILITY (S1 fix):
// The NUI iframe is always rendered by FiveM. To avoid the splash
// covering the game canvas, we default to `visible = false` and
// render nothing. The NUI shows only when:
//   - We are in Vite dev mode (`pnpm dev` browser preview), OR
//   - A `sonar:tablet:open` NUI message arrives from Lua (S4 will
//     own this lifecycle; today no Lua sends it, so the splash
//     never appears in-game).
// ============================================================

interface NuiMessage {
    action?: string;
}

export function App(): JSX.Element | null {
    const [visible, setVisible] = useState<boolean>(import.meta.env.DEV);

    useEffect(() => {
        function handler(event: MessageEvent<NuiMessage>) {
            const data = event.data;
            if (!data || typeof data !== 'object') return;
            if (data.action === 'sonar:tablet:open') setVisible(true);
            if (data.action === 'sonar:tablet:close') setVisible(false);
        }
        window.addEventListener('message', handler);
        return () => window.removeEventListener('message', handler);
    }, []);

    if (!visible) return null;

    return (
        <main
            className="flex h-full w-full flex-col items-center justify-center bg-fs-nav text-fs-fg-inverse"
            data-resource="sonar_farm_tablet"
        >
            <div className="flex flex-col items-center gap-8">
                <div className="flex items-center gap-4">
                    <span
                        aria-hidden
                        className="fs-pulse h-3 w-3 rounded-full bg-fs-accent shadow-[var(--shadow-fs-glow)]"
                    />
                    <h1 className="text-4xl font-semibold tracking-tight md:text-5xl">
                        Farm Sonar
                    </h1>
                </div>

                <p className="max-w-md text-center text-sm leading-relaxed text-fs-fg-inverse/70">
                    Premium farming simulation for FiveM.
                    <br />
                    Foundation phase — workspace skeleton ready.
                </p>
            </div>

            <footer className="fs-mono absolute bottom-6 text-xs text-fs-fg-inverse/40">
                v{VERSION} · sonar_farm_tablet
            </footer>
        </main>
    );
}
