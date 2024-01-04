LinkLuaModifier("modifier_sans_blaster", "heroes/hero_sans/blaster.lua", LUA_MODIFIER_MOTION_NONE)

modifier_sans_blaster = class({
    IsHidden         = function() return true end,
    IsPurgable       = function() return false end,
    RemoveOnDeath    = function() return false end,
    DestroyOnExpire  = function() return false end,
    GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        }
    end,
})

sans_blaster = class({
    GetIntrinsicModifierName = function() return "modifier_sans_blaster" end,
})
sans_blaster.IsCustomVectorTargeting = true

function sans_blaster:GetVectorTargetRange()
    return self:GetSpecialValueFor("ray_length")
end

function sans_blaster:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING
end

if IsServer() then
    function modifier_sans_blaster:OnAbilityFullyCast(keys)
        local ability = self:GetAbility()
        if keys.ability ~= ability then return end

        local caster = self:GetCaster()

        local dodger = caster:FindAbilityByName("sans_dodger")
        local cost = ability:GetSpecialValueFor("charges_cost")

        if dodger:ModifyCharges() < cost then
            ability:EndCooldown()
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_error_no_charges")
            return
        else
            dodger:ModifyCharges(-cost)
        end

        if caster:IsGenocideMode() then
            ability:EndCooldown()
        end
    end

    function sans_blaster:GetCastPoint()
        return self:GetCaster():IsGenocideMode() and 0 or 0.2
    end

    function sans_blaster:OnVectorCastStart(vStartLocation, vDirection)
        local caster = self:GetCaster()

        local startpoint = self:GetCursorPosition()
        startpoint.z = GetGroundHeight(startpoint, nil) + 64
        local endpoint = startpoint +
            vDirection * ((self:GetVectorTargetRange() + caster:GetCastRangeBonus()) * caster:IsGenocideMode(self))
        endpoint.z = GetGroundHeight(endpoint, nil) + 64
        local width = self:GetSpecialValueFor("ray_width") * caster:IsGenocideMode(self)

        local interval = 1
        local abilityDamage = self:GetAbilityDamageType()
        local duration = self:GetSpecialValueFor("duration")
        local delay = self:GetSpecialValueFor("delay")
        local damage = (self:GetSpecialValueFor("damage") --[[* caster:IsGenocideMode(self)]]) --/ duration
        local talent_damage = (caster:GetTalentSpecial("talent_hero_comic_sans_blaster_percent_damage", "percent_damage") or 0)
        local affectedUnits = {}

        Timers:NextTick(function()
            EmitSoundOnLocationWithCaster(startpoint, "Arena.Hero_Sans.Blaster.Start", caster)
            Timers:CreateTimer(delay, function()
                EmitSoundOnLocationWithCaster(startpoint, "Arena.Hero_Sans.Blaster.End", caster)
                local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sans/gaster_blaster.vpcf",
                    PATTACH_WORLDORIGIN, caster)
                ParticleManager:SetParticleControl(pfx, 0, startpoint)
                ParticleManager:SetParticleControl(pfx, 1, endpoint)
                ParticleManager:SetParticleControl(pfx, 4, Vector(width))

                Timers:CreateTimer(function()
                    for _, v in ipairs(FindUnitsInLine(caster:GetTeam(), startpoint, endpoint, nil, width, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())) do
                        if not affectedUnits[v] then
                            affectedUnits[v] = true
                            ApplyDamage({
                                victim = v,
                                attacker = caster,
                                damage = damage + v:GetMaxHealth() * talent_damage * 0.01,
                                damage_type = abilityDamage,
                                ability = self
                            })
                        end
                    end
                    if pfx then return 0.1 end
                end)
                Timers:CreateTimer(duration, function()
                    ParticleManager:DestroyParticle(pfx, false)
                    pfx = nil
                end)
            end)
        end)
    end
end
