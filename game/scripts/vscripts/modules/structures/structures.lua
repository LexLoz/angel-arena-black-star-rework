Structures = Structures or {}
Structures._couriers = Structures._couriers or {}

ModuleRequire(..., "data")
ModuleRequire(..., "shops")

Events:Register("activate", function()
	local gameMode = GameRules:GetGameModeEntity()
	gameMode:SetFountainConstantManaRegen(0)
	gameMode:SetFountainPercentageHealthRegen(0)
	gameMode:SetFountainPercentageManaRegen(0)
	Structures:AddHealers()
	Structures:ActivateTowers()
	Structures:CreateShops()
end)

Events:Register("bosses/kill/cursed_zeld", function()
	Notifications:TopToAll({ text = "#structures_fountain_protection_weak_line1", duration = 7 })
	Notifications:TopToAll({ text = "#structures_fountain_protection_weak_line2", duration = 7 })
end)

Events:Register("bosses/respawn/cursed_zeld", function()
	Notifications:TopToAll({ text = "#structures_fountain_protection_strong_line1", duration = 7 })
	Notifications:TopToAll({ text = "#structures_fountain_protection_strong_line2", duration = 7 })
end)

function Structures:AddTemporaryInvulnerability(structure)
	local preTime = HERO_SELECTION_PICK_TIME + HERO_SELECTION_STRATEGY_TIME + 3.75 + Options:GetValue("PreGameTime")
	if Options:GetValue("BanningPhaseBannedPercentage") > 0 then
		preTime = preTime + HERO_SELECTION_BANNING_TIME
	end
	structure:AddNewModifier(structure, nil, "modifier_invulnerable", nil)
	Timers:CreateTimer(preTime + 60 * 10, function()
		structure:RemoveModifierByName("modifier_invulnerable")
	end)
end

function Structures:ActivateTowers()
	for _, v in ipairs(Entities:FindAllByClassname("npc_dota_tower")) do
		-- print('tower')
		v:AddNewModifier(v, nil, "modifier_arena_tower", nil)
		v:SetBaseHealthRegen(0.25)
		-- Structures:AddTemporaryInvulnerability(v)
		local ability = v:AddAbility("tower_power")
		if ability then
			ability:SetLevel(1)
		end

		-- ability = v:AddAbility("boss_armor")
		-- if ability then
		-- 	ability:SetLevel(1)
		-- end
	end
end

function Structures:AddHealers()
	for _, v in ipairs(Entities:FindAllByClassname("npc_dota_healer")) do
		local model = TEAM_HEALER_MODELS[v:GetTeamNumber()]
		-- print('shrine')
		v:SetOriginalModel(model.mdl)
		v:SetModel(model.mdl)
		if model.color then v:SetRenderColor(unpack(model.color)) end
		-- v:RemoveModifierByName("modifier_invulnerable")
		v:AddNewModifier(v, nil, "modifier_arena_healer", nil)
		v:FindAbilityByName("healer_taste_of_armor"):SetLevel(1)
		v:FindAbilityByName("healer_bottle_refill"):SetLevel(1)
		Structures:AddTemporaryInvulnerability(v)
	end
end

function Structures:OnCourierSpawn(courier)
	Structures._couriers[courier:GetPlayerOwnerID()] = courier
	courier:AddNewModifier(courier, nil, "modifier_arena_courier", nil)
end

function Structures:GetCourier(playerId)
	return Structures._couriers[playerId]
end
