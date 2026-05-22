Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Irrigation = Config.Farm.Irrigation or {}
Config.Farm.Irrigation = {
    tank_max_charges = 5,
    recharge_duration_ms = 5000,
    optimal_ceiling = 90,
    overwater_floor = 50,
    overwater_threshold = 3,
    score_gain_per_water = 10,
    score_loss_overwater = 15,
    well_coords = {
        { x = 1670.0, y = 4815.0, z = 42.0, radius = 2.5 },
    },
}
