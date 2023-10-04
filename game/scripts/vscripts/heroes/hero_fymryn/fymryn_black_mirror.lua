LinkLuaModifier("modifier_fymryn_black_mirror_thinker", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_thinker_debuff", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_spawn", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_thinker_check_location", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_illusion", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_illusion_active", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_phased", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_attack_immune", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_death", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_thinker_check_location_illusion", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_order_filter", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_passive_illusion_cast", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_passive_illusion_die", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_black_mirror_passive_illusion_teleport_afk", "heroes/hero_fymryn/fymryn_black_mirror", LUA_MODIFIER_MOTION_NONE)


fymryn_black_mirror = class({})

function fymryn_black_mirror:Precache(context)
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/sxssss/ultimate.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/fymryn/self_impact.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/units/heroes/hero_phantom_lancer/phantom_lancer_spawn_illusion.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/test_fymryn_smoke.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/fymryn_particle_ground_ultimate.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/units/heroes/hero_abaddon/abaddon_ambient_feet_d.vpcf', context )
end

function fymryn_black_mirror:OnSpellStart()
    if not IsServer() then return end
    if not self.first_cast then
        self:SpawnIllusions()
        self.first_cast = true
    end
    local target = self:GetCursorTarget()
    self:RemoveThinker(thinker)
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_fymryn_black_mirror_spawn", {target = target:entindex()})
end

function fymryn_black_mirror:GetIntrinsicModifierName()
    return "modifier_fymryn_black_mirror_order_filter"
end

---------------------- FUNCTIONS CREATE AND DELETE AOE RING

function fymryn_black_mirror:SaveCurrentThinker(thinker, target)
    self.thinker = thinker
    self.target = target
end

function fymryn_black_mirror:RemoveThinker()
    if self.thinker and not self.thinker:IsNull() then
        self.thinker:Destroy()
        self.thinker = nil
    end
    self:GetCaster():RemoveModifierByName("modifier_fymryn_black_mirror_thinker_check_location")
    if self.target and not self.target:IsNull() then
        --self.target:RemoveModifierByName("modifier_fymryn_black_mirror_thinker_check_location")
        self.target = nil
    end
    for _, illusion in pairs(self.illusions) do
        illusion:RemoveModifierByName("modifier_fymryn_black_mirror_thinker_check_location_illusion")
        illusion:RemoveModifierByName("modifier_fymryn_black_mirror_illusion_active")
    end
end

------------- INIT ILLUSIONS -----------------------------------------------------------------

function fymryn_black_mirror:SpawnIllusions()
    if self:GetCaster():HasModifier("modifier_fymryn_black_mirror_illusion") then return end
    if self.illusions == nil then 
        self.illusions = {} 
    end
    for i = 1, 8 do
        Timers:CreateTimer("fymryn_illusions"..i,
            {
                useGameTime = false,
                endTime = 0.5 * i,
                callback = function()
                    self:CreateIllusion(i)
                end
            }
        )
    end
end

function fymryn_black_mirror:CreateIllusion()
	if self.illusions == nil then
        self.illusions = {}
    end
	local illusion = Illusions:create({
        unit = self:GetCaster(),
        ability = self,
        origin = self:GetCaster():GetAbsOrigin(),
        damageIncoming = 0,
        damageOutgoing = 100,
        duration = 999,
    })--CreateUnitByName(self:GetCaster():GetFullName(), self:GetCaster():GetAbsOrigin(), false, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
	if illusion then
		illusion.owner = self:GetCaster()
		illusion:AddNewModifier(self:GetCaster(), self, "modifier_fymryn_black_mirror_illusion", {})
        illusion:AddNewModifier(self:GetCaster(), self, "modifier_fymryn_black_mirror_death", {})
		table.insert(self.illusions, illusion)
        illusion:SetMaterialGroup("smoke")
	end
end

------------------------ AOE THINKER ----------------------------------------------------------

modifier_fymryn_black_mirror_thinker = class({})
function modifier_fymryn_black_mirror_thinker:IsHidden() return true end
function modifier_fymryn_black_mirror_thinker:IsPurgable() return false end
function modifier_fymryn_black_mirror_thinker:IsPurgeException() return false end
function modifier_fymryn_black_mirror_thinker:OnCreated()
    if not IsServer() then return end
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/sxssss/ultimate.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(self.radius,1,1))
	self:AddParticle(particle, false, false, -1, false, false)
end
function modifier_fymryn_black_mirror_thinker:IsAura()
    return true
end
function modifier_fymryn_black_mirror_thinker:GetModifierAura()
    return "modifier_fymryn_black_mirror_thinker_debuff"
end
function modifier_fymryn_black_mirror_thinker:GetAuraRadius()
    return self.radius
end
function modifier_fymryn_black_mirror_thinker:GetAuraDuration()
    return 0
end
function modifier_fymryn_black_mirror_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_fymryn_black_mirror_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function modifier_fymryn_black_mirror_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end
function modifier_fymryn_black_mirror_thinker:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end
function modifier_fymryn_black_mirror_thinker:OnDestroy()
    if not IsServer() then return end
    self:GetAbility():RemoveThinker()
end

-------------- DEBUFF SLOW ----------------------------------------
modifier_fymryn_black_mirror_thinker_debuff = class({})
function modifier_fymryn_black_mirror_thinker_debuff:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")
end
function modifier_fymryn_black_mirror_thinker_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end
function modifier_fymryn_black_mirror_thinker_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

-------------------- SPAWN FUNCTION ---------------------------------------

modifier_fymryn_black_mirror_spawn = class({})
function modifier_fymryn_black_mirror_spawn:IsPurgable() return false end
function modifier_fymryn_black_mirror_spawn:IsPurgeException() return false end
function modifier_fymryn_black_mirror_spawn:IsHidden() return true end

function modifier_fymryn_black_mirror_spawn:OnCreated(params)
    if not IsServer() then return end

    ---------------------------- Create vars ------------------------------
    self.target = EntIndexToHScript(params.target)
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.spawn_radius = self.radius - self:GetAbility():GetSpecialValueFor("radius_out")
    self.new_pos = self.target:GetAbsOrigin()
    self.illusion_count = self:GetAbility():GetSpecialValueFor("illusion_count")
    
    EmitSoundOnLocationWithCaster(self.target:GetAbsOrigin(), "fymryn_ultimate", self:GetCaster())

    ---------------------------Caster Unvisible ------------------------------
    self:GetParent():AddNoDraw()

    -------------------------------Placeholder Particle ----------------------
    local doppleganger_particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn/self_impact.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(doppleganger_particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(doppleganger_particle)
    --ParticleManager:SetParticleControl(doppleganger_particle, 1, self.new_pos + Vector(0,0,75))
    --self:AddParticle(doppleganger_particle, false, false, -1, false, false)
    local delay_spawn = self:GetAbility():GetSpecialValueFor("delay_spawn")
    self:StartIntervalThink(delay_spawn)
end

function modifier_fymryn_black_mirror_spawn:OnIntervalThink()
    if not IsServer() then return end

    ---------------------------- Update vars ------------------------------
    self.new_pos = self.target:GetAbsOrigin()

    -------------------- Destroy Trees -----------------------------------
    GridNav:DestroyTreesAroundPoint(self.new_pos, self.radius, false)

    -------------------------------Placeholder Particle ----------------------
    --self.spawn_particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/units/heroes/hero_phantom_lancer/phantom_lancer_spawn_illusion.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    --ParticleManager:SetParticleControlEnt(self.spawn_particle, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    --ParticleManager:SetParticleControlEnt(self.spawn_particle, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    --ParticleManager:ReleaseParticleIndex(self.spawn_particle)

    if self.target == nil then self:Destroy() return end
    if self.target:IsNull() then self:Destroy() return end
    if not self.target:IsAlive() then self:Destroy() return end

    ----------------------------Visual - Slow thinker -----------------------
    local duration = self:GetAbility():GetSpecialValueFor("duration")
    local thinker = CreateModifierThinker( self:GetCaster(), self:GetAbility(), "modifier_fymryn_black_mirror_thinker", { duration = duration }, self.target:GetAbsOrigin(), self:GetCaster():GetTeamNumber(), false )
    local origin = thinker:GetAbsOrigin()
    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_black_mirror_thinker_check_location", {x=origin.x, y=origin.y, z=origin.z, target = self.target:entindex()})

    -----------------------Spawn and move illusions and caster ------------------------------
    self:IllusionsMove(thinker)

    local target = self.target
    local ability = self:GetAbility()
    Timers:CreateTimer(0.1, function()
        ability:SaveCurrentThinker(thinker, target)
    end)
    self:StartIntervalThink(-1)
end

function modifier_fymryn_black_mirror_spawn:OnDestroy()
    ---------------------------Caster Visible ------------------------------
    if not IsServer() then return end
    self:GetParent():RemoveNoDraw()
end

function modifier_fymryn_black_mirror_spawn:IllusionsMove(thinker)
    if not IsServer() then return end
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local target = self.target
    local all_illusions = {}
    table.insert(all_illusions, self:GetCaster())
    local count = 0
    for _, td in pairs(self:GetAbility().illusions) do
        if count < self.illusion_count then
            table.insert(all_illusions, td)
            count = count + 1
        else
            break
        end
    end

    local position = thinker:GetAbsOrigin()
    local points = {}
    for i = 1, #all_illusions do
        local point_new = GetGroundPosition(position + self.spawn_radius*Rotation2D(Vector(0,1,0), math.rad((i-0.25)*360/#all_illusions)), nil)
        table.insert(points, point_new)
    end

    points = Shuffle(points)
    
    local delay = 0

    for i = 1, #all_illusions do
        Timers:CreateTimer(i * delay, function()
            if target == nil then 
                caster:RemoveModifierByName("modifier_fymryn_black_mirror_spawn")
                return 
            end
            if target:IsNull() then 
                caster:RemoveModifierByName("modifier_fymryn_black_mirror_spawn")
                return 
            end
            if not target:IsAlive() then 
                caster:RemoveModifierByName("modifier_fymryn_black_mirror_spawn")
                return 
            end
            if not caster:IsAlive() then 
                caster:RemoveModifierByName("modifier_fymryn_black_mirror_spawn")
                return 
            end
            if not caster:HasModifier("modifier_fymryn_black_mirror_thinker_check_location") then
                caster:RemoveModifierByName("modifier_fymryn_black_mirror_spawn")
                return
            end
            local illusion = all_illusions[i]
            
            illusion:AddNewModifier(caster, nil, "modifier_fymryn_black_mirror_phased", {duration = 2})
            local pos = points[i]
            illusion:SetAbsOrigin(pos)
            FindClearSpaceForUnit(illusion, pos, true)

            local dir = target:GetAbsOrigin() - pos
            dir.z = 0
            dir = dir:Normalized()

            local doppleganger_particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn/self_impact.vpcf", PATTACH_WORLDORIGIN, illusion)
            ParticleManager:SetParticleControl(doppleganger_particle, 0, illusion:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(doppleganger_particle)

            if illusion ~= caster then
                illusion:AddNewModifier(caster, ability, "modifier_fymryn_black_mirror_death", {x=pos.x,y=pos.y,z=pos.z,target=target:entindex()})
            end
            illusion:SetForwardVector(dir)
            illusion:FaceTowards(target:GetAbsOrigin())
            
            if illusion ~= caster then
                illusion:SetHealth(illusion:GetMaxHealth())
                illusion:SetMana(illusion:GetMaxMana())
                illusion:AddNewModifier(caster, ability, "modifier_fymryn_black_mirror_illusion_active", {target = target:entindex()})
                illusion:AddNewModifier(caster, ability, "modifier_fymryn_black_mirror_thinker_check_location_illusion", {x=position.x, y=position.y, z=position.z})
            else
                caster:RemoveModifierByName("modifier_fymryn_black_mirror_spawn")
                --caster:StartGesture(ACT_DOTA_SPAWN)
            end
        end)
        delay = 0.02
    end
end

function modifier_fymryn_black_mirror_spawn:CheckState()
    return 
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_STUNNED] = true,
    }
end

------------------ MODIFIER CHECK DISTANCE IN AOE -------------------
modifier_fymryn_black_mirror_thinker_check_location = class({})
function modifier_fymryn_black_mirror_thinker_check_location:IsHidden() return false end
function modifier_fymryn_black_mirror_thinker_check_location:IsPurgable() return false end
function modifier_fymryn_black_mirror_thinker_check_location:IsPurgeException() return false end
function modifier_fymryn_black_mirror_thinker_check_location:RemoveOnDeath() return false end
function modifier_fymryn_black_mirror_thinker_check_location:OnCreated(params)
    if not IsServer() then return end
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.target = EntIndexToHScript(params.target)
    self.center = Vector(params.x,params.y,params.z)
    self:StartIntervalThink(0.5)
end
function modifier_fymryn_black_mirror_thinker_check_location:OnIntervalThink()
    if not IsServer() then return end
    if not self:GetParent():IsPositionInRange(self.center, self.radius) or not self:GetParent():IsAlive() then
        self:GetAbility():RemoveThinker()
    end
    if not self.target:IsPositionInRange(self.center, self.radius) or not self.target:IsAlive() then
        self:GetAbility():RemoveThinker()
    end
    self:StartIntervalThink(0.1)
end

modifier_fymryn_black_mirror_thinker_check_location_illusion = class({})
function modifier_fymryn_black_mirror_thinker_check_location_illusion:IsHidden() return false end
function modifier_fymryn_black_mirror_thinker_check_location_illusion:IsPurgable() return false end
function modifier_fymryn_black_mirror_thinker_check_location_illusion:IsPurgeException() return false end
function modifier_fymryn_black_mirror_thinker_check_location_illusion:OnCreated(params)
    if not IsServer() then return end
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.center = Vector(params.x,params.y,params.z)
    self:StartIntervalThink(0.5)
end
function modifier_fymryn_black_mirror_thinker_check_location_illusion:OnIntervalThink()
    if not IsServer() then return end
    if not self:GetParent():IsPositionInRange(self.center, self.radius) then
        local modifier_fymryn_black_mirror_death = self:GetParent():FindModifierByName("modifier_fymryn_black_mirror_death")
        if modifier_fymryn_black_mirror_death then
            modifier_fymryn_black_mirror_death:StartDeath()
        end
    end
    self:StartIntervalThink(0.1)
end

---------- PASSIVE SPAWN ILLUSION MODIFIER ------------------------------
modifier_fymryn_black_mirror_illusion = class({})

function modifier_fymryn_black_mirror_illusion:IsHidden()
	return true
end

function modifier_fymryn_black_mirror_illusion:IsPurgable()
	return false
end

function modifier_fymryn_black_mirror_illusion:IsPurgeException()
	return false
end

function modifier_fymryn_black_mirror_illusion:OnCreated(params)
	if IsServer() then
		self:GetParent():SetDayTimeVisionRange(0)
		self:GetParent():SetNightTimeVisionRange(0)
		self:GetParent():AddNoDraw()
		self:GetParent():SetOrigin(Vector(-7500.25, 7594.84, 15))
	end
end

function modifier_fymryn_black_mirror_illusion:CheckState()
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then
        return
        {
            [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true,
            [MODIFIER_STATE_UNTARGETABLE] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        }
    end
    return 
    {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }
end

function modifier_fymryn_black_mirror_illusion:DeclareFunctions()
	return 
    {
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_PROPERTY_DISABLE_AUTOATTACK,
		MODIFIER_PROPERTY_TEMPEST_DOUBLE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_TEMPEST_DOUBLE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_fymryn_black_mirror_illusion:GetModifierTempestDouble() return 1 end

function modifier_fymryn_black_mirror_illusion:GetAbsoluteNoDamagePhysical()
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    return 1
end

function modifier_fymryn_black_mirror_illusion:GetAbsoluteNoDamagePure()
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    return 1
end

function modifier_fymryn_black_mirror_illusion:GetAbsoluteNoDamageMagical()
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    return 1
end

function modifier_fymryn_black_mirror_illusion:GetDisableAutoAttack(params)
	return 1
end

function modifier_fymryn_black_mirror_illusion:GetModifierTempestDouble(params)
	return 1
end

function modifier_fymryn_black_mirror_illusion:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("illusion_damage_incoming") - 100
end

function modifier_fymryn_black_mirror_illusion:GetModifierTotalDamageOutgoing_Percentage(params)
    if params.damage_type == DAMAGE_TYPE_MAGICAL then
        return -60
    end
    return self:GetAbility():GetSpecialValueFor("illusion_damage_outgoing") - 100
end

---------- ACTIVE ILLUSION MODIFIER ------------------------------

modifier_fymryn_black_mirror_illusion_active = class({})
function modifier_fymryn_black_mirror_illusion_active:IsHidden() return true end
function modifier_fymryn_black_mirror_illusion_active:IsPurgable() return false end
function modifier_fymryn_black_mirror_illusion_active:IsPurgeException() return false end
function modifier_fymryn_black_mirror_illusion_active:OnCreated(params)
    if not IsServer() then return end

    self.target = EntIndexToHScript(params.target)
    self.orders = {}
    --- ILLUSION ULTIMATE START EFFECTS -------------------
    
    
    local illusion = self:GetParent()
    local hCaster = self:GetCaster()

    if params.illusion_chance then
        illusion:StartGesture(ACT_DOTA_CAST_ABILITY_6)
    else
        --illusion:StartGesture(ACT_DOTA_SPAWN)
    end

    local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn_particle_ground_ultimate.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(particle, false, false, -1, false, false)

    self:GetParent():SetDayTimeVisionRange(600)
    self:GetParent():SetNightTimeVisionRange(600)

    for i = 0,24 do
        local ability = self:GetParent():GetAbilityByIndex(i)
        local caster_ability = self:GetCaster():GetAbilityByIndex(i)
        if ability and caster_ability and not caster_ability:IsAttributeBonus() then
            ability:SetLevel(caster_ability:GetLevel())
            ability:EndCooldown()
            ability:RefreshCharges()
        end
    end

    for i = 0, 5 do
        local item = self:GetParent():GetItemInSlot(i)
        if item then
            item:Destroy()
        end
    end

    local neutral_item = self:GetParent():GetItemInSlot(16)
    if neutral_item then
        neutral_item:Destroy()
    end

    for i = 0, 5 do
        local item = self:GetCaster():GetItemInSlot(i)
        if item and item:GetName() ~= "item_aegis" then
            local new_item = CreateItem(item:GetName(), nil, nil)
            local illusion_item = self:GetParent():AddItem(new_item)
            illusion_item:SetPurchaser(nil)
            if item and item:GetCurrentCharges() > 0 and new_item and not new_item:IsNull() then
                new_item:SetCurrentCharges(item:GetCurrentCharges())
            end
            if new_item and not new_item:IsNull() then 
                self:GetParent():SwapItems(new_item:GetItemSlot(), i)
            end
            new_item:EndCooldown()
        end
    end

    local neutral_item_new = self:GetCaster():GetItemInSlot(16)
    if neutral_item_new then
        local new_item = CreateItem(neutral_item_new:GetName(), nil, nil)
        local illusion_item = self:GetParent():AddItem(new_item)
        illusion_item:SetPurchaser(nil)
        if item and neutral_item_new:GetCurrentCharges() > 0 and new_item and not new_item:IsNull() then
            new_item:SetCurrentCharges(neutral_item_new:GetCurrentCharges())
        end
        new_item:EndCooldown()
    end

    for level = 1, self:GetCaster():GetLevel() do
        if self:GetParent():GetLevel() < self:GetCaster():GetLevel() then
            self:GetParent():HeroLevelUp(false)
        end
    end

    Timers:CreateTimer(FrameTime(), function()
        illusion:RemoveNoDraw()
    end)

    self.min_delay = self:GetAbility():GetSpecialValueFor("min_delay")
    self.max_delay = self:GetAbility():GetSpecialValueFor("max_delay")

    self:StartIntervalThink(RandomFloat(self.min_delay, self.max_delay))
end

function modifier_fymryn_black_mirror_illusion_active:AddEventCast(order)
    if #self.orders > 0 then
        local last_order = self.orders[#self.orders]
        if last_order then
            if order["type"] == "attack" and last_order["type"] == "attack" then
                return
            end
            if order["type"] == "stop" and last_order["type"] == "stop" then
                return
            end
        end
    end
    table.insert(self.orders, order)
end

function modifier_fymryn_black_mirror_illusion_active:OnIntervalThink()
    if not IsServer() then return end
    if #self.orders > 0 and self.target and self.target:IsAlive() then
        local order = table.remove(self.orders, 1)
        local type_order = order["type"]
        local ability = order["ability"]
        local target_type = order["target_type"]
        if type_order == "stop" then
            self:GetParent():Stop()
        elseif type_order == "attack" then
            self:GetParent():MoveToTargetToAttack(self.target)
        elseif type_order == "item" then
            local item = self:GetParent():FindItemInInventory(ability)
            if item then
                if target_type == "no_target" then
                    self:GetParent():CastAbilityNoTarget(item, self:GetParent():GetPlayerOwnerID())
                elseif target_type == "target" then
                    self:GetParent():CastAbilityOnTarget(self.target, item, self:GetParent():GetPlayerOwnerID())
                elseif target_type == "point" then
                    self:GetParent():CastAbilityOnPosition(self.target:GetAbsOrigin(), item, self:GetParent():GetPlayerOwnerID())
                end
            end
        elseif type_order == "ability" then
            local ability_cast = self:GetParent():FindAbilityByName(ability)
            if ability_cast then
                if target_type == "no_target" then
                    self:GetParent():CastAbilityNoTarget(ability_cast, self:GetParent():GetPlayerOwnerID())
                elseif target_type == "target" then
                    self:GetParent():CastAbilityOnTarget(self.target, ability_cast, self:GetParent():GetPlayerOwnerID())
                end
            end
        end
    end
end

function modifier_fymryn_black_mirror_illusion_active:OnDestroy()
    --- ILLUSION ULTIMATE END EFFECTS -----------------------------
    if not IsServer() then return end
    self:GetParent():SetDayTimeVisionRange(0)
    self:GetParent():SetNightTimeVisionRange(0)
    self:GetParent():AddNoDraw()
    self:GetParent():Stop()
    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_fymryn_black_mirror_passive_illusion_teleport_afk", {duration = 1})
end

function modifier_fymryn_black_mirror_illusion_active:GetEffectName()
    return "particles/arena/units/heroes/hero_fymryn/units/heroes/hero_abaddon/abaddon_ambient_feet_d.vpcf"
end

function modifier_fymryn_black_mirror_illusion_active:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_fymryn_black_mirror_passive_illusion_teleport_afk = class({})
function modifier_fymryn_black_mirror_passive_illusion_teleport_afk:IsHidden() return true end
function modifier_fymryn_black_mirror_passive_illusion_teleport_afk:IsPurgable() return false end
function modifier_fymryn_black_mirror_passive_illusion_teleport_afk:IsPurgeException() return false end
function modifier_fymryn_black_mirror_passive_illusion_teleport_afk:OnDestroy()
    if not IsServer() then return end
    if not self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then
        self:GetParent():SetOrigin(Vector(-7500.25, 7594.84, 15))
    end
end

------------------- BONUS MODIFIERS ----------------------------------------

modifier_fymryn_black_mirror_phased = class({})
function modifier_fymryn_black_mirror_phased:IsHidden() return true end
function modifier_fymryn_black_mirror_phased:IsPurgable() return false end
function modifier_fymryn_black_mirror_phased:IsPurgeException() return false end
function modifier_fymryn_black_mirror_phased:CheckState()
    return
    {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end
modifier_fymryn_black_mirror_attack_immune = class({})
function modifier_fymryn_black_mirror_attack_immune:IsHidden() return true end
function modifier_fymryn_black_mirror_attack_immune:IsPurgable() return false end
function modifier_fymryn_black_mirror_attack_immune:IsPurgeException() return false end
function modifier_fymryn_black_mirror_attack_immune:CheckState()
    return
    {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
    }
end

------------------ DIE ILLUSION ABUSE ------------------------------------

modifier_fymryn_black_mirror_death = class({})
function modifier_fymryn_black_mirror_death:IsHidden() return true end
function modifier_fymryn_black_mirror_death:IsPurgable() return false end
function modifier_fymryn_black_mirror_death:IsPurgeException() return false end

function modifier_fymryn_black_mirror_death:OnCreated(params)
    if not IsServer() then return end
    if params.target then
        self.target = EntIndexToHScript(params.target)
    end
    if params.x then
        self.pos = Vector(params.x,params.y,params.z)
    end
    self.illusion_respawn_delay = self:GetAbility():GetSpecialValueFor("illusion_respawn_delay")
    self:StartIntervalThink(-1)
end

function modifier_fymryn_black_mirror_death:OnRefresh(params)
    if not IsServer() then return end
    self.target = EntIndexToHScript(params.target)
    self.pos = Vector(params.x,params.y,params.z)
    self.illusion_respawn_delay = self:GetAbility():GetSpecialValueFor("illusion_respawn_delay")
    self:StartIntervalThink(-1)
end

function modifier_fymryn_black_mirror_death:OnIntervalThink()
    if not IsServer() then return end
    if not self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then 
        self:StartIntervalThink(-1)
        return 
    end
    local parent = self:GetParent()
    local caster = self:GetCaster()
    self:GetParent():SetHealth(self:GetParent():GetMaxHealth())
    self:GetParent():SetMana(self:GetParent():GetMaxMana())
    self:GetParent():AddNewModifier(caster, nil, "modifier_fymryn_black_mirror_phased", {duration = 2})
    self:GetParent():SetAbsOrigin(self.pos)
    FindClearSpaceForUnit(self:GetParent(), self.pos, true)
    local dir = self.target:GetAbsOrigin() - self.pos
    dir.z = 0
    dir = dir:Normalized()
    self:GetParent():SetForwardVector(dir)
    self:GetParent():FaceTowards(self.target:GetAbsOrigin())
    Timers:CreateTimer(FrameTime(), function()
        parent:RemoveNoDraw()
    end)
    self:StartIntervalThink(-1)
end

function modifier_fymryn_black_mirror_death:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_MIN_HEALTH
    }
end

function modifier_fymryn_black_mirror_death:GetMinHealth()
    return 1
end

function modifier_fymryn_black_mirror_death:OnTakeDamage(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if self:GetParent():GetHealth() <= 1 then
        self:StartDeath()
    end
end

function modifier_fymryn_black_mirror_death:StartDeath()
    if not IsServer() then return end
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_attack_immune") then return end
    if not self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    self:GetParent():AddNewModifier(caster, nil, "modifier_fymryn_black_mirror_attack_immune", {duration = self.illusion_respawn_delay})
    self:GetParent():SetDayTimeVisionRange(0)
    self:GetParent():SetNightTimeVisionRange(0)
    self:GetParent():AddNoDraw()
    self:GetParent():Stop()
    self:GetParent():SetOrigin(Vector(-7500.25, 7594.84, 15))
    self:StartIntervalThink(self.illusion_respawn_delay)
end

--------------- USE SKILLS ILLUSION ORDER --------------------------

modifier_fymryn_black_mirror_order_filter = class({})
function modifier_fymryn_black_mirror_order_filter:IsHidden() return true end
function modifier_fymryn_black_mirror_order_filter:IsPurgeException() return false end
function modifier_fymryn_black_mirror_order_filter:IsPurgable() return false end
function modifier_fymryn_black_mirror_order_filter:RemoveOnDeath() return false end

function modifier_fymryn_black_mirror_order_filter:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ORDER
    }
end

function modifier_fymryn_black_mirror_order_filter:OnOrder(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
        local order = 
        {
            ["type"] = "stop",
            ["ability"] = nil,
            ["target_type"] = nil,
        }
        self:GiveIllusionsOrder(order)
    end
    if params.order_type == DOTA_UNIT_ORDER_ATTACK_MOVE or params.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
        local order = 
        {
            ["type"] = "attack",
            ["ability"] = nil,
            ["target_type"] = nil,
        }
        self:GiveIllusionsOrder(order)
    end
end

function modifier_fymryn_black_mirror_order_filter:OnAttackLanded(params)
    if params.attacker ~= self:GetParent() then return end
    if params.target == self:GetParent() then return end
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    local order = 
    {
        ["type"] = "attack",
        ["ability"] = nil,
        ["target_type"] = nil,
    }
    self:GiveIllusionsOrder(order)
end

function modifier_fymryn_black_mirror_order_filter:OnAbilityFullyCast(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    local hAbility = params.ability
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end

    local type_ability = "ability"

    if hAbility:IsItem() then
        type_ability = "item"
    end

    if bit.band(hAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then 
        local order = 
        {
            ["type"] = type_ability,
            ["ability"] = hAbility:GetAbilityName(),
            ["target_type"] = "no_target",
        }
        self:GiveIllusionsOrder(order)
    elseif bit.band(hAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then 
        local order = 
        {
            ["type"] = type_ability,
            ["ability"] = hAbility:GetAbilityName(),
            ["target_type"] = "target",
        }
        self:GiveIllusionsOrder(order)
        local target = params.target
        if RollPercentage(self:GetAbility():GetSpecialValueFor("chance")) and target ~= nil and target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and hAbility:GetAbilityName() ~= "fymryn_black_mirror" then
            local enemies_targets = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
	        for _, enemy_target in pairs(enemies_targets) do
                if enemy_target ~= target then
                    self:CreateIllusionTarget(hAbility:GetAbilityName(), enemy_target)
                    break
                end
            end
        end
    elseif bit.band(hAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
        local order = 
        {
            ["type"] = type_ability,
            ["ability"] = hAbility:GetAbilityName(),
            ["target_type"] = "point",
        }
        self:GiveIllusionsOrder(order)
    end
end

function modifier_fymryn_black_mirror_order_filter:GiveIllusionsOrder(order)
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_thinker_check_location") then
        for _, illusion in pairs(self:GetAbility().illusions) do
            local modifier_fymryn_black_mirror_illusion_active = illusion:FindModifierByName("modifier_fymryn_black_mirror_illusion_active")
            if modifier_fymryn_black_mirror_illusion_active then
                modifier_fymryn_black_mirror_illusion_active:AddEventCast(order)
            end
        end
    end
end

function modifier_fymryn_black_mirror_order_filter:CreateIllusionTarget(ability, target)
    if not IsServer() then return end
    if self:GetParent():HasModifier("modifier_fymryn_black_mirror_illusion_active") then return end
    if self:GetAbility() == nil then return end
    if self:GetAbility().illusions == nil then return end
    local caster = self:GetCaster()
    local ability_orig = self:GetAbility()
    local illusion = self:GetAbility().illusions[#self:GetAbility().illusions]
    local pos = target:GetAbsOrigin() + RandomVector(RandomInt(200, 300))
    illusion:SetHealth(illusion:GetMaxHealth())
    illusion:SetMana(illusion:GetMaxMana())
    illusion:AddNewModifier(caster, ability_orig, "modifier_fymryn_black_mirror_illusion_active", {target = target:entindex(), illusion_chance = 1})
    illusion:AddNewModifier(caster, nil, "modifier_fymryn_black_mirror_phased", {duration = 2})
    illusion:SetAbsOrigin(pos)
    FindClearSpaceForUnit(illusion, pos, true)
    local dir = target:GetAbsOrigin() - illusion:GetAbsOrigin()
    dir.z = 0
    dir = dir:Normalized()
    illusion:SetForwardVector(dir)
    illusion:FaceTowards(target:GetAbsOrigin())
    illusion:AddNewModifier(caster, ability_orig, "modifier_fymryn_black_mirror_passive_illusion_cast", {duration = 5, ability = ability, target = target:entindex()})
end

modifier_fymryn_black_mirror_passive_illusion_cast = class({})
function modifier_fymryn_black_mirror_passive_illusion_cast:IsHidden() return true end
function modifier_fymryn_black_mirror_passive_illusion_cast:IsPurgable() return false end
function modifier_fymryn_black_mirror_passive_illusion_cast:IsPurgeException() return false end
function modifier_fymryn_black_mirror_passive_illusion_cast:RemoveOnDeath() return false end
function modifier_fymryn_black_mirror_passive_illusion_cast:CheckState()
    return
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
    }
end
function modifier_fymryn_black_mirror_passive_illusion_cast:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
    }
end
function modifier_fymryn_black_mirror_passive_illusion_cast:GetModifierCastRangeBonus()
    return 1600
end
function modifier_fymryn_black_mirror_passive_illusion_cast:OnCreated(params)
    if not IsServer() then return end
    self.ability = params.ability
    self.target = EntIndexToHScript(params.target)
    local ability = self:GetParent():FindAbilityByName(self.ability)
    if ability == nil then
        ability = self:GetParent():FindItemInInventory(self.ability)
    end
    self.delay_start = 0
    self.cast = false
    self.delay = RandomFloat(self:GetAbility():GetSpecialValueFor("min_delay")+0.5, self:GetAbility():GetSpecialValueFor("max_delay")+0.5)
    if ability == nil then self:Destroy() return end
    self.cast_ab = ability
    self:StartIntervalThink(0.1)
end
function modifier_fymryn_black_mirror_passive_illusion_cast:OnIntervalThink()
    if not IsServer() then return end
    self.delay_start = self.delay_start + 0.1
    if self.delay_start > self.delay and not self.cast then
        self.cast = true
        self:GetParent():CastAbilityOnTarget(self.target, self.cast_ab, self:GetParent():GetPlayerOwnerID())
    end
    if self.target == nil or not self.target:IsAlive() or self.target:IsInvulnerable() or ( self.target:IsInvisible() and not self:GetParent():CanEntityBeSeenByMyTeam(self.target) ) then
        self:Destroy()
    end
end
function modifier_fymryn_black_mirror_passive_illusion_cast:OnDestroy()
    if not IsServer() then return end
    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_fymryn_black_mirror_passive_illusion_die", {duration = 0.25})
end
function modifier_fymryn_black_mirror_passive_illusion_cast:OnAbilityFullyCast(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    local hAbility = params.ability
    self:Destroy()
end

modifier_fymryn_black_mirror_passive_illusion_die = class({})
function modifier_fymryn_black_mirror_passive_illusion_die:IsHidden() return true end
function modifier_fymryn_black_mirror_passive_illusion_die:IsPurgable() return false end
function modifier_fymryn_black_mirror_passive_illusion_die:IsPurgeException() return false end
function modifier_fymryn_black_mirror_passive_illusion_die:RemoveOnDeath() return false end
function modifier_fymryn_black_mirror_passive_illusion_die:CheckState()
    return
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
    }
end
function modifier_fymryn_black_mirror_passive_illusion_die:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveModifierByName("modifier_fymryn_black_mirror_illusion_active")
end


-------------------       OTHER FUNCTIONS      ----------------------------------
function Rotation2D(vVector, radian)
	local fLength2D = vVector:Length2D()
	local vUnitVector2D = vVector / fLength2D
	local fCos = math.cos(radian)
	local fSin = math.sin(radian)
	return Vector(vUnitVector2D.x*fCos-vUnitVector2D.y*fSin, vUnitVector2D.x*fSin+vUnitVector2D.y*fCos, vUnitVector2D.z)*fLength2D
end

function Shuffle(tbl)
    -- 必须是一个hash表
    local t = shallowcopy(tbl)
    for i = # t, 2, - 1 do
        local j    = RandomInt(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


--- Ультимеейт имеет пассивку с шансом 30/40/50% создает иллюзию которая использует последний направленный на СОСЕДНЮЮ ЦЕЛЬ
-- атаку передать
-- и стопку передать