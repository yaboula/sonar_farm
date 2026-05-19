// ============================================================
// Farm Sonar — Application router.
// ============================================================
//
// Uses MemoryRouter (not HashRouter / BrowserRouter) because the
// FiveM CEF iframe never exposes a URL bar to the player and we
// must not contaminate the CEF history stack. Decision firmada
// en docs/04_UI_PLAYBOOK.md §13.5.
//
// The `initialRoute` prop seeds the router whenever Lua sends
// `sonar:farm:nui:open` with a payload route. Switching mode
// remounts the MemoryRouter so the in-memory history resets.
// ============================================================

import { MemoryRouter, Navigate, Route, Routes } from 'react-router-dom';

import { BatchesPage } from '@/pages/BatchesPage';
import { ContractsPage } from '@/pages/ContractsPage';
import { DashboardPage } from '@/pages/DashboardPage';
import { FinancePage } from '@/pages/FinancePage';
import { LogPage } from '@/pages/LogPage';
import { MarketPage } from '@/pages/MarketPage';
import { MessagesPage } from '@/pages/MessagesPage';
import { PersonnelPage } from '@/pages/PersonnelPage';
import { PlotsPage } from '@/pages/PlotsPage';
import { TasksPage } from '@/pages/TasksPage';
import type { NuiRoute } from '@/types/nui';

interface AppRouterProps {
    initialRoute: NuiRoute;
    children?: React.ReactNode;
}

/**
 * The route table — must be rendered inside a MemoryRouter context.
 * Each shell (ManagerShell, TabletShell) owns its own MemoryRouter so
 * that NavLink / useLocation work in sibling nav components.
 */
export function AppRoutes(): JSX.Element {
    return (
        <Routes>
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/plots" element={<PlotsPage />} />
            <Route path="/batches" element={<BatchesPage />} />
            <Route path="/market" element={<MarketPage />} />
            <Route path="/contracts" element={<ContractsPage />} />
            <Route path="/personnel" element={<PersonnelPage />} />
            <Route path="/finance" element={<FinancePage />} />
            <Route path="/log" element={<LogPage />} />
            <Route path="/tasks" element={<TasksPage />} />
            <Route path="/messages" element={<MessagesPage />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
    );
}

/**
 * Standalone router — wraps AppRoutes in its own MemoryRouter.
 * Use this only when the caller has no existing Router context.
 * ManagerShell and TabletShell own their own MemoryRouter instead
 * so NavLink siblings can live outside the <Routes> tree.
 */
export function AppRouter({ initialRoute }: AppRouterProps): JSX.Element {
    return (
        <MemoryRouter initialEntries={[initialRoute]}>
            <AppRoutes />
        </MemoryRouter>
    );
}
