// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.opengl.api;

version (ZW_OpenGL):
package(zyeware.rendering.opengl):

import std.typecons : Tuple;
import std.string : format;

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

pragma(inline, true)
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

    enum RIDCategory : ushort
    {
        texture,
        mesh,
        framebuffer,
        shader
    }

    bool[RenderFlag] mFlagValues;
    ushort[ushort] mNextRID;

    uint[ushort] mTextureIDs;
    MeshData[ushort] mMeshData;
    uint[ushort] mFramebufferIDs;
    uint[ushort] mShaderIDs;

    pragma(inline, true)
    ushort getNextRID(ushort category) pure nothrow
    {
        ushort* nextId = category in mNextRID;
        
        return RID(category, nextId ? (*nextId)++ : (mNextRID[category] = 0));
    }

    pragma(inline, true)
    void freeTexture(uint id) nothrow
    {
        glDeleteTextures(1, &id);
    }

    pragma(inline, true)
    void freeMesh(ref MeshData data) nothrow
    {
        glDeleteBuffers(1, &data.vbo);
        glDeleteBuffers(1, &data.ebo);
        glDeleteVertexArrays(1, &data.vao);
    }

    pragma(inline, true)
    void freeFramebuffer(uint id) nothrow
    {
        glDeleteFramebuffers(1, &id);
    }

    pragma(inline, true)
    void freeShader(uint id) nothrow
    {
        glDeleteProgram(id);
    }

public:
    void initialize()
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

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glEnable(GL_CULL_FACE);
        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);

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
        foreach (uint id; mTextureIDs.values)
            freeTexture(id);

        foreach (ref MeshData data; mMeshData.values)
            freeMesh(data);

        foreach (uint id; mFramebufferIDs.values)
            freeFramebuffer(id);

        foreach (uint id; mShaderIDs.values)
            freeShader(id);
    }

    void free(RID rid) nothrow
    {
        final switch (rid.category) with (RIDType)
        {
        case texture:
            freeTexture(mTextureIDs[rid.id]);
            mTextureIDs.remove(rid);
            break;

        case mesh:
            freeMesh(mMeshData[rid.id]);
            mMeshData.remove(rid);
            break;

        case framebuffer:
            freeFramebuffer(mFramebufferIDs[rid.id]);
            mFramebufferIDs.remove(rid);
            break;

        case shader:
            freeShader(mShaderIDs[rid.id]);
            mShaderIDs.remove(rid);
            break;
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

        immutable RID rid = getNextRID(RIDCategory.mesh);
        mMeshData[rid] = data;

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

        immutable RID rid = getNextRID(RIDCategory.texture);
        mTextureIDs[rid.id] = id;

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

        immutable RID rid = getNextRID(RIDCategory.texture);
        mTextureIDs[rid.id] = id;

        return rid;
    }

    RID createFramebuffer(in FramebufferProperties properties)
    {
        uint id;

        glGenFramebuffers(1, &id);
        glBindFramebuffer(GL_FRAMEBUFFER, id);

        uint textureID;

        glGenTextures(1, &textureID);
        glBindTexture(GL_TEXTURE_2D, textureID);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, properties.size.x, properties.size.y, 0, GL_RGB, GL_UNSIGNED_BYTE, null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureID, 0);

        uint rbo;

        glGenRenderbuffers(1, &rbo);
        glBindRenderbuffer(GL_RENDERBUFFER, rbo);

        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, properties.size.x, properties.size.y);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);

        assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer is incomplete.");

        glBindFramebuffer(GL_FRAMEBUFFER, 0);

        immutable RID rid = getNextRID(RIDCategory.framebuffer);
        mFramebufferIDs[rid.id] = id;

        return rid;
    }

    RID createShader(in ShaderProperties properties)
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
                shaderType = GL_COMPUTE_SHADER;
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

        immutable RID rid = getNextRID(RIDCategory.shader);
        mShaderIDs[rid.id] = programID;

        return rid;
    }

    void setViewport(Rect2i region) nothrow
    {
        glViewport(region.position.x, region.position.y, region.size.x, region.size.y);
    }

    void setRenderFlag(RenderFlag flag, bool value) nothrow
    {
        if (mFlagValues[flag] == value)
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

        mFlagValues[flag] = value;
    }

    bool getRenderFlag(RenderFlag flag) nothrow
    {
        return mFlagValues[flag];
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