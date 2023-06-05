package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import PlayState;
import Main;
import ClientPrefs;
import GameOverSubstate;
import Paths;
import Note;
import Alphabet;
import InputFormatter;
import Character;
import Conductor;
import CreditsState;

final class FunkinSScript extends tea.SScript
{
	public function new(?scriptFile:String = "", ?preset:Bool = true)
	{
		super(scriptFile, preset);

		traces = false;
		
		execute();
	}

	override function preset():Void
	{
		super.preset();

		set('Alphabet', Alphabet);
		set('Application', Application);
		set('Assets', Assets);
		set('Character', Character);
		set('Conductor', Conductor);
		set('CreditsState', CreditsState);
		set('FlxAngle', FlxAngle);
		set('FlxBar', FlxBar);
		set('FlxBasic', FlxBasic);
		set('FlxCamera', FlxCamera);
		set('FlxEase', FlxEase);
		set('FlxG', FlxG);
		set('FlxGroup', FlxGroup);
		set('FlxMath', FlxMath);
		set('FlxObject', FlxObject);
		set('FlxSave', FlxSave);
		set('FlxSound', FlxSound);
		set('FlxSprite', FlxSprite);
		set('FlxSpriteGroup', FlxSpriteGroup);
		set('FlxText', FlxText);
		set('FlxTextBorderStyle', FlxTextBorderStyle);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxTypedGroup', FlxTypedGroup);
		set('FlxTypedSpriteGroup', FlxTypedSpriteGroup);
		set('ClientPrefs', ClientPrefs);
		set('GameOverSubstate', GameOverSubstate);
		set('InputFormatter', InputFormatter);
		set('Lib', Lib);
		set('Main', Main);
		set('Note', Note);
		set('Paths', Paths);
		set('PlayState', PlayState);
                set('game', PlayState.instance);
		set('this', this);

		set('add', function(FlxBasic:FlxBasic)
		{
			return PlayState.instance.add(FlxBasic);
		});

		set('get', function(id:String)
		{
			var dotList:Array<String> = id.split('.');
			if (dotList.length > 1)
			{
				var property:Dynamic = Reflect.getProperty(PlayState.instance, dotList[0]);
				for (i in 1...dotList.length - 1)
				{
					property = Reflect.getProperty(property, dotList[i]);
				}

				return Reflect.getProperty(property, dotList[dotList.length - 1]);
			}
			return Reflect.getProperty(PlayState.instance, id);
		});

		set('set', function(id:String, value:Dynamic)
		{
			var dotList:Array<String> = id.split('.');
			if (dotList.length > 1)
			{
				var property:Dynamic = Reflect.getProperty(PlayState.instance, dotList[0]);
				for (i in 1...dotList.length - 1)
				{
					property = Reflect.getProperty(property, dotList[i]);
				}

				return Reflect.setProperty(property, dotList[dotList.length - 1], value);
			}
			return Reflect.setProperty(PlayState.instance, id, value);
		});

		set('getColorFromRGB', function(r:Int, g:Int, b:Int)
		{
			return FlxColor.fromRGB(r, b, g);
		});

		set('FlxWhite', FlxColor.WHITE);
		set('CENTER', FlxTextAlign.CENTER);
	}
}
