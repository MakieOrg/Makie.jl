// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

var Hc = "157", zx = {
    LEFT: 0,
    MIDDLE: 1,
    RIGHT: 2,
    ROTATE: 0,
    DOLLY: 1,
    PAN: 2
}, Vx = {
    ROTATE: 0,
    PAN: 1,
    DOLLY_PAN: 2,
    DOLLY_ROTATE: 3
}, kd = 0, rl = 1, Hd = 2, kx = 3, Hx = 0, cd = 1, Gd = 2, pn = 3, Bn = 0, Ft = 1, gn = 2, Gx = 2, Dn = 0, Wi = 1, al = 2, ol = 3, cl = 4, Wd = 5, Bi = 100, Xd = 101, qd = 102, ll = 103, hl = 104, Yd = 200, Zd = 201, Jd = 202, $d = 203, ld = 204, hd = 205, Kd = 206, Qd = 207, jd = 208, ef = 209, tf = 210, nf = 0, sf = 1, rf = 2, uo = 3, af = 4, of = 5, cf = 6, lf = 7, xa = 0, hf = 1, uf = 2, Nn = 0, df = 1, ff = 2, pf = 3, mf = 4, gf = 5, Gc = 300, zn = 301, ci = 302, Ir = 303, Ur = 304, Vs = 306, Dr = 1e3, It = 1001, Nr = 1002, pt = 1003, fo = 1004, Wx = 1004, Lr = 1005, Xx = 1005, mt = 1006, ud = 1007, qx = 1007, li = 1008, Yx = 1008, On = 1009, _f = 1010, xf = 1011, Wc = 1012, dd = 1013, Ln = 1014, xn = 1015, Ts = 1016, fd = 1017, pd = 1018, ii = 1020, vf = 1021, Wt = 1023, yf = 1024, Mf = 1025, si = 1026, Yi = 1027, Sf = 1028, md = 1029, bf = 1030, gd = 1031, _d = 1033, wa = 33776, Aa = 33777, Ra = 33778, Ca = 33779, ul = 35840, dl = 35841, fl = 35842, pl = 35843, Ef = 36196, ml = 37492, gl = 37496, _l = 37808, xl = 37809, vl = 37810, yl = 37811, Ml = 37812, Sl = 37813, bl = 37814, El = 37815, Tl = 37816, wl = 37817, Al = 37818, Rl = 37819, Cl = 37820, Pl = 37821, Pa = 36492, Ll = 36494, Il = 36495, Tf = 36283, Ul = 36284, Dl = 36285, Nl = 36286, wf = 2200, Af = 2201, Rf = 2202, Or = 2300, Fr = 2301, La = 2302, zi = 2400, Vi = 2401, Br = 2402, Xc = 2500, xd = 2501, Zx = 0, Jx = 1, $x = 2, vd = 3e3, ri = 3001, Cf = 3200, Pf = 3201, mi = 0, Lf = 1, Xt = "", vt = "srgb", Mn = "srgb-linear", qc = "display-p3", va = "display-p3-linear", zr = "linear", nt = "srgb", Vr = "rec709", kr = "p3", Kx = 0, Ia = 7680, Qx = 7681, jx = 7682, ev = 7683, tv = 34055, nv = 34056, iv = 5386, sv = 512, rv = 513, av = 514, ov = 515, cv = 516, lv = 517, hv = 518, If = 519, Uf = 512, Df = 513, Nf = 514, Of = 515, Ff = 516, Bf = 517, zf = 518, Vf = 519, Hr = 35044, uv = 35048, dv = 35040, fv = 35045, pv = 35049, mv = 35041, gv = 35046, _v = 35050, xv = 35042, vv = "100", Ol = "300 es", po = 1035, vn = 2e3, Gr = 2001, sn = class {
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
            for(let r = 0, a = i.length; r < a; r++)i[r].call(this, e);
            e.target = null;
        }
    }
}, Et = [
    "00",
    "01",
    "02",
    "03",
    "04",
    "05",
    "06",
    "07",
    "08",
    "09",
    "0a",
    "0b",
    "0c",
    "0d",
    "0e",
    "0f",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16",
    "17",
    "18",
    "19",
    "1a",
    "1b",
    "1c",
    "1d",
    "1e",
    "1f",
    "20",
    "21",
    "22",
    "23",
    "24",
    "25",
    "26",
    "27",
    "28",
    "29",
    "2a",
    "2b",
    "2c",
    "2d",
    "2e",
    "2f",
    "30",
    "31",
    "32",
    "33",
    "34",
    "35",
    "36",
    "37",
    "38",
    "39",
    "3a",
    "3b",
    "3c",
    "3d",
    "3e",
    "3f",
    "40",
    "41",
    "42",
    "43",
    "44",
    "45",
    "46",
    "47",
    "48",
    "49",
    "4a",
    "4b",
    "4c",
    "4d",
    "4e",
    "4f",
    "50",
    "51",
    "52",
    "53",
    "54",
    "55",
    "56",
    "57",
    "58",
    "59",
    "5a",
    "5b",
    "5c",
    "5d",
    "5e",
    "5f",
    "60",
    "61",
    "62",
    "63",
    "64",
    "65",
    "66",
    "67",
    "68",
    "69",
    "6a",
    "6b",
    "6c",
    "6d",
    "6e",
    "6f",
    "70",
    "71",
    "72",
    "73",
    "74",
    "75",
    "76",
    "77",
    "78",
    "79",
    "7a",
    "7b",
    "7c",
    "7d",
    "7e",
    "7f",
    "80",
    "81",
    "82",
    "83",
    "84",
    "85",
    "86",
    "87",
    "88",
    "89",
    "8a",
    "8b",
    "8c",
    "8d",
    "8e",
    "8f",
    "90",
    "91",
    "92",
    "93",
    "94",
    "95",
    "96",
    "97",
    "98",
    "99",
    "9a",
    "9b",
    "9c",
    "9d",
    "9e",
    "9f",
    "a0",
    "a1",
    "a2",
    "a3",
    "a4",
    "a5",
    "a6",
    "a7",
    "a8",
    "a9",
    "aa",
    "ab",
    "ac",
    "ad",
    "ae",
    "af",
    "b0",
    "b1",
    "b2",
    "b3",
    "b4",
    "b5",
    "b6",
    "b7",
    "b8",
    "b9",
    "ba",
    "bb",
    "bc",
    "bd",
    "be",
    "bf",
    "c0",
    "c1",
    "c2",
    "c3",
    "c4",
    "c5",
    "c6",
    "c7",
    "c8",
    "c9",
    "ca",
    "cb",
    "cc",
    "cd",
    "ce",
    "cf",
    "d0",
    "d1",
    "d2",
    "d3",
    "d4",
    "d5",
    "d6",
    "d7",
    "d8",
    "d9",
    "da",
    "db",
    "dc",
    "dd",
    "de",
    "df",
    "e0",
    "e1",
    "e2",
    "e3",
    "e4",
    "e5",
    "e6",
    "e7",
    "e8",
    "e9",
    "ea",
    "eb",
    "ec",
    "ed",
    "ee",
    "ef",
    "f0",
    "f1",
    "f2",
    "f3",
    "f4",
    "f5",
    "f6",
    "f7",
    "f8",
    "f9",
    "fa",
    "fb",
    "fc",
    "fd",
    "fe",
    "ff"
], Fl = 1234567, ai = Math.PI / 180, Zi = 180 / Math.PI;
function kt() {
    let s1 = Math.random() * 4294967295 | 0, e = Math.random() * 4294967295 | 0, t = Math.random() * 4294967295 | 0, n = Math.random() * 4294967295 | 0;
    return (Et[s1 & 255] + Et[s1 >> 8 & 255] + Et[s1 >> 16 & 255] + Et[s1 >> 24 & 255] + "-" + Et[e & 255] + Et[e >> 8 & 255] + "-" + Et[e >> 16 & 15 | 64] + Et[e >> 24 & 255] + "-" + Et[t & 63 | 128] + Et[t >> 8 & 255] + "-" + Et[t >> 16 & 255] + Et[t >> 24 & 255] + Et[n & 255] + Et[n >> 8 & 255] + Et[n >> 16 & 255] + Et[n >> 24 & 255]).toLowerCase();
}
function ct(s1, e, t) {
    return Math.max(e, Math.min(t, s1));
}
function Yc(s1, e) {
    return (s1 % e + e) % e;
}
function kf(s1, e, t, n, i) {
    return n + (s1 - e) * (i - n) / (t - e);
}
function Hf(s1, e, t) {
    return s1 !== e ? (t - s1) / (e - s1) : 0;
}
function ys(s1, e, t) {
    return (1 - t) * s1 + t * e;
}
function Gf(s1, e, t, n) {
    return ys(s1, e, 1 - Math.exp(-t * n));
}
function Wf(s1, e = 1) {
    return e - Math.abs(Yc(s1, e * 2) - e);
}
function Xf(s1, e, t) {
    return s1 <= e ? 0 : s1 >= t ? 1 : (s1 = (s1 - e) / (t - e), s1 * s1 * (3 - 2 * s1));
}
function qf(s1, e, t) {
    return s1 <= e ? 0 : s1 >= t ? 1 : (s1 = (s1 - e) / (t - e), s1 * s1 * s1 * (s1 * (s1 * 6 - 15) + 10));
}
function Yf(s1, e) {
    return s1 + Math.floor(Math.random() * (e - s1 + 1));
}
function Zf(s1, e) {
    return s1 + Math.random() * (e - s1);
}
function Jf(s1) {
    return s1 * (.5 - Math.random());
}
function $f(s1) {
    s1 !== void 0 && (Fl = s1);
    let e = Fl += 1831565813;
    return e = Math.imul(e ^ e >>> 15, e | 1), e ^= e + Math.imul(e ^ e >>> 7, e | 61), ((e ^ e >>> 14) >>> 0) / 4294967296;
}
function Kf(s1) {
    return s1 * ai;
}
function Qf(s1) {
    return s1 * Zi;
}
function mo(s1) {
    return (s1 & s1 - 1) === 0 && s1 !== 0;
}
function yd(s1) {
    return Math.pow(2, Math.ceil(Math.log(s1) / Math.LN2));
}
function Wr(s1) {
    return Math.pow(2, Math.floor(Math.log(s1) / Math.LN2));
}
function jf(s1, e, t, n, i) {
    let r = Math.cos, a = Math.sin, o = r(t / 2), c = a(t / 2), l = r((e + n) / 2), h = a((e + n) / 2), u = r((e - n) / 2), d = a((e - n) / 2), f = r((n - e) / 2), m = a((n - e) / 2);
    switch(i){
        case "XYX":
            s1.set(o * h, c * u, c * d, o * l);
            break;
        case "YZY":
            s1.set(c * d, o * h, c * u, o * l);
            break;
        case "ZXZ":
            s1.set(c * u, c * d, o * h, o * l);
            break;
        case "XZX":
            s1.set(o * h, c * m, c * f, o * l);
            break;
        case "YXY":
            s1.set(c * f, o * h, c * m, o * l);
            break;
        case "ZYZ":
            s1.set(c * m, c * f, o * h, o * l);
            break;
        default:
            console.warn("THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: " + i);
    }
}
function Ot(s1, e) {
    switch(e.constructor){
        case Float32Array:
            return s1;
        case Uint32Array:
            return s1 / 4294967295;
        case Uint16Array:
            return s1 / 65535;
        case Uint8Array:
            return s1 / 255;
        case Int32Array:
            return Math.max(s1 / 2147483647, -1);
        case Int16Array:
            return Math.max(s1 / 32767, -1);
        case Int8Array:
            return Math.max(s1 / 127, -1);
        default:
            throw new Error("Invalid component type.");
    }
}
function Be(s1, e) {
    switch(e.constructor){
        case Float32Array:
            return s1;
        case Uint32Array:
            return Math.round(s1 * 4294967295);
        case Uint16Array:
            return Math.round(s1 * 65535);
        case Uint8Array:
            return Math.round(s1 * 255);
        case Int32Array:
            return Math.round(s1 * 2147483647);
        case Int16Array:
            return Math.round(s1 * 32767);
        case Int8Array:
            return Math.round(s1 * 127);
        default:
            throw new Error("Invalid component type.");
    }
}
var yv = {
    DEG2RAD: ai,
    RAD2DEG: Zi,
    generateUUID: kt,
    clamp: ct,
    euclideanModulo: Yc,
    mapLinear: kf,
    inverseLerp: Hf,
    lerp: ys,
    damp: Gf,
    pingpong: Wf,
    smoothstep: Xf,
    smootherstep: qf,
    randInt: Yf,
    randFloat: Zf,
    randFloatSpread: Jf,
    seededRandom: $f,
    degToRad: Kf,
    radToDeg: Qf,
    isPowerOfTwo: mo,
    ceilPowerOfTwo: yd,
    floorPowerOfTwo: Wr,
    setQuaternionFromProperEuler: jf,
    normalize: Be,
    denormalize: Ot
}, Z = class s1 {
    constructor(e = 0, t = 0){
        s1.prototype.isVector2 = !0, this.x = e, this.y = t;
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
    add(e) {
        return this.x += e.x, this.y += e.y, this;
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
    sub(e) {
        return this.x -= e.x, this.y -= e.y, this;
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
        return this.x = Math.trunc(this.x), this.y = Math.trunc(this.y), this;
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
    angleTo(e) {
        let t = Math.sqrt(this.lengthSq() * e.lengthSq());
        if (t === 0) return Math.PI / 2;
        let n = this.dot(e) / t;
        return Math.acos(ct(n, -1, 1));
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
    fromBufferAttribute(e, t) {
        return this.x = e.getX(t), this.y = e.getY(t), this;
    }
    rotateAround(e, t) {
        let n = Math.cos(t), i = Math.sin(t), r = this.x - e.x, a = this.y - e.y;
        return this.x = r * n - a * i + e.x, this.y = r * i + a * n + e.y, this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y;
    }
}, He = class s1 {
    constructor(e, t, n, i, r, a, o, c, l){
        s1.prototype.isMatrix3 = !0, this.elements = [
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
        ], e !== void 0 && this.set(e, t, n, i, r, a, o, c, l);
    }
    set(e, t, n, i, r, a, o, c, l) {
        let h = this.elements;
        return h[0] = e, h[1] = i, h[2] = o, h[3] = t, h[4] = r, h[5] = c, h[6] = n, h[7] = a, h[8] = l, this;
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
        let n = e.elements, i = t.elements, r = this.elements, a = n[0], o = n[3], c = n[6], l = n[1], h = n[4], u = n[7], d = n[2], f = n[5], m = n[8], _ = i[0], g = i[3], p = i[6], v = i[1], x = i[4], y = i[7], b = i[2], w = i[5], R = i[8];
        return r[0] = a * _ + o * v + c * b, r[3] = a * g + o * x + c * w, r[6] = a * p + o * y + c * R, r[1] = l * _ + h * v + u * b, r[4] = l * g + h * x + u * w, r[7] = l * p + h * y + u * R, r[2] = d * _ + f * v + m * b, r[5] = d * g + f * x + m * w, r[8] = d * p + f * y + m * R, this;
    }
    multiplyScalar(e) {
        let t = this.elements;
        return t[0] *= e, t[3] *= e, t[6] *= e, t[1] *= e, t[4] *= e, t[7] *= e, t[2] *= e, t[5] *= e, t[8] *= e, this;
    }
    determinant() {
        let e = this.elements, t = e[0], n = e[1], i = e[2], r = e[3], a = e[4], o = e[5], c = e[6], l = e[7], h = e[8];
        return t * a * h - t * o * l - n * r * h + n * o * c + i * r * l - i * a * c;
    }
    invert() {
        let e = this.elements, t = e[0], n = e[1], i = e[2], r = e[3], a = e[4], o = e[5], c = e[6], l = e[7], h = e[8], u = h * a - o * l, d = o * c - h * r, f = l * r - a * c, m = t * u + n * d + i * f;
        if (m === 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0);
        let _ = 1 / m;
        return e[0] = u * _, e[1] = (i * l - h * n) * _, e[2] = (o * n - i * a) * _, e[3] = d * _, e[4] = (h * t - i * c) * _, e[5] = (i * r - o * t) * _, e[6] = f * _, e[7] = (n * c - l * t) * _, e[8] = (a * t - n * r) * _, this;
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
    setUvTransform(e, t, n, i, r, a, o) {
        let c = Math.cos(r), l = Math.sin(r);
        return this.set(n * c, n * l, -n * (c * a + l * o) + a + e, -i * l, i * c, -i * (-l * a + c * o) + o + t, 0, 0, 1), this;
    }
    scale(e, t) {
        return this.premultiply(Ua.makeScale(e, t)), this;
    }
    rotate(e) {
        return this.premultiply(Ua.makeRotation(-e)), this;
    }
    translate(e, t) {
        return this.premultiply(Ua.makeTranslation(e, t)), this;
    }
    makeTranslation(e, t) {
        return e.isVector2 ? this.set(1, 0, e.x, 0, 1, e.y, 0, 0, 1) : this.set(1, 0, e, 0, 1, t, 0, 0, 1), this;
    }
    makeRotation(e) {
        let t = Math.cos(e), n = Math.sin(e);
        return this.set(t, -n, 0, n, t, 0, 0, 0, 1), this;
    }
    makeScale(e, t) {
        return this.set(e, 0, 0, 0, t, 0, 0, 0, 1), this;
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
}, Ua = new He;
function Md(s1) {
    for(let e = s1.length - 1; e >= 0; --e)if (s1[e] >= 65535) return !0;
    return !1;
}
var ep = {
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
function ki(s1, e) {
    return new ep[s1](e);
}
function ws(s1) {
    return document.createElementNS("http://www.w3.org/1999/xhtml", s1);
}
function tp() {
    let s1 = ws("canvas");
    return s1.style.display = "block", s1;
}
var Bl = {};
function Ms(s1) {
    s1 in Bl || (Bl[s1] = !0, console.warn(s1));
}
var zl = new He().set(.8224621, .177538, 0, .0331941, .9668058, 0, .0170827, .0723974, .9105199), Vl = new He().set(1.2249401, -.2249404, 0, -.0420569, 1.0420571, 0, -.0196376, -.0786361, 1.0982735), Gs = {
    [Mn]: {
        transfer: zr,
        primaries: Vr,
        toReference: (s1)=>s1,
        fromReference: (s1)=>s1
    },
    [vt]: {
        transfer: nt,
        primaries: Vr,
        toReference: (s1)=>s1.convertSRGBToLinear(),
        fromReference: (s1)=>s1.convertLinearToSRGB()
    },
    [va]: {
        transfer: zr,
        primaries: kr,
        toReference: (s1)=>s1.applyMatrix3(Vl),
        fromReference: (s1)=>s1.applyMatrix3(zl)
    },
    [qc]: {
        transfer: nt,
        primaries: kr,
        toReference: (s1)=>s1.convertSRGBToLinear().applyMatrix3(Vl),
        fromReference: (s1)=>s1.applyMatrix3(zl).convertLinearToSRGB()
    }
}, np = new Set([
    Mn,
    va
]), Qe = {
    enabled: !0,
    _workingColorSpace: Mn,
    get legacyMode () {
        return console.warn("THREE.ColorManagement: .legacyMode=false renamed to .enabled=true in r150."), !this.enabled;
    },
    set legacyMode (s){
        console.warn("THREE.ColorManagement: .legacyMode=false renamed to .enabled=true in r150."), this.enabled = !s;
    },
    get workingColorSpace () {
        return this._workingColorSpace;
    },
    set workingColorSpace (s){
        if (!np.has(s)) throw new Error(`Unsupported working color space, "${s}".`);
        this._workingColorSpace = s;
    },
    convert: function(s1, e, t) {
        if (this.enabled === !1 || e === t || !e || !t) return s1;
        let n = Gs[e].toReference, i = Gs[t].fromReference;
        return i(n(s1));
    },
    fromWorkingColorSpace: function(s1, e) {
        return this.convert(s1, this._workingColorSpace, e);
    },
    toWorkingColorSpace: function(s1, e) {
        return this.convert(s1, e, this._workingColorSpace);
    },
    getPrimaries: function(s1) {
        return Gs[s1].primaries;
    },
    getTransfer: function(s1) {
        return s1 === Xt ? zr : Gs[s1].transfer;
    }
};
function Xi(s1) {
    return s1 < .04045 ? s1 * .0773993808 : Math.pow(s1 * .9478672986 + .0521327014, 2.4);
}
function Da(s1) {
    return s1 < .0031308 ? s1 * 12.92 : 1.055 * Math.pow(s1, .41666) - .055;
}
var gi, Xr = class {
    static getDataURL(e) {
        if (/^data:/i.test(e.src) || typeof HTMLCanvasElement > "u") return e.src;
        let t;
        if (e instanceof HTMLCanvasElement) t = e;
        else {
            gi === void 0 && (gi = ws("canvas")), gi.width = e.width, gi.height = e.height;
            let n = gi.getContext("2d");
            e instanceof ImageData ? n.putImageData(e, 0, 0) : n.drawImage(e, 0, 0, e.width, e.height), t = gi;
        }
        return t.width > 2048 || t.height > 2048 ? (console.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", e), t.toDataURL("image/jpeg", .6)) : t.toDataURL("image/png");
    }
    static sRGBToLinear(e) {
        if (typeof HTMLImageElement < "u" && e instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && e instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && e instanceof ImageBitmap) {
            let t = ws("canvas");
            t.width = e.width, t.height = e.height;
            let n = t.getContext("2d");
            n.drawImage(e, 0, 0, e.width, e.height);
            let i = n.getImageData(0, 0, e.width, e.height), r = i.data;
            for(let a = 0; a < r.length; a++)r[a] = Xi(r[a] / 255) * 255;
            return n.putImageData(i, 0, 0), t;
        } else if (e.data) {
            let t = e.data.slice(0);
            for(let n = 0; n < t.length; n++)t instanceof Uint8Array || t instanceof Uint8ClampedArray ? t[n] = Math.floor(Xi(t[n] / 255) * 255) : t[n] = Xi(t[n]);
            return {
                data: t,
                width: e.width,
                height: e.height
            };
        } else return console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied."), e;
    }
}, ip = 0, In = class {
    constructor(e = null){
        this.isSource = !0, Object.defineProperty(this, "id", {
            value: ip++
        }), this.uuid = kt(), this.data = e, this.version = 0;
    }
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
    toJSON(e) {
        let t = e === void 0 || typeof e == "string";
        if (!t && e.images[this.uuid] !== void 0) return e.images[this.uuid];
        let n = {
            uuid: this.uuid,
            url: ""
        }, i = this.data;
        if (i !== null) {
            let r;
            if (Array.isArray(i)) {
                r = [];
                for(let a = 0, o = i.length; a < o; a++)i[a].isDataTexture ? r.push(Na(i[a].image)) : r.push(Na(i[a]));
            } else r = Na(i);
            n.url = r;
        }
        return t || (e.images[this.uuid] = n), n;
    }
};
function Na(s1) {
    return typeof HTMLImageElement < "u" && s1 instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && s1 instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && s1 instanceof ImageBitmap ? Xr.getDataURL(s1) : s1.data ? {
        data: Array.from(s1.data),
        width: s1.width,
        height: s1.height,
        type: s1.data.constructor.name
    } : (console.warn("THREE.Texture: Unable to serialize Texture."), {});
}
var sp = 0, St = class s1 extends sn {
    constructor(e = s1.DEFAULT_IMAGE, t = s1.DEFAULT_MAPPING, n = It, i = It, r = mt, a = li, o = Wt, c = On, l = s1.DEFAULT_ANISOTROPY, h = Xt){
        super(), this.isTexture = !0, Object.defineProperty(this, "id", {
            value: sp++
        }), this.uuid = kt(), this.name = "", this.source = new In(e), this.mipmaps = [], this.mapping = t, this.channel = 0, this.wrapS = n, this.wrapT = i, this.magFilter = r, this.minFilter = a, this.anisotropy = l, this.format = o, this.internalFormat = null, this.type = c, this.offset = new Z(0, 0), this.repeat = new Z(1, 1), this.center = new Z(0, 0), this.rotation = 0, this.matrixAutoUpdate = !0, this.matrix = new He, this.generateMipmaps = !0, this.premultiplyAlpha = !1, this.flipY = !0, this.unpackAlignment = 4, typeof h == "string" ? this.colorSpace = h : (Ms("THREE.Texture: Property .encoding has been replaced by .colorSpace."), this.colorSpace = h === ri ? vt : Xt), this.userData = {}, this.version = 0, this.onUpdate = null, this.isRenderTargetTexture = !1, this.needsPMREMUpdate = !1;
    }
    get image() {
        return this.source.data;
    }
    set image(e = null) {
        this.source.data = e;
    }
    updateMatrix() {
        this.matrix.setUvTransform(this.offset.x, this.offset.y, this.repeat.x, this.repeat.y, this.rotation, this.center.x, this.center.y);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        return this.name = e.name, this.source = e.source, this.mipmaps = e.mipmaps.slice(0), this.mapping = e.mapping, this.channel = e.channel, this.wrapS = e.wrapS, this.wrapT = e.wrapT, this.magFilter = e.magFilter, this.minFilter = e.minFilter, this.anisotropy = e.anisotropy, this.format = e.format, this.internalFormat = e.internalFormat, this.type = e.type, this.offset.copy(e.offset), this.repeat.copy(e.repeat), this.center.copy(e.center), this.rotation = e.rotation, this.matrixAutoUpdate = e.matrixAutoUpdate, this.matrix.copy(e.matrix), this.generateMipmaps = e.generateMipmaps, this.premultiplyAlpha = e.premultiplyAlpha, this.flipY = e.flipY, this.unpackAlignment = e.unpackAlignment, this.colorSpace = e.colorSpace, this.userData = JSON.parse(JSON.stringify(e.userData)), this.needsUpdate = !0, this;
    }
    toJSON(e) {
        let t = e === void 0 || typeof e == "string";
        if (!t && e.textures[this.uuid] !== void 0) return e.textures[this.uuid];
        let n = {
            metadata: {
                version: 4.6,
                type: "Texture",
                generator: "Texture.toJSON"
            },
            uuid: this.uuid,
            name: this.name,
            image: this.source.toJSON(e).uuid,
            mapping: this.mapping,
            channel: this.channel,
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
            internalFormat: this.internalFormat,
            type: this.type,
            colorSpace: this.colorSpace,
            minFilter: this.minFilter,
            magFilter: this.magFilter,
            anisotropy: this.anisotropy,
            flipY: this.flipY,
            generateMipmaps: this.generateMipmaps,
            premultiplyAlpha: this.premultiplyAlpha,
            unpackAlignment: this.unpackAlignment
        };
        return Object.keys(this.userData).length > 0 && (n.userData = this.userData), t || (e.textures[this.uuid] = n), n;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
    transformUv(e) {
        if (this.mapping !== Gc) return e;
        if (e.applyMatrix3(this.matrix), e.x < 0 || e.x > 1) switch(this.wrapS){
            case Dr:
                e.x = e.x - Math.floor(e.x);
                break;
            case It:
                e.x = e.x < 0 ? 0 : 1;
                break;
            case Nr:
                Math.abs(Math.floor(e.x) % 2) === 1 ? e.x = Math.ceil(e.x) - e.x : e.x = e.x - Math.floor(e.x);
                break;
        }
        if (e.y < 0 || e.y > 1) switch(this.wrapT){
            case Dr:
                e.y = e.y - Math.floor(e.y);
                break;
            case It:
                e.y = e.y < 0 ? 0 : 1;
                break;
            case Nr:
                Math.abs(Math.floor(e.y) % 2) === 1 ? e.y = Math.ceil(e.y) - e.y : e.y = e.y - Math.floor(e.y);
                break;
        }
        return this.flipY && (e.y = 1 - e.y), e;
    }
    set needsUpdate(e) {
        e === !0 && (this.version++, this.source.needsUpdate = !0);
    }
    get encoding() {
        return Ms("THREE.Texture: Property .encoding has been replaced by .colorSpace."), this.colorSpace === vt ? ri : vd;
    }
    set encoding(e) {
        Ms("THREE.Texture: Property .encoding has been replaced by .colorSpace."), this.colorSpace = e === ri ? vt : Xt;
    }
};
St.DEFAULT_IMAGE = null;
St.DEFAULT_MAPPING = Gc;
St.DEFAULT_ANISOTROPY = 1;
var je = class s1 {
    constructor(e = 0, t = 0, n = 0, i = 1){
        s1.prototype.isVector4 = !0, this.x = e, this.y = t, this.z = n, this.w = i;
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
    add(e) {
        return this.x += e.x, this.y += e.y, this.z += e.z, this.w += e.w, this;
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
    sub(e) {
        return this.x -= e.x, this.y -= e.y, this.z -= e.z, this.w -= e.w, this;
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
        let t = this.x, n = this.y, i = this.z, r = this.w, a = e.elements;
        return this.x = a[0] * t + a[4] * n + a[8] * i + a[12] * r, this.y = a[1] * t + a[5] * n + a[9] * i + a[13] * r, this.z = a[2] * t + a[6] * n + a[10] * i + a[14] * r, this.w = a[3] * t + a[7] * n + a[11] * i + a[15] * r, this;
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
        let t, n, i, r, c = e.elements, l = c[0], h = c[4], u = c[8], d = c[1], f = c[5], m = c[9], _ = c[2], g = c[6], p = c[10];
        if (Math.abs(h - d) < .01 && Math.abs(u - _) < .01 && Math.abs(m - g) < .01) {
            if (Math.abs(h + d) < .1 && Math.abs(u + _) < .1 && Math.abs(m + g) < .1 && Math.abs(l + f + p - 3) < .1) return this.set(1, 0, 0, 0), this;
            t = Math.PI;
            let x = (l + 1) / 2, y = (f + 1) / 2, b = (p + 1) / 2, w = (h + d) / 4, R = (u + _) / 4, I = (m + g) / 4;
            return x > y && x > b ? x < .01 ? (n = 0, i = .707106781, r = .707106781) : (n = Math.sqrt(x), i = w / n, r = R / n) : y > b ? y < .01 ? (n = .707106781, i = 0, r = .707106781) : (i = Math.sqrt(y), n = w / i, r = I / i) : b < .01 ? (n = .707106781, i = .707106781, r = 0) : (r = Math.sqrt(b), n = R / r, i = I / r), this.set(n, i, r, t), this;
        }
        let v = Math.sqrt((g - m) * (g - m) + (u - _) * (u - _) + (d - h) * (d - h));
        return Math.abs(v) < .001 && (v = 1), this.x = (g - m) / v, this.y = (u - _) / v, this.z = (d - h) / v, this.w = Math.acos((l + f + p - 1) / 2), this;
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
        return this.x = Math.trunc(this.x), this.y = Math.trunc(this.y), this.z = Math.trunc(this.z), this.w = Math.trunc(this.w), this;
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
    fromBufferAttribute(e, t) {
        return this.x = e.getX(t), this.y = e.getY(t), this.z = e.getZ(t), this.w = e.getW(t), this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this.z = Math.random(), this.w = Math.random(), this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y, yield this.z, yield this.w;
    }
}, go = class extends sn {
    constructor(e = 1, t = 1, n = {}){
        super(), this.isRenderTarget = !0, this.width = e, this.height = t, this.depth = 1, this.scissor = new je(0, 0, e, t), this.scissorTest = !1, this.viewport = new je(0, 0, e, t);
        let i = {
            width: e,
            height: t,
            depth: 1
        };
        n.encoding !== void 0 && (Ms("THREE.WebGLRenderTarget: option.encoding has been replaced by option.colorSpace."), n.colorSpace = n.encoding === ri ? vt : Xt), n = Object.assign({
            generateMipmaps: !1,
            internalFormat: null,
            minFilter: mt,
            depthBuffer: !0,
            stencilBuffer: !1,
            depthTexture: null,
            samples: 0
        }, n), this.texture = new St(i, n.mapping, n.wrapS, n.wrapT, n.magFilter, n.minFilter, n.format, n.type, n.anisotropy, n.colorSpace), this.texture.isRenderTargetTexture = !0, this.texture.flipY = !1, this.texture.generateMipmaps = n.generateMipmaps, this.texture.internalFormat = n.internalFormat, this.depthBuffer = n.depthBuffer, this.stencilBuffer = n.stencilBuffer, this.depthTexture = n.depthTexture, this.samples = n.samples;
    }
    setSize(e, t, n = 1) {
        (this.width !== e || this.height !== t || this.depth !== n) && (this.width = e, this.height = t, this.depth = n, this.texture.image.width = e, this.texture.image.height = t, this.texture.image.depth = n, this.dispose()), this.viewport.set(0, 0, e, t), this.scissor.set(0, 0, e, t);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        this.width = e.width, this.height = e.height, this.depth = e.depth, this.scissor.copy(e.scissor), this.scissorTest = e.scissorTest, this.viewport.copy(e.viewport), this.texture = e.texture.clone(), this.texture.isRenderTargetTexture = !0;
        let t = Object.assign({}, e.texture.image);
        return this.texture.source = new In(t), this.depthBuffer = e.depthBuffer, this.stencilBuffer = e.stencilBuffer, e.depthTexture !== null && (this.depthTexture = e.depthTexture.clone()), this.samples = e.samples, this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
}, qt = class extends go {
    constructor(e = 1, t = 1, n = {}){
        super(e, t, n), this.isWebGLRenderTarget = !0;
    }
}, As = class extends St {
    constructor(e = null, t = 1, n = 1, i = 1){
        super(null), this.isDataArrayTexture = !0, this.image = {
            data: e,
            width: t,
            height: n,
            depth: i
        }, this.magFilter = pt, this.minFilter = pt, this.wrapR = It, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
}, kl = class extends qt {
    constructor(e = 1, t = 1, n = 1){
        super(e, t), this.isWebGLArrayRenderTarget = !0, this.depth = n, this.texture = new As(null, e, t, n), this.texture.isRenderTargetTexture = !0;
    }
}, qr = class extends St {
    constructor(e = null, t = 1, n = 1, i = 1){
        super(null), this.isData3DTexture = !0, this.image = {
            data: e,
            width: t,
            height: n,
            depth: i
        }, this.magFilter = pt, this.minFilter = pt, this.wrapR = It, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
}, Hl = class extends qt {
    constructor(e = 1, t = 1, n = 1){
        super(e, t), this.isWebGL3DRenderTarget = !0, this.depth = n, this.texture = new qr(null, e, t, n), this.texture.isRenderTargetTexture = !0;
    }
}, Gl = class extends qt {
    constructor(e = 1, t = 1, n = 1, i = {}){
        super(e, t, i), this.isWebGLMultipleRenderTargets = !0;
        let r = this.texture;
        this.texture = [];
        for(let a = 0; a < n; a++)this.texture[a] = r.clone(), this.texture[a].isRenderTargetTexture = !0;
    }
    setSize(e, t, n = 1) {
        if (this.width !== e || this.height !== t || this.depth !== n) {
            this.width = e, this.height = t, this.depth = n;
            for(let i = 0, r = this.texture.length; i < r; i++)this.texture[i].image.width = e, this.texture[i].image.height = t, this.texture[i].image.depth = n;
            this.dispose();
        }
        this.viewport.set(0, 0, e, t), this.scissor.set(0, 0, e, t);
    }
    copy(e) {
        this.dispose(), this.width = e.width, this.height = e.height, this.depth = e.depth, this.scissor.copy(e.scissor), this.scissorTest = e.scissorTest, this.viewport.copy(e.viewport), this.depthBuffer = e.depthBuffer, this.stencilBuffer = e.stencilBuffer, e.depthTexture !== null && (this.depthTexture = e.depthTexture.clone()), this.texture.length = 0;
        for(let t = 0, n = e.texture.length; t < n; t++)this.texture[t] = e.texture[t].clone(), this.texture[t].isRenderTargetTexture = !0;
        return this;
    }
}, Ut = class {
    constructor(e = 0, t = 0, n = 0, i = 1){
        this.isQuaternion = !0, this._x = e, this._y = t, this._z = n, this._w = i;
    }
    static slerpFlat(e, t, n, i, r, a, o) {
        let c = n[i + 0], l = n[i + 1], h = n[i + 2], u = n[i + 3], d = r[a + 0], f = r[a + 1], m = r[a + 2], _ = r[a + 3];
        if (o === 0) {
            e[t + 0] = c, e[t + 1] = l, e[t + 2] = h, e[t + 3] = u;
            return;
        }
        if (o === 1) {
            e[t + 0] = d, e[t + 1] = f, e[t + 2] = m, e[t + 3] = _;
            return;
        }
        if (u !== _ || c !== d || l !== f || h !== m) {
            let g = 1 - o, p = c * d + l * f + h * m + u * _, v = p >= 0 ? 1 : -1, x = 1 - p * p;
            if (x > Number.EPSILON) {
                let b = Math.sqrt(x), w = Math.atan2(b, p * v);
                g = Math.sin(g * w) / b, o = Math.sin(o * w) / b;
            }
            let y = o * v;
            if (c = c * g + d * y, l = l * g + f * y, h = h * g + m * y, u = u * g + _ * y, g === 1 - o) {
                let b = 1 / Math.sqrt(c * c + l * l + h * h + u * u);
                c *= b, l *= b, h *= b, u *= b;
            }
        }
        e[t] = c, e[t + 1] = l, e[t + 2] = h, e[t + 3] = u;
    }
    static multiplyQuaternionsFlat(e, t, n, i, r, a) {
        let o = n[i], c = n[i + 1], l = n[i + 2], h = n[i + 3], u = r[a], d = r[a + 1], f = r[a + 2], m = r[a + 3];
        return e[t] = o * m + h * u + c * f - l * d, e[t + 1] = c * m + h * d + l * u - o * f, e[t + 2] = l * m + h * f + o * d - c * u, e[t + 3] = h * m - o * u - c * d - l * f, e;
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
        let n = e._x, i = e._y, r = e._z, a = e._order, o = Math.cos, c = Math.sin, l = o(n / 2), h = o(i / 2), u = o(r / 2), d = c(n / 2), f = c(i / 2), m = c(r / 2);
        switch(a){
            case "XYZ":
                this._x = d * h * u + l * f * m, this._y = l * f * u - d * h * m, this._z = l * h * m + d * f * u, this._w = l * h * u - d * f * m;
                break;
            case "YXZ":
                this._x = d * h * u + l * f * m, this._y = l * f * u - d * h * m, this._z = l * h * m - d * f * u, this._w = l * h * u + d * f * m;
                break;
            case "ZXY":
                this._x = d * h * u - l * f * m, this._y = l * f * u + d * h * m, this._z = l * h * m + d * f * u, this._w = l * h * u - d * f * m;
                break;
            case "ZYX":
                this._x = d * h * u - l * f * m, this._y = l * f * u + d * h * m, this._z = l * h * m - d * f * u, this._w = l * h * u + d * f * m;
                break;
            case "YZX":
                this._x = d * h * u + l * f * m, this._y = l * f * u + d * h * m, this._z = l * h * m - d * f * u, this._w = l * h * u - d * f * m;
                break;
            case "XZY":
                this._x = d * h * u - l * f * m, this._y = l * f * u - d * h * m, this._z = l * h * m + d * f * u, this._w = l * h * u + d * f * m;
                break;
            default:
                console.warn("THREE.Quaternion: .setFromEuler() encountered an unknown order: " + a);
        }
        return t !== !1 && this._onChangeCallback(), this;
    }
    setFromAxisAngle(e, t) {
        let n = t / 2, i = Math.sin(n);
        return this._x = e.x * i, this._y = e.y * i, this._z = e.z * i, this._w = Math.cos(n), this._onChangeCallback(), this;
    }
    setFromRotationMatrix(e) {
        let t = e.elements, n = t[0], i = t[4], r = t[8], a = t[1], o = t[5], c = t[9], l = t[2], h = t[6], u = t[10], d = n + o + u;
        if (d > 0) {
            let f = .5 / Math.sqrt(d + 1);
            this._w = .25 / f, this._x = (h - c) * f, this._y = (r - l) * f, this._z = (a - i) * f;
        } else if (n > o && n > u) {
            let f = 2 * Math.sqrt(1 + n - o - u);
            this._w = (h - c) / f, this._x = .25 * f, this._y = (i + a) / f, this._z = (r + l) / f;
        } else if (o > u) {
            let f = 2 * Math.sqrt(1 + o - n - u);
            this._w = (r - l) / f, this._x = (i + a) / f, this._y = .25 * f, this._z = (c + h) / f;
        } else {
            let f = 2 * Math.sqrt(1 + u - n - o);
            this._w = (a - i) / f, this._x = (r + l) / f, this._y = (c + h) / f, this._z = .25 * f;
        }
        return this._onChangeCallback(), this;
    }
    setFromUnitVectors(e, t) {
        let n = e.dot(t) + 1;
        return n < Number.EPSILON ? (n = 0, Math.abs(e.x) > Math.abs(e.z) ? (this._x = -e.y, this._y = e.x, this._z = 0, this._w = n) : (this._x = 0, this._y = -e.z, this._z = e.y, this._w = n)) : (this._x = e.y * t.z - e.z * t.y, this._y = e.z * t.x - e.x * t.z, this._z = e.x * t.y - e.y * t.x, this._w = n), this.normalize();
    }
    angleTo(e) {
        return 2 * Math.acos(Math.abs(ct(this.dot(e), -1, 1)));
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
    multiply(e) {
        return this.multiplyQuaternions(this, e);
    }
    premultiply(e) {
        return this.multiplyQuaternions(e, this);
    }
    multiplyQuaternions(e, t) {
        let n = e._x, i = e._y, r = e._z, a = e._w, o = t._x, c = t._y, l = t._z, h = t._w;
        return this._x = n * h + a * o + i * l - r * c, this._y = i * h + a * c + r * o - n * l, this._z = r * h + a * l + n * c - i * o, this._w = a * h - n * o - i * c - r * l, this._onChangeCallback(), this;
    }
    slerp(e, t) {
        if (t === 0) return this;
        if (t === 1) return this.copy(e);
        let n = this._x, i = this._y, r = this._z, a = this._w, o = a * e._w + n * e._x + i * e._y + r * e._z;
        if (o < 0 ? (this._w = -e._w, this._x = -e._x, this._y = -e._y, this._z = -e._z, o = -o) : this.copy(e), o >= 1) return this._w = a, this._x = n, this._y = i, this._z = r, this;
        let c = 1 - o * o;
        if (c <= Number.EPSILON) {
            let f = 1 - t;
            return this._w = f * a + t * this._w, this._x = f * n + t * this._x, this._y = f * i + t * this._y, this._z = f * r + t * this._z, this.normalize(), this._onChangeCallback(), this;
        }
        let l = Math.sqrt(c), h = Math.atan2(l, o), u = Math.sin((1 - t) * h) / l, d = Math.sin(t * h) / l;
        return this._w = a * u + this._w * d, this._x = n * u + this._x * d, this._y = i * u + this._y * d, this._z = r * u + this._z * d, this._onChangeCallback(), this;
    }
    slerpQuaternions(e, t, n) {
        return this.copy(e).slerp(t, n);
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
    toJSON() {
        return this.toArray();
    }
    _onChange(e) {
        return this._onChangeCallback = e, this;
    }
    _onChangeCallback() {}
    *[Symbol.iterator]() {
        yield this._x, yield this._y, yield this._z, yield this._w;
    }
}, A = class s1 {
    constructor(e = 0, t = 0, n = 0){
        s1.prototype.isVector3 = !0, this.x = e, this.y = t, this.z = n;
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
    add(e) {
        return this.x += e.x, this.y += e.y, this.z += e.z, this;
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
    sub(e) {
        return this.x -= e.x, this.y -= e.y, this.z -= e.z, this;
    }
    subScalar(e) {
        return this.x -= e, this.y -= e, this.z -= e, this;
    }
    subVectors(e, t) {
        return this.x = e.x - t.x, this.y = e.y - t.y, this.z = e.z - t.z, this;
    }
    multiply(e) {
        return this.x *= e.x, this.y *= e.y, this.z *= e.z, this;
    }
    multiplyScalar(e) {
        return this.x *= e, this.y *= e, this.z *= e, this;
    }
    multiplyVectors(e, t) {
        return this.x = e.x * t.x, this.y = e.y * t.y, this.z = e.z * t.z, this;
    }
    applyEuler(e) {
        return this.applyQuaternion(Wl.setFromEuler(e));
    }
    applyAxisAngle(e, t) {
        return this.applyQuaternion(Wl.setFromAxisAngle(e, t));
    }
    applyMatrix3(e) {
        let t = this.x, n = this.y, i = this.z, r = e.elements;
        return this.x = r[0] * t + r[3] * n + r[6] * i, this.y = r[1] * t + r[4] * n + r[7] * i, this.z = r[2] * t + r[5] * n + r[8] * i, this;
    }
    applyNormalMatrix(e) {
        return this.applyMatrix3(e).normalize();
    }
    applyMatrix4(e) {
        let t = this.x, n = this.y, i = this.z, r = e.elements, a = 1 / (r[3] * t + r[7] * n + r[11] * i + r[15]);
        return this.x = (r[0] * t + r[4] * n + r[8] * i + r[12]) * a, this.y = (r[1] * t + r[5] * n + r[9] * i + r[13]) * a, this.z = (r[2] * t + r[6] * n + r[10] * i + r[14]) * a, this;
    }
    applyQuaternion(e) {
        let t = this.x, n = this.y, i = this.z, r = e.x, a = e.y, o = e.z, c = e.w, l = c * t + a * i - o * n, h = c * n + o * t - r * i, u = c * i + r * n - a * t, d = -r * t - a * n - o * i;
        return this.x = l * c + d * -r + h * -o - u * -a, this.y = h * c + d * -a + u * -r - l * -o, this.z = u * c + d * -o + l * -a - h * -r, this;
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
        return this.x = Math.trunc(this.x), this.y = Math.trunc(this.y), this.z = Math.trunc(this.z), this;
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
    cross(e) {
        return this.crossVectors(this, e);
    }
    crossVectors(e, t) {
        let n = e.x, i = e.y, r = e.z, a = t.x, o = t.y, c = t.z;
        return this.x = i * c - r * o, this.y = r * a - n * c, this.z = n * o - i * a, this;
    }
    projectOnVector(e) {
        let t = e.lengthSq();
        if (t === 0) return this.set(0, 0, 0);
        let n = e.dot(this) / t;
        return this.copy(e).multiplyScalar(n);
    }
    projectOnPlane(e) {
        return Oa.copy(this).projectOnVector(e), this.sub(Oa);
    }
    reflect(e) {
        return this.sub(Oa.copy(e).multiplyScalar(2 * this.dot(e)));
    }
    angleTo(e) {
        let t = Math.sqrt(this.lengthSq() * e.lengthSq());
        if (t === 0) return Math.PI / 2;
        let n = this.dot(e) / t;
        return Math.acos(ct(n, -1, 1));
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
    setFromEuler(e) {
        return this.x = e._x, this.y = e._y, this.z = e._z, this;
    }
    setFromColor(e) {
        return this.x = e.r, this.y = e.g, this.z = e.b, this;
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
    fromBufferAttribute(e, t) {
        return this.x = e.getX(t), this.y = e.getY(t), this.z = e.getZ(t), this;
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
}, Oa = new A, Wl = new Ut, Qt = class {
    constructor(e = new A(1 / 0, 1 / 0, 1 / 0), t = new A(-1 / 0, -1 / 0, -1 / 0)){
        this.isBox3 = !0, this.min = e, this.max = t;
    }
    set(e, t) {
        return this.min.copy(e), this.max.copy(t), this;
    }
    setFromArray(e) {
        this.makeEmpty();
        for(let t = 0, n = e.length; t < n; t += 3)this.expandByPoint(cn.fromArray(e, t));
        return this;
    }
    setFromBufferAttribute(e) {
        this.makeEmpty();
        for(let t = 0, n = e.count; t < n; t++)this.expandByPoint(cn.fromBufferAttribute(e, t));
        return this;
    }
    setFromPoints(e) {
        this.makeEmpty();
        for(let t = 0, n = e.length; t < n; t++)this.expandByPoint(e[t]);
        return this;
    }
    setFromCenterAndSize(e, t) {
        let n = cn.copy(t).multiplyScalar(.5);
        return this.min.copy(e).sub(n), this.max.copy(e).add(n), this;
    }
    setFromObject(e, t = !1) {
        return this.makeEmpty(), this.expandByObject(e, t);
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
    expandByObject(e, t = !1) {
        if (e.updateWorldMatrix(!1, !1), e.boundingBox !== void 0) e.boundingBox === null && e.computeBoundingBox(), _i.copy(e.boundingBox), _i.applyMatrix4(e.matrixWorld), this.union(_i);
        else {
            let i = e.geometry;
            if (i !== void 0) if (t && i.attributes !== void 0 && i.attributes.position !== void 0) {
                let r = i.attributes.position;
                for(let a = 0, o = r.count; a < o; a++)cn.fromBufferAttribute(r, a).applyMatrix4(e.matrixWorld), this.expandByPoint(cn);
            } else i.boundingBox === null && i.computeBoundingBox(), _i.copy(i.boundingBox), _i.applyMatrix4(e.matrixWorld), this.union(_i);
        }
        let n = e.children;
        for(let i = 0, r = n.length; i < r; i++)this.expandByObject(n[i], t);
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
        return this.clampPoint(e.center, cn), cn.distanceToSquared(e.center) <= e.radius * e.radius;
    }
    intersectsPlane(e) {
        let t, n;
        return e.normal.x > 0 ? (t = e.normal.x * this.min.x, n = e.normal.x * this.max.x) : (t = e.normal.x * this.max.x, n = e.normal.x * this.min.x), e.normal.y > 0 ? (t += e.normal.y * this.min.y, n += e.normal.y * this.max.y) : (t += e.normal.y * this.max.y, n += e.normal.y * this.min.y), e.normal.z > 0 ? (t += e.normal.z * this.min.z, n += e.normal.z * this.max.z) : (t += e.normal.z * this.max.z, n += e.normal.z * this.min.z), t <= -e.constant && n >= -e.constant;
    }
    intersectsTriangle(e) {
        if (this.isEmpty()) return !1;
        this.getCenter(cs), Ws.subVectors(this.max, cs), xi.subVectors(e.a, cs), vi.subVectors(e.b, cs), yi.subVectors(e.c, cs), Tn.subVectors(vi, xi), wn.subVectors(yi, vi), Wn.subVectors(xi, yi);
        let t = [
            0,
            -Tn.z,
            Tn.y,
            0,
            -wn.z,
            wn.y,
            0,
            -Wn.z,
            Wn.y,
            Tn.z,
            0,
            -Tn.x,
            wn.z,
            0,
            -wn.x,
            Wn.z,
            0,
            -Wn.x,
            -Tn.y,
            Tn.x,
            0,
            -wn.y,
            wn.x,
            0,
            -Wn.y,
            Wn.x,
            0
        ];
        return !Fa(t, xi, vi, yi, Ws) || (t = [
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
        ], !Fa(t, xi, vi, yi, Ws)) ? !1 : (Xs.crossVectors(Tn, wn), t = [
            Xs.x,
            Xs.y,
            Xs.z
        ], Fa(t, xi, vi, yi, Ws));
    }
    clampPoint(e, t) {
        return t.copy(e).clamp(this.min, this.max);
    }
    distanceToPoint(e) {
        return this.clampPoint(e, cn).distanceTo(e);
    }
    getBoundingSphere(e) {
        return this.isEmpty() ? e.makeEmpty() : (this.getCenter(e.center), e.radius = this.getSize(cn).length() * .5), e;
    }
    intersect(e) {
        return this.min.max(e.min), this.max.min(e.max), this.isEmpty() && this.makeEmpty(), this;
    }
    union(e) {
        return this.min.min(e.min), this.max.max(e.max), this;
    }
    applyMatrix4(e) {
        return this.isEmpty() ? this : (on[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(e), on[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(e), on[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(e), on[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(e), on[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(e), on[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(e), on[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(e), on[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(e), this.setFromPoints(on), this);
    }
    translate(e) {
        return this.min.add(e), this.max.add(e), this;
    }
    equals(e) {
        return e.min.equals(this.min) && e.max.equals(this.max);
    }
}, on = [
    new A,
    new A,
    new A,
    new A,
    new A,
    new A,
    new A,
    new A
], cn = new A, _i = new Qt, xi = new A, vi = new A, yi = new A, Tn = new A, wn = new A, Wn = new A, cs = new A, Ws = new A, Xs = new A, Xn = new A;
function Fa(s1, e, t, n, i) {
    for(let r = 0, a = s1.length - 3; r <= a; r += 3){
        Xn.fromArray(s1, r);
        let o = i.x * Math.abs(Xn.x) + i.y * Math.abs(Xn.y) + i.z * Math.abs(Xn.z), c = e.dot(Xn), l = t.dot(Xn), h = n.dot(Xn);
        if (Math.max(-Math.max(c, l, h), Math.min(c, l, h)) > o) return !1;
    }
    return !0;
}
var rp = new Qt, ls = new A, Ba = new A, Yt = class {
    constructor(e = new A, t = -1){
        this.center = e, this.radius = t;
    }
    set(e, t) {
        return this.center.copy(e), this.radius = t, this;
    }
    setFromPoints(e, t) {
        let n = this.center;
        t !== void 0 ? n.copy(t) : rp.setFromPoints(e).getCenter(n);
        let i = 0;
        for(let r = 0, a = e.length; r < a; r++)i = Math.max(i, n.distanceToSquared(e[r]));
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
        if (this.isEmpty()) return this.center.copy(e), this.radius = 0, this;
        ls.subVectors(e, this.center);
        let t = ls.lengthSq();
        if (t > this.radius * this.radius) {
            let n = Math.sqrt(t), i = (n - this.radius) * .5;
            this.center.addScaledVector(ls, i / n), this.radius += i;
        }
        return this;
    }
    union(e) {
        return e.isEmpty() ? this : this.isEmpty() ? (this.copy(e), this) : (this.center.equals(e.center) === !0 ? this.radius = Math.max(this.radius, e.radius) : (Ba.subVectors(e.center, this.center).setLength(e.radius), this.expandByPoint(ls.copy(e.center).add(Ba)), this.expandByPoint(ls.copy(e.center).sub(Ba))), this);
    }
    equals(e) {
        return e.center.equals(this.center) && e.radius === this.radius;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, ln = new A, za = new A, qs = new A, An = new A, Va = new A, Ys = new A, ka = new A, hi = class {
    constructor(e = new A, t = new A(0, 0, -1)){
        this.origin = e, this.direction = t;
    }
    set(e, t) {
        return this.origin.copy(e), this.direction.copy(t), this;
    }
    copy(e) {
        return this.origin.copy(e.origin), this.direction.copy(e.direction), this;
    }
    at(e, t) {
        return t.copy(this.origin).addScaledVector(this.direction, e);
    }
    lookAt(e) {
        return this.direction.copy(e).sub(this.origin).normalize(), this;
    }
    recast(e) {
        return this.origin.copy(this.at(e, ln)), this;
    }
    closestPointToPoint(e, t) {
        t.subVectors(e, this.origin);
        let n = t.dot(this.direction);
        return n < 0 ? t.copy(this.origin) : t.copy(this.origin).addScaledVector(this.direction, n);
    }
    distanceToPoint(e) {
        return Math.sqrt(this.distanceSqToPoint(e));
    }
    distanceSqToPoint(e) {
        let t = ln.subVectors(e, this.origin).dot(this.direction);
        return t < 0 ? this.origin.distanceToSquared(e) : (ln.copy(this.origin).addScaledVector(this.direction, t), ln.distanceToSquared(e));
    }
    distanceSqToSegment(e, t, n, i) {
        za.copy(e).add(t).multiplyScalar(.5), qs.copy(t).sub(e).normalize(), An.copy(this.origin).sub(za);
        let r = e.distanceTo(t) * .5, a = -this.direction.dot(qs), o = An.dot(this.direction), c = -An.dot(qs), l = An.lengthSq(), h = Math.abs(1 - a * a), u, d, f, m;
        if (h > 0) if (u = a * c - o, d = a * o - c, m = r * h, u >= 0) if (d >= -m) if (d <= m) {
            let _ = 1 / h;
            u *= _, d *= _, f = u * (u + a * d + 2 * o) + d * (a * u + d + 2 * c) + l;
        } else d = r, u = Math.max(0, -(a * d + o)), f = -u * u + d * (d + 2 * c) + l;
        else d = -r, u = Math.max(0, -(a * d + o)), f = -u * u + d * (d + 2 * c) + l;
        else d <= -m ? (u = Math.max(0, -(-a * r + o)), d = u > 0 ? -r : Math.min(Math.max(-r, -c), r), f = -u * u + d * (d + 2 * c) + l) : d <= m ? (u = 0, d = Math.min(Math.max(-r, -c), r), f = d * (d + 2 * c) + l) : (u = Math.max(0, -(a * r + o)), d = u > 0 ? r : Math.min(Math.max(-r, -c), r), f = -u * u + d * (d + 2 * c) + l);
        else d = a > 0 ? -r : r, u = Math.max(0, -(a * d + o)), f = -u * u + d * (d + 2 * c) + l;
        return n && n.copy(this.origin).addScaledVector(this.direction, u), i && i.copy(za).addScaledVector(qs, d), f;
    }
    intersectSphere(e, t) {
        ln.subVectors(e.center, this.origin);
        let n = ln.dot(this.direction), i = ln.dot(ln) - n * n, r = e.radius * e.radius;
        if (i > r) return null;
        let a = Math.sqrt(r - i), o = n - a, c = n + a;
        return c < 0 ? null : o < 0 ? this.at(c, t) : this.at(o, t);
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
        let n, i, r, a, o, c, l = 1 / this.direction.x, h = 1 / this.direction.y, u = 1 / this.direction.z, d = this.origin;
        return l >= 0 ? (n = (e.min.x - d.x) * l, i = (e.max.x - d.x) * l) : (n = (e.max.x - d.x) * l, i = (e.min.x - d.x) * l), h >= 0 ? (r = (e.min.y - d.y) * h, a = (e.max.y - d.y) * h) : (r = (e.max.y - d.y) * h, a = (e.min.y - d.y) * h), n > a || r > i || ((r > n || isNaN(n)) && (n = r), (a < i || isNaN(i)) && (i = a), u >= 0 ? (o = (e.min.z - d.z) * u, c = (e.max.z - d.z) * u) : (o = (e.max.z - d.z) * u, c = (e.min.z - d.z) * u), n > c || o > i) || ((o > n || n !== n) && (n = o), (c < i || i !== i) && (i = c), i < 0) ? null : this.at(n >= 0 ? n : i, t);
    }
    intersectsBox(e) {
        return this.intersectBox(e, ln) !== null;
    }
    intersectTriangle(e, t, n, i, r) {
        Va.subVectors(t, e), Ys.subVectors(n, e), ka.crossVectors(Va, Ys);
        let a = this.direction.dot(ka), o;
        if (a > 0) {
            if (i) return null;
            o = 1;
        } else if (a < 0) o = -1, a = -a;
        else return null;
        An.subVectors(this.origin, e);
        let c = o * this.direction.dot(Ys.crossVectors(An, Ys));
        if (c < 0) return null;
        let l = o * this.direction.dot(Va.cross(An));
        if (l < 0 || c + l > a) return null;
        let h = -o * An.dot(ka);
        return h < 0 ? null : this.at(h / a, r);
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
}, ze = class s1 {
    constructor(e, t, n, i, r, a, o, c, l, h, u, d, f, m, _, g){
        s1.prototype.isMatrix4 = !0, this.elements = [
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
        ], e !== void 0 && this.set(e, t, n, i, r, a, o, c, l, h, u, d, f, m, _, g);
    }
    set(e, t, n, i, r, a, o, c, l, h, u, d, f, m, _, g) {
        let p = this.elements;
        return p[0] = e, p[4] = t, p[8] = n, p[12] = i, p[1] = r, p[5] = a, p[9] = o, p[13] = c, p[2] = l, p[6] = h, p[10] = u, p[14] = d, p[3] = f, p[7] = m, p[11] = _, p[15] = g, this;
    }
    identity() {
        return this.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), this;
    }
    clone() {
        return new s1().fromArray(this.elements);
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
        let t = this.elements, n = e.elements, i = 1 / Mi.setFromMatrixColumn(e, 0).length(), r = 1 / Mi.setFromMatrixColumn(e, 1).length(), a = 1 / Mi.setFromMatrixColumn(e, 2).length();
        return t[0] = n[0] * i, t[1] = n[1] * i, t[2] = n[2] * i, t[3] = 0, t[4] = n[4] * r, t[5] = n[5] * r, t[6] = n[6] * r, t[7] = 0, t[8] = n[8] * a, t[9] = n[9] * a, t[10] = n[10] * a, t[11] = 0, t[12] = 0, t[13] = 0, t[14] = 0, t[15] = 1, this;
    }
    makeRotationFromEuler(e) {
        let t = this.elements, n = e.x, i = e.y, r = e.z, a = Math.cos(n), o = Math.sin(n), c = Math.cos(i), l = Math.sin(i), h = Math.cos(r), u = Math.sin(r);
        if (e.order === "XYZ") {
            let d = a * h, f = a * u, m = o * h, _ = o * u;
            t[0] = c * h, t[4] = -c * u, t[8] = l, t[1] = f + m * l, t[5] = d - _ * l, t[9] = -o * c, t[2] = _ - d * l, t[6] = m + f * l, t[10] = a * c;
        } else if (e.order === "YXZ") {
            let d = c * h, f = c * u, m = l * h, _ = l * u;
            t[0] = d + _ * o, t[4] = m * o - f, t[8] = a * l, t[1] = a * u, t[5] = a * h, t[9] = -o, t[2] = f * o - m, t[6] = _ + d * o, t[10] = a * c;
        } else if (e.order === "ZXY") {
            let d = c * h, f = c * u, m = l * h, _ = l * u;
            t[0] = d - _ * o, t[4] = -a * u, t[8] = m + f * o, t[1] = f + m * o, t[5] = a * h, t[9] = _ - d * o, t[2] = -a * l, t[6] = o, t[10] = a * c;
        } else if (e.order === "ZYX") {
            let d = a * h, f = a * u, m = o * h, _ = o * u;
            t[0] = c * h, t[4] = m * l - f, t[8] = d * l + _, t[1] = c * u, t[5] = _ * l + d, t[9] = f * l - m, t[2] = -l, t[6] = o * c, t[10] = a * c;
        } else if (e.order === "YZX") {
            let d = a * c, f = a * l, m = o * c, _ = o * l;
            t[0] = c * h, t[4] = _ - d * u, t[8] = m * u + f, t[1] = u, t[5] = a * h, t[9] = -o * h, t[2] = -l * h, t[6] = f * u + m, t[10] = d - _ * u;
        } else if (e.order === "XZY") {
            let d = a * c, f = a * l, m = o * c, _ = o * l;
            t[0] = c * h, t[4] = -u, t[8] = l * h, t[1] = d * u + _, t[5] = a * h, t[9] = f * u - m, t[2] = m * u - f, t[6] = o * h, t[10] = _ * u + d;
        }
        return t[3] = 0, t[7] = 0, t[11] = 0, t[12] = 0, t[13] = 0, t[14] = 0, t[15] = 1, this;
    }
    makeRotationFromQuaternion(e) {
        return this.compose(ap, e, op);
    }
    lookAt(e, t, n) {
        let i = this.elements;
        return zt.subVectors(e, t), zt.lengthSq() === 0 && (zt.z = 1), zt.normalize(), Rn.crossVectors(n, zt), Rn.lengthSq() === 0 && (Math.abs(n.z) === 1 ? zt.x += 1e-4 : zt.z += 1e-4, zt.normalize(), Rn.crossVectors(n, zt)), Rn.normalize(), Zs.crossVectors(zt, Rn), i[0] = Rn.x, i[4] = Zs.x, i[8] = zt.x, i[1] = Rn.y, i[5] = Zs.y, i[9] = zt.y, i[2] = Rn.z, i[6] = Zs.z, i[10] = zt.z, this;
    }
    multiply(e) {
        return this.multiplyMatrices(this, e);
    }
    premultiply(e) {
        return this.multiplyMatrices(e, this);
    }
    multiplyMatrices(e, t) {
        let n = e.elements, i = t.elements, r = this.elements, a = n[0], o = n[4], c = n[8], l = n[12], h = n[1], u = n[5], d = n[9], f = n[13], m = n[2], _ = n[6], g = n[10], p = n[14], v = n[3], x = n[7], y = n[11], b = n[15], w = i[0], R = i[4], I = i[8], M = i[12], T = i[1], O = i[5], Y = i[9], $ = i[13], U = i[2], z = i[6], q = i[10], H = i[14], ne = i[3], W = i[7], K = i[11], D = i[15];
        return r[0] = a * w + o * T + c * U + l * ne, r[4] = a * R + o * O + c * z + l * W, r[8] = a * I + o * Y + c * q + l * K, r[12] = a * M + o * $ + c * H + l * D, r[1] = h * w + u * T + d * U + f * ne, r[5] = h * R + u * O + d * z + f * W, r[9] = h * I + u * Y + d * q + f * K, r[13] = h * M + u * $ + d * H + f * D, r[2] = m * w + _ * T + g * U + p * ne, r[6] = m * R + _ * O + g * z + p * W, r[10] = m * I + _ * Y + g * q + p * K, r[14] = m * M + _ * $ + g * H + p * D, r[3] = v * w + x * T + y * U + b * ne, r[7] = v * R + x * O + y * z + b * W, r[11] = v * I + x * Y + y * q + b * K, r[15] = v * M + x * $ + y * H + b * D, this;
    }
    multiplyScalar(e) {
        let t = this.elements;
        return t[0] *= e, t[4] *= e, t[8] *= e, t[12] *= e, t[1] *= e, t[5] *= e, t[9] *= e, t[13] *= e, t[2] *= e, t[6] *= e, t[10] *= e, t[14] *= e, t[3] *= e, t[7] *= e, t[11] *= e, t[15] *= e, this;
    }
    determinant() {
        let e = this.elements, t = e[0], n = e[4], i = e[8], r = e[12], a = e[1], o = e[5], c = e[9], l = e[13], h = e[2], u = e[6], d = e[10], f = e[14], m = e[3], _ = e[7], g = e[11], p = e[15];
        return m * (+r * c * u - i * l * u - r * o * d + n * l * d + i * o * f - n * c * f) + _ * (+t * c * f - t * l * d + r * a * d - i * a * f + i * l * h - r * c * h) + g * (+t * l * u - t * o * f - r * a * u + n * a * f + r * o * h - n * l * h) + p * (-i * o * h - t * c * u + t * o * d + i * a * u - n * a * d + n * c * h);
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
        let e = this.elements, t = e[0], n = e[1], i = e[2], r = e[3], a = e[4], o = e[5], c = e[6], l = e[7], h = e[8], u = e[9], d = e[10], f = e[11], m = e[12], _ = e[13], g = e[14], p = e[15], v = u * g * l - _ * d * l + _ * c * f - o * g * f - u * c * p + o * d * p, x = m * d * l - h * g * l - m * c * f + a * g * f + h * c * p - a * d * p, y = h * _ * l - m * u * l + m * o * f - a * _ * f - h * o * p + a * u * p, b = m * u * c - h * _ * c - m * o * d + a * _ * d + h * o * g - a * u * g, w = t * v + n * x + i * y + r * b;
        if (w === 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        let R = 1 / w;
        return e[0] = v * R, e[1] = (_ * d * r - u * g * r - _ * i * f + n * g * f + u * i * p - n * d * p) * R, e[2] = (o * g * r - _ * c * r + _ * i * l - n * g * l - o * i * p + n * c * p) * R, e[3] = (u * c * r - o * d * r - u * i * l + n * d * l + o * i * f - n * c * f) * R, e[4] = x * R, e[5] = (h * g * r - m * d * r + m * i * f - t * g * f - h * i * p + t * d * p) * R, e[6] = (m * c * r - a * g * r - m * i * l + t * g * l + a * i * p - t * c * p) * R, e[7] = (a * d * r - h * c * r + h * i * l - t * d * l - a * i * f + t * c * f) * R, e[8] = y * R, e[9] = (m * u * r - h * _ * r - m * n * f + t * _ * f + h * n * p - t * u * p) * R, e[10] = (a * _ * r - m * o * r + m * n * l - t * _ * l - a * n * p + t * o * p) * R, e[11] = (h * o * r - a * u * r - h * n * l + t * u * l + a * n * f - t * o * f) * R, e[12] = b * R, e[13] = (h * _ * i - m * u * i + m * n * d - t * _ * d - h * n * g + t * u * g) * R, e[14] = (m * o * i - a * _ * i - m * n * c + t * _ * c + a * n * g - t * o * g) * R, e[15] = (a * u * i - h * o * i + h * n * c - t * u * c - a * n * d + t * o * d) * R, this;
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
        return e.isVector3 ? this.set(1, 0, 0, e.x, 0, 1, 0, e.y, 0, 0, 1, e.z, 0, 0, 0, 1) : this.set(1, 0, 0, e, 0, 1, 0, t, 0, 0, 1, n, 0, 0, 0, 1), this;
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
        let n = Math.cos(t), i = Math.sin(t), r = 1 - n, a = e.x, o = e.y, c = e.z, l = r * a, h = r * o;
        return this.set(l * a + n, l * o - i * c, l * c + i * o, 0, l * o + i * c, h * o + n, h * c - i * a, 0, l * c - i * o, h * c + i * a, r * c * c + n, 0, 0, 0, 0, 1), this;
    }
    makeScale(e, t, n) {
        return this.set(e, 0, 0, 0, 0, t, 0, 0, 0, 0, n, 0, 0, 0, 0, 1), this;
    }
    makeShear(e, t, n, i, r, a) {
        return this.set(1, n, r, 0, e, 1, a, 0, t, i, 1, 0, 0, 0, 0, 1), this;
    }
    compose(e, t, n) {
        let i = this.elements, r = t._x, a = t._y, o = t._z, c = t._w, l = r + r, h = a + a, u = o + o, d = r * l, f = r * h, m = r * u, _ = a * h, g = a * u, p = o * u, v = c * l, x = c * h, y = c * u, b = n.x, w = n.y, R = n.z;
        return i[0] = (1 - (_ + p)) * b, i[1] = (f + y) * b, i[2] = (m - x) * b, i[3] = 0, i[4] = (f - y) * w, i[5] = (1 - (d + p)) * w, i[6] = (g + v) * w, i[7] = 0, i[8] = (m + x) * R, i[9] = (g - v) * R, i[10] = (1 - (d + _)) * R, i[11] = 0, i[12] = e.x, i[13] = e.y, i[14] = e.z, i[15] = 1, this;
    }
    decompose(e, t, n) {
        let i = this.elements, r = Mi.set(i[0], i[1], i[2]).length(), a = Mi.set(i[4], i[5], i[6]).length(), o = Mi.set(i[8], i[9], i[10]).length();
        this.determinant() < 0 && (r = -r), e.x = i[12], e.y = i[13], e.z = i[14], $t.copy(this);
        let l = 1 / r, h = 1 / a, u = 1 / o;
        return $t.elements[0] *= l, $t.elements[1] *= l, $t.elements[2] *= l, $t.elements[4] *= h, $t.elements[5] *= h, $t.elements[6] *= h, $t.elements[8] *= u, $t.elements[9] *= u, $t.elements[10] *= u, t.setFromRotationMatrix($t), n.x = r, n.y = a, n.z = o, this;
    }
    makePerspective(e, t, n, i, r, a, o = vn) {
        let c = this.elements, l = 2 * r / (t - e), h = 2 * r / (n - i), u = (t + e) / (t - e), d = (n + i) / (n - i), f, m;
        if (o === vn) f = -(a + r) / (a - r), m = -2 * a * r / (a - r);
        else if (o === Gr) f = -a / (a - r), m = -a * r / (a - r);
        else throw new Error("THREE.Matrix4.makePerspective(): Invalid coordinate system: " + o);
        return c[0] = l, c[4] = 0, c[8] = u, c[12] = 0, c[1] = 0, c[5] = h, c[9] = d, c[13] = 0, c[2] = 0, c[6] = 0, c[10] = f, c[14] = m, c[3] = 0, c[7] = 0, c[11] = -1, c[15] = 0, this;
    }
    makeOrthographic(e, t, n, i, r, a, o = vn) {
        let c = this.elements, l = 1 / (t - e), h = 1 / (n - i), u = 1 / (a - r), d = (t + e) * l, f = (n + i) * h, m, _;
        if (o === vn) m = (a + r) * u, _ = -2 * u;
        else if (o === Gr) m = r * u, _ = -1 * u;
        else throw new Error("THREE.Matrix4.makeOrthographic(): Invalid coordinate system: " + o);
        return c[0] = 2 * l, c[4] = 0, c[8] = 0, c[12] = -d, c[1] = 0, c[5] = 2 * h, c[9] = 0, c[13] = -f, c[2] = 0, c[6] = 0, c[10] = _, c[14] = -m, c[3] = 0, c[7] = 0, c[11] = 0, c[15] = 1, this;
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
}, Mi = new A, $t = new ze, ap = new A(0, 0, 0), op = new A(1, 1, 1), Rn = new A, Zs = new A, zt = new A, Xl = new ze, ql = new Ut, Yr = class s1 {
    constructor(e = 0, t = 0, n = 0, i = s1.DEFAULT_ORDER){
        this.isEuler = !0, this._x = e, this._y = t, this._z = n, this._order = i;
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
        let i = e.elements, r = i[0], a = i[4], o = i[8], c = i[1], l = i[5], h = i[9], u = i[2], d = i[6], f = i[10];
        switch(t){
            case "XYZ":
                this._y = Math.asin(ct(o, -1, 1)), Math.abs(o) < .9999999 ? (this._x = Math.atan2(-h, f), this._z = Math.atan2(-a, r)) : (this._x = Math.atan2(d, l), this._z = 0);
                break;
            case "YXZ":
                this._x = Math.asin(-ct(h, -1, 1)), Math.abs(h) < .9999999 ? (this._y = Math.atan2(o, f), this._z = Math.atan2(c, l)) : (this._y = Math.atan2(-u, r), this._z = 0);
                break;
            case "ZXY":
                this._x = Math.asin(ct(d, -1, 1)), Math.abs(d) < .9999999 ? (this._y = Math.atan2(-u, f), this._z = Math.atan2(-a, l)) : (this._y = 0, this._z = Math.atan2(c, r));
                break;
            case "ZYX":
                this._y = Math.asin(-ct(u, -1, 1)), Math.abs(u) < .9999999 ? (this._x = Math.atan2(d, f), this._z = Math.atan2(c, r)) : (this._x = 0, this._z = Math.atan2(-a, l));
                break;
            case "YZX":
                this._z = Math.asin(ct(c, -1, 1)), Math.abs(c) < .9999999 ? (this._x = Math.atan2(-h, l), this._y = Math.atan2(-u, r)) : (this._x = 0, this._y = Math.atan2(o, f));
                break;
            case "XZY":
                this._z = Math.asin(-ct(a, -1, 1)), Math.abs(a) < .9999999 ? (this._x = Math.atan2(d, l), this._y = Math.atan2(o, r)) : (this._x = Math.atan2(-h, f), this._y = 0);
                break;
            default:
                console.warn("THREE.Euler: .setFromRotationMatrix() encountered an unknown order: " + t);
        }
        return this._order = t, n === !0 && this._onChangeCallback(), this;
    }
    setFromQuaternion(e, t, n) {
        return Xl.makeRotationFromQuaternion(e), this.setFromRotationMatrix(Xl, t, n);
    }
    setFromVector3(e, t = this._order) {
        return this.set(e.x, e.y, e.z, t);
    }
    reorder(e) {
        return ql.setFromEuler(this), this.setFromQuaternion(ql, e);
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
    _onChange(e) {
        return this._onChangeCallback = e, this;
    }
    _onChangeCallback() {}
    *[Symbol.iterator]() {
        yield this._x, yield this._y, yield this._z, yield this._order;
    }
};
Yr.DEFAULT_ORDER = "XYZ";
var Rs = class {
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
}, cp = 0, Yl = new A, Si = new Ut, hn = new ze, Js = new A, hs = new A, lp = new A, hp = new Ut, Zl = new A(1, 0, 0), Jl = new A(0, 1, 0), $l = new A(0, 0, 1), up = {
    type: "added"
}, dp = {
    type: "removed"
}, Je = class s1 extends sn {
    constructor(){
        super(), this.isObject3D = !0, Object.defineProperty(this, "id", {
            value: cp++
        }), this.uuid = kt(), this.name = "", this.type = "Object3D", this.parent = null, this.children = [], this.up = s1.DEFAULT_UP.clone();
        let e = new A, t = new Yr, n = new Ut, i = new A(1, 1, 1);
        function r() {
            n.setFromEuler(t, !1);
        }
        function a() {
            t.setFromQuaternion(n, void 0, !1);
        }
        t._onChange(r), n._onChange(a), Object.defineProperties(this, {
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
                value: new ze
            },
            normalMatrix: {
                value: new He
            }
        }), this.matrix = new ze, this.matrixWorld = new ze, this.matrixAutoUpdate = s1.DEFAULT_MATRIX_AUTO_UPDATE, this.matrixWorldNeedsUpdate = !1, this.matrixWorldAutoUpdate = s1.DEFAULT_MATRIX_WORLD_AUTO_UPDATE, this.layers = new Rs, this.visible = !0, this.castShadow = !1, this.receiveShadow = !1, this.frustumCulled = !0, this.renderOrder = 0, this.animations = [], this.userData = {};
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
        return Si.setFromAxisAngle(e, t), this.quaternion.multiply(Si), this;
    }
    rotateOnWorldAxis(e, t) {
        return Si.setFromAxisAngle(e, t), this.quaternion.premultiply(Si), this;
    }
    rotateX(e) {
        return this.rotateOnAxis(Zl, e);
    }
    rotateY(e) {
        return this.rotateOnAxis(Jl, e);
    }
    rotateZ(e) {
        return this.rotateOnAxis($l, e);
    }
    translateOnAxis(e, t) {
        return Yl.copy(e).applyQuaternion(this.quaternion), this.position.add(Yl.multiplyScalar(t)), this;
    }
    translateX(e) {
        return this.translateOnAxis(Zl, e);
    }
    translateY(e) {
        return this.translateOnAxis(Jl, e);
    }
    translateZ(e) {
        return this.translateOnAxis($l, e);
    }
    localToWorld(e) {
        return this.updateWorldMatrix(!0, !1), e.applyMatrix4(this.matrixWorld);
    }
    worldToLocal(e) {
        return this.updateWorldMatrix(!0, !1), e.applyMatrix4(hn.copy(this.matrixWorld).invert());
    }
    lookAt(e, t, n) {
        e.isVector3 ? Js.copy(e) : Js.set(e, t, n);
        let i = this.parent;
        this.updateWorldMatrix(!0, !1), hs.setFromMatrixPosition(this.matrixWorld), this.isCamera || this.isLight ? hn.lookAt(hs, Js, this.up) : hn.lookAt(Js, hs, this.up), this.quaternion.setFromRotationMatrix(hn), i && (hn.extractRotation(i.matrixWorld), Si.setFromRotationMatrix(hn), this.quaternion.premultiply(Si.invert()));
    }
    add(e) {
        if (arguments.length > 1) {
            for(let t = 0; t < arguments.length; t++)this.add(arguments[t]);
            return this;
        }
        return e === this ? (console.error("THREE.Object3D.add: object can't be added as a child of itself.", e), this) : (e && e.isObject3D ? (e.parent !== null && e.parent.remove(e), e.parent = this, this.children.push(e), e.dispatchEvent(up)) : console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.", e), this);
    }
    remove(e) {
        if (arguments.length > 1) {
            for(let n = 0; n < arguments.length; n++)this.remove(arguments[n]);
            return this;
        }
        let t = this.children.indexOf(e);
        return t !== -1 && (e.parent = null, this.children.splice(t, 1), e.dispatchEvent(dp)), this;
    }
    removeFromParent() {
        let e = this.parent;
        return e !== null && e.remove(this), this;
    }
    clear() {
        return this.remove(...this.children);
    }
    attach(e) {
        return this.updateWorldMatrix(!0, !1), hn.copy(this.matrixWorld).invert(), e.parent !== null && (e.parent.updateWorldMatrix(!0, !1), hn.multiply(e.parent.matrixWorld)), e.applyMatrix4(hn), this.add(e), e.updateWorldMatrix(!1, !0), this;
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
            let a = this.children[n].getObjectByProperty(e, t);
            if (a !== void 0) return a;
        }
    }
    getObjectsByProperty(e, t) {
        let n = [];
        this[e] === t && n.push(this);
        for(let i = 0, r = this.children.length; i < r; i++){
            let a = this.children[i].getObjectsByProperty(e, t);
            a.length > 0 && (n = n.concat(a));
        }
        return n;
    }
    getWorldPosition(e) {
        return this.updateWorldMatrix(!0, !1), e.setFromMatrixPosition(this.matrixWorld);
    }
    getWorldQuaternion(e) {
        return this.updateWorldMatrix(!0, !1), this.matrixWorld.decompose(hs, e, lp), e;
    }
    getWorldScale(e) {
        return this.updateWorldMatrix(!0, !1), this.matrixWorld.decompose(hs, hp, e), e;
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
        for(let n = 0, i = t.length; n < i; n++){
            let r = t[n];
            (r.matrixWorldAutoUpdate === !0 || e === !0) && r.updateMatrixWorld(e);
        }
    }
    updateWorldMatrix(e, t) {
        let n = this.parent;
        if (e === !0 && n !== null && n.matrixWorldAutoUpdate === !0 && n.updateWorldMatrix(!0, !1), this.matrixAutoUpdate && this.updateMatrix(), this.parent === null ? this.matrixWorld.copy(this.matrix) : this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix), t === !0) {
            let i = this.children;
            for(let r = 0, a = i.length; r < a; r++){
                let o = i[r];
                o.matrixWorldAutoUpdate === !0 && o.updateWorldMatrix(!1, !0);
            }
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
            animations: {},
            nodes: {}
        }, n.metadata = {
            version: 4.6,
            type: "Object",
            generator: "Object3D.toJSON"
        });
        let i = {};
        i.uuid = this.uuid, i.type = this.type, this.name !== "" && (i.name = this.name), this.castShadow === !0 && (i.castShadow = !0), this.receiveShadow === !0 && (i.receiveShadow = !0), this.visible === !1 && (i.visible = !1), this.frustumCulled === !1 && (i.frustumCulled = !1), this.renderOrder !== 0 && (i.renderOrder = this.renderOrder), Object.keys(this.userData).length > 0 && (i.userData = this.userData), i.layers = this.layers.mask, i.matrix = this.matrix.toArray(), i.up = this.up.toArray(), this.matrixAutoUpdate === !1 && (i.matrixAutoUpdate = !1), this.isInstancedMesh && (i.type = "InstancedMesh", i.count = this.count, i.instanceMatrix = this.instanceMatrix.toJSON(), this.instanceColor !== null && (i.instanceColor = this.instanceColor.toJSON()));
        function r(o, c) {
            return o[c.uuid] === void 0 && (o[c.uuid] = c.toJSON(e)), c.uuid;
        }
        if (this.isScene) this.background && (this.background.isColor ? i.background = this.background.toJSON() : this.background.isTexture && (i.background = this.background.toJSON(e).uuid)), this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== !0 && (i.environment = this.environment.toJSON(e).uuid);
        else if (this.isMesh || this.isLine || this.isPoints) {
            i.geometry = r(e.geometries, this.geometry);
            let o = this.geometry.parameters;
            if (o !== void 0 && o.shapes !== void 0) {
                let c = o.shapes;
                if (Array.isArray(c)) for(let l = 0, h = c.length; l < h; l++){
                    let u = c[l];
                    r(e.shapes, u);
                }
                else r(e.shapes, c);
            }
        }
        if (this.isSkinnedMesh && (i.bindMode = this.bindMode, i.bindMatrix = this.bindMatrix.toArray(), this.skeleton !== void 0 && (r(e.skeletons, this.skeleton), i.skeleton = this.skeleton.uuid)), this.material !== void 0) if (Array.isArray(this.material)) {
            let o = [];
            for(let c = 0, l = this.material.length; c < l; c++)o.push(r(e.materials, this.material[c]));
            i.material = o;
        } else i.material = r(e.materials, this.material);
        if (this.children.length > 0) {
            i.children = [];
            for(let o = 0; o < this.children.length; o++)i.children.push(this.children[o].toJSON(e).object);
        }
        if (this.animations.length > 0) {
            i.animations = [];
            for(let o = 0; o < this.animations.length; o++){
                let c = this.animations[o];
                i.animations.push(r(e.animations, c));
            }
        }
        if (t) {
            let o = a(e.geometries), c = a(e.materials), l = a(e.textures), h = a(e.images), u = a(e.shapes), d = a(e.skeletons), f = a(e.animations), m = a(e.nodes);
            o.length > 0 && (n.geometries = o), c.length > 0 && (n.materials = c), l.length > 0 && (n.textures = l), h.length > 0 && (n.images = h), u.length > 0 && (n.shapes = u), d.length > 0 && (n.skeletons = d), f.length > 0 && (n.animations = f), m.length > 0 && (n.nodes = m);
        }
        return n.object = i, n;
        function a(o) {
            let c = [];
            for(let l in o){
                let h = o[l];
                delete h.metadata, c.push(h);
            }
            return c;
        }
    }
    clone(e) {
        return new this.constructor().copy(this, e);
    }
    copy(e, t = !0) {
        if (this.name = e.name, this.up.copy(e.up), this.position.copy(e.position), this.rotation.order = e.rotation.order, this.quaternion.copy(e.quaternion), this.scale.copy(e.scale), this.matrix.copy(e.matrix), this.matrixWorld.copy(e.matrixWorld), this.matrixAutoUpdate = e.matrixAutoUpdate, this.matrixWorldNeedsUpdate = e.matrixWorldNeedsUpdate, this.matrixWorldAutoUpdate = e.matrixWorldAutoUpdate, this.layers.mask = e.layers.mask, this.visible = e.visible, this.castShadow = e.castShadow, this.receiveShadow = e.receiveShadow, this.frustumCulled = e.frustumCulled, this.renderOrder = e.renderOrder, this.animations = e.animations.slice(), this.userData = JSON.parse(JSON.stringify(e.userData)), t === !0) for(let n = 0; n < e.children.length; n++){
            let i = e.children[n];
            this.add(i.clone());
        }
        return this;
    }
};
Je.DEFAULT_UP = new A(0, 1, 0);
Je.DEFAULT_MATRIX_AUTO_UPDATE = !0;
Je.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = !0;
var Kt = new A, un = new A, Ha = new A, dn = new A, bi = new A, Ei = new A, Kl = new A, Ga = new A, Wa = new A, Xa = new A, $s = !1, Un = class s1 {
    constructor(e = new A, t = new A, n = new A){
        this.a = e, this.b = t, this.c = n;
    }
    static getNormal(e, t, n, i) {
        i.subVectors(n, t), Kt.subVectors(e, t), i.cross(Kt);
        let r = i.lengthSq();
        return r > 0 ? i.multiplyScalar(1 / Math.sqrt(r)) : i.set(0, 0, 0);
    }
    static getBarycoord(e, t, n, i, r) {
        Kt.subVectors(i, t), un.subVectors(n, t), Ha.subVectors(e, t);
        let a = Kt.dot(Kt), o = Kt.dot(un), c = Kt.dot(Ha), l = un.dot(un), h = un.dot(Ha), u = a * l - o * o;
        if (u === 0) return r.set(-2, -1, -1);
        let d = 1 / u, f = (l * c - o * h) * d, m = (a * h - o * c) * d;
        return r.set(1 - f - m, m, f);
    }
    static containsPoint(e, t, n, i) {
        return this.getBarycoord(e, t, n, i, dn), dn.x >= 0 && dn.y >= 0 && dn.x + dn.y <= 1;
    }
    static getUV(e, t, n, i, r, a, o, c) {
        return $s === !1 && (console.warn("THREE.Triangle.getUV() has been renamed to THREE.Triangle.getInterpolation()."), $s = !0), this.getInterpolation(e, t, n, i, r, a, o, c);
    }
    static getInterpolation(e, t, n, i, r, a, o, c) {
        return this.getBarycoord(e, t, n, i, dn), c.setScalar(0), c.addScaledVector(r, dn.x), c.addScaledVector(a, dn.y), c.addScaledVector(o, dn.z), c;
    }
    static isFrontFacing(e, t, n, i) {
        return Kt.subVectors(n, t), un.subVectors(e, t), Kt.cross(un).dot(i) < 0;
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
        return Kt.subVectors(this.c, this.b), un.subVectors(this.a, this.b), Kt.cross(un).length() * .5;
    }
    getMidpoint(e) {
        return e.addVectors(this.a, this.b).add(this.c).multiplyScalar(1 / 3);
    }
    getNormal(e) {
        return s1.getNormal(this.a, this.b, this.c, e);
    }
    getPlane(e) {
        return e.setFromCoplanarPoints(this.a, this.b, this.c);
    }
    getBarycoord(e, t) {
        return s1.getBarycoord(e, this.a, this.b, this.c, t);
    }
    getUV(e, t, n, i, r) {
        return $s === !1 && (console.warn("THREE.Triangle.getUV() has been renamed to THREE.Triangle.getInterpolation()."), $s = !0), s1.getInterpolation(e, this.a, this.b, this.c, t, n, i, r);
    }
    getInterpolation(e, t, n, i, r) {
        return s1.getInterpolation(e, this.a, this.b, this.c, t, n, i, r);
    }
    containsPoint(e) {
        return s1.containsPoint(e, this.a, this.b, this.c);
    }
    isFrontFacing(e) {
        return s1.isFrontFacing(this.a, this.b, this.c, e);
    }
    intersectsBox(e) {
        return e.intersectsTriangle(this);
    }
    closestPointToPoint(e, t) {
        let n = this.a, i = this.b, r = this.c, a, o;
        bi.subVectors(i, n), Ei.subVectors(r, n), Ga.subVectors(e, n);
        let c = bi.dot(Ga), l = Ei.dot(Ga);
        if (c <= 0 && l <= 0) return t.copy(n);
        Wa.subVectors(e, i);
        let h = bi.dot(Wa), u = Ei.dot(Wa);
        if (h >= 0 && u <= h) return t.copy(i);
        let d = c * u - h * l;
        if (d <= 0 && c >= 0 && h <= 0) return a = c / (c - h), t.copy(n).addScaledVector(bi, a);
        Xa.subVectors(e, r);
        let f = bi.dot(Xa), m = Ei.dot(Xa);
        if (m >= 0 && f <= m) return t.copy(r);
        let _ = f * l - c * m;
        if (_ <= 0 && l >= 0 && m <= 0) return o = l / (l - m), t.copy(n).addScaledVector(Ei, o);
        let g = h * m - f * u;
        if (g <= 0 && u - h >= 0 && f - m >= 0) return Kl.subVectors(r, i), o = (u - h) / (u - h + (f - m)), t.copy(i).addScaledVector(Kl, o);
        let p = 1 / (g + _ + d);
        return a = _ * p, o = d * p, t.copy(n).addScaledVector(bi, a).addScaledVector(Ei, o);
    }
    equals(e) {
        return e.a.equals(this.a) && e.b.equals(this.b) && e.c.equals(this.c);
    }
}, fp = 0, bt = class extends sn {
    constructor(){
        super(), this.isMaterial = !0, Object.defineProperty(this, "id", {
            value: fp++
        }), this.uuid = kt(), this.name = "", this.type = "Material", this.blending = Wi, this.side = Bn, this.vertexColors = !1, this.opacity = 1, this.transparent = !1, this.alphaHash = !1, this.blendSrc = ld, this.blendDst = hd, this.blendEquation = Bi, this.blendSrcAlpha = null, this.blendDstAlpha = null, this.blendEquationAlpha = null, this.depthFunc = uo, this.depthTest = !0, this.depthWrite = !0, this.stencilWriteMask = 255, this.stencilFunc = If, this.stencilRef = 0, this.stencilFuncMask = 255, this.stencilFail = Ia, this.stencilZFail = Ia, this.stencilZPass = Ia, this.stencilWrite = !1, this.clippingPlanes = null, this.clipIntersection = !1, this.clipShadows = !1, this.shadowSide = null, this.colorWrite = !0, this.precision = null, this.polygonOffset = !1, this.polygonOffsetFactor = 0, this.polygonOffsetUnits = 0, this.dithering = !1, this.alphaToCoverage = !1, this.premultipliedAlpha = !1, this.forceSinglePass = !1, this.visible = !0, this.toneMapped = !0, this.userData = {}, this.version = 0, this._alphaTest = 0;
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
                console.warn(`THREE.Material: parameter '${t}' has value of undefined.`);
                continue;
            }
            let i = this[t];
            if (i === void 0) {
                console.warn(`THREE.Material: '${t}' is not a property of THREE.${this.type}.`);
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
                version: 4.6,
                type: "Material",
                generator: "Material.toJSON"
            }
        };
        n.uuid = this.uuid, n.type = this.type, this.name !== "" && (n.name = this.name), this.color && this.color.isColor && (n.color = this.color.getHex()), this.roughness !== void 0 && (n.roughness = this.roughness), this.metalness !== void 0 && (n.metalness = this.metalness), this.sheen !== void 0 && (n.sheen = this.sheen), this.sheenColor && this.sheenColor.isColor && (n.sheenColor = this.sheenColor.getHex()), this.sheenRoughness !== void 0 && (n.sheenRoughness = this.sheenRoughness), this.emissive && this.emissive.isColor && (n.emissive = this.emissive.getHex()), this.emissiveIntensity && this.emissiveIntensity !== 1 && (n.emissiveIntensity = this.emissiveIntensity), this.specular && this.specular.isColor && (n.specular = this.specular.getHex()), this.specularIntensity !== void 0 && (n.specularIntensity = this.specularIntensity), this.specularColor && this.specularColor.isColor && (n.specularColor = this.specularColor.getHex()), this.shininess !== void 0 && (n.shininess = this.shininess), this.clearcoat !== void 0 && (n.clearcoat = this.clearcoat), this.clearcoatRoughness !== void 0 && (n.clearcoatRoughness = this.clearcoatRoughness), this.clearcoatMap && this.clearcoatMap.isTexture && (n.clearcoatMap = this.clearcoatMap.toJSON(e).uuid), this.clearcoatRoughnessMap && this.clearcoatRoughnessMap.isTexture && (n.clearcoatRoughnessMap = this.clearcoatRoughnessMap.toJSON(e).uuid), this.clearcoatNormalMap && this.clearcoatNormalMap.isTexture && (n.clearcoatNormalMap = this.clearcoatNormalMap.toJSON(e).uuid, n.clearcoatNormalScale = this.clearcoatNormalScale.toArray()), this.iridescence !== void 0 && (n.iridescence = this.iridescence), this.iridescenceIOR !== void 0 && (n.iridescenceIOR = this.iridescenceIOR), this.iridescenceThicknessRange !== void 0 && (n.iridescenceThicknessRange = this.iridescenceThicknessRange), this.iridescenceMap && this.iridescenceMap.isTexture && (n.iridescenceMap = this.iridescenceMap.toJSON(e).uuid), this.iridescenceThicknessMap && this.iridescenceThicknessMap.isTexture && (n.iridescenceThicknessMap = this.iridescenceThicknessMap.toJSON(e).uuid), this.anisotropy !== void 0 && (n.anisotropy = this.anisotropy), this.anisotropyRotation !== void 0 && (n.anisotropyRotation = this.anisotropyRotation), this.anisotropyMap && this.anisotropyMap.isTexture && (n.anisotropyMap = this.anisotropyMap.toJSON(e).uuid), this.map && this.map.isTexture && (n.map = this.map.toJSON(e).uuid), this.matcap && this.matcap.isTexture && (n.matcap = this.matcap.toJSON(e).uuid), this.alphaMap && this.alphaMap.isTexture && (n.alphaMap = this.alphaMap.toJSON(e).uuid), this.lightMap && this.lightMap.isTexture && (n.lightMap = this.lightMap.toJSON(e).uuid, n.lightMapIntensity = this.lightMapIntensity), this.aoMap && this.aoMap.isTexture && (n.aoMap = this.aoMap.toJSON(e).uuid, n.aoMapIntensity = this.aoMapIntensity), this.bumpMap && this.bumpMap.isTexture && (n.bumpMap = this.bumpMap.toJSON(e).uuid, n.bumpScale = this.bumpScale), this.normalMap && this.normalMap.isTexture && (n.normalMap = this.normalMap.toJSON(e).uuid, n.normalMapType = this.normalMapType, n.normalScale = this.normalScale.toArray()), this.displacementMap && this.displacementMap.isTexture && (n.displacementMap = this.displacementMap.toJSON(e).uuid, n.displacementScale = this.displacementScale, n.displacementBias = this.displacementBias), this.roughnessMap && this.roughnessMap.isTexture && (n.roughnessMap = this.roughnessMap.toJSON(e).uuid), this.metalnessMap && this.metalnessMap.isTexture && (n.metalnessMap = this.metalnessMap.toJSON(e).uuid), this.emissiveMap && this.emissiveMap.isTexture && (n.emissiveMap = this.emissiveMap.toJSON(e).uuid), this.specularMap && this.specularMap.isTexture && (n.specularMap = this.specularMap.toJSON(e).uuid), this.specularIntensityMap && this.specularIntensityMap.isTexture && (n.specularIntensityMap = this.specularIntensityMap.toJSON(e).uuid), this.specularColorMap && this.specularColorMap.isTexture && (n.specularColorMap = this.specularColorMap.toJSON(e).uuid), this.envMap && this.envMap.isTexture && (n.envMap = this.envMap.toJSON(e).uuid, this.combine !== void 0 && (n.combine = this.combine)), this.envMapIntensity !== void 0 && (n.envMapIntensity = this.envMapIntensity), this.reflectivity !== void 0 && (n.reflectivity = this.reflectivity), this.refractionRatio !== void 0 && (n.refractionRatio = this.refractionRatio), this.gradientMap && this.gradientMap.isTexture && (n.gradientMap = this.gradientMap.toJSON(e).uuid), this.transmission !== void 0 && (n.transmission = this.transmission), this.transmissionMap && this.transmissionMap.isTexture && (n.transmissionMap = this.transmissionMap.toJSON(e).uuid), this.thickness !== void 0 && (n.thickness = this.thickness), this.thicknessMap && this.thicknessMap.isTexture && (n.thicknessMap = this.thicknessMap.toJSON(e).uuid), this.attenuationDistance !== void 0 && this.attenuationDistance !== 1 / 0 && (n.attenuationDistance = this.attenuationDistance), this.attenuationColor !== void 0 && (n.attenuationColor = this.attenuationColor.getHex()), this.size !== void 0 && (n.size = this.size), this.shadowSide !== null && (n.shadowSide = this.shadowSide), this.sizeAttenuation !== void 0 && (n.sizeAttenuation = this.sizeAttenuation), this.blending !== Wi && (n.blending = this.blending), this.side !== Bn && (n.side = this.side), this.vertexColors === !0 && (n.vertexColors = !0), this.opacity < 1 && (n.opacity = this.opacity), this.transparent === !0 && (n.transparent = !0), n.depthFunc = this.depthFunc, n.depthTest = this.depthTest, n.depthWrite = this.depthWrite, n.colorWrite = this.colorWrite, n.stencilWrite = this.stencilWrite, n.stencilWriteMask = this.stencilWriteMask, n.stencilFunc = this.stencilFunc, n.stencilRef = this.stencilRef, n.stencilFuncMask = this.stencilFuncMask, n.stencilFail = this.stencilFail, n.stencilZFail = this.stencilZFail, n.stencilZPass = this.stencilZPass, this.rotation !== void 0 && this.rotation !== 0 && (n.rotation = this.rotation), this.polygonOffset === !0 && (n.polygonOffset = !0), this.polygonOffsetFactor !== 0 && (n.polygonOffsetFactor = this.polygonOffsetFactor), this.polygonOffsetUnits !== 0 && (n.polygonOffsetUnits = this.polygonOffsetUnits), this.linewidth !== void 0 && this.linewidth !== 1 && (n.linewidth = this.linewidth), this.dashSize !== void 0 && (n.dashSize = this.dashSize), this.gapSize !== void 0 && (n.gapSize = this.gapSize), this.scale !== void 0 && (n.scale = this.scale), this.dithering === !0 && (n.dithering = !0), this.alphaTest > 0 && (n.alphaTest = this.alphaTest), this.alphaHash === !0 && (n.alphaHash = !0), this.alphaToCoverage === !0 && (n.alphaToCoverage = !0), this.premultipliedAlpha === !0 && (n.premultipliedAlpha = !0), this.forceSinglePass === !0 && (n.forceSinglePass = !0), this.wireframe === !0 && (n.wireframe = !0), this.wireframeLinewidth > 1 && (n.wireframeLinewidth = this.wireframeLinewidth), this.wireframeLinecap !== "round" && (n.wireframeLinecap = this.wireframeLinecap), this.wireframeLinejoin !== "round" && (n.wireframeLinejoin = this.wireframeLinejoin), this.flatShading === !0 && (n.flatShading = !0), this.visible === !1 && (n.visible = !1), this.toneMapped === !1 && (n.toneMapped = !1), this.fog === !1 && (n.fog = !1), Object.keys(this.userData).length > 0 && (n.userData = this.userData);
        function i(r) {
            let a = [];
            for(let o in r){
                let c = r[o];
                delete c.metadata, a.push(c);
            }
            return a;
        }
        if (t) {
            let r = i(e.textures), a = i(e.images);
            r.length > 0 && (n.textures = r), a.length > 0 && (n.images = a);
        }
        return n;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(e) {
        this.name = e.name, this.blending = e.blending, this.side = e.side, this.vertexColors = e.vertexColors, this.opacity = e.opacity, this.transparent = e.transparent, this.blendSrc = e.blendSrc, this.blendDst = e.blendDst, this.blendEquation = e.blendEquation, this.blendSrcAlpha = e.blendSrcAlpha, this.blendDstAlpha = e.blendDstAlpha, this.blendEquationAlpha = e.blendEquationAlpha, this.depthFunc = e.depthFunc, this.depthTest = e.depthTest, this.depthWrite = e.depthWrite, this.stencilWriteMask = e.stencilWriteMask, this.stencilFunc = e.stencilFunc, this.stencilRef = e.stencilRef, this.stencilFuncMask = e.stencilFuncMask, this.stencilFail = e.stencilFail, this.stencilZFail = e.stencilZFail, this.stencilZPass = e.stencilZPass, this.stencilWrite = e.stencilWrite;
        let t = e.clippingPlanes, n = null;
        if (t !== null) {
            let i = t.length;
            n = new Array(i);
            for(let r = 0; r !== i; ++r)n[r] = t[r].clone();
        }
        return this.clippingPlanes = n, this.clipIntersection = e.clipIntersection, this.clipShadows = e.clipShadows, this.shadowSide = e.shadowSide, this.colorWrite = e.colorWrite, this.precision = e.precision, this.polygonOffset = e.polygonOffset, this.polygonOffsetFactor = e.polygonOffsetFactor, this.polygonOffsetUnits = e.polygonOffsetUnits, this.dithering = e.dithering, this.alphaTest = e.alphaTest, this.alphaHash = e.alphaHash, this.alphaToCoverage = e.alphaToCoverage, this.premultipliedAlpha = e.premultipliedAlpha, this.forceSinglePass = e.forceSinglePass, this.visible = e.visible, this.toneMapped = e.toneMapped, this.userData = JSON.parse(JSON.stringify(e.userData)), this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
}, Sd = {
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
}, Cn = {
    h: 0,
    s: 0,
    l: 0
}, Ks = {
    h: 0,
    s: 0,
    l: 0
};
function qa(s1, e, t) {
    return t < 0 && (t += 1), t > 1 && (t -= 1), t < 1 / 6 ? s1 + (e - s1) * 6 * t : t < 1 / 2 ? e : t < 2 / 3 ? s1 + (e - s1) * 6 * (2 / 3 - t) : s1;
}
var pe = class {
    constructor(e, t, n){
        return this.isColor = !0, this.r = 1, this.g = 1, this.b = 1, this.set(e, t, n);
    }
    set(e, t, n) {
        if (t === void 0 && n === void 0) {
            let i = e;
            i && i.isColor ? this.copy(i) : typeof i == "number" ? this.setHex(i) : typeof i == "string" && this.setStyle(i);
        } else this.setRGB(e, t, n);
        return this;
    }
    setScalar(e) {
        return this.r = e, this.g = e, this.b = e, this;
    }
    setHex(e, t = vt) {
        return e = Math.floor(e), this.r = (e >> 16 & 255) / 255, this.g = (e >> 8 & 255) / 255, this.b = (e & 255) / 255, Qe.toWorkingColorSpace(this, t), this;
    }
    setRGB(e, t, n, i = Qe.workingColorSpace) {
        return this.r = e, this.g = t, this.b = n, Qe.toWorkingColorSpace(this, i), this;
    }
    setHSL(e, t, n, i = Qe.workingColorSpace) {
        if (e = Yc(e, 1), t = ct(t, 0, 1), n = ct(n, 0, 1), t === 0) this.r = this.g = this.b = n;
        else {
            let r = n <= .5 ? n * (1 + t) : n + t - n * t, a = 2 * n - r;
            this.r = qa(a, r, e + 1 / 3), this.g = qa(a, r, e), this.b = qa(a, r, e - 1 / 3);
        }
        return Qe.toWorkingColorSpace(this, i), this;
    }
    setStyle(e, t = vt) {
        function n(r) {
            r !== void 0 && parseFloat(r) < 1 && console.warn("THREE.Color: Alpha component of " + e + " will be ignored.");
        }
        let i;
        if (i = /^(\w+)\(([^\)]*)\)/.exec(e)) {
            let r, a = i[1], o = i[2];
            switch(a){
                case "rgb":
                case "rgba":
                    if (r = /^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return n(r[4]), this.setRGB(Math.min(255, parseInt(r[1], 10)) / 255, Math.min(255, parseInt(r[2], 10)) / 255, Math.min(255, parseInt(r[3], 10)) / 255, t);
                    if (r = /^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return n(r[4]), this.setRGB(Math.min(100, parseInt(r[1], 10)) / 100, Math.min(100, parseInt(r[2], 10)) / 100, Math.min(100, parseInt(r[3], 10)) / 100, t);
                    break;
                case "hsl":
                case "hsla":
                    if (r = /^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return n(r[4]), this.setHSL(parseFloat(r[1]) / 360, parseFloat(r[2]) / 100, parseFloat(r[3]) / 100, t);
                    break;
                default:
                    console.warn("THREE.Color: Unknown color model " + e);
            }
        } else if (i = /^\#([A-Fa-f\d]+)$/.exec(e)) {
            let r = i[1], a = r.length;
            if (a === 3) return this.setRGB(parseInt(r.charAt(0), 16) / 15, parseInt(r.charAt(1), 16) / 15, parseInt(r.charAt(2), 16) / 15, t);
            if (a === 6) return this.setHex(parseInt(r, 16), t);
            console.warn("THREE.Color: Invalid hex color " + e);
        } else if (e && e.length > 0) return this.setColorName(e, t);
        return this;
    }
    setColorName(e, t = vt) {
        let n = Sd[e.toLowerCase()];
        return n !== void 0 ? this.setHex(n, t) : console.warn("THREE.Color: Unknown color " + e), this;
    }
    clone() {
        return new this.constructor(this.r, this.g, this.b);
    }
    copy(e) {
        return this.r = e.r, this.g = e.g, this.b = e.b, this;
    }
    copySRGBToLinear(e) {
        return this.r = Xi(e.r), this.g = Xi(e.g), this.b = Xi(e.b), this;
    }
    copyLinearToSRGB(e) {
        return this.r = Da(e.r), this.g = Da(e.g), this.b = Da(e.b), this;
    }
    convertSRGBToLinear() {
        return this.copySRGBToLinear(this), this;
    }
    convertLinearToSRGB() {
        return this.copyLinearToSRGB(this), this;
    }
    getHex(e = vt) {
        return Qe.fromWorkingColorSpace(Tt.copy(this), e), Math.round(ct(Tt.r * 255, 0, 255)) * 65536 + Math.round(ct(Tt.g * 255, 0, 255)) * 256 + Math.round(ct(Tt.b * 255, 0, 255));
    }
    getHexString(e = vt) {
        return ("000000" + this.getHex(e).toString(16)).slice(-6);
    }
    getHSL(e, t = Qe.workingColorSpace) {
        Qe.fromWorkingColorSpace(Tt.copy(this), t);
        let n = Tt.r, i = Tt.g, r = Tt.b, a = Math.max(n, i, r), o = Math.min(n, i, r), c, l, h = (o + a) / 2;
        if (o === a) c = 0, l = 0;
        else {
            let u = a - o;
            switch(l = h <= .5 ? u / (a + o) : u / (2 - a - o), a){
                case n:
                    c = (i - r) / u + (i < r ? 6 : 0);
                    break;
                case i:
                    c = (r - n) / u + 2;
                    break;
                case r:
                    c = (n - i) / u + 4;
                    break;
            }
            c /= 6;
        }
        return e.h = c, e.s = l, e.l = h, e;
    }
    getRGB(e, t = Qe.workingColorSpace) {
        return Qe.fromWorkingColorSpace(Tt.copy(this), t), e.r = Tt.r, e.g = Tt.g, e.b = Tt.b, e;
    }
    getStyle(e = vt) {
        Qe.fromWorkingColorSpace(Tt.copy(this), e);
        let t = Tt.r, n = Tt.g, i = Tt.b;
        return e !== vt ? `color(${e} ${t.toFixed(3)} ${n.toFixed(3)} ${i.toFixed(3)})` : `rgb(${Math.round(t * 255)},${Math.round(n * 255)},${Math.round(i * 255)})`;
    }
    offsetHSL(e, t, n) {
        return this.getHSL(Cn), this.setHSL(Cn.h + e, Cn.s + t, Cn.l + n);
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
        this.getHSL(Cn), e.getHSL(Ks);
        let n = ys(Cn.h, Ks.h, t), i = ys(Cn.s, Ks.s, t), r = ys(Cn.l, Ks.l, t);
        return this.setHSL(n, i, r), this;
    }
    setFromVector3(e) {
        return this.r = e.x, this.g = e.y, this.b = e.z, this;
    }
    applyMatrix3(e) {
        let t = this.r, n = this.g, i = this.b, r = e.elements;
        return this.r = r[0] * t + r[3] * n + r[6] * i, this.g = r[1] * t + r[4] * n + r[7] * i, this.b = r[2] * t + r[5] * n + r[8] * i, this;
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
        return this.r = e.getX(t), this.g = e.getY(t), this.b = e.getZ(t), this;
    }
    toJSON() {
        return this.getHex();
    }
    *[Symbol.iterator]() {
        yield this.r, yield this.g, yield this.b;
    }
}, Tt = new pe;
pe.NAMES = Sd;
var Sn = class extends bt {
    constructor(e){
        super(), this.isMeshBasicMaterial = !0, this.type = "MeshBasicMaterial", this.color = new pe(16777215), this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = xa, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.specularMap = e.specularMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.combine = e.combine, this.reflectivity = e.reflectivity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.fog = e.fog, this;
    }
}, _n = pp();
function pp() {
    let s1 = new ArrayBuffer(4), e = new Float32Array(s1), t = new Uint32Array(s1), n = new Uint32Array(512), i = new Uint32Array(512);
    for(let c = 0; c < 256; ++c){
        let l = c - 127;
        l < -27 ? (n[c] = 0, n[c | 256] = 32768, i[c] = 24, i[c | 256] = 24) : l < -14 ? (n[c] = 1024 >> -l - 14, n[c | 256] = 1024 >> -l - 14 | 32768, i[c] = -l - 1, i[c | 256] = -l - 1) : l <= 15 ? (n[c] = l + 15 << 10, n[c | 256] = l + 15 << 10 | 32768, i[c] = 13, i[c | 256] = 13) : l < 128 ? (n[c] = 31744, n[c | 256] = 64512, i[c] = 24, i[c | 256] = 24) : (n[c] = 31744, n[c | 256] = 64512, i[c] = 13, i[c | 256] = 13);
    }
    let r = new Uint32Array(2048), a = new Uint32Array(64), o = new Uint32Array(64);
    for(let c = 1; c < 1024; ++c){
        let l = c << 13, h = 0;
        for(; !(l & 8388608);)l <<= 1, h -= 8388608;
        l &= -8388609, h += 947912704, r[c] = l | h;
    }
    for(let c = 1024; c < 2048; ++c)r[c] = 939524096 + (c - 1024 << 13);
    for(let c = 1; c < 31; ++c)a[c] = c << 23;
    a[31] = 1199570944, a[32] = 2147483648;
    for(let c = 33; c < 63; ++c)a[c] = 2147483648 + (c - 32 << 23);
    a[63] = 3347054592;
    for(let c = 1; c < 64; ++c)c !== 32 && (o[c] = 1024);
    return {
        floatView: e,
        uint32View: t,
        baseTable: n,
        shiftTable: i,
        mantissaTable: r,
        exponentTable: a,
        offsetTable: o
    };
}
function Nt(s1) {
    Math.abs(s1) > 65504 && console.warn("THREE.DataUtils.toHalfFloat(): Value out of range."), s1 = ct(s1, -65504, 65504), _n.floatView[0] = s1;
    let e = _n.uint32View[0], t = e >> 23 & 511;
    return _n.baseTable[t] + ((e & 8388607) >> _n.shiftTable[t]);
}
function xs(s1) {
    let e = s1 >> 10;
    return _n.uint32View[0] = _n.mantissaTable[_n.offsetTable[e] + (s1 & 1023)] + _n.exponentTable[e], _n.floatView[0];
}
var Mv = {
    toHalfFloat: Nt,
    fromHalfFloat: xs
}, ft = new A, Qs = new Z, et = class {
    constructor(e, t, n = !1){
        if (Array.isArray(e)) throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
        this.isBufferAttribute = !0, this.name = "", this.array = e, this.itemSize = t, this.count = e !== void 0 ? e.length / t : 0, this.normalized = n, this.usage = Hr, this.updateRange = {
            offset: 0,
            count: -1
        }, this.gpuType = xn, this.version = 0;
    }
    onUploadCallback() {}
    set needsUpdate(e) {
        e === !0 && this.version++;
    }
    setUsage(e) {
        return this.usage = e, this;
    }
    copy(e) {
        return this.name = e.name, this.array = new e.array.constructor(e.array), this.itemSize = e.itemSize, this.count = e.count, this.normalized = e.normalized, this.usage = e.usage, this.gpuType = e.gpuType, this;
    }
    copyAt(e, t, n) {
        e *= this.itemSize, n *= t.itemSize;
        for(let i = 0, r = this.itemSize; i < r; i++)this.array[e + i] = t.array[n + i];
        return this;
    }
    copyArray(e) {
        return this.array.set(e), this;
    }
    applyMatrix3(e) {
        if (this.itemSize === 2) for(let t = 0, n = this.count; t < n; t++)Qs.fromBufferAttribute(this, t), Qs.applyMatrix3(e), this.setXY(t, Qs.x, Qs.y);
        else if (this.itemSize === 3) for(let t = 0, n = this.count; t < n; t++)ft.fromBufferAttribute(this, t), ft.applyMatrix3(e), this.setXYZ(t, ft.x, ft.y, ft.z);
        return this;
    }
    applyMatrix4(e) {
        for(let t = 0, n = this.count; t < n; t++)ft.fromBufferAttribute(this, t), ft.applyMatrix4(e), this.setXYZ(t, ft.x, ft.y, ft.z);
        return this;
    }
    applyNormalMatrix(e) {
        for(let t = 0, n = this.count; t < n; t++)ft.fromBufferAttribute(this, t), ft.applyNormalMatrix(e), this.setXYZ(t, ft.x, ft.y, ft.z);
        return this;
    }
    transformDirection(e) {
        for(let t = 0, n = this.count; t < n; t++)ft.fromBufferAttribute(this, t), ft.transformDirection(e), this.setXYZ(t, ft.x, ft.y, ft.z);
        return this;
    }
    set(e, t = 0) {
        return this.array.set(e, t), this;
    }
    getComponent(e, t) {
        let n = this.array[e * this.itemSize + t];
        return this.normalized && (n = Ot(n, this.array)), n;
    }
    setComponent(e, t, n) {
        return this.normalized && (n = Be(n, this.array)), this.array[e * this.itemSize + t] = n, this;
    }
    getX(e) {
        let t = this.array[e * this.itemSize];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setX(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize] = t, this;
    }
    getY(e) {
        let t = this.array[e * this.itemSize + 1];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setY(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize + 1] = t, this;
    }
    getZ(e) {
        let t = this.array[e * this.itemSize + 2];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setZ(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize + 2] = t, this;
    }
    getW(e) {
        let t = this.array[e * this.itemSize + 3];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setW(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize + 3] = t, this;
    }
    setXY(e, t, n) {
        return e *= this.itemSize, this.normalized && (t = Be(t, this.array), n = Be(n, this.array)), this.array[e + 0] = t, this.array[e + 1] = n, this;
    }
    setXYZ(e, t, n, i) {
        return e *= this.itemSize, this.normalized && (t = Be(t, this.array), n = Be(n, this.array), i = Be(i, this.array)), this.array[e + 0] = t, this.array[e + 1] = n, this.array[e + 2] = i, this;
    }
    setXYZW(e, t, n, i, r) {
        return e *= this.itemSize, this.normalized && (t = Be(t, this.array), n = Be(n, this.array), i = Be(i, this.array), r = Be(r, this.array)), this.array[e + 0] = t, this.array[e + 1] = n, this.array[e + 2] = i, this.array[e + 3] = r, this;
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
            array: Array.from(this.array),
            normalized: this.normalized
        };
        return this.name !== "" && (e.name = this.name), this.usage !== Hr && (e.usage = this.usage), (this.updateRange.offset !== 0 || this.updateRange.count !== -1) && (e.updateRange = this.updateRange), e;
    }
}, Ql = class extends et {
    constructor(e, t, n){
        super(new Int8Array(e), t, n);
    }
}, jl = class extends et {
    constructor(e, t, n){
        super(new Uint8Array(e), t, n);
    }
}, eh = class extends et {
    constructor(e, t, n){
        super(new Uint8ClampedArray(e), t, n);
    }
}, th = class extends et {
    constructor(e, t, n){
        super(new Int16Array(e), t, n);
    }
}, Zr = class extends et {
    constructor(e, t, n){
        super(new Uint16Array(e), t, n);
    }
}, nh = class extends et {
    constructor(e, t, n){
        super(new Int32Array(e), t, n);
    }
}, Jr = class extends et {
    constructor(e, t, n){
        super(new Uint32Array(e), t, n);
    }
}, ih = class extends et {
    constructor(e, t, n){
        super(new Uint16Array(e), t, n), this.isFloat16BufferAttribute = !0;
    }
    getX(e) {
        let t = xs(this.array[e * this.itemSize]);
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setX(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize] = Nt(t), this;
    }
    getY(e) {
        let t = xs(this.array[e * this.itemSize + 1]);
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setY(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize + 1] = Nt(t), this;
    }
    getZ(e) {
        let t = xs(this.array[e * this.itemSize + 2]);
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setZ(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize + 2] = Nt(t), this;
    }
    getW(e) {
        let t = xs(this.array[e * this.itemSize + 3]);
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setW(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.array[e * this.itemSize + 3] = Nt(t), this;
    }
    setXY(e, t, n) {
        return e *= this.itemSize, this.normalized && (t = Be(t, this.array), n = Be(n, this.array)), this.array[e + 0] = Nt(t), this.array[e + 1] = Nt(n), this;
    }
    setXYZ(e, t, n, i) {
        return e *= this.itemSize, this.normalized && (t = Be(t, this.array), n = Be(n, this.array), i = Be(i, this.array)), this.array[e + 0] = Nt(t), this.array[e + 1] = Nt(n), this.array[e + 2] = Nt(i), this;
    }
    setXYZW(e, t, n, i, r) {
        return e *= this.itemSize, this.normalized && (t = Be(t, this.array), n = Be(n, this.array), i = Be(i, this.array), r = Be(r, this.array)), this.array[e + 0] = Nt(t), this.array[e + 1] = Nt(n), this.array[e + 2] = Nt(i), this.array[e + 3] = Nt(r), this;
    }
}, ve = class extends et {
    constructor(e, t, n){
        super(new Float32Array(e), t, n);
    }
}, sh = class extends et {
    constructor(e, t, n){
        super(new Float64Array(e), t, n);
    }
}, mp = 0, Gt = new ze, Ya = new Je, Ti = new A, Vt = new Qt, us = new Qt, xt = new A, Ge = class s1 extends sn {
    constructor(){
        super(), this.isBufferGeometry = !0, Object.defineProperty(this, "id", {
            value: mp++
        }), this.uuid = kt(), this.name = "", this.type = "BufferGeometry", this.index = null, this.attributes = {}, this.morphAttributes = {}, this.morphTargetsRelative = !1, this.groups = [], this.boundingBox = null, this.boundingSphere = null, this.drawRange = {
            start: 0,
            count: 1 / 0
        }, this.userData = {};
    }
    getIndex() {
        return this.index;
    }
    setIndex(e) {
        return Array.isArray(e) ? this.index = new (Md(e) ? Jr : Zr)(e, 1) : this.index = e, this;
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
            let r = new He().getNormalMatrix(e);
            n.applyNormalMatrix(r), n.needsUpdate = !0;
        }
        let i = this.attributes.tangent;
        return i !== void 0 && (i.transformDirection(e), i.needsUpdate = !0), this.boundingBox !== null && this.computeBoundingBox(), this.boundingSphere !== null && this.computeBoundingSphere(), this;
    }
    applyQuaternion(e) {
        return Gt.makeRotationFromQuaternion(e), this.applyMatrix4(Gt), this;
    }
    rotateX(e) {
        return Gt.makeRotationX(e), this.applyMatrix4(Gt), this;
    }
    rotateY(e) {
        return Gt.makeRotationY(e), this.applyMatrix4(Gt), this;
    }
    rotateZ(e) {
        return Gt.makeRotationZ(e), this.applyMatrix4(Gt), this;
    }
    translate(e, t, n) {
        return Gt.makeTranslation(e, t, n), this.applyMatrix4(Gt), this;
    }
    scale(e, t, n) {
        return Gt.makeScale(e, t, n), this.applyMatrix4(Gt), this;
    }
    lookAt(e) {
        return Ya.lookAt(e), Ya.updateMatrix(), this.applyMatrix4(Ya.matrix), this;
    }
    center() {
        return this.computeBoundingBox(), this.boundingBox.getCenter(Ti).negate(), this.translate(Ti.x, Ti.y, Ti.z), this;
    }
    setFromPoints(e) {
        let t = [];
        for(let n = 0, i = e.length; n < i; n++){
            let r = e[n];
            t.push(r.x, r.y, r.z || 0);
        }
        return this.setAttribute("position", new ve(t, 3)), this;
    }
    computeBoundingBox() {
        this.boundingBox === null && (this.boundingBox = new Qt);
        let e = this.attributes.position, t = this.morphAttributes.position;
        if (e && e.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box. Alternatively set "mesh.frustumCulled" to "false".', this), this.boundingBox.set(new A(-1 / 0, -1 / 0, -1 / 0), new A(1 / 0, 1 / 0, 1 / 0));
            return;
        }
        if (e !== void 0) {
            if (this.boundingBox.setFromBufferAttribute(e), t) for(let n = 0, i = t.length; n < i; n++){
                let r = t[n];
                Vt.setFromBufferAttribute(r), this.morphTargetsRelative ? (xt.addVectors(this.boundingBox.min, Vt.min), this.boundingBox.expandByPoint(xt), xt.addVectors(this.boundingBox.max, Vt.max), this.boundingBox.expandByPoint(xt)) : (this.boundingBox.expandByPoint(Vt.min), this.boundingBox.expandByPoint(Vt.max));
            }
        } else this.boundingBox.makeEmpty();
        (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) && console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
    computeBoundingSphere() {
        this.boundingSphere === null && (this.boundingSphere = new Yt);
        let e = this.attributes.position, t = this.morphAttributes.position;
        if (e && e.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere. Alternatively set "mesh.frustumCulled" to "false".', this), this.boundingSphere.set(new A, 1 / 0);
            return;
        }
        if (e) {
            let n = this.boundingSphere.center;
            if (Vt.setFromBufferAttribute(e), t) for(let r = 0, a = t.length; r < a; r++){
                let o = t[r];
                us.setFromBufferAttribute(o), this.morphTargetsRelative ? (xt.addVectors(Vt.min, us.min), Vt.expandByPoint(xt), xt.addVectors(Vt.max, us.max), Vt.expandByPoint(xt)) : (Vt.expandByPoint(us.min), Vt.expandByPoint(us.max));
            }
            Vt.getCenter(n);
            let i = 0;
            for(let r = 0, a = e.count; r < a; r++)xt.fromBufferAttribute(e, r), i = Math.max(i, n.distanceToSquared(xt));
            if (t) for(let r = 0, a = t.length; r < a; r++){
                let o = t[r], c = this.morphTargetsRelative;
                for(let l = 0, h = o.count; l < h; l++)xt.fromBufferAttribute(o, l), c && (Ti.fromBufferAttribute(e, l), xt.add(Ti)), i = Math.max(i, n.distanceToSquared(xt));
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
        let n = e.array, i = t.position.array, r = t.normal.array, a = t.uv.array, o = i.length / 3;
        this.hasAttribute("tangent") === !1 && this.setAttribute("tangent", new et(new Float32Array(4 * o), 4));
        let c = this.getAttribute("tangent").array, l = [], h = [];
        for(let T = 0; T < o; T++)l[T] = new A, h[T] = new A;
        let u = new A, d = new A, f = new A, m = new Z, _ = new Z, g = new Z, p = new A, v = new A;
        function x(T, O, Y) {
            u.fromArray(i, T * 3), d.fromArray(i, O * 3), f.fromArray(i, Y * 3), m.fromArray(a, T * 2), _.fromArray(a, O * 2), g.fromArray(a, Y * 2), d.sub(u), f.sub(u), _.sub(m), g.sub(m);
            let $ = 1 / (_.x * g.y - g.x * _.y);
            isFinite($) && (p.copy(d).multiplyScalar(g.y).addScaledVector(f, -_.y).multiplyScalar($), v.copy(f).multiplyScalar(_.x).addScaledVector(d, -g.x).multiplyScalar($), l[T].add(p), l[O].add(p), l[Y].add(p), h[T].add(v), h[O].add(v), h[Y].add(v));
        }
        let y = this.groups;
        y.length === 0 && (y = [
            {
                start: 0,
                count: n.length
            }
        ]);
        for(let T = 0, O = y.length; T < O; ++T){
            let Y = y[T], $ = Y.start, U = Y.count;
            for(let z = $, q = $ + U; z < q; z += 3)x(n[z + 0], n[z + 1], n[z + 2]);
        }
        let b = new A, w = new A, R = new A, I = new A;
        function M(T) {
            R.fromArray(r, T * 3), I.copy(R);
            let O = l[T];
            b.copy(O), b.sub(R.multiplyScalar(R.dot(O))).normalize(), w.crossVectors(I, O);
            let $ = w.dot(h[T]) < 0 ? -1 : 1;
            c[T * 4] = b.x, c[T * 4 + 1] = b.y, c[T * 4 + 2] = b.z, c[T * 4 + 3] = $;
        }
        for(let T = 0, O = y.length; T < O; ++T){
            let Y = y[T], $ = Y.start, U = Y.count;
            for(let z = $, q = $ + U; z < q; z += 3)M(n[z + 0]), M(n[z + 1]), M(n[z + 2]);
        }
    }
    computeVertexNormals() {
        let e = this.index, t = this.getAttribute("position");
        if (t !== void 0) {
            let n = this.getAttribute("normal");
            if (n === void 0) n = new et(new Float32Array(t.count * 3), 3), this.setAttribute("normal", n);
            else for(let d = 0, f = n.count; d < f; d++)n.setXYZ(d, 0, 0, 0);
            let i = new A, r = new A, a = new A, o = new A, c = new A, l = new A, h = new A, u = new A;
            if (e) for(let d = 0, f = e.count; d < f; d += 3){
                let m = e.getX(d + 0), _ = e.getX(d + 1), g = e.getX(d + 2);
                i.fromBufferAttribute(t, m), r.fromBufferAttribute(t, _), a.fromBufferAttribute(t, g), h.subVectors(a, r), u.subVectors(i, r), h.cross(u), o.fromBufferAttribute(n, m), c.fromBufferAttribute(n, _), l.fromBufferAttribute(n, g), o.add(h), c.add(h), l.add(h), n.setXYZ(m, o.x, o.y, o.z), n.setXYZ(_, c.x, c.y, c.z), n.setXYZ(g, l.x, l.y, l.z);
            }
            else for(let d = 0, f = t.count; d < f; d += 3)i.fromBufferAttribute(t, d + 0), r.fromBufferAttribute(t, d + 1), a.fromBufferAttribute(t, d + 2), h.subVectors(a, r), u.subVectors(i, r), h.cross(u), n.setXYZ(d + 0, h.x, h.y, h.z), n.setXYZ(d + 1, h.x, h.y, h.z), n.setXYZ(d + 2, h.x, h.y, h.z);
            this.normalizeNormals(), n.needsUpdate = !0;
        }
    }
    normalizeNormals() {
        let e = this.attributes.normal;
        for(let t = 0, n = e.count; t < n; t++)xt.fromBufferAttribute(e, t), xt.normalize(), e.setXYZ(t, xt.x, xt.y, xt.z);
    }
    toNonIndexed() {
        function e(o, c) {
            let l = o.array, h = o.itemSize, u = o.normalized, d = new l.constructor(c.length * h), f = 0, m = 0;
            for(let _ = 0, g = c.length; _ < g; _++){
                o.isInterleavedBufferAttribute ? f = c[_] * o.data.stride + o.offset : f = c[_] * h;
                for(let p = 0; p < h; p++)d[m++] = l[f++];
            }
            return new et(d, h, u);
        }
        if (this.index === null) return console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."), this;
        let t = new s1, n = this.index.array, i = this.attributes;
        for(let o in i){
            let c = i[o], l = e(c, n);
            t.setAttribute(o, l);
        }
        let r = this.morphAttributes;
        for(let o in r){
            let c = [], l = r[o];
            for(let h = 0, u = l.length; h < u; h++){
                let d = l[h], f = e(d, n);
                c.push(f);
            }
            t.morphAttributes[o] = c;
        }
        t.morphTargetsRelative = this.morphTargetsRelative;
        let a = this.groups;
        for(let o = 0, c = a.length; o < c; o++){
            let l = a[o];
            t.addGroup(l.start, l.count, l.materialIndex);
        }
        return t;
    }
    toJSON() {
        let e = {
            metadata: {
                version: 4.6,
                type: "BufferGeometry",
                generator: "BufferGeometry.toJSON"
            }
        };
        if (e.uuid = this.uuid, e.type = this.type, this.name !== "" && (e.name = this.name), Object.keys(this.userData).length > 0 && (e.userData = this.userData), this.parameters !== void 0) {
            let c = this.parameters;
            for(let l in c)c[l] !== void 0 && (e[l] = c[l]);
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
        for(let c in n){
            let l = n[c];
            e.data.attributes[c] = l.toJSON(e.data);
        }
        let i = {}, r = !1;
        for(let c in this.morphAttributes){
            let l = this.morphAttributes[c], h = [];
            for(let u = 0, d = l.length; u < d; u++){
                let f = l[u];
                h.push(f.toJSON(e.data));
            }
            h.length > 0 && (i[c] = h, r = !0);
        }
        r && (e.data.morphAttributes = i, e.data.morphTargetsRelative = this.morphTargetsRelative);
        let a = this.groups;
        a.length > 0 && (e.data.groups = JSON.parse(JSON.stringify(a)));
        let o = this.boundingSphere;
        return o !== null && (e.data.boundingSphere = {
            center: o.center.toArray(),
            radius: o.radius
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
        for(let l in i){
            let h = i[l];
            this.setAttribute(l, h.clone(t));
        }
        let r = e.morphAttributes;
        for(let l in r){
            let h = [], u = r[l];
            for(let d = 0, f = u.length; d < f; d++)h.push(u[d].clone(t));
            this.morphAttributes[l] = h;
        }
        this.morphTargetsRelative = e.morphTargetsRelative;
        let a = e.groups;
        for(let l = 0, h = a.length; l < h; l++){
            let u = a[l];
            this.addGroup(u.start, u.count, u.materialIndex);
        }
        let o = e.boundingBox;
        o !== null && (this.boundingBox = o.clone());
        let c = e.boundingSphere;
        return c !== null && (this.boundingSphere = c.clone()), this.drawRange.start = e.drawRange.start, this.drawRange.count = e.drawRange.count, this.userData = e.userData, this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
}, rh = new ze, qn = new hi, js = new Yt, ah = new A, wi = new A, Ai = new A, Ri = new A, Za = new A, er = new A, tr = new Z, nr = new Z, ir = new Z, oh = new A, ch = new A, lh = new A, sr = new A, rr = new A, Mt = class extends Je {
    constructor(e = new Ge, t = new Sn){
        super(), this.isMesh = !0, this.type = "Mesh", this.geometry = e, this.material = t, this.updateMorphTargets();
    }
    copy(e, t) {
        return super.copy(e, t), e.morphTargetInfluences !== void 0 && (this.morphTargetInfluences = e.morphTargetInfluences.slice()), e.morphTargetDictionary !== void 0 && (this.morphTargetDictionary = Object.assign({}, e.morphTargetDictionary)), this.material = Array.isArray(e.material) ? e.material.slice() : e.material, this.geometry = e.geometry, this;
    }
    updateMorphTargets() {
        let t = this.geometry.morphAttributes, n = Object.keys(t);
        if (n.length > 0) {
            let i = t[n[0]];
            if (i !== void 0) {
                this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                for(let r = 0, a = i.length; r < a; r++){
                    let o = i[r].name || String(r);
                    this.morphTargetInfluences.push(0), this.morphTargetDictionary[o] = r;
                }
            }
        }
    }
    getVertexPosition(e, t) {
        let n = this.geometry, i = n.attributes.position, r = n.morphAttributes.position, a = n.morphTargetsRelative;
        t.fromBufferAttribute(i, e);
        let o = this.morphTargetInfluences;
        if (r && o) {
            er.set(0, 0, 0);
            for(let c = 0, l = r.length; c < l; c++){
                let h = o[c], u = r[c];
                h !== 0 && (Za.fromBufferAttribute(u, e), a ? er.addScaledVector(Za, h) : er.addScaledVector(Za.sub(t), h));
            }
            t.add(er);
        }
        return t;
    }
    raycast(e, t) {
        let n = this.geometry, i = this.material, r = this.matrixWorld;
        i !== void 0 && (n.boundingSphere === null && n.computeBoundingSphere(), js.copy(n.boundingSphere), js.applyMatrix4(r), qn.copy(e.ray).recast(e.near), !(js.containsPoint(qn.origin) === !1 && (qn.intersectSphere(js, ah) === null || qn.origin.distanceToSquared(ah) > (e.far - e.near) ** 2)) && (rh.copy(r).invert(), qn.copy(e.ray).applyMatrix4(rh), !(n.boundingBox !== null && qn.intersectsBox(n.boundingBox) === !1) && this._computeIntersections(e, t, qn)));
    }
    _computeIntersections(e, t, n) {
        let i, r = this.geometry, a = this.material, o = r.index, c = r.attributes.position, l = r.attributes.uv, h = r.attributes.uv1, u = r.attributes.normal, d = r.groups, f = r.drawRange;
        if (o !== null) if (Array.isArray(a)) for(let m = 0, _ = d.length; m < _; m++){
            let g = d[m], p = a[g.materialIndex], v = Math.max(g.start, f.start), x = Math.min(o.count, Math.min(g.start + g.count, f.start + f.count));
            for(let y = v, b = x; y < b; y += 3){
                let w = o.getX(y), R = o.getX(y + 1), I = o.getX(y + 2);
                i = ar(this, p, e, n, l, h, u, w, R, I), i && (i.faceIndex = Math.floor(y / 3), i.face.materialIndex = g.materialIndex, t.push(i));
            }
        }
        else {
            let m = Math.max(0, f.start), _ = Math.min(o.count, f.start + f.count);
            for(let g = m, p = _; g < p; g += 3){
                let v = o.getX(g), x = o.getX(g + 1), y = o.getX(g + 2);
                i = ar(this, a, e, n, l, h, u, v, x, y), i && (i.faceIndex = Math.floor(g / 3), t.push(i));
            }
        }
        else if (c !== void 0) if (Array.isArray(a)) for(let m = 0, _ = d.length; m < _; m++){
            let g = d[m], p = a[g.materialIndex], v = Math.max(g.start, f.start), x = Math.min(c.count, Math.min(g.start + g.count, f.start + f.count));
            for(let y = v, b = x; y < b; y += 3){
                let w = y, R = y + 1, I = y + 2;
                i = ar(this, p, e, n, l, h, u, w, R, I), i && (i.faceIndex = Math.floor(y / 3), i.face.materialIndex = g.materialIndex, t.push(i));
            }
        }
        else {
            let m = Math.max(0, f.start), _ = Math.min(c.count, f.start + f.count);
            for(let g = m, p = _; g < p; g += 3){
                let v = g, x = g + 1, y = g + 2;
                i = ar(this, a, e, n, l, h, u, v, x, y), i && (i.faceIndex = Math.floor(g / 3), t.push(i));
            }
        }
    }
};
function gp(s1, e, t, n, i, r, a, o) {
    let c;
    if (e.side === Ft ? c = n.intersectTriangle(a, r, i, !0, o) : c = n.intersectTriangle(i, r, a, e.side === Bn, o), c === null) return null;
    rr.copy(o), rr.applyMatrix4(s1.matrixWorld);
    let l = t.ray.origin.distanceTo(rr);
    return l < t.near || l > t.far ? null : {
        distance: l,
        point: rr.clone(),
        object: s1
    };
}
function ar(s1, e, t, n, i, r, a, o, c, l) {
    s1.getVertexPosition(o, wi), s1.getVertexPosition(c, Ai), s1.getVertexPosition(l, Ri);
    let h = gp(s1, e, t, n, wi, Ai, Ri, sr);
    if (h) {
        i && (tr.fromBufferAttribute(i, o), nr.fromBufferAttribute(i, c), ir.fromBufferAttribute(i, l), h.uv = Un.getInterpolation(sr, wi, Ai, Ri, tr, nr, ir, new Z)), r && (tr.fromBufferAttribute(r, o), nr.fromBufferAttribute(r, c), ir.fromBufferAttribute(r, l), h.uv1 = Un.getInterpolation(sr, wi, Ai, Ri, tr, nr, ir, new Z), h.uv2 = h.uv1), a && (oh.fromBufferAttribute(a, o), ch.fromBufferAttribute(a, c), lh.fromBufferAttribute(a, l), h.normal = Un.getInterpolation(sr, wi, Ai, Ri, oh, ch, lh, new A), h.normal.dot(n.direction) > 0 && h.normal.multiplyScalar(-1));
        let u = {
            a: o,
            b: c,
            c: l,
            normal: new A,
            materialIndex: 0
        };
        Un.getNormal(wi, Ai, Ri, u.normal), h.face = u;
    }
    return h;
}
var Ji = class s1 extends Ge {
    constructor(e = 1, t = 1, n = 1, i = 1, r = 1, a = 1){
        super(), this.type = "BoxGeometry", this.parameters = {
            width: e,
            height: t,
            depth: n,
            widthSegments: i,
            heightSegments: r,
            depthSegments: a
        };
        let o = this;
        i = Math.floor(i), r = Math.floor(r), a = Math.floor(a);
        let c = [], l = [], h = [], u = [], d = 0, f = 0;
        m("z", "y", "x", -1, -1, n, t, e, a, r, 0), m("z", "y", "x", 1, -1, n, t, -e, a, r, 1), m("x", "z", "y", 1, 1, e, n, t, i, a, 2), m("x", "z", "y", 1, -1, e, n, -t, i, a, 3), m("x", "y", "z", 1, -1, e, t, n, i, r, 4), m("x", "y", "z", -1, -1, e, t, -n, i, r, 5), this.setIndex(c), this.setAttribute("position", new ve(l, 3)), this.setAttribute("normal", new ve(h, 3)), this.setAttribute("uv", new ve(u, 2));
        function m(_, g, p, v, x, y, b, w, R, I, M) {
            let T = y / R, O = b / I, Y = y / 2, $ = b / 2, U = w / 2, z = R + 1, q = I + 1, H = 0, ne = 0, W = new A;
            for(let K = 0; K < q; K++){
                let D = K * O - $;
                for(let G = 0; G < z; G++){
                    let he = G * T - Y;
                    W[_] = he * v, W[g] = D * x, W[p] = U, l.push(W.x, W.y, W.z), W[_] = 0, W[g] = 0, W[p] = w > 0 ? 1 : -1, h.push(W.x, W.y, W.z), u.push(G / R), u.push(1 - K / I), H += 1;
                }
            }
            for(let K = 0; K < I; K++)for(let D = 0; D < R; D++){
                let G = d + D + z * K, he = d + D + z * (K + 1), fe = d + (D + 1) + z * (K + 1), _e = d + (D + 1) + z * K;
                c.push(G, he, _e), c.push(he, fe, _e), ne += 6;
            }
            o.addGroup(f, ne, M), f += ne, d += H;
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.width, e.height, e.depth, e.widthSegments, e.heightSegments, e.depthSegments);
    }
};
function $i(s1) {
    let e = {};
    for(let t in s1){
        e[t] = {};
        for(let n in s1[t]){
            let i = s1[t][n];
            i && (i.isColor || i.isMatrix3 || i.isMatrix4 || i.isVector2 || i.isVector3 || i.isVector4 || i.isTexture || i.isQuaternion) ? i.isRenderTargetTexture ? (console.warn("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms()."), e[t][n] = null) : e[t][n] = i.clone() : Array.isArray(i) ? e[t][n] = i.slice() : e[t][n] = i;
        }
    }
    return e;
}
function Lt(s1) {
    let e = {};
    for(let t = 0; t < s1.length; t++){
        let n = $i(s1[t]);
        for(let i in n)e[i] = n[i];
    }
    return e;
}
function _p(s1) {
    let e = [];
    for(let t = 0; t < s1.length; t++)e.push(s1[t].clone());
    return e;
}
function bd(s1) {
    return s1.getRenderTarget() === null ? s1.outputColorSpace : Qe.workingColorSpace;
}
var xp = {
    clone: $i,
    merge: Lt
}, vp = `void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`, yp = `void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`, jt = class extends bt {
    constructor(e){
        super(), this.isShaderMaterial = !0, this.type = "ShaderMaterial", this.defines = {}, this.uniforms = {}, this.uniformsGroups = [], this.vertexShader = vp, this.fragmentShader = yp, this.linewidth = 1, this.wireframe = !1, this.wireframeLinewidth = 1, this.fog = !1, this.lights = !1, this.clipping = !1, this.forceSinglePass = !0, this.extensions = {
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
            uv1: [
                0,
                0
            ]
        }, this.index0AttributeName = void 0, this.uniformsNeedUpdate = !1, this.glslVersion = null, e !== void 0 && this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.fragmentShader = e.fragmentShader, this.vertexShader = e.vertexShader, this.uniforms = $i(e.uniforms), this.uniformsGroups = _p(e.uniformsGroups), this.defines = Object.assign({}, e.defines), this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.fog = e.fog, this.lights = e.lights, this.clipping = e.clipping, this.extensions = Object.assign({}, e.extensions), this.glslVersion = e.glslVersion, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        t.glslVersion = this.glslVersion, t.uniforms = {};
        for(let i in this.uniforms){
            let a = this.uniforms[i].value;
            a && a.isTexture ? t.uniforms[i] = {
                type: "t",
                value: a.toJSON(e).uuid
            } : a && a.isColor ? t.uniforms[i] = {
                type: "c",
                value: a.getHex()
            } : a && a.isVector2 ? t.uniforms[i] = {
                type: "v2",
                value: a.toArray()
            } : a && a.isVector3 ? t.uniforms[i] = {
                type: "v3",
                value: a.toArray()
            } : a && a.isVector4 ? t.uniforms[i] = {
                type: "v4",
                value: a.toArray()
            } : a && a.isMatrix3 ? t.uniforms[i] = {
                type: "m3",
                value: a.toArray()
            } : a && a.isMatrix4 ? t.uniforms[i] = {
                type: "m4",
                value: a.toArray()
            } : t.uniforms[i] = {
                value: a
            };
        }
        Object.keys(this.defines).length > 0 && (t.defines = this.defines), t.vertexShader = this.vertexShader, t.fragmentShader = this.fragmentShader, t.lights = this.lights, t.clipping = this.clipping;
        let n = {};
        for(let i in this.extensions)this.extensions[i] === !0 && (n[i] = !0);
        return Object.keys(n).length > 0 && (t.extensions = n), t;
    }
}, Cs = class extends Je {
    constructor(){
        super(), this.isCamera = !0, this.type = "Camera", this.matrixWorldInverse = new ze, this.projectionMatrix = new ze, this.projectionMatrixInverse = new ze, this.coordinateSystem = vn;
    }
    copy(e, t) {
        return super.copy(e, t), this.matrixWorldInverse.copy(e.matrixWorldInverse), this.projectionMatrix.copy(e.projectionMatrix), this.projectionMatrixInverse.copy(e.projectionMatrixInverse), this.coordinateSystem = e.coordinateSystem, this;
    }
    getWorldDirection(e) {
        return super.getWorldDirection(e).negate();
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
}, yt = class extends Cs {
    constructor(e = 50, t = 1, n = .1, i = 2e3){
        super(), this.isPerspectiveCamera = !0, this.type = "PerspectiveCamera", this.fov = e, this.zoom = 1, this.near = n, this.far = i, this.focus = 10, this.aspect = t, this.view = null, this.filmGauge = 35, this.filmOffset = 0, this.updateProjectionMatrix();
    }
    copy(e, t) {
        return super.copy(e, t), this.fov = e.fov, this.zoom = e.zoom, this.near = e.near, this.far = e.far, this.focus = e.focus, this.aspect = e.aspect, this.view = e.view === null ? null : Object.assign({}, e.view), this.filmGauge = e.filmGauge, this.filmOffset = e.filmOffset, this;
    }
    setFocalLength(e) {
        let t = .5 * this.getFilmHeight() / e;
        this.fov = Zi * 2 * Math.atan(t), this.updateProjectionMatrix();
    }
    getFocalLength() {
        let e = Math.tan(ai * .5 * this.fov);
        return .5 * this.getFilmHeight() / e;
    }
    getEffectiveFOV() {
        return Zi * 2 * Math.atan(Math.tan(ai * .5 * this.fov) / this.zoom);
    }
    getFilmWidth() {
        return this.filmGauge * Math.min(this.aspect, 1);
    }
    getFilmHeight() {
        return this.filmGauge / Math.max(this.aspect, 1);
    }
    setViewOffset(e, t, n, i, r, a) {
        this.aspect = e / t, this.view === null && (this.view = {
            enabled: !0,
            fullWidth: 1,
            fullHeight: 1,
            offsetX: 0,
            offsetY: 0,
            width: 1,
            height: 1
        }), this.view.enabled = !0, this.view.fullWidth = e, this.view.fullHeight = t, this.view.offsetX = n, this.view.offsetY = i, this.view.width = r, this.view.height = a, this.updateProjectionMatrix();
    }
    clearViewOffset() {
        this.view !== null && (this.view.enabled = !1), this.updateProjectionMatrix();
    }
    updateProjectionMatrix() {
        let e = this.near, t = e * Math.tan(ai * .5 * this.fov) / this.zoom, n = 2 * t, i = this.aspect * n, r = -.5 * i, a = this.view;
        if (this.view !== null && this.view.enabled) {
            let c = a.fullWidth, l = a.fullHeight;
            r += a.offsetX * i / c, t -= a.offsetY * n / l, i *= a.width / c, n *= a.height / l;
        }
        let o = this.filmOffset;
        o !== 0 && (r += e * o / this.getFilmWidth()), this.projectionMatrix.makePerspective(r, r + i, t, t - n, e, this.far, this.coordinateSystem), this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.fov = this.fov, t.object.zoom = this.zoom, t.object.near = this.near, t.object.far = this.far, t.object.focus = this.focus, t.object.aspect = this.aspect, this.view !== null && (t.object.view = Object.assign({}, this.view)), t.object.filmGauge = this.filmGauge, t.object.filmOffset = this.filmOffset, t;
    }
}, Ci = -90, Pi = 1, _o = class extends Je {
    constructor(e, t, n){
        super(), this.type = "CubeCamera", this.renderTarget = n, this.coordinateSystem = null, this.activeMipmapLevel = 0;
        let i = new yt(Ci, Pi, e, t);
        i.layers = this.layers, this.add(i);
        let r = new yt(Ci, Pi, e, t);
        r.layers = this.layers, this.add(r);
        let a = new yt(Ci, Pi, e, t);
        a.layers = this.layers, this.add(a);
        let o = new yt(Ci, Pi, e, t);
        o.layers = this.layers, this.add(o);
        let c = new yt(Ci, Pi, e, t);
        c.layers = this.layers, this.add(c);
        let l = new yt(Ci, Pi, e, t);
        l.layers = this.layers, this.add(l);
    }
    updateCoordinateSystem() {
        let e = this.coordinateSystem, t = this.children.concat(), [n, i, r, a, o, c] = t;
        for (let l of t)this.remove(l);
        if (e === vn) n.up.set(0, 1, 0), n.lookAt(1, 0, 0), i.up.set(0, 1, 0), i.lookAt(-1, 0, 0), r.up.set(0, 0, -1), r.lookAt(0, 1, 0), a.up.set(0, 0, 1), a.lookAt(0, -1, 0), o.up.set(0, 1, 0), o.lookAt(0, 0, 1), c.up.set(0, 1, 0), c.lookAt(0, 0, -1);
        else if (e === Gr) n.up.set(0, -1, 0), n.lookAt(-1, 0, 0), i.up.set(0, -1, 0), i.lookAt(1, 0, 0), r.up.set(0, 0, 1), r.lookAt(0, 1, 0), a.up.set(0, 0, -1), a.lookAt(0, -1, 0), o.up.set(0, -1, 0), o.lookAt(0, 0, 1), c.up.set(0, -1, 0), c.lookAt(0, 0, -1);
        else throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: " + e);
        for (let l of t)this.add(l), l.updateMatrixWorld();
    }
    update(e, t) {
        this.parent === null && this.updateMatrixWorld();
        let { renderTarget: n , activeMipmapLevel: i  } = this;
        this.coordinateSystem !== e.coordinateSystem && (this.coordinateSystem = e.coordinateSystem, this.updateCoordinateSystem());
        let [r, a, o, c, l, h] = this.children, u = e.getRenderTarget(), d = e.getActiveCubeFace(), f = e.getActiveMipmapLevel(), m = e.xr.enabled;
        e.xr.enabled = !1;
        let _ = n.texture.generateMipmaps;
        n.texture.generateMipmaps = !1, e.setRenderTarget(n, 0, i), e.render(t, r), e.setRenderTarget(n, 1, i), e.render(t, a), e.setRenderTarget(n, 2, i), e.render(t, o), e.setRenderTarget(n, 3, i), e.render(t, c), e.setRenderTarget(n, 4, i), e.render(t, l), n.texture.generateMipmaps = _, e.setRenderTarget(n, 5, i), e.render(t, h), e.setRenderTarget(u, d, f), e.xr.enabled = m, n.texture.needsPMREMUpdate = !0;
    }
}, Ki = class extends St {
    constructor(e, t, n, i, r, a, o, c, l, h){
        e = e !== void 0 ? e : [], t = t !== void 0 ? t : zn, super(e, t, n, i, r, a, o, c, l, h), this.isCubeTexture = !0, this.flipY = !1;
    }
    get images() {
        return this.image;
    }
    set images(e) {
        this.image = e;
    }
}, xo = class extends qt {
    constructor(e = 1, t = {}){
        super(e, e, t), this.isWebGLCubeRenderTarget = !0;
        let n = {
            width: e,
            height: e,
            depth: 1
        }, i = [
            n,
            n,
            n,
            n,
            n,
            n
        ];
        t.encoding !== void 0 && (Ms("THREE.WebGLCubeRenderTarget: option.encoding has been replaced by option.colorSpace."), t.colorSpace = t.encoding === ri ? vt : Xt), this.texture = new Ki(i, t.mapping, t.wrapS, t.wrapT, t.magFilter, t.minFilter, t.format, t.type, t.anisotropy, t.colorSpace), this.texture.isRenderTargetTexture = !0, this.texture.generateMipmaps = t.generateMipmaps !== void 0 ? t.generateMipmaps : !1, this.texture.minFilter = t.minFilter !== void 0 ? t.minFilter : mt;
    }
    fromEquirectangularTexture(e, t) {
        this.texture.type = t.type, this.texture.colorSpace = t.colorSpace, this.texture.generateMipmaps = t.generateMipmaps, this.texture.minFilter = t.minFilter, this.texture.magFilter = t.magFilter;
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
        }, i = new Ji(5, 5, 5), r = new jt({
            name: "CubemapFromEquirect",
            uniforms: $i(n.uniforms),
            vertexShader: n.vertexShader,
            fragmentShader: n.fragmentShader,
            side: Ft,
            blending: Dn
        });
        r.uniforms.tEquirect.value = t;
        let a = new Mt(i, r), o = t.minFilter;
        return t.minFilter === li && (t.minFilter = mt), new _o(1, 10, this).update(e, a), t.minFilter = o, a.geometry.dispose(), a.material.dispose(), this;
    }
    clear(e, t, n, i) {
        let r = e.getRenderTarget();
        for(let a = 0; a < 6; a++)e.setRenderTarget(this, a), e.clear(t, n, i);
        e.setRenderTarget(r);
    }
}, Ja = new A, Mp = new A, Sp = new He, mn = class {
    constructor(e = new A(1, 0, 0), t = 0){
        this.isPlane = !0, this.normal = e, this.constant = t;
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
        let i = Ja.subVectors(n, t).cross(Mp.subVectors(e, t)).normalize();
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
        return t.copy(e).addScaledVector(this.normal, -this.distanceToPoint(e));
    }
    intersectLine(e, t) {
        let n = e.delta(Ja), i = this.normal.dot(n);
        if (i === 0) return this.distanceToPoint(e.start) === 0 ? t.copy(e.start) : null;
        let r = -(e.start.dot(this.normal) + this.constant) / i;
        return r < 0 || r > 1 ? null : t.copy(e.start).addScaledVector(n, r);
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
        let n = t || Sp.getNormalMatrix(e), i = this.coplanarPoint(Ja).applyMatrix4(e), r = this.normal.applyMatrix3(n).normalize();
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
}, Yn = new Yt, or = new A, Ps = class {
    constructor(e = new mn, t = new mn, n = new mn, i = new mn, r = new mn, a = new mn){
        this.planes = [
            e,
            t,
            n,
            i,
            r,
            a
        ];
    }
    set(e, t, n, i, r, a) {
        let o = this.planes;
        return o[0].copy(e), o[1].copy(t), o[2].copy(n), o[3].copy(i), o[4].copy(r), o[5].copy(a), this;
    }
    copy(e) {
        let t = this.planes;
        for(let n = 0; n < 6; n++)t[n].copy(e.planes[n]);
        return this;
    }
    setFromProjectionMatrix(e, t = vn) {
        let n = this.planes, i = e.elements, r = i[0], a = i[1], o = i[2], c = i[3], l = i[4], h = i[5], u = i[6], d = i[7], f = i[8], m = i[9], _ = i[10], g = i[11], p = i[12], v = i[13], x = i[14], y = i[15];
        if (n[0].setComponents(c - r, d - l, g - f, y - p).normalize(), n[1].setComponents(c + r, d + l, g + f, y + p).normalize(), n[2].setComponents(c + a, d + h, g + m, y + v).normalize(), n[3].setComponents(c - a, d - h, g - m, y - v).normalize(), n[4].setComponents(c - o, d - u, g - _, y - x).normalize(), t === vn) n[5].setComponents(c + o, d + u, g + _, y + x).normalize();
        else if (t === Gr) n[5].setComponents(o, u, _, x).normalize();
        else throw new Error("THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: " + t);
        return this;
    }
    intersectsObject(e) {
        if (e.boundingSphere !== void 0) e.boundingSphere === null && e.computeBoundingSphere(), Yn.copy(e.boundingSphere).applyMatrix4(e.matrixWorld);
        else {
            let t = e.geometry;
            t.boundingSphere === null && t.computeBoundingSphere(), Yn.copy(t.boundingSphere).applyMatrix4(e.matrixWorld);
        }
        return this.intersectsSphere(Yn);
    }
    intersectsSprite(e) {
        return Yn.center.set(0, 0, 0), Yn.radius = .7071067811865476, Yn.applyMatrix4(e.matrixWorld), this.intersectsSphere(Yn);
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
            if (or.x = i.normal.x > 0 ? e.max.x : e.min.x, or.y = i.normal.y > 0 ? e.max.y : e.min.y, or.z = i.normal.z > 0 ? e.max.z : e.min.z, i.distanceToPoint(or) < 0) return !1;
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
function Ed() {
    let s1 = null, e = !1, t = null, n = null;
    function i(r, a) {
        t(r, a), n = s1.requestAnimationFrame(i);
    }
    return {
        start: function() {
            e !== !0 && t !== null && (n = s1.requestAnimationFrame(i), e = !0);
        },
        stop: function() {
            s1.cancelAnimationFrame(n), e = !1;
        },
        setAnimationLoop: function(r) {
            t = r;
        },
        setContext: function(r) {
            s1 = r;
        }
    };
}
function bp(s1, e) {
    let t = e.isWebGL2, n = new WeakMap;
    function i(l, h) {
        let u = l.array, d = l.usage, f = s1.createBuffer();
        s1.bindBuffer(h, f), s1.bufferData(h, u, d), l.onUploadCallback();
        let m;
        if (u instanceof Float32Array) m = s1.FLOAT;
        else if (u instanceof Uint16Array) if (l.isFloat16BufferAttribute) if (t) m = s1.HALF_FLOAT;
        else throw new Error("THREE.WebGLAttributes: Usage of Float16BufferAttribute requires WebGL2.");
        else m = s1.UNSIGNED_SHORT;
        else if (u instanceof Int16Array) m = s1.SHORT;
        else if (u instanceof Uint32Array) m = s1.UNSIGNED_INT;
        else if (u instanceof Int32Array) m = s1.INT;
        else if (u instanceof Int8Array) m = s1.BYTE;
        else if (u instanceof Uint8Array) m = s1.UNSIGNED_BYTE;
        else if (u instanceof Uint8ClampedArray) m = s1.UNSIGNED_BYTE;
        else throw new Error("THREE.WebGLAttributes: Unsupported buffer data format: " + u);
        return {
            buffer: f,
            type: m,
            bytesPerElement: u.BYTES_PER_ELEMENT,
            version: l.version
        };
    }
    function r(l, h, u) {
        let d = h.array, f = h.updateRange;
        s1.bindBuffer(u, l), f.count === -1 ? s1.bufferSubData(u, 0, d) : (t ? s1.bufferSubData(u, f.offset * d.BYTES_PER_ELEMENT, d, f.offset, f.count) : s1.bufferSubData(u, f.offset * d.BYTES_PER_ELEMENT, d.subarray(f.offset, f.offset + f.count)), f.count = -1), h.onUploadCallback();
    }
    function a(l) {
        return l.isInterleavedBufferAttribute && (l = l.data), n.get(l);
    }
    function o(l) {
        l.isInterleavedBufferAttribute && (l = l.data);
        let h = n.get(l);
        h && (s1.deleteBuffer(h.buffer), n.delete(l));
    }
    function c(l, h) {
        if (l.isGLBufferAttribute) {
            let d = n.get(l);
            (!d || d.version < l.version) && n.set(l, {
                buffer: l.buffer,
                type: l.type,
                bytesPerElement: l.elementSize,
                version: l.version
            });
            return;
        }
        l.isInterleavedBufferAttribute && (l = l.data);
        let u = n.get(l);
        u === void 0 ? n.set(l, i(l, h)) : u.version < l.version && (r(u.buffer, l, h), u.version = l.version);
    }
    return {
        get: a,
        remove: o,
        update: c
    };
}
var $r = class s1 extends Ge {
    constructor(e = 1, t = 1, n = 1, i = 1){
        super(), this.type = "PlaneGeometry", this.parameters = {
            width: e,
            height: t,
            widthSegments: n,
            heightSegments: i
        };
        let r = e / 2, a = t / 2, o = Math.floor(n), c = Math.floor(i), l = o + 1, h = c + 1, u = e / o, d = t / c, f = [], m = [], _ = [], g = [];
        for(let p = 0; p < h; p++){
            let v = p * d - a;
            for(let x = 0; x < l; x++){
                let y = x * u - r;
                m.push(y, -v, 0), _.push(0, 0, 1), g.push(x / o), g.push(1 - p / c);
            }
        }
        for(let p = 0; p < c; p++)for(let v = 0; v < o; v++){
            let x = v + l * p, y = v + l * (p + 1), b = v + 1 + l * (p + 1), w = v + 1 + l * p;
            f.push(x, y, w), f.push(y, b, w);
        }
        this.setIndex(f), this.setAttribute("position", new ve(m, 3)), this.setAttribute("normal", new ve(_, 3)), this.setAttribute("uv", new ve(g, 2));
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.width, e.height, e.widthSegments, e.heightSegments);
    }
}, Ep = `#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`, Tp = `#ifdef USE_ALPHAHASH
	const float ALPHA_HASH_SCALE = 0.05;
	float hash2D( vec2 value ) {
		return fract( 1.0e4 * sin( 17.0 * value.x + 0.1 * value.y ) * ( 0.1 + abs( sin( 13.0 * value.y + value.x ) ) ) );
	}
	float hash3D( vec3 value ) {
		return hash2D( vec2( hash2D( value.xy ), value.z ) );
	}
	float getAlphaHashThreshold( vec3 position ) {
		float maxDeriv = max(
			length( dFdx( position.xyz ) ),
			length( dFdy( position.xyz ) )
		);
		float pixScale = 1.0 / ( ALPHA_HASH_SCALE * maxDeriv );
		vec2 pixScales = vec2(
			exp2( floor( log2( pixScale ) ) ),
			exp2( ceil( log2( pixScale ) ) )
		);
		vec2 alpha = vec2(
			hash3D( floor( pixScales.x * position.xyz ) ),
			hash3D( floor( pixScales.y * position.xyz ) )
		);
		float lerpFactor = fract( log2( pixScale ) );
		float x = ( 1.0 - lerpFactor ) * alpha.x + lerpFactor * alpha.y;
		float a = min( lerpFactor, 1.0 - lerpFactor );
		vec3 cases = vec3(
			x * x / ( 2.0 * a * ( 1.0 - a ) ),
			( x - 0.5 * a ) / ( 1.0 - a ),
			1.0 - ( ( 1.0 - x ) * ( 1.0 - x ) / ( 2.0 * a * ( 1.0 - a ) ) )
		);
		float threshold = ( x < ( 1.0 - a ) )
			? ( ( x < a ) ? cases.x : cases.y )
			: cases.z;
		return clamp( threshold , 1.0e-6, 1.0 );
	}
#endif`, wp = `#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`, Ap = `#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`, Rp = `#ifdef USE_ALPHATEST
	if ( diffuseColor.a < alphaTest ) discard;
#endif`, Cp = `#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`, Pp = `#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`, Lp = `#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`, Ip = `vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`, Up = `vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`, Dp = `float G_BlinnPhong_Implicit( ) {
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
} // validated`, Np = `#ifdef USE_IRIDESCENCE
	const mat3 XYZ_TO_REC709 = mat3(
		 3.2404542, -0.9692660,  0.0556434,
		-1.5371385,  1.8760108, -0.2040259,
		-0.4985314,  0.0415560,  1.0572252
	);
	vec3 Fresnel0ToIor( vec3 fresnel0 ) {
		vec3 sqrtF0 = sqrt( fresnel0 );
		return ( vec3( 1.0 ) + sqrtF0 ) / ( vec3( 1.0 ) - sqrtF0 );
	}
	vec3 IorToFresnel0( vec3 transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - vec3( incidentIor ) ) / ( transmittedIor + vec3( incidentIor ) ) );
	}
	float IorToFresnel0( float transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - incidentIor ) / ( transmittedIor + incidentIor ));
	}
	vec3 evalSensitivity( float OPD, vec3 shift ) {
		float phase = 2.0 * PI * OPD * 1.0e-9;
		vec3 val = vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
		vec3 pos = vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
		vec3 var = vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );
		vec3 xyz = val * sqrt( 2.0 * PI * var ) * cos( pos * phase + shift ) * exp( - pow2( phase ) * var );
		xyz.x += 9.7470e-14 * sqrt( 2.0 * PI * 4.5282e+09 ) * cos( 2.2399e+06 * phase + shift[ 0 ] ) * exp( - 4.5282e+09 * pow2( phase ) );
		xyz /= 1.0685e-7;
		vec3 rgb = XYZ_TO_REC709 * xyz;
		return rgb;
	}
	vec3 evalIridescence( float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0 ) {
		vec3 I;
		float iridescenceIOR = mix( outsideIOR, eta2, smoothstep( 0.0, 0.03, thinFilmThickness ) );
		float sinTheta2Sq = pow2( outsideIOR / iridescenceIOR ) * ( 1.0 - pow2( cosTheta1 ) );
		float cosTheta2Sq = 1.0 - sinTheta2Sq;
		if ( cosTheta2Sq < 0.0 ) {
			return vec3( 1.0 );
		}
		float cosTheta2 = sqrt( cosTheta2Sq );
		float R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
		float R12 = F_Schlick( R0, 1.0, cosTheta1 );
		float T121 = 1.0 - R12;
		float phi12 = 0.0;
		if ( iridescenceIOR < outsideIOR ) phi12 = PI;
		float phi21 = PI - phi12;
		vec3 baseIOR = Fresnel0ToIor( clamp( baseF0, 0.0, 0.9999 ) );		vec3 R1 = IorToFresnel0( baseIOR, iridescenceIOR );
		vec3 R23 = F_Schlick( R1, 1.0, cosTheta2 );
		vec3 phi23 = vec3( 0.0 );
		if ( baseIOR[ 0 ] < iridescenceIOR ) phi23[ 0 ] = PI;
		if ( baseIOR[ 1 ] < iridescenceIOR ) phi23[ 1 ] = PI;
		if ( baseIOR[ 2 ] < iridescenceIOR ) phi23[ 2 ] = PI;
		float OPD = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		vec3 phi = vec3( phi21 ) + phi23;
		vec3 R123 = clamp( R12 * R23, 1e-5, 0.9999 );
		vec3 r123 = sqrt( R123 );
		vec3 Rs = pow2( T121 ) * R23 / ( vec3( 1.0 ) - R123 );
		vec3 C0 = R12 + Rs;
		I = C0;
		vec3 Cm = Rs - T121;
		for ( int m = 1; m <= 2; ++ m ) {
			Cm *= r123;
			vec3 Sm = 2.0 * evalSensitivity( float( m ) * OPD, float( m ) * phi );
			I += Cm * Sm;
		}
		return max( I, vec3( 0.0 ) );
	}
#endif`, Op = `#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vBumpMapUv );
		vec2 dSTdy = dFdy( vBumpMapUv );
		float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = dFdx( surf_pos.xyz );
		vec3 vSigmaY = dFdy( surf_pos.xyz );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`, Fp = `#if NUM_CLIPPING_PLANES > 0
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
#endif`, Bp = `#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`, zp = `#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`, Vp = `#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`, kp = `#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`, Hp = `#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`, Gp = `#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
	varying vec3 vColor;
#endif`, Wp = `#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif`, Xp = `#define PI 3.141592653589793
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
vec3 pow2( const in vec3 x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 v ) { return dot( v, vec3( 0.3333333 ) ); }
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
#ifdef USE_ALPHAHASH
	varying vec3 vPosition;
#endif
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
float luminance( const in vec3 rgb ) {
	const vec3 weights = vec3( 0.2126729, 0.7151522, 0.0721750 );
	return dot( weights, rgb );
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}
vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float F_Schlick( const in float f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
} // validated`, qp = `#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_minMipLevel 4.0
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
		highp vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		uv.x += filterInt * 3.0 * cubeUV_minTileSize;
		uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
		uv.x *= CUBEUV_TEXEL_WIDTH;
		uv.y *= CUBEUV_TEXEL_HEIGHT;
		#ifdef texture2DGradEXT
			return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
		#else
			return texture2D( envMap, uv ).rgb;
		#endif
	}
	#define cubeUV_r0 1.0
	#define cubeUV_v0 0.339
	#define cubeUV_m0 - 2.0
	#define cubeUV_r1 0.8
	#define cubeUV_v1 0.276
	#define cubeUV_m1 - 1.0
	#define cubeUV_r4 0.4
	#define cubeUV_v4 0.046
	#define cubeUV_m4 2.0
	#define cubeUV_r5 0.305
	#define cubeUV_v5 0.016
	#define cubeUV_m5 3.0
	#define cubeUV_r6 0.21
	#define cubeUV_v6 0.0038
	#define cubeUV_m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= cubeUV_r1 ) {
			mip = ( cubeUV_r0 - roughness ) * ( cubeUV_m1 - cubeUV_m0 ) / ( cubeUV_r0 - cubeUV_r1 ) + cubeUV_m0;
		} else if ( roughness >= cubeUV_r4 ) {
			mip = ( cubeUV_r1 - roughness ) * ( cubeUV_m4 - cubeUV_m1 ) / ( cubeUV_r1 - cubeUV_r4 ) + cubeUV_m1;
		} else if ( roughness >= cubeUV_r5 ) {
			mip = ( cubeUV_r4 - roughness ) * ( cubeUV_m5 - cubeUV_m4 ) / ( cubeUV_r4 - cubeUV_r5 ) + cubeUV_m4;
		} else if ( roughness >= cubeUV_r6 ) {
			mip = ( cubeUV_r5 - roughness ) * ( cubeUV_m6 - cubeUV_m5 ) / ( cubeUV_r5 - cubeUV_r6 ) + cubeUV_m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
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
#endif`, Yp = `vec3 transformedNormal = objectNormal;
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
#endif`, Zp = `#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`, Jp = `#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`, $p = `#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`, Kp = `#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`, Qp = "gl_FragColor = linearToOutputTexel( gl_FragColor );", jp = `
const mat3 LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = mat3(
	vec3( 0.8224621, 0.177538, 0.0 ),
	vec3( 0.0331941, 0.9668058, 0.0 ),
	vec3( 0.0170827, 0.0723974, 0.9105199 )
);
const mat3 LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = mat3(
	vec3( 1.2249401, - 0.2249404, 0.0 ),
	vec3( - 0.0420569, 1.0420571, 0.0 ),
	vec3( - 0.0196376, - 0.0786361, 1.0982735 )
);
vec4 LinearSRGBToLinearDisplayP3( in vec4 value ) {
	return vec4( value.rgb * LINEAR_SRGB_TO_LINEAR_DISPLAY_P3, value.a );
}
vec4 LinearDisplayP3ToLinearSRGB( in vec4 value ) {
	return vec4( value.rgb * LINEAR_DISPLAY_P3_TO_LINEAR_SRGB, value.a );
}
vec4 LinearTransferOETF( in vec4 value ) {
	return value;
}
vec4 sRGBTransferOETF( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}
vec4 LinearToLinear( in vec4 value ) {
	return value;
}
vec4 LinearTosRGB( in vec4 value ) {
	return sRGBTransferOETF( value );
}`, em = `#ifdef USE_ENVMAP
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
#endif`, tm = `#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`, nm = `#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`, im = `#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`, sm = `#ifdef USE_ENVMAP
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
#endif`, rm = `#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`, am = `#ifdef USE_FOG
	varying float vFogDepth;
#endif`, om = `#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`, cm = `#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`, lm = `#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );
	#endif
}`, hm = `#ifdef USE_LIGHTMAP
	vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
	vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
	reflectedLight.indirectDiffuse += lightMapIrradiance;
#endif`, um = `#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`, dm = `LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`, fm = `varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`, pm = `uniform bool receiveShadow;
uniform vec3 ambientLightColor;
#if defined( USE_LIGHT_PROBES )
	uniform vec3 lightProbe[ 9 ];
#endif
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
	#if defined ( LEGACY_LIGHTS )
		if ( cutoffDistance > 0.0 && decayExponent > 0.0 ) {
			return pow( saturate( - lightDistance / cutoffDistance + 1.0 ), decayExponent );
		}
		return 1.0;
	#else
		float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
		if ( cutoffDistance > 0.0 ) {
			distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
		}
		return distanceFalloff;
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
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
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
	void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometryPosition;
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
	void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometryPosition;
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
#endif`, mm = `#ifdef USE_ENVMAP
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 reflectVec = reflect( - viewDir, normal );
			reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
			reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	#ifdef USE_ANISOTROPY
		vec3 getIBLAnisotropyRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 bentNormal = cross( bitangent, viewDir );
				bentNormal = normalize( cross( bentNormal, bitangent ) );
				bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
				return getIBLRadiance( viewDir, bentNormal, roughness );
			#else
				return vec3( 0.0 );
			#endif
		}
	#endif
#endif`, gm = `ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`, _m = `varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`, xm = `BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`, vm = `varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`, ym = `PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	material.ior = ior;
	#ifdef USE_SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULAR_COLORMAP
			specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;
		#endif
		#ifdef USE_SPECULAR_INTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );
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
		material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_IRIDESCENCE
	material.iridescence = iridescence;
	material.iridescenceIOR = iridescenceIOR;
	#ifdef USE_IRIDESCENCEMAP
		material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;
	#endif
	#ifdef USE_IRIDESCENCE_THICKNESSMAP
		material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;
	#else
		material.iridescenceThickness = iridescenceThicknessMaximum;
	#endif
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEEN_COLORMAP
		material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );
	#ifdef USE_SHEEN_ROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;
	#endif
#endif
#ifdef USE_ANISOTROPY
	#ifdef USE_ANISOTROPYMAP
		mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
		vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
		vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;
	#else
		vec2 anisotropyV = anisotropyVector;
	#endif
	material.anisotropy = length( anisotropyV );
	anisotropyV /= material.anisotropy;
	material.anisotropy = saturate( material.anisotropy );
	material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );
	material.anisotropyT = tbn[ 0 ] * anisotropyV.x - tbn[ 1 ] * anisotropyV.y;
	material.anisotropyB = tbn[ 1 ] * anisotropyV.x + tbn[ 0 ] * anisotropyV.y;
#endif`, Mm = `struct PhysicalMaterial {
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
	#ifdef USE_IRIDESCENCE
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
	#ifdef IOR
		float ior;
	#endif
	#ifdef USE_TRANSMISSION
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#endif
	#ifdef USE_ANISOTROPY
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#endif
};
vec3 clearcoatSpecular = vec3( 0.0 );
vec3 sheenSpecular = vec3( 0.0 );
vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
    float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
    float x2 = x * x;
    float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );
    return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
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
#ifdef USE_ANISOTROPY
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		float v = 0.5 / ( gv + gl );
		return saturate(v);
	}
	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;
		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#endif
#ifdef USE_CLEARCOAT
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;
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
#endif
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColor;
	float f90 = material.specularF90;
	float roughness = material.roughness;
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	#ifdef USE_IRIDESCENCE
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#endif
	#ifdef USE_ANISOTROPY
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );
		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );
		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#endif
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
#endif
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
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
#ifdef USE_IRIDESCENCE
void computeMultiscatteringIridescence( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#else
void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#endif
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	#ifdef USE_IRIDESCENCE
		vec3 Fr = mix( specularColor, iridescenceF0, iridescence );
	#else
		vec3 Fr = specularColor;
	#endif
	vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometryNormal;
		vec3 viewDir = geometryViewDir;
		vec3 position = geometryPosition;
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
void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometryClearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecular += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
		sheenSpecular += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecular += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecular += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
	#endif
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );
	#else
		computeMultiscattering( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
	#endif
	vec3 totalScattering = singleScattering + multiScattering;
	vec3 diffuse = material.diffuseColor * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
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
}`, Sm = `
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
vec3 geometryClearcoatNormal;
#ifdef USE_CLEARCOAT
	geometryClearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
	}
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
		getPointLightInfo( pointLight, geometryPosition, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometryPosition, directLight );
		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
		#else
		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#endif
		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );
			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		#endif
		#undef SPOT_LIGHT_MAP_INDEX
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
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
		getDirectionalLightInfo( directionalLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	#if defined( USE_LIGHT_PROBES )
		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
	#endif
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
		}
		#pragma unroll_loop_end
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`, bm = `#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometryNormal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );
	#endif
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`, Em = `#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif`, Tm = `#if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )
	gl_FragDepthEXT = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`, wm = `#if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`, Am = `#ifdef USE_LOGDEPTHBUF
	#ifdef USE_LOGDEPTHBUF_EXT
		varying float vFragDepth;
		varying float vIsPerspective;
	#else
		uniform float logDepthBufFC;
	#endif
#endif`, Rm = `#ifdef USE_LOGDEPTHBUF
	#ifdef USE_LOGDEPTHBUF_EXT
		vFragDepth = 1.0 + gl_Position.w;
		vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
	#else
		if ( isPerspectiveMatrix( projectionMatrix ) ) {
			gl_Position.z = log2( max( EPSILON, gl_Position.w + 1.0 ) ) * logDepthBufFC - 1.0;
			gl_Position.z *= gl_Position.w;
		}
	#endif
#endif`, Cm = `#ifdef USE_MAP
	vec4 sampledDiffuseColor = texture2D( map, vMapUv );
	#ifdef DECODE_VIDEO_TEXTURE
		sampledDiffuseColor = vec4( mix( pow( sampledDiffuseColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), sampledDiffuseColor.rgb * 0.0773993808, vec3( lessThanEqual( sampledDiffuseColor.rgb, vec3( 0.04045 ) ) ) ), sampledDiffuseColor.w );
	
	#endif
	diffuseColor *= sampledDiffuseColor;
#endif`, Pm = `#ifdef USE_MAP
	uniform sampler2D map;
#endif`, Lm = `#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	#if defined( USE_POINTS_UV )
		vec2 uv = vUv;
	#else
		vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
	#endif
#endif
#ifdef USE_MAP
	diffuseColor *= texture2D( map, uv );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`, Im = `#if defined( USE_POINTS_UV )
	varying vec2 vUv;
#else
	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
		uniform mat3 uvTransform;
	#endif
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`, Um = `float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`, Dm = `#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`, Nm = `#if defined( USE_MORPHCOLORS ) && defined( MORPHTARGETS_TEXTURE )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`, Om = `#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	#ifdef MORPHTARGETS_TEXTURE
		for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
			if ( morphTargetInfluences[ i ] != 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1 ).xyz * morphTargetInfluences[ i ];
		}
	#else
		objectNormal += morphNormal0 * morphTargetInfluences[ 0 ];
		objectNormal += morphNormal1 * morphTargetInfluences[ 1 ];
		objectNormal += morphNormal2 * morphTargetInfluences[ 2 ];
		objectNormal += morphNormal3 * morphTargetInfluences[ 3 ];
	#endif
#endif`, Fm = `#ifdef USE_MORPHTARGETS
	uniform float morphTargetBaseInfluence;
	#ifdef MORPHTARGETS_TEXTURE
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
		uniform sampler2DArray morphTargetsTexture;
		uniform ivec2 morphTargetsTextureSize;
		vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {
			int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
			int y = texelIndex / morphTargetsTextureSize.x;
			int x = texelIndex - y * morphTargetsTextureSize.x;
			ivec3 morphUV = ivec3( x, y, morphTargetIndex );
			return texelFetch( morphTargetsTexture, morphUV, 0 );
		}
	#else
		#ifndef USE_MORPHNORMALS
			uniform float morphTargetInfluences[ 8 ];
		#else
			uniform float morphTargetInfluences[ 4 ];
		#endif
	#endif
#endif`, Bm = `#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	#ifdef MORPHTARGETS_TEXTURE
		for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
			if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];
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
#endif`, zm = `float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal *= faceDirection;
	#endif
#endif
#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )
	#ifdef USE_TANGENT
		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;
	#endif
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	#ifdef USE_TANGENT
		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;
	#endif
#endif
vec3 nonPerturbedNormal = normal;`, Vm = `#ifdef USE_NORMALMAP_OBJECTSPACE
	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( USE_NORMALMAP_TANGENTSPACE )
	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;
	normal = normalize( tbn * mapN );
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`, km = `#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`, Hm = `#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`, Gm = `#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`, Wm = `#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef USE_NORMALMAP_OBJECTSPACE
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
	mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
		vec3 q0 = dFdx( eye_pos.xyz );
		vec3 q1 = dFdy( eye_pos.xyz );
		vec2 st0 = dFdx( uv.st );
		vec2 st1 = dFdy( uv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
		return mat3( T * scale, B * scale, N );
	}
#endif`, Xm = `#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = nonPerturbedNormal;
#endif`, qm = `#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`, Ym = `#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`, Zm = `#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`, Jm = `#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`, $m = `vec3 packNormalToRGB( const in vec3 normal ) {
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
vec2 packDepthToRG( in highp float v ) {
	return packDepthToRGBA( v ).yx;
}
float unpackRGToDepth( const in highp vec2 v ) {
	return unpackRGBAToDepth( vec4( v.xy, 0.0, 0.0 ) );
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
float orthographicDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return depth * ( near - far ) - near;
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return ( near * far ) / ( ( far - near ) * depth - far );
}`, Km = `#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`, Qm = `vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`, jm = `#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`, eg = `#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`, tg = `float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`, ng = `#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`, ig = `#if NUM_SPOT_LIGHT_COORDS > 0
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#if NUM_SPOT_LIGHT_MAPS > 0
	uniform sampler2D spotLightMap[ NUM_SPOT_LIGHT_MAPS ];
#endif
#ifdef USE_SHADOWMAP
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
		bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
		bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
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
#endif`, sg = `#if NUM_SPOT_LIGHT_COORDS > 0
	uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#ifdef USE_SHADOWMAP
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
#endif`, rg = `#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
	vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
	vec4 shadowWorldPosition;
#endif
#if defined( USE_SHADOWMAP )
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
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
#endif
#if NUM_SPOT_LIGHT_COORDS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {
		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;
		#endif
		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
#endif`, ag = `float getShadowMask() {
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
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
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
}`, og = `#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`, cg = `#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
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
#endif`, lg = `#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`, hg = `#ifdef USE_SKINNING
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
#endif`, ug = `float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`, dg = `#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`, fg = `#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`, pg = `#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return saturate( toneMappingExposure * color );
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
vec3 CustomToneMapping( vec3 color ) { return color; }`, mg = `#ifdef USE_TRANSMISSION
	material.transmission = transmission;
	material.transmissionAlpha = 1.0;
	material.thickness = thickness;
	material.attenuationDistance = attenuationDistance;
	material.attenuationColor = attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = inverseTransformDirection( normal, viewMatrix );
	vec4 transmitted = getIBLVolumeRefraction(
		n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, material.ior, material.thickness,
		material.attenuationColor, material.attenuationDistance );
	material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );
	totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );
#endif`, gg = `#ifdef USE_TRANSMISSION
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
	float w0( float a ) {
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );
	}
	float w1( float a ) {
		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );
	}
	float w2( float a ){
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );
	}
	float w3( float a ) {
		return ( 1.0 / 6.0 ) * ( a * a * a );
	}
	float g0( float a ) {
		return w0( a ) + w1( a );
	}
	float g1( float a ) {
		return w2( a ) + w3( a );
	}
	float h0( float a ) {
		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );
	}
	float h1( float a ) {
		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );
	}
	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {
		uv = uv * texelSize.zw + 0.5;
		vec2 iuv = floor( uv );
		vec2 fuv = fract( uv );
		float g0x = g0( fuv.x );
		float g1x = g1( fuv.x );
		float h0x = h0( fuv.x );
		float h1x = h1( fuv.x );
		float h0y = h0( fuv.y );
		float h1y = h1( fuv.y );
		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +
			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );
	}
	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {
		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );
		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );
		vec2 fLodSizeInv = 1.0 / fLodSize;
		vec2 cLodSizeInv = 1.0 / cLodSize;
		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );
		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );
		return mix( fSample, cSample, fract( lod ) );
	}
	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( const in float roughness, const in float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {
		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );
	}
	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {
		if ( isinf( attenuationDistance ) ) {
			return vec3( 1.0 );
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance;
		}
	}
	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,
		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,
		const in mat4 viewMatrix, const in mat4 projMatrix, const in float ior, const in float thickness,
		const in vec3 attenuationColor, const in float attenuationDistance ) {
		vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
		vec3 refractedRayExit = position + transmissionRay;
		vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
		vec2 refractionCoords = ndcPos.xy / ndcPos.w;
		refractionCoords += 1.0;
		refractionCoords /= 2.0;
		vec4 transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
		vec3 transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );
		vec3 attenuatedColor = transmittance * transmittedLight.rgb;
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;
		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );
	}
#endif`, _g = `#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_SPECULARMAP
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`, xg = `#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	uniform mat3 mapTransform;
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	uniform mat3 alphaMapTransform;
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	uniform mat3 lightMapTransform;
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	uniform mat3 aoMapTransform;
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	uniform mat3 bumpMapTransform;
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	uniform mat3 normalMapTransform;
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_DISPLACEMENTMAP
	uniform mat3 displacementMapTransform;
	varying vec2 vDisplacementMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	uniform mat3 emissiveMapTransform;
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	uniform mat3 metalnessMapTransform;
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	uniform mat3 roughnessMapTransform;
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	uniform mat3 anisotropyMapTransform;
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	uniform mat3 clearcoatMapTransform;
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform mat3 clearcoatNormalMapTransform;
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform mat3 clearcoatRoughnessMapTransform;
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	uniform mat3 sheenColorMapTransform;
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	uniform mat3 sheenRoughnessMapTransform;
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	uniform mat3 iridescenceMapTransform;
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform mat3 iridescenceThicknessMapTransform;
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SPECULARMAP
	uniform mat3 specularMapTransform;
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	uniform mat3 specularColorMapTransform;
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	uniform mat3 specularIntensityMapTransform;
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`, vg = `#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	vUv = vec3( uv, 1 ).xy;
#endif
#ifdef USE_MAP
	vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ALPHAMAP
	vAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_LIGHTMAP
	vLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_AOMAP
	vAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_BUMPMAP
	vBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_NORMALMAP
	vNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_DISPLACEMENTMAP
	vDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_EMISSIVEMAP
	vEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_METALNESSMAP
	vMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ROUGHNESSMAP
	vRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ANISOTROPYMAP
	vAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOATMAP
	vClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	vClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	vClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCEMAP
	vIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	vIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_COLORMAP
	vSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	vSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULARMAP
	vSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_COLORMAP
	vSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	vSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_TRANSMISSIONMAP
	vTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_THICKNESSMAP
	vThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;
#endif`, yg = `#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`, Mg = `varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`, Sg = `uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	#ifdef DECODE_VIDEO_TEXTURE
		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, bg = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`, Eg = `#ifdef ENVMAP_TYPE_CUBE
	uniform samplerCube envMap;
#elif defined( ENVMAP_TYPE_CUBE_UV )
	uniform sampler2D envMap;
#endif
uniform float flipEnvMap;
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	#ifdef ENVMAP_TYPE_CUBE
		vec4 texColor = textureCube( envMap, vec3( flipEnvMap * vWorldDirection.x, vWorldDirection.yz ) );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 texColor = textureCubeUV( envMap, vWorldDirection, backgroundBlurriness );
	#else
		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, Tg = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`, wg = `uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, Ag = `#include <common>
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
}`, Rg = `#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
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
	#include <alphahash_fragment>
	#include <logdepthbuf_fragment>
	float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#endif
}`, Cg = `#define DISTANCE
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
}`, Pg = `#define DISTANCE
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
#include <alphahash_pars_fragment>
#include <clipping_planes_pars_fragment>
void main () {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( 1.0 );
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = packDepthToRGBA( dist );
}`, Lg = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`, Ig = `uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, Ug = `uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`, Dg = `uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
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
	#include <map_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`, Ng = `#include <common>
#include <uv_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
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
}`, Og = `uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
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
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Fg = `#define LAMBERT
varying vec3 vViewPosition;
#include <common>
#include <uv_pars_vertex>
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
	#include <color_vertex>
	#include <morphcolor_vertex>
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
}`, Bg = `#define LAMBERT
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
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
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, zg = `#define MATCAP
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
	#include <morphcolor_vertex>
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
}`, Vg = `#define MATCAP
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
#include <alphahash_pars_fragment>
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
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
	#else
		vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, kg = `#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
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
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	vViewPosition = - mvPosition.xyz;
#endif
}`, Hg = `#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
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
	#ifdef OPAQUE
		gl_FragColor.a = 1.0;
	#endif
}`, Gg = `#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <uv_pars_vertex>
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
	#include <color_vertex>
	#include <morphcolor_vertex>
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
}`, Wg = `#define PHONG
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
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
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
	#include <alphahash_fragment>
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
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Xg = `#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <uv_pars_vertex>
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
	#include <color_vertex>
	#include <morphcolor_vertex>
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
}`, qg = `#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define USE_SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef USE_SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULAR_COLORMAP
		uniform sampler2D specularColorMap;
	#endif
	#ifdef USE_SPECULAR_INTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_IRIDESCENCE
	uniform float iridescence;
	uniform float iridescenceIOR;
	uniform float iridescenceThicknessMinimum;
	uniform float iridescenceThicknessMaximum;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEEN_COLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEEN_ROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
#ifdef USE_ANISOTROPY
	uniform vec2 anisotropyVector;
	#ifdef USE_ANISOTROPYMAP
		uniform sampler2D anisotropyMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <iridescence_fragment>
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
#include <iridescence_pars_fragment>
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
	#include <alphahash_fragment>
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
		float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + clearcoatSpecular * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Yg = `#define TOON
varying vec3 vViewPosition;
#include <common>
#include <uv_pars_vertex>
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
	#include <color_vertex>
	#include <morphcolor_vertex>
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
}`, Zg = `#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
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
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Jg = `uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
#ifdef USE_POINTS_UV
	varying vec2 vUv;
	uniform mat3 uvTransform;
#endif
void main() {
	#ifdef USE_POINTS_UV
		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	#endif
	#include <color_vertex>
	#include <morphcolor_vertex>
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
}`, $g = `uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
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
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`, Kg = `#include <common>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
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
	#include <logdepthbuf_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`, Qg = `uniform vec3 color;
uniform float opacity;
#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	#include <logdepthbuf_fragment>
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`, jg = `uniform float rotation;
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
}`, e_ = `uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
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
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`, ke = {
    alphahash_fragment: Ep,
    alphahash_pars_fragment: Tp,
    alphamap_fragment: wp,
    alphamap_pars_fragment: Ap,
    alphatest_fragment: Rp,
    alphatest_pars_fragment: Cp,
    aomap_fragment: Pp,
    aomap_pars_fragment: Lp,
    begin_vertex: Ip,
    beginnormal_vertex: Up,
    bsdfs: Dp,
    iridescence_fragment: Np,
    bumpmap_pars_fragment: Op,
    clipping_planes_fragment: Fp,
    clipping_planes_pars_fragment: Bp,
    clipping_planes_pars_vertex: zp,
    clipping_planes_vertex: Vp,
    color_fragment: kp,
    color_pars_fragment: Hp,
    color_pars_vertex: Gp,
    color_vertex: Wp,
    common: Xp,
    cube_uv_reflection_fragment: qp,
    defaultnormal_vertex: Yp,
    displacementmap_pars_vertex: Zp,
    displacementmap_vertex: Jp,
    emissivemap_fragment: $p,
    emissivemap_pars_fragment: Kp,
    colorspace_fragment: Qp,
    colorspace_pars_fragment: jp,
    envmap_fragment: em,
    envmap_common_pars_fragment: tm,
    envmap_pars_fragment: nm,
    envmap_pars_vertex: im,
    envmap_physical_pars_fragment: mm,
    envmap_vertex: sm,
    fog_vertex: rm,
    fog_pars_vertex: am,
    fog_fragment: om,
    fog_pars_fragment: cm,
    gradientmap_pars_fragment: lm,
    lightmap_fragment: hm,
    lightmap_pars_fragment: um,
    lights_lambert_fragment: dm,
    lights_lambert_pars_fragment: fm,
    lights_pars_begin: pm,
    lights_toon_fragment: gm,
    lights_toon_pars_fragment: _m,
    lights_phong_fragment: xm,
    lights_phong_pars_fragment: vm,
    lights_physical_fragment: ym,
    lights_physical_pars_fragment: Mm,
    lights_fragment_begin: Sm,
    lights_fragment_maps: bm,
    lights_fragment_end: Em,
    logdepthbuf_fragment: Tm,
    logdepthbuf_pars_fragment: wm,
    logdepthbuf_pars_vertex: Am,
    logdepthbuf_vertex: Rm,
    map_fragment: Cm,
    map_pars_fragment: Pm,
    map_particle_fragment: Lm,
    map_particle_pars_fragment: Im,
    metalnessmap_fragment: Um,
    metalnessmap_pars_fragment: Dm,
    morphcolor_vertex: Nm,
    morphnormal_vertex: Om,
    morphtarget_pars_vertex: Fm,
    morphtarget_vertex: Bm,
    normal_fragment_begin: zm,
    normal_fragment_maps: Vm,
    normal_pars_fragment: km,
    normal_pars_vertex: Hm,
    normal_vertex: Gm,
    normalmap_pars_fragment: Wm,
    clearcoat_normal_fragment_begin: Xm,
    clearcoat_normal_fragment_maps: qm,
    clearcoat_pars_fragment: Ym,
    iridescence_pars_fragment: Zm,
    opaque_fragment: Jm,
    packing: $m,
    premultiplied_alpha_fragment: Km,
    project_vertex: Qm,
    dithering_fragment: jm,
    dithering_pars_fragment: eg,
    roughnessmap_fragment: tg,
    roughnessmap_pars_fragment: ng,
    shadowmap_pars_fragment: ig,
    shadowmap_pars_vertex: sg,
    shadowmap_vertex: rg,
    shadowmask_pars_fragment: ag,
    skinbase_vertex: og,
    skinning_pars_vertex: cg,
    skinning_vertex: lg,
    skinnormal_vertex: hg,
    specularmap_fragment: ug,
    specularmap_pars_fragment: dg,
    tonemapping_fragment: fg,
    tonemapping_pars_fragment: pg,
    transmission_fragment: mg,
    transmission_pars_fragment: gg,
    uv_pars_fragment: _g,
    uv_pars_vertex: xg,
    uv_vertex: vg,
    worldpos_vertex: yg,
    background_vert: Mg,
    background_frag: Sg,
    backgroundCube_vert: bg,
    backgroundCube_frag: Eg,
    cube_vert: Tg,
    cube_frag: wg,
    depth_vert: Ag,
    depth_frag: Rg,
    distanceRGBA_vert: Cg,
    distanceRGBA_frag: Pg,
    equirect_vert: Lg,
    equirect_frag: Ig,
    linedashed_vert: Ug,
    linedashed_frag: Dg,
    meshbasic_vert: Ng,
    meshbasic_frag: Og,
    meshlambert_vert: Fg,
    meshlambert_frag: Bg,
    meshmatcap_vert: zg,
    meshmatcap_frag: Vg,
    meshnormal_vert: kg,
    meshnormal_frag: Hg,
    meshphong_vert: Gg,
    meshphong_frag: Wg,
    meshphysical_vert: Xg,
    meshphysical_frag: qg,
    meshtoon_vert: Yg,
    meshtoon_frag: Zg,
    points_vert: Jg,
    points_frag: $g,
    shadow_vert: Kg,
    shadow_frag: Qg,
    sprite_vert: jg,
    sprite_frag: e_
}, le = {
    common: {
        diffuse: {
            value: new pe(16777215)
        },
        opacity: {
            value: 1
        },
        map: {
            value: null
        },
        mapTransform: {
            value: new He
        },
        alphaMap: {
            value: null
        },
        alphaMapTransform: {
            value: new He
        },
        alphaTest: {
            value: 0
        }
    },
    specularmap: {
        specularMap: {
            value: null
        },
        specularMapTransform: {
            value: new He
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
        },
        aoMapTransform: {
            value: new He
        }
    },
    lightmap: {
        lightMap: {
            value: null
        },
        lightMapIntensity: {
            value: 1
        },
        lightMapTransform: {
            value: new He
        }
    },
    bumpmap: {
        bumpMap: {
            value: null
        },
        bumpMapTransform: {
            value: new He
        },
        bumpScale: {
            value: 1
        }
    },
    normalmap: {
        normalMap: {
            value: null
        },
        normalMapTransform: {
            value: new He
        },
        normalScale: {
            value: new Z(1, 1)
        }
    },
    displacementmap: {
        displacementMap: {
            value: null
        },
        displacementMapTransform: {
            value: new He
        },
        displacementScale: {
            value: 1
        },
        displacementBias: {
            value: 0
        }
    },
    emissivemap: {
        emissiveMap: {
            value: null
        },
        emissiveMapTransform: {
            value: new He
        }
    },
    metalnessmap: {
        metalnessMap: {
            value: null
        },
        metalnessMapTransform: {
            value: new He
        }
    },
    roughnessmap: {
        roughnessMap: {
            value: null
        },
        roughnessMapTransform: {
            value: new He
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
            value: new pe(16777215)
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
        spotLightMap: {
            value: []
        },
        spotShadowMap: {
            value: []
        },
        spotLightMatrix: {
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
            value: new pe(16777215)
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
        alphaMapTransform: {
            value: new He
        },
        alphaTest: {
            value: 0
        },
        uvTransform: {
            value: new He
        }
    },
    sprite: {
        diffuse: {
            value: new pe(16777215)
        },
        opacity: {
            value: 1
        },
        center: {
            value: new Z(.5, .5)
        },
        rotation: {
            value: 0
        },
        map: {
            value: null
        },
        mapTransform: {
            value: new He
        },
        alphaMap: {
            value: null
        },
        alphaMapTransform: {
            value: new He
        },
        alphaTest: {
            value: 0
        }
    }
}, nn = {
    basic: {
        uniforms: Lt([
            le.common,
            le.specularmap,
            le.envmap,
            le.aomap,
            le.lightmap,
            le.fog
        ]),
        vertexShader: ke.meshbasic_vert,
        fragmentShader: ke.meshbasic_frag
    },
    lambert: {
        uniforms: Lt([
            le.common,
            le.specularmap,
            le.envmap,
            le.aomap,
            le.lightmap,
            le.emissivemap,
            le.bumpmap,
            le.normalmap,
            le.displacementmap,
            le.fog,
            le.lights,
            {
                emissive: {
                    value: new pe(0)
                }
            }
        ]),
        vertexShader: ke.meshlambert_vert,
        fragmentShader: ke.meshlambert_frag
    },
    phong: {
        uniforms: Lt([
            le.common,
            le.specularmap,
            le.envmap,
            le.aomap,
            le.lightmap,
            le.emissivemap,
            le.bumpmap,
            le.normalmap,
            le.displacementmap,
            le.fog,
            le.lights,
            {
                emissive: {
                    value: new pe(0)
                },
                specular: {
                    value: new pe(1118481)
                },
                shininess: {
                    value: 30
                }
            }
        ]),
        vertexShader: ke.meshphong_vert,
        fragmentShader: ke.meshphong_frag
    },
    standard: {
        uniforms: Lt([
            le.common,
            le.envmap,
            le.aomap,
            le.lightmap,
            le.emissivemap,
            le.bumpmap,
            le.normalmap,
            le.displacementmap,
            le.roughnessmap,
            le.metalnessmap,
            le.fog,
            le.lights,
            {
                emissive: {
                    value: new pe(0)
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
        vertexShader: ke.meshphysical_vert,
        fragmentShader: ke.meshphysical_frag
    },
    toon: {
        uniforms: Lt([
            le.common,
            le.aomap,
            le.lightmap,
            le.emissivemap,
            le.bumpmap,
            le.normalmap,
            le.displacementmap,
            le.gradientmap,
            le.fog,
            le.lights,
            {
                emissive: {
                    value: new pe(0)
                }
            }
        ]),
        vertexShader: ke.meshtoon_vert,
        fragmentShader: ke.meshtoon_frag
    },
    matcap: {
        uniforms: Lt([
            le.common,
            le.bumpmap,
            le.normalmap,
            le.displacementmap,
            le.fog,
            {
                matcap: {
                    value: null
                }
            }
        ]),
        vertexShader: ke.meshmatcap_vert,
        fragmentShader: ke.meshmatcap_frag
    },
    points: {
        uniforms: Lt([
            le.points,
            le.fog
        ]),
        vertexShader: ke.points_vert,
        fragmentShader: ke.points_frag
    },
    dashed: {
        uniforms: Lt([
            le.common,
            le.fog,
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
        vertexShader: ke.linedashed_vert,
        fragmentShader: ke.linedashed_frag
    },
    depth: {
        uniforms: Lt([
            le.common,
            le.displacementmap
        ]),
        vertexShader: ke.depth_vert,
        fragmentShader: ke.depth_frag
    },
    normal: {
        uniforms: Lt([
            le.common,
            le.bumpmap,
            le.normalmap,
            le.displacementmap,
            {
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: ke.meshnormal_vert,
        fragmentShader: ke.meshnormal_frag
    },
    sprite: {
        uniforms: Lt([
            le.sprite,
            le.fog
        ]),
        vertexShader: ke.sprite_vert,
        fragmentShader: ke.sprite_frag
    },
    background: {
        uniforms: {
            uvTransform: {
                value: new He
            },
            t2D: {
                value: null
            },
            backgroundIntensity: {
                value: 1
            }
        },
        vertexShader: ke.background_vert,
        fragmentShader: ke.background_frag
    },
    backgroundCube: {
        uniforms: {
            envMap: {
                value: null
            },
            flipEnvMap: {
                value: -1
            },
            backgroundBlurriness: {
                value: 0
            },
            backgroundIntensity: {
                value: 1
            }
        },
        vertexShader: ke.backgroundCube_vert,
        fragmentShader: ke.backgroundCube_frag
    },
    cube: {
        uniforms: {
            tCube: {
                value: null
            },
            tFlip: {
                value: -1
            },
            opacity: {
                value: 1
            }
        },
        vertexShader: ke.cube_vert,
        fragmentShader: ke.cube_frag
    },
    equirect: {
        uniforms: {
            tEquirect: {
                value: null
            }
        },
        vertexShader: ke.equirect_vert,
        fragmentShader: ke.equirect_frag
    },
    distanceRGBA: {
        uniforms: Lt([
            le.common,
            le.displacementmap,
            {
                referencePosition: {
                    value: new A
                },
                nearDistance: {
                    value: 1
                },
                farDistance: {
                    value: 1e3
                }
            }
        ]),
        vertexShader: ke.distanceRGBA_vert,
        fragmentShader: ke.distanceRGBA_frag
    },
    shadow: {
        uniforms: Lt([
            le.lights,
            le.fog,
            {
                color: {
                    value: new pe(0)
                },
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: ke.shadow_vert,
        fragmentShader: ke.shadow_frag
    }
};
nn.physical = {
    uniforms: Lt([
        nn.standard.uniforms,
        {
            clearcoat: {
                value: 0
            },
            clearcoatMap: {
                value: null
            },
            clearcoatMapTransform: {
                value: new He
            },
            clearcoatNormalMap: {
                value: null
            },
            clearcoatNormalMapTransform: {
                value: new He
            },
            clearcoatNormalScale: {
                value: new Z(1, 1)
            },
            clearcoatRoughness: {
                value: 0
            },
            clearcoatRoughnessMap: {
                value: null
            },
            clearcoatRoughnessMapTransform: {
                value: new He
            },
            iridescence: {
                value: 0
            },
            iridescenceMap: {
                value: null
            },
            iridescenceMapTransform: {
                value: new He
            },
            iridescenceIOR: {
                value: 1.3
            },
            iridescenceThicknessMinimum: {
                value: 100
            },
            iridescenceThicknessMaximum: {
                value: 400
            },
            iridescenceThicknessMap: {
                value: null
            },
            iridescenceThicknessMapTransform: {
                value: new He
            },
            sheen: {
                value: 0
            },
            sheenColor: {
                value: new pe(0)
            },
            sheenColorMap: {
                value: null
            },
            sheenColorMapTransform: {
                value: new He
            },
            sheenRoughness: {
                value: 1
            },
            sheenRoughnessMap: {
                value: null
            },
            sheenRoughnessMapTransform: {
                value: new He
            },
            transmission: {
                value: 0
            },
            transmissionMap: {
                value: null
            },
            transmissionMapTransform: {
                value: new He
            },
            transmissionSamplerSize: {
                value: new Z
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
            thicknessMapTransform: {
                value: new He
            },
            attenuationDistance: {
                value: 0
            },
            attenuationColor: {
                value: new pe(0)
            },
            specularColor: {
                value: new pe(1, 1, 1)
            },
            specularColorMap: {
                value: null
            },
            specularColorMapTransform: {
                value: new He
            },
            specularIntensity: {
                value: 1
            },
            specularIntensityMap: {
                value: null
            },
            specularIntensityMapTransform: {
                value: new He
            },
            anisotropyVector: {
                value: new Z
            },
            anisotropyMap: {
                value: null
            },
            anisotropyMapTransform: {
                value: new He
            }
        }
    ]),
    vertexShader: ke.meshphysical_vert,
    fragmentShader: ke.meshphysical_frag
};
var cr = {
    r: 0,
    b: 0,
    g: 0
};
function t_(s1, e, t, n, i, r, a) {
    let o = new pe(0), c = r === !0 ? 0 : 1, l, h, u = null, d = 0, f = null;
    function m(g, p) {
        let v = !1, x = p.isScene === !0 ? p.background : null;
        x && x.isTexture && (x = (p.backgroundBlurriness > 0 ? t : e).get(x)), x === null ? _(o, c) : x && x.isColor && (_(x, 1), v = !0);
        let y = s1.xr.getEnvironmentBlendMode();
        y === "additive" ? n.buffers.color.setClear(0, 0, 0, 1, a) : y === "alpha-blend" && n.buffers.color.setClear(0, 0, 0, 0, a), (s1.autoClear || v) && s1.clear(s1.autoClearColor, s1.autoClearDepth, s1.autoClearStencil), x && (x.isCubeTexture || x.mapping === Vs) ? (h === void 0 && (h = new Mt(new Ji(1, 1, 1), new jt({
            name: "BackgroundCubeMaterial",
            uniforms: $i(nn.backgroundCube.uniforms),
            vertexShader: nn.backgroundCube.vertexShader,
            fragmentShader: nn.backgroundCube.fragmentShader,
            side: Ft,
            depthTest: !1,
            depthWrite: !1,
            fog: !1
        })), h.geometry.deleteAttribute("normal"), h.geometry.deleteAttribute("uv"), h.onBeforeRender = function(b, w, R) {
            this.matrixWorld.copyPosition(R.matrixWorld);
        }, Object.defineProperty(h.material, "envMap", {
            get: function() {
                return this.uniforms.envMap.value;
            }
        }), i.update(h)), h.material.uniforms.envMap.value = x, h.material.uniforms.flipEnvMap.value = x.isCubeTexture && x.isRenderTargetTexture === !1 ? -1 : 1, h.material.uniforms.backgroundBlurriness.value = p.backgroundBlurriness, h.material.uniforms.backgroundIntensity.value = p.backgroundIntensity, h.material.toneMapped = Qe.getTransfer(x.colorSpace) !== nt, (u !== x || d !== x.version || f !== s1.toneMapping) && (h.material.needsUpdate = !0, u = x, d = x.version, f = s1.toneMapping), h.layers.enableAll(), g.unshift(h, h.geometry, h.material, 0, 0, null)) : x && x.isTexture && (l === void 0 && (l = new Mt(new $r(2, 2), new jt({
            name: "BackgroundMaterial",
            uniforms: $i(nn.background.uniforms),
            vertexShader: nn.background.vertexShader,
            fragmentShader: nn.background.fragmentShader,
            side: Bn,
            depthTest: !1,
            depthWrite: !1,
            fog: !1
        })), l.geometry.deleteAttribute("normal"), Object.defineProperty(l.material, "map", {
            get: function() {
                return this.uniforms.t2D.value;
            }
        }), i.update(l)), l.material.uniforms.t2D.value = x, l.material.uniforms.backgroundIntensity.value = p.backgroundIntensity, l.material.toneMapped = Qe.getTransfer(x.colorSpace) !== nt, x.matrixAutoUpdate === !0 && x.updateMatrix(), l.material.uniforms.uvTransform.value.copy(x.matrix), (u !== x || d !== x.version || f !== s1.toneMapping) && (l.material.needsUpdate = !0, u = x, d = x.version, f = s1.toneMapping), l.layers.enableAll(), g.unshift(l, l.geometry, l.material, 0, 0, null));
    }
    function _(g, p) {
        g.getRGB(cr, bd(s1)), n.buffers.color.setClear(cr.r, cr.g, cr.b, p, a);
    }
    return {
        getClearColor: function() {
            return o;
        },
        setClearColor: function(g, p = 1) {
            o.set(g), c = p, _(o, c);
        },
        getClearAlpha: function() {
            return c;
        },
        setClearAlpha: function(g) {
            c = g, _(o, c);
        },
        render: m
    };
}
function n_(s1, e, t, n) {
    let i = s1.getParameter(s1.MAX_VERTEX_ATTRIBS), r = n.isWebGL2 ? null : e.get("OES_vertex_array_object"), a = n.isWebGL2 || r !== null, o = {}, c = g(null), l = c, h = !1;
    function u(U, z, q, H, ne) {
        let W = !1;
        if (a) {
            let K = _(H, q, z);
            l !== K && (l = K, f(l.object)), W = p(U, H, q, ne), W && v(U, H, q, ne);
        } else {
            let K = z.wireframe === !0;
            (l.geometry !== H.id || l.program !== q.id || l.wireframe !== K) && (l.geometry = H.id, l.program = q.id, l.wireframe = K, W = !0);
        }
        ne !== null && t.update(ne, s1.ELEMENT_ARRAY_BUFFER), (W || h) && (h = !1, I(U, z, q, H), ne !== null && s1.bindBuffer(s1.ELEMENT_ARRAY_BUFFER, t.get(ne).buffer));
    }
    function d() {
        return n.isWebGL2 ? s1.createVertexArray() : r.createVertexArrayOES();
    }
    function f(U) {
        return n.isWebGL2 ? s1.bindVertexArray(U) : r.bindVertexArrayOES(U);
    }
    function m(U) {
        return n.isWebGL2 ? s1.deleteVertexArray(U) : r.deleteVertexArrayOES(U);
    }
    function _(U, z, q) {
        let H = q.wireframe === !0, ne = o[U.id];
        ne === void 0 && (ne = {}, o[U.id] = ne);
        let W = ne[z.id];
        W === void 0 && (W = {}, ne[z.id] = W);
        let K = W[H];
        return K === void 0 && (K = g(d()), W[H] = K), K;
    }
    function g(U) {
        let z = [], q = [], H = [];
        for(let ne = 0; ne < i; ne++)z[ne] = 0, q[ne] = 0, H[ne] = 0;
        return {
            geometry: null,
            program: null,
            wireframe: !1,
            newAttributes: z,
            enabledAttributes: q,
            attributeDivisors: H,
            object: U,
            attributes: {},
            index: null
        };
    }
    function p(U, z, q, H) {
        let ne = l.attributes, W = z.attributes, K = 0, D = q.getAttributes();
        for(let G in D)if (D[G].location >= 0) {
            let fe = ne[G], _e = W[G];
            if (_e === void 0 && (G === "instanceMatrix" && U.instanceMatrix && (_e = U.instanceMatrix), G === "instanceColor" && U.instanceColor && (_e = U.instanceColor)), fe === void 0 || fe.attribute !== _e || _e && fe.data !== _e.data) return !0;
            K++;
        }
        return l.attributesNum !== K || l.index !== H;
    }
    function v(U, z, q, H) {
        let ne = {}, W = z.attributes, K = 0, D = q.getAttributes();
        for(let G in D)if (D[G].location >= 0) {
            let fe = W[G];
            fe === void 0 && (G === "instanceMatrix" && U.instanceMatrix && (fe = U.instanceMatrix), G === "instanceColor" && U.instanceColor && (fe = U.instanceColor));
            let _e = {};
            _e.attribute = fe, fe && fe.data && (_e.data = fe.data), ne[G] = _e, K++;
        }
        l.attributes = ne, l.attributesNum = K, l.index = H;
    }
    function x() {
        let U = l.newAttributes;
        for(let z = 0, q = U.length; z < q; z++)U[z] = 0;
    }
    function y(U) {
        b(U, 0);
    }
    function b(U, z) {
        let q = l.newAttributes, H = l.enabledAttributes, ne = l.attributeDivisors;
        q[U] = 1, H[U] === 0 && (s1.enableVertexAttribArray(U), H[U] = 1), ne[U] !== z && ((n.isWebGL2 ? s1 : e.get("ANGLE_instanced_arrays"))[n.isWebGL2 ? "vertexAttribDivisor" : "vertexAttribDivisorANGLE"](U, z), ne[U] = z);
    }
    function w() {
        let U = l.newAttributes, z = l.enabledAttributes;
        for(let q = 0, H = z.length; q < H; q++)z[q] !== U[q] && (s1.disableVertexAttribArray(q), z[q] = 0);
    }
    function R(U, z, q, H, ne, W, K) {
        K === !0 ? s1.vertexAttribIPointer(U, z, q, ne, W) : s1.vertexAttribPointer(U, z, q, H, ne, W);
    }
    function I(U, z, q, H) {
        if (n.isWebGL2 === !1 && (U.isInstancedMesh || H.isInstancedBufferGeometry) && e.get("ANGLE_instanced_arrays") === null) return;
        x();
        let ne = H.attributes, W = q.getAttributes(), K = z.defaultAttributeValues;
        for(let D in W){
            let G = W[D];
            if (G.location >= 0) {
                let he = ne[D];
                if (he === void 0 && (D === "instanceMatrix" && U.instanceMatrix && (he = U.instanceMatrix), D === "instanceColor" && U.instanceColor && (he = U.instanceColor)), he !== void 0) {
                    let fe = he.normalized, _e = he.itemSize, we = t.get(he);
                    if (we === void 0) continue;
                    let Ee = we.buffer, Te = we.type, Ye = we.bytesPerElement, it = n.isWebGL2 === !0 && (Te === s1.INT || Te === s1.UNSIGNED_INT || he.gpuType === dd);
                    if (he.isInterleavedBufferAttribute) {
                        let Ce = he.data, L = Ce.stride, oe = he.offset;
                        if (Ce.isInstancedInterleavedBuffer) {
                            for(let X = 0; X < G.locationSize; X++)b(G.location + X, Ce.meshPerAttribute);
                            U.isInstancedMesh !== !0 && H._maxInstanceCount === void 0 && (H._maxInstanceCount = Ce.meshPerAttribute * Ce.count);
                        } else for(let X = 0; X < G.locationSize; X++)y(G.location + X);
                        s1.bindBuffer(s1.ARRAY_BUFFER, Ee);
                        for(let X = 0; X < G.locationSize; X++)R(G.location + X, _e / G.locationSize, Te, fe, L * Ye, (oe + _e / G.locationSize * X) * Ye, it);
                    } else {
                        if (he.isInstancedBufferAttribute) {
                            for(let Ce = 0; Ce < G.locationSize; Ce++)b(G.location + Ce, he.meshPerAttribute);
                            U.isInstancedMesh !== !0 && H._maxInstanceCount === void 0 && (H._maxInstanceCount = he.meshPerAttribute * he.count);
                        } else for(let Ce = 0; Ce < G.locationSize; Ce++)y(G.location + Ce);
                        s1.bindBuffer(s1.ARRAY_BUFFER, Ee);
                        for(let Ce = 0; Ce < G.locationSize; Ce++)R(G.location + Ce, _e / G.locationSize, Te, fe, _e * Ye, _e / G.locationSize * Ce * Ye, it);
                    }
                } else if (K !== void 0) {
                    let fe = K[D];
                    if (fe !== void 0) switch(fe.length){
                        case 2:
                            s1.vertexAttrib2fv(G.location, fe);
                            break;
                        case 3:
                            s1.vertexAttrib3fv(G.location, fe);
                            break;
                        case 4:
                            s1.vertexAttrib4fv(G.location, fe);
                            break;
                        default:
                            s1.vertexAttrib1fv(G.location, fe);
                    }
                }
            }
        }
        w();
    }
    function M() {
        Y();
        for(let U in o){
            let z = o[U];
            for(let q in z){
                let H = z[q];
                for(let ne in H)m(H[ne].object), delete H[ne];
                delete z[q];
            }
            delete o[U];
        }
    }
    function T(U) {
        if (o[U.id] === void 0) return;
        let z = o[U.id];
        for(let q in z){
            let H = z[q];
            for(let ne in H)m(H[ne].object), delete H[ne];
            delete z[q];
        }
        delete o[U.id];
    }
    function O(U) {
        for(let z in o){
            let q = o[z];
            if (q[U.id] === void 0) continue;
            let H = q[U.id];
            for(let ne in H)m(H[ne].object), delete H[ne];
            delete q[U.id];
        }
    }
    function Y() {
        $(), h = !0, l !== c && (l = c, f(l.object));
    }
    function $() {
        c.geometry = null, c.program = null, c.wireframe = !1;
    }
    return {
        setup: u,
        reset: Y,
        resetDefaultState: $,
        dispose: M,
        releaseStatesOfGeometry: T,
        releaseStatesOfProgram: O,
        initAttributes: x,
        enableAttribute: y,
        disableUnusedAttributes: w
    };
}
function i_(s1, e, t, n) {
    let i = n.isWebGL2, r;
    function a(l) {
        r = l;
    }
    function o(l, h) {
        s1.drawArrays(r, l, h), t.update(h, r, 1);
    }
    function c(l, h, u) {
        if (u === 0) return;
        let d, f;
        if (i) d = s1, f = "drawArraysInstanced";
        else if (d = e.get("ANGLE_instanced_arrays"), f = "drawArraysInstancedANGLE", d === null) {
            console.error("THREE.WebGLBufferRenderer: using THREE.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.");
            return;
        }
        d[f](r, l, h, u), t.update(h, r, u);
    }
    this.setMode = a, this.render = o, this.renderInstances = c;
}
function s_(s1, e, t) {
    let n;
    function i() {
        if (n !== void 0) return n;
        if (e.has("EXT_texture_filter_anisotropic") === !0) {
            let R = e.get("EXT_texture_filter_anisotropic");
            n = s1.getParameter(R.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else n = 0;
        return n;
    }
    function r(R) {
        if (R === "highp") {
            if (s1.getShaderPrecisionFormat(s1.VERTEX_SHADER, s1.HIGH_FLOAT).precision > 0 && s1.getShaderPrecisionFormat(s1.FRAGMENT_SHADER, s1.HIGH_FLOAT).precision > 0) return "highp";
            R = "mediump";
        }
        return R === "mediump" && s1.getShaderPrecisionFormat(s1.VERTEX_SHADER, s1.MEDIUM_FLOAT).precision > 0 && s1.getShaderPrecisionFormat(s1.FRAGMENT_SHADER, s1.MEDIUM_FLOAT).precision > 0 ? "mediump" : "lowp";
    }
    let a = typeof WebGL2RenderingContext < "u" && s1.constructor.name === "WebGL2RenderingContext", o = t.precision !== void 0 ? t.precision : "highp", c = r(o);
    c !== o && (console.warn("THREE.WebGLRenderer:", o, "not supported, using", c, "instead."), o = c);
    let l = a || e.has("WEBGL_draw_buffers"), h = t.logarithmicDepthBuffer === !0, u = s1.getParameter(s1.MAX_TEXTURE_IMAGE_UNITS), d = s1.getParameter(s1.MAX_VERTEX_TEXTURE_IMAGE_UNITS), f = s1.getParameter(s1.MAX_TEXTURE_SIZE), m = s1.getParameter(s1.MAX_CUBE_MAP_TEXTURE_SIZE), _ = s1.getParameter(s1.MAX_VERTEX_ATTRIBS), g = s1.getParameter(s1.MAX_VERTEX_UNIFORM_VECTORS), p = s1.getParameter(s1.MAX_VARYING_VECTORS), v = s1.getParameter(s1.MAX_FRAGMENT_UNIFORM_VECTORS), x = d > 0, y = a || e.has("OES_texture_float"), b = x && y, w = a ? s1.getParameter(s1.MAX_SAMPLES) : 0;
    return {
        isWebGL2: a,
        drawBuffers: l,
        getMaxAnisotropy: i,
        getMaxPrecision: r,
        precision: o,
        logarithmicDepthBuffer: h,
        maxTextures: u,
        maxVertexTextures: d,
        maxTextureSize: f,
        maxCubemapSize: m,
        maxAttributes: _,
        maxVertexUniforms: g,
        maxVaryings: p,
        maxFragmentUniforms: v,
        vertexTextures: x,
        floatFragmentTextures: y,
        floatVertexTextures: b,
        maxSamples: w
    };
}
function r_(s1) {
    let e = this, t = null, n = 0, i = !1, r = !1, a = new mn, o = new He, c = {
        value: null,
        needsUpdate: !1
    };
    this.uniform = c, this.numPlanes = 0, this.numIntersection = 0, this.init = function(u, d) {
        let f = u.length !== 0 || d || n !== 0 || i;
        return i = d, n = u.length, f;
    }, this.beginShadows = function() {
        r = !0, h(null);
    }, this.endShadows = function() {
        r = !1;
    }, this.setGlobalState = function(u, d) {
        t = h(u, d, 0);
    }, this.setState = function(u, d, f) {
        let m = u.clippingPlanes, _ = u.clipIntersection, g = u.clipShadows, p = s1.get(u);
        if (!i || m === null || m.length === 0 || r && !g) r ? h(null) : l();
        else {
            let v = r ? 0 : n, x = v * 4, y = p.clippingState || null;
            c.value = y, y = h(m, d, x, f);
            for(let b = 0; b !== x; ++b)y[b] = t[b];
            p.clippingState = y, this.numIntersection = _ ? this.numPlanes : 0, this.numPlanes += v;
        }
    };
    function l() {
        c.value !== t && (c.value = t, c.needsUpdate = n > 0), e.numPlanes = n, e.numIntersection = 0;
    }
    function h(u, d, f, m) {
        let _ = u !== null ? u.length : 0, g = null;
        if (_ !== 0) {
            if (g = c.value, m !== !0 || g === null) {
                let p = f + _ * 4, v = d.matrixWorldInverse;
                o.getNormalMatrix(v), (g === null || g.length < p) && (g = new Float32Array(p));
                for(let x = 0, y = f; x !== _; ++x, y += 4)a.copy(u[x]).applyMatrix4(v, o), a.normal.toArray(g, y), g[y + 3] = a.constant;
            }
            c.value = g, c.needsUpdate = !0;
        }
        return e.numPlanes = _, e.numIntersection = 0, g;
    }
}
function a_(s1) {
    let e = new WeakMap;
    function t(a, o) {
        return o === Ir ? a.mapping = zn : o === Ur && (a.mapping = ci), a;
    }
    function n(a) {
        if (a && a.isTexture && a.isRenderTargetTexture === !1) {
            let o = a.mapping;
            if (o === Ir || o === Ur) if (e.has(a)) {
                let c = e.get(a).texture;
                return t(c, a.mapping);
            } else {
                let c = a.image;
                if (c && c.height > 0) {
                    let l = new xo(c.height / 2);
                    return l.fromEquirectangularTexture(s1, a), e.set(a, l), a.addEventListener("dispose", i), t(l.texture, a.mapping);
                } else return null;
            }
        }
        return a;
    }
    function i(a) {
        let o = a.target;
        o.removeEventListener("dispose", i);
        let c = e.get(o);
        c !== void 0 && (e.delete(o), c.dispose());
    }
    function r() {
        e = new WeakMap;
    }
    return {
        get: n,
        dispose: r
    };
}
var Ls = class extends Cs {
    constructor(e = -1, t = 1, n = 1, i = -1, r = .1, a = 2e3){
        super(), this.isOrthographicCamera = !0, this.type = "OrthographicCamera", this.zoom = 1, this.view = null, this.left = e, this.right = t, this.top = n, this.bottom = i, this.near = r, this.far = a, this.updateProjectionMatrix();
    }
    copy(e, t) {
        return super.copy(e, t), this.left = e.left, this.right = e.right, this.top = e.top, this.bottom = e.bottom, this.near = e.near, this.far = e.far, this.zoom = e.zoom, this.view = e.view === null ? null : Object.assign({}, e.view), this;
    }
    setViewOffset(e, t, n, i, r, a) {
        this.view === null && (this.view = {
            enabled: !0,
            fullWidth: 1,
            fullHeight: 1,
            offsetX: 0,
            offsetY: 0,
            width: 1,
            height: 1
        }), this.view.enabled = !0, this.view.fullWidth = e, this.view.fullHeight = t, this.view.offsetX = n, this.view.offsetY = i, this.view.width = r, this.view.height = a, this.updateProjectionMatrix();
    }
    clearViewOffset() {
        this.view !== null && (this.view.enabled = !1), this.updateProjectionMatrix();
    }
    updateProjectionMatrix() {
        let e = (this.right - this.left) / (2 * this.zoom), t = (this.top - this.bottom) / (2 * this.zoom), n = (this.right + this.left) / 2, i = (this.top + this.bottom) / 2, r = n - e, a = n + e, o = i + t, c = i - t;
        if (this.view !== null && this.view.enabled) {
            let l = (this.right - this.left) / this.view.fullWidth / this.zoom, h = (this.top - this.bottom) / this.view.fullHeight / this.zoom;
            r += l * this.view.offsetX, a = r + l * this.view.width, o -= h * this.view.offsetY, c = o - h * this.view.height;
        }
        this.projectionMatrix.makeOrthographic(r, a, o, c, this.near, this.far, this.coordinateSystem), this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.zoom = this.zoom, t.object.left = this.left, t.object.right = this.right, t.object.top = this.top, t.object.bottom = this.bottom, t.object.near = this.near, t.object.far = this.far, this.view !== null && (t.object.view = Object.assign({}, this.view)), t;
    }
}, Hi = 4, hh = [
    .125,
    .215,
    .35,
    .446,
    .526,
    .582
], ei = 20, $a = new Ls, uh = new pe, Ka = null, jn = (1 + Math.sqrt(5)) / 2, Li = 1 / jn, dh = [
    new A(1, 1, 1),
    new A(-1, 1, 1),
    new A(1, 1, -1),
    new A(-1, 1, -1),
    new A(0, jn, Li),
    new A(0, jn, -Li),
    new A(Li, 0, jn),
    new A(-Li, 0, jn),
    new A(jn, Li, 0),
    new A(-jn, Li, 0)
], Kr = class {
    constructor(e){
        this._renderer = e, this._pingPongRenderTarget = null, this._lodMax = 0, this._cubeSize = 0, this._lodPlanes = [], this._sizeLods = [], this._sigmas = [], this._blurMaterial = null, this._cubemapMaterial = null, this._equirectMaterial = null, this._compileMaterial(this._blurMaterial);
    }
    fromScene(e, t = 0, n = .1, i = 100) {
        Ka = this._renderer.getRenderTarget(), this._setSize(256);
        let r = this._allocateTargets();
        return r.depthBuffer = !0, this._sceneToCubeUV(e, n, i, r), t > 0 && this._blur(r, 0, 0, t), this._applyPMREM(r), this._cleanup(r), r;
    }
    fromEquirectangular(e, t = null) {
        return this._fromTexture(e, t);
    }
    fromCubemap(e, t = null) {
        return this._fromTexture(e, t);
    }
    compileCubemapShader() {
        this._cubemapMaterial === null && (this._cubemapMaterial = mh(), this._compileMaterial(this._cubemapMaterial));
    }
    compileEquirectangularShader() {
        this._equirectMaterial === null && (this._equirectMaterial = ph(), this._compileMaterial(this._equirectMaterial));
    }
    dispose() {
        this._dispose(), this._cubemapMaterial !== null && this._cubemapMaterial.dispose(), this._equirectMaterial !== null && this._equirectMaterial.dispose();
    }
    _setSize(e) {
        this._lodMax = Math.floor(Math.log2(e)), this._cubeSize = Math.pow(2, this._lodMax);
    }
    _dispose() {
        this._blurMaterial !== null && this._blurMaterial.dispose(), this._pingPongRenderTarget !== null && this._pingPongRenderTarget.dispose();
        for(let e = 0; e < this._lodPlanes.length; e++)this._lodPlanes[e].dispose();
    }
    _cleanup(e) {
        this._renderer.setRenderTarget(Ka), e.scissorTest = !1, lr(e, 0, 0, e.width, e.height);
    }
    _fromTexture(e, t) {
        e.mapping === zn || e.mapping === ci ? this._setSize(e.image.length === 0 ? 16 : e.image[0].width || e.image[0].image.width) : this._setSize(e.image.width / 4), Ka = this._renderer.getRenderTarget();
        let n = t || this._allocateTargets();
        return this._textureToCubeUV(e, n), this._applyPMREM(n), this._cleanup(n), n;
    }
    _allocateTargets() {
        let e = 3 * Math.max(this._cubeSize, 112), t = 4 * this._cubeSize, n = {
            magFilter: mt,
            minFilter: mt,
            generateMipmaps: !1,
            type: Ts,
            format: Wt,
            colorSpace: Mn,
            depthBuffer: !1
        }, i = fh(e, t, n);
        if (this._pingPongRenderTarget === null || this._pingPongRenderTarget.width !== e || this._pingPongRenderTarget.height !== t) {
            this._pingPongRenderTarget !== null && this._dispose(), this._pingPongRenderTarget = fh(e, t, n);
            let { _lodMax: r  } = this;
            ({ sizeLods: this._sizeLods , lodPlanes: this._lodPlanes , sigmas: this._sigmas  } = o_(r)), this._blurMaterial = c_(r, e, t);
        }
        return i;
    }
    _compileMaterial(e) {
        let t = new Mt(this._lodPlanes[0], e);
        this._renderer.compile(t, $a);
    }
    _sceneToCubeUV(e, t, n, i) {
        let o = new yt(90, 1, t, n), c = [
            1,
            -1,
            1,
            1,
            1,
            1
        ], l = [
            1,
            1,
            1,
            -1,
            -1,
            -1
        ], h = this._renderer, u = h.autoClear, d = h.toneMapping;
        h.getClearColor(uh), h.toneMapping = Nn, h.autoClear = !1;
        let f = new Sn({
            name: "PMREM.Background",
            side: Ft,
            depthWrite: !1,
            depthTest: !1
        }), m = new Mt(new Ji, f), _ = !1, g = e.background;
        g ? g.isColor && (f.color.copy(g), e.background = null, _ = !0) : (f.color.copy(uh), _ = !0);
        for(let p = 0; p < 6; p++){
            let v = p % 3;
            v === 0 ? (o.up.set(0, c[p], 0), o.lookAt(l[p], 0, 0)) : v === 1 ? (o.up.set(0, 0, c[p]), o.lookAt(0, l[p], 0)) : (o.up.set(0, c[p], 0), o.lookAt(0, 0, l[p]));
            let x = this._cubeSize;
            lr(i, v * x, p > 2 ? x : 0, x, x), h.setRenderTarget(i), _ && h.render(m, o), h.render(e, o);
        }
        m.geometry.dispose(), m.material.dispose(), h.toneMapping = d, h.autoClear = u, e.background = g;
    }
    _textureToCubeUV(e, t) {
        let n = this._renderer, i = e.mapping === zn || e.mapping === ci;
        i ? (this._cubemapMaterial === null && (this._cubemapMaterial = mh()), this._cubemapMaterial.uniforms.flipEnvMap.value = e.isRenderTargetTexture === !1 ? -1 : 1) : this._equirectMaterial === null && (this._equirectMaterial = ph());
        let r = i ? this._cubemapMaterial : this._equirectMaterial, a = new Mt(this._lodPlanes[0], r), o = r.uniforms;
        o.envMap.value = e;
        let c = this._cubeSize;
        lr(t, 0, 0, 3 * c, 2 * c), n.setRenderTarget(t), n.render(a, $a);
    }
    _applyPMREM(e) {
        let t = this._renderer, n = t.autoClear;
        t.autoClear = !1;
        for(let i = 1; i < this._lodPlanes.length; i++){
            let r = Math.sqrt(this._sigmas[i] * this._sigmas[i] - this._sigmas[i - 1] * this._sigmas[i - 1]), a = dh[(i - 1) % dh.length];
            this._blur(e, i - 1, i, r, a);
        }
        t.autoClear = n;
    }
    _blur(e, t, n, i, r) {
        let a = this._pingPongRenderTarget;
        this._halfBlur(e, a, t, n, i, "latitudinal", r), this._halfBlur(a, e, n, n, i, "longitudinal", r);
    }
    _halfBlur(e, t, n, i, r, a, o) {
        let c = this._renderer, l = this._blurMaterial;
        a !== "latitudinal" && a !== "longitudinal" && console.error("blur direction must be either latitudinal or longitudinal!");
        let h = 3, u = new Mt(this._lodPlanes[i], l), d = l.uniforms, f = this._sizeLods[n] - 1, m = isFinite(r) ? Math.PI / (2 * f) : 2 * Math.PI / (2 * ei - 1), _ = r / m, g = isFinite(r) ? 1 + Math.floor(h * _) : ei;
        g > ei && console.warn(`sigmaRadians, ${r}, is too large and will clip, as it requested ${g} samples when the maximum is set to ${ei}`);
        let p = [], v = 0;
        for(let R = 0; R < ei; ++R){
            let I = R / _, M = Math.exp(-I * I / 2);
            p.push(M), R === 0 ? v += M : R < g && (v += 2 * M);
        }
        for(let R = 0; R < p.length; R++)p[R] = p[R] / v;
        d.envMap.value = e.texture, d.samples.value = g, d.weights.value = p, d.latitudinal.value = a === "latitudinal", o && (d.poleAxis.value = o);
        let { _lodMax: x  } = this;
        d.dTheta.value = m, d.mipInt.value = x - n;
        let y = this._sizeLods[i], b = 3 * y * (i > x - Hi ? i - x + Hi : 0), w = 4 * (this._cubeSize - y);
        lr(t, b, w, 3 * y, 2 * y), c.setRenderTarget(t), c.render(u, $a);
    }
};
function o_(s1) {
    let e = [], t = [], n = [], i = s1, r = s1 - Hi + 1 + hh.length;
    for(let a = 0; a < r; a++){
        let o = Math.pow(2, i);
        t.push(o);
        let c = 1 / o;
        a > s1 - Hi ? c = hh[a - s1 + Hi - 1] : a === 0 && (c = 0), n.push(c);
        let l = 1 / (o - 2), h = -l, u = 1 + l, d = [
            h,
            h,
            u,
            h,
            u,
            u,
            h,
            h,
            u,
            u,
            h,
            u
        ], f = 6, m = 6, _ = 3, g = 2, p = 1, v = new Float32Array(_ * m * f), x = new Float32Array(g * m * f), y = new Float32Array(p * m * f);
        for(let w = 0; w < f; w++){
            let R = w % 3 * 2 / 3 - 1, I = w > 2 ? 0 : -1, M = [
                R,
                I,
                0,
                R + 2 / 3,
                I,
                0,
                R + 2 / 3,
                I + 1,
                0,
                R,
                I,
                0,
                R + 2 / 3,
                I + 1,
                0,
                R,
                I + 1,
                0
            ];
            v.set(M, _ * m * w), x.set(d, g * m * w);
            let T = [
                w,
                w,
                w,
                w,
                w,
                w
            ];
            y.set(T, p * m * w);
        }
        let b = new Ge;
        b.setAttribute("position", new et(v, _)), b.setAttribute("uv", new et(x, g)), b.setAttribute("faceIndex", new et(y, p)), e.push(b), i > Hi && i--;
    }
    return {
        lodPlanes: e,
        sizeLods: t,
        sigmas: n
    };
}
function fh(s1, e, t) {
    let n = new qt(s1, e, t);
    return n.texture.mapping = Vs, n.texture.name = "PMREM.cubeUv", n.scissorTest = !0, n;
}
function lr(s1, e, t, n, i) {
    s1.viewport.set(e, t, n, i), s1.scissor.set(e, t, n, i);
}
function c_(s1, e, t) {
    let n = new Float32Array(ei), i = new A(0, 1, 0);
    return new jt({
        name: "SphericalGaussianBlur",
        defines: {
            n: ei,
            CUBEUV_TEXEL_WIDTH: 1 / e,
            CUBEUV_TEXEL_HEIGHT: 1 / t,
            CUBEUV_MAX_MIP: `${s1}.0`
        },
        uniforms: {
            envMap: {
                value: null
            },
            samples: {
                value: 1
            },
            weights: {
                value: n
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
                value: i
            }
        },
        vertexShader: Zc(),
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
        blending: Dn,
        depthTest: !1,
        depthWrite: !1
    });
}
function ph() {
    return new jt({
        name: "EquirectangularToCubeUV",
        uniforms: {
            envMap: {
                value: null
            }
        },
        vertexShader: Zc(),
        fragmentShader: `

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;

			#include <common>

			void main() {

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );

			}
		`,
        blending: Dn,
        depthTest: !1,
        depthWrite: !1
    });
}
function mh() {
    return new jt({
        name: "CubemapToCubeUV",
        uniforms: {
            envMap: {
                value: null
            },
            flipEnvMap: {
                value: -1
            }
        },
        vertexShader: Zc(),
        fragmentShader: `

			precision mediump float;
			precision mediump int;

			uniform float flipEnvMap;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			void main() {

				gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

			}
		`,
        blending: Dn,
        depthTest: !1,
        depthWrite: !1
    });
}
function Zc() {
    return `

		precision mediump float;
		precision mediump int;

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
function l_(s1) {
    let e = new WeakMap, t = null;
    function n(o) {
        if (o && o.isTexture) {
            let c = o.mapping, l = c === Ir || c === Ur, h = c === zn || c === ci;
            if (l || h) if (o.isRenderTargetTexture && o.needsPMREMUpdate === !0) {
                o.needsPMREMUpdate = !1;
                let u = e.get(o);
                return t === null && (t = new Kr(s1)), u = l ? t.fromEquirectangular(o, u) : t.fromCubemap(o, u), e.set(o, u), u.texture;
            } else {
                if (e.has(o)) return e.get(o).texture;
                {
                    let u = o.image;
                    if (l && u && u.height > 0 || h && u && i(u)) {
                        t === null && (t = new Kr(s1));
                        let d = l ? t.fromEquirectangular(o) : t.fromCubemap(o);
                        return e.set(o, d), o.addEventListener("dispose", r), d.texture;
                    } else return null;
                }
            }
        }
        return o;
    }
    function i(o) {
        let c = 0, l = 6;
        for(let h = 0; h < l; h++)o[h] !== void 0 && c++;
        return c === l;
    }
    function r(o) {
        let c = o.target;
        c.removeEventListener("dispose", r);
        let l = e.get(c);
        l !== void 0 && (e.delete(c), l.dispose());
    }
    function a() {
        e = new WeakMap, t !== null && (t.dispose(), t = null);
    }
    return {
        get: n,
        dispose: a
    };
}
function h_(s1) {
    let e = {};
    function t(n) {
        if (e[n] !== void 0) return e[n];
        let i;
        switch(n){
            case "WEBGL_depth_texture":
                i = s1.getExtension("WEBGL_depth_texture") || s1.getExtension("MOZ_WEBGL_depth_texture") || s1.getExtension("WEBKIT_WEBGL_depth_texture");
                break;
            case "EXT_texture_filter_anisotropic":
                i = s1.getExtension("EXT_texture_filter_anisotropic") || s1.getExtension("MOZ_EXT_texture_filter_anisotropic") || s1.getExtension("WEBKIT_EXT_texture_filter_anisotropic");
                break;
            case "WEBGL_compressed_texture_s3tc":
                i = s1.getExtension("WEBGL_compressed_texture_s3tc") || s1.getExtension("MOZ_WEBGL_compressed_texture_s3tc") || s1.getExtension("WEBKIT_WEBGL_compressed_texture_s3tc");
                break;
            case "WEBGL_compressed_texture_pvrtc":
                i = s1.getExtension("WEBGL_compressed_texture_pvrtc") || s1.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");
                break;
            default:
                i = s1.getExtension(n);
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
function u_(s1, e, t, n) {
    let i = {}, r = new WeakMap;
    function a(u) {
        let d = u.target;
        d.index !== null && e.remove(d.index);
        for(let m in d.attributes)e.remove(d.attributes[m]);
        for(let m in d.morphAttributes){
            let _ = d.morphAttributes[m];
            for(let g = 0, p = _.length; g < p; g++)e.remove(_[g]);
        }
        d.removeEventListener("dispose", a), delete i[d.id];
        let f = r.get(d);
        f && (e.remove(f), r.delete(d)), n.releaseStatesOfGeometry(d), d.isInstancedBufferGeometry === !0 && delete d._maxInstanceCount, t.memory.geometries--;
    }
    function o(u, d) {
        return i[d.id] === !0 || (d.addEventListener("dispose", a), i[d.id] = !0, t.memory.geometries++), d;
    }
    function c(u) {
        let d = u.attributes;
        for(let m in d)e.update(d[m], s1.ARRAY_BUFFER);
        let f = u.morphAttributes;
        for(let m in f){
            let _ = f[m];
            for(let g = 0, p = _.length; g < p; g++)e.update(_[g], s1.ARRAY_BUFFER);
        }
    }
    function l(u) {
        let d = [], f = u.index, m = u.attributes.position, _ = 0;
        if (f !== null) {
            let v = f.array;
            _ = f.version;
            for(let x = 0, y = v.length; x < y; x += 3){
                let b = v[x + 0], w = v[x + 1], R = v[x + 2];
                d.push(b, w, w, R, R, b);
            }
        } else if (m !== void 0) {
            let v = m.array;
            _ = m.version;
            for(let x = 0, y = v.length / 3 - 1; x < y; x += 3){
                let b = x + 0, w = x + 1, R = x + 2;
                d.push(b, w, w, R, R, b);
            }
        } else return;
        let g = new (Md(d) ? Jr : Zr)(d, 1);
        g.version = _;
        let p = r.get(u);
        p && e.remove(p), r.set(u, g);
    }
    function h(u) {
        let d = r.get(u);
        if (d) {
            let f = u.index;
            f !== null && d.version < f.version && l(u);
        } else l(u);
        return r.get(u);
    }
    return {
        get: o,
        update: c,
        getWireframeAttribute: h
    };
}
function d_(s1, e, t, n) {
    let i = n.isWebGL2, r;
    function a(d) {
        r = d;
    }
    let o, c;
    function l(d) {
        o = d.type, c = d.bytesPerElement;
    }
    function h(d, f) {
        s1.drawElements(r, f, o, d * c), t.update(f, r, 1);
    }
    function u(d, f, m) {
        if (m === 0) return;
        let _, g;
        if (i) _ = s1, g = "drawElementsInstanced";
        else if (_ = e.get("ANGLE_instanced_arrays"), g = "drawElementsInstancedANGLE", _ === null) {
            console.error("THREE.WebGLIndexedBufferRenderer: using THREE.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.");
            return;
        }
        _[g](r, f, o, d * c, m), t.update(f, r, m);
    }
    this.setMode = a, this.setIndex = l, this.render = h, this.renderInstances = u;
}
function f_(s1) {
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
    function n(r, a, o) {
        switch(t.calls++, a){
            case s1.TRIANGLES:
                t.triangles += o * (r / 3);
                break;
            case s1.LINES:
                t.lines += o * (r / 2);
                break;
            case s1.LINE_STRIP:
                t.lines += o * (r - 1);
                break;
            case s1.LINE_LOOP:
                t.lines += o * r;
                break;
            case s1.POINTS:
                t.points += o * r;
                break;
            default:
                console.error("THREE.WebGLInfo: Unknown draw mode:", a);
                break;
        }
    }
    function i() {
        t.calls = 0, t.triangles = 0, t.points = 0, t.lines = 0;
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
function p_(s1, e) {
    return s1[0] - e[0];
}
function m_(s1, e) {
    return Math.abs(e[1]) - Math.abs(s1[1]);
}
function g_(s1, e, t) {
    let n = {}, i = new Float32Array(8), r = new WeakMap, a = new je, o = [];
    for(let l = 0; l < 8; l++)o[l] = [
        l,
        0
    ];
    function c(l, h, u) {
        let d = l.morphTargetInfluences;
        if (e.isWebGL2 === !0) {
            let f = h.morphAttributes.position || h.morphAttributes.normal || h.morphAttributes.color, m = f !== void 0 ? f.length : 0, _ = r.get(h);
            if (_ === void 0 || _.count !== m) {
                let U = function() {
                    Y.dispose(), r.delete(h), h.removeEventListener("dispose", U);
                };
                _ !== void 0 && _.texture.dispose();
                let v = h.morphAttributes.position !== void 0, x = h.morphAttributes.normal !== void 0, y = h.morphAttributes.color !== void 0, b = h.morphAttributes.position || [], w = h.morphAttributes.normal || [], R = h.morphAttributes.color || [], I = 0;
                v === !0 && (I = 1), x === !0 && (I = 2), y === !0 && (I = 3);
                let M = h.attributes.position.count * I, T = 1;
                M > e.maxTextureSize && (T = Math.ceil(M / e.maxTextureSize), M = e.maxTextureSize);
                let O = new Float32Array(M * T * 4 * m), Y = new As(O, M, T, m);
                Y.type = xn, Y.needsUpdate = !0;
                let $ = I * 4;
                for(let z = 0; z < m; z++){
                    let q = b[z], H = w[z], ne = R[z], W = M * T * 4 * z;
                    for(let K = 0; K < q.count; K++){
                        let D = K * $;
                        v === !0 && (a.fromBufferAttribute(q, K), O[W + D + 0] = a.x, O[W + D + 1] = a.y, O[W + D + 2] = a.z, O[W + D + 3] = 0), x === !0 && (a.fromBufferAttribute(H, K), O[W + D + 4] = a.x, O[W + D + 5] = a.y, O[W + D + 6] = a.z, O[W + D + 7] = 0), y === !0 && (a.fromBufferAttribute(ne, K), O[W + D + 8] = a.x, O[W + D + 9] = a.y, O[W + D + 10] = a.z, O[W + D + 11] = ne.itemSize === 4 ? a.w : 1);
                    }
                }
                _ = {
                    count: m,
                    texture: Y,
                    size: new Z(M, T)
                }, r.set(h, _), h.addEventListener("dispose", U);
            }
            let g = 0;
            for(let v = 0; v < d.length; v++)g += d[v];
            let p = h.morphTargetsRelative ? 1 : 1 - g;
            u.getUniforms().setValue(s1, "morphTargetBaseInfluence", p), u.getUniforms().setValue(s1, "morphTargetInfluences", d), u.getUniforms().setValue(s1, "morphTargetsTexture", _.texture, t), u.getUniforms().setValue(s1, "morphTargetsTextureSize", _.size);
        } else {
            let f = d === void 0 ? 0 : d.length, m = n[h.id];
            if (m === void 0 || m.length !== f) {
                m = [];
                for(let x = 0; x < f; x++)m[x] = [
                    x,
                    0
                ];
                n[h.id] = m;
            }
            for(let x = 0; x < f; x++){
                let y = m[x];
                y[0] = x, y[1] = d[x];
            }
            m.sort(m_);
            for(let x = 0; x < 8; x++)x < f && m[x][1] ? (o[x][0] = m[x][0], o[x][1] = m[x][1]) : (o[x][0] = Number.MAX_SAFE_INTEGER, o[x][1] = 0);
            o.sort(p_);
            let _ = h.morphAttributes.position, g = h.morphAttributes.normal, p = 0;
            for(let x = 0; x < 8; x++){
                let y = o[x], b = y[0], w = y[1];
                b !== Number.MAX_SAFE_INTEGER && w ? (_ && h.getAttribute("morphTarget" + x) !== _[b] && h.setAttribute("morphTarget" + x, _[b]), g && h.getAttribute("morphNormal" + x) !== g[b] && h.setAttribute("morphNormal" + x, g[b]), i[x] = w, p += w) : (_ && h.hasAttribute("morphTarget" + x) === !0 && h.deleteAttribute("morphTarget" + x), g && h.hasAttribute("morphNormal" + x) === !0 && h.deleteAttribute("morphNormal" + x), i[x] = 0);
            }
            let v = h.morphTargetsRelative ? 1 : 1 - p;
            u.getUniforms().setValue(s1, "morphTargetBaseInfluence", v), u.getUniforms().setValue(s1, "morphTargetInfluences", i);
        }
    }
    return {
        update: c
    };
}
function __(s1, e, t, n) {
    let i = new WeakMap;
    function r(c) {
        let l = n.render.frame, h = c.geometry, u = e.get(c, h);
        if (i.get(u) !== l && (e.update(u), i.set(u, l)), c.isInstancedMesh && (c.hasEventListener("dispose", o) === !1 && c.addEventListener("dispose", o), i.get(c) !== l && (t.update(c.instanceMatrix, s1.ARRAY_BUFFER), c.instanceColor !== null && t.update(c.instanceColor, s1.ARRAY_BUFFER), i.set(c, l))), c.isSkinnedMesh) {
            let d = c.skeleton;
            i.get(d) !== l && (d.update(), i.set(d, l));
        }
        return u;
    }
    function a() {
        i = new WeakMap;
    }
    function o(c) {
        let l = c.target;
        l.removeEventListener("dispose", o), t.remove(l.instanceMatrix), l.instanceColor !== null && t.remove(l.instanceColor);
    }
    return {
        update: r,
        dispose: a
    };
}
var Td = new St, wd = new As, Ad = new qr, Rd = new Ki, gh = [], _h = [], xh = new Float32Array(16), vh = new Float32Array(9), yh = new Float32Array(4);
function as(s1, e, t) {
    let n = s1[0];
    if (n <= 0 || n > 0) return s1;
    let i = e * t, r = gh[i];
    if (r === void 0 && (r = new Float32Array(i), gh[i] = r), e !== 0) {
        n.toArray(r, 0);
        for(let a = 1, o = 0; a !== e; ++a)o += t, s1[a].toArray(r, o);
    }
    return r;
}
function gt(s1, e) {
    if (s1.length !== e.length) return !1;
    for(let t = 0, n = s1.length; t < n; t++)if (s1[t] !== e[t]) return !1;
    return !0;
}
function _t(s1, e) {
    for(let t = 0, n = e.length; t < n; t++)s1[t] = e[t];
}
function ya(s1, e) {
    let t = _h[e];
    t === void 0 && (t = new Int32Array(e), _h[e] = t);
    for(let n = 0; n !== e; ++n)t[n] = s1.allocateTextureUnit();
    return t;
}
function x_(s1, e) {
    let t = this.cache;
    t[0] !== e && (s1.uniform1f(this.addr, e), t[0] = e);
}
function v_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y) && (s1.uniform2f(this.addr, e.x, e.y), t[0] = e.x, t[1] = e.y);
    else {
        if (gt(t, e)) return;
        s1.uniform2fv(this.addr, e), _t(t, e);
    }
}
function y_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z) && (s1.uniform3f(this.addr, e.x, e.y, e.z), t[0] = e.x, t[1] = e.y, t[2] = e.z);
    else if (e.r !== void 0) (t[0] !== e.r || t[1] !== e.g || t[2] !== e.b) && (s1.uniform3f(this.addr, e.r, e.g, e.b), t[0] = e.r, t[1] = e.g, t[2] = e.b);
    else {
        if (gt(t, e)) return;
        s1.uniform3fv(this.addr, e), _t(t, e);
    }
}
function M_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z || t[3] !== e.w) && (s1.uniform4f(this.addr, e.x, e.y, e.z, e.w), t[0] = e.x, t[1] = e.y, t[2] = e.z, t[3] = e.w);
    else {
        if (gt(t, e)) return;
        s1.uniform4fv(this.addr, e), _t(t, e);
    }
}
function S_(s1, e) {
    let t = this.cache, n = e.elements;
    if (n === void 0) {
        if (gt(t, e)) return;
        s1.uniformMatrix2fv(this.addr, !1, e), _t(t, e);
    } else {
        if (gt(t, n)) return;
        yh.set(n), s1.uniformMatrix2fv(this.addr, !1, yh), _t(t, n);
    }
}
function b_(s1, e) {
    let t = this.cache, n = e.elements;
    if (n === void 0) {
        if (gt(t, e)) return;
        s1.uniformMatrix3fv(this.addr, !1, e), _t(t, e);
    } else {
        if (gt(t, n)) return;
        vh.set(n), s1.uniformMatrix3fv(this.addr, !1, vh), _t(t, n);
    }
}
function E_(s1, e) {
    let t = this.cache, n = e.elements;
    if (n === void 0) {
        if (gt(t, e)) return;
        s1.uniformMatrix4fv(this.addr, !1, e), _t(t, e);
    } else {
        if (gt(t, n)) return;
        xh.set(n), s1.uniformMatrix4fv(this.addr, !1, xh), _t(t, n);
    }
}
function T_(s1, e) {
    let t = this.cache;
    t[0] !== e && (s1.uniform1i(this.addr, e), t[0] = e);
}
function w_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y) && (s1.uniform2i(this.addr, e.x, e.y), t[0] = e.x, t[1] = e.y);
    else {
        if (gt(t, e)) return;
        s1.uniform2iv(this.addr, e), _t(t, e);
    }
}
function A_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z) && (s1.uniform3i(this.addr, e.x, e.y, e.z), t[0] = e.x, t[1] = e.y, t[2] = e.z);
    else {
        if (gt(t, e)) return;
        s1.uniform3iv(this.addr, e), _t(t, e);
    }
}
function R_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z || t[3] !== e.w) && (s1.uniform4i(this.addr, e.x, e.y, e.z, e.w), t[0] = e.x, t[1] = e.y, t[2] = e.z, t[3] = e.w);
    else {
        if (gt(t, e)) return;
        s1.uniform4iv(this.addr, e), _t(t, e);
    }
}
function C_(s1, e) {
    let t = this.cache;
    t[0] !== e && (s1.uniform1ui(this.addr, e), t[0] = e);
}
function P_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y) && (s1.uniform2ui(this.addr, e.x, e.y), t[0] = e.x, t[1] = e.y);
    else {
        if (gt(t, e)) return;
        s1.uniform2uiv(this.addr, e), _t(t, e);
    }
}
function L_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z) && (s1.uniform3ui(this.addr, e.x, e.y, e.z), t[0] = e.x, t[1] = e.y, t[2] = e.z);
    else {
        if (gt(t, e)) return;
        s1.uniform3uiv(this.addr, e), _t(t, e);
    }
}
function I_(s1, e) {
    let t = this.cache;
    if (e.x !== void 0) (t[0] !== e.x || t[1] !== e.y || t[2] !== e.z || t[3] !== e.w) && (s1.uniform4ui(this.addr, e.x, e.y, e.z, e.w), t[0] = e.x, t[1] = e.y, t[2] = e.z, t[3] = e.w);
    else {
        if (gt(t, e)) return;
        s1.uniform4uiv(this.addr, e), _t(t, e);
    }
}
function U_(s1, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), t.setTexture2D(e || Td, i);
}
function D_(s1, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), t.setTexture3D(e || Ad, i);
}
function N_(s1, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), t.setTextureCube(e || Rd, i);
}
function O_(s1, e, t) {
    let n = this.cache, i = t.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), t.setTexture2DArray(e || wd, i);
}
function F_(s1) {
    switch(s1){
        case 5126:
            return x_;
        case 35664:
            return v_;
        case 35665:
            return y_;
        case 35666:
            return M_;
        case 35674:
            return S_;
        case 35675:
            return b_;
        case 35676:
            return E_;
        case 5124:
        case 35670:
            return T_;
        case 35667:
        case 35671:
            return w_;
        case 35668:
        case 35672:
            return A_;
        case 35669:
        case 35673:
            return R_;
        case 5125:
            return C_;
        case 36294:
            return P_;
        case 36295:
            return L_;
        case 36296:
            return I_;
        case 35678:
        case 36198:
        case 36298:
        case 36306:
        case 35682:
            return U_;
        case 35679:
        case 36299:
        case 36307:
            return D_;
        case 35680:
        case 36300:
        case 36308:
        case 36293:
            return N_;
        case 36289:
        case 36303:
        case 36311:
        case 36292:
            return O_;
    }
}
function B_(s1, e) {
    s1.uniform1fv(this.addr, e);
}
function z_(s1, e) {
    let t = as(e, this.size, 2);
    s1.uniform2fv(this.addr, t);
}
function V_(s1, e) {
    let t = as(e, this.size, 3);
    s1.uniform3fv(this.addr, t);
}
function k_(s1, e) {
    let t = as(e, this.size, 4);
    s1.uniform4fv(this.addr, t);
}
function H_(s1, e) {
    let t = as(e, this.size, 4);
    s1.uniformMatrix2fv(this.addr, !1, t);
}
function G_(s1, e) {
    let t = as(e, this.size, 9);
    s1.uniformMatrix3fv(this.addr, !1, t);
}
function W_(s1, e) {
    let t = as(e, this.size, 16);
    s1.uniformMatrix4fv(this.addr, !1, t);
}
function X_(s1, e) {
    s1.uniform1iv(this.addr, e);
}
function q_(s1, e) {
    s1.uniform2iv(this.addr, e);
}
function Y_(s1, e) {
    s1.uniform3iv(this.addr, e);
}
function Z_(s1, e) {
    s1.uniform4iv(this.addr, e);
}
function J_(s1, e) {
    s1.uniform1uiv(this.addr, e);
}
function $_(s1, e) {
    s1.uniform2uiv(this.addr, e);
}
function K_(s1, e) {
    s1.uniform3uiv(this.addr, e);
}
function Q_(s1, e) {
    s1.uniform4uiv(this.addr, e);
}
function j_(s1, e, t) {
    let n = this.cache, i = e.length, r = ya(t, i);
    gt(n, r) || (s1.uniform1iv(this.addr, r), _t(n, r));
    for(let a = 0; a !== i; ++a)t.setTexture2D(e[a] || Td, r[a]);
}
function e0(s1, e, t) {
    let n = this.cache, i = e.length, r = ya(t, i);
    gt(n, r) || (s1.uniform1iv(this.addr, r), _t(n, r));
    for(let a = 0; a !== i; ++a)t.setTexture3D(e[a] || Ad, r[a]);
}
function t0(s1, e, t) {
    let n = this.cache, i = e.length, r = ya(t, i);
    gt(n, r) || (s1.uniform1iv(this.addr, r), _t(n, r));
    for(let a = 0; a !== i; ++a)t.setTextureCube(e[a] || Rd, r[a]);
}
function n0(s1, e, t) {
    let n = this.cache, i = e.length, r = ya(t, i);
    gt(n, r) || (s1.uniform1iv(this.addr, r), _t(n, r));
    for(let a = 0; a !== i; ++a)t.setTexture2DArray(e[a] || wd, r[a]);
}
function i0(s1) {
    switch(s1){
        case 5126:
            return B_;
        case 35664:
            return z_;
        case 35665:
            return V_;
        case 35666:
            return k_;
        case 35674:
            return H_;
        case 35675:
            return G_;
        case 35676:
            return W_;
        case 5124:
        case 35670:
            return X_;
        case 35667:
        case 35671:
            return q_;
        case 35668:
        case 35672:
            return Y_;
        case 35669:
        case 35673:
            return Z_;
        case 5125:
            return J_;
        case 36294:
            return $_;
        case 36295:
            return K_;
        case 36296:
            return Q_;
        case 35678:
        case 36198:
        case 36298:
        case 36306:
        case 35682:
            return j_;
        case 35679:
        case 36299:
        case 36307:
            return e0;
        case 35680:
        case 36300:
        case 36308:
        case 36293:
            return t0;
        case 36289:
        case 36303:
        case 36311:
        case 36292:
            return n0;
    }
}
var vo = class {
    constructor(e, t, n){
        this.id = e, this.addr = n, this.cache = [], this.setValue = F_(t.type);
    }
}, yo = class {
    constructor(e, t, n){
        this.id = e, this.addr = n, this.cache = [], this.size = t.size, this.setValue = i0(t.type);
    }
}, Mo = class {
    constructor(e){
        this.id = e, this.seq = [], this.map = {};
    }
    setValue(e, t, n) {
        let i = this.seq;
        for(let r = 0, a = i.length; r !== a; ++r){
            let o = i[r];
            o.setValue(e, t[o.id], n);
        }
    }
}, Qa = /(\w+)(\])?(\[|\.)?/g;
function Mh(s1, e) {
    s1.seq.push(e), s1.map[e.id] = e;
}
function s0(s1, e, t) {
    let n = s1.name, i = n.length;
    for(Qa.lastIndex = 0;;){
        let r = Qa.exec(n), a = Qa.lastIndex, o = r[1], c = r[2] === "]", l = r[3];
        if (c && (o = o | 0), l === void 0 || l === "[" && a + 2 === i) {
            Mh(t, l === void 0 ? new vo(o, s1, e) : new yo(o, s1, e));
            break;
        } else {
            let u = t.map[o];
            u === void 0 && (u = new Mo(o), Mh(t, u)), t = u;
        }
    }
}
var qi = class {
    constructor(e, t){
        this.seq = [], this.map = {};
        let n = e.getProgramParameter(t, e.ACTIVE_UNIFORMS);
        for(let i = 0; i < n; ++i){
            let r = e.getActiveUniform(t, i), a = e.getUniformLocation(t, r.name);
            s0(r, a, this);
        }
    }
    setValue(e, t, n, i) {
        let r = this.map[t];
        r !== void 0 && r.setValue(e, n, i);
    }
    setOptional(e, t, n) {
        let i = t[n];
        i !== void 0 && this.setValue(e, n, i);
    }
    static upload(e, t, n, i) {
        for(let r = 0, a = t.length; r !== a; ++r){
            let o = t[r], c = n[o.id];
            c.needsUpdate !== !1 && o.setValue(e, c.value, i);
        }
    }
    static seqWithValue(e, t) {
        let n = [];
        for(let i = 0, r = e.length; i !== r; ++i){
            let a = e[i];
            a.id in t && n.push(a);
        }
        return n;
    }
};
function Sh(s1, e, t) {
    let n = s1.createShader(e);
    return s1.shaderSource(n, t), s1.compileShader(n), n;
}
var r0 = 0;
function a0(s1, e) {
    let t = s1.split(`
`), n = [], i = Math.max(e - 6, 0), r = Math.min(e + 6, t.length);
    for(let a = i; a < r; a++){
        let o = a + 1;
        n.push(`${o === e ? ">" : " "} ${o}: ${t[a]}`);
    }
    return n.join(`
`);
}
function o0(s1) {
    let e = Qe.getPrimaries(Qe.workingColorSpace), t = Qe.getPrimaries(s1), n;
    switch(e === t ? n = "" : e === kr && t === Vr ? n = "LinearDisplayP3ToLinearSRGB" : e === Vr && t === kr && (n = "LinearSRGBToLinearDisplayP3"), s1){
        case Mn:
        case va:
            return [
                n,
                "LinearTransferOETF"
            ];
        case vt:
        case qc:
            return [
                n,
                "sRGBTransferOETF"
            ];
        default:
            return console.warn("THREE.WebGLProgram: Unsupported color space:", s1), [
                n,
                "LinearTransferOETF"
            ];
    }
}
function bh(s1, e, t) {
    let n = s1.getShaderParameter(e, s1.COMPILE_STATUS), i = s1.getShaderInfoLog(e).trim();
    if (n && i === "") return "";
    let r = /ERROR: 0:(\d+)/.exec(i);
    if (r) {
        let a = parseInt(r[1]);
        return t.toUpperCase() + `

` + i + `

` + a0(s1.getShaderSource(e), a);
    } else return i;
}
function c0(s1, e) {
    let t = o0(e);
    return `vec4 ${s1}( vec4 value ) { return ${t[0]}( ${t[1]}( value ) ); }`;
}
function l0(s1, e) {
    let t;
    switch(e){
        case df:
            t = "Linear";
            break;
        case ff:
            t = "Reinhard";
            break;
        case pf:
            t = "OptimizedCineon";
            break;
        case mf:
            t = "ACESFilmic";
            break;
        case gf:
            t = "Custom";
            break;
        default:
            console.warn("THREE.WebGLProgram: Unsupported toneMapping:", e), t = "Linear";
    }
    return "vec3 " + s1 + "( vec3 color ) { return " + t + "ToneMapping( color ); }";
}
function h0(s1) {
    return [
        s1.extensionDerivatives || s1.envMapCubeUVHeight || s1.bumpMap || s1.normalMapTangentSpace || s1.clearcoatNormalMap || s1.flatShading || s1.shaderID === "physical" ? "#extension GL_OES_standard_derivatives : enable" : "",
        (s1.extensionFragDepth || s1.logarithmicDepthBuffer) && s1.rendererExtensionFragDepth ? "#extension GL_EXT_frag_depth : enable" : "",
        s1.extensionDrawBuffers && s1.rendererExtensionDrawBuffers ? "#extension GL_EXT_draw_buffers : require" : "",
        (s1.extensionShaderTextureLOD || s1.envMap || s1.transmission) && s1.rendererExtensionShaderTextureLod ? "#extension GL_EXT_shader_texture_lod : enable" : ""
    ].filter(vs).join(`
`);
}
function u0(s1) {
    let e = [];
    for(let t in s1){
        let n = s1[t];
        n !== !1 && e.push("#define " + t + " " + n);
    }
    return e.join(`
`);
}
function d0(s1, e) {
    let t = {}, n = s1.getProgramParameter(e, s1.ACTIVE_ATTRIBUTES);
    for(let i = 0; i < n; i++){
        let r = s1.getActiveAttrib(e, i), a = r.name, o = 1;
        r.type === s1.FLOAT_MAT2 && (o = 2), r.type === s1.FLOAT_MAT3 && (o = 3), r.type === s1.FLOAT_MAT4 && (o = 4), t[a] = {
            type: r.type,
            location: s1.getAttribLocation(e, a),
            locationSize: o
        };
    }
    return t;
}
function vs(s1) {
    return s1 !== "";
}
function Eh(s1, e) {
    let t = e.numSpotLightShadows + e.numSpotLightMaps - e.numSpotLightShadowsWithMaps;
    return s1.replace(/NUM_DIR_LIGHTS/g, e.numDirLights).replace(/NUM_SPOT_LIGHTS/g, e.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g, e.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g, t).replace(/NUM_RECT_AREA_LIGHTS/g, e.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g, e.numPointLights).replace(/NUM_HEMI_LIGHTS/g, e.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g, e.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, e.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g, e.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g, e.numPointLightShadows);
}
function Th(s1, e) {
    return s1.replace(/NUM_CLIPPING_PLANES/g, e.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g, e.numClippingPlanes - e.numClipIntersection);
}
var f0 = /^[ \t]*#include +<([\w\d./]+)>/gm;
function So(s1) {
    return s1.replace(f0, m0);
}
var p0 = new Map([
    [
        "encodings_fragment",
        "colorspace_fragment"
    ],
    [
        "encodings_pars_fragment",
        "colorspace_pars_fragment"
    ],
    [
        "output_fragment",
        "opaque_fragment"
    ]
]);
function m0(s1, e) {
    let t = ke[e];
    if (t === void 0) {
        let n = p0.get(e);
        if (n !== void 0) t = ke[n], console.warn('THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.', e, n);
        else throw new Error("Can not resolve #include <" + e + ">");
    }
    return So(t);
}
var g0 = /#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;
function wh(s1) {
    return s1.replace(g0, _0);
}
function _0(s1, e, t, n) {
    let i = "";
    for(let r = parseInt(e); r < parseInt(t); r++)i += n.replace(/\[\s*i\s*\]/g, "[ " + r + " ]").replace(/UNROLLED_LOOP_INDEX/g, r);
    return i;
}
function Ah(s1) {
    let e = "precision " + s1.precision + ` float;
precision ` + s1.precision + " int;";
    return s1.precision === "highp" ? e += `
#define HIGH_PRECISION` : s1.precision === "mediump" ? e += `
#define MEDIUM_PRECISION` : s1.precision === "lowp" && (e += `
#define LOW_PRECISION`), e;
}
function x0(s1) {
    let e = "SHADOWMAP_TYPE_BASIC";
    return s1.shadowMapType === cd ? e = "SHADOWMAP_TYPE_PCF" : s1.shadowMapType === Gd ? e = "SHADOWMAP_TYPE_PCF_SOFT" : s1.shadowMapType === pn && (e = "SHADOWMAP_TYPE_VSM"), e;
}
function v0(s1) {
    let e = "ENVMAP_TYPE_CUBE";
    if (s1.envMap) switch(s1.envMapMode){
        case zn:
        case ci:
            e = "ENVMAP_TYPE_CUBE";
            break;
        case Vs:
            e = "ENVMAP_TYPE_CUBE_UV";
            break;
    }
    return e;
}
function y0(s1) {
    let e = "ENVMAP_MODE_REFLECTION";
    if (s1.envMap) switch(s1.envMapMode){
        case ci:
            e = "ENVMAP_MODE_REFRACTION";
            break;
    }
    return e;
}
function M0(s1) {
    let e = "ENVMAP_BLENDING_NONE";
    if (s1.envMap) switch(s1.combine){
        case xa:
            e = "ENVMAP_BLENDING_MULTIPLY";
            break;
        case hf:
            e = "ENVMAP_BLENDING_MIX";
            break;
        case uf:
            e = "ENVMAP_BLENDING_ADD";
            break;
    }
    return e;
}
function S0(s1) {
    let e = s1.envMapCubeUVHeight;
    if (e === null) return null;
    let t = Math.log2(e) - 2, n = 1 / e;
    return {
        texelWidth: 1 / (3 * Math.max(Math.pow(2, t), 7 * 16)),
        texelHeight: n,
        maxMip: t
    };
}
function b0(s1, e, t, n) {
    let i = s1.getContext(), r = t.defines, a = t.vertexShader, o = t.fragmentShader, c = x0(t), l = v0(t), h = y0(t), u = M0(t), d = S0(t), f = t.isWebGL2 ? "" : h0(t), m = u0(r), _ = i.createProgram(), g, p, v = t.glslVersion ? "#version " + t.glslVersion + `
` : "";
    t.isRawShaderMaterial ? (g = [
        "#define SHADER_TYPE " + t.shaderType,
        "#define SHADER_NAME " + t.shaderName,
        m
    ].filter(vs).join(`
`), g.length > 0 && (g += `
`), p = [
        f,
        "#define SHADER_TYPE " + t.shaderType,
        "#define SHADER_NAME " + t.shaderName,
        m
    ].filter(vs).join(`
`), p.length > 0 && (p += `
`)) : (g = [
        Ah(t),
        "#define SHADER_TYPE " + t.shaderType,
        "#define SHADER_NAME " + t.shaderName,
        m,
        t.instancing ? "#define USE_INSTANCING" : "",
        t.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
        t.useFog && t.fog ? "#define USE_FOG" : "",
        t.useFog && t.fogExp2 ? "#define FOG_EXP2" : "",
        t.map ? "#define USE_MAP" : "",
        t.envMap ? "#define USE_ENVMAP" : "",
        t.envMap ? "#define " + h : "",
        t.lightMap ? "#define USE_LIGHTMAP" : "",
        t.aoMap ? "#define USE_AOMAP" : "",
        t.bumpMap ? "#define USE_BUMPMAP" : "",
        t.normalMap ? "#define USE_NORMALMAP" : "",
        t.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
        t.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
        t.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
        t.emissiveMap ? "#define USE_EMISSIVEMAP" : "",
        t.anisotropy ? "#define USE_ANISOTROPY" : "",
        t.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",
        t.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
        t.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
        t.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",
        t.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
        t.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",
        t.specularMap ? "#define USE_SPECULARMAP" : "",
        t.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
        t.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",
        t.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
        t.metalnessMap ? "#define USE_METALNESSMAP" : "",
        t.alphaMap ? "#define USE_ALPHAMAP" : "",
        t.alphaHash ? "#define USE_ALPHAHASH" : "",
        t.transmission ? "#define USE_TRANSMISSION" : "",
        t.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
        t.thicknessMap ? "#define USE_THICKNESSMAP" : "",
        t.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
        t.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",
        t.mapUv ? "#define MAP_UV " + t.mapUv : "",
        t.alphaMapUv ? "#define ALPHAMAP_UV " + t.alphaMapUv : "",
        t.lightMapUv ? "#define LIGHTMAP_UV " + t.lightMapUv : "",
        t.aoMapUv ? "#define AOMAP_UV " + t.aoMapUv : "",
        t.emissiveMapUv ? "#define EMISSIVEMAP_UV " + t.emissiveMapUv : "",
        t.bumpMapUv ? "#define BUMPMAP_UV " + t.bumpMapUv : "",
        t.normalMapUv ? "#define NORMALMAP_UV " + t.normalMapUv : "",
        t.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + t.displacementMapUv : "",
        t.metalnessMapUv ? "#define METALNESSMAP_UV " + t.metalnessMapUv : "",
        t.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + t.roughnessMapUv : "",
        t.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + t.anisotropyMapUv : "",
        t.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + t.clearcoatMapUv : "",
        t.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + t.clearcoatNormalMapUv : "",
        t.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + t.clearcoatRoughnessMapUv : "",
        t.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + t.iridescenceMapUv : "",
        t.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + t.iridescenceThicknessMapUv : "",
        t.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + t.sheenColorMapUv : "",
        t.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + t.sheenRoughnessMapUv : "",
        t.specularMapUv ? "#define SPECULARMAP_UV " + t.specularMapUv : "",
        t.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + t.specularColorMapUv : "",
        t.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + t.specularIntensityMapUv : "",
        t.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + t.transmissionMapUv : "",
        t.thicknessMapUv ? "#define THICKNESSMAP_UV " + t.thicknessMapUv : "",
        t.vertexTangents && t.flatShading === !1 ? "#define USE_TANGENT" : "",
        t.vertexColors ? "#define USE_COLOR" : "",
        t.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
        t.vertexUv1s ? "#define USE_UV1" : "",
        t.vertexUv2s ? "#define USE_UV2" : "",
        t.vertexUv3s ? "#define USE_UV3" : "",
        t.pointsUvs ? "#define USE_POINTS_UV" : "",
        t.flatShading ? "#define FLAT_SHADED" : "",
        t.skinning ? "#define USE_SKINNING" : "",
        t.morphTargets ? "#define USE_MORPHTARGETS" : "",
        t.morphNormals && t.flatShading === !1 ? "#define USE_MORPHNORMALS" : "",
        t.morphColors && t.isWebGL2 ? "#define USE_MORPHCOLORS" : "",
        t.morphTargetsCount > 0 && t.isWebGL2 ? "#define MORPHTARGETS_TEXTURE" : "",
        t.morphTargetsCount > 0 && t.isWebGL2 ? "#define MORPHTARGETS_TEXTURE_STRIDE " + t.morphTextureStride : "",
        t.morphTargetsCount > 0 && t.isWebGL2 ? "#define MORPHTARGETS_COUNT " + t.morphTargetsCount : "",
        t.doubleSided ? "#define DOUBLE_SIDED" : "",
        t.flipSided ? "#define FLIP_SIDED" : "",
        t.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
        t.shadowMapEnabled ? "#define " + c : "",
        t.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",
        t.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",
        t.useLegacyLights ? "#define LEGACY_LIGHTS" : "",
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
        "#ifdef USE_UV1",
        "	attribute vec2 uv1;",
        "#endif",
        "#ifdef USE_UV2",
        "	attribute vec2 uv2;",
        "#endif",
        "#ifdef USE_UV3",
        "	attribute vec2 uv3;",
        "#endif",
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
    ].filter(vs).join(`
`), p = [
        f,
        Ah(t),
        "#define SHADER_TYPE " + t.shaderType,
        "#define SHADER_NAME " + t.shaderName,
        m,
        t.useFog && t.fog ? "#define USE_FOG" : "",
        t.useFog && t.fogExp2 ? "#define FOG_EXP2" : "",
        t.map ? "#define USE_MAP" : "",
        t.matcap ? "#define USE_MATCAP" : "",
        t.envMap ? "#define USE_ENVMAP" : "",
        t.envMap ? "#define " + l : "",
        t.envMap ? "#define " + h : "",
        t.envMap ? "#define " + u : "",
        d ? "#define CUBEUV_TEXEL_WIDTH " + d.texelWidth : "",
        d ? "#define CUBEUV_TEXEL_HEIGHT " + d.texelHeight : "",
        d ? "#define CUBEUV_MAX_MIP " + d.maxMip + ".0" : "",
        t.lightMap ? "#define USE_LIGHTMAP" : "",
        t.aoMap ? "#define USE_AOMAP" : "",
        t.bumpMap ? "#define USE_BUMPMAP" : "",
        t.normalMap ? "#define USE_NORMALMAP" : "",
        t.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
        t.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
        t.emissiveMap ? "#define USE_EMISSIVEMAP" : "",
        t.anisotropy ? "#define USE_ANISOTROPY" : "",
        t.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",
        t.clearcoat ? "#define USE_CLEARCOAT" : "",
        t.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
        t.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
        t.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",
        t.iridescence ? "#define USE_IRIDESCENCE" : "",
        t.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
        t.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",
        t.specularMap ? "#define USE_SPECULARMAP" : "",
        t.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
        t.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",
        t.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
        t.metalnessMap ? "#define USE_METALNESSMAP" : "",
        t.alphaMap ? "#define USE_ALPHAMAP" : "",
        t.alphaTest ? "#define USE_ALPHATEST" : "",
        t.alphaHash ? "#define USE_ALPHAHASH" : "",
        t.sheen ? "#define USE_SHEEN" : "",
        t.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
        t.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",
        t.transmission ? "#define USE_TRANSMISSION" : "",
        t.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
        t.thicknessMap ? "#define USE_THICKNESSMAP" : "",
        t.vertexTangents && t.flatShading === !1 ? "#define USE_TANGENT" : "",
        t.vertexColors || t.instancingColor ? "#define USE_COLOR" : "",
        t.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
        t.vertexUv1s ? "#define USE_UV1" : "",
        t.vertexUv2s ? "#define USE_UV2" : "",
        t.vertexUv3s ? "#define USE_UV3" : "",
        t.pointsUvs ? "#define USE_POINTS_UV" : "",
        t.gradientMap ? "#define USE_GRADIENTMAP" : "",
        t.flatShading ? "#define FLAT_SHADED" : "",
        t.doubleSided ? "#define DOUBLE_SIDED" : "",
        t.flipSided ? "#define FLIP_SIDED" : "",
        t.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
        t.shadowMapEnabled ? "#define " + c : "",
        t.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",
        t.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",
        t.useLegacyLights ? "#define LEGACY_LIGHTS" : "",
        t.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",
        t.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",
        t.logarithmicDepthBuffer && t.rendererExtensionFragDepth ? "#define USE_LOGDEPTHBUF_EXT" : "",
        "uniform mat4 viewMatrix;",
        "uniform vec3 cameraPosition;",
        "uniform bool isOrthographic;",
        t.toneMapping !== Nn ? "#define TONE_MAPPING" : "",
        t.toneMapping !== Nn ? ke.tonemapping_pars_fragment : "",
        t.toneMapping !== Nn ? l0("toneMapping", t.toneMapping) : "",
        t.dithering ? "#define DITHERING" : "",
        t.opaque ? "#define OPAQUE" : "",
        ke.colorspace_pars_fragment,
        c0("linearToOutputTexel", t.outputColorSpace),
        t.useDepthPacking ? "#define DEPTH_PACKING " + t.depthPacking : "",
        `
`
    ].filter(vs).join(`
`)), a = So(a), a = Eh(a, t), a = Th(a, t), o = So(o), o = Eh(o, t), o = Th(o, t), a = wh(a), o = wh(o), t.isWebGL2 && t.isRawShaderMaterial !== !0 && (v = `#version 300 es
`, g = [
        "precision mediump sampler2DArray;",
        "#define attribute in",
        "#define varying out",
        "#define texture2D texture"
    ].join(`
`) + `
` + g, p = [
        "#define varying in",
        t.glslVersion === Ol ? "" : "layout(location = 0) out highp vec4 pc_fragColor;",
        t.glslVersion === Ol ? "" : "#define gl_FragColor pc_fragColor",
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
` + p);
    let x = v + g + a, y = v + p + o, b = Sh(i, i.VERTEX_SHADER, x), w = Sh(i, i.FRAGMENT_SHADER, y);
    if (i.attachShader(_, b), i.attachShader(_, w), t.index0AttributeName !== void 0 ? i.bindAttribLocation(_, 0, t.index0AttributeName) : t.morphTargets === !0 && i.bindAttribLocation(_, 0, "position"), i.linkProgram(_), s1.debug.checkShaderErrors) {
        let M = i.getProgramInfoLog(_).trim(), T = i.getShaderInfoLog(b).trim(), O = i.getShaderInfoLog(w).trim(), Y = !0, $ = !0;
        if (i.getProgramParameter(_, i.LINK_STATUS) === !1) if (Y = !1, typeof s1.debug.onShaderError == "function") s1.debug.onShaderError(i, _, b, w);
        else {
            let U = bh(i, b, "vertex"), z = bh(i, w, "fragment");
            console.error("THREE.WebGLProgram: Shader Error " + i.getError() + " - VALIDATE_STATUS " + i.getProgramParameter(_, i.VALIDATE_STATUS) + `

Program Info Log: ` + M + `
` + U + `
` + z);
        }
        else M !== "" ? console.warn("THREE.WebGLProgram: Program Info Log:", M) : (T === "" || O === "") && ($ = !1);
        $ && (this.diagnostics = {
            runnable: Y,
            programLog: M,
            vertexShader: {
                log: T,
                prefix: g
            },
            fragmentShader: {
                log: O,
                prefix: p
            }
        });
    }
    i.deleteShader(b), i.deleteShader(w);
    let R;
    this.getUniforms = function() {
        return R === void 0 && (R = new qi(i, _)), R;
    };
    let I;
    return this.getAttributes = function() {
        return I === void 0 && (I = d0(i, _)), I;
    }, this.destroy = function() {
        n.releaseStatesOfProgram(this), i.deleteProgram(_), this.program = void 0;
    }, this.type = t.shaderType, this.name = t.shaderName, this.id = r0++, this.cacheKey = e, this.usedTimes = 1, this.program = _, this.vertexShader = b, this.fragmentShader = w, this;
}
var E0 = 0, bo = class {
    constructor(){
        this.shaderCache = new Map, this.materialCache = new Map;
    }
    update(e) {
        let t = e.vertexShader, n = e.fragmentShader, i = this._getShaderStage(t), r = this._getShaderStage(n), a = this._getShaderCacheForMaterial(e);
        return a.has(i) === !1 && (a.add(i), i.usedTimes++), a.has(r) === !1 && (a.add(r), r.usedTimes++), this;
    }
    remove(e) {
        let t = this.materialCache.get(e);
        for (let n of t)n.usedTimes--, n.usedTimes === 0 && this.shaderCache.delete(n.code);
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
        let t = this.materialCache, n = t.get(e);
        return n === void 0 && (n = new Set, t.set(e, n)), n;
    }
    _getShaderStage(e) {
        let t = this.shaderCache, n = t.get(e);
        return n === void 0 && (n = new Eo(e), t.set(e, n)), n;
    }
}, Eo = class {
    constructor(e){
        this.id = E0++, this.code = e, this.usedTimes = 0;
    }
};
function T0(s1, e, t, n, i, r, a) {
    let o = new Rs, c = new bo, l = [], h = i.isWebGL2, u = i.logarithmicDepthBuffer, d = i.vertexTextures, f = i.precision, m = {
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
    function _(M) {
        return M === 0 ? "uv" : `uv${M}`;
    }
    function g(M, T, O, Y, $) {
        let U = Y.fog, z = $.geometry, q = M.isMeshStandardMaterial ? Y.environment : null, H = (M.isMeshStandardMaterial ? t : e).get(M.envMap || q), ne = H && H.mapping === Vs ? H.image.height : null, W = m[M.type];
        M.precision !== null && (f = i.getMaxPrecision(M.precision), f !== M.precision && console.warn("THREE.WebGLProgram.getParameters:", M.precision, "not supported, using", f, "instead."));
        let K = z.morphAttributes.position || z.morphAttributes.normal || z.morphAttributes.color, D = K !== void 0 ? K.length : 0, G = 0;
        z.morphAttributes.position !== void 0 && (G = 1), z.morphAttributes.normal !== void 0 && (G = 2), z.morphAttributes.color !== void 0 && (G = 3);
        let he, fe, _e, we;
        if (W) {
            let tt = nn[W];
            he = tt.vertexShader, fe = tt.fragmentShader;
        } else he = M.vertexShader, fe = M.fragmentShader, c.update(M), _e = c.getVertexShaderID(M), we = c.getFragmentShaderID(M);
        let Ee = s1.getRenderTarget(), Te = $.isInstancedMesh === !0, Ye = !!M.map, it = !!M.matcap, Ce = !!H, L = !!M.aoMap, oe = !!M.lightMap, X = !!M.bumpMap, ie = !!M.normalMap, J = !!M.displacementMap, Se = !!M.emissiveMap, me = !!M.metalnessMap, ye = !!M.roughnessMap, Ne = M.anisotropy > 0, qe = M.clearcoat > 0, rt = M.iridescence > 0, C = M.sheen > 0, S = M.transmission > 0, B = Ne && !!M.anisotropyMap, ee = qe && !!M.clearcoatMap, j = qe && !!M.clearcoatNormalMap, te = qe && !!M.clearcoatRoughnessMap, Me = rt && !!M.iridescenceMap, re = rt && !!M.iridescenceThicknessMap, de = C && !!M.sheenColorMap, Le = C && !!M.sheenRoughnessMap, Ze = !!M.specularMap, se = !!M.specularColorMap, $e = !!M.specularIntensityMap, Oe = S && !!M.transmissionMap, Ie = S && !!M.thicknessMap, Re = !!M.gradientMap, P = !!M.alphaMap, ce = M.alphaTest > 0, ae = !!M.alphaHash, ge = !!M.extensions, ue = !!z.attributes.uv1, Q = !!z.attributes.uv2, be = !!z.attributes.uv3, Fe = Nn;
        return M.toneMapped && (Ee === null || Ee.isXRRenderTarget === !0) && (Fe = s1.toneMapping), {
            isWebGL2: h,
            shaderID: W,
            shaderType: M.type,
            shaderName: M.name,
            vertexShader: he,
            fragmentShader: fe,
            defines: M.defines,
            customVertexShaderID: _e,
            customFragmentShaderID: we,
            isRawShaderMaterial: M.isRawShaderMaterial === !0,
            glslVersion: M.glslVersion,
            precision: f,
            instancing: Te,
            instancingColor: Te && $.instanceColor !== null,
            supportsVertexTextures: d,
            outputColorSpace: Ee === null ? s1.outputColorSpace : Ee.isXRRenderTarget === !0 ? Ee.texture.colorSpace : Mn,
            map: Ye,
            matcap: it,
            envMap: Ce,
            envMapMode: Ce && H.mapping,
            envMapCubeUVHeight: ne,
            aoMap: L,
            lightMap: oe,
            bumpMap: X,
            normalMap: ie,
            displacementMap: d && J,
            emissiveMap: Se,
            normalMapObjectSpace: ie && M.normalMapType === Lf,
            normalMapTangentSpace: ie && M.normalMapType === mi,
            metalnessMap: me,
            roughnessMap: ye,
            anisotropy: Ne,
            anisotropyMap: B,
            clearcoat: qe,
            clearcoatMap: ee,
            clearcoatNormalMap: j,
            clearcoatRoughnessMap: te,
            iridescence: rt,
            iridescenceMap: Me,
            iridescenceThicknessMap: re,
            sheen: C,
            sheenColorMap: de,
            sheenRoughnessMap: Le,
            specularMap: Ze,
            specularColorMap: se,
            specularIntensityMap: $e,
            transmission: S,
            transmissionMap: Oe,
            thicknessMap: Ie,
            gradientMap: Re,
            opaque: M.transparent === !1 && M.blending === Wi,
            alphaMap: P,
            alphaTest: ce,
            alphaHash: ae,
            combine: M.combine,
            mapUv: Ye && _(M.map.channel),
            aoMapUv: L && _(M.aoMap.channel),
            lightMapUv: oe && _(M.lightMap.channel),
            bumpMapUv: X && _(M.bumpMap.channel),
            normalMapUv: ie && _(M.normalMap.channel),
            displacementMapUv: J && _(M.displacementMap.channel),
            emissiveMapUv: Se && _(M.emissiveMap.channel),
            metalnessMapUv: me && _(M.metalnessMap.channel),
            roughnessMapUv: ye && _(M.roughnessMap.channel),
            anisotropyMapUv: B && _(M.anisotropyMap.channel),
            clearcoatMapUv: ee && _(M.clearcoatMap.channel),
            clearcoatNormalMapUv: j && _(M.clearcoatNormalMap.channel),
            clearcoatRoughnessMapUv: te && _(M.clearcoatRoughnessMap.channel),
            iridescenceMapUv: Me && _(M.iridescenceMap.channel),
            iridescenceThicknessMapUv: re && _(M.iridescenceThicknessMap.channel),
            sheenColorMapUv: de && _(M.sheenColorMap.channel),
            sheenRoughnessMapUv: Le && _(M.sheenRoughnessMap.channel),
            specularMapUv: Ze && _(M.specularMap.channel),
            specularColorMapUv: se && _(M.specularColorMap.channel),
            specularIntensityMapUv: $e && _(M.specularIntensityMap.channel),
            transmissionMapUv: Oe && _(M.transmissionMap.channel),
            thicknessMapUv: Ie && _(M.thicknessMap.channel),
            alphaMapUv: P && _(M.alphaMap.channel),
            vertexTangents: !!z.attributes.tangent && (ie || Ne),
            vertexColors: M.vertexColors,
            vertexAlphas: M.vertexColors === !0 && !!z.attributes.color && z.attributes.color.itemSize === 4,
            vertexUv1s: ue,
            vertexUv2s: Q,
            vertexUv3s: be,
            pointsUvs: $.isPoints === !0 && !!z.attributes.uv && (Ye || P),
            fog: !!U,
            useFog: M.fog === !0,
            fogExp2: U && U.isFogExp2,
            flatShading: M.flatShading === !0,
            sizeAttenuation: M.sizeAttenuation === !0,
            logarithmicDepthBuffer: u,
            skinning: $.isSkinnedMesh === !0,
            morphTargets: z.morphAttributes.position !== void 0,
            morphNormals: z.morphAttributes.normal !== void 0,
            morphColors: z.morphAttributes.color !== void 0,
            morphTargetsCount: D,
            morphTextureStride: G,
            numDirLights: T.directional.length,
            numPointLights: T.point.length,
            numSpotLights: T.spot.length,
            numSpotLightMaps: T.spotLightMap.length,
            numRectAreaLights: T.rectArea.length,
            numHemiLights: T.hemi.length,
            numDirLightShadows: T.directionalShadowMap.length,
            numPointLightShadows: T.pointShadowMap.length,
            numSpotLightShadows: T.spotShadowMap.length,
            numSpotLightShadowsWithMaps: T.numSpotLightShadowsWithMaps,
            numLightProbes: T.numLightProbes,
            numClippingPlanes: a.numPlanes,
            numClipIntersection: a.numIntersection,
            dithering: M.dithering,
            shadowMapEnabled: s1.shadowMap.enabled && O.length > 0,
            shadowMapType: s1.shadowMap.type,
            toneMapping: Fe,
            useLegacyLights: s1._useLegacyLights,
            decodeVideoTexture: Ye && M.map.isVideoTexture === !0 && Qe.getTransfer(M.map.colorSpace) === nt,
            premultipliedAlpha: M.premultipliedAlpha,
            doubleSided: M.side === gn,
            flipSided: M.side === Ft,
            useDepthPacking: M.depthPacking >= 0,
            depthPacking: M.depthPacking || 0,
            index0AttributeName: M.index0AttributeName,
            extensionDerivatives: ge && M.extensions.derivatives === !0,
            extensionFragDepth: ge && M.extensions.fragDepth === !0,
            extensionDrawBuffers: ge && M.extensions.drawBuffers === !0,
            extensionShaderTextureLOD: ge && M.extensions.shaderTextureLOD === !0,
            rendererExtensionFragDepth: h || n.has("EXT_frag_depth"),
            rendererExtensionDrawBuffers: h || n.has("WEBGL_draw_buffers"),
            rendererExtensionShaderTextureLod: h || n.has("EXT_shader_texture_lod"),
            customProgramCacheKey: M.customProgramCacheKey()
        };
    }
    function p(M) {
        let T = [];
        if (M.shaderID ? T.push(M.shaderID) : (T.push(M.customVertexShaderID), T.push(M.customFragmentShaderID)), M.defines !== void 0) for(let O in M.defines)T.push(O), T.push(M.defines[O]);
        return M.isRawShaderMaterial === !1 && (v(T, M), x(T, M), T.push(s1.outputColorSpace)), T.push(M.customProgramCacheKey), T.join();
    }
    function v(M, T) {
        M.push(T.precision), M.push(T.outputColorSpace), M.push(T.envMapMode), M.push(T.envMapCubeUVHeight), M.push(T.mapUv), M.push(T.alphaMapUv), M.push(T.lightMapUv), M.push(T.aoMapUv), M.push(T.bumpMapUv), M.push(T.normalMapUv), M.push(T.displacementMapUv), M.push(T.emissiveMapUv), M.push(T.metalnessMapUv), M.push(T.roughnessMapUv), M.push(T.anisotropyMapUv), M.push(T.clearcoatMapUv), M.push(T.clearcoatNormalMapUv), M.push(T.clearcoatRoughnessMapUv), M.push(T.iridescenceMapUv), M.push(T.iridescenceThicknessMapUv), M.push(T.sheenColorMapUv), M.push(T.sheenRoughnessMapUv), M.push(T.specularMapUv), M.push(T.specularColorMapUv), M.push(T.specularIntensityMapUv), M.push(T.transmissionMapUv), M.push(T.thicknessMapUv), M.push(T.combine), M.push(T.fogExp2), M.push(T.sizeAttenuation), M.push(T.morphTargetsCount), M.push(T.morphAttributeCount), M.push(T.numDirLights), M.push(T.numPointLights), M.push(T.numSpotLights), M.push(T.numSpotLightMaps), M.push(T.numHemiLights), M.push(T.numRectAreaLights), M.push(T.numDirLightShadows), M.push(T.numPointLightShadows), M.push(T.numSpotLightShadows), M.push(T.numSpotLightShadowsWithMaps), M.push(T.numLightProbes), M.push(T.shadowMapType), M.push(T.toneMapping), M.push(T.numClippingPlanes), M.push(T.numClipIntersection), M.push(T.depthPacking);
    }
    function x(M, T) {
        o.disableAll(), T.isWebGL2 && o.enable(0), T.supportsVertexTextures && o.enable(1), T.instancing && o.enable(2), T.instancingColor && o.enable(3), T.matcap && o.enable(4), T.envMap && o.enable(5), T.normalMapObjectSpace && o.enable(6), T.normalMapTangentSpace && o.enable(7), T.clearcoat && o.enable(8), T.iridescence && o.enable(9), T.alphaTest && o.enable(10), T.vertexColors && o.enable(11), T.vertexAlphas && o.enable(12), T.vertexUv1s && o.enable(13), T.vertexUv2s && o.enable(14), T.vertexUv3s && o.enable(15), T.vertexTangents && o.enable(16), T.anisotropy && o.enable(17), M.push(o.mask), o.disableAll(), T.fog && o.enable(0), T.useFog && o.enable(1), T.flatShading && o.enable(2), T.logarithmicDepthBuffer && o.enable(3), T.skinning && o.enable(4), T.morphTargets && o.enable(5), T.morphNormals && o.enable(6), T.morphColors && o.enable(7), T.premultipliedAlpha && o.enable(8), T.shadowMapEnabled && o.enable(9), T.useLegacyLights && o.enable(10), T.doubleSided && o.enable(11), T.flipSided && o.enable(12), T.useDepthPacking && o.enable(13), T.dithering && o.enable(14), T.transmission && o.enable(15), T.sheen && o.enable(16), T.opaque && o.enable(17), T.pointsUvs && o.enable(18), T.decodeVideoTexture && o.enable(19), M.push(o.mask);
    }
    function y(M) {
        let T = m[M.type], O;
        if (T) {
            let Y = nn[T];
            O = xp.clone(Y.uniforms);
        } else O = M.uniforms;
        return O;
    }
    function b(M, T) {
        let O;
        for(let Y = 0, $ = l.length; Y < $; Y++){
            let U = l[Y];
            if (U.cacheKey === T) {
                O = U, ++O.usedTimes;
                break;
            }
        }
        return O === void 0 && (O = new b0(s1, T, M, r), l.push(O)), O;
    }
    function w(M) {
        if (--M.usedTimes === 0) {
            let T = l.indexOf(M);
            l[T] = l[l.length - 1], l.pop(), M.destroy();
        }
    }
    function R(M) {
        c.remove(M);
    }
    function I() {
        c.dispose();
    }
    return {
        getParameters: g,
        getProgramCacheKey: p,
        getUniforms: y,
        acquireProgram: b,
        releaseProgram: w,
        releaseShaderCache: R,
        programs: l,
        dispose: I
    };
}
function w0() {
    let s1 = new WeakMap;
    function e(r) {
        let a = s1.get(r);
        return a === void 0 && (a = {}, s1.set(r, a)), a;
    }
    function t(r) {
        s1.delete(r);
    }
    function n(r, a, o) {
        s1.get(r)[a] = o;
    }
    function i() {
        s1 = new WeakMap;
    }
    return {
        get: e,
        remove: t,
        update: n,
        dispose: i
    };
}
function A0(s1, e) {
    return s1.groupOrder !== e.groupOrder ? s1.groupOrder - e.groupOrder : s1.renderOrder !== e.renderOrder ? s1.renderOrder - e.renderOrder : s1.material.id !== e.material.id ? s1.material.id - e.material.id : s1.z !== e.z ? s1.z - e.z : s1.id - e.id;
}
function Rh(s1, e) {
    return s1.groupOrder !== e.groupOrder ? s1.groupOrder - e.groupOrder : s1.renderOrder !== e.renderOrder ? s1.renderOrder - e.renderOrder : s1.z !== e.z ? e.z - s1.z : s1.id - e.id;
}
function Ch() {
    let s1 = [], e = 0, t = [], n = [], i = [];
    function r() {
        e = 0, t.length = 0, n.length = 0, i.length = 0;
    }
    function a(u, d, f, m, _, g) {
        let p = s1[e];
        return p === void 0 ? (p = {
            id: u.id,
            object: u,
            geometry: d,
            material: f,
            groupOrder: m,
            renderOrder: u.renderOrder,
            z: _,
            group: g
        }, s1[e] = p) : (p.id = u.id, p.object = u, p.geometry = d, p.material = f, p.groupOrder = m, p.renderOrder = u.renderOrder, p.z = _, p.group = g), e++, p;
    }
    function o(u, d, f, m, _, g) {
        let p = a(u, d, f, m, _, g);
        f.transmission > 0 ? n.push(p) : f.transparent === !0 ? i.push(p) : t.push(p);
    }
    function c(u, d, f, m, _, g) {
        let p = a(u, d, f, m, _, g);
        f.transmission > 0 ? n.unshift(p) : f.transparent === !0 ? i.unshift(p) : t.unshift(p);
    }
    function l(u, d) {
        t.length > 1 && t.sort(u || A0), n.length > 1 && n.sort(d || Rh), i.length > 1 && i.sort(d || Rh);
    }
    function h() {
        for(let u = e, d = s1.length; u < d; u++){
            let f = s1[u];
            if (f.id === null) break;
            f.id = null, f.object = null, f.geometry = null, f.material = null, f.group = null;
        }
    }
    return {
        opaque: t,
        transmissive: n,
        transparent: i,
        init: r,
        push: o,
        unshift: c,
        finish: h,
        sort: l
    };
}
function R0() {
    let s1 = new WeakMap;
    function e(n, i) {
        let r = s1.get(n), a;
        return r === void 0 ? (a = new Ch, s1.set(n, [
            a
        ])) : i >= r.length ? (a = new Ch, r.push(a)) : a = r[i], a;
    }
    function t() {
        s1 = new WeakMap;
    }
    return {
        get: e,
        dispose: t
    };
}
function C0() {
    let s1 = {};
    return {
        get: function(e) {
            if (s1[e.id] !== void 0) return s1[e.id];
            let t;
            switch(e.type){
                case "DirectionalLight":
                    t = {
                        direction: new A,
                        color: new pe
                    };
                    break;
                case "SpotLight":
                    t = {
                        position: new A,
                        direction: new A,
                        color: new pe,
                        distance: 0,
                        coneCos: 0,
                        penumbraCos: 0,
                        decay: 0
                    };
                    break;
                case "PointLight":
                    t = {
                        position: new A,
                        color: new pe,
                        distance: 0,
                        decay: 0
                    };
                    break;
                case "HemisphereLight":
                    t = {
                        direction: new A,
                        skyColor: new pe,
                        groundColor: new pe
                    };
                    break;
                case "RectAreaLight":
                    t = {
                        color: new pe,
                        position: new A,
                        halfWidth: new A,
                        halfHeight: new A
                    };
                    break;
            }
            return s1[e.id] = t, t;
        }
    };
}
function P0() {
    let s1 = {};
    return {
        get: function(e) {
            if (s1[e.id] !== void 0) return s1[e.id];
            let t;
            switch(e.type){
                case "DirectionalLight":
                    t = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new Z
                    };
                    break;
                case "SpotLight":
                    t = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new Z
                    };
                    break;
                case "PointLight":
                    t = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new Z,
                        shadowCameraNear: 1,
                        shadowCameraFar: 1e3
                    };
                    break;
            }
            return s1[e.id] = t, t;
        }
    };
}
var L0 = 0;
function I0(s1, e) {
    return (e.castShadow ? 2 : 0) - (s1.castShadow ? 2 : 0) + (e.map ? 1 : 0) - (s1.map ? 1 : 0);
}
function U0(s1, e) {
    let t = new C0, n = P0(), i = {
        version: 0,
        hash: {
            directionalLength: -1,
            pointLength: -1,
            spotLength: -1,
            rectAreaLength: -1,
            hemiLength: -1,
            numDirectionalShadows: -1,
            numPointShadows: -1,
            numSpotShadows: -1,
            numSpotMaps: -1,
            numLightProbes: -1
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
        spotLightMap: [],
        spotShadow: [],
        spotShadowMap: [],
        spotLightMatrix: [],
        rectArea: [],
        rectAreaLTC1: null,
        rectAreaLTC2: null,
        point: [],
        pointShadow: [],
        pointShadowMap: [],
        pointShadowMatrix: [],
        hemi: [],
        numSpotLightShadowsWithMaps: 0,
        numLightProbes: 0
    };
    for(let h = 0; h < 9; h++)i.probe.push(new A);
    let r = new A, a = new ze, o = new ze;
    function c(h, u) {
        let d = 0, f = 0, m = 0;
        for(let Y = 0; Y < 9; Y++)i.probe[Y].set(0, 0, 0);
        let _ = 0, g = 0, p = 0, v = 0, x = 0, y = 0, b = 0, w = 0, R = 0, I = 0, M = 0;
        h.sort(I0);
        let T = u === !0 ? Math.PI : 1;
        for(let Y = 0, $ = h.length; Y < $; Y++){
            let U = h[Y], z = U.color, q = U.intensity, H = U.distance, ne = U.shadow && U.shadow.map ? U.shadow.map.texture : null;
            if (U.isAmbientLight) d += z.r * q * T, f += z.g * q * T, m += z.b * q * T;
            else if (U.isLightProbe) {
                for(let W = 0; W < 9; W++)i.probe[W].addScaledVector(U.sh.coefficients[W], q);
                M++;
            } else if (U.isDirectionalLight) {
                let W = t.get(U);
                if (W.color.copy(U.color).multiplyScalar(U.intensity * T), U.castShadow) {
                    let K = U.shadow, D = n.get(U);
                    D.shadowBias = K.bias, D.shadowNormalBias = K.normalBias, D.shadowRadius = K.radius, D.shadowMapSize = K.mapSize, i.directionalShadow[_] = D, i.directionalShadowMap[_] = ne, i.directionalShadowMatrix[_] = U.shadow.matrix, y++;
                }
                i.directional[_] = W, _++;
            } else if (U.isSpotLight) {
                let W = t.get(U);
                W.position.setFromMatrixPosition(U.matrixWorld), W.color.copy(z).multiplyScalar(q * T), W.distance = H, W.coneCos = Math.cos(U.angle), W.penumbraCos = Math.cos(U.angle * (1 - U.penumbra)), W.decay = U.decay, i.spot[p] = W;
                let K = U.shadow;
                if (U.map && (i.spotLightMap[R] = U.map, R++, K.updateMatrices(U), U.castShadow && I++), i.spotLightMatrix[p] = K.matrix, U.castShadow) {
                    let D = n.get(U);
                    D.shadowBias = K.bias, D.shadowNormalBias = K.normalBias, D.shadowRadius = K.radius, D.shadowMapSize = K.mapSize, i.spotShadow[p] = D, i.spotShadowMap[p] = ne, w++;
                }
                p++;
            } else if (U.isRectAreaLight) {
                let W = t.get(U);
                W.color.copy(z).multiplyScalar(q), W.halfWidth.set(U.width * .5, 0, 0), W.halfHeight.set(0, U.height * .5, 0), i.rectArea[v] = W, v++;
            } else if (U.isPointLight) {
                let W = t.get(U);
                if (W.color.copy(U.color).multiplyScalar(U.intensity * T), W.distance = U.distance, W.decay = U.decay, U.castShadow) {
                    let K = U.shadow, D = n.get(U);
                    D.shadowBias = K.bias, D.shadowNormalBias = K.normalBias, D.shadowRadius = K.radius, D.shadowMapSize = K.mapSize, D.shadowCameraNear = K.camera.near, D.shadowCameraFar = K.camera.far, i.pointShadow[g] = D, i.pointShadowMap[g] = ne, i.pointShadowMatrix[g] = U.shadow.matrix, b++;
                }
                i.point[g] = W, g++;
            } else if (U.isHemisphereLight) {
                let W = t.get(U);
                W.skyColor.copy(U.color).multiplyScalar(q * T), W.groundColor.copy(U.groundColor).multiplyScalar(q * T), i.hemi[x] = W, x++;
            }
        }
        v > 0 && (e.isWebGL2 || s1.has("OES_texture_float_linear") === !0 ? (i.rectAreaLTC1 = le.LTC_FLOAT_1, i.rectAreaLTC2 = le.LTC_FLOAT_2) : s1.has("OES_texture_half_float_linear") === !0 ? (i.rectAreaLTC1 = le.LTC_HALF_1, i.rectAreaLTC2 = le.LTC_HALF_2) : console.error("THREE.WebGLRenderer: Unable to use RectAreaLight. Missing WebGL extensions.")), i.ambient[0] = d, i.ambient[1] = f, i.ambient[2] = m;
        let O = i.hash;
        (O.directionalLength !== _ || O.pointLength !== g || O.spotLength !== p || O.rectAreaLength !== v || O.hemiLength !== x || O.numDirectionalShadows !== y || O.numPointShadows !== b || O.numSpotShadows !== w || O.numSpotMaps !== R || O.numLightProbes !== M) && (i.directional.length = _, i.spot.length = p, i.rectArea.length = v, i.point.length = g, i.hemi.length = x, i.directionalShadow.length = y, i.directionalShadowMap.length = y, i.pointShadow.length = b, i.pointShadowMap.length = b, i.spotShadow.length = w, i.spotShadowMap.length = w, i.directionalShadowMatrix.length = y, i.pointShadowMatrix.length = b, i.spotLightMatrix.length = w + R - I, i.spotLightMap.length = R, i.numSpotLightShadowsWithMaps = I, i.numLightProbes = M, O.directionalLength = _, O.pointLength = g, O.spotLength = p, O.rectAreaLength = v, O.hemiLength = x, O.numDirectionalShadows = y, O.numPointShadows = b, O.numSpotShadows = w, O.numSpotMaps = R, O.numLightProbes = M, i.version = L0++);
    }
    function l(h, u) {
        let d = 0, f = 0, m = 0, _ = 0, g = 0, p = u.matrixWorldInverse;
        for(let v = 0, x = h.length; v < x; v++){
            let y = h[v];
            if (y.isDirectionalLight) {
                let b = i.directional[d];
                b.direction.setFromMatrixPosition(y.matrixWorld), r.setFromMatrixPosition(y.target.matrixWorld), b.direction.sub(r), b.direction.transformDirection(p), d++;
            } else if (y.isSpotLight) {
                let b = i.spot[m];
                b.position.setFromMatrixPosition(y.matrixWorld), b.position.applyMatrix4(p), b.direction.setFromMatrixPosition(y.matrixWorld), r.setFromMatrixPosition(y.target.matrixWorld), b.direction.sub(r), b.direction.transformDirection(p), m++;
            } else if (y.isRectAreaLight) {
                let b = i.rectArea[_];
                b.position.setFromMatrixPosition(y.matrixWorld), b.position.applyMatrix4(p), o.identity(), a.copy(y.matrixWorld), a.premultiply(p), o.extractRotation(a), b.halfWidth.set(y.width * .5, 0, 0), b.halfHeight.set(0, y.height * .5, 0), b.halfWidth.applyMatrix4(o), b.halfHeight.applyMatrix4(o), _++;
            } else if (y.isPointLight) {
                let b = i.point[f];
                b.position.setFromMatrixPosition(y.matrixWorld), b.position.applyMatrix4(p), f++;
            } else if (y.isHemisphereLight) {
                let b = i.hemi[g];
                b.direction.setFromMatrixPosition(y.matrixWorld), b.direction.transformDirection(p), g++;
            }
        }
    }
    return {
        setup: c,
        setupView: l,
        state: i
    };
}
function Ph(s1, e) {
    let t = new U0(s1, e), n = [], i = [];
    function r() {
        n.length = 0, i.length = 0;
    }
    function a(u) {
        n.push(u);
    }
    function o(u) {
        i.push(u);
    }
    function c(u) {
        t.setup(n, u);
    }
    function l(u) {
        t.setupView(n, u);
    }
    return {
        init: r,
        state: {
            lightsArray: n,
            shadowsArray: i,
            lights: t
        },
        setupLights: c,
        setupLightsView: l,
        pushLight: a,
        pushShadow: o
    };
}
function D0(s1, e) {
    let t = new WeakMap;
    function n(r, a = 0) {
        let o = t.get(r), c;
        return o === void 0 ? (c = new Ph(s1, e), t.set(r, [
            c
        ])) : a >= o.length ? (c = new Ph(s1, e), o.push(c)) : c = o[a], c;
    }
    function i() {
        t = new WeakMap;
    }
    return {
        get: n,
        dispose: i
    };
}
var Qr = class extends bt {
    constructor(e){
        super(), this.isMeshDepthMaterial = !0, this.type = "MeshDepthMaterial", this.depthPacking = Cf, this.map = null, this.alphaMap = null, this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.wireframe = !1, this.wireframeLinewidth = 1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.depthPacking = e.depthPacking, this.map = e.map, this.alphaMap = e.alphaMap, this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this;
    }
}, jr = class extends bt {
    constructor(e){
        super(), this.isMeshDistanceMaterial = !0, this.type = "MeshDistanceMaterial", this.map = null, this.alphaMap = null, this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.map = e.map, this.alphaMap = e.alphaMap, this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this;
    }
}, N0 = `void main() {
	gl_Position = vec4( position, 1.0 );
}`, O0 = `uniform sampler2D shadow_pass;
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
function F0(s1, e, t) {
    let n = new Ps, i = new Z, r = new Z, a = new je, o = new Qr({
        depthPacking: Pf
    }), c = new jr, l = {}, h = t.maxTextureSize, u = {
        [Bn]: Ft,
        [Ft]: Bn,
        [gn]: gn
    }, d = new jt({
        defines: {
            VSM_SAMPLES: 8
        },
        uniforms: {
            shadow_pass: {
                value: null
            },
            resolution: {
                value: new Z
            },
            radius: {
                value: 4
            }
        },
        vertexShader: N0,
        fragmentShader: O0
    }), f = d.clone();
    f.defines.HORIZONTAL_PASS = 1;
    let m = new Ge;
    m.setAttribute("position", new et(new Float32Array([
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
    let _ = new Mt(m, d), g = this;
    this.enabled = !1, this.autoUpdate = !0, this.needsUpdate = !1, this.type = cd;
    let p = this.type;
    this.render = function(b, w, R) {
        if (g.enabled === !1 || g.autoUpdate === !1 && g.needsUpdate === !1 || b.length === 0) return;
        let I = s1.getRenderTarget(), M = s1.getActiveCubeFace(), T = s1.getActiveMipmapLevel(), O = s1.state;
        O.setBlending(Dn), O.buffers.color.setClear(1, 1, 1, 1), O.buffers.depth.setTest(!0), O.setScissorTest(!1);
        let Y = p !== pn && this.type === pn, $ = p === pn && this.type !== pn;
        for(let U = 0, z = b.length; U < z; U++){
            let q = b[U], H = q.shadow;
            if (H === void 0) {
                console.warn("THREE.WebGLShadowMap:", q, "has no shadow.");
                continue;
            }
            if (H.autoUpdate === !1 && H.needsUpdate === !1) continue;
            i.copy(H.mapSize);
            let ne = H.getFrameExtents();
            if (i.multiply(ne), r.copy(H.mapSize), (i.x > h || i.y > h) && (i.x > h && (r.x = Math.floor(h / ne.x), i.x = r.x * ne.x, H.mapSize.x = r.x), i.y > h && (r.y = Math.floor(h / ne.y), i.y = r.y * ne.y, H.mapSize.y = r.y)), H.map === null || Y === !0 || $ === !0) {
                let K = this.type !== pn ? {
                    minFilter: pt,
                    magFilter: pt
                } : {};
                H.map !== null && H.map.dispose(), H.map = new qt(i.x, i.y, K), H.map.texture.name = q.name + ".shadowMap", H.camera.updateProjectionMatrix();
            }
            s1.setRenderTarget(H.map), s1.clear();
            let W = H.getViewportCount();
            for(let K = 0; K < W; K++){
                let D = H.getViewport(K);
                a.set(r.x * D.x, r.y * D.y, r.x * D.z, r.y * D.w), O.viewport(a), H.updateMatrices(q, K), n = H.getFrustum(), y(w, R, H.camera, q, this.type);
            }
            H.isPointLightShadow !== !0 && this.type === pn && v(H, R), H.needsUpdate = !1;
        }
        p = this.type, g.needsUpdate = !1, s1.setRenderTarget(I, M, T);
    };
    function v(b, w) {
        let R = e.update(_);
        d.defines.VSM_SAMPLES !== b.blurSamples && (d.defines.VSM_SAMPLES = b.blurSamples, f.defines.VSM_SAMPLES = b.blurSamples, d.needsUpdate = !0, f.needsUpdate = !0), b.mapPass === null && (b.mapPass = new qt(i.x, i.y)), d.uniforms.shadow_pass.value = b.map.texture, d.uniforms.resolution.value = b.mapSize, d.uniforms.radius.value = b.radius, s1.setRenderTarget(b.mapPass), s1.clear(), s1.renderBufferDirect(w, null, R, d, _, null), f.uniforms.shadow_pass.value = b.mapPass.texture, f.uniforms.resolution.value = b.mapSize, f.uniforms.radius.value = b.radius, s1.setRenderTarget(b.map), s1.clear(), s1.renderBufferDirect(w, null, R, f, _, null);
    }
    function x(b, w, R, I) {
        let M = null, T = R.isPointLight === !0 ? b.customDistanceMaterial : b.customDepthMaterial;
        if (T !== void 0) M = T;
        else if (M = R.isPointLight === !0 ? c : o, s1.localClippingEnabled && w.clipShadows === !0 && Array.isArray(w.clippingPlanes) && w.clippingPlanes.length !== 0 || w.displacementMap && w.displacementScale !== 0 || w.alphaMap && w.alphaTest > 0 || w.map && w.alphaTest > 0) {
            let O = M.uuid, Y = w.uuid, $ = l[O];
            $ === void 0 && ($ = {}, l[O] = $);
            let U = $[Y];
            U === void 0 && (U = M.clone(), $[Y] = U), M = U;
        }
        if (M.visible = w.visible, M.wireframe = w.wireframe, I === pn ? M.side = w.shadowSide !== null ? w.shadowSide : w.side : M.side = w.shadowSide !== null ? w.shadowSide : u[w.side], M.alphaMap = w.alphaMap, M.alphaTest = w.alphaTest, M.map = w.map, M.clipShadows = w.clipShadows, M.clippingPlanes = w.clippingPlanes, M.clipIntersection = w.clipIntersection, M.displacementMap = w.displacementMap, M.displacementScale = w.displacementScale, M.displacementBias = w.displacementBias, M.wireframeLinewidth = w.wireframeLinewidth, M.linewidth = w.linewidth, R.isPointLight === !0 && M.isMeshDistanceMaterial === !0) {
            let O = s1.properties.get(M);
            O.light = R;
        }
        return M;
    }
    function y(b, w, R, I, M) {
        if (b.visible === !1) return;
        if (b.layers.test(w.layers) && (b.isMesh || b.isLine || b.isPoints) && (b.castShadow || b.receiveShadow && M === pn) && (!b.frustumCulled || n.intersectsObject(b))) {
            b.modelViewMatrix.multiplyMatrices(R.matrixWorldInverse, b.matrixWorld);
            let Y = e.update(b), $ = b.material;
            if (Array.isArray($)) {
                let U = Y.groups;
                for(let z = 0, q = U.length; z < q; z++){
                    let H = U[z], ne = $[H.materialIndex];
                    if (ne && ne.visible) {
                        let W = x(b, ne, I, M);
                        s1.renderBufferDirect(R, null, Y, W, b, H);
                    }
                }
            } else if ($.visible) {
                let U = x(b, $, I, M);
                s1.renderBufferDirect(R, null, Y, U, b, null);
            }
        }
        let O = b.children;
        for(let Y = 0, $ = O.length; Y < $; Y++)y(O[Y], w, R, I, M);
    }
}
function B0(s1, e, t) {
    let n = t.isWebGL2;
    function i() {
        let P = !1, ce = new je, ae = null, ge = new je(0, 0, 0, 0);
        return {
            setMask: function(ue) {
                ae !== ue && !P && (s1.colorMask(ue, ue, ue, ue), ae = ue);
            },
            setLocked: function(ue) {
                P = ue;
            },
            setClear: function(ue, Q, be, Fe, At) {
                At === !0 && (ue *= Fe, Q *= Fe, be *= Fe), ce.set(ue, Q, be, Fe), ge.equals(ce) === !1 && (s1.clearColor(ue, Q, be, Fe), ge.copy(ce));
            },
            reset: function() {
                P = !1, ae = null, ge.set(-1, 0, 0, 0);
            }
        };
    }
    function r() {
        let P = !1, ce = null, ae = null, ge = null;
        return {
            setTest: function(ue) {
                ue ? Ee(s1.DEPTH_TEST) : Te(s1.DEPTH_TEST);
            },
            setMask: function(ue) {
                ce !== ue && !P && (s1.depthMask(ue), ce = ue);
            },
            setFunc: function(ue) {
                if (ae !== ue) {
                    switch(ue){
                        case nf:
                            s1.depthFunc(s1.NEVER);
                            break;
                        case sf:
                            s1.depthFunc(s1.ALWAYS);
                            break;
                        case rf:
                            s1.depthFunc(s1.LESS);
                            break;
                        case uo:
                            s1.depthFunc(s1.LEQUAL);
                            break;
                        case af:
                            s1.depthFunc(s1.EQUAL);
                            break;
                        case of:
                            s1.depthFunc(s1.GEQUAL);
                            break;
                        case cf:
                            s1.depthFunc(s1.GREATER);
                            break;
                        case lf:
                            s1.depthFunc(s1.NOTEQUAL);
                            break;
                        default:
                            s1.depthFunc(s1.LEQUAL);
                    }
                    ae = ue;
                }
            },
            setLocked: function(ue) {
                P = ue;
            },
            setClear: function(ue) {
                ge !== ue && (s1.clearDepth(ue), ge = ue);
            },
            reset: function() {
                P = !1, ce = null, ae = null, ge = null;
            }
        };
    }
    function a() {
        let P = !1, ce = null, ae = null, ge = null, ue = null, Q = null, be = null, Fe = null, At = null;
        return {
            setTest: function(tt) {
                P || (tt ? Ee(s1.STENCIL_TEST) : Te(s1.STENCIL_TEST));
            },
            setMask: function(tt) {
                ce !== tt && !P && (s1.stencilMask(tt), ce = tt);
            },
            setFunc: function(tt, tn, Rt) {
                (ae !== tt || ge !== tn || ue !== Rt) && (s1.stencilFunc(tt, tn, Rt), ae = tt, ge = tn, ue = Rt);
            },
            setOp: function(tt, tn, Rt) {
                (Q !== tt || be !== tn || Fe !== Rt) && (s1.stencilOp(tt, tn, Rt), Q = tt, be = tn, Fe = Rt);
            },
            setLocked: function(tt) {
                P = tt;
            },
            setClear: function(tt) {
                At !== tt && (s1.clearStencil(tt), At = tt);
            },
            reset: function() {
                P = !1, ce = null, ae = null, ge = null, ue = null, Q = null, be = null, Fe = null, At = null;
            }
        };
    }
    let o = new i, c = new r, l = new a, h = new WeakMap, u = new WeakMap, d = {}, f = {}, m = new WeakMap, _ = [], g = null, p = !1, v = null, x = null, y = null, b = null, w = null, R = null, I = null, M = !1, T = null, O = null, Y = null, $ = null, U = null, z = s1.getParameter(s1.MAX_COMBINED_TEXTURE_IMAGE_UNITS), q = !1, H = 0, ne = s1.getParameter(s1.VERSION);
    ne.indexOf("WebGL") !== -1 ? (H = parseFloat(/^WebGL (\d)/.exec(ne)[1]), q = H >= 1) : ne.indexOf("OpenGL ES") !== -1 && (H = parseFloat(/^OpenGL ES (\d)/.exec(ne)[1]), q = H >= 2);
    let W = null, K = {}, D = s1.getParameter(s1.SCISSOR_BOX), G = s1.getParameter(s1.VIEWPORT), he = new je().fromArray(D), fe = new je().fromArray(G);
    function _e(P, ce, ae, ge) {
        let ue = new Uint8Array(4), Q = s1.createTexture();
        s1.bindTexture(P, Q), s1.texParameteri(P, s1.TEXTURE_MIN_FILTER, s1.NEAREST), s1.texParameteri(P, s1.TEXTURE_MAG_FILTER, s1.NEAREST);
        for(let be = 0; be < ae; be++)n && (P === s1.TEXTURE_3D || P === s1.TEXTURE_2D_ARRAY) ? s1.texImage3D(ce, 0, s1.RGBA, 1, 1, ge, 0, s1.RGBA, s1.UNSIGNED_BYTE, ue) : s1.texImage2D(ce + be, 0, s1.RGBA, 1, 1, 0, s1.RGBA, s1.UNSIGNED_BYTE, ue);
        return Q;
    }
    let we = {};
    we[s1.TEXTURE_2D] = _e(s1.TEXTURE_2D, s1.TEXTURE_2D, 1), we[s1.TEXTURE_CUBE_MAP] = _e(s1.TEXTURE_CUBE_MAP, s1.TEXTURE_CUBE_MAP_POSITIVE_X, 6), n && (we[s1.TEXTURE_2D_ARRAY] = _e(s1.TEXTURE_2D_ARRAY, s1.TEXTURE_2D_ARRAY, 1, 1), we[s1.TEXTURE_3D] = _e(s1.TEXTURE_3D, s1.TEXTURE_3D, 1, 1)), o.setClear(0, 0, 0, 1), c.setClear(1), l.setClear(0), Ee(s1.DEPTH_TEST), c.setFunc(uo), J(!1), Se(rl), Ee(s1.CULL_FACE), X(Dn);
    function Ee(P) {
        d[P] !== !0 && (s1.enable(P), d[P] = !0);
    }
    function Te(P) {
        d[P] !== !1 && (s1.disable(P), d[P] = !1);
    }
    function Ye(P, ce) {
        return f[P] !== ce ? (s1.bindFramebuffer(P, ce), f[P] = ce, n && (P === s1.DRAW_FRAMEBUFFER && (f[s1.FRAMEBUFFER] = ce), P === s1.FRAMEBUFFER && (f[s1.DRAW_FRAMEBUFFER] = ce)), !0) : !1;
    }
    function it(P, ce) {
        let ae = _, ge = !1;
        if (P) if (ae = m.get(ce), ae === void 0 && (ae = [], m.set(ce, ae)), P.isWebGLMultipleRenderTargets) {
            let ue = P.texture;
            if (ae.length !== ue.length || ae[0] !== s1.COLOR_ATTACHMENT0) {
                for(let Q = 0, be = ue.length; Q < be; Q++)ae[Q] = s1.COLOR_ATTACHMENT0 + Q;
                ae.length = ue.length, ge = !0;
            }
        } else ae[0] !== s1.COLOR_ATTACHMENT0 && (ae[0] = s1.COLOR_ATTACHMENT0, ge = !0);
        else ae[0] !== s1.BACK && (ae[0] = s1.BACK, ge = !0);
        ge && (t.isWebGL2 ? s1.drawBuffers(ae) : e.get("WEBGL_draw_buffers").drawBuffersWEBGL(ae));
    }
    function Ce(P) {
        return g !== P ? (s1.useProgram(P), g = P, !0) : !1;
    }
    let L = {
        [Bi]: s1.FUNC_ADD,
        [Xd]: s1.FUNC_SUBTRACT,
        [qd]: s1.FUNC_REVERSE_SUBTRACT
    };
    if (n) L[ll] = s1.MIN, L[hl] = s1.MAX;
    else {
        let P = e.get("EXT_blend_minmax");
        P !== null && (L[ll] = P.MIN_EXT, L[hl] = P.MAX_EXT);
    }
    let oe = {
        [Yd]: s1.ZERO,
        [Zd]: s1.ONE,
        [Jd]: s1.SRC_COLOR,
        [ld]: s1.SRC_ALPHA,
        [tf]: s1.SRC_ALPHA_SATURATE,
        [jd]: s1.DST_COLOR,
        [Kd]: s1.DST_ALPHA,
        [$d]: s1.ONE_MINUS_SRC_COLOR,
        [hd]: s1.ONE_MINUS_SRC_ALPHA,
        [ef]: s1.ONE_MINUS_DST_COLOR,
        [Qd]: s1.ONE_MINUS_DST_ALPHA
    };
    function X(P, ce, ae, ge, ue, Q, be, Fe) {
        if (P === Dn) {
            p === !0 && (Te(s1.BLEND), p = !1);
            return;
        }
        if (p === !1 && (Ee(s1.BLEND), p = !0), P !== Wd) {
            if (P !== v || Fe !== M) {
                if ((x !== Bi || w !== Bi) && (s1.blendEquation(s1.FUNC_ADD), x = Bi, w = Bi), Fe) switch(P){
                    case Wi:
                        s1.blendFuncSeparate(s1.ONE, s1.ONE_MINUS_SRC_ALPHA, s1.ONE, s1.ONE_MINUS_SRC_ALPHA);
                        break;
                    case al:
                        s1.blendFunc(s1.ONE, s1.ONE);
                        break;
                    case ol:
                        s1.blendFuncSeparate(s1.ZERO, s1.ONE_MINUS_SRC_COLOR, s1.ZERO, s1.ONE);
                        break;
                    case cl:
                        s1.blendFuncSeparate(s1.ZERO, s1.SRC_COLOR, s1.ZERO, s1.SRC_ALPHA);
                        break;
                    default:
                        console.error("THREE.WebGLState: Invalid blending: ", P);
                        break;
                }
                else switch(P){
                    case Wi:
                        s1.blendFuncSeparate(s1.SRC_ALPHA, s1.ONE_MINUS_SRC_ALPHA, s1.ONE, s1.ONE_MINUS_SRC_ALPHA);
                        break;
                    case al:
                        s1.blendFunc(s1.SRC_ALPHA, s1.ONE);
                        break;
                    case ol:
                        s1.blendFuncSeparate(s1.ZERO, s1.ONE_MINUS_SRC_COLOR, s1.ZERO, s1.ONE);
                        break;
                    case cl:
                        s1.blendFunc(s1.ZERO, s1.SRC_COLOR);
                        break;
                    default:
                        console.error("THREE.WebGLState: Invalid blending: ", P);
                        break;
                }
                y = null, b = null, R = null, I = null, v = P, M = Fe;
            }
            return;
        }
        ue = ue || ce, Q = Q || ae, be = be || ge, (ce !== x || ue !== w) && (s1.blendEquationSeparate(L[ce], L[ue]), x = ce, w = ue), (ae !== y || ge !== b || Q !== R || be !== I) && (s1.blendFuncSeparate(oe[ae], oe[ge], oe[Q], oe[be]), y = ae, b = ge, R = Q, I = be), v = P, M = !1;
    }
    function ie(P, ce) {
        P.side === gn ? Te(s1.CULL_FACE) : Ee(s1.CULL_FACE);
        let ae = P.side === Ft;
        ce && (ae = !ae), J(ae), P.blending === Wi && P.transparent === !1 ? X(Dn) : X(P.blending, P.blendEquation, P.blendSrc, P.blendDst, P.blendEquationAlpha, P.blendSrcAlpha, P.blendDstAlpha, P.premultipliedAlpha), c.setFunc(P.depthFunc), c.setTest(P.depthTest), c.setMask(P.depthWrite), o.setMask(P.colorWrite);
        let ge = P.stencilWrite;
        l.setTest(ge), ge && (l.setMask(P.stencilWriteMask), l.setFunc(P.stencilFunc, P.stencilRef, P.stencilFuncMask), l.setOp(P.stencilFail, P.stencilZFail, P.stencilZPass)), ye(P.polygonOffset, P.polygonOffsetFactor, P.polygonOffsetUnits), P.alphaToCoverage === !0 ? Ee(s1.SAMPLE_ALPHA_TO_COVERAGE) : Te(s1.SAMPLE_ALPHA_TO_COVERAGE);
    }
    function J(P) {
        T !== P && (P ? s1.frontFace(s1.CW) : s1.frontFace(s1.CCW), T = P);
    }
    function Se(P) {
        P !== kd ? (Ee(s1.CULL_FACE), P !== O && (P === rl ? s1.cullFace(s1.BACK) : P === Hd ? s1.cullFace(s1.FRONT) : s1.cullFace(s1.FRONT_AND_BACK))) : Te(s1.CULL_FACE), O = P;
    }
    function me(P) {
        P !== Y && (q && s1.lineWidth(P), Y = P);
    }
    function ye(P, ce, ae) {
        P ? (Ee(s1.POLYGON_OFFSET_FILL), ($ !== ce || U !== ae) && (s1.polygonOffset(ce, ae), $ = ce, U = ae)) : Te(s1.POLYGON_OFFSET_FILL);
    }
    function Ne(P) {
        P ? Ee(s1.SCISSOR_TEST) : Te(s1.SCISSOR_TEST);
    }
    function qe(P) {
        P === void 0 && (P = s1.TEXTURE0 + z - 1), W !== P && (s1.activeTexture(P), W = P);
    }
    function rt(P, ce, ae) {
        ae === void 0 && (W === null ? ae = s1.TEXTURE0 + z - 1 : ae = W);
        let ge = K[ae];
        ge === void 0 && (ge = {
            type: void 0,
            texture: void 0
        }, K[ae] = ge), (ge.type !== P || ge.texture !== ce) && (W !== ae && (s1.activeTexture(ae), W = ae), s1.bindTexture(P, ce || we[P]), ge.type = P, ge.texture = ce);
    }
    function C() {
        let P = K[W];
        P !== void 0 && P.type !== void 0 && (s1.bindTexture(P.type, null), P.type = void 0, P.texture = void 0);
    }
    function S() {
        try {
            s1.compressedTexImage2D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function B() {
        try {
            s1.compressedTexImage3D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function ee() {
        try {
            s1.texSubImage2D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function j() {
        try {
            s1.texSubImage3D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function te() {
        try {
            s1.compressedTexSubImage2D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function Me() {
        try {
            s1.compressedTexSubImage3D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function re() {
        try {
            s1.texStorage2D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function de() {
        try {
            s1.texStorage3D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function Le() {
        try {
            s1.texImage2D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function Ze() {
        try {
            s1.texImage3D.apply(s1, arguments);
        } catch (P) {
            console.error("THREE.WebGLState:", P);
        }
    }
    function se(P) {
        he.equals(P) === !1 && (s1.scissor(P.x, P.y, P.z, P.w), he.copy(P));
    }
    function $e(P) {
        fe.equals(P) === !1 && (s1.viewport(P.x, P.y, P.z, P.w), fe.copy(P));
    }
    function Oe(P, ce) {
        let ae = u.get(ce);
        ae === void 0 && (ae = new WeakMap, u.set(ce, ae));
        let ge = ae.get(P);
        ge === void 0 && (ge = s1.getUniformBlockIndex(ce, P.name), ae.set(P, ge));
    }
    function Ie(P, ce) {
        let ge = u.get(ce).get(P);
        h.get(ce) !== ge && (s1.uniformBlockBinding(ce, ge, P.__bindingPointIndex), h.set(ce, ge));
    }
    function Re() {
        s1.disable(s1.BLEND), s1.disable(s1.CULL_FACE), s1.disable(s1.DEPTH_TEST), s1.disable(s1.POLYGON_OFFSET_FILL), s1.disable(s1.SCISSOR_TEST), s1.disable(s1.STENCIL_TEST), s1.disable(s1.SAMPLE_ALPHA_TO_COVERAGE), s1.blendEquation(s1.FUNC_ADD), s1.blendFunc(s1.ONE, s1.ZERO), s1.blendFuncSeparate(s1.ONE, s1.ZERO, s1.ONE, s1.ZERO), s1.colorMask(!0, !0, !0, !0), s1.clearColor(0, 0, 0, 0), s1.depthMask(!0), s1.depthFunc(s1.LESS), s1.clearDepth(1), s1.stencilMask(4294967295), s1.stencilFunc(s1.ALWAYS, 0, 4294967295), s1.stencilOp(s1.KEEP, s1.KEEP, s1.KEEP), s1.clearStencil(0), s1.cullFace(s1.BACK), s1.frontFace(s1.CCW), s1.polygonOffset(0, 0), s1.activeTexture(s1.TEXTURE0), s1.bindFramebuffer(s1.FRAMEBUFFER, null), n === !0 && (s1.bindFramebuffer(s1.DRAW_FRAMEBUFFER, null), s1.bindFramebuffer(s1.READ_FRAMEBUFFER, null)), s1.useProgram(null), s1.lineWidth(1), s1.scissor(0, 0, s1.canvas.width, s1.canvas.height), s1.viewport(0, 0, s1.canvas.width, s1.canvas.height), d = {}, W = null, K = {}, f = {}, m = new WeakMap, _ = [], g = null, p = !1, v = null, x = null, y = null, b = null, w = null, R = null, I = null, M = !1, T = null, O = null, Y = null, $ = null, U = null, he.set(0, 0, s1.canvas.width, s1.canvas.height), fe.set(0, 0, s1.canvas.width, s1.canvas.height), o.reset(), c.reset(), l.reset();
    }
    return {
        buffers: {
            color: o,
            depth: c,
            stencil: l
        },
        enable: Ee,
        disable: Te,
        bindFramebuffer: Ye,
        drawBuffers: it,
        useProgram: Ce,
        setBlending: X,
        setMaterial: ie,
        setFlipSided: J,
        setCullFace: Se,
        setLineWidth: me,
        setPolygonOffset: ye,
        setScissorTest: Ne,
        activeTexture: qe,
        bindTexture: rt,
        unbindTexture: C,
        compressedTexImage2D: S,
        compressedTexImage3D: B,
        texImage2D: Le,
        texImage3D: Ze,
        updateUBOMapping: Oe,
        uniformBlockBinding: Ie,
        texStorage2D: re,
        texStorage3D: de,
        texSubImage2D: ee,
        texSubImage3D: j,
        compressedTexSubImage2D: te,
        compressedTexSubImage3D: Me,
        scissor: se,
        viewport: $e,
        reset: Re
    };
}
function z0(s1, e, t, n, i, r, a) {
    let o = i.isWebGL2, c = i.maxTextures, l = i.maxCubemapSize, h = i.maxTextureSize, u = i.maxSamples, d = e.has("WEBGL_multisampled_render_to_texture") ? e.get("WEBGL_multisampled_render_to_texture") : null, f = typeof navigator > "u" ? !1 : /OculusBrowser/g.test(navigator.userAgent), m = new WeakMap, _, g = new WeakMap, p = !1;
    try {
        p = typeof OffscreenCanvas < "u" && new OffscreenCanvas(1, 1).getContext("2d") !== null;
    } catch  {}
    function v(C, S) {
        return p ? new OffscreenCanvas(C, S) : ws("canvas");
    }
    function x(C, S, B, ee) {
        let j = 1;
        if ((C.width > ee || C.height > ee) && (j = ee / Math.max(C.width, C.height)), j < 1 || S === !0) if (typeof HTMLImageElement < "u" && C instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && C instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && C instanceof ImageBitmap) {
            let te = S ? Wr : Math.floor, Me = te(j * C.width), re = te(j * C.height);
            _ === void 0 && (_ = v(Me, re));
            let de = B ? v(Me, re) : _;
            return de.width = Me, de.height = re, de.getContext("2d").drawImage(C, 0, 0, Me, re), console.warn("THREE.WebGLRenderer: Texture has been resized from (" + C.width + "x" + C.height + ") to (" + Me + "x" + re + ")."), de;
        } else return "data" in C && console.warn("THREE.WebGLRenderer: Image in DataTexture is too big (" + C.width + "x" + C.height + ")."), C;
        return C;
    }
    function y(C) {
        return mo(C.width) && mo(C.height);
    }
    function b(C) {
        return o ? !1 : C.wrapS !== It || C.wrapT !== It || C.minFilter !== pt && C.minFilter !== mt;
    }
    function w(C, S) {
        return C.generateMipmaps && S && C.minFilter !== pt && C.minFilter !== mt;
    }
    function R(C) {
        s1.generateMipmap(C);
    }
    function I(C, S, B, ee, j = !1) {
        if (o === !1) return S;
        if (C !== null) {
            if (s1[C] !== void 0) return s1[C];
            console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '" + C + "'");
        }
        let te = S;
        if (S === s1.RED && (B === s1.FLOAT && (te = s1.R32F), B === s1.HALF_FLOAT && (te = s1.R16F), B === s1.UNSIGNED_BYTE && (te = s1.R8)), S === s1.RED_INTEGER && (B === s1.UNSIGNED_BYTE && (te = s1.R8UI), B === s1.UNSIGNED_SHORT && (te = s1.R16UI), B === s1.UNSIGNED_INT && (te = s1.R32UI), B === s1.BYTE && (te = s1.R8I), B === s1.SHORT && (te = s1.R16I), B === s1.INT && (te = s1.R32I)), S === s1.RG && (B === s1.FLOAT && (te = s1.RG32F), B === s1.HALF_FLOAT && (te = s1.RG16F), B === s1.UNSIGNED_BYTE && (te = s1.RG8)), S === s1.RGBA) {
            let Me = j ? zr : Qe.getTransfer(ee);
            B === s1.FLOAT && (te = s1.RGBA32F), B === s1.HALF_FLOAT && (te = s1.RGBA16F), B === s1.UNSIGNED_BYTE && (te = Me === nt ? s1.SRGB8_ALPHA8 : s1.RGBA8), B === s1.UNSIGNED_SHORT_4_4_4_4 && (te = s1.RGBA4), B === s1.UNSIGNED_SHORT_5_5_5_1 && (te = s1.RGB5_A1);
        }
        return (te === s1.R16F || te === s1.R32F || te === s1.RG16F || te === s1.RG32F || te === s1.RGBA16F || te === s1.RGBA32F) && e.get("EXT_color_buffer_float"), te;
    }
    function M(C, S, B) {
        return w(C, B) === !0 || C.isFramebufferTexture && C.minFilter !== pt && C.minFilter !== mt ? Math.log2(Math.max(S.width, S.height)) + 1 : C.mipmaps !== void 0 && C.mipmaps.length > 0 ? C.mipmaps.length : C.isCompressedTexture && Array.isArray(C.image) ? S.mipmaps.length : 1;
    }
    function T(C) {
        return C === pt || C === fo || C === Lr ? s1.NEAREST : s1.LINEAR;
    }
    function O(C) {
        let S = C.target;
        S.removeEventListener("dispose", O), $(S), S.isVideoTexture && m.delete(S);
    }
    function Y(C) {
        let S = C.target;
        S.removeEventListener("dispose", Y), z(S);
    }
    function $(C) {
        let S = n.get(C);
        if (S.__webglInit === void 0) return;
        let B = C.source, ee = g.get(B);
        if (ee) {
            let j = ee[S.__cacheKey];
            j.usedTimes--, j.usedTimes === 0 && U(C), Object.keys(ee).length === 0 && g.delete(B);
        }
        n.remove(C);
    }
    function U(C) {
        let S = n.get(C);
        s1.deleteTexture(S.__webglTexture);
        let B = C.source, ee = g.get(B);
        delete ee[S.__cacheKey], a.memory.textures--;
    }
    function z(C) {
        let S = C.texture, B = n.get(C), ee = n.get(S);
        if (ee.__webglTexture !== void 0 && (s1.deleteTexture(ee.__webglTexture), a.memory.textures--), C.depthTexture && C.depthTexture.dispose(), C.isWebGLCubeRenderTarget) for(let j = 0; j < 6; j++){
            if (Array.isArray(B.__webglFramebuffer[j])) for(let te = 0; te < B.__webglFramebuffer[j].length; te++)s1.deleteFramebuffer(B.__webglFramebuffer[j][te]);
            else s1.deleteFramebuffer(B.__webglFramebuffer[j]);
            B.__webglDepthbuffer && s1.deleteRenderbuffer(B.__webglDepthbuffer[j]);
        }
        else {
            if (Array.isArray(B.__webglFramebuffer)) for(let j = 0; j < B.__webglFramebuffer.length; j++)s1.deleteFramebuffer(B.__webglFramebuffer[j]);
            else s1.deleteFramebuffer(B.__webglFramebuffer);
            if (B.__webglDepthbuffer && s1.deleteRenderbuffer(B.__webglDepthbuffer), B.__webglMultisampledFramebuffer && s1.deleteFramebuffer(B.__webglMultisampledFramebuffer), B.__webglColorRenderbuffer) for(let j = 0; j < B.__webglColorRenderbuffer.length; j++)B.__webglColorRenderbuffer[j] && s1.deleteRenderbuffer(B.__webglColorRenderbuffer[j]);
            B.__webglDepthRenderbuffer && s1.deleteRenderbuffer(B.__webglDepthRenderbuffer);
        }
        if (C.isWebGLMultipleRenderTargets) for(let j = 0, te = S.length; j < te; j++){
            let Me = n.get(S[j]);
            Me.__webglTexture && (s1.deleteTexture(Me.__webglTexture), a.memory.textures--), n.remove(S[j]);
        }
        n.remove(S), n.remove(C);
    }
    let q = 0;
    function H() {
        q = 0;
    }
    function ne() {
        let C = q;
        return C >= c && console.warn("THREE.WebGLTextures: Trying to use " + C + " texture units while this GPU supports only " + c), q += 1, C;
    }
    function W(C) {
        let S = [];
        return S.push(C.wrapS), S.push(C.wrapT), S.push(C.wrapR || 0), S.push(C.magFilter), S.push(C.minFilter), S.push(C.anisotropy), S.push(C.internalFormat), S.push(C.format), S.push(C.type), S.push(C.generateMipmaps), S.push(C.premultiplyAlpha), S.push(C.flipY), S.push(C.unpackAlignment), S.push(C.colorSpace), S.join();
    }
    function K(C, S) {
        let B = n.get(C);
        if (C.isVideoTexture && qe(C), C.isRenderTargetTexture === !1 && C.version > 0 && B.__version !== C.version) {
            let ee = C.image;
            if (ee === null) console.warn("THREE.WebGLRenderer: Texture marked for update but no image data found.");
            else if (ee.complete === !1) console.warn("THREE.WebGLRenderer: Texture marked for update but image is incomplete");
            else {
                Ye(B, C, S);
                return;
            }
        }
        t.bindTexture(s1.TEXTURE_2D, B.__webglTexture, s1.TEXTURE0 + S);
    }
    function D(C, S) {
        let B = n.get(C);
        if (C.version > 0 && B.__version !== C.version) {
            Ye(B, C, S);
            return;
        }
        t.bindTexture(s1.TEXTURE_2D_ARRAY, B.__webglTexture, s1.TEXTURE0 + S);
    }
    function G(C, S) {
        let B = n.get(C);
        if (C.version > 0 && B.__version !== C.version) {
            Ye(B, C, S);
            return;
        }
        t.bindTexture(s1.TEXTURE_3D, B.__webglTexture, s1.TEXTURE0 + S);
    }
    function he(C, S) {
        let B = n.get(C);
        if (C.version > 0 && B.__version !== C.version) {
            it(B, C, S);
            return;
        }
        t.bindTexture(s1.TEXTURE_CUBE_MAP, B.__webglTexture, s1.TEXTURE0 + S);
    }
    let fe = {
        [Dr]: s1.REPEAT,
        [It]: s1.CLAMP_TO_EDGE,
        [Nr]: s1.MIRRORED_REPEAT
    }, _e = {
        [pt]: s1.NEAREST,
        [fo]: s1.NEAREST_MIPMAP_NEAREST,
        [Lr]: s1.NEAREST_MIPMAP_LINEAR,
        [mt]: s1.LINEAR,
        [ud]: s1.LINEAR_MIPMAP_NEAREST,
        [li]: s1.LINEAR_MIPMAP_LINEAR
    }, we = {
        [Uf]: s1.NEVER,
        [Vf]: s1.ALWAYS,
        [Df]: s1.LESS,
        [Of]: s1.LEQUAL,
        [Nf]: s1.EQUAL,
        [zf]: s1.GEQUAL,
        [Ff]: s1.GREATER,
        [Bf]: s1.NOTEQUAL
    };
    function Ee(C, S, B) {
        if (B ? (s1.texParameteri(C, s1.TEXTURE_WRAP_S, fe[S.wrapS]), s1.texParameteri(C, s1.TEXTURE_WRAP_T, fe[S.wrapT]), (C === s1.TEXTURE_3D || C === s1.TEXTURE_2D_ARRAY) && s1.texParameteri(C, s1.TEXTURE_WRAP_R, fe[S.wrapR]), s1.texParameteri(C, s1.TEXTURE_MAG_FILTER, _e[S.magFilter]), s1.texParameteri(C, s1.TEXTURE_MIN_FILTER, _e[S.minFilter])) : (s1.texParameteri(C, s1.TEXTURE_WRAP_S, s1.CLAMP_TO_EDGE), s1.texParameteri(C, s1.TEXTURE_WRAP_T, s1.CLAMP_TO_EDGE), (C === s1.TEXTURE_3D || C === s1.TEXTURE_2D_ARRAY) && s1.texParameteri(C, s1.TEXTURE_WRAP_R, s1.CLAMP_TO_EDGE), (S.wrapS !== It || S.wrapT !== It) && console.warn("THREE.WebGLRenderer: Texture is not power of two. Texture.wrapS and Texture.wrapT should be set to THREE.ClampToEdgeWrapping."), s1.texParameteri(C, s1.TEXTURE_MAG_FILTER, T(S.magFilter)), s1.texParameteri(C, s1.TEXTURE_MIN_FILTER, T(S.minFilter)), S.minFilter !== pt && S.minFilter !== mt && console.warn("THREE.WebGLRenderer: Texture is not power of two. Texture.minFilter should be set to THREE.NearestFilter or THREE.LinearFilter.")), S.compareFunction && (s1.texParameteri(C, s1.TEXTURE_COMPARE_MODE, s1.COMPARE_REF_TO_TEXTURE), s1.texParameteri(C, s1.TEXTURE_COMPARE_FUNC, we[S.compareFunction])), e.has("EXT_texture_filter_anisotropic") === !0) {
            let ee = e.get("EXT_texture_filter_anisotropic");
            if (S.magFilter === pt || S.minFilter !== Lr && S.minFilter !== li || S.type === xn && e.has("OES_texture_float_linear") === !1 || o === !1 && S.type === Ts && e.has("OES_texture_half_float_linear") === !1) return;
            (S.anisotropy > 1 || n.get(S).__currentAnisotropy) && (s1.texParameterf(C, ee.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(S.anisotropy, i.getMaxAnisotropy())), n.get(S).__currentAnisotropy = S.anisotropy);
        }
    }
    function Te(C, S) {
        let B = !1;
        C.__webglInit === void 0 && (C.__webglInit = !0, S.addEventListener("dispose", O));
        let ee = S.source, j = g.get(ee);
        j === void 0 && (j = {}, g.set(ee, j));
        let te = W(S);
        if (te !== C.__cacheKey) {
            j[te] === void 0 && (j[te] = {
                texture: s1.createTexture(),
                usedTimes: 0
            }, a.memory.textures++, B = !0), j[te].usedTimes++;
            let Me = j[C.__cacheKey];
            Me !== void 0 && (j[C.__cacheKey].usedTimes--, Me.usedTimes === 0 && U(S)), C.__cacheKey = te, C.__webglTexture = j[te].texture;
        }
        return B;
    }
    function Ye(C, S, B) {
        let ee = s1.TEXTURE_2D;
        (S.isDataArrayTexture || S.isCompressedArrayTexture) && (ee = s1.TEXTURE_2D_ARRAY), S.isData3DTexture && (ee = s1.TEXTURE_3D);
        let j = Te(C, S), te = S.source;
        t.bindTexture(ee, C.__webglTexture, s1.TEXTURE0 + B);
        let Me = n.get(te);
        if (te.version !== Me.__version || j === !0) {
            t.activeTexture(s1.TEXTURE0 + B);
            let re = Qe.getPrimaries(Qe.workingColorSpace), de = S.colorSpace === Xt ? null : Qe.getPrimaries(S.colorSpace), Le = S.colorSpace === Xt || re === de ? s1.NONE : s1.BROWSER_DEFAULT_WEBGL;
            s1.pixelStorei(s1.UNPACK_FLIP_Y_WEBGL, S.flipY), s1.pixelStorei(s1.UNPACK_PREMULTIPLY_ALPHA_WEBGL, S.premultiplyAlpha), s1.pixelStorei(s1.UNPACK_ALIGNMENT, S.unpackAlignment), s1.pixelStorei(s1.UNPACK_COLORSPACE_CONVERSION_WEBGL, Le);
            let Ze = b(S) && y(S.image) === !1, se = x(S.image, Ze, !1, h);
            se = rt(S, se);
            let $e = y(se) || o, Oe = r.convert(S.format, S.colorSpace), Ie = r.convert(S.type), Re = I(S.internalFormat, Oe, Ie, S.colorSpace, S.isVideoTexture);
            Ee(ee, S, $e);
            let P, ce = S.mipmaps, ae = o && S.isVideoTexture !== !0, ge = Me.__version === void 0 || j === !0, ue = M(S, se, $e);
            if (S.isDepthTexture) Re = s1.DEPTH_COMPONENT, o ? S.type === xn ? Re = s1.DEPTH_COMPONENT32F : S.type === Ln ? Re = s1.DEPTH_COMPONENT24 : S.type === ii ? Re = s1.DEPTH24_STENCIL8 : Re = s1.DEPTH_COMPONENT16 : S.type === xn && console.error("WebGLRenderer: Floating point depth texture requires WebGL2."), S.format === si && Re === s1.DEPTH_COMPONENT && S.type !== Wc && S.type !== Ln && (console.warn("THREE.WebGLRenderer: Use UnsignedShortType or UnsignedIntType for DepthFormat DepthTexture."), S.type = Ln, Ie = r.convert(S.type)), S.format === Yi && Re === s1.DEPTH_COMPONENT && (Re = s1.DEPTH_STENCIL, S.type !== ii && (console.warn("THREE.WebGLRenderer: Use UnsignedInt248Type for DepthStencilFormat DepthTexture."), S.type = ii, Ie = r.convert(S.type))), ge && (ae ? t.texStorage2D(s1.TEXTURE_2D, 1, Re, se.width, se.height) : t.texImage2D(s1.TEXTURE_2D, 0, Re, se.width, se.height, 0, Oe, Ie, null));
            else if (S.isDataTexture) if (ce.length > 0 && $e) {
                ae && ge && t.texStorage2D(s1.TEXTURE_2D, ue, Re, ce[0].width, ce[0].height);
                for(let Q = 0, be = ce.length; Q < be; Q++)P = ce[Q], ae ? t.texSubImage2D(s1.TEXTURE_2D, Q, 0, 0, P.width, P.height, Oe, Ie, P.data) : t.texImage2D(s1.TEXTURE_2D, Q, Re, P.width, P.height, 0, Oe, Ie, P.data);
                S.generateMipmaps = !1;
            } else ae ? (ge && t.texStorage2D(s1.TEXTURE_2D, ue, Re, se.width, se.height), t.texSubImage2D(s1.TEXTURE_2D, 0, 0, 0, se.width, se.height, Oe, Ie, se.data)) : t.texImage2D(s1.TEXTURE_2D, 0, Re, se.width, se.height, 0, Oe, Ie, se.data);
            else if (S.isCompressedTexture) if (S.isCompressedArrayTexture) {
                ae && ge && t.texStorage3D(s1.TEXTURE_2D_ARRAY, ue, Re, ce[0].width, ce[0].height, se.depth);
                for(let Q = 0, be = ce.length; Q < be; Q++)P = ce[Q], S.format !== Wt ? Oe !== null ? ae ? t.compressedTexSubImage3D(s1.TEXTURE_2D_ARRAY, Q, 0, 0, 0, P.width, P.height, se.depth, Oe, P.data, 0, 0) : t.compressedTexImage3D(s1.TEXTURE_2D_ARRAY, Q, Re, P.width, P.height, se.depth, 0, P.data, 0, 0) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()") : ae ? t.texSubImage3D(s1.TEXTURE_2D_ARRAY, Q, 0, 0, 0, P.width, P.height, se.depth, Oe, Ie, P.data) : t.texImage3D(s1.TEXTURE_2D_ARRAY, Q, Re, P.width, P.height, se.depth, 0, Oe, Ie, P.data);
            } else {
                ae && ge && t.texStorage2D(s1.TEXTURE_2D, ue, Re, ce[0].width, ce[0].height);
                for(let Q = 0, be = ce.length; Q < be; Q++)P = ce[Q], S.format !== Wt ? Oe !== null ? ae ? t.compressedTexSubImage2D(s1.TEXTURE_2D, Q, 0, 0, P.width, P.height, Oe, P.data) : t.compressedTexImage2D(s1.TEXTURE_2D, Q, Re, P.width, P.height, 0, P.data) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()") : ae ? t.texSubImage2D(s1.TEXTURE_2D, Q, 0, 0, P.width, P.height, Oe, Ie, P.data) : t.texImage2D(s1.TEXTURE_2D, Q, Re, P.width, P.height, 0, Oe, Ie, P.data);
            }
            else if (S.isDataArrayTexture) ae ? (ge && t.texStorage3D(s1.TEXTURE_2D_ARRAY, ue, Re, se.width, se.height, se.depth), t.texSubImage3D(s1.TEXTURE_2D_ARRAY, 0, 0, 0, 0, se.width, se.height, se.depth, Oe, Ie, se.data)) : t.texImage3D(s1.TEXTURE_2D_ARRAY, 0, Re, se.width, se.height, se.depth, 0, Oe, Ie, se.data);
            else if (S.isData3DTexture) ae ? (ge && t.texStorage3D(s1.TEXTURE_3D, ue, Re, se.width, se.height, se.depth), t.texSubImage3D(s1.TEXTURE_3D, 0, 0, 0, 0, se.width, se.height, se.depth, Oe, Ie, se.data)) : t.texImage3D(s1.TEXTURE_3D, 0, Re, se.width, se.height, se.depth, 0, Oe, Ie, se.data);
            else if (S.isFramebufferTexture) {
                if (ge) if (ae) t.texStorage2D(s1.TEXTURE_2D, ue, Re, se.width, se.height);
                else {
                    let Q = se.width, be = se.height;
                    for(let Fe = 0; Fe < ue; Fe++)t.texImage2D(s1.TEXTURE_2D, Fe, Re, Q, be, 0, Oe, Ie, null), Q >>= 1, be >>= 1;
                }
            } else if (ce.length > 0 && $e) {
                ae && ge && t.texStorage2D(s1.TEXTURE_2D, ue, Re, ce[0].width, ce[0].height);
                for(let Q = 0, be = ce.length; Q < be; Q++)P = ce[Q], ae ? t.texSubImage2D(s1.TEXTURE_2D, Q, 0, 0, Oe, Ie, P) : t.texImage2D(s1.TEXTURE_2D, Q, Re, Oe, Ie, P);
                S.generateMipmaps = !1;
            } else ae ? (ge && t.texStorage2D(s1.TEXTURE_2D, ue, Re, se.width, se.height), t.texSubImage2D(s1.TEXTURE_2D, 0, 0, 0, Oe, Ie, se)) : t.texImage2D(s1.TEXTURE_2D, 0, Re, Oe, Ie, se);
            w(S, $e) && R(ee), Me.__version = te.version, S.onUpdate && S.onUpdate(S);
        }
        C.__version = S.version;
    }
    function it(C, S, B) {
        if (S.image.length !== 6) return;
        let ee = Te(C, S), j = S.source;
        t.bindTexture(s1.TEXTURE_CUBE_MAP, C.__webglTexture, s1.TEXTURE0 + B);
        let te = n.get(j);
        if (j.version !== te.__version || ee === !0) {
            t.activeTexture(s1.TEXTURE0 + B);
            let Me = Qe.getPrimaries(Qe.workingColorSpace), re = S.colorSpace === Xt ? null : Qe.getPrimaries(S.colorSpace), de = S.colorSpace === Xt || Me === re ? s1.NONE : s1.BROWSER_DEFAULT_WEBGL;
            s1.pixelStorei(s1.UNPACK_FLIP_Y_WEBGL, S.flipY), s1.pixelStorei(s1.UNPACK_PREMULTIPLY_ALPHA_WEBGL, S.premultiplyAlpha), s1.pixelStorei(s1.UNPACK_ALIGNMENT, S.unpackAlignment), s1.pixelStorei(s1.UNPACK_COLORSPACE_CONVERSION_WEBGL, de);
            let Le = S.isCompressedTexture || S.image[0].isCompressedTexture, Ze = S.image[0] && S.image[0].isDataTexture, se = [];
            for(let Q = 0; Q < 6; Q++)!Le && !Ze ? se[Q] = x(S.image[Q], !1, !0, l) : se[Q] = Ze ? S.image[Q].image : S.image[Q], se[Q] = rt(S, se[Q]);
            let $e = se[0], Oe = y($e) || o, Ie = r.convert(S.format, S.colorSpace), Re = r.convert(S.type), P = I(S.internalFormat, Ie, Re, S.colorSpace), ce = o && S.isVideoTexture !== !0, ae = te.__version === void 0 || ee === !0, ge = M(S, $e, Oe);
            Ee(s1.TEXTURE_CUBE_MAP, S, Oe);
            let ue;
            if (Le) {
                ce && ae && t.texStorage2D(s1.TEXTURE_CUBE_MAP, ge, P, $e.width, $e.height);
                for(let Q = 0; Q < 6; Q++){
                    ue = se[Q].mipmaps;
                    for(let be = 0; be < ue.length; be++){
                        let Fe = ue[be];
                        S.format !== Wt ? Ie !== null ? ce ? t.compressedTexSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be, 0, 0, Fe.width, Fe.height, Ie, Fe.data) : t.compressedTexImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be, P, Fe.width, Fe.height, 0, Fe.data) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()") : ce ? t.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be, 0, 0, Fe.width, Fe.height, Ie, Re, Fe.data) : t.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be, P, Fe.width, Fe.height, 0, Ie, Re, Fe.data);
                    }
                }
            } else {
                ue = S.mipmaps, ce && ae && (ue.length > 0 && ge++, t.texStorage2D(s1.TEXTURE_CUBE_MAP, ge, P, se[0].width, se[0].height));
                for(let Q = 0; Q < 6; Q++)if (Ze) {
                    ce ? t.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, 0, 0, 0, se[Q].width, se[Q].height, Ie, Re, se[Q].data) : t.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, 0, P, se[Q].width, se[Q].height, 0, Ie, Re, se[Q].data);
                    for(let be = 0; be < ue.length; be++){
                        let At = ue[be].image[Q].image;
                        ce ? t.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be + 1, 0, 0, At.width, At.height, Ie, Re, At.data) : t.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be + 1, P, At.width, At.height, 0, Ie, Re, At.data);
                    }
                } else {
                    ce ? t.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, 0, 0, 0, Ie, Re, se[Q]) : t.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, 0, P, Ie, Re, se[Q]);
                    for(let be = 0; be < ue.length; be++){
                        let Fe = ue[be];
                        ce ? t.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be + 1, 0, 0, Ie, Re, Fe.image[Q]) : t.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + Q, be + 1, P, Ie, Re, Fe.image[Q]);
                    }
                }
            }
            w(S, Oe) && R(s1.TEXTURE_CUBE_MAP), te.__version = j.version, S.onUpdate && S.onUpdate(S);
        }
        C.__version = S.version;
    }
    function Ce(C, S, B, ee, j, te) {
        let Me = r.convert(B.format, B.colorSpace), re = r.convert(B.type), de = I(B.internalFormat, Me, re, B.colorSpace);
        if (!n.get(S).__hasExternalTextures) {
            let Ze = Math.max(1, S.width >> te), se = Math.max(1, S.height >> te);
            j === s1.TEXTURE_3D || j === s1.TEXTURE_2D_ARRAY ? t.texImage3D(j, te, de, Ze, se, S.depth, 0, Me, re, null) : t.texImage2D(j, te, de, Ze, se, 0, Me, re, null);
        }
        t.bindFramebuffer(s1.FRAMEBUFFER, C), Ne(S) ? d.framebufferTexture2DMultisampleEXT(s1.FRAMEBUFFER, ee, j, n.get(B).__webglTexture, 0, ye(S)) : (j === s1.TEXTURE_2D || j >= s1.TEXTURE_CUBE_MAP_POSITIVE_X && j <= s1.TEXTURE_CUBE_MAP_NEGATIVE_Z) && s1.framebufferTexture2D(s1.FRAMEBUFFER, ee, j, n.get(B).__webglTexture, te), t.bindFramebuffer(s1.FRAMEBUFFER, null);
    }
    function L(C, S, B) {
        if (s1.bindRenderbuffer(s1.RENDERBUFFER, C), S.depthBuffer && !S.stencilBuffer) {
            let ee = o === !0 ? s1.DEPTH_COMPONENT24 : s1.DEPTH_COMPONENT16;
            if (B || Ne(S)) {
                let j = S.depthTexture;
                j && j.isDepthTexture && (j.type === xn ? ee = s1.DEPTH_COMPONENT32F : j.type === Ln && (ee = s1.DEPTH_COMPONENT24));
                let te = ye(S);
                Ne(S) ? d.renderbufferStorageMultisampleEXT(s1.RENDERBUFFER, te, ee, S.width, S.height) : s1.renderbufferStorageMultisample(s1.RENDERBUFFER, te, ee, S.width, S.height);
            } else s1.renderbufferStorage(s1.RENDERBUFFER, ee, S.width, S.height);
            s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.DEPTH_ATTACHMENT, s1.RENDERBUFFER, C);
        } else if (S.depthBuffer && S.stencilBuffer) {
            let ee = ye(S);
            B && Ne(S) === !1 ? s1.renderbufferStorageMultisample(s1.RENDERBUFFER, ee, s1.DEPTH24_STENCIL8, S.width, S.height) : Ne(S) ? d.renderbufferStorageMultisampleEXT(s1.RENDERBUFFER, ee, s1.DEPTH24_STENCIL8, S.width, S.height) : s1.renderbufferStorage(s1.RENDERBUFFER, s1.DEPTH_STENCIL, S.width, S.height), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.DEPTH_STENCIL_ATTACHMENT, s1.RENDERBUFFER, C);
        } else {
            let ee = S.isWebGLMultipleRenderTargets === !0 ? S.texture : [
                S.texture
            ];
            for(let j = 0; j < ee.length; j++){
                let te = ee[j], Me = r.convert(te.format, te.colorSpace), re = r.convert(te.type), de = I(te.internalFormat, Me, re, te.colorSpace), Le = ye(S);
                B && Ne(S) === !1 ? s1.renderbufferStorageMultisample(s1.RENDERBUFFER, Le, de, S.width, S.height) : Ne(S) ? d.renderbufferStorageMultisampleEXT(s1.RENDERBUFFER, Le, de, S.width, S.height) : s1.renderbufferStorage(s1.RENDERBUFFER, de, S.width, S.height);
            }
        }
        s1.bindRenderbuffer(s1.RENDERBUFFER, null);
    }
    function oe(C, S) {
        if (S && S.isWebGLCubeRenderTarget) throw new Error("Depth Texture with cube render targets is not supported");
        if (t.bindFramebuffer(s1.FRAMEBUFFER, C), !(S.depthTexture && S.depthTexture.isDepthTexture)) throw new Error("renderTarget.depthTexture must be an instance of THREE.DepthTexture");
        (!n.get(S.depthTexture).__webglTexture || S.depthTexture.image.width !== S.width || S.depthTexture.image.height !== S.height) && (S.depthTexture.image.width = S.width, S.depthTexture.image.height = S.height, S.depthTexture.needsUpdate = !0), K(S.depthTexture, 0);
        let ee = n.get(S.depthTexture).__webglTexture, j = ye(S);
        if (S.depthTexture.format === si) Ne(S) ? d.framebufferTexture2DMultisampleEXT(s1.FRAMEBUFFER, s1.DEPTH_ATTACHMENT, s1.TEXTURE_2D, ee, 0, j) : s1.framebufferTexture2D(s1.FRAMEBUFFER, s1.DEPTH_ATTACHMENT, s1.TEXTURE_2D, ee, 0);
        else if (S.depthTexture.format === Yi) Ne(S) ? d.framebufferTexture2DMultisampleEXT(s1.FRAMEBUFFER, s1.DEPTH_STENCIL_ATTACHMENT, s1.TEXTURE_2D, ee, 0, j) : s1.framebufferTexture2D(s1.FRAMEBUFFER, s1.DEPTH_STENCIL_ATTACHMENT, s1.TEXTURE_2D, ee, 0);
        else throw new Error("Unknown depthTexture format");
    }
    function X(C) {
        let S = n.get(C), B = C.isWebGLCubeRenderTarget === !0;
        if (C.depthTexture && !S.__autoAllocateDepthBuffer) {
            if (B) throw new Error("target.depthTexture not supported in Cube render targets");
            oe(S.__webglFramebuffer, C);
        } else if (B) {
            S.__webglDepthbuffer = [];
            for(let ee = 0; ee < 6; ee++)t.bindFramebuffer(s1.FRAMEBUFFER, S.__webglFramebuffer[ee]), S.__webglDepthbuffer[ee] = s1.createRenderbuffer(), L(S.__webglDepthbuffer[ee], C, !1);
        } else t.bindFramebuffer(s1.FRAMEBUFFER, S.__webglFramebuffer), S.__webglDepthbuffer = s1.createRenderbuffer(), L(S.__webglDepthbuffer, C, !1);
        t.bindFramebuffer(s1.FRAMEBUFFER, null);
    }
    function ie(C, S, B) {
        let ee = n.get(C);
        S !== void 0 && Ce(ee.__webglFramebuffer, C, C.texture, s1.COLOR_ATTACHMENT0, s1.TEXTURE_2D, 0), B !== void 0 && X(C);
    }
    function J(C) {
        let S = C.texture, B = n.get(C), ee = n.get(S);
        C.addEventListener("dispose", Y), C.isWebGLMultipleRenderTargets !== !0 && (ee.__webglTexture === void 0 && (ee.__webglTexture = s1.createTexture()), ee.__version = S.version, a.memory.textures++);
        let j = C.isWebGLCubeRenderTarget === !0, te = C.isWebGLMultipleRenderTargets === !0, Me = y(C) || o;
        if (j) {
            B.__webglFramebuffer = [];
            for(let re = 0; re < 6; re++)if (o && S.mipmaps && S.mipmaps.length > 0) {
                B.__webglFramebuffer[re] = [];
                for(let de = 0; de < S.mipmaps.length; de++)B.__webglFramebuffer[re][de] = s1.createFramebuffer();
            } else B.__webglFramebuffer[re] = s1.createFramebuffer();
        } else {
            if (o && S.mipmaps && S.mipmaps.length > 0) {
                B.__webglFramebuffer = [];
                for(let re = 0; re < S.mipmaps.length; re++)B.__webglFramebuffer[re] = s1.createFramebuffer();
            } else B.__webglFramebuffer = s1.createFramebuffer();
            if (te) if (i.drawBuffers) {
                let re = C.texture;
                for(let de = 0, Le = re.length; de < Le; de++){
                    let Ze = n.get(re[de]);
                    Ze.__webglTexture === void 0 && (Ze.__webglTexture = s1.createTexture(), a.memory.textures++);
                }
            } else console.warn("THREE.WebGLRenderer: WebGLMultipleRenderTargets can only be used with WebGL2 or WEBGL_draw_buffers extension.");
            if (o && C.samples > 0 && Ne(C) === !1) {
                let re = te ? S : [
                    S
                ];
                B.__webglMultisampledFramebuffer = s1.createFramebuffer(), B.__webglColorRenderbuffer = [], t.bindFramebuffer(s1.FRAMEBUFFER, B.__webglMultisampledFramebuffer);
                for(let de = 0; de < re.length; de++){
                    let Le = re[de];
                    B.__webglColorRenderbuffer[de] = s1.createRenderbuffer(), s1.bindRenderbuffer(s1.RENDERBUFFER, B.__webglColorRenderbuffer[de]);
                    let Ze = r.convert(Le.format, Le.colorSpace), se = r.convert(Le.type), $e = I(Le.internalFormat, Ze, se, Le.colorSpace, C.isXRRenderTarget === !0), Oe = ye(C);
                    s1.renderbufferStorageMultisample(s1.RENDERBUFFER, Oe, $e, C.width, C.height), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + de, s1.RENDERBUFFER, B.__webglColorRenderbuffer[de]);
                }
                s1.bindRenderbuffer(s1.RENDERBUFFER, null), C.depthBuffer && (B.__webglDepthRenderbuffer = s1.createRenderbuffer(), L(B.__webglDepthRenderbuffer, C, !0)), t.bindFramebuffer(s1.FRAMEBUFFER, null);
            }
        }
        if (j) {
            t.bindTexture(s1.TEXTURE_CUBE_MAP, ee.__webglTexture), Ee(s1.TEXTURE_CUBE_MAP, S, Me);
            for(let re = 0; re < 6; re++)if (o && S.mipmaps && S.mipmaps.length > 0) for(let de = 0; de < S.mipmaps.length; de++)Ce(B.__webglFramebuffer[re][de], C, S, s1.COLOR_ATTACHMENT0, s1.TEXTURE_CUBE_MAP_POSITIVE_X + re, de);
            else Ce(B.__webglFramebuffer[re], C, S, s1.COLOR_ATTACHMENT0, s1.TEXTURE_CUBE_MAP_POSITIVE_X + re, 0);
            w(S, Me) && R(s1.TEXTURE_CUBE_MAP), t.unbindTexture();
        } else if (te) {
            let re = C.texture;
            for(let de = 0, Le = re.length; de < Le; de++){
                let Ze = re[de], se = n.get(Ze);
                t.bindTexture(s1.TEXTURE_2D, se.__webglTexture), Ee(s1.TEXTURE_2D, Ze, Me), Ce(B.__webglFramebuffer, C, Ze, s1.COLOR_ATTACHMENT0 + de, s1.TEXTURE_2D, 0), w(Ze, Me) && R(s1.TEXTURE_2D);
            }
            t.unbindTexture();
        } else {
            let re = s1.TEXTURE_2D;
            if ((C.isWebGL3DRenderTarget || C.isWebGLArrayRenderTarget) && (o ? re = C.isWebGL3DRenderTarget ? s1.TEXTURE_3D : s1.TEXTURE_2D_ARRAY : console.error("THREE.WebGLTextures: THREE.Data3DTexture and THREE.DataArrayTexture only supported with WebGL2.")), t.bindTexture(re, ee.__webglTexture), Ee(re, S, Me), o && S.mipmaps && S.mipmaps.length > 0) for(let de = 0; de < S.mipmaps.length; de++)Ce(B.__webglFramebuffer[de], C, S, s1.COLOR_ATTACHMENT0, re, de);
            else Ce(B.__webglFramebuffer, C, S, s1.COLOR_ATTACHMENT0, re, 0);
            w(S, Me) && R(re), t.unbindTexture();
        }
        C.depthBuffer && X(C);
    }
    function Se(C) {
        let S = y(C) || o, B = C.isWebGLMultipleRenderTargets === !0 ? C.texture : [
            C.texture
        ];
        for(let ee = 0, j = B.length; ee < j; ee++){
            let te = B[ee];
            if (w(te, S)) {
                let Me = C.isWebGLCubeRenderTarget ? s1.TEXTURE_CUBE_MAP : s1.TEXTURE_2D, re = n.get(te).__webglTexture;
                t.bindTexture(Me, re), R(Me), t.unbindTexture();
            }
        }
    }
    function me(C) {
        if (o && C.samples > 0 && Ne(C) === !1) {
            let S = C.isWebGLMultipleRenderTargets ? C.texture : [
                C.texture
            ], B = C.width, ee = C.height, j = s1.COLOR_BUFFER_BIT, te = [], Me = C.stencilBuffer ? s1.DEPTH_STENCIL_ATTACHMENT : s1.DEPTH_ATTACHMENT, re = n.get(C), de = C.isWebGLMultipleRenderTargets === !0;
            if (de) for(let Le = 0; Le < S.length; Le++)t.bindFramebuffer(s1.FRAMEBUFFER, re.__webglMultisampledFramebuffer), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Le, s1.RENDERBUFFER, null), t.bindFramebuffer(s1.FRAMEBUFFER, re.__webglFramebuffer), s1.framebufferTexture2D(s1.DRAW_FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Le, s1.TEXTURE_2D, null, 0);
            t.bindFramebuffer(s1.READ_FRAMEBUFFER, re.__webglMultisampledFramebuffer), t.bindFramebuffer(s1.DRAW_FRAMEBUFFER, re.__webglFramebuffer);
            for(let Le = 0; Le < S.length; Le++){
                te.push(s1.COLOR_ATTACHMENT0 + Le), C.depthBuffer && te.push(Me);
                let Ze = re.__ignoreDepthValues !== void 0 ? re.__ignoreDepthValues : !1;
                if (Ze === !1 && (C.depthBuffer && (j |= s1.DEPTH_BUFFER_BIT), C.stencilBuffer && (j |= s1.STENCIL_BUFFER_BIT)), de && s1.framebufferRenderbuffer(s1.READ_FRAMEBUFFER, s1.COLOR_ATTACHMENT0, s1.RENDERBUFFER, re.__webglColorRenderbuffer[Le]), Ze === !0 && (s1.invalidateFramebuffer(s1.READ_FRAMEBUFFER, [
                    Me
                ]), s1.invalidateFramebuffer(s1.DRAW_FRAMEBUFFER, [
                    Me
                ])), de) {
                    let se = n.get(S[Le]).__webglTexture;
                    s1.framebufferTexture2D(s1.DRAW_FRAMEBUFFER, s1.COLOR_ATTACHMENT0, s1.TEXTURE_2D, se, 0);
                }
                s1.blitFramebuffer(0, 0, B, ee, 0, 0, B, ee, j, s1.NEAREST), f && s1.invalidateFramebuffer(s1.READ_FRAMEBUFFER, te);
            }
            if (t.bindFramebuffer(s1.READ_FRAMEBUFFER, null), t.bindFramebuffer(s1.DRAW_FRAMEBUFFER, null), de) for(let Le = 0; Le < S.length; Le++){
                t.bindFramebuffer(s1.FRAMEBUFFER, re.__webglMultisampledFramebuffer), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Le, s1.RENDERBUFFER, re.__webglColorRenderbuffer[Le]);
                let Ze = n.get(S[Le]).__webglTexture;
                t.bindFramebuffer(s1.FRAMEBUFFER, re.__webglFramebuffer), s1.framebufferTexture2D(s1.DRAW_FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Le, s1.TEXTURE_2D, Ze, 0);
            }
            t.bindFramebuffer(s1.DRAW_FRAMEBUFFER, re.__webglMultisampledFramebuffer);
        }
    }
    function ye(C) {
        return Math.min(u, C.samples);
    }
    function Ne(C) {
        let S = n.get(C);
        return o && C.samples > 0 && e.has("WEBGL_multisampled_render_to_texture") === !0 && S.__useRenderToTexture !== !1;
    }
    function qe(C) {
        let S = a.render.frame;
        m.get(C) !== S && (m.set(C, S), C.update());
    }
    function rt(C, S) {
        let B = C.colorSpace, ee = C.format, j = C.type;
        return C.isCompressedTexture === !0 || C.isVideoTexture === !0 || C.format === po || B !== Mn && B !== Xt && (Qe.getTransfer(B) === nt ? o === !1 ? e.has("EXT_sRGB") === !0 && ee === Wt ? (C.format = po, C.minFilter = mt, C.generateMipmaps = !1) : S = Xr.sRGBToLinear(S) : (ee !== Wt || j !== On) && console.warn("THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.") : console.error("THREE.WebGLTextures: Unsupported texture color space:", B)), S;
    }
    this.allocateTextureUnit = ne, this.resetTextureUnits = H, this.setTexture2D = K, this.setTexture2DArray = D, this.setTexture3D = G, this.setTextureCube = he, this.rebindTextures = ie, this.setupRenderTarget = J, this.updateRenderTargetMipmap = Se, this.updateMultisampleRenderTarget = me, this.setupDepthRenderbuffer = X, this.setupFrameBufferTexture = Ce, this.useMultisampledRTT = Ne;
}
function V0(s1, e, t) {
    let n = t.isWebGL2;
    function i(r, a = Xt) {
        let o, c = Qe.getTransfer(a);
        if (r === On) return s1.UNSIGNED_BYTE;
        if (r === fd) return s1.UNSIGNED_SHORT_4_4_4_4;
        if (r === pd) return s1.UNSIGNED_SHORT_5_5_5_1;
        if (r === _f) return s1.BYTE;
        if (r === xf) return s1.SHORT;
        if (r === Wc) return s1.UNSIGNED_SHORT;
        if (r === dd) return s1.INT;
        if (r === Ln) return s1.UNSIGNED_INT;
        if (r === xn) return s1.FLOAT;
        if (r === Ts) return n ? s1.HALF_FLOAT : (o = e.get("OES_texture_half_float"), o !== null ? o.HALF_FLOAT_OES : null);
        if (r === vf) return s1.ALPHA;
        if (r === Wt) return s1.RGBA;
        if (r === yf) return s1.LUMINANCE;
        if (r === Mf) return s1.LUMINANCE_ALPHA;
        if (r === si) return s1.DEPTH_COMPONENT;
        if (r === Yi) return s1.DEPTH_STENCIL;
        if (r === po) return o = e.get("EXT_sRGB"), o !== null ? o.SRGB_ALPHA_EXT : null;
        if (r === Sf) return s1.RED;
        if (r === md) return s1.RED_INTEGER;
        if (r === bf) return s1.RG;
        if (r === gd) return s1.RG_INTEGER;
        if (r === _d) return s1.RGBA_INTEGER;
        if (r === wa || r === Aa || r === Ra || r === Ca) if (c === nt) if (o = e.get("WEBGL_compressed_texture_s3tc_srgb"), o !== null) {
            if (r === wa) return o.COMPRESSED_SRGB_S3TC_DXT1_EXT;
            if (r === Aa) return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
            if (r === Ra) return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
            if (r === Ca) return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
        } else return null;
        else if (o = e.get("WEBGL_compressed_texture_s3tc"), o !== null) {
            if (r === wa) return o.COMPRESSED_RGB_S3TC_DXT1_EXT;
            if (r === Aa) return o.COMPRESSED_RGBA_S3TC_DXT1_EXT;
            if (r === Ra) return o.COMPRESSED_RGBA_S3TC_DXT3_EXT;
            if (r === Ca) return o.COMPRESSED_RGBA_S3TC_DXT5_EXT;
        } else return null;
        if (r === ul || r === dl || r === fl || r === pl) if (o = e.get("WEBGL_compressed_texture_pvrtc"), o !== null) {
            if (r === ul) return o.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            if (r === dl) return o.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            if (r === fl) return o.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            if (r === pl) return o.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
        } else return null;
        if (r === Ef) return o = e.get("WEBGL_compressed_texture_etc1"), o !== null ? o.COMPRESSED_RGB_ETC1_WEBGL : null;
        if (r === ml || r === gl) if (o = e.get("WEBGL_compressed_texture_etc"), o !== null) {
            if (r === ml) return c === nt ? o.COMPRESSED_SRGB8_ETC2 : o.COMPRESSED_RGB8_ETC2;
            if (r === gl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : o.COMPRESSED_RGBA8_ETC2_EAC;
        } else return null;
        if (r === _l || r === xl || r === vl || r === yl || r === Ml || r === Sl || r === bl || r === El || r === Tl || r === wl || r === Al || r === Rl || r === Cl || r === Pl) if (o = e.get("WEBGL_compressed_texture_astc"), o !== null) {
            if (r === _l) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : o.COMPRESSED_RGBA_ASTC_4x4_KHR;
            if (r === xl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : o.COMPRESSED_RGBA_ASTC_5x4_KHR;
            if (r === vl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : o.COMPRESSED_RGBA_ASTC_5x5_KHR;
            if (r === yl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : o.COMPRESSED_RGBA_ASTC_6x5_KHR;
            if (r === Ml) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : o.COMPRESSED_RGBA_ASTC_6x6_KHR;
            if (r === Sl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : o.COMPRESSED_RGBA_ASTC_8x5_KHR;
            if (r === bl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : o.COMPRESSED_RGBA_ASTC_8x6_KHR;
            if (r === El) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : o.COMPRESSED_RGBA_ASTC_8x8_KHR;
            if (r === Tl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : o.COMPRESSED_RGBA_ASTC_10x5_KHR;
            if (r === wl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : o.COMPRESSED_RGBA_ASTC_10x6_KHR;
            if (r === Al) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : o.COMPRESSED_RGBA_ASTC_10x8_KHR;
            if (r === Rl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : o.COMPRESSED_RGBA_ASTC_10x10_KHR;
            if (r === Cl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : o.COMPRESSED_RGBA_ASTC_12x10_KHR;
            if (r === Pl) return c === nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : o.COMPRESSED_RGBA_ASTC_12x12_KHR;
        } else return null;
        if (r === Pa || r === Ll || r === Il) if (o = e.get("EXT_texture_compression_bptc"), o !== null) {
            if (r === Pa) return c === nt ? o.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : o.COMPRESSED_RGBA_BPTC_UNORM_EXT;
            if (r === Ll) return o.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;
            if (r === Il) return o.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT;
        } else return null;
        if (r === Tf || r === Ul || r === Dl || r === Nl) if (o = e.get("EXT_texture_compression_rgtc"), o !== null) {
            if (r === Pa) return o.COMPRESSED_RED_RGTC1_EXT;
            if (r === Ul) return o.COMPRESSED_SIGNED_RED_RGTC1_EXT;
            if (r === Dl) return o.COMPRESSED_RED_GREEN_RGTC2_EXT;
            if (r === Nl) return o.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
        } else return null;
        return r === ii ? n ? s1.UNSIGNED_INT_24_8 : (o = e.get("WEBGL_depth_texture"), o !== null ? o.UNSIGNED_INT_24_8_WEBGL : null) : s1[r] !== void 0 ? s1[r] : null;
    }
    return {
        convert: i
    };
}
var To = class extends yt {
    constructor(e = []){
        super(), this.isArrayCamera = !0, this.cameras = e;
    }
}, ti = class extends Je {
    constructor(){
        super(), this.isGroup = !0, this.type = "Group";
    }
}, k0 = {
    type: "move"
}, Ss = class {
    constructor(){
        this._targetRay = null, this._grip = null, this._hand = null;
    }
    getHandSpace() {
        return this._hand === null && (this._hand = new ti, this._hand.matrixAutoUpdate = !1, this._hand.visible = !1, this._hand.joints = {}, this._hand.inputState = {
            pinching: !1
        }), this._hand;
    }
    getTargetRaySpace() {
        return this._targetRay === null && (this._targetRay = new ti, this._targetRay.matrixAutoUpdate = !1, this._targetRay.visible = !1, this._targetRay.hasLinearVelocity = !1, this._targetRay.linearVelocity = new A, this._targetRay.hasAngularVelocity = !1, this._targetRay.angularVelocity = new A), this._targetRay;
    }
    getGripSpace() {
        return this._grip === null && (this._grip = new ti, this._grip.matrixAutoUpdate = !1, this._grip.visible = !1, this._grip.hasLinearVelocity = !1, this._grip.linearVelocity = new A, this._grip.hasAngularVelocity = !1, this._grip.angularVelocity = new A), this._grip;
    }
    dispatchEvent(e) {
        return this._targetRay !== null && this._targetRay.dispatchEvent(e), this._grip !== null && this._grip.dispatchEvent(e), this._hand !== null && this._hand.dispatchEvent(e), this;
    }
    connect(e) {
        if (e && e.hand) {
            let t = this._hand;
            if (t) for (let n of e.hand.values())this._getHandJoint(t, n);
        }
        return this.dispatchEvent({
            type: "connected",
            data: e
        }), this;
    }
    disconnect(e) {
        return this.dispatchEvent({
            type: "disconnected",
            data: e
        }), this._targetRay !== null && (this._targetRay.visible = !1), this._grip !== null && (this._grip.visible = !1), this._hand !== null && (this._hand.visible = !1), this;
    }
    update(e, t, n) {
        let i = null, r = null, a = null, o = this._targetRay, c = this._grip, l = this._hand;
        if (e && t.session.visibilityState !== "visible-blurred") {
            if (l && e.hand) {
                a = !0;
                for (let _ of e.hand.values()){
                    let g = t.getJointPose(_, n), p = this._getHandJoint(l, _);
                    g !== null && (p.matrix.fromArray(g.transform.matrix), p.matrix.decompose(p.position, p.rotation, p.scale), p.matrixWorldNeedsUpdate = !0, p.jointRadius = g.radius), p.visible = g !== null;
                }
                let h = l.joints["index-finger-tip"], u = l.joints["thumb-tip"], d = h.position.distanceTo(u.position), f = .02, m = .005;
                l.inputState.pinching && d > f + m ? (l.inputState.pinching = !1, this.dispatchEvent({
                    type: "pinchend",
                    handedness: e.handedness,
                    target: this
                })) : !l.inputState.pinching && d <= f - m && (l.inputState.pinching = !0, this.dispatchEvent({
                    type: "pinchstart",
                    handedness: e.handedness,
                    target: this
                }));
            } else c !== null && e.gripSpace && (r = t.getPose(e.gripSpace, n), r !== null && (c.matrix.fromArray(r.transform.matrix), c.matrix.decompose(c.position, c.rotation, c.scale), c.matrixWorldNeedsUpdate = !0, r.linearVelocity ? (c.hasLinearVelocity = !0, c.linearVelocity.copy(r.linearVelocity)) : c.hasLinearVelocity = !1, r.angularVelocity ? (c.hasAngularVelocity = !0, c.angularVelocity.copy(r.angularVelocity)) : c.hasAngularVelocity = !1));
            o !== null && (i = t.getPose(e.targetRaySpace, n), i === null && r !== null && (i = r), i !== null && (o.matrix.fromArray(i.transform.matrix), o.matrix.decompose(o.position, o.rotation, o.scale), o.matrixWorldNeedsUpdate = !0, i.linearVelocity ? (o.hasLinearVelocity = !0, o.linearVelocity.copy(i.linearVelocity)) : o.hasLinearVelocity = !1, i.angularVelocity ? (o.hasAngularVelocity = !0, o.angularVelocity.copy(i.angularVelocity)) : o.hasAngularVelocity = !1, this.dispatchEvent(k0)));
        }
        return o !== null && (o.visible = i !== null), c !== null && (c.visible = r !== null), l !== null && (l.visible = a !== null), this;
    }
    _getHandJoint(e, t) {
        if (e.joints[t.jointName] === void 0) {
            let n = new ti;
            n.matrixAutoUpdate = !1, n.visible = !1, e.joints[t.jointName] = n, e.add(n);
        }
        return e.joints[t.jointName];
    }
}, wo = class extends St {
    constructor(e, t, n, i, r, a, o, c, l, h){
        if (h = h !== void 0 ? h : si, h !== si && h !== Yi) throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");
        n === void 0 && h === si && (n = Ln), n === void 0 && h === Yi && (n = ii), super(null, i, r, a, o, c, h, n, l), this.isDepthTexture = !0, this.image = {
            width: e,
            height: t
        }, this.magFilter = o !== void 0 ? o : pt, this.minFilter = c !== void 0 ? c : pt, this.flipY = !1, this.generateMipmaps = !1, this.compareFunction = null;
    }
    copy(e) {
        return super.copy(e), this.compareFunction = e.compareFunction, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return this.compareFunction !== null && (t.compareFunction = this.compareFunction), t;
    }
}, Ao = class extends sn {
    constructor(e, t){
        super();
        let n = this, i = null, r = 1, a = null, o = "local-floor", c = 1, l = null, h = null, u = null, d = null, f = null, m = null, _ = t.getContextAttributes(), g = null, p = null, v = [], x = [], y = new yt;
        y.layers.enable(1), y.viewport = new je;
        let b = new yt;
        b.layers.enable(2), b.viewport = new je;
        let w = [
            y,
            b
        ], R = new To;
        R.layers.enable(1), R.layers.enable(2);
        let I = null, M = null;
        this.cameraAutoUpdate = !0, this.enabled = !1, this.isPresenting = !1, this.getController = function(D) {
            let G = v[D];
            return G === void 0 && (G = new Ss, v[D] = G), G.getTargetRaySpace();
        }, this.getControllerGrip = function(D) {
            let G = v[D];
            return G === void 0 && (G = new Ss, v[D] = G), G.getGripSpace();
        }, this.getHand = function(D) {
            let G = v[D];
            return G === void 0 && (G = new Ss, v[D] = G), G.getHandSpace();
        };
        function T(D) {
            let G = x.indexOf(D.inputSource);
            if (G === -1) return;
            let he = v[G];
            he !== void 0 && (he.update(D.inputSource, D.frame, l || a), he.dispatchEvent({
                type: D.type,
                data: D.inputSource
            }));
        }
        function O() {
            i.removeEventListener("select", T), i.removeEventListener("selectstart", T), i.removeEventListener("selectend", T), i.removeEventListener("squeeze", T), i.removeEventListener("squeezestart", T), i.removeEventListener("squeezeend", T), i.removeEventListener("end", O), i.removeEventListener("inputsourceschange", Y);
            for(let D = 0; D < v.length; D++){
                let G = x[D];
                G !== null && (x[D] = null, v[D].disconnect(G));
            }
            I = null, M = null, e.setRenderTarget(g), f = null, d = null, u = null, i = null, p = null, K.stop(), n.isPresenting = !1, n.dispatchEvent({
                type: "sessionend"
            });
        }
        this.setFramebufferScaleFactor = function(D) {
            r = D, n.isPresenting === !0 && console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.");
        }, this.setReferenceSpaceType = function(D) {
            o = D, n.isPresenting === !0 && console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.");
        }, this.getReferenceSpace = function() {
            return l || a;
        }, this.setReferenceSpace = function(D) {
            l = D;
        }, this.getBaseLayer = function() {
            return d !== null ? d : f;
        }, this.getBinding = function() {
            return u;
        }, this.getFrame = function() {
            return m;
        }, this.getSession = function() {
            return i;
        }, this.setSession = async function(D) {
            if (i = D, i !== null) {
                if (g = e.getRenderTarget(), i.addEventListener("select", T), i.addEventListener("selectstart", T), i.addEventListener("selectend", T), i.addEventListener("squeeze", T), i.addEventListener("squeezestart", T), i.addEventListener("squeezeend", T), i.addEventListener("end", O), i.addEventListener("inputsourceschange", Y), _.xrCompatible !== !0 && await t.makeXRCompatible(), i.renderState.layers === void 0 || e.capabilities.isWebGL2 === !1) {
                    let G = {
                        antialias: i.renderState.layers === void 0 ? _.antialias : !0,
                        alpha: !0,
                        depth: _.depth,
                        stencil: _.stencil,
                        framebufferScaleFactor: r
                    };
                    f = new XRWebGLLayer(i, t, G), i.updateRenderState({
                        baseLayer: f
                    }), p = new qt(f.framebufferWidth, f.framebufferHeight, {
                        format: Wt,
                        type: On,
                        colorSpace: e.outputColorSpace,
                        stencilBuffer: _.stencil
                    });
                } else {
                    let G = null, he = null, fe = null;
                    _.depth && (fe = _.stencil ? t.DEPTH24_STENCIL8 : t.DEPTH_COMPONENT24, G = _.stencil ? Yi : si, he = _.stencil ? ii : Ln);
                    let _e = {
                        colorFormat: t.RGBA8,
                        depthFormat: fe,
                        scaleFactor: r
                    };
                    u = new XRWebGLBinding(i, t), d = u.createProjectionLayer(_e), i.updateRenderState({
                        layers: [
                            d
                        ]
                    }), p = new qt(d.textureWidth, d.textureHeight, {
                        format: Wt,
                        type: On,
                        depthTexture: new wo(d.textureWidth, d.textureHeight, he, void 0, void 0, void 0, void 0, void 0, void 0, G),
                        stencilBuffer: _.stencil,
                        colorSpace: e.outputColorSpace,
                        samples: _.antialias ? 4 : 0
                    });
                    let we = e.properties.get(p);
                    we.__ignoreDepthValues = d.ignoreDepthValues;
                }
                p.isXRRenderTarget = !0, this.setFoveation(c), l = null, a = await i.requestReferenceSpace(o), K.setContext(i), K.start(), n.isPresenting = !0, n.dispatchEvent({
                    type: "sessionstart"
                });
            }
        }, this.getEnvironmentBlendMode = function() {
            if (i !== null) return i.environmentBlendMode;
        };
        function Y(D) {
            for(let G = 0; G < D.removed.length; G++){
                let he = D.removed[G], fe = x.indexOf(he);
                fe >= 0 && (x[fe] = null, v[fe].disconnect(he));
            }
            for(let G = 0; G < D.added.length; G++){
                let he = D.added[G], fe = x.indexOf(he);
                if (fe === -1) {
                    for(let we = 0; we < v.length; we++)if (we >= x.length) {
                        x.push(he), fe = we;
                        break;
                    } else if (x[we] === null) {
                        x[we] = he, fe = we;
                        break;
                    }
                    if (fe === -1) break;
                }
                let _e = v[fe];
                _e && _e.connect(he);
            }
        }
        let $ = new A, U = new A;
        function z(D, G, he) {
            $.setFromMatrixPosition(G.matrixWorld), U.setFromMatrixPosition(he.matrixWorld);
            let fe = $.distanceTo(U), _e = G.projectionMatrix.elements, we = he.projectionMatrix.elements, Ee = _e[14] / (_e[10] - 1), Te = _e[14] / (_e[10] + 1), Ye = (_e[9] + 1) / _e[5], it = (_e[9] - 1) / _e[5], Ce = (_e[8] - 1) / _e[0], L = (we[8] + 1) / we[0], oe = Ee * Ce, X = Ee * L, ie = fe / (-Ce + L), J = ie * -Ce;
            G.matrixWorld.decompose(D.position, D.quaternion, D.scale), D.translateX(J), D.translateZ(ie), D.matrixWorld.compose(D.position, D.quaternion, D.scale), D.matrixWorldInverse.copy(D.matrixWorld).invert();
            let Se = Ee + ie, me = Te + ie, ye = oe - J, Ne = X + (fe - J), qe = Ye * Te / me * Se, rt = it * Te / me * Se;
            D.projectionMatrix.makePerspective(ye, Ne, qe, rt, Se, me), D.projectionMatrixInverse.copy(D.projectionMatrix).invert();
        }
        function q(D, G) {
            G === null ? D.matrixWorld.copy(D.matrix) : D.matrixWorld.multiplyMatrices(G.matrixWorld, D.matrix), D.matrixWorldInverse.copy(D.matrixWorld).invert();
        }
        this.updateCamera = function(D) {
            if (i === null) return;
            R.near = b.near = y.near = D.near, R.far = b.far = y.far = D.far, (I !== R.near || M !== R.far) && (i.updateRenderState({
                depthNear: R.near,
                depthFar: R.far
            }), I = R.near, M = R.far);
            let G = D.parent, he = R.cameras;
            q(R, G);
            for(let fe = 0; fe < he.length; fe++)q(he[fe], G);
            he.length === 2 ? z(R, y, b) : R.projectionMatrix.copy(y.projectionMatrix), H(D, R, G);
        };
        function H(D, G, he) {
            he === null ? D.matrix.copy(G.matrixWorld) : (D.matrix.copy(he.matrixWorld), D.matrix.invert(), D.matrix.multiply(G.matrixWorld)), D.matrix.decompose(D.position, D.quaternion, D.scale), D.updateMatrixWorld(!0), D.projectionMatrix.copy(G.projectionMatrix), D.projectionMatrixInverse.copy(G.projectionMatrixInverse), D.isPerspectiveCamera && (D.fov = Zi * 2 * Math.atan(1 / D.projectionMatrix.elements[5]), D.zoom = 1);
        }
        this.getCamera = function() {
            return R;
        }, this.getFoveation = function() {
            if (!(d === null && f === null)) return c;
        }, this.setFoveation = function(D) {
            c = D, d !== null && (d.fixedFoveation = D), f !== null && f.fixedFoveation !== void 0 && (f.fixedFoveation = D);
        };
        let ne = null;
        function W(D, G) {
            if (h = G.getViewerPose(l || a), m = G, h !== null) {
                let he = h.views;
                f !== null && (e.setRenderTargetFramebuffer(p, f.framebuffer), e.setRenderTarget(p));
                let fe = !1;
                he.length !== R.cameras.length && (R.cameras.length = 0, fe = !0);
                for(let _e = 0; _e < he.length; _e++){
                    let we = he[_e], Ee = null;
                    if (f !== null) Ee = f.getViewport(we);
                    else {
                        let Ye = u.getViewSubImage(d, we);
                        Ee = Ye.viewport, _e === 0 && (e.setRenderTargetTextures(p, Ye.colorTexture, d.ignoreDepthValues ? void 0 : Ye.depthStencilTexture), e.setRenderTarget(p));
                    }
                    let Te = w[_e];
                    Te === void 0 && (Te = new yt, Te.layers.enable(_e), Te.viewport = new je, w[_e] = Te), Te.matrix.fromArray(we.transform.matrix), Te.matrix.decompose(Te.position, Te.quaternion, Te.scale), Te.projectionMatrix.fromArray(we.projectionMatrix), Te.projectionMatrixInverse.copy(Te.projectionMatrix).invert(), Te.viewport.set(Ee.x, Ee.y, Ee.width, Ee.height), _e === 0 && (R.matrix.copy(Te.matrix), R.matrix.decompose(R.position, R.quaternion, R.scale)), fe === !0 && R.cameras.push(Te);
                }
            }
            for(let he = 0; he < v.length; he++){
                let fe = x[he], _e = v[he];
                fe !== null && _e !== void 0 && _e.update(fe, G, l || a);
            }
            ne && ne(D, G), G.detectedPlanes && n.dispatchEvent({
                type: "planesdetected",
                data: G
            }), m = null;
        }
        let K = new Ed;
        K.setAnimationLoop(W), this.setAnimationLoop = function(D) {
            ne = D;
        }, this.dispose = function() {};
    }
};
function H0(s1, e) {
    function t(g, p) {
        g.matrixAutoUpdate === !0 && g.updateMatrix(), p.value.copy(g.matrix);
    }
    function n(g, p) {
        p.color.getRGB(g.fogColor.value, bd(s1)), p.isFog ? (g.fogNear.value = p.near, g.fogFar.value = p.far) : p.isFogExp2 && (g.fogDensity.value = p.density);
    }
    function i(g, p, v, x, y) {
        p.isMeshBasicMaterial || p.isMeshLambertMaterial ? r(g, p) : p.isMeshToonMaterial ? (r(g, p), u(g, p)) : p.isMeshPhongMaterial ? (r(g, p), h(g, p)) : p.isMeshStandardMaterial ? (r(g, p), d(g, p), p.isMeshPhysicalMaterial && f(g, p, y)) : p.isMeshMatcapMaterial ? (r(g, p), m(g, p)) : p.isMeshDepthMaterial ? r(g, p) : p.isMeshDistanceMaterial ? (r(g, p), _(g, p)) : p.isMeshNormalMaterial ? r(g, p) : p.isLineBasicMaterial ? (a(g, p), p.isLineDashedMaterial && o(g, p)) : p.isPointsMaterial ? c(g, p, v, x) : p.isSpriteMaterial ? l(g, p) : p.isShadowMaterial ? (g.color.value.copy(p.color), g.opacity.value = p.opacity) : p.isShaderMaterial && (p.uniformsNeedUpdate = !1);
    }
    function r(g, p) {
        g.opacity.value = p.opacity, p.color && g.diffuse.value.copy(p.color), p.emissive && g.emissive.value.copy(p.emissive).multiplyScalar(p.emissiveIntensity), p.map && (g.map.value = p.map, t(p.map, g.mapTransform)), p.alphaMap && (g.alphaMap.value = p.alphaMap, t(p.alphaMap, g.alphaMapTransform)), p.bumpMap && (g.bumpMap.value = p.bumpMap, t(p.bumpMap, g.bumpMapTransform), g.bumpScale.value = p.bumpScale, p.side === Ft && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, t(p.normalMap, g.normalMapTransform), g.normalScale.value.copy(p.normalScale), p.side === Ft && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, t(p.displacementMap, g.displacementMapTransform), g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias), p.emissiveMap && (g.emissiveMap.value = p.emissiveMap, t(p.emissiveMap, g.emissiveMapTransform)), p.specularMap && (g.specularMap.value = p.specularMap, t(p.specularMap, g.specularMapTransform)), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
        let v = e.get(p).envMap;
        if (v && (g.envMap.value = v, g.flipEnvMap.value = v.isCubeTexture && v.isRenderTargetTexture === !1 ? -1 : 1, g.reflectivity.value = p.reflectivity, g.ior.value = p.ior, g.refractionRatio.value = p.refractionRatio), p.lightMap) {
            g.lightMap.value = p.lightMap;
            let x = s1._useLegacyLights === !0 ? Math.PI : 1;
            g.lightMapIntensity.value = p.lightMapIntensity * x, t(p.lightMap, g.lightMapTransform);
        }
        p.aoMap && (g.aoMap.value = p.aoMap, g.aoMapIntensity.value = p.aoMapIntensity, t(p.aoMap, g.aoMapTransform));
    }
    function a(g, p) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, p.map && (g.map.value = p.map, t(p.map, g.mapTransform));
    }
    function o(g, p) {
        g.dashSize.value = p.dashSize, g.totalSize.value = p.dashSize + p.gapSize, g.scale.value = p.scale;
    }
    function c(g, p, v, x) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, g.size.value = p.size * v, g.scale.value = x * .5, p.map && (g.map.value = p.map, t(p.map, g.uvTransform)), p.alphaMap && (g.alphaMap.value = p.alphaMap, t(p.alphaMap, g.alphaMapTransform)), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
    }
    function l(g, p) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, g.rotation.value = p.rotation, p.map && (g.map.value = p.map, t(p.map, g.mapTransform)), p.alphaMap && (g.alphaMap.value = p.alphaMap, t(p.alphaMap, g.alphaMapTransform)), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
    }
    function h(g, p) {
        g.specular.value.copy(p.specular), g.shininess.value = Math.max(p.shininess, 1e-4);
    }
    function u(g, p) {
        p.gradientMap && (g.gradientMap.value = p.gradientMap);
    }
    function d(g, p) {
        g.metalness.value = p.metalness, p.metalnessMap && (g.metalnessMap.value = p.metalnessMap, t(p.metalnessMap, g.metalnessMapTransform)), g.roughness.value = p.roughness, p.roughnessMap && (g.roughnessMap.value = p.roughnessMap, t(p.roughnessMap, g.roughnessMapTransform)), e.get(p).envMap && (g.envMapIntensity.value = p.envMapIntensity);
    }
    function f(g, p, v) {
        g.ior.value = p.ior, p.sheen > 0 && (g.sheenColor.value.copy(p.sheenColor).multiplyScalar(p.sheen), g.sheenRoughness.value = p.sheenRoughness, p.sheenColorMap && (g.sheenColorMap.value = p.sheenColorMap, t(p.sheenColorMap, g.sheenColorMapTransform)), p.sheenRoughnessMap && (g.sheenRoughnessMap.value = p.sheenRoughnessMap, t(p.sheenRoughnessMap, g.sheenRoughnessMapTransform))), p.clearcoat > 0 && (g.clearcoat.value = p.clearcoat, g.clearcoatRoughness.value = p.clearcoatRoughness, p.clearcoatMap && (g.clearcoatMap.value = p.clearcoatMap, t(p.clearcoatMap, g.clearcoatMapTransform)), p.clearcoatRoughnessMap && (g.clearcoatRoughnessMap.value = p.clearcoatRoughnessMap, t(p.clearcoatRoughnessMap, g.clearcoatRoughnessMapTransform)), p.clearcoatNormalMap && (g.clearcoatNormalMap.value = p.clearcoatNormalMap, t(p.clearcoatNormalMap, g.clearcoatNormalMapTransform), g.clearcoatNormalScale.value.copy(p.clearcoatNormalScale), p.side === Ft && g.clearcoatNormalScale.value.negate())), p.iridescence > 0 && (g.iridescence.value = p.iridescence, g.iridescenceIOR.value = p.iridescenceIOR, g.iridescenceThicknessMinimum.value = p.iridescenceThicknessRange[0], g.iridescenceThicknessMaximum.value = p.iridescenceThicknessRange[1], p.iridescenceMap && (g.iridescenceMap.value = p.iridescenceMap, t(p.iridescenceMap, g.iridescenceMapTransform)), p.iridescenceThicknessMap && (g.iridescenceThicknessMap.value = p.iridescenceThicknessMap, t(p.iridescenceThicknessMap, g.iridescenceThicknessMapTransform))), p.transmission > 0 && (g.transmission.value = p.transmission, g.transmissionSamplerMap.value = v.texture, g.transmissionSamplerSize.value.set(v.width, v.height), p.transmissionMap && (g.transmissionMap.value = p.transmissionMap, t(p.transmissionMap, g.transmissionMapTransform)), g.thickness.value = p.thickness, p.thicknessMap && (g.thicknessMap.value = p.thicknessMap, t(p.thicknessMap, g.thicknessMapTransform)), g.attenuationDistance.value = p.attenuationDistance, g.attenuationColor.value.copy(p.attenuationColor)), p.anisotropy > 0 && (g.anisotropyVector.value.set(p.anisotropy * Math.cos(p.anisotropyRotation), p.anisotropy * Math.sin(p.anisotropyRotation)), p.anisotropyMap && (g.anisotropyMap.value = p.anisotropyMap, t(p.anisotropyMap, g.anisotropyMapTransform))), g.specularIntensity.value = p.specularIntensity, g.specularColor.value.copy(p.specularColor), p.specularColorMap && (g.specularColorMap.value = p.specularColorMap, t(p.specularColorMap, g.specularColorMapTransform)), p.specularIntensityMap && (g.specularIntensityMap.value = p.specularIntensityMap, t(p.specularIntensityMap, g.specularIntensityMapTransform));
    }
    function m(g, p) {
        p.matcap && (g.matcap.value = p.matcap);
    }
    function _(g, p) {
        let v = e.get(p).light;
        g.referencePosition.value.setFromMatrixPosition(v.matrixWorld), g.nearDistance.value = v.shadow.camera.near, g.farDistance.value = v.shadow.camera.far;
    }
    return {
        refreshFogUniforms: n,
        refreshMaterialUniforms: i
    };
}
function G0(s1, e, t, n) {
    let i = {}, r = {}, a = [], o = t.isWebGL2 ? s1.getParameter(s1.MAX_UNIFORM_BUFFER_BINDINGS) : 0;
    function c(v, x) {
        let y = x.program;
        n.uniformBlockBinding(v, y);
    }
    function l(v, x) {
        let y = i[v.id];
        y === void 0 && (m(v), y = h(v), i[v.id] = y, v.addEventListener("dispose", g));
        let b = x.program;
        n.updateUBOMapping(v, b);
        let w = e.render.frame;
        r[v.id] !== w && (d(v), r[v.id] = w);
    }
    function h(v) {
        let x = u();
        v.__bindingPointIndex = x;
        let y = s1.createBuffer(), b = v.__size, w = v.usage;
        return s1.bindBuffer(s1.UNIFORM_BUFFER, y), s1.bufferData(s1.UNIFORM_BUFFER, b, w), s1.bindBuffer(s1.UNIFORM_BUFFER, null), s1.bindBufferBase(s1.UNIFORM_BUFFER, x, y), y;
    }
    function u() {
        for(let v = 0; v < o; v++)if (a.indexOf(v) === -1) return a.push(v), v;
        return console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached."), 0;
    }
    function d(v) {
        let x = i[v.id], y = v.uniforms, b = v.__cache;
        s1.bindBuffer(s1.UNIFORM_BUFFER, x);
        for(let w = 0, R = y.length; w < R; w++){
            let I = y[w];
            if (f(I, w, b) === !0) {
                let M = I.__offset, T = Array.isArray(I.value) ? I.value : [
                    I.value
                ], O = 0;
                for(let Y = 0; Y < T.length; Y++){
                    let $ = T[Y], U = _($);
                    typeof $ == "number" ? (I.__data[0] = $, s1.bufferSubData(s1.UNIFORM_BUFFER, M + O, I.__data)) : $.isMatrix3 ? (I.__data[0] = $.elements[0], I.__data[1] = $.elements[1], I.__data[2] = $.elements[2], I.__data[3] = $.elements[0], I.__data[4] = $.elements[3], I.__data[5] = $.elements[4], I.__data[6] = $.elements[5], I.__data[7] = $.elements[0], I.__data[8] = $.elements[6], I.__data[9] = $.elements[7], I.__data[10] = $.elements[8], I.__data[11] = $.elements[0]) : ($.toArray(I.__data, O), O += U.storage / Float32Array.BYTES_PER_ELEMENT);
                }
                s1.bufferSubData(s1.UNIFORM_BUFFER, M, I.__data);
            }
        }
        s1.bindBuffer(s1.UNIFORM_BUFFER, null);
    }
    function f(v, x, y) {
        let b = v.value;
        if (y[x] === void 0) {
            if (typeof b == "number") y[x] = b;
            else {
                let w = Array.isArray(b) ? b : [
                    b
                ], R = [];
                for(let I = 0; I < w.length; I++)R.push(w[I].clone());
                y[x] = R;
            }
            return !0;
        } else if (typeof b == "number") {
            if (y[x] !== b) return y[x] = b, !0;
        } else {
            let w = Array.isArray(y[x]) ? y[x] : [
                y[x]
            ], R = Array.isArray(b) ? b : [
                b
            ];
            for(let I = 0; I < w.length; I++){
                let M = w[I];
                if (M.equals(R[I]) === !1) return M.copy(R[I]), !0;
            }
        }
        return !1;
    }
    function m(v) {
        let x = v.uniforms, y = 0, b = 16, w = 0;
        for(let R = 0, I = x.length; R < I; R++){
            let M = x[R], T = {
                boundary: 0,
                storage: 0
            }, O = Array.isArray(M.value) ? M.value : [
                M.value
            ];
            for(let Y = 0, $ = O.length; Y < $; Y++){
                let U = O[Y], z = _(U);
                T.boundary += z.boundary, T.storage += z.storage;
            }
            if (M.__data = new Float32Array(T.storage / Float32Array.BYTES_PER_ELEMENT), M.__offset = y, R > 0) {
                w = y % b;
                let Y = b - w;
                w !== 0 && Y - T.boundary < 0 && (y += b - w, M.__offset = y);
            }
            y += T.storage;
        }
        return w = y % b, w > 0 && (y += b - w), v.__size = y, v.__cache = {}, this;
    }
    function _(v) {
        let x = {
            boundary: 0,
            storage: 0
        };
        return typeof v == "number" ? (x.boundary = 4, x.storage = 4) : v.isVector2 ? (x.boundary = 8, x.storage = 8) : v.isVector3 || v.isColor ? (x.boundary = 16, x.storage = 12) : v.isVector4 ? (x.boundary = 16, x.storage = 16) : v.isMatrix3 ? (x.boundary = 48, x.storage = 48) : v.isMatrix4 ? (x.boundary = 64, x.storage = 64) : v.isTexture ? console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.") : console.warn("THREE.WebGLRenderer: Unsupported uniform value type.", v), x;
    }
    function g(v) {
        let x = v.target;
        x.removeEventListener("dispose", g);
        let y = a.indexOf(x.__bindingPointIndex);
        a.splice(y, 1), s1.deleteBuffer(i[x.id]), delete i[x.id], delete r[x.id];
    }
    function p() {
        for(let v in i)s1.deleteBuffer(i[v]);
        a = [], i = {}, r = {};
    }
    return {
        bind: c,
        update: l,
        dispose: p
    };
}
var Ro = class {
    constructor(e = {}){
        let { canvas: t = tp() , context: n = null , depth: i = !0 , stencil: r = !0 , alpha: a = !1 , antialias: o = !1 , premultipliedAlpha: c = !0 , preserveDrawingBuffer: l = !1 , powerPreference: h = "default" , failIfMajorPerformanceCaveat: u = !1  } = e;
        this.isWebGLRenderer = !0;
        let d;
        n !== null ? d = n.getContextAttributes().alpha : d = a;
        let f = new Uint32Array(4), m = new Int32Array(4), _ = null, g = null, p = [], v = [];
        this.domElement = t, this.debug = {
            checkShaderErrors: !0,
            onShaderError: null
        }, this.autoClear = !0, this.autoClearColor = !0, this.autoClearDepth = !0, this.autoClearStencil = !0, this.sortObjects = !0, this.clippingPlanes = [], this.localClippingEnabled = !1, this._outputColorSpace = vt, this._useLegacyLights = !1, this.toneMapping = Nn, this.toneMappingExposure = 1;
        let x = this, y = !1, b = 0, w = 0, R = null, I = -1, M = null, T = new je, O = new je, Y = null, $ = new pe(0), U = 0, z = t.width, q = t.height, H = 1, ne = null, W = null, K = new je(0, 0, z, q), D = new je(0, 0, z, q), G = !1, he = new Ps, fe = !1, _e = !1, we = null, Ee = new ze, Te = new Z, Ye = new A, it = {
            background: null,
            fog: null,
            environment: null,
            overrideMaterial: null,
            isScene: !0
        };
        function Ce() {
            return R === null ? H : 1;
        }
        let L = n;
        function oe(E, N) {
            for(let V = 0; V < E.length; V++){
                let F = E[V], k = t.getContext(F, N);
                if (k !== null) return k;
            }
            return null;
        }
        try {
            let E = {
                alpha: !0,
                depth: i,
                stencil: r,
                antialias: o,
                premultipliedAlpha: c,
                preserveDrawingBuffer: l,
                powerPreference: h,
                failIfMajorPerformanceCaveat: u
            };
            if ("setAttribute" in t && t.setAttribute("data-engine", `three.js r${Hc}`), t.addEventListener("webglcontextlost", ce, !1), t.addEventListener("webglcontextrestored", ae, !1), t.addEventListener("webglcontextcreationerror", ge, !1), L === null) {
                let N = [
                    "webgl2",
                    "webgl",
                    "experimental-webgl"
                ];
                if (x.isWebGL1Renderer === !0 && N.shift(), L = oe(N, E), L === null) throw oe(N) ? new Error("Error creating WebGL context with your selected attributes.") : new Error("Error creating WebGL context.");
            }
            typeof WebGLRenderingContext < "u" && L instanceof WebGLRenderingContext && console.warn("THREE.WebGLRenderer: WebGL 1 support was deprecated in r153 and will be removed in r163."), L.getShaderPrecisionFormat === void 0 && (L.getShaderPrecisionFormat = function() {
                return {
                    rangeMin: 1,
                    rangeMax: 1,
                    precision: 1
                };
            });
        } catch (E) {
            throw console.error("THREE.WebGLRenderer: " + E.message), E;
        }
        let X, ie, J, Se, me, ye, Ne, qe, rt, C, S, B, ee, j, te, Me, re, de, Le, Ze, se, $e, Oe, Ie;
        function Re() {
            X = new h_(L), ie = new s_(L, X, e), X.init(ie), $e = new V0(L, X, ie), J = new B0(L, X, ie), Se = new f_(L), me = new w0, ye = new z0(L, X, J, me, ie, $e, Se), Ne = new a_(x), qe = new l_(x), rt = new bp(L, ie), Oe = new n_(L, X, rt, ie), C = new u_(L, rt, Se, Oe), S = new __(L, C, rt, Se), Le = new g_(L, ie, ye), Me = new r_(me), B = new T0(x, Ne, qe, X, ie, Oe, Me), ee = new H0(x, me), j = new R0, te = new D0(X, ie), de = new t_(x, Ne, qe, J, S, d, c), re = new F0(x, S, ie), Ie = new G0(L, Se, ie, J), Ze = new i_(L, X, Se, ie), se = new d_(L, X, Se, ie), Se.programs = B.programs, x.capabilities = ie, x.extensions = X, x.properties = me, x.renderLists = j, x.shadowMap = re, x.state = J, x.info = Se;
        }
        Re();
        let P = new Ao(x, L);
        this.xr = P, this.getContext = function() {
            return L;
        }, this.getContextAttributes = function() {
            return L.getContextAttributes();
        }, this.forceContextLoss = function() {
            let E = X.get("WEBGL_lose_context");
            E && E.loseContext();
        }, this.forceContextRestore = function() {
            let E = X.get("WEBGL_lose_context");
            E && E.restoreContext();
        }, this.getPixelRatio = function() {
            return H;
        }, this.setPixelRatio = function(E) {
            E !== void 0 && (H = E, this.setSize(z, q, !1));
        }, this.getSize = function(E) {
            return E.set(z, q);
        }, this.setSize = function(E, N, V = !0) {
            if (P.isPresenting) {
                console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting.");
                return;
            }
            z = E, q = N, t.width = Math.floor(E * H), t.height = Math.floor(N * H), V === !0 && (t.style.width = E + "px", t.style.height = N + "px"), this.setViewport(0, 0, E, N);
        }, this.getDrawingBufferSize = function(E) {
            return E.set(z * H, q * H).floor();
        }, this.setDrawingBufferSize = function(E, N, V) {
            z = E, q = N, H = V, t.width = Math.floor(E * V), t.height = Math.floor(N * V), this.setViewport(0, 0, E, N);
        }, this.getCurrentViewport = function(E) {
            return E.copy(T);
        }, this.getViewport = function(E) {
            return E.copy(K);
        }, this.setViewport = function(E, N, V, F) {
            E.isVector4 ? K.set(E.x, E.y, E.z, E.w) : K.set(E, N, V, F), J.viewport(T.copy(K).multiplyScalar(H).floor());
        }, this.getScissor = function(E) {
            return E.copy(D);
        }, this.setScissor = function(E, N, V, F) {
            E.isVector4 ? D.set(E.x, E.y, E.z, E.w) : D.set(E, N, V, F), J.scissor(O.copy(D).multiplyScalar(H).floor());
        }, this.getScissorTest = function() {
            return G;
        }, this.setScissorTest = function(E) {
            J.setScissorTest(G = E);
        }, this.setOpaqueSort = function(E) {
            ne = E;
        }, this.setTransparentSort = function(E) {
            W = E;
        }, this.getClearColor = function(E) {
            return E.copy(de.getClearColor());
        }, this.setClearColor = function() {
            de.setClearColor.apply(de, arguments);
        }, this.getClearAlpha = function() {
            return de.getClearAlpha();
        }, this.setClearAlpha = function() {
            de.setClearAlpha.apply(de, arguments);
        }, this.clear = function(E = !0, N = !0, V = !0) {
            let F = 0;
            if (E) {
                let k = !1;
                if (R !== null) {
                    let xe = R.texture.format;
                    k = xe === _d || xe === gd || xe === md;
                }
                if (k) {
                    let xe = R.texture.type, Ae = xe === On || xe === Ln || xe === Wc || xe === ii || xe === fd || xe === pd, Ue = de.getClearColor(), De = de.getClearAlpha(), We = Ue.r, Pe = Ue.g, Ve = Ue.b;
                    Ae ? (f[0] = We, f[1] = Pe, f[2] = Ve, f[3] = De, L.clearBufferuiv(L.COLOR, 0, f)) : (m[0] = We, m[1] = Pe, m[2] = Ve, m[3] = De, L.clearBufferiv(L.COLOR, 0, m));
                } else F |= L.COLOR_BUFFER_BIT;
            }
            N && (F |= L.DEPTH_BUFFER_BIT), V && (F |= L.STENCIL_BUFFER_BIT), L.clear(F);
        }, this.clearColor = function() {
            this.clear(!0, !1, !1);
        }, this.clearDepth = function() {
            this.clear(!1, !0, !1);
        }, this.clearStencil = function() {
            this.clear(!1, !1, !0);
        }, this.dispose = function() {
            t.removeEventListener("webglcontextlost", ce, !1), t.removeEventListener("webglcontextrestored", ae, !1), t.removeEventListener("webglcontextcreationerror", ge, !1), j.dispose(), te.dispose(), me.dispose(), Ne.dispose(), qe.dispose(), S.dispose(), Oe.dispose(), Ie.dispose(), B.dispose(), P.dispose(), P.removeEventListener("sessionstart", tt), P.removeEventListener("sessionend", tn), we && (we.dispose(), we = null), Rt.stop();
        };
        function ce(E) {
            E.preventDefault(), console.log("THREE.WebGLRenderer: Context Lost."), y = !0;
        }
        function ae() {
            console.log("THREE.WebGLRenderer: Context Restored."), y = !1;
            let E = Se.autoReset, N = re.enabled, V = re.autoUpdate, F = re.needsUpdate, k = re.type;
            Re(), Se.autoReset = E, re.enabled = N, re.autoUpdate = V, re.needsUpdate = F, re.type = k;
        }
        function ge(E) {
            console.error("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ", E.statusMessage);
        }
        function ue(E) {
            let N = E.target;
            N.removeEventListener("dispose", ue), Q(N);
        }
        function Q(E) {
            be(E), me.remove(E);
        }
        function be(E) {
            let N = me.get(E).programs;
            N !== void 0 && (N.forEach(function(V) {
                B.releaseProgram(V);
            }), E.isShaderMaterial && B.releaseShaderCache(E));
        }
        this.renderBufferDirect = function(E, N, V, F, k, xe) {
            N === null && (N = it);
            let Ae = k.isMesh && k.matrixWorld.determinant() < 0, Ue = Fd(E, N, V, F, k);
            J.setMaterial(F, Ae);
            let De = V.index, We = 1;
            if (F.wireframe === !0) {
                if (De = C.getWireframeAttribute(V), De === void 0) return;
                We = 2;
            }
            let Pe = V.drawRange, Ve = V.attributes.position, at = Pe.start * We, lt = (Pe.start + Pe.count) * We;
            xe !== null && (at = Math.max(at, xe.start * We), lt = Math.min(lt, (xe.start + xe.count) * We)), De !== null ? (at = Math.max(at, 0), lt = Math.min(lt, De.count)) : Ve != null && (at = Math.max(at, 0), lt = Math.min(lt, Ve.count));
            let Ht = lt - at;
            if (Ht < 0 || Ht === 1 / 0) return;
            Oe.setup(k, F, Ue, V, De);
            let an, ut = Ze;
            if (De !== null && (an = rt.get(De), ut = se, ut.setIndex(an)), k.isMesh) F.wireframe === !0 ? (J.setLineWidth(F.wireframeLinewidth * Ce()), ut.setMode(L.LINES)) : ut.setMode(L.TRIANGLES);
            else if (k.isLine) {
                let Xe = F.linewidth;
                Xe === void 0 && (Xe = 1), J.setLineWidth(Xe * Ce()), k.isLineSegments ? ut.setMode(L.LINES) : k.isLineLoop ? ut.setMode(L.LINE_LOOP) : ut.setMode(L.LINE_STRIP);
            } else k.isPoints ? ut.setMode(L.POINTS) : k.isSprite && ut.setMode(L.TRIANGLES);
            if (k.isInstancedMesh) ut.renderInstances(at, Ht, k.count);
            else if (V.isInstancedBufferGeometry) {
                let Xe = V._maxInstanceCount !== void 0 ? V._maxInstanceCount : 1 / 0, Sa = Math.min(V.instanceCount, Xe);
                ut.renderInstances(at, Ht, Sa);
            } else ut.render(at, Ht);
        }, this.compile = function(E, N) {
            function V(F, k, xe) {
                F.transparent === !0 && F.side === gn && F.forceSinglePass === !1 ? (F.side = Ft, F.needsUpdate = !0, Hs(F, k, xe), F.side = Bn, F.needsUpdate = !0, Hs(F, k, xe), F.side = gn) : Hs(F, k, xe);
            }
            g = te.get(E), g.init(), v.push(g), E.traverseVisible(function(F) {
                F.isLight && F.layers.test(N.layers) && (g.pushLight(F), F.castShadow && g.pushShadow(F));
            }), g.setupLights(x._useLegacyLights), E.traverse(function(F) {
                let k = F.material;
                if (k) if (Array.isArray(k)) for(let xe = 0; xe < k.length; xe++){
                    let Ae = k[xe];
                    V(Ae, E, F);
                }
                else V(k, E, F);
            }), v.pop(), g = null;
        };
        let Fe = null;
        function At(E) {
            Fe && Fe(E);
        }
        function tt() {
            Rt.stop();
        }
        function tn() {
            Rt.start();
        }
        let Rt = new Ed;
        Rt.setAnimationLoop(At), typeof self < "u" && Rt.setContext(self), this.setAnimationLoop = function(E) {
            Fe = E, P.setAnimationLoop(E), E === null ? Rt.stop() : Rt.start();
        }, P.addEventListener("sessionstart", tt), P.addEventListener("sessionend", tn), this.render = function(E, N) {
            if (N !== void 0 && N.isCamera !== !0) {
                console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
                return;
            }
            if (y === !0) return;
            E.matrixWorldAutoUpdate === !0 && E.updateMatrixWorld(), N.parent === null && N.matrixWorldAutoUpdate === !0 && N.updateMatrixWorld(), P.enabled === !0 && P.isPresenting === !0 && (P.cameraAutoUpdate === !0 && P.updateCamera(N), N = P.getCamera()), E.isScene === !0 && E.onBeforeRender(x, E, N, R), g = te.get(E, v.length), g.init(), v.push(g), Ee.multiplyMatrices(N.projectionMatrix, N.matrixWorldInverse), he.setFromProjectionMatrix(Ee), _e = this.localClippingEnabled, fe = Me.init(this.clippingPlanes, _e), _ = j.get(E, p.length), _.init(), p.push(_), jc(E, N, 0, x.sortObjects), _.finish(), x.sortObjects === !0 && _.sort(ne, W), this.info.render.frame++, fe === !0 && Me.beginShadows();
            let V = g.state.shadowsArray;
            if (re.render(V, E, N), fe === !0 && Me.endShadows(), this.info.autoReset === !0 && this.info.reset(), de.render(_, E), g.setupLights(x._useLegacyLights), N.isArrayCamera) {
                let F = N.cameras;
                for(let k = 0, xe = F.length; k < xe; k++){
                    let Ae = F[k];
                    el(_, E, Ae, Ae.viewport);
                }
            } else el(_, E, N);
            R !== null && (ye.updateMultisampleRenderTarget(R), ye.updateRenderTargetMipmap(R)), E.isScene === !0 && E.onAfterRender(x, E, N), Oe.resetDefaultState(), I = -1, M = null, v.pop(), v.length > 0 ? g = v[v.length - 1] : g = null, p.pop(), p.length > 0 ? _ = p[p.length - 1] : _ = null;
        };
        function jc(E, N, V, F) {
            if (E.visible === !1) return;
            if (E.layers.test(N.layers)) {
                if (E.isGroup) V = E.renderOrder;
                else if (E.isLOD) E.autoUpdate === !0 && E.update(N);
                else if (E.isLight) g.pushLight(E), E.castShadow && g.pushShadow(E);
                else if (E.isSprite) {
                    if (!E.frustumCulled || he.intersectsSprite(E)) {
                        F && Ye.setFromMatrixPosition(E.matrixWorld).applyMatrix4(Ee);
                        let Ae = S.update(E), Ue = E.material;
                        Ue.visible && _.push(E, Ae, Ue, V, Ye.z, null);
                    }
                } else if ((E.isMesh || E.isLine || E.isPoints) && (!E.frustumCulled || he.intersectsObject(E))) {
                    let Ae = S.update(E), Ue = E.material;
                    if (F && (E.boundingSphere !== void 0 ? (E.boundingSphere === null && E.computeBoundingSphere(), Ye.copy(E.boundingSphere.center)) : (Ae.boundingSphere === null && Ae.computeBoundingSphere(), Ye.copy(Ae.boundingSphere.center)), Ye.applyMatrix4(E.matrixWorld).applyMatrix4(Ee)), Array.isArray(Ue)) {
                        let De = Ae.groups;
                        for(let We = 0, Pe = De.length; We < Pe; We++){
                            let Ve = De[We], at = Ue[Ve.materialIndex];
                            at && at.visible && _.push(E, Ae, at, V, Ye.z, Ve);
                        }
                    } else Ue.visible && _.push(E, Ae, Ue, V, Ye.z, null);
                }
            }
            let xe = E.children;
            for(let Ae = 0, Ue = xe.length; Ae < Ue; Ae++)jc(xe[Ae], N, V, F);
        }
        function el(E, N, V, F) {
            let k = E.opaque, xe = E.transmissive, Ae = E.transparent;
            g.setupLightsView(V), fe === !0 && Me.setGlobalState(x.clippingPlanes, V), xe.length > 0 && Od(k, xe, N, V), F && J.viewport(T.copy(F)), k.length > 0 && ks(k, N, V), xe.length > 0 && ks(xe, N, V), Ae.length > 0 && ks(Ae, N, V), J.buffers.depth.setTest(!0), J.buffers.depth.setMask(!0), J.buffers.color.setMask(!0), J.setPolygonOffset(!1);
        }
        function Od(E, N, V, F) {
            let k = ie.isWebGL2;
            we === null && (we = new qt(1, 1, {
                generateMipmaps: !0,
                type: X.has("EXT_color_buffer_half_float") ? Ts : On,
                minFilter: li,
                samples: k ? 4 : 0
            })), x.getDrawingBufferSize(Te), k ? we.setSize(Te.x, Te.y) : we.setSize(Wr(Te.x), Wr(Te.y));
            let xe = x.getRenderTarget();
            x.setRenderTarget(we), x.getClearColor($), U = x.getClearAlpha(), U < 1 && x.setClearColor(16777215, .5), x.clear();
            let Ae = x.toneMapping;
            x.toneMapping = Nn, ks(E, V, F), ye.updateMultisampleRenderTarget(we), ye.updateRenderTargetMipmap(we);
            let Ue = !1;
            for(let De = 0, We = N.length; De < We; De++){
                let Pe = N[De], Ve = Pe.object, at = Pe.geometry, lt = Pe.material, Ht = Pe.group;
                if (lt.side === gn && Ve.layers.test(F.layers)) {
                    let an = lt.side;
                    lt.side = Ft, lt.needsUpdate = !0, tl(Ve, V, F, at, lt, Ht), lt.side = an, lt.needsUpdate = !0, Ue = !0;
                }
            }
            Ue === !0 && (ye.updateMultisampleRenderTarget(we), ye.updateRenderTargetMipmap(we)), x.setRenderTarget(xe), x.setClearColor($, U), x.toneMapping = Ae;
        }
        function ks(E, N, V) {
            let F = N.isScene === !0 ? N.overrideMaterial : null;
            for(let k = 0, xe = E.length; k < xe; k++){
                let Ae = E[k], Ue = Ae.object, De = Ae.geometry, We = F === null ? Ae.material : F, Pe = Ae.group;
                Ue.layers.test(V.layers) && tl(Ue, N, V, De, We, Pe);
            }
        }
        function tl(E, N, V, F, k, xe) {
            E.onBeforeRender(x, N, V, F, k, xe), E.modelViewMatrix.multiplyMatrices(V.matrixWorldInverse, E.matrixWorld), E.normalMatrix.getNormalMatrix(E.modelViewMatrix), k.onBeforeRender(x, N, V, F, E, xe), k.transparent === !0 && k.side === gn && k.forceSinglePass === !1 ? (k.side = Ft, k.needsUpdate = !0, x.renderBufferDirect(V, N, F, k, E, xe), k.side = Bn, k.needsUpdate = !0, x.renderBufferDirect(V, N, F, k, E, xe), k.side = gn) : x.renderBufferDirect(V, N, F, k, E, xe), E.onAfterRender(x, N, V, F, k, xe);
        }
        function Hs(E, N, V) {
            N.isScene !== !0 && (N = it);
            let F = me.get(E), k = g.state.lights, xe = g.state.shadowsArray, Ae = k.state.version, Ue = B.getParameters(E, k.state, xe, N, V), De = B.getProgramCacheKey(Ue), We = F.programs;
            F.environment = E.isMeshStandardMaterial ? N.environment : null, F.fog = N.fog, F.envMap = (E.isMeshStandardMaterial ? qe : Ne).get(E.envMap || F.environment), We === void 0 && (E.addEventListener("dispose", ue), We = new Map, F.programs = We);
            let Pe = We.get(De);
            if (Pe !== void 0) {
                if (F.currentProgram === Pe && F.lightsStateVersion === Ae) return nl(E, Ue), Pe;
            } else Ue.uniforms = B.getUniforms(E), E.onBuild(V, Ue, x), E.onBeforeCompile(Ue, x), Pe = B.acquireProgram(Ue, De), We.set(De, Pe), F.uniforms = Ue.uniforms;
            let Ve = F.uniforms;
            (!E.isShaderMaterial && !E.isRawShaderMaterial || E.clipping === !0) && (Ve.clippingPlanes = Me.uniform), nl(E, Ue), F.needsLights = zd(E), F.lightsStateVersion = Ae, F.needsLights && (Ve.ambientLightColor.value = k.state.ambient, Ve.lightProbe.value = k.state.probe, Ve.directionalLights.value = k.state.directional, Ve.directionalLightShadows.value = k.state.directionalShadow, Ve.spotLights.value = k.state.spot, Ve.spotLightShadows.value = k.state.spotShadow, Ve.rectAreaLights.value = k.state.rectArea, Ve.ltc_1.value = k.state.rectAreaLTC1, Ve.ltc_2.value = k.state.rectAreaLTC2, Ve.pointLights.value = k.state.point, Ve.pointLightShadows.value = k.state.pointShadow, Ve.hemisphereLights.value = k.state.hemi, Ve.directionalShadowMap.value = k.state.directionalShadowMap, Ve.directionalShadowMatrix.value = k.state.directionalShadowMatrix, Ve.spotShadowMap.value = k.state.spotShadowMap, Ve.spotLightMatrix.value = k.state.spotLightMatrix, Ve.spotLightMap.value = k.state.spotLightMap, Ve.pointShadowMap.value = k.state.pointShadowMap, Ve.pointShadowMatrix.value = k.state.pointShadowMatrix);
            let at = Pe.getUniforms(), lt = qi.seqWithValue(at.seq, Ve);
            return F.currentProgram = Pe, F.uniformsList = lt, Pe;
        }
        function nl(E, N) {
            let V = me.get(E);
            V.outputColorSpace = N.outputColorSpace, V.instancing = N.instancing, V.instancingColor = N.instancingColor, V.skinning = N.skinning, V.morphTargets = N.morphTargets, V.morphNormals = N.morphNormals, V.morphColors = N.morphColors, V.morphTargetsCount = N.morphTargetsCount, V.numClippingPlanes = N.numClippingPlanes, V.numIntersection = N.numClipIntersection, V.vertexAlphas = N.vertexAlphas, V.vertexTangents = N.vertexTangents, V.toneMapping = N.toneMapping;
        }
        function Fd(E, N, V, F, k) {
            N.isScene !== !0 && (N = it), ye.resetTextureUnits();
            let xe = N.fog, Ae = F.isMeshStandardMaterial ? N.environment : null, Ue = R === null ? x.outputColorSpace : R.isXRRenderTarget === !0 ? R.texture.colorSpace : Mn, De = (F.isMeshStandardMaterial ? qe : Ne).get(F.envMap || Ae), We = F.vertexColors === !0 && !!V.attributes.color && V.attributes.color.itemSize === 4, Pe = !!V.attributes.tangent && (!!F.normalMap || F.anisotropy > 0), Ve = !!V.morphAttributes.position, at = !!V.morphAttributes.normal, lt = !!V.morphAttributes.color, Ht = Nn;
            F.toneMapped && (R === null || R.isXRRenderTarget === !0) && (Ht = x.toneMapping);
            let an = V.morphAttributes.position || V.morphAttributes.normal || V.morphAttributes.color, ut = an !== void 0 ? an.length : 0, Xe = me.get(F), Sa = g.state.lights;
            if (fe === !0 && (_e === !0 || E !== M)) {
                let Bt = E === M && F.id === I;
                Me.setState(F, E, Bt);
            }
            let dt = !1;
            F.version === Xe.__version ? (Xe.needsLights && Xe.lightsStateVersion !== Sa.state.version || Xe.outputColorSpace !== Ue || k.isInstancedMesh && Xe.instancing === !1 || !k.isInstancedMesh && Xe.instancing === !0 || k.isSkinnedMesh && Xe.skinning === !1 || !k.isSkinnedMesh && Xe.skinning === !0 || k.isInstancedMesh && Xe.instancingColor === !0 && k.instanceColor === null || k.isInstancedMesh && Xe.instancingColor === !1 && k.instanceColor !== null || Xe.envMap !== De || F.fog === !0 && Xe.fog !== xe || Xe.numClippingPlanes !== void 0 && (Xe.numClippingPlanes !== Me.numPlanes || Xe.numIntersection !== Me.numIntersection) || Xe.vertexAlphas !== We || Xe.vertexTangents !== Pe || Xe.morphTargets !== Ve || Xe.morphNormals !== at || Xe.morphColors !== lt || Xe.toneMapping !== Ht || ie.isWebGL2 === !0 && Xe.morphTargetsCount !== ut) && (dt = !0) : (dt = !0, Xe.__version = F.version);
            let Hn = Xe.currentProgram;
            dt === !0 && (Hn = Hs(F, N, k));
            let il = !1, os = !1, ba = !1, Ct = Hn.getUniforms(), Gn = Xe.uniforms;
            if (J.useProgram(Hn.program) && (il = !0, os = !0, ba = !0), F.id !== I && (I = F.id, os = !0), il || M !== E) {
                Ct.setValue(L, "projectionMatrix", E.projectionMatrix), Ct.setValue(L, "viewMatrix", E.matrixWorldInverse);
                let Bt = Ct.map.cameraPosition;
                Bt !== void 0 && Bt.setValue(L, Ye.setFromMatrixPosition(E.matrixWorld)), ie.logarithmicDepthBuffer && Ct.setValue(L, "logDepthBufFC", 2 / (Math.log(E.far + 1) / Math.LN2)), (F.isMeshPhongMaterial || F.isMeshToonMaterial || F.isMeshLambertMaterial || F.isMeshBasicMaterial || F.isMeshStandardMaterial || F.isShaderMaterial) && Ct.setValue(L, "isOrthographic", E.isOrthographicCamera === !0), M !== E && (M = E, os = !0, ba = !0);
            }
            if (k.isSkinnedMesh) {
                Ct.setOptional(L, k, "bindMatrix"), Ct.setOptional(L, k, "bindMatrixInverse");
                let Bt = k.skeleton;
                Bt && (ie.floatVertexTextures ? (Bt.boneTexture === null && Bt.computeBoneTexture(), Ct.setValue(L, "boneTexture", Bt.boneTexture, ye), Ct.setValue(L, "boneTextureSize", Bt.boneTextureSize)) : console.warn("THREE.WebGLRenderer: SkinnedMesh can only be used with WebGL 2. With WebGL 1 OES_texture_float and vertex textures support is required."));
            }
            let Ea = V.morphAttributes;
            if ((Ea.position !== void 0 || Ea.normal !== void 0 || Ea.color !== void 0 && ie.isWebGL2 === !0) && Le.update(k, V, Hn), (os || Xe.receiveShadow !== k.receiveShadow) && (Xe.receiveShadow = k.receiveShadow, Ct.setValue(L, "receiveShadow", k.receiveShadow)), F.isMeshGouraudMaterial && F.envMap !== null && (Gn.envMap.value = De, Gn.flipEnvMap.value = De.isCubeTexture && De.isRenderTargetTexture === !1 ? -1 : 1), os && (Ct.setValue(L, "toneMappingExposure", x.toneMappingExposure), Xe.needsLights && Bd(Gn, ba), xe && F.fog === !0 && ee.refreshFogUniforms(Gn, xe), ee.refreshMaterialUniforms(Gn, F, H, q, we), qi.upload(L, Xe.uniformsList, Gn, ye)), F.isShaderMaterial && F.uniformsNeedUpdate === !0 && (qi.upload(L, Xe.uniformsList, Gn, ye), F.uniformsNeedUpdate = !1), F.isSpriteMaterial && Ct.setValue(L, "center", k.center), Ct.setValue(L, "modelViewMatrix", k.modelViewMatrix), Ct.setValue(L, "normalMatrix", k.normalMatrix), Ct.setValue(L, "modelMatrix", k.matrixWorld), F.isShaderMaterial || F.isRawShaderMaterial) {
                let Bt = F.uniformsGroups;
                for(let Ta = 0, Vd = Bt.length; Ta < Vd; Ta++)if (ie.isWebGL2) {
                    let sl = Bt[Ta];
                    Ie.update(sl, Hn), Ie.bind(sl, Hn);
                } else console.warn("THREE.WebGLRenderer: Uniform Buffer Objects can only be used with WebGL 2.");
            }
            return Hn;
        }
        function Bd(E, N) {
            E.ambientLightColor.needsUpdate = N, E.lightProbe.needsUpdate = N, E.directionalLights.needsUpdate = N, E.directionalLightShadows.needsUpdate = N, E.pointLights.needsUpdate = N, E.pointLightShadows.needsUpdate = N, E.spotLights.needsUpdate = N, E.spotLightShadows.needsUpdate = N, E.rectAreaLights.needsUpdate = N, E.hemisphereLights.needsUpdate = N;
        }
        function zd(E) {
            return E.isMeshLambertMaterial || E.isMeshToonMaterial || E.isMeshPhongMaterial || E.isMeshStandardMaterial || E.isShadowMaterial || E.isShaderMaterial && E.lights === !0;
        }
        this.getActiveCubeFace = function() {
            return b;
        }, this.getActiveMipmapLevel = function() {
            return w;
        }, this.getRenderTarget = function() {
            return R;
        }, this.setRenderTargetTextures = function(E, N, V) {
            me.get(E.texture).__webglTexture = N, me.get(E.depthTexture).__webglTexture = V;
            let F = me.get(E);
            F.__hasExternalTextures = !0, F.__hasExternalTextures && (F.__autoAllocateDepthBuffer = V === void 0, F.__autoAllocateDepthBuffer || X.has("WEBGL_multisampled_render_to_texture") === !0 && (console.warn("THREE.WebGLRenderer: Render-to-texture extension was disabled because an external texture was provided"), F.__useRenderToTexture = !1));
        }, this.setRenderTargetFramebuffer = function(E, N) {
            let V = me.get(E);
            V.__webglFramebuffer = N, V.__useDefaultFramebuffer = N === void 0;
        }, this.setRenderTarget = function(E, N = 0, V = 0) {
            R = E, b = N, w = V;
            let F = !0, k = null, xe = !1, Ae = !1;
            if (E) {
                let De = me.get(E);
                De.__useDefaultFramebuffer !== void 0 ? (J.bindFramebuffer(L.FRAMEBUFFER, null), F = !1) : De.__webglFramebuffer === void 0 ? ye.setupRenderTarget(E) : De.__hasExternalTextures && ye.rebindTextures(E, me.get(E.texture).__webglTexture, me.get(E.depthTexture).__webglTexture);
                let We = E.texture;
                (We.isData3DTexture || We.isDataArrayTexture || We.isCompressedArrayTexture) && (Ae = !0);
                let Pe = me.get(E).__webglFramebuffer;
                E.isWebGLCubeRenderTarget ? (Array.isArray(Pe[N]) ? k = Pe[N][V] : k = Pe[N], xe = !0) : ie.isWebGL2 && E.samples > 0 && ye.useMultisampledRTT(E) === !1 ? k = me.get(E).__webglMultisampledFramebuffer : Array.isArray(Pe) ? k = Pe[V] : k = Pe, T.copy(E.viewport), O.copy(E.scissor), Y = E.scissorTest;
            } else T.copy(K).multiplyScalar(H).floor(), O.copy(D).multiplyScalar(H).floor(), Y = G;
            if (J.bindFramebuffer(L.FRAMEBUFFER, k) && ie.drawBuffers && F && J.drawBuffers(E, k), J.viewport(T), J.scissor(O), J.setScissorTest(Y), xe) {
                let De = me.get(E.texture);
                L.framebufferTexture2D(L.FRAMEBUFFER, L.COLOR_ATTACHMENT0, L.TEXTURE_CUBE_MAP_POSITIVE_X + N, De.__webglTexture, V);
            } else if (Ae) {
                let De = me.get(E.texture), We = N || 0;
                L.framebufferTextureLayer(L.FRAMEBUFFER, L.COLOR_ATTACHMENT0, De.__webglTexture, V || 0, We);
            }
            I = -1;
        }, this.readRenderTargetPixels = function(E, N, V, F, k, xe, Ae) {
            if (!(E && E.isWebGLRenderTarget)) {
                console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");
                return;
            }
            let Ue = me.get(E).__webglFramebuffer;
            if (E.isWebGLCubeRenderTarget && Ae !== void 0 && (Ue = Ue[Ae]), Ue) {
                J.bindFramebuffer(L.FRAMEBUFFER, Ue);
                try {
                    let De = E.texture, We = De.format, Pe = De.type;
                    if (We !== Wt && $e.convert(We) !== L.getParameter(L.IMPLEMENTATION_COLOR_READ_FORMAT)) {
                        console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");
                        return;
                    }
                    let Ve = Pe === Ts && (X.has("EXT_color_buffer_half_float") || ie.isWebGL2 && X.has("EXT_color_buffer_float"));
                    if (Pe !== On && $e.convert(Pe) !== L.getParameter(L.IMPLEMENTATION_COLOR_READ_TYPE) && !(Pe === xn && (ie.isWebGL2 || X.has("OES_texture_float") || X.has("WEBGL_color_buffer_float"))) && !Ve) {
                        console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");
                        return;
                    }
                    N >= 0 && N <= E.width - F && V >= 0 && V <= E.height - k && L.readPixels(N, V, F, k, $e.convert(We), $e.convert(Pe), xe);
                } finally{
                    let De = R !== null ? me.get(R).__webglFramebuffer : null;
                    J.bindFramebuffer(L.FRAMEBUFFER, De);
                }
            }
        }, this.copyFramebufferToTexture = function(E, N, V = 0) {
            let F = Math.pow(2, -V), k = Math.floor(N.image.width * F), xe = Math.floor(N.image.height * F);
            ye.setTexture2D(N, 0), L.copyTexSubImage2D(L.TEXTURE_2D, V, 0, 0, E.x, E.y, k, xe), J.unbindTexture();
        }, this.copyTextureToTexture = function(E, N, V, F = 0) {
            let k = N.image.width, xe = N.image.height, Ae = $e.convert(V.format), Ue = $e.convert(V.type);
            ye.setTexture2D(V, 0), L.pixelStorei(L.UNPACK_FLIP_Y_WEBGL, V.flipY), L.pixelStorei(L.UNPACK_PREMULTIPLY_ALPHA_WEBGL, V.premultiplyAlpha), L.pixelStorei(L.UNPACK_ALIGNMENT, V.unpackAlignment), N.isDataTexture ? L.texSubImage2D(L.TEXTURE_2D, F, E.x, E.y, k, xe, Ae, Ue, N.image.data) : N.isCompressedTexture ? L.compressedTexSubImage2D(L.TEXTURE_2D, F, E.x, E.y, N.mipmaps[0].width, N.mipmaps[0].height, Ae, N.mipmaps[0].data) : L.texSubImage2D(L.TEXTURE_2D, F, E.x, E.y, Ae, Ue, N.image), F === 0 && V.generateMipmaps && L.generateMipmap(L.TEXTURE_2D), J.unbindTexture();
        }, this.copyTextureToTexture3D = function(E, N, V, F, k = 0) {
            if (x.isWebGL1Renderer) {
                console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: can only be used with WebGL2.");
                return;
            }
            let xe = E.max.x - E.min.x + 1, Ae = E.max.y - E.min.y + 1, Ue = E.max.z - E.min.z + 1, De = $e.convert(F.format), We = $e.convert(F.type), Pe;
            if (F.isData3DTexture) ye.setTexture3D(F, 0), Pe = L.TEXTURE_3D;
            else if (F.isDataArrayTexture) ye.setTexture2DArray(F, 0), Pe = L.TEXTURE_2D_ARRAY;
            else {
                console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: only supports THREE.DataTexture3D and THREE.DataTexture2DArray.");
                return;
            }
            L.pixelStorei(L.UNPACK_FLIP_Y_WEBGL, F.flipY), L.pixelStorei(L.UNPACK_PREMULTIPLY_ALPHA_WEBGL, F.premultiplyAlpha), L.pixelStorei(L.UNPACK_ALIGNMENT, F.unpackAlignment);
            let Ve = L.getParameter(L.UNPACK_ROW_LENGTH), at = L.getParameter(L.UNPACK_IMAGE_HEIGHT), lt = L.getParameter(L.UNPACK_SKIP_PIXELS), Ht = L.getParameter(L.UNPACK_SKIP_ROWS), an = L.getParameter(L.UNPACK_SKIP_IMAGES), ut = V.isCompressedTexture ? V.mipmaps[0] : V.image;
            L.pixelStorei(L.UNPACK_ROW_LENGTH, ut.width), L.pixelStorei(L.UNPACK_IMAGE_HEIGHT, ut.height), L.pixelStorei(L.UNPACK_SKIP_PIXELS, E.min.x), L.pixelStorei(L.UNPACK_SKIP_ROWS, E.min.y), L.pixelStorei(L.UNPACK_SKIP_IMAGES, E.min.z), V.isDataTexture || V.isData3DTexture ? L.texSubImage3D(Pe, k, N.x, N.y, N.z, xe, Ae, Ue, De, We, ut.data) : V.isCompressedArrayTexture ? (console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: untested support for compressed srcTexture."), L.compressedTexSubImage3D(Pe, k, N.x, N.y, N.z, xe, Ae, Ue, De, ut.data)) : L.texSubImage3D(Pe, k, N.x, N.y, N.z, xe, Ae, Ue, De, We, ut), L.pixelStorei(L.UNPACK_ROW_LENGTH, Ve), L.pixelStorei(L.UNPACK_IMAGE_HEIGHT, at), L.pixelStorei(L.UNPACK_SKIP_PIXELS, lt), L.pixelStorei(L.UNPACK_SKIP_ROWS, Ht), L.pixelStorei(L.UNPACK_SKIP_IMAGES, an), k === 0 && F.generateMipmaps && L.generateMipmap(Pe), J.unbindTexture();
        }, this.initTexture = function(E) {
            E.isCubeTexture ? ye.setTextureCube(E, 0) : E.isData3DTexture ? ye.setTexture3D(E, 0) : E.isDataArrayTexture || E.isCompressedArrayTexture ? ye.setTexture2DArray(E, 0) : ye.setTexture2D(E, 0), J.unbindTexture();
        }, this.resetState = function() {
            b = 0, w = 0, R = null, J.reset(), Oe.reset();
        }, typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe", {
            detail: this
        }));
    }
    get coordinateSystem() {
        return vn;
    }
    get outputColorSpace() {
        return this._outputColorSpace;
    }
    set outputColorSpace(e) {
        this._outputColorSpace = e;
        let t = this.getContext();
        t.drawingBufferColorSpace = e === qc ? "display-p3" : "srgb", t.unpackColorSpace = Qe.workingColorSpace === va ? "display-p3" : "srgb";
    }
    get physicallyCorrectLights() {
        return console.warn("THREE.WebGLRenderer: The property .physicallyCorrectLights has been removed. Set renderer.useLegacyLights instead."), !this.useLegacyLights;
    }
    set physicallyCorrectLights(e) {
        console.warn("THREE.WebGLRenderer: The property .physicallyCorrectLights has been removed. Set renderer.useLegacyLights instead."), this.useLegacyLights = !e;
    }
    get outputEncoding() {
        return console.warn("THREE.WebGLRenderer: Property .outputEncoding has been removed. Use .outputColorSpace instead."), this.outputColorSpace === vt ? ri : vd;
    }
    set outputEncoding(e) {
        console.warn("THREE.WebGLRenderer: Property .outputEncoding has been removed. Use .outputColorSpace instead."), this.outputColorSpace = e === ri ? vt : Mn;
    }
    get useLegacyLights() {
        return console.warn("THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733."), this._useLegacyLights;
    }
    set useLegacyLights(e) {
        console.warn("THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733."), this._useLegacyLights = e;
    }
}, Co = class extends Ro {
};
Co.prototype.isWebGL1Renderer = !0;
var Po = class s1 {
    constructor(e, t = 25e-5){
        this.isFogExp2 = !0, this.name = "", this.color = new pe(e), this.density = t;
    }
    clone() {
        return new s1(this.color, this.density);
    }
    toJSON() {
        return {
            type: "FogExp2",
            name: this.name,
            color: this.color.getHex(),
            density: this.density
        };
    }
}, Lo = class s1 {
    constructor(e, t = 1, n = 1e3){
        this.isFog = !0, this.name = "", this.color = new pe(e), this.near = t, this.far = n;
    }
    clone() {
        return new s1(this.color, this.near, this.far);
    }
    toJSON() {
        return {
            type: "Fog",
            name: this.name,
            color: this.color.getHex(),
            near: this.near,
            far: this.far
        };
    }
}, Io = class extends Je {
    constructor(){
        super(), this.isScene = !0, this.type = "Scene", this.background = null, this.environment = null, this.fog = null, this.backgroundBlurriness = 0, this.backgroundIntensity = 1, this.overrideMaterial = null, typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe", {
            detail: this
        }));
    }
    copy(e, t) {
        return super.copy(e, t), e.background !== null && (this.background = e.background.clone()), e.environment !== null && (this.environment = e.environment.clone()), e.fog !== null && (this.fog = e.fog.clone()), this.backgroundBlurriness = e.backgroundBlurriness, this.backgroundIntensity = e.backgroundIntensity, e.overrideMaterial !== null && (this.overrideMaterial = e.overrideMaterial.clone()), this.matrixAutoUpdate = e.matrixAutoUpdate, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return this.fog !== null && (t.object.fog = this.fog.toJSON()), this.backgroundBlurriness > 0 && (t.object.backgroundBlurriness = this.backgroundBlurriness), this.backgroundIntensity !== 1 && (t.object.backgroundIntensity = this.backgroundIntensity), t;
    }
}, Is = class {
    constructor(e, t){
        this.isInterleavedBuffer = !0, this.array = e, this.stride = t, this.count = e !== void 0 ? e.length / t : 0, this.usage = Hr, this.updateRange = {
            offset: 0,
            count: -1
        }, this.version = 0, this.uuid = kt();
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
        e.arrayBuffers === void 0 && (e.arrayBuffers = {}), this.array.buffer._uuid === void 0 && (this.array.buffer._uuid = kt()), e.arrayBuffers[this.array.buffer._uuid] === void 0 && (e.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0).buffer);
        let t = new this.array.constructor(e.arrayBuffers[this.array.buffer._uuid]), n = new this.constructor(t, this.stride);
        return n.setUsage(this.usage), n;
    }
    onUpload(e) {
        return this.onUploadCallback = e, this;
    }
    toJSON(e) {
        return e.arrayBuffers === void 0 && (e.arrayBuffers = {}), this.array.buffer._uuid === void 0 && (this.array.buffer._uuid = kt()), e.arrayBuffers[this.array.buffer._uuid] === void 0 && (e.arrayBuffers[this.array.buffer._uuid] = Array.from(new Uint32Array(this.array.buffer))), {
            uuid: this.uuid,
            buffer: this.array.buffer._uuid,
            type: this.array.constructor.name,
            stride: this.stride
        };
    }
}, Pt = new A, Qi = class s1 {
    constructor(e, t, n, i = !1){
        this.isInterleavedBufferAttribute = !0, this.name = "", this.data = e, this.itemSize = t, this.offset = n, this.normalized = i;
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
        for(let t = 0, n = this.data.count; t < n; t++)Pt.fromBufferAttribute(this, t), Pt.applyMatrix4(e), this.setXYZ(t, Pt.x, Pt.y, Pt.z);
        return this;
    }
    applyNormalMatrix(e) {
        for(let t = 0, n = this.count; t < n; t++)Pt.fromBufferAttribute(this, t), Pt.applyNormalMatrix(e), this.setXYZ(t, Pt.x, Pt.y, Pt.z);
        return this;
    }
    transformDirection(e) {
        for(let t = 0, n = this.count; t < n; t++)Pt.fromBufferAttribute(this, t), Pt.transformDirection(e), this.setXYZ(t, Pt.x, Pt.y, Pt.z);
        return this;
    }
    setX(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.data.array[e * this.data.stride + this.offset] = t, this;
    }
    setY(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.data.array[e * this.data.stride + this.offset + 1] = t, this;
    }
    setZ(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.data.array[e * this.data.stride + this.offset + 2] = t, this;
    }
    setW(e, t) {
        return this.normalized && (t = Be(t, this.array)), this.data.array[e * this.data.stride + this.offset + 3] = t, this;
    }
    getX(e) {
        let t = this.data.array[e * this.data.stride + this.offset];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    getY(e) {
        let t = this.data.array[e * this.data.stride + this.offset + 1];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    getZ(e) {
        let t = this.data.array[e * this.data.stride + this.offset + 2];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    getW(e) {
        let t = this.data.array[e * this.data.stride + this.offset + 3];
        return this.normalized && (t = Ot(t, this.array)), t;
    }
    setXY(e, t, n) {
        return e = e * this.data.stride + this.offset, this.normalized && (t = Be(t, this.array), n = Be(n, this.array)), this.data.array[e + 0] = t, this.data.array[e + 1] = n, this;
    }
    setXYZ(e, t, n, i) {
        return e = e * this.data.stride + this.offset, this.normalized && (t = Be(t, this.array), n = Be(n, this.array), i = Be(i, this.array)), this.data.array[e + 0] = t, this.data.array[e + 1] = n, this.data.array[e + 2] = i, this;
    }
    setXYZW(e, t, n, i, r) {
        return e = e * this.data.stride + this.offset, this.normalized && (t = Be(t, this.array), n = Be(n, this.array), i = Be(i, this.array), r = Be(r, this.array)), this.data.array[e + 0] = t, this.data.array[e + 1] = n, this.data.array[e + 2] = i, this.data.array[e + 3] = r, this;
    }
    clone(e) {
        if (e === void 0) {
            console.log("THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");
            let t = [];
            for(let n = 0; n < this.count; n++){
                let i = n * this.data.stride + this.offset;
                for(let r = 0; r < this.itemSize; r++)t.push(this.data.array[i + r]);
            }
            return new et(new this.array.constructor(t), this.itemSize, this.normalized);
        } else return e.interleavedBuffers === void 0 && (e.interleavedBuffers = {}), e.interleavedBuffers[this.data.uuid] === void 0 && (e.interleavedBuffers[this.data.uuid] = this.data.clone(e)), new s1(e.interleavedBuffers[this.data.uuid], this.itemSize, this.offset, this.normalized);
    }
    toJSON(e) {
        if (e === void 0) {
            console.log("THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");
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
}, ea = class extends bt {
    constructor(e){
        super(), this.isSpriteMaterial = !0, this.type = "SpriteMaterial", this.color = new pe(16777215), this.map = null, this.alphaMap = null, this.rotation = 0, this.sizeAttenuation = !0, this.transparent = !0, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.alphaMap = e.alphaMap, this.rotation = e.rotation, this.sizeAttenuation = e.sizeAttenuation, this.fog = e.fog, this;
    }
}, Ii, ds = new A, Ui = new A, Di = new A, Ni = new Z, fs = new Z, Cd = new ze, hr = new A, ps = new A, ur = new A, Lh = new Z, ja = new Z, Ih = new Z, Uo = class extends Je {
    constructor(e = new ea){
        if (super(), this.isSprite = !0, this.type = "Sprite", Ii === void 0) {
            Ii = new Ge;
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
            ]), n = new Is(t, 5);
            Ii.setIndex([
                0,
                1,
                2,
                0,
                2,
                3
            ]), Ii.setAttribute("position", new Qi(n, 3, 0, !1)), Ii.setAttribute("uv", new Qi(n, 2, 3, !1));
        }
        this.geometry = Ii, this.material = e, this.center = new Z(.5, .5);
    }
    raycast(e, t) {
        e.camera === null && console.error('THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.'), Ui.setFromMatrixScale(this.matrixWorld), Cd.copy(e.camera.matrixWorld), this.modelViewMatrix.multiplyMatrices(e.camera.matrixWorldInverse, this.matrixWorld), Di.setFromMatrixPosition(this.modelViewMatrix), e.camera.isPerspectiveCamera && this.material.sizeAttenuation === !1 && Ui.multiplyScalar(-Di.z);
        let n = this.material.rotation, i, r;
        n !== 0 && (r = Math.cos(n), i = Math.sin(n));
        let a = this.center;
        dr(hr.set(-.5, -.5, 0), Di, a, Ui, i, r), dr(ps.set(.5, -.5, 0), Di, a, Ui, i, r), dr(ur.set(.5, .5, 0), Di, a, Ui, i, r), Lh.set(0, 0), ja.set(1, 0), Ih.set(1, 1);
        let o = e.ray.intersectTriangle(hr, ps, ur, !1, ds);
        if (o === null && (dr(ps.set(-.5, .5, 0), Di, a, Ui, i, r), ja.set(0, 1), o = e.ray.intersectTriangle(hr, ur, ps, !1, ds), o === null)) return;
        let c = e.ray.origin.distanceTo(ds);
        c < e.near || c > e.far || t.push({
            distance: c,
            point: ds.clone(),
            uv: Un.getInterpolation(ds, hr, ps, ur, Lh, ja, Ih, new Z),
            face: null,
            object: this
        });
    }
    copy(e, t) {
        return super.copy(e, t), e.center !== void 0 && this.center.copy(e.center), this.material = e.material, this;
    }
};
function dr(s1, e, t, n, i, r) {
    Ni.subVectors(s1, t).addScalar(.5).multiply(n), i !== void 0 ? (fs.x = r * Ni.x - i * Ni.y, fs.y = i * Ni.x + r * Ni.y) : fs.copy(Ni), s1.copy(e), s1.x += fs.x, s1.y += fs.y, s1.applyMatrix4(Cd);
}
var fr = new A, Uh = new A, Do = class extends Je {
    constructor(){
        super(), this._currentLevel = 0, this.type = "LOD", Object.defineProperties(this, {
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
            this.addLevel(r.object.clone(), r.distance, r.hysteresis);
        }
        return this.autoUpdate = e.autoUpdate, this;
    }
    addLevel(e, t = 0, n = 0) {
        t = Math.abs(t);
        let i = this.levels, r;
        for(r = 0; r < i.length && !(t < i[r].distance); r++);
        return i.splice(r, 0, {
            distance: t,
            hysteresis: n,
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
            for(n = 1, i = t.length; n < i; n++){
                let r = t[n].distance;
                if (t[n].object.visible && (r -= r * t[n].hysteresis), e < r) break;
            }
            return t[n - 1].object;
        }
        return null;
    }
    raycast(e, t) {
        if (this.levels.length > 0) {
            fr.setFromMatrixPosition(this.matrixWorld);
            let i = e.ray.origin.distanceTo(fr);
            this.getObjectForDistance(i).raycast(e, t);
        }
    }
    update(e) {
        let t = this.levels;
        if (t.length > 1) {
            fr.setFromMatrixPosition(e.matrixWorld), Uh.setFromMatrixPosition(this.matrixWorld);
            let n = fr.distanceTo(Uh) / e.zoom;
            t[0].object.visible = !0;
            let i, r;
            for(i = 1, r = t.length; i < r; i++){
                let a = t[i].distance;
                if (t[i].object.visible && (a -= a * t[i].hysteresis), n >= a) t[i - 1].object.visible = !1, t[i].object.visible = !0;
                else break;
            }
            for(this._currentLevel = i - 1; i < r; i++)t[i].object.visible = !1;
        }
    }
    toJSON(e) {
        let t = super.toJSON(e);
        this.autoUpdate === !1 && (t.object.autoUpdate = !1), t.object.levels = [];
        let n = this.levels;
        for(let i = 0, r = n.length; i < r; i++){
            let a = n[i];
            t.object.levels.push({
                object: a.object.uuid,
                distance: a.distance,
                hysteresis: a.hysteresis
            });
        }
        return t;
    }
}, Dh = new A, Nh = new je, Oh = new je, W0 = new A, Fh = new ze, Oi = new A, eo = new Yt, Bh = new ze, to = new hi, No = class extends Mt {
    constructor(e, t){
        super(e, t), this.isSkinnedMesh = !0, this.type = "SkinnedMesh", this.bindMode = "attached", this.bindMatrix = new ze, this.bindMatrixInverse = new ze, this.boundingBox = null, this.boundingSphere = null;
    }
    computeBoundingBox() {
        let e = this.geometry;
        this.boundingBox === null && (this.boundingBox = new Qt), this.boundingBox.makeEmpty();
        let t = e.getAttribute("position");
        for(let n = 0; n < t.count; n++)Oi.fromBufferAttribute(t, n), this.applyBoneTransform(n, Oi), this.boundingBox.expandByPoint(Oi);
    }
    computeBoundingSphere() {
        let e = this.geometry;
        this.boundingSphere === null && (this.boundingSphere = new Yt), this.boundingSphere.makeEmpty();
        let t = e.getAttribute("position");
        for(let n = 0; n < t.count; n++)Oi.fromBufferAttribute(t, n), this.applyBoneTransform(n, Oi), this.boundingSphere.expandByPoint(Oi);
    }
    copy(e, t) {
        return super.copy(e, t), this.bindMode = e.bindMode, this.bindMatrix.copy(e.bindMatrix), this.bindMatrixInverse.copy(e.bindMatrixInverse), this.skeleton = e.skeleton, e.boundingBox !== null && (this.boundingBox = e.boundingBox.clone()), e.boundingSphere !== null && (this.boundingSphere = e.boundingSphere.clone()), this;
    }
    raycast(e, t) {
        let n = this.material, i = this.matrixWorld;
        n !== void 0 && (this.boundingSphere === null && this.computeBoundingSphere(), eo.copy(this.boundingSphere), eo.applyMatrix4(i), e.ray.intersectsSphere(eo) !== !1 && (Bh.copy(i).invert(), to.copy(e.ray).applyMatrix4(Bh), !(this.boundingBox !== null && to.intersectsBox(this.boundingBox) === !1) && this._computeIntersections(e, t, to)));
    }
    getVertexPosition(e, t) {
        return super.getVertexPosition(e, t), this.applyBoneTransform(e, t), t;
    }
    bind(e, t) {
        this.skeleton = e, t === void 0 && (this.updateMatrixWorld(!0), this.skeleton.calculateInverses(), t = this.matrixWorld), this.bindMatrix.copy(t), this.bindMatrixInverse.copy(t).invert();
    }
    pose() {
        this.skeleton.pose();
    }
    normalizeSkinWeights() {
        let e = new je, t = this.geometry.attributes.skinWeight;
        for(let n = 0, i = t.count; n < i; n++){
            e.fromBufferAttribute(t, n);
            let r = 1 / e.manhattanLength();
            r !== 1 / 0 ? e.multiplyScalar(r) : e.set(1, 0, 0, 0), t.setXYZW(n, e.x, e.y, e.z, e.w);
        }
    }
    updateMatrixWorld(e) {
        super.updateMatrixWorld(e), this.bindMode === "attached" ? this.bindMatrixInverse.copy(this.matrixWorld).invert() : this.bindMode === "detached" ? this.bindMatrixInverse.copy(this.bindMatrix).invert() : console.warn("THREE.SkinnedMesh: Unrecognized bindMode: " + this.bindMode);
    }
    applyBoneTransform(e, t) {
        let n = this.skeleton, i = this.geometry;
        Nh.fromBufferAttribute(i.attributes.skinIndex, e), Oh.fromBufferAttribute(i.attributes.skinWeight, e), Dh.copy(t).applyMatrix4(this.bindMatrix), t.set(0, 0, 0);
        for(let r = 0; r < 4; r++){
            let a = Oh.getComponent(r);
            if (a !== 0) {
                let o = Nh.getComponent(r);
                Fh.multiplyMatrices(n.bones[o].matrixWorld, n.boneInverses[o]), t.addScaledVector(W0.copy(Dh).applyMatrix4(Fh), a);
            }
        }
        return t.applyMatrix4(this.bindMatrixInverse);
    }
    boneTransform(e, t) {
        return console.warn("THREE.SkinnedMesh: .boneTransform() was renamed to .applyBoneTransform() in r151."), this.applyBoneTransform(e, t);
    }
}, ta = class extends Je {
    constructor(){
        super(), this.isBone = !0, this.type = "Bone";
    }
}, oi = class extends St {
    constructor(e = null, t = 1, n = 1, i, r, a, o, c, l = pt, h = pt, u, d){
        super(null, a, o, c, l, h, i, r, u, d), this.isDataTexture = !0, this.image = {
            data: e,
            width: t,
            height: n
        }, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
}, zh = new ze, X0 = new ze, Oo = class s1 {
    constructor(e = [], t = []){
        this.uuid = kt(), this.bones = e.slice(0), this.boneInverses = t, this.boneMatrices = null, this.boneTexture = null, this.boneTextureSize = 0, this.init();
    }
    init() {
        let e = this.bones, t = this.boneInverses;
        if (this.boneMatrices = new Float32Array(e.length * 16), t.length === 0) this.calculateInverses();
        else if (e.length !== t.length) {
            console.warn("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones."), this.boneInverses = [];
            for(let n = 0, i = this.bones.length; n < i; n++)this.boneInverses.push(new ze);
        }
    }
    calculateInverses() {
        this.boneInverses.length = 0;
        for(let e = 0, t = this.bones.length; e < t; e++){
            let n = new ze;
            this.bones[e] && n.copy(this.bones[e].matrixWorld).invert(), this.boneInverses.push(n);
        }
    }
    pose() {
        for(let e = 0, t = this.bones.length; e < t; e++){
            let n = this.bones[e];
            n && n.matrixWorld.copy(this.boneInverses[e]).invert();
        }
        for(let e = 0, t = this.bones.length; e < t; e++){
            let n = this.bones[e];
            n && (n.parent && n.parent.isBone ? (n.matrix.copy(n.parent.matrixWorld).invert(), n.matrix.multiply(n.matrixWorld)) : n.matrix.copy(n.matrixWorld), n.matrix.decompose(n.position, n.quaternion, n.scale));
        }
    }
    update() {
        let e = this.bones, t = this.boneInverses, n = this.boneMatrices, i = this.boneTexture;
        for(let r = 0, a = e.length; r < a; r++){
            let o = e[r] ? e[r].matrixWorld : X0;
            zh.multiplyMatrices(o, t[r]), zh.toArray(n, r * 16);
        }
        i !== null && (i.needsUpdate = !0);
    }
    clone() {
        return new s1(this.bones, this.boneInverses);
    }
    computeBoneTexture() {
        let e = Math.sqrt(this.bones.length * 4);
        e = yd(e), e = Math.max(e, 4);
        let t = new Float32Array(e * e * 4);
        t.set(this.boneMatrices);
        let n = new oi(t, e, e, Wt, xn);
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
            let r = e.bones[n], a = t[r];
            a === void 0 && (console.warn("THREE.Skeleton: No bone found with UUID:", r), a = new ta), this.bones.push(a), this.boneInverses.push(new ze().fromArray(e.boneInverses[n]));
        }
        return this.init(), this;
    }
    toJSON() {
        let e = {
            metadata: {
                version: 4.6,
                type: "Skeleton",
                generator: "Skeleton.toJSON"
            },
            bones: [],
            boneInverses: []
        };
        e.uuid = this.uuid;
        let t = this.bones, n = this.boneInverses;
        for(let i = 0, r = t.length; i < r; i++){
            let a = t[i];
            e.bones.push(a.uuid);
            let o = n[i];
            e.boneInverses.push(o.toArray());
        }
        return e;
    }
}, ui = class extends et {
    constructor(e, t, n, i = 1){
        super(e, t, n), this.isInstancedBufferAttribute = !0, this.meshPerAttribute = i;
    }
    copy(e) {
        return super.copy(e), this.meshPerAttribute = e.meshPerAttribute, this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.meshPerAttribute = this.meshPerAttribute, e.isInstancedBufferAttribute = !0, e;
    }
}, Fi = new ze, Vh = new ze, pr = [], kh = new Qt, q0 = new ze, ms = new Mt, gs = new Yt, Fo = class extends Mt {
    constructor(e, t, n){
        super(e, t), this.isInstancedMesh = !0, this.instanceMatrix = new ui(new Float32Array(n * 16), 16), this.instanceColor = null, this.count = n, this.boundingBox = null, this.boundingSphere = null;
        for(let i = 0; i < n; i++)this.setMatrixAt(i, q0);
    }
    computeBoundingBox() {
        let e = this.geometry, t = this.count;
        this.boundingBox === null && (this.boundingBox = new Qt), e.boundingBox === null && e.computeBoundingBox(), this.boundingBox.makeEmpty();
        for(let n = 0; n < t; n++)this.getMatrixAt(n, Fi), kh.copy(e.boundingBox).applyMatrix4(Fi), this.boundingBox.union(kh);
    }
    computeBoundingSphere() {
        let e = this.geometry, t = this.count;
        this.boundingSphere === null && (this.boundingSphere = new Yt), e.boundingSphere === null && e.computeBoundingSphere(), this.boundingSphere.makeEmpty();
        for(let n = 0; n < t; n++)this.getMatrixAt(n, Fi), gs.copy(e.boundingSphere).applyMatrix4(Fi), this.boundingSphere.union(gs);
    }
    copy(e, t) {
        return super.copy(e, t), this.instanceMatrix.copy(e.instanceMatrix), e.instanceColor !== null && (this.instanceColor = e.instanceColor.clone()), this.count = e.count, e.boundingBox !== null && (this.boundingBox = e.boundingBox.clone()), e.boundingSphere !== null && (this.boundingSphere = e.boundingSphere.clone()), this;
    }
    getColorAt(e, t) {
        t.fromArray(this.instanceColor.array, e * 3);
    }
    getMatrixAt(e, t) {
        t.fromArray(this.instanceMatrix.array, e * 16);
    }
    raycast(e, t) {
        let n = this.matrixWorld, i = this.count;
        if (ms.geometry = this.geometry, ms.material = this.material, ms.material !== void 0 && (this.boundingSphere === null && this.computeBoundingSphere(), gs.copy(this.boundingSphere), gs.applyMatrix4(n), e.ray.intersectsSphere(gs) !== !1)) for(let r = 0; r < i; r++){
            this.getMatrixAt(r, Fi), Vh.multiplyMatrices(n, Fi), ms.matrixWorld = Vh, ms.raycast(e, pr);
            for(let a = 0, o = pr.length; a < o; a++){
                let c = pr[a];
                c.instanceId = r, c.object = this, t.push(c);
            }
            pr.length = 0;
        }
    }
    setColorAt(e, t) {
        this.instanceColor === null && (this.instanceColor = new ui(new Float32Array(this.instanceMatrix.count * 3), 3)), t.toArray(this.instanceColor.array, e * 3);
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
}, wt = class extends bt {
    constructor(e){
        super(), this.isLineBasicMaterial = !0, this.type = "LineBasicMaterial", this.color = new pe(16777215), this.map = null, this.linewidth = 1, this.linecap = "round", this.linejoin = "round", this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.linewidth = e.linewidth, this.linecap = e.linecap, this.linejoin = e.linejoin, this.fog = e.fog, this;
    }
}, Hh = new A, Gh = new A, Wh = new ze, no = new hi, mr = new Yt, bn = class extends Je {
    constructor(e = new Ge, t = new wt){
        super(), this.isLine = !0, this.type = "Line", this.geometry = e, this.material = t, this.updateMorphTargets();
    }
    copy(e, t) {
        return super.copy(e, t), this.material = Array.isArray(e.material) ? e.material.slice() : e.material, this.geometry = e.geometry, this;
    }
    computeLineDistances() {
        let e = this.geometry;
        if (e.index === null) {
            let t = e.attributes.position, n = [
                0
            ];
            for(let i = 1, r = t.count; i < r; i++)Hh.fromBufferAttribute(t, i - 1), Gh.fromBufferAttribute(t, i), n[i] = n[i - 1], n[i] += Hh.distanceTo(Gh);
            e.setAttribute("lineDistance", new ve(n, 1));
        } else console.warn("THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        return this;
    }
    raycast(e, t) {
        let n = this.geometry, i = this.matrixWorld, r = e.params.Line.threshold, a = n.drawRange;
        if (n.boundingSphere === null && n.computeBoundingSphere(), mr.copy(n.boundingSphere), mr.applyMatrix4(i), mr.radius += r, e.ray.intersectsSphere(mr) === !1) return;
        Wh.copy(i).invert(), no.copy(e.ray).applyMatrix4(Wh);
        let o = r / ((this.scale.x + this.scale.y + this.scale.z) / 3), c = o * o, l = new A, h = new A, u = new A, d = new A, f = this.isLineSegments ? 2 : 1, m = n.index, g = n.attributes.position;
        if (m !== null) {
            let p = Math.max(0, a.start), v = Math.min(m.count, a.start + a.count);
            for(let x = p, y = v - 1; x < y; x += f){
                let b = m.getX(x), w = m.getX(x + 1);
                if (l.fromBufferAttribute(g, b), h.fromBufferAttribute(g, w), no.distanceSqToSegment(l, h, d, u) > c) continue;
                d.applyMatrix4(this.matrixWorld);
                let I = e.ray.origin.distanceTo(d);
                I < e.near || I > e.far || t.push({
                    distance: I,
                    point: u.clone().applyMatrix4(this.matrixWorld),
                    index: x,
                    face: null,
                    faceIndex: null,
                    object: this
                });
            }
        } else {
            let p = Math.max(0, a.start), v = Math.min(g.count, a.start + a.count);
            for(let x = p, y = v - 1; x < y; x += f){
                if (l.fromBufferAttribute(g, x), h.fromBufferAttribute(g, x + 1), no.distanceSqToSegment(l, h, d, u) > c) continue;
                d.applyMatrix4(this.matrixWorld);
                let w = e.ray.origin.distanceTo(d);
                w < e.near || w > e.far || t.push({
                    distance: w,
                    point: u.clone().applyMatrix4(this.matrixWorld),
                    index: x,
                    face: null,
                    faceIndex: null,
                    object: this
                });
            }
        }
    }
    updateMorphTargets() {
        let t = this.geometry.morphAttributes, n = Object.keys(t);
        if (n.length > 0) {
            let i = t[n[0]];
            if (i !== void 0) {
                this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                for(let r = 0, a = i.length; r < a; r++){
                    let o = i[r].name || String(r);
                    this.morphTargetInfluences.push(0), this.morphTargetDictionary[o] = r;
                }
            }
        }
    }
}, Xh = new A, qh = new A, en = class extends bn {
    constructor(e, t){
        super(e, t), this.isLineSegments = !0, this.type = "LineSegments";
    }
    computeLineDistances() {
        let e = this.geometry;
        if (e.index === null) {
            let t = e.attributes.position, n = [];
            for(let i = 0, r = t.count; i < r; i += 2)Xh.fromBufferAttribute(t, i), qh.fromBufferAttribute(t, i + 1), n[i] = i === 0 ? 0 : n[i - 1], n[i + 1] = n[i] + Xh.distanceTo(qh);
            e.setAttribute("lineDistance", new ve(n, 1));
        } else console.warn("THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        return this;
    }
}, Bo = class extends bn {
    constructor(e, t){
        super(e, t), this.isLineLoop = !0, this.type = "LineLoop";
    }
}, na = class extends bt {
    constructor(e){
        super(), this.isPointsMaterial = !0, this.type = "PointsMaterial", this.color = new pe(16777215), this.map = null, this.alphaMap = null, this.size = 1, this.sizeAttenuation = !0, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.alphaMap = e.alphaMap, this.size = e.size, this.sizeAttenuation = e.sizeAttenuation, this.fog = e.fog, this;
    }
}, Yh = new ze, zo = new hi, gr = new Yt, _r = new A, Vo = class extends Je {
    constructor(e = new Ge, t = new na){
        super(), this.isPoints = !0, this.type = "Points", this.geometry = e, this.material = t, this.updateMorphTargets();
    }
    copy(e, t) {
        return super.copy(e, t), this.material = Array.isArray(e.material) ? e.material.slice() : e.material, this.geometry = e.geometry, this;
    }
    raycast(e, t) {
        let n = this.geometry, i = this.matrixWorld, r = e.params.Points.threshold, a = n.drawRange;
        if (n.boundingSphere === null && n.computeBoundingSphere(), gr.copy(n.boundingSphere), gr.applyMatrix4(i), gr.radius += r, e.ray.intersectsSphere(gr) === !1) return;
        Yh.copy(i).invert(), zo.copy(e.ray).applyMatrix4(Yh);
        let o = r / ((this.scale.x + this.scale.y + this.scale.z) / 3), c = o * o, l = n.index, u = n.attributes.position;
        if (l !== null) {
            let d = Math.max(0, a.start), f = Math.min(l.count, a.start + a.count);
            for(let m = d, _ = f; m < _; m++){
                let g = l.getX(m);
                _r.fromBufferAttribute(u, g), Zh(_r, g, c, i, e, t, this);
            }
        } else {
            let d = Math.max(0, a.start), f = Math.min(u.count, a.start + a.count);
            for(let m = d, _ = f; m < _; m++)_r.fromBufferAttribute(u, m), Zh(_r, m, c, i, e, t, this);
        }
    }
    updateMorphTargets() {
        let t = this.geometry.morphAttributes, n = Object.keys(t);
        if (n.length > 0) {
            let i = t[n[0]];
            if (i !== void 0) {
                this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                for(let r = 0, a = i.length; r < a; r++){
                    let o = i[r].name || String(r);
                    this.morphTargetInfluences.push(0), this.morphTargetDictionary[o] = r;
                }
            }
        }
    }
};
function Zh(s1, e, t, n, i, r, a) {
    let o = zo.distanceSqToPoint(s1);
    if (o < t) {
        let c = new A;
        zo.closestPointToPoint(s1, c), c.applyMatrix4(n);
        let l = i.ray.origin.distanceTo(c);
        if (l < i.near || l > i.far) return;
        r.push({
            distance: l,
            distanceToRay: Math.sqrt(o),
            point: c,
            index: e,
            face: null,
            object: a
        });
    }
}
var Jh = class extends St {
    constructor(e, t, n, i, r, a, o, c, l){
        super(e, t, n, i, r, a, o, c, l), this.isVideoTexture = !0, this.minFilter = a !== void 0 ? a : mt, this.magFilter = r !== void 0 ? r : mt, this.generateMipmaps = !1;
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
}, $h = class extends St {
    constructor(e, t){
        super({
            width: e,
            height: t
        }), this.isFramebufferTexture = !0, this.magFilter = pt, this.minFilter = pt, this.generateMipmaps = !1, this.needsUpdate = !0;
    }
}, Us = class extends St {
    constructor(e, t, n, i, r, a, o, c, l, h, u, d){
        super(null, a, o, c, l, h, i, r, u, d), this.isCompressedTexture = !0, this.image = {
            width: t,
            height: n
        }, this.mipmaps = e, this.flipY = !1, this.generateMipmaps = !1;
    }
}, Kh = class extends Us {
    constructor(e, t, n, i, r, a){
        super(e, t, n, r, a), this.isCompressedArrayTexture = !0, this.image.depth = i, this.wrapR = It;
    }
}, Qh = class extends Us {
    constructor(e, t, n){
        super(void 0, e[0].width, e[0].height, t, n, zn), this.isCompressedCubeTexture = !0, this.isCubeTexture = !0, this.image = e;
    }
}, jh = class extends St {
    constructor(e, t, n, i, r, a, o, c, l){
        super(e, t, n, i, r, a, o, c, l), this.isCanvasTexture = !0, this.needsUpdate = !0;
    }
}, Zt = class {
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
        for(let a = 1; a <= e; a++)n = this.getPoint(a / e), r += n.distanceTo(i), t.push(r), i = n;
        return this.cacheArcLengths = t, t;
    }
    updateArcLengths() {
        this.needsUpdate = !0, this.getLengths();
    }
    getUtoTmapping(e, t) {
        let n = this.getLengths(), i = 0, r = n.length, a;
        t ? a = t : a = e * n[r - 1];
        let o = 0, c = r - 1, l;
        for(; o <= c;)if (i = Math.floor(o + (c - o) / 2), l = n[i] - a, l < 0) o = i + 1;
        else if (l > 0) c = i - 1;
        else {
            c = i;
            break;
        }
        if (i = c, n[i] === a) return i / (r - 1);
        let h = n[i], d = n[i + 1] - h, f = (a - h) / d;
        return (i + f) / (r - 1);
    }
    getTangent(e, t) {
        let i = e - 1e-4, r = e + 1e-4;
        i < 0 && (i = 0), r > 1 && (r = 1);
        let a = this.getPoint(i), o = this.getPoint(r), c = t || (a.isVector2 ? new Z : new A);
        return c.copy(o).sub(a).normalize(), c;
    }
    getTangentAt(e, t) {
        let n = this.getUtoTmapping(e);
        return this.getTangent(n, t);
    }
    computeFrenetFrames(e, t) {
        let n = new A, i = [], r = [], a = [], o = new A, c = new ze;
        for(let f = 0; f <= e; f++){
            let m = f / e;
            i[f] = this.getTangentAt(m, new A);
        }
        r[0] = new A, a[0] = new A;
        let l = Number.MAX_VALUE, h = Math.abs(i[0].x), u = Math.abs(i[0].y), d = Math.abs(i[0].z);
        h <= l && (l = h, n.set(1, 0, 0)), u <= l && (l = u, n.set(0, 1, 0)), d <= l && n.set(0, 0, 1), o.crossVectors(i[0], n).normalize(), r[0].crossVectors(i[0], o), a[0].crossVectors(i[0], r[0]);
        for(let f = 1; f <= e; f++){
            if (r[f] = r[f - 1].clone(), a[f] = a[f - 1].clone(), o.crossVectors(i[f - 1], i[f]), o.length() > Number.EPSILON) {
                o.normalize();
                let m = Math.acos(ct(i[f - 1].dot(i[f]), -1, 1));
                r[f].applyMatrix4(c.makeRotationAxis(o, m));
            }
            a[f].crossVectors(i[f], r[f]);
        }
        if (t === !0) {
            let f = Math.acos(ct(r[0].dot(r[e]), -1, 1));
            f /= e, i[0].dot(o.crossVectors(r[0], r[e])) > 0 && (f = -f);
            for(let m = 1; m <= e; m++)r[m].applyMatrix4(c.makeRotationAxis(i[m], f * m)), a[m].crossVectors(i[m], r[m]);
        }
        return {
            tangents: i,
            normals: r,
            binormals: a
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
                version: 4.6,
                type: "Curve",
                generator: "Curve.toJSON"
            }
        };
        return e.arcLengthDivisions = this.arcLengthDivisions, e.type = this.type, e;
    }
    fromJSON(e) {
        return this.arcLengthDivisions = e.arcLengthDivisions, this;
    }
}, Ds = class extends Zt {
    constructor(e = 0, t = 0, n = 1, i = 1, r = 0, a = Math.PI * 2, o = !1, c = 0){
        super(), this.isEllipseCurve = !0, this.type = "EllipseCurve", this.aX = e, this.aY = t, this.xRadius = n, this.yRadius = i, this.aStartAngle = r, this.aEndAngle = a, this.aClockwise = o, this.aRotation = c;
    }
    getPoint(e, t) {
        let n = t || new Z, i = Math.PI * 2, r = this.aEndAngle - this.aStartAngle, a = Math.abs(r) < Number.EPSILON;
        for(; r < 0;)r += i;
        for(; r > i;)r -= i;
        r < Number.EPSILON && (a ? r = 0 : r = i), this.aClockwise === !0 && !a && (r === i ? r = -i : r = r - i);
        let o = this.aStartAngle + e * r, c = this.aX + this.xRadius * Math.cos(o), l = this.aY + this.yRadius * Math.sin(o);
        if (this.aRotation !== 0) {
            let h = Math.cos(this.aRotation), u = Math.sin(this.aRotation), d = c - this.aX, f = l - this.aY;
            c = d * h - f * u + this.aX, l = d * u + f * h + this.aY;
        }
        return n.set(c, l);
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
}, ko = class extends Ds {
    constructor(e, t, n, i, r, a){
        super(e, t, n, n, i, r, a), this.isArcCurve = !0, this.type = "ArcCurve";
    }
};
function Jc() {
    let s1 = 0, e = 0, t = 0, n = 0;
    function i(r, a, o, c) {
        s1 = r, e = o, t = -3 * r + 3 * a - 2 * o - c, n = 2 * r - 2 * a + o + c;
    }
    return {
        initCatmullRom: function(r, a, o, c, l) {
            i(a, o, l * (o - r), l * (c - a));
        },
        initNonuniformCatmullRom: function(r, a, o, c, l, h, u) {
            let d = (a - r) / l - (o - r) / (l + h) + (o - a) / h, f = (o - a) / h - (c - a) / (h + u) + (c - o) / u;
            d *= h, f *= h, i(a, o, d, f);
        },
        calc: function(r) {
            let a = r * r, o = a * r;
            return s1 + e * r + t * a + n * o;
        }
    };
}
var xr = new A, io = new Jc, so = new Jc, ro = new Jc, Ho = class extends Zt {
    constructor(e = [], t = !1, n = "centripetal", i = .5){
        super(), this.isCatmullRomCurve3 = !0, this.type = "CatmullRomCurve3", this.points = e, this.closed = t, this.curveType = n, this.tension = i;
    }
    getPoint(e, t = new A) {
        let n = t, i = this.points, r = i.length, a = (r - (this.closed ? 0 : 1)) * e, o = Math.floor(a), c = a - o;
        this.closed ? o += o > 0 ? 0 : (Math.floor(Math.abs(o) / r) + 1) * r : c === 0 && o === r - 1 && (o = r - 2, c = 1);
        let l, h;
        this.closed || o > 0 ? l = i[(o - 1) % r] : (xr.subVectors(i[0], i[1]).add(i[0]), l = xr);
        let u = i[o % r], d = i[(o + 1) % r];
        if (this.closed || o + 2 < r ? h = i[(o + 2) % r] : (xr.subVectors(i[r - 1], i[r - 2]).add(i[r - 1]), h = xr), this.curveType === "centripetal" || this.curveType === "chordal") {
            let f = this.curveType === "chordal" ? .5 : .25, m = Math.pow(l.distanceToSquared(u), f), _ = Math.pow(u.distanceToSquared(d), f), g = Math.pow(d.distanceToSquared(h), f);
            _ < 1e-4 && (_ = 1), m < 1e-4 && (m = _), g < 1e-4 && (g = _), io.initNonuniformCatmullRom(l.x, u.x, d.x, h.x, m, _, g), so.initNonuniformCatmullRom(l.y, u.y, d.y, h.y, m, _, g), ro.initNonuniformCatmullRom(l.z, u.z, d.z, h.z, m, _, g);
        } else this.curveType === "catmullrom" && (io.initCatmullRom(l.x, u.x, d.x, h.x, this.tension), so.initCatmullRom(l.y, u.y, d.y, h.y, this.tension), ro.initCatmullRom(l.z, u.z, d.z, h.z, this.tension));
        return n.set(io.calc(c), so.calc(c), ro.calc(c)), n;
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
            this.points.push(new A().fromArray(i));
        }
        return this.closed = e.closed, this.curveType = e.curveType, this.tension = e.tension, this;
    }
};
function eu(s1, e, t, n, i) {
    let r = (n - e) * .5, a = (i - t) * .5, o = s1 * s1, c = s1 * o;
    return (2 * t - 2 * n + r + a) * c + (-3 * t + 3 * n - 2 * r - a) * o + r * s1 + t;
}
function Y0(s1, e) {
    let t = 1 - s1;
    return t * t * e;
}
function Z0(s1, e) {
    return 2 * (1 - s1) * s1 * e;
}
function J0(s1, e) {
    return s1 * s1 * e;
}
function bs(s1, e, t, n) {
    return Y0(s1, e) + Z0(s1, t) + J0(s1, n);
}
function $0(s1, e) {
    let t = 1 - s1;
    return t * t * t * e;
}
function K0(s1, e) {
    let t = 1 - s1;
    return 3 * t * t * s1 * e;
}
function Q0(s1, e) {
    return 3 * (1 - s1) * s1 * s1 * e;
}
function j0(s1, e) {
    return s1 * s1 * s1 * e;
}
function Es(s1, e, t, n, i) {
    return $0(s1, e) + K0(s1, t) + Q0(s1, n) + j0(s1, i);
}
var ia = class extends Zt {
    constructor(e = new Z, t = new Z, n = new Z, i = new Z){
        super(), this.isCubicBezierCurve = !0, this.type = "CubicBezierCurve", this.v0 = e, this.v1 = t, this.v2 = n, this.v3 = i;
    }
    getPoint(e, t = new Z) {
        let n = t, i = this.v0, r = this.v1, a = this.v2, o = this.v3;
        return n.set(Es(e, i.x, r.x, a.x, o.x), Es(e, i.y, r.y, a.y, o.y)), n;
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
}, Go = class extends Zt {
    constructor(e = new A, t = new A, n = new A, i = new A){
        super(), this.isCubicBezierCurve3 = !0, this.type = "CubicBezierCurve3", this.v0 = e, this.v1 = t, this.v2 = n, this.v3 = i;
    }
    getPoint(e, t = new A) {
        let n = t, i = this.v0, r = this.v1, a = this.v2, o = this.v3;
        return n.set(Es(e, i.x, r.x, a.x, o.x), Es(e, i.y, r.y, a.y, o.y), Es(e, i.z, r.z, a.z, o.z)), n;
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
}, sa = class extends Zt {
    constructor(e = new Z, t = new Z){
        super(), this.isLineCurve = !0, this.type = "LineCurve", this.v1 = e, this.v2 = t;
    }
    getPoint(e, t = new Z) {
        let n = t;
        return e === 1 ? n.copy(this.v2) : (n.copy(this.v2).sub(this.v1), n.multiplyScalar(e).add(this.v1)), n;
    }
    getPointAt(e, t) {
        return this.getPoint(e, t);
    }
    getTangent(e, t = new Z) {
        return t.subVectors(this.v2, this.v1).normalize();
    }
    getTangentAt(e, t) {
        return this.getTangent(e, t);
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
}, Wo = class extends Zt {
    constructor(e = new A, t = new A){
        super(), this.isLineCurve3 = !0, this.type = "LineCurve3", this.v1 = e, this.v2 = t;
    }
    getPoint(e, t = new A) {
        let n = t;
        return e === 1 ? n.copy(this.v2) : (n.copy(this.v2).sub(this.v1), n.multiplyScalar(e).add(this.v1)), n;
    }
    getPointAt(e, t) {
        return this.getPoint(e, t);
    }
    getTangent(e, t = new A) {
        return t.subVectors(this.v2, this.v1).normalize();
    }
    getTangentAt(e, t) {
        return this.getTangent(e, t);
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
}, ra = class extends Zt {
    constructor(e = new Z, t = new Z, n = new Z){
        super(), this.isQuadraticBezierCurve = !0, this.type = "QuadraticBezierCurve", this.v0 = e, this.v1 = t, this.v2 = n;
    }
    getPoint(e, t = new Z) {
        let n = t, i = this.v0, r = this.v1, a = this.v2;
        return n.set(bs(e, i.x, r.x, a.x), bs(e, i.y, r.y, a.y)), n;
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
}, aa = class extends Zt {
    constructor(e = new A, t = new A, n = new A){
        super(), this.isQuadraticBezierCurve3 = !0, this.type = "QuadraticBezierCurve3", this.v0 = e, this.v1 = t, this.v2 = n;
    }
    getPoint(e, t = new A) {
        let n = t, i = this.v0, r = this.v1, a = this.v2;
        return n.set(bs(e, i.x, r.x, a.x), bs(e, i.y, r.y, a.y), bs(e, i.z, r.z, a.z)), n;
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
}, oa = class extends Zt {
    constructor(e = []){
        super(), this.isSplineCurve = !0, this.type = "SplineCurve", this.points = e;
    }
    getPoint(e, t = new Z) {
        let n = t, i = this.points, r = (i.length - 1) * e, a = Math.floor(r), o = r - a, c = i[a === 0 ? a : a - 1], l = i[a], h = i[a > i.length - 2 ? i.length - 1 : a + 1], u = i[a > i.length - 3 ? i.length - 1 : a + 2];
        return n.set(eu(o, c.x, l.x, h.x, u.x), eu(o, c.y, l.y, h.y, u.y)), n;
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
            this.points.push(new Z().fromArray(i));
        }
        return this;
    }
}, ca = Object.freeze({
    __proto__: null,
    ArcCurve: ko,
    CatmullRomCurve3: Ho,
    CubicBezierCurve: ia,
    CubicBezierCurve3: Go,
    EllipseCurve: Ds,
    LineCurve: sa,
    LineCurve3: Wo,
    QuadraticBezierCurve: ra,
    QuadraticBezierCurve3: aa,
    SplineCurve: oa
}), Xo = class extends Zt {
    constructor(){
        super(), this.type = "CurvePath", this.curves = [], this.autoClose = !1;
    }
    add(e) {
        this.curves.push(e);
    }
    closePath() {
        let e = this.curves[0].getPoint(0), t = this.curves[this.curves.length - 1].getPoint(1);
        if (!e.equals(t)) {
            let n = e.isVector2 === !0 ? "LineCurve" : "LineCurve3";
            this.curves.push(new ca[n](t, e));
        }
        return this;
    }
    getPoint(e, t) {
        let n = e * this.getLength(), i = this.getCurveLengths(), r = 0;
        for(; r < i.length;){
            if (i[r] >= n) {
                let a = i[r] - n, o = this.curves[r], c = o.getLength(), l = c === 0 ? 0 : 1 - a / c;
                return o.getPointAt(l, t);
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
            let a = r[i], o = a.isEllipseCurve ? e * 2 : a.isLineCurve || a.isLineCurve3 ? 1 : a.isSplineCurve ? e * a.points.length : e, c = a.getPoints(o);
            for(let l = 0; l < c.length; l++){
                let h = c[l];
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
            this.curves.push(new ca[i.type]().fromJSON(i));
        }
        return this;
    }
}, ji = class extends Xo {
    constructor(e){
        super(), this.type = "Path", this.currentPoint = new Z, e && this.setFromPoints(e);
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
        let n = new sa(this.currentPoint.clone(), new Z(e, t));
        return this.curves.push(n), this.currentPoint.set(e, t), this;
    }
    quadraticCurveTo(e, t, n, i) {
        let r = new ra(this.currentPoint.clone(), new Z(e, t), new Z(n, i));
        return this.curves.push(r), this.currentPoint.set(n, i), this;
    }
    bezierCurveTo(e, t, n, i, r, a) {
        let o = new ia(this.currentPoint.clone(), new Z(e, t), new Z(n, i), new Z(r, a));
        return this.curves.push(o), this.currentPoint.set(r, a), this;
    }
    splineThru(e) {
        let t = [
            this.currentPoint.clone()
        ].concat(e), n = new oa(t);
        return this.curves.push(n), this.currentPoint.copy(e[e.length - 1]), this;
    }
    arc(e, t, n, i, r, a) {
        let o = this.currentPoint.x, c = this.currentPoint.y;
        return this.absarc(e + o, t + c, n, i, r, a), this;
    }
    absarc(e, t, n, i, r, a) {
        return this.absellipse(e, t, n, n, i, r, a), this;
    }
    ellipse(e, t, n, i, r, a, o, c) {
        let l = this.currentPoint.x, h = this.currentPoint.y;
        return this.absellipse(e + l, t + h, n, i, r, a, o, c), this;
    }
    absellipse(e, t, n, i, r, a, o, c) {
        let l = new Ds(e, t, n, i, r, a, o, c);
        if (this.curves.length > 0) {
            let u = l.getPoint(0);
            u.equals(this.currentPoint) || this.lineTo(u.x, u.y);
        }
        this.curves.push(l);
        let h = l.getPoint(1);
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
}, la = class s1 extends Ge {
    constructor(e = [
        new Z(0, -.5),
        new Z(.5, 0),
        new Z(0, .5)
    ], t = 12, n = 0, i = Math.PI * 2){
        super(), this.type = "LatheGeometry", this.parameters = {
            points: e,
            segments: t,
            phiStart: n,
            phiLength: i
        }, t = Math.floor(t), i = ct(i, 0, Math.PI * 2);
        let r = [], a = [], o = [], c = [], l = [], h = 1 / t, u = new A, d = new Z, f = new A, m = new A, _ = new A, g = 0, p = 0;
        for(let v = 0; v <= e.length - 1; v++)switch(v){
            case 0:
                g = e[v + 1].x - e[v].x, p = e[v + 1].y - e[v].y, f.x = p * 1, f.y = -g, f.z = p * 0, _.copy(f), f.normalize(), c.push(f.x, f.y, f.z);
                break;
            case e.length - 1:
                c.push(_.x, _.y, _.z);
                break;
            default:
                g = e[v + 1].x - e[v].x, p = e[v + 1].y - e[v].y, f.x = p * 1, f.y = -g, f.z = p * 0, m.copy(f), f.x += _.x, f.y += _.y, f.z += _.z, f.normalize(), c.push(f.x, f.y, f.z), _.copy(m);
        }
        for(let v = 0; v <= t; v++){
            let x = n + v * h * i, y = Math.sin(x), b = Math.cos(x);
            for(let w = 0; w <= e.length - 1; w++){
                u.x = e[w].x * y, u.y = e[w].y, u.z = e[w].x * b, a.push(u.x, u.y, u.z), d.x = v / t, d.y = w / (e.length - 1), o.push(d.x, d.y);
                let R = c[3 * w + 0] * y, I = c[3 * w + 1], M = c[3 * w + 0] * b;
                l.push(R, I, M);
            }
        }
        for(let v = 0; v < t; v++)for(let x = 0; x < e.length - 1; x++){
            let y = x + v * e.length, b = y, w = y + e.length, R = y + e.length + 1, I = y + 1;
            r.push(b, w, I), r.push(R, I, w);
        }
        this.setIndex(r), this.setAttribute("position", new ve(a, 3)), this.setAttribute("uv", new ve(o, 2)), this.setAttribute("normal", new ve(l, 3));
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.points, e.segments, e.phiStart, e.phiLength);
    }
}, qo = class s1 extends la {
    constructor(e = 1, t = 1, n = 4, i = 8){
        let r = new ji;
        r.absarc(0, -t / 2, e, Math.PI * 1.5, 0), r.absarc(0, t / 2, e, 0, Math.PI * .5), super(r.getPoints(n), i), this.type = "CapsuleGeometry", this.parameters = {
            radius: e,
            length: t,
            capSegments: n,
            radialSegments: i
        };
    }
    static fromJSON(e) {
        return new s1(e.radius, e.length, e.capSegments, e.radialSegments);
    }
}, Yo = class s1 extends Ge {
    constructor(e = 1, t = 32, n = 0, i = Math.PI * 2){
        super(), this.type = "CircleGeometry", this.parameters = {
            radius: e,
            segments: t,
            thetaStart: n,
            thetaLength: i
        }, t = Math.max(3, t);
        let r = [], a = [], o = [], c = [], l = new A, h = new Z;
        a.push(0, 0, 0), o.push(0, 0, 1), c.push(.5, .5);
        for(let u = 0, d = 3; u <= t; u++, d += 3){
            let f = n + u / t * i;
            l.x = e * Math.cos(f), l.y = e * Math.sin(f), a.push(l.x, l.y, l.z), o.push(0, 0, 1), h.x = (a[d] / e + 1) / 2, h.y = (a[d + 1] / e + 1) / 2, c.push(h.x, h.y);
        }
        for(let u = 1; u <= t; u++)r.push(u, u + 1, 0);
        this.setIndex(r), this.setAttribute("position", new ve(a, 3)), this.setAttribute("normal", new ve(o, 3)), this.setAttribute("uv", new ve(c, 2));
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.radius, e.segments, e.thetaStart, e.thetaLength);
    }
}, Ns = class s1 extends Ge {
    constructor(e = 1, t = 1, n = 1, i = 32, r = 1, a = !1, o = 0, c = Math.PI * 2){
        super(), this.type = "CylinderGeometry", this.parameters = {
            radiusTop: e,
            radiusBottom: t,
            height: n,
            radialSegments: i,
            heightSegments: r,
            openEnded: a,
            thetaStart: o,
            thetaLength: c
        };
        let l = this;
        i = Math.floor(i), r = Math.floor(r);
        let h = [], u = [], d = [], f = [], m = 0, _ = [], g = n / 2, p = 0;
        v(), a === !1 && (e > 0 && x(!0), t > 0 && x(!1)), this.setIndex(h), this.setAttribute("position", new ve(u, 3)), this.setAttribute("normal", new ve(d, 3)), this.setAttribute("uv", new ve(f, 2));
        function v() {
            let y = new A, b = new A, w = 0, R = (t - e) / n;
            for(let I = 0; I <= r; I++){
                let M = [], T = I / r, O = T * (t - e) + e;
                for(let Y = 0; Y <= i; Y++){
                    let $ = Y / i, U = $ * c + o, z = Math.sin(U), q = Math.cos(U);
                    b.x = O * z, b.y = -T * n + g, b.z = O * q, u.push(b.x, b.y, b.z), y.set(z, R, q).normalize(), d.push(y.x, y.y, y.z), f.push($, 1 - T), M.push(m++);
                }
                _.push(M);
            }
            for(let I = 0; I < i; I++)for(let M = 0; M < r; M++){
                let T = _[M][I], O = _[M + 1][I], Y = _[M + 1][I + 1], $ = _[M][I + 1];
                h.push(T, O, $), h.push(O, Y, $), w += 6;
            }
            l.addGroup(p, w, 0), p += w;
        }
        function x(y) {
            let b = m, w = new Z, R = new A, I = 0, M = y === !0 ? e : t, T = y === !0 ? 1 : -1;
            for(let Y = 1; Y <= i; Y++)u.push(0, g * T, 0), d.push(0, T, 0), f.push(.5, .5), m++;
            let O = m;
            for(let Y = 0; Y <= i; Y++){
                let U = Y / i * c + o, z = Math.cos(U), q = Math.sin(U);
                R.x = M * q, R.y = g * T, R.z = M * z, u.push(R.x, R.y, R.z), d.push(0, T, 0), w.x = z * .5 + .5, w.y = q * .5 * T + .5, f.push(w.x, w.y), m++;
            }
            for(let Y = 0; Y < i; Y++){
                let $ = b + Y, U = O + Y;
                y === !0 ? h.push(U, U + 1, $) : h.push(U + 1, U, $), I += 3;
            }
            l.addGroup(p, I, y === !0 ? 1 : 2), p += I;
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.radiusTop, e.radiusBottom, e.height, e.radialSegments, e.heightSegments, e.openEnded, e.thetaStart, e.thetaLength);
    }
}, Zo = class s1 extends Ns {
    constructor(e = 1, t = 1, n = 32, i = 1, r = !1, a = 0, o = Math.PI * 2){
        super(0, e, t, n, i, r, a, o), this.type = "ConeGeometry", this.parameters = {
            radius: e,
            height: t,
            radialSegments: n,
            heightSegments: i,
            openEnded: r,
            thetaStart: a,
            thetaLength: o
        };
    }
    static fromJSON(e) {
        return new s1(e.radius, e.height, e.radialSegments, e.heightSegments, e.openEnded, e.thetaStart, e.thetaLength);
    }
}, di = class s1 extends Ge {
    constructor(e = [], t = [], n = 1, i = 0){
        super(), this.type = "PolyhedronGeometry", this.parameters = {
            vertices: e,
            indices: t,
            radius: n,
            detail: i
        };
        let r = [], a = [];
        o(i), l(n), h(), this.setAttribute("position", new ve(r, 3)), this.setAttribute("normal", new ve(r.slice(), 3)), this.setAttribute("uv", new ve(a, 2)), i === 0 ? this.computeVertexNormals() : this.normalizeNormals();
        function o(v) {
            let x = new A, y = new A, b = new A;
            for(let w = 0; w < t.length; w += 3)f(t[w + 0], x), f(t[w + 1], y), f(t[w + 2], b), c(x, y, b, v);
        }
        function c(v, x, y, b) {
            let w = b + 1, R = [];
            for(let I = 0; I <= w; I++){
                R[I] = [];
                let M = v.clone().lerp(y, I / w), T = x.clone().lerp(y, I / w), O = w - I;
                for(let Y = 0; Y <= O; Y++)Y === 0 && I === w ? R[I][Y] = M : R[I][Y] = M.clone().lerp(T, Y / O);
            }
            for(let I = 0; I < w; I++)for(let M = 0; M < 2 * (w - I) - 1; M++){
                let T = Math.floor(M / 2);
                M % 2 === 0 ? (d(R[I][T + 1]), d(R[I + 1][T]), d(R[I][T])) : (d(R[I][T + 1]), d(R[I + 1][T + 1]), d(R[I + 1][T]));
            }
        }
        function l(v) {
            let x = new A;
            for(let y = 0; y < r.length; y += 3)x.x = r[y + 0], x.y = r[y + 1], x.z = r[y + 2], x.normalize().multiplyScalar(v), r[y + 0] = x.x, r[y + 1] = x.y, r[y + 2] = x.z;
        }
        function h() {
            let v = new A;
            for(let x = 0; x < r.length; x += 3){
                v.x = r[x + 0], v.y = r[x + 1], v.z = r[x + 2];
                let y = g(v) / 2 / Math.PI + .5, b = p(v) / Math.PI + .5;
                a.push(y, 1 - b);
            }
            m(), u();
        }
        function u() {
            for(let v = 0; v < a.length; v += 6){
                let x = a[v + 0], y = a[v + 2], b = a[v + 4], w = Math.max(x, y, b), R = Math.min(x, y, b);
                w > .9 && R < .1 && (x < .2 && (a[v + 0] += 1), y < .2 && (a[v + 2] += 1), b < .2 && (a[v + 4] += 1));
            }
        }
        function d(v) {
            r.push(v.x, v.y, v.z);
        }
        function f(v, x) {
            let y = v * 3;
            x.x = e[y + 0], x.y = e[y + 1], x.z = e[y + 2];
        }
        function m() {
            let v = new A, x = new A, y = new A, b = new A, w = new Z, R = new Z, I = new Z;
            for(let M = 0, T = 0; M < r.length; M += 9, T += 6){
                v.set(r[M + 0], r[M + 1], r[M + 2]), x.set(r[M + 3], r[M + 4], r[M + 5]), y.set(r[M + 6], r[M + 7], r[M + 8]), w.set(a[T + 0], a[T + 1]), R.set(a[T + 2], a[T + 3]), I.set(a[T + 4], a[T + 5]), b.copy(v).add(x).add(y).divideScalar(3);
                let O = g(b);
                _(w, T + 0, v, O), _(R, T + 2, x, O), _(I, T + 4, y, O);
            }
        }
        function _(v, x, y, b) {
            b < 0 && v.x === 1 && (a[x] = v.x - 1), y.x === 0 && y.z === 0 && (a[x] = b / 2 / Math.PI + .5);
        }
        function g(v) {
            return Math.atan2(v.z, -v.x);
        }
        function p(v) {
            return Math.atan2(-v.y, Math.sqrt(v.x * v.x + v.z * v.z));
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.vertices, e.indices, e.radius, e.details);
    }
}, Jo = class s1 extends di {
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
        ], a = [
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
        super(r, a, e, t), this.type = "DodecahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new s1(e.radius, e.detail);
    }
}, vr = new A, yr = new A, ao = new A, Mr = new Un, $o = class extends Ge {
    constructor(e = null, t = 1){
        if (super(), this.type = "EdgesGeometry", this.parameters = {
            geometry: e,
            thresholdAngle: t
        }, e !== null) {
            let i = Math.pow(10, 4), r = Math.cos(ai * t), a = e.getIndex(), o = e.getAttribute("position"), c = a ? a.count : o.count, l = [
                0,
                0,
                0
            ], h = [
                "a",
                "b",
                "c"
            ], u = new Array(3), d = {}, f = [];
            for(let m = 0; m < c; m += 3){
                a ? (l[0] = a.getX(m), l[1] = a.getX(m + 1), l[2] = a.getX(m + 2)) : (l[0] = m, l[1] = m + 1, l[2] = m + 2);
                let { a: _ , b: g , c: p  } = Mr;
                if (_.fromBufferAttribute(o, l[0]), g.fromBufferAttribute(o, l[1]), p.fromBufferAttribute(o, l[2]), Mr.getNormal(ao), u[0] = `${Math.round(_.x * i)},${Math.round(_.y * i)},${Math.round(_.z * i)}`, u[1] = `${Math.round(g.x * i)},${Math.round(g.y * i)},${Math.round(g.z * i)}`, u[2] = `${Math.round(p.x * i)},${Math.round(p.y * i)},${Math.round(p.z * i)}`, !(u[0] === u[1] || u[1] === u[2] || u[2] === u[0])) for(let v = 0; v < 3; v++){
                    let x = (v + 1) % 3, y = u[v], b = u[x], w = Mr[h[v]], R = Mr[h[x]], I = `${y}_${b}`, M = `${b}_${y}`;
                    M in d && d[M] ? (ao.dot(d[M].normal) <= r && (f.push(w.x, w.y, w.z), f.push(R.x, R.y, R.z)), d[M] = null) : I in d || (d[I] = {
                        index0: l[v],
                        index1: l[x],
                        normal: ao.clone()
                    });
                }
            }
            for(let m in d)if (d[m]) {
                let { index0: _ , index1: g  } = d[m];
                vr.fromBufferAttribute(o, _), yr.fromBufferAttribute(o, g), f.push(vr.x, vr.y, vr.z), f.push(yr.x, yr.y, yr.z);
            }
            this.setAttribute("position", new ve(f, 3));
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
}, Fn = class extends ji {
    constructor(e){
        super(e), this.uuid = kt(), this.type = "Shape", this.holes = [];
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
            this.holes.push(new ji().fromJSON(i));
        }
        return this;
    }
}, ex = {
    triangulate: function(s1, e, t = 2) {
        let n = e && e.length, i = n ? e[0] * t : s1.length, r = Pd(s1, 0, i, t, !0), a = [];
        if (!r || r.next === r.prev) return a;
        let o, c, l, h, u, d, f;
        if (n && (r = rx(s1, e, r, t)), s1.length > 80 * t) {
            o = l = s1[0], c = h = s1[1];
            for(let m = t; m < i; m += t)u = s1[m], d = s1[m + 1], u < o && (o = u), d < c && (c = d), u > l && (l = u), d > h && (h = d);
            f = Math.max(l - o, h - c), f = f !== 0 ? 32767 / f : 0;
        }
        return Os(r, a, t, o, c, f, 0), a;
    }
};
function Pd(s1, e, t, n, i) {
    let r, a;
    if (i === gx(s1, e, t, n) > 0) for(r = e; r < t; r += n)a = tu(r, s1[r], s1[r + 1], a);
    else for(r = t - n; r >= e; r -= n)a = tu(r, s1[r], s1[r + 1], a);
    return a && Ma(a, a.next) && (Bs(a), a = a.next), a;
}
function fi(s1, e) {
    if (!s1) return s1;
    e || (e = s1);
    let t = s1, n;
    do if (n = !1, !t.steiner && (Ma(t, t.next) || st(t.prev, t, t.next) === 0)) {
        if (Bs(t), t = e = t.prev, t === t.next) break;
        n = !0;
    } else t = t.next;
    while (n || t !== e)
    return e;
}
function Os(s1, e, t, n, i, r, a) {
    if (!s1) return;
    !a && r && hx(s1, n, i, r);
    let o = s1, c, l;
    for(; s1.prev !== s1.next;){
        if (c = s1.prev, l = s1.next, r ? nx(s1, n, i, r) : tx(s1)) {
            e.push(c.i / t | 0), e.push(s1.i / t | 0), e.push(l.i / t | 0), Bs(s1), s1 = l.next, o = l.next;
            continue;
        }
        if (s1 = l, s1 === o) {
            a ? a === 1 ? (s1 = ix(fi(s1), e, t), Os(s1, e, t, n, i, r, 2)) : a === 2 && sx(s1, e, t, n, i, r) : Os(fi(s1), e, t, n, i, r, 1);
            break;
        }
    }
}
function tx(s1) {
    let e = s1.prev, t = s1, n = s1.next;
    if (st(e, t, n) >= 0) return !1;
    let i = e.x, r = t.x, a = n.x, o = e.y, c = t.y, l = n.y, h = i < r ? i < a ? i : a : r < a ? r : a, u = o < c ? o < l ? o : l : c < l ? c : l, d = i > r ? i > a ? i : a : r > a ? r : a, f = o > c ? o > l ? o : l : c > l ? c : l, m = n.next;
    for(; m !== e;){
        if (m.x >= h && m.x <= d && m.y >= u && m.y <= f && Gi(i, o, r, c, a, l, m.x, m.y) && st(m.prev, m, m.next) >= 0) return !1;
        m = m.next;
    }
    return !0;
}
function nx(s1, e, t, n) {
    let i = s1.prev, r = s1, a = s1.next;
    if (st(i, r, a) >= 0) return !1;
    let o = i.x, c = r.x, l = a.x, h = i.y, u = r.y, d = a.y, f = o < c ? o < l ? o : l : c < l ? c : l, m = h < u ? h < d ? h : d : u < d ? u : d, _ = o > c ? o > l ? o : l : c > l ? c : l, g = h > u ? h > d ? h : d : u > d ? u : d, p = Ko(f, m, e, t, n), v = Ko(_, g, e, t, n), x = s1.prevZ, y = s1.nextZ;
    for(; x && x.z >= p && y && y.z <= v;){
        if (x.x >= f && x.x <= _ && x.y >= m && x.y <= g && x !== i && x !== a && Gi(o, h, c, u, l, d, x.x, x.y) && st(x.prev, x, x.next) >= 0 || (x = x.prevZ, y.x >= f && y.x <= _ && y.y >= m && y.y <= g && y !== i && y !== a && Gi(o, h, c, u, l, d, y.x, y.y) && st(y.prev, y, y.next) >= 0)) return !1;
        y = y.nextZ;
    }
    for(; x && x.z >= p;){
        if (x.x >= f && x.x <= _ && x.y >= m && x.y <= g && x !== i && x !== a && Gi(o, h, c, u, l, d, x.x, x.y) && st(x.prev, x, x.next) >= 0) return !1;
        x = x.prevZ;
    }
    for(; y && y.z <= v;){
        if (y.x >= f && y.x <= _ && y.y >= m && y.y <= g && y !== i && y !== a && Gi(o, h, c, u, l, d, y.x, y.y) && st(y.prev, y, y.next) >= 0) return !1;
        y = y.nextZ;
    }
    return !0;
}
function ix(s1, e, t) {
    let n = s1;
    do {
        let i = n.prev, r = n.next.next;
        !Ma(i, r) && Ld(i, n, n.next, r) && Fs(i, r) && Fs(r, i) && (e.push(i.i / t | 0), e.push(n.i / t | 0), e.push(r.i / t | 0), Bs(n), Bs(n.next), n = s1 = r), n = n.next;
    }while (n !== s1)
    return fi(n);
}
function sx(s1, e, t, n, i, r) {
    let a = s1;
    do {
        let o = a.next.next;
        for(; o !== a.prev;){
            if (a.i !== o.i && fx(a, o)) {
                let c = Id(a, o);
                a = fi(a, a.next), c = fi(c, c.next), Os(a, e, t, n, i, r, 0), Os(c, e, t, n, i, r, 0);
                return;
            }
            o = o.next;
        }
        a = a.next;
    }while (a !== s1)
}
function rx(s1, e, t, n) {
    let i = [], r, a, o, c, l;
    for(r = 0, a = e.length; r < a; r++)o = e[r] * n, c = r < a - 1 ? e[r + 1] * n : s1.length, l = Pd(s1, o, c, n, !1), l === l.next && (l.steiner = !0), i.push(dx(l));
    for(i.sort(ax), r = 0; r < i.length; r++)t = ox(i[r], t);
    return t;
}
function ax(s1, e) {
    return s1.x - e.x;
}
function ox(s1, e) {
    let t = cx(s1, e);
    if (!t) return e;
    let n = Id(t, s1);
    return fi(n, n.next), fi(t, t.next);
}
function cx(s1, e) {
    let t = e, n = -1 / 0, i, r = s1.x, a = s1.y;
    do {
        if (a <= t.y && a >= t.next.y && t.next.y !== t.y) {
            let d = t.x + (a - t.y) * (t.next.x - t.x) / (t.next.y - t.y);
            if (d <= r && d > n && (n = d, i = t.x < t.next.x ? t : t.next, d === r)) return i;
        }
        t = t.next;
    }while (t !== e)
    if (!i) return null;
    let o = i, c = i.x, l = i.y, h = 1 / 0, u;
    t = i;
    do r >= t.x && t.x >= c && r !== t.x && Gi(a < l ? r : n, a, c, l, a < l ? n : r, a, t.x, t.y) && (u = Math.abs(a - t.y) / (r - t.x), Fs(t, s1) && (u < h || u === h && (t.x > i.x || t.x === i.x && lx(i, t))) && (i = t, h = u)), t = t.next;
    while (t !== o)
    return i;
}
function lx(s1, e) {
    return st(s1.prev, s1, e.prev) < 0 && st(e.next, s1, s1.next) < 0;
}
function hx(s1, e, t, n) {
    let i = s1;
    do i.z === 0 && (i.z = Ko(i.x, i.y, e, t, n)), i.prevZ = i.prev, i.nextZ = i.next, i = i.next;
    while (i !== s1)
    i.prevZ.nextZ = null, i.prevZ = null, ux(i);
}
function ux(s1) {
    let e, t, n, i, r, a, o, c, l = 1;
    do {
        for(t = s1, s1 = null, r = null, a = 0; t;){
            for(a++, n = t, o = 0, e = 0; e < l && (o++, n = n.nextZ, !!n); e++);
            for(c = l; o > 0 || c > 0 && n;)o !== 0 && (c === 0 || !n || t.z <= n.z) ? (i = t, t = t.nextZ, o--) : (i = n, n = n.nextZ, c--), r ? r.nextZ = i : s1 = i, i.prevZ = r, r = i;
            t = n;
        }
        r.nextZ = null, l *= 2;
    }while (a > 1)
    return s1;
}
function Ko(s1, e, t, n, i) {
    return s1 = (s1 - t) * i | 0, e = (e - n) * i | 0, s1 = (s1 | s1 << 8) & 16711935, s1 = (s1 | s1 << 4) & 252645135, s1 = (s1 | s1 << 2) & 858993459, s1 = (s1 | s1 << 1) & 1431655765, e = (e | e << 8) & 16711935, e = (e | e << 4) & 252645135, e = (e | e << 2) & 858993459, e = (e | e << 1) & 1431655765, s1 | e << 1;
}
function dx(s1) {
    let e = s1, t = s1;
    do (e.x < t.x || e.x === t.x && e.y < t.y) && (t = e), e = e.next;
    while (e !== s1)
    return t;
}
function Gi(s1, e, t, n, i, r, a, o) {
    return (i - a) * (e - o) >= (s1 - a) * (r - o) && (s1 - a) * (n - o) >= (t - a) * (e - o) && (t - a) * (r - o) >= (i - a) * (n - o);
}
function fx(s1, e) {
    return s1.next.i !== e.i && s1.prev.i !== e.i && !px(s1, e) && (Fs(s1, e) && Fs(e, s1) && mx(s1, e) && (st(s1.prev, s1, e.prev) || st(s1, e.prev, e)) || Ma(s1, e) && st(s1.prev, s1, s1.next) > 0 && st(e.prev, e, e.next) > 0);
}
function st(s1, e, t) {
    return (e.y - s1.y) * (t.x - e.x) - (e.x - s1.x) * (t.y - e.y);
}
function Ma(s1, e) {
    return s1.x === e.x && s1.y === e.y;
}
function Ld(s1, e, t, n) {
    let i = br(st(s1, e, t)), r = br(st(s1, e, n)), a = br(st(t, n, s1)), o = br(st(t, n, e));
    return !!(i !== r && a !== o || i === 0 && Sr(s1, t, e) || r === 0 && Sr(s1, n, e) || a === 0 && Sr(t, s1, n) || o === 0 && Sr(t, e, n));
}
function Sr(s1, e, t) {
    return e.x <= Math.max(s1.x, t.x) && e.x >= Math.min(s1.x, t.x) && e.y <= Math.max(s1.y, t.y) && e.y >= Math.min(s1.y, t.y);
}
function br(s1) {
    return s1 > 0 ? 1 : s1 < 0 ? -1 : 0;
}
function px(s1, e) {
    let t = s1;
    do {
        if (t.i !== s1.i && t.next.i !== s1.i && t.i !== e.i && t.next.i !== e.i && Ld(t, t.next, s1, e)) return !0;
        t = t.next;
    }while (t !== s1)
    return !1;
}
function Fs(s1, e) {
    return st(s1.prev, s1, s1.next) < 0 ? st(s1, e, s1.next) >= 0 && st(s1, s1.prev, e) >= 0 : st(s1, e, s1.prev) < 0 || st(s1, s1.next, e) < 0;
}
function mx(s1, e) {
    let t = s1, n = !1, i = (s1.x + e.x) / 2, r = (s1.y + e.y) / 2;
    do t.y > r != t.next.y > r && t.next.y !== t.y && i < (t.next.x - t.x) * (r - t.y) / (t.next.y - t.y) + t.x && (n = !n), t = t.next;
    while (t !== s1)
    return n;
}
function Id(s1, e) {
    let t = new Qo(s1.i, s1.x, s1.y), n = new Qo(e.i, e.x, e.y), i = s1.next, r = e.prev;
    return s1.next = e, e.prev = s1, t.next = i, i.prev = t, n.next = t, t.prev = n, r.next = n, n.prev = r, n;
}
function tu(s1, e, t, n) {
    let i = new Qo(s1, e, t);
    return n ? (i.next = n.next, i.prev = n, n.next.prev = i, n.next = i) : (i.prev = i, i.next = i), i;
}
function Bs(s1) {
    s1.next.prev = s1.prev, s1.prev.next = s1.next, s1.prevZ && (s1.prevZ.nextZ = s1.nextZ), s1.nextZ && (s1.nextZ.prevZ = s1.prevZ);
}
function Qo(s1, e, t) {
    this.i = s1, this.x = e, this.y = t, this.prev = null, this.next = null, this.z = 0, this.prevZ = null, this.nextZ = null, this.steiner = !1;
}
function gx(s1, e, t, n) {
    let i = 0;
    for(let r = e, a = t - n; r < t; r += n)i += (s1[a] - s1[r]) * (s1[r + 1] + s1[a + 1]), a = r;
    return i;
}
var yn = class s1 {
    static area(e) {
        let t = e.length, n = 0;
        for(let i = t - 1, r = 0; r < t; i = r++)n += e[i].x * e[r].y - e[r].x * e[i].y;
        return n * .5;
    }
    static isClockWise(e) {
        return s1.area(e) < 0;
    }
    static triangulateShape(e, t) {
        let n = [], i = [], r = [];
        nu(e), iu(n, e);
        let a = e.length;
        t.forEach(nu);
        for(let c = 0; c < t.length; c++)i.push(a), a += t[c].length, iu(n, t[c]);
        let o = ex.triangulate(n, i);
        for(let c = 0; c < o.length; c += 3)r.push(o.slice(c, c + 3));
        return r;
    }
};
function nu(s1) {
    let e = s1.length;
    e > 2 && s1[e - 1].equals(s1[0]) && s1.pop();
}
function iu(s1, e) {
    for(let t = 0; t < e.length; t++)s1.push(e[t].x), s1.push(e[t].y);
}
var jo = class s1 extends Ge {
    constructor(e = new Fn([
        new Z(.5, .5),
        new Z(-.5, .5),
        new Z(-.5, -.5),
        new Z(.5, -.5)
    ]), t = {}){
        super(), this.type = "ExtrudeGeometry", this.parameters = {
            shapes: e,
            options: t
        }, e = Array.isArray(e) ? e : [
            e
        ];
        let n = this, i = [], r = [];
        for(let o = 0, c = e.length; o < c; o++){
            let l = e[o];
            a(l);
        }
        this.setAttribute("position", new ve(i, 3)), this.setAttribute("uv", new ve(r, 2)), this.computeVertexNormals();
        function a(o) {
            let c = [], l = t.curveSegments !== void 0 ? t.curveSegments : 12, h = t.steps !== void 0 ? t.steps : 1, u = t.depth !== void 0 ? t.depth : 1, d = t.bevelEnabled !== void 0 ? t.bevelEnabled : !0, f = t.bevelThickness !== void 0 ? t.bevelThickness : .2, m = t.bevelSize !== void 0 ? t.bevelSize : f - .1, _ = t.bevelOffset !== void 0 ? t.bevelOffset : 0, g = t.bevelSegments !== void 0 ? t.bevelSegments : 3, p = t.extrudePath, v = t.UVGenerator !== void 0 ? t.UVGenerator : _x, x, y = !1, b, w, R, I;
            p && (x = p.getSpacedPoints(h), y = !0, d = !1, b = p.computeFrenetFrames(h, !1), w = new A, R = new A, I = new A), d || (g = 0, f = 0, m = 0, _ = 0);
            let M = o.extractPoints(l), T = M.shape, O = M.holes;
            if (!yn.isClockWise(T)) {
                T = T.reverse();
                for(let L = 0, oe = O.length; L < oe; L++){
                    let X = O[L];
                    yn.isClockWise(X) && (O[L] = X.reverse());
                }
            }
            let $ = yn.triangulateShape(T, O), U = T;
            for(let L = 0, oe = O.length; L < oe; L++){
                let X = O[L];
                T = T.concat(X);
            }
            function z(L, oe, X) {
                return oe || console.error("THREE.ExtrudeGeometry: vec does not exist"), L.clone().addScaledVector(oe, X);
            }
            let q = T.length, H = $.length;
            function ne(L, oe, X) {
                let ie, J, Se, me = L.x - oe.x, ye = L.y - oe.y, Ne = X.x - L.x, qe = X.y - L.y, rt = me * me + ye * ye, C = me * qe - ye * Ne;
                if (Math.abs(C) > Number.EPSILON) {
                    let S = Math.sqrt(rt), B = Math.sqrt(Ne * Ne + qe * qe), ee = oe.x - ye / S, j = oe.y + me / S, te = X.x - qe / B, Me = X.y + Ne / B, re = ((te - ee) * qe - (Me - j) * Ne) / (me * qe - ye * Ne);
                    ie = ee + me * re - L.x, J = j + ye * re - L.y;
                    let de = ie * ie + J * J;
                    if (de <= 2) return new Z(ie, J);
                    Se = Math.sqrt(de / 2);
                } else {
                    let S = !1;
                    me > Number.EPSILON ? Ne > Number.EPSILON && (S = !0) : me < -Number.EPSILON ? Ne < -Number.EPSILON && (S = !0) : Math.sign(ye) === Math.sign(qe) && (S = !0), S ? (ie = -ye, J = me, Se = Math.sqrt(rt)) : (ie = me, J = ye, Se = Math.sqrt(rt / 2));
                }
                return new Z(ie / Se, J / Se);
            }
            let W = [];
            for(let L = 0, oe = U.length, X = oe - 1, ie = L + 1; L < oe; L++, X++, ie++)X === oe && (X = 0), ie === oe && (ie = 0), W[L] = ne(U[L], U[X], U[ie]);
            let K = [], D, G = W.concat();
            for(let L = 0, oe = O.length; L < oe; L++){
                let X = O[L];
                D = [];
                for(let ie = 0, J = X.length, Se = J - 1, me = ie + 1; ie < J; ie++, Se++, me++)Se === J && (Se = 0), me === J && (me = 0), D[ie] = ne(X[ie], X[Se], X[me]);
                K.push(D), G = G.concat(D);
            }
            for(let L = 0; L < g; L++){
                let oe = L / g, X = f * Math.cos(oe * Math.PI / 2), ie = m * Math.sin(oe * Math.PI / 2) + _;
                for(let J = 0, Se = U.length; J < Se; J++){
                    let me = z(U[J], W[J], ie);
                    Ee(me.x, me.y, -X);
                }
                for(let J = 0, Se = O.length; J < Se; J++){
                    let me = O[J];
                    D = K[J];
                    for(let ye = 0, Ne = me.length; ye < Ne; ye++){
                        let qe = z(me[ye], D[ye], ie);
                        Ee(qe.x, qe.y, -X);
                    }
                }
            }
            let he = m + _;
            for(let L = 0; L < q; L++){
                let oe = d ? z(T[L], G[L], he) : T[L];
                y ? (R.copy(b.normals[0]).multiplyScalar(oe.x), w.copy(b.binormals[0]).multiplyScalar(oe.y), I.copy(x[0]).add(R).add(w), Ee(I.x, I.y, I.z)) : Ee(oe.x, oe.y, 0);
            }
            for(let L = 1; L <= h; L++)for(let oe = 0; oe < q; oe++){
                let X = d ? z(T[oe], G[oe], he) : T[oe];
                y ? (R.copy(b.normals[L]).multiplyScalar(X.x), w.copy(b.binormals[L]).multiplyScalar(X.y), I.copy(x[L]).add(R).add(w), Ee(I.x, I.y, I.z)) : Ee(X.x, X.y, u / h * L);
            }
            for(let L = g - 1; L >= 0; L--){
                let oe = L / g, X = f * Math.cos(oe * Math.PI / 2), ie = m * Math.sin(oe * Math.PI / 2) + _;
                for(let J = 0, Se = U.length; J < Se; J++){
                    let me = z(U[J], W[J], ie);
                    Ee(me.x, me.y, u + X);
                }
                for(let J = 0, Se = O.length; J < Se; J++){
                    let me = O[J];
                    D = K[J];
                    for(let ye = 0, Ne = me.length; ye < Ne; ye++){
                        let qe = z(me[ye], D[ye], ie);
                        y ? Ee(qe.x, qe.y + x[h - 1].y, x[h - 1].x + X) : Ee(qe.x, qe.y, u + X);
                    }
                }
            }
            fe(), _e();
            function fe() {
                let L = i.length / 3;
                if (d) {
                    let oe = 0, X = q * oe;
                    for(let ie = 0; ie < H; ie++){
                        let J = $[ie];
                        Te(J[2] + X, J[1] + X, J[0] + X);
                    }
                    oe = h + g * 2, X = q * oe;
                    for(let ie = 0; ie < H; ie++){
                        let J = $[ie];
                        Te(J[0] + X, J[1] + X, J[2] + X);
                    }
                } else {
                    for(let oe = 0; oe < H; oe++){
                        let X = $[oe];
                        Te(X[2], X[1], X[0]);
                    }
                    for(let oe = 0; oe < H; oe++){
                        let X = $[oe];
                        Te(X[0] + q * h, X[1] + q * h, X[2] + q * h);
                    }
                }
                n.addGroup(L, i.length / 3 - L, 0);
            }
            function _e() {
                let L = i.length / 3, oe = 0;
                we(U, oe), oe += U.length;
                for(let X = 0, ie = O.length; X < ie; X++){
                    let J = O[X];
                    we(J, oe), oe += J.length;
                }
                n.addGroup(L, i.length / 3 - L, 1);
            }
            function we(L, oe) {
                let X = L.length;
                for(; --X >= 0;){
                    let ie = X, J = X - 1;
                    J < 0 && (J = L.length - 1);
                    for(let Se = 0, me = h + g * 2; Se < me; Se++){
                        let ye = q * Se, Ne = q * (Se + 1), qe = oe + ie + ye, rt = oe + J + ye, C = oe + J + Ne, S = oe + ie + Ne;
                        Ye(qe, rt, C, S);
                    }
                }
            }
            function Ee(L, oe, X) {
                c.push(L), c.push(oe), c.push(X);
            }
            function Te(L, oe, X) {
                it(L), it(oe), it(X);
                let ie = i.length / 3, J = v.generateTopUV(n, i, ie - 3, ie - 2, ie - 1);
                Ce(J[0]), Ce(J[1]), Ce(J[2]);
            }
            function Ye(L, oe, X, ie) {
                it(L), it(oe), it(ie), it(oe), it(X), it(ie);
                let J = i.length / 3, Se = v.generateSideWallUV(n, i, J - 6, J - 3, J - 2, J - 1);
                Ce(Se[0]), Ce(Se[1]), Ce(Se[3]), Ce(Se[1]), Ce(Se[2]), Ce(Se[3]);
            }
            function it(L) {
                i.push(c[L * 3 + 0]), i.push(c[L * 3 + 1]), i.push(c[L * 3 + 2]);
            }
            function Ce(L) {
                r.push(L.x), r.push(L.y);
            }
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    toJSON() {
        let e = super.toJSON(), t = this.parameters.shapes, n = this.parameters.options;
        return xx(t, n, e);
    }
    static fromJSON(e, t) {
        let n = [];
        for(let r = 0, a = e.shapes.length; r < a; r++){
            let o = t[e.shapes[r]];
            n.push(o);
        }
        let i = e.options.extrudePath;
        return i !== void 0 && (e.options.extrudePath = new ca[i.type]().fromJSON(i)), new s1(n, e.options);
    }
}, _x = {
    generateTopUV: function(s1, e, t, n, i) {
        let r = e[t * 3], a = e[t * 3 + 1], o = e[n * 3], c = e[n * 3 + 1], l = e[i * 3], h = e[i * 3 + 1];
        return [
            new Z(r, a),
            new Z(o, c),
            new Z(l, h)
        ];
    },
    generateSideWallUV: function(s1, e, t, n, i, r) {
        let a = e[t * 3], o = e[t * 3 + 1], c = e[t * 3 + 2], l = e[n * 3], h = e[n * 3 + 1], u = e[n * 3 + 2], d = e[i * 3], f = e[i * 3 + 1], m = e[i * 3 + 2], _ = e[r * 3], g = e[r * 3 + 1], p = e[r * 3 + 2];
        return Math.abs(o - h) < Math.abs(a - l) ? [
            new Z(a, 1 - c),
            new Z(l, 1 - u),
            new Z(d, 1 - m),
            new Z(_, 1 - p)
        ] : [
            new Z(o, 1 - c),
            new Z(h, 1 - u),
            new Z(f, 1 - m),
            new Z(g, 1 - p)
        ];
    }
};
function xx(s1, e, t) {
    if (t.shapes = [], Array.isArray(s1)) for(let n = 0, i = s1.length; n < i; n++){
        let r = s1[n];
        t.shapes.push(r.uuid);
    }
    else t.shapes.push(s1.uuid);
    return t.options = Object.assign({}, e), e.extrudePath !== void 0 && (t.options.extrudePath = e.extrudePath.toJSON()), t;
}
var ec = class s1 extends di {
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
        super(i, r, e, t), this.type = "IcosahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new s1(e.radius, e.detail);
    }
}, ha = class s1 extends di {
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
        super(n, i, e, t), this.type = "OctahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new s1(e.radius, e.detail);
    }
}, tc = class s1 extends Ge {
    constructor(e = .5, t = 1, n = 32, i = 1, r = 0, a = Math.PI * 2){
        super(), this.type = "RingGeometry", this.parameters = {
            innerRadius: e,
            outerRadius: t,
            thetaSegments: n,
            phiSegments: i,
            thetaStart: r,
            thetaLength: a
        }, n = Math.max(3, n), i = Math.max(1, i);
        let o = [], c = [], l = [], h = [], u = e, d = (t - e) / i, f = new A, m = new Z;
        for(let _ = 0; _ <= i; _++){
            for(let g = 0; g <= n; g++){
                let p = r + g / n * a;
                f.x = u * Math.cos(p), f.y = u * Math.sin(p), c.push(f.x, f.y, f.z), l.push(0, 0, 1), m.x = (f.x / t + 1) / 2, m.y = (f.y / t + 1) / 2, h.push(m.x, m.y);
            }
            u += d;
        }
        for(let _ = 0; _ < i; _++){
            let g = _ * (n + 1);
            for(let p = 0; p < n; p++){
                let v = p + g, x = v, y = v + n + 1, b = v + n + 2, w = v + 1;
                o.push(x, y, w), o.push(y, b, w);
            }
        }
        this.setIndex(o), this.setAttribute("position", new ve(c, 3)), this.setAttribute("normal", new ve(l, 3)), this.setAttribute("uv", new ve(h, 2));
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.innerRadius, e.outerRadius, e.thetaSegments, e.phiSegments, e.thetaStart, e.thetaLength);
    }
}, nc = class s1 extends Ge {
    constructor(e = new Fn([
        new Z(0, .5),
        new Z(-.5, -.5),
        new Z(.5, -.5)
    ]), t = 12){
        super(), this.type = "ShapeGeometry", this.parameters = {
            shapes: e,
            curveSegments: t
        };
        let n = [], i = [], r = [], a = [], o = 0, c = 0;
        if (Array.isArray(e) === !1) l(e);
        else for(let h = 0; h < e.length; h++)l(e[h]), this.addGroup(o, c, h), o += c, c = 0;
        this.setIndex(n), this.setAttribute("position", new ve(i, 3)), this.setAttribute("normal", new ve(r, 3)), this.setAttribute("uv", new ve(a, 2));
        function l(h) {
            let u = i.length / 3, d = h.extractPoints(t), f = d.shape, m = d.holes;
            yn.isClockWise(f) === !1 && (f = f.reverse());
            for(let g = 0, p = m.length; g < p; g++){
                let v = m[g];
                yn.isClockWise(v) === !0 && (m[g] = v.reverse());
            }
            let _ = yn.triangulateShape(f, m);
            for(let g = 0, p = m.length; g < p; g++){
                let v = m[g];
                f = f.concat(v);
            }
            for(let g = 0, p = f.length; g < p; g++){
                let v = f[g];
                i.push(v.x, v.y, 0), r.push(0, 0, 1), a.push(v.x, v.y);
            }
            for(let g = 0, p = _.length; g < p; g++){
                let v = _[g], x = v[0] + u, y = v[1] + u, b = v[2] + u;
                n.push(x, y, b), c += 3;
            }
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    toJSON() {
        let e = super.toJSON(), t = this.parameters.shapes;
        return vx(t, e);
    }
    static fromJSON(e, t) {
        let n = [];
        for(let i = 0, r = e.shapes.length; i < r; i++){
            let a = t[e.shapes[i]];
            n.push(a);
        }
        return new s1(n, e.curveSegments);
    }
};
function vx(s1, e) {
    if (e.shapes = [], Array.isArray(s1)) for(let t = 0, n = s1.length; t < n; t++){
        let i = s1[t];
        e.shapes.push(i.uuid);
    }
    else e.shapes.push(s1.uuid);
    return e;
}
var ua = class s1 extends Ge {
    constructor(e = 1, t = 32, n = 16, i = 0, r = Math.PI * 2, a = 0, o = Math.PI){
        super(), this.type = "SphereGeometry", this.parameters = {
            radius: e,
            widthSegments: t,
            heightSegments: n,
            phiStart: i,
            phiLength: r,
            thetaStart: a,
            thetaLength: o
        }, t = Math.max(3, Math.floor(t)), n = Math.max(2, Math.floor(n));
        let c = Math.min(a + o, Math.PI), l = 0, h = [], u = new A, d = new A, f = [], m = [], _ = [], g = [];
        for(let p = 0; p <= n; p++){
            let v = [], x = p / n, y = 0;
            p === 0 && a === 0 ? y = .5 / t : p === n && c === Math.PI && (y = -.5 / t);
            for(let b = 0; b <= t; b++){
                let w = b / t;
                u.x = -e * Math.cos(i + w * r) * Math.sin(a + x * o), u.y = e * Math.cos(a + x * o), u.z = e * Math.sin(i + w * r) * Math.sin(a + x * o), m.push(u.x, u.y, u.z), d.copy(u).normalize(), _.push(d.x, d.y, d.z), g.push(w + y, 1 - x), v.push(l++);
            }
            h.push(v);
        }
        for(let p = 0; p < n; p++)for(let v = 0; v < t; v++){
            let x = h[p][v + 1], y = h[p][v], b = h[p + 1][v], w = h[p + 1][v + 1];
            (p !== 0 || a > 0) && f.push(x, y, w), (p !== n - 1 || c < Math.PI) && f.push(y, b, w);
        }
        this.setIndex(f), this.setAttribute("position", new ve(m, 3)), this.setAttribute("normal", new ve(_, 3)), this.setAttribute("uv", new ve(g, 2));
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.radius, e.widthSegments, e.heightSegments, e.phiStart, e.phiLength, e.thetaStart, e.thetaLength);
    }
}, ic = class s1 extends di {
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
        super(n, i, e, t), this.type = "TetrahedronGeometry", this.parameters = {
            radius: e,
            detail: t
        };
    }
    static fromJSON(e) {
        return new s1(e.radius, e.detail);
    }
}, sc = class s1 extends Ge {
    constructor(e = 1, t = .4, n = 12, i = 48, r = Math.PI * 2){
        super(), this.type = "TorusGeometry", this.parameters = {
            radius: e,
            tube: t,
            radialSegments: n,
            tubularSegments: i,
            arc: r
        }, n = Math.floor(n), i = Math.floor(i);
        let a = [], o = [], c = [], l = [], h = new A, u = new A, d = new A;
        for(let f = 0; f <= n; f++)for(let m = 0; m <= i; m++){
            let _ = m / i * r, g = f / n * Math.PI * 2;
            u.x = (e + t * Math.cos(g)) * Math.cos(_), u.y = (e + t * Math.cos(g)) * Math.sin(_), u.z = t * Math.sin(g), o.push(u.x, u.y, u.z), h.x = e * Math.cos(_), h.y = e * Math.sin(_), d.subVectors(u, h).normalize(), c.push(d.x, d.y, d.z), l.push(m / i), l.push(f / n);
        }
        for(let f = 1; f <= n; f++)for(let m = 1; m <= i; m++){
            let _ = (i + 1) * f + m - 1, g = (i + 1) * (f - 1) + m - 1, p = (i + 1) * (f - 1) + m, v = (i + 1) * f + m;
            a.push(_, g, v), a.push(g, p, v);
        }
        this.setIndex(a), this.setAttribute("position", new ve(o, 3)), this.setAttribute("normal", new ve(c, 3)), this.setAttribute("uv", new ve(l, 2));
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.radius, e.tube, e.radialSegments, e.tubularSegments, e.arc);
    }
}, rc = class s1 extends Ge {
    constructor(e = 1, t = .4, n = 64, i = 8, r = 2, a = 3){
        super(), this.type = "TorusKnotGeometry", this.parameters = {
            radius: e,
            tube: t,
            tubularSegments: n,
            radialSegments: i,
            p: r,
            q: a
        }, n = Math.floor(n), i = Math.floor(i);
        let o = [], c = [], l = [], h = [], u = new A, d = new A, f = new A, m = new A, _ = new A, g = new A, p = new A;
        for(let x = 0; x <= n; ++x){
            let y = x / n * r * Math.PI * 2;
            v(y, r, a, e, f), v(y + .01, r, a, e, m), g.subVectors(m, f), p.addVectors(m, f), _.crossVectors(g, p), p.crossVectors(_, g), _.normalize(), p.normalize();
            for(let b = 0; b <= i; ++b){
                let w = b / i * Math.PI * 2, R = -t * Math.cos(w), I = t * Math.sin(w);
                u.x = f.x + (R * p.x + I * _.x), u.y = f.y + (R * p.y + I * _.y), u.z = f.z + (R * p.z + I * _.z), c.push(u.x, u.y, u.z), d.subVectors(u, f).normalize(), l.push(d.x, d.y, d.z), h.push(x / n), h.push(b / i);
            }
        }
        for(let x = 1; x <= n; x++)for(let y = 1; y <= i; y++){
            let b = (i + 1) * (x - 1) + (y - 1), w = (i + 1) * x + (y - 1), R = (i + 1) * x + y, I = (i + 1) * (x - 1) + y;
            o.push(b, w, I), o.push(w, R, I);
        }
        this.setIndex(o), this.setAttribute("position", new ve(c, 3)), this.setAttribute("normal", new ve(l, 3)), this.setAttribute("uv", new ve(h, 2));
        function v(x, y, b, w, R) {
            let I = Math.cos(x), M = Math.sin(x), T = b / y * x, O = Math.cos(T);
            R.x = w * (2 + O) * .5 * I, R.y = w * (2 + O) * M * .5, R.z = w * Math.sin(T) * .5;
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    static fromJSON(e) {
        return new s1(e.radius, e.tube, e.tubularSegments, e.radialSegments, e.p, e.q);
    }
}, ac = class s1 extends Ge {
    constructor(e = new aa(new A(-1, -1, 0), new A(-1, 1, 0), new A(1, 1, 0)), t = 64, n = 1, i = 8, r = !1){
        super(), this.type = "TubeGeometry", this.parameters = {
            path: e,
            tubularSegments: t,
            radius: n,
            radialSegments: i,
            closed: r
        };
        let a = e.computeFrenetFrames(t, r);
        this.tangents = a.tangents, this.normals = a.normals, this.binormals = a.binormals;
        let o = new A, c = new A, l = new Z, h = new A, u = [], d = [], f = [], m = [];
        _(), this.setIndex(m), this.setAttribute("position", new ve(u, 3)), this.setAttribute("normal", new ve(d, 3)), this.setAttribute("uv", new ve(f, 2));
        function _() {
            for(let x = 0; x < t; x++)g(x);
            g(r === !1 ? t : 0), v(), p();
        }
        function g(x) {
            h = e.getPointAt(x / t, h);
            let y = a.normals[x], b = a.binormals[x];
            for(let w = 0; w <= i; w++){
                let R = w / i * Math.PI * 2, I = Math.sin(R), M = -Math.cos(R);
                c.x = M * y.x + I * b.x, c.y = M * y.y + I * b.y, c.z = M * y.z + I * b.z, c.normalize(), d.push(c.x, c.y, c.z), o.x = h.x + n * c.x, o.y = h.y + n * c.y, o.z = h.z + n * c.z, u.push(o.x, o.y, o.z);
            }
        }
        function p() {
            for(let x = 1; x <= t; x++)for(let y = 1; y <= i; y++){
                let b = (i + 1) * (x - 1) + (y - 1), w = (i + 1) * x + (y - 1), R = (i + 1) * x + y, I = (i + 1) * (x - 1) + y;
                m.push(b, w, I), m.push(w, R, I);
            }
        }
        function v() {
            for(let x = 0; x <= t; x++)for(let y = 0; y <= i; y++)l.x = x / t, l.y = y / i, f.push(l.x, l.y);
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.path = this.parameters.path.toJSON(), e;
    }
    static fromJSON(e) {
        return new s1(new ca[e.path.type]().fromJSON(e.path), e.tubularSegments, e.radius, e.radialSegments, e.closed);
    }
}, oc = class extends Ge {
    constructor(e = null){
        if (super(), this.type = "WireframeGeometry", this.parameters = {
            geometry: e
        }, e !== null) {
            let t = [], n = new Set, i = new A, r = new A;
            if (e.index !== null) {
                let a = e.attributes.position, o = e.index, c = e.groups;
                c.length === 0 && (c = [
                    {
                        start: 0,
                        count: o.count,
                        materialIndex: 0
                    }
                ]);
                for(let l = 0, h = c.length; l < h; ++l){
                    let u = c[l], d = u.start, f = u.count;
                    for(let m = d, _ = d + f; m < _; m += 3)for(let g = 0; g < 3; g++){
                        let p = o.getX(m + g), v = o.getX(m + (g + 1) % 3);
                        i.fromBufferAttribute(a, p), r.fromBufferAttribute(a, v), su(i, r, n) === !0 && (t.push(i.x, i.y, i.z), t.push(r.x, r.y, r.z));
                    }
                }
            } else {
                let a = e.attributes.position;
                for(let o = 0, c = a.count / 3; o < c; o++)for(let l = 0; l < 3; l++){
                    let h = 3 * o + l, u = 3 * o + (l + 1) % 3;
                    i.fromBufferAttribute(a, h), r.fromBufferAttribute(a, u), su(i, r, n) === !0 && (t.push(i.x, i.y, i.z), t.push(r.x, r.y, r.z));
                }
            }
            this.setAttribute("position", new ve(t, 3));
        }
    }
    copy(e) {
        return super.copy(e), this.parameters = Object.assign({}, e.parameters), this;
    }
};
function su(s1, e, t) {
    let n = `${s1.x},${s1.y},${s1.z}-${e.x},${e.y},${e.z}`, i = `${e.x},${e.y},${e.z}-${s1.x},${s1.y},${s1.z}`;
    return t.has(n) === !0 || t.has(i) === !0 ? !1 : (t.add(n), t.add(i), !0);
}
var ru = Object.freeze({
    __proto__: null,
    BoxGeometry: Ji,
    CapsuleGeometry: qo,
    CircleGeometry: Yo,
    ConeGeometry: Zo,
    CylinderGeometry: Ns,
    DodecahedronGeometry: Jo,
    EdgesGeometry: $o,
    ExtrudeGeometry: jo,
    IcosahedronGeometry: ec,
    LatheGeometry: la,
    OctahedronGeometry: ha,
    PlaneGeometry: $r,
    PolyhedronGeometry: di,
    RingGeometry: tc,
    ShapeGeometry: nc,
    SphereGeometry: ua,
    TetrahedronGeometry: ic,
    TorusGeometry: sc,
    TorusKnotGeometry: rc,
    TubeGeometry: ac,
    WireframeGeometry: oc
}), cc = class extends bt {
    constructor(e){
        super(), this.isShadowMaterial = !0, this.type = "ShadowMaterial", this.color = new pe(0), this.transparent = !0, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.fog = e.fog, this;
    }
}, lc = class extends jt {
    constructor(e){
        super(e), this.isRawShaderMaterial = !0, this.type = "RawShaderMaterial";
    }
}, da = class extends bt {
    constructor(e){
        super(), this.isMeshStandardMaterial = !0, this.defines = {
            STANDARD: ""
        }, this.type = "MeshStandardMaterial", this.color = new pe(16777215), this.roughness = 1, this.metalness = 0, this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new pe(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new Z(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.roughnessMap = null, this.metalnessMap = null, this.alphaMap = null, this.envMap = null, this.envMapIntensity = 1, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.defines = {
            STANDARD: ""
        }, this.color.copy(e.color), this.roughness = e.roughness, this.metalness = e.metalness, this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.roughnessMap = e.roughnessMap, this.metalnessMap = e.metalnessMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.envMapIntensity = e.envMapIntensity, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.flatShading = e.flatShading, this.fog = e.fog, this;
    }
}, hc = class extends da {
    constructor(e){
        super(), this.isMeshPhysicalMaterial = !0, this.defines = {
            STANDARD: "",
            PHYSICAL: ""
        }, this.type = "MeshPhysicalMaterial", this.anisotropyRotation = 0, this.anisotropyMap = null, this.clearcoatMap = null, this.clearcoatRoughness = 0, this.clearcoatRoughnessMap = null, this.clearcoatNormalScale = new Z(1, 1), this.clearcoatNormalMap = null, this.ior = 1.5, Object.defineProperty(this, "reflectivity", {
            get: function() {
                return ct(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
            },
            set: function(t) {
                this.ior = (1 + .4 * t) / (1 - .4 * t);
            }
        }), this.iridescenceMap = null, this.iridescenceIOR = 1.3, this.iridescenceThicknessRange = [
            100,
            400
        ], this.iridescenceThicknessMap = null, this.sheenColor = new pe(0), this.sheenColorMap = null, this.sheenRoughness = 1, this.sheenRoughnessMap = null, this.transmissionMap = null, this.thickness = 0, this.thicknessMap = null, this.attenuationDistance = 1 / 0, this.attenuationColor = new pe(1, 1, 1), this.specularIntensity = 1, this.specularIntensityMap = null, this.specularColor = new pe(1, 1, 1), this.specularColorMap = null, this._anisotropy = 0, this._clearcoat = 0, this._iridescence = 0, this._sheen = 0, this._transmission = 0, this.setValues(e);
    }
    get anisotropy() {
        return this._anisotropy;
    }
    set anisotropy(e) {
        this._anisotropy > 0 != e > 0 && this.version++, this._anisotropy = e;
    }
    get clearcoat() {
        return this._clearcoat;
    }
    set clearcoat(e) {
        this._clearcoat > 0 != e > 0 && this.version++, this._clearcoat = e;
    }
    get iridescence() {
        return this._iridescence;
    }
    set iridescence(e) {
        this._iridescence > 0 != e > 0 && this.version++, this._iridescence = e;
    }
    get sheen() {
        return this._sheen;
    }
    set sheen(e) {
        this._sheen > 0 != e > 0 && this.version++, this._sheen = e;
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
        }, this.anisotropy = e.anisotropy, this.anisotropyRotation = e.anisotropyRotation, this.anisotropyMap = e.anisotropyMap, this.clearcoat = e.clearcoat, this.clearcoatMap = e.clearcoatMap, this.clearcoatRoughness = e.clearcoatRoughness, this.clearcoatRoughnessMap = e.clearcoatRoughnessMap, this.clearcoatNormalMap = e.clearcoatNormalMap, this.clearcoatNormalScale.copy(e.clearcoatNormalScale), this.ior = e.ior, this.iridescence = e.iridescence, this.iridescenceMap = e.iridescenceMap, this.iridescenceIOR = e.iridescenceIOR, this.iridescenceThicknessRange = [
            ...e.iridescenceThicknessRange
        ], this.iridescenceThicknessMap = e.iridescenceThicknessMap, this.sheen = e.sheen, this.sheenColor.copy(e.sheenColor), this.sheenColorMap = e.sheenColorMap, this.sheenRoughness = e.sheenRoughness, this.sheenRoughnessMap = e.sheenRoughnessMap, this.transmission = e.transmission, this.transmissionMap = e.transmissionMap, this.thickness = e.thickness, this.thicknessMap = e.thicknessMap, this.attenuationDistance = e.attenuationDistance, this.attenuationColor.copy(e.attenuationColor), this.specularIntensity = e.specularIntensity, this.specularIntensityMap = e.specularIntensityMap, this.specularColor.copy(e.specularColor), this.specularColorMap = e.specularColorMap, this;
    }
}, uc = class extends bt {
    constructor(e){
        super(), this.isMeshPhongMaterial = !0, this.type = "MeshPhongMaterial", this.color = new pe(16777215), this.specular = new pe(1118481), this.shininess = 30, this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new pe(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new Z(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = xa, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.specular.copy(e.specular), this.shininess = e.shininess, this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.specularMap = e.specularMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.combine = e.combine, this.reflectivity = e.reflectivity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.flatShading = e.flatShading, this.fog = e.fog, this;
    }
}, dc = class extends bt {
    constructor(e){
        super(), this.isMeshToonMaterial = !0, this.defines = {
            TOON: ""
        }, this.type = "MeshToonMaterial", this.color = new pe(16777215), this.map = null, this.gradientMap = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new pe(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new Z(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.alphaMap = null, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.gradientMap = e.gradientMap, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.alphaMap = e.alphaMap, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.fog = e.fog, this;
    }
}, fc = class extends bt {
    constructor(e){
        super(), this.isMeshNormalMaterial = !0, this.type = "MeshNormalMaterial", this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new Z(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.wireframe = !1, this.wireframeLinewidth = 1, this.flatShading = !1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.flatShading = e.flatShading, this;
    }
}, pc = class extends bt {
    constructor(e){
        super(), this.isMeshLambertMaterial = !0, this.type = "MeshLambertMaterial", this.color = new pe(16777215), this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new pe(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new Z(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = xa, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.color.copy(e.color), this.map = e.map, this.lightMap = e.lightMap, this.lightMapIntensity = e.lightMapIntensity, this.aoMap = e.aoMap, this.aoMapIntensity = e.aoMapIntensity, this.emissive.copy(e.emissive), this.emissiveMap = e.emissiveMap, this.emissiveIntensity = e.emissiveIntensity, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.specularMap = e.specularMap, this.alphaMap = e.alphaMap, this.envMap = e.envMap, this.combine = e.combine, this.reflectivity = e.reflectivity, this.refractionRatio = e.refractionRatio, this.wireframe = e.wireframe, this.wireframeLinewidth = e.wireframeLinewidth, this.wireframeLinecap = e.wireframeLinecap, this.wireframeLinejoin = e.wireframeLinejoin, this.flatShading = e.flatShading, this.fog = e.fog, this;
    }
}, mc = class extends bt {
    constructor(e){
        super(), this.isMeshMatcapMaterial = !0, this.defines = {
            MATCAP: ""
        }, this.type = "MeshMatcapMaterial", this.color = new pe(16777215), this.matcap = null, this.map = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new Z(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.alphaMap = null, this.flatShading = !1, this.fog = !0, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.defines = {
            MATCAP: ""
        }, this.color.copy(e.color), this.matcap = e.matcap, this.map = e.map, this.bumpMap = e.bumpMap, this.bumpScale = e.bumpScale, this.normalMap = e.normalMap, this.normalMapType = e.normalMapType, this.normalScale.copy(e.normalScale), this.displacementMap = e.displacementMap, this.displacementScale = e.displacementScale, this.displacementBias = e.displacementBias, this.alphaMap = e.alphaMap, this.flatShading = e.flatShading, this.fog = e.fog, this;
    }
}, gc = class extends wt {
    constructor(e){
        super(), this.isLineDashedMaterial = !0, this.type = "LineDashedMaterial", this.scale = 1, this.dashSize = 3, this.gapSize = 1, this.setValues(e);
    }
    copy(e) {
        return super.copy(e), this.scale = e.scale, this.dashSize = e.dashSize, this.gapSize = e.gapSize, this;
    }
};
function ni(s1, e, t) {
    return !s1 || !t && s1.constructor === e ? s1 : typeof e.BYTES_PER_ELEMENT == "number" ? new e(s1) : Array.prototype.slice.call(s1);
}
function Ud(s1) {
    return ArrayBuffer.isView(s1) && !(s1 instanceof DataView);
}
function Dd(s1) {
    function e(i, r) {
        return s1[i] - s1[r];
    }
    let t = s1.length, n = new Array(t);
    for(let i = 0; i !== t; ++i)n[i] = i;
    return n.sort(e), n;
}
function _c(s1, e, t) {
    let n = s1.length, i = new s1.constructor(n);
    for(let r = 0, a = 0; a !== n; ++r){
        let o = t[r] * e;
        for(let c = 0; c !== e; ++c)i[a++] = s1[o + c];
    }
    return i;
}
function $c(s1, e, t, n) {
    let i = 1, r = s1[0];
    for(; r !== void 0 && r[n] === void 0;)r = s1[i++];
    if (r === void 0) return;
    let a = r[n];
    if (a !== void 0) if (Array.isArray(a)) do a = r[n], a !== void 0 && (e.push(r.time), t.push.apply(t, a)), r = s1[i++];
    while (r !== void 0)
    else if (a.toArray !== void 0) do a = r[n], a !== void 0 && (e.push(r.time), a.toArray(t, t.length)), r = s1[i++];
    while (r !== void 0)
    else do a = r[n], a !== void 0 && (e.push(r.time), t.push(a)), r = s1[i++];
    while (r !== void 0)
}
function yx(s1, e, t, n, i = 30) {
    let r = s1.clone();
    r.name = e;
    let a = [];
    for(let c = 0; c < r.tracks.length; ++c){
        let l = r.tracks[c], h = l.getValueSize(), u = [], d = [];
        for(let f = 0; f < l.times.length; ++f){
            let m = l.times[f] * i;
            if (!(m < t || m >= n)) {
                u.push(l.times[f]);
                for(let _ = 0; _ < h; ++_)d.push(l.values[f * h + _]);
            }
        }
        u.length !== 0 && (l.times = ni(u, l.times.constructor), l.values = ni(d, l.values.constructor), a.push(l));
    }
    r.tracks = a;
    let o = 1 / 0;
    for(let c = 0; c < r.tracks.length; ++c)o > r.tracks[c].times[0] && (o = r.tracks[c].times[0]);
    for(let c = 0; c < r.tracks.length; ++c)r.tracks[c].shift(-1 * o);
    return r.resetDuration(), r;
}
function Mx(s1, e = 0, t = s1, n = 30) {
    n <= 0 && (n = 30);
    let i = t.tracks.length, r = e / n;
    for(let a = 0; a < i; ++a){
        let o = t.tracks[a], c = o.ValueTypeName;
        if (c === "bool" || c === "string") continue;
        let l = s1.tracks.find(function(p) {
            return p.name === o.name && p.ValueTypeName === c;
        });
        if (l === void 0) continue;
        let h = 0, u = o.getValueSize();
        o.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline && (h = u / 3);
        let d = 0, f = l.getValueSize();
        l.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline && (d = f / 3);
        let m = o.times.length - 1, _;
        if (r <= o.times[0]) {
            let p = h, v = u - h;
            _ = o.values.slice(p, v);
        } else if (r >= o.times[m]) {
            let p = m * u + h, v = p + u - h;
            _ = o.values.slice(p, v);
        } else {
            let p = o.createInterpolant(), v = h, x = u - h;
            p.evaluate(r), _ = p.resultBuffer.slice(v, x);
        }
        c === "quaternion" && new Ut().fromArray(_).normalize().conjugate().toArray(_);
        let g = l.times.length;
        for(let p = 0; p < g; ++p){
            let v = p * f + d;
            if (c === "quaternion") Ut.multiplyQuaternionsFlat(l.values, v, _, 0, l.values, v);
            else {
                let x = f - d * 2;
                for(let y = 0; y < x; ++y)l.values[v + y] -= _[y];
            }
        }
    }
    return s1.blendMode = xd, s1;
}
var Sv = {
    convertArray: ni,
    isTypedArray: Ud,
    getKeyframeOrder: Dd,
    sortedArray: _c,
    flattenJSON: $c,
    subclip: yx,
    makeClipAdditive: Mx
}, es = class {
    constructor(e, t, n, i){
        this.parameterPositions = e, this._cachedIndex = 0, this.resultBuffer = i !== void 0 ? i : new t.constructor(n), this.sampleValues = t, this.valueSize = n, this.settings = null, this.DefaultSettings_ = {};
    }
    evaluate(e) {
        let t = this.parameterPositions, n = this._cachedIndex, i = t[n], r = t[n - 1];
        e: {
            t: {
                let a;
                n: {
                    i: if (!(e < i)) {
                        for(let o = n + 2;;){
                            if (i === void 0) {
                                if (e < r) break i;
                                return n = t.length, this._cachedIndex = n, this.copySampleValue_(n - 1);
                            }
                            if (n === o) break;
                            if (r = i, i = t[++n], e < i) break t;
                        }
                        a = t.length;
                        break n;
                    }
                    if (!(e >= r)) {
                        let o = t[1];
                        e < o && (n = 2, r = o);
                        for(let c = n - 2;;){
                            if (r === void 0) return this._cachedIndex = 0, this.copySampleValue_(0);
                            if (n === c) break;
                            if (i = r, r = t[--n - 1], e >= r) break t;
                        }
                        a = n, n = 0;
                        break n;
                    }
                    break e;
                }
                for(; n < a;){
                    let o = n + a >>> 1;
                    e < t[o] ? a = o : n = o + 1;
                }
                if (i = t[n], r = t[n - 1], r === void 0) return this._cachedIndex = 0, this.copySampleValue_(0);
                if (i === void 0) return n = t.length, this._cachedIndex = n, this.copySampleValue_(n - 1);
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
        for(let a = 0; a !== i; ++a)t[a] = n[r + a];
        return t;
    }
    interpolate_() {
        throw new Error("call to abstract method");
    }
    intervalChanged_() {}
}, xc = class extends es {
    constructor(e, t, n, i){
        super(e, t, n, i), this._weightPrev = -0, this._offsetPrev = -0, this._weightNext = -0, this._offsetNext = -0, this.DefaultSettings_ = {
            endingStart: zi,
            endingEnd: zi
        };
    }
    intervalChanged_(e, t, n) {
        let i = this.parameterPositions, r = e - 2, a = e + 1, o = i[r], c = i[a];
        if (o === void 0) switch(this.getSettings_().endingStart){
            case Vi:
                r = e, o = 2 * t - n;
                break;
            case Br:
                r = i.length - 2, o = t + i[r] - i[r + 1];
                break;
            default:
                r = e, o = n;
        }
        if (c === void 0) switch(this.getSettings_().endingEnd){
            case Vi:
                a = e, c = 2 * n - t;
                break;
            case Br:
                a = 1, c = n + i[1] - i[0];
                break;
            default:
                a = e - 1, c = t;
        }
        let l = (n - t) * .5, h = this.valueSize;
        this._weightPrev = l / (t - o), this._weightNext = l / (c - n), this._offsetPrev = r * h, this._offsetNext = a * h;
    }
    interpolate_(e, t, n, i) {
        let r = this.resultBuffer, a = this.sampleValues, o = this.valueSize, c = e * o, l = c - o, h = this._offsetPrev, u = this._offsetNext, d = this._weightPrev, f = this._weightNext, m = (n - t) / (i - t), _ = m * m, g = _ * m, p = -d * g + 2 * d * _ - d * m, v = (1 + d) * g + (-1.5 - 2 * d) * _ + (-.5 + d) * m + 1, x = (-1 - f) * g + (1.5 + f) * _ + .5 * m, y = f * g - f * _;
        for(let b = 0; b !== o; ++b)r[b] = p * a[h + b] + v * a[l + b] + x * a[c + b] + y * a[u + b];
        return r;
    }
}, fa = class extends es {
    constructor(e, t, n, i){
        super(e, t, n, i);
    }
    interpolate_(e, t, n, i) {
        let r = this.resultBuffer, a = this.sampleValues, o = this.valueSize, c = e * o, l = c - o, h = (n - t) / (i - t), u = 1 - h;
        for(let d = 0; d !== o; ++d)r[d] = a[l + d] * u + a[c + d] * h;
        return r;
    }
}, vc = class extends es {
    constructor(e, t, n, i){
        super(e, t, n, i);
    }
    interpolate_(e) {
        return this.copySampleValue_(e - 1);
    }
}, Jt = class {
    constructor(e, t, n, i){
        if (e === void 0) throw new Error("THREE.KeyframeTrack: track name is undefined");
        if (t === void 0 || t.length === 0) throw new Error("THREE.KeyframeTrack: no keyframes in track named " + e);
        this.name = e, this.times = ni(t, this.TimeBufferType), this.values = ni(n, this.ValueBufferType), this.setInterpolation(i || this.DefaultInterpolation);
    }
    static toJSON(e) {
        let t = e.constructor, n;
        if (t.toJSON !== this.toJSON) n = t.toJSON(e);
        else {
            n = {
                name: e.name,
                times: ni(e.times, Array),
                values: ni(e.values, Array)
            };
            let i = e.getInterpolation();
            i !== e.DefaultInterpolation && (n.interpolation = i);
        }
        return n.type = e.ValueTypeName, n;
    }
    InterpolantFactoryMethodDiscrete(e) {
        return new vc(this.times, this.values, this.getValueSize(), e);
    }
    InterpolantFactoryMethodLinear(e) {
        return new fa(this.times, this.values, this.getValueSize(), e);
    }
    InterpolantFactoryMethodSmooth(e) {
        return new xc(this.times, this.values, this.getValueSize(), e);
    }
    setInterpolation(e) {
        let t;
        switch(e){
            case Or:
                t = this.InterpolantFactoryMethodDiscrete;
                break;
            case Fr:
                t = this.InterpolantFactoryMethodLinear;
                break;
            case La:
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
                return Or;
            case this.InterpolantFactoryMethodLinear:
                return Fr;
            case this.InterpolantFactoryMethodSmooth:
                return La;
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
        let n = this.times, i = n.length, r = 0, a = i - 1;
        for(; r !== i && n[r] < e;)++r;
        for(; a !== -1 && n[a] > t;)--a;
        if (++a, r !== 0 || a !== i) {
            r >= a && (a = Math.max(a, 1), r = a - 1);
            let o = this.getValueSize();
            this.times = n.slice(r, a), this.values = this.values.slice(r * o, a * o);
        }
        return this;
    }
    validate() {
        let e = !0, t = this.getValueSize();
        t - Math.floor(t) !== 0 && (console.error("THREE.KeyframeTrack: Invalid value size in track.", this), e = !1);
        let n = this.times, i = this.values, r = n.length;
        r === 0 && (console.error("THREE.KeyframeTrack: Track is empty.", this), e = !1);
        let a = null;
        for(let o = 0; o !== r; o++){
            let c = n[o];
            if (typeof c == "number" && isNaN(c)) {
                console.error("THREE.KeyframeTrack: Time is not a valid number.", this, o, c), e = !1;
                break;
            }
            if (a !== null && a > c) {
                console.error("THREE.KeyframeTrack: Out of order keys.", this, o, c, a), e = !1;
                break;
            }
            a = c;
        }
        if (i !== void 0 && Ud(i)) for(let o = 0, c = i.length; o !== c; ++o){
            let l = i[o];
            if (isNaN(l)) {
                console.error("THREE.KeyframeTrack: Value is not a valid number.", this, o, l), e = !1;
                break;
            }
        }
        return e;
    }
    optimize() {
        let e = this.times.slice(), t = this.values.slice(), n = this.getValueSize(), i = this.getInterpolation() === La, r = e.length - 1, a = 1;
        for(let o = 1; o < r; ++o){
            let c = !1, l = e[o], h = e[o + 1];
            if (l !== h && (o !== 1 || l !== e[0])) if (i) c = !0;
            else {
                let u = o * n, d = u - n, f = u + n;
                for(let m = 0; m !== n; ++m){
                    let _ = t[u + m];
                    if (_ !== t[d + m] || _ !== t[f + m]) {
                        c = !0;
                        break;
                    }
                }
            }
            if (c) {
                if (o !== a) {
                    e[a] = e[o];
                    let u = o * n, d = a * n;
                    for(let f = 0; f !== n; ++f)t[d + f] = t[u + f];
                }
                ++a;
            }
        }
        if (r > 0) {
            e[a] = e[r];
            for(let o = r * n, c = a * n, l = 0; l !== n; ++l)t[c + l] = t[o + l];
            ++a;
        }
        return a !== e.length ? (this.times = e.slice(0, a), this.values = t.slice(0, a * n)) : (this.times = e, this.values = t), this;
    }
    clone() {
        let e = this.times.slice(), t = this.values.slice(), n = this.constructor, i = new n(this.name, e, t);
        return i.createInterpolant = this.createInterpolant, i;
    }
};
Jt.prototype.TimeBufferType = Float32Array;
Jt.prototype.ValueBufferType = Float32Array;
Jt.prototype.DefaultInterpolation = Fr;
var Vn = class extends Jt {
};
Vn.prototype.ValueTypeName = "bool";
Vn.prototype.ValueBufferType = Array;
Vn.prototype.DefaultInterpolation = Or;
Vn.prototype.InterpolantFactoryMethodLinear = void 0;
Vn.prototype.InterpolantFactoryMethodSmooth = void 0;
var pa = class extends Jt {
};
pa.prototype.ValueTypeName = "color";
var ts = class extends Jt {
};
ts.prototype.ValueTypeName = "number";
var yc = class extends es {
    constructor(e, t, n, i){
        super(e, t, n, i);
    }
    interpolate_(e, t, n, i) {
        let r = this.resultBuffer, a = this.sampleValues, o = this.valueSize, c = (n - t) / (i - t), l = e * o;
        for(let h = l + o; l !== h; l += 4)Ut.slerpFlat(r, 0, a, l - o, a, l, c);
        return r;
    }
}, pi = class extends Jt {
    InterpolantFactoryMethodLinear(e) {
        return new yc(this.times, this.values, this.getValueSize(), e);
    }
};
pi.prototype.ValueTypeName = "quaternion";
pi.prototype.DefaultInterpolation = Fr;
pi.prototype.InterpolantFactoryMethodSmooth = void 0;
var kn = class extends Jt {
};
kn.prototype.ValueTypeName = "string";
kn.prototype.ValueBufferType = Array;
kn.prototype.DefaultInterpolation = Or;
kn.prototype.InterpolantFactoryMethodLinear = void 0;
kn.prototype.InterpolantFactoryMethodSmooth = void 0;
var ns = class extends Jt {
};
ns.prototype.ValueTypeName = "vector";
var is = class {
    constructor(e, t = -1, n, i = Xc){
        this.name = e, this.tracks = n, this.duration = t, this.blendMode = i, this.uuid = kt(), this.duration < 0 && this.resetDuration();
    }
    static parse(e) {
        let t = [], n = e.tracks, i = 1 / (e.fps || 1);
        for(let a = 0, o = n.length; a !== o; ++a)t.push(bx(n[a]).scale(i));
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
        for(let r = 0, a = n.length; r !== a; ++r)t.push(Jt.toJSON(n[r]));
        return i;
    }
    static CreateFromMorphTargetSequence(e, t, n, i) {
        let r = t.length, a = [];
        for(let o = 0; o < r; o++){
            let c = [], l = [];
            c.push((o + r - 1) % r, o, (o + 1) % r), l.push(0, 1, 0);
            let h = Dd(c);
            c = _c(c, 1, h), l = _c(l, 1, h), !i && c[0] === 0 && (c.push(r), l.push(l[0])), a.push(new ts(".morphTargetInfluences[" + t[o].name + "]", c, l).scale(1 / n));
        }
        return new this(e, -1, a);
    }
    static findByName(e, t) {
        let n = e;
        if (!Array.isArray(e)) {
            let i = e;
            n = i.geometry && i.geometry.animations || i.animations;
        }
        for(let i = 0; i < n.length; i++)if (n[i].name === t) return n[i];
        return null;
    }
    static CreateClipsFromMorphTargetSequences(e, t, n) {
        let i = {}, r = /^([\w-]*?)([\d]+)$/;
        for(let o = 0, c = e.length; o < c; o++){
            let l = e[o], h = l.name.match(r);
            if (h && h.length > 1) {
                let u = h[1], d = i[u];
                d || (i[u] = d = []), d.push(l);
            }
        }
        let a = [];
        for(let o in i)a.push(this.CreateFromMorphTargetSequence(o, i[o], t, n));
        return a;
    }
    static parseAnimation(e, t) {
        if (!e) return console.error("THREE.AnimationClip: No animation in JSONLoader data."), null;
        let n = function(u, d, f, m, _) {
            if (f.length !== 0) {
                let g = [], p = [];
                $c(f, g, p, m), g.length !== 0 && _.push(new u(d, g, p));
            }
        }, i = [], r = e.name || "default", a = e.fps || 30, o = e.blendMode, c = e.length || -1, l = e.hierarchy || [];
        for(let u = 0; u < l.length; u++){
            let d = l[u].keys;
            if (!(!d || d.length === 0)) if (d[0].morphTargets) {
                let f = {}, m;
                for(m = 0; m < d.length; m++)if (d[m].morphTargets) for(let _ = 0; _ < d[m].morphTargets.length; _++)f[d[m].morphTargets[_]] = -1;
                for(let _ in f){
                    let g = [], p = [];
                    for(let v = 0; v !== d[m].morphTargets.length; ++v){
                        let x = d[m];
                        g.push(x.time), p.push(x.morphTarget === _ ? 1 : 0);
                    }
                    i.push(new ts(".morphTargetInfluence[" + _ + "]", g, p));
                }
                c = f.length * a;
            } else {
                let f = ".bones[" + t[u].name + "]";
                n(ns, f + ".position", d, "pos", i), n(pi, f + ".quaternion", d, "rot", i), n(ns, f + ".scale", d, "scl", i);
            }
        }
        return i.length === 0 ? null : new this(r, c, i, o);
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
function Sx(s1) {
    switch(s1.toLowerCase()){
        case "scalar":
        case "double":
        case "float":
        case "number":
        case "integer":
            return ts;
        case "vector":
        case "vector2":
        case "vector3":
        case "vector4":
            return ns;
        case "color":
            return pa;
        case "quaternion":
            return pi;
        case "bool":
        case "boolean":
            return Vn;
        case "string":
            return kn;
    }
    throw new Error("THREE.KeyframeTrack: Unsupported typeName: " + s1);
}
function bx(s1) {
    if (s1.type === void 0) throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");
    let e = Sx(s1.type);
    if (s1.times === void 0) {
        let t = [], n = [];
        $c(s1.keys, t, n, "value"), s1.times = t, s1.values = n;
    }
    return e.parse !== void 0 ? e.parse(s1) : new e(s1.name, s1.times, s1.values, s1.interpolation);
}
var ss = {
    enabled: !1,
    files: {},
    add: function(s1, e) {
        this.enabled !== !1 && (this.files[s1] = e);
    },
    get: function(s1) {
        if (this.enabled !== !1) return this.files[s1];
    },
    remove: function(s1) {
        delete this.files[s1];
    },
    clear: function() {
        this.files = {};
    }
}, ma = class {
    constructor(e, t, n){
        let i = this, r = !1, a = 0, o = 0, c, l = [];
        this.onStart = void 0, this.onLoad = e, this.onProgress = t, this.onError = n, this.itemStart = function(h) {
            o++, r === !1 && i.onStart !== void 0 && i.onStart(h, a, o), r = !0;
        }, this.itemEnd = function(h) {
            a++, i.onProgress !== void 0 && i.onProgress(h, a, o), a === o && (r = !1, i.onLoad !== void 0 && i.onLoad());
        }, this.itemError = function(h) {
            i.onError !== void 0 && i.onError(h);
        }, this.resolveURL = function(h) {
            return c ? c(h) : h;
        }, this.setURLModifier = function(h) {
            return c = h, this;
        }, this.addHandler = function(h, u) {
            return l.push(h, u), this;
        }, this.removeHandler = function(h) {
            let u = l.indexOf(h);
            return u !== -1 && l.splice(u, 2), this;
        }, this.getHandler = function(h) {
            for(let u = 0, d = l.length; u < d; u += 2){
                let f = l[u], m = l[u + 1];
                if (f.global && (f.lastIndex = 0), f.test(h)) return m;
            }
            return null;
        };
    }
}, Ex = new ma, Dt = class {
    constructor(e){
        this.manager = e !== void 0 ? e : Ex, this.crossOrigin = "anonymous", this.withCredentials = !1, this.path = "", this.resourcePath = "", this.requestHeader = {};
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
};
Dt.DEFAULT_MATERIAL_NAME = "__DEFAULT";
var fn = {}, Mc = class extends Error {
    constructor(e, t){
        super(e), this.response = t;
    }
}, rn = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        e === void 0 && (e = ""), this.path !== void 0 && (e = this.path + e), e = this.manager.resolveURL(e);
        let r = ss.get(e);
        if (r !== void 0) return this.manager.itemStart(e), setTimeout(()=>{
            t && t(r), this.manager.itemEnd(e);
        }, 0), r;
        if (fn[e] !== void 0) {
            fn[e].push({
                onLoad: t,
                onProgress: n,
                onError: i
            });
            return;
        }
        fn[e] = [], fn[e].push({
            onLoad: t,
            onProgress: n,
            onError: i
        });
        let a = new Request(e, {
            headers: new Headers(this.requestHeader),
            credentials: this.withCredentials ? "include" : "same-origin"
        }), o = this.mimeType, c = this.responseType;
        fetch(a).then((l)=>{
            if (l.status === 200 || l.status === 0) {
                if (l.status === 0 && console.warn("THREE.FileLoader: HTTP Status 0 received."), typeof ReadableStream > "u" || l.body === void 0 || l.body.getReader === void 0) return l;
                let h = fn[e], u = l.body.getReader(), d = l.headers.get("Content-Length") || l.headers.get("X-File-Size"), f = d ? parseInt(d) : 0, m = f !== 0, _ = 0, g = new ReadableStream({
                    start (p) {
                        v();
                        function v() {
                            u.read().then(({ done: x , value: y  })=>{
                                if (x) p.close();
                                else {
                                    _ += y.byteLength;
                                    let b = new ProgressEvent("progress", {
                                        lengthComputable: m,
                                        loaded: _,
                                        total: f
                                    });
                                    for(let w = 0, R = h.length; w < R; w++){
                                        let I = h[w];
                                        I.onProgress && I.onProgress(b);
                                    }
                                    p.enqueue(y), v();
                                }
                            });
                        }
                    }
                });
                return new Response(g);
            } else throw new Mc(`fetch for "${l.url}" responded with ${l.status}: ${l.statusText}`, l);
        }).then((l)=>{
            switch(c){
                case "arraybuffer":
                    return l.arrayBuffer();
                case "blob":
                    return l.blob();
                case "document":
                    return l.text().then((h)=>new DOMParser().parseFromString(h, o));
                case "json":
                    return l.json();
                default:
                    if (o === void 0) return l.text();
                    {
                        let u = /charset="?([^;"\s]*)"?/i.exec(o), d = u && u[1] ? u[1].toLowerCase() : void 0, f = new TextDecoder(d);
                        return l.arrayBuffer().then((m)=>f.decode(m));
                    }
            }
        }).then((l)=>{
            ss.add(e, l);
            let h = fn[e];
            delete fn[e];
            for(let u = 0, d = h.length; u < d; u++){
                let f = h[u];
                f.onLoad && f.onLoad(l);
            }
        }).catch((l)=>{
            let h = fn[e];
            if (h === void 0) throw this.manager.itemError(e), l;
            delete fn[e];
            for(let u = 0, d = h.length; u < d; u++){
                let f = h[u];
                f.onError && f.onError(l);
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
}, au = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, a = new rn(this.manager);
        a.setPath(this.path), a.setRequestHeader(this.requestHeader), a.setWithCredentials(this.withCredentials), a.load(e, function(o) {
            try {
                t(r.parse(JSON.parse(o)));
            } catch (c) {
                i ? i(c) : console.error(c), r.manager.itemError(e);
            }
        }, n, i);
    }
    parse(e) {
        let t = [];
        for(let n = 0; n < e.length; n++){
            let i = is.parse(e[n]);
            t.push(i);
        }
        return t;
    }
}, ou = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, a = [], o = new Us, c = new rn(this.manager);
        c.setPath(this.path), c.setResponseType("arraybuffer"), c.setRequestHeader(this.requestHeader), c.setWithCredentials(r.withCredentials);
        let l = 0;
        function h(u) {
            c.load(e[u], function(d) {
                let f = r.parse(d, !0);
                a[u] = {
                    width: f.width,
                    height: f.height,
                    format: f.format,
                    mipmaps: f.mipmaps
                }, l += 1, l === 6 && (f.mipmapCount === 1 && (o.minFilter = mt), o.image = a, o.format = f.format, o.needsUpdate = !0, t && t(o));
            }, n, i);
        }
        if (Array.isArray(e)) for(let u = 0, d = e.length; u < d; ++u)h(u);
        else c.load(e, function(u) {
            let d = r.parse(u, !0);
            if (d.isCubemap) {
                let f = d.mipmaps.length / d.mipmapCount;
                for(let m = 0; m < f; m++){
                    a[m] = {
                        mipmaps: []
                    };
                    for(let _ = 0; _ < d.mipmapCount; _++)a[m].mipmaps.push(d.mipmaps[m * d.mipmapCount + _]), a[m].format = d.format, a[m].width = d.width, a[m].height = d.height;
                }
                o.image = a;
            } else o.image.width = d.width, o.image.height = d.height, o.mipmaps = d.mipmaps;
            d.mipmapCount === 1 && (o.minFilter = mt), o.format = d.format, o.needsUpdate = !0, t && t(o);
        }, n, i);
        return o;
    }
}, rs = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        this.path !== void 0 && (e = this.path + e), e = this.manager.resolveURL(e);
        let r = this, a = ss.get(e);
        if (a !== void 0) return r.manager.itemStart(e), setTimeout(function() {
            t && t(a), r.manager.itemEnd(e);
        }, 0), a;
        let o = ws("img");
        function c() {
            h(), ss.add(e, this), t && t(this), r.manager.itemEnd(e);
        }
        function l(u) {
            h(), i && i(u), r.manager.itemError(e), r.manager.itemEnd(e);
        }
        function h() {
            o.removeEventListener("load", c, !1), o.removeEventListener("error", l, !1);
        }
        return o.addEventListener("load", c, !1), o.addEventListener("error", l, !1), e.slice(0, 5) !== "data:" && this.crossOrigin !== void 0 && (o.crossOrigin = this.crossOrigin), r.manager.itemStart(e), o.src = e, o;
    }
}, cu = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = new Ki;
        r.colorSpace = vt;
        let a = new rs(this.manager);
        a.setCrossOrigin(this.crossOrigin), a.setPath(this.path);
        let o = 0;
        function c(l) {
            a.load(e[l], function(h) {
                r.images[l] = h, o++, o === 6 && (r.needsUpdate = !0, t && t(r));
            }, void 0, i);
        }
        for(let l = 0; l < e.length; ++l)c(l);
        return r;
    }
}, lu = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, a = new oi, o = new rn(this.manager);
        return o.setResponseType("arraybuffer"), o.setRequestHeader(this.requestHeader), o.setPath(this.path), o.setWithCredentials(r.withCredentials), o.load(e, function(c) {
            let l;
            try {
                l = r.parse(c);
            } catch (h) {
                if (i !== void 0) i(h);
                else {
                    console.error(h);
                    return;
                }
            }
            l.image !== void 0 ? a.image = l.image : l.data !== void 0 && (a.image.width = l.width, a.image.height = l.height, a.image.data = l.data), a.wrapS = l.wrapS !== void 0 ? l.wrapS : It, a.wrapT = l.wrapT !== void 0 ? l.wrapT : It, a.magFilter = l.magFilter !== void 0 ? l.magFilter : mt, a.minFilter = l.minFilter !== void 0 ? l.minFilter : mt, a.anisotropy = l.anisotropy !== void 0 ? l.anisotropy : 1, l.colorSpace !== void 0 ? a.colorSpace = l.colorSpace : l.encoding !== void 0 && (a.encoding = l.encoding), l.flipY !== void 0 && (a.flipY = l.flipY), l.format !== void 0 && (a.format = l.format), l.type !== void 0 && (a.type = l.type), l.mipmaps !== void 0 && (a.mipmaps = l.mipmaps, a.minFilter = li), l.mipmapCount === 1 && (a.minFilter = mt), l.generateMipmaps !== void 0 && (a.generateMipmaps = l.generateMipmaps), a.needsUpdate = !0, t && t(a, l);
        }, n, i), a;
    }
}, hu = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = new St, a = new rs(this.manager);
        return a.setCrossOrigin(this.crossOrigin), a.setPath(this.path), a.load(e, function(o) {
            r.image = o, r.needsUpdate = !0, t !== void 0 && t(r);
        }, n, i), r;
    }
}, En = class extends Je {
    constructor(e, t = 1){
        super(), this.isLight = !0, this.type = "Light", this.color = new pe(e), this.intensity = t;
    }
    dispose() {}
    copy(e, t) {
        return super.copy(e, t), this.color.copy(e.color), this.intensity = e.intensity, this;
    }
    toJSON(e) {
        let t = super.toJSON(e);
        return t.object.color = this.color.getHex(), t.object.intensity = this.intensity, this.groundColor !== void 0 && (t.object.groundColor = this.groundColor.getHex()), this.distance !== void 0 && (t.object.distance = this.distance), this.angle !== void 0 && (t.object.angle = this.angle), this.decay !== void 0 && (t.object.decay = this.decay), this.penumbra !== void 0 && (t.object.penumbra = this.penumbra), this.shadow !== void 0 && (t.object.shadow = this.shadow.toJSON()), t;
    }
}, Sc = class extends En {
    constructor(e, t, n){
        super(e, n), this.isHemisphereLight = !0, this.type = "HemisphereLight", this.position.copy(Je.DEFAULT_UP), this.updateMatrix(), this.groundColor = new pe(t);
    }
    copy(e, t) {
        return super.copy(e, t), this.groundColor.copy(e.groundColor), this;
    }
}, oo = new ze, uu = new A, du = new A, zs = class {
    constructor(e){
        this.camera = e, this.bias = 0, this.normalBias = 0, this.radius = 1, this.blurSamples = 8, this.mapSize = new Z(512, 512), this.map = null, this.mapPass = null, this.matrix = new ze, this.autoUpdate = !0, this.needsUpdate = !1, this._frustum = new Ps, this._frameExtents = new Z(1, 1), this._viewportCount = 1, this._viewports = [
            new je(0, 0, 1, 1)
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
        uu.setFromMatrixPosition(e.matrixWorld), t.position.copy(uu), du.setFromMatrixPosition(e.target.matrixWorld), t.lookAt(du), t.updateMatrixWorld(), oo.multiplyMatrices(t.projectionMatrix, t.matrixWorldInverse), this._frustum.setFromProjectionMatrix(oo), n.set(.5, 0, 0, .5, 0, .5, 0, .5, 0, 0, .5, .5, 0, 0, 0, 1), n.multiply(oo);
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
}, bc = class extends zs {
    constructor(){
        super(new yt(50, 1, .5, 500)), this.isSpotLightShadow = !0, this.focus = 1;
    }
    updateMatrices(e) {
        let t = this.camera, n = Zi * 2 * e.angle * this.focus, i = this.mapSize.width / this.mapSize.height, r = e.distance || t.far;
        (n !== t.fov || i !== t.aspect || r !== t.far) && (t.fov = n, t.aspect = i, t.far = r, t.updateProjectionMatrix()), super.updateMatrices(e);
    }
    copy(e) {
        return super.copy(e), this.focus = e.focus, this;
    }
}, Ec = class extends En {
    constructor(e, t, n = 0, i = Math.PI / 3, r = 0, a = 2){
        super(e, t), this.isSpotLight = !0, this.type = "SpotLight", this.position.copy(Je.DEFAULT_UP), this.updateMatrix(), this.target = new Je, this.distance = n, this.angle = i, this.penumbra = r, this.decay = a, this.map = null, this.shadow = new bc;
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
    copy(e, t) {
        return super.copy(e, t), this.distance = e.distance, this.angle = e.angle, this.penumbra = e.penumbra, this.decay = e.decay, this.target = e.target.clone(), this.shadow = e.shadow.clone(), this;
    }
}, fu = new ze, _s = new A, co = new A, Tc = class extends zs {
    constructor(){
        super(new yt(90, 1, .5, 500)), this.isPointLightShadow = !0, this._frameExtents = new Z(4, 2), this._viewportCount = 6, this._viewports = [
            new je(2, 1, 1, 1),
            new je(0, 1, 1, 1),
            new je(3, 1, 1, 1),
            new je(1, 1, 1, 1),
            new je(3, 0, 1, 1),
            new je(1, 0, 1, 1)
        ], this._cubeDirections = [
            new A(1, 0, 0),
            new A(-1, 0, 0),
            new A(0, 0, 1),
            new A(0, 0, -1),
            new A(0, 1, 0),
            new A(0, -1, 0)
        ], this._cubeUps = [
            new A(0, 1, 0),
            new A(0, 1, 0),
            new A(0, 1, 0),
            new A(0, 1, 0),
            new A(0, 0, 1),
            new A(0, 0, -1)
        ];
    }
    updateMatrices(e, t = 0) {
        let n = this.camera, i = this.matrix, r = e.distance || n.far;
        r !== n.far && (n.far = r, n.updateProjectionMatrix()), _s.setFromMatrixPosition(e.matrixWorld), n.position.copy(_s), co.copy(n.position), co.add(this._cubeDirections[t]), n.up.copy(this._cubeUps[t]), n.lookAt(co), n.updateMatrixWorld(), i.makeTranslation(-_s.x, -_s.y, -_s.z), fu.multiplyMatrices(n.projectionMatrix, n.matrixWorldInverse), this._frustum.setFromProjectionMatrix(fu);
    }
}, wc = class extends En {
    constructor(e, t, n = 0, i = 2){
        super(e, t), this.isPointLight = !0, this.type = "PointLight", this.distance = n, this.decay = i, this.shadow = new Tc;
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
    copy(e, t) {
        return super.copy(e, t), this.distance = e.distance, this.decay = e.decay, this.shadow = e.shadow.clone(), this;
    }
}, Ac = class extends zs {
    constructor(){
        super(new Ls(-5, 5, 5, -5, .5, 500)), this.isDirectionalLightShadow = !0;
    }
}, Rc = class extends En {
    constructor(e, t){
        super(e, t), this.isDirectionalLight = !0, this.type = "DirectionalLight", this.position.copy(Je.DEFAULT_UP), this.updateMatrix(), this.target = new Je, this.shadow = new Ac;
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(e) {
        return super.copy(e), this.target = e.target.clone(), this.shadow = e.shadow.clone(), this;
    }
}, Cc = class extends En {
    constructor(e, t){
        super(e, t), this.isAmbientLight = !0, this.type = "AmbientLight";
    }
}, Pc = class extends En {
    constructor(e, t, n = 10, i = 10){
        super(e, t), this.isRectAreaLight = !0, this.type = "RectAreaLight", this.width = n, this.height = i;
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
}, Lc = class {
    constructor(){
        this.isSphericalHarmonics3 = !0, this.coefficients = [];
        for(let e = 0; e < 9; e++)this.coefficients.push(new A);
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
        let n = e.x, i = e.y, r = e.z, a = this.coefficients;
        return t.copy(a[0]).multiplyScalar(.282095), t.addScaledVector(a[1], .488603 * i), t.addScaledVector(a[2], .488603 * r), t.addScaledVector(a[3], .488603 * n), t.addScaledVector(a[4], 1.092548 * (n * i)), t.addScaledVector(a[5], 1.092548 * (i * r)), t.addScaledVector(a[6], .315392 * (3 * r * r - 1)), t.addScaledVector(a[7], 1.092548 * (n * r)), t.addScaledVector(a[8], .546274 * (n * n - i * i)), t;
    }
    getIrradianceAt(e, t) {
        let n = e.x, i = e.y, r = e.z, a = this.coefficients;
        return t.copy(a[0]).multiplyScalar(.886227), t.addScaledVector(a[1], 2 * .511664 * i), t.addScaledVector(a[2], 2 * .511664 * r), t.addScaledVector(a[3], 2 * .511664 * n), t.addScaledVector(a[4], 2 * .429043 * n * i), t.addScaledVector(a[5], 2 * .429043 * i * r), t.addScaledVector(a[6], .743125 * r * r - .247708), t.addScaledVector(a[7], 2 * .429043 * n * r), t.addScaledVector(a[8], .429043 * (n * n - i * i)), t;
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
}, Ic = class extends En {
    constructor(e = new Lc, t = 1){
        super(void 0, t), this.isLightProbe = !0, this.sh = e;
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
}, Uc = class s1 extends Dt {
    constructor(e){
        super(e), this.textures = {};
    }
    load(e, t, n, i) {
        let r = this, a = new rn(r.manager);
        a.setPath(r.path), a.setRequestHeader(r.requestHeader), a.setWithCredentials(r.withCredentials), a.load(e, function(o) {
            try {
                t(r.parse(JSON.parse(o)));
            } catch (c) {
                i ? i(c) : console.error(c), r.manager.itemError(e);
            }
        }, n, i);
    }
    parse(e) {
        let t = this.textures;
        function n(r) {
            return t[r] === void 0 && console.warn("THREE.MaterialLoader: Undefined texture", r), t[r];
        }
        let i = s1.createMaterialFromType(e.type);
        if (e.uuid !== void 0 && (i.uuid = e.uuid), e.name !== void 0 && (i.name = e.name), e.color !== void 0 && i.color !== void 0 && i.color.setHex(e.color), e.roughness !== void 0 && (i.roughness = e.roughness), e.metalness !== void 0 && (i.metalness = e.metalness), e.sheen !== void 0 && (i.sheen = e.sheen), e.sheenColor !== void 0 && (i.sheenColor = new pe().setHex(e.sheenColor)), e.sheenRoughness !== void 0 && (i.sheenRoughness = e.sheenRoughness), e.emissive !== void 0 && i.emissive !== void 0 && i.emissive.setHex(e.emissive), e.specular !== void 0 && i.specular !== void 0 && i.specular.setHex(e.specular), e.specularIntensity !== void 0 && (i.specularIntensity = e.specularIntensity), e.specularColor !== void 0 && i.specularColor !== void 0 && i.specularColor.setHex(e.specularColor), e.shininess !== void 0 && (i.shininess = e.shininess), e.clearcoat !== void 0 && (i.clearcoat = e.clearcoat), e.clearcoatRoughness !== void 0 && (i.clearcoatRoughness = e.clearcoatRoughness), e.iridescence !== void 0 && (i.iridescence = e.iridescence), e.iridescenceIOR !== void 0 && (i.iridescenceIOR = e.iridescenceIOR), e.iridescenceThicknessRange !== void 0 && (i.iridescenceThicknessRange = e.iridescenceThicknessRange), e.transmission !== void 0 && (i.transmission = e.transmission), e.thickness !== void 0 && (i.thickness = e.thickness), e.attenuationDistance !== void 0 && (i.attenuationDistance = e.attenuationDistance), e.attenuationColor !== void 0 && i.attenuationColor !== void 0 && i.attenuationColor.setHex(e.attenuationColor), e.anisotropy !== void 0 && (i.anisotropy = e.anisotropy), e.anisotropyRotation !== void 0 && (i.anisotropyRotation = e.anisotropyRotation), e.fog !== void 0 && (i.fog = e.fog), e.flatShading !== void 0 && (i.flatShading = e.flatShading), e.blending !== void 0 && (i.blending = e.blending), e.combine !== void 0 && (i.combine = e.combine), e.side !== void 0 && (i.side = e.side), e.shadowSide !== void 0 && (i.shadowSide = e.shadowSide), e.opacity !== void 0 && (i.opacity = e.opacity), e.transparent !== void 0 && (i.transparent = e.transparent), e.alphaTest !== void 0 && (i.alphaTest = e.alphaTest), e.alphaHash !== void 0 && (i.alphaHash = e.alphaHash), e.depthTest !== void 0 && (i.depthTest = e.depthTest), e.depthWrite !== void 0 && (i.depthWrite = e.depthWrite), e.colorWrite !== void 0 && (i.colorWrite = e.colorWrite), e.stencilWrite !== void 0 && (i.stencilWrite = e.stencilWrite), e.stencilWriteMask !== void 0 && (i.stencilWriteMask = e.stencilWriteMask), e.stencilFunc !== void 0 && (i.stencilFunc = e.stencilFunc), e.stencilRef !== void 0 && (i.stencilRef = e.stencilRef), e.stencilFuncMask !== void 0 && (i.stencilFuncMask = e.stencilFuncMask), e.stencilFail !== void 0 && (i.stencilFail = e.stencilFail), e.stencilZFail !== void 0 && (i.stencilZFail = e.stencilZFail), e.stencilZPass !== void 0 && (i.stencilZPass = e.stencilZPass), e.wireframe !== void 0 && (i.wireframe = e.wireframe), e.wireframeLinewidth !== void 0 && (i.wireframeLinewidth = e.wireframeLinewidth), e.wireframeLinecap !== void 0 && (i.wireframeLinecap = e.wireframeLinecap), e.wireframeLinejoin !== void 0 && (i.wireframeLinejoin = e.wireframeLinejoin), e.rotation !== void 0 && (i.rotation = e.rotation), e.linewidth !== void 0 && (i.linewidth = e.linewidth), e.dashSize !== void 0 && (i.dashSize = e.dashSize), e.gapSize !== void 0 && (i.gapSize = e.gapSize), e.scale !== void 0 && (i.scale = e.scale), e.polygonOffset !== void 0 && (i.polygonOffset = e.polygonOffset), e.polygonOffsetFactor !== void 0 && (i.polygonOffsetFactor = e.polygonOffsetFactor), e.polygonOffsetUnits !== void 0 && (i.polygonOffsetUnits = e.polygonOffsetUnits), e.dithering !== void 0 && (i.dithering = e.dithering), e.alphaToCoverage !== void 0 && (i.alphaToCoverage = e.alphaToCoverage), e.premultipliedAlpha !== void 0 && (i.premultipliedAlpha = e.premultipliedAlpha), e.forceSinglePass !== void 0 && (i.forceSinglePass = e.forceSinglePass), e.visible !== void 0 && (i.visible = e.visible), e.toneMapped !== void 0 && (i.toneMapped = e.toneMapped), e.userData !== void 0 && (i.userData = e.userData), e.vertexColors !== void 0 && (typeof e.vertexColors == "number" ? i.vertexColors = e.vertexColors > 0 : i.vertexColors = e.vertexColors), e.uniforms !== void 0) for(let r in e.uniforms){
            let a = e.uniforms[r];
            switch(i.uniforms[r] = {}, a.type){
                case "t":
                    i.uniforms[r].value = n(a.value);
                    break;
                case "c":
                    i.uniforms[r].value = new pe().setHex(a.value);
                    break;
                case "v2":
                    i.uniforms[r].value = new Z().fromArray(a.value);
                    break;
                case "v3":
                    i.uniforms[r].value = new A().fromArray(a.value);
                    break;
                case "v4":
                    i.uniforms[r].value = new je().fromArray(a.value);
                    break;
                case "m3":
                    i.uniforms[r].value = new He().fromArray(a.value);
                    break;
                case "m4":
                    i.uniforms[r].value = new ze().fromArray(a.value);
                    break;
                default:
                    i.uniforms[r].value = a.value;
            }
        }
        if (e.defines !== void 0 && (i.defines = e.defines), e.vertexShader !== void 0 && (i.vertexShader = e.vertexShader), e.fragmentShader !== void 0 && (i.fragmentShader = e.fragmentShader), e.glslVersion !== void 0 && (i.glslVersion = e.glslVersion), e.extensions !== void 0) for(let r in e.extensions)i.extensions[r] = e.extensions[r];
        if (e.lights !== void 0 && (i.lights = e.lights), e.clipping !== void 0 && (i.clipping = e.clipping), e.size !== void 0 && (i.size = e.size), e.sizeAttenuation !== void 0 && (i.sizeAttenuation = e.sizeAttenuation), e.map !== void 0 && (i.map = n(e.map)), e.matcap !== void 0 && (i.matcap = n(e.matcap)), e.alphaMap !== void 0 && (i.alphaMap = n(e.alphaMap)), e.bumpMap !== void 0 && (i.bumpMap = n(e.bumpMap)), e.bumpScale !== void 0 && (i.bumpScale = e.bumpScale), e.normalMap !== void 0 && (i.normalMap = n(e.normalMap)), e.normalMapType !== void 0 && (i.normalMapType = e.normalMapType), e.normalScale !== void 0) {
            let r = e.normalScale;
            Array.isArray(r) === !1 && (r = [
                r,
                r
            ]), i.normalScale = new Z().fromArray(r);
        }
        return e.displacementMap !== void 0 && (i.displacementMap = n(e.displacementMap)), e.displacementScale !== void 0 && (i.displacementScale = e.displacementScale), e.displacementBias !== void 0 && (i.displacementBias = e.displacementBias), e.roughnessMap !== void 0 && (i.roughnessMap = n(e.roughnessMap)), e.metalnessMap !== void 0 && (i.metalnessMap = n(e.metalnessMap)), e.emissiveMap !== void 0 && (i.emissiveMap = n(e.emissiveMap)), e.emissiveIntensity !== void 0 && (i.emissiveIntensity = e.emissiveIntensity), e.specularMap !== void 0 && (i.specularMap = n(e.specularMap)), e.specularIntensityMap !== void 0 && (i.specularIntensityMap = n(e.specularIntensityMap)), e.specularColorMap !== void 0 && (i.specularColorMap = n(e.specularColorMap)), e.envMap !== void 0 && (i.envMap = n(e.envMap)), e.envMapIntensity !== void 0 && (i.envMapIntensity = e.envMapIntensity), e.reflectivity !== void 0 && (i.reflectivity = e.reflectivity), e.refractionRatio !== void 0 && (i.refractionRatio = e.refractionRatio), e.lightMap !== void 0 && (i.lightMap = n(e.lightMap)), e.lightMapIntensity !== void 0 && (i.lightMapIntensity = e.lightMapIntensity), e.aoMap !== void 0 && (i.aoMap = n(e.aoMap)), e.aoMapIntensity !== void 0 && (i.aoMapIntensity = e.aoMapIntensity), e.gradientMap !== void 0 && (i.gradientMap = n(e.gradientMap)), e.clearcoatMap !== void 0 && (i.clearcoatMap = n(e.clearcoatMap)), e.clearcoatRoughnessMap !== void 0 && (i.clearcoatRoughnessMap = n(e.clearcoatRoughnessMap)), e.clearcoatNormalMap !== void 0 && (i.clearcoatNormalMap = n(e.clearcoatNormalMap)), e.clearcoatNormalScale !== void 0 && (i.clearcoatNormalScale = new Z().fromArray(e.clearcoatNormalScale)), e.iridescenceMap !== void 0 && (i.iridescenceMap = n(e.iridescenceMap)), e.iridescenceThicknessMap !== void 0 && (i.iridescenceThicknessMap = n(e.iridescenceThicknessMap)), e.transmissionMap !== void 0 && (i.transmissionMap = n(e.transmissionMap)), e.thicknessMap !== void 0 && (i.thicknessMap = n(e.thicknessMap)), e.anisotropyMap !== void 0 && (i.anisotropyMap = n(e.anisotropyMap)), e.sheenColorMap !== void 0 && (i.sheenColorMap = n(e.sheenColorMap)), e.sheenRoughnessMap !== void 0 && (i.sheenRoughnessMap = n(e.sheenRoughnessMap)), i;
    }
    setTextures(e) {
        return this.textures = e, this;
    }
    static createMaterialFromType(e) {
        let t = {
            ShadowMaterial: cc,
            SpriteMaterial: ea,
            RawShaderMaterial: lc,
            ShaderMaterial: jt,
            PointsMaterial: na,
            MeshPhysicalMaterial: hc,
            MeshStandardMaterial: da,
            MeshPhongMaterial: uc,
            MeshToonMaterial: dc,
            MeshNormalMaterial: fc,
            MeshLambertMaterial: pc,
            MeshDepthMaterial: Qr,
            MeshDistanceMaterial: jr,
            MeshBasicMaterial: Sn,
            MeshMatcapMaterial: mc,
            LineDashedMaterial: gc,
            LineBasicMaterial: wt,
            Material: bt
        };
        return new t[e];
    }
}, ga = class {
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
        return t === -1 ? "./" : e.slice(0, t + 1);
    }
    static resolveURL(e, t) {
        return typeof e != "string" || e === "" ? "" : (/^https?:\/\//i.test(t) && /^\//.test(e) && (t = t.replace(/(^https?:\/\/[^\/]+).*/i, "$1")), /^(https?:)?\/\//i.test(e) || /^data:.*,.*$/i.test(e) || /^blob:.*$/i.test(e) ? e : t + e);
    }
}, Dc = class extends Ge {
    constructor(){
        super(), this.isInstancedBufferGeometry = !0, this.type = "InstancedBufferGeometry", this.instanceCount = 1 / 0;
    }
    copy(e) {
        return super.copy(e), this.instanceCount = e.instanceCount, this;
    }
    toJSON() {
        let e = super.toJSON();
        return e.instanceCount = this.instanceCount, e.isInstancedBufferGeometry = !0, e;
    }
}, Nc = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, a = new rn(r.manager);
        a.setPath(r.path), a.setRequestHeader(r.requestHeader), a.setWithCredentials(r.withCredentials), a.load(e, function(o) {
            try {
                t(r.parse(JSON.parse(o)));
            } catch (c) {
                i ? i(c) : console.error(c), r.manager.itemError(e);
            }
        }, n, i);
    }
    parse(e) {
        let t = {}, n = {};
        function i(f, m) {
            if (t[m] !== void 0) return t[m];
            let g = f.interleavedBuffers[m], p = r(f, g.buffer), v = ki(g.type, p), x = new Is(v, g.stride);
            return x.uuid = g.uuid, t[m] = x, x;
        }
        function r(f, m) {
            if (n[m] !== void 0) return n[m];
            let g = f.arrayBuffers[m], p = new Uint32Array(g).buffer;
            return n[m] = p, p;
        }
        let a = e.isInstancedBufferGeometry ? new Dc : new Ge, o = e.data.index;
        if (o !== void 0) {
            let f = ki(o.type, o.array);
            a.setIndex(new et(f, 1));
        }
        let c = e.data.attributes;
        for(let f in c){
            let m = c[f], _;
            if (m.isInterleavedBufferAttribute) {
                let g = i(e.data, m.data);
                _ = new Qi(g, m.itemSize, m.offset, m.normalized);
            } else {
                let g = ki(m.type, m.array), p = m.isInstancedBufferAttribute ? ui : et;
                _ = new p(g, m.itemSize, m.normalized);
            }
            m.name !== void 0 && (_.name = m.name), m.usage !== void 0 && _.setUsage(m.usage), m.updateRange !== void 0 && (_.updateRange.offset = m.updateRange.offset, _.updateRange.count = m.updateRange.count), a.setAttribute(f, _);
        }
        let l = e.data.morphAttributes;
        if (l) for(let f in l){
            let m = l[f], _ = [];
            for(let g = 0, p = m.length; g < p; g++){
                let v = m[g], x;
                if (v.isInterleavedBufferAttribute) {
                    let y = i(e.data, v.data);
                    x = new Qi(y, v.itemSize, v.offset, v.normalized);
                } else {
                    let y = ki(v.type, v.array);
                    x = new et(y, v.itemSize, v.normalized);
                }
                v.name !== void 0 && (x.name = v.name), _.push(x);
            }
            a.morphAttributes[f] = _;
        }
        e.data.morphTargetsRelative && (a.morphTargetsRelative = !0);
        let u = e.data.groups || e.data.drawcalls || e.data.offsets;
        if (u !== void 0) for(let f = 0, m = u.length; f !== m; ++f){
            let _ = u[f];
            a.addGroup(_.start, _.count, _.materialIndex);
        }
        let d = e.data.boundingSphere;
        if (d !== void 0) {
            let f = new A;
            d.center !== void 0 && f.fromArray(d.center), a.boundingSphere = new Yt(f, d.radius);
        }
        return e.name && (a.name = e.name), e.userData && (a.userData = e.userData), a;
    }
}, pu = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, a = this.path === "" ? ga.extractUrlBase(e) : this.path;
        this.resourcePath = this.resourcePath || a;
        let o = new rn(this.manager);
        o.setPath(this.path), o.setRequestHeader(this.requestHeader), o.setWithCredentials(this.withCredentials), o.load(e, function(c) {
            let l = null;
            try {
                l = JSON.parse(c);
            } catch (u) {
                i !== void 0 && i(u), console.error("THREE:ObjectLoader: Can't parse " + e + ".", u.message);
                return;
            }
            let h = l.metadata;
            if (h === void 0 || h.type === void 0 || h.type.toLowerCase() === "geometry") {
                i !== void 0 && i(new Error("THREE.ObjectLoader: Can't load " + e)), console.error("THREE.ObjectLoader: Can't load " + e);
                return;
            }
            r.parse(l, t);
        }, n, i);
    }
    async loadAsync(e, t) {
        let n = this, i = this.path === "" ? ga.extractUrlBase(e) : this.path;
        this.resourcePath = this.resourcePath || i;
        let r = new rn(this.manager);
        r.setPath(this.path), r.setRequestHeader(this.requestHeader), r.setWithCredentials(this.withCredentials);
        let a = await r.loadAsync(e, t), o = JSON.parse(a), c = o.metadata;
        if (c === void 0 || c.type === void 0 || c.type.toLowerCase() === "geometry") throw new Error("THREE.ObjectLoader: Can't load " + e);
        return await n.parseAsync(o);
    }
    parse(e, t) {
        let n = this.parseAnimations(e.animations), i = this.parseShapes(e.shapes), r = this.parseGeometries(e.geometries, i), a = this.parseImages(e.images, function() {
            t !== void 0 && t(l);
        }), o = this.parseTextures(e.textures, a), c = this.parseMaterials(e.materials, o), l = this.parseObject(e.object, r, c, o, n), h = this.parseSkeletons(e.skeletons, l);
        if (this.bindSkeletons(l, h), t !== void 0) {
            let u = !1;
            for(let d in a)if (a[d].data instanceof HTMLImageElement) {
                u = !0;
                break;
            }
            u === !1 && t(l);
        }
        return l;
    }
    async parseAsync(e) {
        let t = this.parseAnimations(e.animations), n = this.parseShapes(e.shapes), i = this.parseGeometries(e.geometries, n), r = await this.parseImagesAsync(e.images), a = this.parseTextures(e.textures, r), o = this.parseMaterials(e.materials, a), c = this.parseObject(e.object, i, o, a, t), l = this.parseSkeletons(e.skeletons, c);
        return this.bindSkeletons(c, l), c;
    }
    parseShapes(e) {
        let t = {};
        if (e !== void 0) for(let n = 0, i = e.length; n < i; n++){
            let r = new Fn().fromJSON(e[n]);
            t[r.uuid] = r;
        }
        return t;
    }
    parseSkeletons(e, t) {
        let n = {}, i = {};
        if (t.traverse(function(r) {
            r.isBone && (i[r.uuid] = r);
        }), e !== void 0) for(let r = 0, a = e.length; r < a; r++){
            let o = new Oo().fromJSON(e[r], i);
            n[o.uuid] = o;
        }
        return n;
    }
    parseGeometries(e, t) {
        let n = {};
        if (e !== void 0) {
            let i = new Nc;
            for(let r = 0, a = e.length; r < a; r++){
                let o, c = e[r];
                switch(c.type){
                    case "BufferGeometry":
                    case "InstancedBufferGeometry":
                        o = i.parse(c);
                        break;
                    default:
                        c.type in ru ? o = ru[c.type].fromJSON(c, t) : console.warn(`THREE.ObjectLoader: Unsupported geometry type "${c.type}"`);
                }
                o.uuid = c.uuid, c.name !== void 0 && (o.name = c.name), c.userData !== void 0 && (o.userData = c.userData), n[c.uuid] = o;
            }
        }
        return n;
    }
    parseMaterials(e, t) {
        let n = {}, i = {};
        if (e !== void 0) {
            let r = new Uc;
            r.setTextures(t);
            for(let a = 0, o = e.length; a < o; a++){
                let c = e[a];
                n[c.uuid] === void 0 && (n[c.uuid] = r.parse(c)), i[c.uuid] = n[c.uuid];
            }
        }
        return i;
    }
    parseAnimations(e) {
        let t = {};
        if (e !== void 0) for(let n = 0; n < e.length; n++){
            let i = e[n], r = is.parse(i);
            t[r.uuid] = r;
        }
        return t;
    }
    parseImages(e, t) {
        let n = this, i = {}, r;
        function a(c) {
            return n.manager.itemStart(c), r.load(c, function() {
                n.manager.itemEnd(c);
            }, void 0, function() {
                n.manager.itemError(c), n.manager.itemEnd(c);
            });
        }
        function o(c) {
            if (typeof c == "string") {
                let l = c, h = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(l) ? l : n.resourcePath + l;
                return a(h);
            } else return c.data ? {
                data: ki(c.type, c.data),
                width: c.width,
                height: c.height
            } : null;
        }
        if (e !== void 0 && e.length > 0) {
            let c = new ma(t);
            r = new rs(c), r.setCrossOrigin(this.crossOrigin);
            for(let l = 0, h = e.length; l < h; l++){
                let u = e[l], d = u.url;
                if (Array.isArray(d)) {
                    let f = [];
                    for(let m = 0, _ = d.length; m < _; m++){
                        let g = d[m], p = o(g);
                        p !== null && (p instanceof HTMLImageElement ? f.push(p) : f.push(new oi(p.data, p.width, p.height)));
                    }
                    i[u.uuid] = new In(f);
                } else {
                    let f = o(u.url);
                    i[u.uuid] = new In(f);
                }
            }
        }
        return i;
    }
    async parseImagesAsync(e) {
        let t = this, n = {}, i;
        async function r(a) {
            if (typeof a == "string") {
                let o = a, c = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(o) ? o : t.resourcePath + o;
                return await i.loadAsync(c);
            } else return a.data ? {
                data: ki(a.type, a.data),
                width: a.width,
                height: a.height
            } : null;
        }
        if (e !== void 0 && e.length > 0) {
            i = new rs(this.manager), i.setCrossOrigin(this.crossOrigin);
            for(let a = 0, o = e.length; a < o; a++){
                let c = e[a], l = c.url;
                if (Array.isArray(l)) {
                    let h = [];
                    for(let u = 0, d = l.length; u < d; u++){
                        let f = l[u], m = await r(f);
                        m !== null && (m instanceof HTMLImageElement ? h.push(m) : h.push(new oi(m.data, m.width, m.height)));
                    }
                    n[c.uuid] = new In(h);
                } else {
                    let h = await r(c.url);
                    n[c.uuid] = new In(h);
                }
            }
        }
        return n;
    }
    parseTextures(e, t) {
        function n(r, a) {
            return typeof r == "number" ? r : (console.warn("THREE.ObjectLoader.parseTexture: Constant should be in numeric form.", r), a[r]);
        }
        let i = {};
        if (e !== void 0) for(let r = 0, a = e.length; r < a; r++){
            let o = e[r];
            o.image === void 0 && console.warn('THREE.ObjectLoader: No "image" specified for', o.uuid), t[o.image] === void 0 && console.warn("THREE.ObjectLoader: Undefined image", o.image);
            let c = t[o.image], l = c.data, h;
            Array.isArray(l) ? (h = new Ki, l.length === 6 && (h.needsUpdate = !0)) : (l && l.data ? h = new oi : h = new St, l && (h.needsUpdate = !0)), h.source = c, h.uuid = o.uuid, o.name !== void 0 && (h.name = o.name), o.mapping !== void 0 && (h.mapping = n(o.mapping, Tx)), o.channel !== void 0 && (h.channel = o.channel), o.offset !== void 0 && h.offset.fromArray(o.offset), o.repeat !== void 0 && h.repeat.fromArray(o.repeat), o.center !== void 0 && h.center.fromArray(o.center), o.rotation !== void 0 && (h.rotation = o.rotation), o.wrap !== void 0 && (h.wrapS = n(o.wrap[0], mu), h.wrapT = n(o.wrap[1], mu)), o.format !== void 0 && (h.format = o.format), o.internalFormat !== void 0 && (h.internalFormat = o.internalFormat), o.type !== void 0 && (h.type = o.type), o.colorSpace !== void 0 && (h.colorSpace = o.colorSpace), o.encoding !== void 0 && (h.encoding = o.encoding), o.minFilter !== void 0 && (h.minFilter = n(o.minFilter, gu)), o.magFilter !== void 0 && (h.magFilter = n(o.magFilter, gu)), o.anisotropy !== void 0 && (h.anisotropy = o.anisotropy), o.flipY !== void 0 && (h.flipY = o.flipY), o.generateMipmaps !== void 0 && (h.generateMipmaps = o.generateMipmaps), o.premultiplyAlpha !== void 0 && (h.premultiplyAlpha = o.premultiplyAlpha), o.unpackAlignment !== void 0 && (h.unpackAlignment = o.unpackAlignment), o.compareFunction !== void 0 && (h.compareFunction = o.compareFunction), o.userData !== void 0 && (h.userData = o.userData), i[o.uuid] = h;
        }
        return i;
    }
    parseObject(e, t, n, i, r) {
        let a;
        function o(d) {
            return t[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined geometry", d), t[d];
        }
        function c(d) {
            if (d !== void 0) {
                if (Array.isArray(d)) {
                    let f = [];
                    for(let m = 0, _ = d.length; m < _; m++){
                        let g = d[m];
                        n[g] === void 0 && console.warn("THREE.ObjectLoader: Undefined material", g), f.push(n[g]);
                    }
                    return f;
                }
                return n[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined material", d), n[d];
            }
        }
        function l(d) {
            return i[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined texture", d), i[d];
        }
        let h, u;
        switch(e.type){
            case "Scene":
                a = new Io, e.background !== void 0 && (Number.isInteger(e.background) ? a.background = new pe(e.background) : a.background = l(e.background)), e.environment !== void 0 && (a.environment = l(e.environment)), e.fog !== void 0 && (e.fog.type === "Fog" ? a.fog = new Lo(e.fog.color, e.fog.near, e.fog.far) : e.fog.type === "FogExp2" && (a.fog = new Po(e.fog.color, e.fog.density)), e.fog.name !== "" && (a.fog.name = e.fog.name)), e.backgroundBlurriness !== void 0 && (a.backgroundBlurriness = e.backgroundBlurriness), e.backgroundIntensity !== void 0 && (a.backgroundIntensity = e.backgroundIntensity);
                break;
            case "PerspectiveCamera":
                a = new yt(e.fov, e.aspect, e.near, e.far), e.focus !== void 0 && (a.focus = e.focus), e.zoom !== void 0 && (a.zoom = e.zoom), e.filmGauge !== void 0 && (a.filmGauge = e.filmGauge), e.filmOffset !== void 0 && (a.filmOffset = e.filmOffset), e.view !== void 0 && (a.view = Object.assign({}, e.view));
                break;
            case "OrthographicCamera":
                a = new Ls(e.left, e.right, e.top, e.bottom, e.near, e.far), e.zoom !== void 0 && (a.zoom = e.zoom), e.view !== void 0 && (a.view = Object.assign({}, e.view));
                break;
            case "AmbientLight":
                a = new Cc(e.color, e.intensity);
                break;
            case "DirectionalLight":
                a = new Rc(e.color, e.intensity);
                break;
            case "PointLight":
                a = new wc(e.color, e.intensity, e.distance, e.decay);
                break;
            case "RectAreaLight":
                a = new Pc(e.color, e.intensity, e.width, e.height);
                break;
            case "SpotLight":
                a = new Ec(e.color, e.intensity, e.distance, e.angle, e.penumbra, e.decay);
                break;
            case "HemisphereLight":
                a = new Sc(e.color, e.groundColor, e.intensity);
                break;
            case "LightProbe":
                a = new Ic().fromJSON(e);
                break;
            case "SkinnedMesh":
                h = o(e.geometry), u = c(e.material), a = new No(h, u), e.bindMode !== void 0 && (a.bindMode = e.bindMode), e.bindMatrix !== void 0 && a.bindMatrix.fromArray(e.bindMatrix), e.skeleton !== void 0 && (a.skeleton = e.skeleton);
                break;
            case "Mesh":
                h = o(e.geometry), u = c(e.material), a = new Mt(h, u);
                break;
            case "InstancedMesh":
                h = o(e.geometry), u = c(e.material);
                let d = e.count, f = e.instanceMatrix, m = e.instanceColor;
                a = new Fo(h, u, d), a.instanceMatrix = new ui(new Float32Array(f.array), 16), m !== void 0 && (a.instanceColor = new ui(new Float32Array(m.array), m.itemSize));
                break;
            case "LOD":
                a = new Do;
                break;
            case "Line":
                a = new bn(o(e.geometry), c(e.material));
                break;
            case "LineLoop":
                a = new Bo(o(e.geometry), c(e.material));
                break;
            case "LineSegments":
                a = new en(o(e.geometry), c(e.material));
                break;
            case "PointCloud":
            case "Points":
                a = new Vo(o(e.geometry), c(e.material));
                break;
            case "Sprite":
                a = new Uo(c(e.material));
                break;
            case "Group":
                a = new ti;
                break;
            case "Bone":
                a = new ta;
                break;
            default:
                a = new Je;
        }
        if (a.uuid = e.uuid, e.name !== void 0 && (a.name = e.name), e.matrix !== void 0 ? (a.matrix.fromArray(e.matrix), e.matrixAutoUpdate !== void 0 && (a.matrixAutoUpdate = e.matrixAutoUpdate), a.matrixAutoUpdate && a.matrix.decompose(a.position, a.quaternion, a.scale)) : (e.position !== void 0 && a.position.fromArray(e.position), e.rotation !== void 0 && a.rotation.fromArray(e.rotation), e.quaternion !== void 0 && a.quaternion.fromArray(e.quaternion), e.scale !== void 0 && a.scale.fromArray(e.scale)), e.up !== void 0 && a.up.fromArray(e.up), e.castShadow !== void 0 && (a.castShadow = e.castShadow), e.receiveShadow !== void 0 && (a.receiveShadow = e.receiveShadow), e.shadow && (e.shadow.bias !== void 0 && (a.shadow.bias = e.shadow.bias), e.shadow.normalBias !== void 0 && (a.shadow.normalBias = e.shadow.normalBias), e.shadow.radius !== void 0 && (a.shadow.radius = e.shadow.radius), e.shadow.mapSize !== void 0 && a.shadow.mapSize.fromArray(e.shadow.mapSize), e.shadow.camera !== void 0 && (a.shadow.camera = this.parseObject(e.shadow.camera))), e.visible !== void 0 && (a.visible = e.visible), e.frustumCulled !== void 0 && (a.frustumCulled = e.frustumCulled), e.renderOrder !== void 0 && (a.renderOrder = e.renderOrder), e.userData !== void 0 && (a.userData = e.userData), e.layers !== void 0 && (a.layers.mask = e.layers), e.children !== void 0) {
            let d = e.children;
            for(let f = 0; f < d.length; f++)a.add(this.parseObject(d[f], t, n, i, r));
        }
        if (e.animations !== void 0) {
            let d = e.animations;
            for(let f = 0; f < d.length; f++){
                let m = d[f];
                a.animations.push(r[m]);
            }
        }
        if (e.type === "LOD") {
            e.autoUpdate !== void 0 && (a.autoUpdate = e.autoUpdate);
            let d = e.levels;
            for(let f = 0; f < d.length; f++){
                let m = d[f], _ = a.getObjectByProperty("uuid", m.object);
                _ !== void 0 && a.addLevel(_, m.distance, m.hysteresis);
            }
        }
        return a;
    }
    bindSkeletons(e, t) {
        Object.keys(t).length !== 0 && e.traverse(function(n) {
            if (n.isSkinnedMesh === !0 && n.skeleton !== void 0) {
                let i = t[n.skeleton];
                i === void 0 ? console.warn("THREE.ObjectLoader: No skeleton found with UUID:", n.skeleton) : n.bind(i, n.bindMatrix);
            }
        });
    }
}, Tx = {
    UVMapping: Gc,
    CubeReflectionMapping: zn,
    CubeRefractionMapping: ci,
    EquirectangularReflectionMapping: Ir,
    EquirectangularRefractionMapping: Ur,
    CubeUVReflectionMapping: Vs
}, mu = {
    RepeatWrapping: Dr,
    ClampToEdgeWrapping: It,
    MirroredRepeatWrapping: Nr
}, gu = {
    NearestFilter: pt,
    NearestMipmapNearestFilter: fo,
    NearestMipmapLinearFilter: Lr,
    LinearFilter: mt,
    LinearMipmapNearestFilter: ud,
    LinearMipmapLinearFilter: li
}, _u = class extends Dt {
    constructor(e){
        super(e), this.isImageBitmapLoader = !0, typeof createImageBitmap > "u" && console.warn("THREE.ImageBitmapLoader: createImageBitmap() not supported."), typeof fetch > "u" && console.warn("THREE.ImageBitmapLoader: fetch() not supported."), this.options = {
            premultiplyAlpha: "none"
        };
    }
    setOptions(e) {
        return this.options = e, this;
    }
    load(e, t, n, i) {
        e === void 0 && (e = ""), this.path !== void 0 && (e = this.path + e), e = this.manager.resolveURL(e);
        let r = this, a = ss.get(e);
        if (a !== void 0) return r.manager.itemStart(e), setTimeout(function() {
            t && t(a), r.manager.itemEnd(e);
        }, 0), a;
        let o = {};
        o.credentials = this.crossOrigin === "anonymous" ? "same-origin" : "include", o.headers = this.requestHeader, fetch(e, o).then(function(c) {
            return c.blob();
        }).then(function(c) {
            return createImageBitmap(c, Object.assign(r.options, {
                colorSpaceConversion: "none"
            }));
        }).then(function(c) {
            ss.add(e, c), t && t(c), r.manager.itemEnd(e);
        }).catch(function(c) {
            i && i(c), r.manager.itemError(e), r.manager.itemEnd(e);
        }), r.manager.itemStart(e);
    }
}, Er, _a = class {
    static getContext() {
        return Er === void 0 && (Er = new (window.AudioContext || window.webkitAudioContext)), Er;
    }
    static setContext(e) {
        Er = e;
    }
}, xu = class extends Dt {
    constructor(e){
        super(e);
    }
    load(e, t, n, i) {
        let r = this, a = new rn(this.manager);
        a.setResponseType("arraybuffer"), a.setPath(this.path), a.setRequestHeader(this.requestHeader), a.setWithCredentials(this.withCredentials), a.load(e, function(c) {
            try {
                let l = c.slice(0);
                _a.getContext().decodeAudioData(l, function(u) {
                    t(u);
                }, o);
            } catch (l) {
                o(l);
            }
        }, n, i);
        function o(c) {
            i ? i(c) : console.error(c), r.manager.itemError(e);
        }
    }
}, vu = new ze, yu = new ze, Zn = new ze, Mu = class {
    constructor(){
        this.type = "StereoCamera", this.aspect = 1, this.eyeSep = .064, this.cameraL = new yt, this.cameraL.layers.enable(1), this.cameraL.matrixAutoUpdate = !1, this.cameraR = new yt, this.cameraR.layers.enable(2), this.cameraR.matrixAutoUpdate = !1, this._cache = {
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
            t.focus = e.focus, t.fov = e.fov, t.aspect = e.aspect * this.aspect, t.near = e.near, t.far = e.far, t.zoom = e.zoom, t.eyeSep = this.eyeSep, Zn.copy(e.projectionMatrix);
            let i = t.eyeSep / 2, r = i * t.near / t.focus, a = t.near * Math.tan(ai * t.fov * .5) / t.zoom, o, c;
            yu.elements[12] = -i, vu.elements[12] = i, o = -a * t.aspect + r, c = a * t.aspect + r, Zn.elements[0] = 2 * t.near / (c - o), Zn.elements[8] = (c + o) / (c - o), this.cameraL.projectionMatrix.copy(Zn), o = -a * t.aspect - r, c = a * t.aspect - r, Zn.elements[0] = 2 * t.near / (c - o), Zn.elements[8] = (c + o) / (c - o), this.cameraR.projectionMatrix.copy(Zn);
        }
        this.cameraL.matrixWorld.copy(e.matrixWorld).multiply(yu), this.cameraR.matrixWorld.copy(e.matrixWorld).multiply(vu);
    }
}, Oc = class {
    constructor(e = !0){
        this.autoStart = e, this.startTime = 0, this.oldTime = 0, this.elapsedTime = 0, this.running = !1;
    }
    start() {
        this.startTime = Su(), this.oldTime = this.startTime, this.elapsedTime = 0, this.running = !0;
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
            let t = Su();
            e = (t - this.oldTime) / 1e3, this.oldTime = t, this.elapsedTime += e;
        }
        return e;
    }
};
function Su() {
    return (typeof performance > "u" ? Date : performance).now();
}
var Jn = new A, bu = new Ut, wx = new A, $n = new A, Eu = class extends Je {
    constructor(){
        super(), this.type = "AudioListener", this.context = _a.getContext(), this.gain = this.context.createGain(), this.gain.connect(this.context.destination), this.filter = null, this.timeDelta = 0, this._clock = new Oc;
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
        if (this.timeDelta = this._clock.getDelta(), this.matrixWorld.decompose(Jn, bu, wx), $n.set(0, 0, -1).applyQuaternion(bu), t.positionX) {
            let i = this.context.currentTime + this.timeDelta;
            t.positionX.linearRampToValueAtTime(Jn.x, i), t.positionY.linearRampToValueAtTime(Jn.y, i), t.positionZ.linearRampToValueAtTime(Jn.z, i), t.forwardX.linearRampToValueAtTime($n.x, i), t.forwardY.linearRampToValueAtTime($n.y, i), t.forwardZ.linearRampToValueAtTime($n.z, i), t.upX.linearRampToValueAtTime(n.x, i), t.upY.linearRampToValueAtTime(n.y, i), t.upZ.linearRampToValueAtTime(n.z, i);
        } else t.setPosition(Jn.x, Jn.y, Jn.z), t.setOrientation($n.x, $n.y, $n.z, n.x, n.y, n.z);
    }
}, Fc = class extends Je {
    constructor(e){
        super(), this.type = "Audio", this.listener = e, this.context = e.context, this.gain = this.context.createGain(), this.gain.connect(e.getInput()), this.autoplay = !1, this.buffer = null, this.detune = 0, this.loop = !1, this.loopStart = 0, this.loopEnd = 0, this.offset = 0, this.duration = void 0, this.playbackRate = 1, this.isPlaying = !1, this.hasPlaybackControl = !0, this.source = null, this.sourceType = "empty", this._startedAt = 0, this._progress = 0, this._connected = !1, this.filters = [];
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
        return this._progress = 0, this.source !== null && (this.source.stop(), this.source.onended = null), this.isPlaying = !1, this;
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
        if (this._connected !== !1) {
            if (this.filters.length > 0) {
                this.source.disconnect(this.filters[0]);
                for(let e = 1, t = this.filters.length; e < t; e++)this.filters[e - 1].disconnect(this.filters[e]);
                this.filters[this.filters.length - 1].disconnect(this.getOutput());
            } else this.source.disconnect(this.getOutput());
            return this._connected = !1, this;
        }
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
}, Kn = new A, Tu = new Ut, Ax = new A, Qn = new A, wu = class extends Fc {
    constructor(e){
        super(e), this.panner = this.context.createPanner(), this.panner.panningModel = "HRTF", this.panner.connect(this.gain);
    }
    connect() {
        super.connect(), this.panner.connect(this.gain);
    }
    disconnect() {
        super.disconnect(), this.panner.disconnect(this.gain);
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
        this.matrixWorld.decompose(Kn, Tu, Ax), Qn.set(0, 0, 1).applyQuaternion(Tu);
        let t = this.panner;
        if (t.positionX) {
            let n = this.context.currentTime + this.listener.timeDelta;
            t.positionX.linearRampToValueAtTime(Kn.x, n), t.positionY.linearRampToValueAtTime(Kn.y, n), t.positionZ.linearRampToValueAtTime(Kn.z, n), t.orientationX.linearRampToValueAtTime(Qn.x, n), t.orientationY.linearRampToValueAtTime(Qn.y, n), t.orientationZ.linearRampToValueAtTime(Qn.z, n);
        } else t.setPosition(Kn.x, Kn.y, Kn.z), t.setOrientation(Qn.x, Qn.y, Qn.z);
    }
}, Au = class {
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
}, Bc = class {
    constructor(e, t, n){
        this.binding = e, this.valueSize = n;
        let i, r, a;
        switch(t){
            case "quaternion":
                i = this._slerp, r = this._slerpAdditive, a = this._setAdditiveIdentityQuaternion, this.buffer = new Float64Array(n * 6), this._workIndex = 5;
                break;
            case "string":
            case "bool":
                i = this._select, r = this._select, a = this._setAdditiveIdentityOther, this.buffer = new Array(n * 5);
                break;
            default:
                i = this._lerp, r = this._lerpAdditive, a = this._setAdditiveIdentityNumeric, this.buffer = new Float64Array(n * 5);
        }
        this._mixBufferRegion = i, this._mixBufferRegionAdditive = r, this._setIdentity = a, this._origIndex = 3, this._addIndex = 4, this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0, this.useCount = 0, this.referenceCount = 0;
    }
    accumulate(e, t) {
        let n = this.buffer, i = this.valueSize, r = e * i + i, a = this.cumulativeWeight;
        if (a === 0) {
            for(let o = 0; o !== i; ++o)n[r + o] = n[o];
            a = t;
        } else {
            a += t;
            let o = t / a;
            this._mixBufferRegion(n, r, 0, o, i);
        }
        this.cumulativeWeight = a;
    }
    accumulateAdditive(e) {
        let t = this.buffer, n = this.valueSize, i = n * this._addIndex;
        this.cumulativeWeightAdditive === 0 && this._setIdentity(), this._mixBufferRegionAdditive(t, i, 0, e, n), this.cumulativeWeightAdditive += e;
    }
    apply(e) {
        let t = this.valueSize, n = this.buffer, i = e * t + t, r = this.cumulativeWeight, a = this.cumulativeWeightAdditive, o = this.binding;
        if (this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0, r < 1) {
            let c = t * this._origIndex;
            this._mixBufferRegion(n, i, c, 1 - r, t);
        }
        a > 0 && this._mixBufferRegionAdditive(n, i, this._addIndex * t, 1, t);
        for(let c = t, l = t + t; c !== l; ++c)if (n[c] !== n[c + t]) {
            o.setValue(n, i);
            break;
        }
    }
    saveOriginalState() {
        let e = this.binding, t = this.buffer, n = this.valueSize, i = n * this._origIndex;
        e.getValue(t, i);
        for(let r = n, a = i; r !== a; ++r)t[r] = t[i + r % n];
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
        if (i >= .5) for(let a = 0; a !== r; ++a)e[t + a] = e[n + a];
    }
    _slerp(e, t, n, i) {
        Ut.slerpFlat(e, t, e, t, e, n, i);
    }
    _slerpAdditive(e, t, n, i, r) {
        let a = this._workIndex * r;
        Ut.multiplyQuaternionsFlat(e, a, e, t, e, n), Ut.slerpFlat(e, t, e, t, e, a, i);
    }
    _lerp(e, t, n, i, r) {
        let a = 1 - i;
        for(let o = 0; o !== r; ++o){
            let c = t + o;
            e[c] = e[c] * a + e[n + o] * i;
        }
    }
    _lerpAdditive(e, t, n, i, r) {
        for(let a = 0; a !== r; ++a){
            let o = t + a;
            e[o] = e[o] + e[n + a] * i;
        }
    }
}, Kc = "\\[\\]\\.:\\/", Rx = new RegExp("[" + Kc + "]", "g"), Qc = "[^" + Kc + "]", Cx = "[^" + Kc.replace("\\.", "") + "]", Px = /((?:WC+[\/:])*)/.source.replace("WC", Qc), Lx = /(WCOD+)?/.source.replace("WCOD", Cx), Ix = /(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC", Qc), Ux = /\.(WC+)(?:\[(.+)\])?/.source.replace("WC", Qc), Dx = new RegExp("^" + Px + Lx + Ix + Ux + "$"), Nx = [
    "material",
    "materials",
    "bones",
    "map"
], zc = class {
    constructor(e, t, n){
        let i = n || Ke.parseTrackName(t);
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
}, Ke = class s1 {
    constructor(e, t, n){
        this.path = t, this.parsedPath = n || s1.parseTrackName(t), this.node = s1.findNode(e, this.parsedPath.nodeName), this.rootNode = e, this.getValue = this._getValue_unbound, this.setValue = this._setValue_unbound;
    }
    static create(e, t, n) {
        return e && e.isAnimationObjectGroup ? new s1.Composite(e, t, n) : new s1(e, t, n);
    }
    static sanitizeNodeName(e) {
        return e.replace(/\s/g, "_").replace(Rx, "");
    }
    static parseTrackName(e) {
        let t = Dx.exec(e);
        if (t === null) throw new Error("PropertyBinding: Cannot parse trackName: " + e);
        let n = {
            nodeName: t[2],
            objectName: t[3],
            objectIndex: t[4],
            propertyName: t[5],
            propertyIndex: t[6]
        }, i = n.nodeName && n.nodeName.lastIndexOf(".");
        if (i !== void 0 && i !== -1) {
            let r = n.nodeName.substring(i + 1);
            Nx.indexOf(r) !== -1 && (n.nodeName = n.nodeName.substring(0, i), n.objectName = r);
        }
        if (n.propertyName === null || n.propertyName.length === 0) throw new Error("PropertyBinding: can not parse propertyName from trackName: " + e);
        return n;
    }
    static findNode(e, t) {
        if (t === void 0 || t === "" || t === "." || t === -1 || t === e.name || t === e.uuid) return e;
        if (e.skeleton) {
            let n = e.skeleton.getBoneByName(t);
            if (n !== void 0) return n;
        }
        if (e.children) {
            let n = function(r) {
                for(let a = 0; a < r.length; a++){
                    let o = r[a];
                    if (o.name === t || o.uuid === t) return o;
                    let c = n(o.children);
                    if (c) return c;
                }
                return null;
            }, i = n(e.children);
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
        if (e || (e = s1.findNode(this.rootNode, t.nodeName), this.node = e), this.getValue = this._getValue_unavailable, this.setValue = this._setValue_unavailable, !e) {
            console.warn("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
            return;
        }
        if (n) {
            let l = t.objectIndex;
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
                    for(let h = 0; h < e.length; h++)if (e[h].name === l) {
                        l = h;
                        break;
                    }
                    break;
                case "map":
                    if ("map" in e) {
                        e = e.map;
                        break;
                    }
                    if (!e.material) {
                        console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
                        return;
                    }
                    if (!e.material.map) {
                        console.error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.", this);
                        return;
                    }
                    e = e.material.map;
                    break;
                default:
                    if (e[n] === void 0) {
                        console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
                        return;
                    }
                    e = e[n];
            }
            if (l !== void 0) {
                if (e[l] === void 0) {
                    console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, e);
                    return;
                }
                e = e[l];
            }
        }
        let a = e[i];
        if (a === void 0) {
            let l = t.nodeName;
            console.error("THREE.PropertyBinding: Trying to update property for track: " + l + "." + i + " but it wasn't found.", e);
            return;
        }
        let o = this.Versioning.None;
        this.targetObject = e, e.needsUpdate !== void 0 ? o = this.Versioning.NeedsUpdate : e.matrixWorldNeedsUpdate !== void 0 && (o = this.Versioning.MatrixWorldNeedsUpdate);
        let c = this.BindingType.Direct;
        if (r !== void 0) {
            if (i === "morphTargetInfluences") {
                if (!e.geometry) {
                    console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
                    return;
                }
                if (!e.geometry.morphAttributes) {
                    console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
                    return;
                }
                e.morphTargetDictionary[r] !== void 0 && (r = e.morphTargetDictionary[r]);
            }
            c = this.BindingType.ArrayElement, this.resolvedProperty = a, this.propertyIndex = r;
        } else a.fromArray !== void 0 && a.toArray !== void 0 ? (c = this.BindingType.HasFromToArray, this.resolvedProperty = a) : Array.isArray(a) ? (c = this.BindingType.EntireArray, this.resolvedProperty = a) : this.propertyName = i;
        this.getValue = this.GetterByBindingType[c], this.setValue = this.SetterByBindingTypeAndVersioning[c][o];
    }
    unbind() {
        this.node = null, this.getValue = this._getValue_unbound, this.setValue = this._setValue_unbound;
    }
};
Ke.Composite = zc;
Ke.prototype.BindingType = {
    Direct: 0,
    EntireArray: 1,
    ArrayElement: 2,
    HasFromToArray: 3
};
Ke.prototype.Versioning = {
    None: 0,
    NeedsUpdate: 1,
    MatrixWorldNeedsUpdate: 2
};
Ke.prototype.GetterByBindingType = [
    Ke.prototype._getValue_direct,
    Ke.prototype._getValue_array,
    Ke.prototype._getValue_arrayElement,
    Ke.prototype._getValue_toArray
];
Ke.prototype.SetterByBindingTypeAndVersioning = [
    [
        Ke.prototype._setValue_direct,
        Ke.prototype._setValue_direct_setNeedsUpdate,
        Ke.prototype._setValue_direct_setMatrixWorldNeedsUpdate
    ],
    [
        Ke.prototype._setValue_array,
        Ke.prototype._setValue_array_setNeedsUpdate,
        Ke.prototype._setValue_array_setMatrixWorldNeedsUpdate
    ],
    [
        Ke.prototype._setValue_arrayElement,
        Ke.prototype._setValue_arrayElement_setNeedsUpdate,
        Ke.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate
    ],
    [
        Ke.prototype._setValue_fromArray,
        Ke.prototype._setValue_fromArray_setNeedsUpdate,
        Ke.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate
    ]
];
var Ru = class {
    constructor(){
        this.isAnimationObjectGroup = !0, this.uuid = kt(), this._objects = Array.prototype.slice.call(arguments), this.nCachedObjects_ = 0;
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
        let e = this._objects, t = this._indicesByUUID, n = this._paths, i = this._parsedPaths, r = this._bindings, a = r.length, o, c = e.length, l = this.nCachedObjects_;
        for(let h = 0, u = arguments.length; h !== u; ++h){
            let d = arguments[h], f = d.uuid, m = t[f];
            if (m === void 0) {
                m = c++, t[f] = m, e.push(d);
                for(let _ = 0, g = a; _ !== g; ++_)r[_].push(new Ke(d, n[_], i[_]));
            } else if (m < l) {
                o = e[m];
                let _ = --l, g = e[_];
                t[g.uuid] = m, e[m] = g, t[f] = _, e[_] = d;
                for(let p = 0, v = a; p !== v; ++p){
                    let x = r[p], y = x[_], b = x[m];
                    x[m] = y, b === void 0 && (b = new Ke(d, n[p], i[p])), x[_] = b;
                }
            } else e[m] !== o && console.error("THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.");
        }
        this.nCachedObjects_ = l;
    }
    remove() {
        let e = this._objects, t = this._indicesByUUID, n = this._bindings, i = n.length, r = this.nCachedObjects_;
        for(let a = 0, o = arguments.length; a !== o; ++a){
            let c = arguments[a], l = c.uuid, h = t[l];
            if (h !== void 0 && h >= r) {
                let u = r++, d = e[u];
                t[d.uuid] = h, e[h] = d, t[l] = u, e[u] = c;
                for(let f = 0, m = i; f !== m; ++f){
                    let _ = n[f], g = _[u], p = _[h];
                    _[h] = g, _[u] = p;
                }
            }
        }
        this.nCachedObjects_ = r;
    }
    uncache() {
        let e = this._objects, t = this._indicesByUUID, n = this._bindings, i = n.length, r = this.nCachedObjects_, a = e.length;
        for(let o = 0, c = arguments.length; o !== c; ++o){
            let l = arguments[o], h = l.uuid, u = t[h];
            if (u !== void 0) if (delete t[h], u < r) {
                let d = --r, f = e[d], m = --a, _ = e[m];
                t[f.uuid] = u, e[u] = f, t[_.uuid] = d, e[d] = _, e.pop();
                for(let g = 0, p = i; g !== p; ++g){
                    let v = n[g], x = v[d], y = v[m];
                    v[u] = x, v[d] = y, v.pop();
                }
            } else {
                let d = --a, f = e[d];
                d > 0 && (t[f.uuid] = u), e[u] = f, e.pop();
                for(let m = 0, _ = i; m !== _; ++m){
                    let g = n[m];
                    g[u] = g[d], g.pop();
                }
            }
        }
        this.nCachedObjects_ = r;
    }
    subscribe_(e, t) {
        let n = this._bindingsIndicesByPath, i = n[e], r = this._bindings;
        if (i !== void 0) return r[i];
        let a = this._paths, o = this._parsedPaths, c = this._objects, l = c.length, h = this.nCachedObjects_, u = new Array(l);
        i = r.length, n[e] = i, a.push(e), o.push(t), r.push(u);
        for(let d = h, f = c.length; d !== f; ++d){
            let m = c[d];
            u[d] = new Ke(m, e, t);
        }
        return u;
    }
    unsubscribe_(e) {
        let t = this._bindingsIndicesByPath, n = t[e];
        if (n !== void 0) {
            let i = this._paths, r = this._parsedPaths, a = this._bindings, o = a.length - 1, c = a[o], l = e[o];
            t[l] = n, a[n] = c, a.pop(), r[n] = r[o], r.pop(), i[n] = i[o], i.pop();
        }
    }
}, Vc = class {
    constructor(e, t, n = null, i = t.blendMode){
        this._mixer = e, this._clip = t, this._localRoot = n, this.blendMode = i;
        let r = t.tracks, a = r.length, o = new Array(a), c = {
            endingStart: zi,
            endingEnd: zi
        };
        for(let l = 0; l !== a; ++l){
            let h = r[l].createInterpolant(null);
            o[l] = h, h.settings = c;
        }
        this._interpolantSettings = c, this._interpolants = o, this._propertyBindings = new Array(a), this._cacheIndex = null, this._byClipCacheIndex = null, this._timeScaleInterpolant = null, this._weightInterpolant = null, this.loop = Af, this._loopCount = -1, this._startTime = null, this.time = 0, this.timeScale = 1, this._effectiveTimeScale = 1, this.weight = 1, this._effectiveWeight = 1, this.repetitions = 1 / 0, this.paused = !1, this.enabled = !0, this.clampWhenFinished = !1, this.zeroSlopeAtStart = !0, this.zeroSlopeAtEnd = !0;
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
            let i = this._clip.duration, r = e._clip.duration, a = r / i, o = i / r;
            e.warp(1, a, t), this.warp(o, 1, t);
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
        let i = this._mixer, r = i.time, a = this.timeScale, o = this._timeScaleInterpolant;
        o === null && (o = i._lendControlInterpolant(), this._timeScaleInterpolant = o);
        let c = o.parameterPositions, l = o.sampleValues;
        return c[0] = r, c[1] = r + n, l[0] = e / a, l[1] = t / a, this;
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
            let c = (e - r) * n;
            c < 0 || n === 0 ? t = 0 : (this._startTime = null, t = n * c);
        }
        t *= this._updateTimeScale(e);
        let a = this._updateTime(t), o = this._updateWeight(e);
        if (o > 0) {
            let c = this._interpolants, l = this._propertyBindings;
            switch(this.blendMode){
                case xd:
                    for(let h = 0, u = c.length; h !== u; ++h)c[h].evaluate(a), l[h].accumulateAdditive(o);
                    break;
                case Xc:
                default:
                    for(let h = 0, u = c.length; h !== u; ++h)c[h].evaluate(a), l[h].accumulate(i, o);
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
            if (n !== null) {
                let i = n.evaluate(e)[0];
                t *= i, e > n.parameterPositions[1] && (this.stopWarping(), t === 0 ? this.paused = !0 : this.timeScale = t);
            }
        }
        return this._effectiveTimeScale = t, t;
    }
    _updateTime(e) {
        let t = this._clip.duration, n = this.loop, i = this.time + e, r = this._loopCount, a = n === Rf;
        if (e === 0) return r === -1 ? i : a && (r & 1) === 1 ? t - i : i;
        if (n === wf) {
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
            if (r === -1 && (e >= 0 ? (r = 0, this._setEndings(!0, this.repetitions === 0, a)) : this._setEndings(this.repetitions === 0, !0, a)), i >= t || i < 0) {
                let o = Math.floor(i / t);
                i -= t * o, r += Math.abs(o);
                let c = this.repetitions - r;
                if (c <= 0) this.clampWhenFinished ? this.paused = !0 : this.enabled = !1, i = e > 0 ? t : 0, this.time = i, this._mixer.dispatchEvent({
                    type: "finished",
                    action: this,
                    direction: e > 0 ? 1 : -1
                });
                else {
                    if (c === 1) {
                        let l = e < 0;
                        this._setEndings(l, !l, a);
                    } else this._setEndings(!1, !1, a);
                    this._loopCount = r, this.time = i, this._mixer.dispatchEvent({
                        type: "loop",
                        action: this,
                        loopDelta: o
                    });
                }
            } else this.time = i;
            if (a && (r & 1) === 1) return t - i;
        }
        return i;
    }
    _setEndings(e, t, n) {
        let i = this._interpolantSettings;
        n ? (i.endingStart = Vi, i.endingEnd = Vi) : (e ? i.endingStart = this.zeroSlopeAtStart ? Vi : zi : i.endingStart = Br, t ? i.endingEnd = this.zeroSlopeAtEnd ? Vi : zi : i.endingEnd = Br);
    }
    _scheduleFading(e, t, n) {
        let i = this._mixer, r = i.time, a = this._weightInterpolant;
        a === null && (a = i._lendControlInterpolant(), this._weightInterpolant = a);
        let o = a.parameterPositions, c = a.sampleValues;
        return o[0] = r, c[0] = t, o[1] = r + e, c[1] = n, this;
    }
}, Ox = new Float32Array(1), Cu = class extends sn {
    constructor(e){
        super(), this._root = e, this._initMemoryManager(), this._accuIndex = 0, this.time = 0, this.timeScale = 1;
    }
    _bindAction(e, t) {
        let n = e._localRoot || this._root, i = e._clip.tracks, r = i.length, a = e._propertyBindings, o = e._interpolants, c = n.uuid, l = this._bindingsByRootAndName, h = l[c];
        h === void 0 && (h = {}, l[c] = h);
        for(let u = 0; u !== r; ++u){
            let d = i[u], f = d.name, m = h[f];
            if (m !== void 0) ++m.referenceCount, a[u] = m;
            else {
                if (m = a[u], m !== void 0) {
                    m._cacheIndex === null && (++m.referenceCount, this._addInactiveBinding(m, c, f));
                    continue;
                }
                let _ = t && t._propertyBindings[u].binding.parsedPath;
                m = new Bc(Ke.create(n, f, _), d.ValueTypeName, d.getValueSize()), ++m.referenceCount, this._addInactiveBinding(m, c, f), a[u] = m;
            }
            o[u].resultBuffer = m.buffer;
        }
    }
    _activateAction(e) {
        if (!this._isActiveAction(e)) {
            if (e._cacheIndex === null) {
                let n = (e._localRoot || this._root).uuid, i = e._clip.uuid, r = this._actionsByClip[i];
                this._bindAction(e, r && r.knownActions[0]), this._addInactiveAction(e, i, n);
            }
            let t = e._propertyBindings;
            for(let n = 0, i = t.length; n !== i; ++n){
                let r = t[n];
                r.useCount++ === 0 && (this._lendBinding(r), r.saveOriginalState());
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
        let i = this._actions, r = this._actionsByClip, a = r[t];
        if (a === void 0) a = {
            knownActions: [
                e
            ],
            actionByRoot: {}
        }, e._byClipCacheIndex = 0, r[t] = a;
        else {
            let o = a.knownActions;
            e._byClipCacheIndex = o.length, o.push(e);
        }
        e._cacheIndex = i.length, i.push(e), a.actionByRoot[n] = e;
    }
    _removeInactiveAction(e) {
        let t = this._actions, n = t[t.length - 1], i = e._cacheIndex;
        n._cacheIndex = i, t[i] = n, t.pop(), e._cacheIndex = null;
        let r = e._clip.uuid, a = this._actionsByClip, o = a[r], c = o.knownActions, l = c[c.length - 1], h = e._byClipCacheIndex;
        l._byClipCacheIndex = h, c[h] = l, c.pop(), e._byClipCacheIndex = null;
        let u = o.actionByRoot, d = (e._localRoot || this._root).uuid;
        delete u[d], c.length === 0 && delete a[r], this._removeInactiveBindingsForAction(e);
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
        let i = this._bindingsByRootAndName, r = this._bindings, a = i[t];
        a === void 0 && (a = {}, i[t] = a), a[n] = e, e._cacheIndex = r.length, r.push(e);
    }
    _removeInactiveBinding(e) {
        let t = this._bindings, n = e.binding, i = n.rootNode.uuid, r = n.path, a = this._bindingsByRootAndName, o = a[i], c = t[t.length - 1], l = e._cacheIndex;
        c._cacheIndex = l, t[l] = c, t.pop(), delete o[r], Object.keys(o).length === 0 && delete a[i];
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
        return n === void 0 && (n = new fa(new Float32Array(2), new Float32Array(2), 1, Ox), n.__cacheIndex = t, e[t] = n), n;
    }
    _takeBackControlInterpolant(e) {
        let t = this._controlInterpolants, n = e.__cacheIndex, i = --this._nActiveControlInterpolants, r = t[i];
        e.__cacheIndex = i, t[i] = e, r.__cacheIndex = n, t[n] = r;
    }
    clipAction(e, t, n) {
        let i = t || this._root, r = i.uuid, a = typeof e == "string" ? is.findByName(i, e) : e, o = a !== null ? a.uuid : e, c = this._actionsByClip[o], l = null;
        if (n === void 0 && (a !== null ? n = a.blendMode : n = Xc), c !== void 0) {
            let u = c.actionByRoot[r];
            if (u !== void 0 && u.blendMode === n) return u;
            l = c.knownActions[0], a === null && (a = l._clip);
        }
        if (a === null) return null;
        let h = new Vc(this, a, t, n);
        return this._bindAction(h, l), this._addInactiveAction(h, o, r), h;
    }
    existingAction(e, t) {
        let n = t || this._root, i = n.uuid, r = typeof e == "string" ? is.findByName(n, e) : e, a = r ? r.uuid : e, o = this._actionsByClip[a];
        return o !== void 0 && o.actionByRoot[i] || null;
    }
    stopAllAction() {
        let e = this._actions, t = this._nActiveActions;
        for(let n = t - 1; n >= 0; --n)e[n].stop();
        return this;
    }
    update(e) {
        e *= this.timeScale;
        let t = this._actions, n = this._nActiveActions, i = this.time += e, r = Math.sign(e), a = this._accuIndex ^= 1;
        for(let l = 0; l !== n; ++l)t[l]._update(i, e, r, a);
        let o = this._bindings, c = this._nActiveBindings;
        for(let l = 0; l !== c; ++l)o[l].apply(a);
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
            let a = r.knownActions;
            for(let o = 0, c = a.length; o !== c; ++o){
                let l = a[o];
                this._deactivateAction(l);
                let h = l._cacheIndex, u = t[t.length - 1];
                l._cacheIndex = null, l._byClipCacheIndex = null, u._cacheIndex = h, t[h] = u, t.pop(), this._removeInactiveBindingsForAction(l);
            }
            delete i[n];
        }
    }
    uncacheRoot(e) {
        let t = e.uuid, n = this._actionsByClip;
        for(let a in n){
            let o = n[a].actionByRoot, c = o[t];
            c !== void 0 && (this._deactivateAction(c), this._removeInactiveAction(c));
        }
        let i = this._bindingsByRootAndName, r = i[t];
        if (r !== void 0) for(let a in r){
            let o = r[a];
            o.restoreOriginalState(), this._removeInactiveBinding(o);
        }
    }
    uncacheAction(e, t) {
        let n = this.existingAction(e, t);
        n !== null && (this._deactivateAction(n), this._removeInactiveAction(n));
    }
}, Pu = class s1 {
    constructor(e){
        this.value = e;
    }
    clone() {
        return new s1(this.value.clone === void 0 ? this.value : this.value.clone());
    }
}, Fx = 0, Lu = class extends sn {
    constructor(){
        super(), this.isUniformsGroup = !0, Object.defineProperty(this, "id", {
            value: Fx++
        }), this.name = "", this.usage = Hr, this.uniforms = [];
    }
    add(e) {
        return this.uniforms.push(e), this;
    }
    remove(e) {
        let t = this.uniforms.indexOf(e);
        return t !== -1 && this.uniforms.splice(t, 1), this;
    }
    setName(e) {
        return this.name = e, this;
    }
    setUsage(e) {
        return this.usage = e, this;
    }
    dispose() {
        return this.dispatchEvent({
            type: "dispose"
        }), this;
    }
    copy(e) {
        this.name = e.name, this.usage = e.usage;
        let t = e.uniforms;
        this.uniforms.length = 0;
        for(let n = 0, i = t.length; n < i; n++)this.uniforms.push(t[n].clone());
        return this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Iu = class extends Is {
    constructor(e, t, n = 1){
        super(e, t), this.isInstancedInterleavedBuffer = !0, this.meshPerAttribute = n;
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
}, Uu = class {
    constructor(e, t, n, i, r){
        this.isGLBufferAttribute = !0, this.name = "", this.buffer = e, this.type = t, this.itemSize = n, this.elementSize = i, this.count = r, this.version = 0;
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
}, Du = class {
    constructor(e, t, n = 0, i = 1 / 0){
        this.ray = new hi(e, t), this.near = n, this.far = i, this.camera = null, this.layers = new Rs, this.params = {
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
        t.isPerspectiveCamera ? (this.ray.origin.setFromMatrixPosition(t.matrixWorld), this.ray.direction.set(e.x, e.y, .5).unproject(t).sub(this.ray.origin).normalize(), this.camera = t) : t.isOrthographicCamera ? (this.ray.origin.set(e.x, e.y, (t.near + t.far) / (t.near - t.far)).unproject(t), this.ray.direction.set(0, 0, -1).transformDirection(t.matrixWorld), this.camera = t) : console.error("THREE.Raycaster: Unsupported camera type: " + t.type);
    }
    intersectObject(e, t = !0, n = []) {
        return kc(e, this, n, t), n.sort(Nu), n;
    }
    intersectObjects(e, t = !0, n = []) {
        for(let i = 0, r = e.length; i < r; i++)kc(e[i], this, n, t);
        return n.sort(Nu), n;
    }
};
function Nu(s1, e) {
    return s1.distance - e.distance;
}
function kc(s1, e, t, n) {
    if (s1.layers.test(e.layers) && s1.raycast(e, t), n === !0) {
        let i = s1.children;
        for(let r = 0, a = i.length; r < a; r++)kc(i[r], e, t, !0);
    }
}
var Ou = class {
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
        return this.radius = Math.sqrt(e * e + t * t + n * n), this.radius === 0 ? (this.theta = 0, this.phi = 0) : (this.theta = Math.atan2(e, n), this.phi = Math.acos(ct(t / this.radius, -1, 1))), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Fu = class {
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
}, Bu = new Z, zu = class {
    constructor(e = new Z(1 / 0, 1 / 0), t = new Z(-1 / 0, -1 / 0)){
        this.isBox2 = !0, this.min = e, this.max = t;
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
        let n = Bu.copy(t).multiplyScalar(.5);
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
        return this.clampPoint(e, Bu).distanceTo(e);
    }
    intersect(e) {
        return this.min.max(e.min), this.max.min(e.max), this.isEmpty() && this.makeEmpty(), this;
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
}, Vu = new A, Tr = new A, ku = class {
    constructor(e = new A, t = new A){
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
        Vu.subVectors(e, this.start), Tr.subVectors(this.end, this.start);
        let n = Tr.dot(Tr), r = Tr.dot(Vu) / n;
        return t && (r = ct(r, 0, 1)), r;
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
}, Hu = new A, Gu = class extends Je {
    constructor(e, t){
        super(), this.light = e, this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.color = t, this.type = "SpotLightHelper";
        let n = new Ge, i = [
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
        for(let a = 0, o = 1, c = 32; a < c; a++, o++){
            let l = a / c * Math.PI * 2, h = o / c * Math.PI * 2;
            i.push(Math.cos(l), Math.sin(l), 1, Math.cos(h), Math.sin(h), 1);
        }
        n.setAttribute("position", new ve(i, 3));
        let r = new wt({
            fog: !1,
            toneMapped: !1
        });
        this.cone = new en(n, r), this.add(this.cone), this.update();
    }
    dispose() {
        this.cone.geometry.dispose(), this.cone.material.dispose();
    }
    update() {
        this.light.updateWorldMatrix(!0, !1), this.light.target.updateWorldMatrix(!0, !1);
        let e = this.light.distance ? this.light.distance : 1e3, t = e * Math.tan(this.light.angle);
        this.cone.scale.set(t, t, e), Hu.setFromMatrixPosition(this.light.target.matrixWorld), this.cone.lookAt(Hu), this.color !== void 0 ? this.cone.material.color.set(this.color) : this.cone.material.color.copy(this.light.color);
    }
}, Pn = new A, wr = new ze, lo = new ze, Wu = class extends en {
    constructor(e){
        let t = Nd(e), n = new Ge, i = [], r = [], a = new pe(0, 0, 1), o = new pe(0, 1, 0);
        for(let l = 0; l < t.length; l++){
            let h = t[l];
            h.parent && h.parent.isBone && (i.push(0, 0, 0), i.push(0, 0, 0), r.push(a.r, a.g, a.b), r.push(o.r, o.g, o.b));
        }
        n.setAttribute("position", new ve(i, 3)), n.setAttribute("color", new ve(r, 3));
        let c = new wt({
            vertexColors: !0,
            depthTest: !1,
            depthWrite: !1,
            toneMapped: !1,
            transparent: !0
        });
        super(n, c), this.isSkeletonHelper = !0, this.type = "SkeletonHelper", this.root = e, this.bones = t, this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1;
    }
    updateMatrixWorld(e) {
        let t = this.bones, n = this.geometry, i = n.getAttribute("position");
        lo.copy(this.root.matrixWorld).invert();
        for(let r = 0, a = 0; r < t.length; r++){
            let o = t[r];
            o.parent && o.parent.isBone && (wr.multiplyMatrices(lo, o.matrixWorld), Pn.setFromMatrixPosition(wr), i.setXYZ(a, Pn.x, Pn.y, Pn.z), wr.multiplyMatrices(lo, o.parent.matrixWorld), Pn.setFromMatrixPosition(wr), i.setXYZ(a + 1, Pn.x, Pn.y, Pn.z), a += 2);
        }
        n.getAttribute("position").needsUpdate = !0, super.updateMatrixWorld(e);
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
};
function Nd(s1) {
    let e = [];
    s1.isBone === !0 && e.push(s1);
    for(let t = 0; t < s1.children.length; t++)e.push.apply(e, Nd(s1.children[t]));
    return e;
}
var Xu = class extends Mt {
    constructor(e, t, n){
        let i = new ua(t, 4, 2), r = new Sn({
            wireframe: !0,
            fog: !1,
            toneMapped: !1
        });
        super(i, r), this.light = e, this.color = n, this.type = "PointLightHelper", this.matrix = this.light.matrixWorld, this.matrixAutoUpdate = !1, this.update();
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
    update() {
        this.light.updateWorldMatrix(!0, !1), this.color !== void 0 ? this.material.color.set(this.color) : this.material.color.copy(this.light.color);
    }
}, Bx = new A, qu = new pe, Yu = new pe, Zu = class extends Je {
    constructor(e, t, n){
        super(), this.light = e, this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.color = n, this.type = "HemisphereLightHelper";
        let i = new ha(t);
        i.rotateY(Math.PI * .5), this.material = new Sn({
            wireframe: !0,
            fog: !1,
            toneMapped: !1
        }), this.color === void 0 && (this.material.vertexColors = !0);
        let r = i.getAttribute("position"), a = new Float32Array(r.count * 3);
        i.setAttribute("color", new et(a, 3)), this.add(new Mt(i, this.material)), this.update();
    }
    dispose() {
        this.children[0].geometry.dispose(), this.children[0].material.dispose();
    }
    update() {
        let e = this.children[0];
        if (this.color !== void 0) this.material.color.set(this.color);
        else {
            let t = e.geometry.getAttribute("color");
            qu.copy(this.light.color), Yu.copy(this.light.groundColor);
            for(let n = 0, i = t.count; n < i; n++){
                let r = n < i / 2 ? qu : Yu;
                t.setXYZ(n, r.r, r.g, r.b);
            }
            t.needsUpdate = !0;
        }
        this.light.updateWorldMatrix(!0, !1), e.lookAt(Bx.setFromMatrixPosition(this.light.matrixWorld).negate());
    }
}, Ju = class extends en {
    constructor(e = 10, t = 10, n = 4473924, i = 8947848){
        n = new pe(n), i = new pe(i);
        let r = t / 2, a = e / t, o = e / 2, c = [], l = [];
        for(let d = 0, f = 0, m = -o; d <= t; d++, m += a){
            c.push(-o, 0, m, o, 0, m), c.push(m, 0, -o, m, 0, o);
            let _ = d === r ? n : i;
            _.toArray(l, f), f += 3, _.toArray(l, f), f += 3, _.toArray(l, f), f += 3, _.toArray(l, f), f += 3;
        }
        let h = new Ge;
        h.setAttribute("position", new ve(c, 3)), h.setAttribute("color", new ve(l, 3));
        let u = new wt({
            vertexColors: !0,
            toneMapped: !1
        });
        super(h, u), this.type = "GridHelper";
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, $u = class extends en {
    constructor(e = 10, t = 16, n = 8, i = 64, r = 4473924, a = 8947848){
        r = new pe(r), a = new pe(a);
        let o = [], c = [];
        if (t > 1) for(let u = 0; u < t; u++){
            let d = u / t * (Math.PI * 2), f = Math.sin(d) * e, m = Math.cos(d) * e;
            o.push(0, 0, 0), o.push(f, 0, m);
            let _ = u & 1 ? r : a;
            c.push(_.r, _.g, _.b), c.push(_.r, _.g, _.b);
        }
        for(let u = 0; u < n; u++){
            let d = u & 1 ? r : a, f = e - e / n * u;
            for(let m = 0; m < i; m++){
                let _ = m / i * (Math.PI * 2), g = Math.sin(_) * f, p = Math.cos(_) * f;
                o.push(g, 0, p), c.push(d.r, d.g, d.b), _ = (m + 1) / i * (Math.PI * 2), g = Math.sin(_) * f, p = Math.cos(_) * f, o.push(g, 0, p), c.push(d.r, d.g, d.b);
            }
        }
        let l = new Ge;
        l.setAttribute("position", new ve(o, 3)), l.setAttribute("color", new ve(c, 3));
        let h = new wt({
            vertexColors: !0,
            toneMapped: !1
        });
        super(l, h), this.type = "PolarGridHelper";
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, Ku = new A, Ar = new A, Qu = new A, ju = class extends Je {
    constructor(e, t, n){
        super(), this.light = e, this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.color = n, this.type = "DirectionalLightHelper", t === void 0 && (t = 1);
        let i = new Ge;
        i.setAttribute("position", new ve([
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
        let r = new wt({
            fog: !1,
            toneMapped: !1
        });
        this.lightPlane = new bn(i, r), this.add(this.lightPlane), i = new Ge, i.setAttribute("position", new ve([
            0,
            0,
            0,
            0,
            0,
            1
        ], 3)), this.targetLine = new bn(i, r), this.add(this.targetLine), this.update();
    }
    dispose() {
        this.lightPlane.geometry.dispose(), this.lightPlane.material.dispose(), this.targetLine.geometry.dispose(), this.targetLine.material.dispose();
    }
    update() {
        this.light.updateWorldMatrix(!0, !1), this.light.target.updateWorldMatrix(!0, !1), Ku.setFromMatrixPosition(this.light.matrixWorld), Ar.setFromMatrixPosition(this.light.target.matrixWorld), Qu.subVectors(Ar, Ku), this.lightPlane.lookAt(Ar), this.color !== void 0 ? (this.lightPlane.material.color.set(this.color), this.targetLine.material.color.set(this.color)) : (this.lightPlane.material.color.copy(this.light.color), this.targetLine.material.color.copy(this.light.color)), this.targetLine.lookAt(Ar), this.targetLine.scale.z = Qu.length();
    }
}, Rr = new A, ot = new Cs, ed = class extends en {
    constructor(e){
        let t = new Ge, n = new wt({
            color: 16777215,
            vertexColors: !0,
            toneMapped: !1
        }), i = [], r = [], a = {};
        o("n1", "n2"), o("n2", "n4"), o("n4", "n3"), o("n3", "n1"), o("f1", "f2"), o("f2", "f4"), o("f4", "f3"), o("f3", "f1"), o("n1", "f1"), o("n2", "f2"), o("n3", "f3"), o("n4", "f4"), o("p", "n1"), o("p", "n2"), o("p", "n3"), o("p", "n4"), o("u1", "u2"), o("u2", "u3"), o("u3", "u1"), o("c", "t"), o("p", "c"), o("cn1", "cn2"), o("cn3", "cn4"), o("cf1", "cf2"), o("cf3", "cf4");
        function o(m, _) {
            c(m), c(_);
        }
        function c(m) {
            i.push(0, 0, 0), r.push(0, 0, 0), a[m] === void 0 && (a[m] = []), a[m].push(i.length / 3 - 1);
        }
        t.setAttribute("position", new ve(i, 3)), t.setAttribute("color", new ve(r, 3)), super(t, n), this.type = "CameraHelper", this.camera = e, this.camera.updateProjectionMatrix && this.camera.updateProjectionMatrix(), this.matrix = e.matrixWorld, this.matrixAutoUpdate = !1, this.pointMap = a, this.update();
        let l = new pe(16755200), h = new pe(16711680), u = new pe(43775), d = new pe(16777215), f = new pe(3355443);
        this.setColors(l, h, u, d, f);
    }
    setColors(e, t, n, i, r) {
        let o = this.geometry.getAttribute("color");
        o.setXYZ(0, e.r, e.g, e.b), o.setXYZ(1, e.r, e.g, e.b), o.setXYZ(2, e.r, e.g, e.b), o.setXYZ(3, e.r, e.g, e.b), o.setXYZ(4, e.r, e.g, e.b), o.setXYZ(5, e.r, e.g, e.b), o.setXYZ(6, e.r, e.g, e.b), o.setXYZ(7, e.r, e.g, e.b), o.setXYZ(8, e.r, e.g, e.b), o.setXYZ(9, e.r, e.g, e.b), o.setXYZ(10, e.r, e.g, e.b), o.setXYZ(11, e.r, e.g, e.b), o.setXYZ(12, e.r, e.g, e.b), o.setXYZ(13, e.r, e.g, e.b), o.setXYZ(14, e.r, e.g, e.b), o.setXYZ(15, e.r, e.g, e.b), o.setXYZ(16, e.r, e.g, e.b), o.setXYZ(17, e.r, e.g, e.b), o.setXYZ(18, e.r, e.g, e.b), o.setXYZ(19, e.r, e.g, e.b), o.setXYZ(20, e.r, e.g, e.b), o.setXYZ(21, e.r, e.g, e.b), o.setXYZ(22, e.r, e.g, e.b), o.setXYZ(23, e.r, e.g, e.b), o.setXYZ(24, t.r, t.g, t.b), o.setXYZ(25, t.r, t.g, t.b), o.setXYZ(26, t.r, t.g, t.b), o.setXYZ(27, t.r, t.g, t.b), o.setXYZ(28, t.r, t.g, t.b), o.setXYZ(29, t.r, t.g, t.b), o.setXYZ(30, t.r, t.g, t.b), o.setXYZ(31, t.r, t.g, t.b), o.setXYZ(32, n.r, n.g, n.b), o.setXYZ(33, n.r, n.g, n.b), o.setXYZ(34, n.r, n.g, n.b), o.setXYZ(35, n.r, n.g, n.b), o.setXYZ(36, n.r, n.g, n.b), o.setXYZ(37, n.r, n.g, n.b), o.setXYZ(38, i.r, i.g, i.b), o.setXYZ(39, i.r, i.g, i.b), o.setXYZ(40, r.r, r.g, r.b), o.setXYZ(41, r.r, r.g, r.b), o.setXYZ(42, r.r, r.g, r.b), o.setXYZ(43, r.r, r.g, r.b), o.setXYZ(44, r.r, r.g, r.b), o.setXYZ(45, r.r, r.g, r.b), o.setXYZ(46, r.r, r.g, r.b), o.setXYZ(47, r.r, r.g, r.b), o.setXYZ(48, r.r, r.g, r.b), o.setXYZ(49, r.r, r.g, r.b), o.needsUpdate = !0;
    }
    update() {
        let e = this.geometry, t = this.pointMap, n = 1, i = 1;
        ot.projectionMatrixInverse.copy(this.camera.projectionMatrixInverse), ht("c", t, e, ot, 0, 0, -1), ht("t", t, e, ot, 0, 0, 1), ht("n1", t, e, ot, -n, -i, -1), ht("n2", t, e, ot, n, -i, -1), ht("n3", t, e, ot, -n, i, -1), ht("n4", t, e, ot, n, i, -1), ht("f1", t, e, ot, -n, -i, 1), ht("f2", t, e, ot, n, -i, 1), ht("f3", t, e, ot, -n, i, 1), ht("f4", t, e, ot, n, i, 1), ht("u1", t, e, ot, n * .7, i * 1.1, -1), ht("u2", t, e, ot, -n * .7, i * 1.1, -1), ht("u3", t, e, ot, 0, i * 2, -1), ht("cf1", t, e, ot, -n, 0, 1), ht("cf2", t, e, ot, n, 0, 1), ht("cf3", t, e, ot, 0, -i, 1), ht("cf4", t, e, ot, 0, i, 1), ht("cn1", t, e, ot, -n, 0, -1), ht("cn2", t, e, ot, n, 0, -1), ht("cn3", t, e, ot, 0, -i, -1), ht("cn4", t, e, ot, 0, i, -1), e.getAttribute("position").needsUpdate = !0;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
};
function ht(s1, e, t, n, i, r, a) {
    Rr.set(i, r, a).unproject(n);
    let o = e[s1];
    if (o !== void 0) {
        let c = t.getAttribute("position");
        for(let l = 0, h = o.length; l < h; l++)c.setXYZ(o[l], Rr.x, Rr.y, Rr.z);
    }
}
var Cr = new Qt, td = class extends en {
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
        ]), i = new Float32Array(8 * 3), r = new Ge;
        r.setIndex(new et(n, 1)), r.setAttribute("position", new et(i, 3)), super(r, new wt({
            color: t,
            toneMapped: !1
        })), this.object = e, this.type = "BoxHelper", this.matrixAutoUpdate = !1, this.update();
    }
    update(e) {
        if (e !== void 0 && console.warn("THREE.BoxHelper: .update() has no longer arguments."), this.object !== void 0 && Cr.setFromObject(this.object), Cr.isEmpty()) return;
        let t = Cr.min, n = Cr.max, i = this.geometry.attributes.position, r = i.array;
        r[0] = n.x, r[1] = n.y, r[2] = n.z, r[3] = t.x, r[4] = n.y, r[5] = n.z, r[6] = t.x, r[7] = t.y, r[8] = n.z, r[9] = n.x, r[10] = t.y, r[11] = n.z, r[12] = n.x, r[13] = n.y, r[14] = t.z, r[15] = t.x, r[16] = n.y, r[17] = t.z, r[18] = t.x, r[19] = t.y, r[20] = t.z, r[21] = n.x, r[22] = t.y, r[23] = t.z, i.needsUpdate = !0, this.geometry.computeBoundingSphere();
    }
    setFromObject(e) {
        return this.object = e, this.update(), this;
    }
    copy(e, t) {
        return super.copy(e, t), this.object = e.object, this;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, nd = class extends en {
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
        ], r = new Ge;
        r.setIndex(new et(n, 1)), r.setAttribute("position", new ve(i, 3)), super(r, new wt({
            color: t,
            toneMapped: !1
        })), this.box = e, this.type = "Box3Helper", this.geometry.computeBoundingSphere();
    }
    updateMatrixWorld(e) {
        let t = this.box;
        t.isEmpty() || (t.getCenter(this.position), t.getSize(this.scale), this.scale.multiplyScalar(.5), super.updateMatrixWorld(e));
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, id = class extends bn {
    constructor(e, t = 1, n = 16776960){
        let i = n, r = [
            1,
            -1,
            0,
            -1,
            1,
            0,
            -1,
            -1,
            0,
            1,
            1,
            0,
            -1,
            1,
            0,
            -1,
            -1,
            0,
            1,
            -1,
            0,
            1,
            1,
            0
        ], a = new Ge;
        a.setAttribute("position", new ve(r, 3)), a.computeBoundingSphere(), super(a, new wt({
            color: i,
            toneMapped: !1
        })), this.type = "PlaneHelper", this.plane = e, this.size = t;
        let o = [
            1,
            1,
            0,
            -1,
            1,
            0,
            -1,
            -1,
            0,
            1,
            1,
            0,
            -1,
            -1,
            0,
            1,
            -1,
            0
        ], c = new Ge;
        c.setAttribute("position", new ve(o, 3)), c.computeBoundingSphere(), this.add(new Mt(c, new Sn({
            color: i,
            opacity: .2,
            transparent: !0,
            depthWrite: !1,
            toneMapped: !1
        })));
    }
    updateMatrixWorld(e) {
        this.position.set(0, 0, 0), this.scale.set(.5 * this.size, .5 * this.size, 1), this.lookAt(this.plane.normal), this.translateZ(-this.plane.constant), super.updateMatrixWorld(e);
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose(), this.children[0].geometry.dispose(), this.children[0].material.dispose();
    }
}, sd = new A, Pr, ho, rd = class extends Je {
    constructor(e = new A(0, 0, 1), t = new A(0, 0, 0), n = 1, i = 16776960, r = n * .2, a = r * .2){
        super(), this.type = "ArrowHelper", Pr === void 0 && (Pr = new Ge, Pr.setAttribute("position", new ve([
            0,
            0,
            0,
            0,
            1,
            0
        ], 3)), ho = new Ns(0, .5, 1, 5, 1), ho.translate(0, -.5, 0)), this.position.copy(t), this.line = new bn(Pr, new wt({
            color: i,
            toneMapped: !1
        })), this.line.matrixAutoUpdate = !1, this.add(this.line), this.cone = new Mt(ho, new Sn({
            color: i,
            toneMapped: !1
        })), this.cone.matrixAutoUpdate = !1, this.add(this.cone), this.setDirection(e), this.setLength(n, r, a);
    }
    setDirection(e) {
        if (e.y > .99999) this.quaternion.set(0, 0, 0, 1);
        else if (e.y < -.99999) this.quaternion.set(1, 0, 0, 0);
        else {
            sd.set(e.z, 0, -e.x).normalize();
            let t = Math.acos(e.y);
            this.quaternion.setFromAxisAngle(sd, t);
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
    dispose() {
        this.line.geometry.dispose(), this.line.material.dispose(), this.cone.geometry.dispose(), this.cone.material.dispose();
    }
}, ad = class extends en {
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
        ], i = new Ge;
        i.setAttribute("position", new ve(t, 3)), i.setAttribute("color", new ve(n, 3));
        let r = new wt({
            vertexColors: !0,
            toneMapped: !1
        });
        super(i, r), this.type = "AxesHelper";
    }
    setColors(e, t, n) {
        let i = new pe, r = this.geometry.attributes.color.array;
        return i.set(e), i.toArray(r, 0), i.toArray(r, 3), i.set(t), i.toArray(r, 6), i.toArray(r, 9), i.set(n), i.toArray(r, 12), i.toArray(r, 15), this.geometry.attributes.color.needsUpdate = !0, this;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, od = class {
    constructor(){
        this.type = "ShapePath", this.color = new pe, this.subPaths = [], this.currentPath = null;
    }
    moveTo(e, t) {
        return this.currentPath = new ji, this.subPaths.push(this.currentPath), this.currentPath.moveTo(e, t), this;
    }
    lineTo(e, t) {
        return this.currentPath.lineTo(e, t), this;
    }
    quadraticCurveTo(e, t, n, i) {
        return this.currentPath.quadraticCurveTo(e, t, n, i), this;
    }
    bezierCurveTo(e, t, n, i, r, a) {
        return this.currentPath.bezierCurveTo(e, t, n, i, r, a), this;
    }
    splineThru(e) {
        return this.currentPath.splineThru(e), this;
    }
    toShapes(e) {
        function t(p) {
            let v = [];
            for(let x = 0, y = p.length; x < y; x++){
                let b = p[x], w = new Fn;
                w.curves = b.curves, v.push(w);
            }
            return v;
        }
        function n(p, v) {
            let x = v.length, y = !1;
            for(let b = x - 1, w = 0; w < x; b = w++){
                let R = v[b], I = v[w], M = I.x - R.x, T = I.y - R.y;
                if (Math.abs(T) > Number.EPSILON) {
                    if (T < 0 && (R = v[w], M = -M, I = v[b], T = -T), p.y < R.y || p.y > I.y) continue;
                    if (p.y === R.y) {
                        if (p.x === R.x) return !0;
                    } else {
                        let O = T * (p.x - R.x) - M * (p.y - R.y);
                        if (O === 0) return !0;
                        if (O < 0) continue;
                        y = !y;
                    }
                } else {
                    if (p.y !== R.y) continue;
                    if (I.x <= p.x && p.x <= R.x || R.x <= p.x && p.x <= I.x) return !0;
                }
            }
            return y;
        }
        let i = yn.isClockWise, r = this.subPaths;
        if (r.length === 0) return [];
        let a, o, c, l = [];
        if (r.length === 1) return o = r[0], c = new Fn, c.curves = o.curves, l.push(c), l;
        let h = !i(r[0].getPoints());
        h = e ? !h : h;
        let u = [], d = [], f = [], m = 0, _;
        d[m] = void 0, f[m] = [];
        for(let p = 0, v = r.length; p < v; p++)o = r[p], _ = o.getPoints(), a = i(_), a = e ? !a : a, a ? (!h && d[m] && m++, d[m] = {
            s: new Fn,
            p: _
        }, d[m].s.curves = o.curves, h && m++, f[m] = []) : f[m].push({
            h: o,
            p: _[0]
        });
        if (!d[0]) return t(r);
        if (d.length > 1) {
            let p = !1, v = 0;
            for(let x = 0, y = d.length; x < y; x++)u[x] = [];
            for(let x = 0, y = d.length; x < y; x++){
                let b = f[x];
                for(let w = 0; w < b.length; w++){
                    let R = b[w], I = !0;
                    for(let M = 0; M < d.length; M++)n(R.p, d[M].p) && (x !== M && v++, I ? (I = !1, u[M].push(R)) : p = !0);
                    I && u[x].push(R);
                }
            }
            v > 0 && p === !1 && (f = u);
        }
        let g;
        for(let p = 0, v = d.length; p < v; p++){
            c = d[p].s, l.push(c), g = f[p];
            for(let x = 0, y = g.length; x < y; x++)c.holes.push(g[x].h);
        }
        return l;
    }
};
typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register", {
    detail: {
        revision: Hc
    }
}));
typeof window < "u" && (window.__THREE__ ? console.warn("WARNING: Multiple instances of Three.js being imported.") : window.__THREE__ = Hc);
const mod = {
    ACESFilmicToneMapping: mf,
    AddEquation: Bi,
    AddOperation: uf,
    AdditiveAnimationBlendMode: xd,
    AdditiveBlending: al,
    AlphaFormat: vf,
    AlwaysCompare: Vf,
    AlwaysDepth: sf,
    AlwaysStencilFunc: If,
    AmbientLight: Cc,
    AnimationAction: Vc,
    AnimationClip: is,
    AnimationLoader: au,
    AnimationMixer: Cu,
    AnimationObjectGroup: Ru,
    AnimationUtils: Sv,
    ArcCurve: ko,
    ArrayCamera: To,
    ArrowHelper: rd,
    Audio: Fc,
    AudioAnalyser: Au,
    AudioContext: _a,
    AudioListener: Eu,
    AudioLoader: xu,
    AxesHelper: ad,
    BackSide: Ft,
    BasicDepthPacking: Cf,
    BasicShadowMap: Hx,
    Bone: ta,
    BooleanKeyframeTrack: Vn,
    Box2: zu,
    Box3: Qt,
    Box3Helper: nd,
    BoxGeometry: Ji,
    BoxHelper: td,
    BufferAttribute: et,
    BufferGeometry: Ge,
    BufferGeometryLoader: Nc,
    ByteType: _f,
    Cache: ss,
    Camera: Cs,
    CameraHelper: ed,
    CanvasTexture: jh,
    CapsuleGeometry: qo,
    CatmullRomCurve3: Ho,
    CineonToneMapping: pf,
    CircleGeometry: Yo,
    ClampToEdgeWrapping: It,
    Clock: Oc,
    Color: pe,
    ColorKeyframeTrack: pa,
    ColorManagement: Qe,
    CompressedArrayTexture: Kh,
    CompressedCubeTexture: Qh,
    CompressedTexture: Us,
    CompressedTextureLoader: ou,
    ConeGeometry: Zo,
    CubeCamera: _o,
    CubeReflectionMapping: zn,
    CubeRefractionMapping: ci,
    CubeTexture: Ki,
    CubeTextureLoader: cu,
    CubeUVReflectionMapping: Vs,
    CubicBezierCurve: ia,
    CubicBezierCurve3: Go,
    CubicInterpolant: xc,
    CullFaceBack: rl,
    CullFaceFront: Hd,
    CullFaceFrontBack: kx,
    CullFaceNone: kd,
    Curve: Zt,
    CurvePath: Xo,
    CustomBlending: Wd,
    CustomToneMapping: gf,
    CylinderGeometry: Ns,
    Cylindrical: Fu,
    Data3DTexture: qr,
    DataArrayTexture: As,
    DataTexture: oi,
    DataTextureLoader: lu,
    DataUtils: Mv,
    DecrementStencilOp: ev,
    DecrementWrapStencilOp: nv,
    DefaultLoadingManager: Ex,
    DepthFormat: si,
    DepthStencilFormat: Yi,
    DepthTexture: wo,
    DirectionalLight: Rc,
    DirectionalLightHelper: ju,
    DiscreteInterpolant: vc,
    DisplayP3ColorSpace: qc,
    DodecahedronGeometry: Jo,
    DoubleSide: gn,
    DstAlphaFactor: Kd,
    DstColorFactor: jd,
    DynamicCopyUsage: _v,
    DynamicDrawUsage: uv,
    DynamicReadUsage: pv,
    EdgesGeometry: $o,
    EllipseCurve: Ds,
    EqualCompare: Nf,
    EqualDepth: af,
    EqualStencilFunc: av,
    EquirectangularReflectionMapping: Ir,
    EquirectangularRefractionMapping: Ur,
    Euler: Yr,
    EventDispatcher: sn,
    ExtrudeGeometry: jo,
    FileLoader: rn,
    Float16BufferAttribute: ih,
    Float32BufferAttribute: ve,
    Float64BufferAttribute: sh,
    FloatType: xn,
    Fog: Lo,
    FogExp2: Po,
    FramebufferTexture: $h,
    FrontSide: Bn,
    Frustum: Ps,
    GLBufferAttribute: Uu,
    GLSL1: vv,
    GLSL3: Ol,
    GreaterCompare: Ff,
    GreaterDepth: cf,
    GreaterEqualCompare: zf,
    GreaterEqualDepth: of,
    GreaterEqualStencilFunc: hv,
    GreaterStencilFunc: cv,
    GridHelper: Ju,
    Group: ti,
    HalfFloatType: Ts,
    HemisphereLight: Sc,
    HemisphereLightHelper: Zu,
    IcosahedronGeometry: ec,
    ImageBitmapLoader: _u,
    ImageLoader: rs,
    ImageUtils: Xr,
    IncrementStencilOp: jx,
    IncrementWrapStencilOp: tv,
    InstancedBufferAttribute: ui,
    InstancedBufferGeometry: Dc,
    InstancedInterleavedBuffer: Iu,
    InstancedMesh: Fo,
    Int16BufferAttribute: th,
    Int32BufferAttribute: nh,
    Int8BufferAttribute: Ql,
    IntType: dd,
    InterleavedBuffer: Is,
    InterleavedBufferAttribute: Qi,
    Interpolant: es,
    InterpolateDiscrete: Or,
    InterpolateLinear: Fr,
    InterpolateSmooth: La,
    InvertStencilOp: iv,
    KeepStencilOp: Ia,
    KeyframeTrack: Jt,
    LOD: Do,
    LatheGeometry: la,
    Layers: Rs,
    LessCompare: Df,
    LessDepth: rf,
    LessEqualCompare: Of,
    LessEqualDepth: uo,
    LessEqualStencilFunc: ov,
    LessStencilFunc: rv,
    Light: En,
    LightProbe: Ic,
    Line: bn,
    Line3: ku,
    LineBasicMaterial: wt,
    LineCurve: sa,
    LineCurve3: Wo,
    LineDashedMaterial: gc,
    LineLoop: Bo,
    LineSegments: en,
    LinearDisplayP3ColorSpace: va,
    LinearEncoding: vd,
    LinearFilter: mt,
    LinearInterpolant: fa,
    LinearMipMapLinearFilter: Yx,
    LinearMipMapNearestFilter: qx,
    LinearMipmapLinearFilter: li,
    LinearMipmapNearestFilter: ud,
    LinearSRGBColorSpace: Mn,
    LinearToneMapping: df,
    LinearTransfer: zr,
    Loader: Dt,
    LoaderUtils: ga,
    LoadingManager: ma,
    LoopOnce: wf,
    LoopPingPong: Rf,
    LoopRepeat: Af,
    LuminanceAlphaFormat: Mf,
    LuminanceFormat: yf,
    MOUSE: zx,
    Material: bt,
    MaterialLoader: Uc,
    MathUtils: yv,
    Matrix3: He,
    Matrix4: ze,
    MaxEquation: hl,
    Mesh: Mt,
    MeshBasicMaterial: Sn,
    MeshDepthMaterial: Qr,
    MeshDistanceMaterial: jr,
    MeshLambertMaterial: pc,
    MeshMatcapMaterial: mc,
    MeshNormalMaterial: fc,
    MeshPhongMaterial: uc,
    MeshPhysicalMaterial: hc,
    MeshStandardMaterial: da,
    MeshToonMaterial: dc,
    MinEquation: ll,
    MirroredRepeatWrapping: Nr,
    MixOperation: hf,
    MultiplyBlending: cl,
    MultiplyOperation: xa,
    NearestFilter: pt,
    NearestMipMapLinearFilter: Xx,
    NearestMipMapNearestFilter: Wx,
    NearestMipmapLinearFilter: Lr,
    NearestMipmapNearestFilter: fo,
    NeverCompare: Uf,
    NeverDepth: nf,
    NeverStencilFunc: sv,
    NoBlending: Dn,
    NoColorSpace: Xt,
    NoToneMapping: Nn,
    NormalAnimationBlendMode: Xc,
    NormalBlending: Wi,
    NotEqualCompare: Bf,
    NotEqualDepth: lf,
    NotEqualStencilFunc: lv,
    NumberKeyframeTrack: ts,
    Object3D: Je,
    ObjectLoader: pu,
    ObjectSpaceNormalMap: Lf,
    OctahedronGeometry: ha,
    OneFactor: Zd,
    OneMinusDstAlphaFactor: Qd,
    OneMinusDstColorFactor: ef,
    OneMinusSrcAlphaFactor: hd,
    OneMinusSrcColorFactor: $d,
    OrthographicCamera: Ls,
    P3Primaries: kr,
    PCFShadowMap: cd,
    PCFSoftShadowMap: Gd,
    PMREMGenerator: Kr,
    Path: ji,
    PerspectiveCamera: yt,
    Plane: mn,
    PlaneGeometry: $r,
    PlaneHelper: id,
    PointLight: wc,
    PointLightHelper: Xu,
    Points: Vo,
    PointsMaterial: na,
    PolarGridHelper: $u,
    PolyhedronGeometry: di,
    PositionalAudio: wu,
    PropertyBinding: Ke,
    PropertyMixer: Bc,
    QuadraticBezierCurve: ra,
    QuadraticBezierCurve3: aa,
    Quaternion: Ut,
    QuaternionKeyframeTrack: pi,
    QuaternionLinearInterpolant: yc,
    RED_GREEN_RGTC2_Format: Dl,
    RED_RGTC1_Format: Tf,
    REVISION: Hc,
    RGBADepthPacking: Pf,
    RGBAFormat: Wt,
    RGBAIntegerFormat: _d,
    RGBA_ASTC_10x10_Format: Rl,
    RGBA_ASTC_10x5_Format: Tl,
    RGBA_ASTC_10x6_Format: wl,
    RGBA_ASTC_10x8_Format: Al,
    RGBA_ASTC_12x10_Format: Cl,
    RGBA_ASTC_12x12_Format: Pl,
    RGBA_ASTC_4x4_Format: _l,
    RGBA_ASTC_5x4_Format: xl,
    RGBA_ASTC_5x5_Format: vl,
    RGBA_ASTC_6x5_Format: yl,
    RGBA_ASTC_6x6_Format: Ml,
    RGBA_ASTC_8x5_Format: Sl,
    RGBA_ASTC_8x6_Format: bl,
    RGBA_ASTC_8x8_Format: El,
    RGBA_BPTC_Format: Pa,
    RGBA_ETC2_EAC_Format: gl,
    RGBA_PVRTC_2BPPV1_Format: pl,
    RGBA_PVRTC_4BPPV1_Format: fl,
    RGBA_S3TC_DXT1_Format: Aa,
    RGBA_S3TC_DXT3_Format: Ra,
    RGBA_S3TC_DXT5_Format: Ca,
    RGB_BPTC_SIGNED_Format: Ll,
    RGB_BPTC_UNSIGNED_Format: Il,
    RGB_ETC1_Format: Ef,
    RGB_ETC2_Format: ml,
    RGB_PVRTC_2BPPV1_Format: dl,
    RGB_PVRTC_4BPPV1_Format: ul,
    RGB_S3TC_DXT1_Format: wa,
    RGFormat: bf,
    RGIntegerFormat: gd,
    RawShaderMaterial: lc,
    Ray: hi,
    Raycaster: Du,
    Rec709Primaries: Vr,
    RectAreaLight: Pc,
    RedFormat: Sf,
    RedIntegerFormat: md,
    ReinhardToneMapping: ff,
    RenderTarget: go,
    RepeatWrapping: Dr,
    ReplaceStencilOp: Qx,
    ReverseSubtractEquation: qd,
    RingGeometry: tc,
    SIGNED_RED_GREEN_RGTC2_Format: Nl,
    SIGNED_RED_RGTC1_Format: Ul,
    SRGBColorSpace: vt,
    SRGBTransfer: nt,
    Scene: Io,
    ShaderChunk: ke,
    ShaderLib: nn,
    ShaderMaterial: jt,
    ShadowMaterial: cc,
    Shape: Fn,
    ShapeGeometry: nc,
    ShapePath: od,
    ShapeUtils: yn,
    ShortType: xf,
    Skeleton: Oo,
    SkeletonHelper: Wu,
    SkinnedMesh: No,
    Source: In,
    Sphere: Yt,
    SphereGeometry: ua,
    Spherical: Ou,
    SphericalHarmonics3: Lc,
    SplineCurve: oa,
    SpotLight: Ec,
    SpotLightHelper: Gu,
    Sprite: Uo,
    SpriteMaterial: ea,
    SrcAlphaFactor: ld,
    SrcAlphaSaturateFactor: tf,
    SrcColorFactor: Jd,
    StaticCopyUsage: gv,
    StaticDrawUsage: Hr,
    StaticReadUsage: fv,
    StereoCamera: Mu,
    StreamCopyUsage: xv,
    StreamDrawUsage: dv,
    StreamReadUsage: mv,
    StringKeyframeTrack: kn,
    SubtractEquation: Xd,
    SubtractiveBlending: ol,
    TOUCH: Vx,
    TangentSpaceNormalMap: mi,
    TetrahedronGeometry: ic,
    Texture: St,
    TextureLoader: hu,
    TorusGeometry: sc,
    TorusKnotGeometry: rc,
    Triangle: Un,
    TriangleFanDrawMode: $x,
    TriangleStripDrawMode: Jx,
    TrianglesDrawMode: Zx,
    TubeGeometry: ac,
    TwoPassDoubleSide: Gx,
    UVMapping: Gc,
    Uint16BufferAttribute: Zr,
    Uint32BufferAttribute: Jr,
    Uint8BufferAttribute: jl,
    Uint8ClampedBufferAttribute: eh,
    Uniform: Pu,
    UniformsGroup: Lu,
    UniformsLib: le,
    UniformsUtils: xp,
    UnsignedByteType: On,
    UnsignedInt248Type: ii,
    UnsignedIntType: Ln,
    UnsignedShort4444Type: fd,
    UnsignedShort5551Type: pd,
    UnsignedShortType: Wc,
    VSMShadowMap: pn,
    Vector2: Z,
    Vector3: A,
    Vector4: je,
    VectorKeyframeTrack: ns,
    VideoTexture: Jh,
    WebGL1Renderer: Co,
    WebGL3DRenderTarget: Hl,
    WebGLArrayRenderTarget: kl,
    WebGLCoordinateSystem: vn,
    WebGLCubeRenderTarget: xo,
    WebGLMultipleRenderTargets: Gl,
    WebGLRenderTarget: qt,
    WebGLRenderer: Ro,
    WebGLUtils: V0,
    WebGPUCoordinateSystem: Gr,
    WireframeGeometry: oc,
    WrapAroundEnding: Br,
    ZeroCurvatureEnding: zi,
    ZeroFactor: Yd,
    ZeroSlopeEnding: Vi,
    ZeroStencilOp: Kx,
    _SRGBAFormat: po,
    createCanvasElement: tp,
    sRGBEncoding: ri
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
function typedarray_to_vectype(typedArray, ndim) {
    if (ndim === 1) {
        return "float";
    } else if (typedArray instanceof Float32Array) {
        return "vec" + ndim;
    } else if (typedArray instanceof Int32Array) {
        return "ivec" + ndim;
    } else if (typedArray instanceof Uint32Array) {
        return "uvec" + ndim;
    } else {
        return;
    }
}
function attribute_type(attribute) {
    if (attribute) {
        return typedarray_to_vectype(attribute.array, attribute.itemSize);
    } else {
        return;
    }
}
function uniform_type(obj) {
    if (obj instanceof THREE.Uniform) {
        return uniform_type(obj.value);
    } else if (typeof obj === "number") {
        return "float";
    } else if (typeof obj === "boolean") {
        return "bool";
    } else if (obj instanceof THREE.Vector2) {
        return "vec2";
    } else if (obj instanceof THREE.Vector3) {
        return "vec3";
    } else if (obj instanceof THREE.Vector4) {
        return "vec4";
    } else if (obj instanceof THREE.Color) {
        return "vec4";
    } else if (obj instanceof THREE.Matrix3) {
        return "mat3";
    } else if (obj instanceof THREE.Matrix4) {
        return "mat4";
    } else if (obj instanceof THREE.Texture) {
        return "sampler2D";
    } else {
        return;
    }
}
function uniforms_to_type_declaration(uniform_dict) {
    let result = "";
    for(const name in uniform_dict){
        const uniform = uniform_dict[name];
        const type = uniform_type(uniform);
        result += `uniform ${type} ${name};\n`;
    }
    return result;
}
function attributes_to_type_declaration(attributes_dict) {
    let result = "";
    for(const name in attributes_dict){
        const attribute = attributes_dict[name];
        const type = attribute_type(attribute);
        result += `in ${type} ${name};\n`;
    }
    return result;
}
const _changeEvent = {
    type: "change"
};
const _startEvent = {
    type: "start"
};
const _endEvent = {
    type: "end"
};
const _ray = new hi();
const _plane = new mn();
const TILT_LIMIT = Math.cos(70 * yv.DEG2RAD);
class OrbitControls extends sn {
    constructor(object, domElement, allow_update, is_in_scene){
        super();
        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = "none";
        this.enabled = true;
        this.target = new A();
        this.cursor = new A();
        this.minDistance = 0;
        this.maxDistance = Infinity;
        this.minZoom = 0;
        this.maxZoom = Infinity;
        this.minTargetRadius = 0;
        this.maxTargetRadius = Infinity;
        this.minPolarAngle = 0;
        this.maxPolarAngle = Math.PI;
        this.minAzimuthAngle = -Infinity;
        this.maxAzimuthAngle = Infinity;
        this.enableDamping = false;
        this.dampingFactor = 0.05;
        this.enableZoom = true;
        this.zoomSpeed = 1.0;
        this.enableRotate = true;
        this.rotateSpeed = 1.0;
        this.enablePan = true;
        this.panSpeed = 1.0;
        this.screenSpacePanning = true;
        this.keyPanSpeed = 7.0;
        this.zoomToCursor = false;
        this.autoRotate = false;
        this.autoRotateSpeed = 2.0;
        this.keys = {
            LEFT: "ArrowLeft",
            UP: "ArrowUp",
            RIGHT: "ArrowRight",
            BOTTOM: "ArrowDown"
        };
        this.mouseButtons = {
            LEFT: zx.ROTATE,
            MIDDLE: zx.DOLLY,
            RIGHT: zx.PAN
        };
        this.touches = {
            ONE: Vx.ROTATE,
            TWO: Vx.DOLLY_PAN
        };
        this.target0 = this.target.clone();
        this.position0 = this.object.position.clone();
        this.zoom0 = this.object.zoom;
        this._domElementKeyEvents = null;
        this.getPolarAngle = function() {
            return spherical.phi;
        };
        this.getAzimuthalAngle = function() {
            return spherical.theta;
        };
        this.getDistance = function() {
            return this.object.position.distanceTo(this.target);
        };
        this.listenToKeyEvents = function(domElement) {
            domElement.addEventListener("keydown", onKeyDown);
            this._domElementKeyEvents = domElement;
        };
        this.stopListenToKeyEvents = function() {
            this._domElementKeyEvents.removeEventListener("keydown", onKeyDown);
            this._domElementKeyEvents = null;
        };
        this.saveState = function() {
            scope.target0.copy(scope.target);
            scope.position0.copy(scope.object.position);
            scope.zoom0 = scope.object.zoom;
        };
        this.reset = function() {
            scope.target.copy(scope.target0);
            scope.object.position.copy(scope.position0);
            scope.object.zoom = scope.zoom0;
            scope.object.updateProjectionMatrix();
            scope.dispatchEvent(_changeEvent);
            scope.update();
            state = STATE.NONE;
        };
        this.update = function() {
            const offset = new A();
            const quat = new Ut().setFromUnitVectors(object.up, new A(0, 1, 0));
            const quatInverse = quat.clone().invert();
            const lastPosition = new A();
            const lastQuaternion = new Ut();
            const lastTargetPosition = new A();
            const twoPI = 2 * Math.PI;
            return function update(deltaTime = null) {
                if (!allow_update()) {
                    return;
                }
                const position = scope.object.position;
                offset.copy(position).sub(scope.target);
                offset.applyQuaternion(quat);
                spherical.setFromVector3(offset);
                if (scope.autoRotate && state === STATE.NONE) {
                    rotateLeft(getAutoRotationAngle(deltaTime));
                }
                if (scope.enableDamping) {
                    spherical.theta += sphericalDelta.theta * scope.dampingFactor;
                    spherical.phi += sphericalDelta.phi * scope.dampingFactor;
                } else {
                    spherical.theta += sphericalDelta.theta;
                    spherical.phi += sphericalDelta.phi;
                }
                let min = scope.minAzimuthAngle;
                let max = scope.maxAzimuthAngle;
                if (isFinite(min) && isFinite(max)) {
                    if (min < -Math.PI) min += twoPI;
                    else if (min > Math.PI) min -= twoPI;
                    if (max < -Math.PI) max += twoPI;
                    else if (max > Math.PI) max -= twoPI;
                    if (min <= max) {
                        spherical.theta = Math.max(min, Math.min(max, spherical.theta));
                    } else {
                        spherical.theta = spherical.theta > (min + max) / 2 ? Math.max(min, spherical.theta) : Math.min(max, spherical.theta);
                    }
                }
                spherical.phi = Math.max(scope.minPolarAngle, Math.min(scope.maxPolarAngle, spherical.phi));
                spherical.makeSafe();
                if (scope.enableDamping === true) {
                    scope.target.addScaledVector(panOffset, scope.dampingFactor);
                } else {
                    scope.target.add(panOffset);
                }
                scope.target.sub(scope.cursor);
                scope.target.clampLength(scope.minTargetRadius, scope.maxTargetRadius);
                scope.target.add(scope.cursor);
                if (scope.zoomToCursor && performCursorZoom || scope.object.isOrthographicCamera) {
                    spherical.radius = clampDistance(spherical.radius);
                } else {
                    spherical.radius = clampDistance(spherical.radius * scale);
                }
                offset.setFromSpherical(spherical);
                offset.applyQuaternion(quatInverse);
                position.copy(scope.target).add(offset);
                scope.object.lookAt(scope.target);
                if (scope.enableDamping === true) {
                    sphericalDelta.theta *= 1 - scope.dampingFactor;
                    sphericalDelta.phi *= 1 - scope.dampingFactor;
                    panOffset.multiplyScalar(1 - scope.dampingFactor);
                } else {
                    sphericalDelta.set(0, 0, 0);
                    panOffset.set(0, 0, 0);
                }
                let zoomChanged = false;
                if (scope.zoomToCursor && performCursorZoom) {
                    let newRadius = null;
                    if (scope.object.isPerspectiveCamera) {
                        const prevRadius = offset.length();
                        newRadius = clampDistance(prevRadius * scale);
                        const radiusDelta = prevRadius - newRadius;
                        scope.object.position.addScaledVector(dollyDirection, radiusDelta);
                        scope.object.updateMatrixWorld();
                    } else if (scope.object.isOrthographicCamera) {
                        const mouseBefore = new A(mouse.x, mouse.y, 0);
                        mouseBefore.unproject(scope.object);
                        scope.object.zoom = Math.max(scope.minZoom, Math.min(scope.maxZoom, scope.object.zoom / scale));
                        scope.object.updateProjectionMatrix();
                        zoomChanged = true;
                        const mouseAfter = new A(mouse.x, mouse.y, 0);
                        mouseAfter.unproject(scope.object);
                        scope.object.position.sub(mouseAfter).add(mouseBefore);
                        scope.object.updateMatrixWorld();
                        newRadius = offset.length();
                    } else {
                        console.warn("WARNING: OrbitControls.js encountered an unknown camera type - zoom to cursor disabled.");
                        scope.zoomToCursor = false;
                    }
                    if (newRadius !== null) {
                        if (this.screenSpacePanning) {
                            scope.target.set(0, 0, -1).transformDirection(scope.object.matrix).multiplyScalar(newRadius).add(scope.object.position);
                        } else {
                            _ray.origin.copy(scope.object.position);
                            _ray.direction.set(0, 0, -1).transformDirection(scope.object.matrix);
                            if (Math.abs(scope.object.up.dot(_ray.direction)) < TILT_LIMIT) {
                                object.lookAt(scope.target);
                            } else {
                                _plane.setFromNormalAndCoplanarPoint(scope.object.up, scope.target);
                                _ray.intersectPlane(_plane, scope.target);
                            }
                        }
                    }
                } else if (scope.object.isOrthographicCamera) {
                    scope.object.zoom = Math.max(scope.minZoom, Math.min(scope.maxZoom, scope.object.zoom / scale));
                    scope.object.updateProjectionMatrix();
                    zoomChanged = true;
                }
                scale = 1;
                performCursorZoom = false;
                if (zoomChanged || lastPosition.distanceToSquared(scope.object.position) > EPS || 8 * (1 - lastQuaternion.dot(scope.object.quaternion)) > EPS || lastTargetPosition.distanceToSquared(scope.target) > 0) {
                    scope.dispatchEvent(_changeEvent);
                    lastPosition.copy(scope.object.position);
                    lastQuaternion.copy(scope.object.quaternion);
                    lastTargetPosition.copy(scope.target);
                    zoomChanged = false;
                    return true;
                }
                return false;
            };
        }();
        this.dispose = function() {
            scope.domElement.removeEventListener("contextmenu", onContextMenu);
            scope.domElement.removeEventListener("pointerdown", onPointerDown);
            scope.domElement.removeEventListener("pointercancel", onPointerUp);
            scope.domElement.removeEventListener("wheel", onMouseWheel);
            scope.domElement.removeEventListener("pointermove", onPointerMove);
            scope.domElement.removeEventListener("pointerup", onPointerUp);
            if (scope._domElementKeyEvents !== null) {
                scope._domElementKeyEvents.removeEventListener("keydown", onKeyDown);
                scope._domElementKeyEvents = null;
            }
        };
        const scope = this;
        const STATE = {
            NONE: -1,
            ROTATE: 0,
            DOLLY: 1,
            PAN: 2,
            TOUCH_ROTATE: 3,
            TOUCH_PAN: 4,
            TOUCH_DOLLY_PAN: 5,
            TOUCH_DOLLY_ROTATE: 6
        };
        let state = STATE.NONE;
        const EPS = 0.000001;
        const spherical = new Ou();
        const sphericalDelta = new Ou();
        let scale = 1;
        const panOffset = new A();
        const rotateStart = new Z();
        const rotateEnd = new Z();
        const rotateDelta = new Z();
        const panStart = new Z();
        const panEnd = new Z();
        const panDelta = new Z();
        const dollyStart = new Z();
        const dollyEnd = new Z();
        const dollyDelta = new Z();
        const dollyDirection = new A();
        const mouse = new Z();
        let performCursorZoom = false;
        const pointers = [];
        const pointerPositions = {};
        function getAutoRotationAngle(deltaTime) {
            if (deltaTime !== null) {
                return 2 * Math.PI / 60 * scope.autoRotateSpeed * deltaTime;
            } else {
                return 2 * Math.PI / 60 / 60 * scope.autoRotateSpeed;
            }
        }
        function getZoomScale() {
            return Math.pow(0.95, scope.zoomSpeed);
        }
        function rotateLeft(angle) {
            sphericalDelta.theta -= angle;
        }
        function rotateUp(angle) {
            sphericalDelta.phi -= angle;
        }
        const panLeft = function() {
            const v = new A();
            return function panLeft(distance, objectMatrix) {
                v.setFromMatrixColumn(objectMatrix, 0);
                v.multiplyScalar(-distance);
                panOffset.add(v);
            };
        }();
        const panUp = function() {
            const v = new A();
            return function panUp(distance, objectMatrix) {
                if (scope.screenSpacePanning === true) {
                    v.setFromMatrixColumn(objectMatrix, 1);
                } else {
                    v.setFromMatrixColumn(objectMatrix, 0);
                    v.crossVectors(scope.object.up, v);
                }
                v.multiplyScalar(distance);
                panOffset.add(v);
            };
        }();
        const pan = function() {
            const offset = new A();
            return function pan(deltaX, deltaY) {
                const element = scope.domElement;
                if (scope.object.isPerspectiveCamera) {
                    const position = scope.object.position;
                    offset.copy(position).sub(scope.target);
                    let targetDistance = offset.length();
                    targetDistance *= Math.tan(scope.object.fov / 2 * Math.PI / 180.0);
                    panLeft(2 * deltaX * targetDistance / element.clientHeight, scope.object.matrix);
                    panUp(2 * deltaY * targetDistance / element.clientHeight, scope.object.matrix);
                } else if (scope.object.isOrthographicCamera) {
                    panLeft(deltaX * (scope.object.right - scope.object.left) / scope.object.zoom / element.clientWidth, scope.object.matrix);
                    panUp(deltaY * (scope.object.top - scope.object.bottom) / scope.object.zoom / element.clientHeight, scope.object.matrix);
                } else {
                    console.warn("WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.");
                    scope.enablePan = false;
                }
            };
        }();
        function dollyOut(dollyScale) {
            if (scope.object.isPerspectiveCamera || scope.object.isOrthographicCamera) {
                scale /= dollyScale;
            } else {
                console.warn("WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.");
                scope.enableZoom = false;
            }
        }
        function dollyIn(dollyScale) {
            if (scope.object.isPerspectiveCamera || scope.object.isOrthographicCamera) {
                scale *= dollyScale;
            } else {
                console.warn("WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.");
                scope.enableZoom = false;
            }
        }
        function updateMouseParameters(event) {
            if (!scope.zoomToCursor) {
                return;
            }
            performCursorZoom = true;
            const rect = scope.domElement.getBoundingClientRect();
            const x = event.clientX - rect.left;
            const y = event.clientY - rect.top;
            const w = rect.width;
            const h = rect.height;
            mouse.x = x / w * 2 - 1;
            mouse.y = -(y / h) * 2 + 1;
            dollyDirection.set(mouse.x, mouse.y, 1).unproject(scope.object).sub(scope.object.position).normalize();
        }
        function clampDistance(dist) {
            return Math.max(scope.minDistance, Math.min(scope.maxDistance, dist));
        }
        function handleMouseDownRotate(event) {
            rotateStart.set(event.clientX, event.clientY);
        }
        function handleMouseDownDolly(event) {
            updateMouseParameters(event);
            dollyStart.set(event.clientX, event.clientY);
        }
        function handleMouseDownPan(event) {
            panStart.set(event.clientX, event.clientY);
        }
        function handleMouseMoveRotate(event) {
            rotateEnd.set(event.clientX, event.clientY);
            rotateDelta.subVectors(rotateEnd, rotateStart).multiplyScalar(scope.rotateSpeed);
            const element = scope.domElement;
            rotateLeft(2 * Math.PI * rotateDelta.x / element.clientHeight);
            rotateUp(2 * Math.PI * rotateDelta.y / element.clientHeight);
            rotateStart.copy(rotateEnd);
            scope.update();
        }
        function handleMouseMoveDolly(event) {
            dollyEnd.set(event.clientX, event.clientY);
            dollyDelta.subVectors(dollyEnd, dollyStart);
            if (dollyDelta.y > 0) {
                dollyOut(getZoomScale());
            } else if (dollyDelta.y < 0) {
                dollyIn(getZoomScale());
            }
            dollyStart.copy(dollyEnd);
            scope.update();
        }
        function handleMouseMovePan(event) {
            panEnd.set(event.clientX, event.clientY);
            panDelta.subVectors(panEnd, panStart).multiplyScalar(scope.panSpeed);
            pan(panDelta.x, panDelta.y);
            panStart.copy(panEnd);
            scope.update();
        }
        function handleMouseWheel(event) {
            updateMouseParameters(event);
            if (event.deltaY < 0) {
                dollyIn(getZoomScale());
            } else if (event.deltaY > 0) {
                dollyOut(getZoomScale());
            }
            scope.update();
        }
        function handleKeyDown(event) {
            let needsUpdate = false;
            switch(event.code){
                case scope.keys.UP:
                    if (event.ctrlKey || event.metaKey || event.shiftKey) {
                        rotateUp(2 * Math.PI * scope.rotateSpeed / scope.domElement.clientHeight);
                    } else {
                        pan(0, scope.keyPanSpeed);
                    }
                    needsUpdate = true;
                    break;
                case scope.keys.BOTTOM:
                    if (event.ctrlKey || event.metaKey || event.shiftKey) {
                        rotateUp(-2 * Math.PI * scope.rotateSpeed / scope.domElement.clientHeight);
                    } else {
                        pan(0, -scope.keyPanSpeed);
                    }
                    needsUpdate = true;
                    break;
                case scope.keys.LEFT:
                    if (event.ctrlKey || event.metaKey || event.shiftKey) {
                        rotateLeft(2 * Math.PI * scope.rotateSpeed / scope.domElement.clientHeight);
                    } else {
                        pan(scope.keyPanSpeed, 0);
                    }
                    needsUpdate = true;
                    break;
                case scope.keys.RIGHT:
                    if (event.ctrlKey || event.metaKey || event.shiftKey) {
                        rotateLeft(-2 * Math.PI * scope.rotateSpeed / scope.domElement.clientHeight);
                    } else {
                        pan(-scope.keyPanSpeed, 0);
                    }
                    needsUpdate = true;
                    break;
            }
            if (needsUpdate) {
                event.preventDefault();
                scope.update();
            }
        }
        function handleTouchStartRotate() {
            if (pointers.length === 1) {
                rotateStart.set(pointers[0].pageX, pointers[0].pageY);
            } else {
                const x = 0.5 * (pointers[0].pageX + pointers[1].pageX);
                const y = 0.5 * (pointers[0].pageY + pointers[1].pageY);
                rotateStart.set(x, y);
            }
        }
        function handleTouchStartPan() {
            if (pointers.length === 1) {
                panStart.set(pointers[0].pageX, pointers[0].pageY);
            } else {
                const x = 0.5 * (pointers[0].pageX + pointers[1].pageX);
                const y = 0.5 * (pointers[0].pageY + pointers[1].pageY);
                panStart.set(x, y);
            }
        }
        function handleTouchStartDolly() {
            const dx = pointers[0].pageX - pointers[1].pageX;
            const dy = pointers[0].pageY - pointers[1].pageY;
            const distance = Math.sqrt(dx * dx + dy * dy);
            dollyStart.set(0, distance);
        }
        function handleTouchStartDollyPan() {
            if (scope.enableZoom) handleTouchStartDolly();
            if (scope.enablePan) handleTouchStartPan();
        }
        function handleTouchStartDollyRotate() {
            if (scope.enableZoom) handleTouchStartDolly();
            if (scope.enableRotate) handleTouchStartRotate();
        }
        function handleTouchMoveRotate(event) {
            if (pointers.length == 1) {
                rotateEnd.set(event.pageX, event.pageY);
            } else {
                const position = getSecondPointerPosition(event);
                const x = 0.5 * (event.pageX + position.x);
                const y = 0.5 * (event.pageY + position.y);
                rotateEnd.set(x, y);
            }
            rotateDelta.subVectors(rotateEnd, rotateStart).multiplyScalar(scope.rotateSpeed);
            const element = scope.domElement;
            rotateLeft(2 * Math.PI * rotateDelta.x / element.clientHeight);
            rotateUp(2 * Math.PI * rotateDelta.y / element.clientHeight);
            rotateStart.copy(rotateEnd);
        }
        function handleTouchMovePan(event) {
            if (pointers.length === 1) {
                panEnd.set(event.pageX, event.pageY);
            } else {
                const position = getSecondPointerPosition(event);
                const x = 0.5 * (event.pageX + position.x);
                const y = 0.5 * (event.pageY + position.y);
                panEnd.set(x, y);
            }
            panDelta.subVectors(panEnd, panStart).multiplyScalar(scope.panSpeed);
            pan(panDelta.x, panDelta.y);
            panStart.copy(panEnd);
        }
        function handleTouchMoveDolly(event) {
            const position = getSecondPointerPosition(event);
            const dx = event.pageX - position.x;
            const dy = event.pageY - position.y;
            const distance = Math.sqrt(dx * dx + dy * dy);
            dollyEnd.set(0, distance);
            dollyDelta.set(0, Math.pow(dollyEnd.y / dollyStart.y, scope.zoomSpeed));
            dollyOut(dollyDelta.y);
            dollyStart.copy(dollyEnd);
        }
        function handleTouchMoveDollyPan(event) {
            if (scope.enableZoom) handleTouchMoveDolly(event);
            if (scope.enablePan) handleTouchMovePan(event);
        }
        function handleTouchMoveDollyRotate(event) {
            if (scope.enableZoom) handleTouchMoveDolly(event);
            if (scope.enableRotate) handleTouchMoveRotate(event);
        }
        function onPointerDown(event) {
            if (scope.enabled === false) return;
            if (pointers.length === 0) {
                scope.domElement.setPointerCapture(event.pointerId);
                scope.domElement.addEventListener("pointermove", onPointerMove);
                scope.domElement.addEventListener("pointerup", onPointerUp);
            }
            addPointer(event);
            if (event.pointerType === "touch") {
                onTouchStart(event);
            } else {
                onMouseDown(event);
            }
        }
        function onPointerMove(event) {
            if (scope.enabled === false) return;
            if (!is_in_scene(event)) return;
            if (event.pointerType === "touch") {
                onTouchMove(event);
            } else {
                onMouseMove(event);
            }
        }
        function onPointerUp(event) {
            removePointer(event);
            if (pointers.length === 0) {
                scope.domElement.releasePointerCapture(event.pointerId);
                scope.domElement.removeEventListener("pointermove", onPointerMove);
                scope.domElement.removeEventListener("pointerup", onPointerUp);
            }
            scope.dispatchEvent(_endEvent);
            state = STATE.NONE;
        }
        function onMouseDown(event) {
            let mouseAction;
            switch(event.button){
                case 0:
                    mouseAction = scope.mouseButtons.LEFT;
                    break;
                case 1:
                    mouseAction = scope.mouseButtons.MIDDLE;
                    break;
                case 2:
                    mouseAction = scope.mouseButtons.RIGHT;
                    break;
                default:
                    mouseAction = -1;
            }
            switch(mouseAction){
                case zx.DOLLY:
                    if (scope.enableZoom === false) return;
                    handleMouseDownDolly(event);
                    state = STATE.DOLLY;
                    break;
                case zx.ROTATE:
                    if (event.ctrlKey || event.metaKey || event.shiftKey) {
                        if (scope.enablePan === false) return;
                        handleMouseDownPan(event);
                        state = STATE.PAN;
                    } else {
                        if (scope.enableRotate === false) return;
                        handleMouseDownRotate(event);
                        state = STATE.ROTATE;
                    }
                    break;
                case zx.PAN:
                    if (event.ctrlKey || event.metaKey || event.shiftKey) {
                        if (scope.enableRotate === false) return;
                        handleMouseDownRotate(event);
                        state = STATE.ROTATE;
                    } else {
                        if (scope.enablePan === false) return;
                        handleMouseDownPan(event);
                        state = STATE.PAN;
                    }
                    break;
                default:
                    state = STATE.NONE;
            }
            if (state !== STATE.NONE) {
                scope.dispatchEvent(_startEvent);
            }
        }
        function onMouseMove(event) {
            switch(state){
                case STATE.ROTATE:
                    if (scope.enableRotate === false) return;
                    handleMouseMoveRotate(event);
                    break;
                case STATE.DOLLY:
                    if (scope.enableZoom === false) return;
                    handleMouseMoveDolly(event);
                    break;
                case STATE.PAN:
                    if (scope.enablePan === false) return;
                    handleMouseMovePan(event);
                    break;
            }
        }
        function onMouseWheel(event) {
            if (scope.enabled === false || scope.enableZoom === false || state !== STATE.NONE || !is_in_scene(event)) return;
            event.preventDefault();
            scope.dispatchEvent(_startEvent);
            handleMouseWheel(event);
            scope.dispatchEvent(_endEvent);
        }
        function onKeyDown(event) {
            if (scope.enabled === false || scope.enablePan === false) return;
            handleKeyDown(event);
        }
        function onTouchStart(event) {
            trackPointer(event);
            switch(pointers.length){
                case 1:
                    switch(scope.touches.ONE){
                        case Vx.ROTATE:
                            if (scope.enableRotate === false) return;
                            handleTouchStartRotate();
                            state = STATE.TOUCH_ROTATE;
                            break;
                        case Vx.PAN:
                            if (scope.enablePan === false) return;
                            handleTouchStartPan();
                            state = STATE.TOUCH_PAN;
                            break;
                        default:
                            state = STATE.NONE;
                    }
                    break;
                case 2:
                    switch(scope.touches.TWO){
                        case Vx.DOLLY_PAN:
                            if (scope.enableZoom === false && scope.enablePan === false) return;
                            handleTouchStartDollyPan();
                            state = STATE.TOUCH_DOLLY_PAN;
                            break;
                        case Vx.DOLLY_ROTATE:
                            if (scope.enableZoom === false && scope.enableRotate === false) return;
                            handleTouchStartDollyRotate();
                            state = STATE.TOUCH_DOLLY_ROTATE;
                            break;
                        default:
                            state = STATE.NONE;
                    }
                    break;
                default:
                    state = STATE.NONE;
            }
            if (state !== STATE.NONE) {
                scope.dispatchEvent(_startEvent);
            }
        }
        function onTouchMove(event) {
            trackPointer(event);
            switch(state){
                case STATE.TOUCH_ROTATE:
                    if (scope.enableRotate === false) return;
                    handleTouchMoveRotate(event);
                    scope.update();
                    break;
                case STATE.TOUCH_PAN:
                    if (scope.enablePan === false) return;
                    handleTouchMovePan(event);
                    scope.update();
                    break;
                case STATE.TOUCH_DOLLY_PAN:
                    if (scope.enableZoom === false && scope.enablePan === false) return;
                    handleTouchMoveDollyPan(event);
                    scope.update();
                    break;
                case STATE.TOUCH_DOLLY_ROTATE:
                    if (scope.enableZoom === false && scope.enableRotate === false) return;
                    handleTouchMoveDollyRotate(event);
                    scope.update();
                    break;
                default:
                    state = STATE.NONE;
            }
        }
        function onContextMenu(event) {
            if (scope.enabled === false) return;
            event.preventDefault();
        }
        function addPointer(event) {
            pointers.push(event);
        }
        function removePointer(event) {
            delete pointerPositions[event.pointerId];
            for(let i = 0; i < pointers.length; i++){
                if (pointers[i].pointerId == event.pointerId) {
                    pointers.splice(i, 1);
                    return;
                }
            }
        }
        function trackPointer(event) {
            let position = pointerPositions[event.pointerId];
            if (position === undefined) {
                position = new Z();
                pointerPositions[event.pointerId] = position;
            }
            position.set(event.pageX, event.pageY);
        }
        function getSecondPointerPosition(event) {
            const pointer = event.pointerId === pointers[0].pointerId ? pointers[1] : pointers[0];
            return pointerPositions[pointer.pointerId];
        }
        scope.domElement.addEventListener("contextmenu", onContextMenu);
        scope.domElement.addEventListener("pointerdown", onPointerDown);
        scope.domElement.addEventListener("pointercancel", onPointerUp);
        scope.domElement.addEventListener("wheel", onMouseWheel, {
            passive: false
        });
        this.update();
    }
}
function events2unitless(screen, event) {
    const { canvas , winscale , renderer  } = screen;
    const rect = canvas.getBoundingClientRect();
    const x = (event.clientX - rect.left) / winscale;
    const y = (event.clientY - rect.top) / winscale;
    return [
        x,
        renderer._height - y
    ];
}
function Identity4x4() {
    return new ze();
}
function in_scene(scene, mouse_event) {
    const [x, y] = events2unitless(scene.screen, mouse_event);
    const [sx, sy, sw, sh] = scene.viewport.value;
    return x >= sx && x < sx + sw && y >= sy && y < sy + sh;
}
function attach_3d_camera(canvas, makie_camera, cam3d, light_dir, scene) {
    if (cam3d === undefined) {
        return;
    }
    const [w, h] = makie_camera.resolution.value;
    const camera = new yt(cam3d.fov.value, w / h, 0.01, 100.0);
    const center = new A(...cam3d.lookat.value);
    camera.up = new A(...cam3d.upvector.value);
    camera.position.set(...cam3d.eyeposition.value);
    camera.lookAt(center);
    const use_orbit_cam = ()=>!(Bonito.can_send_to_julia && Bonito.can_send_to_julia());
    const controls = new OrbitControls(camera, canvas, use_orbit_cam, (e)=>in_scene(scene, e));
    controls.addEventListener("change", (e)=>{
        const view = camera.matrixWorldInverse;
        const projection = camera.projectionMatrix;
        const [width, height] = cam3d.resolution.value;
        const [x, y, z] = camera.position;
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
        camera.updateWorldMatrix();
        makie_camera.update_matrices(view.elements, projection.elements, [
            width,
            height
        ], [
            x,
            y,
            z
        ]);
        makie_camera.update_light_dir(light_dir.value);
    });
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
        this.view = new Pu(Identity4x4());
        this.projection = new Pu(Identity4x4());
        this.projectionview = new Pu(Identity4x4());
        this.pixel_space = new Pu(Identity4x4());
        this.pixel_space_inverse = new Pu(Identity4x4());
        this.projectionview_inverse = new Pu(Identity4x4());
        this.relative_space = new Pu(relative_space());
        this.relative_inverse = new Pu(relative_space().invert());
        this.clip_space = new Pu(Identity4x4());
        this.resolution = new Pu(new Z());
        this.eyeposition = new Pu(new A());
        this.preprojections = {};
        this.light_direction = new Pu(new A(-1, -1, -1).normalize());
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
    update_light_dir(light_dir) {
        const T = new He().setFromMatrix4(this.view.value).invert();
        const new_dir = new A().fromArray(light_dir);
        new_dir.applyMatrix3(T).normalize();
        this.light_direction.value = new_dir;
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
            const uniform = new Pu(matrix);
            this.preprojections[key] = uniform;
            return uniform;
        }
    }
}
const scene_cache = {};
function filter_by_key(dict, keys, default_value = false) {
    const result = {};
    keys.forEach((key)=>{
        const val = dict[key];
        if (val) {
            result[key] = val;
        } else {
            result[key] = default_value;
        }
    });
    return result;
}
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
    delete_three_scene(scene);
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
        const plot = plot_cache[plot_id];
        if (plot) {
            delete_plot(plot);
        }
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
function delete_plots(plot_uuids) {
    const plots = find_plots(plot_uuids);
    plots.forEach(delete_plot);
}
function convert_texture(scene, data) {
    const tex = create_texture(scene, data);
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
function to_uniform(scene, data) {
    if (data.type !== undefined) {
        if (data.type == "Sampler") {
            return convert_texture(scene, data);
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
function deserialize_uniforms(scene, data) {
    const result = {};
    for(const name in data){
        const value = data[name];
        if (value instanceof mod.Uniform) {
            result[name] = value;
        } else {
            const ser = to_uniform(scene, value);
            result[name] = new mod.Uniform(ser);
        }
    }
    return result;
}
function lines_vertex_shader(uniforms, attributes, is_linesegments) {
    const attribute_decl = attributes_to_type_declaration(attributes);
    const uniform_decl = uniforms_to_type_declaration(uniforms);
    const color = attribute_type(attributes.color_start) || uniform_type(uniforms.color_start);
    if (is_linesegments) {
        return `precision mediump int;
            precision highp float;

            ${attribute_decl}


            out vec3 f_quad_sdf;
            out vec2 f_truncation;              // invalid / not needed
            out float f_linestart;              // constant
            out float f_linelength;

            flat out vec2 f_extrusion;          // invalid / not needed
            flat out float f_linewidth;
            flat out vec4 f_pattern_overwrite;  // invalid / not needed
            flat out uint f_instance_id;
            flat out ${color} f_color1;
            flat out ${color} f_color2;
            flat out float f_alpha_weight;
            flat out float f_cumulative_length;
            flat out ivec2 f_capmode;
            flat out vec4 f_linepoints;         // invalid / not needed
            flat out vec4 f_miter_vecs;         // invalid / not needed

            ${uniform_decl}

            // Constants
            const float AA_RADIUS = 0.8;
            const float AA_THICKNESS = 2.0 * AA_RADIUS;


            ////////////////////////////////////////////////////////////////////////
            // Geometry/Position Utils
            ////////////////////////////////////////////////////////////////////////

            vec4 clip_space(vec3 point) {
                return projectionview * model * vec4(point, 1);
            }
            vec4 clip_space(vec2 point) { return clip_space(vec3(point, 0)); }

            vec3 screen_space(vec4 vertex) {
                return vec3(
                    (0.5 * vertex.xy / vertex.w + 0.5) * px_per_unit * resolution,
                    vertex.z / vertex.w + depth_shift
                );
            }

            vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
            vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }


            ////////////////////////////////////////////////////////////////////////
            // Main
            ////////////////////////////////////////////////////////////////////////


            void main() {
                bool is_end = position.x == 1.0;

                ////////////////////////////////////////////////////////////////////
                // Handle line geometry (position, directions)
                ////////////////////////////////////////////////////////////////////


                float width = px_per_unit * (is_end ? linewidth_end : linewidth_start);
                float halfwidth = 0.5 * max(AA_RADIUS, width);

                // restrict to visible area (see other shader)
                vec3 p1, p2;
                {
                    vec4 _p1 = clip_space(linepoint_start), _p2 = clip_space(linepoint_end);
                    vec4 v1 = _p2 - _p1;

                    if (_p1.w < 0.0)
                        _p1 = _p1 + (-_p1.w - _p1.z) / (v1.z + v1.w) * v1;
                    if (_p2.w < 0.0)
                        _p2 = _p2 + (-_p2.w - _p2.z) / (v1.z + v1.w) * v1;

                    p1 = screen_space(_p1);
                    p2 = screen_space(_p2);
                }

                // line vector (xy-normalized vectors in line direction)
                // Need z component for correct depth order
                vec3 v1 = p2 - p1;
                float segment_length = length(v1);
                v1 /= segment_length;

                // line normal (i.e. in linewidth direction)
                vec2 n1 = normal_vector(v1);


                ////////////////////////////////////////////////////////////////////
                // Static vertex data
                ////////////////////////////////////////////////////////////////////


                // invalid - no joints requiring pattern adjustments
                f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);

                // invalid - no joints requiring line sdfs to be extruded
                f_extrusion = vec2(0.0);

                // used to compute width sdf
                f_linewidth = halfwidth;

                f_instance_id = uint(2 * gl_InstanceID);

                // we restart patterns for each segment
                f_cumulative_length = 0.0;

                // no joints means these should be set to a "never discard" state
                f_linepoints = vec4(-1e12);
                f_miter_vecs = vec4(-1);


                ////////////////////////////////////////////////////////////////////
                // Varying vertex data
                ////////////////////////////////////////////////////////////////////


                // linecaps
                f_capmode = ivec2(linecap);

                // Vertex position (padded for joint & anti-aliasing)
                float v_offset = position.x * (0.5 * segment_length + halfwidth + AA_THICKNESS);
                float n_offset = (halfwidth + AA_THICKNESS) * position.y;
                vec3 point = 0.5 * (p1 + p2) + v_offset * v1 + n_offset * vec3(n1, 0);

                // SDF's
                vec2 VP1 = point.xy - p1.xy;
                vec2 VP2 = point.xy - p2.xy;

                // sdf of this segment
                f_quad_sdf.x = dot(VP1, -v1.xy);
                f_quad_sdf.y = dot(VP2,  v1.xy);
                f_quad_sdf.z = dot(VP1,  n1);

                // invalid - no joint to truncate
                f_truncation = vec2(-1e12);

                // simplified - no extrusion or joints means we just have:
                f_linestart = 0.0;
                f_linelength = segment_length;

                // for color sampling
                f_color1 = color_start;
                f_color2 = color_end;
                f_alpha_weight = min(1.0, width / AA_RADIUS);

                // clip space position
                gl_Position = vec4(2.0 * point.xy / (px_per_unit * resolution) - 1.0, point.z, 1.0);
            }
        `;
    } else {
        return `precision mediump int;
            precision highp float;

            ${attribute_decl}

            out vec3 f_quad_sdf;
            out vec2 f_truncation;
            out float f_linestart;
            out float f_linelength;

            flat out vec2 f_extrusion;
            flat out float f_linewidth;
            flat out vec4 f_pattern_overwrite;
            flat out uint f_instance_id;
            flat out ${color} f_color1;
            flat out ${color} f_color2;
            flat out float f_alpha_weight;
            flat out float f_cumulative_length;
            flat out ivec2 f_capmode;
            flat out vec4 f_linepoints;
            flat out vec4 f_miter_vecs;

            ${uniform_decl}

            // Constants
            const float AA_RADIUS = 0.8;
            const float AA_THICKNESS = 2.0 * AA_RADIUS;
            const int BUTT   = 0;
            const int SQUARE = 1;
            const int ROUND  = 2;
            const int MITER  = 0;
            const int BEVEL  = 3;


            ////////////////////////////////////////////////////////////////////////
            // Pattern handling
            ////////////////////////////////////////////////////////////////////////


            vec2 process_pattern(bool pattern, bool[4] isvalid, vec2 extrusion, float segment_length, float halfwidth) {
                // do not adjust stuff
                f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);
                return vec2(0);
            }

            vec2 process_pattern(sampler2D pattern, bool[4] isvalid, vec2 extrusion, float segment_length, float halfwidth) {
                // samples:
                //   -ext1  p1 ext1    -ext2 p2 ext2
                //      1   2   3        4   5   6
                // prev | joint |  this  | joint | next

                // default to no overwrite
                f_pattern_overwrite.x = -1e12;
                f_pattern_overwrite.z = +1e12;
                vec2 adjust = vec2(0);
                float width = 2.0 * halfwidth;
                float uv_scale = 1.0 / (width * pattern_length);
                float left, center, right;

                if (isvalid[0]) {
                    float offset = abs(extrusion[0]);
                    left   = width * texture(pattern, vec2(uv_scale * (lastlen_start - offset), 0.0)).x;
                    center = width * texture(pattern, vec2(uv_scale * (lastlen_start         ), 0.0)).x;
                    right  = width * texture(pattern, vec2(uv_scale * (lastlen_start + offset), 0.0)).x;

                    // cases:
                    // ++-, +--, +-+ => elongate backwards
                    // -++, --+      => shrink forward
                    // +++, ---, -+- => freeze around joint

                    if ((left > 0.0 && center > 0.0 && right > 0.0) || (left < 0.0 && right < 0.0)) {
                        // default/freeze
                        // overwrite until one AA gap past the corner/joint
                        f_pattern_overwrite.x = uv_scale * (lastlen_start + abs(extrusion[0]) + AA_RADIUS);
                        // using the sign of the center to decide between drawing or not drawing
                        f_pattern_overwrite.y = sign(center);
                    } else if (left > 0.0) {
                        // elongate backwards
                        adjust.x = -1.0;
                    } else if (right > 0.0) {
                        // shorten forward
                        adjust.x = 1.0;
                    } else {
                        // default - see above
                        f_pattern_overwrite.x = uv_scale * (lastlen_start + abs(extrusion[0]) + AA_RADIUS);
                        f_pattern_overwrite.y = sign(center);
                    }

                } // else there is no left segment, no left join, so no overwrite

                if (isvalid[3]) {
                    float offset = abs(extrusion[1]);
                    left   = width * texture(pattern, vec2(uv_scale * (lastlen_start + segment_length - offset), 0.0)).x;
                    center = width * texture(pattern, vec2(uv_scale * (lastlen_start + segment_length         ), 0.0)).x;
                    right  = width * texture(pattern, vec2(uv_scale * (lastlen_start + segment_length + offset), 0.0)).x;

                    if ((left > 0.0 && center > 0.0 && right > 0.0) || (left < 0.0 && right < 0.0)) {
                        // default/freeze
                        f_pattern_overwrite.z = uv_scale * (lastlen_start + segment_length - abs(extrusion[1]) - AA_RADIUS);
                        f_pattern_overwrite.w = sign(center);
                    } else if (left > 0.0) {
                        // shrink backwards
                        adjust.y = -1.0;
                    } else if (right > 0.0) {
                        // elongate forward
                        adjust.y = 1.0;
                    } else {
                        // default - see above
                        f_pattern_overwrite.z = uv_scale * (lastlen_start + segment_length - abs(extrusion[1]) - AA_RADIUS);
                        f_pattern_overwrite.w = sign(center);
                    }
                }

                return adjust;
            }


            ////////////////////////////////////////////////////////////////////////
            // Geometry/Position Utils
            ////////////////////////////////////////////////////////////////////////

            vec4 clip_space(vec3 point) {
                return projectionview * model * vec4(point, 1);
            }
            vec4 clip_space(vec2 point) { return clip_space(vec3(point, 0)); }

            vec3 screen_space(vec4 vertex) {
                return vec3(
                    (0.5 * vertex.xy / vertex.w + 0.5) * px_per_unit * resolution,
                    vertex.z / vertex.w + depth_shift
                );
            }

            vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
            vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }
            float sign_no_zero(float value) { return value >= 0.0 ? 1.0 : -1.0; }


            ////////////////////////////////////////////////////////////////////////
            // Main
            ////////////////////////////////////////////////////////////////////////


            void main() {
                bool is_end = position.x == 1.0;


                ////////////////////////////////////////////////////////////////////
                // Handle line geometry (position, directions)
                ////////////////////////////////////////////////////////////////////


                float width = px_per_unit * (is_end ? linewidth_end : linewidth_start);
                float halfwidth = 0.5 * max(AA_RADIUS, width);

                bool[4] isvalid = bool[4](true, true, true, true);

                // To apply pixel space linewidths we transform line vertices to pixel space
                // here. This is dangerous with perspective projection as p.xyz / p.w sends
                // points from behind the camera to beyond far (clip z > 1), causing lines
                // to invert. To avoid this we translate points along the line direction,
                // moving them to the edge of the visible area.
                vec3 p0, p1, p2, p3;
                {
                    // All in clip space
                    vec4 clip_p0 = clip_space(linepoint_prev);
                    vec4 clip_p1 = clip_space(linepoint_start);
                    vec4 clip_p2 = clip_space(linepoint_end);
                    vec4 clip_p3 = clip_space(linepoint_next);

                    vec4 v1 = clip_p2 - clip_p1;

                    // With our perspective projection matrix clip.w = -view.z with
                    // clip.w < 0.0 being behind the camera.
                    // Note that if the signs in the projectionmatrix change, this may become wrong.
                    if (clip_p1.w < 0.0) {
                        // the line connects outside the visible area so we may consider it disconnected
                        isvalid[0] = false;
                        // A clip position is visible if -w <= z <= w. To move the line along
                        // the line direction v to the start of the visible area, we solve:
                        //   p.z + t * v.z = +-(p.w + t * v.w)
                        // where (-) gives us the result for the near clipping plane as p.z
                        // and p.w share the same sign and p.z/p.w = -1.0 is the near plane.
                        clip_p1 = clip_p1 + (-clip_p1.w - clip_p1.z) / (v1.z + v1.w) * v1;
                    }
                    if (clip_p2.w < 0.0) {
                        isvalid[3] = false;
                        clip_p2 = clip_p2 + (-clip_p2.w - clip_p2.z) / (v1.z + v1.w) * v1;
                    }

                    // transform clip -> screen space, applying xyz / w normalization (which
                    // is now save as all vertices are in front of the camera)
                    p0 = screen_space(clip_p0); // start of previous segment
                    p1 = screen_space(clip_p1); // end of previous segment, start of current segment
                    p2 = screen_space(clip_p2); // end of current segment, start of next segment
                    p3 = screen_space(clip_p3); // end of next segment
                }

                // doesn't work correctly with linepoint_x...
                isvalid[0] = p0 != p1;
                isvalid[3] = p2 != p3;

                // line vectors (xy-normalized vectors in line direction)
                // Need z component here for correct depth order
                vec3 v1 = p2 - p1;
                float segment_length = length(v1);
                v1 /= segment_length;

                // We don't need the z component for these
                vec2 v0 = v1.xy, v2 = v1.xy;
                bool[2] skip_joint;
                if (isvalid[0])
                    v0 = normalize(p1.xy - p0.xy);
                if (isvalid[3])
                    v2 = normalize(p3.xy - p2.xy);

                // line normals (i.e. in linewidth direction)
                vec2 n0 = normal_vector(v0);
                vec2 n1 = normal_vector(v1);
                vec2 n2 = normal_vector(v2);


                ////////////////////////////////////////////////////////////////////
                // Handle joint geometry
                ////////////////////////////////////////////////////////////////////


                // joint information

                // Miter normals (normal of truncated edge / vector to sharp corner)
                // Note: n0 + n1 = vec(0) for a 180° change in direction. +-(v0 - v1) is the
                //       same direction, but becomes vec(0) at 0°, so we can use it instead
                vec2 miter = vec2(dot(v0, v1.xy), dot(v1.xy, v2));
                vec2 miter_n1 = miter.x < -0.0 ?
                    sign_no_zero(dot(v0.xy, n1)) * normalize(v0.xy - v1.xy) : normalize(n0 + n1);
                vec2 miter_n2 = miter.y < -0.0 ?
                    sign_no_zero(dot(v1.xy, n2)) * normalize(v1.xy - v2.xy) : normalize(n1 + n2);

                // Are we truncating the joint based on miter limit or joinstyle?
                // bevel / always truncate doesn't work with v1 == v2 (v0) so we use allow
                // miter joints a when v1 ≈ v2 (v0)
                bool[2] is_truncated = bool[2](
                    (int(joinstyle) == BEVEL) ? miter.x < 0.99 : miter.x < miter_limit,
                    (int(joinstyle) == BEVEL) ? miter.y < 0.99 : miter.y < miter_limit
                );

                // miter vectors (line vector matching miter normal)
                vec2 miter_v1 = -normal_vector(miter_n1);
                vec2 miter_v2 = -normal_vector(miter_n2);

                // distance between p1/2 and respective sharp corner
                float miter_offset1 = dot(miter_n1, n1); // = dot(miter_v1, v1)
                float miter_offset2 = dot(miter_n2, n1); // = dot(miter_v2, v1)

                // How far the line needs to extend to accomodate the joint.
                // These are calculated as prefactors to v1 so that the line quad
                // is given by:
                //      p1 + w * extrusion[0] * v1  -----  p2 + w * extrusion[1] * v1
                //                |                                 |
                //      p1 + w * extrusion[0] * v1  -----  p2 + w * extrusion[1] * v1
                // with w = halfwidth for drawn corners and w = halfwidth + AA_THICKNESS
                // for the corners of quad. The sign difference due to miter joints
                // is included based on the current vertex position (position.y).
                // (truncated miter joints do not differ here)
                vec2 extrusion;

                if (is_truncated[0]) {
                    // need to extend segment to include previous segments corners for truncated join
                    extrusion[0] = -abs(miter_offset1 / dot(miter_v1, n1));
                } else {
                    // shallow/spike join needs to include point where miter normal meets outer line edge
                    extrusion[0] = position.y * dot(miter_n1, v1.xy) / miter_offset1;
                }

                if (is_truncated[1]) {
                    extrusion[1] = abs(miter_offset2 / dot(miter_n2, v1.xy));
                } else {
                    extrusion[1] = position.y * dot(miter_n2, v1.xy) / miter_offset2;
                }


                ////////////////////////////////////////////////////////////////////
                // Joint adjustments
                ////////////////////////////////////////////////////////////////////


                // Miter joints can cause vertices to move past each other, e.g.
                //  _______
                //  '.   .'
                //     x
                //   '---'
                // To avoid drawing the "inverted" section we move the relevant
                // vertices to the crossing point (x) using this scaling factor.
                // TODO: skipping this for linestart/end avoid round and square
                //       being cut off but causes overlap...
                float shape_factor = 1.0;
                if ((isvalid[0] && isvalid[3]) || (int(linecap) == BUTT))
                    shape_factor = segment_length / max(segment_length,
                        (halfwidth + AA_THICKNESS) * (extrusion[0] - extrusion[1]));

                // If a pattern starts or stops drawing in a joint it will get
                // fractured across the joint. To avoid this we either:
                // - adjust the involved line segments so that the patterns ends
                //   on straight line quad (adjustment becomes +1.0 or -1.0)
                // - or adjust the pattern to start/stop outside of the joint
                //   (f_pattern_overwrite is set, adjustment is 0.0)
                vec2 adjustment = process_pattern(
                    pattern, isvalid, halfwidth * extrusion, segment_length, halfwidth
                );

                // If adjustment != 0.0 we replace a joint by an extruded line,
                // so we no longer need to shrink the line for the joint to fit.
                if (adjustment[0] != 0.0 || adjustment[1] != 0.0)
                    shape_factor = 1.0;

                ////////////////////////////////////////////////////////////////////
                // Static vertex data
                ////////////////////////////////////////////////////////////////////

                // For truncated miter joints we discard overlapping sections of the two
                // involved line segments. To identify which sections overlap we calculate
                // the signed distance in +- miter vector direction from the shared line
                // point in fragment shader. We pass the necessary data here. If we do not
                // have a truncated joint we adjust the data here to never discard.
                // Why not calculate the sdf here?
                // If we calculate the sdf here and pass it as an interpolated vertex output
                // the values we get between the two line segments will differ since the
                // the vertices each segment interpolates from differ. This causes the
                // discard check to rarely be true or false for both segments, resulting in
                // duplicated or missing pixel/fragment draw.
                // Passing the line point and miter vector instead should fix this issue,
                // because both of these values come from the same calculation between the
                // two segments. I.e. (previous segment).p2 == (next segment).p1 and
                // (previous segment).miter_v2 == (next segment).miter_v1 should be the case.
                if (isvalid[0] && is_truncated[0] && (adjustment[0] == 0.0)) {
                    f_linepoints.xy = p1.xy + px_per_unit * scene_origin;   // FragCoords are relative to the window
                    f_miter_vecs.xy = -miter_v1.xy;                         // but p1/p2 is relative to the scene origin
                } else {
                    f_linepoints.xy = vec2(-1e12);          // FragCoord > 0
                    f_miter_vecs.xy = normalize(vec2(-1));
                }
                if (isvalid[3] && is_truncated[1] && (adjustment[1] == 0.0)) {
                    f_linepoints.zw = p2.xy + px_per_unit * scene_origin;
                    f_miter_vecs.zw = miter_v2.xy;
                } else {
                    f_linepoints.zw = vec2(-1e12);
                    f_miter_vecs.zw = normalize(vec2(-1));
                }

                // Used to elongate sdf to include joints
                // if start/end         elongate slightly so that there is no AA gap in loops
                // if joint skipped     elongate to new length
                // if normal joint      elongate a lot to let shape/truncation handle joint
                f_extrusion = vec2(
                    !isvalid[0] ? min(AA_RADIUS, halfwidth) : (adjustment[0] == 0.0 ? 1e12 : halfwidth * abs(extrusion[0])),
                    !isvalid[3] ? min(AA_RADIUS, halfwidth) : (adjustment[1] == 0.0 ? 1e12 : halfwidth * abs(extrusion[1]))
                );

                // used to compute width sdf
                f_linewidth = halfwidth;

                f_instance_id = uint(gl_InstanceID);

                f_cumulative_length = lastlen_start;

                // linecap + joinstyle
                f_capmode = ivec2(
                    isvalid[0] ? joinstyle : linecap,
                    isvalid[3] ? joinstyle : linecap
                );


                ////////////////////////////////////////////////////////////////////
                // Varying vertex data
                ////////////////////////////////////////////////////////////////////


                vec3 offset;
                int x = int(is_end);
                if (adjustment[x] == 0.0) {
                    if (is_truncated[x] || !isvalid[3 * x]) {
                        // handle overlap in fragment shader via SDF comparison
                        offset = shape_factor * (
                            position.x * (halfwidth * max(1.0, abs(extrusion[x])) + AA_THICKNESS) * v1 +
                            vec3(position.y * (halfwidth + AA_THICKNESS) * n1, 0)
                        );
                    } else {
                        // handle overlap by adjusting geometry
                        // TODO: should this include z in miter_n?
                        offset = position.y * shape_factor *
                            (halfwidth + AA_THICKNESS) /
                            float[2](miter_offset1, miter_offset2)[x] *
                            vec3(vec2[2](miter_n1, miter_n2)[x], 0);
                    }
                } else {
                    // discard joint for cleaner pattern handling
                    offset =
                        adjustment[x] * (halfwidth * abs(extrusion[x]) + AA_THICKNESS) * v1 +
                        vec3(position.y * (halfwidth + AA_THICKNESS) * n1, 0);
                }

                // Vertex position (padded for joint & anti-aliasing)
                vec3 point = vec3[2](p1, p2)[x] + offset;

                // SDF's
                vec2 VP1 = point.xy - p1.xy;
                vec2 VP2 = point.xy - p2.xy;

                // sdf of this segment
                f_quad_sdf.x = dot(VP1, -v1.xy);
                f_quad_sdf.y = dot(VP2,  v1.xy);
                f_quad_sdf.z = dot(VP1,  n1);

                // sdf for creating a flat cap on truncated joints
                // (sign(dot(...)) detects if line bends left or right)
                f_truncation.x = !is_truncated[0] ? -1.0 :
                    dot(VP1, sign(dot(miter_n1, -v1.xy)) * miter_n1) - halfwidth * abs(miter_offset1)
                    - abs(adjustment[0]) * 1e12;
                f_truncation.y = !is_truncated[1] ? -1.0 :
                    dot(VP2, sign(dot(miter_n2, +v1.xy)) * miter_n2) - halfwidth * abs(miter_offset2)
                    - abs(adjustment[1]) * 1e12;

                // Colors should be sampled based on the normalized distance from the
                // extruded edge (varies with offset in n direction)
                // - correcting for this with per-vertex colors results visible face border
                // - calculating normalized distance here will cause div 0/negative
                //   issues as (linelength +- (extrusion[0] + extrusion[1])) <= 0 is possible
                // So defer color interpolation to fragment shader
                f_linestart = shape_factor * halfwidth * extrusion[0];
                f_linelength = max(1.0, segment_length - shape_factor * halfwidth * (extrusion[0] - extrusion[1]));

                // for color sampling
                f_color1 = color_start;
                f_color2 = color_end;
                f_alpha_weight = min(1.0, width / AA_RADIUS);

                // clip space position
                gl_Position = vec4(2.0 * point.xy / (px_per_unit * resolution) - 1.0, point.z, 1.0);
            }
        `;
    }
}
function lines_fragment_shader(uniforms, attributes) {
    const color_uniforms = filter_by_key(uniforms, [
        "picking",
        "pattern",
        "pattern_length",
        "colorrange",
        "colormap",
        "nan_color",
        "highclip",
        "lowclip"
    ]);
    const uniform_decl = uniforms_to_type_declaration(color_uniforms);
    const color = attribute_type(attributes.color_start) || uniform_type(uniforms.color_start);
    return `
    // uncomment for debug rendering
    // #define DEBUG

    precision mediump int;
    precision highp float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    in highp vec3 f_quad_sdf;
    in vec2 f_truncation;
    in float f_linestart;
    in float f_linelength;

    flat in float f_linewidth;
    flat in vec4 f_pattern_overwrite;
    flat in vec2 f_extrusion;
    flat in ${color} f_color1;
    flat in ${color} f_color2;
    flat in float f_alpha_weight;
    flat in uint f_instance_id;
    flat in float f_cumulative_length;
    flat in ivec2 f_capmode;
    flat in vec4 f_linepoints;
    flat in vec4 f_miter_vecs;

    uniform uint object_id;
    ${uniform_decl}

    out vec4 fragment_color;

    // Half width of antialiasing smoothstep
    const float AA_RADIUS = 0.8;
    // space allocated for AA
    const float AA_THICKNESS = 2.0 * AA_RADIUS;
    const int BUTT   = 0;
    const int SQUARE = 1;
    const int ROUND  = 2;
    const int MITER  = 0;
    const int BEVEL  = 3;

    float aastep(float threshold, float value) {
        return smoothstep(threshold-AA_RADIUS, threshold+AA_RADIUS, value);
    }


    ////////////////////////////////////////////////////////////////////////
    // Color handling
    ////////////////////////////////////////////////////////////////////////


    vec4 get_color_from_cmap(float value, sampler2D colormap, vec2 colorrange) {
        float cmin = colorrange.x;
        float cmax = colorrange.y;
        if (value <= cmax && value >= cmin) {
            // in value range, continue!
        } else if (value < cmin) {
            return lowclip;
        } else if (value > cmax) {
            return highclip;
        } else {
            // isnan CAN be broken (of course) -.-
            // so if outside value range and not smaller/bigger min/max we assume NaN
            return nan_color;
        }
        float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
        // 1/0 corresponds to the corner of the colormap, so to properly interpolate
        // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
        float stepsize = 1.0 / float(textureSize(colormap, 0));
        i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
        return texture(colormap, vec2(i01, 0.0));
    }

    vec4 get_color(float color, sampler2D colormap, vec2 colorrange) {
        return get_color_from_cmap(color, colormap, colorrange);
    }

    vec4 get_color(vec4 color, bool colormap, bool colorrange) {
        return color;
    }
    vec4 get_color(vec3 color, bool colormap, bool colorrange) {
        return vec4(color, 1.0);
    }


    ////////////////////////////////////////////////////////////////////////
    // Pattern sampling
    ////////////////////////////////////////////////////////////////////////


    float get_pattern_sdf(sampler2D pattern, vec2 uv){

        // f_pattern_overwrite.x
        //      v           joint
        //    ----------------
        //      |          |
        //    ----------------
        // joint           ^
        //      f_pattern_overwrite.z

        float w = 2.0 * f_linewidth;
        if (uv.x <= f_pattern_overwrite.x) {
            // overwrite for pattern with "ON" to the right (positive uv.x)
            float sdf_overwrite = w * pattern_length * (f_pattern_overwrite.x - uv.x);
            // pattern value where we start overwriting
            float edge_sample = w * texture(pattern, vec2(f_pattern_overwrite.x, 0.5)).x;
            // offset for overwrite to smoothly connect between sampling and edge
            float sdf_offset = max(f_pattern_overwrite.y * edge_sample, -AA_RADIUS);
            // add offset and apply direction ("ON" to left or right) to overwrite
            return f_pattern_overwrite.y * (sdf_overwrite + sdf_offset);
        } else if (uv.x >= f_pattern_overwrite.z) {
            // same as above (other than mirroring overwrite direction)
            float sdf_overwrite = w * pattern_length * (uv.x - f_pattern_overwrite.z);
            float edge_sample = w * texture(pattern, vec2(f_pattern_overwrite.z, 0.5)).x;
            float sdf_offset = max(f_pattern_overwrite.w * edge_sample, -AA_RADIUS);
            return f_pattern_overwrite.w * (sdf_overwrite + sdf_offset);
        } else
            // in allowed range
            return w * texture(pattern, uv).x;
    }

    float get_pattern_sdf(bool _, vec2 uv){
        return -10.0;
    }

    vec4 pack_int(uint id, uint index) {
        vec4 unpack;
        unpack.x = float((id & uint(0xff00)) >> 8) / 255.0;
        unpack.y = float((id & uint(0x00ff)) >> 0) / 255.0;
        unpack.z = float((index & uint(0xff00)) >> 8) / 255.0;
        unpack.w = float((index & uint(0x00ff)) >> 0) / 255.0;
        return unpack;
    }


    void main(){
        vec4 color;

        // f_quad_sdf.x is the distance from p1, negative in v1 direction.
        vec2 uv = vec2(
            (f_cumulative_length - f_quad_sdf.x) / (2.0 * f_linewidth * pattern_length),
            0.5 + 0.5 * f_quad_sdf.z / f_linewidth
        );

    #ifndef DEBUG
        // discard fragments that are other side of the truncated joint
        float discard_sdf1 = dot(gl_FragCoord.xy - f_linepoints.xy, f_miter_vecs.xy);
        float discard_sdf2 = dot(gl_FragCoord.xy - f_linepoints.zw, f_miter_vecs.zw);
        if ((f_quad_sdf.x > 0.0 && discard_sdf1 > 0.0) ||
            (f_quad_sdf.y > 0.0 && discard_sdf2 >= 0.0))
            discard;

        float sdf;

        // f_quad_sdf.x includes everything from p1 in p2-p1 direction, i.e. >
        // f_quad_sdf.y includes everything from p2 in p1-p2 direction, i.e. <
        // <   < | >    < >    < | >   >
        // <   < 1->----<->----<-2 >   >
        // <   < | >    < >    < | >   >
        if (f_capmode.x == ROUND) {
            // in circle(p1, halfwidth) || is beyond p1 in p2-p1 direction
            sdf = min(sqrt(f_quad_sdf.x * f_quad_sdf.x + f_quad_sdf.z * f_quad_sdf.z) - f_linewidth, f_quad_sdf.x);
        } else if (f_capmode.x == SQUARE) {
            // everything in p2-p1 direction shifted by halfwidth in p1-p2 direction (i.e. include more)
            sdf = f_quad_sdf.x - f_linewidth;
        } else { // miter or bevel joint or :butt cap
            // variable shift in -(p2-p1) direction to make space for joints
            sdf = f_quad_sdf.x - f_extrusion.x;
            // do truncate joints
            sdf = max(sdf, f_truncation.x);
        }

        // Same as above but for p2
        if (f_capmode.y == ROUND) {
            sdf = max(sdf,
                min(sqrt(f_quad_sdf.y * f_quad_sdf.y + f_quad_sdf.z * f_quad_sdf.z) - f_linewidth, f_quad_sdf.y)
            );
        } else if (f_capmode.y == SQUARE) {
            sdf = max(sdf, f_quad_sdf.y - f_linewidth);
        } else { // miter or bevel joint or :butt cap
            sdf = max(sdf, f_quad_sdf.y - f_extrusion.y);
            sdf = max(sdf, f_truncation.y);
        }

        // distance in linewidth direction
        // f_quad_sdf.z is 0 along the line connecting p1 and p2 and increases along line-normal direction
        //  ^  |  ^      ^  | ^
        //     1------------2
        //  ^  |  ^      ^  | ^
        sdf = max(sdf, abs(f_quad_sdf.z) - f_linewidth);

        // inner truncation (AA for overlapping parts)
        // min(a, b) keeps what is inside a and b
        // where a is the smoothly cut of part just before discard triggers (i.e. visible)
        // and b is the (smoothly) cut of part where the discard triggers
        // 100.0x sdf makes the sdf much more sharply, avoiding overdraw in the center
        sdf = max(sdf, min(f_quad_sdf.x + 1.0, 100.0 * discard_sdf1 - 1.0));
        sdf = max(sdf, min(f_quad_sdf.y + 1.0, 100.0 * discard_sdf2 - 1.0));

        // pattern application
        sdf = max(sdf, get_pattern_sdf(pattern, uv));

        // draw

        //  v- edge
        //   .---------------
        //    '.
        //      p1      v1
        //        '.   --->
        //          '----------
        // -f_quad_sdf.x is the distance from p1, positive in v1 direction
        // f_linestart is the distance between p1 and the left edge along v1 direction
        // f_start_length.y is the distance between the edges of this segment, in v1 direction
        // so this is 0 at the left edge and 1 at the right edge (with extrusion considered)
        float factor = (-f_quad_sdf.x - f_linestart) / f_linelength;
        color = get_color(f_color1 + factor * (f_color2 - f_color1), colormap, colorrange);

        color.a *= aastep(0.0, -sdf) * f_alpha_weight;
    #endif

    #ifdef DEBUG
        // base color
        color = vec4(0.5, 0.5, 0.5, 0.2);
        color.rgb += (2.0 * mod(float(f_instance_id), 2.0) - 1.0) * 0.1;

        // show color interpolation as brightness gradient
        // float factor = (-f_quad_sdf.x - f_linestart) / f_linelength;
        // color.rgb += (2.0 * factor - 1.0) * 0.2;

        // mark "outside" define by quad_sdf in black
        float sdf = max(f_quad_sdf.x - f_extrusion.x, f_quad_sdf.y - f_extrusion.y);
        sdf = max(sdf, abs(f_quad_sdf.z) - f_linewidth);
        color.rgb -= vec3(0.4) * step(0.0, sdf);

        // Mark discarded space in red/blue
        float discard_sdf1 = dot(gl_FragCoord.xy - f_linepoints.xy, f_miter_vecs.xy);
        float discard_sdf2 = dot(gl_FragCoord.xy - f_linepoints.zw, f_miter_vecs.zw);
        if (f_quad_sdf.x > 0.0 && discard_sdf1 > 0.0)
            color.r += 0.5;
        if (f_quad_sdf.y > 0.0 && discard_sdf2 >= 0.0)
            color.b += 0.5;

        // remaining overlap as softer red/blue
        if (discard_sdf1 - 1.0 > 0.0)
            color.r += 0.2;
            color.r += 0.2;
        if (discard_sdf2 - 1.0 > 0.0)
            color.b += 0.2;

        // Mark regions excluded via truncation in green
        color.g += 0.5 * step(0.0, max(f_truncation.x, f_truncation.y));

        // and inner truncation as softer green
        if (min(f_quad_sdf.x + 1.0, 100.0 * discard_sdf1 - 1.0) > 0.0)
            color.g += 0.2;
        if (min(f_quad_sdf.y + 1.0, 100.0 * discard_sdf2 - 1.0) > 0.0)
            color.g += 0.2;

        // mark pattern in white
        color.rgb += vec3(0.3) * step(0.0, get_pattern_sdf(pattern, uv));
    #endif

        if (color.a <= 0.0)
            discard;

        if (picking) {
            if (color.a > 0.1) {
                fragment_color = pack_int(object_id, f_instance_id);
            }
            return;
        }
        fragment_color = vec4(color.rgb, color.a);
    }
    `;
}
function create_line_material(scene, uniforms, attributes, is_linesegments) {
    const uniforms_des = deserialize_uniforms(scene, uniforms);
    const mat = new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        glslVersion: THREE.GLSL3,
        vertexShader: lines_vertex_shader(uniforms_des, attributes, is_linesegments),
        fragmentShader: lines_fragment_shader(uniforms_des, attributes),
        transparent: true,
        blending: THREE.CustomBlending,
        blendSrc: THREE.SrcAlphaFactor,
        blendDst: THREE.OneMinusSrcAlphaFactor,
        blendSrcAlpha: THREE.ZeroFactor,
        blendDstAlpha: THREE.OneFactor,
        blendEquation: THREE.AddEquation
    });
    mat.uniforms.object_id = {
        value: 1
    };
    return mat;
}
function attach_interleaved_line_buffer(attr_name, geometry, data, ndim, is_segments, is_position) {
    const skip_elems = is_segments ? 2 * ndim : ndim;
    const buffer = new THREE.InstancedInterleavedBuffer(data, skip_elems, 1);
    buffer.count = Math.max(0, is_segments ? Math.floor(buffer.count - 1) : buffer.count - 3);
    geometry.setAttribute(attr_name + "_start", new THREE.InterleavedBufferAttribute(buffer, ndim, ndim));
    geometry.setAttribute(attr_name + "_end", new THREE.InterleavedBufferAttribute(buffer, ndim, 2 * ndim));
    if (is_position) {
        geometry.setAttribute(attr_name + "_prev", new THREE.InterleavedBufferAttribute(buffer, ndim, 0));
        geometry.setAttribute(attr_name + "_next", new THREE.InterleavedBufferAttribute(buffer, ndim, 3 * ndim));
    }
    return buffer;
}
function create_line_instance_geometry() {
    const geometry = new THREE.InstancedBufferGeometry();
    const instance_positions = [
        -1,
        -1,
        1,
        -1,
        1,
        1,
        -1,
        -1,
        1,
        1,
        -1,
        1
    ];
    geometry.setAttribute("position", new THREE.Float32BufferAttribute(instance_positions, 2));
    geometry.boundingSphere = new THREE.Sphere();
    geometry.boundingSphere.radius = 10000000000000;
    geometry.frustumCulled = false;
    return geometry;
}
function create_line_buffer(geometry, buffers, name, attr, is_segments, is_position) {
    const flat_buffer = attr.value.flat;
    const ndims = attr.value.type_length;
    const linebuffer = attach_interleaved_line_buffer(name, geometry, flat_buffer, ndims, is_segments, is_position);
    buffers[name] = linebuffer;
    return flat_buffer;
}
function create_line_buffers(geometry, buffers, attributes, is_segments) {
    for(let name in attributes){
        const attr = attributes[name];
        create_line_buffer(geometry, buffers, name, attr, is_segments, name == "linepoint");
    }
}
function attach_updates(mesh, buffers, attributes, is_segments) {
    for(let name in attributes){
        const attr = attributes[name];
        attr.on((new_vertex_data)=>{
            let buff = buffers[name];
            const new_flat_data = new_vertex_data.flat;
            const old_length = buff.array.length;
            if (old_length != new_flat_data.length) {
                mesh.geometry.dispose();
                mesh.geometry = create_line_instance_geometry();
                create_line_buffers(mesh.geometry, buffers, attributes, is_segments);
                mesh.geometry.instanceCount = mesh.geometry.attributes.linepoint_start.count;
            } else {
                buff.set(new_flat_data);
            }
            buff.needsUpdate = true;
            mesh.needsUpdate = true;
        });
    }
}
function _create_line(scene, line_data, is_segments) {
    const geometry = create_line_instance_geometry();
    const buffers = {};
    create_line_buffers(geometry, buffers, line_data.attributes, is_segments);
    const material = create_line_material(scene, line_data.uniforms, geometry.attributes, is_segments);
    material.depthTest = !line_data.overdraw.value;
    material.depthWrite = !line_data.transparency.value;
    material.uniforms.is_linesegments = {
        value: is_segments
    };
    const mesh = new THREE.Mesh(geometry, material);
    mesh.geometry.instanceCount = geometry.attributes.linepoint_start.count;
    attach_updates(mesh, buffers, line_data.attributes, is_segments);
    return mesh;
}
function create_line(scene, line_data) {
    return _create_line(scene, line_data, false);
}
function create_linesegments(scene, line_data) {
    return _create_line(scene, line_data, true);
}
function deserialize_plot(scene, data) {
    let mesh;
    const update_visible = (v)=>{
        mesh.visible = v;
        return;
    };
    if (data.plot_type === "lines") {
        mesh = create_line(scene, data);
    } else if (data.plot_type === "linesegments") {
        mesh = create_linesegments(scene, data);
    } else if ("instance_attributes" in data) {
        mesh = create_instanced_mesh(scene, data);
    } else {
        mesh = create_mesh(scene, data);
    }
    mesh.name = data.name;
    mesh.frustumCulled = false;
    mesh.matrixAutoUpdate = false;
    mesh.plot_uuid = data.uuid;
    update_visible(data.visible.value);
    data.visible.on(update_visible);
    connect_uniforms(mesh, data.uniform_updater);
    if (!(data.plot_type === "lines" || data.plot_type === "linesegments")) {
        connect_attributes(mesh, data.attribute_updater);
    }
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
    const { px_per_unit  } = scene.screen;
    plot_data.uniforms.resolution = cam.resolution;
    plot_data.uniforms.px_per_unit = new mod.Uniform(px_per_unit);
    if (plot_data.uniforms.preprojection) {
        const { space , markerspace  } = plot_data;
        plot_data.uniforms.preprojection = cam.preprojection_matrix(space.value, markerspace.value);
    }
    if (scene.camera_relative_light) {
        plot_data.uniforms.light_direction = cam.light_direction;
        scene.light_direction.on((value)=>{
            cam.update_light_dir(value);
        });
    } else {
        const light_dir = new mod.Vector3().fromArray(scene.light_direction.value);
        plot_data.uniforms.light_direction = new mod.Uniform(light_dir);
        scene.light_direction.on((value)=>{
            plot_data.uniforms.light_direction.value.fromArray(value);
        });
    }
    const p = deserialize_plot(scene, plot_data);
    plot_cache[p.plot_uuid] = p;
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
function convert_RGB_to_RGBA(rgbArray) {
    const length = rgbArray.length;
    const rgbaArray = new Float32Array(length / 3 * 4);
    for(let i = 0, j = 0; i < length; i += 3, j += 4){
        rgbaArray[j] = rgbArray[i];
        rgbaArray[j + 1] = rgbArray[i + 1];
        rgbaArray[j + 2] = rgbArray[i + 2];
        rgbaArray[j + 3] = 1.0;
    }
    return rgbaArray;
}
function create_texture_from_data(data) {
    let buffer = data.data;
    if (data.size.length == 3) {
        const tex = new mod.Data3DTexture(buffer, data.size[0], data.size[1], data.size[2]);
        tex.format = mod[data.three_format];
        tex.type = mod[data.three_type];
        return tex;
    } else {
        let format = mod[data.three_format];
        if (data.three_format == "RGBFormat") {
            buffer = convert_RGB_to_RGBA(buffer);
            format = mod.RGBAFormat;
        }
        return new mod.DataTexture(buffer, data.size[0], data.size[1], format, mod[data.three_type]);
    }
}
function create_texture(scene, data) {
    const buffer = data.data;
    if (buffer == "texture_atlas") {
        const { texture_atlas  } = scene.screen;
        if (texture_atlas) {
            return texture_atlas;
        } else {
            data.data = TEXTURE_ATLAS[0].value;
            const texture = create_texture_from_data(data);
            scene.screen.texture_atlas = texture;
            TEXTURE_ATLAS[0].on((new_data)=>{
                if (new_data === texture) {
                    return false;
                } else {
                    texture.image.data.set(new_data);
                    texture.needsUpdate = true;
                    return;
                }
            });
            return texture;
        }
    } else {
        return create_texture_from_data(data);
    }
}
function re_create_texture(old_texture, buffer, size) {
    let tex;
    if (size.length == 3) {
        tex = new mod.Data3DTexture(buffer, size[0], size[1], size[2]);
        tex.format = old_texture.format;
        tex.type = old_texture.type;
    } else {
        tex = new mod.DataTexture(buffer, size[0], size[1] ? size[1] : 1, old_texture.format, old_texture.type);
    }
    tex.minFilter = old_texture.minFilter;
    tex.magFilter = old_texture.magFilter;
    tex.anisotropy = old_texture.anisotropy;
    tex.wrapS = old_texture.wrapS;
    if (size.length > 1) {
        tex.wrapT = old_texture.wrapT;
    }
    if (size.length > 2) {
        tex.wrapR = old_texture.wrapR;
    }
    return tex;
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
function create_material(scene, program) {
    const is_volume = "volumedata" in program.uniforms;
    return new mod.RawShaderMaterial({
        uniforms: deserialize_uniforms(scene, program.uniforms),
        vertexShader: program.vertex_source,
        fragmentShader: program.fragment_source,
        side: is_volume ? mod.BackSide : mod.DoubleSide,
        transparent: true,
        glslVersion: mod.GLSL3,
        depthTest: !program.overdraw.value,
        depthWrite: !program.transparency.value
    });
}
function create_mesh(scene, program) {
    const buffer_geometry = new mod.BufferGeometry();
    const faces = new mod.BufferAttribute(program.faces.value, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    const material = create_material(scene, program);
    const mesh = new mod.Mesh(buffer_geometry, material);
    program.faces.on((x)=>{
        mesh.geometry.setIndex(new mod.BufferAttribute(x, 1));
    });
    return mesh;
}
function create_instanced_mesh(scene, program) {
    const buffer_geometry = new mod.InstancedBufferGeometry();
    const faces = new mod.BufferAttribute(program.faces.value, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, program.instance_attributes);
    const material = create_material(scene, program);
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
    scene.viewport = data.viewport;
    scene.backgroundcolor = data.backgroundcolor;
    scene.backgroundcolor_alpha = data.backgroundcolor_alpha;
    scene.clearscene = data.clearscene;
    scene.visible = data.visible;
    scene.camera_relative_light = data.camera_relative_light;
    scene.light_direction = data.light_direction;
    const camera = new MakieCamera();
    scene.wgl_camera = camera;
    function update_cam(camera_matrices, force) {
        if (!force) {
            if (!(Bonito.can_send_to_julia && Bonito.can_send_to_julia())) {
                return;
            }
        }
        const [view, projection, resolution, eyepos] = camera_matrices;
        camera.update_matrices(view, projection, resolution, eyepos);
    }
    if (data.cam3d_state) {
        attach_3d_camera(canvas, camera, data.cam3d_state, data.light_direction, scene);
    }
    update_cam(data.camera.value, true);
    camera.update_light_dir(data.light_direction.value);
    data.camera.on(update_cam);
    data.plots.forEach((plot_data)=>{
        add_plot(scene, plot_data);
    });
    scene.scene_children = data.children.map((child)=>{
        const childscene = deserialize_scene(child, screen);
        return childscene;
    });
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
function render_scene(scene, picking = false) {
    const { camera , renderer , px_per_unit  } = scene.screen;
    const canvas = renderer.domElement;
    if (!document.body.contains(canvas)) {
        console.log("removing WGL context, canvas is not in the DOM anymore!");
        if (scene.screen.texture_atlas) {
            const data = TEXTURE_ATLAS[0].value;
            TEXTURE_ATLAS[0].notify(scene.screen.texture_atlas, true);
            TEXTURE_ATLAS[0].value = data;
            scene.screen.texture_atlas = undefined;
        }
        delete_three_scene(scene);
        renderer.state.reset();
        renderer.dispose();
        return false;
    }
    if (!scene.visible.value) {
        return true;
    }
    renderer.autoClear = scene.clearscene.value;
    const area = scene.viewport.value;
    if (area) {
        const [x, y, w, h] = area.map((x)=>x * px_per_unit);
        renderer.setViewport(x, y, w, h);
        renderer.setScissor(x, y, w, h);
        renderer.setScissorTest(true);
        if (picking) {
            renderer.setClearAlpha(0);
            renderer.setClearColor(new mod.Color(0), 0.0);
        } else {
            const alpha = scene.backgroundcolor_alpha.value;
            renderer.setClearColor(scene.backgroundcolor.value, alpha);
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
    let future_id = undefined;
    function inner_throttle(...args) {
        const now = new Date().getTime();
        if (future_id !== undefined) {
            clearTimeout(future_id);
            future_id = undefined;
        }
        if (now - prev > delay) {
            prev = now;
            return func(...args);
        } else {
            future_id = setTimeout(()=>inner_throttle(...args), now - prev + 1);
        }
    }
    return inner_throttle;
}
function get_body_size() {
    const bodyStyle = window.getComputedStyle(document.body);
    const width_padding = parseInt(bodyStyle.paddingLeft, 10) + parseInt(bodyStyle.paddingRight, 10) + parseInt(bodyStyle.marginLeft, 10) + parseInt(bodyStyle.marginRight, 10);
    const height_padding = parseInt(bodyStyle.paddingTop, 10) + parseInt(bodyStyle.paddingBottom, 10) + parseInt(bodyStyle.marginTop, 10) + parseInt(bodyStyle.marginBottom, 10);
    const width = window.innerWidth - width_padding;
    const height = window.innerHeight - height_padding;
    return [
        width,
        height
    ];
}
function get_parent_size(canvas) {
    const rect = canvas.parentElement.getBoundingClientRect();
    return [
        rect.width,
        rect.height
    ];
}
function wglerror(gl, error) {
    switch(error){
        case gl.NO_ERROR:
            return "No error";
        case gl.INVALID_ENUM:
            return "Invalid enum";
        case gl.INVALID_VALUE:
            return "Invalid value";
        case gl.INVALID_OPERATION:
            return "Invalid operation";
        case gl.OUT_OF_MEMORY:
            return "Out of memory";
        case gl.CONTEXT_LOST_WEBGL:
            return "Context lost";
        default:
            return "Unknown error";
    }
}
function handleSource(string, errorLine) {
    const lines = string.split("\n");
    const lines2 = [];
    const from = Math.max(errorLine - 6, 0);
    const to = Math.min(errorLine + 6, lines.length);
    for(let i = from; i < to; i++){
        const line = i + 1;
        lines2.push(`${line === errorLine ? ">" : " "} ${line}: ${lines[i]}`);
    }
    return lines2.join("\n");
}
function getShaderErrors(gl, shader, type) {
    const status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    const errors = gl.getShaderInfoLog(shader).trim();
    if (status && errors === "") return "";
    const errorMatches = /ERROR: 0:(\d+)/.exec(errors);
    if (errorMatches) {
        const errorLine = parseInt(errorMatches[1]);
        return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
    } else {
        return errors;
    }
}
function on_shader_error(gl, program, glVertexShader, glFragmentShader) {
    const programLog = gl.getProgramInfoLog(program).trim();
    const vertexErrors = getShaderErrors(gl, glVertexShader, "vertex");
    const fragmentErrors = getShaderErrors(gl, glFragmentShader, "fragment");
    const vertexLog = gl.getShaderInfoLog(glVertexShader).trim();
    const fragmentLog = gl.getShaderInfoLog(glFragmentShader).trim();
    const err = "THREE.WebGLProgram: Shader Error " + wglerror(gl, gl.getError()) + " - " + "VALIDATE_STATUS " + gl.getProgramParameter(program, gl.VALIDATE_STATUS) + "\n\n" + "Program Info Log:\n" + programLog + "\n" + vertexErrors + "\n" + fragmentErrors + "\n" + "Fragment log:\n" + fragmentLog + "Vertex log:\n" + vertexLog;
    Bonito.Connection.send_warning(err);
}
function add_canvas_events(screen, comm, resize_to) {
    const { canvas , winscale  } = screen;
    function mouse_callback(event) {
        const [x, y] = events2unitless(screen, event);
        comm.notify({
            mouseposition: [
                x,
                y
            ]
        });
    }
    const notify_mouse_throttled = throttle_function(mouse_callback, 40);
    function mousemove(event) {
        notify_mouse_throttled(event);
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
    function resize_callback() {
        let width, height;
        if (resize_to == "body") {
            [width, height] = get_body_size();
        } else if (resize_to == "parent") {
            [width, height] = get_parent_size(canvas);
        }
        comm.notify({
            resize: [
                width / winscale,
                height / winscale
            ]
        });
    }
    if (resize_to) {
        const resize_callback_throttled = throttle_function(resize_callback, 100);
        window.addEventListener("resize", (event)=>resize_callback_throttled());
        resize_callback_throttled();
    }
}
function threejs_module(canvas) {
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
        powerPreference: "high-performance",
        precision: "highp",
        alpha: true,
        logarithmicDepthBuffer: true
    });
    renderer.debug.onShaderError = on_shader_error;
    renderer.setClearColor("#ffffff");
    return renderer;
}
function set_render_size(screen, width, height) {
    const { renderer , canvas , scalefactor , winscale , px_per_unit  } = screen;
    const [swidth, sheight] = [
        winscale * width,
        winscale * height
    ];
    const real_pixel_width = Math.ceil(width * px_per_unit);
    const real_pixel_height = Math.ceil(height * px_per_unit);
    renderer._width = width;
    renderer._height = height;
    canvas.width = real_pixel_width;
    canvas.height = real_pixel_height;
    canvas.style.width = swidth + "px";
    canvas.style.height = sheight + "px";
    renderer.setViewport(0, 0, real_pixel_width, real_pixel_height);
    add_picking_target(screen);
    return;
}
function add_picking_target(screen) {
    const { picking_target , canvas  } = screen;
    const [w, h] = [
        canvas.width,
        canvas.height
    ];
    if (picking_target) {
        if (picking_target.width == w && picking_target.height == h) {
            return;
        } else {
            picking_target.dispose();
        }
    }
    screen.picking_target = new mod.WebGLRenderTarget(w, h);
    return;
}
function create_scene(wrapper, canvas, canvas_width, scenes, comm, width, height, texture_atlas_obs, fps, resize_to, px_per_unit, scalefactor) {
    if (!scalefactor) {
        scalefactor = window.devicePixelRatio || 1.0;
    }
    if (!px_per_unit) {
        px_per_unit = scalefactor;
    }
    const renderer = threejs_module(canvas);
    TEXTURE_ATLAS[0] = texture_atlas_obs;
    if (!renderer) {
        const warning = getWebGLErrorMessage();
        wrapper.appendChild(warning);
    }
    const camera = new mod.PerspectiveCamera(45, 1, 0, 100);
    camera.updateProjectionMatrix();
    const pixel_ratio = window.devicePixelRatio || 1.0;
    const winscale = scalefactor / pixel_ratio;
    const screen = {
        renderer,
        camera,
        fps,
        canvas,
        px_per_unit,
        scalefactor,
        winscale,
        texture_atlas: undefined
    };
    add_canvas_events(screen, comm, resize_to);
    set_render_size(screen, width, height);
    const three_scene = deserialize_scene(scenes, screen);
    start_renderloop(three_scene);
    canvas_width.on((w_h)=>{
        set_render_size(screen, ...w_h);
    });
    return renderer;
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
function pick_native(scene, _x, _y, _w, _h) {
    const { renderer , picking_target , px_per_unit  } = scene.screen;
    [_x, _y, _w, _h] = [
        _x,
        _y,
        _w,
        _h
    ].map((x)=>Math.ceil(x * px_per_unit));
    const [x, y, w, h] = [
        _x,
        _y,
        _w,
        _h
    ];
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
    const { renderer  } = scene.screen;
    const [width, height] = [
        renderer._width,
        renderer._height
    ];
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
    const { renderer  } = scene.screen;
    const [width, height] = [
        renderer._width,
        renderer._height
    ];
    if (!(1.0 <= xy[0] <= width && 1.0 <= xy[1] <= height)) {
        return null;
    }
    const x0 = Math.max(1, xy[0] - range);
    const y0 = Math.max(1, xy[1] - range);
    const x1 = Math.min(width, Math.floor(xy[0] + range));
    const y1 = Math.min(height, Math.floor(xy[1] + range));
    const dx = x1 - x0;
    const dy = y1 - y0;
    const [plot_data, selected] = pick_native(scene, x0, y0, dx, dy);
    if (selected.length == 0) {
        return null;
    }
    const plot_matrix = plot_data.data;
    const distances = selected.map((x)=>range ^ 2);
    const x = xy[0] + 1 - x0;
    const y = xy[1] + 1 - y0;
    let pindex = 0;
    for(let i = 1; i <= dx; i++){
        for(let j = 1; j <= dx; j++){
            const d = x - i ^ 2 + (y - j) ^ 2;
            if (plot_matrix.length <= pindex) {
                continue;
            }
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
        const [x, y] = events2unitless(scene.screen, event);
        const [_, picks] = pick_native(scene, x, y, 1, 1);
        if (picks.length == 1) {
            const [plot, index] = picks[0];
            if (plots_to_pick.has(plot.plot_uuid)) {
                const result = callback(plot, index);
                if (!popup.classList.contains("show")) {
                    popup.classList.add("show");
                }
                popup.style.left = event.pageX + "px";
                popup.style.top = event.pageY + "px";
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
    events2unitless,
    on_next_insert,
    register_popup,
    render_scene,
    TEXTURE_ATLAS
};
export { deserialize_scene as deserialize_scene, threejs_module as threejs_module, start_renderloop as start_renderloop, delete_plots as delete_plots, insert_plot as insert_plot, find_plots as find_plots, delete_scene as delete_scene, find_scene as find_scene, scene_cache as scene_cache, plot_cache as plot_cache, delete_scenes as delete_scenes, create_scene as create_scene, events2unitless as events2unitless, on_next_insert as on_next_insert };
export { render_scene as render_scene };
export { wglerror as wglerror };
export { pick_native as pick_native };
export { pick_closest as pick_closest };
export { pick_sorted as pick_sorted };
export { pick_native_uuid as pick_native_uuid };
export { pick_native_matrix as pick_native_matrix };
export { register_popup as register_popup };

