LinkLuaModifier("modifier_item_scythe_of_the_ancients_passive", "items/item_scythe_of_the_ancients.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_scythe_of_the_ancients_stun", "items/item_scythe_of_the_ancients.lua", LUA_MODIFIER_MOTION_NONE)

item_scythe_of_the_ancients = class({
	GetIntrinsicModifierName = function() return "modifier_item_scythe_of_the_ancients_passive" end,
})
function item_scythe_of_the_ancients:HasStaticCooldown() return true end

if IsServer() then
	function item_scythe_of_the_ancients:OnSpellStart()
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()

		if not target:TriggerSpellAbsorb(self) then
			target:TriggerSpellReflect(self)

			local particle = ParticleManager:CreateParticle("particles/econ/events/ti4/dagon_beam_black_ti4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
			ParticleManager:SetParticleControl(particle, 1, Vector(800))
			caster:EmitSound("DOTA_Item.Dagon.Activate")
			target:EmitSound("DOTA_Item.Dagon5.Target")
			caster:EmitSound("Hero_Necrolyte.ReapersScythe.Cast")
			target:EmitSound("Hero_Necrolyte.ReapersScythe.Target")

			local units = FindUnitsInRadius(
				caster:GetTeam(),
				target:GetAbsOrigin(),
				nil,
				self:GetSpecialValueFor("kill_creeps_radius"),
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_CREEP,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false)
	
			for _,v in pairs(units) do
				v:Kill(self, caster)
			end

			ApplyDamage({
				attacker = caster,
				victim = target,
				damage = self:GetSpecialValueFor("cast_damage") + (self:GetSpecialValueFor("cast_damage_pct") * target:GetHealth() * 0.01),
				damage_type = self:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = self
			})
			target:AddNewModifier(caster, self, "modifier_item_scythe_of_the_ancients_stun", {duration = self:GetSpecialValueFor("stun_duration")})
		end
	end
end


modifier_item_scythe_of_the_ancients_passive = class({
	RemoveOnDeath = function() return false end,
	IsHidden      = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	IsPurgable    = function() return false end,
})

function modifier_item_scythe_of_the_ancients_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_IS_SCEPTER,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierScepter()
	return 1
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amp_pct")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_scythe_of_the_ancients_passive:GetModifierCastRangeBonus()
	return self:GetAbility():GetSpecialValueFor("cast_range_bonus")
end

if IsServer() then
	function modifier_item_scythe_of_the_ancients_passive:OnCreated()
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

	function modifier_item_scythe_of_the_ancients_passive:OnDestroy()
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

	function modifier_item_scythe_of_the_ancients_passive:OnTakeDamage(keys)
		--[[local parent = self:GetParent()
		local damage = keys.original_damage
		local ability = self:GetAbility()
		if keys.attacker == parent and not keys.unit:IsMagicImmune() and keys.damage_type == 2 and not (keys.inflictor and keys.inflictor:GetAbilityName() == "batrider_sticky_napalm") then
			ability.originalInflictor = keys.inflictor
			ApplyDamage({
				attacker = parent,
				victim = keys.unit,
				damage = 0, --keys.original_damage * ability:GetSpecialValueFor("magic_damage_to_pure_pct") * 0.01,
				damage_type = ability:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = ability
			})
		end]]
	end
end


modifier_item_scythe_of_the_ancients_stun = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
})

if IsServer() then
	function modifier_item_scythe_of_the_ancients_stun:OnCreated()
		local parent = self:GetParent()
		self.particle = ParticleManager:CreateParticle("particles/arena/items_fx/scythe_of_the_ancients_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	end

	function modifier_item_scythe_of_the_ancients_stun:OnDestroy()
		local ability = self:GetAbility()
		local caster = self:GetCaster()
		local target = self:GetParent()
		local team = caster:GetTeamNumber()
		ParticleManager:DestroyParticle(self.particle, false)
		local damage = (target:GetMaxHealth() - target:GetHealth()) * ability:GetSpecialValueFor("delayed_damage_per_health")

		local missing_health_pct = 100 - target:GetHealth() / target:GetMaxHealth() * 100
		Timers:CreateTimer(0.5, function()
			target:InstaKill(ability, caster, true, missing_health_pct * ability:GetSpecialValueFor("delayed_damage_per_health"))
		end)
		--[[ApplyDamage({
			attacker = caster,
			victim = target,
			damage = damage,
			damage_type = ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			ability = ability
		})]]
	end
end

function modifier_item_scythe_of_the_ancients_stun:CheckState()
	return {
		[ MODIFIER_STATE_STUNNED ] = true,
		[ MODIFIER_STATE_PROVIDES_VISION ] = true,
	}
end
