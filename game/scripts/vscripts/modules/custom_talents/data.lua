CUSTOM_TALENTS_DATA = {
	talent_stats_bonus = {
		icon = "talents/bonus_all_stats",
		cost = 10,
		group = 9,
		max_level = 10,
		special_values = {
			bonus_all_stats = { 3, 6, 9, 12, 15, 18, 21, 24, 27, 30 }
		},
		effect = {
			calculate_stat_bonus = true,
			modifiers = {
				modifier_talent_bonus_all_stats = "bonus_all_stats",
			},
		}
	},
	talent_experience_pct1 = {
		icon = "talents/experience",
		cost = 2,
		group = 1,
		max_level = 1,
		special_values = {
			experience_pct = { 10 }
		},
		effect = {
			unit_keys = {
				bonus_experience_percentage = "experience_pct",
			}
		}
	},
	talent_experience_pct2 = {
		icon = "talents/experience",
		cost = 2,
		group = 2,
		max_level = 1,
		special_values = {
			experience_pct = { 20 }
		},
		effect = {
			unit_keys = {
				bonus_experience_percentage = "experience_pct",
			}
		}
	},
	talent_experience_pct3 = {
		icon = "talents/experience",
		cost = 2,
		group = 3,
		max_level = 1,
		special_values = {
			experience_pct = { 30 }
		},
		effect = {
			unit_keys = {
				bonus_experience_percentage = "experience_pct",
			}
		}
	},
	talent_bonus_creep_gold = {
		icon = "talents/gold10",
		cost = 2,
		group = 1,
		max_level = 1,
		special_values = {
			gold_for_creep = { 10 }
		},
		effect = {
			modifiers = {
				modifier_talent_creep_gold = "gold_for_creep",
			},
		}
	},
	talent_passive_experience_income1 = {
		icon = "talents/experience_per_minute",
		cost = 2,
		group = 1,
		max_level = 1,
		special_values = {
			xp_per_minute = { 1000 }
		},
		effect = {
			unit_keys = {
				bonus_xp_per_minute = "xp_per_minute",
			}
		}
	},
	talent_passive_experience_income2 = {
		icon = "talents/experience_per_minute",
		cost = 2,
		group = 2,
		max_level = 1,
		special_values = {
			xp_per_minute = { 2000 }
		},
		effect = {
			unit_keys = {
				bonus_xp_per_minute = "xp_per_minute",
			}
		}
	},
	talent_passive_experience_income3 = {
		icon = "talents/experience_per_minute",
		cost = 2,
		group = 3,
		max_level = 1,
		special_values = {
			xp_per_minute = { 3000 }
		},
		effect = {
			unit_keys = {
				bonus_xp_per_minute = "xp_per_minute",
			}
		}
	},
	talent_passive_gold_income1 = {
		icon = "talents/gold_per_minute",
		cost = 2,
		group = 1,
		max_level = 1,
		special_values = {
			gold_per_minute = { 150 }
		},
		effect = {
			unit_keys = {
				bonus_gold_per_minute = "gold_per_minute",
			}
		}
	},
	talent_passive_gold_income2 = {
		icon = "talents/gold_per_minute",
		cost = 2,
		group = 2,
		max_level = 1,
		special_values = {
			gold_per_minute = { 300 }
		},
		effect = {
			unit_keys = {
				bonus_gold_per_minute = "gold_per_minute",
			}
		}
	},
	talent_passive_gold_income3 = {
		icon = "talents/gold_per_minute",
		cost = 2,
		group = 3,
		max_level = 1,
		special_values = {
			gold_per_minute = { 450 }
		},
		effect = {
			unit_keys = {
				bonus_gold_per_minute = "gold_per_minute",
			}
		}
	},
	talent_spell_amplify = {
		icon = "talents/spell_amplify",
		cost = 5,
		group = 7,
		max_level = 4,
		special_values = {
			spell_amplify = { 7, 14, 21, 28 }
		},
		effect = {
			use_modifier_applier = true,
			modifiers = {
				modifier_talent_spell_amplify = "spell_amplify",
			},
		}
	},
	talent_respawn_time_reduction = {
		icon = "talents/respawn_time_reduction",
		cost = 10,
		group = 8,
		max_level = 6,
		special_values = {
			respawn_time_reduction = { -15, -30, -45, -60, -75, -90 }
		},
		effect = {
			unit_keys = {
				respawn_time_reduction = "respawn_time_reduction",
			}
		}
	},
	talent_attack_damage = {
		icon = "talents/damage",
		cost = 5,
		group = 7,
		max_level = 4,
		special_values = {
			damage = { 100, 200, 300, 400 }
		},
		effect = {
			modifiers = {
				modifier_talent_damage = "damage",
			},
		}
	},
	--[[talent_evasion = {
		icon = "talents/evasion",
		cost = 4,
		group = 5,
		max_level = 4,
		special_values = {
			evasion = {5, 10, 15, 20}
		},
		effect = {
			modifiers = {
				modifier_talent_evasion = "evasion",
			},
		}
	},]]
	talent_health = {
		icon = "talents/health",
		cost = 10,
		group = 8,
		max_level = 3,
		special_values = {
			health = { 10, 15, 20 }
		},
		effect = {
			calculate_stat_bonus = true,
			modifiers = {
				modifier_talent_health = "health",
			},
		}
	},
	talent_mana = {
		icon = "talents/mana",
		cost = 3,
		group = 4,
		max_level = 3,
		special_values = {
			mana = { 10, 20, 30 }
		},
		effect = {
			calculate_stat_bonus = true,
			modifiers = {
				modifier_talent_mana = "mana",
			},
		}
	},
	talent_health_regen = {
		icon = "talents/health_regen",
		cost = 3,
		group = 5,
		max_level = 3,
		special_values = {
			health_regen = { 15, 30, 45 }
		},
		effect = {
			modifiers = {
				modifier_talent_health_regen = "health_regen",
			},
		}
	},
	talent_mana_regen = {
		icon = "talents/mana_regen",
		cost = 3,
		group = 5,
		max_level = 3,
		special_values = {
			mana_regen = { 4, 8, 12 }
		},
		effect = {
			modifiers = {
				modifier_talent_mana_regen = "mana_regen",
			},
		}
	},
	talent_lifesteal = {
		icon = "talents/lifesteal",
		cost = 10,
		group = 8,
		max_level = 1,
		special_values = {
			lifesteal = { 2 }
		},
		effect = {
			modifiers = {
				modifier_talent_lifesteal = "lifesteal",
			},
		}
	},
	talent_armor = {
		icon = "talents/armor",
		cost = 3,
		group = 6,
		max_level = 3,
		special_values = {
			armor = { 4, 8, 12 }
		},
		effect = {
			modifiers = {
				modifier_talent_armor = "armor",
			},
		}
	},
	talent_magic_resistance_pct = {
		icon = "talents/magic_resistance",
		cost = 3,
		group = 6,
		max_level = 3,
		special_values = {
			magic_resistance_pct = { 10, 15, 20 }
		},
		effect = {
			modifiers = {
				modifier_talent_magic_resistance_pct = "magic_resistance_pct",
			},
		}
	},
	talent_vision_day = {
		icon = "talents/day",
		cost = 3,
		group = 4,
		max_level = 3,
		special_values = {
			vision_day = { 100, 200, 300 }
		},
		effect = {
			modifiers = {
				modifier_talent_vision_day = "vision_day",
			},
		}
	},
	talent_vision_night = {
		icon = "talents/night",
		cost = 3,
		group = 4,
		max_level = 3,
		special_values = {
			vision_night = { 100, 200, 300 }
		},
		effect = {
			modifiers = {
				modifier_talent_vision_night = "vision_night",
			},
		}
	},
	talent_cooldown_reduction_pct = {
		icon = "talents/cooldown_reduction",
		cost = 3,
		group = 5,
		max_level = 3,
		special_values = {
			cooldown_reduction_pct = { 5, 10, 15 }
		},
		effect = {
			modifiers = {
				modifier_talent_cooldown_reduction_pct = "cooldown_reduction_pct",
			},
		}
	},
	talent_movespeed_pct = {
		icon = "talents/movespeed",
		cost = 3,
		group = 4,
		max_level = 3,
		special_values = {
			movespeed_pct = { 10, 15, 20 }
		},
		effect = {
			modifiers = {
				modifier_talent_movespeed_pct = "movespeed_pct",
			},
		}
	},
	talent_true_strike = {
		icon = "talents/true_strike",
		cost = 5,
		group = 7,
		max_level = 4,
		special_values = {
			chance = { 20, 35, 50, 65 }
		},
		effect = {
			modifiers = {
				modifier_talent_true_strike = "chance"
			},
		}
	},

	--Unique
	talent_hero_pudge_hook_splitter = {
		icon = "talents/heroes/pudge_hook_splitter",
		cost = 1,
		group = 9,
		requirement = "pudge_meat_hook_lua",
		special_values = {
			hook_amount = 3
		}
	},
	talent_hero_arthas_vsolyanova_bunus_chance = {
		icon = "talents/heroes/arthas_vsolyanova_bunus_chance",
		cost = 5,
		group = 9,
		max_level = 5,
		requirement = "arthas_vsolyanova",
		special_values = {
			chance_multiplier = { 1.1, 1.2, 1.3, 1.4, 1.5 }
		}
	},
	talent_hero_arc_warden_double_spark = {
		icon = "talents/heroes/arc_warden_double_spark",
		cost = 5,
		group = 9,
		requirement = "arc_warden_spark_wraith",
		effect = {
			multicast_abilities = {
				arc_warden_spark_wraith = 2
			}
		}
	},
	talent_hero_apocalypse_apocalypse_no_death = {
		icon = "talents/heroes/apocalypse_apocalypse_no_death",
		cost = 1,
		group = 9,
		requirement = "apocalypse_apocalypse",
	},
	talent_hero_sai_release_of_forge_unlimited_attack_range = {
		icon = "arena/sai_release_of_forge",
		cost = 300,
		group = 9,
		max_level = 1,
		requirement = "sai_release_of_forge",
	},
	talent_hero_sai_release_of_forge_enemy_heroes_vision = {
		icon = "arena/sai_release_of_forge",
		cost = 300,
		group = 9,
		max_level = 1,
		requirement = "sai_release_of_forge",
	},
	talent_hero_comic_sans_karma_aura = {
		icon = "arena/sans_curse",
		cost = 20,
		group = 10,
		max_level = 1,
		requirement = "sans_curse",
		effect = {
			callback = function(hero, data)
				hero:SetNetworkableEntityInfo('HasKarmaTalent', 1)
			end
		}
	},
	--[[talent_hero_sai_release_of_forge_bonus_respawn_time_reduction = {
		icon = "arena/sai_release_of_forge",
		cost = 10,
		group = 8,
		max_level = 4,
		requirement = "sai_release_of_forge",
		special_values = {
			reduction_pct = {25, 50, 75, 100}
		}
	},]]

	--[[talent_hero_sara_evolution_bonus_health = {
		icon = "talents/heroes/sara_evolution_bonus_health",
		cost = 4,
		group = 2,
		max_level = 8,
		special_values = {
			health = {300, 600, 900, 1200, 1500, 1800, 2100, 2400}
		},
		effect = {
			calculate_stat_bonus = true,
			special_values_multiplier = 1 / (1 - GetAbilitySpecial("sara_evolution", "health_reduction_pct") * 0.01),
			modifiers = {
				modifier_talent_health = "health",
			},
		}
	},]]
	--Tinker - Rearm = Purge
}

-- A list of heroes, which have Changed flag, but some native talents for them are still relevant
-- Value should be a table, where irrelevant talents should have a `true` value
PARTIALLY_CHANGED_HEROES = {
	npc_dota_hero_ogre_magi = {},
	npc_dota_hero_huskar = {
		special_bonus_unique_huskar_2 = true,
		special_bonus_unique_huskar_5 = true
	},
	npc_dota_hero_doom_bringer = {
		special_bonus_unique_doom_2 = true,
		special_bonus_unique_doom_3 = true,
	},
}

NATIVE_TALENTS = {
}

table.merge(CUSTOM_TALENTS_DATA, ModuleRequire(..., "native"))

TALENT_GROUP_TO_LEVEL = {
	[1] = 10,
	[2] = 15,
	[3] = 20,
	[4] = 25,
	[5] = 30,
	[6] = 35,
	[7] = 40,
	[8] = 45,
	[9] = 50,
	[10] = 55,
	[11] = 60,
	[12] = 65,
	[13] = 70,
	[14] = 75,
	[15] = 80,
	[18] = 140,
	[19] = 180,
	[20] = 245,
	[21] = 300,
	[22] = 340,
	[23] = 360,
	[24] = 380,
	[25] = 400,
	[26] = 430,
	[27] = 460,
	[28] = 490,
	[29] = 550,
}
-- [1] = 10, exp;gold_creep;
-- [2] = 15, mana;regen;gold_min;exp_min;
-- [3] = 20, armor;mag_resist;
-- [4] = 25, movespeed;spell_amp;
-- [5] = 30, cd;evasion;
-- [6] = 35, ms_limit;
-- [7] = 40, day;night;
-- [8] = 45, respawn_time;
-- [9] = 50, damage;
-- [10] = 55, truestrike
