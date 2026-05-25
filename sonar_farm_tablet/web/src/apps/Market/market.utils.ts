import type {
    MarketCatalogViewModel,
    MarketCropViewModel,
    MarketDelta,
    MarketSignals,
    ServerMarketBuyer,
    ServerMarketCatalogSnapshot,
    ServerMarketCrop,
} from './types';

const GRAMS_PER_KILOGRAM = 1000;
const GRAMS_PER_TONNE = 1_000_000;
const MIN_PROGRESS_PCT = 2;

export const ALL_CROPS_FILTER = 'all';

export function buildMarketCatalogViewModel(
    snapshot: ServerMarketCatalogSnapshot,
    locale: string
): MarketCatalogViewModel {
    const buyers = snapshot.buyers.map((buyer) => toBuyerViewModel(buyer, snapshot.server_now_ts, locale));
    const featuredBuyer = buyers.find((buyer) => buyer.featured) ?? buyers[0] ?? null;
    const signals = computeSignals(buyers);
    const cropIds = Array.from(
        new Set(
            buyers.flatMap((buyer) => {
                return buyer.crops.map((crop) => crop.cropId);
            })
        )
    );

    return {
        day: snapshot.day,
        seasonKey: snapshot.season_key,
        snapshotLabel: formatSnapshotLabel(snapshot.server_now_ts, locale),
        buyers,
        featuredBuyer,
        signals,
        cropIds,
    };
}

function toBuyerViewModel(
    buyer: ServerMarketBuyer,
    serverNowTs: number,
    locale: string
): MarketCatalogViewModel['buyers'][number] {
    const crops = [...buyer.crops]
        .map((crop) => toCropViewModel(crop, locale))
        .sort((left, right) => right.priceEurPerKg - left.priceEurPerKg);

    const topCrop = crops[0] ?? null;
    const capacityRemainingPct = percent(buyer.capacity_remaining_g, buyer.capacity_total_g);

    return {
        id: buyer.id,
        nameKey: buyer.display_name_key,
        kindKey: buyer.kind_key,
        districtKey: buyer.district_key,
        distanceKm: buyer.distance_m / 1000,
        distanceLabel: formatDistanceKm(buyer.distance_m / 1000, locale),
        contractsOpen: buyer.contracts_open,
        featured: buyer.featured,
        updatedMinutes: minutesSince(buyer.updated_ts, serverNowTs),
        updatedLabel: formatUpdatedLabel(buyer.updated_ts, serverNowTs),
        topPriceEurPerKg: buyer.top_price_eur_per_g * GRAMS_PER_KILOGRAM,
        topPriceLabel: formatPriceEurPerKg(buyer.top_price_eur_per_g * GRAMS_PER_KILOGRAM, locale),
        topCropId: topCrop?.cropId ?? null,
        capacityRemainingG: buyer.capacity_remaining_g,
        capacityRemainingLabel: formatWeight(buyer.capacity_remaining_g, locale),
        capacityTotalLabel: formatWeight(buyer.capacity_total_g, locale),
        capacityRemainingPct,
        cropCount: crops.length,
        delta: buyer.delta_since_last_check,
        crops,
    };
}

function toCropViewModel(crop: ServerMarketCrop, locale: string): MarketCropViewModel {
    const capacityRemainingG = Math.max(0, crop.capacity_total_g - crop.capacity_taken_g);
    return {
        cropId: crop.crop,
        cropLabelKey: `crops.${crop.crop}.name`,
        minQuality: crop.min_quality,
        priceEurPerKg: crop.price_eur_per_g * GRAMS_PER_KILOGRAM,
        priceLabel: formatPriceEurPerKg(crop.price_eur_per_g * GRAMS_PER_KILOGRAM, locale),
        capacityTotalG: crop.capacity_total_g,
        capacityTakenG: crop.capacity_taken_g,
        capacityRemainingG,
        capacityRemainingLabel: formatWeight(capacityRemainingG, locale),
        capacityTotalLabel: formatWeight(crop.capacity_total_g, locale),
        capacityRemainingPct: percent(capacityRemainingG, crop.capacity_total_g),
    };
}

function computeSignals(buyers: MarketCatalogViewModel['buyers']): MarketSignals {
    return {
        online: buyers.length,
        premium: buyers.filter((buyer) => buyer.crops.some((crop) => crop.minQuality === 'S')).length,
        contractsOpen: buyers.filter((buyer) => buyer.contractsOpen).length,
        topPriceEurPerKg: buyers.reduce((maxPrice, buyer) => {
            return Math.max(maxPrice, buyer.topPriceEurPerKg);
        }, 0),
    };
}

export function filterBuyersByCrop(
    buyers: ReadonlyArray<MarketCatalogViewModel['buyers'][number]>,
    cropId: string
): MarketCatalogViewModel['buyers'] {
    if (cropId === ALL_CROPS_FILTER) {
        return [...buyers];
    }

    return buyers.filter((buyer) => buyer.crops.some((crop) => crop.cropId === cropId));
}

export function deltaTone(delta: MarketDelta): 'accent' | 'danger' | 'muted' {
    if (delta === 'price_up' || delta === 'volume_up' || delta === 'new_contract') {
        return 'accent';
    }

    if (delta === 'price_down' || delta === 'volume_down') {
        return 'danger';
    }

    return 'muted';
}

export function percent(current: number, total: number): number {
    if (total <= 0) {
        return MIN_PROGRESS_PCT;
    }

    return Math.max(MIN_PROGRESS_PCT, Math.min(100, Math.round((current / total) * 100)));
}

export function formatPriceEurPerKg(value: number, locale: string): string {
    return new Intl.NumberFormat(locale, {
        style: 'currency',
        currency: 'EUR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
    }).format(value);
}

export function formatWeight(grams: number, locale: string): string {
    if (grams >= GRAMS_PER_TONNE) {
        const tonnes = grams / GRAMS_PER_TONNE;
        const maximumFractionDigits = tonnes < 10 ? 1 : 0;
        return `${new Intl.NumberFormat(locale, {
            minimumFractionDigits: 0,
            maximumFractionDigits,
        }).format(tonnes)}t`;
    }

    const kilograms = grams / GRAMS_PER_KILOGRAM;
    return `${new Intl.NumberFormat(locale, {
        minimumFractionDigits: 0,
        maximumFractionDigits: kilograms < 10 ? 1 : 0,
    }).format(kilograms)}kg`;
}

export function formatDistanceKm(distanceKm: number, locale: string): string {
    return `${new Intl.NumberFormat(locale, {
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
    }).format(distanceKm)} km`;
}

export function formatSnapshotLabel(timestamp: number, locale: string): string {
    const date = new Date(timestamp * 1000);
    return new Intl.DateTimeFormat(locale, {
        hour: '2-digit',
        minute: '2-digit',
        day: '2-digit',
        month: 'short',
    }).format(date);
}

function minutesSince(updatedTs: number, serverNowTs: number): number {
    const deltaSeconds = Math.max(0, serverNowTs - updatedTs);
    return Math.max(1, Math.floor(deltaSeconds / 60));
}

function formatUpdatedLabel(updatedTs: number, serverNowTs: number): string {
    return `${minutesSince(updatedTs, serverNowTs)}m`;
}
