// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.vfs.root;

static import std.path;

import core.stdc.stdlib : getenv;
import std.algorithm : findSplit, canFind;
import std.exception : enforce;
import std.typecons : Tuple;
import std.range : empty;
import std.string : fromStringz, format;
import std.file : mkdirRecurse, thisExePath, exists;

import zyeware;
import zyeware.vfs.disk.loader : DirectoryPackageLoader;
import zyeware.vfs.disk.dir : DiskDirectory;
import zyeware.vfs.zip.loader : ZipPackageLoader;
import zyeware.vfs.zip.dir : ZipDirectory;
import zyeware.vfs.dir : StackDirectory;

private ubyte[16] md5FromHex(string hexString)
{
    import std.conv : to;

    if (hexString.length != 32)
        assert(false, "Invalid MD5 string.");

    ubyte[16] result;

    for (size_t i; i < result.length; ++i)
        result[i] = hexString[i * 2 .. i * 2 + 2].to!ubyte(16);

    return result;
}

struct Files
{
private static:
    enum userDirVfsPath = "user://";
    enum userDirPortableName = "ZyeWareData/";

    Directory[string] sSchemes;
    PackageLoader[] sLoaders;
    bool sPortableMode;

    pragma(inline, true) Directory getRootForScheme(string scheme)
    in (scheme, "Scheme cannot be null.")
    {
        Directory dir = sSchemes.get(scheme, null);
        enforce!VfsException(dir, format!"Unknown Files scheme '%s'."(scheme));
        return dir;
    }

    pragma(inline, true) auto splitPath(string path)
    in (path, "Path cannot be null")
    {
        auto splitResult = path.findSplit(":");
        enforce!VfsException(!splitResult[0].empty && !splitResult[1].empty
                && !splitResult[2].empty, "Malformed file path.");
        return splitResult;
    }

    Directory loadPackage(string path, string scheme)
    in (path && scheme)
    {
        foreach (PackageLoader loader; sLoaders)
            if (loader.eligable(path))
                return loader.load(path, scheme);

        throw new VfsException(format!"Failed to find eligable loader for package '%s'."(path));
    }

    Directory createUserDir()
    {
        immutable string userDirName = ZyeWare.projectProperties.authorName
            ~ "/" ~ ZyeWare.projectProperties.projectName;

        string dataDir = std.path.buildNormalizedPath(std.path.dirName(thisExePath),
            userDirPortableName, userDirName);

        if (!sPortableMode)
        {
            version (Posix)
            {
                import core.sys.posix.unistd : getuid;
                import core.sys.posix.pwd : getpwuid;

                stringz homedir;

                synchronized
                {
                    if ((homedir = getenv("HOME")) is null)
                        homedir = getpwuid(getuid()).pw_dir;
                }

                version (linux)
                    dataDir = std.path.buildNormalizedPath(homedir.fromStringz.idup,
                        ".local/share/zyeware/", userDirName);
                else version (OSX)
                    dataDir = std.path.buildNormalizedPath(homedir.fromStringz.idup,
                        "Library/Application Support/ZyeWare/", userDirName);
                else
                    dataDir = std.path.buildNormalizedPath(homedir.fromStringz.idup,
                        ".zyeware/", userDirName);
            }
            else version (Windows)
            {
                dataDir = std.path.buildNormalizedPath(getenv("LocalAppData")
                        .fromStringz.idup, "ZyeWare/", userDirName);
            }
            else
                sPortableMode = true;
        }

        mkdirRecurse(dataDir);

        return new DiskDirectory(userDirVfsPath ~ ':', dataDir);
    }

package(zyeware) static:
    void load()
    {
        if (exists(std.path.buildNormalizedPath(std.path.dirName(thisExePath),
                userDirPortableName, "_sc_")))
            sPortableMode = true;

        Files.registerPackageLoader(new DirectoryPackageLoader());
        Files.registerPackageLoader(new ZipPackageLoader());

        Directory corePackage = loadPackage("core.zpk", "core");

        // In release mode, let's check if the core package has been modified.
        debug
        {
        }
        else
        {
            ZipDirectory coreZip = cast(ZipDirectory) corePackage;
            enforce!VfsException(coreZip, "Core package must be a zip archive.");

            import std.digest.md : md5Of;
            import std.zip : ZipArchive;

            enum coreMd5 = md5FromHex("9448bc0b4ca2a31ac1b6b71c940d1601");
            enforce!VfsException(md5Of((cast(ZipArchive) coreZip.mArchive)
                    .data) == coreMd5, "Core package has been modified, cannot continue.");
        }

        sSchemes["core"] = corePackage;
        sSchemes["res"] = new StackDirectory("res:", []);
        sSchemes["user"] = createUserDir();

        Logger.core.info("Virtual File System initialized.");
    }

    void unload() nothrow
    {
        sSchemes.clear();
        sLoaders.length = 0;
    }

public static:
    /// Registers a new PackageLoader to be used when loading packages.
    ///
    /// Params:
    ///     loader: The loader to register.
    void registerPackageLoader(PackageLoader loader) nothrow
    in (loader)
    {
        sLoaders ~= loader;
    }

    /// Adds a package to the Files.
    ///
    /// Params:
    ///     path: The real path to the package.
    Directory addPackage(string path)
    in (path, "Path cannot be null")
    {
        immutable string scheme = std.path.stripExtension(std.path.baseName(path));
        enforce!CoreException(!sSchemes.keys.canFind(scheme),
            format!"Scheme '%s' already exists."(scheme));

        Directory pck = loadPackage(path, scheme);

        (cast(StackDirectory) sSchemes["res"]).addDirectory(pck);
        sSchemes[scheme] = pck;
        Logger.core.info("Added package '%s' as '%s'.", path, scheme);
        return pck;
    }

    /// Opens the file with the given path and mode.
    /// 
    /// Params:
    ///   name = The path to the file.
    ///   mode = The mode to open the file in.
    File open(string name, File.Mode mode = File.Mode.read)
    in (name, "Name cannot be null.")
    {
        File file = getFile(name);
        file.open(mode);
        return file;
    }

    /// Opens a file from memory.
    ///
    /// Params:
    ///   name = The name of the file. Can be arbitrary.
    ///   data = The data of the file.
    File openFromMemory(string name, in ubyte[] data)
    {
        import zyeware.vfs.memory.file : MemoryFile;

        return new MemoryFile(name, data);
    }

    File getFile(string name)
    in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getRootForScheme(splitResult[0]).getFile(splitResult[2]);
    }

    Directory getDirectory(string name)
    in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getRootForScheme(splitResult[0]).getDirectory(splitResult[2]);
    }

    bool hasFile(string name)
    in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getRootForScheme(splitResult[0]).hasFile(splitResult[2]);
    }

    bool hasDirectory(string name)
    in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getRootForScheme(splitResult[0]).hasDirectory(splitResult[2]);
    }

    bool portableMode() nothrow
    {
        return sPortableMode;
    }
}
