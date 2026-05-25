Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.tomato or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.tomato = {
    display_name_key = 'crops.tomato.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 18000, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.35, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.1, state = 'planted' },
        [1] = { duration_seconds = 18000, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.45, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.08, state = 'germinating' },
        [2] = { duration_seconds = 18000, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.6, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.05, state = 'growing' },
        [3] = { duration_seconds = 18000, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_flower_02', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 0.85, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_flower_02', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 0.95, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 120,
    harvest_window_seconds = 18000,
    harvest_yield_g = 1800,
    fallow_cooldown_seconds = 2700,
    freshness_decay_rate_per_h = 4,
    seed_quality_default = 72,
    optimal_seasons = { 'spring', 'summer' },
    preferred_weather = {
        clear = 95,
        light_rain = 80,
        torrential_rain = 35,
        drought = 30,
        hail = 15,
        frost = 10,
    },
    npk_optimal = { n = 70, p = 50, k = 60 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_k' },
        ceiling = 92,
        wrong_penalty = -4,
        overfertilize_floor = 45,
        max_applications_per_stage = 1,
        score_gain_correct = 16,
    },
    pests = {
        susceptible_to = { 'aphid', 'blight' },
        spawn_probability_per_tick = 0.06,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 32,
        severe_treat_ceiling = 62,
    },
}