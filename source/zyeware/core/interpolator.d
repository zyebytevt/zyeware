module zyeware.core.interpolator;

import std.algorithm : remove, sort, clamp;
import std.typecons : Tuple;

import zyeware.common;

struct Interpolator(T, alias lerp)
{
protected:
    alias Point = Tuple!(float, "offset", T, "value");

    Point[] mPoints;
    bool mMustSortPoints;

public:
    void addPoint(float offset, const T value) pure nothrow
    {
        mPoints ~= Point(offset, value);
        mMustSortPoints = true;
    }

    void removePoint(size_t idx) pure nothrow
    {
        mPoints = mPoints.remove(idx);
        mMustSortPoints = true;
    }

    void clearPoints() pure nothrow
    {
        mPoints.length = 0;
    }

    // Thanks to the Godot Engine for this code!
    // https://github.com/godotengine/godot/blob/master/scene/resources/gradient.h
    T interpolate(float offset) pure nothrow
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