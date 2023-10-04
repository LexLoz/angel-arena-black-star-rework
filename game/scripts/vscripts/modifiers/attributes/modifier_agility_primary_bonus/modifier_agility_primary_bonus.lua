modifier_agility_primary_bonus = class({
	IsPurgable    = function() return false end,
    IsHidden      = function() return false end,
    RemoveOnDeath = function() return false end,
	DestroyOnExpire = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	GetTexture    = function() return "attribute_abilities/agility_attribute_symbol" end,

})

function modifier_agility_primary_bonus:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2
	}
end

function modifier_agility_primary_bonus:OnTooltip()
	return self:GetParent():GetNetworkableEntityInfo("bonus_attacks_requirement")
end

function modifier_agility_primary_bonus:OnTooltip2()
	return self:GetParent():GetNetworkableEntityInfo("agility_for_next_bonus_attack")
end

if IsServer() then
    function modifier_agility_primary_bonus:OnCreated()
		self.primary = DOTA_ATTRIBUTE_AGILITY
        self.tick = 1
		self.bonusAttacksCount = AGILITY_BONUS_ATTACKS_BASE_COUNT
		self.requirement = AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK

		self.calculateChance = function()
			return AGILITY_BONUS_BASE_PROCK_CHANCE + AGILITY_BONUS_PROCK_CHANCE_PER_LEVEL * self:GetParent():GetLevel()
		end
    end

    function modifier_agility_primary_bonus:OnAttackStart(keys)
		--print("bonus attacks")
        local parent = keys.attacker
		-- print('attack')

        if not self.cooldown and not parent:PassivesDisabled() and RollPercentage(self:calculateChance()) and parent == self:GetParent() and (parent:IsTrueHero() or parent:IsIllusion()) and self.bonusAttacksCount >= 1 then
			local attack_rate = 1 / ((1 + parent:GetAttackSpeed()) / parent:GetBaseAttackTime())
			local target = keys.target
			
			local effects_count = #parent:FindAllModifiersByName("modifier_agility_bonus_attacks")
			if effects_count > AGILITY_BONUS_MAX_EFFECTS_COUNT then return end

			local modifier = parent:AddNewModifier(parent, nil, "modifier_agility_bonus_attacks", {duration = attack_rate * self.bonusAttacksCount, target = target, attack_rate = attack_rate, parent_modifier = self, bonus_damage = self.bonus_damage or 0})
			modifier.target = target

			self.cooldown = true
			self:SetDuration(AGILITY_BONUS_ATTACKS_COOLDOWN, true)
			Timers:CreateTimer(AGILITY_BONUS_ATTACKS_COOLDOWN, function()
				self.cooldown = false
			end)
		end
    end
end