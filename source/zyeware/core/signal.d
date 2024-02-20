module zyeware.core.signal;

import std.algorithm : remove;
import std.meta : AliasSeq, staticIndexOf;
import std.sumtype : SumType, match;

import zyeware;

struct Signal(T1...)
{
private:
    alias delegate_t = void delegate(T1);
    alias delegate_nothrow_t = void delegate(T1) nothrow;
    alias function_t = void function(T1);
    alias function_nothrow_t = void function(T1) nothrow;

    alias callbacks_t = AliasSeq!(
        delegate_t,
        delegate_nothrow_t,
        function_t,
        function_nothrow_t
    );

    struct Slot
    {
        SumType!callbacks_t callback;
        bool isOneShot;
    }

    Slot[] mSlots;

    ptrdiff_t findSlot(T)(T callback) @trusted pure nothrow
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];

            immutable ptrdiff_t result = c.callback.match!(
                (T cb) => cb is callback ? i : -1,
                _ => -1
            );

            if (result != -1)
                return result;
        }

        return -1;
    }

public:
    void connect(T)(T callback, Flag!"oneShot" oneShot = No.oneShot) @trusted pure
    {
        enforce!CoreException(callback, "Delegate cannot be null.");
        enforce!CoreException(findSlot(callback) == -1, "Delegate already connected.");

        Slot c;
        c.callback = callback;
        c.isOneShot = oneShot;
        mSlots ~= c;
    }

    void disconnect(T)(T callback) @trusted pure nothrow
    {
        immutable idx = findSlot(callback);
        if (idx >= 0)
            mSlots = mSlots.remove(idx);
    }

    void disconnectAll() @safe pure nothrow
    {
        mSlots = [];
    }

    void emit(T1 args)
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];

            c.callback.match!(
                (delegate_nothrow_t dg) => dg(args),
                (delegate_t dg) => dg(args),
                (function_nothrow_t fn) => fn(args),
                (function_t fn) => fn(args),
            );

            if (c.isOneShot)
                mSlots = mSlots.remove(i--);
        }
    }

    pragma(inline, true)
    {
        void opCall(T1 args) => emit(args);
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