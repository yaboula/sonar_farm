-- ============================================================
-- Farm Sonar Tablet — Tablet interaction (field).
-- ============================================================
--
-- Registers a configurable keybind that opens the NUI in field
-- mode. Uses ox_lib's lib.addKeybind for cross-framework compat.
--
-- Config keys: Config.Farm.Tablet.* (see config.lua).
--

local keybind       = Config.Farm.Tablet.Keybind
local keybind_label = Config.Farm.Tablet.KeybindLabel
local default_route = Config.Farm.Tablet.DefaultRoute

lib.addKeybind({
    name = 'sonar_farm_tablet',
    description = keybind_label,
    defaultKey = keybind,
    onPressed = function()
        SonarFarmTablet.OpenNui('field', default_route)
    end,
})
