local modifiers = {
	"damage",
	--"evasion",
	"movespeed_pct",
	"lifesteal",
	"creep_gold",
	"health",
	"health_regen",
	"armor",
	"magic_resistance_pct",
	"vision_day",
	"vision_night",
	"cooldown_reduction_pct",
	"true_strike",
	"mana",
	"mana_regen",
	"lifesteal",
	"bonus_all_stats",
	--rune multiplier
}

for _,v in pairs(modifiers) do
	ModuleLinkLuaModifier(..., "modifier_talent_" .. v, "modifiers/modifier_talent_" .. v)
end