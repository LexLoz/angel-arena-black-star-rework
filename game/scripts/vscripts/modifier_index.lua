require("modules/modifier_index")

local modifiers = {
	modifier_apocalypse_apocalypse = "heroes/hero_apocalypse/modifier_apocalypse_apocalypse",
	modifier_saitama_limiter = "heroes/hero_saitama/modifier_saitama_limiter",
	modifier_set_attack_range = "modifiers/modifier_set_attack_range",
	modifier_charges = "modifiers/modifier_charges",
	modifier_hero_selection_transformation = "modifiers/modifier_hero_selection_transformation",
	modifier_max_attack_range = "modifiers/modifier_max_attack_range",
	modifier_item_demon_king_bar_curse = "items/modifier_item_demon_king_bar_curse",
	modifier_hero_out_of_game = "modifiers/modifier_hero_out_of_game",
	modifier_summons_upgrade = "modifiers/modifier_summons_upgrade",
	-- modifier_arena_util = "modifiers/modifier_arena_util",

	modifier_splash_timer = "modifiers/modifier_splash_timer",

	modifier_arena_duel_vision = "modifiers/modifier_arena_duel_vision",

	modifier_arena_hero = "modifiers/modifier_arena_hero",
	modifier_arena_hero_health_regen = "modifiers/modifier_arena_hero",
	modifier_arena_hero_mana_regen = "modifiers/modifier_arena_hero",
	modifier_arena_hero_max_mana = "modifiers/modifier_arena_hero",
	modifier_arena_hero_current_mana = "modifiers/modifier_arena_hero",
	modifier_arena_hero_gold = "modifiers/modifier_arena_hero",

	modifier_stamina = "modifiers/attributes/modifier_stamina",
	modifier_strength_crit = "modifiers/attributes/modifier_strength_crit",
	modifier_intelligence_primary_bonus = "modifiers/attributes/modifier_intelligence_primary_bonus",

	modifier_agility_bonus_attacks = "modifiers/attributes/modifier_agility_primary_bonus/modifier_agility_bonus_attacks",
	modifier_agility_primary_bonus = "modifiers/attributes/modifier_agility_primary_bonus/modifier_agility_primary_bonus",

	modifier_universal_attribute = "modifiers/attributes/modifier_universal_attribute",


	--modifier_item_shard_attackspeed_stack = "modifiers/modifier_item_shard_attackspeed_stack",
}

for k,v in pairs(modifiers) do
	LinkLuaModifier(k, v, LUA_MODIFIER_MOTION_NONE)
end