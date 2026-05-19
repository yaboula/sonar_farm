-- ============================================================
-- Farm Sonar — S5 plot registry.
-- ============================================================
--
-- Creates `sonar_farm_plots`, the server-authoritative registry
-- of cultivable terrain units for the MLO farm.
--
-- Design notes:
--   * `plot_id` is a stable config-defined natural key (see
--     ADR-010). Future placement GUI will keep the same shape.
--   * `last_updated_ts`, `planted_ts`, `next_stage_ts` are
--     designed-for-delta-calc from day 1 (Bible §13.2). S6 will
--     populate `planted_ts`/`next_stage_ts`; S5 only writes
--     `last_updated_ts` on every persisted mutation.
--   * `soil_score` persists between reboots and is gameplay-owned,
--     never reset by `/sonarfarm:plots:reload` (ADR-010).
--   * Indexes anticipate the S6 scheduler query
--     `WHERE next_stage_ts IS NOT NULL AND next_stage_ts <= ?`,
--     plus filtering by lifecycle `state` and `plot_type`.

CREATE TABLE IF NOT EXISTS `sonar_farm_plots` (
    `plot_id` VARCHAR(64) NOT NULL,
    `plot_type` VARCHAR(32) NOT NULL,
    `display_name_key` VARCHAR(191) NOT NULL,
    `state` VARCHAR(32) NOT NULL DEFAULT 'fallow',
    `soil_score` TINYINT UNSIGNED NOT NULL DEFAULT 50,
    `coords_x` DOUBLE NOT NULL,
    `coords_y` DOUBLE NOT NULL,
    `coords_z` DOUBLE NOT NULL,
    `radius` DOUBLE NOT NULL,
    `last_updated_ts` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `planted_ts` BIGINT UNSIGNED NULL,
    `next_stage_ts` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plot_id`),
    KEY `idx_sonar_farm_plots_state` (`state`),
    KEY `idx_sonar_farm_plots_next_stage_ts` (`next_stage_ts`),
    KEY `idx_sonar_farm_plots_plot_type` (`plot_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
