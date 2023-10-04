function Return(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local ability = keys.ability
	local level = ability:GetLevel() - 1
	local strMultiplier = caster:GetStrength() * ability:GetLevelSpecialValueFor("str_to_reflection_pct", level) * 0.01
	local multiplier = ((ability:GetLevelSpecialValueFor("base_reflection", level) * 0.01) + strMultiplier)
	if multiplier > 2 and attacker:IsJungleBear() then
		multiplier = 2
	end

	local return_damage = keys.damage * multiplier
	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and not attacker:IsBoss() and not attacker:IsMagicImmune() and not attacker:IsDebuffImmune() and not caster:IsIllusion() and not caster:PassivesDisabled() then
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(pfx, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
		
		ability.NoDamageAmp = true
		ApplyDamage({
			victim = attacker,
			attacker = caster,
			damage = return_damage,
			damage_type = ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			ability = ability
		})
	end
end