// This file was generated by ZyeWare APIgen. Do not edit!
module zyeware.physics.shapes.circle2d;


import std.math : sqrt;
import zyeware;

class CircleShape2d : Shape2d {

package(zyeware.physics.shapes):

Collision2d isCollidingWithCircle(in mat4 thisTransform, in CircleShape2d other, in mat4 otherTransform) pure const nothrow;

public:

float radius;

this(in float radius) {
this.radius = radius;
}

Collision2d isCollidingWith(in mat4 thisTransform, in Shape2d other, in mat4 otherTransform) pure const nothrow;

Collision2d isRaycastColliding(in mat4 thisTransform, in vec2 rayOrigin, in vec2 rayDirection, float maxDistance) pure const nothrow;

Projection2d project(in mat4 thisTransform, in vec2 axis) pure const nothrow;

AABB2 getAABB(in mat4 thisTransform) pure const nothrow;
}