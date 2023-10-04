LinkLuaModifier("modifier_sara_fragment_of_hate_damage", "heroes/hero_sara/fragment_of_hate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_fragment_of_hate", "heroes/hero_sara/fragment_of_hate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_fragment_of_hate_buff_scepter", "heroes/hero_sara/fragment_of_hate.lua", LUA_MODIFIER_MOTION_NONE)

sara_fragment_of_hate = class({
	GetIntrinsicModifierName = function() return "modifier_sara_fragment_of_hate" end,
})

if IsServer() then
	function sara_fragment_of_hate:OnUpgrade()
		if self:GetLevel() == 1 then
			self:ToggleAutoCast()
		end
	end
end

function sara_fragment_of_hate:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function sara_fragment_of_hate:GetManaCost()
	return self:GetCaster():GetMana() * self:GetSpecialValueFor("cost") * 0.01
end

function sara_fragment_of_hate:GetCooldown(level)
	return self:GetCaster():HasScepter() and self.BaseClass.GetCooldown(self, level) or 0
end

--[[if IsServer() then
	function sara_fragment_of_hate:OnSpellStart()
		local caster = self:GetCaster()
		caster:AddNewModifier(caster, self, "modifier_sara_fragment_of_hate", {duration = self:GetSpecialValueFor("buff_duration_scepter")})
	end

	function sara_fragment_of_hate:OnUpgrade()
		if self:GetLevel() == 1 then
			self:ToggleAutoCast()
		end
	end
end]]

modifier_sara_fragment_of_hate = class({
	IsHidden   = function() return true end,
	IsPurgable = function() return false end,
})

modifier_sara_fragment_of_hate_damage = class({
	IsHidden   = function() return true end,
	IsPurgable = function() return false end,
})

function modifier_sara_fragment_of_hate_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then
	function modifier_sara_fragment_of_hate:OnCreated()
		self._ = true
		self:StartIntervalThink(0.1)
	end
	function modifier_sara_fragment_of_hate:OnIntervalThink()
		local ability = self:GetAbility()
		local parent = self:GetParent()

		if ability:GetAutoCastState() and self._ then
			 parent:AddNewModifier(parent, ability, "modifier_sara_fragment_of_hate_damage", {duration = -1})
			 self._ = false
		elseif not ability:GetAutoCastState() and not self._ then
			parent:RemoveModifierByName("modifier_sara_fragment_of_hate_damage")
			self._ = true
		end
	end
	function modifier_sara_fragment_of_hate_damage:OnAttackLanded(keys)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local cost = ability:GetManaCost(-1)
		if keys.attacker == parent then
			parent:ModifyEnergy(-cost)
		end
	end
	function modifier_sara_fragment_of_hate_damage:GetModifierPreAttack_CriticalStrike()
		local ability = self:GetAbility()
		local cost = ability:GetManaCost(-1)
		if RollPercentage(ability:GetSpecialValueFor("crit_chance_pct")) then
			return 100 + cost * ability:GetSpecialValueFor("cost_to_crit_pct") * 0.01
		end
	end
	function modifier_sara_fragment_of_hate_damage:GetModifierPreAttack_BonusDamage()
		local parent = self:GetParent()
		if parent.GetEnergy then
			local ability = self:GetAbility()
			local cost = ability:GetManaCost(-1)
			local damage = cost * ability:GetSpecialValueFor("cost_to_damage") * 0.01
			return damage
		end
	end
else
	function modifier_sara_fragment_of_hate_damage:GetModifierPreAttack_BonusDamage()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local cost = parent:GetNetworkableEntityInfo("Energy") * ability:GetSpecialValueFor("cost") * 0.01
		local damage = cost * ability:GetSpecialValueFor("cost_to_damage") * 0.01
		return damage
	end
end
