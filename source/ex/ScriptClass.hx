package ex;

import hscriptBase.Expr.FieldDecl;
import hscriptBase.Expr.FunctionDecl;
import hscriptBase.Expr.VarDecl;
import hscriptBase.Printer;

import tea.SScript;

enum Param
{
	Unused;
}

@:access(tea.SScript)
class ScriptClass
{
	private var _c:ClassDeclEx;
	var _interp:InterpEx;

	public var superClass:Dynamic = null;

	var superClassName:String;

	public function new(c:ClassDeclEx, args:Array<Dynamic>)
	{
		_c = c;
		_interp = new InterpEx(this);
		buildCaches();

		var ctorField = findField("new");
		if (ctorField != null)
		{
			callFunction("new", args);
			if (superClass == null && _c.extend != null)
			{
				@:privateAccess _interp.error(ECustom("super() not called"));
			}
		}
		else if (_c.extend != null)
		{
			createSuperClass(args);
		}
	}

	public var className(get, null):String;

	private function get_className():String
	{
		var name = "";
		if (_c.pkg != null)
		{
			name += _c.pkg.join(".");
		}
		name += _c.name;
		return name;
	}

	private function superConstructor(arg0:Dynamic = Unused, arg1:Dynamic = Unused, arg2:Dynamic = Unused, arg3:Dynamic = Unused)
	{
		var args = [];
		if (arg0 != Unused)
			args.push(arg0);
		if (arg1 != Unused)
			args.push(arg1);
		if (arg2 != Unused)
			args.push(arg2);
		if (arg3 != Unused)
			args.push(arg3);
		createSuperClass(args);
	}

	private function createSuperClass(args:Array<Dynamic> = null)
	{
		if (args == null)
		{
			args = [];
		}
		var extendString = new Printer().typeToString(_c.extend);
		if (_c.pkg != null && extendString.indexOf(".") == -1)
		{
			extendString = _c.pkg.join(".") + "." + extendString;
		}
		var classDescriptor = InterpEx.findScriptClassDescriptor(extendString);
		superClassName = extendString;
		if (classDescriptor != null)
		{
			var abstractSuperClass:AbstractScriptClass = new ScriptClass(classDescriptor, args);
			superClass = abstractSuperClass;
		}
		else
		{
			var c = Type.resolveClass(extendString);
			if (c == null)
			{
				@:privateAccess _interp.error(ECustom("could not resolve super class: " + extendString));
			}
			else 
			{
				function createSuperClass():Void
					superClass = Type.createInstance(c, args);

				var instance:Dynamic = SScript.superClassInstances[extendString];
				if (instance != null)
				{
					var cl:Class<Dynamic> = Type.getClass(instance);
					if (cl != null && extendString == Type.getClassName(cl))
						superClass = instance;
					else 
						createSuperClass();
				}
				else
					createSuperClass();
			}
		}
	}

	private inline function callFunction0(name:String)
	{
		return callFunction(name);
	}

	private inline function callFunction1(name:String, arg0:Dynamic)
	{
		return callFunction(name, [arg0]);
	}

	private inline function callFunction2(name:String, arg0:Dynamic, arg1:Dynamic)
	{
		return callFunction(name, [arg0, arg1]);
	}

	private inline function callFunction3(name:String, arg0:Dynamic, arg1:Dynamic, arg2:Dynamic)
	{
		return callFunction(name, [arg0, arg1, arg2]);
	}

	private inline function callFunction4(name:String, arg0:Dynamic, arg1:Dynamic, arg2:Dynamic, arg3:Dynamic)
	{
		return callFunction(name, [arg0, arg1, arg2, arg3]);
	}

	public function callFunction(name:String, args:Array<Dynamic> = null)
	{
		var field = findField(name);
		var r:Dynamic = null;

		if (field != null)
		{
			var fn = findFunction(name);
			var f = findField(name);
			if (f != null)
			{
				@:privateAccess
				if (!f.access.contains(AOverride))
				{
					if (superClass != null && Reflect.getProperty(superClass, name) != null)
						throw 'Field $name should be declared with \'override\' since it is inherited from superclass $className';
					else
					{
						var className:String = null;
						// JavaScript issues
						if (superClass != null)
							className = Type.getClassName(superClass);
						if (className == null)
							className = superClassName;
						var expr = Tools.expr(fn.expr);
						function isSuper(expr:ExprDef)
						{
							var e = expr;
							return switch e
							{
								case EIdent(v, _):
									if (v == 'super') true; else false;
								case EField(e, _):
									switch Tools.expr(e)
									{
										case EIdent(v, _):
											if (v == 'super') true; else false;
										case _:
											false;
									}
								case _: false;
							}
						}
						switch expr
						{
							case EBlock(e):
								for (i in e)
								{
									var i = Tools.expr(i);
									if (isSuper(i))
										throw 'Field $name should be declared with \'override\' since it is inherited from superclass $className';
									else
										switch i
										{
											case ECall(e, _):
												if (isSuper(Tools.expr(e)))
													throw 'Field $name should be declared with \'override\' since it is inherited from superclass $className';
											case _:
										}
								}
							case _:
						}
					}
				}
			}
			var previousValues:Map<String, Dynamic> = [];
			var i = 0;
			for (a in fn.args)
			{
				var value:Dynamic = null;

				if (args != null && i < args.length)
				{
					value = args[i];
				}
				else if (a.value != null)
				{
					value = _interp.expr(a.value);
				}

				if (_interp.variables.exists(a.name))
				{
					previousValues.set(a.name, _interp.variables.get(a.name));
				}
				_interp.variables.set(a.name, value);
				i++;
			}

			r = _interp.execute(fn.expr);

			for (a in fn.args)
			{
				if (previousValues.exists(a.name))
				{
					_interp.variables.set(a.name, previousValues.get(a.name));
				}
				else
				{
					_interp.variables.remove(a.name);
				}
			}
		}
		else
		{
			var fixedArgs = [];
			for (a in args)
			{
				if ((a is ScriptClass))
				{
					fixedArgs.push(cast(a, ScriptClass).superClass);
				}
				else
				{
					fixedArgs.push(a);
				}
			}
			r = Reflect.callMethod(superClass, Reflect.field(superClass, name), fixedArgs);
		}
		return r;
	}

	private function findFunction(name:String):FunctionDecl
	{
		if (_cachedFunctionDecls != null)
		{
			return _cachedFunctionDecls.get(name);
		}

		for (f in _c.fields)
		{
			if (f.name == name)
			{
				switch (f.kind)
				{
					case KFunction(fn):
						return fn;
					case _:
				}
			}
		}

		return null;
	}

	private function findVar(name:String):VarDecl
	{
		if (_cachedVarDecls != null)
		{
			_cachedVarDecls.get(name);
		}

		for (f in _c.fields)
		{
			if (f.name == name)
			{
				switch (f.kind)
				{
					case KVar(v):
						return v;
					case _:
				}
			}
		}

		return null;
	}

	private function findField(name:String):FieldDecl
	{
		if (_cachedFieldDecls != null)
		{
			return _cachedFieldDecls.get(name);
		}

		for (f in _c.fields)
		{
			if (f.name == name)
			{
				return f;
			}
		}
		return null;
	}

	public function listFunctions():Map<String, FunctionDecl>
		return if (_cachedFunctionDecls != null) _cachedFunctionDecls else new Map();

	private var _cachedFieldDecls:Map<String, FieldDecl> = null;
	private var _cachedFunctionDecls:Map<String, FunctionDecl> = null;
	private var _cachedVarDecls:Map<String, VarDecl> = null;

	private function buildCaches()
	{
		_cachedFieldDecls = [];
		_cachedFunctionDecls = [];
		_cachedVarDecls = [];

		for (f in _c.fields)
		{
			_cachedFieldDecls.set(f.name, f);
			switch (f.kind)
			{
				case KFunction(fn):
					_cachedFunctionDecls.set(f.name, fn);
				case KVar(v):
					_cachedVarDecls.set(f.name, v);
					if (v.expr != null)
					{
						var varValue = this._interp.expr(v.expr);
						this._interp.variables.set(f.name, varValue);
					}
			}
		}
	}
}
