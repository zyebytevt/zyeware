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

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;
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
        mNativeHandle = Pal.graphicsDriver.createShader(properties);
    }

    ~this()
    {
        Pal.graphicsDriver.freeShader(mNativeHandle);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    static Shader load(string path)
        in (path, "Path cannot be null.")
    {
        Logger.core.log(LogLevel.debug_, "Loading shader '%s'...", path);

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
                    VFSFile includeFile = VFS.getFile(cast(string) include.path);
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

        auto document = ZDLDocument.load(path);

        ShaderProperties properties;

        void loadShader(string filePath, ShaderProperties.ShaderType type)
        {
            Logger.core.log(LogLevel.verbose, "Loading external shader source '%s'...", filePath);
            VFSFile shaderFile = VFS.getFile(filePath);
            scope(exit) shaderFile.close();

            properties.sources[type] = parseIncludes(shaderFile.readAll!string);
        }

        foreach (string name, const ref ZDLNode value; document.root.opengl.expectValue!ZDLMap)
        {
            switch (name)
            {
            case "vertex":
                loadShader(value.expectValue!ZDLString, ShaderProperties.ShaderType.vertex);
                break;

            case "fragment":
                loadShader(value.expectValue!ZDLString, ShaderProperties.ShaderType.fragment);
                break;

            default:
                Logger.core.log(LogLevel.warning, "'%s': Unknown node '%s'.",
                    path, name);
            }
        }

        return new Shader(properties);
    }
}