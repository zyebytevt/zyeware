// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.utils.collection;

import std.traits : hasIndirections, isDynamicArray;
import std.algorithm : countUntil, remove;

struct GrowableCircularQueue(T)
{
private:
    size_t mFirst, mLast;
    T[] mArray = [T.init];

public:
    size_t length;

    this(T[] items...) pure nothrow
    {
        foreach (x; items)
            push(x);
    }

    bool empty() pure const nothrow
    {
        return length == 0;
    }

    inout(T) front() pure inout nothrow
        in (length != 0, "Cannot get front, is empty.")
    {
        return mArray[mFirst];
    }

    inout(T) opIndex(in size_t i) pure inout nothrow
        in (i < length, "OpIndex out of bounds!")
    {
        return mArray[(mFirst + i) & (mArray.length - 1)];
    }

    void push(T item) pure nothrow
    {
        if (length >= mArray.length)
        { // Double the queue.
            immutable oldALen = mArray.length;
            mArray.length *= 2;
            if (mLast < mFirst)
            {
                mArray[oldALen .. oldALen + mLast + 1] = mArray[0 .. mLast + 1];
                static if (hasIndirections!T)
                    mArray[0 .. mLast + 1] = T.init; // Help for the GC.
                mLast += oldALen;
            }
        }

        mLast = (mLast + 1) & (mArray.length - 1);
        mArray[mLast] = item;
        length++;
    }

    T pop() pure nothrow
        in (length != 0, "Cannot pop from queue, is empty.")
    {
        auto saved = mArray[mFirst];
        static if (hasIndirections!T)
            mArray[mFirst] = T.init; // Help for the GC.
        mFirst = (mFirst + 1) & (mArray.length - 1);
        length--;
        return saved;
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
            mArray[mNextPointer] = T.init;
        --mNextPointer;
        return saved;
    }

    size_t length() pure const nothrow
    {
        return mNextPointer;
    }

    void length(size_t value) pure nothrow
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