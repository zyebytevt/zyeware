// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.root;

import core.stdc.stdlib : getenv;
import std.algorithm : findSplit;
import std.exception : enforce;
import std.typecons : Tuple;
import std.range : empty;
import std.string : fromStringz, format;
import std.file : mkdirRecurse, thisExePath, exists;
import std.path : buildNormalizedPath, dirName, isValidPath;

import zyeware;
import zyeware.vfs.disk : VFSDiskLoader, VFSDiskDirectory;
import zyeware.vfs.zip : VFSZipLoader, VFSZipDirectory;
import zyeware.vfs.dir : VFSCombinedDirectory;

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

struct VFS
{
private static:
    enum userDirVFSPath = "user://";
    enum userDirPortableName = "ZyeWareData/";

    VFSDirectory[string] sSchemes;
    VFSLoader[] sLoaders;
    bool sPortableMode;

    pragma(inline, true)
    VFSDirectory getScheme(string scheme)
        in (scheme, "Scheme cannot be null.")
    {
        VFSDirectory dir = sSchemes.get(scheme, null);
        enforce!VFSException(dir, format!"Unknown VFS scheme '%s'."(scheme));
        return dir;
    }

    pragma(inline, true)
    auto splitPath(string path)
        in (path, "Path cannot be null")
    {
        auto splitResult = path.findSplit(":");
        enforce!VFSException(!splitResult[0].empty && !splitResult[1].empty && !splitResult[2].empty,
            "Malformed VFS path.");
        return splitResult;
    }

    VFSDirectory loadPackage(string path, string name)
        in (path && name)
    {
        foreach (VFSLoader loader; sLoaders)
            if (loader.eligable(path))
                return loader.load(path, name);

        throw new VFSException(format!"Failed to find eligable loader for package '%s'."(path));
    }

    VFSDirectory createUserDir()
    {
        immutable string userDirName = ZyeWare.projectProperties.authorName ~ "/" ~ ZyeWare.projectProperties.projectName;

        string dataDir = buildNormalizedPath(thisExePath.dirName, userDirPortableName, userDirName);

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
                    dataDir = buildNormalizedPath(homedir.fromStringz.idup, ".local/share/zyeware/", userDirName);
                else version (OSX)
                    dataDir = buildNormalizedPath(homedir.fromStringz.idup, "Library/Application Support/ZyeWare/", userDirName);
                else
                    dataDir = buildNormalizedPath(homedir.fromStringz.idup, ".zyeware/", userDirName);
            }
            else version (Windows)
            {
                dataDir = buildNormalizedPath(getenv("LocalAppData").fromStringz.idup, "ZyeWare/", userDirName);            
            }
            else
                sPortableMode = true;
        }

        mkdirRecurse(dataDir);

        return new VFSDiskDirectory(userDirVFSPath, dataDir);
    }

package(zyeware) static:
    void initialize()
    {
        if (exists(buildNormalizedPath(thisExePath.dirName, userDirPortableName, "_sc_")))
            sPortableMode = true;

        VFS.registerLoader(new VFSDiskLoader());
        VFS.registerLoader(new VFSZipLoader());

        VFSDirectory corePackage = loadPackage("core.zpk", "core:");

        // In release mode, let's check if the core package has been modified.
        debug {} else {
            VFSZipDirectory coreZip = cast(VFSZipDirectory) corePackage;
            enforce!VFSException(coreZip, "Core package must be a zip archive.");

            import std.digest.md : md5Of;
            import std.zip : ZipArchive;

            enum coreMd5 = md5FromHex("9448bc0b4ca2a31ac1b6b71c940d1601");
            enforce!VFSException(md5Of((cast(ZipArchive)coreZip.mArchive).data) == coreMd5,
                "Core package has been modified, cannot continue.");
        }
    
        sSchemes["core"] = corePackage;
        sSchemes["res"] = new VFSCombinedDirectory("res:", []);
        sSchemes["user"] = createUserDir();

        Logger.core.log(LogLevel.info, "Initialized VFS.");
    }

    void cleanup() nothrow
    {
        sSchemes.clear();
        sLoaders.length = 0;
    }

public static:
    /// Registers a new VFSLoader to be used when loading packages.
    ///
    /// Params:
    ///     loader: The loader to register.
    void registerLoader(VFSLoader loader) nothrow
        in (loader)
    {
        sLoaders ~= loader;
    }

    /// Adds a package to the VFS.
    ///
    /// Params:
    ///     path: The real path to the package.
    VFSDirectory addPackage(string path)
        in (path, "Path cannot be null")
    {
        VFSDirectory pck = loadPackage(path, "/");
        (cast(VFSCombinedDirectory) sSchemes["res"]).addDirectory(pck);
        Logger.core.log(LogLevel.info, "Added package '%s'.", path);
        return pck;
    }

    /// Opens the file with the given path and mode.
    /// 
    /// Params:
    ///   name = The path to the file.
    ///   mode = The mode to open the file in.
    VFSFile open(string name, VFSFile.Mode mode = VFSFile.Mode.read)
        in (name, "Name cannot be null.")
    {
        VFSFile file = getFile(name);
        file.open(mode);
        return file;
    }

    /// Opens a file from memory.
    ///
    /// Params:
    ///   name = The name of the file. Can be arbitrary.
    ///   data = The data of the file.
    VFSFile openFromMemory(string name, in ubyte[] data)
    {
        import zyeware.vfs.memory.file : VFSMemoryFile;

        return new VFSMemoryFile(name, data);
    }

    VFSFile getFile(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getScheme(splitResult[0]).getFile(splitResult[2]);
    }

    VFSDirectory getDirectory(string name)
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