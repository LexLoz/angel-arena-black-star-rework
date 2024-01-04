item_piercing_blade = {
	GetIntrinsicModifierName = function() return "modifier_item_piercing_blade" end
}


LinkLuaModifier("modifier_item_piercing_blade", "items/item_piercing_blade.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_piercing_blade = {
	IsHidden      = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
	IsPurgable    = function() return false end,
}

function modifier_item_piercing_blade:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_START,
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then
	function modifier_item_piercing_blade:OnAttackLanded(keys)
		local attacker = keys.attacker
		if attacker ~= self:GetParent() then return end
		--if keys.target:IsBoss() then return end
		local ability = self:GetAbility()
		local target = keys.target

		if attacker:FindAllModifiersByName(self:GetName())[1] ~= self then return end

		if IsModifierStrongest(attacker, self:GetName(), MODIFIER_PROC_PRIORITY.pure_damage) then

			-- local damage = target:GetHealth() * ability:GetSpecialValueFor("max_health_damage")  * 0.01
			-- ApplyDamage({
			-- 	victim = target,
			-- 	attacker = attacker,
			-- 	damage = damage,
			-- 	damage_type = ability:GetAbilityDamageType(),
			-- 	damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			-- 	ability = ability
			-- })
		end
	end

	function modifier_item_piercing_blade:GetModifierPreAttack_BonusDamage()
		if IsValidEntity(self.BonusDamageTarget) then
			return self:GetAbility():GetSpecialValueFor("bonus_damage") + self:GetParent().PiercingBladeBonusDamage
		end
	end

	function modifier_item_piercing_blade:OnAttackStart(keys)
		if keys.attacker == self:GetParent() then
			if IsModifierStrongest(keys.attacker, self:GetName(), MODIFIER_PROC_PRIORITY.pure_damage) then
				if keys.target:IsBoss() then
					self.BonusDamageTarget = keys.target
					keys.attacker.PiercingBladeBonusDamage = self.BonusDamageTarget:GetHealth() * self:GetAbility():GetSpecialValueFor("max_health_damage") * 0.01 * 0.05
				else
					self.BonusDamageTarget = keys.target
					keys.attacker.PiercingBladeBonusDamage = self.BonusDamageTarget:GetHealth() * self:GetAbility():GetSpecialValueFor("max_health_damage") * 0.01
				end
			end
		end
	end
else
	function modifier_item_piercing_blade:GetModifierPreAttack_BonusDamage()
		return self:GetAbility():GetSpecialValueFor("bonus_damage")
	end
end
