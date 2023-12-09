// D import file generated from 'source/zyeware/physics/shapes/polygon2d.d'
module zyeware.physics.shapes.polygon2d;
import std.typecons : Rebindable;
import std.range;
import zyeware;
class PolygonShape2d : Shape2d
{
	protected
	{
		Rebindable!(const(Vector2f[])) mVertices;
		package(zyeware.physics.shapes)
		{
			const pure nothrow Collision2d isCollidingWithPolygon(in Matrix4f thisTransform, in PolygonShape2d other, in Matrix4f otherTransform);
			const pure nothrow Collision2d isCollidingWithCircle(in Matrix4f transform, in CircleShape2d other, in Matrix4f otherTransform);
			public
			{
				pure this(in Vector2f[] vertices);
				const pure nothrow Collision2d isCollidingWith(in Matrix4f thisTransform, in Shape2d other, in Matrix4f otherTransform);
				const pure nothrow Collision2d isRaycastColliding(in Matrix4f thisTransform, in Vector2f rayOrigin, in Vector2f rayDirection, float maxDistance);
				const pure nothrow Projection2d project(in Matrix4f thisTransform, in Vector2f axis);
				const pure nothrow AABB2 getAABB(in Matrix4f thisTransform);
			}
		}
	}
}
struct Normals2d
{
	private
	{
		Vector2f[] mVertices;
		Matrix4f mTransform;
		Vector2f mFirst;
		Vector2f mLast;
		bool mDidLast;
		public
		{
			pure nothrow this(in Vector2f[] vertices, in Matrix4f transform);
			auto const pure nothrow length()
			{
				return mVertices.length;
			}
			pure nothrow void popFront();
			const pure nothrow bool empty();
			const pure nothrow Vector2f front();
		}
	}
}
