package ex;

import hscriptBase.Expr;
import hscriptBase.*;

import tea.backend.SScriptX;

@:access(ex.ScriptClass)
@:access(ex.AbstractScriptClass)
@:access(tea.backend.SScriptX)
class InterpEx extends hscriptBase.Interp
{
	var pkg(default, null):String;

	@:noPrivateAccess private static var interps:Array<InterpEx> = [];
	private var _proxy:AbstractScriptClass = null;
	var origin:String = "SScriptX";

	var changedClasses:Map<String, Array<String>> = new Map();

	public function new(proxy:AbstractScriptClass = null, ?push:Bool = true, ?superClassInstances:Map<String, Dynamic>)
	{
		super();
		_proxy = proxy;
		variables.set("Type", Type);
		variables.set("Math", Math);
		variables.set("Std", Std);
		if (push)
			interps.push(this);
		for (i in SScriptX.variables.keys())
			if (!variables.exists(i))
				variables.set(i, SScriptX.variables.get(i));
	}

	override function posInfos() {
		#if hscriptPos
			if (curExpr != null)
				return cast { fileName : curExpr.origin, lineNumber : curExpr.line };
		#end
		return cast { fileName : "SScriptX", lineNumber : 0 };
	}

	private static var _scriptClassDescriptors:Map<String, ClassDeclEx> = new Map<String, ClassDeclEx>();

	private static function registerScriptClass(c:ClassDeclEx)
	{
		var name = c.name;
		if (c.pkg != null)
		{
			name = c.pkg.join(".") + "." + name;
		}
		_scriptClassDescriptors.set(name, c);
	}

	public static function findScriptClassDescriptor(name:String)
	{
		return _scriptClassDescriptors.get(name);
	}

	override function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		if (_scriptClassDescriptors.exists(cl))
		{
			var proxy:AbstractScriptClass = new ScriptClass(_scriptClassDescriptors.get(cl), args);
			return proxy;
		}
		else if (_proxy != null)
		{
			if (_proxy._c.pkg != null)
			{
				var packagedClass = _proxy._c.pkg.join(".") + "." + cl;
				if (_scriptClassDescriptors.exists(packagedClass))
				{
					var proxy:AbstractScriptClass = new ScriptClass(_scriptClassDescriptors.get(packagedClass), args);
					return proxy;
				}
			}

			if (_proxy._c.imports != null && _proxy._c.imports.exists(cl))
			{
				var importedClass = _proxy._c.imports.get(cl).join(".");
				if (_scriptClassDescriptors.exists(importedClass))
				{
					var proxy:AbstractScriptClass = new ScriptClass(_scriptClassDescriptors.get(importedClass), args);
					return proxy;
				}

				var c = Type.resolveClass(importedClass);
				if (c != null)
				{
					return Type.createInstance(c, args);
				}
			}
		}
		return super.cnew(cl, args);
	}

	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var v = expr(e2);
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				if (_proxy != null && _proxy.superClass != null && Reflect.hasField(_proxy.superClass, id))
				{
					Reflect.setProperty(_proxy.superClass, id, v);
					return v;
				}
			case _:
		}
		return super.assign(e1, e2);
	}

	override function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
	{
		if ((o is ScriptClass))
		{
			_nextCallObject = null;
			var proxy:ScriptClass = cast(o, ScriptClass);
			return proxy.callFunction(f, args);
		}
		return super.fcall(o, f, args);
	}

	override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic
	{
		// TODO: not sure if this make sense !! seems hacky, but fn() in hscript wont resolve an object first (this.fn() or super.fn() would work fine)
		if (o == null && _nextCallObject != null)
		{
			o = _nextCallObject;
		}
		var r = super.call(o, f, args);
		_nextCallObject = null;
		return r;
	}

	override function get(o:Dynamic, f:String):Dynamic
	{
		if (o == null)
			error(EInvalidAccess(f));
		if ((o is ScriptClass))
		{
			var proxy:AbstractScriptClass = cast(o, ScriptClass);
			if (proxy._interp.variables.exists(f))
			{
				return proxy._interp.variables.get(f);
			}
			else if (proxy.superClass != null && Reflect.hasField(proxy.superClass, f))
			{
				return Reflect.getProperty(proxy.superClass, f);
			}
			else
			{
				try
				{
					return proxy.resolveField(f);
				}
				catch (e:Dynamic) {}
				error(EUnknownVariable(f));
			}
		}
		return super.get(o, f);
	}

	override function set(o:Dynamic, f:String, v:Dynamic):Dynamic
	{
		if (o == null)
			error(EInvalidAccess(f));
		if ((o is ScriptClass))
		{
			var proxy:ScriptClass = cast(o, ScriptClass);
			if (proxy._interp.variables.exists(f))
			{
				proxy._interp.variables.set(f, v);
			}
			else if (proxy.superClass != null && Reflect.hasField(proxy.superClass, f))
			{
				Reflect.setProperty(proxy.superClass, f, v);
			}
			else
			{
				error(EUnknownVariable(f));
			}
			return v;
		}
		return super.set(o, f, v);
	}

	private var _nextCallObject:Dynamic = null;

	override function resolve(id:String):Dynamic
	{
		_nextCallObject = null;
		if (id == "super" && _proxy != null)
		{
			if (_proxy.superClass == null)
			{
				return _proxy.superConstructor;
			}
			else
			{
				return _proxy.superClass;
			}
		}
		else if (id == "this" && _proxy != null)
		{
			return _proxy;
		}

		var l = locals.get(id);
		if (l != null)
			return l.r;
		var v = variables.get(id);
		if (v == null && !variables.exists(id))
		{
			if (_proxy != null && _proxy.findFunction(id) != null)
			{
				_nextCallObject = _proxy;
				return _proxy.resolveField(id);
			}
			else if (_proxy != null
				&& _proxy.superClass != null
				&& (Reflect.hasField(_proxy.superClass, id) || Reflect.getProperty(_proxy.superClass, id) != null))
			{
				_nextCallObject = _proxy.superClass;
				return Reflect.getProperty(_proxy.superClass, id);
			}
			else if (_proxy != null)
			{
				try
				{
					var r = _proxy.resolveField(id);
					_nextCallObject = _proxy;
					return r;
				}
				catch (e:Dynamic) {}
				error(EUnknownVariable(id));
			}
			else
			{
				error(EUnknownVariable(id));
			}
		}
		return v;
	}

	public function addModule(moduleContents:String)
	{
		var parser = new ex.ParserEx();
		var decls = parser.parseModule(moduleContents, this.origin);
		registerModule(decls);
	}

	public function createScriptClassInstance(className:String, args:Array<Dynamic> = null):AbstractScriptClass
	{
		if (args == null)
		{
			args = [];
		}
		var r:AbstractScriptClass = cnew(className, args);
		return r;
	}

	public function registerModule(module:Array<ModuleDecl>)
	{
		var pkg:Array<String> = null;
		var imports:Map<String, Array<String>> = [];
		for (decl in module)
		{
			switch (decl)
			{
				case DPackage(path):
					pkg = path;
					var pkg = pkg.copy();
					if (pkg.length > 1)
					{
						var s = pkg.pop();
						this.pkg = pkg.join('.') + '.$s';
					}
					else
						this.pkg = path[0];
				case DImport(path, _, asIdent):
					var last = path[path.length - 1];
					imports.set(last, path);
				case DClass(c):
					var extend = c.extend;
					if (extend != null)
					{
						var superClassPath = new Printer().typeToString(extend);
						if (imports.exists(superClassPath))
						{
							switch (extend)
							{
								case CTPath(_, params):
									extend = CTPath(imports.get(superClassPath), params);
								case _:
							}
						}
					}
					var classDecl:ClassDeclEx = {
						imports: imports,
						pkg: pkg,
						name: c.name,
						params: c.params,
						meta: c.meta,
						isPrivate: c.isPrivate,
						extend: extend,
						implement: c.implement,
						fields: c.fields,
						isExtern: c.isExtern
					};
					registerScriptClass(classDecl);
				case DTypedef(_):
				case _:
			}
		}
	}
}
