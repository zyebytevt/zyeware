// D import file generated from 'source/zyeware/rendering/camera.d'
module zyeware.rendering.camera;
import zyeware.common;
import zyeware.rendering;
interface Camera
{
	public
	{
		const pure nothrow Matrix4f projectionMatrix();
		pragma (inline, true)static final pure nothrow Matrix4f calculateViewMatrix(Vector3f position, Quaternionf rotation)
		{
			return (Matrix4f.translation(position) * rotation.toMatrix!(4, 4)).inverse;
		}
	}
}
class OrthographicCamera : Camera
{
	protected
	{
		Matrix4f mProjectionMatrix;
		public
		{
			pure nothrow this(float left, float right, float bottom, float top, float near = -1.0F, float far = 1.0F);
			final pure nothrow void setData(float left, float right, float bottom, float top, float near = -1.0F, float far = 1.0F);
			const pure nothrow Matrix4f projectionMatrix();
		}
	}
}
class PerspectiveCamera : Camera
{
	protected
	{
		Matrix4f mProjectionMatrix;
		public
		{
			this(float width, float height, float fov, float near = 0.001F, float far = 1000.0F);
			final pure nothrow void setData(float width, float height, float fov, float near = 0.001F, float far = 1000.0F);
			const pure nothrow Matrix4f projectionMatrix();
		}
	}
}
