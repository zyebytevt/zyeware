// D import file generated from 'source/zyeware/core/math/vector.d'
module zyeware.core.math.vector;
import inmath.math;
import inmath.linalg;
public import inmath.linalg : dot, cross;
import inmath.util : isVector;
import zyeware;
alias Vector2f = Vector!(float, 2);
alias Vector2i = Vector!(int, 2);
alias Vector3f = Vector!(float, 3);
alias Vector3i = Vector!(int, 3);
alias Vector4f = Vector!(float, 4);
alias Vector4i = Vector!(int, 4);
alias cross3d = cross;
pure nothrow @safe T.vt cross2d(T)(const T veca, const T vecb) if (isVector!T && (T.dimension == 2))
{
	return veca.x * vecb.y - veca.y * vecb.x;
}
pure nothrow float calculateBaryCentricHeight(Vector3f p1, Vector3f p2, Vector3f p3, Vector2f position);
