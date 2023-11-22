modifier_agility_bonus_attacks = class({
	IsPurgable    = function() return false end,
    IsHidden      = function() return true end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end
})

function modifier_agility_bonus_attacks:DeclareFunctions()
    return { 
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
    }
end

if IsServer() then
    function modifier_agility_bonus_attacks:OnCreated(keys)
        local parent = self:GetParent()
        self.Pos = parent:GetAbsOrigin()
        self.target = keys.target
        self._tick = 0
        self.tick = keys.attack_rate
        self.bonus_damage = keys.bonus_damage
        self:StartIntervalThink(self.tick)
    end

    function modifier_agility_bonus_attacks:OnIntervalThink()
        --for k in pairs(keys) do print(k) end
        self._tick = self._tick + 1
        if not self.target then return end
        local parent = self:GetParent()
        local target = self.target
        local enemyPos = target:GetAbsOrigin()
        local pos = parent:GetAbsOrigin()

        if parent:PassivesDisabled() then
            self:Destroy()
            return
        end

        if (pos - self.Pos):Length2D() >= DISTANCE_DIFFERENCE_FOR_CANCEL_ATACKS then
            self:Destroy()
        elseif self._tick % (4 / self.tick) == 0 then
            self.Pos = pos
        end

        if not target:IsAlive() then self:Destroy() end
        
        if parent:Script_GetAttackRange() + 100 >= (pos - enemyPos):Length2D() and parent:IsAlive() and target:IsAlive() and not parent:IsStunned() and not parent:IsHexed() and not parent:IsDisarmed() then
            --self.Damage = parent:GetAgility() * AGILITY_BONUS_BONUS_DAMAGE
            local orb = false
            if parent:GetPrimaryAttribute() == 1 and parent:GetNetworkableEntityInfo("BonusPrimaryAttribute1") then
                orb = true
            end
            local attack_damage = parent:GetAverageTrueAttackDamage(parent)
            local increased_damage = parent:GetReliableDamage() * (self.bonus_damage * 0.01)
            parent.bonus_attack = (AGILITY_BONUS_BASE_DAMAGE - 100) + ((increased_damage + attack_damage) / attack_damage * 100 - 100)
            -- print('bonus attacks: '..(parent.bonus_attack))
            PerformGlobalAttack(parent, target, true, true, true, false, false, false, false)
            parent.bonus_attack = nil
            --self.Damage = 0
        else
            self:Destroy()
        end
    end

    function modifier_agility_bonus_attacks:OnAttackCancelled(keys)
        if keys.attacker == self:GetParent() then
            self:Destroy()
        end
    end
    function modifier_agility_bonus_attacks:GetModifierDamageOutgoing_Percentage()
        return self:GetParent().bonus_attack --+ (self.Damage or 0)
    end
end