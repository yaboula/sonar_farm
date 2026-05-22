Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Items = Sonar.Farm.Items or {}

local function build_registry()
    local registry = {}
    local crops = Config and Config.Farm and Config.Farm.Crops or {}

    for crop_type, crop_config in pairs(crops) do
        if type(crop_type) == 'string' and crop_type ~= '' and type(crop_config) == 'table' then
            local seed_name = ('sonar_seed_%s'):format(crop_type)
            local batch_name = ('sonar_batch_%s'):format(crop_type)
            local seed_weight_g = math.floor(tonumber(crop_config.seed_weight_g) or 0)
            local batch_weight_g = math.floor(tonumber(crop_config.harvest_yield_g) or 0)

            registry[seed_name] = {
                name = seed_name,
                label = ('items.%s.label'):format(seed_name),
                weight = seed_weight_g,
                stack = true,
                close = true,
                description = ('items.%s.desc'):format(seed_name),
            }

            registry[batch_name] = {
                name = batch_name,
                label = ('items.%s.label'):format(batch_name),
                weight = batch_weight_g,
                stack = false,
                close = false,
                description = ('items.%s.desc'):format(batch_name),
                client = {
                    image = batch_name,
                },
            }
        end
    end

    return registry
end

Sonar.Farm.Items.Registry = build_registry()

local function verify_items_registered()
    if type(IsDuplicityVersion) == 'function' and IsDuplicityVersion() then
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

if type(AddEventHandler) == 'function' then
    AddEventHandler('onResourceStart', function(resource_name)
        if resource_name ~= GetCurrentResourceName() then
            return
        end

        verify_items_registered()
    end)
end
