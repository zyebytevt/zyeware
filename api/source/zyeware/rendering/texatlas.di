// D import file generated from 'source/zyeware/rendering/texatlas.d'
module zyeware.rendering.texatlas;
import zyeware.common;
import zyeware.rendering;
struct TextureAtlas
{
	private
	{
		Texture2D mTexture;
		Rect2f mRegion = Rect2f(0, 0, 1, 1);
		size_t mHFrames;
		size_t mVFrames;
		size_t mFrame;
		public
		{
			pure nothrow this(Texture2D texture);
			pure nothrow this(Texture2D texture, Rect2f region);
			pure nothrow this(Texture2D texture, size_t hFrames, size_t vFrames, size_t frame);
			pure nothrow void region(in Rect2f value);
			const pure nothrow Rect2f region();
			pure nothrow void frame(size_t value);
			const pure nothrow size_t frame();
			inout pure nothrow inout(Texture2D) texture();
		}
	}
}
