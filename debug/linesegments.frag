    precision mediump int;
    precision mediump float;


// Uniforms: 
uniform vec2 resolution;
vec2 get_resolution(){return resolution;}
uniform mat4 model;
mat4 get_model(){return model;}


varying vec4 frag_color;

void main() {
    gl_FragColor = frag_color;
}
