Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Items = Config.Farm.Items or {}
local tank_max_charges = tonumber(Config.Farm.Irrigation and Config.Farm.Irrigation.tank_max_charges) or 5
Config.Farm.Items.tools = {
    sonar_water_tank = {
        label = 'items.sonar_water_tank.label',
        weight = 2000,
        stack = false,
        close = false,
        metadata = { charges = tank_max_charges },
    },
    sonar_machinery_kit = {
        label = 'items.sonar_machinery_kit.label',
        description = 'items.sonar_machinery_kit.desc',
        weight = 1500,
        stack = true,
        close = true,
        client = {
            prop = 'prop_tool_box_04',
            image = 'repairkit',
        },
    },
    sonar_fertilizer_n = {
        label = 'items.sonar_fertilizer_n.label',
        weight = 1000,
        stack = true,
    },
    sonar_fertilizer_p = {
        label = 'items.sonar_fertilizer_p.label',
        weight = 1000,
        stack = true,
    },
    sonar_fertilizer_k = {
        label = 'items.sonar_fertilizer_k.label',
        weight = 1000,
        stack = true,
    },
    sonar_fertilizer_npk = {
        label = 'items.sonar_fertilizer_npk.label',
        weight = 1000,
        stack = true,
    },
    sonar_pesticide_contact = {
        label = 'items.sonar_pesticide_contact.label',
        weight = 500,
        stack = true,
    },
    sonar_pesticide_systemic = {
        label = 'items.sonar_pesticide_systemic.label',
        weight = 500,
        stack = true,
    },
}

Config.Farm.Items.crops = {
    tomato = {
        seed = {
            label = 'items.sonar_seed_tomato.label',
            description = 'items.sonar_seed_tomato.desc',
            stack = true,
            close = true,
        },
        batch = {
            label = 'items.sonar_batch_tomato.label',
            description = 'items.sonar_batch_tomato.desc',
            stack = false,
            close = false,
        },
    },
    pepper = {
        seed = {
            label = 'items.sonar_seed_pepper.label',
            description = 'items.sonar_seed_pepper.desc',
            stack = true,
            close = true,
        },
        batch = {
            label = 'items.sonar_batch_pepper.label',
            description = 'items.sonar_batch_pepper.desc',
            stack = false,
            close = false,
        },
    },
    lettuce = {
        seed = {
            label = 'items.sonar_seed_lettuce.label',
            description = 'items.sonar_seed_lettuce.desc',
            stack = true,
            close = true,
        },
        batch = {
            label = 'items.sonar_batch_lettuce.label',
            description = 'items.sonar_batch_lettuce.desc',
            stack = false,
            close = false,
        },
    },
    onion = {
        seed = {
            label = 'items.sonar_seed_onion.label',
            description = 'items.sonar_seed_onion.desc',
            stack = true,
            close = true,
        },
        batch = {
            label = 'items.sonar_batch_onion.label',
            description = 'items.sonar_batch_onion.desc',
            stack = false,
            close = false,
        },
    },
    potato = {
        seed = {
            label = 'items.sonar_seed_potato.label',
            description = 'items.sonar_seed_potato.desc',
            stack = true,
            close = true,
        },
        batch = {
            label = 'items.sonar_batch_potato.label',
            description = 'items.sonar_batch_potato.desc',
            stack = false,
            close = false,
        },
    },
}
