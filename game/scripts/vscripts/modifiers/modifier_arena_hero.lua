modifier_arena_hero = class({
	IsPurgable      = function() return false end,
	IsHidden        = function() return true end,
	RemoveOnDeath   = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	GetTexture      = function() return "attribute_abilities/clue" end,
	DestroyOnExpire = function() return false end,
})

function modifier_arena_hero:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_START,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_RESPAWN,
		MODIFIER_EVENT_ON_ABILITY_END_CHANNEL,
		MODIFIER_EVENT_ON_ATTACK_LANDED,

		MODIFIER_PROPERTY_REFLECT_SPELL,
		MODIFIER_PROPERTY_ABSORB_SPELL,
		MODIFIER_PROPERTY_ABILITY_LAYOUT,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,

		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,

		MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER,

		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION
	}
end

if IsClient() then
	function modifier_arena_hero:GetModifierSpellAmplify_Percentage()
		return self:GetParent():GetNetworkableEntityInfo("SpellAmp")
	end

	function modifier_arena_hero:GetModifierPreAttack_BonusDamage()
		return self:GetParent():GetNetworkableEntityInfo("BonusAgilityDamage")
	end
end
function modifier_arena_hero:GetModifierMagicalResistanceDirectModification()
	return -math.max(0, self:GetParent():GetIntellect()) * 0.1
end

if IsServer() then
	function modifier_arena_hero:GetModifierConstantHealthRegen()
		return (self:GetParent():GetStrength() - self:GetParent():GetUnreliableStrength()) * 0.1 -
			self:GetParent():GetStrength() * 0.1 --+ (self:GetParent().custom_regen or 0)
	end

	function modifier_arena_hero:GetModifierConstantManaRegen()
		return (self:GetParent():GetIntellect() - self:GetParent():GetUnreliableIntellect()) * 0.05 -
			self:GetParent():GetIntellect() * 0.05 --+ (self:GetParent().custom_mana_regen or 0)
	end

	function modifier_arena_hero:GetModifierStatusResistanceCaster()
		return (1 - GetLowManaMultiplier(self:GetParent().DamageMultiplier, self:GetParent(), SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD, SPEND_MANA_PER_DAMAGE_MAX_REDUCE_THRESHOLD)) *
			100
	end
end

function modifier_arena_hero:GetModifierAbilityLayout()
	return self.VisibleAbilitiesCount or self:GetSharedKey("VisibleAbilitiesCount") or 4
end

function modifier_arena_hero:GetModifierAttackSpeedBonus_Constant()
	return self:GetParent():GetNetworkableEntityInfo("ReturnedAttackSpeed")
end

if IsServer() then
	modifier_arena_hero.HeroLevel = 1
	function modifier_arena_hero:OnCreated()
		self.tick = .1
		self._tick = 0
		self.modifiers_number = 0
		self:StartIntervalThink(self.tick)
	end

	function modifier_arena_hero:OnIntervalThink()
		self._tick = self._tick + 1
		local parent = self:GetParent()

		--util
		local hero = parent
		local i = hero:GetPlayerID()
		if hero and hero:IsTrueHero() then
			if hero:GetFullName() == "npc_dota_hero_meepo" then
				for _, v in ipairs(MeepoFixes:FindMeepos(hero, true)) do
					local position = v:GetAbsOrigin()
					local mapMin = Vector(-MAP_LENGTH, -MAP_LENGTH)
					local mapClampMin = ExpandVector(mapMin, -MAP_BORDER)
					local mapMax = Vector(MAP_LENGTH, MAP_LENGTH)
					local mapClampMax = ExpandVector(mapMax, -MAP_BORDER)
					if not IsInBox(position, mapMin, mapMax) then
						FindClearSpaceForUnit(v, VectorOnBoxPerimeter(position, mapClampMin, mapClampMax), true)
					end
				end
			else
				local v = parent
				local position = v:GetAbsOrigin()
				local mapMin = Vector(-MAP_LENGTH, -MAP_LENGTH)
				local mapClampMin = ExpandVector(mapMin, -MAP_BORDER)
				local mapMax = Vector(MAP_LENGTH, MAP_LENGTH)
				local mapClampMax = ExpandVector(mapMax, -MAP_BORDER)
				if not IsInBox(position, mapMin, mapMax) then
					FindClearSpaceForUnit(v, VectorOnBoxPerimeter(position, mapClampMin, mapClampMax), true)
				end
			end
		end
		if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			local goldPerTick = 0

			local courier = Structures:GetCourier(i)
			-- print(courier:IsAlive())
			if courier and courier:IsAlive() then
				goldPerTick = CUSTOM_GOLD_PER_TICK * self.tick
			end

			if hero then
				if hero.talent_keys and hero.talent_keys.bonus_gold_per_minute then
					goldPerTick = goldPerTick + hero.talent_keys.bonus_gold_per_minute / 60 * self.tick
				end
				if hero.talent_keys and hero.talent_keys.bonus_xp_per_minute then
					local exp = math.ceil(hero.talent_keys.bonus_xp_per_minute / 60 * self.tick)
					hero:AddExperience(exp, 0, false, false)
					--print("exp: "..exp)
				end
			end

			--print("goldPerTick: "..goldPerTick)
			Gold:AddGold(i, goldPerTick)
		end
		AntiAFK:Think(i)
		-------------------------------

		--удаление неуязвимости от фонтана
		if parent:HasModifier("modifier_fountain_invulnerability") then
			parent:RemoveModifierByName("modifier_fountain_invulnerability")
		end

		local VisibleAbilitiesCount = 0
		for i = 0, parent:GetAbilityCount() - 1 do
			local ability = parent:GetAbilityByIndex(i)
			if ability and not ability:IsHidden() and not ability:GetAbilityName():starts("special_bonus_") then
				VisibleAbilitiesCount = VisibleAbilitiesCount + 1
			end
		end
		if self.VisibleAbilitiesCount ~= VisibleAbilitiesCount then
			self.VisibleAbilitiesCount = VisibleAbilitiesCount
			self:SetSharedKey("VisibleAbilitiesCount", VisibleAbilitiesCount)
		end

		-- if parent:HasModifier("modifier_alchemist_chemical_rage") and parent:HasModifier("modifier_stamina") and not self.chem_rage then
		-- 	local chemical_rage = parent:FindModifierByName("modifier_alchemist_chemical_rage")
		-- 	local stamina = parent:FindModifierByName("modifier_stamina")

		-- 	self.chem_rage = chemical_rage:GetAbility()
		-- 	stamina.outside_change_bat = -self.chem_rage:GetSpecialValueFor("base_attack_time")
		-- elseif not parent:HasModifier("modifier_alchemist_chemical_rage") and self.chem_rage then
		-- 	parent:FindModifierByName("modifier_stamina").outside_change_bat = self.chem_rage:GetSpecialValueFor(
		-- 	"base_attack_time")
		-- 	self.chem_rage = nil
		-- end

		if parent:HasModifier("modifier_item_infinity_gauntlet") and parent:HasModifier("modifier_stamina") and not self.inf_gaunt then
			local gauntlet = parent:FindModifierByName("modifier_item_infinity_gauntlet")
			self.inf_gaunt = gauntlet:GetAbility()

			parent.outside_change_bat = parent.outside_change_bat + self.inf_gaunt:GetSpecialValueFor("bat_increase")
			parent:SetNetworkableEntityInfo("BaseAttackTime",
				parent:GetKeyValue("AttackRate") + parent.outside_change_bat)
		elseif not parent:HasModifier("modifier_item_infinity_gauntlet") and self.inf_gaunt then
			parent.outside_change_bat = parent.outside_change_bat - self.inf_gaunt:GetSpecialValueFor(
				"bat_increase")
			parent:SetNetworkableEntityInfo("BaseAttackTime",
				parent:GetKeyValue("AttackRate") + parent.outside_change_bat)
			self.inf_gaunt = nil
		end

		--костыль для морфа
		if parent:GetFullName() == "npc_dota_hero_morphling" then
			if self.saved_str ~= parent:GetBaseStrength() or
				self.saved_agi ~= parent:GetBaseAgility() then
				self.saved_str = parent:GetBaseStrength()
				self.saved_agi = parent:GetBaseAgility()

				local str_gain = parent:GetStrengthGain()
				local agi_gain = parent:GetAgilityGain()
				local normal_str = str_gain * math.min(STAT_GAIN_LEVEL_LIMIT, parent:GetLevel() - 1) + parent:GetKeyValue("AttributeBaseStrength")
				local normal_agi = agi_gain * math.min(STAT_GAIN_LEVEL_LIMIT, parent:GetLevel() - 1) + parent:GetKeyValue("AttributeBaseAgility")
				local mult = math.max(normal_str, math.min(normal_str, parent:GetBaseStrength())) / math.max(normal_agi, math.min(normal_agi, parent:GetBaseAgility()))
				print('mult: '..mult)
				parent.CustomGain_Strength = str_gain + agi_gain * mult
				parent.CustomGain_Agility = agi_gain + str_gain / mult

				Attributes:UpdateAll(parent)
			end
		end

		--self.backpack = CheckBackpack(parent, self.backpack)

		local allmodifiers = #parent:FindAllModifiers() -
			#parent:FindAllModifiersByName("modifier_agility_bonus_attacks")
		if self.modifiers_number ~= allmodifiers then
			Attributes:UpdateAll(parent)

			if self.modifiers_number > allmodifiers then
				local index = 1
				for k, v in pairs(parent.change_bat_modifiers) do
					if v and not parent:HasModifier(v.name) then
						parent.outside_change_bat = parent.outside_change_bat + v.change
						parent.change_bat_modifiers[index] = nil
						parent:SetNetworkableEntityInfo("BaseAttackTime",
							parent:GetKeyValue("AttackRate") + parent.outside_change_bat)
					end
					index = index + 1
				end
			end

			self.modifiers_number = allmodifiers
		end

		if self.parent_level ~= parent:GetLevel() then
			Attributes:UpdateAll(parent)
			self.parent_level = parent:GetLevel()
		end

		--print(Duel:GetDuelTimer())

		if parent:IsAlive() and
			parent.OnDuel and
			Duel:GetDuelTimer() <= 20 and
			not parent:HasModifier("modifier_arena_duel_vision") then
			parent:AddNewModifier(nil, nil, "modifier_arena_duel_vision", nil)
			parent:AddNewModifier(nil, nil, "modifier_truesight", nil)
		elseif (not parent:IsAlive() or
				not parent.OnDuel) and
			parent:HasModifier("modifier_arena_duel_vision") then
			parent:RemoveModifierByName("modifier_arena_duel_vision")
			parent:RemoveModifierByName("modifier_truesight")
		end

		--panorama

		-- if self._BaseAttackTime ~= parent:GetBaseAttackTime() or
		-- 	self._AttackSpeed ~= parent:GetAttackSpeed()
		-- then
		-- 	parent:SetNetworkableEntityInfo("BaseAttackTime", parent:GetBaseAttackTime())
		-- 	self._BaseAttackTime = parent:GetBaseAttackTime()
		-- 	parent:SetNetworkableEntityInfo("CustomAttackSpeed", parent:GetAttackSpeed())
		-- 	self._AttackSpeed = parent:GetAttackSpeed()
		-- end

		-- if self._Damage ~= parent:GetAverageTrueAttackDamage(parent) then
		-- 	self._Damage = parent:GetAverageTrueAttackDamage(parent)
		-- 	parent:SetNetworkableEntityInfo("BonusDamage", parent:GetAverageTrueAttackDamage(parent))
		-- end
	end

	function modifier_arena_hero:OnDeath(k)
		local parent = self:GetParent()
		if k.unit == parent and not parent:IsIllusion() and parent:IsTrueHero() and not parent:IsTempestDouble() then
			if not Duel:IsDuelOngoing() then
				for _, v in pairs(STONES_TABLE) do
					local stone = FindItemInInventoryByName(parent, v[1], false, false, false, true)
					if stone then
						parent:DropItemAtPositionImmediate(stone, parent:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
					end
				end

				DropInfinityGauntlet(parent)

				local courier = Structures:GetCourier(parent:GetPlayerID())
				if courier:IsAlive() then
					for _, v in pairs(STONES_TABLE) do
						local stone = FindItemInInventoryByName(courier, v[1], _, _, _, true)
						--print(stone)
						if stone then
							courier:DropItemAtPositionImmediate(stone,
								parent:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
						end
					end
				end
			end

			--удаление ненадежных атрибутов при смерти
			Attributes:OnDeath(parent)

			--print(GetOneRemainingTeam())
			if GetOneRemainingTeam() then
				self.deaths_count = (self.deaths_count or 0) + 1
				if self.deaths_count == 3 then
					GameMode:OnOneTeamLeft(DOTA_TEAM_NEUTRALS)
					return
				end
				if self.deaths_count == 1 then
					Notifications:Bottom(parent:GetPlayerID(), { text = "#arena_hud_2lives_left", duration = 8 })
				end
				if self.deaths_count == 2 then
					Notifications:Bottom(parent:GetPlayerID(), { text = "#arena_hud_1lives_left", duration = 8 })
				end
			end
		end

		if k.attacker == parent and k.unit:IsCreep() then
			local gold = 0
			local xp = 0
			for _k, v in pairs(CREEP_BONUSES_MODIFIERS) do
				if parent:HasModifier(_k) then
					local gxp = type(v) == "function" and v(parent) or v
					if gxp then
						gold = math.max(gold, (gxp.gold or 0))
						xp = math.max(xp, (gxp.xp or 0))
					end
				end
			end
			if gold > 0 and not parent:HasModifier("modifier_item_golden_eagle_relic_enabled") then
				Gold:ModifyGold(parent, gold)
				local particle = ParticleManager:CreateParticleForPlayer(
					"particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf", PATTACH_ABSORIGIN, k.unit,
					parent:GetPlayerOwner())
				ParticleManager:SetParticleControl(particle, 1, Vector(0, gold * GetGoldMultiplier(parent), 0))
				ParticleManager:SetParticleControl(particle, 2, Vector(2, string.len(gold) + 1, 0))
				ParticleManager:SetParticleControl(particle, 3, Vector(255, 200, 33))
			end
			if xp > 0 and k.unit:GetFullName() ~= "npc_dota_neutral_jungle_variant1" then
				parent:AddExperience(xp, false, false)
			end
		end
		if k.unit == parent then
			parent:RemoveNoDraw()

			if parent:IsIllusion() then
				parent:ClearNetworkableEntityInfo()
			end
		end
	end

	function modifier_arena_hero:OnRespawn(k)
		if k.unit == self:GetParent() and k.unit:GetUnitName() == "npc_dota_hero_crystal_maiden" then
			k.unit:AddNoDraw()
			Timers:CreateTimer(0.1, function() k.unit:RemoveNoDraw() end)
		end
	end

	function modifier_arena_hero:OnAbilityStart(keys)
		--print("start")
		if keys.ability:GetCaster() == self:GetParent() and ABILITIES_TRIGGERS_ATTACKS[keys.ability:GetAbilityName()] then
			SplashTimer(self:GetParent(), keys.ability)
		end
	end

	function modifier_arena_hero:OnAbilityExecuted(keys)
		if self:GetParent() == keys.unit then
			local ability_cast = keys.ability
			local abilityname = ability_cast ~= nil and ability_cast:GetAbilityName()
			local caster = self:GetParent()
			local target = keys.target or caster:GetCursorPosition()
			if caster.talents_ability_multicast and caster.talents_ability_multicast[abilityname] then
				for i = 1, caster.talents_ability_multicast[abilityname] - 1 do
					Timers:CreateTimer(0.1 * i, function()
						if IsValidEntity(caster) and IsValidEntity(ability_cast) then
							CastAdditionalAbility(caster, ability_cast, target, 0, {})
						end
					end)
				end
			end
		end
	end

	function modifier_arena_hero:OnAbilityEndChannel(keys)
		local parent = self:GetParent()
		local endChannelListeners = parent.EndChannelListeners
		if not endChannelListeners then return end
		for _, v in ipairs(endChannelListeners) do
			v(keys.fail_type < 0)
		end
		parent.EndChannelListeners = {}
	end

	function modifier_arena_hero:OnRemoved()
		print('destroy')
	end

	function modifier_arena_hero:OnDestroy()
		if IsValidEntity(self.reflect_stolen_ability) then
			self.reflect_stolen_ability:RemoveSelf()
		end
	end

	function modifier_arena_hero:GetReflectSpell(keys)
		local parent = self:GetParent()
		if parent:IsIllusion() then return end
		local originalAbility = keys.ability
		self.absorb_without_check = false
		if originalAbility:GetCaster():GetTeam() == parent:GetTeam() then return end
		if SPELL_REFLECT_IGNORED_ABILITIES[originalAbility:GetAbilityName()] then return end

		local item_lotus_sphere = FindItemInInventoryByName(parent, "item_lotus_sphere", false, false, true)
		if parent:HasModifier("modifier_item_lotus_sphere") then
			item_lotus_sphere = parent:FindModifierByName("modifier_item_lotus_sphere"):GetAbility()
		end

		if not self.absorb_without_check and item_lotus_sphere and parent:HasModifier("modifier_item_lotus_sphere") and item_lotus_sphere:PerformPrecastActions() then
			ParticleManager:SetParticleControlEnt(
				ParticleManager:CreateParticle("particles/arena/items_fx/lotus_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW,
					parent),
				0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
			parent:EmitSound("Item.LotusOrb.Activate")
			self.absorb_without_check = true
		end

		if self.absorb_without_check and not originalAbility.item_lotus_sphere then
			if IsValidEntity(self.reflect_stolen_ability) then
				self.reflect_stolen_ability:RemoveSelf()
			end
			local hCaster = self:GetParent()
			local hAbility = hCaster:AddAbility(originalAbility:GetAbilityName())
			if hAbility then
				hAbility.item_lotus_sphere = true
				hAbility:SetStolen(true)
				hAbility:SetHidden(true)
				hAbility:SetLevel(originalAbility:GetLevel())
				hCaster:SetCursorCastTarget(originalAbility:GetCaster())
				hAbility:OnSpellStart()
				hAbility:SetActivated(false)
				self.reflect_stolen_ability = hAbility
			end
		end
	end

	function modifier_arena_hero:GetAbsorbSpell(keys)
		local parent = self:GetParent()
		if self.absorb_without_check then
			self.absorb_without_check = nil
			return 1
		end
		return false
	end
end

--splash
function modifier_arena_hero:OnAttackLanded(keys)
	local attacker = keys.attacker
	local target = keys.target

	if attacker ~= self:GetParent() then return end

	if attacker:FindModifierByName("modifier_splash_timer") then
		return
	end
	if not attacker:IsRangedUnit() then
		local distance = 400
		local start = 100
		local _end = 250
		local item = nil
		local cleave = 0
		if attacker:HasModifier("modifier_item_ultimate_splash") then
			item = attacker:FindModifierByName("modifier_item_ultimate_splash"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		elseif attacker:HasModifier("modifier_item_elemental_fury") then
			item = attacker:FindModifierByName("modifier_item_elemental_fury"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		elseif attacker:HasModifier("modifier_item_battlefury_arena") then
			item = attacker:FindModifierByName("modifier_item_battlefury_arena"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		elseif attacker:HasModifier("modifier_item_quelling_fury") then
			item = attacker:FindModifierByName("modifier_item_quelling_fury"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		end
		if not self._splash_cooldown then
			self._splash_cooldown = true
			DoCleaveAttack(
				attacker,
				target,
				item,
				(keys.damage) * ((cleave or 0) + 25) * 0.01, -- + 0.15 * attacker:GetLevel()) * 0.01,
				distance,
				start,
				_end,
				"particles/items_fx/battlefury_cleave.vpcf"
			)
			Timers:CreateTimer(0.1, function()
				self._splash_cooldown = false
			end)
		end
	else
		local radius = 200
		local splash = 0
		if attacker:HasModifier("modifier_item_ultimate_splash") then
			local item = attacker:FindModifierByName("modifier_item_ultimate_splash"):GetAbility()
			radius = item:GetSpecialValueFor("split_radius")
			splash = item:GetSpecialValueFor("split_damage_pct")
		elseif attacker:HasModifier("modifier_item_splitshot_ultimate") then
			local item = attacker:FindModifierByName("modifier_item_splitshot_ultimate"):GetAbility()
			radius = item:GetSpecialValueFor("split_radius")
			splash = item:GetSpecialValueFor("split_damage_pct")
		elseif attacker:HasModifier("modifier_item_nagascale_bow") then
			local item = attacker:FindModifierByName("modifier_item_nagascale_bow"):GetAbility()
			radius = item:GetSpecialValueFor("split_radius")
			splash = item:GetSpecialValueFor("split_damage_pct")
		end

		if not self._splash_cooldown then
			self._splash_cooldown = true
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
			for _, v in pairs(targets) do
				if v ~= target then
					ApplyDamage({
						attacker = attacker,
						victim = v,
						damage_type = DAMAGE_TYPE_PHYSICAL,
						damage = (keys.damage) * ((splash or 0) + 25) * 0.01, -- + 0.15 * attacker:GetLevel()) * 0.01,
						damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
						ability = item
					})
				end
			end
			Timers:CreateTimer(0.1, function()
				self._splash_cooldown = false
			end)
		end
	end
end
