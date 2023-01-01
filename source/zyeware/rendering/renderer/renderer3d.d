// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderer.renderer3d;

import std.typecons : Rebindable;

import zyeware.common;
import zyeware.rendering;
debug import zyeware.rendering.renderer.renderer2d : currentRenderer, CurrentRenderer;

/// This struct gives access to the 3D rendering API.
struct Renderer3D
{
    @disable this();
    @disable this(this);

private static:
    enum maxMaterialsPerBatch = 10;
    enum maxBufferGroupsPerMaterial = 10;
    enum maxTransformsPerBufferGroup = 10;

    struct MaterialBatch
    {
        Material material;
        BufferGroupBatch[maxBufferGroupsPerMaterial] bufferGroupBatches;
        size_t currentBufferGroupBatch;
    }

    struct BufferGroupBatch
    {
        BufferGroup bufferGroup;
        Matrix4f[maxTransformsPerBufferGroup] transforms;
        size_t currentTransform;
    }

    Matrix4f sActiveViewMatrix;
    Matrix4f sActiveProjectionMatrix;
    Rebindable!(Environment3D) sActiveEnvironment;

    MaterialBatch[maxMaterialsPerBatch] sMaterialBatches;
    size_t sCurrentMaterialBatch;
    ConstantBuffer sMatricesBuffer, sLightsBuffer, sEnvironmentBuffer;

    void renderSky(Renderable sky)
        in (sky, "Argument cannot be null.")
    {
        // Eliminate translation from current view matrix
        Matrix4f viewMatrix = sActiveViewMatrix;
        viewMatrix[0][3] = 0f;
        viewMatrix[1][3] = 0f;
        viewMatrix[2][3] = 0f;

        sMatricesBuffer.setData(sMatricesBuffer.getEntryOffset("view"), viewMatrix.matrix);
        sMatricesBuffer.setData(sMatricesBuffer.getEntryOffset("mvp"),
            (sActiveProjectionMatrix * viewMatrix).matrix);

        sky.material.bind();
        sky.bufferGroup.bind();

        RenderAPI.drawIndexed(sky.bufferGroup.indexBuffer.length);
    }

package(zyeware) static:
    /// Initializes 3D rendering.
    void initialize()
    {
        sMatricesBuffer = new ConstantBuffer(BufferLayout([
            BufferElement("mvp", BufferElement.Type.mat4),
            BufferElement("projection", BufferElement.Type.mat4),
            BufferElement("view", BufferElement.Type.mat4),
            BufferElement("model", BufferElement.Type.mat4)
        ]));

        sEnvironmentBuffer = new ConstantBuffer(BufferLayout([
            BufferElement("cameraPosition", BufferElement.Type.vec4),
            BufferElement("ambientColor", BufferElement.Type.vec4),
            BufferElement("fogColor", BufferElement.Type.vec4),
        ]));

        sLightsBuffer = new ConstantBuffer(BufferLayout([
            BufferElement("position", BufferElement.Type.vec4, maxLights),
            BufferElement("color", BufferElement.Type.vec4, maxLights),
            BufferElement("attenuation", BufferElement.Type.vec4, maxLights),
            BufferElement("count", BufferElement.Type.int_),
        ]));
    }

    /// Cleans up all used resources.
    void cleanup()
    {
        sMatricesBuffer.dispose();
        sEnvironmentBuffer.dispose();
    }

public static:
    /// How many lights can be rendered in one draw call.
    enum maxLights = 10;

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
    void uploadLights(Light[] lights)
        in (lights)
    {
        if (lights.length > maxLights)
        {
            Logger.core.log(LogLevel.warning, "Too many lights in scene.");
            return;
        }

        sLightsBuffer.setData(sLightsBuffer.getEntryOffset("count"), [cast(int) lights.length]);
        RenderAPI.packLightConstantBuffer(sLightsBuffer, lights);
    }

    /// Starts a 3D scene. This must be called before any 3D drawing commands.
    ///
    /// Params:
    ///     projectionMatrix = A 4x4 matrix used for projection.
    ///     viewMatrix = A 4x4 matrix used for view.
    ///     environment = The rendering environment for this scene. May be `null`.
    ///     depthTest = Whether to use depth testing for this scene or not.
    void begin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment)
        in (environment, "Environment cannot be null.")
    {
        debug assert(currentRenderer == CurrentRenderer.none, "A renderer is currently active, cannot begin.");

        sActiveProjectionMatrix = projectionMatrix;
        sActiveViewMatrix = viewMatrix;
        sActiveEnvironment = environment;

        sMatricesBuffer.bind(ConstantBuffer.Slot.matrices);
        sEnvironmentBuffer.bind(ConstantBuffer.Slot.environment);
        sLightsBuffer.bind(ConstantBuffer.Slot.lights);

        sMatricesBuffer.setData(sMatricesBuffer.getEntryOffset("projection"),
            sActiveProjectionMatrix);

        sEnvironmentBuffer.setData(sEnvironmentBuffer.getEntryOffset("cameraPosition"), 
            (sActiveViewMatrix.inverse * Vector4f(0, 0, 0, 1)).vector);
        sEnvironmentBuffer.setData(sEnvironmentBuffer.getEntryOffset("ambientColor"), sActiveEnvironment.ambientColor.vector);
        sEnvironmentBuffer.setData(sEnvironmentBuffer.getEntryOffset("fogColor"), sActiveEnvironment.fogColor.vector);

        RenderAPI.setFlag(RenderFlag.depthTesting, true);

        debug currentRenderer = CurrentRenderer.renderer3D;
    }

    /// Ends a 3D scene. This must be called at the end of all 3D drawing commands, as it flushes
    /// everything to the screen.
    void end()
    {
        debug assert(currentRenderer == CurrentRenderer.renderer3D, "3D renderer is not active, cannot end.");

        flush();

        if (sActiveEnvironment.sky)
            renderSky(sActiveEnvironment.sky);

        debug currentRenderer = CurrentRenderer.none;
    }

    /// Flushes all currently cached drawing commands to the screen.
    void flush()
    {
        sMatricesBuffer.setData(sMatricesBuffer.getEntryOffset("view"), sActiveViewMatrix);

        for (size_t i; i < sCurrentMaterialBatch; ++i)
        {
            MaterialBatch* materialBatch = &sMaterialBatches[i];
            materialBatch.material.bind();

            for (size_t j; j < materialBatch.currentBufferGroupBatch; ++j)
            {
                BufferGroupBatch* bufferGroupBatch = &materialBatch.bufferGroupBatches[j];
                bufferGroupBatch.bufferGroup.bind();

                for (size_t k; k < bufferGroupBatch.currentTransform; ++k)
                {
                    // TODO: Maybe look if this can be optimized.
                    sMatricesBuffer.setData(sMatricesBuffer.getEntryOffset("model"), bufferGroupBatch.transforms[k].matrix);
                    sMatricesBuffer.setData(sMatricesBuffer.getEntryOffset("mvp"), (sActiveProjectionMatrix * sActiveViewMatrix
                        * bufferGroupBatch.transforms[k]).matrix);
                    RenderAPI.drawIndexed(bufferGroupBatch.bufferGroup.indexBuffer.length);
                }

                bufferGroupBatch.currentTransform = 0;
            }

            materialBatch.currentBufferGroupBatch = 0;
        }
    }

    /// Submits a draw command.
    ///
    /// Params:
    ///     renderable = The renderable instance to draw.
    ///     transform = A 4x4 matrix used for transformation.
    pragma(inline, true)
    void submit(Renderable renderable, in Matrix4f transform)
        in (renderable)
    {
        submit(renderable.bufferGroup, renderable.material, transform);
    }

    // TODO: Check constness!
    /// Submits a draw command.
    ///
    /// Params:
    ///     group = The buffer group to draw.
    ///     material = The material to use for drawing.
    ///     transform = A 4x4 matrix used for transformation.
    void submit(BufferGroup group, Material material, in Matrix4f transform)
        in (group && material)
    {
        debug assert(currentRenderer == CurrentRenderer.renderer3D, "3D renderer is not active, cannot submit.");

        size_t i, j;

    retryInsert:
        // Find fitting material batch first
        for (; i < sCurrentMaterialBatch; ++i)
            if (sMaterialBatches[i].material is material)
                break;

        if (i == sCurrentMaterialBatch)
        {
            if (sCurrentMaterialBatch == maxMaterialsPerBatch)
                flush();
            
            sMaterialBatches[sCurrentMaterialBatch++].material = material;
        }

        MaterialBatch* materialBatch = &sMaterialBatches[i];

        // Find fitting buffer group batch next
        for (; j < materialBatch.currentBufferGroupBatch; ++j)
            if (materialBatch.bufferGroupBatches[j].bufferGroup is group)
                break;

        if (j == materialBatch.currentBufferGroupBatch)
        {
            if (materialBatch.currentBufferGroupBatch == maxBufferGroupsPerMaterial)
            {
                flush();
                goto retryInsert;
            }

            materialBatch.bufferGroupBatches[materialBatch.currentBufferGroupBatch++].bufferGroup = group;
        }

        BufferGroupBatch* bufferGroupBatch = &materialBatch.bufferGroupBatches[j];

        // Add transform last.
        if (bufferGroupBatch.currentTransform == maxTransformsPerBufferGroup)
        {
            flush();
            goto retryInsert;
        }

        bufferGroupBatch.transforms[bufferGroupBatch.currentTransform++] = transform;
    }
}