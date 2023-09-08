// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderable;

import zyeware.rendering;

/// Describes an object that can be processed by the rendering subsystem.
interface Renderable
{
    /// Returns the RID of this object. If it has not yet been registered
    /// by the rendering subsystem, it will do so before returning.
    RID rid() pure const nothrow;
}