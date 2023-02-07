// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.shader;

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
interface Shader
{
public:
    void bind() const;

    size_t textureCount() pure const nothrow;

    static Shader create()
    {
        return RenderAPI.sCreateShaderImpl();
    }

    static Shader load(string path)
    {
        return RenderAPI.sLoadShaderImpl(path);
    }
}