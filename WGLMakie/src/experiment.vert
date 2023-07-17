#version 300 es
precision highp float;
const float BEVEL = 4.0f;
const float MITER = 8.0f;
const float ROUND = 12.0f;
const float JOINT_CAP_BUTT = 16.0f;
const float JOINT_CAP_SQUARE = 18.0f;
const float JOINT_CAP_ROUND = 20.0f;

const float CAP_BUTT = 1.0f;
const float CAP_SQUARE = 2.0f;
const float CAP_ROUND = 3.0f;

// === geom ===
in vec2 linepoint_prev;
in vec2 linepoint_start;
in vec2 linepoint_end;
in vec2 linepoint_next;
in float vertexNum;

uniform mat4 projectionview;
uniform mat4 model;

// out vec4 vDistance;
// out vec4 vArc;
out float vType;
out vec4 f_color;

uniform float resolution;
uniform vec4 color_start; // end of previous segment, start of current segment
uniform vec4 color_end; // end of current segment, start of next segment

#define scaleMode 1.0;
#define miterLimit -0.4
#define AA_THICKNESS 1.0f;

vec2 doBisect(
    vec2 norm,
    float len,
    vec2 norm2,
    float len2,
    float dy,
    float inner
) {
    vec2 bisect = (norm + norm2) / 2.0f;
    bisect /= dot(norm, bisect);
    vec2 shift = dy * bisect;
    if (inner > 0.5f) {
        if (len < len2) {
            if (abs(dy * (bisect.x * norm.y - bisect.y * norm.x)) > len) {
                return dy * norm;
            }
        } else {
            if (abs(dy * (bisect.x * norm2.y - bisect.y * norm2.x)) > len2) {
                return dy * norm;
            }
        }
    }
    return dy * bisect;
}

void main(void) {
    f_color = color_start;
    vec2 pointA = (model * vec4(linepoint_start, 0.0, 1.0f)).xy;
    vec2 pointB = (model * vec4(linepoint_end, 0.0, 1.0f)).xy;

    vec2 xBasis = pointB - pointA;
    float len = length(xBasis);
    vec2 forward = xBasis / len;
    vec2 norm = vec2(forward.y, -forward.x);

    float type = 8.0;

    float lineWidth = styleLine.x;
    if (scaleMode > 2.5f) {
        lineWidth *= length(model * vec3(1.0f, 0.0f, 0.0f));
    } else if (scaleMode > 1.5f) {
        lineWidth *= length(model * vec3(0.0f, 1.0f, 0.0f));
    } else if (scaleMode > 0.5f) {
        vec2 avgDiag = (model * vec3(1.0f, 1.0f, 0.0f)).xy;
        lineWidth *= sqrt(dot(avgDiag, avgDiag) * 0.5f);
    }
    float capType = floor(type / 32.0f);
    type -= capType * 32.0f;
    vArc = vec4(0.0f);
    lineWidth *= 0.5f;
    float lineAlignment = 2.0f * styleLine.y - 1.0f;

    vec2 pos;

    if (capType == CAP_ROUND) {
        if (vertexNum < 3.5f) {
            gl_Position = vec4(0.0f, 0.0f, 0.0f, 1.0f);
            return;
        }
        type = JOINT_CAP_ROUND;
        capType = 0.0f;
    }

    if (type >= BEVEL) {
        float dy = lineWidth + AA_THICKNESS;
        float inner = 0.0f;
        if (vertexNum >= 1.5f) {
            dy = -dy;
            inner = 1.0f;
        }

        vec2 base, next, xBasis2, bisect;
        float flag = 0.0f;
        float sign2 = 1.0f;
        if (vertexNum < 0.5f || vertexNum > 2.5f && vertexNum < 3.5f) {
            next = (model * vec3(linepoint_prev, 1.0f)).xy;
            base = pointA;
            flag = type - floor(type / 2.0f) * 2.0f;
            sign2 = -1.0f;
        } else {
            next = (model * vec3(linepoint_next, 1.0f)).xy;
            base = pointB;
            if (type >= MITER && type < MITER + 3.5f) {
                flag = step(MITER + 1.5f, type);
                // check miter limit here?
            }
        }
        xBasis2 = next - base;
        float len2 = length(xBasis2);
        vec2 norm2 = vec2(xBasis2.y, -xBasis2.x) / len2;
        float D = norm.x * norm2.y - norm.y * norm2.x;
        if (D < 0.0f) {
            inner = 1.0f - inner;
        }

        norm2 *= sign2;

        if (abs(lineAlignment) > 0.01f) {
            float shift = lineWidth * lineAlignment;
            pointA += norm * shift;
            pointB += norm * shift;
            if (abs(D) < 0.01f) {
                base += norm * shift;
            } else {
                base += doBisect(norm, len, norm2, len2, shift, 0.0f);
            }
        }

        float collinear = step(0.0f, dot(norm, norm2));

        vType = 0.0f;
        float dy2 = -1000.0f;
        float dy3 = -1000.0f;

        if (abs(D) < 0.01f && collinear < 0.5f) {
            if (type >= ROUND && type < ROUND + 1.5f) {
                type = JOINT_CAP_ROUND;
            }
            //TODO: BUTT here too
        }

        if (vertexNum < 3.5f) {
            if (abs(D) < 0.01f) {
                pos = dy * norm;
            } else {
                if (flag < 0.5f && inner < 0.5f) {
                    pos = dy * norm;
                } else {
                    pos = doBisect(norm, len, norm2, len2, dy, inner);
                }
            }
            if (capType >= CAP_BUTT && capType < CAP_ROUND) {
                float extra = step(CAP_SQUARE, capType) * lineWidth;
                vec2 back = -forward;
                if (vertexNum < 0.5f || vertexNum > 2.5f) {
                    pos += back * (AA_THICKNESS + extra);
                    dy2 = AA_THICKNESS;
                } else {
                    dy2 = dot(pos + base - pointA, back) - extra;
                }
            }
            if (type >= JOINT_CAP_BUTT && type < JOINT_CAP_SQUARE + 0.5f) {
                float extra = step(JOINT_CAP_SQUARE, type) * lineWidth;
                if (vertexNum < 0.5f || vertexNum > 2.5f) {
                    dy3 = dot(pos + base - pointB, forward) - extra;
                } else {
                    pos += forward * (AA_THICKNESS + extra);
                    dy3 = AA_THICKNESS;
                    if (capType >= CAP_BUTT) {
                        dy2 -= AA_THICKNESS + extra;
                    }
                }
            }
        } else if (type >= JOINT_CAP_ROUND && type < JOINT_CAP_ROUND + 1.5f) {
            if (inner > 0.5f) {
                dy = -dy;
                inner = 0.0f;
            }
            vec2 d2 = abs(dy) * forward;
            if (vertexNum < 4.5f) {
                dy = -dy;
                pos = dy * norm;
            } else if (vertexNum < 5.5f) {
                pos = dy * norm;
            } else if (vertexNum < 6.5f) {
                pos = dy * norm + d2;
                vArc.x = abs(dy);
            } else {
                dy = -dy;
                pos = dy * norm + d2;
                vArc.x = abs(dy);
            }
            dy2 = 0.0f;
            vArc.y = dy;
            vArc.z = 0.0f;
            vArc.w = lineWidth;
            vType = 3.0f;
        } else if (abs(D) < 0.01f) {
            pos = dy * norm;
        } else {
            if (type >= ROUND && type < ROUND + 1.5f) {
                if (inner > 0.5f) {
                    dy = -dy;
                    inner = 0.0f;
                }
                if (vertexNum < 4.5f) {
                    pos = doBisect(norm, len, norm2, len2, -dy, 1.0f);
                } else if (vertexNum < 5.5f) {
                    pos = dy * norm;
                } else if (vertexNum > 7.5f) {
                    pos = dy * norm2;
                } else {
                    pos = doBisect(norm, len, norm2, len2, dy, 0.0f);
                    float d2 = abs(dy);
                    if (length(pos) > abs(dy) * 1.5f) {
                        if (vertexNum < 6.5f) {
                            pos.x = dy * norm.x - d2 * norm.y;
                            pos.y = dy * norm.y + d2 * norm.x;
                        } else {
                            pos.x = dy * norm2.x + d2 * norm2.y;
                            pos.y = dy * norm2.y - d2 * norm2.x;
                        }
                    }
                }
                vec2 norm3 = normalize(norm + norm2);

                float sign = step(0.0f, dy) * 2.0f - 1.0f;
                vArc.x = sign * dot(pos, norm3);
                vArc.y = pos.x * norm3.y - pos.y * norm3.x;
                vArc.z = dot(norm, norm3) * lineWidth;
                vArc.w = lineWidth;

                dy = -sign * dot(pos, norm);
                dy2 = -sign * dot(pos, norm2);
                dy3 = vArc.z - vArc.x;
                vType = 3.0f;
            } else {
                float hit = 0.0f;
                if (type >= BEVEL && type < BEVEL + 1.5f) {
                    if (dot(norm, norm2) > 0.0f) {
                        type = MITER;
                    }
                }

                if (type >= MITER && type < MITER + 3.5f) {
                    if (inner > 0.5f) {
                        dy = -dy;
                        inner = 0.0f;
                    }
                    float sign = step(0.0f, dy) * 2.0f - 1.0f;
                    pos = doBisect(norm, len, norm2, len2, dy, 0.0f);
                    if (length(pos) > abs(dy) * miterLimit) {
                        type = BEVEL;
                    } else {
                        if (vertexNum < 4.5f) {
                            dy = -dy;
                            pos = doBisect(norm, len, norm2, len2, dy, 1.0f);
                        } else if (vertexNum < 5.5f) {
                            pos = dy * norm;
                        } else if (vertexNum > 6.5f) {
                            pos = dy * norm2;
                        }
                        vType = 1.0f;
                        dy = -sign * dot(pos, norm);
                        dy2 = -sign * dot(pos, norm2);
                        hit = 1.0f;
                    }
                }
                if (type >= BEVEL && type < BEVEL + 1.5f) {
                    if (inner > 0.5f) {
                        dy = -dy;
                        inner = 0.0f;
                    }
                    float d2 = abs(dy);
                    vec2 pos3 = vec2(dy * norm.x - d2 * norm.y, dy * norm.y + d2 * norm.x);
                    vec2 pos4 = vec2(dy * norm2.x + d2 * norm2.y, dy * norm2.y - d2 * norm2.x);
                    if (vertexNum < 4.5f) {
                        pos = doBisect(norm, len, norm2, len2, -dy, 1.0f);
                    } else if (vertexNum < 5.5f) {
                        pos = dy * norm;
                    } else if (vertexNum > 7.5f) {
                        pos = dy * norm2;
                    } else {
                        if (vertexNum < 6.5f) {
                            pos = pos3;
                        } else {
                            pos = pos4;
                        }
                    }
                    vec2 norm3 = normalize(norm + norm2);
                    float sign = step(0.0f, dy) * 2.0f - 1.0f;

                    dy = -sign * dot(pos, norm);
                    dy2 = -sign * dot(pos, norm2);
                    dy3 = (-sign * dot(pos, norm3)) + lineWidth;
                    vType = 4.0f;
                    hit = 1.0f;
                }
                if (hit < 0.5f) {
                    gl_Position = vec4(0.0f, 0.0f, 0.0f, 1.0f);
                    return;
                }
            }
        }

        pos += base;
        // vDistance = vec4(dy, dy2, dy3, lineWidth) * resolution;
        // vArc = vArc * resolution;
    }

    gl_Position = vec4((projectionview * vec4(pos, 0.0, 1.0f)).xy, 0.0f, 1.0f);
}
