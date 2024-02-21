module zyeware.physics.shapes.polygon2d;

import std.typecons : Rebindable;
import std.range;

import zyeware;

class PolygonShape2d : Shape2d {
protected:
    Rebindable!(const vec2[]) mVertices;

package(zyeware.physics.shapes):
    Collision2d isCollidingWithPolygon(in mat4 thisTransform, in PolygonShape2d other, in mat4 otherTransform) pure const nothrow {
        Projection2d rangeA, rangeB;
        Collision2d collision;

        collision.firstCollider = this;
        collision.secondCollider = other;

        foreach (vec2 normal; Normals2d(mVertices, thisTransform)) {
            rangeA = project(thisTransform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        foreach (vec2 normal; Normals2d(other.mVertices, otherTransform)) {
            rangeA = project(thisTransform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max <= rangeB.min || rangeB.max <= rangeA.min)
                return collision;
        }

        collision.isColliding = true;
        return collision;
    }

    Collision2d isCollidingWithCircle(in mat4 transform, in CircleShape2d other, in mat4 otherTransform) pure const nothrow {
        Collision2d collision;
        Projection2d rangeA, rangeB;

        collision.firstCollider = this;
        collision.secondCollider = other;

        immutable vec2 circlePosition = otherTransform.transformPoint(vec2(0));

        for (size_t i; i < mVertices.length; ++i) {
            immutable vec2 normal = (transform.transformPoint(mVertices[i]) - circlePosition)
                .normalized;

            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max < rangeB.min || rangeB.max < rangeA.min)
                return collision;
        }

        foreach (vec2 normal; Normals2d(mVertices, transform)) {
            rangeA = project(transform, normal);
            rangeB = other.project(otherTransform, normal);

            if (rangeA.max < rangeB.min || rangeB.max < rangeA.min)
                return collision;
        }

        collision.isColliding = true;
        return collision;
    }

public:
    this(in vec2[] vertices) pure
    in (vertices && vertices.length >= 3, "Polygon must have at least 3 vertices.") {
        mVertices = vertices;
    }

    Collision2d isCollidingWith(in mat4 thisTransform, in Shape2d other, in mat4 otherTransform) pure const nothrow {
        if (auto circle = cast(CircleShape2d) other)
            return isCollidingWithCircle(thisTransform, circle, otherTransform);
        else if (auto polygon = cast(PolygonShape2d) other)
            return isCollidingWithPolygon(thisTransform, polygon, otherTransform);

        return Collision2d.init;
    }

    Collision2d isRaycastColliding(in mat4 thisTransform, in vec2 rayOrigin, in vec2 rayDirection, float maxDistance) pure const nothrow {
        Collision2d result;
        immutable vec2 rayEnd = rayOrigin + rayDirection * maxDistance;

        for (size_t i = 0; i < mVertices.length; ++i) {
            immutable vec2 vertex1 = thisTransform.transformPoint(mVertices[i]);
            immutable vec2 vertex2 = thisTransform.transformPoint(
                mVertices[(i + 1) % mVertices.length]);

            immutable vec2 edge = vertex2 - vertex1;
            immutable vec2 normal = vec2(-edge.y, edge.x);

            immutable Projection2d polygonProjection = project(thisTransform, normal);
            immutable Projection2d rayProjection = Projection2d(rayOrigin.dot(normal), rayEnd.dot(normal), normal);

            if (polygonProjection.max < rayProjection.min || rayProjection.max < polygonProjection
                .min)
                return result; // No collision

            // Calculate intersection point
            immutable float t = (cross2d(vertex1 - rayOrigin, rayDirection)) / (cross2d(edge, rayDirection));
            if (t >= 0 && t <= 1) {
                result.point = vertex1 + t * edge;
                result.normal = normal;
                result.isColliding = true;
                return result;
            }
        }

        return result; // No collision
    }

    Projection2d project(in mat4 thisTransform, in vec2 axis) pure const nothrow {
        float min = thisTransform.transformPoint(mVertices[0]).dot(axis);
        float max = min;

        for (size_t i = 1; i < mVertices.length; ++i) {
            immutable float current = thisTransform.transformPoint(mVertices[i]).dot(axis);

            if (current < min)
                min = current;
            else if (current > max)
                max = current;
        }

        return Projection2d(min, max, axis);
    }

    AABB2 getAABB(in mat4 thisTransform) pure const nothrow {
        scope vec2[] transformedVertices = new vec2[mVertices.length];
        scope (exit)
            destroy(transformedVertices);

        foreach (size_t i, const ref vec2 vertex; mVertices)
            transformedVertices[i] = thisTransform.transformPoint(vertex);

        return AABB2.fromPoints(transformedVertices);
    }
}

/// Generates normals of a 2D shape on the fly.
/// Thanks to https://github.com/WebFreak001/sat-inmath/blob/master/source/sat.d !
struct Normals2d {
private:
    vec2[] mVertices;
    mat4 mTransform;
    vec2 mFirst, mLast;
    bool mDidLast;

public:
    this(in vec2[] vertices, in mat4 transform) pure nothrow
    in (vertices, "Vertices cannot be null.") {
        mVertices = vertices.dup;
        mTransform = transform;
    }

    size_t length() pure const nothrow {
        return mVertices.length;
    }

    void popFront() pure nothrow {
        if (mVertices.empty && !mDidLast)
            mDidLast = true;
        else {
            mLast = mVertices.front;
            mVertices.popFront;
        }
    }

    bool empty() pure const nothrow {
        return mVertices.empty && mDidLast;
    }

    vec2 front() pure const nothrow {
        vec2 a;

        if (mVertices.empty)
            a = mTransform.transformPoint(mFirst);
        else
            a = mTransform.transformPoint(mVertices.front);

        const b = mTransform.transformPoint(mLast);
        return vec2(b.y - a.y, a.x - b.x).normalized;
    }
}
