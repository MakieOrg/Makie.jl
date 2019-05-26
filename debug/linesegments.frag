#version 300 es
precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

out vec4 fragment_color;

// Uniforms: 
uniform vec2 resolution;
vec2 get_resolution(){return resolution;}


in vec4 frag_color;

void main() {
    fragment_color = frag_color;
}
