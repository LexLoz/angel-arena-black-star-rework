LinkLuaModifier("modifier_saitama_trainings_invulnerability", "heroes/hero_saitama/trainings.lua", LUA_MODIFIER_MOTION_NONE)

saitama_training = class({})

modifier_saitama_trainings_invulnerability = class({
    CheckState    = function() return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    } end,
    IsDebuff      = function() return false end
})

function saitama_training:HasStaticCooldown() return true end


function saitama_training:OnUpgrade()
    UpgradeTrainings(self:GetCaster(), self:GetLevel())
end

if IsServer() then
	function saitama_training:OnSpellStart()
        local caster = self:GetCaster()
		caster:AddNewModifier(caster, self, "modifier_saitama_trainings_invulnerability", {duration = self:GetChannelTime()})
	end
	function saitama_training:OnChannelFinish(bInterrupted)
		if not bInterrupted then
			local caster = self:GetCaster()
			caster:ModifyStrength(self:GetSpecialValueFor("bonus_strength"))

			local modifier = caster:FindModifierByName("modifier_saitama_limiter")
			if not modifier then modifier = caster:AddNewModifier(caster, self, "modifier_saitama_limiter", nil) end
			modifier:SetStackCount(modifier:GetStackCount() + self:GetSpecialValueFor("stacks_amount"))
		end
		self:GetCaster():RemoveModifierByName("modifier_saitama_trainings_invulnerability")
    end
end

saitama_squats = saitama_training
saitama_sit_ups = saitama_training
saitama_push_ups = saitama_training

function UpgradeTrainings(caster, abilityLevel)
    if caster:FindAbilityByName("saitama_push_ups") and caster:FindAbilityByName("saitama_push_ups"):GetLevel() < abilityLevel then
        caster:FindAbilityByName("saitama_push_ups"):SetLevel(abilityLevel)
    end
    if caster:FindAbilityByName("saitama_sit_ups") and caster:FindAbilityByName("saitama_sit_ups"):GetLevel() < abilityLevel then
        caster:FindAbilityByName("saitama_sit_ups"):SetLevel(abilityLevel)
    end
    if caster:FindAbilityByName("saitama_squats") and caster:FindAbilityByName("saitama_squats"):GetLevel() < abilityLevel then
        caster:FindAbilityByName("saitama_squats"):SetLevel(abilityLevel)
    end
end