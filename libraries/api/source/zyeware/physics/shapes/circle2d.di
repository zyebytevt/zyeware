// D import file generated from 'source/zyeware/physics/shapes/circle2d.d'
module zyeware.physics.shapes.circle2d;
import std.math : sqrt;
import zyeware;
class CircleShape2d : Shape2d
{
	package(zyeware.physics.shapes)
	{
		const pure nothrow Collision2d isCollidingWithCircle(in Matrix4f thisTransform, in CircleShape2d other, in Matrix4f otherTransform);
		public
		{
			float radius = 0;
			this(in float radius);
			const pure nothrow Collision2d isCollidingWith(in Matrix4f thisTransform, in Shape2d other, in Matrix4f otherTransform);
			const pure nothrow Collision2d isRaycastColliding(in Matrix4f thisTransform, in Vector2f rayOrigin, in Vector2f rayDirection, float maxDistance);
			const pure nothrow Projection2d project(in Matrix4f thisTransform, in Vector2f axis);
			const pure nothrow AABB2 getAABB(in Matrix4f thisTransform);
		}
	}
}
