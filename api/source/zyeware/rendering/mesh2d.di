// D import file generated from 'source/zyeware/rendering/mesh2d.d'
module zyeware.rendering.mesh2d;
import zyeware.common;
import zyeware.rendering;
@(asset(Yes.cache))class Mesh2D : Mesh
{
	protected
	{
		const(Vertex2D[]) mVertices;
		const(uint[]) mIndices;
		const(Material) mMaterial;
		const(Texture2D) mTexture;
		public
		{
			this(in Vertex2D[] vertices, in uint[] indices, in Material material, in Texture2D texture);
			const pure nothrow const(Vertex2D[]) vertices();
			const pure nothrow const(uint[]) indices();
			const pure nothrow const(Material) material();
			const pure nothrow const(Texture2D) texture();
		}
	}
}
