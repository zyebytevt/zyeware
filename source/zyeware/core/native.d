module zyeware.core.native;

/// A more readable alias for a native handle (a `void*`).
alias NativeHandle = void*;

/// This interface describes an instance that holds a handle (a `void*`) to a native object.
/// This is used to allow the native object to be passed around without having to worry about
/// the actual type of the native object.
interface NativeObject
{
    const(NativeHandle) handle() pure const nothrow;
}