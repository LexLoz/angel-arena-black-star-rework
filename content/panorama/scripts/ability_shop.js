var DOTA_ACTIVE_GAMEMODE_TYPE = null;
var AbilityShopData = {};
var AllAbilityPanels = [];
var ParsedAbilityData = {};
var SelectedTabIndex = null;
var SearchingFor = '';
var SearchingPurchasedChecked = false;
var SearchingAbLevels = null;
var SelectedHeroPanel = null;
var SelectedHeroData = null;
var HeroImagePanels = [{}, {}]

function GetLocalAbilityNamesInfo() {
	var ab = {};
	var hero = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID());
	for (var i = 0; i < Entities.GetAbilityCount(hero); ++i) {
		var ability = Entities.GetAbility(hero, i);
		if (ability !== -1 && !Abilities.IsHidden(ability)) {
			ab[Abilities.GetAbilityName(ability)] = {
				level: Abilities.GetLevel(ability),
				maxLevel: Abilities.GetMaxLevel(ability)
			};
		}
	}
	return ab;
}

function GetBannedAbilities() {
	var b = [];
	for (var a in GetLocalAbilityNamesInfo()) {
		var abinf = ParsedAbilityData[a];
		if (abinf != null)
			for (var v in abinf.banned_with)
				if (b.indexOf(abinf.banned_with[v]) === -1)
					b.push(abinf.banned_with[v]);
	}
	return b;
}

function CreateSnippet_Ability(panel, abilityname, heroname, cost, heroIndex, tabIndex, abIndex, isClosed) {
	// print(heroIndex)
	// print(tabIndex)
	// print(abIndex)
	// print(cost)
	panel.abilityname = abilityname;
	panel.heroname = heroname;
	panel.BLoadLayoutSnippet('Ability');

	let _cost = +panel.FindChildTraverse('PointCost').text;
	// panel.original_cost = cost;
	panel.FindChildTraverse('PointCost').text = isClosed ? _cost : cost || cost;
	panel.FindChildTraverse('AbilityImage').abilityname = abilityname;
	panel.SetPanelEvent('onmouseover', function () {
		$.DispatchEvent('DOTAShowAbilityTooltip', panel, abilityname);
	});
	panel.SetPanelEvent('onmouseout', function () {
		$.DispatchEvent('DOTAHideAbilityTooltip', panel);
	});
	panel.SetPanelEvent('onactivate', function () {
		if (GameUI.IsShiftDown()) {
			// if (isClosed)
				// panel.FindChildTraverse('PointCost').text = panel.original_cost;

			GameEvents.SendCustomGameEventToServer('ability_shop_sell', {
				ability: abilityname,
				hero: heroIndex,
				tab: tabIndex,
				index: abIndex,
			});
		} else if (!panel.BHasClass('MaxUpgraded')) {
			// if (isClosed)
				// panel.FindChildTraverse('PointCost').text = _cost * 2;

			GameEvents.SendCustomGameEventToServer('ability_shop_buy', {
				ability: abilityname,
				hero: heroIndex,
				tab: tabIndex,
				index: abIndex,
			});
		}
	});
	panel.SetPanelEvent('oncontextmenu', function () {
		if (GameUI.IsShiftDown()) {
			// if (isClosed)
				// panel.FindChildTraverse('PointCost').text = panel.original_cost;

			GameEvents.SendCustomGameEventToServer('ability_shop_downgrade', {
				ability: abilityname,
				hero: heroIndex,
				tab: tabIndex,
				index: abIndex,
			});
		} else if (!panel.BHasClass('MaxUpgraded')) {
			// if (isClosed)
				// panel.FindChildTraverse('PointCost').text = _cost * 2;

			GameEvents.SendCustomGameEventToServer('ability_shop_buy', {
				ability: abilityname,
				hero: heroIndex,
				tab: tabIndex,
				index: abIndex,
			});
		}
	});
	return panel;
}

function Search() {
	var abLevels = GetLocalAbilityNamesInfo();
	var SearchText = $('#SearchBar').text.toLowerCase();
	if (SearchingFor !== SearchText || SearchingPurchasedChecked !== $('#PurchasedAbilitiesToggle').checked || !_.isEqual(SearchingAbLevels, abLevels)) {
		SearchingFor = SearchText;
		SearchingPurchasedChecked = $('#PurchasedAbilitiesToggle').checked;
		SearchingAbLevels = abLevels;
		var ShopSearchOverlay = $('#MainSearchRoot');
		_.each(ShopSearchOverlay.Children(), function (child) {
			var index = AllAbilityPanels.indexOf(child);
			if (index > -1) {
				child.visible = false;
				AllAbilityPanels.splice(index, 1);
			}
		});
		ShopSearchOverlay.RemoveAndDeleteChildren();
		var ShowSearch = SearchText.length > 0 || SearchingPurchasedChecked;
		$.GetContextPanel().SetHasClass('InSearchMode', ShowSearch);
		if (ShowSearch) {
			var FoundAbilities = [];
			if (AbilityShopData) {
				_.each(AbilityShopData, function (tabContent, tindex) {
					_.each(tabContent, function (heroData, hindex) {
						// print(hindex)
						var hero = heroData.heroKey;
						_.each(heroData.abilities, function (abilityData, aindex) {
							if ((hero.toLowerCase().indexOf(SearchText) !== -1 || abilityData.ability.toLowerCase().indexOf(SearchText) !== -1 || $.Localize('#' + hero.toLowerCase()).toLowerCase().indexOf(SearchText) !== -1 || $.Localize(abilityData.ability.toLowerCase()).toLowerCase().indexOf(SearchText) !== -1) && (!SearchingPurchasedChecked || (SearchingPurchasedChecked && abLevels[abilityData.ability] != null))) {
								FoundAbilities.push({
									name: abilityData.ability,
									data: abilityData,
									hero: hero,
									heroIndex: hindex,
									tableIndex: tindex,
									abilityIndex: aindex,
								});
							}
						});
					});
				});
			}
			_.each(_.sortBy(FoundAbilities, 'name'), function (abilityInfo) {
				AllAbilityPanels.push(CreateSnippet_Ability($.CreatePanel('Panel', ShopSearchOverlay, ''), abilityInfo.name, abilityInfo.hero, abilityInfo.data.cost, abilityInfo.heroIndex, abilityInfo.tableIndex, abilityInfo.abilityIndex));
			});
		}
	}
}

function CalculateDowngradeCost(abilityname, upgradecost) {
	return 150 + (upgradecost * 2 * (Math.floor((Game.GetDOTATime(false, false)) / 60) ** 1.1));
}

function UpdateAbilities() {
	var points = Entities.GetAbilityPoints(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()));
	$('#InfoContainerPointsLabel').text = '+' + points;
	var abLevels = GetLocalAbilityNamesInfo();
	var banned_with = GetBannedAbilities();
	_.each(AllAbilityPanels, function (panel) {
		var abilityname = panel.abilityname;
		var purchasedInfo = abLevels[abilityname];
		var cost = Number(panel.FindChildTraverse('PointCost').text);
		panel.SetHasClass('NoPoints', cost > points);
		panel.SetHasClass('Purchased', purchasedInfo != null);
		if (purchasedInfo != null) {
			panel.SetHasClass('MaxUpgraded', purchasedInfo.level == purchasedInfo.maxLevel);
			panel.FindChildTraverse('AbilityLevel').text = 'x' + purchasedInfo.level;
		} else
			panel.RemoveClass('MaxUpgraded');

		if (panel.BHasClass('Purchased') && GameUI.IsShiftDown()) {
			panel.AddClass('CanDelete');
			panel.FindChildTraverse('SellReturn').text = '+' + cost;
			panel.FindChildTraverse('SellCost').text = '-' + NumberReduction(CalculateDowngradeCost(abilityname, cost));

			/*GameEvents.SendEventClientSide("dota_hud_error_message", {
				"splitscreenplayer": 0,
				"reason": 80,
				"message": "#dota_hud_error_not_enough_gold"
			});
			Game.EmitSound("General.NoGold")*/
		} else
			panel.RemoveClass('CanDelete');
		panel.SetHasClass('Banned', banned_with.indexOf(abilityname) !== -1);
	});
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

function UpdateHeroAbilityList(hero, tab) {
	var abilities = HeroImagePanels[tab][hero]
	// print(abilities)
	var abilitiesroot = $('#HeroAbilitiesRoot');
	_.each(abilitiesroot.Children(), function (child) {
		var index = AllAbilityPanels.indexOf(child);
		if (index > -1) {
			child.visible = false;
			AllAbilityPanels.splice(index, 1);
		}
	});
	abilitiesroot.RemoveAndDeleteChildren();

	_.each(abilities, function (abilityInfo) {
		// $.Msg(abilityInfo.cost)
		AllAbilityPanels.push(CreateSnippet_Ability($.CreatePanel('Panel', abilitiesroot, ''), abilityInfo.ability, hero, abilityInfo.cost, abilityInfo.heroIndex, abilityInfo.tableIndex, abilityInfo.abilityIndex));
	});

	UpdateAbilities();
}

function Fill(heroesData, panel, tab) {
	/*for (var heroKey in changesObject[tab]) {
		var hero = changesObject[tab][heroKey].heroKey;

		/*var abs = changesObject[tab][heroKey].abilities;
		for (var ability in abs) {
			abs[ability].ability
		}
	}*/
	// print(typeof(heroesData))
	HeroImagePanels[tab] = {};
	for (var herokey in heroesData) {
		var heroData = heroesData[herokey];
		// print(HeroImagePanels[tab].length);
		var StatPanel = panel.FindChildTraverse('HeroesByAttributes_' + heroData.attribute_primary);
		HeroImagePanels[tab][herokey] = heroData.abilities;
		var HeroImagePanel = $.CreatePanel('Image', StatPanel, 'HeroListPanel_element_' + heroData.heroKey)
		HeroImagePanel.SetImage(TransformTextureToPath(heroData.heroKey));
		HeroImagePanel.AddClass('HeroListElement');
		if (heroData.isChanged) {
			HeroImagePanel.AddClass('ChangedHeroPanel');
		}
		var SelectHeroAction = (function (_herokey, _panel, _tab) {
			return function () {
				if (SelectedHeroPanel !== _panel) {
					if (SelectedHeroPanel != null) {
						SelectedHeroPanel.RemoveClass('HeroPanelSelected');
					}
					_panel.AddClass('HeroPanelSelected');
					SelectedHeroPanel = _panel;
					UpdateHeroAbilityList(_herokey, _tab);
				}
				return "smth"
			};
		})(herokey, HeroImagePanel, tab); 
		// print(SelectHeroAction())

		HeroImagePanel.SetPanelEvent('onactivate', SelectHeroAction
			// function () {
			// 	print('click')
			// 	if (SelectedHeroPanel !== HeroImagePanel) {
			// 		if (SelectedHeroPanel != null) {
			// 			SelectedHeroPanel.RemoveClass('HeroPanelSelected');
			// 		}
			// 		HeroImagePanel.AddClass('HeroPanelSelected');
			// 		SelectedHeroPanel = HeroImagePanel;
			// 		UpdateHeroAbilityList(herokey, heroData.abilities);
			// 	}
			// }
		);
		HeroImagePanel.SelectHeroAction = SelectHeroAction;
		for (var k in heroData.abilities) {
			var abinf = heroData.abilities[k];
			ParsedAbilityData[abinf.ability] = abinf;
		}
	}
}

(function () {
	DynamicSubscribePTListener('ability_shop_data', function (tableName, changesObject, deletionsObject) {
		$('#AbilityShopBase').visible = true;
		AbilityShopData = changesObject;
		for (var tab in changesObject) {
			var TabHeroesPanel = $.CreatePanel('Panel', $('#MainHeroesList'), 'HeroListPanel_tabPanels_' + tab);
			TabHeroesPanel.BLoadLayoutSnippet('HeroesPanel');
			TabHeroesPanel.visible = false;
			// print(changesObject[tab])
			Fill(changesObject[tab], TabHeroesPanel, tab - 1);
		}
		SelectHeroTab(1);
	});
	Game.DisableWheelPanels.push($('#MainContainer'));

	(function autoUpdate() {
		Search();
		UpdateAbilities();
		$('#ShiftStateLabel').text = $.Localize(GameUI.IsShiftDown() ? '#ability_shop_shift_yes' : '#ability_shop_shift_no');
		$.Schedule(0.15, autoUpdate);
	})();
})();
