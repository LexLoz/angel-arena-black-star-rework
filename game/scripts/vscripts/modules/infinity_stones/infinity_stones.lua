ModuleRequire(..., "data")

InfinityStones = InfinityStones or class({})
InfinityStones.particle_cash = {}

if IsServer() then
	function InfinityStones:OnEntityKilled(keys)
		local killedUnit = EntIndexToHScript(keys.entindex_killed)
		local killerEntity
		if keys.entindex_attacker then
			killerEntity = EntIndexToHScript(keys.entindex_attacker)
		end

		if killedUnit and killerEntity then
			--gauntlet drop
			-- if not Bosses:IsLastBossEntity(killedUnit) and not InfinityStones.GauntletDropped then
			-- 	InfinityStones.GauntletDropped = true
			-- 	local gauntlet = CreateItem("item_infinity_gauntlet", nil, nil)
			-- 	CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), gauntlet)
			-- 	Notifications:TopToAll({text="#arena_infinity_gauntlet_dropped", duration = 6})
			-- 	EmitGlobalSound("Arena.Gauntlet_Dropped")
			-- end
			--print(CHAMPIONS_DROP_CHANCE)
			--infinity stones drop
			if
				killerEntity:IsTrueHero() and
				killedUnit:IsChampion() and
				GetDOTATimeInMinutesFull() >= STONES_TIME_DROP and
				DROPPED_STONES < #STONES_TABLE and

				RollPercentage(CHAMPIONS_DROP_CHANCE[killedUnit:FindModifierByName("modifier_neutral_champion"):GetStackCount()] * (PLAYERS_DROP_CHANCE[killerEntity:GetPlayerID()] or 1)) then
				local stone
				while true do
					local i = RandomInt(1, #STONES_TABLE)
					local st = STONES_TABLE[i]
					if st[2] then
						stone = CreateItem(STONES_TABLE[i][1], nil, nil)
						--stone.first = true
						--stone:SetEntityName("infinity_stone")
						STONES_IN_WORLD[STONES_TABLE[i][1]] = stone
						--print(st[1])
						DROPPED_STONES = DROPPED_STONES + 1
						st[2] = false
						break
					end
				end
				--print(stone:GetAbilityName())
				killerEntity:AddItem(stone)
				local drop_chance_mult = PLAYERS_DROP_CHANCE[killerEntity:GetPlayerID()]
				PLAYERS_DROP_CHANCE[killerEntity:GetPlayerID()] = (drop_chance_mult or 1) / DROP_CHANCE_DECREASE

				local hero_name = killerEntity:GetFullName()
				Notifications:TopToAll({ text = "#" .. stone:GetAbilityName(), duration = 6 })
				Notifications:TopToAll({ text = "#infinity_stones_get", continue = true })
				Notifications:TopToAll({ text = "#" .. hero_name, continue = true })
			end
		end
	end

	function InfinityStones:GetMinimapPointName(string)
		local i1 = string.find(string, "_") + 1
		local i2 = string.find(string, "_stone") - 1
		return string:sub(i1, i2)
	end

	function InfinityStones:Think()
		-- print('vision')
		local function DestroyMarks(v)
			if v.vision then
				DynamicMinimap:SetVisibleGlobal(v.vision, false)
				DynamicMinimap:Destroy(v.vision)
				--print(v.vision)
				v.vision = nil
			end
		end
		--print(Entities:FindByName("item_infinity_gauntlet"))
		local gauntlet = Entities:FindByName(nil, "item_infinity_gauntlet")
		if gauntlet then
			if gauntlet:GetItemSlot() == -1 and not gauntlet.vision then
				local name = "icon_gauntlet"
				gauntlet.vision = DynamicMinimap:CreateMinimapPoint(gauntlet:GetAbsOrigin(), name)
				DynamicMinimap:SetVisibleGlobal(gauntlet.vision, true)
			elseif gauntlet:GetItemSlot() == -1 and gauntlet.vision and DynamicMinimap:GetAbsOrigin(gauntlet.vision) ~= gauntlet:GetAbsOrigin() then
				DynamicMinimap:SetAbsOrigin(gauntlet.vision, gauntlet:GetAbsOrigin())
			elseif gauntlet:GetItemSlot() ~= -1 and gauntlet.vision then
				DestroyMarks(gauntlet)
			end
		end
		for k, _ in pairs(STONES_LIST) do
			local stone = k
			local entities = Entities:FindAllByName(stone)
			if entities ~= {} then
				for _, v in pairs(entities) do
					if v:GetItemSlot() == -1 and not v.vision and not v.InGauntlet then
						local name = InfinityStones:GetMinimapPointName(stone)
						v.vision = DynamicMinimap:CreateMinimapPoint(v:GetAbsOrigin(), "icon_stone icon_stone_" .. name)
						DynamicMinimap:SetVisibleGlobal(v.vision, true)
					elseif v:GetItemSlot() == -1 and v.vision and DynamicMinimap:GetAbsOrigin(v.vision) ~= v:GetAbsOrigin() then
						-- DynamicMinimap:SetAbsOrigin(v.vision, v:GetAbsOrigin())
						DestroyMarks(v)
						local name = InfinityStones:GetMinimapPointName(stone)
						v.vision = DynamicMinimap:CreateMinimapPoint(v:GetAbsOrigin(), "icon_stone icon_stone_" .. name)
						DynamicMinimap:SetVisibleGlobal(v.vision, true)
					elseif v:GetItemSlot() ~= -1 and v.vision then
						DestroyMarks(v)
					-- elseif v.vision then
						-- print((DynamicMinimap:GetAbsOrigin(v.vision)))
						-- print('==================')
						-- print((v:GetAbsOrigin()))
					end
					--end
				end
			end
		end
		--end)
		return 0.1
	end

	function InfinityStones:OnItemPickedUp(item)
		--if IsValidEntity(item) and STONES_LIST[item:GetName()] and item.first then
		--item.first = false
		--end
		--self:UpdateMinimapIcons()
	end
end

--GetContainer()
--Entities
