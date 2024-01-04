LinkLuaModifier("modifier_fymryn_stretching", "heroes/hero_fymryn/fymryn_stretching", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_stretching_debuff", "heroes/hero_fymryn/fymryn_stretching", LUA_MODIFIER_MOTION_NONE)

fymryn_stretching = class({})

function fymryn_stretching:Precache(context)
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/fymryn_test_stack.vpcf', context )
    PrecacheResource( "particle", 'particles/arena/units/heroes/hero_fymryn/sxssss/refresh_cd.vpcf', context )
end

function fymryn_stretching:GetIntrinsicModifierName()
    return "modifier_fymryn_stretching"
end

modifier_fymryn_stretching = class({})
function modifier_fymryn_stretching:IsHidden() return true end
function modifier_fymryn_stretching:IsPurgable() return false end
function modifier_fymryn_stretching:IsPurgeException() return false end
function modifier_fymryn_stretching:RemoveOnDeath() return false end

function modifier_fymryn_stretching:OnCreated()
    if not IsServer() then return end
    self.attacks = self:GetAbility():GetSpecialValueFor("attacks")
    self.cooldown_reduction = self:GetAbility():GetSpecialValueFor("cooldown_reduction")
end

function modifier_fymryn_stretching:OnRefresh()
    if not IsServer() then return end
    self.attacks = self:GetAbility():GetSpecialValueFor("attacks")
    self.cooldown_reduction = self:GetAbility():GetSpecialValueFor("cooldown_reduction")
end

function modifier_fymryn_stretching:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
        MODIFIER_EVENT_ON_ATTACK_FAIL,
    }
end

function modifier_fymryn_stretching:OnAttackStart(params)
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    if self:GetAbility():GetLevel() <= 0 then return end
    local target = params.target
    local max_stacks = self:GetAbility():GetSpecialValueFor("attacks_hero")
    if not target:IsHero() then
        max_stacks = self:GetAbility():GetSpecialValueFor("attacks_enemy")
    end
    local modifier_fymryn_stretching_debuff = self:GetParent():FindModifierByName("modifier_fymryn_stretching_debuff")
    if modifier_fymryn_stretching_debuff then
        if modifier_fymryn_stretching_debuff:GetStackCount()+1 >= max_stacks then
            self:GetParent():RemoveGesture(ACT_DOTA_ATTACK_EVENT)
            self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK_EVENT, self:GetParent():GetAttackSpeed(false))
        end
    end
end

function modifier_fymryn_stretching:OnAttackLanded(params)
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    if params.target == self:GetParent() then return end
    if params.target:IsBuilding() then return end
    if params.attacker:IsIllusion() then return end
    local caster = self:GetCaster()
    local caster_original = self:GetCaster()
    if caster:HasModifier("modifier_fymryn_black_mirror_illusion_active") then
        local modifier_fymryn_black_mirror_illusion_active = self:GetParent():FindModifierByName("modifier_fymryn_black_mirror_illusion_active")
        if modifier_fymryn_black_mirror_illusion_active then
            caster_original = modifier_fymryn_black_mirror_illusion_active:GetCaster()
        end
    end
    if self:GetAbility():GetLevel() <= 0 then return end
    local duration = self:GetAbility():GetSpecialValueFor("duration")
    caster_original:AddNewModifier(caster_original, self:GetAbility(), "modifier_fymryn_stretching_debuff", {duration = duration, target = params.target:entindex()})
end

function modifier_fymryn_stretching:CooldownReduction(target)
    if not IsServer() then return end
    for i=0,12 do
        local ability = target:GetAbilityByIndex(i)
        if ability and not ability:IsCooldownReady() and ability:GetAbilityName() ~= "fymryn_black_mirror" then
            local cooldown = ability:GetCooldownTimeRemaining()
            if cooldown - self.cooldown_reduction <= 0 then
                ability:EndCooldown()
            else
                ability:EndCooldown()
                ability:StartCooldown(cooldown - self.cooldown_reduction)
            end
        end
    end
    for i=0,16 do
        local item = target:GetItemInSlot(i)
        if item and not item:IsCooldownReady() then
            local cooldown = item:GetCooldownTimeRemaining()
            if cooldown - self.cooldown_reduction <= 0 then
                item:EndCooldown()
            else
                item:EndCooldown()
                item:StartCooldown(cooldown - self.cooldown_reduction)
            end
        end
    end
end

function modifier_fymryn_stretching:IsAura()
    return true
end

function modifier_fymryn_stretching:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aoe_true_sight")
end

function modifier_fymryn_stretching:GetModifierAura()
    return "modifier_truesight"
end
   
function modifier_fymryn_stretching:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_fymryn_stretching:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_fymryn_stretching:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_fymryn_stretching:GetAuraDuration()
    return 0.1
end

modifier_fymryn_stretching_debuff = class({})
function modifier_fymryn_stretching_debuff:IsPurgable() return false end
function modifier_fymryn_stretching_debuff:OnCreated(params)
    if not IsServer() then return end
    self:SetStackCount(1)
    self.target = EntIndexToHScript(params.target)
    local max_stacks = self:GetAbility():GetSpecialValueFor("attacks_hero")
    if not self.target:IsHero() then
        max_stacks = self:GetAbility():GetSpecialValueFor("attacks_enemy")
    end

    self.particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn_test_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, Vector(0, self:GetStackCount(), 0))
    self:AddParticle(self.particle, false, false, -1, false, false)

    if self:GetStackCount() >= max_stacks then
        local modifier_fymryn_stretching = self:GetParent():FindModifierByName("modifier_fymryn_stretching")
        if modifier_fymryn_stretching then
            modifier_fymryn_stretching:CooldownReduction(self:GetParent())
        end
        if self.particle then
            ParticleManager:DestroyParticle(self.particle, true)
        end
        local last_hit = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/sxssss/refresh_cd.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:ReleaseParticleIndex(last_hit)
        local flash_particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn/passive_aoe_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
        ParticleManager:ReleaseParticleIndex(flash_particle)
        local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self.target:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("radius_damage"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
        for _, enemy in pairs(enemies) do
            ApplyDamage({victim = enemy, attacker = self:GetCaster(), ability = self:GetAbility(), damage = self:GetAbility():GetSpecialValueFor("damage_bonus_magical"), damage_type = DAMAGE_TYPE_MAGICAL})
        end
        self:GetParent():EmitSound("fymryn_passive_damage")
        self:Destroy()
    end
end

function modifier_fymryn_stretching_debuff:OnRefresh(params)
    if not IsServer() then return end
    self:IncrementStackCount()
    self.target = EntIndexToHScript(params.target)
    local max_stacks = self:GetAbility():GetSpecialValueFor("attacks_hero")
    if not self.target:IsHero() then
        max_stacks = self:GetAbility():GetSpecialValueFor("attacks_enemy")
    end
    if self.particle then
        ParticleManager:SetParticleControl(self.particle, 1, Vector(0, self:GetStackCount(), 0))
    end
    if self:GetStackCount() >= max_stacks then
        local modifier_fymryn_stretching = self:GetParent():FindModifierByName("modifier_fymryn_stretching")
        if modifier_fymryn_stretching then
            modifier_fymryn_stretching:CooldownReduction(self:GetParent())
        end
        if self.particle then
            ParticleManager:DestroyParticle(self.particle, true)
        end
        local last_hit = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/sxssss/refresh_cd.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:ReleaseParticleIndex(last_hit)
        local flash_particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn/passive_aoe_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
        ParticleManager:ReleaseParticleIndex(flash_particle)
        local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self.target:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("radius_damage"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
        for _, enemy in pairs(enemies) do
            ApplyDamage({victim = enemy, attacker = self:GetCaster(), ability = self:GetAbility(), damage = self:GetAbility():GetSpecialValueFor("damage_bonus_magical"), damage_type = DAMAGE_TYPE_MAGICAL})
        end
        self:GetParent():EmitSound("fymryn_passive_damage")
        self:Destroy()
    end
end