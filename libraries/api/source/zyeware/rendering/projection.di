// D import file generated from 'source/zyeware/rendering/projection.d'
module zyeware.rendering.projection;
import zyeware;
interface Projection
{
	public
	{
		pure nothrow Matrix4f projectionMatrix();
		pragma (inline, true)static final pure nothrow Matrix4f calculateViewMatrix(Vector3f position, Quaternionf rotation)
		{
			return (Matrix4f.translation(position) * rotation.toMatrix!(4, 4)).inverse;
		}
	}
}
class OrthographicProjection : Projection
{
	protected
	{
		Matrix4f mProjectionMatrix;
		float mLeft;
		float mRight;
		float mBottom;
		float mTop;
		float mNear;
		float mFar;
		bool mIsDirty;
		pragma (inline, true)pure nothrow void recalculateProjectionMatrix()
		{
			mProjectionMatrix = Matrix4f.orthographic(mLeft, mRight, mBottom, mTop, mNear, mFar);
			mIsDirty = false;
		}
		public
		{
			pure nothrow this(float left, float right, float bottom, float top, float near = -1.0F, float far = 1.0F);
			pure nothrow Matrix4f projectionMatrix();
			const pure nothrow float left();
			const pure nothrow float right();
			const pure nothrow float bottom();
			const pure nothrow float top();
			const pure nothrow float near();
			const pure nothrow float far();
			pure nothrow void left(float value);
			pure nothrow void right(float value);
			pure nothrow void bottom(float value);
			pure nothrow void top(float value);
			pure nothrow void near(float value);
			pure nothrow void far(float value);
		}
	}
}
class PerspectiveProjection : Projection
{
	protected
	{
		Matrix4f mProjectionMatrix;
		bool mIsDirty;
		float mWidth;
		float mHeight;
		float mFov;
		float mNear;
		float mFar;
		pure nothrow void recalculateProjectionMatrix();
		public
		{
			this(float width, float height, float fov, float near = 0.001F, float far = 1000.0F);
			final pure nothrow void setData(float width, float height, float fov, float near = 0.001F, float far = 1000.0F);
			pure nothrow Matrix4f projectionMatrix();
			const pure nothrow float width();
			const pure nothrow float height();
			const pure nothrow float fov();
			const pure nothrow float near();
			const pure nothrow float far();
			pure nothrow void width(float value);
			pure nothrow void height(float value);
			pure nothrow void fov(float value);
			pure nothrow void near(float value);
			pure nothrow void far(float value);
		}
	}
}
