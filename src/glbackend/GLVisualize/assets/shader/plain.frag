{{GLSL_VERSION}}

flat in uvec2 o_objectid;

{{color_type}} color;

vec4 get_color(vec4 color){
    return color;
}
vec4 get_color(vec3 color){
    return vec4(color, 1);
}


void write2framebuffer(vec4 color, uvec2 id);

void main(){
    write2framebuffer(
        get_color(color),
        o_objectid
    );
}
