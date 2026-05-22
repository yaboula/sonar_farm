Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.wheat or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.wheat = {
    display_name_key = 'crops.wheat.name',
    plot_types_allowed = { 'extensive' },
    stages = {
        [0] = { duration_seconds = 21600, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_veg_grass_01_a', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 1.0, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or 0.0, state = 'planted' },
        [1] = { duration_seconds = 21600, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_veg_grass_01_b', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 1.0, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or 0.0, state = 'germinating' },
        [2] = { duration_seconds = 21600, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_veg_grass_01_c', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 1.0, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or 0.0, state = 'growing' },
        [3] = { duration_seconds = 21600, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_veg_crop_06', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.0, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_veg_crop_06', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.0, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 500,
    harvest_window_seconds = 21600,
    harvest_yield_g = 2500,
    fallow_cooldown_seconds = 3600,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 70,
    npk_optimal = { n = 60, p = 40, k = 50 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_n' },
        ceiling = 90,
        wrong_penalty = -5,
        overfertilize_floor = 40,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'blight', 'aphid' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
