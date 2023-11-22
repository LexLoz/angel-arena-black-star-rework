if not Attributes then
    Attributes = {}
end

function Attributes:RegenExeptions(parent, custom_regen)
    --fix percent regen
    --print(custom_regen)
    local amp = 0
    local allModifiers = parent:FindAllModifiers()
    for _, v in pairs(allModifiers) do
        if (v:GetName() == "modifier_sai_release_of_forge_final_regeneration") then
            custom_regen = custom_regen - v:GetModifierConstantHealthRegen()
        end
        if (v:GetName() == "modifier_sara_regeneration_active") then
            custom_regen = custom_regen - (v:GetModifierConstantHealthRegen() or v.Regen)
        end
        local declare
        if v.DeclareFunctions then
            declare = v:DeclareFunctions()
            local _hp_reg_pct = 0
            for _, i in ipairs(declare) do
                if i == MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE then
                    _hp_reg_pct = v
                        :GetModifierHealthRegenPercentage()
                end
            end
            custom_regen = custom_regen - _hp_reg_pct * parent:GetMaxHealth() * 0.01

            for _, i in ipairs(declare) do
                if i == MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE then
                    local prop = v:GetModifierHPRegenAmplify_Percentage() or 0
                    amp = amp + prop
                end
            end
        end
    end
    if FindItemInInventoryByName(parent, "item_heart", false, false, true) then
        custom_regen = custom_regen -
            (FindItemInInventoryByName(parent, "item_heart", false, false, true):GetSpecialValueFor("health_regen_pct") or 0) *
            parent:GetMaxHealth() * 0.01
    end
    for _, v in pairs(REGEN_EXEPTIONS) do
        local modifier = parent:FindModifierByName(v[1])
        if modifier then
            local hp_reg_pct
            local ability = modifier:GetAbility()
            if v[1] == "modifier_huskar_berserkers_blood" then
                hp_reg_pct = ability:GetSpecialValueFor(v[2]) * parent:GetStrength() * 0.01
                custom_regen = custom_regen - hp_reg_pct
            elseif ability then
                hp_reg_pct = ability:GetSpecialValueFor(v[2]) * parent:GetMaxHealth() * 0.01
                custom_regen = custom_regen - hp_reg_pct
            end
        end
    end
    --fix health regen amplify
    for _, v in pairs(HP_REGEN_AMP) do
        if FindItemInInventoryByName(parent, v[1], false, false, true) then
            local item = FindItemInInventoryByName(parent, v[1], false, false, true)
            amp = amp + item:GetSpecialValueFor(v[2])
        end
    end
    local regen = parent:GetHealthRegen()
    amp = math.max(1, 1 + amp * 0.01)
    regen = regen - regen / amp
    local HPRegenAmplify = parent.HpRegenAmp * parent:GetStrength()
    custom_regen = math.max(0, custom_regen - regen)
    return custom_regen * HPRegenAmplify
end

function Attributes:CalculateRegen(parent)
    --Timers:NextTick(function()
    --print('attributes: '..parent.HpRegenAmp)
    parent.HPRegenAmplify = 1 + parent.HpRegenAmp * parent:GetStrength()
    local custom_regen = parent:GetHealthRegen()
    parent.custom_regen = math.min(parent:GetMaxHealth() / 1, Attributes:RegenExeptions(parent, custom_regen))
    --end)
end

function Attributes:FountainFix(parent)
    --print("debug4")
    if not parent:IsAlive() then return end
    if parent:FindModifierByName("modifier_fountain_aura_arena") then
        parent:FindModifierByName("modifier_fountain_aura_arena"):Destroy()
        parent:AddNewModifier(parent, nil, "modifier_fountain_aura_arena", nil)
    else
        parent:AddNewModifier(parent, nil, "modifier_fountain_aura_arena", { not_on_fountain = true })
        parent:FindModifierByName("modifier_fountain_aura_arena"):Destroy()
    end
end

function Attributes:UpdateStrength(parent)
    if not parent then return end

    --strength crit
    if parent.FindModifierByName and parent:FindModifierByName("modifier_strength_crit") then
        local mod = parent:FindModifierByName("modifier_strength_crit")
        local multiplier
        local coeff = (parent:GetStrength()) / STRENGTH_CRIT_THRESHOLD

        if parent:GetPrimaryAttribute() == 0 and parent:GetNetworkableEntityInfo("BonusPrimaryAttribute0") and not mod._util then
            mod._util = true
            --mod.decrease_coeff = STRENGTH_CRIT_DECREASE_COEFF / 1.2
            mod.crit_mult = STRENGTH_CRIT_MULTIPLIER * 1.5
            mod._strength = (parent:GetStrength()) - 1
        elseif parent:GetPrimaryAttribute() == 0 and not parent:GetNetworkableEntityInfo("BonusPrimaryAttribute0") and mod._util then
            mod._util = false
            mod.crit_mult = STRENGTH_CRIT_MULTIPLIER
            --mod.decrease_coeff = STRENGTH_CRIT_DECREASE_COEFF
            mod._strength = (parent:GetStrength()) - 1
        end

        multiplier = (parent:GetStrength()) * mod.crit_mult

        -- if coeff >= 1 then
        --     local strength_diff = (parent:GetStrength()) - STRENGTH_CRIT_THRESHOLD
        --     multiplier = (STRENGTH_CRIT_THRESHOLD * mod.crit_mult) +
        --         (strength_diff * math.min(mod.crit_mult, mod.crit_mult / (coeff * mod.decrease_coeff)))
        -- else
        --     multiplier = (parent:GetStrength()) * mod.crit_mult
        -- end

        mod.strengthCriticalDamage = STRENGTH_BASE_CRIT + multiplier
        mod:SetStackCount(100 + math.round(mod.strengthCriticalDamage))
        parent:SetNetworkableEntityInfo("StrengthCritCooldown", mod:calculateCooldown())
        -- print(math.min(500, 100 + (mod:GetStackCount() - 100) / 3))
        parent:SetNetworkableEntityInfo("StrengthSpellCrit", 100 + (mod:GetStackCount() - 100) / 3)
    end

    --regen
    self:CalculateRegen(parent)

    parent:SetNetworkableEntityInfo("ReliableStr", parent:GetReliableStrength())
    parent:SetNetworkableEntityInfo("UnreliableStr", parent:GetUnreliableStrength())
    parent:SetNetworkableEntityInfo("BonusStr", parent:GetBonusStrength())

    self:UpdateDamage(parent)
end

function Attributes:UpdateAgility(parent)
    if parent.FindModifierByName and parent:FindModifierByName("modifier_agility_primary_bonus") then
        local mod = parent:FindModifierByName("modifier_agility_primary_bonus")
        mod.bonusAttacksCount = AGILITY_BONUS_ATTACKS_BASE_COUNT

        local base_requirement = mod.requirement
        local current_requirement = base_requirement
        local max_bonus_attacks = AGILITY_BONUS_ATTACKS_THRESHOULD
        mod.bonus_damage = parent:GetAgility() * AGILITY_BONUS_BONUS_DAMAGE

        if parent.GetPrimaryAttribute and parent:GetPrimaryAttribute() == 1 and parent:GetNetworkableEntityInfo("BonusPrimaryAttribute1") and not mod._util then
            mod._util = true
            mod.requirement = math.round(AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK / 4)
            mod.agility = (parent:GetAgility()) - 1
        elseif parent:GetPrimaryAttribute() == 1 and not parent:GetNetworkableEntityInfo("BonusPrimaryAttribute1") and mod._util then
            mod._util = false
            mod.requirement = AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK
            mod.agility = (parent:GetAgility()) - 1
        end

        for i = 1, math.round(parent:GetAgility()) do
            if i % current_requirement == 0 then
                mod.bonusAttacksCount = mod.bonusAttacksCount + 1
                if mod.bonusAttacksCount >= max_bonus_attacks then
                    base_requirement = math.round(base_requirement *
                        AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK_GROWTH_MULTIPLIER)
                    max_bonus_attacks = max_bonus_attacks + 1
                end
                current_requirement = current_requirement + base_requirement
            end
        end
        parent:SetNetworkableEntityInfo("bonus_attacks_requirement", base_requirement)
        parent:SetNetworkableEntityInfo("agility_for_next_bonus_attack", current_requirement)
        parent:SetNetworkableEntityInfo("AgilityBonusAttacksDamage", AGILITY_BONUS_BASE_DAMAGE + mod.bonus_damage)
        mod:SetStackCount(mod.bonusAttacksCount)
        if (parent:GetAgility()) <= 0 then
            mod.bonusAttacksCount = 1
        end
        if mod._bonusAttacksCount ~= mod.bonusAttacksCount then
            parent:SetNetworkableEntityInfo("AgilityBonusAttacks", mod.bonusAttacksCount)
            mod._bonusAttacksCount = mod.bonusAttacksCount
        end

        if mod._level ~= parent:GetLevel() then
            mod._level = parent:GetLevel()
            parent:SetNetworkableEntityInfo("AgilityBonusChance", mod:calculateChance())
        end
    end


    --damage multiplier
    parent.DamageMultiplier = 1 + (parent:GetAgility() * BASE_AGILITY_DAMAGE_AMPLIFY) * 0.01

    --custom base armor
    local agilityArmor = parent:GetAgility() * (AGILITY_ARMOR_BASE_COEFF)
    local unreliableArmor = parent:GetUnreliableAgility() * UNREABLE_AGILITY_ARMOR_COEFF
    -- print('GetUnreliableAgility: '..parent:GetUnreliableAgility())
    local agilityForArmor
    local agilityArmorCoeff = 1 / parent.AgilityArmorMultiplier
    --print(parent.AgilityArmorMultiplier)

    agilityForArmor = parent:GetReliableAgility() --+
    --((parent.Custom_AttributeBaseAgility or parent:GetKeyValue("AttributeBaseAgility")) / (agilityArmorCoeff / AGILITY_ARMOR_BASE_COEFF))

    if agilityForArmor < 0 then agilityForArmor = 0 end
    local newArmor = agilityForArmor * (agilityArmorCoeff)

    if newArmor < 0 then newArmor = 0 end
    if newArmor > AGILITY_MAX_BASE_ARMOR_COUNT then newArmor = AGILITY_MAX_BASE_ARMOR_COUNT end
    local evolution = parent:FindModifierByName("modifier_sara_evolution") and
        parent:FindModifierByName("modifier_sara_evolution"):GetAbility() or nil
    newArmor = newArmor + unreliableArmor
    local armor = (newArmor - agilityArmor) + parent:GetKeyValue("ArmorPhysical") +
        (evolution and evolution:GetAbilitySpecial("bonus_base_armor") or 0)
    --print(agilityForArmor)
    parent:SetPhysicalArmorBaseValue(armor)
    parent:SetNetworkableEntityInfo("IdealArmor", newArmor)
    --parent:SetNetworkableEntityInfo("AttributeBaseAgility", parent:GetBaseAgility())
    --print(newArmor)

    --custom attack speed
    local level_agility = CalculateStatForLevel(parent, DOTA_ATTRIBUTE_AGILITY, STAT_GAIN_LEVEL_LIMIT, true)
    local bonus_agility = math.min(RELIABLE_BONUS_STAT_LIMIT, parent:GetReliableAgility() - level_agility)
    local custom_as = math.max(0,
        bonus_agility * ATTACK_SPEED_PER_BONUS_AGILITY +
        level_agility *
        ATTACK_SPEED_PER_LEVEL_AGILITY)

    --print(level_agility)
    if custom_as > AGILITY_MAX_ATTACK_SPEED_COUNT then custom_as = AGILITY_MAX_ATTACK_SPEED_COUNT end
    --print(custom_as)
    custom_as = math.min(700, custom_as + parent:GetUnreliableAgility() * (1 / 200))
    parent:SetNetworkableEntityInfo("ReturnedAttackSpeed", -parent:GetAgility() + custom_as)
    parent:SetNetworkableEntityInfo("AgilityAttackSpeed", custom_as)

    --stamina

    local stamina = parent:FindModifierByName("modifier_stamina")

    if stamina then
        stamina:UpdateMaxStamina(parent, STAMINA_PER_AGILITY * parent:GetAgility())
    end

    parent:SetNetworkableEntityInfo("ReliableAgi", parent:GetReliableAgility())
    parent:SetNetworkableEntityInfo("UnreliableAgi", parent:GetUnreliableAgility())
    parent:SetNetworkableEntityInfo("BonusAgi", parent:GetBonusAgility())

    self:UpdateDamage(parent)
end

function Attributes:UpdateIntelligence(parent)
    local unrel_int = parent:GetUnreliableIntellect()
    local rel_int = parent:GetIntellect() - unrel_int
    local resist = math.min(25, rel_int * 0.05) + math.min(25, unrel_int * (1 / 4000))
    parent:SetNetworkableEntityInfo("MagResist", resist)
    parent:SetBaseMagicalResistanceValue((parent.Custom_MagicalResist or 25) + resist)

    Attributes:UpdateManaRegen(parent)

    parent:SetNetworkableEntityInfo("ReliableInt", parent:GetReliableIntellect())
    parent:SetNetworkableEntityInfo("UnreliableInt", parent:GetUnreliableIntellect())
    parent:SetNetworkableEntityInfo("BonusInt", parent:GetBonusIntellect())

    self:UpdateDamage(parent)
end

function Attributes:UpdateManaRegen(parent)
    local ManaRegenAmp = parent:GetIntellect() * parent.ManaRegAmpPerInt

    if not parent.GetEnergy and not parent:HasModifier("modifier_filler_heal") and not parent:HasModifier("modifier_fountain_aura_arena") then
        local custom_regen = parent:GetManaRegen()

        parent.custom_mana_regen = custom_regen * ManaRegenAmp
        parent:SetNetworkableEntityInfo("ManaRegen",
            (__toFixed(parent:GetManaRegen() + (parent.custom_mana_regen or 0), 1)))
        parent:SetNetworkableEntityInfo("ManaRegenAmplify", 1 + (ManaRegenAmp or 0))
    elseif parent.GetEnergy then
        parent:SetNetworkableEntityInfo("ManaRegenAmplify", 1 + (ManaRegenAmp or 0))
    end
end

function Attributes:UpdateDamage(parent)
    --damage
    local unreliable_damage = parent:GetUnreliableBaseDamage()
    parent:SetNetworkableEntityInfo("CustomBaseDamage",
        unreliable_damage)

    local reliable_str = (parent:GetStrength() - parent:GetUnreliableStrength() -
            CalculateStatForLevel(parent, DOTA_ATTRIBUTE_STRENGTH, STAT_GAIN_LEVEL_LIMIT) +
            CalculateStatForLevel(parent, DOTA_ATTRIBUTE_STRENGTH, 600) + parent:GetUnreliableStrength() * DAMAGE_PER_UNRELIABLE_STAT) *
        parent.BaseDamagePerStrength
    local reliable_agi = (parent:GetAgility() - parent:GetUnreliableAgility() -
            CalculateStatForLevel(parent, DOTA_ATTRIBUTE_AGILITY, STAT_GAIN_LEVEL_LIMIT) +
            CalculateStatForLevel(parent, DOTA_ATTRIBUTE_AGILITY, 600) + parent:GetUnreliableAgility() * DAMAGE_PER_UNRELIABLE_STAT) *
        parent.BaseDamagePerStrength
    local reliable_int = (parent:GetIntellect() - parent:GetUnreliableIntellect() -
            CalculateStatForLevel(parent, DOTA_ATTRIBUTE_INTELLECT, STAT_GAIN_LEVEL_LIMIT) +
            CalculateStatForLevel(parent, DOTA_ATTRIBUTE_INTELLECT, 600) + parent:GetUnreliableIntellect() * DAMAGE_PER_UNRELIABLE_STAT) *
        parent.BaseDamagePerStrength
    local reliable_uni = (reliable_str + reliable_agi + reliable_int) * DAMAGE_PER_ATTRIBUTE_FOR_UNIVERSALES

    local primary_attribute = parent:GetPrimaryAttribute()
    local primary_stat_value = primary_attribute == 3 and
        (parent:GetStrength() + parent:GetAgility() + parent:GetIntellect()) * DAMAGE_PER_ATTRIBUTE_FOR_UNIVERSALES or
        parent:GetPrimaryStatValue()

    local damage_min = parent.Custom_AttackDamageMin or parent:GetKeyValue("AttackDamageMin")
    local damage_max = parent.Custom_AttackDamageMax or parent:GetKeyValue("AttackDamageMax")

    if primary_attribute == 0 then
        damage_min = damage_min + reliable_str
        damage_max = damage_max + reliable_str
        --print('str')
        parent:SetNetworkableEntityInfo("BaseDamagePerStr", reliable_str)
        parent.BaseDamagePerStr = reliable_str
    else
        parent:SetNetworkableEntityInfo("BaseDamagePerStr", 0)
        parent.BaseDamagePerStr = 0
    end
    if primary_attribute == 1 then
        damage_min = damage_min + reliable_agi
        damage_max = damage_max + reliable_agi
        --print('agi')
        parent:SetNetworkableEntityInfo("BaseDamagePerAgi", reliable_agi)
        parent.BaseDamagePerAgi = reliable_agi
    else
        parent:SetNetworkableEntityInfo("BaseDamagePerAgi", 0)
        parent.BaseDamagePerAgi = 0
    end
    if primary_attribute == 2 then
        damage_min = damage_min + reliable_int
        damage_max = damage_max + reliable_int
        --print('int')
        parent:SetNetworkableEntityInfo("BaseDamagePerInt", reliable_int)
        parent.BaseDamagePerInt = reliable_int
    else
        parent:SetNetworkableEntityInfo("BaseDamagePerInt", 0)
        parent.BaseDamagePerInt = 0
    end
    if primary_attribute == 3 then
        damage_min = damage_min + reliable_uni
        damage_max = damage_max + reliable_uni
        parent:SetNetworkableEntityInfo("BaseDamagePerUni",
            reliable_uni)
        parent.BaseDamagePerUni =
            reliable_uni
    else
        parent:SetNetworkableEntityInfo("BaseDamagePerUni", 0)
        parent.BaseDamagePerUni = 0;
    end

    parent:SetBaseDamageMin(damage_min + unreliable_damage - primary_stat_value)
    parent:SetBaseDamageMax(damage_max + unreliable_damage - primary_stat_value)

    parent:SetNetworkableEntityInfo("BaseDamageMin", parent:GetBaseDamageMin())
    parent:SetNetworkableEntityInfo("BaseDamageMax", parent:GetBaseDamageMax())

    parent:SetNetworkableEntityInfo("BonusAgilityDamage", CalculateAttackDamage(parent, parent))
    parent:SetNetworkableEntityInfo('ReliableDamage', parent:GetReliableDamage())
end

function Attributes:UpdateDamageMultipliers(parent)
    local attacker = parent
    local addictive_multiplier = 0
    for k, v in pairs(ON_ADDICTIVE_DAMAGE_MODIFIER_PROCS) do
        if attacker:HasModifier(k) then
            -- print(k)
            addictive_multiplier = addictive_multiplier + (v.addictive_multiplier(attacker) - 1)
        end
    end
    -- print('addictive_multiplier: '..addictive_multiplier)
    attacker.addictive_multiplier = addictive_multiplier
end

--------------------------------------------------------------------------

function Attributes:UpdateGoldMultiplier(parent, modifier, bonus_gold)
    -- print(parent:GetName())
    if modifier and modifier:GetAbility() ~= nil then
        local value = modifier:GetAbility():GetSpecialValueFor("bonus_gold_pct")
        -- print(modifier:GetName() .. ', ' .. value)
        if value ~= 0 then
            bonus_gold = (bonus_gold or 0) + value
            parent.bonus_gold_pct = bonus_gold
        end
    end
    return bonus_gold
end

function Attributes:CheckExeptionsInModifiersForStamina(parent, modifier, returned_value)
    -- print(parent:GetName())
    if modifier and modifier:GetAbility() ~= nil then
        local value = modifier:GetAbility():GetSpecialValueFor("stamina_drain_reduction")
        -- print(modifier:GetName() .. ', ' .. value)
        if value ~= 0 then
            returned_value = (returned_value or 1) * (1 - value * 0.01)
            parent.decrease_stamina_cost_mult = returned_value
        end
    end
    return returned_value
end

function Attributes:CheckModifiers(parent)
    local modifiers = parent:FindAllModifiers()
    local value1
    local value2
    parent.bonus_gold_pct = 0
    parent.decrease_stamina_cost_mult = 1
    for _, modifier in ipairs(modifiers) do
        value1 = self:UpdateGoldMultiplier(parent, modifier, value1)
        value2 = self:CheckExeptionsInModifiersForStamina(parent, modifier, value2)
    end
end

-------------------------------------------------------------------------

function Attributes:UpdateStaminaCost(parent)
    if Options:GetValue("DisableStamina") then return 0 end
    local stamina = parent:FindModifierByName('modifier_stamina')
    if not stamina then return end

    STAMINA_HEROES_CONSUMPTION_EXEPTIONS = {
        npc_arena_hero_saitama = 0,
        npc_arena_hero_shinobu = 33,
        npc_arena_hero_sans = 200,
        --npc_dota_hero_life_stealer = true,
        npc_dota_hero_tiny = 0,
        npc_dota_hero_sniper = 40,
        npc_dota_hero_gyrocopter = 30,
    }

    local unreliable_damage = parent:GetAverageTrueAttackDamage(self) -
        parent:GetReliableDamage() -
        (parent:GetBonusDamage() > 1000 and
            parent:GetBonusDamage() - 1000 or 0)

    local bonus_damage = parent:GetBonusDamage()
    for k, _ in pairs(RELIABLE_DAMAGE_MODIFIERS) do
        if parent:HasItemInInventory(k) then
            bonus_damage = bonus_damage - GetAbilitySpecial(k, "bonus_damage")
        end
    end
    bonus_damage = bonus_damage - (parent.FeastBonusDamage or 0) - (parent.PiercingBladeBonusDamage or 0) -
    (parent.SoulcutterBonusDamage or 0)
    unreliable_damage = unreliable_damage +
        (bonus_damage > 1000 and
            bonus_damage - 1000 or 0)

    local decrease_cost_multiplier = parent.decrease_stamina_cost_mult *
        (parent:HasModifier('modifier_arena_rune_tripledamage') and 0.1 or 1)

    local exeptions = 1
    local name = parent:GetFullName()
    if STAMINA_HEROES_CONSUMPTION_EXEPTIONS[name] then
        exeptions = STAMINA_HEROES_CONSUMPTION_EXEPTIONS[name] * 0.01
        if type(exeptions) == "boolean" then exeptions = 0 end
    end

    local cost = unreliable_damage * STAMINA_DAMAGE_PERCENT_IN_STAMINA_CONSUMPTION * 0.01 * decrease_cost_multiplier *
        exeptions
    stamina.cost = cost
    parent:SetNetworkableEntityInfo("StaminaPerHit",
        math.min(100, cost /
            parent:GetMaxStamina() * 100))
end

function Attributes:UpdateSpellDamage(parent)
    local mind_stone = parent:FindModifierByName("modifier_mind_stone")
    local mind_stone_mult = 0
    if mind_stone then
        mind_stone = mind_stone:GetAbility()
        mind_stone_mult = mind_stone:GetSpecialValueFor("bonus_spell_damage")
    end
    local agility_mult = ((parent.DamageMultiplier or 1) - 1) * 100
    local spell_mult = 1 + (parent:GetSpellAmplification(false) or 0)
    parent:SetNetworkableEntityInfo("SpellAmp",
        agility_mult *
        spell_mult +
        mind_stone_mult * spell_mult * (1 + agility_mult * 0.01))
    parent:SetNetworkableEntityInfo('InstakillResistance', math.min(100, math.floor(parent:GetInstakillResist())))
end

function Attributes:UpdateAll(parent, timer)
    if parent and not parent._cooldown then
        parent._cooldown = true
        Timers:CreateTimer(timer or 0, function()
            parent._cooldown = false
            self:CheckModifiers(parent)
            -- print('bonus gold pct: ' .. parent.bonus_gold_pct)
            -- print('decrease stamina cost mult: ' .. parent.decrease_stamina_cost_mult)
            self:UpdateStrength(parent)
            self:UpdateAgility(parent)
            self:UpdateIntelligence(parent)
            self:UpdateDamageMultipliers(parent)
            self:UpdateStaminaCost(parent)
        end)
    end
end

function Attributes:RemoveStats(parent, pct)
    local add_str = parent.Additional_str or 0
    local add_agi = parent.Additional_agi or 0
    local add_int = parent.Additional_int or 0
    parent:ModifyStrength(-add_str * pct * 0.01)
    parent:ModifyAgility(-add_agi * pct * 0.01)
    parent:ModifyIntellect(-add_int * pct * 0.01)
    parent.Additional_str = add_str - add_str * pct * 0.01
    parent.Additional_agi = add_agi - add_agi * pct * 0.01
    parent.Additional_int = add_int - add_int * pct * 0.01

    Attributes:UpdateAll(parent)
end
