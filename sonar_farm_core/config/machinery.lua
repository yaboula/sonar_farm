Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Machinery = Config.Farm.Machinery or {}

Config.Farm.Machinery.DefaultDurability = 100
Config.Farm.Machinery.CriticalBreakThreshold = 30
Config.Farm.Machinery.Usage = {
    mode = 'reported_seconds',
    seconds_per_durability = 60,
    min_report_seconds = 60,
    max_report_seconds = 900,
}
Config.Farm.Machinery.Breakdown = {
    critical_chance_pct = 20,
}
Config.Farm.Machinery.Repair = {
    item_name = 'sonar_machinery_kit',
    restore_durability = 100,
}
Config.Farm.Machinery.Client = {
    Tracking = {
        sample_interval_ms = 10000,
        report_interval_seconds = 60,
        min_movement_distance_m = 1.0,
    },
    Repair = {
        target_distance = 2.5,
        progress_duration_ms = 10000,
        anim_dict = 'mini@repair',
        anim_clip = 'fixing_a_ped',
        anim_flag = 49,
        anim_load_deadline_ms = 5000,
        hood_door_index = 4,
        bones = { 'engine' },
        control_timeout_ms = 750,
    },
    Breakdown = {
        engine_health_broken = -4000.0,
        engine_health_repaired = 1000.0,
        control_timeout_ms = 750,
        control_active_tick_ms = 0,
        control_idle_check_ms = 1000,
    },
}
Config.Farm.Machinery.Models = {
    tractor = {
        wear_multiplier = 1.0,
    },
    tractor2 = {
        wear_multiplier = 0.9,
    },
    tractor3 = {
        wear_multiplier = 0.85,
    },
    fieldmaster = {
        wear_multiplier = 1.15,
    },
    bison = {
        wear_multiplier = 0.75,
    },
    sadler = {
        wear_multiplier = 0.8,
    },
    mower = {
        wear_multiplier = 1.25,
    },
}
