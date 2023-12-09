// D import file generated from 'source/zyeware/physics/shapes/shape2d.d'
module zyeware.physics.shapes.shape2d;
import std.typecons : Rebindable;
public import inmath.aabb;
import zyeware;
struct Collision2d
{
	bool isColliding;
	Rebindable!(const(Shape2d)) firstCollider;
	Rebindable!(const(Shape2d)) secondCollider;
	Vector2f normal;
	Vector2f point;
	float penetrationDepth;
}
struct Projection2d
{
	float min;
	float max;
	Vector2f axis;
}
interface Shape2d
{
	const pure nothrow Collision2d isCollidingWith(in Matrix4f thisTransform, in Shape2d other, in Matrix4f otherTransform);
	const pure nothrow Collision2d isRaycastColliding(in Matrix4f thisTransform, in Vector2f rayOrigin, in Vector2f rayDirection, float maxDistance);
	const pure nothrow Projection2d project(in Matrix4f thisTransform, in Vector2f axis);
	const pure nothrow AABB2 getAABB(in Matrix4f thisTransform);
}
