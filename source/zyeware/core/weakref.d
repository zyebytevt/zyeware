// Weak references reimplemented and fitted for ZyeWare from unstd
module zyeware.core.weakref;

import core.memory;
import core.atomic;

/**
Detect whether a weak reference to type $(D T) can be created.

A weak reference can be created for a $(D class), $(D interface), or $(D delegate).

Warning:
$(D delegate) context must be a class instance.
I.e. creating a weak reference for a $(D delegate) created from a $(D struct)
member function will result in undefined behavior.

$(RED Weak reference will not work for closures) unless enhancement $(DBUGZILLA 9601)
is implemented as now regular D objects aren't created on closures.
*/
enum isWeakReferenceable(T) = is(T == class) || is(T == interface) || is(T == delegate);

/**
Implements weak reference.

Note: The class contains a pointer to a target object thus it behaves as
a normal reference if placed in GC block without $(D NO_SCAN) attribute.

Tip: This behaves like C#'s short weak reference or Java's weak reference.
*/
final class WeakReference(T) if (isWeakReferenceable!T) {
	/* Create weak reference for $(D target).

	Preconditions:
	$(D target !is null)
	*/
	this(T target)
	in {
		assert(target);
	}
	do {
		_data.target = target;
		rt_attachDisposeEvent(_targetToObj(target), &onTargetDisposed);
	}

	/// Determines whether referenced object is finalized.
	bool alive() const {
		return !!atomicLoad(_data.ptr);
	}

	/**
	Returns referenced object if it isn't finalized
	thus creating a strong reference to it.
	Returns null otherwise.
	*/
	inout(T) target() inout {
		return _data.getTarget();
	}

	~this() {
		// This is a really dirty solution to the problem, but since
		// this *only* happens when the application exits, I suppose
		// I can catch it without major consequences.
		import core.exception : InvalidMemoryOperationError;

		try {
			if (T t = target) {
				rt_detachDisposeEvent(_targetToObj(t), &onTargetDisposed);
			}
		} catch (InvalidMemoryOperationError e) {
		}
	}

private:
	shared ubyte[T.sizeof] _dataStore;

	ref inout(_WeakData!T) _data() inout {
		return _dataStore.viewAs!(_WeakData!T);
	}

	void onTargetDisposed(Object) {
		atomicStore(_data.ptr, cast(shared void*) null);
	}
}

/// Convenience function that returns a $(D WeakReference!T) object for $(D target).
WeakReference!T weakReference(T)(T target) if (isWeakReferenceable!T) {
	return new WeakReference!T(target);
}

private:

alias DisposeEvt = void delegate(Object);

extern (C) {
	Object _d_toObject(void* p);
	void rt_attachDisposeEvent(Object obj, DisposeEvt evt);
	void rt_detachDisposeEvent(Object obj, DisposeEvt evt);
}

union _WeakData(T) if (isWeakReferenceable!T) {
	T target;
	shared void* ptr;

	// Returns referenced object if it isn't finalized.
	inout(T) getTarget() inout {
		auto ptr = cast(inout shared void*) atomicLoad( /*de-inout*/ (cast(const) this).ptr);
		if (!ptr)
			return null;

		// Note: this is an implementation dependent GC fence as there
		// is no guarantee `addrOf` will really lock GC mutex.
		GC.addrOf(cast(void*)-1);

		// We have strong reference to ptr here so just test
		// whether we are still alive:
		if (!atomicLoad( /*de-inout*/ (cast(const) this).ptr))
			return null;

		// We have to use obtained reference to ptr in result:
		inout _WeakData res = {ptr: ptr};
		return res.target;
	}
}

inout(Object) _targetToObj(T)(inout T t) if (is(T == class) || is(T == interface)) {
	return cast(inout(Object)) t;
}

inout(To) viewAs(To, From)(inout(From) val) @system {
	return val.viewAs!To;
}

/// ditto
ref inout(To) viewAs(To, From)(ref inout(From) val) @system {
	static assert(To.sizeof == From.sizeof, format("Type size mismatch in `viewAs`: %s.sizeof(%s) != %s.sizeof(%s)",
			To.stringof, To.sizeof, From.stringof, From.sizeof));
	return *cast(inout(To)*)&val;
}
