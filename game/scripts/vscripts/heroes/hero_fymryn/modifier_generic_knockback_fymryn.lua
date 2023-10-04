modifier_generic_knockback_fymryn = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_generic_knockback_fymryn:IsHidden()
	return true
end

function modifier_generic_knockback_fymryn:IsPurgable()
	return false
end

function modifier_generic_knockback_fymryn:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_generic_knockback_fymryn:OnCreated( kv )
	if IsServer() then
		-- creation data (default)
			-- kv.distance (0)
			-- kv.height (-1)
			-- kv.duration (0)
			-- kv.direction_x, kv.direction_y, kv.direction_z (xy:-forward vector, z:0)
			-- kv.tree_destroy_radius (hull-radius), can be null if -1 
			-- kv.IsStun (false)
			-- kv.IsFlail (true)
			-- kv.IsPurgable() // later 
			-- kv.IsMultiple() // later

		-- references
		self.distance = kv.distance or 0
        self.check_target = kv.check_target
		self.height = kv.height or -1
		self.duration = kv.duration or 0
		if kv.direction_x and kv.direction_y then
			self.direction = Vector(kv.direction_x,kv.direction_y,0):Normalized()
		else
			self.direction = -(self:GetParent():GetForwardVector())
		end
		self.tree = kv.tree_destroy_radius or self:GetParent():GetHullRadius()

		if kv.IsStun then self.stun = kv.IsStun==1 else self.stun = false end
		if kv.IsFlail then self.flail = kv.IsFlail==1 else self.flail = true end

		-- check duration
		if self.duration == 0 then
			self:Destroy()
			return
		end

		-- load data
		self.parent = self:GetParent()
		self.origin = self.parent:GetOrigin()

		-- horizontal init
		self.hVelocity = self.distance/self.duration

		-- vertical init
		local half_duration = self.duration/2
		self.gravity = 2*self.height/(half_duration*half_duration)
		self.vVelocity = self.gravity*half_duration

		-- apply motion controllers
		if self.distance>0 then
			if self:ApplyHorizontalMotionController() == false then 
				self:Destroy()
				return
			end
		end
		if self.height>=0 then
			if self:ApplyVerticalMotionController() == false then 
				self:Destroy()
				return
			end
		end

		-- tell client of activity
		if self.flail then
			self:SetStackCount( 1 )
		elseif self.stun then
			self:SetStackCount( 2 )
		end
	else
		self.anim = self:GetStackCount()
		self:SetStackCount( 0 )
	end
end

function modifier_generic_knockback_fymryn:OnRefresh( kv )
	if not IsServer() then return end
end

function modifier_generic_knockback_fymryn:OnDestroy( kv )
	if not IsServer() then return end

	if not self.interrupted then
		-- destroy trees
		if self.tree>0 then
			GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), self.tree, true )
		end
	end

    if self.interrupted then
        local modifier_fymryn_shadow_step_start = self:GetParent():FindModifierByName("modifier_fymryn_shadow_step_start")
        if modifier_fymryn_shadow_step_start then
            modifier_fymryn_shadow_step_start.interrupt = true
        end
    end

	if self.EndCallback then
		self.EndCallback( self.interrupted )
	end

	self:GetParent():InterruptMotionControllers( true )
end

--------------------------------------------------------------------------------
-- Setter
function modifier_generic_knockback_fymryn:SetEndCallback( func ) 
	self.EndCallback = func
end

function modifier_generic_knockback_fymryn:CheckState()
	local state = 
    {
		[MODIFIER_STATE_STUNNED] = true,
	}
	return state
end

--------------------------------------------------------------------------------
-- Motion effects
function modifier_generic_knockback_fymryn:UpdateHorizontalMotion( me, dt )
	local parent = self:GetParent()
	
	-- set position
	local target = self.direction*self.distance*(dt/self.duration)

    if self:GetRemainingTime() <= 0.3 then
        if self.check_target and self.check_target == 1 then
            self:CheckEnemies(100)
        end
    end

    if self:CheckStun(self:GetParent()) or self:GetParent():IsSilenced() then
        self.interrupted = true
        self:Destroy()
        local fymryn_shadow_step = self:GetCaster():FindAbilityByName("fymryn_shadow_step")
        if fymryn_shadow_step then
            fymryn_shadow_step:EndCooldown()
        end
    end

	-- change position
	parent:SetOrigin( parent:GetOrigin() + target )
end

function modifier_generic_knockback_fymryn:CheckStun(parent)
    local exclusive = 
    {
        ["modifier_fymryn_shadow_step"] = true,
        ["modifier_fymryn_shadow_step_end"] = true,
        ["modifier_fymryn_shadow_step_start"] = true,
        ["modifier_generic_knockback_fymryn"] = true,
        
    }
    for _, mod in pairs(parent:FindAllModifiers()) do
        local tables = {}
        mod:CheckStateToTable(tables)
        for state_name, mod_table in pairs(tables) do
            if tostring(state_name) == tostring(MODIFIER_STATE_STUNNED) and exclusive[mod:GetName()] == nil then
                return true
            end
        end
    end
    return false
end

function modifier_generic_knockback_fymryn:CheckEnemies(radius)
    local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
	for _, target in pairs(enemies) do
        target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration_slow")})
        local modifier = self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_buff_attack", {} )
        self:GetCaster():PerformAttack ( target, true, true, true, false, false, false, true )
        if modifier and not modifier:IsNull() then
            modifier:Destroy()
        end
        self.interrupted = true
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
        self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_fymryn_shadow_step_buff_attack_speed", {duration = self:GetAbility():GetSpecialValueFor("duration")+0.3} )
        return
    end
end

function modifier_generic_knockback_fymryn:OnHorizontalMotionInterrupted()
	if IsServer() then
		self.interrupted = true
		self:Destroy()
	end
end

function modifier_generic_knockback_fymryn:UpdateVerticalMotion( me, dt )
	-- set time
	local time = dt/self.duration

	-- change height
	self.parent:SetOrigin( self.parent:GetOrigin() + Vector( 0, 0, self.vVelocity*dt ) )

	-- calculate vertical velocity
	self.vVelocity = self.vVelocity - self.gravity*dt
end

function modifier_generic_knockback_fymryn:OnVerticalMotionInterrupted()
	if IsServer() then
		self.interrupted = true
		self:Destroy()
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_generic_knockback_fymryn:GetEffectName()
	if not IsServer() then return end
	if self.stun then
		return "particles/generic_gameplay/generic_stunned.vpcf"
	end
end

function modifier_generic_knockback_fymryn:GetEffectAttachType()
	if not IsServer() then return end
	return PATTACH_OVERHEAD_FOLLOW
end