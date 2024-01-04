LinkLuaModifier("modifier_generic_knockback_lua", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_aghanim_blink_attack", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_blink_cast = class({})

function aghanim_blink_cast:Precache( context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_preimage.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_faceless_void.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_mars.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_tidehunter.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_shredder.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_rattletrap.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_leshrac.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_wisp.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_wisp.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/custom_sounds.vsndevts", context )
    PrecacheResource( "model", "models/props_gameplay/aghs21_device/aghs21_device.vmdl", context )
    PrecacheResource( "model", "models/aghanim/aghanim_mad.vmdl", context )
    PrecacheResource( "model", "models/aghanim/aghanim_bath.vmdl", context )
    PrecacheResource( "model", "models/aghanim/aghanim_mech.vmdl", context )
    PrecacheResource( "model", "models/aghanim/aghanim_smith.vmdl", context )
end

function aghanim_blink_cast:GetCooldown(level)
    local bonus = 0
    local special_bonus_aghanim_talent_2 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_2")
    if special_bonus_aghanim_talent_2 and special_bonus_aghanim_talent_2:GetLevel() > 0 then
        bonus = special_bonus_aghanim_talent_2:GetSpecialValueFor("value")
    end
    return self.BaseClass.GetCooldown( self, level ) + bonus
end

function aghanim_blink_cast:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end

function aghanim_blink_cast:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function aghanim_blink_cast:OnSpellStart()
    if not IsServer() then return end
    local origin = self:GetCaster():GetOrigin()

    local range = self:GetSpecialValueFor("distance")

    local point = origin + (self:GetCaster():GetForwardVector() * -1) * range

    self.point = self:GetCaster():GetAbsOrigin()

    local distance_teleport = (point - self:GetCaster():GetAbsOrigin()):Length2D()

    local dist_check = (point - self:GetCaster():GetAbsOrigin()):Length2D()

    local direciton = (point - self:GetCaster():GetAbsOrigin())
    direciton.z = 0
    direciton = direciton:Normalized()

    local knockback = self:GetCaster():AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_generic_knockback_lua",
        {
            direction_x = direciton.x,
            direction_y = direciton.y,
            distance = distance_teleport,
            duration = 0.25,
        }
    )

    self:GetCaster():EmitSound("Birzha.VoidJump")

    local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_preimage.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 0, origin )
    ParticleManager:SetParticleControl( nFXIndex, 1, point )
    
    ParticleManager:SetParticleFoWProperties( nFXIndex, 0, 2, 64.0 )
    ParticleManager:ReleaseParticleIndex( nFXIndex )

    local callback = function( bInterrupted )
        FindClearSpaceForUnit( self:GetCaster(), self:GetCaster():GetAbsOrigin(), true )
        ProjectileManager:ProjectileDodge(self:GetCaster())
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_blink_attack", {duration = self:GetSpecialValueFor("ability_duration")})
    end

    knockback:SetEndCallback( callback )
end

modifier_generic_knockback_lua = class({})



function modifier_generic_knockback_lua:IsHidden()
    return true
end

function modifier_generic_knockback_lua:IsPurgable()
    return false
end

function modifier_generic_knockback_lua:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end


function modifier_generic_knockback_lua:OnCreated( kv )
    if IsServer() then
        
            
            
            
            
            
            
            
            
            

        
        self.distance = kv.distance or 0
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

        
        if self.duration == 0 then
            self:Destroy()
            return
        end

        
        self.parent = self:GetParent()
        self.origin = self.parent:GetOrigin()

        
        self.hVelocity = self.distance/self.duration

        
        local half_duration = self.duration/2
        self.gravity = 2*self.height/(half_duration*half_duration)
        self.vVelocity = self.gravity*half_duration

        
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

function modifier_generic_knockback_lua:OnRefresh( kv )
    if not IsServer() then return end
end

function modifier_generic_knockback_lua:OnDestroy( kv )
    if not IsServer() then return end

    if not self.interrupted then
        
        if self.tree>0 then
            GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), self.tree, true )
        end
    end

    if self.EndCallback then
        self.EndCallback( self.interrupted )
    end

    self:GetParent():InterruptMotionControllers( true )
end



function modifier_generic_knockback_lua:SetEndCallback( func ) 
    self.EndCallback = func
end



function modifier_generic_knockback_lua:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = self.stun,
    }

    return state
end



function modifier_generic_knockback_lua:UpdateHorizontalMotion( me, dt )
    local parent = self:GetParent()
    
    
    local target = self.direction*self.distance*(dt/self.duration)

    
    parent:SetOrigin( parent:GetOrigin() + target )
end

function modifier_generic_knockback_lua:OnHorizontalMotionInterrupted()
    if IsServer() then
        self.interrupted = true
        self:Destroy()
    end
end

function modifier_generic_knockback_lua:UpdateVerticalMotion( me, dt )
    
    local time = dt/self.duration

    
    self.parent:SetOrigin( self.parent:GetOrigin() + Vector( 0, 0, self.vVelocity*dt ) )

    
    self.vVelocity = self.vVelocity - self.gravity*dt
end

function modifier_generic_knockback_lua:OnVerticalMotionInterrupted()
    if IsServer() then
        self.interrupted = true
        self:Destroy()
    end
end



function modifier_generic_knockback_lua:GetEffectName()
    if not IsServer() then return end
    if self.stun then
        return "particles/generic_gameplay/generic_stunned.vpcf"
    end
end

function modifier_generic_knockback_lua:GetEffectAttachType()
    if not IsServer() then return end
    return PATTACH_OVERHEAD_FOLLOW
end

modifier_aghanim_blink_attack = class({})

function modifier_aghanim_blink_attack:IsPurgable() return false end
function modifier_aghanim_blink_attack:GetTexture() return "blink_attack" end

function modifier_aghanim_blink_attack:OnCreated()
    if not IsServer() then return end
    self:GetParent():SwapAbilities("aghanim_blink_cast", "aghanim_blink_attack", false, true)
end

function modifier_aghanim_blink_attack:OnDestroy()
    if not IsServer() then return end

    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_blink_cast")

    if aghanim_blink_cast then
        aghanim_blink_cast:EndCooldown()
        aghanim_blink_cast:UseResources(false, false, false, true)
    end

    self:GetParent():SwapAbilities("aghanim_blink_attack", "aghanim_blink_cast", false, true)
end

LinkLuaModifier("modifier_aghanim_blink_attack_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_blink_attack = class({})

function aghanim_blink_attack:Precache( context )
    PrecacheResource( "particle", "particles/econ/events/ti10/portal/portal_open_bad.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/portal_summon.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_portal_summon.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_portal_emit.vpcf", context )
    PrecacheResource( "particle", "particles/econ/events/ti10/portal/portal_emit_large.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf", context )
    PrecacheResource( "particle", "particles/status_fx/status_effect_ghost.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_stomp_magical.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_impact_magical.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_elder_titan.vsndevts", context )
end

function aghanim_blink_attack:OnSpellStart()
    if not IsServer() then return end

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")

    local point = self:GetCaster():GetAbsOrigin()

    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_blink_cast")
    if aghanim_blink_cast then
        point = aghanim_blink_cast.point
    end

    local nFXCastIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_stomp_magical.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( nFXCastIndex, 0, point )
    ParticleManager:SetParticleControl( nFXCastIndex, 1, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( nFXCastIndex )

    EmitSoundOn( "Hero_ElderTitan.EchoStomp", self:GetCaster() )

    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), point, self:GetCaster(), radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
    for _,enemy in pairs( enemies ) do
        if enemy ~= nil and enemy:IsInvulnerable() == false then
            local damageInfo = 
            {
                victim = enemy,
                attacker = self:GetCaster(),
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self,
            }

            ApplyDamage( damageInfo )
            enemy:AddNewModifier( self:GetCaster(), self, "modifier_aghanim_blink_attack_debuff", { duration = duration * (1 - enemy:GetStatusResistance()) } )
            if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
                enemy:AddNewModifier( self:GetCaster(), self, "modifier_aghanim_blink_attack_debuff", { duration = (duration + self:GetSpecialValueFor("stun_shard")) * (1 - enemy:GetStatusResistance()) } )
                enemy:AddNewModifier( self:GetCaster(), self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_shard") * (1 - enemy:GetStatusResistance()) } )
            else
                enemy:AddNewModifier( self:GetCaster(), self, "modifier_aghanim_blink_attack_debuff", { duration = duration * (1 - enemy:GetStatusResistance()) } )
            end
        end
    end

    if true then
        local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), point, self:GetCaster(), radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
        for _,enemy in pairs( enemies ) do
            if enemy ~= nil and enemy:IsInvulnerable() == false then
                local direciton = (point - enemy:GetAbsOrigin())
                local dlina = direciton:Length2D()
                direciton.z = 0
                direciton = direciton:Normalized()

                local knockback = enemy:AddNewModifier(
                    self:GetCaster(),
                    self,
                    "modifier_generic_knockback_lua",
                    {
                        direction_x = direciton.x,
                        direction_y = direciton.y,
                        height = 50,
                        distance = dlina - 75,
                        duration = 0.2,
                    }
                )
                local callback = function( bInterrupted )
                    FindClearSpaceForUnit( enemy, enemy:GetAbsOrigin(), true )
                end
            end
        end
    end

    self:GetCaster():RemoveModifierByName("modifier_aghanim_blink_attack")
end

modifier_aghanim_blink_attack_debuff = class({})

function modifier_aghanim_blink_attack_debuff:GetTexture() return "blink_attack" end

function modifier_aghanim_blink_attack_debuff:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_aghanim_blink_attack_debuff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_aghanim_blink_attack_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

LinkLuaModifier("modifier_mum_meat_hook_hook_thinker", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_shard_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_shard_debuff_crystal", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_shard_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_shard = class({})

function aghanim_shard:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts", context )
end

function aghanim_shard:GetIntrinsicModifierName()
    return "modifier_aghanim_shard_buff"
end

modifier_aghanim_shard_buff = class({})

function modifier_aghanim_shard_buff:IsHidden() return true end
function modifier_aghanim_shard_buff:IsPurgable() return false end
function modifier_aghanim_shard_buff:IsPurgeException() return false end

function modifier_aghanim_shard_buff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_AVOID_DAMAGE
    }
end

function modifier_aghanim_shard_buff:GetModifierAvoidDamage(params)
    if not IsServer() then return end
    if params.attacker:HasModifier("modifier_aghanim_shard_debuff_crystal") and params.inflictor ~= nil then
        local modifier_aghanim_shard_debuff_crystal = params.attacker:FindModifierByName("modifier_aghanim_shard_debuff_crystal")
        if modifier_aghanim_shard_debuff_crystal and modifier_aghanim_shard_debuff_crystal:GetStackCount() <= 0 then
            params.attacker:RemoveModifierByName("modifier_aghanim_shard_debuff_crystal")
        end
        local nFXIndex = ParticleManager:CreateParticle( "particles/crystal_debuff_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
        ParticleManager:SetParticleControl(nFXIndex, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex( nFXIndex )
        self:GetCaster():EmitSound("Hero_Tinker.Warp.Target")
        params.attacker:EmitSound("Hero_Tinker.Warp.Target")
        return 1
    end
end

function aghanim_shard:OnSpellStart()
    if not IsServer() then return end
    local point = self:GetCursorPosition()
    local distance = self:GetSpecialValueFor("max_distance")
    local spawnPos = self:GetCaster():GetOrigin()

    local direction = point-self:GetCaster():GetAbsOrigin()
    direction.z = 0
    direction = direction:Normalized()

    self:GetCaster():EmitSound("Hero_Winter_Wyvern.SplinterBlast.Cast")


    local point_start = self:GetCaster():GetAttachmentOrigin(self:GetCaster():ScriptLookupAttachment("attach_staff_fx"))


    local info = 
    {
        Source = self:GetCaster(),
        Ability = self,
        vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
        bDeleteOnHit = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        EffectName = "particles/shard/aghanim_crystal_attack.vpcf",
        fDistance = distance,
        fStartRadius = 105,
        fEndRadius = 105,
        vVelocity = direction * 900,
        iSourceAttachment   = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bProvidesVision = false,
        ExtraData = {main = 1}
    }

    ProjectileManager:CreateLinearProjectile(info)
end

function aghanim_shard:OnProjectileHit_ExtraData(target, vLocation, table)

    if target ~= nil then
        if table.main == 1 then
            local point = GetGroundPosition(vLocation, nil)
            local particle = ParticleManager:CreateParticle("particles/creatures/aghanim/aghanim_crystal_attack_impact.vpcf", PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(particle, 0, point)

            local dummy = CreateUnitByName( "npc_dota_companion", target:GetAbsOrigin(), false, nil, nil, self:GetCaster():GetTeamNumber() )
            dummy:SetAbsOrigin(target:GetAbsOrigin())
            dummy:AddNewModifier(dummy, self, "modifier_mum_meat_hook_hook_thinker", {duration = 3})
            local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius_dmg"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

            EmitSoundOnLocationWithCaster(point, "Hero_Winter_Wyvern.SplinterBlast.Splinter", self:GetCaster())

            for _,enemy in pairs( enemies ) do
                local info = 
                {
                    Target = enemy,
                    Source = dummy,
                    Ability = self, 
                    EffectName = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf",
                    iMoveSpeed = 800,
                    bReplaceExisting = false,
                    bProvidesVision = true,
                    iVisionRadius = 25,
                    iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
                    ExtraData = {main = 0}
                }
                ProjectileManager:CreateTrackingProjectile(info)
            end
        end
        if table.main == 0 then
            local damage = self:GetSpecialValueFor("damage")

            local special_bonus_aghanim_talent_1 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_1")
            if special_bonus_aghanim_talent_1 and special_bonus_aghanim_talent_1:GetLevel() > 0 then
                damage = damage + special_bonus_aghanim_talent_1:GetSpecialValueFor("value")
            end

            target:EmitSound("Hero_Winter_Wyvern.SplinterBlast.Target")
            if target:HasModifier("modifier_aghanim_shard_debuff_crystal") then
                damage = damage + self:GetSpecialValueFor("bonus_damage")
            end
            --target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_shard_debuff", {duration = self:GetSpecialValueFor("debuff_duration") * (1-target:GetStatusResistance())})
            target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_shard_debuff_crystal", {duration = self:GetSpecialValueFor("crystal_duration") * (1-target:GetStatusResistance())})

            local special_bonus_aghanim_talent_3 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_3")
            if special_bonus_aghanim_talent_3 and special_bonus_aghanim_talent_3:GetLevel() > 0 then
                target:AddNewModifier( self:GetCaster(), self, "modifier_aghanim_shard_debuff", { duration = special_bonus_aghanim_talent_3:GetSpecialValueFor("value2") * (1 - target:GetStatusResistance()) } )
            end

            ApplyDamage({attacker = self:GetCaster(), victim = target, ability = self, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
        end
        return true
    end

    if target == nil then
        if table.main == 1 then
            local point = GetGroundPosition(vLocation, nil)
            local particle = ParticleManager:CreateParticle("particles/creatures/aghanim/aghanim_crystal_attack_impact.vpcf", PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(particle, 0, point)

            local dummy = CreateUnitByName( "npc_dota_companion", point, false, nil, nil, self:GetCaster():GetTeamNumber() )
            dummy:SetAbsOrigin(point)
            dummy:AddNewModifier(dummy, self, "modifier_mum_meat_hook_hook_thinker", {duration = 3})
            local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), point, nil, self:GetSpecialValueFor("radius_dmg"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

            EmitSoundOnLocationWithCaster(point, "Hero_Winter_Wyvern.SplinterBlast.Splinter", self:GetCaster())

            for _,enemy in pairs( enemies ) do
                
                local info = 
                {
                    Target = enemy,
                    Source = dummy,
                    Ability = self, 
                    EffectName = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf",
                    iMoveSpeed = 800,
                    bReplaceExisting = false,
                    bProvidesVision = true,
                    iVisionRadius = 25,
                    iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
                    ExtraData = {main = 0}
                }
                EmitSoundOnLocationWithCaster(point, "Hero_Winter_Wyvern.SplinterBlast.Splinter", self:GetCaster())

                ProjectileManager:CreateTrackingProjectile(info)
            end
        end
    end
end


modifier_aghanim_shard_debuff_crystal = class({})

function modifier_aghanim_shard_debuff_crystal:IsHidden() return self:GetStackCount() == 0 end
function modifier_aghanim_shard_debuff_crystal:GetTexture() return "shard_debuff" end

function modifier_aghanim_shard_debuff_crystal:OnCreated()
    if not IsServer() then return end
    self:SetStackCount(1)
    self.particle = ParticleManager:CreateParticle("particles/aghs_crystal_debuff.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    self:AddParticle(self.particle, false, false, -1, false, true)
end

function modifier_aghanim_shard_debuff_crystal:OnRefresh()
    if not IsServer() then return end
    local special_bonus_unique_winter_wyvern_7 = self:GetCaster():FindAbilityByName("special_bonus_unique_winter_wyvern_7")
    if special_bonus_unique_winter_wyvern_7 and special_bonus_unique_winter_wyvern_7:GetLevel() > 0 then
        self:IncrementStackCount()
    end
end

function modifier_aghanim_shard_debuff_crystal:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
    }
end

function modifier_aghanim_shard_debuff_crystal:OnAbilityFullyCast( params )
    if IsServer() then
        local hAbility = params.ability
        if hAbility == nil or not ( hAbility:GetCaster() == self:GetParent() ) then
            return 0
        end
        if hAbility:IsItem() then 
            return 0
        end
        self:DecrementStackCount()

        if self:GetStackCount() <= 0 then
            if self.particle then
                ParticleManager:DestroyParticle(self.particle, true)
                ParticleManager:ReleaseParticleIndex(self.particle)
            end
            self:SetDuration(2, false)
        end
    end
    return 0
end

modifier_aghanim_shard_debuff = class({})

function modifier_aghanim_shard_debuff:OnCreated()
    if not IsServer() then return end
    self:SetStackCount(1)
end

function modifier_aghanim_shard_debuff:OnRefresh()
    if not IsServer() then return end
    if self:GetStackCount() < 5 then
        self:IncrementStackCount()
    end
end

function modifier_aghanim_shard_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    }
end

function modifier_aghanim_shard_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return -20 * self:GetStackCount()
end

function modifier_aghanim_shard_debuff:GetModifierHealAmplify_PercentageTarget()
    return -20 * self:GetStackCount()
end

function modifier_aghanim_shard_debuff:GetModifierHPRegenAmplify_Percentage()
    return -20 * self:GetStackCount()
end

function modifier_aghanim_shard_debuff:GetTexture() return "aghanim_shard" end

modifier_mum_meat_hook_hook_thinker = class({})

function modifier_mum_meat_hook_hook_thinker:IsHidden() return true end
function modifier_mum_meat_hook_hook_thinker:IsPurgable() return false end
function modifier_mum_meat_hook_hook_thinker:RemoveOnDeath() return false end

function modifier_mum_meat_hook_hook_thinker:CheckState()
    return 
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_mum_meat_hook_hook_thinker:OnDestroy()
    if not IsServer() then return end
    UTIL_Remove(self:GetParent())
end
            
LinkLuaModifier("modifier_aghanim_ray", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_ray_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_ray_bkb", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_ray = class({})

function aghanim_ray:Precache( context )
    PrecacheResource( "particle", "particles/creatures/aghanim/staff_beam.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_beam_channel.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_beam_burn.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/staff_beam_linger.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/staff_beam_tgt_ring.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_debug_ring.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_huskar.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_jakiro.vsndevts", context )
end

function aghanim_ray:OnAbilityPhaseStart()
    if IsServer() then
        self.nChannelFX = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_beam_channel.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    end
    return true
end

function aghanim_ray:OnAbilityPhaseInterrupted()
    if IsServer() then
        if self.nChannelFX then
            ParticleManager:DestroyParticle(self.nChannelFX, true)
        end
    end
end

function aghanim_ray:OnSpellStart()
    if not IsServer() then return end

    local point = self:GetCursorPosition()

    local direction = point - self:GetCaster():GetAbsOrigin()

    local distance = direction:Length2D()

    direction = direction:Normalized()

    if distance > self:GetSpecialValueFor("max_distance") then
        point = self:GetCaster():GetAbsOrigin() + direction * self:GetSpecialValueFor("max_distance")
    end

    if distance < self:GetSpecialValueFor("min_distance") then
        point = self:GetCaster():GetAbsOrigin() + direction * self:GetSpecialValueFor("min_distance")
    end

    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_ray", {duration = self:GetSpecialValueFor("duration"), x = point.x, y = point.y, z = point.z })
end

modifier_aghanim_ray = class({})

function modifier_aghanim_ray:IsPurgable() return false end
function modifier_aghanim_ray:GetTexture() return "aghanim_ray" end

function modifier_aghanim_ray:OnCreated(params)
    if not IsServer() then return end

    local aghanim_ray_stop = self:GetCaster():FindAbilityByName("aghanim_ray_stop")
    if aghanim_ray_stop then
        aghanim_ray_stop:SetLevel(1)
    end

    self.point = Vector(params.x, params.y, params.z)

    self:GetParent():SwapAbilities("aghanim_ray", "aghanim_ray_stop", false, true)

    self.dummy = CreateUnitByName( "npc_dota_companion", self.point, false, nil, nil, self:GetCaster():GetTeamNumber() )
    self.dummy:SetAbsOrigin(self.point)
    self.dummy:AddNewModifier(self.dummy, self:GetAbility(), "modifier_mum_meat_hook_hook_thinker", {duration = self:GetAbility():GetSpecialValueFor("duration")})

    self.effect_time = 0

    self.nBeamFXIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/staff_beam.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_staff_fx", self:GetCaster():GetAbsOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 1, self.dummy, PATTACH_ABSORIGIN_FOLLOW, nil, self.dummy:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 2, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self.dummy:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 9, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true )

    print(self:GetCaster():HasModifier("modifier_item_aghanims_shard"))

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_ray_bkb", {duration = 10})
    end

    --EmitSoundOn( "Hero_Phoenix.SunRay.Cast", self:GetCaster() )
    EmitSoundOn( "Birzha.RayAgh", self:GetCaster() )

    self:StartIntervalThink(FrameTime())
end

modifier_aghanim_ray_bkb = class({})

function modifier_aghanim_ray_bkb:IsPurgable() return false end
function modifier_aghanim_ray_bkb:IsHidden() return true end

function modifier_aghanim_ray_bkb:GetEffectName()
    return "particles/items_fx/black_king_bar_avatar_aghanim.vpcf"
end

function modifier_aghanim_ray_bkb:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_aghanim_ray_bkb:CheckState()
    return 
    {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true
    }
end

function modifier_aghanim_ray_bkb:GetStatusEffectName()
    return "particles/status_effect_avatar_aghanim.vpcf"
end

function modifier_aghanim_ray_bkb:StatusEffectPriority()
    return 99999
end

function modifier_aghanim_ray_bkb:GetTexture()
    return "legion_commander_18"
end

function modifier_aghanim_ray:OnIntervalThink()
    if not IsServer() then return end

    if self.dummy and self.dummy:IsNull() then return end

    if self:GetParent():IsStunned() or self:GetParent():IsSilenced() then
        self:Destroy()
        return
    end

    local damage = self:GetAbility():GetSpecialValueFor("damage") + ( self:GetCaster():GetMana() / 100 * self:GetAbility():GetSpecialValueFor("mana_damage"))

    local direction = self.point - self.dummy:GetAbsOrigin()
    direction.z = 0
    direction = direction:Normalized()

    local new_point = self.dummy:GetAbsOrigin() + direction * (550 * FrameTime())

    local dir_min_c = new_point - self:GetCaster():GetAbsOrigin()

    local distance = dir_min_c:Length2D()

    dir_min_c.z = 0

    local direction_min = dir_min_c:Normalized()

    if distance < self:GetAbility():GetSpecialValueFor("min_distance") - 50 then
        local dir = new_point - self:GetCaster():GetAbsOrigin()
        local len = dir:Length2D()
        dir.z = 0
        dir = dir:Normalized()
        new_point = new_point + dir * (self:GetAbility():GetSpecialValueFor("min_distance") - 150)
    end

    new_point = GetGroundPosition(new_point, nil)

    AddFOWViewer(self:GetCaster():GetTeamNumber(), self.dummy:GetAbsOrigin(), 100, FrameTime(), false)
    self.dummy:SetAbsOrigin(new_point)

    if self.effect_time <= 0.4 then
        self.effect_time = self.effect_time + FrameTime()
    end

    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), new_point, nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

    for _,enemy in pairs( enemies ) do
        if enemy:GetHealthPercent() <= self:GetAbility():GetSpecialValueFor("health_aver") then
            local debuff = enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_ray_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration_debuff") * (1-enemy:GetStatusResistance())})
            if debuff then
                if debuff:GetStackCount() < 100 then
                    debuff:IncrementStackCount()
                end
            end
            damage = damage * self:GetAbility():GetSpecialValueFor("damage_multiple")
        end

        if self.effect_time >= 0.4 then
            local particle = ParticleManager:CreateParticle("particles/aghanim_ray_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
            ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(particle)
            self.effect_time = 0
        end

        local damageInfo = 
        {
            victim = enemy,
            attacker = self:GetCaster(),
            damage = damage * FrameTime(),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(),
        }

        ApplyDamage( damageInfo )
    end

    local direction2 = self.dummy:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()
    direction2.z = 0
    direction2 = direction2:Normalized()

    self:GetCaster():SetForwardVector(direction2)
end

function modifier_aghanim_ray:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveModifierByName("modifier_aghanim_ray_bkb")
    self:GetParent():SwapAbilities("aghanim_ray_stop", "aghanim_ray", false, true)
    self:GetCaster():RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_3)
    if self.dummy and not self.dummy:IsNull() then
        self.dummy:RemoveModifierByName("modifier_mum_meat_hook_hook_thinker")
    end
    if self:GetAbility().nChannelFX then
        ParticleManager:DestroyParticle(self:GetAbility().nChannelFX, false)
    end
    if self.nBeamFXIndex then
        ParticleManager:DestroyParticle(self.nBeamFXIndex, true)
    end
    StopSoundOn( "Birzha.RayAgh", self:GetCaster() )
end

function modifier_aghanim_ray:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }
end

function modifier_aghanim_ray:CheckState()
    local state = 
    {
        [ MODIFIER_STATE_DISARMED ] = true,
        [ MODIFIER_STATE_ROOTED ] = true,
    }
    return state
end

function modifier_aghanim_ray:GetOverrideAnimation()
    return ACT_DOTA_CHANNEL_ABILITY_3
end

function modifier_aghanim_ray:GetModifierDisableTurning()
    return 1
end

function modifier_aghanim_ray:OnOrder( params )
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

        local stop_orders =
        {
            [DOTA_UNIT_ORDER_STOP] = true,
            [DOTA_UNIT_ORDER_HOLD_POSITION] = true,
            [DOTA_UNIT_ORDER_CONTINUE] = true,
            [DOTA_UNIT_ORDER_CAST_POSITION] = true,
            [DOTA_UNIT_ORDER_CAST_TARGET] = true,
            [DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
            [DOTA_UNIT_ORDER_HOLD_POSITION] = true,
        }

        if stop_orders[params.order_type] then
            self:Destroy()
            self:GetParent():Stop()
            return
        end

        if validMoveOrders[params.order_type] then
            local vTargetPos = params.new_pos
            if params.target ~= nil and params.target:IsNull() == false then
                vTargetPos = params.target:GetAbsOrigin()
            end

            local direction = vTargetPos - self:GetCaster():GetAbsOrigin()

            local distance = direction:Length2D()

            direction = direction:Normalized()

            if distance > self:GetAbility():GetSpecialValueFor("max_distance") then
                vTargetPos = self:GetCaster():GetAbsOrigin() + direction * self:GetAbility():GetSpecialValueFor("max_distance")
            end

            if distance < self:GetAbility():GetSpecialValueFor("min_distance") then
                vTargetPos = self:GetCaster():GetAbsOrigin() + direction * self:GetAbility():GetSpecialValueFor("min_distance")
            end

            self.point = vTargetPos
        end
    end
end

modifier_aghanim_ray_debuff = class({})

function modifier_aghanim_ray_debuff:GetTexture() return "aghanim_ray" end

function modifier_aghanim_ray_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_ray_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetStackCount() * -1
end


LinkLuaModifier("modifier_aghanim_change_style_random_time", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_change_style_main_statue", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_change_style_main_statue_clock", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_VERTICAL )
LinkLuaModifier("modifier_aghanim_change_style_main_disabled", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_change_style_main_hero", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier("modifier_aghanim_change_style_main_mad", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_change_style_main_bath", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_change_style_main_mech", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_change_style_main_smith", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_change_style_main = class({})

function aghanim_change_style_main:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_arc_warden.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_terrorblade.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context )
end

function aghanim_change_style_main:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_6)
    if self:GetCaster():HasScepter() then
        self:GetCaster():Heal(self:GetCaster():GetMaxHealth(), self)
        self:GetCaster():Interrupt()
        self:GetCaster():RemoveModifierByName("modifier_aghanim_ray")
        local choose_time = self:GetSpecialValueFor("choose_time")
        local special_bonus_aghanim_talent_4 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_4")
        if special_bonus_aghanim_talent_4 and special_bonus_aghanim_talent_4:GetLevel() > 0 then
            choose_time = choose_time + special_bonus_aghanim_talent_4:GetSpecialValueFor("value")
        end
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_change_style_main_hero", {duration = choose_time})
    else
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_change_style_random_time", {duration = self:GetSpecialValueFor("start_time")})
    end
end

modifier_aghanim_change_style_random_time = class({})

function modifier_aghanim_change_style_random_time:IsHidden() return true end
function modifier_aghanim_change_style_random_time:IsPurgable() return false end
function modifier_aghanim_change_style_random_time:IsPurgeException() return false end

function modifier_aghanim_change_style_random_time:OnCreated()
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/vip_gold.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    self:AddParticle(particle, false, false, -1, false, true)
    self:GetParent():EmitSound("Birzha.UltAghs")
    self:GetAbility():SetActivated(false)
end

function modifier_aghanim_change_style_random_time:OnDestroy()
    if not IsServer() then return end
    self:GetParent():StopSound("Birzha.UltAghs")
    self:GetAbility():SetActivated(true)
    if self:GetCaster():IsAlive() then
        self:GetCaster():Heal(self:GetCaster():GetMaxHealth(), self:GetAbility())
        self:GetCaster():Interrupt()
        self:GetCaster():RemoveModifierByName("modifier_aghanim_ray")
        local choose_time = self:GetAbility():GetSpecialValueFor("choose_time")
        local special_bonus_aghanim_talent_4 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_4")
        if special_bonus_aghanim_talent_4 and special_bonus_aghanim_talent_4:GetLevel() > 0 then
            choose_time = choose_time + special_bonus_aghanim_talent_4:GetSpecialValueFor("value")
        end
        self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_hero", {duration = choose_time})
    end
end

modifier_aghanim_change_style_main_hero = class({})
function modifier_aghanim_change_style_main_hero:GetTexture() return "aghanim_style_main" end
function modifier_aghanim_change_style_main_hero:IsPurgable() return false end
function modifier_aghanim_change_style_main_hero:IsHidden() return false end
function modifier_aghanim_change_style_main_hero:IsPurgeException() return false end

function modifier_aghanim_change_style_main_hero:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_aghanim_change_style_main_hero:OnCreated()
    if not IsServer() then return end

    self.hero_time = self:GetAbility():GetSpecialValueFor("hero_time")

    -- if IsInToolsMode() then
    --     self.hero_time = 99999
    -- end

    local aghanim_shard = self:GetCaster():FindAbilityByName("aghanim_shard")
    if aghanim_shard then
        self:GetCaster().ability_level_aghanim_shard = aghanim_shard:GetLevel()
    end
    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_blink_cast")
    if aghanim_blink_cast then
        self:GetCaster().ability_level_aghanim_blink_cast = aghanim_blink_cast:GetLevel()
    end
    local aghanim_ray = self:GetCaster():FindAbilityByName("aghanim_ray")
    if aghanim_ray then
        self:GetCaster().ability_level_aghanim_ray = aghanim_ray:GetLevel()
    end
    local aghanim_change_style_main = self:GetCaster():FindAbilityByName("aghanim_change_style_main")
    if aghanim_change_style_main then
        self:GetCaster().ability_level_aghanim_change_style_main = aghanim_change_style_main:GetLevel()
    end

    self:GetCaster():RemoveModifierByName("modifier_aghanim_blink_attack")

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            self:GetCaster():RemoveAbility(ability:GetAbilityName())
        end
    end

    self.aghanim_change_style_mad = self:GetCaster():AddAbility("aghanim_change_style_mad")
    self.aghanim_change_style_mad:SetLevel(1)
    self.aghanim_change_style_mad:SetHidden(false)

    self.aghanim_change_style_bath = self:GetCaster():AddAbility("aghanim_change_style_bath")
    self.aghanim_change_style_bath:SetLevel(1)
    self.aghanim_change_style_bath:SetHidden(false)

    self.aghanim_change_style_mech = self:GetCaster():AddAbility("aghanim_change_style_mech")
    self.aghanim_change_style_mech:SetLevel(1)
    self.aghanim_change_style_mech:SetHidden(false)

    self:GetCaster():AddAbility("generic_hidden")
    self:GetCaster():AddAbility("generic_hidden")

    self.aghanim_change_style_smith = self:GetCaster():AddAbility("aghanim_change_style_smith")
    self.aghanim_change_style_smith:SetLevel(1)
    self.aghanim_change_style_smith:SetHidden(false)

    self.aghanim_change_style_mad:SetActivated(true)
    self.aghanim_change_style_bath:SetActivated(true)
    self.aghanim_change_style_mech:SetActivated(true)
    self.aghanim_change_style_smith:SetActivated(true)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end

    if self:GetCaster().use == nil then
        self:GetCaster().use = {}
    end

    if self:GetCaster().use["mad"] ~= nil and self:GetCaster().use["bath"] ~= nil and self:GetCaster().use["mech"] ~= nil and self:GetCaster().use["smith"] ~= nil then
        self:GetCaster().use = {}
    end

    self:GetCaster():EmitSound("Birzha.UltArca")
    self:GetCaster():AddNoDraw()

    GridNav:DestroyTreesAroundPoint(self:GetCaster():GetAbsOrigin(), 600, true)

    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), self:GetCaster(), 600, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
    for _,enemy in pairs( enemies ) do
        if enemy ~= nil and enemy ~= self:GetCaster() then
            local direciton = (enemy:GetAbsOrigin() - self:GetCaster():GetAbsOrigin())
            local dlina = direciton:Length2D()
            direciton.z = 0
            direciton = direciton:Normalized()

            local knockback = enemy:AddNewModifier(
                self:GetCaster(),
                self,
                "modifier_generic_knockback_lua",
                {
                    direction_x = direciton.x,
                    direction_y = direciton.y,
                    height = 50,
                    distance = (600 - dlina) + 100,
                    duration = 0.25,
                }
            )
            local callback = function( bInterrupted )
                FindClearSpaceForUnit( enemy, enemy:GetAbsOrigin(), true )
            end
        end
    end


    self.clock = CreateUnitByName("npc_dota_unit_statue_aghs21_device", self:GetCaster():GetAbsOrigin(), false, nil, nil, self:GetCaster():GetTeamNumber())
    if self.clock then
        self.clock:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_statue_clock", {})
    end

    Timers:CreateTimer(0.1, function()
        self.mad = CreateUnitByName("npc_dota_unit_statue_aghanim_mad", self:GetCaster():GetAbsOrigin() + self:GetCaster():GetForwardVector() * 250, false, nil, nil, self:GetCaster():GetTeamNumber())
        if self.mad then
            self.mad:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_statue", {})
            local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti8/ti8_hero_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mad)
            ParticleManager:SetParticleControl(particle1, 0, self.mad:GetAbsOrigin())
            self:AddParticle(particle1, false, false, -1, false, false)
            local particle = ParticleManager:CreateParticle("particles/tempest_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mad)
            ParticleManager:SetParticleControl(particle, 0, self.mad:GetAbsOrigin())
            self.nFXIndex1 = ParticleManager:CreateParticle( "particles/voi_aghanim.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mad )
            self:AddParticle(self.nFXIndex1, false, false, -1, false, false)
            if not self:GetCaster():HasScepter() then
                if self:GetCaster().use["mad"] ~= nil then
                    self.mad:SetRenderColor(0, 0, 0)
                    self.mad:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_disabled", {})
                    self.aghanim_change_style_mad:SetActivated(false)
                end
            end
        end
    end)

    Timers:CreateTimer(0.2, function()
        self.bath = CreateUnitByName("npc_dota_unit_statue_aghanim_bath", self:GetCaster():GetAbsOrigin() + (self:GetCaster():GetForwardVector() * -1) * 250, false, nil, nil, self:GetCaster():GetTeamNumber())
        if self.bath then
            self.bath:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_statue", {})
            local particle2 = ParticleManager:CreateParticle("particles/econ/events/ti7/ti7_hero_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.bath)
            ParticleManager:SetParticleControl(particle2, 0, self.bath:GetAbsOrigin())
            self:AddParticle(particle2, false, false, -1, false, false)
            local particle = ParticleManager:CreateParticle("particles/tempest_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.bath)
            ParticleManager:SetParticleControl(particle, 0, self.bath:GetAbsOrigin())
            self.nFXIndex2 = ParticleManager:CreateParticle( "particles/voi_aghanim.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.bath )
            self:AddParticle(self.nFXIndex2, false, false, -1, false, false)
            if not self:GetCaster():HasScepter() then
                if self:GetCaster().use["bath"] ~= nil then
                    self.bath:SetRenderColor(0, 0, 0)
                    self.bath:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_disabled", {})
                    self.aghanim_change_style_bath:SetActivated(false)
                end
            end
        end  
    end)

    Timers:CreateTimer(0.3, function()
        self.mech = CreateUnitByName("npc_dota_unit_statue_aghanim_mech", self:GetCaster():GetAbsOrigin() + self:GetCaster():GetRightVector() * 250, false, nil, nil, self:GetCaster():GetTeamNumber())
        if self.mech then
            self.mech:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_statue", {})
            local particle3 = ParticleManager:CreateParticle("particles/econ/events/fall_2021/fall_2021_emblem_game_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mech)
            ParticleManager:SetParticleControl(particle3, 0, self.mech:GetAbsOrigin())
            self:AddParticle(particle3, false, false, -1, false, false)
            local particle = ParticleManager:CreateParticle("particles/tempest_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mech)
            ParticleManager:SetParticleControl(particle, 0, self.mech:GetAbsOrigin())
            self.nFXIndex3 = ParticleManager:CreateParticle( "particles/voi_aghanim.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mech )
            self:AddParticle(self.nFXIndex3, false, false, -1, false, false)
            if not self:GetCaster():HasScepter() then
                if self:GetCaster().use["mech"] ~= nil then
                    self.mech:SetRenderColor(0, 0, 0)
                    self.mech:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_disabled", {})
                    self.aghanim_change_style_mech:SetActivated(false)
                end
            end
        end  
    end)

    Timers:CreateTimer(0.4, function()
        self.smith = CreateUnitByName("npc_dota_unit_statue_aghanim_smith", self:GetCaster():GetAbsOrigin() + self:GetCaster():GetLeftVector() * 250, false, nil, nil, self:GetCaster():GetTeamNumber())
        if self.smith then
            self.smith:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_statue", {})
            local particle4 = ParticleManager:CreateParticle("particles/econ/events/fall_2022/player/fall_2022_emblem_effect_player_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.smith)
            ParticleManager:SetParticleControl(particle4, 0, self.smith:GetAbsOrigin())
            self:AddParticle(particle4, false, false, -1, false, false)
            local particle = ParticleManager:CreateParticle("particles/tempest_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.smith)
            ParticleManager:SetParticleControl(particle, 0, self.smith:GetAbsOrigin())
            self.nFXIndex4 = ParticleManager:CreateParticle( "particles/voi_aghanim.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.smith )
            self:AddParticle(self.nFXIndex4, false, false, -1, false, false)
            if not self:GetCaster():HasScepter() then
                if self:GetCaster().use["smith"] ~= nil then
                    self.smith:SetRenderColor(0, 0, 0)
                    self.smith:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_change_style_main_disabled", {})
                    self.aghanim_change_style_smith:SetActivated(false)
                end
            end
        end
    end)

    self.parent = self:GetParent()
    self.zero = Vector(0,0,0)
    self.revolution = 6
    self.rotate_radius = 250
    self.interval = 0.03
    self.base_facing = Vector(0,1,0)
    self.relative_pos = Vector( -self.rotate_radius, 0, 100 )
    self.rotate_delta = 360/self.revolution * self.interval
    self.position1 = self.parent:GetOrigin() + self.relative_pos
    self.position2 = self.parent:GetOrigin() + self.relative_pos
    self.position3 = self.parent:GetOrigin() + self.relative_pos
    self.position4 = self.parent:GetOrigin() + self.relative_pos
    self.z_height = 50
    self.lift_animation = 10
    self.fall_animation = 10
    self.current_time = 0
    self.change = true
    self.rotation1 = 0
    self.rotation2 = 90
    self.rotation3 = 180
    self.rotation4 = 270
    self.backtrack = 0
    self.mael_cooldown = 0

    self:StartIntervalThink(FrameTime())
end

function modifier_aghanim_change_style_main_hero:OnDestroy()
    if not IsServer() then return end

    self:GetCaster():RemoveNoDraw()

    if self.nFXIndex1 then
        ParticleManager:DestroyParticle(self.nFXIndex1, true)
    end
    if self.nFXIndex2 then
        ParticleManager:DestroyParticle(self.nFXIndex2, true)
    end
    if self.nFXIndex3 then
        ParticleManager:DestroyParticle(self.nFXIndex3, true)
    end
    if self.nFXIndex4 then
        ParticleManager:DestroyParticle(self.nFXIndex4, true)
    end

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            self:GetCaster():RemoveAbility(ability:GetAbilityName())
        end
    end

    if self.choose == nil then
        local aghanim_shard = self:GetCaster():AddAbility("aghanim_shard")
        aghanim_shard:SetLevel(self:GetCaster().ability_level_aghanim_shard)

        local aghanim_blink_cast = self:GetCaster():AddAbility("aghanim_blink_cast")
        aghanim_blink_cast:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

        local aghanim_ray = self:GetCaster():AddAbility("aghanim_ray")
        aghanim_ray:SetLevel(self:GetCaster().ability_level_aghanim_ray)

        local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_blink_attack")
        aghanim_blink_attack:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

        local generic_hidden = self:GetCaster():AddAbility("generic_hidden")
        generic_hidden:SetLevel(1)

        local aghanim_change_style_main = self:GetCaster():AddAbility("aghanim_change_style_main")
        aghanim_change_style_main:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)

        local sunder_particle_2 = ParticleManager:CreateParticle("particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
        ParticleManager:SetParticleControlEnt(sunder_particle_2, 1, self.clock, PATTACH_POINT_FOLLOW, "attach_hitloc", self.clock:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(sunder_particle_2, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        ParticleManager:SetParticleControl(sunder_particle_2, 2, self.clock:GetAbsOrigin())
        ParticleManager:SetParticleControl(sunder_particle_2, 15, Vector(0,152,255))
        ParticleManager:SetParticleControl(sunder_particle_2, 16, Vector(1,0,0))
        ParticleManager:ReleaseParticleIndex(sunder_particle_2)

        self.clock:EmitSound("Hero_Terrorblade.Sunder.Cast")
        self:GetParent():EmitSound("Hero_Terrorblade.Sunder.Target")
    end

    if self.choose == "mad" then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_change_style_main_mad", {duration = self.hero_time})
        self:GetCaster().use["mad"] = true
        self:GetCaster():SetAbsOrigin(self.mad:GetAbsOrigin())
        FindClearSpaceForUnit(self:GetCaster(), self:GetCaster():GetAbsOrigin(), true)
    end

    if self.choose == "bath" then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_change_style_main_bath", {duration = self.hero_time})
        self:GetCaster().use["bath"] = true
        self:GetCaster():SetAbsOrigin(self.bath:GetAbsOrigin())
        FindClearSpaceForUnit(self:GetCaster(), self:GetCaster():GetAbsOrigin(), true)
    end

    if self.choose == "mech" then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_change_style_main_mech", {duration = self.hero_time})
        self:GetCaster().use["mech"] = true
        self:GetCaster():SetAbsOrigin(self.mech:GetAbsOrigin())
        FindClearSpaceForUnit(self:GetCaster(), self:GetCaster():GetAbsOrigin(), true)
    end

    if self.choose == "smith" then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_change_style_main_smith", {duration = self.hero_time})
        self:GetCaster().use["smith"] = true
        self:GetCaster():SetAbsOrigin(self.smith:GetAbsOrigin())
        FindClearSpaceForUnit(self:GetCaster(), self:GetCaster():GetAbsOrigin(), true)
    end

    UTIL_Remove(self.mad)
    UTIL_Remove(self.bath)
    UTIL_Remove(self.mech)
    UTIL_Remove(self.smith)
    UTIL_Remove(self.clock)
end

function modifier_aghanim_change_style_main_hero:OnIntervalThink()
    self.rotation1 = self.rotation1 - self.rotate_delta
    self.rotation2 = self.rotation2 - self.rotate_delta
    self.rotation3 = self.rotation3 - self.rotate_delta
    self.rotation4 = self.rotation4 - self.rotate_delta

    local origin = self.parent:GetOrigin()

    self.position1 = RotatePosition( origin, QAngle( 0, -self.rotation1, 0 ), origin + self.relative_pos )
    self.position2 = RotatePosition( origin, QAngle( 0, -self.rotation2, 0 ), origin + self.relative_pos )
    self.position3 = RotatePosition( origin, QAngle( 0, -self.rotation3, 0 ), origin + self.relative_pos )
    self.position4 = RotatePosition( origin, QAngle( 0, -self.rotation4, 0 ), origin + self.relative_pos )

    if self.change then
        self.current_time = self.current_time + FrameTime()
        if RollPercentage(10) then
            if self.mael_cooldown <= 0 then
                self:StartMaelstrom()
                self.mael_cooldown = 5
            end
        end
    else
        self.current_time = self.current_time - FrameTime()
        if RollPercentage(10) then
            if self.mael_cooldown <= 0 then
                self:StartMaelstrom()
                self.mael_cooldown = 5
            end
        end
    end

    if self.mael_cooldown > 0 then
        self.mael_cooldown = self.mael_cooldown - FrameTime()
    end

    if self.current_time >= 1  then
        self.change = false
    elseif self.current_time <= 0 then
        self.change = true
    end

    local max_height = 100

    if self.change  then
        self.z_height = self.z_height + ((FrameTime() / self.lift_animation) * max_height)
        if self.z_height > 100 then self.z_height = 100 end
        if self.mad then
            self.mad:SetAbsOrigin(GetGroundPosition(self.position1, self.mad) + Vector(0,0,self.z_height) )
        end
        if self.bath then
            self.bath:SetAbsOrigin(GetGroundPosition(self.position2, self.bath) + Vector(0,0,self.z_height) )
        end
        if self.mech then
            self.mech:SetAbsOrigin(GetGroundPosition(self.position3, self.mech) + Vector(0,0,self.z_height) )
        end
        if self.smith then
            self.smith:SetAbsOrigin(GetGroundPosition(self.position4, self.smith) + Vector(0,0,self.z_height) )
        end
    else
        self.z_height = self.z_height - ((FrameTime() / self.fall_animation) * max_height)
        if self.z_height < 50 then self.z_height = 50 end
        if self.mad then
            self.mad:SetAbsOrigin(GetGroundPosition(self.position1, self.mad) + Vector(0,0,self.z_height) )
        end
        if self.bath then
            self.bath:SetAbsOrigin(GetGroundPosition(self.position2, self.bath) + Vector(0,0,self.z_height) )
        end
        if self.mech then
            self.mech:SetAbsOrigin(GetGroundPosition(self.position3, self.mech) + Vector(0,0,self.z_height) )
        end
        if self.smith then
            self.smith:SetAbsOrigin(GetGroundPosition(self.position4, self.smith) + Vector(0,0,self.z_height) )
        end
    end

    if self.mad then
        local dir1 = self.clock:GetAbsOrigin() - self.mad:GetAbsOrigin()
        dir1.z = 0
        dir1 = dir1:Normalized()
        self.mad:SetForwardVector( dir1 )
    end

    if self.bath then
        local dir2 = self.clock:GetAbsOrigin() - self.bath:GetAbsOrigin()
        dir2.z = 0
        dir2 = dir2:Normalized()
        self.bath:SetForwardVector( dir2 )
    end

    if self.mech then
        local dir3 = self.clock:GetAbsOrigin() - self.mech:GetAbsOrigin()
        dir3.z = 0
        dir3 = dir3:Normalized()
        self.mech:SetForwardVector( dir3 )
    end

    if self.smith then
        local dir4 = self.clock:GetAbsOrigin() - self.smith:GetAbsOrigin()
        dir4.z = 0
        dir4 = dir4:Normalized()
        self.smith:SetForwardVector( dir4 )
    end
end

function modifier_aghanim_change_style_main_hero:StartMaelstrom()
    if not IsServer() then return end

    Timers:CreateTimer(FrameTime() * 2, function()
        if self and self.mad then
            local particle = ParticleManager:CreateParticle("particles/econ/events/spring_2021/maelstrom_spring_2021.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mad)
            ParticleManager:SetParticleControlEnt(particle, 0, self.mad, PATTACH_POINT_FOLLOW, "attach_hitloc", self.mad:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(particle, 1, self.bath, PATTACH_POINT_FOLLOW, "attach_hitloc", self.bath:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(particle)
            self.mad:EmitSound("Item.Maelstrom.Chain_Lightning.Jump")
        end
    end)

    Timers:CreateTimer(FrameTime() * 6, function()
        if self and self.bath then
            local particle = ParticleManager:CreateParticle("particles/econ/events/spring_2021/maelstrom_spring_2021.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.bath)
            ParticleManager:SetParticleControlEnt(particle, 0, self.bath, PATTACH_POINT_FOLLOW, "attach_hitloc", self.bath:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(particle, 1, self.mech, PATTACH_POINT_FOLLOW, "attach_hitloc", self.mech:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(particle)
            self.bath:EmitSound("Item.Maelstrom.Chain_Lightning.Jump")
        end
    end)

    Timers:CreateTimer(FrameTime() * 10, function()
        if self and self.mech then
            local particle = ParticleManager:CreateParticle("particles/econ/events/spring_2021/maelstrom_spring_2021.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.mech)
            ParticleManager:SetParticleControlEnt(particle, 0, self.mech, PATTACH_POINT_FOLLOW, "attach_hitloc", self.mech:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(particle, 1, self.smith, PATTACH_POINT_FOLLOW, "attach_hitloc", self.smith:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(particle)
            self.mech:EmitSound("Item.Maelstrom.Chain_Lightning.Jump")
        end
    end)

    Timers:CreateTimer(FrameTime() * 14, function()
        if self and self.smith then
            local particle = ParticleManager:CreateParticle("particles/econ/events/spring_2021/maelstrom_spring_2021.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.smith)
            ParticleManager:SetParticleControlEnt(particle, 0, self.smith, PATTACH_POINT_FOLLOW, "attach_hitloc", self.smith:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(particle, 1, self.mad, PATTACH_POINT_FOLLOW, "attach_hitloc", self.mad:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(particle)
            self.smith:EmitSound("Item.Maelstrom.Chain_Lightning.Jump")
        end
    end)
end

modifier_aghanim_change_style_main_statue = class({})

function modifier_aghanim_change_style_main_statue:IsPurgable() return false end
function modifier_aghanim_change_style_main_statue:IsHidden() return true end
function modifier_aghanim_change_style_main_statue:IsPurgeException() return false end

function modifier_aghanim_change_style_main_statue:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

modifier_aghanim_change_style_main_statue_clock = class({})

function modifier_aghanim_change_style_main_statue_clock:IsPurgable() return false end
function modifier_aghanim_change_style_main_statue_clock:IsHidden() return true end
function modifier_aghanim_change_style_main_statue_clock:IsPurgeException() return false end

function modifier_aghanim_change_style_main_statue_clock:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_aghanim_change_style_main_statue_clock:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
        MODIFIER_PROPERTY_MODEL_SCALE,
    }
end

function modifier_aghanim_change_style_main_statue_clock:GetModifierModelChange()
    return "models/props_gameplay/aghs21_device/aghs21_device.vmdl"
end

function modifier_aghanim_change_style_main_statue_clock:GetOverrideAnimation()
    return ACT_DOTA_IDLE
end

function modifier_aghanim_change_style_main_statue_clock:GetOverrideAnimationRate()
    return 10
end

function modifier_aghanim_change_style_main_statue_clock:OnCreated( params )
    if IsServer() then
        local caster = self:GetCaster()
        local ability = self:GetAbility()
        self.parent = self:GetParent()
        self.z_height = 150
        self.duration = params.duration
        self.lift_animation = 5
        self.fall_animation = 5
        self.current_time = 0
        self.change = true
        self.frametime = FrameTime()
        self:StartIntervalThink(FrameTime())
        self:GetParent():SetAbsOrigin(GetGroundPosition(self:GetParent():GetAbsOrigin(), self:GetParent()) + Vector(0,0,150))
    end
end

function modifier_aghanim_change_style_main_statue_clock:OnIntervalThink()
    if IsServer() then
        self:VerticalMotion(self.parent, self.frametime)
    end
end

function modifier_aghanim_change_style_main_statue_clock:VerticalMotion(unit, dt)
    if IsServer() then
        if self.change then
            self.current_time = self.current_time + dt
        else
            self.current_time = self.current_time - dt
        end

        if self.current_time >= 1  then
            self.change = false
        elseif self.current_time <= 0 then
            self.change = true
        end

        local max_height = 250

        if self.change  then
            self.z_height = self.z_height + ((dt / self.lift_animation) * max_height)
            if self.z_height > 250 then self.z_height = 250 end
            unit:SetAbsOrigin(GetGroundPosition(unit:GetAbsOrigin(), unit) + Vector(0,0,self.z_height))
        else
            self.z_height = self.z_height - ((dt / self.fall_animation) * max_height)
            if self.z_height < 150 then self.z_height = 150 end
            unit:SetAbsOrigin(GetGroundPosition(unit:GetAbsOrigin(), unit) + Vector(0,0,self.z_height))
        end
    end
end







modifier_aghanim_change_style_main_disabled = class({})

function modifier_aghanim_change_style_main_disabled:IsPurgable() return false end
function modifier_aghanim_change_style_main_disabled:IsHidden() return true end
function modifier_aghanim_change_style_main_disabled:IsPurgeException() return false end

function modifier_aghanim_change_style_main_disabled:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_aghanim_change_style_main_disabled:StatusEffectPriority()
    return 10
end

aghanim_change_style_mad = class({})

function aghanim_change_style_mad:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCaster()
    local caster = self:GetCaster()

    local modifier_aghanim_change_style_main_hero = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_hero")
    if modifier_aghanim_change_style_main_hero then
        target = modifier_aghanim_change_style_main_hero.mad
        caster = modifier_aghanim_change_style_main_hero.clock
    end

    local sunder_particle_2 = ParticleManager:CreateParticle("particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(sunder_particle_2, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(sunder_particle_2, 15, Vector(0,152,255))
    ParticleManager:SetParticleControl(sunder_particle_2, 16, Vector(1,0,0))
    ParticleManager:ReleaseParticleIndex(sunder_particle_2)

    caster:EmitSound("Hero_Terrorblade.Sunder.Cast")
    target:EmitSound("Hero_Terrorblade.Sunder.Target")

    Timers:CreateTimer(0.1, function()
        modifier_aghanim_change_style_main_hero.choose = "mad"
        self:GetCaster():RemoveModifierByName("modifier_aghanim_change_style_main_hero")
    end)
end

aghanim_change_style_bath = class({})

function aghanim_change_style_bath:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCaster()
    local caster = self:GetCaster()

    local modifier_aghanim_change_style_main_hero = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_hero")
    if modifier_aghanim_change_style_main_hero then
        target = modifier_aghanim_change_style_main_hero.bath
        caster = modifier_aghanim_change_style_main_hero.clock
    end

    local sunder_particle_2 = ParticleManager:CreateParticle("particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(sunder_particle_2, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(sunder_particle_2, 15, Vector(0,152,255))
    ParticleManager:SetParticleControl(sunder_particle_2, 16, Vector(1,0,0))
    ParticleManager:ReleaseParticleIndex(sunder_particle_2)

    caster:EmitSound("Hero_Terrorblade.Sunder.Cast")
    target:EmitSound("Hero_Terrorblade.Sunder.Target")

    Timers:CreateTimer(0.1, function()
        modifier_aghanim_change_style_main_hero.choose = "bath"
        self:GetCaster():RemoveModifierByName("modifier_aghanim_change_style_main_hero")
    end)
end

aghanim_change_style_mech = class({})

function aghanim_change_style_mech:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCaster()
    local caster = self:GetCaster()

    local modifier_aghanim_change_style_main_hero = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_hero")
    if modifier_aghanim_change_style_main_hero then
        target = modifier_aghanim_change_style_main_hero.mech
        caster = modifier_aghanim_change_style_main_hero.clock
    end

    local sunder_particle_2 = ParticleManager:CreateParticle("particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(sunder_particle_2, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(sunder_particle_2, 15, Vector(0,152,255))
    ParticleManager:SetParticleControl(sunder_particle_2, 16, Vector(1,0,0))
    ParticleManager:ReleaseParticleIndex(sunder_particle_2)

    caster:EmitSound("Hero_Terrorblade.Sunder.Cast")
    target:EmitSound("Hero_Terrorblade.Sunder.Target")

    Timers:CreateTimer(0.1, function()
        modifier_aghanim_change_style_main_hero.choose = "mech"
        self:GetCaster():RemoveModifierByName("modifier_aghanim_change_style_main_hero")
    end)
end

aghanim_change_style_smith = class({})

function aghanim_change_style_smith:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCaster()
    local caster = self:GetCaster()

    local modifier_aghanim_change_style_main_hero = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_hero")
    if modifier_aghanim_change_style_main_hero then
        target = modifier_aghanim_change_style_main_hero.smith
        caster = modifier_aghanim_change_style_main_hero.clock
    end

    local sunder_particle_2 = ParticleManager:CreateParticle("particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(sunder_particle_2, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(sunder_particle_2, 15, Vector(0,152,255))
    ParticleManager:SetParticleControl(sunder_particle_2, 16, Vector(1,0,0))
    ParticleManager:ReleaseParticleIndex(sunder_particle_2)

    caster:EmitSound("Hero_Terrorblade.Sunder.Cast")
    target:EmitSound("Hero_Terrorblade.Sunder.Target")

    Timers:CreateTimer(0.1, function()
        modifier_aghanim_change_style_main_hero.choose = "smith"
        self:GetCaster():RemoveModifierByName("modifier_aghanim_change_style_main_hero")
    end)
end

function aghanim_change_style_mad:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function aghanim_change_style_bath:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function aghanim_change_style_mech:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function aghanim_change_style_smith:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

modifier_aghanim_change_style_main_mad = class({})
function modifier_aghanim_change_style_main_mad:GetTexture() return "aghanim_style_mad" end
function modifier_aghanim_change_style_main_mad:IsPurgable() return false end
function modifier_aghanim_change_style_main_mad:IsPurgeException() return false end

function modifier_aghanim_change_style_main_mad:OnCreated()
    if not IsServer() then return end

    local particle = ParticleManager:CreateParticle("particles/econ/events/ti8/ti8_hero_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    self:AddParticle(particle, false, false, -1, false, false)

    local aghanim_mad_wrench = self:GetCaster():AddAbility("aghanim_mad_wrench")
    aghanim_mad_wrench:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_mad_siled = self:GetCaster():AddAbility("aghanim_mad_siled")
    aghanim_mad_siled:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_chain = self:GetCaster():AddAbility("aghanim_chain")
    aghanim_chain:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_mad_wrench_buff")
    aghanim_blink_attack:SetLevel(1)

    local generic_hidden = self:GetCaster():AddAbility("generic_hidden")
    generic_hidden:SetLevel(1)

    local aghanim_mad_chains = self:GetCaster():AddAbility("aghanim_mad_chains")
    aghanim_mad_chains:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end
end

function modifier_aghanim_change_style_main_mad:OnDestroy()
    if not IsServer() then return end

    self:GetParent():Interrupt()

    local aghanim_shard = self:GetCaster():FindAbilityByName("aghanim_mad_wrench")
    if aghanim_shard then
        self:GetCaster().ability_level_aghanim_shard = aghanim_shard:GetLevel()
    end
    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_mad_siled")
    if aghanim_blink_cast then
        self:GetCaster().ability_level_aghanim_blink_cast = aghanim_blink_cast:GetLevel()
    end
    local aghanim_ray = self:GetCaster():FindAbilityByName("aghanim_chain")
    if aghanim_ray then
        self:GetCaster().ability_level_aghanim_ray = aghanim_ray:GetLevel()
    end
    local aghanim_change_style_main = self:GetCaster():FindAbilityByName("aghanim_mad_chains")
    if aghanim_change_style_main then
        self:GetCaster().ability_level_aghanim_change_style_main = aghanim_change_style_main:GetLevel()
    end

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            self:GetCaster():RemoveAbility(ability:GetAbilityName())
        end
    end

    local aghanim_shard = self:GetCaster():AddAbility("aghanim_shard")
    aghanim_shard:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_blink_cast = self:GetCaster():AddAbility("aghanim_blink_cast")
    aghanim_blink_cast:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_ray = self:GetCaster():AddAbility("aghanim_ray")
    aghanim_ray:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_blink_attack")
    aghanim_blink_attack:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local generic_hidden = self:GetCaster():AddAbility("aghanim_ray_stop")
    generic_hidden:SetLevel(1)

    local aghanim_change_style_main = self:GetCaster():AddAbility("aghanim_change_style_main")
    aghanim_change_style_main:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end

    if self:GetCaster():HasScepter() then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_invul_scepter", {duration = 1.5})
    end
end

function modifier_aghanim_change_style_main_mad:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
    }
end

function modifier_aghanim_change_style_main_mad:GetModifierModelChange()
    return "models/aghanim/aghanim_mad.vmdl"
end

function modifier_aghanim_change_style_main_mad:GetModifierPercentageCooldown()
    local special_bonus_aghanim_talent_5 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_5")
    if special_bonus_aghanim_talent_5 and special_bonus_aghanim_talent_5:GetLevel() > 0 then
        return special_bonus_aghanim_talent_5:GetSpecialValueFor("value")
    end
    return 0
end

modifier_aghanim_change_style_main_bath = class({})
function modifier_aghanim_change_style_main_bath:GetTexture() return "aghanim_style_bath" end
function modifier_aghanim_change_style_main_bath:IsPurgable() return false end
function modifier_aghanim_change_style_main_bath:IsPurgeException() return false end
function modifier_aghanim_change_style_main_bath:DestroyOnExpire() return not self:GetParent():HasModifier("modifier_morphling_boss_tidal_wave_buff") end

function modifier_aghanim_change_style_main_bath:OnCreated()
    if not IsServer() then return end

    local particle = ParticleManager:CreateParticle("particles/econ/events/ti7/ti7_hero_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    self:AddParticle(particle, false, false, -1, false, false)

    local aghanim_bath_bubble = self:GetCaster():AddAbility("aghanim_bath_bubble")
    aghanim_bath_bubble:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_puddle = self:GetCaster():AddAbility("aghanim_puddle")
    aghanim_puddle:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_water_ray = self:GetCaster():AddAbility("aghanim_water_ray")
    aghanim_water_ray:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_water_ray_stop")
    aghanim_blink_attack:SetLevel(1)

    local aghanim_bath_bubble_lop = self:GetCaster():AddAbility("aghanim_bath_bubble_lop")
    aghanim_bath_bubble_lop:SetLevel(1)

    local aghanim_waves_storm = self:GetCaster():AddAbility("aghanim_waves_storm")
    aghanim_waves_storm:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end
end

function modifier_aghanim_change_style_main_bath:OnDestroy()
    if not IsServer() then return end

    local aghanim_shard = self:GetCaster():FindAbilityByName("aghanim_bath_bubble")
    if aghanim_shard then
        self:GetCaster().ability_level_aghanim_shard = aghanim_shard:GetLevel()
    end
    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_puddle")
    if aghanim_blink_cast then
        self:GetCaster().ability_level_aghanim_blink_cast = aghanim_blink_cast:GetLevel()
    end
    local aghanim_ray = self:GetCaster():FindAbilityByName("aghanim_water_ray")
    if aghanim_ray then
        self:GetCaster().ability_level_aghanim_ray = aghanim_ray:GetLevel()
    end
    local aghanim_change_style_main = self:GetCaster():FindAbilityByName("aghanim_waves_storm")
    if aghanim_change_style_main then
        self:GetCaster().ability_level_aghanim_change_style_main = aghanim_change_style_main:GetLevel()
    end

    self:GetParent():Interrupt()

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            self:GetCaster():RemoveAbility(ability:GetAbilityName())
        end
    end

    local aghanim_shard = self:GetCaster():AddAbility("aghanim_shard")
    aghanim_shard:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_blink_cast = self:GetCaster():AddAbility("aghanim_blink_cast")
    aghanim_blink_cast:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_ray = self:GetCaster():AddAbility("aghanim_ray")
    aghanim_ray:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_blink_attack")
    aghanim_blink_attack:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local generic_hidden = self:GetCaster():AddAbility("aghanim_ray_stop")
    generic_hidden:SetLevel(1)

    local aghanim_change_style_main = self:GetCaster():AddAbility("aghanim_change_style_main")
    aghanim_change_style_main:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)
    aghanim_change_style_main:EndCooldown()
    aghanim_change_style_main:UseResources(false, false, false, true)

    local cooldown = aghanim_change_style_main:GetCooldownTimeRemaining()
    if self.cooldown then
        self.cooldown = self.cooldown * 10
        local percent = cooldown / 100 * self.cooldown
        aghanim_change_style_main:EndCooldown()
        aghanim_change_style_main:StartCooldown(cooldown - percent)
    end

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end

    if self:GetCaster():HasScepter() then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_invul_scepter", {duration = 1.5})
    end
end

function modifier_aghanim_change_style_main_bath:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
    }
end

function modifier_aghanim_change_style_main_bath:GetModifierModelChange()
    return "models/aghanim/aghanim_bath.vmdl"
end

function modifier_aghanim_change_style_main_bath:GetModifierPercentageCooldown()
    local special_bonus_aghanim_talent_5 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_5")
    if special_bonus_aghanim_talent_5 and special_bonus_aghanim_talent_5:GetLevel() > 0 then
        return special_bonus_aghanim_talent_5:GetSpecialValueFor("value")
    end
    return 0
end


modifier_aghanim_change_style_main_mech = class({})
function modifier_aghanim_change_style_main_mech:GetTexture() return "aghanim_style_mech" end
function modifier_aghanim_change_style_main_mech:IsPurgable() return false end
function modifier_aghanim_change_style_main_mech:IsPurgeException() return false end
function modifier_aghanim_change_style_main_mech:DestroyOnExpire() return not self:GetParent():HasModifier("modifier_aghanim_mech_attack_cast") end

function modifier_aghanim_change_style_main_mech:OnCreated()
    if not IsServer() then return end

    local particle = ParticleManager:CreateParticle("particles/econ/events/fall_2021/fall_2021_emblem_game_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    self:AddParticle(particle, false, false, -1, false, false)

    local aghanim_mech_sword = self:GetCaster():AddAbility("aghanim_mech_sword")
    aghanim_mech_sword:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_mech_force = self:GetCaster():AddAbility("aghanim_mech_force")
    aghanim_mech_force:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_mech_shield = self:GetCaster():AddAbility("aghanim_mech_shield")
    aghanim_mech_shield:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("generic_hidden")
    aghanim_blink_attack:SetLevel(1)

    local generic_hidden = self:GetCaster():AddAbility("generic_hidden")
    generic_hidden:SetLevel(1)

    local aghanim_mech_attack = self:GetCaster():AddAbility("aghanim_mech_attack")
    aghanim_mech_attack:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end

    self:GetCaster():SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
end

function modifier_aghanim_change_style_main_mech:OnDestroy()
    if not IsServer() then return end

    local aghanim_shard = self:GetCaster():FindAbilityByName("aghanim_mech_sword")
    if aghanim_shard then
        self:GetCaster().ability_level_aghanim_shard = aghanim_shard:GetLevel()
    end
    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_mech_force")
    if aghanim_blink_cast then
        self:GetCaster().ability_level_aghanim_blink_cast = aghanim_blink_cast:GetLevel()
    end
    local aghanim_ray = self:GetCaster():FindAbilityByName("aghanim_mech_shield")
    if aghanim_ray then
        self:GetCaster().ability_level_aghanim_ray = aghanim_ray:GetLevel()
    end
    local aghanim_change_style_main = self:GetCaster():FindAbilityByName("aghanim_mech_attack")
    if aghanim_change_style_main then
        self:GetCaster().ability_level_aghanim_change_style_main = aghanim_change_style_main:GetLevel()
    end

    self:GetParent():Interrupt()
    self:GetCaster():SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            self:GetCaster():RemoveAbility(ability:GetAbilityName())
        end
    end

    local aghanim_shard = self:GetCaster():AddAbility("aghanim_shard")
    aghanim_shard:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_blink_cast = self:GetCaster():AddAbility("aghanim_blink_cast")
    aghanim_blink_cast:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_ray = self:GetCaster():AddAbility("aghanim_ray")
    aghanim_ray:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_blink_attack")
    aghanim_blink_attack:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local generic_hidden = self:GetCaster():AddAbility("aghanim_ray_stop")
    generic_hidden:SetLevel(1)

    local aghanim_change_style_main = self:GetCaster():AddAbility("aghanim_change_style_main")
    aghanim_change_style_main:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)
    aghanim_change_style_main:EndCooldown()
    aghanim_change_style_main:UseResources(false, false, false, true)

    local cooldown = aghanim_change_style_main:GetCooldownTimeRemaining()
    if self.cooldown then
        self.cooldown = self.cooldown * 10
        local percent = cooldown / 100 * self.cooldown
        aghanim_change_style_main:EndCooldown()
        aghanim_change_style_main:StartCooldown(cooldown - percent)
    end

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end

    if self:GetCaster():HasScepter() then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_invul_scepter", {duration = 1.5})
    end
end

function modifier_aghanim_change_style_main_mech:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    }
end

function modifier_aghanim_change_style_main_mech:GetModifierModelChange()
    return "models/aghanim/aghanim_mech.vmdl"
end

function modifier_aghanim_change_style_main_mech:GetModifierAttackRangeBonus()
    return -450
end

function modifier_aghanim_change_style_main_mech:GetAttackSound()
    return "Hero_DragonKnight.Attack"
end

function modifier_aghanim_change_style_main_mech:GetModifierPercentageCooldown()
    local special_bonus_aghanim_talent_5 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_5")
    if special_bonus_aghanim_talent_5 and special_bonus_aghanim_talent_5:GetLevel() > 0 then
        return special_bonus_aghanim_talent_5:GetSpecialValueFor("value")
    end
    return 0
end

modifier_aghanim_change_style_main_smith = class({})
function modifier_aghanim_change_style_main_smith:GetTexture() return "aghanim_style_smith" end
function modifier_aghanim_change_style_main_smith:IsPurgable() return false end
function modifier_aghanim_change_style_main_smith:IsPurgeException() return false end

function modifier_aghanim_change_style_main_smith:OnCreated()
    if not IsServer() then return end

    local particle = ParticleManager:CreateParticle("particles/econ/events/fall_2022/player/fall_2022_emblem_effect_player_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    self:AddParticle(particle, false, false, -1, false, false)

    local aghanim_smith_mech = self:GetCaster():AddAbility("aghanim_smith_mech")
    aghanim_smith_mech:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_smith_jetpack = self:GetCaster():AddAbility("aghanim_smith_jetpack")
    aghanim_smith_jetpack:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_smith_crange = self:GetCaster():AddAbility("aghanim_smith_crange")
    aghanim_smith_crange:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("generic_hidden")
    aghanim_blink_attack:SetLevel(1)

    local generic_hidden = self:GetCaster():AddAbility("generic_hidden")
    generic_hidden:SetLevel(1)

    local aghanim_smith_bomb = self:GetCaster():AddAbility("aghanim_smith_bomb")
    aghanim_smith_bomb:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end
end

function modifier_aghanim_change_style_main_smith:OnDestroy()
    if not IsServer() then return end

    local aghanim_shard = self:GetCaster():FindAbilityByName("aghanim_smith_mech")
    if aghanim_shard then
        self:GetCaster().ability_level_aghanim_shard = aghanim_shard:GetLevel()
    end
    local aghanim_blink_cast = self:GetCaster():FindAbilityByName("aghanim_smith_jetpack")
    if aghanim_blink_cast then
        self:GetCaster().ability_level_aghanim_blink_cast = aghanim_blink_cast:GetLevel()
    end
    local aghanim_ray = self:GetCaster():FindAbilityByName("aghanim_smith_crange")
    if aghanim_ray then
        self:GetCaster().ability_level_aghanim_ray = aghanim_ray:GetLevel()
    end
    local aghanim_change_style_main = self:GetCaster():FindAbilityByName("aghanim_smith_bomb")
    if aghanim_change_style_main then
        self:GetCaster().ability_level_aghanim_change_style_main = aghanim_change_style_main:GetLevel()
    end

    self:GetParent():RemoveModifierByName("modifier_aghanim_smith_crange_buff")
    self:GetParent():Interrupt()

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            self:GetCaster():RemoveAbility(ability:GetAbilityName())
        end
    end

    local aghanim_shard = self:GetCaster():AddAbility("aghanim_shard")
    aghanim_shard:SetLevel(self:GetCaster().ability_level_aghanim_shard)

    local aghanim_blink_cast = self:GetCaster():AddAbility("aghanim_blink_cast")
    aghanim_blink_cast:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local aghanim_ray = self:GetCaster():AddAbility("aghanim_ray")
    aghanim_ray:SetLevel(self:GetCaster().ability_level_aghanim_ray)

    local aghanim_blink_attack = self:GetCaster():AddAbility("aghanim_blink_attack")
    aghanim_blink_attack:SetLevel(self:GetCaster().ability_level_aghanim_blink_cast)

    local generic_hidden = self:GetCaster():AddAbility("aghanim_ray_stop")
    generic_hidden:SetLevel(1)

    local aghanim_change_style_main = self:GetCaster():AddAbility("aghanim_change_style_main")
    aghanim_change_style_main:SetLevel(self:GetCaster().ability_level_aghanim_change_style_main)
    aghanim_change_style_main:EndCooldown()
    aghanim_change_style_main:UseResources(false, false, false, true)

    local cooldown = aghanim_change_style_main:GetCooldownTimeRemaining()
    if self.cooldown then
        self.cooldown = self.cooldown * 10
        local percent = cooldown / 100 * self.cooldown
        aghanim_change_style_main:EndCooldown()
        aghanim_change_style_main:StartCooldown(cooldown - percent)
    end

    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(0.5)
        end
    end

    if self:GetCaster():HasScepter() then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_aghanim_invul_scepter", {duration = 1.5})
    end
end

function modifier_aghanim_change_style_main_smith:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
    }
end

function modifier_aghanim_change_style_main_smith:GetModifierModelChange()
    return "models/aghanim/aghanim_smith.vmdl"
end

function modifier_aghanim_change_style_main_smith:GetModifierPercentageCooldown()
    local special_bonus_aghanim_talent_5 = self:GetCaster():FindAbilityByName("special_bonus_aghanim_talent_5")
    if special_bonus_aghanim_talent_5 and special_bonus_aghanim_talent_5:GetLevel() > 0 then
        return special_bonus_aghanim_talent_5:GetSpecialValueFor("value")
    end
    return 0
end

LinkLuaModifier("modifier_aghanim_mech_sword", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_sword_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_sword_armor_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_mech_sword = class({})

function aghanim_mech_sword:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local radius = self:GetSpecialValueFor("radius")
    local angle = self:GetSpecialValueFor("angle") / 2
    local duration = self:GetSpecialValueFor("knockback_duration")
    local distance = self:GetSpecialValueFor("knockback_distance")

    local enemies = FindUnitsInRadius( caster:GetTeamNumber(), caster:GetOrigin(), nil, radius,  DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,  DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )

    local buff = caster:AddNewModifier( caster, self, "modifier_aghanim_mech_sword", {})

    local origin = caster:GetOrigin()
    local cast_direction = (point-origin):Normalized()
    local cast_angle = VectorToAngles( cast_direction ).y

    local caught = false
    for _,enemy in pairs(enemies) do
        local enemy_direction = (enemy:GetOrigin() - origin):Normalized()
        local enemy_angle = VectorToAngles( enemy_direction ).y
        local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
        if angle_diff<=angle then
            caster:PerformAttack( enemy, true, true, true, true, false, false, true)
            caught = true
            self:PlayEffects2( enemy, origin, cast_direction )
            local modifier_aghanim_mech_sword_buff = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mech_sword_buff", {duration = self:GetSpecialValueFor("activity_duration")})

            if enemy:IsHero() then
                modifier_aghanim_mech_sword_buff:SetStackCount(modifier_aghanim_mech_sword_buff:GetStackCount() + self:GetSpecialValueFor("bonus_damage_hero"))

                local modifier_aghanim_mech_sword_armor_buff = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mech_sword_armor_buff", {duration = self:GetSpecialValueFor("activity_duration")})
                modifier_aghanim_mech_sword_armor_buff:SetStackCount(modifier_aghanim_mech_sword_armor_buff:GetStackCount() + self:GetSpecialValueFor("bonus_armor"))
            else
                modifier_aghanim_mech_sword_buff:SetStackCount(modifier_aghanim_mech_sword_buff:GetStackCount() + self:GetSpecialValueFor("bonus_damage_creep"))
            end
        end
    end

    buff:Destroy()

    self:PlayEffects1( caught, (point-origin):Normalized() )
end

function aghanim_mech_sword:PlayEffects1( caught, direction )
    local particle_cast = "particles/aghs_bash.vpcf"
    local sound_cast = "Hero_Mars.Shield.Cast"
    if not caught then
        local sound_cast = "Hero_Mars.Shield.Cast.Small"
    end
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )
    EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function aghanim_mech_sword:PlayEffects2( target, origin, direction )
    local particle_cast = "particles/aghs_crit.vpcf"
    local sound_cast = "Hero_Mars.Shield.Crit"
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )
    EmitSoundOn( sound_cast, target )
end

modifier_aghanim_mech_sword_buff = class({})
function modifier_aghanim_mech_sword_buff:GetTexture() return "aghanim_sword" end
function modifier_aghanim_mech_sword_buff:IsPurgable() return false end

function modifier_aghanim_mech_sword_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_aghanim_mech_sword_buff:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount()
end

modifier_aghanim_mech_sword_armor_buff = class({})
function modifier_aghanim_mech_sword_armor_buff:GetTexture() return "aghanim_sword" end
function modifier_aghanim_mech_sword_armor_buff:IsPurgable() return false end

function modifier_aghanim_mech_sword_armor_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_aghanim_mech_sword_armor_buff:GetModifierPhysicalArmorBonus()
    return self:GetStackCount()
end

modifier_aghanim_mech_sword = class({})

function modifier_aghanim_mech_sword:IsHidden()
    return true
end

function modifier_aghanim_mech_sword:IsDebuff()
    return false
end

function modifier_aghanim_mech_sword:IsPurgable()
    return false
end

function modifier_aghanim_mech_sword:OnCreated( kv )
    self.bonus_crit = self:GetAbility():GetSpecialValueFor( "crit_mult" )
    self.bonus_damage = self:GetCaster():GetMaxMana() / 100 * self.bonus_crit
end

function modifier_aghanim_mech_sword:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }

    return funcs
end

function modifier_aghanim_mech_sword:GetModifierPreAttack_BonusDamage()
    if IsClient() then
        return 0
    end
    return self.bonus_damage
end

LinkLuaModifier("modifier_aghanim_mech_force_generic_knockback_lua", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_aghanim_mech_force_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_force_thinker", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_force_slow", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_mech_force = class({})

function aghanim_mech_force:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function aghanim_mech_force:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end

function aghanim_mech_force:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function aghanim_mech_force:OnSpellStart()
    if not IsServer() then return end
    local origin = self:GetCaster():GetOrigin()

    local range = self:GetSpecialValueFor("distance")

    local point = origin + self:GetCaster():GetForwardVector() * range

    local distance_teleport = (point - self:GetCaster():GetAbsOrigin()):Length2D()

    local dist_check = (point - self:GetCaster():GetAbsOrigin()):Length2D()

    local direciton = (point - self:GetCaster():GetAbsOrigin())
    direciton.z = 0
    direciton = direciton:Normalized()

    local knockback = self:GetCaster():AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_aghanim_mech_force_generic_knockback_lua",
        {
            direction_x = direciton.x,
            direction_y = direciton.y,
            distance = distance_teleport,
            duration = 0.5,
        }
    )

    self:GetCaster():EmitSound("Birzha.VoidJump")

    local callback = function( bInterrupted )
        FindClearSpaceForUnit( self:GetCaster(), self:GetCaster():GetAbsOrigin(), true )
    end

    knockback:SetEndCallback( callback )
end

modifier_aghanim_mech_force_generic_knockback_lua = class({})

function modifier_aghanim_mech_force_generic_knockback_lua:IsHidden()
    return true
end

function modifier_aghanim_mech_force_generic_knockback_lua:IsPurgable()
    return false
end

function modifier_aghanim_mech_force_generic_knockback_lua:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end


function modifier_aghanim_mech_force_generic_knockback_lua:OnCreated( kv )
    if IsServer() then
        self.distance = kv.distance or 0
        self.height = kv.height or -1
        self.duration = kv.duration or 0
        self.distance_eff = 150
        self.position_eff = self:GetCaster():GetAbsOrigin()
        if kv.direction_x and kv.direction_y then
            self.direction = Vector(kv.direction_x,kv.direction_y,0):Normalized()
        else
            self.direction = -(self:GetParent():GetForwardVector())
        end
        self.tree = kv.tree_destroy_radius or self:GetParent():GetHullRadius()

        if kv.IsStun then self.stun = kv.IsStun==1 else self.stun = false end
        if kv.IsFlail then self.flail = kv.IsFlail==1 else self.flail = true end

        
        if self.duration == 0 then
            self:Destroy()
            return
        end

        
        self.parent = self:GetParent()
        self.origin = self.parent:GetOrigin()

        
        self.hVelocity = self.distance/self.duration

        
        local half_duration = self.duration/2
        self.gravity = 2*self.height/(half_duration*half_duration)
        self.vVelocity = self.gravity*half_duration

        
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

function modifier_aghanim_mech_force_generic_knockback_lua:OnRefresh( kv )
    if not IsServer() then return end
end

function modifier_aghanim_mech_force_generic_knockback_lua:OnDestroy( kv )
    if not IsServer() then return end

    if not self.interrupted then
        
        if self.tree>0 then
            GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), self.tree, true )
        end
    end

    if self.EndCallback then
        self.EndCallback( self.interrupted )
    end

    self:GetParent():InterruptMotionControllers( true )
end



function modifier_aghanim_mech_force_generic_knockback_lua:SetEndCallback( func ) 
    self.EndCallback = func
end



function modifier_aghanim_mech_force_generic_knockback_lua:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = self.stun,
    }

    return state
end



function modifier_aghanim_mech_force_generic_knockback_lua:UpdateHorizontalMotion( me, dt )
    local parent = self:GetParent()
    
    
    local target = self.direction*self.distance*(dt/self.duration)

    if true then
        local distance = (self:GetCaster():GetAbsOrigin() - self.position_eff):Length2D()
        local direction = (self.position_eff - self:GetCaster():GetAbsOrigin()):Normalized()
        self.position_eff = self:GetCaster():GetAbsOrigin()

        self.distance_eff = self.distance_eff + distance

        if self.distance_eff >= 150 then 
            self.distance_eff = 0
            CreateModifierThinker(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mech_force_thinker", {duration = self:GetAbility():GetSpecialValueFor("fire_duration"), x = direction.x, y = direction.y}, self:GetCaster():GetAbsOrigin(), self:GetCaster():GetTeamNumber(), false)
        end
    end

    if true then
        local targets = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), nil, 150, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
        for _,enemy in pairs(targets) do
            enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mech_force_slow", {duration = 1 * (1-enemy:GetStatusResistance())})
        end
    end

    parent:SetOrigin( parent:GetOrigin() + target )
end

function modifier_aghanim_mech_force_generic_knockback_lua:OnHorizontalMotionInterrupted()
    if IsServer() then
        self.interrupted = true
        self:Destroy()
    end
end

function modifier_aghanim_mech_force_generic_knockback_lua:UpdateVerticalMotion( me, dt )
    
    local time = dt/self.duration

    
    self.parent:SetOrigin( self.parent:GetOrigin() + Vector( 0, 0, self.vVelocity*dt ) )

    
    self.vVelocity = self.vVelocity - self.gravity*dt
end

function modifier_aghanim_mech_force_generic_knockback_lua:OnVerticalMotionInterrupted()
    if IsServer() then
        self.interrupted = true
        self:Destroy()
    end
end

function modifier_aghanim_mech_force_generic_knockback_lua:GetEffectName()
    return "particles/econ/events/fall_2021/force_staff_fall_2021.vpcf"
end

function modifier_aghanim_mech_force_generic_knockback_lua:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_aghanim_mech_force_thinker = class({})
function modifier_aghanim_mech_force_thinker:IsHidden() return true end
function modifier_aghanim_mech_force_thinker:IsPurgable() return false end

function modifier_aghanim_mech_force_thinker:OnCreated(params)
    if not IsServer() then return end
    self.radius = 180
    self.duration = self:GetAbility():GetSpecialValueFor("fire_duration")
    self.interval = 0.5
    self.duration_debuff= self:GetAbility():GetSpecialValueFor("debuff_duration")
    self.dir = Vector(params.x, params.y, 0)
    self.start_pos = self:GetParent():GetAbsOrigin() - self.dir*self.radius/2
    self.end_pos = self:GetParent():GetAbsOrigin() + self.dir*self.radius/2

    self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_mars/mars_spear_burning_trail.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.pfx, 0, self.start_pos)
    ParticleManager:SetParticleControl(self.pfx, 1, self.end_pos)
    ParticleManager:SetParticleControl(self.pfx, 2, Vector(self.duration, 0, 0))
    ParticleManager:SetParticleControl(self.pfx, 3, Vector(self.radius, 0, 0))
    ParticleManager:SetParticleControl(self.pfx, 60, Vector(0, 0, 255))
    ParticleManager:SetParticleControl(self.pfx, 61, Vector(1, 1, 1))
    self:AddParticle( self.pfx, false, false, -1, false, false ) 
    self:StartIntervalThink(FrameTime())
end

function modifier_aghanim_mech_force_thinker:OnIntervalThink()
    if not IsServer() then return end
    if self:GetAbility() == nil then return end
    local targets = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), nil, 180, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
    for _,enemy in pairs(targets) do
        enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mech_force_debuff", {duration = self.duration_debuff * (1-enemy:GetStatusResistance())})
    end
end

modifier_aghanim_mech_force_debuff = class({})
function modifier_aghanim_mech_force_debuff:GetTexture() return "aghanim_force" end
function modifier_aghanim_mech_force_debuff:OnCreated()
    self.slow = -30
    self.damage = 80
    if not IsServer() then return end
    self:StartIntervalThink(0.5)
end

function modifier_aghanim_mech_force_debuff:OnIntervalThink()
    if not IsServer() then return end
    ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.damage * 0.5, damage_type = DAMAGE_TYPE_MAGICAL})
end

function modifier_aghanim_mech_force_debuff:GetEffectName()
    return "particles/aghs_fire_debuff.vpcf"
end

function modifier_aghanim_mech_force_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_aghanim_mech_force_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_mech_force_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

modifier_aghanim_mech_force_slow = class({})

function modifier_aghanim_mech_force_slow:GetTexture() return "aghanim_force" end

function modifier_aghanim_mech_force_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_mech_force_slow:GetModifierMoveSpeedBonus_Percentage()
    return -100
end

LinkLuaModifier("modifier_aghanim_mech_attack_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_attack_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_attack_cast", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_mech_attack = class({})

function aghanim_mech_attack:OnSpellStart()
    if not IsServer() then return end
    local point = self:GetCursorPosition()
    local duration = 2.2
    self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_aghanim_mech_attack_cast", { duration = duration, x = point.x, y = point.y, } )
end

modifier_aghanim_mech_attack_cast = class({})

function modifier_aghanim_mech_attack_cast:IsHidden() return true end

function modifier_aghanim_mech_attack_cast:IsPurgable()
    return false
end

function modifier_aghanim_mech_attack_cast:OnCreated( kv )
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.team = self.parent:GetTeamNumber()
    self.charge = 2.2

    self.crit_mult = self:GetAbility():GetSpecialValueFor( "crit_mult" )
    self.turn_rate = 120
    self.interval = 0.03
    self.projectile_range = 2000 + self:GetCaster():GetCastRangeBonus()
    self.projectile_width = 150
    
    if not IsServer() then return end

    EmitSoundOn("Birzha.MechAttackStart", self:GetParent())
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4, 1)

    self:StartIntervalThink( self.interval)

    local vec = Vector( kv.x, kv.y, 0 )

    self:SetDirection( vec )

    self.current_dir = self.target_dir

    self.face_target = true

    self.parent:SetForwardVector( self.current_dir )

    self.max_charge = false

    self.turn_speed = self.interval*self.turn_rate
end

function modifier_aghanim_mech_attack_cast:OnDestroy()
    if not IsServer() then return end

    StopSoundOn("Birzha.MechAttackStart", self:GetParent())
   -- self:GetParent():FadeGesture(ACT_DOTA_CAST_ABILITY_4)

    local direction = self.current_dir

    self:Shoot()
end

function modifier_aghanim_mech_attack_cast:DeclareFunctions()
    local funcs = 
    {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
    return funcs
end

function modifier_aghanim_mech_attack_cast:OnOrder( params )
    if params.unit~=self:GetParent() then return end

    if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION or params.order_type == DOTA_UNIT_ORDER_CONTINUE then
        return
    end

    if  params.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION or
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
    then
        self:SetDirection( params.new_pos )
    elseif 
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET or
        params.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET
    then
        self:SetDirection( params.target:GetOrigin() )
    end
end

function modifier_aghanim_mech_attack_cast:IllusionScepterDirection( target )
    self:SetDirection( target:GetOrigin() )
end

function modifier_aghanim_mech_attack_cast:GetModifierMoveSpeed_Limit()
    return 0.1
end

function modifier_aghanim_mech_attack_cast:GetModifierTurnRate_Percentage()
    return -self.turn_rate
end

function modifier_aghanim_mech_attack_cast:GetModifierDisableTurning()
    return 1
end

function modifier_aghanim_mech_attack_cast:CheckState()
    local state = {}
    state =
    { 
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true,
    }
    return state
end

function modifier_aghanim_mech_attack_cast:SetDirection( vec )
    if vec.x == self:GetCaster():GetAbsOrigin().x and vec.y == self:GetCaster():GetAbsOrigin().y then 
        vec = self:GetCaster():GetAbsOrigin() + 100*self:GetCaster():GetForwardVector()
    end
    self.target_dir = ((vec-self.parent:GetOrigin())*Vector(1,1,0)):Normalized()
    self.face_target = false
end

function modifier_aghanim_mech_attack_cast:TurnLogic()
    if self.face_target then return end
    local current_angle = VectorToAngles( self.current_dir ).y
    local target_angle = VectorToAngles( self.target_dir ).y
    local angle_diff = AngleDiff( current_angle, target_angle )
    local sign = -1
    if angle_diff<0 then sign = 1 end
    if math.abs( angle_diff )<1.1*self.turn_speed then
        self.current_dir = self.target_dir
        self.face_target = true
    else
        self.current_dir = RotatePosition( Vector(0,0,0), QAngle(0, sign*self.turn_speed, 0), self.current_dir )
    end
    local a = self.parent:IsCurrentlyHorizontalMotionControlled()
    local b = self.parent:IsCurrentlyVerticalMotionControlled()
    if not (a or b) then
        self.parent:SetForwardVector( self.current_dir )
    end
end

function modifier_aghanim_mech_attack_cast:UpdateStack()
    local pct = math.min(1, (math.min( self:GetElapsedTime(), self.charge )/self.charge))
    pct = math.floor( pct*100 )
    self:SetStackCount( pct )
end

function modifier_aghanim_mech_attack_cast:OrderFilter( data )
    if #data.units>1 then return true end
    local unit
    for _,id in pairs(data.units) do
        unit = EntIndexToHScript( id )
    end
    if unit~=self.parent then return true end
    if data.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION then
        data.order_type = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
    elseif data.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET or data.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET then
        local pos = EntIndexToHScript( data.entindex_target ):GetOrigin()
        data.order_type = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
        data.position_x = pos.x
        data.position_y = pos.y
        data.position_z = pos.z
    end
    return true
end

function modifier_aghanim_mech_attack_cast:UpdateEffect()
    local startpos = self.parent:GetAbsOrigin()
    local endpos = startpos + self.current_dir * self.projectile_range
    ParticleManager:SetParticleControl( self.effect_cast, 0, startpos )
    ParticleManager:SetParticleControl( self.effect_cast, 1, endpos )
end

function modifier_aghanim_mech_attack_cast:OnIntervalThink()
    if not IsServer() then
        self:UpdateStack()
        return
    end

    self:UpdateStack()

    self:TurnLogic()

    local startpos = self.parent:GetOrigin()
    local visions = self.projectile_range/self.projectile_width
    local delta = self.parent:GetForwardVector() * self.projectile_width

    if not self.charged and self:GetElapsedTime()>self.charge then
        self.charged = true
    end

    local remaining = self:GetRemainingTime()

    local seconds = math.ceil( remaining )

    local isHalf = (seconds-remaining)>0.5

    if isHalf then seconds = seconds-1 end
end

function modifier_aghanim_mech_attack_cast:Shoot(new_pct)
    if not IsServer() then return end
    local direction = self.current_dir

    self:GetParent():EmitSound("Birzha.MechAttackEnd")

    local direction = self:GetCaster():GetForwardVector()

    local point = self:GetCaster():GetAbsOrigin() + direction * self:GetAbility():GetSpecialValueFor("distance")

    local particle = ParticleManager:CreateParticle("particles/elder_aghs.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, point)
    ParticleManager:SetParticleControl(particle, 3, Vector(0,0,0))

    local buff = self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mech_attack_buff", {})

    local units = FindUnitsInLine(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), point, nil, 150, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)

    for _, unit in pairs(units) do
        unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", {duration = self:GetAbility():GetSpecialValueFor("stun") * (1-unit:GetStatusResistance())})
        unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mech_attack_debuff", {duration = self:GetAbility():GetSpecialValueFor("duration") * (1-unit:GetStatusResistance())})
        self:GetCaster():PerformAttack( unit, true, true, true, true, false, false, true)
    end

    EmitSoundOnLocationWithCaster(point, "Birzha.MechAttackEnd", self:GetCaster())

    self:GetCaster():EmitSound("Birzha.MechAttackEnd")

    buff:Destroy()

    local modifier_aghanim_change_style_main_mech = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_mech")
    if modifier_aghanim_change_style_main_mech then
        modifier_aghanim_change_style_main_mech.cooldown = #units
    end

    self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_remove_aghanim_styles_add", {duration = 0.5})
end

modifier_aghanim_mech_attack_buff = class({})

function modifier_aghanim_mech_attack_buff:IsHidden()
    return true
end

function modifier_aghanim_mech_attack_buff:IsDebuff()
    return false
end

function modifier_aghanim_mech_attack_buff:IsPurgable()
    return false
end

function modifier_aghanim_mech_attack_buff:OnCreated( kv )
    self.bonus_crit = self:GetAbility():GetSpecialValueFor( "crit_mult" )
    self.bonus_damage = (self:GetCaster():GetMaxMana() / 100 * self.bonus_crit) + self:GetAbility():GetSpecialValueFor("orig_damage")
end

function modifier_aghanim_mech_attack_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }

    return funcs
end

function modifier_aghanim_mech_attack_buff:GetModifierPreAttack_BonusDamage()
    if IsClient() then
        return 0
    end
    return self.bonus_damage
end

modifier_aghanim_mech_attack_debuff = class({})
function modifier_aghanim_mech_attack_debuff:GetTexture() return "aghanim_attack" end
function modifier_aghanim_mech_attack_debuff:IsPurgeException() return false end
function modifier_aghanim_mech_attack_debuff:IsPurgable() return false end

function modifier_aghanim_mech_attack_debuff:OnCreated()
    self.armor = 0
    self.armor = self:GetParent():GetPhysicalArmorValue(false) / 100 * self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_aghanim_mech_attack_debuff:DeclareFunctions()
    local funcs = {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
    return funcs
end

function modifier_aghanim_mech_attack_debuff:GetModifierPhysicalArmorBonus()
    return self.armor * (-1)
end

function modifier_aghanim_mech_attack_debuff:GetEffectName()
    return "particles/armor_debufff_aghanim.vpcf"
end

function modifier_aghanim_mech_attack_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

LinkLuaModifier("modifier_aghanim_mech_shield", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_shield_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mech_shield_aura", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_mech_shield = class({})

function aghanim_mech_shield:GetIntrinsicModifierName()
    return "modifier_aghanim_mech_shield"
end

function aghanim_mech_shield:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():EmitSound("Hero_Tinker.GridEffect")
    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), self:GetCaster(), self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
    local armor_per_hero = self:GetSpecialValueFor("armor_per_hero") * #enemies
    local magical_per_hero = self:GetSpecialValueFor("magical_per_hero") * #enemies
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mech_shield_buff", {duration = self:GetSpecialValueFor("duration"), armor_per_hero = armor_per_hero, magical_per_hero = magical_per_hero})
end

modifier_aghanim_mech_shield = class({})

function modifier_aghanim_mech_shield:IsHidden() return true end
function modifier_aghanim_mech_shield:IsPurgable() return false end
function modifier_aghanim_mech_shield:IsPurgeException() return false end

function modifier_aghanim_mech_shield:OnCreated()
    self.armor = self:GetAbility():GetSpecialValueFor("armor")
    self.health = self:GetAbility():GetSpecialValueFor("health")
    if not IsServer() then return end
    self:GetCaster():CalculateStatBonus(true)
    self:StartIntervalThink(FrameTime())
end

function modifier_aghanim_mech_shield:OnRefresh()
    self.armor = self:GetAbility():GetSpecialValueFor("armor")
    self.health = self:GetAbility():GetSpecialValueFor("health")
    if not IsServer() then return end
    self:GetCaster():CalculateStatBonus(true)
    self:StartIntervalThink(FrameTime())
end

function modifier_aghanim_mech_shield:OnIntervalThink()
    if not IsServer() then return end
    if self:GetAbility() == nil then
        self:Destroy()
    end
end

function modifier_aghanim_mech_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_aghanim_mech_shield:GetModifierHealthBonus()
    return self.health
end

function modifier_aghanim_mech_shield:GetModifierPhysicalArmorBonus()
    return self.armor
end

modifier_aghanim_mech_shield_buff = class({})
function modifier_aghanim_mech_shield_buff:GetTexture() return "aghanim_shield" end
function modifier_aghanim_mech_shield_buff:OnCreated(params)
    if not IsServer() then return end
    self.armor_per_hero = params.armor_per_hero * -1
    self.magical_per_hero = params.magical_per_hero
    self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_defense_matrix.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(self.pfx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    self:AddParticle(self.pfx, false, false, -1, false, false)
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.1)
end

function modifier_aghanim_mech_shield_buff:OnIntervalThink()
    if not IsServer() then return end
    self:SendBuffRefreshToClients()
end

function modifier_aghanim_mech_shield_buff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_aghanim_mech_shield_buff:GetModifierMagicalResistanceBonus()
    return self.magical_per_hero
end

function modifier_aghanim_mech_shield_buff:OnTooltip()
    return self.armor_per_hero
end

function modifier_aghanim_mech_shield_buff:GetModifierIncomingDamage_Percentage(params)
    if params.damage_type == DAMAGE_TYPE_PHYSICAL then
        return -self.armor_per_hero
    end
end

function modifier_aghanim_mech_shield_buff:AddCustomTransmitterData()
    return 
    {
        magical_per_hero = self.magical_per_hero,
        armor_per_hero = self.armor_per_hero,
    }
end

function modifier_aghanim_mech_shield_buff:HandleCustomTransmitterData( data )
    self.magical_per_hero = data.magical_per_hero
    self.armor_per_hero = data.armor_per_hero
end

function modifier_aghanim_mech_shield_buff:IsAura()
    return true
end

function modifier_aghanim_mech_shield_buff:GetModifierAura()
    return "modifier_aghanim_mech_shield_aura"
end

function modifier_aghanim_mech_shield_buff:GetAuraRadius()
    return 800
end

function modifier_aghanim_mech_shield_buff:GetAuraDuration()
    return 0
end

function modifier_aghanim_mech_shield_buff:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_aghanim_mech_shield_buff:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_aghanim_mech_shield_buff:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_aghanim_mech_shield_buff:GetAuraEntityReject(target)
    if IsServer() then
        if target == self:GetCaster() then
            return true
        else
            return false
        end
    end
end

modifier_aghanim_mech_shield_aura = class({})

function modifier_aghanim_mech_shield_aura:GetTexture() return "aghanim_shield" end

function modifier_aghanim_mech_shield_aura:OnCreated()
    if not IsServer() then return end
    self.armor_per_hero = 0
    self.magical_per_hero = 0
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.1)
end

function modifier_aghanim_mech_shield_aura:OnIntervalThink()
    if not IsServer() then return end
    if self:GetAuraOwner() then
        local modifier_aghanim_mech_shield_buff = self:GetAuraOwner():FindModifierByName("modifier_aghanim_mech_shield_buff")
        if modifier_aghanim_mech_shield_buff then
            self.armor_per_hero = modifier_aghanim_mech_shield_buff.armor_per_hero * 0.5
            self.magical_per_hero = modifier_aghanim_mech_shield_buff.magical_per_hero * 0.5
        end
    end
    self:SendBuffRefreshToClients()
end

function modifier_aghanim_mech_shield_aura:AddCustomTransmitterData()
    return 
    {
        magical_per_hero = self.magical_per_hero,
        armor_per_hero = self.armor_per_hero,
    }
end

function modifier_aghanim_mech_shield_aura:HandleCustomTransmitterData( data )
    self.magical_per_hero = data.magical_per_hero
    self.armor_per_hero = data.armor_per_hero
end

function modifier_aghanim_mech_shield_aura:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_aghanim_mech_shield_aura:GetModifierMagicalResistanceBonus()
    return self.magical_per_hero
end

function modifier_aghanim_mech_shield_aura:GetModifierIncomingDamage_Percentage(params)
    if params.damage_type == DAMAGE_TYPE_PHYSICAL then
        return -self.armor_per_hero
    end
end
















LinkLuaModifier("modifier_aghanim_bath_bubble_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_bath_bubble_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_bath_bubble_lop", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_bath_bubble = class({})

function aghanim_bath_bubble:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts", context )
end

function aghanim_bath_bubble:OnSpellStart()
    if not IsServer() then return end
    local point = self:GetCursorPosition()
    local distance = self:GetSpecialValueFor("distance")
    local spawnPos = self:GetCaster():GetOrigin()

    local direction = point-self:GetCaster():GetAbsOrigin()
    direction.z = 0
    direction = direction:Normalized()

    local info = 
    {
        Source = self:GetCaster(),
        Ability = self,
        vSpawnOrigin = self:GetCaster():GetAttachmentOrigin(self:GetCaster():ScriptLookupAttachment("attach_staff_fx")),
        bDeleteOnHit = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO,
        EffectName = "particles/aghanim_bubble.vpcf",
        fDistance = distance,
        fStartRadius = 100,
        fEndRadius = 100,
        vVelocity = direction * 1200,
        iSourceAttachment   = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bProvidesVision = false,
        ExtraData = {heal = self:GetSpecialValueFor("heal"), damage = self:GetSpecialValueFor("damage")}
    }

    self:GetCaster():EmitSound("Birzha.WaterBubble")

    ProjectileManager:CreateLinearProjectile(info)
end

function aghanim_bath_bubble:OnProjectileHit_ExtraData(target, vLocation, table)

    if target == nil then
        local particle = ParticleManager:CreateParticle("particles/econ/taunts/snapfire/snapfire_taunt_bubble_pop.vpcf", PATTACH_WORLDORIGIN, nil)
        local p = GetGroundPosition(vLocation, nil)
        ParticleManager:SetParticleControl(particle, 0, p)
    end

    if target ~= nil and target ~= self:GetCaster() then
        if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
            target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_bath_bubble_debuff", {duration = self:GetSpecialValueFor("stun_duration") * (1-target:GetStatusResistance())})
            self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_bath_bubble_lop", {duration = self:GetSpecialValueFor("stun_duration") * (1-target:GetStatusResistance()), target = target:entindex()})
        else
            target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_bath_bubble_buff", {duration = self:GetSpecialValueFor("buff_duration")})
            self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_bath_bubble_lop", {duration = self:GetSpecialValueFor("buff_duration"), target = target:entindex()})
        end
        return true
    end
end

modifier_aghanim_bath_bubble_debuff = class({})

function modifier_aghanim_bath_bubble_debuff:GetTexture() return "aghanim_bubble" end

function modifier_aghanim_bath_bubble_debuff:OnCreated()
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/econ/taunts/snapfire/snapfire_taunt_bubble.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt( particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
    self:AddParticle(particle, false, false, -1, false, false)
    self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_ice_slide", {})
    self.lop_damage = self:GetAbility():GetSpecialValueFor("lop_damage")
    self.dmg = self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetMaxMana() / 100 * self:GetAbility():GetSpecialValueFor("damage_from_mana"))
    self.damage = 0
end

function modifier_aghanim_bath_bubble_debuff:OnDestroy()
    if not IsServer() then return end
    ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.dmg, damage_type = DAMAGE_TYPE_PURE})
    self:GetParent():RemoveModifierByName("modifier_ice_slide")
    self:GetCaster():RemoveModifierByName("modifier_aghanim_bath_bubble_lop")
    self:GetParent():EmitSound("Birzha.VoidBubble")
end

function modifier_aghanim_bath_bubble_debuff:CheckState()
    return 
    {
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_FLYING] = true,
        [MODIFIER_STATE_SILENCED] = true,
    }
end

function modifier_aghanim_bath_bubble_debuff:DeclareFunctions()
    return 
    {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
    }
end

function modifier_aghanim_bath_bubble_debuff:GetOverrideAnimation()
    return ACT_DOTA_FLAIL
end

function modifier_aghanim_bath_bubble_debuff:OnTakeDamage(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if params.attacker == self:GetParent() then return end
    self.damage = self.damage + params.damage
    if self.damage >= self.lop_damage then
        self:Destroy()
    end
end

modifier_aghanim_bath_bubble_buff = class({})

function modifier_aghanim_bath_bubble_buff:GetTexture() return "aghanim_bubble" end

function modifier_aghanim_bath_bubble_buff:OnCreated()
    self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
    self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/econ/taunts/snapfire/snapfire_taunt_bubble.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt( particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
    self:AddParticle(particle, false, false, -1, false, false)
    self.lop_damage = self:GetAbility():GetSpecialValueFor("lop_damage")
    self.damage = 0
    self.heal = self:GetAbility():GetSpecialValueFor("heal")
end

function modifier_aghanim_bath_bubble_buff:OnDestroy()
    if not IsServer() then return end
    self:GetParent():EmitSound("Birzha.VoidBubble")
    self:GetParent():Heal(self.heal, self:GetAbility())
    self:GetCaster():RemoveModifierByName("modifier_aghanim_bath_bubble_lop")
end

function modifier_aghanim_bath_bubble_buff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_aghanim_bath_bubble_buff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_aghanim_bath_bubble_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed
end

function modifier_aghanim_bath_bubble_buff:OnTakeDamage(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if params.attacker == self:GetParent() then return end
    self.damage = self.damage + params.damage
    if self.damage >= self.lop_damage then
        self:Destroy()
    end
end

aghanim_bath_bubble_lop = class({})

function aghanim_bath_bubble_lop:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_aghanim_bath_bubble_lop")
end

modifier_aghanim_bath_bubble_lop = class({})

function modifier_aghanim_bath_bubble_lop:IsHidden() return true end
function modifier_aghanim_bath_bubble_lop:IsPurgable() return false end
function modifier_aghanim_bath_bubble_lop:IsPurgeException() return false end

function modifier_aghanim_bath_bubble_lop:OnCreated(params)
    if not IsServer() then return end
    self.target = EntIndexToHScript(params.target)
    self:GetParent():SwapAbilities("aghanim_bath_bubble", "aghanim_bath_bubble_lop", false, true)
end

function modifier_aghanim_bath_bubble_lop:OnDestroy()
    if not IsServer() then return end

    if not self:GetParent():HasModifier("modifier_aghanim_change_style_main_bath") then return end

    self:GetParent():SwapAbilities("aghanim_bath_bubble_lop", "aghanim_bath_bubble", false, true)

    local aghanim_bath_bubble = self:GetCaster():FindAbilityByName("aghanim_bath_bubble")
    if aghanim_bath_bubble then
        aghanim_bath_bubble:EndCooldown()
        aghanim_bath_bubble:UseResources(false, false, false, true)
    end

    if self.target then
        self.target:RemoveModifierByName("modifier_aghanim_bath_bubble_debuff")
        self.target:RemoveModifierByName("modifier_aghanim_bath_bubble_buff")
    end
end

LinkLuaModifier("modifier_aghanim_puddle", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_puddle_aura", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_puddle_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_puddle_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_puddle = class({})

function aghanim_puddle:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function aghanim_puddle:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor( "duration" )
    CreateModifierThinker( caster, self, "modifier_aghanim_puddle", { duration = duration }, point, caster:GetTeamNumber(), false ) 
end

modifier_aghanim_puddle = class({})

function modifier_aghanim_puddle:IsPurgable()
    return false
end

function modifier_aghanim_puddle:OnCreated()
    if not IsServer() then return end
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_water_puddle.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(self.radius,1,1))
    self:AddParticle(particle, false, false, -1, false, false)
    self:GetParent():EmitSound("Birzha.WaterKunkka")
end

function modifier_aghanim_puddle:IsAura()
    return true
end

function modifier_aghanim_puddle:GetModifierAura()
    return "modifier_aghanim_puddle_aura"
end

function modifier_aghanim_puddle:GetAuraRadius()
    return self.radius
end

function modifier_aghanim_puddle:GetAuraDuration()
    return 0
end

function modifier_aghanim_puddle:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_aghanim_puddle:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_aghanim_puddle:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

modifier_aghanim_puddle_aura = class({})

function modifier_aghanim_puddle_aura:IsPurgable()
    return false
end

function modifier_aghanim_puddle_aura:IsHidden()
    return true
end

function modifier_aghanim_puddle_aura:OnCreated()
    if not IsServer() then return end
    if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_puddle_buff", {duration = self:GetAbility():GetSpecialValueFor("buff_duration")})
    else
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_puddle_debuff", {duration = 2})
    end
    self:StartIntervalThink(0.1)
end

function modifier_aghanim_puddle_aura:OnIntervalThink()
    if not IsServer() then return end
    if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_puddle_buff", {duration = self:GetAbility():GetSpecialValueFor("buff_duration")})
    else
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_puddle_debuff", {duration = 2})
    end
end

modifier_aghanim_puddle_buff = class({})

function modifier_aghanim_puddle_buff:GetTexture() return "aghanim_puddle" end

function modifier_aghanim_puddle_buff:OnCreated()
    self.attack_speed = self:GetAbility():GetSpecialValueFor("attackspeed")
    self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_aghanim_puddle_buff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_puddle_buff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_aghanim_puddle_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed
end

modifier_aghanim_puddle_debuff = class({})

function modifier_aghanim_puddle_debuff:GetTexture()
    return "aghanim_puddle"
end

function modifier_aghanim_puddle_debuff:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_aghanim_puddle_debuff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_puddle_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

LinkLuaModifier("modifier_aghanim_water_ray", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_water_ray = class({})

function aghanim_water_ray:Precache( context )
    PrecacheResource( "particle", "particles/creatures/aghanim/staff_beam.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_beam_channel.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_beam_burn.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/staff_beam_linger.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/staff_beam_tgt_ring.vpcf", context )
    PrecacheResource( "particle", "particles/creatures/aghanim/aghanim_debug_ring.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_huskar.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_jakiro.vsndevts", context )
end

function aghanim_water_ray:OnAbilityPhaseStart()
    if IsServer() then
        self.nChannelFX = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_beam_channel.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    end
    return true
end

function aghanim_water_ray:OnAbilityPhaseInterrupted()
    if IsServer() then
        if self.nChannelFX then
            ParticleManager:DestroyParticle(self.nChannelFX, true)
        end
    end
end

function aghanim_water_ray:OnSpellStart()
    if not IsServer() then return end

    local point = self:GetCursorPosition()

    local direction = point - self:GetCaster():GetAbsOrigin()

    local distance = direction:Length2D()

    direction = direction:Normalized()

    if distance > self:GetSpecialValueFor("max_distance") then
        point = self:GetCaster():GetAbsOrigin() + direction * self:GetSpecialValueFor("max_distance")
    end

    if distance < self:GetSpecialValueFor("min_distance") then
        point = self:GetCaster():GetAbsOrigin() + direction * self:GetSpecialValueFor("min_distance")
    end

    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_water_ray", {duration = self:GetSpecialValueFor("duration"), x = point.x, y = point.y, z = point.z })
end

modifier_aghanim_water_ray = class({})

function modifier_aghanim_water_ray:GetTexture() return "aghanim_water_ray" end

function modifier_aghanim_water_ray:IsPurgable() return false end

function modifier_aghanim_water_ray:OnCreated(params)
    if not IsServer() then return end

    local aghanim_water_ray_stop = self:GetCaster():FindAbilityByName("aghanim_water_ray_stop")
    if aghanim_water_ray_stop then
        aghanim_water_ray_stop:SetLevel(1)
    end

    self:GetParent():SwapAbilities("aghanim_water_ray", "aghanim_water_ray_stop", false, true)

    self.point = Vector(params.x, params.y, params.z)

    self.dummy = CreateUnitByName( "npc_dota_companion", self.point, false, nil, nil, self:GetCaster():GetTeamNumber() )
    self.dummy:SetAbsOrigin(self.point)
    self.dummy:AddNewModifier(self.dummy, self:GetAbility(), "modifier_mum_meat_hook_hook_thinker", {duration = self:GetAbility():GetSpecialValueFor("duration")})
    self.effect_time = 0
    self.nBeamFXIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/staff_beam_water.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_staff_fx", self:GetCaster():GetAbsOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 1, self.dummy, PATTACH_ABSORIGIN_FOLLOW, nil, self.dummy:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 2, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self.dummy:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nBeamFXIndex, 9, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true )

    EmitSoundOn( "Birzha.RayAgh", self:GetCaster() )

    self:StartIntervalThink(FrameTime())
end

function modifier_aghanim_water_ray:OnIntervalThink()
    if not IsServer() then return end

    if self.dummy and self.dummy:IsNull() then return end

    if self:GetParent():IsStunned() or self:GetParent():IsSilenced() then
        self:Destroy()
        return
    end

    local heal = self:GetAbility():GetSpecialValueFor("heal")
    local base_heal = self:GetAbility():GetSpecialValueFor("base_heal")

    local direction = self.point - self.dummy:GetAbsOrigin()
    direction.z = 0
    direction = direction:Normalized()

    local new_point = self.dummy:GetAbsOrigin() + direction * (550 * FrameTime())
    local dir_min_c = self:GetCaster():GetAbsOrigin() - new_point
    local distance = dir_min_c:Length2D()
    dir_min_c.z = 0
    local direction_min = dir_min_c:Normalized()

    if distance < self:GetAbility():GetSpecialValueFor("min_distance") - 50 then
        local dir = new_point - self:GetCaster():GetAbsOrigin()
        local len = dir:Length2D()
        dir.z = 0
        dir = dir:Normalized()
        new_point = new_point + dir * (self:GetAbility():GetSpecialValueFor("min_distance") - 150)
    end

    new_point = GetGroundPosition(new_point, nil)

    AddFOWViewer(self:GetCaster():GetTeamNumber(), self.dummy:GetAbsOrigin(), 100, FrameTime(), false)
    self.dummy:SetAbsOrigin(new_point)

    if self.effect_time <= 0.4 then
        self.effect_time = self.effect_time + FrameTime()
    end

    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), new_point, nil, 100, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

    for _,enemy in pairs( enemies ) do
        
        if self.effect_time >= 0.4 then
            local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_gush_splash.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
            ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
            ParticleManager:SetParticleControl(particle, 3, enemy:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(particle)
            self.effect_time = 0
        end
        local healing = (self:GetCaster():GetMaxMana() / 100 * heal) + base_heal
        enemy:Heal(healing * FrameTime(), self:GetAbility())
    end

    local direction2 = self.dummy:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()
    direction2.z = 0
    direction2 = direction2:Normalized()

    self:GetCaster():SetForwardVector(direction2)
end

function modifier_aghanim_water_ray:OnDestroy()
    if not IsServer() then return end
    self:GetParent():SwapAbilities("aghanim_water_ray_stop", "aghanim_water_ray", false, true)
    self:GetCaster():RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_3)
    if self.dummy and not self.dummy:IsNull() then
        self.dummy:RemoveModifierByName("modifier_mum_meat_hook_hook_thinker")
    end
    if self:GetAbility().nChannelFX then
        ParticleManager:DestroyParticle(self:GetAbility().nChannelFX, false)
    end
    if self.nBeamFXIndex then
        ParticleManager:DestroyParticle(self.nBeamFXIndex, false)
    end
    StopSoundOn( "Birzha.RayAgh", self:GetCaster() )
end

function modifier_aghanim_water_ray:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }
end

function modifier_aghanim_water_ray:CheckState()
    local state = 
    {
        [ MODIFIER_STATE_DISARMED ] = true,
        [ MODIFIER_STATE_ROOTED ] = true,
    }
    return state
end

function modifier_aghanim_water_ray:GetOverrideAnimation()
    return ACT_DOTA_CHANNEL_ABILITY_3
end

function modifier_aghanim_water_ray:GetModifierDisableTurning()
    return 1
end

function modifier_aghanim_water_ray:OnOrder( params )
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

        local stop_orders =
        {
            [DOTA_UNIT_ORDER_STOP] = true,
            [DOTA_UNIT_ORDER_HOLD_POSITION] = true,
            [DOTA_UNIT_ORDER_CONTINUE] = true,
            [DOTA_UNIT_ORDER_CAST_POSITION] = true,
            [DOTA_UNIT_ORDER_CAST_TARGET] = true,
            [DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
            [DOTA_UNIT_ORDER_HOLD_POSITION] = true,
        }

        if stop_orders[params.order_type] then
            self:Destroy()
            self:GetParent():Stop()
            return
        end

        if validMoveOrders[params.order_type] then
            local vTargetPos = params.new_pos
            if params.target ~= nil and params.target:IsNull() == false then
                vTargetPos = params.target:GetAbsOrigin()
            end

            local direction = vTargetPos - self:GetCaster():GetAbsOrigin()

            local distance = direction:Length2D()

            direction = direction:Normalized()

            if distance > self:GetAbility():GetSpecialValueFor("max_distance") then
                vTargetPos = self:GetCaster():GetAbsOrigin() + direction * self:GetAbility():GetSpecialValueFor("max_distance")
            end

            if distance < self:GetAbility():GetSpecialValueFor("min_distance") then
                vTargetPos = self:GetCaster():GetAbsOrigin() + direction * self:GetAbility():GetSpecialValueFor("min_distance")
            end

            self.point = vTargetPos
        end
    end
end

LinkLuaModifier("modifier_morphling_boss_tidal_wave_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_morphling_boss_tidal_wave_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_waves_storm = class({})

aghanim_waves_storm.Projectiles = {}
aghanim_waves_storm.Enemies = {}

function aghanim_waves_storm:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_morphling_boss_tidal_wave_buff", {})
end

modifier_morphling_boss_tidal_wave_buff = class({})

function modifier_morphling_boss_tidal_wave_buff:IsHidden()
    return true
end

function modifier_morphling_boss_tidal_wave_buff:IsPurgable()
    return false
end

function modifier_morphling_boss_tidal_wave_buff:GetActivityTranslationModifiers( params )
    return "channelling"
end

function modifier_morphling_boss_tidal_wave_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_EVENT_ON_ORDER
    }
end

function modifier_morphling_boss_tidal_wave_buff:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_6
end

function modifier_morphling_boss_tidal_wave_buff:GetModifierDisableTurning() 
    return 1
end 

function modifier_morphling_boss_tidal_wave_buff:CheckState() 
    return 
    {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_MUTED] = true,
    }
end

function modifier_morphling_boss_tidal_wave_buff:OnCreated( kv )
    if not IsServer() then return end
    self.direction_wave = self:GetCaster():GetForwardVector()
    self.projectile_speed = 1000
    self.projectile_radius = 180
    self.cast_range = 1500
    self.tick_interval = 1
    self.pulses = self:GetAbility():GetSpecialValueFor("count")
    self.pulse_width = 100
    self.bOffset = false
    self.nChannelFX = ParticleManager:CreateParticle( "particles/act_2/siltbreaker_channel.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    self:AddParticle(self.nChannelFX, false, false, -1, false, false)
    self:StartIntervalThink( 5 / self.pulses )

    local aghanim_bath_bubble = self:GetCaster():FindAbilityByName("aghanim_bath_bubble")
    if aghanim_bath_bubble then
        aghanim_bath_bubble:SetActivated(false)
    end
    local aghanim_puddle = self:GetCaster():FindAbilityByName("aghanim_puddle")
    if aghanim_puddle then
        aghanim_puddle:SetActivated(false)
    end
    local aghanim_water_ray = self:GetCaster():FindAbilityByName("aghanim_water_ray")
    if aghanim_water_ray then
        aghanim_water_ray:SetActivated(false)
    end
    local aghanim_water_ray_stop = self:GetCaster():FindAbilityByName("aghanim_water_ray_stop")
    if aghanim_water_ray_stop then
        aghanim_water_ray_stop:SetActivated(false)
    end
    local aghanim_bath_bubble_lop = self:GetCaster():FindAbilityByName("aghanim_bath_bubble_lop")
    if aghanim_bath_bubble_lop then
        aghanim_bath_bubble_lop:SetActivated(false)
    end
    local aghanim_waves_storm = self:GetCaster():FindAbilityByName("aghanim_waves_storm")
    if aghanim_waves_storm then
        aghanim_waves_storm:SetActivated(false)
    end
end

function modifier_morphling_boss_tidal_wave_buff:OnDestroy( kv )
    if not IsServer() then return end
    local aghanim_bath_bubble = self:GetCaster():FindAbilityByName("aghanim_bath_bubble")
    if aghanim_bath_bubble then
        aghanim_bath_bubble:SetActivated(true)
    end
    local aghanim_puddle = self:GetCaster():FindAbilityByName("aghanim_puddle")
    if aghanim_puddle then
        aghanim_puddle:SetActivated(true)
    end
    local aghanim_water_ray = self:GetCaster():FindAbilityByName("aghanim_water_ray")
    if aghanim_water_ray then
        aghanim_water_ray:SetActivated(true)
    end
    local aghanim_water_ray_stop = self:GetCaster():FindAbilityByName("aghanim_water_ray_stop")
    if aghanim_water_ray_stop then
        aghanim_water_ray_stop:SetActivated(true)
    end
    local aghanim_bath_bubble_lop = self:GetCaster():FindAbilityByName("aghanim_bath_bubble_lop")
    if aghanim_bath_bubble_lop then
        aghanim_bath_bubble_lop:SetActivated(true)
    end
    local aghanim_waves_storm = self:GetCaster():FindAbilityByName("aghanim_waves_storm")
    if aghanim_waves_storm then
        aghanim_waves_storm:SetActivated(true)
    end

    self:GetCaster():RemoveModifierByName("modifier_morphling_boss_tidal_wave_buff")

    local modifier_aghanim_change_style_main_bath = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_bath")
    if modifier_aghanim_change_style_main_bath then
        modifier_aghanim_change_style_main_bath.cooldown = #self:GetAbility().Enemies
    end

    self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_remove_aghanim_styles_add", {duration = 0.5})
    
    self:GetAbility().Enemies = {}
end

function modifier_morphling_boss_tidal_wave_buff:OnIntervalThink()
    if not IsServer() then return end
    local angle = QAngle( 0, 0, 0 )
    local nOffset = 0

    if self.pulses <= 0 then
        self:Destroy()
        self:GetCaster():Interrupt() 
        return 
    end

    if self:GetParent():IsStunned() or self:GetParent():IsSilenced() then
        self:Destroy()
        self:GetCaster():Interrupt() 
        return 
    end

    self.pulses = self.pulses - 1

    local info = 
    {
        EffectName = "particles/units/heroes/hero_tidehunter/tidehunter_gush_upgrade.vpcf", 
        Ability = self:GetAbility(),
        vSpawnOrigin = self:GetCaster():GetOrigin(), 
        fStartRadius = self.projectile_radius,
        fEndRadius = self.projectile_radius,
        fDistance = self.cast_range,
        Source = self:GetCaster(),
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO,
        vVelocity = self.direction_wave * self.projectile_speed,
        bProvidesVision = true,
        iVisionRadius = self.projectile_radius,
        iVisionTeamNumber = self:GetParent():GetTeamNumber(),
    }

    local proj = {}
    proj.handle = ProjectileManager:CreateLinearProjectile( info )
    table.insert( self:GetAbility().Projectiles, proj )
    self:GetCaster():EmitSound("Ability.GushCast")
end

function aghanim_waves_storm:OnProjectileHitHandle( hTarget, vLocation, nProjectileHandle )
    if not IsServer() then return end

    if hTarget ~= nil and hTarget ~= self:GetCaster() then
        local projectile_radius = 100

        local damage = self:GetSpecialValueFor("damage")
        local heal = self:GetSpecialValueFor("heal")
        local base_num = self:GetSpecialValueFor("base_num")

        if hTarget:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
            local damageInfo =
            {
                victim = hTarget,
                attacker = self:GetCaster(),
                damage = (damage / 100 * hTarget:GetMaxHealth()) + base_num,
                damage_type = DAMAGE_TYPE_PURE,
                ability = self,
            }
            ApplyDamage( damageInfo )

            local modifier_morphling_boss_tidal_wave_debuff = hTarget:AddNewModifier(self:GetCaster(), self, "modifier_morphling_boss_tidal_wave_debuff", {duration = self:GetSpecialValueFor("duration")})
            modifier_morphling_boss_tidal_wave_debuff:SetStackCount(modifier_morphling_boss_tidal_wave_debuff:GetStackCount() + 1)

            if self.Enemies[hTarget:entindex()] == nil then
                self.Enemies[hTarget:entindex()] = true
            end
        else
            hTarget:Heal((hTarget:GetMaxHealth() / 100 * heal) + base_num, self)
        end

        local dir = hTarget:GetAbsOrigin() - vLocation
        dir.z = 0
        dir = dir:Normalized()

        local knockback = hTarget:AddNewModifier(
        self:GetCaster(),
            nil,
            "modifier_generic_knockback_lua",
            {
                direction_x = dir.x,
                direction_y = dir.y,
                distance = 50,
                height = 0,
                duration = 0.2,
            }
        )

        hTarget:EmitSound("Ability.GushImpact")
    end

    local projectile = nil
    for _, proj in pairs( self.Projectiles ) do
        if proj ~= nil and proj.handle == nProjectileHandle then
            projectile = proj
        end
    end

    return false
end

function modifier_morphling_boss_tidal_wave_buff:OnOrder( params )
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

            local direction = vTargetPos - self:GetCaster():GetAbsOrigin()
            direction.z = 0
            local distance = direction:Length2D()
            direction = direction:Normalized()

            self.direction_wave = direction
        end
    end
end





















modifier_morphling_boss_tidal_wave_debuff = class({})

function modifier_morphling_boss_tidal_wave_debuff:GetTexture()
    return "aghanim_waves_storm"
end

function modifier_morphling_boss_tidal_wave_debuff:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_morphling_boss_tidal_wave_debuff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_morphling_boss_tidal_wave_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow * self:GetStackCount()
end

LinkLuaModifier("modifier_aghanim_mad_wrench", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mad_wrench_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mad_wrench_pull", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_BOTH )

aghanim_mad_wrench = class({})

function aghanim_mad_wrench:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts", context )
end

function aghanim_mad_wrench:OnSpellStart()
    if not IsServer() then return end
    local point = self:GetCursorPosition()
    local distance = self:GetSpecialValueFor("range")
    local spawnPos = self:GetCaster():GetOrigin()

    local direction = point-self:GetCaster():GetAbsOrigin()
    direction.z = 0
    direction = direction:Normalized()

    local info = 
    {
        Source = self:GetCaster(),
        Ability = self,
        vSpawnOrigin = self:GetCaster():GetAttachmentOrigin(self:GetCaster():ScriptLookupAttachment("attach_staff_fx")),
        bDeleteOnHit = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        EffectName = "particles/dddd_chain.vpcf",
        fDistance = distance,
        fStartRadius = 100,
        fEndRadius = 100,
        vVelocity = direction * 1200,
        iSourceAttachment   = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bProvidesVision = false,
        ExtraData = {}
    }

    self:GetCaster():EmitSound("Birzha.EmberChain")

    ProjectileManager:CreateLinearProjectile(info)
end

function aghanim_mad_wrench:OnProjectileHit_ExtraData(target, vLocation, table)
    if target ~= nil then
        target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mad_wrench", {duration = self:GetSpecialValueFor("duration")})
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mad_wrench_buff", {duration = self:GetSpecialValueFor("duration"), target = target:entindex()})
        return true
    end
end

aghanim_mad_wrench_buff = class({})

function aghanim_mad_wrench_buff:GetTexture() return "aghanim_wrench" end

function aghanim_mad_wrench_buff:OnSpellStart()
    if not IsServer() then return end
    print("лалала")
    local modifier_aghanim_mad_wrench_buff = self:GetCaster():FindModifierByName("modifier_aghanim_mad_wrench_buff")
    if modifier_aghanim_mad_wrench_buff then
        print("дадада")
        modifier_aghanim_mad_wrench_buff.use = true
        modifier_aghanim_mad_wrench_buff:Destroy()
    end
end

modifier_aghanim_mad_wrench_buff = class({})

function modifier_aghanim_mad_wrench_buff:IsPurgeException() return false end
function modifier_aghanim_mad_wrench_buff:IsPurgable() return false end
function modifier_aghanim_mad_wrench_buff:IsHidden() return true end

function modifier_aghanim_mad_wrench_buff:OnCreated(params)
    if not IsServer() then return end
    self.target = EntIndexToHScript(params.target)
    self.use = false
    self:GetParent():SwapAbilities("aghanim_mad_wrench", "aghanim_mad_wrench_buff", false, true)
end

function modifier_aghanim_mad_wrench_buff:OnDestroy()
    if not IsServer() then return end
    print("нет нет нет")
    if not self:GetParent():HasModifier("modifier_aghanim_change_style_main_mad") then return end
    print("asasas")
    self:GetParent():SwapAbilities("aghanim_mad_wrench_buff", "aghanim_mad_wrench", false, true)

    local aghanim_mad_wrench = self:GetCaster():FindAbilityByName("aghanim_mad_wrench")
    if aghanim_mad_wrench then
        aghanim_mad_wrench:EndCooldown()
        aghanim_mad_wrench:UseResources(false, false, false, true)
    end

    if self.use then
        self.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mad_wrench_pull", {duration = 0.5, target = self:GetCaster():entindex()})
        self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mad_wrench_pull", {duration = 0.5, target = self.target:entindex()})
    end
end

modifier_aghanim_mad_wrench_pull = class({})

function modifier_aghanim_mad_wrench_pull:IsHidden() return true end
function modifier_aghanim_mad_wrench_pull:GetTexture() return "aghanim_wrench" end

function modifier_aghanim_mad_wrench_pull:OnCreated(params)
    if not IsServer() then return end

    self.target = EntIndexToHScript(params.target)

    self:GetParent():EmitSound("Birzha.LichChain")

    local effect_cast = ParticleManager:CreateParticle( "particles/aghanim_wrength_chainpair.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target )
    ParticleManager:SetParticleControlEnt( effect_cast, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( 1.25, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    local distance = self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()
    distance = distance:Length2D() / 3

    self.pull_units_per_second = distance / 0.5

    if self:ApplyHorizontalMotionController() == false then 
        self:Destroy()
        return
    end
end

function modifier_aghanim_mad_wrench_pull:UpdateHorizontalMotion( me, dt )
    if not IsServer() then return end
    local distance = self.target:GetOrigin() - me:GetOrigin()

    if distance:Length2D() > 60 then
        me:SetOrigin( me:GetOrigin() + distance:Normalized() * self.pull_units_per_second * dt )
    else
        self:Destroy()
    end
end

function modifier_aghanim_mad_wrench_pull:OnDestroy()
    if not IsServer() then return end
    self:GetParent():StopSound("Birzha.LichChain")
    self:GetParent():RemoveHorizontalMotionController( self )
end

modifier_aghanim_mad_wrench = class({})

function modifier_aghanim_mad_wrench:GetTexture() return "aghanim_wrench" end

function modifier_aghanim_mad_wrench:OnCreated()
    if not IsServer() then return end
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    local effect_cast = ParticleManager:CreateParticle( "particles/aghanim_wrength_chainpair.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt( effect_cast, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( self:GetDuration(), 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )
    self:StartIntervalThink(0.5)
end

function modifier_aghanim_mad_wrench:OnIntervalThink()
    if not IsServer() then return end
    ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
end

function modifier_aghanim_mad_wrench:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
    }
end

function modifier_aghanim_mad_wrench:OnDestroy()
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_aghanim_mad_wrench_buff")
end

LinkLuaModifier("modifier_aghanim_chain", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_chain_pull", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_BOTH )

aghanim_chain = class({})

function aghanim_chain:OnSpellStart()
    if not IsServer() then return end
    local target = self:GetCursorTarget()
    if target:TriggerSpellAbsorb(self) then self:GetCaster():Interrupt() return end
    self.target = target
    self:GetCaster():EmitSound("Birzha.LichChain")
    target:EmitSound("Birzha.LichChain")
    target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_chain", {duration = self:GetChannelTime() })
end

function aghanim_chain:OnChannelFinish(bInterrupted)

    if self.target then
        local target_buff = self.target:FindModifierByName("modifier_aghanim_chain")
        if target_buff then
            target_buff:Destroy()
        end
    end

    if bInterrupted then return end
end

modifier_aghanim_chain = class({})

function modifier_aghanim_chain:GetTexture() return "aghanim_chain" end

function modifier_aghanim_chain:IsDebuff() return true end

function modifier_aghanim_chain:OnCreated()
    if not IsServer() then return end
    self.damage = self:GetAbility():GetSpecialValueFor("damage") / self:GetAbility():GetChannelTime()

    self.hook_particle = ParticleManager:CreateParticle( "particles/aghanim_new_chain.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleAlwaysSimulate( self.hook_particle )
    ParticleManager:SetParticleControlEnt( self.hook_particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_chain", self:GetCaster():GetOrigin() + Vector( 0, 0, 96 ), true )
    self:AddParticle(self.hook_particle, false, false, -1, false, false)

    self.start_damage = false
    self.dmg_interval = 1
    self.anim_interval = 0

    self.dist_anim = (self:GetAbility().target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D()

    self.dist_anim_2 = 0

    local dir = self:GetAbility().target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()
    self.dir = dir:Normalized()

    self:StartIntervalThink(FrameTime())
    self:OnIntervalThink()
end

function modifier_aghanim_chain:OnIntervalThink()
    if not IsServer() then return end

    if self.start_damage then
        self.dmg_interval = self.dmg_interval + FrameTime()
        if self.dmg_interval >= 1 then
            ApplyDamage({attacker = self:GetCaster(), victim = self:GetAbility().target, ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
            self.dmg_interval = 0
        end
    else
        self.anim_interval = self.anim_interval + FrameTime()
        if self.anim_interval >= 0.2 then
            self.start_damage = true
            self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_chain_pull", {duration = self:GetAbility():GetChannelTime()})
            ParticleManager:SetParticleControlEnt( self.hook_particle, 1, self:GetAbility().target, PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetAbility().target:GetOrigin() + Vector( 0, 0, 96 ), true )
        end

        if self.dist_anim_2 >= self.dist_anim then
            self.dist_anim_2 = self.dist_anim
        else
            self.dist_anim_2 = self.dist_anim_2 + (self.dist_anim / 0.2 * FrameTime())
        end

        ParticleManager:SetParticleControl(self.hook_particle, PATTACH_ABSORIGIN_FOLLOW, (self:GetCaster():GetAbsOrigin() + self.dir * self.dist_anim_2) + Vector( 0, 0, 150 ) )
    end
end

function modifier_aghanim_chain:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveModifierByName("modifier_aghanim_chain_pull")
    if self:GetCaster():IsChanneling() then
        self:GetAbility():EndChannel(false)
        self:GetCaster():MoveToPositionAggressive(self:GetParent():GetAbsOrigin())
    end
end

modifier_aghanim_chain_pull = class({})

function modifier_aghanim_chain_pull:IsHidden() return true end

function modifier_aghanim_chain_pull:OnCreated(params)
    if not IsServer() then return end

    self.pull_units_per_second = self:GetAbility():GetSpecialValueFor("range") / self:GetAbility():GetSpecialValueFor("duration")

    local distance = self:GetCaster():GetAbsOrigin() - self:GetParent():GetAbsOrigin()
    distance.z = 0

    if self:ApplyHorizontalMotionController() == false then 
        self:Destroy()
        return
    end
end

function modifier_aghanim_chain_pull:UpdateHorizontalMotion( me, dt )
    if not IsServer() then return end
    local distance = self:GetCaster():GetOrigin() - me:GetOrigin()

    if distance:Length2D() > 60 then
        me:SetOrigin( me:GetOrigin() + distance:Normalized() * self.pull_units_per_second * dt )
    else
        self:Destroy()
    end
end

function modifier_aghanim_chain_pull:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveHorizontalMotionController( self )
end

function modifier_aghanim_chain_pull:CheckState()
    return 
    {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_aghanim_chain_pull:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_aghanim_chain_pull:GetOverrideAnimation()
    return ACT_DOTA_FLAIL
end

LinkLuaModifier("modifier_aghanim_mad_siled", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_mad_siled_fear", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_mad_siled = class({})

function aghanim_mad_siled:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mad_siled", {duration = self:GetSpecialValueFor("duration")})
    self:GetCaster():EmitSound("Birzha.Ostrie")
end

modifier_aghanim_mad_siled = class({})

function modifier_aghanim_mad_siled:GetTexture() return "aghanim_siled" end

function modifier_aghanim_mad_siled:OnCreated()
    self.dmg = self:GetAbility():GetSpecialValueFor("damage_return")
    self.dur = self:GetAbility():GetSpecialValueFor("duration")
    self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
    local particle = ParticleManager:CreateParticle("particles/aghanim_hedhehohg.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    self:AddParticle(particle, false, false, -1, false, false)
end

function modifier_aghanim_mad_siled:OnDestroy()

end

function modifier_aghanim_mad_siled:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_mad_siled:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed
end

function modifier_aghanim_mad_siled:OnTakeDamage(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if params.attacker == self:GetParent() then return end
    if params.attacker:IsMagicImmune() then return end
    params.attacker:EmitSound("Birzha.OstrieFear")
    params.attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_mad_siled_fear", {duration = self.dur, x = self:GetCaster():GetAbsOrigin().x, y = self:GetCaster():GetAbsOrigin().y})
    local attacker = params.attacker
    local target = params.unit
    local original_damage = params.original_damage
    local damage_type = params.damage_type
    local damage_flags = params.damage_flags
    if params.unit == self:GetParent() and not params.attacker:IsBuilding() and params.attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= DOTA_DAMAGE_FLAG_HPLOSS and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then  
        EmitSoundOnClient("DOTA_Item.BladeMail.Damage", params.attacker:GetPlayerOwner())
        ApplyDamage({ victim = params.attacker, damage = params.original_damage / 100 * self.dmg, damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, attacker = self:GetParent(), ability = self:GetAbility() })
    end
end

modifier_aghanim_mad_siled_fear = class({})

function modifier_aghanim_mad_siled_fear:GetTexture() return "aghanim_siled" end

function modifier_aghanim_mad_siled_fear:OnCreated(data)
    if not IsServer() then return end

    local vector = Vector(data.x, data.y, 0)

    local pos = (self:GetParent():GetAbsOrigin() - vector)
    pos.z = 0
    pos = pos:Normalized()

    self.position = self:GetParent():GetAbsOrigin() + pos * 500

    if not self:GetParent():IsHero() then
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_disarmed", {duration = 0.1})
        self:GetParent():SetAggroTarget(nil)
    end

    self:GetParent():MoveToPosition( self.position )
end

function modifier_aghanim_mad_siled_fear:OnIntervalThink()
    if not IsServer() then return end
    self:GetParent():MoveToPosition( self.position )
end

function modifier_aghanim_mad_siled_fear:GetEffectName()
    return "particles/units/heroes/hero_muerta/muerta_spell_fear_debuff.vpcf"
end

function modifier_aghanim_mad_siled_fear:StatusEffectPriority()
    return 10
end

function modifier_aghanim_mad_siled_fear:GetStatusEffectName()
    return "particles/units/heroes/hero_muerta/muerta_spell_fear_debuff_status.vpcf"
end

function modifier_aghanim_mad_siled_fear:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_aghanim_mad_siled_fear:CheckState()
    local state = 
    {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_FEARED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = true,
    }
    return state
end

function modifier_aghanim_mad_siled_fear:OnDestroy()
    if not IsServer() then return end
    self:GetParent():Stop()
end

LinkLuaModifier("modifier_aghanim_mad_chains_rooted", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_mad_chains = class({})

function aghanim_mad_chains:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function aghanim_mad_chains:OnSpellStart()
    if not IsServer() then return end

    local stun_duration = self:GetSpecialValueFor("stun_duration")
    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")
    local tick_damage = self:GetSpecialValueFor("tick_damage")
    local tick_mana = self:GetSpecialValueFor("tick_mana")

    local point = self:GetCaster():GetAbsOrigin()

    local effect_cast = ParticleManager:CreateParticle( "particles/aghanim_lesh_tormented.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, point )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )
    EmitSoundOnLocationWithCaster( point, "Hero_Leshrac.Split_Earth", self:GetCaster() )

    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), point, self:GetCaster(), radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )

    for _,enemy in pairs( enemies ) do
        ApplyDamage({attacker = self:GetCaster(), victim = enemy, ability = self, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
        enemy:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = stun_duration * (1 - enemy:GetStatusResistance())})
        enemy:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_mad_chains_rooted", {duration = duration})
    end

    -- if IsInToolsMode() then return end



    local modifier_aghanim_change_style_main_mad = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_mad")
    if modifier_aghanim_change_style_main_mad then
        modifier_aghanim_change_style_main_mad.cooldown = #enemies
    end

    self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_remove_aghanim_styles_add", {duration = 0.5})
end

modifier_aghanim_mad_chains_rooted = class({})

function modifier_aghanim_mad_chains_rooted:GetTexture() return "aghanim_chains" end

function modifier_aghanim_mad_chains_rooted:IsPurgable() return false end
function modifier_aghanim_mad_chains_rooted:IsPurgeException() return false end

function modifier_aghanim_mad_chains_rooted:OnCreated()
    if not IsServer() then return end
    self.tick_damage = self:GetAbility():GetSpecialValueFor("tick_damage")
    self.tick_mana = self:GetAbility():GetSpecialValueFor("tick_mana")
    self:StartIntervalThink(0.7)
end

function modifier_aghanim_mad_chains_rooted:OnIntervalThink()
    if not IsServer() then return end
    local damage = self.tick_damage + (self:GetCaster():GetMaxMana() / 100 * self.tick_mana)
    ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
end


LinkLuaModifier("modifier_aghanim_smith_mech", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_smith_mech_mini", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_smith_mech_boom", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_smith_mech = class({})

function aghanim_smith_mech:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts", context )
end

function aghanim_smith_mech:OnSpellStart()
    if not IsServer() then return end
    local point = self:GetCursorPosition()
    local distance = self:GetSpecialValueFor("distance")
    local spawnPos = self:GetCaster():GetOrigin()

    local direction = point-self:GetCaster():GetAbsOrigin()
    direction.z = 0
    direction = direction:Normalized()

    local info = 
    {
        Source = self:GetCaster(),
        Ability = self,
        vSpawnOrigin = self:GetCaster():GetAttachmentOrigin(self:GetCaster():ScriptLookupAttachment("attach_staff_fx")),
        bDeleteOnHit = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        EffectName = "particles/shard/tinker_mech.vpcf",
        fDistance = distance,
        fStartRadius = 100,
        fEndRadius = 100,
        vVelocity = direction * 1200,
        iSourceAttachment   = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bProvidesVision = false,
        ExtraData = {main = 1}
    }

    self:GetCaster():EmitSound("Birzha.MarchTin")

    ProjectileManager:CreateLinearProjectile(info)
end

function aghanim_smith_mech:OnProjectileHit_ExtraData(target, vLocation, table)

    if target == nil then
        EmitSoundOnLocationWithCaster(vLocation, "Birzha.BrokenMach", self:GetCaster())
        local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), vLocation, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
        for _,enemy in pairs( enemies ) do
            ApplyDamage({attacker = self:GetCaster(), victim = enemy, ability = self, damage = self:GetSpecialValueFor("damage_b"), damage_type = DAMAGE_TYPE_MAGICAL})
        end
    end

    if target ~= nil then
        if table.main == 1 then
            local point = GetGroundPosition(vLocation, nil)
            local dummy = CreateUnitByName( "npc_dota_companion", target:GetAbsOrigin(), false, nil, nil, self:GetCaster():GetTeamNumber() )
            dummy:SetAbsOrigin(target:GetAbsOrigin())
            dummy:AddNewModifier(dummy, self, "modifier_mum_meat_hook_hook_thinker", {duration = 1})
            local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

            target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_smith_mech_boom", {duration = 3.01, type = "big"})

            target:EmitSound("Birzha.MechAttack")

            for _,enemy in pairs( enemies ) do
                if enemy ~= target then
                    local info = 
                    {
                        Target = enemy,
                        Source = dummy,
                        Ability = self, 
                        EffectName = "particles/aghs_mech_tr.vpcf",
                        iMoveSpeed = 800,
                        bReplaceExisting = false,
                        bProvidesVision = true,
                        iVisionRadius = 25,
                        iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
                        ExtraData = {main = 0}
                    }

                    ProjectileManager:CreateTrackingProjectile(info)
                end
            end
        end

        if table.main == 0 then
            target:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_smith_mech_boom", {duration = 3.01, type = "mini"})
        end

        return true
    end
end

modifier_aghanim_smith_mech_boom = class({})

function modifier_aghanim_smith_mech_boom:IsHidden() return true end
function modifier_aghanim_smith_mech_boom:IsPurgeException() return false end
function modifier_aghanim_smith_mech_boom:IsPurgable() return false end

function modifier_aghanim_smith_mech_boom:OnCreated(params)
    if not IsServer() then return end
    self.type = params.type
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
    self.bonus_duration = self:GetAbility():GetSpecialValueFor("bonus_duration")
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.damage_b = self:GetAbility():GetSpecialValueFor("damage_b")
    self:StartIntervalThink(1)
    self.timer = 3
    self.particle = ParticleManager:CreateParticle("particles/aghanim_timerbuff_strength.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.particle, 2, Vector(self.timer, 0, 0))
    ParticleManager:SetParticleControlEnt(self.particle, 3, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, nil , self:GetParent():GetAbsOrigin(), true )
    self:AddParticle(self.particle, false, false, -1, false, true)
end

function modifier_aghanim_smith_mech_boom:OnIntervalThink()
    if not IsServer() then return end
    self.timer = self.timer - 1
    ParticleManager:SetParticleControl(self.particle, 2, Vector(self.timer, 0, 0))
end

function modifier_aghanim_smith_mech_boom:OnDestroy()
    if not IsServer() then return end
    if self.type == "mini" then
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_smith_mech_mini", {duration = self.bonus_duration * (1-self:GetParent():GetStatusResistance())})
        ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.damage_b, damage_type = DAMAGE_TYPE_MAGICAL})
    else
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_aghanim_smith_mech", {duration = self.duration * (1-self:GetParent():GetStatusResistance())})
        ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
    end
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_remote_cart_explode.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    self:GetParent():EmitSound("Hero_Techies.RemoteMine.Detonate")
end

modifier_aghanim_smith_mech = class({})

function modifier_aghanim_smith_mech:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")
    if not IsServer() then return end
    self.cast_anim = self:GetAbility():GetSpecialValueFor("cast_anim")
    local aghs_cast_range_debuff = ParticleManager:CreateParticle("particles/aghs_cast_range_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(aghs_cast_range_debuff, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(aghs_cast_range_debuff, 1, Vector(255,255,255))
    self:AddParticle(aghs_cast_range_debuff, false, false, -1, false, false)
end

function modifier_aghanim_smith_mech:GetTexture() return "aghanim_mech" end

function modifier_aghanim_smith_mech:DeclareFunctions()
    local funcs = 
    {
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
    return funcs
end

function modifier_aghanim_smith_mech:GetModifierPercentageCasttime()
    return self.cast_anim
end

function modifier_aghanim_smith_mech:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

modifier_aghanim_smith_mech_mini = class({})

function modifier_aghanim_smith_mech_mini:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")
    if not IsServer() then return end
    self.cast_anim = self:GetAbility():GetSpecialValueFor("cast_anim_b")
    local aghs_cast_range_debuff = ParticleManager:CreateParticle("particles/aghs_cast_range_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(aghs_cast_range_debuff, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(aghs_cast_range_debuff, 1, Vector(255,255,255))
    self:AddParticle(aghs_cast_range_debuff, false, false, -1, false, false)
end

function modifier_aghanim_smith_mech_mini:DeclareFunctions()
    local funcs = 
    {
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
    return funcs
end

function modifier_aghanim_smith_mech_mini:GetModifierPercentageCasttime()
    return self.cast_anim
end

function modifier_aghanim_smith_mech_mini:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

LinkLuaModifier("modifier_aghanim_smith_jetpack", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_smith_jetpack = class({})

function aghanim_smith_jetpack:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_smith_jetpack", {duration = self:GetSpecialValueFor("duration")})

    local vDirection = self:GetCaster():GetForwardVector()
    vDirection.z = 0.0
    vDirection = vDirection:Normalized()
    local vTargetPos = self:GetCaster():GetAbsOrigin() + vDirection

    local kv =
    {
        duration = self:GetSpecialValueFor( "duration" ),
        vTargetX = vTargetPos.x,
        vTargetY = vTargetPos.y,
        vTargetZ = vTargetPos.z,
    }
    self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_rattletrap_jetpack", kv )
end

modifier_aghanim_smith_jetpack = class({})

function modifier_aghanim_smith_jetpack:IsPurgable() return false end
function modifier_aghanim_smith_jetpack:IsHidden() return true end

function modifier_aghanim_smith_jetpack:OnDestroy()
    if not IsServer() then return end

    local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), self:GetCaster(), self:GetAbility():GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )

    for _,enemy in pairs( enemies ) do
        local damage = self:GetAbility():GetSpecialValueFor("damage")
        ApplyDamage({attacker = self:GetCaster(), victim = enemy, ability = self, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
    end
end

LinkLuaModifier("modifier_aghanim_smith_crange", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_smith_crange_aura", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier("modifier_aghanim_smith_crange_buff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_smith_crange_buff_aura", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_smith_crange = class({})

function aghanim_smith_crange:GetIntrinsicModifierName()
    return "modifier_aghanim_smith_crange"
end

function aghanim_smith_crange:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():EmitSound("Birzha.TinkerPortal")
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_aghanim_smith_crange_buff", {})
end

function aghanim_smith_crange:OnChannelFinish(bInterrupted)
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_aghanim_smith_crange_buff")
end

modifier_aghanim_smith_crange = class({})

function modifier_aghanim_smith_crange:IsHidden() return true end

function modifier_aghanim_smith_crange:IsAura()
    return true
end

function modifier_aghanim_smith_crange:GetModifierAura()
    return "modifier_aghanim_smith_crange_aura"
end

function modifier_aghanim_smith_crange:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_aghanim_smith_crange:GetAuraDuration()
    return 0
end

function modifier_aghanim_smith_crange:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_aghanim_smith_crange:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_aghanim_smith_crange:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

modifier_aghanim_smith_crange_aura = class({})

function modifier_aghanim_smith_crange_aura:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING
    }
end

function modifier_aghanim_smith_crange_aura:GetModifierCastRangeBonusStacking()
    return self:GetAbility():GetSpecialValueFor("cast_range")
end

function modifier_aghanim_smith_crange_aura:GetTexture() return "aghanim_crange" end


modifier_aghanim_smith_crange_buff = class({})

function modifier_aghanim_smith_crange_buff:OnCreated()
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/aghanim_cooldown.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(self:GetAbility():GetSpecialValueFor("radius"), self:GetAbility():GetSpecialValueFor("radius"), self:GetAbility():GetSpecialValueFor("radius")))
    self:AddParticle(particle, false, false, -1, false, false)
end

function modifier_aghanim_smith_crange_buff:IsHidden() return true end

function modifier_aghanim_smith_crange_buff:DeclareFunctions()
    return 
    {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }
end

function modifier_aghanim_smith_crange_buff:GetOverrideAnimation()
    return ACT_DOTA_CHANNEL_ABILITY_3
end

function modifier_aghanim_smith_crange_buff:IsAura()
    return true
end

function modifier_aghanim_smith_crange_buff:GetModifierAura()
    return "modifier_aghanim_smith_crange_buff_aura"
end

function modifier_aghanim_smith_crange_buff:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_aghanim_smith_crange_buff:GetAuraDuration()
    return 0
end

function modifier_aghanim_smith_crange_buff:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_aghanim_smith_crange_buff:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_aghanim_smith_crange_buff:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

modifier_aghanim_smith_crange_buff_aura = class({})

function modifier_aghanim_smith_crange_buff_aura:GetTexture() return "aghanim_crange" end

function modifier_aghanim_smith_crange_buff_aura:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
    self.part = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_overcharge.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt( self.part, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true )
    self:AddParticle(self.part, false, false, -1, false, false)
end

function modifier_aghanim_smith_crange_buff_aura:OnIntervalThink()
    if not IsServer() then return end
    for i = 1, 30 do
        local hAbility = self:GetParent():GetAbilityByIndex(i - 1)
        if hAbility and hAbility.GetCooldownTimeRemaining then
            local flRemaining = hAbility:GetCooldownTimeRemaining()
            if 0.3 < flRemaining then
                if hAbility and hAbility:GetAbilityName() ~= "aghanim_smith_crange" then
                    hAbility:EndCooldown()
                    hAbility:StartCooldown(flRemaining-0.3)
                end
            end
        end
    end
    for i = 0, 6 do
        local hAbility = self:GetParent():GetItemInSlot(i)
        if hAbility and hAbility.GetCooldownTimeRemaining then
            local flRemaining = hAbility:GetCooldownTimeRemaining()
            if 0.3 < flRemaining then
                if hAbility and hAbility:GetAbilityName() ~= "aghanim_smith_crange" then
                    hAbility:EndCooldown()
                    hAbility:StartCooldown(flRemaining-0.3)
                end
            end
        end
    end
end

function modifier_aghanim_smith_crange_buff_aura:OnDestroy()
    if not IsServer() then return end
    if self.part then
        ParticleManager:DestroyParticle(self.part, true)
    end
end

LinkLuaModifier("modifier_aghanim_smith_bomb_debuff", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aghanim_smith_bomb_silenced", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

aghanim_smith_bomb = class({})

function aghanim_smith_bomb:OnSpellStart()
    if not IsServer() then return end

    self:SetActivated(false)

    local point = self:GetCursorPosition()

    self:GetCaster():EmitSound("Birzha.BombStart")

    local dummy = CreateUnitByName( "npc_dota_companion", self:GetCaster():GetAbsOrigin(), false, nil, nil, self:GetCaster():GetTeamNumber() )
    dummy:SetModel("models/heroes/techies/fx_techies_remotebomb_underhollow.vmdl")
    dummy:SetOriginalModel("models/heroes/techies/fx_techies_remotebomb_underhollow.vmdl")
    dummy:SetModelScale(1)

    local distance_teleport = (point - self:GetCaster():GetAbsOrigin()):Length2D()
    local direciton = (point - self:GetCaster():GetAbsOrigin())
    direciton.z = 0
    direciton = direciton:Normalized()

    local knockback = dummy:AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_generic_knockback_lua",
        {
            direction_x = direciton.x,
            direction_y = direciton.y,
            distance = distance_teleport,
            height = 250,
            duration = self:GetSpecialValueFor("fly_duration"),
        }
    )

    local callback = function( bInterrupted )
        local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), dummy:GetAbsOrigin(), self:GetCaster(), self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
        for _,enemy in pairs( enemies ) do
            enemy:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_smith_bomb_silenced", {duration = self:GetSpecialValueFor("silence_duration")})
            enemy:AddNewModifier(self:GetCaster(), self, "modifier_aghanim_smith_bomb_debuff", {duration = self:GetSpecialValueFor("slow_cd")})
            ApplyDamage({attacker = self:GetCaster(), victim = enemy, ability = self, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_PHYSICAL})
        end
        local particle_explosion_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(particle_explosion_fx, 0, dummy:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle_explosion_fx, 1, dummy:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle_explosion_fx, 2, Vector(self:GetSpecialValueFor("radius"), 1, 1))
        ParticleManager:ReleaseParticleIndex(particle_explosion_fx)

        EmitSoundOnLocationWithCaster(dummy:GetAbsOrigin(), "Birzha.MineBomb", self:GetCaster())

        UTIL_Remove(dummy)

        self:SetActivated(true)

        local modifier_aghanim_change_style_main_smith = self:GetCaster():FindModifierByName("modifier_aghanim_change_style_main_smith")
        if modifier_aghanim_change_style_main_smith then
            modifier_aghanim_change_style_main_smith.cooldown = #enemies
        end

        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_remove_aghanim_styles_add", {duration = 0.5})
    end

    knockback:SetEndCallback( callback )

    dummy:AddNewModifier(dummy, self, "modifier_mum_meat_hook_hook_thinker", {})
end

modifier_aghanim_smith_bomb_debuff = class({})

function modifier_aghanim_smith_bomb_debuff:GetTexture() return "aghanim_bomb" end

function modifier_aghanim_smith_bomb_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_aghanim_smith_bomb_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -30
end

modifier_aghanim_smith_bomb_silenced = class({})

function modifier_aghanim_smith_bomb_silenced:GetTexture() return "aghanim_bomb" end

function modifier_aghanim_smith_bomb_silenced:GetEffectName()
    return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_aghanim_smith_bomb_silenced:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_aghanim_smith_bomb_silenced:CheckState()
    return 
    {
        [MODIFIER_STATE_SILENCED] = true
    }
end

LinkLuaModifier( "modifier_aghanim_icon", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE )

modifier_invoker_old_beta_invoke_attack = class({})

function modifier_invoker_old_beta_invoke_attack:IsHidden() return true end
function modifier_invoker_old_beta_invoke_attack:IsPurgable() return false end
function modifier_invoker_old_beta_invoke_attack:IsPurgeException() return false end
function modifier_invoker_old_beta_invoke_attack:RemoveOnDeath() return false end

function modifier_invoker_old_beta_invoke_attack:OnCreated()
    if not IsServer() then return end
    self.icon = CreateUnitByName("npc_dota_aghanim_icon", self:GetParent():GetAbsOrigin(), false, nil, nil, self:GetParent():GetTeamNumber())
    self.icon:AddNewModifier(self:GetParent(), nil, "modifier_aghanim_icon", {})
    self:StartIntervalThink(FrameTime())
end

function modifier_invoker_old_beta_invoke_attack:OnIntervalThink()
    if not IsServer() then return end

    self.icon:SetAbsOrigin(self:GetParent():GetAbsOrigin())

    if not self:GetParent():IsAlive() and self:GetParent():IsIllusion() then
        self.icon:Destroy()
        self:Destroy()
    end
end

function modifier_invoker_old_beta_invoke_attack:CheckState()
    return {
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    }
end

modifier_aghanim_icon = class({})

function modifier_aghanim_icon:IsPurgable() return false end
function modifier_aghanim_icon:IsPurgeException() return false end
function modifier_aghanim_icon:IsHidden() return true end

function modifier_aghanim_icon:CheckState()
    return {
        [MODIFIER_STATE_NOT_ON_MINIMAP] = not self:GetCaster():IsAlive(),
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_INVISIBLE] = self:GetCaster():IsInvisible(),
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    }
end

function modifier_aghanim_icon:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }

    return funcs
end

function modifier_aghanim_icon:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_aghanim_icon:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_aghanim_icon:GetAbsoluteNoDamagePure()
    return 1
end

aghanim_ray_stop = class({})

function aghanim_ray_stop:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_aghanim_ray")
end

aghanim_water_ray_stop = class({})

function aghanim_water_ray_stop:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_aghanim_water_ray")
end

LinkLuaModifier("modifier_aghanim_invul_scepter", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE)

modifier_aghanim_invul_scepter = class({})

function modifier_aghanim_invul_scepter:IsPurgable() return false end
function modifier_aghanim_invul_scepter:IsPurgeException() return false end
function modifier_aghanim_invul_scepter:GetTexture() return "aghanim_style_main" end

function modifier_aghanim_invul_scepter:CheckState()
    return 
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }
end

function modifier_aghanim_invul_scepter:GetStatusEffectName() return "particles/aghs_invul.vpcf" end
function modifier_aghanim_invul_scepter:StatusEffectPriority() return 10 end










LinkLuaModifier("modifier_remove_aghanim_styles_add", "heroes/hero_aghanim/aghanim.lua", LUA_MODIFIER_MOTION_NONE)

modifier_remove_aghanim_styles_add = class({})

function modifier_remove_aghanim_styles_add:IsHidden() return true end
function modifier_remove_aghanim_styles_add:IsPurgable() return false end
function modifier_remove_aghanim_styles_add:IsPurgeException() return false end
function modifier_remove_aghanim_styles_add:OnCreated()
    if not IsServer() then return end
    for i = 0, 5 do
        local ability = self:GetCaster():GetAbilityByIndex(i)
        if ability then
            ability:StartCooldown(1)
        end
    end  
end

function modifier_remove_aghanim_styles_add:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveModifierByName("modifier_aghanim_change_style_main_mad")
    self:GetParent():RemoveModifierByName("modifier_aghanim_change_style_main_bath")
    self:GetParent():RemoveModifierByName("modifier_aghanim_change_style_main_mech")
    self:GetParent():RemoveModifierByName("modifier_aghanim_change_style_main_smith") 
    local sunder_particle_2 = ParticleManager:CreateParticle("particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(sunder_particle_2, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(sunder_particle_2, 2, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(sunder_particle_2, 15, Vector(0,152,255))
    ParticleManager:SetParticleControl(sunder_particle_2, 16, Vector(1,0,0))
    ParticleManager:ReleaseParticleIndex(sunder_particle_2)
    self:GetParent():EmitSound("Hero_Terrorblade.Sunder.Cast")
    self:GetParent():EmitSound("Hero_Terrorblade.Sunder.Target")

    if self:GetCaster():HasScepter() then
        self:GetCaster():Heal(self:GetCaster():GetMaxHealth(), nil)
    end
end