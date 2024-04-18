// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.math.numeric;

public import std.math : abs, PI_2, PI;
public import std.algorithm : clamp;

import std.traits : isNumeric, isFloatingPoint;
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
import std.math : fmod;

float angleBetween(T)(T a, T b) nothrow if (isFloatingPoint!T)
{
    immutable T delta = (b - a) + PI;
    return fmod(delta, PI * 2) - PI;
}

/// Converts a duration of time to seconds, represented as a float.
/// 
/// Params:
///     dt = The duration to convert.
/// 
/// Returns: The seconds as float.
pragma(inline, true) float toFloatSeconds(Duration dt) pure nothrow
{
    return dt.total!"hnsecs" * 0.0000001f;
}

@("Numeric helper functions")
unittest
{
    import std.datetime : seconds;
    import unit_threaded.assertions;

    lerp(0.0, 10.0, 0.5).should == 5.0;
    lerp(5.0f, 15.0f, 0.5).should == 10.0;

    invLerp(0.0, 10.0, 5.0).should == 0.5;
    invLerp(5.0f, 15.0f, 10.0f).should == 0.5;

    angleBetween(0.0, 2).should == 2.0;
    angleBetween(2, 0.0).should == -2.0;

    toFloatSeconds(5.seconds).should == 5.0;
}
