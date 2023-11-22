LinkLuaModifier("modifier_item_unstable_quasar_passive", "items/item_unstable_quasar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_unstable_quasar_slow", "items/item_unstable_quasar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_unstable_quasar_aura", "items/item_unstable_quasar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_unstable_quasar_debuff", "items/item_unstable_quasar.lua", LUA_MODIFIER_MOTION_NONE)

item_unstable_quasar = class({
	GetIntrinsicModifierName = function() return "modifier_item_unstable_quasar_passive" end,
})

function item_unstable_quasar:GetManaCost()
	local caster = self:GetCaster()
	if not caster then return end

	local percentage = caster:GetMaxMana() * self:GetSpecialValueFor("manacost_pct") * 0.01
	return self:GetSpecialValueFor("manacost") + percentage
end

modifier_item_unstable_quasar_passive = class({
	IsHidden      = function() return true end,
	IsPurgable    = function() return false end,
	RemoveOnDeath = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
})

function modifier_item_unstable_quasar_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_BONUS_DAY_VISION,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end

if IsServer() then
	function modifier_item_unstable_quasar_passive:AddStacksToUnit(unit, stackCount)
		local ability = self:GetAbility()
		local parent = self:GetParent()
		if unit == parent then return end
		local duration = ability:GetSpecialValueFor("resist_decrease_duration")
		local debuff = unit:AddNewModifier(parent, ability, "modifier_item_unstable_quasar_debuff",
			{ duration = duration })
		if debuff then
			debuff:SetStackCount(debuff:GetStackCount() + stackCount)
			Timers:CreateTimer(duration, function()
				if IsValidEntity(unit) and debuff then
					debuff:SetStackCount(debuff:GetStackCount() - stackCount)
				end
			end)
			self.cooldown = true
			local cooldown = ability:GetSpecialValueFor("resist_decrease_cooldown")
			Timers:CreateTimer(cooldown, function()
				self.cooldown = false
			end)
		end
	end

	function modifier_item_unstable_quasar_passive:OnTakeDamage(keys)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local inflictor = keys.inflictor
		local unit = keys.unit
		if keys.attacker == parent and not self.cooldown then
			if inflictor and inflictor.GetName and inflictor:GetName() == "item_unstable_quasar" then return end
			self:AddStacksToUnit(unit, ability:GetSpecialValueFor("magic_resist_decrease_for_damage"))
		end
	end

	function modifier_item_unstable_quasar_passive:OnAbilityExecuted(keys)
		local caster = self:GetParent()
		if caster ~= keys.unit then return end
		local ability = self:GetAbility()
		local usedAbility = keys.ability
		local team = caster:GetTeam()
		local pos = caster:GetAbsOrigin()
		local radius = ability:GetSpecialValueFor("singularity_radius")

		if (
				(usedAbility:GetCooldown(usedAbility:GetLevel()) >= 0.1 or (usedAbility.GetAbilityChargeRestoreTime and usedAbility:GetAbilityChargeRestoreTime(usedAbility:GetLevel()) >= 0.1)) and
				usedAbility:GetManaCost(usedAbility:GetLevel()) ~= 0 and
				ability:PerformPrecastActions()
			) then
			for _, v in ipairs(FindUnitsInRadius(team, pos, nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)) do
				--debuff
				self:AddStacksToUnit(v, ability:GetSpecialValueFor("magic_resist_decrease_for_cast"))

				local enemyPos = v:GetAbsOrigin()
				local damage = (v:GetHealth() * ability:GetSpecialValueFor((caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT or caster:GetNetworkableEntityInfo("BonusPrimaryAttribute2")) and "intelligence_damage_pct" or "damage_pct") * 0.01) --* (1 + caster:GetSpellAmplification(false))

				--local spellamp = 1 + (caster:GetSpellAmplification(false) - (caster.DamageAmpPerAgility * 0.01))

				--ability.NoDamageAmp = true
				if not caster:FindModifierByName("sara_evolution_new") then
					ApplyDamage({
						attacker = caster,
						victim = v,
						damage = (ability:GetManaCost() * ability:GetSpecialValueFor("manacost_in_damage_pct") * 0.01),
						damage_type = ability:GetAbilityDamageType(),
						damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
						ability = ability
					})
				end
				ApplyDamage({
					attacker = caster,
					victim = v,
					damage = damage,
					damage_type = ability:GetAbilityDamageType(),
					damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
					ability = ability
				})

				local particle = ParticleManager:CreateParticle(
					"particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(
					particle,
					0,
					caster,
					PATTACH_POINT_FOLLOW,
					"attach_attack1",
					caster:GetAbsOrigin(),
					true
				)
				ParticleManager:SetParticleControl(particle, 1, enemyPos)

				if not v:IsMagicImmune() and not v:IsDebuffImmune() then
					v:AddNewModifier(caster, ability, "modifier_item_unstable_quasar_slow",
						{ duration = ability:GetSpecialValueFor("slow_duration") })
				end

				local direction = (pos - enemyPos):Normalized()
				local distance = ability:GetSpecialValueFor("offset_range")

				FindClearSpaceForUnit(v, GetGroundPosition(enemyPos + direction * distance, caster), true)
			end
		end
	end
end

function modifier_item_unstable_quasar_passive:GetBonusDayVision()
	return self:GetAbility():GetSpecialValueFor("bonus_day_vision")
end

function modifier_item_unstable_quasar_passive:GetBonusNightVision()
	return self:GetAbility():GetSpecialValueFor("bonus_night_vision")
end

function modifier_item_unstable_quasar_passive:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_unstable_quasar_passive:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amp_pct")
end

function modifier_item_unstable_quasar_passive:GetModifierAura()
	return "modifier_item_unstable_quasar_aura"
end

function modifier_item_unstable_quasar_passive:IsAura()
	return true
end

function modifier_item_unstable_quasar_passive:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_unstable_quasar_passive:GetAuraSearchTeam()
	return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_item_unstable_quasar_passive:GetAuraSearchType()
	return self:GetAbility():GetAbilityTargetType()
end

modifier_item_unstable_quasar_slow = class({
	IsHidden      = function() return false end,
	IsPurgable    = function() return true end,
	IsDebuff      = function() return true end,
	GetEffectName = function() return "particles/items_fx/diffusal_slow.vpcf" end,
})

function modifier_item_unstable_quasar_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_LIMIT }
end

function modifier_item_unstable_quasar_slow:GetModifierMoveSpeed_Limit()
	return self:GetAbility():GetSpecialValueFor("slow_speed")
end

modifier_item_unstable_quasar_aura = class({
	DeclareFunctions = function() return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end,
	GetPriority = function() return { MODIFIER_PRIORITY_HIGH } end,
})

function modifier_item_unstable_quasar_aura:GetModifierMagicalResistanceBonus()
	return -self:GetAbility():GetSpecialValueFor("aura_resist_debuff_pct")
end

if IsServer() then
	function modifier_item_unstable_quasar_aura:OnCreated()
		local owner = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		owner.truesight = owner:AddNewModifier(caster, ability, "modifier_truesight", nil)

		if caster:IsRealHero() and owner:IsTrueHero() then
			owner.GemOfPureSoulCooldownsWorldpanel = WorldPanels:CreateWorldPanelForTeam(caster:GetTeamNumber(), {
				layout = "file://{resources}/layout/custom_game/worldpanels/abilitycooldowns.xml",
				entity = owner,
				entityHeight = 210,
				data = { hasHealthBar = not owner:NoHealthBar() }
			})
		end

		if owner:IsIllusion() and caster:IsRealHero() then
			owner.GemOfClearMindIllusionParticle = ParticleManager:CreateParticleForTeam(
				"particles/arena/items_fx/gem_of_clear_mind_illusion.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner,
				caster:GetTeamNumber())
		end
	end

	function modifier_item_unstable_quasar_aura:OnDestroy()
		local target = self:GetParent()
		if not target.truesight:IsNull() then target.truesight:Destroy() end

		if target.GemOfPureSoulCooldownsWorldpanel then
			target.GemOfPureSoulCooldownsWorldpanel:Delete()
			target.GemOfPureSoulCooldownsWorldpanel = nil
		end

		if target.GemOfClearMindIllusionParticle then
			ParticleManager:DestroyParticle(target.GemOfClearMindIllusionParticle, false)
			target.GemOfClearMindIllusionParticle = nil
		end
	end
end

modifier_item_unstable_quasar_debuff = class({
	RemoveOnDeath    = function() return false end,
	IsHidden         = function() return false end,
	IsPurgable       = function() return false end,
	IsDebuff         = function() return true end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_TOOLTIP
		}
	end,
})

function modifier_item_unstable_quasar_debuff:GetModifierMagicalResistanceBonus()
	return -math.ceil(self:GetStackCount() / 2)
end

function modifier_item_unstable_quasar_debuff:GetModifierMagicalResistanceDirectModification()
	return -math.floor(self:GetStackCount() / 2)
end

function modifier_item_unstable_quasar_debuff:OnTooltip()
	return self:GetStackCount()
end
