// D import file generated from 'source/zyeware/rendering/font.d'
module zyeware.rendering.font;
import std.traits : isSomeString;
import std.range : ElementEncodingType;
import bmfont : BMFont = Font, parseFnt;
import zyeware.common;
import zyeware.rendering;
@(asset(Yes.cache))class Font
{
	protected
	{
		const BMFont mBMFont;
		Texture2D[] mPageTextures;
		public
		{
			enum Alignment : uint
			{
				top = 1,
				middle = 1 << 1,
				bottom = 1 << 2,
				left = 1 << 3,
				center = 1 << 4,
				right = 1 << 5,
			}
			this(in BMFont bmFont);
			const pure nothrow int getTextWidth(T)(in T text) if (isSomeString!T)
			in (text)
			{
				int maxLength, lineLength;
				for (size_t i;
				 i < text.length; ++i)
				{
					{
						immutable ElementEncodingType!T c = text[i];
						if (c == '\n')
						{
							lineLength = 0;
							continue;
						}
						immutable short kerning = i > 0 ? mBMFont.getKerning(text[i - 1], text[i]) : 1;
						immutable bmc = mBMFont.getChar(c);
						if (bmc != BMFont.Char.init)
							lineLength += bmc.xadvance + kerning;
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
				return mBMFont.common.lineHeight * lines;
			}
			const nothrow const(BMFont) bmFont();
			const nothrow const(Texture2D) getPageTexture(size_t index);
			static Font load(string path);
		}
	}
}
