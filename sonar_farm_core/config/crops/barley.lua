Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.barley or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.barley = {
    display_name_key = 'crops.barley.name',
    plot_types_allowed = { 'extensive' },
    stages = {
        [0] = { duration_seconds = 25200, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_plant_cane_01a', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.8, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or 0.0, state = 'planted' },
        [1] = { duration_seconds = 25200, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_plant_cane_01a', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 1.0, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or 0.0, state = 'germinating' },
        [2] = { duration_seconds = 25200, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_cane_01b', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 1.05, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or 0.0, state = 'growing' },
        [3] = { duration_seconds = 25200, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_cane_01b', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.15, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_cane_01b', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.2, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 500,
    harvest_window_seconds = 21600,
    harvest_yield_g = 2400,
    fallow_cooldown_seconds = 3600,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 70,
    npk_optimal = { n = 55, p = 35, k = 45 },
}
