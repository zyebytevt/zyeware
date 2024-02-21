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
struct GrowableCircularQueue(T) {
private:
    size_t mLength;
    size_t mFirst, mLast;
    T[] mArray = [T.init];

public:
    /// Params:
    ///   items = The items to initialise this queue with.
    this(T[] items...) pure nothrow {
        foreach (x; items)
            push(x);
    }

    /// Whether the collection is empty.
    bool empty() pure const nothrow {
        return mLength == 0;
    }

    /// Returns the front element of the queue.
    inout(T) front() pure inout nothrow
    in (mLength != 0, "Cannot get front, is empty.") {
        return mArray[mFirst];
    }

    /// Returns the n-th element of the queue, starting from 0.
    inout(T) opIndex(in size_t i) pure inout nothrow
    in (i < mLength, "OpIndex out of bounds!") {
        return mArray[(mFirst + i) & (mArray.length - 1)];
    }

    /// Pushes an item into the queue. Can cause a growth and allocation
    /// if there is not enough space.
    /// Params:
    ///   item = The item to push into the queue.
    void push(T item) pure nothrow {
        if (mLength >= mArray.length) { // Double the queue.
            immutable oldALen = mArray.length;
            mArray.length *= 2;
            if (mLast < mFirst) {
                mArray[oldALen .. oldALen + mLast + 1] = mArray[0 .. mLast + 1];
                static if (hasIndirections!T)
                    mArray[0 .. mLast + 1] = T.init; // Help for the GC.
                mLast += oldALen;
            }
        }

        mLast = (mLast + 1) & (mArray.length - 1);
        mArray[mLast] = item;
        mLength++;
    }

    /// Pops the front-most item from the queue.
    T pop() pure nothrow
    in (mLength != 0, "Cannot pop from queue, is empty.") {
        auto saved = mArray[mFirst];
        static if (hasIndirections!T)
            mArray[mFirst] = T.init; // Help for the GC.
        mFirst = (mFirst + 1) & (mArray.length - 1);
        mLength--;
        return saved;
    }

    /// The length of the queue.
    size_t length() pure const nothrow {
        return mLength;
    }
}

@("GrowableCircularQueue")
unittest {
    import unit_threaded.assertions;

    auto queue = GrowableCircularQueue!int([1, 2, 3, 4, 5]);

    queue.length.should == 5;
    queue.empty.should == false;

    queue.front.should == 1;
    queue[2].should == 3;

    queue.push(6);
    queue.length.should == 6;
    queue[5].should == 6;

    queue.pop.should == 1;
    queue.length.should == 5;
    queue.front.should == 2;
}

struct GrowableStack(T) {
private:
    size_t mNextPointer;
    T[] mArray;

public:
    this(size_t initialSize) pure nothrow {
        mArray.length = initialSize;
    }

    bool empty() pure const nothrow {
        return mNextPointer == 0;
    }

    inout(T) peek() pure inout nothrow
    in (mNextPointer > 0, "Cannot peek on stack, is empty.") {
        return mArray[mNextPointer - 1];
    }

    inout(T) opIndex(size_t i) pure inout nothrow
    in (i < mNextPointer, "OpIndex out of bounds!") {
        return mArray[i];
    }

    void push(T item) pure nothrow {
        if (mNextPointer == mArray.length) {
            if (mArray.length == 0)
                mArray.length = 8;
            else
                mArray.length *= 2;
        }

        mArray[mNextPointer++] = item;
    }

    T pop() pure nothrow
    in (mNextPointer > 0, "Cannot pop from stack, is empty.") {
        auto saved = mArray[mNextPointer - 1];
        static if (hasIndirections!T)
            mArray[mNextPointer - 1] = T.init;
        --mNextPointer;
        return saved;
    }

    size_t length() pure const nothrow {
        return mNextPointer;
    }

    void length(size_t value) pure nothrow {
        mNextPointer = value;
        static if (hasIndirections!T)
            mArray[value + 1 .. $] = T.init;
    }
}

@("GrowableStack")
unittest {
    import unit_threaded.assertions;

    auto stack = GrowableStack!int(5);

    stack.length.should == 0;
    stack.empty.should == true;

    stack.push(1);
    stack.length.should == 1;
    stack.peek.should == 1;

    stack.push(2);
    stack.length.should == 2;
    stack.peek.should == 2;

    stack.pop.should == 2;
    stack.length.should == 1;
    stack.peek.should == 1;

    stack.pop.should == 1;
    stack.length.should == 0;
    stack.empty.should == true;
}
