// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.rendering.environment;

import zyeware;

struct Environment3D
{
    Mesh3d sky;
    color fogColor = color(0, 0, 0, 0.02);
    color ambientColor = color(0.5, 0.5, 0.5, 1);
}
