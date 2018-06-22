{{GLSL_VERSION}}

flat in vec4  o_color;
flat in uvec2 o_objectid;

void write2framebuffer(vec4 color, uvec2 id);

void main(){
    write2framebuffer(o_color, o_objectid);
}
