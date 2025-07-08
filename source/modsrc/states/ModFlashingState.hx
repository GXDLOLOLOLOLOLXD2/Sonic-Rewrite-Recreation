package states;

import flixel.addons.transition.FlxTransitionableState;
//import states.ModFlashingState; // hmmmm?
import backend.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import backend.MusicBeatState;

import states.ModTitleState;

class ModFlashingState extends MusicBeatState {
    var bg:FlxSprite;
    var accepted:Bool = false;
    var warningSound:FlxSound;
    public static var leftState:Bool = false;

    function onCreate()
    {
        DiscordClient.changePresence("Flashing Lights Disclaimer", null);
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;

        bg = new FlxSprite().loadGraphic(Paths.image("menus/warning"));
        bg.scale.set(2, 2);
        bg.screenCenter();
        bg.alpha = 0;
        bg.color = 0xFF0000FF;
        game.add(bg);

        warningSound = FlxG.sound.load(Paths.sound("warning"));

        new FlxTimer().start(0.5, (_) -> {
            FlxTween.color(bg, 0.3, 0xFF0000FF, 0xFFFFFFFF);
            FlxTween.tween(bg, {alpha: 1}, 0.5);
            FlxG.sound.play(Paths.sound("selectSong"));
            new FlxTimer().start(0.75, (_) -> warningSound.play());
        });
    }

    function onUpdate()
    {
        var pressedEnter:Bool = controls.ACCEPT;

        #if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

        if (pressedEnter && !accepted)
        {
            accepted = true;
            FlxG.sound.play(Paths.sound("confirmMenu"));
            FlxTween.color(bg, 0.3, 0xFFFFFFFF, 0xFF0000FF);
            FlxG.camera.fade(0xFF000000, 0.5);
            warningSound.fadeOut(0.3, 0);
            new FlxTimer().start(0.55, (_) -> {
                FlashingState.leftState = true;
                MusicBeatState.switchState(new ModTitleState());
            });
        }
    }

    function onDestroy() {}
}