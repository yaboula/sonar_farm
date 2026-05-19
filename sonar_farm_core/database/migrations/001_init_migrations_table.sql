CREATE TABLE IF NOT EXISTS `sonar_farm_migrations` (
    `id` VARCHAR(16) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `filename` VARCHAR(255) NOT NULL,
    `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
