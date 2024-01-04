'use strict';

//Libraries
var PlayerTables = GameUI.CustomUIConfig().PlayerTables;
var _ = GameUI.CustomUIConfig()._;
var Options = GameUI.CustomUIConfig().Options;
var RegisterKeyBind = GameUI.CustomUIConfig().RegisterKeyBind;
var CommandEvents = GameUI.CustomUIConfig().CommandEvents;
var CustomHooks = GameUI.CustomUIConfig().CustomHooks;

var console = {
	log: function() {
		var args = Array.prototype.slice.call(arguments);
		return $.Msg(args.map(function(x) {return typeof x === 'object' ? JSON.stringify(x, null, 4) : x;}).join('\t'));
	},
	error: function() {
		var args = Array.prototype.slice.call(arguments);
		_.each(args, function(arg) {
			console.log(arg instanceof Error ? arg.stack : new Error(arg).stack);
		});
	}
};

var ServerAddress = false ? 'http://127.0.0.1:6502/' : 'https://stats.dota-aabs.com/';

var HERO_SELECTION_PHASE_NOT_STARTED = 0;
var HERO_SELECTION_PHASE_BANNING = 1;
var HERO_SELECTION_PHASE_HERO_PICK = 2;
var HERO_SELECTION_PHASE_STRATEGY = 3;
var HERO_SELECTION_PHASE_END = 4;

var DOTA_TEAM_SPECTATOR = 1;

var RUNES_COLOR_MAP = {
	0: 'FF7800',
	1: 'FFEC5E',
	2: 'F62817',
	3: 'FFD700',
	4: '8B008B',
	5: '7FFF00',
	6: 'FD3AFB',
	7: 'FF4D00',
	8: '0D0080',
	9: 'C800FF',
	10: '4A0746',
	11: 'B35F5F',
};

var DAMAGE_SUBTYPES = {
	DAMAGE_SUBTYPE_FIRE: "fire",
	DAMAGE_SUBTYPE_WATER: "water",
	DAMAGE_SUBTYPE_EARTH: "earth",
	DAMAGE_SUBTYPE_AIR: "air",
	DAMAGE_SUBTYPE_LIGHTING: "lighting",
	DAMAGE_SUBTYPE_DARK: "dark",
	DAMAGE_SUBTYPE_LIGHT: "light",
	DAMAGE_SUBTYPE_BLOOD: "blood",
	DAMAGE_SUBTYPE_POISON: "poison",
	DAMAGE_SUBTYPE_SOUND: "noise",
	DAMAGE_SUBTYPE_TECH: "tech",
	DAMAGE_SUBTYPE_ENERGY: "energy",
	DAMAGE_SUBTYPE_DEATH: "death",
	DAMAGE_SUBTYPE_VOID: "void",
	DAMAGE_SUBTYPE_ICE: "ice",
	DAMAGE_SUBTYPE_NATURE: "nature",

	/*"damage_subtype" "Подтип урона: "
		"DAMAGE_SUBTYPE_NONE" ""
		"DAMAGE_SUBTYPE_FIRE" "<font color='#fc0000'>Огонь"
		"DAMAGE_SUBTYPE_WATER" "<font color='#0019fc'>Вода"
		"DAMAGE_SUBTYPE_EARTH" "<font color='#913d00'>Земля"
		"DAMAGE_SUBTYPE_AIR" "<font color='#6b70ff'>Воздух"
		"DAMAGE_SUBTYPE_LIGHTING" "<font color='#f2ed50'>Молния"
		"DAMAGE_SUBTYPE_DARK" "<font color='#000'>Тьма"
		"DAMAGE_SUBTYPE_LIGHT" "<font color='#fff'>Свет"
		"DAMAGE_SUBTYPE_BLOOD" "<font color='#940000'>Кровь"
		"DAMAGE_SUBTYPE_POISON" "<font color='#009405'>Яд"
		"DAMAGE_SUBTYPE_SOUND" "<font color='#ded712'>Звук"
		"DAMAGE_SUBTYPE_MECH" "<font color='#595958	'>Технология"
		"DAMAGE_SUBTYPE_ENERGY" "<font color='#de07af'>Энергия"
		"DAMAGE_SUBTYPE_DEATH" "<font color='#4db83d'>Смерть"
		"DAMAGE_SUBTYPE_VOID" "<font color='#82298a'>Пустота"*/
}

String.prototype.endsWith = function(suffix) {
	return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

Entities.GetNetworkableEntityInfo = function(ent, key) {
	var t = GameUI.CustomUIConfig().custom_entity_values[ent];
	if (t != null) {
		return key == null ? t : t[key];
	}
};

Players.GetStatsData = function(playerId) {
	return PlayerTables.GetTableValue('stats_client', playerId) || {};
};

Players.GetHeroSelectionPlayerInfo = function(playerId) {
	return Players.IsValidPlayerID(playerId) ? PlayerTables.GetTableValue('hero_selection', Players.GetTeam(playerId))[playerId] : {};
};

function GetDataFromServer(path, params, resolve, reject) {
	var encodedParams = params == null ? '' : '?' + Object.keys(params).map(function(key) {
	    return encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
	}).join('&');
	$.AsyncWebRequest(ServerAddress + path + encodedParams, {
		type: 'GET',
		success: function(data) {
			if (resolve) resolve(data || {});
		},
		error: function(e) {
			if (reject) reject(e);
		}
	});
}

function IsHeroName(str) {
	return IsDotaHeroName(str) || IsArenaHeroName(str);
}

function IsBossName(str) {
	return str.lastIndexOf('npc_arena_boss_') === 0;
}

function IsDotaHeroName(str) {
	return str.lastIndexOf('npc_dota_hero_') === 0;
}

function IsArenaHeroName(str) {
	return str.lastIndexOf('npc_arena_hero_') === 0;
}

var bossesMap = {
	npc_arena_boss_freya: 'file://{images}/heroes/npc_arena_hero_freya.png',
	npc_arena_boss_zaken: 'file://{images}/heroes/npc_arena_hero_zaken.png',
};
function TransformTextureToPath(texture, optPanelImageStyle) {
	if (IsHeroName(texture)) {
		return optPanelImageStyle === 'portrait' ?
			'file://{images}/heroes/selection/' + texture + '.png' :
			optPanelImageStyle === 'icon' ?
				'file://{images}/heroes/icons/' + texture + '.png' :
				'file://{images}/heroes/' + texture + '.png';
	} else if (IsBossName(texture)) {
		return bossesMap[texture] || 'file://{images}/custom_game/units/' + texture + '.png';
	} else if (texture.lastIndexOf('npc_') === 0) {
		return optPanelImageStyle === 'portrait' ?
			'file://{images}/custom_game/units/portraits/' + texture + '.png' :
			'file://{images}/custom_game/units/' + texture + '.png';
	} else {
		return optPanelImageStyle === 'item' ?
			'raw://resource/flash3/images/items/' + texture + '.png' :
			'raw://resource/flash3/images/spellicons/' + texture + '.png';
	}
}

function GetHeroName(unit) {
	var data = GameUI.CustomUIConfig().custom_entity_values[unit || -1];
	return data != null && data.unit_name != null ? data.unit_name : Entities.GetUnitName(unit);
}

function SafeGetPlayerHeroEntityIndex(playerId) {
	var clientEnt = Players.GetPlayerHeroEntityIndex(playerId);
	return clientEnt === -1 ? (Number(PlayerTables.GetTableValue('player_hero_indexes', playerId)) || -1) : clientEnt;
}

function GetPlayerHeroName(playerId) {
	if (Players.IsValidPlayerID(playerId)) {
		//Is it causes lots of table copies? TODO: Check how that affects perfomance
		//return PlayerTables.GetTableValue("hero_selection", Players.GetTeam(playerId))[playerId].hero;
		return GetHeroName(SafeGetPlayerHeroEntityIndex(playerId));
	}
	return '';
}

function GetPlayerGold(unit) {
	return GetStackCountOfModifier("modifier_arena_hero_gold", unit);
}

function dynamicSort(property) {
	var sortOrder = 1;
	if (property[0] === '-') {
		sortOrder = -1;
		property = property.substr(1);
	}
	return function(a, b) {
		var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
		return result * sortOrder;
	};
}

function GetItemCountInInventory(nEntityIndex, itemName, bStash) {
	var counter = 0;
	var endPoint = 8;
	if (bStash)
		endPoint = 14;
	for (var i = endPoint; i >= 0; i--) {
		var item = Entities.GetItemInSlot(nEntityIndex, i);
		if (Abilities.GetAbilityName(item) === itemName && Items.GetPurchaser(item) === nEntityIndex)
			counter = counter + 1;
	}
	return counter;
}

function GetItemCountInCourier(nEntityIndex, itemName, bStash) {
	var courier = FindCourier(nEntityIndex);
	if (courier == null)
		return 0;
	var counter = 0;
	var endPoint = 8;
	if (bStash)
		endPoint = 14;
	for (var i = endPoint; i >= 0; i--) {
		var item = Entities.GetItemInSlot(courier, i);
		if (Abilities.GetAbilityName(item) === itemName && Items.GetPurchaser(item) === nEntityIndex)
			counter = counter + 1;
	}
	return counter;
}

const FindCourier = (unit) => { 
	const playerId = Entities.GetPlayerOwnerID(unit);
	return Entities.GetAllEntitiesByClassname('npc_dota_courier').find(
		courier => Entities.GetPlayerOwnerID(courier) === playerId
	);
};

function DynamicSubscribePTListener(table, callback, OnConnectedCallback) {
	if (PlayerTables.IsConnected()) {
		//$.Msg("Update " + table + " / PT connected")
		var tableData = PlayerTables.GetAllTableValues(table);
		if (tableData != null)
			callback(table, tableData, {});
		var ptid = PlayerTables.SubscribeNetTableListener(table, callback);
		if (OnConnectedCallback != null) {
			OnConnectedCallback(ptid);
		}
	} else {
		// $.Msg("Update " + table + " / PT not connected, repeat")
		$.Schedule(0.1, function() {
			DynamicSubscribePTListener(table, callback, OnConnectedCallback);
		});
	}
}

function DynamicSubscribeNTListener(table, callback, OnConnectedCallback) {
	var tableData = CustomNetTables.GetAllTableValues(table);
	if (tableData != null) {
		_.each(tableData, function(ent) {
			callback(table, ent.key, ent.value);
		});
	}
	var ptid = CustomNetTables.SubscribeNetTableListener(table, callback);
	if (OnConnectedCallback != null) {
		OnConnectedCallback(ptid);
	}
}

function GetDotaHud() {
	var p = $.GetContextPanel();
	while (true) {
		var parent = p.GetParent();
		if (parent == null)
			return p;
		else
			p = parent;
	}
}

function _DynamicMinimapSubscribe(minimapPanel, OnConnectedCallback) {
	_.each(Game.GetAllTeamIDs(), function(team) {
		DynamicSubscribePTListener('dynamic_minimap_points_' + team, function(tableName, changesObject, deletionsObject) {
			for (var index in changesObject) {
				var panel = $('#minimap_point_id_' + index);
				if (panel == null) {
					panel = $.CreatePanel('Panel', minimapPanel, 'minimap_point_id_' + index);
					panel.hittest = false;
					panel.AddClass('icon');
				}
				_.each(changesObject[index].styleClasses.split(' '), function(ss) {
					panel.AddClass(ss);
				});
				panel.style.position = changesObject[index].position + ' 0';
				panel.visible = changesObject[index].visible === 1;
			}
		}, OnConnectedCallback);
	});
}

function IsCursorOnPanel(panel) {
	var panelCoords = panel.GetPositionWithinWindow();
	var cursorPos = GameUI.GetCursorPosition();
	return cursorPos[0] > panelCoords.x && cursorPos[1] > panelCoords.y && cursorPos[0] < panelCoords.x + panel.actuallayoutwidth && cursorPos[1] < panelCoords.y + panel.actuallayoutheight;
}

function secondsToMS(seconds, bTwoChars) {
	var sec_num = parseInt(seconds, 10);
	var minutes = Math.floor(sec_num / 60);
	var seconds = Math.floor(sec_num - minutes * 60);

	if (bTwoChars && minutes < 10)
		minutes = '0' + minutes;
	if (seconds < 10)
		seconds = '0' + seconds;
	return minutes + ':' + seconds;
}

function AddStyle(panel, table) {
	for (var k in table) {
		panel.style[k] = table[k];
	}
}

function FindDotaHudElement(id) {
	return hud.FindChildTraverse(id);
}

function GetHEXPlayerColor(playerId) {
	var playerColor = Players.GetPlayerColor(playerId).toString(16);
	return playerColor == null ? '#000000' : ('#' + playerColor.substring(6, 8) + playerColor.substring(4, 6) + playerColor.substring(2, 4) + playerColor.substring(0, 2));
}

function shadeColor2(color, percent) {
	var f = parseInt(color.slice(1), 16),
		t = percent < 0 ? 0 : 255,
		p = percent < 0 ? percent * -1 : percent,
		R = f >> 16,
		G = f >> 8 & 0x00FF,
		B = f & 0x0000FF;
	return '#' + (0x1000000 + (Math.round((t - R) * p) + R) * 0x10000 + (Math.round((t - G) * p) + G) * 0x100 + (Math.round((t - B) * p) + B)).toString(16).slice(1);
}

function FormatGold(value) {
	return (GameUI.IsAltDown() ? value : value > 9999999 ? (value/1000000).toFixed(2) + 'M' : value > 99999 ? (value/1000).toFixed(1) + 'k' : value)
		.toString();
}

function SortPanelChildren(panel, sortFunc, compareFunc) {
	var tlc = panel.Children().sort(sortFunc);
	_.each(tlc, function(child) {
		for (var k in tlc) {
			var child2 = tlc[k];
			if (child !== child2 && compareFunc(child, child2)) {
				panel.MoveChildBefore(child, child2);
				break;
			}
		}
	});
};

function GetTeamInfo(team) {
	var t = PlayerTables.GetTableValue('teams', team) || {};
	return {
		score: t.score || 0,
		kill_weight: t.kill_weight || 1,
	};
}

function SetPagePlayerLevel(ProfileBadge, level) {
	var levelbg = Math.floor(level / 100);
	ProfileBadge.FindChildTraverse('BackgroundImage').SetImage('file://{images}/profile_badges/bg_' + ('0' + (levelbg + 1)).slice(-2) + '.psd');
	ProfileBadge.FindChildTraverse('ItemImage').SetImage('file://{images}/profile_badges/level_' + ('0' + (level - levelbg * 100)).slice(-2) + '.png');
	ProfileBadge.FindChildTraverse('ProfileLevel').SetImage('file://{images}/profile_badges/bg_number_01.psd');
	ProfileBadge.FindChildTraverse('ProfileLevel').GetChild(0).text = level;
}

function FindFountain(team) {
	return Entities.GetAllEntitiesByName('npc_arena_fountain_' + team)[0];
}

function GetVisibleAbilityInSlot(unit, slot) {
	var j = 0;
	for (var i = 0; i < Entities.GetAbilityCount(unit); i++) {
		var ability = Entities.GetAbility(unit, i);
		if (!Abilities.IsHidden(ability)) {
			if (j++ === slot) {
				return ability;
			}
		}
	}
}

function NumberReduction(num, tofix, afterPoint){
	if (!afterPoint) afterPoint = 1
	//$.Msg(typeof(num))
	if (!tofix) tofix = 0
	if (typeof(num) != "number") return 0
	if (num >= 10000 * afterPoint) {
		var i = 0
	  	var _num = num
	  	while((_num / 1000) >= 1) {
			i++
			_num = _num / 1000
	  	}
	  	var k = ""
	  	for (var a = 0; a < i; a++){
			k = k + "k"
	  	}
	  	num = (num / Math.pow(1000, i)).toFixed(1) + k
		return num
	}
	//$.Msg(num)
	return num.toFixed(tofix)
}

function print(value) {
	$.Msg(value)
}

function PrintError(err, txt) {
	return $.Msg(`${(new Date()).toString()} | ${err.stack}`+(txt != undefined ? txt : ""));
};

function GetHUDSeed () {
	return 1080 / Game.GetScreenHeight();
};
function CorrectPositionValue (value) {
	return GetHUDSeed() * (value || 0);
};

function transformObjectToArray(obj) {
    if (!obj) {
        return [];
    }

    if (Array.isArray(obj)) {
        return obj;
    }

    var arr = [];
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            arr.push(obj[key]);
        }
    }

    return arr;
}

function GetStackCountOfModifier(modifierName, unit) {
	if (!unit) return 0;
	for (var i = 0; i < Entities.GetNumBuffs(unit); i++) {
		var buff = Entities.GetBuff(unit, i);
		if (buff !== -1) {
			var buffName = Buffs.GetName(unit, buff);
			if (buffName == modifierName) {
				return Buffs.GetStackCount(unit, buff);
			}
		}
	}
	return 0;
}

if (CommandEvents) CommandEvents.RegisterKeyBinds();

var hud = GetDotaHud();