LinkLuaModifier("modifier_fymryn_mirror", "heroes/hero_fymryn/fymryn_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_mirror_double", "heroes/hero_fymryn/fymryn_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_mirror_movespeed", "heroes/hero_fymryn/fymryn_mirror", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fymryn_mirror_invul", "heroes/hero_fymryn/fymryn_mirror", LUA_MODIFIER_MOTION_NONE)

fymryn_mirror = class({})

function fymryn_mirror:Spawn()
    if not IsServer() then return end
    if not self:IsTrained() then
        self:SetLevel(1)
    end
end

function fymryn_mirror:OnSpellStart()
    if not IsServer() then return end

    if self:GetCaster():HasModifier("modifier_fymryn_black_mirror_illusion") then return end

    self:GetCaster():RemoveModifierByName("modifier_fymryn_mirror")

    local hero = nil

    local heroes = {}

    local allHeroes = HeroList:GetAllHeroes()
	for _, hero in pairs(allHeroes) do
        if hero:GetTeamNumber() == self:GetCaster():GetTeamNumber() and hero:GetModelName() ~= "models/development/invisiblebox.vmdl" and hero.illusion == nil and hero ~= self:GetCaster() and not hero:HasModifier("modifier_fymryn_black_mirror_illusion") and not hero:HasModifier("modifier_monkey_king_transform") and not hero:HasModifier("modifier_monkey_king_fur_army_soldier") and not hero:HasModifier("modifier_monkey_king_fur_army_soldier_hidden") then
            table.insert(heroes, hero)
        end
    end

    hero = heroes[RandomInt(1, #heroes)]

    if hero then
        local doppleganger_particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_fymryn/fymryn/self_impact.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
        ParticleManager:SetParticleControl(doppleganger_particle, 0, self:GetCaster():GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(doppleganger_particle)

        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_fymryn_mirror_double", {model = hero:GetModelName(), target = hero:entindex()})
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_fymryn_mirror", {model = hero:GetModelName(), target = hero:entindex()})
    end
end

modifier_fymryn_mirror_invul = class({})
function modifier_fymryn_mirror_invul:IsPurgable() return false end
function modifier_fymryn_mirror_invul:IsHidden() return true end
function modifier_fymryn_mirror_invul:DeclareFunctions()
	local funcs = 
    {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
	return funcs
end
function modifier_fymryn_mirror_invul:GetAbsoluteNoDamagePhysical()
	return 1
end
function modifier_fymryn_mirror_invul:GetAbsoluteNoDamageMagical()
	return 1
end
function modifier_fymryn_mirror_invul:GetAbsoluteNoDamagePure()
	return 1
end
function modifier_fymryn_mirror_invul:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_ATTACK_START,
    }
end
function modifier_fymryn_mirror_invul:OnAttackStart( params )
    if not IsServer() then return end
    if params.attacker~=self:GetParent() then return end
    self:GetCaster():RemoveModifierByName("modifier_fymryn_mirror")
end
function modifier_fymryn_mirror_invul:CheckState()
    return
    {
        [MODIFIER_STATE_DISARMED] = true,
    }
end

modifier_fymryn_mirror_double = class({})
function modifier_fymryn_mirror_double:IsHidden() return true end
function modifier_fymryn_mirror_double:IsPurgable() return false end
function modifier_fymryn_mirror_double:OnCreated(params)
    if not IsServer() then return end
    self.target = EntIndexToHScript(params.target)
    self.illusion = CreateUnitByName( self.target:GetUnitName(), self:GetParent():GetAbsOrigin(), false, self.target, self.target, self.target:GetTeamNumber() )
    self.illusion:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_phased", {})
    self.illusion:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_fymryn_mirror_invul", {})
    self.illusion.illusion = true
    local children = self.illusion:GetChildren();
    for k,child in pairs(children) do
        if child:GetClassname() == "dota_item_wearable" and child:GetModelName() ~= "" then
            child:Destroy()
        end
    end

    self.illusion:SetOriginalModel("models/development/invisiblebox.vmdl")
    self.illusion:SetModel("models/development/invisiblebox.vmdl")
    self:StartIntervalThink(0.01)
end

function modifier_fymryn_mirror_double:OnIntervalThink()
    if not IsServer() then return end
    if self.target:IsNull() then return end
    local level = self.target:GetLevel()
    if level > self.illusion:GetLevel() then
        self.illusion:HeroLevelUp(false)
    end
    self.illusion:SetAbsOrigin(self:GetParent():GetAbsOrigin())
end

function modifier_fymryn_mirror_double:OnDestroy()
    if not IsServer() then return end
    local origin = self.illusion:GetAbsOrigin()
    self.illusion:Destroy()
    self:GetParent():SetAbsOrigin(origin)
    FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
end


modifier_fymryn_mirror = class({})
function modifier_fymryn_mirror:IsPurgable() return false end
function modifier_fymryn_mirror:OnCreated(params)
    if not IsServer() then return end
    self.target = EntIndexToHScript(params.target)
    self.original_model = self:GetParent():GetModelName()
    self.model = params.model
    self:GetParent():SetOriginalModel(self.model)
    self:GetParent():SetModel(self.model)
    self:GetParent():SetModelScale(self.target:GetModelScale())
    self:GetParent():NotifyWearablesOfModelChange(true)
    self:GetParent():ManageModelChanges()
    self.items_econ = {}

    self:GetCaster():SwapAbilities("fymryn_mirror", "fymryn_mirror_cancel", false, true)

    if self.target ~= nil and self.target:IsHero() then
        local children = self.target:GetChildren();
        for k,child in pairs(children) do
            if child:GetClassname() == "dota_item_wearable" and child:GetModelName() ~= "" then
                local item = Entities:CreateByClassname( "wearable_item" )
                item:SetModel( child:GetModelName() )
                item:FollowEntity(self:GetParent(), true)
                item:SetTeam( self:GetParent():GetTeamNumber() )
                item:SetOwner( self:GetParent() )
                table.insert(self.items_econ, item)
            end
        end
    end
end

function modifier_fymryn_mirror:CheckState()
    return
    {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    }
end

function modifier_fymryn_mirror:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_fymryn_mirror:OnTakeDamage(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    self:Destroy()
end

function modifier_fymryn_mirror:OnAttackStart( params )
    if not IsServer() then return end
    if params.attacker~=self:GetParent() then return end
    self:Destroy()
end

function modifier_fymryn_mirror:OnAbilityExecuted(params)
    if not IsServer() then return end
    if params.unit ~= self:GetCaster() then return end
    self:Destroy()
end

function modifier_fymryn_mirror:OnDestroy()
    if not IsServer() then return end
    for _, item in pairs(self.items_econ) do
		if item then
			item:Destroy()
		end
	end
    self:GetCaster():SwapAbilities("fymryn_mirror_cancel", "fymryn_mirror", false, true)
    self:GetParent():RemoveModifierByName("modifier_fymryn_mirror_double")
    self:GetParent():SetOriginalModel(self.original_model)
    self:GetParent():SetModel(self.original_model)
    self:GetParent():SetModelScale(1)
    local fymryn_mirror = self:GetCaster():FindAbilityByName("fymryn_mirror")
    if fymryn_mirror then
        fymryn_mirror:EndCooldown()
        fymryn_mirror:UseResources(false, false, false, true)
    end
end

fymryn_mirror_cancel = class({})

function fymryn_mirror_cancel:Spawn()
    if not IsServer() then return end
    if not self:IsTrained() then
        self:SetLevel(1)
    end
end

function fymryn_mirror_cancel:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_fymryn_mirror_double")
    self:GetCaster():RemoveModifierByName("modifier_fymryn_mirror")
end