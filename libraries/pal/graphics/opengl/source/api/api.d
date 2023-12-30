// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.graphics.opengl.api.api;

import std.typecons : Tuple;
import std.exception : assumeWontThrow;
import std.string : format, toStringz, fromStringz;
import std.conv : dtext;

import bindbc.opengl;

import zyeware;

import zyeware.pal;

import zyeware.pal.graphics.types;
import zyeware.pal.graphics.opengl.api.types;
import zyeware.pal.graphics.opengl.api.utils;

package(zyeware.pal.graphics.opengl):

bool[cast(size_t) RenderFlag.max + 1] pFlagValues;
uint[UniformLocationKey] pUniformLocationCache;

version (Windows)
{
    extern (Windows)
    static void errorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        errorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}
else
{
    extern (C)
    static void errorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        errorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}

uint prepareShaderUniformAssignAndGetLocation(in NativeHandle shader, string name) nothrow
{
    immutable uint id = *(cast(uint*) shader);
    glUseProgram(id);

    immutable auto key = UniformLocationKey(id, name);
    uint* location = key in pUniformLocationCache;
    if (!location)
        return pUniformLocationCache[key] = glGetUniformLocation(id, name.toStringz);
    
    return *location;
}

pragma(inline, true)
static void errorCallbackImpl(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
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

    logPal.log(logLevel, format!"%s: %s"d(typeName, message.fromStringz).assumeWontThrow);
}

void initialize()
{
    import loader = bindbc.loader.sharedlib;

    if (isOpenGLLoaded())
        return;

    immutable glResult = loadOpenGL();
    
    if (glResult != glSupport)
    {
        foreach (info; loader.errors)
            logPal.warning("OpenGL loader: %s", info.message.fromStringz);

        switch (glResult)
        {
        case GLSupport.noLibrary:
            throw new GraphicsException("Could not find OpenGL shared library.");

        case GLSupport.badLibrary:
            throw new GraphicsException("Provided OpenGL shared is corrupted.");

        case GLSupport.noContext:
            throw new GraphicsException("No OpenGL context available.");

        default:
            logPal.warning("Got older OpenGL version than expected. This might lead to errors.");
        }
    }

    logPal.debug_("OpenGL dynamic library loaded.");

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
    glDebugMessageCallback(&errorCallback, null);

    glLineWidth(2);
    glPointSize(4);

    {
        GLboolean resultBool;
        GLint resultInt;

        glGetBooleanv(GL_DEPTH_TEST, &resultBool);
        pFlagValues[cast(size_t) RenderFlag.depthTesting] = cast(bool) resultBool;
        glGetBooleanv(GL_DEPTH_WRITEMASK, &resultBool);
        pFlagValues[cast(size_t) RenderFlag.depthBufferWriting] = cast(bool) resultBool;
        glGetBooleanv(GL_CULL_FACE, &resultBool);
        pFlagValues[cast(size_t) RenderFlag.culling] = cast(bool) resultBool;
        glGetBooleanv(GL_STENCIL_TEST, &resultBool);
        pFlagValues[cast(size_t) RenderFlag.stencilTesting] = cast(bool) resultBool;
        glGetIntegerv(GL_POLYGON_MODE, &resultInt);
        pFlagValues[cast(size_t) RenderFlag.wireframe] = resultInt == GL_LINE;
    }

    logPal.info("Initialized OpenGL:");
    logPal.info("    Vendor: %s", glGetString(GL_VENDOR).fromStringz);
    logPal.info("    Renderer: %s", glGetString(GL_RENDERER).fromStringz);
    logPal.info("    Version: %s", glGetString(GL_VERSION).fromStringz);
    logPal.info("    GLSL Version: %s", glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz);
    logPal.info("    Extensions: %s", glGetString(GL_EXTENSIONS).fromStringz);
}

void cleanup()
{
}

NativeHandle createMesh(in Vertex3D[] vertices, in uint[] indices)
{
    auto data = new MeshData;

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
    // vertex modulate
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, Vertex3D.sizeof, cast(void*) Vertex3D.modulate.offsetof);

    glBindVertexArray(0);

    return cast(NativeHandle) data;
}

NativeHandle createTexture2D(in Image image, in TextureProperties properties)
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

    auto id = new uint;

    glGenTextures(1, id);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, *id);

    glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, image.size.x, image.size.y, 0, srcFormat, GL_UNSIGNED_BYTE, pixels.ptr);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

    if (properties.generateMipmaps)
        glGenerateMipmap(GL_TEXTURE_2D);

    return cast(NativeHandle) id;
}

NativeHandle createTextureCubeMap(in Image[6] images, in TextureProperties properties)
{
    auto id = new uint;

    glGenTextures(1, id);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, *id);

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

    return cast(NativeHandle) id;
}

NativeHandle createFramebuffer(in FramebufferProperties properties)
{
    auto framebuffer = new FramebufferData;

    glGenFramebuffers(1, &framebuffer.id);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id);

    // Create the modulate attachment based on the properties.
    final switch (properties.usageType) with (FramebufferProperties.UsageType)
    {
    case swapChainTarget:
        glGenRenderbuffers(1, &framebuffer.colorAttachmentId);
        glBindRenderbuffer(GL_RENDERBUFFER, framebuffer.colorAttachmentId);

        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB8, properties.size.x, properties.size.y);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, framebuffer.colorAttachmentId);
        break;

    case texture:
        glGenTextures(1, &framebuffer.colorAttachmentId);
        glBindTexture(GL_TEXTURE_2D, framebuffer.colorAttachmentId);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, properties.size.x, properties.size.y, 0, GL_RGB, GL_UNSIGNED_BYTE, null);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, framebuffer.colorAttachmentId, 0);
        break;
    }

    // Now generate the depth buffer, which will always be a renderbuffer.
    glGenRenderbuffers(1, &framebuffer.depthAttachmentId);
    glBindRenderbuffer(GL_RENDERBUFFER, framebuffer.depthAttachmentId);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, properties.size.x, properties.size.y);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, framebuffer.depthAttachmentId);

    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer is incomplete.");

    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    return cast(NativeHandle) framebuffer;
}

NativeHandle createShader(in ShaderProperties properties)
{
    auto id = new uint;
    *id = glCreateProgram();

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

        glAttachShader(*id, shaderID);
        glDeleteShader(shaderID);
    }

    glLinkProgram(*id);

    int success;
    glGetProgramiv(*id, GL_LINK_STATUS, &success);

    if (!success)
    {
        char[2048] infoLog;
        GLsizei length;
        glGetProgramInfoLog(*id, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
        throw new GraphicsException(format!"Shader linking failed: %s"(infoLog[0..length]));
    }

    glValidateProgram(*id);
    glGetProgramiv(*id, GL_VALIDATE_STATUS, &success);

    if (!success)
    {
        char[2048] infoLog;
        GLsizei length;
        glGetProgramInfoLog(*id, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
        throw new GraphicsException(format!"Shader validation failed: %s"(infoLog[0..length]));
    }

    return cast(NativeHandle) id;
}

void freeMesh(NativeHandle mesh) nothrow
{
    auto data = cast(MeshData*) mesh;

    glDeleteBuffers(1, &data.vbo);
    glDeleteBuffers(1, &data.ibo);
    glDeleteVertexArrays(1, &data.vao);

    destroy(data);
}

void freeTexture2D(NativeHandle texture) nothrow
{
    auto id = cast(uint*) texture;
    
    glDeleteTextures(1, id);
    
    destroy(id);
}

void freeTextureCubeMap(NativeHandle texture) nothrow
{
    freeTexture2D(texture);
}

void freeFramebuffer(NativeHandle framebuffer) nothrow
{
    auto data = cast(FramebufferData*) framebuffer;

    glDeleteFramebuffers(1, &data.id);

    // Order is important, as a renderbuffer is also a texture.
    if (glIsRenderbuffer(data.colorAttachmentId))
        glDeleteRenderbuffers(1, &data.colorAttachmentId);
    else if (glIsTexture(data.colorAttachmentId))
        glDeleteTextures(1, &data.colorAttachmentId);

    glDeleteRenderbuffers(1, &data.depthAttachmentId);

    destroy(data);
}

void freeShader(NativeHandle shader) nothrow
{
    auto id = cast(uint*) shader;

    glDeleteProgram(*id);
    
    destroy(id);
}

void setViewport(recti region) nothrow
{
    glViewport(region.x, region.y, region.width, region.height);
}

void setRenderFlag(RenderFlag flag, bool value) nothrow
{
    if (pFlagValues[cast(size_t) flag] == value)
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

    pFlagValues[cast(size_t) flag] = value;
}

bool getRenderFlag(RenderFlag flag) nothrow
{
    return pFlagValues[cast(size_t) flag];
}

size_t getCapability(RenderCapability capability) nothrow
{
    final switch (capability) with (RenderCapability)
    {
    case maxTextureSlots:
        GLint result;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &result);
        return result;
    }
}

void clearScreen(color clearColor) nothrow
{
    glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void setRenderTarget(in NativeHandle target) nothrow
{
    glBindFramebuffer(GL_FRAMEBUFFER, target ? *(cast(uint*) target) : 0);
}

void presentToScreen(in NativeHandle framebuffer, recti srcRegion, recti dstRegion) nothrow
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, *(cast(uint*) framebuffer));
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

    glClear(GL_COLOR_BUFFER_BIT);
    glBlitFramebuffer(srcRegion.x, srcRegion.y, srcRegion.width, srcRegion.height, dstRegion.x, dstRegion.y,
        dstRegion.width, dstRegion.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
}

NativeHandle getTextureFromFramebuffer(in NativeHandle framebuffer) nothrow
{
    FramebufferData* data = cast(FramebufferData*) framebuffer;

    assert(glIsTexture(data.colorAttachmentId), "Framebuffer modulate attachment is not a texture.");

    return cast(NativeHandle) &data.colorAttachmentId;
}

void setShaderUniform1f(in NativeHandle shader, in string name, in float value) nothrow
{
    glUniform1f(prepareShaderUniformAssignAndGetLocation(shader, name), value);
}

void setShaderUniform2f(in NativeHandle shader, in string name, in vec2 value) nothrow
{
    glUniform2f(prepareShaderUniformAssignAndGetLocation(shader, name), value.x, value.y);
}

void setShaderUniform3f(in NativeHandle shader, in string name, in vec3 value) nothrow
{
    glUniform3f(prepareShaderUniformAssignAndGetLocation(shader, name), value.x, value.y, value.z);
}

void setShaderUniform4f(in NativeHandle shader, in string name, in vec4 value) nothrow
{
    glUniform4f(prepareShaderUniformAssignAndGetLocation(shader, name), value.x, value.y, value.z, value.w);
}

void setShaderUniform1i(in NativeHandle shader, in string name, in int value) nothrow
{
    glUniform1i(prepareShaderUniformAssignAndGetLocation(shader, name), value);
}

void setShaderUniformMat4f(in NativeHandle shader, in string name, in mat4 value) nothrow
{
    glUniformMatrix4fv(prepareShaderUniformAssignAndGetLocation(shader, name), 1, GL_TRUE, value.ptr);
}