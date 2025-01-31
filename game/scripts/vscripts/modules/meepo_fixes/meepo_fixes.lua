MeepoFixes = MeepoFixes or class({})
ModuleRequire(..., "data")

function MeepoFixes:FindMeepos(main, includeMain)
	local playerId = main:GetPlayerID()
	local meepos = includeMain and { main } or {}
	for _, clone in ipairs(Entities:FindAllByName("npc_dota_hero_meepo")) do
		if MeepoFixes:IsMeepoClone(clone) then
			table.insert(meepos, clone)
		end
	end
	return meepos
end

function MeepoFixes:IsMeepoClone(unit)
	return unit:GetFullName() == "npc_dota_hero_meepo" and unit:IsTrueHero() and not unit:IsMainHero() and unit:IsClone()
end

function MeepoFixes:ShareItems(unit)
	if unit:GetFullName() == "npc_dota_hero_meepo" then
		local mainItemHash = MeepoFixes:GetFilteredInventoryHash(unit, MEEPO_SHARED_ITEMS)
		-- print(#MeepoFixes:FindMeepos(unit))
		for _, clone in ipairs(MeepoFixes:FindMeepos(unit)) do
			if MeepoFixes:GetFilteredInventoryHash(clone, MEEPO_SHARED_ITEMS) ~= mainItemHash then
				for i, v in ipairs(mainItemHash:split()) do
					local oldItem = clone:GetItemInSlot(i - 1)
					--Mostly uselss, because Dota's clears inventory, but should work with default boots
					if oldItem then
						local oldItemName = oldItem:GetAbilityName()
						if oldItemName ~= v then
							UTIL_Remove(oldItem)
							if v ~= "nil" then
								local item = clone:AddItemByName(v)
								if item then
									item:SetSellable(false)
								end
							end
						end
					else
						if v ~= "nil" then
							local item = clone:AddItemByName(v)
							if item then
								item:SetSellable(false)
							end
						end
					end
				end
				ClearSlotsFromDummy(clone, true)
			end
		end
	end
end

function MeepoFixes:GetFilteredInventoryHash(unit, list)
	local hash = ""
	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		local item = unit:GetItemInSlot(i)
		if item then
			local itemName = item:GetAbilityName()
			hash = hash .. (list[itemName] and itemName or "nil") .. " "
		else
			hash = hash .. "nil "
		end
	end
	return hash:sub(1, -2)
end

function MeepoFixes:UpgradeTalent(unit, name)
	for _, v in pairs(MeepoFixes:FindMeepos(unit)) do
		v:SetAbilityPoints(v:GetAbilityPoints() - CustomTalents:Talent_GetCost(name))
		v:UpgradeTalentRecord(name)
	end
end
