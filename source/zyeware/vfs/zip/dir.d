module zyeware.vfs.zip.dir;

import std.zip;
import std.string : split, format;
import std.exception : enforce;
import std.path : isRooted;

import zyeware;
import zyeware.vfs.zip;

package(zyeware.vfs):

class VFSZipDirectory : VFSDirectory
{
protected:
    alias FileNode = VFSZipLoader.FileNode;

    enum NodeType
    {
        invalid,
        directory,
        file
    }

    FileNode* mRoot;

    NodeType getNodeType(string path) pure const nothrow
    {
        FileNode* current = cast(FileNode*) mRoot;
        foreach (string part; path.split("/"))
        {
            switch (part)
            {
            case "..":
                if (!current.parent)
                    return NodeType.invalid;
                current = current.parent;
                break;
            
            case ".":
                break;

            default:
                FileNode** child = part in current.children;
                if (!child)
                    return NodeType.invalid;
                current = *child;
                break;
            }
        }

        return current.member ? NodeType.file : NodeType.directory;
    }

    FileNode* traversePath(string path) pure const
        in (path, "Path cannot be null.")
    {
        FileNode* current = cast(FileNode*) mRoot;
        foreach (string part; path.split("/"))
        {
            switch (part)
            {
            case "..":
                enforce!VFSException(current.parent, "Cannot go above root directory.");
                current = current.parent;
                break;
            
            case ".":
                break;

            default:
                FileNode** child = part in current.children;
                enforce!VFSException(child, format!"Directory '%s' not found."(part));
                current = *child;
                break;
            }
        }

        return current;
    }

package(zyeware.vfs):
    const ZipArchive mArchive;

    this(string name, in ZipArchive archive, FileNode* root) pure nothrow
    {
        super(name);
        mArchive = archive;
        mRoot = root;
    }

public:
    override VFSDirectory getDirectory(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "Directory name cannot be rooted.");
        FileNode* newRoot = traversePath(name);

        enforce!VFSException(!newRoot.member, format!"'%s' is not a directory."(name));
        return new VFSZipDirectory(name, mArchive, newRoot);
    }

    override VFSFile getFile(string name) const
        in (name, "Name cannot be null.")
    {
        enforce!VFSException(!isRooted(name), "File name cannot be rooted.");
        FileNode* fileNode = traversePath(name);

        enforce!VFSException(fileNode.member, format!"'%s' is not a file."(name));

        // After examination, it seems that the ZipArchive instance
        // isn't actually modified, so casting to mutable is safe. Probably.
        return new VFSZipFile(name, cast(ZipArchive) mArchive, fileNode.member);
    }

    override bool hasDirectory(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        return getNodeType(name) == NodeType.directory;
    }

    override bool hasFile(string name) const nothrow
        in (name, "Name cannot be null.")
    {
        return getNodeType(name) == NodeType.file;
    }

    // TODO: Implement new files and directories methods
    override immutable(string[]) files() const
    {
        return [];
    }

    override immutable(string[]) directories() const
    {
        return [];
    }
}