LinkLuaModifier("modifier_boss_cursed_zeld_shadows_curse", "heroes/bosses/cursed_zeld/shadows_curse.lua", LUA_MODIFIER_MOTION_NONE)

boss_cursed_zeld_shadows_curse = {
	GetIntrinsicModifierName = function() return "modifier_boss_cursed_zeld_shadows_curse" end,
}


modifier_boss_cursed_zeld_shadows_curse = {
	IsPurgable = function() return false end,
}

if IsServer() then
	function modifier_boss_cursed_zeld_shadows_curse:DeclareFunctions()
		return {
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_MIN_HEALTH,
		}
	end

	function modifier_boss_cursed_zeld_shadows_curse:OnTakeDamage(keys)
		local parent = keys.unit
		if parent ~= self:GetParent() then return end

		local ability = self:GetAbility()
		if not ability:IsActivated() then return end

		local healthThreshold = ability:GetSpecialValueFor("health_threshold") --* parent:GetMaxHealth() * 0.01
		local health = parent:GetMaxHealth() - healthThreshold
		if parent:GetHealth() > health then return end

		local isFinalSplit = health <= healthThreshold
		--local clones_limit = ability:GetSpecialValueFor("max_clones_count")
		local armorDamageMultiplier = ability:GetSpecialValueFor("clone_damage_armor_pct") * 0.01
		local armor = parent:GetPhysicalArmorBaseValue() * armorDamageMultiplier
		local damageMin = parent:GetBaseDamageMin() * armorDamageMultiplier
		local damageMax = parent:GetBaseDamageMax() * armorDamageMultiplier
		local resist = parent:Script_GetMagicalArmorValue(false, nil) * 100
		print(resist)
		local modelScale = parent:GetModelScale() - ability:GetSpecialValueFor("clone_model_scale_reduction")

		ability:SetActivated(false)
		parent:SetDeathXP(0)
		parent:TrueKill(ability, parent)

		local direction = RandomVector(150)

		--if self:GetClonesCount() < clones_limit then
			for i = -1, 1, 2 do
				local spawnPosition = parent:GetAbsOrigin() + direction * i
				local clone = CreateUnitByName(parent:GetUnitName(), spawnPosition, true, nil, nil, parent:GetTeamNumber())
				clone.SpawnerEntity = parent.SpawnerEntity
				clone:SetBaseMaxHealth(health)
				clone:SetMaxHealth(health)
				clone:SetHealth(health)
				clone:SetPhysicalArmorBaseValue(armor)
				clone:SetBaseMagicalResistanceValue(resist)
				clone:SetBaseDamageMin(damageMin)
				clone:SetBaseDamageMax(damageMax)
				clone:SetModelScale(modelScale)

				if isFinalSplit then
					clone.isFinalClone = true
					local cloneAbility = clone:FindAbilityByName("boss_cursed_zeld_shadows_curse")
					cloneAbility:SetActivated(false)
				end

				for i = 0, clone:GetAbilityCount() - 1 do
					local cloneAbility = clone:GetAbilityByIndex(i)
					local parentAbility = parent:GetAbilityByIndex(i)
					if cloneAbility and parentAbility then
						cloneAbility:StartCooldown(parentAbility:GetCooldownTimeRemaining() / 2)
					end
				end

				Bosses:MakeBossAI(clone, "cursed_zeld", { spawnPos = parent.ai.spawnPos + direction * i })
			end
		--end
	end

	function modifier_boss_cursed_zeld_shadows_curse:GetClonesCount()
		return #Entities:FindAllByName(self:GetParent():GetUnitName())
	end

	function modifier_boss_cursed_zeld_shadows_curse:GetMinHealth()
		return self:GetAbility():IsActivated() and 1 or 0
	end
end
