HEROES_ON_DUEL = HEROES_ON_DUEL or {}
PLAYER_DATA = PLAYER_DATA or
{ [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {}, [9] = {}, [10] = {}, [11] = {},
	[12] = {}, [13] = {}, [14] = {}, [15] = {}, [16] = {}, [17] = {}, [18] = {}, [19] = {}, [20] = {}, [21] = {}, [22] = {},
	[23] = {} }
RANDOM_OMG_PRECACHED_HEROES = RANDOM_OMG_PRECACHED_HEROES or {}

local mapName = GetMapName()
local underscoreIndex = mapName:find("_")
local landscape = underscoreIndex and mapName:sub(1, underscoreIndex - 1) or mapName
local gamemode = underscoreIndex and mapName:sub(underscoreIndex - #mapName) or ""
local IsCustomAbilities = gamemode == "custom_abilities"

MAX_HERO_LEVEL = IsCustomAbilities and 5000 or 600

XP_PER_LEVEL_TABLE = { 0 }
for i = 2, MAX_HERO_LEVEL do
	XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 100
end


STAMINA_HEROES_CONSUMPTION_EXEPTIONS = {
	npc_arena_hero_saitama = 0,
	npc_arena_hero_shinobu = 33,
	npc_arena_hero_sans = 200,
	--npc_dota_hero_life_stealer = true,
	npc_dota_hero_tiny = 0,
	npc_dota_hero_sniper = 40,
	npc_dota_hero_gyrocopter = 30,
	npc_dota_lone_druid_bear = 0,
}

BLACK_LIST = {
	['76561198103444247'] = true,
	['76561199385670262'] = true,
	['76561198241374538'] = true,
}
