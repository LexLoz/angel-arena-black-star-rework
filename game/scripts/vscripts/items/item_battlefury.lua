local factorySYK = require("items/factory_sange_yasha_kaya")
local fireSplitshotProjectilesFactory = require("items/helper_splitshot")

item_battlefury_baseclass = {}
LinkLuaModifier("modifier_item_battlefury_arena", "items/item_battlefury.lua", LUA_MODIFIER_MOTION_NONE)

function item_battlefury_baseclass:GetIntrinsicModifierName()
	return "modifier_item_battlefury_arena"
end

function item_battlefury_baseclass:CastFilterResultTarget(hTarget)
	return (hTarget:GetClassname() == "ent_dota_tree" or hTarget:IsCustomWard()) and UF_SUCCESS or UF_FAIL_CUSTOM
end

function item_battlefury_baseclass:GetCustomCastErrorTarget(hTarget)
	return (hTarget:GetClassname() == "ent_dota_tree" or hTarget:IsCustomWard()) and "" or "dota_hud_error_cant_cast_on_non_tree_ward"
end

if IsServer() then
	function item_battlefury_baseclass:OnSpellStart()
		self:GetCursorTarget():CutTreeOrWard(self:GetCaster(), self)
	end
end

item_quelling_fury = class(item_battlefury_baseclass)
item_quelling_fury.cleave_pfx = "particles/items_fx/battlefury_cleave.vpcf"
item_battlefury_arena = class(item_battlefury_baseclass)
item_battlefury_arena.cleave_pfx = "particles/items_fx/battlefury_cleave.vpcf"
item_elemental_fury = class(item_battlefury_baseclass)
item_elemental_fury.cleave_pfx = "particles/items_fx/battlefury_cleave.vpcf"
item_ultimate_splash = class(item_battlefury_baseclass)
item_ultimate_splash.cleave_pfx = "particles/items_fx/battlefury_cleave.vpcf"

function item_ultimate_splash:GetIntrinsicModifierName()
	return "modifier_item_ultimate_splash"
end

function item_elemental_fury:GetIntrinsicModifierName()
	return "modifier_item_elemental_fury"
end


modifier_item_battlefury_arena = class({
	IsHidden      = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	IsPurgable    = function() return false end,
})

function modifier_item_battlefury_arena:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		--MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

if IsServer() then
	function modifier_item_battlefury_arena:OnCreated()
		Timers:NextTick(function()
			self:GetParent()._splash = (self:GetParent()._splash or 0) + self:GetAbility():GetSpecialValueFor("cleave_damage_percent")
		end)
	end
	function modifier_item_battlefury_arena:OnDestroy()
		Timers:NextTick(function()
			self:GetParent()._splash = (self:GetParent()._splash or 0) - self:GetAbility():GetSpecialValueFor("cleave_damage_percent")
		end)
	end
end

function modifier_item_battlefury_arena:GetModifierPreAttack_BonusDamage()
	-- print(self:GetAbility():GetSpecialValueFor("bonus_damage"))
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_battlefury_arena:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_battlefury_arena:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

if IsServer() then
	function modifier_item_battlefury_arena:OnAttackLanded(keys)
		local attacker = keys.attacker
		if attacker == self:GetParent() and not attacker:IsIllusion() then
			--print("landed")
			local ability = self:GetAbility()
			local target = keys.target
			--[[if not attacker:IsRangedUnit() and not attacker:FindModifierByName("modifier_splash_timer") then
				DoCleaveAttack(
					attacker,
					target,
					ability,
					keys.damage * ability:GetSpecialValueFor("cleave_damage_percent") * 0.01,
					ability:GetSpecialValueFor("cleave_distance"),
					ability:GetSpecialValueFor("cleave_starting_width"),
					ability:GetSpecialValueFor("cleave_ending_width"),
					self:GetAbility().cleave_pfx
				)
			end]]
		end
	end
end

LinkLuaModifier("modifier_item_ultimate_splash", "items/item_battlefury.lua", LUA_MODIFIER_MOTION_NONE)

modifier_item_ultimate_splash = factorySYK(
	{ sange = true, yasha = true, kaya = true },
	{
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
		--MODIFIER_EVENT_ON_ATTACK,
	}
)

function modifier_item_ultimate_splash:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

local modifier_item_ultimate_splash_projectiles = fireSplitshotProjectilesFactory(
	"modifier_item_ultimate_splash",
	"split_radius"
)

modifier_item_ultimate_splash.GetModifierPreAttack_BonusDamage = modifier_item_battlefury_arena.GetModifierPreAttack_BonusDamage
modifier_item_ultimate_splash.GetModifierConstantHealthRegen = modifier_item_battlefury_arena.GetModifierConstantHealthRegen
modifier_item_ultimate_splash.GetModifierConstantManaRegen = modifier_item_battlefury_arena.GetModifierConstantManaRegen
modifier_item_ultimate_splash.OnAttackLanded = function(self, keys)
	modifier_item_battlefury_arena.OnAttackLanded(self, keys)
end

function modifier_item_ultimate_splash:GetModifierAttackRangeBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

if IsServer() then
	--[[function item_ultimate_splash:OnProjectileHit(hTarget)
		if not hTarget then return end
		local caster = self:GetCaster()
		if caster:IsIllusion() then return end
		local number = #caster:FindAllModifiersByName(self:GetIntrinsicModifierName())

		self.NoDamageAmp = true
		ApplyDamage({
			attacker = caster,
			victim = hTarget,
			damage_type = DAMAGE_TYPE_PHYSICAL,
			damage = caster:GetAverageTrueAttackDamage(target) * self:GetSpecialValueFor("split_damage_pct") * 0.01 * number,
			damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
			ability = self
		})

		hTarget:EmitSound("Hero_Medusa.AttackSplit")
	end]]
end

function modifier_item_ultimate_splash:OnAttack(keys)
	local target = keys.target
	local attacker = keys.attacker
	local ability = self:GetAbility()
	if attacker ~= self:GetParent() then return end

	--modifier_item_ultimate_splash_projectiles(attacker, target, ability)

	--[[if attacker:IsRangedUnit() and not attacker:FindModifierByName("modifier_splash_timer") and RollPercentage(ability:GetSpecialValueFor("global_attack_chance_pct")) then
		local units = FindUnitsInRadius(
			attacker:GetTeamNumber(),
			Vector(0, 0, 0),
			nil,
			FIND_UNITS_EVERYWHERE,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false
		)
		local unit = units[RandomInt(1, #units)]

		local projectile_info = GenerateAttackProjectile(attacker, self)
		projectile_info.Target = unit
		projectile_info.bProvidesVision = true
		projectile_info.iVisionRadius = 50
		projectile_info.iVisionTeamNumber = attacker:GetTeamNumber()
		ProjectileManager:CreateTrackingProjectile(projectile_info)
	end]]
end








LinkLuaModifier("modifier_item_elemental_fury", "items/item_battlefury.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_elemental_fury = factorySYK(
	{ sange = true, yasha = true, kaya = true },
	{
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	}
)

modifier_item_elemental_fury.GetModifierPreAttack_BonusDamage = modifier_item_battlefury_arena.GetModifierPreAttack_BonusDamage
modifier_item_elemental_fury.GetModifierConstantHealthRegen = modifier_item_battlefury_arena.GetModifierConstantHealthRegen
modifier_item_elemental_fury.GetModifierConstantManaRegen = modifier_item_battlefury_arena.GetModifierConstantManaRegen
modifier_item_elemental_fury.OnAttackLanded = function(self, keys)
	modifier_item_battlefury_arena.OnAttackLanded(self, keys)
end