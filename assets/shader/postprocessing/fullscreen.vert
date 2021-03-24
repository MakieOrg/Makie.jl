{{GLSL_VERSION}}

out vec2 frag_uv;

void main() {
    vec2 uv = vec2(0,0);
    if((gl_VertexID & 1) != 0)
        uv.x = 1;
    if((gl_VertexID & 2) != 0)
        uv.y = 1;

    frag_uv = uv * 2;
    gl_Position.xy = (uv * 4) - 1;
    gl_Position.zw = vec2(0,1);
}
