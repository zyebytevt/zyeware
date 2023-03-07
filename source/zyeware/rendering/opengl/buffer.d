// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.opengl.buffer;

version (ZW_OpenGL):
package(zyeware.rendering.opengl):

import std.exception : enforce, assumeWontThrow;
import std.typecons : Rebindable;

import inmath.linalg;
import bindbc.opengl;

import zyeware.common;
import zyeware.rendering;

// OpenGL implements BufferGroup as VertexArray
class OGLBufferGroup : BufferGroup
{
protected:
    uint mVertexArrayID;
    DataBuffer mDataBuffer;
    IndexBuffer mIndexBuffer;

package(zyeware.rendering.opengl):
    this()
    {
        glGenVertexArrays(1, &mVertexArrayID);
        enforce!GraphicsException(mVertexArrayID != 0, "Failed to create OpenGL vertex array!");

        glBindVertexArray(0);
    }
    
    static BufferGroup create()
    {
        return new OGLBufferGroup();
    }

public:
    ~this()
    {
        glDeleteVertexArrays(1, &mVertexArrayID);
    }

    void bind() const nothrow
    {
        glBindVertexArray(mVertexArrayID);
    }

    void dataBuffer(DataBuffer buffer) nothrow
        in (buffer.layout.elements.length > 0, "No elements in buffer layout!")
    {
        mDataBuffer = buffer;
        bind();
        buffer.bind();

        uint index;
        foreach (ref const BufferElement element; buffer.layout.elements)
        {
            glEnableVertexAttribArray(index);
            glVertexAttribPointer(index,
                getElementCount(element.type),
                getOpenGLType(element.type),
                element.normalized,
                buffer.layout.stride,
                cast(const void*) element.offset);

            if (element.divisor > 0)
                glVertexAttribDivisor(index, element.divisor);

            ++index;
        }

        glBindVertexArray(0);
    }

    inout(DataBuffer) dataBuffer() inout nothrow
    {
        return mDataBuffer;
    }

    void indexBuffer(IndexBuffer buffer) nothrow
    {
        mIndexBuffer = buffer;
        bind();
        buffer.bind();

        glBindVertexArray(0);
    }

    inout(IndexBuffer) indexBuffer() inout nothrow
    {
        return mIndexBuffer;
    }
}



class OGLDataBuffer : DataBuffer
{
protected:
    uint mBufferID;
    bool mDynamic;
    BufferLayout mLayout;
    size_t mLength;
    bool mInitialized;

package(zyeware.rendering.opengl):
    this(size_t size, BufferLayout layout, bool dynamic)
    {
        glGenBuffers(1, &mBufferID);
        enforce!GraphicsException(mBufferID != 0, "Failed to create OpenGL vertex buffer!");

        mLayout = layout;
        mLength = size;
        mDynamic = dynamic;
    }

    this(const void[] data, BufferLayout layout, bool dynamic)
    {
        glGenBuffers(1, &mBufferID);
        enforce!GraphicsException(mBufferID != 0, "Failed to create OpenGL vertex buffer!");

        mLayout = layout;
        mLength = data.length;
        mDynamic = dynamic;

        setData(data);
    }
    
    static DataBuffer create(size_t size, BufferLayout layout, bool dynamic)
    {
        return new OGLDataBuffer(size, layout, dynamic);
    }

    static DataBuffer createWithData(const void[] data, BufferLayout layout, bool dynamic)
    {
        return new OGLDataBuffer(data, layout, dynamic);
    }

public:
    ~this()
    {
        glDeleteBuffers(1, &mBufferID);
    }

    void bind() const nothrow
    {
        glBindBuffer(GL_ARRAY_BUFFER, mBufferID);
    }

    void setData(const void[] data)
        in (data.length <= mLength, "Too much data for buffer size.")
    {   
        glBindBuffer(GL_ARRAY_BUFFER, mBufferID);

        if (!mInitialized)
        {
            glBufferData(GL_ARRAY_BUFFER, cast(GLintptr) data.length, data.ptr, mDynamic ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW);
            mInitialized = true;
        }
        else
            glBufferSubData(GL_ARRAY_BUFFER, cast(GLintptr) 0, data.length, data.ptr);
    }

    size_t length() const nothrow
    {
        return mLength;
    }

    void layout(BufferLayout layout) nothrow
    {
        mLayout = layout;
    }

    const(BufferLayout) layout() const nothrow
    {
        return mLayout;
    }
}



class OGLIndexBuffer : IndexBuffer
{
protected:
    uint mBufferID;
    size_t mLength;
    bool mDynamic;
    bool mInitialized;

package(zyeware.rendering.opengl):
    this(size_t size, bool dynamic)
    {
        glGenBuffers(1, &mBufferID);
        enforce!GraphicsException(mBufferID != 0, "Failed to create OpenGL index buffer!");

        mLength = size;
        mDynamic = dynamic;
    }

    this(const uint[] indices, bool dynamic)
    {
        glGenBuffers(1, &mBufferID);
        enforce!GraphicsException(mBufferID != 0, "Failed to create OpenGL index buffer!");

        mLength = indices.length;
        mDynamic = dynamic;

        setData(indices);
    }

    static IndexBuffer create(size_t size, bool dynamic)
    {
        return new OGLIndexBuffer(size, dynamic);
    }

    static IndexBuffer createWithData(const uint[] indices, bool dynamic)
    {
        return new OGLIndexBuffer(indices, dynamic);
    }

public:
    ~this()
    {
        glDeleteBuffers(1, &mBufferID);
    }

    void bind() const nothrow
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mBufferID);
    }

    void setData(const uint[] indices)
        in (indices.length <= mLength, "Too much data for buffer size.")
    {   
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mBufferID);

        if (!mInitialized)
        {
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, cast(GLintptr) indices.length * uint.sizeof, indices.ptr,
                mDynamic ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW);
            mInitialized = true;
        }
        else
            glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, cast(GLintptr) 0, indices.length * uint.sizeof, indices.ptr);
    }

    size_t length() const nothrow
    {
        return mLength;
    }
}



class OGLConstantBuffer : ConstantBuffer
{
protected:
    uint mBufferID;
    size_t mLength;
    GLintptr[string] mConstantsOffsets;

    final void parseLayout(in BufferLayout layout)
    {
        GLintptr offset = 0;

        foreach (const ref BufferElement element; layout.elements)
        {
            offset += (offset % getStd140Alignment(element.type));
            mConstantsOffsets[element.name] = offset;
            offset += element.size;
        }

        mLength = offset;
    }

package(zyeware.rendering.opengl):
    this(in BufferLayout layout)
    {
        glGenBuffers(1, &mBufferID);
        enforce!GraphicsException(mBufferID != 0, "Failed to create OpenGL constant buffer!");

        parseLayout(layout);

        glBindBuffer(GL_UNIFORM_BUFFER, mBufferID);
        glBufferData(GL_UNIFORM_BUFFER, mLength, null, GL_DYNAMIC_DRAW);
    }

    static ConstantBuffer create(in BufferLayout layout)
    {
        return new OGLConstantBuffer(layout);
    }

public:
    ~this()
    {
        glDeleteBuffers(1, &mBufferID);
    }

    void bind(Slot slot) const nothrow
    {
        glBindBufferBase(GL_UNIFORM_BUFFER, slot, mBufferID);
    }

    size_t getEntryOffset(string name) const nothrow
    {
        return cast(size_t) mConstantsOffsets.get(name, -1).assumeWontThrow;
    }

    void setData(size_t offset, in void[] data) nothrow
        in (offset < mLength, "Offset beyond buffer length.")
    {
        glBindBuffer(GL_UNIFORM_BUFFER, mBufferID);
        glBufferSubData(GL_UNIFORM_BUFFER, offset, data.length, data.ptr);
    }

    size_t length() const nothrow
    {
        return mLength;
    }

    const(string[]) entries() const nothrow
    {
        return mConstantsOffsets.keys;
    }
}


private:

GLenum getOpenGLType(BufferElement.Type type) pure nothrow
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

uint getElementCount(BufferElement.Type type) pure nothrow
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

uint getStd140Alignment(BufferElement.Type type) pure nothrow
{
    final switch (type) with (BufferElement.Type)
    {
    case none: return 1;
    case vec2: return 16;
    case vec3: return 16;
    case vec4: return 16;
    case mat3: return 64;
    case mat4: return 64;
    case float_: return 4;
    case int_: return 4;
    case bool_: return 4;
    }
}