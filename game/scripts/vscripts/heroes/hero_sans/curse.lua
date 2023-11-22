LinkLuaModifier("modifier_sans_curse_passive", "heroes/hero_sans/curse.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sans_curse", "heroes/hero_sans/curse.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sans_curse_aura", "heroes/hero_sans/curse.lua", LUA_MODIFIER_MOTION_NONE)


sans_curse = class({
    GetIntrinsicModifierName = function() return "modifier_sans_curse_passive" end
})

function sans_curse:GetBehavior()
    return self:GetCaster():GetNetworkableEntityInfo('HasKarmaTalent') and
        DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_TOGGLE or
        DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function sans_curse:OnToggle()
end

if IsServer() then
    function sans_curse:OnCreated()
        print('karma owner spawned')
        if not self.first_spawn then
            self.first_spawn = true

            local parent = self:GetCaster()

            Timers:CreateTimer(function()
                for i = 0, parent:GetAbilityCount() - 1 do
                    local ability = parent:GetAbilityByIndex(i)

                    if ability and ability:GetLevel() == 0 and not IsUltimateAbility(ability) and ability:GetAbilityName() ~= "sans_ketchup" then
                        ability:SetLevel(1)
                    end
                end
            end)
        end
    end
end

modifier_sans_curse_passive = class({
    IsPurgable         = function() return false end,
    RemoveOnDeath      = function() return false end,
    IsHidden           = function() return true end,
    DestroyOnExpire    = function() return false end,
    GetAttributes      = function() return MODIFIER_ATTRIBUTE_PERMANENT end,

    IsAura             = function() return true end,
    GetAuraRadius      = function() return 99999 end,
    GetModifierAura    = function() return "modifier_sans_curse_aura" end,
    GetAuraSearchTeam  = function() return DOTA_UNIT_TARGET_TEAM_ENEMY end,
    GetAuraSearchType  = function() return DOTA_UNIT_TARGET_HERO end,
    GetAuraSearchFlags = function()
        return
            DOTA_UNIT_TARGET_FLAG_INVULNERABLE +
            DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO +
            DOTA_UNIT_TARGET_FLAG_DEAD +
            DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED +
            DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
    end,

    DeclareFunctions   = function()
        return {
        }
    end
})

modifier_sans_curse = class({
    IsPurgable                           = function() return false end,
    RemoveOnDeath                        = function() return true end,
    IsHidden                             = function() return false end,
    GetAttributes                        = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
    GetModifierHPRegenAmplify_Percentage = function() return -99999 end,
    DeclareFunctions                     = function()
        return {
            MODIFIER_PROPERTY_TOOLTIP,
            -- MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE
        }
    end
})

modifier_sans_curse_aura = class({
    IsHidden         = function() return false end,
    RemoveOnDeath    = function() return false end,
    IsPurgable       = function() return false end,

    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_DEATH,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end
})

function modifier_sans_curse_aura:OnTooltip()
    return self:GetParent():GetNetworkableEntityInfo('KarmaSins')
end

if IsServer() then
    function modifier_sans_curse_aura:UpdateKarmaPercent()
        local ability = self:GetAbility()
        local parent = self:GetParent()
        local player = parent:GetPlayerID()
        local pct_per_creep = ability:GetSpecialValueFor("damage_per_killed_creep_pct")
        local pct_per_hero = ability:GetSpecialValueFor("damage_per_killed_hero_pct")
        local pct_per_assist = ability:GetSpecialValueFor("damage_per_assist_pct")

        if player then
            local unit_killed_creeps = PlayerResource:GetNearbyCreepDeaths(player)
            local unit_killed_heroes = PlayerResource:GetKills(player)
            local unit_assists = PlayerResource:GetAssists(player)

            local curse_pct = (unit_killed_creeps * pct_per_creep + unit_killed_heroes * pct_per_hero + unit_assists * pct_per_assist)
            parent:SetNetworkableEntityInfo('KarmaSins', unit_killed_creeps + unit_killed_heroes + unit_assists)
            self:SetStackCount(curse_pct - parent.carma_redeemed_sins)
        end
    end

    function modifier_sans_curse_aura:OnCreated()
        self:GetParent().carma_redeemed_sins = self:GetParent().carma_redeemed_sins or 0
        self:UpdateKarmaPercent()
    end

    function modifier_sans_curse_aura:OnDeath(keys)
        local parent = self:GetParent()
        if keys.attacker == parent then
            self:UpdateKarmaPercent()
        end
        if keys.unit == parent then
            parent:RemoveModifierByName('modifier_sans_curse')
        end
    end

    function modifier_sans_curse_aura:GetModifierIncomingDamageConstant(keys)
        local ability = self:GetAbility()
        local caster = ability:GetCaster()
        local unit = self:GetParent()
        local talent = caster:HasTalent("talent_hero_comic_sans_karma_aura")
        local stacks = self:GetStackCount()
        local curse = unit:FindModifierByName("modifier_sans_curse")
        if keys.target ~= unit then return end
        if not curse and stacks < 100 then return end

        local function conditionHelper()
            return talent and
                (ability:GetToggleState() and keys.attacker:IsHero() and keys.attacker:GetTeam() == caster:GetTeam()) or
                keys.attacker == caster
        end

        local curse_mult = 2 + stacks * 0.01
        local curse_damage = keys.damage

        if not curse then
            -- local inflictor = keys.inflictor
            -- if inflictor then
            --     local inflictorname = inflictor:GetAbilityName()
            --     if inflictor and ATTACK_DAMAGE_ABILITIES[inflictorname] then
            --         curse_damage = keys.damage + keys.attacker:GetReliableDamage() * curse_mult
            --     elseif type(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) == "string" then
            --         local value = inflictor:GetSpecialValueFor(SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS[inflictorname]) *
            --             curse_mult
            --         curse_damage = keys.damage + value * curse_mult
            --     elseif (inflictor and NeedSpellAmpCondition(inflictor, inflictorname, keys.attacker, keys.damage_flags)) then
            --         curse_damage = keys.damage + keys.damage / (keys.attacker.DamageMultiplier or 1) * curse_mult
            --     elseif not inflictor then
            --         curse_damage = keys.attacker:GetReliableDamage() * curse_mult
            --     end
            -- end

            if stacks >= 100 and conditionHelper() then
                curse_damage = keys.damage * curse_mult
                self:SetStackCount(stacks - 100)
                unit.carma_redeemed_sins = (unit.carma_redeemed_sins or 0) + 100

                unit:AddNewModifier(caster, ability, "modifier_sans_curse", {
                    curse_damage = math.min(unit:GetMaxHealth(), curse_damage),
                })
                unit:EmitSound("Arena.Hero_Sans.Dodger.Curse_Damage")
                return unit:GetHealth() == 1 and 1 or -keys.damage
            end
        else
            curse.curse_damage = (curse.curse_damage or 0) + (curse_damage * 2)
            local interval = curse:CalculateInterval()
            curse:StartIntervalThink(interval)
            unit:EmitSound("Arena.Hero_Sans.Dodger.Curse_Damage")
            return unit:GetHealth() == 1 and 1 or -keys.damage
        end
    end
end

if IsServer() then
    function modifier_sans_curse_passive:OnDestroy()
        local parent = self:GetParent()
        local ability = self:GetAbility()
        if ability then
            Timers:NextTick(function()
                parent:AddNewModifier(parent, ability, "modifier_sans_curse_passive", nil)
            end)
        end
    end

    function modifier_sans_curse:CalculateInterval()
        self.interval = math.min(math.max(self.min_interval, 5 / self.curse_damage), self.max_interval)
        --print(self.interval)
        return self.interval
    end

    function modifier_sans_curse:OnCreated(keys)
        local ability = self:GetAbility()
        if not ability then
            self:Destroy()
            return
        end
        self.curse_damage = keys.curse_damage
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
        local ability = self:GetAbility()
        local parent = self:GetParent()
        local caster = ability:GetCaster()

        if self.curse_damage <= 0 or not parent:IsAlive() or not ability then
            self:Destroy()
            return
        end

        if self.interval == self.min_interval then
            local multiplier = self.min_interval / (5 / self.curse_damage)
            local carma_damage = 1 * (multiplier)
            self.curse_damage = self.curse_damage - carma_damage
            self:SetStackCount(self.curse_damage)
            ApplyInevitableDamage(
                caster,
                parent,
                ability,
                carma_damage,
                false
            )
            parent:EmitSound("Arena.Hero_Sans.Dodger.Curse_Damage")
        else
            self.curse_damage = self.curse_damage - 1
            self:SetStackCount(self.curse_damage)
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
            self:StartIntervalThink(self:CalculateInterval())
        end
    end
end
function modifier_sans_curse:OnTooltip()
    return self:GetStackCount()
end
