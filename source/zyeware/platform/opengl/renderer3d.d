// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.platform.opengl.renderer3d;

import std.typecons : Rebindable;
import std.exception : enforce;

import zyeware.common;
import zyeware.rendering;

version (ZWOpenGLBackend):
package(zyeware.platform.opengl):

debug import zyeware.platform.opengl.renderer2d : currentRenderer, CurrentRenderer;

enum maxLights = 10;
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

Matrix4f pActiveViewMatrix;
Matrix4f pActiveProjectionMatrix;
Rebindable!(Environment3D) pActiveEnvironment;

MaterialBatch[maxMaterialsPerBatch] pMaterialBatches;
size_t pCurrentMaterialBatch;
ConstantBuffer pMatricesBuffer, pLightsBuffer, pEnvironmentBuffer;

void r3dRenderSky(Renderable sky)
    in (sky, "Argument cannot be null.")
{
    // Eliminate translation from current view matrix
    Matrix4f viewMatrix = pActiveViewMatrix;
    viewMatrix[0][3] = 0f;
    viewMatrix[1][3] = 0f;
    viewMatrix[2][3] = 0f;

    pMatricesBuffer.setData(pMatricesBuffer.getEntryOffset("view"), viewMatrix.matrix);
    pMatricesBuffer.setData(pMatricesBuffer.getEntryOffset("mvp"),
        (pActiveProjectionMatrix * viewMatrix).matrix);

    sky.material.bind();
    sky.bufferGroup.bind();

    RenderAPI.drawIndexed(sky.bufferGroup.indexBuffer.length);
}

void r3dInitialize()
{
    pMatricesBuffer = new ConstantBuffer(BufferLayout([
        BufferElement("mvp", BufferElement.Type.mat4),
        BufferElement("projection", BufferElement.Type.mat4),
        BufferElement("view", BufferElement.Type.mat4),
        BufferElement("model", BufferElement.Type.mat4)
    ]));

    pEnvironmentBuffer = new ConstantBuffer(BufferLayout([
        BufferElement("cameraPosition", BufferElement.Type.vec4),
        BufferElement("ambientColor", BufferElement.Type.vec4),
        BufferElement("fogColor", BufferElement.Type.vec4),
    ]));

    pLightsBuffer = new ConstantBuffer(BufferLayout([
        BufferElement("position", BufferElement.Type.vec4, maxLights),
        BufferElement("color", BufferElement.Type.vec4, maxLights),
        BufferElement("attenuation", BufferElement.Type.vec4, maxLights),
        BufferElement("count", BufferElement.Type.int_),
    ]));

    // Make sure to always initialize the count variable with 0, in case lights
    // are not uploaded.
    pLightsBuffer.setData(pLightsBuffer.getEntryOffset("count"), [0]);
}

void r3dCleanup()
{
    pMatricesBuffer.dispose();
    pEnvironmentBuffer.dispose();
}

void r3dUploadLights(in Renderer3D.Light[] lights)
{
    if (lights.length > maxLights)
    {
        Logger.core.log(LogLevel.warning, "Too many lights in scene.");
        return;
    }

    pLightsBuffer.setData(pLightsBuffer.getEntryOffset("count"), [cast(int) lights.length]);
    RenderAPI.packLightConstantBuffer(pLightsBuffer, lights);
}

void r3dBegin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment)
    in (environment, "Environment cannot be null.")
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.none,
        "A renderer is currently active, cannot begin.");

    pActiveProjectionMatrix = projectionMatrix;
    pActiveViewMatrix = viewMatrix;
    pActiveEnvironment = environment;

    pMatricesBuffer.bind(ConstantBuffer.Slot.matrices);
    pEnvironmentBuffer.bind(ConstantBuffer.Slot.environment);
    pLightsBuffer.bind(ConstantBuffer.Slot.lights);

    pMatricesBuffer.setData(pMatricesBuffer.getEntryOffset("projection"),
        pActiveProjectionMatrix);

    pEnvironmentBuffer.setData(pEnvironmentBuffer.getEntryOffset("cameraPosition"), 
        (pActiveViewMatrix.inverse * Vector4f(0, 0, 0, 1)).vector);
    pEnvironmentBuffer.setData(pEnvironmentBuffer.getEntryOffset("ambientColor"), pActiveEnvironment.ambientColor.vector);
    pEnvironmentBuffer.setData(pEnvironmentBuffer.getEntryOffset("fogColor"), pActiveEnvironment.fogColor.vector);

    RenderAPI.setFlag(RenderFlag.depthTesting, true);

    debug currentRenderer = CurrentRenderer.renderer3D;
}

void r3dEnd()
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.renderer3D,
        "3D renderer is not active, cannot end.");

    r3dFlush();

    if (pActiveEnvironment.sky)
        r3dRenderSky(pActiveEnvironment.sky);

    debug currentRenderer = CurrentRenderer.none;
}

void r3dFlush()
{
    pMatricesBuffer.setData(pMatricesBuffer.getEntryOffset("view"), pActiveViewMatrix);

    for (size_t i; i < pCurrentMaterialBatch; ++i)
    {
        MaterialBatch* materialBatch = &pMaterialBatches[i];
        materialBatch.material.bind();

        for (size_t j; j < materialBatch.currentBufferGroupBatch; ++j)
        {
            BufferGroupBatch* bufferGroupBatch = &materialBatch.bufferGroupBatches[j];
            bufferGroupBatch.bufferGroup.bind();

            for (size_t k; k < bufferGroupBatch.currentTransform; ++k)
            {
                // TODO: Maybe look if this can be optimized.
                pMatricesBuffer.setData(pMatricesBuffer.getEntryOffset("model"), bufferGroupBatch.transforms[k].matrix);
                pMatricesBuffer.setData(pMatricesBuffer.getEntryOffset("mvp"), (pActiveProjectionMatrix * pActiveViewMatrix
                    * bufferGroupBatch.transforms[k]).matrix);
                RenderAPI.drawIndexed(bufferGroupBatch.bufferGroup.indexBuffer.length);
            }

            bufferGroupBatch.currentTransform = 0;
        }

        materialBatch.currentBufferGroupBatch = 0;
    }
}

void r3dSubmit(BufferGroup group, Material material, in Matrix4f transform)
    in (group && material)
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.renderer3D,
        "3D renderer is not active, cannot submit.");

    size_t i, j;

retryInsert:
    // Find fitting material batch first
    for (; i < pCurrentMaterialBatch; ++i)
        if (pMaterialBatches[i].material is material)
            break;

    if (i == pCurrentMaterialBatch)
    {
        if (pCurrentMaterialBatch == maxMaterialsPerBatch)
            r3dFlush();
        
        pMaterialBatches[pCurrentMaterialBatch++].material = material;
    }

    MaterialBatch* materialBatch = &pMaterialBatches[i];

    // Find fitting buffer group batch next
    for (; j < materialBatch.currentBufferGroupBatch; ++j)
        if (materialBatch.bufferGroupBatches[j].bufferGroup is group)
            break;

    if (j == materialBatch.currentBufferGroupBatch)
    {
        if (materialBatch.currentBufferGroupBatch == maxBufferGroupsPerMaterial)
        {
            r3dFlush();
            goto retryInsert;
        }

        materialBatch.bufferGroupBatches[materialBatch.currentBufferGroupBatch++].bufferGroup = group;
    }

    BufferGroupBatch* bufferGroupBatch = &materialBatch.bufferGroupBatches[j];

    // Add transform last.
    if (bufferGroupBatch.currentTransform == maxTransformsPerBufferGroup)
    {
        r3dFlush();
        goto retryInsert;
    }

    bufferGroupBatch.transforms[bufferGroupBatch.currentTransform++] = transform;
}