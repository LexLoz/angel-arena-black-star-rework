modifier_boss_upgrade = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return true end,
    DestroyOnExpire = function() return false end,
	GetModifierIgnoreMovespeedLimit = function() return 1 end,
})

function modifier_boss_upgrade:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
	return funcs
end

function modifier_boss_upgrade:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * 25
end

function modifier_boss_upgrade:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * 20
end

function modifier_boss_upgrade:GetModifierBaseDamageOutgoing_Percentage()
	return math.floor((self:GetStackCount() + 1) ^ 1.4 * 5)
end

local function resistFormula(stacks)
	return (0.06 * stacks ^ 1.3) / (1 + 0.06 * stacks ^ 1.3)
end

if IsServer() then
	function modifier_boss_upgrade:GetModifierIncomingDamageConstant(keys)
		return -keys.damage * resistFormula(self:GetStackCount())
	end
else
    function modifier_boss_upgrade:GetModifierIncomingDamage_Percentage()
		return resistFormula(self:GetStackCount()) * 100
	end
end