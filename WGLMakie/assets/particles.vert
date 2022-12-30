precision mediump float;

uniform mat4 projection;
uniform mat4 view;

out vec3 o_normal;
out vec3 o_camdir;

out vec4 frag_color;
out vec3 o_lightdir;


vec3 qmul(vec4 q, vec3 v){
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

void rotate(vec4 q, inout vec3 V, inout vec3 N){
    V = qmul(q, V);
    N = normalize(qmul(q, N));
}

vec4 to_vec4(vec3 v3){return vec4(v3, 1.0);}
vec4 to_vec4(vec4 v4){return v4;}

vec3 to_vec3(vec2 v3){return vec3(v3, 0.0);}
vec3 to_vec3(vec3 v4){return v4;}

flat out uint frag_instance_id;

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition)
{
    // normal in world space
    o_normal = get_normalmatrix() * normal;
    // position in view space (as seen from camera)
    vec4 view_pos = view * position_world;
    // position in clip space (w/ depth)
    gl_Position = projection * view_pos;
    gl_Position.z += gl_Position.w * get_depth_shift();
    // direction to light
    o_lightdir = normalize(view*vec4(lightposition, 1.0) - view_pos).xyz;
    // direction to camera
    // This is equivalent to
    // normalize(view*vec4(eyeposition, 1.0) - view_pos).xyz
    // (by definition `view * eyeposition = 0`)
    o_camdir = normalize(-view_pos).xyz;
}


void main(){
    // get_* gets the global inputs (uniform, sampler, position array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = get_markersize() * get_position();
    vec3 N = get_normals();
    rotate(get_rotations(), vertex_position, N);
    vertex_position = to_vec3(get_offset()) + vertex_position;
    vec4 position_world = model * vec4(vertex_position, 1);

    frag_color = to_vec4(get_color());
    frag_instance_id = uint(gl_InstanceID);
    render(position_world, N, view, projection, get_lightposition());
}
