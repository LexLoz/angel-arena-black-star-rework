modifier_neutral_champion = class({})

function modifier_neutral_champion:IsPurgable()
	return false
end

function modifier_neutral_champion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
		--MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_neutral_champion:OnTooltip()
	return self:GetStackCount() + 1
end

function modifier_neutral_champion:GetTexture()
	return "granite_golem_bash"
end