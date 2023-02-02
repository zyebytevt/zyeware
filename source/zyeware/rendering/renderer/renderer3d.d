// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderer.renderer3d;

import std.typecons : Rebindable;
import std.exception : enforce;

import zyeware.common;
import zyeware.rendering;

/// This struct gives access to the 3D rendering API.
struct Renderer3D
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    void function() sInitializeImpl;
    void function() sCleanupImpl;
    void function(in Light[]) sUploadLightsImpl;
    void function(in Matrix4f, in Matrix4f, Environment3D) sBeginImpl;
    void function() sEndImpl;
    void function() sFlushImpl;
    void function(BufferGroup, Material, in Matrix4f) sSubmitImpl;

    pragma(inline, true)
    void initialize()
    {
        sInitializeImpl();
    }

    pragma(inline, true)
    void cleanup()
    {
        sCleanupImpl();
    }

public static:
    /// Represents a light.
    struct Light
    {
    public:
        Vector3f position; /// The source position of the light.
        Color color; /// The color of the light.
        Vector3f attenuation; /// The attenuation of the light.
    }

    /// How many lights can be rendered in one draw call.
    enum maxLights = 10;

    /// Uploads a struct of light arrays to the rendering API for the next draw call.
    ///
    /// Params:
    ///     lights = The array of lights to upload.
    pragma(inline, true)
    void uploadLights(Light[] lights)
    {
        sUploadLightsImpl(light);
    }

    /// Starts a 3D scene. This must be called before any 3D drawing commands.
    ///
    /// Params:
    ///     projectionMatrix = A 4x4 matrix used for projection.
    ///     viewMatrix = A 4x4 matrix used for view.
    ///     environment = The rendering environment for this scene. May be `null`.
    ///     depthTest = Whether to use depth testing for this scene or not.
    pragma(inline, true)
    void begin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment)
    {
        sBeginImpl(projectionMatrix, viewMatrix, environment);
    }

    /// Ends a 3D scene. This must be called at the end of all 3D drawing commands, as it flushes
    /// everything to the screen.
    pragma(inline, true)
    void end()
    {
        sEndImpl();
    }

    /// Flushes all currently cached drawing commands to the screen.
    pragma(inline, true)
    void flush()
    {
        sFlushImpl();
    }

    /// Submits a draw command.
    ///
    /// Params:
    ///     renderable = The renderable instance to draw.
    ///     transform = A 4x4 matrix used for transformation.
    pragma(inline, true)
    void submit(Renderable renderable, in Matrix4f transform)
    {
        sSubmitImpl(renderable.bufferGroup, renderable.material, transform);
    }

    // TODO: Check constness!
    /// Submits a draw command.
    ///
    /// Params:
    ///     group = The buffer group to draw.
    ///     material = The material to use for drawing.
    ///     transform = A 4x4 matrix used for transformation.
    pragma(inline, true)
    void submit(BufferGroup group, Material material, in Matrix4f transform)
    {
        sSubmitImpl(group, material, transform);
    }
}