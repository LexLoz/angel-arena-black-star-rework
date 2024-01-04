REDUCE_CAMPS_START = 20
REDUCE_CAMPS_PER_MIN = 2
CREEPS_IN_CAMP_MIN = 3

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
	-- night_stalker_hunter_in_the_night = true,
	-- chen_holy_persuasion = true,
	-- item_helm_of_the_dominator = true,
	-- doom_bringer_devour_arena = true,
	-- shinobu_eat_oddity = true,
	-- clinkz_death_pact = true,
	-- enchantress_enchant = true,
}

JUNGLE_BANNED_ABILITIES = {
	item_helm_of_the_overlord = true,
	item_helm_of_the_dominator = true,
	-- item_lucifers_claw = true,
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
		[15]    = { 10,         20,         10,         3,          1,          0.3,        15          },
		[20]    = { 15,         30,         15,         4,          2,          0.4,        40          },
		[30]    = { 30,         80,        25,         6,          3,          0.5,        80          },
		[40]    = { 50,         150,        50,         10,         4,          0.6,        2000         },
		[60]    = { 120,        300,        100,        15,         5,          0.7,        5000         },
	},
	medium = {
		[0]     = { 1,          10,         1,          0,          0.0,        0,	         2          },
		[5]     = { 2,          20,         3,          1,          0.4,        0,           3          },
		[10]    = { 3,          30,         6,          2,          0.6,        0.1,         5          },
		[15]    = { 5,          40,         12,         3,          1,          0.2,         10          },
		[20]    = { 10,         75,        18,         4,          2,          0.3,         25          },
		[30]    = { 15,         150,        30,         6,          3,          0.4,         40          },
		[40]    = { 30,         250,        60,         10,         4,          0.5,         1500         },
		[60]    = { 50,         500,        150,        15,         5,          0.6,         3000         },
	},
	hard = {
		[0]     = { 2,          15,         2,          0,          0.0,        0.0,	      2          },
		[5]     = { 4,          30,         4,          1,          0.5,        0.2,          5          },
		[10]    = { 6,          50,         8,          2,          1,          0.3,          10          },
		[15]    = { 12,         60,         15,         3,          1,          0.5,          20          },
		[20]    = { 20,         100,        20,         5,          2,          0.6,          50          },
		[30]    = { 45,         200,        30,         10,         2.5,          0.7,          100          },
		[40]    = { 70,         400,        75,        15,         3,          0.8,          3000         },
		[60]    = { 200,        700,       150,        20,         4,          1.0,          6000         },
	},
}

SPAWNER_SETTINGS = {
	Cooldown = 60,
	easy = {
		SpawnedPerSpawn = 4,
		MaxUnits = 20,
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
		SpawnedPerSpawn = 4,
		MaxUnits = 20,
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
		SpawnedPerSpawn = 4,
		MaxUnits = 20,
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
					--[10] = "models/items/lone_druid/bear/dark_wood_bear_brown/dark_wood_bear_brown.vmdl",
					--[20] = "models/items/lone_druid/bear/dark_wood_bear_white/dark_wood_bear_white.vmdl",
					[20] = "models/items/lone_druid/bear/dark_wood_bear/dark_wood_bear.vmdl",
					--[40] = "models/items/lone_druid/bear/dark_wood_bear_white/dark_wood_bear_white.vmdl",
					[40] = "models/items/lone_druid/bear/spirit_of_anger/spirit_of_anger.vmdl",
					[60] = "models/items/lone_druid/bear/iron_claw_spirit_bear/iron_claw_spirit_bear.vmdl",
				}
			},
		},
		SpawnTypes2 = {
				[0] = "models/creeps/neutral_creeps/n_creep_golem_b/n_creep_golem_b.vmdl",
				[2] = "models/creeps/neutral_creeps/n_creep_golem_a/neutral_creep_golem_a.vmdl",
				[3] = "models/heroes/warlock/warlock_demon.vmdl",
				[4] = "models/items/warlock/archivist_golem/archivist_golem.vmdl",
				[5] = "models/items/warlock/golem/ahmhedoq/ahmhedoq.vmdl",
				[6] = "models/items/warlock/golem/doom_of_ithogoaki/doom_of_ithogoaki.vmdl",
				[7] = "models/items/warlock/golem/greevil_master_greevil_golem/greevil_master_greevil_golem.vmdl",
				[8] = "models/items/warlock/golem/grimoires_pitlord_ultimate/grimoires_pitlord_ultimate.vmdl",
				[9] = "models/items/warlock/golem/hellsworn_golem/hellsworn_golem.vmdl",
				[10] = "models/items/warlock/golem/mdl_warlock_golem/mdl_warlock_golem.vmdl",
				[11] = "models/items/warlock/golem/mystery_of_the_lost_ores_golem/mystery_of_the_lost_ores_golem.vmdl",
				[12] = "models/items/warlock/golem/obsidian_golem/obsidian_golem.vmdl",
				[13] = "models/items/warlock/golem/puppet_summoner_golem/puppet_summoner_golem.vmdl",
				[14] = "models/items/warlock/golem/tevent_2_gatekeeper_golem/tevent_2_gatekeeper_golem.vmdl",
				[15] = "models/items/warlock/golem/the_torchbearer/the_torchbearer.vmdl",
				[16] = "models/items/warlock/golem/ti9_cache_warlock_tribal_warlock_golem/ti9_cache_warlock_tribal_golem_alt.vmdl",
				[17] = "models/items/warlock/golem/ti_8_warlock_darkness_apostate_golem/ti_8_warlock_darkness_apostate_golem.vmdl",
				[18] = "models/items/warlock/golem/warlock_the_infernal_master_golem/warlock_the_infernal_master_golem.vmdl",
				-- [19] = "models/heroes/undying/undying_flesh_golem.vmdl",
				-- [20] = "models/heroes/undying/undying_flesh_golem_rubick.vmdl",
				-- [21] = "models/items/undying/flesh_golem/corrupted_scourge_corpse_hive/corrupted_scourge_corpse_hive.vmdl",
				-- [22] = "models/items/undying/flesh_golem/davy_jones_set_davy_jones_set_kraken/davy_jones_set_davy_jones_set_kraken.vmdl",
				-- [23] = "models/items/undying/flesh_golem/deathmatch_dominator_golem/deathmatch_dominator_golem.vmdl",
				-- [24] = "models/items/undying/flesh_golem/elegy_of_abyssal_samurai_golem/elegy_of_abyssal_samurai_golem.vmdl",
				-- [25] = "models/items/undying/flesh_golem/frostivus_2018_undying_accursed_draugr_golem/frostivus_2018_undying_accursed_draugr_golem.vmdl",
				-- [26] = "models/items/undying/flesh_golem/grim_harvest_golem/grim_harvest_golem.vmdl",
				-- [27] = "models/items/undying/flesh_golem/incurable_pestilence_golem/incurable_pestilence_golem.vmdl",
				-- [28] = "models/items/undying/flesh_golem/spring2021_bristleback_paganism_pope_golem/spring2021_bristleback_paganism_pope_golem.vmdl",
				-- [29] = "models/items/undying/flesh_golem/ti8_undying_miner_flesh_golem/ti8_undying_miner_flesh_golem.vmdl",
				-- [30] = "models/items/undying/flesh_golem/ti9_cache_undying_carnivorous_parasitism_golem/ti9_cache_undying_carnivorous_parasitism_golem.vmdl",
				-- [31] = "models/items/undying/flesh_golem/undying_frankenstein_ability/undying_frankenstein_ability.vmdl",
				-- [32] = "models/items/undying/flesh_golem/watchmen_of_wheat_field_scarecrow/watchmen_of_wheat_field_scarecrow.vmdl",
			}
	},
}
