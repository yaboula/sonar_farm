Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.NPCs = Config.Farm.NPCs or {}

Config.Farm.NPCs.ValidQualityGrades = {
    S = true,
    A = true,
    B = true,
    C = true,
    D = true,
}

Config.Farm.NPCs.DefaultFreshnessMultiplier = 1.0
Config.Farm.NPCs.DefaultDailyQuotaKg = 99999
Config.Farm.NPCs.DefaultPayoutAccount = 'bank'
Config.Farm.NPCs.buyers = {
    pedro = {
        display_name_key = 'npcs.pedro.name',
        ped_model = 'a_m_m_farmer_01',
        world_coords = {
            x = 1682.15,
            y = 4840.8,
            z = 42.06,
        },
        heading = 96.43,
        interaction_radius = 5.0,
        accepted_crops = { 'wheat' },
        base_price_per_kg = 0.80,
        quality_multipliers = {
            S = 2.0,
            A = 1.6,
            B = 1.0,
            C = 0.6,
            D = 0.3,
        },
        freshness_multiplier = 1.0,
        daily_quota_kg = 99999,
        payout_account = 'bank',
    },
}
