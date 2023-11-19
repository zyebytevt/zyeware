// D import file generated from 'source/zyeware/rendering/mesh3d.d'
module zyeware.rendering.mesh3d;
import std.string : format;
import std.path : extension;
import std.conv : to;
import std.typecons : Rebindable;
import inmath.linalg;
import zyeware.common;
import zyeware.rendering;
import zyeware.pal;
interface Mesh
{
}
@(asset(Yes.cache))class Mesh3D : Mesh, NativeObject
{
	protected
	{
		NativeHandle mNativeHandle;
		Rebindable!(const(Material)) mMaterial;
		pragma (inline, true)static pure nothrow Vector3f calculateSurfaceNormal(Vector3f p1, Vector3f p2, Vector3f p3)
		{
			immutable Vector3f u = p2 - p1;
			immutable Vector3f v = p3 - p1;
			return u.cross(v);
		}
		static pure nothrow void calculateNormals(ref Vertex3D[] vertices, in uint[] indices);
		public
		{
			this(in Vertex3D[] vertices, in uint[] indices, in Material material);
			~this();
			const pure nothrow const(void)* handle();
			static Mesh3D load(string path);
		}
	}
}
private Mesh3D loadFromOBJFile(string path);
