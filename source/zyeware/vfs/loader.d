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
    VFSDirectory load(string diskPath, string name) const;

    /// Returns `true` if the given entry is valid for loading by this loader, `false` otherwise.
    bool eligable(string diskPath) const;
}