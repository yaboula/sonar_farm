// ============================================================
// Farm Sonar — Route catalog.
// ============================================================
//
// Single source of truth for the NUI route table. Each entry
// declares:
//   - path:  canonical route (matches NuiRoute in types/nui.ts).
//   - mode:  which shell modes accept this route.
//   - label: i18n key for nav rendering.
//   - icon:  Lucide icon component for nav rendering.
//
// The shell consumes this list to render the sidebar (manager)
// or tab nav (field). Adding a new route requires:
//   1) Add the path string to `NuiRoute` in `types/nui.ts`.
//   2) Append the entry here.
//   3) Add labels under `nav.<key>` in `locales/{en,es}.json`.
//   4) Add a page component and register it in `AppRouter.tsx`.
// ============================================================

import {
    BarChart3,
    FileSignature,
    LayoutDashboard,
    ListChecks,
    MessageSquare,
    Package,
    ScrollText,
    Sprout,
    Users,
    Wallet,
    type LucideIcon,
} from 'lucide-react';

import type { NuiMode, NuiRoute } from '@/types/nui';

export interface RouteDescriptor {
    path: NuiRoute;
    labelKey: string;
    icon: LucideIcon;
    modes: ReadonlyArray<NuiMode>;
}

export const ROUTES: ReadonlyArray<RouteDescriptor> = [
    {
        path: '/dashboard',
        labelKey: 'nav.dashboard',
        icon: LayoutDashboard,
        modes: ['manager'],
    },
    {
        path: '/plots',
        labelKey: 'nav.plots',
        icon: Sprout,
        modes: ['manager', 'field'],
    },
    {
        path: '/batches',
        labelKey: 'nav.batches',
        icon: Package,
        modes: ['manager'],
    },
    {
        path: '/market',
        labelKey: 'nav.market',
        icon: BarChart3,
        modes: ['manager'],
    },
    {
        path: '/contracts',
        labelKey: 'nav.contracts',
        icon: FileSignature,
        modes: ['manager'],
    },
    {
        path: '/personnel',
        labelKey: 'nav.personnel',
        icon: Users,
        modes: ['manager'],
    },
    {
        path: '/finance',
        labelKey: 'nav.finance',
        icon: Wallet,
        modes: ['manager'],
    },
    {
        path: '/log',
        labelKey: 'nav.log',
        icon: ScrollText,
        modes: ['manager'],
    },
    {
        path: '/tasks',
        labelKey: 'nav.tasks',
        icon: ListChecks,
        modes: ['field'],
    },
    {
        path: '/messages',
        labelKey: 'nav.messages',
        icon: MessageSquare,
        modes: ['manager', 'field'],
    },
] as const;

/** Routes visible in the given mode, preserving catalog order. */
export function routesForMode(mode: NuiMode): ReadonlyArray<RouteDescriptor> {
    return ROUTES.filter((route) => route.modes.includes(mode));
}

/** Default landing route per mode. */
export function defaultRouteForMode(mode: NuiMode): NuiRoute {
    return mode === 'manager' ? '/dashboard' : '/plots';
}