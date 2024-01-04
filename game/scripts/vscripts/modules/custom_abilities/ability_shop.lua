function CustomAbilities:PostAbilityShopData()
	CustomGameEventManager:RegisterListener("ability_shop_buy", function(_, data)
		-- PrintTable(data)
		CustomAbilities:OnAbilityBuy(data.PlayerID, data.ability, tonumber(data.tab), tonumber(data.hero),
			tonumber(data.index))
	end)
	CustomGameEventManager:RegisterListener("ability_shop_sell", Dynamic_Wrap(CustomAbilities, "OnAbilitySell"))
	CustomGameEventManager:RegisterListener("ability_shop_downgrade", Dynamic_Wrap(CustomAbilities, "OnAbilityDowngrade"))
	PlayerTables:CreateTable("ability_shop_data", CustomAbilities.ClientData, AllPlayersInterval)
end

function CustomAbilities:GetAbilityListInfo(abilityname)
	return CustomAbilities.AbilityInfo[abilityname]
end

function CustomAbilities:ChangeAbilityCost(abilityname, value, indexes)
	CustomAbilities.AbilityInfo[abilityname].cost = value
	PrintTable(indexes)
	PrintTable(CustomAbilities.ClientData[indexes.ti][indexes.hi].abilities[indexes.ai])
	local abtable = CustomAbilities.ClientData[indexes.ti][indexes.hi].abilities[indexes.ai]
	CustomAbilities.ClientData[indexes.ti][indexes.hi].abilities[indexes.ai] = {
		ability = abilityname,
		cost = value,
		base_cost = abtable.base_cost,
		banned_with = abtable.banned_with,
		heroIndex = indexes.hi,
		tableIndex = indexes.ti,
		abilityIndex = indexes.ai,
	}
	PlayerTables:CreateTable("ability_shop_data", CustomAbilities.ClientData, AllPlayersInterval)
end

function CustomAbilities:IncreaseAbilityCost(abilityname, indexes)
	local ability = CustomAbilities:GetAbilityListInfo(abilityname)
	CustomAbilities:ChangeAbilityCost(abilityname, ability.cost * 2, {
		ti = tonumber(indexes[1]),
		hi = tonumber(indexes[2]),
		ai = tonumber(indexes[3])
	})
end

function CustomAbilities:DecreaseAbilityCost(abilityname, value, indexes)
	local ability = CustomAbilities:GetAbilityListInfo(abilityname)
	value = ability.cost / 2 ^ value
	CustomAbilities:ChangeAbilityCost(abilityname, value, {
		ti = tonumber(indexes[1]),
		hi = tonumber(indexes[2]),
		ai = tonumber(indexes[3])
	})
	return value
end

function CustomAbilities:Cooldown(key)
	if not CustomAbilities.cooldowns[key] then
		CustomAbilities.cooldowns[key] = true
		Timers:CreateTimer(0.1, function()
			CustomAbilities.cooldowns[key] = nil
		end)
		return false
	else
		return true
	end
end

function CustomAbilities:CalculateAbilityCost(hero, abilityname, abilityh)
	local abilityInfo = CustomAbilities:GetAbilityListInfo(abilityname)
	local cost = abilityInfo.cost
	if not abilityh then return cost end
	-- print(cost / 2 ^ abilityh:GetLevel())
	local heroKv = GetUnitKV(hero:GetFullName())
	for _, _abilityname in pairs(heroKv) do
		if abilityname == _abilityname then
			return abilityInfo.base_cost
		end
	end
	return cost
end

function CustomAbilities:OnAbilityBuy(PlayerID, abilityname, tableIndex, heroIndex, abilityIndex)
	local hero = PlayerResource:GetSelectedHeroEntity(PlayerID)
	if not hero then return end
	local abilityInfo = CustomAbilities:GetAbilityListInfo(abilityname)
	if not abilityInfo then return end
	if not tableIndex then return end
	if not heroIndex then return end
	if not abilityIndex then return end

	if CustomAbilities:Cooldown('buy') then return end

	local function Buy()
		local abilityh = hero:FindAbilityByName(abilityname)
		local cost = CustomAbilities:CalculateAbilityCost(hero, abilityname, abilityh)
		if not IsValidEntity(hero) or hero:GetAbilityPoints() < cost then return end
		for _, v in ipairs(abilityInfo.banned_with) do
			if hero:HasAbility(v) then return end
		end
		CustomAbilities:IncreaseAbilityCost(abilityname, { tableIndex, heroIndex, abilityIndex })

		if abilityh then
			if abilityh:GetLevel() < abilityh:GetMaxLevel() then
				hero:SetAbilityPoints(hero:GetAbilityPoints() - cost)
				abilityh:SetLevel(abilityh:GetLevel() + 1)
			end
		elseif hero:HasAbility("ability_empty") then
			if abilityh and abilityh:IsHidden() then
				RemoveAbilityWithModifiers(hero, abilityh)
			end
			hero:SetAbilityPoints(hero:GetAbilityPoints() - cost)
			hero:RemoveAbility("ability_empty")
			GameMode:PrecacheUnitQueueed(abilityInfo.hero)
			local a, linked = hero:AddNewAbility(abilityname)
			a:SetLevel(1)
			if linked then
				for _, v in ipairs(linked) do
					if v:GetAbilityName() == "phoenix_launch_fire_spirit" then
						v:SetLevel(1)
					end
				end
			end
			hero:CalculateStatBonus(true)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(PlayerID), "dota_ability_changed", {})
		end
	end
	if hero:HasAbility(abilityname) then
		Buy()
	else
		PrecacheItemByNameAsync(abilityname, Buy)
	end
end

function CustomAbilities:OnAbilitySell(data, free)
	local hero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
	local listDataInfo = CustomAbilities:GetAbilityListInfo(data.ability)
	if hero and hero:HasAbility(data.ability) and not hero:IsChanneling() and listDataInfo then
		if CustomAbilities:Cooldown('sell') then return end
		local abilityh = hero:FindAbilityByName(data.ability)
		local cost = free and 0 or CustomAbilities:CalculateAbilityCost(hero, data.ability, abilityh)
		local saved_cost = listDataInfo.cost
		local gold = CustomAbilities:CalculateDowngradeCost(data.ability, cost)
		if Gold:GetGold(data.PlayerID) >= gold and not abilityh:IsHidden() then
			Gold:RemoveGold(data.PlayerID, gold)
			-- print('===================')
			-- print('cost in base, ' .. listDataInfo.cost)
			-- print('saved cost, ' .. saved_cost)
			local _cost = CustomAbilities:DecreaseAbilityCost(data.ability, abilityh:GetLevel(),
				{ data.tab, data.hero, data.index })
			-- print('reduced cost, ' .. _cost)
			-- print('old cost, ' .. cost)
			if cost == saved_cost then
				cost = cost - _cost
			elseif cost > 0 then
				cost = cost * abilityh:GetLevel()
			end
			-- print('new cost, ' .. cost)

			hero:SetAbilityPoints(hero:GetAbilityPoints() + cost)
			RemoveAbilityWithModifiers(hero, abilityh)
			local link = LINKED_ABILITIES[data.ability]
			if link then
				for _, v in ipairs(link) do
					hero:RemoveAbility(v)
				end
			end
			if data.ability == "puck_illusory_orb" then
				local etherealJaunt = hero:FindAbilityByName("puck_ethereal_jaunt")
				if etherealJaunt then etherealJaunt:SetActivated(false) end
			end
			hero:AddAbility("ability_empty")
		end
	end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "dota_ability_changed", {})
end

function CustomAbilities:OnAbilityDowngrade(data)
	local hero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
	local listDataInfo = CustomAbilities:GetAbilityListInfo(data.ability)
	if hero and hero:HasAbility(data.ability) and listDataInfo then
		if CustomAbilities:Cooldown('downgrade') then return end
		local abilityh = hero:FindAbilityByName(data.ability)
		local saved_cost = listDataInfo.cost
		local cost = CustomAbilities:CalculateAbilityCost(hero, data.ability, abilityh)
		if abilityh:GetLevel() <= 1 then
			CustomAbilities:OnAbilitySell(data)
		else
			local gold = CustomAbilities:CalculateDowngradeCost(data.ability, cost)
			if Gold:GetGold(data.PlayerID) >= gold and not abilityh:IsHidden() then
				Gold:RemoveGold(data.PlayerID, gold)
				abilityh:SetLevel(abilityh:GetLevel() - 1)
				local _cost = CustomAbilities:DecreaseAbilityCost(data.ability, 1, { data.tab, data.hero, data.index })
				if cost == saved_cost then
					cost = cost - _cost
				else
					cost = cost
				end
				hero:SetAbilityPoints(hero:GetAbilityPoints() + cost)
			end
		end
	end
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "dota_ability_changed", {})
end

function CustomAbilities:SellAllAbilities(hero)
	for i = 0, hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then
			local abilityName = ability:GetAbilityName()
			if abilityName ~= "ability_empty" then
				local data = CustomAbilities.AbilityInfo[abilityName]
				if data then
					CustomAbilities:OnAbilitySell(
						{
							ability = abilityName,
							PlayerID = hero:GetPlayerOwnerID(),
							tab = data.tableIndex,
							hero = data.heroIndex,
							index = data.abilityIndex
						}, true)
				end
			end
		end
	end
end

function CustomAbilities:CalculateDowngradeCost(abilityname, upgradecost)
	return 150 + (upgradecost * 2 * GetDOTATimeInMinutesFull() ^ 1.1)
end
