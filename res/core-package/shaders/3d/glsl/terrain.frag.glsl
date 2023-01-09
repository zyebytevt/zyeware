#version 410 core

// ===== OUTPUTS =====
layout(location = 0) out vec4 oColor;

// ===== INPUTS =====
#include "core://shaders/include/glsl/uniforms3d.glsl"

layout(std140) uniform ModelUniforms
{
    vec2 textureTiling;
} iModelUniforms;

uniform sampler2D iTextures[4];
uniform sampler2D iBlendMap;

// ===== VARIANTS =====
in vec2 vUV;
in vec4 vColor;
in vec4 vWorldPosition;
in vec3 vToCameraVector;
in vec3 vNormal;

// ===== FUNCTIONS =====
#include "core://shaders/include/glsl/utils.glsl"

void main()
{
    vec2 actualUV = vUV * iModelUniforms.textureTiling;

    vec4 blendAmount = texture(iBlendMap, vUV);
    float backTextureAmount = 1 - (blendAmount.r + blendAmount.g + blendAmount.b);

    oColor = texture(iTextures[0], actualUV) * backTextureAmount
        + texture(iTextures[1], actualUV) * blendAmount.r
        + texture(iTextures[2], actualUV) * blendAmount.g
        + texture(iTextures[3], actualUV) * blendAmount.b
        * vColor;

    oColor.rgb = applySimpleFog(oColor.rgb, iEnvironment.fogColor.rgb, length(vToCameraVector), iEnvironment.fogColor.a);

    vec3 totalDiffuse = iEnvironment.ambientColor.rgb;

    for (int i = 0; i < iLights.count; ++i)
    {
        vec3 att = iLights.attenuation[i].xyz;

        vec3 toLightVector = iLights.position[i].xyz - vWorldPosition.xyz;
        float distance = length(toLightVector);

        float attenuationFactor = att.x + (att.y * distance) + (att.z * distance * distance);

        vec3 unitLightVector = normalize(toLightVector);
        vec3 unitCameraVector = normalize(vToCameraVector);

        float brightness = max(dot(vNormal, unitLightVector), 0.05);
        
        totalDiffuse += brightness * iLights.color[i].rgb / attenuationFactor;
    }

    oColor.rgb *= totalDiffuse;
}