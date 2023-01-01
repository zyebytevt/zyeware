// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.environment;

import zyeware.common;
import zyeware.rendering;

abstract class Environment
{
}

class Environment3D : Environment
{
public:
    Renderable sky;
    Color fogColor = Color(0, 0, 0, 0.02);
    Color ambientColor = Color(0.5, 0.5, 0.5, 1);
}