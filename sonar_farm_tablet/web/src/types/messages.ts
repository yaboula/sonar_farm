// ============================================================
// Farm Sonar — Domain message contracts (typed).
// ============================================================
//
// Source of truth for cross-resource payloads consumed by the NUI
// (tablet) layer beyond the basic shell open/close handshake (see
// `./nui.ts`). Bundle B1 (S6/S7/S8) introduces the `BatchMetadata`
// shape used by the inventory render hook, future sale screen
// (S10), market app (S19) and plots app (S27).
//
// Spec sources (read together):
//   - docs/slices/B1_wheat_lifecycle_item_quality.md §8.1 (canonical
//     mini-brief schema), §8.7 (wire format implemented by
//     Integration in `sonar_farm_core/client/inventory_render.lua`).
//   - docs/00_BIBLE.md §10 (quality grades + 0-100 score range).
//
// Coordination note: the current Lua payload emitted by
// `sonar:farm:nui:batch_tooltip` carries `quality` as a single
// grade letter. The richer `BatchQuality` object below (grade +
// numeric score) is the Frontend-side canonical contract; once
// Integration extends the payload to forward the calculator score
// (DB column `sonar_farm_batches.quality_score`), helpers in
// `lib/nui.ts` should adapt incoming messages to this shape.
// ============================================================

/** Quality grade letter, per Bible §10 (S highest, D lowest). */
export type QualityGrade = 'S' | 'A' | 'B' | 'C' | 'D';

/**
 * Full quality assessment for a batch. `score` is the raw weighted
 * average produced by `Sonar.Farm.Quality.Calculate` (0-100); `grade`
 * is the thresholded letter (S ≥ 95, A ≥ 80, B ≥ 60, C ≥ 40, D < 40).
 */
export interface BatchQuality {
    grade: QualityGrade;
    /** Weighted average across the 7 quality factors. Range 0-100. */
    score: number;
}

/** Provenance metadata captured at harvest time. */
export interface BatchOrigin {
    plot_id: string;
    player_cid: string;
    /** UNIX seconds (server clock at harvest). */
    harvested_ts: number;
    /** Reserved for the company system (S23); `undefined` until then. */
    company_id?: string;
}

/**
 * Canonical physical-item metadata for a harvested batch.
 *
 * Mirrors the Lua schema documented in B1 §1 (S7). Append-only
 * fields like `lineage_chain` must never be mutated in place
 * (anti-pattern §8 — append a new entry instead).
 */
export interface BatchMetadata {
    /** Format: `sf-` + 8 lowercase hex chars (see B1 §8.5). */
    batch_id: string;
    /** e.g. `"wheat"`, `"corn"`. Lowercase crop key from config. */
    crop_type: string;
    /** Exact grams produced at harvest. */
    weight_g: number;
    quality: BatchQuality;
    /** 0-100 at creation; decays per `freshness_decay_rate_per_h`. */
    freshness: number;
    origin: BatchOrigin;
    /** Batch IDs of ancestors; `[]` on first harvest. Append-only. */
    lineage_chain: string[];
    /** UNIX seconds. Equal to `origin.harvested_ts` on first harvest. */
    created_at: number;
}

// ------------------------------------------------------------
// Type guards — defensive parsing of NUI payloads coming from
// `inventory_render.lua`. We never trust unknown data shape.
// ------------------------------------------------------------

const QUALITY_GRADES: readonly QualityGrade[] = ['S', 'A', 'B', 'C', 'D'];

export function isQualityGrade(value: unknown): value is QualityGrade {
    return typeof value === 'string' && (QUALITY_GRADES as readonly string[]).includes(value);
}

function isFiniteNumber(value: unknown): value is number {
    return typeof value === 'number' && Number.isFinite(value);
}

function isStringArray(value: unknown): value is string[] {
    return Array.isArray(value) && value.every((entry) => typeof entry === 'string');
}

export function isBatchQuality(value: unknown): value is BatchQuality {
    if (!value || typeof value !== 'object') return false;
    const candidate = value as { grade?: unknown; score?: unknown };
    return (
        isQualityGrade(candidate.grade) &&
        isFiniteNumber(candidate.score) &&
        candidate.score >= 0 &&
        candidate.score <= 100
    );
}

export function isBatchOrigin(value: unknown): value is BatchOrigin {
    if (!value || typeof value !== 'object') return false;
    const candidate = value as {
        plot_id?: unknown;
        player_cid?: unknown;
        harvested_ts?: unknown;
        company_id?: unknown;
    };
    if (typeof candidate.plot_id !== 'string') return false;
    if (typeof candidate.player_cid !== 'string') return false;
    if (!isFiniteNumber(candidate.harvested_ts)) return false;
    if (candidate.company_id !== undefined && typeof candidate.company_id !== 'string') {
        return false;
    }
    return true;
}

export function isBatchMetadata(value: unknown): value is BatchMetadata {
    if (!value || typeof value !== 'object') return false;
    const candidate = value as {
        batch_id?: unknown;
        crop_type?: unknown;
        weight_g?: unknown;
        quality?: unknown;
        freshness?: unknown;
        origin?: unknown;
        lineage_chain?: unknown;
        created_at?: unknown;
    };
    if (typeof candidate.batch_id !== 'string') return false;
    if (typeof candidate.crop_type !== 'string') return false;
    if (!isFiniteNumber(candidate.weight_g) || candidate.weight_g < 0) return false;
    if (!isBatchQuality(candidate.quality)) return false;
    if (
        !isFiniteNumber(candidate.freshness) ||
        candidate.freshness < 0 ||
        candidate.freshness > 100
    ) {
        return false;
    }
    if (!isBatchOrigin(candidate.origin)) return false;
    if (!isStringArray(candidate.lineage_chain)) return false;
    if (!isFiniteNumber(candidate.created_at)) return false;
    return true;
}
