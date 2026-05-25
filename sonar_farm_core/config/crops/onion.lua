Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.onion or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.onion = {
    display_name_key = 'crops.onion.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 16200, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_plant_01a', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.55, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.4, state = 'planted' },
        [1] = { duration_seconds = 16200, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_plant_01a', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.75, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.35, state = 'germinating' },
        [2] = { duration_seconds = 16200, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_01b', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.9, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.28, state = 'growing' },
        [3] = { duration_seconds = 16200, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_01b', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.0, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or -0.22, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_01b', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.05, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or -0.2, state = 'harvest_ready' },
    },
    seed_weight_g = 130,
    harvest_window_seconds = 18000,
    harvest_yield_g = 1400,
    fallow_cooldown_seconds = 2400,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 71,
    optimal_seasons = { 'spring', 'autumn' },
    preferred_weather = {
        clear = 82,
        light_rain = 88,
        torrential_rain = 60,
        drought = 40,
        hail = 20,
        frost = 55,
    },
    npk_optimal = { n = 45, p = 55, k = 65 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_p', 'sonar_fertilizer_k' },
        ceiling = 91,
        wrong_penalty = -4,
        overfertilize_floor = 48,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'blight' },
        spawn_probability_per_tick = 0.04,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}