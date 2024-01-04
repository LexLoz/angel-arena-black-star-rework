function Console(panel) {
	this.panel = panel;
	this.codeEntry = panel.FindChildrenWithClassTraverse('content__entry')[0];
	this.stackLabel = panel.FindChildrenWithClassTraverse('content__stack')[0];
	this.playerList = panel.FindChildrenWithClassTraverse('header__js-player')[0];
	this.header = panel.FindChildrenWithClassTraverse('header__top')[0];

	var think = (function() {
		this.updateHeroes();
		$.Schedule(1, think);
	}).bind(this);
	think();

	this.setPinned(false);

	$.RegisterEventHandler('DragStart', this.header, this.onDragStart.bind(this));
	$.RegisterEventHandler('DragEnd', this.header, this.onDragEnd.bind(this));

	GameEvents.Subscribe('console-stack', function(event) {
		this.setStack(event.stack);
	}.bind(this));

	GameEvents.Subscribe('console-set-visible', function(event) {
		this.setVisible(event.value != null ? event.value : !this.isVisible());
	}.bind(this));
}

Console.prototype.setPinned = function(pinned) {
	this.header.SetDraggable(!pinned);
};

Console.prototype.isVisible = function() {
	return this.panel.BHasClass('console_visible');
};

Console.prototype.setVisible = function(visible) {
	this.panel.SetHasClass('console_visible', visible);
	if (visible && !this.opened) {
		this.opened = true;
		$.Schedule(1 / 30, (function() {
			// Save center position and reset it to fix dragging offset
			this.panel.style.position = this.panel.actualxoffset.toFixed(5) + 'px ' + this.panel.actualyoffset.toFixed(5) + 'px 0';
			this.panel.style.align = 'left top';
		}).bind(this));
	}
};

Console.prototype.setStack = function(stack) {
	this.stackLabel.text = '>>>\n' + stack;
};

Console.prototype.onDragStart = function(panelId, event) {
	event.displayPanel = this.panel;

	var cursor = GameUI.GetCursorPosition();

	event.offsetX = cursor[0] - this.panel.actualxoffset;
	event.offsetY = cursor[1] - this.panel.actualyoffset;
	event.removePositionBeforeDrop = false;
	return false;
};

Console.prototype.onDragEnd = function() {
	this.panel.SetParent($.GetContextPanel());
	this.setPinned(false);
	return true;
};

Console.prototype.updateHeroes = function() {
	var lines = _.map(Game.GetAllPlayerIDs(), function(playerId) {
		var team = Players.GetTeam(playerId);
		var line = '';
		line += playerId + ': ' + $.Localize(GetPlayerHeroName(playerId)) + ' - ' + Players.GetPlayerName(playerId);
		return line;
	});

	var generated = _.map(this.playerList.AccessDropDownMenu().Children(), function(panel) {
		return panel.text;
	});

	var playerList = this.playerList;

	if (!_.isEqualWith(generated, lines, _.isMatch)) {
		/**
		 * Regenerate all options if some are not matching
		 * Required to have consistent order
		 * TODO: More performant panel sorting with AddOption and RemoveOption
		 */

		playerList.RemoveAllOptions();

		_.each(lines, function(line) {
			var label = $.CreatePanel('Label', playerList, line.split(':')[0]);
			label.text = line;
			playerList.AddOption(label);
		});

		playerList.SetSelected(lines[0].split(':')[0]);
	}
};

Console.prototype.getCode = function() {
	return this.codeEntry.text;
};

Console.prototype.sendLua = function() {
	GameEvents.SendCustomGameEventToServer('console-evaluate', {
		type: 'lua',
		code: this.getCode(),
	})
};

Console.prototype.exec = function(code) {
	$.CreatePanel("Panel", $("#TempPanelsContainer"), "", {hittest: "false", style: "visibility: collapse;", onload: code});
	for (let i=0; i<$("#TempPanelsContainer").GetChildCount(); i++) {
		$("#TempPanelsContainer").GetChild(i).DeleteAsync(0);
	};
}

Console.prototype.safeexec = function(code) {
	if (this.syntaxcheck(code))  {
		return this.exec(`try {${code}} catch(err) {PrintError(err, "| ${code.replace(/'|"|`|\\/g, (v) => {
			return "\\"+v;
		}).replace(/\n/g, (v) => {return ";"})}");}`);
	};
}

Console.prototype.syntaxcheck = function(code) {
	if (code.replace(/\\|\s/g, "") == "" || code.match(/\w/g) == null) {
		$.Msg(`${(new Date()).toString()} | Syntax Error (invalid code) | ${code}`);
		return false;
	};
	const quotes = this.quotes_check(code);
	if (!quotes) {
		$.Msg(`${(new Date()).toString()} | Syntax Error (quotes is not closed) | ${code}`);
		return false;
	};
	const parentheses = this.parentheses_check(code);
	if (!parentheses) {
		$.Msg(`${(new Date()).toString()} | Syntax Error (brackets does not equals) | ${code}`);
		return false;
	};
	return true;
};

Console.prototype.quotes_check = function(code) {
	code = code.replace(/\\\\.+/g, (v) => (""));
	const [single_quotes, double_quotes, multi_quotes] = [code.split("\"").length-1, code.split("'").length-1, code.split("`").length-1];
	return (single_quotes % 2 == 0) && (double_quotes % 2 == 0) && (multi_quotes % 2 == 0);
};

Console.prototype.parentheses_check = function(code) {
	code = code.replace(/\\\\.+/g, (v) => ("")).replace(/("[^"]*[\[\{\(\)\}\]]+[^"]*")|('[^']*[\[\{\(\)\}\]]+[^']*')/g, (v) => (""));
	const brackets_start = {")": "(", "}": "{", "]": "["};
	let stack = [];
	for (let i=0; i<code.length; i++) {
		if (Object.values(brackets_start).includes(code[i])) {
			stack.push(code[i]);
		} else if (stack[stack.length-1] == brackets_start[code[i]]) {
			stack.pop();
		} else if (Object.keys(brackets_start).includes(stack[stack.length-1])) {
			return false;
		};
	};
	return stack.length == 0;
};

Console.prototype.sendJS = function(target) {
	if (target === 'self') {
		try {
			// console.log('js')
			this.safeexec(this.getCode());
		} catch(err) {
			this.setStack(err.stack);
		}
		return;
	} else if (target === 'player') {
		target = this.playerList.GetSelected().id;
	}

	GameEvents.SendCustomGameEventToServer('console-evaluate', {
		type: 'js',
		target: target,
		code: this.getCode(),
	})
};

// Export 'con' variable, so it can be called from layout event handlers
var con = new Console($('#console'));

GameEvents.Subscribe('console-evaluate', function(event) {
	console.log('js console')
	Console.prototype.safeexec(event.code);
});
