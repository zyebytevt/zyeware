// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.dir;

import std.exception : enforce;
import std.string : format;

import zyeware;
import zyeware.vfs;

/// Represents a virtual directory in the VFS. Where this directory is
/// physically located depends on the implementation.
abstract class VFSDirectory
{
protected:
    string mName;

    this(string name) pure nothrow
    {
        mName = name;
    }

public:
    /// Retrieve a subdirectory by it's name.
    /// Returns: The requested VFSDirectory.
    /// Throws: VFSException for invalid paths or if the directory cannot be found.
    abstract VFSDirectory getDirectory(string name);

    /// Retrieve a file inside this directory by it's name.
    /// Returns: The requested VFSFile.
    /// Throws: VFSException for invalid paths or if the file cannot be found.
    abstract VFSFile getFile(string name);

    /// Returns `true` if the subdirectory with the given name exists, `false` otherwise.
    abstract bool hasDirectory(string name) const nothrow;

    /// Returns `true` if the file with the given name exists, `false` otherwise.
    abstract bool hasFile(string name) const nothrow;

    /// Returns the names of all files inside this directory.
    abstract immutable(string[]) files() const;

    /// Returns the names of all subdirectories inside this directory.
    abstract immutable(string[]) directories() const;
}

package(zyeware.vfs):

bool isWriteMode(VFSFile.Mode mode) pure nothrow
{
    return mode == VFSFile.Mode.append || mode == VFSFile.Mode.readWrite
        || mode == VFSFile.Mode.writeRead || mode == VFSFile.Mode.write;
}

class VFSCombinedDirectory : VFSDirectory
{
protected:
    VFSDirectory[] mDirectories;

package:
    this(string name, VFSDirectory[] directories) pure nothrow
    {
        super(name);
        mDirectories = directories;
    }

    void addDirectory(VFSDirectory directory) pure nothrow
        in (directory, "Directory cannot be null.")
    {
        mDirectories ~= directory;
    }

public:
    override VFSDirectory getDirectory(string name)
        in (name, "Name cannot be null.")
    {
        VFSDirectory[] foundDirectories;

        foreach_reverse (dir; mDirectories)
            if (dir.hasDirectory(name))
                foundDirectories ~= dir.getDirectory(name);

        enforce!VFSException(foundDirectories.length > 0, format!"Directory '%s' not found."(name));

        return new VFSCombinedDirectory(name, foundDirectories);
    }

    override VFSFile getFile(string name)
        in (name, "Name cannot be null.")
    {
        foreach_reverse (dir; mDirectories)
            if (dir.hasFile(name))
                return dir.getFile(name);

        throw new VFSException(format!"File '%s' not found."(name));
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