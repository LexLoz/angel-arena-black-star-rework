LinkLuaModifier("modifier_fymryn_shadow_step", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_fymryn_shadow_step_debuff", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_shadow_step_end", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_shadow_step_start", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_fymryn_shadow_step_visual", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_knockback_lua", "heroes/hero_fymryn/modifier_generic_knockback_lua.lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_generic_knockback_fymryn", "heroes/hero_fymryn/modifier_generic_knockback_fymryn.lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_generic_knockback_fymryn_knockback_cooldown", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_fymryn_shadow_step_buff_attack_speed", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_shadow_step_buff_attack", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_shadow_step_creep_damage", "heroes/hero_fymryn/fymryn_shadow_step", LUA_MODIFIER_MOTION_NONE)

fymryn_shadow_step = class({})

function fymryn_shadow_step:Precache(context)
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/sxssss/drow_banshee_wail_parent.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/sxssss/drow_banshee_wail_explosion.vpcf', context )
end

function fymryn_shadow_step:OnSpellStart()
    if not IsServer() then return end

    self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_2)

    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_fymryn_shadow_step_start", {duration = 0.6})

    local direction = self:GetCaster():GetForwardVector() * -1
    local knockback = self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_generic_knockback_fymryn", { direction_x = direction.x, direction_y = direction.y, distance = 80, height = 0, duration = 0.15 })

    local callback = function( bInterrupted )
        Timers:CreateTimer(FrameTime(), function()
            self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_2_END)
            local direction_f = self:GetCaster():GetForwardVector()
            self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_generic_knockback_fymryn", { direction_x = direction_f.x, direction_y = direction_f.y, distance = 380, height = 50, duration = 0.35, check_target = 1 })
        end)
    end

    knockback:SetEndCallback( callback )
end

--380 150

modifier_fymryn_shadow_step_start = class({})
function modifier_fymryn_shadow_step_start:IsPurgable() return false end
function modifier_fymryn_shadow_step_start:IsHidden() return true end
function modifier_fymryn_shadow_step_start:OnCreated()
    if not IsServer() then return end
    local fymryn_shadowmourne = self:GetCaster():FindAbilityByName("fymryn_shadowmourne")
    if fymryn_shadowmourne then
        fymryn_shadowmourne:SetActivated(false)
    end
    local fymryn_shadow_step = self:GetCaster():FindAbilityByName("fymryn_shadow_step")
    if fymryn_shadow_step then
        fymryn_shadow_step:SetActivated(false)
    end
    local fymryn_stretching = self:GetCaster():FindAbilityByName("fymryn_stretching")
    if fymryn_stretching then
        fymryn_stretching:SetActivated(false)
    end
    local fymryn_black_mirror = self:GetCaster():FindAbilityByName("fymryn_black_mirror")
    if fymryn_black_mirror then
        fymryn_black_mirror:SetActivated(false)
    end
    self.interrupt = false
end

function modifier_fymryn_shadow_step_start:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }
end

function modifier_fymryn_shadow_step_start:GetModifierDisableTurning( params )
	return 1
end

function modifier_fymryn_shadow_step_start:OnDestroy()
    if not IsServer() then return end
    local fymryn_shadowmourne = self:GetCaster():FindAbilityByName("fymryn_shadowmourne")
    if fymryn_shadowmourne then
        fymryn_shadowmourne:SetActivated(true)
    end
    local fymryn_shadow_step = self:GetCaster():FindAbilityByName("fymryn_shadow_step")
    if fymryn_shadow_step then
        fymryn_shadow_step:SetActivated(true)
    end
    local fymryn_stretching = self:GetCaster():FindAbilityByName("fymryn_stretching")
    if fymryn_stretching then
        fymryn_stretching:SetActivated(true)
    end
    local fymryn_black_mirror = self:GetCaster():FindAbilityByName("fymryn_black_mirror")
    if fymryn_black_mirror then
        fymryn_black_mirror:SetActivated(true)
    end
    if self.interrupt then return end
    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step", {duration = self:GetAbility():GetSpecialValueFor("duration")})
    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_visual", {})
end

function modifier_fymryn_shadow_step_start:CheckState()
    return
    {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_DISARMED] = true,
        --[MODIFIER_STATE_SILENCED] = true,
        --[MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_STUNNED] = true,
    }
end

modifier_fymryn_shadow_step = class({})

function modifier_fymryn_shadow_step:IsPurgable() return false end
function modifier_fymryn_shadow_step:IsPurgeException() return false end

function modifier_fymryn_shadow_step:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_EVENT_ON_ORDER,
    }
end

function modifier_fymryn_shadow_step:CheckState()
    return
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE_ENEMY] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_DISARMED] = true,
        --[MODIFIER_STATE_SILENCED] = true,
        --[MODIFIER_STATE_MUTED] = true,
    }
end

function modifier_fymryn_shadow_step:GetModifierDisableTurning( params )
	return 1
end

function modifier_fymryn_shadow_step:OnCreated( kv )
	if not IsServer() then return end

    local fymryn_shadowmourne = self:GetCaster():FindAbilityByName("fymryn_shadowmourne")
    if fymryn_shadowmourne then
        fymryn_shadowmourne:SetActivated(false)
    end
    local fymryn_shadow_step = self:GetCaster():FindAbilityByName("fymryn_shadow_step")
    if fymryn_shadow_step then
        fymryn_shadow_step:SetActivated(false)
    end
    local fymryn_stretching = self:GetCaster():FindAbilityByName("fymryn_stretching")
    if fymryn_stretching then
        fymryn_stretching:SetActivated(false)
    end
    local fymryn_black_mirror = self:GetCaster():FindAbilityByName("fymryn_black_mirror")
    if fymryn_black_mirror then
        fymryn_black_mirror:SetActivated(false)
    end
    self:GetCaster():RemoveGesture(ACT_DOTA_CAST_ABILITY_2_END)
	self.flCreationTime = GameRules:GetDOTATime( false, true )
	local hAbility = self:GetAbility()
	self.max_speed = self:GetAbility():GetSpecialValueFor("speed")
	self.acceleration = 350
	self.deceleration = 500
	self.turn_rate_min = 360
	self.turn_rate_max = 360
	self.impact_radius = 150
	self.impact_stun = 0
	self.base_damage = 0
	self.damage_per_level = 0
	self.knockback_distance = 150
	self.knockback_duration = 0
	self.flCurrentSpeed = self.max_speed
	self.flDespawnTime = 0.5
	self.nTreeDestroyRadius = 75
	self.bMaxSpeedNotified = false
	self.bCrashScheduled = false
	self.hCrashScheduledUnit = nil
    local obs = self:GetParent():GetAbsOrigin() +  self:GetParent():GetForwardVector() * 100
    local vDir = obs - self:GetParent():GetAbsOrigin()
	vDir.z = 0
	vDir = vDir:Normalized()
	local angles = VectorAngles( vDir )
	self:GetParent().flDesiredYaw = angles.y
	if self:ApplyHorizontalMotionController() == false then 
		self:Destroy()
		return
	end
	self:StartIntervalThink( FrameTime() )
end

function modifier_fymryn_shadow_step:OnIntervalThink()
    if not IsServer() then return end

    local friendlys = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, 100, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
	for _, friendly in pairs(friendlys) do
        if not friendly:HasModifier("modifier_generic_knockback_fymryn_knockback_cooldown") then
            local direction = friendly:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()
            local length = direction:Length2D()
            direction.z = 0
            direction = direction:Normalized()
            friendly:AddNewModifier(
                self:GetCaster(),
                self,
                "modifier_generic_knockback_lua",
                {
                    direction_x = direction.x,
                    direction_y = direction.y,
                    distance = 70,
                    duration = 0.1,
                }
            )
            friendly:AddNewModifier(friendly, nil, "modifier_generic_knockback_fymryn_knockback_cooldown", {duration = 0.4})
        end
    end

    self:CheckEnemies(100)
end

function modifier_fymryn_shadow_step:CheckEnemies(radius)
    local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
	for _, target in pairs(enemies) do
        target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration_slow")})
        local modifier = self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_buff_attack", {} )
        self:GetCaster():PerformAttack ( target, true, true, true, false, false, false, true )
        if modifier and not modifier:IsNull() then
            modifier:Destroy()
        end
        self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_buff_attack_speed", {duration = self:GetRemainingTime() + 0.3} )
        self.enemy = true
        self:Destroy()
        local victim_angle = target:GetAnglesAsVector()
        local victim_forward_vector = target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()
        victim_forward_vector.z = 0
        victim_forward_vector = victim_forward_vector:Normalized()
        local attacker_new = target:GetAbsOrigin() + (victim_forward_vector) * 175
        attacker_new = GetGroundPosition(attacker_new, self:GetParent())
        self:GetCaster():SetAbsOrigin(attacker_new)
        FindClearSpaceForUnit(self:GetCaster(), attacker_new, true)
        self:GetCaster():SetForwardVector(victim_forward_vector)
        self:GetCaster():MoveToTargetToAttack(target)
        return
    end

    local creeps = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
	for _, target in pairs(creeps) do
        if not target:HasModifier("modifier_fymryn_shadow_step_creep_damage") then
            target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration_slow")})
            target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_creep_damage", {duration = 0.25})
            self:GetCaster():PerformAttack ( target, true, true, true, false, false, false, true )
        end
    end
end

function modifier_fymryn_shadow_step:OnOrder( params )
	if not IsServer() then return end
	if params.unit == self:GetParent() then
		local validMoveOrders =
		{
			[DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
			[DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
			[DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
			[DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
			[DOTA_UNIT_ORDER_PICKUP_ITEM] = true,
			[DOTA_UNIT_ORDER_PICKUP_RUNE] = true,
		}
		if validMoveOrders[params.order_type] then
			local vTargetPos = params.new_pos
			if params.target ~= nil and params.target:IsNull() == false then
				vTargetPos = params.target:GetAbsOrigin()
			end
			local vMountOrigin = self:GetParent():GetOrigin()
			if self.angle_correction ~= nil and self.angle_correction > 0 then
				local flOrderDist = (vMountOrigin - vTargetPos):Length2D()
				vMountOrigin = vMountOrigin + self:GetParent():GetForwardVector() * math.min(self.angle_correction, flOrderDist * 0.75)
			end
			local vDir = vTargetPos - vMountOrigin
			vDir.z = 0
			vDir = vDir:Normalized()
			local angles = VectorAngles( vDir )
			self:GetParent().flDesiredYaw = angles.y
		end
	end
end

function modifier_fymryn_shadow_step:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveHorizontalMotionController( self )
    if self.enemy == nil then
        self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_fymryn_shadow_step_end", {duration = self:GetAbility():GetSpecialValueFor("end_delay")})
    else
        local modifier_fymryn_shadow_step_visual = self:GetParent():FindModifierByName("modifier_fymryn_shadow_step_visual")
        if modifier_fymryn_shadow_step_visual then
            modifier_fymryn_shadow_step_visual:Destroy()
        end
    end
    local fymryn_shadowmourne = self:GetCaster():FindAbilityByName("fymryn_shadowmourne")
    if fymryn_shadowmourne then
        fymryn_shadowmourne:SetActivated(true)
    end
    local fymryn_shadow_step = self:GetCaster():FindAbilityByName("fymryn_shadow_step")
    if fymryn_shadow_step then
        fymryn_shadow_step:SetActivated(true)
    end
    local fymryn_stretching = self:GetCaster():FindAbilityByName("fymryn_stretching")
    if fymryn_stretching then
        fymryn_stretching:SetActivated(true)
    end
    local fymryn_black_mirror = self:GetCaster():FindAbilityByName("fymryn_black_mirror")
    if fymryn_black_mirror then
        fymryn_black_mirror:SetActivated(true)
    end
end

function modifier_fymryn_shadow_step:UpdateHorizontalMotion( me, dt )
	if not IsServer() or not self:GetParent() then return end
	local curAngles = self:GetParent():GetAnglesAsVector()
	local flAngleDiff = AngleDiff( self:GetParent().flDesiredYaw, curAngles.y ) or 0
	local flTurnAmount = dt * ( self.turn_rate_min + self:GetSpeedMultiplier() * ( self.turn_rate_max - self.turn_rate_min ) )
	if self.flLastCrashTime ~= nil and GameRules:GetDOTATime(false, true) - self.flLastCrashTime <= 2.0 then
		flTurnAmount = flTurnAmount * 1.5
	end
	flTurnAmount = math.min( flTurnAmount, math.abs( flAngleDiff ) )
	if flAngleDiff < 0.0 then
		flTurnAmount = flTurnAmount * -1
	end
	if flAngleDiff ~= 0.0 then
		curAngles.y = curAngles.y + flTurnAmount
		me:SetAbsAngles( curAngles.x, curAngles.y, curAngles.z )
	end
	local flMaxSpeed = self.max_speed
	local flAcceleration = self.acceleration or -self.deceleration
	self.flCurrentSpeed = math.max( math.min( self.flCurrentSpeed + ( dt * flAcceleration ), flMaxSpeed ), 0 )
	local vNewPos = self:GetParent():GetOrigin() + self:GetParent():GetForwardVector() * ( dt * self.flCurrentSpeed )
	me:SetOrigin( vNewPos )
end

function modifier_fymryn_shadow_step:OnHorizontalMotionInterrupted()
	if not IsServer() then return end
	self:Destroy()
end

function modifier_fymryn_shadow_step:GetSpeedMultiplier()
	return 0.5 + 0.5 * (self.flCurrentSpeed / self.max_speed)
end

modifier_fymryn_shadow_step_debuff = class({})

function modifier_fymryn_shadow_step_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_fymryn_shadow_step_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_enemy")
end

modifier_fymryn_shadow_step_end = class({})
function modifier_fymryn_shadow_step_end:IsHidden() return true end
function modifier_fymryn_shadow_step_end:IsPurgeException() return false end
function modifier_fymryn_shadow_step_end:IsPurgable() return false end
function modifier_fymryn_shadow_step_end:CheckState()
    return
    {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_fymryn_shadow_step_end:OnCreated()
    if not IsServer() then return end
    self:GetParent():RemoveModifierByName("modifier_fymryn_shadow_step_visual")
    self:GetCaster():RemoveGesture(ACT_DOTA_CAST_ABILITY_2_END)
    self:GetCaster():StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_2_END, 1.1)
    self.speed = self:GetAbility():GetSpecialValueFor("speed")
    self:StartIntervalThink(0.01)
end

function modifier_fymryn_shadow_step_end:OnIntervalThink()
    if not IsServer() then return end
    self.speed = self.speed - (self.speed / self:GetAbility():GetSpecialValueFor("end_delay") * 0.01)
    if self.speed <= 0 then self:Destroy() return end
    local origin = self:GetCaster():GetAbsOrigin() + self:GetCaster():GetForwardVector() * self.speed * 0.01
    origin = GetGroundPosition(origin, self:GetParent())
    self:GetParent():SetAbsOrigin(origin)
end

function modifier_fymryn_shadow_step_end:OnDestroy()
    if not IsServer() then return end
    FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
end

modifier_fymryn_shadow_step_visual = class({})
function modifier_fymryn_shadow_step_visual:IsHidden() return true end
function modifier_fymryn_shadow_step_visual:IsPurgable() return false end
function modifier_fymryn_shadow_step_visual:IsPurgeException() return false end
function modifier_fymryn_shadow_step_visual:OnCreated()
    if not IsServer() then return end
    --self:GetParent():AddNoDraw()
    Timers:CreateTimer(FrameTime(), function()
        self.particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/sxssss/drow_banshee_wail_parent.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt( self.particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
        ParticleManager:SetParticleControlEnt( self.particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
        self:AddParticle(self.particle, false, false, -1, false, false)

        local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/sxssss/drow_banshee_wail_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt( particle, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
        ParticleManager:ReleaseParticleIndex(particle)

        self:GetParent():EmitSound("shadow_start")
        self:GetParent():EmitSound("shadow_loop")
    end)
end
function modifier_fymryn_shadow_step_visual:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MODEL_CHANGE
    }
end
function modifier_fymryn_shadow_step_visual:GetModifierModelChange()
    return "models/units/fymryn/fymryn_smoke.vmdl"
end
function modifier_fymryn_shadow_step_visual:OnDestroy()
    if not IsServer() then return end
    self:GetParent():EmitSound("shadow_end")
    self:GetParent():StopSound("shadow_loop")
    local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/sxssss/drow_banshee_wail_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt( particle, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
    ParticleManager:ReleaseParticleIndex(particle)
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion") then
        self:GetParent():SetMaterialGroup("smoke")
    end
    --self:GetParent():RemoveNoDraw()
end
function modifier_fymryn_shadow_step_visual:CheckState()
    return
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE_ENEMY] = true,
    }
end

modifier_generic_knockback_fymryn_knockback_cooldown = class({})
function modifier_generic_knockback_fymryn_knockback_cooldown:IsHidden() return true end
function modifier_generic_knockback_fymryn_knockback_cooldown:IsPurgable() return false end
function modifier_generic_knockback_fymryn_knockback_cooldown:IsPurgeException() return false end

modifier_fymryn_shadow_step_buff_attack = class({})
function modifier_fymryn_shadow_step_buff_attack:IsHidden()
	return true
end
function modifier_fymryn_shadow_step_buff_attack:IsPurgable()
	return false
end
function modifier_fymryn_shadow_step_buff_attack:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end
function modifier_fymryn_shadow_step_buff_attack:GetModifierDamageOutgoing_Percentage( params )
	if IsServer() then
		return self:GetAbility():GetSpecialValueFor( "damage_from_attack" ) - 100
	end
end

modifier_fymryn_shadow_step_buff_attack_speed = class({})

function modifier_fymryn_shadow_step_buff_attack_speed:IsPurgable() return false end

function modifier_fymryn_shadow_step_buff_attack_speed:OnCreated()
    if not IsServer() then return end
    if not self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion") then
        self:GetParent():SetMaterialGroup("smoke")
    end
    self:StartIntervalThink(0.1)
end

function modifier_fymryn_shadow_step_buff_attack_speed:OnIntervalThink()
    if not IsServer() then return end
    if not self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion") then
        self:GetParent():SetMaterialGroup("smoke")
    end
    self:StartIntervalThink(-1)
end

function modifier_fymryn_shadow_step_buff_attack_speed:OnDestroy()
    if not IsServer() then return end
    if not self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion") then
        print("aaaa")
        self:GetParent():SetMaterialGroup("default")
    else
        self:GetParent():SetMaterialGroup("smoke")
    end
end

function modifier_fymryn_shadow_step_buff_attack_speed:CheckState()
    return
    {
        [MODIFIER_STATE_UNTARGETABLE_ENEMY] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
    }
end

function modifier_fymryn_shadow_step_buff_attack_speed:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_fymryn_shadow_step_buff_attack_speed:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("buff_attack_speed")
end

modifier_fymryn_shadow_step_creep_damage = class({})
function modifier_fymryn_shadow_step_creep_damage:IsHidden() return true end