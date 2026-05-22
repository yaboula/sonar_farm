Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.corn or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.corn = {
    display_name_key = 'crops.corn.name',
    plot_types_allowed = { 'extensive' },
    stages = {
        [0] = { duration_seconds = 31500, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.7, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or 0.0, state = 'planted' },
        [1] = { duration_seconds = 31500, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.95, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or 0.0, state = 'germinating' },
        [2] = { duration_seconds = 31500, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 1.15, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or 0.0, state = 'growing' },
        [3] = { duration_seconds = 31500, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.3, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.35, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 650,
    harvest_window_seconds = 25200,
    harvest_yield_g = 3500,
    fallow_cooldown_seconds = 3600,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 70,
    npk_optimal = { n = 70, p = 35, k = 55 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_k' },
        ceiling = 90,
        wrong_penalty = -5,
        overfertilize_floor = 40,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'aphid', 'blight' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
