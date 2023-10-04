CUSTOM_GOLD_PER_TICK = 2
CUSTOM_GOLD_TICK_TIME = 0.5

Gold = Gold or class({})

Events:Register("activate", function ()
	GameRules:SetGoldPerTick(0)
	GameRules:SetGoldTickTime(0)
	GameRules:SetStartingGold(0)
	GameRules:SetUseBaseGoldBountyOnHeroes(true)
end)

function Gold:UpdatePlayerGold(unitvar)
	local playerId = UnitVarToPlayerID(unitvar)
	if playerId and playerId > -1 then
		PlayerResource:SetGold(playerId, 0, false)
		PlayerTables:SetTableValue("gold", playerId, math.min(2 ^ 30 - 1, PLAYER_DATA[playerId].SavedGold))
		--2^30-1
	end
end

function Gold:ClearGold(unitvar)
	Gold:SetGold(unitvar, 0)
end

function Gold:SetGold(unitvar, gold)
	local playerId = UnitVarToPlayerID(unitvar)
	PLAYER_DATA[playerId].SavedGold = math.floor(gold)
	Gold:UpdatePlayerGold(playerId)
end

function Gold:ModifyGold(unitvar, gold, bReliable, iReason)
	if gold > 0 then
		Gold:AddGold(unitvar, math.round(gold))
	elseif gold < 0 then
		Gold:RemoveGold(unitvar, -math.round(gold))
	end
end

function Gold:RemoveGold(unitvar, gold)
	local playerId = UnitVarToPlayerID(unitvar)
	PLAYER_DATA[playerId].SavedGold = math.max((PLAYER_DATA[playerId].SavedGold or 0) - math.ceil(gold), 0)
	Gold:UpdatePlayerGold(playerId)
end

function Gold:AddGold(unitvar, gold)
	local hero
	if type(unitvar) ~= "table" and PlayerResource:IsValidPlayer(unitvar) then
		hero = PlayerResource:GetSelectedHeroEntity(unitvar)
	end
	gold = gold * GetGoldMultiplier(hero)
	
	local playerId = UnitVarToPlayerID(unitvar)
	PLAYER_DATA[playerId].SavedGold = (PLAYER_DATA[playerId].SavedGold or 0) + gold
	Gold:UpdatePlayerGold(playerId)
end

function Gold:AddGoldWithMessage(unit, gold, optPlayerID)
	local player = optPlayerID and PlayerResource:GetPlayer(optPlayerID) or PlayerResource:GetPlayer(UnitVarToPlayerID(unit))
	SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(gold * GetGoldMultiplier(unit)), player)
	Gold:AddGold(optPlayerID or unit, gold)
end

function Gold:GetGold(unitvar)
	return math.floor(PLAYER_DATA[UnitVarToPlayerID(unitvar)].SavedGold or 0)
end
