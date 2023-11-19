// D import file generated from 'source/zyeware/rendering/environment.d'
module zyeware.rendering.environment;
import zyeware.common;
import zyeware.rendering;
struct Environment3D
{
	Mesh3D sky;
	Color fogColor = Color(0, 0, 0, 0.02);
	Color ambientColor = Color(0.5, 0.5, 0.5, 1);
}
