// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.renderable;

import zyeware;
import zyeware.subsystems.graphics;

interface Renderable3d
{
    inout(BufferGroup) bufferGroup() @nogc pure inout nothrow;
    inout(Material) material() @nogc pure inout nothrow;
}