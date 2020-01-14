precision mediump float;

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

out vec3 frag_normal;
out vec3 frag_position;

out vec4 frag_color;
out vec3 frag_lightdir;


vec3 qmul(vec4 q, vec3 v){
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

void rotate(vec4 q, inout vec3 V, inout vec3 N){
    V = qmul(q, V);
    N = normalize(qmul(q, N));
}

vec4 to_vec4(vec3 v3){return vec4(v3, 1.0);}
vec4 to_vec4(vec4 v4){return v4;}

void main(){
    // get_* gets the global inputs (uniform, sampler, vertex array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = get_markersize() * get_position();
    vec3 lightpos = vec3(20,20,20);
    vec3 N = get_normals();
    rotate(get_rotations(), vertex_position, N);
    vertex_position = get_offset() + vertex_position;
    vec4 position_world = modelMatrix * vec4(vertex_position, 1);
    frag_normal = N;
    frag_lightdir = normalize(lightpos - position_world.xyz);
    frag_color = to_vec4(get_color());
    // direction to camera
    frag_position = -position_world.xyz;
    // screen space coordinates of the vertex
    gl_Position = projectionMatrix * viewMatrix * position_world;
}
