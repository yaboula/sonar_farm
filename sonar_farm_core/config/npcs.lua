Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.NPCs = Config.Farm.NPCs or {}

local function accepted_crops(order, rules)
    local result = {}

    for index = 1, #order do
        result[index] = order[index]
    end

    for crop_name, rule in pairs(rules) do
        result[crop_name] = rule
    end

    return result
end

local function create_coords4(x, y, z, w)
    if type(vec4) == 'function' then
        return vec4(x, y, z, w)
    end

    return {
        x = x,
        y = y,
        z = z,
        w = w,
    }
end

local function build_world_coords(coords)
    return {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
    }
end

Config.Farm.NPCs.ValidQualityGrades = {
    S = true,
    A = true,
    B = true,
    C = true,
    D = true,
}

Config.Farm.NPCs.QualityRank = {
    S = 5,
    A = 4,
    B = 3,
    C = 2,
    D = 1,
}

Config.Farm.NPCs.DefaultQualityMultipliers = {
    S = 2.0,
    A = 1.6,
    B = 1.0,
    C = 0.6,
    D = 0.3,
}

Config.Farm.NPCs.DefaultFreshnessMultiplier = 1.0
Config.Farm.NPCs.DefaultDailyQuotaKg = 99999
Config.Farm.NPCs.DefaultPayoutAccount = 'bank'
Config.Farm.NPCs.DefaultInteractionRadius = 5.0
Config.Farm.NPCs.CatalogDistanceFallbackM = 99999.0
Config.Farm.NPCs.LegacyBuyerAliases = {
    pedro = 'byr_molino_pedro',
}

Config.Farm.NPCs.spawn_layout = {
    anchor = create_coords4(2123.58, 4805.15, 40.2, 115.22),
    spacing_m = 6.0,
    stagger_offset_m = 2.0,
    buyer_order = {
        'byr_molino_pedro',
        'byr_supermercado_casals',
        'byr_restaurante_la_plaza',
        'byr_distribuidora_vega',
        'byr_conservera_del_sur',
        'byr_mercado_verde',
        'byr_granero_ortega',
        'byr_hotel_aurora',
    },
}

Config.Farm.NPCs.vendors = {
    mechanic = {
        display_name_key = 'npcs.mechanic.name',
        ped_model = 's_m_y_xmech_01',
        world_coords = {
            x = 1688.24,
            y = 4809.78,
            z = 42.01,
        },
        heading = 126.0,
        interaction_radius = 4.0,
        catalog = {
            sonar_machinery_kit = {
                price = 250,
                account = 'bank',
            },
        },
    },
}

Config.Farm.NPCs.buyers = {
    byr_molino_pedro = {
        id = 'byr_molino_pedro',
        display_name_key = 'npcs.buyers.byr_molino_pedro.name',
        kind = 'mill',
        district_key = 'npcs.districts.grapeseed_industrial',
        ped_model = 'a_m_m_farmer_01',
        coords = create_coords4(1682.15, 4840.80, 42.06, 96.43),
        world_coords = {
            x = 1682.15,
            y = 4840.80,
            z = 42.06,
        },
        heading = 96.43,
        interaction_radius = 5.0,
        blip = {
            sprite = 478,
            color = 46,
            scale = 0.85,
        },
        accepted_crops = accepted_crops({ 'wheat', 'barley', 'corn' }, {
            wheat = {
                min_quality = 'B',
                base_price_eur_per_g = 0.00080,
                daily_capacity_g = 450000,
            },
            barley = {
                min_quality = 'B',
                base_price_eur_per_g = 0.00072,
                daily_capacity_g = 400000,
            },
            corn = {
                min_quality = 'B',
                base_price_eur_per_g = 0.00068,
                daily_capacity_g = 350000,
            },
        }),
        contracts_enabled = true,
        personality_modifier = 1.0,
        quality_multipliers = {
            S = 2.0,
            A = 1.6,
            B = 1.0,
            C = 0.6,
            D = 0.3,
        },
        freshness_multiplier = 1.0,
        payout_account = 'bank',
    },
    byr_supermercado_casals = {
        id = 'byr_supermercado_casals',
        display_name_key = 'npcs.buyers.byr_supermercado_casals.name',
        kind = 'supermarket',
        district_key = 'npcs.districts.paleto_commercial',
        ped_model = 'a_f_y_business_02',
        coords = create_coords4(117.54, 6640.11, 31.76, 223.19),
        world_coords = {
            x = 117.54,
            y = 6640.11,
            z = 31.76,
        },
        heading = 223.19,
        interaction_radius = 5.0,
        blip = {
            sprite = 52,
            color = 2,
            scale = 0.8,
        },
        accepted_crops = accepted_crops({ 'wheat', 'barley', 'corn', 'tomato', 'pepper', 'lettuce', 'onion', 'potato' }, {
            wheat = { min_quality = 'B', base_price_eur_per_g = 0.00074, daily_capacity_g = 220000 },
            barley = { min_quality = 'B', base_price_eur_per_g = 0.00069, daily_capacity_g = 180000 },
            corn = { min_quality = 'B', base_price_eur_per_g = 0.00072, daily_capacity_g = 200000 },
            tomato = { min_quality = 'B', base_price_eur_per_g = 0.00128, daily_capacity_g = 160000 },
            pepper = { min_quality = 'B', base_price_eur_per_g = 0.00136, daily_capacity_g = 140000 },
            lettuce = { min_quality = 'B', base_price_eur_per_g = 0.00102, daily_capacity_g = 120000 },
            onion = { min_quality = 'B', base_price_eur_per_g = 0.00098, daily_capacity_g = 130000 },
            potato = { min_quality = 'B', base_price_eur_per_g = 0.00090, daily_capacity_g = 190000 },
        }),
        contracts_enabled = true,
        personality_modifier = 1.02,
        payout_account = 'bank',
    },
    byr_restaurante_la_plaza = {
        id = 'byr_restaurante_la_plaza',
        display_name_key = 'npcs.buyers.byr_restaurante_la_plaza.name',
        kind = 'restaurant',
        district_key = 'npcs.districts.sandy_central',
        ped_model = 'u_f_y_mistress',
        coords = create_coords4(1961.24, 3741.57, 32.33, 300.61),
        world_coords = {
            x = 1961.24,
            y = 3741.57,
            z = 32.33,
        },
        heading = 300.61,
        interaction_radius = 5.0,
        blip = {
            sprite = 93,
            color = 5,
            scale = 0.8,
        },
        accepted_crops = accepted_crops({ 'tomato', 'pepper', 'lettuce', 'onion', 'potato' }, {
            tomato = { min_quality = 'A', base_price_eur_per_g = 0.00144, daily_capacity_g = 70000 },
            pepper = { min_quality = 'A', base_price_eur_per_g = 0.00158, daily_capacity_g = 65000 },
            lettuce = { min_quality = 'A', base_price_eur_per_g = 0.00118, daily_capacity_g = 50000 },
            onion = { min_quality = 'A', base_price_eur_per_g = 0.00110, daily_capacity_g = 45000 },
            potato = { min_quality = 'A', base_price_eur_per_g = 0.00102, daily_capacity_g = 60000 },
        }),
        contracts_enabled = false,
        personality_modifier = 1.08,
        payout_account = 'bank',
    },
    byr_distribuidora_vega = {
        id = 'byr_distribuidora_vega',
        display_name_key = 'npcs.buyers.byr_distribuidora_vega.name',
        kind = 'distributor',
        district_key = 'npcs.districts.harmony_logistics',
        ped_model = 's_m_m_dockwork_01',
        coords = create_coords4(587.27, 2793.08, 42.16, 273.51),
        world_coords = {
            x = 587.27,
            y = 2793.08,
            z = 42.16,
        },
        heading = 273.51,
        interaction_radius = 5.0,
        blip = {
            sprite = 478,
            color = 17,
            scale = 0.82,
        },
        accepted_crops = accepted_crops({ 'wheat', 'barley', 'corn', 'tomato', 'pepper', 'lettuce', 'onion', 'potato' }, {
            wheat = { min_quality = 'C', base_price_eur_per_g = 0.00060, daily_capacity_g = 900000 },
            barley = { min_quality = 'C', base_price_eur_per_g = 0.00058, daily_capacity_g = 850000 },
            corn = { min_quality = 'C', base_price_eur_per_g = 0.00056, daily_capacity_g = 900000 },
            tomato = { min_quality = 'C', base_price_eur_per_g = 0.00100, daily_capacity_g = 350000 },
            pepper = { min_quality = 'C', base_price_eur_per_g = 0.00108, daily_capacity_g = 320000 },
            lettuce = { min_quality = 'C', base_price_eur_per_g = 0.00082, daily_capacity_g = 260000 },
            onion = { min_quality = 'C', base_price_eur_per_g = 0.00078, daily_capacity_g = 280000 },
            potato = { min_quality = 'C', base_price_eur_per_g = 0.00072, daily_capacity_g = 420000 },
        }),
        contracts_enabled = true,
        personality_modifier = 0.92,
        payout_account = 'bank',
    },
    byr_conservera_del_sur = {
        id = 'byr_conservera_del_sur',
        display_name_key = 'npcs.buyers.byr_conservera_del_sur.name',
        kind = 'canner',
        district_key = 'npcs.districts.cypress_flats_food',
        ped_model = 's_f_y_factory_01',
        coords = create_coords4(816.41, -2142.68, 29.62, 355.27),
        world_coords = {
            x = 816.41,
            y = -2142.68,
            z = 29.62,
        },
        heading = 355.27,
        interaction_radius = 5.0,
        blip = {
            sprite = 478,
            color = 1,
            scale = 0.82,
        },
        accepted_crops = accepted_crops({ 'tomato', 'pepper', 'onion' }, {
            tomato = { min_quality = 'B', base_price_eur_per_g = 0.00134, daily_capacity_g = 380000 },
            pepper = { min_quality = 'B', base_price_eur_per_g = 0.00142, daily_capacity_g = 320000 },
            onion = { min_quality = 'B', base_price_eur_per_g = 0.00104, daily_capacity_g = 250000 },
        }),
        contracts_enabled = true,
        personality_modifier = 1.04,
        payout_account = 'bank',
    },
    byr_mercado_verde = {
        id = 'byr_mercado_verde',
        display_name_key = 'npcs.buyers.byr_mercado_verde.name',
        kind = 'greengrocer',
        district_key = 'npcs.districts.chumash_market',
        ped_model = 'a_f_m_bevhills_02',
        coords = create_coords4(-3189.67, 1294.42, 14.55, 246.14),
        world_coords = {
            x = -3189.67,
            y = 1294.42,
            z = 14.55,
        },
        heading = 246.14,
        interaction_radius = 5.0,
        blip = {
            sprite = 52,
            color = 25,
            scale = 0.78,
        },
        accepted_crops = accepted_crops({ 'tomato', 'pepper', 'lettuce', 'onion', 'potato' }, {
            tomato = { min_quality = 'A', base_price_eur_per_g = 0.00148, daily_capacity_g = 110000 },
            pepper = { min_quality = 'A', base_price_eur_per_g = 0.00152, daily_capacity_g = 90000 },
            lettuce = { min_quality = 'A', base_price_eur_per_g = 0.00122, daily_capacity_g = 85000 },
            onion = { min_quality = 'B', base_price_eur_per_g = 0.00100, daily_capacity_g = 95000 },
            potato = { min_quality = 'B', base_price_eur_per_g = 0.00094, daily_capacity_g = 100000 },
        }),
        contracts_enabled = false,
        personality_modifier = 1.06,
        payout_account = 'bank',
    },
    byr_granero_ortega = {
        id = 'byr_granero_ortega',
        display_name_key = 'npcs.buyers.byr_granero_ortega.name',
        kind = 'feed_wholesaler',
        district_key = 'npcs.districts.senora_feed',
        ped_model = 's_m_m_cntrybar_01',
        coords = create_coords4(2552.18, 4669.06, 33.95, 17.86),
        world_coords = {
            x = 2552.18,
            y = 4669.06,
            z = 33.95,
        },
        heading = 17.86,
        interaction_radius = 5.0,
        blip = {
            sprite = 478,
            color = 44,
            scale = 0.78,
        },
        accepted_crops = accepted_crops({ 'wheat', 'barley', 'corn', 'potato' }, {
            wheat = { min_quality = 'C', base_price_eur_per_g = 0.00064, daily_capacity_g = 520000 },
            barley = { min_quality = 'C', base_price_eur_per_g = 0.00062, daily_capacity_g = 500000 },
            corn = { min_quality = 'C', base_price_eur_per_g = 0.00061, daily_capacity_g = 550000 },
            potato = { min_quality = 'C', base_price_eur_per_g = 0.00076, daily_capacity_g = 240000 },
        }),
        contracts_enabled = true,
        personality_modifier = 0.96,
        payout_account = 'bank',
    },
    byr_hotel_aurora = {
        id = 'byr_hotel_aurora',
        display_name_key = 'npcs.buyers.byr_hotel_aurora.name',
        kind = 'hospitality',
        district_key = 'npcs.districts.vinewood_hospitality',
        ped_model = 'a_m_y_business_03',
        coords = create_coords4(-1283.27, -1158.91, 5.31, 116.83),
        world_coords = {
            x = -1283.27,
            y = -1158.91,
            z = 5.31,
        },
        heading = 116.83,
        interaction_radius = 5.0,
        blip = {
            sprite = 475,
            color = 7,
            scale = 0.82,
        },
        accepted_crops = accepted_crops({ 'tomato', 'pepper', 'lettuce', 'potato' }, {
            tomato = { min_quality = 'A', base_price_eur_per_g = 0.00162, daily_capacity_g = 90000 },
            pepper = { min_quality = 'A', base_price_eur_per_g = 0.00168, daily_capacity_g = 80000 },
            lettuce = { min_quality = 'A', base_price_eur_per_g = 0.00126, daily_capacity_g = 70000 },
            potato = { min_quality = 'B', base_price_eur_per_g = 0.00100, daily_capacity_g = 75000 },
        }),
        contracts_enabled = true,
        personality_modifier = 1.1,
        payout_account = 'bank',
    },
}

local function apply_buyer_spawn_layout()
    local buyers = Config.Farm.NPCs.buyers or {}
    local layout = Config.Farm.NPCs.spawn_layout or {}
    local anchor = layout.anchor or create_coords4(2123.58, 4805.15, 40.2, 115.22)
    local spacing = tonumber(layout.spacing_m) or 6.0
    local stagger_offset = tonumber(layout.stagger_offset_m) or 2.0
    local heading = tonumber(anchor.w) or 0.0
    local heading_rad = math.rad(heading)
    local forward_x = math.sin(heading_rad)
    local forward_y = math.cos(heading_rad)
    local right_x = math.cos(heading_rad)
    local right_y = -math.sin(heading_rad)
    local buyer_ids = {}
    local seen = {}
    local ordered_ids = type(layout.buyer_order) == 'table' and layout.buyer_order or {}

    for index = 1, #ordered_ids do
        local buyer_id = ordered_ids[index]
        if type(buyer_id) == 'string' and type(buyers[buyer_id]) == 'table' and not seen[buyer_id] then
            buyer_ids[#buyer_ids + 1] = buyer_id
            seen[buyer_id] = true
        end
    end

    local remaining_ids = {}
    for buyer_id, buyer in pairs(buyers) do
        if type(buyer_id) == 'string' and type(buyer) == 'table' and not seen[buyer_id] then
            remaining_ids[#remaining_ids + 1] = buyer_id
        end
    end

    table.sort(remaining_ids)
    for index = 1, #remaining_ids do
        buyer_ids[#buyer_ids + 1] = remaining_ids[index]
    end

    for index = 1, #buyer_ids do
        local buyer_id = buyer_ids[index]
        local buyer = buyers[buyer_id]
        local offset_index = index - 1
        local forward_distance = spacing * offset_index
        local lateral_distance = 0.0

        if offset_index > 0 then
            local lateral_sign = (offset_index % 2 == 1) and 1 or -1
            lateral_distance = stagger_offset * lateral_sign
        end

        local x = (tonumber(anchor.x) or 0.0) + (forward_x * forward_distance) + (right_x * lateral_distance)
        local y = (tonumber(anchor.y) or 0.0) + (forward_y * forward_distance) + (right_y * lateral_distance)
        local z = tonumber(anchor.z) or 0.0
        local coords = create_coords4(x, y, z, heading)

        buyer.coords = coords
        buyer.world_coords = build_world_coords(coords)
        buyer.heading = heading
    end
end

apply_buyer_spawn_layout()

