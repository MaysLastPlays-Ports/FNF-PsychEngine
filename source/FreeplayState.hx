package;

import flixel.util.FlxTimer;
import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import sys.FileSystem;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxSkewedSprite;


#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState // REWRITE FREEPLAY!?!?!? HELL YEA!!!!!
{
	var whiteshit:FlxSprite;

	var curSelected:Int = 0;

	var curSongSelected:Int = 0;

	var textgrp:FlxTypedGroup<FlxText>;

	var charArray:Array<String>;

	var charUnlocked:Array<String>;

	var boxgrp:SkewSpriteGroup;

	var bg:FlxSprite;
	
	var scrollingBg:FlxBackdrop;

	var cdman:Bool = true;

	var fuck:Int = 0;

	var selecting:Bool = false;

	var charText:FlxText;

	var scoreText:FlxText;

	private static var vocals:FlxSound = null;


	override function create()
	{
		CharSongList.init();


		//charArray = CharSongList.chars;

		whiteshit = new FlxSprite().makeGraphic(1280, 720, FlxColor.WHITE);
		whiteshit.alpha = 0;

		bg = new FlxSprite().loadGraphic(Paths.image('backgroundlool'));
		bg.screenCenter();
		bg.setGraphicSize(1280, 720);
		add(bg);

		scrollingBg = new FlxBackdrop(Paths.image('sidebar'), 0, 1, false, true);
		add(scrollingBg);


		textgrp = new FlxTypedGroup<FlxText>();

		boxgrp = new SkewSpriteGroup();

		charArray = CharSongList.characters;

		charUnlocked = CharSongList.characters;



		for (i in 0...charArray.length)
		{
			if (charArray.contains(charArray[i])) // Hey so this is uneeded but it's here lol.
			{
				var box:FlxSkewedSprite = new FlxSkewedSprite(0, i * 415);
				box.loadGraphic(Paths.image('FreeBox'));
				boxgrp.add(box);
				box.ID = i;
				box.setGraphicSize(Std.int(box.width / 1.7));

				FlxG.log.add('searching for ' + 'assets/images/fpstuff/' + charArray[i].toLowerCase() + '.png'); //VOCE PODE MUDAR O fpstuff PRA SUA PASTA!!11

				if (charUnlocked.contains(charArray[i]))
				{
					if (FileSystem.exists('assets/images/fpstuff/' + charArray[i].toLowerCase() + '.png'))
					{
						FlxG.log.add(charArray[i] + ' found');
						var char:FlxSkewedSprite = new FlxSkewedSprite(0, i * 415);
						char.loadGraphic(Paths.image('fpstuff/' + charArray[i].toLowerCase()));
						boxgrp.add(char);
						char.ID = i;
						char.setGraphicSize(Std.int(box.width / 1.7));
					}
				}
				else
				{
					var char:FlxSkewedSprite = new FlxSkewedSprite(0, i * 415); //nao presisa disso isso e inutil so foi feito pra nao crachar
					char.loadGraphic(Paths.image('fpstuff/locked'));
					boxgrp.add(char);
					char.ID = i;
					char.setGraphicSize(Std.int(box.width / 1.7));
				}

			}
		}

		boxgrp.x = -335;

		var uhhdumbassline:FlxSprite = new FlxSprite(300).makeGraphic(10, 720, FlxColor.BLACK);
		add(uhhdumbassline);

		add(boxgrp);

		//add(new FlxSprite().loadGraphic(Paths.image("FreePlayShit"))); // do not.

		add(textgrp);

		scoreText = new FlxText(30, 105, FlxG.width, "");
		scoreText.setFormat("Sonic CD Menu Font Regular", 18, FlxColor.WHITE, CENTER);
		scoreText.y -= 36;
		scoreText.x -= 20;
		add(scoreText);

		if (charUnlocked.contains(charArray[0])) charText = new FlxText(30 , 10, FlxG.width, "Grilfriend"); //O PRIMERO PERSONAGEM DA LISTA DO FREEPLAY
		else charText = new FlxText(30 , 10, FlxG.width, "???");
		charText.setFormat("Sonic CD Menu Font Regular", 36, FlxColor.WHITE, CENTER);
		charText.y -= 10;
		charText.x -= 23;
		add(charText);

		boxgrp.forEach(function(sprite:FlxSkewedSprite)
		{
			if (sprite.ID == curSelected - 1 || sprite.ID == curSelected + 1)
			{
				var diff = curSelected - sprite.ID;
				trace(diff, sprite.ID, curSelected);
				FlxTween.tween(sprite, {alpha: 0.5}, 0.2);
				FlxTween.tween(sprite.scale, {x: 0.465, y: 0.465}, 0.2, {ease: FlxEase.expoOut});
				FlxTween.tween(sprite.skew, {x: 0, y: 0}, 0.2, {ease: FlxEase.expoOut});
			}
			else
			{
				FlxTween.tween(sprite, {alpha: 1}, 0.2);
				FlxTween.tween(sprite.scale, {x: 0.58, y: 0.58}, 0.2, {ease: FlxEase.expoOut});
				FlxTween.tween(sprite.skew, {x: 0, y: 0}, 0.2, {ease: FlxEase.expoOut});
			}
		});
		for (i in 0...CharSongList.getSongsByChar(charArray[curSelected]).length)
		{
			var text:FlxText;
			if (charUnlocked.contains(charArray[curSelected])) text = new FlxText(350, FlxG.height / 2 - 30 * CharSongList.getSongsByChar(charArray[curSelected]).length +  i *  30 * CharSongList.getSongsByChar(charArray[curSelected]).length, FlxG.width, StringTools.replace(CharSongList.getSongsByChar(charArray[curSelected])[i], "-", " "));
			else text = new FlxText(350, FlxG.height / 2 - 30 * CharSongList.getSongsByChar(charArray[curSelected]).length +  i *  30 * CharSongList.getSongsByChar(charArray[curSelected]).length, FlxG.width, "???");
			text.setFormat("Sonic CD Menu Font Regular", 36, 0xFFFFFFFF, CENTER);
			text.ID = i;
			textgrp.add(text);
		}

		 #if windows
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In the Freeplay Menu", null);
		 #end

		add(whiteshit);

		super.create();
	}
	override function update(elapsed:Float)
	{

		scrollingBg.y += 1;

		super.update(elapsed);

		var upP = FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W;
		var downP = FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S;
		var accepted = controls.ACCEPT;


		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.DPAD_UP)
			{
				changeSelection(-1);
			}
			if (gamepad.justPressed.DPAD_DOWN)
			{
				changeSelection(1);
			}
		}

		if (cdman)
		{
			if (upP)
			{
				changeSelection(-1);
			}
			if (downP)
			{
				changeSelection(1);
			}
		}



		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (!selecting) FlxG.switchState(new MainMenuState());
			else
			{
				scoreText.text = "";
				curSongSelected = 0;
				selecting = false;
				textgrp.forEach(function(text:FlxText)
				{
					FlxTween.cancelTweensOf(text);
					text.alpha = 1;
				});
			}
		}


		if (accepted && cdman && selecting)
		{		
			if (charUnlocked.contains(charArray[curSelected]))
			{
				cdman = false;

				var songArray:Array<String> = CharSongList.getSongsByChar(charArray[curSelected]);

				PlayState.SONG = Song.loadFromJson(songArray[curSongSelected].toLowerCase() + '-hard', songArray[curSongSelected].toLowerCase());
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = 2;
				PlayState.storyWeek = 1;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				PlayStateChangeables.nocheese = false;
				switch(songArray[curSongSelected]){
					default:
						FlxTween.tween(whiteshit, {alpha: 1}, 0.4);
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;
						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							LoadingState.loadAndSwitchState(new PlayState());
						});
				}
			}
			else
			{
				cdman = false;
				FlxG.sound.play(Paths.sound('deniedMOMENT'), 1, false, null, false, function()
				{
					cdman = true;
				});
			}
		}
		if (accepted && cdman && !selecting)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			selecting = true;
			if (textgrp.members != null)
				{
					textgrp.forEach(function(text:FlxText)
					{
						FlxTween.cancelTweensOf(text);
						text.alpha = 1;
						if (text.ID == curSongSelected)
						{
							scoreText.text = "Score: " + Highscore.getScore(CharSongList.getSongsByChar(charArray[curSelected])[curSongSelected], 2);
							FlxTween.tween(text, {alpha: 0.5}, 0.5, {ease: FlxEase.expoOut, type: FlxTween.PINGPONG});
						}
					});
				}

		}

	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
	}

	function changeSelection(change:Int = 0)
	{

		#if !switch
		// NGio.logEvent('Fresh');
		#end

		if (!selecting)
		{
			if (change == 1 && curSelected != charArray.length - 1)
			{
				cdman = false;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				FlxTween.tween(boxgrp ,{y: boxgrp.y - 415}, 0.2, {ease: FlxEase.expoOut, onComplete: function(sus:FlxTween)
					{
						cdman = true;
					}
				});

			}
			else if (change == -1 && curSelected != 0)
			{
				cdman = false;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				FlxTween.tween(boxgrp ,{y: boxgrp.y + 415}, 0.2, {ease: FlxEase.expoOut, onComplete: function(sus:FlxTween)
					{
						cdman = true;
					}
				});

			}
			if ((change == 1 && curSelected != charArray.length - 1) || (change == -1 && curSelected != 0)) // This is a.
			{
				if (textgrp.members != null)
				{
					textgrp.forEach(function(text:FlxText)
					{
						text.destroy();
					});
				}
				curSelected = curSelected + change;
				boxgrp.forEach(function(sprite:FlxSkewedSprite)
				{
					if (sprite.ID == curSelected)
					{
						FlxTween.tween(sprite, {alpha: 1}, 0.2);
						FlxTween.tween(sprite.scale, {x: 0.58, y: 0.58}, 0.2, {ease: FlxEase.expoOut});
					}
					else
					{
						FlxTween.tween(sprite, {alpha: 0.5}, 0.2);
						FlxTween.tween(sprite.scale, {x: 0.465, y: 0.465}, 0.2, {ease: FlxEase.expoOut});
					}
				});
				for (i in 0...CharSongList.getSongsByChar(charArray[curSelected]).length)
				{
					var text:FlxText;
					if (charUnlocked.contains(charArray[curSelected])) text = new FlxText(350, FlxG.height / 2 - 30 * CharSongList.getSongsByChar(charArray[curSelected]).length +  i *  30 * CharSongList.getSongsByChar(charArray[curSelected]).length, FlxG.width, StringTools.replace(CharSongList.getSongsByChar(charArray[curSelected])[i], "-", " "));
					else text = new FlxText(350, FlxG.height / 2 - 30 * CharSongList.getSongsByChar(charArray[curSelected]).length +  i *  30 * CharSongList.getSongsByChar(charArray[curSelected]).length, FlxG.width, "???");
					text.setFormat("Sonic CD Menu Font Regular", 36, 0xFFFFFFFF, CENTER);
					text.ID = i;
					textgrp.add(text);
				}
				if (charUnlocked.contains(charArray[curSelected])) charText.text = charArray[curSelected];
				else charText.text = '???';
				
			}
		}
		else
		{
			var songArray:Array<String> = CharSongList.getSongsByChar(charArray[curSelected]);
			var nextSelected = curSongSelected + change;
			if(nextSelected<0)nextSelected=songArray.length-1;
			if(nextSelected>=songArray.length)nextSelected=0;
			if (curSongSelected!=nextSelected)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				curSongSelected += change;
				if (textgrp.members != null)
				{
					textgrp.forEach(function(text:FlxText)
					{
						FlxTween.cancelTweensOf(text);
						text.alpha = 1;
						if (text.ID == curSongSelected)
						{
							scoreText.text = "Score: " + Highscore.getScore(songArray[curSongSelected], 2);
							FlxTween.tween(text, {alpha: 0.5}, 0.5, {ease: FlxEase.expoOut, type: FlxTween.PINGPONG});
						}
					});
				}
			}
		}


		// NGio.logEvent('Fresh');



	}

}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
