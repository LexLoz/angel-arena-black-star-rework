MODIFIERS_DEATH_PREVENTING = {
	"modifier_invulnerable",
	"modifier_dazzle_shallow_grave",
	"modifier_abaddon_aphotic_shield",
	"modifier_abaddon_borrowed_time",
	"modifier_nyx_assassin_spiked_carapace",
	"modifier_crystal_maiden_glacier_tranqulity_buff",
	"modifier_skeleton_king_reincarnation_life_saver",
	"modifier_skeleton_king_reincarnation_ally",
	"modifier_item_aegis_arena",
	"modifier_item_aegis_arena_reincarnation",
	"modifier_item_aegis_arena_life_saver",
	"modifier_item_titanium_bar_active",
	"modifier_fountain_aura_arena",
	"modifier_mana_shield_arena",
	"modifier_saber_avalon_invulnerability",
	"modifier_fountain_aura_invulnerability"
}

DUEL_PURGED_MODIFIERS = {
	"modifier_life_stealer_infest",
	"modifier_pocket_riki_hide",
	"modifier_tether_ally_aghanims",
	"modifier_life_stealer_assimilate",
	"modifier_life_stealer_assimilate_effect",
	"modifier_item_black_king_bar_arena_active",
	"modifier_item_titanium_bar_active"
}

ABILITY_INVULNERABLE_UNITS = {
	"npc_dota_casino_slotmachine",
}

MODIFIERS_TRUESIGHT = {
	"modifier_item_dustofappearance",
	"modifier_bounty_hunter_track",
	"modifier_slardar_amplify_damage",
}

ONCLICK_PURGABLE_MODIFIERS = {
	"modifier_rubick_personality_steal",
	"modifier_tether_ally_aghanims"
}

COOLDOWN_REDUCTION_MODIFIERS = {
	modifier_octarine_unique_cooldown_reduction = function(unit)
		return GetAbilitySpecial(unit:HasModifier("modifier_item_refresher_core") and "item_refresher_core" or "item_octarine_core_arena", "bonus_cooldown_pct")
	end,
	--TODO Make it work without that table, rewrite modifier_octarine_unique_cooldown_reduction in modifier_lua
	modifier_arena_rune_arcane = function(unit)
		return unit:FindModifierByName("modifier_arena_rune_arcane"):GetModifierPercentageCooldown()
	end,
	modifier_talent_cooldown_reduction_pct = function(unit)
		return unit:FindModifierByName("modifier_talent_cooldown_reduction_pct"):GetModifierPercentageCooldown()
	end
}

ATTACK_MODIFIERS = {
	{
		modifier = "modifier_item_skadi_arena",
		projectile = "particles/items2_fx/skadi_projectile.vpcf",
	},
	{
		modifier = "modifier_item_skadi_2",
		projectile = "particles/items2_fx/skadi_projectile.vpcf",
	},
	{
		modifier = "modifier_item_desolator2_arena",
		projectile = "particles/arena/items_fx/desolator2_projectile.vpcf",
	},
	{
		modifier = "modifier_item_skadi_4",
		projectile = "particles/items2_fx/skadi_projectile.vpcf",
	},
	{
		modifier = "modifier_item_desolator3_arena",
		projectile = "particles/arena/items_fx/desolator2_projectile.vpcf",
	},
	{
		modifier = "modifier_item_skadi_8",
		projectile = "particles/items2_fx/skadi_projectile.vpcf",
	},
	{
		modifier = "modifier_item_golden_eagle_relic_unique",
		projectile = "particles/arena/items_fx/golden_eagle_relic_projectile.vpcf",
	},
	{
		modifier = "modifier_item_desolator4_arena",
		projectile = "particles/arena/items_fx/desolator4_projectile.vpcf",
	},
	{
		modifier = "modifier_item_desolator5_arena",
		projectile = "particles/arena/items_fx/desolator5_projectile.vpcf",
	},
	{
		modifier = "modifier_item_desolator6_arena",
		projectile = "particles/arena/items_fx/desolator6_projectile.vpcf",
	},
	--[[{
		modifiers = {
			""
			"modifier_item_desolator6_arena",
		},
		projectile = "particles/arena/items_fx/desolator6_projectile.vpcf",
	}]]
}

MODIFIER_PROC_PRIORITY = {
	nightshadow = {
		modifier_item_nightshadow_unique = 1,
		modifier_item_nightshadow_and_sange = 2,
		modifier_item_nightshadow_and_yasha_unique = 3,
		modifier_item_splitshot_int_unique = 4,
		modifier_item_three_spirits_blades_unique = 5,
		modifier_item_splitshot_ultimate_unique = 6,
		modifier_item_elemental_fury_unique = 7,
	},
	yasha = {
		modifier_item_yasha_arena_unique = 1,
		modifier_item_sange_and_yasha_unique = 2,
		modifier_item_nightshadow_and_yasha_unique = 3,
		modifier_item_splitshot_agi_unique = 4,
		modifier_item_manta_arena_unique = 5,
		modifier_item_three_spirits_blades_unique = 6,
		modifier_item_diffusal_style_unique = 7,
		modifier_item_splitshot_ultimate_unique = 8,
		modifier_item_elemental_fury_unique = 9,
	},
	sange = {
		modifier_item_sange_arena_unique = 1,
		modifier_item_sange_and_yasha_unique = 2,
		modifier_item_nightshadow_and_sange = 3,
		modifier_item_heavens_halberd_arena_unique = 4,
		modifier_item_splitshot_str_unique = 5,
		modifier_item_three_spirits_blades_unique = 6,
		modifier_item_splitshot_ultimate_unique = 7,
		modifier_item_elemental_fury_unique = 8,
	},
	desolator = {
		modifier_item_desolator2_arena = 1,
		modifier_item_desolator3_arena = 2,
		modifier_item_desolator4_arena = 3,
		modifier_item_desolator5_arena = 4,
		modifier_item_desolator6_arena = 5,
	}
}
