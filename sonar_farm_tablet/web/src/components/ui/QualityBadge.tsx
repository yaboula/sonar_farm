// ============================================================
// Farm Sonar — QualityBadge component.
// ============================================================
//
// Standalone pill badge that surfaces a batch quality grade
// (S/A/B/C/D) in JetBrains Mono, consumed by the inventory
// render hook (S7) and future apps (S10 sale screen, S19 market,
// S27 plots app).
//
// Color mapping (UI Playbook v2 §2.4 + Bible §1.1):
//   - S / A → lime accent on near-black text (premium signal).
//   - B    → neutral white surface (no opinion).
//   - C    → amber (warning tier, not in theme.css yet — Tailwind default).
//   - D    → red   (danger tier, not in theme.css yet — Tailwind default).
//
// Motion: none. Per AI Playbook §9, motion is TBD; we keep this
// element static and rely on color to communicate.
// ============================================================

import type { QualityGrade } from '@/types/messages';
import { useI18n } from '@/i18n';

export type QualityBadgeSize = 'sm' | 'md' | 'lg';

interface QualityBadgeProps {
    grade: QualityGrade;
    size?: QualityBadgeSize;
    className?: string;
    'aria-label'?: string;
}

const SIZE_CLASS: Record<QualityBadgeSize, string> = {
    sm: 'text-xs px-1.5 py-0.5',
    md: 'text-sm px-2 py-1',
    lg: 'text-base px-3 py-1.5',
};

const GRADE_CLASS: Record<QualityGrade, string> = {
    S: 'bg-fs-accent text-fs-nav',
    A: 'bg-fs-accent/80 text-fs-nav',
    B: 'bg-fs-surface border border-fs-border text-fs-fg',
    C: 'bg-amber-100 text-amber-800',
    D: 'bg-red-100 text-red-700',
};

export function QualityBadge({
    grade,
    size = 'md',
    className,
    'aria-label': ariaLabel,
}: QualityBadgeProps): JSX.Element {
    const { t } = useI18n();
    const cls = [
        'inline-flex items-center justify-center rounded-full font-mono font-semibold',
        'leading-none select-none',
        SIZE_CLASS[size],
        GRADE_CLASS[grade],
        className,
    ]
        .filter(Boolean)
        .join(' ');

    return (
        <span
            className={cls}
            role="img"
            aria-label={ariaLabel ?? t('component.qualityBadge.ariaLabel', { grade })}
        >
            {grade}
        </span>
    );
}
