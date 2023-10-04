LinkLuaModifier("modifier_item_flesh_potion_growth", "items/item_flesh_potion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_flesh_potion_buff", "items/item_flesh_potion.lua", LUA_MODIFIER_MOTION_NONE)

modifier_item_flesh_potion_growth = class({
    IsHidden         = function() return true end,
    IsPurgable       = function() return false end,
    GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
    DeclareFunctions = function() return {
            MODIFIER_PROPERTY_DISABLE_HEALING
        }
    end,
    GetDisableHealing = function() return 1 end
})

modifier_item_flesh_potion_buff = class({
    IsHidden         = function() return false end,
    IsPurgable       = function() return false end,
    GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
    DeclareFunctions = function() return {
            MODIFIER_PROPERTY_HEALTH_BONUS,
            MODIFIER_PROPERTY_MODEL_SCALE
        }
    end
})

item_flesh_potion = class({})

if IsServer() then
    function item_flesh_potion:OnSpellStart()
        local target = self:GetCursorTarget()
        ParticleManager:CreateParticle("particles/items2_fx/soul_ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
        --ParticleManager:SetParticleControlEnt(ParticleManager:CreateParticle("particles/items2_fx/soul_ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, target), 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        target:AddNewModifier(self:GetCaster(), self, "modifier_item_flesh_potion_buff", {
            duration = self:GetSpecialValueFor("buff_duration")
        })
        target:AddNewModifier(self:GetCaster(), self, "modifier_item_flesh_potion_growth", {
            duration = self:GetSpecialValueFor("growth_duration")
        })
        self:GetCaster():EmitSound("Arena.Items.FleshPotion.Cast")
        self:SpendCharge()
    end

    function modifier_item_flesh_potion_growth:OnCreated()
        self.buff = self:GetParent():FindModifierByName("modifier_item_flesh_potion_buff")
        self.buff.bonus_health = self.buff.bonus_health or 0

        local ability = self:GetAbility()
        self.mult = ability:GetSpecialValueFor('regen_in_growth_pct') * 0.01
        self.max_model_scale = ability:GetSpecialValueFor('max_model_increase')

        self.tick = 0.1
        self:StartIntervalThink(self.tick)
    end
    function modifier_item_flesh_potion_growth:OnIntervalThink()
        local parent = self:GetParent()
        if parent:HasModifier("modifier_fountain_aura_arena") or parent:HasModifier("modifier_filler_heal") or parent:HasModifier("modifier_item_infinity_gauntlet_dusting") then return end
        local hp_regen = (parent:GetHealthRegen() + (parent.custom_regen or 0)) * self.mult * self.tick
        local mana_regen = (parent:GetManaRegen() + parent.custom_mana_regen) * self.mult * self.tick

        self.buff.bonus_health = self.buff.bonus_health + hp_regen + mana_regen

        local stacks = math.abs(math.round((1 - parent:GetMaxHealth() / (parent:GetMaxHealth() - self.buff.bonus_health)) * 100))
        parent:SetHealth(parent:GetHealth() + self.buff.bonus_health)
        self.buff:SetStackCount(stacks)
        parent:CalculateStatBonus(true)

        self.buff.model = math.min(self.max_model_scale, stacks / 100 * self.max_model_scale)
        parent:ManageModelChanges()
    end

    function modifier_item_flesh_potion_buff:GetModifierHealthBonus()
        return self.bonus_health
    end
    function modifier_item_flesh_potion_buff:GetModifierModelScale()
        return self.model
    end
end