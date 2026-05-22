Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Storage = Sonar.Farm.Storage or {}

local function log_info(message)
    print(('[sonar_farm_core] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

function Sonar.Farm.Storage.Boot()
    if not Sonar.Farm.StorageService or type(Sonar.Farm.StorageService.SyncSeededStorage) ~= 'function' then
        log_error(locale('storage.boot.unavailable'))
        return false
    end

    log_info(locale('storage.boot.started'))

    local ok, result_or_error = pcall(Sonar.Farm.StorageService.SyncSeededStorage)
    if not ok then
        log_error(locale('storage.boot.boot_failed'):format(tostring(result_or_error)))
        return false
    end

    local result = result_or_error

    if result.skipped > 0 then
        log_error(locale('storage.boot.skipped_entries'):format(result.skipped))
    end

    log_info(locale('storage.boot.ready'):format(
        result.created,
        result.updated,
        result.unchanged,
        result.skipped,
        result.total
    ))

    return result.skipped == 0
end
