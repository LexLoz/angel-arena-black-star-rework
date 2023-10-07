-- Percentage
BOSS_DAMAGE_ABILITY_MODIFIERS = {
	--zuus_static_field = 5,
	--item_blade_mail = 40,
	--centaur_return = 15,
	enigma_midnight_pulse = 15,
	enigma_black_hole = 200,
	--techies_suicide = 25,
	lina_laguna_blade = 200,
	lion_finger_of_death = 200,
	--shredder_chakram_2 = 40,
	--shredder_chakram = 40,
	--sniper_shrapnel = 40,
	abyssal_underlord_firestorm = 15,
	bristleback_quill_spray = 50,
	--centaur_hoof_stomp = 40,
	--centaur_double_edge = 40,
	kunkka_ghostship = 200,
	kunkka_torrent = 200,
	ember_spirit_flame_guard = 200,
	sandking_sand_storm = 200,
	antimage_mana_void = 25,
	doom_bringer_infernal_blade = 10,
	winter_wyvern_arctic_burn = 10,
	freya_ice_cage = 25,
	--tinker_march_of_the_machines = 2000,
	necrolyte_reapers_scythe = 25,
	huskar_life_break = 20,
	huskar_burning_spear_arena = 10,
	phantom_assassin_fan_of_knives = 15,
	item_unstable_quasar = 15,
	bloodseeker_blood_mist = 200,
	bloodseeker_bloodrage = 20,
	bloodseeker_rupture = 50,
	venomancer_poison_nova = 25,
	venomancer_noxious_plague = 15,
	phoenix_sun_ray = 10,
	zuus_arc_lightning = 15,
	muerta_pierce_the_veil = 33,
	witch_doctor_maledict = 25,

	item_piercing_blade = 5,
	item_soulcutter = 10,
	item_revenants_brooch = 200,
	item_witch_blade = 200,
}

local function OctarineLifesteal(attacker, victim, inflictor, damage, _, damage_flags, itemname, cooldownModifierName)
	if inflictor and attacker:GetTeam() ~= victim:GetTeam() and not HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) and not OCTARINE_NOT_LIFESTALABLE_ABILITIES[inflictor:GetAbilityName()] then
		local heal = math.floor(math.min(victim:GetHealth(), damage *
			GetAbilitySpecial(itemname, victim:IsHero() and "hero_lifesteal" or "creep_lifesteal") * 0.01))
		if heal >= 1 then
			if not victim:IsIllusion() then
				SafeHeal(attacker, heal, inflictor, true, {
					spellLifesteal = true,
					source = attacker
				})
			end
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, attacker, heal, nil)
			ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW,
				attacker)
		end

		local item = FindItemInInventoryByName(attacker, itemname, false)
		if item and RollPercentage(GetAbilitySpecial(itemname, "bash_chance")) and not attacker:HasModifier(cooldownModifierName) then
			victim:AddNewModifier(attacker, item, "modifier_stunned",
				{ duration = GetAbilitySpecial(itemname, "bash_duration") })
			item:ApplyDataDrivenModifier(attacker, attacker, cooldownModifierName, {})
		end
	end
end

ON_DAMAGE_MODIFIER_PROCS = {
	modifier_item_octarine_core_arena = function(attacker, victim, inflictor, damage, damagetype_const, damage_flags)
		OctarineLifesteal(attacker, victim, inflictor, damage, damagetype_const, damage_flags, "item_octarine_core_arena",
			"modifier_octarine_bash_cooldown")
	end,
	modifier_item_refresher_core = function(attacker, victim, inflictor, damage, damagetype_const, damage_flags)
		OctarineLifesteal(attacker, victim, inflictor, damage, damagetype_const, damage_flags, "item_refresher_core",
			"modifier_octarine_bash_cooldown")
	end,
	modifier_sara_evolution = function(attacker, _, _, damage)
		local ability = attacker:FindAbilityByName("sara_evolution")
		if ability and attacker.ModifyEnergy then
			attacker:ModifyEnergy(damage * ability:GetSpecialValueFor("damage_to_energy_pct") * 0.01, true)
		end
	end,
	modifier_item_golden_eagle_relic = function(attacker, victim, inflictor, damage, damagetype_const)
		--print('golden eagle')
		if not IsValidEntity(inflictor) then
			if damagetype_const == DAMAGE_TYPE_PHYSICAL then
				local LifestealPercentage = GetAbilitySpecial("item_golden_eagle_relic", "lifesteal_pct")
				local armor = victim:GetPhysicalArmorValue(false)
				local resist = 1 - CalculatePhysicalResist(victim, armor)
				local lifesteal = math.min(victim:GetHealth(), damage * LifestealPercentage * 0.01 * resist)
				--print("lifesteal: "..lifesteal)
				SafeHeal(attacker, lifesteal,
					attacker:FindModifierByName("modifier_item_golden_eagle_relic"):GetAbility(), false, {
						lifesteal = true,
						source = attacker
					})
				ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf",
					PATTACH_ABSORIGIN_FOLLOW, attacker)
			end
		end
	end,
	modifier_talent_lifesteal = function(attacker, victim, inflictor, _, damagetype_const)
		local lifesteal = 0
		if not IsValidEntity(inflictor) then
			if damagetype_const == DAMAGE_TYPE_PHYSICAL then
				local stacks = attacker:GetModifierStackCount("modifier_talent_lifesteal", attacker)
				local armor = victim:GetPhysicalArmorValue(false)
				local resist = 1 - CalculatePhysicalResist(victim, armor)
				lifesteal = attacker:GetMaxHealth() * stacks * 0.01 * resist
				--print(lifesteal)
				SafeHeal(attacker, lifesteal, inflictor, false, {
					lifesteal = true,
					source = attacker
				})
				ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf",
					PATTACH_ABSORIGIN_FOLLOW, attacker)
			end
		end
	end,
	modifier_shinobu_vampire_blood = function(attacker, _, inflictor, damage, damagetype_const)
		if not IsValidEntity(inflictor) then
			if damagetype_const == DAMAGE_TYPE_PHYSICAL then
				local caster = attacker
				local ability = caster:FindAbilityByName('shinobu_vampire_blood')
				local pct = ability:GetAbilitySpecial("lifesteal_pct_lvl" .. ability.CurrentLevel)
				if pct then
					local amount = damage * pct * 0.01
					caster:SetHealth(caster:GetHealth() + amount)
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, amount, nil)
					ParticleManager:CreateParticle(
						"particles/arena/units/heroes/hero_shinobu/lifesteal_lvl" .. ability.CurrentLevel .. ".vpcf",
						PATTACH_ABSORIGIN_FOLLOW, caster)
				end
			end
		end
	end,
}

ON_DAMAGE_MODIFIER_PROCS_VICTIM = {
	modifier_item_holy_knight_shield = function(attacker, victim, inflictor, damage)
		if inflictor then
			local item = FindItemInInventoryByName(victim, "item_holy_knight_shield", false)
			if item and RollPercentage(GetAbilitySpecial("item_holy_knight_shield", "buff_chance")) and victim:GetTeam() ~= attacker:GetTeam() then
				if item:PerformPrecastActions() then
					item:ApplyDataDrivenModifier(victim, victim, "modifier_item_holy_knight_shield_buff", {})
				end
			end
		end
	end,
}

-- INCOMING_DAMAGE_MODIFIERS_BASE = {
-- 	modifier_beastmaster_axe_stack_counter = {
-- 		multiplier = function(attacker, victim)
-- 			local mod = victim:FindModifierByName("modifier_beastmaster_axe_stack_counter")
-- 			local ability = mod:GetAbility()
-- 			local caster = ability:GetCaster()
-- 			local player = caster:GetPlayerOwnerID()
-- 			if attacker:GetPlayerOwnerID() == player then
-- 				return 1 + ability:GetSpecialValueFor("damage_amp") * mod:GetStackCount() * 0.01
-- 			end
-- 		end
-- 	},
-- 	modifier_undying_flesh_golem_slow = {
-- 		multiplier = function(_, victim)
-- 			local ability = victim:FindModifierByName("modifier_undying_flesh_golem_slow"):GetAbility()
-- 			return 1 + ability:GetSpecialValueFor("damage_amp") * 0.01
-- 		end
-- 	},
-- 	modifier_item_veil_of_discord_debuff = {
-- 		multiplier = function(_, victim, inflictor)
-- 			local ability = victim:FindModifierByName("modifier_item_veil_of_discord_debuff"):GetAbility()
-- 			if inflictor then
-- 				return 1 + ability:GetSpecialValueFor("spell_amp") * 0.01
-- 			end
-- 		end
-- 	},
-- 	modifier_hoodwink_hunters_mark = {
-- 		multiplier = function(_, victim, inflictor)
-- 			local ability = victim:FindModifierByName("modifier_item_veil_of_discord_debuff"):GetAbility()
-- 			if inflictor then
-- 				return 1 + ability:GetSpecialValueFor("spell_amp") * 0.01
-- 			end
-- 		end
-- 	}
-- }

ON_ADDICTIVE_DAMAGE_MODIFIER_PROCS = {
	modifier_item_desolator6_arena = {
		addictive_multiplier = function()
			return 1 + GetAbilitySpecial("item_desolator6", "all_damage_bonus_pct") * 0.01
		end
	},
	modifier_item_demons_paw = {
		addictive_multiplier = function()
			return 1 + GetAbilitySpecial("item_demons_paw", "all_damage_bonus_pct") * 0.01
		end
	},
	modifier_kadash_assasins_skills = {
		addictive_multiplier = function(attacker)
			local ability = attacker:FindAbilityByName("kadash_assasins_skills")
			if ability then
				return 1 + ability:GetSpecialValueFor("all_damage_bonus_pct") * 0.01
			end
		end
	},
	modifier_item_ultimate_splash = {
		addictive_multiplier = function()
			return 1 + GetAbilitySpecial("item_ultimate_splash", "all_damage_bonus_pct") * 0.01
		end
	},
	modifier_item_scythe_of_the_ancients_passive = {
		addictive_multiplier = function()
			return 1 + GetAbilitySpecial("item_scythe_of_the_ancients", "all_damage_bonus_pct") * 0.01
		end
	},
	modifier_item_soulcutter = {
		addictive_multiplier = function()
			return 1 + GetAbilitySpecial("item_soulcutter", "all_damage_increase") * 0.01
		end
	},
	modifier_item_diffusal_style = {
		addictive_multiplier = function()
			return 1 + GetAbilitySpecial("item_diffusal_style", "all_damage_increase") * 0.01
		end
	},

	modifier_item_behelit_buff = {
		addictive_multiplier = function(attacker)
			local damage_bonus = attacker:GetNetworkableEntityInfo("behelit_damage_bonus")
			return 1 + damage_bonus * 0.01
		end
	}
}

OUTGOING_DAMAGE_MODIFIERS = {
	modifier_item_desolator6_arena = function(attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage)
		if not IsValidEntity(inflictor) then
			local mod_name = "modifier_item_desolator6_arena"
			local mod = attacker:FindModifierByName(mod_name)
			local ability = mod:GetAbility()
			local strength_crit = attacker:FindModifierByName("modifier_strength_crit")
			local chance = (strength_crit and strength_crit.ready) and 100 or
				ability:GetSpecialValueFor('ignore_base_armor_chance')

			if ability:IsCooldownReady() then
				if RollPercentage(chance) then
					ability:AutoStartCooldown()

					local base_armor = victim:GetPhysicalArmorValue(false) -
						(victim:GetPhysicalArmorValue(true) < 0 and math.abs(victim:GetPhysicalArmorValue(true)) or victim:GetPhysicalArmorValue(true))
					local total_armor = victim:GetPhysicalArmorValue(false)
					local ignored_armor = base_armor > total_armor and total_armor or base_armor
					local ignored_armor_mult = CalculatePhysicalResist(victim, total_armor - ignored_armor)

					local multiplier = 1
					for k, v in pairs(OUTGOING_DAMAGE_MODIFIERS) do
						if k ~= mod_name and attacker:HasModifier(k) and (type(v) ~= "table" or not v.condition or (v.condition and v.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags))) then
							if multiplier == 0 then break end
							multiplier = multiplier * ExtractMultiplier(
								damage,
								ProcessDamageModifier(v, attacker, victim, inflictor, damage, damagetype_const,
									damage_flags, saved_damage))
						end
					end
					-- print('damage: ' .. (damage * multiplier * (1 - ignored_armor_mult)))
					ApplyDamage({
						victim = victim,
						attacker = attacker,
						damage = damage * multiplier * (1 - ignored_armor_mult),
						damage_type = DAMAGE_TYPE_PHYSICAL,
						damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR,
						ability = ability
					})
					-- attacker:RemoveModifierByName(mod_name)
					return 0
				end
			end
			-- attacker:RemoveModifierByName(mod_name)
			return 1
		end
	end,
	modifier_sans_curse_passive = function(_, victim)
		if victim:GetTeam() == DOTA_TEAM_NEUTRALS and victim:IsCreep() then
			return 0.25
		end
	end,
	modifier_anakim_wisps = {
		condition = function(_, _, inflictor)
			return not inflictor
		end,
		multiplier = function()
			return 0
		end
	},
	modifier_kadash_strike_from_shadows = {
		condition = function(_, _, inflictor)
			return not inflictor
		end,
		multiplier = function(attacker, victim, _, damage)
			local kadash_strike_from_shadows = attacker:FindAbilityByName("kadash_strike_from_shadows")
			attacker:RemoveModifierByName("modifier_kadash_strike_from_shadows")
			attacker:RemoveModifierByName("modifier_invisible")
			if kadash_strike_from_shadows then
				kadash_strike_from_shadows.NoDamageAmp = true
				ApplyDamage({
					victim = victim,
					attacker = attacker,
					damage = damage * kadash_strike_from_shadows:GetAbilitySpecial("magical_damage_pct") * 0.01,
					damage_type = kadash_strike_from_shadows:GetAbilityDamageType(),
					damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
					ability = kadash_strike_from_shadows
				})
				kadash_strike_from_shadows:ApplyDataDrivenModifier(attacker, victim,
					"modifier_kadash_strike_from_shadows_debuff", nil)
				return 0
			end
		end
	},

	modifier_stamina = function(parent, _, inflictor, _)
		local stacks = parent:FindModifierByName("modifier_stamina"):GetStackCount()

		if not inflictor then
			local mult = (1 - stacks / 100) * 50 * 0.01
			parent:CalculateStatBonus(true)
			return 1 - mult
		end
	end,

	modifier_intelligence_primary_bonus = {
		multiplier = function(attacker, victim)
			if attacker:PassivesDisabled() or attacker:IsHexed() then return 1 end
			local mod = attacker:FindModifierByName("modifier_intelligence_primary_bonus")
			if not mod then return 1 end
			local max_bonus = INTELLECT_PRIMARY_BONUS_MAX_BONUS
			local difference = INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT
			if mod.util_ then
				max_bonus = max_bonus * INTELLECT_PRIMARY_BONUS_UPGRADE_MULT
				difference = difference / INTELLECT_PRIMARY_BONUS_UPGRADE_DIFF_MULT
			end
			if (victim:IsTrueHero() or victim:IsIllusion()) and (attacker:IsTrueHero() or attacker:IsIllusion()) then
				local attackerInt = (attacker:GetIntellect())
				local victimInt = victim:GetIntellect()
				local diff

				if attackerInt <= victimInt then
					mod:SetStackCount(0)
					return 1
				end

				if attackerInt > victimInt then
					diff = attackerInt / victimInt
					if diff >= difference then
						mod:SetStackCount(math.round(max_bonus))
						return 1 + max_bonus * 0.01
					else
						diff = 1 - victimInt / attackerInt
						mod:SetStackCount(math.round(max_bonus * diff))
						return 1 + max_bonus * 0.01 * diff
					end
				end
			elseif (attacker:IsTrueHero() or attacker:IsIllusion()) then
				mod:SetStackCount(math.round((max_bonus / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE)))
				return 1 + (max_bonus / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE) * 0.01
			end
		end
	},

	modifier_mind_stone = {
		multiplier = function(_, _, inflictor)
			if inflictor then
				return 1 + GetAbilitySpecial("item_mind_stone", "bonus_spell_damage") * 0.01
			end
		end
	},

	modifier_agility_primary_bonus = function(parent, _, inflictor, _, _, _)
		-- print(parent.bonus_attack)
		if not inflictor and parent.bonus_attack and not parent:PassivesDisabled() then
			-- print('agility bonus attack mult: '..(1 + parent.bonus_attack * 0.01))
			return 1 + parent.bonus_attack * 0.01
		end
	end,

	modifier_strength_crit = function(parent, victim, inflictor, damage, _, damage_flags)
		local modifier = parent:FindModifierByName("modifier_strength_crit")
		local mult = (modifier.strengthCriticalDamage or modifier:GetStackCount() - 100) * 0.01

		local proceed_crit = function()
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, victim,
				damage * mult, nil)
			-- print('proceed crit')
			Timers:CreateTimer(0.05, function()
				modifier:cancel(parent)
			end)
		end
		if not parent:PassivesDisabled() and modifier.ready then
			if inflictor and
				inflictor.GetAbilityName then
				--для абилок с уроном от атак
				if ATTACK_DAMAGE_ABILITIES[inflictor:GetAbilityName()] then
					local increased_damage = parent:GetReliableDamage() * mult
					mult = (increased_damage + damage) / damage
					-- print('для абилок с уроном от атак: '..mult)
					proceed_crit()
					return mult

					--для частично процентных абилок
				elseif (SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictor:GetAbilityName()] and
						type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictor:GetAbilityName()]) == "string") then
					local fixed_damage = inflictor:GetSpecialValueFor(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS
						[inflictor:GetAbilityName()])
					mult = GetSpellCrit(mult)
					local increased_damage = (fixed_damage * mult)
					mult = (increased_damage + damage) / damage
					proceed_crit()
					-- print('для частично процентных абилок: ' .. mult)
					-- print('абилка: ' .. inflictor:GetAbilityName())
					return mult

					--все остальные абилки
				elseif FilterDamageSpellAmpCondition(inflictor, inflictor:GetAbilityName(), parent, damage_flags) then
					mult = GetSpellCrit(mult)
					-- print('spell crit')
					proceed_crit()
					-- print('все остальные абилки: ' .. mult)
					return mult
				end
			end

			--тычки
			if not inflictor then
				--modifier.overhead_cooldown = true
				local increased_damage = parent:GetReliableDamage() * mult
				mult = (increased_damage + damage) / damage
				proceed_crit()
				-- print('тычки: ' .. mult)
				return mult
			end
		else
			return 1
		end
	end,
}

INCOMING_DAMAGE_MODIFIERS = {
	--полное избегание урона
	modifier_sans_dodger = {
		multiplier = function(attacker, victim, inflictor, damage)
			local modifier = victim:FindModifierByName("modifier_sans_dodger")
			local ability = modifier:GetAbility()

			if modifier:DodgeCondition() then
				if damage > ability:GetSpecialValueFor("damage_threshold") and (attacker:IsControllableByAnyPlayer() or attacker:IsBoss()) then
					ability:ModifyCharges(-ability:GetSpecialValueFor("dodge_cost"), true)
				end
				if attacker:IsControllableByAnyPlayer() and damage > ability:GetSpecialValueFor("damage_threshold") then
					local distance = ability:GetSpecialValueFor("blink_distance")
					ability:Blink(victim, victim:GetAbsOrigin() + RandomVector(RandomInt(0, distance)))
				end

				SendOverheadEventMessage(victim:GetPlayerOwner(), OVERHEAD_ALERT_EVADE, victim, 1,
					attacker:GetPlayerOwner())
				SendOverheadEventMessage(attacker:GetPlayerOwner(), OVERHEAD_ALERT_MISS, victim, 1,
					victim:GetPlayerOwner())
				return 0
			elseif not inflictor then
				victim:EmitSound("Arena.Hero_Sans.Take_Damage")
			end
		end
	},
	modifier_item_timelords_butterfly = {
		multiplier = function(_, victim)
			if victim:IsAlive() and not victim:IsMuted() and RollPercentage(GetAbilitySpecial("item_timelords_butterfly", "dodge_chance_pct")) then
				ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf",
					PATTACH_ABSORIGIN_FOLLOW, victim)
				return false
			end
		end
	},
	modifier_mirratie_sixth_sense = {
		multiplier = function(_, victim)
			local mirratie_sixth_sense = victim:FindAbilityByName("mirratie_sixth_sense")
			if mirratie_sixth_sense and victim:IsAlive() and RollPercentage(mirratie_sixth_sense:GetAbilitySpecial("dodge_chance_pct")) and not victim:PassivesDisabled() then
				ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf",
					PATTACH_ABSORIGIN_FOLLOW, victim)
				return 0
			end
		end
	},
	modifier_saber_instinct = {
		multiplier = function(attacker, victim, inflictor, damage)
			local saber_instinct = victim:FindAbilityByName("saber_instinct")
			if not IsValidEntity(inflictor) and saber_instinct and victim:IsAlive() and not victim:PassivesDisabled() then
				if attacker:IsRangedUnit() then
					if RollPercentage(saber_instinct:GetAbilitySpecial("ranged_evasion_pct")) then
						local victimPlayer = victim:GetPlayerOwner()
						local attackerPlayer = attacker:GetPlayerOwner()

						SendOverheadEventMessage(victimPlayer, OVERHEAD_ALERT_EVADE, victim, damage, attackerPlayer)
						SendOverheadEventMessage(attackerPlayer, OVERHEAD_ALERT_MISS, victim, damage, victimPlayer)
						ParticleManager:CreateParticle(
							"particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf",
							PATTACH_ABSORIGIN_FOLLOW, victim)
						return false
					end
				else
					if RollPercentage(saber_instinct:GetAbilitySpecial("melee_block_chance")) then
						local blockPct = saber_instinct:GetAbilitySpecial("melee_damage_pct") * 0.01
						return {
							BlockedDamage = blockPct * damage,
						}
					end
				end
			end
		end
	},



	--барьеры
	modifier_item_pipe_of_enlightenment_team_buff = {
		multiplier = function(_, victim, _, damage, damagetype_const)
			--if not mod then return 1 end
			if damagetype_const ~= DAMAGE_TYPE_MAGICAL then return 1 end

			local mod = victim:FindModifierByName("modifier_item_pipe_of_enlightenment_team_buff")
			local stacks = mod:GetStackCount()

			if stacks > damage then
				mod:SetStackCount(math.round(stacks - damage))
				return 0
			else
				Timers:NextTick(function() mod:Destroy() end)
				return 1 - stacks / damage
			end
		end
	},

	--снижение урона с наивысшим приоритетом (до остальных снижений)
	modifier_mana_shield_arena = {
		multiplier = function(attacker, victim, _, damage)
			local medusa_mana_shield_arena = victim:FindAbilityByName("medusa_mana_shield_arena")
			if medusa_mana_shield_arena and not victim:IsIllusion() and victim:IsAlive() and not victim:PassivesDisabled() then
				local absorption_percent = medusa_mana_shield_arena:GetAbilitySpecial("absorption_tooltip") * 0.01
				local ndamage = damage * absorption_percent
				local mana_needed = ndamage / medusa_mana_shield_arena:GetAbilitySpecial("damage_per_mana")
				--if mana_needed <= victim:GetMana() then
				victim:EmitSound("Hero_Medusa.ManaShield.Proc")

				if medusa_mana_shield_arena:IsCooldownReady() and RollPercentage(medusa_mana_shield_arena:GetAbilitySpecial("reflect_chance")) and not victim:IsMagicImmune() and not victim:IsDebuffImmune() then
					medusa_mana_shield_arena:AutoStartCooldown()
					ApplyDamage({
						attacker = victim,
						victim = attacker,
						ability = medusa_mana_shield_arena,
						damage = ndamage,
						damage_type = medusa_mana_shield_arena:GetAbilityDamageType(),
					})
				end
				victim:SpendMana(math.min(victim:GetMana(), mana_needed), medusa_mana_shield_arena)
				local particleName = "particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf"
				local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, victim)
				ParticleManager:SetParticleControl(particle, 0, victim:GetAbsOrigin())
				ParticleManager:SetParticleControl(particle, 1, Vector(mana_needed, 0, 0))
				return 1 - (absorption_percent * math.min(1, victim:GetMana() / mana_needed))
				--end
			end
		end
	},

	modifier_anakim_transfer_pain = {
		multiplier = function(attacker, victim, inflictor, damage)
			local anakim_transfer_pain = victim:FindAbilityByName("anakim_transfer_pain")
			if anakim_transfer_pain and victim:IsAlive() then
				local transfered_damage_pct = anakim_transfer_pain:GetAbilitySpecial("transfered_damage_pct")
				local radius = anakim_transfer_pain:GetAbilitySpecial("radius")
				local dealt_damage = damage * transfered_damage_pct * 0.01
				local summonTable = victim.custom_summoned_unit_ability_anakim_summon_divine_knight

				if summonTable and IsValidEntity(summonTable[1]) and summonTable[1]:IsAlive() and (summonTable[1]:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() <= radius then
					ApplyDamage({
						attacker = attacker,
						victim = summonTable[1],
						ability = anakim_transfer_pain,
						damage = dealt_damage,
						damage_type = DAMAGE_TYPE_PURE
					})
					return 1 - transfered_damage_pct * 0.01
				end
			end
		end
	},

	--снижение урона с наинизшим приоритетом
	modifier_item_behelit_buff = {
		multiplier = function(_, victim)
			local damage_resist = victim:GetNetworkableEntityInfo("behelit_damage_resist")
			return 1 - damage_resist * 0.01
		end
	},
	modifier_item_titanium_bar_active = {
		multiplier = function()
			return 1 - -GetAbilitySpecial("item_titanium_bar", "active_damage_reduction_pct") * 0.01
		end
	},
	modifier_item_blade_mail_arena_active = {
		multiplier = function(_, victim)
			local modifier = victim:FindModifierByNameAndCaster("modifier_item_blade_mail_arena_active", victim)
			if modifier and IsValidEntity(modifier:GetAbility()) then
				return 1 - modifier:GetAbility():GetAbilitySpecial("reduced_damage_pct") * 0.01
			end
		end
	},
	modifier_item_sacred_blade_mail_active = {
		multiplier = function()
			return 1 - GetAbilitySpecial("item_sacred_blade_mail", "reduced_damage_pct") * 0.01
		end
	},
	modifier_intelligence_primary_bonus = {
		multiplier = function(attacker, victim, _, _, _, damage_flags)
			if victim:PassivesDisabled() or victim:IsHexed() then return 1 end
			if HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return 1 end
			local mod = victim:FindModifierByName("modifier_intelligence_primary_bonus")
			local max_bonus = INTELLECT_PRIMARY_BONUS_MAX_BONUS
			local difference = INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT
			if mod.util_ then
				max_bonus = max_bonus * INTELLECT_PRIMARY_BONUS_UPGRADE_MULT
				difference = difference / INTELLECT_PRIMARY_BONUS_UPGRADE_DIFF_MULT
			end
			if victim:IsTrueHero() and attacker:IsHero() then
				local attackerInt = attacker:GetIntellect()
				local victimInt = (victim:GetIntellect())
				local diff

				if attackerInt >= victimInt then
					mod:SetStackCount(0)
					return 1
				end

				if attackerInt < victimInt then
					diff = victimInt / attackerInt
					if diff >= difference then
						mod:SetStackCount(math.round(max_bonus))
						return 1 - max_bonus * 0.01
					else
						diff = 1 - attackerInt / victimInt
						mod:SetStackCount(math.round(max_bonus * diff))
						return 1 - max_bonus * 0.01 * diff
					end
				end
			elseif victim:IsTrueHero() and (attacker:IsCreep() or attacker:IsBoss()) then
				mod:SetStackCount(math.round(max_bonus / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE))
				return 1 - (max_bonus / INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE) * 0.01
			end
		end
	},

	modififer_sara_conceptual_reflection = {
		multiplier = function(attacker, victim, inflictor, damage, damagetype_const)
			local modifier = victim:FindModifierByName("modififer_sara_conceptual_reflection")
			if attacker:IsBuilding() then return 1 end
			if modifier then
				local ability = modifier:GetAbility()
				local cost_pct = ability:GetSpecialValueFor("absorbed_damage_in_cost")
				if not ability:GetAutoCastState() then return 1 end
				if modifier:GetStackCount() == 0 then return 1 end
				if victim:PassivesDisabled() then return 1 end
				local health_to_proc = victim:GetMaxHealth() * ability:GetSpecialValueFor("max_health_damage_proc") *
					0.01
				local mult = 1 - ability:GetSpecialValueFor("damage_decrease") * 0.01
				local cost = (damage - damage * mult) * (cost_pct * 0.01)
				if victim:GetEnergy() >= cost then
					if damage <= health_to_proc then
						victim:ModifyEnergy(-cost)
						return mult
					elseif damage > health_to_proc then
						local parent = victim
						if (attacker:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > ability:GetSpecialValueFor("reflect_radius") then return 1 end
						if not attacker:IsAlive() --[[or not parent:IsAlive()]] or (attacker:IsMagicImmune() and attacker:IsDebuffImmune()) or parent:PassivesDisabled() then return end

						Timers:CreateTimer(0.8, function()
							parent:EmitSound("Ability.LagunaBlade")
							attacker:EmitSound("Ability.LagunaBladeImpact")

							ability.NoDamageAmp = true
							ApplyDamage({
								attacker = parent,
								victim = attacker,
								damage_type = ability:GetAbilityDamageType(),
								damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION +
									DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY,
								damage = damage * ability:GetSpecialValueFor("reflected_damage") * 0.01,
								ability = ability
							})
							victim:ModifyEnergy(-damage * ability:GetSpecialValueFor("reflected_damage") * 0.01)

							local pfx = ParticleManager:CreateParticle(
								"particles/arena/units/heroes/hero_sara/energy_burst.vpcf", PATTACH_ABSORIGIN, parent)
							ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin() + Vector(0, 0, 224))
							ParticleManager:SetParticleControlEnt(pfx, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc",
								attacker:GetAbsOrigin(), true)

							if attacker:GetHealth() == 1 then attacker:Kill(attacker, parent) end
						end)
						ability:SetActivated(true)
						if not ability:IsCooldownReady() then
							ability:StartCooldown(ability.BaseClass.GetCooldown(
								ability, 1) * parent:GetCooldownReduction())
						end
						modifier:SetStackCount(modifier:GetStackCount() - 1)
						modifier.activated = true
						return 1 - ability:GetSpecialValueFor("reflection_damage_decrease") * 0.01
					end
				else
					return 1
				end
			end
		end
	}
}

CREEP_BONUSES_MODIFIERS = {
	modifier_item_golden_eagle_relic = {
		gold = GetAbilitySpecial("item_golden_eagle_relic", "kill_gold"),
		xp = GetAbilitySpecial("item_golden_eagle_relic", "kill_xp")
	},

	modifier_item_skull_of_midas = {
		gold = GetAbilitySpecial("item_skull_of_midas", "kill_gold"),
		xp = GetAbilitySpecial("item_skull_of_midas", "kill_xp")
	},

	modifier_talent_creep_gold = function(self)
		local modifier = self:FindModifierByName("modifier_talent_creep_gold")
		if modifier then
			return { gold = modifier:GetStackCount() }
		end
	end
}
