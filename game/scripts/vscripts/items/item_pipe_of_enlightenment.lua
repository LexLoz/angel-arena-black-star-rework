
LinkLuaModifier("modifier_item_pipe_of_enlightenment", "items/item_pipe_of_enlightenment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pipe_of_enlightenment_buff", "items/item_pipe_of_enlightenment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pipe_of_enlightenment_buff_cooldown", "items/item_pipe_of_enlightenment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pipe_of_enlightenment_aura", "items/item_pipe_of_enlightenment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pipe_of_enlightenment_team_buff", "items/item_pipe_of_enlightenment.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pipe_of_enlightenment_team_buff_cooldown", "items/item_pipe_of_enlightenment.lua", LUA_MODIFIER_MOTION_NONE)


item_pipe_of_enlightenment = class({
	GetIntrinsicModifierName = function() return "modifier_item_pipe_of_enlightenment" end,
})

if IsServer() then
    function item_pipe_of_enlightenment:OnSpellStart()
        local caster = self:GetCaster()

        caster:EmitSound("DOTA_Item.Pipe.Activate")
        ParticleManager:CreateParticle("particles/arena/items_fx/pipe_of_enlightenment_launch.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

        local allies = FindUnitsInRadius(
            caster:GetTeam(),
            caster:GetAbsOrigin(),
            nil,
            self:GetSpecialValueFor("radius"),
            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE ,
            FIND_ANY_ORDER,
            false
        )

        for _,v in pairs(allies) do
            if not v:HasModifier("modifier_item_pipe_of_enlightenment_team_buff_cooldown") then
                v:AddNewModifier(
                    caster,
                    self,
                    "modifier_item_pipe_of_enlightenment_team_buff",
                    {duration = self:GetSpecialValueFor("barrier_duration")}
                )
                v:AddNewModifier(
                    caster,
                    self,
                    "modifier_item_pipe_of_enlightenment_team_buff_cooldown",
                    {duration = self:GetSpecialValueFor("barrier_cooldown")}
                )
            end
        end
    end
end

modifier_item_pipe_of_enlightenment = class({
	IsHidden =   function() return true end,
	IsPurgable = function() return false end,
})

modifier_item_pipe_of_enlightenment_aura = class({
    IsHidden =   function() return false end,
	IsPurgable = function() return false end,
})

modifier_item_pipe_of_enlightenment_buff_cooldown = class({
	IsPurgable = function() return false end,
	IsDebuff = function() return true end,
})

modifier_item_pipe_of_enlightenment_team_buff = class({
    IsHidden =   function() return false end,
	IsPurgable = function() return true end,
    GetEffectName = function() return "particles/arena/items_fx/pipe_of_enlightenment_v2.vpcf" end,
})

modifier_item_pipe_of_enlightenment_team_buff_cooldown = class({
    IsHidden =   function() return false end,
	IsPurgable = function() return false end,
})

function modifier_item_pipe_of_enlightenment:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION
	}
end

function modifier_item_pipe_of_enlightenment:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_pipe_of_enlightenment:GetModifierMagicalResistanceDirectModification()
	    local parent = self:GetParent()
        local ability = self:GetAbility()
        local armor = parent:GetPhysicalArmorValue(false) - ability:GetSpecialValueFor("bonus_armor")
        local resist_per_armor = ability:GetSpecialValueFor("resist_per_armor")
        local max_resist = ability:GetSpecialValueFor("max_resist_per_armor")
         
        local resist = math.min(max_resist, armor * resist_per_armor)

        --print(resist)
        return resist
end

function modifier_item_pipe_of_enlightenment:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("magic_resistance")
end

function modifier_item_pipe_of_enlightenment:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("health_regen_pct")
end

function modifier_item_pipe_of_enlightenment:GetModifierAura()
	return "modifier_item_pipe_of_enlightenment_aura"
end
function modifier_item_pipe_of_enlightenment:IsAura()
    return true
end
function modifier_item_pipe_of_enlightenment:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end
function modifier_item_pipe_of_enlightenment:GetAuraSearchTeam()
	return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_item_pipe_of_enlightenment:GetAuraSearchType()
	return self:GetAbility():GetAbilityTargetType()
end

function modifier_item_pipe_of_enlightenment:GetAuraSearchFlags()
	return self:GetAbility():GetAbilityTargetFlags()
end
function modifier_item_pipe_of_enlightenment:GetAuraEntityReject(hEntity)
    local caster = self:GetAbility():GetCaster()
    return hEntity == caster
end

if IsServer() then
    function modifier_item_pipe_of_enlightenment:OnCreated()
        --self:StartIntervalThink(1)
    end
    function modifier_item_pipe_of_enlightenment:OnIntervalThink()
        local parent = self:GetParent()
        local ability = self:GetAbility()
        local armor = parent:GetPhysicalArmorValue(false) - ability:GetSpecialValueFor("bonus_armor")
        local resist_per_armor = ability:GetSpecialValueFor("resist_per_armor")
        local max_resist = ability:GetSpecialValueFor("max_resist_per_armor")
        
        local resist = math.min(max_resist, armor * resist_per_armor)
        --print(resist)

        if self.resist ~= resist then
            self.resist = resist
            parent:SetBaseMagicalResistanceValue((parent.Custom_MagicalResist or 25) + resist)
        end
    end

    function modifier_item_pipe_of_enlightenment:OnDestroy()
        self:GetParent():SetBaseMagicalResistanceValue(self:GetParent().Custom_MagicalResist or 25)
    end
	function modifier_item_pipe_of_enlightenment:OnTakeDamage(keys)
		local unit = self:GetParent()
		local ability = self:GetAbility()
		if unit == keys.unit and IsValidEntity(ability) and IsValidEntity(keys.inflictor) and RollPercentage(ability:GetSpecialValueFor("buff_chance")) and not unit:HasModifier("modifier_item_pipe_of_enlightenment_buff_cooldown") then
			unit:AddNewModifier(unit, ability, "modifier_item_pipe_of_enlightenment_buff", {duration = ability:GetSpecialValueFor("buff_duration")})
			unit:AddNewModifier(unit, ability, "modifier_item_pipe_of_enlightenment_buff_cooldown", {duration = ability:GetSpecialValueFor("buff_cooldown")})

		end
	end
end

modifier_item_pipe_of_enlightenment_buff = class({})
function modifier_item_pipe_of_enlightenment_buff:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	}
end
function modifier_item_pipe_of_enlightenment_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end
function modifier_item_pipe_of_enlightenment_buff:GetModifierMagicalResistanceBonus()
	return 50
end

if IsServer() then
	function modifier_item_pipe_of_enlightenment_buff:OnCreated()
		local parent = self:GetParent()
		parent:EmitSound("DOTA_Item.BlackKingBar.Activate")
		parent:Purge(false, true, false, false, false)
		local pfx = ParticleManager:CreateParticle("particles/arena/items_fx/holy_knight_shield_avatar.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(pfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		self:AddParticle(pfx, false, false, -1, true, false)
	end
end

function modifier_item_pipe_of_enlightenment_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE
	}
end

function modifier_item_pipe_of_enlightenment_aura:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("magic_resistance_aura")
end

function modifier_item_pipe_of_enlightenment_aura:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("aura_health_regen_pct")
end

function modifier_item_pipe_of_enlightenment_team_buff:DeclareFunctions()
	return {
		--MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
	}
end

if IsServer() then
    function modifier_item_pipe_of_enlightenment_team_buff:OnCreated()
        local parent = self:GetParent()
        local ability = self:GetAbility()
        local health = ability:GetCaster():GetMaxHealth()
        local block_pct = ability:GetSpecialValueFor("barrier_block_pct")
        self:SetStackCount(math.round(health * block_pct * 0.01))

        self.pfx = ParticleManager:CreateParticle("particles/arena/items_fx/pipe_of_enlightenment_v2.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(self.pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.pfx, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControl(self.pfx, 2, Vector(125, 0, 0))
    end
    function modifier_item_pipe_of_enlightenment_team_buff:OnDestroy()
        ParticleManager:DestroyParticle(self.pfx, false)
    end
    --[[function modifier_item_pipe_of_enlightenment_team_buff:GetModifierTotal_ConstantBlock(keys)
        if self:GetParent() == keys.attacker then return end
        if keys.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

        local stacks = self:GetStackCount()
        if stacks > keys.damage then
            self:SetStackCount(math.round(stacks - keys.damage))
            return -keys.damage * 1000
        else
            Timers:NextTick(function() self:Destroy() end)
            return stacks
        end
    end]]
end