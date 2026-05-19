// ============================================================
// Farm Sonar — Mono primitive.
// ============================================================
//
// JetBrains Mono for IDs, IBANs, dates, coordinates, monospace
// metadata per Bible §1.1. Uses the `.fs-mono` utility from
// globals.css which also enables tnum/zero font features.
// ============================================================

import type { HTMLAttributes, ReactNode } from 'react';

export type MonoSize = 'default' | 'small';

interface MonoProps extends Omit<HTMLAttributes<HTMLSpanElement>, 'children'> {
    size?: MonoSize;
    children: ReactNode;
}

const SIZE_CLASSES: Record<MonoSize, string> = {
    default: 'text-[1rem] leading-[1.45]',
    small: 'text-[0.875rem] leading-[1.4]',
};

export function Mono({ size = 'default', className, children, ...rest }: MonoProps): JSX.Element {
    const cls = ['fs-mono', SIZE_CLASSES[size], 'text-fs-fg', className].filter(Boolean).join(' ');
    return (
        <span className={cls} {...rest}>
            {children}
        </span>
    );
}
