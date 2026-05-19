-- ============================================================
-- Farm Sonar Tablet — Resource config.
-- ============================================================
--
-- All tunable values for NUI entrypoints live here.
-- Per anti-pattern §3, no magic numbers in client code.
--
-- Loaded as a shared script in fxmanifest.lua so client
-- scripts see the same Config table.
--

Config = Config or {}
Config.Farm = Config.Farm or {}

-- ============================================================
-- Laptop (office) — ox_target interaction.
-- ============================================================
-- Targets a native GTA V laptop prop placed in the office MLO.
-- Bible §15: no custom 3D devices; use native props.
Config.Farm.Laptop = Config.Farm.Laptop or {}
Config.Farm.Laptop.TargetModel    = 'prop_laptop_01a'
Config.Farm.Laptop.TargetLabel    = locale('interaction.laptop.target_label')
Config.Farm.Laptop.TargetIcon     = 'fa-solid fa-laptop'
Config.Farm.Laptop.TargetDistance = 2.0

-- Spawn location for the office laptop prop.
-- Set SpawnProp = false to disable auto-spawn (e.g. when an MLO places it).
Config.Farm.Laptop.SpawnProp    = true
Config.Farm.Laptop.SpawnCoords  = vector3(2455.16, 4972.49, 45.81)
Config.Farm.Laptop.SpawnHeading = 131.47

-- ============================================================
-- Tablet (field) — keybind.
-- ============================================================
Config.Farm.Tablet = Config.Farm.Tablet or {}
Config.Farm.Tablet.Keybind      = 'F6'
Config.Farm.Tablet.KeybindLabel = locale('interaction.tablet.keybind_label')
Config.Farm.Tablet.DefaultRoute = '/plots'

-- ============================================================
-- NUI / Shell settings.
-- ============================================================
Config.Farm.Nui = Config.Farm.Nui or {}
Config.Farm.Nui.ResourceName = 'sonar_farm_tablet'
