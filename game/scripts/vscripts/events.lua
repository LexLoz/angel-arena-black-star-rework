--require("modules/duel/data")

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
	local newState = GameRules:State_Get()
	print('game state: ' .. newState)
	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		HeroSelection:CollectPD()
		HeroSelection:HeroSelectionStart()
		GameMode:OnHeroSelectionStart()
	end
end

--events for update new bonuses from attrubutes
function GameMode:InventoryItemAdded(keys)
	--print("InventoryItemAdded")
	local unit = EntIndexToHScript(keys.inventory_parent_entindex)

	if unit:IsHero() and not unit:IsWukongsSummon() then
		MeepoFixes:ShareItems(unit)
	end

	--print(keys.item_entindex)
	local item = EntIndexToHScript(keys.item_entindex)
	--InfinityStones:UpdateMinimapIcons()
	Timers:CreateTimer(0.1, function()
		if IsValidEntity(item) and (STONES_LIST[item:GetName()] or item:GetName() == "item_infinity_gauntlet") and IsValidEntity(unit) then
			if not unit:IsHero() then
				unit:DropItemAtPositionImmediate(item, unit:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
			end
		end
	end)
end

function GameMode:OnReconnected(id)
	print('reconnect')
	Timers:CreateTimer(5, function()
		ReconnectFix(id)
		-- StatsClient:FetchPreGameData()
	end)
end

function GameMode:InventoryItemChange(keys)
	--print("InventoryItemChange")
	local hero = EntIndexToHScript(keys.hero_entindex)
	--InfinityStones:UpdateMinimapIcons()

	if hero:IsHero() and not hero:IsWukongsSummon() then
		MeepoFixes:ShareItems(hero)
		Timers:NextTick(function()
			--Attributes:UpdateAll(hero)
		end)
	end
end

function GameMode:HeroGainedLevel(keys)
	--print("HeroGainedLevel")
	local hero = EntIndexToHScript(keys.hero_entindex)

	if hero:IsHero() and not hero:IsWukongsSummon() and not hero:IsIllusion() then
		Timers:NextTick(function()
			--Attributes:UpdateAll(hero)
		end)

		local parent = hero
		if parent.CustomGain_Strength then
			parent:ModifyStrength((parent.CustomGain_Strength - parent:GetKeyValue("AttributeStrengthGain", nil, true)))
		end
		if parent.CustomGain_Intelligence then
			parent:ModifyIntellect((parent.CustomGain_Intelligence - parent:GetKeyValue("AttributeIntelligenceGain", nil, true)))
		end
		if parent.CustomGain_Agility then
			parent:ModifyAgility((parent.CustomGain_Agility - parent:GetKeyValue("AttributeAgilityGain", nil, true)))
		end
	end
end

-- An NPC has spawned somewhere in game.	This includes heroes
function GameMode:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsCourier() then
		-- print(npc:GetName())
		Structures:OnCourierSpawn(npc)
		return
	end

	--Timers:NextTick(function() npc:AddNewModifier(npc, nil, "modifier_arena_util", nil) end)

	Timers:NextTick(function()
		UpgradeSummons(npc)
	end)

	if not npc:IsHero() then return end
	if HeroSelection:GetState() < HERO_SELECTION_PHASE_END then return end

	local tempest_modifier = npc:FindModifierByName("modifier_arc_warden_tempest_double")
	if tempest_modifier then
		local caster = tempest_modifier:GetCaster()
		if npc:GetUnitName() == "npc_dota_hero" then
			npc:SetUnitName("npc_dota_hero_arena_base")
			npc:AddNewModifier(npc, nil, "modifier_dragon_knight_dragon_form", { duration = 0 })
		end
		if npc:GetFullName() == "npc_arena_hero_aghanim" then
			npc:AddNewModifier(npc, nil, "modifier_invoker_old_beta_invoke_attack", {})
		end

		if npc.tempestDoubleSpawned then
			--Tempest Double resets stats and stuff, so everything needs to be put back where they belong
			Illusions:_copyAbilities(caster, npc)
			npc:ModifyStrength(caster:GetBaseStrength() - npc:GetBaseStrength())
			npc:ModifyIntellect(caster:GetBaseIntellect() - npc:GetBaseIntellect())
			npc:ModifyAgility(caster:GetBaseAgility() - npc:GetBaseAgility())
			npc.Additional_str = caster.Additional_str
			npc.Additional_int = caster.Additional_int
			npc.Additional_agi = caster.Additional_agi
			npc:SetHealth(caster:GetHealth())
			npc:SetMana(caster:GetMana())
		else
			Illusions:_copyEverything(caster, npc)
			npc.tempestDoubleSpawned = true
		end

		local tempestDoubleAbility = npc:FindAbilityByName("arc_warden_tempest_double")
		if tempestDoubleAbility then tempestDoubleAbility:SetLevel(0) end
	end

	--print("spawned")
	Timers:NextTick(function()
		--print("spawned")
		if not IsValidEntity(npc) or not npc:IsAlive() then return end
		--local illusionParent = npc:GetIllusionParent()
		--if illusionParent then Illusions:_copyEverything(illusionParent, npc) end

		DynamicWearables:AutoEquip(npc)
		if npc.ModelOverride then
			npc:SetModel(npc.ModelOverride)
			npc:SetOriginalModel(npc.ModelOverride)
		end
		if not npc:IsWukongsSummon() then
			InitHero(npc)
			npc:AddNewModifier(npc, nil, "modifier_arena_hero", nil)
			npc:AddNewModifier(npc, nil, "modifier_stamina", nil)
			-- npc:AddNewModifier(npc, nil, "modifier_arena_util", nil)

			if not npc:IsIllusion() then
				if npc.ArenaHero then
					local parent = npc
					--print(parent:GetFullName())
					parent:CalculateStatBonus(true)
					local primat = _G[NPC_HEROES_CUSTOM[npc:GetFullName()]["AttributePrimary"]]
					if not primat then
						primat = parent:GetPrimaryAttribute()
					end
					--print(primat)
					if primat == DOTA_ATTRIBUTE_AGILITY then
						npc:AddNewModifier(npc, nil, "modifier_agility_primary_bonus",
							nil)
					end
					if primat == DOTA_ATTRIBUTE_STRENGTH then
						npc:AddNewModifier(npc, nil, "modifier_strength_crit", nil)
					end
					if primat == DOTA_ATTRIBUTE_INTELLECT then
						npc:AddNewModifier(npc, nil,
							"modifier_intelligence_primary_bonus", nil)
					end

					if primat == DOTA_ATTRIBUTE_ALL then npc:AddNewModifier(npc, nil, "modifier_universal_attribute", nil) end
				else
					if npc:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
						npc:AddNewModifier(npc, nil, "modifier_strength_crit", nil)
					end
					if npc:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
						npc:AddNewModifier(npc, nil,
							"modifier_agility_primary_bonus", nil)
					end
					if npc:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
						npc:AddNewModifier(npc, nil,
							"modifier_intelligence_primary_bonus", nil)
					end

					if npc:GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
						npc:AddNewModifier(npc, nil,
							"modifier_universal_attribute", nil)
					end
				end
			end

			if npc:IsTrueHero() then
				npc:ApplyDelayedTalents()

				PlayerTables:SetTableValue("player_hero_indexes", npc:GetPlayerID(), npc:GetEntityIndex())
				CustomAbilities:RandomOMGRollAbilities(npc)
				if not npc.OnDuel and Duel:IsDuelOngoing() then
					Duel:SetUpVisitor(npc)
				end
			end
			if (npc:IsIllusion() or npc:IsStrongIllusion()) and not npc.isCustomIllusion then
				local modifier = npc:FindModifierByName("modifier_illusion")
				Timers:NextTick(function()
					Illusions:_copyEverything(modifier:GetCaster(), npc)
				end)
			end
			if npc then Attributes:UpdateAll(npc) end
		end
	end)
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
	--print("OnItemPickedUp")
	local unitEntity = nil
	if keys.UnitEntitIndex then
		unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
	elseif keys.HeroEntityIndex then
		unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
	end

	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
	--[[if itemEntity.CanOverrideOwner and unitEntity and (unitEntity:IsHero() or unitEntity:IsConsideredHero()) then
		itemEntity:SetOwner(PlayerResource:GetSelectedHeroEntity(keys.PlayerID))
		itemEntity:SetPurchaser(PlayerResource:GetSelectedHeroEntity(keys.PlayerID))
		itemEntity.CanOverrideOwner = nil
	end]]

	if unitEntity and unitEntity:IsHero() and not unitEntity:IsWukongsSummon() then
		MeepoFixes:ShareItems(unitEntity)
	end

	local index = keys.item_entindex
	if not index then
		index = keys.ItemEntityIndex
	end
	local ability = EntIndexToHScript(index)

	if not ability or not ability.GetBehaviorInt then return true end
	local behavior = ability:GetBehaviorInt()

	-- check if the item exists and if it is Vector targeting
	if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING) ~= 0 then
		VectorTarget:UpdateNettable(ability)
	end

	InfinityStones:OnItemPickedUp(EntIndexToHScript(keys.ItemEntityIndex))
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
	local player = PlayerResource:GetPlayer(keys.PlayerID)

	local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
	local abilityname = keys.abilityname
	if hero then
		local ability = hero:FindAbilityByName(abilityname)
		if not ability then ability = FindItemInInventoryByName(hero, abilityname, true) end
		if abilityname == "night_stalker_darkness" and ability then
			CustomGameEventManager:Send_ServerToAllClients("time_nightstalker_darkness",
				{ duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1) })
		end
	end
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
	local treeX = keys.tree_x
	local treeY = keys.tree_y
	if RollPercentage(GetAbilitySpecial("item_tree_banana", "drop_chance_pct")) then
		GameMode:CreateTreeDrop(Vector(treeX, treeY, 0), "item_tree_banana")
	end
end

function GameMode:CreateTreeDrop(location, item)
	local item = CreateItemOnPositionSync(location, CreateItem(item, nil, nil))
	item:SetAbsOrigin(GetGroundPosition(location, item))
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	--local numKills = keys.herokills
	--local killerTeamNumber = keys.teamnumber
	if killerPlayer and victimPlayer then
		Kills:OnEntityKilled(victimPlayer:GetAssignedHero(), killerPlayer:GetAssignedHero())
	end
end

--kill weight increase
function GameMode:KillWeightIncrease()
	local dota_time = GetDOTATimeInMinutesFull()
	--print(GameMode.kill_weight_per_minute)
	--print(dota_time - GameMode.endgame_duels)
	if (dota_time - KILL_WEIGHT_START_INCREASE_MINUTE) == GameMode.kill_weight_per_minute then
		for team, _ in pairsByKeys(Teams.Data) do
			Teams:ChangeKillWeight(team, 1)
		end
		Notifications:TopToAll({ text = "#arena_kill_weight_increase_notifiaction", duration = 10 })
		GameMode.kill_weight_per_minute = GameMode.kill_weight_per_minute + KILL_WEIGHT_BONUS_PER_MINUTE
	end
	return 1
end

-- An entity died
function GameMode:OnEntityKilled(keys)
	-- print('death')
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	local killerEntity
	if keys.entindex_attacker then
		killerEntity = EntIndexToHScript(keys.entindex_attacker)
	end

	if killedUnit then
		--[[--infinity stones drop
		if
		killerEntity:IsTrueHero() and
		killedUnit:IsChampion() and
		GetDOTATimeInMinutesFull() >= STONES_TIME_DROP and
		DROPPED_STONES < #STONES_TABLE and

		RollPercentage(CHAMPIONS_DROP_CHANCE[killerEntity:FindModifierByName("modifier_neutral_champion"):GetStackCount() * (PLAYERS_DROP_CHANCE[killerEntity:GetPlayerID()] or 1)]) then
			local t = true
			local stone
			while t do
				local i = math.random(1, #STONES_TABLE)
				if STONES_TABLE[i][2] then
					STONES_TABLE[i][2] = false
					t = false
					stone = STONES_TABLE[i][1]
					DROPPED_STONES = DROPPED_STONES + 1
				end
			end
			killedUnit:DropItemAtPositionImmediate(stone, killedUnit:GetAbsOrigin())
			local drop_chance_mult = PLAYERS_DROP_CHANCE[killerEntity:GetPlayerID()]
			PLAYERS_DROP_CHANCE[killerEntity:GetPlayerID()] = (drop_chance_mult or 1) / DROP_CHANCE_DECREASE
		end]]
		local killedTeam = killedUnit:GetTeam()
		if killedUnit:IsHero() then
			killedUnit:RemoveModifierByName("modifier_shard_of_true_sight") -- For some reason simple KV modifier not removes on death without this
			if killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
				if killerEntity then
					local killerTeam = killerEntity:GetTeam()
					if killerTeam ~= killedTeam and Teams:IsEnabled(killerTeam) then
						Teams:ModifyScore(killerTeam, Teams:GetTeamKillWeight(killedTeam))
					end
				end

				local respawnTime = killedUnit:CalculateRespawnTime()
				local killedUnits = killedUnit:GetFullName() == "npc_dota_hero_meepo" and
					MeepoFixes:FindMeepos(PlayerResource:GetSelectedHeroEntity(killedUnit:GetPlayerID()), true) or
					{ killedUnit }
				for _, v in ipairs(killedUnits) do
					v:SetTimeUntilRespawn(respawnTime)
					v.RespawnTimeModifierBloodstone = nil
					v.RespawnTimeModifierSaiReleaseOfForge = nil

					if v.OnDuel then
						v.OnDuel = nil
						v.ArenaBeforeTpLocation = nil
					end
				end

				Duel:EndIfFinished()

				if not IsValidEntity(killerEntity) or not killerEntity.GetPlayerOwner or not IsValidEntity(killerEntity:GetPlayerOwner()) then
					Kills:OnEntityKilled(killedUnit, nil)
				elseif killerEntity == killedUnit then
					Kills:OnEntityKilled(killedUnit, killedUnit)
				end
			end
		end

		if killedUnit:IsBoss() and Bosses:IsLastBossEntity(killedUnit) then
			local team = DOTA_TEAM_NEUTRALS
			if killerEntity then
				team = killerEntity:GetTeam()
			end
			Bosses:RegisterKilledBoss(killedUnit, killerEntity, team)
		end

		if killedUnit:IsRealCreep() then
			Spawner:OnCreepDeath(killedUnit)
		end

		if not killedUnit:UnitCanRespawn() then
			killedUnit:ClearNetworkableEntityInfo()
		end

		if killerEntity then
			for _, individual_hero in ipairs(HeroList:GetAllHeroes()) do
				if individual_hero:IsAlive() and individual_hero:HasModifier("modifier_shinobu_hide_in_shadows_invisibility") then
					local shinobu_hide_in_shadows = individual_hero:FindAbilityByName("shinobu_hide_in_shadows")
					if individual_hero:GetTeam() == killedUnit:GetTeam() and individual_hero:GetRangeToUnit(killedUnit) <= shinobu_hide_in_shadows:GetAbilitySpecial("ally_radius") then
						individual_hero:SetHealth(individual_hero:GetMaxHealth())
						shinobu_hide_in_shadows:ApplyDataDrivenModifier(individual_hero, individual_hero,
							"modifier_shinobu_hide_in_shadows_rage", nil)
					end
				end
			end

			if killerEntity:GetTeam() ~= killedTeam and (killerEntity.GetPlayerID or killerEntity.GetPlayerOwnerID) then
				local plId = killerEntity.GetPlayerID ~= nil and killerEntity:GetPlayerID() or
					killerEntity:GetPlayerOwnerID()
				if plId > -1 and not (killerEntity.HasModifier and killerEntity:HasModifier("modifier_item_golden_eagle_relic_enabled")) then
					local gold = RandomInt(killedUnit:GetMinimumGoldBounty(), killedUnit:GetMaximumGoldBounty())
					Gold:ModifyGold(plId, gold)
					if killerEntity:FindModifierByName("modifier_alchemist_goblins_greed") then
						Gold:ModifyGold(plId,
							killerEntity:FindModifierByName("modifier_alchemist_goblins_greed"):GetStackCount())
					end
					SendOverheadEventMessage(killerEntity:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, killedUnit,
						gold * GetGoldMultiplier(killerEntity), killerEntity:GetPlayerOwner())
				end
			end
		end
	end
	InfinityStones:OnEntityKilled(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME and PlayerResource:IsBanned(keys.PlayerID) then
		PlayerResource:KickPlayer(keys.PlayerID)
	end
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
	local plyID = keys.PlayerID
	if not plyID then return end
	local player = PlayerResource:GetPlayer(plyID)
	local itemName = keys.itemname
	local hero = player:GetAssignedHero()
	local itemcost = keys.itemcost

	local recipe = "item_recipe_" .. string.gsub(itemName, "item_", "")
	if GetKeyValue(recipe) and GetKeyValue(recipe, "ItemUseCharges") then
		for i = 0, 11 do
			local item = hero.InventorySnapshot[i]
			if item and item.name == GetKeyValue(recipe, "ItemUseCharges") and item.charges >= GetKeyValue(recipe, "ItemChargeAmount") then
				local newCharges = item.charges - GetKeyValue(recipe, "ItemChargeAmount")
				if newCharges > 0 then
					local newItem = CreateItem(item.name, hero, hero)
					newItem:SetPurchaseTime(item.PurchaseTime)
					newItem:SetPurchaser(item.Purchaser)
					newItem:SetCurrentCharges(newCharges)
					if item.CooldownTimeRemaining > 0 then
						newItem:StartCooldown(item.CooldownTimeRemaining)
					end
					newItem:SetOwner(hero)

					Timers:NextTick(function() hero:AddItem(newItem) end)
				end
			end
		end
	end
end

function GameMode:TrackInventory(unit)
	unit.InventorySnapshot = {}
	for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
		local item = unit:GetItemInSlot(i)
		if item then
			unit.InventorySnapshot[i] = {
				name = item:GetName(),
				charges = item:GetCurrentCharges(),
				PurchaseTime = item:GetPurchaseTime(),
				Purchaser = item:GetPurchaser(),
				CooldownTimeRemaining = item:GetCooldownTimeRemaining(),
			}
		end
	end
end

function GameMode:OnKillGoalReached(team)
	--Duel:EndDuel()
	--PlayerTables:SetTableValue("arena", "duel_timer", 0)
	GameRules:SetSafeToLeave(true)
	GameRules:SetGameWinner(team)
	StatsClient:OnGameEnd(team)
end

function GameMode:OnOneTeamLeft(team)
	--Duel:EndDuel()
	--PlayerTables:SetTableValue("arena", "duel_timer", 0)
	GameRules:SetSafeToLeave(true)
	GameRules:SetGameWinner(team)
	StatsClient:OnGameEnd(team)
end
