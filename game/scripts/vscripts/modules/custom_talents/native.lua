local nativeTalents = {}
local skippedTalents = {}
local talentsExeptions = {
	special_bonus_unique_medusa_4 = true,
	special_bonus_unique_furion_3 = true,
	special_bonus_unique_witch_doctor_2 = true,
}

local npc_heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
local npc_abilities = LoadKeyValues("scripts/npc/npc_abilities.txt")

local function addTalent(talentName, heroName, group, value)
	local newValues
	if not value then
		newValues = GetAbilitySpecial(talentName)
		-- PrintTable(newValues)
	else
		newValues = {}
		newValues[value.key] = value.value
	end

	local cost
	if group <= 3 then
		cost = 4
	elseif group <= 6 then
		cost = 3
	elseif group <= 9 then
		cost = 2
	end
	-- print(talentName)
	nativeTalents[talentName] = {
		cost = cost,
		group = group,
		icon = heroName,
		requirement = heroName,
		special_values = newValues or 0,
		effect = { abilities = talentName }
	}
end

for heroName, heroData in pairs(npc_heroes) do
	local partiallyChanged = PARTIALLY_CHANGED_HEROES[heroName]
	local isChanged = GetKeyValue(heroName, "Changed") == 1 and not partiallyChanged
	if type(heroData) == "table" and not isChanged then
		local i = 1
		for _, talentName in pairs(heroData) do
			if type(talentName) == "string" and (string.starts(talentName, "special_bonus_unique_")) then
				if (not partiallyChanged or partiallyChanged[talentName] ~= true) and not talentsExeptions[talentName] then
					-- print(talentName)
					-- PrintTable(GetAbilitySpecial(talentName))
					if not GetAbilitySpecial(talentName) then
						for _, abilityName in pairs(heroData) do
							local abilityValues
							if type(abilityName) == "string" and not string.starts(abilityName, "special_bonus_unique_") then
								abilityValues = GetKeyValue(abilityName, "AbilityValues")
							end
							if type(abilityValues) == "table" then
								for k, v in pairs(abilityValues) do
									if type(k) == "string" and
										(not string.endswith(k, "tooltip")) and
										type(v) == "table" then
										for k1, v1 in pairs(v) do
											if type(k1) == "string" and string.starts(k1, "special_bonus_unique_") then
												-- print(i)
												-- i = i + 1
												addTalent(k1, heroName, math.random(9), { key = "value", value = v1 })
											end
										end
									end
								end
							end
						end
					else
						-- i = i + 1
						addTalent(talentName, heroName, math.random(5))
					end
				else
					print('skipped talent: ' .. talentName)
				end
			end
		end
	end
end

for name, override in pairs(NATIVE_TALENTS) do
	if not nativeTalents[name] and not skippedTalents[name] then
		--print(name .. ": presents in NATIVE_TALENTS but isn't a valid talent")
	end
end

for name in pairs(LoadKeyValues("scripts/npc/override/talents.txt")) do
	if not nativeTalents[name] then
		--print(name .. ": presents in ability override but isn't a valid talent")
	end
end

return nativeTalents
