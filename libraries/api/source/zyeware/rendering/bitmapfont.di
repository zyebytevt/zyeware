// D import file generated from 'source/zyeware/rendering/bitmapfont.d'
module zyeware.rendering.bitmapfont;
import std.traits : isSomeString;
import std.array : array;
import std.algorithm : map;
import std.string : format;
import zyeware.zyfont;
import zyeware;
struct BitmapFontProperties
{
	string fontName;
	short fontSize;
	bool isBold;
	bool isItalic;
	short lineHeight;
	ubyte[4] padding;
	ubyte[2] spacing;
	Image[] pages;
	BitmapFont.Glyph[dchar] characters;
	short[ulong] kernings;
	TextureProperties pageTextureProperties;
}
@(asset(Yes.cache))class BitmapFont
{
	protected
	{
		const(BitmapFontProperties) mProperties;
		Texture2D[] mPageTextures;
		public
		{
			struct Glyph
			{
				dchar id;
				ubyte pageIndex;
				Vector2f uv1;
				Vector2f uv2;
				Vector2i size;
				Vector2i offset;
				Vector2i advance;
			}
			enum Alignment : uint
			{
				top = 1,
				middle = 1 << 1,
				bottom = 1 << 2,
				left = 1 << 3,
				center = 1 << 4,
				right = 1 << 5,
			}
			this(in BitmapFontProperties properties);
			const pure nothrow int getTextWidth(T)(in T text) if (isSomeString!T)
			in (text)
			{
				int maxLength, lineLength;
				for (size_t i;
				 i < text.length; ++i)
				{
					{
						immutable dchar c = cast(dchar)text[i];
						if (c == '\n')
						{
							lineLength = 0;
							continue;
						}
						immutable short kerning = i > 0 ? getKerning(cast(dchar)text[i - 1], c) : 0;
						immutable Glyph info = getGlyph(c);
						if (info != Glyph.init)
							lineLength += info.advance.x + kerning;
						if (lineLength > maxLength)
							maxLength = lineLength;
					}
				}
				return maxLength;
			}
			const pure nothrow int getTextHeight(T)(in T text) if (isSomeString!T)
			in (text)
			{
				int lines = 1;
				foreach (c; text)
				{
					if (c == '\n')
						++lines;
				}
				return mProperties.lineHeight * lines;
			}
			const nothrow const(Texture2D) getPageTexture(size_t index);
			const pure nothrow Glyph getGlyph(dchar c);
			const pure nothrow short getKerning(dchar first, dchar second);
			const pure nothrow short lineHeight();
			static BitmapFont load(string path);
		}
	}
}
