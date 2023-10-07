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
			caster:EmitSound('Hero_OgreMagi.Fireblast.x' .. multicasts)
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
		unit:HealWithParams(math.min(2000000000, flAmount),
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
		else
			cost = tempItem:GetCost()
			UTIL_Remove(tempItem)
		end
	end
	return cost
end

function GetNotScaledDamage(damage, unit)
	local intSpellDamage = unit:GetSpellAmplification(false)
	--[[if unit.DamageAmpPerAgility then
		local int = unit:GetIntellect()
		intSpellDamage = int * unit.DamageAmpPerAgility * 0.01
	end]]
	damage = damage / (1 + (unit:GetSpellAmplification(false) or 0))
	--print(damage)
	return damage
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

		ability.NoDamageAmp = true
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

function CalculateStatForLevel(parent, stat, level_limit, start_attribute)
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

function FilterDamageSpellAmpCondition(inflictor, inflictorname, attacker, damage_flags)
	return (attacker.DamageMultiplier and not SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] and inflictorname ~= "necrolyte_heartstopper_aura" and not inflictor.NoDamageAmp and not HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) and not HasDamageFlag(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION))
end

function DamageAmpCondition(inflictor, unit)
	return (not inflictor or ((IsValidEntity(inflictor) and inflictor.GetAbilityName) and FilterDamageSpellAmpCondition --[[(inflictor, inflictor:GetAbilityName(), unit)]]))
end

function StaminaThreshouldForDebuff(stamina)
	return stamina:GetStackCount() <= STAMINA_THRESHOLD_FOR_DEBUFF
end

function CheckBackpack(unit, backpack)
	local update = false
	if not backpack then
		backpack = {}
	end

	local index = 0
	for slot = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
		index = index + 1
		local item = unit:GetItemInSlot(slot)
		if item ~= backpack[index] then
			backpack[index] = item
			update = true
		end
	end

	if update then
		--print("yes")
		Attributes:UpdateAll(unit)
	end

	return backpack
end

function CalculateAttackDamage(attacker, victim, original_damage)
	if not attacker.DamageMultiplier then return 0 end
	local amp = ((attacker.DamageMultiplier or 2) - 1)
	local attack_damage = attacker:GetAverageTrueAttackDamage(victim)

	return attacker:GetReliableDamage() * amp * ((original_damage or attack_damage) / attack_damage)
end

function DamageHasInflictor(inflictor, damage, attacker, victim, damagetype_const, damage_flags, original_damage)
	local inflictorname = inflictor:GetAbilityName()

	if (SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] or inflictor.NoDamageAmp) and not ATTACK_DAMAGE_ABILITIES[inflictorname] and attacker:IsHero() then
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
		AddIncreasedDamage(value)
		local mult = (1 + (attacker:GetSpellAmplification(false) or 0)) * (attacker.DamageMultiplier)
		--print(value * mult)
		value = (value * mult) - value
		--print(value)
		damage = damage + value
	elseif FilterDamageSpellAmpCondition(inflictor, inflictorname, attacker, damage_flags) then
		damage = math.min(5000, damage)
		AddIncreasedDamage(damage)
		damage = damage * attacker.DamageMultiplier
	end

	if ATTACK_DAMAGE_ABILITIES[inflictorname] then
		damage = damage + CalculateAttackDamage(attacker, victim, original_damage)
	end

	local jungle_bears_damage_mult = inflictor:GetAbilitySpecial("jungle_bears_damage_multiplier")
	if victim and jungle_bears_damage_mult and victim:IsJungleBear() then
		if string.starts(inflictorname, "item_essential_orb_fire_") and (attacker:GetPrimaryAttribute() ~= 2 or not attacker:GetNetworkableEntityInfo("BonusPrimaryAttribute2")) then
		else
			inflictor.jungle_bears_damage_mult = jungle_bears_damage_mult
			damage = damage * jungle_bears_damage_mult
		end
	end

	if IsValidEntity(inflictor.originalInflictor) then
		inflictorname = inflictor.originalInflictor:GetAbilityName()
	end
	if (inflictor:GetAbilitySpecial("damage_to_arena_boss") or BOSS_DAMAGE_ABILITY_MODIFIERS[inflictorname]) and victim:IsBoss() then
		damage = damage * BOSS_DAMAGE_ABILITY_MODIFIERS[inflictorname] * 0.01
	end

	local condition_helper = function()
		return attacker:IsTrueHero() and
			attacker:GetFullName() ~= "npc_arena_hero_comic_sans" and
			attacker:GetFullName() ~= "npc_arena_hero_sara" and
			attacker.DamageMultiplier > SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD and
			inflictor.GetManaCost and
			inflictor:GetManaCost(inflictor:GetLevel()) > 0 and
			inflictor.GetCooldown and
			inflictor:GetCooldown(inflictor:GetLevel()) > 0
	end

	local damage_decrease_mult = GetLowManaMultiplier(attacker.DamageMultiplier, attacker,
		SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD,
		SPEND_MANA_PER_DAMAGE_MAX_REDUCE_THRESHOLD)
	if (SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] or MANA_SPEND_SPELLS_EXEPTIONS[inflictorname]) and not ATTACK_DAMAGE_ABILITIES[inflictorname] and condition_helper() then
		damage = damage * damage_decrease_mult
	end
	local interval_mult = GetIntervalMult(inflictor, "_damageInterval")
	if SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname] and type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) == "string" and condition_helper() then
		SpendManaPerDamage(attacker, inflictor, increased_damage, interval_mult, "ManaSpendCooldown",
			SPEND_MANA_PER_DAMAGE)
	end

	if condition_helper() and
		inflictor.GetAbilityName and
		not ATTACK_DAMAGE_ABILITIES[inflictorname] and
		FilterDamageSpellAmpCondition(inflictor, inflictorname, attacker, damage_flags)
	then
		damage = damage * damage_decrease_mult
		SpendManaPerDamage(attacker, inflictor, increased_damage, interval_mult, "ManaSpendCooldown",
			SPEND_MANA_PER_DAMAGE)
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
	if mult > startMult then
		local mana_mult = 1 - (attacker:GetMana() / attacker:GetMaxMana())
		mult = math.min(1, (attacker.DamageMultiplier - startMult) / (maxMult - startMult))
		-- print(1 - (mana_mult * mult))
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
	local addictive_multiplier
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
			--[[if multiplier.LifestealPercentage then
				LifestealPercentage = LifestealPercentage + multiplier.LifestealPercentage
			end
			if multiplier.SpellLifestealPercentage and not multiplier.SpellLifestealStackable then
				SpellLifestealPercentage = math.max(SpellLifestealPercentage, multiplier.SpellLifestealPercentage)
				DontShowParticleAndHealNumber = multiplier.DontShowParticleAndHealNumber
				
			elseif multiplier.SpellLifestealPercentage then
				SpellLifestealPercentage = SpellLifestealPercentage + multiplier.SpellLifestealPercentage
				DontShowParticleAndHealNumber = multiplier.DontShowParticleAndHealNumber
			end]]
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
		--print("Raw damage: " .. damage .. ", after " .. k .. ": " .. damage * multiplier .. " (multiplier: " .. multiplier .. ")")
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

function GetGoldMultiplier(hero)
	local bonus_gold = 1
	if hero then
		for _, v in pairs(GAIN_BONUS_GOLD_ITEMS) do
			--if not items_cash[v] then
			local item = FindItemInInventoryByName(hero, v, false, false, true)
			if item and item:GetSpecialValueFor("bonus_gold_pct") then
				bonus_gold = bonus_gold +
					item:GetSpecialValueFor("bonus_gold_pct") *
					0.01 --math.max(bonus_gold, 1 + item:GetSpecialValueFor("bonus_gold_pct") * 0.01)
			end
			--end
		end
	end
	return bonus_gold
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

	parent:SetNetworkableEntityInfo("BaseAttackTime", parent:GetKeyValue("AttackRate"))

	if UNITS_LIST[parent:GetFullName()] and UNITS_LIST[parent:GetFullName()].DamageSubtypeResistance then
		parent:SetNetworkableEntityInfo("DamageSubtypesResistance",
			UNITS_LIST[parent:GetFullName()].DamageSubtypeResistance)
	end

	parent:SetNetworkableEntityInfo("BaseDamagePerStr", 0)
	parent:SetNetworkableEntityInfo("BaseDamagePerAgi", 0)
	parent:SetNetworkableEntityInfo("BaseDamagePerInt", 0)

	parent.HpRegenAmp = STRENGTH_REGEN_AMPLIFY
	parent.BaseDamagePerStrength = BASE_DAMAGE_PER_STRENGTH
	parent.AgilityArmorMultiplier = AGILITY_ARMOR_MULTIPLIER
	parent.ManaRegAmpPerInt = MANA_REGEN_AMPLIFY
	parent.HealthPerStrength = BASE_HP_PER_STRENGTH
	parent.ManaPerInt = BASE_MANA_PER_INT

	parent.outside_change_bat = 0
	parent.change_bat_modifiers = {}

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
	--if damage < victim:GetHealth() then
	--print(lethal)
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
		--victim:SetHealth(victim:GetHealth() - damage)
		if not noOverhead and attacker ~= victim then CreateDamageOverHead(attacker, victim, damage) end
	end
	-- else
	-- 	victim:TrueKill(ability, attacker)
	--end
end

function CreateDamageOverHead(attacker, victim, damage)
	if attacker == victim then return end
	--if attacker ~= victim then
	--end
	SendOverheadEventMessage(victim:GetPlayerOwner(), OVERHEAD_ALERT_INCOMING_DAMAGE, victim, math.round(damage),
		victim:GetPlayerOwner())

	if not attacker:GetPlayerOwner() then return end
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

			unit:RemoveModifierByName(v:GetName())

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
	return math.min(STRENGTH_CRIT_SPELL_LIMIT * 0.01 - 1, 1 + mult / STRENGTH_CRIT_SPELL_CRIT_DECREASRE_MULT)
end

function ReconnectFix(player)
	if HeroSelection:GetState() == HERO_SELECTION_PHASE_END then
		Convars:SetInt("host_timescale", 1)
		StatsClient:AddGuide(nil)
		Duel:CreateGlobalTimer()
		Weather:Init()
		PanoramaShop:StartItemStocks()
		PlayerTables:start()
		PanoramaShop:InitializeItemTable()
		CustomGameEventManager:Send_ServerToPlayer(player, "reconnect-fix", {
			removePickWindow = true
		})
		print(player)
		print('reconnect fix')
	end
end
