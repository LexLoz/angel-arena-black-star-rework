ModuleRequire(..., "data")

ABILITIES_LIST = {}
table.deepmerge(ABILITIES_LIST, LoadKeyValues("scripts/npc/npc_abilities_custom.txt"))
table.deepmerge(ABILITIES_LIST, LoadKeyValues("scripts/npc/npc_items_custom.txt"))
table.deepmerge(ABILITIES_LIST, LoadKeyValues("scripts/npc/npc_abilities_override.txt"))

function SetSubtypeValue(subtypes_table, subtype, value)
    if subtype == "DAMAGE_SUBTYPE_SOUND" then
        subtypes_table[subtype] = value
        return subtypes_table
    end
    if subtype == "DAMAGE_SUBTYPE_BLOOD" then
        subtypes_table[subtype] = value
        return subtypes_table
    end
    if subtypes_table[subtype] then
        return subtypes_table
    else
        subtypes_table[subtype] = value
        return subtypes_table
    end
end

function DamageSubtypesFilter(inflictor, attacker, victim, damage)
    if not victim:IsTrueHero() then return damage end
    --print(inflictor:GetDamageSubType())
    local resist = victim:GetElementalResist(inflictor:GetDamageSubType())
    if resist and resist < 100 then
        damage = damage - damage * resist * 0.01
        return damage
    elseif resist and not victim:IsIllusion() then
        victim:Heal(damage, nil)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, victim, damage, nil)
        ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW,
            victim)
        return 0
    end
    return damage
end

UNITS_LIST = {}
function InitDamageSubtypes()
    for k, v in pairs(ABILITIES_LIST) do
        if v.AbilityUnitDamageSubType then
            --print(k..", "..v.AbilityUnitDamageSubType)
            CustomNetTables:SetTableValue("ability_damage_subtypes", k, { _ = v.AbilityUnitDamageSubType })
        end
    end

    table.deepmerge(UNITS_LIST, LoadKeyValues("scripts/npc/npc_heroes_custom.txt"))
    table.deepmerge(UNITS_LIST, LoadKeyValues("scripts/npc/heroes/new.txt"))
    for k, v in pairs(UNITS_LIST) do
        v.DamageSubtypeResistance = v.DamageSubtypeResistance or {}
        v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_SOUND", -25)
        v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_BLOOD", -25)

        if ALL_ELEMENTS_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_FIRE = 25
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_WATER = 25
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_EARTH = 25
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_AIR = 25
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHTING = 25
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_ICE = 25
        end
        if FIRE_TEMPLATE[k] and not WATER_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_FIRE = FIRE_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_WATER = -25
        elseif FIRE_TEMPLATE[k] and WATER_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_FIRE = FIRE_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_WATER = WATER_TEMPLATE[k]
        end

        if AIR_TEMPLATE[k] and not FIRE_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_AIR = AIR_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_FIRE = -25
        elseif AIR_TEMPLATE[k] and FIRE_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_AIR = AIR_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_FIRE = FIRE_TEMPLATE[k]
        end

        if EARTH_TEMPLATE[k] and not ICE_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_EARTH = EARTH_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_ICE = -25
        elseif EARTH_TEMPLATE[k] and ICE_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_EARTH = EARTH_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_ICE = ICE_TEMPLATE[k]
        end

        if WATER_TEMPLATE[k] and not LIGHTING_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_WATER = WATER_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHTING = -25
        elseif WATER_TEMPLATE[k] and LIGHTING_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_WATER = WATER_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHTING = LIGHTING_TEMPLATE[k]
        end

        if LIGHTING_TEMPLATE[k] and not EARTH_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHTING = LIGHTING_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_EARTH = -25
        elseif LIGHTING_TEMPLATE[k] and EARTH_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHTING = LIGHTING_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_EARTH = EARTH_TEMPLATE[k]
        end

        if ICE_TEMPLATE[k] and not AIR_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_ICE = ICE_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_AIR = -25
        elseif ICE_TEMPLATE[k] and AIR_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_ICE = ICE_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_AIR = AIR_TEMPLATE[k]
        end

        if DARK_TEMPLATE[k] and not LIGHT_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_DARK = DARK_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHT = -25
        elseif DARK_TEMPLATE[k] and LIGHT_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_DARK = DARK_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHT = LIGHT_TEMPLATE[k]
        end

        if LIGHT_TEMPLATE[k] and not DARK_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHT = LIGHT_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_DARK = -25
        elseif LIGHT_TEMPLATE[k] and DARK_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_LIGHT = LIGHT_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_DARK = DARK_TEMPLATE[k]
        end

        if NATURE_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_NATURE = 100
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_TECH = 50
        end

        if VOID_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_VOID = VOID_TEMPLATE[k]
        end

        if BLOOD_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_BLOOD = BLOOD_TEMPLATE[k]
        end

        if POISON_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_POISON = POISON_TEMPLATE[k]
        end

        if TECH_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_TECH = TECH_TEMPLATE[k]
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_WATER = -25
        end

        if ENERGY_TEMPLATE[k] then
            v.DamageSubtypeResistance.DAMAGE_SUBTYPE_ENERGY = ENERGY_TEMPLATE[k]
        end








        if not COSMICAL_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_VOID", -25)
        else
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_FIRE", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_WATER", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_EARTH", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_AIR", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHTING", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DARK", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHT", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_BLOOD", 50)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_SOUND", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_TECH", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_ENERGY", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DEATH", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_VOID", 99)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_ICE", 30)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_NATURE", 30)
        end
        if GOD_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_FIRE", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_WATER", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_EARTH", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_AIR", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHTING", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DARK", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHT", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_BLOOD", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_SOUND", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_TECH", -25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_ENERGY", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DEATH", 75)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_ICE", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_NATURE", 25)
        end
        if DEMON_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DARK", 50)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHT", -25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DEATH", 50)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_BLOOD", 50)
        end
        if BEAST_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_EARTH", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_NATURE", 25)
        end
        if HUMAN_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", -25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHT", 25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_TECH", 25)
        end
        if ELEMENTAL_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_BLOOD", 99)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", 99)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_TECH", -25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_NATURE", 50)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DEATH", 75)
        end
        if UNDEAD_TEMPLATE[k] then
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_FIRE", -25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DARK", 50)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_LIGHT", -25)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_BLOOD", 99)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_POISON", 100)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DEATH", 100)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_ICE", 90)
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_NATURE", -25)
        else
            v.DamageSubtypeResistance = SetSubtypeValue(v.DamageSubtypeResistance, "DAMAGE_SUBTYPE_DEATH", -25)
        end

        CustomNetTables:SetTableValue("units_subtypes_resistance", k, v.DamageSubtypeResistance)
        --table = v.DamageSubtypeResistance
        --[[for t,n in pairs(v.DamageSubtypeResistance) do
            --print(t..", "..n)
            table[t] = n
        end]]
    end
end
