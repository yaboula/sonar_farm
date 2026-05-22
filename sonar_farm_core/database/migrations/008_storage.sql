CREATE TABLE IF NOT EXISTS `sonar_farm_storage_units` (
    `storage_id` VARCHAR(64) NOT NULL,
    `storage_type` VARCHAR(32) NOT NULL,
    `display_name_key` VARCHAR(191) NOT NULL,
    `coords_x` DOUBLE NOT NULL,
    `coords_y` DOUBLE NOT NULL,
    `coords_z` DOUBLE NOT NULL,
    `radius` DOUBLE NOT NULL DEFAULT 2.0,
    `max_slots` SMALLINT UNSIGNED NOT NULL,
    `max_weight_kg` DOUBLE NOT NULL,
    `decay_multiplier` FLOAT NOT NULL DEFAULT 1.0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`storage_id`),
    KEY `idx_sfsu_storage_type` (`storage_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sonar_farm_storage_contents` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `storage_id` VARCHAR(64) NOT NULL,
    `batch_id` VARCHAR(32) NOT NULL,
    `player_cid` VARCHAR(64) NOT NULL,
    `item_name` VARCHAR(64) NOT NULL,
    `deposited_ts` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sfsc_batch_id` (`batch_id`),
    KEY `idx_sfsc_storage` (`storage_id`),
    CONSTRAINT `fk_sfsc_storage`
        FOREIGN KEY (`storage_id`)
        REFERENCES `sonar_farm_storage_units` (`storage_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT `fk_sfsc_batch`
        FOREIGN KEY (`batch_id`)
        REFERENCES `sonar_farm_batches` (`batch_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '008';

DROP TABLE IF EXISTS `sonar_farm_storage_contents`;
DROP TABLE IF EXISTS `sonar_farm_storage_units`;
*/
