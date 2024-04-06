// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.vfs.loader;

import zyeware;

/// Interface for all Files loaders. They are responsible for checking and loading various
/// types of files or directories into the Files.
interface PackageLoader
{
public:
    /// Loads the given entry.
    /// Returns: The loaded directory as Directory.
    Directory load(string diskPath, string scheme) const;

    /// Returns `true` if the given entry is valid for loading by this loader, `false` otherwise.
    bool eligable(string diskPath) const;
}
