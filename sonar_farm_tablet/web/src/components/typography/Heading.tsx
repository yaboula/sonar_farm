// ============================================================
// Farm Sonar — Heading primitive.
// ============================================================
//
// Implements the typography scale signed in UI Playbook v2 §4.2.
// Weights restricted to 500 (h3) / 600 (display, h1, h2) — never
// 700+. Color defaults to `text-fs-fg`; opt-in via className.
// ============================================================

import type { HTMLAttributes, ReactNode } from 'react';

export type HeadingLevel = 'display' | 'h1' | 'h2' | 'h3';

interface HeadingProps extends Omit<HTMLAttributes<HTMLHeadingElement>, 'children'> {
    level?: HeadingLevel;
    /**
     * Override the rendered DOM element. Defaults to the semantic
     * heading matching `level` (display → h1). Accepts `span` when
     * the heading sits inline in a flex row with siblings.
     */
    as?: 'h1' | 'h2' | 'h3' | 'h4' | 'span';
    children: ReactNode;
}

const LEVEL_CLASSES: Record<HeadingLevel, string> = {
    display: 'text-[2.5rem] leading-[1.1] font-semibold tracking-[-0.02em]',
    h1: 'text-[2rem] leading-[1.15] font-semibold tracking-[-0.015em]',
    h2: 'text-[1.5rem] leading-[1.2] font-semibold tracking-[-0.01em]',
    h3: 'text-[1.25rem] leading-[1.3] font-medium',
};

export function Heading({
    level = 'h2',
    as,
    className,
    children,
    ...rest
}: HeadingProps): JSX.Element {
    const Tag = as ?? (level === 'display' ? 'h1' : level);
    const cls = [LEVEL_CLASSES[level], 'text-fs-fg', className].filter(Boolean).join(' ');
    return (
        <Tag className={cls} {...rest}>
            {children}
        </Tag>
    );
}
