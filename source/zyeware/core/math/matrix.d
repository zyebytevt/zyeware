module zyeware.core.math.matrix;

import inmath.math;
import inmath.linalg;

import zyeware.common;

alias Matrix4f = Matrix!(float, 4, 4);
alias Matrix3f = Matrix!(float, 3, 3);

/// Convert a 2D position from world to local space.
/// 
/// Params:
/// 	worldPoint = The 2D position in world space.
/// 
/// Returns: The position in local space.
Vector2f inverseTransformPoint(in Matrix4f transform, in Vector2f worldPoint) pure nothrow
{
    return (transform.inverse * Vector4f(worldPoint, 0, 1)).xy;
}

/// Convert a 2D position from local to world space.
/// 
/// Params:
/// 	localPoint = The 2D position in local space.
/// 
/// Returns: The position in world space.
Vector2f transformPoint(in Matrix4f transform, in Vector2f localPoint) pure nothrow
{
    return (transform * Vector4f(localPoint, 0, 1)).xy;
}

/// Convert a 3D position from world to local space.
/// 
/// Params:
/// 	worldPoint = The 3D position in world space.
/// 
/// Returns: The position in local space.
Vector3f inverseTransformPoint(in Matrix4f transform, in Vector3f worldPoint) pure nothrow
{
    return (transform.inverse * Vector4f(worldPoint, 1)).xyz;
}

/// Convert a 3D position from local to world space.
/// 
/// Params:
/// 	localPoint = The 3D position in local space.
/// 
/// Returns: The position in world space.
Vector3f transformPoint(in Matrix4f transform, in Vector3f localPoint) pure nothrow
{
    return (transform * Vector4f(localPoint, 1)).xyz;
}