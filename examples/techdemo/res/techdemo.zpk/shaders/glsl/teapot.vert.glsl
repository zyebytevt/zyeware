#version 420 core

layout(location = 0) in vec3 a_Position;
layout(location = 1) in vec2 a_UV;
layout(location = 2) in vec3 a_Normal;
layout(location = 3) in vec4 a_Color;

uniform mat4 i_VPMatrix;
uniform mat4 i_ModelMatrix;
uniform mat4 i_ViewMatrix;

out vec3 v_Normal;
out vec3 v_ToCameraVector;

void main()
{
    vec4 worldPosition = i_ModelMatrix * vec4(a_Position, 1.0);

    v_ToCameraVector = (inverse(i_ViewMatrix) * vec4(0, 0, 0, 1)).xyz - worldPosition.xyz;
    v_Normal = (i_ModelMatrix * vec4(a_Normal, 0)).xyz;

    gl_Position = i_VPMatrix * worldPosition;
}