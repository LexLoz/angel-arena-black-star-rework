modifier_arena_util = class({
	IsPurgable    = function() return false end,
	IsHidden      = function() return true end,
	RemoveOnDeath = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
})

function modifier_arena_util:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
	}
end

if IsServer() then
	function modifier_arena_util:GetModifierTotalDamageOutgoing_Percentage(keys)
		local damagetype_const = keys.damage_type
		local damage_flags = keys.damage_flags
		local damage = keys.original_damage
		local saved_damage = keys.original_damage
		local inflictor
		if keys.inflictor then
			inflictor = keys.inflictor
		end
		local attacker
		if keys.attacker then
			attacker = keys.attacker
		end
		local victim
		if keys.target then
			victim = keys.target
		end

		--print(damage)
		if IsValidEntity(inflictor) and inflictor.GetAbilityName then
			damage = DamageHasInflictor(inflictor, damage, attacker, victim, damagetype_const, damage_flags, saved_damage)
		elseif not IsValidEntity(inflictor) and attacker and attacker.DamageMultiplier and damagetype_const == DAMAGE_TYPE_PHYSICAL then
			--print('before amp: '..damage)
			damage = damage + CalculateAttackDamage(attacker, victim)
			--print('after amp: '..damage)
		end
		--print(damage)

		if IsValidEntity(attacker) then
			--local BlockedDamage = 0

			if victim:IsBoss() and (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() > 950 then
				damage = damage / 2
			end
			if victim:IsBoss() and victim._waiting then
				damage = 0
			end

			local function ConditionHelper()
				return IsValidEntity(inflictor) and inflictor.GetAbilityName
			end
			--print(ConditionHelper())
			local condition = not (ConditionHelper() and not FilterDamageSpellAmpCondition(inflictor, inflictor:GetAbilityName(), attacker, keys.damage_flags)) or (ConditionHelper() and ATTACK_DAMAGE_ABILITIES[inflictor:GetAbilityName()])
			--if condition then
				if victim.HasModifier then
					local multiplier = 1
					for k,v in pairs(OUTGOING_DAMAGE_MODIFIERS) do
						if attacker:HasModifier(k) and (type(v) ~= "table" or not v.condition or (v.condition and v.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags))) then
							multiplier = multiplier * ExtractMultiplier(
							damage,
							ProcessDamageModifier(v, attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage))
						end
					end
					for k,v in pairs(ON_DAMAGE_MODIFIER_PROCS) do
						if attacker:HasModifier(k) then
							multiplier = multiplier * ExtractMultiplier(
							damage,
							ProcessDamageModifier(v, attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage))
						end
					end
					local addictive_multiplier = 0
					for k,v in pairs(ON_ADDICTIVE_DAMAGE_MODIFIER_PROCS) do
						if attacker:HasModifier(k) then
							addictive_multiplier = addictive_multiplier + v.addictive_multiplier(attacker) - 1
						end
					end
					--print(addictive_multiplier)
					if addictive_multiplier > 1 then
						multiplier = multiplier + addictive_multiplier
					end

					damage = damage * multiplier
				end
		end
		-- print('current damage: '..damage)
		-- print('saved damage: '..saved_damage)
		-- print('damage increase/decrease percent: '..((damage / saved_damage * 100) - 100))
		return (math.min(2000000000, damage) / saved_damage * 100) - 100
	end

	function modifier_arena_util:GetModifierIncomingDamageConstant(keys)
		local damagetype_const = keys.damage_type
		local damage_flags = keys.damage_flags
		local damage = keys.damage
		local saved_damage = keys.damage
		--print("1: "..damage)
		local inflictor
		if keys.inflictor then
			inflictor = keys.inflictor
		end
		local attacker
		if keys.attacker then
			attacker = keys.attacker
		end
		local victim
		if keys.target then
			victim = keys.target
		end

		if IsValidEntity(attacker) then

			-- if victim:IsBoss() and (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() > 950 then
			-- 	damage = damage / 2
			-- end
			-- if victim:IsBoss() and victim._waiting then
			-- 	return damage
			-- end
			local BlockedDamage = 0

			if victim.HasModifier then
				for k,v in pairs(ON_DAMAGE_MODIFIER_PROCS_VICTIM) do
					if victim:HasModifier(k) then
						damage = ProcessDamageModifier(v, attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage)
					end
					if damage == 0 then break end
				end
				for k,v in pairs(INCOMING_DAMAGE_MODIFIERS) do
					if victim:HasModifier(k) and (type(v) ~= "table" or not v.condition or (v.condition and v.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags))) then
						damage = ProcessDamageModifier(v, attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage)
						if damage == 0 then break end
					end
				end
			end

			if BlockedDamage > 0 then
				-- SendOverheadEventMessage(victim:GetPlayerOwner(), OVERHEAD_ALERT_BLOCK, victim, BlockedDamage, attacker:GetPlayerOwner())
				-- SendOverheadEventMessage(attacker:GetPlayerOwner(), OVERHEAD_ALERT_BLOCK, victim, BlockedDamage, victim:GetPlayerOwner())
	
				damage = damage - BlockedDamage
			end
		end
		-- print('saved damage: '..saved_damage)
		-- print("current damage: "..damage)
		-- print("blocked damage: "..saved_damage - damage)
		-- print('blocked damage pct: '..((damage / saved_damage * 100) - 100))
		return -(saved_damage - damage)
	end

    function modifier_arena_util:OnCreated()
		self.tick = 1 / 20
        self:StartIntervalThink(self.tick)
    end

    function modifier_arena_util:OnIntervalThink()
        local parent = self:GetParent()
        if not self.evolution then
			if parent:GetMaxMana() >= 65536 and (parent:GetMana() ~= self._Mana or parent:GetMaxMana() ~= self._MaxMana) then
				self._Mana = parent:GetMana()
				self._MaxMana = parent:GetMaxMana()
				parent:SetNetworkableEntityInfo("CurrentMana", parent:GetMana())
				parent:SetNetworkableEntityInfo("MaxMana", parent:GetMaxMana())
			end
		end

        --[[if self._Health ~= parent:GetHealth() or self._MaxHealth ~= parent:GetMaxHealth() then
			self._Health = parent:GetHealth()
			self._MaxHealth = parent:GetMaxHealth()
			parent:SetNetworkableEntityInfo("CurrentHealth", parent:GetHealth())
			parent:SetNetworkableEntityInfo("MaxHealth", parent:GetMaxHealth())
		end]]

		if parent:IsHero() and self.health_regen ~= parent:GetHealthRegen() + (parent.custom_regen or 0) then
			self.health_regen = parent:GetHealthRegen() + (parent.custom_regen or 0)
			--print('regen: '..parent:GetHealthRegen())
			--print('custom regen: '..(parent.custom_regen or 0))
			parent:SetNetworkableEntityInfo("HealthRegen", (__toFixed(math.max(0, (parent.custom_regen or 0)) + parent:GetHealthRegen(), 1)))
		end

		if parent:IsHero() and parent:GetHealth() < parent:GetMaxHealth() then
			SafeHeal(parent, math.max(0, (parent.custom_regen or 0) * self.tick), nil, false, {
				amplify = true,
				source = parent
			})
		end

		if parent:IsHero() and parent:GetMana() < parent:GetMaxMana() then
			parent:SetMana(parent:GetMana() + (parent.custom_mana_regen or 0) * self.tick)
		end
    end
end