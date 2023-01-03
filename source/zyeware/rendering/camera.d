// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.camera;

import zyeware.common;
import zyeware.rendering;

interface Camera
{
public:
    Matrix4f projectionMatrix() pure const nothrow;

    pragma(inline, true)
    static final Matrix4f calculateViewMatrix(Vector3f position, Quaternionf rotation) pure nothrow
    {
        return (Matrix4f.translation(position) * rotation.toMatrix!(4, 4)).inverse;
    }
}

class OrthographicCamera : Camera
{
protected:
    Matrix4f mProjectionMatrix;

public:
    this(float left, float right, float bottom, float top, float near = -1f, float far = 1f) pure nothrow
    {
        setData(left, right, bottom, top, near, far);
    }

    void setData(float left, float right, float bottom, float top, float near = -1f, float far = 1f) pure nothrow
    {
        mProjectionMatrix = Matrix4f.orthographic(left, right, bottom, top, near, far);
    }

    Matrix4f projectionMatrix() pure const nothrow
    {
        return mProjectionMatrix;
    }
}

class PerspectiveCamera : Camera
{
protected:
    Matrix4f mProjectionMatrix;

public:
    this(float width, float height, float fov, float near, float far)
    {
        setData(width, height, fov, near, far);
    }

    void setData(float width, float height, float fov, float near = 0.001f, float far = 1000f) pure nothrow
    {
        mProjectionMatrix = Matrix4f.perspective(width, height, fov, near, far);
    }

    Matrix4f projectionMatrix() pure const nothrow
    {
        return mProjectionMatrix;
    }
}