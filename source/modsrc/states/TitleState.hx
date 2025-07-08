package states;

import backend.ClientPrefs;
import backend.DiscordClient;
import backend.CoolUtil;
import backend.MusicBeatState;
import states.PlayState;
//import FlashingState;
import backend.Controls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import openfl.Lib;
import hxvlc.flixel.FlxVideoSprite;

class TitleState extends MusicBeatState {
    var curPhase:Int = 0;
    var introAnim:FlxSprite;
    var ring:FlxSprite;
    var sonic:FlxSprite;
    var arm:FlxSprite;
    var logo:FlxSprite;
    var sparkles:FlxSprite;
    var pressSpace:FlxSprite;
    var introVideo:FlxVideoSprite;
    var canSkipVideo:Bool = false;
    var sega:FlxSprite;
    var canEnter:Bool = false;
    var canSkipSega:Bool = true;
    var skippedIntro:Bool = false;
    var skippedVideo:Bool = false;
    var canSkipIntro:Bool = false;
    var introSound:FlxSound;
    var inIntro:Bool = false;
    public static var leftState:Bool = false;

    function onCreate()
    {
        Paths.clearStoredMemory();
        FlxG.save.bind('funkin', CoolUtil.getSavePath());
        ClientPrefs.loadPrefs();
        DiscordClient.changePresence("Title Screen", null);

        FlxG.scaleMode = PlayState.getStageSizeScaleMode();
        resizeWindow(820, 720);

        FlxG.fixedTimestep = false;
        FlxG.game.focusLostFramerate = 60;
        persistentUpdate = persistentDraw = true;

        if (FlxG.save.data.flashing == null && !FlashingState.leftState) {
            MusicBeatState.switchState(new FlashingState());
            return;
        }

        introAnim = new FlxSprite();
        introAnim.frames = Paths.getSparrowAtlas("menus/title/intro");
        introAnim.animation.addByPrefix("intro", "intro", 30, false);
        introAnim.screenCenter();

        ring = new FlxSprite(250, 207.5).loadGraphic(Paths.image("menus/title/ring"));
        ring.alpha = 0.001;

        sonic = new FlxSprite(387, 239.5).loadGraphic(Paths.image("menus/title/sonic"));
        sonic.alpha = 0.001;

        arm = new FlxSprite();
        arm.frames = Paths.getSparrowAtlas("menus/title/arm");
        arm.animation.addByPrefix("arm", "arm", 15, false);
        arm.screenCenter();
        arm.alpha = 0.001;

        logo = new FlxSprite(382, 506.5).loadGraphic(Paths.image("menus/title/logo"));
        logo.alpha = 0.001;

        sparkles = new FlxSprite();
        sparkles.frames = Paths.getSparrowAtlas("menus/title/sparkles");
        sparkles.animation.addByPrefix("sparkles", "sparkles", 30, true);
        sparkles.screenCenter();
        sparkles.y += 230;
        sparkles.alpha = 0.001;

        pressSpace = new FlxSprite().loadGraphic(Paths.image("pressSpace"));
        pressSpace.screenCenter();
        pressSpace.visible = false;

        introVideo = new FlxVideoSprite();
        introVideo.load(Paths.video('intro'));
        introVideo.alpha = 0.001;
        game.add(introVideo);

        sega = new FlxSprite();
        sega.frames = Paths.getSparrowAtlas("menus/title/sega");
        sega.animation.addByPrefix("sega", "sega", 12, false);
        sega.animation.addByIndices("loop", "sega", [20, 21, 22, 23, 24], "", 12, true);
        sega.screenCenter();

        for (i in [introAnim, ring, sonic, arm, logo, pressSpace, sparkles, sega])
        {
            i.scale.set(i == sparkles ? 1.5 : 3.5, i == sparkles ? 1.5 : 3.5);
            game.add(i);
        }

        introAnim.animation.finishCallback = function (_) setupSonic();

        introSound = FlxG.sound.play(Paths.sound("title"), 0);
        introSound.pause();

        sega.animation.finishCallback = function (_) sega.animation.play("loop", true);

        new FlxTimer().start(1, function(_) {
            sega.animation.play("sega");
            new FlxTimer().start(2.25, function(_) {
                if (curPhase == 0) {
                    canSkipSega = false;
                    FlxG.sound.play(Paths.sound("segaScream"));
                }
            });
        });

        new FlxTimer().start(4.75, function(_) {
            if (sega.alpha < 1) return;
            FlxTween.tween(sega, {alpha: 0.001}, 0.5);
            new FlxTimer().start(2, function(_) startVideo());
        });
    }

    function startVideo()
    {
        curPhase = 1;
        FlxTween.color(introVideo, 0.3, 0x000000FF, 0xFFFFFFFF);
        FlxTween.tween(introVideo, {alpha: 1}, 0.3);
        introVideo.play();

        introVideo.bitmap.onPlaying.add(() -> canSkipVideo = true);
        introVideo.bitmap.onEndReached.add(() -> {
            if (skippedVideo) return;
            introVideo.pause();
            FlxTween.color(introVideo, 0.15, 0xFFFFFFFF, 0x000000FF);
            FlxTween.tween(introVideo, {alpha: 0.001}, 0.3);
            new FlxTimer().start(0.8, (_) -> startIntro());
        });
    }

    function setupSonic()
    {
        introAnim.alpha = 0.001;
        for (i in [ring, sonic, arm, logo]) i.alpha = 1;

        new FlxTimer().start(2, (_) -> arm.animation.play("arm", true));
        new FlxTimer().start(0.35, function(_) pressSpace.visible = !pressSpace.visible, 0);
    }

    function startIntro()
    {
        if (skippedIntro) return;
        inIntro = true;
        curPhase = 2;
        canSkipIntro = true;

        introSound.play(true);
        introSound.volume = 1;

        new FlxTimer().start(1.05, (_) -> introAnim.animation.play("intro"));

        new FlxTimer().start(5, (_) -> {
            if (!skippedIntro) FlxG.camera.fade(0xFFFFFFFF, 0.3, false);
        });

        new FlxTimer().start(6.5, (_) -> {
            if (!skippedIntro) {
                canSkipIntro = false;
                canEnter = true;
                FlxG.camera.fade(0xFFFFFFFF, 0.3, true);
                sparkles.alpha = 1;
                sparkles.animation.play("sparkles");
            }
        });

        new FlxTimer().start(8.5, (_) -> if (!skippedIntro) sparkles.alpha = 0.001);
    }

    function onUpdate(elapsed:Float)
    {
        FlxG.mouse.visible = false;

        var pressedEnter:Bool = controls.ACCEPT;

        #if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true; // can skip the Sega logo and the cutscene
			}
		}
		#end

        if (introVideo != null && introVideo.alpha >= 0.001)
            introVideo.screenCenter();

        if (canSkipSega && pressedEnter && curPhase == 0)
        {
            canSkipSega = false;
            FlxTween.tween(sega, {alpha: 0.001}, 0.3);
            new FlxTimer().start(0.5, (_) -> startVideo());
        }

        if (canSkipVideo && pressedEnter && curPhase == 1 && introVideo.bitmap.isPlaying)
        {
            skippedVideo = true;
            introVideo.pause();
            FlxTween.tween(introVideo, {alpha: 0.001}, 0.3);
            new FlxTimer().start(0.3, (_) -> startIntro());
        }

        if (canEnter && pressedEnter)
        {
            canEnter = false;
            FlxG.sound.play(Paths.sound("confirmMenu"));
            new FlxTimer().start(0.25, (_) -> {
                for (i in [ring, sonic, arm, logo, sparkles, pressSpace])
                    if (i.alpha == 1)
                        FlxTween.color(i, 0.3, 0xFFFFFFFF, 0xFF0000FF);

                FlxG.camera.fade(0xFF000000, 0.5);
                new FlxTimer().start(0.55, (_) -> {
                    MusicBeatState.switchState(new MainMenuState());
                });
            });
        }
    }

    function resizeWindow(width:Int = 820, height:Int = 720)
    {
        FlxG.resizeWindow(width, height);
        FlxG.resizeGame(width, height);
        var stage = Lib.current.stage;
        var win = Lib.application.window;
        var resX = Math.ceil(stage.window.display.currentMode.width * stage.window.scale);
        var resY = Math.ceil(stage.window.display.currentMode.height * stage.window.scale);
        win.x = (resX - win.width) / 2;
        win.y = (resY - win.height) / 2;
    }

    function onDestroy() {
        // nothing
    }
}