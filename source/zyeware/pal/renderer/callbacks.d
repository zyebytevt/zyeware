module zyeware.pal.renderer.callbacks;

import zyeware.common;
import zyeware.rendering;

struct Renderer2DCallbacks
{
public:
    void function() initialize;
    void function() cleanup;
    void function(in Matrix4f projectionMatrix, in Matrix4f viewMatrix) beginScene;
    void function() endScene;
    void function() flush;
    void function(in Vertex2D[] vertices, in uint[] indices, in Matrix4f transform, in Texture2D texture, in Material material) drawVertices;
    void function(in Rect2f dimensions, in Matrix4f transform, in Color modulate, in Texture2D texture, in Material material, in Rect2f region) drawRectangle;
    void function(in string text, in Font font, in Vector2f position, in Color modulate, ubyte alignment, in Material material) drawString;
    void function(in wstring text, in Font font, in Vector2f position, in Color modulate, ubyte alignment, in Material material) drawWString;
    void function(in dstring text, in Font font, in Vector2f position, in Color modulate, ubyte alignment, in Material material) drawDString;
}

struct Renderer3DCallbacks
{
public:
    void function(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment) beginScene;
    void function() end;
    void function(in Matrix4f transform) submit;
}