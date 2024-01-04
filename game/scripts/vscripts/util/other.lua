function CreateTeamNotificationSettings(team, bSecond)
	local textColor = ColorTableToCss(Teams:GetColor(team))
	return { text = Teams:GetName(team, bSecond), continue = true, style = { color = textColor } }
end

function GetDOTATimeInMinutesFull()
	return math.floor(GameRules:GetDOTATime(false, false) / 60)
end

function CreateGoldNotificationSettings(amount)
	return { text = amount, continue = true, style = { color = "gold" } },
		{ text = "#notifications_gold", continue = true, style = { color = "gold" } }
end

function GenerateAttackProjectile(unit, optAbility)
	local projectile_info = {}
	projectile_info = {
		EffectName = unit:GetKeyValue("ProjectileModel"),
		Ability = optAbility,
		vSpawnOrigin = unit:GetAbsOrigin(),
		Source = unit,
		bHasFrontalCone = false,
		iMoveSpeed = unit:GetKeyValue("ProjectileSpeed") or 99999,
		bReplaceExisting = false,
		bProvidesVision = false
	}
	return projectile_info
end

function FindFountain(team)
	return Entities:FindByName(nil, "npc_arena_fountain_" .. team)
end

function HasDamageFlag(damage_flags, flag)
	return bit.band(damage_flags, flag) == flag
end

function ReplaceAbilities(unit, oldAbility, newAbility, keepLevel, keepCooldown)
	local ability = unit:FindAbilityByName(oldAbility)
	local level = ability:GetLevel()
	local cooldown = ability:GetCooldownTimeRemaining()
	unit:RemoveAbility(oldAbility)
	local new_ability = unit:AddAbility(newAbility)
	new_ability:OnCreated()
	if keepLevel then
		new_ability:SetLevel(level)
	end
	if keepCooldown then
		new_ability:StartCooldown(cooldown)
	end
	return new_ability
end

function PreformMulticast(caster, ability_cast, multicast, multicast_delay, target)
	local multicast_type = ability_cast:GetMulticastType()
	if multicast_type ~= MULTICAST_TYPE_NONE then
		local prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf',
			PATTACH_OVERHEAD_FOLLOW, caster)
		local multicast_flag_data = GetMulticastFlags(caster, ability_cast, multicast_type)
		local channelData = {}
		caster:AddEndChannelListener(function(interrupted)
			channelData.endTime = GameRules:GetGameTime()
			channelData.channelFailed = interrupted
		end)
		if multicast_type == MULTICAST_TYPE_INSTANT then
			Timers:NextTick(function()
				ParticleManager:SetParticleControl(prt, 1, Vector(multicast, 0, 0))
				ParticleManager:ReleaseParticleIndex(prt)
				local multicast_casted_data = {}
				for i = 2, multicast do
					CastMulticastedSpellInstantly(caster, ability_cast, target, multicast_flag_data,
						multicast_casted_data, 0, channelData)
				end
			end)
		else
			CastMulticastedSpell(caster, ability_cast, target, multicast - 1, multicast_type, multicast_flag_data, {},
				multicast_delay, channelData, prt, 2)
		end
	end
end

function GetMulticastFlags(caster, ability, multicast_type)
	local rv = {}
	if multicast_type ~= MULTICAST_TYPE_SAME then
		rv.cast_range = ability:GetCastRange(caster:GetOrigin(), caster)
		local abilityTarget = ability:GetAbilityTargetTeam()
		if abilityTarget == 0 then abilityTarget = DOTA_UNIT_TARGET_TEAM_ENEMY end
		rv.abilityTarget = abilityTarget
		local abilityTargetType = ability:GetAbilityTargetTeam()
		if abilityTargetType == 0 then
			abilityTargetType = DOTA_UNIT_TARGET_ALL
		elseif abilityTargetType == 2 and ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT) then
			abilityTargetType = 3
		end
		rv.abilityTargetType = abilityTargetType
		rv.team = caster:GetTeam()
		rv.targetFlags = ability:GetAbilityTargetFlags()
	end
	return rv
end

function CastMulticastedSpellInstantly(caster, ability, target, multicast_flag_data, multicast_casted_data, delay,
									   channelData)
	local candidates = FindUnitsInRadius(multicast_flag_data.team, caster:GetOrigin(), nil,
		multicast_flag_data.cast_range, multicast_flag_data.abilityTarget, multicast_flag_data.abilityTargetType,
		multicast_flag_data.targetFlags, FIND_ANY_ORDER, false)
	local Tier1 = {} --heroes
	local Tier2 = {} --creeps and self
	local Tier3 = {} --already casted
	local Tier4 = {} --dead stuff
	for k, v in pairs(candidates) do
		if caster:CanEntityBeSeenByMyTeam(v) then
			if multicast_casted_data[v] then
				Tier3[#Tier3 + 1] = v
			elseif not v:IsAlive() then
				Tier4[#Tier4 + 1] = v
			elseif v:IsHero() and v ~= caster then
				Tier1[#Tier1 + 1] = v
			else
				Tier2[#Tier2 + 1] = v
			end
		end
	end
	local castTarget = Tier1[math.random(#Tier1)] or Tier2[math.random(#Tier2)] or Tier3[math.random(#Tier3)] or
		Tier4[math.random(#Tier4)] or target
	multicast_casted_data[castTarget] = true
	CastAdditionalAbility(caster, ability, castTarget, delay, channelData)
	return multicast_casted_data
end

function CastMulticastedSpell(caster, ability, target, multicasts, multicast_type, multicast_flag_data,
							  multicast_casted_data, delay, channelData, prt, prtNumber)
	if multicasts >= 1 then
		Timers:CreateTimer(delay, function()
			ParticleManager:DestroyParticle(prt, true)
			ParticleManager:ReleaseParticleIndex(prt)
			prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf',
				PATTACH_OVERHEAD_FOLLOW, caster)
			ParticleManager:SetParticleControl(prt, 1, Vector(prtNumber, 0, 0))
			if multicast_type == MULTICAST_TYPE_SAME then
				CastAdditionalAbility(caster, ability, target, delay * (prtNumber - 1), channelData)
			else
				multicast_casted_data = CastMulticastedSpellInstantly(caster, ability, target, multicast_flag_data,
					multicast_casted_data, delay * (prtNumber - 1), channelData)
			end
			caster:EmitSound('Hero_OgreMagi.Fireblast.x' .. math.max(4, multicasts))
			if multicasts >= 2 then
				CastMulticastedSpell(caster, ability, target, multicasts - 1, multicast_type, multicast_flag_data,
					multicast_casted_data, delay, channelData, prt, prtNumber + 1)
			end
		end)
	else
		ParticleManager:DestroyParticle(prt, false)
		ParticleManager:ReleaseParticleIndex(prt)
	end
end

function CastAdditionalAbility(caster, ability, target, delay, channelData)
	local skill = ability
	local unit = caster
	local channelTime = ability:GetChannelTime() or 0
	if channelTime > 0 then
		if not caster.dummyCasters then
			caster.dummyCasters = {}
			caster.nextFreeDummyCaster = 1
			for i = 1, 8 do
				local dummy = CreateUnitByName("npc_dummy_caster", caster:GetAbsOrigin(), true, caster, caster,
					caster:GetTeamNumber())
				dummy:SetControllableByPlayer(caster:GetPlayerID(), true)
				dummy:AddNoDraw()
				dummy:MakeIllusion()
				table.insert(caster.dummyCasters, dummy)
			end
		end
		local dummy = caster.dummyCasters[caster.nextFreeDummyCaster]
		skill = nil
		caster.nextFreeDummyCaster = caster.nextFreeDummyCaster % #caster.dummyCasters + 1
		local abilityName = ability:GetName()
		for i = 0, DOTA_ITEM_SLOT_9 do
			local ditem = dummy:GetItemInSlot(i)
			if ditem then
				ditem:Destroy()
			end
			local citem = caster:GetItemInSlot(i)
			if citem then
				local newditem = dummy:AddItem(CopyItem(citem))
				if newditem:GetName() == abilityName then
					skill = newditem
				end
			end
		end
		dummy:SetOwner(caster)
		dummy:SetAbsOrigin(caster:GetAbsOrigin())
		dummy:SetBaseStrength(caster:GetStrength())
		dummy:SetBaseAgility(caster:GetAgility())
		dummy:SetBaseIntellect(caster:GetIntellect())
		for _, v in pairs(caster:FindAllModifiers()) do
			local buffName = v:GetName()
			local buffAbility = v:GetAbility()
			local dummyModifier = dummy:FindModifierByName(buffName) or
				dummy:AddNewModifier(dummy, buffAbility, buffName, nil)
			if dummyModifier then dummyModifier:SetStackCount(v:GetStackCount()) end
		end
		Illusions:_copyAbilities(caster, dummy)
		skill = skill or dummy:FindAbilityByName(ability:GetName())
		skill:SetLevel(ability:GetLevel())
		skill.GetCaster = function() return ability:GetCaster() end
		unit = dummy
	end
	if skill:HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
		if target and type(target) == "table" then
			unit:SetCursorCastTarget(target)
		end
	end
	if skill:HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT) then
		if target then
			if target.x and target.y and target.z then
				unit:SetCursorPosition(target)
			elseif target.GetOrigin then
				unit:SetCursorPosition(target:GetOrigin())
			end
		end
	end
	skill:OnSpellStart()
	if channelTime > 0 then
		if channelData.endTime then
			EndAdditionalAbilityChannel(caster, unit, skill, channelData.channelFailed,
				delay - GameRules:GetGameTime() + channelData.endTime)
		else
			caster:AddEndChannelListener(function(interrupted)
				EndAdditionalAbilityChannel(caster, unit, skill, interrupted, delay)
			end)
		end
	end
end

function EndAdditionalAbilityChannel(caster, unit, skill, interrupted, delay)
	Timers:CreateTimer(delay, function()
		FindClearSpaceForUnit(unit, caster:GetOrigin() - caster:GetForwardVector(), false)
		skill:EndChannel(interrupted)
		skill:OnChannelFinish(interrupted)
	end)
end

function GetAllAbilitiesCooldowns(unit)
	local cooldowns = {}
	for i = 0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability then
			table.insert(cooldowns, ability:GetReducedCooldown())
		end
	end
	return cooldowns
end

function RefreshAbilities(unit, tExceptions)
	for i = 0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and (not tExceptions or not tExceptions[ability:GetAbilityName()]) then
			ability:EndCooldown()
			ability:RefreshCharges()
			ability.ManaSpendCooldown = false
		end
	end
	local mod = unit:FindModifierByName("modifier_strength_crit")
	if mod then
		mod:Refresh()
	end
end

function RefreshItems(unit, tExceptions)
	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		local item = unit:GetItemInSlot(i)
		if item and (not tExceptions or not tExceptions[item:GetAbilityName()]) then
			item:EndCooldown()
			item.ManaSpendCooldown = false
		end
	end
	local teleport = unit:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
	if teleport then
		teleport:EndCooldown()
	end
end

function PerformGlobalAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile,
							 bFakeAttack, bNeverMiss, AttackFuncs)
	local abs = unit:GetAbsOrigin()
	unit:SetAbsOrigin(hTarget:GetAbsOrigin())
	SafePerformAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile,
		bFakeAttack, bNeverMiss, AttackFuncs)
	unit:SetAbsOrigin(abs)
end

function SafePerformAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile,
						   bFakeAttack, bNeverMiss, AttackFuncs)
	--bNoSplashesMelee, bNoSplashesRanged, bNoDoubleAttackMelee, bNoDoubleAttackRanged
	if AttackFuncs then
		if not unit.AttackFuncs then unit.AttackFuncs = {} end
		table.merge(unit.AttackFuncs, AttackFuncs)
	end
	unit:PerformAttack(hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile,
		bFakeAttack, bNeverMiss)
	unit.AttackFuncs = nil
end

function ColorTableToCss(color)
	return "rgb(" .. color[1] .. ',' .. color[2] .. ',' .. color[3] .. ')'
end

function FindAllOwnedUnits(playerId)
	local summons = {}
	local units = FindUnitsInRadius(PlayerResource:GetTeam(playerId), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE +
		DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, FIND_ANY_ORDER, false)
	for _, v in ipairs(units) do
		if (v.GetPlayerID and v:GetPlayerID() or v:GetPlayerOwnerID()) == playerId then
			if not (v:HasModifier("modifier_dummy_unit") or v:HasModifier("modifier_containers_shopkeeper_unit") or v:HasModifier("modifier_teleport_passive")) and v ~= hero then
				table.insert(summons, v)
			end
		end
	end
	return summons
end

function RemoveAllOwnedUnits(playerId)
	local player = PlayerResource:GetPlayer(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	RemoveDummyCasters(hero)
	for _, v in ipairs(FindAllOwnedUnits(playerId)) do
		if v ~= hero and not v:IsCourier() then
			v:ClearNetworkableEntityInfo()
			v:ForceKill(false)
			RemoveDummyCasters(v)
			UTIL_Remove(v)
		end
	end
end

function RemoveDummyCasters(unit)
	for _, dummyCaster in pairs(unit.dummyCasters or {}) do UTIL_Remove(dummyCaster) end
end

function GetTeamPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and not PlayerResource:IsPlayerAbandoned(i) and PlayerResource:GetTeam(i) == iTeam then
			counter = counter + 1
		end
	end
	return counter
end

function GetOneRemainingTeam()
	local teamLeft
	for i = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local count = GetTeamPlayerCount(i)
		if count > 0 then
			if teamLeft then
				return false
			else
				teamLeft = i
			end
		end
	end
	return teamLeft
end

function CopyItem(item)
	local newItem = CreateItem(item:GetAbilityName(), nil, nil)
	newItem:SetPurchaseTime(item:GetPurchaseTime())
	newItem:SetPurchaser(item:GetPurchaser())
	newItem:SetOwner(item:GetOwner())
	newItem:SetCurrentCharges(item:GetCurrentCharges())
	return newItem
end

function math.round(x)
	if x % 2 ~= 0.5 then
		return math.floor(x + 0.5)
	end
	return x - 0.5
end

function SafeHeal(unit, flAmount, hInflictor, overhead, table)
	if unit:IsAlive() then
		if hInflictor then
			--print(hInflictor:GetAbilityName()..", "..table.lifesteal)
		end
		if hInflictor and (
				table.lifesteal or
				table.spellLifesteal)
		then
			--print('no heal amp')
			hInflictor.NoHealAmp = true
		end
		unit:HealWithParams(flAmount,
			hInflictor,
			table.lifesteal or false,
			table.amplify or false,
			table.source or unit,
			table.spellLifesteal or false)

		if overhead then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, flAmount, nil)
		end
	end
end

function UnitVarToPlayerID(unitvar)
	if unitvar then
		if type(unitvar) == "number" then
			return unitvar
		elseif IsValidEntity(unitvar) then
			if unitvar.GetPlayerID and unitvar:GetPlayerID() > -1 then
				return unitvar:GetPlayerID()
			elseif unitvar.GetPlayerOwnerID then
				return unitvar:GetPlayerOwnerID()
			end
		end
	end
	return -1
end

function GetTrueItemCost(name)
	local cost = GetItemCost(name)
	if cost <= 0 then
		local tempItem = CreateItem(name, nil, nil)
		if not tempItem then
			print("[GetTrueItemCost] Warning: " .. name)
		elseif tempItem:IsItem() then
			cost = tempItem:GetCost()
			UTIL_Remove(tempItem)
		else
			print('[GetTrueItemCost] Warning: ' ..name .. ' is not an item')
			UTIL_Remove(tempItem)
		end
	end
	return cost
end

function GetNotScaledDamage(damage, unit)
	return damage / (1 + (unit:GetSpellAmplification(false) or 0))
end

function IsUltimateAbility(ability)
	return bit.band(ability:GetAbilityType(), 1) == 1
end

function IsUltimateAbilityKV(abilityname)
	return GetKeyValue(abilityname, "AbilityType") == "DOTA_ABILITY_TYPE_ULTIMATE"
end

function RandomPositionAroundPoint(pos, radius)
	return RotatePosition(pos, QAngle(0, RandomInt(0, 359), 0), pos + Vector(1, 1, 0) * RandomInt(0, radius))
end

function EvalString(str)
	return DebugCallFunction(loadstring(str))
end

function GetPlayersInTeam(team)
	local players = {}
	for playerId = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(playerId) and (not team or PlayerResource:GetTeam(playerId) == team) and not PLAYER_DATA[playerId].IsAbandoned then
			table.insert(players, playerId)
		end
	end
	return players
end

function RemoveAbilityWithModifiers(unit, ability)
	for _, v in ipairs(unit:FindAllModifiers()) do
		if v:GetAbility() == ability then
			v:Destroy()
		end
	end
	if ability.DestroyHookParticles then
		ability:DestroyHookParticles()
	end
	unit:RemoveAbility(ability:GetAbilityName())
end

function CreateGlobalParticle(name, callback, pattach)
	local ps = {}
	for team = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local f = FindFountain(team)
		if f then
			local p = ParticleManager:CreateParticleForTeam(name, pattach or PATTACH_WORLDORIGIN, f, team)
			if callback then callback(p) end
			table.insert(ps, p)
		end
	end
	return ps
end

function WorldPosToMinimap(vec)
	local pct1 = (vec.x + MAP_LENGTH) / (MAP_LENGTH * 2)
	local pct2 = (MAP_LENGTH - vec.y) / (MAP_LENGTH * 2)
	return pct1 * 100 .. "% " .. pct2 * 100 .. "%"
end

function GetHeroTableByName(name)
	local output = {}
	local custom = NPC_HEROES_CUSTOM[name]
	if not custom then
		print("[GetHeroTableByName] Missing hero: " .. name)
		return
	end
	if custom.base_hero then
		table.merge(output, GetUnitKV(custom.base_hero))
		for i = 1, 24 do
			output["Ability" .. i] = nil
		end
		table.merge(output, custom)
	else
		table.merge(output, GetUnitKV(name))
	end
	return output
end

function IsInBox(point, point1, point2)
	return point.x > point1.x and point.y > point1.y and point.x < point2.x and point.y < point2.y
end

function IsInTriggerBox(trigger, extension, vector)
	local origin = trigger:GetAbsOrigin()
	return IsInBox(
		vector,
		origin + ExpandVector(trigger:GetBoundingMins(), extension),
		origin + ExpandVector(trigger:GetBoundingMaxs(), extension)
	)
end

function GetConnectionState(playerId)
	return PlayerResource:IsFakeClient(playerId) and DOTA_CONNECTION_STATE_CONNECTED or
		PlayerResource:GetConnectionState(playerId)
end

function DebugCallFunction(fun)
	--print("debug")
	local status, nextCall = xpcall(fun, function(msg)
		return msg .. '\n' .. debug.traceback() .. '\n'
	end)
	if not status then
		Timers:HandleEventError(nil, nil, nextCall)
	end
end

function GetInGamePlayerCount()
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			counter = counter + 1
		end
	end
	return counter
end

function GetTeamAllPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			if PlayerResource:GetTeam(i) == iTeam then
				counter = counter + 1
			end
		end
	end
	return counter
end

function RecreateAbility(unit, ability)
	local name = ability:GetAbilityName()
	local level = ability:GetLevel()
	RemoveAbilityWithModifiers(unit, ability)
	ability = unit:AddNewAbility(name, true)
	if ability then
		ability:SetLevel(level)
	end
	return ability
end

function CDOTA_Buff:SetSharedKey(key, value)
	local t = CustomNetTables:GetTableValue("shared_modifiers",
		self:GetParent():GetEntityIndex() .. "_" .. self:GetName()) or {}
	t[key] = value
	CustomNetTables:SetTableValue("shared_modifiers", self:GetParent():GetEntityIndex() .. "_" .. self:GetName(), t)
end

--By Noya, from DotaCraft
function GetPreMitigationDamage(value, victim, attacker, damagetype)
	if damagetype == DAMAGE_TYPE_PHYSICAL then
		local armor = victim:GetPhysicalArmorValue(false)
		local reduction = ((armor) * 0.06) / (1 + 0.06 * (armor))
		local damage = value / (1 - reduction)
		return damage, reduction
	elseif damagetype == DAMAGE_TYPE_MAGICAL then
		local reduction = victim:Script_GetMagicalArmorValue(false, nil) * 0.01
		local damage = value / (1 - reduction)

		return damage, reduction
	else
		return value, 0
	end
end

function SimpleDamageReflect(victim, attacker, damage, flags, ability, damage_type)
	if --[[victim:IsAlive() and]] not HasDamageFlag(flags, DOTA_DAMAGE_FLAG_REFLECTION) and attacker:GetTeamNumber() ~= victim:GetTeamNumber() then
		--print("Reflected " .. damage .. " damage from " .. victim:GetUnitName() .. " to " .. attacker:GetUnitName())

		ApplyDamage({
			victim = attacker,
			attacker = victim,
			damage = damage,
			damage_type = damage_type,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION,
			ability = ability
		})
		return true
	end
	return false
end

function IsModifierStrongest(unit, modifier, modifierList)
	local ind = modifierList[modifier]
	if not ind then return false end
	for v, i in pairs(modifierList) do
		if unit:HasModifier(v) and i > ind then
			return false
		end
	end
	return true
end

function pluralize(n, one, many)
	return n == 1 and one or (many or one .. "s")
end

function RemoveAllUnitsByName(name)
	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for _, v in ipairs(units) do
		if v:GetUnitName():match(name) then
			v:ClearNetworkableEntityInfo()
			v:ForceKill(false)
			UTIL_Remove(v)
		end
	end
end

function AnyUnitHasModifier(name, caster)
	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for _, v in ipairs(units) do
		if v:FindModifierByNameAndCaster(name, caster) then
			return true
		end
	end
	return false
end

function ExpandVector(vec, by)
	return Vector(
		(math.abs(vec.x) + by) * math.sign(vec.x),
		(math.abs(vec.y) + by) * math.sign(vec.y),
		(math.abs(vec.z) + by) * math.sign(vec.z)
	)
end

function VectorOnBoxPerimeter(vec, min, max)
	local l, r, b, t = min.x, max.x, min.y, max.y
	local x, y = math.clamp(vec.x, l, r), math.clamp(vec.y, b, t)

	local dl, dr, db, dt = math.abs(x - l), math.abs(x - r), math.abs(y - b), math.abs(y - t)
	local m = math.min(dl, dr, db, dt)

	if m == dl then return Vector(l, y) end
	if m == dr then return Vector(r, y) end
	if m == db then return Vector(x, b) end
	if m == dt then return Vector(x, t) end
end

function CalculateBaseArmor(agility)
	return agility * AGILITY_ARMOR_BASE_COEFF
end

function __toFixed(num, x)
	local multiplier = math.pow(10, x)
	--print(math.floor(num * multiplier) / multiplier)
	return math.ceil(num * multiplier) / multiplier
end

function DamageSubtypes(inflictor, victim, damage)
	if inflictor and inflictor:GetKeyValue("AbilityUnitDamageSubType") then
		local subtype = inflictor:GetKeyValue("AbilityUnitDamageSubType")
		if victim and victim:GetKeyValue("DamageSubtypeResistance") then
			local resist = victim:GetKeyValue("DamageSubtypeResistance")
			if resist[subtype] and not victim:IsHexed() then
				if resist[subtype] > 100 then resist[subtype] = 100 end
				damage = damage - damage * resist[subtype] * 0.01
			elseif subtype == "DAMAGE_SUBTYPE_POISON" then
				damage = damage - damage * -25 * 0.01
			elseif subtype == "DAMAGE_SUBTYPE_SPACE" then
				damage = damage - damage * -25 * 0.01
			end
		elseif victim and subtype == "DAMAGE_SUBTYPE_POISON" then
			damage = damage - damage * -25 * 0.01
		elseif victim and subtype == "DAMAGE_SUBTYPE_SPACE" then
			damage = damage - damage * -25 * 0.01
		end
	end

	return damage
end

function extended(child, parent)
	setmetatable(child, { __index = parent })
end

function CalculateStatPerLevel(parent, stat, level_limit, start_attribute)
	local stat_per_level = 0
	if stat == DOTA_ATTRIBUTE_STRENGTH then
		if parent.CustomGain_Strength then
			if parent:GetLevel() <= level_limit then
				stat_per_level = (parent:GetLevel() - 1) * parent.CustomGain_Strength
			else
				stat_per_level = level_limit * parent.CustomGain_Strength
			end
		else
			if parent:GetLevel() <= level_limit then
				stat_per_level = (parent:GetLevel() - 1) * (parent:GetStrengthGain() or 0)
			else
				stat_per_level = level_limit * (parent:GetStrengthGain() or 0)
			end
		end
		return math.min(parent:GetBaseStrength(), stat_per_level +
			(start_attribute and (NPC_HEROES_CUSTOM[parent:GetFullName()] and NPC_HEROES_CUSTOM[parent:GetFullName()].AttributeBaseStrength or parent:GetKeyValue("AttributeBaseStrength") or 16) or 0))
	end
	if stat == DOTA_ATTRIBUTE_AGILITY then
		if parent.CustomGain_Agility then
			if parent:GetLevel() <= level_limit then
				stat_per_level = (parent:GetLevel() - 1) * parent.CustomGain_Agility
			else
				stat_per_level = level_limit * parent.CustomGain_Agility
			end
		else
			if parent:GetLevel() <= level_limit then
				stat_per_level = (parent:GetLevel() - 1) * (parent:GetAgilityGain() or 0)
			else
				stat_per_level = level_limit * (parent:GetAgilityGain() or 0)
			end
		end
		return math.min(parent:GetBaseAgility(), stat_per_level +
			(start_attribute and (NPC_HEROES_CUSTOM[parent:GetFullName()] and NPC_HEROES_CUSTOM[parent:GetFullName()].AttributeBaseAgility or parent:GetKeyValue("AttributeBaseAgility") or 16) or 0))
	end
	if stat == DOTA_ATTRIBUTE_INTELLECT then
		if parent.CustomGain_Intelligence then
			if parent:GetLevel() <= level_limit then
				stat_per_level = (parent:GetLevel() - 1) * parent.CustomGain_Intelligence
			else
				stat_per_level = level_limit * parent.CustomGain_Intelligence
			end
		else
			if parent:GetLevel() <= level_limit then
				stat_per_level = (parent:GetLevel() - 1) * (parent:GetIntellectGain() or 0)
			else
				stat_per_level = level_limit * (parent:GetIntellectGain() or 0)
			end
		end
		return math.min(parent:GetBaseIntellect(), stat_per_level +
			(start_attribute and (NPC_HEROES_CUSTOM[parent:GetFullName()] and NPC_HEROES_CUSTOM[parent:GetFullName()].AttributeBaseIntelligence or parent:GetKeyValue("AttributeBaseIntelligence") or 16) or 0))
	end
	if stat == 3 then
		local str_per_level
		local agi_per_level
		local int_per_level
		if parent.CustomGain_Strength then
			if parent:GetLevel() <= level_limit then
				str_per_level = (parent:GetLevel() - 1) * parent.CustomGain_Strength
			else
				str_per_level = level_limit * parent.CustomGain_Strength
			end
		else
			if parent:GetLevel() <= level_limit then
				str_per_level = (parent:GetLevel() - 1) * (parent:GetStrengthGain() or 0)
			else
				str_per_level = level_limit * (parent:GetStrengthGain() or 0)
			end
		end

		if parent.CustomGain_Agility then
			if parent:GetLevel() <= level_limit then
				agi_per_level = (parent:GetLevel() - 1) * parent.CustomGain_Agility
			else
				agi_per_level = level_limit * parent.CustomGain_Agility
			end
		else
			if parent:GetLevel() <= level_limit then
				agi_per_level = (parent:GetLevel() - 1) * (parent:GetAgilityGain() or 0)
			else
				agi_per_level = level_limit * (parent:GetAgilityGain() or 0)
			end
		end

		if parent.CustomGain_Intelligence then
			if parent:GetLevel() <= level_limit then
				int_per_level = (parent:GetLevel() - 1) * parent.CustomGain_Intelligence
			else
				int_per_level = level_limit * parent.CustomGain_Intelligence
			end
		else
			if parent:GetLevel() <= level_limit then
				int_per_level = (parent:GetLevel() - 1) * (parent:GetIntellectGain() or 0)
			else
				int_per_level = level_limit * (parent:GetIntellectGain() or 0)
			end
		end
		return math.min(parent:GetBaseStrength() + parent:GetBaseAgility() + parent:GetBaseStrength(),
			(str_per_level + agi_per_level + int_per_level) * DAMAGE_PER_ATTRIBUTE_FOR_UNIVERSALES)
	end
end

function NeedSpellAmpCondition(inflictor, inflictorname, attacker, damage_flags)
	return inflictor and attacker.DamageMultiplier and not SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] and
		inflictorname ~= "necrolyte_heartstopper_aura" and not inflictor.NoDamageAmp and
		not HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) and
		not HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION)
end

function DamageAmpCondition(inflictor, unit)
	return (not inflictor or ((IsValidEntity(inflictor) and inflictor.GetAbilityName) and NeedSpellAmpCondition --[[(inflictor, inflictor:GetAbilityName(), unit)]]))
end

function StaminaThreshouldForDebuff(stamina)
	return stamina:GetStackCount() <= STAMINA_THRESHOLD_FOR_DEBUFF
end

function CalculateAttackDamage(attacker, victim, original_damage)
	if not attacker.DamageMultiplier then return 0 end
	if not original_damage then return attacker.calculated_attack_damage end
	local attack_damage = attacker:GetAverageTrueAttackDamage(victim)
	return attacker.calculated_attack_damage * (original_damage / attack_damage)
end

function DamageHasInflictor(inflictor, damage, attacker, victim, damagetype_const, damage_flags, original_damage)
	local inflictorname = inflictor:GetAbilityName()

	if (SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] or inflictor.NoDamageAmp) and not ATTACK_DAMAGE_ABILITIES[inflictorname] and attacker:IsHero() and not HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) then
		damage = GetNotScaledDamage(damage, attacker)
	end

	local increased_damage = 0
	local function AddIncreasedDamage(value)
		if attacker.DamageMultiplier > SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD then
			increased_damage = value * (attacker.DamageMultiplier - SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD)
			-- print('increased_damage: '..increased_damage)
		end
	end
	if type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) == "string" then
		local value = inflictor:GetSpecialValueFor(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname])
		local spellamp = 1 + (attacker:GetSpellAmplification(false) or 0)
		AddIncreasedDamage(value * spellamp)
		local mult = spellamp * attacker.DamageMultiplier
		-- print(mult)
		damage = damage + value * mult
	elseif NeedSpellAmpCondition(inflictor, inflictorname, attacker, damage_flags) then
		AddIncreasedDamage(damage)
		damage = damage * attacker.DamageMultiplier
	end

	if ATTACK_DAMAGE_ABILITIES[inflictorname] then
		damage = damage + CalculateAttackDamage(attacker, victim, original_damage)
	end

	local jungle_bears_damage_mult = inflictor:GetSpecialValueFor("jungle_bears_damage_multiplier")
	-- print('jungle_bears_damage_mult, ' .. jungle_bears_damage_mult)
	if victim and jungle_bears_damage_mult > 0 and victim:IsJungleBear() then
		if string.starts(inflictorname, "item_essential_orb_fire_") and (attacker:GetPrimaryAttribute() ~= 2 or not attacker.bonus_primary_attribute2) then
		else
			inflictor.jungle_bears_damage_mult = jungle_bears_damage_mult
			damage = damage * jungle_bears_damage_mult
		end
	end

	if IsValidEntity(inflictor.originalInflictor) then
		inflictorname = inflictor.originalInflictor:GetAbilityName()
	end
	if (inflictor:GetSpecialValueFor("damage_to_arena_boss") > 0 or BOSS_DAMAGE_ABILITY_MODIFIERS[inflictorname]) and victim:IsBoss() then
		damage = damage *
			(inflictor:GetSpecialValueFor("damage_to_arena_boss") or BOSS_DAMAGE_ABILITY_MODIFIERS[inflictorname]) * 0.01
	end

	-- local condition_helper = function()
	-- 	return attacker.DamageMultiplier > SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD and
	-- 		inflictor.GetManaCost and
	-- 		inflictor:GetManaCost(inflictor:GetLevel()) > 0 and
	-- 		inflictor.GetCooldown and
	-- 		inflictor:GetCooldown(inflictor:GetLevel()) > 0
	-- end

	local function GetDecreaseDamageMult()
		return GetLowManaMultiplier(attacker.DamageMultiplier, attacker,
			SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD,
			SPEND_MANA_PER_DAMAGE_MAX_REDUCE_THRESHOLD)
	end

	if attacker:IsTrueHero() and victim:GetTeamNumber() ~= attacker:GetTeamNumber() and
		attacker:GetFullName() ~= "npc_arena_hero_comic_sans" and
		attacker:GetFullName() ~= "npc_arena_hero_sara" then
		if attacker.DamageMultiplier > SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD and
			inflictor.GetManaCost and
			inflictor:GetManaCost(inflictor:GetLevel()) > 0 and
			inflictor.GetCooldown and
			inflictor:GetCooldown(inflictor:GetLevel()) > 0
		then
			local interval_mult = GetIntervalMult(inflictor, "_damageInterval")
			-- if (SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] or MANA_SPEND_SPELLS_EXEPTIONS[inflictorname]) and not ATTACK_DAMAGE_ABILITIES[inflictorname] then
			-- end
			if not ATTACK_DAMAGE_ABILITIES[inflictorname] and
				NeedSpellAmpCondition(inflictor, inflictorname, attacker, damage_flags)
			then
				damage = damage * GetDecreaseDamageMult()
				SpendManaPerDamage(attacker, inflictor, increased_damage, interval_mult, "ManaSpendCooldown",
					SPEND_MANA_PER_DAMAGE)
			end
			if (SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] and type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) == "string") then
				damage = damage * GetDecreaseDamageMult()
				SpendManaPerDamage(attacker, inflictor, increased_damage, interval_mult, "ManaSpendCooldown",
					SPEND_MANA_PER_DAMAGE)
			end
		end
	end
	return damage
end

function SpendManaPerDamage(unit, inflictor, increased_value, interval_mult, key, spend)
	local inflictorname = inflictor:GetAbilityName()
	if not inflictorname then return end
	local exeption = MANA_SPEND_SPELLS_EXEPTIONS[inflictorname] or 0
	local mana_spend = (increased_value * spend * 0.01 *
		(type(exeption) == 'number' and 1 - exeption * 0.01 or 0)) / interval_mult

	if not inflictor[key] then
		unit:SpendMana(mana_spend, inflictor)
		Attributes:UpdateSpellDamage(unit)
		inflictor[key] = true
		Timers:CreateTimer(1, function()
			inflictor[key] = false
		end)
	end
end

function GetIntervalMult(inflictor, key)
	local mult = 1
	local inflictorname = inflictor:GetAbilityName()
	if not inflictorname then return 1 end
	local time = GameRules:GetDOTATime(true, true)
	if not MANA_SPEND_SPELLS_EXEPTIONS[inflictorname] and inflictor[key] and math.abs(inflictor[key] - time) < 1 then
		mult = math.abs(inflictor[key] - time)
	end
	inflictor[key] = time
	return mult
end

function GetLowManaMultiplier(mult, attacker, startMult, maxMult)
	if (mult or 1) > startMult then
		local mana_mult = 1 - (attacker:GetMana() / attacker:GetMaxMana())
		mult = math.min(1, (attacker.DamageMultiplier - startMult) / (maxMult - startMult))
		return 1 - (mana_mult * mult)
	else
		return 1
	end
end

function ExtractMultiplier(value1, value2)
	return value2 / value1
end

function ProcessDamageModifier(v, attacker, victim, inflictor, damage_, damagetype_const, damage_flags, original_damage)
	local multiplier
	if type(v) == "function" then
		multiplier = v(attacker, victim, inflictor, damage_, damagetype_const, damage_flags)
	elseif type(v) == "table" then
		if v.multiplier then
			if type(v.multiplier) == "function" then
				multiplier = v.multiplier(attacker, victim, inflictor, damage_, damagetype_const, damage_flags)
			else
				multiplier = v.multiplier
			end
		elseif v.addictive_multiplier then
		else
			multiplier = v
		end
	end
	if multiplier ~= nil then
		if type(multiplier) == "table" then
			if type(multiplier.reject) == "boolean" and not multiplier.reject then
				damage_ = 0
				return 0
			end
			if multiplier.BlockedDamage then
				BlockedDamage = math.max(BlockedDamage, multiplier.BlockedDamage)
			end
			if multiplier.damage then
				if type(multiplier.damage) == "function" then
					local _damage = multiplier.damage(attacker, victim, inflictor, damage_, damagetype_const,
						damage_flags)
					if _damage then
						damage_ = _damage
						return damage_
					end
				else
					damage_ = multiplier.damage
					return damage_
				end
			end
			if multiplier.multiplier then
				multiplier = multiplier.multiplier
			end
		end
		if type(multiplier) == "boolean" and not multiplier then
			damage_ = 0
			return 0
		elseif type(multiplier) == "number" then
			damage_ = damage_ * multiplier
		end
	end
	return damage_
end

function SplashTimer(parent, usedAbility)
	if parent:HasModifier("modifier_item_ultimate_splash") or parent:HasModifier("modifier_item_splitshot_ultimate") or parent:HasModifier("modifier_item_elemental_fury") then return end
	local name = usedAbility:GetAbilityName()

	if ABILITIES_TRIGGERS_ATTACKS[name] then
		local v = ABILITIES_TRIGGERS_ATTACKS[name]
		local duration
		if type(v) == "number" then
			duration = v
		else
			duration = (GetKeyValue(name, "AbilityCastPoint", usedAbility:GetLevel()) or 0) +
				(GetKeyValue(name, "AbilityChannelTime", usedAbility:GetLevel()) or 0) + 0.2
		end
		--print(duration)
		parent:AddNewModifier(parent, nil, "modifier_splash_timer", { duration = duration })
	end
end

function GetPlayersCountMultiplier()
	return 0.8 + math.max(1, Teams:GetPlayersCountInLobby() - 1) * 0.2
end

function GetGoldMultiplier(val)
	local hero
	local playerID
	if type(val) ~= "table" then
		playerID = val
		hero = PlayerResource:GetSelectedHeroEntity(val)
	else
		hero = val
		playerID = hero and hero:GetPlayerOwnerID() or nil
	end
	return hero and
		((1 + math.min(10, Kills:GetDeathStreak(playerID) or 0) * 0.15) + ((hero.bonus_gold_pct or 0) * 0.01) * (IsPlayerInBlackList(playerID) and 0.75 or 1)) or
		1
end

function InitHero(parent)
	parent._splash = 0
	parent._splitshot = 0

	parent:SetNetworkableEntityInfo("IntellectPrimaryBonusMultiplier", INTELLECT_PRIMARY_BONUS_MAX_BONUS)
	parent:SetNetworkableEntityInfo("IntellectPrimaryBonusDifference", INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT)

	parent:SetNetworkableEntityInfo("AttributeAgilityGain",
		parent:GetNetworkableEntityInfo("AttributeAgilityGain") or parent:GetAgilityGain())
	parent:SetNetworkableEntityInfo("AttributeStrengthGain",
		parent:GetNetworkableEntityInfo("AttributeStrengthGain") or parent:GetStrengthGain())
	parent:SetNetworkableEntityInfo("AttributeIntelligenceGain",
		parent:GetNetworkableEntityInfo("AttributeIntelligenceGain") or parent:GetIntellectGain())
	parent:SetNetworkableEntityInfo("unit_name", parent:GetFullName())

	parent:SetNetworkableEntityInfo("BaseAttackTime", parent.Custom_AttackRate or parent:GetKeyValue("AttackRate"))

	if UNITS_LIST[parent:GetFullName()] and UNITS_LIST[parent:GetFullName()].DamageSubtypeResistance then
		parent:SetNetworkableEntityInfo("DamageSubtypesResistance",
			UNITS_LIST[parent:GetFullName()].DamageSubtypeResistance)
	end

	parent:SetNetworkableEntityInfo("BaseDamagePerStr", 0)
	parent:SetNetworkableEntityInfo("BaseDamagePerAgi", 0)
	parent:SetNetworkableEntityInfo("BaseDamagePerInt", 0)

	parent.HpRegenAmp = STRENGTH_REGEN_AMPLIFY
	parent.BaseDamagePerStrength = 1
	parent.AgilityArmorMultiplier = AGILITY_ARMOR_MULTIPLIER
	parent.ManaRegAmpPerInt = MANA_REGEN_AMPLIFY
	parent.HealthPerStrength = BASE_HP_PER_STRENGTH
	parent.ManaPerInt = BASE_MANA_PER_INT

	parent.Additional_str = parent.Additional_str or 0
	parent.Additional_agi = parent.Additional_agi or 0
	parent.Additional_int = parent.Additional_int or 0

	parent.outside_change_bat = 0
	parent.change_bat_modifiers = {}
	parent.custom_base_attack_time = parent.Custom_AttackRate or parent:GetKeyValue("AttackRate")

	parent.bonus_gold_pct = 0
	parent.decrease_stamina_cost_mult = 1

	if parent:GetFullName() == "npc_arena_hero_comic_sans" then
		parent.HpRegenAmp = 0
		parent.ManaRegAmpPerInt = 0
		parent.HealthPerStrength = 0
		parent.ManaPerInt = 0
		parent:SetNetworkableEntityInfo("HealthPerStrength", 0)
		parent:SetNetworkableEntityInfo("ManaPerInt", 0)
		parent:SetNetworkableEntityInfo("HpRegenAmp", 0)
		parent:SetNetworkableEntityInfo("ManaRegAmpPerInt", 0)
	end

	if parent.ArenaHero then
		parent:SetNetworkableEntityInfo("PrimaryAttribute",
			tostring(_G[NPC_HEROES_CUSTOM[parent:GetFullName()]["AttributePrimary"]]))
		return
	end

	parent:SetNetworkableEntityInfo("PrimaryAttribute", tostring(parent:GetPrimaryAttribute()))

	parent:SetCustomDeathXP(0)
end

function ApplyInevitableDamage(attacker, victim, ability, damage, lethal, noOverhead)
	if not lethal then lethal = false end
	if victim:IsBoss() then
		ApplyDamage({
			victim = victim,
			attacker = attacker,
			damage = damage,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_HPLOSS,
			ability = ability
		})
	else
		victim:ModifyHealth(
			victim:GetHealth() - damage,
			ability,
			lethal,
			0)
		if lethal and victim:GetHealth() == 1 then
			victim:TrueKill(ability, attacker)
		end
		-- print(victim == attacker)
		if not noOverhead and attacker ~= victim then CreateDamageOverHead(attacker, victim, damage) end
	end
end

function CreateDamageOverHead(attacker, victim, damage)
	if attacker == victim then return end
	if victim:GetPlayerOwner() then
		SendOverheadEventMessage(victim:GetPlayerOwner(), OVERHEAD_ALERT_INCOMING_DAMAGE, victim, math.round(damage),
			victim:GetPlayerOwner())
	end
	if not attacker or not attacker:GetPlayerOwner() then return end
	SendOverheadEventMessage(attacker:GetPlayerOwner(), OVERHEAD_ALERT_OUTGOING_DAMAGE, victim, math.round(damage),
		attacker:GetPlayerOwner())
end

function DropInfinityGauntlet(parent)
	local gauntlet = FindItemInInventoryByName(parent, "item_infinity_gauntlet", false, false, false, true)

	if gauntlet then
		if #gauntlet.infinity_stones > 0 then
			gauntlet:RemoveModifiers()
		end
		gauntlet:DropStones()
		gauntlet:EndCooldown()
		gauntlet:SetNetworkableEntityInfo("completed", 0)
		parent:DropItemAtPositionImmediate(gauntlet, parent:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
	end
end

function ReloadUnitModifiers(unit)
	local modifiers = unit:FindAllModifiers()
	for k, v in pairs(modifiers) do
		if v:GetRemainingTime() <= -1 then
			local ability = v:GetAbility()
			local name = v:GetName()
			local stacks = v:GetStackCount()
			local caster = v:GetCaster()
			local parent = v:GetParent()

			local exeptions = {
				modifier_arena_hero_health_regen = true,
				modifier_arena_hero_mana_regen = true,
				modifier_arena_hero_max_mana = true,
				modifier_arena_hero_current_mana = true,
				modifier_arena_hero_gold = true,
			}

			unit:RemoveModifierByName(v:GetName())

			if not exeptions[name] then
				local mod = parent:AddNewModifier(caster, ability, name, {})
				if not mod then
					mod = ability:ApplyDataDrivenModifier(caster, parent, name, {})
				end
				if mod then
					mod:SetStackCount(stacks)
				end
			end
		end
	end
end

function CalculatePhysicalResist(unit, armor)
	-- local total_armor = unit:GetPhysicalArmorValue(false)
	-- local function formula(a)
	return (0.06 * armor) / (1 + 0.06 * math.abs(armor))
	-- end
	-- armor = ((armor > 0 and armor > total_armor) or (armor < 0 and armor < total_armor)) and total_armor or armor
	-- local total_armor_mult = formula(total_armor)
	-- local diff = (armor / total_armor)
	-- return total_armor_mult * diff
end

function GetSpellCrit(mult)
	return mult / STRENGTH_CRIT_SPELL_CRIT_DECREASRE_MULT
end

function GetTeamNetworth(team)

end

function ReconnectFix(playerId)
	-- if HeroSelection:GetState() == HERO_SELECTION_PHASE_END then
	print('reconnect fix')
	PlayerTables:PlayerTables_Connected({
		pid = playerId
	})
	StatsClient:AddGuide(nil)
	-- end
end

function GenerateDamageMultiplier(fixedDamage, totalDamage, mult)
	return ((fixedDamage * mult) + totalDamage) / totalDamage
end

function OutgoingDamageModifiers(attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage)
	local multiplier = 1
	local function action(key)
		if multiplier == 0 then return 0 end
		if attacker:HasModifier(key) then
			local data = OUTGOING_DAMAGE_MODIFIERS[key]
			if (type(data) ~= "table" or not data.condition or (data.condition and data.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage))) then
				multiplier = multiplier * ExtractMultiplier(
					damage,
					ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const, damage_flags,
						saved_damage))
			end
		end
	end
	action("modifier_item_desolator6_arena")
	action("modifier_sans_curse_passive")
	action("modifier_anakim_wisps")
	action("modifier_kadash_strike_from_shadows")
	action("modifier_intelligence_primary_bonus")
	action("modifier_mind_stone")
	action("modifier_freya_frozen_strike_crit")
	action("modifier_strength_crit")


	-- if attacker.OUTGOING_DAMAGE_MODIFIERS then
	-- 	for key, v in pairs(attacker.OUTGOING_DAMAGE_MODIFIERS) do
	-- 		if multiplier == 0 then return 0 end
	-- 		if attacker:HasModifier(key) then
	-- 			local data = OUTGOING_DAMAGE_MODIFIERS[key]
	-- 			if (type(data) ~= "table" or not data.condition or (data.condition and data.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags, saved_damage))) then
	-- 				multiplier = multiplier * ExtractMultiplier(
	-- 					damage,
	-- 					ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const, damage_flags,
	-- 						saved_damage))
	-- 			end
	-- 		else
	-- 			attacker.OUTGOING_DAMAGE_MODIFIERS[key] = nil
	-- 		end
	-- 	end
	-- end


	return multiplier
end

function IncomingDamageModifiers(attacker, victim, inflictor, damage, damagetype_const, damage_flags)
	local function action(key)
		if damage == 0 then return 0 end
		if victim:HasModifier(key) then
			local data = INCOMING_DAMAGE_MODIFIERS[key]
			if (type(data) ~= "table" or not data.condition or (data.condition and data.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags))) then
				damage = ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const,
					damage_flags,
					saved_damage)
			end
		end
	end

	action("modifier_sans_dodger")
	action("modifier_item_timelords_butterfly")
	action("modifier_mirratie_sixth_sense")
	action("modifier_saber_instinct")
	action("modifier_item_pipe_of_enlightenment_team_buff")
	action("modifier_mana_shield_arena")
	action("modifier_anakim_transfer_pain")
	action("modifier_item_behelit_buff")
	action("modifier_item_titanium_bar_active")
	action("modifier_item_blade_mail_reflect")
	action("modifier_item_sacred_blade_mail_active")
	action("modifier_intelligence_primary_bonus")
	action("modififer_sara_conceptual_reflection")

	-- if victim.INCOMING_DAMAGE_MODIFIERS then
	-- 	for key, v in pairs(victim.INCOMING_DAMAGE_MODIFIERS) do
	-- 		if damage == 0 then return 0 end
	-- 		if victim:HasModifier(key) then
	-- 			local data = INCOMING_DAMAGE_MODIFIERS[key]
	-- 			if (type(data) ~= "table" or not data.condition or (data.condition and data.condition(attacker, victim, inflictor, damage, damagetype_const, damage_flags))) then
	-- 				damage = ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const,
	-- 					damage_flags,
	-- 					saved_damage)
	-- 			end
	-- 		else
	-- 			victim.INCOMING_DAMAGE_MODIFIERS[key] = nil
	-- 		end
	-- 	end
	-- end


	return damage
end

function OnDamageModifierProcsVictim(attacker, victim, inflictor, damage, damagetype_const,
									 damage_flags, saved_damage)
	local function action(key)
		if victim:HasModifier(key) then
			local data = ON_DAMAGE_MODIFIER_PROCS_VICTIM[key]
			damage = ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const,
				damage_flags,
				saved_damage)
		end
	end

	action("modifier_item_holy_knight_shield")

	-- if victim.ON_DAMAGE_MODIFIER_PROCS_VICTIM then
	-- 	for key, v in pairs(victim.ON_DAMAGE_MODIFIER_PROCS_VICTIM) do
	-- 		if victim:HasModifier(key) then
	-- 			local data = ON_DAMAGE_MODIFIER_PROCS_VICTIM[key]
	-- 			damage = ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const,
	-- 				damage_flags,
	-- 				saved_damage)
	-- 		else
	-- 			victim.ON_DAMAGE_MODIFIER_PROCS_VICTIM[key] = nil
	-- 		end
	-- 	end
	-- end
end

function OnDamageModifierProcs(attacker, victim, inflictor, damage, damagetype_const, damage_flags,
							   saved_damage)
	local function action(k)
		if attacker:HasModifier(k) then
			local data = ON_DAMAGE_MODIFIER_PROCS[k]
			ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const, damage_flags,
				saved_damage)
		end
	end

	action("modifier_item_octarine_core_arena")
	action("modifier_item_refresher_core")
	action("modifier_item_golden_eagle_relic")
	action("modifier_talent_lifesteal")
	action("modifier_shinobu_vampire_blood")
	-- if attacker.ON_DAMAGE_MODIFIER_PROCS then
	-- 	for k, v in pairs(attacker.ON_DAMAGE_MODIFIER_PROCS) do
	-- 		if attacker:HasModifier(k) then
	-- 			local data = ON_DAMAGE_MODIFIER_PROCS[k]
	-- 			ProcessDamageModifier(data, attacker, victim, inflictor, damage, damagetype_const, damage_flags,
	-- 				saved_damage)
	-- 		else
	-- 			attacker.ON_DAMAGE_MODIFIER_PROCS[k] = nil
	-- 		end
	-- 	end
	-- end
end

function IsPlayerInBlackList(PlayerID)
	return false --BLACK_LIST[PlayerResource:GetRealSteamID(PlayerID)]
end

function UpdateIntellgencePrimaryBonus(mod, stacks, hero)
	mod:SetStackCount(stacks)
	Attributes:UpdateSpellDamage(hero)
	if mod.timer then Timers:RemoveTimer(mod.timer) end
	if stacks == 0 then return end
	mod.timer = Timers:CreateTimer(5, function()
		mod:SetStackCount(0)
		Attributes:UpdateSpellDamage(hero)
	end)
end

function UpgradeSummons(npc)
	local npcName = npc:GetFullName()
	if npcName == "npc_shinobu_soul" or npcName == "npc_dota_lucifers_claw_doomling" then return end
	if (npc:IsControllableByAnyPlayer() or npcName == "npc_dota_unit_undying_zombie") and not npc:IsHero() and not (npc:IsIllusion() or npc:IsStrongIllusion()) and not npc:HasInventory() then
		print(npcName)
		local hero = PlayerResource:GetSelectedHeroEntity(npc:GetPlayerOwnerID())

		local strength_crit = hero:FindModifierByName("modifier_strength_crit")

		if strength_crit and strength_crit.ready and npcName ~= "npc_dota_unit_undying_tombstone" then
			Timers:CreateTimer(0.05, function()
				strength_crit:cancel(hero)
			end)
			ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf",
				PATTACH_ABSORIGIN, npc)
			npc:EmitSound("Arena.Items.Behelit.Buff")
			npc:SetModelScale((unit:GetModelScale() or 1) * 1.25)
		end

		local mult = (1 + Attributes:UpdateSpellDamage(hero) * 0.01) + (hero:GetSpellAmplification(false))
		-- print('mult, ' .. mult)
		local attack_speed = math.floor(npc:GetAttackSpeed(false) * 100 * (mult - 1))
		if --npcName ~= "npc_dota_witch_doctor_death_ward" and npcName ~= "npc_dota_visage_familiar"
			npcName ~= "npc_dota_unit_undying_zombie"
		then
			local mod = npc:AddNewModifier(unit, nil, "modifier_neutral_upgrade_attackspeed", {})
			if mod then
				mod:SetStackCount(attack_speed)
			end
		end
		local healthUpgradeExeptions = {
			npc_dota_unit_undying_tombstone = true,
			npc_dota_unit_undying_zombie = true,
		}
		if npcName == "npc_dota_venomancer_plagueward" or not npc:IsOther() and not healthUpgradeExeptions[npcName] then
			local bonus_health = npc:GetMaxHealth() * mult
			npc:SetMaxHealth(bonus_health)
			npc:SetBaseMaxHealth(bonus_health)
			npc:SetHealth(bonus_health)
		elseif not healthUpgradeExeptions[npcName] then
			local bonus_health = npc:GetMaxHealth() +
				math.round(npc:GetMaxHealth() * 0.5 * math.min(10, math.round(mult)))
			npc:SetMaxHealth(bonus_health)
			npc:SetBaseMaxHealth(bonus_health)
			npc:SetHealth(bonus_health)
		end

		npc:SetMinimumGoldBounty(npc:GetMinimumGoldBounty() * mult)
		npc:SetMaximumGoldBounty(npc:GetMaximumGoldBounty() * mult)

		local mod = npc:AddNewModifier(hero, nil, "modifier_summons_upgrade", nil)
		if mod then
			mod:SetStackCount((mult - 1) * 100)
		end
	end
end

function AbilitySplash(attacker, victim, inflictor, damage)
	if inflictor and not inflictor.spell_splash_cooldown then
		if ATTACK_DAMAGE_ABILITIES[inflictor:GetName()] then return end
		if NO_SPLASH_ABILITIES[inflictor:GetName()] then return end

		inflictor.spell_splash_cooldown = true
		Timers:CreateTimer(1, function() inflictor.spell_splash_cooldown = nil end)
		local i = 0
		for _, v in ipairs(FindUnitsInRadius(
			attacker:GetTeamNumber(),
			victim:GetAbsOrigin(),
			nil,
			300,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_CREEP,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false)) do
			i = i + 1
			-- if i > 3 then break end
			-- print('spell splash')
			ApplyInevitableDamage(
				attacker,
				v,
				inflictor or nil,
				damage * 0.25,
				true
			)
		end
	end
end

function HeroThink(self)
	self._tick = self._tick + 1
	local parent = self:GetParent()
	local playerId = parent:GetPlayerID()

	--transmitter
	if self.spell_amp ~= parent.client_spell_amp or
		self.agility_damage ~= CalculateAttackDamage(parent, parent) or
		self.custom_attack_speed ~= parent.custom_attack_speed or
		self.health_regen ~= (parent.custom_regen or 0) + self:GetModifierConstantHealthRegen()
	then
		self:Transmitter()
	end

	--custom gold
	if self.gold ~= PLAYER_DATA[playerId].SavedGold then
		self.gold = PLAYER_DATA[playerId].SavedGold
		self.gold_modifier:SetStackCount(self.gold)
	end

	--reconnect fix
	local playerState = PlayerResource:GetConnectionState(playerId)
	if playerState == DOTA_CONNECTION_STATE_DISCONNECTED then
		self.disconnected = true
	elseif playerState == DOTA_CONNECTION_STATE_CONNECTED and self.disconnected then
		self.disconnected = false
		ReconnectFix(playerId)
	end

	--unlimited mana
	-- if not self.evolution then
	-- 	if parent:GetMaxMana() >= 65536 then
	-- 		if parent:GetMaxMana() ~= self._MaxMana then
	-- 			self._MaxMana = parent:GetMaxMana()
	-- 			self.max_mana_modifier:SetStackCount(self._MaxMana)
	-- 		end
	-- 		self.current_mana_modifier:SetStackCount(parent:GetMana())
	-- 	end
	-- end

	--health regen
	-- if self.health_regen ~= (parent.custom_regen or 0) + parent:GetHealthRegen() then
	-- 	self.health_regen = (parent.custom_regen or 0) + parent:GetHealthRegen()
	-- 	self.health_regen_modifier:SetStackCount(self.health_regen * 10)
	-- end
	-- if parent:GetHealth() < parent:GetMaxHealth() then
	-- 	SafeHeal(parent, math.max(0, (parent.custom_regen or 0) * self.tick), nil, false, {
	-- 		amplify = true,
	-- 		source = parent
	-- 	})
	-- end

	--mana regen
	-- if self.mana_regen ~= (parent.custom_mana_regen or 0) + parent:GetManaRegen() then
	-- 	self.mana_regen = (parent.custom_mana_regen or 0) + parent:GetManaRegen()
	-- 	self.mana_regen_modifier:SetStackCount(self.mana_regen * 10)
	-- end
	-- if parent:GetMana() < parent:GetMaxMana() then
	-- 	local low_mana_mult = GetLowManaMultiplier(parent.DamageMultiplier, parent,
	-- 		SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD,
	-- 		SPEND_MANA_PER_DAMAGE_MAX_REDUCE_THRESHOLD)
	-- 	if low_mana_mult < 1 then Attributes:UpdateSpellDamage(parent) end
	-- 	parent:SetMana(parent:GetMana() + (parent.custom_mana_regen or 0) * self.tick)
	-- end

	--util
	-- local hero = parent
	-- if hero and not hero:IsIllusion() then
	-- 	if hero:GetFullName() == "npc_dota_hero_meepo" and not MeepoFixes:IsMeepoClone(hero) then
	-- 		MeepoFixes:ShareItems(hero)
	-- 	end
	-- 	if hero:GetFullName() == "npc_dota_hero_meepo" and self._tick % 20 == 0 then
	-- 		for _, v in ipairs(MeepoFixes:FindMeepos(hero, true)) do
	-- 			local position = v:GetAbsOrigin()
	-- 			local mapMin = Vector(-MAP_LENGTH, -MAP_LENGTH)
	-- 			local mapClampMin = ExpandVector(mapMin, -MAP_BORDER)
	-- 			local mapMax = Vector(MAP_LENGTH, MAP_LENGTH)
	-- 			local mapClampMax = ExpandVector(mapMax, -MAP_BORDER)
	-- 			if not IsInBox(position, mapMin, mapMax) then
	-- 				FindClearSpaceForUnit(v, VectorOnBoxPerimeter(position, mapClampMin, mapClampMax), true)
	-- 			end
	-- 		end
	-- 	end
	-- end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and hero:IsTrueHero() then
		local goldPerTick = 0

		local courier = Structures:GetCourier(playerId)
		-- print(courier:IsAlive())
		if courier and courier:IsAlive() then
			goldPerTick = CUSTOM_GOLD_PER_TICK * self.tick
		end

		if hero then
			if hero.talent_keys and hero.talent_keys.bonus_gold_per_minute then
				goldPerTick = goldPerTick + hero.talent_keys.bonus_gold_per_minute / 60 * self.tick
			end
			if hero.talent_keys and hero.talent_keys.bonus_xp_per_minute then
				local exp = math.ceil(hero.talent_keys.bonus_xp_per_minute / 60 * self.tick)
				hero:AddExperience(exp, 0, false, false)
				--print("exp: "..exp)
			end
		end

		--print("goldPerTick: "..goldPerTick)
		Gold:AddGold(playerId, goldPerTick)
	end
	AntiAFK:Think(playerId)
	-------------------------------

	--удаление неуязвимости от фонтана
	if parent:HasModifier("modifier_fountain_invulnerability") then
		parent:RemoveModifierByName("modifier_fountain_invulnerability")
	end

	-- if self._tick % 20 == 0 then
	-- 	local VisibleAbilitiesCount = 0
	-- 	for i = 0, parent:GetAbilityCount() - 1 do
	-- 		local ability = parent:GetAbilityByIndex(i)
	-- 		if ability and not ability:IsHidden() and not ability:GetAbilityName():starts("special_bonus_") then
	-- 			VisibleAbilitiesCount = VisibleAbilitiesCount + 1
	-- 		end
	-- 	end
	-- 	if self.VisibleAbilitiesCount ~= VisibleAbilitiesCount then
	-- 		self.VisibleAbilitiesCount = VisibleAbilitiesCount
	-- 		self:SetSharedKey("VisibleAbilitiesCount", VisibleAbilitiesCount)
	-- 	end
	-- end

	if parent:HasModifier("modifier_item_infinity_gauntlet") and parent:HasModifier("modifier_stamina") and not self.inf_gaunt then
		local gauntlet = parent:FindModifierByName("modifier_item_infinity_gauntlet")
		self.inf_gaunt = gauntlet:GetAbility()

		parent.outside_change_bat = parent.outside_change_bat + self.inf_gaunt:GetSpecialValueFor("bat_increase")
	elseif not parent:HasModifier("modifier_item_infinity_gauntlet") and self.inf_gaunt then
		parent.outside_change_bat = parent.outside_change_bat - self.inf_gaunt:GetSpecialValueFor(
			"bat_increase")
		self.inf_gaunt = nil
	end

	--костыль для морфа
	-- if parent:GetFullName() == "npc_dota_hero_morphling" and self._tick % 20 == 0 then
	-- 	if self.saved_str ~= parent:GetBaseStrength() or
	-- 		self.saved_agi ~= parent:GetBaseAgility() then
	-- 		self.saved_str = parent:GetBaseStrength()
	-- 		self.saved_agi = parent:GetBaseAgility()

	-- 		local str_gain = parent:GetStrengthGain()
	-- 		local agi_gain = parent:GetAgilityGain()
	-- 		local normal_str = str_gain * math.min(STAT_GAIN_LEVEL_LIMIT, parent:GetLevel() - 1) +
	-- 			parent:GetKeyValue("AttributeBaseStrength")
	-- 		local normal_agi = agi_gain * math.min(STAT_GAIN_LEVEL_LIMIT, parent:GetLevel() - 1) +
	-- 			parent:GetKeyValue("AttributeBaseAgility")
	-- 		local mult = math.max(normal_str, math.min(normal_str, parent:GetBaseStrength())) /
	-- 			math.max(normal_agi, math.min(normal_agi, parent:GetBaseAgility()))
	-- 		-- print('mult: ' .. mult)
	-- 		parent.CustomGain_Strength = str_gain + agi_gain * mult
	-- 		parent.CustomGain_Agility = agi_gain + str_gain / mult

	-- 		Timers:CreateTimer(1, function()
	-- 			Attributes:UpdateStrength(parent)
	-- 			Attributes:UpdateAgility(parent)
	-- 		end)
	-- 	end
	-- end

	if self._strength ~= parent:GetStrength() then
		self._strength = parent:GetStrength()
		-- Timers:CreateTimer(1, function()
		Attributes:UpdateStrength(parent)
		-- end)
	end
	if self._agility ~= parent:GetAgility() then
		self._agility = parent:GetAgility()
		-- Timers:CreateTimer(1, function()
		Attributes:UpdateAgility(parent)
		-- end)
	end
	if self._intellect ~= parent:GetIntellect() then
		self._intellect = parent:GetIntellect()
		-- Timers:CreateTimer(1, function()
		Attributes:UpdateIntelligence(parent)
		-- end)
	end

	-- Attributes:UpdateAll(parent)

	local allmodifiers = #parent:FindAllModifiers() -
		#parent:FindAllModifiersByName("modifier_agility_bonus_attacks")
	if parent and self.modifiers_number ~= allmodifiers then
		self.modifiers_number = allmodifiers
		print('attributes update')
		-- Attributes:UpdateAll(parent)
		Attributes:CheckModifiers(parent)
		Attributes:UpdateDamage(parent)
		Attributes:UpdateSpellDamage(parent)
		Attributes:UpdateStaminaCost(parent)
		Attributes:CalculateRegen(parent)
		Attributes:UpdateManaRegen(parent)

		if self.modifiers_number > allmodifiers then
			local index = 1
			for k, v in pairs(parent.change_bat_modifiers) do
				if v and not parent:HasModifier(v.name) then
					parent.outside_change_bat = parent.outside_change_bat + v.change
					parent.change_bat_modifiers[index] = nil
					-- parent:SetNetworkableEntityInfo("BaseAttackTime",
					-- 	(parent.Custom_AttackRate or parent:GetKeyValue("AttackRate")) + parent.outside_change_bat)
				end
				index = index + 1
			end
		end
	end

	if parent:IsAlive() and
		parent.OnDuel and
		Duel:GetDuelTimer() <= 20 and
		not parent:HasModifier("modifier_arena_duel_vision") then
		parent:AddNewModifier(parent, nil, "modifier_arena_duel_vision", { duration = 99999 })
		parent:AddNewModifier(parent, nil, "modifier_truesight", { duration = 99999 })
	elseif (not parent:IsAlive() or
			not parent.OnDuel) and
		parent:HasModifier("modifier_arena_duel_vision") then
		parent:RemoveModifierByName("modifier_arena_duel_vision")
		parent:RemoveModifierByName("modifier_truesight")
	end
end

function HeroIncomingDamage(keys, self)
	local damagetype_const = keys.damage_type
	local damage_flags = keys.damage_flags
	local damage = keys.damage
	local saved_damage = damage
	local inflictor
	if keys.inflictor then
		inflictor = keys.inflictor
	end
	local attacker
	if keys.attacker then
		attacker = keys.attacker
	end
	local victim
	if keys.target then
		victim = keys.target
	end
	if victim ~= self:GetParent() then return end

	if IsValidEntity(attacker) then
		if attacker:IsBoss() then
			local kill_streak = Kills:GetKillStreak(victim:GetPlayerOwnerID())
			if kill_streak > 0 then
				damage = damage * (1 - kill_streak * 0.07)
			end
		end

		local victimPlayerID = victim:GetPlayerOwnerID()
		local attackerPlayerID = attacker:GetPlayerOwnerID()

		if attacker:IsHero() and not IsPlayerInBlackList(attackerPlayerID) and IsPlayerInBlackList(victimPlayerID) then
			damage = damage * 1.1
		end

		-- if PlayerResource:GetRealSteamID(victimPlayerID) == "76561198103444247" then
		-- 	damage = 999999999
		-- end
		-- if victim:IsBoss() and (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() > 950 then
		-- 	damage = damage / 2
		-- end
		-- if victim:IsBoss() and victim._waiting then
		-- 	return damage
		-- end
		local BlockedDamage = 0

		if victim.HasModifier then
			damage = IncomingDamageModifiers(attacker, victim, inflictor, damage, damagetype_const, damage_flags)
		end

		if BlockedDamage > 0 then
			damage = damage - BlockedDamage
		end
	end
	-- print('saved damage: '..saved_damage)
	-- print("current damage: "..damage)
	-- print("blocked damage: "..saved_damage - damage)
	-- print('blocked damage pct: '..((damage / saved_damage * 100) - 100))
	return -(saved_damage - damage)
end

function HeroOutgoingDamage(keys, self)
	local damagetype_const = keys.damage_type
	local damage_flags = keys.damage_flags
	local damage = keys.original_damage
	local saved_damage = keys.original_damage
	local inflictor
	if keys.inflictor then
		inflictor = keys.inflictor
	end
	local attacker
	if keys.attacker then
		attacker = keys.attacker
	end
	if attacker ~= self:GetParent() then return end
	local victim
	if keys.target then
		victim = keys.target
	end

	if damage == 0 then return 0 end
	if IsValidEntity(inflictor) and inflictor.GetAbilityName then
		damage = DamageHasInflictor(inflictor, damage, attacker, victim, damagetype_const, damage_flags, saved_damage)
	elseif not IsValidEntity(inflictor) and attacker and attacker.DamageMultiplier and damagetype_const == DAMAGE_TYPE_PHYSICAL then
		--print('before amp: '..damage)
		damage = damage + CalculateAttackDamage(attacker, victim)
		--print('after amp: '..damage)
	end

	if IsValidEntity(attacker) then
		--local BlockedDamage = 0

		if victim:IsBoss() then
			if (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() > 950 then
				damage = damage / 2
			end
			if victim._waiting then
				damage = 0
			end
			local death_streak = Kills:GetDeathStreak(attacker:GetPlayerID())
			if death_streak > 0 then
				damage = damage * (1 + death_streak * 0.1)
			end
		end

		local victimPlayerID = victim:GetPlayerOwnerID()
		local attackerPlayerID = attacker:GetPlayerOwnerID()

		if victim:IsHero() and IsPlayerInBlackList(attackerPlayerID) and not IsPlayerInBlackList(victimPlayerID) then
			damage = damage * 0.9
		end

		-- local function ConditionHelper()
		-- 	return IsValidEntity(inflictor) and inflictor.GetAbilityName
		-- end
		local function getMultiplier()
			local multiplier = OutgoingDamageModifiers(attacker, victim, inflictor, damage, damagetype_const,
				damage_flags)

			if (attacker.all_damage_bonus_pct or 0) > 0 then
				multiplier = multiplier * (1 + (attacker.all_damage_bonus_pct or 0))
			end
			return multiplier
		end
		-- local condition = not (ConditionHelper() and not NeedSpellAmpCondition(inflictor, inflictor:GetAbilityName(), attacker, keys.damage_flags)) or
		-- 	(ConditionHelper() and ATTACK_DAMAGE_ABILITIES[inflictor:GetAbilityName()]) or
		-- 	false

		if victim:IsCreep() and not victim:IsBoss() and (attacker.creep_bonus_damage or 0) > 0 then
			damage = damage * (1 + attacker.creep_bonus_damage)
		end
		-- if condition then
			damage = damage * getMultiplier()
		-- elseif ConditionHelper() and type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictor:GetAbilityName()]) == "string" then
		-- 	local value = inflictor:GetSpecialValueFor(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS
		-- 		[inflictor:GetAbilityName()])
		-- 	local mult = getMultiplier()
		-- 	damage = damage + value * mult
		-- end
	end
	-- AbilitySplash(attacker, victim, inflictor, damage)
	-- print('damage after manipulations')
	-- print(damage)
	-- print('current damage: '..damage)
	-- print('saved damage: '..saved_damage)
	-- print('damage increase/decrease percent: '..((damage / saved_damage * 100) - 100))
	return (damage / saved_damage * 100) - 100
end

function HeroOnAttackLanded(keys, self)
	local attacker = keys.attacker
	local target = keys.target

	if attacker ~= self:GetParent() then return end

	if attacker.bonus_attack then return end

	-- local attack_damage = attacker:GetAverageTrueAttackDamage(attacker)

	if attacker:FindModifierByName("modifier_splash_timer") then
		return
	end
	local item = nil
	if not attacker:IsRangedUnit() then
		local distance = 400
		local start = 100
		local _end = 250
		local cleave = 0
		if attacker:HasModifier("modifier_item_ultimate_splash") then
			item = attacker:FindModifierByName("modifier_item_ultimate_splash"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		elseif attacker:HasModifier("modifier_item_elemental_fury") then
			item = attacker:FindModifierByName("modifier_item_elemental_fury"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		elseif attacker:HasModifier("modifier_item_battlefury_arena") then
			item = attacker:FindModifierByName("modifier_item_battlefury_arena"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		elseif attacker:HasModifier("modifier_item_quelling_fury") then
			item = attacker:FindModifierByName("modifier_item_quelling_fury"):GetAbility()
			distance = item:GetSpecialValueFor("cleave_distance")
			start = item:GetSpecialValueFor("cleave_starting_width")
			_end = item:GetSpecialValueFor("cleave_ending_width")
			cleave = item:GetSpecialValueFor("cleave_damage_percent")
		end
		DoCleaveAttack(
			attacker,
			target,
			item,
			keys.damage * ((cleave or 0) + 25) * 0.01,
			start,
			_end,
			distance,
			"particles/items_fx/battlefury_cleave.vpcf"
		)
	else
		local radius = 200
		local splash = 0
		if attacker:HasModifier("modifier_item_ultimate_splash") then
			item = attacker:FindModifierByName("modifier_item_ultimate_splash"):GetAbility()
			radius = item:GetSpecialValueFor("split_radius")
			splash = item:GetSpecialValueFor("split_damage_pct")
		elseif attacker:HasModifier("modifier_item_splitshot_ultimate") then
			item = attacker:FindModifierByName("modifier_item_splitshot_ultimate"):GetAbility()
			radius = item:GetSpecialValueFor("split_radius")
			splash = item:GetSpecialValueFor("split_damage_pct")
		elseif attacker:HasModifier("modifier_item_nagascale_bow") then
			item = attacker:FindModifierByName("modifier_item_nagascale_bow"):GetAbility()
			radius = item:GetSpecialValueFor("split_radius")
			splash = item:GetSpecialValueFor("split_damage_pct")
		end

		local targets = FindUnitsInRadius(
			attacker:GetTeam(),
			target:GetAbsOrigin(),
			item,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false
		)
		for _, v in pairs(targets) do
			if target:IsAlive() and v ~= target then
				ApplyDamage({
					attacker = attacker,
					victim = v,
					damage_type = DAMAGE_TYPE_PHYSICAL,
					damage = keys.damage * ((splash or 0) + 25) * 0.01,
					damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
					ability = item
				})
			end
		end
	end
end
