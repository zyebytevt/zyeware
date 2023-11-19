// D import file generated from 'source/zyeware/pal/graphics/opengl/api.d'
module zyeware.pal.graphics.opengl.api;
import zyeware.pal.graphics.callbacks;
version (ZW_OpenGL)
{
	import std.typecons : Tuple;
	import std.exception : assumeWontThrow;
	import std.string : format, toStringz;
	import bindbc.opengl;
	import zyeware.common;
	import zyeware.rendering;
	import zyeware.pal;
	import zyeware.pal.graphics.opengl.shader;
	import zyeware.pal.graphics.types;
	private
	{
		struct SequentialBuffer(T)
		{
			private
			{
				T[] mBuffer = new T[8];
				public
				{
					nothrow T* add(in T value)
					{
						for (size_t i;
						 i < mBuffer.length; ++i)
						{
							{
								if (mBuffer[i] == T.init)
								{
									mBuffer[i] = value;
									return &mBuffer[i];
								}
							}
						}
						size_t oldLength = mBuffer.length;
						mBuffer.length *= 2;
						mBuffer[oldLength] = value;
						return &mBuffer[oldLength];
					}
					nothrow T[] data()
					{
						return mBuffer[0..mBuffer.length];
					}
				}
			}
		}
		struct MeshData
		{
			uint vao;
			uint vbo;
			uint ibo;
		}
		struct FramebufferData
		{
			uint id;
			uint colorAttachmentId;
			uint depthAttachmentId;
		}
		extern bool[RenderFlag] pFlagValues;
		version (Windows)
		{
			extern (Windows) static nothrow void palGlErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam);
		}
		else
		{
			extern (C) static nothrow void palGlErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam);
		}
		pragma (inline, true)nothrow void palGlErrorCallbackImpl(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam)
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
			Logger.core.log(logLevel, "%s: %s", typeName, cast(string)message[0..length]);
		}
		GLuint palGlGetGLFilter(TextureProperties.Filter filter);
		GLuint palGlGetGLWrapMode(TextureProperties.WrapMode wrapMode);
		void palGlInitialize();
		void palGlLoadLibs();
		void palGlCleanup();
		package(zyeware.pal)
		{
			NativeHandle palGlCreateMesh(in Vertex3D[] vertices, in uint[] indices);
			NativeHandle palGlCreateTexture2D(in Image image, in TextureProperties properties);
			NativeHandle palGlCreateTextureCubeMap(in Image[6] images, in TextureProperties properties);
			NativeHandle palGlCreateFramebuffer(in FramebufferProperties properties);
			NativeHandle palGlCreateShader(in ShaderProperties properties);
			nothrow void palGlFreeMesh(NativeHandle mesh);
			nothrow void palGlFreeTexture2D(NativeHandle texture);
			nothrow void palGlFreeTextureCubeMap(NativeHandle texture);
			nothrow void palGlFreeFramebuffer(NativeHandle framebuffer);
			nothrow void palGlFreeShader(NativeHandle shader);
			nothrow void palGlSetViewport(Rect2i region);
			nothrow void palGlSetRenderFlag(RenderFlag flag, bool value);
			nothrow bool palGlGetRenderFlag(RenderFlag flag);
			nothrow size_t palGlGetRenderCapability(RenderCapability capability);
			nothrow void palGlClearScreen(Color clearColor);
			nothrow void palGlSetRenderTarget(in NativeHandle target);
			nothrow void palGlPresentToScreen(in NativeHandle framebuffer, Rect2i srcRegion, Rect2i dstRegion);
			nothrow NativeHandle palGlGetTextureFromFramebuffer(in NativeHandle framebuffer);
			public GraphicsPALCallbacks palGlGenerateCallbacks();
		}
	}
}
