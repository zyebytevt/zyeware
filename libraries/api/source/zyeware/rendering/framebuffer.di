// D import file generated from 'source/zyeware/rendering/framebuffer.d'
module zyeware.rendering.framebuffer;
import std.exception : enforce;
import zyeware;
import zyeware.pal;
struct FramebufferProperties
{
	enum UsageType
	{
		swapChainTarget,
		texture,
	}
	Vector2i size;
	UsageType usageType = UsageType.swapChainTarget;
}
class Framebuffer : NativeObject
{
	protected
	{
		NativeHandle mNativeHandle;
		FramebufferProperties mProperties;
		public
		{
			this(in FramebufferProperties properties);
			~this();
			void recreate(in FramebufferProperties properties);
			Texture2D getTexture2D();
			const pure nothrow const(NativeHandle) handle();
			const pure nothrow const(FramebufferProperties) properties();
		}
	}
}
