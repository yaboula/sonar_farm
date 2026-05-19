// ============================================================
// Farm Sonar — Tablet shell (1280×800 overlay).
// ============================================================
//
// Overlay centered on the FiveM game canvas. Outside the overlay
// the React tree renders transparent so the game stays visible.
// Per UI Playbook v2 §12.2.
//
// Tab nav lives inline at the top of the content area (no
// sidebar) since the Tablet only exposes reduced apps.
// ============================================================

import { NavLink } from 'react-router-dom';

import { Body } from '@/components/typography/Body';
import { Icon } from '@/components/ui/Icon';
import { useI18n } from '@/i18n';
import { AppRouter } from '@/router/AppRouter';
import { routesForMode } from '@/router/routes';
import type { NuiRoute } from '@/types/nui';

import { ShellContent } from './ShellContent';
import { ShellTopBar } from './ShellTopBar';

interface TabletShellProps {
    initialRoute: NuiRoute;
    onClose: () => void;
}

export function TabletShell({ initialRoute, onClose }: TabletShellProps): JSX.Element {
    const { t } = useI18n();
    const routes = routesForMode('field');

    return (
        <div className="flex h-full w-full items-center justify-center bg-transparent">
            <div
                className="fs-slide-up flex flex-col overflow-hidden rounded-2xl border border-fs-border bg-fs-bg text-fs-fg shadow-[var(--shadow-fs-glow)]"
                style={{
                    width: 'min(var(--fs-viewport-tablet-w), 100vw)',
                    height: 'min(var(--fs-viewport-tablet-h), 100vh)',
                }}
                role="dialog"
                aria-modal="true"
                aria-label={t('shell.brand')}
            >
                <ShellTopBar mode="field" variant="field" onClose={onClose} />
                <nav
                    className="flex items-center gap-2 border-b border-fs-border bg-fs-surface px-6 py-3"
                    role="navigation"
                    aria-label="Tablet apps"
                >
                    {routes.map((route) => (
                        <NavLink
                            key={route.path}
                            to={route.path}
                            className={({ isActive }) =>
                                [
                                    'inline-flex items-center gap-2 rounded-2xl px-3 py-1.5',
                                    'transition-colors duration-[var(--duration-fs-fast)]',
                                    isActive
                                        ? 'bg-fs-accent text-fs-fg'
                                        : 'text-fs-fg-muted hover:bg-[rgb(150_156_156_/_0.08)] hover:text-fs-fg',
                                ].join(' ')
                            }
                        >
                            <Icon as={route.icon} size="sm" />
                            <Body size="small" as="span" className="font-medium text-current">
                                {t(route.labelKey)}
                            </Body>
                        </NavLink>
                    ))}
                </nav>
                <ShellContent variant="field">
                    <AppRouter initialRoute={initialRoute} />
                </ShellContent>
            </div>
        </div>
    );
}
