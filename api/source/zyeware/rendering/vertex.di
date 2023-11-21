// D import file generated from 'source/zyeware/rendering/vertex.d'
module zyeware.rendering.vertex;
import zyeware.core.math.vector;
import zyeware.rendering.color;
struct Vertex2D
{
	Vector2f position = Vector2f.zero;
	Vector2f uv = Vector2f.zero;
	Color color = Color.white;
}
struct Vertex3D
{
	Vector3f position = Vector3f.zero;
	Vector3f normal = Vector3f.zero;
	Vector2f uv = Vector2f.zero;
	Color color = Color.white;
}
