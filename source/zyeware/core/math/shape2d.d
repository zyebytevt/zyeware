module zyeware.core.math.shape2d;

import std.range;
import std.typecons : Tuple, Rebindable;

import zyeware.common;

/// Represents a collision in 2D space.
struct Collision2D
{
    bool isColliding; /// Whether the collider are actually colliding or not.
    Rebindable!(const Shape2D) firstCollider; /// The collider that checked for collision.
    Rebindable!(const Shape2D) secondCollider; /// The collider that collided with the checking collider.
    Vector2f normal; /// The normal of the collision.
    Vector2f point; /// The point of collision in world space.
    float penetrationDepth; /// How much the second collider penetrated the first.
}

/// Represents a projection of a polygon onto an axis.
struct Projection2D
{
    float min; /// The starting point of the projection.
    float max; /// The end point of the projection.
    Vector2f axis; /// The axis that was projected on.
}

/// Describes a shape in 2D space which can check for collisions.
interface Shape2D
{
    /// Checks for collision with another shape.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    ///     other = The other shape to check collision against.
    ///     otherTransform = The transform to apply to the other shape.
    ///
    /// Returns: A `Collision2D` struct containing information about a potential collision.
    /// See_Also: Collision2D
    Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform) pure const nothrow;

    /// Projects this shape onto an axis.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    ///     axis = The axis to project onto.
    ///
    /// Returns: A `Projection2D` struct containing information about the projection.
    /// See_Also: Projection2D
    Projection2D project(in Matrix4f transform, in Vector2f axis) pure const nothrow;

    /// Returns an axis-aligned bounding box, respecting a transform for this shape.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    Rect2f getBoundingBox(in Matrix4f transform) pure const nothrow;
}

/// Generates normals of a 2D shape on the fly.
/// Thanks to https://github.com/WebFreak001/sat-gl3n/blob/master/source/sat.d !
struct Normals2D
{
private:
	Vector2f[] mVertices;
	Matrix4f mTransform;
	Vector2f mFirst, mLast;
	bool mDidLast;

public:
    this(in Vector2f[] vertices, in Matrix4f transform) pure nothrow
        in (vertices, "Vertices cannot be null.")
    {
        mVertices = vertices.dup;
        mTransform = transform;
    }

    auto length() pure const nothrow
    {
        return mVertices.length;
    }

	void popFront() pure nothrow
	{
		if (mVertices.empty && !mDidLast)
			mDidLast = true;
		else
		{
			mLast = mVertices.front;
			mVertices.popFront;
		}
	}

	bool empty() pure const nothrow
	{
		return mVertices.empty && mDidLast;
	}

	Vector2f front() pure const nothrow
	{
		Vector2f a;
		
        if (mVertices.empty)
			a = mTransform.transformPoint(mFirst);
		else
			a = mTransform.transformPoint(mVertices.front);
        
        const b = mTransform.transformPoint(mLast);
		return Vector2f(b.y - a.y, a.x - b.x).normalized;
	}
}

/// A shape that represents a circle in 2D space.
class CircleShape2D : Shape2D
{
protected:
    Collision2D checkCircleCollision(in Matrix4f transform, in CircleShape2D other, in Matrix4f otherTransform) pure const nothrow
    {
        Collision2D collision;

        immutable Vector2f myPosition = transform.transformPoint(Vector2f(0));
        immutable Vector2f otherPosition = otherTransform.transformPoint(Vector2f(0));
        immutable Vector2f distance = otherPosition - myPosition;

        collision.firstCollider = this;
        collision.secondCollider = other;
        collision.isColliding = distance.magnitude_squared <= (radius + other.radius) ^^ 2;

        if (!collision.isColliding)
            return collision;

        collision.normal = distance.normalized;
        collision.point = transform.transformPoint(collision.normal * radius);
        collision.penetrationDepth = radius + other.radius - distance.magnitude;

        return collision;
    }

public:
    /// The radius of the circle.
    float radius = 0f;

    /// Params:
    ///     radius = The radius of the circle.
    this(float radius) pure nothrow
    {
        this.radius = radius;
    }

    /// Checks for collision with another shape.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    ///     other = The other shape to check collision against.
    ///     otherTransform = The transform to apply to the other shape.
    ///
    /// Returns: A `Collision2D` struct containing information about a potential collision.
    /// See_Also: Collision2D
    Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform) pure const nothrow
        in (other, "Other shape cannot be null.")
    {
        if (auto circle = cast(CircleShape2D) other)
            return checkCircleCollision(transform, circle, otherTransform);
        else if (auto polygon = cast(PolygonShape2D) other)
            return polygon.checkCircleCollision(otherTransform, this, transform);
        else
            return Collision2D.init;
    }

    /// Projects this shape onto an axis.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    ///     axis = The axis to project onto.
    ///
    /// Returns: A `Projection2D` struct containing information about the projection.
    /// See_Also: Projection2D
    Projection2D project(in Matrix4f transform, in Vector2f axis) pure const nothrow
    {
        immutable float center = transform.transformPoint(Vector2f(0)).dot(axis);
        return Projection2D(center - radius, center + radius, axis);
    }

    /// Returns an axis-aligned bounding box, respecting a transform for this shape.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    Rect2f getBoundingBox(in Matrix4f transform) pure const nothrow
    {
        return Rect2f(-radius, -radius, radius, radius);
    }
}

/// A polygon shape in 2D space.
class PolygonShape2D : Shape2D
{
protected:
    Rebindable!(const Vector2f[]) mVertices;

    Collision2D checkPolygonCollision(in Matrix4f transform, in PolygonShape2D other, in Matrix4f otherTransform) pure const nothrow
    {
        Projection2D rangeA, rangeB;
        Collision2D collision;

        collision.firstCollider = this;
        collision.secondCollider = other;

        foreach (Vector2f normal; Normals2D(mVertices, transform))
        {
            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        foreach (Vector2f normal; Normals2D(other.mVertices, otherTransform))
        {
            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        collision.isColliding = true;
        return collision;
    }

    Collision2D checkCircleCollision(in Matrix4f transform, in CircleShape2D other, in Matrix4f otherTransform) pure const nothrow
    {
        Collision2D collision;
        Projection2D rangeA, rangeB;

        collision.firstCollider = this;
        collision.secondCollider = other;

        immutable Vector2f circlePosition = otherTransform.transformPoint(Vector2f(0));

        for (size_t i; i < mVertices.length; ++i)
        {
            immutable Vector2f normal = (transform.transformPoint(mVertices[i]) - circlePosition).normalized;

            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max < rangeB.min || rangeB.max < rangeA.min)
                return collision;
        }

        foreach (Vector2f normal; Normals2D(mVertices, transform))
        {
            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max < rangeB.min || rangeB.max < rangeA.min)
                return collision;
        }

        collision.isColliding = true;
        return collision;
    }

public:
    /// Params:
    ///     vertices = The vertices that this polygon should consist of.
    this(in Vector2f[] vertices) pure
        in (vertices && vertices.length >= 3, "PolygonShape2D must have at least 3 vertices.")
    {
        mVertices = vertices;
    }

    /// Projects this shape onto an axis.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    ///     axis = The axis to project onto.
    ///
    /// Returns: A `Projection2D` struct containing information about the projection.
    /// See_Also: Projection2D
    Projection2D project(in Matrix4f transform, in Vector2f axis) pure const nothrow
    {
        float min = transform.transformPoint(mVertices[0]).dot(axis);
        float max = min;

        for (size_t i = 1; i < mVertices.length; ++i)
        {
            immutable float current = transform.transformPoint(mVertices[i]).dot(axis);

            if (current < min)
                min = current;
            else if (current > max)
                max = current;
        }

        return Projection2D(min, max, axis);
    }

    /// Checks for collision with another shape.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    ///     other = The other shape to check collision against.
    ///     otherTransform = The transform to apply to the other shape.
    ///
    /// Returns: A `Collision2D` struct containing information about a potential collision.
    /// See_Also: Collision2D
    Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform) pure const nothrow
        in (other, "Other shape cannot be null.")
    {
        if (auto polygon = cast(PolygonShape2D) other)
            return checkPolygonCollision(transform, polygon, otherTransform);
        else if (auto circle = cast(CircleShape2D) other)
            return checkCircleCollision(transform, circle, otherTransform);
        else
            return Collision2D.init;
    }

    /// The verticies this polygon consists of.
    const(Vector2f[]) vertices() pure const nothrow
    {
        return mVertices;
    }

    /// Returns an axis-aligned bounding box, respecting a transform for this shape.
    ///
    /// Params:
    ///     transform = The transform to apply to this shape.
    Rect2f getBoundingBox(in Matrix4f transform) pure const nothrow
    {
        Rect2f result = Rect2f(0, 0, 0, 0);

        foreach (Vector2f vertex; mVertices)
        {
            vertex = transform.transformPoint(vertex);

            if (vertex.x < result.min.x)
                result.min.x = vertex.x;
            else if (vertex.x > result.max.x)
                result.max.x = vertex.x;

            if (vertex.y < result.min.y)
                result.min.y = vertex.y;
            else if (vertex.y > result.max.y)
                result.max.y = vertex.y;
        }

        return result;
    }
}

/// A shape representing a rectangle in 2D space.
/// Using this in favor of a rectangle `PolygonShape2D` can increase performance.
/// See_Also: PolygonShape2D
// TODO: Documentation is a lie. Improve performance!
class RectangleShape2D : PolygonShape2D
{
protected:
    Vector2f mHalfExtents;

    version(none)
    Collision2D checkRectCollision(in Matrix4f transform, in RectangleShape2D other, in Matrix4f otherTransform) pure const nothrow
    {
        Projection2D rangeA, rangeB;
        Collision2D collision;

        collision.firstCollider = this;
        collision.secondCollider = other;

        auto normals = Normals2D(mVertices, transform);
        for (size_t i; i < 2; ++i)
        {
            immutable Vector2f normal = normals.front;
            normals.popFront;

            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        auto normals2 = Normals2D(other.mVertices, otherTransform);
        for (size_t i; i < 2; ++i)
        {
            immutable Vector2f normal = normals2.front;
            normals2.popFront;
            
            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        collision.isColliding = true;
        return collision;
    }

public:
    /// Params:
    ///     halfExtents = The half extents of this rectangle.
    this(Vector2f halfExtents)
    {
        this.halfExtents = halfExtents;
        super(mVertices);
    }

    /// The half extents of this rectangle.
    Vector2f halfExtents() pure const nothrow
    {
        return mHalfExtents;
    }

    /// ditto
    void halfExtents(Vector2f value) pure nothrow
    {
        mHalfExtents = value;

        mVertices = [
            Vector2f(-mHalfExtents.x, -mHalfExtents.y),
            Vector2f(mHalfExtents.x, -mHalfExtents.y),
            Vector2f(mHalfExtents.x, mHalfExtents.y),
            Vector2f(-mHalfExtents.x, mHalfExtents.y)
        ];
    }

    /*override Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform) pure const nothrow
    {
        if (auto rect = cast(RectangleShape2D) other)
            return checkRectCollision(transform, rect, otherTransform);

        return super.checkCollision(transform, other, otherTransform);
    }*/
}