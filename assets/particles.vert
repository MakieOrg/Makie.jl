precision highp float;

vec3 qmul(vec4 q, vec3 v){
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

void rotate(vec4 q, inout vec3 V, inout vec3 N){
    V = qmul(q, V);
    N = normalize(qmul(q, N));
}

// shader outputs to fragment shader
varying vec3 o_normal;
varying vec3 o_lightdir;
varying vec3 o_vertex;
varying vec4 o_color;

void render(vec4 position_world, vec3 normal, vec3 light[4])
{
    // normal in world space
    // TODO move transpose inverse calculation to cpu
    o_normal = normal;
    // direction to light
    o_lightdir = normalize(light[3] - position_world.xyz);
    // direction to camera
    o_vertex = -position_world.xyz;
    // screen space coordinates of the vertex
    gl_Position = get_projectionview() * position_world;
}

void main(){
    // get_* gets the global inputs (uniform, sampler, vertex array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = get_point();
    vec3 scale = get_markersize();
    vec3 offset = get_position();
    vec3 N = get_normals();
    o_color = get_color();
    vec2 uv = get_texturecoordinate();
    o_uv = vec2(1.0 - x.y, x.x);

    // scale the objects vertices by markersize
    vec3 V = scale * vertex_position;
    // apply the per instance rotation
    rotate(get_rotations(), V, N);
    render(get_model() * vec4(offset + V, 1), N, get_light());
}
