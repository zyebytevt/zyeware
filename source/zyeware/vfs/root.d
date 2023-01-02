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
import std.file : mkdirRecurse;
import std.path : buildNormalizedPath;

import zyeware.common;
import zyeware.vfs;

struct VFS
{
private static:
    VFSDirectory[string] sProtocols;
    VFSLoader[] sLoaders;

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

    VFSDirectory loadPackage(string path, string name)
        in (path && name)
    {
        foreach (VFSLoader loader; sLoaders)
            if (loader.eligable(path))
                return loader.load(path, name);

        throw new VFSException(format!"Failed to find eligable loader for package '%s'."(path));
    }

    VFSDirectory createUserDir(string userDirName)
        in (userDirName)
    {
        enum userDirVFSPath = "user://";

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

            // TODO: Where are configuration files located on different Posix platforms?
            string configDir = buildNormalizedPath(homedir.fromStringz.idup, ".local/share/zyeware/", userDirName);
        }
        else version (Windows)
        {
            string configDir = buildNormalizedPath(getenv("APPDATA").fromStringz.idup, "zyeware/", userDirName);            
        }
        else
            static assert(false, "VFS: Cannot compile for this operating system");

        mkdirRecurse(configDir);

        return new VFSDiskDirectory(userDirVFSPath, userDirVFSPath, configDir);
    }

package(zyeware) static:
    void initialize()
    {
        VFS.addLoader(new VFSDirectoryLoader());
        VFS.addLoader(new VFSZPKLoader());

        sProtocols["core"] = loadPackage("core.zpk", "core://");
        sProtocols["res"] = new VFSCombinedDirectory("res://", "res://", []);
        sProtocols["user"] = createUserDir(ZyeWare.application.uuid.toString());
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
        auto zpk = loadPackage(path, "/");
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
}