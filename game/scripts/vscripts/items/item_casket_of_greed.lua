LinkLuaModifier("modifier_item_casket_of_greed", "items/item_casket_of_greed.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_casket_of_greed_passive", "items/item_casket_of_greed.lua", LUA_MODIFIER_MOTION_NONE)

item_casket_of_greed = {
    GetIntrinsicModifierName = function() return "modifier_item_casket_of_greed_passive" end
}

modifier_item_casket_of_greed = class({
    IsHidden      = function() return true end,
	IsPurgable    = function() return false end,
    RemoveOnDeath = function() return false end,
    DestroyOnExpire = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
})

modifier_item_casket_of_greed_passive = class({
    IsDebuff      = function() return false end,
    IsHidden      = function() return true end,
	IsPurgable    = function() return false end,
    emoveOnDeath = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
})


function modifier_item_casket_of_greed_passive:DeclareFunctions()
	return {
        MODIFIER_EVENT_ON_DEATH
    }
end

if IsServer() then
    function modifier_item_casket_of_greed_passive:OnCreated()
        local ability = self:GetAbility()

        if not ability.modifiers then
            ability.modifiers = {}
        end

        self.item_casket_of_greed = true

        --print(#ability.modifiers)
        if #ability.modifiers > 0 then
            ability:AddModifiers()
        end
    end
    function modifier_item_casket_of_greed_passive:OnDestroy()
        local ability = self:GetAbility()

        if #ability.modifiers > 0 then
            ability:RemoveModifiers()
        end
    end

    function modifier_item_casket_of_greed:OnDestroy()
        --print('destroy')
        self:GetAbility():RemoveModifiers(true)
        --self:GetAbility():RemoveSelf()
    end

    function modifier_item_casket_of_greed_passive:OnDeath(k)
        local parent = self:GetParent()
        local ability = self:GetAbility()
        if k.unit == parent and not parent:IsIllusion() and parent:IsTrueHero() and not parent:IsTempestDouble() and not Duel:IsDuelOngoing() and not parent:HasModifier('modifier_item_demon_king_bar_curse') then
            ability.deaths_count = (ability.deaths_count or 0) + 1
            if ability.deaths_count == 2 then
                parent:RemoveModifierByName("modifier_item_casket_of_greed")
            end
            ability:SpendCharge()
        end
    end
end

function item_casket_of_greed:GetBehavior()
    return self:GetNetworkableEntityInfo("casket_of_greed_active") == 1 and DOTA_ABILITY_BEHAVIOR_PASSIVE or DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
end

if IsServer() then
    function item_casket_of_greed:AddModifiers(first)
        local caster = self:GetCaster()
        Timers:CreateTimer(0.1, function()
            local mod
            for _,v in pairs(self.modifiers) do
                local ability = v.item
                local modifier = v.modifier
                --print(modifier..", "..(ability:GetAbilityName()))
                mod = caster:AddNewModifier(caster, ability, modifier, {duration = -1})
                if not mod then
                    mod = ability:ApplyDataDrivenModifier(caster, caster, modifier, {duration = -1})
                end
                if mod and first then mod.item_casket_of_greed = true end
            end
        end)
    end
    function item_casket_of_greed:RemoveModifiers(permamently)
        local caster = self:GetCaster()
        Timers:NextTick(function()
            for _,v in pairs(self.modifiers) do
                local ability = v.item
                local modifier = v.modifier
                --print(modifier..", "..(ability:GetAbilityName()))
                caster:RemoveModifierByName(modifier)
                if permamently and ability then
                    UTIL_Remove(ability)
                end
            end
            if permamently then
                self:SpendCharge()
            end
        end)
    end
    function item_casket_of_greed:OnSpellStart()
        local caster = self:GetCaster()
        --[[if caster:HasModifier("modifier_item_casket_of_greed") then
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_casket_of_greed")
            return
        end]]

        self:SetNetworkableEntityInfo("casket_of_greed_active", 1)

        caster:AddNewModifier(caster, self, "modifier_item_casket_of_greed", {
            duration = 99999--self:GetSpecialValueFor("duration_min") * 60
        })

        caster:EmitSound("DOTA_Item.Cheese.Activate")

        local modifiers = caster:FindAllModifiers()

        for _, v in pairs(modifiers) do
            local ability = v.GetAbility and v:GetAbility() or nil
            if v:GetDuration() == -1 and not v.item_casket_of_greed and ability and ability:IsItem() and not ability:IsNeutralDrop() then
                table.insert(self.modifiers, {
                    modifier = v:GetName(),
                    item = caster:TakeItem(ability)
                })
                --caster:RemoveItem(ability)
            end
        end
        self:SetCurrentCharges(2)
        self:AddModifiers(true)
        --self:SpendCharge()
    end
end
