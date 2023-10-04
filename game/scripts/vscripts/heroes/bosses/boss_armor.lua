function Init(keys)
	local caster = keys.caster
	local ability = keys.ability

	for i = 0, caster:GetAbilityCount() - 1 do
		local skill = caster:GetAbilityByIndex(i)
		if skill then
			skill:SetLevel(skill:GetMaxLevel())
		end
	end
end

function Think(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_dazzle_weave_armor")

	if not caster:PassivesDisabled() then
		local ability = keys.ability
		--caster:Purge(false, true, false, false, false)
		--caster:RemoveModifierByName("modifier_ursa_fury_swipes_damage_increase")
		--caster:RemoveModifierByName("modifier_maledict")

		local modifier_razor_eye_of_the_storm_armor = caster:FindModifierByName("modifier_razor_eye_of_the_storm_armor")
		if modifier_razor_eye_of_the_storm_armor and modifier_razor_eye_of_the_storm_armor:GetStackCount() > 10 then
			modifier_razor_eye_of_the_storm_armor:SetStackCount(10)
		end

		local modifier_ursa_fury_swipes_damage_increase = caster:FindModifierByName("modifier_ursa_fury_swipes_damage_increase")
		if modifier_ursa_fury_swipes_damage_increase and modifier_ursa_fury_swipes_damage_increase:GetStackCount() > 25 then
			modifier_ursa_fury_swipes_damage_increase:SetStackCount(25)
		end
	end
end

function OnTakeDamage(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local ability = keys.ability
	if not attacker then return end

	attacker:AddNewModifier(caster, ability, "modifier_max_attack_range", {
		duration = 3,
		AttackRange = ability:GetSpecialValueFor("attack_range_limit"),
	})

	attacker:RemoveModifierByName("modifier_smoke_of_deceit")
	ability:ApplyDataDrivenModifier(caster ,attacker, "modifier_boss_armor_no_invisibility", { duration = 3 })
end
