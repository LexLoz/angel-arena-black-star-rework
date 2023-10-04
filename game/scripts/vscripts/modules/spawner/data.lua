SPAWNER_CHAMPION_LEVELS = {
	[1] = {
		chance = 1,
		minute = 5,
		model_scale = 0.3,
	},
	[2] = {
		chance = 1,
		minute = 10,
		model_scale = 0.35,
	},
	[3] = {
		chance = 1,
		minute = 15,
		model_scale = 0.4,
	},
	[4] = {
		chance = 1,
		minute = 20,
		model_scale = 0.45,
	},
	[5] = {
		chance = 1,
		minute = 25,
		model_scale = 0.5,
	},
	-- [15] = {
	-- 	chance = 1,
	-- 	minute = 30,
	-- 	model_scale = 1,
	-- }
	
}

CHAMPIONS_BANNED_ABILITIES = {
	night_stalker_hunter_in_the_night = true,
	chen_holy_persuasion = true,
	item_helm_of_the_dominator = true,
	doom_bringer_devour_arena = true,
	shinobu_eat_oddity = true,
	clinkz_death_pact = true,
	enchantress_enchant = true,
}

JUNGLE_BANNED_ABILITIES = {
	item_helm_of_the_overlord = true,
	item_helm_of_the_dominator = true,
	item_lucifers_claw = true,
	item_hand_of_midas_arena = true,
	item_hand_of_midas_2_arena = true,
	item_hand_of_midas_3_arena = true,
	item_blink_staff = true,
	item_force_staff = true,
	item_hurricane_pike = true,

	chen_holy_persuasion = true,
	doom_bringer_devour_arena = true,
	shinobu_eat_oddity = true,
	clinkz_death_pact = true,
	enchantress_enchant = true,
	earth_spirit_boulder_smash = true,
	batrider_flaming_lasso = true,
	tusk_walrus_kick = true,
	vengefulspirit_nether_swap = true,
	life_stealer_infest = true,
	night_stalker_hunter_in_the_night = true,
}

CREEP_UPGRADE_FUNCTIONS = {
			   --[[ goldbounty  hp          damage      attackspeed movespeed   armor       xpbounty    ]]--
	easy = {
		[0]     = { 1,          5,          1,          0,          0.0,        0,	        3          },
		[5]     = { 4,          10,         2,          1,          0.5,        0.1,        5          },
		[10]    = { 6,          15,         5,          2,          1,          0.2,        8          },
		[15]    = { 10,         25,         10,         3,          1,          0.3,        15          },
		[20]    = { 15,         50,         15,         4,          2,          0.4,        40          },
		[30]    = { 30,         100,        30,         8,          3,          0.5,        80          },
		[40]    = { 50,         250,        50,         12,         4,          0.6,        2000         },
		[60]    = { 120,        500,        100,        24,         5,          0.7,        5000         },
	},
	medium = {
		[0]     = { 1,          10,         1,          0,          0.0,        0,	         2          },
		[5]     = { 2,          20,         3,          1,          0.4,        0,           3          },
		[10]    = { 3,          30,         6,          2,          0.6,        0.1,         5          },
		[15]    = { 5,          40,         12,         3,          1,          0.2,         10          },
		[20]    = { 10,         100,        18,         4,          2,          0.3,         25          },
		[30]    = { 15,         175,        35,         8,          3,          0.4,         40          },
		[40]    = { 30,         400,        60,         12,         4,          0.5,         1500         },
		[60]    = { 50,         750,        150,        24,         5,          0.6,         3000         },
	},
	hard = {
		[0]     = { 2,          15,         2,          0,          0.0,        0.0,	      2          },
		[5]     = { 4,          30,         4,          1,          0.5,        0.2,          5          },
		[10]    = { 6,          50,         8,          2,          1,          0.3,          10          },
		[15]    = { 12,         60,         15,         3,          1,          0.5,          20          },
		[20]    = { 20,         150,        20,         5,          2,          0.6,          50          },
		[30]    = { 45,         350,        40,         10,         3,          0.7,          100          },
		[40]    = { 70,         650,        100,        15,         4,          0.8,          3000         },
		[60]    = { 200,        1000,       200,        30,         5,          1.0,          6000         },
	},
}

SPAWNER_SETTINGS = {
	Cooldown = 60,
	easy = {
		SpawnedPerSpawn = 3,
		MaxUnits = 21,
		SpawnTypes = {
			[0] ={
				{
					[-1] = "npc_dota_neutral_easy_variant1",
					[0] = "models/items/broodmother/spiderling/virulent_matriarchs_spiderling/virulent_matriarchs_spiderling.vmdl",
					[10] = "models/heroes/broodmother/spiderling.vmdl",
					[20] = "models/items/broodmother/spiderling/amber_queen_spiderling_2/amber_queen_spiderling_2.vmdl",
					[30] = "models/items/broodmother/spiderling/araknarok_broodmother_araknarok_spiderling/araknarok_broodmother_araknarok_spiderling.vmdl",
					[40] = "models/items/broodmother/spiderling/spiderling_dlotus_red/spiderling_dlotus_red.vmdl",
					[50] = "models/items/broodmother/spiderling/thistle_crawler/thistle_crawler.vmdl",
					[60] = "models/items/broodmother/spiderling/perceptive_spiderling/perceptive_spiderling.vmdl",
				}
			},
		},
	},
	medium = {
		SpawnedPerSpawn = 3,
		MaxUnits = 21,
		SpawnTypes = {
			[0] ={
				{
					[-1] = "npc_dota_neutral_medium_variant1",
					[0] = "models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_skeleton_melee.vmdl",
					[30] = "models/creeps/neutral_creeps/n_creep_ghost_a/n_creep_ghost_a.vmdl",
					[60] = "models/creeps/lane_creeps/creep_bad_melee_diretide/creep_bad_melee_diretide.vmdl",
				}
			},
			[1] ={
				{
					[-1] = "npc_dota_neutral_medium_variant1",
					[0] = "models/creeps/neutral_creeps/n_creep_beast/n_creep_beast.vmdl",
					[30] = "models/creeps/neutral_creeps/n_creep_furbolg/n_creep_furbolg_disrupter.vmdl",
					[60] = "models/heroes/ursa/ursa.vmdl",
				}
			},
			[2] ={
				{
					[-1] = "npc_dota_neutral_medium_variant1",
					[0] = "models/creeps/neutral_creeps/n_creep_satyr_b/n_creep_satyr_b.vmdl",
					--[10] = "models/items/lone_druid/bear/dark_wood_bear_brown/dark_wood_bear_brown.vmdl",
					--[20] = "models/items/lone_druid/bear/dark_wood_bear_white/dark_wood_bear_white.vmdl",
					[20] = "models/creeps/neutral_creeps/n_creep_satyr_c/n_creep_satyr_c.vmdl",
					--[40] = "models/items/lone_druid/bear/dark_wood_bear_white/dark_wood_bear_white.vmdl",
					[40] = "models/creeps/neutral_creeps/n_creep_satyr_a/n_creep_satyr_a.vmdl",
					[60] = "models/creeps/neutral_creeps/n_creep_satyr_spawn_a/n_creep_satyr_spawn_a.vmdl",
				}
			},
			[3] ={
				{
					[-1] = "npc_dota_neutral_medium_variant1",
					[0] = "models/items/beastmaster/boar/fotw_wolf/fotw_wolf.vmdl",
					[25] = "models/heroes/lycan/summon_wolves.vmdl",
					[40] = "models/items/lycan/wolves/blood_moon_hunter_wolves/blood_moon_hunter_wolves.vmdl",
					[60] = "models/items/lycan/ultimate/thegreatcalamityti4/thegreatcalamityti4.vmdl",

				}
			},
			--[[[4] ={
				{
					[-1] = "npc_dota_neutral_medium_variant1",
					[0] = "models/creeps/neutral_creeps/n_creep_centaur_lrg/n_creep_centaur_lrg.vmdl",
				}
			},]]
		},
	},
	hard = {
		SpawnedPerSpawn = 3,
		MaxUnits = 21,
		SpawnTypes = {
			[0] ={
				{
					[-1] = "npc_dota_neutral_hard_variant1",
					[0] = "models/creeps/neutral_creeps/n_creep_jungle_stalker/n_creep_gargoyle_jungle_stalker.vmdl",
					[10] = "models/creeps/neutral_creeps/n_creep_black_drake/n_creep_black_drake.vmdl",
					[20] = "models/creeps/neutral_creeps/n_creep_black_dragon/n_creep_black_dragon.vmdl",
					[30] = "models/items/dragon_knight/dragon_immortal_1/dragon_immortal_1.vmdl",
					[40] = "models/items/dragon_knight/fireborn_dragon/fireborn_dragon.vmdl",
					[50] = "models/heroes/dragon_knight/dragon_knight_dragon.vmdl",
					--[60] = "models/heroes/twin_headed_dragon/twin_headed_dragon.vmdl",
				}

			},
			[1] ={
				{
					[-1] = "npc_dota_neutral_hard_variant2",
					[0] = "models/creeps/neutral_creeps/n_creep_centaur_med/n_creep_centaur_med.vmdl",
					[30] = "models/creeps/neutral_creeps/n_creep_centaur_lrg/n_creep_centaur_lrg.vmdl",
					[60] = "models/heroes/centaur/centaur.vmdl",
				}
			},
			[2] ={
				{
					[-1] = "npc_dota_neutral_hard_variant3",
					[0] = "models/heroes/tiny/tiny_01/tiny_01.vmdl",
					[15] = "models/heroes/tiny/tiny_02/tiny_02.vmdl",
					[30] = "models/heroes/tiny/tiny_03/tiny_03.vmdl",
					[45] = "models/heroes/tiny/tiny_04/tiny_04.vmdl",
					[60] = "models/items/tiny/scarlet_quarry/scarlet_quarry_04.vmdl",
				}
			},
		},
	},
	jungle = {
		SpawnedPerSpawn = 3,
		SpawnTypes = {
			[0] ={
				{
					[-1] = "npc_dota_neutral_jungle_variant1",
					[0] = "models/heroes/lone_druid/spirit_bear.vmdl",
					[200] = "models/items/lone_druid/bear/dark_wood_bear_brown/dark_wood_bear_brown.vmdl",
					[400] = "models/items/lone_druid/bear/dark_wood_bear_white/dark_wood_bear_white.vmdl",
					[600] = "models/items/lone_druid/bear/dark_wood_bear/dark_wood_bear.vmdl",
					[800] = "models/items/lone_druid/bear/dark_wood_bear_white/dark_wood_bear_white.vmdl",
					[1000] = "models/items/lone_druid/bear/spirit_of_anger/spirit_of_anger.vmdl",
					[1200] = "models/items/lone_druid/bear/iron_claw_spirit_bear/iron_claw_spirit_bear.vmdl",
				}
			},
		},
	},
}
