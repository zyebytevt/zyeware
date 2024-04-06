module zyeware.core.random;

import std.traits : isFloatingPoint, isSigned, isNumeric, CommonType;
import std.datetime : MonoTime;
import std.random;

/// A simple implementation of a random number generator, with the option of
/// using a custom seed.
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

    /// Params:
    ///   seed = The seed to initialise this RNG with.
    this(size_t seed) nothrow
    {
        this.seed = seed;
    }

    /// Gets the next random number.
    /// Params:
    ///   T = The type of number to generate.
    /// Returns: The next generated random number.
    T get(T)() pure nothrow if (isNumeric!T)
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

    /// Generates a random number that lies between the range given.
    /// Params:
    ///   min = The minimum number to return.
    ///   max = The maximum number to return, exclusive.
    /// Returns: The generated random number.
    auto getRange(T, U)(T min, U max) pure nothrow if (isNumeric!T && isNumeric!U)
    {
        alias R = CommonType!(T, U);
        if (min == max)
            return cast(R) min;

        immutable float multiplier = get!float();

        return cast(R)(min + max * multiplier);
    }

    /// The seed of this random number generator.
    size_t seed() pure const nothrow
    {
        return mSeed;
    }

    /// ditto
    void seed(size_t value) pure nothrow
    {
        mSeed = value;
        mEngine.seed(cast(typeof(Random.defaultSeed)) mSeed);
    }
}
