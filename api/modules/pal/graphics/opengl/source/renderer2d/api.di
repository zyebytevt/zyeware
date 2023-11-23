// D import file generated from 'modules/pal/graphics/opengl/source/renderer2d/api.d'
module zyeware.pal.graphics.opengl.renderer2d.api;
import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;
import bindbc.opengl;
import bmfont : BMFont = Font;
import zyeware.common;
import zyeware.rendering;
import zyeware.pal.graphics.types;
import zyeware.pal.graphics.opengl.api.api;
import zyeware.pal.graphics.opengl.renderer2d.types;
package(zyeware.pal.graphics.opengl)
{
	enum maxMaterialsPerDrawCall = 8;
	enum maxTexturesPerBatch = 8;
	enum maxVerticesPerBatch = 20000;
	enum maxIndicesPerBatch = 30000;
	struct Batch
	{
		Rebindable!(const(Material)) material;
		BatchVertex2D[] vertices;
		uint[] indices;
		Rebindable!(const(Texture2D))[] textures;
		size_t currentVertexCount = 0;
		size_t currentIndexCount = 0;
		size_t currentTextureCount = 1;
		nothrow size_t getIndexForTexture(in Texture2D texture);
		void flush(in GlBuffer buffer);
	}
	extern GlBuffer[2] pRenderBuffers;
	extern Batch[] pBatches;
	extern size_t currentMaterialCount;
	extern Matrix4f pProjectionViewMatrix;
	extern Texture2D pWhiteTexture;
	extern Material pDefaultMaterial;
	nothrow size_t getIndexForMaterial(in Material material);
	void createBuffer(ref GlBuffer buffer);
	void drawStringImpl(T)(in T text, in Font font, in Vector2f position, in Color modulate, ubyte alignment, in Material material) if (isSomeString!T)
	{
		Vector2f cursor = Vector2f.zero;
		if (alignment & Font.Alignment.middle || alignment & Font.Alignment.bottom)
		{
			immutable int height = font.getTextHeight(text);
			cursor.y -= alignment & Font.Alignment.middle ? height / 2 : height;
		}
		foreach (T line; text.lineSplitter)
		{
			if (alignment & Font.Alignment.center || alignment & Font.Alignment.right)
			{
				immutable int width = font.getTextWidth(line);
				cursor.x = -(alignment & Font.Alignment.center ? width / 2 : width);
			}
			else
				cursor.x = 0;
			for (size_t i;
			 i < line.length; ++i)
			{
				{
					switch (line[i])
					{
						case '\t':
						{
							cursor.x += 40;
							break;
						}
						default:
						{
							BMFont.Char c = font.bmFont.getChar(line[i]);
							if (c == BMFont.Char.init)
								break;
							immutable int kerning = i > 0 ? font.bmFont.getKerning(line[i - 1], line[i]) : 1;
							if (c.width > 0 && (c.height > 0))
							{
								const(Texture2D) pageTexture = font.getPageTexture(c.page);
								immutable Vector2f size = pageTexture.size;
								immutable Rect2f region = Rect2f(cast(float)c.x / size.x, cast(float)c.y / size.y, cast(float)c.width / size.x, cast(float)c.height / size.y);
								drawRectangle(Rect2f(0, 0, c.width, c.height), Matrix4f.translation(Vector3f(Vector2f(position + cursor + Vector2f(c.xoffset, c.yoffset)), 0)), modulate, pageTexture, material, region);
							}
							cursor.x += c.xadvance + kerning;
						}
					}
				}
			}
			cursor.y += font.bmFont.common.lineHeight;
		}
	}
	void initializeBatch(ref Batch batch);
	void initialize();
	void cleanup();
	void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix);
	void endScene();
	void flush();
	void drawVertices(in Vertex2D[] vertices, in uint[] indices, in Matrix4f transform, in Texture2D texture = null, in Material material = null);
	void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1), in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1));
	void drawString(in string text, in Font font, in Vector2f position, in Color modulate = Color.white, ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null);
	void drawWString(in wstring text, in Font font, in Vector2f position, in Color modulate = Color.white, ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null);
	void drawDString(in dstring text, in Font font, in Vector2f position, in Color modulate = Color.white, ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null);
}
