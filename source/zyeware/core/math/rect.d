module zyeware.core.math.rect;

import std.traits : isNumeric;

import inmath.linalg;

import zyeware.common;

alias Rect2f = Rect!float;
alias Rect2i = Rect!int;
alias Rect2ui = Rect!uint;

/// Represents an axis-aligned rectangle in 2D space.
struct Rect(T)
    if (isNumeric!T)
{
    private alias VT = Vector!(T, 2);

    /// The starting point of the rectangle.
    VT min = VT(0);
    /// The end point of the rectangle.
    VT max = VT(0);

    /// Params:
    ///     x1 = The starting x-position.
    ///     y1 = The starting y-position.
    ///     x2 = The end x-position.
    ///     y2 = The end y-position.
    this(T x1, T y1, T x2, T y2) pure nothrow const
    {
        min = VT(x1, y1);
        max = VT(x2, y2);
    }

    /// Params:
    ///     min = The starting point.
    ///     max = The end point.
    this(VT min, VT max) pure nothrow const
    {
        this.min = min;
        this.max = max;
    }

    /// Checks if a point falls within the rectangle.
    bool contains(VT v) pure nothrow const
    {
        return v.x >= min.x && v.y >= min.y && v.x <= max.x && v.y <= max.y;
    }

    /// Check if any of the area bounded by this rectangle is bounded by another
    bool overlaps(Rect!T b) pure nothrow const
    {
        // TODO check if this works (unit test!)
        return min.x <= b.max.x
            && max.x >= b.min.x
            && min.y <= b.max.y && max.y >= b.min.y;
    }

    /// Move the rectangle so it is entirely contained with another
    /// If the rectangle is moved it will always be flush with a border of the given area
    version(none)
    Rect!T constrain(Rect!T outer) const
    {
        return Rect!T(min.clamp(outer.min, outer.min + outer.max - max),
                max);
    }
}