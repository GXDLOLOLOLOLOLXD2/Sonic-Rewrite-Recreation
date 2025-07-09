package modsrc.objects;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.util.FlxColor;

typedef DialogueLine = {
	text:String,
	emote:String,
	voice:String,
	speed:Float,
	scale:Float,
	offsetY:Int
};

class MaigoSpeaker extends FlxGroup {
	public var text:FlxText;
	public var backing:FlxSprite;
	public var icon:FlxSprite;

	public var emoteOutput:FlxSprite = null;
	public var currentlySpeaking:Bool = false;
	public var onEndReached:Void->Void = null;

	public function new() {
		super();

		backing = new FlxSprite(0, 540).makeGraphic(FlxG.width, 80, FlxColor.BLACK);
		backing.alpha = 0.001;
		add(backing);

		text = new FlxText(30, 555, FlxG.width - 60, "");
		text.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		text.fieldHeight = 60;
		text.fieldWidth = FlxG.width - 60;
		text.scrollFactor.set();
		add(text);

		icon = new FlxSprite(0, 440);
		icon.frames = Paths.getSparrowAtlas("menus/gallery/maigo/galleryEmotes");
		icon.animation.addByPrefix("talk", "talk", 15, true);
		icon.animation.addByPrefix("hype", "hype", 15, true);
		icon.animation.addByPrefix("sad", "sad", 15, true);
		icon.animation.addByPrefix("shy", "shy", 15, true);
		icon.animation.addByPrefix("book", "book", 15, false);
		icon.animation.addByPrefix("hand", "hand", 15, true);
		icon.scale.set(3.3, 3.3);
		icon.alpha = 0.001;
		add(icon);
	}

	public function swapSpeaker(toDefault:Bool) {
		if (toDefault) {
			emoteOutput = icon;
			icon.alpha = 1;
		} else {
			if (emoteOutput != null) emoteOutput.alpha = 0.001;
			icon.alpha = 0.001;
		}
	}

	public function startDialogue(dialogue:Array<DialogueLine>) {
		currentlySpeaking = true;
		var i = 0;

		function showNextLine() {
			if (i >= dialogue.length) {
				currentlySpeaking = false;
				if (onEndReached != null) onEndReached();
				return;
			}

			var line = dialogue[i];
			var emote = line.emote;
			var voice = line.voice;
			var speed = line.speed;
			var scale = line.scale;
			var offsetY = line.offsetY;

			text.y = 555 + offsetY;
			text.text = "";
			text.fieldWidth = FlxG.width - 60;
			text.scale.set(scale, scale);
			text.alpha = 1;

			if (emoteOutput != null && emote != null) {
				emoteOutput.animation.play(emote, true);
			}

			if (voice != null && voice.length > 0) {
				FlxG.sound.play(Paths.sound("maigo/dialogue/" + voice));
			}

			text.text = line.text;

			new FlxTimer().start(2.0, function(_) {
				i++;
				showNextLine();
			});
		}

		backing.alpha = 0.5;
		text.alpha = 1;
		showNextLine();
	}
}