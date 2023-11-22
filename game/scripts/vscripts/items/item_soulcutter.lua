LinkLuaModifier("modifier_item_soulcutter", "items/item_soulcutter.lua", LUA_MODIFIER_MOTION_NONE)
-- LinkLuaModifier("modifier_item_soulcutter_windwalk", "items/item_soulcutter.lua", LUA_MODIFIER_MOTION_NONE)
-- LinkLuaModifier("modifier_item_soulcutter_hex", "items/item_soulcutter.lua", LUA_MODIFIER_MOTION_NONE)


item_soulcutter = {
	GetIntrinsicModifierName = function() return "modifier_item_soulcutter" end,
	HasStaticCooldown  		 = function() return true end
}

-- if IsServer() then
-- 	function item_soulcutter:OnSpellStart()
-- 		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_edge_of_vyse_active",
-- 			{ duration = self:GetSpecialValueFor("windwalk_duration") })
-- 	end
-- end

modifier_item_soulcutter = {
	IsHidden          = function() return true end,
	GetAttributes     = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	IsPurgable        = function() return false end,

	IsAura            = function() return true end,
	GetModifierAura   = function() return "modifier_item_soulcutter_aura_effect" end,
	GetAuraRadius     = function(self) return self:GetAbility():GetSpecialValueFor("aura_radius") end,
	GetAuraSearchTeam = function() return DOTA_UNIT_TARGET_TEAM_ENEMY end,
	GetAuraSearchType = function() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end,

	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ATTACK_START,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		}
	end,

	-- GetModifierPreAttack_BonusDamage = function(self) return self:GetAbility():GetSpecialValueFor("bonus_damage") end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end,
	GetModifierAttackRangeBonus = function(self) return self:GetAbility():GetSpecialValueFor("bonus_attack_range") end,
}

if IsServer() then
	function modifier_item_soulcutter:GetModifierPreAttack_BonusDamage()
		if IsValidEntity(self.BonusDamageTarget) then
			return self:GetAbility():GetSpecialValueFor("bonus_damage") + self:GetParent().SoulcutterBonusDamage
		end
	end
	function modifier_item_soulcutter:OnAttackStart(keys)
		if keys.attacker == self:GetParent() then
			if IsModifierStrongest(keys.attacker, self:GetName(), MODIFIER_PROC_PRIORITY.pure_damage) then
				if keys.target:IsBoss() then
					self.BonusDamageTarget = keys.target
					keys.attacker.SoulcutterBonusDamage = self.BonusDamageTarget:GetHealth() * self:GetAbility():GetSpecialValueFor("max_health_damage") * 0.01 * 0.05
				else
					self.BonusDamageTarget = keys.target
					keys.attacker.SoulcutterBonusDamage = self.BonusDamageTarget:GetHealth() * self:GetAbility():GetSpecialValueFor("max_health_damage") * 0.01
				end
			end
		end
	end
	function modifier_item_soulcutter:OnAttackLanded(keys)
		--if self:GetParent().bonus_attack then return end
		local attacker = keys.attacker
		if attacker ~= self:GetParent() then return end
		local ability = self:GetAbility()
		local target = keys.target

		if attacker:FindAllModifiersByName(self:GetName())[1] ~= self then return end

		if attacker:IsIllusion() then return end

		ParticleManager:CreateParticle("particles/arena/items_fx/dark_flow_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW,
			target)

		if target:IsAlive() and ability:IsCooldownReady() then
			local modifier = target:AddNewModifier(
				target,
				ability,
				"modifier_item_soulcutter_stack",
				{
					duration = ability:GetSpecialValueFor("duration")
				}
			)
			modifier:IncrementStackCount()
			ability:StartCooldown(ability:GetSpecialValueFor("cooldown"))
		end
	end
else
	function modifier_item_soulcutter:GetModifierPreAttack_BonusDamage()
		return self:GetAbility():GetSpecialValueFor("bonus_damage")
	end
end


LinkLuaModifier("modifier_item_soulcutter_aura_effect", "items/item_soulcutter.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_soulcutter_aura_effect = {
	DeclareFunctions = function() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end,
	GetModifierPhysicalArmorBonus = function(self) return self:GetAbility():GetSpecialValueFor("aura_armor_reduction") end,
}


LinkLuaModifier("modifier_item_soulcutter_stack", "items/item_soulcutter.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_soulcutter_stack = {
	IsPurgable = function() return false end,
	IsDebuff = function() return true end,
	DeclareFunctions = function()
		return {
			-- MODIFIER_PROPERTY_TOOLTIP,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		}
	end,
}

function modifier_item_soulcutter_stack:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_per_hit") * self:GetStackCount() -- self:GetParent():GetNetworkableEntityInfo('IdealArmor') * 0.02 * self:GetStackCount()
end
