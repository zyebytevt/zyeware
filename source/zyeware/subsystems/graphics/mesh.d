// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.mesh;

import std.string : format;
import std.path : extension;
import std.conv : to;
import std.typecons : Rebindable;

import inmath.linalg;

import zyeware;
import zyeware.subsystems.graphics;

@asset(Yes.cache)
class Mesh2d
{
protected:
    const(Vertex2d[]) mVertices;
    const(uint[]) mIndices;
    const(Material) mMaterial;
    const(Texture2d) mTexture;

public:
    this(in Vertex2d[] vertices, in uint[] indices, in Material material, in Texture2d texture)
    {
        mVertices = vertices;
        mIndices = indices;
        mMaterial = material;
        mTexture = texture;
    }

    const(Vertex2d[]) vertices() pure const nothrow
    {
        return mVertices;
    }

    const(uint[]) indices() pure const nothrow
    {
        return mIndices;
    }

    const(Material) material() pure const nothrow
    {
        return mMaterial;
    }

    const(Texture2d) texture() pure const nothrow
    {
        return mTexture;
    }
}

// =================================================================================================

@asset(Yes.cache)
class Mesh3d : NativeObject
{
protected:
    NativeHandle mNativeHandle;

    Rebindable!(const(Material)) mMaterial;

    pragma(inline, true) static vec3 calculateSurfaceNormal(vec3 p1, vec3 p2, vec3 p3) nothrow pure
    {
        immutable vec3 u = p2 - p1;
        immutable vec3 v = p3 - p1;

        return u.cross(v);
    }

    static void calculateNormals(ref Vertex3d[] vertices, in uint[] indices) nothrow pure
    in (vertices, "Vertices cannot be null.")
    in (indices, "Indices cannot be null.")
    {
        // First, calculate all missing vertex normals
        for (size_t i; i < indices.length; i += 3)
        {
            Vertex3d* v1 = &vertices[indices[i]],
                v2 = &vertices[indices[i + 1]], v3 = &vertices[indices[i + 2]];

            // If one of the vertices already has a normal, continue on
            if (v1.normal != vec3(0) || v2.normal != vec3(0) || v3.normal != vec3(0))
                continue;

            immutable vec3 normal = calculateSurfaceNormal(v1.position, v2.position, v3.position);

            v1.normal += normal;
            v2.normal += normal;
            v3.normal += normal;
        }

        // Secondly, normalize all normals
        foreach (ref Vertex3d v; vertices)
            v.normal = v.normal.normalized;
    }

public:
    this(in Vertex3d[] vertices, in uint[] indices, in Material material)
    in (vertices, "Vertices cannot be null.")
    in (indices, "Indices cannot be null.")
    {
        mNativeHandle = GraphicsSubsystem.callbacks.createMesh(vertices, indices);
        mMaterial = material;
    }

    ~this()
    {
        GraphicsSubsystem.callbacks.freeMesh(mNativeHandle);
    }

    const(void)* handle() const nothrow pure
    {
        return mNativeHandle;
    }

    static Mesh3d load(string path)
    in (path, "Path cannot be null.")
    {
        Mesh3d mesh;

        switch (path.extension)
        {
        case ".obj":
            mesh = loadFromOBJFile(path);
            break;

        default:
            throw new RenderException(format!"Could not find suitable mesh loader for '%s'."(path));
        }

        if (Files.hasFile(path ~ ".props")) // Properties file exists
        {
            try
            {
                SDLNode* root = loadSdlDocument(path ~ ".props");
                mesh.mMaterial = AssetManager.load!Material(
                    root.expectChildValue!string("material"));
            }
            catch (Exception ex)
            {
                Logger.core.warning("Failed to parse properties file for '%s': %s",
                    path, ex.message);
            }
        }

        return mesh;
    }
}

private:

Mesh3d loadFromOBJFile(string path)
in (path, "Path cannot be null.")
{
    import std.string : splitLines, strip, startsWith, split;
    import std.conv : to;

    File file = Files.open(path);
    scope (exit)
        file.close();
    string content = file.readAll!string;

    vec4[] positions;
    vec2[] uvs;
    vec3[] normals;

    Vertex3d[] vertices;
    uint[] indices;

    size_t[size_t] positionToVertexIndex;
    size_t lineNr;
    string currentObjectName = null;

parseLoop:
    foreach (string line; content.splitLines)
    {
        ++lineNr;
        line = line.strip;

        // Skip comment or blank lines
        if (line.startsWith("#") || line.length == 0)
            continue;

        string[] element = line.split();

        switch (element[0])
        {
        case "o": // Object name
            if (element.length < 2)
            {
                Logger.core.warning("Malformed object name in '%s' at line %d.", path, lineNr);
                continue;
            }

            if (currentObjectName)
            {
                Logger.core.info("Loading OBJs with multiple objects currently not supported. ('%s')",
                    path);
                break parseLoop;
            }

            currentObjectName = element[1];
            break;

        case "v": // Vertex position
            if (element.length < 4)
            {
                Logger.core.warning("Malformed vertex element in '%s' at line %d.", path, lineNr);
                continue;
            }

            immutable float x = element[1].to!float;
            immutable float y = element[2].to!float;
            immutable float z = element[3].to!float;
            float w = 1;

            if (element.length > 4)
                w = element[4].to!float;

            positions ~= vec4(x, y, z, w);
            break;

        case "vt": // UV
            if (element.length < 2)
            {
                Logger.core.warning("Malformed UV element in '%s' at line %d.", path, lineNr);
                continue;
            }

            immutable float u = element[1].to!float;
            float v;

            if (element.length > 2)
                v = element[2].to!float;

            uvs ~= vec2(u, v);
            break;

        case "vn": // Vertex normal
            if (element.length < 4)
            {
                Logger.core.warning("Malformed normal element in '%s' at line %d.", path, lineNr);
                continue;
            }

            normals ~= vec3(element[1].to!float, element[2].to!float, element[3].to!float);
            break;

        case "f": // Face
            foreach (string vertex; element[1 .. $])
            {
                string[] vertexAttribs = vertex.split("/");

                // To keep code short, put it into this function.
                // Check if vertex attribute exists, if so, get proper index.
                // Negative value from end, positive value starts at 1.
                size_t getAttrib(size_t idx, size_t arrayLength)
                {
                    if (vertexAttribs.length > idx && vertexAttribs[idx] != "")
                    {
                        ptrdiff_t value = vertexAttribs[idx].to!ptrdiff_t;

                        if (value < 0)
                            return arrayLength - value;
                        else
                            return cast(size_t) value - 1;
                    }
                    else
                        return size_t.max;
                }

                immutable size_t posIdx = getAttrib(0, positions.length);
                immutable size_t uvIdx = getAttrib(1, uvs.length);
                immutable size_t normalIdx = getAttrib(2, normals.length);

                // Check if this vertex was already processed. If so, only add index.
                size_t* vertexIdx = posIdx in positionToVertexIndex;

                if (vertexIdx)
                    indices ~= cast(uint)*vertexIdx;
                else
                {
                    Vertex3d v;

                    v.position = positions[posIdx].xyz;

                    if (uvIdx != size_t.max)
                        v.uv = uvs[uvIdx];

                    if (normalIdx != size_t.max)
                        v.normal = normals[normalIdx];

                    positionToVertexIndex[posIdx] = vertices.length;
                    indices ~= cast(uint) vertices.length;
                    vertices ~= v;
                }
            }
            break;

        default:
            Logger.core.debug_("Unrecognized element '%s' in '%s' at line %d.",
                element[0], path, lineNr);
        }
    }

    // TODO: Load materials someday
    return new Mesh3d(vertices, indices, null);
}
