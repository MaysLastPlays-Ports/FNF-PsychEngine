package;

#if android
import android.Permissions;
import android.content.Context;
import android.os.Build;
import android.widget.Toast;
import android.os.Environment;
import lime.app.Application;
#end
import haxe.CallStack;
import haxe.io.Path;
import lime.system.System as LimeSystem;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#else
import haxe.Log;
#end

using StringTools;

enum StorageType
{
	DATA;
	EXTERNAL;
	EXTERNAL_DATA;
	MEDIA;
}

/**
 * ...
 * @author Mihai Alexandru (M.A. Jigsaw)
 * @modified mcagabe19
 */
class SUtil
{
	/**
	 * This returns the external storage path that the game will use by the type.
	 */
	public static function getPath(type:StorageType = MEDIA):String
	{
		var daPath:String = '';

		#if android
		switch (type)
		{
			case DATA:
				daPath = Context.getFilesDir() + '/';
			case EXTERNAL_DATA:
				daPath = Context.getExternalFilesDir(null) + '/';
			case EXTERNAL:
				daPath = Environment.getExternalStorageDirectory() + '/' + '.' + '/' + Application.current.meta.get('file') + '/';
			case MEDIA:
				daPath = Environment.getExternalStorageDirectory()
					+ '/'
					+ 'Android'
					+ '/'
					+ 'media'
					+ '/'
					+ Application.current.meta.get('packageName')
					+ '/';
		}
		#elseif ios
		daPath = LimeSystem.applicationStorageDirectory;
		#end

		return daPath;
	}

	/**
	 * A simple function that checks for storage permissions and game files/folders.
	 */
	public static function doTheCheck():Void
	{
		#if android
		if (!Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE)
			&& !Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE))
		{
			if (VERSION.SDK_INT >= VERSION_CODES.M)
			{
				Permissions.requestPermissions([Permissions.WRITE_EXTERNAL_STORAGE, Permissions.READ_EXTERNAL_STORAGE]);

				/**
				 * Basically for now i can't force the app to stop while its requesting a android permission, so this makes the app to stop while its requesting the specific permission
				 */
				Lib.application.window.alert('If you accepted the permissions you are all good!' + "\nIf you didn't then expect a crash"
					+ '\nPress Ok to see what happens',
					'Permissions?');
			}
			else
			{
				Lib.application.window.alert('Please grant the game storage permissions in app settings' + '\nPress Ok to close the app', 'Permissions?');
				LimeSystem.exit(1);
			}
		}
                #end

                #if mobile
		if (!FileSystem.exists(SUtil.getStorageDirectory() + 'mods'))
		{
			Lib.application.window.alert("Whoops, seems like you didn't extract the assets/mods folder from the .APK!\nPlease copy the assets/mods folder from the .APK to\n" + SUtil.getStorageDirectory(),
				'Error!');
			LimeSystem.exit(1);
		}
		else if (FileSystem.exists(SUtil.getStorageDirectory() + 'mods') && !FileSystem.isDirectory(SUtil.getStorageDirectory() + 'mods'))
		{
			Lib.application.window.alert("Why did you create a file called mods instead of copying the mods directory from the .APK?, expect a crash.",
				'Error!');
			LimeSystem.exit(1);
		}
		if (!sys.FileSystem.exists(SUtil.getPath()))
		{
			Lib.application.window.alert('Please create folder to\n' + SUtil.getPath() + '\nPress Ok to close the app', 'Error!');
			LimeSystem.exit(1);
		}
		#end
	}

	/**
	 * Uncaught error handler, original made by: Sqirra-RNG and YoshiCrafter29
	 */
	public static function gameCrashCheck():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		Lib.application.onExit.add(function(exitCode:Int)
		{
			if (Lib.current.loaderInfo.uncaughtErrorEvents.hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
				Lib.current.loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		});
	}

	private static function onError(e:UncaughtErrorEvent):Void
	{
		var msg:String = '${e.error}\n';

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case CFunction:
					msg += 'Non-Haxe (C) Function';
				case Module(m):
					msg += 'Module ($m)';
				case FilePos(s, file, line, column):
					msg += '$file (line $line)';
				case Method(classname, method):
					msg += '$classname (method $method)';
				case LocalFunction(name):
					msg += 'Local Function ($name)';
			}

			msg += '\n';
		}

		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		#if sys
		try
		{
			if (!FileSystem.exists(SUtil.getPath() + 'logs'))
				FileSystem.createDirectory(SUtil.getPath() + 'logs');

			File.saveContent(SUtil.getPath()
				+ 'logs/'
				+ Lib.application.meta.get('file')
				+ '-'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.log',
				msg);
		}
		catch (e:Dynamic)
		{
			#if android
			Toast.makeText("Error!\nClouldn't save the crash dump because:\n" + e, Toast.LENGTH_LONG);
			#else
			println("Error!\nClouldn't save the crash dump because:\n" + e);
			#end
		}
		#end

		println(msg);
		Lib.application.window.alert(msg, 'Error!');
		LimeSystem.exit(1);
	}

	#if sys
	/**
	 * This is mostly a fork of https://github.com/openfl/hxp/blob/master/src/hxp/System.hx#L595
	 */
	public static function mkDirs(directory:String):Void
	{
		var total:String = '';

		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');

		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				if (!FileSystem.exists(total))
					FileSystem.createDirectory(total);
			}
		}
	}

	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'you forgot to add something in your code lol'):Void
	{
		try
		{
			if (!FileSystem.exists(SUtil.getPath() + 'saves'))
				FileSystem.createDirectory(SUtil.getPath() + 'saves');

			File.saveContent(SUtil.getPath() + 'saves/' + fileName + fileExtension, fileData);
			#if android
			Toast.makeText("File Saved Successfully!", Toast.LENGTH_LONG);
			#end
		}
		catch (e:Dynamic)
		{
			#if android
			Toast.makeText("Error!\nClouldn't save the file because:\n" + e, Toast.LENGTH_LONG);
			#else
			println("Error!\nClouldn't save the file because:\n" + e);
			#end
		}
	}

        public static function saveClipboard(fileData:String = 'you forgot something to add in your code')
	{
		openfl.system.System.setClipboard(fileData);
                #if android
		Toast.makeText("Data Saved to Clipboard Successfully!", Toast.LENGTH_LONG);
                #end
	}

	public static function copyContent(copyPath:String, savePath:String):Void
	{
		try
		{
			if (!FileSystem.exists(savePath) && Assets.exists(copyPath))
			{
				if (!FileSystem.exists(Path.directory(savePath)))
					SUtil.mkDirs(Path.directory(savePath));

				File.saveBytes(savePath, Assets.getBytes(copyPath));
			}
		}
		catch (e:Dynamic)
		{
			#if android
			Toast.makeText("Error!\nClouldn't copy the file because:\n" + e, Toast.LENGTH_LONG);
			#else
			println("Error!\nClouldn't copy the file because:\n" + e);
			#end
		}
	}
	#end

	private static function println(msg:String):Void
	{
		#if sys
		Sys.println(msg);
		#else
		// Pass null to exclude the position.
		Log.trace(msg, null);
		#end
	}
}
