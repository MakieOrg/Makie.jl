out vec2 frag_uv;
out vec3 o_normal;
out vec3 o_camdir;
out vec3 o_lightdir;

out vec4 frag_color;

uniform mat4 projection;
uniform mat4 view;

vec3 tovec3(vec2 v){return vec3(v, 0.0);}
vec3 tovec3(vec3 v){return v;}

vec4 tovec4(vec3 v){return vec4(v, 1.0);}
vec4 tovec4(vec4 v){return v;}



void main(){
    // get_* gets the global inputs (uniform, sampler, position array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = tovec3(get_position());
    if (isnan(vertex_position.z)) {
        vertex_position.z = 0.0;
    }
    vec4 position_world = model * vec4(vertex_position, 1);

    // normal in world space
    o_normal = get_normalmatrix() * get_normals();
    // position in view space (as seen from camera)
    vec4 view_pos = view * position_world;
    // position in clip space (w/ depth)
    gl_Position = projection * view_pos;
    gl_Position.z += gl_Position.w * get_depth_shift();
    // direction to light
    o_lightdir = normalize(view*vec4(get_lightposition(), 1.0) - view_pos).xyz;
    // direction to camera
    // This is equivalent to
    // normalize(view*vec4(eyeposition, 1.0) - view_pos).xyz
    // (by definition `view * eyeposition = 0`)
    o_camdir = normalize(-view_pos).xyz;

    frag_uv = get_uv();
    frag_uv = vec2(1.0 - frag_uv.y, frag_uv.x);
    frag_color = tovec4(get_color());
}
