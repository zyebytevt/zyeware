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

package(zyeware.core) static:
    void initialize()
    {
        //registerDefaultLoaders();
        import zyeware.rendering : Shader, Image, Texture2D, TextureCubeMap, Mesh, Font, Material, SpriteFrames, Cursor;
        import zyeware.core.translation : Translation;
        import zyeware.audio : Sound;

        register!Shader((path) => cast(Object) Shader.load(path));
        register!Texture2D((path) => cast(Object) Texture2D.load(path));
        register!TextureCubeMap((path) => cast(Object) TextureCubeMap.load(path));

        register!Sound((path) => cast(Object) Sound.load(path));

        register!Image(&Image.load);
        register!Mesh(&Mesh.load);
        register!Font(&Font.load);
        register!Material(&Material.load);
        register!Translation(&Translation.load);
        register!SpriteFrames(&SpriteFrames.load);
        register!Cursor(&Cursor.load);
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
        enum fqn = fullyQualifiedName!T;

        LoadFunction* loader = fqn in sLoaders;
        enforce!CoreException(loader, format!"'%s' was not registered as an asset."(fqn));

        path = TranslationManager.remapAssetPath(path);

        auto uid = AssetUID(fqn, path);

        // Check if we have it cached, and if so, if it's still alive
        auto weakref = sCache.get(uid, null).assumeWontThrow;
        if (weakref && weakref.alive)
            return cast(T) weakref.target;

        // Otherwise, load asset
        if (weakref)
            Logger.core.log(LogLevel.debug_, "Asset '%s' (%s) got collected, reloading...", uid.path, uid.typeFQN);
        else
            Logger.core.log(LogLevel.debug_, "Loading asset '%s' (%s)...", uid.path, uid.typeFQN);

        Object asset = loader.callback(path);
        assert(asset, format!"Loader for '%s' returned null!"(T.stringof));

        if (loader.cache)
            sCache[uid] = weakReference(asset);

        return cast(T) asset;
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

        sLoaders[fullyQualifiedName!T] = LoadFunction(callback, data.cache);
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
        return sLoaders.remove(fullyQualifiedName!T);
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
        auto weakref = sCache.get(AssetUID(fullyQualifiedName!T, path), null).assumeWontThrow;
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
                Logger.core.log(LogLevel.verbose, "Uncaching '%s' (%s)...", key.path, key.typeFQN);
                ++cleaned;
            }
        }

        Logger.core.log(LogLevel.debug_, "%d assets cleaned from cache.", cleaned);
    }
}