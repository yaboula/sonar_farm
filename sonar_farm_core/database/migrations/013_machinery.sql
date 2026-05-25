CREATE TABLE IF NOT EXISTS `sonar_farm_machinery_state` (
    `plate` VARCHAR(16) NOT NULL,
    `model` VARCHAR(64) NULL,
    `durability` INT NOT NULL DEFAULT 100,
    `is_broken` TINYINT(1) NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`),
    CONSTRAINT `chk_sonar_farm_machinery_state_durability`
        CHECK (`durability` >= 0 AND `durability` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
