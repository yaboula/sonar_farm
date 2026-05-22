-- ============================================================
-- Farm Sonar — Bridge adapter for QBox.
-- ============================================================
--
-- This file is loaded BEFORE init.lua (see fxmanifest.lua
-- shared_scripts order). It registers itself as
-- `Sonar.Farm.Bridge.__qbox_adapter` and init.lua picks it up
-- if QBox was detected.
--
-- Public contract: see `shared/bridge/INTERFACE.md`.
-- Decisions:       see ADR-005.
--
-- QBox API references used here:
--   - `exports.qbx_core:GetPlayer(src)`         server-only
--   - `Player.PlayerData.charinfo`              { firstname, lastname, ... }
--   - `Player.PlayerData.citizenid`             string
--   - `Player.PlayerData.job`                   { name, grade = { level } }
--   - `Player.PlayerData.money`                 { cash, bank, ... }
--   - `Player.Functions.AddMoney(account, amount, reason)`
--   - `Player.Functions.RemoveMoney(account, amount, reason)`
--
-- Notifications use `ox_lib`'s `lib.notify` because QBox bundles
-- ox_lib as a hard dependency and that's the canonical UI path.
-- ============================================================

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Bridge = Sonar.Farm.Bridge or {}

local adapter = {}

-- ---- Helpers ------------------------------------------------

local function is_server()
    return IsDuplicityVersion()
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

    local Player = exports.qbx_core:GetPlayer(src)
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
        framework  = 'qbox',
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

    local Player = exports.qbx_core:GetPlayer(src)
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

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player or not Player.Functions or not Player.Functions.AddMoney then
        return false, 'player not found or qbox API unavailable'
    end

    local ok = Player.Functions.AddMoney(account, amount, reason)
    if not ok then
        return false, 'qbox AddMoney returned false'
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

    -- Server-authoritative check: never trust the framework's
    -- silent-failure for insufficient funds.
    local current = adapter.GetMoney(src, account)
    if current < amount then
        return false, 'insufficient funds'
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player or not Player.Functions or not Player.Functions.RemoveMoney then
        return false, 'player not found or qbox API unavailable'
    end

    local ok = Player.Functions.RemoveMoney(account, amount, reason)
    if not ok then
        return false, 'qbox RemoveMoney returned false'
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

    -- ox_lib accepts: 'success' | 'error' | 'inform' | 'warning'.
    -- We expose 'info' in our public API for symmetry with QBCore;
    -- map it to ox_lib's 'inform' here.
    local ox_type = notify_type
    if notify_type == 'info' then
        ox_type = 'inform'
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title       = locale('ui.brand_name'),
        description = message,
        type        = ox_type,
    })
end

-- ---- Register adapter ---------------------------------------

Sonar.Farm.Bridge.__qbox_adapter = adapter
