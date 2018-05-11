{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{vertices_type}} vertices;
in vec2 texturecoordinates;

uniform mat4 projection, view, model;
uniform uint objectid;

out vec2       o_uv;
flat out uvec2 o_objectid;

vec4 _position(vec3 p){return vec4(p,1);}
vec4 _position(vec2 p){return vec4(p,0,1);}

void main(){
	o_uv        = texturecoordinates;
	o_objectid  = uvec2(objectid, gl_VertexID+1);
	gl_Position = projection * view * model * _position(vertices);
}
