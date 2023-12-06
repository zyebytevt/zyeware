// D import file generated from 'source/zyeware/rendering/shader.d'
module zyeware.rendering.shader;
import std.exception : enforce;
import std.regex : ctRegex, matchAll;
import std.typecons : Tuple;
import std.array : replaceInPlace;
import std.algorithm : countUntil;
import inmath.linalg;
import zyeware;
import zyeware.pal;
import zyeware.utils.tokenizer;
struct ShaderProperties
{
	enum ShaderType
	{
		vertex,
		fragment,
		geometry,
		compute,
	}
	string[ShaderType] sources;
}
@(asset(Yes.cache))class Shader : NativeObject
{
	protected
	{
		NativeHandle mNativeHandle;
		ShaderProperties mProperties;
		public
		{
			this(ShaderProperties properties);
			~this();
			const pure nothrow const(NativeHandle) handle();
			static Shader load(string path);
		}
	}
}
