// D import file generated from 'source/zyeware/core/math/rect.d'
module zyeware.core.math.rect;
import std.traits : isNumeric;
import inmath.linalg;
import zyeware;
alias Rect2f = Rect!float;
alias Rect2i = Rect!int;
struct Rect(T) if (isNumeric!T)
{
	private alias VT = Vector!(T, 2);
	VT position = VT.zero;
	VT size = VT.zero;
	const pure nothrow this(T x, T y, T width, T height)
	{
		position = VT(x, y);
		size = VT(width, height);
	}
	const pure nothrow this(VT position, VT size)
	{
		this.position = position;
		this.size = size;
	}
	const pure nothrow bool contains(VT v)
	{
		return v.x >= position.x && (v.x <= position.x + size.x) && (v.y >= position.y) && (v.y <= position.y + size.y);
	}
	const pure nothrow bool overlaps(Rect!T b)
	{
		return position.x < b.position.x + b.size.x && (position.x + size.x > b.position.x) && (position.y < b.position.y + b.size.y) && (position.y + size.y > b.position.y);
	}
	const Rect!T constrain(Rect!T outer)
	{
		Rect!T r = this;
		if (r.position.x < outer.position.x)
			r.position.x = outer.position.x;
		if (r.position.y < outer.position.y)
			r.position.y = outer.position.y;
		if (r.position.x + r.size.x > outer.position.x + outer.size.x)
			r.position.x = outer.position.x + outer.size.x - r.size.x;
		if (r.position.y + r.size.y > outer.position.y + outer.size.y)
			r.position.y = outer.position.y + outer.size.y - r.size.y;
		return r;
	}
	const pure nothrow VT min()
	{
		return position;
	}
	const pure nothrow VT max()
	{
		return position + size;
	}
}
