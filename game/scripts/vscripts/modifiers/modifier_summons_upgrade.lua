modifier_summons_upgrade = class({
	IsPurgable       = function() return false end,
	IsHidden         = function() return false end,
	RemoveOnDeath    = function() return true end,
	GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	DestroyOnExpire  = function() return false end,
	DeclareFunctions = function()
		return {
			MODIFIER_EVENT_ON_ATTACK_LANDED,

			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			-- MODIFIER_PROPERTY_HEALTH_BONUS,
		}
	end,
})

if IsServer() then
	function modifier_summons_upgrade:AddCustomTransmitterData()
		return {
			damage_bonus = self.damage_bonus,
			spell_damage_bonus = self:GetModifierTotalDamageOutgoing_Percentage(),
			-- bonus_health = self.bonus_health,
		}
	end

	function modifier_summons_upgrade:Refresh()
		self.damage_bonus = self:GetParent():GetAverageTrueAttackDamage(self:GetParent()) * (self:GetStackCount() * 0.01)
		-- print('damage bonus, ' .. self.damage_bonus)
		self:SetHasCustomTransmitterData(false)
		self:SetHasCustomTransmitterData(true)
		self:SendBuffRefreshToClients()
	end

	function modifier_summons_upgrade:OnCreated()
		self:Refresh()
		self:StartIntervalThink(0.1)
	end

	function modifier_summons_upgrade:OnIntervalThink()
		if self.damage ~= self:GetParent():GetAverageTrueAttackDamage(self:GetParent()) then
			self.damage = self:GetParent():GetAverageTrueAttackDamage(self:GetParent())
			self:Refresh()
		end
	end

	function modifier_summons_upgrade:GetModifierTotalDamageOutgoing_Percentage()
		return self:GetStackCount()
	end

	function modifier_summons_upgrade:OnAttackLanded(keys)
		local attacker = keys.attacker
		local target = keys.target

		if attacker ~= self:GetParent() then return end

		if not attacker:IsRangedUnit() then
			local distance = 400
			local start = 100
			local _end = 250
			DoCleaveAttack(
				attacker,
				target,
				item,
				(attacker:GetAverageTrueAttackDamage(attacker) + self.damage_bonus) * 0.1 / (1 + self:GetStackCount() * 0.01),
				start,
				_end,
				distance,
				"particles/items_fx/battlefury_cleave.vpcf"
			)
		else
			local radius = 200
			local targets = FindUnitsInRadius(
				attacker:GetTeam(),
				target:GetAbsOrigin(),
				item,
				radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
				FIND_ANY_ORDER,
				false
			)
			local i = 0
			for _, v in pairs(targets) do
				if i >= 3 then break end
				if target:IsAlive() and v ~= target then
					ApplyDamage({
						attacker = attacker,
						victim = v,
						damage_type = DAMAGE_TYPE_PHYSICAL,
						damage = (attacker:GetAverageTrueAttackDamage(attacker) + self.damage_bonus) * 0.1,
						damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
					})
				end
			end
		end
	end
else
	function modifier_summons_upgrade:HandleCustomTransmitterData(data)
		self.damage_bonus = data.damage_bonus
		self.spell_damage_bonus = data.spell_damage_bonus
		-- self.bonus_health = data.bonus_health
	end

	function modifier_summons_upgrade:GetModifierSpellAmplify_Percentage()
		return self.spell_damage_bonus or 0
	end

	function modifier_summons_upgrade:GetModifierPreAttack_BonusDamage()
		return self.damage_bonus or 0
	end
end

-- function modifier_summons_upgrade:GetModifierHealthBonus()
-- 	print(self.bonus_health)
-- 	return self.bonus_health or 0
-- end
