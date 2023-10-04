function DamageStartCooldown(keys)
    local attacker = keys.attacker
    if keys.Damage > 0 and ((attacker.IsControllableByAnyPlayer and attacker:IsControllableByAnyPlayer()) or attacker:IsBoss()) then
        keys.ability:AutoStartCooldown()
        local modififer = keys.caster:FindModifierByName("modifier_item_heavy_war_axe_of_rage_regen")
        if modififer then
            keys.caster:RemoveModifierByName("modifier_item_heavy_war_axe_of_rage_regen")
        end
    end
end

function UpdateCooldownModifiers(keys)
    if keys.ability:IsCooldownReady() then
        local modififer = keys.caster:FindModifierByName("modifier_item_heavy_war_axe_of_rage_regen")
        if not modififer then
            keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_item_heavy_war_axe_of_rage_regen", nil)
        end
    end
end