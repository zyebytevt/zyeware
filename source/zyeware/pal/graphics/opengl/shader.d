module zyeware.pal.graphicsDriver.opengl.shader;

import std.string : toStringz;
import std.exception : assumeWontThrow;

import bindbc.opengl;

import zyeware.common;
import zyeware.rendering;

private:

struct UniformLocationKey
{
    uint id;
    string name;
}

uint[UniformLocationKey] pUniformLocationCache;

uint palGlPrepareShaderUniformAssignAndGetLocation(in NativeHandle shader, string name) nothrow
{
    immutable uint id = *(cast(uint*) shader);
    glUseProgram(id);

    immutable auto key = UniformLocationKey(id, name);
    uint location = pUniformLocationCache.get(key, uint.max).assumeWontThrow;
    if (location == uint.max)
        pUniformLocationCache[key] = location = glGetUniformLocation(id, name.toStringz);

    return location;
}

package(zyeware.pal):

void palGlSetShaderUniform1f(in NativeHandle shader, in string name, in float value) nothrow
{
    glUniform1f(palGlPrepareShaderUniformAssignAndGetLocation(shader, name), value);
}

void palGlSetShaderUniform2f(in NativeHandle shader, in string name, in Vector2f value) nothrow
{
    glUniform2f(palGlPrepareShaderUniformAssignAndGetLocation(shader, name), value.x, value.y);
}

void palGlSetShaderUniform3f(in NativeHandle shader, in string name, in Vector3f value) nothrow
{
    glUniform3f(palGlPrepareShaderUniformAssignAndGetLocation(shader, name), value.x, value.y, value.z);
}

void palGlSetShaderUniform4f(in NativeHandle shader, in string name, in Vector4f value) nothrow
{
    glUniform4f(palGlPrepareShaderUniformAssignAndGetLocation(shader, name), value.x, value.y, value.z, value.w);
}

void palGlSetShaderUniform1i(in NativeHandle shader, in string name, in int value) nothrow
{
    glUniform1i(palGlPrepareShaderUniformAssignAndGetLocation(shader, name), value);
}

void palGlSetShaderUniformMat4f(in NativeHandle shader, in string name, in Matrix4f value) nothrow
{
    glUniformMatrix4fv(palGlPrepareShaderUniformAssignAndGetLocation(shader, name), 1, GL_TRUE, value.ptr);
}