// D import file generated from 'source/zyeware/pal/graphics/opengl/shader.d'
module zyeware.pal.graphics.opengl.shader;
import std.string : toStringz;
import std.exception : assumeWontThrow;
import bindbc.opengl;
import zyeware.common;
import zyeware.rendering;
private
{
	struct UniformLocationKey
	{
		uint id;
		string name;
	}
	extern uint[UniformLocationKey] pUniformLocationCache;
	nothrow uint palGlPrepareShaderUniformAssignAndGetLocation(in NativeHandle shader, string name);
	package(zyeware.pal)
	{
		nothrow void palGlSetShaderUniform1f(in NativeHandle shader, in string name, in float value);
		nothrow void palGlSetShaderUniform2f(in NativeHandle shader, in string name, in Vector2f value);
		nothrow void palGlSetShaderUniform3f(in NativeHandle shader, in string name, in Vector3f value);
		nothrow void palGlSetShaderUniform4f(in NativeHandle shader, in string name, in Vector4f value);
		nothrow void palGlSetShaderUniform1i(in NativeHandle shader, in string name, in int value);
		nothrow void palGlSetShaderUniformMat4f(in NativeHandle shader, in string name, in Matrix4f value);
	}
}
