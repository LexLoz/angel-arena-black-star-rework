Game.Events = {};
var contextPanel = $.GetContextPanel();

function GetCommandName(name) {
	return 'arena_hotkey_' + _.snakeCase(name) + '_' + Date.now() + Math.random();
}

function GetKeyBind(name) {
	$.CreatePanel("DOTAHotkey", contextPanel, "hotkey", {keybind: name});
	var keyElement = contextPanel.GetChild(contextPanel.GetChildCount() - 1);
	keyElement.DeleteAsync(0);
	return keyElement.GetChild(0).text;
}

function RegisterKeyBindHandler(name) {
	Game.Events[name] = {};
	Game.AddCommand(GetCommandName(name), function() {
		$.Msg('command')
		for (var key in Game.Events[name]) {
			Game.Events[name][key]();
		}
	}, '', 0);
}

function RegisterKeyBind(name, callback) {
	//$.Msg(Game.Events[name])
	if (Game.Events[name] == null) {
		//RegisterKeyBindHandler(name);
		Game.Events[name] = true;
		var key = GetKeyBind(name)
		print(key)
		if (key !== '') {
			//print('register')
			Game.CreateCustomKeyBind(key, GetCommandName(name));
			Game.AddCommand(GetCommandName(name), function() {
				callback();
				print('command')
			}, "", 0);
			print(GetCommandName(name))
			//print(key)
		}
	}

	//$.Msg(name)
	//$.Msg(callback.name)
	//Game.Events[name][callback.name] = callback;
};

GameUI.CustomUIConfig().RegisterKeyBind = RegisterKeyBind;
