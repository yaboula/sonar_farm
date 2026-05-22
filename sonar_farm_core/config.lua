-- ============================================================
-- Farm Sonar — Root config placeholder.
-- ============================================================
--
-- Future slices will populate this. Per anti-pattern §3, ALL tunable
-- values must live here or in `config/*.lua` partials, never inline
-- in code.
--
-- Loaded as a shared script in fxmanifest.lua so both server and
-- client see the same Config table.
--

Config = Config or {}
Config.Farm = Config.Farm or {}

-- Default locale fallback (per rule 03_languages.md).
Config.Farm.Locale = 'en'

-- Debug flag: toggles verbose logs and admin commands. NEVER true in production.
Config.Farm.Debug = true

Config.Farm.Chat = Config.Farm.Chat or {}
Config.Farm.Chat.BrandColor = { 182, 251, 99 }

Config.Farm.Interactions = {
    Progress = {
        plant = 3000,
        harvest = 5000,
        water = 10000,
        refill = 5000,
        fertilize = 8000,
        treat_pest = 12000,
    },
    Animations = {
        plant = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
        harvest = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
        water = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
        refill = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
        fertilize = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
        treat_pest = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
    },
}

Config.Farm.Rendering = {
    PlotPropCullingRadius = 250.0,
    HarvestFxDurationMs = 900,
}

Config.Farm.Storage = Config.Farm.Storage or {}
Config.Farm.Storage.AllowedTypes = Config.Farm.Storage.AllowedTypes or {}
Config.Farm.Storage.units = Config.Farm.Storage.units or {}

Config.Farm.NPCs = Config.Farm.NPCs or {}
Config.Farm.NPCs.ValidQualityGrades = Config.Farm.NPCs.ValidQualityGrades or {}
Config.Farm.NPCs.buyers = Config.Farm.NPCs.buyers or {}

Config.Farm.Finance = Config.Farm.Finance or {}
Config.Farm.Finance.AmountPrecision = Config.Farm.Finance.AmountPrecision or 2

Config.Farm.Scheduler = { TickSeconds = 30 }

Config.Farm.Persistence = {
    OfflineCapHours = 6,
    MaxFactorPenalty = 30,
    IrrigationPenaltyPerHour = 5,
    PestPenaltyPerHour = 5,
}

Config.Farm.Client = Config.Farm.Client or {}
Config.Farm.Client.Startup = {
    RetryCount = 10,
    RetryWaitMs = 1000,
}

Config.Farm.Client.NPCVendor = {
    ModelLoadDeadlineMs = 5000,
    SaleProgressDurationMs = 3000,
    SuccessNotifyDurationMs = 5000,
}

Config.Farm.Quality = {
    weights = {
        soil = 1.0,
        irrigation = 1.0,
        pest_impact = 1.0,
        weather_match = 1.0,
        seed_quality = 1.0,
        fertilization = 1.0,
        harvest_timing = 1.0,
    },
    NeutralDefaults = {
        irrigation = 70,
        pest_impact = 100,
        weather_match = 70,
        seed_quality = 70,
        fertilization = 70,
    },
    HarvestTimingDecayPerHour = 5,
    Grades = { S = 95, A = 80, B = 60, C = 40 },
}
