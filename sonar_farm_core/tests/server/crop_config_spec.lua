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
dofile('sonar_farm_core/config/verified_props.lua')
dofile('sonar_farm_core/config/crops/wheat.lua')
dofile('sonar_farm_core/config/crops/corn.lua')
dofile('sonar_farm_core/config/crops/barley.lua')
dofile('sonar_farm_core/shared/items/item_registry.lua')

local crops = Config.Farm.Crops or {}
local registry = Sonar.Farm.Items.Registry or {}

assert(type(crops.wheat) == 'table', 'wheat config missing')
assert(type(crops.corn) == 'table', 'corn config missing')
assert(type(crops.barley) == 'table', 'barley config missing')

assert(crops.corn.plot_types_allowed[1] == 'extensive', 'corn must be allowed on extensive plots')
assert(crops.barley.plot_types_allowed[1] == 'extensive', 'barley must be allowed on extensive plots')
assert(crops.corn.stages[4].state == 'harvest_ready', 'corn stage 4 must be harvest_ready')
assert(crops.barley.stages[4].state == 'harvest_ready', 'barley stage 4 must be harvest_ready')
assert((crops.corn.harvest_yield_g or 0) > 0, 'corn harvest_yield_g must be positive')
assert((crops.barley.harvest_yield_g or 0) > 0, 'barley harvest_yield_g must be positive')

assert(type(registry.sonar_seed_wheat) == 'table', 'wheat seed item missing from registry')
assert(type(registry.sonar_batch_wheat) == 'table', 'wheat batch item missing from registry')
assert(type(registry.sonar_seed_corn) == 'table', 'corn seed item missing from registry')
assert(type(registry.sonar_batch_corn) == 'table', 'corn batch item missing from registry')
assert(type(registry.sonar_seed_barley) == 'table', 'barley seed item missing from registry')
assert(type(registry.sonar_batch_barley) == 'table', 'barley batch item missing from registry')

assert(registry.sonar_seed_corn.weight == crops.corn.seed_weight_g, 'corn seed weight must come from crop config')
assert(registry.sonar_batch_corn.weight == crops.corn.harvest_yield_g, 'corn batch weight must come from crop config')
assert(registry.sonar_seed_barley.weight == crops.barley.seed_weight_g, 'barley seed weight must come from crop config')
assert(registry.sonar_batch_barley.weight == crops.barley.harvest_yield_g, 'barley batch weight must come from crop config')

print('crop_config_spec.lua: OK (config-driven registry)')
