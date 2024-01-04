modifier_strength_crit = class({
	IsPurgable      = function() return false end,
	IsHidden        = function() return false end,
	RemoveOnDeath   = function() return false end,
	IsDebuff        = function() return false end,
	DestroyOnExpire = function() return false end,
	GetTexture      = function() return "attribute_abilities/strength_attribute_symbol" end,
})
if IsServer() then
	function modifier_strength_crit:CheckState()
		--return self.ready and { [MODIFIER_STATE_CANNOT_MISS] = true } or nil
	end
end


function modifier_strength_crit:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_CANCELLED,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2
	}
end

if IsClient() then
	function modifier_strength_crit:HandleCustomTransmitterData(data)
		self.cooldown = data.cooldown
		self.spell_crit = data.spell_crit
	end

	function modifier_strength_crit:OnTooltip()
		return self.spell_crit
	end

	function modifier_strength_crit:OnTooltip2()
		return self.cooldown
	end
end

if IsServer() then
	function modifier_strength_crit:AddCustomTransmitterData()
		return {
			cooldown = self.cooldown,
			spell_crit = self.spell_crit,
		}
	end

	function modifier_strength_crit:Transmitter()
		self.cooldown = self:calculateCooldown()
		self.spell_crit = self:GetSpellCrit()
		self:SetHasCustomTransmitterData(false)
		self:SetHasCustomTransmitterData(true)
		self:SendBuffRefreshToClients()
	end

	function modifier_strength_crit:OnCreated()
		local parent = self:GetParent()
		-- parent:SetNetworkableEntityInfo("STRENGTH_CRIT_SPELL_CRIT_DECREASRE_MULT",
		-- 	STRENGTH_CRIT_SPELL_CRIT_DECREASRE_MULT)
		self.calculateCooldown = function()
			if parent then
				return ((STRENGTH_CRIT_COOLDOWN - STRENGTH_CRIT_COOLDOWN_DECREASE_PER_LEVEL * math.min(600, parent:GetLevel()))) *
				parent:GetCooldownReduction()
			end
		end

		-- self.decrease_coeff = STRENGTH_CRIT_DECREASE_COEFF
		self.crit_mult = STRENGTH_CRIT_MULTIPLIER

		self:SetDuration(self:calculateCooldown(), true)
		self.ready = false

		self.OnAttackStart = self.start
		self:Transmitter()
		self:StartIntervalThink(0.2)
	end

	function modifier_strength_crit:OnAttackCancelled(keys)
		if keys.attacker ~= self:GetParent() then return end
		self:GetParent().strength_crit = false
	end

	function modifier_strength_crit:cancel(parent)
		local owner = self:GetParent()
		-- print('cooldown crit')
		Timers:CreateTimer(0.03, function()
			self:SetDuration(self:calculateCooldown(), true)
			self.ready = false
			Attributes:UpdateSpellDamage(parent)

			if owner:HasModifier("modifier_item_coffee_bean") then
				self:Refresh()
				owner:RemoveModifierByName("modifier_item_coffee_bean")
				owner:EmitSound("DOTA_Item.Refresher.Activate")
				ParticleManager:SetParticleControlEnt(
				ParticleManager:CreateParticle("particles/arena/items_fx/coffee_bean_refresh.vpcf",
					PATTACH_ABSORIGIN_FOLLOW, owner), 0, owner, PATTACH_POINT_FOLLOW, "attach_hitloc",
					owner:GetAbsOrigin(), true)
			end
			self.OnAttackLanded = nil
		end)
	end

	function modifier_strength_crit:crit_cancel(keys)
		local parent = self:GetParent()
		-- print('finished')
		if keys.attacker == self:GetParent() then
			self:cancel(parent)
			-- SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, keys.target,
			-- 	keys.original_damage, nil)
		end
	end

	function modifier_strength_crit:start(keys)
		if keys.attacker ~= self:GetParent() then return end
		if not self.ready then return end
		self.OnAttackLanded = self.crit_cancel
	end

	function modifier_strength_crit:Refresh()
		self:SetDuration(-1, true)
		self.ready = true
	end

	function modifier_strength_crit:GetSpellCrit()
		return 100 + (self:GetStackCount() - 100) / 3
	end

	function modifier_strength_crit:OnIntervalThink()
		local parent = self:GetParent()
		if not parent:IsTrueHero() then
			self:SetDuration(self:calculateCooldown(), true)
		end
		if self.spell_crit ~= self:GetSpellCrit() or
			self.cooldown ~= self:calculateCooldown() then
			self:Transmitter()
		end

		if not self.ready and self:GetRemainingTime() <= 0 then
			self:Refresh()
			Attributes:UpdateSpellDamage(parent)
		end
	end
end
