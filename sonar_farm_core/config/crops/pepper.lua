Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.pepper or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.pepper = {
    display_name_key = 'crops.pepper.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 19800, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.32, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.1, state = 'planted' },
        [1] = { duration_seconds = 19800, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.42, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.08, state = 'germinating' },
        [2] = { duration_seconds = 19800, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_flower_01', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.65, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.02, state = 'growing' },
        [3] = { duration_seconds = 19800, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_flower_03', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 0.8, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_flower_03', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 0.9, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 110,
    harvest_window_seconds = 19800,
    harvest_yield_g = 1600,
    fallow_cooldown_seconds = 2700,
    freshness_decay_rate_per_h = 4,
    seed_quality_default = 72,
    optimal_seasons = { 'spring', 'summer' },
    preferred_weather = {
        clear = 92,
        light_rain = 78,
        torrential_rain = 35,
        drought = 28,
        hail = 15,
        frost = 10,
    },
    npk_optimal = { n = 65, p = 45, k = 70 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_k', 'sonar_fertilizer_npk' },
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