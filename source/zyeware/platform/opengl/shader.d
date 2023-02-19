// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.platform.opengl.shader;

version (ZW_OpenGL):
package(zyeware.platform.opengl):

import std.typecons : Rebindable;
import std.string : toStringz, fromStringz, format;
import std.exception : enforce, assumeWontThrow;
import std.regex : ctRegex, matchAll;
import std.typecons : Tuple;
import std.array : replaceInPlace;

import bindbc.opengl;
import inmath.linalg;
import sdlang;

import zyeware.common;
import zyeware.rendering;

class OGLShader : Shader
{
private:
    static Rebindable!(const Shader) sCurrentlyBoundShader;
    static int[string] sUniformBlockBindings;

protected:
    uint mProgramID;

    uint[] mCompiledShaderIDs;
    size_t mTextureCount;

    // As to get it compiling on MacOS, we limit to OpenGL 4.1 and assign
    // bindings directly. Additionally, this method calculates the amount
    // of texture uniforms in this program.
    void parseUniforms() @trusted
    {
        bind().assumeWontThrow;

        int samplerID;
        int count, size;
        uint type;
        char[32] name;
        GLsizei nameLength;
        glGetProgramiv(mProgramID, GL_ACTIVE_UNIFORMS, &count);

        for (size_t i; i < count; ++i)
        {
            glGetActiveUniform(mProgramID, cast(uint) i, name.length, &nameLength, &size, &type, name.ptr);

            // If uniform is a sampler, count them.
            if (type >= GL_SAMPLER_1D && type <= GL_UNSIGNED_INT_SAMPLER_2D_RECT)
            {
                immutable int location = glGetUniformLocation(mProgramID, &name[0]);

                if (size == 1)
                {
                    glUniform1i(location, samplerID++);
                    Logger.core.log(LogLevel.debug_, "Assigning sampler uniform '%s' ID %d.",
                        name[0..nameLength], samplerID - 1);
                }
                else
                {
                    int[] samplerIDs = new int[size];
                    for (size_t j; j < size; ++j)
                        samplerIDs[j] = samplerID++;

                    glUniform1iv(location, size, samplerIDs.ptr);
                    Logger.core.log(LogLevel.debug_, "Assigning sampler uniform array '%s' IDs %d through %d.",
                        name[0..nameLength], samplerIDs[0], samplerIDs[$ - 1]);

                    samplerIDs.destroy();
                }
            }
        }

        mTextureCount = samplerID;

        foreach (string uniformName, int binding; sUniformBlockBindings)
        {
            int blockIndex = glGetUniformBlockIndex(mProgramID, uniformName.toStringz);
            if (blockIndex != -1)
                glUniformBlockBinding(mProgramID, blockIndex, binding);
        }
    }

package(zyeware.platform.opengl):
    this()
    {
        mProgramID = glCreateProgram();
        enforce!GraphicsException(mProgramID > 0, "Failed to allocate new shader program.");

        sUniformBlockBindings = [
            "Matrices": ConstantBuffer.Slot.matrices,
            "Environment": ConstantBuffer.Slot.environment,
            "Lights": ConstantBuffer.Slot.lights,
            "ModelUniforms": ConstantBuffer.Slot.modelVariables
        ];
    }

    static Shader load(string path)
        in (path, "Path cannot be null.")
    {
        Logger.core.log(LogLevel.debug_, "Loading shader '%s'...", path);

        string parseIncludes(string source)
        {
            enum includeRegex = ctRegex!("^#include \"(.*)\"$", "m");

            char[] mutableSource = source.dup;
            alias Include = Tuple!(char[], "path", size_t, "position", size_t, "length");
            
            Include[] includes;
            ptrdiff_t offset;
            size_t includeIterations;

            do
            {
                enforce!GraphicsException(++includeIterations < 100,
                    "Too many iterations, possible infinite include recursion.");

                includes.length = 0;
                foreach (m; matchAll(mutableSource, includeRegex))
                    includes ~= Include(m[1], m.pre.length, m.hit.length);

                foreach (ref Include include; includes)
                {
                    VFSFile includeFile = VFS.getFile(cast(string) include.path);
                    char[] includeSource = cast(char[]) includeFile.readAll!string;
                    includeFile.close();

                    immutable size_t from = include.position + offset;
                    immutable size_t to = from + include.length;

                    mutableSource.replaceInPlace(from, to, includeSource);
                    offset += cast(ptrdiff_t) includeSource.length - include.length;
                }
            } while (includes.length > 0);

            return mutableSource.idup;
        }

        VFSFile file = VFS.getFile(path);
        immutable string source = file.readAll!string;
        Tag root = parseSource(source);
        file.close();

        auto shader = new OGLShader();

        void loadShader(ref Tag tag, int type)
        {
            if (string filePath = tag.getAttribute!string("file", null))
            {
                Logger.core.log(LogLevel.verbose, "Loading external shader source '%s'...", filePath);
                VFSFile shaderFile = VFS.getFile(filePath);
                shader.compileShader(parseIncludes(shaderFile.readAll!string), type);
                shaderFile.close();
            }
            else
                shader.compileShader(parseIncludes(tag.getValue!string), type);
        }

        foreach (ref Tag tag; root.namespaces["opengl"].tags)
        {
            switch (tag.name)
            {
            case "vertex":
                loadShader(tag, GL_VERTEX_SHADER);
                break;

            case "fragment":
                loadShader(tag, GL_FRAGMENT_SHADER);
                break;

            default:
                Logger.core.log(LogLevel.warning, "'%s' %s: Unknown tag '%s'.",
                    path, tag.location, tag.getFullName());
            }
        }

        shader.link();

        return shader;
    }

public:
    ~this()
    {
        glDeleteProgram(mProgramID);
    }

    void compileShader(string source, int type)
    { 
        immutable uint shaderID = glCreateShader(type);
        enforce!GraphicsException(shaderID > 0, "Failed to allocate new shader.");

        scope (failure) if (shaderID > 0) glDeleteShader(shaderID);
        scope (success) mCompiledShaderIDs ~= shaderID;

        auto ptr = cast(const char*) source.ptr;
        auto ptrLength = cast(int) source.length;

        glShaderSource(shaderID, 1, &ptr, &ptrLength);
        glCompileShader(shaderID);

        int isCompiled;
        glGetShaderiv(shaderID, GL_COMPILE_STATUS, &isCompiled);

        int logLength;
        glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, &logLength);

        char[] log = new char[logLength];
        glGetShaderInfoLog(shaderID, logLength, &logLength, log.ptr);

        if (!isCompiled)
            throw new GraphicsException(log.idup);
        else if (logLength > 0)
            Logger.core.log(LogLevel.warning, log.idup);

        glAttachShader(mProgramID, shaderID);
    }

    void link()
    {
        scope (success)
        {
            foreach (uint id; mCompiledShaderIDs)
            {
                glDetachShader(mProgramID, id);
                glDeleteShader(id);
            }

            mCompiledShaderIDs.length = 0;
        }

        int isLinked, isValidated;

        glLinkProgram(mProgramID);
        glGetProgramiv(mProgramID, GL_LINK_STATUS, &isLinked);

        if (isLinked)
        {
            glValidateProgram(mProgramID);
            glGetProgramiv(mProgramID, GL_VALIDATE_STATUS, &isValidated);
        }

        int logLength;
        glGetProgramiv(mProgramID, GL_INFO_LOG_LENGTH, &logLength);
    	
        char[] log = new char[logLength];
        glGetProgramInfoLog(mProgramID, logLength, &logLength, log.ptr);

        if (!isLinked || !isValidated)
            throw new GraphicsException(log.idup);
        else if (logLength > 0)
            Logger.core.log(LogLevel.warning, log.idup);

        parseUniforms();

        Logger.core.log(LogLevel.debug_, "Shader linked successfully.");
    }

    void bind() const
    {
        if (sCurrentlyBoundShader != this)
        {
            glUseProgram(mProgramID);
            sCurrentlyBoundShader = this;
        }
    }

    size_t textureCount() pure const nothrow
    {
        return mTextureCount;
    }
}