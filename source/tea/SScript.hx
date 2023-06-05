package tea;

import ex.*;

import haxe.Exception;

import hscriptBase.*;
import hscriptBase.Expr;

#if openflPos
import openfl.Assets;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import tea.backend.SScriptX;

using StringTools;

typedef SCall =
{
	public var ?fileName(default, null):String;
	public var ?className(default, null):String;
	public var succeeded(default, null):Bool;
	public var calledFunction(default, null):String;
	public var returnValue(default, null):Null<Dynamic>;
	public var exceptions(default, null):Array<Exception>;
}

/**
	The base class for dynamic Haxe scripts.

	A SScript can be a class script or a Haxe Script. 
	
	Once a SScript instance is created, it can't switch back to a class or Haxe script.
**/
@:structInit
@:access(hscriptBase.Interp)
@:access(hscriptBase.Parser)
@:access(tea.backend.SScriptX)
@:access(ScriptClass)
@:access(AbstractScriptClass)
class SScript
{
	/**
		Use this to access to interpreter's variables!
	**/
	public var variables(get, never):Map<String, Dynamic>;

	#if openflPos
	/**
	    `WARNING`: For `openfl` targets, you need to clear this map before switching states otherwise this map
		will cause memory leaks!

		This map is used for Ex scripts (scripts with classes).

		If a class is extended, this map will be checked if there is an instance of the super class.
		If an instance is found, the instance will be used for super class.

		Example:

		```haxe
		var tea:SScript = {};
		var superClass:ExampleClass = new ExampleClass();
		SScript.superClassInstances["ExampleClass"] = superClass;
		tea.doString('class ChildClass extends ExampleClass {}'); // Variable `superClass` is used for this script.
		```
	**/
	#else
	/**
		This map is used for Ex scripts (scripts with classes).

		If a class is extended, this map will be checked if there is an instance of the super class.
		If an instance is found, the instance will be used for super class.

		Example:

		```haxe
		var tea:SScript = {};
		var superClass:ExampleClass = new ExampleClass();
		SScript.superClassInstances["ExampleClass"] = superClass;
		tea.doString('class ChildClass extends ExampleClass {}'); // Variable `superClass` is used for this script.
		```
 	**/
	#end
	public static var superClassInstances(default, null):Map<String, Dynamic> = [];

	/**
		Every created SScript will be mapped to this map. 
	**/
	public static var global(default, null):Map<String, SScript> = [];

	/**
		Main interpreter and executer. 

		Do not use `interp.variables.set` to set variables!
		Instead, use `set`.
	**/
	public var interp(default, null):Interp;

	/**
		An unique parser for the script to parse strings.
	**/
	public var parser(default, null):Parser;

	/**
		The script to execute. Gets set automatically if you create a `new` SScript.
	**/
	public var script(default, null):String = "";

	/**
		This variable tells if this script is active or not.

		Set this to false if you do not want your script to get executed!
	**/
	public var active:Bool = true;

	/**
		This string tells you the path of your script file as a read-only string.
	**/
	public var scriptFile(default, null):String = "";

	/**
		If true, enables error traces from the functions.
	**/
	public var traces:Bool;

	/**
		Tells if this script is in EX mode, in EX mode you can only use `class`, `import` and `package`.
	**/
	public var exMode(get, never):Bool;

	/**
		Package path of this script. Gets set automatically when you use `package`.
	**/
	public var packagePath(get, null):String = "";

	/**
		A list of classes in the current script.

		Will be null if there are no classes in this script.
	**/
	public var classes(get, never):Map<String, AbstractScriptClass>;

	/**
		The name of the current class in this script.

		When a script created, `currentClass` becomes the first class in that script (if there are any classes in script).
	**/
	public var currentClass(get, set):String;

	/**
		Reference to script class in this script.

		To change, change `currentClass`.
	**/
	public var currentScriptClass(get, never):AbstractScriptClass;

	/**
		Reference to super class of `currentScriptClass`.
	**/
	public var currentSuperClass(get, never):Class<Dynamic>;

	@:noPrivateAccess static var defines(default, null):Map<String, String>;

	@:noPrivateAccess var parsingExceptions(default, null):Array<Exception> = new Array();
	@:noPrivateAccess var scriptX(default, null):SScriptX;

	/**
		Creates a new SScript instance.

		@param scriptPath The script path or the script itself (Files are recommended).
		@param Preset If true, SScript will set some useful variables to interp. Override `preset` to customize the settings.
	**/
	public function new(?scriptPath:String = "", ?preset:Bool = true)
	{
		#if sys
		if (defines == null)
		{
			defines = new Map();

			var contents:String = null;
			var path:String = macro.Macro.definePath;

			if (FileSystem.exists(path))
			{
				contents = File.getContent(path);
				FileSystem.deleteFile(path);

				for (i in contents.split('\n'))
				{
					i = i.trim();

					var d1 = null, d2 = null;
					var define:Array<String> = i.split('|');
					if (define.length == 2)
					{
						d1 = define[0];
						d2 = define[1];
					}
					else if (define.length == 1)
					{
						d1 = define[0];
						d2 = '1';
					}

					if (d1 != null)
						defines[d1] = d2 != null ? d2 : '1';
				}
			}
			else 
			{
				defines["true"] = "1";
				defines["haxe"] = "1";
				defines["sys"] = "1";

				#if hscriptPos
				defines["hscriptPos"] = "1";
				#end
			}
		}
		#else
		if (defines == null)
			defines = new Map();

		defines["true"] = "1";
		defines["haxe"] = "1";

		#if hscriptPos
		defines["hscriptPos"] = "1";
		#end
		#end

		interp = new Interp();
		interp.setScr(this);

		parser = new Parser();
		parser.script = this;
		parser.setIntrp(interp);
		interp.setPsr(parser);

		if (preset)
			this.preset();

		doFile(scriptPath);
	}

	/**
		Executes this script once.

		Executing scripts with classes will not do anything.
	**/
	public function execute():Void
	{
		if (scriptX != null)
			return;

		if (interp == null || !active)
			return;

		if (scriptX == null && script != null && script.length > 0)
		{
			var expr:Expr = parser.parseString(script, if (scriptFile != null && scriptFile.length > 0) scriptFile else "SScript");
			interp.execute(expr);
		}
	}

	/**
		Sets a variable to this script. 

		If `key` already exists it will be replaced.
		@param key Variable name.
		@param obj The object to set. If the object is a macro class, function will be aborted.
		@return Returns this instance for chaining.
	**/
	public function set(key:String, obj:Dynamic):SScript
	{
		function setVar(key:String, obj:Dynamic):Void
		{
			if (Tools.keys.contains(key))
				throw '$key is a keyword, set something else';
			else if (macro.Macro.macroClasses.contains(obj))
				throw '$key cannot be a Macro class (tried to set ${Type.getClassName(obj)})';

			SScriptX.variables[key] = obj;
			if (scriptX != null)
			{
				var value:Dynamic = obj;
				scriptX.set(key, value);
			}
			else
			{
				if (interp == null || !active)
				{
					if (traces)
					{
						if (interp == null)
							trace("This script is unusable!");
						else
							trace("This script is not active!");
					}
				}
				else
					interp.variables[key] = obj;
			}
		}

		setVar(key, obj);
		return this;
	}

	/**
		This is a helper function to set classes easily.
		For example; if `cl` is `sys.io.File` class, it'll be set as `File`.
		@param cl The class to set. It cannot be macro classes.
		@return this instance for chaining.
	**/
	public function setClass(cl:Class<Dynamic>):SScript
	{
		if (cl == null)
		{
			if (traces)
			{
				trace('Class cannot be null');
			}

			return null;
		}

		var clName:String = Type.getClassName(cl);
		if (clName != null)
		{
			if (clName.split('.').length > 1)
			{
				clName = clName.split('.')[clName.split('.').length - 1];
			}

			set(clName, cl);
		}
		return this;
	}

	/**
		Sets a class to this script from a string.
		`cl` will be formatted, for example: `sys.io.File` -> `File`.
		@param cl The class to set. It cannot be macro classes.
		@return this instance for chaining.
	**/
	public function setClassString(cl:String):SScript
	{
		if (cl == null || cl.length < 1)
		{
			if (traces)
				trace('Class cannot be null');

			return null;
		}

		var cls:Class<Dynamic> = Type.resolveClass(cl);
		if (cls != null)
		{
			if (cl.split('.').length > 1)
			{
				cl = cl.split('.')[cl.split('.').length - 1];
			}

			set(cl, cls);
		}
		return this;
	}

	/**
		Returns the local variables in this script as a fresh map.

		Changing any value in returned map will not change the script's variables.
	**/
	public function locals():Map<String, Dynamic>
	{
		if (scriptX != null)
		{
			var newMap:Map<String, Dynamic> = new Map();
			if (scriptX.interpEX.locals != null)
				for (i in scriptX.interpEX.locals.keys())
				{
					var v = scriptX.interpEX.locals[i];
					if (v != null)
						newMap[i] = v.r;
				}
			return newMap;
		}

		var newMap:Map<String, Dynamic> = new Map();
		for (i in interp.locals.keys())
		{
			var v = interp.locals[i];
			if (v != null)
				newMap[i] = v.r;
		}
		return newMap;
	}

	/**
		Unsets a variable from this script. 

		If a variable named `key` doesn't exist, unsetting won't do anything.
		@param key Variable name to unset.
		@return Returns this instance for chaining.
	**/
	public function unset(key:String):SScript
	{
		if (scriptX != null)
		{
			scriptX.interpEX.variables.remove(key);
			SScriptX.variables.remove(key);
			for (i in InterpEx.interps)
			{
				if (i.variables != null && i.variables.exists(key))
					i.variables.remove(key);
				else if (i.locals != null && i.locals.exists(key))
					i.locals.remove(key);
			}
		}
		else 
		{
			if (interp == null || !active || key == null || !interp.variables.exists(key))
				return null;

			interp.variables.remove(key);
		}

		return this;
	}

	/**
		Gets a variable by name. 

		If a variable named as `key` does not exists return is null.
		@param key Variable name.
		@return The object got by name.
	**/
	public function get(key:String):Dynamic
	{
		if (scriptX != null)
		{
			return
			{
				var l = locals();
				if (l.exists(key))
					l[key];
				else if (scriptX.interpEX.variables.exists(key))
					scriptX.interpEX.variables[key];
				else if (classes != null) // script with classes will return hscriptBase.Expr if a function is searched
				{
					for (k => i in classes)
					{
						if (i != null && i.listFunctions().exists(key) && i.listFunctions()[key] != null)
							return '#fun';
					}
					null;
				}
				else if (SScriptX.variables.exists(key))
					SScriptX.variables[key];
				else
					null;
			}
		}

		if (interp == null || !active)
		{
			if (traces)
			{
				if (interp == null)
					trace("This script is unusable!");
				else
					trace("This script is not active!");
			}

			return null;
		}

		var l = locals();
		if (l.exists(key))
			return l[key];

		return if (exists(key)) interp.variables[key] else null;
	}

	/**
		Calls a function from the script file.

		`WARNING:` You MUST execute the script at least once to get the functions to script's interpreter.
		If you do not execute this script and `call` a function, script will ignore your call.

		@param func Function name in script file. 
		@param args Arguments for the `func`. If the function does not require arguments, leave it null.
		@param className If provided, searches the specific class. If the function is not found, other classes will be searched.
		@return Returns an unique structure that contains called function, returned value etc. Returned value is at `returnValue`.
	**/
	public function call(func:String, ?args:Array<Dynamic>, ?className:String):SCall
	{
		var scriptFile:String = if (scriptFile != null && scriptFile.length > 0) scriptFile else "";
		var caller:SCall = {
			exceptions: [],
			calledFunction: func,
			succeeded: false,
			returnValue: null
		}
		if (scriptFile != null && scriptFile.length > 0)
			caller = {
				fileName: scriptFile,
				exceptions: [],
				calledFunction: func,
				succeeded: false,
				returnValue: null
			}
		if (args == null)
			args = new Array();

		var pushedExceptions:Array<String> = new Array();
		function pushException(e:String)
		{
			if (!pushedExceptions.contains(e))
				caller.exceptions.push(new Exception(e));
			
			pushedExceptions.push(e);
		}
		if (func == null)
		{
			if (traces)
				trace('Function name cannot be null for $scriptFile!');

			pushException('Function name cannot be null for $scriptFile!');
			return caller;
		}
		var callX:SCall = null;
		if (scriptX != null)
		{
			callX = scriptX.callFunction(func);
		}
		else
		{
			if (exists(func) && Type.typeof(get(func)) != TFunction)
			{
				if (traces)
					trace('$func is not a function');

				pushException('$func is not a function');
			}

			else if (interp == null || !exists(func))
			{
				if (interp == null)
				{
					if (traces)
						trace('Interpreter is null!');

					pushException('Interpreter is null!');
				}
				else
				{
					if (traces)
						trace('Function $func does not exist in $scriptFile.');

					if (scriptFile != null && scriptFile.length > 1)
						pushException('Function $func does not exist in $scriptFile.');
					else 
						pushException('Function $func does not exist in SScript instance.');
				}
			}
			else 
			{
				var oldCaller = caller;
				try
				{
					var functionField:Dynamic = Reflect.callMethod(this, get(func), args);
					caller = {
						exceptions: caller.exceptions,
						calledFunction: func,
						succeeded: true,
						returnValue: functionField
					};
					if (scriptFile != null && scriptFile.length > 0)
						caller = {
							fileName: scriptFile,
							exceptions: caller.exceptions,
							calledFunction: func,
							succeeded: true,
							returnValue: functionField
						};
				}
				catch (e)
				{
					caller = oldCaller;
					pushException(e.details());
				}
			}
		}
		if (!caller.succeeded && (callX == null || !callX.succeeded))
		{
			for (i in parsingExceptions)
			{
				pushException(i.details());
				
				if (callX != null)
					callX.exceptions.push(new Exception(i.details()));
			}
		}

		return if (scriptX != null) callX else caller;
	}

	/**
		Clears all of the keys assigned to this script.

		@return Returns this instance for chaining.
	**/
	public function clear():SScript
	{
		if (scriptX != null)
		{
			scriptX.interpEX.variables = new Map();
			return this;
		}

		if (interp == null)
			return this;

		var importantThings:Array<String> = ['true', 'false', 'null', 'trace'];

		for (i in interp.variables.keys())
			if (!importantThings.contains(i))
				interp.variables.remove(i);

		return this;
	}

	/**
		Tells if the `key` exists in this script's interpreter.
		@param key The string to look for.
		@return Returns true if `key` is found in interpreter.
	**/
	public function exists(key:String):Bool
	{
		if (scriptX != null)
		{
			if (scriptX.currentScriptClass != null
				&& scriptX.currentScriptClass.listFunctions() != null
				&& scriptX.currentScriptClass.listFunctions().exists(key))
				return true;

			var l = locals();
			var v = scriptX.interpEX.variables;
			return if (l != null && l.exists(key)) true else if (v != null && v.exists(key)) true else false;
		}

		if (interp == null)
			return false;
		if (locals().exists(key))
			return locals().exists(key);

		return interp.variables.exists(key);
	}

	/**
		Sets some useful variables to interp to make easier using this script.
		Override this function to set your custom sets aswell.
	**/
	public function preset():Void
	{
		setClass(Math);
		setClass(Std);
		setClass(StringTools);
		setClass(Date);
		setClass(DateTools);

		#if sys
		setClass(File);
		setClass(FileSystem);
		setClass(Sys);
		#end

		#if openflPos
		setClass(Assets);
		#end
	}

	function doFile(scriptPath:String)
	{
		if (scriptPath != null && scriptPath.length > 0)
			try
				scriptX = new SScriptX(scriptPath, this)
			catch (e)
			{
				parsingExceptions.push(new Exception(e.details()));
				scriptX = null;
			}
		
		if (scriptPath != null && scriptPath.length > 0)
		{
			#if sys
				#if openflPos
				if ((try Assets.exists(scriptPath) catch (e) false) || FileSystem.exists(scriptPath))
				#else
				if (FileSystem.exists(scriptPath))
				#end
				{
					scriptFile = scriptPath;
					#if openflPos
					script = try Assets.getText(scriptPath) catch (e) null;
					if (script == null)
						script = File.getContent(scriptPath);
					#else
					script = File.getContent(scriptPath);
					#end
				}
				else
				{
					scriptFile = "";
					script = scriptPath;
				}
			#else
				#if openflPos
				if (try Assets.exists(scriptPath) catch (e) false)
				{
					script = try Assets.getText(scriptPath) catch (e) null;
					if (script == null)
						script = scriptPath;
					else
						scriptFile = scriptPath;
				}
				else
				{
					script = scriptPath;
					scriptFile = "";
				}
				#else
				script = scriptPath;
				scriptFile = "";
				#end
			#end

			execute();

			if (scriptX != null)
			{
				if (scriptX.scriptFile != null && scriptX.scriptFile.length > 0)
					global[scriptX.scriptFile] = this;
			}
			else if (scriptFile != null && scriptFile.length > 0)
				global[scriptFile] = this;
			else if (script != null && script.length > 0)
				global[script] = this;
		}
	}

	/**
		Executes a string once instead of a script file.

		This does not change your `scriptFile` but it changes `script`.

		This function should be avoided whenever possible, when you do a string a lot variables remain unchanged.
		Always try to use a script file.
		@param string String you want to execute.
		@return Returns this instance for chaining. Will return `null` if failed.
	**/
	public function doString(string:String):SScript
	{
		var og:String = "SScript";
		if (string == null || string.length < 1)
			return this;
		#if sys
        else #if openflPos if ((try Assets.exists(string) catch (e) false) || FileSystem.exists(string)) #else if (FileSystem.exists(string)) #end
		{
			og = "" + string;
			scriptFile = string;
			string = File.getContent(string);
		}
		#elseif openflPos
		if (try Assets.exists(string) catch (e) false)
		{
			og = "" + string;
			scriptFile = string;
			string = try Assets.getText(string) catch (e) string;
		}
		#end
		if (scriptX != null)
		{
			if (!global.exists(string))
				global[string] = this;

			scriptX.doString(string, og);
			return this;
		}
		if (!active || interp == null)
			return null;

		if (scriptX == null)
		{
			try
			{
				var expr:Expr = parser.parseString(string, og);
				interp.execute(expr);
				script = string;
			}
			catch (e)
			{
				script = "";

				try
					scriptX = new SScriptX(string, this)
				catch (e)
				{
					parsingExceptions.push(new Exception(e.details()));
					scriptX = null;
				}
			}
		}

		if (!global.exists(script) && script != null && script.length > 0)
			global[script] = this;

		return this;
	}

	inline function toString():String
	{
		if (scriptFile != null && scriptFile.length > 0)
			return scriptFile;

		return "[object Object]";
	}

	#if (sys || openflPos)
	/**
		Checks for scripts in the provided path and returns them as an array.

		Make sure `path` is a directory!

		If `extensions` is not `null`, files' extensions will be checked.
		Otherwise, only files with the `.hx` extensions will be checked and listed.

		@param path The directory to check for. Nondirectory paths will be ignored.
		@param extensions Optional extension to check in file names.
		@return The script array.
	**/
	#else
	/**
		Checks for scripts in the provided path and returns them as an array.

		This function will always return an empty array, because you are targeting an unsupported target.
		@return An empty array.
	**/
	#end
	public static function listScripts(path:String, ?extensions:Array<String>):Array<SScript>
	{
		if (!path.endsWith('/'))
			path += '/';

		if (extensions == null || extensions.length < 1)
			extensions = ['hx'];

		var list:Array<SScript> = [];
		#if sys
		if (FileSystem.exists(path) && FileSystem.isDirectory(path))
		{
			var files:Array<String> = FileSystem.readDirectory(path);
			for (i in files)
			{
				var hasExtension:Bool = false;
				for (l in extensions)
				{
					if (i.endsWith(l))
					{
						hasExtension = true;
						break;
					}
				}
				if (hasExtension && FileSystem.exists(path + i))
					list.push(new SScript(path + i));
			}
		}
		#elseif openflPos
		function readDirectory(path:String):Array<String> 
		{
			if (path.endsWith('/') && path.length > 1)
				path = path.substring(0, path.length - 1);

			var assetsLibrary:Array<String> = [];
			for (folder in Assets.list().filter(list -> list.contains(path))) 
			{
				var myFolder:String = folder;
				myFolder = myFolder.replace('${path}/', '');

				if (myFolder.contains('/'))
					myFolder = myFolder.replace(myFolder.substring(myFolder.indexOf('/'), myFolder.length), '');

				myFolder = '$path/${myFolder}';
				
				if (!myFolder.startsWith('.') && !assetsLibrary.contains(myFolder))
					assetsLibrary.push(myFolder);
		
				assetsLibrary.sort((a, b) -> ({
					a = a.toUpperCase();
					b = b.toUpperCase();
					return a < b ? -1 : a > b ? 1 : 0;
				}));
			}
		
			return assetsLibrary;
		}
		for (i in readDirectory(path))
		{
			var hasExtension:Bool = false;
			for (l in extensions)
			{
				if (i.endsWith(l))
				{
					hasExtension = true;
					break;
				}
			}
			if (hasExtension && Assets.exists(i))
				list.push(new SScript(i));
		}
		#end

		return list;
	}

	function get_variables():Map<String, Dynamic>
	{
		return if (scriptX != null) scriptX.interpEX.variables else interp.variables;
	}

	function setPackagePath(p):String
	{
		return packagePath = p;
	}

	function get_packagePath():String
	{
		return if (scriptX != null) scriptX.interpEX.pkg else packagePath;
	}

	function get_classes():Map<String, AbstractScriptClass>
	{
		return if (scriptX != null)
		{
			var newMap:Map<String, AbstractScriptClass> = new Map();
			for (i => k in scriptX.classes)
				if (i != null && k != null)
					newMap[i] = k;
			newMap;
		}
		else [];
	}

	function get_currentScriptClass():AbstractScriptClass
	{
		return if (scriptX != null) scriptX.currentScriptClass else null;
	}

	function get_currentSuperClass():Class<Dynamic>
	{
		return if (scriptX != null) scriptX.currentSuperClass else null;
	}

	function set_currentClass(value:String):String
	{
		return if (scriptX != null) scriptX.currentClass = value else null;
	}

	function get_currentClass():String
	{
		return if (scriptX != null) scriptX.currentClass else null;
	}

	function get_exMode():Bool 
	{
		return scriptX != null;
	}
}