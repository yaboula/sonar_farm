-- ============================================================
-- Farm Sonar — Finance domain boot coordinator.
-- ============================================================
--
-- Exposes Sonar.Farm.Finance.Boot() called by server/main.lua
-- after DB boot succeeds. Selecting an adapter at boot time is
-- safe: Init() reads config and registers the adapter but never
-- touches the DB directly. DB is only hit during Credit/Debit
-- operations at runtime.
--
-- Preconditions (enforced by fxmanifest.lua load order):
--   server/finance/adapters/native_bridge.lua loaded first.
--   server/finance/movement_service.lua loaded second.
--   server/finance/money_adapter.lua loaded third.
--   THIS FILE loaded fourth, before server/main.lua.
--

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Finance = Sonar.Farm.Finance or {}

local function log_info(message)
    print(('[sonar_farm_core] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

function Sonar.Farm.Finance.Boot()
    if type(Sonar.Farm.Finance.Init) ~= 'function' then
        log_error(locale('finance.boot.unavailable'))
        return false
    end

    Sonar.Farm.Finance.Init()

    local adapter_info = Sonar.Farm.Finance.GetActiveAdapter()
    log_info(locale('finance.boot.adapter_selected'):format(adapter_info.adapter_name, adapter_info.mode))

    return true
end
