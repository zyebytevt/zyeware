layout(std140, shared, row_major) uniform Matrices
{
    mat4 mvp;
    mat4 projection;
    mat4 view;
    mat4 model;
} iMatrices;

layout(std140, shared) uniform Environment
{
    vec4 cameraPosition;
    vec4 ambientColor;
    vec4 fogColor;
} iEnvironment;

layout(std140, shared) uniform Lights
{
    vec4 position[10];
    vec4 color[10];
    vec4 attenuation[10];
    int count;
} iLights;