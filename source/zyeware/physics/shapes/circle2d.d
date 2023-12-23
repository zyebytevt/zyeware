module zyeware.physics.shapes.circle2d;

import std.math : sqrt;

import zyeware;

class CircleShape2d : Shape2d
{
package(zyeware.physics.shapes):
    Collision2d isCollidingWithCircle(in mat4 thisTransform, in CircleShape2d other, in mat4 otherTransform) pure const nothrow
    {
        Collision2d collision;

        immutable vec2 myPosition = thisTransform.transformPoint(vec2(0));
        immutable vec2 otherPosition = otherTransform.transformPoint(vec2(0));
        immutable vec2 distance = otherPosition - myPosition;

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

    Collision2d isCollidingWith(in mat4 thisTransform, in Shape2d other, in mat4 otherTransform) pure const nothrow
    {
        if (auto circle = cast(CircleShape2d) other)
            return isCollidingWithCircle(thisTransform, circle, otherTransform);
        else if (auto polygon = cast(PolygonShape2d) other)
            return polygon.isCollidingWithCircle(otherTransform, this, thisTransform);

        return Collision2d.init;
    }

    Collision2d isRaycastColliding(in mat4 thisTransform, in vec2 rayOrigin, in vec2 rayDirection, float maxDistance) pure const nothrow
    {
        Collision2d result;

        immutable vec2 center = thisTransform.transformPoint(vec2.zero);
        immutable vec2 oc = center - rayOrigin;

        // Calculate the projection of oc onto the ray direction
        immutable float t = dot(oc, rayDirection);

        // Check if the ray intersects the circle
        if (t < 0 || t > maxDistance)
            return result;

        // Calculate the closest point on the ray to the center of the circle
        immutable vec2 closestPoint = rayOrigin + rayDirection * t;

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

    Projection2d project(in mat4 thisTransform, in vec2 axis) pure const nothrow
    {
        immutable float center = thisTransform.transformPoint(vec2(0)).dot(axis);
        return Projection2d(center - radius, center + radius, axis);
    }

    AABB2 getAABB(in mat4 thisTransform) pure const nothrow
    {
        immutable vec2 center = thisTransform.transformPoint(vec2.zero);
        return AABB2(center - vec2(radius), center + vec2(radius));
    }
}