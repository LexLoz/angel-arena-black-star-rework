LinkLuaModifier("modifier_sans_dodger", "heroes/hero_sans/dodger.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sans_dodger_slow", "heroes/hero_sans/dodger.lua", LUA_MODIFIER_MOTION_NONE)

sans_dodger = class({
    GetIntrinsicModifierName = function() return "modifier_sans_dodger" end
})

modifier_sans_dodger_slow = class({
    IsHidden        = function()  return false end,
    IsDebuff        = function()  return true end,
    GetAttributes   = function()  return  MODIFIER_ATTRIBUTE_PERMANENT end,
    DeclareFunctions = function() return {
            MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
        }
    end,
    GetModifierMoveSpeed_Absolute  = function() return 100 end,

    --GetEffectName = function() return "particles/units/heroes/hero_slardar/slardar_amp_damage_flash.vpcf" end,
})

if IsServer() then
    function modifier_sans_dodger_slow:IsPurgable()
        return self:GetAbility():GetCaster() == self:GetParent() and false or true
    end
end

modifier_sans_dodger = class({
    IsHidden        = function()  return false end,
    IsPurgable      = function()  return false end,
    RemoveOnDeath   = function()  return false end,
    DestroyOnExpire = function()  return false end,
    GetAttributes   = function()  return  MODIFIER_ATTRIBUTE_PERMANENT end,
    DeclareFunctions = function() return {
            MODIFIER_PROPERTY_HEALTH_BONUS,
            MODIFIER_PROPERTY_MANACOST_PERCENTAGE,
            MODIFIER_PROPERTY_ABSORB_SPELL,
            MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,

            MODIFIER_EVENT_ON_DEATH,
            MODIFIER_EVENT_ON_RESPAWN,

            MODIFIER_PROPERTY_TOOLTIP,
            MODIFIER_PROPERTY_TOOLTIP2
        }
    end,
    CheckState = function() return {
        [MODIFIER_STATE_EVADE_DISABLED] = true
        }
    end,
})

if IsClient() then
    function sans_dodger:GetCastRange()
        return (self:GetSpecialValueFor("blink_distance"))
    end
end

if IsServer then
    function sans_dodger:Blink(caster, point)
        local casterPos = caster:GetAbsOrigin()
        local blinkRange = (self:GetSpecialValueFor("blink_distance") + (caster:IsGenocideMode() and caster:GetCastRangeBonus() or 0)) * caster:IsGenocideMode(self)

        if (point - casterPos):Length2D() > blinkRange then
            point = casterPos + (point - casterPos):Normalized() * blinkRange
        end

        caster:EmitSound("Arena.Hero_Sans.Dodger.Blink")
        ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
        FindClearSpaceForUnit(caster, point, false)
        ProjectileManager:ProjectileDodge(caster)
    end

    function sans_dodger:ModifyCharges(value, damaged)
        local caster = self:GetCaster()
        local modifier = caster:FindModifierByName("modifier_sans_dodger")
        local stacks = modifier:GetStackCount()
        if not value and not damaged then
            return stacks
        end
        modifier:SetStackCount(math.min(math.max(stacks + value, 0), self:GetSpecialValueFor("max_charges") + modifier.bonus_charges))
        stacks = modifier:GetStackCount()

        if modifier:GetRemainingTime() <= 0 then
            modifier:SetDuration(self:GetCooldown(), true)
        elseif modifier:AllChargesReady() then
            modifier:SetDuration(-1, true)
        end
        if damaged and not caster:IsGenocideMode() then
            modifier:SetDuration(modifier.cooldown_after_damage, true)
        end
        if stacks == 0 then
            modifier:SetDuration(modifier.cooldown_after_damage, true)
            self:StartCooldown(modifier.cooldown_after_damage)
            if caster:IsGenocideMode() then
                caster:RemoveModifierByName("modifier_sans_genocide_mod")
            end
            caster:AddNewModifier(caster, self, "modifier_sans_dodger_slow", {
                duration = modifier.cooldown_after_damage *  caster:GetCooldownReduction(),
                isPurgable = false,
            })
        else
            if caster:HasModifier("modifier_sans_dodger_slow") then caster:RemoveModifierByName("modifier_sans_dodger_slow") end
        end
        return stacks
    end

    function sans_dodger:RefreshCharges(particles)
        if particles then
            self:GetCaster():EmitSound("Arena.Hero_Sans.Dodger.Refresh")
            ParticleManager:SetParticleControlEnt(ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sans/sans_dodger_refresh.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster()), 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
        end
        local modifier = self:GetCaster():FindModifierByName("modifier_sans_dodger")
        self:ModifyCharges(math.round((self:GetSpecialValueFor("max_charges") + modifier.bonus_charges) / 4))
        self:EndCooldown()
    end

    function sans_dodger:SpawnBones(point)
        local caster = self:GetCaster()
        local radius = self:GetSpecialValueFor("radius") * caster:IsGenocideMode(self)
        local teamFilter = self:GetAbilityTargetTeam()
		local typeFilter = self:GetAbilityTargetType()
		local flagFilter = self:GetAbilityTargetFlags()
		local teamNumber = caster:GetTeamNumber()
        EmitSoundOnLocationWithCaster(point, "Arena.Hero_Sans.Dodger.Bones_Predict", caster)
        Timers:CreateTimer(self:GetSpecialValueFor("delay"), function()
            local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sans/sans_dodger_bones.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl(pfx, 0, point)
            ParticleManager:SetParticleControl(pfx, 1, Vector(radius, 0, 0))
            --ParticleManager:ReleaseParticleIndex(pfx)
            EmitSoundOnLocationWithCaster(point, "Arena.Hero_Sans.Dodger.Bones_Release", caster)

            for _,v in ipairs(FindUnitsInRadius(teamNumber, point, nil, radius, teamFilter, typeFilter, flagFilter, FIND_ANY_ORDER, false)) do
                v:AddNewModifier(caster, self, "modifier_sans_dodger_slow", {
                    duration = self:GetSpecialValueFor("stun_duration") * (1 - v:GetStatusResistance()),
                    isPurgable = true,
                })

                local damage = self:GetSpecialValueFor("blink_damage") * caster:IsGenocideMode(self)

                ApplyDamage({
                    victim = v,
                    attacker = caster,
                    damage = damage,
                    damage_type = self:GetAbilityDamageType(),
                    ability = self
                })
            end
        end)
    end

    function sans_dodger:OnUpgrade()
        if self:GetLevel() == 1 then
            self:ToggleAutoCast()
        end
    end
    function sans_dodger:OnSpellStart()
        local caster = self:GetCaster()
        local cost = self:GetSpecialValueFor("blink_cost")
        if self:ModifyCharges() < cost then
            self:EndCooldown()
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_error_no_charges")
            return
        end
        if self:GetAutoCastState() then self:SpawnBones(caster:GetAbsOrigin()) end
        caster:Purge(false, true, false, false, false)
        self:Blink(caster, self:GetCursorPosition())
        self:ModifyCharges(-cost)
        self:StartCooldown(self:GetCooldown())
    end

    function sans_dodger:GetCooldown()
        local caster = self:GetCaster()
        return self:GetSpecialValueFor("blink_cooldown") * caster:GetCooldownReduction() / caster:IsGenocideMode(nil, true) / ((caster:HasModifier("modifier_fountain_aura_arena") or caster:HasModifier("modifier_filler_heal")) and 2 or 1)
    end

---------------------------------------------------------------------------------------------

    function modifier_sans_dodger:AllChargesReady()
        return self:GetStackCount() == self:GetAbility():GetSpecialValueFor("max_charges") + self.bonus_charges and true or false
    end
    function modifier_sans_dodger:DodgeCondition(isSpell)
        local parent = self:GetParent()
        return self:GetStackCount() >= self:GetAbility():GetSpecialValueFor("spell_dodge_cost") and not parent:IsStunned() and not parent:IsRooted() and not parent:IsHexed() and not parent:IsTaunted() and not parent:IsFeared()
    end

    modifier_sans_dodger.tick = 1 / 20
    function modifier_sans_dodger:OnCreated()
        local parent = self:GetParent()
        local ability = self:GetAbility()
        self.bonus_charges = 0
        parent:SetNetworkableEntityInfo("DodgerBonusCharges", self.bonus_charges)
        self.cooldown = ability:GetSpecialValueFor("charge_cooldown")
        self.cooldown_after_damage = ability:GetSpecialValueFor("cooldown_after_damage")
        self:SetStackCount(ability:GetSpecialValueFor("max_charges"))
        parent:SetNetworkableEntityInfo("MaxCharges", self.bonus_charges + self:GetStackCount())
        self:StartIntervalThink(self.tick)
    end

    function modifier_sans_dodger:OnIntervalThink()
        local ability = self:GetAbility()
        local parent = self:GetParent()

        if self:GetRemainingTime() <= 0 and not self:AllChargesReady() and parent:IsAlive() then
            ability:ModifyCharges(1)
        end

        parent:SetBaseManaRegen(0)
        parent:SetMana(self:GetStackCount())
        parent:SetMaxMana(ability:GetSpecialValueFor("max_charges") + self.bonus_charges)
    end

    function modifier_sans_dodger:GetAbsorbSpell(keys)
        local parent = self:GetParent()
        if parent:IsIllusion() then return end
        local originalAbility = keys.ability
        local ability = self:GetAbility()
        if originalAbility:GetCaster():GetTeam() == parent:GetTeam() then return end
        if self:DodgeCondition() then
            local distance = ability:GetSpecialValueFor("blink_distance")
            ability:ModifyCharges(-ability:GetSpecialValueFor("spell_dodge_cost"), true)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_EVADE, parent, 1, nil)
			SendOverheadEventMessage(originalAbility:GetCaster():GetPlayerOwner(), OVERHEAD_ALERT_MISS, parent, 1, parent:GetPlayerOwner())
            ability:Blink(parent, parent:GetAbsOrigin() + RandomVector(RandomInt(0, distance)))
            ParticleManager:SetParticleControlEnt(ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent), 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
            return 1
        end
        return 0
    end

    function modifier_sans_dodger:OnDeath(keys)
		local parent = self:GetParent()
		local ability = self:GetAbility()
        if (
			keys.attacker == parent and
			keys.unit:IsTrueHero() and
			parent:GetTeamNumber() ~= keys.unit:GetTeamNumber()
		) then
			self.bonus_charges = self.bonus_charges + ability:GetSpecialValueFor("charge_per_kill")
            parent:SetNetworkableEntityInfo("DodgerBonusCharges", self.bonus_charges)
            parent:SetNetworkableEntityInfo("MaxCharges", self.bonus_charges + ability:GetSpecialValueFor("max_charges"))
            ability:RefreshCharges(true)
		end
	end

    function modifier_sans_dodger:OnRespawn(k)
        if k.unit == self:GetParent() then
			self:SetStackCount(self:GetAbility():GetSpecialValueFor("max_charges") + self.bonus_charges)
		end
    end

    function modifier_sans_dodger:GetModifierHealthBonus()
        return -199 - math.floor(self:GetParent():GetStrength()) * (22)
    end
end

function modifier_sans_dodger:OnTooltip()
    return self:GetParent():GetNetworkableEntityInfo("MaxCharges")
end
function modifier_sans_dodger:OnTooltip2()
    return self:GetParent():GetNetworkableEntityInfo("DodgerBonusCharges")
end
function modifier_sans_dodger:GetModifierPercentageManacost()
    return 100
end
