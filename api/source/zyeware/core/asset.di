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
		package(zyeware.core) static
		{
			void initialize();
			void cleanup();
			public static
			{
				T load(T)(string path) if (isAsset!T)
				in (path)
				{
					enum fqn = fullyQualifiedName!T;
					LoadFunction* loader = fqn in sLoaders;
					enforce!CoreException(loader, format!"'%s' was not registered as an asset."(fqn));
					path = TranslationManager.remapAssetPath(path);
					auto uid = AssetUID(fqn, path);
					auto weakref = sCache.get(uid, null).assumeWontThrow;
					if (weakref && weakref.alive)
						return cast(T)weakref.target;
					if (weakref)
						Logger.core.log(LogLevel.debug_, "Asset '%s' (%s) got collected, reloading...", uid.path, uid.typeFQN);
					else
						Logger.core.log(LogLevel.debug_, "Loading asset '%s' (%s)...", uid.path, uid.typeFQN);
					Object asset = loader.callback(path);
					assert(asset, format!"Loader for '%s' returned null!"(T.stringof));
					if (loader.cache)
						sCache[uid] = weakReference(asset);
					return cast(T)asset;
				}
				void register(T)(LoadCallback callback) if (isAsset!T)
				{
					import std.traits : getUDAs;
					auto data = getUDAs!(T, asset)[0];
					sLoaders[fullyQualifiedName!T] = LoadFunction(callback, data.cache);
				}
				bool unregister(T)() if (isAsset!T)
				{
					return sLoaders.remove(fullyQualifiedName!T);
				}
				nothrow bool isCached(T)(string path) if (isAsset!T)
				in (path)
				{
					auto weakref = sCache.get(AssetUID(fullyQualifiedName!T, path), null).assumeWontThrow;
					return weakref && weakref.alive;
				}
				void freeAll();
				nothrow void cleanCache();
			}
		}
	}
}
