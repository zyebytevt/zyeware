// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.rendering.camera;

import zyeware;

interface Camera
{
    mat4 getProjectionMatrix() const nothrow;
    mat4 getViewMatrix() const nothrow;
}

class Camera2d : Camera
{
protected:
    vec2 mViewportSize;

public:
    vec2 position;
    float zoom = 1;
    float rotation = 0;

    this(vec2 viewportSize, vec2 position = vec2.zero)
    {
        mViewportSize = viewportSize;
        this.position = position;
    }

    pragma(inline, true) final mat4 getProjectionMatrix() pure const nothrow
        => make2dProjectionMatrix(rect(position.x, position.y, mViewportSize.x, mViewportSize.y));

    pragma(inline, true) final mat4 getViewMatrix() pure const nothrow => mat4.translation(
        vec3(-position, 0)) * mat4.zRotation(rotation) * mat4.scaling(zoom, zoom, 1);
}

class Camera3d : Camera
{
protected:
    vec2 mViewportSize;

public:
    enum Projection
    {
        perspective,
        orthographic
    }

    vec3 position;
    quat rotation = quat.identity;
    Range!float renderRange;
    float fov;
    Projection projection;

    this(vec2 viewportSize, vec3 position = vec3.zero, float fov = 90.0f,
        Range!float renderRange = Range!float(0.001f, 1000f))
    {
        mViewportSize = viewportSize;
        this.position = position;
        this.fov = fov;
        this.renderRange = renderRange;
    }

    pragma(inline, true) final mat4 getProjectionMatrix() pure const nothrow
    {
        final switch (projection) with (Projection)
        {
        case orthographic:
            return mat4.orthographic(-mViewportSize.x / 2, mViewportSize.x / 2,
                -mViewportSize.y / 2, mViewportSize.y / 2, renderRange.min, renderRange.max);
            
        case perspective:
            return mat4.perspective(mViewportSize.x, mViewportSize.y, fov,
                renderRange.min, renderRange.max);
        }
    }

    pragma(inline, true) final mat4 getViewMatrix() pure const nothrow => (
        mat4.translation(position) * rotation.toMatrix!(4, 4)).inverse;
}
