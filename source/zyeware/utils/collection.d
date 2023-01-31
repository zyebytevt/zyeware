// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.utils.collection;

import std.traits : hasIndirections, isDynamicArray;
import std.algorithm : countUntil, remove;

/// A growable circular queue represents a FIFO collection that,
/// except if it needs to grow, doesn't allocate and free memory
/// with each push and pop.
struct GrowableCircularQueue(T)
{
private:
    size_t mLength;
    size_t mFirst, mLast;
    T[] mArray = [T.init];

public:
    /// Params:
    ///   items = The items to initialise this queue with.
    this(T[] items...) pure nothrow
    {
        foreach (x; items)
            push(x);
    }

    /// Whether the collection is empty.
    bool empty() pure const nothrow
    {
        return mLength == 0;
    }

    /// Returns the front element of the queue.
    inout(T) front() pure inout nothrow
        in (mLength != 0, "Cannot get front, is empty.")
    {
        return mArray[mFirst];
    }

    /// Returns the n-th element of the queue, starting from 0.
    inout(T) opIndex(in size_t i) pure inout nothrow
        in (i < mLength, "OpIndex out of bounds!")
    {
        return mArray[(mFirst + i) & (mArray.mLength - 1)];
    }

    /// Pushes an item into the queue. Can cause a growth and allocation
    /// if there is not enough space.
    /// Params:
    ///   item = The item to push into the queue.
    void push(T item) pure nothrow
    {
        if (mLength >= mArray.mLength)
        { // Double the queue.
            immutable oldALen = mArray.mLength;
            mArray.mLength *= 2;
            if (mLast < mFirst)
            {
                mArray[oldALen .. oldALen + mLast + 1] = mArray[0 .. mLast + 1];
                static if (hasIndirections!T)
                    mArray[0 .. mLast + 1] = T.init; // Help for the GC.
                mLast += oldALen;
            }
        }

        mLast = (mLast + 1) & (mArray.mLength - 1);
        mArray[mLast] = item;
        mLength++;
    }

    /// Pops the front-most item from the queue.
    T pop() pure nothrow
        in (mLength != 0, "Cannot pop from queue, is empty.")
    {
        auto saved = mArray[mFirst];
        static if (hasIndirections!T)
            mArray[mFirst] = T.init; // Help for the GC.
        mFirst = (mFirst + 1) & (mArray.mLength - 1);
        mLength--;
        return saved;
    }

    /// The length of the queue.
    size_t length() pure const nothrow
    {
        return mLength;
    }
}

struct GrowableStack(T)
{
private:
    size_t mNextPointer;
    T[] mArray;

public:
    this(size_t initialSize) pure nothrow
    {
        mArray.length = initialSize;
    }

    bool empty() pure const nothrow
    {
        return mNextPointer == 0;
    }

    inout(T) peek() pure inout nothrow
        in (mNextPointer > 0, "Cannot peek on stack, is empty.")
    {
        return mArray[mNextPointer - 1];
    }

    inout(T) opIndex(size_t i) pure inout nothrow
        in (i < mNextPointer, "OpIndex out of bounds!")
    {
        return mArray[i];
    }

    void push(T item) pure nothrow
    {
        if (mNextPointer == mArray.length)
        {
            if (mArray.length == 0)
                mArray.length = 8;
            else
                mArray.length *= 2;
        }

        mArray[mNextPointer++] = item;
    }

    T pop() pure nothrow
        in (mNextPointer > 0, "Cannot pop from stack, is empty.")
    {
        auto saved = mArray[mNextPointer - 1];
        static if (hasIndirections!T)
            mArray[mNextPointer - 1] = T.init;
        --mNextPointer;
        return saved;
    }

    size_t mLength() pure const nothrow
    {
        return mNextPointer;
    }

    void mLength(size_t value) pure nothrow
    {
        mNextPointer = value;
        static if (hasIndirections!T)
            mArray[value + 1 .. $] = T.init;
    }
}

auto removeElement(R, N)(R haystack, N needle)
    if (isDynamicArray!R)
{
    auto index = haystack.countUntil(needle);
    return (index != -1) ? haystack.remove(index) : haystack;
}