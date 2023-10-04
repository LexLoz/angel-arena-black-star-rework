modifier_intelligence_primary_bonus = class({
	IsPurgable    = function() return false end,
	IsHidden      = function() return false end,
	RemoveOnDeath = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	GetTexture      = function() return "attribute_abilities/intelligence_attribute_symbol" end,
})

function modifier_intelligence_primary_bonus:DeclareFunctions()
	return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2
    }
end

function modifier_intelligence_primary_bonus:OnTooltip()
	return self:GetParent():GetNetworkableEntityInfo("IntellectPrimaryBonusMultiplier")
end

function modifier_intelligence_primary_bonus:OnTooltip2()
	return self:GetParent():GetNetworkableEntityInfo("IntellectPrimaryBonusDifference")
end

function modifier_intelligence_primary_bonus:GetModifierStatusResistanceStacking()
	return (self.Target_StatusResist or 0)--not self:GetParent():PassivesDisabled() and (self.Target_StatusResist or 0) or 0
end

function modifier_intelligence_primary_bonus:GetModifierStatusResistanceCaster()
	return  (self.Caster_StatusResist or 0)--not self:GetParent():PassivesDisabled() and (self.Caster_StatusResist or 0) or 0
end

if IsServer() then
	function modifier_intelligence_primary_bonus:OnCreated()
		self:StartIntervalThink(1)
	end
	function modifier_intelligence_primary_bonus:OnIntervalThink()
		local parent = self:GetParent()
		local victim = parent

		if victim:GetPrimaryAttribute() == 2 and victim:GetNetworkableEntityInfo("BonusPrimaryAttribute2") and not self.util_ then
			self.util_ = true

			victim:SetNetworkableEntityInfo("IntellectPrimaryBonusMultiplier", INTELLECT_PRIMARY_BONUS_MAX_BONUS * INTELLECT_PRIMARY_BONUS_UPGRADE_MULT)
			victim:SetNetworkableEntityInfo("IntellectPrimaryBonusDifference", INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT / INTELLECT_PRIMARY_BONUS_UPGRADE_DIFF_MULT)
		elseif not victim:GetNetworkableEntityInfo("BonusPrimaryAttribute2") and self.util_ then
			self.util_ = false

			victim:SetNetworkableEntityInfo("IntellectPrimaryBonusMultiplier", INTELLECT_PRIMARY_BONUS_MAX_BONUS)
			victim:SetNetworkableEntityInfo("IntellectPrimaryBonusDifference", INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT)
		end
	end
    function modifier_intelligence_primary_bonus:OnAbilityExecuted(keys)
		--print('cast')
		local victim = keys.target
		local attacker = keys.ability:GetCaster()

        if not victim then return end
		-- if attacker:PassivesDisabled() then
		-- 	self.Target_StatusResist = 0
		-- 	self.Caster_StatusResist = 0
		-- 	return
		-- end
        if not victim.GetPrimaryAttribute and attacker == self:GetParent() then
			local mult
			if self.util_ then
				mult = INTELLECT_PRIMARY_BONUS_UPGRADE_MULT
			else
				mult = 1
			end
			self.Target_StatusResist = INTELLECT_PRIMARY_BONUS_MAX_BONUS * mult / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE
			self.Caster_StatusResist = INTELLECT_PRIMARY_BONUS_MAX_BONUS * mult / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE
			self:SetStackCount(math.round(INTELLECT_PRIMARY_BONUS_MAX_BONUS * mult / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE))
			return
		end

		local max_bonus = INTELLECT_PRIMARY_BONUS_MAX_BONUS
		local difference = INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT

        if victim == self:GetParent() then
			if self.util_ then
				max_bonus = max_bonus * INTELLECT_PRIMARY_BONUS_UPGRADE_MULT
				difference = difference / INTELLECT_PRIMARY_BONUS_UPGRADE_DIFF_MULT
			else
				max_bonus = INTELLECT_PRIMARY_BONUS_MAX_BONUS
				difference = INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT
			end

			if victim:PassivesDisabled() or victim:IsHexed() then
				self.Target_StatusResist = 0
				return
			end

			local attackerInt = attacker:GetIntellect()
			local victimInt = (victim:GetIntellect())
			local diff

            if attackerInt >= victimInt then
				self.Target_StatusResist = 0
				self:SetStackCount(math.round(self.Target_StatusResist))
			end
			if attackerInt < victimInt then
				diff = victimInt / attackerInt
				if diff >= difference then
					self.Target_StatusResist = max_bonus
					self:SetStackCount(math.round(self.Target_StatusResist))
				else
					diff = 1 - attackerInt / victimInt
					self.Target_StatusResist = max_bonus * diff
					self:SetStackCount(math.round(self.Target_StatusResist))
				end
			end
	    end
		if attacker == self:GetParent() then
			if self._util then
				max_bonus = max_bonus * INTELLECT_PRIMARY_BONUS_UPGRADE_MULT
				difference = difference / INTELLECT_PRIMARY_BONUS_UPGRADE_DIFF_MULT
			else
				max_bonus = INTELLECT_PRIMARY_BONUS_MAX_BONUS
				difference = INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT
			end

			if attacker:PassivesDisabled() or attacker:IsHexed() then
				self.Caster_StatusResist = 0
				return
			end

			local attackerInt = (attacker:GetIntellect())
			local victimInt = victim:GetIntellect()
			local diff

			if attackerInt <= victimInt then
				self.Caster_StatusResist = 0
				self:SetStackCount(math.round(self.Caster_StatusResist))
			end
			if attackerInt > victimInt then
				diff = attackerInt / victimInt
				if diff >= difference then
					self.Caster_StatusResist = -max_bonus
					self:SetStackCount(math.abs(math.round(self.Caster_StatusResist)))
				else
					diff = 1 - victimInt / attackerInt
					self.Caster_StatusResist = -max_bonus * diff
					self:SetStackCount(math.abs(math.round(self.Caster_StatusResist)))
				end
			end
		end
	--print(self.Target_StatusResist)
	--print(self.Caster_StatusResist)
    end
end