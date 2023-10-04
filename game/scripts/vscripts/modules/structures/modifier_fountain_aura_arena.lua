local FOUNTAIN_PERCENTAGE_MANA_REGEN = 15
local FOUNTAIN_PERCENTAGE_HEALTH_REGEN = 15

modifier_fountain_aura_arena = class({
	IsPurgable =                          function() return false end,
	GetModifierHealthRegenPercentage =    function() return FOUNTAIN_PERCENTAGE_MANA_REGEN end,
	GetModifierTotalPercentageManaRegen = function() return FOUNTAIN_PERCENTAGE_HEALTH_REGEN end,
	GetTexture =                          function() return "fountain_heal" end,
})

function modifier_fountain_aura_arena:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE
	}
end

if IsServer() then
	function modifier_fountain_aura_arena:OnCreated(keys)
		if keys.not_on_fountain then self.not_on_fountain = true end
		local parent = self:GetParent()
		self:StartIntervalThink(0.25)
		self:OnIntervalThink()
		if self:GetParent():IsHero() then
			--Attributes:UpdateAll(parent)

			local stamina = parent:FindModifierByName("modifier_stamina")

			if stamina then
				stamina.stamina_regen_fountain_bonus = stamina.stamina_regen * 3
			end
		end
	end

	function modifier_fountain_aura_arena:OnDestroy()
		local parent = self:GetParent()
		self:GetParent():RemoveModifierByName("modifier_fountain_aura_invulnerability")
		if parent:IsHero() then
			--Attributes:UpdateAll(parent, 1)

			local stamina = parent:FindModifierByName("modifier_stamina")

			if stamina then
				stamina.stamina_regen_fountain_bonus = 0
			end
		end
	end

	function modifier_fountain_aura_arena:OnIntervalThink()
		local parent = self:GetParent()
		--while parent:HasModifier("modifier_saber_mana_burst_active") do
			--parent:RemoveModifierByName("modifier_saber_mana_burst_active")
		--end

		local isBossAlive = Bosses:IsAlive("cursed_zeld")
		local hasMod = parent:HasModifier("modifier_fountain_aura_invulnerability")
		if isBossAlive and not hasMod then
			parent:AddNewModifier(parent, nil, "modifier_fountain_aura_invulnerability", nil)
		elseif not isBossAlive and hasMod then
			parent:RemoveModifierByName("modifier_fountain_aura_invulnerability")
		end

		if parent:IsCourier() then return end
		for i = 0, 11 do
			local item = parent:GetItemInSlot(i)
			if item and item:GetAbilityName() == "item_bottle_arena" and not self.not_on_fountain then
				item:SetCurrentCharges(3)
			end
		end
	end
end

modifier_fountain_aura_invulnerability = class({
	IsPurgable =                  function() return false end,
	GetAbsoluteNoDamagePhysical = function() return 1 end,
	GetAbsoluteNoDamageMagical =  function() return 1 end,
	GetAbsoluteNoDamagePure =     function() return 1 end,
	GetTexture =                  function() return "modifier_invulnerable" end,
})

function modifier_fountain_aura_invulnerability:CheckState()
	return {
        --[MODIFIER_STATE_INVULNERABLE] = true
	}
end

function modifier_fountain_aura_invulnerability:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_TOOLTIP
	}
end
