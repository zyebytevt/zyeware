// D import file generated from 'source/zyeware/core/exception.d'
module zyeware.core.exception;
private enum CreateGenericExceptionType(string name) = "class " ~ name ~ " : Exception\n    {\n        this(string message, string file = __FILE__,\n            size_t line = __LINE__, Throwable next = null) pure nothrow\n        {\n            super(message, file, line, next);\n        }\n    }";
mixin(CreateGenericExceptionType!"CoreException");
mixin(CreateGenericExceptionType!"VFSException");
mixin(CreateGenericExceptionType!"AudioException");
mixin(CreateGenericExceptionType!"GraphicsException");
mixin(CreateGenericExceptionType!"RenderException");
mixin(CreateGenericExceptionType!"EntityException");
mixin(CreateGenericExceptionType!"ComponentException");
mixin(CreateGenericExceptionType!"SystemException");
mixin(CreateGenericExceptionType!"GUIException");
