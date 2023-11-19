// D import file generated from 'source/zyeware/core/random.d'
module zyeware.core.random;
import std.traits : isFloatingPoint, isSigned, isNumeric, CommonType;
import std.datetime : MonoTime;
import std.random;
class RandomNumberGenerator
{
	protected
	{
		Random mEngine;
		size_t mSeed;
		public
		{
			nothrow this();
			nothrow this(size_t seed);
			pure nothrow T get(T)() if (isNumeric!T)
			{
				alias UIntType = typeof(mEngine.front);
				immutable UIntType next = mEngine.front;
				mEngine.popFront();
				static if (isFloatingPoint!T)
				{
					return cast(T)next / UIntType.max;
				}
				else
				{
					static if (isSigned!T)
					{
						return cast(T)next - T.max;
					}
					else
					{
						return cast(T)next;
					}
				}
			}
			auto pure nothrow getRange(T, U)(T min, U max) if (isNumeric!T && isNumeric!U)
			{
				alias R = CommonType!(T, U);
				if (min == max)
					return cast(R)min;
				immutable float multiplier = get!float();
				return cast(R)(min + max * multiplier);
			}
			const pure nothrow size_t seed();
			pure nothrow void seed(size_t value);
		}
	}
}
