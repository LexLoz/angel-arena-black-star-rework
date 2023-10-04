

return function(parts, funcs)
  funcs = funcs or {}
  local storedSpecials = {}
  local modifier = {
    IsHidden = function() return true end,
    IsPurgable = function() return false end,
    DeclareFunctions = function() return funcs end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMAMENT end,
  }

  function modifier:OnCreated()
    self:StoreAbilitySpecials(storedSpecials)
  end
  function modifier:OnDestroy()
    self:StoreAbilitySpecials(storedSpecials)
  end

  if parts.sange then
    table.insert(funcs, MODIFIER_PROPERTY_STATUS_RESISTANCE)
    table.insert(storedSpecials, "bonus_status_resist")
    function modifier:GetModifierStatusResistance()
      return self:GetSpecialValueFor("bonus_status_resist")
    end
    --[[table.insert(funcs, MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE)
    table.insert(storedSpecials, "bonus_heal_and_lifesteal")
    function modifier:GetModifierHPRegenAmplify_Percentage()
      return self:GetSpecialValueFor("bonus_heal_and_lifesteal")
    end]]
    table.insert(funcs, MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE)
    table.insert(storedSpecials, "bonus_heal_and_lifesteal")
    function modifier:GetModifierLifestealRegenAmplify_Percentage()
      return self:GetSpecialValueFor("bonus_heal_and_lifesteal")
    end
    --[[table.insert(funcs,   HEAL_AMPLIFY_PERCENTAGE_TARGET)
    table.insert(storedSpecials, "bonus_heal_and_lifesteal")
    function modifier:GetModifierHealAmplify_PercentageTarget()
      return self:GetSpecialValueFor("bonus_heal_and_lifesteal")
    end]]
    table.insert(funcs, MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE )
    table.insert(storedSpecials, "bonus_heal_and_lifesteal")
    function modifier:GetModifierHPRegenAmplify_Percentage()
      return self:GetSpecialValueFor("bonus_heal_and_lifesteal")
    end
    table.insert(funcs, MODIFIER_PROPERTY_STATS_STRENGTH_BONUS)
    table.insert(storedSpecials, "bonus_strength")
    function modifier:GetModifierBonusStats_Strength()
      return self:GetSpecialValueFor("bonus_strength")
    end

    --[[if IsServer() then
      table.insert(funcs, MODIFIER_EVENT_ON_ATTACK_LANDED)
      table.insert(storedSpecials, "maim_chance_pct")
      table.insert(storedSpecials, "maim_duration")
      function modifier:OnAttackLanded(keys)
        local target = keys.target
        local attacker = keys.attacker

        if attacker == self:GetParent() and RollPercentage(self:GetSpecialValueFor("maim_chance_pct")) then
          target:EmitSound("DOTA_Item.Maim")
          target:AddNewModifier(
            attacker,
            self:GetAbility(),
            parts.sange,
            { duration = self:GetSpecialValueFor("maim_duration") }
          )
        end
      end
    end]]
  end

  if parts.yasha then
    table.insert(funcs, MODIFIER_PROPERTY_STATS_AGILITY_BONUS)
    table.insert(storedSpecials, "bonus_agility")
    function modifier:GetModifierBonusStats_Agility()
      return self:GetSpecialValueFor("bonus_agility")
    end

    table.insert(funcs, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT)
    table.insert(storedSpecials, "bonus_attack_speed")
    function modifier:GetModifierAttackSpeedBonus_Constant()
      return self:GetSpecialValueFor("bonus_attack_speed")
    end

    table.insert(funcs, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE)
    table.insert(storedSpecials, "bonus_movement_speed_pct")
    function modifier:GetModifierMoveSpeedBonus_Percentage_Unique()
      return self:GetSpecialValueFor("bonus_movement_speed_pct")
    end
  end

  if parts.kaya then
    table.insert(funcs, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS)
    table.insert(storedSpecials, "bonus_intellect")
    function modifier:GetModifierBonusStats_Intellect()
      return self:GetSpecialValueFor("bonus_intellect")
    end

    table.insert(funcs, MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE_UNIQUE )
    table.insert(storedSpecials, "spell_amp_pct")
    function modifier:GetModifierSpellAmplify_PercentageUnique()
      return self:GetSpecialValueFor("spell_amp_pct")
    end

    table.insert(funcs, MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE )
    table.insert(storedSpecials, "bonus_mana_regen_pct")
    function modifier:GetModifierMPRegenAmplify_Percentage()
      return self:GetSpecialValueFor("bonus_mana_regen_pct")
    end

    table.insert(funcs, MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE)
    table.insert(storedSpecials, "bonus_spell_lifesteal_pct")
    function modifier:GetModifierSpellLifestealRegenAmplify_Percentage()
      return self:GetSpecialValueFor("bonus_spell_lifesteal_pct")
    end
  end

  return modifier
end
