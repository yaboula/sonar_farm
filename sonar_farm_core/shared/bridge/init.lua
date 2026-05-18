-- ============================================================
-- Farm Sonar — Bridge layer entrypoint.
-- ============================================================
--
-- Responsibility:
--   1. Resolve the active framework (qbox | qbcore | unsupported)
--      following the strategy in ADR-005 §Decisión 2 (hybrid:
--      convar override → autodetect by exports → unsupported).
--   2. Load the matching adapter and bind its methods under
--      `Sonar.Farm.Bridge.*` per ADR-005 §Decisión 1.
--   3. Refuse to crash if no framework is found — fall back to
--      `_unsupported.lua` so the resource stays inert but loaded.
--
-- Contract:  see `shared/bridge/INTERFACE.md` (the single source
--            of truth for what `Sonar.Farm.Bridge.*` exposes).
--
-- This file is loaded as a `shared_script` in fxmanifest.lua so it
-- runs on both server and client. Adapters MAY split server-only
-- and client-only logic internally if needed.
-- ============================================================

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Bridge = Sonar.Farm.Bridge or {}

-- ---- Detection ----------------------------------------------

---@return "qbox"|"qbcore"|"unsupported"
local function detect_framework()
    local override = GetConvar('sonar:framework', 'auto')

    if override == 'qbox' then
        return 'qbox'
    elseif override == 'qbcore' then
        return 'qbcore'
    elseif override ~= 'auto' then
        print(('[sonar_farm_core][WARN] convar `sonar:framework` has unknown value "%s", falling back to autodetect.'):format(override))
    end

    -- Autodetect by export presence. Order matters: QBox first
    -- because some servers run both for migration purposes and
    -- QBox is the project's primary target (Bible §11.2).
    if GetResourceState('qbx_core') == 'started' then
        return 'qbox'
    end

    if GetResourceState('qb-core') == 'started' then
        return 'qbcore'
    end

    return 'unsupported'
end

-- ---- Adapter loading ----------------------------------------
--
-- We use the `LoadResourceFile` + `load` pattern instead of
-- `require` because FiveM Lua does not ship a Lua module loader
-- by default. The adapter files are listed in fxmanifest.lua
-- shared_scripts BEFORE this init.lua so their globals (i.e.
-- `Sonar.Farm.Bridge.__qbox_adapter`, `__qbcore_adapter`,
-- `__unsupported_adapter`) are already defined by the time this
-- file runs.

---@type table
local adapter

local detected = detect_framework()

if detected == 'qbox' then
    adapter = Sonar.Farm.Bridge.__qbox_adapter
elseif detected == 'qbcore' then
    adapter = Sonar.Farm.Bridge.__qbcore_adapter
else
    adapter = Sonar.Farm.Bridge.__unsupported_adapter
end

if not adapter then
    print(('[sonar_farm_core][ERROR] Bridge adapter for "%s" not found. Check fxmanifest.lua shared_scripts order.'):format(detected))
    adapter = Sonar.Farm.Bridge.__unsupported_adapter or {}
end

-- ---- Public API binding -------------------------------------

Sonar.Farm.Bridge.GetPlayer    = adapter.GetPlayer
Sonar.Farm.Bridge.GetMoney     = adapter.GetMoney
Sonar.Farm.Bridge.AddMoney     = adapter.AddMoney
Sonar.Farm.Bridge.RemoveMoney  = adapter.RemoveMoney
Sonar.Farm.Bridge.Notify       = adapter.Notify

-- Public read-only metadata.
Sonar.Farm.Bridge.framework    = detected

-- ---- Boot log -----------------------------------------------

-- For unsupported, the boot ERROR was already logged by _unsupported.lua.
if detected ~= 'unsupported' then
    local key = 'boot.bridge_initialized'
    local message
    if _G.locale then
        message = locale(key, detected)
    else
        message = ('Bridge initialized → framework: %s'):format(detected)
    end
    print(('[sonar_farm_core] %s'):format(message))
end
