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

public:
    this(in Vertex2D[] vertices, in uint[] indices, in Material material)
    {
        mVertices = vertices;
        mIndices = indices;
        mMaterial = material;
    }
}