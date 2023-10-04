require("util/string")

function GetDirectoryFromPath(path)
	return path:match("(.*[/\\])")
end

function ModuleLinkLuaModifier(this, className, fileName, LuaModifierType)
	return LinkLuaModifier(className, GetDirectoryFromPath(this) .. (fileName or className),
		LuaModifierType or LUA_MODIFIER_MOTION_NONE)
end

function ModuleRequire(this, fileName)
	return require(GetDirectoryFromPath(this) .. fileName)
end

require("modifier_index")

function CEntityInstance:GetNetworkableEntityInfo(key)
	local t = CustomNetTables:GetTableValue("custom_entity_values", tostring(self:GetEntityIndex())) or {}
	return t[key]
end

function CDOTA_Buff:GetSharedKey(key)
	local t = CustomNetTables:GetTableValue("shared_modifiers", self:GetParent():GetEntityIndex() .. "_" .. self:GetName()) or {}
	return t[key]
end

function CEntityInstance:IsCustomWard()
	if not self.GetUnitName then return false end
	local n = self:GetUnitName()
	return n == "npc_dota_sentry_wards" or n == "npc_dota_observer_wards" or string.starts(n, "npc_arena_ward_")
end

function CDOTA_Buff:StoreAbilitySpecials(specials)
	local ability = self:GetAbility()
	self.specials = {}
	for _,v in ipairs(specials) do
		self.specials[v] = ability:GetSpecialValueFor(v)
	end
end

function CDOTA_Buff:GetSpecialValueFor(name)
	return self.specials[name]
end

function DeclarePassiveAbility(name, modifier)
	_G[name] = { GetIntrinsicModifierName = function() return modifier end }
end

CDOTABaseAbility = IsServer() and CDOTABaseAbility or C_DOTABaseAbility
CDOTA_Ability_Lua = IsServer() and CDOTA_Ability_Lua or C_DOTA_Ability_Lua
CDOTA_Item_Lua = IsServer() and CDOTA_Item_Lua or C_DOTA_Item_Lua

CDOTABaseAbility.HasStaticCooldown = function(self)
    return false
end

local VALVE_CDOTABaseAbility_GetCooldown = CDOTABaseAbility.GetCooldown
CDOTABaseAbility.GetCooldown = function(self, iLevel)
    local hCaster   = self:GetCaster()
    local fCooldown = VALVE_CDOTABaseAbility_GetCooldown(self, iLevel)
    if IsValidEntity(hCaster)
        and self:HasStaticCooldown() then
        local fCDR = hCaster:GetCooldownReduction()
              fCDR = fCDR ~= 0
                     and fCDR
                     or 1
        return fCooldown / fCDR
    end
    return fCooldown
end

local VALVE_CDOTA_Ability_Lua_GetCooldown = CDOTA_Ability_Lua.GetCooldown
CDOTA_Ability_Lua.GetCooldown = function(self, iLevel)
    local hCaster   = self:GetCaster()
    local fCooldown = VALVE_CDOTA_Ability_Lua_GetCooldown(self, iLevel)
    if IsValidEntity(hCaster)
        and self:HasStaticCooldown() then
        local fCDR = hCaster:GetCooldownReduction()
              fCDR = fCDR ~= 0
                     and fCDR
                     or 1
        return fCooldown / fCDR
    end
    return fCooldown
end

local VALVE_CDOTA_Item_Lua_GetCooldown = CDOTA_Item_Lua.GetCooldown
CDOTA_Item_Lua.GetCooldown = function(self, iLevel)
    local hCaster   = self:GetCaster()
    local fCooldown = VALVE_CDOTA_Item_Lua_GetCooldown(self, iLevel)
	--print(fCooldown)
    if IsValidEntity(hCaster)
        and self:HasStaticCooldown() then
        local fCDR = hCaster:GetCooldownReduction()
              fCDR = fCDR ~= 0
                     and fCDR
                     or 1
		--print(fCooldown / fCDR)
        return fCooldown / fCDR
    end
    return fCooldown
end
