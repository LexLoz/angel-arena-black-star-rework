LinkLuaModifier("modifier_sara_regeneration", "heroes/hero_sara/regeneration.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_regeneration_active", "heroes/hero_sara/regeneration.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_regeneration_bonus_health", "heroes/hero_sara/regeneration.lua", LUA_MODIFIER_MOTION_NONE)

sara_regeneration = class({
    GetIntrinsicModifierName = function() return "modifier_sara_regeneration" end
})

function sara_regeneration:CheckEvolution()
    local parent = self:GetCaster()
    local evolution = parent:FindAbilityByName("sara_evolution_new")
    if evolution and self:GetLevel() == 7 then
        return evolution:GetLevel()
    else
        return 1
    end
end

function sara_regeneration:GetCooldown(level)
	return self:CheckEvolution() >= 3 and self:GetSpecialValueFor("cooldown") or 0
end

function sara_regeneration:GetBehavior()
	return self:CheckEvolution() >= 3 and DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST or DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function sara_regeneration:OnSpellStart()
    local caster = self:GetCaster()
    local bonus = self:GetSpecialValueFor("energy_in_health") * caster:GetMana() * 0.01
    caster:AddNewModifier(caster, self, "modifier_sara_regeneration_bonus_health", {duration = self:GetSpecialValueFor("duration"), bonus_health = bonus })
    caster:ModifyEnergy(-bonus)
end

function sara_regeneration:OnUpgrade()
    if not IsServer() then return end
    if self:GetLevel() == 1 then
        self:ToggleAutoCast()
    end
end

modifier_sara_regeneration = class({
	IsHidden   = function() return true end,
	IsPurgable = function() return false end,
})
modifier_sara_regeneration_active = class({
	IsHidden   = function() return false end,
	IsPurgable = function() return false end,
    RemoveOnDeath = function() return true end,
    DeclareFunctions = function() return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT} end
})
modifier_sara_regeneration_bonus_health = class({
    IsHidden   = function() return false end,
	IsPurgable = function() return false end,
    RemoveOnDeath = function() return true end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions = function() return {MODIFIER_PROPERTY_HEALTH_BONUS} end,
})

if IsServer() then
    function modifier_sara_regeneration_active:GetModifierConstantHealthRegen()
        return self:GetStackCount()
    end
    function modifier_sara_regeneration_active:OnCreated(keys)
        local parent = self:GetParent()
        if parent.GetEnergy then
            parent:EmitSound("Hero_Chen.HandOfGodHealHero")
            ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sara/fragment_of_logic.vpcf", PATTACH_ABSORIGIN, parent)
    
            self.tick = 0.1
            self.Regen = keys.regen_const
            self:SetStackCount(self.Regen)
            self.cost = keys.cost * self.tick
            self.tick = 0.1
    
            self:StartIntervalThink(self.tick)
        end
    end
    function modifier_sara_regeneration_active:OnIntervalThink()
        local parent = self:GetParent()
        local ability = self:GetAbility()

        if not (ability.GetAutoCastState and ability:GetAutoCastState()) then self:Destroy() end

        self.cost = self:GetStackCount() * ability:GetAbilitySpecial("energy_cost_pct") * 0.01 * self.tick

        if self.cost <= parent:GetMana() then
            parent:ModifyEnergy(-self.cost)
        elseif self.cost then
            self:Destroy()
        end

        if parent:GetHealth() == parent:GetMaxHealth() then self:Destroy() end
    end

    function modifier_sara_regeneration_bonus_health:OnCreated(keys)
        self.BonusHealth = keys.bonus_health
        self:SetStackCount(self.BonusHealth)
    end
    function modifier_sara_regeneration_bonus_health:OnDestroy()
        self:GetParent():ModifyEnergy(self.BonusHealth, true, true)
    end
    function modifier_sara_regeneration_bonus_health:GetModifierHealthBonus()
        return self:GetStackCount() or 0
    end

    function modifier_sara_regeneration:OnCreated()
        self.tick = 0.1
        self._tick = 0
        self.delay = false
        self.timers = {}
    
        self:StartIntervalThink(self.tick)
    end
    function modifier_sara_regeneration:OnIntervalThink()
        self._tick = self._tick + 1

        local parent = self:GetParent()
        local ability = self:GetAbility()

        if not (ability.GetAutoCastState and ability:GetAutoCastState()) then return end

        if ability:CheckEvolution() == 1 and parent:GetHealth() < parent:GetMaxHealth() and not self.delay then
            self:StartTimer(ability:GetSpecialValueFor("delay"))
        end

        if ability:CheckEvolution() >= 2 and parent:GetHealth() < parent:GetMaxHealth() and self._tick % 1 == 0 then
            local regen = math.min(parent:GetHealth() * ability:GetAbilitySpecial("max_regen_pct") * 0.01, parent:GetMana() * ability:GetAbilitySpecial("energy_in_regen") * 0.01)
            local cost = regen * ability:GetAbilitySpecial("energy_cost_pct") * 0.01
            if parent:HasModifier("modifier_sara_regeneration_active") then
                parent:FindModifierByName("modifier_sara_regeneration_active"):SetStackCount(regen)
            else
                parent:AddNewModifier(parent, ability, "modifier_sara_regeneration_active", {duration = -1, regen_const = regen, cost = cost, level = 2})
            end
        end
    end
    function modifier_sara_regeneration:StartTimer(delay)
        self.delay = true
        local parent = self:GetParent()
        local ability = self:GetAbility()
        local timer_index = #self.timers + 1
        self.timers[timer_index] = Timers:CreateTimer(delay, function()
            if (ability.GetAutoCastState and ability:GetAutoCastState()) then Timers:RemoveTimer(self.timers[timer_index]) end
			if parent:GetHealth() == parent:GetMaxHealth() then
                --print("remove regen timer")
                Timers:RemoveTimer(self.timers[timer_index])
                self.delay = false
            else
                --print("start regen")
                if ability:CheckEvolution() == 1 then
                    local missing_health = parent:GetMaxHealth() - parent:GetHealth()
                    local cost = missing_health * ability:GetAbilitySpecial("energy_cost_pct") * 0.01
                    if cost >= parent:GetMana() then
                        cost = parent:GetMana()
                        missing_health = cost / (ability:GetAbilitySpecial("energy_cost_pct") * 0.01)
                    end
                    local duration = missing_health / ability:GetAbilitySpecial("health_in_second")
                    parent:AddNewModifier(parent, ability, "modifier_sara_regeneration_active", {duration = duration, regen_const = missing_health / duration, cost = cost / duration})
                    self.delay = false
                    Timers:RemoveTimer(self.timers[timer_index])
                end
            end
		end)
    end
else
    function modifier_sara_regeneration:OnCreated()
        -- self.tick = 0.1
        -- self._tick = 0
        -- self.delay = false
        -- self.timers = {}
    
        -- self:StartIntervalThink(self.tick)
    end

    function modifier_sara_regeneration_active:GetModifierConstantHealthRegen()
        return self:GetStackCount()
    end
    function modifier_sara_regeneration_active:OnCreated(keys)
        -- local parent = self:GetParent()
        -- parent:EmitSound("Hero_Chen.HandOfGodHealHero")
        -- ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sara/fragment_of_logic.vpcf", PATTACH_ABSORIGIN, parent)

        -- self.tick = 0.1
        -- self.Regen = keys.regen_const
        -- self:SetStackCount(self.Regen)
        -- self.tick = 0.1

        -- self:StartIntervalThink(self.tick)
    end
    function modifier_sara_regeneration_bonus_health:GetModifierHealthBonus()
        return self:GetStackCount()
    end
end