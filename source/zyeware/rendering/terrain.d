// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.terrain;

import std.math : fmod;

import zyeware.common;
import zyeware.rendering;

class Terrain : Renderable
{
protected:
    Mesh mMesh;
    TerrainProperties mProperties;

    static void generateData(in TerrainProperties properties, out Mesh.Vertex[] vertices, out uint[] indices)
    {
        immutable size_t totalVertices = properties.vertexCount.x * properties.vertexCount.y;
        assert(properties.heightData.length == totalVertices, "Invalid height data length.");

        vertices = new Mesh.Vertex[totalVertices];
        indices = new uint[6 * (properties.vertexCount.x - 1) * (properties.vertexCount.y - 1)];

        size_t currentVertex;
        for (size_t gz; gz < properties.vertexCount.y; ++gz)
            for (size_t gx; gx < properties.vertexCount.x; ++gx)
            {
                immutable uv = Vector2f(cast(float) gx / (properties.vertexCount.x - 1),
                    cast(float) gz / (properties.vertexCount.y - 1));

                vertices[currentVertex] = Mesh.Vertex(
                    Vector3f(uv.x * properties.size.x, properties.heightData[currentVertex], uv.y * properties.size.y),
                    uv,
                    Vector3f(0),
                    Color.white
                );

                ++currentVertex;
            }

        size_t currentIndex;
        for (size_t gz; gz < properties.vertexCount.x - 1; ++gz)
            for (size_t gx; gx < properties.vertexCount.y - 1; ++gx)
            {
                immutable uint topLeft = cast(uint) ((gz * properties.vertexCount.y) + gx);
                immutable uint topRight = topLeft + 1;
                immutable uint bottomLeft = cast(uint) (((gz+1) * properties.vertexCount.y) + gx);
                immutable uint bottomRight = bottomLeft + 1;

                indices[currentIndex++] = topLeft;
                indices[currentIndex++] = bottomLeft;
                indices[currentIndex++] = topRight;
                indices[currentIndex++] = topRight;
                indices[currentIndex++] = bottomLeft;
                indices[currentIndex++] = bottomRight;
            }
    }

    static float[] getHeightData(Image heightMap, float heightScale)
        in (heightMap)
    {
        float[] heightData = new float[heightMap.size.x * heightMap.size.y];

        size_t currentHeightIndex;
        for (uint y; y < heightMap.size.y; ++y)
            for (uint x; x < heightMap.size.x; ++x)
            {
                immutable Color pixel = heightMap.getPixel(Vector2ui(x, y));
                heightData[currentHeightIndex++] = (pixel.r - pixel.b) * heightScale;
            }

        return heightData;
    }

public:
    this(in TerrainProperties properties, Material material = null)
    {
        Mesh.Vertex[] vertices;
        uint[] indices;

        generateData(properties, vertices, indices);

        if (!material)
        {
            material = new Material(AssetManager.load!Shader("core://shaders/3d/terrain.shd"),
                    BufferLayout([
                        BufferElement("textureTiling", BufferElement.Type.vec2)
                    ])
                );

            material.setParameter("textureTiling", Vector2f(properties.textureTiling.x, properties.textureTiling.y));
            
            foreach (size_t gx, const Texture2D texture; properties.textures)
                material.setTexture(gx, texture);

            material.setTexture(4, properties.blendMap);
        }

        mMesh = new Mesh(vertices, indices, material);
        mProperties = cast(TerrainProperties) properties;
    }

    this(in TerrainProperties properties, Image heightMap, float heightScale, Material material = null)
    {
        TerrainProperties updatedProps = cast(TerrainProperties) properties;

        updatedProps.heightData = getHeightData(heightMap, heightScale);
        updatedProps.vertexCount = heightMap.size;

        this(updatedProps, material);

        mProperties = updatedProps;
    }

    version(none)
    void update(Image heightMap, float heightScale)
    {
        TerrainProperties updatedProps = mProperties;
        
        updatedProps.heightData = getHeightData(heightMap, heightScale);
        updatedProps.vertexCount = heightMap.size;

        enforce(mProperties.heightData.length == updatedProps.heightData.length, 
            "Inconsistent height data lengths. Can only update with same length.");
        
        Vertex[] vertices;
        uint[] indices;
        generateData(updatedProps, vertices, indices);

        mBufferGroup.bind();
        mBufferGroup.dataBuffer.setData(vertices);
    }

    float getHeight(Vector2f coords) const nothrow
    {
        if (coords.x < 0 || coords.y < 0 || coords.x > mProperties.size.x || coords.y > mProperties.size.y)
            return 0;

        immutable Vector2f gridSize = Vector2f(mProperties.size.x / (mProperties.vertexCount.x - 1),
            mProperties.size.y / (mProperties.vertexCount.y - 1));

        immutable Vector2ui grid = Vector2ui(cast(uint) (coords.x / gridSize.x), cast(uint) (coords.y / gridSize.y));

        immutable Vector2f unitGridCoords = Vector2f(fmod(coords.x, gridSize.x) / gridSize.x,
            fmod(coords.y, gridSize.y) / gridSize.y);

        if (unitGridCoords.x <= 1 - unitGridCoords.y)
            return calculateBaryCentricHeight(
                Vector3f(0, mProperties.heightData[grid.y * mProperties.vertexCount.x + grid.x], 0),
                Vector3f(1, mProperties.heightData[grid.y * mProperties.vertexCount.x + grid.x + 1], 0),
                Vector3f(0, mProperties.heightData[(grid.y + 1) * mProperties.vertexCount.x + grid.x], 1),
                unitGridCoords
            );
        else
            return calculateBaryCentricHeight(
                Vector3f(1, mProperties.heightData[grid.y * mProperties.vertexCount.x + grid.x + 1], 0),
                Vector3f(1, mProperties.heightData[(grid.y + 1) * mProperties.vertexCount.x + grid.x + 1], 1),
                Vector3f(0, mProperties.heightData[(grid.y + 1) * mProperties.vertexCount.x + grid.x], 1),
                unitGridCoords
            );
    }

    const(TerrainProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    inout(BufferGroup) bufferGroup() pure inout nothrow
    {
        return mMesh.bufferGroup;
    }

    inout(Material) material() pure inout nothrow
    {
        return mMesh.material;
    }
}