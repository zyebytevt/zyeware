module zyeware.vfs.disk.loader;

import std.path : baseName;
import std.file : exists, isDir;

import zyeware;
import zyeware.vfs.disk.dir : VfsDiskDirectory;

package(zyeware.vfs):

/// Loads file system directories as Vfs directories.
class VfsDiskLoader : VfsLoader
{
public:
    VfsDirectory load(string diskPath, string scheme) const
        in (diskPath && vfsPath, "Disk path and VFS path must be valid.")
    {
        return new VfsDiskDirectory(scheme ~ ':', diskPath);
    }

    bool eligable(string diskPath) const
        in (diskPath, "Disk path must be valid.")
    {
        return diskPath.exists && diskPath.isDir;
    }
}