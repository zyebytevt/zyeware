#version 330 core

layout(location = 0) out vec4 color;

in vec3 v_Normal;
in vec3 v_ToCameraVector;

uniform vec3 u_Albedo;
uniform float u_ShineDamper;
uniform float u_Reflectivity;

void main()
{
    vec3 unitLightVector = normalize(vec3(1, 0, 1));
    vec3 unitCameraVector = normalize(v_ToCameraVector);

    float brightness = max(dot(v_Normal, unitLightVector), 0.05);
    float specularFactor = max(dot(reflect(-unitLightVector, v_Normal), unitCameraVector), 0.0);
    
    vec3 diffuse = brightness * vec3(1);
    vec3 specular = pow(specularFactor, u_ShineDamper) * u_Reflectivity * vec3(1);

    color = vec4(diffuse, 1) * vec4(u_Albedo, 1) + vec4(specular, 0);
}