package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import backend.MusicBeatState;
import MainMenuState;

class TestState extends MusicBeatState {
    var leaving:Bool = false;
    var testImage:FlxSprite;

    override function create() {
        super.create();

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;

        var bg = new FlxSprite().makeGraphic(300, 300, 0xFFFFFFFF);
        bg.scale.set(3.3, 3.3);
        bg.screenCenter();
        add(bg);

        testImage = new FlxSprite().loadGraphic(Paths.image("blueCloudsScary"));
        testImage.screenCenter();
        add(testImage);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (leaving) return;

        if (FlxG.keys.justPressed.F) {
            testImage.destroy();
            Paths.clearImageFromMemory("blueCloudsScary.png");
        }

        if (controls.BACK) {
            leaving = true;
            MusicBeatState.switchState(new MainMenuState());
        }
    }
}
