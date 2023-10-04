modifier_talent_health = class({
	IsHidden        = function() return true end,
	IsPermanent     = function() return true end,
	IsPurgable      = function() return false end,
	DestroyOnExpire = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	AllowIllusionDuplicate = function() return true end,
})

function modifier_talent_health:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS}
end

if IsServer() then
	function modifier_talent_health:GetModifierHealthBonus()
		return self:GetStackCount() * self:GetParent().HealthPerStrength * 0.01 * self:GetParent():GetStrength()
	end
end
