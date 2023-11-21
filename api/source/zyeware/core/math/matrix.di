// D import file generated from 'source/zyeware/core/math/matrix.d'
module zyeware.core.math.matrix;
import inmath.math;
import inmath.linalg;
import zyeware.common;
alias Quaternionf = Quaternion!float;
alias Matrix4f = Matrix!(float, 4, 4);
alias Matrix3f = Matrix!(float, 3, 3);
alias Matrix2f = Matrix!(float, 2, 2);
pure nothrow Vector2f inverseTransformPoint(in Matrix4f transform, in Vector2f worldPoint);
pure nothrow Vector2f transformPoint(in Matrix4f transform, in Vector2f localPoint);
pure nothrow Vector3f inverseTransformPoint(in Matrix4f transform, in Vector3f worldPoint);
pure nothrow Vector3f transformPoint(in Matrix4f transform, in Vector3f localPoint);
