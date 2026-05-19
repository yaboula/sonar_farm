// ============================================================
// Farm Sonar — Manager sidebar (240px).
// ============================================================
//
// Vertical nav for the Manager shell. Width comes from the
// `--fs-sidebar-w-manager` token per UI Playbook v2 §12.1.
// Items are sourced from the route catalog filtered by mode,
// so adding a route never requires editing this component.
//
// Active item gets the lime accent fill + dark text.
// Inactive items show in muted gray on a soft hover.
// ============================================================

import { NavLink } from 'react-router-dom';

import { Body } from '@/components/typography/Body';
import { Icon } from '@/components/ui/Icon';
import { useI18n } from '@/i18n';
import { routesForMode } from '@/router/routes';
import type { NuiMode } from '@/types/nui';

interface ShellSidebarProps {
    mode: NuiMode;
}

export function ShellSidebar({ mode }: ShellSidebarProps): JSX.Element {
    const { t } = useI18n();
    const routes = routesForMode(mode);

    return (
        <aside
            className="flex flex-col gap-1 border-r border-fs-border bg-fs-surface px-3 py-6"
            style={{ width: 'var(--fs-sidebar-w-manager)' }}
            aria-label="Primary navigation"
        >
            <nav className="flex flex-col gap-1" role="navigation">
                {routes.map((route) => (
                    <NavLink
                        key={route.path}
                        to={route.path}
                        className={({ isActive }) =>
                            [
                                'group flex items-center gap-3 rounded-2xl px-3 py-2.5',
                                'transition-colors duration-[var(--duration-fs-fast)]',
                                isActive
                                    ? 'bg-fs-accent text-fs-fg'
                                    : 'text-fs-fg-muted hover:bg-[rgb(150_156_156_/_0.08)] hover:text-fs-fg',
                            ].join(' ')
                        }
                    >
                        <Icon as={route.icon} size="md" />
                        <Body size="default" as="span" className="font-medium text-current">
                            {t(route.labelKey)}
                        </Body>
                    </NavLink>
                ))}
            </nav>
        </aside>
    );
}
