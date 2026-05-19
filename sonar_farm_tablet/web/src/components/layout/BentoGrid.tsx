// ============================================================
// Farm Sonar — BentoGrid signature component.
// ============================================================
//
// Implements the Bento Grid paradigm per UI Playbook v2 §5.
//   - Default gap: 16px (--spacing-fs-4).
//   - Base columns: 12 (laptop) or 8 (tablet).
//   - Spans accepted: number 1..12 or per-viewport { laptop, tablet }.
//
// Internally renders a CSS grid container; spans use explicit
// inline styles to satisfy noUncheckedIndexedAccess. Compound
// API:
//
//   <BentoGrid gap="md" columns={12}>
//     <BentoGrid.Item span={4}>...</BentoGrid.Item>
//     <BentoGrid.Item span={{ laptop: 8, tablet: 4 }}>...</BentoGrid.Item>
//   </BentoGrid>
// ============================================================

import type { CSSProperties, HTMLAttributes, ReactNode } from 'react';

export type BentoGap = 'sm' | 'md' | 'lg';
export type BentoColumns = 8 | 12;

const GAP_CLASS: Record<BentoGap, string> = {
    sm: 'gap-2', // 8
    md: 'gap-4', // 16 (canonical)
    lg: 'gap-6', // 24
};

interface BentoGridProps extends HTMLAttributes<HTMLDivElement> {
    gap?: BentoGap;
    columns?: BentoColumns;
    children: ReactNode;
}

function BentoGridRoot({
    gap = 'md',
    columns = 12,
    className,
    style,
    children,
    ...rest
}: BentoGridProps): JSX.Element {
    const cls = ['grid w-full', GAP_CLASS[gap], className].filter(Boolean).join(' ');
    const gridStyle: CSSProperties = {
        gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
        ...style,
    };
    return (
        <div
            className={cls}
            style={gridStyle}
            data-fs-bento-columns={columns}
            data-fs-bento-gap={gap}
            {...rest}
        >
            {children}
        </div>
    );
}

export type BentoSpan = number | { laptop: number; tablet?: number };

interface BentoItemProps extends HTMLAttributes<HTMLDivElement> {
    span?: BentoSpan;
    children: ReactNode;
}

function BentoGridItem({
    span = 12,
    className,
    style,
    children,
    ...rest
}: BentoItemProps): JSX.Element {
    const laptopSpan = typeof span === 'number' ? span : span.laptop;
    const itemStyle: CSSProperties = {
        gridColumn: `span ${laptopSpan} / span ${laptopSpan}`,
        ...style,
    };
    return (
        <div
            className={['min-w-0', className].filter(Boolean).join(' ')}
            style={itemStyle}
            data-fs-bento-span={laptopSpan}
            {...rest}
        >
            {children}
        </div>
    );
}

export const BentoGrid = Object.assign(BentoGridRoot, {
    Item: BentoGridItem,
});
