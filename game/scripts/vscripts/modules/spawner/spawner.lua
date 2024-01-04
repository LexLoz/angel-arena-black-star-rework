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
			local spawnername = string.gsub(string.gsub(entname, "target_mark_spawner_", ""), "_type%d+", "")
			-- print(spawnername)
			if spawnername == "jungle" and not Options:GetValue("EnableBears") then
			else
				Spawner.MinimapPoints[v] = DynamicMinimap:CreateMinimapPoint(v:GetAbsOrigin(),
					"icon_spawner icon_spawner_" ..
					spawnername)
				table.insert(Spawner.SpawnerEntities, v)
			end
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
	if Options:GetValue("EnableBears") then Spawner:MakeJungleStacks() end
end

function Spawner:SpawnStacks()
	local cash = {
		stats = {},
		models = {}
	}
	for _, entity in ipairs(Spawner.SpawnerEntities) do
		DynamicMinimap:SetVisibleGlobal(Spawner.MinimapPoints[entity], true)
		local entname = entity:GetName()
		local sName = string.gsub(string.gsub(entname, "target_mark_spawner_", ""), "_type%d+", "")
		local SpawnerType = tonumber(string.sub(entname, string.find(entname, "_type") + 5))
		if SpawnerType == 2 and sName == "hard" then return end

		local entid = entity:GetEntityIndex()
		local coords = entity:GetAbsOrigin()
		local minute = GetDOTATimeInMinutesFull()
		local function getCreepsCount()
			return math.min(SPAWNER_SETTINGS[sName].SpawnedPerSpawn,
				math.max(CREEPS_IN_CAMP_MIN, SPAWNER_SETTINGS[sName].MaxUnits / (GameMode.MapName == "4v4v4v4" and 2 or 1) - Spawner:CalculateCreepReduction()))
		end
		if sName ~= "jungle" and Spawner:CanSpawnUnits(sName, entid, getCreepsCount()) then
			if not cash.stats[sName] then
				cash.stats[sName] = Spawner:CalculateCreepsStats(sName,
					minute - 1)
			end
			if not cash.models[SpawnerType .. '' .. sName] then
				cash.models[SpawnerType .. '' .. sName] = table.nearestOrLowerKey(SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType][1],
					minute)
			end
			for i = 1, getCreepsCount() do
				local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
				local unitName = unitRootTable[1][-1]
				local unit = CreateUnitByName(unitName, coords, true, nil, nil, DOTA_TEAM_NEUTRALS)
				unit.SpawnerIndex = SpawnerType
				unit.SpawnerType = sName
				unit.SSpawner = entid
				unit.SLevel = minute
				Spawner.Creeps[entid] = Spawner.Creeps[entid] + 1
				Spawner:UpgradeCreep(unit, unit.SLevel, cash.stats[sName], cash.models[SpawnerType .. '' .. sName])
			end
		end
	end
end

function Spawner:CalculateCreepReduction()
	local time = GetDOTATimeInMinutesFull()
	return 0--math.max(0,
		--math.floor(time / REDUCE_CAMPS_START) + math.floor((time - REDUCE_CAMPS_START) / REDUCE_CAMPS_PER_MIN))
end

function Spawner:CanSpawnUnits(sName, id, count)
	Spawner:InitializeStack(id)
	return Spawner.Creeps[id] + count <=
		math.max(CREEPS_IN_CAMP_MIN, SPAWNER_SETTINGS[sName].MaxUnits / (GameMode.MapName == "4v4v4v4" and 2 or 1) - Spawner:CalculateCreepReduction())
end

function Spawner:InitializeStack(id)
	if not Spawner.Creeps[id] then
		Spawner.Creeps[id] = 0
	end
end

function Spawner:RollChampion(minute, unit)
	local champLevel = 0
	for level, info in pairs(SPAWNER_CHAMPION_LEVELS) do
		if minute > info.minute and RollPercentage(info.chance) then
			champLevel = math.max(champLevel, level)
		end
	end

	if champLevel > 0 then
		--print("Spawn champion with level " .. champLevel)
		unit:SetRenderColor(RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255))
		unit:AddNewModifier(unit, nil, "modifier_neutral_champion", nil):SetStackCount(champLevel)
		unit.IsChampionNeutral = true
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
	local _table = CREEP_UPGRADE_FUNCTIONS[type]
	local goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty = 0, 0, 0, 0, 0, 0, 0
	local maxCreepsInCurrentCamp = SPAWNER_SETTINGS[type].MaxUnits / (GameMode.MapName == "4v4v4v4" and 2 or 1)
	local creepReduction = math.min(maxCreepsInCurrentCamp - CREEPS_IN_CAMP_MIN, Spawner:CalculateCreepReduction())
	local mult = creepReduction / (maxCreepsInCurrentCamp - creepReduction)
	--print(goldbounty)
	local function Calc(t)
		goldbounty, hp, damage, attackspeed, movespeed, armor, xpbounty =
			goldbounty + t[1] + t[1] * mult,
			hp + t[2],-- + t[2] * mult,
			damage + t[3],-- + t[3] * mult,
			attackspeed + t[4],-- + t[4] * mult,
			movespeed + t[5],-- + t[5] * mult,
			armor + t[6],-- + t[6] * mult,
			xpbounty + t[7] + t[7] * mult
	end
	local saved_index
	for i = 0, minuteLevel do
		local t = _table[i]
		if t then
			saved_index = i
		end
		Calc(_table[saved_index])
	end

	return {
		goldbounty = goldbounty,
		hp = hp,
		damage = damage,
		attackspeed = attackspeed,
		movespeed = movespeed,
		armor = math.min(100, armor),
		xpbounty = xpbounty
	}
end

function Spawner:UpgradeCreep(unit, minutelevel, stat, model)
	local modelScale = 1 + (0.004 * minutelevel)
	if minutelevel > 1 then
		unit:CreatureLevelUp(minutelevel)
	end
	local champLevel = Spawner:RollChampion(minutelevel, unit)
	if champLevel > 0 then
		modelScale = modelScale + SPAWNER_CHAMPION_LEVELS[champLevel].model_scale
	end
	local MAP_MULTIPLIER = GameMode.Map_Gold_Multiplier or 1
	local PLAYERS_COUNT_MULTIPLIER = GetPlayersCountMultiplier()

	unit:SetDeathXP((unit:GetDeathXP() + stat.xpbounty) * (1 + champLevel) * MAP_MULTIPLIER *
		PLAYERS_COUNT_MULTIPLIER)
	unit:SetMinimumGoldBounty((unit:GetMinimumGoldBounty() + stat.goldbounty) * (1 + champLevel) * MAP_MULTIPLIER *
		PLAYERS_COUNT_MULTIPLIER)
	unit:SetMaximumGoldBounty((unit:GetMaximumGoldBounty() + stat.goldbounty) * (1 + champLevel) * MAP_MULTIPLIER *
		PLAYERS_COUNT_MULTIPLIER)
	unit:SetMaxHealth((unit:GetMaxHealth() + stat.hp) * (1 + champLevel))
	unit:SetBaseMaxHealth((unit:GetBaseMaxHealth() + stat.hp) * (1 + champLevel))
	unit:SetHealth((unit:GetMaxHealth() + stat.hp) * (1 + champLevel))
	unit:SetBaseDamageMin((unit:GetBaseDamageMin() + stat.damage) * (1 + champLevel))
	unit:SetBaseDamageMax((unit:GetBaseDamageMax() + stat.damage) * (1 + champLevel))
	unit:SetBaseMoveSpeed((unit:GetBaseMoveSpeed() + stat.movespeed) * (1 + champLevel))
	unit:SetPhysicalArmorBaseValue((unit:GetPhysicalArmorBaseValue() + stat.armor) * (1 + champLevel))
	--unit:SetBaseHealthRegen(unit:GetMaxHealth() * 0.01)
	unit:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
	local modifier = unit:FindModifierByNameAndCaster("modifier_neutral_upgrade_attackspeed", unit)
	if modifier then
		modifier:SetStackCount(stat.attackspeed * (1 + champLevel))
	end

	unit:SetModelScale(modelScale)

	if model then
		unit:SetModel(model)
		unit:SetOriginalModel(model)
	end
end

function Spawner:OnCreepDeath(unit)
	-- print('on creep death')
	Spawner.Creeps[unit.SSpawner] = Spawner.Creeps[unit.SSpawner] - 1
	if unit.SpawnerType == "jungle" and Spawner.Creeps[unit.SSpawner] == 0 then
		-- print('on all creep death')
		local spawnTime = (GameRules:GetGameTime() - (unit.spawntime or 1))
		-- print('spawn time: ' .. spawnTime)
		local golemUpgrade = false
		if not Options:GetValue("LegacyBears") then
			if spawnTime < 1 then
				golemUpgrade = true
			end
		end
		Timers:CreateTimer(Options:GetValue("LegacyBears") and 0.2 + unit.SLevel * 0.0001 or 0,
			function()
				Spawner:SpawnJungleStacks(unit.SSpawner, unit.SpawnerIndex, unit.SpawnerType,
					{
						golemUpgrade = golemUpgrade,
						golem_stacks = unit.golem_stacks or 1,
						spawnTime = spawnTime,
						gold_buff = unit.gold_buff or 1
					})
			end
		)
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

			Spawner:InitializeStack(entid)
			Spawner:SpawnJungleStacks(entid, SpawnerType, sName, {})
		end
	end
end

function Spawner:SpawnJungleStacks(entid, SpawnerType, sName, deadTable)
	local golem_stacks = deadTable.golem_stacks or 0
	local gold_buff = deadTable.gold_buff or 1
	local golemUpgrade = deadTable.golemUpgrade
	local spawnTime = deadTable.spawnTime

	local entity = EntIndexToHScript(entid)
	if Options:GetValue("LegacyBears") then
		entity.cycle = (entity.cycle or 0) + 1
	elseif golemUpgrade then
		entity.cycle = (entity.cycle or 1) + 1
		gold_buff = gold_buff + entity.cycle ^ 1.05
	end
	gold_buff = gold_buff > 1 and gold_buff * 0.8 or 1
	local cycle = entity.cycle

	-- print('cycle: ' .. cycle)

	DynamicMinimap:SetVisibleGlobal(Spawner.MinimapPoints[entity], true)
	local coords = entity:GetAbsOrigin()
	for i = 1, SPAWNER_SETTINGS[sName].SpawnedPerSpawn do
		local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
		local unitName = unitRootTable[1][-1]
		local unit = CreateUnitByName(unitName, coords, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local champLevel = 0

		if not Options:GetValue("LegacyBears") then
			local buffsCount = (golemUpgrade and (1 - math.min(1, spawnTime or 1)) * math.floor((0.9 + (cycle or 1) * 0.1) ^ 1.05) * 6 or 1) +
				math.floor((cycle or 1) / 15)
			if golemUpgrade then
				champLevel = Spawner:RollChampion(GetDOTATimeInMinutesFull(), unit)
				ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf",
					PATTACH_ABSORIGIN, unit)
				unit:EmitSound("Arena.Items.Behelit.Buff")
			end
			local upgradeBuff = golemUpgrade and cycle or 0
			unit.golem_stacks = golem_stacks + buffsCount + upgradeBuff

			unit:AddNewModifier(unit, nil, "modifier_jungle_golem",
				{ duration = GameMode.MapName == "war3" and 60 or 180 }):SetStackCount(math.round(unit.golem_stacks *
				(champLevel > 0 and 1.25 or 1)))
			unit:AddNewModifier(unit, nil, "modifier_talent_true_strike",
				{}):SetStackCount(25)
		end

		unit.gold_buff = gold_buff or 1
		unit.SpawnerIndex = SpawnerType
		unit.SpawnerType = sName
		unit.SSpawner = entid
		unit.SLevel = cycle
		unit.ChampLevel = champLevel
		Spawner.Creeps[entid] = Spawner.Creeps[entid] + 1
		Spawner:UpgradeJungleCreep(unit, unit.SLevel, unit.SpawnerIndex)
	end
end

function Spawner:UpgradeJungleCreep(unit, cycle, spawnerIndex)
	cycle = cycle or 1
	if cycle > 1 then unit:CreatureLevelUp(cycle - 1) end
	unit.spawntime = GameRules:GetGameTime()

	local WAR3_MULTIPLIER = GameMode.Jungle_Bears_Reward_Multiplier or 1
	local ChampLevel = unit.ChampLevel

	if not Options:GetValue("LegacyBears") then
		unit:SetDeathXP((5 * cycle ^ 1.05 * unit.gold_buff) * WAR3_MULTIPLIER * (1 + ChampLevel * 4))
		unit:SetMinimumGoldBounty((14 * cycle * unit.gold_buff) * WAR3_MULTIPLIER * (1 + ChampLevel * 2))
		unit:SetMaximumGoldBounty((16 * cycle * unit.gold_buff) * WAR3_MULTIPLIER * (1 + ChampLevel * 2))
		local health = 300 * (cycle ^ 1.6) * (1 + ChampLevel)
		unit:SetMaxHealth(health)
		unit:SetBaseMaxHealth(health)
		unit:SetHealth(health)
		unit:SetBaseDamageMin(9 * cycle ^ 1.4 * (1 + ChampLevel))
		unit:SetBaseDamageMax(12 * cycle ^ 1.4 * (1 + ChampLevel))
		unit:SetBaseMoveSpeed(300 + (cycle - 1))
		unit:SetPhysicalArmorBaseValue((0.5 + cycle * 0.5))
		unit:SetBaseMagicalResistanceValue(math.min(99, 25 + (0.3 + cycle * 0.7 - 1)))
		-- unit:SetBaseAttackTime(math.max(0.1, 2 - (0.99 + cycle * 0.01)))
		unit:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
		local modifier = unit:FindModifierByNameAndCaster("modifier_neutral_upgrade_attackspeed", unit)
		if modifier then
			modifier:SetStackCount(math.round(cycle * 10) * (1 + ChampLevel))
		end

		local model = table.nearestOrLowerKey(SPAWNER_SETTINGS.jungle.SpawnTypes2, cycle)
		if model then
			unit:SetModel(model)
			unit:SetOriginalModel(model)
		end
		unit:SetModelScale(1 + 0.002 * cycle * (0.9 + (1 + ChampLevel) * 0.1))
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
		local model = table.nearestOrLowerKey(SPAWNER_SETTINGS.jungle.SpawnTypes[spawnerIndex][1], cycle)
		if model then
			unit:SetModel(model)
			unit:SetOriginalModel(model)
		end
	end
end
