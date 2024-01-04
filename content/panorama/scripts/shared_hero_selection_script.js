var HeroesData = {},
	SelectedHeroName = '',
	BannedHeroes = [],
	LocalPlayerStatus = {};
DynamicSubscribePTListener('hero_selection_heroes_data', function(tableName, changesObject, deletionsObject) {
	HeroesData = changesObject;
	//if (OnRecieveHeroesData) OnRecieveHeroesData();
});

function IsHeroPicked(name) {
	var hero_selection_table = PlayerTables.GetAllTableValues('hero_selection');
	if (hero_selection_table != null) {
		for (var teamKey in hero_selection_table) {
			for (var playerIdInSelection in hero_selection_table[teamKey]) {
				if (hero_selection_table[teamKey][playerIdInSelection].hero === name && hero_selection_table[teamKey][playerIdInSelection].status === 'picked') {
					return true;
				}
			}
		}
	}
	return false;
}

function IsHeroLocked(name) {
	var hero_selection_table = PlayerTables.GetAllTableValues('hero_selection');
	if (hero_selection_table != null) {
		for (var teamKey in hero_selection_table) {
			for (var playerIdInSelection in hero_selection_table[teamKey]) {
				if (hero_selection_table[teamKey][playerIdInSelection].hero === name && hero_selection_table[teamKey][playerIdInSelection].status === 'locked') {
					return true;
				}
			}
		}
	}
	return false;
}

function IsHeroBanned(name) {
	return BannedHeroes.indexOf(name) !== -1;
}

function IsHeroUnreleased(name) {
	return HeroesData[name] && HeroesData[name].Unreleased;
}

function IsHeroDisabledInRanked(name) {
	return HeroesData[name] && HeroesData[name].DisabledInRanked && Options.IsEquals('EnableRatingAffection');
}

function IsLocalHeroPicked() {
	return (LocalPlayerStatus || Players.GetHeroSelectionPlayerInfo(Game.GetLocalPlayerID())).status === 'picked';
}

function IsLocalHeroLocked() {
	return (LocalPlayerStatus || Players.GetHeroSelectionPlayerInfo(Game.GetLocalPlayerID())).status === 'locked';
}

function IsLocalHeroLockedOrPicked() {
	return IsLocalHeroPicked() || IsLocalHeroLocked();
}

var PreviousSearchText = '';
function SearchHero() {
	if ($('#HeroSearchTextEntry') != null) {
		var SearchString = $('#HeroSearchTextEntry').text.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
		if (PreviousSearchText !== SearchString) {
			PreviousSearchText = SearchString;
			$.GetContextPanel().SetHasClass('SearchingHeroes', SearchString.length > 0);

			if (SearchString.length > 0) {
				var matchRegexp = new RegExp(SearchString, 'i');
				var first;
				for (var key in HeroesPanels) {
					var heroName = $.Localize('#' + HeroesPanels[key].id.replace('HeroListPanel_element_', ''));
					var high = matchRegexp.test(heroName);
					HeroesPanels[key].SetHasClass('Highlighted', high);
					if (high && !first) first = HeroesPanels[key];
				}
				if (first != null) {
					first.SelectHeroAction();
				}
			} else {
				for (var key in HeroesPanels) {
					HeroesPanels[key].RemoveClass('Highlighted');
				}
			}
		}
	}
}

function FillHeroesTable(heroList, panel, big) {
	_.each(heroList, function(heroName) {
		var heroData = HeroesData[heroName];
		var StatPanel = panel.FindChildTraverse('HeroesByAttributes_' + heroData.attributes.attribute_primary);
		//$.Msg(StatPanel)

		var HeroCard = $.CreatePanel('Panel', StatPanel, 'HeroListPanel_element_' + heroName);
		HeroCard.BLoadLayoutSnippet('HeroCard');
		HeroCard.FindChildTraverse('HeroImage').SetImage(TransformTextureToPath(heroName, 'portrait'));
		if (!heroData.isChanged) {
			// HeroCard.FindChildTraverse('HeroChangedBurstRoot').CreateChildren('<DOTAScenePanel map="scenes/hud/levelupburst" hittest="false" />');
			// $.CreatePanel('DOTAScenePanel', HeroCard.FindChildTraverse('HeroChangedBurstRoot'), '', {map: "scenes/hud/levelupburst", hittest: 'false'})
			HeroCard.RemoveClass('IsChanged');
		}
		if (heroData.linkedColorGroup) {
			HeroCard.AddClass('HasLinkedColorGroup');
			HeroCard.FindChildTraverse('LinkedHeroesGroupRow').style.backgroundColor = heroData.linkedColorGroup;
		}
		var SelectHeroAction = (function() {
			if (SelectedHeroPanel !== HeroCard) {
				SelectedHeroName = heroName;
				if (SelectedHeroPanel != null) {
					SelectedHeroPanel.RemoveClass('HeroPanelSelected');
				}
				HeroCard.AddClass('HeroPanelSelected');
				SelectedHeroPanel = HeroCard;
				ChooseHeroPanelHero();
			}
		});
		var HitTarget = HeroCard.FindChildTraverse('HitTarget');
		HitTarget.SetPanelEvent('onactivate', SelectHeroAction);
		HitTarget.SetPanelEvent('oninputsubmit', SelectHeroAction);
		HitTarget.SetPanelEvent('onmouseover', function() {
			if (IsDotaHeroName(heroName)) HeroCard.FindChildTraverse('HeroMovie').heroname = heroName;
			HeroCard.AddClass('Expanded');
		});
		HitTarget.SetPanelEvent('onmouseout', function() {
			if (IsDotaHeroName(heroName)) HeroCard.FindChildTraverse('HeroMovie').heroname = null;
			HeroCard.RemoveClass('Expanded');
		});
		HeroCard.FindChildTraverse('HeroName').text = $.Localize('#' + heroName);
		HeroCard.SelectHeroAction = SelectHeroAction;
		HeroesPanels.push(HeroCard);
	});

	/*var attributes_panel = rootPanel.FindChildTraverse('SelectedHeroAttributesPanel');
	attributes_panel.ClearPanelEvent('onmouseover');
	attributes_panel.ClearPanelEvent('onmouseout');

	var ability_damage_subtypes_tooltip = $.CreatePanel('Panel', $.GetContextPanel(), '');
	
	attributes_panel.SetPanelEvent('onmouseover', function() {
		var unit_ = heroName
		//$.Msg(unit_)
		var units_subtypes_resistance = GameUI.CustomUIConfig().units_subtypes_resistance[unit_];

		var cursor_position = {x: GameUI.GetCursorPosition()[0], y: GameUI.GetCursorPosition()[1]};
		$.Msg(GameUI.GetCursorPosition())
		ability_damage_subtypes_tooltip.style.position = (cursor_position.x) + "px 0 " + (cursor_position.y) + "px"
		ability_damage_subtypes_tooltip.style.tooltipPosition = 'bottom';
		ability_damage_subtypes_tooltip.visible = true;

		for (var keys in DAMAGE_SUBTYPES) {
			ability_damage_subtypes_tooltip.SetDialogVariable(DAMAGE_SUBTYPES[keys], "0%");
		}
		if (units_subtypes_resistance) {
			for (var keys in units_subtypes_resistance) {
				var damsubres = units_subtypes_resistance[keys]
				//$.Msg(keys + ", " + damsubres)
				ability_damage_subtypes_tooltip.SetDialogVariable(DAMAGE_SUBTYPES[keys], damsubres + "%");
			}
		}
		$.DispatchEvent("DOTAShowTitleTextTooltip", ability_damage_subtypes_tooltip, "#damage_subtype_resistance", "#damage_subtype_resistance_list")
		//$.Msg("1")
	});
	attributes_panel.SetPanelEvent('onmouseout', function() {
		if (ability_damage_subtypes_tooltip) {
			$.DispatchEvent("DOTAHideTitleTextTooltip");
			ability_damage_subtypes_tooltip.visible = false;
		}
	});*/
}

function SelectFirstHeroPanel() {
	var p;
	for (var key in HeroesPanels) {
		var heroName = HeroesPanels[key].id.replace('HeroListPanel_element_', '');
		if (heroName === 'npc_dota_hero_abaddon') {
			p = HeroesPanels[key];
		}
	}
	if (p == null) {
		for (var key in HeroesPanels) {
			return HeroesPanels[key].SelectHeroAction();
		}
	}
	return p.SelectHeroAction();
}

function ChooseHeroUpdatePanels() {
	var selectedHeroData = HeroesData[SelectedHeroName];
	UpdateSelectionButton();
	var context = $.GetContextPanel();
	$('#SelectedHeroSelectHeroName').text = $.Localize('#' + SelectedHeroName);
	var hype = $.Localize('#' + SelectedHeroName + '_hype');
	//$.Msg(hype)
	hype = hype.replace(/<b>/g, '')
	hype = hype.replace(/<\/b>/g, '')
	//$.Msg(hype)
	$('#SelectedHeroOverview').text = hype
	context.SetHasClass('HoveredHeroHasLinked', selectedHeroData.linked_heroes != null);
	if (selectedHeroData.linked_heroes != null) {
		var linked = [];
		_.each(selectedHeroData.linked_heroes, function(hero) {
			linked.push($.Localize('#' + hero));
		});
		$('#SelectedHeroLinkedHero').text = linked.join(', ');
	}
	$('#SelectedHeroAbilitiesPanelInner').RemoveAndDeleteChildren();

	$('#SelectedHeroDisabledReason').text = IsHeroUnreleased(SelectedHeroName) ?
		$.Localize('#' + 'hero_selection_disabled_reason_unreleased') : IsHeroDisabledInRanked(SelectedHeroName) ?
			$.Localize('#' + 'hero_selection_disabled_reason_disabled_in_ranked') : '';
	FillAbilitiesUI($('#SelectedHeroAbilitiesPanelInner'), selectedHeroData.abilities, 'SelectedHeroAbility');
	FillAttributeUI($('#HeroListControlsGroup3'), selectedHeroData.attributes, SelectedHeroName);

	//var abilities = FindDotaHudElement('SelectedHeroAbilitiesPanelInner').Children()
		//$.Msg(abilities)
		/*if (abilities) {
			for (var i = 0; i < abilities.length; i++){
			var ability_image = abilities[i]
			ability_image.SetPanelEvent('onmouseover', function() {
				var ability_tooltip =  FindDotaHudElement('DOTAAbilityTooltip')
				if (!ability_tooltip) return
				$.Msg(ability_tooltip)
				var description = ability_tooltip.FindChildTraverse('AbilityDescriptionContainer').Children()[0]
				//$.Msg(description)
				description.visible = false
				var ability_name = ability_tooltip.FindChildTraverse("AbilityName").text
				var ability_damage_subtypes = GameUI.CustomUIConfig().ability_damage_subtypes
				var subtype
				for (var keys in ability_damage_subtypes){
					//$.Msg($.Localize("#DOTA_Tooltip_ability_"+keys).toLowerCase())
					if ($.Localize("#DOTA_Tooltip_ability_"+keys).toLowerCase() == ability_name.toLowerCase()) {
						subtype = $.Localize('#'+ability_damage_subtypes[keys]._)
						//$.Msg('#'+subtype)
						$.Msg(ability_name)
						break;
					}
				}
				if (subtype) {
					//$.DispatchEvent('DOTAHideAbilityTooltip', "");
					if (description) {
						var text = description.text
						var _subtype_localization = $.Localize('#damage_subtype')
						description.text = text + '\n'+_subtype_localization + subtype
						//$.Msg(ability_tooltip.FindChildTraverse('AbilityDescriptionContainer').FindChildrenWithClassTraverse('Active')[0].text)
					}
				}
				description.visible = true
			});
		}}*/
}

function FillAbilitiesUI(rootPanel, abilities, className) {
	_.each(abilities, function(abilityName) {
		var abilityPanel = $.CreatePanel('DOTAAbilityImage', rootPanel, '');
		abilityPanel.AddClass(className);
		abilityPanel.abilityname = abilityName;
		abilityPanel.SetPanelEvent('onmouseover', function() {
			$.DispatchEvent('DOTAShowAbilityTooltip', abilityPanel, abilityName);
		});
		abilityPanel.SetPanelEvent('onmouseout', function() {
			$.DispatchEvent('DOTAHideAbilityTooltip', abilityPanel);
		});
	});
}

function FillAttributeUI(rootPanel, attributesData, heroName) {
	$.Msg("1")
	for (var i = 2; i >= 0; i--) {
		rootPanel.FindChildTraverse('DotaAttributePic_' + (i + 1)).SetHasClass('PrimaryAttribute', Number(attributesData.attribute_primary) === i);
		rootPanel.FindChildTraverse('HeroAttributes_' + (i + 1)).text = attributesData['attribute_base_' + i] + ' + ' + Number(attributesData['attribute_gain_' + i]).toFixed(1);
	}
	rootPanel.FindChildTraverse('HeroAttributes_damage').text = attributesData.damage_min + ' - ' + attributesData.damage_max;
	rootPanel.FindChildTraverse('HeroAttributes_speed').text = attributesData.movespeed;
	rootPanel.FindChildTraverse('HeroAttributes_armor').text = Number(attributesData.armor).toFixed(1);
	rootPanel.FindChildTraverse('HeroAttributes_bat').text = Number(attributesData.attackrate).toFixed(1);
}

function SwitchTab() {
	SelectHeroTab(SelectedTabIndex === 1 ? 2 : 1);
}

function SelectHeroTab(tabIndex) {
	if (SelectedTabIndex !== tabIndex) {
		if (SelectedTabIndex != null) {
			$('#HeroListPanel_tabPanels_' + SelectedTabIndex).visible = false;
		}
		$('#HeroListPanel_tabPanels_' + tabIndex).visible = true;
		$('#SwitchHeroesButton').RemoveClass('ActiveTab' + SelectedTabIndex);
		$('#SwitchHeroesButton').AddClass('ActiveTab' + tabIndex);
		SelectedTabIndex = tabIndex;
	}
}

function ClearSearch() {
	$.DispatchEvent('DropInputFocus', $('#HeroSearchTextEntry'));
	$('#HeroSearchTextEntry').text = '';
}

function ListenToBanningPhase() {
	DynamicSubscribePTListener('hero_selection_banning_phase', function(tableName, changesObject, deletionsObject) {
		for (var hero in changesObject) {
			var heroPanel = $('#HeroListPanel_element_' + hero);
			if (Number(changesObject[hero]) === Game.GetLocalPlayerID()) {
				HasBanPoint = false;
				if (UpdateSelectionButton) UpdateSelectionButton();
			}
			if (heroPanel) heroPanel.AddClass('Banned');
			BannedHeroes.push(hero);
		}
		for (var hero in deletionsObject) {
			var heroPanel = $('#HeroListPanel_element_' + hero);
			if (heroPanel) heroPanel.RemoveClass('Banned');
			var index = BannedHeroes.indexOf(hero);
			if (index > -1) BannedHeroes.splice(index, 1);
		}
	});
}
