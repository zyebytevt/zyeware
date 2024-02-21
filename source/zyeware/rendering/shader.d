// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.shader;

import std.exception : enforce;
import std.regex : ctRegex, matchAll;
import std.typecons : Tuple;
import std.array : replaceInPlace;
import std.algorithm : countUntil;

import inmath.linalg;

import zyeware;

import zyeware.pal;

struct ShaderProperties
{
    enum ShaderType
    {
        vertex,
        fragment,
        geometry,
        compute
    }

    string[ShaderType] sources;
}

@asset(Yes.cache)
class Shader : NativeObject
{
protected:
    NativeHandle mNativeHandle;
    ShaderProperties mProperties;

public:
    this(ShaderProperties properties)
    {
        mProperties = properties;
        mNativeHandle = Pal.graphics.api.createShader(properties);
    }

    ~this()
    {
        Pal.graphics.api.freeShader(mNativeHandle);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    static Shader load(string path)
        in (path, "Path cannot be null.")
    {
        Logger.core.debug_("Loading shader '%s'...", path);

        string parseIncludes(string source)
        {
            enum includeRegex = ctRegex!("^#include \"(.*)\"$", "m");

            char[] mutableSource = source.dup;
            alias Include = Tuple!(char[], "path", size_t, "position", size_t, "length");
            
            Include[] includes;
            ptrdiff_t offset;
            size_t includeIterations;

            do
            {
                enforce!GraphicsException(++includeIterations < 100,
                    "Too many iterations, possible infinite include recursion.");

                includes.length = 0;
                foreach (m; matchAll(mutableSource, includeRegex))
                    includes ~= Include(m[1], m.pre.length, m.hit.length);

                foreach (ref Include include; includes)
                {
                    File includeFile = Files.open(cast(string) include.path);
                    char[] includeSource = cast(char[]) includeFile.readAll!string;
                    includeFile.close();

                    immutable size_t from = include.position + offset;
                    immutable size_t to = from + include.length;

                    mutableSource.replaceInPlace(from, to, includeSource);
                    offset += cast(ptrdiff_t) includeSource.length - include.length;
                }
            } while (includes.length > 0);

            return mutableSource.idup;
        }

        ShaderProperties properties;

        void loadShader(string filePath, ShaderProperties.ShaderType type)
        {
            Logger.core.verbose("Loading external shader source '%s'...", filePath);
            File shaderFile = Files.open(filePath);
            scope(exit) shaderFile.close();

            properties.sources[type] = parseIncludes(shaderFile.readAll!string);
        }

        SDLNode* root = loadSdlDocument(path);

        import std.traits : EnumMembers;
        import std.conv : to;

        static foreach (type; EnumMembers!(ShaderProperties.ShaderType))
        {
            if (SDLNode* shaderTypeNode = root.getChild(type.to!string))
            {
                immutable string shaderPath = shaderTypeNode.expectValue!string();
                loadShader(shaderPath, type);
            }
        }

        return new Shader(properties);
    }
}