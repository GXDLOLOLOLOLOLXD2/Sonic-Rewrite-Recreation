package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxTimer;

import backend.DiscordClient;
import backend.MusicBeatState;
import states.LoadingState;
import objects.Character;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import states.editors.NoteSplashDebugState;
import states.ModMainMenuState;
import states.PostCreditsState;
import states.ModTestState;

import openfl.Lib;

class ModMasterEditorState extends MusicBeatState {
    var debug:FlxSprite;
    var curSelected:Int = 0;
    var leaving:Bool = false;
    
    var options:Array<String> = [
        "CHARACTER EDITOR", "CHART EDITOR", "NOTE SPLASH EDITOR",
        "PLAY POST CREDITS", "RESET MAIGO PROGRESSION",
        "RESET SONG PROGRESSION", "RESET CREDITS PROGRESSION",
        "TEST STATE"
    ];
    
    var optionButtons:Array<FlxText> = [];

    override function create() {
        super.create();

        backend.DiscordClient.changePresence("Master Editor Menu", null);
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        resizeWindow(820, 720);

        debug = new FlxSprite().loadGraphic(Paths.image("menus/debug"));
        debug.scale.set(2, 2);
        debug.screenCenter();
        add(debug);

        for (i in 0...options.length) {
            var menuText = new FlxText(0, -50, FlxG.width, options[i]);
            menuText.setFormat(Paths.font("sonic2HUD.ttf"), 55, 0xFFFFFFFF, "center", FlxTextBorderStyle.SHADOW, 0xFF000000);
            menuText.shadowOffset.set(1, 3);
            menuText.screenCenter();
            menuText.y += i * 70 - 200;
            optionButtons.push(menuText);
            add(menuText);
        }

        changeSelection(0, true);
    }

    function changeSelection(change:Int = 0, silent:Bool = false) {
        if (!silent) FlxG.sound.play(Paths.sound("scrollMenu"), 0.8);

        curSelected += change;
        if (curSelected >= optionButtons.length) curSelected = 0;
        if (curSelected < 0) curSelected = optionButtons.length - 1;

        for (i in 0...optionButtons.length) {
            optionButtons[i].color = (i == curSelected) ? 0xFFFCFC00 : 0xFFFFFFFF;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (leaving) return;

        if (controls.BACK) {
            leaving = true;
            MusicBeatState.switchState(new ModMainMenuState());
        }

        if (controls.UI_UP_P) changeSelection(-1, false);
        if (controls.UI_DOWN_P) changeSelection(1, false);

        if (controls.ACCEPT) {
            leaving = true;

            switch (options[curSelected]) {
                case "CHARACTER EDITOR":
                    resizeWindow(1280, 720);
                    LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));

                case "CHART EDITOR":
                    resizeWindow(1280, 720);
                    LoadingState.loadAndSwitchState(new ChartingState(), false);

                case "NOTE SPLASH EDITOR":
                    resizeWindow(1280, 720);
                    MusicBeatState.switchState(new NoteSplashDebugState());

                case "PLAY POST CREDITS":
                    resizeWindow(1280, 720);
                    MusicBeatState.switchState(new PostCreditsState());

                case "TEST STATE":
                    MusicBeatState.switchState(new ModTestState());

                case "RESET MAIGO PROGRESSION":
                    FlxG.save.data.seenMaigoDialogues = [];
                    FlxG.save.data.seenMaigoIntroduction = false;
                    FlxG.save.flush();
                    leaving = false;
                    FlxG.sound.play(Paths.sound("windowsShutdown"));

                case "RESET SONG PROGRESSION":
                    FlxG.save.data.beatenTG = false;
                    FlxG.save.data.beatenTrinity = false;
                    FlxG.save.flush();
                    leaving = false;
                    FlxG.sound.play(Paths.sound("confirmLaugh"));

                case "RESET CREDITS PROGRESSION":
                    FlxG.save.data.seenLegacySplash = false;
                    FlxG.save.data.seenCreditsRoll = false;
                    FlxG.save.data.seenPostCredits = false;
                    FlxG.save.flush();
                    leaving = false;
                    FlxG.sound.play(Paths.sound("deathHit"));
            }
        }
    }

    function resizeWindow(width:Int, height:Int) {
        FlxG.resizeGame(width, height);
        FlxG.resizeWindow(width, height);
        var stage = Lib.current.stage;
        var win = Lib.application.window;
        var resolutionX = Math.ceil(stage.window.display.currentMode.width * stage.window.scale);
        var resolutionY = Math.ceil(stage.window.display.currentMode.height * stage.window.scale);
        win.x = (resolutionX - win.width) / 2;
        win.y = (resolutionY - win.height) / 2;
    }

    override function destroy() {
        super.destroy();
    }
}