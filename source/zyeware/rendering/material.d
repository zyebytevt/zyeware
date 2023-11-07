// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.material;

//import std.variant : Algebraic, visit;
import std.sumtype : SumType, match;
//import std.sumtype;
import std.string : format, startsWith;
import std.exception : enforce;
import std.typecons : Rebindable;
import std.conv : to;
import std.string : split;
import std.algorithm : map, filter;
import std.array : array;

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class Material
{
protected:
    union
    {
        Shader mShader;
        Material mParent;
    }

    bool mIsRoot;
    Rebindable!(const Texture)[] mTextureSlots;
    Parameter[string] mParameters;

public:
    alias Parameter = SumType!(void[], int, float, Vector2f, Vector3f, Vector4f);

    this(Shader shader, size_t textureSlots = 1)
        in (shader, "Shader cannot be null.")
    {
        mShader = shader;
        mIsRoot = true;

        mTextureSlots.length = textureSlots;
    }

    this(Material parent)
        in (parent, "Parent material cannot be null.")
    {
        mParent = parent;
        mIsRoot = false;

        mTextureSlots.length = parent.mTextureSlots.length;
    }

    void setParameter(string name, Parameter value)
    {
        mParameters[name] = value;
    }

    void setParameter(T)(string name, T value)
        in (name, "Parameter name cannot be null.")
    {
        setParameter(Parameter(value));
    }

    Parameter* getParameter(string name)
        in (name, "Parameter name cannot be null.")
    {
        auto parameter = name in mParameters;
        if (parameter)
            return parameter;

        if (!mIsRoot)
            return mParent.getParameter(name);

        return null;
    }

    bool removeParameter(string name) nothrow
        in (name, "Parameter name cannot be null.")
    {
        return mParameters.remove(name);
    }

    void setTexture(size_t idx, in Texture texture)
    {
        enforce!RenderException(idx < mTextureSlots.length,
            format!"Invalid texture slot '%d'. (Max %d slots)"(idx, mTextureSlots.length));
        
        mTextureSlots[idx] = texture;
    }

    const(Texture) getTexture(size_t idx) const
    {
        enforce!RenderException(idx < mTextureSlots.length,
            format!"Invalid texture slot '%d'. (Max %d slots)"(idx, mTextureSlots.length));

        auto tex = mTextureSlots[idx];
        if (tex)
            return tex;

        if (!mIsRoot)
            return mParent.getTexture(idx);

        return null;
    }

    void removeTexture(size_t idx)
    {
        enforce!RenderException(idx < mTextureSlots.length,
            format!"Invalid texture slot '%d'. (Max %d slots)"(idx, mTextureSlots.length));

        mTextureSlots[idx] = null;
    }

    inout(Material) parent() inout nothrow
    {
        if (mIsRoot)
            return null;

        return mParent;
    }

    inout(Material) root() inout nothrow
    {
        Material root = cast(Material) this;
        while (!root.mIsRoot)
            root = root.mParent;

        return cast(inout Material) root;
    }

    inout(Shader) shader() inout nothrow
    {
        return root.mShader;
    }

    static Material load(string path)
        in (path, "Path cannot be null.")
    {
        auto document = ZDLDocument.load(path);

        Material material;

        Parameter[string] parameters;
        Texture[] textures;
        // Parse all parameters first

        if (const(ZDLNode*) parametersNode = document.root.getNode("parameters"))
        {
            foreach (string name, const ref ZDLNode value; parametersNode.expectValue!ZDLMap)
            {
                if (value.checkValue!ZDLInteger)
                    parameters[name] = Parameter(value.expectValue!ZDLInteger.to!int);
                else if (value.checkValue!ZDLFloat)
                    parameters[name] = Parameter(value.expectValue!ZDLFloat.to!float);
                else if (value.checkValue!Vector2f)
                    parameters[name] = Parameter(value.expectValue!Vector2f);
                else if (value.checkValue!Vector3f)
                    parameters[name] = Parameter(value.expectValue!Vector3f);
                else if (value.checkValue!Vector4f)
                    parameters[name] = Parameter(value.expectValue!Vector4f);
                else
                    throw new RenderException(format!"Unknown parameter type for '%s'."(name));
            }
        }

        if (const(ZDLNode*) texturesNode = document.root.getNode("textures"))
        {
            foreach (const ref ZDLNode textureNode; texturesNode.expectValue!ZDLList)
            {
                immutable string type = textureNode.type.expectValue!ZDLString.to!string;

                switch (type)
                {
                case "2d":
                    textures ~= AssetManager.load!Texture2D(textureNode.path.expectValue!ZDLString.to!string);
                    break;

                case "cube":
                    textures ~= AssetManager.load!TextureCubeMap(textureNode.path.expectValue!ZDLString.to!string);
                    break;

                case "null":
                    textures ~= null;
                    break;

                default:
                    throw new RenderException(format!"Unknown texture type '%s'."(type));
                }
            }
        }

        // Check if it either inherits a material or is root
        if (const(ZDLNode*) shaderNode = document.root.getNode("shader"))
        {
            material = new Material(AssetManager.load!Shader(shaderNode.path.expectValue!ZDLString.to!string), textures.length);
        }
        else if (const(ZDLNode*) extendsNode = document.root.getNode("extends"))
        {
            material = new Material(AssetManager.load!Material(extendsNode.expectValue!ZDLString.to!string));
        }
        else
            throw new RenderException(format!"Material '%s': Need either 'shader' or 'extends'."(path));

        material.mParameters = parameters;
        foreach (size_t index, Texture texture; textures)
            material.setTexture(cast(uint) index, texture);

        return material;
    }
}