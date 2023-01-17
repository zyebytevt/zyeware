// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.asset;

import std.string : format;
import std.exception : collectException, assumeWontThrow, enforce;
import std.typecons : Tuple;

import zyeware.common;
import zyeware.core.weakref;

/// UDA to mark an asset to be loaded.
struct asset
{
    Flag!"cache" cache = Yes.cache; /// If this asset should be cached.
}

private template isAsset(E)
{
    import std.traits : hasUDA;

    static if(__traits(compiles, hasUDA!(E, asset)))
        enum bool isAsset = hasUDA!(E, asset) && __traits(compiles, cast(E) E.load("test")) && is(E : Object);
    else
        enum bool isAsset = false;
}

/// Responsible for loading assets into memory. It caches all loaded assets, therefore
/// it will not invoke a loader again as long as the reference in memory is valid.
/// The `AssetManager` will only keep weak references, e.g. it will not cause memory
/// to not be freed.
struct AssetManager
{
    @disable this();
    @disable this(this);

private static:
    struct AssetUID
    {
        string typeMangle;
        string path;
    }

    alias LoadFunction = Tuple!(Object function(string), "callback", bool, "cache");

    LoadFunction[string] sLoaders;
    WeakReference!Object[AssetUID] sCache;

    Object getFromCache(AssetUID uid) nothrow
    {
        auto weakref = sCache.get(uid, null).assumeWontThrow;
        if (weakref && weakref.alive)
            return weakref.target;
        
        return null;
    }

package(zyeware.core) static:
    void initialize()
    {
        //registerDefaultLoaders();
        import zyeware.rendering : Shader, Image, Texture2D, TextureCubeMap, Mesh, Font, Material, SpriteFrames, Cursor;
        import zyeware.core.translation : Translation;
        import zyeware.audio : Audio;

        register!Shader();
        register!Image();
        register!Texture2D();
        register!TextureCubeMap();
        register!Mesh();
        register!Font();
        register!Material();
        register!Translation();
        register!Audio();
        register!SpriteFrames();
        register!Cursor();
    }

    void cleanup()
    {
        freeAll();
    }

public static:
    /// Load the asset at the given path into memory, optionally with a pre-defined
    /// loader format.
    /// 
    /// Params:
    ///     path = The path of the file to load.
    ///     T = The type of Asset to load.
    /// 
    /// Returns: The loaded asset.
    T load(T)(string path)
        if (isAsset!T)
        in (path, "Path cannot be null.")
    {
        LoadFunction* loader = T.mangleof in sLoaders;
        enforce!CoreException(loader, format!"'%s' was not registered as an asset."(T.stringof));

        auto uid = AssetUID(T.mangleof, path);

        // Check if we have it cached, and if so, if it's still alive
        Object asset = getFromCache(uid);
        if (asset)
            return cast(T) asset;

        // Otherwise, load asset
        asset = loader.callback(path);
        assert(asset, format!"Loader for '%s' returned null!"(T.stringof));

        if (loader.cache)
            sCache[uid] = weakReference(asset);

        return cast(T) asset;
    }

    /// Registers a new asset.
    /// 
    /// Params:
    ///     T = The asset type to register.
    void register(T)()
        if (isAsset!T)
    {
        import std.traits : getUDAs;
        auto data = getUDAs!(T, asset)[0];

        sLoaders[T.mangleof] = LoadFunction(&T.load, data.cache);
    }

    /// Unregisters an asset.
    /// 
    /// Params:
    ///     T = The asset type to unregister.
    /// 
    /// Returns: If the loader has been removed.
    bool unregister(T)()
        if (isAsset!T)
    {
        return sLoaders.remove(T.mangleof);
    }

    /// Checks if the given file is already cached.
    /// 
    /// Params:
    ///     T = The type of asset.
    ///     path = The path of the file to check.
    bool isCached(T)(string path) nothrow
        if (isAsset!T)
        in (path, "Path cannot be null.")
    {
        auto weakref = sCache.get(AssetUID(T.mangleof, path), null).assumeWontThrow;
        return weakref && weakref.alive;
    }

    /// Destroys all cached assets.
    void freeAll()
    {
        foreach (weakref; sCache.values)
            if (weakref.alive)
                weakref.target.dispose();

        Logger.core.log(LogLevel.info, "Freed all assets.");
    }

    /// Cleans the cache from assets that have already been garbage collected.
    void cleanCache() nothrow
    {
        size_t cleaned;

        foreach (AssetUID key; sCache.keys)
        {
            if (!sCache[key].alive)
            {
                sCache.remove(key).assumeWontThrow;
                Logger.core.log(LogLevel.trace, "Uncaching '%s'...", key.path);
                ++cleaned;
            }
        }

        Logger.core.log(LogLevel.debug_, "%d assets cleaned from cache.", cleaned);
    }
}