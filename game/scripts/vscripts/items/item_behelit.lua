LinkLuaModifier("modifier_item_behelit_buff", "items/item_behelit.lua", LUA_MODIFIER_MOTION_NONE)

modifier_item_behelit_buff = class({
    IsPurgable       = function() return false end,
    IsHidden         = function() return false end,
    GetTexture       = function() return "item_arena/behelit_active" end,
    GetAttributes    = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_TOOLTIP,
            MODIFIER_PROPERTY_TOOLTIP2,
        }
    end,
})

item_behelit = class({})

function item_behelit:HasStaticCooldown() return true end

function item_behelit:GetAbilityTextureName()
    local activated = self:GetNetworkableEntityInfo("behelit_activated") == 1
    return activated and "item_arena/behelit_active" or "item_arena/behelit"
end

if IsServer() then
    function item_behelit:OnSpellStart()
        if self.active then
            self:EndCooldown()
            return
        end
        local caster = self:GetCaster()
        local units = FindUnitsInRadius(
            caster:GetTeam(),
            caster:GetAbsOrigin(),
            nil,
            self:GetSpecialValueFor("radius"),
            self:GetAbilityTargetTeam(),
            self:GetAbilityTargetType(),
            DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
            FIND_ANY_ORDER,
            false
        )

        local damage_bonus = 0
        local damage_resist = 0
        local max_resist = 50
        local max_damage = 100

        local damage_bonus_per_unit_attack_damage = 0
        local damage_resist_per_unit_health = 0

        local timer = 0
        local units_count = 0
        print(#units)
        if #units > 1 then
            for _, v in pairs(units) do
                if v:GetPlayerOwner() == caster:GetPlayerOwner() and v ~= caster and not v:IsHero() then
                    units_count = units_count + 1
                end
            end
        else
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_no_units")
            self:EndCooldown()
            return
        end
        if units_count > 0 then
            units_count = 0
            for _, v in pairs(units) do
                if v:GetPlayerOwner() == caster:GetPlayerOwner() and v ~= caster and not v:IsHero() then
                    units_count = units_count + 1
                    timer = timer + 0.5
                    Timers:CreateTimer(timer, function()
                        if not v:IsIllusion() then
                            local unit = v
                            local hero_pfx = ParticleManager:CreateParticle(
                                "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf", PATTACH_ABSORIGIN,
                                caster)
                            caster:EmitSound("Arena.Items.Behelit.Buff")

                            local pfx = ParticleManager:CreateParticle(
                                "particles/arena/units/heroes/hero_sara/space_dissection.vpcf", PATTACH_ABSORIGIN_FOLLOW,
                                unit)
                            ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc",
                                caster:GetOrigin(), true)
                            ParticleManager:SetParticleControlEnt(pfx, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc",
                                unit:GetOrigin(), true)
                            ParticleManager:SetParticleControlEnt(pfx, 5, unit, PATTACH_POINT_FOLLOW, "attach_hitloc",
                                unit:GetOrigin(), true)
                            v:EmitSound("Arena.Items.Behelit.Death")

                            local damage_bonus_per_unit = math.min(3 * units_count, 15)
                            damage_bonus_per_unit_attack_damage = damage_bonus_per_unit_attack_damage +
                                math.min(1000, v:GetAverageTrueAttackDamage(v)) * 0.04
                            damage_bonus = damage_bonus_per_unit + damage_bonus_per_unit_attack_damage

                            local damage_resist_per_unit = math.min(5 * units_count, 6)
                            damage_resist_per_unit_health = damage_resist_per_unit_health +
                                math.min(10000, v:GetMaxHealth()) * 0.0006

                            damage_resist = math.min(15, damage_resist_per_unit + damage_resist_per_unit_health)
                            if v:IsAlive() then v:TrueKill(self, caster) end
                        end
                    end)
                end
            end
            self.active = true
            self:SetNetworkableEntityInfo("behelit_activated", 1)
            self:EndCooldown()
        else
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_no_units")
            self:EndCooldown()
            return
        end

        Timers:CreateTimer(timer, function()
            local buff = caster:AddNewModifier(caster, self, "modifier_item_behelit_buff", {
                duration = self:GetSpecialValueFor("buff_duration")
            })
            caster.behelit_bonus_damage = damage_bonus
            caster.behelit_damage_resist = damage_resist
            caster:SetNetworkableEntityInfo("behelit_damage_bonus", damage_bonus)
            caster:SetNetworkableEntityInfo("behelit_damage_resist", damage_resist)
            self:SetNetworkableEntityInfo("behelit_activated", 0)
            self.active = false
            self:SetNetworkableEntityInfo("behelit_activated", 0)
            self:StartCooldown(self.BaseClass.GetCooldown(self, 1) * caster:GetCooldownReduction())
            self:SpendCharge()
        end)
    end

    function modifier_item_behelit_buff:OnDestroy()
        local parent = self:GetParent()

        parent.behelit_bonus_damage = 0
        parent.behelit_damage_resist = 0

        parent:SetNetworkableEntityInfo("behelit_damage_bonus", nil)
        parent:SetNetworkableEntityInfo("behelit_damage_resist", nil)
    end
end

if IsClient() then
    function modifier_item_behelit_buff:OnTooltip()
        return self:GetParent():GetNetworkableEntityInfo("behelit_damage_bonus")
    end

    function modifier_item_behelit_buff:OnTooltip2()
        return self:GetParent():GetNetworkableEntityInfo("behelit_damage_resist")
    end
end
