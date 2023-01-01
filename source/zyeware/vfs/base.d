// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.base;

/// Contains the base properties for all VFS entries.
abstract class VFSBase
{
protected:
    immutable string mFullname;
    immutable string mName;

    this(string fullname, string name) pure nothrow
        in (fullname && name)
    {
        mFullname = fullname;
        mName = name;
    }

public:
    /// The full name of this entry, including path.
    string fullname() pure const nothrow
    {
        return mFullname;
    }

    /// The name of this entry, excluding path.
    string name() pure const nothrow
    {
        return mName;
    }
}
