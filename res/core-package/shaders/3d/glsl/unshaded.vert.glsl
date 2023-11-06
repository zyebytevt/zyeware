#version 420 core

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aUV;
layout(location = 3) in vec4 aColor;

out vec2 vUV;
out vec4 vColor;

layout(std140, shared, row_major) uniform Matrices
{
    mat4 viewProjection;
    mat4 model;
} iMatrices;


void main()
{
    vUV = aUV;
    vColor = aColor;
    gl_Position = iMatrices.viewProjection * iMatrices.model * vec4(aPosition, 1.0);
}