modifier_jungle_golem = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end,
	GetModifierIgnoreMovespeedLimit = function() return 1 end,
	GetModifierAttackSpeed_Limit = function() return 1 end,
})

function modifier_jungle_golem:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE
	}
	return funcs
end

function modifier_jungle_golem:GetModifierPhysicalArmorBonus()
	return 0.5 + self:GetParent():GetLevel() * 0.5
end

function modifier_jungle_golem:GetModifierModelScale()
	return math.min(1, self:GetStackCount() * 0.01)
end

function modifier_jungle_golem:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * (0.95 + self:GetParent():GetLevel() * 0.05)
end

function modifier_jungle_golem:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount()
end

function modifier_jungle_golem:GetModifierBaseDamageOutgoing_Percentage()
	return math.floor(self:GetStackCount() * 30)
end

local function resistFormula(stacks)
	return (0.1 * stacks) / (0.9 + 0.1 * stacks)

end

if IsServer() then
	function modifier_jungle_golem:GetModifierIncomingDamageConstant(keys)
		return -keys.damage * resistFormula(self:GetStackCount())
	end
else
	function modifier_jungle_golem:GetModifierIncomingDamage_Percentage()
		return resistFormula(self:GetStackCount()) * 100
	end
end

if IsServer() then
	function modifier_jungle_golem:OnDestroy()
		self:GetParent().golem_stacks = 0
	end
end