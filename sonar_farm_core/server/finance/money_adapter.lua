Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Finance = Sonar.Farm.Finance or {}
Sonar.Farm.Finance.Adapters = Sonar.Farm.Finance.Adapters or {}

local Finance = Sonar.Farm.Finance

local ACCOUNT_CASH = 'cash'
local ACCOUNT_BANK = 'bank'
local DIRECTION_CREDIT = 'credit'
local DIRECTION_DEBIT = 'debit'
local STATUS_COMPLETED = 'completed'
local ADAPTER_NATIVE = 'native_bridge'

local ERROR_INVALID_SOURCE = 'INVALID_SOURCE'
local ERROR_INVALID_ACCOUNT = 'INVALID_ACCOUNT'
local ERROR_INVALID_AMOUNT = 'INVALID_AMOUNT'
local ERROR_MISSING_REASON = 'MISSING_REASON'
local ERROR_ADAPTER_UNAVAILABLE = 'ADAPTER_UNAVAILABLE'
local ERROR_INSUFFICIENT_FUNDS = 'INSUFFICIENT_FUNDS'
local ERROR_MUTATION_FAILED = 'MUTATION_FAILED'
local ERROR_MISSING_IDEMPOTENCY_KEY = 'MISSING_IDEMPOTENCY_KEY'

local active_adapter_name = nil
local active_adapter = nil
local initialized = false

local function is_valid_source(src)
    return type(src) == 'number' and src > 0 and src == math.floor(src)
end

local function is_valid_account(account)
    return account == ACCOUNT_CASH or account == ACCOUNT_BANK
end

local function get_amount_precision()
    return tonumber(Config and Config.Farm and Config.Farm.Finance and Config.Farm.Finance.AmountPrecision) or 2
end

local function is_valid_amount(amount)
    if type(amount) ~= 'number' or amount <= 0 then
        return false
    end

    local multiplier = 10 ^ get_amount_precision()
    local scaled = amount * multiplier
    return math.abs(scaled - math.floor(scaled + 0.0001)) < 0.0001
end

local function is_present_string(value)
    return type(value) == 'string' and value ~= ''
end

local function configured_adapter_name()
    if Config and Config.Farm and Config.Farm.Finance and is_present_string(Config.Farm.Finance.Adapter) then
        return Config.Farm.Finance.Adapter
    end

    return ADAPTER_NATIVE
end

local function select_adapter()
    local requested = configured_adapter_name()
    local adapter = Finance.Adapters[requested]
    local reason = 'configured'

    if not adapter then
        requested = ADAPTER_NATIVE
        adapter = Finance.Adapters[requested]
        reason = 'fallback'
    end

    active_adapter_name = requested
    active_adapter = adapter
    initialized = true

    TriggerEvent('sonar:farm:banca:adapter_selected', {
        adapter_name = active_adapter_name,
        mode = adapter and adapter.mode or 'unavailable',
        reason = reason,
    })

    return adapter
end

local function ensure_adapter()
    if not initialized then
        return select_adapter()
    end

    return active_adapter
end

local function get_player(src)
    if not is_valid_source(src) then
        return nil, ERROR_INVALID_SOURCE
    end

    if not Sonar.Farm.Bridge or type(Sonar.Farm.Bridge.GetPlayer) ~= 'function' then
        return nil, ERROR_ADAPTER_UNAVAILABLE
    end

    local player = Sonar.Farm.Bridge.GetPlayer(src)
    if not player or not is_present_string(player.citizen_id) then
        return nil, ERROR_INVALID_SOURCE
    end

    return player, nil
end

local function validate_common(src, account, amount, reason, idempotency_key)
    local player, player_error = get_player(src)
    if not player then
        return nil, player_error
    end

    if not is_valid_account(account) then
        return nil, ERROR_INVALID_ACCOUNT
    end

    if amount ~= nil and not is_valid_amount(amount) then
        return nil, ERROR_INVALID_AMOUNT
    end

    if reason ~= nil and not is_present_string(reason) then
        return nil, ERROR_MISSING_REASON
    end

    if idempotency_key ~= nil and not is_present_string(idempotency_key) then
        return nil, ERROR_MISSING_IDEMPOTENCY_KEY
    end

    return player, nil
end

local function emit_movement_created(payload)
    TriggerEvent('sonar:farm:banca:movement_created', payload)
end

local function run_mutation(input, mutate)
    local adapter = ensure_adapter()
    if not adapter then
        return false, {
            error_code = ERROR_ADAPTER_UNAVAILABLE,
        }
    end

    if not Finance.MovementService then
        return false, {
            error_code = ERROR_ADAPTER_UNAVAILABLE,
        }
    end

    local start_result = Finance.MovementService.StartMutation(input)
    if not start_result.ok then
        return false, start_result
    end

    if start_result.replay then
        return start_result.ok, start_result
    end

    local mutation_ok, mutation_error = mutate(adapter)
    if not mutation_ok then
        local failed = Finance.MovementService.FailMutation(start_result.movement_id, mutation_error or ERROR_MUTATION_FAILED)
        return false, failed
    end

    local complete_result = Finance.MovementService.CompleteMutation(start_result.movement_id)
    if not complete_result.ok then
        return false, complete_result
    end

    local result = {
        ok = true,
        replay = false,
        movement_id = start_result.movement_id,
        status = STATUS_COMPLETED,
    }

    emit_movement_created({
        movement_id = result.movement_id,
        citizen_id = input.citizen_id,
        direction = input.direction,
        amount = input.amount,
        account = input.account,
        reason = input.reason,
        adapter_name = input.adapter_name,
        status = result.status,
    })

    return true, result
end

function Finance.Init()
    select_adapter()
end

function Finance.GetActiveAdapter()
    ensure_adapter()

    return {
        adapter_name = active_adapter_name,
        mode = active_adapter and active_adapter.mode or 'unavailable',
    }
end

function Finance.GetBalance(src, account)
    local player, validation_error = validate_common(src, account, nil, nil, nil)
    if not player then
        return nil, validation_error
    end

    local adapter = ensure_adapter()
    if not adapter or type(adapter.GetBalance) ~= 'function' then
        return nil, ERROR_ADAPTER_UNAVAILABLE
    end

    local ok, balance, adapter_error = adapter.GetBalance(src, account)
    if not ok then
        return nil, adapter_error or ERROR_ADAPTER_UNAVAILABLE
    end

    return balance, nil
end

function Finance.CanAfford(src, account, amount)
    local player, validation_error = validate_common(src, account, amount, nil, nil)
    if not player then
        return false, validation_error
    end

    local balance, balance_error = Finance.GetBalance(src, account)
    if balance == nil then
        return false, balance_error
    end

    if balance < amount then
        return false, ERROR_INSUFFICIENT_FUNDS
    end

    return true, nil
end

function Finance.Credit(src, account, amount, reason, idempotency_key, metadata)
    local player, validation_error = validate_common(src, account, amount, reason, idempotency_key)
    if not player then
        return false, {
            error_code = validation_error,
        }
    end

    local adapter_info = Finance.GetActiveAdapter()
    local input = {
        operation = DIRECTION_CREDIT,
        src = src,
        citizen_id = player.citizen_id,
        direction = DIRECTION_CREDIT,
        account = account,
        amount = amount,
        reason = reason,
        idempotency_key = idempotency_key,
        adapter_name = adapter_info.adapter_name,
        metadata = metadata,
    }

    return run_mutation(input, function(adapter)
        if type(adapter.Credit) ~= 'function' then
            return false, ERROR_ADAPTER_UNAVAILABLE
        end

        return adapter.Credit(src, account, amount, reason)
    end)
end

function Finance.Debit(src, account, amount, reason, idempotency_key, metadata)
    local player, validation_error = validate_common(src, account, amount, reason, idempotency_key)
    if not player then
        return false, {
            error_code = validation_error,
        }
    end

    local can_afford, afford_error = Finance.CanAfford(src, account, amount)
    if not can_afford then
        return false, {
            error_code = afford_error,
        }
    end

    local adapter_info = Finance.GetActiveAdapter()
    local input = {
        operation = DIRECTION_DEBIT,
        src = src,
        citizen_id = player.citizen_id,
        direction = DIRECTION_DEBIT,
        account = account,
        amount = amount,
        reason = reason,
        idempotency_key = idempotency_key,
        adapter_name = adapter_info.adapter_name,
        metadata = metadata,
    }

    return run_mutation(input, function(adapter)
        if type(adapter.Debit) ~= 'function' then
            return false, ERROR_ADAPTER_UNAVAILABLE
        end

        return adapter.Debit(src, account, amount, reason)
    end)
end

function Finance.Transfer(_src, _from_account, _to_account, _amount, _reason, _idempotency_key, _metadata)
    return false, {
        error_code = ERROR_ADAPTER_UNAVAILABLE,
    }
end
