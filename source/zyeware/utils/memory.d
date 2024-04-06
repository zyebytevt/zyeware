module zyeware.utils.memory;

import core.memory : GC;

/// Destroys the given object and immediately frees it from the GC.
/// Use this function sparingly.
pragma(inline, true) void dispose(T)(T obj)
{
    destroy!false(obj);
    GC.free(cast(void*) obj);
}
