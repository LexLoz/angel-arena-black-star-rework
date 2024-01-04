LinkLuaModifier("modifier_item_elderberry_wand", "items/item_ultimate_scepter.lua", LUA_MODIFIER_MOTION_NONE)

item_elderberry_wand = class({
	GetIntrinsicModifierName = function() return "modifier_item_elderberry_wand" end,
})
function item_elderberry_wand:HasStaticCooldown() return true end

if IsServer() then
	function item_elderberry_wand:OnAbilityPhaseStart()
		--particles/units/heroes/hero_skeletonking/wraith_king_death_e_reincarnate.vpcf
		self:GetCaster():EmitSound("Arena.Items.Elderberry_Wand.Cast.Start")
		local timer = 1
		Timers:CreateTimer(function()
			ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
			timer = timer - 0.1
			if timer > 0 then return 0.1 end
		end)
		ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	end
	function item_elderberry_wand:OnSpellStart()
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()

		if not target:TriggerSpellAbsorb(self) and target:IsHero() then
			target:TriggerSpellReflect(self)

			local pfx = ParticleManager:CreateParticle("particles/econ/items/lion/lion_ti8/lion_spell_finger_of_death_charge_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
			caster:EmitSound("Arena.Items.Elderberry_Wand.Cast")
			Timers:CreateTimer(1, function()
				target:InstaKill(self, caster, false, nil, true)
			end)
		end
	end
end

modifier_item_elderberry_wand = class({
	RemoveOnDeath = function() return false end,
	IsHidden      = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	IsPurgable    = function() return false end,
})

function modifier_item_elderberry_wand:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_IS_SCEPTER,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
end

function modifier_item_elderberry_wand:GetModifierScepter()
	return 1
end

function modifier_item_elderberry_wand:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_elderberry_wand:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_elderberry_wand:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_elderberry_wand:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amp_pct")
end

function modifier_item_elderberry_wand:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_elderberry_wand:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_elderberry_wand:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_elderberry_wand:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_elderberry_wand:GetModifierCastRangeBonus()
	return self:GetAbility():GetSpecialValueFor("cast_range_bonus")
end

if IsServer() then
	function modifier_item_elderberry_wand:OnCreated()
		local parent = self:GetParent()
		for i = 0, parent:GetAbilityCount() - 1 do
			local ability = parent:GetAbilityByIndex(i)
			if ability and ability:GetKeyValue("IsGrantedByScepter") == 1 then
				if ability:GetKeyValue("ScepterGrantedLevel") ~= 0 then
					ability:SetLevel(1)
				end
				ability:SetHidden(false)
			end
		end
	end

	function modifier_item_elderberry_wand:OnDestroy()
		local parent = self:GetParent()
		if not parent:HasScepter() then
			for i = 0, parent:GetAbilityCount() - 1 do
				local ability = parent:GetAbilityByIndex(i)
				if ability and ability:GetKeyValue("IsGrantedByScepter") == 1 then
					if ability:GetKeyValue("ScepterGrantedLevel") ~= 0 then
						ability:SetLevel(0)
					end
					ability:SetHidden(true)
				end
			end
		end
	end
end
