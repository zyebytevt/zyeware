// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.graphics.opengl.api;

import zyeware.pal.graphics.callbacks;

version (ZW_OpenGL):

import std.typecons : Tuple;
import std.exception : assumeWontThrow;
import std.string : format, toStringz;

import bindbc.opengl;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

import zyeware.pal.graphics.opengl.shader;
import zyeware.pal.graphics.types;

private:

struct SequentialBuffer(T)
{
private:
    T[] mBuffer = new T[8];

public:
    T* add(in T value) nothrow
    {
        for (size_t i; i < mBuffer.length; ++i)
        {
            if (mBuffer[i] == T.init)
            {
                mBuffer[i] = value;
                return &mBuffer[i];
            }
        }

        size_t oldLength = mBuffer.length;
        mBuffer.length *= 2;
        mBuffer[oldLength] = value;
        return &mBuffer[oldLength];
    }

    T[] data() nothrow
    {
        return mBuffer[0..mBuffer.length];
    }
}

struct MeshData
{
    uint vao;
    uint vbo;
    uint ibo;
}

bool[RenderFlag] pFlagValues;

SequentialBuffer!uint pTexture2DIDs;
SequentialBuffer!uint pTextureCubeMapIDs;
SequentialBuffer!MeshData pMeshData;
SequentialBuffer!uint pFramebufferIDs;
SequentialBuffer!uint pShaderIDs;

version (Windows)
{
    extern(Windows) static void palGlErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        palGlErrorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}
else
{
    extern(C) static void palGlErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        palGlErrorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}

pragma(inline, true)
void palGlErrorCallbackImpl(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
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

GLuint palGlGetGLFilter(TextureProperties.Filter filter)
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

GLuint palGlGetGLWrapMode(TextureProperties.WrapMode wrapMode)
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

void palGlInitialize()
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
    glDebugMessageCallback(&palGlErrorCallback, null);

    glLineWidth(2);
    glPointSize(4);

    {
        import std.traits : EnumMembers;

        foreach (flag; EnumMembers!RenderFlag)
            pFlagValues[flag] = false;

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

void palGlLoadLibs()
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

void palGlCleanup()
{
    foreach (ref uint id; pTexture2DIDs.data)
        palGlFreeTexture2D(cast(NativeHandle) &id);

    foreach (ref uint id; pTextureCubeMapIDs.data)
        palGlFreeTextureCubeMap(cast(NativeHandle) &id);

    foreach (ref MeshData data; pMeshData.data)
        palGlFreeMesh(cast(NativeHandle) &data);

    foreach (ref uint id; pFramebufferIDs.data)
        palGlFreeFramebuffer(cast(NativeHandle) &id);

    foreach (ref uint id; pShaderIDs.data)
        palGlFreeShader(cast(NativeHandle) &id);
}

package(zyeware.pal):

NativeHandle palGlCreateMesh(in Vertex3D[] vertices, in uint[] indices)
{
    MeshData data;

    glGenVertexArrays(1, &data.vao);
    glGenBuffers(1, &data.vbo);
    glGenBuffers(1, &data.ibo);

    glBindVertexArray(data.vao);
    glBindBuffer(GL_ARRAY_BUFFER, data.vbo);

    glBufferData(GL_ARRAY_BUFFER, vertices.length * Vertex3D.sizeof, &vertices[0], GL_STATIC_DRAW);  

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, data.ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * uint.sizeof, 
                &indices[0], GL_STATIC_DRAW);

    // vertex positions
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex3D.sizeof, cast(void*) Vertex3D.position.offsetof);
    // vertex normals
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, Vertex3D.sizeof, cast(void*) Vertex3D.normal.offsetof);
    // vertex texture coords
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, Vertex3D.sizeof, cast(void*) Vertex3D.uv.offsetof);
    // vertex color
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, Vertex3D.sizeof, cast(void*) Vertex3D.color.offsetof);

    glBindVertexArray(0);

    return cast(NativeHandle) pMeshData.add(data);
}

NativeHandle palGlCreateTexture2D(in Image image, in TextureProperties properties)
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

    glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, image.size.x, image.size.y, 0, srcFormat, GL_UNSIGNED_BYTE, pixels.ptr);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, palGlGetGLFilter(properties.minFilter));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, palGlGetGLFilter(properties.magFilter));

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, palGlGetGLWrapMode(properties.wrapS));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, palGlGetGLWrapMode(properties.wrapT));

    if (properties.generateMipmaps)
        glGenerateMipmap(GL_TEXTURE_2D);

    return cast(NativeHandle) pTexture2DIDs.add(id);
}

NativeHandle palGlCreateTextureCubeMap(in Image[6] images, in TextureProperties properties)
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

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, palGlGetGLFilter(properties.minFilter));
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, palGlGetGLFilter(properties.magFilter));

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, palGlGetGLWrapMode(properties.wrapS));
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, palGlGetGLWrapMode(properties.wrapT));

    if (properties.generateMipmaps)
        glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    return cast(NativeHandle) pTextureCubeMapIDs.add(id);
}

NativeHandle palGlCreateFramebuffer(in FramebufferProperties properties)
{
    uint id;

    glGenFramebuffers(1, &id);
    glBindFramebuffer(GL_FRAMEBUFFER, id);

    uint colorRBO, depthRBO;

    glGenRenderbuffers(1, &colorRBO);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRBO);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB8, properties.size.x, properties.size.y);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRBO);

    glGenRenderbuffers(1, &depthRBO);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRBO);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, properties.size.x, properties.size.y);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depthRBO);

    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer is incomplete.");

    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    return cast(NativeHandle) pFramebufferIDs.add(id);
}

NativeHandle palGlCreateShader(in ShaderProperties properties)
{
    immutable uint programID = glCreateProgram();

    foreach (ShaderProperties.ShaderType type, string source; properties.sources)
    {
        GLenum shaderType;

        final switch (type) with (ShaderProperties.ShaderType)
        {
        case vertex:
            shaderType = GL_VERTEX_SHADER;
            break;

        case fragment:
            shaderType = GL_FRAGMENT_SHADER;
            break;

        case geometry:
            shaderType = GL_GEOMETRY_SHADER;
            break;

        case compute:
        //    shaderType = GL_COMPUTE_SHADER;
            break;
        }

        uint shaderID = glCreateShader(shaderType);

        const char* sourcePtr = cast(char*) source.ptr;

        glShaderSource(shaderID, 1, &sourcePtr, null);
        glCompileShader(shaderID);

        int success;
        glGetShaderiv(shaderID, GL_COMPILE_STATUS, &success);

        if (!success)
        {
            char[2048] infoLog;
            GLsizei length;
            glGetShaderInfoLog(shaderID, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
            throw new GraphicsException(format!"Shader compilation failed: %s"(infoLog[0..length]));
        }

        glAttachShader(programID, shaderID);
        glDeleteShader(shaderID);
    }

    glLinkProgram(programID);

    int success;
    glGetProgramiv(programID, GL_LINK_STATUS, &success);

    if (!success)
    {
        char[2048] infoLog;
        GLsizei length;
        glGetProgramInfoLog(programID, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
        throw new GraphicsException(format!"Shader linking failed: %s"(infoLog[0..length]));
    }

    glValidateProgram(programID);
    glGetProgramiv(programID, GL_VALIDATE_STATUS, &success);

    if (!success)
    {
        char[2048] infoLog;
        GLsizei length;
        glGetProgramInfoLog(programID, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
        throw new GraphicsException(format!"Shader validation failed: %s"(infoLog[0..length]));
    }

    return cast(NativeHandle) pShaderIDs.add(programID);
}

void palGlFreeMesh(NativeHandle mesh) nothrow
{
    auto data = cast(MeshData*) mesh;

    glDeleteBuffers(1, &data.vbo);
    glDeleteBuffers(1, &data.ibo);
    glDeleteVertexArrays(1, &data.vao);

    *data = MeshData.init;
}

void palGlFreeTexture2D(NativeHandle texture) nothrow
{
    uint* id = cast(uint*) texture;
    
    glDeleteTextures(1, id);
    *id = uint.init;
}

void palGlFreeTextureCubeMap(NativeHandle texture) nothrow
{
    palGlFreeTexture2D(texture);
}

void palGlFreeFramebuffer(NativeHandle framebuffer) nothrow
{
    uint* id = cast(uint*) framebuffer;

    glDeleteFramebuffers(1, id);
    *id = uint.init;
}

void palGlFreeShader(NativeHandle shader) nothrow
{
    uint* id = cast(uint*) shader;

    glDeleteProgram(*id);
    *id = uint.init;
}

void palGlSetViewport(Rect2i region) nothrow
{
    glViewport(region.position.x, region.position.y, region.size.x, region.size.y);
}

void palGlSetRenderFlag(RenderFlag flag, bool value) nothrow
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

bool palGlGetRenderFlag(RenderFlag flag) nothrow
{
    return pFlagValues[flag];
}

size_t palGlGetRenderCapability(RenderCapability capability) nothrow
{
    final switch (capability) with (RenderCapability)
    {
    case maxTextureSlots:
        GLint result;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &result);
        return result;
    }
}

void palGlClearScreen(Color clearColor) nothrow
{
    glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void palGlSetRenderTarget(in NativeHandle target) nothrow
{
    glBindFramebuffer(GL_FRAMEBUFFER, target ? *(cast(uint*) target) : 0);
}

void palGlPresentToScreen(in NativeHandle framebuffer, Rect2i srcRegion, Rect2i dstRegion) nothrow
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, *(cast(uint*) framebuffer));
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

    glClear(GL_COLOR_BUFFER_BIT);
    glBlitFramebuffer(srcRegion.position.x, srcRegion.position.y, srcRegion.size.x, srcRegion.size.y, dstRegion.position.x, dstRegion.position.y,
        dstRegion.size.x, dstRegion.size.y, GL_COLOR_BUFFER_BIT, GL_NEAREST);
}

public:

GraphicsPALCallbacks palGlGenerateCallbacks()
{
    return GraphicsPALCallbacks(
        &palGlInitialize,
        &palGlLoadLibs,
        &palGlCleanup,
        &palGlCreateMesh,
        &palGlCreateTexture2D,
        &palGlCreateTextureCubeMap,
        &palGlCreateFramebuffer,
        &palGlCreateShader,
        &palGlFreeMesh,
        &palGlFreeTexture2D,
        &palGlFreeTextureCubeMap,
        &palGlFreeFramebuffer,
        &palGlFreeShader,
        &palGlSetShaderUniform1f,
        &palGlSetShaderUniform2f,
        &palGlSetShaderUniform3f,
        &palGlSetShaderUniform4f,
        &palGlSetShaderUniform1i,
        &palGlSetShaderUniformMat4f,
        &palGlSetViewport,
        &palGlSetRenderFlag,
        &palGlGetRenderFlag,
        &palGlGetRenderCapability,
        &palGlClearScreen,
        &palGlSetRenderTarget,
        &palGlPresentToScreen,
    );
}