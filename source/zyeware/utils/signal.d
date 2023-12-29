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

public:
    alias slotidx_t = size_t;

    slotidx_t connect(delegate_t dg, Flag!"oneShot" oneShot = No.oneShot) @trusted pure nothrow
    {
        Slot c;
        c.dg = dg;
        c.isDelegate = true;
        c.isOneShot = oneShot;
        mSlots ~= c;

        return mSlots.length - 1;
    }

    slotidx_t connect(function_t fn, Flag!"oneShot" oneShot = No.oneShot) @trusted pure nothrow
    {
        Slot c;
        c.fn = fn;
        c.isDelegate = false;
        c.isOneShot = oneShot;
        mSlots ~= c;

        return mSlots.length - 1;
    }

    void disconnect(slotidx_t idx) @safe pure nothrow
    {
        mSlots = mSlots.remove(idx);
    }

    void disconnect(delegate_t dg) @trusted pure nothrow
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];

            if (c.isDelegate && c.dg is dg)
            {
                mSlots = mSlots.remove(i);
                break;
            }
        }
    }

    void disconnect(function_t fn) @trusted pure nothrow
    {
        for (size_t i; i < mSlots.length; ++i)
        {
            auto c = &mSlots[i];
            
            if (!c.isDelegate && c.fn is fn)
            {
                mSlots = mSlots.remove(i);
                break;
            }
        }
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
        slotidx_t opOpAssign(string op)(delegate_t dg) if (op == "+") => connect(dg);
        slotidx_t opOpAssign(string op)(function_t fn) if (op == "+") => connect(fn);
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

    auto slot1 = signal.connect(delegate1);
    signal.mSlots.length.should == 1;

    auto slot2 = signal.connect(function1);
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
    slot1 = signal.connect(delegate1);
    slot2 = signal.connect(function1);
    signal.mSlots.length.should == 2;

    // Disconnect using the slot index
    signal.disconnect(slot1);
    signal.mSlots.length.should == 1;
    signal.disconnect(slot2);
    signal.mSlots.length.should == 0;

    // Connect the delegate and function again
    slot1 = signal.connect(delegate1);
    slot2 = signal.connect(function1);
    signal.mSlots.length.should == 2;

    // Disconnect all
    signal.disconnectAll();
    signal.mSlots.length.should == 0;
}