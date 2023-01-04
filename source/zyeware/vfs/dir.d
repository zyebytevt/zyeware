// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.dir;

import core.stdc.stdio : FILE;

import std.path : dirSeparator, baseName, buildPath, isRooted;
import std.file : exists, isDir, isFile, dirEntries, SpanMode;
import std.exception : enforce, assumeWontThrow;
import std.string : split, format;

import zyeware.common;
import zyeware.vfs;

/// Represents a virtual directory in the VFS. Where this directory is
/// physically located depends on the implementation.
abstract class VFSDirectory : VFSBase
{
package:
    this(string fullname, string name) pure nothrow
    {
        super(fullname, name);
    }

public:
    /// Retrieve a subdirectory by it's name.
    /// Returns: The requested VFSDirectory.
    /// Throws: VFSException for invalid paths or if the directory cannot be found.
    abstract VFSDirectory getDirectory(string name);

    /// Retrieve a file inside this directory by it's name.
    /// Returns: The requested VFSFile.
    /// Throws: VFSException for invalid paths or if the file cannot be found.
    /// Params:
    ///     mode = The access mode by which to open the requested file.
    abstract VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read);

    /// Returns `true` if the subdirectory with the given name exists, `false` otherwise.
    abstract bool hasDirectory(string name) const nothrow;

    /// Returns `true` if the file with the given name exists, `false` otherwise.
    abstract bool hasFile(string name) const nothrow;

    /// Returns the names of all files inside this directory.
    abstract immutable(string[]) files() const;

    /// Returns the names of all subdirectories inside this directory.
    abstract immutable(string[]) directories() const;
}

package:

class VFSCombinedDirectory : VFSDirectory
{
protected:
    VFSDirectory[] mDirectories;

package:
    this(string fullname, string name, VFSDirectory[] directories) pure nothrow
    {
        super(fullname, name);
        mDirectories = directories;
    }

    void addDirectory(VFSDirectory directory) pure nothrow
        in (directory)
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

        return new VFSCombinedDirectory(fullname ~ name, name, foundDirectories);
    }

    override VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read)
        in (name, "Name cannot be null.")
    {
        foreach_reverse (dir; mDirectories)
            if (dir.hasFile(name) || isWriteMode(mode))
                return dir.getFile(name, mode);

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

class VFSDiskDirectory : VFSDirectory
{
protected:
    immutable string mDiskPath;

package:
    this(string fullname, string name, string diskPath) pure nothrow
        in (diskPath)
    {
        super(fullname, name);
        mDiskPath = diskPath;
    }

public:
    override VFSDirectory getDirectory(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "Subdirectory name cannot be rooted.");
        enforce!VFSException(hasDirectory(name), format!"Subdirectory '%s' not found."(name));

        return new VFSDiskDirectory(buildPath(fullname, name), name, buildPath(mDiskPath, name));
    }

    override VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read) const
        in (name, "Name cannot be null.")
    {
        import std.stdio : fopen;
        import std.string : toStringz;

        static immutable(char)*[VFSFile.Mode] modeToC;
        
        if (modeToC.length == 0)
            modeToC= [
                VFSFile.Mode.read: "rb",
                VFSFile.Mode.write: "wb",
                VFSFile.Mode.readWrite: "r+b",
                VFSFile.Mode.writeRead: "w+b",
                VFSFile.Mode.append: "ab"
            ];

        enforce!VFSException(!isRooted(name), "File name cannot be rooted.");
        enforce!VFSException(isWriteMode(mode) || hasFile(name), format!"File '%s' not found."(name));

        return new VFSDiskFile(buildPath(fullname, name), name,
                fopen(buildPath(mDiskPath, name).toStringz, modeToC[mode]));
    }

    override bool hasDirectory(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        immutable string path = buildPath(mDiskPath, name);
        return exists(path) && isDir(path).assumeWontThrow;
    }

    override bool hasFile(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        immutable string path = buildPath(mDiskPath, name);
        return exists(path) && isFile(path).assumeWontThrow;
    }

    override immutable(string[]) files() const
    {
        string[] result;
        foreach (string name; dirEntries(mDiskPath, SpanMode.shallow))
            if (isFile(name))
                result ~= name.baseName;

        return result.idup;
    }

    override immutable(string[]) directories() const
    {
        string[] result;
        foreach (string name; dirEntries(mDiskPath, SpanMode.shallow))
            if (isDir(name))
                result ~= name.baseName;

        return result.idup;
    }
}

class VFSZPKDirectory : VFSDirectory
{
protected:
    alias Node = VFSZPKLoader.FileNode;

    FILE* mCFile;
    Node* mRoot;
    bool mFilePointerOwner;

package:
    this(string fullname, string name, FILE* file, Node* root, Flag!"filePointerOwner" filePointerOwner) pure nothrow
        in (file && root)
    {
        super(fullname, name);
        mCFile = file;
        mRoot = root;
        mFilePointerOwner = filePointerOwner;
    }

public:
    ~this()
    {
        import core.stdc.stdio : fclose;
        if (mFilePointerOwner)
            fclose(mCFile);
    }

    override VFSDirectory getDirectory(string name) pure
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "Subdirectory name cannot be rooted.");

        if (name == ".")
            return new VFSZPKDirectory(fullname, name, mCFile, mRoot, No.filePointerOwner);

        Node* current = mRoot;
        foreach (part; name.split("/"))
        {
            current = current.children.get(part, null);
            enforce!VFSException(current, format!"Subdirectory '%s' not found."(name));
        }

        // Check if it's a directory.
        enforce!VFSException(!current.fileInfo, format!"Subdirectory '%s' not found."(name));
        return new VFSZPKDirectory(buildPath(fullname, name), name, mCFile, current, No.filePointerOwner);
    }

    override VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read) pure
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "File name cannot be rooted.");
        enforce!VFSException(!isWriteMode(mode), "Cannot write files into ZPK archives.");

        Node* current = mRoot;
        foreach (part; name.split("/"))
        {
            current = current.children.get(part, null);
            enforce!VFSException(current, format!"File '%s' not found."(name));
        }

        // Check if it's a file.
        enforce!VFSException(current.fileInfo, format!"File '%s' not found."(name));
        return new VFSZPKFile(buildPath(fullname, name), name, mCFile,
                current.fileInfo.offset, current.fileInfo.size);
    }

    override bool hasDirectory(string name) pure const nothrow
        in (name, "Name cannot be null.")
    {
        if (name == ".")
            return true;

        Node* current = cast(Node*) mRoot;
        foreach (part; name.split("/"))
        {
            current = current.children.get(part, null).assumeWontThrow;
            if (!current)
                return false;
        }

        return current.fileInfo is null;
    }

    override bool hasFile(string name) pure const nothrow
        in (name, "Name cannot be null.")
    {
        Node* current = cast(Node*) mRoot;
        foreach (part; name.split("/"))
        {
            current = current.children.get(part, null).assumeWontThrow;
            if (!current)
                return false;
        }

        return current.fileInfo !is null;
    }

    override immutable(string[]) files() pure const
    {
        string[] result;
        foreach (string name, child; mRoot.children)
            if (child.fileInfo)
                result ~= name;

        return result.idup;
    }

    override immutable(string[]) directories() pure const
    {
        string[] result;
        foreach (string name, child; mRoot.children)
            if (!child.fileInfo)
                result ~= name;

        return result.idup;
    }
}

private:

bool isWriteMode(VFSFile.Mode mode) pure nothrow
{
    return mode == VFSFile.Mode.append || mode == VFSFile.Mode.readWrite
        || mode == VFSFile.Mode.writeRead || mode == VFSFile.Mode.write;
}
