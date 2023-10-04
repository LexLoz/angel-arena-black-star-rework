function OnCreated(keys)
    local caster = keys.caster
    local bonus_agility = caster:GetAgility() * keys.BonusAgility * 0.01
    caster:SetBaseAgility(caster:GetBaseAgility() + bonus_agility)
    caster.Butterfly_BonusAgility = bonus_agility
    Timers:NextTick(function()
        Attributes:UpdateStrength(caster)
        Attributes:UpdateAgility(caster)
    end)
end

function OnDestroy(keys)
    local caster = keys.caster
    caster:SetBaseAgility(caster:GetBaseAgility() - caster.Butterfly_BonusAgility)
    caster.Butterfly_BonusAgility = nil
    Timers:NextTick(function()
        Attributes:UpdateStrength(caster)
        Attributes:UpdateAgility(caster)
    end)
end