Events:Register("activate", function ()
	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(GameMode, 'ExecuteOrderFilter'), GameRules)
	GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(GameMode, 'DamageFilter'), GameRules)
	GameRules:GetGameModeEntity():SetModifyGoldFilter(Dynamic_Wrap(GameMode, 'ModifyGoldFilter'), GameRules)
	GameRules:GetGameModeEntity():SetModifyExperienceFilter(Dynamic_Wrap(GameMode, 'ModifyExperienceFilter'), GameRules)
	GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(Dynamic_Wrap(GameMode, 'ItemAddedToInventoryFilter'), GameRules)
	GameRules:GetGameModeEntity():SetHealingFilter(Dynamic_Wrap(GameMode, 'HealFilter'), GameRules)
	GameRules:GetGameModeEntity():SetModifierGainedFilter(Dynamic_Wrap(GameMode, 'ModifiersFilter'), GameRules)
end)

function GameMode:ModifiersFilter(filterTable)
	local name
	local caster
	local parent
	local ability

	if filterTable.name_const then
		name = filterTable.name_const
	end

	if filterTable.entindex_caster_const then
		caster = EntIndexToHScript(filterTable.entindex_caster_const)
	end

	if filterTable.entindex_parent_const then
		parent = EntIndexToHScript(filterTable.entindex_parent_const)
	end

	if filterTable.entindex_ability_const then
		ability = EntIndexToHScript(filterTable.entindex_ability_const)
	end

	--print(BAT_DECREASE_MODIFIERS[name])

	if parent and name and ability and BAT_DECREASE_MODIFIERS[name] then
		for k,v in pairs(parent.change_bat_modifiers) do
			if v and parent:HasModifier(v.name) then
				return true
			end
		end
		local default_bat = parent:GetKeyValue("AttackRate")
		local ability_bat = ability:GetSpecialValueFor("base_attack_time")
		local difference = math.abs(default_bat - ability_bat)
		parent.outside_change_bat = parent.outside_change_bat - difference
		parent.change_bat_modifiers = parent.change_bat_modifiers or {}
		table.insert(parent.change_bat_modifiers, {name = name, change = difference})
		parent:SetNetworkableEntityInfo("BaseAttackTime", default_bat + parent.outside_change_bat)
		--print(parent.outside_change_bat)
	end
	
	return true
end

function GameMode:HealFilter(filterTable)
	--print("1")
	local healer
	if filterTable.entindex_healer_const then
		healer = EntIndexToHScript(filterTable.entindex_healer_const)
	end
	local inflictor
	if filterTable.entindex_inflictor_const then
		inflictor = EntIndexToHScript(filterTable.entindex_inflictor_const)
	end
	local target
	if filterTable.entindex_target_const then
		target = EntIndexToHScript(filterTable.entindex_target_const)
	end
	local saving_heal = filterTable.heal

	if IsValidEntity(target) and IsValidEntity(inflictor) then
		local inflictorname = inflictor.GetAbilityName and inflictor:GetAbilityName() or nil
		for _,v in pairs(REGEN_EXEPTIONS) do
			if target:HasModifier(v[1]) then
				local ability = target:FindModifierByName(v[1]):GetAbility()
				if ability == inflictor then
					return true
				end
			end
		end
		--print(healer.HPRegenAmplify)
		local interval_mult = GetIntervalMult(inflictor, "_healInterval")
		if inflictorname and (not NO_HEAL_AMPLIFY[inflictorname] and not inflictor.NoHealAmp) then
			local heal_mult = (healer.HPRegenAmplify or 1) + (target.HPRegenAmplify or 1)
			filterTable.heal = math.min(5000, filterTable.heal)
			if healer.HPRegenAmplify > SPEND_MANA_PER_HEAL_MULT_THRESHOLD then
				SpendManaPerDamage(healer, inflictor, filterTable.heal * (heal_mult - SPEND_MANA_PER_HEAL_MULT_THRESHOLD), interval_mult, "ManaSpendCooldownHeal", SPEND_MANA_PER_HEAL)
			end
			filterTable.heal = math.min(2000000000, filterTable.heal * heal_mult * GetLowManaMultiplier(healer.HPRegenAmplify, healer, SPEND_MANA_PER_HEAL_MULT_THRESHOLD, SPEND_MANA_PER_HEAL_MAX_REDUCE_THRESHOLD))
			--print(filterTable.heal)
		end
	end
	-- print(filterTable.heal)
	filterTable.heal = math.min(2000000000, filterTable.heal)
	return true
end

function GameMode:ExecuteOrderFilter(filterTable)
	if filterTable.units and filterTable.units["0"] then
		unit = EntIndexToHScript(filterTable.units["0"])
	end
	local target = filterTable.entindex_target ~= 0 and EntIndexToHScript(filterTable.entindex_target) or nil
	local orderType = filterTable["order_type"]

    -- if unit and unit:IsRealHero() then
    --     if unit:HasModifier("modifier_fymryn_shadow_step_start") or unit:HasModifier("modifier_fymryn_shadow_step") or unit:HasModifier("modifier_fymryn_shadow_step_end") then
    --         if orderType == DOTA_UNIT_ORDER_CAST_POSITION or orderType == DOTA_UNIT_ORDER_CAST_TARGET or orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then
    --             return false
    --         end
    --     end
    -- end

	local ability = EntIndexToHScript(filterTable.entindex_ability)
	if not ability or not ability.GetBehaviorInt then return true end
	local behavior = ability:GetBehaviorInt()


	local order_type = filterTable.order_type
	local playerId = filterTable.issuer_player_id_const
	if order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
		return false
	end
	local target = EntIndexToHScript(filterTable.entindex_target)
	local ability = EntIndexToHScript(filterTable.entindex_ability)
	local abilityname
	if ability and ability.GetAbilityName then
		abilityname = ability:GetAbilityName()
	end
	if order_type == DOTA_UNIT_ORDER_TRAIN_ABILITY and Options:IsEquals("EnableAbilityShop") then
		CustomAbilities:OnAbilityBuy(playerId, abilityname)
		return false
	end



	--[[if ability and ability.GetCaster then
		local caster = ability:GetCaster()
		if ability.ManaSpend and ability.ManaSpend > caster:GetMana() then
			--print(ability.ManaSpend)
			Containers:DisplayError(playerId, "#arena_hud_error_no_mana")
			return false
		end
	end]]

	local unit = EntIndexToHScript(filterTable.units["0"])

	if unit and order_type == DOTA_UNIT_ORDER_SELL_ITEM and ability then
		PanoramaShop:SellItem(playerId, unit, ability)
		return false
	end

	if unit:IsCourier() then
		if (
			order_type == DOTA_UNIT_ORDER_CAST_POSITION or
			order_type == DOTA_UNIT_ORDER_CAST_TARGET or
			order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE or
			order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET or
			order_type == DOTA_UNIT_ORDER_CAST_TOGGLE
		) and ability and ability:IsItem() then
			Containers:DisplayError(playerId, "dota_hud_error_courier_cant_use_item")
			return false
		end

		if (order_type == DOTA_UNIT_ORDER_DROP_ITEM or order_type == DOTA_UNIT_ORDER_GIVE_ITEM) and ability and ability:IsItem() then
			local purchaser = ability:GetPurchaser()
			if purchaser and purchaser:GetPlayerID() ~= playerId then
				Containers:DisplayError(playerId, "arena_hud_error_courier_cant_order_item")
				return false
			end
		end
	end

	if not unit:IsConsideredHero() then return true end

	GameMode:TrackInventory(unit)
	if not ability then return true end

	if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
		if (
			abilityname == "item_ward_sentry" or
			(abilityname == "item_ward_dispenser" and not ability:GetToggleState())
		) then
			local team = PlayerResource:GetTeam(playerId)
			local wards = {}
			for _, ward in ipairs(Entities:FindAllByClassname("npc_dota_ward_base_truesight")) do
				if ward:GetUnitName() == "npc_dota_sentry_wards" and ward:GetTeamNumber() == team then
					table.insert(wards, ward)
				end
			end
			if #wards > 20 then
				Containers:DisplayError(playerId, "arena_hud_error_sentry_ward_limit")
				return false
			end
		end
		if not Duel:IsDuelOngoing() and ARENA_NOT_CASTABLE_ABILITIES[abilityname] then
			local orderVector = Vector(filterTable.position_x, filterTable.position_y, 0)
			if type(ARENA_NOT_CASTABLE_ABILITIES[abilityname]) == "number" then
				local ent1len = (orderVector - Entities:FindByName(nil, "target_mark_arena_team2"):GetAbsOrigin()):Length2D()
				local ent2len = (orderVector - Entities:FindByName(nil, "target_mark_arena_team3"):GetAbsOrigin()):Length2D()
				if ent1len <= ARENA_NOT_CASTABLE_ABILITIES[abilityname] + 200 or ent2len <= ARENA_NOT_CASTABLE_ABILITIES[abilityname] + 200 then
					Containers:DisplayError(playerId, "#arena_hud_error_cant_target_duel")
					return false
				end
			end
			for _, box in ipairs(Duel.Boxes) do
				if IsInTriggerBox(box.trigger, 96, orderVector) then
					Containers:DisplayError(playerId, "#arena_hud_error_cant_target_duel")
					return false
				end
			end
		end
	elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET and IsValidEntity(target) then
		if abilityname == "rubick_spell_steal" then
			if target == unit then
				Containers:DisplayError(playerId, "#dota_hud_error_cant_cast_on_self")
				return false
			end
			if target:HasAbility("doppelganger_mimic") then
				Containers:DisplayError(playerId, "#dota_hud_error_cant_steal_spell")
				return false
			end
			if target:HasAbility("sans_dodger") then
				Containers:DisplayError(playerId, "#dota_hud_error_cant_steal_spell")
				return false
			end
		end
		if abilityname == "morphling_replicate" then
			if target:HasAbility("doppelganger_mimic") then
				Containers:DisplayError(playerId, "#arena_hud_error_cant_replicate_hero")
				return false
			end
			if target:GetFullName() == unit:GetFullName() then
				Containers:DisplayError(playerId, "#arena_hud_error_cant_replicate_hero")
				return false
			end
		end
		if target:IsChampion() and CHAMPIONS_BANNED_ABILITIES[abilityname] then
			Containers:DisplayError(playerId, "#dota_hud_error_ability_cant_target_champion")
			return false
		end
		if target:IsJungleBear() and JUNGLE_BANNED_ABILITIES[abilityname] then
			Containers:DisplayError(playerId, "#dota_hud_error_ability_cant_target_jungle")
			return false
		end
		if target:IsBoss() and BOSS_BANNED_ABILITIES[abilityname] then
			Containers:DisplayError(playerId, "#dota_hud_error_ability_cant_target_boss")
			return false
		end
	elseif order_type == DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK then
		local lockType = filterTable.entindex_target
		if ability.auto_lock_order then
			ability.auto_lock_order = false
		elseif lockType == 0 then
			ability.player_locked = false
		else
			ability.player_locked = true
		end
	end

	return true
end

function GameMode:DamageFilter(filterTable)
	local damagetype_const = filterTable.damagetype_const
	local damage = filterTable.damage
	local inflictor
	if filterTable.entindex_inflictor_const then
		inflictor = EntIndexToHScript(filterTable.entindex_inflictor_const)
	end
	local attacker
	if filterTable.entindex_attacker_const then
		attacker = EntIndexToHScript(filterTable.entindex_attacker_const)
	end
	local victim = EntIndexToHScript(filterTable.entindex_victim_const)
	--print(filterTable.damage)

	if IsValidEntity(attacker) then
		if attacker:HasAbility("sans_curse") and (victim:GetTeam() ~= attacker:GetTeam() and victim:IsTrueHero() and victim:IsControllableByAnyPlayer()) then
			local percent = victim:GetHealth() / victim:GetMaxHealth() * 100
			if percent > 1 then
				filterTable.damage = 0
			else
				filterTable.damage = victim:GetHealth()
			end
		end
		-- elseif attacker:HasAbility("sans_curse") and victim:GetTeam() == DOTA_TEAM_NEUTRALS and victim:IsCreep() then
		-- 	filterTable.damage = filterTable.damage * 0.25
		-- end
		if victim:HasModifier("modifier_sans_curse") then
			local modifier = victim:FindModifierByName("modifier_sans_curse")
			local caster = modifier:GetAbility():GetCaster()
			local talent = caster:HasTalent("talent_hero_comic_sans_karma_aura")

			if talent and attacker ~= caster and (victim:GetTeam() ~= caster:GetTeam() and victim:IsTrueHero() and victim:IsControllableByAnyPlayer()) then
				filterTable.damage = filterTable.damage / 2
			end
		end

		if IsValidEntity(inflictor) and inflictor.GetAbilityName then
			filterTable.damage = DamageSubtypesFilter(inflictor, attacker, victim, filterTable.damage) or filterTable.damage
			--filterTable = DamageHasInflictor(inflictor, filterTable, attacker, victim, damagetype_const)
		end

		if attacker.GetPlayerOwnerID then
			local attackerPlayerId = attacker:GetPlayerOwnerID()
			if attackerPlayerId > -1 then
				if victim:IsRealHero() then
					PlayerResource:ModifyPlayerStat(attackerPlayerId, "heroDamage", filterTable.damage)
				end
				if victim:IsBoss() then
					PlayerResource:ModifyPlayerStat(attackerPlayerId, "bossDamage", filterTable.damage)
					victim.DamageReceived = victim.DamageReceived or {}
					victim.DamageReceived[attackerPlayerId] = (victim.DamageReceived[attackerPlayerId] or 0) + filterTable.damage
				end
			end
		end

	end
	return true
end

function GameMode:ModifyGoldFilter(filterTable)
	local reason = filterTable.reason_const
	if reason >= DOTA_ModifyGold_Building and reason <= DOTA_ModifyGold_CourierKill then
		filterTable.gold = 0
		return false
	end
	print("[GameMode:ModifyGoldFilter]: Attempt to call default dota gold modify func... FIX IT - Reason: " .. filterTable.reason_const .."  --  Amount: " .. filterTable.gold)
	filterTable.gold = 0
	return false
end


function GameMode:ModifyExperienceFilter(filterTable)
	local hero = PlayerResource:GetSelectedHeroEntity(filterTable.player_id_const)
	if hero then
		local item_chest_of_midas = FindItemInInventoryByName(hero, "item_chest_of_midas", false, false, true)
		item_chest_of_midas = item_chest_of_midas and item_chest_of_midas:GetSpecialValueFor("bonus_exp_pct") * 0.01 or 0
		-- print(item_chest_of_midas)
		local talent = 0
		local acceleration = 0
		if hero.talent_keys and hero.talent_keys.bonus_experience_percentage then
			talent = talent + hero.talent_keys.bonus_experience_percentage * 0.01
		end
		for _,v in ipairs(hero:FindAllModifiersByName("modifier_arena_rune_acceleration")) do
			if v.xp_multiplier then
				acceleration = acceleration + v.xp_multiplier
			end
		end
		filterTable.experience = filterTable.experience * (1 + item_chest_of_midas + talent + acceleration)
		if hero:GetFullName() == "npc_arena_hero_comic_sans" then
			filterTable.experience = filterTable.experience * 1.5
		end
	end
	PLAYER_DATA[filterTable.player_id_const].AntiAFKLastXP = GameRules:GetGameTime() + PLAYER_ANTI_AFK_TIME
	--if Duel.IsFirstDuel and Duel:IsDuelOngoing() then
		--filterTable.experience = filterTable.experience * 0.1
	--end
	return true
end

function GameMode:ItemAddedToInventoryFilter(filterTable)
	local item = EntIndexToHScript(filterTable.item_entindex_const)
	local unit = EntIndexToHScript(filterTable.inventory_parent_entindex_const)
	local item_name = item:GetAbilityName()

	-- print(item.RuneType)
	if item.RuneType and not unit:IsCourier() then
		CustomRunes:PickUpRune(unit, item)
		return false
	end

	if (STONES_LIST[item_name] or item_name == "item_infinity_gauntlet") and not unit:IsTrueHero() then
		return false
	end

	if item.suggestedSlot then
		filterTable.suggested_slot = item.suggestedSlot
		item.suggestedSlot = nil
	end
	return true
end
