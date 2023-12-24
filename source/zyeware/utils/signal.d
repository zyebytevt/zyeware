module zyeware.utils.signal;

import std.algorithm : remove;

import zyeware;

struct Signal(T1...)
{
private:
    struct Slot
    {
        union
        {
            void delegate(T1) dg;
            void function(T1) fn;
        }

        bool isDelegate;
        bool isOneShot;
    }

    Slot[] mSlots;

public:
    alias slotidx_t = size_t;

    slotidx_t connect(void delegate(T1) dg, Flag!"oneShot" oneShot = No.oneShot)
    {
        Slot c;
        c.dg = dg;
        c.isDelegate = true;
        c.isOneShot = oneShot;
        mSlots ~= c;

        return mSlots.length - 1;
    }

    slotidx_t connect(void function(T1) fn, Flag!"oneShot" oneShot = No.oneShot)
    {
        Slot c;
        c.fn = fn;
        c.isDelegate = false;
        c.isOneShot = oneShot;
        mSlots ~= c;

        return mSlots.length - 1;
    }

    void disconnect(slotidx_t idx)
    {
        mSlots = mSlots.remove(idx);
    }

    void disconnect(void delegate(T1) dg)
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

    void disconnect(void function(T1) fn)
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

    void disconnectAll()
    {
        mSlots = [];
    }

    void emit(T1 args)
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
        slotidx_t opOpAssign(string op = "+")(void delegate(T1) dg) => connect(dg);
        slotidx_t opOpAssign(string op = "+")(void function(T1) fn) => connect(fn);
        void opOpAssign(string op = "-")(void delegate(T1) dg) => disconnect(dg);
        void opOpAssign(string op = "-")(void function(T1) fn) => disconnect(fn);
    }
}