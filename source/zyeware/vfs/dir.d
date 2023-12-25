// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.dir;

import std.exception : enforce;
import std.string : format;

import zyeware;

/// Represents a virtual directory in the Vfs. Where this directory is
/// physically located depends on the implementation.
abstract class VfsDirectory
{
protected:
    string mPath;

    this(string path) pure nothrow
    {
        mPath = path;
    }

public:
    /// Retrieve a subdirectory by it's name.
    /// Returns: The requested VfsDirectory.
    /// Throws: VfsException for invalid paths or if the directory cannot be found.
    abstract VfsDirectory getDirectory(string name);

    /// Retrieve a file inside this directory by it's name.
    /// Returns: The requested VfsFile.
    /// Throws: VfsException for invalid paths or if the file cannot be found.
    abstract VfsFile getFile(string name);

    /// Returns `true` if the subdirectory with the given name exists, `false` otherwise.
    abstract bool hasDirectory(string name) const nothrow;

    /// Returns `true` if the file with the given name exists, `false` otherwise.
    abstract bool hasFile(string name) const nothrow;

    /// Returns the names of all files inside this directory.
    abstract immutable(string[]) files() const;

    /// Returns the names of all subdirectories inside this directory.
    abstract immutable(string[]) directories() const;

    string path() pure const nothrow
    {
        return mPath;
    }
}

package(zyeware.vfs):

bool isWriteMode(VfsFile.Mode mode) pure nothrow
{
    return mode == VfsFile.Mode.append || mode == VfsFile.Mode.readWrite
        || mode == VfsFile.Mode.writeRead || mode == VfsFile.Mode.write;
}

class VfsCombinedDirectory : VfsDirectory
{
protected:
    VfsDirectory[] mDirectories;

package:
    this(string path, VfsDirectory[] directories) pure nothrow
    {
        super(path);
        mDirectories = directories;
    }

    void addDirectory(VfsDirectory directory) pure nothrow
        in (directory, "Directory cannot be null.")
    {
        mDirectories ~= directory;
    }

public:
    override VfsDirectory getDirectory(string name)
        in (name, "Name cannot be null.")
    {
        VfsDirectory[] foundDirectories;

        foreach_reverse (dir; mDirectories)
            if (dir.hasDirectory(name))
                foundDirectories ~= dir.getDirectory(name);

        enforce!VfsException(foundDirectories.length > 0, format!"Directory '%s' not found."(name));

        return new VfsCombinedDirectory(buildPath(mPath, name), foundDirectories);
    }

    override VfsFile getFile(string name)
        in (name, "Name cannot be null.")
    {
        foreach_reverse (dir; mDirectories)
            if (dir.hasFile(name))
                return dir.getFile(name);

        throw new VfsException(format!"File '%s' not found."(buildPath(mPath, name)));
    }

    override bool hasDirectory(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        foreach_reverse (dir; mDirectories)
            if (dir.hasDirectory(name))
                return true;

        return false;
    }

    override bool hasFile(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        foreach_reverse (dir; mDirectories)
            if (dir.hasFile(name))
                return true;

        return false;
    }

    override immutable(string[]) files() const
    {
        int[string] files;

        foreach_reverse (dir; mDirectories)
            foreach (string file; dir.files)
                files[file] = 0;

        return files.keys.idup;
    }

    override immutable(string[]) directories() const
    {
        int[string] directories;

        foreach_reverse (dir; mDirectories)
            foreach (string subdir; dir.directories)
                directories[subdir] = 0;

        return directories.keys.idup;
    }
}