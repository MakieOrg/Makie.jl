// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

var ca = "136", Gy = {
    LEFT: 0,
    MIDDLE: 1,
    RIGHT: 2,
    ROTATE: 0,
    DOLLY: 1,
    PAN: 2
}, Vy = {
    ROTATE: 0,
    PAN: 1,
    DOLLY_PAN: 2,
    DOLLY_ROTATE: 3
}, uu = 0, tl = 1, du = 2, Wy = 3, qy = 0, Hc = 1, fu = 2, ir = 3, Ai = 0, it = 1, Ci = 2, kc = 1, Xy = 2, vn = 0, sr = 1, nl = 2, il = 3, rl = 4, pu = 5, _i = 100, mu = 101, gu = 102, sl = 103, ol = 104, xu = 200, yu = 201, vu = 202, _u = 203, Gc = 204, Vc = 205, Mu = 206, bu = 207, wu = 208, Su = 209, Tu = 210, Eu = 0, Au = 1, Cu = 2, ea = 3, Lu = 4, Ru = 5, Pu = 6, Iu = 7, Vs = 0, Du = 1, Fu = 2, _n = 0, Nu = 1, Bu = 2, zu = 3, Uu = 4, Ou = 5, ha = 300, Bi = 301, zi = 302, Ds = 303, Fs = 304, Pr = 306, Ws = 307, Ns = 1e3, vt = 1001, Bs = 1002, rt = 1003, ta = 1004, Jy = 1004, na = 1005, Yy = 1005, tt = 1006, Wc = 1007, Zy = 1007, Ui = 1008, $y = 1008, rn = 1009, Hu = 1010, ku = 1011, cr = 1012, Gu = 1013, Ps = 1014, nn = 1015, kn = 1016, Vu = 1017, Wu = 1018, qu = 1019, Ti = 1020, Xu = 1021, Gn = 1022, ct = 1023, Ju = 1024, Yu = 1025, Vn = 1026, Li = 1027, Zu = 1028, $u = 1029, ju = 1030, Qu = 1031, Ku = 1032, ed = 1033, al = 33776, ll = 33777, cl = 33778, hl = 33779, ul = 35840, dl = 35841, fl = 35842, pl = 35843, td = 36196, ml = 37492, gl = 37496, nd = 37808, id = 37809, rd = 37810, sd = 37811, od = 37812, ad = 37813, ld = 37814, cd = 37815, hd = 37816, ud = 37817, dd = 37818, fd = 37819, pd = 37820, md = 37821, gd = 36492, xd = 37840, yd = 37841, vd = 37842, _d = 37843, Md = 37844, bd = 37845, wd = 37846, Sd = 37847, Td = 37848, Ed = 37849, Ad = 37850, Cd = 37851, Ld = 37852, Rd = 37853, Pd = 2200, Id = 2201, Dd = 2202, zs = 2300, Us = 2301, yo = 2302, Mi = 2400, bi = 2401, Os = 2402, ua = 2500, qc = 2501, Fd = 0, jy = 1, Qy = 2, Nt = 3e3, Oi = 3001, Nd = 3200, Bd = 3201, Hi = 0, zd = 1, Ky = 0, vo = 7680, e0 = 7681, t0 = 7682, n0 = 7683, i0 = 34055, r0 = 34056, s0 = 5386, o0 = 512, a0 = 513, l0 = 514, c0 = 515, h0 = 516, u0 = 517, d0 = 518, Ud = 519, hr = 35044, ur = 35048, f0 = 35040, p0 = 35045, m0 = 35049, g0 = 35041, x0 = 35046, y0 = 35050, v0 = 35042, _0 = "100", xl = "300 es", En = class {
    addEventListener(e, t) {
        this._listeners === void 0 && (this._listeners = {});
        let n = this._listeners;
        n[e] === void 0 && (n[e] = []), n[e].indexOf(t) === -1 && n[e].push(t);
    }
    hasEventListener(e, t) {
        if (this._listeners === void 0) return !1;
        let n = this._listeners;
        return n[e] !== void 0 && n[e].indexOf(t) !== -1;
    }
    removeEventListener(e, t) {
        if (this._listeners === void 0) return;
        let i = this._listeners[e];
        if (i !== void 0) {
            let r = i.indexOf(t);
            r !== -1 && i.splice(r, 1);
        }
    }
    dispatchEvent(e) {
        if (this._listeners === void 0) return;
        let n = this._listeners[e.type];
        if (n !== void 0) {
            e.target = this;
            let i = n.slice(0);
            for(let r = 0, o = i.length; r < o; r++)i[r].call(this, e);
            e.target = null;
        }
    }
}, pt = [];
for(let s = 0; s < 256; s++)pt[s] = (s < 16 ? "0" : "") + s.toString(16);
var Vr = 1234567, Wn = Math.PI / 180, dr = 180 / Math.PI;
function Et() {
    let s = Math.random() * 4294967295 | 0, e = Math.random() * 4294967295 | 0, t = Math.random() * 4294967295 | 0, n = Math.random() * 4294967295 | 0;
    return (pt[s & 255] + pt[s >> 8 & 255] + pt[s >> 16 & 255] + pt[s >> 24 & 255] + "-" + pt[e & 255] + pt[e >> 8 & 255] + "-" + pt[e >> 16 & 15 | 64] + pt[e >> 24 & 255] + "-" + pt[t & 63 | 128] + pt[t >> 8 & 255] + "-" + pt[t >> 16 & 255] + pt[t >> 24 & 255] + pt[n & 255] + pt[n >> 8 & 255] + pt[n >> 16 & 255] + pt[n >> 24 & 255]).toUpperCase();
}
function mt(s, e, t) {
    return Math.max(e, Math.min(t, s));
}
function da(s, e) {
    return (s % e + e) % e;
}
function Od(s, e, t, n, i) {
    return n + (s - e) * (i - n) / (t - e);
}
function Hd(s, e, t) {
    return s !== e ? (t - s) / (e - s) : 0;
}
function or(s, e, t) {
    return (1 - t) * s + t * e;
}
function kd(s, e, t, n) {
    return or(s, e, 1 - Math.exp(-t * n));
}
function Gd(s, e = 1) {
    return e - Math.abs(da(s, e * 2) - e);
}
function Vd(s, e, t) {
    return s <= e ? 0 : s >= t ? 1 : (s = (s - e) / (t - e), s * s * (3 - 2 * s));
}
function Wd(s, e, t) {
    return s <= e ? 0 : s >= t ? 1 : (s = (s - e) / (t - e), s * s * s * (s * (s * 6 - 15) + 10));
}
function qd(s, e) {
    return s + Math.floor(Math.random() * (e - s + 1));
}
function Xd(s, e) {
    return s + Math.random() * (e - s);
}
function Jd(s) {
    return s * (.5 - Math.random());
}
function Yd(s) {
    return s !== void 0 && (Vr = s % 2147483647), Vr = Vr * 16807 % 2147483647, (Vr - 1) / 2147483646;
}
function Zd(s) {
    return s * Wn;
}
function $d(s) {
    return s * dr;
}
function ia(s) {
    return (s & s - 1) === 0 && s !== 0;
}
function Xc(s) {
    return Math.pow(2, Math.ceil(Math.log(s) / Math.LN2));
}
function Jc(s) {
    return Math.pow(2, Math.floor(Math.log(s) / Math.LN2));
}
function jd(s, e, t, n, i) {
    let r = Math.cos, o = Math.sin, a = r(t / 2), l = o(t / 2), c = r((e + n) / 2), h = o((e + n) / 2), u = r((e - n) / 2), d = o((e - n) / 2), f = r((n - e) / 2), m = o((n - e) / 2);
    switch(i){
        case "XYX":
            s.set(a * h, l * u, l * d, a * c);
            break;
        case "YZY":
            s.set(l * d, a * h, l * u, a * c);
            break;
        case "ZXZ":
            s.set(l * u, l * d, a * h, a * c);
            break;
        case "XZX":
            s.set(a * h, l * m, l * f, a * c);
            break;
        case "YXY":
            s.set(l * f, a * h, l * m, a * c);
            break;
        case "ZYZ":
            s.set(l * m, l * f, a * h, a * c);
            break;
        default:
            console.warn("THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: " + i);
    }
}
var M0 = Object.freeze({
    __proto__: null,
    DEG2RAD: Wn,
    RAD2DEG: dr,
    generateUUID: Et,
    clamp: mt,
    euclideanModulo: da,
    mapLinear: Od,
    inverseLerp: Hd,
    lerp: or,
    damp: kd,
    pingpong: Gd,
    smoothstep: Vd,
    smootherstep: Wd,
    randInt: qd,
    randFloat: Xd,
    randFloatSpread: Jd,
    seededRandom: Yd,
    degToRad: Zd,
    radToDeg: $d,
    isPowerOfTwo: ia,
    ceilPowerOfTwo: Xc,
    floorPowerOfTwo: Jc,
    setQuaternionFromProperEuler: jd
}), X = class {
    constructor(e = 0, t = 0){
        this.x = e, this.y = t;
    }
    get width() {
        return this.x;
    }
    set width(e) {
        this.x = e;
    }
    get height() {
        return this.y;
    }
    set height(e) {
        this.y = e;
    }
    set(e, t) {
        return this.x = e, this.y = t, this;
    }
    setScalar(e) {
        return this.x = e, this.y = e, this;
    }
    setX(e) {
        return this.x = e, this;
    }
    setY(e) {
        return this.y = e, this;
    }
    setComponent(e, t) {
        switch(e){
            case 0:
                this.x = t;
                break;
            case 1:
                this.y = t;
                break;
            default:
                throw new Error("index is out of range: " + e);
        }
        return this;
    }
    getComponent(e) {
        switch(e){
            case 0:
                return this.x;
            case 1:
                return this.y;
            default:
                throw new Error("index is out of range: " + e);
        }
    }
    clone() {
        return new this.constructor(this.x, this.y);
    }
    copy(e) {
        return this.x = e.x, this.y = e.y, this;
    }
    add(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector2: .add() now only accepts one argument. Use .addVectors( a, b ) instead."), this.addVectors(e, t)) : (this.x += e.x, this.y += e.y, this);
    }
    addScalar(e) {
        return this.x += e, this.y += e, this;
    }
    addVectors(e, t) {
        return this.x = e.x + t.x, this.y = e.y + t.y, this;
    }
    addScaledVector(e, t) {
        return this.x += e.x * t, this.y += e.y * t, this;
    }
    sub(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector2: .sub() now only accepts one argument. Use .subVectors( a, b ) instead."), this.subVectors(e, t)) : (this.x -= e.x, this.y -= e.y, this);
    }
    subScalar(e) {
        return this.x -= e, this.y -= e, this;
    }
    subVectors(e, t) {
        return this.x = e.x - t.x, this.y = e.y - t.y, this;
    }
    multiply(e) {
        return this.x *= e.x, this.y *= e.y, this;
    }
    multiplyScalar(e) {
        return this.x *= e, this.y *= e, this;
    }
    divide(e) {
        return this.x /= e.x, this.y /= e.y, this;
    }
    divideScalar(e) {
        return this.multiplyScalar(1 / e);
    }
    applyMatrix3(e) {
        let t = this.x, n = this.y, i = e.elements;
        return this.x = i[0] * t + i[3] * n + i[6], this.y = i[1] * t + i[4] * n + i[7], this;
    }
    min(e) {
        return this.x = Math.min(this.x, e.x), this.y = Math.min(this.y, e.y), this;
    }
    max(e) {
        return this.x = Math.max(this.x, e.x), this.y = Math.max(this.y, e.y), this;
    }
    clamp(e, t) {
        return this.x = Math.max(e.x, Math.min(t.x, this.x)), this.y = Math.max(e.y, Math.min(t.y, this.y)), this;
    }
    clampScalar(e, t) {
        return this.x = Math.max(e, Math.min(t, this.x)), this.y = Math.max(e, Math.min(t, this.y)), this;
    }
    clampLength(e, t) {
        let n = this.length();
        return this.divideScalar(n || 1).multiplyScalar(Math.max(e, Math.min(t, n)));
    }
    floor() {
        return this.x = Math.floor(this.x), this.y = Math.floor(this.y), this;
    }
    ceil() {
        return this.x = Math.ceil(this.x), this.y = Math.ceil(this.y), this;
    }
    round() {
        return this.x = Math.round(this.x), this.y = Math.round(this.y), this;
    }
    roundToZero() {
        return this.x = this.x < 0 ? Math.ceil(this.x) : Math.floor(this.x), this.y = this.y < 0 ? Math.ceil(this.y) : Math.floor(this.y), this;
    }
    negate() {
        return this.x = -this.x, this.y = -this.y, this;
    }
    dot(e) {
        return this.x * e.x + this.y * e.y;
    }
    cross(e) {
        return this.x * e.y - this.y * e.x;
    }
    lengthSq() {
        return this.x * this.x + this.y * this.y;
    }
    length() {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }
    manhattanLength() {
        return Math.abs(this.x) + Math.abs(this.y);
    }
    normalize() {
        return this.divideScalar(this.length() || 1);
    }
    angle() {
        return Math.atan2(-this.y, -this.x) + Math.PI;
    }
    distanceTo(e) {
        return Math.sqrt(this.distanceToSquared(e));
    }
    distanceToSquared(e) {
        let t = this.x - e.x, n = this.y - e.y;
        return t * t + n * n;
    }
    manhattanDistanceTo(e) {
        return Math.abs(this.x - e.x) + Math.abs(this.y - e.y);
    }
    setLength(e) {
        return this.normalize().multiplyScalar(e);
    }
    lerp(e, t) {
        return this.x += (e.x - this.x) * t, this.y += (e.y - this.y) * t, this;
    }
    lerpVectors(e, t, n) {
        return this.x = e.x + (t.x - e.x) * n, this.y = e.y + (t.y - e.y) * n, this;
    }
    equals(e) {
        return e.x === this.x && e.y === this.y;
    }
    fromArray(e, t = 0) {
        return this.x = e[t], this.y = e[t + 1], this;
    }
    toArray(e = [], t = 0) {
        return e[t] = this.x, e[t + 1] = this.y, e;
    }
    fromBufferAttribute(e, t, n) {
        return n !== void 0 && console.warn("THREE.Vector2: offset has been removed from .fromBufferAttribute()."), this.x = e.getX(t), this.y = e.getY(t), this;
    }
    rotateAround(e, t) {
        let n = Math.cos(t), i = Math.sin(t), r = this.x - e.x, o = this.y - e.y;
        return this.x = r * n - o * i + e.x, this.y = r * i + o * n + e.y, this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y;
    }
};
X.prototype.isVector2 = !0;
var lt = class {
    constructor(){
        this.elements = [
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
        ], arguments.length > 0 && console.error("THREE.Matrix3: the constructor no longer reads arguments. use .set() instead.");
    }
    set(e, t, n, i, r, o, a, l, c) {
        let h = this.elements;
        return h[0] = e, h[1] = i, h[2] = a, h[3] = t, h[4] = r, h[5] = l, h[6] = n, h[7] = o, h[8] = c, this;
    }
    identity() {
        return this.set(1, 0, 0, 0, 1, 0, 0, 0, 1), this;
    }
    copy(e) {
        let t = this.elements, n = e.elements;
        return t[0] = n[0], t[1] = n[1], t[2] = n[2], t[3] = n[3], t[4] = n[4], t[5] = n[5], t[6] = n[6], t[7] = n[7], t[8] = n[8], this;
    }
    extractBasis(e, t, n) {
        return e.setFromMatrix3Column(this, 0), t.setFromMatrix3Column(this, 1), n.setFromMatrix3Column(this, 2), this;
    }
    setFromMatrix4(e) {
        let t = e.elements;
        return this.set(t[0], t[4], t[8], t[1], t[5], t[9], t[2], t[6], t[10]), this;
    }
    multiply(e) {
        return this.multiplyMatrices(this, e);
    }
    premultiply(e) {
        return this.multiplyMatrices(e, this);
    }
    multiplyMatrices(e, t) {
        let n = e.elements, i = t.elements, r = this.elements, o = n[0], a = n[3], l = n[6], c = n[1], h = n[4], u = n[7], d = n[2], f = n[5], m = n[8], x = i[0], v = i[3], g = i[6], p = i[1], _ = i[4], y = i[7], b = i[2], A = i[5], L = i[8];
        return r[0] = o * x + a * p + l * b, r[3] = o * v + a * _ + l * A, r[6] = o * g + a * y + l * L, r[1] = c * x + h * p + u * b, r[4] = c * v + h * _ + u * A, r[7] = c * g + h * y + u * L, r[2] = d * x + f * p + m * b, r[5] = d * v + f * _ + m * A, r[8] = d * g + f * y + m * L, this;
    }
    multiplyScalar(e) {
        let t = this.elements;
        return t[0] *= e, t[3] *= e, t[6] *= e, t[1] *= e, t[4] *= e, t[7] *= e, t[2] *= e, t[5] *= e, t[8] *= e, this;
    }
    determinant() {
        let e = this.elements, t = e[0], n = e[1], i = e[2], r = e[3], o = e[4], a = e[5], l = e[6], c = e[7], h = e[8];
        return t * o * h - t * a * c - n * r * h + n * a * l + i * r * c - i * o * l;
    }
    invert() {
        let e = this.elements, t = e[0], n = e[1], i = e[2], r = e[3], o = e[4], a = e[5], l = e[6], c = e[7], h = e[8], u = h * o - a * c, d = a * l - h * r, f = c * r - o * l, m = t * u + n * d + i * f;
        if (m === 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0);
        let x = 1 / m;
        return e[0] = u * x, e[1] = (i * c - h * n) * x, e[2] = (a * n - i * o) * x, e[3] = d * x, e[4] = (h * t - i * l) * x, e[5] = (i * r - a * t) * x, e[6] = f * x, e[7] = (n * l - c * t) * x, e[8] = (o * t - n * r) * x, this;
    }
    transpose() {
        let e, t = this.elements;
        return e = t[1], t[1] = t[3], t[3] = e, e = t[2], t[2] = t[6], t[6] = e, e = t[5], t[5] = t[7], t[7] = e, this;
    }
    getNormalMatrix(e) {
        return this.setFromMatrix4(e).invert().transpose();
    }
    transposeIntoArray(e) {
        let t = this.elements;
        return e[0] = t[0], e[1] = t[3], e[2] = t[6], e[3] = t[1], e[4] = t[4], e[5] = t[7], e[6] = t[2], e[7] = t[5], e[8] = t[8], this;
    }
    setUvTransform(e, t, n, i, r, o, a) {
        let l = Math.cos(r), c = Math.sin(r);
        return this.set(n * l, n * c, -n * (l * o + c * a) + o + e, -i * c, i * l, -i * (-c * o + l * a) + a + t, 0, 0, 1), this;
    }
    scale(e, t) {
        let n = this.elements;
        return n[0] *= e, n[3] *= e, n[6] *= e, n[1] *= t, n[4] *= t, n[7] *= t, this;
    }
    rotate(e) {
        let t = Math.cos(e), n = Math.sin(e), i = this.elements, r = i[0], o = i[3], a = i[6], l = i[1], c = i[4], h = i[7];
        return i[0] = t * r + n * l, i[3] = t * o + n * c, i[6] = t * a + n * h, i[1] = -n * r + t * l, i[4] = -n * o + t * c, i[7] = -n * a + t * h, this;
    }
    translate(e, t) {
        let n = this.elements;
        return n[0] += e * n[2], n[3] += e * n[5], n[6] += e * n[8], n[1] += t * n[2], n[4] += t * n[5], n[7] += t * n[8], this;
    }
    equals(e) {
        let t = this.elements, n = e.elements;
        for(let i = 0; i < 9; i++)if (t[i] !== n[i]) return !1;
        return !0;
    }
    fromArray(e, t = 0) {
        for(let n = 0; n < 9; n++)this.elements[n] = e[n + t];
        return this;
    }
    toArray(e = [], t = 0) {
        let n = this.elements;
        return e[t] = n[0], e[t + 1] = n[1], e[t + 2] = n[2], e[t + 3] = n[3], e[t + 4] = n[4], e[t + 5] = n[5], e[t + 6] = n[6], e[t + 7] = n[7], e[t + 8] = n[8], e;
    }
    clone() {
        return new this.constructor().fromArray(this.elements);
    }
};
lt.prototype.isMatrix3 = !0;
function Yc(s) {
    if (s.length === 0) return -1 / 0;
    let e = s[0];
    for(let t = 1, n = s.length; t < n; ++t)s[t] > e && (e = s[t]);
    return e;
}
var Qd = {
    Int8Array,
    Uint8Array,
    Uint8ClampedArray,
    Int16Array,
    Uint16Array,
    Int32Array,
    Uint32Array,
    Float32Array,
    Float64Array
};
function wi(s, e) {
    return new Qd[s](e);
}
function qs(s) {
    return document.createElementNS("http://www.w3.org/1999/xhtml", s);
}
var ti, Yn = class {
    static getDataURL(e) {
        if (/^data:/i.test(e.src) || typeof HTMLCanvasElement > "u") return e.src;
        let t;
        if (e instanceof HTMLCanvasElement) t = e;
        else {
            ti === void 0 && (ti = qs("canvas")), ti.width = e.width, ti.height = e.height;
            let n = ti.getContext("2d");
            e instanceof ImageData ? n.putImageData(e, 0, 0) : n.drawImage(e, 0, 0, e.width, e.height), t = ti;
        }
        return t.width > 2048 || t.height > 2048 ? (console.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", e), t.toDataURL("image/jpeg", .6)) : t.toDataURL("image/png");
    }
}, Kd = 0, ot = class extends En {
    constructor(e = ot.DEFAULT_IMAGE, t = ot.DEFAULT_MAPPING, n = vt, i = vt, r = tt, o = Ui, a = ct, l = rn, c = 1, h = Nt){
        super();
        Object.defineProperty(this, "id", {
            value: Kd++
        }), this.uuid = Et(), this.name = "", this.image = e, this.mipmaps = [], this.mapping = t, this.wrapS = n, this.wrapT = i, this.magFilter = r, this.minFilter = o, this.anisotropy = c, this.format = a, this.internalFormat = null, this.type = l, this.offset = new X(0, 0), this.repeat = new X(1, 1), this.center = new X(0, 0), this.rotation = 0, this.matrixAutoUpdate = !0, this.matrix = new lt, this.generateMipmaps = !0, this.premultiplyAlpha = !1, this.flipY = !0, this.unpackAlignment = 4, this.encoding = h, this.userData = {}, this.version = 0, this.onUpdate = null, this.isRenderTargetTexture = !1;
    }
    updateMatrix() {
        this.matrix.setUvTransform(this.offset.x, this.offset.y, this.repeat.x, this.repeat.y, this.rotation, this.center.x, this.center.y);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.name = e.name, this.image = e.image, this.mipmaps = e.mipmaps.slice(0), this.mapping = e.mapping, this.wrapS = e.wrapS, this.wrapT = e.wrapT, this.magFilter = e.magFilter, this.minFilter = e.minFilter, this.anisotropy = e.anisotropy, this.format = e.format, this.internalFormat = e.internalFormat, this.type = e.type, this.offset.copy(e.offset), this.repeat.copy(e.repeat), this.center.copy(e.center), this.rotation = e.rotation, this.matrixAutoUpdate = e.matrixAutoUpdate, this.matrix.copy(e.matrix), this.generateMipmaps = e.generateMipmaps, this.premultiplyAlpha = e.premultiplyAlpha, this.flipY = e.flipY, this.unpackAlignment = e.unpackAlignment, this.encoding = e.encoding, this.userData = JSON.parse(JSON.stringify(e.userData)), this;
    }
    toJSON(e) {
        let t = e === void 0 || typeof e == "string";
        if (!t && e.textures[this.uuid] !== void 0) return e.textures[this.uuid];
        let n = {
            metadata: {
                version: 4.5,
                type: "Texture",
                generator: "Texture.toJSON"
            },
            uuid: this.uuid,
            name: this.name,
            mapping: this.mapping,
            repeat: [
                this.repeat.x,
                this.repeat.y
            ],
            offset: [
                this.offset.x,
                this.offset.y
            ],
            center: [
                this.center.x,
                this.center.y
            ],
            rotation: this.rotation,
            wrap: [
                this.wrapS,
                this.wrapT
            ],
            format: this.format,
            type: this.type,
            encoding: this.encoding,
            minFilter: this.minFilter,
            magFilter: this.magFilter,
            anisotropy: this.anisotropy,
            flipY: this.flipY,
            premultiplyAlpha: this.premultiplyAlpha,
            unpackAlignment: this.unpackAlignment
        };
        if (this.image !== void 0) {
            let i = this.image;
            if (i.uuid === void 0 && (i.uuid = Et()), !t && e.images[i.uuid] === void 0) {
                let r;
                if (Array.isArray(i)) {
                    r = [];
                    for(let o = 0, a = i.length; o < a; o++)i[o].isDataTexture ? r.push(_o(i[o].image)) : r.push(_o(i[o]));
                } else r = _o(i);
                e.images[i.uuid] = {
                    uuid: i.uuid,
                    url: r
                };
            }
            n.image = i.uuid;
        }
        return JSON.stringify(this.userData) !== "{}" && (n.userData = this.userData), t || (e.textures[this.uuid] = n), n;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
    transformUv(e) {
        if (this.mapping !== ha) return e;
        if (e.applyMatrix3(this.matrix), e.x < 0 || e.x > 1) switch(this.wrapS){
            case Ns:
                e.x = e.x - Math.floor(e.x);
                break;
            case vt:
                e.x = e.x < 0 ? 0 : 1;
                break;
            case Bs:
                Math.abs(Math.floor(e.x) % 2) === 1 ? e.x = Math.ceil(e.x) - e.x : e.x = e.x - Math.floor(e.x);
                break;
        }
        if (e.y < 0 || e.y > 1) switch(this.wrapT){
            case Ns:
                e.y = e.y - Math.floor(e.y);
                break;
            case vt:
                e.y = e.y < 0 ? 0 : 1;
                break;
            case Bs:
                Math.abs(Math.floor(e.y) % 2) === 1 ? e.y = Math.ceil(e.y) - e.y : e.y = e.y - Math.floor(e.y);
                break;
        }
        return this.flipY && (e.y = 1 - e.y), e;
    }
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
};
ot.DEFAULT_IMAGE = void 0;
ot.DEFAULT_MAPPING = ha;
ot.prototype.isTexture = !0;
function _o(s) {
    return typeof HTMLImageElement < "u" && s instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && s instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && s instanceof ImageBitmap ? Yn.getDataURL(s) : s.data ? {
        data: Array.prototype.slice.call(s.data),
        width: s.width,
        height: s.height,
        type: s.data.constructor.name
    } : (console.warn("THREE.Texture: Unable to serialize Texture."), {});
}
var Ve = class {
    constructor(e = 0, t = 0, n = 0, i = 1){
        this.x = e, this.y = t, this.z = n, this.w = i;
    }
    get width() {
        return this.z;
    }
    set width(e) {
        this.z = e;
    }
    get height() {
        return this.w;
    }
    set height(e) {
        this.w = e;
    }
    set(e, t, n, i) {
        return this.x = e, this.y = t, this.z = n, this.w = i, this;
    }
    setScalar(e) {
        return this.x = e, this.y = e, this.z = e, this.w = e, this;
    }
    setX(e) {
        return this.x = e, this;
    }
    setY(e) {
        return this.y = e, this;
    }
    setZ(e) {
        return this.z = e, this;
    }
    setW(e) {
        return this.w = e, this;
    }
    setComponent(e, t) {
        switch(e){
            case 0:
                this.x = t;
                break;
            case 1:
                this.y = t;
                break;
            case 2:
                this.z = t;
                break;
            case 3:
                this.w = t;
                break;
            default:
                throw new Error("index is out of range: " + e);
        }
        return this;
    }
    getComponent(e) {
        switch(e){
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            case 3:
                return this.w;
            default:
                throw new Error("index is out of range: " + e);
        }
    }
    clone() {
        return new this.constructor(this.x, this.y, this.z, this.w);
    }
    copy(e) {
        return this.x = e.x, this.y = e.y, this.z = e.z, this.w = e.w !== void 0 ? e.w : 1, this;
    }
    add(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector4: .add() now only accepts one argument. Use .addVectors( a, b ) instead."), this.addVectors(e, t)) : (this.x += e.x, this.y += e.y, this.z += e.z, this.w += e.w, this);
    }
    addScalar(e) {
        return this.x += e, this.y += e, this.z += e, this.w += e, this;
    }
    addVectors(e, t) {
        return this.x = e.x + t.x, this.y = e.y + t.y, this.z = e.z + t.z, this.w = e.w + t.w, this;
    }
    addScaledVector(e, t) {
        return this.x += e.x * t, this.y += e.y * t, this.z += e.z * t, this.w += e.w * t, this;
    }
    sub(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector4: .sub() now only accepts one argument. Use .subVectors( a, b ) instead."), this.subVectors(e, t)) : (this.x -= e.x, this.y -= e.y, this.z -= e.z, this.w -= e.w, this);
    }
    subScalar(e) {
        return this.x -= e, this.y -= e, this.z -= e, this.w -= e, this;
    }
    subVectors(e, t) {
        return this.x = e.x - t.x, this.y = e.y - t.y, this.z = e.z - t.z, this.w = e.w - t.w, this;
    }
    multiply(e) {
        return this.x *= e.x, this.y *= e.y, this.z *= e.z, this.w *= e.w, this;
    }
    multiplyScalar(e) {
        return this.x *= e, this.y *= e, this.z *= e, this.w *= e, this;
    }
    applyMatrix4(e) {
        let t = this.x, n = this.y, i = this.z, r = this.w, o = e.elements;
        return this.x = o[0] * t + o[4] * n + o[8] * i + o[12] * r, this.y = o[1] * t + o[5] * n + o[9] * i + o[13] * r, this.z = o[2] * t + o[6] * n + o[10] * i + o[14] * r, this.w = o[3] * t + o[7] * n + o[11] * i + o[15] * r, this;
    }
    divideScalar(e) {
        return this.multiplyScalar(1 / e);
    }
    setAxisAngleFromQuaternion(e) {
        this.w = 2 * Math.acos(e.w);
        let t = Math.sqrt(1 - e.w * e.w);
        return t < 1e-4 ? (this.x = 1, this.y = 0, this.z = 0) : (this.x = e.x / t, this.y = e.y / t, this.z = e.z / t), this;
    }
    setAxisAngleFromRotationMatrix(e) {
        let t, n, i, r, l = e.elements, c = l[0], h = l[4], u = l[8], d = l[1], f = l[5], m = l[9], x = l[2], v = l[6], g = l[10];
        if (Math.abs(h - d) < .01 && Math.abs(u - x) < .01 && Math.abs(m - v) < .01) {
            if (Math.abs(h + d) < .1 && Math.abs(u + x) < .1 && Math.abs(m + v) < .1 && Math.abs(c + f + g - 3) < .1) return this.set(1, 0, 0, 0), this;
            t = Math.PI;
            let _ = (c + 1) / 2, y = (f + 1) / 2, b = (g + 1) / 2, A = (h + d) / 4, L = (u + x) / 4, I = (m + v) / 4;
            return _ > y && _ > b ? _ < .01 ? (n = 0, i = .707106781, r = .707106781) : (n = Math.sqrt(_), i = A / n, r = L / n) : y > b ? y < .01 ? (n = .707106781, i = 0, r = .707106781) : (i = Math.sqrt(y), n = A / i, r = I / i) : b < .01 ? (n = .707106781, i = .707106781, r = 0) : (r = Math.sqrt(b), n = L / r, i = I / r), this.set(n, i, r, t), this;
        }
        let p = Math.sqrt((v - m) * (v - m) + (u - x) * (u - x) + (d - h) * (d - h));
        return Math.abs(p) < .001 && (p = 1), this.x = (v - m) / p, this.y = (u - x) / p, this.z = (d - h) / p, this.w = Math.acos((c + f + g - 1) / 2), this;
    }
    min(e) {
        return this.x = Math.min(this.x, e.x), this.y = Math.min(this.y, e.y), this.z = Math.min(this.z, e.z), this.w = Math.min(this.w, e.w), this;
    }
    max(e) {
        return this.x = Math.max(this.x, e.x), this.y = Math.max(this.y, e.y), this.z = Math.max(this.z, e.z), this.w = Math.max(this.w, e.w), this;
    }
    clamp(e, t) {
        return this.x = Math.max(e.x, Math.min(t.x, this.x)), this.y = Math.max(e.y, Math.min(t.y, this.y)), this.z = Math.max(e.z, Math.min(t.z, this.z)), this.w = Math.max(e.w, Math.min(t.w, this.w)), this;
    }
    clampScalar(e, t) {
        return this.x = Math.max(e, Math.min(t, this.x)), this.y = Math.max(e, Math.min(t, this.y)), this.z = Math.max(e, Math.min(t, this.z)), this.w = Math.max(e, Math.min(t, this.w)), this;
    }
    clampLength(e, t) {
        let n = this.length();
        return this.divideScalar(n || 1).multiplyScalar(Math.max(e, Math.min(t, n)));
    }
    floor() {
        return this.x = Math.floor(this.x), this.y = Math.floor(this.y), this.z = Math.floor(this.z), this.w = Math.floor(this.w), this;
    }
    ceil() {
        return this.x = Math.ceil(this.x), this.y = Math.ceil(this.y), this.z = Math.ceil(this.z), this.w = Math.ceil(this.w), this;
    }
    round() {
        return this.x = Math.round(this.x), this.y = Math.round(this.y), this.z = Math.round(this.z), this.w = Math.round(this.w), this;
    }
    roundToZero() {
        return this.x = this.x < 0 ? Math.ceil(this.x) : Math.floor(this.x), this.y = this.y < 0 ? Math.ceil(this.y) : Math.floor(this.y), this.z = this.z < 0 ? Math.ceil(this.z) : Math.floor(this.z), this.w = this.w < 0 ? Math.ceil(this.w) : Math.floor(this.w), this;
    }
    negate() {
        return this.x = -this.x, this.y = -this.y, this.z = -this.z, this.w = -this.w, this;
    }
    dot(e) {
        return this.x * e.x + this.y * e.y + this.z * e.z + this.w * e.w;
    }
    lengthSq() {
        return this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w;
    }
    length() {
        return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
    }
    manhattanLength() {
        return Math.abs(this.x) + Math.abs(this.y) + Math.abs(this.z) + Math.abs(this.w);
    }
    normalize() {
        return this.divideScalar(this.length() || 1);
    }
    setLength(e) {
        return this.normalize().multiplyScalar(e);
    }
    lerp(e, t) {
        return this.x += (e.x - this.x) * t, this.y += (e.y - this.y) * t, this.z += (e.z - this.z) * t, this.w += (e.w - this.w) * t, this;
    }
    lerpVectors(e, t, n) {
        return this.x = e.x + (t.x - e.x) * n, this.y = e.y + (t.y - e.y) * n, this.z = e.z + (t.z - e.z) * n, this.w = e.w + (t.w - e.w) * n, this;
    }
    equals(e) {
        return e.x === this.x && e.y === this.y && e.z === this.z && e.w === this.w;
    }
    fromArray(e, t = 0) {
        return this.x = e[t], this.y = e[t + 1], this.z = e[t + 2], this.w = e[t + 3], this;
    }
    toArray(e = [], t = 0) {
        return e[t] = this.x, e[t + 1] = this.y, e[t + 2] = this.z, e[t + 3] = this.w, e;
    }
    fromBufferAttribute(e, t, n) {
        return n !== void 0 && console.warn("THREE.Vector4: offset has been removed from .fromBufferAttribute()."), this.x = e.getX(t), this.y = e.getY(t), this.z = e.getZ(t), this.w = e.getW(t), this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this.z = Math.random(), this.w = Math.random(), this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y, yield this.z, yield this.w;
    }
};
Ve.prototype.isVector4 = !0;
var At = class extends En {
    constructor(e, t, n = {}){
        super();
        this.width = e, this.height = t, this.depth = 1, this.scissor = new Ve(0, 0, e, t), this.scissorTest = !1, this.viewport = new Ve(0, 0, e, t), this.texture = new ot(void 0, n.mapping, n.wrapS, n.wrapT, n.magFilter, n.minFilter, n.format, n.type, n.anisotropy, n.encoding), this.texture.isRenderTargetTexture = !0, this.texture.image = {
            width: e,
            height: t,
            depth: 1
        }, this.texture.generateMipmaps = n.generateMipmaps !== void 0 ? n.generateMipmaps : !1, this.texture.internalFormat = n.internalFormat !== void 0 ? n.internalFormat : null, this.texture.minFilter = n.minFilter !== void 0 ? n.minFilter : tt, this.depthBuffer = n.depthBuffer !== void 0 ? n.depthBuffer : !0, this.stencilBuffer = n.stencilBuffer !== void 0 ? n.stencilBuffer : !1, this.depthTexture = n.depthTexture !== void 0 ? n.depthTexture : null;
    }
    setTexture(e) {
        e.image = {
            width: this.width,
            height: this.height,
            depth: this.depth
        }, this.texture = e;
    }
    setSize(e, t, n = 1) {
        (this.width !== e || this.height !== t || this.depth !== n) && (this.width = e, this.height = t, this.depth = n, this.texture.image.width = e, this.texture.image.height = t, this.texture.image.depth = n, this.dispose()), this.viewport.set(0, 0, e, t), this.scissor.set(0, 0, e, t);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.width = e.width, this.height = e.height, this.depth = e.depth, this.viewport.copy(e.viewport), this.texture = e.texture.clone(), this.texture.image = {
            ...this.texture.image
        }, this.depthBuffer = e.depthBuffer, this.stencilBuffer = e.stencilBuffer, this.depthTexture = e.depthTexture, this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
};
At.prototype.isWebGLRenderTarget = !0;
var Zc = class extends At {
    constructor(e, t, n){
        super(e, t);
        let i = this.texture;
        this.texture = [];
        for(let r = 0; r < n; r++)this.texture[r] = i.clone();
    }
    setSize(e, t, n = 1) {
        if (this.width !== e || this.height !== t || this.depth !== n) {
            this.width = e, this.height = t, this.depth = n;
            for(let i = 0, r = this.texture.length; i < r; i++)this.texture[i].image.width = e, this.texture[i].image.height = t, this.texture[i].image.depth = n;
            this.dispose();
        }
        return this.viewport.set(0, 0, e, t), this.scissor.set(0, 0, e, t), this;
    }
    copy(e) {
        this.dispose(), this.width = e.width, this.height = e.height, this.depth = e.depth, this.viewport.set(0, 0, this.width, this.height), this.scissor.set(0, 0, this.width, this.height), this.depthBuffer = e.depthBuffer, this.stencilBuffer = e.stencilBuffer, this.depthTexture = e.depthTexture, this.texture.length = 0;
        for(let t = 0, n = e.texture.length; t < n; t++)this.texture[t] = e.texture[t].clone();
        return this;
    }
};
Zc.prototype.isWebGLMultipleRenderTargets = !0;
var Xs = class extends At {
    constructor(e, t, n = {}){
        super(e, t, n);
        this.samples = 4, this.ignoreDepthForMultisampleCopy = n.ignoreDepth !== void 0 ? n.ignoreDepth : !0, this.useRenderToTexture = n.useRenderToTexture !== void 0 ? n.useRenderToTexture : !1, this.useRenderbuffer = this.useRenderToTexture === !1;
    }
    copy(e) {
        return super.copy.call(this, e), this.samples = e.samples, this.useRenderToTexture = e.useRenderToTexture, this.useRenderbuffer = e.useRenderbuffer, this;
    }
};
Xs.prototype.isWebGLMultisampleRenderTarget = !0;
var gt = class {
    constructor(e = 0, t = 0, n = 0, i = 1){
        this._x = e, this._y = t, this._z = n, this._w = i;
    }
    static slerp(e, t, n, i) {
        return console.warn("THREE.Quaternion: Static .slerp() has been deprecated. Use qm.slerpQuaternions( qa, qb, t ) instead."), n.slerpQuaternions(e, t, i);
    }
    static slerpFlat(e, t, n, i, r, o, a) {
        let l = n[i + 0], c = n[i + 1], h = n[i + 2], u = n[i + 3], d = r[o + 0], f = r[o + 1], m = r[o + 2], x = r[o + 3];
        if (a === 0) {
            e[t + 0] = l, e[t + 1] = c, e[t + 2] = h, e[t + 3] = u;
            return;
        }
        if (a === 1) {
            e[t + 0] = d, e[t + 1] = f, e[t + 2] = m, e[t + 3] = x;
            return;
        }
        if (u !== x || l !== d || c !== f || h !== m) {
            let v = 1 - a, g = l * d + c * f + h * m + u * x, p = g >= 0 ? 1 : -1, _ = 1 - g * g;
            if (_ > Number.EPSILON) {
                let b = Math.sqrt(_), A = Math.atan2(b, g * p);
                v = Math.sin(v * A) / b, a = Math.sin(a * A) / b;
            }
            let y = a * p;
            if (l = l * v + d * y, c = c * v + f * y, h = h * v + m * y, u = u * v + x * y, v === 1 - a) {
                let b1 = 1 / Math.sqrt(l * l + c * c + h * h + u * u);
                l *= b1, c *= b1, h *= b1, u *= b1;
            }
        }
        e[t] = l, e[t + 1] = c, e[t + 2] = h, e[t + 3] = u;
    }
    static multiplyQuaternionsFlat(e, t, n, i, r, o) {
        let a = n[i], l = n[i + 1], c = n[i + 2], h = n[i + 3], u = r[o], d = r[o + 1], f = r[o + 2], m = r[o + 3];
        return e[t] = a * m + h * u + l * f - c * d, e[t + 1] = l * m + h * d + c * u - a * f, e[t + 2] = c * m + h * f + a * d - l * u, e[t + 3] = h * m - a * u - l * d - c * f, e;
    }
    get x() {
        return this._x;
    }
    set x(e) {
        this._x = e, this._onChangeCallback();
    }
    get y() {
        return this._y;
    }
    set y(e) {
        this._y = e, this._onChangeCallback();
    }
    get z() {
        return this._z;
    }
    set z(e) {
        this._z = e, this._onChangeCallback();
    }
    get w() {
        return this._w;
    }
    set w(e) {
        this._w = e, this._onChangeCallback();
    }
    set(e, t, n, i) {
        return this._x = e, this._y = t, this._z = n, this._w = i, this._onChangeCallback(), this;
    }
    clone() {
        return new this.constructor(this._x, this._y, this._z, this._w);
    }
    copy(e) {
        return this._x = e.x, this._y = e.y, this._z = e.z, this._w = e.w, this._onChangeCallback(), this;
    }
    setFromEuler(e, t) {
        if (!(e && e.isEuler)) throw new Error("THREE.Quaternion: .setFromEuler() now expects an Euler rotation rather than a Vector3 and order.");
        let n = e._x, i = e._y, r = e._z, o = e._order, a = Math.cos, l = Math.sin, c = a(n / 2), h = a(i / 2), u = a(r / 2), d = l(n / 2), f = l(i / 2), m = l(r / 2);
        switch(o){
            case "XYZ":
                this._x = d * h * u + c * f * m, this._y = c * f * u - d * h * m, this._z = c * h * m + d * f * u, this._w = c * h * u - d * f * m;
                break;
            case "YXZ":
                this._x = d * h * u + c * f * m, this._y = c * f * u - d * h * m, this._z = c * h * m - d * f * u, this._w = c * h * u + d * f * m;
                break;
            case "ZXY":
                this._x = d * h * u - c * f * m, this._y = c * f * u + d * h * m, this._z = c * h * m + d * f * u, this._w = c * h * u - d * f * m;
                break;
            case "ZYX":
                this._x = d * h * u - c * f * m, this._y = c * f * u + d * h * m, this._z = c * h * m - d * f * u, this._w = c * h * u + d * f * m;
                break;
            case "YZX":
                this._x = d * h * u + c * f * m, this._y = c * f * u + d * h * m, this._z = c * h * m - d * f * u, this._w = c * h * u - d * f * m;
                break;
            case "XZY":
                this._x = d * h * u - c * f * m, this._y = c * f * u - d * h * m, this._z = c * h * m + d * f * u, this._w = c * h * u + d * f * m;
                break;
            default:
                console.warn("THREE.Quaternion: .setFromEuler() encountered an unknown order: " + o);
        }
        return t !== !1 && this._onChangeCallback(), this;
    }
    setFromAxisAngle(e, t) {
        let n = t / 2, i = Math.sin(n);
        return this._x = e.x * i, this._y = e.y * i, this._z = e.z * i, this._w = Math.cos(n), this._onChangeCallback(), this;
    }
    setFromRotationMatrix(e) {
        let t = e.elements, n = t[0], i = t[4], r = t[8], o = t[1], a = t[5], l = t[9], c = t[2], h = t[6], u = t[10], d = n + a + u;
        if (d > 0) {
            let f = .5 / Math.sqrt(d + 1);
            this._w = .25 / f, this._x = (h - l) * f, this._y = (r - c) * f, this._z = (o - i) * f;
        } else if (n > a && n > u) {
            let f1 = 2 * Math.sqrt(1 + n - a - u);
            this._w = (h - l) / f1, this._x = .25 * f1, this._y = (i + o) / f1, this._z = (r + c) / f1;
        } else if (a > u) {
            let f2 = 2 * Math.sqrt(1 + a - n - u);
            this._w = (r - c) / f2, this._x = (i + o) / f2, this._y = .25 * f2, this._z = (l + h) / f2;
        } else {
            let f3 = 2 * Math.sqrt(1 + u - n - a);
            this._w = (o - i) / f3, this._x = (r + c) / f3, this._y = (l + h) / f3, this._z = .25 * f3;
        }
        return this._onChangeCallback(), this;
    }
    setFromUnitVectors(e, t) {
        let n = e.dot(t) + 1;
        return n < Number.EPSILON ? (n = 0, Math.abs(e.x) > Math.abs(e.z) ? (this._x = -e.y, this._y = e.x, this._z = 0, this._w = n) : (this._x = 0, this._y = -e.z, this._z = e.y, this._w = n)) : (this._x = e.y * t.z - e.z * t.y, this._y = e.z * t.x - e.x * t.z, this._z = e.x * t.y - e.y * t.x, this._w = n), this.normalize();
    }
    angleTo(e) {
        return 2 * Math.acos(Math.abs(mt(this.dot(e), -1, 1)));
    }
    rotateTowards(e, t) {
        let n = this.angleTo(e);
        if (n === 0) return this;
        let i = Math.min(1, t / n);
        return this.slerp(e, i), this;
    }
    identity() {
        return this.set(0, 0, 0, 1);
    }
    invert() {
        return this.conjugate();
    }
    conjugate() {
        return this._x *= -1, this._y *= -1, this._z *= -1, this._onChangeCallback(), this;
    }
    dot(e) {
        return this._x * e._x + this._y * e._y + this._z * e._z + this._w * e._w;
    }
    lengthSq() {
        return this._x * this._x + this._y * this._y + this._z * this._z + this._w * this._w;
    }
    length() {
        return Math.sqrt(this._x * this._x + this._y * this._y + this._z * this._z + this._w * this._w);
    }
    normalize() {
        let e = this.length();
        return e === 0 ? (this._x = 0, this._y = 0, this._z = 0, this._w = 1) : (e = 1 / e, this._x = this._x * e, this._y = this._y * e, this._z = this._z * e, this._w = this._w * e), this._onChangeCallback(), this;
    }
    multiply(e, t) {
        return t !== void 0 ? (console.warn("THREE.Quaternion: .multiply() now only accepts one argument. Use .multiplyQuaternions( a, b ) instead."), this.multiplyQuaternions(e, t)) : this.multiplyQuaternions(this, e);
    }
    premultiply(e) {
        return this.multiplyQuaternions(e, this);
    }
    multiplyQuaternions(e, t) {
        let n = e._x, i = e._y, r = e._z, o = e._w, a = t._x, l = t._y, c = t._z, h = t._w;
        return this._x = n * h + o * a + i * c - r * l, this._y = i * h + o * l + r * a - n * c, this._z = r * h + o * c + n * l - i * a, this._w = o * h - n * a - i * l - r * c, this._onChangeCallback(), this;
    }
    slerp(e, t) {
        if (t === 0) return this;
        if (t === 1) return this.copy(e);
        let n = this._x, i = this._y, r = this._z, o = this._w, a = o * e._w + n * e._x + i * e._y + r * e._z;
        if (a < 0 ? (this._w = -e._w, this._x = -e._x, this._y = -e._y, this._z = -e._z, a = -a) : this.copy(e), a >= 1) return this._w = o, this._x = n, this._y = i, this._z = r, this;
        let l = 1 - a * a;
        if (l <= Number.EPSILON) {
            let f = 1 - t;
            return this._w = f * o + t * this._w, this._x = f * n + t * this._x, this._y = f * i + t * this._y, this._z = f * r + t * this._z, this.normalize(), this._onChangeCallback(), this;
        }
        let c = Math.sqrt(l), h = Math.atan2(c, a), u = Math.sin((1 - t) * h) / c, d = Math.sin(t * h) / c;
        return this._w = o * u + this._w * d, this._x = n * u + this._x * d, this._y = i * u + this._y * d, this._z = r * u + this._z * d, this._onChangeCallback(), this;
    }
    slerpQuaternions(e, t, n) {
        this.copy(e).slerp(t, n);
    }
    random() {
        let e = Math.random(), t = Math.sqrt(1 - e), n = Math.sqrt(e), i = 2 * Math.PI * Math.random(), r = 2 * Math.PI * Math.random();
        return this.set(t * Math.cos(i), n * Math.sin(r), n * Math.cos(r), t * Math.sin(i));
    }
    equals(e) {
        return e._x === this._x && e._y === this._y && e._z === this._z && e._w === this._w;
    }
    fromArray(e, t = 0) {
        return this._x = e[t], this._y = e[t + 1], this._z = e[t + 2], this._w = e[t + 3], this._onChangeCallback(), this;
    }
    toArray(e = [], t = 0) {
        return e[t] = this._x, e[t + 1] = this._y, e[t + 2] = this._z, e[t + 3] = this._w, e;
    }
    fromBufferAttribute(e, t) {
        return this._x = e.getX(t), this._y = e.getY(t), this._z = e.getZ(t), this._w = e.getW(t), this;
    }
    _onChange(e) {
        return this._onChangeCallback = e, this;
    }
    _onChangeCallback() {}
};
gt.prototype.isQuaternion = !0;
var M = class {
    constructor(e = 0, t = 0, n = 0){
        this.x = e, this.y = t, this.z = n;
    }
    set(e, t, n) {
        return n === void 0 && (n = this.z), this.x = e, this.y = t, this.z = n, this;
    }
    setScalar(e) {
        return this.x = e, this.y = e, this.z = e, this;
    }
    setX(e) {
        return this.x = e, this;
    }
    setY(e) {
        return this.y = e, this;
    }
    setZ(e) {
        return this.z = e, this;
    }
    setComponent(e, t) {
        switch(e){
            case 0:
                this.x = t;
                break;
            case 1:
                this.y = t;
                break;
            case 2:
                this.z = t;
                break;
            default:
                throw new Error("index is out of range: " + e);
        }
        return this;
    }
    getComponent(e) {
        switch(e){
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            default:
                throw new Error("index is out of range: " + e);
        }
    }
    clone() {
        return new this.constructor(this.x, this.y, this.z);
    }
    copy(e) {
        return this.x = e.x, this.y = e.y, this.z = e.z, this;
    }
    add(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector3: .add() now only accepts one argument. Use .addVectors( a, b ) instead."), this.addVectors(e, t)) : (this.x += e.x, this.y += e.y, this.z += e.z, this);
    }
    addScalar(e) {
        return this.x += e, this.y += e, this.z += e, this;
    }
    addVectors(e, t) {
        return this.x = e.x + t.x, this.y = e.y + t.y, this.z = e.z + t.z, this;
    }
    addScaledVector(e, t) {
        return this.x += e.x * t, this.y += e.y * t, this.z += e.z * t, this;
    }
    sub(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector3: .sub() now only accepts one argument. Use .subVectors( a, b ) instead."), this.subVectors(e, t)) : (this.x -= e.x, this.y -= e.y, this.z -= e.z, this);
    }
    subScalar(e) {
        return this.x -= e, this.y -= e, this.z -= e, this;
    }
    subVectors(e, t) {
        return this.x = e.x - t.x, this.y = e.y - t.y, this.z = e.z - t.z, this;
    }
    multiply(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector3: .multiply() now only accepts one argument. Use .multiplyVectors( a, b ) instead."), this.multiplyVectors(e, t)) : (this.x *= e.x, this.y *= e.y, this.z *= e.z, this);
    }
    multiplyScalar(e) {
        return this.x *= e, this.y *= e, this.z *= e, this;
    }
    multiplyVectors(e, t) {
        return this.x = e.x * t.x, this.y = e.y * t.y, this.z = e.z * t.z, this;
    }
    applyEuler(e) {
        return e && e.isEuler || console.error("THREE.Vector3: .applyEuler() now expects an Euler rotation rather than a Vector3 and order."), this.applyQuaternion(yl.setFromEuler(e));
    }
    applyAxisAngle(e, t) {
        return this.applyQuaternion(yl.setFromAxisAngle(e, t));
    }
    applyMatrix3(e) {
        let t = this.x, n = this.y, i = this.z, r = e.elements;
        return this.x = r[0] * t + r[3] * n + r[6] * i, this.y = r[1] * t + r[4] * n + r[7] * i, this.z = r[2] * t + r[5] * n + r[8] * i, this;
    }
    applyNormalMatrix(e) {
        return this.applyMatrix3(e).normalize();
    }
    applyMatrix4(e) {
        let t = this.x, n = this.y, i = this.z, r = e.elements, o = 1 / (r[3] * t + r[7] * n + r[11] * i + r[15]);
        return this.x = (r[0] * t + r[4] * n + r[8] * i + r[12]) * o, this.y = (r[1] * t + r[5] * n + r[9] * i + r[13]) * o, this.z = (r[2] * t + r[6] * n + r[10] * i + r[14]) * o, this;
    }
    applyQuaternion(e) {
        let t = this.x, n = this.y, i = this.z, r = e.x, o = e.y, a = e.z, l = e.w, c = l * t + o * i - a * n, h = l * n + a * t - r * i, u = l * i + r * n - o * t, d = -r * t - o * n - a * i;
        return this.x = c * l + d * -r + h * -a - u * -o, this.y = h * l + d * -o + u * -r - c * -a, this.z = u * l + d * -a + c * -o - h * -r, this;
    }
    project(e) {
        return this.applyMatrix4(e.matrixWorldInverse).applyMatrix4(e.projectionMatrix);
    }
    unproject(e) {
        return this.applyMatrix4(e.projectionMatrixInverse).applyMatrix4(e.matrixWorld);
    }
    transformDirection(e) {
        let t = this.x, n = this.y, i = this.z, r = e.elements;
        return this.x = r[0] * t + r[4] * n + r[8] * i, this.y = r[1] * t + r[5] * n + r[9] * i, this.z = r[2] * t + r[6] * n + r[10] * i, this.normalize();
    }
    divide(e) {
        return this.x /= e.x, this.y /= e.y, this.z /= e.z, this;
    }
    divideScalar(e) {
        return this.multiplyScalar(1 / e);
    }
    min(e) {
        return this.x = Math.min(this.x, e.x), this.y = Math.min(this.y, e.y), this.z = Math.min(this.z, e.z), this;
    }
    max(e) {
        return this.x = Math.max(this.x, e.x), this.y = Math.max(this.y, e.y), this.z = Math.max(this.z, e.z), this;
    }
    clamp(e, t) {
        return this.x = Math.max(e.x, Math.min(t.x, this.x)), this.y = Math.max(e.y, Math.min(t.y, this.y)), this.z = Math.max(e.z, Math.min(t.z, this.z)), this;
    }
    clampScalar(e, t) {
        return this.x = Math.max(e, Math.min(t, this.x)), this.y = Math.max(e, Math.min(t, this.y)), this.z = Math.max(e, Math.min(t, this.z)), this;
    }
    clampLength(e, t) {
        let n = this.length();
        return this.divideScalar(n || 1).multiplyScalar(Math.max(e, Math.min(t, n)));
    }
    floor() {
        return this.x = Math.floor(this.x), this.y = Math.floor(this.y), this.z = Math.floor(this.z), this;
    }
    ceil() {
        return this.x = Math.ceil(this.x), this.y = Math.ceil(this.y), this.z = Math.ceil(this.z), this;
    }
    round() {
        return this.x = Math.round(this.x), this.y = Math.round(this.y), this.z = Math.round(this.z), this;
    }
    roundToZero() {
        return this.x = this.x < 0 ? Math.ceil(this.x) : Math.floor(this.x), this.y = this.y < 0 ? Math.ceil(this.y) : Math.floor(this.y), this.z = this.z < 0 ? Math.ceil(this.z) : Math.floor(this.z), this;
    }
    negate() {
        return this.x = -this.x, this.y = -this.y, this.z = -this.z, this;
    }
    dot(e) {
        return this.x * e.x + this.y * e.y + this.z * e.z;
    }
    lengthSq() {
        return this.x * this.x + this.y * this.y + this.z * this.z;
    }
    length() {
        return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }
    manhattanLength() {
        return Math.abs(this.x) + Math.abs(this.y) + Math.abs(this.z);
    }
    normalize() {
        return this.divideScalar(this.length() || 1);
    }
    setLength(e) {
        return this.normalize().multiplyScalar(e);
    }
    lerp(e, t) {
        return this.x += (e.x - this.x) * t, this.y += (e.y - this.y) * t, this.z += (e.z - this.z) * t, this;
    }
    lerpVectors(e, t, n) {
        return this.x = e.x + (t.x - e.x) * n, this.y = e.y + (t.y - e.y) * n, this.z = e.z + (t.z - e.z) * n, this;
    }
    cross(e, t) {
        return t !== void 0 ? (console.warn("THREE.Vector3: .cross() now only accepts one argument. Use .crossVectors( a, b ) instead."), this.crossVectors(e, t)) : this.crossVectors(this, e);
    }
    crossVectors(e, t) {
        let n = e.x, i = e.y, r = e.z, o = t.x, a = t.y, l = t.z;
        return this.x = i * l - r * a, this.y = r * o - n * l, this.z = n * a - i * o, this;
    }
    projectOnVector(e) {
        let t = e.lengthSq();
        if (t === 0) return this.set(0, 0, 0);
        let n = e.dot(this) / t;
        return this.copy(e).multiplyScalar(n);
    }
    projectOnPlane(e) {
        return Mo.copy(this).projectOnVector(e), this.sub(Mo);
    }
    reflect(e) {
        return this.sub(Mo.copy(e).multiplyScalar(2 * this.dot(e)));
    }
    angleTo(e) {
        let t = Math.sqrt(this.lengthSq() * e.lengthSq());
        if (t === 0) return Math.PI / 2;
        let n = this.dot(e) / t;
        return Math.acos(mt(n, -1, 1));
    }
    distanceTo(e) {
        return Math.sqrt(this.distanceToSquared(e));
    }
    distanceToSquared(e) {
        let t = this.x - e.x, n = this.y - e.y, i = this.z - e.z;
        return t * t + n * n + i * i;
    }
    manhattanDistanceTo(e) {
        return Math.abs(this.x - e.x) + Math.abs(this.y - e.y) + Math.abs(this.z - e.z);
    }
    setFromSpherical(e) {
        return this.setFromSphericalCoords(e.radius, e.phi, e.theta);
    }
    setFromSphericalCoords(e, t, n) {
        let i = Math.sin(t) * e;
        return this.x = i * Math.sin(n), this.y = Math.cos(t) * e, this.z = i * Math.cos(n), this;
    }
    setFromCylindrical(e) {
        return this.setFromCylindricalCoords(e.radius, e.theta, e.y);
    }
    setFromCylindricalCoords(e, t, n) {
        return this.x = e * Math.sin(t), this.y = n, this.z = e * Math.cos(t), this;
    }
    setFromMatrixPosition(e) {
        let t = e.elements;
        return this.x = t[12], this.y = t[13], this.z = t[14], this;
    }
    setFromMatrixScale(e) {
        let t = this.setFromMatrixColumn(e, 0).length(), n = this.setFromMatrixColumn(e, 1).length(), i = this.setFromMatrixColumn(e, 2).length();
        return this.x = t, this.y = n, this.z = i, this;
    }
    setFromMatrixColumn(e, t) {
        return this.fromArray(e.elements, t * 4);
    }
    setFromMatrix3Column(e, t) {
        return this.fromArray(e.elements, t * 3);
    }
    equals(e) {
        return e.x === this.x && e.y === this.y && e.z === this.z;
    }
    fromArray(e, t = 0) {
        return this.x = e[t], this.y = e[t + 1], this.z = e[t + 2], this;
    }
    toArray(e = [], t = 0) {
        return e[t] = this.x, e[t + 1] = this.y, e[t + 2] = this.z, e;
    }
    fromBufferAttribute(e, t, n) {
        return n !== void 0 && console.warn("THREE.Vector3: offset has been removed from .fromBufferAttribute()."), this.x = e.getX(t), this.y = e.getY(t), this.z = e.getZ(t), this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this.z = Math.random(), this;
    }
    randomDirection() {
        let e = (Math.random() - .5) * 2, t = Math.random() * Math.PI * 2, n = Math.sqrt(1 - e ** 2);
        return this.x = n * Math.cos(t), this.y = n * Math.sin(t), this.z = e, this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y, yield this.z;
    }
};
M.prototype.isVector3 = !0;
var Mo = new M, yl = new gt, Lt = class {
    constructor(e = new M(1 / 0, 1 / 0, 1 / 0), t = new M(-1 / 0, -1 / 0, -1 / 0)){
        this.min = e, this.max = t;
    }
    set(e, t) {
        return this.min.copy(e), this.max.copy(t), this;
    }
    setFromArray(e) {
        let t = 1 / 0, n = 1 / 0, i = 1 / 0, r = -1 / 0, o = -1 / 0, a = -1 / 0;
        for(let l = 0, c = e.length; l < c; l += 3){
            let h = e[l], u = e[l + 1], d = e[l + 2];
            h < t && (t = h), u < n && (n = u), d < i && (i = d), h > r && (r = h), u > o && (o = u), d > a && (a = d);
        }
        return this.min.set(t, n, i), this.max.set(r, o, a), this;
    }
    setFromBufferAttribute(e) {
        let t = 1 / 0, n = 1 / 0, i = 1 / 0, r = -1 / 0, o = -1 / 0, a = -1 / 0;
        for(let l = 0, c = e.count; l < c; l++){
            let h = e.getX(l), u = e.getY(l), d = e.getZ(l);
            h < t && (t = h), u < n && (n = u), d < i && (i = d), h > r && (r = h), u > o && (o = u), d > a && (a = d);
        }
        return this.min.set(t, n, i), this.max.set(r, o, a), this;
    }
    setFromPoints(e) {
        this.makeEmpty();
        for(let t = 0, n = e.length; t < n; t++)this.expandByPoint(e[t]);
        return this;
    }
    setFromCenterAndSize(e, t) {
        let n = Ji.copy(t).multiplyScalar(.5);
        return this.min.copy(e).sub(n), this.max.copy(e).add(n), this;
    }
    setFromObject(e) {
        return this.makeEmpty(), this.expandByObject(e);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.min.copy(e.min), this.max.copy(e.max), this;
    }
    makeEmpty() {
        return this.min.x = this.min.y = this.min.z = 1 / 0, this.max.x = this.max.y = this.max.z = -1 / 0, this;
    }
    isEmpty() {
        return this.max.x < this.min.x || this.max.y < this.min.y || this.max.z < this.min.z;
    }
    getCenter(e) {
        return this.isEmpty() ? e.set(0, 0, 0) : e.addVectors(this.min, this.max).multiplyScalar(.5);
    }
    getSize(e) {
        return this.isEmpty() ? e.set(0, 0, 0) : e.subVectors(this.max, this.min);
    }
    expandByPoint(e) {
        return this.min.min(e), this.max.max(e), this;
    }
    expandByVector(e) {
        return this.min.sub(e), this.max.add(e), this;
    }
    expandByScalar(e) {
        return this.min.addScalar(-e), this.max.addScalar(e), this;
    }
    expandByObject(e) {
        e.updateWorldMatrix(!1, !1);
        let t = e.geometry;
        t !== void 0 && (t.boundingBox === null && t.computeBoundingBox(), bo.copy(t.boundingBox), bo.applyMatrix4(e.matrixWorld), this.union(bo));
        let n = e.children;
        for(let i = 0, r = n.length; i < r; i++)this.expandByObject(n[i]);
        return this;
    }
    containsPoint(e) {
        return !(e.x < this.min.x || e.x > this.max.x || e.y < this.min.y || e.y > this.max.y || e.z < this.min.z || e.z > this.max.z);
    }
    containsBox(e) {
        return this.min.x <= e.min.x && e.max.x <= this.max.x && this.min.y <= e.min.y && e.max.y <= this.max.y && this.min.z <= e.min.z && e.max.z <= this.max.z;
    }
    getParameter(e, t) {
        return t.set((e.x - this.min.x) / (this.max.x - this.min.x), (e.y - this.min.y) / (this.max.y - this.min.y), (e.z - this.min.z) / (this.max.z - this.min.z));
    }
    intersectsBox(e) {
        return !(e.max.x < this.min.x || e.min.x > this.max.x || e.max.y < this.min.y || e.min.y > this.max.y || e.max.z < this.min.z || e.min.z > this.max.z);
    }
    intersectsSphere(e) {
        return this.clampPoint(e.center, Ji), Ji.distanceToSquared(e.center) <= e.radius * e.radius;
    }
    intersectsPlane(e) {
        let t, n;
        return e.normal.x > 0 ? (t = e.normal.x * this.min.x, n = e.normal.x * this.max.x) : (t = e.normal.x * this.max.x, n = e.normal.x * this.min.x), e.normal.y > 0 ? (t += e.normal.y * this.min.y, n += e.normal.y * this.max.y) : (t += e.normal.y * this.max.y, n += e.normal.y * this.min.y), e.normal.z > 0 ? (t += e.normal.z * this.min.z, n += e.normal.z * this.max.z) : (t += e.normal.z * this.max.z, n += e.normal.z * this.min.z), t <= -e.constant && n >= -e.constant;
    }
    intersectsTriangle(e) {
        if (this.isEmpty()) return !1;
        this.getCenter(Yi), Wr.subVectors(this.max, Yi), ni.subVectors(e.a, Yi), ii.subVectors(e.b, Yi), ri.subVectors(e.c, Yi), un.subVectors(ii, ni), dn.subVectors(ri, ii), Pn.subVectors(ni, ri);
        let t = [
            0,
            -un.z,
            un.y,
            0,
            -dn.z,
            dn.y,
            0,
            -Pn.z,
            Pn.y,
            un.z,
            0,
            -un.x,
            dn.z,
            0,
            -dn.x,
            Pn.z,
            0,
            -Pn.x,
            -un.y,
            un.x,
            0,
            -dn.y,
            dn.x,
            0,
            -Pn.y,
            Pn.x,
            0
        ];
        return !wo(t, ni, ii, ri, Wr) || (t = [
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
        ], !wo(t, ni, ii, ri, Wr)) ? !1 : (qr.crossVectors(un, dn), t = [
            qr.x,
            qr.y,
            qr.z
        ], wo(t, ni, ii, ri, Wr));
    }
    clampPoint(e, t) {
        return t.copy(e).clamp(this.min, this.max);
    }
    distanceToPoint(e) {
        return Ji.copy(e).clamp(this.min, this.max).sub(e).length();
    }
    getBoundingSphere(e) {
        return this.getCenter(e.center), e.radius = this.getSize(Ji).length() * .5, e;
    }
    intersect(e) {
        return this.min.max(e.min), this.max.min(e.max), this.isEmpty() && this.makeEmpty(), this;
    }
    union(e) {
        return this.min.min(e.min), this.max.max(e.max), this;
    }
    applyMatrix4(e) {
        return this.isEmpty() ? this : ($t[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(e), $t[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(e), $t[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(e), $t[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(e), $t[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(e), $t[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(e), $t[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(e), $t[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(e), this.setFromPoints($t), this);
    }
    translate(e) {
        return this.min.add(e), this.max.add(e), this;
    }
    equals(e) {
        return e.min.equals(this.min) && e.max.equals(this.max);
    }
};
Lt.prototype.isBox3 = !0;
var $t = [
    new M,
    new M,
    new M,
    new M,
    new M,
    new M,
    new M,
    new M
], Ji = new M, bo = new Lt, ni = new M, ii = new M, ri = new M, un = new M, dn = new M, Pn = new M, Yi = new M, Wr = new M, qr = new M, In = new M;
function wo(s, e, t, n, i) {
    for(let r = 0, o = s.length - 3; r <= o; r += 3){
        In.fromArray(s, r);
        let a = i.x * Math.abs(In.x) + i.y * Math.abs(In.y) + i.z * Math.abs(In.z), l = e.dot(In), c = t.dot(In), h = n.dot(In);
        if (Math.max(-Math.max(l, c, h), Math.min(l, c, h)) > a) return !1;
    }
    return !0;
}
var ef = new Lt, vl = new M, Xr = new M, So = new M, An = class {
    constructor(e = new M, t = -1){
        this.center = e, this.radius = t;
    }
    set(e, t) {
        return this.center.copy(e), this.radius = t, this;
    }
    setFromPoints(e, t) {
        let n = this.center;
        t !== void 0 ? n.copy(t) : ef.setFromPoints(e).getCenter(n);
        let i = 0;
        for(let r = 0, o = e.length; r < o; r++)i = Math.max(i, n.distanceToSquared(e[r]));
        return this.radius = Math.sqrt(i), this;
    }
    copy(e) {
        return this.center.copy(e.center), this.radius = e.radius, this;
    }
    isEmpty() {
        return this.radius < 0;
    }
    makeEmpty() {
        return this.center.set(0, 0, 0), this.radius = -1, this;
    }
    containsPoint(e) {
        return e.distanceToSquared(this.center) <= this.radius * this.radius;
    }
    distanceToPoint(e) {
        return e.distanceTo(this.center) - this.radius;
    }
    intersectsSphere(e) {
        let t = this.radius + e.radius;
        return e.center.distanceToSquared(this.center) <= t * t;
    }
    intersectsBox(e) {
        return e.intersectsSphere(this);
    }
    intersectsPlane(e) {
        return Math.abs(e.distanceToPoint(this.center)) <= this.radius;
    }
    clampPoint(e, t) {
        let n = this.center.distanceToSquared(e);
        return t.copy(e), n > this.radius * this.radius && (t.sub(this.center).normalize(), t.multiplyScalar(this.radius).add(this.center)), t;
    }
    getBoundingBox(e) {
        return this.isEmpty() ? (e.makeEmpty(), e) : (e.set(this.center, this.center), e.expandByScalar(this.radius), e);
    }
    applyMatrix4(e) {
        return this.center.applyMatrix4(e), this.radius = this.radius * e.getMaxScaleOnAxis(), this;
    }
    translate(e) {
        return this.center.add(e), this;
    }
    expandByPoint(e) {
        So.subVectors(e, this.center);
        let t = So.lengthSq();
        if (t > this.radius * this.radius) {
            let n = Math.sqrt(t), i = (n - this.radius) * .5;
            this.center.add(So.multiplyScalar(i / n)), this.radius += i;
        }
        return this;
    }
    union(e) {
        return this.center.equals(e.center) === !0 ? Xr.set(0, 0, 1).multiplyScalar(e.radius) : Xr.subVectors(e.center, this.center).normalize().multiplyScalar(e.radius), this.expandByPoint(vl.copy(e.center).add(Xr)), this.expandByPoint(vl.copy(e.center).sub(Xr)), this;
    }
    equals(e) {
        return e.center.equals(this.center) && e.radius === this.radius;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, jt = new M, To = new M, Jr = new M, fn = new M, Eo = new M, Yr = new M, Ao = new M, Cn = class {
    constructor(e = new M, t = new M(0, 0, -1)){
        this.origin = e, this.direction = t;
    }
    set(e, t) {
        return this.origin.copy(e), this.direction.copy(t), this;
    }
    copy(e) {
        return this.origin.copy(e.origin), this.direction.copy(e.direction), this;
    }
    at(e, t) {
        return t.copy(this.direction).multiplyScalar(e).add(this.origin);
    }
    lookAt(e) {
        return this.direction.copy(e).sub(this.origin).normalize(), this;
    }
    recast(e) {
        return this.origin.copy(this.at(e, jt)), this;
    }
    closestPointToPoint(e, t) {
        t.subVectors(e, this.origin);
        let n = t.dot(this.direction);
        return n < 0 ? t.copy(this.origin) : t.copy(this.direction).multiplyScalar(n).add(this.origin);
    }
    distanceToPoint(e) {
        return Math.sqrt(this.distanceSqToPoint(e));
    }
    distanceSqToPoint(e) {
        let t = jt.subVectors(e, this.origin).dot(this.direction);
        return t < 0 ? this.origin.distanceToSquared(e) : (jt.copy(this.direction).multiplyScalar(t).add(this.origin), jt.distanceToSquared(e));
    }
    distanceSqToSegment(e, t, n, i) {
        To.copy(e).add(t).multiplyScalar(.5), Jr.copy(t).sub(e).normalize(), fn.copy(this.origin).sub(To);
        let r = e.distanceTo(t) * .5, o = -this.direction.dot(Jr), a = fn.dot(this.direction), l = -fn.dot(Jr), c = fn.lengthSq(), h = Math.abs(1 - o * o), u, d, f, m;
        if (h > 0) if (u = o * l - a, d = o * a - l, m = r * h, u >= 0) if (d >= -m) if (d <= m) {
            let x = 1 / h;
            u *= x, d *= x, f = u * (u + o * d + 2 * a) + d * (o * u + d + 2 * l) + c;
        } else d = r, u = Math.max(0, -(o * d + a)), f = -u * u + d * (d + 2 * l) + c;
        else d = -r, u = Math.max(0, -(o * d + a)), f = -u * u + d * (d + 2 * l) + c;
        else d <= -m ? (u = Math.max(0, -(-o * r + a)), d = u > 0 ? -r : Math.min(Math.max(-r, -l), r), f = -u * u + d * (d + 2 * l) + c) : d <= m ? (u = 0, d = Math.min(Math.max(-r, -l), r), f = d * (d + 2 * l) + c) : (u = Math.max(0, -(o * r + a)), d = u > 0 ? r : Math.min(Math.max(-r, -l), r), f = -u * u + d * (d + 2 * l) + c);
        else d = o > 0 ? -r : r, u = Math.max(0, -(o * d + a)), f = -u * u + d * (d + 2 * l) + c;
        return n && n.copy(this.direction).multiplyScalar(u).add(this.origin), i && i.copy(Jr).multiplyScalar(d).add(To), f;
    }
    intersectSphere(e, t) {
        jt.subVectors(e.center, this.origin);
        let n = jt.dot(this.direction), i = jt.dot(jt) - n * n, r = e.radius * e.radius;
        if (i > r) return null;
        let o = Math.sqrt(r - i), a = n - o, l = n + o;
        return a < 0 && l < 0 ? null : a < 0 ? this.at(l, t) : this.at(a, t);
    }
    intersectsSphere(e) {
        return this.distanceSqToPoint(e.center) <= e.radius * e.radius;
    }
    distanceToPlane(e) {
        let t = e.normal.dot(this.direction);
        if (t === 0) return e.distanceToPoint(this.origin) === 0 ? 0 : null;
        let n = -(this.origin.dot(e.normal) + e.constant) / t;
        return n >= 0 ? n : null;
    }
    intersectPlane(e, t) {
        let n = this.distanceToPlane(e);
        return n === null ? null : this.at(n, t);
    }
    intersectsPlane(e) {
        let t = e.distanceToPoint(this.origin);
        return t === 0 || e.normal.dot(this.direction) * t < 0;
    }
    intersectBox(e, t) {
        let n, i, r, o, a, l, c = 1 / this.direction.x, h = 1 / this.direction.y, u = 1 / this.direction.z, d = this.origin;
        return c >= 0 ? (n = (e.min.x - d.x) * c, i = (e.max.x - d.x) * c) : (n = (e.max.x - d.x) * c, i = (e.min.x - d.x) * c), h >= 0 ? (r = (e.min.y - d.y) * h, o = (e.max.y - d.y) * h) : (r = (e.max.y - d.y) * h, o = (e.min.y - d.y) * h), n > o || r > i || ((r > n || n !== n) && (n = r), (o < i || i !== i) && (i = o), u >= 0 ? (a = (e.min.z - d.z) * u, l = (e.max.z - d.z) * u) : (a = (e.max.z - d.z) * u, l = (e.min.z - d.z) * u), n > l || a > i) || ((a > n || n !== n) && (n = a), (l < i || i !== i) && (i = l), i < 0) ? null : this.at(n >= 0 ? n : i, t);
    }
    intersectsBox(e) {
        return this.intersectBox(e, jt) !== null;
    }
    intersectTriangle(e, t, n, i, r) {
        Eo.subVectors(t, e), Yr.subVectors(n, e), Ao.crossVectors(Eo, Yr);
        let o = this.direction.dot(Ao), a;
        if (o > 0) {
            if (i) return null;
            a = 1;
        } else if (o < 0) a = -1, o = -o;
        else return null;
        fn.subVectors(this.origin, e);
        let l = a * this.direction.dot(Yr.crossVectors(fn, Yr));
        if (l < 0) return null;
        let c = a * this.direction.dot(Eo.cross(fn));
        if (c < 0 || l + c > o) return null;
        let h = -a * fn.dot(Ao);
        return h < 0 ? null : this.at(h / o, r);
    }
    applyMatrix4(e) {
        return this.origin.applyMatrix4(e), this.direction.transformDirection(e), this;
    }
    equals(e) {
        return e.origin.equals(this.origin) && e.direction.equals(this.direction);
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, pe = class {
    constructor(){
        this.elements = [
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1
        ], arguments.length > 0 && console.error("THREE.Matrix4: the constructor no longer reads arguments. use .set() instead.");
    }
    set(e, t, n, i, r, o, a, l, c, h, u, d, f, m, x, v) {
        let g = this.elements;
        return g[0] = e, g[4] = t, g[8] = n, g[12] = i, g[1] = r, g[5] = o, g[9] = a, g[13] = l, g[2] = c, g[6] = h, g[10] = u, g[14] = d, g[3] = f, g[7] = m, g[11] = x, g[15] = v, this;
    }
    identity() {
        return this.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), this;
    }
    clone() {
        return new pe().fromArray(this.elements);
    }
    copy(e) {
        let t = this.elements, n = e.elements;
        return t[0] = n[0], t[1] = n[1], t[2] = n[2], t[3] = n[3], t[4] = n[4], t[5] = n[5], t[6] = n[6], t[7] = n[7], t[8] = n[8], t[9] = n[9], t[10] = n[10], t[11] = n[11], t[12] = n[12], t[13] = n[13], t[14] = n[14], t[15] = n[15], this;
    }
    copyPosition(e) {
        let t = this.elements, n = e.elements;
        return t[12] = n[12], t[13] = n[13], t[14] = n[14], this;
    }
    setFromMatrix3(e) {
        let t = e.elements;
        return this.set(t[0], t[3], t[6], 0, t[1], t[4], t[7], 0, t[2], t[5], t[8], 0, 0, 0, 0, 1), this;
    }
    extractBasis(e, t, n) {
        return e.setFromMatrixColumn(this, 0), t.setFromMatrixColumn(this, 1), n.setFromMatrixColumn(this, 2), this;
    }
    makeBasis(e, t, n) {
        return this.set(e.x, t.x, n.x, 0, e.y, t.y, n.y, 0, e.z, t.z, n.z, 0, 0, 0, 0, 1), this;
    }
    extractRotation(e) {
        let t = this.elements, n = e.elements, i = 1 / si.setFromMatrixColumn(e, 0).length(), r = 1 / si.setFromMatrixColumn(e, 1).length(), o = 1 / si.setFromMatrixColumn(e, 2).length();
        return t[0] = n[0] * i, t[1] = n[1] * i, t[2] = n[2] * i, t[3] = 0, t[4] = n[4] * r, t[5] = n[5] * r, t[6] = n[6] * r, t[7] = 0, t[8] = n[8] * o, t[9] = n[9] * o, t[10] = n[10] * o, t[11] = 0, t[12] = 0, t[13] = 0, t[14] = 0, t[15] = 1, this;
    }
    makeRotationFromEuler(e) {
        e && e.isEuler || console.error("THREE.Matrix4: .makeRotationFromEuler() now expects a Euler rotation rather than a Vector3 and order.");
        let t = this.elements, n = e.x, i = e.y, r = e.z, o = Math.cos(n), a = Math.sin(n), l = Math.cos(i), c = Math.sin(i), h = Math.cos(r), u = Math.sin(r);
        if (e.order === "XYZ") {
            let d = o * h, f = o * u, m = a * h, x = a * u;
            t[0] = l * h, t[4] = -l * u, t[8] = c, t[1] = f + m * c, t[5] = d - x * c, t[9] = -a * l, t[2] = x - d * c, t[6] = m + f * c, t[10] = o * l;
        } else if (e.order === "YXZ") {
            let d1 = l * h, f1 = l * u, m1 = c * h, x1 = c * u;
            t[0] = d1 + x1 * a, t[4] = m1 * a - f1, t[8] = o * c, t[1] = o * u, t[5] = o * h, t[9] = -a, t[2] = f1 * a - m1, t[6] = x1 + d1 * a, t[10] = o * l;
        } else if (e.order === "ZXY") {
            let d2 = l * h, f2 = l * u, m2 = c * h, x2 = c * u;
            t[0] = d2 - x2 * a, t[4] = -o * u, t[8] = m2 + f2 * a, t[1] = f2 + m2 * a, t[5] = o * h, t[9] = x2 - d2 * a, t[2] = -o * c, t[6] = a, t[10] = o * l;
        } else if (e.order === "ZYX") {
            let d3 = o * h, f3 = o * u, m3 = a * h, x3 = a * u;
            t[0] = l * h, t[4] = m3 * c - f3, t[8] = d3 * c + x3, t[1] = l * u, t[5] = x3 * c + d3, t[9] = f3 * c - m3, t[2] = -c, t[6] = a * l, t[10] = o * l;
        } else if (e.order === "YZX") {
            let d4 = o * l, f4 = o * c, m4 = a * l, x4 = a * c;
            t[0] = l * h, t[4] = x4 - d4 * u, t[8] = m4 * u + f4, t[1] = u, t[5] = o * h, t[9] = -a * h, t[2] = -c * h, t[6] = f4 * u + m4, t[10] = d4 - x4 * u;
        } else if (e.order === "XZY") {
            let d5 = o * l, f5 = o * c, m5 = a * l, x5 = a * c;
            t[0] = l * h, t[4] = -u, t[8] = c * h, t[1] = d5 * u + x5, t[5] = o * h, t[9] = f5 * u - m5, t[2] = m5 * u - f5, t[6] = a * h, t[10] = x5 * u + d5;
        }
        return t[3] = 0, t[7] = 0, t[11] = 0, t[12] = 0, t[13] = 0, t[14] = 0, t[15] = 1, this;
    }
    makeRotationFromQuaternion(e) {
        return this.compose(tf, e, nf);
    }
    lookAt(e, t, n) {
        let i = this.elements;
        return St.subVectors(e, t), St.lengthSq() === 0 && (St.z = 1), St.normalize(), pn.crossVectors(n, St), pn.lengthSq() === 0 && (Math.abs(n.z) === 1 ? St.x += 1e-4 : St.z += 1e-4, St.normalize(), pn.crossVectors(n, St)), pn.normalize(), Zr.crossVectors(St, pn), i[0] = pn.x, i[4] = Zr.x, i[8] = St.x, i[1] = pn.y, i[5] = Zr.y, i[9] = St.y, i[2] = pn.z, i[6] = Zr.z, i[10] = St.z, this;
    }
    multiply(e, t) {
        return t !== void 0 ? (console.warn("THREE.Matrix4: .multiply() now only accepts one argument. Use .multiplyMatrices( a, b ) instead."), this.multiplyMatrices(e, t)) : this.multiplyMatrices(this, e);
    }
    premultiply(e) {
        return this.multiplyMatrices(e, this);
    }
    multiplyMatrices(e, t) {
        let n = e.elements, i = t.elements, r = this.elements, o = n[0], a = n[4], l = n[8], c = n[12], h = n[1], u = n[5], d = n[9], f = n[13], m = n[2], x = n[6], v = n[10], g = n[14], p = n[3], _ = n[7], y = n[11], b = n[15], A = i[0], L = i[4], I = i[8], k = i[12], B = i[1], P = i[5], w = i[9], E = i[13], D = i[2], U = i[6], F = i[10], O = i[14], ne = i[3], ce = i[7], V = i[11], W = i[15];
        return r[0] = o * A + a * B + l * D + c * ne, r[4] = o * L + a * P + l * U + c * ce, r[8] = o * I + a * w + l * F + c * V, r[12] = o * k + a * E + l * O + c * W, r[1] = h * A + u * B + d * D + f * ne, r[5] = h * L + u * P + d * U + f * ce, r[9] = h * I + u * w + d * F + f * V, r[13] = h * k + u * E + d * O + f * W, r[2] = m * A + x * B + v * D + g * ne, r[6] = m * L + x * P + v * U + g * ce, r[10] = m * I + x * w + v * F + g * V, r[14] = m * k + x * E + v * O + g * W, r[3] = p * A + _ * B + y * D + b * ne, r[7] = p * L + _ * P + y * U + b * ce, r[11] = p * I + _ * w + y * F + b * V, r[15] = p * k + _ * E + y * O + b * W, this;
    }
    multiplyScalar(e) {
        let t = this.elements;
        return t[0] *= e, t[4] *= e, t[8] *= e, t[12] *= e, t[1] *= e, t[5] *= e, t[9] *= e, t[13] *= e, t[2] *= e, t[6] *= e, t[10] *= e, t[14] *= e, t[3] *= e, t[7] *= e, t[11] *= e, t[15] *= e, this;
    }
    determinant() {
        let e = this.elements, t = e[0], n = e[4], i = e[8], r = e[12], o = e[1], a = e[5], l = e[9], c = e[13], h = e[2], u = e[6], d = e[10], f = e[14], m = e[3], x = e[7], v = e[11], g = e[15];
        return m * (+r * l * u - i * c * u - r * a * d + n * c * d + i * a * f - n * l * f) + x * (+t * l * f - t * c * d + r * o * d - i * o * f + i * c * h - r * l * h) + v * (+t * c * u - t * a * f - r * o * u + n * o * f + r * a * h - n * c * h) + g * (-i * a * h - t * l * u + t * a * d + i * o * u - n * o * d + n * l * h);
    }
    transpose() {
        let e = this.elements, t;
        return t = e[1], e[1] = e[4], e[4] = t, t = e[2], e[2] = e[8], e[8] = t, t = e[6], e[6] = e[9], e[9] = t, t = e[3], e[3] = e[12], e[12] = t, t = e[7], e[7] = e[13], e[13] = t, t = e[11], e[11] = e[14], e[14] = t, this;
    }
    setPosition(e, t, n) {
        let i = this.elements;
        return e.isVector3 ? (i[12] = e.x, i[13] = e.y, i[14] = e.z) : (i[12] = e, i[13] = t, i[14] = n), this;
    }
    invert() {
        let e = this.elements, t = e[0], n = e[1], i = e[2], r = e[3], o = e[4], a = e[5], l = e[6], c = e[7], h = e[8], u = e[9], d = e[10], f = e[11], m = e[12], x = e[13], v = e[14], g = e[15], p = u * v * c - x * d * c + x * l * f - a * v * f - u * l * g + a * d * g, _ = m * d * c - h * v * c - m * l * f + o * v * f + h * l * g - o * d * g, y = h * x * c - m * u * c + m * a * f - o * x * f - h * a * g + o * u * g, b = m * u * l - h * x * l - m * a * d + o * x * d + h * a * v - o * u * v, A = t * p + n * _ + i * y + r * b;
        if (A === 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        let L = 1 / A;
        return e[0] = p * L, e[1] = (x * d * r - u * v * r - x * i * f + n * v * f + u * i * g - n * d * g) * L, e[2] = (a * v * r - x * l * r + x * i * c - n * v * c - a * i * g + n * l * g) * L, e[3] = (u * l * r - a * d * r - u * i * c + n * d * c + a * i * f - n * l * f) * L, e[4] = _ * L, e[5] = (h * v * r - m * d * r + m * i * f - t * v * f - h * i * g + t * d * g) * L, e[6] = (m * l * r - o * v * r - m * i * c + t * v * c + o * i * g - t * l * g) * L, e[7] = (o * d * r - h * l * r + h * i * c - t * d * c - o * i * f + t * l * f) * L, e[8] = y * L, e[9] = (m * u * r - h * x * r - m * n * f + t * x * f + h * n * g - t * u * g) * L, e[10] = (o * x * r - m * a * r + m * n * c - t * x * c - o * n * g + t * a * g) * L, e[11] = (h * a * r - o * u * r - h * n * c + t * u * c + o * n * f - t * a * f) * L, e[12] = b * L, e[13] = (h * x * i - m * u * i + m * n * d - t * x * d - h * n * v + t * u * v) * L, e[14] = (m * a * i - o * x * i - m * n * l + t * x * l + o * n * v - t * a * v) * L, e[15] = (o * u * i - h * a * i + h * n * l - t * u * l - o * n * d + t * a * d) * L, this;
    }
    scale(e) {
        let t = this.elements, n = e.x, i = e.y, r = e.z;
        return t[0] *= n, t[4] *= i, t[8] *= r, t[1] *= n, t[5] *= i, t[9] *= r, t[2] *= n, t[6] *= i, t[10] *= r, t[3] *= n, t[7] *= i, t[11] *= r, this;
    }
    getMaxScaleOnAxis() {
        let e = this.elements, t = e[0] * e[0] + e[1] * e[1] + e[2] * e[2], n = e[4] * e[4] + e[5] * e[5] + e[6] * e[6], i = e[8] * e[8] + e[9] * e[9] + e[10] * e[10];
        return Math.sqrt(Math.max(t, n, i));
    }
    makeTranslation(e, t, n) {
        return this.set(1, 0, 0, e, 0, 1, 0, t, 0, 0, 1, n, 0, 0, 0, 1), this;
    }
    makeRotationX(e) {
        let t = Math.cos(e), n = Math.sin(e);
        return this.set(1, 0, 0, 0, 0, t, -n, 0, 0, n, t, 0, 0, 0, 0, 1), this;
    }
    makeRotationY(e) {
        let t = Math.cos(e), n = Math.sin(e);
        return this.set(t, 0, n, 0, 0, 1, 0, 0, -n, 0, t, 0, 0, 0, 0, 1), this;
    }
    makeRotationZ(e) {
        let t = Math.cos(e), n = Math.sin(e);
        return this.set(t, -n, 0, 0, n, t, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), this;
    }
    makeRotationAxis(e, t) {
        let n = Math.cos(t), i = Math.sin(t), r = 1 - n, o = e.x, a = e.y, l = e.z, c = r * o, h = r * a;
        return this.set(c * o + n, c * a - i * l, c * l + i * a, 0, c * a + i * l, h * a + n, h * l - i * o, 0, c * l - i * a, h * l + i * o, r * l * l + n, 0, 0, 0, 0, 1), this;
    }
    makeScale(e, t, n) {
        return this.set(e, 0, 0, 0, 0, t, 0, 0, 0, 0, n, 0, 0, 0, 0, 1), this;
    }
    makeShear(e, t, n, i, r, o) {
        return this.set(1, n, r, 0, e, 1, o, 0, t, i, 1, 0, 0, 0, 0, 1), this;
    }
    compose(e, t, n) {
        let i = this.elements, r = t._x, o = t._y, a = t._z, l = t._w, c = r + r, h = o + o, u = a + a, d = r * c, f = r * h, m = r * u, x = o * h, v = o * u, g = a * u, p = l * c, _ = l * h, y = l * u, b = n.x, A = n.y, L = n.z;
        return i[0] = (1 - (x + g)) * b, i[1] = (f + y) * b, i[2] = (m - _) * b, i[3] = 0, i[4] = (f - y) * A, i[5] = (1 - (d + g)) * A, i[6] = (v + p) * A, i[7] = 0, i[8] = (m + _) * L, i[9] = (v - p) * L, i[10] = (1 - (d + x)) * L, i[11] = 0, i[12] = e.x, i[13] = e.y, i[14] = e.z, i[15] = 1, this;
    }
    decompose(e, t, n) {
        let i = this.elements, r = si.set(i[0], i[1], i[2]).length(), o = si.set(i[4], i[5], i[6]).length(), a = si.set(i[8], i[9], i[10]).length();
        this.determinant() < 0 && (r = -r), e.x = i[12], e.y = i[13], e.z = i[14], It.copy(this);
        let c = 1 / r, h = 1 / o, u = 1 / a;
        return It.elements[0] *= c, It.elements[1] *= c, It.elements[2] *= c, It.elements[4] *= h, It.elements[5] *= h, It.elements[6] *= h, It.elements[8] *= u, It.elements[9] *= u, It.elements[10] *= u, t.setFromRotationMatrix(It), n.x = r, n.y = o, n.z = a, this;
    }
    makePerspective(e, t, n, i, r, o) {
        o === void 0 && console.warn("THREE.Matrix4: .makePerspective() has been redefined and has a new signature. Please check the docs.");
        let a = this.elements, l = 2 * r / (t - e), c = 2 * r / (n - i), h = (t + e) / (t - e), u = (n + i) / (n - i), d = -(o + r) / (o - r), f = -2 * o * r / (o - r);
        return a[0] = l, a[4] = 0, a[8] = h, a[12] = 0, a[1] = 0, a[5] = c, a[9] = u, a[13] = 0, a[2] = 0, a[6] = 0, a[10] = d, a[14] = f, a[3] = 0, a[7] = 0, a[11] = -1, a[15] = 0, this;
    }
    makeOrthographic(e, t, n, i, r, o) {
        let a = this.elements, l = 1 / (t - e), c = 1 / (n - i), h = 1 / (o - r), u = (t + e) * l, d = (n + i) * c, f = (o + r) * h;
        return a[0] = 2 * l, a[4] = 0, a[8] = 0, a[12] = -u, a[1] = 0, a[5] = 2 * c, a[9] = 0, a[13] = -d, a[2] = 0, a[6] = 0, a[10] = -2 * h, a[14] = -f, a[3] = 0, a[7] = 0, a[11] = 0, a[15] = 1, this;
    }
    equals(e) {
        let t = this.elements, n = e.elements;
        for(let i = 0; i < 16; i++)if (t[i] !== n[i]) return !1;
        return !0;
    }
    fromArray(e, t = 0) {
        for(let n = 0; n < 16; n++)this.elements[n] = e[n + t];
        return this;
    }
    toArray(e = [], t = 0) {
        let n = this.elements;
        return e[t] = n[0], e[t + 1] = n[1], e[t + 2] = n[2], e[t + 3] = n[3], e[t + 4] = n[4], e[t + 5] = n[5], e[t + 6] = n[6], e[t + 7] = n[7], e[t + 8] = n[8], e[t + 9] = n[9], e[t + 10] = n[10], e[t + 11] = n[11], e[t + 12] = n[12], e[t + 13] = n[13], e[t + 14] = n[14], e[t + 15] = n[15], e;
    }
};
pe.prototype.isMatrix4 = !0;
var si = new M, It = new pe, tf = new M(0, 0, 0), nf = new M(1, 1, 1), pn = new M, Zr = new M, St = new M, _l = new pe, Ml = new gt, Zn = class {
    constructor(e = 0, t = 0, n = 0, i = Zn.DefaultOrder){
        this._x = e, this._y = t, this._z = n, this._order = i;
    }
    get x() {
        return this._x;
    }
    set x(e) {
        this._x = e, this._onChangeCallback();
    }
    get y() {
        return this._y;
    }
    set y(e) {
        this._y = e, this._onChangeCallback();
    }
    get z() {
        return this._z;
    }
    set z(e) {
        this._z = e, this._onChangeCallback();
    }
    get order() {
        return this._order;
    }
    set order(e) {
        this._order = e, this._onChangeCallback();
    }
    set(e, t, n, i = this._order) {
        return this._x = e, this._y = t, this._z = n, this._order = i, this._onChangeCallback(), this;
    }
    clone() {
        return new this.constructor(this._x, this._y, this._z, this._order);
    }
    copy(e) {
        return this._x = e._x, this._y = e._y, this._z = e._z, this._order = e._order, this._onChangeCallback(), this;
    }
    setFromRotationMatrix(e, t = this._order, n = !0) {
        let i = e.elements, r = i[0], o = i[4], a = i[8], l = i[1], c = i[5], h = i[9], u = i[2], d = i[6], f = i[10];
        switch(t){
            case "XYZ":
                this._y = Math.asin(mt(a, -1, 1)), Math.abs(a) < .9999999 ? (this._x = Math.atan2(-h, f), this._z = Math.atan2(-o, r)) : (this._x = Math.atan2(d, c), this._z = 0);
                break;
            case "YXZ":
                this._x = Math.asin(-mt(h, -1, 1)), Math.abs(h) < .9999999 ? (this._y = Math.atan2(a, f), this._z = Math.atan2(l, c)) : (this._y = Math.atan2(-u, r), this._z = 0);
                break;
            case "ZXY":
                this._x = Math.asin(mt(d, -1, 1)), Math.abs(d) < .9999999 ? (this._y = Math.atan2(-u, f), this._z = Math.atan2(-o, c)) : (this._y = 0, this._z = Math.atan2(l, r));
                break;
            case "ZYX":
                this._y = Math.asin(-mt(u, -1, 1)), Math.abs(u) < .9999999 ? (this._x = Math.atan2(d, f), this._z = Math.atan2(l, r)) : (this._x = 0, this._z = Math.atan2(-o, c));
                break;
            case "YZX":
                this._z = Math.asin(mt(l, -1, 1)), Math.abs(l) < .9999999 ? (this._x = Math.atan2(-h, c), this._y = Math.atan2(-u, r)) : (this._x = 0, this._y = Math.atan2(a, f));
                break;
            case "XZY":
                this._z = Math.asin(-mt(o, -1, 1)), Math.abs(o) < .9999999 ? (this._x = Math.atan2(d, c), this._y = Math.atan2(a, r)) : (this._x = Math.atan2(-h, f), this._y = 0);
                break;
            default:
                console.warn("THREE.Euler: .setFromRotationMatrix() encountered an unknown order: " + t);
        }
        return this._order = t, n === !0 && this._onChangeCallback(), this;
    }
    setFromQuaternion(e, t, n) {
        return _l.makeRotationFromQuaternion(e), this.setFromRotationMatrix(_l, t, n);
    }
    setFromVector3(e, t = this._order) {
        return this.set(e.x, e.y, e.z, t);
    }
    reorder(e) {
        return Ml.setFromEuler(this), this.setFromQuaternion(Ml, e);
    }
    equals(e) {
        return e._x === this._x && e._y === this._y && e._z === this._z && e._order === this._order;
    }
    fromArray(e) {
        return this._x = e[0], this._y = e[1], this._z = e[2], e[3] !== void 0 && (this._order = e[3]), this._onChangeCallback(), this;
    }
    toArray(e = [], t = 0) {
        return e[t] = this._x, e[t + 1] = this._y, e[t + 2] = this._z, e[t + 3] = this._order, e;
    }
    toVector3(e) {
        return e ? e.set(this._x, this._y, this._z) : new M(this._x, this._y, this._z);
    }
    _onChange(e) {
        return this._onChangeCallback = e, this;
    }
    _onChangeCallback() {}
};
Zn.prototype.isEuler = !0;
Zn.DefaultOrder = "XYZ";
Zn.RotationOrders = [
    "XYZ",
    "YZX",
    "ZXY",
    "XZY",
    "YXZ",
    "ZYX"
];
var Js = class {
    constructor(){
        this.mask = 1;
    }
    set(e) {
        this.mask = (1 << e | 0) >>> 0;
    }
    enable(e) {
        this.mask |= 1 << e | 0;
    }
    enableAll() {
        this.mask = -1;
    }
    toggle(e) {
        this.mask ^= 1 << e | 0;
    }
    disable(e) {
        this.mask &= ~(1 << e | 0);
    }
    disableAll() {
        this.mask = 0;
    }
    test(e) {
        return (this.mask & e.mask) !== 0;
    }
    isEnabled(e) {
        return (this.mask & (1 << e | 0)) !== 0;
    }
}, rf = 0, bl = new M, oi = new gt, Qt = new pe, $r = new M, Zi = new M, sf = new M, of = new gt, wl = new M(1, 0, 0), Sl = new M(0, 1, 0), Tl = new M(0, 0, 1), af = {
    type: "added"
}, El = {
    type: "removed"
}, Ne = class extends En {
    constructor(){
        super();
        Object.defineProperty(this, "id", {
            value: rf++
        }), this.uuid = Et(), this.name = "", this.type = "Object3D", this.parent = null, this.children = [], this.up = Ne.DefaultUp.clone();
        let e = new M, t = new Zn, n = new gt, i = new M(1, 1, 1);
        function r() {
            n.setFromEuler(t, !1);
        }
        function o() {
            t.setFromQuaternion(n, void 0, !1);
        }
        t._onChange(r), n._onChange(o), Object.defineProperties(this, {
            position: {
                configurable: !0,
                enumerable: !0,
                value: e
            },
            rotation: {
                configurable: !0,
                enumerable: !0,
                value: t
            },
            quaternion: {
                configurable: !0,
                enumerable: !0,
                value: n
            },
            scale: {
                configurable: !0,
                enumerable: !0,
                value: i
            },
            modelViewMatrix: {
                value: new pe
            },
            normalMatrix: {
                value: new lt
            }
        }), this.matrix = new pe, this.matrixWorld = new pe, this.matrixAutoUpdate = Ne.DefaultMatrixAutoUpdate, this.matrixWorldNeedsUpdate = !1, this.layers = new Js, this.visible = !0, this.castShadow = !1, this.receiveShadow = !1, this.frustumCulled = !0, this.renderOrder = 0, this.animations = [], this.userData = {};
    }
    onBeforeRender() {}
    onAfterRender() {}
    applyMatrix4(e) {
        this.matrixAutoUpdate && this.updateMatrix(), this.matrix.premultiply(e), this.matrix.decompose(this.position, this.quaternion, this.scale);
    }
    applyQuaternion(e) {
        return this.quaternion.premultiply(e), this;
    }
    setRotationFromAxisAngle(e, t) {
        this.quaternion.setFromAxisAngle(e, t);
    }
    setRotationFromEuler(e) {
        this.quaternion.setFromEuler(e, !0);
    }
    setRotationFromMatrix(e) {
        this.quaternion.setFromRotationMatrix(e);
    }
    setRotationFromQuaternion(e) {
        this.quaternion.copy(e);
    }
    rotateOnAxis(e, t) {
        return oi.setFromAxisAngle(e, t), this.quaternion.multiply(oi), this;
    }
    rotateOnWorldAxis(e, t) {
        return oi.setFromAxisAngle(e, t), this.quaternion.premultiply(oi), this;
    }
    rotateX(e) {
        return this.rotateOnAxis(wl, e);
    }
    rotateY(e) {
        return this.rotateOnAxis(Sl, e);
    }
    rotateZ(e) {
        return this.rotateOnAxis(Tl, e);
    }
    translateOnAxis(e, t) {
        return bl.copy(e).applyQuaternion(this.quaternion), this.position.add(bl.multiplyScalar(t)), this;
    }
    translateX(e) {
        return this.translateOnAxis(wl, e);
    }
    translateY(e) {
        return this.translateOnAxis(Sl, e);
    }
    translateZ(e) {
        return this.translateOnAxis(Tl, e);
    }
    localToWorld(e) {
        return e.applyMatrix4(this.matrixWorld);
    }
    worldToLocal(e) {
        return e.applyMatrix4(Qt.copy(this.matrixWorld).invert());
    }
    lookAt(e, t, n) {
        e.isVector3 ? $r.copy(e) : $r.set(e, t, n);
        let i = this.parent;
        this.updateWorldMatrix(!0, !1), Zi.setFromMatrixPosition(this.matrixWorld), this.isCamera || this.isLight ? Qt.lookAt(Zi, $r, this.up) : Qt.lookAt($r, Zi, this.up), this.quaternion.setFromRotationMatrix(Qt), i && (Qt.extractRotation(i.matrixWorld), oi.setFromRotationMatrix(Qt), this.quaternion.premultiply(oi.invert()));
    }
    add(e) {
        if (arguments.length > 1) {
            for(let t = 0; t < arguments.length; t++)this.add(arguments[t]);
            return this;
        }
        return e === this ? (console.error("THREE.Object3D.add: object can't be added as a child of itself.", e), this) : (e && e.isObject3D ? (e.parent !== null && e.parent.remove(e), e.parent = this, this.children.push(e), e.dispatchEvent(af)) : console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.", e), this);
    }
    remove(e) {
        if (arguments.length > 1) {
            for(let n = 0; n < arguments.length; n++)this.remove(arguments[n]);
            return this;
        }
        let t = this.children.indexOf(e);
        return t !== -1 && (e.parent = null, this.children.splice(t, 1), e.dispatchEvent(El)), this;
    }
    removeFromParent() {
        let e = this.parent;
        return e !== null && e.remove(this), this;
    }
    clear() {
        for(let e = 0; e < this.children.length; e++){
            let t = this.children[e];
            t.parent = null, t.dispatchEvent(El);
        }
        return this.children.length = 0, this;
    }
    attach(e) {
        return this.updateWorldMatrix(!0, !1), Qt.copy(this.matrixWorld).invert(), e.parent !== null && (e.parent.updateWorldMatrix(!0, !1), Qt.multiply(e.parent.matrixWorld)), e.applyMatrix4(Qt), this.add(e), e.updateWorldMatrix(!1, !0), this;
    }
    getObjectById(e) {
        return this.getObjectByProperty("id", e);
    }
    getObjectByName(e) {
        return this.getObjectByProperty("name", e);
    }
    getObjectByProperty(e, t) {
        if (this[e] === t) return this;
        for(let n = 0, i = this.children.length; n < i; n++){
            let o = this.children[n].getObjectByProperty(e, t);
            if (o !== void 0) return o;
        }
    }
    getWorldPosition(e) {
        return this.updateWorldMatrix(!0, !1), e.setFromMatrixPosition(this.matrixWorld);
    }
    getWorldQuaternion(e) {
        return this.updateWorldMatrix(!0, !1), this.matrixWorld.decompose(Zi, e, sf), e;
    }
    getWorldScale(e) {
        return this.updateWorldMatrix(!0, !1), this.matrixWorld.decompose(Zi, of, e), e;
    }
    getWorldDirection(e) {
        this.updateWorldMatrix(!0, !1);
        let t = this.matrixWorld.elements;
        return e.set(t[8], t[9], t[10]).normalize();
    }
    raycast() {}
    traverse(e) {
        e(this);
        let t = this.children;
        for(let n = 0, i = t.length; n < i; n++)t[n].traverse(e);
    }
    traverseVisible(e) {
        if (this.visible === !1) return;
        e(this);
        let t = this.children;
        for(let n = 0, i = t.length; n < i; n++)t[n].traverseVisible(e);
    }
    traverseAncestors(e) {
        let t = this.parent;
        t !== null && (e(t), t.traverseAncestors(e));
    }
    updateMatrix() {
        this.matrix.compose(this.position, this.quaternion, this.scale), this.matrixWorldNeedsUpdate = !0;
    }
    updateMatrixWorld(e) {
        this.matrixAutoUpdate && this.updateMatrix(), (this.matrixWorldNeedsUpdate || e) && (this.parent === null ? this.matrixWorld.copy(this.matrix) : this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix), this.matrixWorldNeedsUpdate = !1, e = !0);
        let t = this.children;
        for(let n = 0, i = t.length; n < i; n++)t[n].updateMatrixWorld(e);
    }
    updateWorldMatrix(e, t) {
        let n = this.parent;
        if (e === !0 && n !== null && n.updateWorldMatrix(!0, !1), this.matrixAutoUpdate && this.updateMatrix(), this.parent === null ? this.matrixWorld.copy(this.matrix) : this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix), t === !0) {
            let i = this.children;
            for(let r = 0, o = i.length; r < o; r++)i[r].updateWorldMatrix(!1, !0);
        }
    }
    toJSON(e) {
        let t = e === void 0 || typeof e == "string", n = {};
        t && (e = {
            geometries: {},
            materials: {},
            textures: {},
            images: {},
            shapes: {},
            skeletons: {},
            animations: {}
        }, n.metadata = {
            version: 4.5,
            type: "Object",
            generator: "Object3D.toJSON"
        });
        let i = {};
        i.uuid = this.uuid, i.type = this.type, this.name !== "" && (i.name = this.name), this.castShadow === !0 && (i.castShadow = !0), this.receiveShadow === !0 && (i.receiveShadow = !0), this.visible === !1 && (i.visible = !1), this.frustumCulled === !1 && (i.frustumCulled = !1), this.renderOrder !== 0 && (i.renderOrder = this.renderOrder), JSON.stringify(this.userData) !== "{}" && (i.userData = this.userData), i.layers = this.layers.mask, i.matrix = this.matrix.toArray(), this.matrixAutoUpdate === !1 && (i.matrixAutoUpdate = !1), this.isInstancedMesh && (i.type = "InstancedMesh", i.count = this.count, i.instanceMatrix = this.instanceMatrix.toJSON(), this.instanceColor !== null && (i.instanceColor = this.instanceColor.toJSON()));
        function r(a, l) {
            return a[l.uuid] === void 0 && (a[l.uuid] = l.toJSON(e)), l.uuid;
        }
        if (this.isScene) this.background && (this.background.isColor ? i.background = this.background.toJSON() : this.background.isTexture && (i.background = this.background.toJSON(e).uuid)), this.environment && this.environment.isTexture && (i.environment = this.environment.toJSON(e).uuid);
        else if (this.isMesh || this.isLine || this.isPoints) {
            i.geometry = r(e.geometries, this.geometry);
            let a = this.geometry.parameters;
            if (a !== void 0 && a.shapes !== void 0) {
                let l = a.shapes;
                if (Array.isArray(l)) for(let c = 0, h = l.length; c < h; c++){
                    let u = l[c];
                    r(e.shapes, u);
                }
                else r(e.shapes, l);
            }
        }
        if (this.isSkinnedMesh && (i.bindMode = this.bindMode, i.bindMatrix = this.bindMatrix.toArray(), this.skeleton !== void 0 && (r(e.skeletons, this.skeleton), i.skeleton = this.skeleton.uuid)), this.material !== void 0) if (Array.isArray(this.material)) {
            let a1 = [];
            for(let l1 = 0, c1 = this.material.length; l1 < c1; l1++)a1.push(r(e.materials, this.material[l1]));
            i.material = a1;
        } else i.material = r(e.materials, this.material);
        if (this.children.length > 0) {
            i.children = [];
            for(let a2 = 0; a2 < this.children.length; a2++)i.children.push(this.children[a2].toJSON(e).object);
        }
        if (this.animations.length > 0) {
            i.animations = [];
            for(let a3 = 0; a3 < this.animations.length; a3++){
                let l2 = this.animations[a3];
                i.animations.push(r(e.animations, l2));
            }
        }
        if (t) {
            let a4 = o(e.geometries), l3 = o(e.materials), c2 = o(e.textures), h1 = o(e.images), u1 = o(e.shapes), d = o(e.skeletons), f = o(e.animations);
            a4.length > 0 && (n.geometries = a4), l3.length > 0 && (n.materials = l3), c2.length > 0 && (n.textures = c2), h1.length > 0 && (n.images = h1), u1.length > 0 && (n.shapes = u1), d.length > 0 && (n.skeletons = d), f.length > 0 && (n.animations = f);
        }
        return n.object = i, n;
        function o(a) {
            let l = [];
            for(let c in a){
                let h = a[c];
                delete h.metadata, l.push(h);
            }
            return l;
        }
    }
    clone(e) {
        return new this.constructor().copy(this, e);
    }
    copy(e, t = !0) {
        if (this.name = e.name, this.up.copy(e.up), this.position.copy(e.position), this.rotation.order = e.rotation.order, this.quaternion.copy(e.quaternion), this.scale.copy(e.scale), this.matrix.copy(e.matrix), this.matrixWorld.copy(e.matrixWorld), this.matrixAutoUpdate = e.matrixAutoUpdate, this.matrixWorldNeedsUpdate = e.matrixWorldNeedsUpdate, this.layers.mask = e.layers.mask, this.visible = e.visible, this.castShadow = e.castShadow, this.receiveShadow = e.receiveShadow, this.frustumCulled = e.frustumCulled, this.renderOrder = e.renderOrder, this.userData = JSON.parse(JSON.stringify(e.userData)), t === !0) for(let n = 0; n < e.children.length; n++){
            let i = e.children[n];
            this.add(i.clone());
        }
        return this;
    }
};
Ne.DefaultUp = new M(0, 1, 0);
Ne.DefaultMatrixAutoUpdate = !0;
Ne.prototype.isObject3D = !0;
var Dt = new M, Kt = new M, Co = new M, en = new M, ai = new M, li = new M, Al = new M, Lo = new M, Ro = new M, Po = new M, nt = class {
    constructor(e = new M, t = new M, n = new M){
        this.a = e, this.b = t, this.c = n;
    }
    static getNormal(e, t, n, i) {
        i.subVectors(n, t), Dt.subVectors(e, t), i.cross(Dt);
        let r = i.lengthSq();
        return r > 0 ? i.multiplyScalar(1 / Math.sqrt(r)) : i.set(0, 0, 0);
    }
    static getBarycoord(e, t, n, i, r) {
        Dt.subVectors(i, t), Kt.subVectors(n, t), Co.subVectors(e, t);
        let o = Dt.dot(Dt), a = Dt.dot(Kt), l = Dt.dot(Co), c = Kt.dot(Kt), h = Kt.dot(Co), u = o * c - a * a;
        if (u === 0) return r.set(-2, -1, -1);
        let d = 1 / u, f = (c * l - a * h) * d, m = (o * h - a * l) * d;
        return r.set(1 - f - m, m, f);
    }
    static containsPoint(e, t, n, i) {
        return this.getBarycoord(e, t, n, i, en), en.x >= 0 && en.y >= 0 && en.x + en.y <= 1;
    }
    static getUV(e, t, n, i, r, o, a, l) {
        return this.getBarycoord(e, t, n, i, en), l.set(0, 0), l.addScaledVector(r, en.x), l.addScaledVector(o, en.y), l.addScaledVector(a, en.z), l;
    }
    static isFrontFacing(e, t, n, i) {
        return Dt.subVectors(n, t), Kt.subVectors(e, t), Dt.cross(Kt).dot(i) < 0;
    }
    set(e, t, n) {
        return this.a.copy(e), this.b.copy(t), this.c.copy(n), this;
    }
    setFromPointsAndIndices(e, t, n, i) {
        return this.a.copy(e[t]), this.b.copy(e[n]), this.c.copy(e[i]), this;
    }
    setFromAttributeAndIndices(e, t, n, i) {
        return this.a.fromBufferAttribute(e, t), this.b.fromBufferAttribute(e, n), this.c.fromBufferAttribute(e, i), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.a.copy(e.a), this.b.copy(e.b), this.c.copy(e.c), this;
    }
    getArea() {
        return Dt.subVectors(this.c, this.b), Kt.subVectors(this.a, this.b), Dt.cross(Kt).length() * .5;
    }
    getMidpoint(e) {
        return e.addVectors(this.a, this.b).add(this.c).multiplyScalar(1 / 3);
    }
    getNormal(e) {
        return nt.getNormal(this.a, this.b, this.c, e);
    }
    getPlane(e) {
        return e.setFromCoplanarPoints(this.a, this.b, this.c);
    }
    getBarycoord(e, t) {
        return nt.getBarycoord(e, this.a, this.b, this.c, t);
    }
    getUV(e, t, n, i, r) {
        return nt.getUV(e, this.a, this.b, this.c, t, n, i, r);
    }
    containsPoint(e) {
        return nt.containsPoint(e, this.a, this.b, this.c);
    }
    isFrontFacing(e) {
        return nt.isFrontFacing(this.a, this.b, this.c, e);
    }
    intersectsBox(e) {
        return e.intersectsTriangle(this);
    }
    closestPointToPoint(e, t) {
        let n = this.a, i = this.b, r = this.c, o, a;
        ai.subVectors(i, n), li.subVectors(r, n), Lo.subVectors(e, n);
        let l = ai.dot(Lo), c = li.dot(Lo);
        if (l <= 0 && c <= 0) return t.copy(n);
        Ro.subVectors(e, i);
        let h = ai.dot(Ro), u = li.dot(Ro);
        if (h >= 0 && u <= h) return t.copy(i);
        let d = l * u - h * c;
        if (d <= 0 && l >= 0 && h <= 0) return o = l / (l - h), t.copy(n).addScaledVector(ai, o);
        Po.subVectors(e, r);
        let f = ai.dot(Po), m = li.dot(Po);
        if (m >= 0 && f <= m) return t.copy(r);
        let x = f * c - l * m;
        if (x <= 0 && c >= 0 && m <= 0) return a = c / (c - m), t.copy(n).addScaledVector(li, a);
        let v = h * m - f * u;
        if (v <= 0 && u - h >= 0 && f - m >= 0) return Al.subVectors(r, i), a = (u - h) / (u - h + (f - m)), t.copy(i).addScaledVector(Al, a);
        let g = 1 / (v + x + d);
        return o = x * g, a = d * g, t.copy(n).addScaledVector(ai, o).addScaledVector(li, a);
    }
    equals(e) {
        return e.a.equals(this.a) && e.b.equals(this.b) && e.c.equals(this.c);
    }
}, lf = 0, dt = class extends En {
    constructor(){
        super();
        Object.defineProperty(this, "id", {
            value: lf++
        }), this.uuid = Et(), this.name = "", this.type = "Material", this.fog = !0, this.blending = sr, this.side = Ai, this.vertexColors = !1, this.opacity = 1, this.format = ct, this.transparent = !1, this.blendSrc = Gc, this.blendDst = Vc, this.blendEquation = _i, this.blendSrcAlpha = null, this.blendDstAlpha = null, this.blendEquationAlpha = null, this.depthFunc = ea, this.depthTest = !0, this.depthWrite = !0, this.stencilWriteMask = 255, this.stencilFunc = Ud, this.stencilRef = 0, this.stencilFuncMask = 255, this.stencilFail = vo, this.stencilZFail = vo, this.stencilZPass = vo, this.stencilWrite = !1, this.clippingPlanes = null, this.clipIntersection = !1, this.clipShadows = !1, this.shadowSide = null, this.colorWrite = !0, this.precision = null, this.polygonOffset = !1, this.polygonOffsetFactor = 0, this.polygonOffsetUnits = 0, this.dithering = !1, this.alphaToCoverage = !1, this.premultipliedAlpha = !1, this.visible = !0, this.toneMapped = !0, this.userData = {}, this.version = 0, this._alphaTest = 0;
    }
    get alphaTest() {
        return this._alphaTest;
    }
    set alphaTest(e) {
        this._alphaTest > 0 != e > 0 && this.version++, this._alphaTest = e;
    }
    onBuild() {}
    onBeforeRender() {}
    onBeforeCompile() {}
    customProgramCacheKey() {
        return this.onBeforeCompile.toString();
    }
    setValues(e) {
        if (e !== void 0) for(let t in e){
            let n = e[t];
            if (n === void 0) {
                console.warn("THREE.Material: '" + t + "' parameter is undefined.");
                continue;
            }
            if (t === "shading") {
                console.warn("THREE." + this.type + ": .shading has been removed. Use the boolean .flatShading instead."), this.flatShading = n === kc;
                continue;
            }
            let i = this[t];
            if (i === void 0) {
                console.warn("THREE." + this.type + ": '" + t + "' is not a property of this material.");
                continue;
            }
            i && i.isColor ? i.set(n) : i && i.isVector3 && n && n.isVector3 ? i.copy(n) : this[t] = n;
        }
    }
    toJSON(e) {
        let t = e === void 0 || typeof e == "string";
        t && (e = {
            textures: {},
            images: {}
        });
        let n = {
            metadata: {
                version: 4.5,
                type: "Material",
                generator: "Material.toJSON"
            }
        };
        n.uuid = this.uuid, n.type = this.type, this.name !== "" && (n.name = this.name), this.color && this.color.isColor && (n.color = this.color.getHex()), this.roughness !== void 0 && (n.roughness = this.roughness), this.metalness !== void 0 && (n.metalness = this.metalness), this.sheen !== void 0 && (n.sheen = this.sheen), this.sheenColor && this.sheenColor.isColor && (n.sheenColor = this.sheenColor.getHex()), this.sheenRoughness !== void 0 && (n.sheenRoughness = this.sheenRoughness), this.emissive && this.emissive.isColor && (n.emissive = this.emissive.getHex()), this.emissiveIntensity && this.emissiveIntensity !== 1 && (n.emissiveIntensity = this.emissiveIntensity), this.specular && this.specular.isColor && (n.specular = this.specular.getHex()), this.specularIntensity !== void 0 && (n.specularIntensity = this.specularIntensity), this.specularColor && this.specularColor.isColor && (n.specularColor = this.specularColor.getHex()), this.shininess !== void 0 && (n.shininess = this.shininess), this.clearcoat !== void 0 && (n.clearcoat = this.clearcoat), this.clearcoatRoughness !== void 0 && (n.clearcoatRoughness = this.clearcoatRoughness), this.clearcoatMap && this.clearcoatMap.isTexture && (n.clearcoatMap = this.clearcoatMap.toJSON(e).uuid), this.clearcoatRoughnessMap && this.clearcoatRoughnessMap.isTexture && (n.clearcoatRoughnessMap = this.clearcoatRoughnessMap.toJSON(e).uuid), this.clearcoatNormalMap && this.clearcoatNormalMap.isTexture && (n.clearcoatNormalMap = this.clearcoatNormalMap.toJSON(e).uuid, n.clearcoatNormalScale = this.clearcoatNormalScale.toArray()), this.map && this.map.isTexture && (n.map = this.map.toJSON(e).uuid), this.matcap && this.matcap.isTexture && (n.matcap = this.matcap.toJSON(e).uuid), this.alphaMap && this.alphaMap.isTexture && (n.alphaMap = this.alphaMap.toJSON(e).uuid), this.lightMap && this.lightMap.isTexture && (n.lightMap = this.lightMap.toJSON(e).uuid, n.lightMapIntensity = this.lightMapIntensity), this.aoMap && this.aoMap.isTexture && (n.aoMap = this.aoMap.toJSON(e).uuid, n.aoMapIntensity = this.aoMapIntensity), this.bumpMap && this.bumpMap.isTexture && (n.bumpMap = this.bumpMap.toJSON(e).uuid, n.bumpScale = this.bumpScale), this.normalMap && this.normalMap.isTexture && (n.normalMap = this.normalMap.toJSON(e).uuid, n.normalMapType = this.normalMapType, n.normalScale = this.normalScale.toArray()), this.displacementMap && this.displacementMap.isTexture && (n.displacementMap = this.displacementMap.toJSON(e).uuid, n.displacementScale = this.displacementScale, n.displacementBias = this.displacementBias), this.roughnessMap && this.roughnessMap.isTexture && (n.roughnessMap = this.roughnessMap.toJSON(e).uuid), this.metalnessMap && this.metalnessMap.isTexture && (n.metalnessMap = this.metalnessMap.toJSON(e).uuid), this.emissiveMap && this.emissiveMap.isTexture && (n.emissiveMap = this.emissiveMap.toJSON(e).uuid), this.specularMap && this.specularMap.isTexture && (n.specularMap = this.specularMap.toJSON(e).uuid), this.specularIntensityMap && this.specularIntensityMap.isTexture && (n.specularIntensityMap = this.specularIntensityMap.toJSON(e).uuid), this.specularColorMap && this.specularColorMap.isTexture && (n.specularColorMap = this.specularColorMap.toJSON(e).uuid), this.envMap && this.envMap.isTexture && (n.envMap = this.envMap.toJSON(e).uuid, this.combine !== void 0 && (n.combine = this.combine)), this.envMapIntensity !== void 0 && (n.envMapIntensity = this.envMapIntensity), this.reflectivity !== void 0 && (n.reflectivity = this.reflectivity), this.refractionRatio !== void 0 && (n.refractionRatio = this.refractionRatio), this.gradientMap && this.gradientMap.isTexture && (n.gradientMap = this.gradientMap.toJSON(e).uuid), this.transmission !== void 0 && (n.transmission = this.transmission), this.transmissionMap && this.transmissionMap.isTexture && (n.transmissionMap = this.transmissionMap.toJSON(e).uuid), this.thickness !== void 0 && (n.thickness = this.thickness), this.thicknessMap && this.thicknessMap.isTexture && (n.thicknessMap = this.thicknessMap.toJSON(e).uuid), this.attenuationDistance !== void 0 && (n.attenuationDistance = this.attenuationDistance), this.attenuationColor !== void 0 && (n.attenuationColor = this.attenuationColor.getHex()), this.size !== void 0 && (n.size = this.size), this.shadowSide !== null && (n.shadowSide = this.shadowSide), this.sizeAttenuation !== void 0 && (n.sizeAttenuation = this.sizeAttenuation), this.blending !== sr && (n.blending = this.blending), this.side !== Ai && (n.side = this.side), this.vertexColors && (n.vertexColors = !0), this.opacity < 1 && (n.opacity = this.opacity), this.format !== ct && (n.format = this.format), this.transparent === !0 && (n.transparent = this.transparent), n.depthFunc = this.depthFunc, n.depthTest = this.depthTest, n.depthWrite = this.depthWrite, n.colorWrite = this.colorWrite, n.stencilWrite = this.stencilWrite, n.stencilWriteMask = this.stencilWriteMask, n.stencilFunc = this.stencilFunc, n.stencilRef = this.stencilRef, n.stencilFuncMask = this.stencilFuncMask, n.stencilFail = this.stencilFail, n.stencilZFail = this.stencilZFail, n.stencilZPass = this.stencilZPass, this.rotation && this.rotation !== 0 && (n.rotation = this.rotation), this.polygonOffset === !0 && (n.polygonOffset = !0), this.polygonOffsetFactor !== 0 && (n.polygonOffsetFactor = this.polygonOffsetFactor), this.polygonOffsetUnits !== 0 && (n.polygonOffsetUnits = this.polygonOffsetUnits), this.linewidth && this.linewidth !== 1 && (n.linewidth = this.linewidth), this.dashSize !== void 0 && (n.dashSize = this.dashSize), this.gapSize !== void 0 && (n.gapSize = this.gapSize), this.scale !== void 0 && (n.scale = this.scale), this.dithering === !0 && (n.dithering = !0), this.alphaTest > 0 && (n.alphaTest = this.alphaTest), this.alphaToCoverage === !0 && (n.alphaToCoverage = this.alphaToCoverage), this.premultipliedAlpha === !0 && (n.premultipliedAlpha = this.premultipliedAlpha), this.wireframe === !0 && (n.wireframe = this.wireframe), this.wireframeLinewidth > 1 && (n.wireframeLinewidth = this.wireframeLinewidth), this.wireframeLinecap !== "round" && (n.wireframeLinecap = this.wireframeLinecap), this.wireframeLinejoin !== "round" && (n.wireframeLinejoin = this.wireframeLinejoin), this.flatShading === !0 && (n.flatShading = this.flatShading), this.visible === !1 && (n.visible = !1), this.toneMapped === !1 && (n.toneMapped = !1), JSON.stringify(this.userData) !== "{}" && (n.userData = this.userData);
        function i(r) {
            let o = [];
            for(let a in r){
                let l = r[a];
                delete l.metadata, o.push(l);
            }
            return o;
        }
        if (t) {
            let r = i(e.textures), o = i(e.images);
            r.length > 0 && (n.textures = r), o.length > 0 && (n.images = o);
        }
        return n;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        this.name = e.name, this.fog = e.fog, this.blending = e.blending, this.side = e.side, this.vertexColors = e.vertexColors, this.opacity = e.opacity, this.format = e.format, this.transparent = e.transparent, this.blendSrc = e.blendSrc, this.blendDst = e.blendDst, this.blendEquation = e.blendEquation, this.blendSrcAlpha = e.blendSrcAlpha, this.blendDstAlpha = e.blendDstAlpha, this.blendEquationAlpha = e.blendEquationAlpha, this.depthFunc = e.depthFunc, this.depthTest = e.depthTest, this.depthWrite = e.depthWrite, this.stencilWriteMask = e.stencilWriteMask, this.stencilFunc = e.stencilFunc, this.stencilRef = e.stencilRef, this.stencilFuncMask = e.stencilFuncMask, this.stencilFail = e.stencilFail, this.stencilZFail = e.stencilZFail, this.stencilZPass = e.stencilZPass, this.stencilWrite = e.stencilWrite;
        let t = e.clippingPlanes, n = null;
        if (t !== null) {
            let i = t.length;
            n = new Array(i);
            for(let r = 0; r !== i; ++r)n[r] = t[r].clone();
        }
        return this.clippingPlanes = n, this.clipIntersection = e.clipIntersection, this.clipShadows = e.clipShadows, this.shadowSide = e.shadowSide, this.colorWrite = e.colorWrite, this.precision = e.precision, this.polygonOffset = e.polygonOffset, this.polygonOffsetFactor = e.polygonOffsetFactor, this.polygonOffsetUnits = e.polygonOffsetUnits, this.dithering = e.dithering, this.alphaTest = e.alphaTest, this.alphaToCoverage = e.alphaToCoverage, this.premultipliedAlpha = e.premultipliedAlpha, this.visible = e.visible, this.toneMapped = e.toneMapped, this.userData = JSON.parse(JSON.stringify(e.userData)), this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
};
dt.prototype.isMaterial = !0;
var $c = {
    aliceblue: 15792383,
    antiquewhite: 16444375,
    aqua: 65535,
    aquamarine: 8388564,
    azure: 15794175,
    beige: 16119260,
    bisque: 16770244,
    black: 0,
    blanchedalmond: 16772045,
    blue: 255,
    blueviolet: 9055202,
    brown: 10824234,
    burlywood: 14596231,
    cadetblue: 6266528,
    chartreuse: 8388352,
    chocolate: 13789470,
    coral: 16744272,
    cornflowerblue: 6591981,
    cornsilk: 16775388,
    crimson: 14423100,
    cyan: 65535,
    darkblue: 139,
    darkcyan: 35723,
    darkgoldenrod: 12092939,
    darkgray: 11119017,
    darkgreen: 25600,
    darkgrey: 11119017,
    darkkhaki: 12433259,
    darkmagenta: 9109643,
    darkolivegreen: 5597999,
    darkorange: 16747520,
    darkorchid: 10040012,
    darkred: 9109504,
    darksalmon: 15308410,
    darkseagreen: 9419919,
    darkslateblue: 4734347,
    darkslategray: 3100495,
    darkslategrey: 3100495,
    darkturquoise: 52945,
    darkviolet: 9699539,
    deeppink: 16716947,
    deepskyblue: 49151,
    dimgray: 6908265,
    dimgrey: 6908265,
    dodgerblue: 2003199,
    firebrick: 11674146,
    floralwhite: 16775920,
    forestgreen: 2263842,
    fuchsia: 16711935,
    gainsboro: 14474460,
    ghostwhite: 16316671,
    gold: 16766720,
    goldenrod: 14329120,
    gray: 8421504,
    green: 32768,
    greenyellow: 11403055,
    grey: 8421504,
    honeydew: 15794160,
    hotpink: 16738740,
    indianred: 13458524,
    indigo: 4915330,
    ivory: 16777200,
    khaki: 15787660,
    lavender: 15132410,
    lavenderblush: 16773365,
    lawngreen: 8190976,
    lemonchiffon: 16775885,
    lightblue: 11393254,
    lightcoral: 15761536,
    lightcyan: 14745599,
    lightgoldenrodyellow: 16448210,
    lightgray: 13882323,
    lightgreen: 9498256,
    lightgrey: 13882323,
    lightpink: 16758465,
    lightsalmon: 16752762,
    lightseagreen: 2142890,
    lightskyblue: 8900346,
    lightslategray: 7833753,
    lightslategrey: 7833753,
    lightsteelblue: 11584734,
    lightyellow: 16777184,
    lime: 65280,
    limegreen: 3329330,
    linen: 16445670,
    magenta: 16711935,
    maroon: 8388608,
    mediumaquamarine: 6737322,
    mediumblue: 205,
    mediumorchid: 12211667,
    mediumpurple: 9662683,
    mediumseagreen: 3978097,
    mediumslateblue: 8087790,
    mediumspringgreen: 64154,
    mediumturquoise: 4772300,
    mediumvioletred: 13047173,
    midnightblue: 1644912,
    mintcream: 16121850,
    mistyrose: 16770273,
    moccasin: 16770229,
    navajowhite: 16768685,
    navy: 128,
    oldlace: 16643558,
    olive: 8421376,
    olivedrab: 7048739,
    orange: 16753920,
    orangered: 16729344,
    orchid: 14315734,
    palegoldenrod: 15657130,
    palegreen: 10025880,
    paleturquoise: 11529966,
    palevioletred: 14381203,
    papayawhip: 16773077,
    peachpuff: 16767673,
    peru: 13468991,
    pink: 16761035,
    plum: 14524637,
    powderblue: 11591910,
    purple: 8388736,
    rebeccapurple: 6697881,
    red: 16711680,
    rosybrown: 12357519,
    royalblue: 4286945,
    saddlebrown: 9127187,
    salmon: 16416882,
    sandybrown: 16032864,
    seagreen: 3050327,
    seashell: 16774638,
    sienna: 10506797,
    silver: 12632256,
    skyblue: 8900331,
    slateblue: 6970061,
    slategray: 7372944,
    slategrey: 7372944,
    snow: 16775930,
    springgreen: 65407,
    steelblue: 4620980,
    tan: 13808780,
    teal: 32896,
    thistle: 14204888,
    tomato: 16737095,
    turquoise: 4251856,
    violet: 15631086,
    wheat: 16113331,
    white: 16777215,
    whitesmoke: 16119285,
    yellow: 16776960,
    yellowgreen: 10145074
}, Ft = {
    h: 0,
    s: 0,
    l: 0
}, jr = {
    h: 0,
    s: 0,
    l: 0
};
function Io(s, e, t) {
    return t < 0 && (t += 1), t > 1 && (t -= 1), t < 1 / 6 ? s + (e - s) * 6 * t : t < 1 / 2 ? e : t < 2 / 3 ? s + (e - s) * 6 * (2 / 3 - t) : s;
}
function Do(s) {
    return s < .04045 ? s * .0773993808 : Math.pow(s * .9478672986 + .0521327014, 2.4);
}
function Fo(s) {
    return s < .0031308 ? s * 12.92 : 1.055 * Math.pow(s, .41666) - .055;
}
var ae = class {
    constructor(e, t, n){
        return t === void 0 && n === void 0 ? this.set(e) : this.setRGB(e, t, n);
    }
    set(e) {
        return e && e.isColor ? this.copy(e) : typeof e == "number" ? this.setHex(e) : typeof e == "string" && this.setStyle(e), this;
    }
    setScalar(e) {
        return this.r = e, this.g = e, this.b = e, this;
    }
    setHex(e) {
        return e = Math.floor(e), this.r = (e >> 16 & 255) / 255, this.g = (e >> 8 & 255) / 255, this.b = (e & 255) / 255, this;
    }
    setRGB(e, t, n) {
        return this.r = e, this.g = t, this.b = n, this;
    }
    setHSL(e, t, n) {
        if (e = da(e, 1), t = mt(t, 0, 1), n = mt(n, 0, 1), t === 0) this.r = this.g = this.b = n;
        else {
            let i = n <= .5 ? n * (1 + t) : n + t - n * t, r = 2 * n - i;
            this.r = Io(r, i, e + 1 / 3), this.g = Io(r, i, e), this.b = Io(r, i, e - 1 / 3);
        }
        return this;
    }
    setStyle(e) {
        function t(i) {
            i !== void 0 && parseFloat(i) < 1 && console.warn("THREE.Color: Alpha component of " + e + " will be ignored.");
        }
        let n;
        if (n = /^((?:rgb|hsl)a?)\(([^\)]*)\)/.exec(e)) {
            let i, r = n[1], o = n[2];
            switch(r){
                case "rgb":
                case "rgba":
                    if (i = /^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return this.r = Math.min(255, parseInt(i[1], 10)) / 255, this.g = Math.min(255, parseInt(i[2], 10)) / 255, this.b = Math.min(255, parseInt(i[3], 10)) / 255, t(i[4]), this;
                    if (i = /^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return this.r = Math.min(100, parseInt(i[1], 10)) / 100, this.g = Math.min(100, parseInt(i[2], 10)) / 100, this.b = Math.min(100, parseInt(i[3], 10)) / 100, t(i[4]), this;
                    break;
                case "hsl":
                case "hsla":
                    if (i = /^\s*(\d*\.?\d+)\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) {
                        let a = parseFloat(i[1]) / 360, l = parseInt(i[2], 10) / 100, c = parseInt(i[3], 10) / 100;
                        return t(i[4]), this.setHSL(a, l, c);
                    }
                    break;
            }
        } else if (n = /^\#([A-Fa-f\d]+)$/.exec(e)) {
            let i1 = n[1], r1 = i1.length;
            if (r1 === 3) return this.r = parseInt(i1.charAt(0) + i1.charAt(0), 16) / 255, this.g = parseInt(i1.charAt(1) + i1.charAt(1), 16) / 255, this.b = parseInt(i1.charAt(2) + i1.charAt(2), 16) / 255, this;
            if (r1 === 6) return this.r = parseInt(i1.charAt(0) + i1.charAt(1), 16) / 255, this.g = parseInt(i1.charAt(2) + i1.charAt(3), 16) / 255, this.b = parseInt(i1.charAt(4) + i1.charAt(5), 16) / 255, this;
        }
        return e && e.length > 0 ? this.setColorName(e) : this;
    }
    setColorName(e) {
        let t = $c[e.toLowerCase()];
        return t !== void 0 ? this.setHex(t) : console.warn("THREE.Color: Unknown color " + e), this;
    }
    clone() {
        return new this.constructor(this.r, this.g, this.b);
    }
    copy(e) {
        return this.r = e.r, this.g = e.g, this.b = e.b, this;
    }
    copySRGBToLinear(e) {
        return this.r = Do(e.r), this.g = Do(e.g), this.b = Do(e.b), this;
    }
    copyLinearToSRGB(e) {
        return this.r = Fo(e.r), this.g = Fo(e.g), this.b = Fo(e.b), this;
    }
    convertSRGBToLinear() {
        return this.copySRGBToLinear(this), this;
    }
    convertLinearToSRGB() {
        return this.copyLinearToSRGB(this), this;
    }
    getHex() {
        return this.r * 255 << 16 ^ this.g * 255 << 8 ^ this.b * 255 << 0;
    }
    getHexString() {
        return ("000000" + this.getHex().toString(16)).slice(-6);
    }
    getHSL(e) {
        let t = this.r, n = this.g, i = this.b, r = Math.max(t, n, i), o = Math.min(t, n, i), a, l, c = (o + r) / 2;
        if (o === r) a = 0, l = 0;
        else {
            let h = r - o;
            switch(l = c <= .5 ? h / (r + o) : h / (2 - r - o), r){
                case t:
                    a = (n - i) / h + (n < i ? 6 : 0);
                    break;
                case n:
                    a = (i - t) / h + 2;
                    break;
                case i:
                    a = (t - n) / h + 4;
                    break;
            }
            a /= 6;
        }
        return e.h = a, e.s = l, e.l = c, e;
    }
    getStyle() {
        return "rgb(" + (this.r * 255 | 0) + "," + (this.g * 255 | 0) + "," + (this.b * 255 | 0) + ")";
    }
    offsetHSL(e, t, n) {
        return this.getHSL(Ft), Ft.h += e, Ft.s += t, Ft.l += n, this.setHSL(Ft.h, Ft.s, Ft.l), this;
    }
    add(e) {
        return this.r += e.r, this.g += e.g, this.b += e.b, this;
    }
    addColors(e, t) {
        return this.r = e.r + t.r, this.g = e.g + t.g, this.b = e.b + t.b, this;
    }
    addScalar(e) {
        return this.r += e, this.g += e, this.b += e, this;
    }
    sub(e) {
        return this.r = Math.max(0, this.r - e.r), this.g = Math.max(0, this.g - e.g), this.b = Math.max(0, this.b - e.b), this;
    }
    multiply(e) {
        return this.r *= e.r, this.g *= e.g, this.b *= e.b, this;
    }
    multiplyScalar(e) {
        return this.r *= e, this.g *= e, this.b *= e, this;
    }
    lerp(e, t) {
        return this.r += (e.r - this.r) * t, this.g += (e.g - this.g) * t, this.b += (e.b - this.b) * t, this;
    }
    lerpColors(e, t, n) {
        return this.r = e.r + (t.r - e.r) * n, this.g = e.g + (t.g - e.g) * n, this.b = e.b + (t.b - e.b) * n, this;
    }
    lerpHSL(e, t) {
        this.getHSL(Ft), e.getHSL(jr);
        let n = or(Ft.h, jr.h, t), i = or(Ft.s, jr.s, t), r = or(Ft.l, jr.l, t);
        return this.setHSL(n, i, r), this;
    }
    equals(e) {
        return e.r === this.r && e.g === this.g && e.b === this.b;
    }
    fromArray(e, t = 0) {
        return this.r = e[t], this.g = e[t + 1], this.b = e[t + 2], this;
    }
    toArray(e = [], t = 0) {
        return e[t] = this.r, e[t + 1] = this.g, e[t + 2] = this.b, e;
    }
    fromBufferAttribute(e, t) {
        return this.r = e.getX(t), this.g = e.getY(t), this.b = e.getZ(t), e.normalized === !0 && (this.r /= 255, this.g /= 255, this.b /= 255), this;
    }
    toJSON() {
        return this.getHex();
    }
};
ae.NAMES = $c;
ae.prototype.isColor = !0;
ae.prototype.r = 1;
ae.prototype.g = 1;
ae.prototype.b = 1;
var hn = class extends dt {
    constructor(e){
        super();
        this.type = "MeshBasicMaterial", this.color = new ae(16777215), this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = Vs, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.specularMap = e.specularMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.combine = e.combine, this.reflectivity = e.reflectivity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this;
    }
};
hn.prototype.isMeshBasicMaterial = !0;
var Je = new M, Qr = new X, Ue = class {
    constructor(e, t, n){
        if (Array.isArray(e)) throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
        this.name = "", this.array = e, this.itemSize = t, this.count = e !== void 0 ? e.length / t : 0, this.normalized = n === !0, this.usage = hr, this.updateRange = {
            offset: 0,
            count: -1
        }, this.version = 0;
    }
    onUploadCallback() {}
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
    setUsage(e) {
        return this.usage = e, this;
    }
    copy(e) {
        return this.name = e.name, this.array = new e.array.constructor(e.array), this.itemSize = e.itemSize, this.count = e.count, this.normalized = e.normalized, this.usage = e.usage, this;
    }
    copyAt(e, t, n) {
        e *= this.itemSize, n *= t.itemSize;
        for(let i = 0, r = this.itemSize; i < r; i++)this.array[e + i] = t.array[n + i];
        return this;
    }
    copyArray(e) {
        return this.array.set(e), this;
    }
    copyColorsArray(e) {
        let t = this.array, n = 0;
        for(let i = 0, r = e.length; i < r; i++){
            let o = e[i];
            o === void 0 && (console.warn("THREE.BufferAttribute.copyColorsArray(): color is undefined", i), o = new ae), t[n++] = o.r, t[n++] = o.g, t[n++] = o.b;
        }
        return this;
    }
    copyVector2sArray(e) {
        let t = this.array, n = 0;
        for(let i = 0, r = e.length; i < r; i++){
            let o = e[i];
            o === void 0 && (console.warn("THREE.BufferAttribute.copyVector2sArray(): vector is undefined", i), o = new X), t[n++] = o.x, t[n++] = o.y;
        }
        return this;
    }
    copyVector3sArray(e) {
        let t = this.array, n = 0;
        for(let i = 0, r = e.length; i < r; i++){
            let o = e[i];
            o === void 0 && (console.warn("THREE.BufferAttribute.copyVector3sArray(): vector is undefined", i), o = new M), t[n++] = o.x, t[n++] = o.y, t[n++] = o.z;
        }
        return this;
    }
    copyVector4sArray(e) {
        let t = this.array, n = 0;
        for(let i = 0, r = e.length; i < r; i++){
            let o = e[i];
            o === void 0 && (console.warn("THREE.BufferAttribute.copyVector4sArray(): vector is undefined", i), o = new Ve), t[n++] = o.x, t[n++] = o.y, t[n++] = o.z, t[n++] = o.w;
        }
        return this;
    }
    applyMatrix3(e) {
        if (this.itemSize === 2) for(let t = 0, n = this.count; t < n; t++)Qr.fromBufferAttribute(this, t), Qr.applyMatrix3(e), this.setXY(t, Qr.x, Qr.y);
        else if (this.itemSize === 3) for(let t1 = 0, n1 = this.count; t1 < n1; t1++)Je.fromBufferAttribute(this, t1), Je.applyMatrix3(e), this.setXYZ(t1, Je.x, Je.y, Je.z);
        return this;
    }
    applyMatrix4(e) {
        for(let t = 0, n = this.count; t < n; t++)Je.x = this.getX(t), Je.y = this.getY(t), Je.z = this.getZ(t), Je.applyMatrix4(e), this.setXYZ(t, Je.x, Je.y, Je.z);
        return this;
    }
    applyNormalMatrix(e) {
        for(let t = 0, n = this.count; t < n; t++)Je.x = this.getX(t), Je.y = this.getY(t), Je.z = this.getZ(t), Je.applyNormalMatrix(e), this.setXYZ(t, Je.x, Je.y, Je.z);
        return this;
    }
    transformDirection(e) {
        for(let t = 0, n = this.count; t < n; t++)Je.x = this.getX(t), Je.y = this.getY(t), Je.z = this.getZ(t), Je.transformDirection(e), this.setXYZ(t, Je.x, Je.y, Je.z);
        return this;
    }
    set(e, t = 0) {
        return this.array.set(e, t), this;
    }
    getX(e) {
        return this.array[e * this.itemSize];
    }
    setX(e, t) {
        return this.array[e * this.itemSize] = t, this;
    }
    getY(e) {
        return this.array[e * this.itemSize + 1];
    }
    setY(e, t) {
        return this.array[e * this.itemSize + 1] = t, this;
    }
    getZ(e) {
        return this.array[e * this.itemSize + 2];
    }
    setZ(e, t) {
        return this.array[e * this.itemSize + 2] = t, this;
    }
    getW(e) {
        return this.array[e * this.itemSize + 3];
    }
    setW(e, t) {
        return this.array[e * this.itemSize + 3] = t, this;
    }
    setXY(e, t, n) {
        return e *= this.itemSize, this.array[e + 0] = t, this.array[e + 1] = n, this;
    }
    setXYZ(e, t, n, i) {
        return e *= this.itemSize, this.array[e + 0] = t, this.array[e + 1] = n, this.array[e + 2] = i, this;
    }
    setXYZW(e, t, n, i, r) {
        return e *= this.itemSize, this.array[e + 0] = t, this.array[e + 1] = n, this.array[e + 2] = i, this.array[e + 3] = r, this;
    }
    onUpload(e) {
        return this.onUploadCallback = e, this;
    }
    clone() {
        return new this.constructor(this.array, this.itemSize).copy(this);
    }
    toJSON() {
        let e = {
            itemSize: this.itemSize,
            type: this.array.constructor.name,
            array: Array.prototype.slice.call(this.array),
            normalized: this.normalized
        };
        return this.name !== "" && (e.name = this.name), this.usage !== hr && (e.usage = this.usage), (this.updateRange.offset !== 0 || this.updateRange.count !== -1) && (e.updateRange = this.updateRange), e;
    }
};
Ue.prototype.isBufferAttribute = !0;
var jc = class extends Ue {
    constructor(e, t, n){
        super(new Int8Array(e), t, n);
    }
}, Qc = class extends Ue {
    constructor(e, t, n){
        super(new Uint8Array(e), t, n);
    }
}, Kc = class extends Ue {
    constructor(e, t, n){
        super(new Uint8ClampedArray(e), t, n);
    }
}, eh = class extends Ue {
    constructor(e, t, n){
        super(new Int16Array(e), t, n);
    }
}, Ys = class extends Ue {
    constructor(e, t, n){
        super(new Uint16Array(e), t, n);
    }
}, th = class extends Ue {
    constructor(e, t, n){
        super(new Int32Array(e), t, n);
    }
}, Zs = class extends Ue {
    constructor(e, t, n){
        super(new Uint32Array(e), t, n);
    }
}, nh = class extends Ue {
    constructor(e, t, n){
        super(new Uint16Array(e), t, n);
    }
};
nh.prototype.isFloat16BufferAttribute = !0;
var de = class extends Ue {
    constructor(e, t, n){
        super(new Float32Array(e), t, n);
    }
}, ih = class extends Ue {
    constructor(e, t, n){
        super(new Float64Array(e), t, n);
    }
}, cf = 0, Rt = new pe, No = new Ne, ci = new M, Tt = new Lt, $i = new Lt, ht = new M, _e = class extends En {
    constructor(){
        super();
        Object.defineProperty(this, "id", {
            value: cf++
        }), this.uuid = Et(), this.name = "", this.type = "BufferGeometry", this.index = null, this.attributes = {}, this.morphAttributes = {}, this.morphTargetsRelative = !1, this.groups = [], this.boundingBox = null, this.boundingSphere = null, this.drawRange = {
            start: 0,
            count: 1 / 0
        }, this.userData = {};
    }
    getIndex() {
        return this.index;
    }
    setIndex(e) {
        return Array.isArray(e) ? this.index = new (Yc(e) > 65535 ? Zs : Ys)(e, 1) : this.index = e, this;
    }
    getAttribute(e) {
        return this.attributes[e];
    }
    setAttribute(e, t) {
        return this.attributes[e] = t, this;
    }
    deleteAttribute(e) {
        return delete this.attributes[e], this;
    }
    hasAttribute(e) {
        return this.attributes[e] !== void 0;
    }
    addGroup(e, t, n = 0) {
        this.groups.push({
            start: e,
            count: t,
            materialIndex: n
        });
    }
    clearGroups() {
        this.groups = [];
    }
    setDrawRange(e, t) {
        this.drawRange.start = e, this.drawRange.count = t;
    }
    applyMatrix4(e) {
        let t = this.attributes.position;
        t !== void 0 && (t.applyMatrix4(e), t.needsUpdate = !0);
        let n = this.attributes.normal;
        if (n !== void 0) {
            let r = new lt().getNormalMatrix(e);
            n.applyNormalMatrix(r), n.needsUpdate = !0;
        }
        let i = this.attributes.tangent;
        return i !== void 0 && (i.transformDirection(e), i.needsUpdate = !0), this.boundingBox !== null && this.computeBoundingBox(), this.boundingSphere !== null && this.computeBoundingSphere(), this;
    }
    applyQuaternion(e) {
        return Rt.makeRotationFromQuaternion(e), this.applyMatrix4(Rt), this;
    }
    rotateX(e) {
        return Rt.makeRotationX(e), this.applyMatrix4(Rt), this;
    }
    rotateY(e) {
        return Rt.makeRotationY(e), this.applyMatrix4(Rt), this;
    }
    rotateZ(e) {
        return Rt.makeRotationZ(e), this.applyMatrix4(Rt), this;
    }
    translate(e, t, n) {
        return Rt.makeTranslation(e, t, n), this.applyMatrix4(Rt), this;
    }
    scale(e, t, n) {
        return Rt.makeScale(e, t, n), this.applyMatrix4(Rt), this;
    }
    lookAt(e) {
        return No.lookAt(e), No.updateMatrix(), this.applyMatrix4(No.matrix), this;
    }
    center() {
        return this.computeBoundingBox(), this.boundingBox.getCenter(ci).negate(), this.translate(ci.x, ci.y, ci.z), this;
    }
    setFromPoints(e) {
        let t = [];
        for(let n = 0, i = e.length; n < i; n++){
            let r = e[n];
            t.push(r.x, r.y, r.z || 0);
        }
        return this.setAttribute("position", new de(t, 3)), this;
    }
    computeBoundingBox() {
        this.boundingBox === null && (this.boundingBox = new Lt);
        let e = this.attributes.position, t = this.morphAttributes.position;
        if (e && e.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box. Alternatively set "mesh.frustumCulled" to "false".', this), this.boundingBox.set(new M(-1 / 0, -1 / 0, -1 / 0), new M(1 / 0, 1 / 0, 1 / 0));
            return;
        }
        if (e !== void 0) {
            if (this.boundingBox.setFromBufferAttribute(e), t) for(let n = 0, i = t.length; n < i; n++){
                let r = t[n];
                Tt.setFromBufferAttribute(r), this.morphTargetsRelative ? (ht.addVectors(this.boundingBox.min, Tt.min), this.boundingBox.expandByPoint(ht), ht.addVectors(this.boundingBox.max, Tt.max), this.boundingBox.expandByPoint(ht)) : (this.boundingBox.expandByPoint(Tt.min), this.boundingBox.expandByPoint(Tt.max));
            }
        } else this.boundingBox.makeEmpty();
        (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) && console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
    computeBoundingSphere() {
        this.boundingSphere === null && (this.boundingSphere = new An);
        let e = this.attributes.position, t = this.morphAttributes.position;
        if (e && e.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere. Alternatively set "mesh.frustumCulled" to "false".', this), this.boundingSphere.set(new M, 1 / 0);
            return;
        }
        if (e) {
            let n = this.boundingSphere.center;
            if (Tt.setFromBufferAttribute(e), t) for(let r = 0, o = t.length; r < o; r++){
                let a = t[r];
                $i.setFromBufferAttribute(a), this.morphTargetsRelative ? (ht.addVectors(Tt.min, $i.min), Tt.expandByPoint(ht), ht.addVectors(Tt.max, $i.max), Tt.expandByPoint(ht)) : (Tt.expandByPoint($i.min), Tt.expandByPoint($i.max));
            }
            Tt.getCenter(n);
            let i = 0;
            for(let r1 = 0, o1 = e.count; r1 < o1; r1++)ht.fromBufferAttribute(e, r1), i = Math.max(i, n.distanceToSquared(ht));
            if (t) for(let r2 = 0, o2 = t.length; r2 < o2; r2++){
                let a1 = t[r2], l = this.morphTargetsRelative;
                for(let c = 0, h = a1.count; c < h; c++)ht.fromBufferAttribute(a1, c), l && (ci.fromBufferAttribute(e, c), ht.add(ci)), i = Math.max(i, n.distanceToSquared(ht));
            }
            this.boundingSphere.radius = Math.sqrt(i), isNaN(this.boundingSphere.radius) && console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
        }
    }
    computeTangents() {
        let e = this.index, t = this.attributes;
        if (e === null || t.position === void 0 || t.normal === void 0 || t.uv === void 0) {
            console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");
            return;
        }
        let n = e.array, i = t.position.array, r = t.normal.array, o = t.uv.array, a = i.length / 3;
        t.tangent === void 0 && this.setAttribute("tangent", new Ue(new Float32Array(4 * a), 4));
        let l = t.tangent.array, c = [], h = [];
        for(let B = 0; B < a; B++)c[B] = new M, h[B] = new M;
        let u = new M, d = new M, f = new M, m = new X, x = new X, v = new X, g = new M, p = new M;
        function _(B, P, w) {
            u.fromArray(i, B * 3), d.fromArray(i, P * 3), f.fromArray(i, w * 3), m.fromArray(o, B * 2), x.fromArray(o, P * 2), v.fromArray(o, w * 2), d.sub(u), f.sub(u), x.sub(m), v.sub(m);
            let E = 1 / (x.x * v.y - v.x * x.y);
            !isFinite(E) || (g.copy(d).multiplyScalar(v.y).addScaledVector(f, -x.y).multiplyScalar(E), p.copy(f).multiplyScalar(x.x).addScaledVector(d, -v.x).multiplyScalar(E), c[B].add(g), c[P].add(g), c[w].add(g), h[B].add(p), h[P].add(p), h[w].add(p));
        }
        let y = this.groups;
        y.length === 0 && (y = [
            {
                start: 0,
                count: n.length
            }
        ]);
        for(let B1 = 0, P = y.length; B1 < P; ++B1){
            let w = y[B1], E = w.start, D = w.count;
            for(let U = E, F = E + D; U < F; U += 3)_(n[U + 0], n[U + 1], n[U + 2]);
        }
        let b = new M, A = new M, L = new M, I = new M;
        function k(B) {
            L.fromArray(r, B * 3), I.copy(L);
            let P = c[B];
            b.copy(P), b.sub(L.multiplyScalar(L.dot(P))).normalize(), A.crossVectors(I, P);
            let E = A.dot(h[B]) < 0 ? -1 : 1;
            l[B * 4] = b.x, l[B * 4 + 1] = b.y, l[B * 4 + 2] = b.z, l[B * 4 + 3] = E;
        }
        for(let B2 = 0, P1 = y.length; B2 < P1; ++B2){
            let w1 = y[B2], E1 = w1.start, D1 = w1.count;
            for(let U1 = E1, F1 = E1 + D1; U1 < F1; U1 += 3)k(n[U1 + 0]), k(n[U1 + 1]), k(n[U1 + 2]);
        }
    }
    computeVertexNormals() {
        let e = this.index, t = this.getAttribute("position");
        if (t !== void 0) {
            let n = this.getAttribute("normal");
            if (n === void 0) n = new Ue(new Float32Array(t.count * 3), 3), this.setAttribute("normal", n);
            else for(let d = 0, f = n.count; d < f; d++)n.setXYZ(d, 0, 0, 0);
            let i = new M, r = new M, o = new M, a = new M, l = new M, c = new M, h = new M, u = new M;
            if (e) for(let d1 = 0, f1 = e.count; d1 < f1; d1 += 3){
                let m = e.getX(d1 + 0), x = e.getX(d1 + 1), v = e.getX(d1 + 2);
                i.fromBufferAttribute(t, m), r.fromBufferAttribute(t, x), o.fromBufferAttribute(t, v), h.subVectors(o, r), u.subVectors(i, r), h.cross(u), a.fromBufferAttribute(n, m), l.fromBufferAttribute(n, x), c.fromBufferAttribute(n, v), a.add(h), l.add(h), c.add(h), n.setXYZ(m, a.x, a.y, a.z), n.setXYZ(x, l.x, l.y, l.z), n.setXYZ(v, c.x, c.y, c.z);
            }
            else for(let d2 = 0, f2 = t.count; d2 < f2; d2 += 3)i.fromBufferAttribute(t, d2 + 0), r.fromBufferAttribute(t, d2 + 1), o.fromBufferAttribute(t, d2 + 2), h.subVectors(o, r), u.subVectors(i, r), h.cross(u), n.setXYZ(d2 + 0, h.x, h.y, h.z), n.setXYZ(d2 + 1, h.x, h.y, h.z), n.setXYZ(d2 + 2, h.x, h.y, h.z);
            this.normalizeNormals(), n.needsUpdate = !0;
        }
    }
    merge(e, t) {
        if (!(e && e.isBufferGeometry)) {
            console.error("THREE.BufferGeometry.merge(): geometry not an instance of THREE.BufferGeometry.", e);
            return;
        }
        t === void 0 && (t = 0, console.warn("THREE.BufferGeometry.merge(): Overwriting original geometry, starting at offset=0. Use BufferGeometryUtils.mergeBufferGeometries() for lossless merge."));
        let n = this.attributes;
        for(let i in n){
            if (e.attributes[i] === void 0) continue;
            let o = n[i].array, a = e.attributes[i], l = a.array, c = a.itemSize * t, h = Math.min(l.length, o.length - c);
            for(let u = 0, d = c; u < h; u++, d++)o[d] = l[u];
        }
        return this;
    }
    normalizeNormals() {
        let e = this.attributes.normal;
        for(let t = 0, n = e.count; t < n; t++)ht.fromBufferAttribute(e, t), ht.normalize(), e.setXYZ(t, ht.x, ht.y, ht.z);
    }
    toNonIndexed() {
        function e(a, l) {
            let c = a.array, h = a.itemSize, u = a.normalized, d = new c.constructor(l.length * h), f = 0, m = 0;
            for(let x = 0, v = l.length; x < v; x++){
                a.isInterleavedBufferAttribute ? f = l[x] * a.data.stride + a.offset : f = l[x] * h;
                for(let g = 0; g < h; g++)d[m++] = c[f++];
            }
            return new Ue(d, h, u);
        }
        if (this.index === null) return console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."), this;
        let t = new _e, n = this.index.array, i = this.attributes;
        for(let a in i){
            let l = i[a], c = e(l, n);
            t.setAttribute(a, c);
        }
        let r = this.morphAttributes;
        for(let a1 in r){
            let l1 = [], c1 = r[a1];
            for(let h = 0, u = c1.length; h < u; h++){
                let d = c1[h], f = e(d, n);
                l1.push(f);
            }
            t.morphAttributes[a1] = l1;
        }
        t.morphTargetsRelative = this.morphTargetsRelative;
        let o = this.groups;
        for(let a2 = 0, l2 = o.length; a2 < l2; a2++){
            let c2 = o[a2];
            t.addGroup(c2.start, c2.count, c2.materialIndex);
        }
        return t;
    }
    toJSON() {
        let e = {
            metadata: {
                version: 4.5,
                type: "BufferGeometry",
                generator: "BufferGeometry.toJSON"
            }
        };
        if (e.uuid = this.uuid, e.type = this.type, this.name !== "" && (e.name = this.name), Object.keys(this.userData).length > 0 && (e.userData = this.userData), this.parameters !== void 0) {
            let l = this.parameters;
            for(let c in l)l[c] !== void 0 && (e[c] = l[c]);
            return e;
        }
        e.data = {
            attributes: {}
        };
        let t = this.index;
        t !== null && (e.data.index = {
            type: t.array.constructor.name,
            array: Array.prototype.slice.call(t.array)
        });
        let n = this.attributes;
        for(let l1 in n){
            let c1 = n[l1];
            e.data.attributes[l1] = c1.toJSON(e.data);
        }
        let i = {}, r = !1;
        for(let l2 in this.morphAttributes){
            let c2 = this.morphAttributes[l2], h = [];
            for(let u = 0, d = c2.length; u < d; u++){
                let f = c2[u];
                h.push(f.toJSON(e.data));
            }
            h.length > 0 && (i[l2] = h, r = !0);
        }
        r && (e.data.morphAttributes = i, e.data.morphTargetsRelative = this.morphTargetsRelative);
        let o = this.groups;
        o.length > 0 && (e.data.groups = JSON.parse(JSON.stringify(o)));
        let a = this.boundingSphere;
        return a !== null && (e.data.boundingSphere = {
            center: a.center.toArray(),
            radius: a.radius
        }), e;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        this.index = null, this.attributes = {}, this.morphAttributes = {}, this.groups = [], this.boundingBox = null, this.boundingSphere = null;
        let t = {};
        this.name = e.name;
        let n = e.index;
        n !== null && this.setIndex(n.clone(t));
        let i = e.attributes;
        for(let c in i){
            let h = i[c];
            this.setAttribute(c, h.clone(t));
        }
        let r = e.morphAttributes;
        for(let c1 in r){
            let h1 = [], u = r[c1];
            for(let d = 0, f = u.length; d < f; d++)h1.push(u[d].clone(t));
            this.morphAttributes[c1] = h1;
        }
        this.morphTargetsRelative = e.morphTargetsRelative;
        let o = e.groups;
        for(let c2 = 0, h2 = o.length; c2 < h2; c2++){
            let u1 = o[c2];
            this.addGroup(u1.start, u1.count, u1.materialIndex);
        }
        let a = e.boundingBox;
        a !== null && (this.boundingBox = a.clone());
        let l = e.boundingSphere;
        return l !== null && (this.boundingSphere = l.clone()), this.drawRange.start = e.drawRange.start, this.drawRange.count = e.drawRange.count, this.userData = e.userData, e.parameters !== void 0 && (this.parameters = Object.assign({}, e.parameters)), this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
};
_e.prototype.isBufferGeometry = !0;
var Cl = new pe, hi = new Cn, Bo = new An, mn = new M, gn = new M, xn = new M, zo = new M, Uo = new M, Oo = new M, Kr = new M, es = new M, ts = new M, ns = new X, is = new X, rs = new X, Ho = new M, ss = new M, st = class extends Ne {
    constructor(e = new _e, t = new hn){
        super();
        this.type = "Mesh", this.geometry = e, this.material = t, this.updateMorphTargets();
    }
    copy(e) {
        return super.copy(e), e.morphTargetInfluences !== void 0 && (this.morphTargetInfluences = e.morphTargetInfluences.slice()), e.morphTargetDictionary !== void 0 && (this.morphTargetDictionary = Object.assign({}, e.morphTargetDictionary)), this.material = e.material, this.geometry = e.geometry, this;
    }
    updateMorphTargets() {
        let e = this.geometry;
        if (e.isBufferGeometry) {
            let t = e.morphAttributes, n = Object.keys(t);
            if (n.length > 0) {
                let i = t[n[0]];
                if (i !== void 0) {
                    this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                    for(let r = 0, o = i.length; r < o; r++){
                        let a = i[r].name || String(r);
                        this.morphTargetInfluences.push(0), this.morphTargetDictionary[a] = r;
                    }
                }
            }
        } else {
            let t1 = e.morphTargets;
            t1 !== void 0 && t1.length > 0 && console.error("THREE.Mesh.updateMorphTargets() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.");
        }
    }
    raycast(e, t) {
        let n = this.geometry, i = this.material, r = this.matrixWorld;
        if (i === void 0 || (n.boundingSphere === null && n.computeBoundingSphere(), Bo.copy(n.boundingSphere), Bo.applyMatrix4(r), e.ray.intersectsSphere(Bo) === !1) || (Cl.copy(r).invert(), hi.copy(e.ray).applyMatrix4(Cl), n.boundingBox !== null && hi.intersectsBox(n.boundingBox) === !1)) return;
        let o;
        if (n.isBufferGeometry) {
            let a = n.index, l = n.attributes.position, c = n.morphAttributes.position, h = n.morphTargetsRelative, u = n.attributes.uv, d = n.attributes.uv2, f = n.groups, m = n.drawRange;
            if (a !== null) if (Array.isArray(i)) for(let x = 0, v = f.length; x < v; x++){
                let g = f[x], p = i[g.materialIndex], _ = Math.max(g.start, m.start), y = Math.min(a.count, Math.min(g.start + g.count, m.start + m.count));
                for(let b = _, A = y; b < A; b += 3){
                    let L = a.getX(b), I = a.getX(b + 1), k = a.getX(b + 2);
                    o = os(this, p, e, hi, l, c, h, u, d, L, I, k), o && (o.faceIndex = Math.floor(b / 3), o.face.materialIndex = g.materialIndex, t.push(o));
                }
            }
            else {
                let x1 = Math.max(0, m.start), v1 = Math.min(a.count, m.start + m.count);
                for(let g1 = x1, p1 = v1; g1 < p1; g1 += 3){
                    let _1 = a.getX(g1), y1 = a.getX(g1 + 1), b1 = a.getX(g1 + 2);
                    o = os(this, i, e, hi, l, c, h, u, d, _1, y1, b1), o && (o.faceIndex = Math.floor(g1 / 3), t.push(o));
                }
            }
            else if (l !== void 0) if (Array.isArray(i)) for(let x2 = 0, v2 = f.length; x2 < v2; x2++){
                let g2 = f[x2], p2 = i[g2.materialIndex], _2 = Math.max(g2.start, m.start), y2 = Math.min(l.count, Math.min(g2.start + g2.count, m.start + m.count));
                for(let b2 = _2, A1 = y2; b2 < A1; b2 += 3){
                    let L1 = b2, I1 = b2 + 1, k1 = b2 + 2;
                    o = os(this, p2, e, hi, l, c, h, u, d, L1, I1, k1), o && (o.faceIndex = Math.floor(b2 / 3), o.face.materialIndex = g2.materialIndex, t.push(o));
                }
            }
            else {
                let x3 = Math.max(0, m.start), v3 = Math.min(l.count, m.start + m.count);
                for(let g3 = x3, p3 = v3; g3 < p3; g3 += 3){
                    let _3 = g3, y3 = g3 + 1, b3 = g3 + 2;
                    o = os(this, i, e, hi, l, c, h, u, d, _3, y3, b3), o && (o.faceIndex = Math.floor(g3 / 3), t.push(o));
                }
            }
        } else n.isGeometry && console.error("THREE.Mesh.raycast() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.");
    }
};
st.prototype.isMesh = !0;
function hf(s, e, t, n, i, r, o, a) {
    let l;
    if (e.side === it ? l = n.intersectTriangle(o, r, i, !0, a) : l = n.intersectTriangle(i, r, o, e.side !== Ci, a), l === null) return null;
    ss.copy(a), ss.applyMatrix4(s.matrixWorld);
    let c = t.ray.origin.distanceTo(ss);
    return c < t.near || c > t.far ? null : {
        distance: c,
        point: ss.clone(),
        object: s
    };
}
function os(s, e, t, n, i, r, o, a, l, c, h, u) {
    mn.fromBufferAttribute(i, c), gn.fromBufferAttribute(i, h), xn.fromBufferAttribute(i, u);
    let d = s.morphTargetInfluences;
    if (r && d) {
        Kr.set(0, 0, 0), es.set(0, 0, 0), ts.set(0, 0, 0);
        for(let m = 0, x = r.length; m < x; m++){
            let v = d[m], g = r[m];
            v !== 0 && (zo.fromBufferAttribute(g, c), Uo.fromBufferAttribute(g, h), Oo.fromBufferAttribute(g, u), o ? (Kr.addScaledVector(zo, v), es.addScaledVector(Uo, v), ts.addScaledVector(Oo, v)) : (Kr.addScaledVector(zo.sub(mn), v), es.addScaledVector(Uo.sub(gn), v), ts.addScaledVector(Oo.sub(xn), v)));
        }
        mn.add(Kr), gn.add(es), xn.add(ts);
    }
    s.isSkinnedMesh && (s.boneTransform(c, mn), s.boneTransform(h, gn), s.boneTransform(u, xn));
    let f = hf(s, e, t, n, mn, gn, xn, Ho);
    if (f) {
        a && (ns.fromBufferAttribute(a, c), is.fromBufferAttribute(a, h), rs.fromBufferAttribute(a, u), f.uv = nt.getUV(Ho, mn, gn, xn, ns, is, rs, new X)), l && (ns.fromBufferAttribute(l, c), is.fromBufferAttribute(l, h), rs.fromBufferAttribute(l, u), f.uv2 = nt.getUV(Ho, mn, gn, xn, ns, is, rs, new X));
        let m1 = {
            a: c,
            b: h,
            c: u,
            normal: new M,
            materialIndex: 0
        };
        nt.getNormal(mn, gn, xn, m1.normal), f.face = m1;
    }
    return f;
}
var wn = class extends _e {
    constructor(e = 1, t = 1, n = 1, i = 1, r = 1, o = 1){
        super();
        this.type = "BoxGeometry", this.parameters = {
            width: e,
            height: t,
            depth: n,
            widthSegments: i,
            heightSegments: r,
            depthSegments: o
        };
        let a = this;
        i = Math.floor(i), r = Math.floor(r), o = Math.floor(o);
        let l = [], c = [], h = [], u = [], d = 0, f = 0;
        m("z", "y", "x", -1, -1, n, t, e, o, r, 0), m("z", "y", "x", 1, -1, n, t, -e, o, r, 1), m("x", "z", "y", 1, 1, e, n, t, i, o, 2), m("x", "z", "y", 1, -1, e, n, -t, i, o, 3), m("x", "y", "z", 1, -1, e, t, n, i, r, 4), m("x", "y", "z", -1, -1, e, t, -n, i, r, 5), this.setIndex(l), this.setAttribute("position", new de(c, 3)), this.setAttribute("normal", new de(h, 3)), this.setAttribute("uv", new de(u, 2));
        function m(x, v, g, p, _, y, b, A, L, I, k) {
            let B = y / L, P = b / I, w = y / 2, E = b / 2, D = A / 2, U = L + 1, F = I + 1, O = 0, ne = 0, ce = new M;
            for(let V = 0; V < F; V++){
                let W = V * P - E;
                for(let he = 0; he < U; he++){
                    let le = he * B - w;
                    ce[x] = le * p, ce[v] = W * _, ce[g] = D, c.push(ce.x, ce.y, ce.z), ce[x] = 0, ce[v] = 0, ce[g] = A > 0 ? 1 : -1, h.push(ce.x, ce.y, ce.z), u.push(he / L), u.push(1 - V / I), O += 1;
                }
            }
            for(let V1 = 0; V1 < I; V1++)for(let W1 = 0; W1 < L; W1++){
                let he1 = d + W1 + U * V1, le1 = d + W1 + U * (V1 + 1), fe = d + (W1 + 1) + U * (V1 + 1), Be = d + (W1 + 1) + U * V1;
                l.push(he1, le1, Be), l.push(le1, fe, Be), ne += 6;
            }
            a.addGroup(f, ne, k), f += ne, d += O;
        }
    }
    static fromJSON(e) {
        return new wn(e.width, e.height, e.depth, e.widthSegments, e.heightSegments, e.depthSegments);
    }
};
function Ri(s) {
    let e = {};
    for(let t in s){
        e[t] = {};
        for(let n in s[t]){
            let i = s[t][n];
            i && (i.isColor || i.isMatrix3 || i.isMatrix4 || i.isVector2 || i.isVector3 || i.isVector4 || i.isTexture || i.isQuaternion) ? e[t][n] = i.clone() : Array.isArray(i) ? e[t][n] = i.slice() : e[t][n] = i;
        }
    }
    return e;
}
function yt(s) {
    let e = {};
    for(let t = 0; t < s.length; t++){
        let n = Ri(s[t]);
        for(let i in n)e[i] = n[i];
    }
    return e;
}
var uf = {
    clone: Ri,
    merge: yt
}, df = `void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`, ff = `void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`, sn = class extends dt {
    constructor(e){
        super();
        this.type = "ShaderMaterial", this.defines = {}, this.uniforms = {}, this.vertexShader = df, this.fragmentShader = ff, this.linewidth = 1, this.wireframe = !1, this.wireframeLinewidth = 1, this.fog = !1, this.lights = !1, this.clipping = !1, this.extensions = {
            derivatives: !1,
            fragDepth: !1,
            drawBuffers: !1,
            shaderTextureLOD: !1
        }, this.defaultAttributeValues = {
            color: [
                1,
                1,
                1
            ],
            uv: [
                0,
                0
            ],
            uv2: [
                0,
                0
            ]
        }, this.index0AttributeName = void 0, this.uniformsNeedUpdate = !1, this.glslVersion = null, e !== void 0 && (e.attributes !== void 0 && console.error("THREE.ShaderMaterial: attributes should now be defined in THREE.BufferGeometry instead."), this.setValues(e));
    }
    copy(e) {
        return super.copy(e), this.fragmentShader = e.fragmentShader, this.vertexShader = e.vertexShader, this.uniforms = Ri(e.uniforms), this.defines = Object.assign({}, e.defines), this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.lights = e.lights, this.clipping = e.clipping, this.extensions = Object.assign({}, e.extensions), this.glslVersion = e.glslVersion, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        t.glslVersion = this.glslVersion, t.uniforms = {};
        for(let i in this.uniforms){
            let o = this.uniforms[i].value;
            o && o.isTexture ? t.uniforms[i] = {
                type: "t",
                value: o.toJSON(e).uuid
            } : o && o.isColor ? t.uniforms[i] = {
                type: "c",
                value: o.getHex()
            } : o && o.isVector2 ? t.uniforms[i] = {
                type: "v2",
                value: o.toArray()
            } : o && o.isVector3 ? t.uniforms[i] = {
                type: "v3",
                value: o.toArray()
            } : o && o.isVector4 ? t.uniforms[i] = {
                type: "v4",
                value: o.toArray()
            } : o && o.isMatrix3 ? t.uniforms[i] = {
                type: "m3",
                value: o.toArray()
            } : o && o.isMatrix4 ? t.uniforms[i] = {
                type: "m4",
                value: o.toArray()
            } : t.uniforms[i] = {
                value: o
            };
        }
        Object.keys(this.defines).length > 0 && (t.defines = this.defines), t.vertexShader = this.vertexShader, t.fragmentShader = this.fragmentShader;
        let n = {};
        for(let i1 in this.extensions)this.extensions[i1] === !0 && (n[i1] = !0);
        return Object.keys(n).length > 0 && (t.extensions = n), t;
    }
};
sn.prototype.isShaderMaterial = !0;
var Ir = class extends Ne {
    constructor(){
        super();
        this.type = "Camera", this.matrixWorldInverse = new pe, this.projectionMatrix = new pe, this.projectionMatrixInverse = new pe;
    }
    copy(e, t) {
        return super.copy(e, t), this.matrixWorldInverse.copy(e.matrixWorldInverse), this.projectionMatrix.copy(e.projectionMatrix), this.projectionMatrixInverse.copy(e.projectionMatrixInverse), this;
    }
    getWorldDirection(e) {
        this.updateWorldMatrix(!0, !1);
        let t = this.matrixWorld.elements;
        return e.set(-t[8], -t[9], -t[10]).normalize();
    }
    updateMatrixWorld(e) {
        super.updateMatrixWorld(e), this.matrixWorldInverse.copy(this.matrixWorld).invert();
    }
    updateWorldMatrix(e, t) {
        super.updateWorldMatrix(e, t), this.matrixWorldInverse.copy(this.matrixWorld).invert();
    }
    clone() {
        return new this.constructor().copy(this);
    }
};
Ir.prototype.isCamera = !0;
var ut = class extends Ir {
    constructor(e = 50, t = 1, n = .1, i = 2e3){
        super();
        this.type = "PerspectiveCamera", this.fov = e, this.zoom = 1, this.near = n, this.far = i, this.focus = 10, this.aspect = t, this.view = null, this.filmGauge = 35, this.filmOffset = 0, this.updateProjectionMatrix();
    }
    copy(e, t) {
        return super.copy(e, t), this.fov = e.fov, this.zoom = e.zoom, this.near = e.near, this.far = e.far, this.focus = e.focus, this.aspect = e.aspect, this.view = e.view === null ? null : Object.assign({}, e.view), this.filmGauge = e.filmGauge, this.filmOffset = e.filmOffset, this;
    }
    setFocalLength(e) {
        let t = .5 * this.getFilmHeight() / e;
        this.fov = dr * 2 * Math.atan(t), this.updateProjectionMatrix();
    }
    getFocalLength() {
        let e = Math.tan(Wn * .5 * this.fov);
        return .5 * this.getFilmHeight() / e;
    }
    getEffectiveFOV() {
        return dr * 2 * Math.atan(Math.tan(Wn * .5 * this.fov) / this.zoom);
    }
    getFilmWidth() {
        return this.filmGauge * Math.min(this.aspect, 1);
    }
    getFilmHeight() {
        return this.filmGauge / Math.max(this.aspect, 1);
    }
    setViewOffset(e, t, n, i, r, o) {
        this.aspect = e / t, this.view === null && (this.view = {
            enabled: !0,
            fullWidth: 1,
            fullHeight: 1,
            offsetX: 0,
            offsetY: 0,
            width: 1,
            height: 1
        }), this.view.enabled = !0, this.view.fullWidth = e, this.view.fullHeight = t, this.view.offsetX = n, this.view.offsetY = i, this.view.width = r, this.view.height = o, this.updateProjectionMatrix();
    }
    clearViewOffset() {
        this.view !== null && (this.view.enabled = !1), this.updateProjectionMatrix();
    }
    updateProjectionMatrix() {
        let e = this.near, t = e * Math.tan(Wn * .5 * this.fov) / this.zoom, n = 2 * t, i = this.aspect * n, r = -.5 * i, o = this.view;
        if (this.view !== null && this.view.enabled) {
            let l = o.fullWidth, c = o.fullHeight;
            r += o.offsetX * i / l, t -= o.offsetY * n / c, i *= o.width / l, n *= o.height / c;
        }
        let a = this.filmOffset;
        a !== 0 && (r += e * a / this.getFilmWidth()), this.projectionMatrix.makePerspective(r, r + i, t, t - n, e, this.far), this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.fov = this.fov, t.object.zoom = this.zoom, t.object.near = this.near, t.object.far = this.far, t.object.focus = this.focus, t.object.aspect = this.aspect, this.view !== null && (t.object.view = Object.assign({}, this.view)), t.object.filmGauge = this.filmGauge, t.object.filmOffset = this.filmOffset, t;
    }
};
ut.prototype.isPerspectiveCamera = !0;
var ui = 90, di = 1, $s = class extends Ne {
    constructor(e, t, n){
        super();
        if (this.type = "CubeCamera", n.isWebGLCubeRenderTarget !== !0) {
            console.error("THREE.CubeCamera: The constructor now expects an instance of WebGLCubeRenderTarget as third parameter.");
            return;
        }
        this.renderTarget = n;
        let i = new ut(ui, di, e, t);
        i.layers = this.layers, i.up.set(0, -1, 0), i.lookAt(new M(1, 0, 0)), this.add(i);
        let r = new ut(ui, di, e, t);
        r.layers = this.layers, r.up.set(0, -1, 0), r.lookAt(new M(-1, 0, 0)), this.add(r);
        let o = new ut(ui, di, e, t);
        o.layers = this.layers, o.up.set(0, 0, 1), o.lookAt(new M(0, 1, 0)), this.add(o);
        let a = new ut(ui, di, e, t);
        a.layers = this.layers, a.up.set(0, 0, -1), a.lookAt(new M(0, -1, 0)), this.add(a);
        let l = new ut(ui, di, e, t);
        l.layers = this.layers, l.up.set(0, -1, 0), l.lookAt(new M(0, 0, 1)), this.add(l);
        let c = new ut(ui, di, e, t);
        c.layers = this.layers, c.up.set(0, -1, 0), c.lookAt(new M(0, 0, -1)), this.add(c);
    }
    update(e, t) {
        this.parent === null && this.updateMatrixWorld();
        let n = this.renderTarget, [i, r, o, a, l, c] = this.children, h = e.xr.enabled, u = e.getRenderTarget();
        e.xr.enabled = !1;
        let d = n.texture.generateMipmaps;
        n.texture.generateMipmaps = !1, e.setRenderTarget(n, 0), e.render(t, i), e.setRenderTarget(n, 1), e.render(t, r), e.setRenderTarget(n, 2), e.render(t, o), e.setRenderTarget(n, 3), e.render(t, a), e.setRenderTarget(n, 4), e.render(t, l), n.texture.generateMipmaps = d, e.setRenderTarget(n, 5), e.render(t, c), e.setRenderTarget(u), e.xr.enabled = h;
    }
}, ki = class extends ot {
    constructor(e, t, n, i, r, o, a, l, c, h){
        e = e !== void 0 ? e : [], t = t !== void 0 ? t : Bi;
        super(e, t, n, i, r, o, a, l, c, h);
        this.flipY = !1;
    }
    get images() {
        return this.image;
    }
    set images(e) {
        this.image = e;
    }
};
ki.prototype.isCubeTexture = !0;
var js = class extends At {
    constructor(e, t, n){
        Number.isInteger(t) && (console.warn("THREE.WebGLCubeRenderTarget: constructor signature is now WebGLCubeRenderTarget( size, options )"), t = n);
        super(e, e, t);
        t = t || {}, this.texture = new ki(void 0, t.mapping, t.wrapS, t.wrapT, t.magFilter, t.minFilter, t.format, t.type, t.anisotropy, t.encoding), this.texture.isRenderTargetTexture = !0, this.texture.generateMipmaps = t.generateMipmaps !== void 0 ? t.generateMipmaps : !1, this.texture.minFilter = t.minFilter !== void 0 ? t.minFilter : tt, this.texture._needsFlipEnvMap = !1;
    }
    fromEquirectangularTexture(e, t) {
        this.texture.type = t.type, this.texture.format = ct, this.texture.encoding = t.encoding, this.texture.generateMipmaps = t.generateMipmaps, this.texture.minFilter = t.minFilter, this.texture.magFilter = t.magFilter;
        let n = {
            uniforms: {
                tEquirect: {
                    value: null
                }
            },
            vertexShader: `

				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,
            fragmentShader: `

				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`
        }, i = new wn(5, 5, 5), r = new sn({
            name: "CubemapFromEquirect",
            uniforms: Ri(n.uniforms),
            vertexShader: n.vertexShader,
            fragmentShader: n.fragmentShader,
            side: it,
            blending: vn
        });
        r.uniforms.tEquirect.value = t;
        let o = new st(i, r), a = t.minFilter;
        return t.minFilter === Ui && (t.minFilter = tt), new $s(1, 10, this).update(e, o), t.minFilter = a, o.geometry.dispose(), o.material.dispose(), this;
    }
    clear(e, t, n, i) {
        let r = e.getRenderTarget();
        for(let o = 0; o < 6; o++)e.setRenderTarget(this, o), e.clear(t, n, i);
        e.setRenderTarget(r);
    }
};
js.prototype.isWebGLCubeRenderTarget = !0;
var ko = new M, pf = new M, mf = new lt, Wt = class {
    constructor(e = new M(1, 0, 0), t = 0){
        this.normal = e, this.constant = t;
    }
    set(e, t) {
        return this.normal.copy(e), this.constant = t, this;
    }
    setComponents(e, t, n, i) {
        return this.normal.set(e, t, n), this.constant = i, this;
    }
    setFromNormalAndCoplanarPoint(e, t) {
        return this.normal.copy(e), this.constant = -t.dot(this.normal), this;
    }
    setFromCoplanarPoints(e, t, n) {
        let i = ko.subVectors(n, t).cross(pf.subVectors(e, t)).normalize();
        return this.setFromNormalAndCoplanarPoint(i, e), this;
    }
    copy(e) {
        return this.normal.copy(e.normal), this.constant = e.constant, this;
    }
    normalize() {
        let e = 1 / this.normal.length();
        return this.normal.multiplyScalar(e), this.constant *= e, this;
    }
    negate() {
        return this.constant *= -1, this.normal.negate(), this;
    }
    distanceToPoint(e) {
        return this.normal.dot(e) + this.constant;
    }
    distanceToSphere(e) {
        return this.distanceToPoint(e.center) - e.radius;
    }
    projectPoint(e, t) {
        return t.copy(this.normal).multiplyScalar(-this.distanceToPoint(e)).add(e);
    }
    intersectLine(e, t) {
        let n = e.delta(ko), i = this.normal.dot(n);
        if (i === 0) return this.distanceToPoint(e.start) === 0 ? t.copy(e.start) : null;
        let r = -(e.start.dot(this.normal) + this.constant) / i;
        return r < 0 || r > 1 ? null : t.copy(n).multiplyScalar(r).add(e.start);
    }
    intersectsLine(e) {
        let t = this.distanceToPoint(e.start), n = this.distanceToPoint(e.end);
        return t < 0 && n > 0 || n < 0 && t > 0;
    }
    intersectsBox(e) {
        return e.intersectsPlane(this);
    }
    intersectsSphere(e) {
        return e.intersectsPlane(this);
    }
    coplanarPoint(e) {
        return e.copy(this.normal).multiplyScalar(-this.constant);
    }
    applyMatrix4(e, t) {
        let n = t || mf.getNormalMatrix(e), i = this.coplanarPoint(ko).applyMatrix4(e), r = this.normal.applyMatrix3(n).normalize();
        return this.constant = -i.dot(r), this;
    }
    translate(e) {
        return this.constant -= e.dot(this.normal), this;
    }
    equals(e) {
        return e.normal.equals(this.normal) && e.constant === this.constant;
    }
    clone() {
        return new this.constructor().copy(this);
    }
};
Wt.prototype.isPlane = !0;
var fi = new An, as = new M, Dr = class {
    constructor(e = new Wt, t = new Wt, n = new Wt, i = new Wt, r = new Wt, o = new Wt){
        this.planes = [
            e,
            t,
            n,
            i,
            r,
            o
        ];
    }
    set(e, t, n, i, r, o) {
        let a = this.planes;
        return a[0].copy(e), a[1].copy(t), a[2].copy(n), a[3].copy(i), a[4].copy(r), a[5].copy(o), this;
    }
    copy(e) {
        let t = this.planes;
        for(let n = 0; n < 6; n++)t[n].copy(e.planes[n]);
        return this;
    }
    setFromProjectionMatrix(e) {
        let t = this.planes, n = e.elements, i = n[0], r = n[1], o = n[2], a = n[3], l = n[4], c = n[5], h = n[6], u = n[7], d = n[8], f = n[9], m = n[10], x = n[11], v = n[12], g = n[13], p = n[14], _ = n[15];
        return t[0].setComponents(a - i, u - l, x - d, _ - v).normalize(), t[1].setComponents(a + i, u + l, x + d, _ + v).normalize(), t[2].setComponents(a + r, u + c, x + f, _ + g).normalize(), t[3].setComponents(a - r, u - c, x - f, _ - g).normalize(), t[4].setComponents(a - o, u - h, x - m, _ - p).normalize(), t[5].setComponents(a + o, u + h, x + m, _ + p).normalize(), this;
    }
    intersectsObject(e) {
        let t = e.geometry;
        return t.boundingSphere === null && t.computeBoundingSphere(), fi.copy(t.boundingSphere).applyMatrix4(e.matrixWorld), this.intersectsSphere(fi);
    }
    intersectsSprite(e) {
        return fi.center.set(0, 0, 0), fi.radius = .7071067811865476, fi.applyMatrix4(e.matrixWorld), this.intersectsSphere(fi);
    }
    intersectsSphere(e) {
        let t = this.planes, n = e.center, i = -e.radius;
        for(let r = 0; r < 6; r++)if (t[r].distanceToPoint(n) < i) return !1;
        return !0;
    }
    intersectsBox(e) {
        let t = this.planes;
        for(let n = 0; n < 6; n++){
            let i = t[n];
            if (as.x = i.normal.x > 0 ? e.max.x : e.min.x, as.y = i.normal.y > 0 ? e.max.y : e.min.y, as.z = i.normal.z > 0 ? e.max.z : e.min.z, i.distanceToPoint(as) < 0) return !1;
        }
        return !0;
    }
    containsPoint(e) {
        let t = this.planes;
        for(let n = 0; n < 6; n++)if (t[n].distanceToPoint(e) < 0) return !1;
        return !0;
    }
    clone() {
        return new this.constructor().copy(this);
    }
};
function rh() {
    let s = null, e = !1, t = null, n = null;
    function i(r, o) {
        t(r, o), n = s.requestAnimationFrame(i);
    }
    return {
        start: function() {
            e !== !0 && t !== null && (n = s.requestAnimationFrame(i), e = !0);
        },
        stop: function() {
            s.cancelAnimationFrame(n), e = !1;
        },
        setAnimationLoop: function(r) {
            t = r;
        },
        setContext: function(r) {
            s = r;
        }
    };
}
function gf(s, e) {
    let t = e.isWebGL2, n = new WeakMap;
    function i(c, h) {
        let u = c.array, d = c.usage, f = s.createBuffer();
        s.bindBuffer(h, f), s.bufferData(h, u, d), c.onUploadCallback();
        let m = 5126;
        return u instanceof Float32Array ? m = 5126 : u instanceof Float64Array ? console.warn("THREE.WebGLAttributes: Unsupported data buffer format: Float64Array.") : u instanceof Uint16Array ? c.isFloat16BufferAttribute ? t ? m = 5131 : console.warn("THREE.WebGLAttributes: Usage of Float16BufferAttribute requires WebGL2.") : m = 5123 : u instanceof Int16Array ? m = 5122 : u instanceof Uint32Array ? m = 5125 : u instanceof Int32Array ? m = 5124 : u instanceof Int8Array ? m = 5120 : (u instanceof Uint8Array || u instanceof Uint8ClampedArray) && (m = 5121), {
            buffer: f,
            type: m,
            bytesPerElement: u.BYTES_PER_ELEMENT,
            version: c.version
        };
    }
    function r(c, h, u) {
        let d = h.array, f = h.updateRange;
        s.bindBuffer(u, c), f.count === -1 ? s.bufferSubData(u, 0, d) : (t ? s.bufferSubData(u, f.offset * d.BYTES_PER_ELEMENT, d, f.offset, f.count) : s.bufferSubData(u, f.offset * d.BYTES_PER_ELEMENT, d.subarray(f.offset, f.offset + f.count)), f.count = -1);
    }
    function o(c) {
        return c.isInterleavedBufferAttribute && (c = c.data), n.get(c);
    }
    function a(c) {
        c.isInterleavedBufferAttribute && (c = c.data);
        let h = n.get(c);
        h && (s.deleteBuffer(h.buffer), n.delete(c));
    }
    function l(c, h) {
        if (c.isGLBufferAttribute) {
            let d = n.get(c);
            (!d || d.version < c.version) && n.set(c, {
                buffer: c.buffer,
                type: c.type,
                bytesPerElement: c.elementSize,
                version: c.version
            });
            return;
        }
        c.isInterleavedBufferAttribute && (c = c.data);
        let u = n.get(c);
        u === void 0 ? n.set(c, i(c, h)) : u.version < c.version && (r(u.buffer, c, h), u.version = c.version);
    }
    return {
        get: o,
        remove: a,
        update: l
    };
}
var Pi = class extends _e {
    constructor(e = 1, t = 1, n = 1, i = 1){
        super();
        this.type = "PlaneGeometry", this.parameters = {
            width: e,
            height: t,
            widthSegments: n,
            heightSegments: i
        };
        let r = e / 2, o = t / 2, a = Math.floor(n), l = Math.floor(i), c = a + 1, h = l + 1, u = e / a, d = t / l, f = [], m = [], x = [], v = [];
        for(let g = 0; g < h; g++){
            let p = g * d - o;
            for(let _ = 0; _ < c; _++){
                let y = _ * u - r;
                m.push(y, -p, 0), x.push(0, 0, 1), v.push(_ / a), v.push(1 - g / l);
            }
        }
        for(let g1 = 0; g1 < l; g1++)for(let p1 = 0; p1 < a; p1++){
            let _1 = p1 + c * g1, y1 = p1 + c * (g1 + 1), b = p1 + 1 + c * (g1 + 1), A = p1 + 1 + c * g1;
            f.push(_1, y1, A), f.push(y1, b, A);
        }
        this.setIndex(f), this.setAttribute("position", new de(m, 3)), this.setAttribute("normal", new de(x, 3)), this.setAttribute("uv", new de(v, 2));
    }
    static fromJSON(e) {
        return new Pi(e.width, e.height, e.widthSegments, e.heightSegments);
    }
}, xf = `#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vUv ).g;
#endif`, yf = `#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`, vf = `#ifdef USE_ALPHATEST
	if ( diffuseColor.a < alphaTest ) discard;
#endif`, _f = `#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`, Mf = `#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vUv2 ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometry.normal, geometry.viewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`, bf = `#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`, wf = "vec3 transformed = vec3( position );", Sf = `vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`, Tf = `vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );
	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );
	return 0.5 / max( gv + gl, EPSILON );
}
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );
	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0;
	return RECIPROCAL_PI * a2 / pow2( denom );
}
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 f0, const in float f90, const in float roughness ) {
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
	float D = D_GGX( alpha, dotNH );
	return F * ( V * D );
}
vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;
	float dotNV = saturate( dot( N, V ) );
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}
float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}
vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}
vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] ) {
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 );
	mat3 mat = mInv * transposeMat3( mat3( T1, T2, N ) );
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );
	return vec3( result );
}
float G_BlinnPhong_Implicit( ) {
	return 0.25;
}
float D_BlinnPhong( const in float shininess, const in float dotNH ) {
	return RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess );
}
vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( specularColor, 1.0, dotVH );
	float G = G_BlinnPhong_Implicit( );
	float D = D_BlinnPhong( shininess, dotNH );
	return F * ( G * D );
}
#if defined( USE_SHEEN )
float D_Charlie( float roughness, float dotNH ) {
	float alpha = pow2( roughness );
	float invAlpha = 1.0 / alpha;
	float cos2h = dotNH * dotNH;
	float sin2h = max( 1.0 - cos2h, 0.0078125 );
	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}
float V_Neubelt( float dotNV, float dotNL ) {
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}
vec3 BRDF_Sheen( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float D = D_Charlie( sheenRoughness, dotNH );
	float V = V_Neubelt( dotNV, dotNL );
	return sheenColor * ( D * V );
}
#endif`, Ef = `#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vUv );
		vec2 dSTdy = dFdy( vUv );
		float Hll = bumpScale * texture2D( bumpMap, vUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = vec3( dFdx( surf_pos.x ), dFdx( surf_pos.y ), dFdx( surf_pos.z ) );
		vec3 vSigmaY = vec3( dFdy( surf_pos.x ), dFdy( surf_pos.y ), dFdy( surf_pos.z ) );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`, Af = `#if NUM_CLIPPING_PLANES > 0
	vec4 plane;
	#pragma unroll_loop_start
	for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
		plane = clippingPlanes[ i ];
		if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;
	}
	#pragma unroll_loop_end
	#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
		bool clipped = true;
		#pragma unroll_loop_start
		for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;
		}
		#pragma unroll_loop_end
		if ( clipped ) discard;
	#endif
#endif`, Cf = `#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`, Lf = `#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`, Rf = `#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`, Pf = `#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`, If = `#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`, Df = `#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
	varying vec3 vColor;
#endif`, Ff = `#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif`, Nf = `#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6
#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define whiteComplement( a ) ( 1.0 - saturate( a ) )
float pow2( const in float x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 color ) { return dot( color, vec3( 0.3333 ) ); }
highp float rand( const in vec2 uv ) {
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract( sin( sn ) * c );
}
#ifdef HIGH_PRECISION
	float precisionSafeLength( vec3 v ) { return length( v ); }
#else
	float precisionSafeLength( vec3 v ) {
		float maxComponent = max3( abs( v ) );
		return length( v / maxComponent ) * maxComponent;
	}
#endif
struct IncidentLight {
	vec3 color;
	vec3 direction;
	bool visible;
};
struct ReflectedLight {
	vec3 directDiffuse;
	vec3 directSpecular;
	vec3 indirectDiffuse;
	vec3 indirectSpecular;
};
struct GeometricContext {
	vec3 position;
	vec3 normal;
	vec3 viewDir;
#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal;
#endif
};
vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}
vec3 inverseTransformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( vec4( dir, 0.0 ) * matrix ).xyz );
}
mat3 transposeMat3( const in mat3 m ) {
	mat3 tmp;
	tmp[ 0 ] = vec3( m[ 0 ].x, m[ 1 ].x, m[ 2 ].x );
	tmp[ 1 ] = vec3( m[ 0 ].y, m[ 1 ].y, m[ 2 ].y );
	tmp[ 2 ] = vec3( m[ 0 ].z, m[ 1 ].z, m[ 2 ].z );
	return tmp;
}
float linearToRelativeLuminance( const in vec3 color ) {
	vec3 weights = vec3( 0.2126, 0.7152, 0.0722 );
	return dot( weights, color.rgb );
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}`, Bf = `#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_maxMipLevel 8.0
	#define cubeUV_minMipLevel 4.0
	#define cubeUV_maxTileSize 256.0
	#define cubeUV_minTileSize 16.0
	float getFace( vec3 direction ) {
		vec3 absDirection = abs( direction );
		float face = - 1.0;
		if ( absDirection.x > absDirection.z ) {
			if ( absDirection.x > absDirection.y )
				face = direction.x > 0.0 ? 0.0 : 3.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		} else {
			if ( absDirection.z > absDirection.y )
				face = direction.z > 0.0 ? 2.0 : 5.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		}
		return face;
	}
	vec2 getUV( vec3 direction, float face ) {
		vec2 uv;
		if ( face == 0.0 ) {
			uv = vec2( direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 1.0 ) {
			uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
		} else if ( face == 2.0 ) {
			uv = vec2( - direction.x, direction.y ) / abs( direction.z );
		} else if ( face == 3.0 ) {
			uv = vec2( - direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 4.0 ) {
			uv = vec2( - direction.x, direction.z ) / abs( direction.y );
		} else {
			uv = vec2( direction.x, direction.y ) / abs( direction.z );
		}
		return 0.5 * ( uv + 1.0 );
	}
	vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
		float face = getFace( direction );
		float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
		mipInt = max( mipInt, cubeUV_minMipLevel );
		float faceSize = exp2( mipInt );
		float texelSize = 1.0 / ( 3.0 * cubeUV_maxTileSize );
		vec2 uv = getUV( direction, face ) * ( faceSize - 1.0 ) + 0.5;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		if ( mipInt < cubeUV_maxMipLevel ) {
			uv.y += 2.0 * cubeUV_maxTileSize;
		}
		uv.y += filterInt * 2.0 * cubeUV_minTileSize;
		uv.x += 3.0 * max( 0.0, cubeUV_maxTileSize - 2.0 * faceSize );
		uv *= texelSize;
		return texture2D( envMap, uv ).rgb;
	}
	#define r0 1.0
	#define v0 0.339
	#define m0 - 2.0
	#define r1 0.8
	#define v1 0.276
	#define m1 - 1.0
	#define r4 0.4
	#define v4 0.046
	#define m4 2.0
	#define r5 0.305
	#define v5 0.016
	#define m5 3.0
	#define r6 0.21
	#define v6 0.0038
	#define m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= r1 ) {
			mip = ( r0 - roughness ) * ( m1 - m0 ) / ( r0 - r1 ) + m0;
		} else if ( roughness >= r4 ) {
			mip = ( r1 - roughness ) * ( m4 - m1 ) / ( r1 - r4 ) + m1;
		} else if ( roughness >= r5 ) {
			mip = ( r4 - roughness ) * ( m5 - m4 ) / ( r4 - r5 ) + m4;
		} else if ( roughness >= r6 ) {
			mip = ( r5 - roughness ) * ( m6 - m5 ) / ( r5 - r6 ) + m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), m0, cubeUV_maxMipLevel );
		float mipF = fract( mip );
		float mipInt = floor( mip );
		vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
		if ( mipF == 0.0 ) {
			return vec4( color0, 1.0 );
		} else {
			vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
			return vec4( mix( color0, color1, mipF ), 1.0 );
		}
	}
#endif`, zf = `vec3 transformedNormal = objectNormal;
#ifdef USE_INSTANCING
	mat3 m = mat3( instanceMatrix );
	transformedNormal /= vec3( dot( m[ 0 ], m[ 0 ] ), dot( m[ 1 ], m[ 1 ] ), dot( m[ 2 ], m[ 2 ] ) );
	transformedNormal = m * transformedNormal;
#endif
transformedNormal = normalMatrix * transformedNormal;
#ifdef FLIP_SIDED
	transformedNormal = - transformedNormal;
#endif
#ifdef USE_TANGENT
	vec3 transformedTangent = ( modelViewMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#ifdef FLIP_SIDED
		transformedTangent = - transformedTangent;
	#endif
#endif`, Uf = `#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`, Of = `#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vUv ).x * displacementScale + displacementBias );
#endif`, Hf = `#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vUv );
	emissiveColor.rgb = emissiveMapTexelToLinear( emissiveColor ).rgb;
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`, kf = `#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`, Gf = "gl_FragColor = linearToOutputTexel( gl_FragColor );", Vf = `vec4 LinearToLinear( in vec4 value ) {
	return value;
}
vec4 sRGBToLinear( in vec4 value ) {
	return vec4( mix( pow( value.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), value.rgb * 0.0773993808, vec3( lessThanEqual( value.rgb, vec3( 0.04045 ) ) ) ), value.a );
}
vec4 LinearTosRGB( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`, Wf = `#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vec3 cameraToFrag;
		if ( isOrthographic ) {
			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToFrag = normalize( vWorldPosition - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vec3 reflectVec = reflect( cameraToFrag, worldNormal );
		#else
			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
		#endif
	#else
		vec3 reflectVec = vReflect;
	#endif
	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );
		envColor = envMapTexelToLinear( envColor );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 envColor = textureCubeUV( envMap, reflectVec, 0.0 );
	#else
		vec4 envColor = vec4( 0.0 );
	#endif
	#ifdef ENVMAP_BLENDING_MULTIPLY
		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_MIX )
		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_ADD )
		outgoingLight += envColor.xyz * specularStrength * reflectivity;
	#endif
#endif`, qf = `#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`, Xf = `#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`, Jf = `#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) ||defined( PHONG )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`, Yf = `#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vWorldPosition = worldPosition.xyz;
	#else
		vec3 cameraToVertex;
		if ( isOrthographic ) {
			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vReflect = reflect( cameraToVertex, worldNormal );
		#else
			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
		#endif
	#endif
#endif`, Zf = `#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`, $f = `#ifdef USE_FOG
	varying float vFogDepth;
#endif`, jf = `#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`, Qf = `#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`, Kf = `#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		return ( coord.x < 0.7 ) ? vec3( 0.7 ) : vec3( 1.0 );
	#endif
}`, ep = `#ifdef USE_LIGHTMAP
	vec4 lightMapTexel = texture2D( lightMap, vUv2 );
	vec3 lightMapIrradiance = lightMapTexelToLinear( lightMapTexel ).rgb * lightMapIntensity;
	#ifndef PHYSICALLY_CORRECT_LIGHTS
		lightMapIrradiance *= PI;
	#endif
	reflectedLight.indirectDiffuse += lightMapIrradiance;
#endif`, tp = `#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`, np = `vec3 diffuse = vec3( 1.0 );
GeometricContext geometry;
geometry.position = mvPosition.xyz;
geometry.normal = normalize( transformedNormal );
geometry.viewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( -mvPosition.xyz );
GeometricContext backGeometry;
backGeometry.position = geometry.position;
backGeometry.normal = -geometry.normal;
backGeometry.viewDir = geometry.viewDir;
vLightFront = vec3( 0.0 );
vIndirectFront = vec3( 0.0 );
#ifdef DOUBLE_SIDED
	vLightBack = vec3( 0.0 );
	vIndirectBack = vec3( 0.0 );
#endif
IncidentLight directLight;
float dotNL;
vec3 directLightColor_Diffuse;
vIndirectFront += getAmbientLightIrradiance( ambientLightColor );
vIndirectFront += getLightProbeIrradiance( lightProbe, geometry.normal );
#ifdef DOUBLE_SIDED
	vIndirectBack += getAmbientLightIrradiance( ambientLightColor );
	vIndirectBack += getLightProbeIrradiance( lightProbe, backGeometry.normal );
#endif
#if NUM_POINT_LIGHTS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		getPointLightInfo( pointLights[ i ], geometry, directLight );
		dotNL = dot( geometry.normal, directLight.direction );
		directLightColor_Diffuse = directLight.color;
		vLightFront += saturate( dotNL ) * directLightColor_Diffuse;
		#ifdef DOUBLE_SIDED
			vLightBack += saturate( - dotNL ) * directLightColor_Diffuse;
		#endif
	}
	#pragma unroll_loop_end
#endif
#if NUM_SPOT_LIGHTS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		getSpotLightInfo( spotLights[ i ], geometry, directLight );
		dotNL = dot( geometry.normal, directLight.direction );
		directLightColor_Diffuse = directLight.color;
		vLightFront += saturate( dotNL ) * directLightColor_Diffuse;
		#ifdef DOUBLE_SIDED
			vLightBack += saturate( - dotNL ) * directLightColor_Diffuse;
		#endif
	}
	#pragma unroll_loop_end
#endif
#if NUM_DIR_LIGHTS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		getDirectionalLightInfo( directionalLights[ i ], geometry, directLight );
		dotNL = dot( geometry.normal, directLight.direction );
		directLightColor_Diffuse = directLight.color;
		vLightFront += saturate( dotNL ) * directLightColor_Diffuse;
		#ifdef DOUBLE_SIDED
			vLightBack += saturate( - dotNL ) * directLightColor_Diffuse;
		#endif
	}
	#pragma unroll_loop_end
#endif
#if NUM_HEMI_LIGHTS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
		vIndirectFront += getHemisphereLightIrradiance( hemisphereLights[ i ], geometry.normal );
		#ifdef DOUBLE_SIDED
			vIndirectBack += getHemisphereLightIrradiance( hemisphereLights[ i ], backGeometry.normal );
		#endif
	}
	#pragma unroll_loop_end
#endif`, ip = `uniform bool receiveShadow;
uniform vec3 ambientLightColor;
uniform vec3 lightProbe[ 9 ];
vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
	float x = normal.x, y = normal.y, z = normal.z;
	vec3 result = shCoefficients[ 0 ] * 0.886227;
	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );
	return result;
}
vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
	vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
	vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
	return irradiance;
}
vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
	vec3 irradiance = ambientLightColor;
	return irradiance;
}
float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
	#if defined ( PHYSICALLY_CORRECT_LIGHTS )
		float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
		if ( cutoffDistance > 0.0 ) {
			distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
		}
		return distanceFalloff;
	#else
		if ( cutoffDistance > 0.0 && decayExponent > 0.0 ) {
			return pow( saturate( - lightDistance / cutoffDistance + 1.0 ), decayExponent );
		}
		return 1.0;
	#endif
}
float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
	return smoothstep( coneCosine, penumbraCosine, angleCosine );
}
#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;
	};
	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, const in GeometricContext geometry, out IncidentLight light ) {
		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;
	}
#endif
#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;
	};
	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];
	void getPointLightInfo( const in PointLight pointLight, const in GeometricContext geometry, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometry.position;
		light.direction = normalize( lVector );
		float lightDistance = length( lVector );
		light.color = pointLight.color;
		light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
		light.visible = ( light.color != vec3( 0.0 ) );
	}
#endif
#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;
	};
	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];
	void getSpotLightInfo( const in SpotLight spotLight, const in GeometricContext geometry, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometry.position;
		light.direction = normalize( lVector );
		float angleCos = dot( light.direction, spotLight.direction );
		float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
		if ( spotAttenuation > 0.0 ) {
			float lightDistance = length( lVector );
			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
			light.visible = ( light.color != vec3( 0.0 ) );
		} else {
			light.color = vec3( 0.0 );
			light.visible = false;
		}
	}
#endif
#if NUM_RECT_AREA_LIGHTS > 0
	struct RectAreaLight {
		vec3 color;
		vec3 position;
		vec3 halfWidth;
		vec3 halfHeight;
	};
	uniform sampler2D ltc_1;	uniform sampler2D ltc_2;
	uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
#endif
#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};
	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];
	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
		float dotNL = dot( normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
		return irradiance;
	}
#endif`, rp = `#if defined( USE_ENVMAP )
	#ifdef ENVMAP_MODE_REFRACTION
		uniform float refractionRatio;
	#endif
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#if defined( ENVMAP_TYPE_CUBE_UV )
			vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#if defined( ENVMAP_TYPE_CUBE_UV )
			vec3 reflectVec;
			#ifdef ENVMAP_MODE_REFLECTION
				reflectVec = reflect( - viewDir, normal );
				reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
			#else
				reflectVec = refract( - viewDir, normal, refractionRatio );
			#endif
			reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
#endif`, sp = `ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`, op = `varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in GeometricContext geometry, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometry.normal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in GeometricContext geometry, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon
#define Material_LightProbeLOD( material )	(0)`, ap = `BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`, lp = `varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in GeometricContext geometry, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometry.normal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometry.viewDir, geometry.normal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in GeometricContext geometry, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong
#define Material_LightProbeLOD( material )	(0)`, cp = `PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( geometryNormal ) ), abs( dFdy( geometryNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	#ifdef SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULARINTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vUv ).a;
		#endif
		#ifdef USE_SPECULARCOLORMAP
			specularColorFactor *= specularColorMapTexelToLinear( texture2D( specularColorMap, vUv ) ).rgb;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = mix( min( pow2( ( ior - 1.0 ) / ( ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );
	material.specularF90 = 1.0;
#endif
#ifdef USE_CLEARCOAT
	material.clearcoat = clearcoat;
	material.clearcoatRoughness = clearcoatRoughness;
	material.clearcoatF0 = vec3( 0.04 );
	material.clearcoatF90 = 1.0;
	#ifdef USE_CLEARCOATMAP
		material.clearcoat *= texture2D( clearcoatMap, vUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEENCOLORMAP
		material.sheenColor *= sheenColorMapTexelToLinear( texture2D( sheenColorMap, vUv ) ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );
	#ifdef USE_SHEENROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vUv ).a;
	#endif
#endif`, hp = `struct PhysicalMaterial {
	vec3 diffuseColor;
	float roughness;
	vec3 specularColor;
	float specularF90;
	#ifdef USE_CLEARCOAT
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
};
vec3 clearcoatSpecular = vec3( 0.0 );
vec3 sheenSpecular = vec3( 0.0 );
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness) {
	float dotNV = saturate( dot( normal, viewDir ) );
	float r2 = roughness * roughness;
	float a = roughness < 0.25 ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;
	float b = roughness < 0.25 ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;
	float DG = exp( a * dotNV + b ) + ( roughness < 0.25 ? 0.0 : 0.1 * ( roughness - 0.25 ) );
	return saturate( DG * RECIPROCAL_PI );
}
vec2 DFGApprox( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	const vec4 c0 = vec4( - 1, - 0.0275, - 0.572, 0.022 );
	const vec4 c1 = vec4( 1, 0.0425, 1.04, - 0.04 );
	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;
	vec2 fab = vec2( - 1.04, 1.04 ) * a004 + r.zw;
	return fab;
}
vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness ) {
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	return specularColor * fab.x + specularF90 * fab.y;
}
void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	vec3 FssEss = specularColor * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = specularColor + ( 1.0 - specularColor ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometry.normal;
		vec3 viewDir = geometry.viewDir;
		vec3 position = geometry.position;
		vec3 lightPos = rectAreaLight.position;
		vec3 halfWidth = rectAreaLight.halfWidth;
		vec3 halfHeight = rectAreaLight.halfHeight;
		vec3 lightColor = rectAreaLight.color;
		float roughness = material.roughness;
		vec3 rectCoords[ 4 ];
		rectCoords[ 0 ] = lightPos + halfWidth - halfHeight;		rectCoords[ 1 ] = lightPos - halfWidth - halfHeight;
		rectCoords[ 2 ] = lightPos - halfWidth + halfHeight;
		rectCoords[ 3 ] = lightPos + halfWidth + halfHeight;
		vec2 uv = LTC_Uv( normal, viewDir, roughness );
		vec4 t1 = texture2D( ltc_1, uv );
		vec4 t2 = texture2D( ltc_2, uv );
		mat3 mInv = mat3(
			vec3( t1.x, 0, t1.y ),
			vec3(    0, 1,    0 ),
			vec3( t1.z, 0, t1.w )
		);
		vec3 fresnel = ( material.specularColor * t2.x + ( vec3( 1.0 ) - material.specularColor ) * t2.y );
		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );
		reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords );
	}
#endif
void RE_Direct_Physical( const in IncidentLight directLight, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometry.normal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometry.clearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecular += ccIrradiance * BRDF_GGX( directLight.direction, geometry.viewDir, geometry.clearcoatNormal, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecular += irradiance * BRDF_Sheen( directLight.direction, geometry.viewDir, geometry.normal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometry.viewDir, geometry.normal, material.specularColor, material.specularF90, material.roughness );
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecular += clearcoatRadiance * EnvironmentBRDF( geometry.clearcoatNormal, geometry.viewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecular += irradiance * material.sheenColor * IBLSheenBRDF( geometry.normal, geometry.viewDir, material.sheenRoughness );
	#endif
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	computeMultiscattering( geometry.normal, geometry.viewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
	vec3 diffuse = material.diffuseColor * ( 1.0 - ( singleScattering + multiScattering ) );
	reflectedLight.indirectSpecular += radiance * singleScattering;
	reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;
	reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}
#define RE_Direct				RE_Direct_Physical
#define RE_Direct_RectArea		RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness ) {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}`, up = `
GeometricContext geometry;
geometry.position = - vViewPosition;
geometry.normal = normal;
geometry.viewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
#ifdef USE_CLEARCOAT
	geometry.clearcoatNormal = clearcoatNormal;
#endif
IncidentLight directLight;
#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		pointLight = pointLights[ i ];
		getPointLightInfo( pointLight, geometry, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= all( bvec2( directLight.visible, receiveShadow ) ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometry, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometry, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= all( bvec2( directLight.visible, receiveShadow ) ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometry, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		directionalLight = directionalLights[ i ];
		getDirectionalLightInfo( directionalLight, geometry, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= all( bvec2( directLight.visible, receiveShadow ) ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometry, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometry, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	irradiance += getLightProbeIrradiance( lightProbe, geometry.normal );
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometry.normal );
		}
		#pragma unroll_loop_end
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`, dp = `#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vUv2 );
		vec3 lightMapIrradiance = lightMapTexelToLinear( lightMapTexel ).rgb * lightMapIntensity;
		#ifndef PHYSICALLY_CORRECT_LIGHTS
			lightMapIrradiance *= PI;
		#endif
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometry.normal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	radiance += getIBLRadiance( geometry.viewDir, geometry.normal, material.roughness );
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometry.viewDir, geometry.clearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`, fp = `#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometry, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometry, material, reflectedLight );
#endif`, pp = `#if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )
	gl_FragDepthEXT = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`, mp = `#if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`, gp = `#ifdef USE_LOGDEPTHBUF
	#ifdef USE_LOGDEPTHBUF_EXT
		varying float vFragDepth;
		varying float vIsPerspective;
	#else
		uniform float logDepthBufFC;
	#endif
#endif`, xp = `#ifdef USE_LOGDEPTHBUF
	#ifdef USE_LOGDEPTHBUF_EXT
		vFragDepth = 1.0 + gl_Position.w;
		vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
	#else
		if ( isPerspectiveMatrix( projectionMatrix ) ) {
			gl_Position.z = log2( max( EPSILON, gl_Position.w + 1.0 ) ) * logDepthBufFC - 1.0;
			gl_Position.z *= gl_Position.w;
		}
	#endif
#endif`, yp = `#ifdef USE_MAP
	vec4 texelColor = texture2D( map, vUv );
	texelColor = mapTexelToLinear( texelColor );
	diffuseColor *= texelColor;
#endif`, vp = `#ifdef USE_MAP
	uniform sampler2D map;
#endif`, _p = `#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
#endif
#ifdef USE_MAP
	vec4 mapTexel = texture2D( map, uv );
	diffuseColor *= mapTexelToLinear( mapTexel );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`, Mp = `#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	uniform mat3 uvTransform;
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`, bp = `float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vUv );
	metalnessFactor *= texelMetalness.b;
#endif`, wp = `#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`, Sp = `#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	#ifdef MORPHTARGETS_TEXTURE
		for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
			if ( morphTargetInfluences[ i ] > 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1, 2 ) * morphTargetInfluences[ i ];
		}
	#else
		objectNormal += morphNormal0 * morphTargetInfluences[ 0 ];
		objectNormal += morphNormal1 * morphTargetInfluences[ 1 ];
		objectNormal += morphNormal2 * morphTargetInfluences[ 2 ];
		objectNormal += morphNormal3 * morphTargetInfluences[ 3 ];
	#endif
#endif`, Tp = `#ifdef USE_MORPHTARGETS
	uniform float morphTargetBaseInfluence;
	#ifdef MORPHTARGETS_TEXTURE
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
		uniform sampler2DArray morphTargetsTexture;
		uniform vec2 morphTargetsTextureSize;
		vec3 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset, const in int stride ) {
			float texelIndex = float( vertexIndex * stride + offset );
			float y = floor( texelIndex / morphTargetsTextureSize.x );
			float x = texelIndex - y * morphTargetsTextureSize.x;
			vec3 morphUV = vec3( ( x + 0.5 ) / morphTargetsTextureSize.x, y / morphTargetsTextureSize.y, morphTargetIndex );
			return texture( morphTargetsTexture, morphUV ).xyz;
		}
	#else
		#ifndef USE_MORPHNORMALS
			uniform float morphTargetInfluences[ 8 ];
		#else
			uniform float morphTargetInfluences[ 4 ];
		#endif
	#endif
#endif`, Ep = `#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	#ifdef MORPHTARGETS_TEXTURE
		for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
			#ifndef USE_MORPHNORMALS
				if ( morphTargetInfluences[ i ] > 0.0 ) transformed += getMorph( gl_VertexID, i, 0, 1 ) * morphTargetInfluences[ i ];
			#else
				if ( morphTargetInfluences[ i ] > 0.0 ) transformed += getMorph( gl_VertexID, i, 0, 2 ) * morphTargetInfluences[ i ];
			#endif
		}
	#else
		transformed += morphTarget0 * morphTargetInfluences[ 0 ];
		transformed += morphTarget1 * morphTargetInfluences[ 1 ];
		transformed += morphTarget2 * morphTargetInfluences[ 2 ];
		transformed += morphTarget3 * morphTargetInfluences[ 3 ];
		#ifndef USE_MORPHNORMALS
			transformed += morphTarget4 * morphTargetInfluences[ 4 ];
			transformed += morphTarget5 * morphTargetInfluences[ 5 ];
			transformed += morphTarget6 * morphTargetInfluences[ 6 ];
			transformed += morphTarget7 * morphTargetInfluences[ 7 ];
		#endif
	#endif
#endif`, Ap = `float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = vec3( dFdx( vViewPosition.x ), dFdx( vViewPosition.y ), dFdx( vViewPosition.z ) );
	vec3 fdy = vec3( dFdy( vViewPosition.x ), dFdy( vViewPosition.y ), dFdy( vViewPosition.z ) );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	#ifdef USE_TANGENT
		vec3 tangent = normalize( vTangent );
		vec3 bitangent = normalize( vBitangent );
		#ifdef DOUBLE_SIDED
			tangent = tangent * faceDirection;
			bitangent = bitangent * faceDirection;
		#endif
		#if defined( TANGENTSPACE_NORMALMAP ) || defined( USE_CLEARCOAT_NORMALMAP )
			mat3 vTBN = mat3( tangent, bitangent, normal );
		#endif
	#endif
#endif
vec3 geometryNormal = normal;`, Cp = `#ifdef OBJECTSPACE_NORMALMAP
	normal = texture2D( normalMap, vUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( TANGENTSPACE_NORMALMAP )
	vec3 mapN = texture2D( normalMap, vUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;
	#ifdef USE_TANGENT
		normal = normalize( vTBN * mapN );
	#else
		normal = perturbNormal2Arb( - vViewPosition, normal, mapN, faceDirection );
	#endif
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`, Lp = `#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`, Rp = `#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`, Pp = `#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`, Ip = `#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef OBJECTSPACE_NORMALMAP
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( TANGENTSPACE_NORMALMAP ) || defined ( USE_CLEARCOAT_NORMALMAP ) )
	vec3 perturbNormal2Arb( vec3 eye_pos, vec3 surf_norm, vec3 mapN, float faceDirection ) {
		vec3 q0 = vec3( dFdx( eye_pos.x ), dFdx( eye_pos.y ), dFdx( eye_pos.z ) );
		vec3 q1 = vec3( dFdy( eye_pos.x ), dFdy( eye_pos.y ), dFdy( eye_pos.z ) );
		vec2 st0 = dFdx( vUv.st );
		vec2 st1 = dFdy( vUv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : faceDirection * inversesqrt( det );
		return normalize( T * ( mapN.x * scale ) + B * ( mapN.y * scale ) + N * mapN.z );
	}
#endif`, Dp = `#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = geometryNormal;
#endif`, Fp = `#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	#ifdef USE_TANGENT
		clearcoatNormal = normalize( vTBN * clearcoatMapN );
	#else
		clearcoatNormal = perturbNormal2Arb( - vViewPosition, clearcoatNormal, clearcoatMapN, faceDirection );
	#endif
#endif`, Np = `#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif`, Bp = `#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= transmissionAlpha + 0.1;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`, zp = `vec3 packNormalToRGB( const in vec3 normal ) {
	return normalize( normal ) * 0.5 + 0.5;
}
vec3 unpackRGBToNormal( const in vec3 rgb ) {
	return 2.0 * rgb.xyz - 1.0;
}
const float PackUpscale = 256. / 255.;const float UnpackDownscale = 255. / 256.;
const vec3 PackFactors = vec3( 256. * 256. * 256., 256. * 256., 256. );
const vec4 UnpackFactors = UnpackDownscale / vec4( PackFactors, 1. );
const float ShiftRight8 = 1. / 256.;
vec4 packDepthToRGBA( const in float v ) {
	vec4 r = vec4( fract( v * PackFactors ), v );
	r.yzw -= r.xyz * ShiftRight8;	return r * PackUpscale;
}
float unpackRGBAToDepth( const in vec4 v ) {
	return dot( v, UnpackFactors );
}
vec4 pack2HalfToRGBA( vec2 v ) {
	vec4 r = vec4( v.x, fract( v.x * 255.0 ), v.y, fract( v.y * 255.0 ) );
	return vec4( r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w );
}
vec2 unpackRGBATo2Half( vec4 v ) {
	return vec2( v.x + ( v.y / 255.0 ), v.z + ( v.w / 255.0 ) );
}
float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far ) {
	return ( viewZ + near ) / ( near - far );
}
float orthographicDepthToViewZ( const in float linearClipZ, const in float near, const in float far ) {
	return linearClipZ * ( near - far ) - near;
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float invClipZ, const in float near, const in float far ) {
	return ( near * far ) / ( ( far - near ) * invClipZ - far );
}`, Up = `#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`, Op = `vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`, Hp = `#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`, kp = `#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`, Gp = `float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vUv );
	roughnessFactor *= texelRoughness.g;
#endif`, Vp = `#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`, Wp = `#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform sampler2D directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		uniform sampler2D spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		varying vec4 vSpotShadowCoord[ NUM_SPOT_LIGHT_SHADOWS ];
		struct SpotLightShadow {
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform sampler2D pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
	float texture2DCompare( sampler2D depths, vec2 uv, float compare ) {
		return step( compare, unpackRGBAToDepth( texture2D( depths, uv ) ) );
	}
	vec2 texture2DDistribution( sampler2D shadow, vec2 uv ) {
		return unpackRGBATo2Half( texture2D( shadow, uv ) );
	}
	float VSMShadow (sampler2D shadow, vec2 uv, float compare ){
		float occlusion = 1.0;
		vec2 distribution = texture2DDistribution( shadow, uv );
		float hard_shadow = step( compare , distribution.x );
		if (hard_shadow != 1.0 ) {
			float distance = compare - distribution.x ;
			float variance = max( 0.00000, distribution.y * distribution.y );
			float softness_probability = variance / (variance + distance * distance );			softness_probability = clamp( ( softness_probability - 0.3 ) / ( 0.95 - 0.3 ), 0.0, 1.0 );			occlusion = clamp( max( hard_shadow, softness_probability ), 0.0, 1.0 );
		}
		return occlusion;
	}
	float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
		float shadow = 1.0;
		shadowCoord.xyz /= shadowCoord.w;
		shadowCoord.z += shadowBias;
		bvec4 inFrustumVec = bvec4 ( shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0 );
		bool inFrustum = all( inFrustumVec );
		bvec2 frustumTestVec = bvec2( inFrustum, shadowCoord.z <= 1.0 );
		bool frustumTest = all( frustumTestVec );
		if ( frustumTest ) {
		#if defined( SHADOWMAP_TYPE_PCF )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx0 = - texelSize.x * shadowRadius;
			float dy0 = - texelSize.y * shadowRadius;
			float dx1 = + texelSize.x * shadowRadius;
			float dy1 = + texelSize.y * shadowRadius;
			float dx2 = dx0 / 2.0;
			float dy2 = dy0 / 2.0;
			float dx3 = dx1 / 2.0;
			float dy3 = dy1 / 2.0;
			shadow = (
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy1 ), shadowCoord.z )
			) * ( 1.0 / 17.0 );
		#elif defined( SHADOWMAP_TYPE_PCF_SOFT )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx = texelSize.x;
			float dy = texelSize.y;
			vec2 uv = shadowCoord.xy;
			vec2 f = fract( uv * shadowMapSize + 0.5 );
			uv -= f * texelSize;
			shadow = (
				texture2DCompare( shadowMap, uv, shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( dx, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( 0.0, dy ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + texelSize, shadowCoord.z ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, 0.0 ), shadowCoord.z ), 
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 0.0 ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, dy ), shadowCoord.z ), 
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, dy ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( 0.0, -dy ), shadowCoord.z ), 
					 texture2DCompare( shadowMap, uv + vec2( 0.0, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( texture2DCompare( shadowMap, uv + vec2( dx, -dy ), shadowCoord.z ), 
					 texture2DCompare( shadowMap, uv + vec2( dx, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( mix( texture2DCompare( shadowMap, uv + vec2( -dx, -dy ), shadowCoord.z ), 
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, -dy ), shadowCoord.z ),
						  f.x ),
					 mix( texture2DCompare( shadowMap, uv + vec2( -dx, 2.0 * dy ), shadowCoord.z ), 
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 2.0 * dy ), shadowCoord.z ),
						  f.x ),
					 f.y )
			) * ( 1.0 / 9.0 );
		#elif defined( SHADOWMAP_TYPE_VSM )
			shadow = VSMShadow( shadowMap, shadowCoord.xy, shadowCoord.z );
		#else
			shadow = texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z );
		#endif
		}
		return shadow;
	}
	vec2 cubeToUV( vec3 v, float texelSizeY ) {
		vec3 absV = abs( v );
		float scaleToCube = 1.0 / max( absV.x, max( absV.y, absV.z ) );
		absV *= scaleToCube;
		v *= scaleToCube * ( 1.0 - 2.0 * texelSizeY );
		vec2 planar = v.xy;
		float almostATexel = 1.5 * texelSizeY;
		float almostOne = 1.0 - almostATexel;
		if ( absV.z >= almostOne ) {
			if ( v.z > 0.0 )
				planar.x = 4.0 - v.x;
		} else if ( absV.x >= almostOne ) {
			float signX = sign( v.x );
			planar.x = v.z * signX + 2.0 * signX;
		} else if ( absV.y >= almostOne ) {
			float signY = sign( v.y );
			planar.x = v.x + 2.0 * signY + 2.0;
			planar.y = v.z * signY - 2.0;
		}
		return vec2( 0.125, 0.25 ) * planar + vec2( 0.375, 0.75 );
	}
	float getPointShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		vec2 texelSize = vec2( 1.0 ) / ( shadowMapSize * vec2( 4.0, 2.0 ) );
		vec3 lightToPosition = shadowCoord.xyz;
		float dp = ( length( lightToPosition ) - shadowCameraNear ) / ( shadowCameraFar - shadowCameraNear );		dp += shadowBias;
		vec3 bd3D = normalize( lightToPosition );
		#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )
			vec2 offset = vec2( - 1, 1 ) * shadowRadius * texelSize.y;
			return (
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyy, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyy, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyx, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyx, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxy, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxy, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxx, texelSize.y ), dp ) +
				texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxx, texelSize.y ), dp )
			) * ( 1.0 / 9.0 );
		#else
			return texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp );
		#endif
	}
#endif`, qp = `#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		uniform mat4 spotShadowMatrix[ NUM_SPOT_LIGHT_SHADOWS ];
		varying vec4 vSpotShadowCoord[ NUM_SPOT_LIGHT_SHADOWS ];
		struct SpotLightShadow {
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
#endif`, Xp = `#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0 || NUM_SPOT_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0
		vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
		vec4 shadowWorldPosition;
	#endif
	#if NUM_DIR_LIGHT_SHADOWS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
		vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias, 0 );
		vSpotShadowCoord[ i ] = spotShadowMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );
		vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
	#endif
#endif`, Jp = `float getShadowMask() {
	float shadow = 1.0;
	#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		directionalLight = directionalLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		spotLight = spotLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowBias, spotLight.shadowRadius, vSpotShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		pointLight = pointLightShadows[ i ];
		shadow *= receiveShadow ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ], pointLight.shadowCameraNear, pointLight.shadowCameraFar ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#endif
	return shadow;
}`, Yp = `#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`, Zp = `#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
	#ifdef BONE_TEXTURE
		uniform highp sampler2D boneTexture;
		uniform int boneTextureSize;
		mat4 getBoneMatrix( const in float i ) {
			float j = i * 4.0;
			float x = mod( j, float( boneTextureSize ) );
			float y = floor( j / float( boneTextureSize ) );
			float dx = 1.0 / float( boneTextureSize );
			float dy = 1.0 / float( boneTextureSize );
			y = dy * ( y + 0.5 );
			vec4 v1 = texture2D( boneTexture, vec2( dx * ( x + 0.5 ), y ) );
			vec4 v2 = texture2D( boneTexture, vec2( dx * ( x + 1.5 ), y ) );
			vec4 v3 = texture2D( boneTexture, vec2( dx * ( x + 2.5 ), y ) );
			vec4 v4 = texture2D( boneTexture, vec2( dx * ( x + 3.5 ), y ) );
			mat4 bone = mat4( v1, v2, v3, v4 );
			return bone;
		}
	#else
		uniform mat4 boneMatrices[ MAX_BONES ];
		mat4 getBoneMatrix( const in float i ) {
			mat4 bone = boneMatrices[ int(i) ];
			return bone;
		}
	#endif
#endif`, $p = `#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`, jp = `#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;
	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
	#ifdef USE_TANGENT
		objectTangent = vec4( skinMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#endif
#endif`, Qp = `float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`, Kp = `#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`, em = `#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`, tm = `#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return toneMappingExposure * color;
}
vec3 ReinhardToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 OptimizedCineonToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	color = max( vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
	vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
	vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
	const mat3 ACESInputMat = mat3(
		vec3( 0.59719, 0.07600, 0.02840 ),		vec3( 0.35458, 0.90834, 0.13383 ),
		vec3( 0.04823, 0.01566, 0.83777 )
	);
	const mat3 ACESOutputMat = mat3(
		vec3(  1.60475, -0.10208, -0.00327 ),		vec3( -0.53108,  1.10813, -0.07276 ),
		vec3( -0.07367, -0.00605,  1.07602 )
	);
	color *= toneMappingExposure / 0.6;
	color = ACESInputMat * color;
	color = RRTAndODTFit( color );
	color = ACESOutputMat * color;
	return saturate( color );
}
vec3 CustomToneMapping( vec3 color ) { return color; }`, nm = `#ifdef USE_TRANSMISSION
	float transmissionAlpha = 1.0;
	float transmissionFactor = transmission;
	float thicknessFactor = thickness;
	#ifdef USE_TRANSMISSIONMAP
		transmissionFactor *= texture2D( transmissionMap, vUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		thicknessFactor *= texture2D( thicknessMap, vUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = inverseTransformDirection( normal, viewMatrix );
	vec4 transmission = getIBLVolumeRefraction(
		n, v, roughnessFactor, material.diffuseColor, material.specularColor, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, ior, thicknessFactor,
		attenuationColor, attenuationDistance );
	totalDiffuse = mix( totalDiffuse, transmission.rgb, transmissionFactor );
	transmissionAlpha = mix( transmissionAlpha, transmission.a, transmissionFactor );
#endif`, im = `#ifdef USE_TRANSMISSION
	uniform float transmission;
	uniform float thickness;
	uniform float attenuationDistance;
	uniform vec3 attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		uniform sampler2D transmissionMap;
	#endif
	#ifdef USE_THICKNESSMAP
		uniform sampler2D thicknessMap;
	#endif
	uniform vec2 transmissionSamplerSize;
	uniform sampler2D transmissionSamplerMap;
	uniform mat4 modelMatrix;
	uniform mat4 projectionMatrix;
	varying vec3 vWorldPosition;
	vec3 getVolumeTransmissionRay( vec3 n, vec3 v, float thickness, float ior, mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( float roughness, float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( vec2 fragCoord, float roughness, float ior ) {
		float framebufferLod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		#ifdef TEXTURE_LOD_EXT
			return texture2DLodEXT( transmissionSamplerMap, fragCoord.xy, framebufferLod );
		#else
			return texture2D( transmissionSamplerMap, fragCoord.xy, framebufferLod );
		#endif
	}
	vec3 applyVolumeAttenuation( vec3 radiance, float transmissionDistance, vec3 attenuationColor, float attenuationDistance ) {
		if ( attenuationDistance == 0.0 ) {
			return radiance;
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance * radiance;
		}
	}
	vec4 getIBLVolumeRefraction( vec3 n, vec3 v, float roughness, vec3 diffuseColor, vec3 specularColor, float specularF90,
		vec3 position, mat4 modelMatrix, mat4 viewMatrix, mat4 projMatrix, float ior, float thickness,
		vec3 attenuationColor, float attenuationDistance ) {
		vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
		vec3 refractedRayExit = position + transmissionRay;
		vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
		vec2 refractionCoords = ndcPos.xy / ndcPos.w;
		refractionCoords += 1.0;
		refractionCoords /= 2.0;
		vec4 transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
		vec3 attenuatedColor = applyVolumeAttenuation( transmittedLight.rgb, length( transmissionRay ), attenuationColor, attenuationDistance );
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		return vec4( ( 1.0 - F ) * attenuatedColor * diffuseColor, transmittedLight.a );
	}
#endif`, rm = `#if ( defined( USE_UV ) && ! defined( UVS_VERTEX_ONLY ) )
	varying vec2 vUv;
#endif`, sm = `#ifdef USE_UV
	#ifdef UVS_VERTEX_ONLY
		vec2 vUv;
	#else
		varying vec2 vUv;
	#endif
	uniform mat3 uvTransform;
#endif`, om = `#ifdef USE_UV
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
#endif`, am = `#if defined( USE_LIGHTMAP ) || defined( USE_AOMAP )
	varying vec2 vUv2;
#endif`, lm = `#if defined( USE_LIGHTMAP ) || defined( USE_AOMAP )
	attribute vec2 uv2;
	varying vec2 vUv2;
	uniform mat3 uv2Transform;
#endif`, cm = `#if defined( USE_LIGHTMAP ) || defined( USE_AOMAP )
	vUv2 = ( uv2Transform * vec3( uv2, 1 ) ).xy;
#endif`, hm = `#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION )
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`, um = `varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`, dm = `uniform sampler2D t2D;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	gl_FragColor = mapTexelToLinear( texColor );
	#include <tonemapping_fragment>
	#include <encodings_fragment>
}`, fm = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`, pm = `#include <envmap_common_pars_fragment>
uniform float opacity;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	vec3 vReflect = vWorldDirection;
	#include <envmap_fragment>
	gl_FragColor = envColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <encodings_fragment>
}`, mm = `#include <common>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
varying vec2 vHighPrecisionZW;
void main() {
	#include <uv_vertex>
	#include <skinbase_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vHighPrecisionZW = gl_Position.zw;
}`, gm = `#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( 1.0 );
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <logdepthbuf_fragment>
	float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#endif
}`, xm = `#define DISTANCE
varying vec3 vWorldPosition;
#include <common>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <skinbase_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <clipping_planes_vertex>
	vWorldPosition = worldPosition.xyz;
}`, ym = `#define DISTANCE
uniform vec3 referencePosition;
uniform float nearDistance;
uniform float farDistance;
varying vec3 vWorldPosition;
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <clipping_planes_pars_fragment>
void main () {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( 1.0 );
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = packDepthToRGBA( dist );
}`, vm = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`, _m = `uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	vec4 texColor = texture2D( tEquirect, sampleUV );
	gl_FragColor = mapTexelToLinear( texColor );
	#include <tonemapping_fragment>
	#include <encodings_fragment>
}`, Mm = `uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <color_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`, bm = `uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	if ( mod( vLineDistance, totalSize ) > dashSize ) {
		discard;
	}
	vec3 outgoingLight = vec3( 0.0 );
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <logdepthbuf_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`, wm = `#include <common>
#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <uv2_vertex>
	#include <color_vertex>
	#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinbase_vertex>
		#include <skinnormal_vertex>
		#include <defaultnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <fog_vertex>
}`, Sm = `uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <uv2_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <cube_uv_reflection_fragment>
#include <fog_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel= texture2D( lightMap, vUv2 );
		reflectedLight.indirectDiffuse += lightMapTexelToLinear( lightMapTexel ).rgb * lightMapIntensity;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Tm = `#define LAMBERT
varying vec3 vLightFront;
varying vec3 vIndirectFront;
#ifdef DOUBLE_SIDED
	varying vec3 vLightBack;
	varying vec3 vIndirectBack;
#endif
#include <common>
#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <envmap_pars_vertex>
#include <bsdfs>
#include <lights_pars_begin>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <uv2_vertex>
	#include <color_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <lights_lambert_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`, Em = `uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
varying vec3 vLightFront;
varying vec3 vIndirectFront;
#ifdef DOUBLE_SIDED
	varying vec3 vLightBack;
	varying vec3 vIndirectBack;
#endif
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <uv2_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <cube_uv_reflection_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <fog_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( diffuse, opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <specularmap_fragment>
	#include <emissivemap_fragment>
	#ifdef DOUBLE_SIDED
		reflectedLight.indirectDiffuse += ( gl_FrontFacing ) ? vIndirectFront : vIndirectBack;
	#else
		reflectedLight.indirectDiffuse += vIndirectFront;
	#endif
	#include <lightmap_fragment>
	reflectedLight.indirectDiffuse *= BRDF_Lambert( diffuseColor.rgb );
	#ifdef DOUBLE_SIDED
		reflectedLight.directDiffuse = ( gl_FrontFacing ) ? vLightFront : vLightBack;
	#else
		reflectedLight.directDiffuse = vLightFront;
	#endif
	reflectedLight.directDiffuse *= BRDF_Lambert( diffuseColor.rgb ) * getShadowMask();
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Am = `#define MATCAP
varying vec3 vViewPosition;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <displacementmap_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
	vViewPosition = - mvPosition.xyz;
}`, Cm = `#define MATCAP
uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <fog_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
		matcapColor = matcapTexelToLinear( matcapColor );
	#else
		vec4 matcapColor = vec4( 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Lm = `#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( TANGENTSPACE_NORMALMAP )
	varying vec3 vViewPosition;
#endif
#include <common>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( TANGENTSPACE_NORMALMAP )
	vViewPosition = - mvPosition.xyz;
#endif
}`, Rm = `#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( TANGENTSPACE_NORMALMAP )
	varying vec3 vViewPosition;
#endif
#include <packing>
#include <uv_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	gl_FragColor = vec4( packNormalToRGB( normal ), opacity );
}`, Pm = `#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <uv2_vertex>
	#include <color_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`, Im = `#define PHONG
uniform vec3 diffuse;
uniform vec3 emissive;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <uv2_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <cube_uv_reflection_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_phong_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( diffuse, opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Dm = `#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <uv2_vertex>
	#include <color_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
#ifdef USE_TRANSMISSION
	vWorldPosition = worldPosition.xyz;
#endif
}`, Fm = `#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULARINTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
	#ifdef USE_SPECULARCOLORMAP
		uniform sampler2D specularColorMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEENCOLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEENROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <uv2_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <bsdfs>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>
#include <transmission_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( diffuse, opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <clearcoat_normal_fragment_begin>
	#include <clearcoat_normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;
	#include <transmission_fragment>
	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;
	#ifdef USE_SHEEN
		float sheenEnergyComp = 1.0 - 0.157 * max3( material.sheenColor );
		outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecular;
	#endif
	#ifdef USE_CLEARCOAT
		float dotNVcc = saturate( dot( geometry.clearcoatNormal, geometry.viewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + clearcoatSpecular * material.clearcoat;
	#endif
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Nm = `#define TOON
varying vec3 vViewPosition;
#include <common>
#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <uv2_vertex>
	#include <color_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`, Bm = `#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <uv2_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <gradientmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_toon_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( diffuse, opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, zm = `uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <color_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	gl_PointSize = size;
	#ifdef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
	#endif
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>
}`, Um = `uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`, Om = `#include <common>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
void main() {
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`, Hm = `uniform vec3 color;
uniform float opacity;
#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
}`, km = `uniform float rotation;
uniform vec2 center;
#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	vec4 mvPosition = modelViewMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );
	vec2 scale;
	scale.x = length( vec3( modelMatrix[ 0 ].x, modelMatrix[ 0 ].y, modelMatrix[ 0 ].z ) );
	scale.y = length( vec3( modelMatrix[ 1 ].x, modelMatrix[ 1 ].y, modelMatrix[ 1 ].z ) );
	#ifndef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) scale *= - mvPosition.z;
	#endif
	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;
	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;
	mvPosition.xy += rotatedPosition;
	gl_Position = projectionMatrix * mvPosition;
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`, Gm = `uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <output_fragment>
	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
}`, Fe = {
    alphamap_fragment: xf,
    alphamap_pars_fragment: yf,
    alphatest_fragment: vf,
    alphatest_pars_fragment: _f,
    aomap_fragment: Mf,
    aomap_pars_fragment: bf,
    begin_vertex: wf,
    beginnormal_vertex: Sf,
    bsdfs: Tf,
    bumpmap_pars_fragment: Ef,
    clipping_planes_fragment: Af,
    clipping_planes_pars_fragment: Cf,
    clipping_planes_pars_vertex: Lf,
    clipping_planes_vertex: Rf,
    color_fragment: Pf,
    color_pars_fragment: If,
    color_pars_vertex: Df,
    color_vertex: Ff,
    common: Nf,
    cube_uv_reflection_fragment: Bf,
    defaultnormal_vertex: zf,
    displacementmap_pars_vertex: Uf,
    displacementmap_vertex: Of,
    emissivemap_fragment: Hf,
    emissivemap_pars_fragment: kf,
    encodings_fragment: Gf,
    encodings_pars_fragment: Vf,
    envmap_fragment: Wf,
    envmap_common_pars_fragment: qf,
    envmap_pars_fragment: Xf,
    envmap_pars_vertex: Jf,
    envmap_physical_pars_fragment: rp,
    envmap_vertex: Yf,
    fog_vertex: Zf,
    fog_pars_vertex: $f,
    fog_fragment: jf,
    fog_pars_fragment: Qf,
    gradientmap_pars_fragment: Kf,
    lightmap_fragment: ep,
    lightmap_pars_fragment: tp,
    lights_lambert_vertex: np,
    lights_pars_begin: ip,
    lights_toon_fragment: sp,
    lights_toon_pars_fragment: op,
    lights_phong_fragment: ap,
    lights_phong_pars_fragment: lp,
    lights_physical_fragment: cp,
    lights_physical_pars_fragment: hp,
    lights_fragment_begin: up,
    lights_fragment_maps: dp,
    lights_fragment_end: fp,
    logdepthbuf_fragment: pp,
    logdepthbuf_pars_fragment: mp,
    logdepthbuf_pars_vertex: gp,
    logdepthbuf_vertex: xp,
    map_fragment: yp,
    map_pars_fragment: vp,
    map_particle_fragment: _p,
    map_particle_pars_fragment: Mp,
    metalnessmap_fragment: bp,
    metalnessmap_pars_fragment: wp,
    morphnormal_vertex: Sp,
    morphtarget_pars_vertex: Tp,
    morphtarget_vertex: Ep,
    normal_fragment_begin: Ap,
    normal_fragment_maps: Cp,
    normal_pars_fragment: Lp,
    normal_pars_vertex: Rp,
    normal_vertex: Pp,
    normalmap_pars_fragment: Ip,
    clearcoat_normal_fragment_begin: Dp,
    clearcoat_normal_fragment_maps: Fp,
    clearcoat_pars_fragment: Np,
    output_fragment: Bp,
    packing: zp,
    premultiplied_alpha_fragment: Up,
    project_vertex: Op,
    dithering_fragment: Hp,
    dithering_pars_fragment: kp,
    roughnessmap_fragment: Gp,
    roughnessmap_pars_fragment: Vp,
    shadowmap_pars_fragment: Wp,
    shadowmap_pars_vertex: qp,
    shadowmap_vertex: Xp,
    shadowmask_pars_fragment: Jp,
    skinbase_vertex: Yp,
    skinning_pars_vertex: Zp,
    skinning_vertex: $p,
    skinnormal_vertex: jp,
    specularmap_fragment: Qp,
    specularmap_pars_fragment: Kp,
    tonemapping_fragment: em,
    tonemapping_pars_fragment: tm,
    transmission_fragment: nm,
    transmission_pars_fragment: im,
    uv_pars_fragment: rm,
    uv_pars_vertex: sm,
    uv_vertex: om,
    uv2_pars_fragment: am,
    uv2_pars_vertex: lm,
    uv2_vertex: cm,
    worldpos_vertex: hm,
    background_vert: um,
    background_frag: dm,
    cube_vert: fm,
    cube_frag: pm,
    depth_vert: mm,
    depth_frag: gm,
    distanceRGBA_vert: xm,
    distanceRGBA_frag: ym,
    equirect_vert: vm,
    equirect_frag: _m,
    linedashed_vert: Mm,
    linedashed_frag: bm,
    meshbasic_vert: wm,
    meshbasic_frag: Sm,
    meshlambert_vert: Tm,
    meshlambert_frag: Em,
    meshmatcap_vert: Am,
    meshmatcap_frag: Cm,
    meshnormal_vert: Lm,
    meshnormal_frag: Rm,
    meshphong_vert: Pm,
    meshphong_frag: Im,
    meshphysical_vert: Dm,
    meshphysical_frag: Fm,
    meshtoon_vert: Nm,
    meshtoon_frag: Bm,
    points_vert: zm,
    points_frag: Um,
    shadow_vert: Om,
    shadow_frag: Hm,
    sprite_vert: km,
    sprite_frag: Gm
}, ie = {
    common: {
        diffuse: {
            value: new ae(16777215)
        },
        opacity: {
            value: 1
        },
        map: {
            value: null
        },
        uvTransform: {
            value: new lt
        },
        uv2Transform: {
            value: new lt
        },
        alphaMap: {
            value: null
        },
        alphaTest: {
            value: 0
        }
    },
    specularmap: {
        specularMap: {
            value: null
        }
    },
    envmap: {
        envMap: {
            value: null
        },
        flipEnvMap: {
            value: -1
        },
        reflectivity: {
            value: 1
        },
        ior: {
            value: 1.5
        },
        refractionRatio: {
            value: .98
        }
    },
    aomap: {
        aoMap: {
            value: null
        },
        aoMapIntensity: {
            value: 1
        }
    },
    lightmap: {
        lightMap: {
            value: null
        },
        lightMapIntensity: {
            value: 1
        }
    },
    emissivemap: {
        emissiveMap: {
            value: null
        }
    },
    bumpmap: {
        bumpMap: {
            value: null
        },
        bumpScale: {
            value: 1
        }
    },
    normalmap: {
        normalMap: {
            value: null
        },
        normalScale: {
            value: new X(1, 1)
        }
    },
    displacementmap: {
        displacementMap: {
            value: null
        },
        displacementScale: {
            value: 1
        },
        displacementBias: {
            value: 0
        }
    },
    roughnessmap: {
        roughnessMap: {
            value: null
        }
    },
    metalnessmap: {
        metalnessMap: {
            value: null
        }
    },
    gradientmap: {
        gradientMap: {
            value: null
        }
    },
    fog: {
        fogDensity: {
            value: 25e-5
        },
        fogNear: {
            value: 1
        },
        fogFar: {
            value: 2e3
        },
        fogColor: {
            value: new ae(16777215)
        }
    },
    lights: {
        ambientLightColor: {
            value: []
        },
        lightProbe: {
            value: []
        },
        directionalLights: {
            value: [],
            properties: {
                direction: {},
                color: {}
            }
        },
        directionalLightShadows: {
            value: [],
            properties: {
                shadowBias: {},
                shadowNormalBias: {},
                shadowRadius: {},
                shadowMapSize: {}
            }
        },
        directionalShadowMap: {
            value: []
        },
        directionalShadowMatrix: {
            value: []
        },
        spotLights: {
            value: [],
            properties: {
                color: {},
                position: {},
                direction: {},
                distance: {},
                coneCos: {},
                penumbraCos: {},
                decay: {}
            }
        },
        spotLightShadows: {
            value: [],
            properties: {
                shadowBias: {},
                shadowNormalBias: {},
                shadowRadius: {},
                shadowMapSize: {}
            }
        },
        spotShadowMap: {
            value: []
        },
        spotShadowMatrix: {
            value: []
        },
        pointLights: {
            value: [],
            properties: {
                color: {},
                position: {},
                decay: {},
                distance: {}
            }
        },
        pointLightShadows: {
            value: [],
            properties: {
                shadowBias: {},
                shadowNormalBias: {},
                shadowRadius: {},
                shadowMapSize: {},
                shadowCameraNear: {},
                shadowCameraFar: {}
            }
        },
        pointShadowMap: {
            value: []
        },
        pointShadowMatrix: {
            value: []
        },
        hemisphereLights: {
            value: [],
            properties: {
                direction: {},
                skyColor: {},
                groundColor: {}
            }
        },
        rectAreaLights: {
            value: [],
            properties: {
                color: {},
                position: {},
                width: {},
                height: {}
            }
        },
        ltc_1: {
            value: null
        },
        ltc_2: {
            value: null
        }
    },
    points: {
        diffuse: {
            value: new ae(16777215)
        },
        opacity: {
            value: 1
        },
        size: {
            value: 1
        },
        scale: {
            value: 1
        },
        map: {
            value: null
        },
        alphaMap: {
            value: null
        },
        alphaTest: {
            value: 0
        },
        uvTransform: {
            value: new lt
        }
    },
    sprite: {
        diffuse: {
            value: new ae(16777215)
        },
        opacity: {
            value: 1
        },
        center: {
            value: new X(.5, .5)
        },
        rotation: {
            value: 0
        },
        map: {
            value: null
        },
        alphaMap: {
            value: null
        },
        alphaTest: {
            value: 0
        },
        uvTransform: {
            value: new lt
        }
    }
}, qt = {
    basic: {
        uniforms: yt([
            ie.common,
            ie.specularmap,
            ie.envmap,
            ie.aomap,
            ie.lightmap,
            ie.fog
        ]),
        vertexShader: Fe.meshbasic_vert,
        fragmentShader: Fe.meshbasic_frag
    },
    lambert: {
        uniforms: yt([
            ie.common,
            ie.specularmap,
            ie.envmap,
            ie.aomap,
            ie.lightmap,
            ie.emissivemap,
            ie.fog,
            ie.lights,
            {
                emissive: {
                    value: new ae(0)
                }
            }
        ]),
        vertexShader: Fe.meshlambert_vert,
        fragmentShader: Fe.meshlambert_frag
    },
    phong: {
        uniforms: yt([
            ie.common,
            ie.specularmap,
            ie.envmap,
            ie.aomap,
            ie.lightmap,
            ie.emissivemap,
            ie.bumpmap,
            ie.normalmap,
            ie.displacementmap,
            ie.fog,
            ie.lights,
            {
                emissive: {
                    value: new ae(0)
                },
                specular: {
                    value: new ae(1118481)
                },
                shininess: {
                    value: 30
                }
            }
        ]),
        vertexShader: Fe.meshphong_vert,
        fragmentShader: Fe.meshphong_frag
    },
    standard: {
        uniforms: yt([
            ie.common,
            ie.envmap,
            ie.aomap,
            ie.lightmap,
            ie.emissivemap,
            ie.bumpmap,
            ie.normalmap,
            ie.displacementmap,
            ie.roughnessmap,
            ie.metalnessmap,
            ie.fog,
            ie.lights,
            {
                emissive: {
                    value: new ae(0)
                },
                roughness: {
                    value: 1
                },
                metalness: {
                    value: 0
                },
                envMapIntensity: {
                    value: 1
                }
            }
        ]),
        vertexShader: Fe.meshphysical_vert,
        fragmentShader: Fe.meshphysical_frag
    },
    toon: {
        uniforms: yt([
            ie.common,
            ie.aomap,
            ie.lightmap,
            ie.emissivemap,
            ie.bumpmap,
            ie.normalmap,
            ie.displacementmap,
            ie.gradientmap,
            ie.fog,
            ie.lights,
            {
                emissive: {
                    value: new ae(0)
                }
            }
        ]),
        vertexShader: Fe.meshtoon_vert,
        fragmentShader: Fe.meshtoon_frag
    },
    matcap: {
        uniforms: yt([
            ie.common,
            ie.bumpmap,
            ie.normalmap,
            ie.displacementmap,
            ie.fog,
            {
                matcap: {
                    value: null
                }
            }
        ]),
        vertexShader: Fe.meshmatcap_vert,
        fragmentShader: Fe.meshmatcap_frag
    },
    points: {
        uniforms: yt([
            ie.points,
            ie.fog
        ]),
        vertexShader: Fe.points_vert,
        fragmentShader: Fe.points_frag
    },
    dashed: {
        uniforms: yt([
            ie.common,
            ie.fog,
            {
                scale: {
                    value: 1
                },
                dashSize: {
                    value: 1
                },
                totalSize: {
                    value: 2
                }
            }
        ]),
        vertexShader: Fe.linedashed_vert,
        fragmentShader: Fe.linedashed_frag
    },
    depth: {
        uniforms: yt([
            ie.common,
            ie.displacementmap
        ]),
        vertexShader: Fe.depth_vert,
        fragmentShader: Fe.depth_frag
    },
    normal: {
        uniforms: yt([
            ie.common,
            ie.bumpmap,
            ie.normalmap,
            ie.displacementmap,
            {
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: Fe.meshnormal_vert,
        fragmentShader: Fe.meshnormal_frag
    },
    sprite: {
        uniforms: yt([
            ie.sprite,
            ie.fog
        ]),
        vertexShader: Fe.sprite_vert,
        fragmentShader: Fe.sprite_frag
    },
    background: {
        uniforms: {
            uvTransform: {
                value: new lt
            },
            t2D: {
                value: null
            }
        },
        vertexShader: Fe.background_vert,
        fragmentShader: Fe.background_frag
    },
    cube: {
        uniforms: yt([
            ie.envmap,
            {
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: Fe.cube_vert,
        fragmentShader: Fe.cube_frag
    },
    equirect: {
        uniforms: {
            tEquirect: {
                value: null
            }
        },
        vertexShader: Fe.equirect_vert,
        fragmentShader: Fe.equirect_frag
    },
    distanceRGBA: {
        uniforms: yt([
            ie.common,
            ie.displacementmap,
            {
                referencePosition: {
                    value: new M
                },
                nearDistance: {
                    value: 1
                },
                farDistance: {
                    value: 1e3
                }
            }
        ]),
        vertexShader: Fe.distanceRGBA_vert,
        fragmentShader: Fe.distanceRGBA_frag
    },
    shadow: {
        uniforms: yt([
            ie.lights,
            ie.fog,
            {
                color: {
                    value: new ae(0)
                },
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: Fe.shadow_vert,
        fragmentShader: Fe.shadow_frag
    }
};
qt.physical = {
    uniforms: yt([
        qt.standard.uniforms,
        {
            clearcoat: {
                value: 0
            },
            clearcoatMap: {
                value: null
            },
            clearcoatRoughness: {
                value: 0
            },
            clearcoatRoughnessMap: {
                value: null
            },
            clearcoatNormalScale: {
                value: new X(1, 1)
            },
            clearcoatNormalMap: {
                value: null
            },
            sheen: {
                value: 0
            },
            sheenColor: {
                value: new ae(0)
            },
            sheenColorMap: {
                value: null
            },
            sheenRoughness: {
                value: 0
            },
            sheenRoughnessMap: {
                value: null
            },
            transmission: {
                value: 0
            },
            transmissionMap: {
                value: null
            },
            transmissionSamplerSize: {
                value: new X
            },
            transmissionSamplerMap: {
                value: null
            },
            thickness: {
                value: 0
            },
            thicknessMap: {
                value: null
            },
            attenuationDistance: {
                value: 0
            },
            attenuationColor: {
                value: new ae(0)
            },
            specularIntensity: {
                value: 0
            },
            specularIntensityMap: {
                value: null
            },
            specularColor: {
                value: new ae(1, 1, 1)
            },
            specularColorMap: {
                value: null
            }
        }
    ]),
    vertexShader: Fe.meshphysical_vert,
    fragmentShader: Fe.meshphysical_frag
};
function Vm(s, e, t, n, i) {
    let r = new ae(0), o = 0, a, l, c = null, h = 0, u = null;
    function d(m, x) {
        let v = !1, g = x.isScene === !0 ? x.background : null;
        g && g.isTexture && (g = e.get(g));
        let p = s.xr, _ = p.getSession && p.getSession();
        _ && _.environmentBlendMode === "additive" && (g = null), g === null ? f(r, o) : g && g.isColor && (f(g, 1), v = !0), (s.autoClear || v) && s.clear(s.autoClearColor, s.autoClearDepth, s.autoClearStencil), g && (g.isCubeTexture || g.mapping === Pr) ? (l === void 0 && (l = new st(new wn(1, 1, 1), new sn({
            name: "BackgroundCubeMaterial",
            uniforms: Ri(qt.cube.uniforms),
            vertexShader: qt.cube.vertexShader,
            fragmentShader: qt.cube.fragmentShader,
            side: it,
            depthTest: !1,
            depthWrite: !1,
            fog: !1
        })), l.geometry.deleteAttribute("normal"), l.geometry.deleteAttribute("uv"), l.onBeforeRender = function(y, b, A) {
            this.matrixWorld.copyPosition(A.matrixWorld);
        }, Object.defineProperty(l.material, "envMap", {
            get: function() {
                return this.uniforms.envMap.value;
            }
        }), n.update(l)), l.material.uniforms.envMap.value = g, l.material.uniforms.flipEnvMap.value = g.isCubeTexture && g.isRenderTargetTexture === !1 ? -1 : 1, (c !== g || h !== g.version || u !== s.toneMapping) && (l.material.needsUpdate = !0, c = g, h = g.version, u = s.toneMapping), m.unshift(l, l.geometry, l.material, 0, 0, null)) : g && g.isTexture && (a === void 0 && (a = new st(new Pi(2, 2), new sn({
            name: "BackgroundMaterial",
            uniforms: Ri(qt.background.uniforms),
            vertexShader: qt.background.vertexShader,
            fragmentShader: qt.background.fragmentShader,
            side: Ai,
            depthTest: !1,
            depthWrite: !1,
            fog: !1
        })), a.geometry.deleteAttribute("normal"), Object.defineProperty(a.material, "map", {
            get: function() {
                return this.uniforms.t2D.value;
            }
        }), n.update(a)), a.material.uniforms.t2D.value = g, g.matrixAutoUpdate === !0 && g.updateMatrix(), a.material.uniforms.uvTransform.value.copy(g.matrix), (c !== g || h !== g.version || u !== s.toneMapping) && (a.material.needsUpdate = !0, c = g, h = g.version, u = s.toneMapping), m.unshift(a, a.geometry, a.material, 0, 0, null));
    }
    function f(m, x) {
        t.buffers.color.setClear(m.r, m.g, m.b, x, i);
    }
    return {
        getClearColor: function() {
            return r;
        },
        setClearColor: function(m, x = 1) {
            r.set(m), o = x, f(r, o);
        },
        getClearAlpha: function() {
            return o;
        },
        setClearAlpha: function(m) {
            o = m, f(r, o);
        },
        render: d
    };
}
function Wm(s, e, t, n) {
    let i = s.getParameter(34921), r = n.isWebGL2 ? null : e.get("OES_vertex_array_object"), o = n.isWebGL2 || r !== null, a = {}, l = x(null), c = l;
    function h(E, D, U, F, O) {
        let ne = !1;
        if (o) {
            let ce = m(F, U, D);
            c !== ce && (c = ce, d(c.object)), ne = v(F, O), ne && g(F, O);
        } else {
            let ce1 = D.wireframe === !0;
            (c.geometry !== F.id || c.program !== U.id || c.wireframe !== ce1) && (c.geometry = F.id, c.program = U.id, c.wireframe = ce1, ne = !0);
        }
        E.isInstancedMesh === !0 && (ne = !0), O !== null && t.update(O, 34963), ne && (L(E, D, U, F), O !== null && s.bindBuffer(34963, t.get(O).buffer));
    }
    function u() {
        return n.isWebGL2 ? s.createVertexArray() : r.createVertexArrayOES();
    }
    function d(E) {
        return n.isWebGL2 ? s.bindVertexArray(E) : r.bindVertexArrayOES(E);
    }
    function f(E) {
        return n.isWebGL2 ? s.deleteVertexArray(E) : r.deleteVertexArrayOES(E);
    }
    function m(E, D, U) {
        let F = U.wireframe === !0, O = a[E.id];
        O === void 0 && (O = {}, a[E.id] = O);
        let ne = O[D.id];
        ne === void 0 && (ne = {}, O[D.id] = ne);
        let ce = ne[F];
        return ce === void 0 && (ce = x(u()), ne[F] = ce), ce;
    }
    function x(E) {
        let D = [], U = [], F = [];
        for(let O = 0; O < i; O++)D[O] = 0, U[O] = 0, F[O] = 0;
        return {
            geometry: null,
            program: null,
            wireframe: !1,
            newAttributes: D,
            enabledAttributes: U,
            attributeDivisors: F,
            object: E,
            attributes: {},
            index: null
        };
    }
    function v(E, D) {
        let U = c.attributes, F = E.attributes, O = 0;
        for(let ne in F){
            let ce = U[ne], V = F[ne];
            if (ce === void 0 || ce.attribute !== V || ce.data !== V.data) return !0;
            O++;
        }
        return c.attributesNum !== O || c.index !== D;
    }
    function g(E, D) {
        let U = {}, F = E.attributes, O = 0;
        for(let ne in F){
            let ce = F[ne], V = {};
            V.attribute = ce, ce.data && (V.data = ce.data), U[ne] = V, O++;
        }
        c.attributes = U, c.attributesNum = O, c.index = D;
    }
    function p() {
        let E = c.newAttributes;
        for(let D = 0, U = E.length; D < U; D++)E[D] = 0;
    }
    function _(E) {
        y(E, 0);
    }
    function y(E, D) {
        let U = c.newAttributes, F = c.enabledAttributes, O = c.attributeDivisors;
        U[E] = 1, F[E] === 0 && (s.enableVertexAttribArray(E), F[E] = 1), O[E] !== D && ((n.isWebGL2 ? s : e.get("ANGLE_instanced_arrays"))[n.isWebGL2 ? "vertexAttribDivisor" : "vertexAttribDivisorANGLE"](E, D), O[E] = D);
    }
    function b() {
        let E = c.newAttributes, D = c.enabledAttributes;
        for(let U = 0, F = D.length; U < F; U++)D[U] !== E[U] && (s.disableVertexAttribArray(U), D[U] = 0);
    }
    function A(E, D, U, F, O, ne) {
        n.isWebGL2 === !0 && (U === 5124 || U === 5125) ? s.vertexAttribIPointer(E, D, U, O, ne) : s.vertexAttribPointer(E, D, U, F, O, ne);
    }
    function L(E, D, U, F) {
        if (n.isWebGL2 === !1 && (E.isInstancedMesh || F.isInstancedBufferGeometry) && e.get("ANGLE_instanced_arrays") === null) return;
        p();
        let O = F.attributes, ne = U.getAttributes(), ce = D.defaultAttributeValues;
        for(let V in ne){
            let W = ne[V];
            if (W.location >= 0) {
                let he = O[V];
                if (he === void 0 && (V === "instanceMatrix" && E.instanceMatrix && (he = E.instanceMatrix), V === "instanceColor" && E.instanceColor && (he = E.instanceColor)), he !== void 0) {
                    let le = he.normalized, fe = he.itemSize, Be = t.get(he);
                    if (Be === void 0) continue;
                    let Y = Be.buffer, Ce = Be.type, ye = Be.bytesPerElement;
                    if (he.isInterleavedBufferAttribute) {
                        let ge = he.data, xe = ge.stride, Oe = he.offset;
                        if (ge && ge.isInstancedInterleavedBuffer) {
                            for(let G = 0; G < W.locationSize; G++)y(W.location + G, ge.meshPerAttribute);
                            E.isInstancedMesh !== !0 && F._maxInstanceCount === void 0 && (F._maxInstanceCount = ge.meshPerAttribute * ge.count);
                        } else for(let G1 = 0; G1 < W.locationSize; G1++)_(W.location + G1);
                        s.bindBuffer(34962, Y);
                        for(let G2 = 0; G2 < W.locationSize; G2++)A(W.location + G2, fe / W.locationSize, Ce, le, xe * ye, (Oe + fe / W.locationSize * G2) * ye);
                    } else {
                        if (he.isInstancedBufferAttribute) {
                            for(let ge1 = 0; ge1 < W.locationSize; ge1++)y(W.location + ge1, he.meshPerAttribute);
                            E.isInstancedMesh !== !0 && F._maxInstanceCount === void 0 && (F._maxInstanceCount = he.meshPerAttribute * he.count);
                        } else for(let ge2 = 0; ge2 < W.locationSize; ge2++)_(W.location + ge2);
                        s.bindBuffer(34962, Y);
                        for(let ge3 = 0; ge3 < W.locationSize; ge3++)A(W.location + ge3, fe / W.locationSize, Ce, le, fe * ye, fe / W.locationSize * ge3 * ye);
                    }
                } else if (ce !== void 0) {
                    let le1 = ce[V];
                    if (le1 !== void 0) switch(le1.length){
                        case 2:
                            s.vertexAttrib2fv(W.location, le1);
                            break;
                        case 3:
                            s.vertexAttrib3fv(W.location, le1);
                            break;
                        case 4:
                            s.vertexAttrib4fv(W.location, le1);
                            break;
                        default:
                            s.vertexAttrib1fv(W.location, le1);
                    }
                }
            }
        }
        b();
    }
    function I() {
        P();
        for(let E in a){
            let D = a[E];
            for(let U in D){
                let F = D[U];
                for(let O in F)f(F[O].object), delete F[O];
                delete D[U];
            }
            delete a[E];
        }
    }
    function k(E) {
        if (a[E.id] === void 0) return;
        let D = a[E.id];
        for(let U in D){
            let F = D[U];
            for(let O in F)f(F[O].object), delete F[O];
            delete D[U];
        }
        delete a[E.id];
    }
    function B(E) {
        for(let D in a){
            let U = a[D];
            if (U[E.id] === void 0) continue;
            let F = U[E.id];
            for(let O in F)f(F[O].object), delete F[O];
            delete U[E.id];
        }
    }
    function P() {
        w(), c !== l && (c = l, d(c.object));
    }
    function w() {
        l.geometry = null, l.program = null, l.wireframe = !1;
    }
    return {
        setup: h,
        reset: P,
        resetDefaultState: w,
        dispose: I,
        releaseStatesOfGeometry: k,
        releaseStatesOfProgram: B,
        initAttributes: p,
        enableAttribute: _,
        disableUnusedAttributes: b
    };
}
function qm(s, e, t, n) {
    let i = n.isWebGL2, r;
    function o(c) {
        r = c;
    }
    function a(c, h) {
        s.drawArrays(r, c, h), t.update(h, r, 1);
    }
    function l(c, h, u) {
        if (u === 0) return;
        let d, f;
        if (i) d = s, f = "drawArraysInstanced";
        else if (d = e.get("ANGLE_instanced_arrays"), f = "drawArraysInstancedANGLE", d === null) {
            console.error("THREE.WebGLBufferRenderer: using THREE.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.");
            return;
        }
        d[f](r, c, h, u), t.update(h, r, u);
    }
    this.setMode = o, this.render = a, this.renderInstances = l;
}
function Xm(s, e, t) {
    let n;
    function i() {
        if (n !== void 0) return n;
        if (e.has("EXT_texture_filter_anisotropic") === !0) {
            let L = e.get("EXT_texture_filter_anisotropic");
            n = s.getParameter(L.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else n = 0;
        return n;
    }
    function r(L) {
        if (L === "highp") {
            if (s.getShaderPrecisionFormat(35633, 36338).precision > 0 && s.getShaderPrecisionFormat(35632, 36338).precision > 0) return "highp";
            L = "mediump";
        }
        return L === "mediump" && s.getShaderPrecisionFormat(35633, 36337).precision > 0 && s.getShaderPrecisionFormat(35632, 36337).precision > 0 ? "mediump" : "lowp";
    }
    let o = typeof WebGL2RenderingContext < "u" && s instanceof WebGL2RenderingContext || typeof WebGL2ComputeRenderingContext < "u" && s instanceof WebGL2ComputeRenderingContext, a = t.precision !== void 0 ? t.precision : "highp", l = r(a);
    l !== a && (console.warn("THREE.WebGLRenderer:", a, "not supported, using", l, "instead."), a = l);
    let c = o || e.has("WEBGL_draw_buffers"), h = t.logarithmicDepthBuffer === !0, u = s.getParameter(34930), d = s.getParameter(35660), f = s.getParameter(3379), m = s.getParameter(34076), x = s.getParameter(34921), v = s.getParameter(36347), g = s.getParameter(36348), p = s.getParameter(36349), _ = d > 0, y = o || e.has("OES_texture_float"), b = _ && y, A = o ? s.getParameter(36183) : 0;
    return {
        isWebGL2: o,
        drawBuffers: c,
        getMaxAnisotropy: i,
        getMaxPrecision: r,
        precision: a,
        logarithmicDepthBuffer: h,
        maxTextures: u,
        maxVertexTextures: d,
        maxTextureSize: f,
        maxCubemapSize: m,
        maxAttributes: x,
        maxVertexUniforms: v,
        maxVaryings: g,
        maxFragmentUniforms: p,
        vertexTextures: _,
        floatFragmentTextures: y,
        floatVertexTextures: b,
        maxSamples: A
    };
}
function Jm(s) {
    let e = this, t = null, n = 0, i = !1, r = !1, o = new Wt, a = new lt, l = {
        value: null,
        needsUpdate: !1
    };
    this.uniform = l, this.numPlanes = 0, this.numIntersection = 0, this.init = function(u, d, f) {
        let m = u.length !== 0 || d || n !== 0 || i;
        return i = d, t = h(u, f, 0), n = u.length, m;
    }, this.beginShadows = function() {
        r = !0, h(null);
    }, this.endShadows = function() {
        r = !1, c();
    }, this.setState = function(u, d, f) {
        let m = u.clippingPlanes, x = u.clipIntersection, v = u.clipShadows, g = s.get(u);
        if (!i || m === null || m.length === 0 || r && !v) r ? h(null) : c();
        else {
            let p = r ? 0 : n, _ = p * 4, y = g.clippingState || null;
            l.value = y, y = h(m, d, _, f);
            for(let b = 0; b !== _; ++b)y[b] = t[b];
            g.clippingState = y, this.numIntersection = x ? this.numPlanes : 0, this.numPlanes += p;
        }
    };
    function c() {
        l.value !== t && (l.value = t, l.needsUpdate = n > 0), e.numPlanes = n, e.numIntersection = 0;
    }
    function h(u, d, f, m) {
        let x = u !== null ? u.length : 0, v = null;
        if (x !== 0) {
            if (v = l.value, m !== !0 || v === null) {
                let g = f + x * 4, p = d.matrixWorldInverse;
                a.getNormalMatrix(p), (v === null || v.length < g) && (v = new Float32Array(g));
                for(let _ = 0, y = f; _ !== x; ++_, y += 4)o.copy(u[_]).applyMatrix4(p, a), o.normal.toArray(v, y), v[y + 3] = o.constant;
            }
            l.value = v, l.needsUpdate = !0;
        }
        return e.numPlanes = x, e.numIntersection = 0, v;
    }
}
function Ym(s) {
    let e = new WeakMap;
    function t(o, a) {
        return a === Ds ? o.mapping = Bi : a === Fs && (o.mapping = zi), o;
    }
    function n(o) {
        if (o && o.isTexture && o.isRenderTargetTexture === !1) {
            let a = o.mapping;
            if (a === Ds || a === Fs) if (e.has(o)) {
                let l = e.get(o).texture;
                return t(l, o.mapping);
            } else {
                let l1 = o.image;
                if (l1 && l1.height > 0) {
                    let c = s.getRenderTarget(), h = new js(l1.height / 2);
                    return h.fromEquirectangularTexture(s, o), e.set(o, h), s.setRenderTarget(c), o.addEventListener("dispose", i), t(h.texture, o.mapping);
                } else return null;
            }
        }
        return o;
    }
    function i(o) {
        let a = o.target;
        a.removeEventListener("dispose", i);
        let l = e.get(a);
        l !== void 0 && (e.delete(a), l.dispose());
    }
    function r() {
        e = new WeakMap;
    }
    return {
        get: n,
        dispose: r
    };
}
var Fr = class extends Ir {
    constructor(e = -1, t = 1, n = 1, i = -1, r = .1, o = 2e3){
        super();
        this.type = "OrthographicCamera", this.zoom = 1, this.view = null, this.left = e, this.right = t, this.top = n, this.bottom = i, this.near = r, this.far = o, this.updateProjectionMatrix();
    }
    copy(e, t) {
        return super.copy(e, t), this.left = e.left, this.right = e.right, this.top = e.top, this.bottom = e.bottom, this.near = e.near, this.far = e.far, this.zoom = e.zoom, this.view = e.view === null ? null : Object.assign({}, e.view), this;
    }
    setViewOffset(e, t, n, i, r, o) {
        this.view === null && (this.view = {
            enabled: !0,
            fullWidth: 1,
            fullHeight: 1,
            offsetX: 0,
            offsetY: 0,
            width: 1,
            height: 1
        }), this.view.enabled = !0, this.view.fullWidth = e, this.view.fullHeight = t, this.view.offsetX = n, this.view.offsetY = i, this.view.width = r, this.view.height = o, this.updateProjectionMatrix();
    }
    clearViewOffset() {
        this.view !== null && (this.view.enabled = !1), this.updateProjectionMatrix();
    }
    updateProjectionMatrix() {
        let e = (this.right - this.left) / (2 * this.zoom), t = (this.top - this.bottom) / (2 * this.zoom), n = (this.right + this.left) / 2, i = (this.top + this.bottom) / 2, r = n - e, o = n + e, a = i + t, l = i - t;
        if (this.view !== null && this.view.enabled) {
            let c = (this.right - this.left) / this.view.fullWidth / this.zoom, h = (this.top - this.bottom) / this.view.fullHeight / this.zoom;
            r += c * this.view.offsetX, o = r + c * this.view.width, a -= h * this.view.offsetY, l = a - h * this.view.height;
        }
        this.projectionMatrix.makeOrthographic(r, o, a, l, this.near, this.far), this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.zoom = this.zoom, t.object.left = this.left, t.object.right = this.right, t.object.top = this.top, t.object.bottom = this.bottom, t.object.near = this.near, t.object.far = this.far, this.view !== null && (t.object.view = Object.assign({}, this.view)), t;
    }
};
Fr.prototype.isOrthographicCamera = !0;
var Gi = class extends sn {
    constructor(e){
        super(e);
        this.type = "RawShaderMaterial";
    }
};
Gi.prototype.isRawShaderMaterial = !0;
var Ei = 4, Mn = 8, Vt = Math.pow(2, Mn), sh = [
    .125,
    .215,
    .35,
    .446,
    .526,
    .582
], oh = Mn - Ei + 1 + sh.length, pi = 20, Hs = {
    [Nt]: 0,
    [Oi]: 1
}, Go = new Fr, { _lodPlanes: ji , _sizeLods: Ll , _sigmas: ls  } = Zm(), Rl = new ae, Vo = null, On = (1 + Math.sqrt(5)) / 2, mi = 1 / On, Pl = [
    new M(1, 1, 1),
    new M(-1, 1, 1),
    new M(1, 1, -1),
    new M(-1, 1, -1),
    new M(0, On, mi),
    new M(0, On, -mi),
    new M(mi, 0, On),
    new M(-mi, 0, On),
    new M(On, mi, 0),
    new M(-On, mi, 0)
], ah = class {
    constructor(e){
        this._renderer = e, this._pingPongRenderTarget = null, this._blurMaterial = $m(pi), this._equirectShader = null, this._cubemapShader = null, this._compileMaterial(this._blurMaterial);
    }
    fromScene(e, t = 0, n = .1, i = 100) {
        Vo = this._renderer.getRenderTarget();
        let r = this._allocateTargets();
        return this._sceneToCubeUV(e, n, i, r), t > 0 && this._blur(r, 0, 0, t), this._applyPMREM(r), this._cleanup(r), r;
    }
    fromEquirectangular(e) {
        return this._fromTexture(e);
    }
    fromCubemap(e) {
        return this._fromTexture(e);
    }
    compileCubemapShader() {
        this._cubemapShader === null && (this._cubemapShader = Fl(), this._compileMaterial(this._cubemapShader));
    }
    compileEquirectangularShader() {
        this._equirectShader === null && (this._equirectShader = Dl(), this._compileMaterial(this._equirectShader));
    }
    dispose() {
        this._blurMaterial.dispose(), this._cubemapShader !== null && this._cubemapShader.dispose(), this._equirectShader !== null && this._equirectShader.dispose();
        for(let e = 0; e < ji.length; e++)ji[e].dispose();
    }
    _cleanup(e) {
        this._pingPongRenderTarget.dispose(), this._renderer.setRenderTarget(Vo), e.scissorTest = !1, cs(e, 0, 0, e.width, e.height);
    }
    _fromTexture(e) {
        Vo = this._renderer.getRenderTarget();
        let t = this._allocateTargets(e);
        return this._textureToCubeUV(e, t), this._applyPMREM(t), this._cleanup(t), t;
    }
    _allocateTargets(e) {
        let t = {
            magFilter: tt,
            minFilter: tt,
            generateMipmaps: !1,
            type: kn,
            format: ct,
            encoding: Nt,
            depthBuffer: !1
        }, n = Il(t);
        return n.depthBuffer = !e, this._pingPongRenderTarget = Il(t), n;
    }
    _compileMaterial(e) {
        let t = new st(ji[0], e);
        this._renderer.compile(t, Go);
    }
    _sceneToCubeUV(e, t, n, i) {
        let a = new ut(90, 1, t, n), l = [
            1,
            -1,
            1,
            1,
            1,
            1
        ], c = [
            1,
            1,
            1,
            -1,
            -1,
            -1
        ], h = this._renderer, u = h.autoClear, d = h.toneMapping;
        h.getClearColor(Rl), h.toneMapping = _n, h.autoClear = !1;
        let f = new hn({
            name: "PMREM.Background",
            side: it,
            depthWrite: !1,
            depthTest: !1
        }), m = new st(new wn, f), x = !1, v = e.background;
        v ? v.isColor && (f.color.copy(v), e.background = null, x = !0) : (f.color.copy(Rl), x = !0);
        for(let g = 0; g < 6; g++){
            let p = g % 3;
            p == 0 ? (a.up.set(0, l[g], 0), a.lookAt(c[g], 0, 0)) : p == 1 ? (a.up.set(0, 0, l[g]), a.lookAt(0, c[g], 0)) : (a.up.set(0, l[g], 0), a.lookAt(0, 0, c[g])), cs(i, p * Vt, g > 2 ? Vt : 0, Vt, Vt), h.setRenderTarget(i), x && h.render(m, a), h.render(e, a);
        }
        m.geometry.dispose(), m.material.dispose(), h.toneMapping = d, h.autoClear = u, e.background = v;
    }
    _setEncoding(e, t) {
        this._renderer.capabilities.isWebGL2 === !0 && t.format === ct && t.type === rn && t.encoding === Oi ? e.value = Hs[Nt] : e.value = Hs[t.encoding];
    }
    _textureToCubeUV(e, t) {
        let n = this._renderer, i = e.mapping === Bi || e.mapping === zi;
        i ? this._cubemapShader == null && (this._cubemapShader = Fl()) : this._equirectShader == null && (this._equirectShader = Dl());
        let r = i ? this._cubemapShader : this._equirectShader, o = new st(ji[0], r), a = r.uniforms;
        a.envMap.value = e, i || a.texelSize.value.set(1 / e.image.width, 1 / e.image.height), this._setEncoding(a.inputEncoding, e), cs(t, 0, 0, 3 * Vt, 2 * Vt), n.setRenderTarget(t), n.render(o, Go);
    }
    _applyPMREM(e) {
        let t = this._renderer, n = t.autoClear;
        t.autoClear = !1;
        for(let i = 1; i < oh; i++){
            let r = Math.sqrt(ls[i] * ls[i] - ls[i - 1] * ls[i - 1]), o = Pl[(i - 1) % Pl.length];
            this._blur(e, i - 1, i, r, o);
        }
        t.autoClear = n;
    }
    _blur(e, t, n, i, r) {
        let o = this._pingPongRenderTarget;
        this._halfBlur(e, o, t, n, i, "latitudinal", r), this._halfBlur(o, e, n, n, i, "longitudinal", r);
    }
    _halfBlur(e, t, n, i, r, o, a) {
        let l = this._renderer, c = this._blurMaterial;
        o !== "latitudinal" && o !== "longitudinal" && console.error("blur direction must be either latitudinal or longitudinal!");
        let h = 3, u = new st(ji[i], c), d = c.uniforms, f = Ll[n] - 1, m = isFinite(r) ? Math.PI / (2 * f) : 2 * Math.PI / (2 * pi - 1), x = r / m, v = isFinite(r) ? 1 + Math.floor(h * x) : pi;
        v > pi && console.warn(`sigmaRadians, ${r}, is too large and will clip, as it requested ${v} samples when the maximum is set to ${pi}`);
        let g = [], p = 0;
        for(let A = 0; A < pi; ++A){
            let L = A / x, I = Math.exp(-L * L / 2);
            g.push(I), A == 0 ? p += I : A < v && (p += 2 * I);
        }
        for(let A1 = 0; A1 < g.length; A1++)g[A1] = g[A1] / p;
        d.envMap.value = e.texture, d.samples.value = v, d.weights.value = g, d.latitudinal.value = o === "latitudinal", a && (d.poleAxis.value = a), d.dTheta.value = m, d.mipInt.value = Mn - n;
        let _ = Ll[i], y = 3 * Math.max(0, Vt - 2 * _), b = (i === 0 ? 0 : 2 * Vt) + 2 * _ * (i > Mn - Ei ? i - Mn + Ei : 0);
        cs(t, y, b, 3 * _, 2 * _), l.setRenderTarget(t), l.render(u, Go);
    }
};
function Zm() {
    let s = [], e = [], t = [], n = Mn;
    for(let i = 0; i < oh; i++){
        let r = Math.pow(2, n);
        e.push(r);
        let o = 1 / r;
        i > Mn - Ei ? o = sh[i - Mn + Ei - 1] : i == 0 && (o = 0), t.push(o);
        let a = 1 / (r - 1), l = -a / 2, c = 1 + a / 2, h = [
            l,
            l,
            c,
            l,
            c,
            c,
            l,
            l,
            c,
            c,
            l,
            c
        ], u = 6, d = 6, f = 3, m = 2, x = 1, v = new Float32Array(f * d * u), g = new Float32Array(m * d * u), p = new Float32Array(x * d * u);
        for(let y = 0; y < u; y++){
            let b = y % 3 * 2 / 3 - 1, A = y > 2 ? 0 : -1, L = [
                b,
                A,
                0,
                b + 2 / 3,
                A,
                0,
                b + 2 / 3,
                A + 1,
                0,
                b,
                A,
                0,
                b + 2 / 3,
                A + 1,
                0,
                b,
                A + 1,
                0
            ];
            v.set(L, f * d * y), g.set(h, m * d * y);
            let I = [
                y,
                y,
                y,
                y,
                y,
                y
            ];
            p.set(I, x * d * y);
        }
        let _ = new _e;
        _.setAttribute("position", new Ue(v, f)), _.setAttribute("uv", new Ue(g, m)), _.setAttribute("faceIndex", new Ue(p, x)), s.push(_), n > Ei && n--;
    }
    return {
        _lodPlanes: s,
        _sizeLods: e,
        _sigmas: t
    };
}
function Il(s) {
    let e = new At(3 * Vt, 3 * Vt, s);
    return e.texture.mapping = Pr, e.texture.name = "PMREM.cubeUv", e.scissorTest = !0, e;
}
function cs(s, e, t, n, i) {
    s.viewport.set(e, t, n, i), s.scissor.set(e, t, n, i);
}
function $m(s) {
    let e = new Float32Array(s), t = new M(0, 1, 0);
    return new Gi({
        name: "SphericalGaussianBlur",
        defines: {
            n: s
        },
        uniforms: {
            envMap: {
                value: null
            },
            samples: {
                value: 1
            },
            weights: {
                value: e
            },
            latitudinal: {
                value: !1
            },
            dTheta: {
                value: 0
            },
            mipInt: {
                value: 0
            },
            poleAxis: {
                value: t
            }
        },
        vertexShader: fa(),
        fragmentShader: `

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform int samples;
			uniform float weights[ n ];
			uniform bool latitudinal;
			uniform float dTheta;
			uniform float mipInt;
			uniform vec3 poleAxis;

			${pa()}

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			vec3 getSample( float theta, vec3 axis ) {

				float cosTheta = cos( theta );
				// Rodrigues' axis-angle rotation
				vec3 sampleDirection = vOutputDirection * cosTheta
					+ cross( axis, vOutputDirection ) * sin( theta )
					+ axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );

				return bilinearCubeUV( envMap, sampleDirection, mipInt );

			}

			void main() {

				vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );

				if ( all( equal( axis, vec3( 0.0 ) ) ) ) {

					axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );

				}

				axis = normalize( axis );

				gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
				gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );

				for ( int i = 1; i < n; i++ ) {

					if ( i >= samples ) {

						break;

					}

					float theta = dTheta * float( i );
					gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
					gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );

				}

			}
		`,
        blending: vn,
        depthTest: !1,
        depthWrite: !1
    });
}
function Dl() {
    let s = new X(1, 1);
    return new Gi({
        name: "EquirectangularToCubeUV",
        uniforms: {
            envMap: {
                value: null
            },
            texelSize: {
                value: s
            },
            inputEncoding: {
                value: Hs[Nt]
            }
        },
        vertexShader: fa(),
        fragmentShader: `

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform vec2 texelSize;

			${pa()}

			#include <common>

			void main() {

				gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				vec2 f = fract( uv / texelSize - 0.5 );
				uv -= f * texelSize;
				vec3 tl = envMapTexelToLinear( texture2D ( envMap, uv ) ).rgb;
				uv.x += texelSize.x;
				vec3 tr = envMapTexelToLinear( texture2D ( envMap, uv ) ).rgb;
				uv.y += texelSize.y;
				vec3 br = envMapTexelToLinear( texture2D ( envMap, uv ) ).rgb;
				uv.x -= texelSize.x;
				vec3 bl = envMapTexelToLinear( texture2D ( envMap, uv ) ).rgb;

				vec3 tm = mix( tl, tr, f.x );
				vec3 bm = mix( bl, br, f.x );
				gl_FragColor.rgb = mix( tm, bm, f.y );

			}
		`,
        blending: vn,
        depthTest: !1,
        depthWrite: !1
    });
}
function Fl() {
    return new Gi({
        name: "CubemapToCubeUV",
        uniforms: {
            envMap: {
                value: null
            },
            inputEncoding: {
                value: Hs[Nt]
            }
        },
        vertexShader: fa(),
        fragmentShader: `

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			${pa()}

			void main() {

				gl_FragColor = envMapTexelToLinear( textureCube( envMap, vec3( - vOutputDirection.x, vOutputDirection.yz ) ) );

			}
		`,
        blending: vn,
        depthTest: !1,
        depthWrite: !1
    });
}
function fa() {
    return `

		precision mediump float;
		precision mediump int;

		attribute vec3 position;
		attribute vec2 uv;
		attribute float faceIndex;

		varying vec3 vOutputDirection;

		// RH coordinate system; PMREM face-indexing convention
		vec3 getDirection( vec2 uv, float face ) {

			uv = 2.0 * uv - 1.0;

			vec3 direction = vec3( uv, 1.0 );

			if ( face == 0.0 ) {

				direction = direction.zyx; // ( 1, v, u ) pos x

			} else if ( face == 1.0 ) {

				direction = direction.xzy;
				direction.xz *= -1.0; // ( -u, 1, -v ) pos y

			} else if ( face == 2.0 ) {

				direction.x *= -1.0; // ( -u, v, 1 ) pos z

			} else if ( face == 3.0 ) {

				direction = direction.zyx;
				direction.xz *= -1.0; // ( -1, v, -u ) neg x

			} else if ( face == 4.0 ) {

				direction = direction.xzy;
				direction.xy *= -1.0; // ( -u, -1, v ) neg y

			} else if ( face == 5.0 ) {

				direction.z *= -1.0; // ( u, v, -1 ) neg z

			}

			return direction;

		}

		void main() {

			vOutputDirection = getDirection( uv, faceIndex );
			gl_Position = vec4( position, 1.0 );

		}
	`;
}
function pa() {
    return `

		uniform int inputEncoding;

		#include <encodings_pars_fragment>

		vec4 inputTexelToLinear( vec4 value ) {

			if ( inputEncoding == 0 ) {

				return value;

			} else {

				return sRGBToLinear( value );

			}

		}

		vec4 envMapTexelToLinear( vec4 color ) {

			return inputTexelToLinear( color );

		}
	`;
}
function jm(s) {
    let e = new WeakMap, t = null;
    function n(a) {
        if (a && a.isTexture && a.isRenderTargetTexture === !1) {
            let l = a.mapping, c = l === Ds || l === Fs, h = l === Bi || l === zi;
            if (c || h) {
                if (e.has(a)) return e.get(a).texture;
                {
                    let u = a.image;
                    if (c && u && u.height > 0 || h && u && i(u)) {
                        let d = s.getRenderTarget();
                        t === null && (t = new ah(s));
                        let f = c ? t.fromEquirectangular(a) : t.fromCubemap(a);
                        return e.set(a, f), s.setRenderTarget(d), a.addEventListener("dispose", r), f.texture;
                    } else return null;
                }
            }
        }
        return a;
    }
    function i(a) {
        let l = 0, c = 6;
        for(let h = 0; h < c; h++)a[h] !== void 0 && l++;
        return l === c;
    }
    function r(a) {
        let l = a.target;
        l.removeEventListener("dispose", r);
        let c = e.get(l);
        c !== void 0 && (e.delete(l), c.dispose());
    }
    function o() {
        e = new WeakMap, t !== null && (t.dispose(), t = null);
    }
    return {
        get: n,
        dispose: o
    };
}
function Qm(s) {
    let e = {};
    function t(n) {
        if (e[n] !== void 0) return e[n];
        let i;
        switch(n){
            case "WEBGL_depth_texture":
                i = s.getExtension("WEBGL_depth_texture") || s.getExtension("MOZ_WEBGL_depth_texture") || s.getExtension("WEBKIT_WEBGL_depth_texture");
                break;
            case "EXT_texture_filter_anisotropic":
                i = s.getExtension("EXT_texture_filter_anisotropic") || s.getExtension("MOZ_EXT_texture_filter_anisotropic") || s.getExtension("WEBKIT_EXT_texture_filter_anisotropic");
                break;
            case "WEBGL_compressed_texture_s3tc":
                i = s.getExtension("WEBGL_compressed_texture_s3tc") || s.getExtension("MOZ_WEBGL_compressed_texture_s3tc") || s.getExtension("WEBKIT_WEBGL_compressed_texture_s3tc");
                break;
            case "WEBGL_compressed_texture_pvrtc":
                i = s.getExtension("WEBGL_compressed_texture_pvrtc") || s.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");
                break;
            default:
                i = s.getExtension(n);
        }
        return e[n] = i, i;
    }
    return {
        has: function(n) {
            return t(n) !== null;
        },
        init: function(n) {
            n.isWebGL2 ? t("EXT_color_buffer_float") : (t("WEBGL_depth_texture"), t("OES_texture_float"), t("OES_texture_half_float"), t("OES_texture_half_float_linear"), t("OES_standard_derivatives"), t("OES_element_index_uint"), t("OES_vertex_array_object"), t("ANGLE_instanced_arrays")), t("OES_texture_float_linear"), t("EXT_color_buffer_half_float"), t("WEBGL_multisampled_render_to_texture");
        },
        get: function(n) {
            let i = t(n);
            return i === null && console.warn("THREE.WebGLRenderer: " + n + " extension not supported."), i;
        }
    };
}
function Km(s, e, t, n) {
    let i = {}, r = new WeakMap;
    function o(u) {
        let d = u.target;
        d.index !== null && e.remove(d.index);
        for(let m in d.attributes)e.remove(d.attributes[m]);
        d.removeEventListener("dispose", o), delete i[d.id];
        let f = r.get(d);
        f && (e.remove(f), r.delete(d)), n.releaseStatesOfGeometry(d), d.isInstancedBufferGeometry === !0 && delete d._maxInstanceCount, t.memory.geometries--;
    }
    function a(u, d) {
        return i[d.id] === !0 || (d.addEventListener("dispose", o), i[d.id] = !0, t.memory.geometries++), d;
    }
    function l(u) {
        let d = u.attributes;
        for(let m in d)e.update(d[m], 34962);
        let f = u.morphAttributes;
        for(let m1 in f){
            let x = f[m1];
            for(let v = 0, g = x.length; v < g; v++)e.update(x[v], 34962);
        }
    }
    function c(u) {
        let d = [], f = u.index, m = u.attributes.position, x = 0;
        if (f !== null) {
            let p = f.array;
            x = f.version;
            for(let _ = 0, y = p.length; _ < y; _ += 3){
                let b = p[_ + 0], A = p[_ + 1], L = p[_ + 2];
                d.push(b, A, A, L, L, b);
            }
        } else {
            let p1 = m.array;
            x = m.version;
            for(let _1 = 0, y1 = p1.length / 3 - 1; _1 < y1; _1 += 3){
                let b1 = _1 + 0, A1 = _1 + 1, L1 = _1 + 2;
                d.push(b1, A1, A1, L1, L1, b1);
            }
        }
        let v = new (Yc(d) > 65535 ? Zs : Ys)(d, 1);
        v.version = x;
        let g = r.get(u);
        g && e.remove(g), r.set(u, v);
    }
    function h(u) {
        let d = r.get(u);
        if (d) {
            let f = u.index;
            f !== null && d.version < f.version && c(u);
        } else c(u);
        return r.get(u);
    }
    return {
        get: a,
        update: l,
        getWireframeAttribute: h
    };
}
function eg(s, e, t, n) {
    let i = n.isWebGL2, r;
    function o(d) {
        r = d;
    }
    let a, l;
    function c(d) {
        a = d.type, l = d.bytesPerElement;
    }
    function h(d, f) {
        s.drawElements(r, f, a, d * l), t.update(f, r, 1);
    }
    function u(d, f, m) {
        if (m === 0) return;
        let x, v;
        if (i) x = s, v = "drawElementsInstanced";
        else if (x = e.get("ANGLE_instanced_arrays"), v = "drawElementsInstancedANGLE", x === null) {
            console.error("THREE.WebGLIndexedBufferRenderer: using THREE.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.");
            return;
        }
        x[v](r, f, a, d * l, m), t.update(f, r, m);
    }
    this.setMode = o, this.setIndex = c, this.render = h, this.renderInstances = u;
}
function tg(s) {
    let e = {
        geometries: 0,
        textures: 0
    }, t = {
        frame: 0,
        calls: 0,
        triangles: 0,
        points: 0,
        lines: 0
    };
    function n(r, o, a) {
        switch(t.calls++, o){
            case 4:
                t.triangles += a * (r / 3);
                break;
            case 1:
                t.lines += a * (r / 2);
                break;
            case 3:
                t.lines += a * (r - 1);
                break;
            case 2:
                t.lines += a * r;
                break;
            case 0:
                t.points += a * r;
                break;
            default:
                console.error("THREE.WebGLInfo: Unknown draw mode:", o);
                break;
        }
    }
    function i() {
        t.frame++, t.calls = 0, t.triangles = 0, t.points = 0, t.lines = 0;
    }
    return {
        memory: e,
        render: t,
        programs: null,
        autoReset: !0,
        reset: i,
        update: n
    };
}
var Qs = class extends ot {
    constructor(e = null, t = 1, n = 1, i = 1){
        super(null);
        this.image = {
            data: e,
            width: t,
            height: n,
            depth: i
        }, this.magFilter = rt, this.minFilter = rt, this.wrapR = vt, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
};
Qs.prototype.isDataTexture2DArray = !0;
function ng(s, e) {
    return s[0] - e[0];
}
function ig(s, e) {
    return Math.abs(e[1]) - Math.abs(s[1]);
}
function Nl(s, e) {
    let t = 1, n = e.isInterleavedBufferAttribute ? e.data.array : e.array;
    n instanceof Int8Array ? t = 127 : n instanceof Int16Array ? t = 32767 : n instanceof Int32Array ? t = 2147483647 : console.error("THREE.WebGLMorphtargets: Unsupported morph attribute data type: ", n), s.divideScalar(t);
}
function rg(s, e, t) {
    let n = {}, i = new Float32Array(8), r = new WeakMap, o = new M, a = [];
    for(let c = 0; c < 8; c++)a[c] = [
        c,
        0
    ];
    function l(c, h, u, d) {
        let f = c.morphTargetInfluences;
        if (e.isWebGL2 === !0) {
            let m = h.morphAttributes.position.length, x = r.get(h);
            if (x === void 0 || x.count !== m) {
                x !== void 0 && x.texture.dispose();
                let p = h.morphAttributes.normal !== void 0, _ = h.morphAttributes.position, y = h.morphAttributes.normal || [], b = h.attributes.position.count, A = p === !0 ? 2 : 1, L = b * A, I = 1;
                L > e.maxTextureSize && (I = Math.ceil(L / e.maxTextureSize), L = e.maxTextureSize);
                let k = new Float32Array(L * I * 4 * m), B = new Qs(k, L, I, m);
                B.format = ct, B.type = nn, B.needsUpdate = !0;
                let P = A * 4;
                for(let w = 0; w < m; w++){
                    let E = _[w], D = y[w], U = L * I * 4 * w;
                    for(let F = 0; F < E.count; F++){
                        o.fromBufferAttribute(E, F), E.normalized === !0 && Nl(o, E);
                        let O = F * P;
                        k[U + O + 0] = o.x, k[U + O + 1] = o.y, k[U + O + 2] = o.z, k[U + O + 3] = 0, p === !0 && (o.fromBufferAttribute(D, F), D.normalized === !0 && Nl(o, D), k[U + O + 4] = o.x, k[U + O + 5] = o.y, k[U + O + 6] = o.z, k[U + O + 7] = 0);
                    }
                }
                x = {
                    count: m,
                    texture: B,
                    size: new X(L, I)
                }, r.set(h, x);
            }
            let v = 0;
            for(let p1 = 0; p1 < f.length; p1++)v += f[p1];
            let g = h.morphTargetsRelative ? 1 : 1 - v;
            d.getUniforms().setValue(s, "morphTargetBaseInfluence", g), d.getUniforms().setValue(s, "morphTargetInfluences", f), d.getUniforms().setValue(s, "morphTargetsTexture", x.texture, t), d.getUniforms().setValue(s, "morphTargetsTextureSize", x.size);
        } else {
            let m1 = f === void 0 ? 0 : f.length, x1 = n[h.id];
            if (x1 === void 0 || x1.length !== m1) {
                x1 = [];
                for(let y1 = 0; y1 < m1; y1++)x1[y1] = [
                    y1,
                    0
                ];
                n[h.id] = x1;
            }
            for(let y2 = 0; y2 < m1; y2++){
                let b1 = x1[y2];
                b1[0] = y2, b1[1] = f[y2];
            }
            x1.sort(ig);
            for(let y3 = 0; y3 < 8; y3++)y3 < m1 && x1[y3][1] ? (a[y3][0] = x1[y3][0], a[y3][1] = x1[y3][1]) : (a[y3][0] = Number.MAX_SAFE_INTEGER, a[y3][1] = 0);
            a.sort(ng);
            let v1 = h.morphAttributes.position, g1 = h.morphAttributes.normal, p2 = 0;
            for(let y4 = 0; y4 < 8; y4++){
                let b2 = a[y4], A1 = b2[0], L1 = b2[1];
                A1 !== Number.MAX_SAFE_INTEGER && L1 ? (v1 && h.getAttribute("morphTarget" + y4) !== v1[A1] && h.setAttribute("morphTarget" + y4, v1[A1]), g1 && h.getAttribute("morphNormal" + y4) !== g1[A1] && h.setAttribute("morphNormal" + y4, g1[A1]), i[y4] = L1, p2 += L1) : (v1 && h.hasAttribute("morphTarget" + y4) === !0 && h.deleteAttribute("morphTarget" + y4), g1 && h.hasAttribute("morphNormal" + y4) === !0 && h.deleteAttribute("morphNormal" + y4), i[y4] = 0);
            }
            let _1 = h.morphTargetsRelative ? 1 : 1 - p2;
            d.getUniforms().setValue(s, "morphTargetBaseInfluence", _1), d.getUniforms().setValue(s, "morphTargetInfluences", i);
        }
    }
    return {
        update: l
    };
}
function sg(s, e, t, n) {
    let i = new WeakMap;
    function r(l) {
        let c = n.render.frame, h = l.geometry, u = e.get(l, h);
        return i.get(u) !== c && (e.update(u), i.set(u, c)), l.isInstancedMesh && (l.hasEventListener("dispose", a) === !1 && l.addEventListener("dispose", a), t.update(l.instanceMatrix, 34962), l.instanceColor !== null && t.update(l.instanceColor, 34962)), u;
    }
    function o() {
        i = new WeakMap;
    }
    function a(l) {
        let c = l.target;
        c.removeEventListener("dispose", a), t.remove(c.instanceMatrix), c.instanceColor !== null && t.remove(c.instanceColor);
    }
    return {
        update: r,
        dispose: o
    };
}
var ma = class extends ot {
    constructor(e = null, t = 1, n = 1, i = 1){
        super(null);
        this.image = {
            data: e,
            width: t,
            height: n,
            depth: i
        }, this.magFilter = rt, this.minFilter = rt, this.wrapR = vt, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
};
ma.prototype.isDataTexture3D = !0;
var lh = new ot, ch = new Qs, hh = new ma, uh = new ki, Bl = [], zl = [], Ul = new Float32Array(16), Ol = new Float32Array(9), Hl = new Float32Array(4);
function Vi(s, e, t) {
    let n = s[0];
    if (n <= 0 || n > 0) return s;
    let i = e * t, r = Bl[i];
    if (r === void 0 && (r = new Float32Array(i), Bl[i] = r), e !== 0) {
        n.toArray(r, 0);
        for(let o = 1, a = 0; o !== e; ++o)a += t, s[o].toArray(r, a);
    }
    return r;
}
function Mt(s, e) {
    if (s.length !== e.length) return !1;
    for(let t = 0, n = s.length; t < n; t++)if (s[t] !== e[t]) return !1;
    return !0;
}
function _t(s, e) {
    for(let t = 0, n = e.length; t < n; t++)s[t] = e[t];
}
function Ks(s, e) {
    let t = zl[e];
    t === void 0 && (t = new Int32Array(e), zl[e] = t);
    for(let n = 0; n !== e; ++n)t[n] = s.allocateTextureUnit();
    return t;
}
function og(s, e) {
    let t = this.cache;
    t[0] !== e && (s.uniform1f(this.addr, e), t[0] = e);
}
function ag(s, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y) && (s.uniform2f(this.addr, e.x, e.y), t[0] = e.x, t[1] = e.y);
    else {
        if (Mt(t, e)) return;
        s.uniform2fv(this.addr, e), _t(t, e);
    }
}
function lg(s, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z) && (s.uniform3f(this.addr, e.x, e.y, e.z), t[0] = e.x, t[1] = e.y, t[2] = e.z);
    else if (e.r !== void 0) (t[0] !== e.r || t[1] !== e.g || t[2] !== e.b) && (s.uniform3f(this.addr, e.r, e.g, e.b), t[0] = e.r, t[1] = e.g, t[2] = e.b);
    else {
        if (Mt(t, e)) return;
        s.uniform3fv(this.addr, e), _t(t, e);
    }
}
function cg(s, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z || t[3] !== e.w) && (s.uniform4f(this.addr, e.x, e.y, e.z, e.w), t[0] = e.x, t[1] = e.y, t[2] = e.z, t[3] = e.w);
    else {
        if (Mt(t, e)) return;
        s.uniform4fv(this.addr, e), _t(t, e);
    }
}
function hg(s, e) {
    let t = this.cache, n = e.elements;
    if (n === void 0) {
        if (Mt(t, e)) return;
        s.uniformMatrix2fv(this.addr, !1, e), _t(t, e);
    } else {
        if (Mt(t, n)) return;
        Hl.set(n), s.uniformMatrix2fv(this.addr, !1, Hl), _t(t, n);
    }
}
function ug(s, e) {
    let t = this.cache, n = e.elements;
    if (n === void 0) {
        if (Mt(t, e)) return;
        s.uniformMatrix3fv(this.addr, !1, e), _t(t, e);
    } else {
        if (Mt(t, n)) return;
        Ol.set(n), s.uniformMatrix3fv(this.addr, !1, Ol), _t(t, n);
    }
}
function dg(s, e) {
    let t = this.cache, n = e.elements;
    if (n === void 0) {
        if (Mt(t, e)) return;
        s.uniformMatrix4fv(this.addr, !1, e), _t(t, e);
    } else {
        if (Mt(t, n)) return;
        Ul.set(n), s.uniformMatrix4fv(this.addr, !1, Ul), _t(t, n);
    }
}
function fg(s, e) {
    let t = this.cache;
    t[0] !== e && (s.uniform1i(this.addr, e), t[0] = e);
}
function pg(s, e) {
    let t = this.cache;
    Mt(t, e) || (s.uniform2iv(this.addr, e), _t(t, e));
}
function mg(s, e) {
    let t = this.cache;
    Mt(t, e) || (s.uniform3iv(this.addr, e), _t(t, e));
}
function gg(s, e) {
    let t = this.cache;
    Mt(t, e) || (s.uniform4iv(this.addr, e), _t(t, e));
}
function xg(s, e) {
    let t = this.cache;
    t[0] !== e && (s.uniform1ui(this.addr, e), t[0] = e);
}
function yg(s, e) {
    let t = this.cache;
    Mt(t, e) || (s.uniform2uiv(this.addr, e), _t(t, e));
}
function vg(s, e) {
    let t = this.cache;
    Mt(t, e) || (s.uniform3uiv(this.addr, e), _t(t, e));
}
function _g(s, e) {
    let t = this.cache;
    Mt(t, e) || (s.uniform4uiv(this.addr, e), _t(t, e));
}
function Mg(s, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s.uniform1i(this.addr, i), n[0] = i), t.safeSetTexture2D(e || lh, i);
}
function bg(s, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s.uniform1i(this.addr, i), n[0] = i), t.setTexture3D(e || hh, i);
}
function wg(s, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s.uniform1i(this.addr, i), n[0] = i), t.safeSetTextureCube(e || uh, i);
}
function Sg(s, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s.uniform1i(this.addr, i), n[0] = i), t.setTexture2DArray(e || ch, i);
}
function Tg(s) {
    switch(s){
        case 5126:
            return og;
        case 35664:
            return ag;
        case 35665:
            return lg;
        case 35666:
            return cg;
        case 35674:
            return hg;
        case 35675:
            return ug;
        case 35676:
            return dg;
        case 5124:
        case 35670:
            return fg;
        case 35667:
        case 35671:
            return pg;
        case 35668:
        case 35672:
            return mg;
        case 35669:
        case 35673:
            return gg;
        case 5125:
            return xg;
        case 36294:
            return yg;
        case 36295:
            return vg;
        case 36296:
            return _g;
        case 35678:
        case 36198:
        case 36298:
        case 36306:
        case 35682:
            return Mg;
        case 35679:
        case 36299:
        case 36307:
            return bg;
        case 35680:
        case 36300:
        case 36308:
        case 36293:
            return wg;
        case 36289:
        case 36303:
        case 36311:
        case 36292:
            return Sg;
    }
}
function Eg(s, e) {
    s.uniform1fv(this.addr, e);
}
function Ag(s, e) {
    let t = Vi(e, this.size, 2);
    s.uniform2fv(this.addr, t);
}
function Cg(s, e) {
    let t = Vi(e, this.size, 3);
    s.uniform3fv(this.addr, t);
}
function Lg(s, e) {
    let t = Vi(e, this.size, 4);
    s.uniform4fv(this.addr, t);
}
function Rg(s, e) {
    let t = Vi(e, this.size, 4);
    s.uniformMatrix2fv(this.addr, !1, t);
}
function Pg(s, e) {
    let t = Vi(e, this.size, 9);
    s.uniformMatrix3fv(this.addr, !1, t);
}
function Ig(s, e) {
    let t = Vi(e, this.size, 16);
    s.uniformMatrix4fv(this.addr, !1, t);
}
function Dg(s, e) {
    s.uniform1iv(this.addr, e);
}
function Fg(s, e) {
    s.uniform2iv(this.addr, e);
}
function Ng(s, e) {
    s.uniform3iv(this.addr, e);
}
function Bg(s, e) {
    s.uniform4iv(this.addr, e);
}
function zg(s, e) {
    s.uniform1uiv(this.addr, e);
}
function Ug(s, e) {
    s.uniform2uiv(this.addr, e);
}
function Og(s, e) {
    s.uniform3uiv(this.addr, e);
}
function Hg(s, e) {
    s.uniform4uiv(this.addr, e);
}
function kg(s, e, t) {
    let n = e.length, i = Ks(t, n);
    s.uniform1iv(this.addr, i);
    for(let r = 0; r !== n; ++r)t.safeSetTexture2D(e[r] || lh, i[r]);
}
function Gg(s, e, t) {
    let n = e.length, i = Ks(t, n);
    s.uniform1iv(this.addr, i);
    for(let r = 0; r !== n; ++r)t.setTexture3D(e[r] || hh, i[r]);
}
function Vg(s, e, t) {
    let n = e.length, i = Ks(t, n);
    s.uniform1iv(this.addr, i);
    for(let r = 0; r !== n; ++r)t.safeSetTextureCube(e[r] || uh, i[r]);
}
function Wg(s, e, t) {
    let n = e.length, i = Ks(t, n);
    s.uniform1iv(this.addr, i);
    for(let r = 0; r !== n; ++r)t.setTexture2DArray(e[r] || ch, i[r]);
}
function qg(s) {
    switch(s){
        case 5126:
            return Eg;
        case 35664:
            return Ag;
        case 35665:
            return Cg;
        case 35666:
            return Lg;
        case 35674:
            return Rg;
        case 35675:
            return Pg;
        case 35676:
            return Ig;
        case 5124:
        case 35670:
            return Dg;
        case 35667:
        case 35671:
            return Fg;
        case 35668:
        case 35672:
            return Ng;
        case 35669:
        case 35673:
            return Bg;
        case 5125:
            return zg;
        case 36294:
            return Ug;
        case 36295:
            return Og;
        case 36296:
            return Hg;
        case 35678:
        case 36198:
        case 36298:
        case 36306:
        case 35682:
            return kg;
        case 35679:
        case 36299:
        case 36307:
            return Gg;
        case 35680:
        case 36300:
        case 36308:
        case 36293:
            return Vg;
        case 36289:
        case 36303:
        case 36311:
        case 36292:
            return Wg;
    }
}
function Xg(s, e, t) {
    this.id = s, this.addr = t, this.cache = [], this.setValue = Tg(e.type);
}
function dh(s, e, t) {
    this.id = s, this.addr = t, this.cache = [], this.size = e.size, this.setValue = qg(e.type);
}
dh.prototype.updateCache = function(s) {
    let e = this.cache;
    s instanceof Float32Array && e.length !== s.length && (this.cache = new Float32Array(s.length)), _t(e, s);
};
function fh(s) {
    this.id = s, this.seq = [], this.map = {};
}
fh.prototype.setValue = function(s, e, t) {
    let n = this.seq;
    for(let i = 0, r = n.length; i !== r; ++i){
        let o = n[i];
        o.setValue(s, e[o.id], t);
    }
};
var Wo = /(\w+)(\])?(\[|\.)?/g;
function kl(s, e) {
    s.seq.push(e), s.map[e.id] = e;
}
function Jg(s, e, t) {
    let n = s.name, i = n.length;
    for(Wo.lastIndex = 0;;){
        let r = Wo.exec(n), o = Wo.lastIndex, a = r[1], l = r[2] === "]", c = r[3];
        if (l && (a = a | 0), c === void 0 || c === "[" && o + 2 === i) {
            kl(t, c === void 0 ? new Xg(a, s, e) : new dh(a, s, e));
            break;
        } else {
            let u = t.map[a];
            u === void 0 && (u = new fh(a), kl(t, u)), t = u;
        }
    }
}
function bn(s, e) {
    this.seq = [], this.map = {};
    let t = s.getProgramParameter(e, 35718);
    for(let n = 0; n < t; ++n){
        let i = s.getActiveUniform(e, n), r = s.getUniformLocation(e, i.name);
        Jg(i, r, this);
    }
}
bn.prototype.setValue = function(s, e, t, n) {
    let i = this.map[e];
    i !== void 0 && i.setValue(s, t, n);
};
bn.prototype.setOptional = function(s, e, t) {
    let n = e[t];
    n !== void 0 && this.setValue(s, t, n);
};
bn.upload = function(s, e, t, n) {
    for(let i = 0, r = e.length; i !== r; ++i){
        let o = e[i], a = t[o.id];
        a.needsUpdate !== !1 && o.setValue(s, a.value, n);
    }
};
bn.seqWithValue = function(s, e) {
    let t = [];
    for(let n = 0, i = s.length; n !== i; ++n){
        let r = s[n];
        r.id in e && t.push(r);
    }
    return t;
};
function Gl(s, e, t) {
    let n = s.createShader(e);
    return s.shaderSource(n, t), s.compileShader(n), n;
}
var Yg = 0;
function Zg(s) {
    let e = s.split(`
`);
    for(let t = 0; t < e.length; t++)e[t] = t + 1 + ": " + e[t];
    return e.join(`
`);
}
function ph(s) {
    switch(s){
        case Nt:
            return [
                "Linear",
                "( value )"
            ];
        case Oi:
            return [
                "sRGB",
                "( value )"
            ];
        default:
            return console.warn("THREE.WebGLProgram: Unsupported encoding:", s), [
                "Linear",
                "( value )"
            ];
    }
}
function Vl(s, e, t) {
    let n = s.getShaderParameter(e, 35713), i = s.getShaderInfoLog(e).trim();
    return n && i === "" ? "" : t.toUpperCase() + `

` + i + `

` + Zg(s.getShaderSource(e));
}
function Dn(s, e) {
    let t = ph(e);
    return "vec4 " + s + "( vec4 value ) { return " + t[0] + "ToLinear" + t[1] + "; }";
}
function $g(s, e) {
    let t = ph(e);
    return "vec4 " + s + "( vec4 value ) { return LinearTo" + t[0] + t[1] + "; }";
}
function jg(s, e) {
    let t;
    switch(e){
        case Nu:
            t = "Linear";
            break;
        case Bu:
            t = "Reinhard";
            break;
        case zu:
            t = "OptimizedCineon";
            break;
        case Uu:
            t = "ACESFilmic";
            break;
        case Ou:
            t = "Custom";
            break;
        default:
            console.warn("THREE.WebGLProgram: Unsupported toneMapping:", e), t = "Linear";
    }
    return "vec3 " + s + "( vec3 color ) { return " + t + "ToneMapping( color ); }";
}
function Qg(s) {
    return [
        s.extensionDerivatives || s.envMapCubeUV || s.bumpMap || s.tangentSpaceNormalMap || s.clearcoatNormalMap || s.flatShading || s.shaderID === "physical" ? "#extension GL_OES_standard_derivatives : enable" : "",
        (s.extensionFragDepth || s.logarithmicDepthBuffer) && s.rendererExtensionFragDepth ? "#extension GL_EXT_frag_depth : enable" : "",
        s.extensionDrawBuffers && s.rendererExtensionDrawBuffers ? "#extension GL_EXT_draw_buffers : require" : "",
        (s.extensionShaderTextureLOD || s.envMap || s.transmission) && s.rendererExtensionShaderTextureLod ? "#extension GL_EXT_shader_texture_lod : enable" : ""
    ].filter(rr).join(`
`);
}
function Kg(s) {
    let e = [];
    for(let t in s){
        let n = s[t];
        n !== !1 && e.push("#define " + t + " " + n);
    }
    return e.join(`
`);
}
function ex(s, e) {
    let t = {}, n = s.getProgramParameter(e, 35721);
    for(let i = 0; i < n; i++){
        let r = s.getActiveAttrib(e, i), o = r.name, a = 1;
        r.type === 35674 && (a = 2), r.type === 35675 && (a = 3), r.type === 35676 && (a = 4), t[o] = {
            type: r.type,
            location: s.getAttribLocation(e, o),
            locationSize: a
        };
    }
    return t;
}
function rr(s) {
    return s !== "";
}
function Wl(s, e) {
    return s.replace(/NUM_DIR_LIGHTS/g, e.numDirLights).replace(/NUM_SPOT_LIGHTS/g, e.numSpotLights).replace(/NUM_RECT_AREA_LIGHTS/g, e.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g, e.numPointLights).replace(/NUM_HEMI_LIGHTS/g, e.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g, e.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS/g, e.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g, e.numPointLightShadows);
}
function ql(s, e) {
    return s.replace(/NUM_CLIPPING_PLANES/g, e.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g, e.numClippingPlanes - e.numClipIntersection);
}
var tx = /^[ \t]*#include +<([\w\d./]+)>/gm;
function ra(s) {
    return s.replace(tx, nx);
}
function nx(s, e) {
    let t = Fe[e];
    if (t === void 0) throw new Error("Can not resolve #include <" + e + ">");
    return ra(t);
}
var ix = /#pragma unroll_loop[\s]+?for \( int i \= (\d+)\; i < (\d+)\; i \+\+ \) \{([\s\S]+?)(?=\})\}/g, rx = /#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;
function Xl(s) {
    return s.replace(rx, mh).replace(ix, sx);
}
function sx(s, e, t, n) {
    return console.warn("WebGLProgram: #pragma unroll_loop shader syntax is deprecated. Please use #pragma unroll_loop_start syntax instead."), mh(s, e, t, n);
}
function mh(s, e, t, n) {
    let i = "";
    for(let r = parseInt(e); r < parseInt(t); r++)i += n.replace(/\[\s*i\s*\]/g, "[ " + r + " ]").replace(/UNROLLED_LOOP_INDEX/g, r);
    return i;
}
function Jl(s) {
    let e = "precision " + s.precision + ` float;
precision ` + s.precision + " int;";
    return s.precision === "highp" ? e += `
#define HIGH_PRECISION` : s.precision === "mediump" ? e += `
#define MEDIUM_PRECISION` : s.precision === "lowp" && (e += `
#define LOW_PRECISION`), e;
}
function ox(s) {
    let e = "SHADOWMAP_TYPE_BASIC";
    return s.shadowMapType === Hc ? e = "SHADOWMAP_TYPE_PCF" : s.shadowMapType === fu ? e = "SHADOWMAP_TYPE_PCF_SOFT" : s.shadowMapType === ir && (e = "SHADOWMAP_TYPE_VSM"), e;
}
function ax(s) {
    let e = "ENVMAP_TYPE_CUBE";
    if (s.envMap) switch(s.envMapMode){
        case Bi:
        case zi:
            e = "ENVMAP_TYPE_CUBE";
            break;
        case Pr:
        case Ws:
            e = "ENVMAP_TYPE_CUBE_UV";
            break;
    }
    return e;
}
function lx(s) {
    let e = "ENVMAP_MODE_REFLECTION";
    if (s.envMap) switch(s.envMapMode){
        case zi:
        case Ws:
            e = "ENVMAP_MODE_REFRACTION";
            break;
    }
    return e;
}
function cx(s) {
    let e = "ENVMAP_BLENDING_NONE";
    if (s.envMap) switch(s.combine){
        case Vs:
            e = "ENVMAP_BLENDING_MULTIPLY";
            break;
        case Du:
            e = "ENVMAP_BLENDING_MIX";
            break;
        case Fu:
            e = "ENVMAP_BLENDING_ADD";
            break;
    }
    return e;
}
function hx(s, e, t, n) {
    let i = s.getContext(), r = t.defines, o = t.vertexShader, a = t.fragmentShader, l = ox(t), c = ax(t), h = lx(t), u = cx(t), d = t.isWebGL2 ? "" : Qg(t), f = Kg(r), m = i.createProgram(), x, v, g = t.glslVersion ? "#version " + t.glslVersion + `
` : "";
    t.isRawShaderMaterial ? (x = [
        f
    ].filter(rr).join(`
`), x.length > 0 && (x += `
`), v = [
        d,
        f
    ].filter(rr).join(`
`), v.length > 0 && (v += `
`)) : (x = [
        Jl(t),
        "#define SHADER_NAME " + t.shaderName,
        f,
        t.instancing ? "#define USE_INSTANCING" : "",
        t.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
        t.supportsVertexTextures ? "#define VERTEX_TEXTURES" : "",
        "#define MAX_BONES " + t.maxBones,
        t.useFog && t.fog ? "#define USE_FOG" : "",
        t.useFog && t.fogExp2 ? "#define FOG_EXP2" : "",
        t.map ? "#define USE_MAP" : "",
        t.envMap ? "#define USE_ENVMAP" : "",
        t.envMap ? "#define " + h : "",
        t.lightMap ? "#define USE_LIGHTMAP" : "",
        t.aoMap ? "#define USE_AOMAP" : "",
        t.emissiveMap ? "#define USE_EMISSIVEMAP" : "",
        t.bumpMap ? "#define USE_BUMPMAP" : "",
        t.normalMap ? "#define USE_NORMALMAP" : "",
        t.normalMap && t.objectSpaceNormalMap ? "#define OBJECTSPACE_NORMALMAP" : "",
        t.normalMap && t.tangentSpaceNormalMap ? "#define TANGENTSPACE_NORMALMAP" : "",
        t.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
        t.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
        t.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",
        t.displacementMap && t.supportsVertexTextures ? "#define USE_DISPLACEMENTMAP" : "",
        t.specularMap ? "#define USE_SPECULARMAP" : "",
        t.specularIntensityMap ? "#define USE_SPECULARINTENSITYMAP" : "",
        t.specularColorMap ? "#define USE_SPECULARCOLORMAP" : "",
        t.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
        t.metalnessMap ? "#define USE_METALNESSMAP" : "",
        t.alphaMap ? "#define USE_ALPHAMAP" : "",
        t.transmission ? "#define USE_TRANSMISSION" : "",
        t.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
        t.thicknessMap ? "#define USE_THICKNESSMAP" : "",
        t.sheenColorMap ? "#define USE_SHEENCOLORMAP" : "",
        t.sheenRoughnessMap ? "#define USE_SHEENROUGHNESSMAP" : "",
        t.vertexTangents ? "#define USE_TANGENT" : "",
        t.vertexColors ? "#define USE_COLOR" : "",
        t.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
        t.vertexUvs ? "#define USE_UV" : "",
        t.uvsVertexOnly ? "#define UVS_VERTEX_ONLY" : "",
        t.flatShading ? "#define FLAT_SHADED" : "",
        t.skinning ? "#define USE_SKINNING" : "",
        t.useVertexTexture ? "#define BONE_TEXTURE" : "",
        t.morphTargets ? "#define USE_MORPHTARGETS" : "",
        t.morphNormals && t.flatShading === !1 ? "#define USE_MORPHNORMALS" : "",
        t.morphTargets && t.isWebGL2 ? "#define MORPHTARGETS_TEXTURE" : "",
        t.morphTargets && t.isWebGL2 ? "#define MORPHTARGETS_COUNT " + t.morphTargetsCount : "",
        t.doubleSided ? "#define DOUBLE_SIDED" : "",
        t.flipSided ? "#define FLIP_SIDED" : "",
        t.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
        t.shadowMapEnabled ? "#define " + l : "",
        t.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",
        t.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",
        t.logarithmicDepthBuffer && t.rendererExtensionFragDepth ? "#define USE_LOGDEPTHBUF_EXT" : "",
        "uniform mat4 modelMatrix;",
        "uniform mat4 modelViewMatrix;",
        "uniform mat4 projectionMatrix;",
        "uniform mat4 viewMatrix;",
        "uniform mat3 normalMatrix;",
        "uniform vec3 cameraPosition;",
        "uniform bool isOrthographic;",
        "#ifdef USE_INSTANCING",
        "	attribute mat4 instanceMatrix;",
        "#endif",
        "#ifdef USE_INSTANCING_COLOR",
        "	attribute vec3 instanceColor;",
        "#endif",
        "attribute vec3 position;",
        "attribute vec3 normal;",
        "attribute vec2 uv;",
        "#ifdef USE_TANGENT",
        "	attribute vec4 tangent;",
        "#endif",
        "#if defined( USE_COLOR_ALPHA )",
        "	attribute vec4 color;",
        "#elif defined( USE_COLOR )",
        "	attribute vec3 color;",
        "#endif",
        "#if ( defined( USE_MORPHTARGETS ) && ! defined( MORPHTARGETS_TEXTURE ) )",
        "	attribute vec3 morphTarget0;",
        "	attribute vec3 morphTarget1;",
        "	attribute vec3 morphTarget2;",
        "	attribute vec3 morphTarget3;",
        "	#ifdef USE_MORPHNORMALS",
        "		attribute vec3 morphNormal0;",
        "		attribute vec3 morphNormal1;",
        "		attribute vec3 morphNormal2;",
        "		attribute vec3 morphNormal3;",
        "	#else",
        "		attribute vec3 morphTarget4;",
        "		attribute vec3 morphTarget5;",
        "		attribute vec3 morphTarget6;",
        "		attribute vec3 morphTarget7;",
        "	#endif",
        "#endif",
        "#ifdef USE_SKINNING",
        "	attribute vec4 skinIndex;",
        "	attribute vec4 skinWeight;",
        "#endif",
        `
`
    ].filter(rr).join(`
`), v = [
        d,
        Jl(t),
        "#define SHADER_NAME " + t.shaderName,
        f,
        t.useFog && t.fog ? "#define USE_FOG" : "",
        t.useFog && t.fogExp2 ? "#define FOG_EXP2" : "",
        t.map ? "#define USE_MAP" : "",
        t.matcap ? "#define USE_MATCAP" : "",
        t.envMap ? "#define USE_ENVMAP" : "",
        t.envMap ? "#define " + c : "",
        t.envMap ? "#define " + h : "",
        t.envMap ? "#define " + u : "",
        t.lightMap ? "#define USE_LIGHTMAP" : "",
        t.aoMap ? "#define USE_AOMAP" : "",
        t.emissiveMap ? "#define USE_EMISSIVEMAP" : "",
        t.bumpMap ? "#define USE_BUMPMAP" : "",
        t.normalMap ? "#define USE_NORMALMAP" : "",
        t.normalMap && t.objectSpaceNormalMap ? "#define OBJECTSPACE_NORMALMAP" : "",
        t.normalMap && t.tangentSpaceNormalMap ? "#define TANGENTSPACE_NORMALMAP" : "",
        t.clearcoat ? "#define USE_CLEARCOAT" : "",
        t.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
        t.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
        t.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",
        t.specularMap ? "#define USE_SPECULARMAP" : "",
        t.specularIntensityMap ? "#define USE_SPECULARINTENSITYMAP" : "",
        t.specularColorMap ? "#define USE_SPECULARCOLORMAP" : "",
        t.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
        t.metalnessMap ? "#define USE_METALNESSMAP" : "",
        t.alphaMap ? "#define USE_ALPHAMAP" : "",
        t.alphaTest ? "#define USE_ALPHATEST" : "",
        t.sheen ? "#define USE_SHEEN" : "",
        t.sheenColorMap ? "#define USE_SHEENCOLORMAP" : "",
        t.sheenRoughnessMap ? "#define USE_SHEENROUGHNESSMAP" : "",
        t.transmission ? "#define USE_TRANSMISSION" : "",
        t.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
        t.thicknessMap ? "#define USE_THICKNESSMAP" : "",
        t.vertexTangents ? "#define USE_TANGENT" : "",
        t.vertexColors || t.instancingColor ? "#define USE_COLOR" : "",
        t.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
        t.vertexUvs ? "#define USE_UV" : "",
        t.uvsVertexOnly ? "#define UVS_VERTEX_ONLY" : "",
        t.gradientMap ? "#define USE_GRADIENTMAP" : "",
        t.flatShading ? "#define FLAT_SHADED" : "",
        t.doubleSided ? "#define DOUBLE_SIDED" : "",
        t.flipSided ? "#define FLIP_SIDED" : "",
        t.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
        t.shadowMapEnabled ? "#define " + l : "",
        t.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",
        t.physicallyCorrectLights ? "#define PHYSICALLY_CORRECT_LIGHTS" : "",
        t.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",
        t.logarithmicDepthBuffer && t.rendererExtensionFragDepth ? "#define USE_LOGDEPTHBUF_EXT" : "",
        (t.extensionShaderTextureLOD || t.envMap) && t.rendererExtensionShaderTextureLod ? "#define TEXTURE_LOD_EXT" : "",
        "uniform mat4 viewMatrix;",
        "uniform vec3 cameraPosition;",
        "uniform bool isOrthographic;",
        t.toneMapping !== _n ? "#define TONE_MAPPING" : "",
        t.toneMapping !== _n ? Fe.tonemapping_pars_fragment : "",
        t.toneMapping !== _n ? jg("toneMapping", t.toneMapping) : "",
        t.dithering ? "#define DITHERING" : "",
        t.format === Gn ? "#define OPAQUE" : "",
        Fe.encodings_pars_fragment,
        t.map ? Dn("mapTexelToLinear", t.mapEncoding) : "",
        t.matcap ? Dn("matcapTexelToLinear", t.matcapEncoding) : "",
        t.envMap ? Dn("envMapTexelToLinear", t.envMapEncoding) : "",
        t.emissiveMap ? Dn("emissiveMapTexelToLinear", t.emissiveMapEncoding) : "",
        t.specularColorMap ? Dn("specularColorMapTexelToLinear", t.specularColorMapEncoding) : "",
        t.sheenColorMap ? Dn("sheenColorMapTexelToLinear", t.sheenColorMapEncoding) : "",
        t.lightMap ? Dn("lightMapTexelToLinear", t.lightMapEncoding) : "",
        $g("linearToOutputTexel", t.outputEncoding),
        t.depthPacking ? "#define DEPTH_PACKING " + t.depthPacking : "",
        `
`
    ].filter(rr).join(`
`)), o = ra(o), o = Wl(o, t), o = ql(o, t), a = ra(a), a = Wl(a, t), a = ql(a, t), o = Xl(o), a = Xl(a), t.isWebGL2 && t.isRawShaderMaterial !== !0 && (g = `#version 300 es
`, x = [
        "precision mediump sampler2DArray;",
        "#define attribute in",
        "#define varying out",
        "#define texture2D texture"
    ].join(`
`) + `
` + x, v = [
        "#define varying in",
        t.glslVersion === xl ? "" : "layout(location = 0) out highp vec4 pc_fragColor;",
        t.glslVersion === xl ? "" : "#define gl_FragColor pc_fragColor",
        "#define gl_FragDepthEXT gl_FragDepth",
        "#define texture2D texture",
        "#define textureCube texture",
        "#define texture2DProj textureProj",
        "#define texture2DLodEXT textureLod",
        "#define texture2DProjLodEXT textureProjLod",
        "#define textureCubeLodEXT textureLod",
        "#define texture2DGradEXT textureGrad",
        "#define texture2DProjGradEXT textureProjGrad",
        "#define textureCubeGradEXT textureGrad"
    ].join(`
`) + `
` + v);
    let p = g + x + o, _ = g + v + a, y = Gl(i, 35633, p), b = Gl(i, 35632, _);
    if (i.attachShader(m, y), i.attachShader(m, b), t.index0AttributeName !== void 0 ? i.bindAttribLocation(m, 0, t.index0AttributeName) : t.morphTargets === !0 && i.bindAttribLocation(m, 0, "position"), i.linkProgram(m), s.debug.checkShaderErrors) {
        let I = i.getProgramInfoLog(m).trim(), k = i.getShaderInfoLog(y).trim(), B = i.getShaderInfoLog(b).trim(), P = !0, w = !0;
        if (i.getProgramParameter(m, 35714) === !1) {
            P = !1;
            let E = Vl(i, y, "vertex"), D = Vl(i, b, "fragment");
            console.error("THREE.WebGLProgram: Shader Error " + i.getError() + " - VALIDATE_STATUS " + i.getProgramParameter(m, 35715) + `

Program Info Log: ` + I + `
` + E + `
` + D);
        } else I !== "" ? console.warn("THREE.WebGLProgram: Program Info Log:", I) : (k === "" || B === "") && (w = !1);
        w && (this.diagnostics = {
            runnable: P,
            programLog: I,
            vertexShader: {
                log: k,
                prefix: x
            },
            fragmentShader: {
                log: B,
                prefix: v
            }
        });
    }
    i.deleteShader(y), i.deleteShader(b);
    let A;
    this.getUniforms = function() {
        return A === void 0 && (A = new bn(i, m)), A;
    };
    let L;
    return this.getAttributes = function() {
        return L === void 0 && (L = ex(i, m)), L;
    }, this.destroy = function() {
        n.releaseStatesOfProgram(this), i.deleteProgram(m), this.program = void 0;
    }, this.name = t.shaderName, this.id = Yg++, this.cacheKey = e, this.usedTimes = 1, this.program = m, this.vertexShader = y, this.fragmentShader = b, this;
}
var ux = 0, gh = class {
    constructor(){
        this.shaderCache = new Map, this.materialCache = new Map;
    }
    update(e) {
        let t = e.vertexShader, n = e.fragmentShader, i = this._getShaderStage(t), r = this._getShaderStage(n), o = this._getShaderCacheForMaterial(e);
        return o.has(i) === !1 && (o.add(i), i.usedTimes++), o.has(r) === !1 && (o.add(r), r.usedTimes++), this;
    }
    remove(e) {
        let t = this.materialCache.get(e);
        for (let n of t)n.usedTimes--, n.usedTimes === 0 && this.shaderCache.delete(n);
        return this.materialCache.delete(e), this;
    }
    getVertexShaderID(e) {
        return this._getShaderStage(e.vertexShader).id;
    }
    getFragmentShaderID(e) {
        return this._getShaderStage(e.fragmentShader).id;
    }
    dispose() {
        this.shaderCache.clear(), this.materialCache.clear();
    }
    _getShaderCacheForMaterial(e) {
        let t = this.materialCache;
        return t.has(e) === !1 && t.set(e, new Set), t.get(e);
    }
    _getShaderStage(e) {
        let t = this.shaderCache;
        if (t.has(e) === !1) {
            let n = new xh;
            t.set(e, n);
        }
        return t.get(e);
    }
}, xh = class {
    constructor(){
        this.id = ux++, this.usedTimes = 0;
    }
};
function dx(s, e, t, n, i, r, o) {
    let a = new Js, l = new gh, c = [], h = i.isWebGL2, u = i.logarithmicDepthBuffer, d = i.floatVertexTextures, f = i.maxVertexUniforms, m = i.vertexTextures, x = i.precision, v = {
        MeshDepthMaterial: "depth",
        MeshDistanceMaterial: "distanceRGBA",
        MeshNormalMaterial: "normal",
        MeshBasicMaterial: "basic",
        MeshLambertMaterial: "lambert",
        MeshPhongMaterial: "phong",
        MeshToonMaterial: "toon",
        MeshStandardMaterial: "physical",
        MeshPhysicalMaterial: "physical",
        MeshMatcapMaterial: "matcap",
        LineBasicMaterial: "basic",
        LineDashedMaterial: "dashed",
        PointsMaterial: "points",
        ShadowMaterial: "shadow",
        SpriteMaterial: "sprite"
    };
    function g(w) {
        let D = w.skeleton.bones;
        if (d) return 1024;
        {
            let F = Math.floor((f - 20) / 4), O = Math.min(F, D.length);
            return O < D.length ? (console.warn("THREE.WebGLRenderer: Skeleton has " + D.length + " bones. This GPU supports " + O + "."), 0) : O;
        }
    }
    function p(w) {
        let E;
        return w && w.isTexture ? E = w.encoding : w && w.isWebGLRenderTarget ? (console.warn("THREE.WebGLPrograms.getTextureEncodingFromMap: don't use render targets as textures. Use their .texture property instead."), E = w.texture.encoding) : E = Nt, h && w && w.isTexture && w.format === ct && w.type === rn && w.encoding === Oi && (E = Nt), E;
    }
    function _(w, E, D, U, F) {
        let O = U.fog, ne = w.isMeshStandardMaterial ? U.environment : null, ce = (w.isMeshStandardMaterial ? t : e).get(w.envMap || ne), V = v[w.type], W = F.isSkinnedMesh ? g(F) : 0;
        w.precision !== null && (x = i.getMaxPrecision(w.precision), x !== w.precision && console.warn("THREE.WebGLProgram.getParameters:", w.precision, "not supported, using", x, "instead."));
        let he, le, fe, Be;
        if (V) {
            let xe = qt[V];
            he = xe.vertexShader, le = xe.fragmentShader;
        } else he = w.vertexShader, le = w.fragmentShader, l.update(w), fe = l.getVertexShaderID(w), Be = l.getFragmentShaderID(w);
        let Y = s.getRenderTarget(), Ce = w.alphaTest > 0, ye = w.clearcoat > 0;
        return {
            isWebGL2: h,
            shaderID: V,
            shaderName: w.type,
            vertexShader: he,
            fragmentShader: le,
            defines: w.defines,
            customVertexShaderID: fe,
            customFragmentShaderID: Be,
            isRawShaderMaterial: w.isRawShaderMaterial === !0,
            glslVersion: w.glslVersion,
            precision: x,
            instancing: F.isInstancedMesh === !0,
            instancingColor: F.isInstancedMesh === !0 && F.instanceColor !== null,
            supportsVertexTextures: m,
            outputEncoding: Y !== null ? p(Y.texture) : s.outputEncoding,
            map: !!w.map,
            mapEncoding: p(w.map),
            matcap: !!w.matcap,
            matcapEncoding: p(w.matcap),
            envMap: !!ce,
            envMapMode: ce && ce.mapping,
            envMapEncoding: p(ce),
            envMapCubeUV: !!ce && (ce.mapping === Pr || ce.mapping === Ws),
            lightMap: !!w.lightMap,
            lightMapEncoding: p(w.lightMap),
            aoMap: !!w.aoMap,
            emissiveMap: !!w.emissiveMap,
            emissiveMapEncoding: p(w.emissiveMap),
            bumpMap: !!w.bumpMap,
            normalMap: !!w.normalMap,
            objectSpaceNormalMap: w.normalMapType === zd,
            tangentSpaceNormalMap: w.normalMapType === Hi,
            clearcoat: ye,
            clearcoatMap: ye && !!w.clearcoatMap,
            clearcoatRoughnessMap: ye && !!w.clearcoatRoughnessMap,
            clearcoatNormalMap: ye && !!w.clearcoatNormalMap,
            displacementMap: !!w.displacementMap,
            roughnessMap: !!w.roughnessMap,
            metalnessMap: !!w.metalnessMap,
            specularMap: !!w.specularMap,
            specularIntensityMap: !!w.specularIntensityMap,
            specularColorMap: !!w.specularColorMap,
            specularColorMapEncoding: p(w.specularColorMap),
            alphaMap: !!w.alphaMap,
            alphaTest: Ce,
            gradientMap: !!w.gradientMap,
            sheen: w.sheen > 0,
            sheenColorMap: !!w.sheenColorMap,
            sheenColorMapEncoding: p(w.sheenColorMap),
            sheenRoughnessMap: !!w.sheenRoughnessMap,
            transmission: w.transmission > 0,
            transmissionMap: !!w.transmissionMap,
            thicknessMap: !!w.thicknessMap,
            combine: w.combine,
            vertexTangents: !!w.normalMap && !!F.geometry && !!F.geometry.attributes.tangent,
            vertexColors: w.vertexColors,
            vertexAlphas: w.vertexColors === !0 && !!F.geometry && !!F.geometry.attributes.color && F.geometry.attributes.color.itemSize === 4,
            vertexUvs: !!w.map || !!w.bumpMap || !!w.normalMap || !!w.specularMap || !!w.alphaMap || !!w.emissiveMap || !!w.roughnessMap || !!w.metalnessMap || !!w.clearcoatMap || !!w.clearcoatRoughnessMap || !!w.clearcoatNormalMap || !!w.displacementMap || !!w.transmissionMap || !!w.thicknessMap || !!w.specularIntensityMap || !!w.specularColorMap || !!w.sheenColorMap || !!w.sheenRoughnessMap,
            uvsVertexOnly: !(!!w.map || !!w.bumpMap || !!w.normalMap || !!w.specularMap || !!w.alphaMap || !!w.emissiveMap || !!w.roughnessMap || !!w.metalnessMap || !!w.clearcoatNormalMap || w.transmission > 0 || !!w.transmissionMap || !!w.thicknessMap || !!w.specularIntensityMap || !!w.specularColorMap || w.sheen > 0 || !!w.sheenColorMap || !!w.sheenRoughnessMap) && !!w.displacementMap,
            fog: !!O,
            useFog: w.fog,
            fogExp2: O && O.isFogExp2,
            flatShading: !!w.flatShading,
            sizeAttenuation: w.sizeAttenuation,
            logarithmicDepthBuffer: u,
            skinning: F.isSkinnedMesh === !0 && W > 0,
            maxBones: W,
            useVertexTexture: d,
            morphTargets: !!F.geometry && !!F.geometry.morphAttributes.position,
            morphNormals: !!F.geometry && !!F.geometry.morphAttributes.normal,
            morphTargetsCount: !!F.geometry && !!F.geometry.morphAttributes.position ? F.geometry.morphAttributes.position.length : 0,
            numDirLights: E.directional.length,
            numPointLights: E.point.length,
            numSpotLights: E.spot.length,
            numRectAreaLights: E.rectArea.length,
            numHemiLights: E.hemi.length,
            numDirLightShadows: E.directionalShadowMap.length,
            numPointLightShadows: E.pointShadowMap.length,
            numSpotLightShadows: E.spotShadowMap.length,
            numClippingPlanes: o.numPlanes,
            numClipIntersection: o.numIntersection,
            format: w.format,
            dithering: w.dithering,
            shadowMapEnabled: s.shadowMap.enabled && D.length > 0,
            shadowMapType: s.shadowMap.type,
            toneMapping: w.toneMapped ? s.toneMapping : _n,
            physicallyCorrectLights: s.physicallyCorrectLights,
            premultipliedAlpha: w.premultipliedAlpha,
            doubleSided: w.side === Ci,
            flipSided: w.side === it,
            depthPacking: w.depthPacking !== void 0 ? w.depthPacking : !1,
            index0AttributeName: w.index0AttributeName,
            extensionDerivatives: w.extensions && w.extensions.derivatives,
            extensionFragDepth: w.extensions && w.extensions.fragDepth,
            extensionDrawBuffers: w.extensions && w.extensions.drawBuffers,
            extensionShaderTextureLOD: w.extensions && w.extensions.shaderTextureLOD,
            rendererExtensionFragDepth: h || n.has("EXT_frag_depth"),
            rendererExtensionDrawBuffers: h || n.has("WEBGL_draw_buffers"),
            rendererExtensionShaderTextureLod: h || n.has("EXT_shader_texture_lod"),
            customProgramCacheKey: w.customProgramCacheKey()
        };
    }
    function y(w) {
        let E = [];
        if (w.shaderID ? E.push(w.shaderID) : (E.push(w.customVertexShaderID), E.push(w.customFragmentShaderID)), w.defines !== void 0) for(let D in w.defines)E.push(D), E.push(w.defines[D]);
        return w.isRawShaderMaterial === !1 && (b(E, w), A(E, w), E.push(s.outputEncoding)), E.push(w.customProgramCacheKey), E.join();
    }
    function b(w, E) {
        w.push(E.precision), w.push(E.outputEncoding), w.push(E.mapEncoding), w.push(E.matcapEncoding), w.push(E.envMapMode), w.push(E.envMapEncoding), w.push(E.lightMapEncoding), w.push(E.emissiveMapEncoding), w.push(E.combine), w.push(E.vertexUvs), w.push(E.fogExp2), w.push(E.sizeAttenuation), w.push(E.maxBones), w.push(E.morphTargetsCount), w.push(E.numDirLights), w.push(E.numPointLights), w.push(E.numSpotLights), w.push(E.numHemiLights), w.push(E.numRectAreaLights), w.push(E.numDirLightShadows), w.push(E.numPointLightShadows), w.push(E.numSpotLightShadows), w.push(E.shadowMapType), w.push(E.toneMapping), w.push(E.numClippingPlanes), w.push(E.numClipIntersection), w.push(E.format), w.push(E.specularColorMapEncoding), w.push(E.sheenColorMapEncoding);
    }
    function A(w, E) {
        a.disableAll(), E.isWebGL2 && a.enable(0), E.supportsVertexTextures && a.enable(1), E.instancing && a.enable(2), E.instancingColor && a.enable(3), E.map && a.enable(4), E.matcap && a.enable(5), E.envMap && a.enable(6), E.envMapCubeUV && a.enable(7), E.lightMap && a.enable(8), E.aoMap && a.enable(9), E.emissiveMap && a.enable(10), E.bumpMap && a.enable(11), E.normalMap && a.enable(12), E.objectSpaceNormalMap && a.enable(13), E.tangentSpaceNormalMap && a.enable(14), E.clearcoat && a.enable(15), E.clearcoatMap && a.enable(16), E.clearcoatRoughnessMap && a.enable(17), E.clearcoatNormalMap && a.enable(18), E.displacementMap && a.enable(19), E.specularMap && a.enable(20), E.roughnessMap && a.enable(21), E.metalnessMap && a.enable(22), E.gradientMap && a.enable(23), E.alphaMap && a.enable(24), E.alphaTest && a.enable(25), E.vertexColors && a.enable(26), E.vertexAlphas && a.enable(27), E.vertexUvs && a.enable(28), E.vertexTangents && a.enable(29), E.uvsVertexOnly && a.enable(30), E.fog && a.enable(31), w.push(a.mask), a.disableAll(), E.useFog && a.enable(0), E.flatShading && a.enable(1), E.logarithmicDepthBuffer && a.enable(2), E.skinning && a.enable(3), E.useVertexTexture && a.enable(4), E.morphTargets && a.enable(5), E.morphNormals && a.enable(6), E.premultipliedAlpha && a.enable(7), E.shadowMapEnabled && a.enable(8), E.physicallyCorrectLights && a.enable(9), E.doubleSided && a.enable(10), E.flipSided && a.enable(11), E.depthPacking && a.enable(12), E.dithering && a.enable(13), E.specularIntensityMap && a.enable(14), E.specularColorMap && a.enable(15), E.transmission && a.enable(16), E.transmissionMap && a.enable(17), E.thicknessMap && a.enable(18), E.sheen && a.enable(19), E.sheenColorMap && a.enable(20), E.sheenRoughnessMap && a.enable(21), w.push(a.mask);
    }
    function L(w) {
        let E = v[w.type], D;
        if (E) {
            let U = qt[E];
            D = uf.clone(U.uniforms);
        } else D = w.uniforms;
        return D;
    }
    function I(w, E) {
        let D;
        for(let U = 0, F = c.length; U < F; U++){
            let O = c[U];
            if (O.cacheKey === E) {
                D = O, ++D.usedTimes;
                break;
            }
        }
        return D === void 0 && (D = new hx(s, E, w, r), c.push(D)), D;
    }
    function k(w) {
        if (--w.usedTimes === 0) {
            let E = c.indexOf(w);
            c[E] = c[c.length - 1], c.pop(), w.destroy();
        }
    }
    function B(w) {
        l.remove(w);
    }
    function P() {
        l.dispose();
    }
    return {
        getParameters: _,
        getProgramCacheKey: y,
        getUniforms: L,
        acquireProgram: I,
        releaseProgram: k,
        releaseShaderCache: B,
        programs: c,
        dispose: P
    };
}
function fx() {
    let s = new WeakMap;
    function e(r) {
        let o = s.get(r);
        return o === void 0 && (o = {}, s.set(r, o)), o;
    }
    function t(r) {
        s.delete(r);
    }
    function n(r, o, a) {
        s.get(r)[o] = a;
    }
    function i() {
        s = new WeakMap;
    }
    return {
        get: e,
        remove: t,
        update: n,
        dispose: i
    };
}
function px(s, e) {
    return s.groupOrder !== e.groupOrder ? s.groupOrder - e.groupOrder : s.renderOrder !== e.renderOrder ? s.renderOrder - e.renderOrder : s.material.id !== e.material.id ? s.material.id - e.material.id : s.z !== e.z ? s.z - e.z : s.id - e.id;
}
function Yl(s, e) {
    return s.groupOrder !== e.groupOrder ? s.groupOrder - e.groupOrder : s.renderOrder !== e.renderOrder ? s.renderOrder - e.renderOrder : s.z !== e.z ? e.z - s.z : s.id - e.id;
}
function Zl() {
    let s = [], e = 0, t = [], n = [], i = [];
    function r() {
        e = 0, t.length = 0, n.length = 0, i.length = 0;
    }
    function o(u, d, f, m, x, v) {
        let g = s[e];
        return g === void 0 ? (g = {
            id: u.id,
            object: u,
            geometry: d,
            material: f,
            groupOrder: m,
            renderOrder: u.renderOrder,
            z: x,
            group: v
        }, s[e] = g) : (g.id = u.id, g.object = u, g.geometry = d, g.material = f, g.groupOrder = m, g.renderOrder = u.renderOrder, g.z = x, g.group = v), e++, g;
    }
    function a(u, d, f, m, x, v) {
        let g = o(u, d, f, m, x, v);
        f.transmission > 0 ? n.push(g) : f.transparent === !0 ? i.push(g) : t.push(g);
    }
    function l(u, d, f, m, x, v) {
        let g = o(u, d, f, m, x, v);
        f.transmission > 0 ? n.unshift(g) : f.transparent === !0 ? i.unshift(g) : t.unshift(g);
    }
    function c(u, d) {
        t.length > 1 && t.sort(u || px), n.length > 1 && n.sort(d || Yl), i.length > 1 && i.sort(d || Yl);
    }
    function h() {
        for(let u = e, d = s.length; u < d; u++){
            let f = s[u];
            if (f.id === null) break;
            f.id = null, f.object = null, f.geometry = null, f.material = null, f.group = null;
        }
    }
    return {
        opaque: t,
        transmissive: n,
        transparent: i,
        init: r,
        push: a,
        unshift: l,
        finish: h,
        sort: c
    };
}
function mx() {
    let s = new WeakMap;
    function e(n, i) {
        let r;
        return s.has(n) === !1 ? (r = new Zl, s.set(n, [
            r
        ])) : i >= s.get(n).length ? (r = new Zl, s.get(n).push(r)) : r = s.get(n)[i], r;
    }
    function t() {
        s = new WeakMap;
    }
    return {
        get: e,
        dispose: t
    };
}
function gx() {
    let s = {};
    return {
        get: function(e) {
            if (s[e.id] !== void 0) return s[e.id];
            let t;
            switch(e.type){
                case "DirectionalLight":
                    t = {
                        direction: new M,
                        color: new ae
                    };
                    break;
                case "SpotLight":
                    t = {
                        position: new M,
                        direction: new M,
                        color: new ae,
                        distance: 0,
                        coneCos: 0,
                        penumbraCos: 0,
                        decay: 0
                    };
                    break;
                case "PointLight":
                    t = {
                        position: new M,
                        color: new ae,
                        distance: 0,
                        decay: 0
                    };
                    break;
                case "HemisphereLight":
                    t = {
                        direction: new M,
                        skyColor: new ae,
                        groundColor: new ae
                    };
                    break;
                case "RectAreaLight":
                    t = {
                        color: new ae,
                        position: new M,
                        halfWidth: new M,
                        halfHeight: new M
                    };
                    break;
            }
            return s[e.id] = t, t;
        }
    };
}
function xx() {
    let s = {};
    return {
        get: function(e) {
            if (s[e.id] !== void 0) return s[e.id];
            let t;
            switch(e.type){
                case "DirectionalLight":
                    t = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new X
                    };
                    break;
                case "SpotLight":
                    t = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new X
                    };
                    break;
                case "PointLight":
                    t = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new X,
                        shadowCameraNear: 1,
                        shadowCameraFar: 1e3
                    };
                    break;
            }
            return s[e.id] = t, t;
        }
    };
}
var yx = 0;
function vx(s, e) {
    return (e.castShadow ? 1 : 0) - (s.castShadow ? 1 : 0);
}
function _x(s, e) {
    let t = new gx, n = xx(), i = {
        version: 0,
        hash: {
            directionalLength: -1,
            pointLength: -1,
            spotLength: -1,
            rectAreaLength: -1,
            hemiLength: -1,
            numDirectionalShadows: -1,
            numPointShadows: -1,
            numSpotShadows: -1
        },
        ambient: [
            0,
            0,
            0
        ],
        probe: [],
        directional: [],
        directionalShadow: [],
        directionalShadowMap: [],
        directionalShadowMatrix: [],
        spot: [],
        spotShadow: [],
        spotShadowMap: [],
        spotShadowMatrix: [],
        rectArea: [],
        rectAreaLTC1: null,
        rectAreaLTC2: null,
        point: [],
        pointShadow: [],
        pointShadowMap: [],
        pointShadowMatrix: [],
        hemi: []
    };
    for(let h = 0; h < 9; h++)i.probe.push(new M);
    let r = new M, o = new pe, a = new pe;
    function l(h, u) {
        let d = 0, f = 0, m = 0;
        for(let k = 0; k < 9; k++)i.probe[k].set(0, 0, 0);
        let x = 0, v = 0, g = 0, p = 0, _ = 0, y = 0, b = 0, A = 0;
        h.sort(vx);
        let L = u !== !0 ? Math.PI : 1;
        for(let k1 = 0, B = h.length; k1 < B; k1++){
            let P = h[k1], w = P.color, E = P.intensity, D = P.distance, U = P.shadow && P.shadow.map ? P.shadow.map.texture : null;
            if (P.isAmbientLight) d += w.r * E * L, f += w.g * E * L, m += w.b * E * L;
            else if (P.isLightProbe) for(let F = 0; F < 9; F++)i.probe[F].addScaledVector(P.sh.coefficients[F], E);
            else if (P.isDirectionalLight) {
                let F1 = t.get(P);
                if (F1.color.copy(P.color).multiplyScalar(P.intensity * L), P.castShadow) {
                    let O = P.shadow, ne = n.get(P);
                    ne.shadowBias = O.bias, ne.shadowNormalBias = O.normalBias, ne.shadowRadius = O.radius, ne.shadowMapSize = O.mapSize, i.directionalShadow[x] = ne, i.directionalShadowMap[x] = U, i.directionalShadowMatrix[x] = P.shadow.matrix, y++;
                }
                i.directional[x] = F1, x++;
            } else if (P.isSpotLight) {
                let F2 = t.get(P);
                if (F2.position.setFromMatrixPosition(P.matrixWorld), F2.color.copy(w).multiplyScalar(E * L), F2.distance = D, F2.coneCos = Math.cos(P.angle), F2.penumbraCos = Math.cos(P.angle * (1 - P.penumbra)), F2.decay = P.decay, P.castShadow) {
                    let O1 = P.shadow, ne1 = n.get(P);
                    ne1.shadowBias = O1.bias, ne1.shadowNormalBias = O1.normalBias, ne1.shadowRadius = O1.radius, ne1.shadowMapSize = O1.mapSize, i.spotShadow[g] = ne1, i.spotShadowMap[g] = U, i.spotShadowMatrix[g] = P.shadow.matrix, A++;
                }
                i.spot[g] = F2, g++;
            } else if (P.isRectAreaLight) {
                let F3 = t.get(P);
                F3.color.copy(w).multiplyScalar(E), F3.halfWidth.set(P.width * .5, 0, 0), F3.halfHeight.set(0, P.height * .5, 0), i.rectArea[p] = F3, p++;
            } else if (P.isPointLight) {
                let F4 = t.get(P);
                if (F4.color.copy(P.color).multiplyScalar(P.intensity * L), F4.distance = P.distance, F4.decay = P.decay, P.castShadow) {
                    let O2 = P.shadow, ne2 = n.get(P);
                    ne2.shadowBias = O2.bias, ne2.shadowNormalBias = O2.normalBias, ne2.shadowRadius = O2.radius, ne2.shadowMapSize = O2.mapSize, ne2.shadowCameraNear = O2.camera.near, ne2.shadowCameraFar = O2.camera.far, i.pointShadow[v] = ne2, i.pointShadowMap[v] = U, i.pointShadowMatrix[v] = P.shadow.matrix, b++;
                }
                i.point[v] = F4, v++;
            } else if (P.isHemisphereLight) {
                let F5 = t.get(P);
                F5.skyColor.copy(P.color).multiplyScalar(E * L), F5.groundColor.copy(P.groundColor).multiplyScalar(E * L), i.hemi[_] = F5, _++;
            }
        }
        p > 0 && (e.isWebGL2 || s.has("OES_texture_float_linear") === !0 ? (i.rectAreaLTC1 = ie.LTC_FLOAT_1, i.rectAreaLTC2 = ie.LTC_FLOAT_2) : s.has("OES_texture_half_float_linear") === !0 ? (i.rectAreaLTC1 = ie.LTC_HALF_1, i.rectAreaLTC2 = ie.LTC_HALF_2) : console.error("THREE.WebGLRenderer: Unable to use RectAreaLight. Missing WebGL extensions.")), i.ambient[0] = d, i.ambient[1] = f, i.ambient[2] = m;
        let I = i.hash;
        (I.directionalLength !== x || I.pointLength !== v || I.spotLength !== g || I.rectAreaLength !== p || I.hemiLength !== _ || I.numDirectionalShadows !== y || I.numPointShadows !== b || I.numSpotShadows !== A) && (i.directional.length = x, i.spot.length = g, i.rectArea.length = p, i.point.length = v, i.hemi.length = _, i.directionalShadow.length = y, i.directionalShadowMap.length = y, i.pointShadow.length = b, i.pointShadowMap.length = b, i.spotShadow.length = A, i.spotShadowMap.length = A, i.directionalShadowMatrix.length = y, i.pointShadowMatrix.length = b, i.spotShadowMatrix.length = A, I.directionalLength = x, I.pointLength = v, I.spotLength = g, I.rectAreaLength = p, I.hemiLength = _, I.numDirectionalShadows = y, I.numPointShadows = b, I.numSpotShadows = A, i.version = yx++);
    }
    function c(h, u) {
        let d = 0, f = 0, m = 0, x = 0, v = 0, g = u.matrixWorldInverse;
        for(let p = 0, _ = h.length; p < _; p++){
            let y = h[p];
            if (y.isDirectionalLight) {
                let b = i.directional[d];
                b.direction.setFromMatrixPosition(y.matrixWorld), r.setFromMatrixPosition(y.target.matrixWorld), b.direction.sub(r), b.direction.transformDirection(g), d++;
            } else if (y.isSpotLight) {
                let b1 = i.spot[m];
                b1.position.setFromMatrixPosition(y.matrixWorld), b1.position.applyMatrix4(g), b1.direction.setFromMatrixPosition(y.matrixWorld), r.setFromMatrixPosition(y.target.matrixWorld), b1.direction.sub(r), b1.direction.transformDirection(g), m++;
            } else if (y.isRectAreaLight) {
                let b2 = i.rectArea[x];
                b2.position.setFromMatrixPosition(y.matrixWorld), b2.position.applyMatrix4(g), a.identity(), o.copy(y.matrixWorld), o.premultiply(g), a.extractRotation(o), b2.halfWidth.set(y.width * .5, 0, 0), b2.halfHeight.set(0, y.height * .5, 0), b2.halfWidth.applyMatrix4(a), b2.halfHeight.applyMatrix4(a), x++;
            } else if (y.isPointLight) {
                let b3 = i.point[f];
                b3.position.setFromMatrixPosition(y.matrixWorld), b3.position.applyMatrix4(g), f++;
            } else if (y.isHemisphereLight) {
                let b4 = i.hemi[v];
                b4.direction.setFromMatrixPosition(y.matrixWorld), b4.direction.transformDirection(g), b4.direction.normalize(), v++;
            }
        }
    }
    return {
        setup: l,
        setupView: c,
        state: i
    };
}
function $l(s, e) {
    let t = new _x(s, e), n = [], i = [];
    function r() {
        n.length = 0, i.length = 0;
    }
    function o(u) {
        n.push(u);
    }
    function a(u) {
        i.push(u);
    }
    function l(u) {
        t.setup(n, u);
    }
    function c(u) {
        t.setupView(n, u);
    }
    return {
        init: r,
        state: {
            lightsArray: n,
            shadowsArray: i,
            lights: t
        },
        setupLights: l,
        setupLightsView: c,
        pushLight: o,
        pushShadow: a
    };
}
function Mx(s, e) {
    let t = new WeakMap;
    function n(r, o = 0) {
        let a;
        return t.has(r) === !1 ? (a = new $l(s, e), t.set(r, [
            a
        ])) : o >= t.get(r).length ? (a = new $l(s, e), t.get(r).push(a)) : a = t.get(r)[o], a;
    }
    function i() {
        t = new WeakMap;
    }
    return {
        get: n,
        dispose: i
    };
}
var eo = class extends dt {
    constructor(e){
        super();
        this.type = "MeshDepthMaterial", this.depthPacking = Nd, this.map = null, this.alphaMap = null, this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.wireframe = !1, this.wireframeLinewidth = 1, this.fog = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.depthPacking = e.depthPacking, this.map = e.map, this.alphaMap = e.alphaMap, this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this;
    }
};
eo.prototype.isMeshDepthMaterial = !0;
var to = class extends dt {
    constructor(e){
        super();
        this.type = "MeshDistanceMaterial", this.referencePosition = new M, this.nearDistance = 1, this.farDistance = 1e3, this.map = null, this.alphaMap = null, this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.fog = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.referencePosition.copy(e.referencePosition), this.nearDistance = e.nearDistance, this.farDistance = e.farDistance, this.map = e.map, this.alphaMap = e.alphaMap, this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this;
    }
};
to.prototype.isMeshDistanceMaterial = !0;
var bx = `void main() {
	gl_Position = vec4( position, 1.0 );
}`, wx = `uniform sampler2D shadow_pass;
uniform vec2 resolution;
uniform float radius;
#include <packing>
void main() {
	const float samples = float( VSM_SAMPLES );
	float mean = 0.0;
	float squared_mean = 0.0;
	float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
	float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
	for ( float i = 0.0; i < samples; i ++ ) {
		float uvOffset = uvStart + i * uvStride;
		#ifdef HORIZONTAL_PASS
			vec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );
			mean += distribution.x;
			squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
		#else
			float depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );
			mean += depth;
			squared_mean += depth * depth;
		#endif
	}
	mean = mean / samples;
	squared_mean = squared_mean / samples;
	float std_dev = sqrt( squared_mean - mean * mean );
	gl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );
}`;
function yh(s, e, t) {
    let n = new Dr, i = new X, r = new X, o = new Ve, a = new eo({
        depthPacking: Bd
    }), l = new to, c = {}, h = t.maxTextureSize, u = {
        0: it,
        1: Ai,
        2: Ci
    }, d = new sn({
        defines: {
            VSM_SAMPLES: 8
        },
        uniforms: {
            shadow_pass: {
                value: null
            },
            resolution: {
                value: new X
            },
            radius: {
                value: 4
            }
        },
        vertexShader: bx,
        fragmentShader: wx
    }), f = d.clone();
    f.defines.HORIZONTAL_PASS = 1;
    let m = new _e;
    m.setAttribute("position", new Ue(new Float32Array([
        -1,
        -1,
        .5,
        3,
        -1,
        .5,
        -1,
        3,
        .5
    ]), 3));
    let x = new st(m, d), v = this;
    this.enabled = !1, this.autoUpdate = !0, this.needsUpdate = !1, this.type = Hc, this.render = function(y, b, A) {
        if (v.enabled === !1 || v.autoUpdate === !1 && v.needsUpdate === !1 || y.length === 0) return;
        let L = s.getRenderTarget(), I = s.getActiveCubeFace(), k = s.getActiveMipmapLevel(), B = s.state;
        B.setBlending(vn), B.buffers.color.setClear(1, 1, 1, 1), B.buffers.depth.setTest(!0), B.setScissorTest(!1);
        for(let P = 0, w = y.length; P < w; P++){
            let E = y[P], D = E.shadow;
            if (D === void 0) {
                console.warn("THREE.WebGLShadowMap:", E, "has no shadow.");
                continue;
            }
            if (D.autoUpdate === !1 && D.needsUpdate === !1) continue;
            i.copy(D.mapSize);
            let U = D.getFrameExtents();
            if (i.multiply(U), r.copy(D.mapSize), (i.x > h || i.y > h) && (i.x > h && (r.x = Math.floor(h / U.x), i.x = r.x * U.x, D.mapSize.x = r.x), i.y > h && (r.y = Math.floor(h / U.y), i.y = r.y * U.y, D.mapSize.y = r.y)), D.map === null && !D.isPointLightShadow && this.type === ir) {
                let O = {
                    minFilter: tt,
                    magFilter: tt,
                    format: ct
                };
                D.map = new At(i.x, i.y, O), D.map.texture.name = E.name + ".shadowMap", D.mapPass = new At(i.x, i.y, O), D.camera.updateProjectionMatrix();
            }
            if (D.map === null) {
                let O1 = {
                    minFilter: rt,
                    magFilter: rt,
                    format: ct
                };
                D.map = new At(i.x, i.y, O1), D.map.texture.name = E.name + ".shadowMap", D.camera.updateProjectionMatrix();
            }
            s.setRenderTarget(D.map), s.clear();
            let F = D.getViewportCount();
            for(let O2 = 0; O2 < F; O2++){
                let ne = D.getViewport(O2);
                o.set(r.x * ne.x, r.y * ne.y, r.x * ne.z, r.y * ne.w), B.viewport(o), D.updateMatrices(E, O2), n = D.getFrustum(), _(b, A, D.camera, E, this.type);
            }
            !D.isPointLightShadow && this.type === ir && g(D, A), D.needsUpdate = !1;
        }
        v.needsUpdate = !1, s.setRenderTarget(L, I, k);
    };
    function g(y, b) {
        let A = e.update(x);
        d.defines.VSM_SAMPLES !== y.blurSamples && (d.defines.VSM_SAMPLES = y.blurSamples, f.defines.VSM_SAMPLES = y.blurSamples, d.needsUpdate = !0, f.needsUpdate = !0), d.uniforms.shadow_pass.value = y.map.texture, d.uniforms.resolution.value = y.mapSize, d.uniforms.radius.value = y.radius, s.setRenderTarget(y.mapPass), s.clear(), s.renderBufferDirect(b, null, A, d, x, null), f.uniforms.shadow_pass.value = y.mapPass.texture, f.uniforms.resolution.value = y.mapSize, f.uniforms.radius.value = y.radius, s.setRenderTarget(y.map), s.clear(), s.renderBufferDirect(b, null, A, f, x, null);
    }
    function p(y, b, A, L, I, k, B) {
        let P = null, w = L.isPointLight === !0 ? y.customDistanceMaterial : y.customDepthMaterial;
        if (w !== void 0 ? P = w : P = L.isPointLight === !0 ? l : a, s.localClippingEnabled && A.clipShadows === !0 && A.clippingPlanes.length !== 0 || A.displacementMap && A.displacementScale !== 0 || A.alphaMap && A.alphaTest > 0) {
            let E = P.uuid, D = A.uuid, U = c[E];
            U === void 0 && (U = {}, c[E] = U);
            let F = U[D];
            F === void 0 && (F = P.clone(), U[D] = F), P = F;
        }
        return P.visible = A.visible, P.wireframe = A.wireframe, B === ir ? P.side = A.shadowSide !== null ? A.shadowSide : A.side : P.side = A.shadowSide !== null ? A.shadowSide : u[A.side], P.alphaMap = A.alphaMap, P.alphaTest = A.alphaTest, P.clipShadows = A.clipShadows, P.clippingPlanes = A.clippingPlanes, P.clipIntersection = A.clipIntersection, P.displacementMap = A.displacementMap, P.displacementScale = A.displacementScale, P.displacementBias = A.displacementBias, P.wireframeLinewidth = A.wireframeLinewidth, P.linewidth = A.linewidth, L.isPointLight === !0 && P.isMeshDistanceMaterial === !0 && (P.referencePosition.setFromMatrixPosition(L.matrixWorld), P.nearDistance = I, P.farDistance = k), P;
    }
    function _(y, b, A, L, I) {
        if (y.visible === !1) return;
        if (y.layers.test(b.layers) && (y.isMesh || y.isLine || y.isPoints) && (y.castShadow || y.receiveShadow && I === ir) && (!y.frustumCulled || n.intersectsObject(y))) {
            y.modelViewMatrix.multiplyMatrices(A.matrixWorldInverse, y.matrixWorld);
            let P = e.update(y), w = y.material;
            if (Array.isArray(w)) {
                let E = P.groups;
                for(let D = 0, U = E.length; D < U; D++){
                    let F = E[D], O = w[F.materialIndex];
                    if (O && O.visible) {
                        let ne = p(y, P, O, L, A.near, A.far, I);
                        s.renderBufferDirect(A, null, P, ne, y, F);
                    }
                }
            } else if (w.visible) {
                let E1 = p(y, P, w, L, A.near, A.far, I);
                s.renderBufferDirect(A, null, P, E1, y, null);
            }
        }
        let B = y.children;
        for(let P1 = 0, w1 = B.length; P1 < w1; P1++)_(B[P1], b, A, L, I);
    }
}
function Sx(s, e, t) {
    let n = t.isWebGL2;
    function i() {
        let R = !1, ee = new Ve, Q = null, Ee = new Ve(0, 0, 0, 0);
        return {
            setMask: function(me) {
                Q !== me && !R && (s.colorMask(me, me, me, me), Q = me);
            },
            setLocked: function(me) {
                R = me;
            },
            setClear: function(me, Re, oe, Le, Xe) {
                Xe === !0 && (me *= Le, Re *= Le, oe *= Le), ee.set(me, Re, oe, Le), Ee.equals(ee) === !1 && (s.clearColor(me, Re, oe, Le), Ee.copy(ee));
            },
            reset: function() {
                R = !1, Q = null, Ee.set(-1, 0, 0, 0);
            }
        };
    }
    function r() {
        let R = !1, ee = null, Q = null, Ee = null;
        return {
            setTest: function(me) {
                me ? le(2929) : fe(2929);
            },
            setMask: function(me) {
                ee !== me && !R && (s.depthMask(me), ee = me);
            },
            setFunc: function(me) {
                if (Q !== me) {
                    if (me) switch(me){
                        case Eu:
                            s.depthFunc(512);
                            break;
                        case Au:
                            s.depthFunc(519);
                            break;
                        case Cu:
                            s.depthFunc(513);
                            break;
                        case ea:
                            s.depthFunc(515);
                            break;
                        case Lu:
                            s.depthFunc(514);
                            break;
                        case Ru:
                            s.depthFunc(518);
                            break;
                        case Pu:
                            s.depthFunc(516);
                            break;
                        case Iu:
                            s.depthFunc(517);
                            break;
                        default:
                            s.depthFunc(515);
                    }
                    else s.depthFunc(515);
                    Q = me;
                }
            },
            setLocked: function(me) {
                R = me;
            },
            setClear: function(me) {
                Ee !== me && (s.clearDepth(me), Ee = me);
            },
            reset: function() {
                R = !1, ee = null, Q = null, Ee = null;
            }
        };
    }
    function o() {
        let R = !1, ee = null, Q = null, Ee = null, me = null, Re = null, oe = null, Le = null, Xe = null;
        return {
            setTest: function(We) {
                R || (We ? le(2960) : fe(2960));
            },
            setMask: function(We) {
                ee !== We && !R && (s.stencilMask(We), ee = We);
            },
            setFunc: function(We, Ut, Ot) {
                (Q !== We || Ee !== Ut || me !== Ot) && (s.stencilFunc(We, Ut, Ot), Q = We, Ee = Ut, me = Ot);
            },
            setOp: function(We, Ut, Ot) {
                (Re !== We || oe !== Ut || Le !== Ot) && (s.stencilOp(We, Ut, Ot), Re = We, oe = Ut, Le = Ot);
            },
            setLocked: function(We) {
                R = We;
            },
            setClear: function(We) {
                Xe !== We && (s.clearStencil(We), Xe = We);
            },
            reset: function() {
                R = !1, ee = null, Q = null, Ee = null, me = null, Re = null, oe = null, Le = null, Xe = null;
            }
        };
    }
    let a = new i, l = new r, c = new o, h = {}, u = {}, d = null, f = !1, m = null, x = null, v = null, g = null, p = null, _ = null, y = null, b = !1, A = null, L = null, I = null, k = null, B = null, P = s.getParameter(35661), w = !1, E = 0, D = s.getParameter(7938);
    D.indexOf("WebGL") !== -1 ? (E = parseFloat(/^WebGL (\d)/.exec(D)[1]), w = E >= 1) : D.indexOf("OpenGL ES") !== -1 && (E = parseFloat(/^OpenGL ES (\d)/.exec(D)[1]), w = E >= 2);
    let U = null, F = {}, O = s.getParameter(3088), ne = s.getParameter(2978), ce = new Ve().fromArray(O), V = new Ve().fromArray(ne);
    function W(R, ee, Q) {
        let Ee = new Uint8Array(4), me = s.createTexture();
        s.bindTexture(R, me), s.texParameteri(R, 10241, 9728), s.texParameteri(R, 10240, 9728);
        for(let Re = 0; Re < Q; Re++)s.texImage2D(ee + Re, 0, 6408, 1, 1, 0, 6408, 5121, Ee);
        return me;
    }
    let he = {};
    he[3553] = W(3553, 3553, 1), he[34067] = W(34067, 34069, 6), a.setClear(0, 0, 0, 1), l.setClear(1), c.setClear(0), le(2929), l.setFunc(ea), Oe(!1), G(tl), le(2884), ge(vn);
    function le(R) {
        h[R] !== !0 && (s.enable(R), h[R] = !0);
    }
    function fe(R) {
        h[R] !== !1 && (s.disable(R), h[R] = !1);
    }
    function Be(R, ee) {
        return u[R] !== ee ? (s.bindFramebuffer(R, ee), u[R] = ee, n && (R === 36009 && (u[36160] = ee), R === 36160 && (u[36009] = ee)), !0) : !1;
    }
    function Y(R) {
        return d !== R ? (s.useProgram(R), d = R, !0) : !1;
    }
    let Ce = {
        [_i]: 32774,
        [mu]: 32778,
        [gu]: 32779
    };
    if (n) Ce[sl] = 32775, Ce[ol] = 32776;
    else {
        let R = e.get("EXT_blend_minmax");
        R !== null && (Ce[sl] = R.MIN_EXT, Ce[ol] = R.MAX_EXT);
    }
    let ye = {
        [xu]: 0,
        [yu]: 1,
        [vu]: 768,
        [Gc]: 770,
        [Tu]: 776,
        [wu]: 774,
        [Mu]: 772,
        [_u]: 769,
        [Vc]: 771,
        [Su]: 775,
        [bu]: 773
    };
    function ge(R, ee, Q, Ee, me, Re, oe, Le) {
        if (R === vn) {
            f === !0 && (fe(3042), f = !1);
            return;
        }
        if (f === !1 && (le(3042), f = !0), R !== pu) {
            if (R !== m || Le !== b) {
                if ((x !== _i || p !== _i) && (s.blendEquation(32774), x = _i, p = _i), Le) switch(R){
                    case sr:
                        s.blendFuncSeparate(1, 771, 1, 771);
                        break;
                    case nl:
                        s.blendFunc(1, 1);
                        break;
                    case il:
                        s.blendFuncSeparate(0, 0, 769, 771);
                        break;
                    case rl:
                        s.blendFuncSeparate(0, 768, 0, 770);
                        break;
                    default:
                        console.error("THREE.WebGLState: Invalid blending: ", R);
                        break;
                }
                else switch(R){
                    case sr:
                        s.blendFuncSeparate(770, 771, 1, 771);
                        break;
                    case nl:
                        s.blendFunc(770, 1);
                        break;
                    case il:
                        s.blendFunc(0, 769);
                        break;
                    case rl:
                        s.blendFunc(0, 768);
                        break;
                    default:
                        console.error("THREE.WebGLState: Invalid blending: ", R);
                        break;
                }
                v = null, g = null, _ = null, y = null, m = R, b = Le;
            }
            return;
        }
        me = me || ee, Re = Re || Q, oe = oe || Ee, (ee !== x || me !== p) && (s.blendEquationSeparate(Ce[ee], Ce[me]), x = ee, p = me), (Q !== v || Ee !== g || Re !== _ || oe !== y) && (s.blendFuncSeparate(ye[Q], ye[Ee], ye[Re], ye[oe]), v = Q, g = Ee, _ = Re, y = oe), m = R, b = null;
    }
    function xe(R, ee) {
        R.side === Ci ? fe(2884) : le(2884);
        let Q = R.side === it;
        ee && (Q = !Q), Oe(Q), R.blending === sr && R.transparent === !1 ? ge(vn) : ge(R.blending, R.blendEquation, R.blendSrc, R.blendDst, R.blendEquationAlpha, R.blendSrcAlpha, R.blendDstAlpha, R.premultipliedAlpha), l.setFunc(R.depthFunc), l.setTest(R.depthTest), l.setMask(R.depthWrite), a.setMask(R.colorWrite);
        let Ee = R.stencilWrite;
        c.setTest(Ee), Ee && (c.setMask(R.stencilWriteMask), c.setFunc(R.stencilFunc, R.stencilRef, R.stencilFuncMask), c.setOp(R.stencilFail, R.stencilZFail, R.stencilZPass)), K(R.polygonOffset, R.polygonOffsetFactor, R.polygonOffsetUnits), R.alphaToCoverage === !0 ? le(32926) : fe(32926);
    }
    function Oe(R) {
        A !== R && (R ? s.frontFace(2304) : s.frontFace(2305), A = R);
    }
    function G(R) {
        R !== uu ? (le(2884), R !== L && (R === tl ? s.cullFace(1029) : R === du ? s.cullFace(1028) : s.cullFace(1032))) : fe(2884), L = R;
    }
    function j(R) {
        R !== I && (w && s.lineWidth(R), I = R);
    }
    function K(R, ee, Q) {
        R ? (le(32823), (k !== ee || B !== Q) && (s.polygonOffset(ee, Q), k = ee, B = Q)) : fe(32823);
    }
    function ue(R) {
        R ? le(3089) : fe(3089);
    }
    function se(R) {
        R === void 0 && (R = 33984 + P - 1), U !== R && (s.activeTexture(R), U = R);
    }
    function Se(R, ee) {
        U === null && se();
        let Q = F[U];
        Q === void 0 && (Q = {
            type: void 0,
            texture: void 0
        }, F[U] = Q), (Q.type !== R || Q.texture !== ee) && (s.bindTexture(R, ee || he[R]), Q.type = R, Q.texture = ee);
    }
    function Te() {
        let R = F[U];
        R !== void 0 && R.type !== void 0 && (s.bindTexture(R.type, null), R.type = void 0, R.texture = void 0);
    }
    function Pe() {
        try {
            s.compressedTexImage2D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function Ye() {
        try {
            s.texSubImage2D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function C() {
        try {
            s.texSubImage3D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function T() {
        try {
            s.compressedTexSubImage2D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function J() {
        try {
            s.texStorage2D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function $() {
        try {
            s.texStorage3D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function re() {
        try {
            s.texImage2D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function Z() {
        try {
            s.texImage3D.apply(s, arguments);
        } catch (R) {
            console.error("THREE.WebGLState:", R);
        }
    }
    function Me(R) {
        ce.equals(R) === !1 && (s.scissor(R.x, R.y, R.z, R.w), ce.copy(R));
    }
    function ve(R) {
        V.equals(R) === !1 && (s.viewport(R.x, R.y, R.z, R.w), V.copy(R));
    }
    function te() {
        s.disable(3042), s.disable(2884), s.disable(2929), s.disable(32823), s.disable(3089), s.disable(2960), s.disable(32926), s.blendEquation(32774), s.blendFunc(1, 0), s.blendFuncSeparate(1, 0, 1, 0), s.colorMask(!0, !0, !0, !0), s.clearColor(0, 0, 0, 0), s.depthMask(!0), s.depthFunc(513), s.clearDepth(1), s.stencilMask(4294967295), s.stencilFunc(519, 0, 4294967295), s.stencilOp(7680, 7680, 7680), s.clearStencil(0), s.cullFace(1029), s.frontFace(2305), s.polygonOffset(0, 0), s.activeTexture(33984), s.bindFramebuffer(36160, null), n === !0 && (s.bindFramebuffer(36009, null), s.bindFramebuffer(36008, null)), s.useProgram(null), s.lineWidth(1), s.scissor(0, 0, s.canvas.width, s.canvas.height), s.viewport(0, 0, s.canvas.width, s.canvas.height), h = {}, U = null, F = {}, u = {}, d = null, f = !1, m = null, x = null, v = null, g = null, p = null, _ = null, y = null, b = !1, A = null, L = null, I = null, k = null, B = null, ce.set(0, 0, s.canvas.width, s.canvas.height), V.set(0, 0, s.canvas.width, s.canvas.height), a.reset(), l.reset(), c.reset();
    }
    return {
        buffers: {
            color: a,
            depth: l,
            stencil: c
        },
        enable: le,
        disable: fe,
        bindFramebuffer: Be,
        useProgram: Y,
        setBlending: ge,
        setMaterial: xe,
        setFlipSided: Oe,
        setCullFace: G,
        setLineWidth: j,
        setPolygonOffset: K,
        setScissorTest: ue,
        activeTexture: se,
        bindTexture: Se,
        unbindTexture: Te,
        compressedTexImage2D: Pe,
        texImage2D: re,
        texImage3D: Z,
        texStorage2D: J,
        texStorage3D: $,
        texSubImage2D: Ye,
        texSubImage3D: C,
        compressedTexSubImage2D: T,
        scissor: Me,
        viewport: ve,
        reset: te
    };
}
function Tx(s, e, t, n, i, r, o) {
    let a = i.isWebGL2, l = i.maxTextures, c = i.maxCubemapSize, h = i.maxTextureSize, u = i.maxSamples, f = e.has("WEBGL_multisampled_render_to_texture") ? e.get("WEBGL_multisampled_render_to_texture") : void 0, m = new WeakMap, x, v = !1;
    try {
        v = typeof OffscreenCanvas < "u" && new OffscreenCanvas(1, 1).getContext("2d") !== null;
    } catch  {}
    function g(C, T) {
        return v ? new OffscreenCanvas(C, T) : qs("canvas");
    }
    function p(C, T, J, $) {
        let re = 1;
        if ((C.width > $ || C.height > $) && (re = $ / Math.max(C.width, C.height)), re < 1 || T === !0) if (typeof HTMLImageElement < "u" && C instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && C instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && C instanceof ImageBitmap) {
            let Z = T ? Jc : Math.floor, Me = Z(re * C.width), ve = Z(re * C.height);
            x === void 0 && (x = g(Me, ve));
            let te = J ? g(Me, ve) : x;
            return te.width = Me, te.height = ve, te.getContext("2d").drawImage(C, 0, 0, Me, ve), console.warn("THREE.WebGLRenderer: Texture has been resized from (" + C.width + "x" + C.height + ") to (" + Me + "x" + ve + ")."), te;
        } else return "data" in C && console.warn("THREE.WebGLRenderer: Image in DataTexture is too big (" + C.width + "x" + C.height + ")."), C;
        return C;
    }
    function _(C) {
        return ia(C.width) && ia(C.height);
    }
    function y(C) {
        return a ? !1 : C.wrapS !== vt || C.wrapT !== vt || C.minFilter !== rt && C.minFilter !== tt;
    }
    function b(C, T) {
        return C.generateMipmaps && T && C.minFilter !== rt && C.minFilter !== tt;
    }
    function A(C) {
        s.generateMipmap(C);
    }
    function L(C, T, J, $) {
        if (a === !1) return T;
        if (C !== null) {
            if (s[C] !== void 0) return s[C];
            console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '" + C + "'");
        }
        let re = T;
        return T === 6403 && (J === 5126 && (re = 33326), J === 5131 && (re = 33325), J === 5121 && (re = 33321)), T === 6407 && (J === 5126 && (re = 34837), J === 5131 && (re = 34843), J === 5121 && (re = 32849)), T === 6408 && (J === 5126 && (re = 34836), J === 5131 && (re = 34842), J === 5121 && (re = $ === Oi ? 35907 : 32856)), (re === 33325 || re === 33326 || re === 34842 || re === 34836) && e.get("EXT_color_buffer_float"), re;
    }
    function I(C, T, J) {
        return b(C, J) === !0 || C.isFramebufferTexture && C.minFilter !== rt && C.minFilter !== tt ? Math.log2(Math.max(T.width, T.height)) + 1 : C.mipmaps !== void 0 && C.mipmaps.length > 0 ? C.mipmaps.length : C.isCompressedTexture && Array.isArray(C.image) ? T.mipmaps.length : 1;
    }
    function k(C) {
        return C === rt || C === ta || C === na ? 9728 : 9729;
    }
    function B(C) {
        let T = C.target;
        T.removeEventListener("dispose", B), w(T), T.isVideoTexture && m.delete(T), o.memory.textures--;
    }
    function P(C) {
        let T = C.target;
        T.removeEventListener("dispose", P), E(T);
    }
    function w(C) {
        let T = n.get(C);
        T.__webglInit !== void 0 && (s.deleteTexture(T.__webglTexture), n.remove(C));
    }
    function E(C) {
        let T = C.texture, J = n.get(C), $ = n.get(T);
        if (!!C) {
            if ($.__webglTexture !== void 0 && (s.deleteTexture($.__webglTexture), o.memory.textures--), C.depthTexture && C.depthTexture.dispose(), C.isWebGLCubeRenderTarget) for(let re = 0; re < 6; re++)s.deleteFramebuffer(J.__webglFramebuffer[re]), J.__webglDepthbuffer && s.deleteRenderbuffer(J.__webglDepthbuffer[re]);
            else s.deleteFramebuffer(J.__webglFramebuffer), J.__webglDepthbuffer && s.deleteRenderbuffer(J.__webglDepthbuffer), J.__webglMultisampledFramebuffer && s.deleteFramebuffer(J.__webglMultisampledFramebuffer), J.__webglColorRenderbuffer && s.deleteRenderbuffer(J.__webglColorRenderbuffer), J.__webglDepthRenderbuffer && s.deleteRenderbuffer(J.__webglDepthRenderbuffer);
            if (C.isWebGLMultipleRenderTargets) for(let re1 = 0, Z = T.length; re1 < Z; re1++){
                let Me = n.get(T[re1]);
                Me.__webglTexture && (s.deleteTexture(Me.__webglTexture), o.memory.textures--), n.remove(T[re1]);
            }
            n.remove(T), n.remove(C);
        }
    }
    let D = 0;
    function U() {
        D = 0;
    }
    function F() {
        let C = D;
        return C >= l && console.warn("THREE.WebGLTextures: Trying to use " + C + " texture units while this GPU supports only " + l), D += 1, C;
    }
    function O(C, T) {
        let J = n.get(C);
        if (C.isVideoTexture && se(C), C.version > 0 && J.__version !== C.version) {
            let $ = C.image;
            if ($ === void 0) console.warn("THREE.WebGLRenderer: Texture marked for update but image is undefined");
            else if ($.complete === !1) console.warn("THREE.WebGLRenderer: Texture marked for update but image is incomplete");
            else {
                Be(J, C, T);
                return;
            }
        }
        t.activeTexture(33984 + T), t.bindTexture(3553, J.__webglTexture);
    }
    function ne(C, T) {
        let J = n.get(C);
        if (C.version > 0 && J.__version !== C.version) {
            Be(J, C, T);
            return;
        }
        t.activeTexture(33984 + T), t.bindTexture(35866, J.__webglTexture);
    }
    function ce(C, T) {
        let J = n.get(C);
        if (C.version > 0 && J.__version !== C.version) {
            Be(J, C, T);
            return;
        }
        t.activeTexture(33984 + T), t.bindTexture(32879, J.__webglTexture);
    }
    function V(C, T) {
        let J = n.get(C);
        if (C.version > 0 && J.__version !== C.version) {
            Y(J, C, T);
            return;
        }
        t.activeTexture(33984 + T), t.bindTexture(34067, J.__webglTexture);
    }
    let W = {
        [Ns]: 10497,
        [vt]: 33071,
        [Bs]: 33648
    }, he = {
        [rt]: 9728,
        [ta]: 9984,
        [na]: 9986,
        [tt]: 9729,
        [Wc]: 9985,
        [Ui]: 9987
    };
    function le(C, T, J) {
        if (J ? (s.texParameteri(C, 10242, W[T.wrapS]), s.texParameteri(C, 10243, W[T.wrapT]), (C === 32879 || C === 35866) && s.texParameteri(C, 32882, W[T.wrapR]), s.texParameteri(C, 10240, he[T.magFilter]), s.texParameteri(C, 10241, he[T.minFilter])) : (s.texParameteri(C, 10242, 33071), s.texParameteri(C, 10243, 33071), (C === 32879 || C === 35866) && s.texParameteri(C, 32882, 33071), (T.wrapS !== vt || T.wrapT !== vt) && console.warn("THREE.WebGLRenderer: Texture is not power of two. Texture.wrapS and Texture.wrapT should be set to THREE.ClampToEdgeWrapping."), s.texParameteri(C, 10240, k(T.magFilter)), s.texParameteri(C, 10241, k(T.minFilter)), T.minFilter !== rt && T.minFilter !== tt && console.warn("THREE.WebGLRenderer: Texture is not power of two. Texture.minFilter should be set to THREE.NearestFilter or THREE.LinearFilter.")), e.has("EXT_texture_filter_anisotropic") === !0) {
            let $ = e.get("EXT_texture_filter_anisotropic");
            if (T.type === nn && e.has("OES_texture_float_linear") === !1 || a === !1 && T.type === kn && e.has("OES_texture_half_float_linear") === !1) return;
            (T.anisotropy > 1 || n.get(T).__currentAnisotropy) && (s.texParameterf(C, $.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(T.anisotropy, i.getMaxAnisotropy())), n.get(T).__currentAnisotropy = T.anisotropy);
        }
    }
    function fe(C, T) {
        C.__webglInit === void 0 && (C.__webglInit = !0, T.addEventListener("dispose", B), C.__webglTexture = s.createTexture(), o.memory.textures++);
    }
    function Be(C, T, J) {
        let $ = 3553;
        T.isDataTexture2DArray && ($ = 35866), T.isDataTexture3D && ($ = 32879), fe(C, T), t.activeTexture(33984 + J), t.bindTexture($, C.__webglTexture), s.pixelStorei(37440, T.flipY), s.pixelStorei(37441, T.premultiplyAlpha), s.pixelStorei(3317, T.unpackAlignment), s.pixelStorei(37443, 0);
        let re = y(T) && _(T.image) === !1, Z = p(T.image, re, !1, h), Me = _(Z) || a, ve = r.convert(T.format), te = r.convert(T.type), R = L(T.internalFormat, ve, te, T.encoding);
        le($, T, Me);
        let ee, Q = T.mipmaps, Ee = a && T.isVideoTexture !== !0, me = C.__version === void 0, Re = I(T, Z, Me);
        if (T.isDepthTexture) R = 6402, a ? T.type === nn ? R = 36012 : T.type === Ps ? R = 33190 : T.type === Ti ? R = 35056 : R = 33189 : T.type === nn && console.error("WebGLRenderer: Floating point depth texture requires WebGL2."), T.format === Vn && R === 6402 && T.type !== cr && T.type !== Ps && (console.warn("THREE.WebGLRenderer: Use UnsignedShortType or UnsignedIntType for DepthFormat DepthTexture."), T.type = cr, te = r.convert(T.type)), T.format === Li && R === 6402 && (R = 34041, T.type !== Ti && (console.warn("THREE.WebGLRenderer: Use UnsignedInt248Type for DepthStencilFormat DepthTexture."), T.type = Ti, te = r.convert(T.type))), Ee && me ? t.texStorage2D(3553, 1, R, Z.width, Z.height) : t.texImage2D(3553, 0, R, Z.width, Z.height, 0, ve, te, null);
        else if (T.isDataTexture) if (Q.length > 0 && Me) {
            Ee && me && t.texStorage2D(3553, Re, R, Q[0].width, Q[0].height);
            for(let oe = 0, Le = Q.length; oe < Le; oe++)ee = Q[oe], Ee ? t.texSubImage2D(3553, 0, 0, 0, ee.width, ee.height, ve, te, ee.data) : t.texImage2D(3553, oe, R, ee.width, ee.height, 0, ve, te, ee.data);
            T.generateMipmaps = !1;
        } else Ee ? (me && t.texStorage2D(3553, Re, R, Z.width, Z.height), t.texSubImage2D(3553, 0, 0, 0, Z.width, Z.height, ve, te, Z.data)) : t.texImage2D(3553, 0, R, Z.width, Z.height, 0, ve, te, Z.data);
        else if (T.isCompressedTexture) {
            Ee && me && t.texStorage2D(3553, Re, R, Q[0].width, Q[0].height);
            for(let oe1 = 0, Le1 = Q.length; oe1 < Le1; oe1++)ee = Q[oe1], T.format !== ct && T.format !== Gn ? ve !== null ? Ee ? t.compressedTexSubImage2D(3553, oe1, 0, 0, ee.width, ee.height, ve, ee.data) : t.compressedTexImage2D(3553, oe1, R, ee.width, ee.height, 0, ee.data) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()") : Ee ? t.texSubImage2D(3553, oe1, 0, 0, ee.width, ee.height, ve, te, ee.data) : t.texImage2D(3553, oe1, R, ee.width, ee.height, 0, ve, te, ee.data);
        } else if (T.isDataTexture2DArray) Ee ? (me && t.texStorage3D(35866, Re, R, Z.width, Z.height, Z.depth), t.texSubImage3D(35866, 0, 0, 0, 0, Z.width, Z.height, Z.depth, ve, te, Z.data)) : t.texImage3D(35866, 0, R, Z.width, Z.height, Z.depth, 0, ve, te, Z.data);
        else if (T.isDataTexture3D) Ee ? (me && t.texStorage3D(32879, Re, R, Z.width, Z.height, Z.depth), t.texSubImage3D(32879, 0, 0, 0, 0, Z.width, Z.height, Z.depth, ve, te, Z.data)) : t.texImage3D(32879, 0, R, Z.width, Z.height, Z.depth, 0, ve, te, Z.data);
        else if (T.isFramebufferTexture) Ee && me ? t.texStorage2D(3553, Re, R, Z.width, Z.height) : t.texImage2D(3553, 0, R, Z.width, Z.height, 0, ve, te, null);
        else if (Q.length > 0 && Me) {
            Ee && me && t.texStorage2D(3553, Re, R, Q[0].width, Q[0].height);
            for(let oe2 = 0, Le2 = Q.length; oe2 < Le2; oe2++)ee = Q[oe2], Ee ? t.texSubImage2D(3553, oe2, 0, 0, ve, te, ee) : t.texImage2D(3553, oe2, R, ve, te, ee);
            T.generateMipmaps = !1;
        } else Ee ? (me && t.texStorage2D(3553, Re, R, Z.width, Z.height), t.texSubImage2D(3553, 0, 0, 0, ve, te, Z)) : t.texImage2D(3553, 0, R, ve, te, Z);
        b(T, Me) && A($), C.__version = T.version, T.onUpdate && T.onUpdate(T);
    }
    function Y(C, T, J) {
        if (T.image.length !== 6) return;
        fe(C, T), t.activeTexture(33984 + J), t.bindTexture(34067, C.__webglTexture), s.pixelStorei(37440, T.flipY), s.pixelStorei(37441, T.premultiplyAlpha), s.pixelStorei(3317, T.unpackAlignment), s.pixelStorei(37443, 0);
        let $ = T && (T.isCompressedTexture || T.image[0].isCompressedTexture), re = T.image[0] && T.image[0].isDataTexture, Z = [];
        for(let oe = 0; oe < 6; oe++)!$ && !re ? Z[oe] = p(T.image[oe], !1, !0, c) : Z[oe] = re ? T.image[oe].image : T.image[oe];
        let Me = Z[0], ve = _(Me) || a, te = r.convert(T.format), R = r.convert(T.type), ee = L(T.internalFormat, te, R, T.encoding), Q = a && T.isVideoTexture !== !0, Ee = C.__version === void 0, me = I(T, Me, ve);
        le(34067, T, ve);
        let Re;
        if ($) {
            Q && Ee && t.texStorage2D(34067, me, ee, Me.width, Me.height);
            for(let oe1 = 0; oe1 < 6; oe1++){
                Re = Z[oe1].mipmaps;
                for(let Le = 0; Le < Re.length; Le++){
                    let Xe = Re[Le];
                    T.format !== ct && T.format !== Gn ? te !== null ? Q ? t.compressedTexSubImage2D(34069 + oe1, Le, 0, 0, Xe.width, Xe.height, te, Xe.data) : t.compressedTexImage2D(34069 + oe1, Le, ee, Xe.width, Xe.height, 0, Xe.data) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()") : Q ? t.texSubImage2D(34069 + oe1, Le, 0, 0, Xe.width, Xe.height, te, R, Xe.data) : t.texImage2D(34069 + oe1, Le, ee, Xe.width, Xe.height, 0, te, R, Xe.data);
                }
            }
        } else {
            Re = T.mipmaps, Q && Ee && (Re.length > 0 && me++, t.texStorage2D(34067, me, ee, Z[0].width, Z[0].height));
            for(let oe2 = 0; oe2 < 6; oe2++)if (re) {
                Q ? t.texSubImage2D(34069 + oe2, 0, 0, 0, Z[oe2].width, Z[oe2].height, te, R, Z[oe2].data) : t.texImage2D(34069 + oe2, 0, ee, Z[oe2].width, Z[oe2].height, 0, te, R, Z[oe2].data);
                for(let Le1 = 0; Le1 < Re.length; Le1++){
                    let We = Re[Le1].image[oe2].image;
                    Q ? t.texSubImage2D(34069 + oe2, Le1 + 1, 0, 0, We.width, We.height, te, R, We.data) : t.texImage2D(34069 + oe2, Le1 + 1, ee, We.width, We.height, 0, te, R, We.data);
                }
            } else {
                Q ? t.texSubImage2D(34069 + oe2, 0, 0, 0, te, R, Z[oe2]) : t.texImage2D(34069 + oe2, 0, ee, te, R, Z[oe2]);
                for(let Le2 = 0; Le2 < Re.length; Le2++){
                    let Xe1 = Re[Le2];
                    Q ? t.texSubImage2D(34069 + oe2, Le2 + 1, 0, 0, te, R, Xe1.image[oe2]) : t.texImage2D(34069 + oe2, Le2 + 1, ee, te, R, Xe1.image[oe2]);
                }
            }
        }
        b(T, ve) && A(34067), C.__version = T.version, T.onUpdate && T.onUpdate(T);
    }
    function Ce(C, T, J, $, re) {
        let Z = r.convert(J.format), Me = r.convert(J.type), ve = L(J.internalFormat, Z, Me, J.encoding);
        n.get(T).__hasExternalTextures || (re === 32879 || re === 35866 ? t.texImage3D(re, 0, ve, T.width, T.height, T.depth, 0, Z, Me, null) : t.texImage2D(re, 0, ve, T.width, T.height, 0, Z, Me, null)), t.bindFramebuffer(36160, C), T.useRenderToTexture ? f.framebufferTexture2DMultisampleEXT(36160, $, re, n.get(J).__webglTexture, 0, ue(T)) : s.framebufferTexture2D(36160, $, re, n.get(J).__webglTexture, 0), t.bindFramebuffer(36160, null);
    }
    function ye(C, T, J) {
        if (s.bindRenderbuffer(36161, C), T.depthBuffer && !T.stencilBuffer) {
            let $ = 33189;
            if (J || T.useRenderToTexture) {
                let re = T.depthTexture;
                re && re.isDepthTexture && (re.type === nn ? $ = 36012 : re.type === Ps && ($ = 33190));
                let Z = ue(T);
                T.useRenderToTexture ? f.renderbufferStorageMultisampleEXT(36161, Z, $, T.width, T.height) : s.renderbufferStorageMultisample(36161, Z, $, T.width, T.height);
            } else s.renderbufferStorage(36161, $, T.width, T.height);
            s.framebufferRenderbuffer(36160, 36096, 36161, C);
        } else if (T.depthBuffer && T.stencilBuffer) {
            let $1 = ue(T);
            J && T.useRenderbuffer ? s.renderbufferStorageMultisample(36161, $1, 35056, T.width, T.height) : T.useRenderToTexture ? f.renderbufferStorageMultisampleEXT(36161, $1, 35056, T.width, T.height) : s.renderbufferStorage(36161, 34041, T.width, T.height), s.framebufferRenderbuffer(36160, 33306, 36161, C);
        } else {
            let $2 = T.isWebGLMultipleRenderTargets === !0 ? T.texture[0] : T.texture, re1 = r.convert($2.format), Z1 = r.convert($2.type), Me = L($2.internalFormat, re1, Z1, $2.encoding), ve = ue(T);
            J && T.useRenderbuffer ? s.renderbufferStorageMultisample(36161, ve, Me, T.width, T.height) : T.useRenderToTexture ? f.renderbufferStorageMultisampleEXT(36161, ve, Me, T.width, T.height) : s.renderbufferStorage(36161, Me, T.width, T.height);
        }
        s.bindRenderbuffer(36161, null);
    }
    function ge(C, T) {
        if (T && T.isWebGLCubeRenderTarget) throw new Error("Depth Texture with cube render targets is not supported");
        if (t.bindFramebuffer(36160, C), !(T.depthTexture && T.depthTexture.isDepthTexture)) throw new Error("renderTarget.depthTexture must be an instance of THREE.DepthTexture");
        (!n.get(T.depthTexture).__webglTexture || T.depthTexture.image.width !== T.width || T.depthTexture.image.height !== T.height) && (T.depthTexture.image.width = T.width, T.depthTexture.image.height = T.height, T.depthTexture.needsUpdate = !0), O(T.depthTexture, 0);
        let $ = n.get(T.depthTexture).__webglTexture, re = ue(T);
        if (T.depthTexture.format === Vn) T.useRenderToTexture ? f.framebufferTexture2DMultisampleEXT(36160, 36096, 3553, $, 0, re) : s.framebufferTexture2D(36160, 36096, 3553, $, 0);
        else if (T.depthTexture.format === Li) T.useRenderToTexture ? f.framebufferTexture2DMultisampleEXT(36160, 33306, 3553, $, 0, re) : s.framebufferTexture2D(36160, 33306, 3553, $, 0);
        else throw new Error("Unknown depthTexture format");
    }
    function xe(C) {
        let T = n.get(C), J = C.isWebGLCubeRenderTarget === !0;
        if (C.depthTexture && !T.__autoAllocateDepthBuffer) {
            if (J) throw new Error("target.depthTexture not supported in Cube render targets");
            ge(T.__webglFramebuffer, C);
        } else if (J) {
            T.__webglDepthbuffer = [];
            for(let $ = 0; $ < 6; $++)t.bindFramebuffer(36160, T.__webglFramebuffer[$]), T.__webglDepthbuffer[$] = s.createRenderbuffer(), ye(T.__webglDepthbuffer[$], C, !1);
        } else t.bindFramebuffer(36160, T.__webglFramebuffer), T.__webglDepthbuffer = s.createRenderbuffer(), ye(T.__webglDepthbuffer, C, !1);
        t.bindFramebuffer(36160, null);
    }
    function Oe(C, T, J) {
        let $ = n.get(C);
        T !== void 0 && Ce($.__webglFramebuffer, C, C.texture, 36064, 3553), J !== void 0 && xe(C);
    }
    function G(C) {
        let T = C.texture, J = n.get(C), $ = n.get(T);
        C.addEventListener("dispose", P), C.isWebGLMultipleRenderTargets !== !0 && ($.__webglTexture === void 0 && ($.__webglTexture = s.createTexture()), $.__version = T.version, o.memory.textures++);
        let re = C.isWebGLCubeRenderTarget === !0, Z = C.isWebGLMultipleRenderTargets === !0, Me = T.isDataTexture3D || T.isDataTexture2DArray, ve = _(C) || a;
        if (a && T.format === Gn && (T.type === nn || T.type === kn) && (T.format = ct, console.warn("THREE.WebGLRenderer: Rendering to textures with RGB format is not supported. Using RGBA format instead.")), re) {
            J.__webglFramebuffer = [];
            for(let te = 0; te < 6; te++)J.__webglFramebuffer[te] = s.createFramebuffer();
        } else if (J.__webglFramebuffer = s.createFramebuffer(), Z) if (i.drawBuffers) {
            let te1 = C.texture;
            for(let R = 0, ee = te1.length; R < ee; R++){
                let Q = n.get(te1[R]);
                Q.__webglTexture === void 0 && (Q.__webglTexture = s.createTexture(), o.memory.textures++);
            }
        } else console.warn("THREE.WebGLRenderer: WebGLMultipleRenderTargets can only be used with WebGL2 or WEBGL_draw_buffers extension.");
        else if (C.useRenderbuffer) if (a) {
            J.__webglMultisampledFramebuffer = s.createFramebuffer(), J.__webglColorRenderbuffer = s.createRenderbuffer(), s.bindRenderbuffer(36161, J.__webglColorRenderbuffer);
            let te2 = r.convert(T.format), R1 = r.convert(T.type), ee1 = L(T.internalFormat, te2, R1, T.encoding), Q1 = ue(C);
            s.renderbufferStorageMultisample(36161, Q1, ee1, C.width, C.height), t.bindFramebuffer(36160, J.__webglMultisampledFramebuffer), s.framebufferRenderbuffer(36160, 36064, 36161, J.__webglColorRenderbuffer), s.bindRenderbuffer(36161, null), C.depthBuffer && (J.__webglDepthRenderbuffer = s.createRenderbuffer(), ye(J.__webglDepthRenderbuffer, C, !0)), t.bindFramebuffer(36160, null);
        } else console.warn("THREE.WebGLRenderer: WebGLMultisampleRenderTarget can only be used with WebGL2.");
        if (re) {
            t.bindTexture(34067, $.__webglTexture), le(34067, T, ve);
            for(let te3 = 0; te3 < 6; te3++)Ce(J.__webglFramebuffer[te3], C, T, 36064, 34069 + te3);
            b(T, ve) && A(34067), t.unbindTexture();
        } else if (Z) {
            let te4 = C.texture;
            for(let R2 = 0, ee2 = te4.length; R2 < ee2; R2++){
                let Q2 = te4[R2], Ee = n.get(Q2);
                t.bindTexture(3553, Ee.__webglTexture), le(3553, Q2, ve), Ce(J.__webglFramebuffer, C, Q2, 36064 + R2, 3553), b(Q2, ve) && A(3553);
            }
            t.unbindTexture();
        } else {
            let te5 = 3553;
            Me && (a ? te5 = T.isDataTexture3D ? 32879 : 35866 : console.warn("THREE.DataTexture3D and THREE.DataTexture2DArray only supported with WebGL2.")), t.bindTexture(te5, $.__webglTexture), le(te5, T, ve), Ce(J.__webglFramebuffer, C, T, 36064, te5), b(T, ve) && A(te5), t.unbindTexture();
        }
        C.depthBuffer && xe(C);
    }
    function j(C) {
        let T = _(C) || a, J = C.isWebGLMultipleRenderTargets === !0 ? C.texture : [
            C.texture
        ];
        for(let $ = 0, re = J.length; $ < re; $++){
            let Z = J[$];
            if (b(Z, T)) {
                let Me = C.isWebGLCubeRenderTarget ? 34067 : 3553, ve = n.get(Z).__webglTexture;
                t.bindTexture(Me, ve), A(Me), t.unbindTexture();
            }
        }
    }
    function K(C) {
        if (C.useRenderbuffer) if (a) {
            let T = C.width, J = C.height, $ = 16384, re = [
                36064
            ], Z = C.stencilBuffer ? 33306 : 36096;
            C.depthBuffer && re.push(Z), C.ignoreDepthForMultisampleCopy || (C.depthBuffer && ($ |= 256), C.stencilBuffer && ($ |= 1024));
            let Me = n.get(C);
            t.bindFramebuffer(36008, Me.__webglMultisampledFramebuffer), t.bindFramebuffer(36009, Me.__webglFramebuffer), C.ignoreDepthForMultisampleCopy && (s.invalidateFramebuffer(36008, [
                Z
            ]), s.invalidateFramebuffer(36009, [
                Z
            ])), s.blitFramebuffer(0, 0, T, J, 0, 0, T, J, $, 9728), s.invalidateFramebuffer(36008, re), t.bindFramebuffer(36008, null), t.bindFramebuffer(36009, Me.__webglMultisampledFramebuffer);
        } else console.warn("THREE.WebGLRenderer: WebGLMultisampleRenderTarget can only be used with WebGL2.");
    }
    function ue(C) {
        return a && (C.useRenderbuffer || C.useRenderToTexture) ? Math.min(u, C.samples) : 0;
    }
    function se(C) {
        let T = o.render.frame;
        m.get(C) !== T && (m.set(C, T), C.update());
    }
    let Se = !1, Te = !1;
    function Pe(C, T) {
        C && C.isWebGLRenderTarget && (Se === !1 && (console.warn("THREE.WebGLTextures.safeSetTexture2D: don't use render targets as textures. Use their .texture property instead."), Se = !0), C = C.texture), O(C, T);
    }
    function Ye(C, T) {
        C && C.isWebGLCubeRenderTarget && (Te === !1 && (console.warn("THREE.WebGLTextures.safeSetTextureCube: don't use cube render targets as textures. Use their .texture property instead."), Te = !0), C = C.texture), V(C, T);
    }
    this.allocateTextureUnit = F, this.resetTextureUnits = U, this.setTexture2D = O, this.setTexture2DArray = ne, this.setTexture3D = ce, this.setTextureCube = V, this.rebindTextures = Oe, this.setupRenderTarget = G, this.updateRenderTargetMipmap = j, this.updateMultisampleRenderTarget = K, this.setupDepthRenderbuffer = xe, this.setupFrameBufferTexture = Ce, this.safeSetTexture2D = Pe, this.safeSetTextureCube = Ye;
}
function Ex(s, e, t) {
    let n = t.isWebGL2;
    function i(r) {
        let o;
        if (r === rn) return 5121;
        if (r === Vu) return 32819;
        if (r === Wu) return 32820;
        if (r === qu) return 33635;
        if (r === Hu) return 5120;
        if (r === ku) return 5122;
        if (r === cr) return 5123;
        if (r === Gu) return 5124;
        if (r === Ps) return 5125;
        if (r === nn) return 5126;
        if (r === kn) return n ? 5131 : (o = e.get("OES_texture_half_float"), o !== null ? o.HALF_FLOAT_OES : null);
        if (r === Xu) return 6406;
        if (r === Gn) return 6407;
        if (r === ct) return 6408;
        if (r === Ju) return 6409;
        if (r === Yu) return 6410;
        if (r === Vn) return 6402;
        if (r === Li) return 34041;
        if (r === Zu) return 6403;
        if (r === $u) return 36244;
        if (r === ju) return 33319;
        if (r === Qu) return 33320;
        if (r === Ku) return 36248;
        if (r === ed) return 36249;
        if (r === al || r === ll || r === cl || r === hl) if (o = e.get("WEBGL_compressed_texture_s3tc"), o !== null) {
            if (r === al) return o.COMPRESSED_RGB_S3TC_DXT1_EXT;
            if (r === ll) return o.COMPRESSED_RGBA_S3TC_DXT1_EXT;
            if (r === cl) return o.COMPRESSED_RGBA_S3TC_DXT3_EXT;
            if (r === hl) return o.COMPRESSED_RGBA_S3TC_DXT5_EXT;
        } else return null;
        if (r === ul || r === dl || r === fl || r === pl) if (o = e.get("WEBGL_compressed_texture_pvrtc"), o !== null) {
            if (r === ul) return o.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            if (r === dl) return o.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            if (r === fl) return o.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            if (r === pl) return o.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
        } else return null;
        if (r === td) return o = e.get("WEBGL_compressed_texture_etc1"), o !== null ? o.COMPRESSED_RGB_ETC1_WEBGL : null;
        if ((r === ml || r === gl) && (o = e.get("WEBGL_compressed_texture_etc"), o !== null)) {
            if (r === ml) return o.COMPRESSED_RGB8_ETC2;
            if (r === gl) return o.COMPRESSED_RGBA8_ETC2_EAC;
        }
        if (r === nd || r === id || r === rd || r === sd || r === od || r === ad || r === ld || r === cd || r === hd || r === ud || r === dd || r === fd || r === pd || r === md || r === xd || r === yd || r === vd || r === _d || r === Md || r === bd || r === wd || r === Sd || r === Td || r === Ed || r === Ad || r === Cd || r === Ld || r === Rd) return o = e.get("WEBGL_compressed_texture_astc"), o !== null ? r : null;
        if (r === gd) return o = e.get("EXT_texture_compression_bptc"), o !== null ? r : null;
        if (r === Ti) return n ? 34042 : (o = e.get("WEBGL_depth_texture"), o !== null ? o.UNSIGNED_INT_24_8_WEBGL : null);
    }
    return {
        convert: i
    };
}
var ga = class extends ut {
    constructor(e = []){
        super();
        this.cameras = e;
    }
};
ga.prototype.isArrayCamera = !0;
var Hn = class extends Ne {
    constructor(){
        super();
        this.type = "Group";
    }
};
Hn.prototype.isGroup = !0;
var Ax = {
    type: "move"
}, Is = class {
    constructor(){
        this._targetRay = null, this._grip = null, this._hand = null;
    }
    getHandSpace() {
        return this._hand === null && (this._hand = new Hn, this._hand.matrixAutoUpdate = !1, this._hand.visible = !1, this._hand.joints = {}, this._hand.inputState = {
            pinching: !1
        }), this._hand;
    }
    getTargetRaySpace() {
        return this._targetRay === null && (this._targetRay = new Hn, this._targetRay.matrixAutoUpdate = !1, this._targetRay.visible = !1, this._targetRay.hasLinearVelocity = !1, this._targetRay.linearVelocity = new M, this._targetRay.hasAngularVelocity = !1, this._targetRay.angularVelocity = new M), this._targetRay;
    }
    getGripSpace() {
        return this._grip === null && (this._grip = new Hn, this._grip.matrixAutoUpdate = !1, this._grip.visible = !1, this._grip.hasLinearVelocity = !1, this._grip.linearVelocity = new M, this._grip.hasAngularVelocity = !1, this._grip.angularVelocity = new M), this._grip;
    }
    dispatchEvent(e) {
        return this._targetRay !== null && this._targetRay.dispatchEvent(e), this._grip !== null && this._grip.dispatchEvent(e), this._hand !== null && this._hand.dispatchEvent(e), this;
    }
    disconnect(e) {
        return this.dispatchEvent({
            type: "disconnected",
            data: e
        }), this._targetRay !== null && (this._targetRay.visible = !1), this._grip !== null && (this._grip.visible = !1), this._hand !== null && (this._hand.visible = !1), this;
    }
    update(e, t, n) {
        let i = null, r = null, o = null, a = this._targetRay, l = this._grip, c = this._hand;
        if (e && t.session.visibilityState !== "visible-blurred") if (a !== null && (i = t.getPose(e.targetRaySpace, n), i !== null && (a.matrix.fromArray(i.transform.matrix), a.matrix.decompose(a.position, a.rotation, a.scale), i.linearVelocity ? (a.hasLinearVelocity = !0, a.linearVelocity.copy(i.linearVelocity)) : a.hasLinearVelocity = !1, i.angularVelocity ? (a.hasAngularVelocity = !0, a.angularVelocity.copy(i.angularVelocity)) : a.hasAngularVelocity = !1, this.dispatchEvent(Ax))), c && e.hand) {
            o = !0;
            for (let x of e.hand.values()){
                let v = t.getJointPose(x, n);
                if (c.joints[x.jointName] === void 0) {
                    let p = new Hn;
                    p.matrixAutoUpdate = !1, p.visible = !1, c.joints[x.jointName] = p, c.add(p);
                }
                let g = c.joints[x.jointName];
                v !== null && (g.matrix.fromArray(v.transform.matrix), g.matrix.decompose(g.position, g.rotation, g.scale), g.jointRadius = v.radius), g.visible = v !== null;
            }
            let h = c.joints["index-finger-tip"], u = c.joints["thumb-tip"], d = h.position.distanceTo(u.position), f = .02, m = .005;
            c.inputState.pinching && d > f + m ? (c.inputState.pinching = !1, this.dispatchEvent({
                type: "pinchend",
                handedness: e.handedness,
                target: this
            })) : !c.inputState.pinching && d <= f - m && (c.inputState.pinching = !0, this.dispatchEvent({
                type: "pinchstart",
                handedness: e.handedness,
                target: this
            }));
        } else l !== null && e.gripSpace && (r = t.getPose(e.gripSpace, n), r !== null && (l.matrix.fromArray(r.transform.matrix), l.matrix.decompose(l.position, l.rotation, l.scale), r.linearVelocity ? (l.hasLinearVelocity = !0, l.linearVelocity.copy(r.linearVelocity)) : l.hasLinearVelocity = !1, r.angularVelocity ? (l.hasAngularVelocity = !0, l.angularVelocity.copy(r.angularVelocity)) : l.hasAngularVelocity = !1));
        return a !== null && (a.visible = i !== null), l !== null && (l.visible = r !== null), c !== null && (c.visible = o !== null), this;
    }
}, ks = class extends ot {
    constructor(e, t, n, i, r, o, a, l, c, h){
        if (h = h !== void 0 ? h : Vn, h !== Vn && h !== Li) throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");
        n === void 0 && h === Vn && (n = cr), n === void 0 && h === Li && (n = Ti);
        super(null, i, r, o, a, l, h, n, c);
        this.image = {
            width: e,
            height: t
        }, this.magFilter = a !== void 0 ? a : rt, this.minFilter = l !== void 0 ? l : rt, this.flipY = !1, this.generateMipmaps = !1;
    }
};
ks.prototype.isDepthTexture = !0;
var vh = class extends En {
    constructor(e, t){
        super();
        let n = this, i = null, r = 1, o = null, a = "local-floor", l = e.extensions.has("WEBGL_multisampled_render_to_texture"), c = null, h = null, u = null, d = null, f = !1, m = null, x = t.getContextAttributes(), v = null, g = null, p = [], _ = new Map, y = new ut;
        y.layers.enable(1), y.viewport = new Ve;
        let b = new ut;
        b.layers.enable(2), b.viewport = new Ve;
        let A = [
            y,
            b
        ], L = new ga;
        L.layers.enable(1), L.layers.enable(2);
        let I = null, k = null;
        this.cameraAutoUpdate = !0, this.enabled = !1, this.isPresenting = !1, this.getController = function(V) {
            let W = p[V];
            return W === void 0 && (W = new Is, p[V] = W), W.getTargetRaySpace();
        }, this.getControllerGrip = function(V) {
            let W = p[V];
            return W === void 0 && (W = new Is, p[V] = W), W.getGripSpace();
        }, this.getHand = function(V) {
            let W = p[V];
            return W === void 0 && (W = new Is, p[V] = W), W.getHandSpace();
        };
        function B(V) {
            let W = _.get(V.inputSource);
            W && W.dispatchEvent({
                type: V.type,
                data: V.inputSource
            });
        }
        function P() {
            _.forEach(function(V, W) {
                V.disconnect(W);
            }), _.clear(), I = null, k = null, e.setRenderTarget(v), d = null, u = null, h = null, i = null, g = null, ce.stop(), n.isPresenting = !1, n.dispatchEvent({
                type: "sessionend"
            });
        }
        this.setFramebufferScaleFactor = function(V) {
            r = V, n.isPresenting === !0 && console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.");
        }, this.setReferenceSpaceType = function(V) {
            a = V, n.isPresenting === !0 && console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.");
        }, this.getReferenceSpace = function() {
            return o;
        }, this.getBaseLayer = function() {
            return u !== null ? u : d;
        }, this.getBinding = function() {
            return h;
        }, this.getFrame = function() {
            return m;
        }, this.getSession = function() {
            return i;
        }, this.setSession = async function(V) {
            if (i = V, i !== null) {
                if (v = e.getRenderTarget(), i.addEventListener("select", B), i.addEventListener("selectstart", B), i.addEventListener("selectend", B), i.addEventListener("squeeze", B), i.addEventListener("squeezestart", B), i.addEventListener("squeezeend", B), i.addEventListener("end", P), i.addEventListener("inputsourceschange", w), x.xrCompatible !== !0 && await t.makeXRCompatible(), i.renderState.layers === void 0 || e.capabilities.isWebGL2 === !1) {
                    let W = {
                        antialias: i.renderState.layers === void 0 ? x.antialias : !0,
                        alpha: x.alpha,
                        depth: x.depth,
                        stencil: x.stencil,
                        framebufferScaleFactor: r
                    };
                    d = new XRWebGLLayer(i, t, W), i.updateRenderState({
                        baseLayer: d
                    }), g = new At(d.framebufferWidth, d.framebufferHeight, {
                        format: ct,
                        type: rn,
                        encoding: e.outputEncoding
                    });
                } else {
                    f = x.antialias;
                    let W1 = null, he = null, le = null;
                    x.depth && (le = x.stencil ? 35056 : 33190, W1 = x.stencil ? Li : Vn, he = x.stencil ? Ti : cr);
                    let fe = {
                        colorFormat: x.alpha || f ? 32856 : 32849,
                        depthFormat: le,
                        scaleFactor: r
                    };
                    h = new XRWebGLBinding(i, t), u = h.createProjectionLayer(fe), i.updateRenderState({
                        layers: [
                            u
                        ]
                    }), f ? g = new Xs(u.textureWidth, u.textureHeight, {
                        format: ct,
                        type: rn,
                        depthTexture: new ks(u.textureWidth, u.textureHeight, he, void 0, void 0, void 0, void 0, void 0, void 0, W1),
                        stencilBuffer: x.stencil,
                        ignoreDepth: u.ignoreDepthValues,
                        useRenderToTexture: l,
                        encoding: e.outputEncoding
                    }) : g = new At(u.textureWidth, u.textureHeight, {
                        format: x.alpha ? ct : Gn,
                        type: rn,
                        depthTexture: new ks(u.textureWidth, u.textureHeight, he, void 0, void 0, void 0, void 0, void 0, void 0, W1),
                        stencilBuffer: x.stencil,
                        ignoreDepth: u.ignoreDepthValues,
                        encoding: e.outputEncoding
                    });
                }
                this.setFoveation(1), o = await i.requestReferenceSpace(a), ce.setContext(i), ce.start(), n.isPresenting = !0, n.dispatchEvent({
                    type: "sessionstart"
                });
            }
        };
        function w(V) {
            let W = i.inputSources;
            for(let he = 0; he < p.length; he++)_.set(W[he], p[he]);
            for(let he1 = 0; he1 < V.removed.length; he1++){
                let le = V.removed[he1], fe = _.get(le);
                fe && (fe.dispatchEvent({
                    type: "disconnected",
                    data: le
                }), _.delete(le));
            }
            for(let he2 = 0; he2 < V.added.length; he2++){
                let le1 = V.added[he2], fe1 = _.get(le1);
                fe1 && fe1.dispatchEvent({
                    type: "connected",
                    data: le1
                });
            }
        }
        let E = new M, D = new M;
        function U(V, W, he) {
            E.setFromMatrixPosition(W.matrixWorld), D.setFromMatrixPosition(he.matrixWorld);
            let le = E.distanceTo(D), fe = W.projectionMatrix.elements, Be = he.projectionMatrix.elements, Y = fe[14] / (fe[10] - 1), Ce = fe[14] / (fe[10] + 1), ye = (fe[9] + 1) / fe[5], ge = (fe[9] - 1) / fe[5], xe = (fe[8] - 1) / fe[0], Oe = (Be[8] + 1) / Be[0], G = Y * xe, j = Y * Oe, K = le / (-xe + Oe), ue = K * -xe;
            W.matrixWorld.decompose(V.position, V.quaternion, V.scale), V.translateX(ue), V.translateZ(K), V.matrixWorld.compose(V.position, V.quaternion, V.scale), V.matrixWorldInverse.copy(V.matrixWorld).invert();
            let se = Y + K, Se = Ce + K, Te = G - ue, Pe = j + (le - ue), Ye = ye * Ce / Se * se, C = ge * Ce / Se * se;
            V.projectionMatrix.makePerspective(Te, Pe, Ye, C, se, Se);
        }
        function F(V, W) {
            W === null ? V.matrixWorld.copy(V.matrix) : V.matrixWorld.multiplyMatrices(W.matrixWorld, V.matrix), V.matrixWorldInverse.copy(V.matrixWorld).invert();
        }
        this.updateCamera = function(V) {
            if (i === null) return;
            L.near = b.near = y.near = V.near, L.far = b.far = y.far = V.far, (I !== L.near || k !== L.far) && (i.updateRenderState({
                depthNear: L.near,
                depthFar: L.far
            }), I = L.near, k = L.far);
            let W = V.parent, he = L.cameras;
            F(L, W);
            for(let fe = 0; fe < he.length; fe++)F(he[fe], W);
            L.matrixWorld.decompose(L.position, L.quaternion, L.scale), V.position.copy(L.position), V.quaternion.copy(L.quaternion), V.scale.copy(L.scale), V.matrix.copy(L.matrix), V.matrixWorld.copy(L.matrixWorld);
            let le = V.children;
            for(let fe1 = 0, Be = le.length; fe1 < Be; fe1++)le[fe1].updateMatrixWorld(!0);
            he.length === 2 ? U(L, y, b) : L.projectionMatrix.copy(y.projectionMatrix);
        }, this.getCamera = function() {
            return L;
        }, this.getFoveation = function() {
            if (u !== null) return u.fixedFoveation;
            if (d !== null) return d.fixedFoveation;
        }, this.setFoveation = function(V) {
            u !== null && (u.fixedFoveation = V), d !== null && d.fixedFoveation !== void 0 && (d.fixedFoveation = V);
        };
        let O = null;
        function ne(V, W) {
            if (c = W.getViewerPose(o), m = W, c !== null) {
                let le = c.views;
                d !== null && (e.setRenderTargetFramebuffer(g, d.framebuffer), e.setRenderTarget(g));
                let fe = !1;
                le.length !== L.cameras.length && (L.cameras.length = 0, fe = !0);
                for(let Be = 0; Be < le.length; Be++){
                    let Y = le[Be], Ce = null;
                    if (d !== null) Ce = d.getViewport(Y);
                    else {
                        let ge = h.getViewSubImage(u, Y);
                        Ce = ge.viewport, Be === 0 && (e.setRenderTargetTextures(g, ge.colorTexture, u.ignoreDepthValues ? void 0 : ge.depthStencilTexture), e.setRenderTarget(g));
                    }
                    let ye = A[Be];
                    ye.matrix.fromArray(Y.transform.matrix), ye.projectionMatrix.fromArray(Y.projectionMatrix), ye.viewport.set(Ce.x, Ce.y, Ce.width, Ce.height), Be === 0 && L.matrix.copy(ye.matrix), fe === !0 && L.cameras.push(ye);
                }
            }
            let he = i.inputSources;
            for(let le1 = 0; le1 < p.length; le1++){
                let fe1 = p[le1], Be1 = he[le1];
                fe1.update(Be1, W, o);
            }
            O && O(V, W), m = null;
        }
        let ce = new rh;
        ce.setAnimationLoop(ne), this.setAnimationLoop = function(V) {
            O = V;
        }, this.dispose = function() {};
    }
};
function Cx(s) {
    function e(g, p) {
        g.fogColor.value.copy(p.color), p.isFog ? (g.fogNear.value = p.near, g.fogFar.value = p.far) : p.isFogExp2 && (g.fogDensity.value = p.density);
    }
    function t(g, p, _, y, b) {
        p.isMeshBasicMaterial ? n(g, p) : p.isMeshLambertMaterial ? (n(g, p), l(g, p)) : p.isMeshToonMaterial ? (n(g, p), h(g, p)) : p.isMeshPhongMaterial ? (n(g, p), c(g, p)) : p.isMeshStandardMaterial ? (n(g, p), p.isMeshPhysicalMaterial ? d(g, p, b) : u(g, p)) : p.isMeshMatcapMaterial ? (n(g, p), f(g, p)) : p.isMeshDepthMaterial ? (n(g, p), m(g, p)) : p.isMeshDistanceMaterial ? (n(g, p), x(g, p)) : p.isMeshNormalMaterial ? (n(g, p), v(g, p)) : p.isLineBasicMaterial ? (i(g, p), p.isLineDashedMaterial && r(g, p)) : p.isPointsMaterial ? o(g, p, _, y) : p.isSpriteMaterial ? a(g, p) : p.isShadowMaterial ? (g.color.value.copy(p.color), g.opacity.value = p.opacity) : p.isShaderMaterial && (p.uniformsNeedUpdate = !1);
    }
    function n(g, p) {
        g.opacity.value = p.opacity, p.color && g.diffuse.value.copy(p.color), p.emissive && g.emissive.value.copy(p.emissive).multiplyScalar(p.emissiveIntensity), p.map && (g.map.value = p.map), p.alphaMap && (g.alphaMap.value = p.alphaMap), p.specularMap && (g.specularMap.value = p.specularMap), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
        let _ = s.get(p).envMap;
        _ && (g.envMap.value = _, g.flipEnvMap.value = _.isCubeTexture && _.isRenderTargetTexture === !1 ? -1 : 1, g.reflectivity.value = p.reflectivity, g.ior.value = p.ior, g.refractionRatio.value = p.refractionRatio), p.lightMap && (g.lightMap.value = p.lightMap, g.lightMapIntensity.value = p.lightMapIntensity), p.aoMap && (g.aoMap.value = p.aoMap, g.aoMapIntensity.value = p.aoMapIntensity);
        let y;
        p.map ? y = p.map : p.specularMap ? y = p.specularMap : p.displacementMap ? y = p.displacementMap : p.normalMap ? y = p.normalMap : p.bumpMap ? y = p.bumpMap : p.roughnessMap ? y = p.roughnessMap : p.metalnessMap ? y = p.metalnessMap : p.alphaMap ? y = p.alphaMap : p.emissiveMap ? y = p.emissiveMap : p.clearcoatMap ? y = p.clearcoatMap : p.clearcoatNormalMap ? y = p.clearcoatNormalMap : p.clearcoatRoughnessMap ? y = p.clearcoatRoughnessMap : p.specularIntensityMap ? y = p.specularIntensityMap : p.specularColorMap ? y = p.specularColorMap : p.transmissionMap ? y = p.transmissionMap : p.thicknessMap ? y = p.thicknessMap : p.sheenColorMap ? y = p.sheenColorMap : p.sheenRoughnessMap && (y = p.sheenRoughnessMap), y !== void 0 && (y.isWebGLRenderTarget && (y = y.texture), y.matrixAutoUpdate === !0 && y.updateMatrix(), g.uvTransform.value.copy(y.matrix));
        let b;
        p.aoMap ? b = p.aoMap : p.lightMap && (b = p.lightMap), b !== void 0 && (b.isWebGLRenderTarget && (b = b.texture), b.matrixAutoUpdate === !0 && b.updateMatrix(), g.uv2Transform.value.copy(b.matrix));
    }
    function i(g, p) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity;
    }
    function r(g, p) {
        g.dashSize.value = p.dashSize, g.totalSize.value = p.dashSize + p.gapSize, g.scale.value = p.scale;
    }
    function o(g, p, _, y) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, g.size.value = p.size * _, g.scale.value = y * .5, p.map && (g.map.value = p.map), p.alphaMap && (g.alphaMap.value = p.alphaMap), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
        let b;
        p.map ? b = p.map : p.alphaMap && (b = p.alphaMap), b !== void 0 && (b.matrixAutoUpdate === !0 && b.updateMatrix(), g.uvTransform.value.copy(b.matrix));
    }
    function a(g, p) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, g.rotation.value = p.rotation, p.map && (g.map.value = p.map), p.alphaMap && (g.alphaMap.value = p.alphaMap), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
        let _;
        p.map ? _ = p.map : p.alphaMap && (_ = p.alphaMap), _ !== void 0 && (_.matrixAutoUpdate === !0 && _.updateMatrix(), g.uvTransform.value.copy(_.matrix));
    }
    function l(g, p) {
        p.emissiveMap && (g.emissiveMap.value = p.emissiveMap);
    }
    function c(g, p) {
        g.specular.value.copy(p.specular), g.shininess.value = Math.max(p.shininess, 1e-4), p.emissiveMap && (g.emissiveMap.value = p.emissiveMap), p.bumpMap && (g.bumpMap.value = p.bumpMap, g.bumpScale.value = p.bumpScale, p.side === it && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, g.normalScale.value.copy(p.normalScale), p.side === it && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias);
    }
    function h(g, p) {
        p.gradientMap && (g.gradientMap.value = p.gradientMap), p.emissiveMap && (g.emissiveMap.value = p.emissiveMap), p.bumpMap && (g.bumpMap.value = p.bumpMap, g.bumpScale.value = p.bumpScale, p.side === it && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, g.normalScale.value.copy(p.normalScale), p.side === it && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias);
    }
    function u(g, p) {
        g.roughness.value = p.roughness, g.metalness.value = p.metalness, p.roughnessMap && (g.roughnessMap.value = p.roughnessMap), p.metalnessMap && (g.metalnessMap.value = p.metalnessMap), p.emissiveMap && (g.emissiveMap.value = p.emissiveMap), p.bumpMap && (g.bumpMap.value = p.bumpMap, g.bumpScale.value = p.bumpScale, p.side === it && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, g.normalScale.value.copy(p.normalScale), p.side === it && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias), s.get(p).envMap && (g.envMapIntensity.value = p.envMapIntensity);
    }
    function d(g, p, _) {
        u(g, p), g.ior.value = p.ior, p.sheen > 0 && (g.sheenColor.value.copy(p.sheenColor).multiplyScalar(p.sheen), g.sheenRoughness.value = p.sheenRoughness, p.sheenColorMap && (g.sheenColorMap.value = p.sheenColorMap), p.sheenRoughnessMap && (g.sheenRoughnessMap.value = p.sheenRoughnessMap)), p.clearcoat > 0 && (g.clearcoat.value = p.clearcoat, g.clearcoatRoughness.value = p.clearcoatRoughness, p.clearcoatMap && (g.clearcoatMap.value = p.clearcoatMap), p.clearcoatRoughnessMap && (g.clearcoatRoughnessMap.value = p.clearcoatRoughnessMap), p.clearcoatNormalMap && (g.clearcoatNormalScale.value.copy(p.clearcoatNormalScale), g.clearcoatNormalMap.value = p.clearcoatNormalMap, p.side === it && g.clearcoatNormalScale.value.negate())), p.transmission > 0 && (g.transmission.value = p.transmission, g.transmissionSamplerMap.value = _.texture, g.transmissionSamplerSize.value.set(_.width, _.height), p.transmissionMap && (g.transmissionMap.value = p.transmissionMap), g.thickness.value = p.thickness, p.thicknessMap && (g.thicknessMap.value = p.thicknessMap), g.attenuationDistance.value = p.attenuationDistance, g.attenuationColor.value.copy(p.attenuationColor)), g.specularIntensity.value = p.specularIntensity, g.specularColor.value.copy(p.specularColor), p.specularIntensityMap && (g.specularIntensityMap.value = p.specularIntensityMap), p.specularColorMap && (g.specularColorMap.value = p.specularColorMap);
    }
    function f(g, p) {
        p.matcap && (g.matcap.value = p.matcap), p.bumpMap && (g.bumpMap.value = p.bumpMap, g.bumpScale.value = p.bumpScale, p.side === it && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, g.normalScale.value.copy(p.normalScale), p.side === it && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias);
    }
    function m(g, p) {
        p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias);
    }
    function x(g, p) {
        p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias), g.referencePosition.value.copy(p.referencePosition), g.nearDistance.value = p.nearDistance, g.farDistance.value = p.farDistance;
    }
    function v(g, p) {
        p.bumpMap && (g.bumpMap.value = p.bumpMap, g.bumpScale.value = p.bumpScale, p.side === it && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, g.normalScale.value.copy(p.normalScale), p.side === it && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias);
    }
    return {
        refreshFogUniforms: e,
        refreshMaterialUniforms: t
    };
}
function Lx() {
    let s = qs("canvas");
    return s.style.display = "block", s;
}
function qe(s = {}) {
    let e = s.canvas !== void 0 ? s.canvas : Lx(), t = s.context !== void 0 ? s.context : null, n = s.alpha !== void 0 ? s.alpha : !1, i = s.depth !== void 0 ? s.depth : !0, r = s.stencil !== void 0 ? s.stencil : !0, o = s.antialias !== void 0 ? s.antialias : !1, a = s.premultipliedAlpha !== void 0 ? s.premultipliedAlpha : !0, l = s.preserveDrawingBuffer !== void 0 ? s.preserveDrawingBuffer : !1, c = s.powerPreference !== void 0 ? s.powerPreference : "default", h = s.failIfMajorPerformanceCaveat !== void 0 ? s.failIfMajorPerformanceCaveat : !1, u = null, d = null, f = [], m = [];
    this.domElement = e, this.debug = {
        checkShaderErrors: !0
    }, this.autoClear = !0, this.autoClearColor = !0, this.autoClearDepth = !0, this.autoClearStencil = !0, this.sortObjects = !0, this.clippingPlanes = [], this.localClippingEnabled = !1, this.outputEncoding = Nt, this.physicallyCorrectLights = !1, this.toneMapping = _n, this.toneMappingExposure = 1;
    let x = this, v = !1, g = 0, p = 0, _ = null, y = -1, b = null, A = new Ve, L = new Ve, I = null, k = e.width, B = e.height, P = 1, w = null, E = null, D = new Ve(0, 0, k, B), U = new Ve(0, 0, k, B), F = !1, O = [], ne = new Dr, ce = !1, V = !1, W = null, he = new pe, le = new M, fe = {
        background: null,
        fog: null,
        environment: null,
        overrideMaterial: null,
        isScene: !0
    };
    function Be() {
        return _ === null ? P : 1;
    }
    let Y = t;
    function Ce(S, N) {
        for(let H = 0; H < S.length; H++){
            let z = S[H], q = e.getContext(z, N);
            if (q !== null) return q;
        }
        return null;
    }
    try {
        let S = {
            alpha: n,
            depth: i,
            stencil: r,
            antialias: o,
            premultipliedAlpha: a,
            preserveDrawingBuffer: l,
            powerPreference: c,
            failIfMajorPerformanceCaveat: h
        };
        if ("setAttribute" in e && e.setAttribute("data-engine", `three.js r${ca}`), e.addEventListener("webglcontextlost", Ee, !1), e.addEventListener("webglcontextrestored", me, !1), Y === null) {
            let N = [
                "webgl2",
                "webgl",
                "experimental-webgl"
            ];
            if (x.isWebGL1Renderer === !0 && N.shift(), Y = Ce(N, S), Y === null) throw Ce(N) ? new Error("Error creating WebGL context with your selected attributes.") : new Error("Error creating WebGL context.");
        }
        Y.getShaderPrecisionFormat === void 0 && (Y.getShaderPrecisionFormat = function() {
            return {
                rangeMin: 1,
                rangeMax: 1,
                precision: 1
            };
        });
    } catch (S1) {
        throw console.error("THREE.WebGLRenderer: " + S1.message), S1;
    }
    let ye, ge, xe, Oe, G, j, K, ue, se, Se, Te, Pe, Ye, C, T, J, $, re, Z, Me, ve, te, R;
    function ee() {
        ye = new Qm(Y), ge = new Xm(Y, ye, s), ye.init(ge), te = new Ex(Y, ye, ge), xe = new Sx(Y, ye, ge), O[0] = 1029, Oe = new tg(Y), G = new fx, j = new Tx(Y, ye, xe, G, ge, te, Oe), K = new Ym(x), ue = new jm(x), se = new gf(Y, ge), R = new Wm(Y, ye, se, ge), Se = new Km(Y, se, Oe, R), Te = new sg(Y, Se, se, Oe), Z = new rg(Y, ge, j), J = new Jm(G), Pe = new dx(x, K, ue, ye, ge, R, J), Ye = new Cx(G), C = new mx, T = new Mx(ye, ge), re = new Vm(x, K, xe, Te, a), $ = new yh(x, Te, ge), Me = new qm(Y, ye, Oe, ge), ve = new eg(Y, ye, Oe, ge), Oe.programs = Pe.programs, x.capabilities = ge, x.extensions = ye, x.properties = G, x.renderLists = C, x.shadowMap = $, x.state = xe, x.info = Oe;
    }
    ee();
    let Q = new vh(x, Y);
    this.xr = Q, this.getContext = function() {
        return Y;
    }, this.getContextAttributes = function() {
        return Y.getContextAttributes();
    }, this.forceContextLoss = function() {
        let S = ye.get("WEBGL_lose_context");
        S && S.loseContext();
    }, this.forceContextRestore = function() {
        let S = ye.get("WEBGL_lose_context");
        S && S.restoreContext();
    }, this.getPixelRatio = function() {
        return P;
    }, this.setPixelRatio = function(S) {
        S !== void 0 && (P = S, this.setSize(k, B, !1));
    }, this.getSize = function(S) {
        return S.set(k, B);
    }, this.setSize = function(S, N, H) {
        if (Q.isPresenting) {
            console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting.");
            return;
        }
        k = S, B = N, e.width = Math.floor(S * P), e.height = Math.floor(N * P), H !== !1 && (e.style.width = S + "px", e.style.height = N + "px"), this.setViewport(0, 0, S, N);
    }, this.getDrawingBufferSize = function(S) {
        return S.set(k * P, B * P).floor();
    }, this.setDrawingBufferSize = function(S, N, H) {
        k = S, B = N, P = H, e.width = Math.floor(S * H), e.height = Math.floor(N * H), this.setViewport(0, 0, S, N);
    }, this.getCurrentViewport = function(S) {
        return S.copy(A);
    }, this.getViewport = function(S) {
        return S.copy(D);
    }, this.setViewport = function(S, N, H, z) {
        S.isVector4 ? D.set(S.x, S.y, S.z, S.w) : D.set(S, N, H, z), xe.viewport(A.copy(D).multiplyScalar(P).floor());
    }, this.getScissor = function(S) {
        return S.copy(U);
    }, this.setScissor = function(S, N, H, z) {
        S.isVector4 ? U.set(S.x, S.y, S.z, S.w) : U.set(S, N, H, z), xe.scissor(L.copy(U).multiplyScalar(P).floor());
    }, this.getScissorTest = function() {
        return F;
    }, this.setScissorTest = function(S) {
        xe.setScissorTest(F = S);
    }, this.setOpaqueSort = function(S) {
        w = S;
    }, this.setTransparentSort = function(S) {
        E = S;
    }, this.getClearColor = function(S) {
        return S.copy(re.getClearColor());
    }, this.setClearColor = function() {
        re.setClearColor.apply(re, arguments);
    }, this.getClearAlpha = function() {
        return re.getClearAlpha();
    }, this.setClearAlpha = function() {
        re.setClearAlpha.apply(re, arguments);
    }, this.clear = function(S, N, H) {
        let z = 0;
        (S === void 0 || S) && (z |= 16384), (N === void 0 || N) && (z |= 256), (H === void 0 || H) && (z |= 1024), Y.clear(z);
    }, this.clearColor = function() {
        this.clear(!0, !1, !1);
    }, this.clearDepth = function() {
        this.clear(!1, !0, !1);
    }, this.clearStencil = function() {
        this.clear(!1, !1, !0);
    }, this.dispose = function() {
        e.removeEventListener("webglcontextlost", Ee, !1), e.removeEventListener("webglcontextrestored", me, !1), C.dispose(), T.dispose(), G.dispose(), K.dispose(), ue.dispose(), Te.dispose(), R.dispose(), Pe.dispose(), Q.dispose(), Q.removeEventListener("sessionstart", Ut), Q.removeEventListener("sessionend", Ot), W && (W.dispose(), W = null), Ln.stop();
    };
    function Ee(S) {
        S.preventDefault(), console.log("THREE.WebGLRenderer: Context Lost."), v = !0;
    }
    function me() {
        console.log("THREE.WebGLRenderer: Context Restored."), v = !1;
        let S = Oe.autoReset, N = $.enabled, H = $.autoUpdate, z = $.needsUpdate, q = $.type;
        ee(), Oe.autoReset = S, $.enabled = N, $.autoUpdate = H, $.needsUpdate = z, $.type = q;
    }
    function Re(S) {
        let N = S.target;
        N.removeEventListener("dispose", Re), oe(N);
    }
    function oe(S) {
        Le(S), G.remove(S);
    }
    function Le(S) {
        let N = G.get(S).programs;
        N !== void 0 && (N.forEach(function(H) {
            Pe.releaseProgram(H);
        }), S.isShaderMaterial && Pe.releaseShaderCache(S));
    }
    this.renderBufferDirect = function(S, N, H, z, q, be) {
        N === null && (N = fe);
        let Ae = q.isMesh && q.matrixWorld.determinant() < 0, Ie = lu(S, N, H, z, q);
        xe.setMaterial(z, Ae);
        let we = H.index, He = H.attributes.position;
        if (we === null) {
            if (He === void 0 || He.count === 0) return;
        } else if (we.count === 0) return;
        let De = 1;
        z.wireframe === !0 && (we = Se.getWireframeAttribute(H), De = 2), R.setup(q, z, Ie, H, we);
        let ze, je = Me;
        we !== null && (ze = se.get(we), je = ve, je.setIndex(ze));
        let Rn = we !== null ? we.count : He.count, ei = H.drawRange.start * De, Ge = H.drawRange.count * De, Ht = be !== null ? be.start * De : 0, at = be !== null ? be.count * De : 1 / 0, kt = Math.max(ei, Ht), Gr = Math.min(Rn, ei + Ge, Ht + at) - 1, Gt = Math.max(0, Gr - kt + 1);
        if (Gt !== 0) {
            if (q.isMesh) z.wireframe === !0 ? (xe.setLineWidth(z.wireframeLinewidth * Be()), je.setMode(1)) : je.setMode(4);
            else if (q.isLine) {
                let Zt = z.linewidth;
                Zt === void 0 && (Zt = 1), xe.setLineWidth(Zt * Be()), q.isLineSegments ? je.setMode(1) : q.isLineLoop ? je.setMode(2) : je.setMode(3);
            } else q.isPoints ? je.setMode(0) : q.isSprite && je.setMode(4);
            if (q.isInstancedMesh) je.renderInstances(kt, Gt, q.count);
            else if (H.isInstancedBufferGeometry) {
                let Zt1 = Math.min(H.instanceCount, H._maxInstanceCount);
                je.renderInstances(kt, Gt, Zt1);
            } else je.render(kt, Gt);
        }
    }, this.compile = function(S, N) {
        d = T.get(S), d.init(), m.push(d), S.traverseVisible(function(H) {
            H.isLight && H.layers.test(N.layers) && (d.pushLight(H), H.castShadow && d.pushShadow(H));
        }), d.setupLights(x.physicallyCorrectLights), S.traverse(function(H) {
            let z = H.material;
            if (z) if (Array.isArray(z)) for(let q = 0; q < z.length; q++){
                let be = z[q];
                xo(be, S, H);
            }
            else xo(z, S, H);
        }), m.pop(), d = null;
    };
    let Xe = null;
    function We(S) {
        Xe && Xe(S);
    }
    function Ut() {
        Ln.stop();
    }
    function Ot() {
        Ln.start();
    }
    let Ln = new rh;
    Ln.setAnimationLoop(We), typeof window < "u" && Ln.setContext(window), this.setAnimationLoop = function(S) {
        Xe = S, Q.setAnimationLoop(S), S === null ? Ln.stop() : Ln.start();
    }, Q.addEventListener("sessionstart", Ut), Q.addEventListener("sessionend", Ot), this.render = function(S, N) {
        if (N !== void 0 && N.isCamera !== !0) {
            console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
            return;
        }
        if (v === !0) return;
        S.autoUpdate === !0 && S.updateMatrixWorld(), N.parent === null && N.updateMatrixWorld(), Q.enabled === !0 && Q.isPresenting === !0 && (Q.cameraAutoUpdate === !0 && Q.updateCamera(N), N = Q.getCamera()), S.isScene === !0 && S.onBeforeRender(x, S, N, _), d = T.get(S, m.length), d.init(), m.push(d), he.multiplyMatrices(N.projectionMatrix, N.matrixWorldInverse), ne.setFromProjectionMatrix(he), V = this.localClippingEnabled, ce = J.init(this.clippingPlanes, V, N), u = C.get(S, f.length), u.init(), f.push(u), Qa(S, N, 0, x.sortObjects), u.finish(), x.sortObjects === !0 && u.sort(w, E), ce === !0 && J.beginShadows();
        let H = d.state.shadowsArray;
        if ($.render(H, S, N), ce === !0 && J.endShadows(), this.info.autoReset === !0 && this.info.reset(), re.render(u, S), d.setupLights(x.physicallyCorrectLights), N.isArrayCamera) {
            let z = N.cameras;
            for(let q = 0, be = z.length; q < be; q++){
                let Ae = z[q];
                Ka(u, S, Ae, Ae.viewport);
            }
        } else Ka(u, S, N);
        _ !== null && (j.updateMultisampleRenderTarget(_), j.updateRenderTargetMipmap(_)), S.isScene === !0 && S.onAfterRender(x, S, N), xe.buffers.depth.setTest(!0), xe.buffers.depth.setMask(!0), xe.buffers.color.setMask(!0), xe.setPolygonOffset(!1), R.resetDefaultState(), y = -1, b = null, m.pop(), m.length > 0 ? d = m[m.length - 1] : d = null, f.pop(), f.length > 0 ? u = f[f.length - 1] : u = null;
    };
    function Qa(S, N, H, z) {
        if (S.visible === !1) return;
        if (S.layers.test(N.layers)) {
            if (S.isGroup) H = S.renderOrder;
            else if (S.isLOD) S.autoUpdate === !0 && S.update(N);
            else if (S.isLight) d.pushLight(S), S.castShadow && d.pushShadow(S);
            else if (S.isSprite) {
                if (!S.frustumCulled || ne.intersectsSprite(S)) {
                    z && le.setFromMatrixPosition(S.matrixWorld).applyMatrix4(he);
                    let Ae = Te.update(S), Ie = S.material;
                    Ie.visible && u.push(S, Ae, Ie, H, le.z, null);
                }
            } else if ((S.isMesh || S.isLine || S.isPoints) && (S.isSkinnedMesh && S.skeleton.frame !== Oe.render.frame && (S.skeleton.update(), S.skeleton.frame = Oe.render.frame), !S.frustumCulled || ne.intersectsObject(S))) {
                z && le.setFromMatrixPosition(S.matrixWorld).applyMatrix4(he);
                let Ae1 = Te.update(S), Ie1 = S.material;
                if (Array.isArray(Ie1)) {
                    let we = Ae1.groups;
                    for(let He = 0, De = we.length; He < De; He++){
                        let ze = we[He], je = Ie1[ze.materialIndex];
                        je && je.visible && u.push(S, Ae1, je, H, le.z, ze);
                    }
                } else Ie1.visible && u.push(S, Ae1, Ie1, H, le.z, null);
            }
        }
        let be = S.children;
        for(let Ae2 = 0, Ie2 = be.length; Ae2 < Ie2; Ae2++)Qa(be[Ae2], N, H, z);
    }
    function Ka(S, N, H, z) {
        let q = S.opaque, be = S.transmissive, Ae = S.transparent;
        d.setupLightsView(H), be.length > 0 && ou(q, N, H), z && xe.viewport(A.copy(z)), q.length > 0 && kr(q, N, H), be.length > 0 && kr(be, N, H), Ae.length > 0 && kr(Ae, N, H);
    }
    function ou(S, N, H) {
        if (W === null) {
            let Ae = o === !0 && ge.isWebGL2 === !0 ? Xs : At;
            W = new Ae(1024, 1024, {
                generateMipmaps: !0,
                type: te.convert(kn) !== null ? kn : rn,
                minFilter: Ui,
                magFilter: rt,
                wrapS: vt,
                wrapT: vt,
                useRenderToTexture: ye.has("WEBGL_multisampled_render_to_texture")
            });
        }
        let z = x.getRenderTarget();
        x.setRenderTarget(W), x.clear();
        let q = x.toneMapping;
        x.toneMapping = _n, kr(S, N, H), x.toneMapping = q, j.updateMultisampleRenderTarget(W), j.updateRenderTargetMipmap(W), x.setRenderTarget(z);
    }
    function kr(S, N, H) {
        let z = N.isScene === !0 ? N.overrideMaterial : null;
        for(let q = 0, be = S.length; q < be; q++){
            let Ae = S[q], Ie = Ae.object, we = Ae.geometry, He = z === null ? Ae.material : z, De = Ae.group;
            Ie.layers.test(H.layers) && au(Ie, N, H, we, He, De);
        }
    }
    function au(S, N, H, z, q, be) {
        S.onBeforeRender(x, N, H, z, q, be), S.modelViewMatrix.multiplyMatrices(H.matrixWorldInverse, S.matrixWorld), S.normalMatrix.getNormalMatrix(S.modelViewMatrix), q.onBeforeRender(x, N, H, z, S, be), q.transparent === !0 && q.side === Ci ? (q.side = it, q.needsUpdate = !0, x.renderBufferDirect(H, N, z, q, S, be), q.side = Ai, q.needsUpdate = !0, x.renderBufferDirect(H, N, z, q, S, be), q.side = Ci) : x.renderBufferDirect(H, N, z, q, S, be), S.onAfterRender(x, N, H, z, q, be);
    }
    function xo(S, N, H) {
        N.isScene !== !0 && (N = fe);
        let z = G.get(S), q = d.state.lights, be = d.state.shadowsArray, Ae = q.state.version, Ie = Pe.getParameters(S, q.state, be, N, H), we = Pe.getProgramCacheKey(Ie), He = z.programs;
        z.environment = S.isMeshStandardMaterial ? N.environment : null, z.fog = N.fog, z.envMap = (S.isMeshStandardMaterial ? ue : K).get(S.envMap || z.environment), He === void 0 && (S.addEventListener("dispose", Re), He = new Map, z.programs = He);
        let De = He.get(we);
        if (De !== void 0) {
            if (z.currentProgram === De && z.lightsStateVersion === Ae) return el(S, Ie), De;
        } else Ie.uniforms = Pe.getUniforms(S), S.onBuild(H, Ie, x), S.onBeforeCompile(Ie, x), De = Pe.acquireProgram(Ie, we), He.set(we, De), z.uniforms = Ie.uniforms;
        let ze = z.uniforms;
        (!S.isShaderMaterial && !S.isRawShaderMaterial || S.clipping === !0) && (ze.clippingPlanes = J.uniform), el(S, Ie), z.needsLights = hu(S), z.lightsStateVersion = Ae, z.needsLights && (ze.ambientLightColor.value = q.state.ambient, ze.lightProbe.value = q.state.probe, ze.directionalLights.value = q.state.directional, ze.directionalLightShadows.value = q.state.directionalShadow, ze.spotLights.value = q.state.spot, ze.spotLightShadows.value = q.state.spotShadow, ze.rectAreaLights.value = q.state.rectArea, ze.ltc_1.value = q.state.rectAreaLTC1, ze.ltc_2.value = q.state.rectAreaLTC2, ze.pointLights.value = q.state.point, ze.pointLightShadows.value = q.state.pointShadow, ze.hemisphereLights.value = q.state.hemi, ze.directionalShadowMap.value = q.state.directionalShadowMap, ze.directionalShadowMatrix.value = q.state.directionalShadowMatrix, ze.spotShadowMap.value = q.state.spotShadowMap, ze.spotShadowMatrix.value = q.state.spotShadowMatrix, ze.pointShadowMap.value = q.state.pointShadowMap, ze.pointShadowMatrix.value = q.state.pointShadowMatrix);
        let je = De.getUniforms(), Rn = bn.seqWithValue(je.seq, ze);
        return z.currentProgram = De, z.uniformsList = Rn, De;
    }
    function el(S, N) {
        let H = G.get(S);
        H.outputEncoding = N.outputEncoding, H.instancing = N.instancing, H.skinning = N.skinning, H.morphTargets = N.morphTargets, H.morphNormals = N.morphNormals, H.morphTargetsCount = N.morphTargetsCount, H.numClippingPlanes = N.numClippingPlanes, H.numIntersection = N.numClipIntersection, H.vertexAlphas = N.vertexAlphas, H.vertexTangents = N.vertexTangents, H.toneMapping = N.toneMapping;
    }
    function lu(S, N, H, z, q) {
        N.isScene !== !0 && (N = fe), j.resetTextureUnits();
        let be = N.fog, Ae = z.isMeshStandardMaterial ? N.environment : null, Ie = _ === null ? x.outputEncoding : _.texture.encoding, we = (z.isMeshStandardMaterial ? ue : K).get(z.envMap || Ae), He = z.vertexColors === !0 && !!H.attributes.color && H.attributes.color.itemSize === 4, De = !!z.normalMap && !!H.attributes.tangent, ze = !!H.morphAttributes.position, je = !!H.morphAttributes.normal, Rn = H.morphAttributes.position ? H.morphAttributes.position.length : 0, ei = z.toneMapped ? x.toneMapping : _n, Ge = G.get(z), Ht = d.state.lights;
        if (ce === !0 && (V === !0 || S !== b)) {
            let Pt = S === b && z.id === y;
            J.setState(z, S, Pt);
        }
        let at = !1;
        z.version === Ge.__version ? (Ge.needsLights && Ge.lightsStateVersion !== Ht.state.version || Ge.outputEncoding !== Ie || q.isInstancedMesh && Ge.instancing === !1 || !q.isInstancedMesh && Ge.instancing === !0 || q.isSkinnedMesh && Ge.skinning === !1 || !q.isSkinnedMesh && Ge.skinning === !0 || Ge.envMap !== we || z.fog && Ge.fog !== be || Ge.numClippingPlanes !== void 0 && (Ge.numClippingPlanes !== J.numPlanes || Ge.numIntersection !== J.numIntersection) || Ge.vertexAlphas !== He || Ge.vertexTangents !== De || Ge.morphTargets !== ze || Ge.morphNormals !== je || Ge.toneMapping !== ei || ge.isWebGL2 === !0 && Ge.morphTargetsCount !== Rn) && (at = !0) : (at = !0, Ge.__version = z.version);
        let kt = Ge.currentProgram;
        at === !0 && (kt = xo(z, N, q));
        let Gr = !1, Gt = !1, Zt = !1, xt = kt.getUniforms(), Xi = Ge.uniforms;
        if (xe.useProgram(kt.program) && (Gr = !0, Gt = !0, Zt = !0), z.id !== y && (y = z.id, Gt = !0), Gr || b !== S) {
            if (xt.setValue(Y, "projectionMatrix", S.projectionMatrix), ge.logarithmicDepthBuffer && xt.setValue(Y, "logDepthBufFC", 2 / (Math.log(S.far + 1) / Math.LN2)), b !== S && (b = S, Gt = !0, Zt = !0), z.isShaderMaterial || z.isMeshPhongMaterial || z.isMeshToonMaterial || z.isMeshStandardMaterial || z.envMap) {
                let Pt1 = xt.map.cameraPosition;
                Pt1 !== void 0 && Pt1.setValue(Y, le.setFromMatrixPosition(S.matrixWorld));
            }
            (z.isMeshPhongMaterial || z.isMeshToonMaterial || z.isMeshLambertMaterial || z.isMeshBasicMaterial || z.isMeshStandardMaterial || z.isShaderMaterial) && xt.setValue(Y, "isOrthographic", S.isOrthographicCamera === !0), (z.isMeshPhongMaterial || z.isMeshToonMaterial || z.isMeshLambertMaterial || z.isMeshBasicMaterial || z.isMeshStandardMaterial || z.isShaderMaterial || z.isShadowMaterial || q.isSkinnedMesh) && xt.setValue(Y, "viewMatrix", S.matrixWorldInverse);
        }
        if (q.isSkinnedMesh) {
            xt.setOptional(Y, q, "bindMatrix"), xt.setOptional(Y, q, "bindMatrixInverse");
            let Pt2 = q.skeleton;
            Pt2 && (ge.floatVertexTextures ? (Pt2.boneTexture === null && Pt2.computeBoneTexture(), xt.setValue(Y, "boneTexture", Pt2.boneTexture, j), xt.setValue(Y, "boneTextureSize", Pt2.boneTextureSize)) : xt.setOptional(Y, Pt2, "boneMatrices"));
        }
        return !!H && (H.morphAttributes.position !== void 0 || H.morphAttributes.normal !== void 0) && Z.update(q, H, z, kt), (Gt || Ge.receiveShadow !== q.receiveShadow) && (Ge.receiveShadow = q.receiveShadow, xt.setValue(Y, "receiveShadow", q.receiveShadow)), Gt && (xt.setValue(Y, "toneMappingExposure", x.toneMappingExposure), Ge.needsLights && cu(Xi, Zt), be && z.fog && Ye.refreshFogUniforms(Xi, be), Ye.refreshMaterialUniforms(Xi, z, P, B, W), bn.upload(Y, Ge.uniformsList, Xi, j)), z.isShaderMaterial && z.uniformsNeedUpdate === !0 && (bn.upload(Y, Ge.uniformsList, Xi, j), z.uniformsNeedUpdate = !1), z.isSpriteMaterial && xt.setValue(Y, "center", q.center), xt.setValue(Y, "modelViewMatrix", q.modelViewMatrix), xt.setValue(Y, "normalMatrix", q.normalMatrix), xt.setValue(Y, "modelMatrix", q.matrixWorld), kt;
    }
    function cu(S, N) {
        S.ambientLightColor.needsUpdate = N, S.lightProbe.needsUpdate = N, S.directionalLights.needsUpdate = N, S.directionalLightShadows.needsUpdate = N, S.pointLights.needsUpdate = N, S.pointLightShadows.needsUpdate = N, S.spotLights.needsUpdate = N, S.spotLightShadows.needsUpdate = N, S.rectAreaLights.needsUpdate = N, S.hemisphereLights.needsUpdate = N;
    }
    function hu(S) {
        return S.isMeshLambertMaterial || S.isMeshToonMaterial || S.isMeshPhongMaterial || S.isMeshStandardMaterial || S.isShadowMaterial || S.isShaderMaterial && S.lights === !0;
    }
    this.getActiveCubeFace = function() {
        return g;
    }, this.getActiveMipmapLevel = function() {
        return p;
    }, this.getRenderTarget = function() {
        return _;
    }, this.setRenderTargetTextures = function(S, N, H) {
        G.get(S.texture).__webglTexture = N, G.get(S.depthTexture).__webglTexture = H;
        let z = G.get(S);
        z.__hasExternalTextures = !0, z.__hasExternalTextures && (z.__autoAllocateDepthBuffer = H === void 0, z.__autoAllocateDepthBuffer || S.useRenderToTexture && (console.warn("render-to-texture extension was disabled because an external texture was provided"), S.useRenderToTexture = !1, S.useRenderbuffer = !0));
    }, this.setRenderTargetFramebuffer = function(S, N) {
        let H = G.get(S);
        H.__webglFramebuffer = N, H.__useDefaultFramebuffer = N === void 0;
    }, this.setRenderTarget = function(S, N = 0, H = 0) {
        _ = S, g = N, p = H;
        let z = !0;
        if (S) {
            let we = G.get(S);
            we.__useDefaultFramebuffer !== void 0 ? (xe.bindFramebuffer(36160, null), z = !1) : we.__webglFramebuffer === void 0 ? j.setupRenderTarget(S) : we.__hasExternalTextures && j.rebindTextures(S, G.get(S.texture).__webglTexture, G.get(S.depthTexture).__webglTexture);
        }
        let q = null, be = !1, Ae = !1;
        if (S) {
            let we1 = S.texture;
            (we1.isDataTexture3D || we1.isDataTexture2DArray) && (Ae = !0);
            let He = G.get(S).__webglFramebuffer;
            S.isWebGLCubeRenderTarget ? (q = He[N], be = !0) : S.useRenderbuffer ? q = G.get(S).__webglMultisampledFramebuffer : q = He, A.copy(S.viewport), L.copy(S.scissor), I = S.scissorTest;
        } else A.copy(D).multiplyScalar(P).floor(), L.copy(U).multiplyScalar(P).floor(), I = F;
        if (xe.bindFramebuffer(36160, q) && ge.drawBuffers && z) {
            let we2 = !1;
            if (S) if (S.isWebGLMultipleRenderTargets) {
                let He1 = S.texture;
                if (O.length !== He1.length || O[0] !== 36064) {
                    for(let De = 0, ze = He1.length; De < ze; De++)O[De] = 36064 + De;
                    O.length = He1.length, we2 = !0;
                }
            } else (O.length !== 1 || O[0] !== 36064) && (O[0] = 36064, O.length = 1, we2 = !0);
            else (O.length !== 1 || O[0] !== 1029) && (O[0] = 1029, O.length = 1, we2 = !0);
            we2 && (ge.isWebGL2 ? Y.drawBuffers(O) : ye.get("WEBGL_draw_buffers").drawBuffersWEBGL(O));
        }
        if (xe.viewport(A), xe.scissor(L), xe.setScissorTest(I), be) {
            let we3 = G.get(S.texture);
            Y.framebufferTexture2D(36160, 36064, 34069 + N, we3.__webglTexture, H);
        } else if (Ae) {
            let we4 = G.get(S.texture), He2 = N || 0;
            Y.framebufferTextureLayer(36160, 36064, we4.__webglTexture, H || 0, He2);
        }
        y = -1;
    }, this.readRenderTargetPixels = function(S, N, H, z, q, be, Ae) {
        if (!(S && S.isWebGLRenderTarget)) {
            console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");
            return;
        }
        let Ie = G.get(S).__webglFramebuffer;
        if (S.isWebGLCubeRenderTarget && Ae !== void 0 && (Ie = Ie[Ae]), Ie) {
            xe.bindFramebuffer(36160, Ie);
            try {
                let we = S.texture, He = we.format, De = we.type;
                if (He !== ct && te.convert(He) !== Y.getParameter(35739)) {
                    console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");
                    return;
                }
                let ze = De === kn && (ye.has("EXT_color_buffer_half_float") || ge.isWebGL2 && ye.has("EXT_color_buffer_float"));
                if (De !== rn && te.convert(De) !== Y.getParameter(35738) && !(De === nn && (ge.isWebGL2 || ye.has("OES_texture_float") || ye.has("WEBGL_color_buffer_float"))) && !ze) {
                    console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");
                    return;
                }
                Y.checkFramebufferStatus(36160) === 36053 ? N >= 0 && N <= S.width - z && H >= 0 && H <= S.height - q && Y.readPixels(N, H, z, q, te.convert(He), te.convert(De), be) : console.error("THREE.WebGLRenderer.readRenderTargetPixels: readPixels from renderTarget failed. Framebuffer not complete.");
            } finally{
                let we1 = _ !== null ? G.get(_).__webglFramebuffer : null;
                xe.bindFramebuffer(36160, we1);
            }
        }
    }, this.copyFramebufferToTexture = function(S, N, H = 0) {
        if (N.isFramebufferTexture !== !0) {
            console.error("THREE.WebGLRenderer: copyFramebufferToTexture() can only be used with FramebufferTexture.");
            return;
        }
        let z = Math.pow(2, -H), q = Math.floor(N.image.width * z), be = Math.floor(N.image.height * z);
        j.setTexture2D(N, 0), Y.copyTexSubImage2D(3553, H, 0, 0, S.x, S.y, q, be), xe.unbindTexture();
    }, this.copyTextureToTexture = function(S, N, H, z = 0) {
        let q = N.image.width, be = N.image.height, Ae = te.convert(H.format), Ie = te.convert(H.type);
        j.setTexture2D(H, 0), Y.pixelStorei(37440, H.flipY), Y.pixelStorei(37441, H.premultiplyAlpha), Y.pixelStorei(3317, H.unpackAlignment), N.isDataTexture ? Y.texSubImage2D(3553, z, S.x, S.y, q, be, Ae, Ie, N.image.data) : N.isCompressedTexture ? Y.compressedTexSubImage2D(3553, z, S.x, S.y, N.mipmaps[0].width, N.mipmaps[0].height, Ae, N.mipmaps[0].data) : Y.texSubImage2D(3553, z, S.x, S.y, Ae, Ie, N.image), z === 0 && H.generateMipmaps && Y.generateMipmap(3553), xe.unbindTexture();
    }, this.copyTextureToTexture3D = function(S, N, H, z, q = 0) {
        if (x.isWebGL1Renderer) {
            console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: can only be used with WebGL2.");
            return;
        }
        let be = S.max.x - S.min.x + 1, Ae = S.max.y - S.min.y + 1, Ie = S.max.z - S.min.z + 1, we = te.convert(z.format), He = te.convert(z.type), De;
        if (z.isDataTexture3D) j.setTexture3D(z, 0), De = 32879;
        else if (z.isDataTexture2DArray) j.setTexture2DArray(z, 0), De = 35866;
        else {
            console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: only supports THREE.DataTexture3D and THREE.DataTexture2DArray.");
            return;
        }
        Y.pixelStorei(37440, z.flipY), Y.pixelStorei(37441, z.premultiplyAlpha), Y.pixelStorei(3317, z.unpackAlignment);
        let ze = Y.getParameter(3314), je = Y.getParameter(32878), Rn = Y.getParameter(3316), ei = Y.getParameter(3315), Ge = Y.getParameter(32877), Ht = H.isCompressedTexture ? H.mipmaps[0] : H.image;
        Y.pixelStorei(3314, Ht.width), Y.pixelStorei(32878, Ht.height), Y.pixelStorei(3316, S.min.x), Y.pixelStorei(3315, S.min.y), Y.pixelStorei(32877, S.min.z), H.isDataTexture || H.isDataTexture3D ? Y.texSubImage3D(De, q, N.x, N.y, N.z, be, Ae, Ie, we, He, Ht.data) : H.isCompressedTexture ? (console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: untested support for compressed srcTexture."), Y.compressedTexSubImage3D(De, q, N.x, N.y, N.z, be, Ae, Ie, we, Ht.data)) : Y.texSubImage3D(De, q, N.x, N.y, N.z, be, Ae, Ie, we, He, Ht), Y.pixelStorei(3314, ze), Y.pixelStorei(32878, je), Y.pixelStorei(3316, Rn), Y.pixelStorei(3315, ei), Y.pixelStorei(32877, Ge), q === 0 && z.generateMipmaps && Y.generateMipmap(De), xe.unbindTexture();
    }, this.initTexture = function(S) {
        j.setTexture2D(S, 0), xe.unbindTexture();
    }, this.resetState = function() {
        g = 0, p = 0, _ = null, xe.reset(), R.reset();
    }, typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe", {
        detail: this
    }));
}
qe.prototype.isWebGLRenderer = !0;
var _h = class extends qe {
};
_h.prototype.isWebGL1Renderer = !0;
var Nr = class {
    constructor(e, t = 25e-5){
        this.name = "", this.color = new ae(e), this.density = t;
    }
    clone() {
        return new Nr(this.color, this.density);
    }
    toJSON() {
        return {
            type: "FogExp2",
            color: this.color.getHex(),
            density: this.density
        };
    }
};
Nr.prototype.isFogExp2 = !0;
var Br = class {
    constructor(e, t = 1, n = 1e3){
        this.name = "", this.color = new ae(e), this.near = t, this.far = n;
    }
    clone() {
        return new Br(this.color, this.near, this.far);
    }
    toJSON() {
        return {
            type: "Fog",
            color: this.color.getHex(),
            near: this.near,
            far: this.far
        };
    }
};
Br.prototype.isFog = !0;
var no = class extends Ne {
    constructor(){
        super();
        this.type = "Scene", this.background = null, this.environment = null, this.fog = null, this.overrideMaterial = null, this.autoUpdate = !0, typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe", {
            detail: this
        }));
    }
    copy(e, t) {
        return super.copy(e, t), e.background !== null && (this.background = e.background.clone()), e.environment !== null && (this.environment = e.environment.clone()), e.fog !== null && (this.fog = e.fog.clone()), e.overrideMaterial !== null && (this.overrideMaterial = e.overrideMaterial.clone()), this.autoUpdate = e.autoUpdate, this.matrixAutoUpdate = e.matrixAutoUpdate, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return this.fog !== null && (t.object.fog = this.fog.toJSON()), t;
    }
};
no.prototype.isScene = !0;
var $n = class {
    constructor(e, t){
        this.array = e, this.stride = t, this.count = e !== void 0 ? e.length / t : 0, this.usage = hr, this.updateRange = {
            offset: 0,
            count: -1
        }, this.version = 0, this.uuid = Et();
    }
    onUploadCallback() {}
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
    setUsage(e) {
        return this.usage = e, this;
    }
    copy(e) {
        return this.array = new e.array.constructor(e.array), this.count = e.count, this.stride = e.stride, this.usage = e.usage, this;
    }
    copyAt(e, t, n) {
        e *= this.stride, n *= t.stride;
        for(let i = 0, r = this.stride; i < r; i++)this.array[e + i] = t.array[n + i];
        return this;
    }
    set(e, t = 0) {
        return this.array.set(e, t), this;
    }
    clone(e) {
        e.arrayBuffers === void 0 && (e.arrayBuffers = {}), this.array.buffer._uuid === void 0 && (this.array.buffer._uuid = Et()), e.arrayBuffers[this.array.buffer._uuid] === void 0 && (e.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0).buffer);
        let t = new this.array.constructor(e.arrayBuffers[this.array.buffer._uuid]), n = new this.constructor(t, this.stride);
        return n.setUsage(this.usage), n;
    }
    onUpload(e) {
        return this.onUploadCallback = e, this;
    }
    toJSON(e) {
        return e.arrayBuffers === void 0 && (e.arrayBuffers = {}), this.array.buffer._uuid === void 0 && (this.array.buffer._uuid = Et()), e.arrayBuffers[this.array.buffer._uuid] === void 0 && (e.arrayBuffers[this.array.buffer._uuid] = Array.prototype.slice.call(new Uint32Array(this.array.buffer))), {
            uuid: this.uuid,
            buffer: this.array.buffer._uuid,
            type: this.array.constructor.name,
            stride: this.stride
        };
    }
};
$n.prototype.isInterleavedBuffer = !0;
var Ke = new M, Sn = class {
    constructor(e, t, n, i = !1){
        this.name = "", this.data = e, this.itemSize = t, this.offset = n, this.normalized = i === !0;
    }
    get count() {
        return this.data.count;
    }
    get array() {
        return this.data.array;
    }
    set needsUpdate(e) {
        this.data.needsUpdate = e;
    }
    applyMatrix4(e) {
        for(let t = 0, n = this.data.count; t < n; t++)Ke.x = this.getX(t), Ke.y = this.getY(t), Ke.z = this.getZ(t), Ke.applyMatrix4(e), this.setXYZ(t, Ke.x, Ke.y, Ke.z);
        return this;
    }
    applyNormalMatrix(e) {
        for(let t = 0, n = this.count; t < n; t++)Ke.x = this.getX(t), Ke.y = this.getY(t), Ke.z = this.getZ(t), Ke.applyNormalMatrix(e), this.setXYZ(t, Ke.x, Ke.y, Ke.z);
        return this;
    }
    transformDirection(e) {
        for(let t = 0, n = this.count; t < n; t++)Ke.x = this.getX(t), Ke.y = this.getY(t), Ke.z = this.getZ(t), Ke.transformDirection(e), this.setXYZ(t, Ke.x, Ke.y, Ke.z);
        return this;
    }
    setX(e, t) {
        return this.data.array[e * this.data.stride + this.offset] = t, this;
    }
    setY(e, t) {
        return this.data.array[e * this.data.stride + this.offset + 1] = t, this;
    }
    setZ(e, t) {
        return this.data.array[e * this.data.stride + this.offset + 2] = t, this;
    }
    setW(e, t) {
        return this.data.array[e * this.data.stride + this.offset + 3] = t, this;
    }
    getX(e) {
        return this.data.array[e * this.data.stride + this.offset];
    }
    getY(e) {
        return this.data.array[e * this.data.stride + this.offset + 1];
    }
    getZ(e) {
        return this.data.array[e * this.data.stride + this.offset + 2];
    }
    getW(e) {
        return this.data.array[e * this.data.stride + this.offset + 3];
    }
    setXY(e, t, n) {
        return e = e * this.data.stride + this.offset, this.data.array[e + 0] = t, this.data.array[e + 1] = n, this;
    }
    setXYZ(e, t, n, i) {
        return e = e * this.data.stride + this.offset, this.data.array[e + 0] = t, this.data.array[e + 1] = n, this.data.array[e + 2] = i, this;
    }
    setXYZW(e, t, n, i, r) {
        return e = e * this.data.stride + this.offset, this.data.array[e + 0] = t, this.data.array[e + 1] = n, this.data.array[e + 2] = i, this.data.array[e + 3] = r, this;
    }
    clone(e) {
        if (e === void 0) {
            console.log("THREE.InterleavedBufferAttribute.clone(): Cloning an interlaved buffer attribute will deinterleave buffer data.");
            let t = [];
            for(let n = 0; n < this.count; n++){
                let i = n * this.data.stride + this.offset;
                for(let r = 0; r < this.itemSize; r++)t.push(this.data.array[i + r]);
            }
            return new Ue(new this.array.constructor(t), this.itemSize, this.normalized);
        } else return e.interleavedBuffers === void 0 && (e.interleavedBuffers = {}), e.interleavedBuffers[this.data.uuid] === void 0 && (e.interleavedBuffers[this.data.uuid] = this.data.clone(e)), new Sn(e.interleavedBuffers[this.data.uuid], this.itemSize, this.offset, this.normalized);
    }
    toJSON(e) {
        if (e === void 0) {
            console.log("THREE.InterleavedBufferAttribute.toJSON(): Serializing an interlaved buffer attribute will deinterleave buffer data.");
            let t = [];
            for(let n = 0; n < this.count; n++){
                let i = n * this.data.stride + this.offset;
                for(let r = 0; r < this.itemSize; r++)t.push(this.data.array[i + r]);
            }
            return {
                itemSize: this.itemSize,
                type: this.array.constructor.name,
                array: t,
                normalized: this.normalized
            };
        } else return e.interleavedBuffers === void 0 && (e.interleavedBuffers = {}), e.interleavedBuffers[this.data.uuid] === void 0 && (e.interleavedBuffers[this.data.uuid] = this.data.toJSON(e)), {
            isInterleavedBufferAttribute: !0,
            itemSize: this.itemSize,
            data: this.data.uuid,
            offset: this.offset,
            normalized: this.normalized
        };
    }
};
Sn.prototype.isInterleavedBufferAttribute = !0;
var io = class extends dt {
    constructor(e){
        super();
        this.type = "SpriteMaterial", this.color = new ae(16777215), this.map = null, this.alphaMap = null, this.rotation = 0, this.sizeAttenuation = !0, this.transparent = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.alphaMap = e.alphaMap, this.rotation = e.rotation, this.sizeAttenuation = e.sizeAttenuation, this;
    }
};
io.prototype.isSpriteMaterial = !0;
var gi, Qi = new M, xi = new M, yi = new M, vi = new X, Ki = new X, Mh = new pe, hs = new M, er = new M, us = new M, jl = new X, qo = new X, Ql = new X, ro = class extends Ne {
    constructor(e){
        super();
        if (this.type = "Sprite", gi === void 0) {
            gi = new _e;
            let t = new Float32Array([
                -.5,
                -.5,
                0,
                0,
                0,
                .5,
                -.5,
                0,
                1,
                0,
                .5,
                .5,
                0,
                1,
                1,
                -.5,
                .5,
                0,
                0,
                1
            ]), n = new $n(t, 5);
            gi.setIndex([
                0,
                1,
                2,
                0,
                2,
                3
            ]), gi.setAttribute("position", new Sn(n, 3, 0, !1)), gi.setAttribute("uv", new Sn(n, 2, 3, !1));
        }
        this.geometry = gi, this.material = e !== void 0 ? e : new io, this.center = new X(.5, .5);
    }
    raycast(e, t) {
        e.camera === null && console.error('THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.'), xi.setFromMatrixScale(this.matrixWorld), Mh.copy(e.camera.matrixWorld), this.modelViewMatrix.multiplyMatrices(e.camera.matrixWorldInverse, this.matrixWorld), yi.setFromMatrixPosition(this.modelViewMatrix), e.camera.isPerspectiveCamera && this.material.sizeAttenuation === !1 && xi.multiplyScalar(-yi.z);
        let n = this.material.rotation, i, r;
        n !== 0 && (r = Math.cos(n), i = Math.sin(n));
        let o = this.center;
        ds(hs.set(-.5, -.5, 0), yi, o, xi, i, r), ds(er.set(.5, -.5, 0), yi, o, xi, i, r), ds(us.set(.5, .5, 0), yi, o, xi, i, r), jl.set(0, 0), qo.set(1, 0), Ql.set(1, 1);
        let a = e.ray.intersectTriangle(hs, er, us, !1, Qi);
        if (a === null && (ds(er.set(-.5, .5, 0), yi, o, xi, i, r), qo.set(0, 1), a = e.ray.intersectTriangle(hs, us, er, !1, Qi), a === null)) return;
        let l = e.ray.origin.distanceTo(Qi);
        l < e.near || l > e.far || t.push({
            distance: l,
            point: Qi.clone(),
            uv: nt.getUV(Qi, hs, er, us, jl, qo, Ql, new X),
            face: null,
            object: this
        });
    }
    copy(e) {
        return super.copy(e), e.center !== void 0 && this.center.copy(e.center), this.material = e.material, this;
    }
};
ro.prototype.isSprite = !0;
function ds(s, e, t, n, i, r) {
    vi.subVectors(s, t).addScalar(.5).multiply(n), i !== void 0 ? (Ki.x = r * vi.x - i * vi.y, Ki.y = i * vi.x + r * vi.y) : Ki.copy(vi), s.copy(e), s.x += Ki.x, s.y += Ki.y, s.applyMatrix4(Mh);
}
var fs = new M, Kl = new M, bh = class extends Ne {
    constructor(){
        super();
        this._currentLevel = 0, this.type = "LOD", Object.defineProperties(this, {
            levels: {
                enumerable: !0,
                value: []
            },
            isLOD: {
                value: !0
            }
        }), this.autoUpdate = !0;
    }
    copy(e) {
        super.copy(e, !1);
        let t = e.levels;
        for(let n = 0, i = t.length; n < i; n++){
            let r = t[n];
            this.addLevel(r.object.clone(), r.distance);
        }
        return this.autoUpdate = e.autoUpdate, this;
    }
    addLevel(e, t = 0) {
        t = Math.abs(t);
        let n = this.levels, i;
        for(i = 0; i < n.length && !(t < n[i].distance); i++);
        return n.splice(i, 0, {
            distance: t,
            object: e
        }), this.add(e), this;
    }
    getCurrentLevel() {
        return this._currentLevel;
    }
    getObjectForDistance(e) {
        let t = this.levels;
        if (t.length > 0) {
            let n, i;
            for(n = 1, i = t.length; n < i && !(e < t[n].distance); n++);
            return t[n - 1].object;
        }
        return null;
    }
    raycast(e, t) {
        if (this.levels.length > 0) {
            fs.setFromMatrixPosition(this.matrixWorld);
            let i = e.ray.origin.distanceTo(fs);
            this.getObjectForDistance(i).raycast(e, t);
        }
    }
    update(e) {
        let t = this.levels;
        if (t.length > 1) {
            fs.setFromMatrixPosition(e.matrixWorld), Kl.setFromMatrixPosition(this.matrixWorld);
            let n = fs.distanceTo(Kl) / e.zoom;
            t[0].object.visible = !0;
            let i, r;
            for(i = 1, r = t.length; i < r && n >= t[i].distance; i++)t[i - 1].object.visible = !1, t[i].object.visible = !0;
            for(this._currentLevel = i - 1; i < r; i++)t[i].object.visible = !1;
        }
    }
    toJSON(e) {
        let t = super.toJSON(e);
        this.autoUpdate === !1 && (t.object.autoUpdate = !1), t.object.levels = [];
        let n = this.levels;
        for(let i = 0, r = n.length; i < r; i++){
            let o = n[i];
            t.object.levels.push({
                object: o.object.uuid,
                distance: o.distance
            });
        }
        return t;
    }
}, ec = new M, tc = new Ve, nc = new Ve, Rx = new M, ic = new pe, so = class extends st {
    constructor(e, t){
        super(e, t);
        this.type = "SkinnedMesh", this.bindMode = "attached", this.bindMatrix = new pe, this.bindMatrixInverse = new pe;
    }
    copy(e) {
        return super.copy(e), this.bindMode = e.bindMode, this.bindMatrix.copy(e.bindMatrix), this.bindMatrixInverse.copy(e.bindMatrixInverse), this.skeleton = e.skeleton, this;
    }
    bind(e, t) {
        this.skeleton = e, t === void 0 && (this.updateMatrixWorld(!0), this.skeleton.calculateInverses(), t = this.matrixWorld), this.bindMatrix.copy(t), this.bindMatrixInverse.copy(t).invert();
    }
    pose() {
        this.skeleton.pose();
    }
    normalizeSkinWeights() {
        let e = new Ve, t = this.geometry.attributes.skinWeight;
        for(let n = 0, i = t.count; n < i; n++){
            e.x = t.getX(n), e.y = t.getY(n), e.z = t.getZ(n), e.w = t.getW(n);
            let r = 1 / e.manhattanLength();
            r !== 1 / 0 ? e.multiplyScalar(r) : e.set(1, 0, 0, 0), t.setXYZW(n, e.x, e.y, e.z, e.w);
        }
    }
    updateMatrixWorld(e) {
        super.updateMatrixWorld(e), this.bindMode === "attached" ? this.bindMatrixInverse.copy(this.matrixWorld).invert() : this.bindMode === "detached" ? this.bindMatrixInverse.copy(this.bindMatrix).invert() : console.warn("THREE.SkinnedMesh: Unrecognized bindMode: " + this.bindMode);
    }
    boneTransform(e, t) {
        let n = this.skeleton, i = this.geometry;
        tc.fromBufferAttribute(i.attributes.skinIndex, e), nc.fromBufferAttribute(i.attributes.skinWeight, e), ec.copy(t).applyMatrix4(this.bindMatrix), t.set(0, 0, 0);
        for(let r = 0; r < 4; r++){
            let o = nc.getComponent(r);
            if (o !== 0) {
                let a = tc.getComponent(r);
                ic.multiplyMatrices(n.bones[a].matrixWorld, n.boneInverses[a]), t.addScaledVector(Rx.copy(ec).applyMatrix4(ic), o);
            }
        }
        return t.applyMatrix4(this.bindMatrixInverse);
    }
};
so.prototype.isSkinnedMesh = !0;
var oo = class extends Ne {
    constructor(){
        super();
        this.type = "Bone";
    }
};
oo.prototype.isBone = !0;
var qn = class extends ot {
    constructor(e = null, t = 1, n = 1, i, r, o, a, l, c = rt, h = rt, u, d){
        super(null, o, a, l, c, h, i, r, u, d);
        this.image = {
            data: e,
            width: t,
            height: n
        }, this.magFilter = c, this.minFilter = h, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
};
qn.prototype.isDataTexture = !0;
var rc = new pe, Px = new pe, ao = class {
    constructor(e = [], t = []){
        this.uuid = Et(), this.bones = e.slice(0), this.boneInverses = t, this.boneMatrices = null, this.boneTexture = null, this.boneTextureSize = 0, this.frame = -1, this.init();
    }
    init() {
        let e = this.bones, t = this.boneInverses;
        if (this.boneMatrices = new Float32Array(e.length * 16), t.length === 0) this.calculateInverses();
        else if (e.length !== t.length) {
            console.warn("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones."), this.boneInverses = [];
            for(let n = 0, i = this.bones.length; n < i; n++)this.boneInverses.push(new pe);
        }
    }
    calculateInverses() {
        this.boneInverses.length = 0;
        for(let e = 0, t = this.bones.length; e < t; e++){
            let n = new pe;
            this.bones[e] && n.copy(this.bones[e].matrixWorld).invert(), this.boneInverses.push(n);
        }
    }
    pose() {
        for(let e = 0, t = this.bones.length; e < t; e++){
            let n = this.bones[e];
            n && n.matrixWorld.copy(this.boneInverses[e]).invert();
        }
        for(let e1 = 0, t1 = this.bones.length; e1 < t1; e1++){
            let n1 = this.bones[e1];
            n1 && (n1.parent && n1.parent.isBone ? (n1.matrix.copy(n1.parent.matrixWorld).invert(), n1.matrix.multiply(n1.matrixWorld)) : n1.matrix.copy(n1.matrixWorld), n1.matrix.decompose(n1.position, n1.quaternion, n1.scale));
        }
    }
    update() {
        let e = this.bones, t = this.boneInverses, n = this.boneMatrices, i = this.boneTexture;
        for(let r = 0, o = e.length; r < o; r++){
            let a = e[r] ? e[r].matrixWorld : Px;
            rc.multiplyMatrices(a, t[r]), rc.toArray(n, r * 16);
        }
        i !== null && (i.needsUpdate = !0);
    }
    clone() {
        return new ao(this.bones, this.boneInverses);
    }
    computeBoneTexture() {
        let e = Math.sqrt(this.bones.length * 4);
        e = Xc(e), e = Math.max(e, 4);
        let t = new Float32Array(e * e * 4);
        t.set(this.boneMatrices);
        let n = new qn(t, e, e, ct, nn);
        return n.needsUpdate = !0, this.boneMatrices = t, this.boneTexture = n, this.boneTextureSize = e, this;
    }
    getBoneByName(e) {
        for(let t = 0, n = this.bones.length; t < n; t++){
            let i = this.bones[t];
            if (i.name === e) return i;
        }
    }
    dispose() {
        this.boneTexture !== null && (this.boneTexture.dispose(), this.boneTexture = null);
    }
    fromJSON(e, t) {
        this.uuid = e.uuid;
        for(let n = 0, i = e.bones.length; n < i; n++){
            let r = e.bones[n], o = t[r];
            o === void 0 && (console.warn("THREE.Skeleton: No bone found with UUID:", r), o = new oo), this.bones.push(o), this.boneInverses.push(new pe().fromArray(e.boneInverses[n]));
        }
        return this.init(), this;
    }
    toJSON() {
        let e = {
            metadata: {
                version: 4.5,
                type: "Skeleton",
                generator: "Skeleton.toJSON"
            },
            bones: [],
            boneInverses: []
        };
        e.uuid = this.uuid;
        let t = this.bones, n = this.boneInverses;
        for(let i = 0, r = t.length; i < r; i++){
            let o = t[i];
            e.bones.push(o.uuid);
            let a = n[i];
            e.boneInverses.push(a.toArray());
        }
        return e;
    }
}, Xn = class extends Ue {
    constructor(e, t, n, i = 1){
        typeof n == "number" && (i = n, n = !1, console.error("THREE.InstancedBufferAttribute: The constructor now expects normalized as the third argument."));
        super(e, t, n);
        this.meshPerAttribute = i;
    }
    copy(e) {
        return super.copy(e), this.meshPerAttribute = e.meshPerAttribute, this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.meshPerAttribute = this.meshPerAttribute, e.isInstancedBufferAttribute = !0, e;
    }
};
Xn.prototype.isInstancedBufferAttribute = !0;
var sc = new pe, oc = new pe, ps = [], tr = new st, xa = class extends st {
    constructor(e, t, n){
        super(e, t);
        this.instanceMatrix = new Xn(new Float32Array(n * 16), 16), this.instanceColor = null, this.count = n, this.frustumCulled = !1;
    }
    copy(e) {
        return super.copy(e), this.instanceMatrix.copy(e.instanceMatrix), e.instanceColor !== null && (this.instanceColor = e.instanceColor.clone()), this.count = e.count, this;
    }
    getColorAt(e, t) {
        t.fromArray(this.instanceColor.array, e * 3);
    }
    getMatrixAt(e, t) {
        t.fromArray(this.instanceMatrix.array, e * 16);
    }
    raycast(e, t) {
        let n = this.matrixWorld, i = this.count;
        if (tr.geometry = this.geometry, tr.material = this.material, tr.material !== void 0) for(let r = 0; r < i; r++){
            this.getMatrixAt(r, sc), oc.multiplyMatrices(n, sc), tr.matrixWorld = oc, tr.raycast(e, ps);
            for(let o = 0, a = ps.length; o < a; o++){
                let l = ps[o];
                l.instanceId = r, l.object = this, t.push(l);
            }
            ps.length = 0;
        }
    }
    setColorAt(e, t) {
        this.instanceColor === null && (this.instanceColor = new Xn(new Float32Array(this.instanceMatrix.count * 3), 3)), t.toArray(this.instanceColor.array, e * 3);
    }
    setMatrixAt(e, t) {
        t.toArray(this.instanceMatrix.array, e * 16);
    }
    updateMorphTargets() {}
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
};
xa.prototype.isInstancedMesh = !0;
var ft = class extends dt {
    constructor(e){
        super();
        this.type = "LineBasicMaterial", this.color = new ae(16777215), this.linewidth = 1, this.linecap = "round", this.linejoin = "round", this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.linewidth = e.linewidth, this.linecap = e.linecap, this.linejoin = e.linejoin, this;
    }
};
ft.prototype.isLineBasicMaterial = !0;
var ac = new M, lc = new M, cc = new pe, Xo = new Cn, ms = new An, on = class extends Ne {
    constructor(e = new _e, t = new ft){
        super();
        this.type = "Line", this.geometry = e, this.material = t, this.updateMorphTargets();
    }
    copy(e) {
        return super.copy(e), this.material = e.material, this.geometry = e.geometry, this;
    }
    computeLineDistances() {
        let e = this.geometry;
        if (e.isBufferGeometry) if (e.index === null) {
            let t = e.attributes.position, n = [
                0
            ];
            for(let i = 1, r = t.count; i < r; i++)ac.fromBufferAttribute(t, i - 1), lc.fromBufferAttribute(t, i), n[i] = n[i - 1], n[i] += ac.distanceTo(lc);
            e.setAttribute("lineDistance", new de(n, 1));
        } else console.warn("THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        else e.isGeometry && console.error("THREE.Line.computeLineDistances() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.");
        return this;
    }
    raycast(e, t) {
        let n = this.geometry, i = this.matrixWorld, r = e.params.Line.threshold, o = n.drawRange;
        if (n.boundingSphere === null && n.computeBoundingSphere(), ms.copy(n.boundingSphere), ms.applyMatrix4(i), ms.radius += r, e.ray.intersectsSphere(ms) === !1) return;
        cc.copy(i).invert(), Xo.copy(e.ray).applyMatrix4(cc);
        let a = r / ((this.scale.x + this.scale.y + this.scale.z) / 3), l = a * a, c = new M, h = new M, u = new M, d = new M, f = this.isLineSegments ? 2 : 1;
        if (n.isBufferGeometry) {
            let m = n.index, v = n.attributes.position;
            if (m !== null) {
                let g = Math.max(0, o.start), p = Math.min(m.count, o.start + o.count);
                for(let _ = g, y = p - 1; _ < y; _ += f){
                    let b = m.getX(_), A = m.getX(_ + 1);
                    if (c.fromBufferAttribute(v, b), h.fromBufferAttribute(v, A), Xo.distanceSqToSegment(c, h, d, u) > l) continue;
                    d.applyMatrix4(this.matrixWorld);
                    let I = e.ray.origin.distanceTo(d);
                    I < e.near || I > e.far || t.push({
                        distance: I,
                        point: u.clone().applyMatrix4(this.matrixWorld),
                        index: _,
                        face: null,
                        faceIndex: null,
                        object: this
                    });
                }
            } else {
                let g1 = Math.max(0, o.start), p1 = Math.min(v.count, o.start + o.count);
                for(let _1 = g1, y1 = p1 - 1; _1 < y1; _1 += f){
                    if (c.fromBufferAttribute(v, _1), h.fromBufferAttribute(v, _1 + 1), Xo.distanceSqToSegment(c, h, d, u) > l) continue;
                    d.applyMatrix4(this.matrixWorld);
                    let A1 = e.ray.origin.distanceTo(d);
                    A1 < e.near || A1 > e.far || t.push({
                        distance: A1,
                        point: u.clone().applyMatrix4(this.matrixWorld),
                        index: _1,
                        face: null,
                        faceIndex: null,
                        object: this
                    });
                }
            }
        } else n.isGeometry && console.error("THREE.Line.raycast() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.");
    }
    updateMorphTargets() {
        let e = this.geometry;
        if (e.isBufferGeometry) {
            let t = e.morphAttributes, n = Object.keys(t);
            if (n.length > 0) {
                let i = t[n[0]];
                if (i !== void 0) {
                    this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                    for(let r = 0, o = i.length; r < o; r++){
                        let a = i[r].name || String(r);
                        this.morphTargetInfluences.push(0), this.morphTargetDictionary[a] = r;
                    }
                }
            }
        } else {
            let t1 = e.morphTargets;
            t1 !== void 0 && t1.length > 0 && console.error("THREE.Line.updateMorphTargets() does not support THREE.Geometry. Use THREE.BufferGeometry instead.");
        }
    }
};
on.prototype.isLine = !0;
var hc = new M, uc = new M, wt = class extends on {
    constructor(e, t){
        super(e, t);
        this.type = "LineSegments";
    }
    computeLineDistances() {
        let e = this.geometry;
        if (e.isBufferGeometry) if (e.index === null) {
            let t = e.attributes.position, n = [];
            for(let i = 0, r = t.count; i < r; i += 2)hc.fromBufferAttribute(t, i), uc.fromBufferAttribute(t, i + 1), n[i] = i === 0 ? 0 : n[i - 1], n[i + 1] = n[i] + hc.distanceTo(uc);
            e.setAttribute("lineDistance", new de(n, 1));
        } else console.warn("THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        else e.isGeometry && console.error("THREE.LineSegments.computeLineDistances() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.");
        return this;
    }
};
wt.prototype.isLineSegments = !0;
var ya = class extends on {
    constructor(e, t){
        super(e, t);
        this.type = "LineLoop";
    }
};
ya.prototype.isLineLoop = !0;
var jn = class extends dt {
    constructor(e){
        super();
        this.type = "PointsMaterial", this.color = new ae(16777215), this.map = null, this.alphaMap = null, this.size = 1, this.sizeAttenuation = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.alphaMap = e.alphaMap, this.size = e.size, this.sizeAttenuation = e.sizeAttenuation, this;
    }
};
jn.prototype.isPointsMaterial = !0;
var dc = new pe, sa = new Cn, gs = new An, xs = new M, zr = class extends Ne {
    constructor(e = new _e, t = new jn){
        super();
        this.type = "Points", this.geometry = e, this.material = t, this.updateMorphTargets();
    }
    copy(e) {
        return super.copy(e), this.material = e.material, this.geometry = e.geometry, this;
    }
    raycast(e, t) {
        let n = this.geometry, i = this.matrixWorld, r = e.params.Points.threshold, o = n.drawRange;
        if (n.boundingSphere === null && n.computeBoundingSphere(), gs.copy(n.boundingSphere), gs.applyMatrix4(i), gs.radius += r, e.ray.intersectsSphere(gs) === !1) return;
        dc.copy(i).invert(), sa.copy(e.ray).applyMatrix4(dc);
        let a = r / ((this.scale.x + this.scale.y + this.scale.z) / 3), l = a * a;
        if (n.isBufferGeometry) {
            let c = n.index, u = n.attributes.position;
            if (c !== null) {
                let d = Math.max(0, o.start), f = Math.min(c.count, o.start + o.count);
                for(let m = d, x = f; m < x; m++){
                    let v = c.getX(m);
                    xs.fromBufferAttribute(u, v), fc(xs, v, l, i, e, t, this);
                }
            } else {
                let d1 = Math.max(0, o.start), f1 = Math.min(u.count, o.start + o.count);
                for(let m1 = d1, x1 = f1; m1 < x1; m1++)xs.fromBufferAttribute(u, m1), fc(xs, m1, l, i, e, t, this);
            }
        } else console.error("THREE.Points.raycast() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.");
    }
    updateMorphTargets() {
        let e = this.geometry;
        if (e.isBufferGeometry) {
            let t = e.morphAttributes, n = Object.keys(t);
            if (n.length > 0) {
                let i = t[n[0]];
                if (i !== void 0) {
                    this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                    for(let r = 0, o = i.length; r < o; r++){
                        let a = i[r].name || String(r);
                        this.morphTargetInfluences.push(0), this.morphTargetDictionary[a] = r;
                    }
                }
            }
        } else {
            let t1 = e.morphTargets;
            t1 !== void 0 && t1.length > 0 && console.error("THREE.Points.updateMorphTargets() does not support THREE.Geometry. Use THREE.BufferGeometry instead.");
        }
    }
};
zr.prototype.isPoints = !0;
function fc(s, e, t, n, i, r, o) {
    let a = sa.distanceSqToPoint(s);
    if (a < t) {
        let l = new M;
        sa.closestPointToPoint(s, l), l.applyMatrix4(n);
        let c = i.ray.origin.distanceTo(l);
        if (c < i.near || c > i.far) return;
        r.push({
            distance: c,
            distanceToRay: Math.sqrt(a),
            point: l,
            index: e,
            face: null,
            object: o
        });
    }
}
var wh = class extends ot {
    constructor(e, t, n, i, r, o, a, l, c){
        super(e, t, n, i, r, o, a, l, c);
        this.format = a !== void 0 ? a : Gn, this.minFilter = o !== void 0 ? o : tt, this.magFilter = r !== void 0 ? r : tt, this.generateMipmaps = !1;
        let h = this;
        function u() {
            h.needsUpdate = !0, e.requestVideoFrameCallback(u);
        }
        "requestVideoFrameCallback" in e && e.requestVideoFrameCallback(u);
    }
    clone() {
        return new this.constructor(this.image).copy(this);
    }
    update() {
        let e = this.image;
        "requestVideoFrameCallback" in e === !1 && e.readyState >= e.HAVE_CURRENT_DATA && (this.needsUpdate = !0);
    }
};
wh.prototype.isVideoTexture = !0;
var Sh = class extends ot {
    constructor(e, t, n){
        super({
            width: e,
            height: t
        });
        this.format = n, this.magFilter = rt, this.minFilter = rt, this.generateMipmaps = !1, this.needsUpdate = !0;
    }
};
Sh.prototype.isFramebufferTexture = !0;
var va = class extends ot {
    constructor(e, t, n, i, r, o, a, l, c, h, u, d){
        super(null, o, a, l, c, h, i, r, u, d);
        this.image = {
            width: t,
            height: n
        }, this.mipmaps = e, this.flipY = !1, this.generateMipmaps = !1;
    }
};
va.prototype.isCompressedTexture = !0;
var Th = class extends ot {
    constructor(e, t, n, i, r, o, a, l, c){
        super(e, t, n, i, r, o, a, l, c);
        this.needsUpdate = !0;
    }
};
Th.prototype.isCanvasTexture = !0;
var fr = class extends _e {
    constructor(e = 1, t = 8, n = 0, i = Math.PI * 2){
        super();
        this.type = "CircleGeometry", this.parameters = {
            radius: e,
            segments: t,
            thetaStart: n,
            thetaLength: i
        }, t = Math.max(3, t);
        let r = [], o = [], a = [], l = [], c = new M, h = new X;
        o.push(0, 0, 0), a.push(0, 0, 1), l.push(.5, .5);
        for(let u = 0, d = 3; u <= t; u++, d += 3){
            let f = n + u / t * i;
            c.x = e * Math.cos(f), c.y = e * Math.sin(f), o.push(c.x, c.y, c.z), a.push(0, 0, 1), h.x = (o[d] / e + 1) / 2, h.y = (o[d + 1] / e + 1) / 2, l.push(h.x, h.y);
        }
        for(let u1 = 1; u1 <= t; u1++)r.push(u1, u1 + 1, 0);
        this.setIndex(r), this.setAttribute("position", new de(o, 3)), this.setAttribute("normal", new de(a, 3)), this.setAttribute("uv", new de(l, 2));
    }
    static fromJSON(e) {
        return new fr(e.radius, e.segments, e.thetaStart, e.thetaLength);
    }
}, Jn = class extends _e {
    constructor(e = 1, t = 1, n = 1, i = 8, r = 1, o = !1, a = 0, l = Math.PI * 2){
        super();
        this.type = "CylinderGeometry", this.parameters = {
            radiusTop: e,
            radiusBottom: t,
            height: n,
            radialSegments: i,
            heightSegments: r,
            openEnded: o,
            thetaStart: a,
            thetaLength: l
        };
        let c = this;
        i = Math.floor(i), r = Math.floor(r);
        let h = [], u = [], d = [], f = [], m = 0, x = [], v = n / 2, g = 0;
        p(), o === !1 && (e > 0 && _(!0), t > 0 && _(!1)), this.setIndex(h), this.setAttribute("position", new de(u, 3)), this.setAttribute("normal", new de(d, 3)), this.setAttribute("uv", new de(f, 2));
        function p() {
            let y = new M, b = new M, A = 0, L = (t - e) / n;
            for(let I = 0; I <= r; I++){
                let k = [], B = I / r, P = B * (t - e) + e;
                for(let w = 0; w <= i; w++){
                    let E = w / i, D = E * l + a, U = Math.sin(D), F = Math.cos(D);
                    b.x = P * U, b.y = -B * n + v, b.z = P * F, u.push(b.x, b.y, b.z), y.set(U, L, F).normalize(), d.push(y.x, y.y, y.z), f.push(E, 1 - B), k.push(m++);
                }
                x.push(k);
            }
            for(let I1 = 0; I1 < i; I1++)for(let k1 = 0; k1 < r; k1++){
                let B1 = x[k1][I1], P1 = x[k1 + 1][I1], w1 = x[k1 + 1][I1 + 1], E1 = x[k1][I1 + 1];
                h.push(B1, P1, E1), h.push(P1, w1, E1), A += 6;
            }
            c.addGroup(g, A, 0), g += A;
        }
        function _(y) {
            let b = m, A = new X, L = new M, I = 0, k = y === !0 ? e : t, B = y === !0 ? 1 : -1;
            for(let w = 1; w <= i; w++)u.push(0, v * B, 0), d.push(0, B, 0), f.push(.5, .5), m++;
            let P = m;
            for(let w1 = 0; w1 <= i; w1++){
                let D = w1 / i * l + a, U = Math.cos(D), F = Math.sin(D);
                L.x = k * F, L.y = v * B, L.z = k * U, u.push(L.x, L.y, L.z), d.push(0, B, 0), A.x = U * .5 + .5, A.y = F * .5 * B + .5, f.push(A.x, A.y), m++;
            }
            for(let w2 = 0; w2 < i; w2++){
                let E = b + w2, D1 = P + w2;
                y === !0 ? h.push(D1, D1 + 1, E) : h.push(D1 + 1, D1, E), I += 3;
            }
            c.addGroup(g, I, y === !0 ? 1 : 2), g += I;
        }
    }
    static fromJSON(e) {
        return new Jn(e.radiusTop, e.radiusBottom, e.height, e.radialSegments, e.heightSegments, e.openEnded, e.thetaStart, e.thetaLength);
    }
}, pr = class extends Jn {
    constructor(e = 1, t = 1, n = 8, i = 1, r = !1, o = 0, a = Math.PI * 2){
        super(0, e, t, n, i, r, o, a);
        this.type = "ConeGeometry", this.parameters = {
            radius: e,
            height: t,
            radialSegments: n,
            heightSegments: i,
            openEnded: r,
            thetaStart: o,
            thetaLength: a
        };
    }
    static fromJSON(e) {
        return new pr(e.radius, e.height, e.radialSegments, e.heightSegments, e.openEnded, e.thetaStart, e.thetaLength);
    }
}, an = class extends _e {
    constructor(e = [], t = [], n = 1, i = 0){
        super();
        this.type = "PolyhedronGeometry", this.parameters = {
            vertices: e,
            indices: t,
            radius: n,
            detail: i
        };
        let r = [], o = [];
        a(i), c(n), h(), this.setAttribute("position", new de(r, 3)), this.setAttribute("normal", new de(r.slice(), 3)), this.setAttribute("uv", new de(o, 2)), i === 0 ? this.computeVertexNormals() : this.normalizeNormals();
        function a(p) {
            let _ = new M, y = new M, b = new M;
            for(let A = 0; A < t.length; A += 3)f(t[A + 0], _), f(t[A + 1], y), f(t[A + 2], b), l(_, y, b, p);
        }
        function l(p, _, y, b) {
            let A = b + 1, L = [];
            for(let I = 0; I <= A; I++){
                L[I] = [];
                let k = p.clone().lerp(y, I / A), B = _.clone().lerp(y, I / A), P = A - I;
                for(let w = 0; w <= P; w++)w === 0 && I === A ? L[I][w] = k : L[I][w] = k.clone().lerp(B, w / P);
            }
            for(let I1 = 0; I1 < A; I1++)for(let k1 = 0; k1 < 2 * (A - I1) - 1; k1++){
                let B1 = Math.floor(k1 / 2);
                k1 % 2 === 0 ? (d(L[I1][B1 + 1]), d(L[I1 + 1][B1]), d(L[I1][B1])) : (d(L[I1][B1 + 1]), d(L[I1 + 1][B1 + 1]), d(L[I1 + 1][B1]));
            }
        }
        function c(p) {
            let _ = new M;
            for(let y = 0; y < r.length; y += 3)_.x = r[y + 0], _.y = r[y + 1], _.z = r[y + 2], _.normalize().multiplyScalar(p), r[y + 0] = _.x, r[y + 1] = _.y, r[y + 2] = _.z;
        }
        function h() {
            let p = new M;
            for(let _ = 0; _ < r.length; _ += 3){
                p.x = r[_ + 0], p.y = r[_ + 1], p.z = r[_ + 2];
                let y = v(p) / 2 / Math.PI + .5, b = g(p) / Math.PI + .5;
                o.push(y, 1 - b);
            }
            m(), u();
        }
        function u() {
            for(let p = 0; p < o.length; p += 6){
                let _ = o[p + 0], y = o[p + 2], b = o[p + 4], A = Math.max(_, y, b), L = Math.min(_, y, b);
                A > .9 && L < .1 && (_ < .2 && (o[p + 0] += 1), y < .2 && (o[p + 2] += 1), b < .2 && (o[p + 4] += 1));
            }
        }
        function d(p) {
            r.push(p.x, p.y, p.z);
        }
        function f(p, _) {
            let y = p * 3;
            _.x = e[y + 0], _.y = e[y + 1], _.z = e[y + 2];
        }
        function m() {
            let p = new M, _ = new M, y = new M, b = new M, A = new X, L = new X, I = new X;
            for(let k = 0, B = 0; k < r.length; k += 9, B += 6){
                p.set(r[k + 0], r[k + 1], r[k + 2]), _.set(r[k + 3], r[k + 4], r[k + 5]), y.set(r[k + 6], r[k + 7], r[k + 8]), A.set(o[B + 0], o[B + 1]), L.set(o[B + 2], o[B + 3]), I.set(o[B + 4], o[B + 5]), b.copy(p).add(_).add(y).divideScalar(3);
                let P = v(b);
                x(A, B + 0, p, P), x(L, B + 2, _, P), x(I, B + 4, y, P);
            }
        }
        function x(p, _, y, b) {
            b < 0 && p.x === 1 && (o[_] = p.x - 1), y.x === 0 && y.z === 0 && (o[_] = b / 2 / Math.PI + .5);
        }
        function v(p) {
            return Math.atan2(p.z, -p.x);
        }
        function g(p) {
            return Math.atan2(-p.y, Math.sqrt(p.x * p.x + p.z * p.z));
        }
    }
    static fromJSON(e) {
        return new an(e.vertices, e.indices, e.radius, e.details);
    }
}, mr = class extends an {
    constructor(e = 1, t = 0){
        let n = (1 + Math.sqrt(5)) / 2, i = 1 / n, r = [
            -1,
            -1,
            -1,
            -1,
            -1,
            1,
            -1,
            1,
            -1,
            -1,
            1,
            1,
            1,
            -1,
            -1,
            1,
            -1,
            1,
            1,
            1,
            -1,
            1,
            1,
            1,
            0,
            -i,
            -n,
            0,
            -i,
            n,
            0,
            i,
            -n,
            0,
            i,
            n,
            -i,
            -n,
            0,
            -i,
            n,
            0,
            i,
            -n,
            0,
            i,
            n,
            0,
            -n,
            0,
            -i,
            n,
            0,
            -i,
            -n,
            0,
            i,
            n,
            0,
            i
        ], o = [
            3,
            11,
            7,
            3,
            7,
            15,
            3,
            15,
            13,
            7,
            19,
            17,
            7,
            17,
            6,
            7,
            6,
            15,
            17,
            4,
            8,
            17,
            8,
            10,
            17,
            10,
            6,
            8,
            0,
            16,
            8,
            16,
            2,
            8,
            2,
            10,
            0,
            12,
            1,
            0,
            1,
            18,
            0,
            18,
            16,
            6,
            10,
            2,
            6,
            2,
            13,
            6,
            13,
            15,
            2,
            16,
            18,
            2,
            18,
            3,
            2,
            3,
            13,
            18,
            1,
            9,
            18,
            9,
            11,
            18,
            11,
            3,
            4,
            14,
            12,
            4,
            12,
            0,
            4,
            0,
            8,
            11,
            9,
            5,
            11,
            5,
            19,
            11,
            19,
            7,
            19,
            5,
            14,
            19,
            14,
            4,
            19,
            4,
            17,
            1,
            12,
            14,
            1,
            14,
            5,
            1,
            5,
            9
        ];
        super(r, o, e, t);
        this.type = "DodecahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new mr(e.radius, e.detail);
    }
}, ys = new M, vs = new M, Jo = new M, _s = new nt, _a = class extends _e {
    constructor(e = null, t = 1){
        super();
        if (this.type = "EdgesGeometry", this.parameters = {
            geometry: e,
            thresholdAngle: t
        }, e !== null) {
            let i = Math.pow(10, 4), r = Math.cos(Wn * t), o = e.getIndex(), a = e.getAttribute("position"), l = o ? o.count : a.count, c = [
                0,
                0,
                0
            ], h = [
                "a",
                "b",
                "c"
            ], u = new Array(3), d = {}, f = [];
            for(let m = 0; m < l; m += 3){
                o ? (c[0] = o.getX(m), c[1] = o.getX(m + 1), c[2] = o.getX(m + 2)) : (c[0] = m, c[1] = m + 1, c[2] = m + 2);
                let { a: x , b: v , c: g  } = _s;
                if (x.fromBufferAttribute(a, c[0]), v.fromBufferAttribute(a, c[1]), g.fromBufferAttribute(a, c[2]), _s.getNormal(Jo), u[0] = `${Math.round(x.x * i)},${Math.round(x.y * i)},${Math.round(x.z * i)}`, u[1] = `${Math.round(v.x * i)},${Math.round(v.y * i)},${Math.round(v.z * i)}`, u[2] = `${Math.round(g.x * i)},${Math.round(g.y * i)},${Math.round(g.z * i)}`, !(u[0] === u[1] || u[1] === u[2] || u[2] === u[0])) for(let p = 0; p < 3; p++){
                    let _ = (p + 1) % 3, y = u[p], b = u[_], A = _s[h[p]], L = _s[h[_]], I = `${y}_${b}`, k = `${b}_${y}`;
                    k in d && d[k] ? (Jo.dot(d[k].normal) <= r && (f.push(A.x, A.y, A.z), f.push(L.x, L.y, L.z)), d[k] = null) : I in d || (d[I] = {
                        index0: c[p],
                        index1: c[_],
                        normal: Jo.clone()
                    });
                }
            }
            for(let m1 in d)if (d[m1]) {
                let { index0: x1 , index1: v1  } = d[m1];
                ys.fromBufferAttribute(a, x1), vs.fromBufferAttribute(a, v1), f.push(ys.x, ys.y, ys.z), f.push(vs.x, vs.y, vs.z);
            }
            this.setAttribute("position", new de(f, 3));
        }
    }
}, Ct = class {
    constructor(){
        this.type = "Curve", this.arcLengthDivisions = 200;
    }
    getPoint() {
        return console.warn("THREE.Curve: .getPoint() not implemented."), null;
    }
    getPointAt(e, t) {
        let n = this.getUtoTmapping(e);
        return this.getPoint(n, t);
    }
    getPoints(e = 5) {
        let t = [];
        for(let n = 0; n <= e; n++)t.push(this.getPoint(n / e));
        return t;
    }
    getSpacedPoints(e = 5) {
        let t = [];
        for(let n = 0; n <= e; n++)t.push(this.getPointAt(n / e));
        return t;
    }
    getLength() {
        let e = this.getLengths();
        return e[e.length - 1];
    }
    getLengths(e = this.arcLengthDivisions) {
        if (this.cacheArcLengths && this.cacheArcLengths.length === e + 1 && !this.needsUpdate) return this.cacheArcLengths;
        this.needsUpdate = !1;
        let t = [], n, i = this.getPoint(0), r = 0;
        t.push(0);
        for(let o = 1; o <= e; o++)n = this.getPoint(o / e), r += n.distanceTo(i), t.push(r), i = n;
        return this.cacheArcLengths = t, t;
    }
    updateArcLengths() {
        this.needsUpdate = !0, this.getLengths();
    }
    getUtoTmapping(e, t) {
        let n = this.getLengths(), i = 0, r = n.length, o;
        t ? o = t : o = e * n[r - 1];
        let a = 0, l = r - 1, c;
        for(; a <= l;)if (i = Math.floor(a + (l - a) / 2), c = n[i] - o, c < 0) a = i + 1;
        else if (c > 0) l = i - 1;
        else {
            l = i;
            break;
        }
        if (i = l, n[i] === o) return i / (r - 1);
        let h = n[i], d = n[i + 1] - h, f = (o - h) / d;
        return (i + f) / (r - 1);
    }
    getTangent(e, t) {
        let i = e - 1e-4, r = e + 1e-4;
        i < 0 && (i = 0), r > 1 && (r = 1);
        let o = this.getPoint(i), a = this.getPoint(r), l = t || (o.isVector2 ? new X : new M);
        return l.copy(a).sub(o).normalize(), l;
    }
    getTangentAt(e, t) {
        let n = this.getUtoTmapping(e);
        return this.getTangent(n, t);
    }
    computeFrenetFrames(e, t) {
        let n = new M, i = [], r = [], o = [], a = new M, l = new pe;
        for(let f = 0; f <= e; f++){
            let m = f / e;
            i[f] = this.getTangentAt(m, new M);
        }
        r[0] = new M, o[0] = new M;
        let c = Number.MAX_VALUE, h = Math.abs(i[0].x), u = Math.abs(i[0].y), d = Math.abs(i[0].z);
        h <= c && (c = h, n.set(1, 0, 0)), u <= c && (c = u, n.set(0, 1, 0)), d <= c && n.set(0, 0, 1), a.crossVectors(i[0], n).normalize(), r[0].crossVectors(i[0], a), o[0].crossVectors(i[0], r[0]);
        for(let f1 = 1; f1 <= e; f1++){
            if (r[f1] = r[f1 - 1].clone(), o[f1] = o[f1 - 1].clone(), a.crossVectors(i[f1 - 1], i[f1]), a.length() > Number.EPSILON) {
                a.normalize();
                let m1 = Math.acos(mt(i[f1 - 1].dot(i[f1]), -1, 1));
                r[f1].applyMatrix4(l.makeRotationAxis(a, m1));
            }
            o[f1].crossVectors(i[f1], r[f1]);
        }
        if (t === !0) {
            let f2 = Math.acos(mt(r[0].dot(r[e]), -1, 1));
            f2 /= e, i[0].dot(a.crossVectors(r[0], r[e])) > 0 && (f2 = -f2);
            for(let m2 = 1; m2 <= e; m2++)r[m2].applyMatrix4(l.makeRotationAxis(i[m2], f2 * m2)), o[m2].crossVectors(i[m2], r[m2]);
        }
        return {
            tangents: i,
            normals: r,
            binormals: o
        };
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.arcLengthDivisions = e.arcLengthDivisions, this;
    }
    toJSON() {
        let e = {
            metadata: {
                version: 4.5,
                type: "Curve",
                generator: "Curve.toJSON"
            }
        };
        return e.arcLengthDivisions = this.arcLengthDivisions, e.type = this.type, e;
    }
    fromJSON(e) {
        return this.arcLengthDivisions = e.arcLengthDivisions, this;
    }
}, Ur = class extends Ct {
    constructor(e = 0, t = 0, n = 1, i = 1, r = 0, o = Math.PI * 2, a = !1, l = 0){
        super();
        this.type = "EllipseCurve", this.aX = e, this.aY = t, this.xRadius = n, this.yRadius = i, this.aStartAngle = r, this.aEndAngle = o, this.aClockwise = a, this.aRotation = l;
    }
    getPoint(e, t) {
        let n = t || new X, i = Math.PI * 2, r = this.aEndAngle - this.aStartAngle, o = Math.abs(r) < Number.EPSILON;
        for(; r < 0;)r += i;
        for(; r > i;)r -= i;
        r < Number.EPSILON && (o ? r = 0 : r = i), this.aClockwise === !0 && !o && (r === i ? r = -i : r = r - i);
        let a = this.aStartAngle + e * r, l = this.aX + this.xRadius * Math.cos(a), c = this.aY + this.yRadius * Math.sin(a);
        if (this.aRotation !== 0) {
            let h = Math.cos(this.aRotation), u = Math.sin(this.aRotation), d = l - this.aX, f = c - this.aY;
            l = d * h - f * u + this.aX, c = d * u + f * h + this.aY;
        }
        return n.set(l, c);
    }
    copy(e) {
        return super.copy(e), this.aX = e.aX, this.aY = e.aY, this.xRadius = e.xRadius, this.yRadius = e.yRadius, this.aStartAngle = e.aStartAngle, this.aEndAngle = e.aEndAngle, this.aClockwise = e.aClockwise, this.aRotation = e.aRotation, this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.aX = this.aX, e.aY = this.aY, e.xRadius = this.xRadius, e.yRadius = this.yRadius, e.aStartAngle = this.aStartAngle, e.aEndAngle = this.aEndAngle, e.aClockwise = this.aClockwise, e.aRotation = this.aRotation, e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.aX = e.aX, this.aY = e.aY, this.xRadius = e.xRadius, this.yRadius = e.yRadius, this.aStartAngle = e.aStartAngle, this.aEndAngle = e.aEndAngle, this.aClockwise = e.aClockwise, this.aRotation = e.aRotation, this;
    }
};
Ur.prototype.isEllipseCurve = !0;
var Ma = class extends Ur {
    constructor(e, t, n, i, r, o){
        super(e, t, n, n, i, r, o);
        this.type = "ArcCurve";
    }
};
Ma.prototype.isArcCurve = !0;
function ba() {
    let s = 0, e = 0, t = 0, n = 0;
    function i(r, o, a, l) {
        s = r, e = a, t = -3 * r + 3 * o - 2 * a - l, n = 2 * r - 2 * o + a + l;
    }
    return {
        initCatmullRom: function(r, o, a, l, c) {
            i(o, a, c * (a - r), c * (l - o));
        },
        initNonuniformCatmullRom: function(r, o, a, l, c, h, u) {
            let d = (o - r) / c - (a - r) / (c + h) + (a - o) / h, f = (a - o) / h - (l - o) / (h + u) + (l - a) / u;
            d *= h, f *= h, i(o, a, d, f);
        },
        calc: function(r) {
            let o = r * r, a = o * r;
            return s + e * r + t * o + n * a;
        }
    };
}
var Ms = new M, Yo = new ba, Zo = new ba, $o = new ba, wa = class extends Ct {
    constructor(e = [], t = !1, n = "centripetal", i = .5){
        super();
        this.type = "CatmullRomCurve3", this.points = e, this.closed = t, this.curveType = n, this.tension = i;
    }
    getPoint(e, t = new M) {
        let n = t, i = this.points, r = i.length, o = (r - (this.closed ? 0 : 1)) * e, a = Math.floor(o), l = o - a;
        this.closed ? a += a > 0 ? 0 : (Math.floor(Math.abs(a) / r) + 1) * r : l === 0 && a === r - 1 && (a = r - 2, l = 1);
        let c, h;
        this.closed || a > 0 ? c = i[(a - 1) % r] : (Ms.subVectors(i[0], i[1]).add(i[0]), c = Ms);
        let u = i[a % r], d = i[(a + 1) % r];
        if (this.closed || a + 2 < r ? h = i[(a + 2) % r] : (Ms.subVectors(i[r - 1], i[r - 2]).add(i[r - 1]), h = Ms), this.curveType === "centripetal" || this.curveType === "chordal") {
            let f = this.curveType === "chordal" ? .5 : .25, m = Math.pow(c.distanceToSquared(u), f), x = Math.pow(u.distanceToSquared(d), f), v = Math.pow(d.distanceToSquared(h), f);
            x < 1e-4 && (x = 1), m < 1e-4 && (m = x), v < 1e-4 && (v = x), Yo.initNonuniformCatmullRom(c.x, u.x, d.x, h.x, m, x, v), Zo.initNonuniformCatmullRom(c.y, u.y, d.y, h.y, m, x, v), $o.initNonuniformCatmullRom(c.z, u.z, d.z, h.z, m, x, v);
        } else this.curveType === "catmullrom" && (Yo.initCatmullRom(c.x, u.x, d.x, h.x, this.tension), Zo.initCatmullRom(c.y, u.y, d.y, h.y, this.tension), $o.initCatmullRom(c.z, u.z, d.z, h.z, this.tension));
        return n.set(Yo.calc(l), Zo.calc(l), $o.calc(l)), n;
    }
    copy(e) {
        super.copy(e), this.points = [];
        for(let t = 0, n = e.points.length; t < n; t++){
            let i = e.points[t];
            this.points.push(i.clone());
        }
        return this.closed = e.closed, this.curveType = e.curveType, this.tension = e.tension, this;
    }
    toJSON() {
        let e = super.toJSON();
        e.points = [];
        for(let t = 0, n = this.points.length; t < n; t++){
            let i = this.points[t];
            e.points.push(i.toArray());
        }
        return e.closed = this.closed, e.curveType = this.curveType, e.tension = this.tension, e;
    }
    fromJSON(e) {
        super.fromJSON(e), this.points = [];
        for(let t = 0, n = e.points.length; t < n; t++){
            let i = e.points[t];
            this.points.push(new M().fromArray(i));
        }
        return this.closed = e.closed, this.curveType = e.curveType, this.tension = e.tension, this;
    }
};
wa.prototype.isCatmullRomCurve3 = !0;
function pc(s, e, t, n, i) {
    let r = (n - e) * .5, o = (i - t) * .5, a = s * s, l = s * a;
    return (2 * t - 2 * n + r + o) * l + (-3 * t + 3 * n - 2 * r - o) * a + r * s + t;
}
function Ix(s, e) {
    let t = 1 - s;
    return t * t * e;
}
function Dx(s, e) {
    return 2 * (1 - s) * s * e;
}
function Fx(s, e) {
    return s * s * e;
}
function ar(s, e, t, n) {
    return Ix(s, e) + Dx(s, t) + Fx(s, n);
}
function Nx(s, e) {
    let t = 1 - s;
    return t * t * t * e;
}
function Bx(s, e) {
    let t = 1 - s;
    return 3 * t * t * s * e;
}
function zx(s, e) {
    return 3 * (1 - s) * s * s * e;
}
function Ux(s, e) {
    return s * s * s * e;
}
function lr(s, e, t, n, i) {
    return Nx(s, e) + Bx(s, t) + zx(s, n) + Ux(s, i);
}
var lo = class extends Ct {
    constructor(e = new X, t = new X, n = new X, i = new X){
        super();
        this.type = "CubicBezierCurve", this.v0 = e, this.v1 = t, this.v2 = n, this.v3 = i;
    }
    getPoint(e, t = new X) {
        let n = t, i = this.v0, r = this.v1, o = this.v2, a = this.v3;
        return n.set(lr(e, i.x, r.x, o.x, a.x), lr(e, i.y, r.y, o.y, a.y)), n;
    }
    copy(e) {
        return super.copy(e), this.v0.copy(e.v0), this.v1.copy(e.v1), this.v2.copy(e.v2), this.v3.copy(e.v3), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.v0 = this.v0.toArray(), e.v1 = this.v1.toArray(), e.v2 = this.v2.toArray(), e.v3 = this.v3.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.v0.fromArray(e.v0), this.v1.fromArray(e.v1), this.v2.fromArray(e.v2), this.v3.fromArray(e.v3), this;
    }
};
lo.prototype.isCubicBezierCurve = !0;
var Sa = class extends Ct {
    constructor(e = new M, t = new M, n = new M, i = new M){
        super();
        this.type = "CubicBezierCurve3", this.v0 = e, this.v1 = t, this.v2 = n, this.v3 = i;
    }
    getPoint(e, t = new M) {
        let n = t, i = this.v0, r = this.v1, o = this.v2, a = this.v3;
        return n.set(lr(e, i.x, r.x, o.x, a.x), lr(e, i.y, r.y, o.y, a.y), lr(e, i.z, r.z, o.z, a.z)), n;
    }
    copy(e) {
        return super.copy(e), this.v0.copy(e.v0), this.v1.copy(e.v1), this.v2.copy(e.v2), this.v3.copy(e.v3), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.v0 = this.v0.toArray(), e.v1 = this.v1.toArray(), e.v2 = this.v2.toArray(), e.v3 = this.v3.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.v0.fromArray(e.v0), this.v1.fromArray(e.v1), this.v2.fromArray(e.v2), this.v3.fromArray(e.v3), this;
    }
};
Sa.prototype.isCubicBezierCurve3 = !0;
var Or = class extends Ct {
    constructor(e = new X, t = new X){
        super();
        this.type = "LineCurve", this.v1 = e, this.v2 = t;
    }
    getPoint(e, t = new X) {
        let n = t;
        return e === 1 ? n.copy(this.v2) : (n.copy(this.v2).sub(this.v1), n.multiplyScalar(e).add(this.v1)), n;
    }
    getPointAt(e, t) {
        return this.getPoint(e, t);
    }
    getTangent(e, t) {
        let n = t || new X;
        return n.copy(this.v2).sub(this.v1).normalize(), n;
    }
    copy(e) {
        return super.copy(e), this.v1.copy(e.v1), this.v2.copy(e.v2), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.v1 = this.v1.toArray(), e.v2 = this.v2.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.v1.fromArray(e.v1), this.v2.fromArray(e.v2), this;
    }
};
Or.prototype.isLineCurve = !0;
var Eh = class extends Ct {
    constructor(e = new M, t = new M){
        super();
        this.type = "LineCurve3", this.isLineCurve3 = !0, this.v1 = e, this.v2 = t;
    }
    getPoint(e, t = new M) {
        let n = t;
        return e === 1 ? n.copy(this.v2) : (n.copy(this.v2).sub(this.v1), n.multiplyScalar(e).add(this.v1)), n;
    }
    getPointAt(e, t) {
        return this.getPoint(e, t);
    }
    copy(e) {
        return super.copy(e), this.v1.copy(e.v1), this.v2.copy(e.v2), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.v1 = this.v1.toArray(), e.v2 = this.v2.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.v1.fromArray(e.v1), this.v2.fromArray(e.v2), this;
    }
}, co = class extends Ct {
    constructor(e = new X, t = new X, n = new X){
        super();
        this.type = "QuadraticBezierCurve", this.v0 = e, this.v1 = t, this.v2 = n;
    }
    getPoint(e, t = new X) {
        let n = t, i = this.v0, r = this.v1, o = this.v2;
        return n.set(ar(e, i.x, r.x, o.x), ar(e, i.y, r.y, o.y)), n;
    }
    copy(e) {
        return super.copy(e), this.v0.copy(e.v0), this.v1.copy(e.v1), this.v2.copy(e.v2), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.v0 = this.v0.toArray(), e.v1 = this.v1.toArray(), e.v2 = this.v2.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.v0.fromArray(e.v0), this.v1.fromArray(e.v1), this.v2.fromArray(e.v2), this;
    }
};
co.prototype.isQuadraticBezierCurve = !0;
var ho = class extends Ct {
    constructor(e = new M, t = new M, n = new M){
        super();
        this.type = "QuadraticBezierCurve3", this.v0 = e, this.v1 = t, this.v2 = n;
    }
    getPoint(e, t = new M) {
        let n = t, i = this.v0, r = this.v1, o = this.v2;
        return n.set(ar(e, i.x, r.x, o.x), ar(e, i.y, r.y, o.y), ar(e, i.z, r.z, o.z)), n;
    }
    copy(e) {
        return super.copy(e), this.v0.copy(e.v0), this.v1.copy(e.v1), this.v2.copy(e.v2), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.v0 = this.v0.toArray(), e.v1 = this.v1.toArray(), e.v2 = this.v2.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.v0.fromArray(e.v0), this.v1.fromArray(e.v1), this.v2.fromArray(e.v2), this;
    }
};
ho.prototype.isQuadraticBezierCurve3 = !0;
var uo = class extends Ct {
    constructor(e = []){
        super();
        this.type = "SplineCurve", this.points = e;
    }
    getPoint(e, t = new X) {
        let n = t, i = this.points, r = (i.length - 1) * e, o = Math.floor(r), a = r - o, l = i[o === 0 ? o : o - 1], c = i[o], h = i[o > i.length - 2 ? i.length - 1 : o + 1], u = i[o > i.length - 3 ? i.length - 1 : o + 2];
        return n.set(pc(a, l.x, c.x, h.x, u.x), pc(a, l.y, c.y, h.y, u.y)), n;
    }
    copy(e) {
        super.copy(e), this.points = [];
        for(let t = 0, n = e.points.length; t < n; t++){
            let i = e.points[t];
            this.points.push(i.clone());
        }
        return this;
    }
    toJSON() {
        let e = super.toJSON();
        e.points = [];
        for(let t = 0, n = this.points.length; t < n; t++){
            let i = this.points[t];
            e.points.push(i.toArray());
        }
        return e;
    }
    fromJSON(e) {
        super.fromJSON(e), this.points = [];
        for(let t = 0, n = e.points.length; t < n; t++){
            let i = e.points[t];
            this.points.push(new X().fromArray(i));
        }
        return this;
    }
};
uo.prototype.isSplineCurve = !0;
var Ta = Object.freeze({
    __proto__: null,
    ArcCurve: Ma,
    CatmullRomCurve3: wa,
    CubicBezierCurve: lo,
    CubicBezierCurve3: Sa,
    EllipseCurve: Ur,
    LineCurve: Or,
    LineCurve3: Eh,
    QuadraticBezierCurve: co,
    QuadraticBezierCurve3: ho,
    SplineCurve: uo
}), Ah = class extends Ct {
    constructor(){
        super();
        this.type = "CurvePath", this.curves = [], this.autoClose = !1;
    }
    add(e) {
        this.curves.push(e);
    }
    closePath() {
        let e = this.curves[0].getPoint(0), t = this.curves[this.curves.length - 1].getPoint(1);
        e.equals(t) || this.curves.push(new Or(t, e));
    }
    getPoint(e, t) {
        let n = e * this.getLength(), i = this.getCurveLengths(), r = 0;
        for(; r < i.length;){
            if (i[r] >= n) {
                let o = i[r] - n, a = this.curves[r], l = a.getLength(), c = l === 0 ? 0 : 1 - o / l;
                return a.getPointAt(c, t);
            }
            r++;
        }
        return null;
    }
    getLength() {
        let e = this.getCurveLengths();
        return e[e.length - 1];
    }
    updateArcLengths() {
        this.needsUpdate = !0, this.cacheLengths = null, this.getCurveLengths();
    }
    getCurveLengths() {
        if (this.cacheLengths && this.cacheLengths.length === this.curves.length) return this.cacheLengths;
        let e = [], t = 0;
        for(let n = 0, i = this.curves.length; n < i; n++)t += this.curves[n].getLength(), e.push(t);
        return this.cacheLengths = e, e;
    }
    getSpacedPoints(e = 40) {
        let t = [];
        for(let n = 0; n <= e; n++)t.push(this.getPoint(n / e));
        return this.autoClose && t.push(t[0]), t;
    }
    getPoints(e = 12) {
        let t = [], n;
        for(let i = 0, r = this.curves; i < r.length; i++){
            let o = r[i], a = o && o.isEllipseCurve ? e * 2 : o && (o.isLineCurve || o.isLineCurve3) ? 1 : o && o.isSplineCurve ? e * o.points.length : e, l = o.getPoints(a);
            for(let c = 0; c < l.length; c++){
                let h = l[c];
                n && n.equals(h) || (t.push(h), n = h);
            }
        }
        return this.autoClose && t.length > 1 && !t[t.length - 1].equals(t[0]) && t.push(t[0]), t;
    }
    copy(e) {
        super.copy(e), this.curves = [];
        for(let t = 0, n = e.curves.length; t < n; t++){
            let i = e.curves[t];
            this.curves.push(i.clone());
        }
        return this.autoClose = e.autoClose, this;
    }
    toJSON() {
        let e = super.toJSON();
        e.autoClose = this.autoClose, e.curves = [];
        for(let t = 0, n = this.curves.length; t < n; t++){
            let i = this.curves[t];
            e.curves.push(i.toJSON());
        }
        return e;
    }
    fromJSON(e) {
        super.fromJSON(e), this.autoClose = e.autoClose, this.curves = [];
        for(let t = 0, n = e.curves.length; t < n; t++){
            let i = e.curves[t];
            this.curves.push(new Ta[i.type]().fromJSON(i));
        }
        return this;
    }
}, gr = class extends Ah {
    constructor(e){
        super();
        this.type = "Path", this.currentPoint = new X, e && this.setFromPoints(e);
    }
    setFromPoints(e) {
        this.moveTo(e[0].x, e[0].y);
        for(let t = 1, n = e.length; t < n; t++)this.lineTo(e[t].x, e[t].y);
        return this;
    }
    moveTo(e, t) {
        return this.currentPoint.set(e, t), this;
    }
    lineTo(e, t) {
        let n = new Or(this.currentPoint.clone(), new X(e, t));
        return this.curves.push(n), this.currentPoint.set(e, t), this;
    }
    quadraticCurveTo(e, t, n, i) {
        let r = new co(this.currentPoint.clone(), new X(e, t), new X(n, i));
        return this.curves.push(r), this.currentPoint.set(n, i), this;
    }
    bezierCurveTo(e, t, n, i, r, o) {
        let a = new lo(this.currentPoint.clone(), new X(e, t), new X(n, i), new X(r, o));
        return this.curves.push(a), this.currentPoint.set(r, o), this;
    }
    splineThru(e) {
        let t = [
            this.currentPoint.clone()
        ].concat(e), n = new uo(t);
        return this.curves.push(n), this.currentPoint.copy(e[e.length - 1]), this;
    }
    arc(e, t, n, i, r, o) {
        let a = this.currentPoint.x, l = this.currentPoint.y;
        return this.absarc(e + a, t + l, n, i, r, o), this;
    }
    absarc(e, t, n, i, r, o) {
        return this.absellipse(e, t, n, n, i, r, o), this;
    }
    ellipse(e, t, n, i, r, o, a, l) {
        let c = this.currentPoint.x, h = this.currentPoint.y;
        return this.absellipse(e + c, t + h, n, i, r, o, a, l), this;
    }
    absellipse(e, t, n, i, r, o, a, l) {
        let c = new Ur(e, t, n, i, r, o, a, l);
        if (this.curves.length > 0) {
            let u = c.getPoint(0);
            u.equals(this.currentPoint) || this.lineTo(u.x, u.y);
        }
        this.curves.push(c);
        let h = c.getPoint(1);
        return this.currentPoint.copy(h), this;
    }
    copy(e) {
        return super.copy(e), this.currentPoint.copy(e.currentPoint), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.currentPoint = this.currentPoint.toArray(), e;
    }
    fromJSON(e) {
        return super.fromJSON(e), this.currentPoint.fromArray(e.currentPoint), this;
    }
}, Xt = class extends gr {
    constructor(e){
        super(e);
        this.uuid = Et(), this.type = "Shape", this.holes = [];
    }
    getPointsHoles(e) {
        let t = [];
        for(let n = 0, i = this.holes.length; n < i; n++)t[n] = this.holes[n].getPoints(e);
        return t;
    }
    extractPoints(e) {
        return {
            shape: this.getPoints(e),
            holes: this.getPointsHoles(e)
        };
    }
    copy(e) {
        super.copy(e), this.holes = [];
        for(let t = 0, n = e.holes.length; t < n; t++){
            let i = e.holes[t];
            this.holes.push(i.clone());
        }
        return this;
    }
    toJSON() {
        let e = super.toJSON();
        e.uuid = this.uuid, e.holes = [];
        for(let t = 0, n = this.holes.length; t < n; t++){
            let i = this.holes[t];
            e.holes.push(i.toJSON());
        }
        return e;
    }
    fromJSON(e) {
        super.fromJSON(e), this.uuid = e.uuid, this.holes = [];
        for(let t = 0, n = e.holes.length; t < n; t++){
            let i = e.holes[t];
            this.holes.push(new gr().fromJSON(i));
        }
        return this;
    }
}, Ox = {
    triangulate: function(s, e, t = 2) {
        let n = e && e.length, i = n ? e[0] * t : s.length, r = Ch(s, 0, i, t, !0), o = [];
        if (!r || r.next === r.prev) return o;
        let a, l, c, h, u, d, f;
        if (n && (r = Wx(s, e, r, t)), s.length > 80 * t) {
            a = c = s[0], l = h = s[1];
            for(let m = t; m < i; m += t)u = s[m], d = s[m + 1], u < a && (a = u), d < l && (l = d), u > c && (c = u), d > h && (h = d);
            f = Math.max(c - a, h - l), f = f !== 0 ? 1 / f : 0;
        }
        return xr(r, o, t, a, l, f), o;
    }
};
function Ch(s, e, t, n, i) {
    let r, o;
    if (i === ty(s, e, t, n) > 0) for(r = e; r < t; r += n)o = mc(r, s[r], s[r + 1], o);
    else for(r = t - n; r >= e; r -= n)o = mc(r, s[r], s[r + 1], o);
    return o && fo(o, o.next) && (vr(o), o = o.next), o;
}
function Tn(s, e) {
    if (!s) return s;
    e || (e = s);
    let t = s, n;
    do if (n = !1, !t.steiner && (fo(t, t.next) || $e(t.prev, t, t.next) === 0)) {
        if (vr(t), t = e = t.prev, t === t.next) break;
        n = !0;
    } else t = t.next;
    while (n || t !== e)
    return e;
}
function xr(s, e, t, n, i, r, o) {
    if (!s) return;
    !o && r && Zx(s, n, i, r);
    let a = s, l, c;
    for(; s.prev !== s.next;){
        if (l = s.prev, c = s.next, r ? kx(s, n, i, r) : Hx(s)) {
            e.push(l.i / t), e.push(s.i / t), e.push(c.i / t), vr(s), s = c.next, a = c.next;
            continue;
        }
        if (s = c, s === a) {
            o ? o === 1 ? (s = Gx(Tn(s), e, t), xr(s, e, t, n, i, r, 2)) : o === 2 && Vx(s, e, t, n, i, r) : xr(Tn(s), e, t, n, i, r, 1);
            break;
        }
    }
}
function Hx(s) {
    let e = s.prev, t = s, n = s.next;
    if ($e(e, t, n) >= 0) return !1;
    let i = s.next.next;
    for(; i !== s.prev;){
        if (Si(e.x, e.y, t.x, t.y, n.x, n.y, i.x, i.y) && $e(i.prev, i, i.next) >= 0) return !1;
        i = i.next;
    }
    return !0;
}
function kx(s, e, t, n) {
    let i = s.prev, r = s, o = s.next;
    if ($e(i, r, o) >= 0) return !1;
    let a = i.x < r.x ? i.x < o.x ? i.x : o.x : r.x < o.x ? r.x : o.x, l = i.y < r.y ? i.y < o.y ? i.y : o.y : r.y < o.y ? r.y : o.y, c = i.x > r.x ? i.x > o.x ? i.x : o.x : r.x > o.x ? r.x : o.x, h = i.y > r.y ? i.y > o.y ? i.y : o.y : r.y > o.y ? r.y : o.y, u = oa(a, l, e, t, n), d = oa(c, h, e, t, n), f = s.prevZ, m = s.nextZ;
    for(; f && f.z >= u && m && m.z <= d;){
        if (f !== s.prev && f !== s.next && Si(i.x, i.y, r.x, r.y, o.x, o.y, f.x, f.y) && $e(f.prev, f, f.next) >= 0 || (f = f.prevZ, m !== s.prev && m !== s.next && Si(i.x, i.y, r.x, r.y, o.x, o.y, m.x, m.y) && $e(m.prev, m, m.next) >= 0)) return !1;
        m = m.nextZ;
    }
    for(; f && f.z >= u;){
        if (f !== s.prev && f !== s.next && Si(i.x, i.y, r.x, r.y, o.x, o.y, f.x, f.y) && $e(f.prev, f, f.next) >= 0) return !1;
        f = f.prevZ;
    }
    for(; m && m.z <= d;){
        if (m !== s.prev && m !== s.next && Si(i.x, i.y, r.x, r.y, o.x, o.y, m.x, m.y) && $e(m.prev, m, m.next) >= 0) return !1;
        m = m.nextZ;
    }
    return !0;
}
function Gx(s, e, t) {
    let n = s;
    do {
        let i = n.prev, r = n.next.next;
        !fo(i, r) && Lh(i, n, n.next, r) && yr(i, r) && yr(r, i) && (e.push(i.i / t), e.push(n.i / t), e.push(r.i / t), vr(n), vr(n.next), n = s = r), n = n.next;
    }while (n !== s)
    return Tn(n);
}
function Vx(s, e, t, n, i, r) {
    let o = s;
    do {
        let a = o.next.next;
        for(; a !== o.prev;){
            if (o.i !== a.i && Qx(o, a)) {
                let l = Rh(o, a);
                o = Tn(o, o.next), l = Tn(l, l.next), xr(o, e, t, n, i, r), xr(l, e, t, n, i, r);
                return;
            }
            a = a.next;
        }
        o = o.next;
    }while (o !== s)
}
function Wx(s, e, t, n) {
    let i = [], r, o, a, l, c;
    for(r = 0, o = e.length; r < o; r++)a = e[r] * n, l = r < o - 1 ? e[r + 1] * n : s.length, c = Ch(s, a, l, n, !1), c === c.next && (c.steiner = !0), i.push(jx(c));
    for(i.sort(qx), r = 0; r < i.length; r++)Xx(i[r], t), t = Tn(t, t.next);
    return t;
}
function qx(s, e) {
    return s.x - e.x;
}
function Xx(s, e) {
    if (e = Jx(s, e), e) {
        let t = Rh(e, s);
        Tn(e, e.next), Tn(t, t.next);
    }
}
function Jx(s, e) {
    let t = e, n = s.x, i = s.y, r = -1 / 0, o;
    do {
        if (i <= t.y && i >= t.next.y && t.next.y !== t.y) {
            let d = t.x + (i - t.y) * (t.next.x - t.x) / (t.next.y - t.y);
            if (d <= n && d > r) {
                if (r = d, d === n) {
                    if (i === t.y) return t;
                    if (i === t.next.y) return t.next;
                }
                o = t.x < t.next.x ? t : t.next;
            }
        }
        t = t.next;
    }while (t !== e)
    if (!o) return null;
    if (n === r) return o;
    let a = o, l = o.x, c = o.y, h = 1 / 0, u;
    t = o;
    do n >= t.x && t.x >= l && n !== t.x && Si(i < c ? n : r, i, l, c, i < c ? r : n, i, t.x, t.y) && (u = Math.abs(i - t.y) / (n - t.x), yr(t, s) && (u < h || u === h && (t.x > o.x || t.x === o.x && Yx(o, t))) && (o = t, h = u)), t = t.next;
    while (t !== a)
    return o;
}
function Yx(s, e) {
    return $e(s.prev, s, e.prev) < 0 && $e(e.next, s, s.next) < 0;
}
function Zx(s, e, t, n) {
    let i = s;
    do i.z === null && (i.z = oa(i.x, i.y, e, t, n)), i.prevZ = i.prev, i.nextZ = i.next, i = i.next;
    while (i !== s)
    i.prevZ.nextZ = null, i.prevZ = null, $x(i);
}
function $x(s) {
    let e, t, n, i, r, o, a, l, c = 1;
    do {
        for(t = s, s = null, r = null, o = 0; t;){
            for(o++, n = t, a = 0, e = 0; e < c && (a++, n = n.nextZ, !!n); e++);
            for(l = c; a > 0 || l > 0 && n;)a !== 0 && (l === 0 || !n || t.z <= n.z) ? (i = t, t = t.nextZ, a--) : (i = n, n = n.nextZ, l--), r ? r.nextZ = i : s = i, i.prevZ = r, r = i;
            t = n;
        }
        r.nextZ = null, c *= 2;
    }while (o > 1)
    return s;
}
function oa(s, e, t, n, i) {
    return s = 32767 * (s - t) * i, e = 32767 * (e - n) * i, s = (s | s << 8) & 16711935, s = (s | s << 4) & 252645135, s = (s | s << 2) & 858993459, s = (s | s << 1) & 1431655765, e = (e | e << 8) & 16711935, e = (e | e << 4) & 252645135, e = (e | e << 2) & 858993459, e = (e | e << 1) & 1431655765, s | e << 1;
}
function jx(s) {
    let e = s, t = s;
    do (e.x < t.x || e.x === t.x && e.y < t.y) && (t = e), e = e.next;
    while (e !== s)
    return t;
}
function Si(s, e, t, n, i, r, o, a) {
    return (i - o) * (e - a) - (s - o) * (r - a) >= 0 && (s - o) * (n - a) - (t - o) * (e - a) >= 0 && (t - o) * (r - a) - (i - o) * (n - a) >= 0;
}
function Qx(s, e) {
    return s.next.i !== e.i && s.prev.i !== e.i && !Kx(s, e) && (yr(s, e) && yr(e, s) && ey(s, e) && ($e(s.prev, s, e.prev) || $e(s, e.prev, e)) || fo(s, e) && $e(s.prev, s, s.next) > 0 && $e(e.prev, e, e.next) > 0);
}
function $e(s, e, t) {
    return (e.y - s.y) * (t.x - e.x) - (e.x - s.x) * (t.y - e.y);
}
function fo(s, e) {
    return s.x === e.x && s.y === e.y;
}
function Lh(s, e, t, n) {
    let i = ws($e(s, e, t)), r = ws($e(s, e, n)), o = ws($e(t, n, s)), a = ws($e(t, n, e));
    return !!(i !== r && o !== a || i === 0 && bs(s, t, e) || r === 0 && bs(s, n, e) || o === 0 && bs(t, s, n) || a === 0 && bs(t, e, n));
}
function bs(s, e, t) {
    return e.x <= Math.max(s.x, t.x) && e.x >= Math.min(s.x, t.x) && e.y <= Math.max(s.y, t.y) && e.y >= Math.min(s.y, t.y);
}
function ws(s) {
    return s > 0 ? 1 : s < 0 ? -1 : 0;
}
function Kx(s, e) {
    let t = s;
    do {
        if (t.i !== s.i && t.next.i !== s.i && t.i !== e.i && t.next.i !== e.i && Lh(t, t.next, s, e)) return !0;
        t = t.next;
    }while (t !== s)
    return !1;
}
function yr(s, e) {
    return $e(s.prev, s, s.next) < 0 ? $e(s, e, s.next) >= 0 && $e(s, s.prev, e) >= 0 : $e(s, e, s.prev) < 0 || $e(s, s.next, e) < 0;
}
function ey(s, e) {
    let t = s, n = !1, i = (s.x + e.x) / 2, r = (s.y + e.y) / 2;
    do t.y > r != t.next.y > r && t.next.y !== t.y && i < (t.next.x - t.x) * (r - t.y) / (t.next.y - t.y) + t.x && (n = !n), t = t.next;
    while (t !== s)
    return n;
}
function Rh(s, e) {
    let t = new aa(s.i, s.x, s.y), n = new aa(e.i, e.x, e.y), i = s.next, r = e.prev;
    return s.next = e, e.prev = s, t.next = i, i.prev = t, n.next = t, t.prev = n, r.next = n, n.prev = r, n;
}
function mc(s, e, t, n) {
    let i = new aa(s, e, t);
    return n ? (i.next = n.next, i.prev = n, n.next.prev = i, n.next = i) : (i.prev = i, i.next = i), i;
}
function vr(s) {
    s.next.prev = s.prev, s.prev.next = s.next, s.prevZ && (s.prevZ.nextZ = s.nextZ), s.nextZ && (s.nextZ.prevZ = s.prevZ);
}
function aa(s, e, t) {
    this.i = s, this.x = e, this.y = t, this.prev = null, this.next = null, this.z = null, this.prevZ = null, this.nextZ = null, this.steiner = !1;
}
function ty(s, e, t, n) {
    let i = 0;
    for(let r = e, o = t - n; r < t; r += n)i += (s[o] - s[r]) * (s[r + 1] + s[o + 1]), o = r;
    return i;
}
var Jt = class {
    static area(e) {
        let t = e.length, n = 0;
        for(let i = t - 1, r = 0; r < t; i = r++)n += e[i].x * e[r].y - e[r].x * e[i].y;
        return n * .5;
    }
    static isClockWise(e) {
        return Jt.area(e) < 0;
    }
    static triangulateShape(e, t) {
        let n = [], i = [], r = [];
        gc(e), xc(n, e);
        let o = e.length;
        t.forEach(gc);
        for(let l = 0; l < t.length; l++)i.push(o), o += t[l].length, xc(n, t[l]);
        let a = Ox.triangulate(n, i);
        for(let l1 = 0; l1 < a.length; l1 += 3)r.push(a.slice(l1, l1 + 3));
        return r;
    }
};
function gc(s) {
    let e = s.length;
    e > 2 && s[e - 1].equals(s[0]) && s.pop();
}
function xc(s, e) {
    for(let t = 0; t < e.length; t++)s.push(e[t].x), s.push(e[t].y);
}
var ln = class extends _e {
    constructor(e = new Xt([
        new X(.5, .5),
        new X(-.5, .5),
        new X(-.5, -.5),
        new X(.5, -.5)
    ]), t = {}){
        super();
        this.type = "ExtrudeGeometry", this.parameters = {
            shapes: e,
            options: t
        }, e = Array.isArray(e) ? e : [
            e
        ];
        let n = this, i = [], r = [];
        for(let a = 0, l = e.length; a < l; a++){
            let c = e[a];
            o(c);
        }
        this.setAttribute("position", new de(i, 3)), this.setAttribute("uv", new de(r, 2)), this.computeVertexNormals();
        function o(a) {
            let l = [], c = t.curveSegments !== void 0 ? t.curveSegments : 12, h = t.steps !== void 0 ? t.steps : 1, u = t.depth !== void 0 ? t.depth : 1, d = t.bevelEnabled !== void 0 ? t.bevelEnabled : !0, f = t.bevelThickness !== void 0 ? t.bevelThickness : .2, m = t.bevelSize !== void 0 ? t.bevelSize : f - .1, x = t.bevelOffset !== void 0 ? t.bevelOffset : 0, v = t.bevelSegments !== void 0 ? t.bevelSegments : 3, g = t.extrudePath, p = t.UVGenerator !== void 0 ? t.UVGenerator : ny;
            t.amount !== void 0 && (console.warn("THREE.ExtrudeBufferGeometry: amount has been renamed to depth."), u = t.amount);
            let _, y = !1, b, A, L, I;
            g && (_ = g.getSpacedPoints(h), y = !0, d = !1, b = g.computeFrenetFrames(h, !1), A = new M, L = new M, I = new M), d || (v = 0, f = 0, m = 0, x = 0);
            let k = a.extractPoints(c), B = k.shape, P = k.holes;
            if (!Jt.isClockWise(B)) {
                B = B.reverse();
                for(let G = 0, j = P.length; G < j; G++){
                    let K = P[G];
                    Jt.isClockWise(K) && (P[G] = K.reverse());
                }
            }
            let E = Jt.triangulateShape(B, P), D = B;
            for(let G1 = 0, j1 = P.length; G1 < j1; G1++){
                let K1 = P[G1];
                B = B.concat(K1);
            }
            function U(G, j, K) {
                return j || console.error("THREE.ExtrudeGeometry: vec does not exist"), j.clone().multiplyScalar(K).add(G);
            }
            let F = B.length, O = E.length;
            function ne(G, j, K) {
                let ue, se, Se, Te = G.x - j.x, Pe = G.y - j.y, Ye = K.x - G.x, C = K.y - G.y, T = Te * Te + Pe * Pe, J = Te * C - Pe * Ye;
                if (Math.abs(J) > Number.EPSILON) {
                    let $ = Math.sqrt(T), re = Math.sqrt(Ye * Ye + C * C), Z = j.x - Pe / $, Me = j.y + Te / $, ve = K.x - C / re, te = K.y + Ye / re, R = ((ve - Z) * C - (te - Me) * Ye) / (Te * C - Pe * Ye);
                    ue = Z + Te * R - G.x, se = Me + Pe * R - G.y;
                    let ee = ue * ue + se * se;
                    if (ee <= 2) return new X(ue, se);
                    Se = Math.sqrt(ee / 2);
                } else {
                    let $1 = !1;
                    Te > Number.EPSILON ? Ye > Number.EPSILON && ($1 = !0) : Te < -Number.EPSILON ? Ye < -Number.EPSILON && ($1 = !0) : Math.sign(Pe) === Math.sign(C) && ($1 = !0), $1 ? (ue = -Pe, se = Te, Se = Math.sqrt(T)) : (ue = Te, se = Pe, Se = Math.sqrt(T / 2));
                }
                return new X(ue / Se, se / Se);
            }
            let ce = [];
            for(let G2 = 0, j2 = D.length, K2 = j2 - 1, ue = G2 + 1; G2 < j2; G2++, K2++, ue++)K2 === j2 && (K2 = 0), ue === j2 && (ue = 0), ce[G2] = ne(D[G2], D[K2], D[ue]);
            let V = [], W, he = ce.concat();
            for(let G3 = 0, j3 = P.length; G3 < j3; G3++){
                let K3 = P[G3];
                W = [];
                for(let ue1 = 0, se = K3.length, Se = se - 1, Te = ue1 + 1; ue1 < se; ue1++, Se++, Te++)Se === se && (Se = 0), Te === se && (Te = 0), W[ue1] = ne(K3[ue1], K3[Se], K3[Te]);
                V.push(W), he = he.concat(W);
            }
            for(let G4 = 0; G4 < v; G4++){
                let j4 = G4 / v, K4 = f * Math.cos(j4 * Math.PI / 2), ue2 = m * Math.sin(j4 * Math.PI / 2) + x;
                for(let se1 = 0, Se1 = D.length; se1 < Se1; se1++){
                    let Te1 = U(D[se1], ce[se1], ue2);
                    Ce(Te1.x, Te1.y, -K4);
                }
                for(let se2 = 0, Se2 = P.length; se2 < Se2; se2++){
                    let Te2 = P[se2];
                    W = V[se2];
                    for(let Pe = 0, Ye = Te2.length; Pe < Ye; Pe++){
                        let C = U(Te2[Pe], W[Pe], ue2);
                        Ce(C.x, C.y, -K4);
                    }
                }
            }
            let le = m + x;
            for(let G5 = 0; G5 < F; G5++){
                let j5 = d ? U(B[G5], he[G5], le) : B[G5];
                y ? (L.copy(b.normals[0]).multiplyScalar(j5.x), A.copy(b.binormals[0]).multiplyScalar(j5.y), I.copy(_[0]).add(L).add(A), Ce(I.x, I.y, I.z)) : Ce(j5.x, j5.y, 0);
            }
            for(let G6 = 1; G6 <= h; G6++)for(let j6 = 0; j6 < F; j6++){
                let K5 = d ? U(B[j6], he[j6], le) : B[j6];
                y ? (L.copy(b.normals[G6]).multiplyScalar(K5.x), A.copy(b.binormals[G6]).multiplyScalar(K5.y), I.copy(_[G6]).add(L).add(A), Ce(I.x, I.y, I.z)) : Ce(K5.x, K5.y, u / h * G6);
            }
            for(let G7 = v - 1; G7 >= 0; G7--){
                let j7 = G7 / v, K6 = f * Math.cos(j7 * Math.PI / 2), ue3 = m * Math.sin(j7 * Math.PI / 2) + x;
                for(let se3 = 0, Se3 = D.length; se3 < Se3; se3++){
                    let Te3 = U(D[se3], ce[se3], ue3);
                    Ce(Te3.x, Te3.y, u + K6);
                }
                for(let se4 = 0, Se4 = P.length; se4 < Se4; se4++){
                    let Te4 = P[se4];
                    W = V[se4];
                    for(let Pe1 = 0, Ye1 = Te4.length; Pe1 < Ye1; Pe1++){
                        let C1 = U(Te4[Pe1], W[Pe1], ue3);
                        y ? Ce(C1.x, C1.y + _[h - 1].y, _[h - 1].x + K6) : Ce(C1.x, C1.y, u + K6);
                    }
                }
            }
            fe(), Be();
            function fe() {
                let G = i.length / 3;
                if (d) {
                    let j = 0, K = F * j;
                    for(let ue = 0; ue < O; ue++){
                        let se = E[ue];
                        ye(se[2] + K, se[1] + K, se[0] + K);
                    }
                    j = h + v * 2, K = F * j;
                    for(let ue1 = 0; ue1 < O; ue1++){
                        let se1 = E[ue1];
                        ye(se1[0] + K, se1[1] + K, se1[2] + K);
                    }
                } else {
                    for(let j1 = 0; j1 < O; j1++){
                        let K1 = E[j1];
                        ye(K1[2], K1[1], K1[0]);
                    }
                    for(let j2 = 0; j2 < O; j2++){
                        let K2 = E[j2];
                        ye(K2[0] + F * h, K2[1] + F * h, K2[2] + F * h);
                    }
                }
                n.addGroup(G, i.length / 3 - G, 0);
            }
            function Be() {
                let G = i.length / 3, j = 0;
                Y(D, j), j += D.length;
                for(let K = 0, ue = P.length; K < ue; K++){
                    let se = P[K];
                    Y(se, j), j += se.length;
                }
                n.addGroup(G, i.length / 3 - G, 1);
            }
            function Y(G, j) {
                let K = G.length;
                for(; --K >= 0;){
                    let ue = K, se = K - 1;
                    se < 0 && (se = G.length - 1);
                    for(let Se = 0, Te = h + v * 2; Se < Te; Se++){
                        let Pe = F * Se, Ye = F * (Se + 1), C = j + ue + Pe, T = j + se + Pe, J = j + se + Ye, $ = j + ue + Ye;
                        ge(C, T, J, $);
                    }
                }
            }
            function Ce(G, j, K) {
                l.push(G), l.push(j), l.push(K);
            }
            function ye(G, j, K) {
                xe(G), xe(j), xe(K);
                let ue = i.length / 3, se = p.generateTopUV(n, i, ue - 3, ue - 2, ue - 1);
                Oe(se[0]), Oe(se[1]), Oe(se[2]);
            }
            function ge(G, j, K, ue) {
                xe(G), xe(j), xe(ue), xe(j), xe(K), xe(ue);
                let se = i.length / 3, Se = p.generateSideWallUV(n, i, se - 6, se - 3, se - 2, se - 1);
                Oe(Se[0]), Oe(Se[1]), Oe(Se[3]), Oe(Se[1]), Oe(Se[2]), Oe(Se[3]);
            }
            function xe(G) {
                i.push(l[G * 3 + 0]), i.push(l[G * 3 + 1]), i.push(l[G * 3 + 2]);
            }
            function Oe(G) {
                r.push(G.x), r.push(G.y);
            }
        }
    }
    toJSON() {
        let e = super.toJSON(), t = this.parameters.shapes, n = this.parameters.options;
        return iy(t, n, e);
    }
    static fromJSON(e, t) {
        let n = [];
        for(let r = 0, o = e.shapes.length; r < o; r++){
            let a = t[e.shapes[r]];
            n.push(a);
        }
        let i = e.options.extrudePath;
        return i !== void 0 && (e.options.extrudePath = new Ta[i.type]().fromJSON(i)), new ln(n, e.options);
    }
}, ny = {
    generateTopUV: function(s, e, t, n, i) {
        let r = e[t * 3], o = e[t * 3 + 1], a = e[n * 3], l = e[n * 3 + 1], c = e[i * 3], h = e[i * 3 + 1];
        return [
            new X(r, o),
            new X(a, l),
            new X(c, h)
        ];
    },
    generateSideWallUV: function(s, e, t, n, i, r) {
        let o = e[t * 3], a = e[t * 3 + 1], l = e[t * 3 + 2], c = e[n * 3], h = e[n * 3 + 1], u = e[n * 3 + 2], d = e[i * 3], f = e[i * 3 + 1], m = e[i * 3 + 2], x = e[r * 3], v = e[r * 3 + 1], g = e[r * 3 + 2];
        return Math.abs(a - h) < Math.abs(o - c) ? [
            new X(o, 1 - l),
            new X(c, 1 - u),
            new X(d, 1 - m),
            new X(x, 1 - g)
        ] : [
            new X(a, 1 - l),
            new X(h, 1 - u),
            new X(f, 1 - m),
            new X(v, 1 - g)
        ];
    }
};
function iy(s, e, t) {
    if (t.shapes = [], Array.isArray(s)) for(let n = 0, i = s.length; n < i; n++){
        let r = s[n];
        t.shapes.push(r.uuid);
    }
    else t.shapes.push(s.uuid);
    return e.extrudePath !== void 0 && (t.options.extrudePath = e.extrudePath.toJSON()), t;
}
var _r = class extends an {
    constructor(e = 1, t = 0){
        let n = (1 + Math.sqrt(5)) / 2, i = [
            -1,
            n,
            0,
            1,
            n,
            0,
            -1,
            -n,
            0,
            1,
            -n,
            0,
            0,
            -1,
            n,
            0,
            1,
            n,
            0,
            -1,
            -n,
            0,
            1,
            -n,
            n,
            0,
            -1,
            n,
            0,
            1,
            -n,
            0,
            -1,
            -n,
            0,
            1
        ], r = [
            0,
            11,
            5,
            0,
            5,
            1,
            0,
            1,
            7,
            0,
            7,
            10,
            0,
            10,
            11,
            1,
            5,
            9,
            5,
            11,
            4,
            11,
            10,
            2,
            10,
            7,
            6,
            7,
            1,
            8,
            3,
            9,
            4,
            3,
            4,
            2,
            3,
            2,
            6,
            3,
            6,
            8,
            3,
            8,
            9,
            4,
            9,
            5,
            2,
            4,
            11,
            6,
            2,
            10,
            8,
            6,
            7,
            9,
            8,
            1
        ];
        super(i, r, e, t);
        this.type = "IcosahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new _r(e.radius, e.detail);
    }
}, Mr = class extends _e {
    constructor(e = [
        new X(0, .5),
        new X(.5, 0),
        new X(0, -.5)
    ], t = 12, n = 0, i = Math.PI * 2){
        super();
        this.type = "LatheGeometry", this.parameters = {
            points: e,
            segments: t,
            phiStart: n,
            phiLength: i
        }, t = Math.floor(t), i = mt(i, 0, Math.PI * 2);
        let r = [], o = [], a = [], l = [], c = [], h = 1 / t, u = new M, d = new X, f = new M, m = new M, x = new M, v = 0, g = 0;
        for(let p = 0; p <= e.length - 1; p++)switch(p){
            case 0:
                v = e[p + 1].x - e[p].x, g = e[p + 1].y - e[p].y, f.x = g * 1, f.y = -v, f.z = g * 0, x.copy(f), f.normalize(), l.push(f.x, f.y, f.z);
                break;
            case e.length - 1:
                l.push(x.x, x.y, x.z);
                break;
            default:
                v = e[p + 1].x - e[p].x, g = e[p + 1].y - e[p].y, f.x = g * 1, f.y = -v, f.z = g * 0, m.copy(f), f.x += x.x, f.y += x.y, f.z += x.z, f.normalize(), l.push(f.x, f.y, f.z), x.copy(m);
        }
        for(let p1 = 0; p1 <= t; p1++){
            let _ = n + p1 * h * i, y = Math.sin(_), b = Math.cos(_);
            for(let A = 0; A <= e.length - 1; A++){
                u.x = e[A].x * y, u.y = e[A].y, u.z = e[A].x * b, o.push(u.x, u.y, u.z), d.x = p1 / t, d.y = A / (e.length - 1), a.push(d.x, d.y);
                let L = l[3 * A + 0] * y, I = l[3 * A + 1], k = l[3 * A + 0] * b;
                c.push(L, I, k);
            }
        }
        for(let p2 = 0; p2 < t; p2++)for(let _1 = 0; _1 < e.length - 1; _1++){
            let y1 = _1 + p2 * e.length, b1 = y1, A1 = y1 + e.length, L1 = y1 + e.length + 1, I1 = y1 + 1;
            r.push(b1, A1, I1), r.push(A1, L1, I1);
        }
        this.setIndex(r), this.setAttribute("position", new de(o, 3)), this.setAttribute("uv", new de(a, 2)), this.setAttribute("normal", new de(c, 3));
    }
    static fromJSON(e) {
        return new Mr(e.points, e.segments, e.phiStart, e.phiLength);
    }
}, Ii = class extends an {
    constructor(e = 1, t = 0){
        let n = [
            1,
            0,
            0,
            -1,
            0,
            0,
            0,
            1,
            0,
            0,
            -1,
            0,
            0,
            0,
            1,
            0,
            0,
            -1
        ], i = [
            0,
            2,
            4,
            0,
            4,
            3,
            0,
            3,
            5,
            0,
            5,
            2,
            1,
            2,
            5,
            1,
            5,
            3,
            1,
            3,
            4,
            1,
            4,
            2
        ];
        super(n, i, e, t);
        this.type = "OctahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new Ii(e.radius, e.detail);
    }
}, br = class extends _e {
    constructor(e = .5, t = 1, n = 8, i = 1, r = 0, o = Math.PI * 2){
        super();
        this.type = "RingGeometry", this.parameters = {
            innerRadius: e,
            outerRadius: t,
            thetaSegments: n,
            phiSegments: i,
            thetaStart: r,
            thetaLength: o
        }, n = Math.max(3, n), i = Math.max(1, i);
        let a = [], l = [], c = [], h = [], u = e, d = (t - e) / i, f = new M, m = new X;
        for(let x = 0; x <= i; x++){
            for(let v = 0; v <= n; v++){
                let g = r + v / n * o;
                f.x = u * Math.cos(g), f.y = u * Math.sin(g), l.push(f.x, f.y, f.z), c.push(0, 0, 1), m.x = (f.x / t + 1) / 2, m.y = (f.y / t + 1) / 2, h.push(m.x, m.y);
            }
            u += d;
        }
        for(let x1 = 0; x1 < i; x1++){
            let v1 = x1 * (n + 1);
            for(let g1 = 0; g1 < n; g1++){
                let p = g1 + v1, _ = p, y = p + n + 1, b = p + n + 2, A = p + 1;
                a.push(_, y, A), a.push(y, b, A);
            }
        }
        this.setIndex(a), this.setAttribute("position", new de(l, 3)), this.setAttribute("normal", new de(c, 3)), this.setAttribute("uv", new de(h, 2));
    }
    static fromJSON(e) {
        return new br(e.innerRadius, e.outerRadius, e.thetaSegments, e.phiSegments, e.thetaStart, e.thetaLength);
    }
}, Di = class extends _e {
    constructor(e = new Xt([
        new X(0, .5),
        new X(-.5, -.5),
        new X(.5, -.5)
    ]), t = 12){
        super();
        this.type = "ShapeGeometry", this.parameters = {
            shapes: e,
            curveSegments: t
        };
        let n = [], i = [], r = [], o = [], a = 0, l = 0;
        if (Array.isArray(e) === !1) c(e);
        else for(let h = 0; h < e.length; h++)c(e[h]), this.addGroup(a, l, h), a += l, l = 0;
        this.setIndex(n), this.setAttribute("position", new de(i, 3)), this.setAttribute("normal", new de(r, 3)), this.setAttribute("uv", new de(o, 2));
        function c(h) {
            let u = i.length / 3, d = h.extractPoints(t), f = d.shape, m = d.holes;
            Jt.isClockWise(f) === !1 && (f = f.reverse());
            for(let v = 0, g = m.length; v < g; v++){
                let p = m[v];
                Jt.isClockWise(p) === !0 && (m[v] = p.reverse());
            }
            let x = Jt.triangulateShape(f, m);
            for(let v1 = 0, g1 = m.length; v1 < g1; v1++){
                let p1 = m[v1];
                f = f.concat(p1);
            }
            for(let v2 = 0, g2 = f.length; v2 < g2; v2++){
                let p2 = f[v2];
                i.push(p2.x, p2.y, 0), r.push(0, 0, 1), o.push(p2.x, p2.y);
            }
            for(let v3 = 0, g3 = x.length; v3 < g3; v3++){
                let p3 = x[v3], _ = p3[0] + u, y = p3[1] + u, b = p3[2] + u;
                n.push(_, y, b), l += 3;
            }
        }
    }
    toJSON() {
        let e = super.toJSON(), t = this.parameters.shapes;
        return ry(t, e);
    }
    static fromJSON(e, t) {
        let n = [];
        for(let i = 0, r = e.shapes.length; i < r; i++){
            let o = t[e.shapes[i]];
            n.push(o);
        }
        return new Di(n, e.curveSegments);
    }
};
function ry(s, e) {
    if (e.shapes = [], Array.isArray(s)) for(let t = 0, n = s.length; t < n; t++){
        let i = s[t];
        e.shapes.push(i.uuid);
    }
    else e.shapes.push(s.uuid);
    return e;
}
var Fi = class extends _e {
    constructor(e = 1, t = 32, n = 16, i = 0, r = Math.PI * 2, o = 0, a = Math.PI){
        super();
        this.type = "SphereGeometry", this.parameters = {
            radius: e,
            widthSegments: t,
            heightSegments: n,
            phiStart: i,
            phiLength: r,
            thetaStart: o,
            thetaLength: a
        }, t = Math.max(3, Math.floor(t)), n = Math.max(2, Math.floor(n));
        let l = Math.min(o + a, Math.PI), c = 0, h = [], u = new M, d = new M, f = [], m = [], x = [], v = [];
        for(let g = 0; g <= n; g++){
            let p = [], _ = g / n, y = 0;
            g == 0 && o == 0 ? y = .5 / t : g == n && l == Math.PI && (y = -.5 / t);
            for(let b = 0; b <= t; b++){
                let A = b / t;
                u.x = -e * Math.cos(i + A * r) * Math.sin(o + _ * a), u.y = e * Math.cos(o + _ * a), u.z = e * Math.sin(i + A * r) * Math.sin(o + _ * a), m.push(u.x, u.y, u.z), d.copy(u).normalize(), x.push(d.x, d.y, d.z), v.push(A + y, 1 - _), p.push(c++);
            }
            h.push(p);
        }
        for(let g1 = 0; g1 < n; g1++)for(let p1 = 0; p1 < t; p1++){
            let _1 = h[g1][p1 + 1], y1 = h[g1][p1], b1 = h[g1 + 1][p1], A1 = h[g1 + 1][p1 + 1];
            (g1 !== 0 || o > 0) && f.push(_1, y1, A1), (g1 !== n - 1 || l < Math.PI) && f.push(y1, b1, A1);
        }
        this.setIndex(f), this.setAttribute("position", new de(m, 3)), this.setAttribute("normal", new de(x, 3)), this.setAttribute("uv", new de(v, 2));
    }
    static fromJSON(e) {
        return new Fi(e.radius, e.widthSegments, e.heightSegments, e.phiStart, e.phiLength, e.thetaStart, e.thetaLength);
    }
}, wr = class extends an {
    constructor(e = 1, t = 0){
        let n = [
            1,
            1,
            1,
            -1,
            -1,
            1,
            -1,
            1,
            -1,
            1,
            -1,
            -1
        ], i = [
            2,
            1,
            0,
            0,
            3,
            2,
            1,
            3,
            0,
            2,
            3,
            1
        ];
        super(n, i, e, t);
        this.type = "TetrahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new wr(e.radius, e.detail);
    }
}, Sr = class extends _e {
    constructor(e = 1, t = .4, n = 8, i = 6, r = Math.PI * 2){
        super();
        this.type = "TorusGeometry", this.parameters = {
            radius: e,
            tube: t,
            radialSegments: n,
            tubularSegments: i,
            arc: r
        }, n = Math.floor(n), i = Math.floor(i);
        let o = [], a = [], l = [], c = [], h = new M, u = new M, d = new M;
        for(let f = 0; f <= n; f++)for(let m = 0; m <= i; m++){
            let x = m / i * r, v = f / n * Math.PI * 2;
            u.x = (e + t * Math.cos(v)) * Math.cos(x), u.y = (e + t * Math.cos(v)) * Math.sin(x), u.z = t * Math.sin(v), a.push(u.x, u.y, u.z), h.x = e * Math.cos(x), h.y = e * Math.sin(x), d.subVectors(u, h).normalize(), l.push(d.x, d.y, d.z), c.push(m / i), c.push(f / n);
        }
        for(let f1 = 1; f1 <= n; f1++)for(let m1 = 1; m1 <= i; m1++){
            let x1 = (i + 1) * f1 + m1 - 1, v1 = (i + 1) * (f1 - 1) + m1 - 1, g = (i + 1) * (f1 - 1) + m1, p = (i + 1) * f1 + m1;
            o.push(x1, v1, p), o.push(v1, g, p);
        }
        this.setIndex(o), this.setAttribute("position", new de(a, 3)), this.setAttribute("normal", new de(l, 3)), this.setAttribute("uv", new de(c, 2));
    }
    static fromJSON(e) {
        return new Sr(e.radius, e.tube, e.radialSegments, e.tubularSegments, e.arc);
    }
}, Tr = class extends _e {
    constructor(e = 1, t = .4, n = 64, i = 8, r = 2, o = 3){
        super();
        this.type = "TorusKnotGeometry", this.parameters = {
            radius: e,
            tube: t,
            tubularSegments: n,
            radialSegments: i,
            p: r,
            q: o
        }, n = Math.floor(n), i = Math.floor(i);
        let a = [], l = [], c = [], h = [], u = new M, d = new M, f = new M, m = new M, x = new M, v = new M, g = new M;
        for(let _ = 0; _ <= n; ++_){
            let y = _ / n * r * Math.PI * 2;
            p(y, r, o, e, f), p(y + .01, r, o, e, m), v.subVectors(m, f), g.addVectors(m, f), x.crossVectors(v, g), g.crossVectors(x, v), x.normalize(), g.normalize();
            for(let b = 0; b <= i; ++b){
                let A = b / i * Math.PI * 2, L = -t * Math.cos(A), I = t * Math.sin(A);
                u.x = f.x + (L * g.x + I * x.x), u.y = f.y + (L * g.y + I * x.y), u.z = f.z + (L * g.z + I * x.z), l.push(u.x, u.y, u.z), d.subVectors(u, f).normalize(), c.push(d.x, d.y, d.z), h.push(_ / n), h.push(b / i);
            }
        }
        for(let _1 = 1; _1 <= n; _1++)for(let y1 = 1; y1 <= i; y1++){
            let b1 = (i + 1) * (_1 - 1) + (y1 - 1), A1 = (i + 1) * _1 + (y1 - 1), L1 = (i + 1) * _1 + y1, I1 = (i + 1) * (_1 - 1) + y1;
            a.push(b1, A1, I1), a.push(A1, L1, I1);
        }
        this.setIndex(a), this.setAttribute("position", new de(l, 3)), this.setAttribute("normal", new de(c, 3)), this.setAttribute("uv", new de(h, 2));
        function p(_, y, b, A, L) {
            let I = Math.cos(_), k = Math.sin(_), B = b / y * _, P = Math.cos(B);
            L.x = A * (2 + P) * .5 * I, L.y = A * (2 + P) * k * .5, L.z = A * Math.sin(B) * .5;
        }
    }
    static fromJSON(e) {
        return new Tr(e.radius, e.tube, e.tubularSegments, e.radialSegments, e.p, e.q);
    }
}, Er = class extends _e {
    constructor(e = new ho(new M(-1, -1, 0), new M(-1, 1, 0), new M(1, 1, 0)), t = 64, n = 1, i = 8, r = !1){
        super();
        this.type = "TubeGeometry", this.parameters = {
            path: e,
            tubularSegments: t,
            radius: n,
            radialSegments: i,
            closed: r
        };
        let o = e.computeFrenetFrames(t, r);
        this.tangents = o.tangents, this.normals = o.normals, this.binormals = o.binormals;
        let a = new M, l = new M, c = new X, h = new M, u = [], d = [], f = [], m = [];
        x(), this.setIndex(m), this.setAttribute("position", new de(u, 3)), this.setAttribute("normal", new de(d, 3)), this.setAttribute("uv", new de(f, 2));
        function x() {
            for(let _ = 0; _ < t; _++)v(_);
            v(r === !1 ? t : 0), p(), g();
        }
        function v(_) {
            h = e.getPointAt(_ / t, h);
            let y = o.normals[_], b = o.binormals[_];
            for(let A = 0; A <= i; A++){
                let L = A / i * Math.PI * 2, I = Math.sin(L), k = -Math.cos(L);
                l.x = k * y.x + I * b.x, l.y = k * y.y + I * b.y, l.z = k * y.z + I * b.z, l.normalize(), d.push(l.x, l.y, l.z), a.x = h.x + n * l.x, a.y = h.y + n * l.y, a.z = h.z + n * l.z, u.push(a.x, a.y, a.z);
            }
        }
        function g() {
            for(let _ = 1; _ <= t; _++)for(let y = 1; y <= i; y++){
                let b = (i + 1) * (_ - 1) + (y - 1), A = (i + 1) * _ + (y - 1), L = (i + 1) * _ + y, I = (i + 1) * (_ - 1) + y;
                m.push(b, A, I), m.push(A, L, I);
            }
        }
        function p() {
            for(let _ = 0; _ <= t; _++)for(let y = 0; y <= i; y++)c.x = _ / t, c.y = y / i, f.push(c.x, c.y);
        }
    }
    toJSON() {
        let e = super.toJSON();
        return e.path = this.parameters.path.toJSON(), e;
    }
    static fromJSON(e) {
        return new Er(new Ta[e.path.type]().fromJSON(e.path), e.tubularSegments, e.radius, e.radialSegments, e.closed);
    }
}, Ea = class extends _e {
    constructor(e = null){
        super();
        if (this.type = "WireframeGeometry", this.parameters = {
            geometry: e
        }, e !== null) {
            let t = [], n = new Set, i = new M, r = new M;
            if (e.index !== null) {
                let o = e.attributes.position, a = e.index, l = e.groups;
                l.length === 0 && (l = [
                    {
                        start: 0,
                        count: a.count,
                        materialIndex: 0
                    }
                ]);
                for(let c = 0, h = l.length; c < h; ++c){
                    let u = l[c], d = u.start, f = u.count;
                    for(let m = d, x = d + f; m < x; m += 3)for(let v = 0; v < 3; v++){
                        let g = a.getX(m + v), p = a.getX(m + (v + 1) % 3);
                        i.fromBufferAttribute(o, g), r.fromBufferAttribute(o, p), yc(i, r, n) === !0 && (t.push(i.x, i.y, i.z), t.push(r.x, r.y, r.z));
                    }
                }
            } else {
                let o1 = e.attributes.position;
                for(let a1 = 0, l1 = o1.count / 3; a1 < l1; a1++)for(let c1 = 0; c1 < 3; c1++){
                    let h1 = 3 * a1 + c1, u1 = 3 * a1 + (c1 + 1) % 3;
                    i.fromBufferAttribute(o1, h1), r.fromBufferAttribute(o1, u1), yc(i, r, n) === !0 && (t.push(i.x, i.y, i.z), t.push(r.x, r.y, r.z));
                }
            }
            this.setAttribute("position", new de(t, 3));
        }
    }
};
function yc(s, e, t) {
    let n = `${s.x},${s.y},${s.z}-${e.x},${e.y},${e.z}`, i = `${e.x},${e.y},${e.z}-${s.x},${s.y},${s.z}`;
    return t.has(n) === !0 || t.has(i) === !0 ? !1 : (t.add(n, i), !0);
}
var vc = Object.freeze({
    __proto__: null,
    BoxGeometry: wn,
    BoxBufferGeometry: wn,
    CircleGeometry: fr,
    CircleBufferGeometry: fr,
    ConeGeometry: pr,
    ConeBufferGeometry: pr,
    CylinderGeometry: Jn,
    CylinderBufferGeometry: Jn,
    DodecahedronGeometry: mr,
    DodecahedronBufferGeometry: mr,
    EdgesGeometry: _a,
    ExtrudeGeometry: ln,
    ExtrudeBufferGeometry: ln,
    IcosahedronGeometry: _r,
    IcosahedronBufferGeometry: _r,
    LatheGeometry: Mr,
    LatheBufferGeometry: Mr,
    OctahedronGeometry: Ii,
    OctahedronBufferGeometry: Ii,
    PlaneGeometry: Pi,
    PlaneBufferGeometry: Pi,
    PolyhedronGeometry: an,
    PolyhedronBufferGeometry: an,
    RingGeometry: br,
    RingBufferGeometry: br,
    ShapeGeometry: Di,
    ShapeBufferGeometry: Di,
    SphereGeometry: Fi,
    SphereBufferGeometry: Fi,
    TetrahedronGeometry: wr,
    TetrahedronBufferGeometry: wr,
    TorusGeometry: Sr,
    TorusBufferGeometry: Sr,
    TorusKnotGeometry: Tr,
    TorusKnotBufferGeometry: Tr,
    TubeGeometry: Er,
    TubeBufferGeometry: Er,
    WireframeGeometry: Ea
}), Aa = class extends dt {
    constructor(e){
        super();
        this.type = "ShadowMaterial", this.color = new ae(0), this.transparent = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this;
    }
};
Aa.prototype.isShadowMaterial = !0;
var po = class extends dt {
    constructor(e){
        super();
        this.defines = {
            STANDARD: ""
        }, this.type = "MeshStandardMaterial", this.color = new ae(16777215), this.roughness = 1, this.metalness = 0, this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ae(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = Hi, this.normalScale = new X(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.roughnessMap = null, this.metalnessMap = null, this.alphaMap = null, this.envMap = null, this.envMapIntensity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.defines = {
            STANDARD: ""
        }, this.color.copy(e.color), this.roughness = e.roughness, this.metalness = e.metalness, this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.roughnessMap = e.roughnessMap, this.metalnessMap = e.metalnessMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.envMapIntensity = e.envMapIntensity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.flatShading = e.flatShading, this;
    }
};
po.prototype.isMeshStandardMaterial = !0;
var Ca = class extends po {
    constructor(e){
        super();
        this.defines = {
            STANDARD: "",
            PHYSICAL: ""
        }, this.type = "MeshPhysicalMaterial", this.clearcoatMap = null, this.clearcoatRoughness = 0, this.clearcoatRoughnessMap = null, this.clearcoatNormalScale = new X(1, 1), this.clearcoatNormalMap = null, this.ior = 1.5, Object.defineProperty(this, "reflectivity", {
            get: function() {
                return mt(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
            },
            set: function(t) {
                this.ior = (1 + .4 * t) / (1 - .4 * t);
            }
        }), this.sheenColor = new ae(0), this.sheenColorMap = null, this.sheenRoughness = 1, this.sheenRoughnessMap = null, this.transmissionMap = null, this.thickness = 0, this.thicknessMap = null, this.attenuationDistance = 0, this.attenuationColor = new ae(1, 1, 1), this.specularIntensity = 1, this.specularIntensityMap = null, this.specularColor = new ae(1, 1, 1), this.specularColorMap = null, this._sheen = 0, this._clearcoat = 0, this._transmission = 0, this.setValues(e);
    }
    get sheen() {
        return this._sheen;
    }
    set sheen(e) {
        this._sheen > 0 != e > 0 && this.version++, this._sheen = e;
    }
    get clearcoat() {
        return this._clearcoat;
    }
    set clearcoat(e) {
        this._clearcoat > 0 != e > 0 && this.version++, this._clearcoat = e;
    }
    get transmission() {
        return this._transmission;
    }
    set transmission(e) {
        this._transmission > 0 != e > 0 && this.version++, this._transmission = e;
    }
    copy(e) {
        return super.copy(e), this.defines = {
            STANDARD: "",
            PHYSICAL: ""
        }, this.clearcoat = e.clearcoat, this.clearcoatMap = e.clearcoatMap, this.clearcoatRoughness = e.clearcoatRoughness, this.clearcoatRoughnessMap = e.clearcoatRoughnessMap, this.clearcoatNormalMap = e.clearcoatNormalMap, this.clearcoatNormalScale.copy(e.clearcoatNormalScale), this.ior = e.ior, this.sheen = e.sheen, this.sheenColor.copy(e.sheenColor), this.sheenColorMap = e.sheenColorMap, this.sheenRoughness = e.sheenRoughness, this.sheenRoughnessMap = e.sheenRoughnessMap, this.transmission = e.transmission, this.transmissionMap = e.transmissionMap, this.thickness = e.thickness, this.thicknessMap = e.thicknessMap, this.attenuationDistance = e.attenuationDistance, this.attenuationColor.copy(e.attenuationColor), this.specularIntensity = e.specularIntensity, this.specularIntensityMap = e.specularIntensityMap, this.specularColor.copy(e.specularColor), this.specularColorMap = e.specularColorMap, this;
    }
};
Ca.prototype.isMeshPhysicalMaterial = !0;
var La = class extends dt {
    constructor(e){
        super();
        this.type = "MeshPhongMaterial", this.color = new ae(16777215), this.specular = new ae(1118481), this.shininess = 30, this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ae(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = Hi, this.normalScale = new X(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = Vs, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.specular.copy(e.specular), this.shininess = e.shininess, this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.specularMap = e.specularMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.combine = e.combine, this.reflectivity = e.reflectivity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.flatShading = e.flatShading, this;
    }
};
La.prototype.isMeshPhongMaterial = !0;
var Ra = class extends dt {
    constructor(e){
        super();
        this.defines = {
            TOON: ""
        }, this.type = "MeshToonMaterial", this.color = new ae(16777215), this.map = null, this.gradientMap = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ae(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = Hi, this.normalScale = new X(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.alphaMap = null, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.gradientMap = e.gradientMap, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.alphaMap = e.alphaMap, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this;
    }
};
Ra.prototype.isMeshToonMaterial = !0;
var Pa = class extends dt {
    constructor(e){
        super();
        this.type = "MeshNormalMaterial", this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = Hi, this.normalScale = new X(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.wireframe = !1, this.wireframeLinewidth = 1, this.fog = !1, this.flatShading = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.flatShading = e.flatShading, this;
    }
};
Pa.prototype.isMeshNormalMaterial = !0;
var Ia = class extends dt {
    constructor(e){
        super();
        this.type = "MeshLambertMaterial", this.color = new ae(16777215), this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ae(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = Vs, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.specularMap = e.specularMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.combine = e.combine, this.reflectivity = e.reflectivity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this;
    }
};
Ia.prototype.isMeshLambertMaterial = !0;
var Da = class extends dt {
    constructor(e){
        super();
        this.defines = {
            MATCAP: ""
        }, this.type = "MeshMatcapMaterial", this.color = new ae(16777215), this.matcap = null, this.map = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = Hi, this.normalScale = new X(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.alphaMap = null, this.flatShading = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.defines = {
            MATCAP: ""
        }, this.color.copy(e.color), this.matcap = e.matcap, this.map = e.map, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.alphaMap = e.alphaMap, this.flatShading = e.flatShading, this;
    }
};
Da.prototype.isMeshMatcapMaterial = !0;
var Fa = class extends ft {
    constructor(e){
        super();
        this.type = "LineDashedMaterial", this.scale = 1, this.dashSize = 3, this.gapSize = 1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.scale = e.scale, this.dashSize = e.dashSize, this.gapSize = e.gapSize, this;
    }
};
Fa.prototype.isLineDashedMaterial = !0;
var sy = Object.freeze({
    __proto__: null,
    ShadowMaterial: Aa,
    SpriteMaterial: io,
    RawShaderMaterial: Gi,
    ShaderMaterial: sn,
    PointsMaterial: jn,
    MeshPhysicalMaterial: Ca,
    MeshStandardMaterial: po,
    MeshPhongMaterial: La,
    MeshToonMaterial: Ra,
    MeshNormalMaterial: Pa,
    MeshLambertMaterial: Ia,
    MeshDepthMaterial: eo,
    MeshDistanceMaterial: to,
    MeshBasicMaterial: hn,
    MeshMatcapMaterial: Da,
    LineDashedMaterial: Fa,
    LineBasicMaterial: ft,
    Material: dt
}), Ze = {
    arraySlice: function(s, e, t) {
        return Ze.isTypedArray(s) ? new s.constructor(s.subarray(e, t !== void 0 ? t : s.length)) : s.slice(e, t);
    },
    convertArray: function(s, e, t) {
        return !s || !t && s.constructor === e ? s : typeof e.BYTES_PER_ELEMENT == "number" ? new e(s) : Array.prototype.slice.call(s);
    },
    isTypedArray: function(s) {
        return ArrayBuffer.isView(s) && !(s instanceof DataView);
    },
    getKeyframeOrder: function(s) {
        function e(i, r) {
            return s[i] - s[r];
        }
        let t = s.length, n = new Array(t);
        for(let i = 0; i !== t; ++i)n[i] = i;
        return n.sort(e), n;
    },
    sortedArray: function(s, e, t) {
        let n = s.length, i = new s.constructor(n);
        for(let r = 0, o = 0; o !== n; ++r){
            let a = t[r] * e;
            for(let l = 0; l !== e; ++l)i[o++] = s[a + l];
        }
        return i;
    },
    flattenJSON: function(s, e, t, n) {
        let i = 1, r = s[0];
        for(; r !== void 0 && r[n] === void 0;)r = s[i++];
        if (r === void 0) return;
        let o = r[n];
        if (o !== void 0) if (Array.isArray(o)) do o = r[n], o !== void 0 && (e.push(r.time), t.push.apply(t, o)), r = s[i++];
        while (r !== void 0)
        else if (o.toArray !== void 0) do o = r[n], o !== void 0 && (e.push(r.time), o.toArray(t, t.length)), r = s[i++];
        while (r !== void 0)
        else do o = r[n], o !== void 0 && (e.push(r.time), t.push(o)), r = s[i++];
        while (r !== void 0)
    },
    subclip: function(s, e, t, n, i = 30) {
        let r = s.clone();
        r.name = e;
        let o = [];
        for(let l = 0; l < r.tracks.length; ++l){
            let c = r.tracks[l], h = c.getValueSize(), u = [], d = [];
            for(let f = 0; f < c.times.length; ++f){
                let m = c.times[f] * i;
                if (!(m < t || m >= n)) {
                    u.push(c.times[f]);
                    for(let x = 0; x < h; ++x)d.push(c.values[f * h + x]);
                }
            }
            u.length !== 0 && (c.times = Ze.convertArray(u, c.times.constructor), c.values = Ze.convertArray(d, c.values.constructor), o.push(c));
        }
        r.tracks = o;
        let a = 1 / 0;
        for(let l1 = 0; l1 < r.tracks.length; ++l1)a > r.tracks[l1].times[0] && (a = r.tracks[l1].times[0]);
        for(let l2 = 0; l2 < r.tracks.length; ++l2)r.tracks[l2].shift(-1 * a);
        return r.resetDuration(), r;
    },
    makeClipAdditive: function(s, e = 0, t = s, n = 30) {
        n <= 0 && (n = 30);
        let i = t.tracks.length, r = e / n;
        for(let o = 0; o < i; ++o){
            let a = t.tracks[o], l = a.ValueTypeName;
            if (l === "bool" || l === "string") continue;
            let c = s.tracks.find(function(g) {
                return g.name === a.name && g.ValueTypeName === l;
            });
            if (c === void 0) continue;
            let h = 0, u = a.getValueSize();
            a.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline && (h = u / 3);
            let d = 0, f = c.getValueSize();
            c.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline && (d = f / 3);
            let m = a.times.length - 1, x;
            if (r <= a.times[0]) {
                let g = h, p = u - h;
                x = Ze.arraySlice(a.values, g, p);
            } else if (r >= a.times[m]) {
                let g1 = m * u + h, p1 = g1 + u - h;
                x = Ze.arraySlice(a.values, g1, p1);
            } else {
                let g2 = a.createInterpolant(), p2 = h, _ = u - h;
                g2.evaluate(r), x = Ze.arraySlice(g2.resultBuffer, p2, _);
            }
            l === "quaternion" && new gt().fromArray(x).normalize().conjugate().toArray(x);
            let v = c.times.length;
            for(let g3 = 0; g3 < v; ++g3){
                let p3 = g3 * f + d;
                if (l === "quaternion") gt.multiplyQuaternionsFlat(c.values, p3, x, 0, c.values, p3);
                else {
                    let _1 = f - d * 2;
                    for(let y = 0; y < _1; ++y)c.values[p3 + y] -= x[y];
                }
            }
        }
        return s.blendMode = qc, s;
    }
}, cn = class {
    constructor(e, t, n, i){
        this.parameterPositions = e, this._cachedIndex = 0, this.resultBuffer = i !== void 0 ? i : new t.constructor(n), this.sampleValues = t, this.valueSize = n, this.settings = null, this.DefaultSettings_ = {};
    }
    evaluate(e) {
        let t = this.parameterPositions, n = this._cachedIndex, i = t[n], r = t[n - 1];
        e: {
            t: {
                let o;
                n: {
                    i: if (!(e < i)) {
                        for(let a = n + 2;;){
                            if (i === void 0) {
                                if (e < r) break i;
                                return n = t.length, this._cachedIndex = n, this.afterEnd_(n - 1, e, r);
                            }
                            if (n === a) break;
                            if (r = i, i = t[++n], e < i) break t;
                        }
                        o = t.length;
                        break n;
                    }
                    if (!(e >= r)) {
                        let a1 = t[1];
                        e < a1 && (n = 2, r = a1);
                        for(let l = n - 2;;){
                            if (r === void 0) return this._cachedIndex = 0, this.beforeStart_(0, e, i);
                            if (n === l) break;
                            if (i = r, r = t[--n - 1], e >= r) break t;
                        }
                        o = n, n = 0;
                        break n;
                    }
                    break e;
                }
                for(; n < o;){
                    let a2 = n + o >>> 1;
                    e < t[a2] ? o = a2 : n = a2 + 1;
                }
                if (i = t[n], r = t[n - 1], r === void 0) return this._cachedIndex = 0, this.beforeStart_(0, e, i);
                if (i === void 0) return n = t.length, this._cachedIndex = n, this.afterEnd_(n - 1, r, e);
            }
            this._cachedIndex = n, this.intervalChanged_(n, r, i);
        }
        return this.interpolate_(n, r, e, i);
    }
    getSettings_() {
        return this.settings || this.DefaultSettings_;
    }
    copySampleValue_(e) {
        let t = this.resultBuffer, n = this.sampleValues, i = this.valueSize, r = e * i;
        for(let o = 0; o !== i; ++o)t[o] = n[r + o];
        return t;
    }
    interpolate_() {
        throw new Error("call to abstract method");
    }
    intervalChanged_() {}
};
cn.prototype.beforeStart_ = cn.prototype.copySampleValue_;
cn.prototype.afterEnd_ = cn.prototype.copySampleValue_;
var Ph = class extends cn {
    constructor(e, t, n, i){
        super(e, t, n, i);
        this._weightPrev = -0, this._offsetPrev = -0, this._weightNext = -0, this._offsetNext = -0, this.DefaultSettings_ = {
            endingStart: Mi,
            endingEnd: Mi
        };
    }
    intervalChanged_(e, t, n) {
        let i = this.parameterPositions, r = e - 2, o = e + 1, a = i[r], l = i[o];
        if (a === void 0) switch(this.getSettings_().endingStart){
            case bi:
                r = e, a = 2 * t - n;
                break;
            case Os:
                r = i.length - 2, a = t + i[r] - i[r + 1];
                break;
            default:
                r = e, a = n;
        }
        if (l === void 0) switch(this.getSettings_().endingEnd){
            case bi:
                o = e, l = 2 * n - t;
                break;
            case Os:
                o = 1, l = n + i[1] - i[0];
                break;
            default:
                o = e - 1, l = t;
        }
        let c = (n - t) * .5, h = this.valueSize;
        this._weightPrev = c / (t - a), this._weightNext = c / (l - n), this._offsetPrev = r * h, this._offsetNext = o * h;
    }
    interpolate_(e, t, n, i) {
        let r = this.resultBuffer, o = this.sampleValues, a = this.valueSize, l = e * a, c = l - a, h = this._offsetPrev, u = this._offsetNext, d = this._weightPrev, f = this._weightNext, m = (n - t) / (i - t), x = m * m, v = x * m, g = -d * v + 2 * d * x - d * m, p = (1 + d) * v + (-1.5 - 2 * d) * x + (-.5 + d) * m + 1, _ = (-1 - f) * v + (1.5 + f) * x + .5 * m, y = f * v - f * x;
        for(let b = 0; b !== a; ++b)r[b] = g * o[h + b] + p * o[c + b] + _ * o[l + b] + y * o[u + b];
        return r;
    }
}, Na = class extends cn {
    constructor(e, t, n, i){
        super(e, t, n, i);
    }
    interpolate_(e, t, n, i) {
        let r = this.resultBuffer, o = this.sampleValues, a = this.valueSize, l = e * a, c = l - a, h = (n - t) / (i - t), u = 1 - h;
        for(let d = 0; d !== a; ++d)r[d] = o[c + d] * u + o[l + d] * h;
        return r;
    }
}, Ih = class extends cn {
    constructor(e, t, n, i){
        super(e, t, n, i);
    }
    interpolate_(e) {
        return this.copySampleValue_(e - 1);
    }
}, zt = class {
    constructor(e, t, n, i){
        if (e === void 0) throw new Error("THREE.KeyframeTrack: track name is undefined");
        if (t === void 0 || t.length === 0) throw new Error("THREE.KeyframeTrack: no keyframes in track named " + e);
        this.name = e, this.times = Ze.convertArray(t, this.TimeBufferType), this.values = Ze.convertArray(n, this.ValueBufferType), this.setInterpolation(i || this.DefaultInterpolation);
    }
    static toJSON(e) {
        let t = e.constructor, n;
        if (t.toJSON !== this.toJSON) n = t.toJSON(e);
        else {
            n = {
                name: e.name,
                times: Ze.convertArray(e.times, Array),
                values: Ze.convertArray(e.values, Array)
            };
            let i = e.getInterpolation();
            i !== e.DefaultInterpolation && (n.interpolation = i);
        }
        return n.type = e.ValueTypeName, n;
    }
    InterpolantFactoryMethodDiscrete(e) {
        return new Ih(this.times, this.values, this.getValueSize(), e);
    }
    InterpolantFactoryMethodLinear(e) {
        return new Na(this.times, this.values, this.getValueSize(), e);
    }
    InterpolantFactoryMethodSmooth(e) {
        return new Ph(this.times, this.values, this.getValueSize(), e);
    }
    setInterpolation(e) {
        let t;
        switch(e){
            case zs:
                t = this.InterpolantFactoryMethodDiscrete;
                break;
            case Us:
                t = this.InterpolantFactoryMethodLinear;
                break;
            case yo:
                t = this.InterpolantFactoryMethodSmooth;
                break;
        }
        if (t === void 0) {
            let n = "unsupported interpolation for " + this.ValueTypeName + " keyframe track named " + this.name;
            if (this.createInterpolant === void 0) if (e !== this.DefaultInterpolation) this.setInterpolation(this.DefaultInterpolation);
            else throw new Error(n);
            return console.warn("THREE.KeyframeTrack:", n), this;
        }
        return this.createInterpolant = t, this;
    }
    getInterpolation() {
        switch(this.createInterpolant){
            case this.InterpolantFactoryMethodDiscrete:
                return zs;
            case this.InterpolantFactoryMethodLinear:
                return Us;
            case this.InterpolantFactoryMethodSmooth:
                return yo;
        }
    }
    getValueSize() {
        return this.values.length / this.times.length;
    }
    shift(e) {
        if (e !== 0) {
            let t = this.times;
            for(let n = 0, i = t.length; n !== i; ++n)t[n] += e;
        }
        return this;
    }
    scale(e) {
        if (e !== 1) {
            let t = this.times;
            for(let n = 0, i = t.length; n !== i; ++n)t[n] *= e;
        }
        return this;
    }
    trim(e, t) {
        let n = this.times, i = n.length, r = 0, o = i - 1;
        for(; r !== i && n[r] < e;)++r;
        for(; o !== -1 && n[o] > t;)--o;
        if (++o, r !== 0 || o !== i) {
            r >= o && (o = Math.max(o, 1), r = o - 1);
            let a = this.getValueSize();
            this.times = Ze.arraySlice(n, r, o), this.values = Ze.arraySlice(this.values, r * a, o * a);
        }
        return this;
    }
    validate() {
        let e = !0, t = this.getValueSize();
        t - Math.floor(t) !== 0 && (console.error("THREE.KeyframeTrack: Invalid value size in track.", this), e = !1);
        let n = this.times, i = this.values, r = n.length;
        r === 0 && (console.error("THREE.KeyframeTrack: Track is empty.", this), e = !1);
        let o = null;
        for(let a = 0; a !== r; a++){
            let l = n[a];
            if (typeof l == "number" && isNaN(l)) {
                console.error("THREE.KeyframeTrack: Time is not a valid number.", this, a, l), e = !1;
                break;
            }
            if (o !== null && o > l) {
                console.error("THREE.KeyframeTrack: Out of order keys.", this, a, l, o), e = !1;
                break;
            }
            o = l;
        }
        if (i !== void 0 && Ze.isTypedArray(i)) for(let a1 = 0, l1 = i.length; a1 !== l1; ++a1){
            let c = i[a1];
            if (isNaN(c)) {
                console.error("THREE.KeyframeTrack: Value is not a valid number.", this, a1, c), e = !1;
                break;
            }
        }
        return e;
    }
    optimize() {
        let e = Ze.arraySlice(this.times), t = Ze.arraySlice(this.values), n = this.getValueSize(), i = this.getInterpolation() === yo, r = e.length - 1, o = 1;
        for(let a = 1; a < r; ++a){
            let l = !1, c = e[a], h = e[a + 1];
            if (c !== h && (a !== 1 || c !== e[0])) if (i) l = !0;
            else {
                let u = a * n, d = u - n, f = u + n;
                for(let m = 0; m !== n; ++m){
                    let x = t[u + m];
                    if (x !== t[d + m] || x !== t[f + m]) {
                        l = !0;
                        break;
                    }
                }
            }
            if (l) {
                if (a !== o) {
                    e[o] = e[a];
                    let u1 = a * n, d1 = o * n;
                    for(let f1 = 0; f1 !== n; ++f1)t[d1 + f1] = t[u1 + f1];
                }
                ++o;
            }
        }
        if (r > 0) {
            e[o] = e[r];
            for(let a1 = r * n, l1 = o * n, c1 = 0; c1 !== n; ++c1)t[l1 + c1] = t[a1 + c1];
            ++o;
        }
        return o !== e.length ? (this.times = Ze.arraySlice(e, 0, o), this.values = Ze.arraySlice(t, 0, o * n)) : (this.times = e, this.values = t), this;
    }
    clone() {
        let e = Ze.arraySlice(this.times, 0), t = Ze.arraySlice(this.values, 0), n = this.constructor, i = new n(this.name, e, t);
        return i.createInterpolant = this.createInterpolant, i;
    }
};
zt.prototype.TimeBufferType = Float32Array;
zt.prototype.ValueBufferType = Float32Array;
zt.prototype.DefaultInterpolation = Us;
var Qn = class extends zt {
};
Qn.prototype.ValueTypeName = "bool";
Qn.prototype.ValueBufferType = Array;
Qn.prototype.DefaultInterpolation = zs;
Qn.prototype.InterpolantFactoryMethodLinear = void 0;
Qn.prototype.InterpolantFactoryMethodSmooth = void 0;
var Ba = class extends zt {
};
Ba.prototype.ValueTypeName = "color";
var Ar = class extends zt {
};
Ar.prototype.ValueTypeName = "number";
var Dh = class extends cn {
    constructor(e, t, n, i){
        super(e, t, n, i);
    }
    interpolate_(e, t, n, i) {
        let r = this.resultBuffer, o = this.sampleValues, a = this.valueSize, l = (n - t) / (i - t), c = e * a;
        for(let h = c + a; c !== h; c += 4)gt.slerpFlat(r, 0, o, c - a, o, c, l);
        return r;
    }
}, Wi = class extends zt {
    InterpolantFactoryMethodLinear(e) {
        return new Dh(this.times, this.values, this.getValueSize(), e);
    }
};
Wi.prototype.ValueTypeName = "quaternion";
Wi.prototype.DefaultInterpolation = Us;
Wi.prototype.InterpolantFactoryMethodSmooth = void 0;
var Kn = class extends zt {
};
Kn.prototype.ValueTypeName = "string";
Kn.prototype.ValueBufferType = Array;
Kn.prototype.DefaultInterpolation = zs;
Kn.prototype.InterpolantFactoryMethodLinear = void 0;
Kn.prototype.InterpolantFactoryMethodSmooth = void 0;
var Cr = class extends zt {
};
Cr.prototype.ValueTypeName = "vector";
var Lr = class {
    constructor(e, t = -1, n, i = ua){
        this.name = e, this.tracks = n, this.duration = t, this.blendMode = i, this.uuid = Et(), this.duration < 0 && this.resetDuration();
    }
    static parse(e) {
        let t = [], n = e.tracks, i = 1 / (e.fps || 1);
        for(let o = 0, a = n.length; o !== a; ++o)t.push(ay(n[o]).scale(i));
        let r = new this(e.name, e.duration, t, e.blendMode);
        return r.uuid = e.uuid, r;
    }
    static toJSON(e) {
        let t = [], n = e.tracks, i = {
            name: e.name,
            duration: e.duration,
            tracks: t,
            uuid: e.uuid,
            blendMode: e.blendMode
        };
        for(let r = 0, o = n.length; r !== o; ++r)t.push(zt.toJSON(n[r]));
        return i;
    }
    static CreateFromMorphTargetSequence(e, t, n, i) {
        let r = t.length, o = [];
        for(let a = 0; a < r; a++){
            let l = [], c = [];
            l.push((a + r - 1) % r, a, (a + 1) % r), c.push(0, 1, 0);
            let h = Ze.getKeyframeOrder(l);
            l = Ze.sortedArray(l, 1, h), c = Ze.sortedArray(c, 1, h), !i && l[0] === 0 && (l.push(r), c.push(c[0])), o.push(new Ar(".morphTargetInfluences[" + t[a].name + "]", l, c).scale(1 / n));
        }
        return new this(e, -1, o);
    }
    static findByName(e, t) {
        let n = e;
        if (!Array.isArray(e)) {
            let i = e;
            n = i.geometry && i.geometry.animations || i.animations;
        }
        for(let i1 = 0; i1 < n.length; i1++)if (n[i1].name === t) return n[i1];
        return null;
    }
    static CreateClipsFromMorphTargetSequences(e, t, n) {
        let i = {}, r = /^([\w-]*?)([\d]+)$/;
        for(let a = 0, l = e.length; a < l; a++){
            let c = e[a], h = c.name.match(r);
            if (h && h.length > 1) {
                let u = h[1], d = i[u];
                d || (i[u] = d = []), d.push(c);
            }
        }
        let o = [];
        for(let a1 in i)o.push(this.CreateFromMorphTargetSequence(a1, i[a1], t, n));
        return o;
    }
    static parseAnimation(e, t) {
        if (!e) return console.error("THREE.AnimationClip: No animation in JSONLoader data."), null;
        let n = function(u, d, f, m, x) {
            if (f.length !== 0) {
                let v = [], g = [];
                Ze.flattenJSON(f, v, g, m), v.length !== 0 && x.push(new u(d, v, g));
            }
        }, i = [], r = e.name || "default", o = e.fps || 30, a = e.blendMode, l = e.length || -1, c = e.hierarchy || [];
        for(let u = 0; u < c.length; u++){
            let d = c[u].keys;
            if (!(!d || d.length === 0)) if (d[0].morphTargets) {
                let f = {}, m;
                for(m = 0; m < d.length; m++)if (d[m].morphTargets) for(let x = 0; x < d[m].morphTargets.length; x++)f[d[m].morphTargets[x]] = -1;
                for(let x1 in f){
                    let v = [], g = [];
                    for(let p = 0; p !== d[m].morphTargets.length; ++p){
                        let _ = d[m];
                        v.push(_.time), g.push(_.morphTarget === x1 ? 1 : 0);
                    }
                    i.push(new Ar(".morphTargetInfluence[" + x1 + "]", v, g));
                }
                l = f.length * (o || 1);
            } else {
                let f1 = ".bones[" + t[u].name + "]";
                n(Cr, f1 + ".position", d, "pos", i), n(Wi, f1 + ".quaternion", d, "rot", i), n(Cr, f1 + ".scale", d, "scl", i);
            }
        }
        return i.length === 0 ? null : new this(r, l, i, a);
    }
    resetDuration() {
        let e = this.tracks, t = 0;
        for(let n = 0, i = e.length; n !== i; ++n){
            let r = this.tracks[n];
            t = Math.max(t, r.times[r.times.length - 1]);
        }
        return this.duration = t, this;
    }
    trim() {
        for(let e = 0; e < this.tracks.length; e++)this.tracks[e].trim(0, this.duration);
        return this;
    }
    validate() {
        let e = !0;
        for(let t = 0; t < this.tracks.length; t++)e = e && this.tracks[t].validate();
        return e;
    }
    optimize() {
        for(let e = 0; e < this.tracks.length; e++)this.tracks[e].optimize();
        return this;
    }
    clone() {
        let e = [];
        for(let t = 0; t < this.tracks.length; t++)e.push(this.tracks[t].clone());
        return new this.constructor(this.name, this.duration, e, this.blendMode);
    }
    toJSON() {
        return this.constructor.toJSON(this);
    }
};
function oy(s) {
    switch(s.toLowerCase()){
        case "scalar":
        case "double":
        case "float":
        case "number":
        case "integer":
            return Ar;
        case "vector":
        case "vector2":
        case "vector3":
        case "vector4":
            return Cr;
        case "color":
            return Ba;
        case "quaternion":
            return Wi;
        case "bool":
        case "boolean":
            return Qn;
        case "string":
            return Kn;
    }
    throw new Error("THREE.KeyframeTrack: Unsupported typeName: " + s);
}
function ay(s) {
    if (s.type === void 0) throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");
    let e = oy(s.type);
    if (s.times === void 0) {
        let t = [], n = [];
        Ze.flattenJSON(s.keys, t, n, "value"), s.times = t, s.values = n;
    }
    return e.parse !== void 0 ? e.parse(s) : new e(s.name, s.times, s.values, s.interpolation);
}
var Ni = {
    enabled: !1,
    files: {},
    add: function(s, e) {
        this.enabled !== !1 && (this.files[s] = e);
    },
    get: function(s) {
        if (this.enabled !== !1) return this.files[s];
    },
    remove: function(s) {
        delete this.files[s];
    },
    clear: function() {
        this.files = {};
    }
}, za = class {
    constructor(e, t, n){
        let i = this, r = !1, o = 0, a = 0, l, c = [];
        this.onStart = void 0, this.onLoad = e, this.onProgress = t, this.onError = n, this.itemStart = function(h) {
            a++, r === !1 && i.onStart !== void 0 && i.onStart(h, o, a), r = !0;
        }, this.itemEnd = function(h) {
            o++, i.onProgress !== void 0 && i.onProgress(h, o, a), o === a && (r = !1, i.onLoad !== void 0 && i.onLoad());
        }, this.itemError = function(h) {
            i.onError !== void 0 && i.onError(h);
        }, this.resolveURL = function(h) {
            return l ? l(h) : h;
        }, this.setURLModifier = function(h) {
            return l = h, this;
        }, this.addHandler = function(h, u) {
            return c.push(h, u), this;
        }, this.removeHandler = function(h) {
            let u = c.indexOf(h);
            return u !== -1 && c.splice(u, 2), this;
        }, this.getHandler = function(h) {
            for(let u = 0, d = c.length; u < d; u += 2){
                let f = c[u], m = c[u + 1];
                if (f.global && (f.lastIndex = 0), f.test(h)) return m;
            }
            return null;
        };
    }
}, ly = new za, bt = class {
    constructor(e){
        this.manager = e !== void 0 ? e : ly, this.crossOrigin = "anonymous", this.withCredentials = !1, this.path = "", this.resourcePath = "", this.requestHeader = {};
    }
    load() {}
    loadAsync(e, t) {
        let n = this;
        return new Promise(function(i, r) {
            n.load(e, i, t, r);
        });
    }
    parse() {}
    setCrossOrigin(e) {
        return this.crossOrigin = e, this;
    }
    setWithCredentials(e) {
        return this.withCredentials = e, this;
    }
    setPath(e) {
        return this.path = e, this;
    }
    setResourcePath(e) {
        return this.resourcePath = e, this;
    }
    setRequestHeader(e) {
        return this.requestHeader = e, this;
    }
}, tn = {}, Yt = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        e === void 0 && (e = ""), this.path !== void 0 && (e = this.path + e), e = this.manager.resolveURL(e);
        let r = Ni.get(e);
        if (r !== void 0) return this.manager.itemStart(e), setTimeout(()=>{
            t && t(r), this.manager.itemEnd(e);
        }, 0), r;
        if (tn[e] !== void 0) {
            tn[e].push({
                onLoad: t,
                onProgress: n,
                onError: i
            });
            return;
        }
        tn[e] = [], tn[e].push({
            onLoad: t,
            onProgress: n,
            onError: i
        });
        let o = new Request(e, {
            headers: new Headers(this.requestHeader),
            credentials: this.withCredentials ? "include" : "same-origin"
        });
        fetch(o).then((a)=>{
            if (a.status === 200 || a.status === 0) {
                if (a.status === 0 && console.warn("THREE.FileLoader: HTTP Status 0 received."), typeof ReadableStream > "u" || a.body.getReader === void 0) return a;
                let l = tn[e], c = a.body.getReader(), h = a.headers.get("Content-Length"), u = h ? parseInt(h) : 0, d = u !== 0, f = 0, m = new ReadableStream({
                    start (x) {
                        v();
                        function v() {
                            c.read().then(({ done: g , value: p  })=>{
                                if (g) x.close();
                                else {
                                    f += p.byteLength;
                                    let _ = new ProgressEvent("progress", {
                                        lengthComputable: d,
                                        loaded: f,
                                        total: u
                                    });
                                    for(let y = 0, b = l.length; y < b; y++){
                                        let A = l[y];
                                        A.onProgress && A.onProgress(_);
                                    }
                                    x.enqueue(p), v();
                                }
                            });
                        }
                    }
                });
                return new Response(m);
            } else throw Error(`fetch for "${a.url}" responded with ${a.status}: ${a.statusText}`);
        }).then((a)=>{
            switch(this.responseType){
                case "arraybuffer":
                    return a.arrayBuffer();
                case "blob":
                    return a.blob();
                case "document":
                    return a.text().then((l)=>new DOMParser().parseFromString(l, this.mimeType));
                case "json":
                    return a.json();
                default:
                    return a.text();
            }
        }).then((a)=>{
            Ni.add(e, a);
            let l = tn[e];
            delete tn[e];
            for(let c = 0, h = l.length; c < h; c++){
                let u = l[c];
                u.onLoad && u.onLoad(a);
            }
        }).catch((a)=>{
            let l = tn[e];
            if (l === void 0) throw this.manager.itemError(e), a;
            delete tn[e];
            for(let c = 0, h = l.length; c < h; c++){
                let u = l[c];
                u.onError && u.onError(a);
            }
            this.manager.itemError(e);
        }).finally(()=>{
            this.manager.itemEnd(e);
        }), this.manager.itemStart(e);
    }
    setResponseType(e) {
        return this.responseType = e, this;
    }
    setMimeType(e) {
        return this.mimeType = e, this;
    }
}, cy = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, o = new Yt(this.manager);
        o.setPath(this.path), o.setRequestHeader(this.requestHeader), o.setWithCredentials(this.withCredentials), o.load(e, function(a) {
            try {
                t(r.parse(JSON.parse(a)));
            } catch (l) {
                i ? i(l) : console.error(l), r.manager.itemError(e);
            }
        }, n, i);
    }
    parse(e) {
        let t = [];
        for(let n = 0; n < e.length; n++){
            let i = Lr.parse(e[n]);
            t.push(i);
        }
        return t;
    }
}, hy = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, o = [], a = new va, l = new Yt(this.manager);
        l.setPath(this.path), l.setResponseType("arraybuffer"), l.setRequestHeader(this.requestHeader), l.setWithCredentials(r.withCredentials);
        let c = 0;
        function h(u) {
            l.load(e[u], function(d) {
                let f = r.parse(d, !0);
                o[u] = {
                    width: f.width,
                    height: f.height,
                    format: f.format,
                    mipmaps: f.mipmaps
                }, c += 1, c === 6 && (f.mipmapCount === 1 && (a.minFilter = tt), a.image = o, a.format = f.format, a.needsUpdate = !0, t && t(a));
            }, n, i);
        }
        if (Array.isArray(e)) for(let u = 0, d = e.length; u < d; ++u)h(u);
        else l.load(e, function(u) {
            let d = r.parse(u, !0);
            if (d.isCubemap) {
                let f = d.mipmaps.length / d.mipmapCount;
                for(let m = 0; m < f; m++){
                    o[m] = {
                        mipmaps: []
                    };
                    for(let x = 0; x < d.mipmapCount; x++)o[m].mipmaps.push(d.mipmaps[m * d.mipmapCount + x]), o[m].format = d.format, o[m].width = d.width, o[m].height = d.height;
                }
                a.image = o;
            } else a.image.width = d.width, a.image.height = d.height, a.mipmaps = d.mipmaps;
            d.mipmapCount === 1 && (a.minFilter = tt), a.format = d.format, a.needsUpdate = !0, t && t(a);
        }, n, i);
        return a;
    }
}, Rr = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        this.path !== void 0 && (e = this.path + e), e = this.manager.resolveURL(e);
        let r = this, o = Ni.get(e);
        if (o !== void 0) return r.manager.itemStart(e), setTimeout(function() {
            t && t(o), r.manager.itemEnd(e);
        }, 0), o;
        let a = qs("img");
        function l() {
            h(), Ni.add(e, this), t && t(this), r.manager.itemEnd(e);
        }
        function c(u) {
            h(), i && i(u), r.manager.itemError(e), r.manager.itemEnd(e);
        }
        function h() {
            a.removeEventListener("load", l, !1), a.removeEventListener("error", c, !1);
        }
        return a.addEventListener("load", l, !1), a.addEventListener("error", c, !1), e.substr(0, 5) !== "data:" && this.crossOrigin !== void 0 && (a.crossOrigin = this.crossOrigin), r.manager.itemStart(e), a.src = e, a;
    }
}, Fh = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = new ki, o = new Rr(this.manager);
        o.setCrossOrigin(this.crossOrigin), o.setPath(this.path);
        let a = 0;
        function l(c) {
            o.load(e[c], function(h) {
                r.images[c] = h, a++, a === 6 && (r.needsUpdate = !0, t && t(r));
            }, void 0, i);
        }
        for(let c = 0; c < e.length; ++c)l(c);
        return r;
    }
}, Nh = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, o = new qn, a = new Yt(this.manager);
        return a.setResponseType("arraybuffer"), a.setRequestHeader(this.requestHeader), a.setPath(this.path), a.setWithCredentials(r.withCredentials), a.load(e, function(l) {
            let c = r.parse(l);
            !c || (c.image !== void 0 ? o.image = c.image : c.data !== void 0 && (o.image.width = c.width, o.image.height = c.height, o.image.data = c.data), o.wrapS = c.wrapS !== void 0 ? c.wrapS : vt, o.wrapT = c.wrapT !== void 0 ? c.wrapT : vt, o.magFilter = c.magFilter !== void 0 ? c.magFilter : tt, o.minFilter = c.minFilter !== void 0 ? c.minFilter : tt, o.anisotropy = c.anisotropy !== void 0 ? c.anisotropy : 1, c.encoding !== void 0 && (o.encoding = c.encoding), c.flipY !== void 0 && (o.flipY = c.flipY), c.format !== void 0 && (o.format = c.format), c.type !== void 0 && (o.type = c.type), c.mipmaps !== void 0 && (o.mipmaps = c.mipmaps, o.minFilter = Ui), c.mipmapCount === 1 && (o.minFilter = tt), c.generateMipmaps !== void 0 && (o.generateMipmaps = c.generateMipmaps), o.needsUpdate = !0, t && t(o, c));
        }, n, i), o;
    }
}, Bh = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = new ot, o = new Rr(this.manager);
        return o.setCrossOrigin(this.crossOrigin), o.setPath(this.path), o.load(e, function(a) {
            r.image = a, r.needsUpdate = !0, t !== void 0 && t(r);
        }, n, i), r;
    }
}, Bt = class extends Ne {
    constructor(e, t = 1){
        super();
        this.type = "Light", this.color = new ae(e), this.intensity = t;
    }
    dispose() {}
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.intensity = e.intensity, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.color = this.color.getHex(), t.object.intensity = this.intensity, this.groundColor !== void 0 && (t.object.groundColor = this.groundColor.getHex()), this.distance !== void 0 && (t.object.distance = this.distance), this.angle !== void 0 && (t.object.angle = this.angle), this.decay !== void 0 && (t.object.decay = this.decay), this.penumbra !== void 0 && (t.object.penumbra = this.penumbra), this.shadow !== void 0 && (t.object.shadow = this.shadow.toJSON()), t;
    }
};
Bt.prototype.isLight = !0;
var Ua = class extends Bt {
    constructor(e, t, n){
        super(e, n);
        this.type = "HemisphereLight", this.position.copy(Ne.DefaultUp), this.updateMatrix(), this.groundColor = new ae(t);
    }
    copy(e) {
        return Bt.prototype.copy.call(this, e), this.groundColor.copy(e.groundColor), this;
    }
};
Ua.prototype.isHemisphereLight = !0;
var _c = new pe, Mc = new M, bc = new M, mo = class {
    constructor(e){
        this.camera = e, this.bias = 0, this.normalBias = 0, this.radius = 1, this.blurSamples = 8, this.mapSize = new X(512, 512), this.map = null, this.mapPass = null, this.matrix = new pe, this.autoUpdate = !0, this.needsUpdate = !1, this._frustum = new Dr, this._frameExtents = new X(1, 1), this._viewportCount = 1, this._viewports = [
            new Ve(0, 0, 1, 1)
        ];
    }
    getViewportCount() {
        return this._viewportCount;
    }
    getFrustum() {
        return this._frustum;
    }
    updateMatrices(e) {
        let t = this.camera, n = this.matrix;
        Mc.setFromMatrixPosition(e.matrixWorld), t.position.copy(Mc), bc.setFromMatrixPosition(e.target.matrixWorld), t.lookAt(bc), t.updateMatrixWorld(), _c.multiplyMatrices(t.projectionMatrix, t.matrixWorldInverse), this._frustum.setFromProjectionMatrix(_c), n.set(.5, 0, 0, .5, 0, .5, 0, .5, 0, 0, .5, .5, 0, 0, 0, 1), n.multiply(t.projectionMatrix), n.multiply(t.matrixWorldInverse);
    }
    getViewport(e) {
        return this._viewports[e];
    }
    getFrameExtents() {
        return this._frameExtents;
    }
    dispose() {
        this.map && this.map.dispose(), this.mapPass && this.mapPass.dispose();
    }
    copy(e) {
        return this.camera = e.camera.clone(), this.bias = e.bias, this.radius = e.radius, this.mapSize.copy(e.mapSize), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    toJSON() {
        let e = {};
        return this.bias !== 0 && (e.bias = this.bias), this.normalBias !== 0 && (e.normalBias = this.normalBias), this.radius !== 1 && (e.radius = this.radius), (this.mapSize.x !== 512 || this.mapSize.y !== 512) && (e.mapSize = this.mapSize.toArray()), e.camera = this.camera.toJSON(!1).object, delete e.camera.matrix, e;
    }
}, Oa = class extends mo {
    constructor(){
        super(new ut(50, 1, .5, 500));
        this.focus = 1;
    }
    updateMatrices(e) {
        let t = this.camera, n = dr * 2 * e.angle * this.focus, i = this.mapSize.width / this.mapSize.height, r = e.distance || t.far;
        (n !== t.fov || i !== t.aspect || r !== t.far) && (t.fov = n, t.aspect = i, t.far = r, t.updateProjectionMatrix()), super.updateMatrices(e);
    }
    copy(e) {
        return super.copy(e), this.focus = e.focus, this;
    }
};
Oa.prototype.isSpotLightShadow = !0;
var Ha = class extends Bt {
    constructor(e, t, n = 0, i = Math.PI / 3, r = 0, o = 1){
        super(e, t);
        this.type = "SpotLight", this.position.copy(Ne.DefaultUp), this.updateMatrix(), this.target = new Ne, this.distance = n, this.angle = i, this.penumbra = r, this.decay = o, this.shadow = new Oa;
    }
    get power() {
        return this.intensity * Math.PI;
    }
    set power(e) {
        this.intensity = e / Math.PI;
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(e) {
        return super.copy(e), this.distance = e.distance, this.angle = e.angle, this.penumbra = e.penumbra, this.decay = e.decay, this.target = e.target.clone(), this.shadow = e.shadow.clone(), this;
    }
};
Ha.prototype.isSpotLight = !0;
var wc = new pe, nr = new M, jo = new M, ka = class extends mo {
    constructor(){
        super(new ut(90, 1, .5, 500));
        this._frameExtents = new X(4, 2), this._viewportCount = 6, this._viewports = [
            new Ve(2, 1, 1, 1),
            new Ve(0, 1, 1, 1),
            new Ve(3, 1, 1, 1),
            new Ve(1, 1, 1, 1),
            new Ve(3, 0, 1, 1),
            new Ve(1, 0, 1, 1)
        ], this._cubeDirections = [
            new M(1, 0, 0),
            new M(-1, 0, 0),
            new M(0, 0, 1),
            new M(0, 0, -1),
            new M(0, 1, 0),
            new M(0, -1, 0)
        ], this._cubeUps = [
            new M(0, 1, 0),
            new M(0, 1, 0),
            new M(0, 1, 0),
            new M(0, 1, 0),
            new M(0, 0, 1),
            new M(0, 0, -1)
        ];
    }
    updateMatrices(e, t = 0) {
        let n = this.camera, i = this.matrix, r = e.distance || n.far;
        r !== n.far && (n.far = r, n.updateProjectionMatrix()), nr.setFromMatrixPosition(e.matrixWorld), n.position.copy(nr), jo.copy(n.position), jo.add(this._cubeDirections[t]), n.up.copy(this._cubeUps[t]), n.lookAt(jo), n.updateMatrixWorld(), i.makeTranslation(-nr.x, -nr.y, -nr.z), wc.multiplyMatrices(n.projectionMatrix, n.matrixWorldInverse), this._frustum.setFromProjectionMatrix(wc);
    }
};
ka.prototype.isPointLightShadow = !0;
var Ga = class extends Bt {
    constructor(e, t, n = 0, i = 1){
        super(e, t);
        this.type = "PointLight", this.distance = n, this.decay = i, this.shadow = new ka;
    }
    get power() {
        return this.intensity * 4 * Math.PI;
    }
    set power(e) {
        this.intensity = e / (4 * Math.PI);
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(e) {
        return super.copy(e), this.distance = e.distance, this.decay = e.decay, this.shadow = e.shadow.clone(), this;
    }
};
Ga.prototype.isPointLight = !0;
var Va = class extends mo {
    constructor(){
        super(new Fr(-5, 5, 5, -5, .5, 500));
    }
};
Va.prototype.isDirectionalLightShadow = !0;
var Wa = class extends Bt {
    constructor(e, t){
        super(e, t);
        this.type = "DirectionalLight", this.position.copy(Ne.DefaultUp), this.updateMatrix(), this.target = new Ne, this.shadow = new Va;
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(e) {
        return super.copy(e), this.target = e.target.clone(), this.shadow = e.shadow.clone(), this;
    }
};
Wa.prototype.isDirectionalLight = !0;
var qa = class extends Bt {
    constructor(e, t){
        super(e, t);
        this.type = "AmbientLight";
    }
};
qa.prototype.isAmbientLight = !0;
var Xa = class extends Bt {
    constructor(e, t, n = 10, i = 10){
        super(e, t);
        this.type = "RectAreaLight", this.width = n, this.height = i;
    }
    get power() {
        return this.intensity * this.width * this.height * Math.PI;
    }
    set power(e) {
        this.intensity = e / (this.width * this.height * Math.PI);
    }
    copy(e) {
        return super.copy(e), this.width = e.width, this.height = e.height, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.width = this.width, t.object.height = this.height, t;
    }
};
Xa.prototype.isRectAreaLight = !0;
var Ja = class {
    constructor(){
        this.coefficients = [];
        for(let e = 0; e < 9; e++)this.coefficients.push(new M);
    }
    set(e) {
        for(let t = 0; t < 9; t++)this.coefficients[t].copy(e[t]);
        return this;
    }
    zero() {
        for(let e = 0; e < 9; e++)this.coefficients[e].set(0, 0, 0);
        return this;
    }
    getAt(e, t) {
        let n = e.x, i = e.y, r = e.z, o = this.coefficients;
        return t.copy(o[0]).multiplyScalar(.282095), t.addScaledVector(o[1], .488603 * i), t.addScaledVector(o[2], .488603 * r), t.addScaledVector(o[3], .488603 * n), t.addScaledVector(o[4], 1.092548 * (n * i)), t.addScaledVector(o[5], 1.092548 * (i * r)), t.addScaledVector(o[6], .315392 * (3 * r * r - 1)), t.addScaledVector(o[7], 1.092548 * (n * r)), t.addScaledVector(o[8], .546274 * (n * n - i * i)), t;
    }
    getIrradianceAt(e, t) {
        let n = e.x, i = e.y, r = e.z, o = this.coefficients;
        return t.copy(o[0]).multiplyScalar(.886227), t.addScaledVector(o[1], 2 * .511664 * i), t.addScaledVector(o[2], 2 * .511664 * r), t.addScaledVector(o[3], 2 * .511664 * n), t.addScaledVector(o[4], 2 * .429043 * n * i), t.addScaledVector(o[5], 2 * .429043 * i * r), t.addScaledVector(o[6], .743125 * r * r - .247708), t.addScaledVector(o[7], 2 * .429043 * n * r), t.addScaledVector(o[8], .429043 * (n * n - i * i)), t;
    }
    add(e) {
        for(let t = 0; t < 9; t++)this.coefficients[t].add(e.coefficients[t]);
        return this;
    }
    addScaledSH(e, t) {
        for(let n = 0; n < 9; n++)this.coefficients[n].addScaledVector(e.coefficients[n], t);
        return this;
    }
    scale(e) {
        for(let t = 0; t < 9; t++)this.coefficients[t].multiplyScalar(e);
        return this;
    }
    lerp(e, t) {
        for(let n = 0; n < 9; n++)this.coefficients[n].lerp(e.coefficients[n], t);
        return this;
    }
    equals(e) {
        for(let t = 0; t < 9; t++)if (!this.coefficients[t].equals(e.coefficients[t])) return !1;
        return !0;
    }
    copy(e) {
        return this.set(e.coefficients);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    fromArray(e, t = 0) {
        let n = this.coefficients;
        for(let i = 0; i < 9; i++)n[i].fromArray(e, t + i * 3);
        return this;
    }
    toArray(e = [], t = 0) {
        let n = this.coefficients;
        for(let i = 0; i < 9; i++)n[i].toArray(e, t + i * 3);
        return e;
    }
    static getBasisAt(e, t) {
        let n = e.x, i = e.y, r = e.z;
        t[0] = .282095, t[1] = .488603 * i, t[2] = .488603 * r, t[3] = .488603 * n, t[4] = 1.092548 * n * i, t[5] = 1.092548 * i * r, t[6] = .315392 * (3 * r * r - 1), t[7] = 1.092548 * n * r, t[8] = .546274 * (n * n - i * i);
    }
};
Ja.prototype.isSphericalHarmonics3 = !0;
var Hr = class extends Bt {
    constructor(e = new Ja, t = 1){
        super(void 0, t);
        this.sh = e;
    }
    copy(e) {
        return super.copy(e), this.sh.copy(e.sh), this;
    }
    fromJSON(e) {
        return this.intensity = e.intensity, this.sh.fromArray(e.sh), this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.sh = this.sh.toArray(), t;
    }
};
Hr.prototype.isLightProbe = !0;
var zh = class extends bt {
    constructor(e){
        super(e);
        this.textures = {};
    }
    load(e, t, n, i) {
        let r = this, o = new Yt(r.manager);
        o.setPath(r.path), o.setRequestHeader(r.requestHeader), o.setWithCredentials(r.withCredentials), o.load(e, function(a) {
            try {
                t(r.parse(JSON.parse(a)));
            } catch (l) {
                i ? i(l) : console.error(l), r.manager.itemError(e);
            }
        }, n, i);
    }
    parse(e) {
        let t = this.textures;
        function n(r) {
            return t[r] === void 0 && console.warn("THREE.MaterialLoader: Undefined texture", r), t[r];
        }
        let i = new sy[e.type];
        if (e.uuid !== void 0 && (i.uuid = e.uuid), e.name !== void 0 && (i.name = e.name), e.color !== void 0 && i.color !== void 0 && i.color.setHex(e.color), e.roughness !== void 0 && (i.roughness = e.roughness), e.metalness !== void 0 && (i.metalness = e.metalness), e.sheen !== void 0 && (i.sheen = e.sheen), e.sheenColor !== void 0 && (i.sheenColor = new ae().setHex(e.sheenColor)), e.sheenRoughness !== void 0 && (i.sheenRoughness = e.sheenRoughness), e.emissive !== void 0 && i.emissive !== void 0 && i.emissive.setHex(e.emissive), e.specular !== void 0 && i.specular !== void 0 && i.specular.setHex(e.specular), e.specularIntensity !== void 0 && (i.specularIntensity = e.specularIntensity), e.specularColor !== void 0 && i.specularColor !== void 0 && i.specularColor.setHex(e.specularColor), e.shininess !== void 0 && (i.shininess = e.shininess), e.clearcoat !== void 0 && (i.clearcoat = e.clearcoat), e.clearcoatRoughness !== void 0 && (i.clearcoatRoughness = e.clearcoatRoughness), e.transmission !== void 0 && (i.transmission = e.transmission), e.thickness !== void 0 && (i.thickness = e.thickness), e.attenuationDistance !== void 0 && (i.attenuationDistance = e.attenuationDistance), e.attenuationColor !== void 0 && i.attenuationColor !== void 0 && i.attenuationColor.setHex(e.attenuationColor), e.fog !== void 0 && (i.fog = e.fog), e.flatShading !== void 0 && (i.flatShading = e.flatShading), e.blending !== void 0 && (i.blending = e.blending), e.combine !== void 0 && (i.combine = e.combine), e.side !== void 0 && (i.side = e.side), e.shadowSide !== void 0 && (i.shadowSide = e.shadowSide), e.opacity !== void 0 && (i.opacity = e.opacity), e.format !== void 0 && (i.format = e.format), e.transparent !== void 0 && (i.transparent = e.transparent), e.alphaTest !== void 0 && (i.alphaTest = e.alphaTest), e.depthTest !== void 0 && (i.depthTest = e.depthTest), e.depthWrite !== void 0 && (i.depthWrite = e.depthWrite), e.colorWrite !== void 0 && (i.colorWrite = e.colorWrite), e.stencilWrite !== void 0 && (i.stencilWrite = e.stencilWrite), e.stencilWriteMask !== void 0 && (i.stencilWriteMask = e.stencilWriteMask), e.stencilFunc !== void 0 && (i.stencilFunc = e.stencilFunc), e.stencilRef !== void 0 && (i.stencilRef = e.stencilRef), e.stencilFuncMask !== void 0 && (i.stencilFuncMask = e.stencilFuncMask), e.stencilFail !== void 0 && (i.stencilFail = e.stencilFail), e.stencilZFail !== void 0 && (i.stencilZFail = e.stencilZFail), e.stencilZPass !== void 0 && (i.stencilZPass = e.stencilZPass), e.wireframe !== void 0 && (i.wireframe = e.wireframe), e.wireframeLinewidth !== void 0 && (i.wireframeLinewidth = e.wireframeLinewidth), e.wireframeLinecap !== void 0 && (i.wireframeLinecap = e.wireframeLinecap), e.wireframeLinejoin !== void 0 && (i.wireframeLinejoin = e.wireframeLinejoin), e.rotation !== void 0 && (i.rotation = e.rotation), e.linewidth !== 1 && (i.linewidth = e.linewidth), e.dashSize !== void 0 && (i.dashSize = e.dashSize), e.gapSize !== void 0 && (i.gapSize = e.gapSize), e.scale !== void 0 && (i.scale = e.scale), e.polygonOffset !== void 0 && (i.polygonOffset = e.polygonOffset), e.polygonOffsetFactor !== void 0 && (i.polygonOffsetFactor = e.polygonOffsetFactor), e.polygonOffsetUnits !== void 0 && (i.polygonOffsetUnits = e.polygonOffsetUnits), e.dithering !== void 0 && (i.dithering = e.dithering), e.alphaToCoverage !== void 0 && (i.alphaToCoverage = e.alphaToCoverage), e.premultipliedAlpha !== void 0 && (i.premultipliedAlpha = e.premultipliedAlpha), e.visible !== void 0 && (i.visible = e.visible), e.toneMapped !== void 0 && (i.toneMapped = e.toneMapped), e.userData !== void 0 && (i.userData = e.userData), e.vertexColors !== void 0 && (typeof e.vertexColors == "number" ? i.vertexColors = e.vertexColors > 0 : i.vertexColors = e.vertexColors), e.uniforms !== void 0) for(let r in e.uniforms){
            let o = e.uniforms[r];
            switch(i.uniforms[r] = {}, o.type){
                case "t":
                    i.uniforms[r].value = n(o.value);
                    break;
                case "c":
                    i.uniforms[r].value = new ae().setHex(o.value);
                    break;
                case "v2":
                    i.uniforms[r].value = new X().fromArray(o.value);
                    break;
                case "v3":
                    i.uniforms[r].value = new M().fromArray(o.value);
                    break;
                case "v4":
                    i.uniforms[r].value = new Ve().fromArray(o.value);
                    break;
                case "m3":
                    i.uniforms[r].value = new lt().fromArray(o.value);
                    break;
                case "m4":
                    i.uniforms[r].value = new pe().fromArray(o.value);
                    break;
                default:
                    i.uniforms[r].value = o.value;
            }
        }
        if (e.defines !== void 0 && (i.defines = e.defines), e.vertexShader !== void 0 && (i.vertexShader = e.vertexShader), e.fragmentShader !== void 0 && (i.fragmentShader = e.fragmentShader), e.extensions !== void 0) for(let r1 in e.extensions)i.extensions[r1] = e.extensions[r1];
        if (e.shading !== void 0 && (i.flatShading = e.shading === 1), e.size !== void 0 && (i.size = e.size), e.sizeAttenuation !== void 0 && (i.sizeAttenuation = e.sizeAttenuation), e.map !== void 0 && (i.map = n(e.map)), e.matcap !== void 0 && (i.matcap = n(e.matcap)), e.alphaMap !== void 0 && (i.alphaMap = n(e.alphaMap)), e.bumpMap !== void 0 && (i.bumpMap = n(e.bumpMap)), e.bumpScale !== void 0 && (i.bumpScale = e.bumpScale), e.normalMap !== void 0 && (i.normalMap = n(e.normalMap)), e.normalMapType !== void 0 && (i.normalMapType = e.normalMapType), e.normalScale !== void 0) {
            let r2 = e.normalScale;
            Array.isArray(r2) === !1 && (r2 = [
                r2,
                r2
            ]), i.normalScale = new X().fromArray(r2);
        }
        return e.displacementMap !== void 0 && (i.displacementMap = n(e.displacementMap)), e.displacementScale !== void 0 && (i.displacementScale = e.displacementScale), e.displacementBias !== void 0 && (i.displacementBias = e.displacementBias), e.roughnessMap !== void 0 && (i.roughnessMap = n(e.roughnessMap)), e.metalnessMap !== void 0 && (i.metalnessMap = n(e.metalnessMap)), e.emissiveMap !== void 0 && (i.emissiveMap = n(e.emissiveMap)), e.emissiveIntensity !== void 0 && (i.emissiveIntensity = e.emissiveIntensity), e.specularMap !== void 0 && (i.specularMap = n(e.specularMap)), e.specularIntensityMap !== void 0 && (i.specularIntensityMap = n(e.specularIntensityMap)), e.specularColorMap !== void 0 && (i.specularColorMap = n(e.specularColorMap)), e.envMap !== void 0 && (i.envMap = n(e.envMap)), e.envMapIntensity !== void 0 && (i.envMapIntensity = e.envMapIntensity), e.reflectivity !== void 0 && (i.reflectivity = e.reflectivity), e.refractionRatio !== void 0 && (i.refractionRatio = e.refractionRatio), e.lightMap !== void 0 && (i.lightMap = n(e.lightMap)), e.lightMapIntensity !== void 0 && (i.lightMapIntensity = e.lightMapIntensity), e.aoMap !== void 0 && (i.aoMap = n(e.aoMap)), e.aoMapIntensity !== void 0 && (i.aoMapIntensity = e.aoMapIntensity), e.gradientMap !== void 0 && (i.gradientMap = n(e.gradientMap)), e.clearcoatMap !== void 0 && (i.clearcoatMap = n(e.clearcoatMap)), e.clearcoatRoughnessMap !== void 0 && (i.clearcoatRoughnessMap = n(e.clearcoatRoughnessMap)), e.clearcoatNormalMap !== void 0 && (i.clearcoatNormalMap = n(e.clearcoatNormalMap)), e.clearcoatNormalScale !== void 0 && (i.clearcoatNormalScale = new X().fromArray(e.clearcoatNormalScale)), e.transmissionMap !== void 0 && (i.transmissionMap = n(e.transmissionMap)), e.thicknessMap !== void 0 && (i.thicknessMap = n(e.thicknessMap)), e.sheenColorMap !== void 0 && (i.sheenColorMap = n(e.sheenColorMap)), e.sheenRoughnessMap !== void 0 && (i.sheenRoughnessMap = n(e.sheenRoughnessMap)), i;
    }
    setTextures(e) {
        return this.textures = e, this;
    }
}, Gs = class {
    static decodeText(e) {
        if (typeof TextDecoder < "u") return new TextDecoder().decode(e);
        let t = "";
        for(let n = 0, i = e.length; n < i; n++)t += String.fromCharCode(e[n]);
        try {
            return decodeURIComponent(escape(t));
        } catch  {
            return t;
        }
    }
    static extractUrlBase(e) {
        let t = e.lastIndexOf("/");
        return t === -1 ? "./" : e.substr(0, t + 1);
    }
    static resolveURL(e, t) {
        return typeof e != "string" || e === "" ? "" : (/^https?:\/\//i.test(t) && /^\//.test(e) && (t = t.replace(/(^https?:\/\/[^\/]+).*/i, "$1")), /^(https?:)?\/\//i.test(e) || /^data:.*,.*$/i.test(e) || /^blob:.*$/i.test(e) ? e : t + e);
    }
}, Ya = class extends _e {
    constructor(){
        super();
        this.type = "InstancedBufferGeometry", this.instanceCount = 1 / 0;
    }
    copy(e) {
        return super.copy(e), this.instanceCount = e.instanceCount, this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    toJSON() {
        let e = super.toJSON(this);
        return e.instanceCount = this.instanceCount, e.isInstancedBufferGeometry = !0, e;
    }
};
Ya.prototype.isInstancedBufferGeometry = !0;
var Uh = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, o = new Yt(r.manager);
        o.setPath(r.path), o.setRequestHeader(r.requestHeader), o.setWithCredentials(r.withCredentials), o.load(e, function(a) {
            try {
                t(r.parse(JSON.parse(a)));
            } catch (l) {
                i ? i(l) : console.error(l), r.manager.itemError(e);
            }
        }, n, i);
    }
    parse(e) {
        let t = {}, n = {};
        function i(f, m) {
            if (t[m] !== void 0) return t[m];
            let v = f.interleavedBuffers[m], g = r(f, v.buffer), p = wi(v.type, g), _ = new $n(p, v.stride);
            return _.uuid = v.uuid, t[m] = _, _;
        }
        function r(f, m) {
            if (n[m] !== void 0) return n[m];
            let v = f.arrayBuffers[m], g = new Uint32Array(v).buffer;
            return n[m] = g, g;
        }
        let o = e.isInstancedBufferGeometry ? new Ya : new _e, a = e.data.index;
        if (a !== void 0) {
            let f = wi(a.type, a.array);
            o.setIndex(new Ue(f, 1));
        }
        let l = e.data.attributes;
        for(let f1 in l){
            let m = l[f1], x;
            if (m.isInterleavedBufferAttribute) {
                let v = i(e.data, m.data);
                x = new Sn(v, m.itemSize, m.offset, m.normalized);
            } else {
                let v1 = wi(m.type, m.array), g = m.isInstancedBufferAttribute ? Xn : Ue;
                x = new g(v1, m.itemSize, m.normalized);
            }
            m.name !== void 0 && (x.name = m.name), m.usage !== void 0 && x.setUsage(m.usage), m.updateRange !== void 0 && (x.updateRange.offset = m.updateRange.offset, x.updateRange.count = m.updateRange.count), o.setAttribute(f1, x);
        }
        let c = e.data.morphAttributes;
        if (c) for(let f2 in c){
            let m1 = c[f2], x1 = [];
            for(let v2 = 0, g1 = m1.length; v2 < g1; v2++){
                let p = m1[v2], _;
                if (p.isInterleavedBufferAttribute) {
                    let y = i(e.data, p.data);
                    _ = new Sn(y, p.itemSize, p.offset, p.normalized);
                } else {
                    let y1 = wi(p.type, p.array);
                    _ = new Ue(y1, p.itemSize, p.normalized);
                }
                p.name !== void 0 && (_.name = p.name), x1.push(_);
            }
            o.morphAttributes[f2] = x1;
        }
        e.data.morphTargetsRelative && (o.morphTargetsRelative = !0);
        let u = e.data.groups || e.data.drawcalls || e.data.offsets;
        if (u !== void 0) for(let f3 = 0, m2 = u.length; f3 !== m2; ++f3){
            let x2 = u[f3];
            o.addGroup(x2.start, x2.count, x2.materialIndex);
        }
        let d = e.data.boundingSphere;
        if (d !== void 0) {
            let f4 = new M;
            d.center !== void 0 && f4.fromArray(d.center), o.boundingSphere = new An(f4, d.radius);
        }
        return e.name && (o.name = e.name), e.userData && (o.userData = e.userData), o;
    }
}, uy = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, o = this.path === "" ? Gs.extractUrlBase(e) : this.path;
        this.resourcePath = this.resourcePath || o;
        let a = new Yt(this.manager);
        a.setPath(this.path), a.setRequestHeader(this.requestHeader), a.setWithCredentials(this.withCredentials), a.load(e, function(l) {
            let c = null;
            try {
                c = JSON.parse(l);
            } catch (u) {
                i !== void 0 && i(u), console.error("THREE:ObjectLoader: Can't parse " + e + ".", u.message);
                return;
            }
            let h = c.metadata;
            if (h === void 0 || h.type === void 0 || h.type.toLowerCase() === "geometry") {
                console.error("THREE.ObjectLoader: Can't load " + e);
                return;
            }
            r.parse(c, t);
        }, n, i);
    }
    async loadAsync(e, t) {
        let n = this, i = this.path === "" ? Gs.extractUrlBase(e) : this.path;
        this.resourcePath = this.resourcePath || i;
        let r = new Yt(this.manager);
        r.setPath(this.path), r.setRequestHeader(this.requestHeader), r.setWithCredentials(this.withCredentials);
        let o = await r.loadAsync(e, t), a = JSON.parse(o), l = a.metadata;
        if (l === void 0 || l.type === void 0 || l.type.toLowerCase() === "geometry") throw new Error("THREE.ObjectLoader: Can't load " + e);
        return await n.parseAsync(a);
    }
    parse(e, t) {
        let n = this.parseAnimations(e.animations), i = this.parseShapes(e.shapes), r = this.parseGeometries(e.geometries, i), o = this.parseImages(e.images, function() {
            t !== void 0 && t(c);
        }), a = this.parseTextures(e.textures, o), l = this.parseMaterials(e.materials, a), c = this.parseObject(e.object, r, l, a, n), h = this.parseSkeletons(e.skeletons, c);
        if (this.bindSkeletons(c, h), t !== void 0) {
            let u = !1;
            for(let d in o)if (o[d] instanceof HTMLImageElement) {
                u = !0;
                break;
            }
            u === !1 && t(c);
        }
        return c;
    }
    async parseAsync(e) {
        let t = this.parseAnimations(e.animations), n = this.parseShapes(e.shapes), i = this.parseGeometries(e.geometries, n), r = await this.parseImagesAsync(e.images), o = this.parseTextures(e.textures, r), a = this.parseMaterials(e.materials, o), l = this.parseObject(e.object, i, a, o, t), c = this.parseSkeletons(e.skeletons, l);
        return this.bindSkeletons(l, c), l;
    }
    parseShapes(e) {
        let t = {};
        if (e !== void 0) for(let n = 0, i = e.length; n < i; n++){
            let r = new Xt().fromJSON(e[n]);
            t[r.uuid] = r;
        }
        return t;
    }
    parseSkeletons(e, t) {
        let n = {}, i = {};
        if (t.traverse(function(r) {
            r.isBone && (i[r.uuid] = r);
        }), e !== void 0) for(let r = 0, o = e.length; r < o; r++){
            let a = new ao().fromJSON(e[r], i);
            n[a.uuid] = a;
        }
        return n;
    }
    parseGeometries(e, t) {
        let n = {};
        if (e !== void 0) {
            let i = new Uh;
            for(let r = 0, o = e.length; r < o; r++){
                let a, l = e[r];
                switch(l.type){
                    case "BufferGeometry":
                    case "InstancedBufferGeometry":
                        a = i.parse(l);
                        break;
                    case "Geometry":
                        console.error("THREE.ObjectLoader: The legacy Geometry type is no longer supported.");
                        break;
                    default:
                        l.type in vc ? a = vc[l.type].fromJSON(l, t) : console.warn(`THREE.ObjectLoader: Unsupported geometry type "${l.type}"`);
                }
                a.uuid = l.uuid, l.name !== void 0 && (a.name = l.name), a.isBufferGeometry === !0 && l.userData !== void 0 && (a.userData = l.userData), n[l.uuid] = a;
            }
        }
        return n;
    }
    parseMaterials(e, t) {
        let n = {}, i = {};
        if (e !== void 0) {
            let r = new zh;
            r.setTextures(t);
            for(let o = 0, a = e.length; o < a; o++){
                let l = e[o];
                if (l.type === "MultiMaterial") {
                    let c = [];
                    for(let h = 0; h < l.materials.length; h++){
                        let u = l.materials[h];
                        n[u.uuid] === void 0 && (n[u.uuid] = r.parse(u)), c.push(n[u.uuid]);
                    }
                    i[l.uuid] = c;
                } else n[l.uuid] === void 0 && (n[l.uuid] = r.parse(l)), i[l.uuid] = n[l.uuid];
            }
        }
        return i;
    }
    parseAnimations(e) {
        let t = {};
        if (e !== void 0) for(let n = 0; n < e.length; n++){
            let i = e[n], r = Lr.parse(i);
            t[r.uuid] = r;
        }
        return t;
    }
    parseImages(e, t) {
        let n = this, i = {}, r;
        function o(l) {
            return n.manager.itemStart(l), r.load(l, function() {
                n.manager.itemEnd(l);
            }, void 0, function() {
                n.manager.itemError(l), n.manager.itemEnd(l);
            });
        }
        function a(l) {
            if (typeof l == "string") {
                let c = l, h = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(c) ? c : n.resourcePath + c;
                return o(h);
            } else return l.data ? {
                data: wi(l.type, l.data),
                width: l.width,
                height: l.height
            } : null;
        }
        if (e !== void 0 && e.length > 0) {
            let l = new za(t);
            r = new Rr(l), r.setCrossOrigin(this.crossOrigin);
            for(let c = 0, h = e.length; c < h; c++){
                let u = e[c], d = u.url;
                if (Array.isArray(d)) {
                    i[u.uuid] = [];
                    for(let f = 0, m = d.length; f < m; f++){
                        let x = d[f], v = a(x);
                        v !== null && (v instanceof HTMLImageElement ? i[u.uuid].push(v) : i[u.uuid].push(new qn(v.data, v.width, v.height)));
                    }
                } else {
                    let f1 = a(u.url);
                    f1 !== null && (i[u.uuid] = f1);
                }
            }
        }
        return i;
    }
    async parseImagesAsync(e) {
        let t = this, n = {}, i;
        async function r(o) {
            if (typeof o == "string") {
                let a = o, l = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(a) ? a : t.resourcePath + a;
                return await i.loadAsync(l);
            } else return o.data ? {
                data: wi(o.type, o.data),
                width: o.width,
                height: o.height
            } : null;
        }
        if (e !== void 0 && e.length > 0) {
            i = new Rr(this.manager), i.setCrossOrigin(this.crossOrigin);
            for(let o = 0, a = e.length; o < a; o++){
                let l = e[o], c = l.url;
                if (Array.isArray(c)) {
                    n[l.uuid] = [];
                    for(let h = 0, u = c.length; h < u; h++){
                        let d = c[h], f = await r(d);
                        f !== null && (f instanceof HTMLImageElement ? n[l.uuid].push(f) : n[l.uuid].push(new qn(f.data, f.width, f.height)));
                    }
                } else {
                    let h1 = await r(l.url);
                    h1 !== null && (n[l.uuid] = h1);
                }
            }
        }
        return n;
    }
    parseTextures(e, t) {
        function n(r, o) {
            return typeof r == "number" ? r : (console.warn("THREE.ObjectLoader.parseTexture: Constant should be in numeric form.", r), o[r]);
        }
        let i = {};
        if (e !== void 0) for(let r = 0, o = e.length; r < o; r++){
            let a = e[r];
            a.image === void 0 && console.warn('THREE.ObjectLoader: No "image" specified for', a.uuid), t[a.image] === void 0 && console.warn("THREE.ObjectLoader: Undefined image", a.image);
            let l, c = t[a.image];
            Array.isArray(c) ? (l = new ki(c), c.length === 6 && (l.needsUpdate = !0)) : (c && c.data ? l = new qn(c.data, c.width, c.height) : l = new ot(c), c && (l.needsUpdate = !0)), l.uuid = a.uuid, a.name !== void 0 && (l.name = a.name), a.mapping !== void 0 && (l.mapping = n(a.mapping, dy)), a.offset !== void 0 && l.offset.fromArray(a.offset), a.repeat !== void 0 && l.repeat.fromArray(a.repeat), a.center !== void 0 && l.center.fromArray(a.center), a.rotation !== void 0 && (l.rotation = a.rotation), a.wrap !== void 0 && (l.wrapS = n(a.wrap[0], Sc), l.wrapT = n(a.wrap[1], Sc)), a.format !== void 0 && (l.format = a.format), a.type !== void 0 && (l.type = a.type), a.encoding !== void 0 && (l.encoding = a.encoding), a.minFilter !== void 0 && (l.minFilter = n(a.minFilter, Tc)), a.magFilter !== void 0 && (l.magFilter = n(a.magFilter, Tc)), a.anisotropy !== void 0 && (l.anisotropy = a.anisotropy), a.flipY !== void 0 && (l.flipY = a.flipY), a.premultiplyAlpha !== void 0 && (l.premultiplyAlpha = a.premultiplyAlpha), a.unpackAlignment !== void 0 && (l.unpackAlignment = a.unpackAlignment), a.userData !== void 0 && (l.userData = a.userData), i[a.uuid] = l;
        }
        return i;
    }
    parseObject(e, t, n, i, r) {
        let o;
        function a(d) {
            return t[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined geometry", d), t[d];
        }
        function l(d) {
            if (d !== void 0) {
                if (Array.isArray(d)) {
                    let f = [];
                    for(let m = 0, x = d.length; m < x; m++){
                        let v = d[m];
                        n[v] === void 0 && console.warn("THREE.ObjectLoader: Undefined material", v), f.push(n[v]);
                    }
                    return f;
                }
                return n[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined material", d), n[d];
            }
        }
        function c(d) {
            return i[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined texture", d), i[d];
        }
        let h, u;
        switch(e.type){
            case "Scene":
                o = new no, e.background !== void 0 && (Number.isInteger(e.background) ? o.background = new ae(e.background) : o.background = c(e.background)), e.environment !== void 0 && (o.environment = c(e.environment)), e.fog !== void 0 && (e.fog.type === "Fog" ? o.fog = new Br(e.fog.color, e.fog.near, e.fog.far) : e.fog.type === "FogExp2" && (o.fog = new Nr(e.fog.color, e.fog.density)));
                break;
            case "PerspectiveCamera":
                o = new ut(e.fov, e.aspect, e.near, e.far), e.focus !== void 0 && (o.focus = e.focus), e.zoom !== void 0 && (o.zoom = e.zoom), e.filmGauge !== void 0 && (o.filmGauge = e.filmGauge), e.filmOffset !== void 0 && (o.filmOffset = e.filmOffset), e.view !== void 0 && (o.view = Object.assign({}, e.view));
                break;
            case "OrthographicCamera":
                o = new Fr(e.left, e.right, e.top, e.bottom, e.near, e.far), e.zoom !== void 0 && (o.zoom = e.zoom), e.view !== void 0 && (o.view = Object.assign({}, e.view));
                break;
            case "AmbientLight":
                o = new qa(e.color, e.intensity);
                break;
            case "DirectionalLight":
                o = new Wa(e.color, e.intensity);
                break;
            case "PointLight":
                o = new Ga(e.color, e.intensity, e.distance, e.decay);
                break;
            case "RectAreaLight":
                o = new Xa(e.color, e.intensity, e.width, e.height);
                break;
            case "SpotLight":
                o = new Ha(e.color, e.intensity, e.distance, e.angle, e.penumbra, e.decay);
                break;
            case "HemisphereLight":
                o = new Ua(e.color, e.groundColor, e.intensity);
                break;
            case "LightProbe":
                o = new Hr().fromJSON(e);
                break;
            case "SkinnedMesh":
                h = a(e.geometry), u = l(e.material), o = new so(h, u), e.bindMode !== void 0 && (o.bindMode = e.bindMode), e.bindMatrix !== void 0 && o.bindMatrix.fromArray(e.bindMatrix), e.skeleton !== void 0 && (o.skeleton = e.skeleton);
                break;
            case "Mesh":
                h = a(e.geometry), u = l(e.material), o = new st(h, u);
                break;
            case "InstancedMesh":
                h = a(e.geometry), u = l(e.material);
                let d = e.count, f = e.instanceMatrix, m = e.instanceColor;
                o = new xa(h, u, d), o.instanceMatrix = new Xn(new Float32Array(f.array), 16), m !== void 0 && (o.instanceColor = new Xn(new Float32Array(m.array), m.itemSize));
                break;
            case "LOD":
                o = new bh;
                break;
            case "Line":
                o = new on(a(e.geometry), l(e.material));
                break;
            case "LineLoop":
                o = new ya(a(e.geometry), l(e.material));
                break;
            case "LineSegments":
                o = new wt(a(e.geometry), l(e.material));
                break;
            case "PointCloud":
            case "Points":
                o = new zr(a(e.geometry), l(e.material));
                break;
            case "Sprite":
                o = new ro(l(e.material));
                break;
            case "Group":
                o = new Hn;
                break;
            case "Bone":
                o = new oo;
                break;
            default:
                o = new Ne;
        }
        if (o.uuid = e.uuid, e.name !== void 0 && (o.name = e.name), e.matrix !== void 0 ? (o.matrix.fromArray(e.matrix), e.matrixAutoUpdate !== void 0 && (o.matrixAutoUpdate = e.matrixAutoUpdate), o.matrixAutoUpdate && o.matrix.decompose(o.position, o.quaternion, o.scale)) : (e.position !== void 0 && o.position.fromArray(e.position), e.rotation !== void 0 && o.rotation.fromArray(e.rotation), e.quaternion !== void 0 && o.quaternion.fromArray(e.quaternion), e.scale !== void 0 && o.scale.fromArray(e.scale)), e.castShadow !== void 0 && (o.castShadow = e.castShadow), e.receiveShadow !== void 0 && (o.receiveShadow = e.receiveShadow), e.shadow && (e.shadow.bias !== void 0 && (o.shadow.bias = e.shadow.bias), e.shadow.normalBias !== void 0 && (o.shadow.normalBias = e.shadow.normalBias), e.shadow.radius !== void 0 && (o.shadow.radius = e.shadow.radius), e.shadow.mapSize !== void 0 && o.shadow.mapSize.fromArray(e.shadow.mapSize), e.shadow.camera !== void 0 && (o.shadow.camera = this.parseObject(e.shadow.camera))), e.visible !== void 0 && (o.visible = e.visible), e.frustumCulled !== void 0 && (o.frustumCulled = e.frustumCulled), e.renderOrder !== void 0 && (o.renderOrder = e.renderOrder), e.userData !== void 0 && (o.userData = e.userData), e.layers !== void 0 && (o.layers.mask = e.layers), e.children !== void 0) {
            let d1 = e.children;
            for(let f1 = 0; f1 < d1.length; f1++)o.add(this.parseObject(d1[f1], t, n, i, r));
        }
        if (e.animations !== void 0) {
            let d2 = e.animations;
            for(let f2 = 0; f2 < d2.length; f2++){
                let m1 = d2[f2];
                o.animations.push(r[m1]);
            }
        }
        if (e.type === "LOD") {
            e.autoUpdate !== void 0 && (o.autoUpdate = e.autoUpdate);
            let d3 = e.levels;
            for(let f3 = 0; f3 < d3.length; f3++){
                let m2 = d3[f3], x = o.getObjectByProperty("uuid", m2.object);
                x !== void 0 && o.addLevel(x, m2.distance);
            }
        }
        return o;
    }
    bindSkeletons(e, t) {
        Object.keys(t).length !== 0 && e.traverse(function(n) {
            if (n.isSkinnedMesh === !0 && n.skeleton !== void 0) {
                let i = t[n.skeleton];
                i === void 0 ? console.warn("THREE.ObjectLoader: No skeleton found with UUID:", n.skeleton) : n.bind(i, n.bindMatrix);
            }
        });
    }
    setTexturePath(e) {
        return console.warn("THREE.ObjectLoader: .setTexturePath() has been renamed to .setResourcePath()."), this.setResourcePath(e);
    }
}, dy = {
    UVMapping: ha,
    CubeReflectionMapping: Bi,
    CubeRefractionMapping: zi,
    EquirectangularReflectionMapping: Ds,
    EquirectangularRefractionMapping: Fs,
    CubeUVReflectionMapping: Pr,
    CubeUVRefractionMapping: Ws
}, Sc = {
    RepeatWrapping: Ns,
    ClampToEdgeWrapping: vt,
    MirroredRepeatWrapping: Bs
}, Tc = {
    NearestFilter: rt,
    NearestMipmapNearestFilter: ta,
    NearestMipmapLinearFilter: na,
    LinearFilter: tt,
    LinearMipmapNearestFilter: Wc,
    LinearMipmapLinearFilter: Ui
}, Oh = class extends bt {
    constructor(e){
        super(e);
        typeof createImageBitmap > "u" && console.warn("THREE.ImageBitmapLoader: createImageBitmap() not supported."), typeof fetch > "u" && console.warn("THREE.ImageBitmapLoader: fetch() not supported."), this.options = {
            premultiplyAlpha: "none"
        };
    }
    setOptions(e) {
        return this.options = e, this;
    }
    load(e, t, n, i) {
        e === void 0 && (e = ""), this.path !== void 0 && (e = this.path + e), e = this.manager.resolveURL(e);
        let r = this, o = Ni.get(e);
        if (o !== void 0) return r.manager.itemStart(e), setTimeout(function() {
            t && t(o), r.manager.itemEnd(e);
        }, 0), o;
        let a = {};
        a.credentials = this.crossOrigin === "anonymous" ? "same-origin" : "include", a.headers = this.requestHeader, fetch(e, a).then(function(l) {
            return l.blob();
        }).then(function(l) {
            return createImageBitmap(l, Object.assign(r.options, {
                colorSpaceConversion: "none"
            }));
        }).then(function(l) {
            Ni.add(e, l), t && t(l), r.manager.itemEnd(e);
        }).catch(function(l) {
            i && i(l), r.manager.itemError(e), r.manager.itemEnd(e);
        }), r.manager.itemStart(e);
    }
};
Oh.prototype.isImageBitmapLoader = !0;
var Ss, Hh = {
    getContext: function() {
        return Ss === void 0 && (Ss = new (window.AudioContext || window.webkitAudioContext)), Ss;
    },
    setContext: function(s) {
        Ss = s;
    }
}, kh = class extends bt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, o = new Yt(this.manager);
        o.setResponseType("arraybuffer"), o.setPath(this.path), o.setRequestHeader(this.requestHeader), o.setWithCredentials(this.withCredentials), o.load(e, function(a) {
            try {
                let l = a.slice(0);
                Hh.getContext().decodeAudioData(l, function(h) {
                    t(h);
                });
            } catch (l1) {
                i ? i(l1) : console.error(l1), r.manager.itemError(e);
            }
        }, n, i);
    }
}, Gh = class extends Hr {
    constructor(e, t, n = 1){
        super(void 0, n);
        let i = new ae().set(e), r = new ae().set(t), o = new M(i.r, i.g, i.b), a = new M(r.r, r.g, r.b), l = Math.sqrt(Math.PI), c = l * Math.sqrt(.75);
        this.sh.coefficients[0].copy(o).add(a).multiplyScalar(l), this.sh.coefficients[1].copy(o).sub(a).multiplyScalar(c);
    }
};
Gh.prototype.isHemisphereLightProbe = !0;
var Vh = class extends Hr {
    constructor(e, t = 1){
        super(void 0, t);
        let n = new ae().set(e);
        this.sh.coefficients[0].set(n.r, n.g, n.b).multiplyScalar(2 * Math.sqrt(Math.PI));
    }
};
Vh.prototype.isAmbientLightProbe = !0;
var Ec = new pe, Ac = new pe, Fn = new pe, fy = class {
    constructor(){
        this.type = "StereoCamera", this.aspect = 1, this.eyeSep = .064, this.cameraL = new ut, this.cameraL.layers.enable(1), this.cameraL.matrixAutoUpdate = !1, this.cameraR = new ut, this.cameraR.layers.enable(2), this.cameraR.matrixAutoUpdate = !1, this._cache = {
            focus: null,
            fov: null,
            aspect: null,
            near: null,
            far: null,
            zoom: null,
            eyeSep: null
        };
    }
    update(e) {
        let t = this._cache;
        if (t.focus !== e.focus || t.fov !== e.fov || t.aspect !== e.aspect * this.aspect || t.near !== e.near || t.far !== e.far || t.zoom !== e.zoom || t.eyeSep !== this.eyeSep) {
            t.focus = e.focus, t.fov = e.fov, t.aspect = e.aspect * this.aspect, t.near = e.near, t.far = e.far, t.zoom = e.zoom, t.eyeSep = this.eyeSep, Fn.copy(e.projectionMatrix);
            let i = t.eyeSep / 2, r = i * t.near / t.focus, o = t.near * Math.tan(Wn * t.fov * .5) / t.zoom, a, l;
            Ac.elements[12] = -i, Ec.elements[12] = i, a = -o * t.aspect + r, l = o * t.aspect + r, Fn.elements[0] = 2 * t.near / (l - a), Fn.elements[8] = (l + a) / (l - a), this.cameraL.projectionMatrix.copy(Fn), a = -o * t.aspect - r, l = o * t.aspect - r, Fn.elements[0] = 2 * t.near / (l - a), Fn.elements[8] = (l + a) / (l - a), this.cameraR.projectionMatrix.copy(Fn);
        }
        this.cameraL.matrixWorld.copy(e.matrixWorld).multiply(Ac), this.cameraR.matrixWorld.copy(e.matrixWorld).multiply(Ec);
    }
}, Wh = class {
    constructor(e = !0){
        this.autoStart = e, this.startTime = 0, this.oldTime = 0, this.elapsedTime = 0, this.running = !1;
    }
    start() {
        this.startTime = Cc(), this.oldTime = this.startTime, this.elapsedTime = 0, this.running = !0;
    }
    stop() {
        this.getElapsedTime(), this.running = !1, this.autoStart = !1;
    }
    getElapsedTime() {
        return this.getDelta(), this.elapsedTime;
    }
    getDelta() {
        let e = 0;
        if (this.autoStart && !this.running) return this.start(), 0;
        if (this.running) {
            let t = Cc();
            e = (t - this.oldTime) / 1e3, this.oldTime = t, this.elapsedTime += e;
        }
        return e;
    }
};
function Cc() {
    return (typeof performance > "u" ? Date : performance).now();
}
var Nn = new M, Lc = new gt, py = new M, Bn = new M, my = class extends Ne {
    constructor(){
        super();
        this.type = "AudioListener", this.context = Hh.getContext(), this.gain = this.context.createGain(), this.gain.connect(this.context.destination), this.filter = null, this.timeDelta = 0, this._clock = new Wh;
    }
    getInput() {
        return this.gain;
    }
    removeFilter() {
        return this.filter !== null && (this.gain.disconnect(this.filter), this.filter.disconnect(this.context.destination), this.gain.connect(this.context.destination), this.filter = null), this;
    }
    getFilter() {
        return this.filter;
    }
    setFilter(e) {
        return this.filter !== null ? (this.gain.disconnect(this.filter), this.filter.disconnect(this.context.destination)) : this.gain.disconnect(this.context.destination), this.filter = e, this.gain.connect(this.filter), this.filter.connect(this.context.destination), this;
    }
    getMasterVolume() {
        return this.gain.gain.value;
    }
    setMasterVolume(e) {
        return this.gain.gain.setTargetAtTime(e, this.context.currentTime, .01), this;
    }
    updateMatrixWorld(e) {
        super.updateMatrixWorld(e);
        let t = this.context.listener, n = this.up;
        if (this.timeDelta = this._clock.getDelta(), this.matrixWorld.decompose(Nn, Lc, py), Bn.set(0, 0, -1).applyQuaternion(Lc), t.positionX) {
            let i = this.context.currentTime + this.timeDelta;
            t.positionX.linearRampToValueAtTime(Nn.x, i), t.positionY.linearRampToValueAtTime(Nn.y, i), t.positionZ.linearRampToValueAtTime(Nn.z, i), t.forwardX.linearRampToValueAtTime(Bn.x, i), t.forwardY.linearRampToValueAtTime(Bn.y, i), t.forwardZ.linearRampToValueAtTime(Bn.z, i), t.upX.linearRampToValueAtTime(n.x, i), t.upY.linearRampToValueAtTime(n.y, i), t.upZ.linearRampToValueAtTime(n.z, i);
        } else t.setPosition(Nn.x, Nn.y, Nn.z), t.setOrientation(Bn.x, Bn.y, Bn.z, n.x, n.y, n.z);
    }
}, Za = class extends Ne {
    constructor(e){
        super();
        this.type = "Audio", this.listener = e, this.context = e.context, this.gain = this.context.createGain(), this.gain.connect(e.getInput()), this.autoplay = !1, this.buffer = null, this.detune = 0, this.loop = !1, this.loopStart = 0, this.loopEnd = 0, this.offset = 0, this.duration = void 0, this.playbackRate = 1, this.isPlaying = !1, this.hasPlaybackControl = !0, this.source = null, this.sourceType = "empty", this._startedAt = 0, this._progress = 0, this._connected = !1, this.filters = [];
    }
    getOutput() {
        return this.gain;
    }
    setNodeSource(e) {
        return this.hasPlaybackControl = !1, this.sourceType = "audioNode", this.source = e, this.connect(), this;
    }
    setMediaElementSource(e) {
        return this.hasPlaybackControl = !1, this.sourceType = "mediaNode", this.source = this.context.createMediaElementSource(e), this.connect(), this;
    }
    setMediaStreamSource(e) {
        return this.hasPlaybackControl = !1, this.sourceType = "mediaStreamNode", this.source = this.context.createMediaStreamSource(e), this.connect(), this;
    }
    setBuffer(e) {
        return this.buffer = e, this.sourceType = "buffer", this.autoplay && this.play(), this;
    }
    play(e = 0) {
        if (this.isPlaying === !0) {
            console.warn("THREE.Audio: Audio is already playing.");
            return;
        }
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        this._startedAt = this.context.currentTime + e;
        let t = this.context.createBufferSource();
        return t.buffer = this.buffer, t.loop = this.loop, t.loopStart = this.loopStart, t.loopEnd = this.loopEnd, t.onended = this.onEnded.bind(this), t.start(this._startedAt, this._progress + this.offset, this.duration), this.isPlaying = !0, this.source = t, this.setDetune(this.detune), this.setPlaybackRate(this.playbackRate), this.connect();
    }
    pause() {
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        return this.isPlaying === !0 && (this._progress += Math.max(this.context.currentTime - this._startedAt, 0) * this.playbackRate, this.loop === !0 && (this._progress = this._progress % (this.duration || this.buffer.duration)), this.source.stop(), this.source.onended = null, this.isPlaying = !1), this;
    }
    stop() {
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        return this._progress = 0, this.source.stop(), this.source.onended = null, this.isPlaying = !1, this;
    }
    connect() {
        if (this.filters.length > 0) {
            this.source.connect(this.filters[0]);
            for(let e = 1, t = this.filters.length; e < t; e++)this.filters[e - 1].connect(this.filters[e]);
            this.filters[this.filters.length - 1].connect(this.getOutput());
        } else this.source.connect(this.getOutput());
        return this._connected = !0, this;
    }
    disconnect() {
        if (this.filters.length > 0) {
            this.source.disconnect(this.filters[0]);
            for(let e = 1, t = this.filters.length; e < t; e++)this.filters[e - 1].disconnect(this.filters[e]);
            this.filters[this.filters.length - 1].disconnect(this.getOutput());
        } else this.source.disconnect(this.getOutput());
        return this._connected = !1, this;
    }
    getFilters() {
        return this.filters;
    }
    setFilters(e) {
        return e || (e = []), this._connected === !0 ? (this.disconnect(), this.filters = e.slice(), this.connect()) : this.filters = e.slice(), this;
    }
    setDetune(e) {
        if (this.detune = e, this.source.detune !== void 0) return this.isPlaying === !0 && this.source.detune.setTargetAtTime(this.detune, this.context.currentTime, .01), this;
    }
    getDetune() {
        return this.detune;
    }
    getFilter() {
        return this.getFilters()[0];
    }
    setFilter(e) {
        return this.setFilters(e ? [
            e
        ] : []);
    }
    setPlaybackRate(e) {
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        return this.playbackRate = e, this.isPlaying === !0 && this.source.playbackRate.setTargetAtTime(this.playbackRate, this.context.currentTime, .01), this;
    }
    getPlaybackRate() {
        return this.playbackRate;
    }
    onEnded() {
        this.isPlaying = !1;
    }
    getLoop() {
        return this.hasPlaybackControl === !1 ? (console.warn("THREE.Audio: this Audio has no playback control."), !1) : this.loop;
    }
    setLoop(e) {
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        return this.loop = e, this.isPlaying === !0 && (this.source.loop = this.loop), this;
    }
    setLoopStart(e) {
        return this.loopStart = e, this;
    }
    setLoopEnd(e) {
        return this.loopEnd = e, this;
    }
    getVolume() {
        return this.gain.gain.value;
    }
    setVolume(e) {
        return this.gain.gain.setTargetAtTime(e, this.context.currentTime, .01), this;
    }
}, zn = new M, Rc = new gt, gy = new M, Un = new M, xy = class extends Za {
    constructor(e){
        super(e);
        this.panner = this.context.createPanner(), this.panner.panningModel = "HRTF", this.panner.connect(this.gain);
    }
    getOutput() {
        return this.panner;
    }
    getRefDistance() {
        return this.panner.refDistance;
    }
    setRefDistance(e) {
        return this.panner.refDistance = e, this;
    }
    getRolloffFactor() {
        return this.panner.rolloffFactor;
    }
    setRolloffFactor(e) {
        return this.panner.rolloffFactor = e, this;
    }
    getDistanceModel() {
        return this.panner.distanceModel;
    }
    setDistanceModel(e) {
        return this.panner.distanceModel = e, this;
    }
    getMaxDistance() {
        return this.panner.maxDistance;
    }
    setMaxDistance(e) {
        return this.panner.maxDistance = e, this;
    }
    setDirectionalCone(e, t, n) {
        return this.panner.coneInnerAngle = e, this.panner.coneOuterAngle = t, this.panner.coneOuterGain = n, this;
    }
    updateMatrixWorld(e) {
        if (super.updateMatrixWorld(e), this.hasPlaybackControl === !0 && this.isPlaying === !1) return;
        this.matrixWorld.decompose(zn, Rc, gy), Un.set(0, 0, 1).applyQuaternion(Rc);
        let t = this.panner;
        if (t.positionX) {
            let n = this.context.currentTime + this.listener.timeDelta;
            t.positionX.linearRampToValueAtTime(zn.x, n), t.positionY.linearRampToValueAtTime(zn.y, n), t.positionZ.linearRampToValueAtTime(zn.z, n), t.orientationX.linearRampToValueAtTime(Un.x, n), t.orientationY.linearRampToValueAtTime(Un.y, n), t.orientationZ.linearRampToValueAtTime(Un.z, n);
        } else t.setPosition(zn.x, zn.y, zn.z), t.setOrientation(Un.x, Un.y, Un.z);
    }
}, qh = class {
    constructor(e, t = 2048){
        this.analyser = e.context.createAnalyser(), this.analyser.fftSize = t, this.data = new Uint8Array(this.analyser.frequencyBinCount), e.getOutput().connect(this.analyser);
    }
    getFrequencyData() {
        return this.analyser.getByteFrequencyData(this.data), this.data;
    }
    getAverageFrequency() {
        let e = 0, t = this.getFrequencyData();
        for(let n = 0; n < t.length; n++)e += t[n];
        return e / t.length;
    }
}, Xh = class {
    constructor(e, t, n){
        this.binding = e, this.valueSize = n;
        let i, r, o;
        switch(t){
            case "quaternion":
                i = this._slerp, r = this._slerpAdditive, o = this._setAdditiveIdentityQuaternion, this.buffer = new Float64Array(n * 6), this._workIndex = 5;
                break;
            case "string":
            case "bool":
                i = this._select, r = this._select, o = this._setAdditiveIdentityOther, this.buffer = new Array(n * 5);
                break;
            default:
                i = this._lerp, r = this._lerpAdditive, o = this._setAdditiveIdentityNumeric, this.buffer = new Float64Array(n * 5);
        }
        this._mixBufferRegion = i, this._mixBufferRegionAdditive = r, this._setIdentity = o, this._origIndex = 3, this._addIndex = 4, this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0, this.useCount = 0, this.referenceCount = 0;
    }
    accumulate(e, t) {
        let n = this.buffer, i = this.valueSize, r = e * i + i, o = this.cumulativeWeight;
        if (o === 0) {
            for(let a = 0; a !== i; ++a)n[r + a] = n[a];
            o = t;
        } else {
            o += t;
            let a1 = t / o;
            this._mixBufferRegion(n, r, 0, a1, i);
        }
        this.cumulativeWeight = o;
    }
    accumulateAdditive(e) {
        let t = this.buffer, n = this.valueSize, i = n * this._addIndex;
        this.cumulativeWeightAdditive === 0 && this._setIdentity(), this._mixBufferRegionAdditive(t, i, 0, e, n), this.cumulativeWeightAdditive += e;
    }
    apply(e) {
        let t = this.valueSize, n = this.buffer, i = e * t + t, r = this.cumulativeWeight, o = this.cumulativeWeightAdditive, a = this.binding;
        if (this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0, r < 1) {
            let l = t * this._origIndex;
            this._mixBufferRegion(n, i, l, 1 - r, t);
        }
        o > 0 && this._mixBufferRegionAdditive(n, i, this._addIndex * t, 1, t);
        for(let l1 = t, c = t + t; l1 !== c; ++l1)if (n[l1] !== n[l1 + t]) {
            a.setValue(n, i);
            break;
        }
    }
    saveOriginalState() {
        let e = this.binding, t = this.buffer, n = this.valueSize, i = n * this._origIndex;
        e.getValue(t, i);
        for(let r = n, o = i; r !== o; ++r)t[r] = t[i + r % n];
        this._setIdentity(), this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0;
    }
    restoreOriginalState() {
        let e = this.valueSize * 3;
        this.binding.setValue(this.buffer, e);
    }
    _setAdditiveIdentityNumeric() {
        let e = this._addIndex * this.valueSize, t = e + this.valueSize;
        for(let n = e; n < t; n++)this.buffer[n] = 0;
    }
    _setAdditiveIdentityQuaternion() {
        this._setAdditiveIdentityNumeric(), this.buffer[this._addIndex * this.valueSize + 3] = 1;
    }
    _setAdditiveIdentityOther() {
        let e = this._origIndex * this.valueSize, t = this._addIndex * this.valueSize;
        for(let n = 0; n < this.valueSize; n++)this.buffer[t + n] = this.buffer[e + n];
    }
    _select(e, t, n, i, r) {
        if (i >= .5) for(let o = 0; o !== r; ++o)e[t + o] = e[n + o];
    }
    _slerp(e, t, n, i) {
        gt.slerpFlat(e, t, e, t, e, n, i);
    }
    _slerpAdditive(e, t, n, i, r) {
        let o = this._workIndex * r;
        gt.multiplyQuaternionsFlat(e, o, e, t, e, n), gt.slerpFlat(e, t, e, t, e, o, i);
    }
    _lerp(e, t, n, i, r) {
        let o = 1 - i;
        for(let a = 0; a !== r; ++a){
            let l = t + a;
            e[l] = e[l] * o + e[n + a] * i;
        }
    }
    _lerpAdditive(e, t, n, i, r) {
        for(let o = 0; o !== r; ++o){
            let a = t + o;
            e[a] = e[a] + e[n + o] * i;
        }
    }
}, $a = "\\[\\]\\.:\\/", yy = new RegExp("[" + $a + "]", "g"), ja = "[^" + $a + "]", vy = "[^" + $a.replace("\\.", "") + "]", _y = /((?:WC+[\/:])*)/.source.replace("WC", ja), My = /(WCOD+)?/.source.replace("WCOD", vy), by = /(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC", ja), wy = /\.(WC+)(?:\[(.+)\])?/.source.replace("WC", ja), Sy = new RegExp("^" + _y + My + by + wy + "$"), Ty = [
    "material",
    "materials",
    "bones"
], Jh = class {
    constructor(e, t, n){
        let i = n || ke.parseTrackName(t);
        this._targetGroup = e, this._bindings = e.subscribe_(t, i);
    }
    getValue(e, t) {
        this.bind();
        let n = this._targetGroup.nCachedObjects_, i = this._bindings[n];
        i !== void 0 && i.getValue(e, t);
    }
    setValue(e, t) {
        let n = this._bindings;
        for(let i = this._targetGroup.nCachedObjects_, r = n.length; i !== r; ++i)n[i].setValue(e, t);
    }
    bind() {
        let e = this._bindings;
        for(let t = this._targetGroup.nCachedObjects_, n = e.length; t !== n; ++t)e[t].bind();
    }
    unbind() {
        let e = this._bindings;
        for(let t = this._targetGroup.nCachedObjects_, n = e.length; t !== n; ++t)e[t].unbind();
    }
}, ke = class {
    constructor(e, t, n){
        this.path = t, this.parsedPath = n || ke.parseTrackName(t), this.node = ke.findNode(e, this.parsedPath.nodeName) || e, this.rootNode = e, this.getValue = this._getValue_unbound, this.setValue = this._setValue_unbound;
    }
    static create(e, t, n) {
        return e && e.isAnimationObjectGroup ? new ke.Composite(e, t, n) : new ke(e, t, n);
    }
    static sanitizeNodeName(e) {
        return e.replace(/\s/g, "_").replace(yy, "");
    }
    static parseTrackName(e) {
        let t = Sy.exec(e);
        if (!t) throw new Error("PropertyBinding: Cannot parse trackName: " + e);
        let n = {
            nodeName: t[2],
            objectName: t[3],
            objectIndex: t[4],
            propertyName: t[5],
            propertyIndex: t[6]
        }, i = n.nodeName && n.nodeName.lastIndexOf(".");
        if (i !== void 0 && i !== -1) {
            let r = n.nodeName.substring(i + 1);
            Ty.indexOf(r) !== -1 && (n.nodeName = n.nodeName.substring(0, i), n.objectName = r);
        }
        if (n.propertyName === null || n.propertyName.length === 0) throw new Error("PropertyBinding: can not parse propertyName from trackName: " + e);
        return n;
    }
    static findNode(e, t) {
        if (!t || t === "" || t === "." || t === -1 || t === e.name || t === e.uuid) return e;
        if (e.skeleton) {
            let n = e.skeleton.getBoneByName(t);
            if (n !== void 0) return n;
        }
        if (e.children) {
            let n1 = function(r) {
                for(let o = 0; o < r.length; o++){
                    let a = r[o];
                    if (a.name === t || a.uuid === t) return a;
                    let l = n1(a.children);
                    if (l) return l;
                }
                return null;
            }, i = n1(e.children);
            if (i) return i;
        }
        return null;
    }
    _getValue_unavailable() {}
    _setValue_unavailable() {}
    _getValue_direct(e, t) {
        e[t] = this.targetObject[this.propertyName];
    }
    _getValue_array(e, t) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)e[t++] = n[i];
    }
    _getValue_arrayElement(e, t) {
        e[t] = this.resolvedProperty[this.propertyIndex];
    }
    _getValue_toArray(e, t) {
        this.resolvedProperty.toArray(e, t);
    }
    _setValue_direct(e, t) {
        this.targetObject[this.propertyName] = e[t];
    }
    _setValue_direct_setNeedsUpdate(e, t) {
        this.targetObject[this.propertyName] = e[t], this.targetObject.needsUpdate = !0;
    }
    _setValue_direct_setMatrixWorldNeedsUpdate(e, t) {
        this.targetObject[this.propertyName] = e[t], this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _setValue_array(e, t) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)n[i] = e[t++];
    }
    _setValue_array_setNeedsUpdate(e, t) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)n[i] = e[t++];
        this.targetObject.needsUpdate = !0;
    }
    _setValue_array_setMatrixWorldNeedsUpdate(e, t) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)n[i] = e[t++];
        this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _setValue_arrayElement(e, t) {
        this.resolvedProperty[this.propertyIndex] = e[t];
    }
    _setValue_arrayElement_setNeedsUpdate(e, t) {
        this.resolvedProperty[this.propertyIndex] = e[t], this.targetObject.needsUpdate = !0;
    }
    _setValue_arrayElement_setMatrixWorldNeedsUpdate(e, t) {
        this.resolvedProperty[this.propertyIndex] = e[t], this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _setValue_fromArray(e, t) {
        this.resolvedProperty.fromArray(e, t);
    }
    _setValue_fromArray_setNeedsUpdate(e, t) {
        this.resolvedProperty.fromArray(e, t), this.targetObject.needsUpdate = !0;
    }
    _setValue_fromArray_setMatrixWorldNeedsUpdate(e, t) {
        this.resolvedProperty.fromArray(e, t), this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _getValue_unbound(e, t) {
        this.bind(), this.getValue(e, t);
    }
    _setValue_unbound(e, t) {
        this.bind(), this.setValue(e, t);
    }
    bind() {
        let e = this.node, t = this.parsedPath, n = t.objectName, i = t.propertyName, r = t.propertyIndex;
        if (e || (e = ke.findNode(this.rootNode, t.nodeName) || this.rootNode, this.node = e), this.getValue = this._getValue_unavailable, this.setValue = this._setValue_unavailable, !e) {
            console.error("THREE.PropertyBinding: Trying to update node for track: " + this.path + " but it wasn't found.");
            return;
        }
        if (n) {
            let c = t.objectIndex;
            switch(n){
                case "materials":
                    if (!e.material) {
                        console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
                        return;
                    }
                    if (!e.material.materials) {
                        console.error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.", this);
                        return;
                    }
                    e = e.material.materials;
                    break;
                case "bones":
                    if (!e.skeleton) {
                        console.error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.", this);
                        return;
                    }
                    e = e.skeleton.bones;
                    for(let h = 0; h < e.length; h++)if (e[h].name === c) {
                        c = h;
                        break;
                    }
                    break;
                default:
                    if (e[n] === void 0) {
                        console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
                        return;
                    }
                    e = e[n];
            }
            if (c !== void 0) {
                if (e[c] === void 0) {
                    console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, e);
                    return;
                }
                e = e[c];
            }
        }
        let o = e[i];
        if (o === void 0) {
            let c1 = t.nodeName;
            console.error("THREE.PropertyBinding: Trying to update property for track: " + c1 + "." + i + " but it wasn't found.", e);
            return;
        }
        let a = this.Versioning.None;
        this.targetObject = e, e.needsUpdate !== void 0 ? a = this.Versioning.NeedsUpdate : e.matrixWorldNeedsUpdate !== void 0 && (a = this.Versioning.MatrixWorldNeedsUpdate);
        let l = this.BindingType.Direct;
        if (r !== void 0) {
            if (i === "morphTargetInfluences") {
                if (!e.geometry) {
                    console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
                    return;
                }
                if (e.geometry.isBufferGeometry) {
                    if (!e.geometry.morphAttributes) {
                        console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
                        return;
                    }
                    e.morphTargetDictionary[r] !== void 0 && (r = e.morphTargetDictionary[r]);
                } else {
                    console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences on THREE.Geometry. Use THREE.BufferGeometry instead.", this);
                    return;
                }
            }
            l = this.BindingType.ArrayElement, this.resolvedProperty = o, this.propertyIndex = r;
        } else o.fromArray !== void 0 && o.toArray !== void 0 ? (l = this.BindingType.HasFromToArray, this.resolvedProperty = o) : Array.isArray(o) ? (l = this.BindingType.EntireArray, this.resolvedProperty = o) : this.propertyName = i;
        this.getValue = this.GetterByBindingType[l], this.setValue = this.SetterByBindingTypeAndVersioning[l][a];
    }
    unbind() {
        this.node = null, this.getValue = this._getValue_unbound, this.setValue = this._setValue_unbound;
    }
};
ke.Composite = Jh;
ke.prototype.BindingType = {
    Direct: 0,
    EntireArray: 1,
    ArrayElement: 2,
    HasFromToArray: 3
};
ke.prototype.Versioning = {
    None: 0,
    NeedsUpdate: 1,
    MatrixWorldNeedsUpdate: 2
};
ke.prototype.GetterByBindingType = [
    ke.prototype._getValue_direct,
    ke.prototype._getValue_array,
    ke.prototype._getValue_arrayElement,
    ke.prototype._getValue_toArray
];
ke.prototype.SetterByBindingTypeAndVersioning = [
    [
        ke.prototype._setValue_direct,
        ke.prototype._setValue_direct_setNeedsUpdate,
        ke.prototype._setValue_direct_setMatrixWorldNeedsUpdate
    ],
    [
        ke.prototype._setValue_array,
        ke.prototype._setValue_array_setNeedsUpdate,
        ke.prototype._setValue_array_setMatrixWorldNeedsUpdate
    ],
    [
        ke.prototype._setValue_arrayElement,
        ke.prototype._setValue_arrayElement_setNeedsUpdate,
        ke.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate
    ],
    [
        ke.prototype._setValue_fromArray,
        ke.prototype._setValue_fromArray_setNeedsUpdate,
        ke.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate
    ]
];
var Yh = class {
    constructor(){
        this.uuid = Et(), this._objects = Array.prototype.slice.call(arguments), this.nCachedObjects_ = 0;
        let e = {};
        this._indicesByUUID = e;
        for(let n = 0, i = arguments.length; n !== i; ++n)e[arguments[n].uuid] = n;
        this._paths = [], this._parsedPaths = [], this._bindings = [], this._bindingsIndicesByPath = {};
        let t = this;
        this.stats = {
            objects: {
                get total () {
                    return t._objects.length;
                },
                get inUse () {
                    return this.total - t.nCachedObjects_;
                }
            },
            get bindingsPerObject () {
                return t._bindings.length;
            }
        };
    }
    add() {
        let e = this._objects, t = this._indicesByUUID, n = this._paths, i = this._parsedPaths, r = this._bindings, o = r.length, a, l = e.length, c = this.nCachedObjects_;
        for(let h = 0, u = arguments.length; h !== u; ++h){
            let d = arguments[h], f = d.uuid, m = t[f];
            if (m === void 0) {
                m = l++, t[f] = m, e.push(d);
                for(let x = 0, v = o; x !== v; ++x)r[x].push(new ke(d, n[x], i[x]));
            } else if (m < c) {
                a = e[m];
                let x1 = --c, v1 = e[x1];
                t[v1.uuid] = m, e[m] = v1, t[f] = x1, e[x1] = d;
                for(let g = 0, p = o; g !== p; ++g){
                    let _ = r[g], y = _[x1], b = _[m];
                    _[m] = y, b === void 0 && (b = new ke(d, n[g], i[g])), _[x1] = b;
                }
            } else e[m] !== a && console.error("THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.");
        }
        this.nCachedObjects_ = c;
    }
    remove() {
        let e = this._objects, t = this._indicesByUUID, n = this._bindings, i = n.length, r = this.nCachedObjects_;
        for(let o = 0, a = arguments.length; o !== a; ++o){
            let l = arguments[o], c = l.uuid, h = t[c];
            if (h !== void 0 && h >= r) {
                let u = r++, d = e[u];
                t[d.uuid] = h, e[h] = d, t[c] = u, e[u] = l;
                for(let f = 0, m = i; f !== m; ++f){
                    let x = n[f], v = x[u], g = x[h];
                    x[h] = v, x[u] = g;
                }
            }
        }
        this.nCachedObjects_ = r;
    }
    uncache() {
        let e = this._objects, t = this._indicesByUUID, n = this._bindings, i = n.length, r = this.nCachedObjects_, o = e.length;
        for(let a = 0, l = arguments.length; a !== l; ++a){
            let c = arguments[a], h = c.uuid, u = t[h];
            if (u !== void 0) if (delete t[h], u < r) {
                let d = --r, f = e[d], m = --o, x = e[m];
                t[f.uuid] = u, e[u] = f, t[x.uuid] = d, e[d] = x, e.pop();
                for(let v = 0, g = i; v !== g; ++v){
                    let p = n[v], _ = p[d], y = p[m];
                    p[u] = _, p[d] = y, p.pop();
                }
            } else {
                let d1 = --o, f1 = e[d1];
                d1 > 0 && (t[f1.uuid] = u), e[u] = f1, e.pop();
                for(let m1 = 0, x1 = i; m1 !== x1; ++m1){
                    let v1 = n[m1];
                    v1[u] = v1[d1], v1.pop();
                }
            }
        }
        this.nCachedObjects_ = r;
    }
    subscribe_(e, t) {
        let n = this._bindingsIndicesByPath, i = n[e], r = this._bindings;
        if (i !== void 0) return r[i];
        let o = this._paths, a = this._parsedPaths, l = this._objects, c = l.length, h = this.nCachedObjects_, u = new Array(c);
        i = r.length, n[e] = i, o.push(e), a.push(t), r.push(u);
        for(let d = h, f = l.length; d !== f; ++d){
            let m = l[d];
            u[d] = new ke(m, e, t);
        }
        return u;
    }
    unsubscribe_(e) {
        let t = this._bindingsIndicesByPath, n = t[e];
        if (n !== void 0) {
            let i = this._paths, r = this._parsedPaths, o = this._bindings, a = o.length - 1, l = o[a], c = e[a];
            t[c] = n, o[n] = l, o.pop(), r[n] = r[a], r.pop(), i[n] = i[a], i.pop();
        }
    }
};
Yh.prototype.isAnimationObjectGroup = !0;
var Zh = class {
    constructor(e, t, n = null, i = t.blendMode){
        this._mixer = e, this._clip = t, this._localRoot = n, this.blendMode = i;
        let r = t.tracks, o = r.length, a = new Array(o), l = {
            endingStart: Mi,
            endingEnd: Mi
        };
        for(let c = 0; c !== o; ++c){
            let h = r[c].createInterpolant(null);
            a[c] = h, h.settings = l;
        }
        this._interpolantSettings = l, this._interpolants = a, this._propertyBindings = new Array(o), this._cacheIndex = null, this._byClipCacheIndex = null, this._timeScaleInterpolant = null, this._weightInterpolant = null, this.loop = Id, this._loopCount = -1, this._startTime = null, this.time = 0, this.timeScale = 1, this._effectiveTimeScale = 1, this.weight = 1, this._effectiveWeight = 1, this.repetitions = 1 / 0, this.paused = !1, this.enabled = !0, this.clampWhenFinished = !1, this.zeroSlopeAtStart = !0, this.zeroSlopeAtEnd = !0;
    }
    play() {
        return this._mixer._activateAction(this), this;
    }
    stop() {
        return this._mixer._deactivateAction(this), this.reset();
    }
    reset() {
        return this.paused = !1, this.enabled = !0, this.time = 0, this._loopCount = -1, this._startTime = null, this.stopFading().stopWarping();
    }
    isRunning() {
        return this.enabled && !this.paused && this.timeScale !== 0 && this._startTime === null && this._mixer._isActiveAction(this);
    }
    isScheduled() {
        return this._mixer._isActiveAction(this);
    }
    startAt(e) {
        return this._startTime = e, this;
    }
    setLoop(e, t) {
        return this.loop = e, this.repetitions = t, this;
    }
    setEffectiveWeight(e) {
        return this.weight = e, this._effectiveWeight = this.enabled ? e : 0, this.stopFading();
    }
    getEffectiveWeight() {
        return this._effectiveWeight;
    }
    fadeIn(e) {
        return this._scheduleFading(e, 0, 1);
    }
    fadeOut(e) {
        return this._scheduleFading(e, 1, 0);
    }
    crossFadeFrom(e, t, n) {
        if (e.fadeOut(t), this.fadeIn(t), n) {
            let i = this._clip.duration, r = e._clip.duration, o = r / i, a = i / r;
            e.warp(1, o, t), this.warp(a, 1, t);
        }
        return this;
    }
    crossFadeTo(e, t, n) {
        return e.crossFadeFrom(this, t, n);
    }
    stopFading() {
        let e = this._weightInterpolant;
        return e !== null && (this._weightInterpolant = null, this._mixer._takeBackControlInterpolant(e)), this;
    }
    setEffectiveTimeScale(e) {
        return this.timeScale = e, this._effectiveTimeScale = this.paused ? 0 : e, this.stopWarping();
    }
    getEffectiveTimeScale() {
        return this._effectiveTimeScale;
    }
    setDuration(e) {
        return this.timeScale = this._clip.duration / e, this.stopWarping();
    }
    syncWith(e) {
        return this.time = e.time, this.timeScale = e.timeScale, this.stopWarping();
    }
    halt(e) {
        return this.warp(this._effectiveTimeScale, 0, e);
    }
    warp(e, t, n) {
        let i = this._mixer, r = i.time, o = this.timeScale, a = this._timeScaleInterpolant;
        a === null && (a = i._lendControlInterpolant(), this._timeScaleInterpolant = a);
        let l = a.parameterPositions, c = a.sampleValues;
        return l[0] = r, l[1] = r + n, c[0] = e / o, c[1] = t / o, this;
    }
    stopWarping() {
        let e = this._timeScaleInterpolant;
        return e !== null && (this._timeScaleInterpolant = null, this._mixer._takeBackControlInterpolant(e)), this;
    }
    getMixer() {
        return this._mixer;
    }
    getClip() {
        return this._clip;
    }
    getRoot() {
        return this._localRoot || this._mixer._root;
    }
    _update(e, t, n, i) {
        if (!this.enabled) {
            this._updateWeight(e);
            return;
        }
        let r = this._startTime;
        if (r !== null) {
            let l = (e - r) * n;
            if (l < 0 || n === 0) return;
            this._startTime = null, t = n * l;
        }
        t *= this._updateTimeScale(e);
        let o = this._updateTime(t), a = this._updateWeight(e);
        if (a > 0) {
            let l1 = this._interpolants, c = this._propertyBindings;
            switch(this.blendMode){
                case qc:
                    for(let h = 0, u = l1.length; h !== u; ++h)l1[h].evaluate(o), c[h].accumulateAdditive(a);
                    break;
                case ua:
                default:
                    for(let h1 = 0, u1 = l1.length; h1 !== u1; ++h1)l1[h1].evaluate(o), c[h1].accumulate(i, a);
            }
        }
    }
    _updateWeight(e) {
        let t = 0;
        if (this.enabled) {
            t = this.weight;
            let n = this._weightInterpolant;
            if (n !== null) {
                let i = n.evaluate(e)[0];
                t *= i, e > n.parameterPositions[1] && (this.stopFading(), i === 0 && (this.enabled = !1));
            }
        }
        return this._effectiveWeight = t, t;
    }
    _updateTimeScale(e) {
        let t = 0;
        if (!this.paused) {
            t = this.timeScale;
            let n = this._timeScaleInterpolant;
            n !== null && (t *= n.evaluate(e)[0], e > n.parameterPositions[1] && (this.stopWarping(), t === 0 ? this.paused = !0 : this.timeScale = t));
        }
        return this._effectiveTimeScale = t, t;
    }
    _updateTime(e) {
        let t = this._clip.duration, n = this.loop, i = this.time + e, r = this._loopCount, o = n === Dd;
        if (e === 0) return r === -1 ? i : o && (r & 1) === 1 ? t - i : i;
        if (n === Pd) {
            r === -1 && (this._loopCount = 0, this._setEndings(!0, !0, !1));
            e: {
                if (i >= t) i = t;
                else if (i < 0) i = 0;
                else {
                    this.time = i;
                    break e;
                }
                this.clampWhenFinished ? this.paused = !0 : this.enabled = !1, this.time = i, this._mixer.dispatchEvent({
                    type: "finished",
                    action: this,
                    direction: e < 0 ? -1 : 1
                });
            }
        } else {
            if (r === -1 && (e >= 0 ? (r = 0, this._setEndings(!0, this.repetitions === 0, o)) : this._setEndings(this.repetitions === 0, !0, o)), i >= t || i < 0) {
                let a = Math.floor(i / t);
                i -= t * a, r += Math.abs(a);
                let l = this.repetitions - r;
                if (l <= 0) this.clampWhenFinished ? this.paused = !0 : this.enabled = !1, i = e > 0 ? t : 0, this.time = i, this._mixer.dispatchEvent({
                    type: "finished",
                    action: this,
                    direction: e > 0 ? 1 : -1
                });
                else {
                    if (l === 1) {
                        let c = e < 0;
                        this._setEndings(c, !c, o);
                    } else this._setEndings(!1, !1, o);
                    this._loopCount = r, this.time = i, this._mixer.dispatchEvent({
                        type: "loop",
                        action: this,
                        loopDelta: a
                    });
                }
            } else this.time = i;
            if (o && (r & 1) === 1) return t - i;
        }
        return i;
    }
    _setEndings(e, t, n) {
        let i = this._interpolantSettings;
        n ? (i.endingStart = bi, i.endingEnd = bi) : (e ? i.endingStart = this.zeroSlopeAtStart ? bi : Mi : i.endingStart = Os, t ? i.endingEnd = this.zeroSlopeAtEnd ? bi : Mi : i.endingEnd = Os);
    }
    _scheduleFading(e, t, n) {
        let i = this._mixer, r = i.time, o = this._weightInterpolant;
        o === null && (o = i._lendControlInterpolant(), this._weightInterpolant = o);
        let a = o.parameterPositions, l = o.sampleValues;
        return a[0] = r, l[0] = t, a[1] = r + e, l[1] = n, this;
    }
}, $h = class extends En {
    constructor(e){
        super();
        this._root = e, this._initMemoryManager(), this._accuIndex = 0, this.time = 0, this.timeScale = 1;
    }
    _bindAction(e, t) {
        let n = e._localRoot || this._root, i = e._clip.tracks, r = i.length, o = e._propertyBindings, a = e._interpolants, l = n.uuid, c = this._bindingsByRootAndName, h = c[l];
        h === void 0 && (h = {}, c[l] = h);
        for(let u = 0; u !== r; ++u){
            let d = i[u], f = d.name, m = h[f];
            if (m !== void 0) o[u] = m;
            else {
                if (m = o[u], m !== void 0) {
                    m._cacheIndex === null && (++m.referenceCount, this._addInactiveBinding(m, l, f));
                    continue;
                }
                let x = t && t._propertyBindings[u].binding.parsedPath;
                m = new Xh(ke.create(n, f, x), d.ValueTypeName, d.getValueSize()), ++m.referenceCount, this._addInactiveBinding(m, l, f), o[u] = m;
            }
            a[u].resultBuffer = m.buffer;
        }
    }
    _activateAction(e) {
        if (!this._isActiveAction(e)) {
            if (e._cacheIndex === null) {
                let n = (e._localRoot || this._root).uuid, i = e._clip.uuid, r = this._actionsByClip[i];
                this._bindAction(e, r && r.knownActions[0]), this._addInactiveAction(e, i, n);
            }
            let t = e._propertyBindings;
            for(let n1 = 0, i1 = t.length; n1 !== i1; ++n1){
                let r1 = t[n1];
                r1.useCount++ === 0 && (this._lendBinding(r1), r1.saveOriginalState());
            }
            this._lendAction(e);
        }
    }
    _deactivateAction(e) {
        if (this._isActiveAction(e)) {
            let t = e._propertyBindings;
            for(let n = 0, i = t.length; n !== i; ++n){
                let r = t[n];
                --r.useCount === 0 && (r.restoreOriginalState(), this._takeBackBinding(r));
            }
            this._takeBackAction(e);
        }
    }
    _initMemoryManager() {
        this._actions = [], this._nActiveActions = 0, this._actionsByClip = {}, this._bindings = [], this._nActiveBindings = 0, this._bindingsByRootAndName = {}, this._controlInterpolants = [], this._nActiveControlInterpolants = 0;
        let e = this;
        this.stats = {
            actions: {
                get total () {
                    return e._actions.length;
                },
                get inUse () {
                    return e._nActiveActions;
                }
            },
            bindings: {
                get total () {
                    return e._bindings.length;
                },
                get inUse () {
                    return e._nActiveBindings;
                }
            },
            controlInterpolants: {
                get total () {
                    return e._controlInterpolants.length;
                },
                get inUse () {
                    return e._nActiveControlInterpolants;
                }
            }
        };
    }
    _isActiveAction(e) {
        let t = e._cacheIndex;
        return t !== null && t < this._nActiveActions;
    }
    _addInactiveAction(e, t, n) {
        let i = this._actions, r = this._actionsByClip, o = r[t];
        if (o === void 0) o = {
            knownActions: [
                e
            ],
            actionByRoot: {}
        }, e._byClipCacheIndex = 0, r[t] = o;
        else {
            let a = o.knownActions;
            e._byClipCacheIndex = a.length, a.push(e);
        }
        e._cacheIndex = i.length, i.push(e), o.actionByRoot[n] = e;
    }
    _removeInactiveAction(e) {
        let t = this._actions, n = t[t.length - 1], i = e._cacheIndex;
        n._cacheIndex = i, t[i] = n, t.pop(), e._cacheIndex = null;
        let r = e._clip.uuid, o = this._actionsByClip, a = o[r], l = a.knownActions, c = l[l.length - 1], h = e._byClipCacheIndex;
        c._byClipCacheIndex = h, l[h] = c, l.pop(), e._byClipCacheIndex = null;
        let u = a.actionByRoot, d = (e._localRoot || this._root).uuid;
        delete u[d], l.length === 0 && delete o[r], this._removeInactiveBindingsForAction(e);
    }
    _removeInactiveBindingsForAction(e) {
        let t = e._propertyBindings;
        for(let n = 0, i = t.length; n !== i; ++n){
            let r = t[n];
            --r.referenceCount === 0 && this._removeInactiveBinding(r);
        }
    }
    _lendAction(e) {
        let t = this._actions, n = e._cacheIndex, i = this._nActiveActions++, r = t[i];
        e._cacheIndex = i, t[i] = e, r._cacheIndex = n, t[n] = r;
    }
    _takeBackAction(e) {
        let t = this._actions, n = e._cacheIndex, i = --this._nActiveActions, r = t[i];
        e._cacheIndex = i, t[i] = e, r._cacheIndex = n, t[n] = r;
    }
    _addInactiveBinding(e, t, n) {
        let i = this._bindingsByRootAndName, r = this._bindings, o = i[t];
        o === void 0 && (o = {}, i[t] = o), o[n] = e, e._cacheIndex = r.length, r.push(e);
    }
    _removeInactiveBinding(e) {
        let t = this._bindings, n = e.binding, i = n.rootNode.uuid, r = n.path, o = this._bindingsByRootAndName, a = o[i], l = t[t.length - 1], c = e._cacheIndex;
        l._cacheIndex = c, t[c] = l, t.pop(), delete a[r], Object.keys(a).length === 0 && delete o[i];
    }
    _lendBinding(e) {
        let t = this._bindings, n = e._cacheIndex, i = this._nActiveBindings++, r = t[i];
        e._cacheIndex = i, t[i] = e, r._cacheIndex = n, t[n] = r;
    }
    _takeBackBinding(e) {
        let t = this._bindings, n = e._cacheIndex, i = --this._nActiveBindings, r = t[i];
        e._cacheIndex = i, t[i] = e, r._cacheIndex = n, t[n] = r;
    }
    _lendControlInterpolant() {
        let e = this._controlInterpolants, t = this._nActiveControlInterpolants++, n = e[t];
        return n === void 0 && (n = new Na(new Float32Array(2), new Float32Array(2), 1, this._controlInterpolantsResultBuffer), n.__cacheIndex = t, e[t] = n), n;
    }
    _takeBackControlInterpolant(e) {
        let t = this._controlInterpolants, n = e.__cacheIndex, i = --this._nActiveControlInterpolants, r = t[i];
        e.__cacheIndex = i, t[i] = e, r.__cacheIndex = n, t[n] = r;
    }
    clipAction(e, t, n) {
        let i = t || this._root, r = i.uuid, o = typeof e == "string" ? Lr.findByName(i, e) : e, a = o !== null ? o.uuid : e, l = this._actionsByClip[a], c = null;
        if (n === void 0 && (o !== null ? n = o.blendMode : n = ua), l !== void 0) {
            let u = l.actionByRoot[r];
            if (u !== void 0 && u.blendMode === n) return u;
            c = l.knownActions[0], o === null && (o = c._clip);
        }
        if (o === null) return null;
        let h = new Zh(this, o, t, n);
        return this._bindAction(h, c), this._addInactiveAction(h, a, r), h;
    }
    existingAction(e, t) {
        let n = t || this._root, i = n.uuid, r = typeof e == "string" ? Lr.findByName(n, e) : e, o = r ? r.uuid : e, a = this._actionsByClip[o];
        return a !== void 0 && a.actionByRoot[i] || null;
    }
    stopAllAction() {
        let e = this._actions, t = this._nActiveActions;
        for(let n = t - 1; n >= 0; --n)e[n].stop();
        return this;
    }
    update(e) {
        e *= this.timeScale;
        let t = this._actions, n = this._nActiveActions, i = this.time += e, r = Math.sign(e), o = this._accuIndex ^= 1;
        for(let c = 0; c !== n; ++c)t[c]._update(i, e, r, o);
        let a = this._bindings, l = this._nActiveBindings;
        for(let c1 = 0; c1 !== l; ++c1)a[c1].apply(o);
        return this;
    }
    setTime(e) {
        this.time = 0;
        for(let t = 0; t < this._actions.length; t++)this._actions[t].time = 0;
        return this.update(e);
    }
    getRoot() {
        return this._root;
    }
    uncacheClip(e) {
        let t = this._actions, n = e.uuid, i = this._actionsByClip, r = i[n];
        if (r !== void 0) {
            let o = r.knownActions;
            for(let a = 0, l = o.length; a !== l; ++a){
                let c = o[a];
                this._deactivateAction(c);
                let h = c._cacheIndex, u = t[t.length - 1];
                c._cacheIndex = null, c._byClipCacheIndex = null, u._cacheIndex = h, t[h] = u, t.pop(), this._removeInactiveBindingsForAction(c);
            }
            delete i[n];
        }
    }
    uncacheRoot(e) {
        let t = e.uuid, n = this._actionsByClip;
        for(let o in n){
            let a = n[o].actionByRoot, l = a[t];
            l !== void 0 && (this._deactivateAction(l), this._removeInactiveAction(l));
        }
        let i = this._bindingsByRootAndName, r = i[t];
        if (r !== void 0) for(let o1 in r){
            let a1 = r[o1];
            a1.restoreOriginalState(), this._removeInactiveBinding(a1);
        }
    }
    uncacheAction(e, t) {
        let n = this.existingAction(e, t);
        n !== null && (this._deactivateAction(n), this._removeInactiveAction(n));
    }
};
$h.prototype._controlInterpolantsResultBuffer = new Float32Array(1);
var go = class {
    constructor(e){
        typeof e == "string" && (console.warn("THREE.Uniform: Type parameter is no longer needed."), e = arguments[1]), this.value = e;
    }
    clone() {
        return new go(this.value.clone === void 0 ? this.value : this.value.clone());
    }
}, jh = class extends $n {
    constructor(e, t, n = 1){
        super(e, t);
        this.meshPerAttribute = n;
    }
    copy(e) {
        return super.copy(e), this.meshPerAttribute = e.meshPerAttribute, this;
    }
    clone(e) {
        let t = super.clone(e);
        return t.meshPerAttribute = this.meshPerAttribute, t;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.isInstancedInterleavedBuffer = !0, t.meshPerAttribute = this.meshPerAttribute, t;
    }
};
jh.prototype.isInstancedInterleavedBuffer = !0;
var Qh = class {
    constructor(e, t, n, i, r){
        this.buffer = e, this.type = t, this.itemSize = n, this.elementSize = i, this.count = r, this.version = 0;
    }
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
    setBuffer(e) {
        return this.buffer = e, this;
    }
    setType(e, t) {
        return this.type = e, this.elementSize = t, this;
    }
    setItemSize(e) {
        return this.itemSize = e, this;
    }
    setCount(e) {
        return this.count = e, this;
    }
};
Qh.prototype.isGLBufferAttribute = !0;
var Ey = class {
    constructor(e, t, n = 0, i = 1 / 0){
        this.ray = new Cn(e, t), this.near = n, this.far = i, this.camera = null, this.layers = new Js, this.params = {
            Mesh: {},
            Line: {
                threshold: 1
            },
            LOD: {},
            Points: {
                threshold: 1
            },
            Sprite: {}
        };
    }
    set(e, t) {
        this.ray.set(e, t);
    }
    setFromCamera(e, t) {
        t && t.isPerspectiveCamera ? (this.ray.origin.setFromMatrixPosition(t.matrixWorld), this.ray.direction.set(e.x, e.y, .5).unproject(t).sub(this.ray.origin).normalize(), this.camera = t) : t && t.isOrthographicCamera ? (this.ray.origin.set(e.x, e.y, (t.near + t.far) / (t.near - t.far)).unproject(t), this.ray.direction.set(0, 0, -1).transformDirection(t.matrixWorld), this.camera = t) : console.error("THREE.Raycaster: Unsupported camera type: " + t.type);
    }
    intersectObject(e, t = !0, n = []) {
        return la(e, this, n, t), n.sort(Pc), n;
    }
    intersectObjects(e, t = !0, n = []) {
        for(let i = 0, r = e.length; i < r; i++)la(e[i], this, n, t);
        return n.sort(Pc), n;
    }
};
function Pc(s, e) {
    return s.distance - e.distance;
}
function la(s, e, t, n) {
    if (s.layers.test(e.layers) && s.raycast(e, t), n === !0) {
        let i = s.children;
        for(let r = 0, o = i.length; r < o; r++)la(i[r], e, t, !0);
    }
}
var Ay = class {
    constructor(e = 1, t = 0, n = 0){
        return this.radius = e, this.phi = t, this.theta = n, this;
    }
    set(e, t, n) {
        return this.radius = e, this.phi = t, this.theta = n, this;
    }
    copy(e) {
        return this.radius = e.radius, this.phi = e.phi, this.theta = e.theta, this;
    }
    makeSafe() {
        return this.phi = Math.max(1e-6, Math.min(Math.PI - 1e-6, this.phi)), this;
    }
    setFromVector3(e) {
        return this.setFromCartesianCoords(e.x, e.y, e.z);
    }
    setFromCartesianCoords(e, t, n) {
        return this.radius = Math.sqrt(e * e + t * t + n * n), this.radius === 0 ? (this.theta = 0, this.phi = 0) : (this.theta = Math.atan2(e, n), this.phi = Math.acos(mt(t / this.radius, -1, 1))), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Cy = class {
    constructor(e = 1, t = 0, n = 0){
        return this.radius = e, this.theta = t, this.y = n, this;
    }
    set(e, t, n) {
        return this.radius = e, this.theta = t, this.y = n, this;
    }
    copy(e) {
        return this.radius = e.radius, this.theta = e.theta, this.y = e.y, this;
    }
    setFromVector3(e) {
        return this.setFromCartesianCoords(e.x, e.y, e.z);
    }
    setFromCartesianCoords(e, t, n) {
        return this.radius = Math.sqrt(e * e + n * n), this.theta = Math.atan2(e, n), this.y = t, this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Ic = new X, qi = class {
    constructor(e = new X(1 / 0, 1 / 0), t = new X(-1 / 0, -1 / 0)){
        this.min = e, this.max = t;
    }
    set(e, t) {
        return this.min.copy(e), this.max.copy(t), this;
    }
    setFromPoints(e) {
        this.makeEmpty();
        for(let t = 0, n = e.length; t < n; t++)this.expandByPoint(e[t]);
        return this;
    }
    setFromCenterAndSize(e, t) {
        let n = Ic.copy(t).multiplyScalar(.5);
        return this.min.copy(e).sub(n), this.max.copy(e).add(n), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.min.copy(e.min), this.max.copy(e.max), this;
    }
    makeEmpty() {
        return this.min.x = this.min.y = 1 / 0, this.max.x = this.max.y = -1 / 0, this;
    }
    isEmpty() {
        return this.max.x < this.min.x || this.max.y < this.min.y;
    }
    getCenter(e) {
        return this.isEmpty() ? e.set(0, 0) : e.addVectors(this.min, this.max).multiplyScalar(.5);
    }
    getSize(e) {
        return this.isEmpty() ? e.set(0, 0) : e.subVectors(this.max, this.min);
    }
    expandByPoint(e) {
        return this.min.min(e), this.max.max(e), this;
    }
    expandByVector(e) {
        return this.min.sub(e), this.max.add(e), this;
    }
    expandByScalar(e) {
        return this.min.addScalar(-e), this.max.addScalar(e), this;
    }
    containsPoint(e) {
        return !(e.x < this.min.x || e.x > this.max.x || e.y < this.min.y || e.y > this.max.y);
    }
    containsBox(e) {
        return this.min.x <= e.min.x && e.max.x <= this.max.x && this.min.y <= e.min.y && e.max.y <= this.max.y;
    }
    getParameter(e, t) {
        return t.set((e.x - this.min.x) / (this.max.x - this.min.x), (e.y - this.min.y) / (this.max.y - this.min.y));
    }
    intersectsBox(e) {
        return !(e.max.x < this.min.x || e.min.x > this.max.x || e.max.y < this.min.y || e.min.y > this.max.y);
    }
    clampPoint(e, t) {
        return t.copy(e).clamp(this.min, this.max);
    }
    distanceToPoint(e) {
        return Ic.copy(e).clamp(this.min, this.max).sub(e).length();
    }
    intersect(e) {
        return this.min.max(e.min), this.max.min(e.max), this;
    }
    union(e) {
        return this.min.min(e.min), this.max.max(e.max), this;
    }
    translate(e) {
        return this.min.add(e), this.max.add(e), this;
    }
    equals(e) {
        return e.min.equals(this.min) && e.max.equals(this.max);
    }
};
qi.prototype.isBox2 = !0;
var Dc = new M, Ts = new M, Kh = class {
    constructor(e = new M, t = new M){
        this.start = e, this.end = t;
    }
    set(e, t) {
        return this.start.copy(e), this.end.copy(t), this;
    }
    copy(e) {
        return this.start.copy(e.start), this.end.copy(e.end), this;
    }
    getCenter(e) {
        return e.addVectors(this.start, this.end).multiplyScalar(.5);
    }
    delta(e) {
        return e.subVectors(this.end, this.start);
    }
    distanceSq() {
        return this.start.distanceToSquared(this.end);
    }
    distance() {
        return this.start.distanceTo(this.end);
    }
    at(e, t) {
        return this.delta(t).multiplyScalar(e).add(this.start);
    }
    closestPointToPointParameter(e, t) {
        Dc.subVectors(e, this.start), Ts.subVectors(this.end, this.start);
        let n = Ts.dot(Ts), r = Ts.dot(Dc) / n;
        return t && (r = mt(r, 0, 1)), r;
    }
    closestPointToPoint(e, t, n) {
        let i = this.closestPointToPointParameter(e, t);
        return this.delta(n).multiplyScalar(i).add(this.start);
    }
    applyMatrix4(e) {
        return this.start.applyMatrix4(e), this.end.applyMatrix4(e), this;
    }
    equals(e) {
        return e.start.equals(this.start) && e.end.equals(this.end);
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Fc = new M, Ly = class extends Ne {
    constructor(e, t){
        super();
        this.light = e, this.light.updateMatrixWorld(), this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.color = t;
        let n = new _e, i = [
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1,
            0,
            1,
            0,
            0,
            0,
            -1,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            1,
            0,
            0,
            0,
            0,
            -1,
            1
        ];
        for(let o = 0, a = 1, l = 32; o < l; o++, a++){
            let c = o / l * Math.PI * 2, h = a / l * Math.PI * 2;
            i.push(Math.cos(c), Math.sin(c), 1, Math.cos(h), Math.sin(h), 1);
        }
        n.setAttribute("position", new de(i, 3));
        let r = new ft({
            fog: !1,
            toneMapped: !1
        });
        this.cone = new wt(n, r), this.add(this.cone), this.update();
    }
    dispose() {
        this.cone.geometry.dispose(), this.cone.material.dispose();
    }
    update() {
        this.light.updateMatrixWorld();
        let e = this.light.distance ? this.light.distance : 1e3, t = e * Math.tan(this.light.angle);
        this.cone.scale.set(t, t, e), Fc.setFromMatrixPosition(this.light.target.matrixWorld), this.cone.lookAt(Fc), this.color !== void 0 ? this.cone.material.color.set(this.color) : this.cone.material.color.copy(this.light.color);
    }
}, yn = new M, Es = new pe, Qo = new pe, eu = class extends wt {
    constructor(e){
        let t = tu(e), n = new _e, i = [], r = [], o = new ae(0, 0, 1), a = new ae(0, 1, 0);
        for(let c = 0; c < t.length; c++){
            let h = t[c];
            h.parent && h.parent.isBone && (i.push(0, 0, 0), i.push(0, 0, 0), r.push(o.r, o.g, o.b), r.push(a.r, a.g, a.b));
        }
        n.setAttribute("position", new de(i, 3)), n.setAttribute("color", new de(r, 3));
        let l = new ft({
            vertexColors: !0,
            depthTest: !1,
            depthWrite: !1,
            toneMapped: !1,
            transparent: !0
        });
        super(n, l);
        this.type = "SkeletonHelper", this.isSkeletonHelper = !0, this.root = e, this.bones = t, this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1;
    }
    updateMatrixWorld(e) {
        let t = this.bones, n = this.geometry, i = n.getAttribute("position");
        Qo.copy(this.root.matrixWorld).invert();
        for(let r = 0, o = 0; r < t.length; r++){
            let a = t[r];
            a.parent && a.parent.isBone && (Es.multiplyMatrices(Qo, a.matrixWorld), yn.setFromMatrixPosition(Es), i.setXYZ(o, yn.x, yn.y, yn.z), Es.multiplyMatrices(Qo, a.parent.matrixWorld), yn.setFromMatrixPosition(Es), i.setXYZ(o + 1, yn.x, yn.y, yn.z), o += 2);
        }
        n.getAttribute("position").needsUpdate = !0, super.updateMatrixWorld(e);
    }
};
function tu(s) {
    let e = [];
    s && s.isBone && e.push(s);
    for(let t = 0; t < s.children.length; t++)e.push.apply(e, tu(s.children[t]));
    return e;
}
var Ry = class extends st {
    constructor(e, t, n){
        let i = new Fi(t, 4, 2), r = new hn({
            wireframe: !0,
            fog: !1,
            toneMapped: !1
        });
        super(i, r);
        this.light = e, this.light.updateMatrixWorld(), this.color = n, this.type = "PointLightHelper", this.matrix = this.light.matrixWorld, this.matrixAutoUpdate = !1, this.update();
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
    update() {
        this.color !== void 0 ? this.material.color.set(this.color) : this.material.color.copy(this.light.color);
    }
}, Py = new M, Nc = new ae, Bc = new ae, Iy = class extends Ne {
    constructor(e, t, n){
        super();
        this.light = e, this.light.updateMatrixWorld(), this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.color = n;
        let i = new Ii(t);
        i.rotateY(Math.PI * .5), this.material = new hn({
            wireframe: !0,
            fog: !1,
            toneMapped: !1
        }), this.color === void 0 && (this.material.vertexColors = !0);
        let r = i.getAttribute("position"), o = new Float32Array(r.count * 3);
        i.setAttribute("color", new Ue(o, 3)), this.add(new st(i, this.material)), this.update();
    }
    dispose() {
        this.children[0].geometry.dispose(), this.children[0].material.dispose();
    }
    update() {
        let e = this.children[0];
        if (this.color !== void 0) this.material.color.set(this.color);
        else {
            let t = e.geometry.getAttribute("color");
            Nc.copy(this.light.color), Bc.copy(this.light.groundColor);
            for(let n = 0, i = t.count; n < i; n++){
                let r = n < i / 2 ? Nc : Bc;
                t.setXYZ(n, r.r, r.g, r.b);
            }
            t.needsUpdate = !0;
        }
        e.lookAt(Py.setFromMatrixPosition(this.light.matrixWorld).negate());
    }
}, nu = class extends wt {
    constructor(e = 10, t = 10, n = 4473924, i = 8947848){
        n = new ae(n), i = new ae(i);
        let r = t / 2, o = e / t, a = e / 2, l = [], c = [];
        for(let d = 0, f = 0, m = -a; d <= t; d++, m += o){
            l.push(-a, 0, m, a, 0, m), l.push(m, 0, -a, m, 0, a);
            let x = d === r ? n : i;
            x.toArray(c, f), f += 3, x.toArray(c, f), f += 3, x.toArray(c, f), f += 3, x.toArray(c, f), f += 3;
        }
        let h = new _e;
        h.setAttribute("position", new de(l, 3)), h.setAttribute("color", new de(c, 3));
        let u = new ft({
            vertexColors: !0,
            toneMapped: !1
        });
        super(h, u);
        this.type = "GridHelper";
    }
}, Dy = class extends wt {
    constructor(e = 10, t = 16, n = 8, i = 64, r = 4473924, o = 8947848){
        r = new ae(r), o = new ae(o);
        let a = [], l = [];
        for(let u = 0; u <= t; u++){
            let d = u / t * (Math.PI * 2), f = Math.sin(d) * e, m = Math.cos(d) * e;
            a.push(0, 0, 0), a.push(f, 0, m);
            let x = u & 1 ? r : o;
            l.push(x.r, x.g, x.b), l.push(x.r, x.g, x.b);
        }
        for(let u1 = 0; u1 <= n; u1++){
            let d1 = u1 & 1 ? r : o, f1 = e - e / n * u1;
            for(let m1 = 0; m1 < i; m1++){
                let x1 = m1 / i * (Math.PI * 2), v = Math.sin(x1) * f1, g = Math.cos(x1) * f1;
                a.push(v, 0, g), l.push(d1.r, d1.g, d1.b), x1 = (m1 + 1) / i * (Math.PI * 2), v = Math.sin(x1) * f1, g = Math.cos(x1) * f1, a.push(v, 0, g), l.push(d1.r, d1.g, d1.b);
            }
        }
        let c = new _e;
        c.setAttribute("position", new de(a, 3)), c.setAttribute("color", new de(l, 3));
        let h = new ft({
            vertexColors: !0,
            toneMapped: !1
        });
        super(c, h);
        this.type = "PolarGridHelper";
    }
}, zc = new M, As = new M, Uc = new M, Fy = class extends Ne {
    constructor(e, t, n){
        super();
        this.light = e, this.light.updateMatrixWorld(), this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.color = n, t === void 0 && (t = 1);
        let i = new _e;
        i.setAttribute("position", new de([
            -t,
            t,
            0,
            t,
            t,
            0,
            t,
            -t,
            0,
            -t,
            -t,
            0,
            -t,
            t,
            0
        ], 3));
        let r = new ft({
            fog: !1,
            toneMapped: !1
        });
        this.lightPlane = new on(i, r), this.add(this.lightPlane), i = new _e, i.setAttribute("position", new de([
            0,
            0,
            0,
            0,
            0,
            1
        ], 3)), this.targetLine = new on(i, r), this.add(this.targetLine), this.update();
    }
    dispose() {
        this.lightPlane.geometry.dispose(), this.lightPlane.material.dispose(), this.targetLine.geometry.dispose(), this.targetLine.material.dispose();
    }
    update() {
        zc.setFromMatrixPosition(this.light.matrixWorld), As.setFromMatrixPosition(this.light.target.matrixWorld), Uc.subVectors(As, zc), this.lightPlane.lookAt(As), this.color !== void 0 ? (this.lightPlane.material.color.set(this.color), this.targetLine.material.color.set(this.color)) : (this.lightPlane.material.color.copy(this.light.color), this.targetLine.material.color.copy(this.light.color)), this.targetLine.lookAt(As), this.targetLine.scale.z = Uc.length();
    }
}, Cs = new M, Qe = new Ir, Ny = class extends wt {
    constructor(e){
        let t = new _e, n = new ft({
            color: 16777215,
            vertexColors: !0,
            toneMapped: !1
        }), i = [], r = [], o = {}, a = new ae(16755200), l = new ae(16711680), c = new ae(43775), h = new ae(16777215), u = new ae(3355443);
        d("n1", "n2", a), d("n2", "n4", a), d("n4", "n3", a), d("n3", "n1", a), d("f1", "f2", a), d("f2", "f4", a), d("f4", "f3", a), d("f3", "f1", a), d("n1", "f1", a), d("n2", "f2", a), d("n3", "f3", a), d("n4", "f4", a), d("p", "n1", l), d("p", "n2", l), d("p", "n3", l), d("p", "n4", l), d("u1", "u2", c), d("u2", "u3", c), d("u3", "u1", c), d("c", "t", h), d("p", "c", u), d("cn1", "cn2", u), d("cn3", "cn4", u), d("cf1", "cf2", u), d("cf3", "cf4", u);
        function d(m, x, v) {
            f(m, v), f(x, v);
        }
        function f(m, x) {
            i.push(0, 0, 0), r.push(x.r, x.g, x.b), o[m] === void 0 && (o[m] = []), o[m].push(i.length / 3 - 1);
        }
        t.setAttribute("position", new de(i, 3)), t.setAttribute("color", new de(r, 3));
        super(t, n);
        this.type = "CameraHelper", this.camera = e, this.camera.updateProjectionMatrix && this.camera.updateProjectionMatrix(), this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.pointMap = o, this.update();
    }
    update() {
        let e = this.geometry, t = this.pointMap, n = 1, i = 1;
        Qe.projectionMatrixInverse.copy(this.camera.projectionMatrixInverse), et("c", t, e, Qe, 0, 0, -1), et("t", t, e, Qe, 0, 0, 1), et("n1", t, e, Qe, -n, -i, -1), et("n2", t, e, Qe, n, -i, -1), et("n3", t, e, Qe, -n, i, -1), et("n4", t, e, Qe, n, i, -1), et("f1", t, e, Qe, -n, -i, 1), et("f2", t, e, Qe, n, -i, 1), et("f3", t, e, Qe, -n, i, 1), et("f4", t, e, Qe, n, i, 1), et("u1", t, e, Qe, n * .7, i * 1.1, -1), et("u2", t, e, Qe, -n * .7, i * 1.1, -1), et("u3", t, e, Qe, 0, i * 2, -1), et("cf1", t, e, Qe, -n, 0, 1), et("cf2", t, e, Qe, n, 0, 1), et("cf3", t, e, Qe, 0, -i, 1), et("cf4", t, e, Qe, 0, i, 1), et("cn1", t, e, Qe, -n, 0, -1), et("cn2", t, e, Qe, n, 0, -1), et("cn3", t, e, Qe, 0, -i, -1), et("cn4", t, e, Qe, 0, i, -1), e.getAttribute("position").needsUpdate = !0;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
};
function et(s, e, t, n, i, r, o) {
    Cs.set(i, r, o).unproject(n);
    let a = e[s];
    if (a !== void 0) {
        let l = t.getAttribute("position");
        for(let c = 0, h = a.length; c < h; c++)l.setXYZ(a[c], Cs.x, Cs.y, Cs.z);
    }
}
var Ls = new Lt, iu = class extends wt {
    constructor(e, t = 16776960){
        let n = new Uint16Array([
            0,
            1,
            1,
            2,
            2,
            3,
            3,
            0,
            4,
            5,
            5,
            6,
            6,
            7,
            7,
            4,
            0,
            4,
            1,
            5,
            2,
            6,
            3,
            7
        ]), i = new Float32Array(8 * 3), r = new _e;
        r.setIndex(new Ue(n, 1)), r.setAttribute("position", new Ue(i, 3));
        super(r, new ft({
            color: t,
            toneMapped: !1
        }));
        this.object = e, this.type = "BoxHelper", this.matrixAutoUpdate = !1, this.update();
    }
    update(e) {
        if (e !== void 0 && console.warn("THREE.BoxHelper: .update() has no longer arguments."), this.object !== void 0 && Ls.setFromObject(this.object), Ls.isEmpty()) return;
        let t = Ls.min, n = Ls.max, i = this.geometry.attributes.position, r = i.array;
        r[0] = n.x, r[1] = n.y, r[2] = n.z, r[3] = t.x, r[4] = n.y, r[5] = n.z, r[6] = t.x, r[7] = t.y, r[8] = n.z, r[9] = n.x, r[10] = t.y, r[11] = n.z, r[12] = n.x, r[13] = n.y, r[14] = t.z, r[15] = t.x, r[16] = n.y, r[17] = t.z, r[18] = t.x, r[19] = t.y, r[20] = t.z, r[21] = n.x, r[22] = t.y, r[23] = t.z, i.needsUpdate = !0, this.geometry.computeBoundingSphere();
    }
    setFromObject(e) {
        return this.object = e, this.update(), this;
    }
    copy(e) {
        return wt.prototype.copy.call(this, e), this.object = e.object, this;
    }
}, By = class extends wt {
    constructor(e, t = 16776960){
        let n = new Uint16Array([
            0,
            1,
            1,
            2,
            2,
            3,
            3,
            0,
            4,
            5,
            5,
            6,
            6,
            7,
            7,
            4,
            0,
            4,
            1,
            5,
            2,
            6,
            3,
            7
        ]), i = [
            1,
            1,
            1,
            -1,
            1,
            1,
            -1,
            -1,
            1,
            1,
            -1,
            1,
            1,
            1,
            -1,
            -1,
            1,
            -1,
            -1,
            -1,
            -1,
            1,
            -1,
            -1
        ], r = new _e;
        r.setIndex(new Ue(n, 1)), r.setAttribute("position", new de(i, 3));
        super(r, new ft({
            color: t,
            toneMapped: !1
        }));
        this.box = e, this.type = "Box3Helper", this.geometry.computeBoundingSphere();
    }
    updateMatrixWorld(e) {
        let t = this.box;
        t.isEmpty() || (t.getCenter(this.position), t.getSize(this.scale), this.scale.multiplyScalar(.5), super.updateMatrixWorld(e));
    }
}, zy = class extends on {
    constructor(e, t = 1, n = 16776960){
        let i = n, r = [
            1,
            -1,
            1,
            -1,
            1,
            1,
            -1,
            -1,
            1,
            1,
            1,
            1,
            -1,
            1,
            1,
            -1,
            -1,
            1,
            1,
            -1,
            1,
            1,
            1,
            1,
            0,
            0,
            1,
            0,
            0,
            0
        ], o = new _e;
        o.setAttribute("position", new de(r, 3)), o.computeBoundingSphere();
        super(o, new ft({
            color: i,
            toneMapped: !1
        }));
        this.type = "PlaneHelper", this.plane = e, this.size = t;
        let a = [
            1,
            1,
            1,
            -1,
            1,
            1,
            -1,
            -1,
            1,
            1,
            1,
            1,
            -1,
            -1,
            1,
            1,
            -1,
            1
        ], l = new _e;
        l.setAttribute("position", new de(a, 3)), l.computeBoundingSphere(), this.add(new st(l, new hn({
            color: i,
            opacity: .2,
            transparent: !0,
            depthWrite: !1,
            toneMapped: !1
        })));
    }
    updateMatrixWorld(e) {
        let t = -this.plane.constant;
        Math.abs(t) < 1e-8 && (t = 1e-8), this.scale.set(.5 * this.size, .5 * this.size, t), this.children[0].material.side = t < 0 ? it : Ai, this.lookAt(this.plane.normal), super.updateMatrixWorld(e);
    }
}, Oc = new M, Rs, Ko, Uy = class extends Ne {
    constructor(e = new M(0, 0, 1), t = new M(0, 0, 0), n = 1, i = 16776960, r = n * .2, o = r * .2){
        super();
        this.type = "ArrowHelper", Rs === void 0 && (Rs = new _e, Rs.setAttribute("position", new de([
            0,
            0,
            0,
            0,
            1,
            0
        ], 3)), Ko = new Jn(0, .5, 1, 5, 1), Ko.translate(0, -.5, 0)), this.position.copy(t), this.line = new on(Rs, new ft({
            color: i,
            toneMapped: !1
        })), this.line.matrixAutoUpdate = !1, this.add(this.line), this.cone = new st(Ko, new hn({
            color: i,
            toneMapped: !1
        })), this.cone.matrixAutoUpdate = !1, this.add(this.cone), this.setDirection(e), this.setLength(n, r, o);
    }
    setDirection(e) {
        if (e.y > .99999) this.quaternion.set(0, 0, 0, 1);
        else if (e.y < -.99999) this.quaternion.set(1, 0, 0, 0);
        else {
            Oc.set(e.z, 0, -e.x).normalize();
            let t = Math.acos(e.y);
            this.quaternion.setFromAxisAngle(Oc, t);
        }
    }
    setLength(e, t = e * .2, n = t * .2) {
        this.line.scale.set(1, Math.max(1e-4, e - t), 1), this.line.updateMatrix(), this.cone.scale.set(n, t, n), this.cone.position.y = e, this.cone.updateMatrix();
    }
    setColor(e) {
        this.line.material.color.set(e), this.cone.material.color.set(e);
    }
    copy(e) {
        return super.copy(e, !1), this.line.copy(e.line), this.cone.copy(e.cone), this;
    }
}, ru = class extends wt {
    constructor(e = 1){
        let t = [
            0,
            0,
            0,
            e,
            0,
            0,
            0,
            0,
            0,
            0,
            e,
            0,
            0,
            0,
            0,
            0,
            0,
            e
        ], n = [
            1,
            0,
            0,
            1,
            .6,
            0,
            0,
            1,
            0,
            .6,
            1,
            0,
            0,
            0,
            1,
            0,
            .6,
            1
        ], i = new _e;
        i.setAttribute("position", new de(t, 3)), i.setAttribute("color", new de(n, 3));
        let r = new ft({
            vertexColors: !0,
            toneMapped: !1
        });
        super(i, r);
        this.type = "AxesHelper";
    }
    setColors(e, t, n) {
        let i = new ae, r = this.geometry.attributes.color.array;
        return i.set(e), i.toArray(r, 0), i.toArray(r, 3), i.set(t), i.toArray(r, 6), i.toArray(r, 9), i.set(n), i.toArray(r, 12), i.toArray(r, 15), this.geometry.attributes.color.needsUpdate = !0, this;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, Oy = class {
    constructor(){
        this.type = "ShapePath", this.color = new ae, this.subPaths = [], this.currentPath = null;
    }
    moveTo(e, t) {
        return this.currentPath = new gr, this.subPaths.push(this.currentPath), this.currentPath.moveTo(e, t), this;
    }
    lineTo(e, t) {
        return this.currentPath.lineTo(e, t), this;
    }
    quadraticCurveTo(e, t, n, i) {
        return this.currentPath.quadraticCurveTo(e, t, n, i), this;
    }
    bezierCurveTo(e, t, n, i, r, o) {
        return this.currentPath.bezierCurveTo(e, t, n, i, r, o), this;
    }
    splineThru(e) {
        return this.currentPath.splineThru(e), this;
    }
    toShapes(e, t) {
        function n(p) {
            let _ = [];
            for(let y = 0, b = p.length; y < b; y++){
                let A = p[y], L = new Xt;
                L.curves = A.curves, _.push(L);
            }
            return _;
        }
        function i(p, _) {
            let y = _.length, b = !1;
            for(let A = y - 1, L = 0; L < y; A = L++){
                let I = _[A], k = _[L], B = k.x - I.x, P = k.y - I.y;
                if (Math.abs(P) > Number.EPSILON) {
                    if (P < 0 && (I = _[L], B = -B, k = _[A], P = -P), p.y < I.y || p.y > k.y) continue;
                    if (p.y === I.y) {
                        if (p.x === I.x) return !0;
                    } else {
                        let w = P * (p.x - I.x) - B * (p.y - I.y);
                        if (w === 0) return !0;
                        if (w < 0) continue;
                        b = !b;
                    }
                } else {
                    if (p.y !== I.y) continue;
                    if (k.x <= p.x && p.x <= I.x || I.x <= p.x && p.x <= k.x) return !0;
                }
            }
            return b;
        }
        let r = Jt.isClockWise, o = this.subPaths;
        if (o.length === 0) return [];
        if (t === !0) return n(o);
        let a, l, c, h = [];
        if (o.length === 1) return l = o[0], c = new Xt, c.curves = l.curves, h.push(c), h;
        let u = !r(o[0].getPoints());
        u = e ? !u : u;
        let d = [], f = [], m = [], x = 0, v;
        f[x] = void 0, m[x] = [];
        for(let p = 0, _ = o.length; p < _; p++)l = o[p], v = l.getPoints(), a = r(v), a = e ? !a : a, a ? (!u && f[x] && x++, f[x] = {
            s: new Xt,
            p: v
        }, f[x].s.curves = l.curves, u && x++, m[x] = []) : m[x].push({
            h: l,
            p: v[0]
        });
        if (!f[0]) return n(o);
        if (f.length > 1) {
            let p1 = !1, _1 = [];
            for(let y = 0, b = f.length; y < b; y++)d[y] = [];
            for(let y1 = 0, b1 = f.length; y1 < b1; y1++){
                let A = m[y1];
                for(let L = 0; L < A.length; L++){
                    let I = A[L], k = !0;
                    for(let B = 0; B < f.length; B++)i(I.p, f[B].p) && (y1 !== B && _1.push({
                        froms: y1,
                        tos: B,
                        hole: L
                    }), k ? (k = !1, d[B].push(I)) : p1 = !0);
                    k && d[y1].push(I);
                }
            }
            _1.length > 0 && (p1 || (m = d));
        }
        let g;
        for(let p2 = 0, _2 = f.length; p2 < _2; p2++){
            c = f[p2].s, h.push(c), g = m[p2];
            for(let y2 = 0, b2 = g.length; y2 < b2; y2++)c.holes.push(g[y2].h);
        }
        return h;
    }
}, su = new Float32Array(1), Hy = new Int32Array(su.buffer), ky = class {
    static toHalfFloat(e) {
        e > 65504 && (console.warn("THREE.DataUtils.toHalfFloat(): value exceeds 65504."), e = 65504), su[0] = e;
        let t = Hy[0], n = t >> 16 & 32768, i = t >> 12 & 2047, r = t >> 23 & 255;
        return r < 103 ? n : r > 142 ? (n |= 31744, n |= (r == 255 ? 0 : 1) && t & 8388607, n) : r < 113 ? (i |= 2048, n |= (i >> 114 - r) + (i >> 113 - r & 1), n) : (n |= r - 112 << 10 | i >> 1, n += i & 1, n);
    }
}, b0 = 0, w0 = 1, S0 = 0, T0 = 1, E0 = 2;
function A0(s) {
    return console.warn("THREE.MeshFaceMaterial has been removed. Use an Array instead."), s;
}
function C0(s = []) {
    return console.warn("THREE.MultiMaterial has been removed. Use an Array instead."), s.isMultiMaterial = !0, s.materials = s, s.clone = function() {
        return s.slice();
    }, s;
}
function L0(s, e) {
    return console.warn("THREE.PointCloud has been renamed to THREE.Points."), new zr(s, e);
}
function R0(s) {
    return console.warn("THREE.Particle has been renamed to THREE.Sprite."), new ro(s);
}
function P0(s, e) {
    return console.warn("THREE.ParticleSystem has been renamed to THREE.Points."), new zr(s, e);
}
function I0(s) {
    return console.warn("THREE.PointCloudMaterial has been renamed to THREE.PointsMaterial."), new jn(s);
}
function D0(s) {
    return console.warn("THREE.ParticleBasicMaterial has been renamed to THREE.PointsMaterial."), new jn(s);
}
function F0(s) {
    return console.warn("THREE.ParticleSystemMaterial has been renamed to THREE.PointsMaterial."), new jn(s);
}
function N0(s, e, t) {
    return console.warn("THREE.Vertex has been removed. Use THREE.Vector3 instead."), new M(s, e, t);
}
function B0(s, e) {
    return console.warn("THREE.DynamicBufferAttribute has been removed. Use new THREE.BufferAttribute().setUsage( THREE.DynamicDrawUsage ) instead."), new Ue(s, e).setUsage(ur);
}
function z0(s, e) {
    return console.warn("THREE.Int8Attribute has been removed. Use new THREE.Int8BufferAttribute() instead."), new jc(s, e);
}
function U0(s, e) {
    return console.warn("THREE.Uint8Attribute has been removed. Use new THREE.Uint8BufferAttribute() instead."), new Qc(s, e);
}
function O0(s, e) {
    return console.warn("THREE.Uint8ClampedAttribute has been removed. Use new THREE.Uint8ClampedBufferAttribute() instead."), new Kc(s, e);
}
function H0(s, e) {
    return console.warn("THREE.Int16Attribute has been removed. Use new THREE.Int16BufferAttribute() instead."), new eh(s, e);
}
function k0(s, e) {
    return console.warn("THREE.Uint16Attribute has been removed. Use new THREE.Uint16BufferAttribute() instead."), new Ys(s, e);
}
function G0(s, e) {
    return console.warn("THREE.Int32Attribute has been removed. Use new THREE.Int32BufferAttribute() instead."), new th(s, e);
}
function V0(s, e) {
    return console.warn("THREE.Uint32Attribute has been removed. Use new THREE.Uint32BufferAttribute() instead."), new Zs(s, e);
}
function W0(s, e) {
    return console.warn("THREE.Float32Attribute has been removed. Use new THREE.Float32BufferAttribute() instead."), new de(s, e);
}
function q0(s, e) {
    return console.warn("THREE.Float64Attribute has been removed. Use new THREE.Float64BufferAttribute() instead."), new ih(s, e);
}
Ct.create = function(s, e) {
    return console.log("THREE.Curve.create() has been deprecated"), s.prototype = Object.create(Ct.prototype), s.prototype.constructor = s, s.prototype.getPoint = e, s;
};
gr.prototype.fromPoints = function(s) {
    return console.warn("THREE.Path: .fromPoints() has been renamed to .setFromPoints()."), this.setFromPoints(s);
};
function X0(s) {
    return console.warn("THREE.AxisHelper has been renamed to THREE.AxesHelper."), new ru(s);
}
function J0(s, e) {
    return console.warn("THREE.BoundingBoxHelper has been deprecated. Creating a THREE.BoxHelper instead."), new iu(s, e);
}
function Y0(s, e) {
    return console.warn("THREE.EdgesHelper has been removed. Use THREE.EdgesGeometry instead."), new wt(new _a(s.geometry), new ft({
        color: e !== void 0 ? e : 16777215
    }));
}
nu.prototype.setColors = function() {
    console.error("THREE.GridHelper: setColors() has been deprecated, pass them in the constructor instead.");
};
eu.prototype.update = function() {
    console.error("THREE.SkeletonHelper: update() no longer needs to be called.");
};
function Z0(s, e) {
    return console.warn("THREE.WireframeHelper has been removed. Use THREE.WireframeGeometry instead."), new wt(new Ea(s.geometry), new ft({
        color: e !== void 0 ? e : 16777215
    }));
}
bt.prototype.extractUrlBase = function(s) {
    return console.warn("THREE.Loader: .extractUrlBase() has been deprecated. Use THREE.LoaderUtils.extractUrlBase() instead."), Gs.extractUrlBase(s);
};
bt.Handlers = {
    add: function() {
        console.error("THREE.Loader: Handlers.add() has been removed. Use LoadingManager.addHandler() instead.");
    },
    get: function() {
        console.error("THREE.Loader: Handlers.get() has been removed. Use LoadingManager.getHandler() instead.");
    }
};
function $0(s) {
    return console.warn("THREE.XHRLoader has been renamed to THREE.FileLoader."), new Yt(s);
}
function j0(s) {
    return console.warn("THREE.BinaryTextureLoader has been renamed to THREE.DataTextureLoader."), new Nh(s);
}
qi.prototype.center = function(s) {
    return console.warn("THREE.Box2: .center() has been renamed to .getCenter()."), this.getCenter(s);
};
qi.prototype.empty = function() {
    return console.warn("THREE.Box2: .empty() has been renamed to .isEmpty()."), this.isEmpty();
};
qi.prototype.isIntersectionBox = function(s) {
    return console.warn("THREE.Box2: .isIntersectionBox() has been renamed to .intersectsBox()."), this.intersectsBox(s);
};
qi.prototype.size = function(s) {
    return console.warn("THREE.Box2: .size() has been renamed to .getSize()."), this.getSize(s);
};
Lt.prototype.center = function(s) {
    return console.warn("THREE.Box3: .center() has been renamed to .getCenter()."), this.getCenter(s);
};
Lt.prototype.empty = function() {
    return console.warn("THREE.Box3: .empty() has been renamed to .isEmpty()."), this.isEmpty();
};
Lt.prototype.isIntersectionBox = function(s) {
    return console.warn("THREE.Box3: .isIntersectionBox() has been renamed to .intersectsBox()."), this.intersectsBox(s);
};
Lt.prototype.isIntersectionSphere = function(s) {
    return console.warn("THREE.Box3: .isIntersectionSphere() has been renamed to .intersectsSphere()."), this.intersectsSphere(s);
};
Lt.prototype.size = function(s) {
    return console.warn("THREE.Box3: .size() has been renamed to .getSize()."), this.getSize(s);
};
An.prototype.empty = function() {
    return console.warn("THREE.Sphere: .empty() has been renamed to .isEmpty()."), this.isEmpty();
};
Dr.prototype.setFromMatrix = function(s) {
    return console.warn("THREE.Frustum: .setFromMatrix() has been renamed to .setFromProjectionMatrix()."), this.setFromProjectionMatrix(s);
};
Kh.prototype.center = function(s) {
    return console.warn("THREE.Line3: .center() has been renamed to .getCenter()."), this.getCenter(s);
};
lt.prototype.flattenToArrayOffset = function(s, e) {
    return console.warn("THREE.Matrix3: .flattenToArrayOffset() has been deprecated. Use .toArray() instead."), this.toArray(s, e);
};
lt.prototype.multiplyVector3 = function(s) {
    return console.warn("THREE.Matrix3: .multiplyVector3() has been removed. Use vector.applyMatrix3( matrix ) instead."), s.applyMatrix3(this);
};
lt.prototype.multiplyVector3Array = function() {
    console.error("THREE.Matrix3: .multiplyVector3Array() has been removed.");
};
lt.prototype.applyToBufferAttribute = function(s) {
    return console.warn("THREE.Matrix3: .applyToBufferAttribute() has been removed. Use attribute.applyMatrix3( matrix ) instead."), s.applyMatrix3(this);
};
lt.prototype.applyToVector3Array = function() {
    console.error("THREE.Matrix3: .applyToVector3Array() has been removed.");
};
lt.prototype.getInverse = function(s) {
    return console.warn("THREE.Matrix3: .getInverse() has been removed. Use matrixInv.copy( matrix ).invert(); instead."), this.copy(s).invert();
};
pe.prototype.extractPosition = function(s) {
    return console.warn("THREE.Matrix4: .extractPosition() has been renamed to .copyPosition()."), this.copyPosition(s);
};
pe.prototype.flattenToArrayOffset = function(s, e) {
    return console.warn("THREE.Matrix4: .flattenToArrayOffset() has been deprecated. Use .toArray() instead."), this.toArray(s, e);
};
pe.prototype.getPosition = function() {
    return console.warn("THREE.Matrix4: .getPosition() has been removed. Use Vector3.setFromMatrixPosition( matrix ) instead."), new M().setFromMatrixColumn(this, 3);
};
pe.prototype.setRotationFromQuaternion = function(s) {
    return console.warn("THREE.Matrix4: .setRotationFromQuaternion() has been renamed to .makeRotationFromQuaternion()."), this.makeRotationFromQuaternion(s);
};
pe.prototype.multiplyToArray = function() {
    console.warn("THREE.Matrix4: .multiplyToArray() has been removed.");
};
pe.prototype.multiplyVector3 = function(s) {
    return console.warn("THREE.Matrix4: .multiplyVector3() has been removed. Use vector.applyMatrix4( matrix ) instead."), s.applyMatrix4(this);
};
pe.prototype.multiplyVector4 = function(s) {
    return console.warn("THREE.Matrix4: .multiplyVector4() has been removed. Use vector.applyMatrix4( matrix ) instead."), s.applyMatrix4(this);
};
pe.prototype.multiplyVector3Array = function() {
    console.error("THREE.Matrix4: .multiplyVector3Array() has been removed.");
};
pe.prototype.rotateAxis = function(s) {
    console.warn("THREE.Matrix4: .rotateAxis() has been removed. Use Vector3.transformDirection( matrix ) instead."), s.transformDirection(this);
};
pe.prototype.crossVector = function(s) {
    return console.warn("THREE.Matrix4: .crossVector() has been removed. Use vector.applyMatrix4( matrix ) instead."), s.applyMatrix4(this);
};
pe.prototype.translate = function() {
    console.error("THREE.Matrix4: .translate() has been removed.");
};
pe.prototype.rotateX = function() {
    console.error("THREE.Matrix4: .rotateX() has been removed.");
};
pe.prototype.rotateY = function() {
    console.error("THREE.Matrix4: .rotateY() has been removed.");
};
pe.prototype.rotateZ = function() {
    console.error("THREE.Matrix4: .rotateZ() has been removed.");
};
pe.prototype.rotateByAxis = function() {
    console.error("THREE.Matrix4: .rotateByAxis() has been removed.");
};
pe.prototype.applyToBufferAttribute = function(s) {
    return console.warn("THREE.Matrix4: .applyToBufferAttribute() has been removed. Use attribute.applyMatrix4( matrix ) instead."), s.applyMatrix4(this);
};
pe.prototype.applyToVector3Array = function() {
    console.error("THREE.Matrix4: .applyToVector3Array() has been removed.");
};
pe.prototype.makeFrustum = function(s, e, t, n, i, r) {
    return console.warn("THREE.Matrix4: .makeFrustum() has been removed. Use .makePerspective( left, right, top, bottom, near, far ) instead."), this.makePerspective(s, e, n, t, i, r);
};
pe.prototype.getInverse = function(s) {
    return console.warn("THREE.Matrix4: .getInverse() has been removed. Use matrixInv.copy( matrix ).invert(); instead."), this.copy(s).invert();
};
Wt.prototype.isIntersectionLine = function(s) {
    return console.warn("THREE.Plane: .isIntersectionLine() has been renamed to .intersectsLine()."), this.intersectsLine(s);
};
gt.prototype.multiplyVector3 = function(s) {
    return console.warn("THREE.Quaternion: .multiplyVector3() has been removed. Use is now vector.applyQuaternion( quaternion ) instead."), s.applyQuaternion(this);
};
gt.prototype.inverse = function() {
    return console.warn("THREE.Quaternion: .inverse() has been renamed to invert()."), this.invert();
};
Cn.prototype.isIntersectionBox = function(s) {
    return console.warn("THREE.Ray: .isIntersectionBox() has been renamed to .intersectsBox()."), this.intersectsBox(s);
};
Cn.prototype.isIntersectionPlane = function(s) {
    return console.warn("THREE.Ray: .isIntersectionPlane() has been renamed to .intersectsPlane()."), this.intersectsPlane(s);
};
Cn.prototype.isIntersectionSphere = function(s) {
    return console.warn("THREE.Ray: .isIntersectionSphere() has been renamed to .intersectsSphere()."), this.intersectsSphere(s);
};
nt.prototype.area = function() {
    return console.warn("THREE.Triangle: .area() has been renamed to .getArea()."), this.getArea();
};
nt.prototype.barycoordFromPoint = function(s, e) {
    return console.warn("THREE.Triangle: .barycoordFromPoint() has been renamed to .getBarycoord()."), this.getBarycoord(s, e);
};
nt.prototype.midpoint = function(s) {
    return console.warn("THREE.Triangle: .midpoint() has been renamed to .getMidpoint()."), this.getMidpoint(s);
};
nt.prototypenormal = function(s) {
    return console.warn("THREE.Triangle: .normal() has been renamed to .getNormal()."), this.getNormal(s);
};
nt.prototype.plane = function(s) {
    return console.warn("THREE.Triangle: .plane() has been renamed to .getPlane()."), this.getPlane(s);
};
nt.barycoordFromPoint = function(s, e, t, n, i) {
    return console.warn("THREE.Triangle: .barycoordFromPoint() has been renamed to .getBarycoord()."), nt.getBarycoord(s, e, t, n, i);
};
nt.normal = function(s, e, t, n) {
    return console.warn("THREE.Triangle: .normal() has been renamed to .getNormal()."), nt.getNormal(s, e, t, n);
};
Xt.prototype.extractAllPoints = function(s) {
    return console.warn("THREE.Shape: .extractAllPoints() has been removed. Use .extractPoints() instead."), this.extractPoints(s);
};
Xt.prototype.extrude = function(s) {
    return console.warn("THREE.Shape: .extrude() has been removed. Use ExtrudeGeometry() instead."), new ln(this, s);
};
Xt.prototype.makeGeometry = function(s) {
    return console.warn("THREE.Shape: .makeGeometry() has been removed. Use ShapeGeometry() instead."), new Di(this, s);
};
X.prototype.fromAttribute = function(s, e, t) {
    return console.warn("THREE.Vector2: .fromAttribute() has been renamed to .fromBufferAttribute()."), this.fromBufferAttribute(s, e, t);
};
X.prototype.distanceToManhattan = function(s) {
    return console.warn("THREE.Vector2: .distanceToManhattan() has been renamed to .manhattanDistanceTo()."), this.manhattanDistanceTo(s);
};
X.prototype.lengthManhattan = function() {
    return console.warn("THREE.Vector2: .lengthManhattan() has been renamed to .manhattanLength()."), this.manhattanLength();
};
M.prototype.setEulerFromRotationMatrix = function() {
    console.error("THREE.Vector3: .setEulerFromRotationMatrix() has been removed. Use Euler.setFromRotationMatrix() instead.");
};
M.prototype.setEulerFromQuaternion = function() {
    console.error("THREE.Vector3: .setEulerFromQuaternion() has been removed. Use Euler.setFromQuaternion() instead.");
};
M.prototype.getPositionFromMatrix = function(s) {
    return console.warn("THREE.Vector3: .getPositionFromMatrix() has been renamed to .setFromMatrixPosition()."), this.setFromMatrixPosition(s);
};
M.prototype.getScaleFromMatrix = function(s) {
    return console.warn("THREE.Vector3: .getScaleFromMatrix() has been renamed to .setFromMatrixScale()."), this.setFromMatrixScale(s);
};
M.prototype.getColumnFromMatrix = function(s, e) {
    return console.warn("THREE.Vector3: .getColumnFromMatrix() has been renamed to .setFromMatrixColumn()."), this.setFromMatrixColumn(e, s);
};
M.prototype.applyProjection = function(s) {
    return console.warn("THREE.Vector3: .applyProjection() has been removed. Use .applyMatrix4( m ) instead."), this.applyMatrix4(s);
};
M.prototype.fromAttribute = function(s, e, t) {
    return console.warn("THREE.Vector3: .fromAttribute() has been renamed to .fromBufferAttribute()."), this.fromBufferAttribute(s, e, t);
};
M.prototype.distanceToManhattan = function(s) {
    return console.warn("THREE.Vector3: .distanceToManhattan() has been renamed to .manhattanDistanceTo()."), this.manhattanDistanceTo(s);
};
M.prototype.lengthManhattan = function() {
    return console.warn("THREE.Vector3: .lengthManhattan() has been renamed to .manhattanLength()."), this.manhattanLength();
};
Ve.prototype.fromAttribute = function(s, e, t) {
    return console.warn("THREE.Vector4: .fromAttribute() has been renamed to .fromBufferAttribute()."), this.fromBufferAttribute(s, e, t);
};
Ve.prototype.lengthManhattan = function() {
    return console.warn("THREE.Vector4: .lengthManhattan() has been renamed to .manhattanLength()."), this.manhattanLength();
};
Ne.prototype.getChildByName = function(s) {
    return console.warn("THREE.Object3D: .getChildByName() has been renamed to .getObjectByName()."), this.getObjectByName(s);
};
Ne.prototype.renderDepth = function() {
    console.warn("THREE.Object3D: .renderDepth has been removed. Use .renderOrder, instead.");
};
Ne.prototype.translate = function(s, e) {
    return console.warn("THREE.Object3D: .translate() has been removed. Use .translateOnAxis( axis, distance ) instead."), this.translateOnAxis(e, s);
};
Ne.prototype.getWorldRotation = function() {
    console.error("THREE.Object3D: .getWorldRotation() has been removed. Use THREE.Object3D.getWorldQuaternion( target ) instead.");
};
Ne.prototype.applyMatrix = function(s) {
    return console.warn("THREE.Object3D: .applyMatrix() has been renamed to .applyMatrix4()."), this.applyMatrix4(s);
};
Object.defineProperties(Ne.prototype, {
    eulerOrder: {
        get: function() {
            return console.warn("THREE.Object3D: .eulerOrder is now .rotation.order."), this.rotation.order;
        },
        set: function(s) {
            console.warn("THREE.Object3D: .eulerOrder is now .rotation.order."), this.rotation.order = s;
        }
    },
    useQuaternion: {
        get: function() {
            console.warn("THREE.Object3D: .useQuaternion has been removed. The library now uses quaternions by default.");
        },
        set: function() {
            console.warn("THREE.Object3D: .useQuaternion has been removed. The library now uses quaternions by default.");
        }
    }
});
st.prototype.setDrawMode = function() {
    console.error("THREE.Mesh: .setDrawMode() has been removed. The renderer now always assumes THREE.TrianglesDrawMode. Transform your geometry via BufferGeometryUtils.toTrianglesDrawMode() if necessary.");
};
Object.defineProperties(st.prototype, {
    drawMode: {
        get: function() {
            return console.error("THREE.Mesh: .drawMode has been removed. The renderer now always assumes THREE.TrianglesDrawMode."), Fd;
        },
        set: function() {
            console.error("THREE.Mesh: .drawMode has been removed. The renderer now always assumes THREE.TrianglesDrawMode. Transform your geometry via BufferGeometryUtils.toTrianglesDrawMode() if necessary.");
        }
    }
});
so.prototype.initBones = function() {
    console.error("THREE.SkinnedMesh: initBones() has been removed.");
};
ut.prototype.setLens = function(s, e) {
    console.warn("THREE.PerspectiveCamera.setLens is deprecated. Use .setFocalLength and .filmGauge for a photographic setup."), e !== void 0 && (this.filmGauge = e), this.setFocalLength(s);
};
Object.defineProperties(Bt.prototype, {
    onlyShadow: {
        set: function() {
            console.warn("THREE.Light: .onlyShadow has been removed.");
        }
    },
    shadowCameraFov: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraFov is now .shadow.camera.fov."), this.shadow.camera.fov = s;
        }
    },
    shadowCameraLeft: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraLeft is now .shadow.camera.left."), this.shadow.camera.left = s;
        }
    },
    shadowCameraRight: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraRight is now .shadow.camera.right."), this.shadow.camera.right = s;
        }
    },
    shadowCameraTop: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraTop is now .shadow.camera.top."), this.shadow.camera.top = s;
        }
    },
    shadowCameraBottom: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraBottom is now .shadow.camera.bottom."), this.shadow.camera.bottom = s;
        }
    },
    shadowCameraNear: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraNear is now .shadow.camera.near."), this.shadow.camera.near = s;
        }
    },
    shadowCameraFar: {
        set: function(s) {
            console.warn("THREE.Light: .shadowCameraFar is now .shadow.camera.far."), this.shadow.camera.far = s;
        }
    },
    shadowCameraVisible: {
        set: function() {
            console.warn("THREE.Light: .shadowCameraVisible has been removed. Use new THREE.CameraHelper( light.shadow.camera ) instead.");
        }
    },
    shadowBias: {
        set: function(s) {
            console.warn("THREE.Light: .shadowBias is now .shadow.bias."), this.shadow.bias = s;
        }
    },
    shadowDarkness: {
        set: function() {
            console.warn("THREE.Light: .shadowDarkness has been removed.");
        }
    },
    shadowMapWidth: {
        set: function(s) {
            console.warn("THREE.Light: .shadowMapWidth is now .shadow.mapSize.width."), this.shadow.mapSize.width = s;
        }
    },
    shadowMapHeight: {
        set: function(s) {
            console.warn("THREE.Light: .shadowMapHeight is now .shadow.mapSize.height."), this.shadow.mapSize.height = s;
        }
    }
});
Object.defineProperties(Ue.prototype, {
    length: {
        get: function() {
            return console.warn("THREE.BufferAttribute: .length has been deprecated. Use .count instead."), this.array.length;
        }
    },
    dynamic: {
        get: function() {
            return console.warn("THREE.BufferAttribute: .dynamic has been deprecated. Use .usage instead."), this.usage === ur;
        },
        set: function() {
            console.warn("THREE.BufferAttribute: .dynamic has been deprecated. Use .usage instead."), this.setUsage(ur);
        }
    }
});
Ue.prototype.setDynamic = function(s) {
    return console.warn("THREE.BufferAttribute: .setDynamic() has been deprecated. Use .setUsage() instead."), this.setUsage(s === !0 ? ur : hr), this;
};
Ue.prototype.copyIndicesArray = function() {
    console.error("THREE.BufferAttribute: .copyIndicesArray() has been removed.");
}, Ue.prototype.setArray = function() {
    console.error("THREE.BufferAttribute: .setArray has been removed. Use BufferGeometry .setAttribute to replace/resize attribute buffers");
};
_e.prototype.addIndex = function(s) {
    console.warn("THREE.BufferGeometry: .addIndex() has been renamed to .setIndex()."), this.setIndex(s);
};
_e.prototype.addAttribute = function(s, e) {
    return console.warn("THREE.BufferGeometry: .addAttribute() has been renamed to .setAttribute()."), !(e && e.isBufferAttribute) && !(e && e.isInterleavedBufferAttribute) ? (console.warn("THREE.BufferGeometry: .addAttribute() now expects ( name, attribute )."), this.setAttribute(s, new Ue(arguments[1], arguments[2]))) : s === "index" ? (console.warn("THREE.BufferGeometry.addAttribute: Use .setIndex() for index attribute."), this.setIndex(e), this) : this.setAttribute(s, e);
};
_e.prototype.addDrawCall = function(s, e, t) {
    t !== void 0 && console.warn("THREE.BufferGeometry: .addDrawCall() no longer supports indexOffset."), console.warn("THREE.BufferGeometry: .addDrawCall() is now .addGroup()."), this.addGroup(s, e);
};
_e.prototype.clearDrawCalls = function() {
    console.warn("THREE.BufferGeometry: .clearDrawCalls() is now .clearGroups()."), this.clearGroups();
};
_e.prototype.computeOffsets = function() {
    console.warn("THREE.BufferGeometry: .computeOffsets() has been removed.");
};
_e.prototype.removeAttribute = function(s) {
    return console.warn("THREE.BufferGeometry: .removeAttribute() has been renamed to .deleteAttribute()."), this.deleteAttribute(s);
};
_e.prototype.applyMatrix = function(s) {
    return console.warn("THREE.BufferGeometry: .applyMatrix() has been renamed to .applyMatrix4()."), this.applyMatrix4(s);
};
Object.defineProperties(_e.prototype, {
    drawcalls: {
        get: function() {
            return console.error("THREE.BufferGeometry: .drawcalls has been renamed to .groups."), this.groups;
        }
    },
    offsets: {
        get: function() {
            return console.warn("THREE.BufferGeometry: .offsets has been renamed to .groups."), this.groups;
        }
    }
});
$n.prototype.setDynamic = function(s) {
    return console.warn("THREE.InterleavedBuffer: .setDynamic() has been deprecated. Use .setUsage() instead."), this.setUsage(s === !0 ? ur : hr), this;
};
$n.prototype.setArray = function() {
    console.error("THREE.InterleavedBuffer: .setArray has been removed. Use BufferGeometry .setAttribute to replace/resize attribute buffers");
};
ln.prototype.getArrays = function() {
    console.error("THREE.ExtrudeGeometry: .getArrays() has been removed.");
};
ln.prototype.addShapeList = function() {
    console.error("THREE.ExtrudeGeometry: .addShapeList() has been removed.");
};
ln.prototype.addShape = function() {
    console.error("THREE.ExtrudeGeometry: .addShape() has been removed.");
};
no.prototype.dispose = function() {
    console.error("THREE.Scene: .dispose() has been removed.");
};
go.prototype.onUpdate = function() {
    return console.warn("THREE.Uniform: .onUpdate() has been removed. Use object.onBeforeRender() instead."), this;
};
Object.defineProperties(dt.prototype, {
    wrapAround: {
        get: function() {
            console.warn("THREE.Material: .wrapAround has been removed.");
        },
        set: function() {
            console.warn("THREE.Material: .wrapAround has been removed.");
        }
    },
    overdraw: {
        get: function() {
            console.warn("THREE.Material: .overdraw has been removed.");
        },
        set: function() {
            console.warn("THREE.Material: .overdraw has been removed.");
        }
    },
    wrapRGB: {
        get: function() {
            return console.warn("THREE.Material: .wrapRGB has been removed."), new ae;
        }
    },
    shading: {
        get: function() {
            console.error("THREE." + this.type + ": .shading has been removed. Use the boolean .flatShading instead.");
        },
        set: function(s) {
            console.warn("THREE." + this.type + ": .shading has been removed. Use the boolean .flatShading instead."), this.flatShading = s === kc;
        }
    },
    stencilMask: {
        get: function() {
            return console.warn("THREE." + this.type + ": .stencilMask has been removed. Use .stencilFuncMask instead."), this.stencilFuncMask;
        },
        set: function(s) {
            console.warn("THREE." + this.type + ": .stencilMask has been removed. Use .stencilFuncMask instead."), this.stencilFuncMask = s;
        }
    },
    vertexTangents: {
        get: function() {
            console.warn("THREE." + this.type + ": .vertexTangents has been removed.");
        },
        set: function() {
            console.warn("THREE." + this.type + ": .vertexTangents has been removed.");
        }
    }
});
Object.defineProperties(sn.prototype, {
    derivatives: {
        get: function() {
            return console.warn("THREE.ShaderMaterial: .derivatives has been moved to .extensions.derivatives."), this.extensions.derivatives;
        },
        set: function(s) {
            console.warn("THREE. ShaderMaterial: .derivatives has been moved to .extensions.derivatives."), this.extensions.derivatives = s;
        }
    }
});
qe.prototype.clearTarget = function(s, e, t, n) {
    console.warn("THREE.WebGLRenderer: .clearTarget() has been deprecated. Use .setRenderTarget() and .clear() instead."), this.setRenderTarget(s), this.clear(e, t, n);
};
qe.prototype.animate = function(s) {
    console.warn("THREE.WebGLRenderer: .animate() is now .setAnimationLoop()."), this.setAnimationLoop(s);
};
qe.prototype.getCurrentRenderTarget = function() {
    return console.warn("THREE.WebGLRenderer: .getCurrentRenderTarget() is now .getRenderTarget()."), this.getRenderTarget();
};
qe.prototype.getMaxAnisotropy = function() {
    return console.warn("THREE.WebGLRenderer: .getMaxAnisotropy() is now .capabilities.getMaxAnisotropy()."), this.capabilities.getMaxAnisotropy();
};
qe.prototype.getPrecision = function() {
    return console.warn("THREE.WebGLRenderer: .getPrecision() is now .capabilities.precision."), this.capabilities.precision;
};
qe.prototype.resetGLState = function() {
    return console.warn("THREE.WebGLRenderer: .resetGLState() is now .state.reset()."), this.state.reset();
};
qe.prototype.supportsFloatTextures = function() {
    return console.warn("THREE.WebGLRenderer: .supportsFloatTextures() is now .extensions.get( 'OES_texture_float' )."), this.extensions.get("OES_texture_float");
};
qe.prototype.supportsHalfFloatTextures = function() {
    return console.warn("THREE.WebGLRenderer: .supportsHalfFloatTextures() is now .extensions.get( 'OES_texture_half_float' )."), this.extensions.get("OES_texture_half_float");
};
qe.prototype.supportsStandardDerivatives = function() {
    return console.warn("THREE.WebGLRenderer: .supportsStandardDerivatives() is now .extensions.get( 'OES_standard_derivatives' )."), this.extensions.get("OES_standard_derivatives");
};
qe.prototype.supportsCompressedTextureS3TC = function() {
    return console.warn("THREE.WebGLRenderer: .supportsCompressedTextureS3TC() is now .extensions.get( 'WEBGL_compressed_texture_s3tc' )."), this.extensions.get("WEBGL_compressed_texture_s3tc");
};
qe.prototype.supportsCompressedTexturePVRTC = function() {
    return console.warn("THREE.WebGLRenderer: .supportsCompressedTexturePVRTC() is now .extensions.get( 'WEBGL_compressed_texture_pvrtc' )."), this.extensions.get("WEBGL_compressed_texture_pvrtc");
};
qe.prototype.supportsBlendMinMax = function() {
    return console.warn("THREE.WebGLRenderer: .supportsBlendMinMax() is now .extensions.get( 'EXT_blend_minmax' )."), this.extensions.get("EXT_blend_minmax");
};
qe.prototype.supportsVertexTextures = function() {
    return console.warn("THREE.WebGLRenderer: .supportsVertexTextures() is now .capabilities.vertexTextures."), this.capabilities.vertexTextures;
};
qe.prototype.supportsInstancedArrays = function() {
    return console.warn("THREE.WebGLRenderer: .supportsInstancedArrays() is now .extensions.get( 'ANGLE_instanced_arrays' )."), this.extensions.get("ANGLE_instanced_arrays");
};
qe.prototype.enableScissorTest = function(s) {
    console.warn("THREE.WebGLRenderer: .enableScissorTest() is now .setScissorTest()."), this.setScissorTest(s);
};
qe.prototype.initMaterial = function() {
    console.warn("THREE.WebGLRenderer: .initMaterial() has been removed.");
};
qe.prototype.addPrePlugin = function() {
    console.warn("THREE.WebGLRenderer: .addPrePlugin() has been removed.");
};
qe.prototype.addPostPlugin = function() {
    console.warn("THREE.WebGLRenderer: .addPostPlugin() has been removed.");
};
qe.prototype.updateShadowMap = function() {
    console.warn("THREE.WebGLRenderer: .updateShadowMap() has been removed.");
};
qe.prototype.setFaceCulling = function() {
    console.warn("THREE.WebGLRenderer: .setFaceCulling() has been removed.");
};
qe.prototype.allocTextureUnit = function() {
    console.warn("THREE.WebGLRenderer: .allocTextureUnit() has been removed.");
};
qe.prototype.setTexture = function() {
    console.warn("THREE.WebGLRenderer: .setTexture() has been removed.");
};
qe.prototype.setTexture2D = function() {
    console.warn("THREE.WebGLRenderer: .setTexture2D() has been removed.");
};
qe.prototype.setTextureCube = function() {
    console.warn("THREE.WebGLRenderer: .setTextureCube() has been removed.");
};
qe.prototype.getActiveMipMapLevel = function() {
    return console.warn("THREE.WebGLRenderer: .getActiveMipMapLevel() is now .getActiveMipmapLevel()."), this.getActiveMipmapLevel();
};
Object.defineProperties(qe.prototype, {
    shadowMapEnabled: {
        get: function() {
            return this.shadowMap.enabled;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderer: .shadowMapEnabled is now .shadowMap.enabled."), this.shadowMap.enabled = s;
        }
    },
    shadowMapType: {
        get: function() {
            return this.shadowMap.type;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderer: .shadowMapType is now .shadowMap.type."), this.shadowMap.type = s;
        }
    },
    shadowMapCullFace: {
        get: function() {
            console.warn("THREE.WebGLRenderer: .shadowMapCullFace has been removed. Set Material.shadowSide instead.");
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .shadowMapCullFace has been removed. Set Material.shadowSide instead.");
        }
    },
    context: {
        get: function() {
            return console.warn("THREE.WebGLRenderer: .context has been removed. Use .getContext() instead."), this.getContext();
        }
    },
    vr: {
        get: function() {
            return console.warn("THREE.WebGLRenderer: .vr has been renamed to .xr"), this.xr;
        }
    },
    gammaInput: {
        get: function() {
            return console.warn("THREE.WebGLRenderer: .gammaInput has been removed. Set the encoding for textures via Texture.encoding instead."), !1;
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .gammaInput has been removed. Set the encoding for textures via Texture.encoding instead.");
        }
    },
    gammaOutput: {
        get: function() {
            return console.warn("THREE.WebGLRenderer: .gammaOutput has been removed. Set WebGLRenderer.outputEncoding instead."), !1;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderer: .gammaOutput has been removed. Set WebGLRenderer.outputEncoding instead."), this.outputEncoding = s === !0 ? Oi : Nt;
        }
    },
    toneMappingWhitePoint: {
        get: function() {
            return console.warn("THREE.WebGLRenderer: .toneMappingWhitePoint has been removed."), 1;
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .toneMappingWhitePoint has been removed.");
        }
    },
    gammaFactor: {
        get: function() {
            return console.warn("THREE.WebGLRenderer: .gammaFactor has been removed."), 2;
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .gammaFactor has been removed.");
        }
    }
});
Object.defineProperties(yh.prototype, {
    cullFace: {
        get: function() {
            console.warn("THREE.WebGLRenderer: .shadowMap.cullFace has been removed. Set Material.shadowSide instead.");
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .shadowMap.cullFace has been removed. Set Material.shadowSide instead.");
        }
    },
    renderReverseSided: {
        get: function() {
            console.warn("THREE.WebGLRenderer: .shadowMap.renderReverseSided has been removed. Set Material.shadowSide instead.");
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .shadowMap.renderReverseSided has been removed. Set Material.shadowSide instead.");
        }
    },
    renderSingleSided: {
        get: function() {
            console.warn("THREE.WebGLRenderer: .shadowMap.renderSingleSided has been removed. Set Material.shadowSide instead.");
        },
        set: function() {
            console.warn("THREE.WebGLRenderer: .shadowMap.renderSingleSided has been removed. Set Material.shadowSide instead.");
        }
    }
});
function Q0(s, e, t) {
    return console.warn("THREE.WebGLRenderTargetCube( width, height, options ) is now WebGLCubeRenderTarget( size, options )."), new js(s, t);
}
Object.defineProperties(At.prototype, {
    wrapS: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .wrapS is now .texture.wrapS."), this.texture.wrapS;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .wrapS is now .texture.wrapS."), this.texture.wrapS = s;
        }
    },
    wrapT: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .wrapT is now .texture.wrapT."), this.texture.wrapT;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .wrapT is now .texture.wrapT."), this.texture.wrapT = s;
        }
    },
    magFilter: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .magFilter is now .texture.magFilter."), this.texture.magFilter;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .magFilter is now .texture.magFilter."), this.texture.magFilter = s;
        }
    },
    minFilter: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .minFilter is now .texture.minFilter."), this.texture.minFilter;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .minFilter is now .texture.minFilter."), this.texture.minFilter = s;
        }
    },
    anisotropy: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .anisotropy is now .texture.anisotropy."), this.texture.anisotropy;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .anisotropy is now .texture.anisotropy."), this.texture.anisotropy = s;
        }
    },
    offset: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .offset is now .texture.offset."), this.texture.offset;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .offset is now .texture.offset."), this.texture.offset = s;
        }
    },
    repeat: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .repeat is now .texture.repeat."), this.texture.repeat;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .repeat is now .texture.repeat."), this.texture.repeat = s;
        }
    },
    format: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .format is now .texture.format."), this.texture.format;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .format is now .texture.format."), this.texture.format = s;
        }
    },
    type: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .type is now .texture.type."), this.texture.type;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .type is now .texture.type."), this.texture.type = s;
        }
    },
    generateMipmaps: {
        get: function() {
            return console.warn("THREE.WebGLRenderTarget: .generateMipmaps is now .texture.generateMipmaps."), this.texture.generateMipmaps;
        },
        set: function(s) {
            console.warn("THREE.WebGLRenderTarget: .generateMipmaps is now .texture.generateMipmaps."), this.texture.generateMipmaps = s;
        }
    }
});
Za.prototype.load = function(s) {
    console.warn("THREE.Audio: .load has been deprecated. Use THREE.AudioLoader instead.");
    let e = this;
    return new kh().load(s, function(n) {
        e.setBuffer(n);
    }), this;
};
qh.prototype.getData = function() {
    return console.warn("THREE.AudioAnalyser: .getData() is now .getFrequencyData()."), this.getFrequencyData();
};
$s.prototype.updateCubeMap = function(s, e) {
    return console.warn("THREE.CubeCamera: .updateCubeMap() is now .update()."), this.update(s, e);
};
$s.prototype.clear = function(s, e, t, n) {
    return console.warn("THREE.CubeCamera: .clear() is now .renderTarget.clear()."), this.renderTarget.clear(s, e, t, n);
};
Yn.crossOrigin = void 0;
Yn.loadTexture = function(s, e, t, n) {
    console.warn("THREE.ImageUtils.loadTexture has been deprecated. Use THREE.TextureLoader() instead.");
    let i = new Bh;
    i.setCrossOrigin(this.crossOrigin);
    let r = i.load(s, t, void 0, n);
    return e && (r.mapping = e), r;
};
Yn.loadTextureCube = function(s, e, t, n) {
    console.warn("THREE.ImageUtils.loadTextureCube has been deprecated. Use THREE.CubeTextureLoader() instead.");
    let i = new Fh;
    i.setCrossOrigin(this.crossOrigin);
    let r = i.load(s, t, void 0, n);
    return e && (r.mapping = e), r;
};
Yn.loadCompressedTexture = function() {
    console.error("THREE.ImageUtils.loadCompressedTexture has been removed. Use THREE.DDSLoader instead.");
};
Yn.loadCompressedTextureCube = function() {
    console.error("THREE.ImageUtils.loadCompressedTextureCube has been removed. Use THREE.DDSLoader instead.");
};
function K0() {
    console.error("THREE.CanvasRenderer has been removed");
}
function ev() {
    console.error("THREE.JSONLoader has been removed.");
}
var tv = {
    createMultiMaterialObject: function() {
        console.error("THREE.SceneUtils has been moved to /examples/jsm/utils/SceneUtils.js");
    },
    detach: function() {
        console.error("THREE.SceneUtils has been moved to /examples/jsm/utils/SceneUtils.js");
    },
    attach: function() {
        console.error("THREE.SceneUtils has been moved to /examples/jsm/utils/SceneUtils.js");
    }
};
function nv() {
    console.error("THREE.LensFlare has been moved to /examples/jsm/objects/Lensflare.js");
}
function iv() {
    return console.error("THREE.ParametricGeometry has been moved to /examples/jsm/geometries/ParametricGeometry.js"), new _e;
}
function rv() {
    return console.error("THREE.TextGeometry has been moved to /examples/jsm/geometries/TextGeometry.js"), new _e;
}
function sv() {
    console.error("THREE.FontLoader has been moved to /examples/jsm/loaders/FontLoader.js");
}
function ov() {
    console.error("THREE.Font has been moved to /examples/jsm/loaders/FontLoader.js");
}
function av() {
    console.error("THREE.ImmediateRenderObject has been removed.");
}
typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register", {
    detail: {
        revision: ca
    }
}));
typeof window < "u" && (window.__THREE__ ? console.warn("WARNING: Multiple instances of Three.js being imported.") : window.__THREE__ = ca);
const mod = {
    ACESFilmicToneMapping: Uu,
    AddEquation: _i,
    AddOperation: Fu,
    AdditiveAnimationBlendMode: qc,
    AdditiveBlending: nl,
    AlphaFormat: Xu,
    AlwaysDepth: Au,
    AlwaysStencilFunc: Ud,
    AmbientLight: qa,
    AmbientLightProbe: Vh,
    AnimationClip: Lr,
    AnimationLoader: cy,
    AnimationMixer: $h,
    AnimationObjectGroup: Yh,
    AnimationUtils: Ze,
    ArcCurve: Ma,
    ArrayCamera: ga,
    ArrowHelper: Uy,
    Audio: Za,
    AudioAnalyser: qh,
    AudioContext: Hh,
    AudioListener: my,
    AudioLoader: kh,
    AxesHelper: ru,
    AxisHelper: X0,
    BackSide: it,
    BasicDepthPacking: Nd,
    BasicShadowMap: qy,
    BinaryTextureLoader: j0,
    Bone: oo,
    BooleanKeyframeTrack: Qn,
    BoundingBoxHelper: J0,
    Box2: qi,
    Box3: Lt,
    Box3Helper: By,
    BoxBufferGeometry: wn,
    BoxGeometry: wn,
    BoxHelper: iu,
    BufferAttribute: Ue,
    BufferGeometry: _e,
    BufferGeometryLoader: Uh,
    ByteType: Hu,
    Cache: Ni,
    Camera: Ir,
    CameraHelper: Ny,
    CanvasRenderer: K0,
    CanvasTexture: Th,
    CatmullRomCurve3: wa,
    CineonToneMapping: zu,
    CircleBufferGeometry: fr,
    CircleGeometry: fr,
    ClampToEdgeWrapping: vt,
    Clock: Wh,
    Color: ae,
    ColorKeyframeTrack: Ba,
    CompressedTexture: va,
    CompressedTextureLoader: hy,
    ConeBufferGeometry: pr,
    ConeGeometry: pr,
    CubeCamera: $s,
    CubeReflectionMapping: Bi,
    CubeRefractionMapping: zi,
    CubeTexture: ki,
    CubeTextureLoader: Fh,
    CubeUVReflectionMapping: Pr,
    CubeUVRefractionMapping: Ws,
    CubicBezierCurve: lo,
    CubicBezierCurve3: Sa,
    CubicInterpolant: Ph,
    CullFaceBack: tl,
    CullFaceFront: du,
    CullFaceFrontBack: Wy,
    CullFaceNone: uu,
    Curve: Ct,
    CurvePath: Ah,
    CustomBlending: pu,
    CustomToneMapping: Ou,
    CylinderBufferGeometry: Jn,
    CylinderGeometry: Jn,
    Cylindrical: Cy,
    DataTexture: qn,
    DataTexture2DArray: Qs,
    DataTexture3D: ma,
    DataTextureLoader: Nh,
    DataUtils: ky,
    DecrementStencilOp: n0,
    DecrementWrapStencilOp: r0,
    DefaultLoadingManager: ly,
    DepthFormat: Vn,
    DepthStencilFormat: Li,
    DepthTexture: ks,
    DirectionalLight: Wa,
    DirectionalLightHelper: Fy,
    DiscreteInterpolant: Ih,
    DodecahedronBufferGeometry: mr,
    DodecahedronGeometry: mr,
    DoubleSide: Ci,
    DstAlphaFactor: Mu,
    DstColorFactor: wu,
    DynamicBufferAttribute: B0,
    DynamicCopyUsage: y0,
    DynamicDrawUsage: ur,
    DynamicReadUsage: m0,
    EdgesGeometry: _a,
    EdgesHelper: Y0,
    EllipseCurve: Ur,
    EqualDepth: Lu,
    EqualStencilFunc: l0,
    EquirectangularReflectionMapping: Ds,
    EquirectangularRefractionMapping: Fs,
    Euler: Zn,
    EventDispatcher: En,
    ExtrudeBufferGeometry: ln,
    ExtrudeGeometry: ln,
    FaceColors: T0,
    FileLoader: Yt,
    FlatShading: kc,
    Float16BufferAttribute: nh,
    Float32Attribute: W0,
    Float32BufferAttribute: de,
    Float64Attribute: q0,
    Float64BufferAttribute: ih,
    FloatType: nn,
    Fog: Br,
    FogExp2: Nr,
    Font: ov,
    FontLoader: sv,
    FramebufferTexture: Sh,
    FrontSide: Ai,
    Frustum: Dr,
    GLBufferAttribute: Qh,
    GLSL1: _0,
    GLSL3: xl,
    GreaterDepth: Pu,
    GreaterEqualDepth: Ru,
    GreaterEqualStencilFunc: d0,
    GreaterStencilFunc: h0,
    GridHelper: nu,
    Group: Hn,
    HalfFloatType: kn,
    HemisphereLight: Ua,
    HemisphereLightHelper: Iy,
    HemisphereLightProbe: Gh,
    IcosahedronBufferGeometry: _r,
    IcosahedronGeometry: _r,
    ImageBitmapLoader: Oh,
    ImageLoader: Rr,
    ImageUtils: Yn,
    ImmediateRenderObject: av,
    IncrementStencilOp: t0,
    IncrementWrapStencilOp: i0,
    InstancedBufferAttribute: Xn,
    InstancedBufferGeometry: Ya,
    InstancedInterleavedBuffer: jh,
    InstancedMesh: xa,
    Int16Attribute: H0,
    Int16BufferAttribute: eh,
    Int32Attribute: G0,
    Int32BufferAttribute: th,
    Int8Attribute: z0,
    Int8BufferAttribute: jc,
    IntType: Gu,
    InterleavedBuffer: $n,
    InterleavedBufferAttribute: Sn,
    Interpolant: cn,
    InterpolateDiscrete: zs,
    InterpolateLinear: Us,
    InterpolateSmooth: yo,
    InvertStencilOp: s0,
    JSONLoader: ev,
    KeepStencilOp: vo,
    KeyframeTrack: zt,
    LOD: bh,
    LatheBufferGeometry: Mr,
    LatheGeometry: Mr,
    Layers: Js,
    LensFlare: nv,
    LessDepth: Cu,
    LessEqualDepth: ea,
    LessEqualStencilFunc: c0,
    LessStencilFunc: a0,
    Light: Bt,
    LightProbe: Hr,
    Line: on,
    Line3: Kh,
    LineBasicMaterial: ft,
    LineCurve: Or,
    LineCurve3: Eh,
    LineDashedMaterial: Fa,
    LineLoop: ya,
    LinePieces: w0,
    LineSegments: wt,
    LineStrip: b0,
    LinearEncoding: Nt,
    LinearFilter: tt,
    LinearInterpolant: Na,
    LinearMipMapLinearFilter: $y,
    LinearMipMapNearestFilter: Zy,
    LinearMipmapLinearFilter: Ui,
    LinearMipmapNearestFilter: Wc,
    LinearToneMapping: Nu,
    Loader: bt,
    LoaderUtils: Gs,
    LoadingManager: za,
    LoopOnce: Pd,
    LoopPingPong: Dd,
    LoopRepeat: Id,
    LuminanceAlphaFormat: Yu,
    LuminanceFormat: Ju,
    MOUSE: Gy,
    Material: dt,
    MaterialLoader: zh,
    Math: M0,
    MathUtils: M0,
    Matrix3: lt,
    Matrix4: pe,
    MaxEquation: ol,
    Mesh: st,
    MeshBasicMaterial: hn,
    MeshDepthMaterial: eo,
    MeshDistanceMaterial: to,
    MeshFaceMaterial: A0,
    MeshLambertMaterial: Ia,
    MeshMatcapMaterial: Da,
    MeshNormalMaterial: Pa,
    MeshPhongMaterial: La,
    MeshPhysicalMaterial: Ca,
    MeshStandardMaterial: po,
    MeshToonMaterial: Ra,
    MinEquation: sl,
    MirroredRepeatWrapping: Bs,
    MixOperation: Du,
    MultiMaterial: C0,
    MultiplyBlending: rl,
    MultiplyOperation: Vs,
    NearestFilter: rt,
    NearestMipMapLinearFilter: Yy,
    NearestMipMapNearestFilter: Jy,
    NearestMipmapLinearFilter: na,
    NearestMipmapNearestFilter: ta,
    NeverDepth: Eu,
    NeverStencilFunc: o0,
    NoBlending: vn,
    NoColors: S0,
    NoToneMapping: _n,
    NormalAnimationBlendMode: ua,
    NormalBlending: sr,
    NotEqualDepth: Iu,
    NotEqualStencilFunc: u0,
    NumberKeyframeTrack: Ar,
    Object3D: Ne,
    ObjectLoader: uy,
    ObjectSpaceNormalMap: zd,
    OctahedronBufferGeometry: Ii,
    OctahedronGeometry: Ii,
    OneFactor: yu,
    OneMinusDstAlphaFactor: bu,
    OneMinusDstColorFactor: Su,
    OneMinusSrcAlphaFactor: Vc,
    OneMinusSrcColorFactor: _u,
    OrthographicCamera: Fr,
    PCFShadowMap: Hc,
    PCFSoftShadowMap: fu,
    PMREMGenerator: ah,
    ParametricGeometry: iv,
    Particle: R0,
    ParticleBasicMaterial: D0,
    ParticleSystem: P0,
    ParticleSystemMaterial: F0,
    Path: gr,
    PerspectiveCamera: ut,
    Plane: Wt,
    PlaneBufferGeometry: Pi,
    PlaneGeometry: Pi,
    PlaneHelper: zy,
    PointCloud: L0,
    PointCloudMaterial: I0,
    PointLight: Ga,
    PointLightHelper: Ry,
    Points: zr,
    PointsMaterial: jn,
    PolarGridHelper: Dy,
    PolyhedronBufferGeometry: an,
    PolyhedronGeometry: an,
    PositionalAudio: xy,
    PropertyBinding: ke,
    PropertyMixer: Xh,
    QuadraticBezierCurve: co,
    QuadraticBezierCurve3: ho,
    Quaternion: gt,
    QuaternionKeyframeTrack: Wi,
    QuaternionLinearInterpolant: Dh,
    REVISION: ca,
    RGBADepthPacking: Bd,
    RGBAFormat: ct,
    RGBAIntegerFormat: ed,
    RGBA_ASTC_10x10_Format: fd,
    RGBA_ASTC_10x5_Format: hd,
    RGBA_ASTC_10x6_Format: ud,
    RGBA_ASTC_10x8_Format: dd,
    RGBA_ASTC_12x10_Format: pd,
    RGBA_ASTC_12x12_Format: md,
    RGBA_ASTC_4x4_Format: nd,
    RGBA_ASTC_5x4_Format: id,
    RGBA_ASTC_5x5_Format: rd,
    RGBA_ASTC_6x5_Format: sd,
    RGBA_ASTC_6x6_Format: od,
    RGBA_ASTC_8x5_Format: ad,
    RGBA_ASTC_8x6_Format: ld,
    RGBA_ASTC_8x8_Format: cd,
    RGBA_BPTC_Format: gd,
    RGBA_ETC2_EAC_Format: gl,
    RGBA_PVRTC_2BPPV1_Format: pl,
    RGBA_PVRTC_4BPPV1_Format: fl,
    RGBA_S3TC_DXT1_Format: ll,
    RGBA_S3TC_DXT3_Format: cl,
    RGBA_S3TC_DXT5_Format: hl,
    RGBFormat: Gn,
    RGBIntegerFormat: Ku,
    RGB_ETC1_Format: td,
    RGB_ETC2_Format: ml,
    RGB_PVRTC_2BPPV1_Format: dl,
    RGB_PVRTC_4BPPV1_Format: ul,
    RGB_S3TC_DXT1_Format: al,
    RGFormat: ju,
    RGIntegerFormat: Qu,
    RawShaderMaterial: Gi,
    Ray: Cn,
    Raycaster: Ey,
    RectAreaLight: Xa,
    RedFormat: Zu,
    RedIntegerFormat: $u,
    ReinhardToneMapping: Bu,
    RepeatWrapping: Ns,
    ReplaceStencilOp: e0,
    ReverseSubtractEquation: gu,
    RingBufferGeometry: br,
    RingGeometry: br,
    SRGB8_ALPHA8_ASTC_10x10_Format: Cd,
    SRGB8_ALPHA8_ASTC_10x5_Format: Td,
    SRGB8_ALPHA8_ASTC_10x6_Format: Ed,
    SRGB8_ALPHA8_ASTC_10x8_Format: Ad,
    SRGB8_ALPHA8_ASTC_12x10_Format: Ld,
    SRGB8_ALPHA8_ASTC_12x12_Format: Rd,
    SRGB8_ALPHA8_ASTC_4x4_Format: xd,
    SRGB8_ALPHA8_ASTC_5x4_Format: yd,
    SRGB8_ALPHA8_ASTC_5x5_Format: vd,
    SRGB8_ALPHA8_ASTC_6x5_Format: _d,
    SRGB8_ALPHA8_ASTC_6x6_Format: Md,
    SRGB8_ALPHA8_ASTC_8x5_Format: bd,
    SRGB8_ALPHA8_ASTC_8x6_Format: wd,
    SRGB8_ALPHA8_ASTC_8x8_Format: Sd,
    Scene: no,
    SceneUtils: tv,
    ShaderChunk: Fe,
    ShaderLib: qt,
    ShaderMaterial: sn,
    ShadowMaterial: Aa,
    Shape: Xt,
    ShapeBufferGeometry: Di,
    ShapeGeometry: Di,
    ShapePath: Oy,
    ShapeUtils: Jt,
    ShortType: ku,
    Skeleton: ao,
    SkeletonHelper: eu,
    SkinnedMesh: so,
    SmoothShading: Xy,
    Sphere: An,
    SphereBufferGeometry: Fi,
    SphereGeometry: Fi,
    Spherical: Ay,
    SphericalHarmonics3: Ja,
    SplineCurve: uo,
    SpotLight: Ha,
    SpotLightHelper: Ly,
    Sprite: ro,
    SpriteMaterial: io,
    SrcAlphaFactor: Gc,
    SrcAlphaSaturateFactor: Tu,
    SrcColorFactor: vu,
    StaticCopyUsage: x0,
    StaticDrawUsage: hr,
    StaticReadUsage: p0,
    StereoCamera: fy,
    StreamCopyUsage: v0,
    StreamDrawUsage: f0,
    StreamReadUsage: g0,
    StringKeyframeTrack: Kn,
    SubtractEquation: mu,
    SubtractiveBlending: il,
    TOUCH: Vy,
    TangentSpaceNormalMap: Hi,
    TetrahedronBufferGeometry: wr,
    TetrahedronGeometry: wr,
    TextGeometry: rv,
    Texture: ot,
    TextureLoader: Bh,
    TorusBufferGeometry: Sr,
    TorusGeometry: Sr,
    TorusKnotBufferGeometry: Tr,
    TorusKnotGeometry: Tr,
    Triangle: nt,
    TriangleFanDrawMode: Qy,
    TriangleStripDrawMode: jy,
    TrianglesDrawMode: Fd,
    TubeBufferGeometry: Er,
    TubeGeometry: Er,
    UVMapping: ha,
    Uint16Attribute: k0,
    Uint16BufferAttribute: Ys,
    Uint32Attribute: V0,
    Uint32BufferAttribute: Zs,
    Uint8Attribute: U0,
    Uint8BufferAttribute: Qc,
    Uint8ClampedAttribute: O0,
    Uint8ClampedBufferAttribute: Kc,
    Uniform: go,
    UniformsLib: ie,
    UniformsUtils: uf,
    UnsignedByteType: rn,
    UnsignedInt248Type: Ti,
    UnsignedIntType: Ps,
    UnsignedShort4444Type: Vu,
    UnsignedShort5551Type: Wu,
    UnsignedShort565Type: qu,
    UnsignedShortType: cr,
    VSMShadowMap: ir,
    Vector2: X,
    Vector3: M,
    Vector4: Ve,
    VectorKeyframeTrack: Cr,
    Vertex: N0,
    VertexColors: E0,
    VideoTexture: wh,
    WebGL1Renderer: _h,
    WebGLCubeRenderTarget: js,
    WebGLMultipleRenderTargets: Zc,
    WebGLMultisampleRenderTarget: Xs,
    WebGLRenderTarget: At,
    WebGLRenderTargetCube: Q0,
    WebGLRenderer: qe,
    WebGLUtils: Ex,
    WireframeGeometry: Ea,
    WireframeHelper: Z0,
    WrapAroundEnding: Os,
    XHRLoader: $0,
    ZeroCurvatureEnding: Mi,
    ZeroFactor: xu,
    ZeroSlopeEnding: bi,
    ZeroStencilOp: Ky,
    sRGBEncoding: Oi
};
function getWebGLErrorMessage() {
    return getErrorMessage(1);
}
function getErrorMessage(version) {
    var names = {
        1: "WebGL",
        2: "WebGL 2"
    };
    var contexts = {
        1: window.WebGLRenderingContext,
        2: window.WebGL2RenderingContext
    };
    var message = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';
    var element = document.createElement("div");
    element.id = "webglmessage";
    element.style.fontFamily = "monospace";
    element.style.fontSize = "13px";
    element.style.fontWeight = "normal";
    element.style.textAlign = "center";
    element.style.background = "#fff";
    element.style.color = "#000";
    element.style.padding = "1.5em";
    element.style.width = "400px";
    element.style.margin = "5em auto 0";
    if (contexts[version]) {
        message = message.replace("$0", "graphics card");
    } else {
        message = message.replace("$0", "browser");
    }
    message = message.replace("$1", names[version]);
    element.innerHTML = message;
    return element;
}
const pixelRatio = window.devicePixelRatio || 1.0;
function event2scene_pixel(scene, event) {
    const { canvas  } = scene.screen;
    const rect = canvas.getBoundingClientRect();
    const x = (event.clientX - rect.left) * pixelRatio;
    const y = (rect.height - (event.clientY - rect.top)) * pixelRatio;
    return [
        x,
        y
    ];
}
function Identity4x4() {
    return new pe();
}
function in_scene(scene, mouse_event) {
    const [x, y] = event2scene_pixel(scene, mouse_event);
    const [sx, sy, sw, sh] = scene.pixelarea.value;
    return x >= sx && x < sx + sw && y >= sy && y < sy + sh;
}
function attach_3d_camera(canvas, makie_camera, cam3d, scene) {
    if (cam3d === undefined) {
        return;
    }
    const [w, h] = makie_camera.resolution.value;
    const camera = new ut(cam3d.fov, w / h, cam3d.near, cam3d.far);
    const center = new M(...cam3d.lookat);
    camera.up = new M(...cam3d.upvector);
    camera.position.set(...cam3d.eyeposition);
    camera.lookAt(center);
    function update() {
        camera.updateProjectionMatrix();
        camera.updateWorldMatrix();
        const view = camera.matrixWorldInverse;
        const projection = camera.projectionMatrix;
        const [width, height] = makie_camera.resolution.value;
        const [x, y, z] = camera.position;
        makie_camera.update_matrices(view.elements, projection.elements, [
            width,
            height
        ], [
            x,
            y,
            z
        ]);
    }
    function addMouseHandler(domObject, drag, zoomIn, zoomOut) {
        let startDragX = null;
        let startDragY = null;
        function mouseWheelHandler(e) {
            e = window.event || e;
            if (!in_scene(scene, e)) {
                return;
            }
            const delta = Math.sign(e.deltaY);
            if (delta == -1) {
                zoomOut();
            } else if (delta == 1) {
                zoomIn();
            }
            e.preventDefault();
        }
        function mouseDownHandler(e) {
            if (!in_scene(scene, e)) {
                return;
            }
            startDragX = e.clientX;
            startDragY = e.clientY;
            e.preventDefault();
        }
        function mouseMoveHandler(e) {
            if (!in_scene(scene, e)) {
                return;
            }
            if (startDragX === null || startDragY === null) return;
            if (drag) drag(e.clientX - startDragX, e.clientY - startDragY);
            startDragX = e.clientX;
            startDragY = e.clientY;
            e.preventDefault();
        }
        function mouseUpHandler(e) {
            if (!in_scene(scene, e)) {
                return;
            }
            mouseMoveHandler.call(this, e);
            startDragX = null;
            startDragY = null;
            e.preventDefault();
        }
        domObject.addEventListener("wheel", mouseWheelHandler);
        domObject.addEventListener("mousedown", mouseDownHandler);
        domObject.addEventListener("mousemove", mouseMoveHandler);
        domObject.addEventListener("mouseup", mouseUpHandler);
    }
    function drag(deltaX, deltaY) {
        const radPerPixel = Math.PI / 450;
        const deltaPhi = radPerPixel * deltaX;
        const deltaTheta = radPerPixel * deltaY;
        const pos = camera.position.sub(center);
        const radius = pos.length();
        let theta = Math.acos(pos.z / radius);
        let phi = Math.atan2(pos.y, pos.x);
        theta = Math.min(Math.max(theta - deltaTheta, 0), Math.PI);
        phi -= deltaPhi;
        pos.x = radius * Math.sin(theta) * Math.cos(phi);
        pos.y = radius * Math.sin(theta) * Math.sin(phi);
        pos.z = radius * Math.cos(theta);
        camera.position.add(center);
        camera.lookAt(center);
        update();
    }
    function zoomIn() {
        camera.position.sub(center).multiplyScalar(0.9).add(center);
        update();
    }
    function zoomOut() {
        camera.position.sub(center).multiplyScalar(1.1).add(center);
        update();
    }
    addMouseHandler(canvas, drag, zoomIn, zoomOut);
}
function mul(a, b) {
    return b.clone().multiply(a);
}
function orthographicprojection(left, right, bottom, top, znear, zfar) {
    return [
        2 / (right - left),
        0,
        0,
        0,
        0,
        2 / (top - bottom),
        0,
        0,
        0,
        0,
        -2 / (zfar - znear),
        0,
        -(right + left) / (right - left),
        -(top + bottom) / (top - bottom),
        -(zfar + znear) / (zfar - znear),
        1
    ];
}
function pixel_space_inverse(w, h, near) {
    return [
        0.5 * w,
        0,
        0,
        0,
        0,
        0.5 * h,
        0,
        0,
        0,
        0,
        near,
        0,
        0.5 * w,
        0.5 * h,
        0,
        1
    ];
}
function relative_space() {
    const relative = Identity4x4();
    relative.fromArray([
        2,
        0,
        0,
        0,
        0,
        2,
        0,
        0,
        0,
        0,
        1,
        0,
        -1,
        -1,
        0,
        1
    ]);
    return relative;
}
class MakieCamera {
    constructor(){
        this.view = new go(Identity4x4());
        this.projection = new go(Identity4x4());
        this.projectionview = new go(Identity4x4());
        this.pixel_space = new go(Identity4x4());
        this.pixel_space_inverse = new go(Identity4x4());
        this.projectionview_inverse = new go(Identity4x4());
        this.relative_space = new go(relative_space());
        this.relative_inverse = new go(relative_space().invert());
        this.clip_space = new go(Identity4x4());
        this.resolution = new go(new X());
        this.eyeposition = new go(new M());
        this.preprojections = {};
    }
    calculate_matrices() {
        const [w, h] = this.resolution.value;
        const nearclip = -10_000;
        this.pixel_space.value.fromArray(orthographicprojection(0, w, 0, h, nearclip, 10_000));
        this.pixel_space_inverse.value.fromArray(pixel_space_inverse(w, h, nearclip));
        const proj_view = mul(this.view.value, this.projection.value);
        this.projectionview.value = proj_view;
        this.projectionview_inverse.value = proj_view.clone().invert();
        Object.keys(this.preprojections).forEach((key)=>{
            const [space, markerspace] = key.split(",");
            this.preprojections[key].value = this.calculate_preprojection_matrix(space, markerspace);
        });
    }
    update_matrices(view, projection, resolution, eyepos) {
        this.view.value.fromArray(view);
        this.projection.value.fromArray(projection);
        this.resolution.value.fromArray(resolution);
        this.eyeposition.value.fromArray(eyepos);
        this.calculate_matrices();
        return;
    }
    clip_to_space(space) {
        if (space === "data") {
            return this.projectionview_inverse.value;
        } else if (space === "pixel") {
            return this.pixel_space_inverse.value;
        } else if (space === "relative") {
            return this.relative_inverse.value;
        } else if (space === "clip") {
            return this.clip_space.value;
        } else {
            throw new Error(`Space ${space} not recognized`);
        }
    }
    space_to_clip(space) {
        if (space === "data") {
            return this.projectionview.value;
        } else if (space === "pixel") {
            return this.pixel_space.value;
        } else if (space === "relative") {
            return this.relative_space.value;
        } else if (space === "clip") {
            return this.clip_space.value;
        } else {
            throw new Error(`Space ${space} not recognized`);
        }
    }
    calculate_preprojection_matrix(space, markerspace) {
        const cp = this.clip_to_space(markerspace);
        const sc = this.space_to_clip(space);
        return mul(sc, cp);
    }
    preprojection_matrix(space, markerspace) {
        const key = [
            space,
            markerspace
        ];
        const matrix_uniform = this.preprojections[key];
        if (matrix_uniform) {
            return matrix_uniform;
        } else {
            const matrix = this.calculate_preprojection_matrix(space, markerspace);
            const uniform = new go(matrix);
            this.preprojections[key] = uniform;
            return uniform;
        }
    }
}
const scene_cache = {};
const plot_cache = {};
const TEXTURE_ATLAS = [
    undefined
];
function add_scene(scene_id, three_scene) {
    scene_cache[scene_id] = three_scene;
}
function find_scene(scene_id) {
    return scene_cache[scene_id];
}
function delete_scene(scene_id) {
    const scene = scene_cache[scene_id];
    if (!scene) {
        return;
    }
    while(scene.children.length > 0){
        scene.remove(scene.children[0]);
    }
    delete scene_cache[scene_id];
}
function find_plots(plot_uuids) {
    const plots = [];
    plot_uuids.forEach((id)=>{
        const plot = plot_cache[id];
        if (plot) {
            plots.push(plot);
        }
    });
    return plots;
}
function delete_scenes(scene_uuids, plot_uuids) {
    plot_uuids.forEach((plot_id)=>{
        delete plot_cache[plot_id];
    });
    scene_uuids.forEach((scene_id)=>{
        delete_scene(scene_id);
    });
}
function insert_plot(scene_id, plot_data) {
    const scene = find_scene(scene_id);
    plot_data.forEach((plot)=>{
        add_plot(scene, plot);
    });
}
function delete_plots(scene_id, plot_uuids) {
    const scene = find_scene(scene_id);
    const plots = find_plots(plot_uuids);
    plots.forEach((p)=>{
        scene.remove(p);
        delete plot_cache[p];
    });
}
function convert_texture(data) {
    const tex = create_texture(data);
    tex.needsUpdate = true;
    tex.minFilter = mod[data.minFilter];
    tex.magFilter = mod[data.magFilter];
    tex.anisotropy = data.anisotropy;
    tex.wrapS = mod[data.wrapS];
    if (data.size.length > 1) {
        tex.wrapT = mod[data.wrapT];
    }
    if (data.size.length > 2) {
        tex.wrapR = mod[data.wrapR];
    }
    return tex;
}
function is_three_fixed_array(value) {
    return value instanceof mod.Vector2 || value instanceof mod.Vector3 || value instanceof mod.Vector4 || value instanceof mod.Matrix4;
}
function to_uniform(data) {
    if (data.type !== undefined) {
        if (data.type == "Sampler") {
            return convert_texture(data);
        }
        throw new Error(`Type ${data.type} not known`);
    }
    if (Array.isArray(data) || ArrayBuffer.isView(data)) {
        if (!data.every((x)=>typeof x === "number")) {
            return data;
        }
        if (data.length == 2) {
            return new mod.Vector2().fromArray(data);
        }
        if (data.length == 3) {
            return new mod.Vector3().fromArray(data);
        }
        if (data.length == 4) {
            return new mod.Vector4().fromArray(data);
        }
        if (data.length == 16) {
            const mat = new mod.Matrix4();
            mat.fromArray(data);
            return mat;
        }
    }
    return data;
}
function deserialize_uniforms(data) {
    const result = {};
    for(const name in data){
        const value = data[name];
        if (value instanceof mod.Uniform) {
            result[name] = value;
        } else {
            const ser = to_uniform(value);
            result[name] = new mod.Uniform(ser);
        }
    }
    return result;
}
function deserialize_plot(data) {
    let mesh;
    if ("instance_attributes" in data) {
        mesh = create_instanced_mesh(data);
    } else {
        mesh = create_mesh(data);
    }
    mesh.name = data.name;
    mesh.frustumCulled = false;
    mesh.matrixAutoUpdate = false;
    mesh.plot_uuid = data.uuid;
    const update_visible = (v)=>{
        mesh.visible = v;
        return;
    };
    update_visible(data.visible.value);
    data.visible.on(update_visible);
    connect_uniforms(mesh, data.uniform_updater);
    connect_attributes(mesh, data.attribute_updater);
    return mesh;
}
const ON_NEXT_INSERT = new Set();
function on_next_insert(f) {
    ON_NEXT_INSERT.add(f);
}
function add_plot(scene, plot_data) {
    const cam = scene.wgl_camera;
    const identity = new mod.Uniform(new mod.Matrix4());
    if (plot_data.cam_space == "data") {
        plot_data.uniforms.view = cam.view;
        plot_data.uniforms.projection = cam.projection;
        plot_data.uniforms.projectionview = cam.projectionview;
        plot_data.uniforms.eyeposition = cam.eyeposition;
    } else if (plot_data.cam_space == "pixel") {
        plot_data.uniforms.view = identity;
        plot_data.uniforms.projection = cam.pixel_space;
        plot_data.uniforms.projectionview = cam.pixel_space;
    } else if (plot_data.cam_space == "relative") {
        plot_data.uniforms.view = identity;
        plot_data.uniforms.projection = cam.relative_space;
        plot_data.uniforms.projectionview = cam.relative_space;
    } else {
        plot_data.uniforms.view = identity;
        plot_data.uniforms.projection = identity;
        plot_data.uniforms.projectionview = identity;
    }
    plot_data.uniforms.resolution = cam.resolution;
    if (plot_data.uniforms.preprojection) {
        const { space , markerspace  } = plot_data;
        plot_data.uniforms.preprojection = cam.preprojection_matrix(space.value, markerspace.value);
    }
    const p = deserialize_plot(plot_data);
    plot_cache[plot_data.uuid] = p;
    scene.add(p);
    const next_insert = new Set(ON_NEXT_INSERT);
    next_insert.forEach((f)=>f());
}
function connect_uniforms(mesh, updater) {
    updater.on(([name, data])=>{
        if (name === "none") {
            return;
        }
        const uniform = mesh.material.uniforms[name];
        if (uniform.value.isTexture) {
            const im_data = uniform.value.image;
            const [size, tex_data] = data;
            if (tex_data.length == im_data.data.length) {
                im_data.data.set(tex_data);
            } else {
                const old_texture = uniform.value;
                uniform.value = re_create_texture(old_texture, tex_data, size);
                old_texture.dispose();
            }
            uniform.value.needsUpdate = true;
        } else {
            if (is_three_fixed_array(uniform.value)) {
                uniform.value.fromArray(data);
            } else {
                uniform.value = data;
            }
        }
    });
}
function create_texture(data) {
    const buffer = data.data;
    if (data.size.length == 3) {
        const tex = new mod.DataTexture3D(buffer, data.size[0], data.size[1], data.size[2]);
        tex.format = mod[data.three_format];
        tex.type = mod[data.three_type];
        return tex;
    } else {
        const tex_data = buffer == "texture_atlas" ? TEXTURE_ATLAS[0].value : buffer;
        return new mod.DataTexture(tex_data, data.size[0], data.size[1], mod[data.three_format], mod[data.three_type]);
    }
}
function re_create_texture(old_texture, buffer, size) {
    if (size.length == 3) {
        const tex = new mod.DataTexture3D(buffer, size[0], size[1], size[2]);
        tex.format = old_texture.format;
        tex.type = old_texture.type;
        return tex;
    } else {
        return new mod.DataTexture(buffer, size[0], size[1] ? size[1] : 1, old_texture.format, old_texture.type);
    }
}
function BufferAttribute(buffer) {
    const jsbuff = new mod.BufferAttribute(buffer.flat, buffer.type_length);
    jsbuff.setUsage(mod.DynamicDrawUsage);
    return jsbuff;
}
function InstanceBufferAttribute(buffer) {
    const jsbuff = new mod.InstancedBufferAttribute(buffer.flat, buffer.type_length);
    jsbuff.setUsage(mod.DynamicDrawUsage);
    return jsbuff;
}
function attach_geometry(buffer_geometry, vertexarrays, faces) {
    for(const name in vertexarrays){
        const buff = vertexarrays[name];
        let buffer;
        if (buff.to_update) {
            buffer = new mod.BufferAttribute(buff.to_update, buff.itemSize);
        } else {
            buffer = BufferAttribute(buff);
        }
        buffer_geometry.setAttribute(name, buffer);
    }
    buffer_geometry.setIndex(faces);
    buffer_geometry.boundingSphere = new mod.Sphere();
    buffer_geometry.boundingSphere.radius = 10000000000000;
    buffer_geometry.frustumCulled = false;
    return buffer_geometry;
}
function attach_instanced_geometry(buffer_geometry, instance_attributes) {
    for(const name in instance_attributes){
        const buffer = InstanceBufferAttribute(instance_attributes[name]);
        buffer_geometry.setAttribute(name, buffer);
    }
}
function recreate_geometry(mesh, vertexarrays, faces) {
    const buffer_geometry = new mod.BufferGeometry();
    attach_geometry(buffer_geometry, vertexarrays, faces);
    mesh.geometry.dispose();
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
}
function recreate_instanced_geometry(mesh) {
    const buffer_geometry = new mod.InstancedBufferGeometry();
    const vertexarrays = {};
    const instance_attributes = {};
    const faces = [
        ...mesh.geometry.index.array
    ];
    Object.keys(mesh.geometry.attributes).forEach((name)=>{
        const buffer = mesh.geometry.attributes[name];
        const copy = buffer.to_update ? buffer.to_update : buffer.array.map((x)=>x);
        if (buffer.isInstancedBufferAttribute) {
            instance_attributes[name] = {
                flat: copy,
                type_length: buffer.itemSize
            };
        } else {
            vertexarrays[name] = {
                flat: copy,
                type_length: buffer.itemSize
            };
        }
    });
    attach_geometry(buffer_geometry, vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, instance_attributes);
    mesh.geometry.dispose();
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
}
function create_material(program) {
    const is_volume = "volumedata" in program.uniforms;
    return new mod.RawShaderMaterial({
        uniforms: deserialize_uniforms(program.uniforms),
        vertexShader: program.vertex_source,
        fragmentShader: program.fragment_source,
        side: is_volume ? mod.BackSide : mod.DoubleSide,
        transparent: true,
        depthTest: !program.overdraw.value,
        depthWrite: !program.transparency.value
    });
}
function create_mesh(program) {
    const buffer_geometry = new mod.BufferGeometry();
    const faces = new mod.BufferAttribute(program.faces.value, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    const material = create_material(program);
    const mesh = new mod.Mesh(buffer_geometry, material);
    program.faces.on((x)=>{
        mesh.geometry.setIndex(new mod.BufferAttribute(x, 1));
    });
    return mesh;
}
function create_instanced_mesh(program) {
    const buffer_geometry = new mod.InstancedBufferGeometry();
    const faces = new mod.BufferAttribute(program.faces.value, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, program.instance_attributes);
    const material = create_material(program);
    const mesh = new mod.Mesh(buffer_geometry, material);
    program.faces.on((x)=>{
        mesh.geometry.setIndex(new mod.BufferAttribute(x, 1));
    });
    return mesh;
}
function first(x) {
    return x[Object.keys(x)[0]];
}
function connect_attributes(mesh, updater) {
    const instance_buffers = {};
    const geometry_buffers = {};
    let first_instance_buffer;
    const real_instance_length = [
        0
    ];
    let first_geometry_buffer;
    const real_geometry_length = [
        0
    ];
    function re_assign_buffers() {
        const attributes = mesh.geometry.attributes;
        Object.keys(attributes).forEach((name)=>{
            const buffer = attributes[name];
            if (buffer.isInstancedBufferAttribute) {
                instance_buffers[name] = buffer;
            } else {
                geometry_buffers[name] = buffer;
            }
        });
        first_instance_buffer = first(instance_buffers);
        if (first_instance_buffer) {
            real_instance_length[0] = first_instance_buffer.count;
        }
        first_geometry_buffer = first(geometry_buffers);
        real_geometry_length[0] = first_geometry_buffer.count;
    }
    re_assign_buffers();
    updater.on(([name, new_values, length])=>{
        const buffer = mesh.geometry.attributes[name];
        let buffers;
        let real_length;
        let is_instance = false;
        if (name in instance_buffers) {
            buffers = instance_buffers;
            first_instance_buffer;
            real_length = real_instance_length;
            is_instance = true;
        } else {
            buffers = geometry_buffers;
            first_geometry_buffer;
            real_length = real_geometry_length;
        }
        if (length <= real_length[0]) {
            buffer.set(new_values);
            buffer.needsUpdate = true;
            if (is_instance) {
                mesh.geometry.instanceCount = length;
            }
        } else {
            buffer.to_update = new_values;
            const all_have_same_length = Object.values(buffers).every((x)=>x.to_update && x.to_update.length / x.itemSize == length);
            if (all_have_same_length) {
                if (is_instance) {
                    recreate_instanced_geometry(mesh);
                    re_assign_buffers();
                    mesh.geometry.instanceCount = new_values.length / buffer.itemSize;
                } else {
                    recreate_geometry(mesh, buffers, mesh.geometry.index);
                    re_assign_buffers();
                }
            }
        }
    });
}
function deserialize_scene(data, screen) {
    const scene = new mod.Scene();
    scene.screen = screen;
    const { canvas  } = screen;
    add_scene(data.uuid, scene);
    scene.scene_uuid = data.uuid;
    scene.frustumCulled = false;
    scene.pixelarea = data.pixelarea;
    scene.backgroundcolor = data.backgroundcolor;
    scene.clearscene = data.clearscene;
    scene.visible = data.visible;
    const camera = new MakieCamera();
    scene.wgl_camera = camera;
    function update_cam(camera_matrices) {
        const [view, projection, resolution, eyepos] = camera_matrices;
        camera.update_matrices(view, projection, resolution, eyepos);
    }
    update_cam(data.camera.value);
    if (data.cam3d_state) {
        attach_3d_camera(canvas, camera, data.cam3d_state, scene);
    } else {
        data.camera.on(update_cam);
    }
    data.plots.forEach((plot_data)=>{
        add_plot(scene, plot_data);
    });
    scene.scene_children = data.children.map((child)=>deserialize_scene(child, screen));
    return scene;
}
function delete_plot(plot) {
    delete plot_cache[plot.plot_uuid];
    const { parent  } = plot;
    if (parent) {
        parent.remove(plot);
    }
    plot.geometry.dispose();
    plot.material.dispose();
}
function delete_three_scene(scene) {
    delete scene_cache[scene.scene_uuid];
    scene.scene_children.forEach(delete_three_scene);
    while(scene.children.length > 0){
        delete_plot(scene.children[0]);
    }
}
window.THREE = mod;
const pixelRatio1 = window.devicePixelRatio || 1.0;
function render_scene(scene, picking = false) {
    const { camera , renderer  } = scene.screen;
    const canvas = renderer.domElement;
    if (!document.body.contains(canvas)) {
        console.log("EXITING WGL");
        renderer.state.reset();
        renderer.dispose();
        delete_three_scene(scene);
        return false;
    }
    if (!scene.visible.value) {
        return true;
    }
    renderer.autoClear = scene.clearscene;
    const area = scene.pixelarea.value;
    if (area) {
        const [x, y, w, h] = area.map((t)=>t / pixelRatio1);
        renderer.setViewport(x, y, w, h);
        renderer.setScissor(x, y, w, h);
        renderer.setScissorTest(true);
        if (picking) {
            renderer.setClearAlpha(0);
            renderer.setClearColor(new mod.Color(0), 0.0);
        } else {
            renderer.setClearColor(scene.backgroundcolor.value);
        }
        renderer.render(scene, camera);
    }
    return scene.scene_children.every((x)=>render_scene(x, picking));
}
function start_renderloop(three_scene) {
    const { fps  } = three_scene.screen;
    const time_per_frame = 1 / fps * 1000;
    let last_time_stamp = performance.now();
    function renderloop(timestamp) {
        if (timestamp - last_time_stamp > time_per_frame) {
            const all_rendered = render_scene(three_scene);
            if (!all_rendered) {
                return;
            }
            last_time_stamp = performance.now();
        }
        window.requestAnimationFrame(renderloop);
    }
    render_scene(three_scene);
    renderloop();
}
function throttle_function(func, delay) {
    let prev = 0;
    return (...args)=>{
        const now = new Date().getTime();
        if (now - prev > delay) {
            prev = now;
            return func(...args);
        }
    };
}
function threejs_module(canvas, comm, width, height) {
    let context = canvas.getContext("webgl2", {
        preserveDrawingBuffer: true
    });
    if (!context) {
        console.warn("WebGL 2.0 not supported by browser, falling back to WebGL 1.0 (Volume plots will not work)");
        context = canvas.getContext("webgl", {
            preserveDrawingBuffer: true
        });
    }
    if (!context) {
        return;
    }
    const renderer = new mod.WebGLRenderer({
        antialias: true,
        canvas: canvas,
        context: context,
        powerPreference: "high-performance"
    });
    renderer.setClearColor("#ffffff");
    renderer.setPixelRatio(pixelRatio1);
    renderer.setSize(width / pixelRatio1, height / pixelRatio1);
    const mouse_callback = (x, y)=>comm.notify({
            mouseposition: [
                x,
                y
            ]
        });
    const notify_mouse_throttled = throttle_function(mouse_callback, 40);
    function mousemove(event) {
        var rect = canvas.getBoundingClientRect();
        var x = (event.clientX - rect.left) * pixelRatio1;
        var y = (event.clientY - rect.top) * pixelRatio1;
        notify_mouse_throttled(x, y);
        return false;
    }
    canvas.addEventListener("mousemove", mousemove);
    function mousedown(event) {
        comm.notify({
            mousedown: event.buttons
        });
        return false;
    }
    canvas.addEventListener("mousedown", mousedown);
    function mouseup(event) {
        comm.notify({
            mouseup: event.buttons
        });
        return false;
    }
    canvas.addEventListener("mouseup", mouseup);
    function wheel(event) {
        comm.notify({
            scroll: [
                event.deltaX,
                -event.deltaY
            ]
        });
        event.preventDefault();
        return false;
    }
    canvas.addEventListener("wheel", wheel);
    function keydown(event) {
        comm.notify({
            keydown: event.code
        });
        return false;
    }
    canvas.addEventListener("keydown", keydown);
    function keyup(event) {
        comm.notify({
            keyup: event.code
        });
        return false;
    }
    canvas.addEventListener("keyup", keyup);
    function contextmenu(event) {
        comm.notify({
            keyup: "delete_keys"
        });
        return false;
    }
    canvas.addEventListener("contextmenu", (e)=>e.preventDefault());
    canvas.addEventListener("focusout", contextmenu);
    return renderer;
}
function create_scene(wrapper, canvas, canvas_width, scenes, comm, width, height, fps, texture_atlas_obs) {
    const renderer = threejs_module(canvas, comm, width, height);
    TEXTURE_ATLAS[0] = texture_atlas_obs;
    if (renderer) {
        const camera = new mod.PerspectiveCamera(45, 1, 0, 100);
        camera.updateProjectionMatrix();
        const size = new mod.Vector2();
        renderer.getDrawingBufferSize(size);
        const picking_target = new mod.WebGLRenderTarget(size.x, size.y);
        const screen = {
            renderer,
            picking_target,
            camera,
            fps,
            canvas
        };
        const three_scene = deserialize_scene(scenes, screen);
        console.log(three_scene);
        start_renderloop(three_scene);
        canvas_width.on((w_h)=>{
            const pixelRatio = renderer.getPixelRatio();
            renderer.setSize(w_h[0] / pixelRatio, w_h[1] / pixelRatio);
        });
    } else {
        const warning = getWebGLErrorMessage();
        wrapper.appendChild(warning);
    }
}
function set_picking_uniforms(scene, last_id, picking, picked_plots, plots, id_to_plot) {
    scene.children.forEach((plot, index)=>{
        const { material  } = plot;
        const { uniforms  } = material;
        if (picking) {
            uniforms.object_id.value = last_id + index;
            uniforms.picking.value = true;
            material.blending = mod.NoBlending;
        } else {
            uniforms.picking.value = false;
            material.blending = mod.NormalBlending;
            const id = uniforms.object_id.value;
            if (id in picked_plots) {
                plots.push([
                    plot,
                    picked_plots[id]
                ]);
                id_to_plot[id] = plot;
            }
        }
    });
    let next_id = last_id + scene.children.length;
    scene.scene_children.forEach((scene)=>{
        next_id = set_picking_uniforms(scene, next_id, picking, picked_plots, plots, id_to_plot);
    });
    return next_id;
}
function pick_native(scene, x, y, w, h) {
    const { renderer , picking_target  } = scene.screen;
    renderer.setRenderTarget(picking_target);
    set_picking_uniforms(scene, 1, true);
    render_scene(scene, true);
    renderer.setRenderTarget(null);
    const nbytes = w * h * 4;
    const pixel_bytes = new Uint8Array(nbytes);
    renderer.readRenderTargetPixels(picking_target, x, y, w, h, pixel_bytes);
    const picked_plots = {};
    const picked_plots_array = [];
    const reinterpret_view = new DataView(pixel_bytes.buffer);
    for(let i = 0; i < pixel_bytes.length / 4; i++){
        const id = reinterpret_view.getUint16(i * 4);
        const index = reinterpret_view.getUint16(i * 4 + 2);
        picked_plots_array.push([
            id,
            index
        ]);
        picked_plots[id] = index;
    }
    const plots = [];
    const id_to_plot = {};
    set_picking_uniforms(scene, 0, false, picked_plots, plots, id_to_plot);
    const picked_plots_matrix = picked_plots_array.map(([id, index])=>{
        const p = id_to_plot[id];
        return [
            p ? p.plot_uuid : null,
            index
        ];
    });
    const plot_matrix = {
        data: picked_plots_matrix,
        size: [
            w,
            h
        ]
    };
    return [
        plot_matrix,
        plots
    ];
}
function pick_closest(scene, xy, range) {
    const { picking_target  } = scene.screen;
    const { width , height  } = picking_target;
    if (!(1.0 <= xy[0] <= width && 1.0 <= xy[1] <= height)) {
        return [
            null,
            0
        ];
    }
    const x0 = Math.max(1, xy[0] - range);
    const y0 = Math.max(1, xy[1] - range);
    const x1 = Math.min(width, Math.floor(xy[0] + range));
    const y1 = Math.min(height, Math.floor(xy[1] + range));
    const dx = x1 - x0;
    const dy = y1 - y0;
    const [plot_data, _] = pick_native(scene, x0, y0, dx, dy);
    const plot_matrix = plot_data.data;
    let min_dist = range ^ 2;
    let selection = [
        null,
        0
    ];
    const x = xy[0] + 1 - x0;
    const y = xy[1] + 1 - y0;
    let pindex = 0;
    for(let i = 1; i <= dx; i++){
        for(let j = 1; j <= dx; j++){
            const d = x - i ^ 2 + (y - j) ^ 2;
            const [plot_uuid, index] = plot_matrix[pindex];
            pindex = pindex + 1;
            if (d < min_dist && plot_uuid) {
                min_dist = d;
                selection = [
                    plot_uuid,
                    index
                ];
            }
        }
    }
    return selection;
}
function pick_sorted(scene, xy, range) {
    const { picking_target  } = scene.screen;
    const { width , height  } = picking_target;
    if (!(1.0 <= xy[0] <= width && 1.0 <= xy[1] <= height)) {
        return [
            null,
            0
        ];
    }
    const x0 = Math.max(1, xy[0] - range);
    const y0 = Math.max(1, xy[1] - range);
    const x1 = Math.min(width, Math.floor(xy[0] + range));
    const y1 = Math.min(height, Math.floor(xy[1] + range));
    const dx = x1 - x0;
    const dy = y1 - y0;
    const [plot_data, selected] = pick_native(scene, x0, y0, dx, dy);
    if (selected.length == 0) {
        return [];
    }
    const plot_matrix = plot_data.data;
    const distances = selected.map((x)=>range ^ 2);
    const x = xy[0] + 1 - x0;
    const y = xy[1] + 1 - y0;
    let pindex = 0;
    for(let i = 1; i <= dx; i++){
        for(let j = 1; j <= dx; j++){
            const d = x - i ^ 2 + (y - j) ^ 2;
            const [plot_uuid, index] = plot_matrix[pindex];
            pindex = pindex + 1;
            const plot_index = selected.findIndex((x)=>x[0].plot_uuid == plot_uuid);
            if (plot_index >= 0 && d < distances[plot_index]) {
                distances[plot_index] = d;
            }
        }
    }
    const sorted_indices = Array.from(Array(distances.length).keys()).sort((a, b)=>distances[a] < distances[b] ? -1 : distances[b] < distances[a] | 0);
    return sorted_indices.map((idx)=>{
        const [plot, index] = selected[idx];
        return [
            plot.plot_uuid,
            index
        ];
    });
}
function pick_native_uuid(scene, x, y, w, h) {
    const [_, picked_plots] = pick_native(scene, x, y, w, h);
    return picked_plots.map(([p, index])=>[
            p.plot_uuid,
            index
        ]);
}
function pick_native_matrix(scene, x, y, w, h) {
    const [matrix, _] = pick_native(scene, x, y, w, h);
    return matrix;
}
function register_popup(popup, scene, plots_to_pick, callback) {
    if (!scene || !scene.screen) {
        return;
    }
    const { canvas  } = scene.screen;
    canvas.addEventListener("mousedown", (event)=>{
        if (!popup.classList.contains("show")) {
            popup.classList.add("show");
        }
        popup.style.left = event.pageX + "px";
        popup.style.top = event.pageY + "px";
        const [x, y] = WGLMakie.event2scene_pixel(scene, event);
        const [_, picks] = WGLMakie.pick_native(scene, x, y, 1, 1);
        if (picks.length == 1) {
            const [plot, index] = picks[0];
            if (plots_to_pick.has(plot.plot_uuid)) {
                const result = callback(plot, index);
                if (typeof result === "string" || result instanceof String) {
                    popup.innerText = result;
                } else {
                    popup.innerHTML = result;
                }
            }
        } else {
            popup.classList.remove("show");
        }
    });
    canvas.addEventListener("keyup", (event)=>{
        if (event.key === "Escape") {
            popup.classList.remove("show");
        }
    });
}
window.WGL = {
    deserialize_scene,
    threejs_module,
    start_renderloop,
    delete_plots,
    insert_plot,
    find_plots,
    delete_scene,
    find_scene,
    scene_cache,
    plot_cache,
    delete_scenes,
    create_scene,
    event2scene_pixel,
    on_next_insert
};
export { deserialize_scene as deserialize_scene, threejs_module as threejs_module, start_renderloop as start_renderloop, delete_plots as delete_plots, insert_plot as insert_plot, find_plots as find_plots, delete_scene as delete_scene, find_scene as find_scene, scene_cache as scene_cache, plot_cache as plot_cache, delete_scenes as delete_scenes, create_scene as create_scene, event2scene_pixel as event2scene_pixel, on_next_insert as on_next_insert };
export { render_scene as render_scene };
export { pick_native as pick_native };
export { pick_closest as pick_closest };
export { pick_sorted as pick_sorted };
export { pick_native_uuid as pick_native_uuid };
export { pick_native_matrix as pick_native_matrix };
export { register_popup as register_popup };

