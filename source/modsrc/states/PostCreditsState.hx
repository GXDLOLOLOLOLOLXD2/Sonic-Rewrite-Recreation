package states;

import openfl.Lib;
import states.PlayState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import backend.MusicBeatState;
import backend.DiscordClient;
import Main;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import states.MainMenuState;

class PostCreditsState extends MusicBeatState {
    var theEnd:FlxSprite;
    var subtitleText:FlxText;
    var gameSprite:FlxSprite;
    var overSprite:FlxSprite;
    var blueFade:FlxSprite;

    var maxWidth:Int;
    var maxHeight:Int;

    override function create() {
        Main.fpsVar.visible = false;
        maxWidth = Lib.application.window.stage.fullScreenWidth;
        maxHeight = Lib.application.window.stage.fullScreenHeight;

        new FlxTimer().start(0.1, function(_) {
            FlxG.scaleMode = PlayState.getRatioScaleMode();          
            FlxG.camera.x = -230;
            resizeWindow(maxWidth + 1, maxHeight + 1);
        });

        Lib.application.window.borderless = true;
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;

        DiscordClient.changePresence("Post Credits", null);

        if (FlxG.sound.music != null) FlxG.sound.music.stop();

        theEnd = new FlxSprite(0, 430);
        theEnd.frames = Paths.getSparrowAtlas("menus/postCredits/theEnd");
        theEnd.animation.addByPrefix("theEnd", "theEnd", 30, true);
        theEnd.animation.play("theEnd");
        theEnd.setGraphicSize(1280, 720);
        theEnd.screenCenter();
        theEnd.alpha = 0.0001;
        add(theEnd);

        subtitleText = new FlxText(0, 600, 1280, "");
        subtitleText.setFormat(Paths.font("sonic2HUD.ttf"), 40, 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
        subtitleText.borderSize = 2;
        add(subtitleText);

        gameSprite = new FlxSprite(0, 560).loadGraphic(Paths.image("menus/postCredits/game"));
        overSprite = new FlxSprite(0, 560).loadGraphic(Paths.image("menus/postCredits/over"));

        for (i in [gameSprite, overSprite]) {
            i.scale.set(3, 3);
            i.screenCenter(0x10);
            add(i);
        }

        gameSprite.x = -300;
        overSprite.x = 1400;

        blueFade = new FlxSprite(0, 0).makeGraphic(100, 100, 0xFF0000FF);
        blueFade.scale.set(100, 100);
        blueFade.screenCenter();
        blueFade.blend = 9;
        blueFade.alpha = 0.001;
        add(blueFade);

        Paths.sound('sonicPostCredits');
        Paths.music("theEnd");

        new FlxTimer().start(1.7, function(_) {
            FlxG.sound.play(Paths.sound('sonicPostCredits'));
            startSonicDialogue();
        });
    }

    function startSonicDialogue()
    {
        subtitleText.text = "Are you still there?";

        new FlxTimer().start(1.91, (_) -> {
            subtitleText.text = "That's a silly question, I know you are!";
        });

        new FlxTimer().start(5.29, (_) -> {
            subtitleText.text = "It's hard to let go of things, isn't it?";
        });

        new FlxTimer().start(7.79, (_) -> {
            subtitleText.text = "You stubborn head!";
        });

        new FlxTimer().start(9.38, (_) -> {
            subtitleText.text = "";
        });

        new FlxTimer().start(10.17, (_) -> {
            subtitleText.text = "You see...";
        });

        new FlxTimer().start(11.20, (_) -> {
            subtitleText.text = "When you're soaked underwater, all the way down to the bottom,";
            FlxG.sound.playMusic(Paths.music("theEnd"), 0);
            FlxTween.tween(FlxG.sound.music, {volume: 1}, 7);

            new FlxTimer().start(14.39, (_) -> {
                FlxTween.tween(theEnd, {alpha: 1}, 8);
            });
        });

        new FlxTimer().start(15.09, (_) -> {
            subtitleText.text = "With all this pressure on you, they say it's an excruciating pain when you make contact with the air again.";
        });

        new FlxTimer().start(23.04, (_) -> {
            subtitleText.text = "It doesn't hurt to invite the water in.";
        });

        new FlxTimer().start(25.86, (_) -> {
            subtitleText.text = "Might even be a relief for your flesh.";
        });

        new FlxTimer().start(28.72, (_) -> {
            subtitleText.text = "And, in the end...";
        });

        new FlxTimer().start(30.31, (_) -> {
            subtitleText.text = "That's what lasts from it.";
        });

        new FlxTimer().start(32.14, (_) -> {
            subtitleText.text = "";
        });

        new FlxTimer().start(32.79, (_) -> {
            subtitleText.text = "But fear not!";
        });

        new FlxTimer().start(34.79, (_) -> {
            subtitleText.text = "You won't have to worry about this anymore, friend.";
        });

        new FlxTimer().start(37.65, (_) -> {
            subtitleText.text = "You're deep down the lake...";
            FlxTween.tween(gameSprite, {x: 500}, 1);
            FlxTween.tween(overSprite, {x: 740}, 1);

            new FlxTimer().start(14.59, (_) -> {
                FlxG.save.data.seenPostCredits = true;
                FlxG.save.flush();
                FlxG.camera.fade(0xFF000000, 0.9);
                FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.9);
                FlxTween.tween(blueFade, {alpha: 1}, 0.6);
                new FlxTimer().start(0.95, (_) -> {
                    FlxG.sound.music.stop();
                    FlxG.sound.music = null;
                    MusicBeatState.switchState(new MainMenuState());
                });
            });
        });

        new FlxTimer().start(39.74, (_) -> {
            FlxTween.tween(subtitleText, {alpha: 0}, 2);
        });
    }

    function resizeWindow(width:Int, height:Int)
    {
        FlxG.resizeGame(width, height);
        FlxG.resizeWindow(width, height);
        var resolutionX = Math.ceil(Lib.current.stage.window.display.currentMode.width * Lib.current.stage.window.scale);
        var resolutionY = Math.ceil(Lib.current.stage.window.display.currentMode.height * Lib.current.stage.window.scale);
        Lib.application.window.x = (resolutionX - Lib.application.window.width) / 2;
        Lib.application.window.y = (resolutionY - Lib.application.window.height) / 2;
    }

    override function destroy() {
        if (ClientPrefs.data.showFPS) Main.fpsVar.visible = true;
        resizeWindow(820, 720);
        Lib.application.window.fullscreen = false;
        Lib.application.window.borderless = false;
        super.destroy();
    }
}