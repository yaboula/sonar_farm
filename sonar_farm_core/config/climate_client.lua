Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Climate = Config.Farm.Climate or {}

Config.Farm.Climate.WeatherTransitionSeconds = Config.Farm.Climate.WeatherTransitionSeconds or 20
Config.Farm.Climate.WeatherPersistRefreshSeconds = Config.Farm.Climate.WeatherPersistRefreshSeconds or 60
Config.Farm.Climate.NativeWeatherMap = Config.Farm.Climate.NativeWeatherMap or {
    clear = 'EXTRASUNNY',
    light_rain = 'RAIN',
    torrential_rain = 'THUNDER',
    drought = 'CLEAR',
    hail = 'XMAS',
    frost = 'SNOW',
}