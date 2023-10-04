LinkLuaModifier("modififer_sara_conceptual_reflection", "heroes/hero_sara/conceptual_reflection.lua", LUA_MODIFIER_MOTION_NONE)

sara_conceptual_reflection = class({})

function sara_conceptual_reflection:OnUpgrade()
    self:ToggleAutoCast()
    if not IsServer() then return end
    local caster = self:GetCaster()
	local modifier = caster:AddNewModifier(caster, self, "modififer_sara_conceptual_reflection", nil)
    modifier:SetStackCount(self:GetSpecialValueFor("max_charges"))
end

if IsClient() then
	function sara_conceptual_reflection:GetManaCost()
		return self:GetSpecialValueFor("energy_cost") + self:GetCaster():GetMana() * self:GetSpecialValueFor("cost_percent") * 0.01
	end
end

function sara_conceptual_reflection:OnSpellStart()
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modififer_sara_conceptual_reflection")

    if modifier then
        caster:ModifyEnergy(-self:GetSpecialValueFor("energy_cost"))
        modifier:IncrementStackCount()
        modifier.activated = true
    else
        caster:AddNewModifier(caster, self, "modififer_sara_conceptual_reflection", nil):SetStackCount(1)
    end
end

modififer_sara_conceptual_reflection = class({
    IsHidden            = function() return false end,
    IsPurgable          = function() return false end,
    GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
    GetEffectName       = function() return "particles/arena/units/heroes/hero_sara/fragment_of_armor.vpcf" end,
    RemoveOnDeath	    = function() return false end,
    DeclareFunctions    = function() return {
        --MODIFIER_EVENT_ON_TAKEDAMAGE,
    } end
})

if IsServer() then
    function modififer_sara_conceptual_reflection:OnCreated()
        self.activated = true
        self:StartIntervalThink(1 / 30)
    end
    function modififer_sara_conceptual_reflection:OnTakeDamage(keys)
        local ability = self:GetAbility()
        local parent = self:GetParent()
        local charges = self:GetStackCount()
        if not ability:IsActivated() and not ability:GetAutoCastState() then ability:ToggleAutoCast() end
        if not ability:GetAutoCastState() then return end

        if keys.unit ~= parent then return end

        local damage = keys.damage

        --[[if damage > parent:GetMaxHealth() * ability:GetSpecialValueFor("max_health_damage_proc") * 0.01 and self:GetStackCount() > 0 then
            if (keys.attacker:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > ability:GetSpecialValueFor("reflect_radius") then return end
            if not keys.attacker:IsAlive() or keys.attacker:IsMagicImmune() or parent:PassivesDisabled() then return end

            Timers:CreateTimer(0.8, function()
                parent:EmitSound("Ability.LagunaBlade")
                keys.attacker:EmitSound("Ability.LagunaBladeImpact")

                ability.NoDamageAmp = true
                ApplyDamage({
                    attacker = parent,
                    victim = keys.attacker,
                    damage_type = keys.damage_type,
                    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY,
                    damage = keys.original_damage * ability:GetSpecialValueFor("reflected_damage") * 0.01,
                    ability = ability
                })

				local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_sara/energy_burst.vpcf", PATTACH_ABSORIGIN, parent)
				ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin() + Vector(0,0,224))
				ParticleManager:SetParticleControlEnt(pfx, 1, keys.attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.attacker:GetAbsOrigin(), true)

                if keys.attacker:GetHealth() == 1 then keys.attacker:TrueKill(keys.attacker,  parent) end
                ability:SetActivated(true)
                ability:StartCooldown(ability.BaseClass.GetCooldown(ability, 1) * parent:GetCooldownReduction())
                self.activated = true
            end)
        end]]
    end

    function modififer_sara_conceptual_reflection:OnIntervalThink()
        local ability = self:GetAbility()
        if self:GetStackCount() == 0 then
            self:Destroy()
        elseif self:GetStackCount() >= ability:GetSpecialValueFor("max_charges") and self.activated then
            self:SetStackCount(ability:GetSpecialValueFor("max_charges"))
            ability:SetActivated(false)
            self.activated = false
        end
    end
end