modifier_universal_attribute = class({
    IsPurgable    = function() return false end,
    IsHidden      = function() return true end,
    RemoveOnDeath = function() return false end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
})

if IsServer() then
    function modifier_universal_attribute:ChangePrimaryBonus(index)
        local parent = self:GetParent()
        if not parent.ArenaHero then
            if self.PrimaryBonuses[index] then
                parent:SetPrimaryAttribute(index - 1)
                parent:AddNewModifier(parent, nil, self.PrimaryBonuses[index], nil)
                self.CurrentPrimaryBonus = index
            elseif index == 4 then
                self.CurrentPrimaryBonus = 4
                parent:SetPrimaryAttribute(index - 1)
            else
                self.CurrentPrimaryBonus = 1
                self:ChangePrimaryBonus(1)
            end
        else
            if self.PrimaryBonuses[index] then
                parent:SetPrimaryAttribute(index - 1)
				parent.GetPrimaryAttribute = function()
					return index - 1
				end
                parent:AddNewModifier(parent, nil, self.PrimaryBonuses[index], nil)
                self.CurrentPrimaryBonus = index
            elseif index == 4 then
                self.CurrentPrimaryBonus = 4
                parent:SetPrimaryAttribute(index - 1)
				parent.GetPrimaryAttribute = function()
					return index - 1
				end
            else
                self.CurrentPrimaryBonus = 1
                self:ChangePrimaryBonus(1)
            end
        end


        --print(parent:GetPrimaryAttribute())
        --if not parent.ArenaHero then
            parent:SetNetworkableEntityInfo("PrimaryAttribute", tostring(parent:GetPrimaryAttribute()))
            --print(tostring(parent:GetPrimaryAttribute()))
        -- else
        --     local primat = _G[NPC_HEROES_CUSTOM[parent:GetFullName()]["AttributePrimary"]]
        --     if not primat then
        --         primat = parent:GetPrimaryAttribute()
        --     end
        --     print(primat)
        --     parent:SetNetworkableEntityInfo("PrimaryAttribute", tostring(primat))
        -- end
    end

    function modifier_universal_attribute:OnCreated()
        self.PrimaryBonuses = {
            "modifier_strength_crit",
            "modifier_agility_primary_bonus",
            "modifier_intelligence_primary_bonus"
        }

        self.CurrentPrimaryBonus = 0

        --self:ChangePrimaryBonus(self.CurrentPrimaryBonus)
    end
end
