// ============================================================
// Farm Sonar — Skeleton primitive.
// ============================================================
//
// Loading placeholder per UI Playbook v2 §10.8 + §11.1.
// Uses the `.fs-skeleton` utility from globals.css which respects
// `prefers-reduced-motion` (becomes a static neutral background).
//
// Variants:
//   text   — N stacked bars, h-3 each, 70-100% width randomized.
//   card   — full-block placeholder for an entire card.
//   circle — round avatar/icon placeholder.
//   rect   — generic rectangle (caller controls dimensions).
// ============================================================

import { useI18n } from '@/i18n';

export type SkeletonVariant = 'text' | 'card' | 'circle' | 'rect';
export type SkeletonCircleSize = 'sm' | 'md' | 'lg';

interface SkeletonProps {
    variant?: SkeletonVariant;
    lines?: number;
    size?: SkeletonCircleSize;
    className?: string;
    'aria-label'?: string;
}

const CIRCLE_SIZE: Record<SkeletonCircleSize, string> = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6',
    lg: 'h-10 w-10',
};

const LINE_WIDTHS = ['w-full', 'w-11/12', 'w-9/12', 'w-10/12'] as const;

export function Skeleton({
    variant = 'text',
    lines = 1,
    size = 'md',
    className,
    'aria-label': ariaLabel,
}: SkeletonProps): JSX.Element {
    const { t } = useI18n();
    const baseCls = 'fs-skeleton rounded-md bg-[rgb(150_156_156_/_0.15)]';
    const resolvedAriaLabel = ariaLabel ?? t('state.loading.title');

    if (variant === 'text') {
        return (
            <div
                className={['flex flex-col gap-2', className].filter(Boolean).join(' ')}
                aria-busy="true"
                aria-label={resolvedAriaLabel}
            >
                {Array.from({ length: lines }).map((_, idx) => (
                    <div
                        key={idx}
                        className={[
                            baseCls,
                            'h-3',
                            LINE_WIDTHS[idx % LINE_WIDTHS.length] ?? 'w-full',
                        ].join(' ')}
                    />
                ))}
            </div>
        );
    }

    if (variant === 'circle') {
        const cls = [baseCls, 'rounded-full', CIRCLE_SIZE[size], className]
            .filter(Boolean)
            .join(' ');
        return <div className={cls} aria-busy="true" aria-label={resolvedAriaLabel} />;
    }

    if (variant === 'card') {
        const cls = [baseCls, 'h-32 w-full rounded-2xl', className].filter(Boolean).join(' ');
        return <div className={cls} aria-busy="true" aria-label={resolvedAriaLabel} />;
    }

    const cls = [baseCls, 'h-6 w-full', className].filter(Boolean).join(' ');
    return <div className={cls} aria-busy="true" aria-label={resolvedAriaLabel} />;
}
