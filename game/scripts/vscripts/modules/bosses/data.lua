MIN_ITEMS_FROM_BOSS = 6
MAX_ITEMS_FROM_BOSS = 8

DROP_TABLE = {
	["npc_arena_boss_freya"] = {
		hero = "npc_arena_hero_freya",
		{ Item = "item_soul_of_titan", DropChance = 30, DamageWeightPct = 30, },
		{ Item = "item_dark_blade", DropChance = 30, DamageWeightPct = 25, },
		{ Item = "item_demons_paw", DropChance = 90, DamageWeightPct = 30, },
		{ Item = "item_demons_paw", DropChance = 5, DamageWeightPct = 30, },

		{ Item = "item_casket_of_greed", DropChance = 100, DamageWeightPct = 50, },

		{ Item = "item_moon_dust", DropChance = 30, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 5, DamageWeightPct = 25, },

		{ Item = "item_shard_str_extreme", DropChance = 20, },
		{ Item = "item_shard_agi_extreme", DropChance = 20, },
		{ Item = "item_shard_int_extreme", DropChance = 20, },
	},
	["npc_arena_boss_zaken"] = {
		hero = "npc_arena_hero_zaken",
		{ Item = "item_soul_of_titan", DropChance = 30, DamageWeightPct = 30, },
		{ Item = "item_dark_blade", DropChance = 30, DamageWeightPct = 25, },
		{ Item = "item_demons_paw", DropChance = 90, DamageWeightPct = 30, },
		{ Item = "item_demons_paw", DropChance = 5, DamageWeightPct = 30, },

		{ Item = "item_casket_of_greed", DropChance = 100, DamageWeightPct = 50, },

		{ Item = "item_moon_dust", DropChance = 30, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 5, DamageWeightPct = 25, },

		{ Item = "item_shard_str_extreme", DropChance = 20, },
		{ Item = "item_shard_agi_extreme", DropChance = 20, },
		{ Item = "item_shard_int_extreme", DropChance = 20, },
	},
	["npc_arena_boss_cursed_zeld"] = {
		{ Item = "item_dark_blade", DropChance = 50, DamageWeightPct = 25, },
		{ Item = "item_dark_blade", DropChance = 50, DamageWeightPct = 25, },

		{ Item = "item_soul_of_titan", DropChance = 50, DamageWeightPct = 30, },
		{ Item = "item_soul_of_titan", DropChance = 25, DamageWeightPct = 30, },

		{ Item = "item_fallen_star", DropChance = 50, DamageWeightPct = 30, },
		{ Item = "item_fallen_star", DropChance = 25, DamageWeightPct = 30, },

		{ Item = "item_demons_paw", DropChance = 50, DamageWeightPct = 30, },
		{ Item = "item_demons_paw", DropChance = 25, DamageWeightPct = 30, },

		{ Item = "item_casket_of_greed", DropChance = 100, DamageWeightPct = 50, },
		{ Item = "item_casket_of_greed", DropChance = 100, DamageWeightPct = 50, },

		{ Item = "item_shard_str_ultimate", DropChance = 25, },
		{ Item = "item_shard_agi_ultimate", DropChance = 25, },
		{ Item = "item_shard_int_ultimate", DropChance = 25, },

		{ Item = "item_shard_ultimate_small", DropChance = 10 },
		{ Item = "item_shard_ultimate_medium", DropChance = 1 },
	},
	["npc_arena_boss_l1_v1"] = {
		{ Item = "item_dark_blade", DropChance = 20, DamageWeightPct = 25, },
		{ Item = "item_dark_blade", DropChance = 5, DamageWeightPct = 25, },
		{ Item = "item_phantom_bone", DropChance = 20, DamageWeightPct = 20, },

		{ Item = "item_moon_dust", DropChance = 100, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 20, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 5, DamageWeightPct = 25, },

		{ Item = "item_cursed_eye", DropChance = 20, DamageWeightPct = 30, },
		{ Item = "item_fallen_star", DropChance = 25, DamageWeightPct = 30, },
	},
	["npc_arena_boss_l1_v2"] = {
		{ Item = "item_dark_blade", DropChance = 20, DamageWeightPct = 25, },
		{ Item = "item_dark_blade", DropChance = 5, DamageWeightPct = 25, },
		{ Item = "item_phantom_bone", DropChance = 20, DamageWeightPct = 20, },

		{ Item = "item_moon_dust", DropChance = 100, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 20, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 5, DamageWeightPct = 25, },

		{ Item = "item_cursed_eye", DropChance = 20, DamageWeightPct = 20, },
		{ Item = "item_fallen_star", DropChance = 25, DamageWeightPct = 20, },
	},
	["npc_arena_boss_l2_v1"] = {
		{ Item = "item_soul_of_titan", DropChance = 100, DamageWeightPct = 30, },
		{ Item = "item_dark_blade", DropChance = 40, DamageWeightPct = 25, },
		{ Item = "item_phantom_bone", DropChance = 35, DamageWeightPct = 20, },

		{ Item = "item_moon_dust", DropChance = 50, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 25, DamageWeightPct = 25, },

		{ Item = "item_soul_of_titan", DropChance = 10, DamageWeightPct = 30, },
		{ Item = "item_cursed_eye", DropChance = 20, DamageWeightPct = 15, },
		{ Item = "item_fallen_star", DropChance = 25, DamageWeightPct = 15, },

		{ Item = "item_shard_str_large", DropChance = 15, },
		{ Item = "item_shard_agi_large", DropChance = 15, },
		{ Item = "item_shard_int_large", DropChance = 15, },
	},
	["npc_arena_boss_l2_v2"] = {
		{ Item = "item_soul_of_titan", DropChance = 100, DamageWeightPct = 30, },
		{ Item = "item_dark_blade", DropChance = 40, DamageWeightPct = 25, },
		{ Item = "item_phantom_bone", DropChance = 35, DamageWeightPct = 20, },

		{ Item = "item_moon_dust", DropChance = 50, DamageWeightPct = 25, },
		{ Item = "item_moon_dust", DropChance = 25, DamageWeightPct = 25, },

		{ Item = "item_soul_of_titan", DropChance = 10, DamageWeightPct = 30, },
		{ Item = "item_cursed_eye", DropChance = 20, DamageWeightPct = 15, },
		{ Item = "item_fallen_star", DropChance = 25, DamageWeightPct = 15, },

		{ Item = "item_shard_str_large", DropChance = 15, },
		{ Item = "item_shard_agi_large", DropChance = 15, },
		{ Item = "item_shard_int_large", DropChance = 15, },
	},
}
