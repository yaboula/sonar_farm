Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.lettuce or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.lettuce = {
    display_name_key = 'crops.lettuce.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 14400, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_plant_clover_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.55, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.08, state = 'planted' },
        [1] = { duration_seconds = 14400, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_plant_clover_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.75, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.06, state = 'germinating' },
        [2] = { duration_seconds = 14400, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_clover_02', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.9, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.05, state = 'growing' },
        [3] = { duration_seconds = 14400, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_clover_02', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.05, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or -0.05, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_clover_02', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.1, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or -0.05, state = 'harvest_ready' },
    },
    seed_weight_g = 90,
    harvest_window_seconds = 14400,
    harvest_yield_g = 900,
    fallow_cooldown_seconds = 1800,
    freshness_decay_rate_per_h = 5,
    seed_quality_default = 74,
    optimal_seasons = { 'autumn', 'winter' },
    preferred_weather = {
        clear = 75,
        light_rain = 95,
        torrential_rain = 65,
        drought = 30,
        hail = 25,
        frost = 70,
    },
    npk_optimal = { n = 55, p = 60, k = 40 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_p', 'sonar_fertilizer_n' },
        ceiling = 90,
        wrong_penalty = -4,
        overfertilize_floor = 50,
        max_applications_per_stage = 1,
        score_gain_correct = 14,
    },
    pests = {
        susceptible_to = { 'aphid' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}