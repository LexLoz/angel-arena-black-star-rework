modifier_stamina = class({
	IsPurgable      = function() return false end,
	IsHidden        = function() return true end,
	RemoveOnDeath   = function() return false end,
	DestroyOnExpire = function() return false end,
	GetTexture      = function() return "attribute_abilities/stamina" end,
})

function modifier_stamina:CheckState()
	return self:GetStackCount() == 0 and {
		[MODIFIER_STATE_EVADE_DISABLED] = true
	}
end

function modifier_stamina:DeclareFunctions()
	return {
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_RESPAWN,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		--MODIFIER_PROPERTY_TOOLTIP,
	}
end

function modifier_stamina:OnTooltip()
	--print('tooltip')
	return --self:GetParent():GetNetworkableEntityInfo("StaminaPerHit")
end

if IsClient() then
	function modifier_stamina:HandleCustomTransmitterData(data)
		self.max_bat_decrease = data.max_bat_decrease
		self.reduce_damage = data.reduce_damage
		self.reduce_ms = data.reduce_ms
		self.bat = data.bat
	end

	function modifier_stamina:GetModifierBaseAttackTimeConstant()
		return self.bat +
			(1 - self:GetStackCount() / 100) * self.max_bat_decrease
	end
end

function modifier_stamina:GetModifierDamageOutgoing_Percentage()
	return (1 - self:GetStackCount() / 100) * self.reduce_damage
end

function modifier_stamina:GetModifierMoveSpeedBonus_Percentage()
	return (1 - self:GetStackCount() / 100) * self.reduce_ms
end

if IsServer() then
	function modifier_stamina:OnCreated()
		self:SetDuration(0.1, true)
		self.debuff = false
		self.Pos = self:GetParent():GetAbsOrigin()
		self.bonus_for_health = 0
		self.bonus_for_mana = 0
		self.cost = 0
		local parent = self:GetParent()
		self.stamina = 100 + STAMINA_PER_AGILITY * parent:GetAgility()
		self._stamina = self.stamina
		self.current_stamina = self.stamina
		self.stamina_regen = self.stamina * STAMINA_REGEN * 0.01
		self:SetStackCount(100)
		self.stamina_regen_fountain_bonus = 3
		self.ret_ms = 0
		self.attack_time_change = 0
		self.changed_bat = 0
		self.saved_bat = 0
		self._bonus_stamina_regen_pct = 1

		parent.bonus_stamina_pct = 1
		parent.bonus_stamina_regen_pct = 1
		--self.disable_regen = false

		-- parent:SetNetworkableEntityInfo("StaminaMSReduce", STAMINA_MAX_MS_REDUSE)
		-- parent:SetNetworkableEntityInfo("StaminaDamageReduce", STAMINA_DAMAGE_DECREASE_PCT)
		parent:SetNetworkableEntityInfo("MaxStamina", math.round(self.stamina))
		-- parent:SetNetworkableEntityInfo("Stamina", self.stamina)
		--parent:SetNetworkableEntityInfo("STAMINA_ARMOR_DECREASE_MULT", STAMINA_ARMOR_DECREASE_MULT)
		--parent:SetNetworkableEntityInfo("STAMINA_DEBUFF_DURATION", STAMINA_DEBUFF_DURATION)
		--parent:SetNetworkableEntityInfo("StaminaThreshouldForDebuff", STAMINA_THRESHOLD_FOR_DEBUFF)

		parent.GetMaxStamina = function()
			return self.stamina
		end
		parent.GetStamina = function()
			return self.current_stamina
		end
		parent.GetStaminaRegen = function()
			return self.stamina_regen + self.stamina_regen_fountain_bonus
		end
		parent.SetStamina = function(value)

		end
		parent.ModifyStamina = function(_, value, bShowMessage, timer)
			if self.debuff then return 0 end
			--if value > (parent:GetStaminaRegen()) * (1/20) then print(value) end
			--if value < 0 then print(value) end
			if type(value) ~= "number" then return 0 end
			--Timers:CreateTimer(timer or 0, function()
			self.current_stamina = math.min(math.max(self.current_stamina + value, 0), self.stamina)
			--parent:SetNetworkableEntityInfo("CurrentStamina", self.current_stamina)
			self:SetStackCount(math.max(1, math.round(parent:GetStamina() / parent:GetMaxStamina() * 100)))
			if self.debuff then self:SetStackCount(0) end
			self._bonus_stamina_regen_pct = 1 + (self:GetStackCount() / 100 * STAMINA_REGEN_INCREASE_MULT)

			if StaminaThreshouldForDebuff(self) and not self.timer1 and not self.timer2 then
				self.timer1 = true
				self:SetDuration(STAMINA_START_DEBUFF_DELAY, true)
				Timers:CreateTimer(STAMINA_START_DEBUFF_DELAY, function()
					if StaminaThreshouldForDebuff(self) then
						if not self.timer2 then
							self.timer2 = true
							self.debuff = true
							--self:StartIntervalThink(-1)
							self.pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_disarm.vpcf",
								PATTACH_OVERHEAD_FOLLOW, parent)
							self:SetStackCount(0)
							Timers:CreateTimer(STAMINA_DEBUFF_DURATION, function()
								self.debuff = false
								self.timer1 = false
								self:SetDuration(STAMINA_DEBUFF_DELAY - STAMINA_DEBUFF_DURATION, true)
								parent:ModifyStamina(parent:GetMaxStamina() / 2)
								ParticleManager:DestroyParticle(self.pfx, false)
								self:StartIntervalThink(self.tick)
							end)
							Timers:CreateTimer(STAMINA_DEBUFF_DELAY, function()
								self.timer2 = false
								--self.timer1 = false
							end)
						end
					else
						self.timer1 = false
					end
				end)
			end
			return self.current_stamina
		end

		--transmitter
		self.reduce_ms = STAMINA_MAX_MS_REDUSE
		self.reduce_damage = STAMINA_DAMAGE_DECREASE_PCT
		self:Transmitter()

		self.tick = 1 / 20
		self:StartIntervalThink(self.tick)
	end

	function modifier_stamina:OnAttackStart(keys)
		local parent = keys.attacker

		if parent ~= self:GetParent() or not parent:IsTrueHero() then return end

		if keys.inflictor then return end

		if parent.bonus_attack then return end
		local mod_str_crit = parent:FindModifierByName("modifier_strength_crit")
		if mod_str_crit and mod_str_crit.ready then return end
		--Timers:NextTick(function()
		--if parent == self:GetParent() then
		if self.stamina and self.current_stamina then
			--Timers:NextTick(function()
			parent:ModifyStamina(-(self.cost or 0))
			--self:StartIntervalThink(self.tick)
			--end)
		end
		--end
		--end)
	end

	function modifier_stamina:GetModifierBaseAttackTimeConstant()
		local parent = self:GetParent()
		local total_bat = self.bat
		return (1 - self:GetStackCount() / 100) * STAMINA_MAX_BAT_DECREASE +
			total_bat
	end

	function modifier_stamina:AddCustomTransmitterData()
		return {
			max_bat_decrease = STAMINA_MAX_BAT_DECREASE,
			reduce_damage = self.reduce_damage,
			reduce_ms = self.reduce_ms,
			bat = self.bat
		}
	end

	function modifier_stamina:Transmitter()
		local parent = self:GetParent()

		--transmitter
		self.bat = (parent.Custom_AttackRate or parent:GetKeyValue("AttackRate")) + (parent.outside_change_bat or 0)
		self:SetHasCustomTransmitterData(false)
		self:SetHasCustomTransmitterData(true)
		self:SendBuffRefreshToClients()
	end

	function modifier_stamina:OnIntervalThink()
		--self._tick = self._tick + 1
		local parent = self:GetParent()

		--transmitter
		self:Transmitter()

		--regen stamina
		if parent:IsAlive() and not self.debuff and self.current_stamina < self.stamina then
			parent:ModifyStamina(((self.stamina_regen + self.stamina_regen_fountain_bonus) * (parent.bonus_stamina_regen_pct or 1) * (self._bonus_stamina_regen_pct or 1)) *
				self.tick)
		end
	end

	function modifier_stamina:UpdateMaxStamina(parent, value)
		self.stamina = value
		Timers:NextTick(function()
			if self._stamina < self.stamina then
				local difference = self.stamina - self._stamina
				parent:ModifyStamina(difference)
				self.stamina_regen = self.stamina * STAMINA_REGEN * 0.01
				self._stamina = self.stamina
				parent:SetNetworkableEntityInfo("MaxStamina", math.round(self.stamina))
				-- parent:SetNetworkableEntityInfo("Stamina", self.stamina)
			elseif self._stamina > self.stamina then
				local difference = self._stamina - self.stamina
				parent:ModifyStamina(-difference)
				self.stamina_regen = self.stamina * STAMINA_REGEN * 0.01
				self._stamina = self.stamina
				parent:SetNetworkableEntityInfo("MaxStamina", math.round(self.stamina))
				-- parent:SetNetworkableEntityInfo("Stamina", self.stamina)
			end
		end)
	end

	function modifier_stamina:OnRespawn()
		self:GetParent():ModifyStamina(self:GetParent():GetMaxStamina())
	end
end
