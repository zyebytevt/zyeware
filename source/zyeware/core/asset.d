// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.asset;

import std.string : format;
import std.exception : collectException, assumeWontThrow, enforce;
import std.typecons : Tuple;
import std.traits : fullyQualifiedName;

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
        enum bool isAsset = hasUDA!(E, asset) && __traits(compiles, cast(E) E.load("test"));// && is(E : Object);
    else
        enum bool isAsset = false;
}

/// Responsible for loading assets into memory. It caches all loaded assets, therefore
/// it will not invoke a loader again as long as the reference in memory is valid.
/// The `AssetManager` will only keep weak references, e.g. it will not keep an unused
/// asset from being collected by the GC.
struct AssetManager
{
    @disable this();
    @disable this(this);

private static:
    struct AssetUID
    {
        string typeFQN;
        string path;
    }

    alias LoadCallback = Object function(string);
    alias LoadFunction = Tuple!(LoadCallback, "callback", bool, "cache");

    LoadFunction[string] sLoaders;
    WeakReference!Object[AssetUID] sCache;

    Object load(in AssetUID uid)
    {
        LoadFunction* loader = uid.typeFQN in sLoaders;
        enforce!CoreException(loader, format!"'%s' was not registered as an asset."(uid.typeFQN));

        // Check if we have it cached, and if so, if it's still alive
        auto weakref = sCache.get(uid, null).assumeWontThrow;
        if (weakref && weakref.alive)
            return weakref.target;

        // Otherwise, load asset
        if (weakref)
            Logger.core.log(LogLevel.debug_, "Asset '%s' (%s) got collected, reloading...", uid.path, uid.typeFQN);
        else
            Logger.core.log(LogLevel.debug_, "Loading asset '%s' (%s)...", uid.path, uid.typeFQN);

        Object asset = loader.callback(uid.path);
        assert(asset, format!"Loader for '%s' returned null!"(uid.typeFQN));

        if (loader.cache)
            sCache[uid] = weakReference(asset);

        return asset;
    }

    void register(string fqn, LoadCallback callback, bool cache)
    {
        sLoaders[fqn] = LoadFunction(callback, cache);
    }

    bool unregister(string fqn)
    {
        return sLoaders.remove(fqn);
    }

    bool isCached(in AssetUID uid) nothrow
    {
        auto weakref = sCache.get(uid, null).assumeWontThrow;
        return weakref && weakref.alive;
    }

package(zyeware.core) static:
    void initialize()
    {
        import zyeware.rendering : Shader, Image, Texture2D, TextureCubeMap, Mesh3D, BitmapFont, Material, SpriteFrames, Cursor;
        import zyeware.core.translation : Translation;
        import zyeware.audio : AudioBuffer;

        register!Shader((path) => cast(Object) Shader.load(path));
        register!Texture2D((path) => cast(Object) Texture2D.load(path));
        register!TextureCubeMap((path) => cast(Object) TextureCubeMap.load(path));

        register!AudioBuffer((path) => cast(Object) AudioBuffer.load(path));

        register!Image(&Image.load);
        register!Mesh3D(&Mesh3D.load);
        register!BitmapFont(&BitmapFont.load);
        register!Material(&Material.load);
        register!Translation(&Translation.load);
        register!SpriteFrames(&SpriteFrames.load);
        register!Cursor(&Cursor.load);

        Logger.core.log(LogLevel.debug_, "Initialized default asset loaders.");
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
    pragma(inline, true)
    T load(T)(string path)
        if (isAsset!T)
        in (path, "Path cannot be null.")
    {
        return cast(T) load(AssetUID(fullyQualifiedName!T, path));
    }

    /// Registers a new asset.
    /// 
    /// Params:
    ///     T = The asset type to register.
    void register(T)(LoadCallback callback)
        if (isAsset!T)
    {
        import std.traits : getUDAs;
        auto data = getUDAs!(T, asset)[0];

        register(fullyQualifiedName!T, callback, data.cache);
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
        return unregister(fullyQualifiedName!T);
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
        return isCached(AssetUID(fullyQualifiedName!T, path));
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
                Logger.core.log(LogLevel.verbose, "Uncaching '%s' (%s)...", key.path, key.typeFQN);
                ++cleaned;
            }
        }

        Logger.core.log(LogLevel.debug_, "%d assets cleaned from cache.", cleaned);
    }
}