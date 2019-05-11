precision mediump float;

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;

varying vec3 frag_normal;
varying vec3 frag_position;
varying vec3 frag_lightdir;

void main(){
    // get_* gets the global inputs (uniform, sampler, vertex array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = get_offset() + (get_markersize() * get_position());
    vec4 position_world = get_model() * vec4(vertex_position, 1);
    vec3 lightpos = vec3(20,20,20);

    frag_normal = get_normals();
    frag_lightdir = normalize(lightpos - position_world.xyz);
    // direction to camera
    frag_position = -position_world.xyz;
    // screen space coordinates of the vertex
    gl_Position = projectionMatrix * viewMatrix * position_world;
}
