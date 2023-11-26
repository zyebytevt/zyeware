// D import file generated from 'source/zyeware/core/exception.d'
module zyeware.core.exception;
private template GenericExceptionCtor()
{
	pure nothrow this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
	{
		super(message, file, line, next);
	}
}
class CoreException : Exception
{
	mixin GenericExceptionCtor!();
}
class VFSException : Exception
{
	mixin GenericExceptionCtor!();
}
class ResourceException : Exception
{
	mixin GenericExceptionCtor!();
}
class DisplayException : Exception
{
	mixin GenericExceptionCtor!();
}
class AudioException : Exception
{
	mixin GenericExceptionCtor!();
}
class GraphicsException : Exception
{
	mixin GenericExceptionCtor!();
}
class RenderException : Exception
{
	mixin GenericExceptionCtor!();
}
