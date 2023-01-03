// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.buffer;

import inmath.linalg;

import zyeware.common;

/// Represents an element in a tightly-bound data buffer.
struct BufferElement
{
public:
    /// The type of the element.
    enum Type : ubyte
    {
        none,
        vec2, vec3, vec4,
        mat3, mat4,
        float_, int_, bool_
    }

    /// Params:
    ///     name = The name of the element. Used for debugging purposes.
    ///     type = The type of the element.
    ///     normalized = If this element is normalized. Only effective on vectors.
    ///     divisor = The divisor of this element.
    this(string name, Type type, uint amount = 1, Flag!"normalized" normalized = No.normalized, uint divisor = 0);

    string name() pure const nothrow;
    Type type() pure const nothrow;
    uint size() pure const nothrow;
    uint amount() pure const nothrow;
    uint elementSize() pure const nothrow;
    uint offset() pure const nothrow;
    bool normalized() pure const nothrow;
    uint divisor() pure const nothrow;
}

/// Represents a layout of a tightly-bound data buffer.
struct BufferLayout
{
public:
    /// Params:
    ///     elements = The elements of one instance.
    this(BufferElement[] elements);

    /// How many bytes one instance uses.
    uint stride() pure const nothrow;

    /// The elements of one instance.
    inout(BufferElement[]) elements() pure inout nothrow;
}

/// A buffer group represents a data buffer and an index buffer combined.
///
/// See_Also: DataBuffer, IndexBuffer.
class BufferGroup
{
public:
    this();

    /// Binds this buffer group (therefore the data and index buffers) for further use.
    void bind() const nothrow;

    /// The data buffer of this buffer group.
    void dataBuffer(DataBuffer buffer) nothrow;
    /// ditto
    inout(DataBuffer) dataBuffer() inout nothrow;

    /// The index buffer of this buffer group.
    void indexBuffer(IndexBuffer buffer) nothrow;
    /// ditto
    inout(IndexBuffer) indexBuffer() inout nothrow;
}

class DataBuffer
{
public:
    this(size_t size, BufferLayout layout, Flag!"dynamic" dynamic);
    this(const void[] data, BufferLayout layout, Flag!"dynamic" dynamic);

    void bind() const nothrow;

    void setData(const void[] data);

    size_t length() const nothrow;

    void layout(BufferLayout layout) nothrow;
    const(BufferLayout) layout() const nothrow;
}

class IndexBuffer
{
public:
    this(size_t size, Flag!"dynamic" dynamic);
    this(const uint[] indices, Flag!"dynamic" dynamic);

    void bind() const nothrow;

    void setData(const uint[] indices);

    size_t length() const nothrow;
}

class ConstantBuffer
{
    enum Slot
    {
        matrices,
        environment,
        lights,
        modelVariables
    }

    this(in BufferLayout layout);

    void bind(Slot slot) const nothrow;
    
    size_t getEntryOffset(string name) const nothrow;

    void setData(size_t offset, in void[] data) nothrow;

    size_t length() const nothrow;
    const(string[]) entries() const nothrow;
}