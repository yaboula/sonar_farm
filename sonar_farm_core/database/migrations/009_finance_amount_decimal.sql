ALTER TABLE `sonar_farm_finance_movements`
    MODIFY COLUMN `amount` DECIMAL(12,2) UNSIGNED NOT NULL;

/*
Rollback SQL:

DELETE FROM `sonar_farm_migrations`
WHERE `id` = '009';

ALTER TABLE `sonar_farm_finance_movements`
    MODIFY COLUMN `amount` BIGINT UNSIGNED NOT NULL;
*/
