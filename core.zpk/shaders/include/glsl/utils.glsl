vec3 applySimpleFog(in vec3 orig, in vec3 fogColor, in float distance, in float density)
{
    float fogAmount = 1.0 - exp( -distance * density );
    return mix(orig, fogColor, fogAmount);
}

/*vec3 applyFog(in vec3 rgb, in float distance, in vec3 rayDir, in vec3 sunDir)
{
    float fogAmount = 1.0 - exp( -distance * density );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( vec3(0.5,0.6,0.7), // bluish
                           vec3(1.0,0.9,0.7), // yellowish
                           pow(sunAmount,8.0) );
    return mix( rgb, fogColor, fogAmount );
}*/

/*
vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayOri,   // camera position
               in vec3  rayDir )  // camera to point vector
{
    float fogAmount = (100/density) * exp(-rayOri.y*density) * (1.0-exp( -distance*rayDir.y*density ))/rayDir.y;
    vec3  fogColor  = vec3(0.5,0.6,0.7);
    return mix( rgb, fogColor, fogAmount );
}*/