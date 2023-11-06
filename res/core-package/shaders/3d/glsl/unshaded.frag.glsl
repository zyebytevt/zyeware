#version 420 core
			
layout(location = 0) out vec4 oColor;

in vec2 vUV;
in vec4 vColor;

void main()
{
    oColor = vColor;
}