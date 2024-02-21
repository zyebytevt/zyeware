module zyeware.physics.shapes.shape2d;

import std.typecons : Rebindable;

public import inmath.aabb;

import zyeware;

/// Represents a collision in 2D space.
struct Collision2d {
    bool isColliding; /// Whether the collider are actually colliding or not.
    Rebindable!(const Shape2d) firstCollider; /// The collider that checked for collision.
    Rebindable!(const Shape2d) secondCollider; /// The collider that collided with the checking collider.
    vec2 normal; /// The normal of the collision.
    vec2 point; /// The point of collision in world space.
    float penetrationDepth; /// How much the second collider penetrated the first.
}

/// Represents a projection of a polygon onto an axis.
struct Projection2d {
    float min; /// The starting point of the projection.
    float max; /// The end point of the projection.
    vec2 axis; /// The axis that was projected on.
}

interface Shape2d {
    Collision2d isCollidingWith(in mat4 thisTransform, in Shape2d other, in mat4 otherTransform) pure const nothrow;
    Collision2d isRaycastColliding(in mat4 thisTransform, in vec2 rayOrigin, in vec2 rayDirection, float maxDistance) pure const nothrow;
    Projection2d project(in mat4 thisTransform, in vec2 axis) pure const nothrow;
    AABB2 getAABB(in mat4 thisTransform) pure const nothrow;
}
