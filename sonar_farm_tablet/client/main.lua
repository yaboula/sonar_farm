-- ============================================================
-- Farm Sonar Tablet — NUI lifecycle coordinator.
-- ============================================================
--
-- Owns the NUI open/close state machine and the close callback.
-- Other client modules (laptop_interaction, tablet_interaction)
-- call SonarFarmTablet.OpenNui() to trigger the NUI.
--
-- Message contracts MUST match web/src/types/nui.ts byte-for-byte.
-- See docs/slices/S4_nui_shell_design_system.md §8.1.
--

SonarFarmTablet = {}

local is_nui_open = false

--- Open the NUI shell in the given mode, optionally deep-linking to a route.
--- Idempotent: if already open, sends a new open message so the React shell
--- can react to mode/route changes without losing focus.
--- @param mode string 'manager' | 'field'
--- @param route string|nil e.g. '/dashboard', '/plots'
function SonarFarmTablet.OpenNui(mode, route)
    if is_nui_open then
        SendNUIMessage({
            action = 'sonar:farm:nui:open',
            payload = {
                mode = mode,
                route = route,
            },
        })
        return
    end

    is_nui_open = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'sonar:farm:nui:open',
        payload = {
            mode = mode,
            route = route,
        },
    })
end

--- Returns whether the NUI is currently open and holding input focus.
--- @return boolean
function SonarFarmTablet.IsOpen()
    return is_nui_open
end

-- ============================================================
-- NUI close callback — triggered by React when user presses
-- Escape or clicks the topbar close button.
-- ============================================================
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    is_nui_open = false
    SendNUIMessage({ action = 'sonar:farm:nui:close' })
    cb({ ok = true })
end)
