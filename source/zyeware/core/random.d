module zyeware.core.random;

import std.traits : isFloatingPoint, isSigned, isNumeric, CommonType;
import std.datetime : MonoTime;
import std.random;

class RandomNumberGenerator
{
protected:
    Random mEngine;
    size_t mSeed;

public:
    this() nothrow
    {
        this(MonoTime.currTime().ticks);
    }

    this(size_t seed) nothrow
    {
        this.seed = seed;
    }

    T get(T)() pure nothrow
    {
        alias UIntType = typeof(mEngine.front);
        immutable UIntType next = mEngine.front;
        mEngine.popFront();

        static if (isFloatingPoint!T)
            return cast(T) next / UIntType.max;
        else static if (isSigned!T)
            return cast(T) next - T.max;
        else
            return cast(T) next;
    }

    auto getRange(T, U)(T min, U max) pure nothrow
        if (isNumeric!T && isNumeric!U)
    {
        alias R = CommonType!(T, U);
        if (min == max)
            return cast(R) min;

        immutable float multiplier = get!float();

        return cast(R) (min + max * multiplier);
    }

    size_t seed() pure const nothrow
    {
        return mSeed;
    }
    
    void seed(size_t value) pure nothrow
    {
        mSeed = value;
        mEngine.seed(cast(typeof(Random.defaultSeed)) mSeed);
    }
}