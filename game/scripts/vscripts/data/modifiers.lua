MODIFIERS_DEATH_PREVENTING = {
	"modifier_invulnerable",
	"modifier_dazzle_shallow_grave",
	"modifier_abaddon_aphotic_shield",
	"modifier_abaddon_borrowed_time",
	"modifier_nyx_assassin_spiked_carapace",
	"modifier_troll_warlord_battle_trance",
	"modifier_skeleton_king_reincarnation_scepter_active",
	"modifier_monkey_king_transform",
	"modifier_oracle_false_promise",
	"modifier_templar_assassin_refraction_absorb",
	"modifier_winter_wyvern_winters_curse_aura",
	"modifier_winter_wyvern_winters_curse",

	"modifier_item_titanium_bar_active",
	"modifier_fountain_aura_arena",
	"modifier_mana_shield_arena",
	"modifier_saber_avalon_invulnerability",
	"modifier_sans_ketchup",
}

DUEL_PURGED_MODIFIERS = {
	"modifier_life_stealer_infest",
	"modifier_tether_ally_aghanims",
	"modifier_life_stealer_assimilate",
	"modifier_life_stealer_assimilate_effect",
	"modifier_item_black_king_bar_arena_active",
	"modifier_item_titanium_bar_active",
}

MODIFIERS_TRUESIGHT = {
	"modifier_item_dustofappearance",
	"modifier_bounty_hunter_track",
	"modifier_slardar_amplify_damage",
}

ONCLICK_PURGABLE_MODIFIERS = {
	"modifier_doppelganger_mimic",
	"modifier_tether_ally_aghanims",
	"modifier_universal_attribute"
}

UNDESTROYABLE_MODIFIERS = {
	modifier_razor_static_link_debuff = true,
}

COOLDOWN_REDUCTION_MODIFIERS = {
	modifier_octarine_unique_cooldown_reduction = function(unit)
		return GetAbilitySpecial(
			unit:HasModifier("modifier_item_refresher_core") and "item_refresher_core" or "item_octarine_core_arena",
			"bonus_cooldown_pct")
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
	desolator = {
		modifier_item_desolator2_arena = 1,
		modifier_item_desolator3_arena = 2,
		modifier_item_desolator4_arena = 3,
		modifier_item_desolator5_arena = 4,
		modifier_item_desolator6_arena = 5,
	},
	pure_damage = {
		modifier_item_piercing_blade = 1,
		modifier_item_soulcutter = 2,
	},
}


REGEN_EXEPTIONS = {
	{ "modifier_item_phantom_bone",                "bonus_hp_regen_pct" },
	{ "modifier_item_heart_cyclone_regen",         "health_regen_percent_per_second" },
	{ "modifier_item_heart_cyclone_active_regen",  "active_health_regen_percent_per_second" },
	{ "modifier_item_heavy_war_axe_of_rage_regen", "health_regen_percent_per_second" },
	{ "modifier_item_demonic_cuirass_ally_aura",   "aura_bonus_hp_regen_pct" },
	{ "modifier_item_lotus_sphere",                "bonus_hp_regen_pct" },
	{ "modifier_arthas_vikared",                   "health_regen_percent" },
	{ "modifier_huskar_berserkers_blood",          "maximum_health_regen" },
	{ "modifier_juggernaut_healing_ward_heal",     "healing_ward_heal_amount" },
	{ "modifier_filler_heal",                      "hp_heal_pct" },
	{ "modifier_wisp_overcharge",				   "hp_regen"}
}

DAMAGE_REFLECT_MODIFIERS = {
	["modifier_freya_pain_reflection"] = "freya_pain_reflection",
	["modifier_item_blade_mail_arena_active"] = "item_blade_mail_arena",
	["modifier_item_sacred_blade_mail_active"] = "item_sacred_blade_mail",
}

RELIABLE_DAMAGE_MODIFIERS = {
	item_desolator4 = true,
	item_desolator5 = true,
	item_desolator6 = true,

	item_soulcutter = true,
	item_demon_king_bar = true,
	item_bloodthorn_2 = true,
	item_ultimate_splash = true,
	item_radiance_frozen = true,
	item_demonic_cuirass = true,
	item_sacred_blade_mail = true,
	item_titanium_bar = true,
}

BAT_DECREASE_MODIFIERS = {
	modifier_alchemist_chemical_rage = true,
	modifier_broodmother_insatiable_hunger = true,
	modifier_terrorblade_metamorphosis = true,
	modifier_troll_warlord_berserkers_rage = true,
	modifier_snapfire_lil_shredder_buff = true,
	modifier_lone_druid_true_form = true,
}
