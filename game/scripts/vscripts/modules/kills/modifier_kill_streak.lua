modifier_kill_streak = class({
	IsPurgable      = function() return false end,
	IsHidden        = function() return false end,
	RemoveOnDeath   = function() return false end,
	GetAttributes   = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	GetTexture      = function() return "arena/kill_streak" end,
	DestroyOnExpire = function() return false end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_TOOLTIP,
            MODIFIER_PROPERTY_TOOLTIP2
        }
    end,
})

-- if IsServer() then
--     function modifier_kill_streak:OnCreated()
--         print('created')
--         self:StartIntervalThink(1)
--     end

--     function modifier_kill_streak:OnIntervalThink()
--         print('think')
--     end
-- end

function modifier_kill_streak:OnTooltip()
    return self:GetStackCount() * 5
end

function modifier_kill_streak:OnTooltip2()
    return self:GetStackCount() * 7
end