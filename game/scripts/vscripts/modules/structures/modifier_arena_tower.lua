modifier_arena_tower = class({})
function modifier_arena_tower:IsHidden() return true end

function modifier_arena_tower:IsPurgable() return false end

function modifier_arena_tower:DestroyOnExpire() return false end

function modifier_arena_tower:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_arena_tower:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true,
        [MODIFIER_STATE_STUNNED] = false,
    }
end

function modifier_arena_tower:GetPriority()
    return 9999
end

-- if IsClient() then
--     function modifier_arena_tower:GetModifierIncomingDamageConstant(keys)
--         return self:GetParent():GetHealth()
--     end
-- end

if IsServer() then
    function modifier_arena_tower:GetModifierIncomingDamageConstant(keys)
        local attacker = keys.attacker
        local tower = self:GetParent()
        if tower ~= keys.target then return end
        local attackRange = tower:Script_GetAttackRange()
        if attacker:IsTrueHero() then
            if (attacker:GetAbsOrigin() - tower:GetAbsOrigin()):Length2D() >= attackRange or attacker.bonus_attack then
                return -keys.damage
            else
                return -keys.damage + 1
            end
        else
            return -keys.damage
        end
    end

    function modifier_arena_tower:OnCreated()
        local tower = self:GetParent()
        self:StartIntervalThink(0.1)
        self:SetDuration(60, true)
        self.teamNumber = tower:GetTeamNumber()
        -- print('tower init')

        tower:SetBaseMaxHealth(TOWER_HEALTH_BASE)
        tower:SetMaxHealth(TOWER_HEALTH_BASE)

        Timers:CreateTimer(function()
            tower:Purge(false, true, false, true, true)
            return 0.1
        end)

        self.tower_rage_time = RandomInt(TOWER_RAGE_TIMING - 2, TOWER_RAGE_TIMING + 2)
    end

    function modifier_arena_tower:OnIntervalThink()
        local tower = self:GetParent()
        if self:GetRemainingTime() <= 0 then
            tower:SetBaseMaxHealth(tower:GetBaseMaxHealth() + TOWER_HEALTH_GROWTH)
            tower:SetMaxHealth(tower:GetMaxHealth() + TOWER_HEALTH_GROWTH)
            tower:SetHealth(tower:GetHealth() + TOWER_HEALTH_GROWTH)
            tower:SetBaseDamageMin(tower:GetBaseDamageMin() + TOWER_DAMAGE_GROWTH)
            tower:SetBaseDamageMax(tower:GetBaseDamageMax() + TOWER_DAMAGE_GROWTH)
            self:SetDuration(60, true)
        end

        if GetDOTATimeInMinutesFull() >= self.tower_rage_time and not tower.boss_armor then
            local team = self:GetParent():GetTeamNumber()
            local localizedTeam = Teams.Data[team].name2
            local notification1 = "#arena_tower_rage1"
            local notification2 = "#arena_tower_rage2"
            local notification3 = "#arena_tower_rage3"

            Notifications:TopToAll({ text = notification1, duration = 6 })
            Notifications:TopToAll({ text = localizedTeam, continue = true })
            Notifications:TopToAll({ text = notification2, continue = true })
            Notifications:TopToAll({ text = notification3,  duration = 6 })

            tower.boss_armor = tower:AddAbility("boss_armor")
            if tower.boss_armor then
                tower.boss_armor:SetLevel(1)
            end

            EmitGlobalSound("Arena.Items.FleshPotion.Cast")
        end
    end

    function modifier_arena_tower:OnAttackLanded(keys)
        local parent = self:GetParent()
        local victim = keys.target

        if victim:IsHero() and parent == keys.attacker then
            ApplyInevitableDamage(parent,
                victim,
                nil,
                victim:GetHealth() * TOWER_PERCENT_DAMAGE * 0.01,
                true)

            victim:AddNewModifier(parent, nil, "modifier_arena_tower_disable_healing",
                {
                    duration = GetDOTATimeInMinutesFull() >= self.tower_rage_time and TOWER_DEBUFF_DURATION_IN_RAGE or
                    TOWER_DEBUFF_DURATION })
        end
    end

    function modifier_arena_tower:OnDeath(keys)
        if self:GetParent() ~= keys.unit then return end

        local team = self:GetParent():GetTeamNumber()
        local localizedTeam = Teams.Data[team].name2
        local notification1 = "#arena_kill_weight_increase_after_kill_struct_notifiaction1"
        local notification2 = "#arena_kill_weight_increase_after_kill_struct_notifiaction2"
        Teams:ChangeKillWeight(team, 2)
        Notifications:TopToAll({ text = notification1, duration = 6 })
        Notifications:TopToAll({ text = localizedTeam, continue = true })
        Notifications:TopToAll({ text = notification2, continue = true })
        Notifications:TopToAll({ text = "ㅤ" .. " 2", continue = true })

        if keys.attacker:GetTeamNumber() ~= team and keys.attacker:IsTrueHero() then
            Gold:AddGoldWithMessage(keys.attacker, 10000 + Gold:GetGold(keys.attacker:GetPlayerOwnerID()) * 0.5)
        end
    end
end

modifier_arena_tower_disable_healing = class({})
function modifier_arena_tower_disable_healing:IsHidden() return false end

function modifier_arena_tower_disable_healing:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_arena_tower_disable_healing:CheckState()
    return {
        [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    }
end

function modifier_arena_tower_disable_healing:GetModifierMoveSpeedBonus_Percentage()
    return -30
end

function modifier_arena_tower_disable_healing:GetDisableHealing()
    return 1
end
