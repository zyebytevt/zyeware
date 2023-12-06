module zyeware.utils.signal;

import std.algorithm : remove;

import zyeware;

struct Signal(Args...)
{
private:
    struct Callable
    {
        union
        {
            void delegate(Args) dg;
            void function(Args) fn;
        }
        bool isDelegate;
        bool isOneShot;
    }

    Callable[] mCallables;

public:
    void connect(void delegate(Args) dg, Flag!"oneShot" oneShot = No.oneShot)
    {
        Callable c;
        c.dg = dg;
        c.isDelegate = true;
        c.isOneShot = oneShot;
        mCallables ~= c;
    }

    void connect(void function(Args) fn, Flag!"oneShot" oneShot = No.oneShot)
    {
        Callable c;
        c.fn = fn;
        c.isDelegate = false;
        c.isOneShot = oneShot;
        mCallables ~= c;
    }

    void disconnect(void delegate(Args) dg)
    {
        for (size_t i; i < mCallables.length; ++i)
        {
            ref auto c = mCallables[i];

            if (c.isDelegate && c.dg is dg)
            {
                mCallables = mCallables.remove(i--);
                break;
            }
        }
    }

    void disconnect(void function(Args) fn)
    {
        for (size_t i; i < mCallables.length; ++i)
        {
            ref auto c = mCallables[i];
            
            if (!c.isDelegate && c.fn is fn)
            {
                mCallables = mCallables.remove(i--);
                break;
            }
        }
    }

    void disconnectAll()
    {
        mCallables = [];
    }

    void emit(Args args)
    {
        for (size_t i; i < mCallables.length; ++i)
        {
            ref auto c = mCallables[i];

            if (c.isDelegate)
                c.dg(args);
            else
                c.fn(args);

            if (c.isOneShot)
                mCallables = mCallables.remove(i--);
        }
    }

    pragma(inline, true)
    void opCall(Args args)
    {
        emit(args);
    }
}