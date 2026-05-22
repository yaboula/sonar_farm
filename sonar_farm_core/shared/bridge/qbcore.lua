-- ============================================================
-- Farm Sonar — Bridge adapter for QBCore.
-- ============================================================
--
-- Public contract: see `shared/bridge/INTERFACE.md`.
-- Decisions:       see ADR-005.
--
-- QBCore API references used here:
--   - `QBCore.Functions.GetPlayer(src)`         server-only
--   - `Player.PlayerData.charinfo`              { firstname, lastname, ... }
--   - `Player.PlayerData.citizenid`             string
--   - `Player.PlayerData.job`                   { name, grade = { level } }
--   - `Player.PlayerData.money`                 { cash = n, bank = n }
--   - `Player.Functions.AddMoney(account, amount, reason)`
--   - `Player.Functions.RemoveMoney(account, amount, reason)`
--   - `QBCore.Functions.Notify(src, message, type, length)`
--
-- Notifications use QBCore's native Notify on the server-side
-- TriggerClientEvent path (`QBCore:Notify`) so that QBCore servers
-- without ox_lib still get notifications. Type symbols differ
-- from ox_lib: QBCore uses 'success' | 'error' | 'primary'.
-- We translate from our public symbols.
-- ============================================================

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Bridge = Sonar.Farm.Bridge or {}

local adapter = {}

-- ---- Helpers ------------------------------------------------

local function is_server()
    return IsDuplicityVersion()
end

local function get_qbcore()
    -- QBCore exposes itself via the 'qb-core:GetObject' export.
    -- We cache it on first access to avoid the export round-trip
    -- on every call.
    if not adapter._QBCore then
        adapter._QBCore = exports['qb-core']:GetCoreObject()
    end
    return adapter._QBCore
end

---@param account string
---@return boolean
local function is_valid_account(account)
    return account == 'cash' or account == 'bank'
end

local function get_amount_precision()
    return tonumber(Config and Config.Farm and Config.Farm.Finance and Config.Farm.Finance.AmountPrecision) or 2
end

---@param amount any
---@return boolean
local function is_valid_positive_amount(amount)
    if type(amount) ~= 'number' or amount <= 0 then
        return false
    end

    local multiplier = 10 ^ get_amount_precision()
    local scaled = amount * multiplier
    return math.abs(scaled - math.floor(scaled + 0.0001)) < 0.0001
end

-- ---- GetPlayer ----------------------------------------------

---@param src number
---@return Sonar.Farm.Bridge.Player|nil
function adapter.GetPlayer(src)
    if not is_server() then
        return nil
    end

    if type(src) ~= 'number' or src <= 0 then
        return nil
    end

    local QBCore = get_qbcore()
    if not QBCore then
        return nil
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData then
        return nil
    end

    local data = Player.PlayerData
    local charinfo = data.charinfo or {}
    local job = data.job or {}
    local money = data.money or {}

    local first = charinfo.firstname or ''
    local last  = charinfo.lastname or ''

    return {
        src        = src,
        citizen_id = data.citizenid or '',
        name       = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', ''),
        job_name   = job.name or 'unemployed',
        job_grade  = (job.grade and job.grade.level) or 0,
        cash       = tonumber(money.cash) or 0,
        bank       = tonumber(money.bank) or 0,
        framework  = 'qbcore',
    }
end

-- ---- GetMoney -----------------------------------------------

---@param src number
---@param account "cash"|"bank"
---@return number
function adapter.GetMoney(src, account)
    if not is_server() then
        return 0
    end

    if not is_valid_account(account) then
        return 0
    end

    local QBCore = get_qbcore()
    if not QBCore then
        return 0
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData or not Player.PlayerData.money then
        return 0
    end

    return tonumber(Player.PlayerData.money[account]) or 0
end

-- ---- AddMoney -----------------------------------------------

---@param src number
---@param account "cash"|"bank"
---@param amount number
---@param reason string
---@return boolean ok
---@return string|nil err
function adapter.AddMoney(src, account, amount, reason)
    if not is_server() then
        return false, 'must be called from server'
    end

    if not is_valid_account(account) then
        return false, 'invalid account: ' .. tostring(account)
    end

    if not is_valid_positive_amount(amount) then
        return false, 'invalid amount: ' .. tostring(amount)
    end

    if type(reason) ~= 'string' or reason == '' then
        return false, 'reason is required for audit trail'
    end

    local QBCore = get_qbcore()
    if not QBCore then
        return false, 'qb-core core object unavailable'
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.Functions or not Player.Functions.AddMoney then
        return false, 'player not found or qb-core API unavailable'
    end

    local ok = Player.Functions.AddMoney(account, amount, reason)
    if not ok then
        return false, 'qb-core AddMoney returned false'
    end

    return true, nil
end

-- ---- RemoveMoney --------------------------------------------

---@param src number
---@param account "cash"|"bank"
---@param amount number
---@param reason string
---@return boolean ok
---@return string|nil err
function adapter.RemoveMoney(src, account, amount, reason)
    if not is_server() then
        return false, 'must be called from server'
    end

    if not is_valid_account(account) then
        return false, 'invalid account: ' .. tostring(account)
    end

    if not is_valid_positive_amount(amount) then
        return false, 'invalid amount: ' .. tostring(amount)
    end

    if type(reason) ~= 'string' or reason == '' then
        return false, 'reason is required for audit trail'
    end

    -- Server-authoritative check.
    local current = adapter.GetMoney(src, account)
    if current < amount then
        return false, 'insufficient funds'
    end

    local QBCore = get_qbcore()
    if not QBCore then
        return false, 'qb-core core object unavailable'
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.Functions or not Player.Functions.RemoveMoney then
        return false, 'player not found or qb-core API unavailable'
    end

    local ok = Player.Functions.RemoveMoney(account, amount, reason)
    if not ok then
        return false, 'qb-core RemoveMoney returned false'
    end

    return true, nil
end

-- ---- Notify -------------------------------------------------

---@param src number
---@param message string
---@param notify_type "success"|"error"|"info"|"warning"
function adapter.Notify(src, message, notify_type)
    if not is_server() then
        return
    end

    local QBCore = get_qbcore()
    if not QBCore or not QBCore.Functions or not QBCore.Functions.Notify then
        return
    end

    -- QBCore native types: 'success' | 'error' | 'primary'.
    -- Our public API exposes: success | error | info | warning.
    local qb_type
    if notify_type == 'success' then
        qb_type = 'success'
    elseif notify_type == 'error' or notify_type == 'warning' then
        qb_type = 'error'
    else -- 'info' or anything unknown
        qb_type = 'primary'
    end

    QBCore.Functions.Notify(src, message, qb_type)
end

-- ---- Register adapter ---------------------------------------

Sonar.Farm.Bridge.__qbcore_adapter = adapter
