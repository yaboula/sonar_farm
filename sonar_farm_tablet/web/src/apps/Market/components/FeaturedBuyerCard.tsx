import { ArrowUpRight, Clock3, MapPin, ScrollText } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { Mono } from '@/components/typography/Mono';
import { Button, Card } from '@/components/ui';
import { useI18n } from '@/i18n';

import { QualityChip } from './QualityChip';
import type { MarketBuyerViewModel } from '../types';

interface FeaturedBuyerCardProps {
    buyer: MarketBuyerViewModel;
    onSetWaypoint: (buyerId: string) => void;
}

export function FeaturedBuyerCard({ buyer, onSetWaypoint }: FeaturedBuyerCardProps): JSX.Element {
    const { t } = useI18n();
    const topCrop = buyer.crops[0] ?? null;

    return (
        <article className="fs-slide-up overflow-hidden rounded-[22px] border border-fs-border bg-fs-surface">
            <div className="flex flex-col xl:flex-row">
                <div className="flex flex-1 flex-col gap-5 p-6 md:p-8 xl:pr-6">
                    <div className="flex items-center justify-between gap-3">
                        <div className="flex min-w-0 items-center gap-2.5">
                            <span className="inline-flex items-center rounded-md bg-fs-nav px-2 py-[3px] text-[0.625rem] font-medium tracking-[0.18em] text-fs-fg-inverse">
                                {t('market.featured.badge')}
                            </span>
                            <Body size="small" as="span" muted className="truncate">
                                {t(buyer.kindKey)}
                            </Body>
                        </div>

                        <span className="inline-flex items-center gap-1.5 rounded-full bg-fs-accent px-2.5 py-[5px] text-[0.6875rem] font-medium text-fs-fg">
                            <span className="inline-block h-1.5 w-1.5 rounded-full bg-fs-fg" />
                            {t('market.featured.top_match')}
                        </span>
                    </div>

                    <div className="flex flex-col gap-3">
                        <Heading
                            level="display"
                            as="h2"
                            className="text-[clamp(2.125rem,4vw,3.5rem)] leading-[0.98] tracking-[-0.03em]"
                        >
                            {t(buyer.nameKey)}
                        </Heading>

                        <div className="flex flex-wrap items-center gap-2 text-fs-fg-muted">
                            <MapPin size={14} strokeWidth={1.5} />
                            <Body size="small" as="span" muted>
                                {t(buyer.districtKey)}
                            </Body>
                            <span className="text-fs-border">·</span>
                            <Mono size="small">{buyer.distanceLabel}</Mono>
                            <span className="text-fs-border">·</span>
                            <Mono size="small">{buyer.id}</Mono>
                        </div>

                        <Body size="small" muted className="max-w-xl text-[0.875rem] leading-[1.6]">
                            {t(`market.copy.buyer_notes.${buyer.id}`, {
                                buyer: t(buyer.nameKey),
                                kind: t(buyer.kindKey),
                            })}
                        </Body>
                    </div>

                    {topCrop ? (
                        <div className="mt-2 flex flex-col gap-2">
                            <Body size="micro" as="span" className="text-fs-fg-muted">
                                {t('market.cards.top_price_today', { crop: t(topCrop.cropLabelKey) })}
                            </Body>
                            <div className="flex flex-wrap items-end gap-3">
                                <Mono className="text-[clamp(4rem,8vw,7.25rem)] font-medium leading-none tracking-[-0.045em]">
                                    {topCrop.priceLabel}
                                </Mono>
                                <Body size="default" as="span" muted className="pb-2">
                                    {t('market.units.eur_per_kg')}
                                </Body>
                                <QualityChip grade={topCrop.minQuality} />
                            </div>
                        </div>
                    ) : null}
                </div>

                <div className="border-t border-fs-border bg-[rgb(251_252_252)] p-6 md:p-7 xl:w-[44%] xl:max-w-[480px] xl:border-l xl:border-t-0">
                    <div className="flex items-center justify-between gap-3">
                        <Body size="micro" as="span" className="text-fs-fg-muted">
                            {t('market.cards.accepts_today')}
                        </Body>
                        <Mono size="small" className="text-fs-fg-muted">
                            {t('market.cards.crops_count', { count: buyer.cropCount })}
                        </Mono>
                    </div>

                    <ul className="mt-4 flex flex-col gap-3">
                        {buyer.crops.map((crop, index) => (
                            <li key={`${buyer.id}-${crop.cropId}`}>
                                <Card padding="compact" className="bg-fs-surface">
                                    <div className="flex items-center justify-between gap-3">
                                        <div className="flex min-w-0 items-center gap-2.5">
                                            <QualityChip grade={crop.minQuality} />
                                            <Body size="default" as="span" className="truncate font-medium">
                                                {t(crop.cropLabelKey)}
                                            </Body>
                                        </div>
                                        <Mono size="small">{crop.priceLabel}</Mono>
                                    </div>

                                    <div className="mt-2.5 flex items-center justify-between gap-3 text-fs-fg-muted">
                                        <Body size="small" as="span" muted>
                                            {t('market.cards.capacity_remaining_of_total', {
                                                remaining: crop.capacityRemainingLabel,
                                                total: crop.capacityTotalLabel,
                                            })}
                                        </Body>
                                        <Mono size="small">{crop.capacityRemainingPct}%</Mono>
                                    </div>

                                    <div className="mt-1.5 h-[3px] w-full overflow-hidden rounded-full bg-[rgb(150_156_156_/_0.18)]">
                                        <div
                                            className={index === 0 ? 'h-full rounded-full bg-fs-accent' : 'h-full rounded-full bg-fs-nav'}
                                            style={{ width: `${crop.capacityRemainingPct}%` }}
                                        />
                                    </div>
                                </Card>
                            </li>
                        ))}
                    </ul>

                    <Body size="small" muted className="mt-5 leading-[1.55]">
                        {t('market.cards.aggregated_capacity_remaining', {
                            pct: buyer.capacityRemainingPct,
                        })}
                    </Body>
                </div>
            </div>

            <div className="flex flex-wrap items-center justify-between gap-4 bg-fs-nav px-6 py-4 text-fs-fg-inverse md:px-8">
                <div className="flex flex-wrap items-center gap-4 text-[0.8125rem]">
                    <span className="inline-flex items-center gap-1.5 text-white/90">
                        <Clock3 size={13} strokeWidth={1.5} />
                        <Mono size="small" className="text-fs-fg-inverse">
                            {buyer.updatedLabel}
                        </Mono>
                        <Body size="small" as="span" className="text-white/55">
                            {t('market.cards.ago')}
                        </Body>
                    </span>

                    <span className="h-3.5 w-px bg-white/15" />

                    {buyer.contractsOpen ? (
                        <span className="inline-flex items-center gap-1.5 text-white/90">
                            <ScrollText size={13} strokeWidth={1.5} />
                            <Body size="small" as="span" className="text-current">
                                {t('market.contracts_open')}
                            </Body>
                        </span>
                    ) : (
                        <Body size="small" as="span" className="text-white/55">
                            {t('market.contracts_closed')}
                        </Body>
                    )}
                </div>

                <Button
                    variant="primary"
                    size="md"
                    onClick={() => onSetWaypoint(buyer.id)}
                    rightIcon={
                        <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-fs-nav text-fs-fg-inverse">
                            <ArrowUpRight size={12} strokeWidth={1.8} />
                        </span>
                    }
                    className="rounded-full"
                >
                    {t('market.cta.set_on_map')}
                </Button>
            </div>
        </article>
    );
}
