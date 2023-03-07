module zyeware.core.math.numeric;

public import std.math : abs;
public import std.algorithm : clamp;

import std.traits : isNumeric;
import std.datetime : Duration;

public import inmath.math : degrees, radians;
import inmath.util : isVector;

/// Represents a range of values, given a `min` and `max`.
struct Range(T)
{
    T min;
    T max;
}

/// Linearly interpolate between two numeric values.
/// 
/// Params:
///     a = The first value.
///     b = The second value.
///     t = Factor to interpolate between a and b, must be between 0.0 and 1.0.
/// 
/// Returns: The interpolated value.
T lerp(T)(T a, T b, float t) if (isNumeric!T || isVector!T)
{
    return t * b + (1f - t) * a;
}

/// Linearly inverse interpolate between two points.
/// 
/// Params:
///     a = The first value.
///     b = The second value.
///     v = The value to inversly interpolate between `a` and `b`.
/// 
/// Returns: A value between 0.0 and 1.0.
T invLerp(T)(T a, T b, float v) if (isNumeric!T || isVector!T)
{
    return (v - a) / (b - a);
}

/// Returns the shortest angular distance between two angles.
/// 
/// Params:
///     a = The first angle, in radians.
///     b = The second angle, in radians.
/// 
/// Returns: The shortest angular distance, in radians.
float angleBetween(T)(T a, T b) pure nothrow
    if (isFloatingPoint!T)
{
    immutable T delta = (b - a) % PI2;
    return ((2 * delta) % PI2) - delta;
}

/// Converts a duration of time to seconds, represented as a float.
/// 
/// Params:
///     dt = The duration to convert.
/// 
/// Returns: The seconds as float.
pragma(inline, true)
float toFloatSeconds(Duration dt) pure nothrow
{
    return dt.total!"hnsecs" * 0.0000001f;
}