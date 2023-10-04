modifier_neutral_upgrade_attackspeed = class({})

function modifier_neutral_upgrade_attackspeed:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		--MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	}
	return funcs
end

if IsServer() then
	-- function modifier_neutral_upgrade_attackspeed:GetModifierConstantHealthRegen()
	-- 	return self:GetParent():IsJungleBear() and
	-- 		(not GameMode.Jungle_Bears_Reward_Multiplier and
	-- 			(self:GetParent():GetLevel() % 200 == 0 and
	-- 				self:GetParent():GetHealth() * 0.2
	-- 				or 0)
	-- 			or 0)
	-- 		or 0
	-- end
end

function modifier_neutral_upgrade_attackspeed:GetModifierAttackSpeedBonus_Constant()
	return 1 * self:GetStackCount()
end

function modifier_neutral_upgrade_attackspeed:IsHidden()
	return true
end