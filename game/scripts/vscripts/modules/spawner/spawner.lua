-- TODO: Refactor this

ModuleRequire(..., "data")

if Spawner == nil then
	Spawner = class({})
	Spawner.SpawnerEntities = {}
	Spawner.Creeps = {}
	Spawner.MinimapPoints = {}
	Spawner.NextCreepsSpawnTime = 0
end

function Spawner:GetSpawners()
	local spawners = {}
	for i, _ in pairs(SPAWNER_SETTINGS) do
		if i ~= "Cooldown" then
			table.insert(spawners, i)
		end
	end
	return spawners
end

function Spawner:PreloadSpawners()
	local targets = Entities:FindAllByClassname("info_target")
	for _, v in ipairs(targets) do
		local entname = v:GetName()
		--print(entname)
		if string.find(entname, "target_mark_spawner_") then
			Spawner.MinimapPoints[v] = DynamicMinimap:CreateMinimapPoint(v:GetAbsOrigin(),
				"icon_spawner icon_spawner_" ..
				string.gsub(string.gsub(entname, "target_mark_spawner_", ""), "_type%d+", ""))
			table.insert(Spawner.SpawnerEntities, v)
		end
	end
end

function Spawner:RegisterTimers()
	Timers:CreateTimer(function()
		if GameRules:GetDOTATime(false, false) >= Spawner.NextCreepsSpawnTime then
			Spawner.NextCreepsSpawnTime = Spawner.NextCreepsSpawnTime +
				SPAWNER_SETTINGS.Cooldown * (Spawner.NextCreepsSpawnTime == 0 and 2 or 1)
			Spawner:SpawnStacks()
		end
		return 0.5
	end)
	Spawner:MakeJungleStacks()
end

function Spawner:SpawnStacks()
	local timer1 = 0
	for _, entity in ipairs(Spawner.SpawnerEntities) do
		DynamicMinimap:SetVisibleGlobal(Spawner.MinimapPoints[entity], true)
		local entname = entity:GetName()
		local sName = string.gsub(string.gsub(entname, "target_mark_spawner_", ""), "_type%d+", "")
		local SpawnerType = tonumber(string.sub(entname, string.find(entname, "_type") + 5))
		local entid = entity:GetEntityIndex()
		local coords = entity:GetAbsOrigin()
		if sName ~= "jungle" and Spawner:CanSpawnUnits(sName, entid) then
			for i = 1, SPAWNER_SETTINGS[sName].SpawnedPerSpawn do
				local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
				local unitName = unitRootTable[1][-1]
				local unit = CreateUnitByName(unitName, coords, true, nil, nil, DOTA_TEAM_NEUTRALS)
				unit.SpawnerIndex = SpawnerType
				unit.SpawnerType = sName
				unit.SSpawner = entid
				unit.SLevel = GetDOTATimeInMinutesFull()
				Spawner.Creeps[entid] = Spawner.Creeps[entid] + 1
				Spawner:UpgradeCreep(unit, unit.SpawnerType, unit.SLevel, unit.SpawnerIndex)
			end
		end
	end
end

function Spawner:CanSpawnUnits(sName, id)
	Spawner:InitializeStack(id)
	return Spawner.Creeps[id] + SPAWNER_SETTINGS[sName].SpawnedPerSpawn <= SPAWNER_SETTINGS[sName].MaxUnits
end

function Spawner:InitializeStack(id)
	if not Spawner.Creeps[id] then
		Spawner.Creeps[id] = 0
	end
end

function Spawner:RollChampion(minute)
	local champLevel = 0
	for level, info in pairs(SPAWNER_CHAMPION_LEVELS) do
		if minute > info.minute and RollPercentage(info.chance) then
			champLevel = math.max(champLevel, level)
		end
	end
	return champLevel
end

function CDOTA_BaseNPC:IsChampion()
	return self.IsChampionNeutral == true
end

function CDOTA_BaseNPC:IsJungleBear()
	return self.SpawnerType == "jungle"
end

CDOTA_BaseNPC_Creature.IsChampion = CDOTA_BaseNPC.IsChampion

function Spawner:CalculateCreepsStats(type, minuteLevel)
	local table = CREEP_UPGRADE_FUNCTIONS[type]
	local goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty = 0, 0, 0, 0, 0, 0, 0
	--print(goldbounty)
	local function Calc(t)
		goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty =
			goldbounty + t[1],
			hp + t[2],
			damage + t[3],
			attackspeed + t[4],
			movespeed + t[5],
			armor + t[6],
			xpbounty + t[7]
	end
	local saved_index
	for i = 0, minuteLevel do
		local t = table[i]
		if t then
			saved_index = i
		end
		Calc(table[saved_index])
	end

	return goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty
end

--print(Spawner:CalculateCreepsStats('easy', 50))

function Spawner:UpgradeCreep(unit, spawnerType, minutelevel, spawnerIndex)
	local modelScale = 1 + (0.004 * minutelevel)
	if minutelevel > 1 then
		unit:CreatureLevelUp(minutelevel)
	end

	local goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty = Spawner:CalculateCreepsStats(spawnerType,
		minutelevel - 1)

	--unpack(table.nearestOrLowerKey(CREEP_UPGRADE_FUNCTIONS[spawnerType], minutelevel))
	-- if not customCalculate then
	-- 	goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty = goldbounty * minutelevel, hp * minutelevel, damage * minutelevel, attackspeed * minutelevel, movespeed * minutelevel, armor * minutelevel, xpbounty * minutelevel
	-- end
	local champLevel = Spawner:RollChampion(minutelevel)
	if champLevel > 0 then
		--print("Spawn champion with level " .. champLevel)
		modelScale = modelScale + SPAWNER_CHAMPION_LEVELS[champLevel].model_scale
		unit:SetRenderColor(RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255))
		unit:AddNewModifier(unit, nil, "modifier_neutral_champion", nil):SetStackCount(champLevel)
		unit.IsChampionNeutral = true
	end
	local MAP_MULTIPLIER = GameMode.Map_Gold_Multiplier or 1
	local PLAYERS_COUNT_MULTIPLIER = GetPlayersCountMultiplier()

	unit:SetDeathXP((unit:GetDeathXP() + xpbounty) * (1 + champLevel * 5) * MAP_MULTIPLIER * PLAYERS_COUNT_MULTIPLIER)
	unit:SetMinimumGoldBounty((unit:GetMinimumGoldBounty() + goldbounty) * (1 + champLevel * 1.5) * MAP_MULTIPLIER *
		PLAYERS_COUNT_MULTIPLIER)
	unit:SetMaximumGoldBounty((unit:GetMaximumGoldBounty() + goldbounty) * (1 + champLevel * 1.5) * MAP_MULTIPLIER *
		PLAYERS_COUNT_MULTIPLIER)
	unit:SetMaxHealth((unit:GetMaxHealth() + hp) * (1 + champLevel))
	unit:SetBaseMaxHealth((unit:GetBaseMaxHealth() + hp) * (1 + champLevel))
	unit:SetHealth((unit:GetMaxHealth() + hp) * (1 + champLevel))
	unit:SetBaseDamageMin((unit:GetBaseDamageMin() + damage) * (1 + champLevel * 0.5))
	unit:SetBaseDamageMax((unit:GetBaseDamageMax() + damage) * (1 + champLevel * 0.5))
	unit:SetBaseMoveSpeed((unit:GetBaseMoveSpeed() + movespeed) * (1 + champLevel))
	unit:SetPhysicalArmorBaseValue((unit:GetPhysicalArmorBaseValue() + armor) * (1 + champLevel * 0.5))
	--unit:SetBaseHealthRegen(unit:GetMaxHealth() * 0.01)
	unit:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
	local modifier = unit:FindModifierByNameAndCaster("modifier_neutral_upgrade_attackspeed", unit)
	if modifier then
		modifier:SetStackCount(attackspeed * (1 + champLevel))
	end

	unit:SetModelScale(modelScale)

	local model = table.nearestOrLowerKey(SPAWNER_SETTINGS[spawnerType].SpawnTypes[spawnerIndex][1], minutelevel)
	if model then
		unit:SetModel(model)
		unit:SetOriginalModel(model)
	end
end

function Spawner:OnCreepDeath(unit)
	Spawner.Creeps[unit.SSpawner] = Spawner.Creeps[unit.SSpawner] - 1
	if unit.SpawnerType == "jungle" and Spawner.Creeps[unit.SSpawner] == 0 then
		local spawn_delay = 0
		if (GameRules:GetGameTime() - unit.spawntime) <= 0.1 and unit:GetLevel() < 400 then
			spawn_delay = 0.5
		end
		if unit:GetLevel() >= 1200 and not Options:GetValue("LegacyBears") then
			spawn_delay = 9999999;
		end
		Timers:CreateTimer(spawn_delay, function()
			Spawner:SpawnJungleStacks(unit.SSpawner, unit.SpawnerIndex, unit.SpawnerType)
		end)
	end
end

function Spawner:MakeJungleStacks()
	for _, entity in ipairs(Spawner.SpawnerEntities) do
		DynamicMinimap:SetVisibleGlobal(Spawner.MinimapPoints[entity], true)
		local entname = entity:GetName()
		local sName = string.gsub(string.gsub(entname, "target_mark_spawner_", ""), "_type%d+", "")
		if sName == "jungle" then
			local SpawnerType = tonumber(string.sub(entname, string.find(entname, "_type") + 5))
			local entid = entity:GetEntityIndex()
			local coords = entity:GetAbsOrigin()

			Spawner:InitializeStack(entid)
			Spawner:SpawnJungleStacks(entid, SpawnerType, sName)
		end
	end
end

function Spawner:SpawnJungleStacks(entid, SpawnerType, sName)
	local entity = EntIndexToHScript(entid)
	entity.cycle = (entity.cycle or 0) + 1

	DynamicMinimap:SetVisibleGlobal(Spawner.MinimapPoints[entity], true)
	local coords = entity:GetAbsOrigin()
	for i = 1, SPAWNER_SETTINGS[sName].SpawnedPerSpawn do
		local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
		local unitName = unitRootTable[1][-1]
		local unit = CreateUnitByName(unitName, coords, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit.SpawnerIndex = SpawnerType
		unit.SpawnerType = sName
		unit.SSpawner = entid
		unit.SLevel = entity.cycle
		Spawner.Creeps[entid] = Spawner.Creeps[entid] + 1
		Spawner:UpgradeJungleCreep(unit, unit.SLevel, unit.SpawnerIndex)
	end
end

function Spawner:UpgradeJungleCreep(unit, cycle, spawnerIndex)
	--cycle = cycle + 198
	if cycle > 1 then unit:CreatureLevelUp(cycle - 1) end
	unit.spawntime = GameRules:GetGameTime()

	local WAR3_MULTIPLIER = GameMode.Jungle_Bears_Reward_Multiplier or 1
	local MAP_MULTIPLIER = GameMode.Map_Gold_Multiplier or 1

	if not Options:GetValue("LegacyBears") then
		local LEVEL = unit:GetLevel()

		local BASE_HEALTH = unit:GetMaxHealth()
		local HEALTH_PER_LEVEL = 10

		local BASE_GOLD = unit:GetMinimumGoldBounty()

		local BASE_DAMAGE = unit:GetBaseDamageMin()
		local DAMAGE_PER_LEVEL = 0.2

		local LEVEL_TO_UPGRADE = 200
		local MAX_LEVEL = 1200

		local LEVEL_MULTIPLIER = 1 + math.floor(LEVEL / LEVEL_TO_UPGRADE)
		local MAX_LEVEL_MULTIPLIER = 1 +
			(LEVEL >= MAX_LEVEL and math.floor((LEVEL - MAX_LEVEL + LEVEL_TO_UPGRADE) / LEVEL_TO_UPGRADE) or 0)

		local ONE_TIME_MULTIPLIER = 1
		if LEVEL % LEVEL_TO_UPGRADE == 0 then
			ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf",
				PATTACH_ABSORIGIN, unit)
			unit:EmitSound("Arena.Items.Behelit.Buff")
			ONE_TIME_MULTIPLIER = 1 + (LEVEL / LEVEL_TO_UPGRADE)
			unit:AddNewModifier(unit, nil, "modifier_jungle_bear", {})
		end

		unit:SetDeathXP((unit:GetDeathXP() + LEVEL * 0.1 + ((ONE_TIME_MULTIPLIER - 1)) * 5000 * 1.5 ^ (ONE_TIME_MULTIPLIER - 1)) *
			WAR3_MULTIPLIER * MAP_MULTIPLIER)

		local gold_reward = math.min(30000000000,
			math.floor((BASE_GOLD * (0.75 + MAX_LEVEL_MULTIPLIER * 0.25) * ONE_TIME_MULTIPLIER ^ 5) *
				(LEVEL_MULTIPLIER ^ 2.5) * WAR3_MULTIPLIER * MAP_MULTIPLIER))
		-- print(gold_reward)
		unit:SetMinimumGoldBounty(gold_reward)
		unit:SetMaximumGoldBounty(gold_reward)

		--unit:SetMaxMana((unit:GetMaxMana() * ((0.75 + LEVEL_MULTIPLIER * 0.25) ^ 2)) * (0.988 + cycle * 0.012))
		--unit:SetMana(unit:GetMaxMana())

		unit:SetMaxHealth(math.min(2000000000,
			math.floor(BASE_HEALTH * LEVEL_MULTIPLIER ^ 2 +
				(HEALTH_PER_LEVEL * (0.3 + MAX_LEVEL_MULTIPLIER * 0.7) * (ONE_TIME_MULTIPLIER ^ 1.6)) * (LEVEL - 1) *
				(LEVEL >= LEVEL_TO_UPGRADE and 2 or 1) ^ (0.5 + LEVEL_MULTIPLIER * 0.5))))
		unit:SetBaseMaxHealth(unit:GetMaxHealth())
		unit:SetHealth(unit:GetMaxHealth())

		local damage = math.floor(BASE_DAMAGE +
			(DAMAGE_PER_LEVEL * (0.6 + MAX_LEVEL_MULTIPLIER * 0.4) * ONE_TIME_MULTIPLIER ^ 1.2) * (LEVEL - 1) *
			LEVEL_MULTIPLIER ^ 3.25)
		unit:SetBaseDamageMin(damage)
		unit:SetBaseDamageMax(damage)

		unit:SetBaseMoveSpeed(unit:GetBaseMoveSpeed() + 1 * (0.35 + cycle * 0.65))

		--unit:SetBaseHealthRegen(ONE_TIME_MULTIPLIER > 1 and unit:GetMaxHealth() * 0.12 or unit:GetMaxHealth() * 0.03)
		unit:SetBaseHealthRegen(unit:GetMaxHealth() * 0.01)
		local armor = ((LEVEL_MULTIPLIER - 1) * 2 + (MAX_LEVEL_MULTIPLIER - 1) * 5) *
			(ONE_TIME_MULTIPLIER > 1 and 10 or 1)
		unit:SetPhysicalArmorBaseValue(armor)
		unit:SetBaseMagicalResistanceValue(ONE_TIME_MULTIPLIER > 1 and (MAX_LEVEL_MULTIPLIER > 1 and 60 or 40) or 25)

		unit:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
		local modifier = unit:FindModifierByNameAndCaster("modifier_neutral_upgrade_attackspeed", unit)
		if modifier then
			modifier:SetStackCount(math.round((1 * (LEVEL_MULTIPLIER - 1) * 2) + cycle * 0.25))
		end

		if unit:GetLevel() >= MAX_LEVEL or ONE_TIME_MULTIPLIER > 1 then
			unit:SetModelScale(1 + 0.1 * LEVEL_MULTIPLIER)
		end
	else
		local multiplier = 0.5 + cycle * 0.5
		unit:SetDeathXP(35 * (0.85 + cycle * 0.15))
		unit:SetMinimumGoldBounty(36 * (0.85 + cycle * 0.15))
		unit:SetMaximumGoldBounty(47 * (0.85 + cycle * 0.15))
		unit:SetMaxHealth(220 * multiplier)
		unit:SetBaseMaxHealth(220 * multiplier)
		unit:SetHealth(220 * multiplier)
		unit:SetBaseDamageMin(7 * multiplier)
		unit:SetBaseDamageMax(8 * multiplier)
		unit:SetBaseMoveSpeed(unit:GetBaseMoveSpeed() + 1 * multiplier)
		unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorBaseValue() * multiplier)
		unit:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
		local modifier = unit:FindModifierByNameAndCaster("modifier_neutral_upgrade_attackspeed", unit)
		if modifier then
			modifier:SetStackCount(math.round(multiplier))
		end

		unit:SetModelScale(1 + 0.0015 * cycle)
	end
	local model = table.nearestOrLowerKey(SPAWNER_SETTINGS.jungle.SpawnTypes[spawnerIndex][1], cycle)
	if model then
		unit:SetModel(model)
		unit:SetOriginalModel(model)
	end
end
