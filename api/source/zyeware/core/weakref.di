// D import file generated from 'source/zyeware/core/weakref.d'
module zyeware.core.weakref;
import core.memory;
import core.atomic;
enum isWeakReferenceable(T) = is(T == class) || is(T == interface) || is(T == delegate);
final class WeakReference(T) if (isWeakReferenceable!T)
{
	this(T target)
	in
	{
		assert(target);
	}
	do
	{
		_data.target = target;
		rt_attachDisposeEvent(_targetToObj(target), &onTargetDisposed);
	}
	const bool alive()
	{
		return !!atomicLoad(_data.ptr);
	}
	inout inout(T) target()
	{
		return _data.getTarget();
	}
	~this()
	{
		import core.exception : InvalidMemoryOperationError;
		try
		{
			if (T t = target)
			{
				rt_detachDisposeEvent(_targetToObj(t), &onTargetDisposed);
			}
		}
		catch(InvalidMemoryOperationError e)
		{
		}
	}
	private
	{
		shared ubyte[T.sizeof] _dataStore;
		inout ref inout(_WeakData!T) _data()
		{
			return _dataStore.viewAs!(_WeakData!T);
		}
		void onTargetDisposed(Object)
		{
			atomicStore(_data.ptr, cast(shared(void*))null);
		}
	}
}
WeakReference!T weakReference(T)(T target) if (isWeakReferenceable!T)
{
	return new WeakReference!T(target);
}
private
{
	alias DisposeEvt = void delegate(Object);
	extern (C)
	{
		Object _d_toObject(void* p);
		void rt_attachDisposeEvent(Object obj, DisposeEvt evt);
		void rt_detachDisposeEvent(Object obj, DisposeEvt evt);
	}
	union _WeakData(T) if (isWeakReferenceable!T)
	{
		T target;
		shared void* ptr;
		inout inout(T) getTarget()
		{
			auto ptr = cast(shared(inout(void*)))atomicLoad((cast(const)this).ptr);
			if (!ptr)
				return null;
			GC.addrOf(cast(void*)-1);
			if (!atomicLoad((cast(const)this).ptr))
				return null;
			inout _WeakData res = {ptr:ptr};
			return res.target;
		}
	}
	inout(Object) _targetToObj(T)(inout T t) if (is(T == class) || is(T == interface))
	{
		return cast(inout(Object))t;
	}
	@system inout(To) viewAs(To, From)(inout(From) val)
	{
		return val.viewAs!To;
	}
	ref @system inout(To) viewAs(To, From)(ref inout(From) val)
	{
		static assert(To.sizeof == From.sizeof, format("Type size mismatch in `viewAs`: %s.sizeof(%s) != %s.sizeof(%s)", To.stringof, To.sizeof, From.stringof, From.sizeof));
		return *cast(inout(To)*)&val;
	}
}
