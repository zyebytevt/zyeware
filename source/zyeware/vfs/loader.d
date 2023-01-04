// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.loader;

import zyeware.common;
import zyeware.vfs;

/// Interface for all VFS loaders. They are responsible for checking and loading various
/// types of files or directories into the VFS.
interface VFSLoader
{
public:
    /// Loads the given entry.
    /// Returns: The loaded directory as VFSDirectory.
    LoadPackageResult load(string diskPath, string name) const;

    /// Returns `true` if the given entry is valid for loading by this loader, `false` otherwise.
    bool eligable(string diskPath) const;
}

/// Loads file system directories as VFS directories.
class VFSDirectoryLoader : VFSLoader
{
public:
    LoadPackageResult load(string diskPath, string name) const
        in (diskPath && name)
    {
        import std.path : baseName;

        return LoadPackageResult(new VFSDiskDirectory(name, name, diskPath), null);
    }

    bool eligable(string diskPath) const
        in (diskPath)
    {
        import std.file : exists, isDir;

        return diskPath.exists && diskPath.isDir;
    }
}

/// Loads ZPK files as VFS directories.
class VFSZPKLoader : VFSLoader
{
    import core.stdc.stdio;

protected:
    string readPString(LengthType = ushort)(FILE* file) const nothrow
        in (file)
    {
        import std.bitmanip : read, Endian;

        LengthType length = readPrimitive!LengthType(file);
        char[] str = new char[length];

        fread(str.ptr, char.sizeof, length, file);
        return str.idup;
    }

    T readPrimitive(T)(FILE* file) const nothrow
        in (file)
    {
        import std.bitmanip : read, Endian;

        ubyte[] buffer = new ubyte[T.sizeof];
        fread(buffer.ptr, ubyte.sizeof, T.sizeof, file);

        return read!(T, Endian.littleEndian)(buffer);
    }

package:
    struct FileNode
    {
        struct FileInfo
        {
            string fullPath;
            int offset;
            int size;
        }

        FileInfo* fileInfo;
        FileNode*[string] children;
    }

public:
    LoadPackageResult load(string diskPath, string name) const
        in (diskPath && name)
    {
        import std.file : read;
        import std.string : split, toStringz;
        import std.digest.md;

        // Calculate hash
        ubyte[] hash = new MD5Digest().digest(read(diskPath));

        // Open file and parse
        FILE* file = fopen(diskPath.toStringz, "rb");

        FileNode* root = new FileNode;

        // Skip magic
        fseek(file, 4, SEEK_CUR);

        // Go to central directory
        immutable uint centralDirectoryOffset = readPrimitive!uint(file);
        fseek(file, centralDirectoryOffset, SEEK_SET);

        // Read central directory
        immutable int fileAmount = readPrimitive!uint(file);
        for (size_t i; i < fileAmount; ++i)
        {
            immutable string fullPath = readPString(file);
            immutable int fileOffset = readPrimitive!uint(file);
            immutable int fileSize = readPrimitive!uint(file);

            immutable string[] pathParts = fullPath.split("/");
            FileNode* current = root;

            foreach (part; pathParts)
            {
                FileNode* child = current.children.get(part, null);

                if (!child)
                {
                    child = new FileNode;
                    current.children[part] = child;
                }

                current = child;
            }

            current.fileInfo = new FileNode.FileInfo(fullPath, fileOffset, fileSize);
        }

        return LoadPackageResult(new VFSZPKDirectory(name, name, file, root, Yes.filePointerOwner), hash);
    }

    bool eligable(string diskPath) const
        in (diskPath)
    {
        import std.file : exists, isFile;
        import std.string : toStringz;

        if (!diskPath.exists || !diskPath.isFile)
            return false;

        FILE* file = fopen(diskPath.toStringz, "rb");

        // Check magic number
        char[4] magic;
        fread(magic.ptr, 4, char.sizeof, file);
        fclose(file);

        return magic == "ZPK1";
    }
}
