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
    /// Initializes 3D rendering.
    void initialize();

    /// Cleans up all used resources.
    void cleanup();

public static:
    /// Represents a light.
    struct Light
    {
    public:
        Vector3f position; /// The source position of the light.
        Color color; /// The color of the light.
        Vector3f attenuation; /// The attenuation of the light.
    }

    /// Uploads a struct of light arrays to the rendering API for the next draw call.
    ///
    /// Params:
    ///     lights = The array of lights to upload.
    void uploadLights(Light[] lights);

    /// Starts a 3D scene. This must be called before any 3D drawing commands.
    ///
    /// Params:
    ///     projectionMatrix = A 4x4 matrix used for projection.
    ///     viewMatrix = A 4x4 matrix used for view.
    ///     environment = The rendering environment for this scene. May be `null`.
    ///     depthTest = Whether to use depth testing for this scene or not.
    void begin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment);

    /// Ends a 3D scene. This must be called at the end of all 3D drawing commands, as it flushes
    /// everything to the screen.
    void end();

    /// Flushes all currently cached drawing commands to the screen.
    void flush();

    /// Submits a draw command.
    ///
    /// Params:
    ///     renderable = The renderable instance to draw.
    ///     transform = A 4x4 matrix used for transformation.
    pragma(inline, true)
    void submit(Renderable renderable, in Matrix4f transform);

    // TODO: Check constness!
    /// Submits a draw command.
    ///
    /// Params:
    ///     group = The buffer group to draw.
    ///     material = The material to use for drawing.
    ///     transform = A 4x4 matrix used for transformation.
    void submit(BufferGroup group, Material material, in Matrix4f transform);
}