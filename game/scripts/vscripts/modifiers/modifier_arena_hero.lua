modifier_baseclass = {
	IsPurgable      = function() return false end,
	IsHidden        = function() return true end,
	RemoveOnDeath   = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	DestroyOnExpire = function() return false end,
}
modifier_arena_hero = class(modifier_baseclass)
modifier_arena_hero_health_regen = class(modifier_baseclass)
modifier_arena_hero_mana_regen = class(modifier_baseclass)
modifier_arena_hero_max_mana = class(modifier_baseclass)
modifier_arena_hero_current_mana = class(modifier_baseclass)
modifier_arena_hero_gold = class(modifier_baseclass)


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

		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION,

		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
	}
end

if IsServer() then
	function modifier_arena_hero:GetModifierTotalDamageOutgoing_Percentage(keys)
		return HeroOutgoingDamage(keys, self)
	end

	function modifier_arena_hero:GetModifierIncomingDamageConstant(keys)
		return HeroIncomingDamage(keys, self)
	end

	function modifier_arena_hero:GetModifierConstantHealthRegen()
		return (self:GetParent():GetStrength() - self:GetParent():GetUnreliableStrength()) * 0.1 -
			self:GetParent():GetStrength() * 0.1
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
	return self.custom_attack_speed
end

function modifier_arena_hero:GetModifierMagicalResistanceDirectModification()
	return -math.max(0, self:GetParent():GetIntellect()) * 0.1
end

if IsClient() then
	function modifier_arena_hero:HandleCustomTransmitterData(data)
		self.spell_amp = data.spell_amp
		self.agility_damage = data.agility_damage
		self.custom_attack_speed = data.custom_attack_speed
	end

	function modifier_arena_hero:GetModifierSpellAmplify_Percentage()
		return self.spell_amp
	end

	function modifier_arena_hero:GetModifierPreAttack_BonusDamage()
		return self.agility_damage
	end
end

if IsServer() then
	modifier_arena_hero.HeroLevel = 1
	function modifier_arena_hero:OnCreated()
		local parent = self:GetParent()
		self.tick = 1 / 20
		self._tick = 0
		self.modifiers_number = 0
		self.spell_amp = 0
		self.agility_damage = 0
		self.custom_attack_speed = 0

		self.health_regen_modifier = parent:AddNewModifier(parent, nil, "modifier_arena_hero_health_regen", nil)
		self.mana_regen_modifier = parent:AddNewModifier(parent, nil, "modifier_arena_hero_mana_regen", nil)
		self.max_mana_modifier = parent:AddNewModifier(parent, nil, "modifier_arena_hero_max_mana", nil)
		self.current_mana_modifier = parent:AddNewModifier(parent, nil, "modifier_arena_hero_current_mana", nil)
		self.gold_modifier = parent:AddNewModifier(parent, nil, "modifier_arena_hero_gold", nil)

		self:Transmitter()
		self:StartIntervalThink(self.tick)
	end

	function modifier_arena_hero:AddCustomTransmitterData()
		return {
			spell_amp = self.spell_amp,
			agility_damage = self.agility_damage,
			custom_attack_speed = self.custom_attack_speed
		}
	end

	function modifier_arena_hero:Transmitter()
		local parent = self:GetParent()
		self.spell_amp = parent.client_spell_amp or 0
		self.agility_damage = CalculateAttackDamage(parent, parent) or 0
		self.custom_attack_speed = parent.custom_attack_speed or 0
		self:SetHasCustomTransmitterData(false)
		self:SetHasCustomTransmitterData(true)
		self:SendBuffRefreshToClients()
	end

	function modifier_arena_hero:OnIntervalThink()
		HeroThink(self)
	end

	function modifier_arena_hero:OnDeath(k)
		local parent = self:GetParent()
		if k.unit == parent then
			parent:RemoveNoDraw()

			if parent:IsIllusion() then
				parent:ClearNetworkableEntityInfo()
				-- UTIL_Remove(parent)
			end
			if not parent:IsIllusion() and parent:IsTrueHero() and not parent:IsTempestDouble() and not parent:IsReincarnating() then
				if not Duel:IsDuelOngoing() then
					for _, v in pairs(STONES_TABLE) do
						local stone = FindItemInInventoryByName(parent, v[1], false, false, false, true)
						if stone then
							parent:DropItemAtPositionImmediate(stone,
								parent:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
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
				if k.attacker and k.attacker:IsHero() then
					local attackerBuyingStatsSum = k.attacker.Additional_str + k.attacker.Additional_agi +
						k.attacker.Additional_int
					local victimBuyingStatsSum = parent.Additional_str + parent.Additional_agi + parent.Additional_int
					if attackerBuyingStatsSum < victimBuyingStatsSum then
						Attributes:RemoveStats(parent, 30)
					end
				end

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
		-- print('destroy')
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
	HeroOnAttackLanded(keys, self)
end
