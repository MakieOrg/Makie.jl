#version 300 es
precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

// Instance inputs: 
in vec3 position;
vec3 get_position(){return position;}
in vec3 texturecoordinates;
vec3 get_texturecoordinates(){return texturecoordinates;}

// Uniforms: 
uniform sampler3D volumedata;
uniform mat4 modelinv;
mat4 get_modelinv(){return modelinv;}
uniform sampler2D colormap;
uniform vec2 colorrange;
vec2 get_colorrange(){return colorrange;}
uniform float isovalue;
float get_isovalue(){return isovalue;}
uniform float isorange;
float get_isorange(){return isorange;}
uniform vec3 light_position;
vec3 get_light_position(){return light_position;}



out vec3 frag_vert;
out vec3 frag_uv;

uniform mat4 projectionMatrix, viewMatrix, modelMatrix;

void main()
{
    vec4 world_vert = modelMatrix * vec4(position, 1);
    frag_vert = world_vert.xyz;
    frag_uv = texturecoordinates;
    gl_Position =  projectionMatrix * viewMatrix * world_vert;
}

