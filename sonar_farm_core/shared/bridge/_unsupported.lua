-- ============================================================
-- Farm Sonar — Bridge fallback adapter for unsupported frameworks.
-- ============================================================
--
-- Loaded when neither QBox nor QBCore is detected. All public
-- methods are no-ops that return safe `nil` / `false` / `0`
-- values so callers don't crash.
--
-- The intent is twofold:
--   1. The resource stays loaded (admins can still see it in
--      `resources` and inspect logs).
--   2. The user-facing error is logged ONCE, clearly, on boot,
--      so the server admin knows what to install.
-- ============================================================

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Bridge = Sonar.Farm.Bridge or {}

local adapter = {}

-- One-time log on the server side only.
if IsDuplicityVersion() then
    local key = 'boot.framework_unsupported'
    local message
    if _G.locale then
        message = locale(key)
    else
        message = 'Farm Sonar requires QBox or QBCore. ESX bridge planned for wave 2+.'
    end
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

-- ---- No-op methods (keep the public surface intact) --------

function adapter.GetPlayer(_src)
    return nil
end

function adapter.GetMoney(_src, _account)
    return 0
end

function adapter.AddMoney(_src, _account, _amount, _reason)
    return false, 'bridge not initialized: no supported framework detected'
end

function adapter.RemoveMoney(_src, _account, _amount, _reason)
    return false, 'bridge not initialized: no supported framework detected'
end

function adapter.Notify(_src, _message, _type)
    -- Silent no-op. The boot error already informed the admin.
end

-- ---- Register adapter ---------------------------------------

Sonar.Farm.Bridge.__unsupported_adapter = adapter
