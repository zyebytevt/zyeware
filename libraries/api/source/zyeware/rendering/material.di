// D import file generated from 'source/zyeware/rendering/material.d'
module zyeware.rendering.material;
import std.sumtype : SumType, match;
import std.string : format, startsWith;
import std.exception : enforce;
import std.typecons : Rebindable;
import std.conv : to;
import std.string : split, format;
import std.algorithm : map, filter, sort, uniq;
import std.array : array;
import inmath.linalg;
import zyeware.common;
import zyeware.rendering;
import zyeware.utils.tokenizer;
@(asset(Yes.cache))class Material
{
	protected
	{
		union
		{
			Shader mShader;
			Material mParent;
		}
		bool mIsRoot;
		Rebindable!(const(Texture))[] mTextureSlots;
		Parameter[string] mParameters;
		public
		{
			alias Parameter = SumType!(void[], int, float, Vector2f, Vector3f, Vector4f);
			this(Shader shader, size_t textureSlots = 1);
			this(Material parent);
			void setParameter(string name, Parameter value);
			void setParameter(T)(string name, T value)
			in (name)
			{
				setParameter(Parameter(value));
			}
			inout ref inout(Parameter) getParameter(string name);
			nothrow bool removeParameter(string name);
			void setTexture(size_t idx, in Texture texture);
			const const(Texture) getTexture(size_t idx);
			void removeTexture(size_t idx);
			const nothrow string[] parameterList();
			inout nothrow inout(Material) parent();
			inout nothrow inout(Material) root();
			inout nothrow inout(Shader) shader();
			static Material load(string path);
		}
	}
}
