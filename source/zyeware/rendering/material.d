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

    this(Shader shader)
        in (shader, "Shader cannot be null.")
    {
        mShader = shader;
        mIsRoot = true;

        //mTextureSlots.length = shader.textureCount;
    }

    this(Material parent)
        in (parent, "Parent material cannot be null.")
    {
        mParent = parent;
        mIsRoot = false;

        //mTextureSlots.length = shader.textureCount;
    }

    void setParameter(T)(string name, T value)
        in (name, "Parameter name cannot be null.")
    {
        mParameters[name] = Parameter(value);
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

    void bind()
    {
        //shader.bind();

        // Bind constant buffer, if it exists
        //ConstantBuffer bindBuffer = buffer;

        //if (bindBuffer)
        {
            /*foreach (string entry; buffer.entries)
            {
                Parameter* parameter = getParameter(entry);

                if (!parameter)
                    continue;

                immutable size_t offset = bindBuffer.getEntryOffset(entry);

                (*parameter).match!(
                    (void[] x) => bindBuffer.setData(offset, x),
                    (int x) => bindBuffer.setData(offset, [x]),
                    (float x) => bindBuffer.setData(offset, [x]),
                    (Vector2f x) => bindBuffer.setData(offset, x.vector),
                    (Vector3f x) => bindBuffer.setData(offset, x.vector),
                    (Vector4f x) => bindBuffer.setData(offset, x.vector),
                );
            }*/

            //bindBuffer.bind(ConstantBuffer.Slot.modelVariables);
        }

        // Bind textures
        for (size_t i; i < mTextureSlots.length; ++i)
        {
            auto tex = getTexture(i);
            //if (tex)
            //    tex.bind(cast(uint) i);
        }
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

        Parameter[string] parsedParams;
        string[] paramOrder;
        Texture[] parsedTextures;
        // Parse all parameters first

        if (const(ZDLNode*) parameters = document.root.getNode("parameters"))
        {
            foreach (string name, const ref ZDLNode value; parameters.expectValue!ZDLMap)
            {
                paramOrder ~= name;

                if (value.checkValue!ZDLInteger)
                    parsedParams[name] = Parameter(value.expectValue!ZDLInteger.to!int);
                else if (value.checkValue!ZDLFloat)
                    parsedParams[name] = Parameter(value.expectValue!ZDLFloat.to!float);
                else if (value.checkValue!Vector2f)
                    parsedParams[name] = Parameter(value.expectValue!Vector2f);
                else if (value.checkValue!Vector3f)
                    parsedParams[name] = Parameter(value.expectValue!Vector3f);
                else if (value.checkValue!Vector4f)
                    parsedParams[name] = Parameter(value.expectValue!Vector4f);
                else
                    throw new RenderException(format!"Unknown parameter type for '%s'."(name));
            }
        }

        if (const(ZDLNode*) textures = document.root.getNode("textures"))
        {
            foreach (const ref ZDLNode textureNode; document.root.textures.expectValue!ZDLList)
            {
                immutable string texPath = textureNode.path.expectValue!ZDLString;
                immutable string type = textureNode.type.expectValue!ZDLString;

                switch (type)
                {
                case "2d":
                    parsedTextures ~= AssetManager.load!Texture2D(texPath);
                    break;

                case "cube":
                    parsedTextures ~= AssetManager.load!TextureCubeMap(texPath);
                    break;

                default:
                    throw new RenderException(format!"Unknown texture type '%s'."(type));
                }
            }
        }

        // Check if it either inherits a material or is root
        if (const(ZDLNode*) shaderNode = document.root.getNode("shader"))
        {
            Shader shader = AssetManager.load!Shader(shaderNode.expectValue!ZDLString);
            
            /*BufferElement[] bufferElements;
            foreach (string name; paramOrder)
            {
                bufferElements ~= parsedParams[name].match!(
                    (void[] x) => BufferElement(name, BufferElement.Type.none, cast(uint) x.length),
                    (int x) => BufferElement(name, BufferElement.Type.int_),
                    (float x) => BufferElement(name, BufferElement.Type.float_),
                    (Vector2f x) => BufferElement(name, BufferElement.Type.vec2),
                    (Vector3f x) => BufferElement(name, BufferElement.Type.vec3),
                    (Vector4f x) => BufferElement(name, BufferElement.Type.vec4),
                );
            }

            if (bufferElements.length > 0)
                material = new Material(shader, BufferLayout(bufferElements));
            else
                material = new Material(shader);*/
        }
        else if (const(ZDLNode*) extendsNode = document.root.getNode("extends"))
        {
            material = new Material(AssetManager.load!Material(extendsNode.expectValue!ZDLString));
            
        }
        else
            throw new RenderException(format!"Material '%s': Need either 'shader' or 'extends'."(path));

        material.mParameters = parsedParams;
        foreach (size_t index, Texture texture; parsedTextures)
            material.setTexture(cast(uint) index, texture);

        return material;
    }
}