module zyeware.physics.shapes.circle2d;

import std.math : sqrt;

import zyeware;

class CircleShape2d : Shape2d
{
package(zyeware.physics.shapes):
    Collision2d isCollidingWithCircle(in Matrix4f thisTransform, in CircleShape2d other, in Matrix4f otherTransform) pure const nothrow
    {
        Collision2d collision;

        immutable Vector2f myPosition = thisTransform.transformPoint(Vector2f(0));
        immutable Vector2f otherPosition = otherTransform.transformPoint(Vector2f(0));
        immutable Vector2f distance = otherPosition - myPosition;

        immutable float distanceSquared = distance.lengthSquared;

        collision.firstCollider = this;
        collision.secondCollider = other;
        collision.isColliding = distanceSquared <= (radius + other.radius) ^^ 2;

        if (!collision.isColliding)
            return collision;

        immutable float distanceLength = sqrt(distanceSquared);

        collision.normal = distance / distanceLength;
        collision.point = thisTransform.transformPoint(collision.normal * radius);
        collision.penetrationDepth = radius + other.radius - distanceLength;

        return collision;
    }

public:
    float radius = 0;

    this(in float radius)
    {
        this.radius = radius;
    }

    Collision2d isCollidingWith(in Matrix4f thisTransform, in Shape2d other, in Matrix4f otherTransform) pure const nothrow
    {
        if (auto circle = cast(CircleShape2d) other)
            return isCollidingWithCircle(thisTransform, circle, otherTransform);
        else if (auto polygon = cast(PolygonShape2d) other)
            return polygon.isCollidingWithCircle(otherTransform, this, thisTransform);

        return Collision2d.init;
    }

    Collision2d isRaycastColliding(in Matrix4f thisTransform, in Vector2f rayOrigin, in Vector2f rayDirection, float maxDistance) pure const nothrow
    {
        Collision2d result;

        immutable Vector2f center = thisTransform.transformPoint(Vector2f.zero);
        immutable Vector2f oc = center - rayOrigin;

        // Calculate the projection of oc onto the ray direction
        immutable float t = dot(oc, rayDirection);

        // Check if the ray intersects the circle
        if (t < 0 || t > maxDistance)
            return result;

        // Calculate the closest point on the ray to the center of the circle
        immutable Vector2f closestPoint = rayOrigin + rayDirection * t;

        // Calculate the distance between the closest point and the center of the circle
        immutable float distanceSquared = (closestPoint - center).lengthSquared;

        // Check if the ray intersects the circle
        if (distanceSquared <= radius * radius)
        {
            result.isColliding = true;
            result.point = closestPoint;
            result.normal = (closestPoint - center) / sqrt(distanceSquared);
        }

        return result;
    }

    Projection2d project(in Matrix4f thisTransform, in Vector2f axis) pure const nothrow
    {
        immutable float center = thisTransform.transformPoint(Vector2f(0)).dot(axis);
        return Projection2d(center - radius, center + radius, axis);
    }

    AABB2 getAABB(in Matrix4f thisTransform) pure const nothrow
    {
        immutable Vector2f center = thisTransform.transformPoint(Vector2f.zero);
        return AABB2(center - Vector2f(radius), center + Vector2f(radius));
    }
}