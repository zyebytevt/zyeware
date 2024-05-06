// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.shader;

import std.string : toStringz;

import bindbc.opengl;

import zyeware;

package (zyeware.platform.opengl):

struct UniformLocationKey
{
    uint id;
    string name;
}

uint[UniformLocationKey] pUniformLocationCache;

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
        }

        uint shaderID = glCreateShader(shaderType);

        stringz sourcePtr = cast(char*) source.ptr;

        glShaderSource(shaderID, 1, &sourcePtr, null);
        glCompileShader(shaderID);

        int success;
        glGetShaderiv(shaderID, GL_COMPILE_STATUS, &success);

        if (!success)
        {
            char[2048] infoLog;
            GLsizei length;
            glGetShaderInfoLog(shaderID, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
            throw new GraphicsException(
                format!"Shader compilation failed: %s"(infoLog[0 .. length]));
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
        throw new GraphicsException(format!"Shader linking failed: %s"(infoLog[0 .. length]));
    }

    glValidateProgram(*id);
    glGetProgramiv(*id, GL_VALIDATE_STATUS, &success);

    if (!success)
    {
        char[2048] infoLog;
        GLsizei length;
        glGetProgramInfoLog(*id, cast(GLsizei) infoLog.length, &length, &infoLog[0]);
        throw new GraphicsException(format!"Shader validation failed: %s"(infoLog[0 .. length]));
    }

    return cast(NativeHandle) id;
}

void freeShader(NativeHandle shader) nothrow
{
    auto id = cast(uint*) shader;

    glDeleteProgram(*id);

    destroy(id);
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
    glUniform4f(prepareShaderUniformAssignAndGetLocation(shader, name),
        value.x, value.y, value.z, value.w);
}

void setShaderUniform1i(in NativeHandle shader, in string name, in int value) nothrow
{
    glUniform1i(prepareShaderUniformAssignAndGetLocation(shader, name), value);
}

void setShaderUniformMat4f(in NativeHandle shader, in string name, in mat4 value) nothrow
{
    glUniformMatrix4fv(prepareShaderUniformAssignAndGetLocation(shader, name),
        1, GL_TRUE, value.ptr);
}

void bindShader(in NativeHandle shader) nothrow
{
    glUseProgram(*(cast(uint*) shader));
}

private:

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