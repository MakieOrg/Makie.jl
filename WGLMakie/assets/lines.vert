#version 300 es

in float position;
in vec2 linepoint_prev;
in vec2 linepoint_start;
in vec2 linepoint_end;
in vec2 linepoint_next;
in float linewidth_prev;
in float linewidth_start;
in float linewidth_end;
in float linewidth_next;

uniform vec4 is_valid;
uniform vec4 color_end;
uniform vec4 color_start;
uniform mat4 model;
uniform mat4 projectionview;
uniform vec2 resolution;

out vec2 f_uv;
out vec4 f_color;
out float f_thickness;

vec3 screen_space(vec3 point) {
    vec4 vertex = projectionview * model * vec4(point, 1);
    return vec3(vertex.xy * resolution, vertex.z) / vertex.w;
}

vec3 screen_space(vec2 point) {
    return screen_space(vec3(point, 0));
}


void emit_vertex(vec3 position, vec2 uv, bool is_start) {

    f_uv = uv;

    f_color = is_start ? color_start : color_end;

    gl_Position = vec4((position.xy / resolution), position.z, 1.0);
            // linewidth scaling may shrink the effective linewidth
    f_thickness = is_start ? linewidth_start : linewidth_end;
}

void main() {
    vec3 p1 = screen_space(linepoint_start);
    vec3 p2 = screen_space(linepoint_end);
    vec2 dir = p1.xy - p2.xy;
    dir = normalize(dir);
    vec2 line_normal = vec2(dir.y, -dir.x);
    vec2 line_offset = line_normal * (linewidth_start / 2.0);

            // triangle 1
    vec3 v0 = vec3(p1.xy - line_offset, p1.z);
    if (position == 0.0) {
        emit_vertex(v0, vec2(0.0, 0.0), true);
        return;
    }
    vec3 v2 = vec3(p2.xy - line_offset, p2.z);
    if (position == 1.0) {
        emit_vertex(v2, vec2(0.0, 0.0), false);
        return;
    }
    vec3 v1 = vec3(p1.xy + line_offset, p1.z);
    if (position == 2.0) {
        emit_vertex(v1, vec2(0.0, 0.0), true);
        return;
    }

            // triangle 2
    if (position == 3.0) {
        emit_vertex(v2, vec2(0.0, 0.0), false);
        return;
    }
    vec3 v3 = vec3(p2.xy + line_offset, p2.z);
    if (position == 4.0) {
        emit_vertex(v3, vec2(0.0, 0.0), false);
        return;
    }
    if (position == 5.0) {
        emit_vertex(v1, vec2(0.0, 0.0), true);
        return;
    }
}
