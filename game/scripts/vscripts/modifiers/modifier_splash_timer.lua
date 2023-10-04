modifier_splash_timer = class ({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
})

if IsServer() then
	function modifier_splash_timer:OnCreated(keys)
		--print(keys.duration)
		--print(self:GetDuration())
	end
end