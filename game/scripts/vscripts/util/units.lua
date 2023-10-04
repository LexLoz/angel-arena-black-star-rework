--Entity
function CEntityInstance:SetNetworkableEntityInfo(key, value)
	local t = CustomNetTables:GetTableValue("custom_entity_values", tostring(self:GetEntityIndex())) or {}
	t[key] = value
	CustomNetTables:SetTableValue("custom_entity_values", tostring(self:GetEntityIndex()), t)
end

function CEntityInstance:ClearNetworkableEntityInfo()
	CustomNetTables:SetTableValue("custom_entity_values", tostring(self:GetEntityIndex()), nil)
end

function CEntityInstance:CutTreeOrWard(caster, ability)
	if self:GetClassname() == "ent_dota_tree" then
		self:CutDown(caster:GetTeamNumber())
	elseif self:IsCustomWard() then
		self:TrueKill(ability, caster)
	end
end

--NPC
function CDOTA_BaseNPC:IsRealCreep()
	return self.SSpawner ~= nil and self.SpawnerType ~= nil
end

function CDOTA_BaseNPC:GetFullName()
	return self.UnitName or (self.GetUnitName and self:GetUnitName()) or self:GetName()
end

function CDOTA_BaseNPC:DestroyAllModifiers()
	for _, v in ipairs(self:FindAllModifiers()) do
		if not UNDESTROYABLE_MODIFIERS[v:GetName()] then
			v:Destroy()
		end
	end
end

function CDOTA_BaseNPC:HasModelChanged()
	if self:HasModifier("modifier_terrorblade_metamorphosis") or self:HasModifier("modifier_monkey_king_transform") or self:HasModifier("modifier_lone_druid_true_form") then
		return true
	end
	for _, modifier in ipairs(self:FindAllModifiers()) do
		if modifier.DeclareFunctions and table.includes(modifier:DeclareFunctions(), MODIFIER_PROPERTY_MODEL_CHANGE) then
			if modifier.GetModifierModelChange and modifier:GetModifierModelChange() then
				return true
			end
		end
	end
	return false
end

local TELEPORT_MAX_COLLISION_RANGE = 256
function CDOTA_BaseNPC:Teleport(position)
	self.TeleportPosition = position
	self:Stop()

	local playerId = self:GetPlayerOwnerID()
	PlayerResource:SetCameraTarget(playerId, self)

	FindClearSpaceForUnit(self, position, true)

	Timers:CreateTimer(0.1, function()
		if not IsValidEntity(self) then return end
		if self.TeleportPosition ~= position then return end
		if (self:GetAbsOrigin() - position):Length2D() > TELEPORT_MAX_COLLISION_RANGE then
			FindClearSpaceForUnit(self, position, true)
			return 0.1
		end

		self.TeleportPosition = nil
		PlayerResource:SetCameraTarget(playerId, nil)
		self:Stop()
	end)
end

function CDOTA_BaseNPC:IsRangedUnit()
	return self:IsRangedAttacker() or self:HasModifier("modifier_terrorblade_metamorphosis_transform_aura_applier")
end

function CDOTA_BaseNPC:TrueKill(ability, killer)
	self.IsMarkedForTrueKill = true
	if self:HasAbility("skeleton_king_reincarnation") then
		self:FindAbilityByName("skeleton_king_reincarnation"):StartCooldown(1 / 30)
	end
	self:Kill(ability, killer)
	if IsValidEntity(self) and self:IsAlive() then
		self:RemoveDeathPreventingModifiers()
		self:Kill(ability, killer)
	end
	self.IsMarkedForTrueKill = false
end

function CDOTA_BaseNPC:InstaKill(ability, killer, dealDamageIfFail, ignoreResist, createParticle)
	if self:IsInvulnerable() then return false end
	local chance = math.min(100,
		math.max(0, 100 - (self:GetInstakillResist() - math.abs(ignoreResist or 0))) -
		self:GetSpellAmplification(false) * 100 * 0.05)
	local c = 0

	local victim_atsum = self:GetAttributesSum()
	local killer_atsum = killer:GetAttributesSum()
	local difference = 2
	local max_bonus = 50
	local diff

	if killer_atsum <= victim_atsum then
		diff = victim_atsum / killer_atsum
		if diff >= difference then
			chance = chance - max_bonus
		else
			diff = 1 - killer_atsum / victim_atsum
			chance = chance - max_bonus * diff
		end
	end

	if killer_atsum > victim_atsum then
		diff = killer_atsum / victim_atsum
		if diff >= difference then
			chance = chance + max_bonus
		else
			diff = 1 - victim_atsum / killer_atsum
			chance = chance + max_bonus * diff
		end
	end

	--print("victim_atsum: " .. victim_atsum)
	--print("killer_atsum: " .. killer_atsum)
	--print(chance)

	local function CreateParticles()
		if createParticle then
			self:EmitSound("Hero_Chen.HandOfGodHealHero")
			local pfx = ParticleManager:CreateParticle(
				"particles/econ/items/dazzle/dazzle_dark_light_weapon/dazzle_dark_shallow_grave.vpcf",
				PATTACH_ABSORIGIN_FOLLOW, self)
			Timers:CreateTimer(2, function()
				ParticleManager:DestroyParticle(pfx, true)
			end)
		end
	end
	local chances = 3
	for i = 1, chances do
		if RollPercentage(chance) then
			c = c + 1
		end
	end
	if c == chances then
		self:FixedKill(ability, killer)
		return true
	elseif dealDamageIfFail then
		local needed_health = self:GetHealth() * (100 - chance) * 0.01
		local damage = self:GetHealth() - needed_health
		--print(damage)
		ApplyInevitableDamage(killer, self, ability, damage, false)
		self:SetHealth(self:GetHealth() * (100 - chance) * 0.01)
		CreateParticles()
		return false
	else
		CreateParticles()
		return false
	end
end

function CDOTA_BaseNPC:FixedKill(ability, killer)
	self:SetHealth(1)
	self:Kill(ability, killer)
end

function CDOTA_BaseNPC:GetLinkedHeroNames()
	return HeroSelection:GetLinkedHeroNames(self:GetFullName())
end

function CDOTA_BaseNPC:UpdateAttackProjectile()
	local projectile
	for i = #ATTACK_MODIFIERS, 1, -1 do
		local attack_modifier = ATTACK_MODIFIERS[i]
		local apply = true
		if attack_modifier.modifiers then
			for _, v in ipairs(attack_modifier.modifiers) do
				if not self:HasModifier(v) then
					apply = false
					break
				end
			end
		end
		if apply and attack_modifier.modifier then
			apply = self:HasModifier(attack_modifier.modifier)
		end
		if apply then
			projectile = attack_modifier.projectile
			break
		end
	end
	projectile = projectile or self:GetKeyValue("ProjectileModel")
	self:SetRangedProjectileName(projectile)
	return projectile
end

function CDOTA_BaseNPC:ModifyPlayerStat(key, value)
	if self.GetPlayerOwnerID and self:GetPlayerOwnerID() > -1 then
		return PlayerResource:ModifyPlayerStat(self:GetPlayerOwnerID(), key, value)
	end
end

function CDOTA_BaseNPC:IsTrueHero()
	return self:IsRealHero() and not self:IsTempestDouble() and not self:IsWukongsSummon()
end

function CDOTA_BaseNPC:IsMainHero()
	return self:IsRealHero() and self == PlayerResource:GetSelectedHeroEntity(self:GetPlayerID())
end

function CDOTA_BaseNPC:AddNewAbility(ability_name, skipLinked)
	local hAbility = self:AddAbility(ability_name)
	hAbility:ClearFalseInnateModifiers()
	local linked
	local link = LINKED_ABILITIES[ability_name]
	if link and not skipLinked then
		linked = {}
		for _, v in ipairs(link) do
			local h = self:AddNewAbility(v)
			table.insert(linked, h)
		end
	end
	if hAbility.Spawn then
		hAbility:Spawn()
	end
	return hAbility, linked
end

function CDOTA_BaseNPC:IsWukongsSummon()
	return self:IsHero() and (
		self:HasModifier("modifier_monkey_king_fur_army_soldier") or
		self:HasModifier("modifier_monkey_king_fur_army_soldier_inactive") or
		self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")
	)
end

function CDOTA_BaseNPC:GetIllusionParent()
	-- TODO: make a correct fix for standard illusions
	if not self.isCustomIllusion then return end
	local modifier_illusion = self:FindModifierByName("modifier_illusion")
	if modifier_illusion then
		return modifier_illusion:GetCaster()
	end
end

function CDOTA_BaseNPC:AddEndChannelListener(listener)
	local endChannelListeners = self.EndChannelListeners or {}
	self.EndChannelListeners = endChannelListeners
	local index = #endChannelListeners + 1
	endChannelListeners[index] = listener
end

--Hero
function CDOTA_BaseNPC_Hero:CalculateRespawnTime()
	if self.OnDuel then return 1 end
	local time = (5 + self:GetLevel() * 0.2)
	if self.talent_keys and self.talent_keys.respawn_time_reduction then
		time = time + self.talent_keys.respawn_time_reduction
	end
	local death_resist = self:GetInstakillResist() * 0.75
	local gauntlet_debuff = self:HasModifier("modifier_item_infinity_gauntlet_dusting") and 50 or 0

	--[[local bloodstone = self:FindItemInInventory("item_bloodstone")
	if bloodstone then
		time = time - bloodstone:GetCurrentCharges() * bloodstone:GetSpecialValueFor("respawn_time_reduction")
	end]]

	return math.max(time * (1 - death_resist * 0.01) + gauntlet_debuff, 5)
end

function CDOTA_BaseNPC_Hero:GetTotalHealthReduction()
	local pct = self:GetModifierStackCount("modifier_kadash_immortality_health_penalty", self)
	local mod = self:FindModifierByName("modifier_stegius_brightness_of_desolate_effect")
	if mod then
		pct = pct + mod:GetAbility():GetAbilitySpecial("health_decrease_pct")
	end

	--[[local sara_evolution = self:FindAbilityByName("sara_evolution")
	if sara_evolution then
		local dec = sara_evolution:GetSpecialValueFor("health_reduction_pct")
		return dec + ((100-dec) * pct * 0.01)
	end]]
	--[[local space_st = self:FindModifierByName("modifier_space_stone"):GetAbility()
	if space_st then
		pct = pct - space_st:GetAbilitySpecial("all_energies_bonus_pct")
	end]]
	return pct
end

function CDOTA_BaseNPC_Hero:CalculateHealthReduction()
	self:CalculateStatBonus(true)
	local pct = self:GetTotalHealthReduction()
	self:SetMaxHealth(pct >= 100 and 1 or self:GetMaxHealth() - pct * (self:GetMaxHealth() / 100))
end

function CDOTA_BaseNPC_Hero:ResetAbilityPoints()
	self:SetAbilityPoints(self:GetLevel() - self:GetAbilityPointsWastedAllOnTalents())
end

function CDOTA_BaseNPC_Hero:GetAttribute(attribute)
	if attribute == DOTA_ATTRIBUTE_STRENGTH then
		return self:GetStrength()
	elseif attribute == DOTA_ATTRIBUTE_AGILITY then
		return self:GetAgility()
	elseif attribute == DOTA_ATTRIBUTE_INTELLECT then
		return self:GetIntellect()
	end
end

function CDOTA_BaseNPC_Hero:GetAttributesSum()
	return self:GetStrength() + self:GetAgility() + self:GetIntellect()
end

function CDOTA_BaseNPC_Hero:GetUniversalAttribute()
	if self:HasModifier("modifier_universal_attribute") then
		return (self:GetAttributesSum()) * UNIVERSALES_MULTIPLIER
	else
		return false
	end
end

function CDOTA_BaseNPC_Hero:IsGenocideMode(ability, isDodgeCooldown)
	if not ability and not isDodgeCooldown then
		return self:HasModifier("modifier_sans_genocide_mod")
	end
	if self:HasModifier("modifier_sans_genocide_mod") and isDodgeCooldown then
		return 1 +
			self:FindModifierByName("modifier_sans_genocide_mod"):GetAbility():GetSpecialValueFor(
				"charge_gain_increase_pct") *
			0.01
	elseif not self:HasModifier("modifier_sans_genocide_mod") and isDodgeCooldown then
		return 1
	end
	if ability and self:HasModifier("modifier_sans_genocide_mod") then
		return 1 + ((ability:GetSpecialValueFor("genocide_bonus_pct") * 0.01) or 0)
	else
		return 1
	end
end

function CDOTA_BaseNPC_Hero:HasShard()
	if self:HasModifier("modifier_item_aghanims_shard") then
		return true
	end

	return false
end

function CDOTA_BaseNPC_Hero:GetNetWorth()
	local att_cost = 200

	local shardsGold = (self.Additional_str or 0) * att_cost + (self.Additional_agi or 0) * att_cost +
		(self.Additional_int or 0) * att_cost
	local itemsCost = 0
	for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_TP_SCROLL do
		local item = self:GetItemInSlot(item_slot)
		if item then
			itemsCost = itemsCost + GetTrueItemCost(item:GetAbilityName())
		end
	end
	return shardsGold + Gold:GetGold(self:GetPlayerID()) + itemsCost
end

function CDOTA_BaseNPC:GetElementalResist(element)
	if not self:IsHero() then return 0 end
	local unit = UNITS_LIST[self:GetFullName()]
	local resists
	local condition_curse = (self:HasModifier("modifier_item_demon_king_bar_curse"))
	local condition_hex = self:IsHexed()
	if unit and unit.DamageSubtypeResistance then
		resists = unit.DamageSubtypeResistance
	else
		return 0
	end
	if condition_curse and type(resists[element]) == "number" and resists[element] > 0 then
		return -1 * resists[element]
	elseif condition_curse and type(resists[element]) == "number" and resists[element] < 0 then
		return resists[element]
	elseif condition_hex and type(resists[element]) == "number" and (resists[element] > 0 or resists[element] < 0) then
		return 0
	end
	return resists[element]
end

function CDOTA_BaseNPC:GetInstakillResist()
	local magic_resist = (self:Script_GetMagicalArmorValue(false, nil) or 0) * 100 * 0.75
	local status_resist = (self:GetStatusResistance() or 0) * 100 * 0.6

	local death_resist
	local unit = UNITS_LIST[self:GetFullName()]
	if unit and unit.DamageSubtypeResistance and unit.DamageSubtypeResistance['DAMAGE_SUBTYPE_DEATH'] then
		death_resist = unit.DamageSubtypeResistance['DAMAGE_SUBTYPE_DEATH']
	else
		death_resist = 0
	end
	--local level = self:GetLevel() * 0.02

	local sum = magic_resist + status_resist + death_resist --+ level
	--print(sum)
	return math.max(0, sum)
end

function CDOTA_BaseNPC_Hero:GetBonusStrength()
	return math.max(0, self:GetStrength() - self:GetBaseStrength() - (self:HasModifier("modifier_talent_bonus_all_stats") and
		self:FindModifierByName("modifier_talent_bonus_all_stats"):GetStackCount()
		or 0))
end

function CDOTA_BaseNPC_Hero:GetBonusAgility()
	return math.max(0, self:GetAgility() - self:GetBaseAgility() - (self:HasModifier("modifier_talent_bonus_all_stats") and
		self:FindModifierByName("modifier_talent_bonus_all_stats"):GetStackCount()
		or 0))
end

function CDOTA_BaseNPC_Hero:GetBonusIntellect()
	return math.max(0, self:GetIntellect() - self:GetBaseIntellect() - (self:HasModifier("modifier_talent_bonus_all_stats") and
		self:FindModifierByName("modifier_talent_bonus_all_stats"):GetStackCount()
		or 0))
end

function CDOTA_BaseNPC_Hero:GetUnreliableStrength()
	local stat_per_level = CalculateStatForLevel(self, DOTA_ATTRIBUTE_STRENGTH, STAT_GAIN_LEVEL_LIMIT, true)
	local bonus_stat = self:GetBonusStrength() < RELIABLE_BONUS_STAT_LIMIT and
		self:GetBonusStrength() or
		RELIABLE_BONUS_STAT_LIMIT
	return self:GetStrength() - stat_per_level - bonus_stat
end

function CDOTA_BaseNPC_Hero:GetUnreliableAgility()
	local stat_per_level = CalculateStatForLevel(self, DOTA_ATTRIBUTE_AGILITY, STAT_GAIN_LEVEL_LIMIT, true)
	local bonus_stat = self:GetBonusAgility()

	local marksmanship = self:FindModifierByName("modifier_drow_ranger_marksmanship_aura_bonus")
	if marksmanship then
		local ability = marksmanship:GetAbility()
		local owner = ability:GetCaster()
		local pct = ability:GetSpecialValueFor("agility_multiplier")
		local decrease_for_allies = ability:GetSpecialValueFor("agility_multiplier_ally")
		local mult = 1

		if self == owner then
			mult = 1 + pct * 0.01
		else
			mult = 1 + (pct * decrease_for_allies * 0.01) * 0.01
		end


		local m_bonus = owner:GetAgility() - (owner:GetAgility() / mult)

		bonus_stat = bonus_stat - m_bonus < RELIABLE_BONUS_STAT_LIMIT and
			bonus_stat - m_bonus or
			RELIABLE_BONUS_STAT_LIMIT

		--print(m_bonus)
	end
	return self:GetAgility() - stat_per_level - bonus_stat
end

function CDOTA_BaseNPC_Hero:GetUnreliableIntellect()
	local stat_per_level = CalculateStatForLevel(self, DOTA_ATTRIBUTE_INTELLECT, STAT_GAIN_LEVEL_LIMIT, true)
	local bonus_stat = self:GetBonusIntellect() < RELIABLE_BONUS_STAT_LIMIT and
		self:GetBonusIntellect() or
		RELIABLE_BONUS_STAT_LIMIT
	return self:GetIntellect() - stat_per_level - bonus_stat
end

function CDOTA_BaseNPC_Hero:GetReliableStrength()
	return self:GetStrength() - self:GetUnreliableStrength()
end

function CDOTA_BaseNPC_Hero:GetReliableAgility()
	return self:GetAgility() - self:GetUnreliableAgility()
end

function CDOTA_BaseNPC_Hero:GetReliableIntellect()
	return self:GetIntellect() - self:GetUnreliableIntellect()
end

function CDOTA_BaseNPC_Hero:GetBonusDamage()
	local base_damage = (self:GetBaseDamageMin() + self:GetBaseDamageMax()) / 2
	--print(self:GetAverageTrueAttackDamage(self) - base_damage)
	local bonus_damage = self:GetAverageTrueAttackDamage(self) - base_damage
	return math.max(0, bonus_damage)
end

function CDOTA_BaseNPC_Hero:GetUnreliableBonusDamage()
	local bonus_damage = self:GetBonusDamage()
	return (bonus_damage > 1000 and
	bonus_damage - 1000 or 0)
end

function CDOTA_BaseNPC_Hero:GetUnreliableBaseDamage()
	return math.max(0, (self:GetUnreliableStrength() +
	CalculateStatForLevel(self, DOTA_ATTRIBUTE_STRENGTH, STAT_GAIN_LEVEL_LIMIT, true) -
	CalculateStatForLevel(self, DOTA_ATTRIBUTE_STRENGTH, 600, true)) * 0.5 * self.BaseDamagePerStrength)
end

function CDOTA_BaseNPC_Hero:GetReliableDamage()
	if not self:IsHero() then return 0 end
	local unreliable_damage = self:GetUnreliableBaseDamage() + self:GetUnreliableBonusDamage()
	-- print(damage)
	return self:GetAverageTrueAttackDamage(self) - unreliable_damage
end

--[[function CDOTA_BaseNPC_Hero:GetStrengthGain()

end

function CDOTA_BaseNPC_Hero:GetAgilityGain()

end

function CDOTA_BaseNPC_Hero:GetIntellectGain()

end]]
