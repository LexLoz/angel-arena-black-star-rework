LinkLuaModifier("modifier_sans_ketchup", "heroes/hero_sans/ketchup.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sans_last_breath", "heroes/hero_sans/ketchup.lua", LUA_MODIFIER_MOTION_NONE)

sans_ketchup = class({
    GetIntrinsicModifierName = function() return "modifier_sans_ketchup" end
})

modifier_sans_last_breath = class({
    IsDebuff        = function()  return false end,
    IsHidden        = function()  return false end,
    IsPurgable      = function()  return false end,
    RemoveOnDeath   = function()  return true end,
    DestroyOnExpire = function()  return true end,
    GetAttributes   = function()  return  MODIFIER_ATTRIBUTE_PERMANENT end,
    CheckState      = function()
	    return {
		    [MODIFIER_STATE_INVULNERABLE] = true,
		    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
		    [MODIFIER_STATE_UNTARGETABLE] = true,
            [MODIFIER_STATE_ATTACK_IMMUNE] = true,
		    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_STUNNED] = true
	    }
    end,
    DeclareFunctions = function()  return MODIFIER_PROPERTY_DISABLE_HEALING end,
    GetDisableHealing = function() return 1 end,
})

modifier_sans_ketchup = class({
    IsHidden        = function()  return true end,
    IsPurgable      = function()  return false end,
    RemoveOnDeath   = function()  return false end,
    DestroyOnExpire = function()  return false end,
    GetAttributes   = function()  return  MODIFIER_ATTRIBUTE_PERMANENT end,
    DeclareFunctions = function() return {
            MODIFIER_EVENT_ON_RESPAWN,
            MODIFIER_PROPERTY_MIN_HEALTH,
            MODIFIER_EVENT_ON_TAKEDAMAGE
        }
    end
})

if IsServer() then
    function modifier_sans_ketchup:OnTakeDamage(keys)
		local parent = keys.unit
        local ability = self:GetAbility()
		if keys.damage > 0 and ability:IsCooldownReady() and parent == self:GetParent() and parent:GetHealth() <= 1 and not parent:IsIllusion() and ability:IsActivated() then
            local dodger = parent:FindModifierByName("modifier_sans_dodger")
            dodger:SetDuration(999, false)
            local duration = ability:GetSpecialValueFor("duration")
			parent:AddNewModifier(parent, ability, "modifier_sans_last_breath", {
                duration = duration
            })
            local anim_duration = 4.6
            StartAnimation(parent, {duration=anim_duration, activity=ACT_DOTA_DIE})
            Timers:CreateTimer(anim_duration - 0.2, function()
                FreezeAnimation(parent, duration - anim_duration)
            end)
            parent:EmitSound("Arena.Hero_Sans.Last_Breath")
            parent:Purge(false, true, false, true, true)
            ability:SetActivated(false)

            local shard_duration = ability:GetSpecialValueFor("scepter_genocide_mod_duration")
            Timers:CreateTimer(duration, function()
                UnfreezeAnimation(parent)
                StartAnimation(parent, {duration=1.1, activity=ACT_DOTA_SPAWN})
                dodger:SetDuration(-1, false)
                parent:SetHealth(parent:GetMaxHealth())
                parent:FindAbilityByName("sans_dodger"):ModifyCharges(ability:GetSpecialValueFor("charges_restore"))
                if parent:HasShard() and parent:FindAbilityByName("sans_genocide_mod"):GetLevel() > 0 then
                    parent:StopSound("Arena.Hero_Sans.Last_Breath")
                    parent:EmitSound("Arena.Hero_Sans.Last_Breath.Aghanim")
                    parent:AddNewModifier(parent, parent:FindAbilityByName("sans_genocide_mod"), "modifier_sans_genocide_mod", {
                        duration = shard_duration
                    })
                end
            end)
        end
    end

    function modifier_sans_ketchup:GetMinHealth(keys)
		local parent = self:GetParent()
		if not parent:IsIllusion() and self:GetAbility():IsCooldownReady() and self:GetAbility():IsActivated() then
			return 1
		end
	end

    function modifier_sans_ketchup:OnRespawn(keys)

        local ability = self:GetAbility()

        if not ability:IsActivated() and keys.unit == self:GetParent() then
            ability:SetActivated(true)
            ability:StartCooldown(ability.BaseClass.GetCooldown(ability, 1) * self:GetParent():GetCooldownReduction())
        end
    end
end