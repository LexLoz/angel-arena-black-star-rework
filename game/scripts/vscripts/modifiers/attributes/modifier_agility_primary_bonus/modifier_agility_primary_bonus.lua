modifier_agility_primary_bonus = class({
	IsPurgable      = function() return false end,
	IsHidden        = function() return false end,
	RemoveOnDeath   = function() return false end,
	DestroyOnExpire = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	GetTexture      = function() return "attribute_abilities/agility_attribute_symbol" end,

})

function modifier_agility_primary_bonus:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2,
	}
end

if IsClient() then
	function modifier_agility_primary_bonus:HandleCustomTransmitterData(data)
		self.bonus_attacks_requirement = data.bonus_attacks_requirement
		self.agility_for_next_bonus_attack = data.agility_for_next_bonus_attack
	end

	function modifier_agility_primary_bonus:OnTooltip()
		return self.bonus_attacks_requirement
	end

	function modifier_agility_primary_bonus:OnTooltip2()
		return self.agility_for_next_bonus_attack
	end
end

if IsServer() then
	function modifier_agility_primary_bonus:AddCustomTransmitterData()
		return {
			bonus_attacks_requirement = self.bonus_attacks_requirement or 0,
			agility_for_next_bonus_attack = self.agility_for_next_bonus_attack or 0
		}
	end

	function modifier_agility_primary_bonus:Transmitter()
		self:SetHasCustomTransmitterData(false)
		self:SetHasCustomTransmitterData(true)
		self:SendBuffRefreshToClients()
	end

	function modifier_agility_primary_bonus:OnCreated()
		self.primary = DOTA_ATTRIBUTE_AGILITY
		self.tick = 1
		self.bonusAttacksCount = AGILITY_BONUS_ATTACKS_BASE_COUNT
		self.requirement = AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK

		self.calculateChance = function()
			return AGILITY_BONUS_BASE_PROCK_CHANCE + AGILITY_BONUS_PROCK_CHANCE_PER_LEVEL * math.min(600, self:GetParent():GetLevel())
		end

		self:Transmitter()
	end

	function modifier_agility_primary_bonus:OnAbilityExecuted(keys)
		local parent = self:GetParent()
		if parent ~= keys.unit then return end
		local castedAbility = keys.ability

		if castedAbility:IsToggle() then return end
		if (castedAbility:GetCooldown(castedAbility:GetLevel()) == 0 or (castedAbility.GetAbilityChargeRestoreTime and castedAbility:GetAbilityChargeRestoreTime(castedAbility:GetLevel()) == 0)) and castedAbility:GetManaCost(castedAbility:GetLevel()) == 0 then return end
		-- print('multicast')
		if castedAbility:IsItem() then return end

		local caster = self:GetParent()
		local target = keys.target or caster:GetCursorPosition()
		local ability = self:GetAbility()

		if RollPseudoRandomPercentage(self:calculateChance(), DOTA_PSEUDO_RANDOM_OGRE_ITEM_MULTICAST, caster) then
			-- print('multicast')
			PreformMulticast(caster, castedAbility, math.max(2, math.min(4, math.floor(self:GetStackCount() / 2))), 0.75, target)
		end
	end

	function modifier_agility_primary_bonus:OnAttackStart(keys)
		--print("bonus attacks")
		local parent = keys.attacker
		-- print('attack')

		if not self.cooldown and not parent:IsIllusion() and not parent:PassivesDisabled() and RollPseudoRandomPercentage(self:calculateChance(), DOTA_PSEUDO_RANDOM_FACELESS_BASH, parent) and parent == self:GetParent() and (parent:IsTrueHero() or parent:IsIllusion()) and self.bonusAttacksCount >= 1 then
			local attack_rate = math.max(0.1, 1 / ((1 + parent:GetAttackSpeed(false)) / parent:GetBaseAttackTime()))
			local target = keys.target

			local effects_count = #parent:FindAllModifiersByName("modifier_agility_bonus_attacks")
			if effects_count > AGILITY_BONUS_MAX_EFFECTS_COUNT then return end

			local modifier = parent:AddNewModifier(parent, nil, "modifier_agility_bonus_attacks",
				{
					duration = attack_rate * self.bonusAttacksCount,
					target = target,
					attack_rate = attack_rate,
					parent_modifier =
						self,
					bonus_damage = self.bonus_damage or 0
				})
			if modifier then modifier.target = target end

			-- self.cooldown = true
			-- self:SetDuration(AGILITY_BONUS_ATTACKS_COOLDOWN, true)
			Timers:CreateTimer(AGILITY_BONUS_ATTACKS_COOLDOWN, function()
				self.cooldown = false
			end)
		end
	end
end
