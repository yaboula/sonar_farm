-- ============================================================
-- Farm Sonar — B1 harvested batches table.
-- ============================================================

CREATE TABLE IF NOT EXISTS `sonar_farm_batches` (
    `batch_id` VARCHAR(32) NOT NULL,
    `plot_id` VARCHAR(64) NOT NULL,
    `crop_id` INT UNSIGNED NOT NULL,
    `player_cid` VARCHAR(64) NOT NULL,
    `crop_type` VARCHAR(32) NOT NULL,
    `quality` CHAR(1) NOT NULL,
    `quality_score` TINYINT UNSIGNED NOT NULL,
    `weight_g` INT UNSIGNED NOT NULL,
    `freshness` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `lineage_chain` JSON NOT NULL DEFAULT '[]',
    `harvested_ts` BIGINT UNSIGNED NOT NULL,
    `sold_ts` BIGINT UNSIGNED NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`batch_id`),
    KEY `idx_sfbatches_plot` (`plot_id`),
    KEY `idx_sfbatches_crop_type` (`crop_type`),
    KEY `idx_sfbatches_player_cid` (`player_cid`),
    KEY `idx_sfbatches_harvested_ts` (`harvested_ts`),
    CONSTRAINT `fk_sfbatches_plot`
        FOREIGN KEY (`plot_id`)
        REFERENCES `sonar_farm_plots` (`plot_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '006';

DROP TABLE IF EXISTS `sonar_farm_batches`;
*/
