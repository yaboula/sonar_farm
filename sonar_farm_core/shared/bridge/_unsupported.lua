-- ============================================================
-- Farm Sonar — Bridge fallback adapter for unsupported frameworks.
-- ============================================================
--
-- This file ALWAYS loads as a shared_script (so the table is
-- registered on Sonar.Farm.Bridge.__unsupported_adapter and
-- init.lua can pick it). But its error log MUST NOT fire at
-- top-level — `init.lua` calls `adapter.LogUnsupportedOnce()`
-- only when this adapter is actually selected.
--
-- Intent when activated:
--   1. The resource stays loaded (admins still see it).
--   2. A clear, one-time error tells the admin what to install.
--   3. All public methods are no-ops returning safe nil/false/0.
-- ============================================================

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Bridge = Sonar.Farm.Bridge or {}

local adapter = {}

-- Logger to be invoked by init.lua when (and only when) this
-- adapter has been picked. Server side only.
function adapter.LogUnsupportedOnce()
    if IsDuplicityVersion() then
        print(('[sonar_farm_core][ERROR] %s'):format(locale('boot.framework_unsupported')))
    end
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
