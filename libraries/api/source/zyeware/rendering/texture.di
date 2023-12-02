// D import file generated from 'source/zyeware/rendering/texture.d'
module zyeware.rendering.texture;
import std.conv : to;
import std.string : format;
import std.algorithm : countUntil;
import zyeware.common;
import zyeware.rendering;
import zyeware.pal;
import zyeware.utils.tokenizer;
struct TextureProperties
{
	enum Filter
	{
		nearest,
		linear,
		bilinear,
		trilinear,
	}
	enum WrapMode
	{
		repeat,
		mirroredRepeat,
		clampToEdge,
	}
	Filter minFilter;
	Filter magFilter;
	WrapMode wrapS;
	WrapMode wrapT;
	bool generateMipmaps = true;
}
interface Texture : NativeObject
{
	const pure nothrow const(TextureProperties) properties();
}
@(asset(Yes.cache))class Texture2D : Texture
{
	protected
	{
		NativeHandle mNativeHandle;
		TextureProperties mProperties;
		Vector2i mSize;
		package(zyeware)
		{
			nothrow this(NativeHandle handle, in Vector2i size, in TextureProperties properties = TextureProperties.init);
			public
			{
				this(in Image image, in TextureProperties properties = TextureProperties.init);
				~this();
				const pure nothrow const(TextureProperties) properties();
				const pure nothrow const(NativeHandle) handle();
				const pure nothrow const(Vector2i) size();
				static Texture2D load(string path);
			}
		}
	}
}
@(asset(Yes.cache))class TextureCubeMap : Texture
{
	protected
	{
		NativeHandle mNativeHandle;
		TextureProperties mProperties;
		public
		{
			this(in Image[6] images, in TextureProperties properties = TextureProperties.init);
			~this();
			const pure nothrow const(TextureProperties) properties();
			const pure nothrow const(NativeHandle) handle();
			static TextureCubeMap load(string path);
		}
	}
}
private void parseTextureProperties(string path, out TextureProperties properties);
