module zyeware.vfs.disk.dir;

import std.exception : enforce, assumeWontThrow;
import std.string : format;
import std.path : isRooted, buildPath, baseName;
import std.file : exists, isDir, isFile, dirEntries, SpanMode; 

import zyeware;
import zyeware.vfs.dir : isWriteMode;
import zyeware.vfs.disk;

package(zyeware.vfs):

class VfsDiskDirectory : VfsDirectory
{
protected:
    immutable string mDiskPath;

package(zyeware.vfs):
    this(string name, string diskPath) pure nothrow
        in (diskPath, "Disk path cannot be null!")
    {
        super(name);
        mDiskPath = diskPath;
    }

public:
    override VfsDirectory getDirectory(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VfsException(!isRooted(name), "Subdirectory name cannot be rooted.");
        enforce!VfsException(hasDirectory(name), format!"Subdirectory '%s' not found."(name));

        return new VfsDiskDirectory(name, buildPath(mDiskPath, name));
    }

    override VfsFile getFile(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VfsException(!isRooted(name), "File name cannot be rooted.");
        enforce!VfsException(hasFile(name), format!"File '%s' not found."(name));

        return new VfsDiskFile(name, buildPath(mDiskPath, name));
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