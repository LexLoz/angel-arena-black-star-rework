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
		-- local hero = PlayerResource:GetSelectedHeroEntity(0)
		-- local modifier = hero:FindModifierByName("modifier_arena_hero_gold")
		-- if modifier then
		-- 	modifier:SetStackCount(math.round(PLAYER_DATA[playerId].SavedGold))
		-- end


		-- PlayerTables:SetTableValue("gold", playerId, PLAYER_DATA[playerId].SavedGold)
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
	local playerId = UnitVarToPlayerID(unitvar)
	local hero
	if type(unitvar) ~= "table" and PlayerResource:IsValidPlayer(playerId) then
		-- print('playerId: ' .. playerId)
		hero = PlayerResource:GetSelectedHeroEntity(playerId)
	end
	gold = gold * GetGoldMultiplier(playerId)
	
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
