modifier_death_streak = class({
	IsPurgable      = function() return false end,
	IsHidden        = function() return false end,
	RemoveOnDeath   = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	GetTexture      = function() return "arena/death_streak" end,
	DestroyOnExpire = function() return false end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_TOOLTIP,
            MODIFIER_PROPERTY_TOOLTIP2        }
    end,
})

function modifier_death_streak:OnTooltip()
    return self:GetStackCount() * 15
end

function modifier_death_streak:OnTooltip2()
    return self:GetStackCount() * 10
end