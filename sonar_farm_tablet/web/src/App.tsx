// ============================================================
// Farm Sonar — App root.
// ============================================================
//
// Replaces the S0 splash with the real NUI shell lifecycle.
//
// Invariants (S4 §6 slice-specific DoD):
//   - In FiveM: renders NOTHING until `sonar:farm:nui:open` arrives.
//   - In Vite dev: starts visible in manager mode so designers can
//     preview the shell in a browser tab.
//   - ESC closes the shell, releases NUI focus via Lua callback,
//     and returns control to the game.
//   - Mode switch (`manager` ↔ `field`) remounts the shell tree so
//     the MemoryRouter resets to the appropriate landing route.
// ============================================================

import { I18nProvider } from '@/i18n';
import { useEscapeClose } from '@/hooks/useEscapeClose';
import { useNuiVisibility } from '@/hooks/useNuiVisibility';
import { ManagerShell } from '@/shell/ManagerShell';
import { TabletShell } from '@/shell/TabletShell';

export function App(): JSX.Element | null {
    const { visible, mode, route, close } = useNuiVisibility();

    useEscapeClose(close, visible);

    if (!visible) return null;

    return (
        <I18nProvider initialLocale="en">
            {mode === 'manager' ? (
                <ManagerShell key="manager" initialRoute={route} onClose={close} />
            ) : (
                <TabletShell key="field" initialRoute={route} onClose={close} />
            )}
        </I18nProvider>
    );
}
