LinkLuaModifier("modifier_item_infinity_gauntlet", "items/item_infinity_gauntlet.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_infinity_gauntlet_dusting", "items/item_infinity_gauntlet.lua", LUA_MODIFIER_MOTION_NONE)

item_infinity_gauntlet = class({
    GetIntrinsicModifierName = function() return "modifier_item_infinity_gauntlet" end,
})

function item_infinity_gauntlet:HasStaticCooldown() return true end

modifier_item_infinity_gauntlet = class({
    RemoveOnDeath = function() return false end,
    IsHidden      = function() return true end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
    IsPurgable    = function() return false end,
})

function modifier_item_infinity_gauntlet:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_item_infinity_gauntlet:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

modifier_item_infinity_gauntlet_dusting = class({
    IsHidden          = function() return false end,
    GetAttributes     = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
    IsPurgable        = function() return false end,
    IsDebuff          = function() return true end,
    GetDisableHealing = function() return 1 end,
})

function modifier_item_infinity_gauntlet_dusting:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING
    }
end

function item_infinity_gauntlet:GetAbilityTextureName()
    return self:GetNetworkableEntityInfo("completed") == 1 and "item_arena/completed_infinity_gauntlet" or
        "item_arena/empty_infinity_gauntlet"
end

if IsServer() then
    function modifier_item_infinity_gauntlet_dusting:DealDamage()
        local parent = self:GetParent()
        local caster = self:GetCaster()
        --print(caster)

        --print(self.damage)
        self.damage = math.ceil(self.damage - self.tick_damage)
        ApplyInevitableDamage(
            caster,
            parent,
            nil,
            self.tick_damage,
            true,
            true
        )
        if self.damage > 0 and parent:IsAlive() then
            return self.tick
        end
    end

    function modifier_item_infinity_gauntlet_dusting:OnCreated(keys)
        self.damage = keys.damage / keys.duration
        self.tick = 0.01
        self.tick_damage = self.damage * self.tick
        self:DealDamage()
        self:StartIntervalThink(self.tick)
    end

    function modifier_item_infinity_gauntlet_dusting:OnIntervalThink()
        self:DealDamage()
    end

    function item_infinity_gauntlet:OnAbilityPhaseStart()
        if self:GetNetworkableEntityInfo("completed") == 1 then
            self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_infinity_gauntlet_dusting", {
                damage = 1000000,
                duration = 1
            })
        end
    end

    function item_infinity_gauntlet:OnSpellStart()
        local caster = self:GetCaster()
        if #self.infinity_stones == 6 then
            if not Duel:IsDuelOngoing() then
                --Duel:SetDuelTimer(9999 or 0)
                self:StartCooldown(self:GetSpecialValueFor("cooldown"))

                for team, _ in pairsByKeys(Teams.Data) do
                    --if caster:GetTeamNumber() ~= team then
                    local current_weight = Teams:GetTeamKillWeight(team)
                    Teams:ChangeKillWeight(team, current_weight)
                    --end
                end

                EmitGlobalSound("Arena.Items.Infinity_Gauntlet.Click")
                --local teams = Teams:GetAllEnabledTeams()
                --print(#teams)
                -- for _,v in pairs(teams) do
                --     if caster:GetTeamNumber() ~= v then

                --     end
                -- end

                local enemy_players = FindUnitsInRadius(
                    caster:GetTeamNumber(),
                    caster:GetAbsOrigin(),
                    nil,
                    FIND_UNITS_EVERYWHERE,
                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                    DOTA_UNIT_TARGET_HERO,
                    DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
                    FIND_ANY_ORDER,
                    false
                )
                local duration = self:GetSpecialValueFor("duration")
                local function Kill(timer, v)
                    Timers:CreateTimer(timer, function()
                        v:EmitSound("Arena.Items.Infinity_Gauntlet.Dusting")
                        v:AddNewModifier(v:IsBoss() and caster or nil, self, "modifier_item_infinity_gauntlet_dusting", {
                            damage = v:GetMaxHealth(),
                            duration = duration
                        })
                        --v:TrueKill(self, caster)
                    end)
                end
                local timer = 3
                for _, v in pairs(enemy_players) do
                    if v:GetUnitName() ~= "npc_arena_boss_cursed_zeld" and v:IsAlive() then
                        if v:IsBoss() and RollPercentage(25) then
                            Kill(timer, v)
                        elseif v:IsTrueHero() then
                            Kill(timer, v)
                        end
                        timer = timer + 3
                    end
                end
                return
            else
                Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_error_cant_target_duel")
                self:EndCooldown()
                return
            end
        end
        self:CheckInventory()
    end

    function item_infinity_gauntlet:CheckInventory()
        local caster = self:GetCaster()
        local accept = false

        for _, v in pairs(STONES_TABLE) do
            local stone = FindItemInInventoryByName(caster, v[1], _, _, _, true)
            local function ConditionHelper(item)
                local stone_name = item:GetAbilityName()
                for __, _v in pairs(self.infinity_stones) do
                    if _v.item:GetAbilityName() == stone_name then
                        --Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_error_stone_duplicate")
                        return false
                    end
                end
                return true
            end
            if stone and not accept and ConditionHelper(stone) then
                accept = true
                local modifier = stone:GetIntrinsicModifierName()
                stone.InGauntlet = true
                table.insert(self.infinity_stones, {
                    modifier = modifier,
                    item = caster:TakeItem(stone)
                })
            end
        end
        --print(#self.infinity_stones)
        if accept then
            self:AddModifiers()
            caster:EmitSound("Arena.Items.Infinity_Gauntlet.StonePlaced")
            if #self.infinity_stones == 6 then
                self:SetNetworkableEntityInfo("completed", 1)
            end
        else
            Containers:DisplayError(caster:GetPlayerID(), "#arena_hud_error_no_stones")
            self:EndCooldown()
        end
        --PrintTable(self.infinity_stones)
    end

    function item_infinity_gauntlet:AddModifiers()
        local caster = self:GetCaster()
        if #self.infinity_stones > 0 then
            --Timers:NextTick(function()
            local mod
            for _, v in pairs(self.infinity_stones) do
                local ability = v.item
                local modifier = v.modifier
                caster:AddNewModifier(caster, ability, modifier, { duration = -1 })
            end
            --end)
        end
    end

    function item_infinity_gauntlet:RemoveModifiers()
        local caster = self:GetCaster()
        print(#self.infinity_stones)
        if #self.infinity_stones > 0 then
            --Timers:NextTick(function()
            for _, v in pairs(self.infinity_stones) do
                local modifier = v.modifier
                caster:RemoveModifierByName(modifier)
            end
            --end)
        end
    end

    function item_infinity_gauntlet:DropStones()
        if #self.infinity_stones > 0 then
            for _, v in pairs(self.infinity_stones) do
                v.item.InGauntlet = false
                CreateItemOnPositionSync(self:GetCaster():GetAbsOrigin() + RandomVector(RandomInt(90, 300)), v.item)
            end
        end
        self.infinity_stones = {}
    end

    function modifier_item_infinity_gauntlet:OnCreated()
        local ability = self:GetAbility()

        if not ability.infinity_stones then
            ability.infinity_stones = {}
        end

        if #ability.infinity_stones > 0 then
            ability:AddModifiers()
        end
    end

    function modifier_item_infinity_gauntlet:OnDestroy()
        local ability = self:GetAbility()

        if #ability.infinity_stones > 0 then
            ability:RemoveModifiers()
        end
    end
end
