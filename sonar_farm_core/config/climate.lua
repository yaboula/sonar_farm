Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Climate = Config.Farm.Climate or {}

Config.Farm.Climate.EnableWeatherSync = true
Config.Farm.Climate.DefaultSeason = 'spring'
Config.Farm.Climate.DefaultWeather = 'clear'
Config.Farm.Climate.SeasonOrder = { 'spring', 'summer', 'autumn', 'winter' }
Config.Farm.Climate.WeatherEvaluationSeconds = 60
Config.Farm.Climate.PlotEffectIntervalSeconds = 60

Config.Farm.Climate.WeatherFactor = {
    SeasonWeight = 0.6,
    WeatherWeight = 0.4,
    OptimalSeasonScore = 100,
    ShoulderSeasonScore = 70,
    OffSeasonScore = 35,
}

Config.Farm.Climate.WeatherEffects = {
    clear = {
        irrigation_delta = 0,
        irrigation_floor = 0,
        irrigation_ceiling = 100,
    },
    light_rain = {
        irrigation_delta = 8,
        irrigation_floor = 0,
        irrigation_ceiling = 95,
    },
    torrential_rain = {
        irrigation_delta = -12,
        irrigation_floor = 40,
        irrigation_ceiling = 100,
    },
    drought = {
        irrigation_delta = -10,
        irrigation_floor = 25,
        irrigation_ceiling = 100,
    },
    hail = {
        irrigation_delta = -15,
        irrigation_floor = 20,
        irrigation_ceiling = 100,
    },
    frost = {
        irrigation_delta = -6,
        irrigation_floor = 30,
        irrigation_ceiling = 100,
    },
}

Config.Farm.Climate.Seasons = {
    spring = {
        duration_seconds = 86400,
        weather_probabilities = {
            clear = 0.28,
            light_rain = 0.34,
            torrential_rain = 0.10,
            drought = 0.06,
            hail = 0.10,
            frost = 0.12,
        },
    },
    summer = {
        duration_seconds = 86400,
        weather_probabilities = {
            clear = 0.42,
            light_rain = 0.18,
            torrential_rain = 0.08,
            drought = 0.20,
            hail = 0.07,
            frost = 0.05,
        },
    },
    autumn = {
        duration_seconds = 86400,
        weather_probabilities = {
            clear = 0.25,
            light_rain = 0.32,
            torrential_rain = 0.12,
            drought = 0.08,
            hail = 0.08,
            frost = 0.15,
        },
    },
    winter = {
        duration_seconds = 86400,
        weather_probabilities = {
            clear = 0.20,
            light_rain = 0.18,
            torrential_rain = 0.10,
            drought = 0.02,
            hail = 0.15,
            frost = 0.35,
        },
    },
}
