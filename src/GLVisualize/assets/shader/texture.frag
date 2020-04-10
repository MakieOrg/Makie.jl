{{GLSL_VERSION}}

in vec2 o_uv;
flat in uvec2 o_objectid;
out vec4 fragment_color;
out uvec2 fragment_groupid;

{{image_type}} image;

vec4 getindex(sampler2D image, vec2 uv){
    return texture(image, uv);
}
vec4 getindex(sampler1D image, vec2 uv){
    return texture(image, uv.x);
}

void write2framebuffer(vec4 color, uvec2 id);

void main(){
    write2framebuffer(
        getindex(image, vec2(o_uv.x, 1-o_uv.y)),
        o_objectid
    );
}
