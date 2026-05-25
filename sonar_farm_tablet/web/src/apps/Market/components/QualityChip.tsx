import type { HTMLAttributes } from 'react';

import { Mono } from '@/components/typography/Mono';
import { useI18n } from '@/i18n';

import type { MarketQualityGrade } from '../types';

type QualityChipSize = 'sm' | 'xs';

interface QualityChipProps extends HTMLAttributes<HTMLSpanElement> {
    grade: MarketQualityGrade;
    size?: QualityChipSize;
}

const TONE_CLASS: Record<MarketQualityGrade, string> = {
    S: 'bg-fs-success-bg text-fs-success-fg',
    A: 'bg-fs-success-bg text-fs-success-fg',
    B: 'bg-fs-warning-bg text-fs-warning-fg',
    C: 'bg-fs-danger-bg text-fs-danger-fg',
    D: 'bg-fs-danger-bg text-fs-danger-fg',
};

const SIZE_CLASS: Record<QualityChipSize, string> = {
    sm: 'px-2 py-[2px] text-[0.6875rem]',
    xs: 'px-1.5 py-[1px] text-[0.625rem]',
};

export function QualityChip({ grade, size = 'sm', className, ...rest }: QualityChipProps): JSX.Element {
    const { t } = useI18n();
    const cls = [
        'inline-flex items-center justify-center rounded-md font-medium tracking-[0.06em]',
        TONE_CLASS[grade],
        SIZE_CLASS[size],
        className,
    ]
        .filter(Boolean)
        .join(' ');

    return (
        <span className={cls} title={t('market.cards.min_quality_tooltip', { grade })} {...rest}>
            <Mono size="small">{grade}</Mono>
        </span>
    );
}
