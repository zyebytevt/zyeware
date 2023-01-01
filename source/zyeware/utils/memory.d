module zyeware.utils.memory;

import core.memory : GC;

pragma(inline, true)
void dispose(T)(T obj)
{
    destroy!false(obj);
    GC.free(cast(void*) obj);
}