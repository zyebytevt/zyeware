// D import file generated from 'source/zyeware/utils/collection.d'
module zyeware.utils.collection;
import std.traits : hasIndirections, isDynamicArray;
import std.algorithm : countUntil, remove;
struct GrowableCircularQueue(T)
{
	private
	{
		size_t mLength;
		size_t mFirst;
		size_t mLast;
		T[] mArray = [T.init];
		public
		{
			pure nothrow this(T[] items...)
			{
				foreach (x; items)
				{
					push(x);
				}
			}
			const pure nothrow bool empty()
			{
				return mLength == 0;
			}
			inout pure nothrow inout(T) front()
			in (mLength != 0)
			{
				return mArray[mFirst];
			}
			inout pure nothrow inout(T) opIndex(in size_t i)
			in (i < mLength)
			{
				return mArray[mFirst + i & mArray.mLength - 1];
			}
			pure nothrow void push(T item)
			{
				if (mLength >= mArray.mLength)
				{
					immutable oldALen = mArray.mLength;
					mArray.mLength *= 2;
					if (mLast < mFirst)
					{
						mArray[oldALen..oldALen + mLast + 1] = mArray[0..mLast + 1];
						static if (hasIndirections!T)
						{
							mArray[0..mLast + 1] = T.init;
						}

						mLast += oldALen;
					}
				}
				mLast = mLast + 1 & mArray.mLength - 1;
				mArray[mLast] = item;
				mLength++;
			}
			pure nothrow T pop()
			in (mLength != 0)
			{
				auto saved = mArray[mFirst];
				static if (hasIndirections!T)
				{
					mArray[mFirst] = T.init;
				}

				mFirst = mFirst + 1 & mArray.mLength - 1;
				mLength--;
				return saved;
			}
			const pure nothrow size_t length()
			{
				return mLength;
			}
		}
	}
}
struct GrowableStack(T)
{
	private
	{
		size_t mNextPointer;
		T[] mArray;
		public
		{
			pure nothrow this(size_t initialSize)
			{
				mArray.length = initialSize;
			}
			const pure nothrow bool empty()
			{
				return mNextPointer == 0;
			}
			inout pure nothrow inout(T) peek()
			in (mNextPointer > 0)
			{
				return mArray[mNextPointer - 1];
			}
			inout pure nothrow inout(T) opIndex(size_t i)
			in (i < mNextPointer)
			{
				return mArray[i];
			}
			pure nothrow void push(T item)
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
			pure nothrow T pop()
			in (mNextPointer > 0)
			{
				auto saved = mArray[mNextPointer - 1];
				static if (hasIndirections!T)
				{
					mArray[mNextPointer - 1] = T.init;
				}

				--mNextPointer;
				return saved;
			}
			const pure nothrow size_t mLength()
			{
				return mNextPointer;
			}
			pure nothrow void mLength(size_t value)
			{
				mNextPointer = value;
				static if (hasIndirections!T)
				{
					mArray[value + 1..$] = T.init;
				}

			}
		}
	}
}
auto removeElement(R, N)(R haystack, N needle) if (isDynamicArray!R)
{
	auto index = haystack.countUntil(needle);
	return index != -1 ? haystack.remove(index) : haystack;
}
