import { Search, SlidersHorizontal } from 'lucide-react';
import { useMemo } from 'react';

import { Body } from '@/components/typography/Body';
import { useI18n } from '@/i18n';

import { ALL_CROPS_FILTER } from '../market.utils';

interface CropFilterBarProps {
    activeCropId: string;
    cropIds: ReadonlyArray<string>;
    searchValue: string;
    onCropChange: (cropId: string) => void;
    onSearchChange: (value: string) => void;
}

export function CropFilterBar({
    activeCropId,
    cropIds,
    searchValue,
    onCropChange,
    onSearchChange,
}: CropFilterBarProps): JSX.Element {
    const { t } = useI18n();
    const filters = useMemo(() => [ALL_CROPS_FILTER, ...cropIds], [cropIds]);

    return (
        <div className="flex flex-wrap items-center gap-3">
            <label className="flex items-center gap-2 rounded-full border border-fs-border bg-fs-surface px-3 py-2 text-[0.8125rem]">
                <Search size={14} strokeWidth={1.5} className="text-fs-fg-muted" />
                <input
                    type="text"
                    value={searchValue}
                    onChange={(event) => onSearchChange(event.target.value)}
                    placeholder={t('market.filters.search_placeholder')}
                    aria-label={t('market.filters.search_label')}
                    className="w-[160px] bg-transparent text-fs-fg outline-none placeholder:text-fs-fg-muted md:w-[220px]"
                />
            </label>

            <div
                className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-fs-border bg-fs-surface text-fs-fg-muted"
                aria-hidden="true"
            >
                <SlidersHorizontal size={15} strokeWidth={1.5} />
            </div>

            <div className="mx-1 hidden h-6 w-px bg-fs-border md:block" />

            <div className="flex flex-wrap items-center gap-1.5" role="tablist" aria-label={t('market.filters.crops_label')}>
                {filters.map((cropId) => {
                    const isActive = cropId === activeCropId;
                    const label =
                        cropId === ALL_CROPS_FILTER ? t('market.filters.all') : t(`crops.${cropId}.name`);

                    return (
                        <button
                            key={cropId}
                            type="button"
                            role="tab"
                            aria-selected={isActive}
                            onClick={() => onCropChange(cropId)}
                            className={[
                                'rounded-full px-3 py-1.5 transition-colors duration-[var(--duration-fs-fast)]',
                                isActive
                                    ? 'bg-fs-nav text-fs-fg-inverse'
                                    : 'border border-fs-border bg-fs-surface text-fs-fg hover:bg-[rgb(150_156_156_/_0.08)]',
                            ].join(' ')}
                        >
                            <Body size="small" as="span" className="font-medium text-current">
                                {label}
                            </Body>
                        </button>
                    );
                })}
            </div>
        </div>
    );
}
