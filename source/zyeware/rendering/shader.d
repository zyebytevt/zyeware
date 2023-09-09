// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.shader;

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;

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
class Shader
{
protected:
    RID mRid;
    ShaderProperties mProperties;

public:
    this(in ShaderProperties properties)
    {
        mProperties = properties;
        mRid = ZyeWare.graphics.api.createShader(properties);
    }

    ~this()
    {
        ZyeWare.graphics.api.free(mRid);
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

        VFSFile file = VFS.getFile(path);
        immutable string source = file.readAll!string;
        Tag root = parseSource(source);
        file.close();

        ShaderProperties properties;

        void loadShader(ref Tag tag, ShaderProperties.ShaderType type)
        {
            if (string filePath = tag.getAttribute!string("file", null))
            {
                Logger.core.log(LogLevel.verbose, "Loading external shader source '%s'...", filePath);
                VFSFile shaderFile = VFS.getFile(filePath);
                scope(exit) shaderFile.close();

                properties.sources[type] = parseIncludes(shaderFile.readAll!string);
            }
            else
                properties.sources[type] = parseIncludes(tag.getValue!string);
        }

        foreach (ref Tag tag; root.all.tags)
        {
            switch (tag.name)
            {
            case "vertex":
                loadShader(tag, ShaderProperties.ShaderType.vertex);
                break;

            case "fragment":
                loadShader(tag, ShaderProperties.ShaderType.fragment);
                break;

            case "geometry":
                loadShader(tag, ShaderProperties.ShaderType.geometry);
                break;

            case "compute":
                loadShader(tag, ShaderProperties.ShaderType.compute);
                break;

            default:
                Logger.core.log(LogLevel.warning, "'%s' %s: Unknown tag '%s'.",
                    path, tag.location, tag.getFullName());
            }
        }

        return new Shader(properties);
    }
}