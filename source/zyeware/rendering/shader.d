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
class Shader : Renderable
{
protected:
    RID mRid;

public:
    this()
    {
        
    }

    static Shader load(string path)
    {
        return GraphicsAPI.sLoadShaderImpl(path);
    }
}