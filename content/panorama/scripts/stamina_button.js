function UpdateHealthBar() {
	var unit = Players.GetLocalPlayerPortraitUnit();
	//$.Msg(Entities.IsHero(unit))
	if (!unit) return
	var custom_entity_value = GameUI.CustomUIConfig().custom_entity_values[unit];
	var HealthContainer = FindDotaHudElement('HealthContainer');
	var HealthLabel = HealthContainer.FindChildTraverse('HealthLabel');

	var HealthRegenLabel = FindDotaHudElement('HealthRegenLabel'); 
	if (HealthLabel && HealthRegenLabel && unit && Entities.IsHero(unit)) {
		var curhealth = (Entities.GetHealth(unit))
		var maxhealth = (Entities.GetMaxHealth(unit))
		//HealthRegenLabel.text = "+" + ((custom_entity_value ? custom_entity_value.HealthRegen : Entities.GetHealthThinkRegen(unit)) / Entities.GetMaxHealth(unit) * 100).toFixed(1)+"%"
		HealthRegenLabel.text = "+" + NumberReduction(custom_entity_value ? custom_entity_value.HealthRegen : Entities.GetHealthThinkRegen(unit), 1, 0.1)
		curhealth = NumberReduction(Entities.GetHealth(unit))
		maxhealth = NumberReduction(Entities.GetMaxHealth(unit))
		HealthLabel.text = curhealth + " /" + maxhealth
	} else if (HealthLabel && HealthRegenLabel && unit) {
		var curhealth = (Entities.GetHealth(unit))
		var maxhealth = (Entities.GetMaxHealth(unit))
		curhealth = NumberReduction(curhealth)
		maxhealth = NumberReduction(maxhealth)
		HealthLabel.text = curhealth + " /" + maxhealth
		HealthRegenLabel.text = "+" + Entities.GetHealthThinkRegen(unit).toFixed(1)
	}
}

function UpdateManaBar() {
	//$.Msg('Mana')
	var unit = Players.GetLocalPlayerPortraitUnit();
	if (!unit) return
	var custom_entity_value = GameUI.CustomUIConfig().custom_entity_values[unit];

	var ManaContainer = FindDotaHudElement('ManaContainer');
	var ManaProgress = FindDotaHudElement('ManaProgress');
	var ManaRegenLabel = FindDotaHudElement('ManaRegenLabel');
	var ManaLabel = ManaContainer.FindChildTraverse('ManaLabel');

	if (ManaContainer && unit && ManaProgress) {
		if (custom_entity_value && !custom_entity_value.Energy) {
			//$.Msg('mana')
			var curmana = Entities.GetMaxMana(unit) == 65536 ? custom_entity_value.CurrentMana : Entities.GetMana(unit)
			var maxmana = Entities.GetMaxMana(unit) == 65536 ? custom_entity_value.MaxMana : Entities.GetMaxMana(unit)
			var manareg = custom_entity_value.ManaRegen
			var manacount = curmana / maxmana
			//ManaRegenLabel.text = "+"+(manareg / maxmana * 100).toFixed(1) + "%"
			ManaRegenLabel.text = "+" + NumberReduction(manareg, 1, 0.1)
			//ManaRegenLabel.text = "+"+(manareg).toFixed(1)
			ManaProgress.value = manacount
			curmana = NumberReduction(curmana)
			maxmana = NumberReduction(maxmana)
			ManaLabel.text = curmana + " /" + maxmana
		} else if (custom_entity_value && custom_entity_value.Energy) {
			var energy = custom_entity_value.Energy
			var energyLimit = custom_entity_value.EnergyLimit
			if (energyLimit != 2000000000) {
				ManaProgress.value = energy / energyLimit
				energy = NumberReduction(energy)
				energyLimit = NumberReduction(energyLimit)
				ManaLabel.text = energy + " /" + energyLimit
			} else {
				ManaLabel.text = NumberReduction(energy)
			}
			ManaRegenLabel.text = "+" + NumberReduction(custom_entity_value.ManaRegen)
		} else if (!custom_entity_value) {
			ManaRegenLabel.text = "+" + (Entities.GetManaThinkRegen(unit)).toFixed(1)
			ManaLabel.text = Entities.GetMana(unit) + " /" + Entities.GetMaxMana(unit)
			ManaProgress.value = Entities.GetMana(unit) / Entities.GetMaxMana(unit)
		}
	}
}

function UpdateStaminaBar() {
	//$.Msg('Stamina')
	var unit = Players.GetLocalPlayerPortraitUnit();
	if (!unit || !Entities.IsHero(unit)) return
	var custom_entity_value = GameUI.CustomUIConfig().custom_entity_values[unit];

	var stacks
	// print(Entities.GetNumBuffs(unit))
	for (var i = 0; i < Entities.GetNumBuffs(unit); i++) {
		var buff = Entities.GetBuff(unit, i);
		if (buff !== -1) {
			var buffName = Buffs.GetName(unit, buff);
			// print(buffName);
			if (buffName == "modifier_stamina") {
				stacks = Buffs.GetStackCount(unit, buff);
			}
		}
	}

	var ManaContainer = FindDotaHudElement('ManaContainer');
	var ManaProgress = FindDotaHudElement('ManaProgress');
	var ManaRegenLabel = FindDotaHudElement('ManaRegenLabel');
	var ManaLabel = ManaContainer.FindChildTraverse('ManaLabel');

	if (ManaContainer && unit && custom_entity_value && ManaProgress && ManaLabel) {
		var maxstam = NumberReduction(custom_entity_value.MaxStamina)
		var curstam = NumberReduction(custom_entity_value.MaxStamina * stacks * 0.01)//NumberReduction(custom_entity_value.CurrentStamina)
		//$.Msg(curstam)
		var stamreg = custom_entity_value.StaminaRegen
		var stamperhit = custom_entity_value.StaminaPerHit
		var stamcount = (custom_entity_value.MaxStamina * stacks * 0.01) / custom_entity_value.MaxStamina
		ManaLabel.text = (curstam) + " /" + maxstam
		ManaRegenLabel.text = "-" + stamperhit.toFixed(1) + "%" + $.Localize("#arena_stamina_reduce")
		ManaProgress.value = stamcount
	}
}

function ToggleOnStaminaBar() {
	var ButtonSwap = $.GetContextPanel("ButtonSwapMana")
	var agbut = ButtonSwap.FindChildTraverse("Stamina")
	var intbut = ButtonSwap.FindChildTraverse("Mana")

	var ManaProgress_Left = FindDotaHudElement("ManaProgress_Left")
	var ManaProgress_Right = FindDotaHudElement("ManaProgress_Right")
	ManaProgress_Left.style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #2b8737 ), color-stop( 0.2, #4dce41 ), color-stop( .5, #57ea4a), to( #2b8737 ) )"
	ManaProgress_Right.style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #103213 ), color-stop( 0.2, #194717 ), color-stop( .5, #164420), to( #10321a ) )"

	agbut.visible = false;
	intbut.visible = true;
	ButtonSwap.Mana = false;
	ButtonSwap.Stamina = true;
	AutoUpdateStaminaBar();
}

function ToggleOnManaBar() {
	var ButtonSwap = $.GetContextPanel("ButtonSwapMana");
	var agbut = ButtonSwap.FindChildTraverse("Stamina");
	var intbut = ButtonSwap.FindChildTraverse("Mana");

	var ManaProgress_Left = FindDotaHudElement("ManaProgress_Left");
	var ManaProgress_Right = FindDotaHudElement("ManaProgress_Right");
	ManaProgress_Left.style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #2b4287 ), color-stop( 0.2, #4165ce ), color-stop( .5, #4a73ea), to( #2b4287 ) )";
	ManaProgress_Right.style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #101932 ), color-stop( 0.2, #172447 ), color-stop( .5, #162244), to( #101932 ) )";

	agbut.visible = true;
	intbut.visible = false;
	ButtonSwap.Mana = true;
	ButtonSwap.Stamina = false;
	AutoUpdateManaBar();
}

function UpdateButtonSwapManaPosition(first) {
	var ManaContainerPosition = FindDotaHudElement("ManaContainer").GetPositionWithinWindow();
	var coords = CorrectPositionValue(ManaContainerPosition.x) + "px " + CorrectPositionValue(ManaContainerPosition.y) + "px " + "0";
	ManaContainerPosition.x = CorrectPositionValue(ManaContainerPosition.x);
	ManaContainerPosition.y = CorrectPositionValue(ManaContainerPosition.y);
	//print(coords)
	var ButtonSwap = FindDotaHudElement("ButtonSwapMana");
	//print(ButtonSwap);
	//if (ButtonSwap.style.position != coords) {
		//print(coords)
		ButtonSwap.style.position = coords;
		// ButtonSwap.style["padding-top"] = ManaContainerPosition.x + "px";
		// ButtonSwap.style["padding-left"] = ManaContainerPosition.y + "px";
	//}
	if (first) {
		ButtonSwap.stamina_description_tooltip = $.CreatePanel('Panel', $.GetContextPanel(), '');
		ButtonSwap.stamina_description_tooltip.style.tooltipPosition = 'top';
		return ButtonSwap
	}
	if (ButtonSwap.stamina_description_tooltip) {
		ButtonSwap.stamina_description_tooltip.style.position = coords;
	}

	return ButtonSwap;
}

function AutoUpdateManaBar() {
	var ButtonSwap = $.GetContextPanel("ButtonSwapMana");
	if (!ButtonSwap.Mana) return;
	$.Schedule(1 / 40, AutoUpdateManaBar);
	UpdateManaBar();
}

function AutoUpdateStaminaBar() {
	var ButtonSwap = $.GetContextPanel("ButtonSwapMana");
	if (!ButtonSwap.Stamina) return;
	$.Schedule(1 / 40, AutoUpdateStaminaBar);
	UpdateStaminaBar();
}

function AutoUpdateHealthBar() {
	$.Schedule(1 / 40, AutoUpdateHealthBar);
	UpdateHealthBar();
}

function AutoUpdateButtonPosition() {
    $.Schedule(0.1, AutoUpdateButtonPosition);
    UpdateButtonSwapManaPosition();
}

function RecolorHealthBar() {
	var HealthBar = FindDotaHudElement("HealthContainer");
	var HealthBarProgress_Left = HealthBar.FindChildTraverse("HealthProgress_Left");
	var HealthBarProgress_Right = HealthBar.FindChildTraverse("HealthProgress_Right");
	var HealthRegenLabel = HealthBar.FindChildTraverse("HealthRegenLabel")

	HealthBarProgress_Left.style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #5d2525 ), color-stop( 0.2, #a53939 ), color-stop( .5, #903030), to( #5d2525) )";
	HealthBarProgress_Right.style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #200d0d ), color-stop( 0.2, #2e1313 ), color-stop( .5, #291111), to( #200d0d) )";
	HealthRegenLabel.style.color = "white"
}

(function () {
	RecolorHealthBar();
	FindDotaHudElement('ManaRegenLabel').style.color = "white";

	var ButtonSwap = UpdateButtonSwapManaPosition(true); 
	
	ButtonSwap.FindChildTraverse("Mana").visible = false;
	ButtonSwap.FindChildTraverse("Stamina").visible = true;
	ButtonSwap.Mana = true;
	ButtonSwap.Stamina = false;

	ButtonSwap.SetPanelEvent('onmouseover', function () {
		if (ButtonSwap.stamina_description_tooltip){	
			ButtonSwap.stamina_description_tooltip.visible = true;
			$.DispatchEvent("DOTAShowTitleTextTooltip", ButtonSwap.stamina_description_tooltip, "#stamina_description_tooltip_name", "#stamina_description_tooltip")
		}
	});
	ButtonSwap.SetPanelEvent('onmouseout', function () {
		if (ButtonSwap.stamina_description_tooltip) {
			$.DispatchEvent("DOTAHideTitleTextTooltip");
			ButtonSwap.stamina_description_tooltip.visible = false;
		}
	});

	AutoUpdateManaBar();
	AutoUpdateHealthBar();
    AutoUpdateButtonPosition();
})

(function () {})