// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// A list of usefull distance function to simple primitives, and an example on how to
// do some interesting boolean operations, repetition and displacement.
//
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

float sdPlane(vec3 p) {
return p.y;
}

float sdSphere(vec3 p, float s) {
return length(p) - s;
}

float sdBox(vec3 p, vec3 b) {
vec3 d = abs(p) - b;
return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float udRoundBox(vec3 p, vec3 b, float r) {
return length(max(abs(p) - b, 0.0)) - r;
}

float sdTorus(vec3 p, vec2 t) {
return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float sdHexPrism(vec3 p, vec2 h) {
vec3 q = abs(p);
#if 0
return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
#else
float d1 = q.z - h.y;
float d2 = max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x;
return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
#endif
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
vec3 pa = p - a, ba = b - a;
float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
return length(pa - ba * h) - r;
}

float sdTriPrism(vec3 p, vec2 h) {
vec3 q = abs(p);
#if 0
return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, - p.y) - h.x * 0.5);
#else
float d1 = q.z - h.y;
float d2 = max(q.x * 0.866025 + p.y * 0.5, - p.y) - h.x * 0.5;
return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
#endif
}

float sdCylinder(vec3 p, vec2 h) {
vec2 d = abs(vec2(length(p.xz), p.y)) - h;
return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCone(in vec3 p, in vec3 c) {
vec2 q = vec2(length(p.xz), p.y);
#if 0
return max(max(dot(q, c.xy), p.y), - p.y - c.z);
#else
float d1 = - p.y - c.z;
float d2 = max(dot(q, c.xy), p.y);
return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
#endif
}

float length2(vec2 p) {
return sqrt(p.x * p.x + p.y * p.y);
}

float length6(vec2 p) {
p = p * p * p;
p = p * p;
return pow(p.x + p.y, 1.0 / 6.0);
}

float length8(vec2 p) {
p = p * p;
p = p * p;
p = p * p;
return pow(p.x + p.y, 1.0 / 8.0);
}

float sdTorus82(vec3 p, vec2 t) {
vec2 q = vec2(length2(p.xz) - t.x, p.y);
return length8(q) - t.y;
}

float sdTorus88(vec3 p, vec2 t) {
vec2 q = vec2(length8(p.xz) - t.x, p.y);
return length8(q) - t.y;
}

float sdCylinder6(vec3 p, vec2 h) {
return max(length6(p.xz) - h.x, abs(p.y) - h.y);
}

//----------------------------------------------------------------------

float opS(float d1, float d2) {
return max(- d2, d1);
}

vec2 opU(vec2 d1, vec2 d2) {
return (d1.x < d2.x) ? d1 : d2;
}

vec3 opRep(vec3 p, vec3 c) {
return mod(p, c) - 0.5 * c;
}

vec3 opTwist(vec3 p) {
float c = cos(10.0 * p.y + 10.0);
float s = sin(10.0 * p.y + 10.0);
mat2 m = mat2(c, - s, s, c);
return vec3(m * p.xz, p.y);
}

//----------------------------------------------------------------------

vec2 map(in vec3 pos) {
vec2 res = opU(vec2(sdPlane(pos), 1.0), vec2(sdSphere(pos - vec3(0.0, 0.25, 0.0), 0.25), 46.9));
res = opU(res, vec2(sdBox(pos - vec3(1.0, 0.25, 0.0), vec3(0.25)), 3.0));
res = opU(res, vec2(udRoundBox(pos - vec3(1.0, 0.25, 1.0), vec3(0.15), 0.1), 41.0));
res = opU(res, vec2(sdTorus(pos - vec3(0.0, 0.25, 1.0), vec2(0.20, 0.05)), 25.0));
res = opU(res, vec2(sdCapsule(pos, vec3(- 1.3, 0.20, - 0.1), vec3(- 1.0, 0.20, 0.2), 0.1), 31.9));
res = opU(res, vec2(sdTriPrism(pos - vec3(- 1.0, 0.25, - 1.0), vec2(0.25, 0.05)), 43.5));
res = opU(res, vec2(sdCylinder(pos - vec3(1.0, 0.30, - 1.0), vec2(0.1, 0.2)), 8.0));
res = opU(res, vec2(sdCone(pos - vec3(0.0, 0.50, - 1.0), vec3(0.8, 0.6, 0.3)), 55.0));
res = opU(res, vec2(sdTorus82(pos - vec3(0.0, 0.25, 2.0), vec2(0.20, 0.05)), 50.0));
res = opU(res, vec2(sdTorus88(pos - vec3(- 1.0, 0.25, 2.0), vec2(0.20, 0.05)), 43.0));
res = opU(res, vec2(sdCylinder6(pos - vec3(1.0, 0.30, 2.0), vec2(0.1, 0.2)), 12.0));
res = opU(res, vec2(sdHexPrism(pos - vec3(- 1.0, 0.20, 1.0), vec2(0.25, 0.05)), 17.0));

res = opU(res, vec2(opS(udRoundBox(pos - vec3(- 2.0, 0.2, 1.0), vec3(0.15), 0.05), sdSphere(pos - vec3(- 2.0, 0.2, 1.0), 0.25)), 13.0));
res = opU(res, vec2(opS(sdTorus82(pos - vec3(- 2.0, 0.2, 0.0), vec2(0.20, 0.1)), sdCylinder(opRep(vec3(atan(pos.x + 2.0, pos.z) / 6.2831, pos.y, 0.02 + 0.5 * length(pos - vec3(- 2.0, 0.2, 0.0))), vec3(0.05, 1.0, 0.05)), vec2(0.02, 0.6))), 51.0));
res = opU(res, vec2(0.7 * sdSphere(pos - vec3(- 2.0, 0.25, - 1.0), 0.2) +
    0.03 * sin(50.0 * pos.x) * sin(50.0 * pos.y) * sin(50.0 * pos.z), 65.0));
res = opU(res, vec2(0.5 * sdTorus(opTwist(pos - vec3(- 2.0, 0.25, 2.0)), vec2(0.20, 0.05)), 46.7));

return res;
}

vec2 castRay(in vec3 ro, in vec3 rd) {
float tmin = 1.0;
float tmax = 20.0;

#if 0
float tp1 = (0.0 - ro.y) / rd.y;
if (tp1 > 0.0) tmax = min(tmax, tp1);
float tp2 = (1.6 - ro.y) / rd.y;
if (tp2 > 0.0) {
if (ro.y > 1.6) tmin = max(tmin, tp2);
else tmax = min(tmax, tp2);
}
#endif

float precis = 0.002;
float t = tmin;
float m = - 1.0;
for (int i = 0;
i < 50;
i ++) {
vec2 res = map(ro + rd * t);
if (res.x < precis || t > tmax) break;
t += res.x;
m = res.y;
}

if (t > tmax) m = - 1.0;
return vec2(t, m);
}

float softshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax) {
float res = 1.0;
float t = mint;
for (int i = 0;
i < 16;
i ++) {
float h = map(ro + rd * t).x;
res = min(res, 8.0 * h / t);
t += clamp(h, 0.02, 0.10);
if (h < 0.001 || t > tmax) break;
}
return clamp(res, 0.0, 1.0);

}

vec3 calcNormal(in vec3 pos) {
vec3 eps = vec3(0.001, 0.0, 0.0);
vec3 nor = vec3(map(pos + eps.xyy).x - map(pos - eps.xyy).x, map(pos + eps.yxy).x - map(pos - eps.yxy).x, map(pos + eps.yyx).x - map(pos - eps.yyx).x);
return normalize(nor);
}

float calcAO(in vec3 pos, in vec3 nor) {
float occ = 0.0;
float sca = 1.0;
for (int i = 0;
i < 5;
i ++) {
float hr = 0.01 + 0.12 * float(i) / 4.0;
vec3 aopos = nor * hr + pos;
float dd = map(aopos).x;
occ += - (dd - hr) * sca;
sca *= 0.95;
}
return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

vec3 render(in vec3 ro, in vec3 rd) {
vec3 col = vec3(0.8, 0.9, 1.0);
vec2 res = castRay(ro, rd);
float t = res.x;
float m = res.y;
if (m > - 0.5) {
vec3 pos = ro + t * rd;
vec3 nor = calcNormal(pos);
vec3 ref = reflect(rd, nor);

        // material
col = 0.45 + 0.3 * sin(vec3(0.05, 0.08, 0.10) * (m - 1.0));

if (m < 1.5) {

float f = mod(floor(5.0 * pos.z) + floor(5.0 * pos.x), 2.0);
col = 0.4 + 0.1 * f * vec3(1.0);
}

        // lighitng
float occ = calcAO(pos, nor);
vec3 lig = normalize(vec3(- 0.6, 0.7, - 0.5));
float amb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
float dif = clamp(dot(nor, lig), 0.0, 1.0);
float bac = clamp(dot(nor, normalize(vec3(- lig.x, 0.0, - lig.z))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0);
float dom = smoothstep(- 0.1, 0.1, ref.y);
float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);
float spe = pow(clamp(dot(ref, lig), 0.0, 1.0), 16.0);

dif *= softshadow(pos, lig, 0.02, 2.5);
dom *= softshadow(pos, ref, 0.02, 2.5);

vec3 brdf = vec3(0.0);
brdf += 1.20 * dif * vec3(1.00, 0.90, 0.60);
brdf += 1.20 * spe * vec3(1.00, 0.90, 0.60) * dif;
brdf += 0.30 * amb * vec3(0.50, 0.70, 1.00) * occ;
brdf += 0.40 * dom * vec3(0.50, 0.70, 1.00) * occ;
brdf += 0.30 * bac * vec3(0.25, 0.25, 0.25) * occ;
brdf += 0.40 * fre * vec3(1.00, 1.00, 1.00) * occ;
brdf += 0.02;
col = col * brdf;

col = mix(col, vec3(0.8, 0.9, 1.0), 1.0 - exp(- 0.0005 * t * t));

}

return vec3(clamp(col, 0.0, 1.0));
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
vec3 cw = normalize(ta - ro);
vec3 cp = vec3(sin(cr), cos(cr), 0.0);
vec3 cu = normalize(cross(cw, cp));
vec3 cv = normalize(cross(cu, cw));
return mat3(cu, cv, cw);
}

void mainImage(in vec2 fragCoord) {
vec2 q = gl_FragCoord.xy / iResolution.xy;
vec2 p = - 1.0 + 2.0 * q;
p.x *= iResolution.x / iResolution.y;
vec2 mo = iMouse.xy / iResolution.xy;

float time = 15.0 + iGlobalTime;

        // camera
vec3 ro = vec3(- 0.5 + 3.2 * cos(0.1 * time + 6.0 * mo.x), 1.0 + 2.0 * mo.y, 0.5 + 3.2 * sin(0.1 * time + 6.0 * mo.x));
vec3 ta = vec3(- 0.5, - 0.4, 0.5);

        // camera-to-world transformation
mat3 ca = setCamera(ro, ta, 0.0);

        // ray direction
vec3 rd = ca * normalize(vec3(p.xy, 2.5));

        // render
vec3 col = render(ro, rd);

col = pow(col, vec3(0.4545));

fragment_color = vec4(col, 1.0);
}
