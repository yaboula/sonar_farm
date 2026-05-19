// ============================================================
// Farm Sonar — Card primitive (flat minimalista).
// ============================================================
//
// Surface per ADR-006 + UI Playbook v2 §3.1:
//   - bg-fs-surface (#FFFFFF)
//   - shadow-none
//   - border 1px --fs-border
//   - rounded-2xl (16px)
//
// Three padding variants per §10.2. Compound slots Card.Header /
// Card.Body / Card.Footer are optional sugar; the bare <Card>
// renders children directly inside the padded box.
//
// `interactive` adds focus ring + cursor pointer, intended for
// click-through cards (e.g. batch card opening a detail page).
// ============================================================

import type { HTMLAttributes, ReactNode } from 'react';

export type CardPadding = 'compact' | 'comfortable' | 'lg';

const PADDING_CLASSES: Record<CardPadding, string> = {
    compact: 'p-4',
    comfortable: 'p-6',
    lg: 'p-8',
};

interface CardProps extends HTMLAttributes<HTMLDivElement> {
    padding?: CardPadding;
    interactive?: boolean;
    children: ReactNode;
}

function CardRoot({
    padding = 'comfortable',
    interactive = false,
    className,
    children,
    ...rest
}: CardProps): JSX.Element {
    const cls = [
        'rounded-2xl border bg-fs-surface',
        'border-fs-border',
        PADDING_CLASSES[padding],
        interactive ? 'cursor-pointer transition-colors duration-[var(--duration-fs-fast)]' : '',
        className,
    ]
        .filter(Boolean)
        .join(' ');

    if (interactive) {
        return (
            <div className={cls} role="button" tabIndex={0} {...rest}>
                {children}
            </div>
        );
    }

    return (
        <div className={cls} {...rest}>
            {children}
        </div>
    );
}

function CardHeader({ className, children, ...rest }: HTMLAttributes<HTMLDivElement>): JSX.Element {
    const cls = ['mb-4 flex items-start justify-between gap-3', className]
        .filter(Boolean)
        .join(' ');
    return (
        <div className={cls} {...rest}>
            {children}
        </div>
    );
}

function CardBody({ className, children, ...rest }: HTMLAttributes<HTMLDivElement>): JSX.Element {
    const cls = ['flex flex-col gap-3', className].filter(Boolean).join(' ');
    return (
        <div className={cls} {...rest}>
            {children}
        </div>
    );
}

function CardFooter({ className, children, ...rest }: HTMLAttributes<HTMLDivElement>): JSX.Element {
    const cls = ['mt-4 flex items-center justify-between gap-3', className]
        .filter(Boolean)
        .join(' ');
    return (
        <div className={cls} {...rest}>
            {children}
        </div>
    );
}

export const Card = Object.assign(CardRoot, {
    Header: CardHeader,
    Body: CardBody,
    Footer: CardFooter,
});
