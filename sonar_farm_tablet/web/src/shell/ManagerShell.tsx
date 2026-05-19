// ============================================================
// Farm Sonar — Manager shell (Laptop, 1920×1080 fullscreen).
// ============================================================
//
// Layout: TopBar (64px) + Sidebar (240px) + Content (rest).
// Per UI Playbook v2 §12.1.
//
// The router is mounted INSIDE the shell so navigation happens
// in the content area without re-rendering the topbar/sidebar.
// ============================================================

import { MemoryRouter } from 'react-router-dom';

import { AppRoutes } from '@/router/AppRouter';
import type { NuiRoute } from '@/types/nui';

import { ShellContent } from './ShellContent';
import { ShellSidebar } from './ShellSidebar';
import { ShellTopBar } from './ShellTopBar';

interface ManagerShellProps {
    initialRoute: NuiRoute;
    onClose: () => void;
}

export function ManagerShell({ initialRoute, onClose }: ManagerShellProps): JSX.Element {
    return (
        <MemoryRouter initialEntries={[initialRoute]}>
            <div className="fs-fade-in flex h-full w-full flex-col bg-fs-bg text-fs-fg">
                <ShellTopBar mode="manager" variant="manager" onClose={onClose} />
                <div className="flex flex-1 overflow-hidden">
                    <ShellSidebar mode="manager" />
                    <ShellContent variant="manager">
                        <AppRoutes />
                    </ShellContent>
                </div>
            </div>
        </MemoryRouter>
    );
}
