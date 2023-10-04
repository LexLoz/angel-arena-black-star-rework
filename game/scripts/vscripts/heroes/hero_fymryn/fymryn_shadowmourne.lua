LinkLuaModifier("modifier_fymryn_shadowmourne_attack", "heroes/hero_fymryn/fymryn_shadowmourne", LUA_MODIFIER_MOTION_NONE)

fymryn_shadowmourne = class({})

function fymryn_shadowmourne:Precache(context)
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/fymryn_test_step.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/fymryn/splash_active.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/fymryn_test_attack.vpcf', context )
end

function fymryn_shadowmourne:OnAbilityPhaseStart()
    if not IsServer() then return end
    self:GetCaster():EmitSound("fymryn_1")
    return true
end

function fymryn_shadowmourne:OnAbilityPhaseInterrupted()
    if not IsServer() then return end
    self:GetCaster():StopSound("fymryn_1")
end

function fymryn_shadowmourne:OnSpellStart()
    if not IsServer() then return end
    local target = self:GetCursorTarget()
    -- if self:GetCaster():GetUnitName() ~= "npc_dota_hero_antimage" then return end
    if target:TriggerSpellAbsorb(self) then return end

    local dir = (target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin())
    dir.z = 0
    local length = dir:Length2D()
    dir = dir:Normalized()

    local origin = target:GetAbsOrigin() + dir * length

    self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_fymryn_shadowmourne_attack", {target = target:entindex(), x=origin.x, y=origin.y, z=origin.z} )
end

modifier_fymryn_shadowmourne_attack = class({})

function modifier_fymryn_shadowmourne_attack:IsHidden()
	return true
end

function modifier_fymryn_shadowmourne_attack:IsPurgable()
	return false
end

function modifier_fymryn_shadowmourne_attack:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end

function modifier_fymryn_shadowmourne_attack:GetModifierDamageOutgoing_Percentage( params )
	if IsServer() then
		return self:GetAbility():GetSpecialValueFor( "damage_from_attack" ) - 100
	end
end

function modifier_fymryn_shadowmourne_attack:OnCreated(params)
    if not IsServer() then return end
    self:GetCaster():AddNoDraw()
    self.target = EntIndexToHScript(params.target)
    self.point = Vector(params.x,params.y,params.z)
    --local effect_cast = ParticleManager:CreateParticle( "particles/arena/units/heroes/hero_fymryn/fymryn/blink_trail.vpcf", PATTACH_WORLDORIGIN, nil )
	--ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetAbsOrigin() )
	--ParticleManager:SetParticleControl( effect_cast, 1, self.target:GetAbsOrigin() )
	--ParticleManager:ReleaseParticleIndex( effect_cast )

    local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn_blink_outstart.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( particle, 0, self:GetCaster():GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( particle )

    local particle_smoke = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn/splash_active.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle_smoke, 0, self.target:GetAbsOrigin())

    --local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn_test_attack.vpcf", PATTACH_CUSTOMORIGIN, nil)
    --ParticleManager:SetParticleControl(particle, 0, self.target:GetAbsOrigin() )
    --ParticleManager:SetParticleControl(particle, 1, self.target:GetAbsOrigin() )
    --ParticleManager:SetParticleControlEnt(particle, 2, self:GetParent(), PATTACH_CUSTOMORIGIN, "attach_hitloc", self.target:GetAbsOrigin(), true)
    --ParticleManager:ReleaseParticleIndex(particle)
    self.end_cast = false
    self:StartIntervalThink(0.3)
end

function modifier_fymryn_shadowmourne_attack:OnIntervalThink()
    if not IsServer() then return end
    if self.end_cast then
        self:Destroy()
    else
        local duration = self:GetAbility():GetSpecialValueFor("silence_duration")
        local damage = self:GetAbility():GetSpecialValueFor("damage")
        self.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_silence", {duration = duration})
        ApplyDamage({victim = self.target, attacker = self:GetCaster(), ability = self, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
	    self:GetCaster():PerformAttack ( self.target, true, true, true, false, false, false, true )
        self.end_cast = true
        self:GetCaster():Stop()
        self:StartIntervalThink(0.1)
    end
end

function modifier_fymryn_shadowmourne_attack:CheckState()
    return
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
    }
end

function modifier_fymryn_shadowmourne_attack:OnDestroy()
    if not IsServer() then return end
    --local effect_cast = ParticleManager:CreateParticle( "particles/arena/units/heroes/hero_fymryn/fymryn/blink_trail.vpcf", PATTACH_WORLDORIGIN, nil )
	--ParticleManager:SetParticleControl( effect_cast, 0, self.target:GetAbsOrigin() )
	--ParticleManager:SetParticleControl( effect_cast, 1, self.point )
	--ParticleManager:ReleaseParticleIndex( effect_cast )

    local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn_blink_outstart.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( particle, 0, self.point )
    ParticleManager:ReleaseParticleIndex( particle )

    self:GetCaster():SetAbsOrigin(self.point)
    FindClearSpaceForUnit(self:GetCaster(), self.point, true)
    local new_dir = (self.target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin())
    new_dir.z = 0
    new_dir = new_dir:Normalized()
    self:GetCaster():SetForwardVector(new_dir)
    self:GetCaster():FaceTowards(self.target:GetAbsOrigin())
    if self:GetCaster():HasModifier("modifier_fymryn_black_mirror_illusion_active") or not self:GetCaster():HasModifier("modifier_fymryn_black_mirror_illusion") then
        self:GetCaster():RemoveNoDraw()
    end
end