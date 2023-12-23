// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.material;

import std.sumtype : SumType, match;
import std.string : format, startsWith;
import std.exception : enforce;
import std.typecons : Rebindable;
import std.conv : to;
import std.string : split, format;
import std.algorithm : map, filter, sort, uniq;
import std.array : array;

import inmath.linalg;

import zyeware;

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
    alias Parameter = SumType!(void[], int, float, vec2, vec3, vec4);

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

    ref inout(Parameter) getParameter(string name) inout
        in (name, "Parameter name cannot be null.")
    {
        auto parameter = name in mParameters;
        if (parameter)
            return *parameter;

        if (!mIsRoot)
            return mParent.getParameter(name);

        assert(false, "Trying to get non-existant parameter.");
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

    string[] parameterList() const nothrow
    {
        string[] list;

        Material current = cast(Material) this;

        while (true)
        {
            list ~= current.mParameters.keys;
            if (current.mIsRoot)
                break;

            current = current.mParent;
        }

        return list.sort.uniq.array;
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
        SDLNode* root = loadSdlDocument(path);
        
        bool isRoot;
        string resourcePath;
        Parameter[string] parameters;
        Texture[] textures;

        if (auto shaderNode = root.getChild("shader"))
        {
            isRoot = true;
            resourcePath = shaderNode.expectValue!string();
        }
        else if (auto extendsNode = root.getChild("extends"))
        {
            isRoot = false;
            resourcePath = extendsNode.expectValue!string();
        }
        else
            throw new ResourceException("Expected either 'shader' or 'extends' instruction.");

        if (auto parametersNode = root.getChild("parameters"))
        {
            for (size_t i; i < parametersNode.children.length; ++i)
            {
                SDLNode* parameterNode = &parametersNode.children[i];

                immutable string type = parameterNode.expectAttributeValue!string("type");

                switch (type)
                {
                case "int":
                    parameters[parametersNode.name] = Parameter(parameterNode.expectAttributeValue!int("value"));
                    break;

                case "float":
                    parameters[parametersNode.name] = Parameter(parameterNode.expectAttributeValue!float("value"));
                    break;

                case "vec2":
                    parameters[parametersNode.name] = Parameter(parameterNode.expectAttributeValue!vec2("value"));
                    break;

                case "vec3":
                    parameters[parametersNode.name] = Parameter(parameterNode.expectAttributeValue!vec3("value"));
                    break;

                case "vec4":
                    parameters[parametersNode.name] = Parameter(parameterNode.expectAttributeValue!vec4("value"));
                    break;

                default:
                    throw new ResourceException(format!"Unknown parameter type '%s'."(type));
                }
            }
        }

        if (auto texturesNode = root.getChild("textures"))
        {
            for (size_t i; i < texturesNode.children.length; ++i)
            {
                SDLNode* textureNode = &texturesNode.children[i];

                enforce!ResourceException(textureNode.name == "texture", "Expected 'texture' node.");

                immutable string type = textureNode.expectAttributeValue!string("type");

                switch (type)
                {
                case "two":
                    textures ~= AssetManager.load!Texture2D(textureNode.expectAttributeValue!string("path"));
                    break;

                case "cube":
                    textures ~= AssetManager.load!TextureCubeMap(textureNode.expectAttributeValue!string("path"));
                    break;

                case "null":
                    textures ~= null;
                    break;

                default:
                    throw new ResourceException(format!"Unknown texture type '%s'."(type));
                }
            }
        }

        Material material;
        // Check if it either inherits a material or is root
        if (isRoot)
            material = new Material(AssetManager.load!Shader(resourcePath), textures.length);
        else
            material = new Material(AssetManager.load!Material(resourcePath));

        material.mParameters = parameters;
        foreach (size_t index, Texture texture; textures)
            material.setTexture(cast(uint) index, texture);

        return material;
    }
}