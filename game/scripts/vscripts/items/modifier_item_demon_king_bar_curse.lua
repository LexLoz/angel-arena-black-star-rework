modifier_item_demon_king_bar_curse = class({})
function modifier_item_demon_king_bar_curse:IsDebuff() return true end
function modifier_item_demon_king_bar_curse:IsPurgable() return false end
function modifier_item_demon_king_bar_curse:IsPurgeException() return true end

function modifier_item_demon_king_bar_curse:GetEffectName()
	return "particles/arena/items_fx/demon_king_bar_curse_mark.vpcf"
end

function modifier_item_demon_king_bar_curse:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_item_demon_king_bar_curse:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP}
end

if IsServer() then

	function modifier_item_demon_king_bar_curse:OnCreated()
		self:StartIntervalThink(0.5)
		self:OnIntervalThink()
	end

	function modifier_item_demon_king_bar_curse:OnIntervalThink()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		local damage = self:OnTooltip() * 0.5
		ApplyInevitableDamage(
			self:GetCaster(),
			parent,
			ability,
			damage,
			false
		)
		if not parent:IsAlive() then
			parent:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
		end
	end
end

function modifier_item_demon_king_bar_curse:OnTooltip()
	return math.min(self:GetParent():GetMaxHealth(), 1.15 ^ math.ceil(self:GetElapsedTime())/2)
end
