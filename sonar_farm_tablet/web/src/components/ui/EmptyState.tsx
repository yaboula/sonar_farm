// ============================================================
// Farm Sonar — EmptyState primitive.
// ============================================================
//
// Canonical empty pattern per UI Playbook v2 §11.2.
// Centered icon + heading + body + optional CTA.
//
// Caller is responsible for providing the icon element (usually
// via the `<Icon>` wrapper with size "xl"). Strings come from i18n.
// ============================================================

import type { ReactNode } from 'react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';

import { Button } from './Button';

interface EmptyStateAction {
    label: string;
    onClick: () => void;
}

interface EmptyStateProps {
    icon?: ReactNode;
    title: string;
    body?: string;
    action?: EmptyStateAction;
    className?: string;
}

export function EmptyState({ icon, title, body, action, className }: EmptyStateProps): JSX.Element {
    const cls = [
        'flex flex-col items-center justify-center gap-4 px-6 py-12 text-center',
        className,
    ]
        .filter(Boolean)
        .join(' ');

    return (
        <div className={cls} role="status">
            {icon ? <div className="text-fs-fg-muted">{icon}</div> : null}
            <Heading level="h3" as="h2">
                {title}
            </Heading>
            {body ? (
                <Body size="default" muted className="max-w-sm">
                    {body}
                </Body>
            ) : null}
            {action ? (
                <Button variant="ghost" size="md" onClick={action.onClick}>
                    {action.label}
                </Button>
            ) : null}
        </div>
    );
}
