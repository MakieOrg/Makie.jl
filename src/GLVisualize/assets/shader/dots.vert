{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{vertex_type}}     vertex;
{{color_type}}      color;
{{color_norm_type}} color_norm;
{{color_map_type}}  color_map;
uniform uint objectid;

flat out vec4 o_color;
flat out uvec2 o_objectid;


float _normalize(float val, float from, float to){return (val-from) / (to - from);}

vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm){
    return texture(color_ramp, _normalize(intensity, norm.x, norm.y));
}
void colorize(Nothing intensity, vec3 color, Nothing color_norm){
    o_color = vec4(color, 1);
}
void colorize(Nothing intensity, vec4 color, Nothing color_norm){
    o_color = color;
}
void colorize(sampler1D color, float intensity, vec2 color_norm){
    o_color = color_lookup(intensity, color, color_norm);
}
vec4 _position(vec3 p){return vec4(p,1);}
vec4 _position(vec2 p){return vec4(p,0,1);}

uniform mat4 projectionview, model;

void main(){
	colorize(color_map, color, color_norm);
    o_objectid  = uvec2(objectid, gl_VertexID+1);
	gl_Position = projectionview * model * _position(vertex);
}
