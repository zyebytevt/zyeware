module zyeware.utils.memory;

import core.memory : GC;
import std.traits;

/// Destroys the given object and immediately frees it from the GC.
/// Use this function sparingly.
pragma(inline, true) void dispose(T)(T obj)
{
    destroy!false(obj);
    GC.free(cast(void*) obj);
}

auto assumeNoGc(T)(T t) {
    enum attrs = functionAttributes!T | FunctionAttribute.nogc;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}