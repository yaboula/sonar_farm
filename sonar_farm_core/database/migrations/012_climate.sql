CREATE TABLE IF NOT EXISTS `sonar_farm_climate_state` (
    `id` TINYINT UNSIGNED NOT NULL,
    `current_season` VARCHAR(16) NOT NULL,
    `current_weather` VARCHAR(32) NOT NULL,
    `season_started_at` BIGINT UNSIGNED NOT NULL,
    `weather_started_at` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '012';

DROP TABLE IF EXISTS `sonar_farm_climate_state`;
*/
