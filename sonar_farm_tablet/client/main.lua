-- ============================================================
-- Farm Sonar Tablet — NUI client entrypoint.
-- ============================================================
--
-- S0 scope: empty. The NUI is bundled and exposed via ui_page but
-- kept hidden until S4 (NUI shell) wires up the laptop / tablet
-- entrypoints (ox_target on the office laptop + keybind for tablet).
--

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    -- Deliberately NOT calling SetNuiFocus(true, true) here.
    -- S4 will own the NUI lifecycle (open/close, focus, hide/show).
    SendNUIMessage({ action = 'farm:tablet:boot', payload = { ready = true } })
end)
