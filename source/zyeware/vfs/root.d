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
import std.path : buildNormalizedPath, dirName;

import zyeware.common;
import zyeware.vfs;

package(zyeware.vfs) alias LoadPackageResult = Tuple!(VFSDirectory, "root", ubyte[], "hash");

struct VFS
{
private static:
    enum userDirVFSPath = "user://";
    enum userDirPortableName = "ZyeWareData/";

    VFSDirectory[string] sProtocols;
    VFSLoader[] sLoaders;
    bool sPortableMode;

    pragma(inline, true)
    VFSDirectory getProtocol(string protocol)
        in (protocol)
    {
        VFSDirectory dir = sProtocols.get(protocol, null);
        enforce!VFSException(dir, format!"Unknown VFS protocol '%s'."(protocol));
        return dir;
    }

    pragma(inline, true)
    auto splitPath(string path)
        in (path, "Path cannot be null")
    {
        auto splitResult = path.findSplit("://");
        enforce!VFSException(!splitResult[0].empty && !splitResult[1].empty && !splitResult[2].empty,
            "Malformed VFS path.");
        return splitResult;
    }

    LoadPackageResult loadPackage(string path, string name)
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

        return new VFSDiskDirectory(userDirVFSPath, userDirVFSPath, dataDir);
    }

package(zyeware) static:
    void initialize()
    {
        if (exists(buildNormalizedPath(thisExePath.dirName, userDirPortableName, "_sc_")))
            sPortableMode = true;

        VFS.addLoader(new VFSDirectoryLoader());
        VFS.addLoader(new VFSZPKLoader());

        // Load core package and check hash if in release mode
        LoadPackageResult core = loadPackage("core.zpk", "core://");
        debug {} else
        {
            static immutable ubyte[] expectedHash = [];
            if (core.hash is null || core.hash != expectedHash)
                throw new VFSException("Core package has been modified, cannot proceed.");
        }
        
        sProtocols["core"] = core.root;
        sProtocols["res"] = new VFSCombinedDirectory("res://", "res://", []);
        sProtocols["user"] = createUserDir();
    }

    void cleanup() nothrow
    {
        sProtocols.clear();
        sLoaders.length = 0;
    }

public static:
    void addLoader(VFSLoader loader) nothrow
        in (loader)
    {
        sLoaders ~= loader;
    }

    VFSDirectory addPackage(string path)
        in (path, "Path cannot be null")
    {
        auto zpk = loadPackage(path, "/").root;
        (cast(VFSCombinedDirectory) sProtocols["res"]).addDirectory(zpk);
        Logger.core.log(LogLevel.info, "Added package '%s'.", path);
        return zpk;
    }

    VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getProtocol(splitResult[0]).getFile(splitResult[2], mode);
    }

    VFSDirectory getDirectory(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getProtocol(splitResult[0]).getDirectory(splitResult[2]);
    }

    bool hasFile(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getProtocol(splitResult[0]).hasFile(splitResult[2]);
    }

    bool hasDirectory(string name)
        in (name, "Name cannot be null.")
    {
        immutable splitResult = splitPath(name);
        return getProtocol(splitResult[0]).hasDirectory(splitResult[2]);
    }

    bool portableMode() nothrow
    {
        return sPortableMode;
    }
}