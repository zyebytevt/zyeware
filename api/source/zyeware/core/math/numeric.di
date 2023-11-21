// D import file generated from 'source/zyeware/core/math/numeric.d'
module zyeware.core.math.numeric;
public import std.math : abs;
public import std.algorithm : clamp;
import std.traits : isNumeric;
import std.datetime : Duration;
public import inmath.math : degrees, radians;
import inmath.util : isVector;
struct Range(T)
{
	T min;
	T max;
}
T lerp(T)(T a, T b, float t) if (isNumeric!T || isVector!T)
{
	return t * b + (1.0F - t) * a;
}
T invLerp(T)(T a, T b, float v) if (isNumeric!T || isVector!T)
{
	return (v - a) / (b - a);
}
pure nothrow float angleBetween(T)(T a, T b) if (isFloatingPoint!T)
{
	immutable T delta = (b - a) % PI2;
	return 2 * delta % PI2 - delta;
}
pragma (inline, true)pure nothrow float toFloatSeconds(Duration dt)
{
	return dt.total!"hnsecs" * 1e-07F;
}
