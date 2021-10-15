{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{vertices_type}} vertices;
in vec2 texturecoordinates;

uniform mat4 projection, view, model;
uniform uint objectid;
uniform float depth_shift;

out vec2 o_uv;
flat out uvec2 o_objectid;

out vec4 o_view_pos;
out vec3 o_normal;

vec4 _position(vec3 p){return vec4(p,1);}
vec4 _position(vec2 p){return vec4(p,0,1);}

void main(){
    //Outputs for ssao, which we don't use for 2d shaders like heatmap/image
    o_view_pos = vec4(0);
    o_normal = vec3(0);
    o_uv = texturecoordinates;
    o_objectid = uvec2(objectid, gl_VertexID+1);
    gl_Position = projection * view * model * _position(vertices);
    gl_Position.z += gl_Position.w * depth_shift;
}
