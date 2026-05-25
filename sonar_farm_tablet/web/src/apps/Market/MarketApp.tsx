import { BarChart3, ShoppingBasket, Store } from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';

import { BentoGrid } from '@/components/layout/BentoGrid';
import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { Mono } from '@/components/typography/Mono';
import { ErrorState, Icon } from '@/components/ui';
import { useI18n } from '@/i18n';
import { fetchNui } from '@/lib/nui';

import {
    BuyerCard,
    CropFilterBar,
    EmptyState,
    FeaturedBuyerCard,
    MarketHeader,
    PulseBar,
    SkeletonState,
} from './components';
import { ALL_CROPS_FILTER, buildMarketCatalogViewModel, filterBuyersByCrop } from './market.utils';
import type { MarketCatalogViewModel, ServerMarketCatalogSnapshot } from './types';

const EMPTY_SNAPSHOT: ServerMarketCatalogSnapshot = {
    day: 0,
    season_key: 'spring',
    server_now_ts: 0,
    buyers: [],
};

export function MarketApp(): JSX.Element {
    const { locale, t } = useI18n();
    const [catalog, setCatalog] = useState<MarketCatalogViewModel | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);
    const [activeCropId, setActiveCropId] = useState(ALL_CROPS_FILTER);
    const [searchValue, setSearchValue] = useState('');

    const loadCatalog = useCallback(async () => {
        setLoading(true);
        setError(false);

        try {
            const snapshot = await fetchNui<ServerMarketCatalogSnapshot, Record<string, never>>(
                'sonar:farm:market:get_catalog',
                {},
                EMPTY_SNAPSHOT
            );

            if (!Array.isArray(snapshot.buyers)) {
                throw new Error('invalid_market_snapshot');
            }

            setCatalog(buildMarketCatalogViewModel(snapshot, locale));
        } catch {
            setError(true);
            setCatalog(buildMarketCatalogViewModel(EMPTY_SNAPSHOT, locale));
        } finally {
            setLoading(false);
        }
    }, [locale]);

    useEffect(() => {
        void loadCatalog();
    }, [loadCatalog]);

    const handleSetWaypoint = useCallback(async (buyerId: string) => {
        await fetchNui<{ ok: boolean; error?: string }, { type: string; buyer_id: string }>(
            'sonar:farm:market:set_waypoint',
            {
                type: 'sonar:farm:market:set_waypoint',
                buyer_id: buyerId,
            },
            { ok: true }
        );
    }, []);

    const filteredBuyers = useMemo(() => {
        const source = catalog?.buyers ?? [];
        const byCrop = filterBuyersByCrop(source, activeCropId);
        const normalizedSearch = searchValue.trim().toLowerCase();

        if (normalizedSearch === '') {
            return byCrop;
        }

        return byCrop.filter((buyer) => {
            const name = t(buyer.nameKey).toLowerCase();
            const kind = t(buyer.kindKey).toLowerCase();
            const district = t(buyer.districtKey).toLowerCase();
            const crops = buyer.crops.map((crop) => t(crop.cropLabelKey).toLowerCase());

            return [name, kind, district, buyer.id.toLowerCase(), ...crops].some((value) => value.includes(normalizedSearch));
        });
    }, [activeCropId, catalog?.buyers, searchValue, t]);

    const featuredBuyer = useMemo(() => {
        if (!catalog?.featuredBuyer) {
            return null;
        }

        if (activeCropId !== ALL_CROPS_FILTER) {
            const matchesFilter = catalog.featuredBuyer.crops.some((crop) => crop.cropId === activeCropId);
            if (!matchesFilter) {
                return null;
            }
        }

        const normalizedSearch = searchValue.trim().toLowerCase();
        if (normalizedSearch === '') {
            return catalog.featuredBuyer;
        }

        const featuredName = t(catalog.featuredBuyer.nameKey).toLowerCase();
        const featuredKind = t(catalog.featuredBuyer.kindKey).toLowerCase();
        const featuredDistrict = t(catalog.featuredBuyer.districtKey).toLowerCase();
        const featuredCrops = catalog.featuredBuyer.crops.map((crop) => t(crop.cropLabelKey).toLowerCase());

        const matchesSearch = [
            featuredName,
            featuredKind,
            featuredDistrict,
            catalog.featuredBuyer.id.toLowerCase(),
            ...featuredCrops,
        ].some((value) => value.includes(normalizedSearch));

        return matchesSearch ? catalog.featuredBuyer : null;
    }, [activeCropId, catalog?.featuredBuyer, searchValue, t]);

    const secondaryBuyers = useMemo(() => {
        return filteredBuyers.filter((buyer) => buyer.id !== featuredBuyer?.id);
    }, [featuredBuyer?.id, filteredBuyers]);

    const hasNoVisibleBuyers = featuredBuyer === null && secondaryBuyers.length === 0;

    if (loading || catalog === null) {
        return <SkeletonState />;
    }

    if (error) {
        return (
            <section className="fs-fade-in flex flex-col gap-6">
                <header className="flex flex-col gap-1">
                    <Heading level="h1" as="h1">
                        {t('page.market.title')}
                    </Heading>
                    <Body size="small" muted>
                        {t('page.market.subtitle')}
                    </Body>
                </header>
                <ErrorState
                    title={t('state.error.title')}
                    body={t('state.error.body')}
                    retry={loadCatalog}
                    retryLabel={t('state.error.retry')}
                />
            </section>
        );
    }

    if (catalog.buyers.length === 0) {
        return (
            <section className="fs-fade-in flex flex-col gap-8">
                <MarketHeader signals={catalog.signals} loading={loading} onRefresh={loadCatalog} />
                <EmptyState
                    nextOpenLabel={t('market.empty.next_open_fallback')}
                    lastCloseLabel={t('market.empty.last_close_fallback')}
                />
            </section>
        );
    }

    const bestGridPrice = secondaryBuyers.reduce((maxPrice, buyer) => {
        return Math.max(maxPrice, buyer.topPriceEurPerKg);
    }, 0);

    return (
        <section className="fs-fade-in flex flex-col gap-8 pb-4">
            <PulseBar buyers={catalog.buyers} day={catalog.day} snapshotLabel={catalog.snapshotLabel} />

            <MarketHeader signals={catalog.signals} loading={loading} onRefresh={loadCatalog} />

            <div className="flex flex-wrap items-center justify-between gap-4">
                <CropFilterBar
                    activeCropId={activeCropId}
                    cropIds={catalog.cropIds}
                    searchValue={searchValue}
                    onCropChange={setActiveCropId}
                    onSearchChange={setSearchValue}
                />
            </div>

            {featuredBuyer ? <FeaturedBuyerCard buyer={featuredBuyer} onSetWaypoint={handleSetWaypoint} /> : null}

            {secondaryBuyers.length > 0 ? (
                <section className="flex flex-col gap-5" data-testid="buyers-grid">
                    <div className="flex flex-wrap items-baseline justify-between gap-3">
                        <Body size="micro" as="div" className="text-fs-fg-muted">
                            {t('market.grid.all_buyers', { count: secondaryBuyers.length })}
                        </Body>
                        <Body size="small" muted>
                            {t('market.grid.sorted_by')}
                        </Body>
                    </div>

                    <BentoGrid columns={12} gap="md">
                        {secondaryBuyers.map((buyer, index) => (
                            <BentoGrid.Item key={buyer.id} span={4}>
                                <BuyerCard
                                    buyer={buyer}
                                    rank={index + 1}
                                    bestOfGrid={buyer.topPriceEurPerKg === bestGridPrice}
                                    onSetWaypoint={handleSetWaypoint}
                                />
                            </BentoGrid.Item>
                        ))}
                    </BentoGrid>
                </section>
            ) : null}

            {hasNoVisibleBuyers ? (
                <div className="rounded-[20px] border border-fs-border bg-fs-surface px-8 py-16 text-center" data-testid="market-no-results">
                    <div className="mb-6 flex justify-center text-fs-fg-muted">
                        <Icon as={searchValue.trim() === '' ? ShoppingBasket : Store} size="xl" />
                    </div>
                    <Heading level="h2" as="h2" className="tracking-[-0.02em]">
                        {activeCropId === ALL_CROPS_FILTER
                            ? t('market.no_results.search_title')
                            : t('market.no_results.crop_title', {
                                  crop: t(`crops.${activeCropId}.name`),
                              })}
                    </Heading>
                    <Body size="small" muted className="mx-auto mt-2 max-w-xl">
                        {searchValue.trim() === ''
                            ? t('market.no_results.crop_body')
                            : t('market.no_results.search_body', { query: searchValue })}
                    </Body>
                </div>
            ) : null}

            <footer className="flex flex-wrap items-center justify-between gap-3 border-t border-fs-border pt-5 text-fs-fg-muted">
                <div className="flex items-center gap-3">
                    <Body size="micro" as="span">
                        {t('shell.brand')}
                    </Body>
                    <span className="h-px w-[14px] bg-[rgb(150_156_156_/_0.4)]" />
                    <Body size="small" as="span" muted>
                        {t('market.footer.version')}
                    </Body>
                </div>
                <div className="flex items-center gap-2">
                    <BarChart3 size={14} strokeWidth={1.5} />
                    <Mono size="small" className="text-fs-fg-muted">
                        {t('market.footer.snapshot', { snapshot: catalog.snapshotLabel })}
                    </Mono>
                </div>
            </footer>
        </section>
    );
}