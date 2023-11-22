CUSTOMCHAT_COMMAND_LEVEL_PUBLIC = 0
CUSTOMCHAT_COMMAND_LEVEL_CHEAT = 1
CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER = 2
CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER = 3

return {
	-- ['reconnectfix'] = {
	-- 	level = CUSTOMCHAT_COMMAND_LEVEL_PUBLIC,
	-- 	f = function(args, hero)
	-- 		ReconnectFix(hero:GetPlayerID())
	-- 	end
	-- },
	["someshit"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function()
			HeroSelection:SetState(HERO_SELECTION_PHASE_END)
			-- HeroSelection:StartStateInGame({})
		end
	},
	["option"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			Options:SetValue(args[1], args[2] == "1" and true or false)
		end
	},
	["killweight"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for team, _ in pairsByKeys(Teams.Data) do
				local current_weight = 0
				Teams.Data[team].kill_weight_increased = 0
				Teams:SetTeamKillWeight(team, args[1])
			end
		end
	},
	["respawn_zeld"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function()
			if not Bosses:IsAlive("cursed_zeld") then
				Bosses:SpawnStaticBoss("cursed_zeld")
			end
		end
	},
	["spp"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function()
			if HeroSelection.CurrentState == HERO_SELECTION_PHASE_BANNING then
				HeroSelection:StartStateHeroPick()
			elseif HeroSelection.CurrentState == HERO_SELECTION_PHASE_HERO_PICK then
				HeroSelection:StartStateStrategy()
			elseif HeroSelection.CurrentState == HERO_SELECTION_PHASE_STRATEGY then
				HeroSelection:StartStateInGame({})
			elseif HeroSelection.CurrentState == HERO_SELECTION_PHASE_END then
				Tutorial:ForceGameStart()
			end
		end
	},
	["mr"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function()
			for i = 0, 23 do
				if PlayerResource:IsValidPlayerID(i) then
					local hero = PlayerResource:GetSelectedHeroEntity(i)
					ReloadUnitModifiers(hero)
				end
			end
		end
	},
	["sr"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function(args, hero)
			-- StatsClient:AddGuide(nil)
			SendToServerConsole('script_reload')
		end
	},
	["timescale"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args)
			local value = tonumber(args[1])
			if value < 1 then value = 1 end -- if arg < 1 server freezes
			Convars:SetInt("host_timescale", value)
		end
	},
	["gold"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			Gold:ModifyGold(hero, tonumber(args[1]))
		end
	},
	["spawnrune"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function()
			CustomRunes:SpawnRunes()
		end
	},
	["t"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for i = 2, 50 do
				if XP_PER_LEVEL_TABLE[hero:GetLevel()] and XP_PER_LEVEL_TABLE[hero:GetLevel() + 1] then
					hero:AddExperience(XP_PER_LEVEL_TABLE[hero:GetLevel() + 1] - XP_PER_LEVEL_TABLE[hero:GetLevel()], 0,
						false, false)
				else
					break
				end
			end
			hero:AddItem(CreateItem("item_blink", hero, hero))
			hero:AddItem(CreateItem("item_rapier_arena", hero, hero))
			SendToServerConsole("dota_ability_debug 1")
		end
	},
	["stats"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			local i = tonumber(args[1])
			hero.Additional_str = (hero.Additional_str or 0) + i
			hero.Additional_agi = (hero.Additional_agi or 0) + i
			hero.Additional_int = (hero.Additional_int or 0) + i
			hero:ModifyAgility(i)
			hero:ModifyStrength(i)
			hero:ModifyIntellect(i)
			Attributes:UpdateAll(hero)
		end
	},
	["duel"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args)
			Duel:SetDuelTimer(args[1] or 0)
		end
	},
	["killcreeps"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for _, v in ipairs(FindUnitsInRadius(hero:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
				v:ForceKill(true)
			end
		end
	},
	["reset"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for i = 0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					RecreateAbility(hero, ability):SetLevel(0)
				end
			end
		end
	},
	["createcreep"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			local sName = tostring(args[1]) or "medium"
			local SpawnerType = tonumber(args[2]) or 0
			local time = tonumber(args[3]) or 0
			local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
			PrintTable(SPAWNER_SETTINGS[sName])
			local unit = CreateUnitByName(unitRootTable[1][-1], hero:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
			unit.SpawnerIndex = SpawnerType
			unit.SpawnerType = sName
			unit.SSpawner = -1
			unit.SLevel = time
			Spawner:UpgradeCreep(unit, unit.SpawnerType, unit.SLevel, unit.SpawnerIndex)
		end
	},
	["talents_clear"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			hero:ClearTalents()
		end
	},
	["equip"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			DynamicWearables:EquipWearable(hero, tonumber(args[1]))
		end
	},
	["reattach"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			DynamicWearables:UnequipAll(hero)
			DynamicWearables:AutoEquip(hero)
		end
	},
	["maxenergy"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			hero:ModifyMaxEnergy(args[1] - hero:GetMaxEnergy())
		end
	},
	["runetest"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for i = ARENA_RUNE_FIRST, ARENA_RUNE_LAST do
				CustomRunes:CreateRune(hero:GetAbsOrigin() + RandomVector(RandomInt(90, 300)), i)
			end
		end
	},


	["debugallcalls"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function()
			DebugAllCalls()
		end
	},
	["dcs"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function()
			_G.DebugConnectionStates = not DebugConnectionStates
		end
	},
	["kick"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function(args)
			PlayerResource:KickPlayer(tonumber(args[1]))
		end
	},
	["model"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			hero:SetModel(args[1])
			hero:SetOriginalModel(args[1])
		end
	},
	["pick"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero, playerId)
			HeroSelection:ChangeHero(playerId, args[1], true, 0)
		end
	},
	["abandon"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			if PlayerResource:IsValidPlayerID(tonumber(args[1])) then
				PlayerResource:MakePlayerAbandoned(tonumber(args[1]))
			end
		end
	},
	["ban"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			local playerId = tonumber(args[1])
			if not PlayerResource:IsValidPlayerID(playerId) then return end

			PLAYER_DATA[playerId].isBanned = true
			PlayerResource:MakePlayerAbandoned(playerId)
			PlayerResource:KickPlayer(playerId)
		end
	},
	["a_createhero"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero, playerId)
			local heroName = args[1]
			local optplayerId
			if tonumber(args[2]) then optplayerId = tonumber(args[2]) end
			local heroTableCustom = NPC_HEROES_CUSTOM[heroName]
			local baseNewHero = heroTableCustom.base_hero or heroName
			local heroEntity = optplayerId and
				PlayerResource:ReplaceHeroWith(optplayerId, baseNewHero, 0, 0) or
				CreateHeroForPlayer(baseNewHero, PlayerResource:GetPlayer(playerId))

			local team = 2
			if PlayerResource:GetTeam(optplayerId or playerId) == team and table.includes(args, "enemy") then
				team = 3
			end
			heroEntity:SetTeam(team)
			heroEntity:SetAbsOrigin(hero:GetAbsOrigin())

			heroEntity:SetControllableByPlayer(playerId, true)
			if optplayerId then
				heroEntity:SetControllableByPlayer(optplayerId, true)
			end
			for i = 1, 300 do
				heroEntity:HeroLevelUp(false)
			end
			if optplayerId then
				HeroSelection:ChangeHero(optplayerId, heroName, true, 0)
			else
				HeroSelection:InitializeHeroClass(heroEntity, heroTableCustom)
				if heroTableCustom.base_hero then
					TransformUnitClass(heroEntity, heroTableCustom)
					heroEntity.UnitName = heroName
				end
			end
		end
	},
	["consts"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args)
			for k, v in pairs(_G) do
				if string.find(k, args[1]) then
					print(k, v)
				end
			end
		end
	},
	["end"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function(args, hero)
			local team = tonumber(args[1])
			if team then
				GameMode:OnKillGoalReached(team)
			end
		end
	},
	["weather"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args)
			local weather = tostring(args[1])
			if weather then
				Weather:Start(weather)
			end
		end
	},
	["console"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function(_, _, playerId)
			Console:SetVisible(PlayerResource:GetPlayer(playerId))
		end
	},
}
