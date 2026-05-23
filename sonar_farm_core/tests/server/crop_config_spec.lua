-- ============================================================
-- Farm Sonar — Config-driven crop registry specs (S12).
-- ============================================================
--
-- Plain Lua spec. Run with:
--     lua sonar_farm_core/tests/server/crop_config_spec.lua
-- ============================================================

Config = nil
Sonar = nil

dofile('sonar_farm_core/config.lua')
dofile('sonar_farm_core/config/items.lua')
dofile('sonar_farm_core/config/verified_props.lua')
dofile('sonar_farm_core/config/crops/wheat.lua')
dofile('sonar_farm_core/config/crops/corn.lua')
dofile('sonar_farm_core/config/crops/barley.lua')
dofile('sonar_farm_core/config/crops/tomato.lua')
dofile('sonar_farm_core/config/crops/pepper.lua')
dofile('sonar_farm_core/config/crops/lettuce.lua')
dofile('sonar_farm_core/config/crops/onion.lua')
dofile('sonar_farm_core/config/crops/potato.lua')
dofile('sonar_farm_core/shared/items/item_registry.lua')

local crops = Config.Farm.Crops or {}
local registry = Sonar.Farm.Items.Registry or {}

assert(type(crops.wheat) == 'table', 'wheat config missing')
assert(type(crops.corn) == 'table', 'corn config missing')
assert(type(crops.barley) == 'table', 'barley config missing')
assert(type(crops.tomato) == 'table', 'tomato config missing')
assert(type(crops.pepper) == 'table', 'pepper config missing')
assert(type(crops.lettuce) == 'table', 'lettuce config missing')
assert(type(crops.onion) == 'table', 'onion config missing')
assert(type(crops.potato) == 'table', 'potato config missing')

assert(crops.corn.plot_types_allowed[1] == 'extensive', 'corn must be allowed on extensive plots')
assert(crops.barley.plot_types_allowed[1] == 'extensive', 'barley must be allowed on extensive plots')
assert(crops.tomato.plot_types_allowed[1] == 'horticultural', 'tomato must be allowed on horticultural plots')
assert(crops.tomato.plot_types_allowed[2] == 'greenhouse', 'tomato must be allowed on greenhouse plots')
assert(crops.pepper.plot_types_allowed[2] == 'greenhouse', 'pepper must be allowed on greenhouse plots')
assert(crops.lettuce.plot_types_allowed[2] == 'greenhouse', 'lettuce must be allowed on greenhouse plots')
assert(crops.onion.plot_types_allowed[2] == 'greenhouse', 'onion must be allowed on greenhouse plots')
assert(crops.potato.plot_types_allowed[2] == 'greenhouse', 'potato must be allowed on greenhouse plots')
assert(crops.corn.stages[4].state == 'harvest_ready', 'corn stage 4 must be harvest_ready')
assert(crops.barley.stages[4].state == 'harvest_ready', 'barley stage 4 must be harvest_ready')
assert(crops.tomato.stages[4].state == 'harvest_ready', 'tomato stage 4 must be harvest_ready')
assert(crops.pepper.stages[4].state == 'harvest_ready', 'pepper stage 4 must be harvest_ready')
assert(crops.lettuce.stages[4].state == 'harvest_ready', 'lettuce stage 4 must be harvest_ready')
assert(crops.onion.stages[4].state == 'harvest_ready', 'onion stage 4 must be harvest_ready')
assert(crops.potato.stages[4].state == 'harvest_ready', 'potato stage 4 must be harvest_ready')
assert((crops.corn.harvest_yield_g or 0) > 0, 'corn harvest_yield_g must be positive')
assert((crops.barley.harvest_yield_g or 0) > 0, 'barley harvest_yield_g must be positive')
assert((crops.tomato.harvest_yield_g or 0) > 0, 'tomato harvest_yield_g must be positive')
assert((crops.pepper.harvest_yield_g or 0) > 0, 'pepper harvest_yield_g must be positive')
assert((crops.lettuce.harvest_yield_g or 0) > 0, 'lettuce harvest_yield_g must be positive')
assert((crops.onion.harvest_yield_g or 0) > 0, 'onion harvest_yield_g must be positive')
assert((crops.potato.harvest_yield_g or 0) > 0, 'potato harvest_yield_g must be positive')

assert(type(registry.sonar_seed_wheat) == 'table', 'wheat seed item missing from registry')
assert(type(registry.sonar_batch_wheat) == 'table', 'wheat batch item missing from registry')
assert(type(registry.sonar_seed_corn) == 'table', 'corn seed item missing from registry')
assert(type(registry.sonar_batch_corn) == 'table', 'corn batch item missing from registry')
assert(type(registry.sonar_seed_barley) == 'table', 'barley seed item missing from registry')
assert(type(registry.sonar_batch_barley) == 'table', 'barley batch item missing from registry')
assert(type(registry.sonar_seed_tomato) == 'table', 'tomato seed item missing from registry')
assert(type(registry.sonar_batch_tomato) == 'table', 'tomato batch item missing from registry')
assert(type(registry.sonar_seed_pepper) == 'table', 'pepper seed item missing from registry')
assert(type(registry.sonar_batch_pepper) == 'table', 'pepper batch item missing from registry')
assert(type(registry.sonar_seed_lettuce) == 'table', 'lettuce seed item missing from registry')
assert(type(registry.sonar_batch_lettuce) == 'table', 'lettuce batch item missing from registry')
assert(type(registry.sonar_seed_onion) == 'table', 'onion seed item missing from registry')
assert(type(registry.sonar_batch_onion) == 'table', 'onion batch item missing from registry')
assert(type(registry.sonar_seed_potato) == 'table', 'potato seed item missing from registry')
assert(type(registry.sonar_batch_potato) == 'table', 'potato batch item missing from registry')

assert(registry.sonar_seed_corn.weight == crops.corn.seed_weight_g, 'corn seed weight must come from crop config')
assert(registry.sonar_batch_corn.weight == crops.corn.harvest_yield_g, 'corn batch weight must come from crop config')
assert(registry.sonar_seed_barley.weight == crops.barley.seed_weight_g, 'barley seed weight must come from crop config')
assert(registry.sonar_batch_barley.weight == crops.barley.harvest_yield_g, 'barley batch weight must come from crop config')
assert(registry.sonar_seed_tomato.weight == crops.tomato.seed_weight_g, 'tomato seed weight must come from crop config')
assert(registry.sonar_batch_tomato.weight == crops.tomato.harvest_yield_g, 'tomato batch weight must come from crop config')
assert(registry.sonar_seed_potato.weight == crops.potato.seed_weight_g, 'potato seed weight must come from crop config')
assert(registry.sonar_batch_potato.weight == crops.potato.harvest_yield_g, 'potato batch weight must come from crop config')

print('crop_config_spec.lua: OK (config-driven registry)')
