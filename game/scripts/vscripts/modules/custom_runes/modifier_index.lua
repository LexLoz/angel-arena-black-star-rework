local modifiers = {
	"tripledamage",
	"haste",
	"invisibility",
	"arcane",
	"flame",
	"acceleration",
	"vibration",
	"spikes",
	"soul_steal",
	soul_steal_effect = "soul_steal"
}
for k,v in pairs(modifiers) do
	if type(k) == "string" then
		k, v = v, k
	else
		k = nil
	end
	ModuleLinkLuaModifier(..., "modifier_arena_rune_" .. v, "modifiers/modifier_arena_rune_" .. (k or v))
end