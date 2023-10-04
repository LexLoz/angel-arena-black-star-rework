modifier_talent_true_strike = class({
	IsHidden        = function() return true end,
	IsPermanent     = function() return true end,
	IsPurgable      = function() return false end,
	DestroyOnExpire = function() return false end,
	AllowIllusionDuplicate = function() return true end,
})

function modifier_talent_true_strike:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_FAIL
	}
end

function modifier_talent_true_strike:CheckState()
	if self.proc == true then
		return {
			[MODIFIER_STATE_CANNOT_MISS] = true
		}
	else
		return {}
	end
end

function modifier_talent_true_strike:Random()
	local chance = self:GetStackCount()
	if RollPercentage(chance) then
		self.proc = true
	end
end

function modifier_talent_true_strike:OnAttackLanded(keys)
	if keys.target:IsBuilding() then return end
	if self:GetParent() ~= keys.attacker then return end
	if self.proc == true then
		self.proc = false
	end
	self:Random()
end

function modifier_talent_true_strike:OnAttackFail(keys)
	if keys.target:IsBuilding() then return end
	if self:GetParent() ~= keys.attacker then return end
	self:Random()
end
