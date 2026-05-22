ALTER TABLE `sonar_farm_quality_tracking`
    ADD COLUMN `pest_severity` ENUM('none', 'detected', 'severe') NOT NULL DEFAULT 'none'
    AFTER `pest_detected_ts`;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '011';

ALTER TABLE `sonar_farm_quality_tracking`
    DROP COLUMN `pest_severity`;
*/
