Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.VerifiedProps = Config.Farm.VerifiedProps or {}

Config.Farm.VerifiedProps.wheat = {
    stages = {
        [0] = { prop_name = 'prop_veg_grass_01_a', prop_scale = 1.0, prop_z_offset = 0.0 },
        [1] = { prop_name = 'prop_veg_grass_01_b', prop_scale = 1.0, prop_z_offset = 0.0 },
        [2] = { prop_name = 'prop_veg_grass_01_c', prop_scale = 1.0, prop_z_offset = 0.0 },
        [3] = { prop_name = 'prop_veg_crop_06', prop_scale = 1.0, prop_z_offset = 0.0 },
        [4] = { prop_name = 'prop_veg_crop_06', prop_scale = 1.0, prop_z_offset = 0.0 },
    },
    cooldown = {
        prop_name = 'prop_veg_crop_04',
        prop_scale = 1.0,
        prop_z_offset = -0.75,
    },
}

Config.Farm.VerifiedProps.corn = {
    stages = {
        [0] = { prop_name = 'prop_veg_corn_01', prop_scale = 0.7, prop_z_offset = 0.0 },
        [1] = { prop_name = 'prop_veg_corn_01', prop_scale = 0.95, prop_z_offset = 0.0 },
        [2] = { prop_name = 'prop_veg_corn_01', prop_scale = 1.15, prop_z_offset = 0.0 },
        [3] = { prop_name = 'prop_veg_corn_01', prop_scale = 1.3, prop_z_offset = 0.0 },
        [4] = { prop_name = 'prop_veg_corn_01', prop_scale = 1.35, prop_z_offset = 0.0 },
    },
    cooldown = {
        prop_name = 'prop_veg_crop_04',
        prop_scale = 1.0,
        prop_z_offset = -0.75,
    },
}

Config.Farm.VerifiedProps.barley = {
    stages = {
        [0] = { prop_name = 'prop_plant_cane_01a', prop_scale = 0.8, prop_z_offset = 0.0 },
        [1] = { prop_name = 'prop_plant_cane_01a', prop_scale = 1.0, prop_z_offset = 0.0 },
        [2] = { prop_name = 'prop_plant_cane_01b', prop_scale = 1.05, prop_z_offset = 0.0 },
        [3] = { prop_name = 'prop_plant_cane_01b', prop_scale = 1.15, prop_z_offset = 0.0 },
        [4] = { prop_name = 'prop_plant_cane_01b', prop_scale = 1.2, prop_z_offset = 0.0 },
    },
    cooldown = {
        prop_name = 'prop_veg_crop_04',
        prop_scale = 1.0,
        prop_z_offset = -0.75,
    },
}
