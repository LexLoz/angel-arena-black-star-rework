modifier_talent_bonus_all_stats = class({
	IsHidden        = function() return true end,
	IsPermanent     = function() return true end,
	IsPurgable      = function() return false end,
	DestroyOnExpire = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
    AllowIllusionDuplicate = function() return true end,
})

function modifier_talent_bonus_all_stats:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
end

function modifier_talent_bonus_all_stats:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end
function modifier_talent_bonus_all_stats:GetModifierBonusStats_Agility()
    return self:GetStackCount()
end
function modifier_talent_bonus_all_stats:GetModifierBonusStats_Intellect()
    return self:GetStackCount()
end