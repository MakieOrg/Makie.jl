{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{position_x_type}} position_x;
{{position_y_type}} position_y;
{{vertices_type}} vertices;
in vec2 texturecoordinates;

uniform mat4 projection, view, model;
uniform uint objectid;

out vec2       o_uv;
flat out uvec2 o_objectid;
out vec4 o_view_pos;
out vec3 o_normal;


vec4 _position(vec3 p){return vec4(p,1);}
vec4 _position(vec2 p){return vec4(p,0,1);}

ivec2 ind2sub(ivec2 dim, int linearindex){
    return ivec2(linearindex % dim.x, linearindex / dim.x);
}

// Called for heatmap(xs, ys, values)
// Generates a tile per instance positioned based on position_x and position_y
// Should use a Rect(0,0,1,1) as primitive
void render_tile(sampler1D position_x, sampler1D position_y){
	int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = ivec2(textureSize(position_x, 0), textureSize(position_y, 0));
	int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);

	o_uv = vec2(index01.x, 1.0 - index01.y);
	o_objectid = uvec2(objectid, index1D+1);

	float x = texelFetch(position_x, index2D.x, 0).x;
	float y = texelFetch(position_y, index2D.y, 0).x;

	gl_Position = projection * view * model * vec4(x, y, 0, 1);
}


// Called for image(img) or heatmap(values)
// Generates just one tile
// primitive should be Rect(min_x, min_y, width, height)
void render_tile(Nothing position_x, Nothing position_y){
	o_uv = texturecoordinates;
	o_objectid = uvec2(objectid, gl_VertexID+1);
	gl_Position = projection * view * model * _position(vertices);
}


void main(){
	o_view_pos = vec4(0);
	o_normal = vec3(0);
	render_tile(position_x, position_y);
}
