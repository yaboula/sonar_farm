Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.potato or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.potato = {
    display_name_key = 'crops.potato.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 18900, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.5, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.45, state = 'planted' },
        [1] = { duration_seconds = 18900, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.68, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.4, state = 'germinating' },
        [2] = { duration_seconds = 18900, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.82, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.35, state = 'growing' },
        [3] = { duration_seconds = 18900, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 0.95, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or -0.32, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.0, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or -0.3, state = 'harvest_ready' },
    },
    seed_weight_g = 220,
    harvest_window_seconds = 21600,
    harvest_yield_g = 2200,
    fallow_cooldown_seconds = 3000,
    freshness_decay_rate_per_h = 1,
    seed_quality_default = 70,
    optimal_seasons = { 'spring', 'autumn' },
    preferred_weather = {
        clear = 80,
        light_rain = 90,
        torrential_rain = 65,
        drought = 38,
        hail = 22,
        frost = 50,
    },
    npk_optimal = { n = 60, p = 50, k = 75 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_k', 'sonar_fertilizer_npk' },
        ceiling = 92,
        wrong_penalty = -5,
        overfertilize_floor = 46,
        max_applications_per_stage = 1,
        score_gain_correct = 16,
    },
    pests = {
        susceptible_to = { 'blight', 'aphid' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 32,
        severe_treat_ceiling = 62,
    },
}