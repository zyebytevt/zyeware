module zyeware.vfs.zip.loader;

import std.string : split, startsWith;
import std.file : read, isFile;
import std.exception : enforce;
import std.zip;

import zyeware;
import zyeware.vfs.zip.dir : ZipDirectory;

package(zyeware.vfs):

class ZipPackageLoader : PackageLoader
{
package(zyeware.vfs):
    struct FileNode
    {
        ArchiveMember member;
        FileNode*[string] children;
        FileNode* parent;
    }

public:
    Directory load(string diskPath, string scheme) const
        in (diskPath && scheme)
    {
        ZipArchive archive = new ZipArchive(read(diskPath));
        enforce!VfsException(archive.comment.startsWith("ZPK2\x0D\x0A"), "ZIP archive is not a valid ZyeWare package.");

        FileNode* root = new FileNode();

        foreach (ArchiveMember member; archive.directory)
        {
            if (member.name.length == 0 || member.name[$-1] == '/')
                continue;

            FileNode* current = root;

            foreach (string part; split(member.name, "/"))
            {
                FileNode** child = part in current.children;
                if (!child)
                {
                    current.children[part] = new FileNode();
                    current.children[part].parent = current;
                    child = &current.children[part];
                }

                current = *child;
            }

            current.member = member;
        }

        return new ZipDirectory(scheme ~ ':', archive, root);
    }

    bool eligable(string diskPath) const
        in (diskPath, "Disk path must be valid.")
    {
        return isFile(diskPath);
    }
}