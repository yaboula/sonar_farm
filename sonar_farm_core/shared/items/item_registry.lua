Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Items = Sonar.Farm.Items or {}

local function build_registry()
    local registry = {}
    local crops = Config and Config.Farm and Config.Farm.Crops or {}
    local item_crops = Config and Config.Farm and Config.Farm.Items and Config.Farm.Items.crops or {}
    local item_tools = Config and Config.Farm and Config.Farm.Items and Config.Farm.Items.tools or {}

    for crop_type, crop_config in pairs(crops) do
        if type(crop_type) == 'string' and crop_type ~= '' and type(crop_config) == 'table' then
            local seed_name = ('sonar_seed_%s'):format(crop_type)
            local batch_name = ('sonar_batch_%s'):format(crop_type)
            local seed_weight_g = math.floor(tonumber(crop_config.seed_weight_g) or 0)
            local batch_weight_g = math.floor(tonumber(crop_config.harvest_yield_g) or 0)
            local crop_item_config = type(item_crops[crop_type]) == 'table' and item_crops[crop_type] or {}
            local seed_item_config = type(crop_item_config.seed) == 'table' and crop_item_config.seed or {}
            local batch_item_config = type(crop_item_config.batch) == 'table' and crop_item_config.batch or {}

            registry[seed_name] = {
                name = seed_name,
                label = seed_item_config.label or ('items.%s.label'):format(seed_name),
                weight = seed_weight_g,
                stack = seed_item_config.stack ~= false,
                close = seed_item_config.close ~= false,
                description = seed_item_config.description or ('items.%s.desc'):format(seed_name),
                client = seed_item_config.client,
            }

            registry[batch_name] = {
                name = batch_name,
                label = batch_item_config.label or ('items.%s.label'):format(batch_name),
                weight = batch_weight_g,
                stack = batch_item_config.stack == true,
                close = batch_item_config.close == true,
                description = batch_item_config.description or ('items.%s.desc'):format(batch_name),
                client = batch_item_config.client or {
                    image = batch_name,
                },
            }
        end
    end

    for item_name, item_config in pairs(item_tools) do
        if type(item_name) == 'string' and item_name ~= '' and type(item_config) == 'table' then
            registry[item_name] = {
                name = item_name,
                label = item_config.label or ('items.%s.label'):format(item_name),
                weight = math.floor(tonumber(item_config.weight) or 0),
                stack = item_config.stack == true,
                close = item_config.close == true,
                consume = tonumber(item_config.consume),
                description = item_config.description or ('items.%s.desc'):format(item_name),
                client = item_config.client,
                metadata = item_config.metadata,
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
