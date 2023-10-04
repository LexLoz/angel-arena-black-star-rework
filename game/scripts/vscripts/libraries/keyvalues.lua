KEYVALUES_VERSION = "1.00"

--[[
	Simple Lua KeyValues library, modified version
	Author: Martin Noya // github.com/MNoya

	Installation:
	- require this file inside your code

	Usage:
	- Your npc custom files will be validated on require, error will occur if one is missing or has faulty syntax.
	- This allows to safely grab key-value definitions in npc custom abilities/items/units/heroes

		"some_custom_entry"
		{
			"CustomName" "Barbarian"
			"CustomKey"  "1"
			"CustomStat" "100 200"
		}

		With a handle:
			handle:GetKeyValue() -- returns the whole table based on the handles baseclass
			handle:GetKeyValue("CustomName") -- returns "Barbarian"
			handle:GetKeyValue("CustomKey")  -- returns 1 (number)
			handle:GetKeyValue("CustomStat") -- returns "100 200" (string)
			handle:GetKeyValue("CustomStat", 2) -- returns 200 (number)

		Same results with strings:
			GetKeyValue("some_custom_entry")
			GetKeyValue("some_custom_entry", "CustomName")
			GetKeyValue("some_custom_entry", "CustomStat")
			GetKeyValue("some_custom_entry", "CustomStat", 2)

	- Ability Special value grabbing:

		"some_custom_ability"
		{
			"AbilitySpecial"
			{
				"01"
				{
					"var_type"    "FIELD_INTEGER"
					"some_key"    "-3 -4 -5"
				}
			}
		}

		With a handle:
			ability:GetAbilitySpecial("some_key") -- returns based on the level of the ability/item

		With string:
			GetAbilitySpecial("some_custom_ability", "some_key")    -- returns "-3 -4 -5" (string)
			GetAbilitySpecial("some_custom_ability", "some_key", 2) -- returns -4 (number)

	Notes:
	- In case a key can't be matched, the returned value will be nil
	- Don't identify your custom units/heroes with the same name or it will only grab one of them.
]]

if not KeyValues then
	KeyValues = {}
end

-- Load all the necessary key value files
function LoadGameKeyValues()
	local scriptPath = "scripts/npc/"
	local override = LoadKeyValues(scriptPath .. "npc_abilities_override.txt")
	local files = {
		AbilityKV = { base = "npc_abilities", custom = "npc_abilities_custom" },
		ItemKV = { base = "items", custom = "npc_items_custom" },
		UnitKV = { base = "npc_units", custom = "npc_units_custom" },
		HeroKV = { base = "npc_heroes", custom = "npc_heroes_custom", new = "heroes/new" }
	}
	if not override then
		error("[KeyValues] Critical Error on " .. override .. ".txt")
	end
	-- Load and validate the files
	for KVType, KVFilePaths in pairs(files) do
		local file = LoadKeyValues(scriptPath .. KVFilePaths.base .. ".txt")
		-- Replace main game keys by any match on the override file
		for k, v in pairs(override) do
			if file[k] then
				if type(v) == "table" then
					table.merge(file[k], v)
				else
					file[k] = v
				end
			end
		end
		local custom_file = LoadKeyValues(scriptPath .. KVFilePaths.custom .. ".txt")
		if custom_file then
			if KVType == "HeroKV" then
				for k, v in pairs(custom_file) do
					if not file[k] then
						file[k] = {}
						table.deepmerge(file[k], v)
					else
						table.deepmerge(file[k], v)
					end
				end
			else
				table.deepmerge(file, custom_file)
			end
		else
			error("[KeyValues] Critical Error on " .. KVFilePaths.custom .. ".txt")
		end
		if KVFilePaths.new then
			table.deepmerge(file, LoadKeyValues(scriptPath .. KVFilePaths.new .. ".txt"))
		end

		file.Version = nil
		KeyValues[KVType] = file
	end

	-- Merge All KVs
	KeyValues.All = {}
	for name, path in pairs(files) do
		for key, value in pairs(KeyValues[name]) do
			KeyValues.All[key] = value
		end
	end

	-- Merge units and heroes (due to them sharing the same class CDOTA_BaseNPC)
	for key, value in pairs(KeyValues.HeroKV) do
		if not KeyValues.UnitKV[key] then
			KeyValues.UnitKV[key] = value
		elseif type(KeyValues.All[key]) == "table" then
			table.deepmerge(KeyValues.UnitKV[key], value)
		end
	end
	KeyValues.HeroKV = nil

	for k, v in pairs(KeyValues.UnitKV) do
		local override_hero = v.override_hero or v.base_hero
		if override_hero and KeyValues.UnitKV[override_hero] then
			table.deepmerge(v, KeyValues.UnitKV[override_hero])
		end
	end
end

-- Works for heroes and units on the same table due to merging both tables on game init
function CDOTA_BaseNPC:GetKeyValue(key, level, bOriginalHero)
	return GetUnitKV(bOriginalHero and self:GetUnitName() or self:GetFullName(), key, level)
end

-- Dynamic version of CDOTABaseAbility:GetAbilityKeyValues()
function CDOTABaseAbility:GetKeyValue(key, level)
	if level then
		return GetAbilityKV(self:GetAbilityName(), key, level)
	else
		return GetAbilityKV(self:GetAbilityName(), key)
	end
end

-- Item version
function CDOTA_Item:GetKeyValue(key, level)
	if level then
		return GetItemKV(self:GetAbilityName(), key, level)
	else
		return GetItemKV(self:GetAbilityName(), key)
	end
end

function CDOTABaseAbility:GetAbilitySpecial(key)
	return GetAbilitySpecial(self:GetAbilityName(), key, self:GetLevel())
end

-- Global functions
-- Key is optional, returns the whole table by omission
-- Level is optional, returns the whole value by omission
function GetKeyValue(name, key, level, tbl)
	local t = tbl or KeyValues.All[name]
	if key and t then
		if t[key] and level then
			local s = string.split(t[key])
			if s[level] then
				return tonumber(s[level]) or s[level] -- Try to cast to number
			else
				return tonumber(s[#s]) or s[#s]
			end
		else
			return t[key]
		end
	else
		return t
	end
end

function GetUnitKV(unitName, key, level)
	return GetKeyValue(unitName, key, level, KeyValues.UnitKV[unitName])
end

function GetAbilityKV(abilityName, key, level)
	return GetKeyValue(abilityName, key, level, KeyValues.AbilityKV[abilityName])
end

function GetItemKV(itemName, key, level)
	return GetKeyValue(itemName, key, level, KeyValues.ItemKV[itemName])
end

function GetAbilitySpecial(name, key, level, t)
	if not t then t = KeyValues.All[name] end
	if t then
		local AbilitySpecial = t.AbilitySpecial
		local AbilityValues = t.AbilityValues
		if AbilitySpecial then
			if key then
				-- Find the key we are looking for
				for _, values in pairs(AbilitySpecial) do
					if values[key] then
						return GetValueInStringForLevel(values[key], level)
					end
				end
			else
				local o = {}
				for _, values in pairs(AbilitySpecial) do
					for k, v in pairs(values) do
						if k ~= 'var_type' and k ~= 'CalculateSpellDamageTooltip' and k ~= 'levelkey' then
							o[k] = v
						end
					end
				end
				return o
			end
		elseif AbilityValues then
			if key then
				local o = AbilityValues[key]
				if o then
					if type(o) ~= "table" then
						return o
					elseif o["value"] then
						return o["value"]
					end
				end
			else
				local o = {}
				for key, values in ipairs(AbilityValues) do
					if type(values) == table then
						o[key] = values.value
					else
						o[key] = values
					end
				end
				return o
			end
		end
	end
end

function GetValueInStringForLevel(str, level)
	if not level then
		return str
	else
		local s = string.split(str)
		if s[level] then
			-- If we match the level, return that one
			return tonumber(s[level])
		else
			-- Otherwise, return the max
			return tonumber(s[#s])
		end
	end
end

function GetItemNameById(itemid)
	for name, kv in pairs(KeyValues.ItemKV) do
		if kv and type(kv) == "table" and kv.ID and kv.ID == itemid then
			return name
		end
	end
end

function GetItemIdByName(itemName)
	return KeyValues.ItemKV[itemName].ID
end

--if not KeyValues.All then LoadGameKeyValues() end
LoadGameKeyValues()


















--KV Generator

function GenerateLocalization(table)
	for k, v in ipairs(table) do
		print(v)
	end
end

function PrintGeneratedKV(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	done = done or {}
	done[t] = true
	if not indent then
		print("Printing table")
	end
	indent = indent or 1

	local l = {}
	for k, v in pairs(t) do
		table.insert(l, k)
	end

	table.sort(l)
	for k, v in ipairs(l) do
		-- Ignore FDesc
		if v ~= 'FDesc' then
			local value = t[v]
			if type(value) == "table" and not done[value] then
				done[value] = true
				print('')
				print(string.rep("\t", indent) .. '"' .. tostring(v) .. '"')
				print(string.rep("\t", indent) .. '{')
				PrintGeneratedKV(value, indent + 1, done)
				print(string.rep("\t", indent) .. "}")
			else
				if t.FDesc and t.FDesc[v] then
					print(string.rep("\t", indent) .. '"' .. tostring(t.FDesc[v]) .. '"')
				else
					print(string.rep("\t", indent) .. '"' .. tostring(v) .. '" "' .. tostring(value) .. '"')
				end
			end
		end
	end
end

KV_AVERAGE_MULTIPLIER = 1.5
function GenerateAbilitiesKVTable(parameters)
	parameters = parameters or {}

	print('NEW KV TABLE')
	local overrideKV = LoadKeyValues("scripts/npc/override/abilities.txt")
	local oldKV = LoadKeyValues("scripts/npc/override/abilities.txt")
	local newKV = {}
	local localization_eng = {}
	local localization_ru = {}

	local function conditionHelper(parameterName)
		return parameterName ~= "LinkedSpecialBonusOperation" and
			parameterName ~= "var_type" and
			parameterName ~= "LinkedSpecialBonus" and
			parameterName ~= "CalculateSpellDamageTooltip" and
			parameterName ~= "RequiresShard" and
			parameterName ~= "DamageTypeTooltip" and
			parameterName ~= "RequiresScepter" and
			parameterName ~= "ad_linked_abilities"
	end

	local function foundParameter(table, key)
		if table["AbilitySpecial"] then
			for index, parameterValues in pairs(table["AbilitySpecial"]) do
				for parameterName, parameterValue in pairs(parameterValues) do
					if conditionHelper(parameterName) then
						-- print('ability special: '..key..', '..parameterName)
						if key == parameterName then
							return parameterValue
						end
					end
				end
			end
		elseif table["AbilityValues"] then
			for parameterName, parameterValues in pairs(table["AbilityValues"]) do
				-- print('ability values: '..key..', '..parameterName)
				if parameterName == key then
					if type(parameterValues) == "table" then
						for k, v in pairs(parameterValues) do
							if k == "value" then
								return v
							end
						end
					else
						return parameterValues
					end
				end
			end
		end
	end

	local function createLoc(parameterName, abilityName, parameterValues)
		table.insert(localization_ru,
			'"DOTA_Tooltip_ability_' ..
			abilityName ..
			"_" .. parameterName .. '" "' .. parameterValues.localizationRu .. '"')
		table.insert(localization_eng,
			'"DOTA_Tooltip_ability_' ..
			abilityName ..
			"_" .. parameterName .. '" "' .. parameterValues.localizationEng ..
			'"')
	end

	local function createParameter(newAbilityKVTable, parameterName, parameterValues, parameterValue, abilityName)
		--if valuesType == "AbilityValues" then
		newAbilityKVTable["AbilityValues"][parameterName] = {
			value = parameterValue,
			CalculateSpellDamageTooltip = parameterValues.isCalculateSpellDamageTooltip and 1 or
				0
		}

		if parameters.createLocalization then
			createLoc(parameterName, abilityName, parameterValues)
		end

		return newAbilityKVTable
		-- elseif valuesType == "AbilitySpecial" then
		-- 	newAbilityKVTable[valuesType][tostring(i)] = {
		-- 		var_type = "FIELD_FLOAT",
		-- 		[parameterName] = parameterValue,
		-- 		CalculateSpellDamageTooltip = parameterValues.isCalculateSpellDamageTooltip and 1 or
		-- 			0
		-- 	}
		-- 	if parameters.createLocalization then
		-- 		createLoc(parameterName, abilityName, parameterValues)
		-- 	end

		-- 	return newAbilityKVTable
	end

	for abilityName, oldAbilityKVTable in pairs(oldKV) do
		local overrideAbilityKVTable = overrideKV[abilityName]
		if overrideAbilityKVTable then
			newKV[abilityName] = {
				MaxLevel = oldAbilityKVTable["MaxLevel"]
			}
			local newAbilityKVTable = newKV[abilityName]

			for valuesType, value in pairs(overrideAbilityKVTable) do
				if oldAbilityKVTable[valuesType] and not (valuesType == "AbilitySpecial" or valuesType == "AbilityValues") then
					newAbilityKVTable[valuesType] = oldAbilityKVTable[valuesType]
				end

				if valuesType == "AbilitySpecial" then
					local AbilitySpecial = value
					newAbilityKVTable["AbilityValues"] = {}
					for _, parameterValues in pairs(AbilitySpecial) do
						for parameterName, parameterValue in pairs(parameterValues) do
							if conditionHelper(parameterName) then
								newAbilityKVTable["AbilityValues"][parameterName] = {}
								newAbilityKVTable["AbilityValues"][parameterName]["value"] = foundParameter(
								oldAbilityKVTable, parameterName) or parameterValue
								for k, v in pairs(parameterValues) do
									if k == "LinkedSpecialBonuыs" then
										newAbilityKVTable["AbilityValues"][parameterName]["LinkedSpecialBonus"] = v
									elseif k == "CalculateSpellDamageTooltip" then
										newAbilityKVTable["AbilityValues"][parameterName]["CalculateSpellDamageTooltip"] =
										v
									elseif k == "LinkedSpecialBonusOperation" then
										-- table.insert(newAbilityKVTable["AbilityValues"][parameterName], "LinkedSpecialBonusOperation", v)
										newAbilityKVTable["AbilityValues"][parameterName]["LinkedSpecialBonusOperation"] =
										v
									elseif k == "RequiresShard" then
										newAbilityKVTable["AbilityValues"][parameterName]["RequiresShard"] =
										v
									elseif k == "DamageTypeTooltip" then
										newAbilityKVTable["AbilityValues"][parameterName]["DamageTypeTooltip"] =
										v
									elseif k == "RequiresScepter" then
										newAbilityKVTable["AbilityValues"][parameterName]["RequiresScepter"] =
										v
									elseif k == "ad_linked_abilities" then
										newAbilityKVTable["AbilityValues"][parameterName]["ad_linked_abilities"] =
										v
									end
								end
							end
						end
					end
					------------------------------------генерация параметров-------------------------------------
					local i = 100

					for parameterName, parameterValues in pairs(parameters) do
						if type(parameterValues) == "table" then
							local parameterValue = foundParameter(oldAbilityKVTable,
								parameterName)
							-- print(parameterValues.table)
							if not parameterValues.table and parameterValue then
								i = i - 1
								newAbilityKVTable = createParameter(newAbilityKVTable, parameterName, parameterValues,
									parameterValue, abilityName)
							elseif parameterValues.table and parameterValues.table[abilityName] then
								parameterValue = parameterValues.table[abilityName]
								i = i - 1
								newAbilityKVTable = createParameter(newAbilityKVTable, parameterName, parameterValues,
									parameterValue, abilityName)
							end
						end
					end
					--------------------------------------------------------------------------------------------
				elseif valuesType == "AbilityValues" then
					local AbilityValues = value
					newAbilityKVTable[valuesType] = {}
					for parameterName, parameterValues in pairs(AbilityValues) do
						newAbilityKVTable[valuesType][parameterName] = parameterValues;
						if type(parameterValues) == "table" then
							for k, v in pairs(parameterValues) do
								if k == "value" then
									newAbilityKVTable[valuesType][parameterName][k] = foundParameter(
										oldAbilityKVTable, parameterName) or v
								end
							end
						else
							newAbilityKVTable[valuesType][parameterName] = foundParameter(oldAbilityKVTable,
								parameterName) or parameterValues
						end
					end
					------------------------------------генерация параметров-------------------------------------
					for parameterName, parameterValues in pairs(parameters) do
						if type(parameterValues) == "table" then
							local parameterValue = foundParameter(oldAbilityKVTable,
								parameterName)
							if not parameterValues.table and parameterValue then
								newAbilityKVTable = createParameter(newAbilityKVTable, parameterName, parameterValues,
									parameterValue, abilityName)
							elseif parameterValues.table and parameterValues.table[abilityName] then
								parameterValue = parameterValues.table[abilityName]
								-- print(abilityName..', '..parameterValue)
								newAbilityKVTable = createParameter(newAbilityKVTable, parameterName, parameterValues,
									parameterValue, abilityName)
							end
						end
					end
					--------------------------------------------------------------------------------------------
				end
			end
		end
	end

	-- for key, value in pairs(overrideKV) do
	-- if string.starts(key, "special_bonus_unique") then
	-- newKV[key] = value
	-- elseif not newKV[key] then
	-- 	newKV[key] = value
	-- end
	-- end

	if parameters.createLocalization then
		print("========================================")
		print("RU LOCALIZATION")
		GenerateLocalization(localization_ru)
		print("========================================")
		print("ENG LOCALIZATION")
		GenerateLocalization(localization_eng)
		print("========================================")
	end

	return newKV
end

-- PrintGeneratedKV(GenerateAbilitiesKVTable({}))

-- GenerateAbilitiesKVTable({
-- 	createLocalization = true,
-- 	stamina_drain_reduction = {
-- 		isCalculateSpellDamageTooltip = false,
-- 		localizationRu = "%УМЕНЬШЕНИЕ РАСХОДА ВЫНОСЛИВОСТИ:",
-- 		localizationEng = "%STAMINA CONSUMPTION REDUCE:"
-- 	},
-- 	jungle_bears_damage_multiplier = {
-- 		isCalculateSpellDamageTooltip = false,
-- 		localizationRu = "МНОЖИТЕЛЬ УРОНА ПО ЛЕСНЫМ МЕДВЕДЯМ:",
-- 		localizationEng = "JUNGLE BEARS DAMAGE MULTIPLIER:"
-- 	},
-- 	damage_to_arena_boss = {
-- 		isCalculateSpellDamageTooltip = false,
-- 		localizationRu = "%УРОН ПО БОССАМ:",
-- 		localizationEng = "%DAMAGE TO BOSSES:",
-- 		table = {
-- 			--zuus_static_field = 5,
-- 			--item_blade_mail = 40,
-- 			--centaur_return = 15,
-- 			enigma_midnight_pulse = 15,
-- 			enigma_black_hole = 200,
-- 			--techies_suicide = 25,
-- 			lina_laguna_blade = 200,
-- 			lion_finger_of_death = 200,
-- 			--shredder_chakram_2 = 40,
-- 			--shredder_chakram = 40,
-- 			--sniper_shrapnel = 40,
-- 			abyssal_underlord_firestorm = 15,
-- 			bristleback_quill_spray = 50,
-- 			--centaur_hoof_stomp = 40,
-- 			--centaur_double_edge = 40,
-- 			kunkka_ghostship = 200,
-- 			kunkka_torrent = 200,
-- 			ember_spirit_flame_guard = 200,
-- 			sandking_sand_storm = 200,
-- 			antimage_mana_void = 25,
-- 			doom_bringer_infernal_blade = 10,
-- 			winter_wyvern_arctic_burn = 10,
-- 			freya_ice_cage = 25,
-- 			--tinker_march_of_the_machines = 2000,
-- 			necrolyte_reapers_scythe = 25,
-- 			huskar_life_break = 20,
-- 			huskar_burning_spear_arena = 10,
-- 			phantom_assassin_fan_of_knives = 15,
-- 			item_unstable_quasar = 30,
-- 			bloodseeker_blood_mist = 200,
-- 			bloodseeker_bloodrage = 20,
-- 			bloodseeker_rupture = 50,
-- 			venomancer_poison_nova = 25,
-- 			venomancer_noxious_plague = 15,
-- 			phoenix_sun_ray = 10,
-- 			zuus_arc_lightning = 15,
-- 			muerta_pierce_the_veil = 33,
-- 			witch_doctor_maledict = 25,

-- 			item_piercing_blade = 5,
-- 			item_soulcutter = 10,
-- 			item_revenants_brooch = 200,
-- 			item_witch_blade = 200,
-- 		}
-- 	}
-- })
