-- ============================================================
-- Farm Sonar — B1 quality factor tracking.
-- ============================================================

CREATE TABLE IF NOT EXISTS `sonar_farm_quality_tracking` (
    `plot_id` VARCHAR(64) NOT NULL,
    `soil_score` TINYINT UNSIGNED NOT NULL DEFAULT 50,
    `irrigation` TINYINT UNSIGNED NOT NULL DEFAULT 70,
    `pest_impact` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `weather_match` TINYINT UNSIGNED NOT NULL DEFAULT 70,
    `seed_quality` TINYINT UNSIGNED NOT NULL DEFAULT 70,
    `fertilization` TINYINT UNSIGNED NOT NULL DEFAULT 70,
    `harvest_timing` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `calculated_at` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`plot_id`),
    CONSTRAINT `fk_sfquality_plot`
        FOREIGN KEY (`plot_id`)
        REFERENCES `sonar_farm_plots` (`plot_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '006';

DROP TABLE IF EXISTS `sonar_farm_quality_tracking`;
*/
