-- ============================================================
-- Farm Sonar — B1 crop lifecycle table.
-- ============================================================

CREATE TABLE IF NOT EXISTS `sonar_farm_crops` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plot_id` VARCHAR(64) NOT NULL,
    `crop_type` VARCHAR(32) NOT NULL,
    `player_cid` VARCHAR(64) NOT NULL,
    `stage` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `planted_ts` BIGINT UNSIGNED NOT NULL,
    `next_stage_ts` BIGINT UNSIGNED NOT NULL,
    `harvest_deadline_ts` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sfcrop_plot` (`plot_id`),
    KEY `idx_sfcrop_next_stage` (`plot_id`, `next_stage_ts`),
    KEY `idx_sfcrop_stage_next_stage` (`stage`, `next_stage_ts`),
    CONSTRAINT `fk_sfcrop_plot`
        FOREIGN KEY (`plot_id`)
        REFERENCES `sonar_farm_plots` (`plot_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '005';

DROP TABLE IF EXISTS `sonar_farm_crops`;
*/
