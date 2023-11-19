// D import file generated from 'source/zyeware/rendering/renderer2d.d'
module zyeware.rendering.renderer2d;
import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;
import std.exception : enforce;
import bmfont : BMFont = Font;
import zyeware.common;
import zyeware.core.debugging.profiler;
import zyeware.rendering;
import zyeware.pal.renderer.callbacks;
import zyeware.pal;
struct Renderer2D
{
	@disable this();
	@disable this(this);
	package(zyeware) static
	{
		void initialize();
		void cleanup();
		public static
		{
			void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix);
			void endScene();
			void flush();
			void drawMesh(in Mesh2D mesh, in Matrix4f transform);
			pragma (inline, true)void drawRectangle(in Rect2f dimensions, in Vector2f position, in Vector2f scale, in Color modulate = Color.white, in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
			{
				PAL.renderer2D.drawRectangle(dimensions, Matrix4f.translation(Vector3f(position, 0)) * Matrix4f.scaling(scale.x, scale.y, 1), modulate, texture, material, region);
			}
			pragma (inline, true)void drawRectangle(in Rect2f dimensions, in Vector2f position, in Vector2f scale, float rotation, in Color modulate = Vector4f(1), in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
			{
				PAL.renderer2D.drawRectangle(dimensions, Matrix4f.translation(Vector3f(position, 0)) * Matrix4f.rotation(rotation, Vector3f(0, 0, 1)) * Matrix4f.scaling(scale.x, scale.y, 1), modulate, texture, material, region);
			}
			void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1), in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1));
			void drawString(T)(in T text, in Font font, in Vector2f position, in Color modulate = Color.white, ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null) if (isSomeString!T)
			{
				static if (is(T == string))
				{
					PAL.renderer2D.drawString(text, font, position, modulate, alignment, material);
				}
				else
				{
					static if (is(T == wstring))
					{
						PAL.renderer2D.drawWString(text, font, position, modulate, alignment, material);
					}
					else
					{
						static if (is(T == dstring))
						{
							PAL.renderer2D.drawDString(text, font, position, modulate, alignment, material);
						}
						else
						{
							static assert(false, "Unsupported string type for rendering");
						}
					}
				}
			}
		}
	}
}
