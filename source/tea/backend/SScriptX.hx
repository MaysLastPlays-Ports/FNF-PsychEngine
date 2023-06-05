package tea.backend;

import ex.*;

import haxe.DynamicAccess;
import haxe.Exception;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import tea.SScript.SCall;

#if openflPos
import openfl.Assets;
#end

/**
	A sub class for SScript, supports classes but it doesn't support any features of SScript.

	SScript will already have a SScriptX instance so don't use this class.
**/
@:access(ex.InterpEx)
@:access(SScript)
class SScriptX
{
	@:noPrivateAccess static var variables:Map<String, Dynamic> = new Map();

	static var NONE(default, null):Array<Exception> = new Array();

	var tea:SScript;

	@:noPrivateAccess var script:SScript;

	/**
		An unique interpreter for this instance of `SScriptX`.

		Do not mess with its properities!
	**/
	var interpEX(default, null):InterpEx = new InterpEx(false);

	/**
		List of the classes in provided script.

		Will refresh itself every time when a new script provided.
	**/
	var classes(default, null):DynamicAccess<AbstractScriptClass> = {};

	/**
		The name of the current class in this script.

		When a script created, `currentClass` becomes the first class in that script.
	**/
	var currentClass(default, set):String;

	/**
		Reference to script class in this script.

		To change, change `currentClass`.
	**/
	var currentScriptClass(default, null):AbstractScriptClass;

	/**
		Reference to super class of `currentScriptClass`.
	**/
	var currentSuperClass(get, never):Class<Dynamic>;

	/**
		A read-only string that references to the provided script file.

		Can be also the script itself.
	**/
	var scriptFile(default, null):String;

	/**
		Creates a new `SScriptX` instance.
		@param scriptFile The script file or the script itself. It is optional, but you'll need to `doString` after to use this instance.
	**/
	function new(?scriptFile:String = "", tea:SScript)
	{
		if (scriptFile != null && scriptFile.length > 0)
		{
			#if sys
			#if openflPos
			if ((try Assets.exists(scriptFile) catch (e) false) || FileSystem.exists(scriptFile))
			#else
			if (FileSystem.exists(scriptFile))
			#end
			{
				this.scriptFile = scriptFile;
				interpEX.origin = scriptFile;

				var contents:String = #if openflPos try Assets.getText(scriptFile) catch (e) #end File.getContent(scriptFile);
				interpEX.addModule(File.getContent(contents));
			}
			else
			{
				this.scriptFile = "";
				interpEX.addModule(scriptFile);
			}
			#else
			#if openflPos
			if ((try Assets.exists(scriptFile) catch (e) false))
			{
				this.scriptFile = scriptFile;
				var contents:String = try Assets.getText(scriptFile) catch (e) null;
				if (contents != null)
				{
					interpEX.origin = scriptFile;
					interpEX.addModule(contents);
				}
				else
				{
					this.scriptFile = "";
					interpEX.addModule(scriptFile);
				}
			}
			else
			{
			#end
				this.scriptFile = "";
				interpEX.addModule(scriptFile);
			#if openflPos
			}
			#end
			#end
		}
		else
			this.scriptFile = "";

		clearClasses();
		createClasses();

		this.tea = tea;
	}

	/**
		Tries the call the provided function in `className`.

		If `className` is null or not valid, `className` will be ignored and this script will try to call the same function in other available classes.
		@param func The function name to call.
		@param args Optional arguments, if null becomes `[]`.
		@param className Optional class to check.
		@return Returns the return value, the class name and exceptions (if there are any).
	**/
	function callFunction(func:String, ?args:Array<Dynamic>, ?className:String):SCall
	{
		var cl = className == null ? null : classes[className];
		if (cl != null)
		{
			return try {
				returnValue: cl.callFunction(func, args),
				className: className,
				calledFunction: func,
				succeeded: true,
				exceptions: NONE
			}
			catch (e) {
				returnValue: null,
				className: className,
				exceptions: [new Exception(e.details())],
				succeeded: false,
				calledFunction: func
			};
		}
		else
		{
			var cl:AbstractScriptClass = null;
			var exceptions:Array<Exception> = [];
			for (i in classes.keys())
			{
				cl = classes[i];
				try
				{
					currentClass = i;
					return {
						returnValue: cl.callFunction(func, args),
						className: i,
						calledFunction: func,
						succeeded: true,
						exceptions: NONE
					};
				}
				catch (e)
				{
					exceptions.push(new Exception(e.details()));
				}
			}

			if (cl == null)
			{
				if (scriptFile != null)
				{
					exceptions.push(new Exception('${if (scriptFile.length > 0) scriptFile else "This instance of SScript"} does not have any valid classes in it, returning $null.'));
				}
			}

			return {
				returnValue: null,
				className: className,
				exceptions: exceptions,
				calledFunction: func,
				succeeded: false
			};
		}
	}

	/**
		Sets a variable to this script. 

		If `key` already exists it will be replaced.
		@param key Variable name.
		@param obj The object to set. 
		@return Returns this instance for chaining.
	**/
	function set(key:String, value:Dynamic):SScriptX
	{
		if (interpEX == null)
			return null;

		interpEX.variables[key] = value;
		for (i in InterpEx.interps)
		{
			for (l => k in variables)
				if (!i.variables.exists(l))
					i.variables[l] = k;
		}
		return this;
	}

	function doString(string:String, ?origin:String):SScriptX
	{
		if (origin == 'SScript')
			origin = 'SScriptX';
		
		var vars = interpEX.variables.copy();
		interpEX = new InterpEx(false);
		interpEX.variables = vars;
		if (origin != null)
			interpEX.origin = origin;
		interpEX.addModule(string);
		clearClasses();
		createClasses();

		return this;
	}

	inline function createClasses()
	{
		if (scriptFile != null)
			for (i in InterpEx._scriptClassDescriptors.keys())
				classes[i] = interpEX.createScriptClassInstance(i);

		if (Reflect.fields(classes) != null && Reflect.fields(classes).length > 0)
			currentClass = Reflect.fields(classes)[0];
	}

	inline function clearClasses()
	{
		classes = {};
		currentClass = null;
	}

	inline function set_currentClass(value:String):String
	{
		if (value == null)
			currentScriptClass = null;
		else if (classes != null && classes[value] != null)
			currentScriptClass = classes[value];
		else
			currentScriptClass = null;

		return currentClass = value;
	}

	inline function toString():String
		return "[ex.SScriptX]";

	function get_currentSuperClass():Class<Dynamic>
	{
		if (currentScriptClass == null)
			return null;
		if (currentScriptClass.superClass == null)
			return null;

		return Type.getClass(currentScriptClass.superClass);
	}
}
