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

import zyeware.utils.tokenizer;

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
        auto t = Tokenizer(["shader", "extends", "parameter", "texture"]);
        t.load(path);

        bool isRoot;
        string resourcePath;
        Parameter[string] parameters;
        Texture[] textures;

        if (t.consume(Token.Type.keyword, "shader"))
        {
            isRoot = true;
            resourcePath = t.expect(Token.Type.string, null, "Expected path to shader.").value;
        }
        else if (t.consume(Token.Type.keyword, "extends"))
        {
            isRoot = false;
            resourcePath = t.expect(Token.Type.string, null, "Expected path to material.").value;
        }
        else
            throw new ResourceException("Expected 'shader' or 'extends' as first instruction.");

        while (!t.isEof)
        {
            if (t.consume(Token.Type.keyword, "parameter"))
            {
                immutable string name = t.expect(Token.Type.identifier, null, "Expected parameter name.").value;

                if (t.consume(Token.Type.delimiter, "("))
                {
                    string[] values;
                    while (!t.isEof)
                    {
                        values ~= t.get().value;
                        if (t.consume(Token.Type.delimiter, ")"))
                            break;
                        else
                            t.expect(Token.Type.delimiter, ",", "Expected comma between values.");
                    }
                    
                    switch (values.length)
                    {
                    case 2:
                        parameters[name] = Parameter(Vector2f(values[0].to!float, values[1].to!float));
                        break;
                    
                    case 3:
                        parameters[name] = Parameter(Vector3f(values[0].to!float, values[1].to!float, values[2].to!float));
                        break;

                    case 4:
                        parameters[name] = Parameter(Vector4f(values[0].to!float, values[1].to!float, values[2].to!float, values[3].to!float));
                        break;

                    default:
                        throw new RenderException(format!"Invalid number of values for vector '%s'."(name));
                    }
                }
                else
                {
                    Token tk = t.get();

                    switch (tk.type)
                    {
                    case Token.Type.integer:
                        parameters[name] = Parameter(tk.value.to!int);
                        break;
                    
                    case Token.Type.decimal:
                        parameters[name] = Parameter(tk.value.to!float);
                        break;

                    default:
                        throw new RenderException(format!"Invalid parameter value for '%s'."(name));
                    }
                }
            }
            else if (t.consume(Token.Type.keyword, "texture"))
            {
                immutable string type = t.expect(Token.Type.identifier, null, "Expected texture type.").value;

                switch (type)
                {
                case "two":
                    textures ~= AssetManager.load!Texture2D(t.expect(Token.Type.string, null, "Expected path to texture.").value);
                    break;

                case "cube":
                    textures ~= AssetManager.load!TextureCubeMap(t.expect(Token.Type.string, null, "Expected path to texture.").value);
                    break;

                case "null":
                    textures ~= null;
                    break;

                default:
                    throw new RenderException(format!"Unknown texture type '%s'."(type));
                }
            }
            else
                throw new ResourceException(format!"Unknown instruction '%s'."(t.get().value));
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