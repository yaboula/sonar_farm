-- ============================================================
-- Farm Sonar Tablet — Laptop interaction (office).
-- ============================================================
--
-- Optionally spawns a native GTA V laptop prop at the configured
-- coords, then registers an ox_target interaction on that model.
-- Opens the NUI in manager mode.
--
-- Config keys: Config.Farm.Laptop.* (see config.lua).
--

local laptop_model    = Config.Farm.Laptop.TargetModel
local laptop_label    = Config.Farm.Laptop.TargetLabel
local laptop_icon     = Config.Farm.Laptop.TargetIcon
local laptop_distance = Config.Farm.Laptop.TargetDistance

local spawned_prop = nil

-- Spawn the prop if Config.Farm.Laptop.SpawnProp is true.
if Config.Farm.Laptop.SpawnProp then
    local coords  = Config.Farm.Laptop.SpawnCoords
    local heading = Config.Farm.Laptop.SpawnHeading
    local model   = GetHashKey(laptop_model)

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    spawned_prop = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(spawned_prop, heading)
    FreezeEntityPosition(spawned_prop, true)
    SetEntityCollision(spawned_prop, true, true)
    PlaceObjectOnGroundProperly(spawned_prop)

    SetModelAsNoLongerNeeded(model)
end

exports.ox_target:addModel(laptop_model, {
    {
        name = 'sonar_farm_laptop',
        label = laptop_label,
        icon = laptop_icon,
        distance = laptop_distance,
        onSelect = function()
            SonarFarmTablet.OpenNui('manager', '/dashboard')
        end,
    },
})

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name == GetCurrentResourceName() then
        exports.ox_target:removeModel(laptop_model, { 'sonar_farm_laptop' })
        if spawned_prop and DoesEntityExist(spawned_prop) then
            DeleteObject(spawned_prop)
        end
    end
end)
