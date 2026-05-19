Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Finance = Sonar.Farm.Finance or {}

local MovementService = {}

local STATUS_PENDING = 'pending'
local STATUS_COMPLETED = 'completed'
local STATUS_FAILED = 'failed'
local ERROR_DB = 'DB_ERROR'
local ERROR_REPLAY = 'IDEMPOTENCY_REPLAY'
local ERROR_CONFLICT = 'IDEMPOTENCY_CONFLICT'

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 3)
    end

    return Sonar.Farm.DB
end

local function escape_json_string(value)
    local replacements = {
        ['\\'] = '\\\\',
        ['"'] = '\\"',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t',
    }

    return value:gsub('[\\"\b\f\n\r\t]', replacements)
end

local function is_array(value)
    local max_index = 0
    local count = 0

    for key in pairs(value) do
        if type(key) ~= 'number' or key < 1 or key ~= math.floor(key) then
            return false
        end

        if key > max_index then
            max_index = key
        end

        count = count + 1
    end

    return max_index == count
end

local function encode_json(value)
    local value_type = type(value)

    if value == nil then
        return 'null'
    end

    if value_type == 'string' then
        return '"' .. escape_json_string(value) .. '"'
    end

    if value_type == 'number' then
        return tostring(value)
    end

    if value_type == 'boolean' then
        return value and 'true' or 'false'
    end

    if value_type ~= 'table' then
        return '"' .. escape_json_string(tostring(value)) .. '"'
    end

    local parts = {}

    if is_array(value) then
        for index = 1, #value do
            parts[#parts + 1] = encode_json(value[index])
        end

        return '[' .. table.concat(parts, ',') .. ']'
    end

    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = tostring(key)
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
        parts[#parts + 1] = encode_json(key) .. ':' .. encode_json(value[key])
    end

    return '{' .. table.concat(parts, ',') .. '}'
end

local function hash_string(value)
    local hash = 5381

    for index = 1, #value do
        hash = ((hash * 33) + value:byte(index)) % 4294967296
    end

    return ('%08x'):format(hash)
end

local function build_movement_id(idempotency_key, fingerprint)
    return ('sfm_%s_%s'):format(hash_string(idempotency_key), hash_string(fingerprint))
end

local function run_db(operation)
    local ok, result = pcall(operation)

    if not ok then
        return false, {
            error_code = ERROR_DB,
            error_message = tostring(result),
        }
    end

    return true, result
end

local function get_existing(idempotency_key)
    return get_db().row([[
        SELECT
            `idempotency_key`,
            `request_fingerprint`,
            `movement_id`,
            `status`
        FROM `sonar_farm_finance_movements`
        WHERE `idempotency_key` = ?
        LIMIT 1
    ]], { idempotency_key })
end

function MovementService.EncodeMetadata(metadata)
    if metadata == nil then
        return nil
    end

    if type(metadata) == 'string' then
        return metadata
    end

    return encode_json(metadata)
end

function MovementService.BuildFingerprint(input)
    local metadata_json = MovementService.EncodeMetadata(input.metadata) or ''

    local raw_fingerprint = table.concat({
        tostring(input.operation),
        tostring(input.src),
        tostring(input.citizen_id),
        tostring(input.direction),
        tostring(input.account),
        tostring(input.amount),
        tostring(input.reason),
        tostring(input.adapter_name),
        metadata_json,
    }, '|')

    return raw_fingerprint
end

function MovementService.StartMutation(input)
    local fingerprint = MovementService.BuildFingerprint(input)
    local metadata_json = MovementService.EncodeMetadata(input.metadata)
    local movement_id = build_movement_id(input.idempotency_key, fingerprint)

    local ok, result = run_db(function()
        local existing = get_existing(input.idempotency_key)

        if existing then
            if existing.request_fingerprint ~= fingerprint then
                return {
                    ok = false,
                    replay = false,
                    error_code = ERROR_CONFLICT,
                    movement_id = existing.movement_id,
                    status = existing.status,
                }
            end

            return {
                ok = existing.status == STATUS_COMPLETED,
                replay = true,
                error_code = ERROR_REPLAY,
                movement_id = existing.movement_id,
                status = existing.status,
            }
        end

        get_db().execute([[
            INSERT INTO `sonar_farm_finance_movements` (
                `movement_id`,
                `idempotency_key`,
                `request_fingerprint`,
                `citizen_id`,
                `src`,
                `direction`,
                `account`,
                `amount`,
                `reason`,
                `adapter_name`,
                `status`,
                `metadata_json`
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            movement_id,
            input.idempotency_key,
            fingerprint,
            input.citizen_id,
            input.src,
            input.direction,
            input.account,
            input.amount,
            input.reason,
            input.adapter_name,
            STATUS_PENDING,
            metadata_json,
        })

        return {
            ok = true,
            replay = false,
            movement_id = movement_id,
            status = STATUS_PENDING,
        }
    end)

    if not ok then
        return result
    end

    return result
end

function MovementService.CompleteMutation(movement_id)
    local ok, result = run_db(function()
        get_db().execute([[
            UPDATE `sonar_farm_finance_movements`
            SET `status` = ?, `error_code` = NULL
            WHERE `movement_id` = ?
        ]], { STATUS_COMPLETED, movement_id })

        return {
            ok = true,
            movement_id = movement_id,
            status = STATUS_COMPLETED,
        }
    end)

    if not ok then
        return result
    end

    return result
end

function MovementService.FailMutation(movement_id, error_code)
    local ok, result = run_db(function()
        get_db().execute([[
            UPDATE `sonar_farm_finance_movements`
            SET `status` = ?, `error_code` = ?
            WHERE `movement_id` = ?
        ]], { STATUS_FAILED, error_code, movement_id })

        return {
            ok = false,
            movement_id = movement_id,
            status = STATUS_FAILED,
            error_code = error_code,
        }
    end)

    if not ok then
        return result
    end

    return result
end

Sonar.Farm.Finance.MovementService = MovementService
