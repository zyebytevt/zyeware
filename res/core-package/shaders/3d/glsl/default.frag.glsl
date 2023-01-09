#version 410 core

// ===== OUTPUTS =====
layout(location = 0) out vec4 oColor;

// ===== INPUTS =====
#include "core://shaders/include/glsl/uniforms3d.glsl"

layout(std140) uniform ModelUniforms
{
    float shineDamper;
    float reflectivity;
} iModelUniforms;

uniform sampler2D iAlbedo;

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
    oColor = texture(iAlbedo, vUV);
    if (oColor.a <= 0)
        discard;
    
    oColor.rgb = applySimpleFog(oColor.rgb, iEnvironment.fogColor.rgb, length(vToCameraVector), iEnvironment.fogColor.a);

    vec3 totalDiffuse = iEnvironment.ambientColor.rgb;
    vec3 totalSpecular = vec3(0);

    for (int i = 0; i < iLights.count; ++i)
    {
        vec3 att = iLights.attenuation[i].xyz;

        vec3 toLightVector = iLights.position[i].xyz - vWorldPosition.xyz;
        float distance = length(toLightVector);

        float attenuationFactor = att.x + (att.y * distance) + (att.z * distance * distance);

        vec3 unitLightVector = normalize(toLightVector);
        vec3 unitCameraVector = normalize(vToCameraVector);

        float brightness = max(dot(vNormal, unitLightVector), 0.05);
        float specularFactor = max(dot(reflect(-unitLightVector, vNormal), unitCameraVector), 0.0);
        
        totalDiffuse += brightness * iLights.color[i].rgb / attenuationFactor;
        totalSpecular += (pow(specularFactor, iModelUniforms.shineDamper) * iModelUniforms.reflectivity
            * iLights.color[i].rgb) / attenuationFactor;
    }

    oColor.rgb = oColor.rgb * totalDiffuse + totalSpecular;
}