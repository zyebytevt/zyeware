// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.projection;

import zyeware;

/// Provides common functionality between different types of cameras.
interface Projection {
public:
    /// The projection matrix of this camera.
    mat4 projectionMatrix() pure nothrow;

    /// Calculates a new view matrix based on the given translation.
    /// Params:
    ///   position = The position of the camera.
    ///   rotation = The rotation of the camera.
    /// Returns: A newly calculated view matrix.
    pragma(inline, true)
    static final mat4 calculateViewMatrix(vec3 position, quat rotation) pure nothrow {
        return (mat4.translation(position) * rotation.toMatrix!(4, 4)).inverse;
    }
}

/// Represents a camera with a orthographic projection.
class OrthographicProjection : Projection {
protected:
    mat4 mProjectionMatrix;

    float mLeft, mRight, mBottom, mTop, mNear, mFar;
    bool mIsDirty;

    pragma(inline, true)
    void recalculateProjectionMatrix() pure nothrow {
        mProjectionMatrix = mat4.orthographic(mLeft, mRight, mBottom, mTop, mNear, mFar);
        mIsDirty = false;
    }

public:
    this(float left, float right, float bottom, float top, float near = -1f, float far = 1f) pure nothrow {
        mLeft = left;
        mRight = right;
        mBottom = bottom;
        mTop = top;
        mNear = near;
        mFar = far;

        recalculateProjectionMatrix();
    }

    mat4 projectionMatrix() pure nothrow {
        if (mIsDirty)
            recalculateProjectionMatrix();

        return mProjectionMatrix;
    }

    float left() pure const nothrow {
        return mLeft;
    }

    float right() pure const nothrow {
        return mRight;
    }

    float bottom() pure const nothrow {
        return mBottom;
    }

    float top() pure const nothrow {
        return mTop;
    }

    float near() pure const nothrow {
        return mNear;
    }

    float far() pure const nothrow {
        return mFar;
    }

    void left(float value) pure nothrow {
        mLeft = value;
        mIsDirty = true;
    }

    void right(float value) pure nothrow {
        mRight = value;
        mIsDirty = true;
    }

    void bottom(float value) pure nothrow {
        mBottom = value;
        mIsDirty = true;
    }

    void top(float value) pure nothrow {
        mTop = value;
        mIsDirty = true;
    }

    void near(float value) pure nothrow {
        mNear = value;
        mIsDirty = true;
    }

    void far(float value) pure nothrow {
        mFar = value;
        mIsDirty = true;
    }
}

class PerspectiveProjection : Projection {
protected:
    mat4 mProjectionMatrix;
    bool mIsDirty;

    float mWidth;
    float mHeight;
    float mFov;
    float mNear;
    float mFar;

    void recalculateProjectionMatrix() pure nothrow {
        mProjectionMatrix = mat4.perspective(mWidth, mHeight, mFov, mNear, mFar);
        mIsDirty = false;
    }

public:
    this(float width, float height, float fov, float near = 0.001f, float far = 1000f) {
        setData(width, height, fov, near, far);
    }

    final void setData(float width, float height, float fov, float near = 0.001f, float far = 1000f) pure nothrow {
        mWidth = width;
        mHeight = height;
        mFov = fov;
        mNear = near;
        mFar = far;

        recalculateProjectionMatrix();
    }

    mat4 projectionMatrix() pure nothrow {
        if (mIsDirty)
            recalculateProjectionMatrix();

        return mProjectionMatrix;
    }

    float width() pure const nothrow {
        return mWidth;
    }

    float height() pure const nothrow {
        return mHeight;
    }

    float fov() pure const nothrow {
        return mFov;
    }

    float near() pure const nothrow {
        return mNear;
    }

    float far() pure const nothrow {
        return mFar;
    }

    void width(float value) pure nothrow {
        mWidth = value;
        mIsDirty = true;
    }

    void height(float value) pure nothrow {
        mHeight = value;
        mIsDirty = true;
    }

    void fov(float value) pure nothrow {
        mFov = value;
        mIsDirty = true;
    }

    void near(float value) pure nothrow {
        mNear = value;
        mIsDirty = true;
    }

    void far(float value) pure nothrow {
        mFar = value;
        mIsDirty = true;
    }
}
