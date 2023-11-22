ModuleRequire(..., "data")
if not Kills then
	_G.Kills = class({})
end

function Kills:GetExpForKill(killerUnit, killedUnit)
	if Duel.IsFirstDuel and Duel:IsDuelOngoing() then
		return 0
	end

	local killerLvl = killerUnit:GetLevel()
	local killedLvl = killedUnit:GetLevel()
	local streak = Kills:GetKillStreak(killedUnit:GetPlayerID())

	local difference = killerLvl - killedLvl
	-- print(difference)

	local exp_for_level = (XP_PER_LEVEL_TABLE[killerLvl + 1] or XP_PER_LEVEL_TABLE[killerLvl]) -
	XP_PER_LEVEL_TABLE[killerLvl]

	if difference > 0 then
		local upped_levels = math.floor(killerLvl / 100)
		local newLevel = math.min(killerLvl + upped_levels, #XP_PER_LEVEL_TABLE)
		return exp_for_level * 0.25 +
			(XP_PER_LEVEL_TABLE[newLevel] - XP_PER_LEVEL_TABLE[killerLvl]) +
			((XP_PER_LEVEL_TABLE[killerLvl + streak] or XP_PER_LEVEL_TABLE[killerLvl]) - XP_PER_LEVEL_TABLE[killerLvl]) *
			0.5
	elseif difference == 0 then
		return exp_for_level * 0.75 +
			((XP_PER_LEVEL_TABLE[killerLvl + streak] or XP_PER_LEVEL_TABLE[killerLvl]) - XP_PER_LEVEL_TABLE[killerLvl]) *
			0.5
	elseif difference < 0 then
		local newLevel = math.min(killerLvl - difference, #XP_PER_LEVEL_TABLE)
		return (XP_PER_LEVEL_TABLE[newLevel] - XP_PER_LEVEL_TABLE[killerLvl]) * 0.5 +
			((XP_PER_LEVEL_TABLE[killerLvl + streak] or XP_PER_LEVEL_TABLE[killerLvl]) - XP_PER_LEVEL_TABLE[killerLvl]) *
			0.5
	end
	return 0
end

function Kills:GetGoldForKill(killedUnit, killerPlayer)
	local playerID = killedUnit:GetPlayerID()
	local killStreak = Kills:GetKillStreakGold(playerID)
	local victimLevel = killedUnit:GetLevel()
	local killerUnit = killerPlayer and killerPlayer:GetAssignedHero() or nil
	local attackerLevel = killerUnit and killerUnit:GetLevel() or victimLevel
	local victimNetworth = killedUnit:GetNetWorth()
	local killerNetworth = killerUnit and killerUnit:GetNetWorth() or victimNetworth
	-- print('killer networth: ' .. killerNetworth)
	-- print('victim networth: ' .. victimNetworth)
	-- print('mult: ' .. math.max(0.1, math.min(victimNetworth / killerNetworth, 10)))
	local creepStat = PlayerResource:GetNearbyCreepDeaths(playerID)
	local killWeight = Teams:GetTeamKillWeight(killedUnit:GetTeamNumber())
	local minute = GetDOTATimeInMinutesFull()

	local gold = math.floor((125 + killStreak + victimLevel * 15 + victimNetworth * 0.1) *
		math.max(0.5, math.min(victimNetworth / killerNetworth, 5))) --* (minute >= KILL_WEIGHT_START_INCREASE_MINUTE / 2 and killWeight or 1))
	print('gold for kill: ' .. gold)

	return --[[(Duel.IsFirstDuel and Duel:IsDuelOngoing()) and 0 or]] gold
end

function Kills:SetKillStreak(player, ks)
	PLAYER_DATA[player].KillStreak = ks
end

function Kills:SetDeathStreak(player, ds)
	PLAYER_DATA[player].DeathStreak = ds
end

function Kills:GetKillStreak(player)
	return math.min(10, PLAYER_DATA[player].KillStreak or 0)
end

function Kills:GetDeathStreak(player)
	return math.min(10, PLAYER_DATA[player].DeathStreak or 0)
end

function Kills:GetKillStreakGold(player)
	return KILL_STREAK_GOLD[Kills:GetKillStreak(player)] or KILL_STREAK_GOLD[#KILL_STREAK_GOLD]
end

function Kills:IncreaseKillStreak(player)
	Kills:SetKillStreak(player, Kills:GetKillStreak(player) + 1)
end

function Kills:IncreaseDeathStreak(player)
	Kills:SetDeathStreak(player, Kills:GetDeathStreak(player) + 1)
end

function Kills:OnEntityKilled(killedPlayer, killerPlayer)
	if not killedPlayer then
		return
	end
	local killedUnit = killedPlayer:GetAssignedHero()
	local killedPlayerID = killedPlayer:GetPlayerID()

	local killerEntity
	local killerPlayerID
	if killerPlayer then
		killerEntity = killerPlayer:GetAssignedHero()
		if killerEntity.GetPlayerID then
			killerPlayerID = killerEntity:GetPlayerID()
		elseif killerEntity.GetPlayerOwnerID then
			killerPlayerID = killerEntity:GetPlayerOwnerID()
		end
	end
	local goldChange = Kills:GetGoldForKill(killedUnit, killerPlayer)
	local isDeny = false
	if killerEntity and killerEntity:IsControllableByAnyPlayer() then
		if killerEntity.GetPlayerID or killerEntity.GetPlayerOwnerID then
			if killerEntity == killedUnit then
				Kills:CreateKillTooltip(killedPlayerID, killedPlayerID)
				isDeny = true
			elseif killerEntity:GetTeamNumber() == killedUnit:GetTeamNumber() then
				Kills:CreateKillTooltip(killerPlayerID, killedPlayerID)
				isDeny = true
			else
				local expChange = Kills:GetExpForKill(killerEntity, killedUnit)

				Kills:IncreaseDeathStreak(killedPlayerID)
				local respawnTime = killedUnit:CalculateRespawnTime()
				Timers:CreateTimer(respawnTime + 1, function()
					killedUnit:AddNewModifier(killedUnit, nil, "modifier_death_streak", nil):SetStackCount(Kills:GetDeathStreak(killedPlayerID))
				end)

				Kills:IncreaseKillStreak(killerPlayerID)
				killerEntity:AddNewModifier(killerEntity, nil, "modifier_kill_streak", nil):SetStackCount(Kills:GetKillStreak(killerPlayerID))
				Kills:SetDeathStreak(killerPlayerID, 0)
				killerEntity:RemoveModifierByName("modifier_death_streak")

				-- if not Duel.IsFirstDuel or not Duel:IsDuelOngoing() then
				-- 	Kills:IncreaseKillStreak(killerPlayerID)
				-- end

				if killerEntity:HasModifier("modifier_item_golden_eagle_relic_enabled") then
					goldChange = 0
					expChange = 0
				end
				--уменьшение золота жертвы
				if killedUnit:GetNetWorth() > killerEntity:GetNetWorth() then
					Gold:ModifyGold(killedUnit, -(Gold:GetGold(killedUnit:GetPlayerID()) * 0.5))
				end

				Kills:CreateKillTooltip(killerPlayerID, killedPlayerID, goldChange * GetGoldMultiplier(killerEntity))
				Kills:_GiveKillGold(killerEntity, killedUnit, goldChange)
				killerEntity:AddExperience(expChange, DOTA_ModifyXP_HeroKill, false, false)
			end
		else
			Kills:CreateKillTooltip(nil, killedPlayerID, goldChange)
		end
		if not isDeny then
			local assists = FindUnitsInRadius(killerEntity:GetTeamNumber(), killedUnit:GetAbsOrigin(), nil,
				HERO_ASSIST_RANGE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			local assistGold = math.round(goldChange * 0.5)
			local hadGold = { killerPlayerID }
			for _, v in ipairs(assists) do
				if v ~= killerEntity and v and v:IsMainHero() then
					if not table.includes(hadGold) then
						local assistExp = Kills:GetExpForKill(v, killedUnit) * 0.5
						Kills:_GiveKillGold(v, killedUnit, assistGold)
						v:AddExperience(assistExp, DOTA_ModifyXP_HeroKill, false, false)
						table.insert(hadGold, v:GetPlayerID())
					end
				end
			end
		end
	else
		local assistGold = math.round(goldChange * 0.5)
		for playerId = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(playerId) and PlayerResource:GetTeam(playerId) ~= killedUnit:GetTeamNumber() then
				local player = PlayerResource:GetPlayer(playerId)
				if player and player:GetAssignedHero() then
					SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, player:GetAssignedHero(),
						(assistGold * GetGoldMultiplier(player:GetAssignedHero())), player)
				end
				Gold:ModifyGold(playerId, assistGold)
			end
		end
		Kills:CreateKillTooltip(nil, killedPlayerID, assistGold)
	end
	if not isDeny then
		local streak = Kills:GetKillStreak(killedPlayerID)
		if streak > 1 then
			CustomGameEventManager:Send_ServerToAllClients("create_custom_toast", {
				type = "generic",
				text = "#custom_toast_KillStreak_Ended",
				victimPlayer = killedPlayerID,
				teamPlayer = killedPlayerID,
				teamInverted = true,
				variables = {
					["{kill_streak}"] = streak
				}
			})
		end
		Kills:SetKillStreak(killedPlayerID, 0)
		killedUnit:RemoveModifierByName("modifier_kill_streak")
	end
end

function Kills:_GiveKillGold(killerEntity, killedUnit, goldChange)
	local plId = -1
	if killerEntity.GetPlayerID then
		plId = killerEntity:GetPlayerID()
	end
	if plId == -1 and killerEntity.GetPlayerOwnerID then
		plId = killerEntity:GetPlayerOwnerID()
	end
	if plId ~= -1 then
		Gold:ModifyGold(plId, goldChange)
		SendOverheadEventMessage(killerEntity:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, killedUnit,
			math.round(goldChange * GetGoldMultiplier(killerEntity:GetPlayerOwner():GetAssignedHero())),
			killerEntity:GetPlayerOwner())
	end
end

function Kills:CreateKillTooltip(killer, killed, gold)
	CustomGameEventManager:Send_ServerToAllClients("create_custom_toast", {
		type = "kill",
		killerPlayer = killer,
		victimPlayer = killed,
		gold = gold,
	})
end
