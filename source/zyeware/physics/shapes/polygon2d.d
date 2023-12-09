module zyeware.physics.shapes.polygon2d;

import std.typecons : Rebindable;
import std.range;

import zyeware;

class PolygonShape2d : Shape2d
{
protected:
    Rebindable!(const Vector2f[]) mVertices;

package(zyeware.physics.shapes):
    Collision2d isCollidingWithPolygon(in Matrix4f thisTransform, in PolygonShape2d other, in Matrix4f otherTransform) pure const nothrow
    {
        Projection2d rangeA, rangeB;
        Collision2d collision;

        collision.firstCollider = this;
        collision.secondCollider = other;

        foreach (Vector2f normal; Normals2d(mVertices, thisTransform))
        {
            rangeA = project(thisTransform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        foreach (Vector2f normal; Normals2d(other.mVertices, otherTransform))
        {
            rangeA = project(thisTransform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        collision.isColliding = true;
        return collision;
    }

    Collision2d isCollidingWithCircle(in Matrix4f transform, in CircleShape2d other, in Matrix4f otherTransform) pure const nothrow
    {
        Collision2d collision;
        Projection2d rangeA, rangeB;

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

        foreach (Vector2f normal; Normals2d(mVertices, transform))
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
    this(in Vector2f[] vertices) pure
        in (vertices && vertices.length >= 3, "Polygon must have at least 3 vertices.")
    {
        mVertices = vertices;
    }

    Collision2d isCollidingWith(in Matrix4f thisTransform, in Shape2d other, in Matrix4f otherTransform) pure const nothrow
    {
        if (auto circle = cast(CircleShape2d) other)
            return isCollidingWithCircle(thisTransform, circle, otherTransform);
        else if (auto polygon = cast(PolygonShape2d) other)
            return isCollidingWithPolygon(thisTransform, polygon, otherTransform);
        
        return Collision2d.init;
    }

    Collision2d isRaycastColliding(in Matrix4f thisTransform, in Vector2f rayOrigin, in Vector2f rayDirection, float maxDistance) pure const nothrow
    {
        Collision2d result;
        immutable Vector2f rayEnd = rayOrigin + rayDirection * maxDistance;

        for (size_t i = 0; i < mVertices.length; ++i)
        {
            immutable Vector2f vertex1 = thisTransform.transformPoint(mVertices[i]);
            immutable Vector2f vertex2 = thisTransform.transformPoint(mVertices[(i + 1) % mVertices.length]);

            immutable Vector2f edge = vertex2 - vertex1;
            immutable Vector2f normal = Vector2f(-edge.y, edge.x);

            immutable Projection2d polygonProjection = project(thisTransform, normal);
            immutable Projection2d rayProjection = Projection2d(rayOrigin.dot(normal), rayEnd.dot(normal), normal);

            if (polygonProjection.max < rayProjection.min || rayProjection.max < polygonProjection.min)
                return result; // No collision

            // Calculate intersection point
            immutable float t = (cross2d(vertex1 - rayOrigin, rayDirection)) / (cross2d(edge, rayDirection));
            if (t >= 0 && t <= 1)
            {
                result.point = vertex1 + t * edge;
                result.normal = normal;
                result.isColliding = true;
                return result;
            }
        }

        return result; // No collision
    }

    Projection2d project(in Matrix4f thisTransform, in Vector2f axis) pure const nothrow
    {
        float min = thisTransform.transformPoint(mVertices[0]).dot(axis);
        float max = min;

        for (size_t i = 1; i < mVertices.length; ++i)
        {
            immutable float current = thisTransform.transformPoint(mVertices[i]).dot(axis);

            if (current < min)
                min = current;
            else if (current > max)
                max = current;
        }

        return Projection2d(min, max, axis);
    }

    AABB2 getAABB(in Matrix4f thisTransform) pure const nothrow
    {
        scope Vector2f[] transformedVertices = new Vector2f[mVertices.length];
        scope (exit) destroy(transformedVertices);

        foreach (size_t i, const ref Vector2f vertex; mVertices)
            transformedVertices[i] = thisTransform.transformPoint(vertex);

        return AABB2.fromPoints(transformedVertices);
    }
}

/// Generates normals of a 2D shape on the fly.
/// Thanks to https://github.com/WebFreak001/sat-inmath/blob/master/source/sat.d !
struct Normals2d
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