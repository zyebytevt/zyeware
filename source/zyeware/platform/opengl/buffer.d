// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.buffer;

import std.typecons : Rebindable;
import std.algorithm : reduce;

import bindbc.opengl;

import zyeware;

package (zyeware.platform.opengl):

Rebindable!(const BufferLayout)[uint] pLayouts;

NativeHandle createIndexBuffer(size_t size, bool dynamic)
{
    auto id = new uint;

    glGenBuffers(1, id);
    enforce!GraphicsException(*id != 0, "Could not create index buffer.");

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size, null, dynamic ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW);

    return cast(NativeHandle) id;
}

NativeHandle createIndexBufferWithData(in uint[] indices, bool dynamic)
{
    auto id = new uint;

    glGenBuffers(1, id);
    enforce!GraphicsException(*id != 0, "Could not create index buffer.");

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * uint.sizeof,
        &indices[0], dynamic ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW);

    return cast(NativeHandle) id;
}

void updateIndexBufferData(NativeHandle buffer, in uint[] indices) nothrow
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *(cast(uint*) buffer));
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indices.length * uint.sizeof, &indices[0]);
}

void freeIndexBuffer(NativeHandle buffer) nothrow
{
    auto id = cast(uint*) buffer;

    glDeleteBuffers(1, id);

    destroy(id);
}

NativeHandle createDataBuffer(size_t size, in BufferLayout layout, bool dynamic)
{
    auto id = new uint;

    glGenBuffers(1, id);
    enforce!GraphicsException(*id != 0, "Could not create data buffer.");
    pLayouts[*id] = layout;

    glBindBuffer(GL_ARRAY_BUFFER, *id);
    glBufferData(GL_ARRAY_BUFFER, size, null, dynamic ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW);

    return cast(NativeHandle) id;
}

NativeHandle createDataBufferWithData(in void[] data, in BufferLayout layout, bool dynamic)
{
    auto id = new uint;

    glGenBuffers(1, id);
    enforce!GraphicsException(*id != 0, "Could not create data buffer.");
    pLayouts[*id] = layout;

    glBindBuffer(GL_ARRAY_BUFFER, *id);
    glBufferData(GL_ARRAY_BUFFER, data.length, &data[0], dynamic ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW);

    return cast(NativeHandle) id;
}

void updateDataBufferData(NativeHandle buffer, in void[] data) nothrow
{
    glBindBuffer(GL_ARRAY_BUFFER, *(cast(uint*) buffer));
    glBufferSubData(GL_ARRAY_BUFFER, 0, data.length, &data[0]);
}

void freeDataBuffer(NativeHandle buffer) nothrow
{
    auto id = cast(uint*) buffer;

    pLayouts.remove(*id);
    glDeleteBuffers(1, id);

    destroy(id);
}

NativeHandle createBufferGroup()
{
    auto id = new uint;

    glGenVertexArrays(1, id);
    enforce!GraphicsException(*id != 0, "Could not create buffer group.");
    glBindVertexArray(0);

    return cast(NativeHandle) id;
}

void setBufferGroupDataBuffer(NativeHandle group, in NativeHandle buffer) nothrow
{
    glBindVertexArray(*(cast(uint*) group));

    immutable uint bufferId = *(cast(uint*) buffer);
    glBindBuffer(GL_ARRAY_BUFFER, bufferId);

    auto layout = bufferId in pLayouts;
    if (!layout)
        return;

    immutable uint stride = reduce!((a, b) => a + b.amount * getTypeSize(b.type))(0, layout.elements);
    uint index;
    uint offset;
    
    foreach (ref const BufferElement element; layout.elements)
    {
        immutable uint elementCount = getElementCount(element.type);

        glEnableVertexAttribArray(index);
        glVertexAttribPointer(index, elementCount, getType(element.type), element.normalized,
            stride, cast(void*) offset);

        if (element.divisor > 0)
            glVertexAttribDivisor(index, element.divisor);

        ++index;
        offset += element.amount * getTypeSize(element.type);
    }

    glBindVertexArray(0);
}

void setBufferGroupIndexBuffer(NativeHandle group, in NativeHandle buffer) nothrow
{
    glBindVertexArray(*(cast(uint*) group));
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *(cast(uint*) buffer));
    glBindVertexArray(0);
}

void bindBufferGroup(NativeHandle group) nothrow
{
    glBindVertexArray(*(cast(uint*) group));
}

void freeBufferGroup(NativeHandle group) nothrow
{
    auto id = cast(uint*) group;

    glDeleteVertexArrays(1, id);

    destroy(id);
}

private:

static GLenum getType(BufferElement.Type type) pure nothrow
{
    final switch (type) with (BufferElement.Type)
    {
    case none: return 0;
    case vec2: return GL_FLOAT;
    case vec3: return GL_FLOAT;
    case vec4: return GL_FLOAT;
    case mat3: return GL_FLOAT;
    case mat4: return GL_FLOAT;
    case float_: return GL_FLOAT;
    case int_: return GL_INT;
    case bool_: return GL_BOOL;
    }
}

static uint getElementCount(BufferElement.Type type) pure nothrow
{
    final switch (type) with (BufferElement.Type)
    {
    case none: return 0;
    case vec2: return 2;
    case vec3: return 3;
    case vec4: return 4;
    case mat3: return 3 * 3;
    case mat4: return 4 * 4;
    case float_: return 1;
    case int_: return 1;
    case bool_: return 1;
    }
}

static uint getTypeSize(BufferElement.Type type) pure nothrow
{
    final switch (type) with (BufferElement.Type)
    {
    case none: return 1;
    case vec2: return float.sizeof * 2;
    case vec3: return float.sizeof * 3;
    case vec4: return float.sizeof * 4;
    case mat3: return float.sizeof * 3 * 3;
    case mat4: return float.sizeof * 4 * 4;
    case float_: return float.sizeof;
    case int_: return int.sizeof;
    case bool_: return 1;
    }
}