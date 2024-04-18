// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.math.matrix;

import inmath.math;
import inmath.linalg;
public import inmath.linalg : quat, mat2, mat3, mat4;

import zyeware;

pragma(inline, true):

/// Convert a 2D position from world to local space.
/// 
/// Params:
/// 	worldPoint = The 2D position in world space.
/// 
/// Returns: The position in local space.
vec2 inverseTransformPoint(in mat4 transform, in vec2 worldPoint) pure nothrow
{
    return (transform.inverse * vec4(worldPoint, 0, 1)).xy;
}

/// Convert a 2D position from local to world space.
/// 
/// Params:
/// 	localPoint = The 2D position in local space.
/// 
/// Returns: The position in world space.
vec2 transformPoint(in mat4 transform, in vec2 localPoint) pure nothrow
{
    return (transform * vec4(localPoint, 0, 1)).xy;
}

/// Convert a 3D position from world to local space.
/// 
/// Params:
/// 	worldPoint = The 3D position in world space.
/// 
/// Returns: The position in local space.
vec3 inverseTransformPoint(in mat4 transform, in vec3 worldPoint) pure nothrow
{
    return (transform.inverse * vec4(worldPoint, 1)).xyz;
}

/// Convert a 3D position from local to world space.
/// 
/// Params:
/// 	localPoint = The 3D position in local space.
/// 
/// Returns: The position in world space.
vec3 transformPoint(in mat4 transform, in vec3 localPoint) pure nothrow
{
    return (transform * vec4(localPoint, 1)).xyz;
}

/// Create a 2D orthographic projection matrix with the given viewport.
mat4 make2dProjectionMatrix(in rect viewport) pure nothrow
{
    return mat4.orthographic(viewport.x, viewport.width, viewport.height, viewport.y, -1, 1);
}

@("Matrix vector transforms")
unittest
{
    import unit_threaded.assertions;

    // Test the 2D transform functions
    {
        mat4 transform = mat4.identity.translate(vec3(10, 20, 0));
        vec2 localPoint = vec2(5, 5);
        vec2 worldPoint = transformPoint(transform, localPoint);

        worldPoint.x.should == 15.0;
        worldPoint.y.should == 25.0;

        vec2 inversePoint = inverseTransformPoint(transform, worldPoint);

        inversePoint.x.should == localPoint.x;
        inversePoint.y.should == localPoint.y;
    }

    // Test the 3D transform functions
    {
        mat4 transform = mat4.identity.translate(vec3(10, 20, 30));
        vec3 localPoint = vec3(5, 5, 5);
        vec3 worldPoint = transformPoint(transform, localPoint);

        worldPoint.x.should == 15.0;
        worldPoint.y.should == 25.0;
        worldPoint.z.should == 35.0;

        vec3 inversePoint = inverseTransformPoint(transform, worldPoint);

        inversePoint.x.should == localPoint.x;
        inversePoint.y.should == localPoint.y;
        inversePoint.z.should == localPoint.z;
    }
}
