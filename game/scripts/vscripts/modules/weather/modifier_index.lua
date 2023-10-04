ModuleRequire(..., "weather_effects")

ModuleLinkLuaModifier(..., "modifier_weather_storm_debuff")
ModuleLinkLuaModifier(..., "modifier_weather_blizzard_debuff")

LinkLuaModifier("modifier_weather_sunny_aura", "modules/weather/modifiers/modifier_weather_sunny", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weather_sunny_aura_normal", "modules/weather/modifiers/modifier_weather_sunny", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_weather_snow_aura", "modules/weather/modifiers/modifier_weather_snow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weather_snow_aura_normal", "modules/weather/modifiers/modifier_weather_snow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weather_blizzard_debuff", "modules/weather/modifiers/modifier_weather_snow", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_weather_rain_aura", "modules/weather/modifiers/modifier_weather_rain", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weather_rain_aura_normal", "modules/weather/modifiers/modifier_weather_rain", LUA_MODIFIER_MOTION_NONE)

for _,v in pairs(WEATHER_EFFECTS) do
	if v.dummyModifier then
		ModuleLinkLuaModifier(..., v.dummyModifier, "modifiers/" .. v.dummyModifier)
	end
end