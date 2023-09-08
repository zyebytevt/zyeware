// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.opengl.api;

version (ZW_OpenGL):
package(zyeware.rendering.opengl):

import std.typecons : Tuple;

import bindbc.opengl;

import zyeware.common;
import zyeware.rendering.vertex;
import zyeware.core.debugging.profiler;
import zyeware.rendering;

import zyeware.rendering.opengl.buffer;

version (Windows)
{
    extern(Windows) static void glErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        glErrorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}
else
{
    extern(C) static void glErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        glErrorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}

void glErrorCallbackImpl(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
    const(char)* message, void* userParam) nothrow
{
    glGetError();

    string typeName;
    LogLevel logLevel;

    switch (type)
    {
        case GL_DEBUG_TYPE_ERROR:
            typeName = "Error";
            break;
        
        case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
            typeName = "Deprecated Behavior";
            break;
        
        case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
            typeName = "Undefined Behavior";
            break;

        case GL_DEBUG_TYPE_PERFORMANCE:
            typeName = "Performance";
            break;

        case GL_DEBUG_TYPE_OTHER:
        default:
            return;
    }

    switch (severity)
    {
        case GL_DEBUG_SEVERITY_LOW:
            logLevel = LogLevel.info;
            break;

        case GL_DEBUG_SEVERITY_MEDIUM:
            logLevel = LogLevel.warning;
            break;

        case GL_DEBUG_SEVERITY_HIGH:
            logLevel = LogLevel.error;
            break;

        default:
            logLevel = LogLevel.debug_;
            break;
    }

    Logger.core.log(logLevel, "%s: %s", typeName, cast(string) message[0..length]);
}

final class OpenGLAPI : GraphicsAPI
{
protected:
    alias MeshData = Tuple!(uint, "vao", uint, "vbo", uint, "ebo");

    enum RIDType
    {
        texture,
        mesh
    }

    bool[RenderFlag] mFlagValues;
    
    size_t[RID] mRefCount;
    RIDType[RID] mRidType;
    RID mNextRID;
    
    uint[RID] mTextureIDs;
    MeshData[RID] mMeshData;

    pragma(inline, true)
    RID getNextRID() pure nothrow
    {
        return mNextRID++;
    }

public:
    void initialize()
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glEnable(GL_CULL_FACE);
        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);
        
        //glAlphaFunc(GL_GREATER, 0);

        glDepthFunc(GL_LEQUAL);
        
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
        glDebugMessageCallback(&glErrorCallback, null);

        glLineWidth(2);
        glPointSize(4);

        {
            GLboolean resultBool;
            GLint resultInt;

            glGetBooleanv(GL_DEPTH_TEST, &resultBool);
            pFlagValues[RenderFlag.depthTesting] = cast(bool) resultBool;
            glGetBooleanv(GL_DEPTH_WRITEMASK, &resultBool);
            pFlagValues[RenderFlag.depthBufferWriting] = cast(bool) resultBool;
            glGetBooleanv(GL_CULL_FACE, &resultBool);
            pFlagValues[RenderFlag.culling] = cast(bool) resultBool;
            glGetBooleanv(GL_STENCIL_TEST, &resultBool);
            pFlagValues[RenderFlag.stencilTesting] = cast(bool) resultBool;
            glGetIntegerv(GL_POLYGON_MODE, &resultInt);
            pFlagValues[RenderFlag.wireframe] = resultInt == GL_LINE;
        }
    }

    void cleanup()
    {

    }

    void addRef(RID rid) nothrow
    {
        if (rid in mRefCount)
            mRefCount[rid]++;
        else
            mRefCount[rid] = 1;
    }

    void release(RID rid) nothrow
    {
        if (rid !in mRefCount)
            return;

        if (--mRefCount[rid] == 0)
        {
            final switch (mRidType[rid]) with (RIDType)
            {
            case texture:
                immutable uint id = mTextureIDs[rid];
                glDeleteTextures(1, &id);
                mTextureIDs.remove(rid);
                break;

            case mesh:
                immutable MeshData data = mMeshData[rid];
                glDeleteBuffers(1, &data.vbo);
                glDeleteBuffers(1, &data.ebo);
                glDeleteVertexArrays(1, &data.vao);
                mMeshData.remove(rid);
                break;
            }
            
            mRidType.remove(rid);
        }
    }

    void drawIndexed(size_t count)
    {
        glDrawElements(GL_TRIANGLES, cast(int) count, GL_UNSIGNED_INT, null);
    
        version (ZW_Profiling)
        {
            ++Profiler.currentWriteData.renderData.drawCalls;
            Profiler.currentWriteData.renderData.polygonCount += count / 3;
        }
    }

    RID createMesh(in Vertex3D[] vertices, in uint[] indices)
    {
        MeshData data;

        glGenVertexArrays(1, &data.vao);
        glGenBuffers(1, &data.vbo);
        glGenBuffers(1, &data.ebo);

        glBindVertexArray(data.vao);
        glBindBuffer(GL_ARRAY_BUFFER, data.vbo);

        glBufferData(GL_ARRAY_BUFFER, vertices.length * Vertex3D.sizeof, &vertices[0], GL_STATIC_DRAW);  

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, data.ebo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * uint.sizeof, 
                    &indices[0], GL_STATIC_DRAW);

        // vertex positions
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*) 0);
        // vertex normals
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*) Vertex.normal.offsetof);
        // vertex texture coords
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*) Vertex.uv.offsetof);
        // vertex color
        glEnableVertexAttribArray(3);
        glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*) Vertex.color.offsetof);
        // vertex material index
        glEnableVertexAttribArray(4);
        glVertexAttribPointer(4, 1, GL_UNSIGNED_BYTE, GL_FALSE, Vertex.sizeof, cast(void*) Vertex.materialIdx.offsetof);

        glBindVertexArray(0);

        immutable RID rid = getNextRID();
        mMeshData[rid] = data;
        mRidType[rid] = RIDType.mesh;
        addRef(rid);

        return rid;
    }

    RID createTexture2D(in Image image, in TextureProperties properties)
    {
        const(ubyte)[] pixels = image.pixels;

        assert(pixels.length <= image.size.x * image.size.y * image.channels,
            "Too much pixel data for texture size.");

        GLenum internalFormat, srcFormat;

        final switch (image.channels)
        {
        case 1:
        case 2:
            internalFormat = GL_ALPHA;
            srcFormat = GL_ALPHA;
            break;

        case 3:
            internalFormat = GL_RGB8;
            srcFormat = GL_RGB;
            break;

        case 4:
            internalFormat = GL_RGBA8;
            srcFormat = GL_RGBA;
            break;
        }

        uint id;

        glGenTextures(1, &id);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, id);

        glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, mSize.x, mSize.y, 0, srcFormat, GL_UNSIGNED_BYTE, pixels.ptr);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

        if (properties.generateMipmaps)
            glGenerateMipmap(GL_TEXTURE_2D);

        immutable RID rid = getNextRID();
        mTextureIDs[rid] = id;
        mRidType[rid] = RIDType.texture;
        addRef(rid);

        return rid;
    }

    RID createTextureCubeMap(in Image[6] images, in TextureProperties properties)
    {
        uint id;

        glGenTextures(1, &id);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, id);

        for (size_t i; i < 6; ++i)
        {
            GLenum internalFormat, srcFormat;

            final switch (images[i].channels)
            {
            case 1:
            case 2:
                internalFormat = GL_ALPHA;
                srcFormat = GL_ALPHA;
                break;

            case 3:
                internalFormat = GL_RGB8;
                srcFormat = GL_RGB;
                break;

            case 4:
                internalFormat = GL_RGBA8;
                srcFormat = GL_RGBA;
                break;
            }

            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(int) i, 0, internalFormat, images[i].size.x, images[i].size.y, 0, srcFormat,
                GL_UNSIGNED_BYTE, images[i].pixels.ptr);
        }

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

        if (properties.generateMipmaps)
            glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

        immutable RID rid = getNextRID();
        mTextureIDs[rid] = id;
        mRidType[rid] = RIDType.texture;
        addRef(rid);

        return rid;
    }
}

private:

GLuint getGLFilter(TextureProperties.Filter filter)
{
    static GLint[TextureProperties.Filter] glFilter;

    if (!glFilter) 
        glFilter = [
            TextureProperties.Filter.nearest: GL_NEAREST,
            TextureProperties.Filter.linear: GL_LINEAR,
            TextureProperties.Filter.bilinear: GL_LINEAR,
            TextureProperties.Filter.trilinear: GL_LINEAR_MIPMAP_LINEAR
        ];

    return glFilter[filter];
}

GLuint getGLWrapMode(TextureProperties.WrapMode wrapMode)
{
    static GLint[TextureProperties.WrapMode] glWrapMode;

    if (!glWrapMode)
        glWrapMode = [
            TextureProperties.WrapMode.repeat: GL_REPEAT,
            TextureProperties.WrapMode.mirroredRepeat: GL_MIRRORED_REPEAT,
            TextureProperties.WrapMode.clampToEdge: GL_CLAMP_TO_EDGE
        ];

    return glWrapMode[wrapMode];
}

/+
void apiInitialize()
{
    
}

void apiLoadLibraries()
{
    import loader = bindbc.loader.sharedlib;
    import std.string : fromStringz;

    if (isOpenGLLoaded())
        return;

    immutable glResult = loadOpenGL();
    
    if (glResult != glSupport)
    {
        foreach (info; loader.errors)
            Logger.core.log(LogLevel.warning, "OpenGL loader: %s", info.message.fromStringz);

        switch (glResult)
        {
        case GLSupport.noLibrary:
            throw new GraphicsException("Could not find OpenGL shared library.");

        case GLSupport.badLibrary:
            throw new GraphicsException("Provided OpenGL shared is corrupted.");

        case GLSupport.noContext:
            throw new GraphicsException("No OpenGL context available.");

        default:
            Logger.core.log(LogLevel.warning, "Got older OpenGL version than expected. This might lead to errors.");
        }
    }
}

void apiCleanup()
{
}

void apiSetClearColor(in Color value) nothrow
{
    glClearColor(value.r, value.g, value.b, value.a);
}

void apiClear() nothrow
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void apiSetViewport(int x, int y, uint width, uint height) nothrow
{
    glViewport(x, y, cast(GLsizei) width, cast(GLsizei) height);
}

void apiDrawIndexed(size_t count) nothrow
{
    glDrawElements(GL_TRIANGLES, cast(int) count, GL_UNSIGNED_INT, null);
    
    version (ZW_Profiling)
    {
        ++Profiler.currentWriteData.renderData.drawCalls;
        Profiler.currentWriteData.renderData.polygonCount += count / 3;
    }
}

void apiPackLightConstantBuffer(ref ConstantBuffer buffer, in Renderer3D.Light[] lights) nothrow
{
    Vector4f[10] positions;
    Vector4f[10] colors;
    Vector4f[10] attenuations;

    for (size_t i; i < lights.length; ++i)
    {
        positions[i] = Vector4f(lights[i].position, 0);
        colors[i] = lights[i].color;
        attenuations[i] = Vector4f(lights[i].attenuation, 0);
    }

    buffer.setData(buffer.getEntryOffset("position"), positions);
    buffer.setData(buffer.getEntryOffset("color"), colors);
    buffer.setData(buffer.getEntryOffset("attenuation"), attenuations);
}

bool apiGetFlag(RenderFlag flag) nothrow
{
    return pFlagValues[flag];
}

void apiSetFlag(RenderFlag flag, bool value) nothrow
{
    if (pFlagValues[flag] == value)
        return;

    final switch (flag) with (RenderFlag)
    {
    case depthTesting:
        if (value)
            glEnable(GL_DEPTH_TEST);
        else
            glDisable(GL_DEPTH_TEST);
        break;

    case depthBufferWriting:
        glDepthMask(value);
        break;

    case culling:
        if (value)
            glEnable(GL_CULL_FACE);
        else
            glDisable(GL_CULL_FACE);
        break;

    case stencilTesting:
        if (value)
            glEnable(GL_STENCIL_TEST);
        else
            glDisable(GL_STENCIL_TEST);
        break;

    case wireframe:
        glPolygonMode(GL_FRONT_AND_BACK, value ? GL_LINE : GL_FILL);
        break;
    }

    pFlagValues[flag] = value;
}

size_t apiGetCapability(RenderCapability capability) nothrow
{
    final switch (capability) with (RenderCapability)
    {
    case maxTextureSlots:
        GLint result;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &result);
        return result;
    }
}+/