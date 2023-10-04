LinkLuaModifier("modifier_sans_genocide_mod", "heroes/hero_sans/genocide_mod.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sans_genocide_mod_debuff", "heroes/hero_sans/genocide_mod.lua", LUA_MODIFIER_MOTION_NONE)

sans_genocide_mod = class({})

modifier_sans_genocide_mod = class({
    IsDebuff        = function()  return false end,
    IsHidden        = function()  return false end,
    IsPurgable      = function()  return false end,
    RemoveOnDeath   = function()  return true end,
    DestroyOnExpire = function()  return true end,
    GetAttributes   = function()  return  MODIFIER_ATTRIBUTE_PERMANENT end,
    CheckState      = function()
        return {
            [MODIFIER_STATE_DEBUFF_IMMUNE] = true
        }
    end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS
    }
    end,

	GetAbsoluteNoDamageMagical  = function() return 1 end,
	GetAbsoluteNoDamagePure     = function() return 1 end,
})

modifier_sans_genocide_mod_debuff = class({
    IsDebuff        = function()  return true end,
    IsHidden        = function()  return false end,
    IsPurgable      = function()  return true end,
    RemoveOnDeath   = function()  return true end,
    DestroyOnExpire = function()  return true end,
    GetAttributes   = function()  return  MODIFIER_ATTRIBUTE_PERMANENT end,
    CheckState      = function()
        return {[MODIFIER_STATE_TETHERED] = true}
    end
})

function modifier_sans_genocide_mod:GetModifierCastRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_cast_distance")
end

if IsServer() then
    function sans_genocide_mod:GetBehavior()
        return not self:GetCaster():HasScepter() and DOTA_ABILITY_BEHAVIOR_NO_TARGET or DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
    end

    function sans_genocide_mod:OnAbilityPhaseStart()
        self:GetCaster():EmitSound("Arena.Hero_Sans.Genocide_Mode.Cast")
    end
    function sans_genocide_mod:OnSpellStart()
        local caster = self:GetCaster()
        local duration = self:GetSpecialValueFor("duration")
        local dodger = caster:FindAbilityByName("sans_dodger")
        dodger:RefreshCharges(true)
        caster:Purge(false, true, false, true, false)
        caster:AddNewModifier(caster, self, "modifier_sans_genocide_mod", {
            duration = duration
        })
        caster:EmitSound("Arena.Hero_Sans.Genocide_Mode.Proceed")

        for _,v in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("debuff_radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)) do
            v:AddNewModifier(caster, self, "modifier_sans_genocide_mod_debuff", {
                duration = duration * (1 - v:GetStatusResistance())
            })
        end
    end
    function modifier_sans_genocide_mod:OnCreated(keys)
        local parent = self:GetParent()

        local caster = parent
        local ability = self:GetAbility()
        local duration = self:GetRemainingTime()
        if caster:HasScepter() then
            local interval = ability:GetSpecialValueFor("scepter_bones_interval")
            local radius = ability:GetSpecialValueFor("scepter_bones_radius")
            local dodger = caster:FindAbilityByName("sans_dodger")

            local function ProceedAghanimAbility()
                local timer = Timers:CreateTimer(function()
                    --for i=0,2 do
                        local point = caster:GetAbsOrigin()
                        point.x = RandomInt(point.x - radius, point.x + radius)
                        point.y = RandomInt(point.y - radius, point.y + radius)
                        dodger:SpawnBones(point)
                    --end
                    return interval
                end)
                Timers:CreateTimer(duration, function()
                    Timers:RemoveTimer(timer)
                end)
                return timer
            end

            if not self.aghanim_think then
                self.aghanim_think = ProceedAghanimAbility()
            else
                Timers:RemoveTimer(self.aghanim_think)
                self.aghanim_think = ProceedAghanimAbility()
            end
        end

        parent:FindModifierByName("modifier_sans_dodger"):SetDuration(-1, true)
		parent:Purge(false, true, false, false, false)
		local pfx = ParticleManager:CreateParticle("particles/arena/items_fx/holy_knight_shield_avatar.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(pfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		self:AddParticle(pfx, false, false, -1, true, false)
    end
    function modifier_sans_genocide_mod:OnDestroy()
        self:GetParent():StopSound("Arena.Hero_Sans.Genocide_Mode.Proceed")
        self:GetParent():StopSound("Arena.Hero_Sans.Last_Breath.Aghanim")
    end
end