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
