    precision mediump int;
    precision mediump float;


// Uniforms: 
uniform float linewidth_start;
float get_linewidth_start(){return linewidth_start;}
uniform float linewidth_end;
float get_linewidth_end(){return linewidth_end;}
uniform vec2 resolution;
vec2 get_resolution(){return resolution;}
uniform float linewidth;
float get_linewidth(){return linewidth;}
uniform mat4 model;
mat4 get_model(){return model;}


varying vec4 frag_color;

void main() {
    gl_FragColor = frag_color;
}
