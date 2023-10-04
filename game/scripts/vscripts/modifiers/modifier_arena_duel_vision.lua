modifier_arena_duel_vision = class({
    IsPurgable    = function() return false end,
    IsHidden      = function() return true end,
    RemoveOnDeath = function() return true end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
})

function modifier_arena_duel_vision:DeclareFunctions()
    return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

if IsServer() then
    function modifier_arena_duel_vision:GetModifierProvidesFOWVision()
        return 1
    end
end
