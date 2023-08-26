// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.buffer;

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;

/// Represents an element in a tightly-bound data buffer.
struct BufferElement
{
private:
    string mName;
    Type mType;
    uint mSize;
    uint mOffset;
    bool mNormalized;
    uint mDivisor;
    uint mAmount;

    static uint getTypeSize(Type type) pure nothrow
    {
        final switch (type) with (Type)
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
    this(string name, Type type, uint amount = 1, Flag!"normalized" normalized = No.normalized, uint divisor = 0)
    {
        mName = name;
        mType = type;
        mNormalized = normalized;
        mSize = elementSize * amount;
        mAmount = amount;
        mDivisor = divisor;
    }

    /// The name of the buffer element.
    string name() pure const nothrow
    {
        return mName;
    }

    /// The type of the buffer element.
    Type type() pure const nothrow
    {
        return mType;
    }

    /// The size of the buffer element in bytes.
    uint size() pure const nothrow
    {
        return mSize;
    }

    /// The amount of individual elements of this buffer element.
    uint amount() pure const nothrow
    {
        return mAmount;
    }

    /// The size of an individual element of this buffer element, in bytes.
    uint elementSize() pure const nothrow
    {
        return getTypeSize(mType);
    }

    /// Offset of this buffer element inside the buffer.
    uint offset() pure const nothrow
    {
        return mOffset;
    }

    /// If the values of this buffer element are normalized.
    bool normalized() pure const nothrow
    {
        return mNormalized;
    }

    /// The divisor of this element.
    uint divisor() pure const nothrow
    {
        return mDivisor;
    }
}

/// Represents a layout of a tightly-bound data buffer.
struct BufferLayout
{
private:
    BufferElement[] mElements;
    uint mStride;

    void calculateOffsetAndStride() pure nothrow
    {
        mStride = 0;

        foreach (ref BufferElement element; mElements)
        {
            element.mOffset = mStride;
            mStride += element.size;
        }
    }

public:
    /// Params:
    ///     elements = The elements of one instance.
    this(BufferElement[] elements)
    {
        mElements = elements;
        calculateOffsetAndStride();
    }

    /// How many bytes one instance uses.
    uint stride() pure const nothrow
    {
        return mStride;
    }

    /// The elements of one instance.
    inout(BufferElement[]) elements() pure inout nothrow
    {
        return mElements;
    }
}

/// A buffer group represents a data buffer and an index buffer combined.
///
/// See_Also: DataBuffer, IndexBuffer.
interface BufferGroup
{
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

    static BufferGroup create()
    {
        return GraphicsAPI.sCreateBufferGroupImpl();
    }
}

interface DataBuffer
{
    void bind() const nothrow;

    void setData(const void[] data);

    size_t length() const nothrow;

    void layout(BufferLayout layout) nothrow;
    const(BufferLayout) layout() const nothrow;

    static DataBuffer create(size_t size, BufferLayout layout, Flag!"dynamic" dynamic)
    {
        return GraphicsAPI.sCreateDataBufferImpl(size, layout, dynamic);
    }

    static DataBuffer create(const void[] data, BufferLayout layout, Flag!"dynamic" dynamic)
    {
        return GraphicsAPI.sCreateDataBufferWithDataImpl(data, layout, dynamic);
    }
}

interface IndexBuffer
{
    void bind() const nothrow;

    void setData(const uint[] indices);

    size_t length() const nothrow;

    static IndexBuffer create(size_t size, Flag!"dynamic" dynamic)
    {
        return GraphicsAPI.sCreateIndexBufferImpl(size, dynamic);
    }

    static IndexBuffer create(const uint[] indices, Flag!"dynamic" dynamic)
    {
        return GraphicsAPI.sCreateIndexBufferWithDataImpl(indices, dynamic);
    }
}

interface ConstantBuffer
{
    enum Slot
    {
        matrices,
        environment,
        lights,
        modelVariables
    }

    void bind(Slot slot) const nothrow;
    
    size_t getEntryOffset(string name) const nothrow;

    void setData(size_t offset, in void[] data) nothrow;

    size_t length() const nothrow;
    const(string[]) entries() const nothrow;

    static ConstantBuffer create(in BufferLayout layout)
    {
        return GraphicsAPI.sCreateConstantBufferImpl(layout);
    }
}