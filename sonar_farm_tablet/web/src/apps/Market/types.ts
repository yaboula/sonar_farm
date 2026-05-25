export type MarketQualityGrade = 'S' | 'A' | 'B' | 'C' | 'D';

export type MarketDelta =
    | 'price_up'
    | 'price_down'
    | 'volume_up'
    | 'volume_down'
    | 'new_contract'
    | 'stable';

export interface ServerMarketCoords {
    x: number;
    y: number;
    z: number;
    w: number;
}

export interface ServerMarketCrop {
    crop: string;
    min_quality: MarketQualityGrade;
    price_eur_per_g: number;
    capacity_total_g: number;
    capacity_taken_g: number;
}

export interface ServerMarketBuyer {
    id: string;
    display_name_key: string;
    kind_key: string;
    district_key: string;
    coords: ServerMarketCoords;
    distance_m: number;
    contracts_open: boolean;
    featured: boolean;
    updated_ts: number;
    top_price_eur_per_g: number;
    capacity_remaining_g: number;
    capacity_total_g: number;
    delta_since_last_check: MarketDelta;
    crops: ServerMarketCrop[];
}

export interface ServerMarketCatalogSnapshot {
    day: number;
    season_key: string;
    server_now_ts: number;
    buyers: ServerMarketBuyer[];
}

export interface MarketCropViewModel {
    cropId: string;
    cropLabelKey: string;
    minQuality: MarketQualityGrade;
    priceEurPerKg: number;
    priceLabel: string;
    capacityTotalG: number;
    capacityTakenG: number;
    capacityRemainingG: number;
    capacityRemainingLabel: string;
    capacityTotalLabel: string;
    capacityRemainingPct: number;
}

export interface MarketBuyerViewModel {
    id: string;
    nameKey: string;
    kindKey: string;
    districtKey: string;
    distanceKm: number;
    distanceLabel: string;
    contractsOpen: boolean;
    featured: boolean;
    updatedMinutes: number;
    updatedLabel: string;
    topPriceEurPerKg: number;
    topPriceLabel: string;
    topCropId: string | null;
    capacityRemainingG: number;
    capacityRemainingLabel: string;
    capacityTotalLabel: string;
    capacityRemainingPct: number;
    cropCount: number;
    delta: MarketDelta;
    crops: MarketCropViewModel[];
}

export interface MarketSignals {
    online: number;
    premium: number;
    contractsOpen: number;
    topPriceEurPerKg: number;
}

export interface MarketCatalogViewModel {
    day: number;
    seasonKey: string;
    snapshotLabel: string;
    buyers: MarketBuyerViewModel[];
    featuredBuyer: MarketBuyerViewModel | null;
    signals: MarketSignals;
    cropIds: string[];
}
