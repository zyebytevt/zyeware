module zyeware.vfs.disk.loader;

import std.path : baseName;
import std.file : exists, isDir;

import zyeware.vfs;
import zyeware.vfs.disk;

package(zyeware.vfs):

/// Loads file system directories as Vfs directories.
class VfsDiskLoader : VfsLoader
{
public:
    VfsDirectory load(string diskPath, string name) const
        in (diskPath && name, "Disk path and name must be valid.")
    {
        return new VfsDiskDirectory(name, diskPath);
    }

    bool eligable(string diskPath) const
        in (diskPath, "Disk path must be valid.")
    {
        return diskPath.exists && diskPath.isDir;
    }
}