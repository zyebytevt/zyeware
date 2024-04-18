// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.api.types;

package(zyeware.platform.opengl):

struct MeshData
{
    uint vao;
    uint vbo;
    uint ibo;
}

struct FramebufferData
{
    uint id;
    uint colorAttachmentId;
    uint depthAttachmentId;
}

struct UniformLocationKey
{
    uint id;
    string name;
}
