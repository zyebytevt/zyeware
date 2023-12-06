// D import file generated from 'source/zyeware/rendering/renderer3d.d'
module zyeware.rendering.renderer3d;
import std.typecons : Rebindable;
import std.exception : enforce;
import zyeware;
import zyeware.pal;
struct Renderer3D
{
	@disable this();
	@disable this(this);
	public static
	{
		pragma (inline, true)nothrow void clearScreen(in Color clearColor)
		{
			Pal.graphics.api.clearScreen(clearColor);
		}
		void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment);
		void end();
		void submit(in Matrix4f transform);
	}
}
