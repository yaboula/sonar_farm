ALTER TABLE `sonar_farm_quality_tracking`
    ADD COLUMN `next_irrigation_due_ts` BIGINT UNSIGNED NULL DEFAULT NULL AFTER `irrigation`,
    ADD COLUMN `pest_detected_ts` BIGINT UNSIGNED NULL DEFAULT NULL AFTER `pest_impact`;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '010';

ALTER TABLE `sonar_farm_quality_tracking`
    DROP COLUMN `next_irrigation_due_ts`,
    DROP COLUMN `pest_detected_ts`;
*/
