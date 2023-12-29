// This file was generated by ZyeWare APIgen. Do not edit!
module zyeware.core.weakref;


import core.memory;
import core.atomic;

/// Implements weak reference.
/// 
/// Note: The class contains a pointer to a target object thus it behaves as
/// a normal reference if placed in GC block without $(D NO_SCAN) attribute.
/// 
/// Tip: This behaves like C#'s short weak reference or Java's weak reference.
final class WeakReference(T) 
if(isWeakReferenceable!T) {

this(T target)
in {
assert (target);
}
do {
_data.target = target;
rt_attachDisposeEvent(_targetToObj(target), &onTargetDisposed);
}

/// Determines whether referenced object is finalized.
bool alive() const;

/// Returns referenced object if it isn't finalized
/// thus creating a strong reference to it.
/// Returns null otherwise.
inout(T) target() inout;

~this() {
import core.exception : InvalidMemoryOperationError;


try {
if (T t = target) {
rt_detachDisposeEvent(_targetToObj(t), &onTargetDisposed);
}
} catch(InvalidMemoryOperationError e) {}
}

private:

shared ubyte[T.sizeof] _dataStore;

ref inout(_WeakData!T) _data() inout;

void onTargetDisposed(Object);
}

/// Convenience function that returns a $(D WeakReference!T) object for $(D target).
WeakReference!T weakReference(T)(T target) 
if(isWeakReferenceable!T) {
return new WeakReference!T(target);
}

private:
alias DisposeEvt = void delegate(Object);extern (C)  {

Object _d_toObject(void* p);

void rt_attachDisposeEvent(Object obj, DisposeEvt evt);

void rt_detachDisposeEvent(Object obj, DisposeEvt evt);
}

union _WeakData(T) 
if(isWeakReferenceable!T) {

T target;

shared void* ptr;

inout(T) getTarget() inout;
}

inout(Object) _targetToObj(T)(inout T t) 
if(is(T == class) || is(T == interface)) {
return cast(inout(Object))t;
}

inout(To) viewAs(To, From)(inout(From) val) @system {
return val.viewAs!To;
}

/// ditto
ref inout(To) viewAs(To, From)(ref inout(From) val) @system {
static assert (To.sizeof == From.sizeof, format("Type size mismatch in `viewAs`: %s.sizeof(%s) != %s.sizeof(%s)", To.stringof, To.sizeof, From.stringof, From.sizeof));
return *cast(inout(To)*)&val;
}