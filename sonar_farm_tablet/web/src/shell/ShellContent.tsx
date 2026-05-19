// ============================================================
// Farm Sonar — Shell content wrapper.
// ============================================================
//
// Wraps the active page with the canonical max-width + padding
// per UI Playbook v2 §12. Scrolls vertically when the page
// content overflows.
// ============================================================

import type { ReactNode } from 'react';

interface ShellContentProps {
    variant: 'manager' | 'field';
    children: ReactNode;
}

export function ShellContent({ variant, children }: ShellContentProps): JSX.Element {
    const paddingClass = variant === 'manager' ? 'p-8' : 'p-6';
    const maxWidthStyle =
        variant === 'manager'
            ? { maxWidth: 'var(--fs-viewport-laptop-max)' }
            : { maxWidth: 'var(--fs-viewport-tablet-w)' };

    return (
        <main className={`flex-1 overflow-y-auto bg-fs-bg ${paddingClass}`} role="main">
            <div className="mx-auto w-full" style={maxWidthStyle}>
                {children}
            </div>
        </main>
    );
}
