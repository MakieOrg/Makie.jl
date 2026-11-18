{{GLSL_VERSION}}

#define MAX_SCENE_CLIPS 4
#define PI 3.141592653589793

// Analytic clip shapes of the enclosing scenes. Each maps gl_FragCoord into the
// clip's local pixel space via `scene_clip_frames`.
// shapes: rect -> (center, half widths), annular sector -> (center, rmin, rmax)
// params: (sector center angle, sector half angle, kind (0 rect, 1 sector), device px per local px)
uniform int scene_clip_count;
uniform mat3 scene_clip_frames[MAX_SCENE_CLIPS];
uniform vec4 scene_clip_shapes[MAX_SCENE_CLIPS];
uniform vec4 scene_clip_params[MAX_SCENE_CLIPS];

float rect_sdf(vec2 p, vec4 shape) {
    vec2 d = abs(p - shape.xy) - shape.zw;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float annular_sector_sdf(vec2 p, vec4 shape, vec4 params) {
    vec2 q = p - shape.xy;
    float r = length(q);
    float d = max(shape.z - r, r - shape.w);
    float half_angle = params.y;
    if (half_angle < PI) {
        float a = params.x - 0.5 * PI;
        float ca = cos(a), sa = sin(a);
        q = vec2(ca * q.x + sa * q.y, -sa * q.x + ca * q.y);
        q.x = abs(q.x);
        vec2 c = vec2(sin(half_angle), cos(half_angle));
        float m = length(q - c * clamp(dot(q, c), 0.0, shape.w));
        d = max(d, m * sign(c.y * q.x - c.x * q.y));
    }
    return d;
}

float scene_clip_coverage() {
    float coverage = 1.0;
    for (int i = 0; i < scene_clip_count; i++) {
        vec2 p = (scene_clip_frames[i] * vec3(gl_FragCoord.xy, 1.0)).xy;
        vec4 params = scene_clip_params[i];
        vec4 shape = scene_clip_shapes[i];
        float d = params.z < 0.5 ? rect_sdf(p, shape) : annular_sector_sdf(p, shape, params);
        coverage *= clamp(0.5 - d * params.w, 0.0, 1.0);
    }
    return coverage;
}
