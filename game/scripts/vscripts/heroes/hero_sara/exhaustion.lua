LinkLuaModifier("modifier_sara_exhaustion", "heroes/hero_sara/exhaustion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_exhaustion_helper", "heroes/hero_sara/exhaustion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_exhaustion_debuff", "heroes/hero_sara/exhaustion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sara_exhaustion_buff", "heroes/hero_sara/exhaustion.lua", LUA_MODIFIER_MOTION_NONE)

sara_exhaustion = class({
    GetIntrinsicModifierName = function() return "modifier_sara_exhaustion" end,
})

function sara_exhaustion:CheckEvolution()
    local parent = self:GetCaster()
    local evolution = parent:FindAbilityByName("sara_evolution_new")
    if evolution and self:GetLevel() == 7 then
        return evolution:GetLevel()
    else
        return 1
    end
end

function sara_exhaustion:GetCooldown(iLevel)
    return self:CheckEvolution() >= 3 and self:GetSpecialValueFor("evolution_lvl3_cooldown") or self.BaseClass.GetCooldown(self, iLevel)
end

modifier_sara_exhaustion = class({
    IsHidden   = function() return true end,
	IsPurgable = function() return false end,
    DeclareFunctions = function() return {MODIFIER_EVENT_ON_ATTACK_LANDED} end,
})

modifier_sara_exhaustion_helper = class({
    IsHidden   = function() return true end,
	IsPurgable = function() return true end,
    IsDebuff   = function() return true end,
    RemoveOnDeath = function() return true end,
})

modifier_sara_exhaustion_debuff = class({
    IsHidden   = function() return false end,
	IsPurgable = function() return true end,
    IsDebuff   = function() return true end,
    RemoveOnDeath = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_TOOLTIP,
    } end,
    GetEffectName = function() return "particles/arena/units/heroes/hero_sai/divine_flesh.vpcf" end,
})
function modifier_sara_exhaustion_debuff:OnTooltip()
    return self:GetStackCount()
end
function modifier_sara_exhaustion_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed_reduce")
end
function modifier_sara_exhaustion_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_speed_reduce")
end
function modifier_sara_exhaustion_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduce")
end

modifier_sara_exhaustion_buff = class({
    IsHidden   = function() return false end,
	IsPurgable = function() return false end,
    IsDebuff   = function() return false end,
    RemoveOnDeath = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_TOOLTIP
    } end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
})
function modifier_sara_exhaustion_buff:OnTooltip()
    return self:GetStackCount()
end

if IsServer() then
	function sara_exhaustion:OnUpgrade()
		if self:GetLevel() == 1 then
			self:ToggleAutoCast()
		end
	end

    function modifier_sara_exhaustion:OnAttackLanded(keys)
        local parent = self:GetParent()
		local ability = self:GetAbility()
		if (
			keys.attacker == parent and
			parent.GetEnergy and
			(ability:GetAutoCastState() or parent:GetCurrentActiveAbility() == ability)
		) then
            local unit = keys.target
			if ability:PerformPrecastActions() then
                if not unit:IsIllusion() and not unit:IsMagicImmune() and not unit:IsDebuffImmune() then
                    local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sara/space_dissection.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
				    ParticleManager:SetParticleControlEnt(pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
				    ParticleManager:SetParticleControlEnt(pfx, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetOrigin(), true)
				    ParticleManager:SetParticleControlEnt(pfx, 5, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetOrigin(), true)
				    unit:EmitSound("Hero_Centaur.DoubleEdge")

                    if not unit:FindModifierByName("modifier_sara_exhaustion_helper") then
                        local modifier = unit:AddNewModifier(parent, ability, "modifier_sara_exhaustion_helper", {duration = ability:GetAbilitySpecial("duration")})
                        modifier:SetStackCount(1)
                    else
                        local modifier = unit:FindModifierByName("modifier_sara_exhaustion_helper")
                        modifier:SetStackCount(modifier:GetStackCount() + 1)
                        modifier:SetDuration(modifier:GetDuration() +  ability:GetAbilitySpecial("duration"), true)
                    end
                else
                    ability:EndCooldown()
                end
            end
        end
    end

    function modifier_sara_exhaustion_helper:OnCreated(keys)
        self._tick = 0

        local parent = self:GetCaster()
        local unit = self:GetParent()
        local ability = self:GetAbility()

        self.soul_particle = "particles/units/heroes/hero_nevermore/nevermore_necro_souls.vpcf"

        local modifiers = parent:FindAllModifiersByName("modifier_sara_exhaustion_buff")
        if modifiers then
            for _,v in pairs(modifiers) do
                if v:GetCaster() == unit then
                    self.modifier_bonus = v
                end
            end
            if not self.modifier_bonus then
                self.modifier_bonus = parent:AddNewModifier(unit, ability, "modifier_sara_exhaustion_buff", nil)
            end
        else
            self.modifier_bonus = parent:AddNewModifier(unit, ability, "modifier_sara_exhaustion_buff", nil)
        end

        if not unit:FindModifierByName("modifier_sara_exhaustion_debuff") then
            self.modifier_debuff = unit:AddNewModifier(parent, ability, "modifier_sara_exhaustion_debuff", nil)
        else
            self.modifier_debuff = unit:FindModifierByName("modifier_sara_exhaustion_debuff")
        end
        self:StartIntervalThink(1)
    end
    function modifier_sara_exhaustion_helper:OnIntervalThink()
        self._tick = self._tick + 1

        local ability = self:GetAbility()
        local bonus = self.modifier_bonus
        local debuff = self.modifier_debuff

        local stacks = self:GetStackCount() or 0
        if stacks == 0 then self:Destroy() end
        if self._tick % ability:GetAbilitySpecial("duration") == 0 then self:SetStackCount(stacks - 1) end

        local parent_pos = self:GetCaster():GetAbsOrigin()
        local target_pos = self:GetParent():GetAbsOrigin()

        if (parent_pos - target_pos):Length2D() > ability:GetAbilitySpecial("distance") then
            self:Destroy()
        end

        local value = ability:GetAbilitySpecial("health_decrease") * stacks

        if debuff then
            debuff:SetStackCount((debuff:GetStackCount() or 0) + value)
            if ability:CheckEvolution() >= 2 then
                value = math.ceil(ability:GetAbilitySpecial("health_decrease_pct") * debuff:GetParent():GetHealth() * 0.01)
                debuff:SetStackCount((debuff:GetStackCount() or 0) + value)
            end
        end

        if (not debuff:GetParent():IsBoss() and not debuff:GetParent():IsJungleBear())
        and
        bonus and
        bonus.SetStackCount and
        bonus.GetStackCount then
            bonus:SetStackCount(math.ceil((bonus:GetStackCount() or 0) + value * ability:GetAbilitySpecial("health_in_energy_pct") * 0.01))
        end

        ProjectileManager:CreateTrackingProjectile(self:CreateProjectileTable(self:GetCaster(), self:GetParent(), ability))
    end
    function modifier_sara_exhaustion_helper:CreateProjectileTable(parent, unit, ability)
		return {Target = parent, Source = unit, Ability = ability,EffectName = self.soul_particle, bDodgeable = false,bProvidesVision = true, iVisionRadius =  50, iMoveSpeed = self.projectile_speed, iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION}
	end
-----------------------------------------------------------------------------------------
    function modifier_sara_exhaustion_buff:OnCreated(keys)
        self.duration = self:GetAbility():GetAbilitySpecial("effect_delay")
        self:StartIntervalThink(1 / 30)
    end
    function modifier_sara_exhaustion_buff:OnIntervalThink()
        if self:GetStackCount() == 0 and self:GetDuration() > 0 then self:Destroy() end
        
        local parent = self:GetParent()
        local target = self:GetCaster()
        local ability = self:GetAbility()

        local pos1 = parent:GetAbsOrigin()
        local pos2 = target:GetAbsOrigin()
        local distance = (pos1 - pos2):Length2D() > ability:GetAbilitySpecial("distance")

        if self._d then self.duration = self:GetRemainingTime() end

        if not target:IsAlive() then
            self:SetDuration(self.duration, true)
            return
        end

        if distance and not self._d then
            self:SetDuration(self.duration, true)
            self._d = true
        elseif not distance and self._d then
            self:SetDuration(-1, true)
            self._d = false
        end
    end
    function modifier_sara_exhaustion_buff:OnStackCountChanged(oldStacks)
        local parent = self:GetParent()
        local stacks = self:GetStackCount()
        parent.BonusEnergy = parent.BonusEnergy - oldStacks + stacks
        parent:ModifyEnergy(-oldStacks + stacks, true, true)
    end
    function modifier_sara_exhaustion_buff:OnDestroy()
        local parent = self:GetParent()
        local stacks = self:GetStackCount()
        parent.BonusEnergy = parent.BonusEnergy - stacks
        parent:ModifyEnergy(-stacks)
    end
----------------------------------------------------------------------------------
    function modifier_sara_exhaustion_debuff:OnCreated(keys)
        self.duration = self:GetAbility():GetAbilitySpecial("effect_delay")
        self:StartIntervalThink(1 / 30)
    end
    function modifier_sara_exhaustion_debuff:GetModifierAttackSpeedBonus_Constant()
        return self:GetAbility():GetAbilitySpecial("attack_speed_reduce")
    end
    function modifier_sara_exhaustion_debuff:GetModifierMoveSpeedBonus_Percentage()
        return self:GetAbility():GetAbilitySpecial("movement_speed_reduce")
    end
    function modifier_sara_exhaustion_debuff:GetModifierPhysicalArmorBonus()
        return self:GetAbility():GetAbilitySpecial("armor_reduce")
    end
    function modifier_sara_exhaustion_debuff:OnStackCountChanged(oldStacks)
        local parent = self:GetParent()
        if parent:IsBoss() then return end
        local stacks = self:GetStackCount()
        parent:SetHealth(math.max(parent:GetHealth() + oldStacks - stacks, 1))
    end
    function modifier_sara_exhaustion_debuff:OnIntervalThink()
        local parent = self:GetParent()
        local pos1 = parent:GetAbsOrigin()
        local pos2 = self:GetCaster():GetAbsOrigin()
        local ability = self:GetAbility()
        local distance = (pos1 - pos2):Length2D() > ability:GetAbilitySpecial("distance")

        if not parent:IsBoss() and parent:GetHealth() > parent:GetMaxHealth() - self:GetStackCount() then
            parent:SetHealth(math.max(parent:GetMaxHealth() - self:GetStackCount(), 1))
        end

        if self._d then self.duration = self:GetRemainingTime() end

        if distance and not self._d then
            self:SetDuration(self.duration, true)
            self._d = true
        elseif not distance and self._d then
            self:SetDuration(-1, true)
            self._d = false
        end
    end
end