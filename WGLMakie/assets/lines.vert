# version 300 es

precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

// https://github.com/mrdoob/three.js/blob/dev/examples/jsm/lines/LineMaterial.js
// https://www.khronos.org/assets/uploads/developers/presentations/Crazy_Panda_How_to_draw_lines_in_WebGL.pdf
// https://github.com/gameofbombs/pixi-candles/tree/master/src
// https://github.com/wwwtyro/instanced-lines-demos/tree/master

in vec2 uv;
in vec3 position;
in vec2 instanceStart;
in vec2 instanceEnd;

out vec2 vUv;

uniform mat4 projection;
uniform mat4 model;
uniform mat4 view;

uniform float linewidth;
uniform vec2 resolution;

void trimSegment(const in vec4 start, inout vec4 end) {

    // trim end segment so it terminates between the camera plane and the near plane

    // conservative estimate of the near plane
    float a = projection[2][2]; // 3nd entry in 3th column
    float b = projection[3][2]; // 3nd entry in 4th column
    float nearEstimate = -0.5 * b / a;

    float alpha = (nearEstimate - start.z) / (end.z - start.z);

    end.xyz = mix(start.xyz, end.xyz, alpha);

}

void main() {

    float aspect = resolution.x / resolution.y;
    mat4 model_view = model * view;
    // camera space
    vec4 start = model_view * vec4(instanceStart, 0.0, 1.0);
    vec4 end = model_view * vec4(instanceEnd, 0.0, 1.0);
    vUv = uv;

    // special case for perspective projection, and segments that terminate either in, or behind, the camera plane
    // clearly the gpu firmware has a way of addressing this issue when projecting into ndc space
    // but we need to perform ndc-space calculations in the shader, so we must address this issue directly
    // perhaps there is a more elegant solution -- WestLangley

    bool perspective = false; //(projection[2][3] == -1.0); // 4th entry in the 3rd column

    if (perspective) {

        if (start.z < 0.0 && end.z >= 0.0) {

            trimSegment(start, end);

        } else if (end.z < 0.0 && start.z >= 0.0) {

            trimSegment(end, start);

        }

    }

    // clip space
    vec4 clipStart = projection * start;
    vec4 clipEnd = projection * end;

    // ndc space
    vec3 ndcStart = clipStart.xyz / clipStart.w;
    vec3 ndcEnd = clipEnd.xyz / clipEnd.w;

    // direction
    vec2 dir = ndcEnd.xy - ndcStart.xy;

    // account for clip-space aspect ratio
    dir.x *= aspect;
    dir = normalize(dir);

    vec2 offset = vec2(dir.y, -dir.x);
        // undo aspect ratio adjustment
    dir.x /= aspect;
    offset.x /= aspect;

        // sign flip
    if (position.x < 0.0)
        offset *= -1.0;

        // endcaps
    if (position.y < 0.0) {

        offset += -dir;

    } else if (position.y > 1.0) {

        offset += dir;

    }

        // adjust for linewidth
    offset *= linewidth;

        // adjust for clip-space to screen-space conversion // maybe resolution should be based on viewport ...
    offset /= resolution.y;

        // select end
    vec4 clip = (position.y < 0.5) ? clipStart : clipEnd;

        // back to clip space
        // back to clip space
    offset *= clip.w;

    clip.xy += offset;

    gl_Position = clip;
}
