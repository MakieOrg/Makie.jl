precision highp float;

vec3 qmul(vec4 q, vec3 v){
	return v + 2.0 * cross( q.xyz, cross(q.xyz, v) + q.w * v);
}

void rotate(vec4 q, int index, inout vec3 V, inout vec3 N){
    V = qmul(q, V);
    N = normalize(qmul(q, N));
}

vec3 scale3d(vec2 markersize){
    return vec3(markersize, 1);
}

vec3 scale3d(vec3 markersize){
    return markersize;
}

// constant color!
vec4 colorize(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm);
vec4 colorize(vec3 color, Nothing intensity, Nothing color_map, Nothing color_norm);

// no color, but intensities a color map and color norm. Color will be based on intensity!
vec4 colorize(Nothing color, sampler1D intensity, sampler1D color_map, vec2 color_norm);

vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm);

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
    gl_Position = projectionview * position_world;
}

vec2 get_uv(vec2 x){return vec2(1.0 - x.y, x.x);}

void main(){

    vec3 s = scale3d(markersize);
    vec3 V = points * s;
    vec3 N = normals;
    vec3 pos = position;

    o_color = colorize(color, intensity, color_map, color_norm);
    o_uv = get_uv(uv);
    rotate(rotation, index, V, N);
    render(model * vec4(pos + V, 1), N, view, projection, light);
}
