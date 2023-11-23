// D import file generated from 'modules/pal/graphics/opengl/source/api/api.d'
module zyeware.pal.graphics.opengl.api.api;
import std.typecons : Tuple;
import std.exception : assumeWontThrow;
import std.string : format, toStringz, fromStringz;
import bindbc.opengl;
import zyeware.common;
import zyeware.rendering;
import zyeware.pal;
import zyeware.pal.graphics.types;
import zyeware.pal.graphics.opengl.api.types;
import zyeware.pal.graphics.opengl.api.utils;
package(zyeware.pal.graphics.opengl)
{
	extern bool[cast(size_t)RenderFlag.max + 1] pFlagValues;
	extern uint[UniformLocationKey] pUniformLocationCache;
	version (Windows)
	{
		extern (Windows) static nothrow void errorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam);
	}
	else
	{
		extern (C) static nothrow void errorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam);
	}
	nothrow uint prepareShaderUniformAssignAndGetLocation(in NativeHandle shader, string name);
	pragma (inline, true)static nothrow void errorCallbackImpl(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam)
	{
		glGetError();
		string typeName;
		LogLevel logLevel;
		switch (type)
		{
			case GL_DEBUG_TYPE_ERROR:
			{
				typeName = "Error";
				break;
			}
			case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
			{
				typeName = "Deprecated Behavior";
				break;
			}
			case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
			{
				typeName = "Undefined Behavior";
				break;
			}
			case GL_DEBUG_TYPE_PERFORMANCE:
			{
				typeName = "Performance";
				break;
			}
			case GL_DEBUG_TYPE_OTHER:
			{
			}
			default:
			{
				return ;
			}
		}
		switch (severity)
		{
			case GL_DEBUG_SEVERITY_LOW:
			{
				logLevel = LogLevel.info;
				break;
			}
			case GL_DEBUG_SEVERITY_MEDIUM:
			{
				logLevel = LogLevel.warning;
				break;
			}
			case GL_DEBUG_SEVERITY_HIGH:
			{
				logLevel = LogLevel.error;
				break;
			}
			default:
			{
				logLevel = LogLevel.debug_;
				break;
			}
		}
		Logger.pal.log(logLevel, "%s: %s", typeName, cast(string)message[0..length]);
	}
	void initialize();
	void cleanup();
	NativeHandle createMesh(in Vertex3D[] vertices, in uint[] indices);
	NativeHandle createTexture2D(in Image image, in TextureProperties properties);
	NativeHandle createTextureCubeMap(in Image[6] images, in TextureProperties properties);
	NativeHandle createFramebuffer(in FramebufferProperties properties);
	NativeHandle createShader(in ShaderProperties properties);
	nothrow void freeMesh(NativeHandle mesh);
	nothrow void freeTexture2D(NativeHandle texture);
	nothrow void freeTextureCubeMap(NativeHandle texture);
	nothrow void freeFramebuffer(NativeHandle framebuffer);
	nothrow void freeShader(NativeHandle shader);
	nothrow void setViewport(Rect2i region);
	nothrow void setRenderFlag(RenderFlag flag, bool value);
	nothrow bool getRenderFlag(RenderFlag flag);
	nothrow size_t getCapability(RenderCapability capability);
	nothrow void clearScreen(Color clearColor);
	nothrow void setRenderTarget(in NativeHandle target);
	nothrow void presentToScreen(in NativeHandle framebuffer, Rect2i srcRegion, Rect2i dstRegion);
	nothrow NativeHandle getTextureFromFramebuffer(in NativeHandle framebuffer);
	nothrow void setShaderUniform1f(in NativeHandle shader, in string name, in float value);
	nothrow void setShaderUniform2f(in NativeHandle shader, in string name, in Vector2f value);
	nothrow void setShaderUniform3f(in NativeHandle shader, in string name, in Vector3f value);
	nothrow void setShaderUniform4f(in NativeHandle shader, in string name, in Vector4f value);
	nothrow void setShaderUniform1i(in NativeHandle shader, in string name, in int value);
	nothrow void setShaderUniformMat4f(in NativeHandle shader, in string name, in Matrix4f value);
}
