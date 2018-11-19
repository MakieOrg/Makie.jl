{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

in vec2 vertices;

uniform vec3 light[4];
{{color_type}} color;
uniform vec2 color_norm;

uniform sampler2D x;
uniform sampler2D y;
uniform sampler2D z;


uniform vec3 scale;

uniform mat4 view, model, projection;

void render(vec3 vertices, vec3 normal, vec4 color, mat4 viewmodel, mat4 projection, vec3 light[4]);
ivec2 ind2sub(ivec2 dim, int linearindex);
vec2 linear_index(ivec2 dims, int index, vec2 offset);
vec4 linear_texture(sampler2D tex, int index, vec2 offset);
vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm);


bool isinbounds(vec2 uv)
{
	return (uv.x <= 1.0 && uv.y <= 1.0 && uv.x >= 0.0 && uv.y >= 0.0);
}
vec3 getnormal(sampler2D zvalues, vec2 uv)
{   
    float weps = 1.0/textureSize(zvalues,0).x;
    float heps = 1.0/textureSize(zvalues,0).y;

    vec3 result = vec3(0);
    
    vec3 s0 = vec3(uv, texture(zvalues, uv).x);

    vec2 off1 = uv + vec2(-weps,0);
    vec2 off2 = uv + vec2(0, heps);
    vec2 off3 = uv + vec2(weps, 0);
    vec2 off4 = uv + vec2(0,-heps);
    vec3 s1, s2, s3, s4;

	s1 = vec3((off1), texture(zvalues, off1).x);
	s2 = vec3((off2), texture(zvalues, off2).x);
	s3 = vec3((off3), texture(zvalues, off3).x);
    s4 = vec3((off4), texture(zvalues, off4).x);

    if(isinbounds(off1) && isinbounds(off2))
    {
		result += cross(s2-s0, s1-s0);
	}
	if(isinbounds(off2) && isinbounds(off3))
    {
	    result += cross(s3-s0, s2-s0);
    }
	if(isinbounds(off3) && isinbounds(off4))
    {
		result += cross(s4-s0, s3-s0);
	}
	if(isinbounds(off4) && isinbounds(off1))
    {
		result += cross(s1-s0, s4-s0);
	}

    return normalize(result); // normal should be zero, but needs to be here, because the dead-code elimanation of GLSL is overly enthusiastic
}

uniform uint objectid;
flat out uvec2 o_id;

void main()
{
	ivec2 dims 		= textureSize(z, 0);
	vec3 pos;
	int index 		= gl_InstanceID;

	pos.x 			= linear_texture(x, index, vertices).x;
	pos.y 			= linear_texture(y, index, vertices).x;
	pos.z 			= linear_texture(z, index, vertices).x;

	vec4 instance_color = color_lookup(pos.z, color, color_norm);
	vec3 normalvec 		= getnormal(z, linear_index(dims, index, vertices));
	render(pos, normalvec, instance_color, view * model, projection, light);
	o_id                = uvec2(objectid, index+1);
}


