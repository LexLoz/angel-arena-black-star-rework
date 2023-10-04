function OnAttackLanded(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if not target:IsMagicImmune() and not target:IsInvulnerable() and not target:IsDebuffImmune() then
		local manaburn = keys.feedback_mana_burn + keys.mana_burn_pct * target:GetMana() * 0.01
		local manadrain = manaburn * keys.feedback_mana_drain_pct * 0.01
		if caster:IsIllusion() then
			manaburn = manaburn * keys.illusion_mana_burn * 0.01
			manadrain = 0
		end
		target:SpendMana(manaburn, ability)
		caster:GiveMana(manadrain)

		ability.NoDamageAmp = true
		ApplyDamage({
			victim = target,
			attacker = caster,
			damage = manaburn * keys.damage_per_burn_pct * 0.01,
			damage_type = ability:GetAbilityDamageType(),
			ability = ability,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
		})
		ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:CreateParticle("particles/arena/generic_gameplay/generic_manasteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	end
end

function Purge(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	ParticleManager:CreateParticle("particles/generic_gameplay/generic_purge.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	caster:EmitSound("DOTA_Item.DiffusalBlade.Activate")
	if target:IsSummoned() then
		target:EmitSound("DOTA_Item.DiffusalBlade.Kill")
	else
		target:EmitSound("DOTA_Item.DiffusalBlade.Target")
	end
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		target:Purge(false, true, false, false, false)
	else
		if target:IsSummoned() then
			target:TrueKill(ability, caster)
		else
			target:Purge(true, false, false, false, false)
			if not target:IsMagicImmune() and not target:IsInvulnerable() and not target:IsDebuffImmune() then
				ability:ApplyDataDrivenModifier(caster, target, keys.modifier_root, {})
				ability:ApplyDataDrivenModifier(caster, target, keys.modifier_slow, {})
			end
		end
	end
end
