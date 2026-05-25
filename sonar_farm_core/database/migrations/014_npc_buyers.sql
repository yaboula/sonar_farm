CREATE TABLE IF NOT EXISTS `sonar_farm_npc_buyer_state` (
    `buyer_id` VARCHAR(64) NOT NULL,
    `volume_remaining_today_g` BIGINT UNSIGNED NOT NULL,
    `today_top_price_eur_per_g` DECIMAL(12,6) NOT NULL,
    `previous_volume_remaining_today_g` BIGINT UNSIGNED NOT NULL,
    `previous_top_price_eur_per_g` DECIMAL(12,6) NOT NULL,
    `contracts_enabled` TINYINT(1) NOT NULL DEFAULT 0,
    `previous_contracts_enabled` TINYINT(1) NOT NULL DEFAULT 0,
    `crop_volume_taken_today_json` TEXT NULL,
    `last_reset_ts` BIGINT UNSIGNED NOT NULL,
    `updated_ts` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`buyer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
