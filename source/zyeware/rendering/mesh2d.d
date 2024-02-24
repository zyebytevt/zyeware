module zyeware.rendering.Mesh2d;

import zyeware;

@asset(Yes.cache)
class Mesh2d : Mesh {
protected:
    const(Vertex2d[]) mVertices;
    const(uint[]) mIndices;
    const(Material) mMaterial;
    const(Texture2d) mTexture;

public:
    this(in Vertex2d[] vertices, in uint[] indices, in Material material, in Texture2d texture) {
        mVertices = vertices;
        mIndices = indices;
        mMaterial = material;
        mTexture = texture;
    }

    const(Vertex2d[]) vertices() pure const nothrow {
        return mVertices;
    }

    const(uint[]) indices() pure const nothrow {
        return mIndices;
    }

    const(Material) material() pure const nothrow {
        return mMaterial;
    }

    const(Texture2d) texture() pure const nothrow {
        return mTexture;
    }
}
