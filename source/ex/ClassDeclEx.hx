package ex;

import hscriptBase.Expr.ClassDecl;

abstract OneOfTwo<T, K>(Dynamic) from T to T from K to K {}

enum Status
{
	NONE;
}

typedef ClassDeclEx =
{
	> ClassDecl,
	@:optional var imports:Map<String, Array<String>>;
	@:optional var pkg:Array<String>;
}
