module zyeware.rendering.mesh2d;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class Mesh2D : Mesh
{
protected:
    const(Vertex2D[]) mVertices;
    const(uint[]) mIndices;
    const(Material) mMaterial;
    const(Texture2D) mTexture;

public:
    this(in Vertex2D[] vertices, in uint[] indices, in Material material, in Texture2D texture)
    {
        mVertices = vertices;
        mIndices = indices;
        mMaterial = material;
        mTexture = texture;
    }

    const(Vertex2D[]) vertices() pure const nothrow
    {
        return mVertices;
    }

    const(uint[]) indices() pure const nothrow
    {
        return mIndices;
    }

    const(Material) material() pure const nothrow
    {
        return mMaterial;
    }

    const(Texture2D) texture() pure const nothrow
    {
        return mTexture;
    }
}