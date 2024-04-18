module zyeware.utils.interpolator;

import std.algorithm : remove, sort, clamp;
import std.typecons : Tuple;

import zyeware;
import zyeware.utils.sdlang;

alias Interpolatorf = Interpolator!(float, lerp!float);
alias Interpolatord = Interpolator!(double, lerp!double);

/// The `Interpolator` allows to create various keypoints on a 
/// one dimensional line, and interpolating between them.
/// You can supply a custom type and lerping function for various
/// different types.
struct Interpolator(T, alias lerp)
{
protected:
    alias Point = Tuple!(float, "offset", T, "value");

    Point[] mPoints;
    bool mMustSortPoints;

public:
    /// Add a keypoint to the interpolator with the given offset and value.
    /// Params:
    ///   offset = The offset of the keypoint.
    ///   value = The value of the keypoint.
    void addPoint(float offset, const T value) pure nothrow
    {
        mPoints ~= Point(offset, value);
        mMustSortPoints = true;
    }

    /// Removes a keypoint with the given index.
    void removePoint(size_t idx) pure nothrow
    {
        mPoints = mPoints.remove(idx);
        mMustSortPoints = true;
    }

    /// Removes all keypoints from this interpolator.
    void clearPoints() pure nothrow
    {
        mPoints.length = 0;
    }

    // Thanks to the Godot Engine for this code!
    // https://github.com/godotengine/godot/blob/master/scene/resources/gradient.h
    /// Interpolates a value from the keypoints in this interpolator from the given offset.
    /// Params:
    ///   offset = The offset to use.
    /// Returns: The interpolated value.
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
        ptrdiff_t high = cast(ptrdiff_t) mPoints.length - 1;
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

        return lerp(pointFirst.value, pointSecond.value,
            (offset - pointFirst.offset) / (pointSecond.offset - pointFirst.offset));
    }

    static auto load(string path)
    {
        SDLNode* root = loadSdlDocument(path);

        Interpolator!(T, lerp) interpolator;

        for (size_t i; i < root.children.length; ++i)
        {
            SDLNode* node = &root.children[i];
            if (node.name == "keypoint")
                interpolator.addPoint(node.getAttributeValue!float("offset"),
                    node.getAttributeValue!T("value"));
        }

        return interpolator;
    }
}

@("Interpolator")
unittest
{
    import unit_threaded.assertions;

    // Create an Interpolator
    Interpolatorf interpolator;

    // Add points
    interpolator.addPoint(0.0f, 0.0f);
    interpolator.addPoint(1.0f, 1.0f);
    interpolator.addPoint(0.5f, 0.5f);
    interpolator.mPoints.length.should == 3;

    // Remove a point
    interpolator.removePoint(1);
    interpolator.mPoints.length.should == 2;

    // Clear points
    interpolator.clearPoints();
    interpolator.mPoints.length.should == 0;

    // Add points again
    interpolator.addPoint(0.0f, 0.0f);
    interpolator.addPoint(1.0f, 1.0f);
    interpolator.addPoint(0.5f, 0.5f);
    interpolator.mPoints.length.should == 3;

    // Interpolate
    interpolator.interpolate(0.25f).should == 0.25f;
    interpolator.interpolate(0.75f).should == 0.75f;
}
