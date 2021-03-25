{{GLSL_VERSION}}

float rand(vec2 co){
    // implementation found at: lumina.sourceforge.net/Tutorials/Noise.html
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

// Put your user defined function here...
{{function}}

uniform float jitter = 1.0;
uniform float thickness = 2000;
uniform int samples = 8;

in vec2 aa_scale;


float getalpha(vec2 pos) {
    vec2 step = thickness*vec2(aa_scale.x,aa_scale.y)/samples;
    float samples = float(samples);
    int count = 0;
    int mysamples = 0;
    for (float i = 0.0; i < samples; i++) {
        for (float  j = 0.0;j < samples; j++) {
            if (i*i+j*j>samples*samples) continue;
            mysamples++;
            float ii = i + jitter*rand(vec2(pos.x + i*step.x,pos.y + j*step.y));
            float jj = j + jitter*rand(vec2(pos.y + i*step.x,pos.x + j*step.y));
            float f = function(pos.x+ ii*step.x)-(pos.y+ jj*step.y);
            count += (f>0.) ? 1 : -1;
        }
    }
    if (abs(count)!=mysamples) return 1-abs(float(count))/float(mysamples);
    return 0.0;
}

in vec2 o_uv;
uniform vec4 color;

void write2framebuffer(vec4 color, uvec2 id);

void main()
{
    write2framebuffer(
        vec4(color.rgb, color.a*getalpha(vec2(o_uv.x*5, o_uv.y))),
        uvec2(0)
    );
}


/*
//note: shadertoy-pluggable, http://www.iquilezles.org/apps/shadertoy/

*/
