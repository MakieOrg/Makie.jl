{{GLSL_VERSION}}

in vec2 vertices;
in vec2 texturecoordinates;

out vec2 o_uv;
out vec2 aa_scale;

uniform vec2 resolution;
uniform float AntiAliasScale = 0.75;
uniform float Zoom = 1.;

uniform mat4 projection, projectionview, model;
void main(){
    o_uv = texturecoordinates;
    aa_scale = vec2(projection[0][0],projection[1][1])*(1.0/resolution)*AntiAliasScale/Zoom;
    gl_Position = projectionview * model * vec4(vertices, 0, 1);
}
