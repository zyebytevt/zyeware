module zyeware.core.math.vector;

import inmath.math;
import inmath.linalg;

public import inmath.linalg : dot, cross, vec2, vec3, vec4, vec2i, vec3i, vec4i, vec2d, vec3d, vec4d;
import inmath.util : isVector;

import zyeware;

alias cross3d = cross;

T.vt cross2d(T)(const T veca, const T vecb) @safe pure nothrow
    if (isVector!T && T.dimension == 2)
{
    return veca.x * vecb.y - veca.y * vecb.x;
}

/// Calculates the height on a specific point of a triangle using the barycentric algorithm.
/// Params:
///     p1 = The first point of the triangle.
///     p2 = The second point of the triangle.
///     p3 = The third point of the triangle.
///     position = The position to check the height of.
///
/// Returns: The height at the specified position.
float calculateBaryCentricHeight(vec3 p1, vec3 p2, vec3 p3, vec2 position) pure nothrow
{
    immutable float det = (p2.z - p3.z) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.z - p3.z);
    immutable float l1 = ((p2.z - p3.z) * (position.x - p3.x) + (p3.x - p2.x) * (position.y - p3.z)) / det;
    immutable float l2 = ((p3.z - p1.z) * (position.x - p3.x) + (p1.x - p3.x) * (position.y - p3.z)) / det;
    immutable float l3 = 1.0f - l1 - l2;

    return l1 * p1.y + l2 * p2.y + l3 * p3.y;
}