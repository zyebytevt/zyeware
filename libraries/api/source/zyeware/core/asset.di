// D import file generated from 'source/zyeware/core/asset.d'
module zyeware.core.asset;
import std.string : format;
import std.exception : collectException, assumeWontThrow, enforce;
import std.typecons : Tuple;
import std.traits : fullyQualifiedName;
import zyeware.common;
import zyeware.core.weakref;
struct asset
{
	Flag!"cache" cache = Yes.cache;
}
private template isAsset(E)
{
	import std.traits : hasUDA;
	static if (__traits(compiles, hasUDA!(E, asset)))
	{
		enum bool isAsset = hasUDA!(E, asset) && __traits(compiles, cast(E)E.load("test"));
	}
	else
	{
		enum bool isAsset = false;
	}
}
struct AssetManager
{
	@disable this();
	@disable this(this);
	private static
	{
		struct AssetUID
		{
			string typeFQN;
			string path;
		}
		alias LoadCallback = Object function(string);
		alias LoadFunction = Tuple!(LoadCallback, "callback", bool, "cache");
		LoadFunction[string] sLoaders;
		WeakReference!Object[AssetUID] sCache;
		Object load(in AssetUID uid);
		void register(string fqn, LoadCallback callback, bool cache);
		bool unregister(string fqn);
		nothrow bool isCached(in AssetUID uid);
		package(zyeware.core) static
		{
			void initialize();
			void cleanup();
			public static
			{
				pragma (inline, true)T load(T)(string path) if (isAsset!T)
				in (path)
				{
					return cast(T)load(AssetUID(fullyQualifiedName!T, path));
				}
				void register(T)(LoadCallback callback) if (isAsset!T)
				{
					import std.traits : getUDAs;
					auto data = getUDAs!(T, asset)[0];
					register(fullyQualifiedName!T, callback, data.cache);
				}
				bool unregister(T)() if (isAsset!T)
				{
					return unregister(fullyQualifiedName!T);
				}
				nothrow bool isCached(T)(string path) if (isAsset!T)
				in (path)
				{
					return isCached(AssetUID(fullyQualifiedName!T, path));
				}
				void freeAll();
				nothrow void cleanCache();
			}
		}
	}
}
