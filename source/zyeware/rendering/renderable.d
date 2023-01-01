// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderable;

import zyeware.rendering;

interface Renderable
{
    inout(BufferGroup) bufferGroup() pure inout nothrow;
    inout(Material) material() pure inout nothrow;
}