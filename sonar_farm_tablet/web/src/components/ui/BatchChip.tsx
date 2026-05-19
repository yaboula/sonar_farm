// ============================================================
// Farm Sonar — BatchChip signature component.
// ============================================================
//
// Compact representation of a batch identifier with quality dot
// and optional freshness annotation. Source spec: UI Playbook v2
// §10.3. Identifier renders in JetBrains Mono (§4).
//
// Layout:  [dot] [b_8f3a4e…] [optional quality letter]
//
// Quality color map per Playbook §2.4.
// Freshness < 30 → reveals a danger-toned indicator next to the
// batch id (caller can pair with a Tooltip in future slices).
// ============================================================

import { Mono } from '@/components/typography/Mono';
import { useI18n } from '@/i18n';

export type BatchQuality = 'S' | 'A' | 'B' | 'C' | 'D';

interface BatchChipProps {
    batchId: string;
    quality?: BatchQuality | null;
    freshness?: number | null;
    onClick?: () => void;
    className?: string;
    'aria-label'?: string;
}

const QUALITY_DOT_CLASS: Record<BatchQuality, string> = {
    S: 'bg-fs-accent shadow-[var(--shadow-fs-glow)]',
    A: 'bg-fs-accent',
    B: 'bg-fs-quality-b',
    C: 'bg-fs-quality-c',
    D: 'bg-fs-quality-d',
};

const QUALITY_TEXT_CLASS: Record<BatchQuality, string> = {
    S: 'text-fs-fg',
    A: 'text-fs-fg',
    B: 'text-fs-fg-muted',
    C: 'text-fs-warning-fg',
    D: 'text-fs-danger-fg',
};

function truncateBatchId(batchId: string): string {
    if (batchId.length <= 12) return batchId;
    return `${batchId.slice(0, 8)}…`;
}

export function BatchChip({
    batchId,
    quality = null,
    freshness = null,
    onClick,
    className,
    'aria-label': ariaLabel,
}: BatchChipProps): JSX.Element {
    const { t } = useI18n();
    const cls = [
        'inline-flex items-center gap-2 rounded-2xl border border-fs-border bg-fs-surface px-3 py-1.5',
        'transition-colors duration-[var(--duration-fs-fast)]',
        onClick ? 'cursor-pointer hover:bg-[rgb(150_156_156_/_0.06)]' : '',
        className,
    ]
        .filter(Boolean)
        .join(' ');

    const dotClass = quality ? QUALITY_DOT_CLASS[quality] : 'bg-fs-fg-muted';
    const qualityClass = quality ? QUALITY_TEXT_CLASS[quality] : 'text-fs-fg-muted';
    const isStale = typeof freshness === 'number' && freshness < 30;

    const Tag = onClick ? 'button' : 'span';

    return (
        <Tag
            className={cls}
            type={onClick ? 'button' : undefined}
            onClick={onClick}
            aria-label={ariaLabel ?? t('component.batchChip.ariaLabel', { batchId })}
        >
            <span
                aria-hidden="true"
                className={['inline-block h-2 w-2 rounded-full', dotClass].join(' ')}
            />
            <Mono size="small" className="text-fs-fg">
                {truncateBatchId(batchId)}
            </Mono>
            {quality ? (
                <span className={['text-[0.75rem] font-semibold', qualityClass].join(' ')}>
                    {quality}
                </span>
            ) : null}
            {isStale ? (
                <span
                    aria-hidden="true"
                    className="ml-1 inline-block h-1.5 w-1.5 rounded-full bg-fs-danger-fg"
                    title={t('component.batchChip.lowFreshness')}
                />
            ) : null}
        </Tag>
    );
}
