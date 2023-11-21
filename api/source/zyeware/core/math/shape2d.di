// D import file generated from 'source/zyeware/core/math/shape2d.d'
module zyeware.core.math.shape2d;
import std.range;
import std.typecons : Tuple, Rebindable;
import zyeware.common;
struct Collision2D
{
	bool isColliding;
	Rebindable!(const(Shape2D)) firstCollider;
	Rebindable!(const(Shape2D)) secondCollider;
	Vector2f normal;
	Vector2f point;
	float penetrationDepth;
}
struct Projection2D
{
	float min;
	float max;
	Vector2f axis;
}
interface Shape2D
{
	const pure nothrow Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform);
	const pure nothrow Projection2D project(in Matrix4f transform, in Vector2f axis);
	const pure nothrow Rect2f getBoundingBox(in Matrix4f transform);
}
struct Normals2D
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
class CircleShape2D : Shape2D
{
	protected
	{
		const pure nothrow Collision2D checkCircleCollision(in Matrix4f transform, in CircleShape2D other, in Matrix4f otherTransform);
		public
		{
			float radius = 0.0F;
			pure nothrow this(float radius);
			const pure nothrow Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform);
			const pure nothrow Projection2D project(in Matrix4f transform, in Vector2f axis);
			const pure nothrow Rect2f getBoundingBox(in Matrix4f transform);
		}
	}
}
class PolygonShape2D : Shape2D
{
	protected
	{
		Rebindable!(const(Vector2f[])) mVertices;
		const pure nothrow Collision2D checkPolygonCollision(in Matrix4f transform, in PolygonShape2D other, in Matrix4f otherTransform);
		const pure nothrow Collision2D checkCircleCollision(in Matrix4f transform, in CircleShape2D other, in Matrix4f otherTransform);
		public
		{
			pure this(in Vector2f[] vertices);
			const pure nothrow Projection2D project(in Matrix4f transform, in Vector2f axis);
			const pure nothrow Collision2D checkCollision(in Matrix4f transform, in Shape2D other, in Matrix4f otherTransform);
			const pure nothrow const(Vector2f[]) vertices();
			const pure nothrow Rect2f getBoundingBox(in Matrix4f transform);
		}
	}
}
class RectangleShape2D : PolygonShape2D
{
	protected
	{
		Vector2f mHalfExtents;
		version (none)
		{
			const pure nothrow Collision2D checkRectCollision(in Matrix4f transform, in RectangleShape2D other, in Matrix4f otherTransform);
		}
		public
		{
			this(Vector2f halfExtents);
			const pure nothrow Vector2f halfExtents();
			pure nothrow void halfExtents(Vector2f value);
		}
	}
}
