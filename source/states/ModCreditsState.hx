package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import openfl.utils.Assets;
import openfl.Lib;

import backend.MusicBeatState;
import backend.DiscordClient;
import backend.CoolUtil;
import backend.Controls;
import backend.Mods;
import backend.Paths;


import states.ModMainMenuState;
import states.EndCreditsState;
import states.ModTitleState;

using StringTools;

class CreditsState extends MusicBeatState {
    var bg:FlxBackdrop;
    var menuTitle:FlxSprite;
    var back:FlxSprite;
    var up:FlxSprite;
    var down:FlxSprite;
    var endCredits:FlxSprite;
    var blueFade:FlxSprite;

    var bsky:FlxSprite;
    var youtube:FlxSprite;
    var twitter:FlxSprite;

    var border:FlxSprite;
    var name:FlxText;
    var seperator:FlxSprite;
    var desc:FlxText;
    var customCursor:FlxSprite;

    var entries:Array<Array<String>> = [];
    var icons:Array<FlxSprite> = [];
    var allowInput:Bool = true;
    var canChange:Bool = true;
    var curSelected:Int = 0;

    override public function create() {
        super.create();

        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        FlxG.mouse.visible = false;

        backend.DiscordClient.changePresence("Credits", null);
        FlxG.camera.flash(FlxColor.BLACK, 0.6);

        bg = new FlxBackdrop(Paths.image("menus/credits/bg"));
        bg.setGraphicSize(FlxG.width * 2, FlxG.height * 2);
        bg.screenCenter();
        bg.velocity.set(10, 10);
        add(bg);

        back = new FlxSprite(10, 635).loadGraphic(Paths.image("menus/options/back"));
        menuTitle = new FlxSprite(140, 50).loadGraphic(Paths.image("menus/credits/credits"));
        back.scale.set(3, 3);
        add(back);

        for (mod in Mods.parseList().enabled) pushEntriesToCredits(mod);

        bsky = socialIcon("bsky", 102, 236);
        youtube = socialIcon("youtube", 103, 366);
        twitter = socialIcon("twitter", 107, 445);

        for (i in [bsky, youtube, twitter]) {
            i.x -= 70;
            add(i);
        }

        border = new FlxSprite().loadGraphic(Paths.image("menus/credits/select"));
        border.scale.set(5, 5);
        border.screenCenter();
        border.x -= 50;
        add(border);

        name = new FlxText(border.x + 146, border.y - 40, FlxG.width, "");
        name.setFormat(Paths.font("3dBlast.ttf"), 28, FlxColor.WHITE, "left");
        add(name);

        seperator = new FlxSprite(border.x + 148, border.y).makeGraphic(371, 6, FlxColor.WHITE);
        add(seperator);

        desc = new FlxText(border.x + 146, border.y + 10, FlxG.width, "");
        desc.setFormat(Paths.font("sonic2HUD.ttf"), 26, FlxColor.WHITE, "left");
        add(desc);

        for (i in [name, desc, seperator]) i.x -= 70;

        for (i in 0...entries.length) {
            var icon = new FlxSprite(border.x, border.y + i * 200).loadGraphic(Paths.image("credits/" + entries[i][0]));
            icon.scale.set(5, 5);
            icons.push(icon);
            add(icon);
        }

        up = new FlxSprite(550, 80).loadGraphic(Paths.image("menus/credits/arrow"));
        down = new FlxSprite(550, 580).loadGraphic(Paths.image("menus/credits/arrow"));
        down.flipY = true;
        for (i in [up, down]) {
            i.scale.set(5, 5);
            add(i);
        }

        endCredits = new FlxSprite(20, 150).loadGraphic(Paths.image("menus/credits/replayCreditsRoll"));
        endCredits.scale.set(2.6, 2.6);
        add(endCredits);

        add(menuTitle);

        customCursor = new FlxSprite(-100, -100);
        customCursor.frames = Paths.getSparrowAtlas("cursor");
        customCursor.animation.addByPrefix("default", "default", 24, false);
        customCursor.animation.addByPrefix("wait", "wait", 24, false);
        customCursor.animation.addByPrefix("hover", "hover", 24, false);
        customCursor.animation.play("default");
        customCursor.scale.set(1.5, 1.5);
        add(customCursor);

        blueFade = new FlxSprite().makeGraphic(100, 100, 0xFF0000FF);
        blueFade.scale.set(100, 100);
        blueFade.alpha = 0.001;
        blueFade.screenCenter();
        blueFade.blend = 9;
        add(blueFade);

        changeSelection(0);
    }

    function pushEntriesToCredits(folder:String) {
        var entriesFile = folder != null && folder.trim().length > 0 ?
            Paths.mods(folder + "/data/credits.txt") :
            Paths.mods("data/credits.txt");

        if (utils.MobileUtils.exists(entriesFile)) {
            var lines = sys.io.File.getContent(entriesFile).split("\n");
            for (line in lines) {
                var data = line.replace("\\n", "\n").split("::");
                entries.push(data);
            }
        }
    }

    function socialIcon(prefix:String, x:Float, y:Float):FlxSprite {
        var spr = new FlxSprite(x, y);
        spr.frames = Paths.getSparrowAtlas("menus/credits/socials");
        spr.animation.addByPrefix("enabled", prefix + "0", 24, true);
        spr.animation.addByPrefix("disabled", prefix + "Disabled", 24, true);
        spr.animation.play("enabled");
        spr.scale.set(5, 5);
        spr.updateHitbox();
        return spr;
    }

    function changeSelection(change:Int) {
        if (!canChange) return;
        if (change != 0) FlxG.sound.play(Paths.sound("scrollMenu"), 0.8);
        curSelected += change;
        if (curSelected >= entries.length) curSelected = 0;
        if (curSelected < 0) curSelected = entries.length - 1;

        name.text = entries[curSelected][0].toUpperCase();
        desc.text = entries[curSelected][1];
        bsky.animation.play(entries[curSelected][2] == "null" ? "disabled" : "enabled");
        youtube.animation.play(entries[curSelected][3] == "null" ? "disabled" : "enabled");
        twitter.animation.play(entries[curSelected][4] == "null" ? "disabled" : "enabled");

        for (i in 0...icons.length) {
            var icon = icons[i];
            var newY = border.y + (i - curSelected) * 200;
            var scale = i == curSelected ? 5 : 4;
            var alpha = i == curSelected ? 1 : 0.5;

            canChange = false;
            FlxTween.cancelTweensOf(icon);
            FlxTween.tween(icon, {y: newY, alpha: alpha}, 0.15, {
                ease: FlxEase.cubeOut,
                onComplete: (_) -> canChange = true
            });
            FlxTween.tween(icon.scale, {x: scale, y: scale}, 0.15, {ease: FlxEase.cubeOut});
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        customCursor.setPosition(FlxG.mouse.x, FlxG.mouse.y);

        if (!allowInput) {
            customCursor.animation.play("wait");
            return;
        }

        customCursor.animation.play("default");
        if (FlxG.mouse.overlaps(up) || FlxG.mouse.overlaps(down) || FlxG.mouse.overlaps(bsky) || FlxG.mouse.overlaps(youtube) || FlxG.mouse.overlaps(twitter) || FlxG.mouse.overlaps(endCredits) || FlxG.mouse.overlaps(back)) {
            customCursor.animation.play("hover");
        }

        if (controls.BACK) switchState("states/MainMenuState");

        if (controls.UI_UP_P || FlxG.mouse.justPressed && FlxG.mouse.overlaps(up)) changeSelection(-1);
        if (controls.UI_DOWN_P || FlxG.mouse.justPressed && FlxG.mouse.overlaps(down)) changeSelection(1);

        if (FlxG.mouse.justPressed) {
            if (FlxG.mouse.overlaps(bsky) && bsky.animation.curAnim.name == "enabled") CoolUtil.browserLoad(entries[curSelected][2]);
            else if (FlxG.mouse.overlaps(youtube) && youtube.animation.curAnim.name == "enabled") CoolUtil.browserLoad(entries[curSelected][3]);
            else if (FlxG.mouse.overlaps(twitter) && twitter.animation.curAnim.name == "enabled") CoolUtil.browserLoad(entries[curSelected][4]);
            else if (FlxG.mouse.overlaps(endCredits)) switchState("states/EndCreditsState");
            else if (FlxG.mouse.overlaps(back)) switchState("states/MainMenuState");
        }
    }

    function switchState(path:String) {
        allowInput = false;
        FlxG.sound.play(Paths.sound("cancelMenu"));
        FlxG.camera.fade(FlxColor.BLACK, 0.9);
        if (path != "states/MainMenuState") FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.6);
        FlxTween.tween(blueFade, {alpha: 1}, 0.6);

        new FlxTimer().start(0.95, (_) -> {
            var newState:MusicBeatState = null;
            switch (path) {
                case "states/MainMenuState":
                    newState = new ModTitleState();
                case "states/EndCreditsState":
                    newState = new EndCreditsState();
                default:
                    newState = new ModTitleState(); // fallback
            }
            MusicBeatState.switchState(newState);
        });
    }
}