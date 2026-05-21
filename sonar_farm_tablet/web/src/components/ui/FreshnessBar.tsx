// ============================================================
// Farm Sonar — FreshnessBar component.
// ============================================================
//
// Horizontal progress bar showing batch freshness (0-100). Used
// by the inventory render hook (S7) and future apps (S10 sale
// screen, S19 market, S27 plots app).
//
// Color thresholds (mirrors `inventory_render.lua` Lua side):
//   - > 60  → green  (healthy)
//   - 30-60 → amber  (degrading)
//   - < 30  → red    (stale)
//
// These thresholds are intentionally hardcoded as Tailwind utility
// classes per the B1 deliverable spec — they are not promoted to
// theme.css tokens yet (status palette is reserved for the success/
// warning/danger pairs in §2.3, not this 3-step gradient).
//
// Motion: none. Per AI Playbook §9, motion is TBD; the fill is a
// static width with no transition.
// ============================================================

import { useI18n } from '@/i18n';

interface FreshnessBarProps {
    /** Freshness percentage. Clamped to 0-100 internally. */
    value: number;
    /** When true, renders `{value}%` to the right in mono micro text. */
    showLabel?: boolean;
    className?: string;
    'aria-label'?: string;
}

function clampPercent(value: number): number {
    if (!Number.isFinite(value)) return 0;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return Math.round(value);
}

function getFillClass(percent: number): string {
    if (percent > 60) return 'bg-green-500';
    if (percent >= 30) return 'bg-amber-500';
    return 'bg-red-500';
}

export function FreshnessBar({
    value,
    showLabel = false,
    className,
    'aria-label': ariaLabel,
}: FreshnessBarProps): JSX.Element {
    const { t } = useI18n();
    const percent = clampPercent(value);
    const fillClass = getFillClass(percent);

    const wrapperCls = ['flex items-center gap-2', className].filter(Boolean).join(' ');

    return (
        <div className={wrapperCls}>
            <div
                role="progressbar"
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={percent}
                aria-label={ariaLabel ?? t('component.freshnessBar.ariaLabel', { value: percent })}
                className="relative h-1.5 w-full overflow-hidden rounded-full bg-fs-border/40"
            >
                <div
                    className={['h-full rounded-full', fillClass].join(' ')}
                    style={{ width: `${percent}%` }}
                    aria-hidden="true"
                />
            </div>
            {showLabel ? (
                <span
                    className="font-mono text-xs text-fs-fg-muted tabular-nums"
                    aria-hidden="true"
                >
                    {t('component.freshnessBar.label', { value: percent })}
                </span>
            ) : null}
        </div>
    );
}
