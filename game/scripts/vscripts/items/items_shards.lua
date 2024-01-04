item_shard_baseclass = {}
if IsServer() then
	function item_shard_baseclass:OnSpellStart()
		local caster = self:GetCaster()
		if self and self:GetSpecialValueFor("strength") > 0 then
			local value = self:GetSpecialValueFor("strength")
			caster:ModifyStrength(value)
			caster.Additional_str = (caster.Additional_str or 0) + value
		end
		if self and self:GetSpecialValueFor("agility") > 0 then
			local value = self:GetSpecialValueFor("agility")
			caster:ModifyAgility(value)
			caster.Additional_agi = (caster.Additional_agi or 0) + value
		end
		if self and self:GetSpecialValueFor("intelligence") > 0 then
			local value = self:GetSpecialValueFor("intelligence")
			caster:ModifyIntellect(value)
			caster.Additional_int = (caster.Additional_int or 0) + value
		end
		if self and self:GetSpecialValueFor("stats") > 0 then
			local value = self:GetSpecialValueFor("stats")
			caster:ModifyStrength(value)
			caster:ModifyAgility(value)
			caster:ModifyIntellect(value)
			caster.Additional_str = (caster.Additional_str or 0) + value
			caster.Additional_agi = (caster.Additional_agi or 0) + value
			caster.Additional_int = (caster.Additional_int or 0) + value
		end
		if self and self:GetSpecialValueFor("levels") > 0 then
			local level = caster:GetLevel()
			local value = self:GetSpecialValueFor("levels")
			local newLevel = math.min(level + value, #XP_PER_LEVEL_TABLE)
			caster:AddExperience(XP_PER_LEVEL_TABLE[newLevel] - XP_PER_LEVEL_TABLE[level], 0, false, false)
		end
		-- print(GetOneRemainingTeam())
		if self and self:GetAbilityName() == "item_end_shard" and GetOneRemainingTeam() then
			GameMode:OnOneTeamLeft(GetOneRemainingTeam())
		elseif self and self:GetAbilityName() == "item_end_shard" and not GetOneRemainingTeam() then
			Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_end_shard")
			return
		end
		-- Attributes:UpdateAll(caster, 1)
		self:SpendCharge()
	end
end
item_shard_str_baseclass = class(item_shard_baseclass)

item_shard_str_small = item_shard_str_baseclass
item_shard_str_medium = item_shard_str_baseclass
item_shard_str_large = item_shard_str_baseclass
item_shard_str_extreme = item_shard_str_baseclass
item_shard_str_ultimate = item_shard_str_baseclass

item_shard_agi_baseclass = class(item_shard_baseclass)

item_shard_agi_small = item_shard_agi_baseclass
item_shard_agi_medium = item_shard_agi_baseclass
item_shard_agi_large = item_shard_agi_baseclass
item_shard_agi_extreme = item_shard_agi_baseclass
item_shard_agi_ultimate = item_shard_agi_baseclass

item_shard_int_baseclass = class(item_shard_baseclass)

item_shard_int_small = item_shard_int_baseclass
item_shard_int_medium = item_shard_int_baseclass
item_shard_int_large = item_shard_int_baseclass
item_shard_int_extreme = item_shard_int_baseclass
item_shard_int_ultimate = item_shard_int_baseclass

item_shard_ultimate_baseclass = class(item_shard_baseclass)
item_shard_ultimate_small = item_shard_ultimate_baseclass
item_shard_ultimate_medium = item_shard_ultimate_baseclass
item_shard_ultimate_large = item_shard_ultimate_baseclass
-- item_shard_ultimate_extreme = item_shard_ultimate_baseclass

-- item_end_shard = class(item_shard_baseclass)

item_shard_level = class(item_shard_baseclass)
item_shard_level10 = class(item_shard_baseclass)
