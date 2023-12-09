// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.root;

static import std.path;

import core.stdc.stdlib : getenv;
import std.algorithm : findSplit;
import std.exception : enforce;
import std.typecons : Tuple;
import std.range : empty;
import std.string : fromStringz, format;
import std.file : mkdirRecurse, thisExePath, exists;

import zyeware;
import zyeware.vfs.disk : VfsDiskLoader, VfsDiskDirectory;
import zyeware.vfs.zip : VfsZipLoader, VfsZipDirectory;
import zyeware.vfs.dir : VfsCombinedDirectory;

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

struct Vfs
{
private static:
    enum userDirVfsPath = "user://";
    enum userDirPortableName = "ZyeWareData/";

    VfsDirectory[string] sSchemes;
    VfsLoader[] sLoaders;
    bool sPortableMode;

    pragma(inline, true)
    VfsDirectory getScheme(string scheme)
        in (scheme, "Scheme cannot be null.")
    {
        VfsDirectory dir = sSchemes.get(scheme, null);
        enforce!VfsException(dir, format!"Unknown Vfs scheme '%s'."(scheme));
        return dir;
    }

    pragma(inline, true)
    auto splitPath(string path)
        in (path, "Path cannot be null")
    {
        auto splitResult = path.findSplit(":");
        enforce!VfsException(!splitResult[0].empty && !splitResult[1].empty && !splitResult[2].empty,
            "Malformed Vfs path.");
        return splitResult;
    }

    VfsDirectory loadPackage(string path, string scheme)
        in (path && scheme)
    {
        foreach (VfsLoader loader; sLoaders)
            if (loader.eligable(path))
                return loader.load(path, scheme);

        throw new VfsException(format!"Failed to find eligable loader for package '%s'."(path));
    }

    VfsDirectory createUserDir()
    {
        immutable string userDirName = ZyeWare.projectProperties.authorName ~ "/" ~ ZyeWare.projectProperties.projectName;

        string dataDir = std.path.buildNormalizedPath(std.path.dirName(thisExePath), userDirPortableName, userDirName);

        if (!sPortableMode)
        {
            version (Posix)
            {
                import core.sys.posix.unistd : getuid;
                import core.sys.posix.pwd : getpwuid;

                const(char)* homedir;

                synchronized
                {
                    if ((homedir = getenv("HOME")) is null)
                        homedir = getpwuid(getuid()).pw_dir;
                }

                version (linux)
                    dataDir = std.path.buildNormalizedPath(homedir.fromStringz.idup, ".local/share/zyeware/", userDirName);
                else version (OSX)
                    dataDir = std.path.buildNormalizedPath(homedir.fromStringz.idup, "Library/Application Support/ZyeWare/", userDirName);
                else
                    dataDir = std.path.buildNormalizedPath(homedir.fromStringz.idup, ".zyeware/", userDirName);
            }
            else version (Windows)
            {
                dataDir = std.path.buildNormalizedPath(getenv("LocalAppData").fromStringz.idup, "ZyeWare/", userDirName);            
            }
            else
                sPortableMode = true;
        }

        mkdirRecurse(dataDir);

        return new VfsDiskDirectory(userDirVfsPath, dataDir);
    }

package(zyeware) static:
    void initialize()
    {
        if (exists(std.path.buildNormalizedPath(std.path.dirName(thisExePath), userDirPortableName, "_sc_")))
            sPortableMode = true;

        Vfs.registerLoader(new VfsDiskLoader());
        Vfs.registerLoader(new VfsZipLoader());

        VfsDirectory corePackage = loadPackage("core.zpk", "core:");

        // In release mode, let's check if the core package has been modified.
        debug {} else {
            VfsZipDirectory coreZip = cast(VfsZipDirectory) corePackage;
            enforce!VfsException(coreZip, "Core package must be a zip archive.");

            import std.digest.md : md5Of;
            import std.zip : ZipArchive;

            enum coreMd5 = md5FromHex("9448bc0b4ca2a31ac1b6b71c940d1601");
            enforce!VfsException(md5Of((cast(ZipArchive)coreZip.mArchive).data) == coreMd5,
                "Core package has been modified, cannot continue.");
        }
    
        sSchemes["core"] = corePackage;
        sSchemes["res"] = new VfsCombinedDirectory("res:", []);
        sSchemes["user"] = createUserDir();

        Logger.core.log(LogLevel.info, "Initialized Vfs.");
    }

    void cleanup() nothrow
    {
        sSchemes.clear();
        sLoaders.length = 0;
    }

public static:
    /// Registers a new VfsLoader to be used when loading packages.
    ///
    /// Params:
    ///     loader: The loader to register.
    void registerLoader(VfsLoader loader) nothrow
        in (loader)
    {
        sLoaders ~= loader;
    }

    /// Adds a package to the Vfs.
    ///
    /// Params:
    ///     path: The real path to the package.
    VfsDirectory addPackage(string path)
        in (path, "Path cannot be null")
    {
        immutable string scheme = std.path.stripExtension(std.path.baseName(path)) ~ ':';
        VfsDirectory pck = loadPackage(path, scheme);

        (cast(VfsCombinedDirectory) sSchemes["res"]).addDirectory(pck);
        Logger.core.log(LogLevel.info, "Added package '%s'.", path);
        return pck;
    }

    /// Opens the file with the given path and mode.
    /// 
    /// Params:
    ///   name = The path to the file.
    ///   mode = The mode to open the file in.
    VfsFile open(string name, VfsFile.Mode mode = VfsFile.Mode.read)
        in (name, "Name cannot be null.")
    {
        VfsFile file = getFile(name);
        file.open(mode);
        return file;
    }

    /// Opens a file from memory.
    ///
    /// Params:
    ///   name = The name of the file. Can be arbitrary.
    ///   data = The data of the file.
    VfsFile openFromMemory(string name, in ubyte[] data)
    {
        import zyeware.vfs.memory.file : VfsMemoryFile;

        return new VfsMemoryFile(name, data);
    }

    VfsFile getFile(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getScheme(splitResult[0]).getFile(splitResult[2]);
    }

    VfsDirectory getDirectory(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getScheme(splitResult[0]).getDirectory(splitResult[2]);
    }

    bool hasFile(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getScheme(splitResult[0]).hasFile(splitResult[2]);
    }

    bool hasDirectory(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getScheme(splitResult[0]).hasDirectory(splitResult[2]);
    }

    bool portableMode() nothrow
    {
        return sPortableMode;
    }
}