// D import file generated from 'source/zyeware/rendering/texatlas.d'
module zyeware.rendering.texatlas;
import zyeware.common;
import zyeware.rendering;
struct TextureAtlas
{
	private
	{
		Texture2D mTexture;
		size_t mHFrames;
		size_t mVFrames;
		public
		{
			pure nothrow this(Texture2D texture, size_t hFrames, size_t vFrames);
			pure nothrow Rect2f getRegionForFrame(size_t frame);
			pure nothrow Vector2f spriteSize();
			inout pure nothrow inout(Texture2D) texture();
		}
	}
}
