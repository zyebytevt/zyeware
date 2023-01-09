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

import sdlang;
import inmath.linalg;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class Material
{
protected:
    union
    {
        struct
        {
            Shader mShader;
            ConstantBuffer mBuffer;
        }

        Material mParent;
    }

    bool mIsRoot;
    Rebindable!(const Texture)[] mTextureSlots;
    Parameter[string] mParameters;

public:
    alias Parameter = SumType!(void[], int, int[], float, Vector2f, Vector3f, Vector4f, Matrix4f);

    this(Shader shader)
        in (shader, "Shader cannot be null.")
    {
        mShader = shader;
        mIsRoot = true;

        mTextureSlots.length = shader.textureCount;
    }

    this(Shader shader, in BufferLayout layout)
        in (shader, "Shader cannot be null.")
    {
        mShader = shader;
        mIsRoot = true;

        mTextureSlots.length = shader.textureCount;
        mBuffer = new ConstantBuffer(layout);
    }

    this(Material parent)
        in (parent, "Parent material cannot be null.")
    {
        mParent = parent;
        mIsRoot = false;

        mTextureSlots.length = shader.textureCount;
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
        shader.bind();

        // Bind constant buffer, if it exists
        ConstantBuffer bindBuffer = buffer;

        if (bindBuffer)
        {
            foreach (string entry; buffer.entries)
            {
                Parameter* parameter = getParameter(entry);

                if (!parameter)
                    continue;

                immutable size_t offset = bindBuffer.getEntryOffset(entry);

                (*parameter).match!(
                    (void[] x) => bindBuffer.setData(offset, x),
                    (int x) => bindBuffer.setData(offset, [x]),
                    //(int[] x) => bindBuffer.setData(offset, x),
                    (float x) => bindBuffer.setData(offset, [x]),
                    (Vector2f x) => bindBuffer.setData(offset, x.vector),
                    (Vector3f x) => bindBuffer.setData(offset, x.vector),
                    (Vector4f x) => bindBuffer.setData(offset, x.vector),
                    //(Matrix4f x) => bindBuffer.setData(offset, x.matrix),
                );
            }

            bindBuffer.bind(ConstantBuffer.Slot.modelVariables);
        }

        // Bind textures
        for (size_t i; i < mTextureSlots.length; ++i)
        {
            auto tex = getTexture(i);
            if (tex)
                tex.bind(cast(uint) i);
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

    inout(ConstantBuffer) buffer() inout nothrow
    {
        return root.mBuffer;
    }

    static Material load(string path)
        in (path, "Path cannot be null.")
    {
        VFSFile file = VFS.getFile(path);
        Tag root = parseSource(file.readAll!string);
        file.close();

        Material material;

        Parameter[string] parsedParams;
        string[] paramOrder;
        Texture[] parsedTextures;
        // Parse all parameters first

        foreach (Tag paramTag; root.maybe.namespaces["parameter"].tags)
        {
            immutable string name = paramTag.name;
            immutable string value = paramTag.expectAttribute!string("value");
            immutable string type = paramTag.expectAttribute!string("type");

            paramOrder ~= name;

            switch (type)
            {
            case "raw":
                parsedParams[name] = Parameter(cast(void[]) value.to!(ubyte[]));
                break;

            case "int":
                parsedParams[name] = Parameter(value.to!int);
                break;

            case "int[]":
                parsedParams[name] = Parameter(value.to!(int[]));
                break;

            case "float":
                parsedParams[name] = Parameter(value.to!float);
                break;

            case "vec2":
                auto values = value.split(",").map!(x => x.to!float).array;
                enforce!RenderException(values.length == 2, "Not enough arguments for vec2.");

                parsedParams[name] = Parameter(Vector2f(values[0], values[1]));
                break;

            case "vec3":
                auto values = value.split(",").map!(x => x.to!float).array;
                enforce!RenderException(values.length == 3, "Not enough arguments for vec3.");

                parsedParams[name] = Parameter(Vector3f(values[0], values[1], values[2]));
                break;

            case "vec4":
                auto values = value.split(",").map!(x => x.to!float).array;
                enforce!RenderException(values.length == 2, "Not enough arguments for vec4.");

                parsedParams[name] = Parameter(Vector4f(values[0], values[1], values[2], values[3]));
                break;

            default:
                throw new RenderException(format!"Unknown parameter type '%s'."(type));
            }
        }

        foreach (Tag textureTag; root.tags.filter!(x => x.name == "texture"))
        {
            immutable string texPath = textureTag.expectAttribute!string("path");
            immutable string type = textureTag.expectAttribute!string("type");

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

        // Check if it either inherits a material or is root
        if (Tag shaderTag = root.getTag("shader"))
        {
            Shader shader = AssetManager.load!Shader(shaderTag.expectValue!string);
            
            BufferElement[] bufferElements;
            foreach (string name; paramOrder)
            {
                bufferElements ~= parsedParams[name].match!(
                    (void[] x) => BufferElement(name, BufferElement.Type.none, cast(uint) x.length),
                    (int x) => BufferElement(name, BufferElement.Type.int_),
                    //(int[] x) => BufferElement(name, BufferElement.Type.int_, cast(uint) x.length),
                    (float x) => BufferElement(name, BufferElement.Type.float_),
                    (Vector2f x) => BufferElement(name, BufferElement.Type.vec2),
                    (Vector3f x) => BufferElement(name, BufferElement.Type.vec3),
                    (Vector4f x) => BufferElement(name, BufferElement.Type.vec4),
                    //(Matrix4f x) => BufferElement(name, BufferElement.Type.mat4),
                );
            }

            if (bufferElements.length > 0)
                material = new Material(shader, BufferLayout(bufferElements));
            else
                material = new Material(shader);
        }
        else if (Tag extendsTag = root.getTag("extends"))
        {
            material = new Material(AssetManager.load!Material(extendsTag.expectValue!string));
            
        }
        else
            throw new RenderException(format!"Material '%s': Need either 'shader' or 'extends'."(path));

        material.mParameters = parsedParams;
        foreach (size_t index, Texture texture; parsedTextures)
            material.setTexture(cast(uint) index, texture);

        return material;
    }
}