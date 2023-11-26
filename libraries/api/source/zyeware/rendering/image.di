// D import file generated from 'source/zyeware/rendering/image.d'
module zyeware.rendering.image;
import std.string : format;
import std.exception : enforce;
import zyeware.common;
import zyeware.rendering;
@(asset(Yes.cache))class Image
{
	protected
	{
		const(ubyte[]) mPixels;
		ubyte mChannels;
		ubyte mBitsPerChannel;
		Vector2i mSize;
		public
		{
			pure nothrow this(in ubyte[] pixels, ubyte channels, ubyte bitsPerChannel, Vector2i size);
			const pure nothrow Color getPixel(Vector2i coords);
			const pure nothrow const(ubyte[]) pixels();
			const pure nothrow ubyte channels();
			const pure nothrow ubyte bitsPerChannel();
			const pure nothrow Vector2i size();
			static Image load(string path);
			static Image load(in ubyte[] data);
		}
	}
}
