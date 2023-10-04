sans_blaster = class({})

function sans_blaster:GetVectorTargetRange()
    return self:GetSpecialValueFor("ray_length")
end

function sans_blaster:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING
end

if IsServer() then
    function sans_blaster:GetCastPoint()
        return self:GetCaster():IsGenocideMode() and 0 or 0.2
    end
    function sans_blaster:OnVectorCastStart(vStartLocation, vDirection)
        local caster = self:GetCaster()

        local dodger = caster:FindAbilityByName("sans_dodger")
        local cost = self:GetSpecialValueFor("charges_cost")

        if dodger:ModifyCharges() < cost then
            self:EndCooldown()
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_error_no_charges")
            return
        else
            dodger:ModifyCharges(-cost)
        end

        if caster:IsGenocideMode() then
            self:EndCooldown()
        end

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
                                damage = damage,
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
