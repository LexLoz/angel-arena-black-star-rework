LinkLuaModifier("modifier_sans_curse_passive", "heroes/hero_sans/curse.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sans_curse", "heroes/hero_sans/curse.lua", LUA_MODIFIER_MOTION_NONE)

sans_curse = class({
    GetIntrinsicModifierName = function() return "modifier_sans_curse_passive" end
})

modifier_sans_curse_passive = class({
    IsPurgable       = function() return false end,
    RemoveOnDeath    = function() return false end,
    IsHidden         = function() return false end,
    DestroyOnExpire  = function() return false end,
    GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end
})

modifier_sans_curse = class({
    IsPurgable       = function() return false end,
    RemoveOnDeath    = function() return true end,
    IsHidden         = function() return false end,
    GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
    DeclareFunctions = function() return { MODIFIER_PROPERTY_TOOLTIP } end
})

function modifier_sans_curse_passive:OnTooltip()
    return self:GetStackCount()
end

if IsServer() then
    function modifier_sans_curse_passive:OnCreated()
        local parent = self:GetParent()

        Timers:CreateTimer(1, function()
            for i = 0, parent:GetAbilityCount() - 1 do
                local ability = parent:GetAbilityByIndex(i)

                if ability and ability:GetLevel() == 0 and not IsUltimateAbility(ability) and ability:GetAbilityName() ~= "sans_ketchup" then
                    ability:SetLevel(1)
                end
            end
        end)
    end

    function modifier_sans_curse_passive:OnDestroy()
        local parent = self:GetParent()
        local ability = self:GetAbility()
        Timers:NextTick(function()
            parent:AddNewModifier(parent, ability, "modifier_sans_curse_passive", nil)
        end)
    end

    function modifier_sans_curse_passive:OnTakeDamage(keys)
        local parent = self:GetParent()
        local ability = self:GetAbility()
        local unit = keys.unit
        local talent = self:GetCaster():HasTalent("talent_hero_comic_sans_karma_aura")

        local function KarmaProceed(isNotOwner)
            if isNotOwner and (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > 1200 then
                return
            end
            local player = unit:GetPlayerID()
            local pct_per_creep = ability:GetSpecialValueFor("damage_per_killed_creep_pct")
            local pct_per_hero = ability:GetSpecialValueFor("damage_per_killed_hero_pct")
            local pct_per_assist = ability:GetSpecialValueFor("damage_per_assist_pct")

            local unit_killed_creeps = PlayerResource:GetNearbyCreepDeaths(player)
            local unit_killed_heroes = PlayerResource:GetKills(player)
            local unit_assists = PlayerResource:GetAssists(player)

            local curse_pct = (unit_killed_creeps * pct_per_creep + unit_killed_heroes * pct_per_hero + unit_assists * pct_per_assist) *
                (isNotOwner and 0.5 or parent:IsGenocideMode(ability))
            curse_pct = curse_pct + 100
            local curse_mult = curse_pct * 0.01
            local curse_damage = keys.damage * curse_mult

            local inflictor = keys.inflictor
            local inflictorname = inflictor:GetAbilityName()
            if inflictor and ATTACK_DAMAGE_ABILITIES[inflictorname] then
                curse_damage = keys.damage + keys.attacker:GetReliableDamage() * curse_mult
            elseif type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) == "string" then
                local value = inflictor:GetSpecialValueFor(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) * curse_mult
                curse_damage = keys.damage + value
            elseif (inflictor and FilterDamageSpellAmpCondition(inflictor, inflictorname, keys.attacker, keys.damage_flags)) then
                curse_damage = keys.damage * curse_mult
            elseif not inflictor then
                curse_damage = keys.damage + keys.attacker:GetReliableDamage() * curse_mult
            end
            if not isNotOwner then
                self:SetStackCount(math.round(curse_pct) - 100)
            end
            unit:EmitSound("Arena.Hero_Sans.Dodger.Curse_Damage")

            local curse = unit:FindModifierByName("modifier_sans_curse")
            if not curse then
                local mod = unit:AddNewModifier(parent, ability, "modifier_sans_curse", {
                    curse_damage = curse_damage,
                    curse_pct = curse_pct - 100
                })
            else
                curse.curse_damage = curse.curse_damage + curse_damage
                curse.curse_pct = curse_pct - 100
                local interval = curse:CalculateInterval()
                curse:StartIntervalThink(interval)
            end

            --[[local percent = unit:GetHealth() / unit:GetMaxHealth() * 100
            if curse and percent <= 1 then
                unit:RemoveModifierByName("modifier_sans_curse")
                ApplyDamage({
                    victim = unit,
                    attacker = keys.attacker,
                    damage =  unit:GetMaxHealth(),
                    damage_type = DAMAGE_TYPE_HP_REMOVAL,
                    ability = self
                })
            end]]
        end


        if keys.attacker == parent and (unit:GetTeam() ~= parent:GetTeam() and unit:IsTrueHero() and unit:IsControllableByAnyPlayer()) then
            KarmaProceed()
        elseif talent and keys.attacker ~= parent and (unit:GetTeam() ~= parent:GetTeam() and unit:IsTrueHero() and unit:IsControllableByAnyPlayer()) then
            KarmaProceed(true)
        else
            self:SetStackCount(0)
        end
    end

    function modifier_sans_curse:CalculateInterval()
        self.interval = math.min(math.max(self.min_interval, 5 / self.curse_damage), self.max_interval)
        --print(self.interval)
        return self.interval
    end

    function modifier_sans_curse:OnCreated(keys)
        --print(self:GetRemainingTime())
        local ability = self:GetAbility()
        self.curse_damage = keys.curse_damage
        self.curse_pct = keys.curse_pct
        self.total_damage = 0
        self.min_interval = ability:GetSpecialValueFor("min_interval")
        self.max_interval = ability:GetSpecialValueFor("max_interval")
        self.color = self:GetParent():GetRenderColor()

        self:GetParent():SetRenderColor(165, 0, 255)
        self:StartIntervalThink(self:CalculateInterval())
    end

    function modifier_sans_curse:OnDestroy()
        local color = self.color
        self:GetParent():SetRenderColor(color.x, color.y, color.z)
        self:GetParent():StopSound("Arena.Hero_Sans.Dodger.Curse_Damage")
    end

    function modifier_sans_curse:OnIntervalThink()
        local parent = self:GetParent()

        if self.curse_damage <= 0 or not parent:IsAlive() then
            self:Destroy()
            return
        end

        local ability = self:GetAbility()
        local caster = ability:GetCaster()

        -- local limit = parent:GetMaxHealth() - (self.curse_damage / (1 + self.curse_pct * 0.01))
        -- --print("health: "..parent:GetHealth())
        -- --print("limit :"..limit)
        -- if parent:GetHealth() >= limit then
        --     local difference = parent:GetHealth() - limit
        --     --print('difference: '..difference)
        --     parent:SetHealth(math.max(parent:GetHealth() - difference, 1))
        --     self.curse_damage = self.curse_damage - math.floor(difference)
        --     --print("curse_damage: "..self.curse_damage)
        --     return
        -- end

        if self.interval == self.min_interval then
            local multiplier = self.min_interval / (5 / self.curse_damage)
            self.curse_damage = self.curse_damage - 1 * multiplier
            ApplyInevitableDamage(
                caster,
                parent,
                ability,
                1 * multiplier,
                false
            )
            parent:EmitSound("Arena.Hero_Sans.Dodger.Curse_Damage")
        else
            self.curse_damage = self.curse_damage - 1
            ApplyInevitableDamage(
                caster,
                parent,
                ability,
                1,
                false
            )
            parent:EmitSound("Arena.Hero_Sans.Dodger.Curse_Damage")
        end

        parent:SetNetworkableEntityInfo("KarmaDamage", self.curse_damage)

        if __toFixed(self.interval, 2) ~= __toFixed(self:CalculateInterval(), 2) then
            --print('interval')
            self:StartIntervalThink(self:CalculateInterval())
        end
    end
end
function modifier_sans_curse:OnTooltip()
    return self:GetParent():GetNetworkableEntityInfo("KarmaDamage")
end
