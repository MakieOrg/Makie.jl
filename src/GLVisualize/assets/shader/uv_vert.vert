{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{position_x_type}} position_x;
{{position_y_type}} position_y;
{{vertices_type}} vertices;
in vec2 texturecoordinates;

uniform mat4 projection, view, model;
uniform uint objectid;

out vec2       o_uv;
flat out uvec2 o_objectid;

ivec2 ind2sub(ivec2 dim, int linearindex){
    return ivec2(linearindex % dim.x, linearindex / dim.x);
}

out vec4 o_view_pos;
out vec3 o_normal;

void main()
{
	int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = ivec2(textureSize(position_x, 0), textureSize(position_y, 0));
	int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);

	o_view_pos = vec4(0);
	o_normal = vec3(0);

	float x = texelFetch(position_x, index2D.x, 0).x;
	float y = texelFetch(position_y, dims.y - index2D.y, 0).x;

	o_uv = index01;
	o_objectid = uvec2(objectid, gl_VertexID+1);
	gl_Position = projection * view * model * vec4(x, y, 0, 1);
}
