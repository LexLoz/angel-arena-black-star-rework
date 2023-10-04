LinkLuaModifier("modifier_sara_evolution", "heroes/hero_sara/evolution.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_evolution_active", "heroes/hero_sara/evolution.lua", LUA_MODIFIER_MOTION_NONE)

sara_evolution_new = class({
	GetIntrinsicModifierName = function() return "modifier_sara_evolution" end,
})

function sara_evolution_new:GetBehavior()
	return self:GetLevel() >= 3 and DOTA_ABILITY_BEHAVIOR_NO_TARGET or DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function sara_evolution_new:GetCooldown(level)
	return self:GetLevel() >= 3 and self.BaseClass.GetCooldown(self, level) or 0
end

function sara_evolution_new:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetAbilitySpecial("active_duration")
	if caster:HasModifier("modifier_sara_evolution") then
		caster:AddNewModifier(caster, self, "modifier_sara_evolution_active", {duration = duration})
	end
end

modifier_sara_evolution = class({
	IsPurgable      = function() return false end,
	DestroyOnExpire = function() return false end,
	IsHidden		= function() return true end,
})

modifier_sara_evolution_active = class({
	IsHidden  	  = function() return false end,
	IsPurgable	  = function() return true end,
    RemoveOnDeath = function() return true end,
})

function modifier_sara_evolution:DeclareFunctions()
	return {
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_DEATH,
		--MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE
	}
end

if IsServer() then
	function modifier_sara_evolution_active:OnCreated()
		self:GetParent():FindModifierByName("modifier_sara_evolution").radius = 99999
	end
	function modifier_sara_evolution_active:OnDestroy()
		self:GetParent():FindModifierByName("modifier_sara_evolution").radius = self:GetAbility():GetAbilitySpecial("energy_increase_radius")
	end

	function modifier_sara_evolution:GetModifierHealthBonus()
		return self.Health or 0
	end
	function modifier_sara_evolution:GetModifierPercentageManacost()
        return 100
    end

	modifier_sara_evolution.think_interval = 1/20
	function modifier_sara_evolution:OnCreated()
		local parent = self:GetParent()
		local ability = self:GetAbility()


		parent.ManaPerInt = 0
		if ability:GetLevel() == 0 then
			ability:SetLevel(1)
		end

		Timers:NextTick(function()
			if not parent then return end
			parent.HealthPerStrength = ability:GetSpecialValueFor("health_for_strength")
			parent:SetNetworkableEntityInfo("HealthPerStrength", ability:GetSpecialValueFor("health_for_strength"))
			parent.AgilityArmorMultiplier = ability:GetSpecialValueFor("armor_per_agility")
		end)

		self.AbilityUpdate = 200
		self.soul_particle = "particles/units/heroes/hero_nevermore/nevermore_necro_souls.vpcf"
		self.Energy = 1
		self.energy_limit_boost_pct = 1
		self.energy_growth_boost_pct = 1
		self.radius = ability:GetAbilitySpecial("energy_increase_radius")
		self.projectile_speed = 300
		self.ConceptualReflection = false

		local illusionParent = parent:GetIllusionParent()
		if parent.SavedEnergyStates then
			self.Energy = parent.SavedEnergyStates.Energy or self.Energy
			self.AbilityUpdate = parent.SavedEnergyStates.AbilityUpdate or self.AbilityUpdate
			parent.SavedEnergyStates = nil
		elseif IsValidEntity(illusionParent) and illusionParent.GetEnergy and illusionParent.GetMaxEnergy then
			self.Energy = illusionParent:GetEnergy()
			self.AbilityUpdate = illusionParent:_AbilityUpdate()
		end

		parent.GetEnergy = function()
			return self.Energy
		end
		parent.GetMaxEnergy = function()
			return self.Energy
		end
		parent.GetEnergyLimit = function()
			return self.EnergyLimit
		end
		parent._AbilityUpdate = function()
			return self.AbilityUpdate
		end
		parent:SetNetworkableEntityInfo("Energy", self.Energy)
		parent:SetNetworkableEntityInfo("MaxEnergy", self.Energy)

		parent.ModifyMaxEnergy = function(_, value)
			self.Energy = self.Energy + value
			parent:SetNetworkableEntityInfo("MaxEnergy", self.Energy)
			return self.Energy
		end

		parent.ModifyEnergy = function(_, value, bShowMessage, noAmp)
			if bShowMessage then
				--print("Call: modify mana by " .. value  .. ", result: old mana: " .. self.Energy .. " new mana: " .. math.min(math.max(self.Energy + value, 0), self.MaxEnergy))
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, value, nil)
			end
			local int_multiplier = ability:GetAbilitySpecial("int_in_growth_mult_pct") * parent:GetIntellect() * 0.01 * value * 0.01
			if value > 0 and not noAmp then value = (value + int_multiplier) end
			local returned_value = value
			value = math.min(math.max(self.Energy + value, 1), self.EnergyLimit)
			self.Energy = value
			parent:SetNetworkableEntityInfo("Energy", __toFixed(self.Energy, 0))
			return returned_value
		end
		parent.BonusEnergy = 0
		self:StartIntervalThink(self.think_interval)
	end

	function modifier_sara_evolution:GetModifierManaBonus()
		return --self.ManaModifier or self:GetSharedKey("ManaModifier") or 0
	end

	function modifier_sara_evolution:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		if self._ManaPerInt ~= parent.ManaPerInt then
			self._ManaPerInt = 0
			parent.ManaPerInt = 0
		end

		for i = 2, parent:GetLevel() do
			if i % self.AbilityUpdate == 0 then
				ability:SetLevel(ability:GetLevel() + 1)
				self.AbilityUpdate = self.AbilityUpdate + 200
				Notifications:TopToAll({text="#sara_evolution_upgrade", duration = 6, style={color="red", ["font-size"]="72px"}})
				EmitGlobalSound("Arena.Hero_Sara.Evolution")
			end
		end

		if ability:GetLevel() >= 4 then
			self.EnergyLimit = 2000000000
			parent:SetNetworkableEntityInfo("EnergyLimit", self.EnergyLimit)
		else
			self.EnergyLimit = (ability:GetSpecialValueFor("energy_limit") + ability:GetSpecialValueFor("energy_limit_per_lvl") * parent:GetLevel() + parent.BonusEnergy) * self.energy_limit_boost_pct
			parent:SetNetworkableEntityInfo("EnergyLimit", self.EnergyLimit)
		end
		self.EnergyGrowth = ability:GetSpecialValueFor("energy_growth_sec") + ability:GetSpecialValueFor("energy_growth_sec_per_lvl") * parent:GetLevel()

		self.Health = -parent:GetStrength() * 20 + parent:GetStrength() * ability:GetSpecialValueFor("health_for_strength") + ability:GetSpecialValueFor("bonus_health")

		local ConceptualReflection = parent:FindAbilityByName("sara_conceptual_reflection")
		if ability:GetLevel() >= 3 and not self.ConceptualReflection then
			ConceptualReflection:SetHidden(false)
			ConceptualReflection:SetLevel(1)
			self.ConceptualReflection = true
		end

		parent:SetMaxMana(self.Energy)
		parent:SetMana(self.Energy)
		--parent:SetBaseManaRegen(self.EnergyGrowth)
		local growth = 0
		if parent:IsAlive() then
			growth = parent:ModifyEnergy((self.EnergyGrowth * (self.energy_growth_boost_pct or 1)) * self.think_interval)
		end

		--parent:SetNetworkableEntityInfo("CurrentMana", __toFixed(self.Energy, 0))
		parent:SetNetworkableEntityInfo("MaxMana", __toFixed(self.Energy, 0))
		parent:SetNetworkableEntityInfo("ManaRegen", (__toFixed((growth / self.think_interval), 1)))
	end

	function modifier_sara_evolution:OnDestroy()
		local parent = self:GetParent()
		if IsValidEntity(parent) then
			--For illusions and RecreateAbility function
			parent.SavedEnergyStates = {
				Energy = self.Energy,
				AbilityUpdate = self.AbilityUpdate
			}
		end
	end

	function modifier_sara_evolution:OnDeath(keys)
		local parent = self:GetParent()

		if keys.unit == parent and not parent:IsIllusion() and parent:IsTrueHero() and not parent:IsTempestDouble() then
            parent:DropItemAtPositionImmediate(self:GetAbility(), parent:GetAbsOrigin())
        end
		
		local ability = self:GetAbility()
		local attacker = keys.attacker
		local unit = keys.unit
		if attacker == parent then
			if unit:IsRealCreep() then
				local energy = ability:GetSpecialValueFor("creeps_max_health_in_energy_pct") * unit:GetMaxHealth() * 0.01
				if unit:GetFullName() == "npc_dota_neutral_jungle_variant1" and parent:GetEnergy() < ability:GetSpecialValueFor("thresould") then
					attacker:ModifyEnergy(energy)
					--print(energy)
					ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
				elseif unit:GetFullName() ~= "npc_dota_neutral_jungle_variant1" then
					attacker:ModifyEnergy(energy)
					--print(energy)
					ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
				end
			end
			if unit:IsHero() then
				local energy = ability:GetSpecialValueFor("heroes_max_health_in_energy_pct") * unit:GetMaxHealth() * 0.01
				attacker:ModifyEnergy(energy)
				ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
			end
			if unit:IsBoss() then
				local energy = ability:GetSpecialValueFor("bosses_max_health_in_energy_pct") * unit:GetMaxHealth() * 0.01
				attacker:ModifyEnergy(energy)
				ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
			end
		end

		local parent_pos = parent:GetAbsOrigin()
		local unit_pos = unit:GetAbsOrigin()
		local radius = self.radius
		local energy_gain_in_radius = ability:GetAbilitySpecial("energy_gain_in_radius")

		if	attacker ~= parent and
			parent ~= unit and
			parent:IsAlive() and
			(parent_pos - unit_pos):Length2D() <= radius and attacker and
			not (attacker:FindAbilityByName("nevermore_necromastery") or attacker:FindAbilityByName("sara_evolution_new")) then

			if unit:IsRealCreep() then
				local energy = ability:GetSpecialValueFor("creeps_max_health_in_energy_pct") * unit:GetMaxHealth() * 0.01 * energy_gain_in_radius * 0.01
				if parent:GetEnergy() < ability:GetSpecialValueFor("thresould") * 1000000 and unit:GetFullName() ~= "npc_dota_neutral_jungle_variant1" then
					parent:ModifyEnergy(energy)
					--print(energy)
					ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
				end
			end
			if unit:IsHero() then
				local energy = ability:GetSpecialValueFor("heroes_max_health_in_energy_pct") * unit:GetMaxHealth() * 0.01 * energy_gain_in_radius * 0.01
				parent:ModifyEnergy(energy)
				ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
			end
			if unit:IsBoss() then
				local energy = ability:GetSpecialValueFor("bosses_max_health_in_energy_pct") * unit:GetMaxHealth() * 0.01 * energy_gain_in_radius * 0.01
				parent:ModifyEnergy(energy)
				ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(parent, unit, ability))
			end
		end
	end

	function modifier_sara_evolution:CreateProjectileTable(parent, unit, ability)
		return {Target = parent, Source = unit, Ability = ability,EffectName = self.soul_particle, bDodgeable = false,bProvidesVision = true, iVisionRadius =  50, iMoveSpeed = self.projectile_speed, iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION}
	end
end

--[[function modifier_sara_evolution:GetModifierManaBonus()
	return self.ManaModifier or self:GetSharedKey("ManaModifier") or 0
end

function modifier_sara_evolution:OnTooltip()
	local ability = self:GetAbility()
	return ability:GetSpecialValueFor("max_per_minute") + ability:GetSpecialValueFor("max_per_minute_pct") * self:GetParent():GetMaxMana() * 0.01
end

function modifier_sara_evolution:GetModifierPhysicalArmorBonus()
	return self.armorReduction
end
if IsServer() then
	modifier_sara_evolution.think_interval = 1/30
	function modifier_sara_evolution:OnCreated()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		if ability:GetLevel() == 0 then
			ability:SetLevel(1)
		end
		self:StartIntervalThink(self.think_interval)
		self:SetDuration(60, true)
		self.MaxEnergy = 100
		self.Energy = self.MaxEnergy
		local illusionParent = parent:GetIllusionParent()
		if parent.SavedEnergyStates then
			self.Energy = parent.SavedEnergyStates.Energy or self.Energy
			self.MaxEnergy = parent.SavedEnergyStates.MaxEnergy or self.MaxEnergy
			parent.SavedEnergyStates = nil
		elseif IsValidEntity(illusionParent) and illusionParent.GetEnergy and illusionParent.GetMaxEnergy then
			self.Energy = illusionParent:GetEnergy()
			self.MaxEnergy = illusionParent:GetMaxEnergy()
		end
		parent:SetNetworkableEntityInfo("Energy", self.Energy)
		parent:SetNetworkableEntityInfo("MaxEnergy", self.MaxEnergy)
		parent.ModifyEnergy = function(_, value, bShowMessage)
			if value > 0 and parent:HasModifier("modifier_sara_fragment_of_logic_debuff") then
				return self.Energy
			end
			if bShowMessage then
				--print("Call: modify mana by " .. value  .. ", result: old mana: " .. self.Energy .. " new mana: " .. math.min(math.max(self.Energy + value, 0), self.MaxEnergy))
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, value, nil)
			end
			self.Energy = math.min(math.max(self.Energy + value, 0), self.MaxEnergy)
			parent:SetNetworkableEntityInfo("Energy", self.Energy)
			return self.Energy
		end
		parent.GetEnergy = function()
			return self.Energy
		end
		parent.GetMaxEnergy = function()
			return self.MaxEnergy
		end
		parent.ModifyMaxEnergy = function(_, value)
			self.MaxEnergy = self.MaxEnergy + value
			parent:SetNetworkableEntityInfo("MaxEnergy", self.MaxEnergy)
			return self.MaxEnergy
		end
	end
	function modifier_sara_evolution:OnDestroy()
		local parent = self:GetParent()
		if IsValidEntity(parent) then
			--For illusions and RecreateAbility function
			parent.SavedEnergyStates = {
				Energy = self.Energy,
				MaxEnergy = self.MaxEnergy
			}
		end
	end
	function modifier_sara_evolution:OnAttackLanded(keys)
		if keys.attacker == self:GetParent() then
			--keys.attacker:ModifyEnergy(keys.attacker:GetMaxEnergy() * self:GetAbility():GetSpecialValueFor("per_hit_pct") * 0.01)
		end
	end
	function modifier_sara_evolution:OnDeath(keys)
		if keys.attacker == self:GetParent() and keys.unit:IsRealCreep() then
			local ability = self:GetAbility()
			local energy = ability:GetSpecialValueFor("max_per_creep") + ability:GetSpecialValueFor("max_per_creep_pct") * keys.attacker:GetMaxEnergy() * 0.01
			if keys.unit.SpaceDissectionMultiplier then
				energy = energy * keys.unit.SpaceDissectionMultiplier
			end
			keys.attacker:ModifyMaxEnergy(energy)
		end
	end
	function modifier_sara_evolution:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		if self:GetRemainingTime() <= 0 then
			self:GetParent():ModifyMaxEnergy(ability:GetSpecialValueFor("max_per_minute") + ability:GetSpecialValueFor("max_per_minute_pct") * parent:GetMaxEnergy() * 0.01)
			self:SetDuration(60, true)
		end
		local energyPS = (ability:GetSpecialValueFor("per_sec_pct") * parent:GetMaxEnergy() * 0.01 + ability:GetSpecialValueFor("per_sec"))
		if parent:HasScepter() then
			energyPS = energyPS * ability:GetSpecialValueFor("per_sec_multiplier_scepter")
		end
		parent:ModifyEnergy(energyPS * self.think_interval)
		parent:SetMana(self.Energy)
		local maxMana = parent:GetMaxMana() - (self.ManaModifier or 0)
		local previous = self.ManaModifier
		self.ManaModifier = self.MaxEnergy - maxMana
		self:SetSharedKey("ManaModifier", self.ManaModifier)
		if parent:IsAlive() then
			parent:CalculateHealthReduction()
		end
		self.armorReduction = ability:GetSpecialValueFor("armor_reduction_pct") * (parent:GetPhysicalArmorValue(false) - (self.armorReduction or 0)) * 0.01
	end
else
	function modifier_sara_evolution:OnCreated()
		self:StartIntervalThink(0.1)


	end
	function modifier_sara_evolution:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		self.armorReduction = ability:GetSpecialValueFor("armor_reduction_pct") * (parent:GetPhysicalArmorValue(false) - (self.armorReduction or 0)) * 0.01
	end
end]]
