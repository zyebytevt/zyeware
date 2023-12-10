module zyeware.vfs.disk.dir;

static import std.path;
import std.exception : enforce, assumeWontThrow;
import std.string : format;
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
    this(string path, string diskPath) pure nothrow
        in (diskPath, "Disk path cannot be null!")
    {
        super(path);
        mDiskPath = diskPath;
    }

public:
    override VfsDirectory getDirectory(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VfsException(!std.path.isRooted(name), "Subdirectory name cannot be rooted.");

        immutable string newPath = buildPath(mPath, name);

        enforce!VfsException(hasDirectory(name), format!"Subdirectory '%s' not found."(newPath));
        return new VfsDiskDirectory(newPath, std.path.buildPath(mDiskPath, name));
    }

    override VfsFile getFile(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VfsException(!std.path.isRooted(name), "File name cannot be rooted.");

        immutable string newPath = buildPath(mPath, name);

        enforce!VfsException(hasFile(name), format!"File '%s' not found."(newPath));
        return new VfsDiskFile(newPath, std.path.buildPath(mDiskPath, name));
    }

    override bool hasDirectory(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        immutable string path = std.path.buildPath(mDiskPath, name);
        return exists(path) && isDir(path).assumeWontThrow;
    }

    override bool hasFile(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        immutable string path = std.path.buildPath(mDiskPath, name);

        try return exists(path) && isFile(path);
        catch (Exception) return false;
    }

    override immutable(string[]) files() const
    {
        string[] result;
        foreach (string path; dirEntries(mDiskPath, SpanMode.shallow))
            if (isFile(path))
                result ~= path;

        return result.idup;
    }

    override immutable(string[]) directories() const
    {
        string[] result;
        foreach (string path; dirEntries(mDiskPath, SpanMode.shallow))
            if (isDir(path))
                result ~= path;

        return result.idup;
    }
}