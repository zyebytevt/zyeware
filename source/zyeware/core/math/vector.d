module zyeware.core.math.vector;

import inmath.math;
import inmath.linalg;

public import inmath.linalg : dot, cross;

import zyeware.common;

alias Vector2f = Vector!(float, 2);
alias Vector2i = Vector!(int, 2);

alias Vector3f = Vector!(float, 3);
alias Vector3i = Vector!(int, 3);

alias Vector4f = Vector!(float, 4);
alias Vector4i = Vector!(int, 4);

/// Calculates the height on a specific point of a triangle using the barycentric algorithm.
/// Params:
///     p1 = The first point of the triangle.
///     p2 = The second point of the triangle.
///     p3 = The third point of the triangle.
///     position = The position to check the height of.
///
/// Returns: The height at the specified position.
float calculateBaryCentricHeight(Vector3f p1, Vector3f p2, Vector3f p3, Vector2f position) pure nothrow
{
    immutable float det = (p2.z - p3.z) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.z - p3.z);
    immutable float l1 = ((p2.z - p3.z) * (position.x - p3.x) + (p3.x - p2.x) * (position.y - p3.z)) / det;
    immutable float l2 = ((p3.z - p1.z) * (position.x - p3.x) + (p1.x - p3.x) * (position.y - p3.z)) / det;
    immutable float l3 = 1.0f - l1 - l2;

    return l1 * p1.y + l2 * p2.y + l3 * p3.y;
}