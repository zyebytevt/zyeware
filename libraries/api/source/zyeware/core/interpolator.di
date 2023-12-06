// D import file generated from 'source/zyeware/core/interpolator.d'
module zyeware.core.interpolator;
import std.algorithm : remove, sort, clamp;
import std.typecons : Tuple;
import zyeware;
struct Interpolator(T, alias lerp)
{
	protected
	{
		alias Point = Tuple!(float, "offset", T, "value");
		Point[] mPoints;
		bool mMustSortPoints;
		public
		{
			pure nothrow void addPoint(float offset, const T value)
			{
				mPoints ~= Point(offset, value);
				mMustSortPoints = true;
			}
			pure nothrow void removePoint(size_t idx)
			{
				mPoints = mPoints.remove(idx);
				mMustSortPoints = true;
			}
			pure nothrow void clearPoints()
			{
				mPoints.length = 0;
			}
			pure nothrow T interpolate(float offset)
			{
				if (mPoints.length == 0)
					return T.init;
				else if (mPoints.length == 1)
					return mPoints[0].value;
				if (mMustSortPoints)
				{
					sort!((a, b) => a.offset < b.offset)(mPoints);
					mMustSortPoints = false;
				}
				ptrdiff_t low = 0;
				ptrdiff_t high = cast(ptrdiff_t)mPoints.length - 1;
				ptrdiff_t middle = 0;
				while (low <= high)
				{
					middle = (low + high) / 2;
					const Point* point = &mPoints[middle];
					if (point.offset > offset)
						high = middle - 1;
					else if (point.offset < offset)
						low = middle + 1;
					else
						return point.value;
				}
				if (mPoints[middle].offset > offset)
					--middle;
				immutable size_t first = middle;
				immutable size_t second = middle + 1;
				if (second >= mPoints.length)
					return mPoints[$ - 1].value;
				if (first < 0)
					return mPoints[0].value;
				const Point* pointFirst = &mPoints[first];
				const Point* pointSecond = &mPoints[second];
				return lerp(pointFirst.value, pointSecond.value, (offset - pointFirst.offset) / (pointSecond.offset - pointFirst.offset));
			}
		}
	}
}
