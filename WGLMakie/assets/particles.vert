precision mediump float;

uniform mat4 projection;
uniform mat4 view;
uniform vec3 eyeposition;

out vec3 frag_normal;
out vec3 frag_position;
out vec4 frag_color;
out vec3 o_camdir;

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

void main(){
    // get_* gets the global inputs (uniform, sampler, position array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = get_markersize() * to_vec3(get_position());
    vec3 N = get_normals() / get_markersize(); // see issue #3702
    rotate(get_rotations(), vertex_position, N);
    vertex_position = to_vec3(get_offset()) + vertex_position;
    vec4 position_world = model * vec4(vertex_position, 1);
    frag_normal = N;
    frag_color = to_vec4(get_color());
    // direction to camera
    o_camdir = position_world.xyz / position_world.w - eyeposition;
    // screen space coordinates of the position
    gl_Position = projection * view * position_world;
    gl_Position.z += gl_Position.w * get_depth_shift();
    frag_instance_id = uint(gl_InstanceID);
}
