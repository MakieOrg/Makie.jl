uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;

varying vec4 frag_color;
varying vec2 frag_uv;
varying float frag_uvscale;
varying float frag_distancefield_scale;


float distancefield_scale(){
    // Glyph distance field units are in pixels; convert to dimensionless
    // x-coordinate of texture instead for consistency with programmatic uv
    // distance fields in fragment shader. See also comments below.
    vec4 uv_rect = get_uv_offset_width();
    float tsize = 4096.0;
    float pixsize_x = (uv_rect.z - uv_rect.x) * tsize;
    return -1.0/pixsize_x;
}


void main(){
    // get_* gets the global inputs (uniform, sampler, vertex array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = vec3(get_markersize() * get_position(), 0);
    //rotate(get_rotations(), vertex_position, N);
    vertex_position = vec3(get_offset(), 0) + vertex_position;
    vec4 position_world;
    if(get_transform_marker()){
        position_world = get_model() * vec4(vertex_position, 1);
    }else{
        position_world = vec4(vertex_position, 1);
    }
    frag_color = get_color();
    vec2 mpixel = (projectionMatrix * vec4(get_markersize(), 0, 0)).xy;
    mpixel = ((mpixel + 1.0) / 2.0) * get_resolution();
    frag_uvscale = length(mpixel);
    vec2 uv = get_texturecoordinates();
    frag_uv = uv;
    frag_distancefield_scale = distancefield_scale();
    // screen space coordinates of the vertex
    gl_Position = projectionMatrix * viewMatrix * position_world;
}
