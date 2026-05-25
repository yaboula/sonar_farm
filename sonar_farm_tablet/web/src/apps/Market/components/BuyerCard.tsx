import { ArrowUpRight, MapPin, ScrollText } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { Mono } from '@/components/typography/Mono';
import { Button } from '@/components/ui';
import { useI18n } from '@/i18n';

import { QualityChip } from './QualityChip';
import type { MarketBuyerViewModel } from '../types';

interface BuyerCardProps {
    buyer: MarketBuyerViewModel;
    rank: number;
    bestOfGrid: boolean;
    onSetWaypoint: (buyerId: string) => void;
}

const KIND_ABBREVIATION_KEY: Record<string, string> = {
    'npcs.kinds.mill': 'market.kind_abbr.mill',
    'npcs.kinds.supermarket': 'market.kind_abbr.supermarket',
    'npcs.kinds.restaurant': 'market.kind_abbr.restaurant',
    'npcs.kinds.distributor': 'market.kind_abbr.distributor',
    'npcs.kinds.canner': 'market.kind_abbr.canner',
    'npcs.kinds.greengrocer': 'market.kind_abbr.greengrocer',
    'npcs.kinds.feed_wholesaler': 'market.kind_abbr.feed_wholesaler',
    'npcs.kinds.hospitality': 'market.kind_abbr.hospitality',
    'npcs.kinds.buyer': 'market.kind_abbr.buyer',
};

export function BuyerCard({ buyer, rank, bestOfGrid, onSetWaypoint }: BuyerCardProps): JSX.Element {
    const { t } = useI18n();
    const topCrop = buyer.crops[0] ?? null;
    const kindAbbreviationKey = KIND_ABBREVIATION_KEY[buyer.kindKey] ?? 'market.kind_abbr.buyer';

    return (
        <article className="fs-slide-up group flex h-full flex-col overflow-hidden rounded-[18px] border border-fs-border bg-fs-surface transition-[transform,border-color] duration-[var(--duration-fs-fast)] hover:-translate-y-[1px] hover:border-[rgb(5_5_5_/_0.22)]">
            <div className="flex items-center justify-between gap-3 px-5 pb-3 pt-4">
                <div className="flex min-w-0 items-center gap-2">
                    <span className="inline-flex items-center rounded-md bg-fs-nav px-2 py-[3px] text-[0.625rem] font-medium tracking-[0.18em] text-fs-fg-inverse">
                        {t(kindAbbreviationKey)}
                    </span>
                    <Body size="small" as="span" muted className="truncate">
                        {t(buyer.kindKey)}
                    </Body>
                    {bestOfGrid ? (
                        <span className="ml-1 inline-flex items-center gap-1 rounded-md bg-fs-accent px-1.5 py-[2px] text-[0.625rem] font-medium uppercase tracking-[0.14em] text-fs-fg">
                            <span className="h-1.5 w-1.5 rounded-full bg-fs-fg" />
                            {t('market.cards.best_price')}
                        </span>
                    ) : null}
                </div>

                <Mono size="small" className="text-fs-fg-muted">
                    {String(rank).padStart(2, '0')}
                </Mono>
            </div>

            <div className="px-5">
                <Heading level="h2" as="h3" className="text-[1.4375rem] leading-[1.08] tracking-[-0.015em]">
                    {t(buyer.nameKey)}
                </Heading>

                <div className="mt-2 flex flex-wrap items-center gap-2 text-fs-fg-muted">
                    <MapPin size={13} strokeWidth={1.5} />
                    <Body size="small" as="span" muted>
                        {t(buyer.districtKey)}
                    </Body>
                    <span className="text-fs-border">·</span>
                    <Mono size="small">{buyer.distanceLabel}</Mono>
                    <span className="text-fs-border">·</span>
                    <Mono size="small">{buyer.id}</Mono>
                </div>
            </div>

            {topCrop ? (
                <div className="mt-5 px-5">
                    <Body size="micro" as="span" className="text-fs-fg-muted">
                        {t('market.cards.top_price', { crop: t(topCrop.cropLabelKey) })}
                    </Body>
                    <div className="mt-1.5 flex flex-wrap items-baseline gap-3">
                        <Mono className="text-[2.375rem] font-medium leading-none tracking-[-0.035em]">
                            {topCrop.priceLabel}
                        </Mono>
                        <Body size="small" as="span" muted>
                            {t('market.units.eur_per_kg')}
                        </Body>
                        <QualityChip grade={topCrop.minQuality} size="xs" />
                    </div>
                    <div className="mt-4 h-px w-full bg-fs-border" />
                </div>
            ) : null}

            <ul className="flex flex-1 flex-col gap-[10px] px-5 pb-0 pt-4">
                {buyer.crops.map((crop, index) => (
                    <li key={`${buyer.id}-${crop.cropId}`} className="flex items-center justify-between gap-3 text-[0.8125rem]">
                        <div className="flex min-w-0 items-center gap-2.5">
                            <span
                                aria-hidden="true"
                                className={[
                                    'h-[5px] w-[5px] shrink-0 rounded-[1px]',
                                    index === 0 ? 'bg-fs-nav' : 'bg-[rgb(150_156_156_/_0.45)]',
                                ].join(' ')}
                            />
                            <QualityChip grade={crop.minQuality} size="xs" />
                            <Body size="small" as="span" className="truncate">
                                {t(crop.cropLabelKey)}
                            </Body>
                        </div>
                        <div className="flex items-center gap-3">
                            <Mono size="small" className="text-fs-fg/85">
                                {crop.priceLabel}
                            </Mono>
                            <Mono size="small" className="min-w-[72px] text-right text-fs-fg-muted">
                                {t('market.cards.capacity_short', { remaining: crop.capacityRemainingLabel })}
                            </Mono>
                        </div>
                    </li>
                ))}
            </ul>

            <div className="mt-5 px-5">
                <div className="flex items-center justify-between gap-3">
                    <Body size="micro" as="span" className="text-fs-fg-muted">
                        {t('market.cards.capacity_today')}
                    </Body>
                    <Mono size="small" className="text-fs-fg-muted">
                        {buyer.capacityRemainingPct}%
                    </Mono>
                </div>
                <div className="mt-2 h-[3px] w-full overflow-hidden rounded-full bg-[rgb(150_156_156_/_0.18)]">
                    <div className="h-full rounded-full bg-fs-nav" style={{ width: `${buyer.capacityRemainingPct}%` }} />
                </div>
            </div>

            <div className="mt-5 flex items-center justify-between gap-3 bg-fs-nav px-5 py-3 text-fs-fg-inverse">
                <div className="flex items-center gap-3 text-[0.71875rem]">
                    <Mono size="small" className="text-fs-fg-inverse">
                        {buyer.updatedLabel}
                    </Mono>
                    <span className="text-white/55">{t('market.cards.ago')}</span>
                    <span className="h-3 w-px bg-white/15" />
                    {buyer.contractsOpen ? (
                        <span className="inline-flex items-center gap-1.5 text-white/90">
                            <ScrollText size={12} strokeWidth={1.5} />
                            {t('market.cards.contracts')}
                        </span>
                    ) : (
                        <span className="text-white/55">{t('market.cards.spot_only')}</span>
                    )}
                </div>

                <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onSetWaypoint(buyer.id)}
                    aria-label={t('market.cards.set_on_map_aria', { buyer: t(buyer.nameKey) })}
                    className="gap-1.5 rounded-full px-0 text-fs-fg-inverse hover:bg-transparent hover:text-fs-fg-inverse"
                    rightIcon={
                        <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-fs-accent text-fs-fg transition-transform duration-[var(--duration-fs-fast)] group-hover:scale-[1.06]">
                            <ArrowUpRight size={12} strokeWidth={2} />
                        </span>
                    }
                >
                    {t('market.cta.set_on_map_short')}
                </Button>
            </div>
        </article>
    );
}
