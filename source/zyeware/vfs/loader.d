// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.loader;

import zyeware;
import zyeware.vfs;

/// Interface for all Vfs loaders. They are responsible for checking and loading various
/// types of files or directories into the Vfs.
interface VfsLoader
{
public:
    /// Loads the given entry.
    /// Returns: The loaded directory as VfsDirectory.
    VfsDirectory load(string diskPath, string name) const;

    /// Returns `true` if the given entry is valid for loading by this loader, `false` otherwise.
    bool eligable(string diskPath) const;
}