modifier_talent_mana = class({
	IsHidden        = function() return true end,
	IsPermanent     = function() return true end,
	IsPurgable      = function() return false end,
	DestroyOnExpire = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	AllowIllusionDuplicate = function() return true end,
})

function modifier_talent_mana:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_BONUS}
end

if IsServer() then
	function modifier_talent_mana:GetModifierManaBonus()
		return self:GetStackCount() * self:GetParent().ManaPerInt * 0.01 * self:GetParent():GetIntellect()
	end
end
