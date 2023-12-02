module zyeware.vfs.disk.dir;

import std.exception : enforce, assumeWontThrow;
import std.string : format;
import std.path : isRooted, buildPath, baseName;
import std.file : exists, isDir, isFile, dirEntries, SpanMode; 

import zyeware.common;
import zyeware.vfs.dir : isWriteMode;
import zyeware.vfs.disk;

package(zyeware.vfs):

class VFSDiskDirectory : VFSDirectory
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
    override VFSDirectory getDirectory(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "Subdirectory name cannot be rooted.");
        enforce!VFSException(hasDirectory(name), format!"Subdirectory '%s' not found."(name));

        return new VFSDiskDirectory(name, buildPath(mDiskPath, name));
    }

    override VFSFile getFile(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "File name cannot be rooted.");
        enforce!VFSException(hasFile(name), format!"File '%s' not found."(name));

        return new VFSDiskFile(name, buildPath(mDiskPath, name));
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