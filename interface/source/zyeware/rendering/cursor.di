// D import file generated from 'source/zyeware/rendering/cursor.d'
module zyeware.rendering.cursor;
import zyeware.common;
import zyeware.rendering;
@(asset(Yes.cache))final class Cursor
{
	protected
	{
		const Image mImage;
		Vector2i mHotspot;
		public
		{
			this(const Image image, Vector2i hotspot);
			const pure nothrow const(Image) image();
			const pure nothrow Vector2i hotspot();
			static Cursor load(string path);
		}
	}
}
