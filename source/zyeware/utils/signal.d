module zyeware.utils.signal;

import std.algorithm : remove;

import zyeware;

struct Signal(T1...)
{
private:
    alias delegate_t = void delegate(T1) nothrow;
    alias function_t = void function(T1) nothrow;

    struct Slot
    {
        union
        {
            delegate_t dg;
            function_t fn;
        }

        bool isDelegate;
        bool isOneShot;
    }

    Slot[] mSlots;

    ptrdiff_t findSlot(delegate_t dg) @trusted pure nothrow
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];

            if (c.isDelegate && c.dg is dg)
                return i;
        }

        return -1;
    }

    ptrdiff_t findSlot(function_t fn) @trusted pure nothrow
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];

            if (!c.isDelegate && c.fn is fn)
                return i;
        }

        return -1;
    }

public:
    void connect(delegate_t dg, Flag!"oneShot" oneShot = No.oneShot) @trusted pure
    {
        enforce!CoreException(dg, "Delegate cannot be null.");
        enforce!CoreException(findSlot(dg) == -1, "Delegate already connected.");

        Slot c;
        c.dg = dg;
        c.isDelegate = true;
        c.isOneShot = oneShot;
        mSlots ~= c;
    }

    void connect(function_t fn, Flag!"oneShot" oneShot = No.oneShot) @trusted pure
    {
        enforce!CoreException(fn, "Function cannot be null.");
        enforce!CoreException(findSlot(fn) == -1, "Function already connected.");
        
        Slot c;
        c.fn = fn;
        c.isDelegate = false;
        c.isOneShot = oneShot;
        mSlots ~= c;
    }

    void disconnect(delegate_t dg) @trusted pure nothrow
    {
        immutable idx = findSlot(dg);
        if (idx >= 0)
            mSlots = mSlots.remove(idx);
    }

    void disconnect(function_t fn) @trusted pure nothrow
    {
        immutable idx = findSlot(fn);
        if (idx >= 0)
            mSlots = mSlots.remove(idx);
    }

    void disconnectAll() @safe pure nothrow
    {
        mSlots = [];
    }

    void emit(T1 args) nothrow
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];

            if (c.isDelegate)
                c.dg(args);
            else
                c.fn(args);

            if (c.isOneShot)
                mSlots = mSlots.remove(i--);
        }
    }

    pragma(inline, true)
    {
        void opCall(T1 args) => emit(args);
        void opOpAssign(string op)(delegate_t dg) if (op == "~") => connect(dg);
        void opOpAssign(string op)(function_t fn) if (op == "~") => connect(fn);
        void opOpAssign(string op)(delegate_t dg) if (op == "-") => disconnect(dg);
        void opOpAssign(string op)(function_t fn) if (op == "-") => disconnect(fn);
    }
}

@("Signals")
unittest
{
    import unit_threaded.assertions;

    // Create a Signal
    Signal!int signal;

    int result;

    // Connect a delegate
    void delegate(int x) nothrow delegate1 = (x) {
        result = x;
    };

    void function(int x) nothrow function1 = (x) { };

    signal.connect(delegate1);
    signal.mSlots.length.should == 1;

    signal.connect(function1);
    signal.mSlots.length.should == 2;

    // Emit the signal
    signal.emit(20);
    result.should == 20;

    // Disconnect the delegate
    signal.disconnect(delegate1);
    signal.mSlots.length.should == 1;

    // Disconnect the function
    signal.disconnect(function1);
    signal.mSlots.length.should == 0;

    // Connect the delegate and function again
    signal.connect(delegate1);
    signal.connect(function1);
    signal.mSlots.length.should == 2;

    // Reconnecting same delegate and function should throw
    signal.connect(delegate1).shouldThrow;
    signal.connect(function1).shouldThrow;

    // Connecting null should throw
    signal.connect(cast(signal.delegate_t) null).shouldThrow;
    signal.connect(cast(signal.function_t) null).shouldThrow;

    // Disconnect all
    signal.disconnectAll();
    signal.mSlots.length.should == 0;
}