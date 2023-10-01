package;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import lime.app.Application;
#if windows
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import lime.system.ThreadPool;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class CacheState extends FlxState
{
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 1, 0xFFAB6F00);
	var splash:FlxSprite;
	var loadingSpeen:FlxSprite;
	var freakz:FlxText;
	var randomTxt:FlxText;
	
	var isTweening:Bool = false;
	var lastString:String = '';

	override function create()
	{
	
		FlxG.mouse.visible = true;

		FlxG.worldBounds.set(0,0);

		super.create();

		splash = new FlxSprite().loadGraphic(Paths.image("logoName"));
		splash.screenCenter();
		splash.y -= 60;
		splash.antialiasing = true;
		add(splash);
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x553D0468, 0xFFFFA500], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);
		
		var bottomPanel:FlxSprite = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, 0xFF000000);
		bottomPanel.alpha = 0.5;
		add(bottomPanel);	
		
		randomTxt = new FlxText(20, FlxG.height - 80, 1000, "", 26);
		randomTxt.scrollFactor.set();
		randomTxt.setFormat("VCR OSD Mono", 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(randomTxt);
		
		loadingSpeen = new FlxSprite().loadGraphic(Paths.image("loading_speen"));
		loadingSpeen.screenCenter(X);
        loadingSpeen.setGraphicSize(Std.int(loadingSpeen.width * 0.89));
        loadingSpeen.x = FlxG.width - 91;
		loadingSpeen.y = FlxG.height - 91;
		loadingSpeen.angularVelocity = 180;
		loadingSpeen.antialiasing = true;
		add(loadingSpeen);
		
		freakz = new FlxText(12, FlxG.height - 24, 0, "", 8);
		freakz.scrollFactor.set();
		freakz.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(freakz);
		freakz.text = " Loading... ";

        new FlxTimer().start(10, function(tmr:FlxTimer)
		{
            goToState();
        });

		super.create();
	}
	
	var selectedSomethin:Bool = false;
	var timer:Float = 0;
	
	override function update(elapsed:Float) 
	{
		if (!selectedSomethin){
			if (isTweening){
				randomTxt.screenCenter(X);
				timer = 0;
			}else{
				randomTxt.screenCenter(X);
				timer += elapsed;
				if (timer >= 3)
				{
					changeText();
				}
			}
		}
		super.update(elapsed);
	}

	function goToState()
	{
		FlxG.switchState(new TitleState());
	}
	
	function changeText()
	{
		var selectedText:String = '';
		var textArray:Array<String> = CoolUtil.coolTextFile(Paths.txt('sbEngineTip'));

		randomTxt.alpha = 1;
		isTweening = true;
		selectedText = textArray[FlxG.random.int(0, (textArray.length - 1))].replace('--', '\n');
		FlxTween.tween(randomTxt, {alpha: 0}, 1, {
			ease: FlxEase.linear,
			onComplete: function(freak:FlxTween)
			{
				if (selectedText != lastString)
				{
					randomTxt.text = selectedText;
					lastString = selectedText;
				}
				else
				{
					selectedText = textArray[FlxG.random.int(0, (textArray.length - 1))].replace('--', '\n');
					randomTxt.text = selectedText;
				}

				randomTxt.alpha = 0;

				FlxTween.tween(randomTxt, {alpha: 1}, 1, {
					ease: FlxEase.linear,
					onComplete: function(freak:FlxTween)
					{
						isTweening = false;
					}
				});
			}
		});
	}
}