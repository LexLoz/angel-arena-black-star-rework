modifier_jungle_bear = class({})

function modifier_jungle_bear:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	}
	return funcs
end

-- if IsServer() then
	function modifier_jungle_bear:GetModifierConstantHealthRegen()
		return self:GetParent():GetHealth() * 0.2
	end
-- end

function modifier_jungle_bear:IsHidden()
	return true
end