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
				Spawner:SpawnJungleStacks(unit.SSpawner, unit.SpawnerIndex, unit.SpawnerType, golemUpgrade, unit.golem_stacks or 1,
					spawnTime)
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
			Spawner:SpawnJungleStacks(entid, SpawnerType, sName)
		end
	end
end

function Spawner:SpawnJungleStacks(entid, SpawnerType, sName, golemUpgrade, golem_stacks, spawnTime)
	golem_stacks = golem_stacks or 0
	local entity = EntIndexToHScript(entid)
	if Options:GetValue("LegacyBears") then
		entity.cycle = (entity.cycle or 0) + 1
	elseif golemUpgrade then
		entity.cycle = (entity.cycle or 1) + 1
	end
	local cycle = entity.cycle
	-- print('cycle: ' .. cycle)

	DynamicMinimap:SetVisibleGlobal(Spawner.MinimapPoints[entity], true)
	local coords = entity:GetAbsOrigin()
	for i = 1, SPAWNER_SETTINGS[sName].SpawnedPerSpawn do
		local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
		local unitName = unitRootTable[1][-1]
		local unit = CreateUnitByName(unitName, coords, true, nil, nil, DOTA_TEAM_NEUTRALS)

		if not Options:GetValue("LegacyBears") then
			local buffsCount = (golemUpgrade and (1 - math.min(1, spawnTime or 1)) * math.floor((0.8 + (cycle or 1) * 0.1) ^ 1.1) * 10 or 1) + math.floor((cycle or 1) / 15)
			if golemUpgrade then
				ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf",
					PATTACH_ABSORIGIN, unit)
				unit:EmitSound("Arena.Items.Behelit.Buff")
			end
			local upgradeBuff = golemUpgrade and cycle or 0
			unit.golem_stacks = (golem_stacks + buffsCount) + upgradeBuff
			unit:AddNewModifier(unit, nil, "modifier_jungle_golem",
				{ duration = GameMode.MapName == "war3" and 60 or 180 }):SetStackCount(unit.golem_stacks)
			unit:AddNewModifier(unit, nil, "modifier_talent_true_strike",
				{}):SetStackCount(25)
		end

		unit.SpawnerIndex = SpawnerType
		unit.SpawnerType = sName
		unit.SSpawner = entid
		unit.SLevel = cycle
		-- unit.cycle = cycle
		Spawner.Creeps[entid] = Spawner.Creeps[entid] + 1
		Spawner:UpgradeJungleCreep(unit, unit.SLevel, unit.SpawnerIndex, golemUpgrade)
	end
end

function Spawner:UpgradeJungleCreep(unit, cycle, spawnerIndex, golemUpgrade)
	cycle = cycle or 1
	if cycle > 1 then unit:CreatureLevelUp(cycle - 1) end
	unit.spawntime = GameRules:GetGameTime()

	local WAR3_MULTIPLIER = GameMode.Jungle_Bears_Reward_Multiplier or 1

	if not Options:GetValue("LegacyBears") then
		local golemUpgradeBuff = (golemUpgrade and cycle or 1)

		unit:SetDeathXP((5 * cycle ^ 1.05 * golemUpgradeBuff ^ 1.3) * WAR3_MULTIPLIER)
		unit:SetMinimumGoldBounty((15 * (cycle ^ 1.3) * golemUpgradeBuff ^ 1.3) * WAR3_MULTIPLIER)
		unit:SetMaximumGoldBounty((15 * (cycle ^ 1.3) * golemUpgradeBuff ^ 1.3) * WAR3_MULTIPLIER)
		local health = 300 * cycle ^ 2.2
		unit:SetMaxHealth(health)
		unit:SetBaseMaxHealth(health)
		unit:SetHealth(health)
		unit:SetBaseDamageMin(9 * cycle ^ 1.6)
		unit:SetBaseDamageMax(12 * cycle ^ 1.6)
		unit:SetBaseMoveSpeed(300 + (cycle - 1))
		unit:SetPhysicalArmorBaseValue(0.5 + cycle * 0.5)
		unit:SetBaseMagicalResistanceValue(math.min(99, 25 + (0.3 + cycle * 0.7 - 1)))
		-- unit:SetBaseAttackTime(math.max(0.1, 2 - (0.99 + cycle * 0.01)))
		unit:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
		local modifier = unit:FindModifierByNameAndCaster("modifier_neutral_upgrade_attackspeed", unit)
		if modifier then
			modifier:SetStackCount(math.round(cycle * 10))
		end

		local model = table.nearestOrLowerKey({
			[0] = "models/creeps/neutral_creeps/n_creep_golem_b/n_creep_golem_b.vmdl",
			[2] = "models/creeps/neutral_creeps/n_creep_golem_a/neutral_creep_golem_a.vmdl",
			[3] = "models/heroes/warlock/warlock_demon.vmdl",
			[4] = "models/items/warlock/archivist_golem/archivist_golem.vmdl",
			[5] = "models/items/warlock/golem/ahmhedoq/ahmhedoq.vmdl",
			[6] = "models/items/warlock/golem/doom_of_ithogoaki/doom_of_ithogoaki.vmdl",
			[7] = "models/items/warlock/golem/greevil_master_greevil_golem/greevil_master_greevil_golem.vmdl",
			[8] = "models/items/warlock/golem/grimoires_pitlord_ultimate/grimoires_pitlord_ultimate.vmdl",
			[9] = "models/items/warlock/golem/hellsworn_golem/hellsworn_golem.vmdl",
			[10] = "models/items/warlock/golem/mdl_warlock_golem/mdl_warlock_golem.vmdl",
			[11] = "models/items/warlock/golem/mystery_of_the_lost_ores_golem/mystery_of_the_lost_ores_golem.vmdl",
			[12] = "models/items/warlock/golem/obsidian_golem/obsidian_golem.vmdl",
			[13] = "models/items/warlock/golem/puppet_summoner_golem/puppet_summoner_golem.vmdl",
			[14] = "models/items/warlock/golem/tevent_2_gatekeeper_golem/tevent_2_gatekeeper_golem.vmdl",
			[15] = "models/items/warlock/golem/the_torchbearer/the_torchbearer.vmdl",
			[16] = "models/items/warlock/golem/ti9_cache_warlock_tribal_warlock_golem/ti9_cache_warlock_tribal_golem_alt.vmdl",
			[17] = "models/items/warlock/golem/ti_8_warlock_darkness_apostate_golem/ti_8_warlock_darkness_apostate_golem.vmdl",
			[18] = "models/items/warlock/golem/warlock_the_infernal_master_golem/warlock_the_infernal_master_golem.vmdl",
			[19] = "models/heroes/undying/undying_flesh_golem.vmdl",
			[20] = "models/heroes/undying/undying_flesh_golem_rubick.vmdl",
			[21] = "models/items/undying/flesh_golem/corrupted_scourge_corpse_hive/corrupted_scourge_corpse_hive.vmdl",
			[22] = "models/items/undying/flesh_golem/davy_jones_set_davy_jones_set_kraken/davy_jones_set_davy_jones_set_kraken.vmdl",
			[23] = "models/items/undying/flesh_golem/deathmatch_dominator_golem/deathmatch_dominator_golem.vmdl",
			[24] = "models/items/undying/flesh_golem/elegy_of_abyssal_samurai_golem/elegy_of_abyssal_samurai_golem.vmdl",
			[25] = "models/items/undying/flesh_golem/frostivus_2018_undying_accursed_draugr_golem/frostivus_2018_undying_accursed_draugr_golem.vmdl",
			[26] = "models/items/undying/flesh_golem/grim_harvest_golem/grim_harvest_golem.vmdl",
			[27] = "models/items/undying/flesh_golem/incurable_pestilence_golem/incurable_pestilence_golem.vmdl",
			[28] = "models/items/undying/flesh_golem/spring2021_bristleback_paganism_pope_golem/spring2021_bristleback_paganism_pope_golem.vmdl",
			[29] = "models/items/undying/flesh_golem/ti8_undying_miner_flesh_golem/ti8_undying_miner_flesh_golem.vmdl",
			[30] = "models/items/undying/flesh_golem/ti9_cache_undying_carnivorous_parasitism_golem/ti9_cache_undying_carnivorous_parasitism_golem.vmdl",
			[31] = "models/items/undying/flesh_golem/undying_frankenstein_ability/undying_frankenstein_ability.vmdl",
			[32] = "models/items/undying/flesh_golem/watchmen_of_wheat_field_scarecrow/watchmen_of_wheat_field_scarecrow.vmdl",
		}, cycle)
		if model then
			unit:SetModel(model)
			unit:SetOriginalModel(model)
		end
		unit:SetModelScale(1 + 0.02 * cycle)
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
