package substates;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;

import substates.PauseSubState;
import states.PlayState;
import engine.backend.MusicBeatState;
import states.ModMainMenuState;

class ModPauseSubstate extends FlxSubState {
	var overlay:FlxSprite;
	var pause:FlxSprite;
	var menuItems:Array<Array<Dynamic>> = [
		["RESUME", []],
		["RESTART", []],
		["EXIT", []]
	];
	var curSelected:Int = 0;
	var selectedSomething:Bool = false;

	public function new() {
		super();
	}

	override public function create():Void {
		super.create();

		overlay = new FlxSprite().makeGraphic(100, 100, 0xFF000000);
		overlay.scale.set(1000, 1000);
		overlay.alpha = 0.6;
		overlay.scrollFactor.set();
		add(overlay);

		pause = new FlxSprite(605, 150);
		pause.frames = Paths.getSparrowAtlas("menus/pause/paused");
		pause.animation.addByPrefix("pause", "paused", 24, false);
		pause.animation.play("pause");
		pause.scale.set(3, 3);
		pause.scrollFactor.set();
		add(pause);

		for (i in 0...menuItems.length) {
			var option = new FlxSprite(570, 250 + i * 130);
			option.frames = Paths.getSparrowAtlas("menus/pause/option");
			option.animation.addByPrefix("normal", "optionNormal", 1, true);
			option.animation.addByPrefix("selected", "optionSelected", 1, true);
			option.animation.play("normal");
			option.scale.set(3, 3);
			option.scrollFactor.set();
			menuItems[i][1].push(option);
			add(option);

			var text = new FlxText(option.x - 340, option.y - 15, FlxG.width, menuItems[i][0]);
			text.setFormat(Paths.font("sonicCD.ttf"), 24, 0xFFFFFFFF, "center", FlxTextBorderStyle.SHADOW, 0xFF000000);
			text.shadowOffset.set(1, 3);
			text.scrollFactor.set();
			menuItems[i][1].push(text);
			add(text);
		}

		changeSelection(0);

		addTouchPad(PlayState.chartingMode ? "LEFT_FULL" : "UP_DOWN", "A");
		addTouchPadCamera();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!selectedSomething) {
			if (FlxG.keys.justPressed.UP) changeSelection(-1);
			if (FlxG.keys.justPressed.DOWN) changeSelection(1);
			if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) selectOption();
		}
	}

	function changeSelection(change:Int):Void {
		curSelected += change;
		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected > menuItems.length - 1) curSelected = 0;

		FlxG.sound.play(Paths.sound("scrollMenu"), 0.8);

		for (i in 0...menuItems.length) {
			var btn = menuItems[i][1][0];
			var txt = menuItems[i][1][1];
			if (i == curSelected) {
				btn.animation.play("selected");
				txt.color = 0xFFE0E000;
			} else {
				btn.animation.play("normal");
				txt.color = 0xFFFFFFFF;
			}
		}
	}

	function selectOption():Void {
		selectedSomething = true;
		FlxG.sound.play(Paths.sound("confirmMenu"));

		switch (curSelected) {
			case 0: // RESUME
				close();
			case 1: // RESTART
				FlxG.camera.fade(0xFF000000, 0.5);
				new FlxTimer().start(0.5, function(_) {
					PauseSubState.restartSong(false);
				});
			case 2: // EXIT
				FlxG.camera.fade(0xFF000000, 0.5);
				new FlxTimer().start(0.5, function(_) {
					FlxG.sound.playMusic(Paths.music("freakyMenu"), 1);
					PlayState.checkpointTime = 0;
					PlayState.campaignMisses = 0;
					PlayState.songVariation = null;
					MusicBeatState.switchState(new ModMainMenuState());
				});
		}
	}
}
