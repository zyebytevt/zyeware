module zyeware.core.math.rect;

import std.traits : isNumeric;

import inmath.linalg;

import zyeware.common;

/// A two dimensional rectangle with float values.
alias Rect2f = Rect!float;
/// A two dimensional rectangle with int values.
alias Rect2i = Rect!int;

/// Represents an axis-aligned rectangle in 2D space.
struct Rect(T)
    if (isNumeric!T)
{
    private alias VT = Vector!(T, 2);

    VT position = VT.zero;
    VT size = VT.zero;

    /// Params:
    ///   x =  The x coordinate of the rectangle.
    ///   y =  The y coordinate of the rectangle.
    ///   width = The width of the rectangle.
    ///   height = The height of the rectangle.
    this(T x, T y, T width, T height) pure nothrow const
    {
        position = VT(x, y);
        size = VT(width, height);
    }

    /// Params:
    ///     position = The position of the rectangle.
    ///     size = The size of the rectangle.
    this(VT position, VT size) pure nothrow const
    {
        this.position = position;
        this.size = size;
    }

    /// Checks if a point falls within the rectangle.
    /// Params:
    ///   v = The point to check for.
    /// Returns: Whether the point is inside the rectangle.
    bool contains(VT v) pure nothrow const
    {
        return v.x >= position.x && v.x <= position.x + size.x
            && v.y >= position.y && v.y <= position.y + size.y;
    }

    /// Check if any of the area bounded by this rectangle is bounded by another
    /// Params:
    ///   b = The rectangle to check for.
    /// Returns: Whether the rectangle is overlapping.
    bool overlaps(Rect!T b) pure nothrow const
    {
        return position.x < b.position.x + b.size.x
            && position.x + size.x > b.position.x
            && position.y < b.position.y + b.size.y
            && position.y + size.y > b.position.y;
    }

    /// Move the rectangle so it is entirely contained within another
    /// If the rectangle is moved it will always be flush with a border of the given area
    Rect!T constrain(Rect!T outer) const
    {
        Rect!T r = this;
        if (r.position.x < outer.position.x)
            r.position.x = outer.position.x;
        if (r.position.y < outer.position.y)
            r.position.y = outer.position.y;
        if (r.position.x + r.size.x > outer.position.x + outer.size.x)
            r.position.x = outer.position.x + outer.size.x - r.size.x;
        if (r.position.y + r.size.y > outer.position.y + outer.size.y)
            r.position.y = outer.position.y + outer.size.y - r.size.y;
        return r;
    }

    VT min() pure nothrow const
    {
        return position;
    }

    VT max() pure nothrow const
    {
        return position + size;
    }
}