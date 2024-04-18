// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.renderer2d.types;

import zyeware;

package(zyeware.platform.opengl):

struct BatchVertex2d
{
    vec4 position;
    vec2 uv;
    color modulate;
    float textureIndex;
}

struct GlBuffer
{
    uint vao;
    uint vbo;
    uint ibo;
}
