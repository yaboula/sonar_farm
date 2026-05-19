// ============================================================
// Farm Sonar — ErrorState primitive.
// ============================================================
//
// Canonical error pattern per UI Playbook v2 §11.3.
// Icon defaults to TriangleAlert (in danger fg) but caller can
// override; CTA defaults to a "Retry" button when `retry` is
// supplied.
// ============================================================

import type { ReactNode } from 'react';

import { TriangleAlert } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';

import { Button } from './Button';

interface ErrorStateProps {
    icon?: ReactNode;
    title: string;
    body?: string;
    retry?: () => void;
    retryLabel?: string;
    className?: string;
}

export function ErrorState({
    icon,
    title,
    body,
    retry,
    retryLabel,
    className,
}: ErrorStateProps): JSX.Element {
    const cls = [
        'flex flex-col items-center justify-center gap-4 px-6 py-12 text-center',
        className,
    ]
        .filter(Boolean)
        .join(' ');

    return (
        <div className={cls} role="alert">
            <div className="text-fs-danger-fg">
                {icon ?? <TriangleAlert size={32} strokeWidth={1.5} aria-hidden="true" />}
            </div>
            <Heading level="h3" as="h2">
                {title}
            </Heading>
            {body ? (
                <Body size="default" muted className="max-w-sm">
                    {body}
                </Body>
            ) : null}
            {retry && retryLabel ? (
                <Button variant="secondary" size="md" onClick={retry}>
                    {retryLabel}
                </Button>
            ) : null}
        </div>
    );
}
