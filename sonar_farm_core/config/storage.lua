Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Storage = Config.Farm.Storage or {}

Config.Farm.Storage.AllowedTypes = {
    dry = true,
    cold = true,
}

Config.Farm.Storage.DefaultRadius = 2.0
Config.Farm.Storage.DefaultDecayMultiplier = 1.0
Config.Farm.Storage.StashPrefix = 'sonar_farm_silo_'
Config.Farm.Storage.units = {
    {
        storage_id = 'silo_grapeseed_01',
        display_name_key = 'storage.silo_grapeseed_01.name',
        storage_type = 'dry',
        coords = {
            x = 1680.0,
            y = 4820.0,
            z = 42.0,
        },
        radius = 3.0,
        max_slots = 50,
        max_weight_kg = 5000,
        decay_multiplier = 1.0,
    },
}
