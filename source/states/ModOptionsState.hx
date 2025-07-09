package states;

import states.PlayState;
import openfl.Lib;
import backend.ClientPrefs;
import backend.Controls;
import backend.MusicBeatState;
import backend.DiscordClient;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import options.ModVisualSettings;
import options.ControlsSubState;
import options.ModGameplaySettings;
import options.ModGraphicsSettings;
import options.NoteOffsetState;
//import options.NotesSubState;
import states.ModMainMenuState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.text.FlxTextBorderStyle;

import options.RewriteSettings;

using StringTools;

class ModOptionsState extends MusicBeatState {
	var bg:FlxSprite;
	var menuTitle:FlxSprite;
	var back:FlxSprite;
	var menuItems:Array<Dynamic> = [["CONTROLS", []], ["NOTE / BEAT DELAY", []], ["GRAPHICS", []], ["VISUALS & UI", []], ["GAMEPLAY", []], ["MOD OPTIONS", []]];
	var selector:FlxSprite;
	var curSelected:Int = 0;
	var selectedSomething:Bool = false;
	var warningText:FlxText;
	var inSubstate:Bool = false;
	var blueFade:FlxSprite;

	override function create() {
		backend.DiscordClient.changePresence("Settings Menu", null);
		FlxG.scaleMode = PlayState.getStageSizeScaleMode();
		resizeWindow(820, 720);

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		new FlxTimer().start(0.001, function(_) {
			FlxG.camera.alpha = 1;
			FlxG.camera.flash(0xFF000000, 0.6);
		});

		bg = new FlxSprite().loadGraphic(Paths.image("menus/options/bg"));
		bg.scale.set(3.25, 3.25);

		menuTitle = new FlxSprite().loadGraphic(Paths.image("menus/options/settings"));
		back = new FlxSprite(670, 650).loadGraphic(Paths.image("menus/options/back"));

		for (i in [bg, menuTitle, back]) {
			if (i != bg) i.scale.set(3, 3);
			if (i != back) i.screenCenter();
			add(i);
		}

		menuTitle.y -= 290;

		for (i in 0...menuItems.length) {
			var option = new FlxSprite(170, 180 + i * 82).loadGraphic(Paths.image("menus/options/option"));
			option.scale.set(3, 3);
			add(option);
			menuItems[i][1].push(option);

			var text = new FlxText(option.x - 340, option.y - 15, FlxG.width, menuItems[i][0]);
			text.setFormat(Paths.font("sonic2HUD.ttf"), 44, 0xFFFFFFFF, "center", FlxTextBorderStyle.SHADOW, 0xFF000000);
			text.shadowOffset.x += 1;
			text.shadowOffset.y += 3;
			add(text);
			menuItems[i][1].push(text);
		}

		selector = new FlxSprite(480).loadGraphic(Paths.image("menus/options/selector"));
		selector.scale.set(3, 3);
		add(selector);

		warningText = new FlxText(-170, 640, FlxG.width, 'THIS CATEGORY\nCONTAINS MOD SPOILERS');
		warningText.setFormat(Paths.font("sonic2HUD.ttf"), 34, 0xFFFF0000, "center", FlxTextBorderStyle.SHADOW, 0xFF000000);
		warningText.shadowOffset.x += 1;
		warningText.shadowOffset.y += 3;
		add(warningText);

		changeSelection(0, true);
		ClientPrefs.saveSettings();

		blueFade = new FlxSprite(0, 0).makeGraphic(100, 100, 0xFF0000FF);
		blueFade.scale.set(100, 100);
		blueFade.screenCenter();
		blueFade.blend = 9;
		blueFade.alpha = 0.001;
		add(blueFade);
	}

	function changeSelection(change:Int, silent:Bool) {
		if (!silent) FlxG.sound.play(Paths.sound("scrollMenu"), 0.8);

		curSelected += change;
		if (curSelected > menuItems.length - 1) curSelected = 0;
		if (curSelected < 0) curSelected = menuItems.length - 1;

		for (i in 0...menuItems.length) {
			if (i == curSelected) {
				menuItems[i][1][1].color = 0xFFFCFC00;
				if (menuItems[i][0] == "MOD OPTIONS") warningText.visible = true;
			} else {
				menuItems[i][1][1].color = 0xFFFFFFFF;
				warningText.visible = false;
			}
		}

		selector.y = menuItems[curSelected][1][0].y + 5;
	}

	function selectSomething() {
		selectedSomething = true;
		FlxG.sound.play(Paths.sound("confirmMenu"));
		var selected:Bool = true;
		new FlxTimer().start(0.05, function(_) {
			selected = !selected;
			menuItems[curSelected][1][1].color = selected ? 0xFFFFFFFF : 0xFFFCFC00;
		}, 21);

		new FlxTimer().start(1.4, function(_) {
			switch (curSelected) {
				case 0:
					inSubstate = true;
					persistentUpdate = true;
					resizeWindow(1280, 720);
					for (i in [bg, menuTitle, back, selector]) i.visible = false;
					for (i in menuItems) for (o in i[1]) o.visible = false;
					FlxG.camera.alpha = 0;
					MusicBeatState.switchState(new ControlsSubState());

				case 1:
					FlxTween.tween(blueFade, {alpha: 1}, 0.5);
					FlxG.camera.fade(0xFF000000, 0.7);
					new FlxTimer().start(0.95, (_) -> {
						MusicBeatState.switchState(new NoteOffsetState());
					});

				case 2:
					inSubstate = true;
					persistentUpdate = true;
					switchState("options/GraphicSettings");

				case 3:
					inSubstate = true;
					persistentUpdate = true;
					switchState("options/VisualSettings");

				case 4:
					inSubstate = true;
					persistentUpdate = true;
					switchState("options/GameplaySettings");

				case 5:
					inSubstate = true;
					persistentUpdate = true;
					switchState("options/RewriteSettings");
			}
		});
	}

	function switchState(state:String) {
		FlxTween.tween(blueFade, {alpha: 1}, 0.5);
		FlxG.camera.fade(0xFF000000, 0.7);
		new FlxTimer().start(0.75, (_) -> {
			switch (state) {
                case "options/GraphicSettings":
                    MusicBeatState.switchState(new ModGraphicsSettings()); // idk
                case "options/VisualSettings":
                    MusicBeatState.switchState(new ModVisualSettings()); // idk
                case "options/GameplaySettings":
                    MusicBeatState.switchState(new ModGameplaySettings()); // idk
                case "options/RewriteSettings":
                    trace("MOD OPTIONS");
                    MusicBeatState.switchState(new RewriteSettings());
        }
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P && !selectedSomething) changeSelection(-1, false);
		if (controls.UI_DOWN_P && !selectedSomething) changeSelection(1, false);
		if (controls.ACCEPT && !selectedSomething) selectSomething();

		if (controls.BACK) {
			if (inSubstate && selectedSomething) {
				inSubstate = false;
				selectedSomething = false;
				changeSelection(0, true);
				resizeWindow(820, 720);
				ClientPrefs.saveSettings();
				for (i in [bg, menuTitle, back]) i.visible = true;
				for (i in menuItems) for (o in i[1]) o.visible = true;
			} else if (!selectedSomething) {
				FlxG.sound.play(Paths.sound("cancelMenu"));
				selectedSomething = true;
				FlxTween.tween(blueFade, {alpha: 1}, 0.5);
				FlxG.camera.fade(0xFF000000, 0.7);
				new FlxTimer().start(0.95, (_) -> {
					MusicBeatState.switchState(new ModMainMenuState());
				});
			}
		}
	}

	function resizeWindow(width:Int, height:Int) {
		FlxG.resizeWindow(width, height);
		FlxG.resizeGame(width, height);
		var resolutionX = Math.ceil(Lib.current.stage.window.display.currentMode.width * Lib.current.stage.window.scale);
		var resolutionY = Math.ceil(Lib.current.stage.window.display.currentMode.height * Lib.current.stage.window.scale);
		Lib.application.window.x = (resolutionX - Lib.application.window.width) / 2;
		Lib.application.window.y = (resolutionY - Lib.application.window.height) / 2;
	}

	override function destroy() {
		super.destroy();
	}
}