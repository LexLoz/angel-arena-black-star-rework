LinkLuaModifier("modifier_item_sacred_blade_mail", "items/item_sacred_blade_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_blade_mail_active", "items/item_sacred_blade_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_blade_mail_buff", "items/item_sacred_blade_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_blade_mail_buff_cooldown", "items/item_sacred_blade_mail.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_blade_mail = class({
	GetIntrinsicModifierName = function() return "modifier_item_sacred_blade_mail" end,
})

if IsServer() then
	function item_sacred_blade_mail:OnSpellStart()
		local caster = self:GetCaster()
		caster:AddNewModifier(caster, self, "modifier_item_sacred_blade_mail_active", {duration = self:GetSpecialValueFor("duration")})
		caster:EmitSound("DOTA_Item.BladeMail.Activate")
		caster:Purge(false, true, false, false, false)
	end
end


modifier_item_sacred_blade_mail = class({
	IsHidden =   function() return true end,
	IsPurgable = function() return false end,
})

function modifier_item_sacred_blade_mail:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		--MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		--MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_sacred_blade_mail:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_sacred_blade_mail:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_sacred_blade_mail:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_sacred_blade_mail:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_sacred_blade_mail:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_magical_armor")
end

function modifier_item_sacred_blade_mail:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("bonus_hp_regen_pct")
end


modifier_item_sacred_blade_mail_active = class({
	IsPurgable    = 		function() return false end,
	GetEffectName =        function() return "particles/items_fx/blademail.vpcf" end,
	GetEffectAttachType =  function() return PATTACH_ABSORIGIN end,
	GetStatusEffectName =  function() return "particles/status_fx/status_effect_blademail.vpcf" end,
	StatusEffectPriority = function() return 10 end,
})

if IsServer() then
	function modifier_item_sacred_blade_mail_active:DeclareFunctions()
		return { MODIFIER_EVENT_ON_TAKEDAMAGE }
	end

	function modifier_item_sacred_blade_mail_active:OnTakeDamage(keys)
		local unit = self:GetParent()
		local ability = self:GetAbility()
		if unit == keys.unit and SimpleDamageReflect(unit, keys.attacker, keys.damage * ability:GetSpecialValueFor("reflected_damage_pct") * 0.01, keys.damage_flags, ability, DAMAGE_TYPE_PURE) then
			keys.attacker:EmitSound("DOTA_Item.BladeMail.Damage")
		end
	end
end
