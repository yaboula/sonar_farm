-- ============================================================
-- Farm Sonar — Client entrypoint.
-- ============================================================
--
-- S0 scope: empty. The client is loaded but does nothing visible
-- yet. Future slices will register interactions, NUI focus, and
-- ox_target zones here.
--

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    if not Sonar or not Sonar.Farm or not Sonar.Farm.Version then
        return
    end

    -- Intentionally minimal. Slice S4 (NUI shell) will hook here.
end)
