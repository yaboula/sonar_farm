Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Items = Sonar.Farm.Items or {}

local crop_config = Config and Config.Farm and Config.Farm.Crops and Config.Farm.Crops.wheat or {}
local seed_weight_g = math.floor(tonumber(crop_config.seed_weight_g) or 0)
local batch_weight_g = math.floor(tonumber(crop_config.harvest_yield_g) or 0)

Sonar.Farm.Items.Registry = {
    sonar_seed_wheat = {
        name = 'sonar_seed_wheat',
        label = 'items.sonar_seed_wheat.label',
        weight = seed_weight_g,
        stack = true,
        close = true,
        description = 'items.sonar_seed_wheat.desc',
    },
    sonar_batch_wheat = {
        name = 'sonar_batch_wheat',
        label = 'items.sonar_batch_wheat.label',
        weight = batch_weight_g,
        stack = false,
        close = false,
        description = 'items.sonar_batch_wheat.desc',
        client = {
            image = 'sonar_batch_wheat',
        },
    },
}

local function verify_items_registered()
    if IsDuplicityVersion() then
        if type(exports) ~= 'table' or not exports.ox_inventory then
            return
        end

        local ok, items_or_error = pcall(function()
            return exports.ox_inventory:Items()
        end)

        if not ok or type(items_or_error) ~= 'table' then
            return
        end

        local registry = Sonar.Farm.Items.Registry
        for item_name, _ in pairs(registry) do
            if not items_or_error[item_name] then
                print(('[sonar_farm_core][items][WARN] item "%s" is not present in ox_inventory shared item data'):format(item_name))
            end
        end
    end
end

AddEventHandler('onResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    verify_items_registered()
end)
