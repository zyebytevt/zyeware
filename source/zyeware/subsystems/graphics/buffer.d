// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.buffer;

import zyeware;

package(zyeware):

/// Represents an element in a tightly-bound data buffer.
struct BufferElement
{
private:
    Type mType;
    bool mNormalized;
    uint mDivisor;
    uint mAmount;

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
    ///     type = The type of the element.
    ///     normalized = If this element is normalized. Only effective on vectors.
    ///     divisor = The divisor of this element.
    this(Type type, uint amount = 1, Flag!"normalized" normalized = No.normalized, uint divisor = 0)
    {
        mType = type;
        mNormalized = normalized;
        mAmount = amount;
        mDivisor = divisor;
    }

    /// The type of the buffer element.
    Type type() pure const nothrow => mType;

    /// The amount of individual elements of this buffer element.
    uint amount() pure const nothrow => mAmount;

    /// If the values of this buffer element are normalized.
    bool normalized() pure const nothrow => mNormalized;

    /// The divisor of this element.
    uint divisor() pure const nothrow => mDivisor;
}

/// Represents a layout of a tightly-bound data buffer.
struct BufferLayout
{
private:
    BufferElement[] mElements;

public:
    /// Params:
    ///     elements = The elements of one instance.
    this(BufferElement[] elements)
    {
        mElements = elements;
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
final class BufferGroup
{
private:
    NativeHandle mNativeHandle;
    DataBuffer mDataBuffer;
    IndexBuffer mIndexBuffer;

public:
    this()
    {
        mNativeHandle = GraphicsSubsystem.callbacks.createBufferGroup();
    }

    ~this() nothrow
    {
        GraphicsSubsystem.callbacks.freeBufferGroup(mNativeHandle);
    }

    /// The data buffer of this buffer group.
    DataBuffer dataBuffer(DataBuffer buffer) nothrow
    in (buffer, "Invalid data buffer.")
    {
        mDataBuffer = buffer;
        GraphicsSubsystem.callbacks.setBufferGroupDataBuffer(mNativeHandle, buffer.handle);
        return buffer;
    }

    /// ditto
    inout(DataBuffer) dataBuffer() inout nothrow => mDataBuffer;

    /// The index buffer of this buffer group.
    IndexBuffer indexBuffer(IndexBuffer buffer) nothrow
    in (buffer, "Invalid index buffer.")
    {
        mIndexBuffer = buffer;
        GraphicsSubsystem.callbacks.setBufferGroupIndexBuffer(mNativeHandle, buffer.handle);
        return buffer;
    }

    void bind() nothrow
    {
        GraphicsSubsystem.callbacks.bindBufferGroup(mNativeHandle);
    }

    /// ditto
    inout(IndexBuffer) indexBuffer() inout nothrow => mIndexBuffer;
}

final class DataBuffer : NativeObject
{
private:
    NativeHandle mNativeHandle;
    const BufferLayout mLayout;

public:
    this(size_t size, in BufferLayout layout, Flag!"dynamic" dynamic)
    {
        mNativeHandle = GraphicsSubsystem.callbacks.createDataBuffer(size, layout, dynamic);
        mLayout = layout;
    }

    this(in void[] data, in BufferLayout layout, Flag!"dynamic" dynamic)
    {
        mNativeHandle = GraphicsSubsystem.callbacks.createDataBufferWithData(data, layout, dynamic);
        mLayout = layout;
    }

    ~this() nothrow
    {
        GraphicsSubsystem.callbacks.freeDataBuffer(mNativeHandle);
    }

    void updateData(in void[] data)
    {
        GraphicsSubsystem.callbacks.updateDataBufferData(mNativeHandle, data);
    }

    const(BufferLayout) layout() const nothrow => mLayout;

    const(NativeHandle) handle() pure const nothrow => mNativeHandle;
}

final class IndexBuffer : NativeObject
{
private:
    NativeHandle mNativeHandle;

public:
    this(size_t size, Flag!"dynamic" dynamic)
    {
        mNativeHandle = GraphicsSubsystem.callbacks.createIndexBuffer(size, dynamic);
    }

    this(in uint[] indices, Flag!"dynamic" dynamic)
    {
        mNativeHandle = GraphicsSubsystem.callbacks.createIndexBufferWithData(indices, dynamic);
    }

    ~this()
    {
        GraphicsSubsystem.callbacks.freeIndexBuffer(mNativeHandle);
    }

    void updateData(in uint[] indices)
    {
        GraphicsSubsystem.callbacks.updateIndexBufferData(mNativeHandle, indices);
    }

    const(NativeHandle) handle() pure const nothrow => mNativeHandle;
}