// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

var Fc = "155", Ox = {
    LEFT: 0,
    MIDDLE: 1,
    RIGHT: 2,
    ROTATE: 0,
    DOLLY: 1,
    PAN: 2
}, Bx = {
    ROTATE: 0,
    PAN: 1,
    DOLLY_PAN: 2,
    DOLLY_ROTATE: 3
}, Nd = 0, tl = 1, Fd = 2, zx = 3, kx = 0, nd = 1, Od = 2, pn = 3, On = 0, De = 1, gn = 2, Vx = 2, Un = 0, Wi = 1, el = 2, nl = 3, il = 4, Bd = 5, Bi = 100, zd = 101, kd = 102, sl = 103, rl = 104, Vd = 200, Hd = 201, Gd = 202, Wd = 203, id = 204, sd = 205, Xd = 206, qd = 207, Yd = 208, Zd = 209, Jd = 210, $d = 0, Kd = 1, Qd = 2, ao = 3, jd = 4, tf = 5, ef = 6, nf = 7, pa = 0, sf = 1, rf = 2, Dn = 0, af = 1, of = 2, cf = 3, lf = 4, hf = 5, Oc = 300, Bn = 301, ci = 302, Ur = 303, Dr = 304, Hs = 306, Nr = 1e3, Ce = 1001, Fr = 1002, fe = 1003, oo = 1004, Hx = 1004, Ir = 1005, Gx = 1005, pe = 1006, rd = 1007, Wx = 1007, li = 1008, Xx = 1008, Nn = 1009, uf = 1010, df = 1011, Bc = 1012, ad = 1013, Pn = 1014, xn = 1015, Ts = 1016, od = 1017, cd = 1018, ni = 1020, ff = 1021, He = 1023, pf = 1024, mf = 1025, ii = 1026, Yi = 1027, gf = 1028, ld = 1029, _f = 1030, hd = 1031, ud = 1033, Ma = 33776, Sa = 33777, ba = 33778, Ea = 33779, al = 35840, ol = 35841, cl = 35842, ll = 35843, xf = 36196, hl = 37492, ul = 37496, dl = 37808, fl = 37809, pl = 37810, ml = 37811, gl = 37812, _l = 37813, xl = 37814, vl = 37815, yl = 37816, Ml = 37817, Sl = 37818, bl = 37819, El = 37820, Tl = 37821, Ta = 36492, vf = 36283, wl = 36284, Al = 36285, Rl = 36286, yf = 2200, Mf = 2201, Sf = 2202, Or = 2300, Br = 2301, wa = 2302, zi = 2400, ki = 2401, zr = 2402, zc = 2500, dd = 2501, qx = 0, Yx = 1, Zx = 2, fd = 3e3, si = 3001, bf = 3200, Ef = 3201, mi = 0, Tf = 1, ri = "", Nt = "srgb", nn = "srgb-linear", pd = "display-p3", Jx = 0, Aa = 7680, $x = 7681, Kx = 7682, Qx = 7683, jx = 34055, tv = 34056, ev = 5386, nv = 512, iv = 513, sv = 514, rv = 515, av = 516, ov = 517, cv = 518, wf = 519, Af = 512, Rf = 513, Cf = 514, Pf = 515, Lf = 516, If = 517, Uf = 518, Df = 519, kr = 35044, lv = 35048, hv = 35040, uv = 35045, dv = 35049, fv = 35041, pv = 35046, mv = 35050, gv = 35042, _v = "100", Cl = "300 es", co = 1035, vn = 2e3, Vr = 2001, sn = class {
    addEventListener(t, e) {
        this._listeners === void 0 && (this._listeners = {});
        let n = this._listeners;
        n[t] === void 0 && (n[t] = []), n[t].indexOf(e) === -1 && n[t].push(e);
    }
    hasEventListener(t, e) {
        if (this._listeners === void 0) return !1;
        let n = this._listeners;
        return n[t] !== void 0 && n[t].indexOf(e) !== -1;
    }
    removeEventListener(t, e) {
        if (this._listeners === void 0) return;
        let i = this._listeners[t];
        if (i !== void 0) {
            let r = i.indexOf(e);
            r !== -1 && i.splice(r, 1);
        }
    }
    dispatchEvent(t) {
        if (this._listeners === void 0) return;
        let n = this._listeners[t.type];
        if (n !== void 0) {
            t.target = this;
            let i = n.slice(0);
            for(let r = 0, a = i.length; r < a; r++)i[r].call(this, t);
            t.target = null;
        }
    }
}, Se = [
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
], Pl = 1234567, ai = Math.PI / 180, Zi = 180 / Math.PI;
function Be() {
    let s1 = Math.random() * 4294967295 | 0, t = Math.random() * 4294967295 | 0, e = Math.random() * 4294967295 | 0, n = Math.random() * 4294967295 | 0;
    return (Se[s1 & 255] + Se[s1 >> 8 & 255] + Se[s1 >> 16 & 255] + Se[s1 >> 24 & 255] + "-" + Se[t & 255] + Se[t >> 8 & 255] + "-" + Se[t >> 16 & 15 | 64] + Se[t >> 24 & 255] + "-" + Se[e & 63 | 128] + Se[e >> 8 & 255] + "-" + Se[e >> 16 & 255] + Se[e >> 24 & 255] + Se[n & 255] + Se[n >> 8 & 255] + Se[n >> 16 & 255] + Se[n >> 24 & 255]).toLowerCase();
}
function ae(s1, t, e) {
    return Math.max(t, Math.min(e, s1));
}
function kc(s1, t) {
    return (s1 % t + t) % t;
}
function Nf(s1, t, e, n, i) {
    return n + (s1 - t) * (i - n) / (e - t);
}
function Ff(s1, t, e) {
    return s1 !== t ? (e - s1) / (t - s1) : 0;
}
function ys(s1, t, e) {
    return (1 - e) * s1 + e * t;
}
function Of(s1, t, e, n) {
    return ys(s1, t, 1 - Math.exp(-e * n));
}
function Bf(s1, t = 1) {
    return t - Math.abs(kc(s1, t * 2) - t);
}
function zf(s1, t, e) {
    return s1 <= t ? 0 : s1 >= e ? 1 : (s1 = (s1 - t) / (e - t), s1 * s1 * (3 - 2 * s1));
}
function kf(s1, t, e) {
    return s1 <= t ? 0 : s1 >= e ? 1 : (s1 = (s1 - t) / (e - t), s1 * s1 * s1 * (s1 * (s1 * 6 - 15) + 10));
}
function Vf(s1, t) {
    return s1 + Math.floor(Math.random() * (t - s1 + 1));
}
function Hf(s1, t) {
    return s1 + Math.random() * (t - s1);
}
function Gf(s1) {
    return s1 * (.5 - Math.random());
}
function Wf(s1) {
    s1 !== void 0 && (Pl = s1);
    let t = Pl += 1831565813;
    return t = Math.imul(t ^ t >>> 15, t | 1), t ^= t + Math.imul(t ^ t >>> 7, t | 61), ((t ^ t >>> 14) >>> 0) / 4294967296;
}
function Xf(s1) {
    return s1 * ai;
}
function qf(s1) {
    return s1 * Zi;
}
function lo(s1) {
    return (s1 & s1 - 1) === 0 && s1 !== 0;
}
function md(s1) {
    return Math.pow(2, Math.ceil(Math.log(s1) / Math.LN2));
}
function Hr(s1) {
    return Math.pow(2, Math.floor(Math.log(s1) / Math.LN2));
}
function Yf(s1, t, e, n, i) {
    let r = Math.cos, a = Math.sin, o = r(e / 2), c = a(e / 2), l = r((t + n) / 2), h = a((t + n) / 2), u = r((t - n) / 2), d = a((t - n) / 2), f = r((n - t) / 2), m = a((n - t) / 2);
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
function Ue(s1, t) {
    switch(t.constructor){
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
function Ft(s1, t) {
    switch(t.constructor){
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
var xv = {
    DEG2RAD: ai,
    RAD2DEG: Zi,
    generateUUID: Be,
    clamp: ae,
    euclideanModulo: kc,
    mapLinear: Nf,
    inverseLerp: Ff,
    lerp: ys,
    damp: Of,
    pingpong: Bf,
    smoothstep: zf,
    smootherstep: kf,
    randInt: Vf,
    randFloat: Hf,
    randFloatSpread: Gf,
    seededRandom: Wf,
    degToRad: Xf,
    radToDeg: qf,
    isPowerOfTwo: lo,
    ceilPowerOfTwo: md,
    floorPowerOfTwo: Hr,
    setQuaternionFromProperEuler: Yf,
    normalize: Ft,
    denormalize: Ue
}, J = class s1 {
    constructor(t = 0, e = 0){
        s1.prototype.isVector2 = !0, this.x = t, this.y = e;
    }
    get width() {
        return this.x;
    }
    set width(t) {
        this.x = t;
    }
    get height() {
        return this.y;
    }
    set height(t) {
        this.y = t;
    }
    set(t, e) {
        return this.x = t, this.y = e, this;
    }
    setScalar(t) {
        return this.x = t, this.y = t, this;
    }
    setX(t) {
        return this.x = t, this;
    }
    setY(t) {
        return this.y = t, this;
    }
    setComponent(t, e) {
        switch(t){
            case 0:
                this.x = e;
                break;
            case 1:
                this.y = e;
                break;
            default:
                throw new Error("index is out of range: " + t);
        }
        return this;
    }
    getComponent(t) {
        switch(t){
            case 0:
                return this.x;
            case 1:
                return this.y;
            default:
                throw new Error("index is out of range: " + t);
        }
    }
    clone() {
        return new this.constructor(this.x, this.y);
    }
    copy(t) {
        return this.x = t.x, this.y = t.y, this;
    }
    add(t) {
        return this.x += t.x, this.y += t.y, this;
    }
    addScalar(t) {
        return this.x += t, this.y += t, this;
    }
    addVectors(t, e) {
        return this.x = t.x + e.x, this.y = t.y + e.y, this;
    }
    addScaledVector(t, e) {
        return this.x += t.x * e, this.y += t.y * e, this;
    }
    sub(t) {
        return this.x -= t.x, this.y -= t.y, this;
    }
    subScalar(t) {
        return this.x -= t, this.y -= t, this;
    }
    subVectors(t, e) {
        return this.x = t.x - e.x, this.y = t.y - e.y, this;
    }
    multiply(t) {
        return this.x *= t.x, this.y *= t.y, this;
    }
    multiplyScalar(t) {
        return this.x *= t, this.y *= t, this;
    }
    divide(t) {
        return this.x /= t.x, this.y /= t.y, this;
    }
    divideScalar(t) {
        return this.multiplyScalar(1 / t);
    }
    applyMatrix3(t) {
        let e = this.x, n = this.y, i = t.elements;
        return this.x = i[0] * e + i[3] * n + i[6], this.y = i[1] * e + i[4] * n + i[7], this;
    }
    min(t) {
        return this.x = Math.min(this.x, t.x), this.y = Math.min(this.y, t.y), this;
    }
    max(t) {
        return this.x = Math.max(this.x, t.x), this.y = Math.max(this.y, t.y), this;
    }
    clamp(t, e) {
        return this.x = Math.max(t.x, Math.min(e.x, this.x)), this.y = Math.max(t.y, Math.min(e.y, this.y)), this;
    }
    clampScalar(t, e) {
        return this.x = Math.max(t, Math.min(e, this.x)), this.y = Math.max(t, Math.min(e, this.y)), this;
    }
    clampLength(t, e) {
        let n = this.length();
        return this.divideScalar(n || 1).multiplyScalar(Math.max(t, Math.min(e, n)));
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
    dot(t) {
        return this.x * t.x + this.y * t.y;
    }
    cross(t) {
        return this.x * t.y - this.y * t.x;
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
    angleTo(t) {
        let e = Math.sqrt(this.lengthSq() * t.lengthSq());
        if (e === 0) return Math.PI / 2;
        let n = this.dot(t) / e;
        return Math.acos(ae(n, -1, 1));
    }
    distanceTo(t) {
        return Math.sqrt(this.distanceToSquared(t));
    }
    distanceToSquared(t) {
        let e = this.x - t.x, n = this.y - t.y;
        return e * e + n * n;
    }
    manhattanDistanceTo(t) {
        return Math.abs(this.x - t.x) + Math.abs(this.y - t.y);
    }
    setLength(t) {
        return this.normalize().multiplyScalar(t);
    }
    lerp(t, e) {
        return this.x += (t.x - this.x) * e, this.y += (t.y - this.y) * e, this;
    }
    lerpVectors(t, e, n) {
        return this.x = t.x + (e.x - t.x) * n, this.y = t.y + (e.y - t.y) * n, this;
    }
    equals(t) {
        return t.x === this.x && t.y === this.y;
    }
    fromArray(t, e = 0) {
        return this.x = t[e], this.y = t[e + 1], this;
    }
    toArray(t = [], e = 0) {
        return t[e] = this.x, t[e + 1] = this.y, t;
    }
    fromBufferAttribute(t, e) {
        return this.x = t.getX(e), this.y = t.getY(e), this;
    }
    rotateAround(t, e) {
        let n = Math.cos(e), i = Math.sin(e), r = this.x - t.x, a = this.y - t.y;
        return this.x = r * n - a * i + t.x, this.y = r * i + a * n + t.y, this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y;
    }
}, kt = class s1 {
    constructor(t, e, n, i, r, a, o, c, l){
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
        ], t !== void 0 && this.set(t, e, n, i, r, a, o, c, l);
    }
    set(t, e, n, i, r, a, o, c, l) {
        let h = this.elements;
        return h[0] = t, h[1] = i, h[2] = o, h[3] = e, h[4] = r, h[5] = c, h[6] = n, h[7] = a, h[8] = l, this;
    }
    identity() {
        return this.set(1, 0, 0, 0, 1, 0, 0, 0, 1), this;
    }
    copy(t) {
        let e = this.elements, n = t.elements;
        return e[0] = n[0], e[1] = n[1], e[2] = n[2], e[3] = n[3], e[4] = n[4], e[5] = n[5], e[6] = n[6], e[7] = n[7], e[8] = n[8], this;
    }
    extractBasis(t, e, n) {
        return t.setFromMatrix3Column(this, 0), e.setFromMatrix3Column(this, 1), n.setFromMatrix3Column(this, 2), this;
    }
    setFromMatrix4(t) {
        let e = t.elements;
        return this.set(e[0], e[4], e[8], e[1], e[5], e[9], e[2], e[6], e[10]), this;
    }
    multiply(t) {
        return this.multiplyMatrices(this, t);
    }
    premultiply(t) {
        return this.multiplyMatrices(t, this);
    }
    multiplyMatrices(t, e) {
        let n = t.elements, i = e.elements, r = this.elements, a = n[0], o = n[3], c = n[6], l = n[1], h = n[4], u = n[7], d = n[2], f = n[5], m = n[8], x = i[0], g = i[3], p = i[6], v = i[1], _ = i[4], y = i[7], b = i[2], w = i[5], R = i[8];
        return r[0] = a * x + o * v + c * b, r[3] = a * g + o * _ + c * w, r[6] = a * p + o * y + c * R, r[1] = l * x + h * v + u * b, r[4] = l * g + h * _ + u * w, r[7] = l * p + h * y + u * R, r[2] = d * x + f * v + m * b, r[5] = d * g + f * _ + m * w, r[8] = d * p + f * y + m * R, this;
    }
    multiplyScalar(t) {
        let e = this.elements;
        return e[0] *= t, e[3] *= t, e[6] *= t, e[1] *= t, e[4] *= t, e[7] *= t, e[2] *= t, e[5] *= t, e[8] *= t, this;
    }
    determinant() {
        let t = this.elements, e = t[0], n = t[1], i = t[2], r = t[3], a = t[4], o = t[5], c = t[6], l = t[7], h = t[8];
        return e * a * h - e * o * l - n * r * h + n * o * c + i * r * l - i * a * c;
    }
    invert() {
        let t = this.elements, e = t[0], n = t[1], i = t[2], r = t[3], a = t[4], o = t[5], c = t[6], l = t[7], h = t[8], u = h * a - o * l, d = o * c - h * r, f = l * r - a * c, m = e * u + n * d + i * f;
        if (m === 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0);
        let x = 1 / m;
        return t[0] = u * x, t[1] = (i * l - h * n) * x, t[2] = (o * n - i * a) * x, t[3] = d * x, t[4] = (h * e - i * c) * x, t[5] = (i * r - o * e) * x, t[6] = f * x, t[7] = (n * c - l * e) * x, t[8] = (a * e - n * r) * x, this;
    }
    transpose() {
        let t, e = this.elements;
        return t = e[1], e[1] = e[3], e[3] = t, t = e[2], e[2] = e[6], e[6] = t, t = e[5], e[5] = e[7], e[7] = t, this;
    }
    getNormalMatrix(t) {
        return this.setFromMatrix4(t).invert().transpose();
    }
    transposeIntoArray(t) {
        let e = this.elements;
        return t[0] = e[0], t[1] = e[3], t[2] = e[6], t[3] = e[1], t[4] = e[4], t[5] = e[7], t[6] = e[2], t[7] = e[5], t[8] = e[8], this;
    }
    setUvTransform(t, e, n, i, r, a, o) {
        let c = Math.cos(r), l = Math.sin(r);
        return this.set(n * c, n * l, -n * (c * a + l * o) + a + t, -i * l, i * c, -i * (-l * a + c * o) + o + e, 0, 0, 1), this;
    }
    scale(t, e) {
        return this.premultiply(Ra.makeScale(t, e)), this;
    }
    rotate(t) {
        return this.premultiply(Ra.makeRotation(-t)), this;
    }
    translate(t, e) {
        return this.premultiply(Ra.makeTranslation(t, e)), this;
    }
    makeTranslation(t, e) {
        return t.isVector2 ? this.set(1, 0, t.x, 0, 1, t.y, 0, 0, 1) : this.set(1, 0, t, 0, 1, e, 0, 0, 1), this;
    }
    makeRotation(t) {
        let e = Math.cos(t), n = Math.sin(t);
        return this.set(e, -n, 0, n, e, 0, 0, 0, 1), this;
    }
    makeScale(t, e) {
        return this.set(t, 0, 0, 0, e, 0, 0, 0, 1), this;
    }
    equals(t) {
        let e = this.elements, n = t.elements;
        for(let i = 0; i < 9; i++)if (e[i] !== n[i]) return !1;
        return !0;
    }
    fromArray(t, e = 0) {
        for(let n = 0; n < 9; n++)this.elements[n] = t[n + e];
        return this;
    }
    toArray(t = [], e = 0) {
        let n = this.elements;
        return t[e] = n[0], t[e + 1] = n[1], t[e + 2] = n[2], t[e + 3] = n[3], t[e + 4] = n[4], t[e + 5] = n[5], t[e + 6] = n[6], t[e + 7] = n[7], t[e + 8] = n[8], t;
    }
    clone() {
        return new this.constructor().fromArray(this.elements);
    }
}, Ra = new kt;
function gd(s1) {
    for(let t = s1.length - 1; t >= 0; --t)if (s1[t] >= 65535) return !0;
    return !1;
}
var Zf = {
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
function Vi(s1, t) {
    return new Zf[s1](t);
}
function ws(s1) {
    return document.createElementNS("http://www.w3.org/1999/xhtml", s1);
}
var Ll = {};
function Ms(s1) {
    s1 in Ll || (Ll[s1] = !0, console.warn(s1));
}
function Xi(s1) {
    return s1 < .04045 ? s1 * .0773993808 : Math.pow(s1 * .9478672986 + .0521327014, 2.4);
}
function Ca(s1) {
    return s1 < .0031308 ? s1 * 12.92 : 1.055 * Math.pow(s1, .41666) - .055;
}
var Jf = new kt().fromArray([
    .8224621,
    .0331941,
    .0170827,
    .177538,
    .9668058,
    .0723974,
    -1e-7,
    1e-7,
    .9105199
]), $f = new kt().fromArray([
    1.2249401,
    -.0420569,
    -.0196376,
    -.2249404,
    1.0420571,
    -.0786361,
    1e-7,
    0,
    1.0982735
]);
function Kf(s1) {
    return s1.convertSRGBToLinear().applyMatrix3($f);
}
function Qf(s1) {
    return s1.applyMatrix3(Jf).convertLinearToSRGB();
}
var jf = {
    [nn]: (s1)=>s1,
    [Nt]: (s1)=>s1.convertSRGBToLinear(),
    [pd]: Kf
}, tp = {
    [nn]: (s1)=>s1,
    [Nt]: (s1)=>s1.convertLinearToSRGB(),
    [pd]: Qf
}, Ye = {
    enabled: !0,
    get legacyMode () {
        return console.warn("THREE.ColorManagement: .legacyMode=false renamed to .enabled=true in r150."), !this.enabled;
    },
    set legacyMode (s){
        console.warn("THREE.ColorManagement: .legacyMode=false renamed to .enabled=true in r150."), this.enabled = !s;
    },
    get workingColorSpace () {
        return nn;
    },
    set workingColorSpace (s){
        console.warn("THREE.ColorManagement: .workingColorSpace is readonly.");
    },
    convert: function(s1, t, e) {
        if (this.enabled === !1 || t === e || !t || !e) return s1;
        let n = jf[t], i = tp[e];
        if (n === void 0 || i === void 0) throw new Error(`Unsupported color space conversion, "${t}" to "${e}".`);
        return i(n(s1));
    },
    fromWorkingColorSpace: function(s1, t) {
        return this.convert(s1, this.workingColorSpace, t);
    },
    toWorkingColorSpace: function(s1, t) {
        return this.convert(s1, t, this.workingColorSpace);
    }
}, gi, Gr = class {
    static getDataURL(t) {
        if (/^data:/i.test(t.src) || typeof HTMLCanvasElement > "u") return t.src;
        let e;
        if (t instanceof HTMLCanvasElement) e = t;
        else {
            gi === void 0 && (gi = ws("canvas")), gi.width = t.width, gi.height = t.height;
            let n = gi.getContext("2d");
            t instanceof ImageData ? n.putImageData(t, 0, 0) : n.drawImage(t, 0, 0, t.width, t.height), e = gi;
        }
        return e.width > 2048 || e.height > 2048 ? (console.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons", t), e.toDataURL("image/jpeg", .6)) : e.toDataURL("image/png");
    }
    static sRGBToLinear(t) {
        if (typeof HTMLImageElement < "u" && t instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && t instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && t instanceof ImageBitmap) {
            let e = ws("canvas");
            e.width = t.width, e.height = t.height;
            let n = e.getContext("2d");
            n.drawImage(t, 0, 0, t.width, t.height);
            let i = n.getImageData(0, 0, t.width, t.height), r = i.data;
            for(let a = 0; a < r.length; a++)r[a] = Xi(r[a] / 255) * 255;
            return n.putImageData(i, 0, 0), e;
        } else if (t.data) {
            let e = t.data.slice(0);
            for(let n = 0; n < e.length; n++)e instanceof Uint8Array || e instanceof Uint8ClampedArray ? e[n] = Math.floor(Xi(e[n] / 255) * 255) : e[n] = Xi(e[n]);
            return {
                data: e,
                width: t.width,
                height: t.height
            };
        } else return console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied."), t;
    }
}, ep = 0, Ln = class {
    constructor(t = null){
        this.isSource = !0, Object.defineProperty(this, "id", {
            value: ep++
        }), this.uuid = Be(), this.data = t, this.version = 0;
    }
    set needsUpdate(t) {
        t === !0 && this.version++;
    }
    toJSON(t) {
        let e = t === void 0 || typeof t == "string";
        if (!e && t.images[this.uuid] !== void 0) return t.images[this.uuid];
        let n = {
            uuid: this.uuid,
            url: ""
        }, i = this.data;
        if (i !== null) {
            let r;
            if (Array.isArray(i)) {
                r = [];
                for(let a = 0, o = i.length; a < o; a++)i[a].isDataTexture ? r.push(Pa(i[a].image)) : r.push(Pa(i[a]));
            } else r = Pa(i);
            n.url = r;
        }
        return e || (t.images[this.uuid] = n), n;
    }
};
function Pa(s1) {
    return typeof HTMLImageElement < "u" && s1 instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && s1 instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && s1 instanceof ImageBitmap ? Gr.getDataURL(s1) : s1.data ? {
        data: Array.from(s1.data),
        width: s1.width,
        height: s1.height,
        type: s1.data.constructor.name
    } : (console.warn("THREE.Texture: Unable to serialize Texture."), {});
}
var np = 0, ye = class s1 extends sn {
    constructor(t = s1.DEFAULT_IMAGE, e = s1.DEFAULT_MAPPING, n = Ce, i = Ce, r = pe, a = li, o = He, c = Nn, l = s1.DEFAULT_ANISOTROPY, h = ri){
        super(), this.isTexture = !0, Object.defineProperty(this, "id", {
            value: np++
        }), this.uuid = Be(), this.name = "", this.source = new Ln(t), this.mipmaps = [], this.mapping = e, this.channel = 0, this.wrapS = n, this.wrapT = i, this.magFilter = r, this.minFilter = a, this.anisotropy = l, this.format = o, this.internalFormat = null, this.type = c, this.offset = new J(0, 0), this.repeat = new J(1, 1), this.center = new J(0, 0), this.rotation = 0, this.matrixAutoUpdate = !0, this.matrix = new kt, this.generateMipmaps = !0, this.premultiplyAlpha = !1, this.flipY = !0, this.unpackAlignment = 4, typeof h == "string" ? this.colorSpace = h : (Ms("THREE.Texture: Property .encoding has been replaced by .colorSpace."), this.colorSpace = h === si ? Nt : ri), this.userData = {}, this.version = 0, this.onUpdate = null, this.isRenderTargetTexture = !1, this.needsPMREMUpdate = !1;
    }
    get image() {
        return this.source.data;
    }
    set image(t = null) {
        this.source.data = t;
    }
    updateMatrix() {
        this.matrix.setUvTransform(this.offset.x, this.offset.y, this.repeat.x, this.repeat.y, this.rotation, this.center.x, this.center.y);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        return this.name = t.name, this.source = t.source, this.mipmaps = t.mipmaps.slice(0), this.mapping = t.mapping, this.channel = t.channel, this.wrapS = t.wrapS, this.wrapT = t.wrapT, this.magFilter = t.magFilter, this.minFilter = t.minFilter, this.anisotropy = t.anisotropy, this.format = t.format, this.internalFormat = t.internalFormat, this.type = t.type, this.offset.copy(t.offset), this.repeat.copy(t.repeat), this.center.copy(t.center), this.rotation = t.rotation, this.matrixAutoUpdate = t.matrixAutoUpdate, this.matrix.copy(t.matrix), this.generateMipmaps = t.generateMipmaps, this.premultiplyAlpha = t.premultiplyAlpha, this.flipY = t.flipY, this.unpackAlignment = t.unpackAlignment, this.colorSpace = t.colorSpace, this.userData = JSON.parse(JSON.stringify(t.userData)), this.needsUpdate = !0, this;
    }
    toJSON(t) {
        let e = t === void 0 || typeof t == "string";
        if (!e && t.textures[this.uuid] !== void 0) return t.textures[this.uuid];
        let n = {
            metadata: {
                version: 4.6,
                type: "Texture",
                generator: "Texture.toJSON"
            },
            uuid: this.uuid,
            name: this.name,
            image: this.source.toJSON(t).uuid,
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
        return Object.keys(this.userData).length > 0 && (n.userData = this.userData), e || (t.textures[this.uuid] = n), n;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
    transformUv(t) {
        if (this.mapping !== Oc) return t;
        if (t.applyMatrix3(this.matrix), t.x < 0 || t.x > 1) switch(this.wrapS){
            case Nr:
                t.x = t.x - Math.floor(t.x);
                break;
            case Ce:
                t.x = t.x < 0 ? 0 : 1;
                break;
            case Fr:
                Math.abs(Math.floor(t.x) % 2) === 1 ? t.x = Math.ceil(t.x) - t.x : t.x = t.x - Math.floor(t.x);
                break;
        }
        if (t.y < 0 || t.y > 1) switch(this.wrapT){
            case Nr:
                t.y = t.y - Math.floor(t.y);
                break;
            case Ce:
                t.y = t.y < 0 ? 0 : 1;
                break;
            case Fr:
                Math.abs(Math.floor(t.y) % 2) === 1 ? t.y = Math.ceil(t.y) - t.y : t.y = t.y - Math.floor(t.y);
                break;
        }
        return this.flipY && (t.y = 1 - t.y), t;
    }
    set needsUpdate(t) {
        t === !0 && (this.version++, this.source.needsUpdate = !0);
    }
    get encoding() {
        return Ms("THREE.Texture: Property .encoding has been replaced by .colorSpace."), this.colorSpace === Nt ? si : fd;
    }
    set encoding(t) {
        Ms("THREE.Texture: Property .encoding has been replaced by .colorSpace."), this.colorSpace = t === si ? Nt : ri;
    }
};
ye.DEFAULT_IMAGE = null;
ye.DEFAULT_MAPPING = Oc;
ye.DEFAULT_ANISOTROPY = 1;
var $t = class s1 {
    constructor(t = 0, e = 0, n = 0, i = 1){
        s1.prototype.isVector4 = !0, this.x = t, this.y = e, this.z = n, this.w = i;
    }
    get width() {
        return this.z;
    }
    set width(t) {
        this.z = t;
    }
    get height() {
        return this.w;
    }
    set height(t) {
        this.w = t;
    }
    set(t, e, n, i) {
        return this.x = t, this.y = e, this.z = n, this.w = i, this;
    }
    setScalar(t) {
        return this.x = t, this.y = t, this.z = t, this.w = t, this;
    }
    setX(t) {
        return this.x = t, this;
    }
    setY(t) {
        return this.y = t, this;
    }
    setZ(t) {
        return this.z = t, this;
    }
    setW(t) {
        return this.w = t, this;
    }
    setComponent(t, e) {
        switch(t){
            case 0:
                this.x = e;
                break;
            case 1:
                this.y = e;
                break;
            case 2:
                this.z = e;
                break;
            case 3:
                this.w = e;
                break;
            default:
                throw new Error("index is out of range: " + t);
        }
        return this;
    }
    getComponent(t) {
        switch(t){
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            case 3:
                return this.w;
            default:
                throw new Error("index is out of range: " + t);
        }
    }
    clone() {
        return new this.constructor(this.x, this.y, this.z, this.w);
    }
    copy(t) {
        return this.x = t.x, this.y = t.y, this.z = t.z, this.w = t.w !== void 0 ? t.w : 1, this;
    }
    add(t) {
        return this.x += t.x, this.y += t.y, this.z += t.z, this.w += t.w, this;
    }
    addScalar(t) {
        return this.x += t, this.y += t, this.z += t, this.w += t, this;
    }
    addVectors(t, e) {
        return this.x = t.x + e.x, this.y = t.y + e.y, this.z = t.z + e.z, this.w = t.w + e.w, this;
    }
    addScaledVector(t, e) {
        return this.x += t.x * e, this.y += t.y * e, this.z += t.z * e, this.w += t.w * e, this;
    }
    sub(t) {
        return this.x -= t.x, this.y -= t.y, this.z -= t.z, this.w -= t.w, this;
    }
    subScalar(t) {
        return this.x -= t, this.y -= t, this.z -= t, this.w -= t, this;
    }
    subVectors(t, e) {
        return this.x = t.x - e.x, this.y = t.y - e.y, this.z = t.z - e.z, this.w = t.w - e.w, this;
    }
    multiply(t) {
        return this.x *= t.x, this.y *= t.y, this.z *= t.z, this.w *= t.w, this;
    }
    multiplyScalar(t) {
        return this.x *= t, this.y *= t, this.z *= t, this.w *= t, this;
    }
    applyMatrix4(t) {
        let e = this.x, n = this.y, i = this.z, r = this.w, a = t.elements;
        return this.x = a[0] * e + a[4] * n + a[8] * i + a[12] * r, this.y = a[1] * e + a[5] * n + a[9] * i + a[13] * r, this.z = a[2] * e + a[6] * n + a[10] * i + a[14] * r, this.w = a[3] * e + a[7] * n + a[11] * i + a[15] * r, this;
    }
    divideScalar(t) {
        return this.multiplyScalar(1 / t);
    }
    setAxisAngleFromQuaternion(t) {
        this.w = 2 * Math.acos(t.w);
        let e = Math.sqrt(1 - t.w * t.w);
        return e < 1e-4 ? (this.x = 1, this.y = 0, this.z = 0) : (this.x = t.x / e, this.y = t.y / e, this.z = t.z / e), this;
    }
    setAxisAngleFromRotationMatrix(t) {
        let e, n, i, r, c = t.elements, l = c[0], h = c[4], u = c[8], d = c[1], f = c[5], m = c[9], x = c[2], g = c[6], p = c[10];
        if (Math.abs(h - d) < .01 && Math.abs(u - x) < .01 && Math.abs(m - g) < .01) {
            if (Math.abs(h + d) < .1 && Math.abs(u + x) < .1 && Math.abs(m + g) < .1 && Math.abs(l + f + p - 3) < .1) return this.set(1, 0, 0, 0), this;
            e = Math.PI;
            let _ = (l + 1) / 2, y = (f + 1) / 2, b = (p + 1) / 2, w = (h + d) / 4, R = (u + x) / 4, L = (m + g) / 4;
            return _ > y && _ > b ? _ < .01 ? (n = 0, i = .707106781, r = .707106781) : (n = Math.sqrt(_), i = w / n, r = R / n) : y > b ? y < .01 ? (n = .707106781, i = 0, r = .707106781) : (i = Math.sqrt(y), n = w / i, r = L / i) : b < .01 ? (n = .707106781, i = .707106781, r = 0) : (r = Math.sqrt(b), n = R / r, i = L / r), this.set(n, i, r, e), this;
        }
        let v = Math.sqrt((g - m) * (g - m) + (u - x) * (u - x) + (d - h) * (d - h));
        return Math.abs(v) < .001 && (v = 1), this.x = (g - m) / v, this.y = (u - x) / v, this.z = (d - h) / v, this.w = Math.acos((l + f + p - 1) / 2), this;
    }
    min(t) {
        return this.x = Math.min(this.x, t.x), this.y = Math.min(this.y, t.y), this.z = Math.min(this.z, t.z), this.w = Math.min(this.w, t.w), this;
    }
    max(t) {
        return this.x = Math.max(this.x, t.x), this.y = Math.max(this.y, t.y), this.z = Math.max(this.z, t.z), this.w = Math.max(this.w, t.w), this;
    }
    clamp(t, e) {
        return this.x = Math.max(t.x, Math.min(e.x, this.x)), this.y = Math.max(t.y, Math.min(e.y, this.y)), this.z = Math.max(t.z, Math.min(e.z, this.z)), this.w = Math.max(t.w, Math.min(e.w, this.w)), this;
    }
    clampScalar(t, e) {
        return this.x = Math.max(t, Math.min(e, this.x)), this.y = Math.max(t, Math.min(e, this.y)), this.z = Math.max(t, Math.min(e, this.z)), this.w = Math.max(t, Math.min(e, this.w)), this;
    }
    clampLength(t, e) {
        let n = this.length();
        return this.divideScalar(n || 1).multiplyScalar(Math.max(t, Math.min(e, n)));
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
    dot(t) {
        return this.x * t.x + this.y * t.y + this.z * t.z + this.w * t.w;
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
    setLength(t) {
        return this.normalize().multiplyScalar(t);
    }
    lerp(t, e) {
        return this.x += (t.x - this.x) * e, this.y += (t.y - this.y) * e, this.z += (t.z - this.z) * e, this.w += (t.w - this.w) * e, this;
    }
    lerpVectors(t, e, n) {
        return this.x = t.x + (e.x - t.x) * n, this.y = t.y + (e.y - t.y) * n, this.z = t.z + (e.z - t.z) * n, this.w = t.w + (e.w - t.w) * n, this;
    }
    equals(t) {
        return t.x === this.x && t.y === this.y && t.z === this.z && t.w === this.w;
    }
    fromArray(t, e = 0) {
        return this.x = t[e], this.y = t[e + 1], this.z = t[e + 2], this.w = t[e + 3], this;
    }
    toArray(t = [], e = 0) {
        return t[e] = this.x, t[e + 1] = this.y, t[e + 2] = this.z, t[e + 3] = this.w, t;
    }
    fromBufferAttribute(t, e) {
        return this.x = t.getX(e), this.y = t.getY(e), this.z = t.getZ(e), this.w = t.getW(e), this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this.z = Math.random(), this.w = Math.random(), this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y, yield this.z, yield this.w;
    }
}, ho = class extends sn {
    constructor(t = 1, e = 1, n = {}){
        super(), this.isRenderTarget = !0, this.width = t, this.height = e, this.depth = 1, this.scissor = new $t(0, 0, t, e), this.scissorTest = !1, this.viewport = new $t(0, 0, t, e);
        let i = {
            width: t,
            height: e,
            depth: 1
        };
        n.encoding !== void 0 && (Ms("THREE.WebGLRenderTarget: option.encoding has been replaced by option.colorSpace."), n.colorSpace = n.encoding === si ? Nt : ri), this.texture = new ye(i, n.mapping, n.wrapS, n.wrapT, n.magFilter, n.minFilter, n.format, n.type, n.anisotropy, n.colorSpace), this.texture.isRenderTargetTexture = !0, this.texture.flipY = !1, this.texture.generateMipmaps = n.generateMipmaps !== void 0 ? n.generateMipmaps : !1, this.texture.internalFormat = n.internalFormat !== void 0 ? n.internalFormat : null, this.texture.minFilter = n.minFilter !== void 0 ? n.minFilter : pe, this.depthBuffer = n.depthBuffer !== void 0 ? n.depthBuffer : !0, this.stencilBuffer = n.stencilBuffer !== void 0 ? n.stencilBuffer : !1, this.depthTexture = n.depthTexture !== void 0 ? n.depthTexture : null, this.samples = n.samples !== void 0 ? n.samples : 0;
    }
    setSize(t, e, n = 1) {
        (this.width !== t || this.height !== e || this.depth !== n) && (this.width = t, this.height = e, this.depth = n, this.texture.image.width = t, this.texture.image.height = e, this.texture.image.depth = n, this.dispose()), this.viewport.set(0, 0, t, e), this.scissor.set(0, 0, t, e);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        this.width = t.width, this.height = t.height, this.depth = t.depth, this.scissor.copy(t.scissor), this.scissorTest = t.scissorTest, this.viewport.copy(t.viewport), this.texture = t.texture.clone(), this.texture.isRenderTargetTexture = !0;
        let e = Object.assign({}, t.texture.image);
        return this.texture.source = new Ln(e), this.depthBuffer = t.depthBuffer, this.stencilBuffer = t.stencilBuffer, t.depthTexture !== null && (this.depthTexture = t.depthTexture.clone()), this.samples = t.samples, this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
}, Ge = class extends ho {
    constructor(t = 1, e = 1, n = {}){
        super(t, e, n), this.isWebGLRenderTarget = !0;
    }
}, As = class extends ye {
    constructor(t = null, e = 1, n = 1, i = 1){
        super(null), this.isDataArrayTexture = !0, this.image = {
            data: t,
            width: e,
            height: n,
            depth: i
        }, this.magFilter = fe, this.minFilter = fe, this.wrapR = Ce, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
}, Il = class extends Ge {
    constructor(t = 1, e = 1, n = 1){
        super(t, e), this.isWebGLArrayRenderTarget = !0, this.depth = n, this.texture = new As(null, t, e, n), this.texture.isRenderTargetTexture = !0;
    }
}, Wr = class extends ye {
    constructor(t = null, e = 1, n = 1, i = 1){
        super(null), this.isData3DTexture = !0, this.image = {
            data: t,
            width: e,
            height: n,
            depth: i
        }, this.magFilter = fe, this.minFilter = fe, this.wrapR = Ce, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
}, Ul = class extends Ge {
    constructor(t = 1, e = 1, n = 1){
        super(t, e), this.isWebGL3DRenderTarget = !0, this.depth = n, this.texture = new Wr(null, t, e, n), this.texture.isRenderTargetTexture = !0;
    }
}, Dl = class extends Ge {
    constructor(t = 1, e = 1, n = 1, i = {}){
        super(t, e, i), this.isWebGLMultipleRenderTargets = !0;
        let r = this.texture;
        this.texture = [];
        for(let a = 0; a < n; a++)this.texture[a] = r.clone(), this.texture[a].isRenderTargetTexture = !0;
    }
    setSize(t, e, n = 1) {
        if (this.width !== t || this.height !== e || this.depth !== n) {
            this.width = t, this.height = e, this.depth = n;
            for(let i = 0, r = this.texture.length; i < r; i++)this.texture[i].image.width = t, this.texture[i].image.height = e, this.texture[i].image.depth = n;
            this.dispose();
        }
        this.viewport.set(0, 0, t, e), this.scissor.set(0, 0, t, e);
    }
    copy(t) {
        this.dispose(), this.width = t.width, this.height = t.height, this.depth = t.depth, this.scissor.copy(t.scissor), this.scissorTest = t.scissorTest, this.viewport.copy(t.viewport), this.depthBuffer = t.depthBuffer, this.stencilBuffer = t.stencilBuffer, t.depthTexture !== null && (this.depthTexture = t.depthTexture.clone()), this.texture.length = 0;
        for(let e = 0, n = t.texture.length; e < n; e++)this.texture[e] = t.texture[e].clone(), this.texture[e].isRenderTargetTexture = !0;
        return this;
    }
}, Pe = class {
    constructor(t = 0, e = 0, n = 0, i = 1){
        this.isQuaternion = !0, this._x = t, this._y = e, this._z = n, this._w = i;
    }
    static slerpFlat(t, e, n, i, r, a, o) {
        let c = n[i + 0], l = n[i + 1], h = n[i + 2], u = n[i + 3], d = r[a + 0], f = r[a + 1], m = r[a + 2], x = r[a + 3];
        if (o === 0) {
            t[e + 0] = c, t[e + 1] = l, t[e + 2] = h, t[e + 3] = u;
            return;
        }
        if (o === 1) {
            t[e + 0] = d, t[e + 1] = f, t[e + 2] = m, t[e + 3] = x;
            return;
        }
        if (u !== x || c !== d || l !== f || h !== m) {
            let g = 1 - o, p = c * d + l * f + h * m + u * x, v = p >= 0 ? 1 : -1, _ = 1 - p * p;
            if (_ > Number.EPSILON) {
                let b = Math.sqrt(_), w = Math.atan2(b, p * v);
                g = Math.sin(g * w) / b, o = Math.sin(o * w) / b;
            }
            let y = o * v;
            if (c = c * g + d * y, l = l * g + f * y, h = h * g + m * y, u = u * g + x * y, g === 1 - o) {
                let b = 1 / Math.sqrt(c * c + l * l + h * h + u * u);
                c *= b, l *= b, h *= b, u *= b;
            }
        }
        t[e] = c, t[e + 1] = l, t[e + 2] = h, t[e + 3] = u;
    }
    static multiplyQuaternionsFlat(t, e, n, i, r, a) {
        let o = n[i], c = n[i + 1], l = n[i + 2], h = n[i + 3], u = r[a], d = r[a + 1], f = r[a + 2], m = r[a + 3];
        return t[e] = o * m + h * u + c * f - l * d, t[e + 1] = c * m + h * d + l * u - o * f, t[e + 2] = l * m + h * f + o * d - c * u, t[e + 3] = h * m - o * u - c * d - l * f, t;
    }
    get x() {
        return this._x;
    }
    set x(t) {
        this._x = t, this._onChangeCallback();
    }
    get y() {
        return this._y;
    }
    set y(t) {
        this._y = t, this._onChangeCallback();
    }
    get z() {
        return this._z;
    }
    set z(t) {
        this._z = t, this._onChangeCallback();
    }
    get w() {
        return this._w;
    }
    set w(t) {
        this._w = t, this._onChangeCallback();
    }
    set(t, e, n, i) {
        return this._x = t, this._y = e, this._z = n, this._w = i, this._onChangeCallback(), this;
    }
    clone() {
        return new this.constructor(this._x, this._y, this._z, this._w);
    }
    copy(t) {
        return this._x = t.x, this._y = t.y, this._z = t.z, this._w = t.w, this._onChangeCallback(), this;
    }
    setFromEuler(t, e) {
        let n = t._x, i = t._y, r = t._z, a = t._order, o = Math.cos, c = Math.sin, l = o(n / 2), h = o(i / 2), u = o(r / 2), d = c(n / 2), f = c(i / 2), m = c(r / 2);
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
        return e !== !1 && this._onChangeCallback(), this;
    }
    setFromAxisAngle(t, e) {
        let n = e / 2, i = Math.sin(n);
        return this._x = t.x * i, this._y = t.y * i, this._z = t.z * i, this._w = Math.cos(n), this._onChangeCallback(), this;
    }
    setFromRotationMatrix(t) {
        let e = t.elements, n = e[0], i = e[4], r = e[8], a = e[1], o = e[5], c = e[9], l = e[2], h = e[6], u = e[10], d = n + o + u;
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
    setFromUnitVectors(t, e) {
        let n = t.dot(e) + 1;
        return n < Number.EPSILON ? (n = 0, Math.abs(t.x) > Math.abs(t.z) ? (this._x = -t.y, this._y = t.x, this._z = 0, this._w = n) : (this._x = 0, this._y = -t.z, this._z = t.y, this._w = n)) : (this._x = t.y * e.z - t.z * e.y, this._y = t.z * e.x - t.x * e.z, this._z = t.x * e.y - t.y * e.x, this._w = n), this.normalize();
    }
    angleTo(t) {
        return 2 * Math.acos(Math.abs(ae(this.dot(t), -1, 1)));
    }
    rotateTowards(t, e) {
        let n = this.angleTo(t);
        if (n === 0) return this;
        let i = Math.min(1, e / n);
        return this.slerp(t, i), this;
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
    dot(t) {
        return this._x * t._x + this._y * t._y + this._z * t._z + this._w * t._w;
    }
    lengthSq() {
        return this._x * this._x + this._y * this._y + this._z * this._z + this._w * this._w;
    }
    length() {
        return Math.sqrt(this._x * this._x + this._y * this._y + this._z * this._z + this._w * this._w);
    }
    normalize() {
        let t = this.length();
        return t === 0 ? (this._x = 0, this._y = 0, this._z = 0, this._w = 1) : (t = 1 / t, this._x = this._x * t, this._y = this._y * t, this._z = this._z * t, this._w = this._w * t), this._onChangeCallback(), this;
    }
    multiply(t) {
        return this.multiplyQuaternions(this, t);
    }
    premultiply(t) {
        return this.multiplyQuaternions(t, this);
    }
    multiplyQuaternions(t, e) {
        let n = t._x, i = t._y, r = t._z, a = t._w, o = e._x, c = e._y, l = e._z, h = e._w;
        return this._x = n * h + a * o + i * l - r * c, this._y = i * h + a * c + r * o - n * l, this._z = r * h + a * l + n * c - i * o, this._w = a * h - n * o - i * c - r * l, this._onChangeCallback(), this;
    }
    slerp(t, e) {
        if (e === 0) return this;
        if (e === 1) return this.copy(t);
        let n = this._x, i = this._y, r = this._z, a = this._w, o = a * t._w + n * t._x + i * t._y + r * t._z;
        if (o < 0 ? (this._w = -t._w, this._x = -t._x, this._y = -t._y, this._z = -t._z, o = -o) : this.copy(t), o >= 1) return this._w = a, this._x = n, this._y = i, this._z = r, this;
        let c = 1 - o * o;
        if (c <= Number.EPSILON) {
            let f = 1 - e;
            return this._w = f * a + e * this._w, this._x = f * n + e * this._x, this._y = f * i + e * this._y, this._z = f * r + e * this._z, this.normalize(), this._onChangeCallback(), this;
        }
        let l = Math.sqrt(c), h = Math.atan2(l, o), u = Math.sin((1 - e) * h) / l, d = Math.sin(e * h) / l;
        return this._w = a * u + this._w * d, this._x = n * u + this._x * d, this._y = i * u + this._y * d, this._z = r * u + this._z * d, this._onChangeCallback(), this;
    }
    slerpQuaternions(t, e, n) {
        return this.copy(t).slerp(e, n);
    }
    random() {
        let t = Math.random(), e = Math.sqrt(1 - t), n = Math.sqrt(t), i = 2 * Math.PI * Math.random(), r = 2 * Math.PI * Math.random();
        return this.set(e * Math.cos(i), n * Math.sin(r), n * Math.cos(r), e * Math.sin(i));
    }
    equals(t) {
        return t._x === this._x && t._y === this._y && t._z === this._z && t._w === this._w;
    }
    fromArray(t, e = 0) {
        return this._x = t[e], this._y = t[e + 1], this._z = t[e + 2], this._w = t[e + 3], this._onChangeCallback(), this;
    }
    toArray(t = [], e = 0) {
        return t[e] = this._x, t[e + 1] = this._y, t[e + 2] = this._z, t[e + 3] = this._w, t;
    }
    fromBufferAttribute(t, e) {
        return this._x = t.getX(e), this._y = t.getY(e), this._z = t.getZ(e), this._w = t.getW(e), this;
    }
    toJSON() {
        return this.toArray();
    }
    _onChange(t) {
        return this._onChangeCallback = t, this;
    }
    _onChangeCallback() {}
    *[Symbol.iterator]() {
        yield this._x, yield this._y, yield this._z, yield this._w;
    }
}, A = class s1 {
    constructor(t = 0, e = 0, n = 0){
        s1.prototype.isVector3 = !0, this.x = t, this.y = e, this.z = n;
    }
    set(t, e, n) {
        return n === void 0 && (n = this.z), this.x = t, this.y = e, this.z = n, this;
    }
    setScalar(t) {
        return this.x = t, this.y = t, this.z = t, this;
    }
    setX(t) {
        return this.x = t, this;
    }
    setY(t) {
        return this.y = t, this;
    }
    setZ(t) {
        return this.z = t, this;
    }
    setComponent(t, e) {
        switch(t){
            case 0:
                this.x = e;
                break;
            case 1:
                this.y = e;
                break;
            case 2:
                this.z = e;
                break;
            default:
                throw new Error("index is out of range: " + t);
        }
        return this;
    }
    getComponent(t) {
        switch(t){
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            default:
                throw new Error("index is out of range: " + t);
        }
    }
    clone() {
        return new this.constructor(this.x, this.y, this.z);
    }
    copy(t) {
        return this.x = t.x, this.y = t.y, this.z = t.z, this;
    }
    add(t) {
        return this.x += t.x, this.y += t.y, this.z += t.z, this;
    }
    addScalar(t) {
        return this.x += t, this.y += t, this.z += t, this;
    }
    addVectors(t, e) {
        return this.x = t.x + e.x, this.y = t.y + e.y, this.z = t.z + e.z, this;
    }
    addScaledVector(t, e) {
        return this.x += t.x * e, this.y += t.y * e, this.z += t.z * e, this;
    }
    sub(t) {
        return this.x -= t.x, this.y -= t.y, this.z -= t.z, this;
    }
    subScalar(t) {
        return this.x -= t, this.y -= t, this.z -= t, this;
    }
    subVectors(t, e) {
        return this.x = t.x - e.x, this.y = t.y - e.y, this.z = t.z - e.z, this;
    }
    multiply(t) {
        return this.x *= t.x, this.y *= t.y, this.z *= t.z, this;
    }
    multiplyScalar(t) {
        return this.x *= t, this.y *= t, this.z *= t, this;
    }
    multiplyVectors(t, e) {
        return this.x = t.x * e.x, this.y = t.y * e.y, this.z = t.z * e.z, this;
    }
    applyEuler(t) {
        return this.applyQuaternion(Nl.setFromEuler(t));
    }
    applyAxisAngle(t, e) {
        return this.applyQuaternion(Nl.setFromAxisAngle(t, e));
    }
    applyMatrix3(t) {
        let e = this.x, n = this.y, i = this.z, r = t.elements;
        return this.x = r[0] * e + r[3] * n + r[6] * i, this.y = r[1] * e + r[4] * n + r[7] * i, this.z = r[2] * e + r[5] * n + r[8] * i, this;
    }
    applyNormalMatrix(t) {
        return this.applyMatrix3(t).normalize();
    }
    applyMatrix4(t) {
        let e = this.x, n = this.y, i = this.z, r = t.elements, a = 1 / (r[3] * e + r[7] * n + r[11] * i + r[15]);
        return this.x = (r[0] * e + r[4] * n + r[8] * i + r[12]) * a, this.y = (r[1] * e + r[5] * n + r[9] * i + r[13]) * a, this.z = (r[2] * e + r[6] * n + r[10] * i + r[14]) * a, this;
    }
    applyQuaternion(t) {
        let e = this.x, n = this.y, i = this.z, r = t.x, a = t.y, o = t.z, c = t.w, l = c * e + a * i - o * n, h = c * n + o * e - r * i, u = c * i + r * n - a * e, d = -r * e - a * n - o * i;
        return this.x = l * c + d * -r + h * -o - u * -a, this.y = h * c + d * -a + u * -r - l * -o, this.z = u * c + d * -o + l * -a - h * -r, this;
    }
    project(t) {
        return this.applyMatrix4(t.matrixWorldInverse).applyMatrix4(t.projectionMatrix);
    }
    unproject(t) {
        return this.applyMatrix4(t.projectionMatrixInverse).applyMatrix4(t.matrixWorld);
    }
    transformDirection(t) {
        let e = this.x, n = this.y, i = this.z, r = t.elements;
        return this.x = r[0] * e + r[4] * n + r[8] * i, this.y = r[1] * e + r[5] * n + r[9] * i, this.z = r[2] * e + r[6] * n + r[10] * i, this.normalize();
    }
    divide(t) {
        return this.x /= t.x, this.y /= t.y, this.z /= t.z, this;
    }
    divideScalar(t) {
        return this.multiplyScalar(1 / t);
    }
    min(t) {
        return this.x = Math.min(this.x, t.x), this.y = Math.min(this.y, t.y), this.z = Math.min(this.z, t.z), this;
    }
    max(t) {
        return this.x = Math.max(this.x, t.x), this.y = Math.max(this.y, t.y), this.z = Math.max(this.z, t.z), this;
    }
    clamp(t, e) {
        return this.x = Math.max(t.x, Math.min(e.x, this.x)), this.y = Math.max(t.y, Math.min(e.y, this.y)), this.z = Math.max(t.z, Math.min(e.z, this.z)), this;
    }
    clampScalar(t, e) {
        return this.x = Math.max(t, Math.min(e, this.x)), this.y = Math.max(t, Math.min(e, this.y)), this.z = Math.max(t, Math.min(e, this.z)), this;
    }
    clampLength(t, e) {
        let n = this.length();
        return this.divideScalar(n || 1).multiplyScalar(Math.max(t, Math.min(e, n)));
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
    dot(t) {
        return this.x * t.x + this.y * t.y + this.z * t.z;
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
    setLength(t) {
        return this.normalize().multiplyScalar(t);
    }
    lerp(t, e) {
        return this.x += (t.x - this.x) * e, this.y += (t.y - this.y) * e, this.z += (t.z - this.z) * e, this;
    }
    lerpVectors(t, e, n) {
        return this.x = t.x + (e.x - t.x) * n, this.y = t.y + (e.y - t.y) * n, this.z = t.z + (e.z - t.z) * n, this;
    }
    cross(t) {
        return this.crossVectors(this, t);
    }
    crossVectors(t, e) {
        let n = t.x, i = t.y, r = t.z, a = e.x, o = e.y, c = e.z;
        return this.x = i * c - r * o, this.y = r * a - n * c, this.z = n * o - i * a, this;
    }
    projectOnVector(t) {
        let e = t.lengthSq();
        if (e === 0) return this.set(0, 0, 0);
        let n = t.dot(this) / e;
        return this.copy(t).multiplyScalar(n);
    }
    projectOnPlane(t) {
        return La.copy(this).projectOnVector(t), this.sub(La);
    }
    reflect(t) {
        return this.sub(La.copy(t).multiplyScalar(2 * this.dot(t)));
    }
    angleTo(t) {
        let e = Math.sqrt(this.lengthSq() * t.lengthSq());
        if (e === 0) return Math.PI / 2;
        let n = this.dot(t) / e;
        return Math.acos(ae(n, -1, 1));
    }
    distanceTo(t) {
        return Math.sqrt(this.distanceToSquared(t));
    }
    distanceToSquared(t) {
        let e = this.x - t.x, n = this.y - t.y, i = this.z - t.z;
        return e * e + n * n + i * i;
    }
    manhattanDistanceTo(t) {
        return Math.abs(this.x - t.x) + Math.abs(this.y - t.y) + Math.abs(this.z - t.z);
    }
    setFromSpherical(t) {
        return this.setFromSphericalCoords(t.radius, t.phi, t.theta);
    }
    setFromSphericalCoords(t, e, n) {
        let i = Math.sin(e) * t;
        return this.x = i * Math.sin(n), this.y = Math.cos(e) * t, this.z = i * Math.cos(n), this;
    }
    setFromCylindrical(t) {
        return this.setFromCylindricalCoords(t.radius, t.theta, t.y);
    }
    setFromCylindricalCoords(t, e, n) {
        return this.x = t * Math.sin(e), this.y = n, this.z = t * Math.cos(e), this;
    }
    setFromMatrixPosition(t) {
        let e = t.elements;
        return this.x = e[12], this.y = e[13], this.z = e[14], this;
    }
    setFromMatrixScale(t) {
        let e = this.setFromMatrixColumn(t, 0).length(), n = this.setFromMatrixColumn(t, 1).length(), i = this.setFromMatrixColumn(t, 2).length();
        return this.x = e, this.y = n, this.z = i, this;
    }
    setFromMatrixColumn(t, e) {
        return this.fromArray(t.elements, e * 4);
    }
    setFromMatrix3Column(t, e) {
        return this.fromArray(t.elements, e * 3);
    }
    setFromEuler(t) {
        return this.x = t._x, this.y = t._y, this.z = t._z, this;
    }
    setFromColor(t) {
        return this.x = t.r, this.y = t.g, this.z = t.b, this;
    }
    equals(t) {
        return t.x === this.x && t.y === this.y && t.z === this.z;
    }
    fromArray(t, e = 0) {
        return this.x = t[e], this.y = t[e + 1], this.z = t[e + 2], this;
    }
    toArray(t = [], e = 0) {
        return t[e] = this.x, t[e + 1] = this.y, t[e + 2] = this.z, t;
    }
    fromBufferAttribute(t, e) {
        return this.x = t.getX(e), this.y = t.getY(e), this.z = t.getZ(e), this;
    }
    random() {
        return this.x = Math.random(), this.y = Math.random(), this.z = Math.random(), this;
    }
    randomDirection() {
        let t = (Math.random() - .5) * 2, e = Math.random() * Math.PI * 2, n = Math.sqrt(1 - t ** 2);
        return this.x = n * Math.cos(e), this.y = n * Math.sin(e), this.z = t, this;
    }
    *[Symbol.iterator]() {
        yield this.x, yield this.y, yield this.z;
    }
}, La = new A, Nl = new Pe, Ke = class {
    constructor(t = new A(1 / 0, 1 / 0, 1 / 0), e = new A(-1 / 0, -1 / 0, -1 / 0)){
        this.isBox3 = !0, this.min = t, this.max = e;
    }
    set(t, e) {
        return this.min.copy(t), this.max.copy(e), this;
    }
    setFromArray(t) {
        this.makeEmpty();
        for(let e = 0, n = t.length; e < n; e += 3)this.expandByPoint(cn.fromArray(t, e));
        return this;
    }
    setFromBufferAttribute(t) {
        this.makeEmpty();
        for(let e = 0, n = t.count; e < n; e++)this.expandByPoint(cn.fromBufferAttribute(t, e));
        return this;
    }
    setFromPoints(t) {
        this.makeEmpty();
        for(let e = 0, n = t.length; e < n; e++)this.expandByPoint(t[e]);
        return this;
    }
    setFromCenterAndSize(t, e) {
        let n = cn.copy(e).multiplyScalar(.5);
        return this.min.copy(t).sub(n), this.max.copy(t).add(n), this;
    }
    setFromObject(t, e = !1) {
        return this.makeEmpty(), this.expandByObject(t, e);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        return this.min.copy(t.min), this.max.copy(t.max), this;
    }
    makeEmpty() {
        return this.min.x = this.min.y = this.min.z = 1 / 0, this.max.x = this.max.y = this.max.z = -1 / 0, this;
    }
    isEmpty() {
        return this.max.x < this.min.x || this.max.y < this.min.y || this.max.z < this.min.z;
    }
    getCenter(t) {
        return this.isEmpty() ? t.set(0, 0, 0) : t.addVectors(this.min, this.max).multiplyScalar(.5);
    }
    getSize(t) {
        return this.isEmpty() ? t.set(0, 0, 0) : t.subVectors(this.max, this.min);
    }
    expandByPoint(t) {
        return this.min.min(t), this.max.max(t), this;
    }
    expandByVector(t) {
        return this.min.sub(t), this.max.add(t), this;
    }
    expandByScalar(t) {
        return this.min.addScalar(-t), this.max.addScalar(t), this;
    }
    expandByObject(t, e = !1) {
        if (t.updateWorldMatrix(!1, !1), t.boundingBox !== void 0) t.boundingBox === null && t.computeBoundingBox(), _i.copy(t.boundingBox), _i.applyMatrix4(t.matrixWorld), this.union(_i);
        else {
            let i = t.geometry;
            if (i !== void 0) if (e && i.attributes !== void 0 && i.attributes.position !== void 0) {
                let r = i.attributes.position;
                for(let a = 0, o = r.count; a < o; a++)cn.fromBufferAttribute(r, a).applyMatrix4(t.matrixWorld), this.expandByPoint(cn);
            } else i.boundingBox === null && i.computeBoundingBox(), _i.copy(i.boundingBox), _i.applyMatrix4(t.matrixWorld), this.union(_i);
        }
        let n = t.children;
        for(let i = 0, r = n.length; i < r; i++)this.expandByObject(n[i], e);
        return this;
    }
    containsPoint(t) {
        return !(t.x < this.min.x || t.x > this.max.x || t.y < this.min.y || t.y > this.max.y || t.z < this.min.z || t.z > this.max.z);
    }
    containsBox(t) {
        return this.min.x <= t.min.x && t.max.x <= this.max.x && this.min.y <= t.min.y && t.max.y <= this.max.y && this.min.z <= t.min.z && t.max.z <= this.max.z;
    }
    getParameter(t, e) {
        return e.set((t.x - this.min.x) / (this.max.x - this.min.x), (t.y - this.min.y) / (this.max.y - this.min.y), (t.z - this.min.z) / (this.max.z - this.min.z));
    }
    intersectsBox(t) {
        return !(t.max.x < this.min.x || t.min.x > this.max.x || t.max.y < this.min.y || t.min.y > this.max.y || t.max.z < this.min.z || t.min.z > this.max.z);
    }
    intersectsSphere(t) {
        return this.clampPoint(t.center, cn), cn.distanceToSquared(t.center) <= t.radius * t.radius;
    }
    intersectsPlane(t) {
        let e, n;
        return t.normal.x > 0 ? (e = t.normal.x * this.min.x, n = t.normal.x * this.max.x) : (e = t.normal.x * this.max.x, n = t.normal.x * this.min.x), t.normal.y > 0 ? (e += t.normal.y * this.min.y, n += t.normal.y * this.max.y) : (e += t.normal.y * this.max.y, n += t.normal.y * this.min.y), t.normal.z > 0 ? (e += t.normal.z * this.min.z, n += t.normal.z * this.max.z) : (e += t.normal.z * this.max.z, n += t.normal.z * this.min.z), e <= -t.constant && n >= -t.constant;
    }
    intersectsTriangle(t) {
        if (this.isEmpty()) return !1;
        this.getCenter(cs), Xs.subVectors(this.max, cs), xi.subVectors(t.a, cs), vi.subVectors(t.b, cs), yi.subVectors(t.c, cs), Tn.subVectors(vi, xi), wn.subVectors(yi, vi), Gn.subVectors(xi, yi);
        let e = [
            0,
            -Tn.z,
            Tn.y,
            0,
            -wn.z,
            wn.y,
            0,
            -Gn.z,
            Gn.y,
            Tn.z,
            0,
            -Tn.x,
            wn.z,
            0,
            -wn.x,
            Gn.z,
            0,
            -Gn.x,
            -Tn.y,
            Tn.x,
            0,
            -wn.y,
            wn.x,
            0,
            -Gn.y,
            Gn.x,
            0
        ];
        return !Ia(e, xi, vi, yi, Xs) || (e = [
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
        ], !Ia(e, xi, vi, yi, Xs)) ? !1 : (qs.crossVectors(Tn, wn), e = [
            qs.x,
            qs.y,
            qs.z
        ], Ia(e, xi, vi, yi, Xs));
    }
    clampPoint(t, e) {
        return e.copy(t).clamp(this.min, this.max);
    }
    distanceToPoint(t) {
        return this.clampPoint(t, cn).distanceTo(t);
    }
    getBoundingSphere(t) {
        return this.isEmpty() ? t.makeEmpty() : (this.getCenter(t.center), t.radius = this.getSize(cn).length() * .5), t;
    }
    intersect(t) {
        return this.min.max(t.min), this.max.min(t.max), this.isEmpty() && this.makeEmpty(), this;
    }
    union(t) {
        return this.min.min(t.min), this.max.max(t.max), this;
    }
    applyMatrix4(t) {
        return this.isEmpty() ? this : (on[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(t), on[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(t), on[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(t), on[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(t), on[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(t), on[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(t), on[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(t), on[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(t), this.setFromPoints(on), this);
    }
    translate(t) {
        return this.min.add(t), this.max.add(t), this;
    }
    equals(t) {
        return t.min.equals(this.min) && t.max.equals(this.max);
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
], cn = new A, _i = new Ke, xi = new A, vi = new A, yi = new A, Tn = new A, wn = new A, Gn = new A, cs = new A, Xs = new A, qs = new A, Wn = new A;
function Ia(s1, t, e, n, i) {
    for(let r = 0, a = s1.length - 3; r <= a; r += 3){
        Wn.fromArray(s1, r);
        let o = i.x * Math.abs(Wn.x) + i.y * Math.abs(Wn.y) + i.z * Math.abs(Wn.z), c = t.dot(Wn), l = e.dot(Wn), h = n.dot(Wn);
        if (Math.max(-Math.max(c, l, h), Math.min(c, l, h)) > o) return !1;
    }
    return !0;
}
var ip = new Ke, ls = new A, Ua = new A, We = class {
    constructor(t = new A, e = -1){
        this.center = t, this.radius = e;
    }
    set(t, e) {
        return this.center.copy(t), this.radius = e, this;
    }
    setFromPoints(t, e) {
        let n = this.center;
        e !== void 0 ? n.copy(e) : ip.setFromPoints(t).getCenter(n);
        let i = 0;
        for(let r = 0, a = t.length; r < a; r++)i = Math.max(i, n.distanceToSquared(t[r]));
        return this.radius = Math.sqrt(i), this;
    }
    copy(t) {
        return this.center.copy(t.center), this.radius = t.radius, this;
    }
    isEmpty() {
        return this.radius < 0;
    }
    makeEmpty() {
        return this.center.set(0, 0, 0), this.radius = -1, this;
    }
    containsPoint(t) {
        return t.distanceToSquared(this.center) <= this.radius * this.radius;
    }
    distanceToPoint(t) {
        return t.distanceTo(this.center) - this.radius;
    }
    intersectsSphere(t) {
        let e = this.radius + t.radius;
        return t.center.distanceToSquared(this.center) <= e * e;
    }
    intersectsBox(t) {
        return t.intersectsSphere(this);
    }
    intersectsPlane(t) {
        return Math.abs(t.distanceToPoint(this.center)) <= this.radius;
    }
    clampPoint(t, e) {
        let n = this.center.distanceToSquared(t);
        return e.copy(t), n > this.radius * this.radius && (e.sub(this.center).normalize(), e.multiplyScalar(this.radius).add(this.center)), e;
    }
    getBoundingBox(t) {
        return this.isEmpty() ? (t.makeEmpty(), t) : (t.set(this.center, this.center), t.expandByScalar(this.radius), t);
    }
    applyMatrix4(t) {
        return this.center.applyMatrix4(t), this.radius = this.radius * t.getMaxScaleOnAxis(), this;
    }
    translate(t) {
        return this.center.add(t), this;
    }
    expandByPoint(t) {
        if (this.isEmpty()) return this.center.copy(t), this.radius = 0, this;
        ls.subVectors(t, this.center);
        let e = ls.lengthSq();
        if (e > this.radius * this.radius) {
            let n = Math.sqrt(e), i = (n - this.radius) * .5;
            this.center.addScaledVector(ls, i / n), this.radius += i;
        }
        return this;
    }
    union(t) {
        return t.isEmpty() ? this : this.isEmpty() ? (this.copy(t), this) : (this.center.equals(t.center) === !0 ? this.radius = Math.max(this.radius, t.radius) : (Ua.subVectors(t.center, this.center).setLength(t.radius), this.expandByPoint(ls.copy(t.center).add(Ua)), this.expandByPoint(ls.copy(t.center).sub(Ua))), this);
    }
    equals(t) {
        return t.center.equals(this.center) && t.radius === this.radius;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, ln = new A, Da = new A, Ys = new A, An = new A, Na = new A, Zs = new A, Fa = new A, hi = class {
    constructor(t = new A, e = new A(0, 0, -1)){
        this.origin = t, this.direction = e;
    }
    set(t, e) {
        return this.origin.copy(t), this.direction.copy(e), this;
    }
    copy(t) {
        return this.origin.copy(t.origin), this.direction.copy(t.direction), this;
    }
    at(t, e) {
        return e.copy(this.origin).addScaledVector(this.direction, t);
    }
    lookAt(t) {
        return this.direction.copy(t).sub(this.origin).normalize(), this;
    }
    recast(t) {
        return this.origin.copy(this.at(t, ln)), this;
    }
    closestPointToPoint(t, e) {
        e.subVectors(t, this.origin);
        let n = e.dot(this.direction);
        return n < 0 ? e.copy(this.origin) : e.copy(this.origin).addScaledVector(this.direction, n);
    }
    distanceToPoint(t) {
        return Math.sqrt(this.distanceSqToPoint(t));
    }
    distanceSqToPoint(t) {
        let e = ln.subVectors(t, this.origin).dot(this.direction);
        return e < 0 ? this.origin.distanceToSquared(t) : (ln.copy(this.origin).addScaledVector(this.direction, e), ln.distanceToSquared(t));
    }
    distanceSqToSegment(t, e, n, i) {
        Da.copy(t).add(e).multiplyScalar(.5), Ys.copy(e).sub(t).normalize(), An.copy(this.origin).sub(Da);
        let r = t.distanceTo(e) * .5, a = -this.direction.dot(Ys), o = An.dot(this.direction), c = -An.dot(Ys), l = An.lengthSq(), h = Math.abs(1 - a * a), u, d, f, m;
        if (h > 0) if (u = a * c - o, d = a * o - c, m = r * h, u >= 0) if (d >= -m) if (d <= m) {
            let x = 1 / h;
            u *= x, d *= x, f = u * (u + a * d + 2 * o) + d * (a * u + d + 2 * c) + l;
        } else d = r, u = Math.max(0, -(a * d + o)), f = -u * u + d * (d + 2 * c) + l;
        else d = -r, u = Math.max(0, -(a * d + o)), f = -u * u + d * (d + 2 * c) + l;
        else d <= -m ? (u = Math.max(0, -(-a * r + o)), d = u > 0 ? -r : Math.min(Math.max(-r, -c), r), f = -u * u + d * (d + 2 * c) + l) : d <= m ? (u = 0, d = Math.min(Math.max(-r, -c), r), f = d * (d + 2 * c) + l) : (u = Math.max(0, -(a * r + o)), d = u > 0 ? r : Math.min(Math.max(-r, -c), r), f = -u * u + d * (d + 2 * c) + l);
        else d = a > 0 ? -r : r, u = Math.max(0, -(a * d + o)), f = -u * u + d * (d + 2 * c) + l;
        return n && n.copy(this.origin).addScaledVector(this.direction, u), i && i.copy(Da).addScaledVector(Ys, d), f;
    }
    intersectSphere(t, e) {
        ln.subVectors(t.center, this.origin);
        let n = ln.dot(this.direction), i = ln.dot(ln) - n * n, r = t.radius * t.radius;
        if (i > r) return null;
        let a = Math.sqrt(r - i), o = n - a, c = n + a;
        return c < 0 ? null : o < 0 ? this.at(c, e) : this.at(o, e);
    }
    intersectsSphere(t) {
        return this.distanceSqToPoint(t.center) <= t.radius * t.radius;
    }
    distanceToPlane(t) {
        let e = t.normal.dot(this.direction);
        if (e === 0) return t.distanceToPoint(this.origin) === 0 ? 0 : null;
        let n = -(this.origin.dot(t.normal) + t.constant) / e;
        return n >= 0 ? n : null;
    }
    intersectPlane(t, e) {
        let n = this.distanceToPlane(t);
        return n === null ? null : this.at(n, e);
    }
    intersectsPlane(t) {
        let e = t.distanceToPoint(this.origin);
        return e === 0 || t.normal.dot(this.direction) * e < 0;
    }
    intersectBox(t, e) {
        let n, i, r, a, o, c, l = 1 / this.direction.x, h = 1 / this.direction.y, u = 1 / this.direction.z, d = this.origin;
        return l >= 0 ? (n = (t.min.x - d.x) * l, i = (t.max.x - d.x) * l) : (n = (t.max.x - d.x) * l, i = (t.min.x - d.x) * l), h >= 0 ? (r = (t.min.y - d.y) * h, a = (t.max.y - d.y) * h) : (r = (t.max.y - d.y) * h, a = (t.min.y - d.y) * h), n > a || r > i || ((r > n || isNaN(n)) && (n = r), (a < i || isNaN(i)) && (i = a), u >= 0 ? (o = (t.min.z - d.z) * u, c = (t.max.z - d.z) * u) : (o = (t.max.z - d.z) * u, c = (t.min.z - d.z) * u), n > c || o > i) || ((o > n || n !== n) && (n = o), (c < i || i !== i) && (i = c), i < 0) ? null : this.at(n >= 0 ? n : i, e);
    }
    intersectsBox(t) {
        return this.intersectBox(t, ln) !== null;
    }
    intersectTriangle(t, e, n, i, r) {
        Na.subVectors(e, t), Zs.subVectors(n, t), Fa.crossVectors(Na, Zs);
        let a = this.direction.dot(Fa), o;
        if (a > 0) {
            if (i) return null;
            o = 1;
        } else if (a < 0) o = -1, a = -a;
        else return null;
        An.subVectors(this.origin, t);
        let c = o * this.direction.dot(Zs.crossVectors(An, Zs));
        if (c < 0) return null;
        let l = o * this.direction.dot(Na.cross(An));
        if (l < 0 || c + l > a) return null;
        let h = -o * An.dot(Fa);
        return h < 0 ? null : this.at(h / a, r);
    }
    applyMatrix4(t) {
        return this.origin.applyMatrix4(t), this.direction.transformDirection(t), this;
    }
    equals(t) {
        return t.origin.equals(this.origin) && t.direction.equals(this.direction);
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Ot = class s1 {
    constructor(t, e, n, i, r, a, o, c, l, h, u, d, f, m, x, g){
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
        ], t !== void 0 && this.set(t, e, n, i, r, a, o, c, l, h, u, d, f, m, x, g);
    }
    set(t, e, n, i, r, a, o, c, l, h, u, d, f, m, x, g) {
        let p = this.elements;
        return p[0] = t, p[4] = e, p[8] = n, p[12] = i, p[1] = r, p[5] = a, p[9] = o, p[13] = c, p[2] = l, p[6] = h, p[10] = u, p[14] = d, p[3] = f, p[7] = m, p[11] = x, p[15] = g, this;
    }
    identity() {
        return this.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), this;
    }
    clone() {
        return new s1().fromArray(this.elements);
    }
    copy(t) {
        let e = this.elements, n = t.elements;
        return e[0] = n[0], e[1] = n[1], e[2] = n[2], e[3] = n[3], e[4] = n[4], e[5] = n[5], e[6] = n[6], e[7] = n[7], e[8] = n[8], e[9] = n[9], e[10] = n[10], e[11] = n[11], e[12] = n[12], e[13] = n[13], e[14] = n[14], e[15] = n[15], this;
    }
    copyPosition(t) {
        let e = this.elements, n = t.elements;
        return e[12] = n[12], e[13] = n[13], e[14] = n[14], this;
    }
    setFromMatrix3(t) {
        let e = t.elements;
        return this.set(e[0], e[3], e[6], 0, e[1], e[4], e[7], 0, e[2], e[5], e[8], 0, 0, 0, 0, 1), this;
    }
    extractBasis(t, e, n) {
        return t.setFromMatrixColumn(this, 0), e.setFromMatrixColumn(this, 1), n.setFromMatrixColumn(this, 2), this;
    }
    makeBasis(t, e, n) {
        return this.set(t.x, e.x, n.x, 0, t.y, e.y, n.y, 0, t.z, e.z, n.z, 0, 0, 0, 0, 1), this;
    }
    extractRotation(t) {
        let e = this.elements, n = t.elements, i = 1 / Mi.setFromMatrixColumn(t, 0).length(), r = 1 / Mi.setFromMatrixColumn(t, 1).length(), a = 1 / Mi.setFromMatrixColumn(t, 2).length();
        return e[0] = n[0] * i, e[1] = n[1] * i, e[2] = n[2] * i, e[3] = 0, e[4] = n[4] * r, e[5] = n[5] * r, e[6] = n[6] * r, e[7] = 0, e[8] = n[8] * a, e[9] = n[9] * a, e[10] = n[10] * a, e[11] = 0, e[12] = 0, e[13] = 0, e[14] = 0, e[15] = 1, this;
    }
    makeRotationFromEuler(t) {
        let e = this.elements, n = t.x, i = t.y, r = t.z, a = Math.cos(n), o = Math.sin(n), c = Math.cos(i), l = Math.sin(i), h = Math.cos(r), u = Math.sin(r);
        if (t.order === "XYZ") {
            let d = a * h, f = a * u, m = o * h, x = o * u;
            e[0] = c * h, e[4] = -c * u, e[8] = l, e[1] = f + m * l, e[5] = d - x * l, e[9] = -o * c, e[2] = x - d * l, e[6] = m + f * l, e[10] = a * c;
        } else if (t.order === "YXZ") {
            let d = c * h, f = c * u, m = l * h, x = l * u;
            e[0] = d + x * o, e[4] = m * o - f, e[8] = a * l, e[1] = a * u, e[5] = a * h, e[9] = -o, e[2] = f * o - m, e[6] = x + d * o, e[10] = a * c;
        } else if (t.order === "ZXY") {
            let d = c * h, f = c * u, m = l * h, x = l * u;
            e[0] = d - x * o, e[4] = -a * u, e[8] = m + f * o, e[1] = f + m * o, e[5] = a * h, e[9] = x - d * o, e[2] = -a * l, e[6] = o, e[10] = a * c;
        } else if (t.order === "ZYX") {
            let d = a * h, f = a * u, m = o * h, x = o * u;
            e[0] = c * h, e[4] = m * l - f, e[8] = d * l + x, e[1] = c * u, e[5] = x * l + d, e[9] = f * l - m, e[2] = -l, e[6] = o * c, e[10] = a * c;
        } else if (t.order === "YZX") {
            let d = a * c, f = a * l, m = o * c, x = o * l;
            e[0] = c * h, e[4] = x - d * u, e[8] = m * u + f, e[1] = u, e[5] = a * h, e[9] = -o * h, e[2] = -l * h, e[6] = f * u + m, e[10] = d - x * u;
        } else if (t.order === "XZY") {
            let d = a * c, f = a * l, m = o * c, x = o * l;
            e[0] = c * h, e[4] = -u, e[8] = l * h, e[1] = d * u + x, e[5] = a * h, e[9] = f * u - m, e[2] = m * u - f, e[6] = o * h, e[10] = x * u + d;
        }
        return e[3] = 0, e[7] = 0, e[11] = 0, e[12] = 0, e[13] = 0, e[14] = 0, e[15] = 1, this;
    }
    makeRotationFromQuaternion(t) {
        return this.compose(sp, t, rp);
    }
    lookAt(t, e, n) {
        let i = this.elements;
        return Fe.subVectors(t, e), Fe.lengthSq() === 0 && (Fe.z = 1), Fe.normalize(), Rn.crossVectors(n, Fe), Rn.lengthSq() === 0 && (Math.abs(n.z) === 1 ? Fe.x += 1e-4 : Fe.z += 1e-4, Fe.normalize(), Rn.crossVectors(n, Fe)), Rn.normalize(), Js.crossVectors(Fe, Rn), i[0] = Rn.x, i[4] = Js.x, i[8] = Fe.x, i[1] = Rn.y, i[5] = Js.y, i[9] = Fe.y, i[2] = Rn.z, i[6] = Js.z, i[10] = Fe.z, this;
    }
    multiply(t) {
        return this.multiplyMatrices(this, t);
    }
    premultiply(t) {
        return this.multiplyMatrices(t, this);
    }
    multiplyMatrices(t, e) {
        let n = t.elements, i = e.elements, r = this.elements, a = n[0], o = n[4], c = n[8], l = n[12], h = n[1], u = n[5], d = n[9], f = n[13], m = n[2], x = n[6], g = n[10], p = n[14], v = n[3], _ = n[7], y = n[11], b = n[15], w = i[0], R = i[4], L = i[8], M = i[12], E = i[1], V = i[5], $ = i[9], F = i[13], O = i[2], z = i[6], K = i[10], X = i[14], Y = i[3], j = i[7], tt = i[11], N = i[15];
        return r[0] = a * w + o * E + c * O + l * Y, r[4] = a * R + o * V + c * z + l * j, r[8] = a * L + o * $ + c * K + l * tt, r[12] = a * M + o * F + c * X + l * N, r[1] = h * w + u * E + d * O + f * Y, r[5] = h * R + u * V + d * z + f * j, r[9] = h * L + u * $ + d * K + f * tt, r[13] = h * M + u * F + d * X + f * N, r[2] = m * w + x * E + g * O + p * Y, r[6] = m * R + x * V + g * z + p * j, r[10] = m * L + x * $ + g * K + p * tt, r[14] = m * M + x * F + g * X + p * N, r[3] = v * w + _ * E + y * O + b * Y, r[7] = v * R + _ * V + y * z + b * j, r[11] = v * L + _ * $ + y * K + b * tt, r[15] = v * M + _ * F + y * X + b * N, this;
    }
    multiplyScalar(t) {
        let e = this.elements;
        return e[0] *= t, e[4] *= t, e[8] *= t, e[12] *= t, e[1] *= t, e[5] *= t, e[9] *= t, e[13] *= t, e[2] *= t, e[6] *= t, e[10] *= t, e[14] *= t, e[3] *= t, e[7] *= t, e[11] *= t, e[15] *= t, this;
    }
    determinant() {
        let t = this.elements, e = t[0], n = t[4], i = t[8], r = t[12], a = t[1], o = t[5], c = t[9], l = t[13], h = t[2], u = t[6], d = t[10], f = t[14], m = t[3], x = t[7], g = t[11], p = t[15];
        return m * (+r * c * u - i * l * u - r * o * d + n * l * d + i * o * f - n * c * f) + x * (+e * c * f - e * l * d + r * a * d - i * a * f + i * l * h - r * c * h) + g * (+e * l * u - e * o * f - r * a * u + n * a * f + r * o * h - n * l * h) + p * (-i * o * h - e * c * u + e * o * d + i * a * u - n * a * d + n * c * h);
    }
    transpose() {
        let t = this.elements, e;
        return e = t[1], t[1] = t[4], t[4] = e, e = t[2], t[2] = t[8], t[8] = e, e = t[6], t[6] = t[9], t[9] = e, e = t[3], t[3] = t[12], t[12] = e, e = t[7], t[7] = t[13], t[13] = e, e = t[11], t[11] = t[14], t[14] = e, this;
    }
    setPosition(t, e, n) {
        let i = this.elements;
        return t.isVector3 ? (i[12] = t.x, i[13] = t.y, i[14] = t.z) : (i[12] = t, i[13] = e, i[14] = n), this;
    }
    invert() {
        let t = this.elements, e = t[0], n = t[1], i = t[2], r = t[3], a = t[4], o = t[5], c = t[6], l = t[7], h = t[8], u = t[9], d = t[10], f = t[11], m = t[12], x = t[13], g = t[14], p = t[15], v = u * g * l - x * d * l + x * c * f - o * g * f - u * c * p + o * d * p, _ = m * d * l - h * g * l - m * c * f + a * g * f + h * c * p - a * d * p, y = h * x * l - m * u * l + m * o * f - a * x * f - h * o * p + a * u * p, b = m * u * c - h * x * c - m * o * d + a * x * d + h * o * g - a * u * g, w = e * v + n * _ + i * y + r * b;
        if (w === 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        let R = 1 / w;
        return t[0] = v * R, t[1] = (x * d * r - u * g * r - x * i * f + n * g * f + u * i * p - n * d * p) * R, t[2] = (o * g * r - x * c * r + x * i * l - n * g * l - o * i * p + n * c * p) * R, t[3] = (u * c * r - o * d * r - u * i * l + n * d * l + o * i * f - n * c * f) * R, t[4] = _ * R, t[5] = (h * g * r - m * d * r + m * i * f - e * g * f - h * i * p + e * d * p) * R, t[6] = (m * c * r - a * g * r - m * i * l + e * g * l + a * i * p - e * c * p) * R, t[7] = (a * d * r - h * c * r + h * i * l - e * d * l - a * i * f + e * c * f) * R, t[8] = y * R, t[9] = (m * u * r - h * x * r - m * n * f + e * x * f + h * n * p - e * u * p) * R, t[10] = (a * x * r - m * o * r + m * n * l - e * x * l - a * n * p + e * o * p) * R, t[11] = (h * o * r - a * u * r - h * n * l + e * u * l + a * n * f - e * o * f) * R, t[12] = b * R, t[13] = (h * x * i - m * u * i + m * n * d - e * x * d - h * n * g + e * u * g) * R, t[14] = (m * o * i - a * x * i - m * n * c + e * x * c + a * n * g - e * o * g) * R, t[15] = (a * u * i - h * o * i + h * n * c - e * u * c - a * n * d + e * o * d) * R, this;
    }
    scale(t) {
        let e = this.elements, n = t.x, i = t.y, r = t.z;
        return e[0] *= n, e[4] *= i, e[8] *= r, e[1] *= n, e[5] *= i, e[9] *= r, e[2] *= n, e[6] *= i, e[10] *= r, e[3] *= n, e[7] *= i, e[11] *= r, this;
    }
    getMaxScaleOnAxis() {
        let t = this.elements, e = t[0] * t[0] + t[1] * t[1] + t[2] * t[2], n = t[4] * t[4] + t[5] * t[5] + t[6] * t[6], i = t[8] * t[8] + t[9] * t[9] + t[10] * t[10];
        return Math.sqrt(Math.max(e, n, i));
    }
    makeTranslation(t, e, n) {
        return t.isVector3 ? this.set(1, 0, 0, t.x, 0, 1, 0, t.y, 0, 0, 1, t.z, 0, 0, 0, 1) : this.set(1, 0, 0, t, 0, 1, 0, e, 0, 0, 1, n, 0, 0, 0, 1), this;
    }
    makeRotationX(t) {
        let e = Math.cos(t), n = Math.sin(t);
        return this.set(1, 0, 0, 0, 0, e, -n, 0, 0, n, e, 0, 0, 0, 0, 1), this;
    }
    makeRotationY(t) {
        let e = Math.cos(t), n = Math.sin(t);
        return this.set(e, 0, n, 0, 0, 1, 0, 0, -n, 0, e, 0, 0, 0, 0, 1), this;
    }
    makeRotationZ(t) {
        let e = Math.cos(t), n = Math.sin(t);
        return this.set(e, -n, 0, 0, n, e, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), this;
    }
    makeRotationAxis(t, e) {
        let n = Math.cos(e), i = Math.sin(e), r = 1 - n, a = t.x, o = t.y, c = t.z, l = r * a, h = r * o;
        return this.set(l * a + n, l * o - i * c, l * c + i * o, 0, l * o + i * c, h * o + n, h * c - i * a, 0, l * c - i * o, h * c + i * a, r * c * c + n, 0, 0, 0, 0, 1), this;
    }
    makeScale(t, e, n) {
        return this.set(t, 0, 0, 0, 0, e, 0, 0, 0, 0, n, 0, 0, 0, 0, 1), this;
    }
    makeShear(t, e, n, i, r, a) {
        return this.set(1, n, r, 0, t, 1, a, 0, e, i, 1, 0, 0, 0, 0, 1), this;
    }
    compose(t, e, n) {
        let i = this.elements, r = e._x, a = e._y, o = e._z, c = e._w, l = r + r, h = a + a, u = o + o, d = r * l, f = r * h, m = r * u, x = a * h, g = a * u, p = o * u, v = c * l, _ = c * h, y = c * u, b = n.x, w = n.y, R = n.z;
        return i[0] = (1 - (x + p)) * b, i[1] = (f + y) * b, i[2] = (m - _) * b, i[3] = 0, i[4] = (f - y) * w, i[5] = (1 - (d + p)) * w, i[6] = (g + v) * w, i[7] = 0, i[8] = (m + _) * R, i[9] = (g - v) * R, i[10] = (1 - (d + x)) * R, i[11] = 0, i[12] = t.x, i[13] = t.y, i[14] = t.z, i[15] = 1, this;
    }
    decompose(t, e, n) {
        let i = this.elements, r = Mi.set(i[0], i[1], i[2]).length(), a = Mi.set(i[4], i[5], i[6]).length(), o = Mi.set(i[8], i[9], i[10]).length();
        this.determinant() < 0 && (r = -r), t.x = i[12], t.y = i[13], t.z = i[14], Ze.copy(this);
        let l = 1 / r, h = 1 / a, u = 1 / o;
        return Ze.elements[0] *= l, Ze.elements[1] *= l, Ze.elements[2] *= l, Ze.elements[4] *= h, Ze.elements[5] *= h, Ze.elements[6] *= h, Ze.elements[8] *= u, Ze.elements[9] *= u, Ze.elements[10] *= u, e.setFromRotationMatrix(Ze), n.x = r, n.y = a, n.z = o, this;
    }
    makePerspective(t, e, n, i, r, a, o = vn) {
        let c = this.elements, l = 2 * r / (e - t), h = 2 * r / (n - i), u = (e + t) / (e - t), d = (n + i) / (n - i), f, m;
        if (o === vn) f = -(a + r) / (a - r), m = -2 * a * r / (a - r);
        else if (o === Vr) f = -a / (a - r), m = -a * r / (a - r);
        else throw new Error("THREE.Matrix4.makePerspective(): Invalid coordinate system: " + o);
        return c[0] = l, c[4] = 0, c[8] = u, c[12] = 0, c[1] = 0, c[5] = h, c[9] = d, c[13] = 0, c[2] = 0, c[6] = 0, c[10] = f, c[14] = m, c[3] = 0, c[7] = 0, c[11] = -1, c[15] = 0, this;
    }
    makeOrthographic(t, e, n, i, r, a, o = vn) {
        let c = this.elements, l = 1 / (e - t), h = 1 / (n - i), u = 1 / (a - r), d = (e + t) * l, f = (n + i) * h, m, x;
        if (o === vn) m = (a + r) * u, x = -2 * u;
        else if (o === Vr) m = r * u, x = -1 * u;
        else throw new Error("THREE.Matrix4.makeOrthographic(): Invalid coordinate system: " + o);
        return c[0] = 2 * l, c[4] = 0, c[8] = 0, c[12] = -d, c[1] = 0, c[5] = 2 * h, c[9] = 0, c[13] = -f, c[2] = 0, c[6] = 0, c[10] = x, c[14] = -m, c[3] = 0, c[7] = 0, c[11] = 0, c[15] = 1, this;
    }
    equals(t) {
        let e = this.elements, n = t.elements;
        for(let i = 0; i < 16; i++)if (e[i] !== n[i]) return !1;
        return !0;
    }
    fromArray(t, e = 0) {
        for(let n = 0; n < 16; n++)this.elements[n] = t[n + e];
        return this;
    }
    toArray(t = [], e = 0) {
        let n = this.elements;
        return t[e] = n[0], t[e + 1] = n[1], t[e + 2] = n[2], t[e + 3] = n[3], t[e + 4] = n[4], t[e + 5] = n[5], t[e + 6] = n[6], t[e + 7] = n[7], t[e + 8] = n[8], t[e + 9] = n[9], t[e + 10] = n[10], t[e + 11] = n[11], t[e + 12] = n[12], t[e + 13] = n[13], t[e + 14] = n[14], t[e + 15] = n[15], t;
    }
}, Mi = new A, Ze = new Ot, sp = new A(0, 0, 0), rp = new A(1, 1, 1), Rn = new A, Js = new A, Fe = new A, Fl = new Ot, Ol = new Pe, Xr = class s1 {
    constructor(t = 0, e = 0, n = 0, i = s1.DEFAULT_ORDER){
        this.isEuler = !0, this._x = t, this._y = e, this._z = n, this._order = i;
    }
    get x() {
        return this._x;
    }
    set x(t) {
        this._x = t, this._onChangeCallback();
    }
    get y() {
        return this._y;
    }
    set y(t) {
        this._y = t, this._onChangeCallback();
    }
    get z() {
        return this._z;
    }
    set z(t) {
        this._z = t, this._onChangeCallback();
    }
    get order() {
        return this._order;
    }
    set order(t) {
        this._order = t, this._onChangeCallback();
    }
    set(t, e, n, i = this._order) {
        return this._x = t, this._y = e, this._z = n, this._order = i, this._onChangeCallback(), this;
    }
    clone() {
        return new this.constructor(this._x, this._y, this._z, this._order);
    }
    copy(t) {
        return this._x = t._x, this._y = t._y, this._z = t._z, this._order = t._order, this._onChangeCallback(), this;
    }
    setFromRotationMatrix(t, e = this._order, n = !0) {
        let i = t.elements, r = i[0], a = i[4], o = i[8], c = i[1], l = i[5], h = i[9], u = i[2], d = i[6], f = i[10];
        switch(e){
            case "XYZ":
                this._y = Math.asin(ae(o, -1, 1)), Math.abs(o) < .9999999 ? (this._x = Math.atan2(-h, f), this._z = Math.atan2(-a, r)) : (this._x = Math.atan2(d, l), this._z = 0);
                break;
            case "YXZ":
                this._x = Math.asin(-ae(h, -1, 1)), Math.abs(h) < .9999999 ? (this._y = Math.atan2(o, f), this._z = Math.atan2(c, l)) : (this._y = Math.atan2(-u, r), this._z = 0);
                break;
            case "ZXY":
                this._x = Math.asin(ae(d, -1, 1)), Math.abs(d) < .9999999 ? (this._y = Math.atan2(-u, f), this._z = Math.atan2(-a, l)) : (this._y = 0, this._z = Math.atan2(c, r));
                break;
            case "ZYX":
                this._y = Math.asin(-ae(u, -1, 1)), Math.abs(u) < .9999999 ? (this._x = Math.atan2(d, f), this._z = Math.atan2(c, r)) : (this._x = 0, this._z = Math.atan2(-a, l));
                break;
            case "YZX":
                this._z = Math.asin(ae(c, -1, 1)), Math.abs(c) < .9999999 ? (this._x = Math.atan2(-h, l), this._y = Math.atan2(-u, r)) : (this._x = 0, this._y = Math.atan2(o, f));
                break;
            case "XZY":
                this._z = Math.asin(-ae(a, -1, 1)), Math.abs(a) < .9999999 ? (this._x = Math.atan2(d, l), this._y = Math.atan2(o, r)) : (this._x = Math.atan2(-h, f), this._y = 0);
                break;
            default:
                console.warn("THREE.Euler: .setFromRotationMatrix() encountered an unknown order: " + e);
        }
        return this._order = e, n === !0 && this._onChangeCallback(), this;
    }
    setFromQuaternion(t, e, n) {
        return Fl.makeRotationFromQuaternion(t), this.setFromRotationMatrix(Fl, e, n);
    }
    setFromVector3(t, e = this._order) {
        return this.set(t.x, t.y, t.z, e);
    }
    reorder(t) {
        return Ol.setFromEuler(this), this.setFromQuaternion(Ol, t);
    }
    equals(t) {
        return t._x === this._x && t._y === this._y && t._z === this._z && t._order === this._order;
    }
    fromArray(t) {
        return this._x = t[0], this._y = t[1], this._z = t[2], t[3] !== void 0 && (this._order = t[3]), this._onChangeCallback(), this;
    }
    toArray(t = [], e = 0) {
        return t[e] = this._x, t[e + 1] = this._y, t[e + 2] = this._z, t[e + 3] = this._order, t;
    }
    _onChange(t) {
        return this._onChangeCallback = t, this;
    }
    _onChangeCallback() {}
    *[Symbol.iterator]() {
        yield this._x, yield this._y, yield this._z, yield this._order;
    }
};
Xr.DEFAULT_ORDER = "XYZ";
var Rs = class {
    constructor(){
        this.mask = 1;
    }
    set(t) {
        this.mask = (1 << t | 0) >>> 0;
    }
    enable(t) {
        this.mask |= 1 << t | 0;
    }
    enableAll() {
        this.mask = -1;
    }
    toggle(t) {
        this.mask ^= 1 << t | 0;
    }
    disable(t) {
        this.mask &= ~(1 << t | 0);
    }
    disableAll() {
        this.mask = 0;
    }
    test(t) {
        return (this.mask & t.mask) !== 0;
    }
    isEnabled(t) {
        return (this.mask & (1 << t | 0)) !== 0;
    }
}, ap = 0, Bl = new A, Si = new Pe, hn = new Ot, $s = new A, hs = new A, op = new A, cp = new Pe, zl = new A(1, 0, 0), kl = new A(0, 1, 0), Vl = new A(0, 0, 1), lp = {
    type: "added"
}, Hl = {
    type: "removed"
}, Zt = class s1 extends sn {
    constructor(){
        super(), this.isObject3D = !0, Object.defineProperty(this, "id", {
            value: ap++
        }), this.uuid = Be(), this.name = "", this.type = "Object3D", this.parent = null, this.children = [], this.up = s1.DEFAULT_UP.clone();
        let t = new A, e = new Xr, n = new Pe, i = new A(1, 1, 1);
        function r() {
            n.setFromEuler(e, !1);
        }
        function a() {
            e.setFromQuaternion(n, void 0, !1);
        }
        e._onChange(r), n._onChange(a), Object.defineProperties(this, {
            position: {
                configurable: !0,
                enumerable: !0,
                value: t
            },
            rotation: {
                configurable: !0,
                enumerable: !0,
                value: e
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
                value: new Ot
            },
            normalMatrix: {
                value: new kt
            }
        }), this.matrix = new Ot, this.matrixWorld = new Ot, this.matrixAutoUpdate = s1.DEFAULT_MATRIX_AUTO_UPDATE, this.matrixWorldNeedsUpdate = !1, this.matrixWorldAutoUpdate = s1.DEFAULT_MATRIX_WORLD_AUTO_UPDATE, this.layers = new Rs, this.visible = !0, this.castShadow = !1, this.receiveShadow = !1, this.frustumCulled = !0, this.renderOrder = 0, this.animations = [], this.userData = {};
    }
    onBeforeRender() {}
    onAfterRender() {}
    applyMatrix4(t) {
        this.matrixAutoUpdate && this.updateMatrix(), this.matrix.premultiply(t), this.matrix.decompose(this.position, this.quaternion, this.scale);
    }
    applyQuaternion(t) {
        return this.quaternion.premultiply(t), this;
    }
    setRotationFromAxisAngle(t, e) {
        this.quaternion.setFromAxisAngle(t, e);
    }
    setRotationFromEuler(t) {
        this.quaternion.setFromEuler(t, !0);
    }
    setRotationFromMatrix(t) {
        this.quaternion.setFromRotationMatrix(t);
    }
    setRotationFromQuaternion(t) {
        this.quaternion.copy(t);
    }
    rotateOnAxis(t, e) {
        return Si.setFromAxisAngle(t, e), this.quaternion.multiply(Si), this;
    }
    rotateOnWorldAxis(t, e) {
        return Si.setFromAxisAngle(t, e), this.quaternion.premultiply(Si), this;
    }
    rotateX(t) {
        return this.rotateOnAxis(zl, t);
    }
    rotateY(t) {
        return this.rotateOnAxis(kl, t);
    }
    rotateZ(t) {
        return this.rotateOnAxis(Vl, t);
    }
    translateOnAxis(t, e) {
        return Bl.copy(t).applyQuaternion(this.quaternion), this.position.add(Bl.multiplyScalar(e)), this;
    }
    translateX(t) {
        return this.translateOnAxis(zl, t);
    }
    translateY(t) {
        return this.translateOnAxis(kl, t);
    }
    translateZ(t) {
        return this.translateOnAxis(Vl, t);
    }
    localToWorld(t) {
        return this.updateWorldMatrix(!0, !1), t.applyMatrix4(this.matrixWorld);
    }
    worldToLocal(t) {
        return this.updateWorldMatrix(!0, !1), t.applyMatrix4(hn.copy(this.matrixWorld).invert());
    }
    lookAt(t, e, n) {
        t.isVector3 ? $s.copy(t) : $s.set(t, e, n);
        let i = this.parent;
        this.updateWorldMatrix(!0, !1), hs.setFromMatrixPosition(this.matrixWorld), this.isCamera || this.isLight ? hn.lookAt(hs, $s, this.up) : hn.lookAt($s, hs, this.up), this.quaternion.setFromRotationMatrix(hn), i && (hn.extractRotation(i.matrixWorld), Si.setFromRotationMatrix(hn), this.quaternion.premultiply(Si.invert()));
    }
    add(t) {
        if (arguments.length > 1) {
            for(let e = 0; e < arguments.length; e++)this.add(arguments[e]);
            return this;
        }
        return t === this ? (console.error("THREE.Object3D.add: object can't be added as a child of itself.", t), this) : (t && t.isObject3D ? (t.parent !== null && t.parent.remove(t), t.parent = this, this.children.push(t), t.dispatchEvent(lp)) : console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.", t), this);
    }
    remove(t) {
        if (arguments.length > 1) {
            for(let n = 0; n < arguments.length; n++)this.remove(arguments[n]);
            return this;
        }
        let e = this.children.indexOf(t);
        return e !== -1 && (t.parent = null, this.children.splice(e, 1), t.dispatchEvent(Hl)), this;
    }
    removeFromParent() {
        let t = this.parent;
        return t !== null && t.remove(this), this;
    }
    clear() {
        for(let t = 0; t < this.children.length; t++){
            let e = this.children[t];
            e.parent = null, e.dispatchEvent(Hl);
        }
        return this.children.length = 0, this;
    }
    attach(t) {
        return this.updateWorldMatrix(!0, !1), hn.copy(this.matrixWorld).invert(), t.parent !== null && (t.parent.updateWorldMatrix(!0, !1), hn.multiply(t.parent.matrixWorld)), t.applyMatrix4(hn), this.add(t), t.updateWorldMatrix(!1, !0), this;
    }
    getObjectById(t) {
        return this.getObjectByProperty("id", t);
    }
    getObjectByName(t) {
        return this.getObjectByProperty("name", t);
    }
    getObjectByProperty(t, e) {
        if (this[t] === e) return this;
        for(let n = 0, i = this.children.length; n < i; n++){
            let a = this.children[n].getObjectByProperty(t, e);
            if (a !== void 0) return a;
        }
    }
    getObjectsByProperty(t, e) {
        let n = [];
        this[t] === e && n.push(this);
        for(let i = 0, r = this.children.length; i < r; i++){
            let a = this.children[i].getObjectsByProperty(t, e);
            a.length > 0 && (n = n.concat(a));
        }
        return n;
    }
    getWorldPosition(t) {
        return this.updateWorldMatrix(!0, !1), t.setFromMatrixPosition(this.matrixWorld);
    }
    getWorldQuaternion(t) {
        return this.updateWorldMatrix(!0, !1), this.matrixWorld.decompose(hs, t, op), t;
    }
    getWorldScale(t) {
        return this.updateWorldMatrix(!0, !1), this.matrixWorld.decompose(hs, cp, t), t;
    }
    getWorldDirection(t) {
        this.updateWorldMatrix(!0, !1);
        let e = this.matrixWorld.elements;
        return t.set(e[8], e[9], e[10]).normalize();
    }
    raycast() {}
    traverse(t) {
        t(this);
        let e = this.children;
        for(let n = 0, i = e.length; n < i; n++)e[n].traverse(t);
    }
    traverseVisible(t) {
        if (this.visible === !1) return;
        t(this);
        let e = this.children;
        for(let n = 0, i = e.length; n < i; n++)e[n].traverseVisible(t);
    }
    traverseAncestors(t) {
        let e = this.parent;
        e !== null && (t(e), e.traverseAncestors(t));
    }
    updateMatrix() {
        this.matrix.compose(this.position, this.quaternion, this.scale), this.matrixWorldNeedsUpdate = !0;
    }
    updateMatrixWorld(t) {
        this.matrixAutoUpdate && this.updateMatrix(), (this.matrixWorldNeedsUpdate || t) && (this.parent === null ? this.matrixWorld.copy(this.matrix) : this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix), this.matrixWorldNeedsUpdate = !1, t = !0);
        let e = this.children;
        for(let n = 0, i = e.length; n < i; n++){
            let r = e[n];
            (r.matrixWorldAutoUpdate === !0 || t === !0) && r.updateMatrixWorld(t);
        }
    }
    updateWorldMatrix(t, e) {
        let n = this.parent;
        if (t === !0 && n !== null && n.matrixWorldAutoUpdate === !0 && n.updateWorldMatrix(!0, !1), this.matrixAutoUpdate && this.updateMatrix(), this.parent === null ? this.matrixWorld.copy(this.matrix) : this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix), e === !0) {
            let i = this.children;
            for(let r = 0, a = i.length; r < a; r++){
                let o = i[r];
                o.matrixWorldAutoUpdate === !0 && o.updateWorldMatrix(!1, !0);
            }
        }
    }
    toJSON(t) {
        let e = t === void 0 || typeof t == "string", n = {};
        e && (t = {
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
            return o[c.uuid] === void 0 && (o[c.uuid] = c.toJSON(t)), c.uuid;
        }
        if (this.isScene) this.background && (this.background.isColor ? i.background = this.background.toJSON() : this.background.isTexture && (i.background = this.background.toJSON(t).uuid)), this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== !0 && (i.environment = this.environment.toJSON(t).uuid);
        else if (this.isMesh || this.isLine || this.isPoints) {
            i.geometry = r(t.geometries, this.geometry);
            let o = this.geometry.parameters;
            if (o !== void 0 && o.shapes !== void 0) {
                let c = o.shapes;
                if (Array.isArray(c)) for(let l = 0, h = c.length; l < h; l++){
                    let u = c[l];
                    r(t.shapes, u);
                }
                else r(t.shapes, c);
            }
        }
        if (this.isSkinnedMesh && (i.bindMode = this.bindMode, i.bindMatrix = this.bindMatrix.toArray(), this.skeleton !== void 0 && (r(t.skeletons, this.skeleton), i.skeleton = this.skeleton.uuid)), this.material !== void 0) if (Array.isArray(this.material)) {
            let o = [];
            for(let c = 0, l = this.material.length; c < l; c++)o.push(r(t.materials, this.material[c]));
            i.material = o;
        } else i.material = r(t.materials, this.material);
        if (this.children.length > 0) {
            i.children = [];
            for(let o = 0; o < this.children.length; o++)i.children.push(this.children[o].toJSON(t).object);
        }
        if (this.animations.length > 0) {
            i.animations = [];
            for(let o = 0; o < this.animations.length; o++){
                let c = this.animations[o];
                i.animations.push(r(t.animations, c));
            }
        }
        if (e) {
            let o = a(t.geometries), c = a(t.materials), l = a(t.textures), h = a(t.images), u = a(t.shapes), d = a(t.skeletons), f = a(t.animations), m = a(t.nodes);
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
    clone(t) {
        return new this.constructor().copy(this, t);
    }
    copy(t, e = !0) {
        if (this.name = t.name, this.up.copy(t.up), this.position.copy(t.position), this.rotation.order = t.rotation.order, this.quaternion.copy(t.quaternion), this.scale.copy(t.scale), this.matrix.copy(t.matrix), this.matrixWorld.copy(t.matrixWorld), this.matrixAutoUpdate = t.matrixAutoUpdate, this.matrixWorldNeedsUpdate = t.matrixWorldNeedsUpdate, this.matrixWorldAutoUpdate = t.matrixWorldAutoUpdate, this.layers.mask = t.layers.mask, this.visible = t.visible, this.castShadow = t.castShadow, this.receiveShadow = t.receiveShadow, this.frustumCulled = t.frustumCulled, this.renderOrder = t.renderOrder, this.animations = t.animations.slice(), this.userData = JSON.parse(JSON.stringify(t.userData)), e === !0) for(let n = 0; n < t.children.length; n++){
            let i = t.children[n];
            this.add(i.clone());
        }
        return this;
    }
};
Zt.DEFAULT_UP = new A(0, 1, 0);
Zt.DEFAULT_MATRIX_AUTO_UPDATE = !0;
Zt.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = !0;
var Je = new A, un = new A, Oa = new A, dn = new A, bi = new A, Ei = new A, Gl = new A, Ba = new A, za = new A, ka = new A, Ks = !1, In = class s1 {
    constructor(t = new A, e = new A, n = new A){
        this.a = t, this.b = e, this.c = n;
    }
    static getNormal(t, e, n, i) {
        i.subVectors(n, e), Je.subVectors(t, e), i.cross(Je);
        let r = i.lengthSq();
        return r > 0 ? i.multiplyScalar(1 / Math.sqrt(r)) : i.set(0, 0, 0);
    }
    static getBarycoord(t, e, n, i, r) {
        Je.subVectors(i, e), un.subVectors(n, e), Oa.subVectors(t, e);
        let a = Je.dot(Je), o = Je.dot(un), c = Je.dot(Oa), l = un.dot(un), h = un.dot(Oa), u = a * l - o * o;
        if (u === 0) return r.set(-2, -1, -1);
        let d = 1 / u, f = (l * c - o * h) * d, m = (a * h - o * c) * d;
        return r.set(1 - f - m, m, f);
    }
    static containsPoint(t, e, n, i) {
        return this.getBarycoord(t, e, n, i, dn), dn.x >= 0 && dn.y >= 0 && dn.x + dn.y <= 1;
    }
    static getUV(t, e, n, i, r, a, o, c) {
        return Ks === !1 && (console.warn("THREE.Triangle.getUV() has been renamed to THREE.Triangle.getInterpolation()."), Ks = !0), this.getInterpolation(t, e, n, i, r, a, o, c);
    }
    static getInterpolation(t, e, n, i, r, a, o, c) {
        return this.getBarycoord(t, e, n, i, dn), c.setScalar(0), c.addScaledVector(r, dn.x), c.addScaledVector(a, dn.y), c.addScaledVector(o, dn.z), c;
    }
    static isFrontFacing(t, e, n, i) {
        return Je.subVectors(n, e), un.subVectors(t, e), Je.cross(un).dot(i) < 0;
    }
    set(t, e, n) {
        return this.a.copy(t), this.b.copy(e), this.c.copy(n), this;
    }
    setFromPointsAndIndices(t, e, n, i) {
        return this.a.copy(t[e]), this.b.copy(t[n]), this.c.copy(t[i]), this;
    }
    setFromAttributeAndIndices(t, e, n, i) {
        return this.a.fromBufferAttribute(t, e), this.b.fromBufferAttribute(t, n), this.c.fromBufferAttribute(t, i), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        return this.a.copy(t.a), this.b.copy(t.b), this.c.copy(t.c), this;
    }
    getArea() {
        return Je.subVectors(this.c, this.b), un.subVectors(this.a, this.b), Je.cross(un).length() * .5;
    }
    getMidpoint(t) {
        return t.addVectors(this.a, this.b).add(this.c).multiplyScalar(1 / 3);
    }
    getNormal(t) {
        return s1.getNormal(this.a, this.b, this.c, t);
    }
    getPlane(t) {
        return t.setFromCoplanarPoints(this.a, this.b, this.c);
    }
    getBarycoord(t, e) {
        return s1.getBarycoord(t, this.a, this.b, this.c, e);
    }
    getUV(t, e, n, i, r) {
        return Ks === !1 && (console.warn("THREE.Triangle.getUV() has been renamed to THREE.Triangle.getInterpolation()."), Ks = !0), s1.getInterpolation(t, this.a, this.b, this.c, e, n, i, r);
    }
    getInterpolation(t, e, n, i, r) {
        return s1.getInterpolation(t, this.a, this.b, this.c, e, n, i, r);
    }
    containsPoint(t) {
        return s1.containsPoint(t, this.a, this.b, this.c);
    }
    isFrontFacing(t) {
        return s1.isFrontFacing(this.a, this.b, this.c, t);
    }
    intersectsBox(t) {
        return t.intersectsTriangle(this);
    }
    closestPointToPoint(t, e) {
        let n = this.a, i = this.b, r = this.c, a, o;
        bi.subVectors(i, n), Ei.subVectors(r, n), Ba.subVectors(t, n);
        let c = bi.dot(Ba), l = Ei.dot(Ba);
        if (c <= 0 && l <= 0) return e.copy(n);
        za.subVectors(t, i);
        let h = bi.dot(za), u = Ei.dot(za);
        if (h >= 0 && u <= h) return e.copy(i);
        let d = c * u - h * l;
        if (d <= 0 && c >= 0 && h <= 0) return a = c / (c - h), e.copy(n).addScaledVector(bi, a);
        ka.subVectors(t, r);
        let f = bi.dot(ka), m = Ei.dot(ka);
        if (m >= 0 && f <= m) return e.copy(r);
        let x = f * l - c * m;
        if (x <= 0 && l >= 0 && m <= 0) return o = l / (l - m), e.copy(n).addScaledVector(Ei, o);
        let g = h * m - f * u;
        if (g <= 0 && u - h >= 0 && f - m >= 0) return Gl.subVectors(r, i), o = (u - h) / (u - h + (f - m)), e.copy(i).addScaledVector(Gl, o);
        let p = 1 / (g + x + d);
        return a = x * p, o = d * p, e.copy(n).addScaledVector(bi, a).addScaledVector(Ei, o);
    }
    equals(t) {
        return t.a.equals(this.a) && t.b.equals(this.b) && t.c.equals(this.c);
    }
}, hp = 0, Me = class extends sn {
    constructor(){
        super(), this.isMaterial = !0, Object.defineProperty(this, "id", {
            value: hp++
        }), this.uuid = Be(), this.name = "", this.type = "Material", this.blending = Wi, this.side = On, this.vertexColors = !1, this.opacity = 1, this.transparent = !1, this.alphaHash = !1, this.blendSrc = id, this.blendDst = sd, this.blendEquation = Bi, this.blendSrcAlpha = null, this.blendDstAlpha = null, this.blendEquationAlpha = null, this.depthFunc = ao, this.depthTest = !0, this.depthWrite = !0, this.stencilWriteMask = 255, this.stencilFunc = wf, this.stencilRef = 0, this.stencilFuncMask = 255, this.stencilFail = Aa, this.stencilZFail = Aa, this.stencilZPass = Aa, this.stencilWrite = !1, this.clippingPlanes = null, this.clipIntersection = !1, this.clipShadows = !1, this.shadowSide = null, this.colorWrite = !0, this.precision = null, this.polygonOffset = !1, this.polygonOffsetFactor = 0, this.polygonOffsetUnits = 0, this.dithering = !1, this.alphaToCoverage = !1, this.premultipliedAlpha = !1, this.forceSinglePass = !1, this.visible = !0, this.toneMapped = !0, this.userData = {}, this.version = 0, this._alphaTest = 0;
    }
    get alphaTest() {
        return this._alphaTest;
    }
    set alphaTest(t) {
        this._alphaTest > 0 != t > 0 && this.version++, this._alphaTest = t;
    }
    onBuild() {}
    onBeforeRender() {}
    onBeforeCompile() {}
    customProgramCacheKey() {
        return this.onBeforeCompile.toString();
    }
    setValues(t) {
        if (t !== void 0) for(let e in t){
            let n = t[e];
            if (n === void 0) {
                console.warn(`THREE.Material: parameter '${e}' has value of undefined.`);
                continue;
            }
            let i = this[e];
            if (i === void 0) {
                console.warn(`THREE.Material: '${e}' is not a property of THREE.${this.type}.`);
                continue;
            }
            i && i.isColor ? i.set(n) : i && i.isVector3 && n && n.isVector3 ? i.copy(n) : this[e] = n;
        }
    }
    toJSON(t) {
        let e = t === void 0 || typeof t == "string";
        e && (t = {
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
        n.uuid = this.uuid, n.type = this.type, this.name !== "" && (n.name = this.name), this.color && this.color.isColor && (n.color = this.color.getHex()), this.roughness !== void 0 && (n.roughness = this.roughness), this.metalness !== void 0 && (n.metalness = this.metalness), this.sheen !== void 0 && (n.sheen = this.sheen), this.sheenColor && this.sheenColor.isColor && (n.sheenColor = this.sheenColor.getHex()), this.sheenRoughness !== void 0 && (n.sheenRoughness = this.sheenRoughness), this.emissive && this.emissive.isColor && (n.emissive = this.emissive.getHex()), this.emissiveIntensity && this.emissiveIntensity !== 1 && (n.emissiveIntensity = this.emissiveIntensity), this.specular && this.specular.isColor && (n.specular = this.specular.getHex()), this.specularIntensity !== void 0 && (n.specularIntensity = this.specularIntensity), this.specularColor && this.specularColor.isColor && (n.specularColor = this.specularColor.getHex()), this.shininess !== void 0 && (n.shininess = this.shininess), this.clearcoat !== void 0 && (n.clearcoat = this.clearcoat), this.clearcoatRoughness !== void 0 && (n.clearcoatRoughness = this.clearcoatRoughness), this.clearcoatMap && this.clearcoatMap.isTexture && (n.clearcoatMap = this.clearcoatMap.toJSON(t).uuid), this.clearcoatRoughnessMap && this.clearcoatRoughnessMap.isTexture && (n.clearcoatRoughnessMap = this.clearcoatRoughnessMap.toJSON(t).uuid), this.clearcoatNormalMap && this.clearcoatNormalMap.isTexture && (n.clearcoatNormalMap = this.clearcoatNormalMap.toJSON(t).uuid, n.clearcoatNormalScale = this.clearcoatNormalScale.toArray()), this.iridescence !== void 0 && (n.iridescence = this.iridescence), this.iridescenceIOR !== void 0 && (n.iridescenceIOR = this.iridescenceIOR), this.iridescenceThicknessRange !== void 0 && (n.iridescenceThicknessRange = this.iridescenceThicknessRange), this.iridescenceMap && this.iridescenceMap.isTexture && (n.iridescenceMap = this.iridescenceMap.toJSON(t).uuid), this.iridescenceThicknessMap && this.iridescenceThicknessMap.isTexture && (n.iridescenceThicknessMap = this.iridescenceThicknessMap.toJSON(t).uuid), this.anisotropy !== void 0 && (n.anisotropy = this.anisotropy), this.anisotropyRotation !== void 0 && (n.anisotropyRotation = this.anisotropyRotation), this.anisotropyMap && this.anisotropyMap.isTexture && (n.anisotropyMap = this.anisotropyMap.toJSON(t).uuid), this.map && this.map.isTexture && (n.map = this.map.toJSON(t).uuid), this.matcap && this.matcap.isTexture && (n.matcap = this.matcap.toJSON(t).uuid), this.alphaMap && this.alphaMap.isTexture && (n.alphaMap = this.alphaMap.toJSON(t).uuid), this.lightMap && this.lightMap.isTexture && (n.lightMap = this.lightMap.toJSON(t).uuid, n.lightMapIntensity = this.lightMapIntensity), this.aoMap && this.aoMap.isTexture && (n.aoMap = this.aoMap.toJSON(t).uuid, n.aoMapIntensity = this.aoMapIntensity), this.bumpMap && this.bumpMap.isTexture && (n.bumpMap = this.bumpMap.toJSON(t).uuid, n.bumpScale = this.bumpScale), this.normalMap && this.normalMap.isTexture && (n.normalMap = this.normalMap.toJSON(t).uuid, n.normalMapType = this.normalMapType, n.normalScale = this.normalScale.toArray()), this.displacementMap && this.displacementMap.isTexture && (n.displacementMap = this.displacementMap.toJSON(t).uuid, n.displacementScale = this.displacementScale, n.displacementBias = this.displacementBias), this.roughnessMap && this.roughnessMap.isTexture && (n.roughnessMap = this.roughnessMap.toJSON(t).uuid), this.metalnessMap && this.metalnessMap.isTexture && (n.metalnessMap = this.metalnessMap.toJSON(t).uuid), this.emissiveMap && this.emissiveMap.isTexture && (n.emissiveMap = this.emissiveMap.toJSON(t).uuid), this.specularMap && this.specularMap.isTexture && (n.specularMap = this.specularMap.toJSON(t).uuid), this.specularIntensityMap && this.specularIntensityMap.isTexture && (n.specularIntensityMap = this.specularIntensityMap.toJSON(t).uuid), this.specularColorMap && this.specularColorMap.isTexture && (n.specularColorMap = this.specularColorMap.toJSON(t).uuid), this.envMap && this.envMap.isTexture && (n.envMap = this.envMap.toJSON(t).uuid, this.combine !== void 0 && (n.combine = this.combine)), this.envMapIntensity !== void 0 && (n.envMapIntensity = this.envMapIntensity), this.reflectivity !== void 0 && (n.reflectivity = this.reflectivity), this.refractionRatio !== void 0 && (n.refractionRatio = this.refractionRatio), this.gradientMap && this.gradientMap.isTexture && (n.gradientMap = this.gradientMap.toJSON(t).uuid), this.transmission !== void 0 && (n.transmission = this.transmission), this.transmissionMap && this.transmissionMap.isTexture && (n.transmissionMap = this.transmissionMap.toJSON(t).uuid), this.thickness !== void 0 && (n.thickness = this.thickness), this.thicknessMap && this.thicknessMap.isTexture && (n.thicknessMap = this.thicknessMap.toJSON(t).uuid), this.attenuationDistance !== void 0 && this.attenuationDistance !== 1 / 0 && (n.attenuationDistance = this.attenuationDistance), this.attenuationColor !== void 0 && (n.attenuationColor = this.attenuationColor.getHex()), this.size !== void 0 && (n.size = this.size), this.shadowSide !== null && (n.shadowSide = this.shadowSide), this.sizeAttenuation !== void 0 && (n.sizeAttenuation = this.sizeAttenuation), this.blending !== Wi && (n.blending = this.blending), this.side !== On && (n.side = this.side), this.vertexColors && (n.vertexColors = !0), this.opacity < 1 && (n.opacity = this.opacity), this.transparent === !0 && (n.transparent = this.transparent), n.depthFunc = this.depthFunc, n.depthTest = this.depthTest, n.depthWrite = this.depthWrite, n.colorWrite = this.colorWrite, n.stencilWrite = this.stencilWrite, n.stencilWriteMask = this.stencilWriteMask, n.stencilFunc = this.stencilFunc, n.stencilRef = this.stencilRef, n.stencilFuncMask = this.stencilFuncMask, n.stencilFail = this.stencilFail, n.stencilZFail = this.stencilZFail, n.stencilZPass = this.stencilZPass, this.rotation !== void 0 && this.rotation !== 0 && (n.rotation = this.rotation), this.polygonOffset === !0 && (n.polygonOffset = !0), this.polygonOffsetFactor !== 0 && (n.polygonOffsetFactor = this.polygonOffsetFactor), this.polygonOffsetUnits !== 0 && (n.polygonOffsetUnits = this.polygonOffsetUnits), this.linewidth !== void 0 && this.linewidth !== 1 && (n.linewidth = this.linewidth), this.dashSize !== void 0 && (n.dashSize = this.dashSize), this.gapSize !== void 0 && (n.gapSize = this.gapSize), this.scale !== void 0 && (n.scale = this.scale), this.dithering === !0 && (n.dithering = !0), this.alphaTest > 0 && (n.alphaTest = this.alphaTest), this.alphaHash === !0 && (n.alphaHash = this.alphaHash), this.alphaToCoverage === !0 && (n.alphaToCoverage = this.alphaToCoverage), this.premultipliedAlpha === !0 && (n.premultipliedAlpha = this.premultipliedAlpha), this.forceSinglePass === !0 && (n.forceSinglePass = this.forceSinglePass), this.wireframe === !0 && (n.wireframe = this.wireframe), this.wireframeLinewidth > 1 && (n.wireframeLinewidth = this.wireframeLinewidth), this.wireframeLinecap !== "round" && (n.wireframeLinecap = this.wireframeLinecap), this.wireframeLinejoin !== "round" && (n.wireframeLinejoin = this.wireframeLinejoin), this.flatShading === !0 && (n.flatShading = this.flatShading), this.visible === !1 && (n.visible = !1), this.toneMapped === !1 && (n.toneMapped = !1), this.fog === !1 && (n.fog = !1), Object.keys(this.userData).length > 0 && (n.userData = this.userData);
        function i(r) {
            let a = [];
            for(let o in r){
                let c = r[o];
                delete c.metadata, a.push(c);
            }
            return a;
        }
        if (e) {
            let r = i(t.textures), a = i(t.images);
            r.length > 0 && (n.textures = r), a.length > 0 && (n.images = a);
        }
        return n;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        this.name = t.name, this.blending = t.blending, this.side = t.side, this.vertexColors = t.vertexColors, this.opacity = t.opacity, this.transparent = t.transparent, this.blendSrc = t.blendSrc, this.blendDst = t.blendDst, this.blendEquation = t.blendEquation, this.blendSrcAlpha = t.blendSrcAlpha, this.blendDstAlpha = t.blendDstAlpha, this.blendEquationAlpha = t.blendEquationAlpha, this.depthFunc = t.depthFunc, this.depthTest = t.depthTest, this.depthWrite = t.depthWrite, this.stencilWriteMask = t.stencilWriteMask, this.stencilFunc = t.stencilFunc, this.stencilRef = t.stencilRef, this.stencilFuncMask = t.stencilFuncMask, this.stencilFail = t.stencilFail, this.stencilZFail = t.stencilZFail, this.stencilZPass = t.stencilZPass, this.stencilWrite = t.stencilWrite;
        let e = t.clippingPlanes, n = null;
        if (e !== null) {
            let i = e.length;
            n = new Array(i);
            for(let r = 0; r !== i; ++r)n[r] = e[r].clone();
        }
        return this.clippingPlanes = n, this.clipIntersection = t.clipIntersection, this.clipShadows = t.clipShadows, this.shadowSide = t.shadowSide, this.colorWrite = t.colorWrite, this.precision = t.precision, this.polygonOffset = t.polygonOffset, this.polygonOffsetFactor = t.polygonOffsetFactor, this.polygonOffsetUnits = t.polygonOffsetUnits, this.dithering = t.dithering, this.alphaTest = t.alphaTest, this.alphaHash = t.alphaHash, this.alphaToCoverage = t.alphaToCoverage, this.premultipliedAlpha = t.premultipliedAlpha, this.forceSinglePass = t.forceSinglePass, this.visible = t.visible, this.toneMapped = t.toneMapped, this.userData = JSON.parse(JSON.stringify(t.userData)), this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
    set needsUpdate(t) {
        t === !0 && this.version++;
    }
}, _d = {
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
}, $e = {
    h: 0,
    s: 0,
    l: 0
}, Qs = {
    h: 0,
    s: 0,
    l: 0
};
function Va(s1, t, e) {
    return e < 0 && (e += 1), e > 1 && (e -= 1), e < 1 / 6 ? s1 + (t - s1) * 6 * e : e < 1 / 2 ? t : e < 2 / 3 ? s1 + (t - s1) * 6 * (2 / 3 - e) : s1;
}
var ft = class {
    constructor(t, e, n){
        return this.isColor = !0, this.r = 1, this.g = 1, this.b = 1, this.set(t, e, n);
    }
    set(t, e, n) {
        if (e === void 0 && n === void 0) {
            let i = t;
            i && i.isColor ? this.copy(i) : typeof i == "number" ? this.setHex(i) : typeof i == "string" && this.setStyle(i);
        } else this.setRGB(t, e, n);
        return this;
    }
    setScalar(t) {
        return this.r = t, this.g = t, this.b = t, this;
    }
    setHex(t, e = Nt) {
        return t = Math.floor(t), this.r = (t >> 16 & 255) / 255, this.g = (t >> 8 & 255) / 255, this.b = (t & 255) / 255, Ye.toWorkingColorSpace(this, e), this;
    }
    setRGB(t, e, n, i = Ye.workingColorSpace) {
        return this.r = t, this.g = e, this.b = n, Ye.toWorkingColorSpace(this, i), this;
    }
    setHSL(t, e, n, i = Ye.workingColorSpace) {
        if (t = kc(t, 1), e = ae(e, 0, 1), n = ae(n, 0, 1), e === 0) this.r = this.g = this.b = n;
        else {
            let r = n <= .5 ? n * (1 + e) : n + e - n * e, a = 2 * n - r;
            this.r = Va(a, r, t + 1 / 3), this.g = Va(a, r, t), this.b = Va(a, r, t - 1 / 3);
        }
        return Ye.toWorkingColorSpace(this, i), this;
    }
    setStyle(t, e = Nt) {
        function n(r) {
            r !== void 0 && parseFloat(r) < 1 && console.warn("THREE.Color: Alpha component of " + t + " will be ignored.");
        }
        let i;
        if (i = /^(\w+)\(([^\)]*)\)/.exec(t)) {
            let r, a = i[1], o = i[2];
            switch(a){
                case "rgb":
                case "rgba":
                    if (r = /^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return n(r[4]), this.setRGB(Math.min(255, parseInt(r[1], 10)) / 255, Math.min(255, parseInt(r[2], 10)) / 255, Math.min(255, parseInt(r[3], 10)) / 255, e);
                    if (r = /^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return n(r[4]), this.setRGB(Math.min(100, parseInt(r[1], 10)) / 100, Math.min(100, parseInt(r[2], 10)) / 100, Math.min(100, parseInt(r[3], 10)) / 100, e);
                    break;
                case "hsl":
                case "hsla":
                    if (r = /^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o)) return n(r[4]), this.setHSL(parseFloat(r[1]) / 360, parseFloat(r[2]) / 100, parseFloat(r[3]) / 100, e);
                    break;
                default:
                    console.warn("THREE.Color: Unknown color model " + t);
            }
        } else if (i = /^\#([A-Fa-f\d]+)$/.exec(t)) {
            let r = i[1], a = r.length;
            if (a === 3) return this.setRGB(parseInt(r.charAt(0), 16) / 15, parseInt(r.charAt(1), 16) / 15, parseInt(r.charAt(2), 16) / 15, e);
            if (a === 6) return this.setHex(parseInt(r, 16), e);
            console.warn("THREE.Color: Invalid hex color " + t);
        } else if (t && t.length > 0) return this.setColorName(t, e);
        return this;
    }
    setColorName(t, e = Nt) {
        let n = _d[t.toLowerCase()];
        return n !== void 0 ? this.setHex(n, e) : console.warn("THREE.Color: Unknown color " + t), this;
    }
    clone() {
        return new this.constructor(this.r, this.g, this.b);
    }
    copy(t) {
        return this.r = t.r, this.g = t.g, this.b = t.b, this;
    }
    copySRGBToLinear(t) {
        return this.r = Xi(t.r), this.g = Xi(t.g), this.b = Xi(t.b), this;
    }
    copyLinearToSRGB(t) {
        return this.r = Ca(t.r), this.g = Ca(t.g), this.b = Ca(t.b), this;
    }
    convertSRGBToLinear() {
        return this.copySRGBToLinear(this), this;
    }
    convertLinearToSRGB() {
        return this.copyLinearToSRGB(this), this;
    }
    getHex(t = Nt) {
        return Ye.fromWorkingColorSpace(be.copy(this), t), Math.round(ae(be.r * 255, 0, 255)) * 65536 + Math.round(ae(be.g * 255, 0, 255)) * 256 + Math.round(ae(be.b * 255, 0, 255));
    }
    getHexString(t = Nt) {
        return ("000000" + this.getHex(t).toString(16)).slice(-6);
    }
    getHSL(t, e = Ye.workingColorSpace) {
        Ye.fromWorkingColorSpace(be.copy(this), e);
        let n = be.r, i = be.g, r = be.b, a = Math.max(n, i, r), o = Math.min(n, i, r), c, l, h = (o + a) / 2;
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
        return t.h = c, t.s = l, t.l = h, t;
    }
    getRGB(t, e = Ye.workingColorSpace) {
        return Ye.fromWorkingColorSpace(be.copy(this), e), t.r = be.r, t.g = be.g, t.b = be.b, t;
    }
    getStyle(t = Nt) {
        Ye.fromWorkingColorSpace(be.copy(this), t);
        let e = be.r, n = be.g, i = be.b;
        return t !== Nt ? `color(${t} ${e.toFixed(3)} ${n.toFixed(3)} ${i.toFixed(3)})` : `rgb(${Math.round(e * 255)},${Math.round(n * 255)},${Math.round(i * 255)})`;
    }
    offsetHSL(t, e, n) {
        return this.getHSL($e), $e.h += t, $e.s += e, $e.l += n, this.setHSL($e.h, $e.s, $e.l), this;
    }
    add(t) {
        return this.r += t.r, this.g += t.g, this.b += t.b, this;
    }
    addColors(t, e) {
        return this.r = t.r + e.r, this.g = t.g + e.g, this.b = t.b + e.b, this;
    }
    addScalar(t) {
        return this.r += t, this.g += t, this.b += t, this;
    }
    sub(t) {
        return this.r = Math.max(0, this.r - t.r), this.g = Math.max(0, this.g - t.g), this.b = Math.max(0, this.b - t.b), this;
    }
    multiply(t) {
        return this.r *= t.r, this.g *= t.g, this.b *= t.b, this;
    }
    multiplyScalar(t) {
        return this.r *= t, this.g *= t, this.b *= t, this;
    }
    lerp(t, e) {
        return this.r += (t.r - this.r) * e, this.g += (t.g - this.g) * e, this.b += (t.b - this.b) * e, this;
    }
    lerpColors(t, e, n) {
        return this.r = t.r + (e.r - t.r) * n, this.g = t.g + (e.g - t.g) * n, this.b = t.b + (e.b - t.b) * n, this;
    }
    lerpHSL(t, e) {
        this.getHSL($e), t.getHSL(Qs);
        let n = ys($e.h, Qs.h, e), i = ys($e.s, Qs.s, e), r = ys($e.l, Qs.l, e);
        return this.setHSL(n, i, r), this;
    }
    setFromVector3(t) {
        return this.r = t.x, this.g = t.y, this.b = t.z, this;
    }
    applyMatrix3(t) {
        let e = this.r, n = this.g, i = this.b, r = t.elements;
        return this.r = r[0] * e + r[3] * n + r[6] * i, this.g = r[1] * e + r[4] * n + r[7] * i, this.b = r[2] * e + r[5] * n + r[8] * i, this;
    }
    equals(t) {
        return t.r === this.r && t.g === this.g && t.b === this.b;
    }
    fromArray(t, e = 0) {
        return this.r = t[e], this.g = t[e + 1], this.b = t[e + 2], this;
    }
    toArray(t = [], e = 0) {
        return t[e] = this.r, t[e + 1] = this.g, t[e + 2] = this.b, t;
    }
    fromBufferAttribute(t, e) {
        return this.r = t.getX(e), this.g = t.getY(e), this.b = t.getZ(e), this;
    }
    toJSON() {
        return this.getHex();
    }
    *[Symbol.iterator]() {
        yield this.r, yield this.g, yield this.b;
    }
}, be = new ft;
ft.NAMES = _d;
var Mn = class extends Me {
    constructor(t){
        super(), this.isMeshBasicMaterial = !0, this.type = "MeshBasicMaterial", this.color = new ft(16777215), this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = pa, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.map = t.map, this.lightMap = t.lightMap, this.lightMapIntensity = t.lightMapIntensity, this.aoMap = t.aoMap, this.aoMapIntensity = t.aoMapIntensity, this.specularMap = t.specularMap, this.alphaMap = t.alphaMap, this.envMap = t.envMap, this.combine = t.combine, this.reflectivity = t.reflectivity, this.refractionRatio = t.refractionRatio, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.wireframeLinecap = t.wireframeLinecap, this.wireframeLinejoin = t.wireframeLinejoin, this.fog = t.fog, this;
    }
}, _n = up();
function up() {
    let s1 = new ArrayBuffer(4), t = new Float32Array(s1), e = new Uint32Array(s1), n = new Uint32Array(512), i = new Uint32Array(512);
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
        floatView: t,
        uint32View: e,
        baseTable: n,
        shiftTable: i,
        mantissaTable: r,
        exponentTable: a,
        offsetTable: o
    };
}
function Ie(s1) {
    Math.abs(s1) > 65504 && console.warn("THREE.DataUtils.toHalfFloat(): Value out of range."), s1 = ae(s1, -65504, 65504), _n.floatView[0] = s1;
    let t = _n.uint32View[0], e = t >> 23 & 511;
    return _n.baseTable[e] + ((t & 8388607) >> _n.shiftTable[e]);
}
function xs(s1) {
    let t = s1 >> 10;
    return _n.uint32View[0] = _n.mantissaTable[_n.offsetTable[t] + (s1 & 1023)] + _n.exponentTable[t], _n.floatView[0];
}
var vv = {
    toHalfFloat: Ie,
    fromHalfFloat: xs
}, de = new A, js = new J, Kt = class {
    constructor(t, e, n = !1){
        if (Array.isArray(t)) throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
        this.isBufferAttribute = !0, this.name = "", this.array = t, this.itemSize = e, this.count = t !== void 0 ? t.length / e : 0, this.normalized = n, this.usage = kr, this.updateRange = {
            offset: 0,
            count: -1
        }, this.gpuType = xn, this.version = 0;
    }
    onUploadCallback() {}
    set needsUpdate(t) {
        t === !0 && this.version++;
    }
    setUsage(t) {
        return this.usage = t, this;
    }
    copy(t) {
        return this.name = t.name, this.array = new t.array.constructor(t.array), this.itemSize = t.itemSize, this.count = t.count, this.normalized = t.normalized, this.usage = t.usage, this.gpuType = t.gpuType, this;
    }
    copyAt(t, e, n) {
        t *= this.itemSize, n *= e.itemSize;
        for(let i = 0, r = this.itemSize; i < r; i++)this.array[t + i] = e.array[n + i];
        return this;
    }
    copyArray(t) {
        return this.array.set(t), this;
    }
    applyMatrix3(t) {
        if (this.itemSize === 2) for(let e = 0, n = this.count; e < n; e++)js.fromBufferAttribute(this, e), js.applyMatrix3(t), this.setXY(e, js.x, js.y);
        else if (this.itemSize === 3) for(let e = 0, n = this.count; e < n; e++)de.fromBufferAttribute(this, e), de.applyMatrix3(t), this.setXYZ(e, de.x, de.y, de.z);
        return this;
    }
    applyMatrix4(t) {
        for(let e = 0, n = this.count; e < n; e++)de.fromBufferAttribute(this, e), de.applyMatrix4(t), this.setXYZ(e, de.x, de.y, de.z);
        return this;
    }
    applyNormalMatrix(t) {
        for(let e = 0, n = this.count; e < n; e++)de.fromBufferAttribute(this, e), de.applyNormalMatrix(t), this.setXYZ(e, de.x, de.y, de.z);
        return this;
    }
    transformDirection(t) {
        for(let e = 0, n = this.count; e < n; e++)de.fromBufferAttribute(this, e), de.transformDirection(t), this.setXYZ(e, de.x, de.y, de.z);
        return this;
    }
    set(t, e = 0) {
        return this.array.set(t, e), this;
    }
    getComponent(t, e) {
        let n = this.array[t * this.itemSize + e];
        return this.normalized && (n = Ue(n, this.array)), n;
    }
    setComponent(t, e, n) {
        return this.normalized && (n = Ft(n, this.array)), this.array[t * this.itemSize + e] = n, this;
    }
    getX(t) {
        let e = this.array[t * this.itemSize];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setX(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize] = e, this;
    }
    getY(t) {
        let e = this.array[t * this.itemSize + 1];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setY(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize + 1] = e, this;
    }
    getZ(t) {
        let e = this.array[t * this.itemSize + 2];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setZ(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize + 2] = e, this;
    }
    getW(t) {
        let e = this.array[t * this.itemSize + 3];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setW(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize + 3] = e, this;
    }
    setXY(t, e, n) {
        return t *= this.itemSize, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array)), this.array[t + 0] = e, this.array[t + 1] = n, this;
    }
    setXYZ(t, e, n, i) {
        return t *= this.itemSize, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array), i = Ft(i, this.array)), this.array[t + 0] = e, this.array[t + 1] = n, this.array[t + 2] = i, this;
    }
    setXYZW(t, e, n, i, r) {
        return t *= this.itemSize, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array), i = Ft(i, this.array), r = Ft(r, this.array)), this.array[t + 0] = e, this.array[t + 1] = n, this.array[t + 2] = i, this.array[t + 3] = r, this;
    }
    onUpload(t) {
        return this.onUploadCallback = t, this;
    }
    clone() {
        return new this.constructor(this.array, this.itemSize).copy(this);
    }
    toJSON() {
        let t = {
            itemSize: this.itemSize,
            type: this.array.constructor.name,
            array: Array.from(this.array),
            normalized: this.normalized
        };
        return this.name !== "" && (t.name = this.name), this.usage !== kr && (t.usage = this.usage), (this.updateRange.offset !== 0 || this.updateRange.count !== -1) && (t.updateRange = this.updateRange), t;
    }
}, Wl = class extends Kt {
    constructor(t, e, n){
        super(new Int8Array(t), e, n);
    }
}, Xl = class extends Kt {
    constructor(t, e, n){
        super(new Uint8Array(t), e, n);
    }
}, ql = class extends Kt {
    constructor(t, e, n){
        super(new Uint8ClampedArray(t), e, n);
    }
}, Yl = class extends Kt {
    constructor(t, e, n){
        super(new Int16Array(t), e, n);
    }
}, qr = class extends Kt {
    constructor(t, e, n){
        super(new Uint16Array(t), e, n);
    }
}, Zl = class extends Kt {
    constructor(t, e, n){
        super(new Int32Array(t), e, n);
    }
}, Yr = class extends Kt {
    constructor(t, e, n){
        super(new Uint32Array(t), e, n);
    }
}, Jl = class extends Kt {
    constructor(t, e, n){
        super(new Uint16Array(t), e, n), this.isFloat16BufferAttribute = !0;
    }
    getX(t) {
        let e = xs(this.array[t * this.itemSize]);
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setX(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize] = Ie(e), this;
    }
    getY(t) {
        let e = xs(this.array[t * this.itemSize + 1]);
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setY(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize + 1] = Ie(e), this;
    }
    getZ(t) {
        let e = xs(this.array[t * this.itemSize + 2]);
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setZ(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize + 2] = Ie(e), this;
    }
    getW(t) {
        let e = xs(this.array[t * this.itemSize + 3]);
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setW(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.array[t * this.itemSize + 3] = Ie(e), this;
    }
    setXY(t, e, n) {
        return t *= this.itemSize, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array)), this.array[t + 0] = Ie(e), this.array[t + 1] = Ie(n), this;
    }
    setXYZ(t, e, n, i) {
        return t *= this.itemSize, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array), i = Ft(i, this.array)), this.array[t + 0] = Ie(e), this.array[t + 1] = Ie(n), this.array[t + 2] = Ie(i), this;
    }
    setXYZW(t, e, n, i, r) {
        return t *= this.itemSize, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array), i = Ft(i, this.array), r = Ft(r, this.array)), this.array[t + 0] = Ie(e), this.array[t + 1] = Ie(n), this.array[t + 2] = Ie(i), this.array[t + 3] = Ie(r), this;
    }
}, _t = class extends Kt {
    constructor(t, e, n){
        super(new Float32Array(t), e, n);
    }
}, $l = class extends Kt {
    constructor(t, e, n){
        super(new Float64Array(t), e, n);
    }
}, dp = 0, ke = new Ot, Ha = new Zt, Ti = new A, Oe = new Ke, us = new Ke, _e = new A, Vt = class s1 extends sn {
    constructor(){
        super(), this.isBufferGeometry = !0, Object.defineProperty(this, "id", {
            value: dp++
        }), this.uuid = Be(), this.name = "", this.type = "BufferGeometry", this.index = null, this.attributes = {}, this.morphAttributes = {}, this.morphTargetsRelative = !1, this.groups = [], this.boundingBox = null, this.boundingSphere = null, this.drawRange = {
            start: 0,
            count: 1 / 0
        }, this.userData = {};
    }
    getIndex() {
        return this.index;
    }
    setIndex(t) {
        return Array.isArray(t) ? this.index = new (gd(t) ? Yr : qr)(t, 1) : this.index = t, this;
    }
    getAttribute(t) {
        return this.attributes[t];
    }
    setAttribute(t, e) {
        return this.attributes[t] = e, this;
    }
    deleteAttribute(t) {
        return delete this.attributes[t], this;
    }
    hasAttribute(t) {
        return this.attributes[t] !== void 0;
    }
    addGroup(t, e, n = 0) {
        this.groups.push({
            start: t,
            count: e,
            materialIndex: n
        });
    }
    clearGroups() {
        this.groups = [];
    }
    setDrawRange(t, e) {
        this.drawRange.start = t, this.drawRange.count = e;
    }
    applyMatrix4(t) {
        let e = this.attributes.position;
        e !== void 0 && (e.applyMatrix4(t), e.needsUpdate = !0);
        let n = this.attributes.normal;
        if (n !== void 0) {
            let r = new kt().getNormalMatrix(t);
            n.applyNormalMatrix(r), n.needsUpdate = !0;
        }
        let i = this.attributes.tangent;
        return i !== void 0 && (i.transformDirection(t), i.needsUpdate = !0), this.boundingBox !== null && this.computeBoundingBox(), this.boundingSphere !== null && this.computeBoundingSphere(), this;
    }
    applyQuaternion(t) {
        return ke.makeRotationFromQuaternion(t), this.applyMatrix4(ke), this;
    }
    rotateX(t) {
        return ke.makeRotationX(t), this.applyMatrix4(ke), this;
    }
    rotateY(t) {
        return ke.makeRotationY(t), this.applyMatrix4(ke), this;
    }
    rotateZ(t) {
        return ke.makeRotationZ(t), this.applyMatrix4(ke), this;
    }
    translate(t, e, n) {
        return ke.makeTranslation(t, e, n), this.applyMatrix4(ke), this;
    }
    scale(t, e, n) {
        return ke.makeScale(t, e, n), this.applyMatrix4(ke), this;
    }
    lookAt(t) {
        return Ha.lookAt(t), Ha.updateMatrix(), this.applyMatrix4(Ha.matrix), this;
    }
    center() {
        return this.computeBoundingBox(), this.boundingBox.getCenter(Ti).negate(), this.translate(Ti.x, Ti.y, Ti.z), this;
    }
    setFromPoints(t) {
        let e = [];
        for(let n = 0, i = t.length; n < i; n++){
            let r = t[n];
            e.push(r.x, r.y, r.z || 0);
        }
        return this.setAttribute("position", new _t(e, 3)), this;
    }
    computeBoundingBox() {
        this.boundingBox === null && (this.boundingBox = new Ke);
        let t = this.attributes.position, e = this.morphAttributes.position;
        if (t && t.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box. Alternatively set "mesh.frustumCulled" to "false".', this), this.boundingBox.set(new A(-1 / 0, -1 / 0, -1 / 0), new A(1 / 0, 1 / 0, 1 / 0));
            return;
        }
        if (t !== void 0) {
            if (this.boundingBox.setFromBufferAttribute(t), e) for(let n = 0, i = e.length; n < i; n++){
                let r = e[n];
                Oe.setFromBufferAttribute(r), this.morphTargetsRelative ? (_e.addVectors(this.boundingBox.min, Oe.min), this.boundingBox.expandByPoint(_e), _e.addVectors(this.boundingBox.max, Oe.max), this.boundingBox.expandByPoint(_e)) : (this.boundingBox.expandByPoint(Oe.min), this.boundingBox.expandByPoint(Oe.max));
            }
        } else this.boundingBox.makeEmpty();
        (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) && console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
    computeBoundingSphere() {
        this.boundingSphere === null && (this.boundingSphere = new We);
        let t = this.attributes.position, e = this.morphAttributes.position;
        if (t && t.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere. Alternatively set "mesh.frustumCulled" to "false".', this), this.boundingSphere.set(new A, 1 / 0);
            return;
        }
        if (t) {
            let n = this.boundingSphere.center;
            if (Oe.setFromBufferAttribute(t), e) for(let r = 0, a = e.length; r < a; r++){
                let o = e[r];
                us.setFromBufferAttribute(o), this.morphTargetsRelative ? (_e.addVectors(Oe.min, us.min), Oe.expandByPoint(_e), _e.addVectors(Oe.max, us.max), Oe.expandByPoint(_e)) : (Oe.expandByPoint(us.min), Oe.expandByPoint(us.max));
            }
            Oe.getCenter(n);
            let i = 0;
            for(let r = 0, a = t.count; r < a; r++)_e.fromBufferAttribute(t, r), i = Math.max(i, n.distanceToSquared(_e));
            if (e) for(let r = 0, a = e.length; r < a; r++){
                let o = e[r], c = this.morphTargetsRelative;
                for(let l = 0, h = o.count; l < h; l++)_e.fromBufferAttribute(o, l), c && (Ti.fromBufferAttribute(t, l), _e.add(Ti)), i = Math.max(i, n.distanceToSquared(_e));
            }
            this.boundingSphere.radius = Math.sqrt(i), isNaN(this.boundingSphere.radius) && console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
        }
    }
    computeTangents() {
        let t = this.index, e = this.attributes;
        if (t === null || e.position === void 0 || e.normal === void 0 || e.uv === void 0) {
            console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");
            return;
        }
        let n = t.array, i = e.position.array, r = e.normal.array, a = e.uv.array, o = i.length / 3;
        this.hasAttribute("tangent") === !1 && this.setAttribute("tangent", new Kt(new Float32Array(4 * o), 4));
        let c = this.getAttribute("tangent").array, l = [], h = [];
        for(let E = 0; E < o; E++)l[E] = new A, h[E] = new A;
        let u = new A, d = new A, f = new A, m = new J, x = new J, g = new J, p = new A, v = new A;
        function _(E, V, $) {
            u.fromArray(i, E * 3), d.fromArray(i, V * 3), f.fromArray(i, $ * 3), m.fromArray(a, E * 2), x.fromArray(a, V * 2), g.fromArray(a, $ * 2), d.sub(u), f.sub(u), x.sub(m), g.sub(m);
            let F = 1 / (x.x * g.y - g.x * x.y);
            isFinite(F) && (p.copy(d).multiplyScalar(g.y).addScaledVector(f, -x.y).multiplyScalar(F), v.copy(f).multiplyScalar(x.x).addScaledVector(d, -g.x).multiplyScalar(F), l[E].add(p), l[V].add(p), l[$].add(p), h[E].add(v), h[V].add(v), h[$].add(v));
        }
        let y = this.groups;
        y.length === 0 && (y = [
            {
                start: 0,
                count: n.length
            }
        ]);
        for(let E = 0, V = y.length; E < V; ++E){
            let $ = y[E], F = $.start, O = $.count;
            for(let z = F, K = F + O; z < K; z += 3)_(n[z + 0], n[z + 1], n[z + 2]);
        }
        let b = new A, w = new A, R = new A, L = new A;
        function M(E) {
            R.fromArray(r, E * 3), L.copy(R);
            let V = l[E];
            b.copy(V), b.sub(R.multiplyScalar(R.dot(V))).normalize(), w.crossVectors(L, V);
            let F = w.dot(h[E]) < 0 ? -1 : 1;
            c[E * 4] = b.x, c[E * 4 + 1] = b.y, c[E * 4 + 2] = b.z, c[E * 4 + 3] = F;
        }
        for(let E = 0, V = y.length; E < V; ++E){
            let $ = y[E], F = $.start, O = $.count;
            for(let z = F, K = F + O; z < K; z += 3)M(n[z + 0]), M(n[z + 1]), M(n[z + 2]);
        }
    }
    computeVertexNormals() {
        let t = this.index, e = this.getAttribute("position");
        if (e !== void 0) {
            let n = this.getAttribute("normal");
            if (n === void 0) n = new Kt(new Float32Array(e.count * 3), 3), this.setAttribute("normal", n);
            else for(let d = 0, f = n.count; d < f; d++)n.setXYZ(d, 0, 0, 0);
            let i = new A, r = new A, a = new A, o = new A, c = new A, l = new A, h = new A, u = new A;
            if (t) for(let d = 0, f = t.count; d < f; d += 3){
                let m = t.getX(d + 0), x = t.getX(d + 1), g = t.getX(d + 2);
                i.fromBufferAttribute(e, m), r.fromBufferAttribute(e, x), a.fromBufferAttribute(e, g), h.subVectors(a, r), u.subVectors(i, r), h.cross(u), o.fromBufferAttribute(n, m), c.fromBufferAttribute(n, x), l.fromBufferAttribute(n, g), o.add(h), c.add(h), l.add(h), n.setXYZ(m, o.x, o.y, o.z), n.setXYZ(x, c.x, c.y, c.z), n.setXYZ(g, l.x, l.y, l.z);
            }
            else for(let d = 0, f = e.count; d < f; d += 3)i.fromBufferAttribute(e, d + 0), r.fromBufferAttribute(e, d + 1), a.fromBufferAttribute(e, d + 2), h.subVectors(a, r), u.subVectors(i, r), h.cross(u), n.setXYZ(d + 0, h.x, h.y, h.z), n.setXYZ(d + 1, h.x, h.y, h.z), n.setXYZ(d + 2, h.x, h.y, h.z);
            this.normalizeNormals(), n.needsUpdate = !0;
        }
    }
    normalizeNormals() {
        let t = this.attributes.normal;
        for(let e = 0, n = t.count; e < n; e++)_e.fromBufferAttribute(t, e), _e.normalize(), t.setXYZ(e, _e.x, _e.y, _e.z);
    }
    toNonIndexed() {
        function t(o, c) {
            let l = o.array, h = o.itemSize, u = o.normalized, d = new l.constructor(c.length * h), f = 0, m = 0;
            for(let x = 0, g = c.length; x < g; x++){
                o.isInterleavedBufferAttribute ? f = c[x] * o.data.stride + o.offset : f = c[x] * h;
                for(let p = 0; p < h; p++)d[m++] = l[f++];
            }
            return new Kt(d, h, u);
        }
        if (this.index === null) return console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."), this;
        let e = new s1, n = this.index.array, i = this.attributes;
        for(let o in i){
            let c = i[o], l = t(c, n);
            e.setAttribute(o, l);
        }
        let r = this.morphAttributes;
        for(let o in r){
            let c = [], l = r[o];
            for(let h = 0, u = l.length; h < u; h++){
                let d = l[h], f = t(d, n);
                c.push(f);
            }
            e.morphAttributes[o] = c;
        }
        e.morphTargetsRelative = this.morphTargetsRelative;
        let a = this.groups;
        for(let o = 0, c = a.length; o < c; o++){
            let l = a[o];
            e.addGroup(l.start, l.count, l.materialIndex);
        }
        return e;
    }
    toJSON() {
        let t = {
            metadata: {
                version: 4.6,
                type: "BufferGeometry",
                generator: "BufferGeometry.toJSON"
            }
        };
        if (t.uuid = this.uuid, t.type = this.type, this.name !== "" && (t.name = this.name), Object.keys(this.userData).length > 0 && (t.userData = this.userData), this.parameters !== void 0) {
            let c = this.parameters;
            for(let l in c)c[l] !== void 0 && (t[l] = c[l]);
            return t;
        }
        t.data = {
            attributes: {}
        };
        let e = this.index;
        e !== null && (t.data.index = {
            type: e.array.constructor.name,
            array: Array.prototype.slice.call(e.array)
        });
        let n = this.attributes;
        for(let c in n){
            let l = n[c];
            t.data.attributes[c] = l.toJSON(t.data);
        }
        let i = {}, r = !1;
        for(let c in this.morphAttributes){
            let l = this.morphAttributes[c], h = [];
            for(let u = 0, d = l.length; u < d; u++){
                let f = l[u];
                h.push(f.toJSON(t.data));
            }
            h.length > 0 && (i[c] = h, r = !0);
        }
        r && (t.data.morphAttributes = i, t.data.morphTargetsRelative = this.morphTargetsRelative);
        let a = this.groups;
        a.length > 0 && (t.data.groups = JSON.parse(JSON.stringify(a)));
        let o = this.boundingSphere;
        return o !== null && (t.data.boundingSphere = {
            center: o.center.toArray(),
            radius: o.radius
        }), t;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        this.index = null, this.attributes = {}, this.morphAttributes = {}, this.groups = [], this.boundingBox = null, this.boundingSphere = null;
        let e = {};
        this.name = t.name;
        let n = t.index;
        n !== null && this.setIndex(n.clone(e));
        let i = t.attributes;
        for(let l in i){
            let h = i[l];
            this.setAttribute(l, h.clone(e));
        }
        let r = t.morphAttributes;
        for(let l in r){
            let h = [], u = r[l];
            for(let d = 0, f = u.length; d < f; d++)h.push(u[d].clone(e));
            this.morphAttributes[l] = h;
        }
        this.morphTargetsRelative = t.morphTargetsRelative;
        let a = t.groups;
        for(let l = 0, h = a.length; l < h; l++){
            let u = a[l];
            this.addGroup(u.start, u.count, u.materialIndex);
        }
        let o = t.boundingBox;
        o !== null && (this.boundingBox = o.clone());
        let c = t.boundingSphere;
        return c !== null && (this.boundingSphere = c.clone()), this.drawRange.start = t.drawRange.start, this.drawRange.count = t.drawRange.count, this.userData = t.userData, this;
    }
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
}, Kl = new Ot, Xn = new hi, tr = new We, Ql = new A, wi = new A, Ai = new A, Ri = new A, Ga = new A, er = new A, nr = new J, ir = new J, sr = new J, jl = new A, th = new A, eh = new A, rr = new A, ar = new A, ve = class extends Zt {
    constructor(t = new Vt, e = new Mn){
        super(), this.isMesh = !0, this.type = "Mesh", this.geometry = t, this.material = e, this.updateMorphTargets();
    }
    copy(t, e) {
        return super.copy(t, e), t.morphTargetInfluences !== void 0 && (this.morphTargetInfluences = t.morphTargetInfluences.slice()), t.morphTargetDictionary !== void 0 && (this.morphTargetDictionary = Object.assign({}, t.morphTargetDictionary)), this.material = t.material, this.geometry = t.geometry, this;
    }
    updateMorphTargets() {
        let e = this.geometry.morphAttributes, n = Object.keys(e);
        if (n.length > 0) {
            let i = e[n[0]];
            if (i !== void 0) {
                this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                for(let r = 0, a = i.length; r < a; r++){
                    let o = i[r].name || String(r);
                    this.morphTargetInfluences.push(0), this.morphTargetDictionary[o] = r;
                }
            }
        }
    }
    getVertexPosition(t, e) {
        let n = this.geometry, i = n.attributes.position, r = n.morphAttributes.position, a = n.morphTargetsRelative;
        e.fromBufferAttribute(i, t);
        let o = this.morphTargetInfluences;
        if (r && o) {
            er.set(0, 0, 0);
            for(let c = 0, l = r.length; c < l; c++){
                let h = o[c], u = r[c];
                h !== 0 && (Ga.fromBufferAttribute(u, t), a ? er.addScaledVector(Ga, h) : er.addScaledVector(Ga.sub(e), h));
            }
            e.add(er);
        }
        return e;
    }
    raycast(t, e) {
        let n = this.geometry, i = this.material, r = this.matrixWorld;
        i !== void 0 && (n.boundingSphere === null && n.computeBoundingSphere(), tr.copy(n.boundingSphere), tr.applyMatrix4(r), Xn.copy(t.ray).recast(t.near), !(tr.containsPoint(Xn.origin) === !1 && (Xn.intersectSphere(tr, Ql) === null || Xn.origin.distanceToSquared(Ql) > (t.far - t.near) ** 2)) && (Kl.copy(r).invert(), Xn.copy(t.ray).applyMatrix4(Kl), !(n.boundingBox !== null && Xn.intersectsBox(n.boundingBox) === !1) && this._computeIntersections(t, e, Xn)));
    }
    _computeIntersections(t, e, n) {
        let i, r = this.geometry, a = this.material, o = r.index, c = r.attributes.position, l = r.attributes.uv, h = r.attributes.uv1, u = r.attributes.normal, d = r.groups, f = r.drawRange;
        if (o !== null) if (Array.isArray(a)) for(let m = 0, x = d.length; m < x; m++){
            let g = d[m], p = a[g.materialIndex], v = Math.max(g.start, f.start), _ = Math.min(o.count, Math.min(g.start + g.count, f.start + f.count));
            for(let y = v, b = _; y < b; y += 3){
                let w = o.getX(y), R = o.getX(y + 1), L = o.getX(y + 2);
                i = or(this, p, t, n, l, h, u, w, R, L), i && (i.faceIndex = Math.floor(y / 3), i.face.materialIndex = g.materialIndex, e.push(i));
            }
        }
        else {
            let m = Math.max(0, f.start), x = Math.min(o.count, f.start + f.count);
            for(let g = m, p = x; g < p; g += 3){
                let v = o.getX(g), _ = o.getX(g + 1), y = o.getX(g + 2);
                i = or(this, a, t, n, l, h, u, v, _, y), i && (i.faceIndex = Math.floor(g / 3), e.push(i));
            }
        }
        else if (c !== void 0) if (Array.isArray(a)) for(let m = 0, x = d.length; m < x; m++){
            let g = d[m], p = a[g.materialIndex], v = Math.max(g.start, f.start), _ = Math.min(c.count, Math.min(g.start + g.count, f.start + f.count));
            for(let y = v, b = _; y < b; y += 3){
                let w = y, R = y + 1, L = y + 2;
                i = or(this, p, t, n, l, h, u, w, R, L), i && (i.faceIndex = Math.floor(y / 3), i.face.materialIndex = g.materialIndex, e.push(i));
            }
        }
        else {
            let m = Math.max(0, f.start), x = Math.min(c.count, f.start + f.count);
            for(let g = m, p = x; g < p; g += 3){
                let v = g, _ = g + 1, y = g + 2;
                i = or(this, a, t, n, l, h, u, v, _, y), i && (i.faceIndex = Math.floor(g / 3), e.push(i));
            }
        }
    }
};
function fp(s1, t, e, n, i, r, a, o) {
    let c;
    if (t.side === De ? c = n.intersectTriangle(a, r, i, !0, o) : c = n.intersectTriangle(i, r, a, t.side === On, o), c === null) return null;
    ar.copy(o), ar.applyMatrix4(s1.matrixWorld);
    let l = e.ray.origin.distanceTo(ar);
    return l < e.near || l > e.far ? null : {
        distance: l,
        point: ar.clone(),
        object: s1
    };
}
function or(s1, t, e, n, i, r, a, o, c, l) {
    s1.getVertexPosition(o, wi), s1.getVertexPosition(c, Ai), s1.getVertexPosition(l, Ri);
    let h = fp(s1, t, e, n, wi, Ai, Ri, rr);
    if (h) {
        i && (nr.fromBufferAttribute(i, o), ir.fromBufferAttribute(i, c), sr.fromBufferAttribute(i, l), h.uv = In.getInterpolation(rr, wi, Ai, Ri, nr, ir, sr, new J)), r && (nr.fromBufferAttribute(r, o), ir.fromBufferAttribute(r, c), sr.fromBufferAttribute(r, l), h.uv1 = In.getInterpolation(rr, wi, Ai, Ri, nr, ir, sr, new J), h.uv2 = h.uv1), a && (jl.fromBufferAttribute(a, o), th.fromBufferAttribute(a, c), eh.fromBufferAttribute(a, l), h.normal = In.getInterpolation(rr, wi, Ai, Ri, jl, th, eh, new A), h.normal.dot(n.direction) > 0 && h.normal.multiplyScalar(-1));
        let u = {
            a: o,
            b: c,
            c: l,
            normal: new A,
            materialIndex: 0
        };
        In.getNormal(wi, Ai, Ri, u.normal), h.face = u;
    }
    return h;
}
var Ji = class s1 extends Vt {
    constructor(t = 1, e = 1, n = 1, i = 1, r = 1, a = 1){
        super(), this.type = "BoxGeometry", this.parameters = {
            width: t,
            height: e,
            depth: n,
            widthSegments: i,
            heightSegments: r,
            depthSegments: a
        };
        let o = this;
        i = Math.floor(i), r = Math.floor(r), a = Math.floor(a);
        let c = [], l = [], h = [], u = [], d = 0, f = 0;
        m("z", "y", "x", -1, -1, n, e, t, a, r, 0), m("z", "y", "x", 1, -1, n, e, -t, a, r, 1), m("x", "z", "y", 1, 1, t, n, e, i, a, 2), m("x", "z", "y", 1, -1, t, n, -e, i, a, 3), m("x", "y", "z", 1, -1, t, e, n, i, r, 4), m("x", "y", "z", -1, -1, t, e, -n, i, r, 5), this.setIndex(c), this.setAttribute("position", new _t(l, 3)), this.setAttribute("normal", new _t(h, 3)), this.setAttribute("uv", new _t(u, 2));
        function m(x, g, p, v, _, y, b, w, R, L, M) {
            let E = y / R, V = b / L, $ = y / 2, F = b / 2, O = w / 2, z = R + 1, K = L + 1, X = 0, Y = 0, j = new A;
            for(let tt = 0; tt < K; tt++){
                let N = tt * V - F;
                for(let q = 0; q < z; q++){
                    let lt = q * E - $;
                    j[x] = lt * v, j[g] = N * _, j[p] = O, l.push(j.x, j.y, j.z), j[x] = 0, j[g] = 0, j[p] = w > 0 ? 1 : -1, h.push(j.x, j.y, j.z), u.push(q / R), u.push(1 - tt / L), X += 1;
                }
            }
            for(let tt = 0; tt < L; tt++)for(let N = 0; N < R; N++){
                let q = d + N + z * tt, lt = d + N + z * (tt + 1), ut = d + (N + 1) + z * (tt + 1), pt = d + (N + 1) + z * tt;
                c.push(q, lt, pt), c.push(lt, ut, pt), Y += 6;
            }
            o.addGroup(f, Y, M), f += Y, d += X;
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.width, t.height, t.depth, t.widthSegments, t.heightSegments, t.depthSegments);
    }
};
function $i(s1) {
    let t = {};
    for(let e in s1){
        t[e] = {};
        for(let n in s1[e]){
            let i = s1[e][n];
            i && (i.isColor || i.isMatrix3 || i.isMatrix4 || i.isVector2 || i.isVector3 || i.isVector4 || i.isTexture || i.isQuaternion) ? i.isRenderTargetTexture ? (console.warn("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms()."), t[e][n] = null) : t[e][n] = i.clone() : Array.isArray(i) ? t[e][n] = i.slice() : t[e][n] = i;
        }
    }
    return t;
}
function Re(s1) {
    let t = {};
    for(let e = 0; e < s1.length; e++){
        let n = $i(s1[e]);
        for(let i in n)t[i] = n[i];
    }
    return t;
}
function pp(s1) {
    let t = [];
    for(let e = 0; e < s1.length; e++)t.push(s1[e].clone());
    return t;
}
function xd(s1) {
    return s1.getRenderTarget() === null ? s1.outputColorSpace : nn;
}
var mp = {
    clone: $i,
    merge: Re
}, gp = `void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`, _p = `void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`, Qe = class extends Me {
    constructor(t){
        super(), this.isShaderMaterial = !0, this.type = "ShaderMaterial", this.defines = {}, this.uniforms = {}, this.uniformsGroups = [], this.vertexShader = gp, this.fragmentShader = _p, this.linewidth = 1, this.wireframe = !1, this.wireframeLinewidth = 1, this.fog = !1, this.lights = !1, this.clipping = !1, this.forceSinglePass = !0, this.extensions = {
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
        }, this.index0AttributeName = void 0, this.uniformsNeedUpdate = !1, this.glslVersion = null, t !== void 0 && this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.fragmentShader = t.fragmentShader, this.vertexShader = t.vertexShader, this.uniforms = $i(t.uniforms), this.uniformsGroups = pp(t.uniformsGroups), this.defines = Object.assign({}, t.defines), this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.fog = t.fog, this.lights = t.lights, this.clipping = t.clipping, this.extensions = Object.assign({}, t.extensions), this.glslVersion = t.glslVersion, this;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        e.glslVersion = this.glslVersion, e.uniforms = {};
        for(let i in this.uniforms){
            let a = this.uniforms[i].value;
            a && a.isTexture ? e.uniforms[i] = {
                type: "t",
                value: a.toJSON(t).uuid
            } : a && a.isColor ? e.uniforms[i] = {
                type: "c",
                value: a.getHex()
            } : a && a.isVector2 ? e.uniforms[i] = {
                type: "v2",
                value: a.toArray()
            } : a && a.isVector3 ? e.uniforms[i] = {
                type: "v3",
                value: a.toArray()
            } : a && a.isVector4 ? e.uniforms[i] = {
                type: "v4",
                value: a.toArray()
            } : a && a.isMatrix3 ? e.uniforms[i] = {
                type: "m3",
                value: a.toArray()
            } : a && a.isMatrix4 ? e.uniforms[i] = {
                type: "m4",
                value: a.toArray()
            } : e.uniforms[i] = {
                value: a
            };
        }
        Object.keys(this.defines).length > 0 && (e.defines = this.defines), e.vertexShader = this.vertexShader, e.fragmentShader = this.fragmentShader, e.lights = this.lights, e.clipping = this.clipping;
        let n = {};
        for(let i in this.extensions)this.extensions[i] === !0 && (n[i] = !0);
        return Object.keys(n).length > 0 && (e.extensions = n), e;
    }
}, Cs = class extends Zt {
    constructor(){
        super(), this.isCamera = !0, this.type = "Camera", this.matrixWorldInverse = new Ot, this.projectionMatrix = new Ot, this.projectionMatrixInverse = new Ot, this.coordinateSystem = vn;
    }
    copy(t, e) {
        return super.copy(t, e), this.matrixWorldInverse.copy(t.matrixWorldInverse), this.projectionMatrix.copy(t.projectionMatrix), this.projectionMatrixInverse.copy(t.projectionMatrixInverse), this.coordinateSystem = t.coordinateSystem, this;
    }
    getWorldDirection(t) {
        this.updateWorldMatrix(!0, !1);
        let e = this.matrixWorld.elements;
        return t.set(-e[8], -e[9], -e[10]).normalize();
    }
    updateMatrixWorld(t) {
        super.updateMatrixWorld(t), this.matrixWorldInverse.copy(this.matrixWorld).invert();
    }
    updateWorldMatrix(t, e) {
        super.updateWorldMatrix(t, e), this.matrixWorldInverse.copy(this.matrixWorld).invert();
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, xe = class extends Cs {
    constructor(t = 50, e = 1, n = .1, i = 2e3){
        super(), this.isPerspectiveCamera = !0, this.type = "PerspectiveCamera", this.fov = t, this.zoom = 1, this.near = n, this.far = i, this.focus = 10, this.aspect = e, this.view = null, this.filmGauge = 35, this.filmOffset = 0, this.updateProjectionMatrix();
    }
    copy(t, e) {
        return super.copy(t, e), this.fov = t.fov, this.zoom = t.zoom, this.near = t.near, this.far = t.far, this.focus = t.focus, this.aspect = t.aspect, this.view = t.view === null ? null : Object.assign({}, t.view), this.filmGauge = t.filmGauge, this.filmOffset = t.filmOffset, this;
    }
    setFocalLength(t) {
        let e = .5 * this.getFilmHeight() / t;
        this.fov = Zi * 2 * Math.atan(e), this.updateProjectionMatrix();
    }
    getFocalLength() {
        let t = Math.tan(ai * .5 * this.fov);
        return .5 * this.getFilmHeight() / t;
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
    setViewOffset(t, e, n, i, r, a) {
        this.aspect = t / e, this.view === null && (this.view = {
            enabled: !0,
            fullWidth: 1,
            fullHeight: 1,
            offsetX: 0,
            offsetY: 0,
            width: 1,
            height: 1
        }), this.view.enabled = !0, this.view.fullWidth = t, this.view.fullHeight = e, this.view.offsetX = n, this.view.offsetY = i, this.view.width = r, this.view.height = a, this.updateProjectionMatrix();
    }
    clearViewOffset() {
        this.view !== null && (this.view.enabled = !1), this.updateProjectionMatrix();
    }
    updateProjectionMatrix() {
        let t = this.near, e = t * Math.tan(ai * .5 * this.fov) / this.zoom, n = 2 * e, i = this.aspect * n, r = -.5 * i, a = this.view;
        if (this.view !== null && this.view.enabled) {
            let c = a.fullWidth, l = a.fullHeight;
            r += a.offsetX * i / c, e -= a.offsetY * n / l, i *= a.width / c, n *= a.height / l;
        }
        let o = this.filmOffset;
        o !== 0 && (r += t * o / this.getFilmWidth()), this.projectionMatrix.makePerspective(r, r + i, e, e - n, t, this.far, this.coordinateSystem), this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return e.object.fov = this.fov, e.object.zoom = this.zoom, e.object.near = this.near, e.object.far = this.far, e.object.focus = this.focus, e.object.aspect = this.aspect, this.view !== null && (e.object.view = Object.assign({}, this.view)), e.object.filmGauge = this.filmGauge, e.object.filmOffset = this.filmOffset, e;
    }
}, Ci = -90, Pi = 1, uo = class extends Zt {
    constructor(t, e, n){
        super(), this.type = "CubeCamera", this.renderTarget = n, this.coordinateSystem = null;
        let i = new xe(Ci, Pi, t, e);
        i.layers = this.layers, this.add(i);
        let r = new xe(Ci, Pi, t, e);
        r.layers = this.layers, this.add(r);
        let a = new xe(Ci, Pi, t, e);
        a.layers = this.layers, this.add(a);
        let o = new xe(Ci, Pi, t, e);
        o.layers = this.layers, this.add(o);
        let c = new xe(Ci, Pi, t, e);
        c.layers = this.layers, this.add(c);
        let l = new xe(Ci, Pi, t, e);
        l.layers = this.layers, this.add(l);
    }
    updateCoordinateSystem() {
        let t = this.coordinateSystem, e = this.children.concat(), [n, i, r, a, o, c] = e;
        for (let l of e)this.remove(l);
        if (t === vn) n.up.set(0, 1, 0), n.lookAt(1, 0, 0), i.up.set(0, 1, 0), i.lookAt(-1, 0, 0), r.up.set(0, 0, -1), r.lookAt(0, 1, 0), a.up.set(0, 0, 1), a.lookAt(0, -1, 0), o.up.set(0, 1, 0), o.lookAt(0, 0, 1), c.up.set(0, 1, 0), c.lookAt(0, 0, -1);
        else if (t === Vr) n.up.set(0, -1, 0), n.lookAt(-1, 0, 0), i.up.set(0, -1, 0), i.lookAt(1, 0, 0), r.up.set(0, 0, 1), r.lookAt(0, 1, 0), a.up.set(0, 0, -1), a.lookAt(0, -1, 0), o.up.set(0, -1, 0), o.lookAt(0, 0, 1), c.up.set(0, -1, 0), c.lookAt(0, 0, -1);
        else throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: " + t);
        for (let l of e)this.add(l), l.updateMatrixWorld();
    }
    update(t, e) {
        this.parent === null && this.updateMatrixWorld();
        let n = this.renderTarget;
        this.coordinateSystem !== t.coordinateSystem && (this.coordinateSystem = t.coordinateSystem, this.updateCoordinateSystem());
        let [i, r, a, o, c, l] = this.children, h = t.getRenderTarget(), u = t.xr.enabled;
        t.xr.enabled = !1;
        let d = n.texture.generateMipmaps;
        n.texture.generateMipmaps = !1, t.setRenderTarget(n, 0), t.render(e, i), t.setRenderTarget(n, 1), t.render(e, r), t.setRenderTarget(n, 2), t.render(e, a), t.setRenderTarget(n, 3), t.render(e, o), t.setRenderTarget(n, 4), t.render(e, c), n.texture.generateMipmaps = d, t.setRenderTarget(n, 5), t.render(e, l), t.setRenderTarget(h), t.xr.enabled = u, n.texture.needsPMREMUpdate = !0;
    }
}, Ki = class extends ye {
    constructor(t, e, n, i, r, a, o, c, l, h){
        t = t !== void 0 ? t : [], e = e !== void 0 ? e : Bn, super(t, e, n, i, r, a, o, c, l, h), this.isCubeTexture = !0, this.flipY = !1;
    }
    get images() {
        return this.image;
    }
    set images(t) {
        this.image = t;
    }
}, fo = class extends Ge {
    constructor(t = 1, e = {}){
        super(t, t, e), this.isWebGLCubeRenderTarget = !0;
        let n = {
            width: t,
            height: t,
            depth: 1
        }, i = [
            n,
            n,
            n,
            n,
            n,
            n
        ];
        e.encoding !== void 0 && (Ms("THREE.WebGLCubeRenderTarget: option.encoding has been replaced by option.colorSpace."), e.colorSpace = e.encoding === si ? Nt : ri), this.texture = new Ki(i, e.mapping, e.wrapS, e.wrapT, e.magFilter, e.minFilter, e.format, e.type, e.anisotropy, e.colorSpace), this.texture.isRenderTargetTexture = !0, this.texture.generateMipmaps = e.generateMipmaps !== void 0 ? e.generateMipmaps : !1, this.texture.minFilter = e.minFilter !== void 0 ? e.minFilter : pe;
    }
    fromEquirectangularTexture(t, e) {
        this.texture.type = e.type, this.texture.colorSpace = e.colorSpace, this.texture.generateMipmaps = e.generateMipmaps, this.texture.minFilter = e.minFilter, this.texture.magFilter = e.magFilter;
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
        }, i = new Ji(5, 5, 5), r = new Qe({
            name: "CubemapFromEquirect",
            uniforms: $i(n.uniforms),
            vertexShader: n.vertexShader,
            fragmentShader: n.fragmentShader,
            side: De,
            blending: Un
        });
        r.uniforms.tEquirect.value = e;
        let a = new ve(i, r), o = e.minFilter;
        return e.minFilter === li && (e.minFilter = pe), new uo(1, 10, this).update(t, a), e.minFilter = o, a.geometry.dispose(), a.material.dispose(), this;
    }
    clear(t, e, n, i) {
        let r = t.getRenderTarget();
        for(let a = 0; a < 6; a++)t.setRenderTarget(this, a), t.clear(e, n, i);
        t.setRenderTarget(r);
    }
}, Wa = new A, xp = new A, vp = new kt, mn = class {
    constructor(t = new A(1, 0, 0), e = 0){
        this.isPlane = !0, this.normal = t, this.constant = e;
    }
    set(t, e) {
        return this.normal.copy(t), this.constant = e, this;
    }
    setComponents(t, e, n, i) {
        return this.normal.set(t, e, n), this.constant = i, this;
    }
    setFromNormalAndCoplanarPoint(t, e) {
        return this.normal.copy(t), this.constant = -e.dot(this.normal), this;
    }
    setFromCoplanarPoints(t, e, n) {
        let i = Wa.subVectors(n, e).cross(xp.subVectors(t, e)).normalize();
        return this.setFromNormalAndCoplanarPoint(i, t), this;
    }
    copy(t) {
        return this.normal.copy(t.normal), this.constant = t.constant, this;
    }
    normalize() {
        let t = 1 / this.normal.length();
        return this.normal.multiplyScalar(t), this.constant *= t, this;
    }
    negate() {
        return this.constant *= -1, this.normal.negate(), this;
    }
    distanceToPoint(t) {
        return this.normal.dot(t) + this.constant;
    }
    distanceToSphere(t) {
        return this.distanceToPoint(t.center) - t.radius;
    }
    projectPoint(t, e) {
        return e.copy(t).addScaledVector(this.normal, -this.distanceToPoint(t));
    }
    intersectLine(t, e) {
        let n = t.delta(Wa), i = this.normal.dot(n);
        if (i === 0) return this.distanceToPoint(t.start) === 0 ? e.copy(t.start) : null;
        let r = -(t.start.dot(this.normal) + this.constant) / i;
        return r < 0 || r > 1 ? null : e.copy(t.start).addScaledVector(n, r);
    }
    intersectsLine(t) {
        let e = this.distanceToPoint(t.start), n = this.distanceToPoint(t.end);
        return e < 0 && n > 0 || n < 0 && e > 0;
    }
    intersectsBox(t) {
        return t.intersectsPlane(this);
    }
    intersectsSphere(t) {
        return t.intersectsPlane(this);
    }
    coplanarPoint(t) {
        return t.copy(this.normal).multiplyScalar(-this.constant);
    }
    applyMatrix4(t, e) {
        let n = e || vp.getNormalMatrix(t), i = this.coplanarPoint(Wa).applyMatrix4(t), r = this.normal.applyMatrix3(n).normalize();
        return this.constant = -i.dot(r), this;
    }
    translate(t) {
        return this.constant -= t.dot(this.normal), this;
    }
    equals(t) {
        return t.normal.equals(this.normal) && t.constant === this.constant;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, qn = new We, cr = new A, Ps = class {
    constructor(t = new mn, e = new mn, n = new mn, i = new mn, r = new mn, a = new mn){
        this.planes = [
            t,
            e,
            n,
            i,
            r,
            a
        ];
    }
    set(t, e, n, i, r, a) {
        let o = this.planes;
        return o[0].copy(t), o[1].copy(e), o[2].copy(n), o[3].copy(i), o[4].copy(r), o[5].copy(a), this;
    }
    copy(t) {
        let e = this.planes;
        for(let n = 0; n < 6; n++)e[n].copy(t.planes[n]);
        return this;
    }
    setFromProjectionMatrix(t, e = vn) {
        let n = this.planes, i = t.elements, r = i[0], a = i[1], o = i[2], c = i[3], l = i[4], h = i[5], u = i[6], d = i[7], f = i[8], m = i[9], x = i[10], g = i[11], p = i[12], v = i[13], _ = i[14], y = i[15];
        if (n[0].setComponents(c - r, d - l, g - f, y - p).normalize(), n[1].setComponents(c + r, d + l, g + f, y + p).normalize(), n[2].setComponents(c + a, d + h, g + m, y + v).normalize(), n[3].setComponents(c - a, d - h, g - m, y - v).normalize(), n[4].setComponents(c - o, d - u, g - x, y - _).normalize(), e === vn) n[5].setComponents(c + o, d + u, g + x, y + _).normalize();
        else if (e === Vr) n[5].setComponents(o, u, x, _).normalize();
        else throw new Error("THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: " + e);
        return this;
    }
    intersectsObject(t) {
        if (t.boundingSphere !== void 0) t.boundingSphere === null && t.computeBoundingSphere(), qn.copy(t.boundingSphere).applyMatrix4(t.matrixWorld);
        else {
            let e = t.geometry;
            e.boundingSphere === null && e.computeBoundingSphere(), qn.copy(e.boundingSphere).applyMatrix4(t.matrixWorld);
        }
        return this.intersectsSphere(qn);
    }
    intersectsSprite(t) {
        return qn.center.set(0, 0, 0), qn.radius = .7071067811865476, qn.applyMatrix4(t.matrixWorld), this.intersectsSphere(qn);
    }
    intersectsSphere(t) {
        let e = this.planes, n = t.center, i = -t.radius;
        for(let r = 0; r < 6; r++)if (e[r].distanceToPoint(n) < i) return !1;
        return !0;
    }
    intersectsBox(t) {
        let e = this.planes;
        for(let n = 0; n < 6; n++){
            let i = e[n];
            if (cr.x = i.normal.x > 0 ? t.max.x : t.min.x, cr.y = i.normal.y > 0 ? t.max.y : t.min.y, cr.z = i.normal.z > 0 ? t.max.z : t.min.z, i.distanceToPoint(cr) < 0) return !1;
        }
        return !0;
    }
    containsPoint(t) {
        let e = this.planes;
        for(let n = 0; n < 6; n++)if (e[n].distanceToPoint(t) < 0) return !1;
        return !0;
    }
    clone() {
        return new this.constructor().copy(this);
    }
};
function vd() {
    let s1 = null, t = !1, e = null, n = null;
    function i(r, a) {
        e(r, a), n = s1.requestAnimationFrame(i);
    }
    return {
        start: function() {
            t !== !0 && e !== null && (n = s1.requestAnimationFrame(i), t = !0);
        },
        stop: function() {
            s1.cancelAnimationFrame(n), t = !1;
        },
        setAnimationLoop: function(r) {
            e = r;
        },
        setContext: function(r) {
            s1 = r;
        }
    };
}
function yp(s1, t) {
    let e = t.isWebGL2, n = new WeakMap;
    function i(l, h) {
        let u = l.array, d = l.usage, f = s1.createBuffer();
        s1.bindBuffer(h, f), s1.bufferData(h, u, d), l.onUploadCallback();
        let m;
        if (u instanceof Float32Array) m = s1.FLOAT;
        else if (u instanceof Uint16Array) if (l.isFloat16BufferAttribute) if (e) m = s1.HALF_FLOAT;
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
        s1.bindBuffer(u, l), f.count === -1 ? s1.bufferSubData(u, 0, d) : (e ? s1.bufferSubData(u, f.offset * d.BYTES_PER_ELEMENT, d, f.offset, f.count) : s1.bufferSubData(u, f.offset * d.BYTES_PER_ELEMENT, d.subarray(f.offset, f.offset + f.count)), f.count = -1), h.onUploadCallback();
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
var Zr = class s1 extends Vt {
    constructor(t = 1, e = 1, n = 1, i = 1){
        super(), this.type = "PlaneGeometry", this.parameters = {
            width: t,
            height: e,
            widthSegments: n,
            heightSegments: i
        };
        let r = t / 2, a = e / 2, o = Math.floor(n), c = Math.floor(i), l = o + 1, h = c + 1, u = t / o, d = e / c, f = [], m = [], x = [], g = [];
        for(let p = 0; p < h; p++){
            let v = p * d - a;
            for(let _ = 0; _ < l; _++){
                let y = _ * u - r;
                m.push(y, -v, 0), x.push(0, 0, 1), g.push(_ / o), g.push(1 - p / c);
            }
        }
        for(let p = 0; p < c; p++)for(let v = 0; v < o; v++){
            let _ = v + l * p, y = v + l * (p + 1), b = v + 1 + l * (p + 1), w = v + 1 + l * p;
            f.push(_, y, w), f.push(y, b, w);
        }
        this.setIndex(f), this.setAttribute("position", new _t(m, 3)), this.setAttribute("normal", new _t(x, 3)), this.setAttribute("uv", new _t(g, 2));
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.width, t.height, t.widthSegments, t.heightSegments);
    }
}, Mp = `#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`, Sp = `#ifdef USE_ALPHAHASH
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
#endif`, bp = `#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`, Ep = `#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`, Tp = `#ifdef USE_ALPHATEST
	if ( diffuseColor.a < alphaTest ) discard;
#endif`, wp = `#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`, Ap = `#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometry.normal, geometry.viewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`, Rp = `#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`, Cp = `vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`, Pp = `vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`, Lp = `float G_BlinnPhong_Implicit( ) {
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
} // validated`, Ip = `#ifdef USE_IRIDESCENCE
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
#endif`, Up = `#ifdef USE_BUMPMAP
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
#endif`, Dp = `#if NUM_CLIPPING_PLANES > 0
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
#endif`, Np = `#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`, Fp = `#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`, Op = `#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`, Bp = `#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`, zp = `#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`, kp = `#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
	varying vec3 vColor;
#endif`, Vp = `#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif`, Hp = `#define PI 3.141592653589793
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
struct GeometricContext {
	vec3 position;
	vec3 normal;
	vec3 viewDir;
#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal;
#endif
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
} // validated`, Gp = `#ifdef ENVMAP_TYPE_CUBE_UV
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
#endif`, Wp = `vec3 transformedNormal = objectNormal;
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
#endif`, Xp = `#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`, qp = `#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`, Yp = `#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`, Zp = `#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`, Jp = "gl_FragColor = linearToOutputTexel( gl_FragColor );", $p = `vec4 LinearToLinear( in vec4 value ) {
	return value;
}
vec4 LinearTosRGB( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`, Kp = `#ifdef USE_ENVMAP
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
#endif`, Qp = `#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`, jp = `#ifdef USE_ENVMAP
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
#endif`, tm = `#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`, em = `#ifdef USE_ENVMAP
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
#endif`, nm = `#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`, im = `#ifdef USE_FOG
	varying float vFogDepth;
#endif`, sm = `#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`, rm = `#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`, am = `#ifdef USE_GRADIENTMAP
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
}`, om = `#ifdef USE_LIGHTMAP
	vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
	vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
	reflectedLight.indirectDiffuse += lightMapIrradiance;
#endif`, cm = `#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`, lm = `LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`, hm = `varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in GeometricContext geometry, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometry.normal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in GeometricContext geometry, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`, um = `uniform bool receiveShadow;
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
#endif`, dm = `#ifdef USE_ENVMAP
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
#endif`, fm = `ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`, pm = `varying vec3 vViewPosition;
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
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`, mm = `BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`, gm = `varying vec3 vViewPosition;
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
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`, _m = `PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( geometryNormal ) ), abs( dFdy( geometryNormal ) ) );
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
#endif`, xm = `struct PhysicalMaterial {
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
		clearcoatSpecular += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometry.viewDir, geometry.clearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
		sheenSpecular += irradiance * BRDF_Sheen( directLight.direction, geometry.viewDir, geometry.normal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometry.viewDir, geometry.normal, material );
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
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( geometry.normal, geometry.viewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );
	#else
		computeMultiscattering( geometry.normal, geometry.viewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
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
}`, vm = `
GeometricContext geometry;
geometry.position = - vViewPosition;
geometry.normal = normal;
geometry.viewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
#ifdef USE_CLEARCOAT
	geometry.clearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometry.viewDir ) );
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
		getPointLightInfo( pointLight, geometry, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometry, material, reflectedLight );
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
		getSpotLightInfo( spotLight, geometry, directLight );
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
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
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
#endif`, ym = `#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometry.normal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		radiance += getIBLAnisotropyRadiance( geometry.viewDir, geometry.normal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		radiance += getIBLRadiance( geometry.viewDir, geometry.normal, material.roughness );
	#endif
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometry.viewDir, geometry.clearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`, Mm = `#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometry, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometry, material, reflectedLight );
#endif`, Sm = `#if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )
	gl_FragDepthEXT = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`, bm = `#if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`, Em = `#ifdef USE_LOGDEPTHBUF
	#ifdef USE_LOGDEPTHBUF_EXT
		varying float vFragDepth;
		varying float vIsPerspective;
	#else
		uniform float logDepthBufFC;
	#endif
#endif`, Tm = `#ifdef USE_LOGDEPTHBUF
	#ifdef USE_LOGDEPTHBUF_EXT
		vFragDepth = 1.0 + gl_Position.w;
		vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
	#else
		if ( isPerspectiveMatrix( projectionMatrix ) ) {
			gl_Position.z = log2( max( EPSILON, gl_Position.w + 1.0 ) ) * logDepthBufFC - 1.0;
			gl_Position.z *= gl_Position.w;
		}
	#endif
#endif`, wm = `#ifdef USE_MAP
	diffuseColor *= texture2D( map, vMapUv );
#endif`, Am = `#ifdef USE_MAP
	uniform sampler2D map;
#endif`, Rm = `#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
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
#endif`, Cm = `#if defined( USE_POINTS_UV )
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
#endif`, Pm = `float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`, Lm = `#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`, Im = `#if defined( USE_MORPHCOLORS ) && defined( MORPHTARGETS_TEXTURE )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`, Um = `#ifdef USE_MORPHNORMALS
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
#endif`, Dm = `#ifdef USE_MORPHTARGETS
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
#endif`, Nm = `#ifdef USE_MORPHTARGETS
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
#endif`, Fm = `float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
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
vec3 geometryNormal = normal;`, Om = `#ifdef USE_NORMALMAP_OBJECTSPACE
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
#endif`, Bm = `#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`, zm = `#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`, km = `#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`, Vm = `#ifdef USE_NORMALMAP
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
#endif`, Hm = `#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = geometryNormal;
#endif`, Gm = `#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`, Wm = `#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`, Xm = `#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`, qm = `#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`, Ym = `vec3 packNormalToRGB( const in vec3 normal ) {
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
}`, Zm = `#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`, Jm = `vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`, $m = `#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`, Km = `#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`, Qm = `float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`, jm = `#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`, tg = `#if NUM_SPOT_LIGHT_COORDS > 0
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
#endif`, eg = `#if NUM_SPOT_LIGHT_COORDS > 0
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
#endif`, ng = `#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
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
#endif`, ig = `float getShadowMask() {
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
}`, sg = `#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`, rg = `#ifdef USE_SKINNING
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
#endif`, ag = `#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`, og = `#ifdef USE_SKINNING
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
#endif`, cg = `float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`, lg = `#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`, hg = `#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`, ug = `#ifndef saturate
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
vec3 CustomToneMapping( vec3 color ) { return color; }`, dg = `#ifdef USE_TRANSMISSION
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
#endif`, fg = `#ifdef USE_TRANSMISSION
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
#endif`, pg = `#if defined( USE_UV ) || defined( USE_ANISOTROPY )
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
#endif`, mg = `#if defined( USE_UV ) || defined( USE_ANISOTROPY )
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
#endif`, gg = `#if defined( USE_UV ) || defined( USE_ANISOTROPY )
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
#endif`, _g = `#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`, xg = `varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`, vg = `uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, yg = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`, Mg = `#ifdef ENVMAP_TYPE_CUBE
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
}`, Sg = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`, bg = `uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, Eg = `#include <common>
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
}`, Tg = `#if DEPTH_PACKING == 3200
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
}`, wg = `#define DISTANCE
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
}`, Ag = `#define DISTANCE
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
}`, Rg = `varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`, Cg = `uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`, Pg = `uniform float scale;
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
}`, Lg = `uniform vec3 diffuse;
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
}`, Ig = `#include <common>
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
}`, Ug = `uniform vec3 diffuse;
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
}`, Dg = `#define LAMBERT
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
}`, Ng = `#define LAMBERT
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
}`, Fg = `#define MATCAP
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
}`, Og = `#define MATCAP
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
}`, Bg = `#define NORMAL
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
}`, zg = `#define NORMAL
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
}`, kg = `#define PHONG
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
}`, Vg = `#define PHONG
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
}`, Hg = `#define STANDARD
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
}`, Gg = `#define STANDARD
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
		float dotNVcc = saturate( dot( geometry.clearcoatNormal, geometry.viewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + clearcoatSpecular * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`, Wg = `#define TOON
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
}`, Xg = `#define TOON
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
}`, qg = `uniform float size;
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
}`, Yg = `uniform vec3 diffuse;
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
}`, Zg = `#include <common>
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
}`, Jg = `uniform vec3 color;
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
}`, $g = `uniform float rotation;
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
}`, Kg = `uniform vec3 diffuse;
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
}`, zt = {
    alphahash_fragment: Mp,
    alphahash_pars_fragment: Sp,
    alphamap_fragment: bp,
    alphamap_pars_fragment: Ep,
    alphatest_fragment: Tp,
    alphatest_pars_fragment: wp,
    aomap_fragment: Ap,
    aomap_pars_fragment: Rp,
    begin_vertex: Cp,
    beginnormal_vertex: Pp,
    bsdfs: Lp,
    iridescence_fragment: Ip,
    bumpmap_pars_fragment: Up,
    clipping_planes_fragment: Dp,
    clipping_planes_pars_fragment: Np,
    clipping_planes_pars_vertex: Fp,
    clipping_planes_vertex: Op,
    color_fragment: Bp,
    color_pars_fragment: zp,
    color_pars_vertex: kp,
    color_vertex: Vp,
    common: Hp,
    cube_uv_reflection_fragment: Gp,
    defaultnormal_vertex: Wp,
    displacementmap_pars_vertex: Xp,
    displacementmap_vertex: qp,
    emissivemap_fragment: Yp,
    emissivemap_pars_fragment: Zp,
    colorspace_fragment: Jp,
    colorspace_pars_fragment: $p,
    envmap_fragment: Kp,
    envmap_common_pars_fragment: Qp,
    envmap_pars_fragment: jp,
    envmap_pars_vertex: tm,
    envmap_physical_pars_fragment: dm,
    envmap_vertex: em,
    fog_vertex: nm,
    fog_pars_vertex: im,
    fog_fragment: sm,
    fog_pars_fragment: rm,
    gradientmap_pars_fragment: am,
    lightmap_fragment: om,
    lightmap_pars_fragment: cm,
    lights_lambert_fragment: lm,
    lights_lambert_pars_fragment: hm,
    lights_pars_begin: um,
    lights_toon_fragment: fm,
    lights_toon_pars_fragment: pm,
    lights_phong_fragment: mm,
    lights_phong_pars_fragment: gm,
    lights_physical_fragment: _m,
    lights_physical_pars_fragment: xm,
    lights_fragment_begin: vm,
    lights_fragment_maps: ym,
    lights_fragment_end: Mm,
    logdepthbuf_fragment: Sm,
    logdepthbuf_pars_fragment: bm,
    logdepthbuf_pars_vertex: Em,
    logdepthbuf_vertex: Tm,
    map_fragment: wm,
    map_pars_fragment: Am,
    map_particle_fragment: Rm,
    map_particle_pars_fragment: Cm,
    metalnessmap_fragment: Pm,
    metalnessmap_pars_fragment: Lm,
    morphcolor_vertex: Im,
    morphnormal_vertex: Um,
    morphtarget_pars_vertex: Dm,
    morphtarget_vertex: Nm,
    normal_fragment_begin: Fm,
    normal_fragment_maps: Om,
    normal_pars_fragment: Bm,
    normal_pars_vertex: zm,
    normal_vertex: km,
    normalmap_pars_fragment: Vm,
    clearcoat_normal_fragment_begin: Hm,
    clearcoat_normal_fragment_maps: Gm,
    clearcoat_pars_fragment: Wm,
    iridescence_pars_fragment: Xm,
    opaque_fragment: qm,
    packing: Ym,
    premultiplied_alpha_fragment: Zm,
    project_vertex: Jm,
    dithering_fragment: $m,
    dithering_pars_fragment: Km,
    roughnessmap_fragment: Qm,
    roughnessmap_pars_fragment: jm,
    shadowmap_pars_fragment: tg,
    shadowmap_pars_vertex: eg,
    shadowmap_vertex: ng,
    shadowmask_pars_fragment: ig,
    skinbase_vertex: sg,
    skinning_pars_vertex: rg,
    skinning_vertex: ag,
    skinnormal_vertex: og,
    specularmap_fragment: cg,
    specularmap_pars_fragment: lg,
    tonemapping_fragment: hg,
    tonemapping_pars_fragment: ug,
    transmission_fragment: dg,
    transmission_pars_fragment: fg,
    uv_pars_fragment: pg,
    uv_pars_vertex: mg,
    uv_vertex: gg,
    worldpos_vertex: _g,
    background_vert: xg,
    background_frag: vg,
    backgroundCube_vert: yg,
    backgroundCube_frag: Mg,
    cube_vert: Sg,
    cube_frag: bg,
    depth_vert: Eg,
    depth_frag: Tg,
    distanceRGBA_vert: wg,
    distanceRGBA_frag: Ag,
    equirect_vert: Rg,
    equirect_frag: Cg,
    linedashed_vert: Pg,
    linedashed_frag: Lg,
    meshbasic_vert: Ig,
    meshbasic_frag: Ug,
    meshlambert_vert: Dg,
    meshlambert_frag: Ng,
    meshmatcap_vert: Fg,
    meshmatcap_frag: Og,
    meshnormal_vert: Bg,
    meshnormal_frag: zg,
    meshphong_vert: kg,
    meshphong_frag: Vg,
    meshphysical_vert: Hg,
    meshphysical_frag: Gg,
    meshtoon_vert: Wg,
    meshtoon_frag: Xg,
    points_vert: qg,
    points_frag: Yg,
    shadow_vert: Zg,
    shadow_frag: Jg,
    sprite_vert: $g,
    sprite_frag: Kg
}, ct = {
    common: {
        diffuse: {
            value: new ft(16777215)
        },
        opacity: {
            value: 1
        },
        map: {
            value: null
        },
        mapTransform: {
            value: new kt
        },
        alphaMap: {
            value: null
        },
        alphaMapTransform: {
            value: new kt
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
            value: new kt
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
            value: new kt
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
            value: new kt
        }
    },
    bumpmap: {
        bumpMap: {
            value: null
        },
        bumpMapTransform: {
            value: new kt
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
            value: new kt
        },
        normalScale: {
            value: new J(1, 1)
        }
    },
    displacementmap: {
        displacementMap: {
            value: null
        },
        displacementMapTransform: {
            value: new kt
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
            value: new kt
        }
    },
    metalnessmap: {
        metalnessMap: {
            value: null
        },
        metalnessMapTransform: {
            value: new kt
        }
    },
    roughnessmap: {
        roughnessMap: {
            value: null
        },
        roughnessMapTransform: {
            value: new kt
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
            value: new ft(16777215)
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
            value: new ft(16777215)
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
            value: new kt
        },
        alphaTest: {
            value: 0
        },
        uvTransform: {
            value: new kt
        }
    },
    sprite: {
        diffuse: {
            value: new ft(16777215)
        },
        opacity: {
            value: 1
        },
        center: {
            value: new J(.5, .5)
        },
        rotation: {
            value: 0
        },
        map: {
            value: null
        },
        mapTransform: {
            value: new kt
        },
        alphaMap: {
            value: null
        },
        alphaMapTransform: {
            value: new kt
        },
        alphaTest: {
            value: 0
        }
    }
}, en = {
    basic: {
        uniforms: Re([
            ct.common,
            ct.specularmap,
            ct.envmap,
            ct.aomap,
            ct.lightmap,
            ct.fog
        ]),
        vertexShader: zt.meshbasic_vert,
        fragmentShader: zt.meshbasic_frag
    },
    lambert: {
        uniforms: Re([
            ct.common,
            ct.specularmap,
            ct.envmap,
            ct.aomap,
            ct.lightmap,
            ct.emissivemap,
            ct.bumpmap,
            ct.normalmap,
            ct.displacementmap,
            ct.fog,
            ct.lights,
            {
                emissive: {
                    value: new ft(0)
                }
            }
        ]),
        vertexShader: zt.meshlambert_vert,
        fragmentShader: zt.meshlambert_frag
    },
    phong: {
        uniforms: Re([
            ct.common,
            ct.specularmap,
            ct.envmap,
            ct.aomap,
            ct.lightmap,
            ct.emissivemap,
            ct.bumpmap,
            ct.normalmap,
            ct.displacementmap,
            ct.fog,
            ct.lights,
            {
                emissive: {
                    value: new ft(0)
                },
                specular: {
                    value: new ft(1118481)
                },
                shininess: {
                    value: 30
                }
            }
        ]),
        vertexShader: zt.meshphong_vert,
        fragmentShader: zt.meshphong_frag
    },
    standard: {
        uniforms: Re([
            ct.common,
            ct.envmap,
            ct.aomap,
            ct.lightmap,
            ct.emissivemap,
            ct.bumpmap,
            ct.normalmap,
            ct.displacementmap,
            ct.roughnessmap,
            ct.metalnessmap,
            ct.fog,
            ct.lights,
            {
                emissive: {
                    value: new ft(0)
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
        vertexShader: zt.meshphysical_vert,
        fragmentShader: zt.meshphysical_frag
    },
    toon: {
        uniforms: Re([
            ct.common,
            ct.aomap,
            ct.lightmap,
            ct.emissivemap,
            ct.bumpmap,
            ct.normalmap,
            ct.displacementmap,
            ct.gradientmap,
            ct.fog,
            ct.lights,
            {
                emissive: {
                    value: new ft(0)
                }
            }
        ]),
        vertexShader: zt.meshtoon_vert,
        fragmentShader: zt.meshtoon_frag
    },
    matcap: {
        uniforms: Re([
            ct.common,
            ct.bumpmap,
            ct.normalmap,
            ct.displacementmap,
            ct.fog,
            {
                matcap: {
                    value: null
                }
            }
        ]),
        vertexShader: zt.meshmatcap_vert,
        fragmentShader: zt.meshmatcap_frag
    },
    points: {
        uniforms: Re([
            ct.points,
            ct.fog
        ]),
        vertexShader: zt.points_vert,
        fragmentShader: zt.points_frag
    },
    dashed: {
        uniforms: Re([
            ct.common,
            ct.fog,
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
        vertexShader: zt.linedashed_vert,
        fragmentShader: zt.linedashed_frag
    },
    depth: {
        uniforms: Re([
            ct.common,
            ct.displacementmap
        ]),
        vertexShader: zt.depth_vert,
        fragmentShader: zt.depth_frag
    },
    normal: {
        uniforms: Re([
            ct.common,
            ct.bumpmap,
            ct.normalmap,
            ct.displacementmap,
            {
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: zt.meshnormal_vert,
        fragmentShader: zt.meshnormal_frag
    },
    sprite: {
        uniforms: Re([
            ct.sprite,
            ct.fog
        ]),
        vertexShader: zt.sprite_vert,
        fragmentShader: zt.sprite_frag
    },
    background: {
        uniforms: {
            uvTransform: {
                value: new kt
            },
            t2D: {
                value: null
            },
            backgroundIntensity: {
                value: 1
            }
        },
        vertexShader: zt.background_vert,
        fragmentShader: zt.background_frag
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
        vertexShader: zt.backgroundCube_vert,
        fragmentShader: zt.backgroundCube_frag
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
        vertexShader: zt.cube_vert,
        fragmentShader: zt.cube_frag
    },
    equirect: {
        uniforms: {
            tEquirect: {
                value: null
            }
        },
        vertexShader: zt.equirect_vert,
        fragmentShader: zt.equirect_frag
    },
    distanceRGBA: {
        uniforms: Re([
            ct.common,
            ct.displacementmap,
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
        vertexShader: zt.distanceRGBA_vert,
        fragmentShader: zt.distanceRGBA_frag
    },
    shadow: {
        uniforms: Re([
            ct.lights,
            ct.fog,
            {
                color: {
                    value: new ft(0)
                },
                opacity: {
                    value: 1
                }
            }
        ]),
        vertexShader: zt.shadow_vert,
        fragmentShader: zt.shadow_frag
    }
};
en.physical = {
    uniforms: Re([
        en.standard.uniforms,
        {
            clearcoat: {
                value: 0
            },
            clearcoatMap: {
                value: null
            },
            clearcoatMapTransform: {
                value: new kt
            },
            clearcoatNormalMap: {
                value: null
            },
            clearcoatNormalMapTransform: {
                value: new kt
            },
            clearcoatNormalScale: {
                value: new J(1, 1)
            },
            clearcoatRoughness: {
                value: 0
            },
            clearcoatRoughnessMap: {
                value: null
            },
            clearcoatRoughnessMapTransform: {
                value: new kt
            },
            iridescence: {
                value: 0
            },
            iridescenceMap: {
                value: null
            },
            iridescenceMapTransform: {
                value: new kt
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
                value: new kt
            },
            sheen: {
                value: 0
            },
            sheenColor: {
                value: new ft(0)
            },
            sheenColorMap: {
                value: null
            },
            sheenColorMapTransform: {
                value: new kt
            },
            sheenRoughness: {
                value: 1
            },
            sheenRoughnessMap: {
                value: null
            },
            sheenRoughnessMapTransform: {
                value: new kt
            },
            transmission: {
                value: 0
            },
            transmissionMap: {
                value: null
            },
            transmissionMapTransform: {
                value: new kt
            },
            transmissionSamplerSize: {
                value: new J
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
                value: new kt
            },
            attenuationDistance: {
                value: 0
            },
            attenuationColor: {
                value: new ft(0)
            },
            specularColor: {
                value: new ft(1, 1, 1)
            },
            specularColorMap: {
                value: null
            },
            specularColorMapTransform: {
                value: new kt
            },
            specularIntensity: {
                value: 1
            },
            specularIntensityMap: {
                value: null
            },
            specularIntensityMapTransform: {
                value: new kt
            },
            anisotropyVector: {
                value: new J
            },
            anisotropyMap: {
                value: null
            },
            anisotropyMapTransform: {
                value: new kt
            }
        }
    ]),
    vertexShader: zt.meshphysical_vert,
    fragmentShader: zt.meshphysical_frag
};
var lr = {
    r: 0,
    b: 0,
    g: 0
};
function Qg(s1, t, e, n, i, r, a) {
    let o = new ft(0), c = r === !0 ? 0 : 1, l, h, u = null, d = 0, f = null;
    function m(g, p) {
        let v = !1, _ = p.isScene === !0 ? p.background : null;
        switch(_ && _.isTexture && (_ = (p.backgroundBlurriness > 0 ? e : t).get(_)), _ === null ? x(o, c) : _ && _.isColor && (x(_, 1), v = !0), s1.xr.getEnvironmentBlendMode()){
            case "opaque":
                v = !0;
                break;
            case "additive":
                n.buffers.color.setClear(0, 0, 0, 1, a), v = !0;
                break;
            case "alpha-blend":
                n.buffers.color.setClear(0, 0, 0, 0, a), v = !0;
                break;
        }
        (s1.autoClear || v) && s1.clear(s1.autoClearColor, s1.autoClearDepth, s1.autoClearStencil), _ && (_.isCubeTexture || _.mapping === Hs) ? (h === void 0 && (h = new ve(new Ji(1, 1, 1), new Qe({
            name: "BackgroundCubeMaterial",
            uniforms: $i(en.backgroundCube.uniforms),
            vertexShader: en.backgroundCube.vertexShader,
            fragmentShader: en.backgroundCube.fragmentShader,
            side: De,
            depthTest: !1,
            depthWrite: !1,
            fog: !1
        })), h.geometry.deleteAttribute("normal"), h.geometry.deleteAttribute("uv"), h.onBeforeRender = function(w, R, L) {
            this.matrixWorld.copyPosition(L.matrixWorld);
        }, Object.defineProperty(h.material, "envMap", {
            get: function() {
                return this.uniforms.envMap.value;
            }
        }), i.update(h)), h.material.uniforms.envMap.value = _, h.material.uniforms.flipEnvMap.value = _.isCubeTexture && _.isRenderTargetTexture === !1 ? -1 : 1, h.material.uniforms.backgroundBlurriness.value = p.backgroundBlurriness, h.material.uniforms.backgroundIntensity.value = p.backgroundIntensity, h.material.toneMapped = _.colorSpace !== Nt, (u !== _ || d !== _.version || f !== s1.toneMapping) && (h.material.needsUpdate = !0, u = _, d = _.version, f = s1.toneMapping), h.layers.enableAll(), g.unshift(h, h.geometry, h.material, 0, 0, null)) : _ && _.isTexture && (l === void 0 && (l = new ve(new Zr(2, 2), new Qe({
            name: "BackgroundMaterial",
            uniforms: $i(en.background.uniforms),
            vertexShader: en.background.vertexShader,
            fragmentShader: en.background.fragmentShader,
            side: On,
            depthTest: !1,
            depthWrite: !1,
            fog: !1
        })), l.geometry.deleteAttribute("normal"), Object.defineProperty(l.material, "map", {
            get: function() {
                return this.uniforms.t2D.value;
            }
        }), i.update(l)), l.material.uniforms.t2D.value = _, l.material.uniforms.backgroundIntensity.value = p.backgroundIntensity, l.material.toneMapped = _.colorSpace !== Nt, _.matrixAutoUpdate === !0 && _.updateMatrix(), l.material.uniforms.uvTransform.value.copy(_.matrix), (u !== _ || d !== _.version || f !== s1.toneMapping) && (l.material.needsUpdate = !0, u = _, d = _.version, f = s1.toneMapping), l.layers.enableAll(), g.unshift(l, l.geometry, l.material, 0, 0, null));
    }
    function x(g, p) {
        g.getRGB(lr, xd(s1)), n.buffers.color.setClear(lr.r, lr.g, lr.b, p, a);
    }
    return {
        getClearColor: function() {
            return o;
        },
        setClearColor: function(g, p = 1) {
            o.set(g), c = p, x(o, c);
        },
        getClearAlpha: function() {
            return c;
        },
        setClearAlpha: function(g) {
            c = g, x(o, c);
        },
        render: m
    };
}
function jg(s1, t, e, n) {
    let i = s1.getParameter(s1.MAX_VERTEX_ATTRIBS), r = n.isWebGL2 ? null : t.get("OES_vertex_array_object"), a = n.isWebGL2 || r !== null, o = {}, c = g(null), l = c, h = !1;
    function u(O, z, K, X, Y) {
        let j = !1;
        if (a) {
            let tt = x(X, K, z);
            l !== tt && (l = tt, f(l.object)), j = p(O, X, K, Y), j && v(O, X, K, Y);
        } else {
            let tt = z.wireframe === !0;
            (l.geometry !== X.id || l.program !== K.id || l.wireframe !== tt) && (l.geometry = X.id, l.program = K.id, l.wireframe = tt, j = !0);
        }
        Y !== null && e.update(Y, s1.ELEMENT_ARRAY_BUFFER), (j || h) && (h = !1, L(O, z, K, X), Y !== null && s1.bindBuffer(s1.ELEMENT_ARRAY_BUFFER, e.get(Y).buffer));
    }
    function d() {
        return n.isWebGL2 ? s1.createVertexArray() : r.createVertexArrayOES();
    }
    function f(O) {
        return n.isWebGL2 ? s1.bindVertexArray(O) : r.bindVertexArrayOES(O);
    }
    function m(O) {
        return n.isWebGL2 ? s1.deleteVertexArray(O) : r.deleteVertexArrayOES(O);
    }
    function x(O, z, K) {
        let X = K.wireframe === !0, Y = o[O.id];
        Y === void 0 && (Y = {}, o[O.id] = Y);
        let j = Y[z.id];
        j === void 0 && (j = {}, Y[z.id] = j);
        let tt = j[X];
        return tt === void 0 && (tt = g(d()), j[X] = tt), tt;
    }
    function g(O) {
        let z = [], K = [], X = [];
        for(let Y = 0; Y < i; Y++)z[Y] = 0, K[Y] = 0, X[Y] = 0;
        return {
            geometry: null,
            program: null,
            wireframe: !1,
            newAttributes: z,
            enabledAttributes: K,
            attributeDivisors: X,
            object: O,
            attributes: {},
            index: null
        };
    }
    function p(O, z, K, X) {
        let Y = l.attributes, j = z.attributes, tt = 0, N = K.getAttributes();
        for(let q in N)if (N[q].location >= 0) {
            let ut = Y[q], pt = j[q];
            if (pt === void 0 && (q === "instanceMatrix" && O.instanceMatrix && (pt = O.instanceMatrix), q === "instanceColor" && O.instanceColor && (pt = O.instanceColor)), ut === void 0 || ut.attribute !== pt || pt && ut.data !== pt.data) return !0;
            tt++;
        }
        return l.attributesNum !== tt || l.index !== X;
    }
    function v(O, z, K, X) {
        let Y = {}, j = z.attributes, tt = 0, N = K.getAttributes();
        for(let q in N)if (N[q].location >= 0) {
            let ut = j[q];
            ut === void 0 && (q === "instanceMatrix" && O.instanceMatrix && (ut = O.instanceMatrix), q === "instanceColor" && O.instanceColor && (ut = O.instanceColor));
            let pt = {};
            pt.attribute = ut, ut && ut.data && (pt.data = ut.data), Y[q] = pt, tt++;
        }
        l.attributes = Y, l.attributesNum = tt, l.index = X;
    }
    function _() {
        let O = l.newAttributes;
        for(let z = 0, K = O.length; z < K; z++)O[z] = 0;
    }
    function y(O) {
        b(O, 0);
    }
    function b(O, z) {
        let K = l.newAttributes, X = l.enabledAttributes, Y = l.attributeDivisors;
        K[O] = 1, X[O] === 0 && (s1.enableVertexAttribArray(O), X[O] = 1), Y[O] !== z && ((n.isWebGL2 ? s1 : t.get("ANGLE_instanced_arrays"))[n.isWebGL2 ? "vertexAttribDivisor" : "vertexAttribDivisorANGLE"](O, z), Y[O] = z);
    }
    function w() {
        let O = l.newAttributes, z = l.enabledAttributes;
        for(let K = 0, X = z.length; K < X; K++)z[K] !== O[K] && (s1.disableVertexAttribArray(K), z[K] = 0);
    }
    function R(O, z, K, X, Y, j, tt) {
        tt === !0 ? s1.vertexAttribIPointer(O, z, K, Y, j) : s1.vertexAttribPointer(O, z, K, X, Y, j);
    }
    function L(O, z, K, X) {
        if (n.isWebGL2 === !1 && (O.isInstancedMesh || X.isInstancedBufferGeometry) && t.get("ANGLE_instanced_arrays") === null) return;
        _();
        let Y = X.attributes, j = K.getAttributes(), tt = z.defaultAttributeValues;
        for(let N in j){
            let q = j[N];
            if (q.location >= 0) {
                let lt = Y[N];
                if (lt === void 0 && (N === "instanceMatrix" && O.instanceMatrix && (lt = O.instanceMatrix), N === "instanceColor" && O.instanceColor && (lt = O.instanceColor)), lt !== void 0) {
                    let ut = lt.normalized, pt = lt.itemSize, Et = e.get(lt);
                    if (Et === void 0) continue;
                    let Tt = Et.buffer, wt = Et.type, Yt = Et.bytesPerElement, te = n.isWebGL2 === !0 && (wt === s1.INT || wt === s1.UNSIGNED_INT || lt.gpuType === ad);
                    if (lt.isInterleavedBufferAttribute) {
                        let Pt = lt.data, P = Pt.stride, at = lt.offset;
                        if (Pt.isInstancedInterleavedBuffer) {
                            for(let Z = 0; Z < q.locationSize; Z++)b(q.location + Z, Pt.meshPerAttribute);
                            O.isInstancedMesh !== !0 && X._maxInstanceCount === void 0 && (X._maxInstanceCount = Pt.meshPerAttribute * Pt.count);
                        } else for(let Z = 0; Z < q.locationSize; Z++)y(q.location + Z);
                        s1.bindBuffer(s1.ARRAY_BUFFER, Tt);
                        for(let Z = 0; Z < q.locationSize; Z++)R(q.location + Z, pt / q.locationSize, wt, ut, P * Yt, (at + pt / q.locationSize * Z) * Yt, te);
                    } else {
                        if (lt.isInstancedBufferAttribute) {
                            for(let Pt = 0; Pt < q.locationSize; Pt++)b(q.location + Pt, lt.meshPerAttribute);
                            O.isInstancedMesh !== !0 && X._maxInstanceCount === void 0 && (X._maxInstanceCount = lt.meshPerAttribute * lt.count);
                        } else for(let Pt = 0; Pt < q.locationSize; Pt++)y(q.location + Pt);
                        s1.bindBuffer(s1.ARRAY_BUFFER, Tt);
                        for(let Pt = 0; Pt < q.locationSize; Pt++)R(q.location + Pt, pt / q.locationSize, wt, ut, pt * Yt, pt / q.locationSize * Pt * Yt, te);
                    }
                } else if (tt !== void 0) {
                    let ut = tt[N];
                    if (ut !== void 0) switch(ut.length){
                        case 2:
                            s1.vertexAttrib2fv(q.location, ut);
                            break;
                        case 3:
                            s1.vertexAttrib3fv(q.location, ut);
                            break;
                        case 4:
                            s1.vertexAttrib4fv(q.location, ut);
                            break;
                        default:
                            s1.vertexAttrib1fv(q.location, ut);
                    }
                }
            }
        }
        w();
    }
    function M() {
        $();
        for(let O in o){
            let z = o[O];
            for(let K in z){
                let X = z[K];
                for(let Y in X)m(X[Y].object), delete X[Y];
                delete z[K];
            }
            delete o[O];
        }
    }
    function E(O) {
        if (o[O.id] === void 0) return;
        let z = o[O.id];
        for(let K in z){
            let X = z[K];
            for(let Y in X)m(X[Y].object), delete X[Y];
            delete z[K];
        }
        delete o[O.id];
    }
    function V(O) {
        for(let z in o){
            let K = o[z];
            if (K[O.id] === void 0) continue;
            let X = K[O.id];
            for(let Y in X)m(X[Y].object), delete X[Y];
            delete K[O.id];
        }
    }
    function $() {
        F(), h = !0, l !== c && (l = c, f(l.object));
    }
    function F() {
        c.geometry = null, c.program = null, c.wireframe = !1;
    }
    return {
        setup: u,
        reset: $,
        resetDefaultState: F,
        dispose: M,
        releaseStatesOfGeometry: E,
        releaseStatesOfProgram: V,
        initAttributes: _,
        enableAttribute: y,
        disableUnusedAttributes: w
    };
}
function t_(s1, t, e, n) {
    let i = n.isWebGL2, r;
    function a(l) {
        r = l;
    }
    function o(l, h) {
        s1.drawArrays(r, l, h), e.update(h, r, 1);
    }
    function c(l, h, u) {
        if (u === 0) return;
        let d, f;
        if (i) d = s1, f = "drawArraysInstanced";
        else if (d = t.get("ANGLE_instanced_arrays"), f = "drawArraysInstancedANGLE", d === null) {
            console.error("THREE.WebGLBufferRenderer: using THREE.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.");
            return;
        }
        d[f](r, l, h, u), e.update(h, r, u);
    }
    this.setMode = a, this.render = o, this.renderInstances = c;
}
function e_(s1, t, e) {
    let n;
    function i() {
        if (n !== void 0) return n;
        if (t.has("EXT_texture_filter_anisotropic") === !0) {
            let R = t.get("EXT_texture_filter_anisotropic");
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
    let a = typeof WebGL2RenderingContext < "u" && s1.constructor.name === "WebGL2RenderingContext", o = e.precision !== void 0 ? e.precision : "highp", c = r(o);
    c !== o && (console.warn("THREE.WebGLRenderer:", o, "not supported, using", c, "instead."), o = c);
    let l = a || t.has("WEBGL_draw_buffers"), h = e.logarithmicDepthBuffer === !0, u = s1.getParameter(s1.MAX_TEXTURE_IMAGE_UNITS), d = s1.getParameter(s1.MAX_VERTEX_TEXTURE_IMAGE_UNITS), f = s1.getParameter(s1.MAX_TEXTURE_SIZE), m = s1.getParameter(s1.MAX_CUBE_MAP_TEXTURE_SIZE), x = s1.getParameter(s1.MAX_VERTEX_ATTRIBS), g = s1.getParameter(s1.MAX_VERTEX_UNIFORM_VECTORS), p = s1.getParameter(s1.MAX_VARYING_VECTORS), v = s1.getParameter(s1.MAX_FRAGMENT_UNIFORM_VECTORS), _ = d > 0, y = a || t.has("OES_texture_float"), b = _ && y, w = a ? s1.getParameter(s1.MAX_SAMPLES) : 0;
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
        maxAttributes: x,
        maxVertexUniforms: g,
        maxVaryings: p,
        maxFragmentUniforms: v,
        vertexTextures: _,
        floatFragmentTextures: y,
        floatVertexTextures: b,
        maxSamples: w
    };
}
function n_(s1) {
    let t = this, e = null, n = 0, i = !1, r = !1, a = new mn, o = new kt, c = {
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
        e = h(u, d, 0);
    }, this.setState = function(u, d, f) {
        let m = u.clippingPlanes, x = u.clipIntersection, g = u.clipShadows, p = s1.get(u);
        if (!i || m === null || m.length === 0 || r && !g) r ? h(null) : l();
        else {
            let v = r ? 0 : n, _ = v * 4, y = p.clippingState || null;
            c.value = y, y = h(m, d, _, f);
            for(let b = 0; b !== _; ++b)y[b] = e[b];
            p.clippingState = y, this.numIntersection = x ? this.numPlanes : 0, this.numPlanes += v;
        }
    };
    function l() {
        c.value !== e && (c.value = e, c.needsUpdate = n > 0), t.numPlanes = n, t.numIntersection = 0;
    }
    function h(u, d, f, m) {
        let x = u !== null ? u.length : 0, g = null;
        if (x !== 0) {
            if (g = c.value, m !== !0 || g === null) {
                let p = f + x * 4, v = d.matrixWorldInverse;
                o.getNormalMatrix(v), (g === null || g.length < p) && (g = new Float32Array(p));
                for(let _ = 0, y = f; _ !== x; ++_, y += 4)a.copy(u[_]).applyMatrix4(v, o), a.normal.toArray(g, y), g[y + 3] = a.constant;
            }
            c.value = g, c.needsUpdate = !0;
        }
        return t.numPlanes = x, t.numIntersection = 0, g;
    }
}
function i_(s1) {
    let t = new WeakMap;
    function e(a, o) {
        return o === Ur ? a.mapping = Bn : o === Dr && (a.mapping = ci), a;
    }
    function n(a) {
        if (a && a.isTexture && a.isRenderTargetTexture === !1) {
            let o = a.mapping;
            if (o === Ur || o === Dr) if (t.has(a)) {
                let c = t.get(a).texture;
                return e(c, a.mapping);
            } else {
                let c = a.image;
                if (c && c.height > 0) {
                    let l = new fo(c.height / 2);
                    return l.fromEquirectangularTexture(s1, a), t.set(a, l), a.addEventListener("dispose", i), e(l.texture, a.mapping);
                } else return null;
            }
        }
        return a;
    }
    function i(a) {
        let o = a.target;
        o.removeEventListener("dispose", i);
        let c = t.get(o);
        c !== void 0 && (t.delete(o), c.dispose());
    }
    function r() {
        t = new WeakMap;
    }
    return {
        get: n,
        dispose: r
    };
}
var Ls = class extends Cs {
    constructor(t = -1, e = 1, n = 1, i = -1, r = .1, a = 2e3){
        super(), this.isOrthographicCamera = !0, this.type = "OrthographicCamera", this.zoom = 1, this.view = null, this.left = t, this.right = e, this.top = n, this.bottom = i, this.near = r, this.far = a, this.updateProjectionMatrix();
    }
    copy(t, e) {
        return super.copy(t, e), this.left = t.left, this.right = t.right, this.top = t.top, this.bottom = t.bottom, this.near = t.near, this.far = t.far, this.zoom = t.zoom, this.view = t.view === null ? null : Object.assign({}, t.view), this;
    }
    setViewOffset(t, e, n, i, r, a) {
        this.view === null && (this.view = {
            enabled: !0,
            fullWidth: 1,
            fullHeight: 1,
            offsetX: 0,
            offsetY: 0,
            width: 1,
            height: 1
        }), this.view.enabled = !0, this.view.fullWidth = t, this.view.fullHeight = e, this.view.offsetX = n, this.view.offsetY = i, this.view.width = r, this.view.height = a, this.updateProjectionMatrix();
    }
    clearViewOffset() {
        this.view !== null && (this.view.enabled = !1), this.updateProjectionMatrix();
    }
    updateProjectionMatrix() {
        let t = (this.right - this.left) / (2 * this.zoom), e = (this.top - this.bottom) / (2 * this.zoom), n = (this.right + this.left) / 2, i = (this.top + this.bottom) / 2, r = n - t, a = n + t, o = i + e, c = i - e;
        if (this.view !== null && this.view.enabled) {
            let l = (this.right - this.left) / this.view.fullWidth / this.zoom, h = (this.top - this.bottom) / this.view.fullHeight / this.zoom;
            r += l * this.view.offsetX, a = r + l * this.view.width, o -= h * this.view.offsetY, c = o - h * this.view.height;
        }
        this.projectionMatrix.makeOrthographic(r, a, o, c, this.near, this.far, this.coordinateSystem), this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return e.object.zoom = this.zoom, e.object.left = this.left, e.object.right = this.right, e.object.top = this.top, e.object.bottom = this.bottom, e.object.near = this.near, e.object.far = this.far, this.view !== null && (e.object.view = Object.assign({}, this.view)), e;
    }
}, Hi = 4, nh = [
    .125,
    .215,
    .35,
    .446,
    .526,
    .582
], jn = 20, Xa = new Ls, ih = new ft, qa = null, Qn = (1 + Math.sqrt(5)) / 2, Li = 1 / Qn, sh = [
    new A(1, 1, 1),
    new A(-1, 1, 1),
    new A(1, 1, -1),
    new A(-1, 1, -1),
    new A(0, Qn, Li),
    new A(0, Qn, -Li),
    new A(Li, 0, Qn),
    new A(-Li, 0, Qn),
    new A(Qn, Li, 0),
    new A(-Qn, Li, 0)
], Jr = class {
    constructor(t){
        this._renderer = t, this._pingPongRenderTarget = null, this._lodMax = 0, this._cubeSize = 0, this._lodPlanes = [], this._sizeLods = [], this._sigmas = [], this._blurMaterial = null, this._cubemapMaterial = null, this._equirectMaterial = null, this._compileMaterial(this._blurMaterial);
    }
    fromScene(t, e = 0, n = .1, i = 100) {
        qa = this._renderer.getRenderTarget(), this._setSize(256);
        let r = this._allocateTargets();
        return r.depthBuffer = !0, this._sceneToCubeUV(t, n, i, r), e > 0 && this._blur(r, 0, 0, e), this._applyPMREM(r), this._cleanup(r), r;
    }
    fromEquirectangular(t, e = null) {
        return this._fromTexture(t, e);
    }
    fromCubemap(t, e = null) {
        return this._fromTexture(t, e);
    }
    compileCubemapShader() {
        this._cubemapMaterial === null && (this._cubemapMaterial = oh(), this._compileMaterial(this._cubemapMaterial));
    }
    compileEquirectangularShader() {
        this._equirectMaterial === null && (this._equirectMaterial = ah(), this._compileMaterial(this._equirectMaterial));
    }
    dispose() {
        this._dispose(), this._cubemapMaterial !== null && this._cubemapMaterial.dispose(), this._equirectMaterial !== null && this._equirectMaterial.dispose();
    }
    _setSize(t) {
        this._lodMax = Math.floor(Math.log2(t)), this._cubeSize = Math.pow(2, this._lodMax);
    }
    _dispose() {
        this._blurMaterial !== null && this._blurMaterial.dispose(), this._pingPongRenderTarget !== null && this._pingPongRenderTarget.dispose();
        for(let t = 0; t < this._lodPlanes.length; t++)this._lodPlanes[t].dispose();
    }
    _cleanup(t) {
        this._renderer.setRenderTarget(qa), t.scissorTest = !1, hr(t, 0, 0, t.width, t.height);
    }
    _fromTexture(t, e) {
        t.mapping === Bn || t.mapping === ci ? this._setSize(t.image.length === 0 ? 16 : t.image[0].width || t.image[0].image.width) : this._setSize(t.image.width / 4), qa = this._renderer.getRenderTarget();
        let n = e || this._allocateTargets();
        return this._textureToCubeUV(t, n), this._applyPMREM(n), this._cleanup(n), n;
    }
    _allocateTargets() {
        let t = 3 * Math.max(this._cubeSize, 112), e = 4 * this._cubeSize, n = {
            magFilter: pe,
            minFilter: pe,
            generateMipmaps: !1,
            type: Ts,
            format: He,
            colorSpace: nn,
            depthBuffer: !1
        }, i = rh(t, e, n);
        if (this._pingPongRenderTarget === null || this._pingPongRenderTarget.width !== t || this._pingPongRenderTarget.height !== e) {
            this._pingPongRenderTarget !== null && this._dispose(), this._pingPongRenderTarget = rh(t, e, n);
            let { _lodMax: r  } = this;
            ({ sizeLods: this._sizeLods , lodPlanes: this._lodPlanes , sigmas: this._sigmas  } = s_(r)), this._blurMaterial = r_(r, t, e);
        }
        return i;
    }
    _compileMaterial(t) {
        let e = new ve(this._lodPlanes[0], t);
        this._renderer.compile(e, Xa);
    }
    _sceneToCubeUV(t, e, n, i) {
        let o = new xe(90, 1, e, n), c = [
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
        h.getClearColor(ih), h.toneMapping = Dn, h.autoClear = !1;
        let f = new Mn({
            name: "PMREM.Background",
            side: De,
            depthWrite: !1,
            depthTest: !1
        }), m = new ve(new Ji, f), x = !1, g = t.background;
        g ? g.isColor && (f.color.copy(g), t.background = null, x = !0) : (f.color.copy(ih), x = !0);
        for(let p = 0; p < 6; p++){
            let v = p % 3;
            v === 0 ? (o.up.set(0, c[p], 0), o.lookAt(l[p], 0, 0)) : v === 1 ? (o.up.set(0, 0, c[p]), o.lookAt(0, l[p], 0)) : (o.up.set(0, c[p], 0), o.lookAt(0, 0, l[p]));
            let _ = this._cubeSize;
            hr(i, v * _, p > 2 ? _ : 0, _, _), h.setRenderTarget(i), x && h.render(m, o), h.render(t, o);
        }
        m.geometry.dispose(), m.material.dispose(), h.toneMapping = d, h.autoClear = u, t.background = g;
    }
    _textureToCubeUV(t, e) {
        let n = this._renderer, i = t.mapping === Bn || t.mapping === ci;
        i ? (this._cubemapMaterial === null && (this._cubemapMaterial = oh()), this._cubemapMaterial.uniforms.flipEnvMap.value = t.isRenderTargetTexture === !1 ? -1 : 1) : this._equirectMaterial === null && (this._equirectMaterial = ah());
        let r = i ? this._cubemapMaterial : this._equirectMaterial, a = new ve(this._lodPlanes[0], r), o = r.uniforms;
        o.envMap.value = t;
        let c = this._cubeSize;
        hr(e, 0, 0, 3 * c, 2 * c), n.setRenderTarget(e), n.render(a, Xa);
    }
    _applyPMREM(t) {
        let e = this._renderer, n = e.autoClear;
        e.autoClear = !1;
        for(let i = 1; i < this._lodPlanes.length; i++){
            let r = Math.sqrt(this._sigmas[i] * this._sigmas[i] - this._sigmas[i - 1] * this._sigmas[i - 1]), a = sh[(i - 1) % sh.length];
            this._blur(t, i - 1, i, r, a);
        }
        e.autoClear = n;
    }
    _blur(t, e, n, i, r) {
        let a = this._pingPongRenderTarget;
        this._halfBlur(t, a, e, n, i, "latitudinal", r), this._halfBlur(a, t, n, n, i, "longitudinal", r);
    }
    _halfBlur(t, e, n, i, r, a, o) {
        let c = this._renderer, l = this._blurMaterial;
        a !== "latitudinal" && a !== "longitudinal" && console.error("blur direction must be either latitudinal or longitudinal!");
        let h = 3, u = new ve(this._lodPlanes[i], l), d = l.uniforms, f = this._sizeLods[n] - 1, m = isFinite(r) ? Math.PI / (2 * f) : 2 * Math.PI / (2 * jn - 1), x = r / m, g = isFinite(r) ? 1 + Math.floor(h * x) : jn;
        g > jn && console.warn(`sigmaRadians, ${r}, is too large and will clip, as it requested ${g} samples when the maximum is set to ${jn}`);
        let p = [], v = 0;
        for(let R = 0; R < jn; ++R){
            let L = R / x, M = Math.exp(-L * L / 2);
            p.push(M), R === 0 ? v += M : R < g && (v += 2 * M);
        }
        for(let R = 0; R < p.length; R++)p[R] = p[R] / v;
        d.envMap.value = t.texture, d.samples.value = g, d.weights.value = p, d.latitudinal.value = a === "latitudinal", o && (d.poleAxis.value = o);
        let { _lodMax: _  } = this;
        d.dTheta.value = m, d.mipInt.value = _ - n;
        let y = this._sizeLods[i], b = 3 * y * (i > _ - Hi ? i - _ + Hi : 0), w = 4 * (this._cubeSize - y);
        hr(e, b, w, 3 * y, 2 * y), c.setRenderTarget(e), c.render(u, Xa);
    }
};
function s_(s1) {
    let t = [], e = [], n = [], i = s1, r = s1 - Hi + 1 + nh.length;
    for(let a = 0; a < r; a++){
        let o = Math.pow(2, i);
        e.push(o);
        let c = 1 / o;
        a > s1 - Hi ? c = nh[a - s1 + Hi - 1] : a === 0 && (c = 0), n.push(c);
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
        ], f = 6, m = 6, x = 3, g = 2, p = 1, v = new Float32Array(x * m * f), _ = new Float32Array(g * m * f), y = new Float32Array(p * m * f);
        for(let w = 0; w < f; w++){
            let R = w % 3 * 2 / 3 - 1, L = w > 2 ? 0 : -1, M = [
                R,
                L,
                0,
                R + 2 / 3,
                L,
                0,
                R + 2 / 3,
                L + 1,
                0,
                R,
                L,
                0,
                R + 2 / 3,
                L + 1,
                0,
                R,
                L + 1,
                0
            ];
            v.set(M, x * m * w), _.set(d, g * m * w);
            let E = [
                w,
                w,
                w,
                w,
                w,
                w
            ];
            y.set(E, p * m * w);
        }
        let b = new Vt;
        b.setAttribute("position", new Kt(v, x)), b.setAttribute("uv", new Kt(_, g)), b.setAttribute("faceIndex", new Kt(y, p)), t.push(b), i > Hi && i--;
    }
    return {
        lodPlanes: t,
        sizeLods: e,
        sigmas: n
    };
}
function rh(s1, t, e) {
    let n = new Ge(s1, t, e);
    return n.texture.mapping = Hs, n.texture.name = "PMREM.cubeUv", n.scissorTest = !0, n;
}
function hr(s1, t, e, n, i) {
    s1.viewport.set(t, e, n, i), s1.scissor.set(t, e, n, i);
}
function r_(s1, t, e) {
    let n = new Float32Array(jn), i = new A(0, 1, 0);
    return new Qe({
        name: "SphericalGaussianBlur",
        defines: {
            n: jn,
            CUBEUV_TEXEL_WIDTH: 1 / t,
            CUBEUV_TEXEL_HEIGHT: 1 / e,
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
        vertexShader: Vc(),
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
        blending: Un,
        depthTest: !1,
        depthWrite: !1
    });
}
function ah() {
    return new Qe({
        name: "EquirectangularToCubeUV",
        uniforms: {
            envMap: {
                value: null
            }
        },
        vertexShader: Vc(),
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
        blending: Un,
        depthTest: !1,
        depthWrite: !1
    });
}
function oh() {
    return new Qe({
        name: "CubemapToCubeUV",
        uniforms: {
            envMap: {
                value: null
            },
            flipEnvMap: {
                value: -1
            }
        },
        vertexShader: Vc(),
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
        blending: Un,
        depthTest: !1,
        depthWrite: !1
    });
}
function Vc() {
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
function a_(s1) {
    let t = new WeakMap, e = null;
    function n(o) {
        if (o && o.isTexture) {
            let c = o.mapping, l = c === Ur || c === Dr, h = c === Bn || c === ci;
            if (l || h) if (o.isRenderTargetTexture && o.needsPMREMUpdate === !0) {
                o.needsPMREMUpdate = !1;
                let u = t.get(o);
                return e === null && (e = new Jr(s1)), u = l ? e.fromEquirectangular(o, u) : e.fromCubemap(o, u), t.set(o, u), u.texture;
            } else {
                if (t.has(o)) return t.get(o).texture;
                {
                    let u = o.image;
                    if (l && u && u.height > 0 || h && u && i(u)) {
                        e === null && (e = new Jr(s1));
                        let d = l ? e.fromEquirectangular(o) : e.fromCubemap(o);
                        return t.set(o, d), o.addEventListener("dispose", r), d.texture;
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
        let l = t.get(c);
        l !== void 0 && (t.delete(c), l.dispose());
    }
    function a() {
        t = new WeakMap, e !== null && (e.dispose(), e = null);
    }
    return {
        get: n,
        dispose: a
    };
}
function o_(s1) {
    let t = {};
    function e(n) {
        if (t[n] !== void 0) return t[n];
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
        return t[n] = i, i;
    }
    return {
        has: function(n) {
            return e(n) !== null;
        },
        init: function(n) {
            n.isWebGL2 ? e("EXT_color_buffer_float") : (e("WEBGL_depth_texture"), e("OES_texture_float"), e("OES_texture_half_float"), e("OES_texture_half_float_linear"), e("OES_standard_derivatives"), e("OES_element_index_uint"), e("OES_vertex_array_object"), e("ANGLE_instanced_arrays")), e("OES_texture_float_linear"), e("EXT_color_buffer_half_float"), e("WEBGL_multisampled_render_to_texture");
        },
        get: function(n) {
            let i = e(n);
            return i === null && console.warn("THREE.WebGLRenderer: " + n + " extension not supported."), i;
        }
    };
}
function c_(s1, t, e, n) {
    let i = {}, r = new WeakMap;
    function a(u) {
        let d = u.target;
        d.index !== null && t.remove(d.index);
        for(let m in d.attributes)t.remove(d.attributes[m]);
        for(let m in d.morphAttributes){
            let x = d.morphAttributes[m];
            for(let g = 0, p = x.length; g < p; g++)t.remove(x[g]);
        }
        d.removeEventListener("dispose", a), delete i[d.id];
        let f = r.get(d);
        f && (t.remove(f), r.delete(d)), n.releaseStatesOfGeometry(d), d.isInstancedBufferGeometry === !0 && delete d._maxInstanceCount, e.memory.geometries--;
    }
    function o(u, d) {
        return i[d.id] === !0 || (d.addEventListener("dispose", a), i[d.id] = !0, e.memory.geometries++), d;
    }
    function c(u) {
        let d = u.attributes;
        for(let m in d)t.update(d[m], s1.ARRAY_BUFFER);
        let f = u.morphAttributes;
        for(let m in f){
            let x = f[m];
            for(let g = 0, p = x.length; g < p; g++)t.update(x[g], s1.ARRAY_BUFFER);
        }
    }
    function l(u) {
        let d = [], f = u.index, m = u.attributes.position, x = 0;
        if (f !== null) {
            let v = f.array;
            x = f.version;
            for(let _ = 0, y = v.length; _ < y; _ += 3){
                let b = v[_ + 0], w = v[_ + 1], R = v[_ + 2];
                d.push(b, w, w, R, R, b);
            }
        } else if (m !== void 0) {
            let v = m.array;
            x = m.version;
            for(let _ = 0, y = v.length / 3 - 1; _ < y; _ += 3){
                let b = _ + 0, w = _ + 1, R = _ + 2;
                d.push(b, w, w, R, R, b);
            }
        } else return;
        let g = new (gd(d) ? Yr : qr)(d, 1);
        g.version = x;
        let p = r.get(u);
        p && t.remove(p), r.set(u, g);
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
function l_(s1, t, e, n) {
    let i = n.isWebGL2, r;
    function a(d) {
        r = d;
    }
    let o, c;
    function l(d) {
        o = d.type, c = d.bytesPerElement;
    }
    function h(d, f) {
        s1.drawElements(r, f, o, d * c), e.update(f, r, 1);
    }
    function u(d, f, m) {
        if (m === 0) return;
        let x, g;
        if (i) x = s1, g = "drawElementsInstanced";
        else if (x = t.get("ANGLE_instanced_arrays"), g = "drawElementsInstancedANGLE", x === null) {
            console.error("THREE.WebGLIndexedBufferRenderer: using THREE.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.");
            return;
        }
        x[g](r, f, o, d * c, m), e.update(f, r, m);
    }
    this.setMode = a, this.setIndex = l, this.render = h, this.renderInstances = u;
}
function h_(s1) {
    let t = {
        geometries: 0,
        textures: 0
    }, e = {
        frame: 0,
        calls: 0,
        triangles: 0,
        points: 0,
        lines: 0
    };
    function n(r, a, o) {
        switch(e.calls++, a){
            case s1.TRIANGLES:
                e.triangles += o * (r / 3);
                break;
            case s1.LINES:
                e.lines += o * (r / 2);
                break;
            case s1.LINE_STRIP:
                e.lines += o * (r - 1);
                break;
            case s1.LINE_LOOP:
                e.lines += o * r;
                break;
            case s1.POINTS:
                e.points += o * r;
                break;
            default:
                console.error("THREE.WebGLInfo: Unknown draw mode:", a);
                break;
        }
    }
    function i() {
        e.calls = 0, e.triangles = 0, e.points = 0, e.lines = 0;
    }
    return {
        memory: t,
        render: e,
        programs: null,
        autoReset: !0,
        reset: i,
        update: n
    };
}
function u_(s1, t) {
    return s1[0] - t[0];
}
function d_(s1, t) {
    return Math.abs(t[1]) - Math.abs(s1[1]);
}
function f_(s1, t, e) {
    let n = {}, i = new Float32Array(8), r = new WeakMap, a = new $t, o = [];
    for(let l = 0; l < 8; l++)o[l] = [
        l,
        0
    ];
    function c(l, h, u) {
        let d = l.morphTargetInfluences;
        if (t.isWebGL2 === !0) {
            let f = h.morphAttributes.position || h.morphAttributes.normal || h.morphAttributes.color, m = f !== void 0 ? f.length : 0, x = r.get(h);
            if (x === void 0 || x.count !== m) {
                let O = function() {
                    $.dispose(), r.delete(h), h.removeEventListener("dispose", O);
                };
                x !== void 0 && x.texture.dispose();
                let v = h.morphAttributes.position !== void 0, _ = h.morphAttributes.normal !== void 0, y = h.morphAttributes.color !== void 0, b = h.morphAttributes.position || [], w = h.morphAttributes.normal || [], R = h.morphAttributes.color || [], L = 0;
                v === !0 && (L = 1), _ === !0 && (L = 2), y === !0 && (L = 3);
                let M = h.attributes.position.count * L, E = 1;
                M > t.maxTextureSize && (E = Math.ceil(M / t.maxTextureSize), M = t.maxTextureSize);
                let V = new Float32Array(M * E * 4 * m), $ = new As(V, M, E, m);
                $.type = xn, $.needsUpdate = !0;
                let F = L * 4;
                for(let z = 0; z < m; z++){
                    let K = b[z], X = w[z], Y = R[z], j = M * E * 4 * z;
                    for(let tt = 0; tt < K.count; tt++){
                        let N = tt * F;
                        v === !0 && (a.fromBufferAttribute(K, tt), V[j + N + 0] = a.x, V[j + N + 1] = a.y, V[j + N + 2] = a.z, V[j + N + 3] = 0), _ === !0 && (a.fromBufferAttribute(X, tt), V[j + N + 4] = a.x, V[j + N + 5] = a.y, V[j + N + 6] = a.z, V[j + N + 7] = 0), y === !0 && (a.fromBufferAttribute(Y, tt), V[j + N + 8] = a.x, V[j + N + 9] = a.y, V[j + N + 10] = a.z, V[j + N + 11] = Y.itemSize === 4 ? a.w : 1);
                    }
                }
                x = {
                    count: m,
                    texture: $,
                    size: new J(M, E)
                }, r.set(h, x), h.addEventListener("dispose", O);
            }
            let g = 0;
            for(let v = 0; v < d.length; v++)g += d[v];
            let p = h.morphTargetsRelative ? 1 : 1 - g;
            u.getUniforms().setValue(s1, "morphTargetBaseInfluence", p), u.getUniforms().setValue(s1, "morphTargetInfluences", d), u.getUniforms().setValue(s1, "morphTargetsTexture", x.texture, e), u.getUniforms().setValue(s1, "morphTargetsTextureSize", x.size);
        } else {
            let f = d === void 0 ? 0 : d.length, m = n[h.id];
            if (m === void 0 || m.length !== f) {
                m = [];
                for(let _ = 0; _ < f; _++)m[_] = [
                    _,
                    0
                ];
                n[h.id] = m;
            }
            for(let _ = 0; _ < f; _++){
                let y = m[_];
                y[0] = _, y[1] = d[_];
            }
            m.sort(d_);
            for(let _ = 0; _ < 8; _++)_ < f && m[_][1] ? (o[_][0] = m[_][0], o[_][1] = m[_][1]) : (o[_][0] = Number.MAX_SAFE_INTEGER, o[_][1] = 0);
            o.sort(u_);
            let x = h.morphAttributes.position, g = h.morphAttributes.normal, p = 0;
            for(let _ = 0; _ < 8; _++){
                let y = o[_], b = y[0], w = y[1];
                b !== Number.MAX_SAFE_INTEGER && w ? (x && h.getAttribute("morphTarget" + _) !== x[b] && h.setAttribute("morphTarget" + _, x[b]), g && h.getAttribute("morphNormal" + _) !== g[b] && h.setAttribute("morphNormal" + _, g[b]), i[_] = w, p += w) : (x && h.hasAttribute("morphTarget" + _) === !0 && h.deleteAttribute("morphTarget" + _), g && h.hasAttribute("morphNormal" + _) === !0 && h.deleteAttribute("morphNormal" + _), i[_] = 0);
            }
            let v = h.morphTargetsRelative ? 1 : 1 - p;
            u.getUniforms().setValue(s1, "morphTargetBaseInfluence", v), u.getUniforms().setValue(s1, "morphTargetInfluences", i);
        }
    }
    return {
        update: c
    };
}
function p_(s1, t, e, n) {
    let i = new WeakMap;
    function r(c) {
        let l = n.render.frame, h = c.geometry, u = t.get(c, h);
        if (i.get(u) !== l && (t.update(u), i.set(u, l)), c.isInstancedMesh && (c.hasEventListener("dispose", o) === !1 && c.addEventListener("dispose", o), i.get(c) !== l && (e.update(c.instanceMatrix, s1.ARRAY_BUFFER), c.instanceColor !== null && e.update(c.instanceColor, s1.ARRAY_BUFFER), i.set(c, l))), c.isSkinnedMesh) {
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
        l.removeEventListener("dispose", o), e.remove(l.instanceMatrix), l.instanceColor !== null && e.remove(l.instanceColor);
    }
    return {
        update: r,
        dispose: a
    };
}
var yd = new ye, Md = new As, Sd = new Wr, bd = new Ki, ch = [], lh = [], hh = new Float32Array(16), uh = new Float32Array(9), dh = new Float32Array(4);
function as(s1, t, e) {
    let n = s1[0];
    if (n <= 0 || n > 0) return s1;
    let i = t * e, r = ch[i];
    if (r === void 0 && (r = new Float32Array(i), ch[i] = r), t !== 0) {
        n.toArray(r, 0);
        for(let a = 1, o = 0; a !== t; ++a)o += e, s1[a].toArray(r, o);
    }
    return r;
}
function me(s1, t) {
    if (s1.length !== t.length) return !1;
    for(let e = 0, n = s1.length; e < n; e++)if (s1[e] !== t[e]) return !1;
    return !0;
}
function ge(s1, t) {
    for(let e = 0, n = t.length; e < n; e++)s1[e] = t[e];
}
function ma(s1, t) {
    let e = lh[t];
    e === void 0 && (e = new Int32Array(t), lh[t] = e);
    for(let n = 0; n !== t; ++n)e[n] = s1.allocateTextureUnit();
    return e;
}
function m_(s1, t) {
    let e = this.cache;
    e[0] !== t && (s1.uniform1f(this.addr, t), e[0] = t);
}
function g_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y) && (s1.uniform2f(this.addr, t.x, t.y), e[0] = t.x, e[1] = t.y);
    else {
        if (me(e, t)) return;
        s1.uniform2fv(this.addr, t), ge(e, t);
    }
}
function __(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y || e[2] !== t.z) && (s1.uniform3f(this.addr, t.x, t.y, t.z), e[0] = t.x, e[1] = t.y, e[2] = t.z);
    else if (t.r !== void 0) (e[0] !== t.r || e[1] !== t.g || e[2] !== t.b) && (s1.uniform3f(this.addr, t.r, t.g, t.b), e[0] = t.r, e[1] = t.g, e[2] = t.b);
    else {
        if (me(e, t)) return;
        s1.uniform3fv(this.addr, t), ge(e, t);
    }
}
function x_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y || e[2] !== t.z || e[3] !== t.w) && (s1.uniform4f(this.addr, t.x, t.y, t.z, t.w), e[0] = t.x, e[1] = t.y, e[2] = t.z, e[3] = t.w);
    else {
        if (me(e, t)) return;
        s1.uniform4fv(this.addr, t), ge(e, t);
    }
}
function v_(s1, t) {
    let e = this.cache, n = t.elements;
    if (n === void 0) {
        if (me(e, t)) return;
        s1.uniformMatrix2fv(this.addr, !1, t), ge(e, t);
    } else {
        if (me(e, n)) return;
        dh.set(n), s1.uniformMatrix2fv(this.addr, !1, dh), ge(e, n);
    }
}
function y_(s1, t) {
    let e = this.cache, n = t.elements;
    if (n === void 0) {
        if (me(e, t)) return;
        s1.uniformMatrix3fv(this.addr, !1, t), ge(e, t);
    } else {
        if (me(e, n)) return;
        uh.set(n), s1.uniformMatrix3fv(this.addr, !1, uh), ge(e, n);
    }
}
function M_(s1, t) {
    let e = this.cache, n = t.elements;
    if (n === void 0) {
        if (me(e, t)) return;
        s1.uniformMatrix4fv(this.addr, !1, t), ge(e, t);
    } else {
        if (me(e, n)) return;
        hh.set(n), s1.uniformMatrix4fv(this.addr, !1, hh), ge(e, n);
    }
}
function S_(s1, t) {
    let e = this.cache;
    e[0] !== t && (s1.uniform1i(this.addr, t), e[0] = t);
}
function b_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y) && (s1.uniform2i(this.addr, t.x, t.y), e[0] = t.x, e[1] = t.y);
    else {
        if (me(e, t)) return;
        s1.uniform2iv(this.addr, t), ge(e, t);
    }
}
function E_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y || e[2] !== t.z) && (s1.uniform3i(this.addr, t.x, t.y, t.z), e[0] = t.x, e[1] = t.y, e[2] = t.z);
    else {
        if (me(e, t)) return;
        s1.uniform3iv(this.addr, t), ge(e, t);
    }
}
function T_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y || e[2] !== t.z || e[3] !== t.w) && (s1.uniform4i(this.addr, t.x, t.y, t.z, t.w), e[0] = t.x, e[1] = t.y, e[2] = t.z, e[3] = t.w);
    else {
        if (me(e, t)) return;
        s1.uniform4iv(this.addr, t), ge(e, t);
    }
}
function w_(s1, t) {
    let e = this.cache;
    e[0] !== t && (s1.uniform1ui(this.addr, t), e[0] = t);
}
function A_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y) && (s1.uniform2ui(this.addr, t.x, t.y), e[0] = t.x, e[1] = t.y);
    else {
        if (me(e, t)) return;
        s1.uniform2uiv(this.addr, t), ge(e, t);
    }
}
function R_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y || e[2] !== t.z) && (s1.uniform3ui(this.addr, t.x, t.y, t.z), e[0] = t.x, e[1] = t.y, e[2] = t.z);
    else {
        if (me(e, t)) return;
        s1.uniform3uiv(this.addr, t), ge(e, t);
    }
}
function C_(s1, t) {
    let e = this.cache;
    if (t.x !== void 0) (e[0] !== t.x || e[1] !== t.y || e[2] !== t.z || e[3] !== t.w) && (s1.uniform4ui(this.addr, t.x, t.y, t.z, t.w), e[0] = t.x, e[1] = t.y, e[2] = t.z, e[3] = t.w);
    else {
        if (me(e, t)) return;
        s1.uniform4uiv(this.addr, t), ge(e, t);
    }
}
function P_(s1, t, e) {
    let n = this.cache, i = e.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), e.setTexture2D(t || yd, i);
}
function L_(s1, t, e) {
    let n = this.cache, i = e.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), e.setTexture3D(t || Sd, i);
}
function I_(s1, t, e) {
    let n = this.cache, i = e.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), e.setTextureCube(t || bd, i);
}
function U_(s1, t, e) {
    let n = this.cache, i = e.allocateTextureUnit();
    n[0] !== i && (s1.uniform1i(this.addr, i), n[0] = i), e.setTexture2DArray(t || Md, i);
}
function D_(s1) {
    switch(s1){
        case 5126:
            return m_;
        case 35664:
            return g_;
        case 35665:
            return __;
        case 35666:
            return x_;
        case 35674:
            return v_;
        case 35675:
            return y_;
        case 35676:
            return M_;
        case 5124:
        case 35670:
            return S_;
        case 35667:
        case 35671:
            return b_;
        case 35668:
        case 35672:
            return E_;
        case 35669:
        case 35673:
            return T_;
        case 5125:
            return w_;
        case 36294:
            return A_;
        case 36295:
            return R_;
        case 36296:
            return C_;
        case 35678:
        case 36198:
        case 36298:
        case 36306:
        case 35682:
            return P_;
        case 35679:
        case 36299:
        case 36307:
            return L_;
        case 35680:
        case 36300:
        case 36308:
        case 36293:
            return I_;
        case 36289:
        case 36303:
        case 36311:
        case 36292:
            return U_;
    }
}
function N_(s1, t) {
    s1.uniform1fv(this.addr, t);
}
function F_(s1, t) {
    let e = as(t, this.size, 2);
    s1.uniform2fv(this.addr, e);
}
function O_(s1, t) {
    let e = as(t, this.size, 3);
    s1.uniform3fv(this.addr, e);
}
function B_(s1, t) {
    let e = as(t, this.size, 4);
    s1.uniform4fv(this.addr, e);
}
function z_(s1, t) {
    let e = as(t, this.size, 4);
    s1.uniformMatrix2fv(this.addr, !1, e);
}
function k_(s1, t) {
    let e = as(t, this.size, 9);
    s1.uniformMatrix3fv(this.addr, !1, e);
}
function V_(s1, t) {
    let e = as(t, this.size, 16);
    s1.uniformMatrix4fv(this.addr, !1, e);
}
function H_(s1, t) {
    s1.uniform1iv(this.addr, t);
}
function G_(s1, t) {
    s1.uniform2iv(this.addr, t);
}
function W_(s1, t) {
    s1.uniform3iv(this.addr, t);
}
function X_(s1, t) {
    s1.uniform4iv(this.addr, t);
}
function q_(s1, t) {
    s1.uniform1uiv(this.addr, t);
}
function Y_(s1, t) {
    s1.uniform2uiv(this.addr, t);
}
function Z_(s1, t) {
    s1.uniform3uiv(this.addr, t);
}
function J_(s1, t) {
    s1.uniform4uiv(this.addr, t);
}
function $_(s1, t, e) {
    let n = this.cache, i = t.length, r = ma(e, i);
    me(n, r) || (s1.uniform1iv(this.addr, r), ge(n, r));
    for(let a = 0; a !== i; ++a)e.setTexture2D(t[a] || yd, r[a]);
}
function K_(s1, t, e) {
    let n = this.cache, i = t.length, r = ma(e, i);
    me(n, r) || (s1.uniform1iv(this.addr, r), ge(n, r));
    for(let a = 0; a !== i; ++a)e.setTexture3D(t[a] || Sd, r[a]);
}
function Q_(s1, t, e) {
    let n = this.cache, i = t.length, r = ma(e, i);
    me(n, r) || (s1.uniform1iv(this.addr, r), ge(n, r));
    for(let a = 0; a !== i; ++a)e.setTextureCube(t[a] || bd, r[a]);
}
function j_(s1, t, e) {
    let n = this.cache, i = t.length, r = ma(e, i);
    me(n, r) || (s1.uniform1iv(this.addr, r), ge(n, r));
    for(let a = 0; a !== i; ++a)e.setTexture2DArray(t[a] || Md, r[a]);
}
function t0(s1) {
    switch(s1){
        case 5126:
            return N_;
        case 35664:
            return F_;
        case 35665:
            return O_;
        case 35666:
            return B_;
        case 35674:
            return z_;
        case 35675:
            return k_;
        case 35676:
            return V_;
        case 5124:
        case 35670:
            return H_;
        case 35667:
        case 35671:
            return G_;
        case 35668:
        case 35672:
            return W_;
        case 35669:
        case 35673:
            return X_;
        case 5125:
            return q_;
        case 36294:
            return Y_;
        case 36295:
            return Z_;
        case 36296:
            return J_;
        case 35678:
        case 36198:
        case 36298:
        case 36306:
        case 35682:
            return $_;
        case 35679:
        case 36299:
        case 36307:
            return K_;
        case 35680:
        case 36300:
        case 36308:
        case 36293:
            return Q_;
        case 36289:
        case 36303:
        case 36311:
        case 36292:
            return j_;
    }
}
var po = class {
    constructor(t, e, n){
        this.id = t, this.addr = n, this.cache = [], this.setValue = D_(e.type);
    }
}, mo = class {
    constructor(t, e, n){
        this.id = t, this.addr = n, this.cache = [], this.size = e.size, this.setValue = t0(e.type);
    }
}, go = class {
    constructor(t){
        this.id = t, this.seq = [], this.map = {};
    }
    setValue(t, e, n) {
        let i = this.seq;
        for(let r = 0, a = i.length; r !== a; ++r){
            let o = i[r];
            o.setValue(t, e[o.id], n);
        }
    }
}, Ya = /(\w+)(\])?(\[|\.)?/g;
function fh(s1, t) {
    s1.seq.push(t), s1.map[t.id] = t;
}
function e0(s1, t, e) {
    let n = s1.name, i = n.length;
    for(Ya.lastIndex = 0;;){
        let r = Ya.exec(n), a = Ya.lastIndex, o = r[1], c = r[2] === "]", l = r[3];
        if (c && (o = o | 0), l === void 0 || l === "[" && a + 2 === i) {
            fh(e, l === void 0 ? new po(o, s1, t) : new mo(o, s1, t));
            break;
        } else {
            let u = e.map[o];
            u === void 0 && (u = new go(o), fh(e, u)), e = u;
        }
    }
}
var qi = class {
    constructor(t, e){
        this.seq = [], this.map = {};
        let n = t.getProgramParameter(e, t.ACTIVE_UNIFORMS);
        for(let i = 0; i < n; ++i){
            let r = t.getActiveUniform(e, i), a = t.getUniformLocation(e, r.name);
            e0(r, a, this);
        }
    }
    setValue(t, e, n, i) {
        let r = this.map[e];
        r !== void 0 && r.setValue(t, n, i);
    }
    setOptional(t, e, n) {
        let i = e[n];
        i !== void 0 && this.setValue(t, n, i);
    }
    static upload(t, e, n, i) {
        for(let r = 0, a = e.length; r !== a; ++r){
            let o = e[r], c = n[o.id];
            c.needsUpdate !== !1 && o.setValue(t, c.value, i);
        }
    }
    static seqWithValue(t, e) {
        let n = [];
        for(let i = 0, r = t.length; i !== r; ++i){
            let a = t[i];
            a.id in e && n.push(a);
        }
        return n;
    }
};
function ph(s1, t, e) {
    let n = s1.createShader(t);
    return s1.shaderSource(n, e), s1.compileShader(n), n;
}
var n0 = 0;
function i0(s1, t) {
    let e = s1.split(`
`), n = [], i = Math.max(t - 6, 0), r = Math.min(t + 6, e.length);
    for(let a = i; a < r; a++){
        let o = a + 1;
        n.push(`${o === t ? ">" : " "} ${o}: ${e[a]}`);
    }
    return n.join(`
`);
}
function s0(s1) {
    switch(s1){
        case nn:
            return [
                "Linear",
                "( value )"
            ];
        case Nt:
            return [
                "sRGB",
                "( value )"
            ];
        default:
            return console.warn("THREE.WebGLProgram: Unsupported color space:", s1), [
                "Linear",
                "( value )"
            ];
    }
}
function mh(s1, t, e) {
    let n = s1.getShaderParameter(t, s1.COMPILE_STATUS), i = s1.getShaderInfoLog(t).trim();
    if (n && i === "") return "";
    let r = /ERROR: 0:(\d+)/.exec(i);
    if (r) {
        let a = parseInt(r[1]);
        return e.toUpperCase() + `

` + i + `

` + i0(s1.getShaderSource(t), a);
    } else return i;
}
function r0(s1, t) {
    let e = s0(t);
    return "vec4 " + s1 + "( vec4 value ) { return LinearTo" + e[0] + e[1] + "; }";
}
function a0(s1, t) {
    let e;
    switch(t){
        case af:
            e = "Linear";
            break;
        case of:
            e = "Reinhard";
            break;
        case cf:
            e = "OptimizedCineon";
            break;
        case lf:
            e = "ACESFilmic";
            break;
        case hf:
            e = "Custom";
            break;
        default:
            console.warn("THREE.WebGLProgram: Unsupported toneMapping:", t), e = "Linear";
    }
    return "vec3 " + s1 + "( vec3 color ) { return " + e + "ToneMapping( color ); }";
}
function o0(s1) {
    return [
        s1.extensionDerivatives || s1.envMapCubeUVHeight || s1.bumpMap || s1.normalMapTangentSpace || s1.clearcoatNormalMap || s1.flatShading || s1.shaderID === "physical" ? "#extension GL_OES_standard_derivatives : enable" : "",
        (s1.extensionFragDepth || s1.logarithmicDepthBuffer) && s1.rendererExtensionFragDepth ? "#extension GL_EXT_frag_depth : enable" : "",
        s1.extensionDrawBuffers && s1.rendererExtensionDrawBuffers ? "#extension GL_EXT_draw_buffers : require" : "",
        (s1.extensionShaderTextureLOD || s1.envMap || s1.transmission) && s1.rendererExtensionShaderTextureLod ? "#extension GL_EXT_shader_texture_lod : enable" : ""
    ].filter(vs).join(`
`);
}
function c0(s1) {
    let t = [];
    for(let e in s1){
        let n = s1[e];
        n !== !1 && t.push("#define " + e + " " + n);
    }
    return t.join(`
`);
}
function l0(s1, t) {
    let e = {}, n = s1.getProgramParameter(t, s1.ACTIVE_ATTRIBUTES);
    for(let i = 0; i < n; i++){
        let r = s1.getActiveAttrib(t, i), a = r.name, o = 1;
        r.type === s1.FLOAT_MAT2 && (o = 2), r.type === s1.FLOAT_MAT3 && (o = 3), r.type === s1.FLOAT_MAT4 && (o = 4), e[a] = {
            type: r.type,
            location: s1.getAttribLocation(t, a),
            locationSize: o
        };
    }
    return e;
}
function vs(s1) {
    return s1 !== "";
}
function gh(s1, t) {
    let e = t.numSpotLightShadows + t.numSpotLightMaps - t.numSpotLightShadowsWithMaps;
    return s1.replace(/NUM_DIR_LIGHTS/g, t.numDirLights).replace(/NUM_SPOT_LIGHTS/g, t.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g, t.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g, e).replace(/NUM_RECT_AREA_LIGHTS/g, t.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g, t.numPointLights).replace(/NUM_HEMI_LIGHTS/g, t.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g, t.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, t.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g, t.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g, t.numPointLightShadows);
}
function _h(s1, t) {
    return s1.replace(/NUM_CLIPPING_PLANES/g, t.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g, t.numClippingPlanes - t.numClipIntersection);
}
var h0 = /^[ \t]*#include +<([\w\d./]+)>/gm;
function _o(s1) {
    return s1.replace(h0, d0);
}
var u0 = new Map([
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
function d0(s1, t) {
    let e = zt[t];
    if (e === void 0) {
        let n = u0.get(t);
        if (n !== void 0) e = zt[n], console.warn('THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.', t, n);
        else throw new Error("Can not resolve #include <" + t + ">");
    }
    return _o(e);
}
var f0 = /#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;
function xh(s1) {
    return s1.replace(f0, p0);
}
function p0(s1, t, e, n) {
    let i = "";
    for(let r = parseInt(t); r < parseInt(e); r++)i += n.replace(/\[\s*i\s*\]/g, "[ " + r + " ]").replace(/UNROLLED_LOOP_INDEX/g, r);
    return i;
}
function vh(s1) {
    let t = "precision " + s1.precision + ` float;
precision ` + s1.precision + " int;";
    return s1.precision === "highp" ? t += `
#define HIGH_PRECISION` : s1.precision === "mediump" ? t += `
#define MEDIUM_PRECISION` : s1.precision === "lowp" && (t += `
#define LOW_PRECISION`), t;
}
function m0(s1) {
    let t = "SHADOWMAP_TYPE_BASIC";
    return s1.shadowMapType === nd ? t = "SHADOWMAP_TYPE_PCF" : s1.shadowMapType === Od ? t = "SHADOWMAP_TYPE_PCF_SOFT" : s1.shadowMapType === pn && (t = "SHADOWMAP_TYPE_VSM"), t;
}
function g0(s1) {
    let t = "ENVMAP_TYPE_CUBE";
    if (s1.envMap) switch(s1.envMapMode){
        case Bn:
        case ci:
            t = "ENVMAP_TYPE_CUBE";
            break;
        case Hs:
            t = "ENVMAP_TYPE_CUBE_UV";
            break;
    }
    return t;
}
function _0(s1) {
    let t = "ENVMAP_MODE_REFLECTION";
    if (s1.envMap) switch(s1.envMapMode){
        case ci:
            t = "ENVMAP_MODE_REFRACTION";
            break;
    }
    return t;
}
function x0(s1) {
    let t = "ENVMAP_BLENDING_NONE";
    if (s1.envMap) switch(s1.combine){
        case pa:
            t = "ENVMAP_BLENDING_MULTIPLY";
            break;
        case sf:
            t = "ENVMAP_BLENDING_MIX";
            break;
        case rf:
            t = "ENVMAP_BLENDING_ADD";
            break;
    }
    return t;
}
function v0(s1) {
    let t = s1.envMapCubeUVHeight;
    if (t === null) return null;
    let e = Math.log2(t) - 2, n = 1 / t;
    return {
        texelWidth: 1 / (3 * Math.max(Math.pow(2, e), 7 * 16)),
        texelHeight: n,
        maxMip: e
    };
}
function y0(s1, t, e, n) {
    let i = s1.getContext(), r = e.defines, a = e.vertexShader, o = e.fragmentShader, c = m0(e), l = g0(e), h = _0(e), u = x0(e), d = v0(e), f = e.isWebGL2 ? "" : o0(e), m = c0(r), x = i.createProgram(), g, p, v = e.glslVersion ? "#version " + e.glslVersion + `
` : "";
    e.isRawShaderMaterial ? (g = [
        "#define SHADER_TYPE " + e.shaderType,
        "#define SHADER_NAME " + e.shaderName,
        m
    ].filter(vs).join(`
`), g.length > 0 && (g += `
`), p = [
        f,
        "#define SHADER_TYPE " + e.shaderType,
        "#define SHADER_NAME " + e.shaderName,
        m
    ].filter(vs).join(`
`), p.length > 0 && (p += `
`)) : (g = [
        vh(e),
        "#define SHADER_TYPE " + e.shaderType,
        "#define SHADER_NAME " + e.shaderName,
        m,
        e.instancing ? "#define USE_INSTANCING" : "",
        e.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
        e.useFog && e.fog ? "#define USE_FOG" : "",
        e.useFog && e.fogExp2 ? "#define FOG_EXP2" : "",
        e.map ? "#define USE_MAP" : "",
        e.envMap ? "#define USE_ENVMAP" : "",
        e.envMap ? "#define " + h : "",
        e.lightMap ? "#define USE_LIGHTMAP" : "",
        e.aoMap ? "#define USE_AOMAP" : "",
        e.bumpMap ? "#define USE_BUMPMAP" : "",
        e.normalMap ? "#define USE_NORMALMAP" : "",
        e.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
        e.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
        e.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
        e.emissiveMap ? "#define USE_EMISSIVEMAP" : "",
        e.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",
        e.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
        e.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
        e.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",
        e.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
        e.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",
        e.specularMap ? "#define USE_SPECULARMAP" : "",
        e.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
        e.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",
        e.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
        e.metalnessMap ? "#define USE_METALNESSMAP" : "",
        e.alphaMap ? "#define USE_ALPHAMAP" : "",
        e.alphaHash ? "#define USE_ALPHAHASH" : "",
        e.transmission ? "#define USE_TRANSMISSION" : "",
        e.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
        e.thicknessMap ? "#define USE_THICKNESSMAP" : "",
        e.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
        e.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",
        e.mapUv ? "#define MAP_UV " + e.mapUv : "",
        e.alphaMapUv ? "#define ALPHAMAP_UV " + e.alphaMapUv : "",
        e.lightMapUv ? "#define LIGHTMAP_UV " + e.lightMapUv : "",
        e.aoMapUv ? "#define AOMAP_UV " + e.aoMapUv : "",
        e.emissiveMapUv ? "#define EMISSIVEMAP_UV " + e.emissiveMapUv : "",
        e.bumpMapUv ? "#define BUMPMAP_UV " + e.bumpMapUv : "",
        e.normalMapUv ? "#define NORMALMAP_UV " + e.normalMapUv : "",
        e.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + e.displacementMapUv : "",
        e.metalnessMapUv ? "#define METALNESSMAP_UV " + e.metalnessMapUv : "",
        e.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + e.roughnessMapUv : "",
        e.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + e.anisotropyMapUv : "",
        e.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + e.clearcoatMapUv : "",
        e.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + e.clearcoatNormalMapUv : "",
        e.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + e.clearcoatRoughnessMapUv : "",
        e.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + e.iridescenceMapUv : "",
        e.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + e.iridescenceThicknessMapUv : "",
        e.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + e.sheenColorMapUv : "",
        e.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + e.sheenRoughnessMapUv : "",
        e.specularMapUv ? "#define SPECULARMAP_UV " + e.specularMapUv : "",
        e.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + e.specularColorMapUv : "",
        e.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + e.specularIntensityMapUv : "",
        e.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + e.transmissionMapUv : "",
        e.thicknessMapUv ? "#define THICKNESSMAP_UV " + e.thicknessMapUv : "",
        e.vertexTangents && e.flatShading === !1 ? "#define USE_TANGENT" : "",
        e.vertexColors ? "#define USE_COLOR" : "",
        e.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
        e.vertexUv1s ? "#define USE_UV1" : "",
        e.vertexUv2s ? "#define USE_UV2" : "",
        e.vertexUv3s ? "#define USE_UV3" : "",
        e.pointsUvs ? "#define USE_POINTS_UV" : "",
        e.flatShading ? "#define FLAT_SHADED" : "",
        e.skinning ? "#define USE_SKINNING" : "",
        e.morphTargets ? "#define USE_MORPHTARGETS" : "",
        e.morphNormals && e.flatShading === !1 ? "#define USE_MORPHNORMALS" : "",
        e.morphColors && e.isWebGL2 ? "#define USE_MORPHCOLORS" : "",
        e.morphTargetsCount > 0 && e.isWebGL2 ? "#define MORPHTARGETS_TEXTURE" : "",
        e.morphTargetsCount > 0 && e.isWebGL2 ? "#define MORPHTARGETS_TEXTURE_STRIDE " + e.morphTextureStride : "",
        e.morphTargetsCount > 0 && e.isWebGL2 ? "#define MORPHTARGETS_COUNT " + e.morphTargetsCount : "",
        e.doubleSided ? "#define DOUBLE_SIDED" : "",
        e.flipSided ? "#define FLIP_SIDED" : "",
        e.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
        e.shadowMapEnabled ? "#define " + c : "",
        e.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",
        e.useLegacyLights ? "#define LEGACY_LIGHTS" : "",
        e.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",
        e.logarithmicDepthBuffer && e.rendererExtensionFragDepth ? "#define USE_LOGDEPTHBUF_EXT" : "",
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
        vh(e),
        "#define SHADER_TYPE " + e.shaderType,
        "#define SHADER_NAME " + e.shaderName,
        m,
        e.useFog && e.fog ? "#define USE_FOG" : "",
        e.useFog && e.fogExp2 ? "#define FOG_EXP2" : "",
        e.map ? "#define USE_MAP" : "",
        e.matcap ? "#define USE_MATCAP" : "",
        e.envMap ? "#define USE_ENVMAP" : "",
        e.envMap ? "#define " + l : "",
        e.envMap ? "#define " + h : "",
        e.envMap ? "#define " + u : "",
        d ? "#define CUBEUV_TEXEL_WIDTH " + d.texelWidth : "",
        d ? "#define CUBEUV_TEXEL_HEIGHT " + d.texelHeight : "",
        d ? "#define CUBEUV_MAX_MIP " + d.maxMip + ".0" : "",
        e.lightMap ? "#define USE_LIGHTMAP" : "",
        e.aoMap ? "#define USE_AOMAP" : "",
        e.bumpMap ? "#define USE_BUMPMAP" : "",
        e.normalMap ? "#define USE_NORMALMAP" : "",
        e.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
        e.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
        e.emissiveMap ? "#define USE_EMISSIVEMAP" : "",
        e.anisotropy ? "#define USE_ANISOTROPY" : "",
        e.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",
        e.clearcoat ? "#define USE_CLEARCOAT" : "",
        e.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
        e.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
        e.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",
        e.iridescence ? "#define USE_IRIDESCENCE" : "",
        e.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
        e.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",
        e.specularMap ? "#define USE_SPECULARMAP" : "",
        e.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
        e.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",
        e.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
        e.metalnessMap ? "#define USE_METALNESSMAP" : "",
        e.alphaMap ? "#define USE_ALPHAMAP" : "",
        e.alphaTest ? "#define USE_ALPHATEST" : "",
        e.alphaHash ? "#define USE_ALPHAHASH" : "",
        e.sheen ? "#define USE_SHEEN" : "",
        e.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
        e.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",
        e.transmission ? "#define USE_TRANSMISSION" : "",
        e.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
        e.thicknessMap ? "#define USE_THICKNESSMAP" : "",
        e.vertexTangents && e.flatShading === !1 ? "#define USE_TANGENT" : "",
        e.vertexColors || e.instancingColor ? "#define USE_COLOR" : "",
        e.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
        e.vertexUv1s ? "#define USE_UV1" : "",
        e.vertexUv2s ? "#define USE_UV2" : "",
        e.vertexUv3s ? "#define USE_UV3" : "",
        e.pointsUvs ? "#define USE_POINTS_UV" : "",
        e.gradientMap ? "#define USE_GRADIENTMAP" : "",
        e.flatShading ? "#define FLAT_SHADED" : "",
        e.doubleSided ? "#define DOUBLE_SIDED" : "",
        e.flipSided ? "#define FLIP_SIDED" : "",
        e.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
        e.shadowMapEnabled ? "#define " + c : "",
        e.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",
        e.useLegacyLights ? "#define LEGACY_LIGHTS" : "",
        e.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",
        e.logarithmicDepthBuffer && e.rendererExtensionFragDepth ? "#define USE_LOGDEPTHBUF_EXT" : "",
        "uniform mat4 viewMatrix;",
        "uniform vec3 cameraPosition;",
        "uniform bool isOrthographic;",
        e.toneMapping !== Dn ? "#define TONE_MAPPING" : "",
        e.toneMapping !== Dn ? zt.tonemapping_pars_fragment : "",
        e.toneMapping !== Dn ? a0("toneMapping", e.toneMapping) : "",
        e.dithering ? "#define DITHERING" : "",
        e.opaque ? "#define OPAQUE" : "",
        zt.colorspace_pars_fragment,
        r0("linearToOutputTexel", e.outputColorSpace),
        e.useDepthPacking ? "#define DEPTH_PACKING " + e.depthPacking : "",
        `
`
    ].filter(vs).join(`
`)), a = _o(a), a = gh(a, e), a = _h(a, e), o = _o(o), o = gh(o, e), o = _h(o, e), a = xh(a), o = xh(o), e.isWebGL2 && e.isRawShaderMaterial !== !0 && (v = `#version 300 es
`, g = [
        "precision mediump sampler2DArray;",
        "#define attribute in",
        "#define varying out",
        "#define texture2D texture"
    ].join(`
`) + `
` + g, p = [
        "#define varying in",
        e.glslVersion === Cl ? "" : "layout(location = 0) out highp vec4 pc_fragColor;",
        e.glslVersion === Cl ? "" : "#define gl_FragColor pc_fragColor",
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
    let _ = v + g + a, y = v + p + o, b = ph(i, i.VERTEX_SHADER, _), w = ph(i, i.FRAGMENT_SHADER, y);
    if (i.attachShader(x, b), i.attachShader(x, w), e.index0AttributeName !== void 0 ? i.bindAttribLocation(x, 0, e.index0AttributeName) : e.morphTargets === !0 && i.bindAttribLocation(x, 0, "position"), i.linkProgram(x), s1.debug.checkShaderErrors) {
        let M = i.getProgramInfoLog(x).trim(), E = i.getShaderInfoLog(b).trim(), V = i.getShaderInfoLog(w).trim(), $ = !0, F = !0;
        if (i.getProgramParameter(x, i.LINK_STATUS) === !1) if ($ = !1, typeof s1.debug.onShaderError == "function") s1.debug.onShaderError(i, x, b, w);
        else {
            let O = mh(i, b, "vertex"), z = mh(i, w, "fragment");
            console.error("THREE.WebGLProgram: Shader Error " + i.getError() + " - VALIDATE_STATUS " + i.getProgramParameter(x, i.VALIDATE_STATUS) + `

Program Info Log: ` + M + `
` + O + `
` + z);
        }
        else M !== "" ? console.warn("THREE.WebGLProgram: Program Info Log:", M) : (E === "" || V === "") && (F = !1);
        F && (this.diagnostics = {
            runnable: $,
            programLog: M,
            vertexShader: {
                log: E,
                prefix: g
            },
            fragmentShader: {
                log: V,
                prefix: p
            }
        });
    }
    i.deleteShader(b), i.deleteShader(w);
    let R;
    this.getUniforms = function() {
        return R === void 0 && (R = new qi(i, x)), R;
    };
    let L;
    return this.getAttributes = function() {
        return L === void 0 && (L = l0(i, x)), L;
    }, this.destroy = function() {
        n.releaseStatesOfProgram(this), i.deleteProgram(x), this.program = void 0;
    }, this.type = e.shaderType, this.name = e.shaderName, this.id = n0++, this.cacheKey = t, this.usedTimes = 1, this.program = x, this.vertexShader = b, this.fragmentShader = w, this;
}
var M0 = 0, xo = class {
    constructor(){
        this.shaderCache = new Map, this.materialCache = new Map;
    }
    update(t) {
        let e = t.vertexShader, n = t.fragmentShader, i = this._getShaderStage(e), r = this._getShaderStage(n), a = this._getShaderCacheForMaterial(t);
        return a.has(i) === !1 && (a.add(i), i.usedTimes++), a.has(r) === !1 && (a.add(r), r.usedTimes++), this;
    }
    remove(t) {
        let e = this.materialCache.get(t);
        for (let n of e)n.usedTimes--, n.usedTimes === 0 && this.shaderCache.delete(n.code);
        return this.materialCache.delete(t), this;
    }
    getVertexShaderID(t) {
        return this._getShaderStage(t.vertexShader).id;
    }
    getFragmentShaderID(t) {
        return this._getShaderStage(t.fragmentShader).id;
    }
    dispose() {
        this.shaderCache.clear(), this.materialCache.clear();
    }
    _getShaderCacheForMaterial(t) {
        let e = this.materialCache, n = e.get(t);
        return n === void 0 && (n = new Set, e.set(t, n)), n;
    }
    _getShaderStage(t) {
        let e = this.shaderCache, n = e.get(t);
        return n === void 0 && (n = new vo(t), e.set(t, n)), n;
    }
}, vo = class {
    constructor(t){
        this.id = M0++, this.code = t, this.usedTimes = 0;
    }
};
function S0(s1, t, e, n, i, r, a) {
    let o = new Rs, c = new xo, l = [], h = i.isWebGL2, u = i.logarithmicDepthBuffer, d = i.vertexTextures, f = i.precision, m = {
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
    function x(M) {
        return M === 0 ? "uv" : `uv${M}`;
    }
    function g(M, E, V, $, F) {
        let O = $.fog, z = F.geometry, K = M.isMeshStandardMaterial ? $.environment : null, X = (M.isMeshStandardMaterial ? e : t).get(M.envMap || K), Y = X && X.mapping === Hs ? X.image.height : null, j = m[M.type];
        M.precision !== null && (f = i.getMaxPrecision(M.precision), f !== M.precision && console.warn("THREE.WebGLProgram.getParameters:", M.precision, "not supported, using", f, "instead."));
        let tt = z.morphAttributes.position || z.morphAttributes.normal || z.morphAttributes.color, N = tt !== void 0 ? tt.length : 0, q = 0;
        z.morphAttributes.position !== void 0 && (q = 1), z.morphAttributes.normal !== void 0 && (q = 2), z.morphAttributes.color !== void 0 && (q = 3);
        let lt, ut, pt, Et;
        if (j) {
            let jt = en[j];
            lt = jt.vertexShader, ut = jt.fragmentShader;
        } else lt = M.vertexShader, ut = M.fragmentShader, c.update(M), pt = c.getVertexShaderID(M), Et = c.getFragmentShaderID(M);
        let Tt = s1.getRenderTarget(), wt = F.isInstancedMesh === !0, Yt = !!M.map, te = !!M.matcap, Pt = !!X, P = !!M.aoMap, at = !!M.lightMap, Z = !!M.bumpMap, st = !!M.normalMap, Q = !!M.displacementMap, St = !!M.emissiveMap, mt = !!M.metalnessMap, xt = !!M.roughnessMap, Dt = M.anisotropy > 0, Xt = M.clearcoat > 0, ie = M.iridescence > 0, C = M.sheen > 0, S = M.transmission > 0, B = Dt && !!M.anisotropyMap, nt = Xt && !!M.clearcoatMap, et = Xt && !!M.clearcoatNormalMap, it = Xt && !!M.clearcoatRoughnessMap, Mt = ie && !!M.iridescenceMap, rt = ie && !!M.iridescenceThicknessMap, k = C && !!M.sheenColorMap, Rt = C && !!M.sheenRoughnessMap, bt = !!M.specularMap, At = !!M.specularColorMap, vt = !!M.specularIntensityMap, yt = S && !!M.transmissionMap, Ht = S && !!M.thicknessMap, Qt = !!M.gradientMap, I = !!M.alphaMap, ht = M.alphaTest > 0, H = !!M.alphaHash, ot = !!M.extensions, dt = !!z.attributes.uv1, qt = !!z.attributes.uv2, ee = !!z.attributes.uv3, le = Dn;
        return M.toneMapped && (Tt === null || Tt.isXRRenderTarget === !0) && (le = s1.toneMapping), {
            isWebGL2: h,
            shaderID: j,
            shaderType: M.type,
            shaderName: M.name,
            vertexShader: lt,
            fragmentShader: ut,
            defines: M.defines,
            customVertexShaderID: pt,
            customFragmentShaderID: Et,
            isRawShaderMaterial: M.isRawShaderMaterial === !0,
            glslVersion: M.glslVersion,
            precision: f,
            instancing: wt,
            instancingColor: wt && F.instanceColor !== null,
            supportsVertexTextures: d,
            outputColorSpace: Tt === null ? s1.outputColorSpace : Tt.isXRRenderTarget === !0 ? Tt.texture.colorSpace : nn,
            map: Yt,
            matcap: te,
            envMap: Pt,
            envMapMode: Pt && X.mapping,
            envMapCubeUVHeight: Y,
            aoMap: P,
            lightMap: at,
            bumpMap: Z,
            normalMap: st,
            displacementMap: d && Q,
            emissiveMap: St,
            normalMapObjectSpace: st && M.normalMapType === Tf,
            normalMapTangentSpace: st && M.normalMapType === mi,
            metalnessMap: mt,
            roughnessMap: xt,
            anisotropy: Dt,
            anisotropyMap: B,
            clearcoat: Xt,
            clearcoatMap: nt,
            clearcoatNormalMap: et,
            clearcoatRoughnessMap: it,
            iridescence: ie,
            iridescenceMap: Mt,
            iridescenceThicknessMap: rt,
            sheen: C,
            sheenColorMap: k,
            sheenRoughnessMap: Rt,
            specularMap: bt,
            specularColorMap: At,
            specularIntensityMap: vt,
            transmission: S,
            transmissionMap: yt,
            thicknessMap: Ht,
            gradientMap: Qt,
            opaque: M.transparent === !1 && M.blending === Wi,
            alphaMap: I,
            alphaTest: ht,
            alphaHash: H,
            combine: M.combine,
            mapUv: Yt && x(M.map.channel),
            aoMapUv: P && x(M.aoMap.channel),
            lightMapUv: at && x(M.lightMap.channel),
            bumpMapUv: Z && x(M.bumpMap.channel),
            normalMapUv: st && x(M.normalMap.channel),
            displacementMapUv: Q && x(M.displacementMap.channel),
            emissiveMapUv: St && x(M.emissiveMap.channel),
            metalnessMapUv: mt && x(M.metalnessMap.channel),
            roughnessMapUv: xt && x(M.roughnessMap.channel),
            anisotropyMapUv: B && x(M.anisotropyMap.channel),
            clearcoatMapUv: nt && x(M.clearcoatMap.channel),
            clearcoatNormalMapUv: et && x(M.clearcoatNormalMap.channel),
            clearcoatRoughnessMapUv: it && x(M.clearcoatRoughnessMap.channel),
            iridescenceMapUv: Mt && x(M.iridescenceMap.channel),
            iridescenceThicknessMapUv: rt && x(M.iridescenceThicknessMap.channel),
            sheenColorMapUv: k && x(M.sheenColorMap.channel),
            sheenRoughnessMapUv: Rt && x(M.sheenRoughnessMap.channel),
            specularMapUv: bt && x(M.specularMap.channel),
            specularColorMapUv: At && x(M.specularColorMap.channel),
            specularIntensityMapUv: vt && x(M.specularIntensityMap.channel),
            transmissionMapUv: yt && x(M.transmissionMap.channel),
            thicknessMapUv: Ht && x(M.thicknessMap.channel),
            alphaMapUv: I && x(M.alphaMap.channel),
            vertexTangents: !!z.attributes.tangent && (st || Dt),
            vertexColors: M.vertexColors,
            vertexAlphas: M.vertexColors === !0 && !!z.attributes.color && z.attributes.color.itemSize === 4,
            vertexUv1s: dt,
            vertexUv2s: qt,
            vertexUv3s: ee,
            pointsUvs: F.isPoints === !0 && !!z.attributes.uv && (Yt || I),
            fog: !!O,
            useFog: M.fog === !0,
            fogExp2: O && O.isFogExp2,
            flatShading: M.flatShading === !0,
            sizeAttenuation: M.sizeAttenuation === !0,
            logarithmicDepthBuffer: u,
            skinning: F.isSkinnedMesh === !0,
            morphTargets: z.morphAttributes.position !== void 0,
            morphNormals: z.morphAttributes.normal !== void 0,
            morphColors: z.morphAttributes.color !== void 0,
            morphTargetsCount: N,
            morphTextureStride: q,
            numDirLights: E.directional.length,
            numPointLights: E.point.length,
            numSpotLights: E.spot.length,
            numSpotLightMaps: E.spotLightMap.length,
            numRectAreaLights: E.rectArea.length,
            numHemiLights: E.hemi.length,
            numDirLightShadows: E.directionalShadowMap.length,
            numPointLightShadows: E.pointShadowMap.length,
            numSpotLightShadows: E.spotShadowMap.length,
            numSpotLightShadowsWithMaps: E.numSpotLightShadowsWithMaps,
            numClippingPlanes: a.numPlanes,
            numClipIntersection: a.numIntersection,
            dithering: M.dithering,
            shadowMapEnabled: s1.shadowMap.enabled && V.length > 0,
            shadowMapType: s1.shadowMap.type,
            toneMapping: le,
            useLegacyLights: s1._useLegacyLights,
            premultipliedAlpha: M.premultipliedAlpha,
            doubleSided: M.side === gn,
            flipSided: M.side === De,
            useDepthPacking: M.depthPacking >= 0,
            depthPacking: M.depthPacking || 0,
            index0AttributeName: M.index0AttributeName,
            extensionDerivatives: ot && M.extensions.derivatives === !0,
            extensionFragDepth: ot && M.extensions.fragDepth === !0,
            extensionDrawBuffers: ot && M.extensions.drawBuffers === !0,
            extensionShaderTextureLOD: ot && M.extensions.shaderTextureLOD === !0,
            rendererExtensionFragDepth: h || n.has("EXT_frag_depth"),
            rendererExtensionDrawBuffers: h || n.has("WEBGL_draw_buffers"),
            rendererExtensionShaderTextureLod: h || n.has("EXT_shader_texture_lod"),
            customProgramCacheKey: M.customProgramCacheKey()
        };
    }
    function p(M) {
        let E = [];
        if (M.shaderID ? E.push(M.shaderID) : (E.push(M.customVertexShaderID), E.push(M.customFragmentShaderID)), M.defines !== void 0) for(let V in M.defines)E.push(V), E.push(M.defines[V]);
        return M.isRawShaderMaterial === !1 && (v(E, M), _(E, M), E.push(s1.outputColorSpace)), E.push(M.customProgramCacheKey), E.join();
    }
    function v(M, E) {
        M.push(E.precision), M.push(E.outputColorSpace), M.push(E.envMapMode), M.push(E.envMapCubeUVHeight), M.push(E.mapUv), M.push(E.alphaMapUv), M.push(E.lightMapUv), M.push(E.aoMapUv), M.push(E.bumpMapUv), M.push(E.normalMapUv), M.push(E.displacementMapUv), M.push(E.emissiveMapUv), M.push(E.metalnessMapUv), M.push(E.roughnessMapUv), M.push(E.anisotropyMapUv), M.push(E.clearcoatMapUv), M.push(E.clearcoatNormalMapUv), M.push(E.clearcoatRoughnessMapUv), M.push(E.iridescenceMapUv), M.push(E.iridescenceThicknessMapUv), M.push(E.sheenColorMapUv), M.push(E.sheenRoughnessMapUv), M.push(E.specularMapUv), M.push(E.specularColorMapUv), M.push(E.specularIntensityMapUv), M.push(E.transmissionMapUv), M.push(E.thicknessMapUv), M.push(E.combine), M.push(E.fogExp2), M.push(E.sizeAttenuation), M.push(E.morphTargetsCount), M.push(E.morphAttributeCount), M.push(E.numDirLights), M.push(E.numPointLights), M.push(E.numSpotLights), M.push(E.numSpotLightMaps), M.push(E.numHemiLights), M.push(E.numRectAreaLights), M.push(E.numDirLightShadows), M.push(E.numPointLightShadows), M.push(E.numSpotLightShadows), M.push(E.numSpotLightShadowsWithMaps), M.push(E.shadowMapType), M.push(E.toneMapping), M.push(E.numClippingPlanes), M.push(E.numClipIntersection), M.push(E.depthPacking);
    }
    function _(M, E) {
        o.disableAll(), E.isWebGL2 && o.enable(0), E.supportsVertexTextures && o.enable(1), E.instancing && o.enable(2), E.instancingColor && o.enable(3), E.matcap && o.enable(4), E.envMap && o.enable(5), E.normalMapObjectSpace && o.enable(6), E.normalMapTangentSpace && o.enable(7), E.clearcoat && o.enable(8), E.iridescence && o.enable(9), E.alphaTest && o.enable(10), E.vertexColors && o.enable(11), E.vertexAlphas && o.enable(12), E.vertexUv1s && o.enable(13), E.vertexUv2s && o.enable(14), E.vertexUv3s && o.enable(15), E.vertexTangents && o.enable(16), E.anisotropy && o.enable(17), M.push(o.mask), o.disableAll(), E.fog && o.enable(0), E.useFog && o.enable(1), E.flatShading && o.enable(2), E.logarithmicDepthBuffer && o.enable(3), E.skinning && o.enable(4), E.morphTargets && o.enable(5), E.morphNormals && o.enable(6), E.morphColors && o.enable(7), E.premultipliedAlpha && o.enable(8), E.shadowMapEnabled && o.enable(9), E.useLegacyLights && o.enable(10), E.doubleSided && o.enable(11), E.flipSided && o.enable(12), E.useDepthPacking && o.enable(13), E.dithering && o.enable(14), E.transmission && o.enable(15), E.sheen && o.enable(16), E.opaque && o.enable(17), E.pointsUvs && o.enable(18), M.push(o.mask);
    }
    function y(M) {
        let E = m[M.type], V;
        if (E) {
            let $ = en[E];
            V = mp.clone($.uniforms);
        } else V = M.uniforms;
        return V;
    }
    function b(M, E) {
        let V;
        for(let $ = 0, F = l.length; $ < F; $++){
            let O = l[$];
            if (O.cacheKey === E) {
                V = O, ++V.usedTimes;
                break;
            }
        }
        return V === void 0 && (V = new y0(s1, E, M, r), l.push(V)), V;
    }
    function w(M) {
        if (--M.usedTimes === 0) {
            let E = l.indexOf(M);
            l[E] = l[l.length - 1], l.pop(), M.destroy();
        }
    }
    function R(M) {
        c.remove(M);
    }
    function L() {
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
        dispose: L
    };
}
function b0() {
    let s1 = new WeakMap;
    function t(r) {
        let a = s1.get(r);
        return a === void 0 && (a = {}, s1.set(r, a)), a;
    }
    function e(r) {
        s1.delete(r);
    }
    function n(r, a, o) {
        s1.get(r)[a] = o;
    }
    function i() {
        s1 = new WeakMap;
    }
    return {
        get: t,
        remove: e,
        update: n,
        dispose: i
    };
}
function E0(s1, t) {
    return s1.groupOrder !== t.groupOrder ? s1.groupOrder - t.groupOrder : s1.renderOrder !== t.renderOrder ? s1.renderOrder - t.renderOrder : s1.material.id !== t.material.id ? s1.material.id - t.material.id : s1.z !== t.z ? s1.z - t.z : s1.id - t.id;
}
function yh(s1, t) {
    return s1.groupOrder !== t.groupOrder ? s1.groupOrder - t.groupOrder : s1.renderOrder !== t.renderOrder ? s1.renderOrder - t.renderOrder : s1.z !== t.z ? t.z - s1.z : s1.id - t.id;
}
function Mh() {
    let s1 = [], t = 0, e = [], n = [], i = [];
    function r() {
        t = 0, e.length = 0, n.length = 0, i.length = 0;
    }
    function a(u, d, f, m, x, g) {
        let p = s1[t];
        return p === void 0 ? (p = {
            id: u.id,
            object: u,
            geometry: d,
            material: f,
            groupOrder: m,
            renderOrder: u.renderOrder,
            z: x,
            group: g
        }, s1[t] = p) : (p.id = u.id, p.object = u, p.geometry = d, p.material = f, p.groupOrder = m, p.renderOrder = u.renderOrder, p.z = x, p.group = g), t++, p;
    }
    function o(u, d, f, m, x, g) {
        let p = a(u, d, f, m, x, g);
        f.transmission > 0 ? n.push(p) : f.transparent === !0 ? i.push(p) : e.push(p);
    }
    function c(u, d, f, m, x, g) {
        let p = a(u, d, f, m, x, g);
        f.transmission > 0 ? n.unshift(p) : f.transparent === !0 ? i.unshift(p) : e.unshift(p);
    }
    function l(u, d) {
        e.length > 1 && e.sort(u || E0), n.length > 1 && n.sort(d || yh), i.length > 1 && i.sort(d || yh);
    }
    function h() {
        for(let u = t, d = s1.length; u < d; u++){
            let f = s1[u];
            if (f.id === null) break;
            f.id = null, f.object = null, f.geometry = null, f.material = null, f.group = null;
        }
    }
    return {
        opaque: e,
        transmissive: n,
        transparent: i,
        init: r,
        push: o,
        unshift: c,
        finish: h,
        sort: l
    };
}
function T0() {
    let s1 = new WeakMap;
    function t(n, i) {
        let r = s1.get(n), a;
        return r === void 0 ? (a = new Mh, s1.set(n, [
            a
        ])) : i >= r.length ? (a = new Mh, r.push(a)) : a = r[i], a;
    }
    function e() {
        s1 = new WeakMap;
    }
    return {
        get: t,
        dispose: e
    };
}
function w0() {
    let s1 = {};
    return {
        get: function(t) {
            if (s1[t.id] !== void 0) return s1[t.id];
            let e;
            switch(t.type){
                case "DirectionalLight":
                    e = {
                        direction: new A,
                        color: new ft
                    };
                    break;
                case "SpotLight":
                    e = {
                        position: new A,
                        direction: new A,
                        color: new ft,
                        distance: 0,
                        coneCos: 0,
                        penumbraCos: 0,
                        decay: 0
                    };
                    break;
                case "PointLight":
                    e = {
                        position: new A,
                        color: new ft,
                        distance: 0,
                        decay: 0
                    };
                    break;
                case "HemisphereLight":
                    e = {
                        direction: new A,
                        skyColor: new ft,
                        groundColor: new ft
                    };
                    break;
                case "RectAreaLight":
                    e = {
                        color: new ft,
                        position: new A,
                        halfWidth: new A,
                        halfHeight: new A
                    };
                    break;
            }
            return s1[t.id] = e, e;
        }
    };
}
function A0() {
    let s1 = {};
    return {
        get: function(t) {
            if (s1[t.id] !== void 0) return s1[t.id];
            let e;
            switch(t.type){
                case "DirectionalLight":
                    e = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new J
                    };
                    break;
                case "SpotLight":
                    e = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new J
                    };
                    break;
                case "PointLight":
                    e = {
                        shadowBias: 0,
                        shadowNormalBias: 0,
                        shadowRadius: 1,
                        shadowMapSize: new J,
                        shadowCameraNear: 1,
                        shadowCameraFar: 1e3
                    };
                    break;
            }
            return s1[t.id] = e, e;
        }
    };
}
var R0 = 0;
function C0(s1, t) {
    return (t.castShadow ? 2 : 0) - (s1.castShadow ? 2 : 0) + (t.map ? 1 : 0) - (s1.map ? 1 : 0);
}
function P0(s1, t) {
    let e = new w0, n = A0(), i = {
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
            numSpotMaps: -1
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
        numSpotLightShadowsWithMaps: 0
    };
    for(let h = 0; h < 9; h++)i.probe.push(new A);
    let r = new A, a = new Ot, o = new Ot;
    function c(h, u) {
        let d = 0, f = 0, m = 0;
        for(let V = 0; V < 9; V++)i.probe[V].set(0, 0, 0);
        let x = 0, g = 0, p = 0, v = 0, _ = 0, y = 0, b = 0, w = 0, R = 0, L = 0;
        h.sort(C0);
        let M = u === !0 ? Math.PI : 1;
        for(let V = 0, $ = h.length; V < $; V++){
            let F = h[V], O = F.color, z = F.intensity, K = F.distance, X = F.shadow && F.shadow.map ? F.shadow.map.texture : null;
            if (F.isAmbientLight) d += O.r * z * M, f += O.g * z * M, m += O.b * z * M;
            else if (F.isLightProbe) for(let Y = 0; Y < 9; Y++)i.probe[Y].addScaledVector(F.sh.coefficients[Y], z);
            else if (F.isDirectionalLight) {
                let Y = e.get(F);
                if (Y.color.copy(F.color).multiplyScalar(F.intensity * M), F.castShadow) {
                    let j = F.shadow, tt = n.get(F);
                    tt.shadowBias = j.bias, tt.shadowNormalBias = j.normalBias, tt.shadowRadius = j.radius, tt.shadowMapSize = j.mapSize, i.directionalShadow[x] = tt, i.directionalShadowMap[x] = X, i.directionalShadowMatrix[x] = F.shadow.matrix, y++;
                }
                i.directional[x] = Y, x++;
            } else if (F.isSpotLight) {
                let Y = e.get(F);
                Y.position.setFromMatrixPosition(F.matrixWorld), Y.color.copy(O).multiplyScalar(z * M), Y.distance = K, Y.coneCos = Math.cos(F.angle), Y.penumbraCos = Math.cos(F.angle * (1 - F.penumbra)), Y.decay = F.decay, i.spot[p] = Y;
                let j = F.shadow;
                if (F.map && (i.spotLightMap[R] = F.map, R++, j.updateMatrices(F), F.castShadow && L++), i.spotLightMatrix[p] = j.matrix, F.castShadow) {
                    let tt = n.get(F);
                    tt.shadowBias = j.bias, tt.shadowNormalBias = j.normalBias, tt.shadowRadius = j.radius, tt.shadowMapSize = j.mapSize, i.spotShadow[p] = tt, i.spotShadowMap[p] = X, w++;
                }
                p++;
            } else if (F.isRectAreaLight) {
                let Y = e.get(F);
                Y.color.copy(O).multiplyScalar(z), Y.halfWidth.set(F.width * .5, 0, 0), Y.halfHeight.set(0, F.height * .5, 0), i.rectArea[v] = Y, v++;
            } else if (F.isPointLight) {
                let Y = e.get(F);
                if (Y.color.copy(F.color).multiplyScalar(F.intensity * M), Y.distance = F.distance, Y.decay = F.decay, F.castShadow) {
                    let j = F.shadow, tt = n.get(F);
                    tt.shadowBias = j.bias, tt.shadowNormalBias = j.normalBias, tt.shadowRadius = j.radius, tt.shadowMapSize = j.mapSize, tt.shadowCameraNear = j.camera.near, tt.shadowCameraFar = j.camera.far, i.pointShadow[g] = tt, i.pointShadowMap[g] = X, i.pointShadowMatrix[g] = F.shadow.matrix, b++;
                }
                i.point[g] = Y, g++;
            } else if (F.isHemisphereLight) {
                let Y = e.get(F);
                Y.skyColor.copy(F.color).multiplyScalar(z * M), Y.groundColor.copy(F.groundColor).multiplyScalar(z * M), i.hemi[_] = Y, _++;
            }
        }
        v > 0 && (t.isWebGL2 || s1.has("OES_texture_float_linear") === !0 ? (i.rectAreaLTC1 = ct.LTC_FLOAT_1, i.rectAreaLTC2 = ct.LTC_FLOAT_2) : s1.has("OES_texture_half_float_linear") === !0 ? (i.rectAreaLTC1 = ct.LTC_HALF_1, i.rectAreaLTC2 = ct.LTC_HALF_2) : console.error("THREE.WebGLRenderer: Unable to use RectAreaLight. Missing WebGL extensions.")), i.ambient[0] = d, i.ambient[1] = f, i.ambient[2] = m;
        let E = i.hash;
        (E.directionalLength !== x || E.pointLength !== g || E.spotLength !== p || E.rectAreaLength !== v || E.hemiLength !== _ || E.numDirectionalShadows !== y || E.numPointShadows !== b || E.numSpotShadows !== w || E.numSpotMaps !== R) && (i.directional.length = x, i.spot.length = p, i.rectArea.length = v, i.point.length = g, i.hemi.length = _, i.directionalShadow.length = y, i.directionalShadowMap.length = y, i.pointShadow.length = b, i.pointShadowMap.length = b, i.spotShadow.length = w, i.spotShadowMap.length = w, i.directionalShadowMatrix.length = y, i.pointShadowMatrix.length = b, i.spotLightMatrix.length = w + R - L, i.spotLightMap.length = R, i.numSpotLightShadowsWithMaps = L, E.directionalLength = x, E.pointLength = g, E.spotLength = p, E.rectAreaLength = v, E.hemiLength = _, E.numDirectionalShadows = y, E.numPointShadows = b, E.numSpotShadows = w, E.numSpotMaps = R, i.version = R0++);
    }
    function l(h, u) {
        let d = 0, f = 0, m = 0, x = 0, g = 0, p = u.matrixWorldInverse;
        for(let v = 0, _ = h.length; v < _; v++){
            let y = h[v];
            if (y.isDirectionalLight) {
                let b = i.directional[d];
                b.direction.setFromMatrixPosition(y.matrixWorld), r.setFromMatrixPosition(y.target.matrixWorld), b.direction.sub(r), b.direction.transformDirection(p), d++;
            } else if (y.isSpotLight) {
                let b = i.spot[m];
                b.position.setFromMatrixPosition(y.matrixWorld), b.position.applyMatrix4(p), b.direction.setFromMatrixPosition(y.matrixWorld), r.setFromMatrixPosition(y.target.matrixWorld), b.direction.sub(r), b.direction.transformDirection(p), m++;
            } else if (y.isRectAreaLight) {
                let b = i.rectArea[x];
                b.position.setFromMatrixPosition(y.matrixWorld), b.position.applyMatrix4(p), o.identity(), a.copy(y.matrixWorld), a.premultiply(p), o.extractRotation(a), b.halfWidth.set(y.width * .5, 0, 0), b.halfHeight.set(0, y.height * .5, 0), b.halfWidth.applyMatrix4(o), b.halfHeight.applyMatrix4(o), x++;
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
function Sh(s1, t) {
    let e = new P0(s1, t), n = [], i = [];
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
        e.setup(n, u);
    }
    function l(u) {
        e.setupView(n, u);
    }
    return {
        init: r,
        state: {
            lightsArray: n,
            shadowsArray: i,
            lights: e
        },
        setupLights: c,
        setupLightsView: l,
        pushLight: a,
        pushShadow: o
    };
}
function L0(s1, t) {
    let e = new WeakMap;
    function n(r, a = 0) {
        let o = e.get(r), c;
        return o === void 0 ? (c = new Sh(s1, t), e.set(r, [
            c
        ])) : a >= o.length ? (c = new Sh(s1, t), o.push(c)) : c = o[a], c;
    }
    function i() {
        e = new WeakMap;
    }
    return {
        get: n,
        dispose: i
    };
}
var $r = class extends Me {
    constructor(t){
        super(), this.isMeshDepthMaterial = !0, this.type = "MeshDepthMaterial", this.depthPacking = bf, this.map = null, this.alphaMap = null, this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.wireframe = !1, this.wireframeLinewidth = 1, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.depthPacking = t.depthPacking, this.map = t.map, this.alphaMap = t.alphaMap, this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this;
    }
}, Kr = class extends Me {
    constructor(t){
        super(), this.isMeshDistanceMaterial = !0, this.type = "MeshDistanceMaterial", this.map = null, this.alphaMap = null, this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.map = t.map, this.alphaMap = t.alphaMap, this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this;
    }
}, I0 = `void main() {
	gl_Position = vec4( position, 1.0 );
}`, U0 = `uniform sampler2D shadow_pass;
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
function D0(s1, t, e) {
    let n = new Ps, i = new J, r = new J, a = new $t, o = new $r({
        depthPacking: Ef
    }), c = new Kr, l = {}, h = e.maxTextureSize, u = {
        [On]: De,
        [De]: On,
        [gn]: gn
    }, d = new Qe({
        defines: {
            VSM_SAMPLES: 8
        },
        uniforms: {
            shadow_pass: {
                value: null
            },
            resolution: {
                value: new J
            },
            radius: {
                value: 4
            }
        },
        vertexShader: I0,
        fragmentShader: U0
    }), f = d.clone();
    f.defines.HORIZONTAL_PASS = 1;
    let m = new Vt;
    m.setAttribute("position", new Kt(new Float32Array([
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
    let x = new ve(m, d), g = this;
    this.enabled = !1, this.autoUpdate = !0, this.needsUpdate = !1, this.type = nd;
    let p = this.type;
    this.render = function(b, w, R) {
        if (g.enabled === !1 || g.autoUpdate === !1 && g.needsUpdate === !1 || b.length === 0) return;
        let L = s1.getRenderTarget(), M = s1.getActiveCubeFace(), E = s1.getActiveMipmapLevel(), V = s1.state;
        V.setBlending(Un), V.buffers.color.setClear(1, 1, 1, 1), V.buffers.depth.setTest(!0), V.setScissorTest(!1);
        let $ = p !== pn && this.type === pn, F = p === pn && this.type !== pn;
        for(let O = 0, z = b.length; O < z; O++){
            let K = b[O], X = K.shadow;
            if (X === void 0) {
                console.warn("THREE.WebGLShadowMap:", K, "has no shadow.");
                continue;
            }
            if (X.autoUpdate === !1 && X.needsUpdate === !1) continue;
            i.copy(X.mapSize);
            let Y = X.getFrameExtents();
            if (i.multiply(Y), r.copy(X.mapSize), (i.x > h || i.y > h) && (i.x > h && (r.x = Math.floor(h / Y.x), i.x = r.x * Y.x, X.mapSize.x = r.x), i.y > h && (r.y = Math.floor(h / Y.y), i.y = r.y * Y.y, X.mapSize.y = r.y)), X.map === null || $ === !0 || F === !0) {
                let tt = this.type !== pn ? {
                    minFilter: fe,
                    magFilter: fe
                } : {};
                X.map !== null && X.map.dispose(), X.map = new Ge(i.x, i.y, tt), X.map.texture.name = K.name + ".shadowMap", X.camera.updateProjectionMatrix();
            }
            s1.setRenderTarget(X.map), s1.clear();
            let j = X.getViewportCount();
            for(let tt = 0; tt < j; tt++){
                let N = X.getViewport(tt);
                a.set(r.x * N.x, r.y * N.y, r.x * N.z, r.y * N.w), V.viewport(a), X.updateMatrices(K, tt), n = X.getFrustum(), y(w, R, X.camera, K, this.type);
            }
            X.isPointLightShadow !== !0 && this.type === pn && v(X, R), X.needsUpdate = !1;
        }
        p = this.type, g.needsUpdate = !1, s1.setRenderTarget(L, M, E);
    };
    function v(b, w) {
        let R = t.update(x);
        d.defines.VSM_SAMPLES !== b.blurSamples && (d.defines.VSM_SAMPLES = b.blurSamples, f.defines.VSM_SAMPLES = b.blurSamples, d.needsUpdate = !0, f.needsUpdate = !0), b.mapPass === null && (b.mapPass = new Ge(i.x, i.y)), d.uniforms.shadow_pass.value = b.map.texture, d.uniforms.resolution.value = b.mapSize, d.uniforms.radius.value = b.radius, s1.setRenderTarget(b.mapPass), s1.clear(), s1.renderBufferDirect(w, null, R, d, x, null), f.uniforms.shadow_pass.value = b.mapPass.texture, f.uniforms.resolution.value = b.mapSize, f.uniforms.radius.value = b.radius, s1.setRenderTarget(b.map), s1.clear(), s1.renderBufferDirect(w, null, R, f, x, null);
    }
    function _(b, w, R, L) {
        let M = null, E = R.isPointLight === !0 ? b.customDistanceMaterial : b.customDepthMaterial;
        if (E !== void 0) M = E;
        else if (M = R.isPointLight === !0 ? c : o, s1.localClippingEnabled && w.clipShadows === !0 && Array.isArray(w.clippingPlanes) && w.clippingPlanes.length !== 0 || w.displacementMap && w.displacementScale !== 0 || w.alphaMap && w.alphaTest > 0 || w.map && w.alphaTest > 0) {
            let V = M.uuid, $ = w.uuid, F = l[V];
            F === void 0 && (F = {}, l[V] = F);
            let O = F[$];
            O === void 0 && (O = M.clone(), F[$] = O), M = O;
        }
        if (M.visible = w.visible, M.wireframe = w.wireframe, L === pn ? M.side = w.shadowSide !== null ? w.shadowSide : w.side : M.side = w.shadowSide !== null ? w.shadowSide : u[w.side], M.alphaMap = w.alphaMap, M.alphaTest = w.alphaTest, M.map = w.map, M.clipShadows = w.clipShadows, M.clippingPlanes = w.clippingPlanes, M.clipIntersection = w.clipIntersection, M.displacementMap = w.displacementMap, M.displacementScale = w.displacementScale, M.displacementBias = w.displacementBias, M.wireframeLinewidth = w.wireframeLinewidth, M.linewidth = w.linewidth, R.isPointLight === !0 && M.isMeshDistanceMaterial === !0) {
            let V = s1.properties.get(M);
            V.light = R;
        }
        return M;
    }
    function y(b, w, R, L, M) {
        if (b.visible === !1) return;
        if (b.layers.test(w.layers) && (b.isMesh || b.isLine || b.isPoints) && (b.castShadow || b.receiveShadow && M === pn) && (!b.frustumCulled || n.intersectsObject(b))) {
            b.modelViewMatrix.multiplyMatrices(R.matrixWorldInverse, b.matrixWorld);
            let $ = t.update(b), F = b.material;
            if (Array.isArray(F)) {
                let O = $.groups;
                for(let z = 0, K = O.length; z < K; z++){
                    let X = O[z], Y = F[X.materialIndex];
                    if (Y && Y.visible) {
                        let j = _(b, Y, L, M);
                        s1.renderBufferDirect(R, null, $, j, b, X);
                    }
                }
            } else if (F.visible) {
                let O = _(b, F, L, M);
                s1.renderBufferDirect(R, null, $, O, b, null);
            }
        }
        let V = b.children;
        for(let $ = 0, F = V.length; $ < F; $++)y(V[$], w, R, L, M);
    }
}
function N0(s1, t, e) {
    let n = e.isWebGL2;
    function i() {
        let I = !1, ht = new $t, H = null, ot = new $t(0, 0, 0, 0);
        return {
            setMask: function(dt) {
                H !== dt && !I && (s1.colorMask(dt, dt, dt, dt), H = dt);
            },
            setLocked: function(dt) {
                I = dt;
            },
            setClear: function(dt, qt, ee, le, En) {
                En === !0 && (dt *= le, qt *= le, ee *= le), ht.set(dt, qt, ee, le), ot.equals(ht) === !1 && (s1.clearColor(dt, qt, ee, le), ot.copy(ht));
            },
            reset: function() {
                I = !1, H = null, ot.set(-1, 0, 0, 0);
            }
        };
    }
    function r() {
        let I = !1, ht = null, H = null, ot = null;
        return {
            setTest: function(dt) {
                dt ? Tt(s1.DEPTH_TEST) : wt(s1.DEPTH_TEST);
            },
            setMask: function(dt) {
                ht !== dt && !I && (s1.depthMask(dt), ht = dt);
            },
            setFunc: function(dt) {
                if (H !== dt) {
                    switch(dt){
                        case $d:
                            s1.depthFunc(s1.NEVER);
                            break;
                        case Kd:
                            s1.depthFunc(s1.ALWAYS);
                            break;
                        case Qd:
                            s1.depthFunc(s1.LESS);
                            break;
                        case ao:
                            s1.depthFunc(s1.LEQUAL);
                            break;
                        case jd:
                            s1.depthFunc(s1.EQUAL);
                            break;
                        case tf:
                            s1.depthFunc(s1.GEQUAL);
                            break;
                        case ef:
                            s1.depthFunc(s1.GREATER);
                            break;
                        case nf:
                            s1.depthFunc(s1.NOTEQUAL);
                            break;
                        default:
                            s1.depthFunc(s1.LEQUAL);
                    }
                    H = dt;
                }
            },
            setLocked: function(dt) {
                I = dt;
            },
            setClear: function(dt) {
                ot !== dt && (s1.clearDepth(dt), ot = dt);
            },
            reset: function() {
                I = !1, ht = null, H = null, ot = null;
            }
        };
    }
    function a() {
        let I = !1, ht = null, H = null, ot = null, dt = null, qt = null, ee = null, le = null, En = null;
        return {
            setTest: function(jt) {
                I || (jt ? Tt(s1.STENCIL_TEST) : wt(s1.STENCIL_TEST));
            },
            setMask: function(jt) {
                ht !== jt && !I && (s1.stencilMask(jt), ht = jt);
            },
            setFunc: function(jt, tn, Te) {
                (H !== jt || ot !== tn || dt !== Te) && (s1.stencilFunc(jt, tn, Te), H = jt, ot = tn, dt = Te);
            },
            setOp: function(jt, tn, Te) {
                (qt !== jt || ee !== tn || le !== Te) && (s1.stencilOp(jt, tn, Te), qt = jt, ee = tn, le = Te);
            },
            setLocked: function(jt) {
                I = jt;
            },
            setClear: function(jt) {
                En !== jt && (s1.clearStencil(jt), En = jt);
            },
            reset: function() {
                I = !1, ht = null, H = null, ot = null, dt = null, qt = null, ee = null, le = null, En = null;
            }
        };
    }
    let o = new i, c = new r, l = new a, h = new WeakMap, u = new WeakMap, d = {}, f = {}, m = new WeakMap, x = [], g = null, p = !1, v = null, _ = null, y = null, b = null, w = null, R = null, L = null, M = !1, E = null, V = null, $ = null, F = null, O = null, z = s1.getParameter(s1.MAX_COMBINED_TEXTURE_IMAGE_UNITS), K = !1, X = 0, Y = s1.getParameter(s1.VERSION);
    Y.indexOf("WebGL") !== -1 ? (X = parseFloat(/^WebGL (\d)/.exec(Y)[1]), K = X >= 1) : Y.indexOf("OpenGL ES") !== -1 && (X = parseFloat(/^OpenGL ES (\d)/.exec(Y)[1]), K = X >= 2);
    let j = null, tt = {}, N = s1.getParameter(s1.SCISSOR_BOX), q = s1.getParameter(s1.VIEWPORT), lt = new $t().fromArray(N), ut = new $t().fromArray(q);
    function pt(I, ht, H, ot) {
        let dt = new Uint8Array(4), qt = s1.createTexture();
        s1.bindTexture(I, qt), s1.texParameteri(I, s1.TEXTURE_MIN_FILTER, s1.NEAREST), s1.texParameteri(I, s1.TEXTURE_MAG_FILTER, s1.NEAREST);
        for(let ee = 0; ee < H; ee++)n && (I === s1.TEXTURE_3D || I === s1.TEXTURE_2D_ARRAY) ? s1.texImage3D(ht, 0, s1.RGBA, 1, 1, ot, 0, s1.RGBA, s1.UNSIGNED_BYTE, dt) : s1.texImage2D(ht + ee, 0, s1.RGBA, 1, 1, 0, s1.RGBA, s1.UNSIGNED_BYTE, dt);
        return qt;
    }
    let Et = {};
    Et[s1.TEXTURE_2D] = pt(s1.TEXTURE_2D, s1.TEXTURE_2D, 1), Et[s1.TEXTURE_CUBE_MAP] = pt(s1.TEXTURE_CUBE_MAP, s1.TEXTURE_CUBE_MAP_POSITIVE_X, 6), n && (Et[s1.TEXTURE_2D_ARRAY] = pt(s1.TEXTURE_2D_ARRAY, s1.TEXTURE_2D_ARRAY, 1, 1), Et[s1.TEXTURE_3D] = pt(s1.TEXTURE_3D, s1.TEXTURE_3D, 1, 1)), o.setClear(0, 0, 0, 1), c.setClear(1), l.setClear(0), Tt(s1.DEPTH_TEST), c.setFunc(ao), Q(!1), St(tl), Tt(s1.CULL_FACE), Z(Un);
    function Tt(I) {
        d[I] !== !0 && (s1.enable(I), d[I] = !0);
    }
    function wt(I) {
        d[I] !== !1 && (s1.disable(I), d[I] = !1);
    }
    function Yt(I, ht) {
        return f[I] !== ht ? (s1.bindFramebuffer(I, ht), f[I] = ht, n && (I === s1.DRAW_FRAMEBUFFER && (f[s1.FRAMEBUFFER] = ht), I === s1.FRAMEBUFFER && (f[s1.DRAW_FRAMEBUFFER] = ht)), !0) : !1;
    }
    function te(I, ht) {
        let H = x, ot = !1;
        if (I) if (H = m.get(ht), H === void 0 && (H = [], m.set(ht, H)), I.isWebGLMultipleRenderTargets) {
            let dt = I.texture;
            if (H.length !== dt.length || H[0] !== s1.COLOR_ATTACHMENT0) {
                for(let qt = 0, ee = dt.length; qt < ee; qt++)H[qt] = s1.COLOR_ATTACHMENT0 + qt;
                H.length = dt.length, ot = !0;
            }
        } else H[0] !== s1.COLOR_ATTACHMENT0 && (H[0] = s1.COLOR_ATTACHMENT0, ot = !0);
        else H[0] !== s1.BACK && (H[0] = s1.BACK, ot = !0);
        ot && (e.isWebGL2 ? s1.drawBuffers(H) : t.get("WEBGL_draw_buffers").drawBuffersWEBGL(H));
    }
    function Pt(I) {
        return g !== I ? (s1.useProgram(I), g = I, !0) : !1;
    }
    let P = {
        [Bi]: s1.FUNC_ADD,
        [zd]: s1.FUNC_SUBTRACT,
        [kd]: s1.FUNC_REVERSE_SUBTRACT
    };
    if (n) P[sl] = s1.MIN, P[rl] = s1.MAX;
    else {
        let I = t.get("EXT_blend_minmax");
        I !== null && (P[sl] = I.MIN_EXT, P[rl] = I.MAX_EXT);
    }
    let at = {
        [Vd]: s1.ZERO,
        [Hd]: s1.ONE,
        [Gd]: s1.SRC_COLOR,
        [id]: s1.SRC_ALPHA,
        [Jd]: s1.SRC_ALPHA_SATURATE,
        [Yd]: s1.DST_COLOR,
        [Xd]: s1.DST_ALPHA,
        [Wd]: s1.ONE_MINUS_SRC_COLOR,
        [sd]: s1.ONE_MINUS_SRC_ALPHA,
        [Zd]: s1.ONE_MINUS_DST_COLOR,
        [qd]: s1.ONE_MINUS_DST_ALPHA
    };
    function Z(I, ht, H, ot, dt, qt, ee, le) {
        if (I === Un) {
            p === !0 && (wt(s1.BLEND), p = !1);
            return;
        }
        if (p === !1 && (Tt(s1.BLEND), p = !0), I !== Bd) {
            if (I !== v || le !== M) {
                if ((_ !== Bi || w !== Bi) && (s1.blendEquation(s1.FUNC_ADD), _ = Bi, w = Bi), le) switch(I){
                    case Wi:
                        s1.blendFuncSeparate(s1.ONE, s1.ONE_MINUS_SRC_ALPHA, s1.ONE, s1.ONE_MINUS_SRC_ALPHA);
                        break;
                    case el:
                        s1.blendFunc(s1.ONE, s1.ONE);
                        break;
                    case nl:
                        s1.blendFuncSeparate(s1.ZERO, s1.ONE_MINUS_SRC_COLOR, s1.ZERO, s1.ONE);
                        break;
                    case il:
                        s1.blendFuncSeparate(s1.ZERO, s1.SRC_COLOR, s1.ZERO, s1.SRC_ALPHA);
                        break;
                    default:
                        console.error("THREE.WebGLState: Invalid blending: ", I);
                        break;
                }
                else switch(I){
                    case Wi:
                        s1.blendFuncSeparate(s1.SRC_ALPHA, s1.ONE_MINUS_SRC_ALPHA, s1.ONE, s1.ONE_MINUS_SRC_ALPHA);
                        break;
                    case el:
                        s1.blendFunc(s1.SRC_ALPHA, s1.ONE);
                        break;
                    case nl:
                        s1.blendFuncSeparate(s1.ZERO, s1.ONE_MINUS_SRC_COLOR, s1.ZERO, s1.ONE);
                        break;
                    case il:
                        s1.blendFunc(s1.ZERO, s1.SRC_COLOR);
                        break;
                    default:
                        console.error("THREE.WebGLState: Invalid blending: ", I);
                        break;
                }
                y = null, b = null, R = null, L = null, v = I, M = le;
            }
            return;
        }
        dt = dt || ht, qt = qt || H, ee = ee || ot, (ht !== _ || dt !== w) && (s1.blendEquationSeparate(P[ht], P[dt]), _ = ht, w = dt), (H !== y || ot !== b || qt !== R || ee !== L) && (s1.blendFuncSeparate(at[H], at[ot], at[qt], at[ee]), y = H, b = ot, R = qt, L = ee), v = I, M = !1;
    }
    function st(I, ht) {
        I.side === gn ? wt(s1.CULL_FACE) : Tt(s1.CULL_FACE);
        let H = I.side === De;
        ht && (H = !H), Q(H), I.blending === Wi && I.transparent === !1 ? Z(Un) : Z(I.blending, I.blendEquation, I.blendSrc, I.blendDst, I.blendEquationAlpha, I.blendSrcAlpha, I.blendDstAlpha, I.premultipliedAlpha), c.setFunc(I.depthFunc), c.setTest(I.depthTest), c.setMask(I.depthWrite), o.setMask(I.colorWrite);
        let ot = I.stencilWrite;
        l.setTest(ot), ot && (l.setMask(I.stencilWriteMask), l.setFunc(I.stencilFunc, I.stencilRef, I.stencilFuncMask), l.setOp(I.stencilFail, I.stencilZFail, I.stencilZPass)), xt(I.polygonOffset, I.polygonOffsetFactor, I.polygonOffsetUnits), I.alphaToCoverage === !0 ? Tt(s1.SAMPLE_ALPHA_TO_COVERAGE) : wt(s1.SAMPLE_ALPHA_TO_COVERAGE);
    }
    function Q(I) {
        E !== I && (I ? s1.frontFace(s1.CW) : s1.frontFace(s1.CCW), E = I);
    }
    function St(I) {
        I !== Nd ? (Tt(s1.CULL_FACE), I !== V && (I === tl ? s1.cullFace(s1.BACK) : I === Fd ? s1.cullFace(s1.FRONT) : s1.cullFace(s1.FRONT_AND_BACK))) : wt(s1.CULL_FACE), V = I;
    }
    function mt(I) {
        I !== $ && (K && s1.lineWidth(I), $ = I);
    }
    function xt(I, ht, H) {
        I ? (Tt(s1.POLYGON_OFFSET_FILL), (F !== ht || O !== H) && (s1.polygonOffset(ht, H), F = ht, O = H)) : wt(s1.POLYGON_OFFSET_FILL);
    }
    function Dt(I) {
        I ? Tt(s1.SCISSOR_TEST) : wt(s1.SCISSOR_TEST);
    }
    function Xt(I) {
        I === void 0 && (I = s1.TEXTURE0 + z - 1), j !== I && (s1.activeTexture(I), j = I);
    }
    function ie(I, ht, H) {
        H === void 0 && (j === null ? H = s1.TEXTURE0 + z - 1 : H = j);
        let ot = tt[H];
        ot === void 0 && (ot = {
            type: void 0,
            texture: void 0
        }, tt[H] = ot), (ot.type !== I || ot.texture !== ht) && (j !== H && (s1.activeTexture(H), j = H), s1.bindTexture(I, ht || Et[I]), ot.type = I, ot.texture = ht);
    }
    function C() {
        let I = tt[j];
        I !== void 0 && I.type !== void 0 && (s1.bindTexture(I.type, null), I.type = void 0, I.texture = void 0);
    }
    function S() {
        try {
            s1.compressedTexImage2D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function B() {
        try {
            s1.compressedTexImage3D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function nt() {
        try {
            s1.texSubImage2D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function et() {
        try {
            s1.texSubImage3D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function it() {
        try {
            s1.compressedTexSubImage2D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function Mt() {
        try {
            s1.compressedTexSubImage3D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function rt() {
        try {
            s1.texStorage2D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function k() {
        try {
            s1.texStorage3D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function Rt() {
        try {
            s1.texImage2D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function bt() {
        try {
            s1.texImage3D.apply(s1, arguments);
        } catch (I) {
            console.error("THREE.WebGLState:", I);
        }
    }
    function At(I) {
        lt.equals(I) === !1 && (s1.scissor(I.x, I.y, I.z, I.w), lt.copy(I));
    }
    function vt(I) {
        ut.equals(I) === !1 && (s1.viewport(I.x, I.y, I.z, I.w), ut.copy(I));
    }
    function yt(I, ht) {
        let H = u.get(ht);
        H === void 0 && (H = new WeakMap, u.set(ht, H));
        let ot = H.get(I);
        ot === void 0 && (ot = s1.getUniformBlockIndex(ht, I.name), H.set(I, ot));
    }
    function Ht(I, ht) {
        let ot = u.get(ht).get(I);
        h.get(ht) !== ot && (s1.uniformBlockBinding(ht, ot, I.__bindingPointIndex), h.set(ht, ot));
    }
    function Qt() {
        s1.disable(s1.BLEND), s1.disable(s1.CULL_FACE), s1.disable(s1.DEPTH_TEST), s1.disable(s1.POLYGON_OFFSET_FILL), s1.disable(s1.SCISSOR_TEST), s1.disable(s1.STENCIL_TEST), s1.disable(s1.SAMPLE_ALPHA_TO_COVERAGE), s1.blendEquation(s1.FUNC_ADD), s1.blendFunc(s1.ONE, s1.ZERO), s1.blendFuncSeparate(s1.ONE, s1.ZERO, s1.ONE, s1.ZERO), s1.colorMask(!0, !0, !0, !0), s1.clearColor(0, 0, 0, 0), s1.depthMask(!0), s1.depthFunc(s1.LESS), s1.clearDepth(1), s1.stencilMask(4294967295), s1.stencilFunc(s1.ALWAYS, 0, 4294967295), s1.stencilOp(s1.KEEP, s1.KEEP, s1.KEEP), s1.clearStencil(0), s1.cullFace(s1.BACK), s1.frontFace(s1.CCW), s1.polygonOffset(0, 0), s1.activeTexture(s1.TEXTURE0), s1.bindFramebuffer(s1.FRAMEBUFFER, null), n === !0 && (s1.bindFramebuffer(s1.DRAW_FRAMEBUFFER, null), s1.bindFramebuffer(s1.READ_FRAMEBUFFER, null)), s1.useProgram(null), s1.lineWidth(1), s1.scissor(0, 0, s1.canvas.width, s1.canvas.height), s1.viewport(0, 0, s1.canvas.width, s1.canvas.height), d = {}, j = null, tt = {}, f = {}, m = new WeakMap, x = [], g = null, p = !1, v = null, _ = null, y = null, b = null, w = null, R = null, L = null, M = !1, E = null, V = null, $ = null, F = null, O = null, lt.set(0, 0, s1.canvas.width, s1.canvas.height), ut.set(0, 0, s1.canvas.width, s1.canvas.height), o.reset(), c.reset(), l.reset();
    }
    return {
        buffers: {
            color: o,
            depth: c,
            stencil: l
        },
        enable: Tt,
        disable: wt,
        bindFramebuffer: Yt,
        drawBuffers: te,
        useProgram: Pt,
        setBlending: Z,
        setMaterial: st,
        setFlipSided: Q,
        setCullFace: St,
        setLineWidth: mt,
        setPolygonOffset: xt,
        setScissorTest: Dt,
        activeTexture: Xt,
        bindTexture: ie,
        unbindTexture: C,
        compressedTexImage2D: S,
        compressedTexImage3D: B,
        texImage2D: Rt,
        texImage3D: bt,
        updateUBOMapping: yt,
        uniformBlockBinding: Ht,
        texStorage2D: rt,
        texStorage3D: k,
        texSubImage2D: nt,
        texSubImage3D: et,
        compressedTexSubImage2D: it,
        compressedTexSubImage3D: Mt,
        scissor: At,
        viewport: vt,
        reset: Qt
    };
}
function F0(s1, t, e, n, i, r, a) {
    let o = i.isWebGL2, c = i.maxTextures, l = i.maxCubemapSize, h = i.maxTextureSize, u = i.maxSamples, d = t.has("WEBGL_multisampled_render_to_texture") ? t.get("WEBGL_multisampled_render_to_texture") : null, f = typeof navigator > "u" ? !1 : /OculusBrowser/g.test(navigator.userAgent), m = new WeakMap, x, g = new WeakMap, p = !1;
    try {
        p = typeof OffscreenCanvas < "u" && new OffscreenCanvas(1, 1).getContext("2d") !== null;
    } catch  {}
    function v(C, S) {
        return p ? new OffscreenCanvas(C, S) : ws("canvas");
    }
    function _(C, S, B, nt) {
        let et = 1;
        if ((C.width > nt || C.height > nt) && (et = nt / Math.max(C.width, C.height)), et < 1 || S === !0) if (typeof HTMLImageElement < "u" && C instanceof HTMLImageElement || typeof HTMLCanvasElement < "u" && C instanceof HTMLCanvasElement || typeof ImageBitmap < "u" && C instanceof ImageBitmap) {
            let it = S ? Hr : Math.floor, Mt = it(et * C.width), rt = it(et * C.height);
            x === void 0 && (x = v(Mt, rt));
            let k = B ? v(Mt, rt) : x;
            return k.width = Mt, k.height = rt, k.getContext("2d").drawImage(C, 0, 0, Mt, rt), console.warn("THREE.WebGLRenderer: Texture has been resized from (" + C.width + "x" + C.height + ") to (" + Mt + "x" + rt + ")."), k;
        } else return "data" in C && console.warn("THREE.WebGLRenderer: Image in DataTexture is too big (" + C.width + "x" + C.height + ")."), C;
        return C;
    }
    function y(C) {
        return lo(C.width) && lo(C.height);
    }
    function b(C) {
        return o ? !1 : C.wrapS !== Ce || C.wrapT !== Ce || C.minFilter !== fe && C.minFilter !== pe;
    }
    function w(C, S) {
        return C.generateMipmaps && S && C.minFilter !== fe && C.minFilter !== pe;
    }
    function R(C) {
        s1.generateMipmap(C);
    }
    function L(C, S, B, nt, et = !1) {
        if (o === !1) return S;
        if (C !== null) {
            if (s1[C] !== void 0) return s1[C];
            console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '" + C + "'");
        }
        let it = S;
        return S === s1.RED && (B === s1.FLOAT && (it = s1.R32F), B === s1.HALF_FLOAT && (it = s1.R16F), B === s1.UNSIGNED_BYTE && (it = s1.R8)), S === s1.RED_INTEGER && (B === s1.UNSIGNED_BYTE && (it = s1.R8UI), B === s1.UNSIGNED_SHORT && (it = s1.R16UI), B === s1.UNSIGNED_INT && (it = s1.R32UI), B === s1.BYTE && (it = s1.R8I), B === s1.SHORT && (it = s1.R16I), B === s1.INT && (it = s1.R32I)), S === s1.RG && (B === s1.FLOAT && (it = s1.RG32F), B === s1.HALF_FLOAT && (it = s1.RG16F), B === s1.UNSIGNED_BYTE && (it = s1.RG8)), S === s1.RGBA && (B === s1.FLOAT && (it = s1.RGBA32F), B === s1.HALF_FLOAT && (it = s1.RGBA16F), B === s1.UNSIGNED_BYTE && (it = nt === Nt && et === !1 ? s1.SRGB8_ALPHA8 : s1.RGBA8), B === s1.UNSIGNED_SHORT_4_4_4_4 && (it = s1.RGBA4), B === s1.UNSIGNED_SHORT_5_5_5_1 && (it = s1.RGB5_A1)), (it === s1.R16F || it === s1.R32F || it === s1.RG16F || it === s1.RG32F || it === s1.RGBA16F || it === s1.RGBA32F) && t.get("EXT_color_buffer_float"), it;
    }
    function M(C, S, B) {
        return w(C, B) === !0 || C.isFramebufferTexture && C.minFilter !== fe && C.minFilter !== pe ? Math.log2(Math.max(S.width, S.height)) + 1 : C.mipmaps !== void 0 && C.mipmaps.length > 0 ? C.mipmaps.length : C.isCompressedTexture && Array.isArray(C.image) ? S.mipmaps.length : 1;
    }
    function E(C) {
        return C === fe || C === oo || C === Ir ? s1.NEAREST : s1.LINEAR;
    }
    function V(C) {
        let S = C.target;
        S.removeEventListener("dispose", V), F(S), S.isVideoTexture && m.delete(S);
    }
    function $(C) {
        let S = C.target;
        S.removeEventListener("dispose", $), z(S);
    }
    function F(C) {
        let S = n.get(C);
        if (S.__webglInit === void 0) return;
        let B = C.source, nt = g.get(B);
        if (nt) {
            let et = nt[S.__cacheKey];
            et.usedTimes--, et.usedTimes === 0 && O(C), Object.keys(nt).length === 0 && g.delete(B);
        }
        n.remove(C);
    }
    function O(C) {
        let S = n.get(C);
        s1.deleteTexture(S.__webglTexture);
        let B = C.source, nt = g.get(B);
        delete nt[S.__cacheKey], a.memory.textures--;
    }
    function z(C) {
        let S = C.texture, B = n.get(C), nt = n.get(S);
        if (nt.__webglTexture !== void 0 && (s1.deleteTexture(nt.__webglTexture), a.memory.textures--), C.depthTexture && C.depthTexture.dispose(), C.isWebGLCubeRenderTarget) for(let et = 0; et < 6; et++){
            if (Array.isArray(B.__webglFramebuffer[et])) for(let it = 0; it < B.__webglFramebuffer[et].length; it++)s1.deleteFramebuffer(B.__webglFramebuffer[et][it]);
            else s1.deleteFramebuffer(B.__webglFramebuffer[et]);
            B.__webglDepthbuffer && s1.deleteRenderbuffer(B.__webglDepthbuffer[et]);
        }
        else {
            if (Array.isArray(B.__webglFramebuffer)) for(let et = 0; et < B.__webglFramebuffer.length; et++)s1.deleteFramebuffer(B.__webglFramebuffer[et]);
            else s1.deleteFramebuffer(B.__webglFramebuffer);
            if (B.__webglDepthbuffer && s1.deleteRenderbuffer(B.__webglDepthbuffer), B.__webglMultisampledFramebuffer && s1.deleteFramebuffer(B.__webglMultisampledFramebuffer), B.__webglColorRenderbuffer) for(let et = 0; et < B.__webglColorRenderbuffer.length; et++)B.__webglColorRenderbuffer[et] && s1.deleteRenderbuffer(B.__webglColorRenderbuffer[et]);
            B.__webglDepthRenderbuffer && s1.deleteRenderbuffer(B.__webglDepthRenderbuffer);
        }
        if (C.isWebGLMultipleRenderTargets) for(let et = 0, it = S.length; et < it; et++){
            let Mt = n.get(S[et]);
            Mt.__webglTexture && (s1.deleteTexture(Mt.__webglTexture), a.memory.textures--), n.remove(S[et]);
        }
        n.remove(S), n.remove(C);
    }
    let K = 0;
    function X() {
        K = 0;
    }
    function Y() {
        let C = K;
        return C >= c && console.warn("THREE.WebGLTextures: Trying to use " + C + " texture units while this GPU supports only " + c), K += 1, C;
    }
    function j(C) {
        let S = [];
        return S.push(C.wrapS), S.push(C.wrapT), S.push(C.wrapR || 0), S.push(C.magFilter), S.push(C.minFilter), S.push(C.anisotropy), S.push(C.internalFormat), S.push(C.format), S.push(C.type), S.push(C.generateMipmaps), S.push(C.premultiplyAlpha), S.push(C.flipY), S.push(C.unpackAlignment), S.push(C.colorSpace), S.join();
    }
    function tt(C, S) {
        let B = n.get(C);
        if (C.isVideoTexture && Xt(C), C.isRenderTargetTexture === !1 && C.version > 0 && B.__version !== C.version) {
            let nt = C.image;
            if (nt === null) console.warn("THREE.WebGLRenderer: Texture marked for update but no image data found.");
            else if (nt.complete === !1) console.warn("THREE.WebGLRenderer: Texture marked for update but image is incomplete");
            else {
                Yt(B, C, S);
                return;
            }
        }
        e.bindTexture(s1.TEXTURE_2D, B.__webglTexture, s1.TEXTURE0 + S);
    }
    function N(C, S) {
        let B = n.get(C);
        if (C.version > 0 && B.__version !== C.version) {
            Yt(B, C, S);
            return;
        }
        e.bindTexture(s1.TEXTURE_2D_ARRAY, B.__webglTexture, s1.TEXTURE0 + S);
    }
    function q(C, S) {
        let B = n.get(C);
        if (C.version > 0 && B.__version !== C.version) {
            Yt(B, C, S);
            return;
        }
        e.bindTexture(s1.TEXTURE_3D, B.__webglTexture, s1.TEXTURE0 + S);
    }
    function lt(C, S) {
        let B = n.get(C);
        if (C.version > 0 && B.__version !== C.version) {
            te(B, C, S);
            return;
        }
        e.bindTexture(s1.TEXTURE_CUBE_MAP, B.__webglTexture, s1.TEXTURE0 + S);
    }
    let ut = {
        [Nr]: s1.REPEAT,
        [Ce]: s1.CLAMP_TO_EDGE,
        [Fr]: s1.MIRRORED_REPEAT
    }, pt = {
        [fe]: s1.NEAREST,
        [oo]: s1.NEAREST_MIPMAP_NEAREST,
        [Ir]: s1.NEAREST_MIPMAP_LINEAR,
        [pe]: s1.LINEAR,
        [rd]: s1.LINEAR_MIPMAP_NEAREST,
        [li]: s1.LINEAR_MIPMAP_LINEAR
    }, Et = {
        [Af]: s1.NEVER,
        [Df]: s1.ALWAYS,
        [Rf]: s1.LESS,
        [Pf]: s1.LEQUAL,
        [Cf]: s1.EQUAL,
        [Uf]: s1.GEQUAL,
        [Lf]: s1.GREATER,
        [If]: s1.NOTEQUAL
    };
    function Tt(C, S, B) {
        if (B ? (s1.texParameteri(C, s1.TEXTURE_WRAP_S, ut[S.wrapS]), s1.texParameteri(C, s1.TEXTURE_WRAP_T, ut[S.wrapT]), (C === s1.TEXTURE_3D || C === s1.TEXTURE_2D_ARRAY) && s1.texParameteri(C, s1.TEXTURE_WRAP_R, ut[S.wrapR]), s1.texParameteri(C, s1.TEXTURE_MAG_FILTER, pt[S.magFilter]), s1.texParameteri(C, s1.TEXTURE_MIN_FILTER, pt[S.minFilter])) : (s1.texParameteri(C, s1.TEXTURE_WRAP_S, s1.CLAMP_TO_EDGE), s1.texParameteri(C, s1.TEXTURE_WRAP_T, s1.CLAMP_TO_EDGE), (C === s1.TEXTURE_3D || C === s1.TEXTURE_2D_ARRAY) && s1.texParameteri(C, s1.TEXTURE_WRAP_R, s1.CLAMP_TO_EDGE), (S.wrapS !== Ce || S.wrapT !== Ce) && console.warn("THREE.WebGLRenderer: Texture is not power of two. Texture.wrapS and Texture.wrapT should be set to THREE.ClampToEdgeWrapping."), s1.texParameteri(C, s1.TEXTURE_MAG_FILTER, E(S.magFilter)), s1.texParameteri(C, s1.TEXTURE_MIN_FILTER, E(S.minFilter)), S.minFilter !== fe && S.minFilter !== pe && console.warn("THREE.WebGLRenderer: Texture is not power of two. Texture.minFilter should be set to THREE.NearestFilter or THREE.LinearFilter.")), S.compareFunction && (s1.texParameteri(C, s1.TEXTURE_COMPARE_MODE, s1.COMPARE_REF_TO_TEXTURE), s1.texParameteri(C, s1.TEXTURE_COMPARE_FUNC, Et[S.compareFunction])), t.has("EXT_texture_filter_anisotropic") === !0) {
            let nt = t.get("EXT_texture_filter_anisotropic");
            if (S.magFilter === fe || S.minFilter !== Ir && S.minFilter !== li || S.type === xn && t.has("OES_texture_float_linear") === !1 || o === !1 && S.type === Ts && t.has("OES_texture_half_float_linear") === !1) return;
            (S.anisotropy > 1 || n.get(S).__currentAnisotropy) && (s1.texParameterf(C, nt.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(S.anisotropy, i.getMaxAnisotropy())), n.get(S).__currentAnisotropy = S.anisotropy);
        }
    }
    function wt(C, S) {
        let B = !1;
        C.__webglInit === void 0 && (C.__webglInit = !0, S.addEventListener("dispose", V));
        let nt = S.source, et = g.get(nt);
        et === void 0 && (et = {}, g.set(nt, et));
        let it = j(S);
        if (it !== C.__cacheKey) {
            et[it] === void 0 && (et[it] = {
                texture: s1.createTexture(),
                usedTimes: 0
            }, a.memory.textures++, B = !0), et[it].usedTimes++;
            let Mt = et[C.__cacheKey];
            Mt !== void 0 && (et[C.__cacheKey].usedTimes--, Mt.usedTimes === 0 && O(S)), C.__cacheKey = it, C.__webglTexture = et[it].texture;
        }
        return B;
    }
    function Yt(C, S, B) {
        let nt = s1.TEXTURE_2D;
        (S.isDataArrayTexture || S.isCompressedArrayTexture) && (nt = s1.TEXTURE_2D_ARRAY), S.isData3DTexture && (nt = s1.TEXTURE_3D);
        let et = wt(C, S), it = S.source;
        e.bindTexture(nt, C.__webglTexture, s1.TEXTURE0 + B);
        let Mt = n.get(it);
        if (it.version !== Mt.__version || et === !0) {
            e.activeTexture(s1.TEXTURE0 + B), s1.pixelStorei(s1.UNPACK_FLIP_Y_WEBGL, S.flipY), s1.pixelStorei(s1.UNPACK_PREMULTIPLY_ALPHA_WEBGL, S.premultiplyAlpha), s1.pixelStorei(s1.UNPACK_ALIGNMENT, S.unpackAlignment), s1.pixelStorei(s1.UNPACK_COLORSPACE_CONVERSION_WEBGL, s1.NONE);
            let rt = b(S) && y(S.image) === !1, k = _(S.image, rt, !1, h);
            k = ie(S, k);
            let Rt = y(k) || o, bt = r.convert(S.format, S.colorSpace), At = r.convert(S.type), vt = L(S.internalFormat, bt, At, S.colorSpace);
            Tt(nt, S, Rt);
            let yt, Ht = S.mipmaps, Qt = o && S.isVideoTexture !== !0, I = Mt.__version === void 0 || et === !0, ht = M(S, k, Rt);
            if (S.isDepthTexture) vt = s1.DEPTH_COMPONENT, o ? S.type === xn ? vt = s1.DEPTH_COMPONENT32F : S.type === Pn ? vt = s1.DEPTH_COMPONENT24 : S.type === ni ? vt = s1.DEPTH24_STENCIL8 : vt = s1.DEPTH_COMPONENT16 : S.type === xn && console.error("WebGLRenderer: Floating point depth texture requires WebGL2."), S.format === ii && vt === s1.DEPTH_COMPONENT && S.type !== Bc && S.type !== Pn && (console.warn("THREE.WebGLRenderer: Use UnsignedShortType or UnsignedIntType for DepthFormat DepthTexture."), S.type = Pn, At = r.convert(S.type)), S.format === Yi && vt === s1.DEPTH_COMPONENT && (vt = s1.DEPTH_STENCIL, S.type !== ni && (console.warn("THREE.WebGLRenderer: Use UnsignedInt248Type for DepthStencilFormat DepthTexture."), S.type = ni, At = r.convert(S.type))), I && (Qt ? e.texStorage2D(s1.TEXTURE_2D, 1, vt, k.width, k.height) : e.texImage2D(s1.TEXTURE_2D, 0, vt, k.width, k.height, 0, bt, At, null));
            else if (S.isDataTexture) if (Ht.length > 0 && Rt) {
                Qt && I && e.texStorage2D(s1.TEXTURE_2D, ht, vt, Ht[0].width, Ht[0].height);
                for(let H = 0, ot = Ht.length; H < ot; H++)yt = Ht[H], Qt ? e.texSubImage2D(s1.TEXTURE_2D, H, 0, 0, yt.width, yt.height, bt, At, yt.data) : e.texImage2D(s1.TEXTURE_2D, H, vt, yt.width, yt.height, 0, bt, At, yt.data);
                S.generateMipmaps = !1;
            } else Qt ? (I && e.texStorage2D(s1.TEXTURE_2D, ht, vt, k.width, k.height), e.texSubImage2D(s1.TEXTURE_2D, 0, 0, 0, k.width, k.height, bt, At, k.data)) : e.texImage2D(s1.TEXTURE_2D, 0, vt, k.width, k.height, 0, bt, At, k.data);
            else if (S.isCompressedTexture) if (S.isCompressedArrayTexture) {
                Qt && I && e.texStorage3D(s1.TEXTURE_2D_ARRAY, ht, vt, Ht[0].width, Ht[0].height, k.depth);
                for(let H = 0, ot = Ht.length; H < ot; H++)yt = Ht[H], S.format !== He ? bt !== null ? Qt ? e.compressedTexSubImage3D(s1.TEXTURE_2D_ARRAY, H, 0, 0, 0, yt.width, yt.height, k.depth, bt, yt.data, 0, 0) : e.compressedTexImage3D(s1.TEXTURE_2D_ARRAY, H, vt, yt.width, yt.height, k.depth, 0, yt.data, 0, 0) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()") : Qt ? e.texSubImage3D(s1.TEXTURE_2D_ARRAY, H, 0, 0, 0, yt.width, yt.height, k.depth, bt, At, yt.data) : e.texImage3D(s1.TEXTURE_2D_ARRAY, H, vt, yt.width, yt.height, k.depth, 0, bt, At, yt.data);
            } else {
                Qt && I && e.texStorage2D(s1.TEXTURE_2D, ht, vt, Ht[0].width, Ht[0].height);
                for(let H = 0, ot = Ht.length; H < ot; H++)yt = Ht[H], S.format !== He ? bt !== null ? Qt ? e.compressedTexSubImage2D(s1.TEXTURE_2D, H, 0, 0, yt.width, yt.height, bt, yt.data) : e.compressedTexImage2D(s1.TEXTURE_2D, H, vt, yt.width, yt.height, 0, yt.data) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()") : Qt ? e.texSubImage2D(s1.TEXTURE_2D, H, 0, 0, yt.width, yt.height, bt, At, yt.data) : e.texImage2D(s1.TEXTURE_2D, H, vt, yt.width, yt.height, 0, bt, At, yt.data);
            }
            else if (S.isDataArrayTexture) Qt ? (I && e.texStorage3D(s1.TEXTURE_2D_ARRAY, ht, vt, k.width, k.height, k.depth), e.texSubImage3D(s1.TEXTURE_2D_ARRAY, 0, 0, 0, 0, k.width, k.height, k.depth, bt, At, k.data)) : e.texImage3D(s1.TEXTURE_2D_ARRAY, 0, vt, k.width, k.height, k.depth, 0, bt, At, k.data);
            else if (S.isData3DTexture) Qt ? (I && e.texStorage3D(s1.TEXTURE_3D, ht, vt, k.width, k.height, k.depth), e.texSubImage3D(s1.TEXTURE_3D, 0, 0, 0, 0, k.width, k.height, k.depth, bt, At, k.data)) : e.texImage3D(s1.TEXTURE_3D, 0, vt, k.width, k.height, k.depth, 0, bt, At, k.data);
            else if (S.isFramebufferTexture) {
                if (I) if (Qt) e.texStorage2D(s1.TEXTURE_2D, ht, vt, k.width, k.height);
                else {
                    let H = k.width, ot = k.height;
                    for(let dt = 0; dt < ht; dt++)e.texImage2D(s1.TEXTURE_2D, dt, vt, H, ot, 0, bt, At, null), H >>= 1, ot >>= 1;
                }
            } else if (Ht.length > 0 && Rt) {
                Qt && I && e.texStorage2D(s1.TEXTURE_2D, ht, vt, Ht[0].width, Ht[0].height);
                for(let H = 0, ot = Ht.length; H < ot; H++)yt = Ht[H], Qt ? e.texSubImage2D(s1.TEXTURE_2D, H, 0, 0, bt, At, yt) : e.texImage2D(s1.TEXTURE_2D, H, vt, bt, At, yt);
                S.generateMipmaps = !1;
            } else Qt ? (I && e.texStorage2D(s1.TEXTURE_2D, ht, vt, k.width, k.height), e.texSubImage2D(s1.TEXTURE_2D, 0, 0, 0, bt, At, k)) : e.texImage2D(s1.TEXTURE_2D, 0, vt, bt, At, k);
            w(S, Rt) && R(nt), Mt.__version = it.version, S.onUpdate && S.onUpdate(S);
        }
        C.__version = S.version;
    }
    function te(C, S, B) {
        if (S.image.length !== 6) return;
        let nt = wt(C, S), et = S.source;
        e.bindTexture(s1.TEXTURE_CUBE_MAP, C.__webglTexture, s1.TEXTURE0 + B);
        let it = n.get(et);
        if (et.version !== it.__version || nt === !0) {
            e.activeTexture(s1.TEXTURE0 + B), s1.pixelStorei(s1.UNPACK_FLIP_Y_WEBGL, S.flipY), s1.pixelStorei(s1.UNPACK_PREMULTIPLY_ALPHA_WEBGL, S.premultiplyAlpha), s1.pixelStorei(s1.UNPACK_ALIGNMENT, S.unpackAlignment), s1.pixelStorei(s1.UNPACK_COLORSPACE_CONVERSION_WEBGL, s1.NONE);
            let Mt = S.isCompressedTexture || S.image[0].isCompressedTexture, rt = S.image[0] && S.image[0].isDataTexture, k = [];
            for(let H = 0; H < 6; H++)!Mt && !rt ? k[H] = _(S.image[H], !1, !0, l) : k[H] = rt ? S.image[H].image : S.image[H], k[H] = ie(S, k[H]);
            let Rt = k[0], bt = y(Rt) || o, At = r.convert(S.format, S.colorSpace), vt = r.convert(S.type), yt = L(S.internalFormat, At, vt, S.colorSpace), Ht = o && S.isVideoTexture !== !0, Qt = it.__version === void 0 || nt === !0, I = M(S, Rt, bt);
            Tt(s1.TEXTURE_CUBE_MAP, S, bt);
            let ht;
            if (Mt) {
                Ht && Qt && e.texStorage2D(s1.TEXTURE_CUBE_MAP, I, yt, Rt.width, Rt.height);
                for(let H = 0; H < 6; H++){
                    ht = k[H].mipmaps;
                    for(let ot = 0; ot < ht.length; ot++){
                        let dt = ht[ot];
                        S.format !== He ? At !== null ? Ht ? e.compressedTexSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot, 0, 0, dt.width, dt.height, At, dt.data) : e.compressedTexImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot, yt, dt.width, dt.height, 0, dt.data) : console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()") : Ht ? e.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot, 0, 0, dt.width, dt.height, At, vt, dt.data) : e.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot, yt, dt.width, dt.height, 0, At, vt, dt.data);
                    }
                }
            } else {
                ht = S.mipmaps, Ht && Qt && (ht.length > 0 && I++, e.texStorage2D(s1.TEXTURE_CUBE_MAP, I, yt, k[0].width, k[0].height));
                for(let H = 0; H < 6; H++)if (rt) {
                    Ht ? e.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, 0, 0, 0, k[H].width, k[H].height, At, vt, k[H].data) : e.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, 0, yt, k[H].width, k[H].height, 0, At, vt, k[H].data);
                    for(let ot = 0; ot < ht.length; ot++){
                        let qt = ht[ot].image[H].image;
                        Ht ? e.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot + 1, 0, 0, qt.width, qt.height, At, vt, qt.data) : e.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot + 1, yt, qt.width, qt.height, 0, At, vt, qt.data);
                    }
                } else {
                    Ht ? e.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, 0, 0, 0, At, vt, k[H]) : e.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, 0, yt, At, vt, k[H]);
                    for(let ot = 0; ot < ht.length; ot++){
                        let dt = ht[ot];
                        Ht ? e.texSubImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot + 1, 0, 0, At, vt, dt.image[H]) : e.texImage2D(s1.TEXTURE_CUBE_MAP_POSITIVE_X + H, ot + 1, yt, At, vt, dt.image[H]);
                    }
                }
            }
            w(S, bt) && R(s1.TEXTURE_CUBE_MAP), it.__version = et.version, S.onUpdate && S.onUpdate(S);
        }
        C.__version = S.version;
    }
    function Pt(C, S, B, nt, et, it) {
        let Mt = r.convert(B.format, B.colorSpace), rt = r.convert(B.type), k = L(B.internalFormat, Mt, rt, B.colorSpace);
        if (!n.get(S).__hasExternalTextures) {
            let bt = Math.max(1, S.width >> it), At = Math.max(1, S.height >> it);
            et === s1.TEXTURE_3D || et === s1.TEXTURE_2D_ARRAY ? e.texImage3D(et, it, k, bt, At, S.depth, 0, Mt, rt, null) : e.texImage2D(et, it, k, bt, At, 0, Mt, rt, null);
        }
        e.bindFramebuffer(s1.FRAMEBUFFER, C), Dt(S) ? d.framebufferTexture2DMultisampleEXT(s1.FRAMEBUFFER, nt, et, n.get(B).__webglTexture, 0, xt(S)) : (et === s1.TEXTURE_2D || et >= s1.TEXTURE_CUBE_MAP_POSITIVE_X && et <= s1.TEXTURE_CUBE_MAP_NEGATIVE_Z) && s1.framebufferTexture2D(s1.FRAMEBUFFER, nt, et, n.get(B).__webglTexture, it), e.bindFramebuffer(s1.FRAMEBUFFER, null);
    }
    function P(C, S, B) {
        if (s1.bindRenderbuffer(s1.RENDERBUFFER, C), S.depthBuffer && !S.stencilBuffer) {
            let nt = s1.DEPTH_COMPONENT16;
            if (B || Dt(S)) {
                let et = S.depthTexture;
                et && et.isDepthTexture && (et.type === xn ? nt = s1.DEPTH_COMPONENT32F : et.type === Pn && (nt = s1.DEPTH_COMPONENT24));
                let it = xt(S);
                Dt(S) ? d.renderbufferStorageMultisampleEXT(s1.RENDERBUFFER, it, nt, S.width, S.height) : s1.renderbufferStorageMultisample(s1.RENDERBUFFER, it, nt, S.width, S.height);
            } else s1.renderbufferStorage(s1.RENDERBUFFER, nt, S.width, S.height);
            s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.DEPTH_ATTACHMENT, s1.RENDERBUFFER, C);
        } else if (S.depthBuffer && S.stencilBuffer) {
            let nt = xt(S);
            B && Dt(S) === !1 ? s1.renderbufferStorageMultisample(s1.RENDERBUFFER, nt, s1.DEPTH24_STENCIL8, S.width, S.height) : Dt(S) ? d.renderbufferStorageMultisampleEXT(s1.RENDERBUFFER, nt, s1.DEPTH24_STENCIL8, S.width, S.height) : s1.renderbufferStorage(s1.RENDERBUFFER, s1.DEPTH_STENCIL, S.width, S.height), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.DEPTH_STENCIL_ATTACHMENT, s1.RENDERBUFFER, C);
        } else {
            let nt = S.isWebGLMultipleRenderTargets === !0 ? S.texture : [
                S.texture
            ];
            for(let et = 0; et < nt.length; et++){
                let it = nt[et], Mt = r.convert(it.format, it.colorSpace), rt = r.convert(it.type), k = L(it.internalFormat, Mt, rt, it.colorSpace), Rt = xt(S);
                B && Dt(S) === !1 ? s1.renderbufferStorageMultisample(s1.RENDERBUFFER, Rt, k, S.width, S.height) : Dt(S) ? d.renderbufferStorageMultisampleEXT(s1.RENDERBUFFER, Rt, k, S.width, S.height) : s1.renderbufferStorage(s1.RENDERBUFFER, k, S.width, S.height);
            }
        }
        s1.bindRenderbuffer(s1.RENDERBUFFER, null);
    }
    function at(C, S) {
        if (S && S.isWebGLCubeRenderTarget) throw new Error("Depth Texture with cube render targets is not supported");
        if (e.bindFramebuffer(s1.FRAMEBUFFER, C), !(S.depthTexture && S.depthTexture.isDepthTexture)) throw new Error("renderTarget.depthTexture must be an instance of THREE.DepthTexture");
        (!n.get(S.depthTexture).__webglTexture || S.depthTexture.image.width !== S.width || S.depthTexture.image.height !== S.height) && (S.depthTexture.image.width = S.width, S.depthTexture.image.height = S.height, S.depthTexture.needsUpdate = !0), tt(S.depthTexture, 0);
        let nt = n.get(S.depthTexture).__webglTexture, et = xt(S);
        if (S.depthTexture.format === ii) Dt(S) ? d.framebufferTexture2DMultisampleEXT(s1.FRAMEBUFFER, s1.DEPTH_ATTACHMENT, s1.TEXTURE_2D, nt, 0, et) : s1.framebufferTexture2D(s1.FRAMEBUFFER, s1.DEPTH_ATTACHMENT, s1.TEXTURE_2D, nt, 0);
        else if (S.depthTexture.format === Yi) Dt(S) ? d.framebufferTexture2DMultisampleEXT(s1.FRAMEBUFFER, s1.DEPTH_STENCIL_ATTACHMENT, s1.TEXTURE_2D, nt, 0, et) : s1.framebufferTexture2D(s1.FRAMEBUFFER, s1.DEPTH_STENCIL_ATTACHMENT, s1.TEXTURE_2D, nt, 0);
        else throw new Error("Unknown depthTexture format");
    }
    function Z(C) {
        let S = n.get(C), B = C.isWebGLCubeRenderTarget === !0;
        if (C.depthTexture && !S.__autoAllocateDepthBuffer) {
            if (B) throw new Error("target.depthTexture not supported in Cube render targets");
            at(S.__webglFramebuffer, C);
        } else if (B) {
            S.__webglDepthbuffer = [];
            for(let nt = 0; nt < 6; nt++)e.bindFramebuffer(s1.FRAMEBUFFER, S.__webglFramebuffer[nt]), S.__webglDepthbuffer[nt] = s1.createRenderbuffer(), P(S.__webglDepthbuffer[nt], C, !1);
        } else e.bindFramebuffer(s1.FRAMEBUFFER, S.__webglFramebuffer), S.__webglDepthbuffer = s1.createRenderbuffer(), P(S.__webglDepthbuffer, C, !1);
        e.bindFramebuffer(s1.FRAMEBUFFER, null);
    }
    function st(C, S, B) {
        let nt = n.get(C);
        S !== void 0 && Pt(nt.__webglFramebuffer, C, C.texture, s1.COLOR_ATTACHMENT0, s1.TEXTURE_2D, 0), B !== void 0 && Z(C);
    }
    function Q(C) {
        let S = C.texture, B = n.get(C), nt = n.get(S);
        C.addEventListener("dispose", $), C.isWebGLMultipleRenderTargets !== !0 && (nt.__webglTexture === void 0 && (nt.__webglTexture = s1.createTexture()), nt.__version = S.version, a.memory.textures++);
        let et = C.isWebGLCubeRenderTarget === !0, it = C.isWebGLMultipleRenderTargets === !0, Mt = y(C) || o;
        if (et) {
            B.__webglFramebuffer = [];
            for(let rt = 0; rt < 6; rt++)if (o && S.mipmaps && S.mipmaps.length > 0) {
                B.__webglFramebuffer[rt] = [];
                for(let k = 0; k < S.mipmaps.length; k++)B.__webglFramebuffer[rt][k] = s1.createFramebuffer();
            } else B.__webglFramebuffer[rt] = s1.createFramebuffer();
        } else {
            if (o && S.mipmaps && S.mipmaps.length > 0) {
                B.__webglFramebuffer = [];
                for(let rt = 0; rt < S.mipmaps.length; rt++)B.__webglFramebuffer[rt] = s1.createFramebuffer();
            } else B.__webglFramebuffer = s1.createFramebuffer();
            if (it) if (i.drawBuffers) {
                let rt = C.texture;
                for(let k = 0, Rt = rt.length; k < Rt; k++){
                    let bt = n.get(rt[k]);
                    bt.__webglTexture === void 0 && (bt.__webglTexture = s1.createTexture(), a.memory.textures++);
                }
            } else console.warn("THREE.WebGLRenderer: WebGLMultipleRenderTargets can only be used with WebGL2 or WEBGL_draw_buffers extension.");
            if (o && C.samples > 0 && Dt(C) === !1) {
                let rt = it ? S : [
                    S
                ];
                B.__webglMultisampledFramebuffer = s1.createFramebuffer(), B.__webglColorRenderbuffer = [], e.bindFramebuffer(s1.FRAMEBUFFER, B.__webglMultisampledFramebuffer);
                for(let k = 0; k < rt.length; k++){
                    let Rt = rt[k];
                    B.__webglColorRenderbuffer[k] = s1.createRenderbuffer(), s1.bindRenderbuffer(s1.RENDERBUFFER, B.__webglColorRenderbuffer[k]);
                    let bt = r.convert(Rt.format, Rt.colorSpace), At = r.convert(Rt.type), vt = L(Rt.internalFormat, bt, At, Rt.colorSpace, C.isXRRenderTarget === !0), yt = xt(C);
                    s1.renderbufferStorageMultisample(s1.RENDERBUFFER, yt, vt, C.width, C.height), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + k, s1.RENDERBUFFER, B.__webglColorRenderbuffer[k]);
                }
                s1.bindRenderbuffer(s1.RENDERBUFFER, null), C.depthBuffer && (B.__webglDepthRenderbuffer = s1.createRenderbuffer(), P(B.__webglDepthRenderbuffer, C, !0)), e.bindFramebuffer(s1.FRAMEBUFFER, null);
            }
        }
        if (et) {
            e.bindTexture(s1.TEXTURE_CUBE_MAP, nt.__webglTexture), Tt(s1.TEXTURE_CUBE_MAP, S, Mt);
            for(let rt = 0; rt < 6; rt++)if (o && S.mipmaps && S.mipmaps.length > 0) for(let k = 0; k < S.mipmaps.length; k++)Pt(B.__webglFramebuffer[rt][k], C, S, s1.COLOR_ATTACHMENT0, s1.TEXTURE_CUBE_MAP_POSITIVE_X + rt, k);
            else Pt(B.__webglFramebuffer[rt], C, S, s1.COLOR_ATTACHMENT0, s1.TEXTURE_CUBE_MAP_POSITIVE_X + rt, 0);
            w(S, Mt) && R(s1.TEXTURE_CUBE_MAP), e.unbindTexture();
        } else if (it) {
            let rt = C.texture;
            for(let k = 0, Rt = rt.length; k < Rt; k++){
                let bt = rt[k], At = n.get(bt);
                e.bindTexture(s1.TEXTURE_2D, At.__webglTexture), Tt(s1.TEXTURE_2D, bt, Mt), Pt(B.__webglFramebuffer, C, bt, s1.COLOR_ATTACHMENT0 + k, s1.TEXTURE_2D, 0), w(bt, Mt) && R(s1.TEXTURE_2D);
            }
            e.unbindTexture();
        } else {
            let rt = s1.TEXTURE_2D;
            if ((C.isWebGL3DRenderTarget || C.isWebGLArrayRenderTarget) && (o ? rt = C.isWebGL3DRenderTarget ? s1.TEXTURE_3D : s1.TEXTURE_2D_ARRAY : console.error("THREE.WebGLTextures: THREE.Data3DTexture and THREE.DataArrayTexture only supported with WebGL2.")), e.bindTexture(rt, nt.__webglTexture), Tt(rt, S, Mt), o && S.mipmaps && S.mipmaps.length > 0) for(let k = 0; k < S.mipmaps.length; k++)Pt(B.__webglFramebuffer[k], C, S, s1.COLOR_ATTACHMENT0, rt, k);
            else Pt(B.__webglFramebuffer, C, S, s1.COLOR_ATTACHMENT0, rt, 0);
            w(S, Mt) && R(rt), e.unbindTexture();
        }
        C.depthBuffer && Z(C);
    }
    function St(C) {
        let S = y(C) || o, B = C.isWebGLMultipleRenderTargets === !0 ? C.texture : [
            C.texture
        ];
        for(let nt = 0, et = B.length; nt < et; nt++){
            let it = B[nt];
            if (w(it, S)) {
                let Mt = C.isWebGLCubeRenderTarget ? s1.TEXTURE_CUBE_MAP : s1.TEXTURE_2D, rt = n.get(it).__webglTexture;
                e.bindTexture(Mt, rt), R(Mt), e.unbindTexture();
            }
        }
    }
    function mt(C) {
        if (o && C.samples > 0 && Dt(C) === !1) {
            let S = C.isWebGLMultipleRenderTargets ? C.texture : [
                C.texture
            ], B = C.width, nt = C.height, et = s1.COLOR_BUFFER_BIT, it = [], Mt = C.stencilBuffer ? s1.DEPTH_STENCIL_ATTACHMENT : s1.DEPTH_ATTACHMENT, rt = n.get(C), k = C.isWebGLMultipleRenderTargets === !0;
            if (k) for(let Rt = 0; Rt < S.length; Rt++)e.bindFramebuffer(s1.FRAMEBUFFER, rt.__webglMultisampledFramebuffer), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Rt, s1.RENDERBUFFER, null), e.bindFramebuffer(s1.FRAMEBUFFER, rt.__webglFramebuffer), s1.framebufferTexture2D(s1.DRAW_FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Rt, s1.TEXTURE_2D, null, 0);
            e.bindFramebuffer(s1.READ_FRAMEBUFFER, rt.__webglMultisampledFramebuffer), e.bindFramebuffer(s1.DRAW_FRAMEBUFFER, rt.__webglFramebuffer);
            for(let Rt = 0; Rt < S.length; Rt++){
                it.push(s1.COLOR_ATTACHMENT0 + Rt), C.depthBuffer && it.push(Mt);
                let bt = rt.__ignoreDepthValues !== void 0 ? rt.__ignoreDepthValues : !1;
                if (bt === !1 && (C.depthBuffer && (et |= s1.DEPTH_BUFFER_BIT), C.stencilBuffer && (et |= s1.STENCIL_BUFFER_BIT)), k && s1.framebufferRenderbuffer(s1.READ_FRAMEBUFFER, s1.COLOR_ATTACHMENT0, s1.RENDERBUFFER, rt.__webglColorRenderbuffer[Rt]), bt === !0 && (s1.invalidateFramebuffer(s1.READ_FRAMEBUFFER, [
                    Mt
                ]), s1.invalidateFramebuffer(s1.DRAW_FRAMEBUFFER, [
                    Mt
                ])), k) {
                    let At = n.get(S[Rt]).__webglTexture;
                    s1.framebufferTexture2D(s1.DRAW_FRAMEBUFFER, s1.COLOR_ATTACHMENT0, s1.TEXTURE_2D, At, 0);
                }
                s1.blitFramebuffer(0, 0, B, nt, 0, 0, B, nt, et, s1.NEAREST), f && s1.invalidateFramebuffer(s1.READ_FRAMEBUFFER, it);
            }
            if (e.bindFramebuffer(s1.READ_FRAMEBUFFER, null), e.bindFramebuffer(s1.DRAW_FRAMEBUFFER, null), k) for(let Rt = 0; Rt < S.length; Rt++){
                e.bindFramebuffer(s1.FRAMEBUFFER, rt.__webglMultisampledFramebuffer), s1.framebufferRenderbuffer(s1.FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Rt, s1.RENDERBUFFER, rt.__webglColorRenderbuffer[Rt]);
                let bt = n.get(S[Rt]).__webglTexture;
                e.bindFramebuffer(s1.FRAMEBUFFER, rt.__webglFramebuffer), s1.framebufferTexture2D(s1.DRAW_FRAMEBUFFER, s1.COLOR_ATTACHMENT0 + Rt, s1.TEXTURE_2D, bt, 0);
            }
            e.bindFramebuffer(s1.DRAW_FRAMEBUFFER, rt.__webglMultisampledFramebuffer);
        }
    }
    function xt(C) {
        return Math.min(u, C.samples);
    }
    function Dt(C) {
        let S = n.get(C);
        return o && C.samples > 0 && t.has("WEBGL_multisampled_render_to_texture") === !0 && S.__useRenderToTexture !== !1;
    }
    function Xt(C) {
        let S = a.render.frame;
        m.get(C) !== S && (m.set(C, S), C.update());
    }
    function ie(C, S) {
        let B = C.colorSpace, nt = C.format, et = C.type;
        return C.isCompressedTexture === !0 || C.format === co || B !== nn && B !== ri && (B === Nt ? o === !1 ? t.has("EXT_sRGB") === !0 && nt === He ? (C.format = co, C.minFilter = pe, C.generateMipmaps = !1) : S = Gr.sRGBToLinear(S) : (nt !== He || et !== Nn) && console.warn("THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType.") : console.error("THREE.WebGLTextures: Unsupported texture color space:", B)), S;
    }
    this.allocateTextureUnit = Y, this.resetTextureUnits = X, this.setTexture2D = tt, this.setTexture2DArray = N, this.setTexture3D = q, this.setTextureCube = lt, this.rebindTextures = st, this.setupRenderTarget = Q, this.updateRenderTargetMipmap = St, this.updateMultisampleRenderTarget = mt, this.setupDepthRenderbuffer = Z, this.setupFrameBufferTexture = Pt, this.useMultisampledRTT = Dt;
}
function O0(s1, t, e) {
    let n = e.isWebGL2;
    function i(r, a = ri) {
        let o;
        if (r === Nn) return s1.UNSIGNED_BYTE;
        if (r === od) return s1.UNSIGNED_SHORT_4_4_4_4;
        if (r === cd) return s1.UNSIGNED_SHORT_5_5_5_1;
        if (r === uf) return s1.BYTE;
        if (r === df) return s1.SHORT;
        if (r === Bc) return s1.UNSIGNED_SHORT;
        if (r === ad) return s1.INT;
        if (r === Pn) return s1.UNSIGNED_INT;
        if (r === xn) return s1.FLOAT;
        if (r === Ts) return n ? s1.HALF_FLOAT : (o = t.get("OES_texture_half_float"), o !== null ? o.HALF_FLOAT_OES : null);
        if (r === ff) return s1.ALPHA;
        if (r === He) return s1.RGBA;
        if (r === pf) return s1.LUMINANCE;
        if (r === mf) return s1.LUMINANCE_ALPHA;
        if (r === ii) return s1.DEPTH_COMPONENT;
        if (r === Yi) return s1.DEPTH_STENCIL;
        if (r === co) return o = t.get("EXT_sRGB"), o !== null ? o.SRGB_ALPHA_EXT : null;
        if (r === gf) return s1.RED;
        if (r === ld) return s1.RED_INTEGER;
        if (r === _f) return s1.RG;
        if (r === hd) return s1.RG_INTEGER;
        if (r === ud) return s1.RGBA_INTEGER;
        if (r === Ma || r === Sa || r === ba || r === Ea) if (a === Nt) if (o = t.get("WEBGL_compressed_texture_s3tc_srgb"), o !== null) {
            if (r === Ma) return o.COMPRESSED_SRGB_S3TC_DXT1_EXT;
            if (r === Sa) return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
            if (r === ba) return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
            if (r === Ea) return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
        } else return null;
        else if (o = t.get("WEBGL_compressed_texture_s3tc"), o !== null) {
            if (r === Ma) return o.COMPRESSED_RGB_S3TC_DXT1_EXT;
            if (r === Sa) return o.COMPRESSED_RGBA_S3TC_DXT1_EXT;
            if (r === ba) return o.COMPRESSED_RGBA_S3TC_DXT3_EXT;
            if (r === Ea) return o.COMPRESSED_RGBA_S3TC_DXT5_EXT;
        } else return null;
        if (r === al || r === ol || r === cl || r === ll) if (o = t.get("WEBGL_compressed_texture_pvrtc"), o !== null) {
            if (r === al) return o.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            if (r === ol) return o.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            if (r === cl) return o.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            if (r === ll) return o.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
        } else return null;
        if (r === xf) return o = t.get("WEBGL_compressed_texture_etc1"), o !== null ? o.COMPRESSED_RGB_ETC1_WEBGL : null;
        if (r === hl || r === ul) if (o = t.get("WEBGL_compressed_texture_etc"), o !== null) {
            if (r === hl) return a === Nt ? o.COMPRESSED_SRGB8_ETC2 : o.COMPRESSED_RGB8_ETC2;
            if (r === ul) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : o.COMPRESSED_RGBA8_ETC2_EAC;
        } else return null;
        if (r === dl || r === fl || r === pl || r === ml || r === gl || r === _l || r === xl || r === vl || r === yl || r === Ml || r === Sl || r === bl || r === El || r === Tl) if (o = t.get("WEBGL_compressed_texture_astc"), o !== null) {
            if (r === dl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : o.COMPRESSED_RGBA_ASTC_4x4_KHR;
            if (r === fl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : o.COMPRESSED_RGBA_ASTC_5x4_KHR;
            if (r === pl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : o.COMPRESSED_RGBA_ASTC_5x5_KHR;
            if (r === ml) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : o.COMPRESSED_RGBA_ASTC_6x5_KHR;
            if (r === gl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : o.COMPRESSED_RGBA_ASTC_6x6_KHR;
            if (r === _l) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : o.COMPRESSED_RGBA_ASTC_8x5_KHR;
            if (r === xl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : o.COMPRESSED_RGBA_ASTC_8x6_KHR;
            if (r === vl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : o.COMPRESSED_RGBA_ASTC_8x8_KHR;
            if (r === yl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : o.COMPRESSED_RGBA_ASTC_10x5_KHR;
            if (r === Ml) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : o.COMPRESSED_RGBA_ASTC_10x6_KHR;
            if (r === Sl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : o.COMPRESSED_RGBA_ASTC_10x8_KHR;
            if (r === bl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : o.COMPRESSED_RGBA_ASTC_10x10_KHR;
            if (r === El) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : o.COMPRESSED_RGBA_ASTC_12x10_KHR;
            if (r === Tl) return a === Nt ? o.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : o.COMPRESSED_RGBA_ASTC_12x12_KHR;
        } else return null;
        if (r === Ta) if (o = t.get("EXT_texture_compression_bptc"), o !== null) {
            if (r === Ta) return a === Nt ? o.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : o.COMPRESSED_RGBA_BPTC_UNORM_EXT;
        } else return null;
        if (r === vf || r === wl || r === Al || r === Rl) if (o = t.get("EXT_texture_compression_rgtc"), o !== null) {
            if (r === Ta) return o.COMPRESSED_RED_RGTC1_EXT;
            if (r === wl) return o.COMPRESSED_SIGNED_RED_RGTC1_EXT;
            if (r === Al) return o.COMPRESSED_RED_GREEN_RGTC2_EXT;
            if (r === Rl) return o.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
        } else return null;
        return r === ni ? n ? s1.UNSIGNED_INT_24_8 : (o = t.get("WEBGL_depth_texture"), o !== null ? o.UNSIGNED_INT_24_8_WEBGL : null) : s1[r] !== void 0 ? s1[r] : null;
    }
    return {
        convert: i
    };
}
var yo = class extends xe {
    constructor(t = []){
        super(), this.isArrayCamera = !0, this.cameras = t;
    }
}, ti = class extends Zt {
    constructor(){
        super(), this.isGroup = !0, this.type = "Group";
    }
}, B0 = {
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
    dispatchEvent(t) {
        return this._targetRay !== null && this._targetRay.dispatchEvent(t), this._grip !== null && this._grip.dispatchEvent(t), this._hand !== null && this._hand.dispatchEvent(t), this;
    }
    connect(t) {
        if (t && t.hand) {
            let e = this._hand;
            if (e) for (let n of t.hand.values())this._getHandJoint(e, n);
        }
        return this.dispatchEvent({
            type: "connected",
            data: t
        }), this;
    }
    disconnect(t) {
        return this.dispatchEvent({
            type: "disconnected",
            data: t
        }), this._targetRay !== null && (this._targetRay.visible = !1), this._grip !== null && (this._grip.visible = !1), this._hand !== null && (this._hand.visible = !1), this;
    }
    update(t, e, n) {
        let i = null, r = null, a = null, o = this._targetRay, c = this._grip, l = this._hand;
        if (t && e.session.visibilityState !== "visible-blurred") {
            if (l && t.hand) {
                a = !0;
                for (let x of t.hand.values()){
                    let g = e.getJointPose(x, n), p = this._getHandJoint(l, x);
                    g !== null && (p.matrix.fromArray(g.transform.matrix), p.matrix.decompose(p.position, p.rotation, p.scale), p.matrixWorldNeedsUpdate = !0, p.jointRadius = g.radius), p.visible = g !== null;
                }
                let h = l.joints["index-finger-tip"], u = l.joints["thumb-tip"], d = h.position.distanceTo(u.position), f = .02, m = .005;
                l.inputState.pinching && d > f + m ? (l.inputState.pinching = !1, this.dispatchEvent({
                    type: "pinchend",
                    handedness: t.handedness,
                    target: this
                })) : !l.inputState.pinching && d <= f - m && (l.inputState.pinching = !0, this.dispatchEvent({
                    type: "pinchstart",
                    handedness: t.handedness,
                    target: this
                }));
            } else c !== null && t.gripSpace && (r = e.getPose(t.gripSpace, n), r !== null && (c.matrix.fromArray(r.transform.matrix), c.matrix.decompose(c.position, c.rotation, c.scale), c.matrixWorldNeedsUpdate = !0, r.linearVelocity ? (c.hasLinearVelocity = !0, c.linearVelocity.copy(r.linearVelocity)) : c.hasLinearVelocity = !1, r.angularVelocity ? (c.hasAngularVelocity = !0, c.angularVelocity.copy(r.angularVelocity)) : c.hasAngularVelocity = !1));
            o !== null && (i = e.getPose(t.targetRaySpace, n), i === null && r !== null && (i = r), i !== null && (o.matrix.fromArray(i.transform.matrix), o.matrix.decompose(o.position, o.rotation, o.scale), o.matrixWorldNeedsUpdate = !0, i.linearVelocity ? (o.hasLinearVelocity = !0, o.linearVelocity.copy(i.linearVelocity)) : o.hasLinearVelocity = !1, i.angularVelocity ? (o.hasAngularVelocity = !0, o.angularVelocity.copy(i.angularVelocity)) : o.hasAngularVelocity = !1, this.dispatchEvent(B0)));
        }
        return o !== null && (o.visible = i !== null), c !== null && (c.visible = r !== null), l !== null && (l.visible = a !== null), this;
    }
    _getHandJoint(t, e) {
        if (t.joints[e.jointName] === void 0) {
            let n = new ti;
            n.matrixAutoUpdate = !1, n.visible = !1, t.joints[e.jointName] = n, t.add(n);
        }
        return t.joints[e.jointName];
    }
}, Mo = class extends ye {
    constructor(t, e, n, i, r, a, o, c, l, h){
        if (h = h !== void 0 ? h : ii, h !== ii && h !== Yi) throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");
        n === void 0 && h === ii && (n = Pn), n === void 0 && h === Yi && (n = ni), super(null, i, r, a, o, c, h, n, l), this.isDepthTexture = !0, this.image = {
            width: t,
            height: e
        }, this.magFilter = o !== void 0 ? o : fe, this.minFilter = c !== void 0 ? c : fe, this.flipY = !1, this.generateMipmaps = !1, this.compareFunction = null;
    }
    copy(t) {
        return super.copy(t), this.compareFunction = t.compareFunction, this;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return this.compareFunction !== null && (e.compareFunction = this.compareFunction), e;
    }
}, So = class extends sn {
    constructor(t, e){
        super();
        let n = this, i = null, r = 1, a = null, o = "local-floor", c = 1, l = null, h = null, u = null, d = null, f = null, m = null, x = e.getContextAttributes(), g = null, p = null, v = [], _ = [], y = new xe;
        y.layers.enable(1), y.viewport = new $t;
        let b = new xe;
        b.layers.enable(2), b.viewport = new $t;
        let w = [
            y,
            b
        ], R = new yo;
        R.layers.enable(1), R.layers.enable(2);
        let L = null, M = null;
        this.cameraAutoUpdate = !0, this.enabled = !1, this.isPresenting = !1, this.getController = function(N) {
            let q = v[N];
            return q === void 0 && (q = new Ss, v[N] = q), q.getTargetRaySpace();
        }, this.getControllerGrip = function(N) {
            let q = v[N];
            return q === void 0 && (q = new Ss, v[N] = q), q.getGripSpace();
        }, this.getHand = function(N) {
            let q = v[N];
            return q === void 0 && (q = new Ss, v[N] = q), q.getHandSpace();
        };
        function E(N) {
            let q = _.indexOf(N.inputSource);
            if (q === -1) return;
            let lt = v[q];
            lt !== void 0 && (lt.update(N.inputSource, N.frame, l || a), lt.dispatchEvent({
                type: N.type,
                data: N.inputSource
            }));
        }
        function V() {
            i.removeEventListener("select", E), i.removeEventListener("selectstart", E), i.removeEventListener("selectend", E), i.removeEventListener("squeeze", E), i.removeEventListener("squeezestart", E), i.removeEventListener("squeezeend", E), i.removeEventListener("end", V), i.removeEventListener("inputsourceschange", $);
            for(let N = 0; N < v.length; N++){
                let q = _[N];
                q !== null && (_[N] = null, v[N].disconnect(q));
            }
            L = null, M = null, t.setRenderTarget(g), f = null, d = null, u = null, i = null, p = null, tt.stop(), n.isPresenting = !1, n.dispatchEvent({
                type: "sessionend"
            });
        }
        this.setFramebufferScaleFactor = function(N) {
            r = N, n.isPresenting === !0 && console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.");
        }, this.setReferenceSpaceType = function(N) {
            o = N, n.isPresenting === !0 && console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.");
        }, this.getReferenceSpace = function() {
            return l || a;
        }, this.setReferenceSpace = function(N) {
            l = N;
        }, this.getBaseLayer = function() {
            return d !== null ? d : f;
        }, this.getBinding = function() {
            return u;
        }, this.getFrame = function() {
            return m;
        }, this.getSession = function() {
            return i;
        }, this.setSession = async function(N) {
            if (i = N, i !== null) {
                if (g = t.getRenderTarget(), i.addEventListener("select", E), i.addEventListener("selectstart", E), i.addEventListener("selectend", E), i.addEventListener("squeeze", E), i.addEventListener("squeezestart", E), i.addEventListener("squeezeend", E), i.addEventListener("end", V), i.addEventListener("inputsourceschange", $), x.xrCompatible !== !0 && await e.makeXRCompatible(), i.renderState.layers === void 0 || t.capabilities.isWebGL2 === !1) {
                    let q = {
                        antialias: i.renderState.layers === void 0 ? x.antialias : !0,
                        alpha: !0,
                        depth: x.depth,
                        stencil: x.stencil,
                        framebufferScaleFactor: r
                    };
                    f = new XRWebGLLayer(i, e, q), i.updateRenderState({
                        baseLayer: f
                    }), p = new Ge(f.framebufferWidth, f.framebufferHeight, {
                        format: He,
                        type: Nn,
                        colorSpace: t.outputColorSpace,
                        stencilBuffer: x.stencil
                    });
                } else {
                    let q = null, lt = null, ut = null;
                    x.depth && (ut = x.stencil ? e.DEPTH24_STENCIL8 : e.DEPTH_COMPONENT24, q = x.stencil ? Yi : ii, lt = x.stencil ? ni : Pn);
                    let pt = {
                        colorFormat: e.RGBA8,
                        depthFormat: ut,
                        scaleFactor: r
                    };
                    u = new XRWebGLBinding(i, e), d = u.createProjectionLayer(pt), i.updateRenderState({
                        layers: [
                            d
                        ]
                    }), p = new Ge(d.textureWidth, d.textureHeight, {
                        format: He,
                        type: Nn,
                        depthTexture: new Mo(d.textureWidth, d.textureHeight, lt, void 0, void 0, void 0, void 0, void 0, void 0, q),
                        stencilBuffer: x.stencil,
                        colorSpace: t.outputColorSpace,
                        samples: x.antialias ? 4 : 0
                    });
                    let Et = t.properties.get(p);
                    Et.__ignoreDepthValues = d.ignoreDepthValues;
                }
                p.isXRRenderTarget = !0, this.setFoveation(c), l = null, a = await i.requestReferenceSpace(o), tt.setContext(i), tt.start(), n.isPresenting = !0, n.dispatchEvent({
                    type: "sessionstart"
                });
            }
        }, this.getEnvironmentBlendMode = function() {
            if (i !== null) return i.environmentBlendMode;
        };
        function $(N) {
            for(let q = 0; q < N.removed.length; q++){
                let lt = N.removed[q], ut = _.indexOf(lt);
                ut >= 0 && (_[ut] = null, v[ut].disconnect(lt));
            }
            for(let q = 0; q < N.added.length; q++){
                let lt = N.added[q], ut = _.indexOf(lt);
                if (ut === -1) {
                    for(let Et = 0; Et < v.length; Et++)if (Et >= _.length) {
                        _.push(lt), ut = Et;
                        break;
                    } else if (_[Et] === null) {
                        _[Et] = lt, ut = Et;
                        break;
                    }
                    if (ut === -1) break;
                }
                let pt = v[ut];
                pt && pt.connect(lt);
            }
        }
        let F = new A, O = new A;
        function z(N, q, lt) {
            F.setFromMatrixPosition(q.matrixWorld), O.setFromMatrixPosition(lt.matrixWorld);
            let ut = F.distanceTo(O), pt = q.projectionMatrix.elements, Et = lt.projectionMatrix.elements, Tt = pt[14] / (pt[10] - 1), wt = pt[14] / (pt[10] + 1), Yt = (pt[9] + 1) / pt[5], te = (pt[9] - 1) / pt[5], Pt = (pt[8] - 1) / pt[0], P = (Et[8] + 1) / Et[0], at = Tt * Pt, Z = Tt * P, st = ut / (-Pt + P), Q = st * -Pt;
            q.matrixWorld.decompose(N.position, N.quaternion, N.scale), N.translateX(Q), N.translateZ(st), N.matrixWorld.compose(N.position, N.quaternion, N.scale), N.matrixWorldInverse.copy(N.matrixWorld).invert();
            let St = Tt + st, mt = wt + st, xt = at - Q, Dt = Z + (ut - Q), Xt = Yt * wt / mt * St, ie = te * wt / mt * St;
            N.projectionMatrix.makePerspective(xt, Dt, Xt, ie, St, mt), N.projectionMatrixInverse.copy(N.projectionMatrix).invert();
        }
        function K(N, q) {
            q === null ? N.matrixWorld.copy(N.matrix) : N.matrixWorld.multiplyMatrices(q.matrixWorld, N.matrix), N.matrixWorldInverse.copy(N.matrixWorld).invert();
        }
        this.updateCamera = function(N) {
            if (i === null) return;
            R.near = b.near = y.near = N.near, R.far = b.far = y.far = N.far, (L !== R.near || M !== R.far) && (i.updateRenderState({
                depthNear: R.near,
                depthFar: R.far
            }), L = R.near, M = R.far);
            let q = N.parent, lt = R.cameras;
            K(R, q);
            for(let ut = 0; ut < lt.length; ut++)K(lt[ut], q);
            lt.length === 2 ? z(R, y, b) : R.projectionMatrix.copy(y.projectionMatrix), X(N, R, q);
        };
        function X(N, q, lt) {
            lt === null ? N.matrix.copy(q.matrixWorld) : (N.matrix.copy(lt.matrixWorld), N.matrix.invert(), N.matrix.multiply(q.matrixWorld)), N.matrix.decompose(N.position, N.quaternion, N.scale), N.updateMatrixWorld(!0);
            let ut = N.children;
            for(let pt = 0, Et = ut.length; pt < Et; pt++)ut[pt].updateMatrixWorld(!0);
            N.projectionMatrix.copy(q.projectionMatrix), N.projectionMatrixInverse.copy(q.projectionMatrixInverse), N.isPerspectiveCamera && (N.fov = Zi * 2 * Math.atan(1 / N.projectionMatrix.elements[5]), N.zoom = 1);
        }
        this.getCamera = function() {
            return R;
        }, this.getFoveation = function() {
            if (!(d === null && f === null)) return c;
        }, this.setFoveation = function(N) {
            c = N, d !== null && (d.fixedFoveation = N), f !== null && f.fixedFoveation !== void 0 && (f.fixedFoveation = N);
        };
        let Y = null;
        function j(N, q) {
            if (h = q.getViewerPose(l || a), m = q, h !== null) {
                let lt = h.views;
                f !== null && (t.setRenderTargetFramebuffer(p, f.framebuffer), t.setRenderTarget(p));
                let ut = !1;
                lt.length !== R.cameras.length && (R.cameras.length = 0, ut = !0);
                for(let pt = 0; pt < lt.length; pt++){
                    let Et = lt[pt], Tt = null;
                    if (f !== null) Tt = f.getViewport(Et);
                    else {
                        let Yt = u.getViewSubImage(d, Et);
                        Tt = Yt.viewport, pt === 0 && (t.setRenderTargetTextures(p, Yt.colorTexture, d.ignoreDepthValues ? void 0 : Yt.depthStencilTexture), t.setRenderTarget(p));
                    }
                    let wt = w[pt];
                    wt === void 0 && (wt = new xe, wt.layers.enable(pt), wt.viewport = new $t, w[pt] = wt), wt.matrix.fromArray(Et.transform.matrix), wt.matrix.decompose(wt.position, wt.quaternion, wt.scale), wt.projectionMatrix.fromArray(Et.projectionMatrix), wt.projectionMatrixInverse.copy(wt.projectionMatrix).invert(), wt.viewport.set(Tt.x, Tt.y, Tt.width, Tt.height), pt === 0 && (R.matrix.copy(wt.matrix), R.matrix.decompose(R.position, R.quaternion, R.scale)), ut === !0 && R.cameras.push(wt);
                }
            }
            for(let lt = 0; lt < v.length; lt++){
                let ut = _[lt], pt = v[lt];
                ut !== null && pt !== void 0 && pt.update(ut, q, l || a);
            }
            Y && Y(N, q), q.detectedPlanes && n.dispatchEvent({
                type: "planesdetected",
                data: q
            }), m = null;
        }
        let tt = new vd;
        tt.setAnimationLoop(j), this.setAnimationLoop = function(N) {
            Y = N;
        }, this.dispose = function() {};
    }
};
function z0(s1, t) {
    function e(g, p) {
        g.matrixAutoUpdate === !0 && g.updateMatrix(), p.value.copy(g.matrix);
    }
    function n(g, p) {
        p.color.getRGB(g.fogColor.value, xd(s1)), p.isFog ? (g.fogNear.value = p.near, g.fogFar.value = p.far) : p.isFogExp2 && (g.fogDensity.value = p.density);
    }
    function i(g, p, v, _, y) {
        p.isMeshBasicMaterial || p.isMeshLambertMaterial ? r(g, p) : p.isMeshToonMaterial ? (r(g, p), u(g, p)) : p.isMeshPhongMaterial ? (r(g, p), h(g, p)) : p.isMeshStandardMaterial ? (r(g, p), d(g, p), p.isMeshPhysicalMaterial && f(g, p, y)) : p.isMeshMatcapMaterial ? (r(g, p), m(g, p)) : p.isMeshDepthMaterial ? r(g, p) : p.isMeshDistanceMaterial ? (r(g, p), x(g, p)) : p.isMeshNormalMaterial ? r(g, p) : p.isLineBasicMaterial ? (a(g, p), p.isLineDashedMaterial && o(g, p)) : p.isPointsMaterial ? c(g, p, v, _) : p.isSpriteMaterial ? l(g, p) : p.isShadowMaterial ? (g.color.value.copy(p.color), g.opacity.value = p.opacity) : p.isShaderMaterial && (p.uniformsNeedUpdate = !1);
    }
    function r(g, p) {
        g.opacity.value = p.opacity, p.color && g.diffuse.value.copy(p.color), p.emissive && g.emissive.value.copy(p.emissive).multiplyScalar(p.emissiveIntensity), p.map && (g.map.value = p.map, e(p.map, g.mapTransform)), p.alphaMap && (g.alphaMap.value = p.alphaMap, e(p.alphaMap, g.alphaMapTransform)), p.bumpMap && (g.bumpMap.value = p.bumpMap, e(p.bumpMap, g.bumpMapTransform), g.bumpScale.value = p.bumpScale, p.side === De && (g.bumpScale.value *= -1)), p.normalMap && (g.normalMap.value = p.normalMap, e(p.normalMap, g.normalMapTransform), g.normalScale.value.copy(p.normalScale), p.side === De && g.normalScale.value.negate()), p.displacementMap && (g.displacementMap.value = p.displacementMap, e(p.displacementMap, g.displacementMapTransform), g.displacementScale.value = p.displacementScale, g.displacementBias.value = p.displacementBias), p.emissiveMap && (g.emissiveMap.value = p.emissiveMap, e(p.emissiveMap, g.emissiveMapTransform)), p.specularMap && (g.specularMap.value = p.specularMap, e(p.specularMap, g.specularMapTransform)), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
        let v = t.get(p).envMap;
        if (v && (g.envMap.value = v, g.flipEnvMap.value = v.isCubeTexture && v.isRenderTargetTexture === !1 ? -1 : 1, g.reflectivity.value = p.reflectivity, g.ior.value = p.ior, g.refractionRatio.value = p.refractionRatio), p.lightMap) {
            g.lightMap.value = p.lightMap;
            let _ = s1._useLegacyLights === !0 ? Math.PI : 1;
            g.lightMapIntensity.value = p.lightMapIntensity * _, e(p.lightMap, g.lightMapTransform);
        }
        p.aoMap && (g.aoMap.value = p.aoMap, g.aoMapIntensity.value = p.aoMapIntensity, e(p.aoMap, g.aoMapTransform));
    }
    function a(g, p) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, p.map && (g.map.value = p.map, e(p.map, g.mapTransform));
    }
    function o(g, p) {
        g.dashSize.value = p.dashSize, g.totalSize.value = p.dashSize + p.gapSize, g.scale.value = p.scale;
    }
    function c(g, p, v, _) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, g.size.value = p.size * v, g.scale.value = _ * .5, p.map && (g.map.value = p.map, e(p.map, g.uvTransform)), p.alphaMap && (g.alphaMap.value = p.alphaMap, e(p.alphaMap, g.alphaMapTransform)), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
    }
    function l(g, p) {
        g.diffuse.value.copy(p.color), g.opacity.value = p.opacity, g.rotation.value = p.rotation, p.map && (g.map.value = p.map, e(p.map, g.mapTransform)), p.alphaMap && (g.alphaMap.value = p.alphaMap, e(p.alphaMap, g.alphaMapTransform)), p.alphaTest > 0 && (g.alphaTest.value = p.alphaTest);
    }
    function h(g, p) {
        g.specular.value.copy(p.specular), g.shininess.value = Math.max(p.shininess, 1e-4);
    }
    function u(g, p) {
        p.gradientMap && (g.gradientMap.value = p.gradientMap);
    }
    function d(g, p) {
        g.metalness.value = p.metalness, p.metalnessMap && (g.metalnessMap.value = p.metalnessMap, e(p.metalnessMap, g.metalnessMapTransform)), g.roughness.value = p.roughness, p.roughnessMap && (g.roughnessMap.value = p.roughnessMap, e(p.roughnessMap, g.roughnessMapTransform)), t.get(p).envMap && (g.envMapIntensity.value = p.envMapIntensity);
    }
    function f(g, p, v) {
        g.ior.value = p.ior, p.sheen > 0 && (g.sheenColor.value.copy(p.sheenColor).multiplyScalar(p.sheen), g.sheenRoughness.value = p.sheenRoughness, p.sheenColorMap && (g.sheenColorMap.value = p.sheenColorMap, e(p.sheenColorMap, g.sheenColorMapTransform)), p.sheenRoughnessMap && (g.sheenRoughnessMap.value = p.sheenRoughnessMap, e(p.sheenRoughnessMap, g.sheenRoughnessMapTransform))), p.clearcoat > 0 && (g.clearcoat.value = p.clearcoat, g.clearcoatRoughness.value = p.clearcoatRoughness, p.clearcoatMap && (g.clearcoatMap.value = p.clearcoatMap, e(p.clearcoatMap, g.clearcoatMapTransform)), p.clearcoatRoughnessMap && (g.clearcoatRoughnessMap.value = p.clearcoatRoughnessMap, e(p.clearcoatRoughnessMap, g.clearcoatRoughnessMapTransform)), p.clearcoatNormalMap && (g.clearcoatNormalMap.value = p.clearcoatNormalMap, e(p.clearcoatNormalMap, g.clearcoatNormalMapTransform), g.clearcoatNormalScale.value.copy(p.clearcoatNormalScale), p.side === De && g.clearcoatNormalScale.value.negate())), p.iridescence > 0 && (g.iridescence.value = p.iridescence, g.iridescenceIOR.value = p.iridescenceIOR, g.iridescenceThicknessMinimum.value = p.iridescenceThicknessRange[0], g.iridescenceThicknessMaximum.value = p.iridescenceThicknessRange[1], p.iridescenceMap && (g.iridescenceMap.value = p.iridescenceMap, e(p.iridescenceMap, g.iridescenceMapTransform)), p.iridescenceThicknessMap && (g.iridescenceThicknessMap.value = p.iridescenceThicknessMap, e(p.iridescenceThicknessMap, g.iridescenceThicknessMapTransform))), p.transmission > 0 && (g.transmission.value = p.transmission, g.transmissionSamplerMap.value = v.texture, g.transmissionSamplerSize.value.set(v.width, v.height), p.transmissionMap && (g.transmissionMap.value = p.transmissionMap, e(p.transmissionMap, g.transmissionMapTransform)), g.thickness.value = p.thickness, p.thicknessMap && (g.thicknessMap.value = p.thicknessMap, e(p.thicknessMap, g.thicknessMapTransform)), g.attenuationDistance.value = p.attenuationDistance, g.attenuationColor.value.copy(p.attenuationColor)), p.anisotropy > 0 && (g.anisotropyVector.value.set(p.anisotropy * Math.cos(p.anisotropyRotation), p.anisotropy * Math.sin(p.anisotropyRotation)), p.anisotropyMap && (g.anisotropyMap.value = p.anisotropyMap, e(p.anisotropyMap, g.anisotropyMapTransform))), g.specularIntensity.value = p.specularIntensity, g.specularColor.value.copy(p.specularColor), p.specularColorMap && (g.specularColorMap.value = p.specularColorMap, e(p.specularColorMap, g.specularColorMapTransform)), p.specularIntensityMap && (g.specularIntensityMap.value = p.specularIntensityMap, e(p.specularIntensityMap, g.specularIntensityMapTransform));
    }
    function m(g, p) {
        p.matcap && (g.matcap.value = p.matcap);
    }
    function x(g, p) {
        let v = t.get(p).light;
        g.referencePosition.value.setFromMatrixPosition(v.matrixWorld), g.nearDistance.value = v.shadow.camera.near, g.farDistance.value = v.shadow.camera.far;
    }
    return {
        refreshFogUniforms: n,
        refreshMaterialUniforms: i
    };
}
function k0(s1, t, e, n) {
    let i = {}, r = {}, a = [], o = e.isWebGL2 ? s1.getParameter(s1.MAX_UNIFORM_BUFFER_BINDINGS) : 0;
    function c(v, _) {
        let y = _.program;
        n.uniformBlockBinding(v, y);
    }
    function l(v, _) {
        let y = i[v.id];
        y === void 0 && (m(v), y = h(v), i[v.id] = y, v.addEventListener("dispose", g));
        let b = _.program;
        n.updateUBOMapping(v, b);
        let w = t.render.frame;
        r[v.id] !== w && (d(v), r[v.id] = w);
    }
    function h(v) {
        let _ = u();
        v.__bindingPointIndex = _;
        let y = s1.createBuffer(), b = v.__size, w = v.usage;
        return s1.bindBuffer(s1.UNIFORM_BUFFER, y), s1.bufferData(s1.UNIFORM_BUFFER, b, w), s1.bindBuffer(s1.UNIFORM_BUFFER, null), s1.bindBufferBase(s1.UNIFORM_BUFFER, _, y), y;
    }
    function u() {
        for(let v = 0; v < o; v++)if (a.indexOf(v) === -1) return a.push(v), v;
        return console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached."), 0;
    }
    function d(v) {
        let _ = i[v.id], y = v.uniforms, b = v.__cache;
        s1.bindBuffer(s1.UNIFORM_BUFFER, _);
        for(let w = 0, R = y.length; w < R; w++){
            let L = y[w];
            if (f(L, w, b) === !0) {
                let M = L.__offset, E = Array.isArray(L.value) ? L.value : [
                    L.value
                ], V = 0;
                for(let $ = 0; $ < E.length; $++){
                    let F = E[$], O = x(F);
                    typeof F == "number" ? (L.__data[0] = F, s1.bufferSubData(s1.UNIFORM_BUFFER, M + V, L.__data)) : F.isMatrix3 ? (L.__data[0] = F.elements[0], L.__data[1] = F.elements[1], L.__data[2] = F.elements[2], L.__data[3] = F.elements[0], L.__data[4] = F.elements[3], L.__data[5] = F.elements[4], L.__data[6] = F.elements[5], L.__data[7] = F.elements[0], L.__data[8] = F.elements[6], L.__data[9] = F.elements[7], L.__data[10] = F.elements[8], L.__data[11] = F.elements[0]) : (F.toArray(L.__data, V), V += O.storage / Float32Array.BYTES_PER_ELEMENT);
                }
                s1.bufferSubData(s1.UNIFORM_BUFFER, M, L.__data);
            }
        }
        s1.bindBuffer(s1.UNIFORM_BUFFER, null);
    }
    function f(v, _, y) {
        let b = v.value;
        if (y[_] === void 0) {
            if (typeof b == "number") y[_] = b;
            else {
                let w = Array.isArray(b) ? b : [
                    b
                ], R = [];
                for(let L = 0; L < w.length; L++)R.push(w[L].clone());
                y[_] = R;
            }
            return !0;
        } else if (typeof b == "number") {
            if (y[_] !== b) return y[_] = b, !0;
        } else {
            let w = Array.isArray(y[_]) ? y[_] : [
                y[_]
            ], R = Array.isArray(b) ? b : [
                b
            ];
            for(let L = 0; L < w.length; L++){
                let M = w[L];
                if (M.equals(R[L]) === !1) return M.copy(R[L]), !0;
            }
        }
        return !1;
    }
    function m(v) {
        let _ = v.uniforms, y = 0, b = 16, w = 0;
        for(let R = 0, L = _.length; R < L; R++){
            let M = _[R], E = {
                boundary: 0,
                storage: 0
            }, V = Array.isArray(M.value) ? M.value : [
                M.value
            ];
            for(let $ = 0, F = V.length; $ < F; $++){
                let O = V[$], z = x(O);
                E.boundary += z.boundary, E.storage += z.storage;
            }
            if (M.__data = new Float32Array(E.storage / Float32Array.BYTES_PER_ELEMENT), M.__offset = y, R > 0) {
                w = y % b;
                let $ = b - w;
                w !== 0 && $ - E.boundary < 0 && (y += b - w, M.__offset = y);
            }
            y += E.storage;
        }
        return w = y % b, w > 0 && (y += b - w), v.__size = y, v.__cache = {}, this;
    }
    function x(v) {
        let _ = {
            boundary: 0,
            storage: 0
        };
        return typeof v == "number" ? (_.boundary = 4, _.storage = 4) : v.isVector2 ? (_.boundary = 8, _.storage = 8) : v.isVector3 || v.isColor ? (_.boundary = 16, _.storage = 12) : v.isVector4 ? (_.boundary = 16, _.storage = 16) : v.isMatrix3 ? (_.boundary = 48, _.storage = 48) : v.isMatrix4 ? (_.boundary = 64, _.storage = 64) : v.isTexture ? console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.") : console.warn("THREE.WebGLRenderer: Unsupported uniform value type.", v), _;
    }
    function g(v) {
        let _ = v.target;
        _.removeEventListener("dispose", g);
        let y = a.indexOf(_.__bindingPointIndex);
        a.splice(y, 1), s1.deleteBuffer(i[_.id]), delete i[_.id], delete r[_.id];
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
function V0() {
    let s1 = ws("canvas");
    return s1.style.display = "block", s1;
}
var bo = class {
    constructor(t = {}){
        let { canvas: e = V0() , context: n = null , depth: i = !0 , stencil: r = !0 , alpha: a = !1 , antialias: o = !1 , premultipliedAlpha: c = !0 , preserveDrawingBuffer: l = !1 , powerPreference: h = "default" , failIfMajorPerformanceCaveat: u = !1  } = t;
        this.isWebGLRenderer = !0;
        let d;
        n !== null ? d = n.getContextAttributes().alpha : d = a;
        let f = new Uint32Array(4), m = new Int32Array(4), x = null, g = null, p = [], v = [];
        this.domElement = e, this.debug = {
            checkShaderErrors: !0,
            onShaderError: null
        }, this.autoClear = !0, this.autoClearColor = !0, this.autoClearDepth = !0, this.autoClearStencil = !0, this.sortObjects = !0, this.clippingPlanes = [], this.localClippingEnabled = !1, this.outputColorSpace = Nt, this._useLegacyLights = !1, this.toneMapping = Dn, this.toneMappingExposure = 1;
        let _ = this, y = !1, b = 0, w = 0, R = null, L = -1, M = null, E = new $t, V = new $t, $ = null, F = new ft(0), O = 0, z = e.width, K = e.height, X = 1, Y = null, j = null, tt = new $t(0, 0, z, K), N = new $t(0, 0, z, K), q = !1, lt = new Ps, ut = !1, pt = !1, Et = null, Tt = new Ot, wt = new J, Yt = new A, te = {
            background: null,
            fog: null,
            environment: null,
            overrideMaterial: null,
            isScene: !0
        };
        function Pt() {
            return R === null ? X : 1;
        }
        let P = n;
        function at(T, D) {
            for(let W = 0; W < T.length; W++){
                let U = T[W], G = e.getContext(U, D);
                if (G !== null) return G;
            }
            return null;
        }
        try {
            let T = {
                alpha: !0,
                depth: i,
                stencil: r,
                antialias: o,
                premultipliedAlpha: c,
                preserveDrawingBuffer: l,
                powerPreference: h,
                failIfMajorPerformanceCaveat: u
            };
            if ("setAttribute" in e && e.setAttribute("data-engine", `three.js r${Fc}`), e.addEventListener("webglcontextlost", ht, !1), e.addEventListener("webglcontextrestored", H, !1), e.addEventListener("webglcontextcreationerror", ot, !1), P === null) {
                let D = [
                    "webgl2",
                    "webgl",
                    "experimental-webgl"
                ];
                if (_.isWebGL1Renderer === !0 && D.shift(), P = at(D, T), P === null) throw at(D) ? new Error("Error creating WebGL context with your selected attributes.") : new Error("Error creating WebGL context.");
            }
            typeof WebGLRenderingContext < "u" && P instanceof WebGLRenderingContext && console.warn("THREE.WebGLRenderer: WebGL 1 support was deprecated in r153 and will be removed in r163."), P.getShaderPrecisionFormat === void 0 && (P.getShaderPrecisionFormat = function() {
                return {
                    rangeMin: 1,
                    rangeMax: 1,
                    precision: 1
                };
            });
        } catch (T) {
            throw console.error("THREE.WebGLRenderer: " + T.message), T;
        }
        let Z, st, Q, St, mt, xt, Dt, Xt, ie, C, S, B, nt, et, it, Mt, rt, k, Rt, bt, At, vt, yt, Ht;
        function Qt() {
            Z = new o_(P), st = new e_(P, Z, t), Z.init(st), vt = new O0(P, Z, st), Q = new N0(P, Z, st), St = new h_(P), mt = new b0, xt = new F0(P, Z, Q, mt, st, vt, St), Dt = new i_(_), Xt = new a_(_), ie = new yp(P, st), yt = new jg(P, Z, ie, st), C = new c_(P, ie, St, yt), S = new p_(P, C, ie, St), Rt = new f_(P, st, xt), Mt = new n_(mt), B = new S0(_, Dt, Xt, Z, st, yt, Mt), nt = new z0(_, mt), et = new T0, it = new L0(Z, st), k = new Qg(_, Dt, Xt, Q, S, d, c), rt = new D0(_, S, st), Ht = new k0(P, St, st, Q), bt = new t_(P, Z, St, st), At = new l_(P, Z, St, st), St.programs = B.programs, _.capabilities = st, _.extensions = Z, _.properties = mt, _.renderLists = et, _.shadowMap = rt, _.state = Q, _.info = St;
        }
        Qt();
        let I = new So(_, P);
        this.xr = I, this.getContext = function() {
            return P;
        }, this.getContextAttributes = function() {
            return P.getContextAttributes();
        }, this.forceContextLoss = function() {
            let T = Z.get("WEBGL_lose_context");
            T && T.loseContext();
        }, this.forceContextRestore = function() {
            let T = Z.get("WEBGL_lose_context");
            T && T.restoreContext();
        }, this.getPixelRatio = function() {
            return X;
        }, this.setPixelRatio = function(T) {
            T !== void 0 && (X = T, this.setSize(z, K, !1));
        }, this.getSize = function(T) {
            return T.set(z, K);
        }, this.setSize = function(T, D, W = !0) {
            if (I.isPresenting) {
                console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting.");
                return;
            }
            z = T, K = D, e.width = Math.floor(T * X), e.height = Math.floor(D * X), W === !0 && (e.style.width = T + "px", e.style.height = D + "px"), this.setViewport(0, 0, T, D);
        }, this.getDrawingBufferSize = function(T) {
            return T.set(z * X, K * X).floor();
        }, this.setDrawingBufferSize = function(T, D, W) {
            z = T, K = D, X = W, e.width = Math.floor(T * W), e.height = Math.floor(D * W), this.setViewport(0, 0, T, D);
        }, this.getCurrentViewport = function(T) {
            return T.copy(E);
        }, this.getViewport = function(T) {
            return T.copy(tt);
        }, this.setViewport = function(T, D, W, U) {
            T.isVector4 ? tt.set(T.x, T.y, T.z, T.w) : tt.set(T, D, W, U), Q.viewport(E.copy(tt).multiplyScalar(X).floor());
        }, this.getScissor = function(T) {
            return T.copy(N);
        }, this.setScissor = function(T, D, W, U) {
            T.isVector4 ? N.set(T.x, T.y, T.z, T.w) : N.set(T, D, W, U), Q.scissor(V.copy(N).multiplyScalar(X).floor());
        }, this.getScissorTest = function() {
            return q;
        }, this.setScissorTest = function(T) {
            Q.setScissorTest(q = T);
        }, this.setOpaqueSort = function(T) {
            Y = T;
        }, this.setTransparentSort = function(T) {
            j = T;
        }, this.getClearColor = function(T) {
            return T.copy(k.getClearColor());
        }, this.setClearColor = function() {
            k.setClearColor.apply(k, arguments);
        }, this.getClearAlpha = function() {
            return k.getClearAlpha();
        }, this.setClearAlpha = function() {
            k.setClearAlpha.apply(k, arguments);
        }, this.clear = function(T = !0, D = !0, W = !0) {
            let U = 0;
            if (T) {
                let G = !1;
                if (R !== null) {
                    let gt = R.texture.format;
                    G = gt === ud || gt === hd || gt === ld;
                }
                if (G) {
                    let gt = R.texture.type, Ct = gt === Nn || gt === Pn || gt === Bc || gt === ni || gt === od || gt === cd, It = k.getClearColor(), Ut = k.getClearAlpha(), Gt = It.r, Lt = It.g, Bt = It.b;
                    Ct ? (f[0] = Gt, f[1] = Lt, f[2] = Bt, f[3] = Ut, P.clearBufferuiv(P.COLOR, 0, f)) : (m[0] = Gt, m[1] = Lt, m[2] = Bt, m[3] = Ut, P.clearBufferiv(P.COLOR, 0, m));
                } else U |= P.COLOR_BUFFER_BIT;
            }
            D && (U |= P.DEPTH_BUFFER_BIT), W && (U |= P.STENCIL_BUFFER_BIT), P.clear(U);
        }, this.clearColor = function() {
            this.clear(!0, !1, !1);
        }, this.clearDepth = function() {
            this.clear(!1, !0, !1);
        }, this.clearStencil = function() {
            this.clear(!1, !1, !0);
        }, this.dispose = function() {
            e.removeEventListener("webglcontextlost", ht, !1), e.removeEventListener("webglcontextrestored", H, !1), e.removeEventListener("webglcontextcreationerror", ot, !1), et.dispose(), it.dispose(), mt.dispose(), Dt.dispose(), Xt.dispose(), S.dispose(), yt.dispose(), Ht.dispose(), B.dispose(), I.dispose(), I.removeEventListener("sessionstart", jt), I.removeEventListener("sessionend", tn), Et && (Et.dispose(), Et = null), Te.stop();
        };
        function ht(T) {
            T.preventDefault(), console.log("THREE.WebGLRenderer: Context Lost."), y = !0;
        }
        function H() {
            console.log("THREE.WebGLRenderer: Context Restored."), y = !1;
            let T = St.autoReset, D = rt.enabled, W = rt.autoUpdate, U = rt.needsUpdate, G = rt.type;
            Qt(), St.autoReset = T, rt.enabled = D, rt.autoUpdate = W, rt.needsUpdate = U, rt.type = G;
        }
        function ot(T) {
            console.error("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ", T.statusMessage);
        }
        function dt(T) {
            let D = T.target;
            D.removeEventListener("dispose", dt), qt(D);
        }
        function qt(T) {
            ee(T), mt.remove(T);
        }
        function ee(T) {
            let D = mt.get(T).programs;
            D !== void 0 && (D.forEach(function(W) {
                B.releaseProgram(W);
            }), T.isShaderMaterial && B.releaseShaderCache(T));
        }
        this.renderBufferDirect = function(T, D, W, U, G, gt) {
            D === null && (D = te);
            let Ct = G.isMesh && G.matrixWorld.determinant() < 0, It = Ld(T, D, W, U, G);
            Q.setMaterial(U, Ct);
            let Ut = W.index, Gt = 1;
            if (U.wireframe === !0) {
                if (Ut = C.getWireframeAttribute(W), Ut === void 0) return;
                Gt = 2;
            }
            let Lt = W.drawRange, Bt = W.attributes.position, se = Lt.start * Gt, oe = (Lt.start + Lt.count) * Gt;
            gt !== null && (se = Math.max(se, gt.start * Gt), oe = Math.min(oe, (gt.start + gt.count) * Gt)), Ut !== null ? (se = Math.max(se, 0), oe = Math.min(oe, Ut.count)) : Bt != null && (se = Math.max(se, 0), oe = Math.min(oe, Bt.count));
            let ze = oe - se;
            if (ze < 0 || ze === 1 / 0) return;
            yt.setup(G, U, It, W, Ut);
            let an, he = bt;
            if (Ut !== null && (an = ie.get(Ut), he = At, he.setIndex(an)), G.isMesh) U.wireframe === !0 ? (Q.setLineWidth(U.wireframeLinewidth * Pt()), he.setMode(P.LINES)) : he.setMode(P.TRIANGLES);
            else if (G.isLine) {
                let Wt = U.linewidth;
                Wt === void 0 && (Wt = 1), Q.setLineWidth(Wt * Pt()), G.isLineSegments ? he.setMode(P.LINES) : G.isLineLoop ? he.setMode(P.LINE_LOOP) : he.setMode(P.LINE_STRIP);
            } else G.isPoints ? he.setMode(P.POINTS) : G.isSprite && he.setMode(P.TRIANGLES);
            if (G.isInstancedMesh) he.renderInstances(se, ze, G.count);
            else if (W.isInstancedBufferGeometry) {
                let Wt = W._maxInstanceCount !== void 0 ? W._maxInstanceCount : 1 / 0, _a = Math.min(W.instanceCount, Wt);
                he.renderInstances(se, ze, _a);
            } else he.render(se, ze);
        }, this.compile = function(T, D) {
            function W(U, G, gt) {
                U.transparent === !0 && U.side === gn && U.forceSinglePass === !1 ? (U.side = De, U.needsUpdate = !0, Ws(U, G, gt), U.side = On, U.needsUpdate = !0, Ws(U, G, gt), U.side = gn) : Ws(U, G, gt);
            }
            g = it.get(T), g.init(), v.push(g), T.traverseVisible(function(U) {
                U.isLight && U.layers.test(D.layers) && (g.pushLight(U), U.castShadow && g.pushShadow(U));
            }), g.setupLights(_._useLegacyLights), T.traverse(function(U) {
                let G = U.material;
                if (G) if (Array.isArray(G)) for(let gt = 0; gt < G.length; gt++){
                    let Ct = G[gt];
                    W(Ct, T, U);
                }
                else W(G, T, U);
            }), v.pop(), g = null;
        };
        let le = null;
        function En(T) {
            le && le(T);
        }
        function jt() {
            Te.stop();
        }
        function tn() {
            Te.start();
        }
        let Te = new vd;
        Te.setAnimationLoop(En), typeof self < "u" && Te.setContext(self), this.setAnimationLoop = function(T) {
            le = T, I.setAnimationLoop(T), T === null ? Te.stop() : Te.start();
        }, I.addEventListener("sessionstart", jt), I.addEventListener("sessionend", tn), this.render = function(T, D) {
            if (D !== void 0 && D.isCamera !== !0) {
                console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
                return;
            }
            if (y === !0) return;
            T.matrixWorldAutoUpdate === !0 && T.updateMatrixWorld(), D.parent === null && D.matrixWorldAutoUpdate === !0 && D.updateMatrixWorld(), I.enabled === !0 && I.isPresenting === !0 && (I.cameraAutoUpdate === !0 && I.updateCamera(D), D = I.getCamera()), T.isScene === !0 && T.onBeforeRender(_, T, D, R), g = it.get(T, v.length), g.init(), v.push(g), Tt.multiplyMatrices(D.projectionMatrix, D.matrixWorldInverse), lt.setFromProjectionMatrix(Tt), pt = this.localClippingEnabled, ut = Mt.init(this.clippingPlanes, pt), x = et.get(T, p.length), x.init(), p.push(x), Zc(T, D, 0, _.sortObjects), x.finish(), _.sortObjects === !0 && x.sort(Y, j), this.info.render.frame++, ut === !0 && Mt.beginShadows();
            let W = g.state.shadowsArray;
            if (rt.render(W, T, D), ut === !0 && Mt.endShadows(), this.info.autoReset === !0 && this.info.reset(), k.render(x, T), g.setupLights(_._useLegacyLights), D.isArrayCamera) {
                let U = D.cameras;
                for(let G = 0, gt = U.length; G < gt; G++){
                    let Ct = U[G];
                    Jc(x, T, Ct, Ct.viewport);
                }
            } else Jc(x, T, D);
            R !== null && (xt.updateMultisampleRenderTarget(R), xt.updateRenderTargetMipmap(R)), T.isScene === !0 && T.onAfterRender(_, T, D), yt.resetDefaultState(), L = -1, M = null, v.pop(), v.length > 0 ? g = v[v.length - 1] : g = null, p.pop(), p.length > 0 ? x = p[p.length - 1] : x = null;
        };
        function Zc(T, D, W, U) {
            if (T.visible === !1) return;
            if (T.layers.test(D.layers)) {
                if (T.isGroup) W = T.renderOrder;
                else if (T.isLOD) T.autoUpdate === !0 && T.update(D);
                else if (T.isLight) g.pushLight(T), T.castShadow && g.pushShadow(T);
                else if (T.isSprite) {
                    if (!T.frustumCulled || lt.intersectsSprite(T)) {
                        U && Yt.setFromMatrixPosition(T.matrixWorld).applyMatrix4(Tt);
                        let Ct = S.update(T), It = T.material;
                        It.visible && x.push(T, Ct, It, W, Yt.z, null);
                    }
                } else if ((T.isMesh || T.isLine || T.isPoints) && (!T.frustumCulled || lt.intersectsObject(T))) {
                    let Ct = S.update(T), It = T.material;
                    if (U && (T.boundingSphere !== void 0 ? (T.boundingSphere === null && T.computeBoundingSphere(), Yt.copy(T.boundingSphere.center)) : (Ct.boundingSphere === null && Ct.computeBoundingSphere(), Yt.copy(Ct.boundingSphere.center)), Yt.applyMatrix4(T.matrixWorld).applyMatrix4(Tt)), Array.isArray(It)) {
                        let Ut = Ct.groups;
                        for(let Gt = 0, Lt = Ut.length; Gt < Lt; Gt++){
                            let Bt = Ut[Gt], se = It[Bt.materialIndex];
                            se && se.visible && x.push(T, Ct, se, W, Yt.z, Bt);
                        }
                    } else It.visible && x.push(T, Ct, It, W, Yt.z, null);
                }
            }
            let gt = T.children;
            for(let Ct = 0, It = gt.length; Ct < It; Ct++)Zc(gt[Ct], D, W, U);
        }
        function Jc(T, D, W, U) {
            let G = T.opaque, gt = T.transmissive, Ct = T.transparent;
            g.setupLightsView(W), ut === !0 && Mt.setGlobalState(_.clippingPlanes, W), gt.length > 0 && Pd(G, gt, D, W), U && Q.viewport(E.copy(U)), G.length > 0 && Gs(G, D, W), gt.length > 0 && Gs(gt, D, W), Ct.length > 0 && Gs(Ct, D, W), Q.buffers.depth.setTest(!0), Q.buffers.depth.setMask(!0), Q.buffers.color.setMask(!0), Q.setPolygonOffset(!1);
        }
        function Pd(T, D, W, U) {
            let G = st.isWebGL2;
            Et === null && (Et = new Ge(1, 1, {
                generateMipmaps: !0,
                type: Z.has("EXT_color_buffer_half_float") ? Ts : Nn,
                minFilter: li,
                samples: G ? 4 : 0
            })), _.getDrawingBufferSize(wt), G ? Et.setSize(wt.x, wt.y) : Et.setSize(Hr(wt.x), Hr(wt.y));
            let gt = _.getRenderTarget();
            _.setRenderTarget(Et), _.getClearColor(F), O = _.getClearAlpha(), O < 1 && _.setClearColor(16777215, .5), _.clear();
            let Ct = _.toneMapping;
            _.toneMapping = Dn, Gs(T, W, U), xt.updateMultisampleRenderTarget(Et), xt.updateRenderTargetMipmap(Et);
            let It = !1;
            for(let Ut = 0, Gt = D.length; Ut < Gt; Ut++){
                let Lt = D[Ut], Bt = Lt.object, se = Lt.geometry, oe = Lt.material, ze = Lt.group;
                if (oe.side === gn && Bt.layers.test(U.layers)) {
                    let an = oe.side;
                    oe.side = De, oe.needsUpdate = !0, $c(Bt, W, U, se, oe, ze), oe.side = an, oe.needsUpdate = !0, It = !0;
                }
            }
            It === !0 && (xt.updateMultisampleRenderTarget(Et), xt.updateRenderTargetMipmap(Et)), _.setRenderTarget(gt), _.setClearColor(F, O), _.toneMapping = Ct;
        }
        function Gs(T, D, W) {
            let U = D.isScene === !0 ? D.overrideMaterial : null;
            for(let G = 0, gt = T.length; G < gt; G++){
                let Ct = T[G], It = Ct.object, Ut = Ct.geometry, Gt = U === null ? Ct.material : U, Lt = Ct.group;
                It.layers.test(W.layers) && $c(It, D, W, Ut, Gt, Lt);
            }
        }
        function $c(T, D, W, U, G, gt) {
            T.onBeforeRender(_, D, W, U, G, gt), T.modelViewMatrix.multiplyMatrices(W.matrixWorldInverse, T.matrixWorld), T.normalMatrix.getNormalMatrix(T.modelViewMatrix), G.onBeforeRender(_, D, W, U, T, gt), G.transparent === !0 && G.side === gn && G.forceSinglePass === !1 ? (G.side = De, G.needsUpdate = !0, _.renderBufferDirect(W, D, U, G, T, gt), G.side = On, G.needsUpdate = !0, _.renderBufferDirect(W, D, U, G, T, gt), G.side = gn) : _.renderBufferDirect(W, D, U, G, T, gt), T.onAfterRender(_, D, W, U, G, gt);
        }
        function Ws(T, D, W) {
            D.isScene !== !0 && (D = te);
            let U = mt.get(T), G = g.state.lights, gt = g.state.shadowsArray, Ct = G.state.version, It = B.getParameters(T, G.state, gt, D, W), Ut = B.getProgramCacheKey(It), Gt = U.programs;
            U.environment = T.isMeshStandardMaterial ? D.environment : null, U.fog = D.fog, U.envMap = (T.isMeshStandardMaterial ? Xt : Dt).get(T.envMap || U.environment), Gt === void 0 && (T.addEventListener("dispose", dt), Gt = new Map, U.programs = Gt);
            let Lt = Gt.get(Ut);
            if (Lt !== void 0) {
                if (U.currentProgram === Lt && U.lightsStateVersion === Ct) return Kc(T, It), Lt;
            } else It.uniforms = B.getUniforms(T), T.onBuild(W, It, _), T.onBeforeCompile(It, _), Lt = B.acquireProgram(It, Ut), Gt.set(Ut, Lt), U.uniforms = It.uniforms;
            let Bt = U.uniforms;
            (!T.isShaderMaterial && !T.isRawShaderMaterial || T.clipping === !0) && (Bt.clippingPlanes = Mt.uniform), Kc(T, It), U.needsLights = Ud(T), U.lightsStateVersion = Ct, U.needsLights && (Bt.ambientLightColor.value = G.state.ambient, Bt.lightProbe.value = G.state.probe, Bt.directionalLights.value = G.state.directional, Bt.directionalLightShadows.value = G.state.directionalShadow, Bt.spotLights.value = G.state.spot, Bt.spotLightShadows.value = G.state.spotShadow, Bt.rectAreaLights.value = G.state.rectArea, Bt.ltc_1.value = G.state.rectAreaLTC1, Bt.ltc_2.value = G.state.rectAreaLTC2, Bt.pointLights.value = G.state.point, Bt.pointLightShadows.value = G.state.pointShadow, Bt.hemisphereLights.value = G.state.hemi, Bt.directionalShadowMap.value = G.state.directionalShadowMap, Bt.directionalShadowMatrix.value = G.state.directionalShadowMatrix, Bt.spotShadowMap.value = G.state.spotShadowMap, Bt.spotLightMatrix.value = G.state.spotLightMatrix, Bt.spotLightMap.value = G.state.spotLightMap, Bt.pointShadowMap.value = G.state.pointShadowMap, Bt.pointShadowMatrix.value = G.state.pointShadowMatrix);
            let se = Lt.getUniforms(), oe = qi.seqWithValue(se.seq, Bt);
            return U.currentProgram = Lt, U.uniformsList = oe, Lt;
        }
        function Kc(T, D) {
            let W = mt.get(T);
            W.outputColorSpace = D.outputColorSpace, W.instancing = D.instancing, W.instancingColor = D.instancingColor, W.skinning = D.skinning, W.morphTargets = D.morphTargets, W.morphNormals = D.morphNormals, W.morphColors = D.morphColors, W.morphTargetsCount = D.morphTargetsCount, W.numClippingPlanes = D.numClippingPlanes, W.numIntersection = D.numClipIntersection, W.vertexAlphas = D.vertexAlphas, W.vertexTangents = D.vertexTangents, W.toneMapping = D.toneMapping;
        }
        function Ld(T, D, W, U, G) {
            D.isScene !== !0 && (D = te), xt.resetTextureUnits();
            let gt = D.fog, Ct = U.isMeshStandardMaterial ? D.environment : null, It = R === null ? _.outputColorSpace : R.isXRRenderTarget === !0 ? R.texture.colorSpace : nn, Ut = (U.isMeshStandardMaterial ? Xt : Dt).get(U.envMap || Ct), Gt = U.vertexColors === !0 && !!W.attributes.color && W.attributes.color.itemSize === 4, Lt = !!W.attributes.tangent && (!!U.normalMap || U.anisotropy > 0), Bt = !!W.morphAttributes.position, se = !!W.morphAttributes.normal, oe = !!W.morphAttributes.color, ze = Dn;
            U.toneMapped && (R === null || R.isXRRenderTarget === !0) && (ze = _.toneMapping);
            let an = W.morphAttributes.position || W.morphAttributes.normal || W.morphAttributes.color, he = an !== void 0 ? an.length : 0, Wt = mt.get(U), _a = g.state.lights;
            if (ut === !0 && (pt === !0 || T !== M)) {
                let Ne = T === M && U.id === L;
                Mt.setState(U, T, Ne);
            }
            let ue = !1;
            U.version === Wt.__version ? (Wt.needsLights && Wt.lightsStateVersion !== _a.state.version || Wt.outputColorSpace !== It || G.isInstancedMesh && Wt.instancing === !1 || !G.isInstancedMesh && Wt.instancing === !0 || G.isSkinnedMesh && Wt.skinning === !1 || !G.isSkinnedMesh && Wt.skinning === !0 || G.isInstancedMesh && Wt.instancingColor === !0 && G.instanceColor === null || G.isInstancedMesh && Wt.instancingColor === !1 && G.instanceColor !== null || Wt.envMap !== Ut || U.fog === !0 && Wt.fog !== gt || Wt.numClippingPlanes !== void 0 && (Wt.numClippingPlanes !== Mt.numPlanes || Wt.numIntersection !== Mt.numIntersection) || Wt.vertexAlphas !== Gt || Wt.vertexTangents !== Lt || Wt.morphTargets !== Bt || Wt.morphNormals !== se || Wt.morphColors !== oe || Wt.toneMapping !== ze || st.isWebGL2 === !0 && Wt.morphTargetsCount !== he) && (ue = !0) : (ue = !0, Wt.__version = U.version);
            let Vn = Wt.currentProgram;
            ue === !0 && (Vn = Ws(U, D, G));
            let Qc = !1, os = !1, xa = !1, we = Vn.getUniforms(), Hn = Wt.uniforms;
            if (Q.useProgram(Vn.program) && (Qc = !0, os = !0, xa = !0), U.id !== L && (L = U.id, os = !0), Qc || M !== T) {
                if (we.setValue(P, "projectionMatrix", T.projectionMatrix), st.logarithmicDepthBuffer && we.setValue(P, "logDepthBufFC", 2 / (Math.log(T.far + 1) / Math.LN2)), M !== T && (M = T, os = !0, xa = !0), U.isShaderMaterial || U.isMeshPhongMaterial || U.isMeshToonMaterial || U.isMeshStandardMaterial || U.envMap) {
                    let Ne = we.map.cameraPosition;
                    Ne !== void 0 && Ne.setValue(P, Yt.setFromMatrixPosition(T.matrixWorld));
                }
                (U.isMeshPhongMaterial || U.isMeshToonMaterial || U.isMeshLambertMaterial || U.isMeshBasicMaterial || U.isMeshStandardMaterial || U.isShaderMaterial) && we.setValue(P, "isOrthographic", T.isOrthographicCamera === !0), (U.isMeshPhongMaterial || U.isMeshToonMaterial || U.isMeshLambertMaterial || U.isMeshBasicMaterial || U.isMeshStandardMaterial || U.isShaderMaterial || U.isShadowMaterial || G.isSkinnedMesh) && we.setValue(P, "viewMatrix", T.matrixWorldInverse);
            }
            if (G.isSkinnedMesh) {
                we.setOptional(P, G, "bindMatrix"), we.setOptional(P, G, "bindMatrixInverse");
                let Ne = G.skeleton;
                Ne && (st.floatVertexTextures ? (Ne.boneTexture === null && Ne.computeBoneTexture(), we.setValue(P, "boneTexture", Ne.boneTexture, xt), we.setValue(P, "boneTextureSize", Ne.boneTextureSize)) : console.warn("THREE.WebGLRenderer: SkinnedMesh can only be used with WebGL 2. With WebGL 1 OES_texture_float and vertex textures support is required."));
            }
            let va = W.morphAttributes;
            if ((va.position !== void 0 || va.normal !== void 0 || va.color !== void 0 && st.isWebGL2 === !0) && Rt.update(G, W, Vn), (os || Wt.receiveShadow !== G.receiveShadow) && (Wt.receiveShadow = G.receiveShadow, we.setValue(P, "receiveShadow", G.receiveShadow)), U.isMeshGouraudMaterial && U.envMap !== null && (Hn.envMap.value = Ut, Hn.flipEnvMap.value = Ut.isCubeTexture && Ut.isRenderTargetTexture === !1 ? -1 : 1), os && (we.setValue(P, "toneMappingExposure", _.toneMappingExposure), Wt.needsLights && Id(Hn, xa), gt && U.fog === !0 && nt.refreshFogUniforms(Hn, gt), nt.refreshMaterialUniforms(Hn, U, X, K, Et), qi.upload(P, Wt.uniformsList, Hn, xt)), U.isShaderMaterial && U.uniformsNeedUpdate === !0 && (qi.upload(P, Wt.uniformsList, Hn, xt), U.uniformsNeedUpdate = !1), U.isSpriteMaterial && we.setValue(P, "center", G.center), we.setValue(P, "modelViewMatrix", G.modelViewMatrix), we.setValue(P, "normalMatrix", G.normalMatrix), we.setValue(P, "modelMatrix", G.matrixWorld), U.isShaderMaterial || U.isRawShaderMaterial) {
                let Ne = U.uniformsGroups;
                for(let ya = 0, Dd = Ne.length; ya < Dd; ya++)if (st.isWebGL2) {
                    let jc = Ne[ya];
                    Ht.update(jc, Vn), Ht.bind(jc, Vn);
                } else console.warn("THREE.WebGLRenderer: Uniform Buffer Objects can only be used with WebGL 2.");
            }
            return Vn;
        }
        function Id(T, D) {
            T.ambientLightColor.needsUpdate = D, T.lightProbe.needsUpdate = D, T.directionalLights.needsUpdate = D, T.directionalLightShadows.needsUpdate = D, T.pointLights.needsUpdate = D, T.pointLightShadows.needsUpdate = D, T.spotLights.needsUpdate = D, T.spotLightShadows.needsUpdate = D, T.rectAreaLights.needsUpdate = D, T.hemisphereLights.needsUpdate = D;
        }
        function Ud(T) {
            return T.isMeshLambertMaterial || T.isMeshToonMaterial || T.isMeshPhongMaterial || T.isMeshStandardMaterial || T.isShadowMaterial || T.isShaderMaterial && T.lights === !0;
        }
        this.getActiveCubeFace = function() {
            return b;
        }, this.getActiveMipmapLevel = function() {
            return w;
        }, this.getRenderTarget = function() {
            return R;
        }, this.setRenderTargetTextures = function(T, D, W) {
            mt.get(T.texture).__webglTexture = D, mt.get(T.depthTexture).__webglTexture = W;
            let U = mt.get(T);
            U.__hasExternalTextures = !0, U.__hasExternalTextures && (U.__autoAllocateDepthBuffer = W === void 0, U.__autoAllocateDepthBuffer || Z.has("WEBGL_multisampled_render_to_texture") === !0 && (console.warn("THREE.WebGLRenderer: Render-to-texture extension was disabled because an external texture was provided"), U.__useRenderToTexture = !1));
        }, this.setRenderTargetFramebuffer = function(T, D) {
            let W = mt.get(T);
            W.__webglFramebuffer = D, W.__useDefaultFramebuffer = D === void 0;
        }, this.setRenderTarget = function(T, D = 0, W = 0) {
            R = T, b = D, w = W;
            let U = !0, G = null, gt = !1, Ct = !1;
            if (T) {
                let Ut = mt.get(T);
                Ut.__useDefaultFramebuffer !== void 0 ? (Q.bindFramebuffer(P.FRAMEBUFFER, null), U = !1) : Ut.__webglFramebuffer === void 0 ? xt.setupRenderTarget(T) : Ut.__hasExternalTextures && xt.rebindTextures(T, mt.get(T.texture).__webglTexture, mt.get(T.depthTexture).__webglTexture);
                let Gt = T.texture;
                (Gt.isData3DTexture || Gt.isDataArrayTexture || Gt.isCompressedArrayTexture) && (Ct = !0);
                let Lt = mt.get(T).__webglFramebuffer;
                T.isWebGLCubeRenderTarget ? (Array.isArray(Lt[D]) ? G = Lt[D][W] : G = Lt[D], gt = !0) : st.isWebGL2 && T.samples > 0 && xt.useMultisampledRTT(T) === !1 ? G = mt.get(T).__webglMultisampledFramebuffer : Array.isArray(Lt) ? G = Lt[W] : G = Lt, E.copy(T.viewport), V.copy(T.scissor), $ = T.scissorTest;
            } else E.copy(tt).multiplyScalar(X).floor(), V.copy(N).multiplyScalar(X).floor(), $ = q;
            if (Q.bindFramebuffer(P.FRAMEBUFFER, G) && st.drawBuffers && U && Q.drawBuffers(T, G), Q.viewport(E), Q.scissor(V), Q.setScissorTest($), gt) {
                let Ut = mt.get(T.texture);
                P.framebufferTexture2D(P.FRAMEBUFFER, P.COLOR_ATTACHMENT0, P.TEXTURE_CUBE_MAP_POSITIVE_X + D, Ut.__webglTexture, W);
            } else if (Ct) {
                let Ut = mt.get(T.texture), Gt = D || 0;
                P.framebufferTextureLayer(P.FRAMEBUFFER, P.COLOR_ATTACHMENT0, Ut.__webglTexture, W || 0, Gt);
            }
            L = -1;
        }, this.readRenderTargetPixels = function(T, D, W, U, G, gt, Ct) {
            if (!(T && T.isWebGLRenderTarget)) {
                console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");
                return;
            }
            let It = mt.get(T).__webglFramebuffer;
            if (T.isWebGLCubeRenderTarget && Ct !== void 0 && (It = It[Ct]), It) {
                Q.bindFramebuffer(P.FRAMEBUFFER, It);
                try {
                    let Ut = T.texture, Gt = Ut.format, Lt = Ut.type;
                    if (Gt !== He && vt.convert(Gt) !== P.getParameter(P.IMPLEMENTATION_COLOR_READ_FORMAT)) {
                        console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");
                        return;
                    }
                    let Bt = Lt === Ts && (Z.has("EXT_color_buffer_half_float") || st.isWebGL2 && Z.has("EXT_color_buffer_float"));
                    if (Lt !== Nn && vt.convert(Lt) !== P.getParameter(P.IMPLEMENTATION_COLOR_READ_TYPE) && !(Lt === xn && (st.isWebGL2 || Z.has("OES_texture_float") || Z.has("WEBGL_color_buffer_float"))) && !Bt) {
                        console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");
                        return;
                    }
                    D >= 0 && D <= T.width - U && W >= 0 && W <= T.height - G && P.readPixels(D, W, U, G, vt.convert(Gt), vt.convert(Lt), gt);
                } finally{
                    let Ut = R !== null ? mt.get(R).__webglFramebuffer : null;
                    Q.bindFramebuffer(P.FRAMEBUFFER, Ut);
                }
            }
        }, this.copyFramebufferToTexture = function(T, D, W = 0) {
            let U = Math.pow(2, -W), G = Math.floor(D.image.width * U), gt = Math.floor(D.image.height * U);
            xt.setTexture2D(D, 0), P.copyTexSubImage2D(P.TEXTURE_2D, W, 0, 0, T.x, T.y, G, gt), Q.unbindTexture();
        }, this.copyTextureToTexture = function(T, D, W, U = 0) {
            let G = D.image.width, gt = D.image.height, Ct = vt.convert(W.format), It = vt.convert(W.type);
            xt.setTexture2D(W, 0), P.pixelStorei(P.UNPACK_FLIP_Y_WEBGL, W.flipY), P.pixelStorei(P.UNPACK_PREMULTIPLY_ALPHA_WEBGL, W.premultiplyAlpha), P.pixelStorei(P.UNPACK_ALIGNMENT, W.unpackAlignment), D.isDataTexture ? P.texSubImage2D(P.TEXTURE_2D, U, T.x, T.y, G, gt, Ct, It, D.image.data) : D.isCompressedTexture ? P.compressedTexSubImage2D(P.TEXTURE_2D, U, T.x, T.y, D.mipmaps[0].width, D.mipmaps[0].height, Ct, D.mipmaps[0].data) : P.texSubImage2D(P.TEXTURE_2D, U, T.x, T.y, Ct, It, D.image), U === 0 && W.generateMipmaps && P.generateMipmap(P.TEXTURE_2D), Q.unbindTexture();
        }, this.copyTextureToTexture3D = function(T, D, W, U, G = 0) {
            if (_.isWebGL1Renderer) {
                console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: can only be used with WebGL2.");
                return;
            }
            let gt = T.max.x - T.min.x + 1, Ct = T.max.y - T.min.y + 1, It = T.max.z - T.min.z + 1, Ut = vt.convert(U.format), Gt = vt.convert(U.type), Lt;
            if (U.isData3DTexture) xt.setTexture3D(U, 0), Lt = P.TEXTURE_3D;
            else if (U.isDataArrayTexture) xt.setTexture2DArray(U, 0), Lt = P.TEXTURE_2D_ARRAY;
            else {
                console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: only supports THREE.DataTexture3D and THREE.DataTexture2DArray.");
                return;
            }
            P.pixelStorei(P.UNPACK_FLIP_Y_WEBGL, U.flipY), P.pixelStorei(P.UNPACK_PREMULTIPLY_ALPHA_WEBGL, U.premultiplyAlpha), P.pixelStorei(P.UNPACK_ALIGNMENT, U.unpackAlignment);
            let Bt = P.getParameter(P.UNPACK_ROW_LENGTH), se = P.getParameter(P.UNPACK_IMAGE_HEIGHT), oe = P.getParameter(P.UNPACK_SKIP_PIXELS), ze = P.getParameter(P.UNPACK_SKIP_ROWS), an = P.getParameter(P.UNPACK_SKIP_IMAGES), he = W.isCompressedTexture ? W.mipmaps[0] : W.image;
            P.pixelStorei(P.UNPACK_ROW_LENGTH, he.width), P.pixelStorei(P.UNPACK_IMAGE_HEIGHT, he.height), P.pixelStorei(P.UNPACK_SKIP_PIXELS, T.min.x), P.pixelStorei(P.UNPACK_SKIP_ROWS, T.min.y), P.pixelStorei(P.UNPACK_SKIP_IMAGES, T.min.z), W.isDataTexture || W.isData3DTexture ? P.texSubImage3D(Lt, G, D.x, D.y, D.z, gt, Ct, It, Ut, Gt, he.data) : W.isCompressedArrayTexture ? (console.warn("THREE.WebGLRenderer.copyTextureToTexture3D: untested support for compressed srcTexture."), P.compressedTexSubImage3D(Lt, G, D.x, D.y, D.z, gt, Ct, It, Ut, he.data)) : P.texSubImage3D(Lt, G, D.x, D.y, D.z, gt, Ct, It, Ut, Gt, he), P.pixelStorei(P.UNPACK_ROW_LENGTH, Bt), P.pixelStorei(P.UNPACK_IMAGE_HEIGHT, se), P.pixelStorei(P.UNPACK_SKIP_PIXELS, oe), P.pixelStorei(P.UNPACK_SKIP_ROWS, ze), P.pixelStorei(P.UNPACK_SKIP_IMAGES, an), G === 0 && U.generateMipmaps && P.generateMipmap(Lt), Q.unbindTexture();
        }, this.initTexture = function(T) {
            T.isCubeTexture ? xt.setTextureCube(T, 0) : T.isData3DTexture ? xt.setTexture3D(T, 0) : T.isDataArrayTexture || T.isCompressedArrayTexture ? xt.setTexture2DArray(T, 0) : xt.setTexture2D(T, 0), Q.unbindTexture();
        }, this.resetState = function() {
            b = 0, w = 0, R = null, Q.reset(), yt.reset();
        }, typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe", {
            detail: this
        }));
    }
    get coordinateSystem() {
        return vn;
    }
    get physicallyCorrectLights() {
        return console.warn("THREE.WebGLRenderer: The property .physicallyCorrectLights has been removed. Set renderer.useLegacyLights instead."), !this.useLegacyLights;
    }
    set physicallyCorrectLights(t) {
        console.warn("THREE.WebGLRenderer: The property .physicallyCorrectLights has been removed. Set renderer.useLegacyLights instead."), this.useLegacyLights = !t;
    }
    get outputEncoding() {
        return console.warn("THREE.WebGLRenderer: Property .outputEncoding has been removed. Use .outputColorSpace instead."), this.outputColorSpace === Nt ? si : fd;
    }
    set outputEncoding(t) {
        console.warn("THREE.WebGLRenderer: Property .outputEncoding has been removed. Use .outputColorSpace instead."), this.outputColorSpace = t === si ? Nt : nn;
    }
    get useLegacyLights() {
        return console.warn("THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733."), this._useLegacyLights;
    }
    set useLegacyLights(t) {
        console.warn("THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733."), this._useLegacyLights = t;
    }
}, Eo = class extends bo {
};
Eo.prototype.isWebGL1Renderer = !0;
var To = class s1 {
    constructor(t, e = 25e-5){
        this.isFogExp2 = !0, this.name = "", this.color = new ft(t), this.density = e;
    }
    clone() {
        return new s1(this.color, this.density);
    }
    toJSON() {
        return {
            type: "FogExp2",
            color: this.color.getHex(),
            density: this.density
        };
    }
}, wo = class s1 {
    constructor(t, e = 1, n = 1e3){
        this.isFog = !0, this.name = "", this.color = new ft(t), this.near = e, this.far = n;
    }
    clone() {
        return new s1(this.color, this.near, this.far);
    }
    toJSON() {
        return {
            type: "Fog",
            color: this.color.getHex(),
            near: this.near,
            far: this.far
        };
    }
}, Ao = class extends Zt {
    constructor(){
        super(), this.isScene = !0, this.type = "Scene", this.background = null, this.environment = null, this.fog = null, this.backgroundBlurriness = 0, this.backgroundIntensity = 1, this.overrideMaterial = null, typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe", {
            detail: this
        }));
    }
    copy(t, e) {
        return super.copy(t, e), t.background !== null && (this.background = t.background.clone()), t.environment !== null && (this.environment = t.environment.clone()), t.fog !== null && (this.fog = t.fog.clone()), this.backgroundBlurriness = t.backgroundBlurriness, this.backgroundIntensity = t.backgroundIntensity, t.overrideMaterial !== null && (this.overrideMaterial = t.overrideMaterial.clone()), this.matrixAutoUpdate = t.matrixAutoUpdate, this;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return this.fog !== null && (e.object.fog = this.fog.toJSON()), this.backgroundBlurriness > 0 && (e.object.backgroundBlurriness = this.backgroundBlurriness), this.backgroundIntensity !== 1 && (e.object.backgroundIntensity = this.backgroundIntensity), e;
    }
}, Is = class {
    constructor(t, e){
        this.isInterleavedBuffer = !0, this.array = t, this.stride = e, this.count = t !== void 0 ? t.length / e : 0, this.usage = kr, this.updateRange = {
            offset: 0,
            count: -1
        }, this.version = 0, this.uuid = Be();
    }
    onUploadCallback() {}
    set needsUpdate(t) {
        t === !0 && this.version++;
    }
    setUsage(t) {
        return this.usage = t, this;
    }
    copy(t) {
        return this.array = new t.array.constructor(t.array), this.count = t.count, this.stride = t.stride, this.usage = t.usage, this;
    }
    copyAt(t, e, n) {
        t *= this.stride, n *= e.stride;
        for(let i = 0, r = this.stride; i < r; i++)this.array[t + i] = e.array[n + i];
        return this;
    }
    set(t, e = 0) {
        return this.array.set(t, e), this;
    }
    clone(t) {
        t.arrayBuffers === void 0 && (t.arrayBuffers = {}), this.array.buffer._uuid === void 0 && (this.array.buffer._uuid = Be()), t.arrayBuffers[this.array.buffer._uuid] === void 0 && (t.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0).buffer);
        let e = new this.array.constructor(t.arrayBuffers[this.array.buffer._uuid]), n = new this.constructor(e, this.stride);
        return n.setUsage(this.usage), n;
    }
    onUpload(t) {
        return this.onUploadCallback = t, this;
    }
    toJSON(t) {
        return t.arrayBuffers === void 0 && (t.arrayBuffers = {}), this.array.buffer._uuid === void 0 && (this.array.buffer._uuid = Be()), t.arrayBuffers[this.array.buffer._uuid] === void 0 && (t.arrayBuffers[this.array.buffer._uuid] = Array.from(new Uint32Array(this.array.buffer))), {
            uuid: this.uuid,
            buffer: this.array.buffer._uuid,
            type: this.array.constructor.name,
            stride: this.stride
        };
    }
}, Ae = new A, Qi = class s1 {
    constructor(t, e, n, i = !1){
        this.isInterleavedBufferAttribute = !0, this.name = "", this.data = t, this.itemSize = e, this.offset = n, this.normalized = i;
    }
    get count() {
        return this.data.count;
    }
    get array() {
        return this.data.array;
    }
    set needsUpdate(t) {
        this.data.needsUpdate = t;
    }
    applyMatrix4(t) {
        for(let e = 0, n = this.data.count; e < n; e++)Ae.fromBufferAttribute(this, e), Ae.applyMatrix4(t), this.setXYZ(e, Ae.x, Ae.y, Ae.z);
        return this;
    }
    applyNormalMatrix(t) {
        for(let e = 0, n = this.count; e < n; e++)Ae.fromBufferAttribute(this, e), Ae.applyNormalMatrix(t), this.setXYZ(e, Ae.x, Ae.y, Ae.z);
        return this;
    }
    transformDirection(t) {
        for(let e = 0, n = this.count; e < n; e++)Ae.fromBufferAttribute(this, e), Ae.transformDirection(t), this.setXYZ(e, Ae.x, Ae.y, Ae.z);
        return this;
    }
    setX(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.data.array[t * this.data.stride + this.offset] = e, this;
    }
    setY(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.data.array[t * this.data.stride + this.offset + 1] = e, this;
    }
    setZ(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.data.array[t * this.data.stride + this.offset + 2] = e, this;
    }
    setW(t, e) {
        return this.normalized && (e = Ft(e, this.array)), this.data.array[t * this.data.stride + this.offset + 3] = e, this;
    }
    getX(t) {
        let e = this.data.array[t * this.data.stride + this.offset];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    getY(t) {
        let e = this.data.array[t * this.data.stride + this.offset + 1];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    getZ(t) {
        let e = this.data.array[t * this.data.stride + this.offset + 2];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    getW(t) {
        let e = this.data.array[t * this.data.stride + this.offset + 3];
        return this.normalized && (e = Ue(e, this.array)), e;
    }
    setXY(t, e, n) {
        return t = t * this.data.stride + this.offset, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array)), this.data.array[t + 0] = e, this.data.array[t + 1] = n, this;
    }
    setXYZ(t, e, n, i) {
        return t = t * this.data.stride + this.offset, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array), i = Ft(i, this.array)), this.data.array[t + 0] = e, this.data.array[t + 1] = n, this.data.array[t + 2] = i, this;
    }
    setXYZW(t, e, n, i, r) {
        return t = t * this.data.stride + this.offset, this.normalized && (e = Ft(e, this.array), n = Ft(n, this.array), i = Ft(i, this.array), r = Ft(r, this.array)), this.data.array[t + 0] = e, this.data.array[t + 1] = n, this.data.array[t + 2] = i, this.data.array[t + 3] = r, this;
    }
    clone(t) {
        if (t === void 0) {
            console.log("THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");
            let e = [];
            for(let n = 0; n < this.count; n++){
                let i = n * this.data.stride + this.offset;
                for(let r = 0; r < this.itemSize; r++)e.push(this.data.array[i + r]);
            }
            return new Kt(new this.array.constructor(e), this.itemSize, this.normalized);
        } else return t.interleavedBuffers === void 0 && (t.interleavedBuffers = {}), t.interleavedBuffers[this.data.uuid] === void 0 && (t.interleavedBuffers[this.data.uuid] = this.data.clone(t)), new s1(t.interleavedBuffers[this.data.uuid], this.itemSize, this.offset, this.normalized);
    }
    toJSON(t) {
        if (t === void 0) {
            console.log("THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");
            let e = [];
            for(let n = 0; n < this.count; n++){
                let i = n * this.data.stride + this.offset;
                for(let r = 0; r < this.itemSize; r++)e.push(this.data.array[i + r]);
            }
            return {
                itemSize: this.itemSize,
                type: this.array.constructor.name,
                array: e,
                normalized: this.normalized
            };
        } else return t.interleavedBuffers === void 0 && (t.interleavedBuffers = {}), t.interleavedBuffers[this.data.uuid] === void 0 && (t.interleavedBuffers[this.data.uuid] = this.data.toJSON(t)), {
            isInterleavedBufferAttribute: !0,
            itemSize: this.itemSize,
            data: this.data.uuid,
            offset: this.offset,
            normalized: this.normalized
        };
    }
}, Qr = class extends Me {
    constructor(t){
        super(), this.isSpriteMaterial = !0, this.type = "SpriteMaterial", this.color = new ft(16777215), this.map = null, this.alphaMap = null, this.rotation = 0, this.sizeAttenuation = !0, this.transparent = !0, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.map = t.map, this.alphaMap = t.alphaMap, this.rotation = t.rotation, this.sizeAttenuation = t.sizeAttenuation, this.fog = t.fog, this;
    }
}, Ii, ds = new A, Ui = new A, Di = new A, Ni = new J, fs = new J, Ed = new Ot, ur = new A, ps = new A, dr = new A, bh = new J, Za = new J, Eh = new J, Ro = class extends Zt {
    constructor(t){
        if (super(), this.isSprite = !0, this.type = "Sprite", Ii === void 0) {
            Ii = new Vt;
            let e = new Float32Array([
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
            ]), n = new Is(e, 5);
            Ii.setIndex([
                0,
                1,
                2,
                0,
                2,
                3
            ]), Ii.setAttribute("position", new Qi(n, 3, 0, !1)), Ii.setAttribute("uv", new Qi(n, 2, 3, !1));
        }
        this.geometry = Ii, this.material = t !== void 0 ? t : new Qr, this.center = new J(.5, .5);
    }
    raycast(t, e) {
        t.camera === null && console.error('THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.'), Ui.setFromMatrixScale(this.matrixWorld), Ed.copy(t.camera.matrixWorld), this.modelViewMatrix.multiplyMatrices(t.camera.matrixWorldInverse, this.matrixWorld), Di.setFromMatrixPosition(this.modelViewMatrix), t.camera.isPerspectiveCamera && this.material.sizeAttenuation === !1 && Ui.multiplyScalar(-Di.z);
        let n = this.material.rotation, i, r;
        n !== 0 && (r = Math.cos(n), i = Math.sin(n));
        let a = this.center;
        fr(ur.set(-.5, -.5, 0), Di, a, Ui, i, r), fr(ps.set(.5, -.5, 0), Di, a, Ui, i, r), fr(dr.set(.5, .5, 0), Di, a, Ui, i, r), bh.set(0, 0), Za.set(1, 0), Eh.set(1, 1);
        let o = t.ray.intersectTriangle(ur, ps, dr, !1, ds);
        if (o === null && (fr(ps.set(-.5, .5, 0), Di, a, Ui, i, r), Za.set(0, 1), o = t.ray.intersectTriangle(ur, dr, ps, !1, ds), o === null)) return;
        let c = t.ray.origin.distanceTo(ds);
        c < t.near || c > t.far || e.push({
            distance: c,
            point: ds.clone(),
            uv: In.getInterpolation(ds, ur, ps, dr, bh, Za, Eh, new J),
            face: null,
            object: this
        });
    }
    copy(t, e) {
        return super.copy(t, e), t.center !== void 0 && this.center.copy(t.center), this.material = t.material, this;
    }
};
function fr(s1, t, e, n, i, r) {
    Ni.subVectors(s1, e).addScalar(.5).multiply(n), i !== void 0 ? (fs.x = r * Ni.x - i * Ni.y, fs.y = i * Ni.x + r * Ni.y) : fs.copy(Ni), s1.copy(t), s1.x += fs.x, s1.y += fs.y, s1.applyMatrix4(Ed);
}
var pr = new A, Th = new A, Co = class extends Zt {
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
    copy(t) {
        super.copy(t, !1);
        let e = t.levels;
        for(let n = 0, i = e.length; n < i; n++){
            let r = e[n];
            this.addLevel(r.object.clone(), r.distance, r.hysteresis);
        }
        return this.autoUpdate = t.autoUpdate, this;
    }
    addLevel(t, e = 0, n = 0) {
        e = Math.abs(e);
        let i = this.levels, r;
        for(r = 0; r < i.length && !(e < i[r].distance); r++);
        return i.splice(r, 0, {
            distance: e,
            hysteresis: n,
            object: t
        }), this.add(t), this;
    }
    getCurrentLevel() {
        return this._currentLevel;
    }
    getObjectForDistance(t) {
        let e = this.levels;
        if (e.length > 0) {
            let n, i;
            for(n = 1, i = e.length; n < i; n++){
                let r = e[n].distance;
                if (e[n].object.visible && (r -= r * e[n].hysteresis), t < r) break;
            }
            return e[n - 1].object;
        }
        return null;
    }
    raycast(t, e) {
        if (this.levels.length > 0) {
            pr.setFromMatrixPosition(this.matrixWorld);
            let i = t.ray.origin.distanceTo(pr);
            this.getObjectForDistance(i).raycast(t, e);
        }
    }
    update(t) {
        let e = this.levels;
        if (e.length > 1) {
            pr.setFromMatrixPosition(t.matrixWorld), Th.setFromMatrixPosition(this.matrixWorld);
            let n = pr.distanceTo(Th) / t.zoom;
            e[0].object.visible = !0;
            let i, r;
            for(i = 1, r = e.length; i < r; i++){
                let a = e[i].distance;
                if (e[i].object.visible && (a -= a * e[i].hysteresis), n >= a) e[i - 1].object.visible = !1, e[i].object.visible = !0;
                else break;
            }
            for(this._currentLevel = i - 1; i < r; i++)e[i].object.visible = !1;
        }
    }
    toJSON(t) {
        let e = super.toJSON(t);
        this.autoUpdate === !1 && (e.object.autoUpdate = !1), e.object.levels = [];
        let n = this.levels;
        for(let i = 0, r = n.length; i < r; i++){
            let a = n[i];
            e.object.levels.push({
                object: a.object.uuid,
                distance: a.distance,
                hysteresis: a.hysteresis
            });
        }
        return e;
    }
}, wh = new A, Ah = new $t, Rh = new $t, H0 = new A, Ch = new Ot, Fi = new A, Ja = new We, Ph = new Ot, $a = new hi, Po = class extends ve {
    constructor(t, e){
        super(t, e), this.isSkinnedMesh = !0, this.type = "SkinnedMesh", this.bindMode = "attached", this.bindMatrix = new Ot, this.bindMatrixInverse = new Ot, this.boundingBox = null, this.boundingSphere = null;
    }
    computeBoundingBox() {
        let t = this.geometry;
        this.boundingBox === null && (this.boundingBox = new Ke), this.boundingBox.makeEmpty();
        let e = t.getAttribute("position");
        for(let n = 0; n < e.count; n++)Fi.fromBufferAttribute(e, n), this.applyBoneTransform(n, Fi), this.boundingBox.expandByPoint(Fi);
    }
    computeBoundingSphere() {
        let t = this.geometry;
        this.boundingSphere === null && (this.boundingSphere = new We), this.boundingSphere.makeEmpty();
        let e = t.getAttribute("position");
        for(let n = 0; n < e.count; n++)Fi.fromBufferAttribute(e, n), this.applyBoneTransform(n, Fi), this.boundingSphere.expandByPoint(Fi);
    }
    copy(t, e) {
        return super.copy(t, e), this.bindMode = t.bindMode, this.bindMatrix.copy(t.bindMatrix), this.bindMatrixInverse.copy(t.bindMatrixInverse), this.skeleton = t.skeleton, t.boundingBox !== null && (this.boundingBox = t.boundingBox.clone()), t.boundingSphere !== null && (this.boundingSphere = t.boundingSphere.clone()), this;
    }
    raycast(t, e) {
        let n = this.material, i = this.matrixWorld;
        n !== void 0 && (this.boundingSphere === null && this.computeBoundingSphere(), Ja.copy(this.boundingSphere), Ja.applyMatrix4(i), t.ray.intersectsSphere(Ja) !== !1 && (Ph.copy(i).invert(), $a.copy(t.ray).applyMatrix4(Ph), !(this.boundingBox !== null && $a.intersectsBox(this.boundingBox) === !1) && this._computeIntersections(t, e, $a)));
    }
    getVertexPosition(t, e) {
        return super.getVertexPosition(t, e), this.applyBoneTransform(t, e), e;
    }
    bind(t, e) {
        this.skeleton = t, e === void 0 && (this.updateMatrixWorld(!0), this.skeleton.calculateInverses(), e = this.matrixWorld), this.bindMatrix.copy(e), this.bindMatrixInverse.copy(e).invert();
    }
    pose() {
        this.skeleton.pose();
    }
    normalizeSkinWeights() {
        let t = new $t, e = this.geometry.attributes.skinWeight;
        for(let n = 0, i = e.count; n < i; n++){
            t.fromBufferAttribute(e, n);
            let r = 1 / t.manhattanLength();
            r !== 1 / 0 ? t.multiplyScalar(r) : t.set(1, 0, 0, 0), e.setXYZW(n, t.x, t.y, t.z, t.w);
        }
    }
    updateMatrixWorld(t) {
        super.updateMatrixWorld(t), this.bindMode === "attached" ? this.bindMatrixInverse.copy(this.matrixWorld).invert() : this.bindMode === "detached" ? this.bindMatrixInverse.copy(this.bindMatrix).invert() : console.warn("THREE.SkinnedMesh: Unrecognized bindMode: " + this.bindMode);
    }
    applyBoneTransform(t, e) {
        let n = this.skeleton, i = this.geometry;
        Ah.fromBufferAttribute(i.attributes.skinIndex, t), Rh.fromBufferAttribute(i.attributes.skinWeight, t), wh.copy(e).applyMatrix4(this.bindMatrix), e.set(0, 0, 0);
        for(let r = 0; r < 4; r++){
            let a = Rh.getComponent(r);
            if (a !== 0) {
                let o = Ah.getComponent(r);
                Ch.multiplyMatrices(n.bones[o].matrixWorld, n.boneInverses[o]), e.addScaledVector(H0.copy(wh).applyMatrix4(Ch), a);
            }
        }
        return e.applyMatrix4(this.bindMatrixInverse);
    }
    boneTransform(t, e) {
        return console.warn("THREE.SkinnedMesh: .boneTransform() was renamed to .applyBoneTransform() in r151."), this.applyBoneTransform(t, e);
    }
}, jr = class extends Zt {
    constructor(){
        super(), this.isBone = !0, this.type = "Bone";
    }
}, oi = class extends ye {
    constructor(t = null, e = 1, n = 1, i, r, a, o, c, l = fe, h = fe, u, d){
        super(null, a, o, c, l, h, i, r, u, d), this.isDataTexture = !0, this.image = {
            data: t,
            width: e,
            height: n
        }, this.generateMipmaps = !1, this.flipY = !1, this.unpackAlignment = 1;
    }
}, Lh = new Ot, G0 = new Ot, Lo = class s1 {
    constructor(t = [], e = []){
        this.uuid = Be(), this.bones = t.slice(0), this.boneInverses = e, this.boneMatrices = null, this.boneTexture = null, this.boneTextureSize = 0, this.init();
    }
    init() {
        let t = this.bones, e = this.boneInverses;
        if (this.boneMatrices = new Float32Array(t.length * 16), e.length === 0) this.calculateInverses();
        else if (t.length !== e.length) {
            console.warn("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones."), this.boneInverses = [];
            for(let n = 0, i = this.bones.length; n < i; n++)this.boneInverses.push(new Ot);
        }
    }
    calculateInverses() {
        this.boneInverses.length = 0;
        for(let t = 0, e = this.bones.length; t < e; t++){
            let n = new Ot;
            this.bones[t] && n.copy(this.bones[t].matrixWorld).invert(), this.boneInverses.push(n);
        }
    }
    pose() {
        for(let t = 0, e = this.bones.length; t < e; t++){
            let n = this.bones[t];
            n && n.matrixWorld.copy(this.boneInverses[t]).invert();
        }
        for(let t = 0, e = this.bones.length; t < e; t++){
            let n = this.bones[t];
            n && (n.parent && n.parent.isBone ? (n.matrix.copy(n.parent.matrixWorld).invert(), n.matrix.multiply(n.matrixWorld)) : n.matrix.copy(n.matrixWorld), n.matrix.decompose(n.position, n.quaternion, n.scale));
        }
    }
    update() {
        let t = this.bones, e = this.boneInverses, n = this.boneMatrices, i = this.boneTexture;
        for(let r = 0, a = t.length; r < a; r++){
            let o = t[r] ? t[r].matrixWorld : G0;
            Lh.multiplyMatrices(o, e[r]), Lh.toArray(n, r * 16);
        }
        i !== null && (i.needsUpdate = !0);
    }
    clone() {
        return new s1(this.bones, this.boneInverses);
    }
    computeBoneTexture() {
        let t = Math.sqrt(this.bones.length * 4);
        t = md(t), t = Math.max(t, 4);
        let e = new Float32Array(t * t * 4);
        e.set(this.boneMatrices);
        let n = new oi(e, t, t, He, xn);
        return n.needsUpdate = !0, this.boneMatrices = e, this.boneTexture = n, this.boneTextureSize = t, this;
    }
    getBoneByName(t) {
        for(let e = 0, n = this.bones.length; e < n; e++){
            let i = this.bones[e];
            if (i.name === t) return i;
        }
    }
    dispose() {
        this.boneTexture !== null && (this.boneTexture.dispose(), this.boneTexture = null);
    }
    fromJSON(t, e) {
        this.uuid = t.uuid;
        for(let n = 0, i = t.bones.length; n < i; n++){
            let r = t.bones[n], a = e[r];
            a === void 0 && (console.warn("THREE.Skeleton: No bone found with UUID:", r), a = new jr), this.bones.push(a), this.boneInverses.push(new Ot().fromArray(t.boneInverses[n]));
        }
        return this.init(), this;
    }
    toJSON() {
        let t = {
            metadata: {
                version: 4.6,
                type: "Skeleton",
                generator: "Skeleton.toJSON"
            },
            bones: [],
            boneInverses: []
        };
        t.uuid = this.uuid;
        let e = this.bones, n = this.boneInverses;
        for(let i = 0, r = e.length; i < r; i++){
            let a = e[i];
            t.bones.push(a.uuid);
            let o = n[i];
            t.boneInverses.push(o.toArray());
        }
        return t;
    }
}, ui = class extends Kt {
    constructor(t, e, n, i = 1){
        super(t, e, n), this.isInstancedBufferAttribute = !0, this.meshPerAttribute = i;
    }
    copy(t) {
        return super.copy(t), this.meshPerAttribute = t.meshPerAttribute, this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.meshPerAttribute = this.meshPerAttribute, t.isInstancedBufferAttribute = !0, t;
    }
}, Oi = new Ot, Ih = new Ot, mr = [], Uh = new Ke, W0 = new Ot, ms = new ve, gs = new We, Io = class extends ve {
    constructor(t, e, n){
        super(t, e), this.isInstancedMesh = !0, this.instanceMatrix = new ui(new Float32Array(n * 16), 16), this.instanceColor = null, this.count = n, this.boundingBox = null, this.boundingSphere = null;
        for(let i = 0; i < n; i++)this.setMatrixAt(i, W0);
    }
    computeBoundingBox() {
        let t = this.geometry, e = this.count;
        this.boundingBox === null && (this.boundingBox = new Ke), t.boundingBox === null && t.computeBoundingBox(), this.boundingBox.makeEmpty();
        for(let n = 0; n < e; n++)this.getMatrixAt(n, Oi), Uh.copy(t.boundingBox).applyMatrix4(Oi), this.boundingBox.union(Uh);
    }
    computeBoundingSphere() {
        let t = this.geometry, e = this.count;
        this.boundingSphere === null && (this.boundingSphere = new We), t.boundingSphere === null && t.computeBoundingSphere(), this.boundingSphere.makeEmpty();
        for(let n = 0; n < e; n++)this.getMatrixAt(n, Oi), gs.copy(t.boundingSphere).applyMatrix4(Oi), this.boundingSphere.union(gs);
    }
    copy(t, e) {
        return super.copy(t, e), this.instanceMatrix.copy(t.instanceMatrix), t.instanceColor !== null && (this.instanceColor = t.instanceColor.clone()), this.count = t.count, t.boundingBox !== null && (this.boundingBox = t.boundingBox.clone()), t.boundingSphere !== null && (this.boundingSphere = t.boundingSphere.clone()), this;
    }
    getColorAt(t, e) {
        e.fromArray(this.instanceColor.array, t * 3);
    }
    getMatrixAt(t, e) {
        e.fromArray(this.instanceMatrix.array, t * 16);
    }
    raycast(t, e) {
        let n = this.matrixWorld, i = this.count;
        if (ms.geometry = this.geometry, ms.material = this.material, ms.material !== void 0 && (this.boundingSphere === null && this.computeBoundingSphere(), gs.copy(this.boundingSphere), gs.applyMatrix4(n), t.ray.intersectsSphere(gs) !== !1)) for(let r = 0; r < i; r++){
            this.getMatrixAt(r, Oi), Ih.multiplyMatrices(n, Oi), ms.matrixWorld = Ih, ms.raycast(t, mr);
            for(let a = 0, o = mr.length; a < o; a++){
                let c = mr[a];
                c.instanceId = r, c.object = this, e.push(c);
            }
            mr.length = 0;
        }
    }
    setColorAt(t, e) {
        this.instanceColor === null && (this.instanceColor = new ui(new Float32Array(this.instanceMatrix.count * 3), 3)), e.toArray(this.instanceColor.array, t * 3);
    }
    setMatrixAt(t, e) {
        e.toArray(this.instanceMatrix.array, t * 16);
    }
    updateMorphTargets() {}
    dispose() {
        this.dispatchEvent({
            type: "dispose"
        });
    }
}, Ee = class extends Me {
    constructor(t){
        super(), this.isLineBasicMaterial = !0, this.type = "LineBasicMaterial", this.color = new ft(16777215), this.map = null, this.linewidth = 1, this.linecap = "round", this.linejoin = "round", this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.map = t.map, this.linewidth = t.linewidth, this.linecap = t.linecap, this.linejoin = t.linejoin, this.fog = t.fog, this;
    }
}, Dh = new A, Nh = new A, Fh = new Ot, Ka = new hi, gr = new We, Sn = class extends Zt {
    constructor(t = new Vt, e = new Ee){
        super(), this.isLine = !0, this.type = "Line", this.geometry = t, this.material = e, this.updateMorphTargets();
    }
    copy(t, e) {
        return super.copy(t, e), this.material = t.material, this.geometry = t.geometry, this;
    }
    computeLineDistances() {
        let t = this.geometry;
        if (t.index === null) {
            let e = t.attributes.position, n = [
                0
            ];
            for(let i = 1, r = e.count; i < r; i++)Dh.fromBufferAttribute(e, i - 1), Nh.fromBufferAttribute(e, i), n[i] = n[i - 1], n[i] += Dh.distanceTo(Nh);
            t.setAttribute("lineDistance", new _t(n, 1));
        } else console.warn("THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        return this;
    }
    raycast(t, e) {
        let n = this.geometry, i = this.matrixWorld, r = t.params.Line.threshold, a = n.drawRange;
        if (n.boundingSphere === null && n.computeBoundingSphere(), gr.copy(n.boundingSphere), gr.applyMatrix4(i), gr.radius += r, t.ray.intersectsSphere(gr) === !1) return;
        Fh.copy(i).invert(), Ka.copy(t.ray).applyMatrix4(Fh);
        let o = r / ((this.scale.x + this.scale.y + this.scale.z) / 3), c = o * o, l = new A, h = new A, u = new A, d = new A, f = this.isLineSegments ? 2 : 1, m = n.index, g = n.attributes.position;
        if (m !== null) {
            let p = Math.max(0, a.start), v = Math.min(m.count, a.start + a.count);
            for(let _ = p, y = v - 1; _ < y; _ += f){
                let b = m.getX(_), w = m.getX(_ + 1);
                if (l.fromBufferAttribute(g, b), h.fromBufferAttribute(g, w), Ka.distanceSqToSegment(l, h, d, u) > c) continue;
                d.applyMatrix4(this.matrixWorld);
                let L = t.ray.origin.distanceTo(d);
                L < t.near || L > t.far || e.push({
                    distance: L,
                    point: u.clone().applyMatrix4(this.matrixWorld),
                    index: _,
                    face: null,
                    faceIndex: null,
                    object: this
                });
            }
        } else {
            let p = Math.max(0, a.start), v = Math.min(g.count, a.start + a.count);
            for(let _ = p, y = v - 1; _ < y; _ += f){
                if (l.fromBufferAttribute(g, _), h.fromBufferAttribute(g, _ + 1), Ka.distanceSqToSegment(l, h, d, u) > c) continue;
                d.applyMatrix4(this.matrixWorld);
                let w = t.ray.origin.distanceTo(d);
                w < t.near || w > t.far || e.push({
                    distance: w,
                    point: u.clone().applyMatrix4(this.matrixWorld),
                    index: _,
                    face: null,
                    faceIndex: null,
                    object: this
                });
            }
        }
    }
    updateMorphTargets() {
        let e = this.geometry.morphAttributes, n = Object.keys(e);
        if (n.length > 0) {
            let i = e[n[0]];
            if (i !== void 0) {
                this.morphTargetInfluences = [], this.morphTargetDictionary = {};
                for(let r = 0, a = i.length; r < a; r++){
                    let o = i[r].name || String(r);
                    this.morphTargetInfluences.push(0), this.morphTargetDictionary[o] = r;
                }
            }
        }
    }
}, Oh = new A, Bh = new A, je = class extends Sn {
    constructor(t, e){
        super(t, e), this.isLineSegments = !0, this.type = "LineSegments";
    }
    computeLineDistances() {
        let t = this.geometry;
        if (t.index === null) {
            let e = t.attributes.position, n = [];
            for(let i = 0, r = e.count; i < r; i += 2)Oh.fromBufferAttribute(e, i), Bh.fromBufferAttribute(e, i + 1), n[i] = i === 0 ? 0 : n[i - 1], n[i + 1] = n[i] + Oh.distanceTo(Bh);
            t.setAttribute("lineDistance", new _t(n, 1));
        } else console.warn("THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        return this;
    }
}, Uo = class extends Sn {
    constructor(t, e){
        super(t, e), this.isLineLoop = !0, this.type = "LineLoop";
    }
}, ta = class extends Me {
    constructor(t){
        super(), this.isPointsMaterial = !0, this.type = "PointsMaterial", this.color = new ft(16777215), this.map = null, this.alphaMap = null, this.size = 1, this.sizeAttenuation = !0, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.map = t.map, this.alphaMap = t.alphaMap, this.size = t.size, this.sizeAttenuation = t.sizeAttenuation, this.fog = t.fog, this;
    }
}, zh = new Ot, Do = new hi, _r = new We, xr = new A, No = class extends Zt {
    constructor(t = new Vt, e = new ta){
        super(), this.isPoints = !0, this.type = "Points", this.geometry = t, this.material = e, this.updateMorphTargets();
    }
    copy(t, e) {
        return super.copy(t, e), this.material = t.material, this.geometry = t.geometry, this;
    }
    raycast(t, e) {
        let n = this.geometry, i = this.matrixWorld, r = t.params.Points.threshold, a = n.drawRange;
        if (n.boundingSphere === null && n.computeBoundingSphere(), _r.copy(n.boundingSphere), _r.applyMatrix4(i), _r.radius += r, t.ray.intersectsSphere(_r) === !1) return;
        zh.copy(i).invert(), Do.copy(t.ray).applyMatrix4(zh);
        let o = r / ((this.scale.x + this.scale.y + this.scale.z) / 3), c = o * o, l = n.index, u = n.attributes.position;
        if (l !== null) {
            let d = Math.max(0, a.start), f = Math.min(l.count, a.start + a.count);
            for(let m = d, x = f; m < x; m++){
                let g = l.getX(m);
                xr.fromBufferAttribute(u, g), kh(xr, g, c, i, t, e, this);
            }
        } else {
            let d = Math.max(0, a.start), f = Math.min(u.count, a.start + a.count);
            for(let m = d, x = f; m < x; m++)xr.fromBufferAttribute(u, m), kh(xr, m, c, i, t, e, this);
        }
    }
    updateMorphTargets() {
        let e = this.geometry.morphAttributes, n = Object.keys(e);
        if (n.length > 0) {
            let i = e[n[0]];
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
function kh(s1, t, e, n, i, r, a) {
    let o = Do.distanceSqToPoint(s1);
    if (o < e) {
        let c = new A;
        Do.closestPointToPoint(s1, c), c.applyMatrix4(n);
        let l = i.ray.origin.distanceTo(c);
        if (l < i.near || l > i.far) return;
        r.push({
            distance: l,
            distanceToRay: Math.sqrt(o),
            point: c,
            index: t,
            face: null,
            object: a
        });
    }
}
var Vh = class extends ye {
    constructor(t, e, n, i, r, a, o, c, l){
        super(t, e, n, i, r, a, o, c, l), this.isVideoTexture = !0, this.minFilter = a !== void 0 ? a : pe, this.magFilter = r !== void 0 ? r : pe, this.generateMipmaps = !1;
        let h = this;
        function u() {
            h.needsUpdate = !0, t.requestVideoFrameCallback(u);
        }
        "requestVideoFrameCallback" in t && t.requestVideoFrameCallback(u);
    }
    clone() {
        return new this.constructor(this.image).copy(this);
    }
    update() {
        let t = this.image;
        "requestVideoFrameCallback" in t === !1 && t.readyState >= t.HAVE_CURRENT_DATA && (this.needsUpdate = !0);
    }
}, Hh = class extends ye {
    constructor(t, e){
        super({
            width: t,
            height: e
        }), this.isFramebufferTexture = !0, this.magFilter = fe, this.minFilter = fe, this.generateMipmaps = !1, this.needsUpdate = !0;
    }
}, Us = class extends ye {
    constructor(t, e, n, i, r, a, o, c, l, h, u, d){
        super(null, a, o, c, l, h, i, r, u, d), this.isCompressedTexture = !0, this.image = {
            width: e,
            height: n
        }, this.mipmaps = t, this.flipY = !1, this.generateMipmaps = !1;
    }
}, Gh = class extends Us {
    constructor(t, e, n, i, r, a){
        super(t, e, n, r, a), this.isCompressedArrayTexture = !0, this.image.depth = i, this.wrapR = Ce;
    }
}, Wh = class extends Us {
    constructor(t, e, n){
        super(void 0, t[0].width, t[0].height, e, n, Bn), this.isCompressedCubeTexture = !0, this.isCubeTexture = !0, this.image = t;
    }
}, Xh = class extends ye {
    constructor(t, e, n, i, r, a, o, c, l){
        super(t, e, n, i, r, a, o, c, l), this.isCanvasTexture = !0, this.needsUpdate = !0;
    }
}, Xe = class {
    constructor(){
        this.type = "Curve", this.arcLengthDivisions = 200;
    }
    getPoint() {
        return console.warn("THREE.Curve: .getPoint() not implemented."), null;
    }
    getPointAt(t, e) {
        let n = this.getUtoTmapping(t);
        return this.getPoint(n, e);
    }
    getPoints(t = 5) {
        let e = [];
        for(let n = 0; n <= t; n++)e.push(this.getPoint(n / t));
        return e;
    }
    getSpacedPoints(t = 5) {
        let e = [];
        for(let n = 0; n <= t; n++)e.push(this.getPointAt(n / t));
        return e;
    }
    getLength() {
        let t = this.getLengths();
        return t[t.length - 1];
    }
    getLengths(t = this.arcLengthDivisions) {
        if (this.cacheArcLengths && this.cacheArcLengths.length === t + 1 && !this.needsUpdate) return this.cacheArcLengths;
        this.needsUpdate = !1;
        let e = [], n, i = this.getPoint(0), r = 0;
        e.push(0);
        for(let a = 1; a <= t; a++)n = this.getPoint(a / t), r += n.distanceTo(i), e.push(r), i = n;
        return this.cacheArcLengths = e, e;
    }
    updateArcLengths() {
        this.needsUpdate = !0, this.getLengths();
    }
    getUtoTmapping(t, e) {
        let n = this.getLengths(), i = 0, r = n.length, a;
        e ? a = e : a = t * n[r - 1];
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
    getTangent(t, e) {
        let i = t - 1e-4, r = t + 1e-4;
        i < 0 && (i = 0), r > 1 && (r = 1);
        let a = this.getPoint(i), o = this.getPoint(r), c = e || (a.isVector2 ? new J : new A);
        return c.copy(o).sub(a).normalize(), c;
    }
    getTangentAt(t, e) {
        let n = this.getUtoTmapping(t);
        return this.getTangent(n, e);
    }
    computeFrenetFrames(t, e) {
        let n = new A, i = [], r = [], a = [], o = new A, c = new Ot;
        for(let f = 0; f <= t; f++){
            let m = f / t;
            i[f] = this.getTangentAt(m, new A);
        }
        r[0] = new A, a[0] = new A;
        let l = Number.MAX_VALUE, h = Math.abs(i[0].x), u = Math.abs(i[0].y), d = Math.abs(i[0].z);
        h <= l && (l = h, n.set(1, 0, 0)), u <= l && (l = u, n.set(0, 1, 0)), d <= l && n.set(0, 0, 1), o.crossVectors(i[0], n).normalize(), r[0].crossVectors(i[0], o), a[0].crossVectors(i[0], r[0]);
        for(let f = 1; f <= t; f++){
            if (r[f] = r[f - 1].clone(), a[f] = a[f - 1].clone(), o.crossVectors(i[f - 1], i[f]), o.length() > Number.EPSILON) {
                o.normalize();
                let m = Math.acos(ae(i[f - 1].dot(i[f]), -1, 1));
                r[f].applyMatrix4(c.makeRotationAxis(o, m));
            }
            a[f].crossVectors(i[f], r[f]);
        }
        if (e === !0) {
            let f = Math.acos(ae(r[0].dot(r[t]), -1, 1));
            f /= t, i[0].dot(o.crossVectors(r[0], r[t])) > 0 && (f = -f);
            for(let m = 1; m <= t; m++)r[m].applyMatrix4(c.makeRotationAxis(i[m], f * m)), a[m].crossVectors(i[m], r[m]);
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
    copy(t) {
        return this.arcLengthDivisions = t.arcLengthDivisions, this;
    }
    toJSON() {
        let t = {
            metadata: {
                version: 4.6,
                type: "Curve",
                generator: "Curve.toJSON"
            }
        };
        return t.arcLengthDivisions = this.arcLengthDivisions, t.type = this.type, t;
    }
    fromJSON(t) {
        return this.arcLengthDivisions = t.arcLengthDivisions, this;
    }
}, Ds = class extends Xe {
    constructor(t = 0, e = 0, n = 1, i = 1, r = 0, a = Math.PI * 2, o = !1, c = 0){
        super(), this.isEllipseCurve = !0, this.type = "EllipseCurve", this.aX = t, this.aY = e, this.xRadius = n, this.yRadius = i, this.aStartAngle = r, this.aEndAngle = a, this.aClockwise = o, this.aRotation = c;
    }
    getPoint(t, e) {
        let n = e || new J, i = Math.PI * 2, r = this.aEndAngle - this.aStartAngle, a = Math.abs(r) < Number.EPSILON;
        for(; r < 0;)r += i;
        for(; r > i;)r -= i;
        r < Number.EPSILON && (a ? r = 0 : r = i), this.aClockwise === !0 && !a && (r === i ? r = -i : r = r - i);
        let o = this.aStartAngle + t * r, c = this.aX + this.xRadius * Math.cos(o), l = this.aY + this.yRadius * Math.sin(o);
        if (this.aRotation !== 0) {
            let h = Math.cos(this.aRotation), u = Math.sin(this.aRotation), d = c - this.aX, f = l - this.aY;
            c = d * h - f * u + this.aX, l = d * u + f * h + this.aY;
        }
        return n.set(c, l);
    }
    copy(t) {
        return super.copy(t), this.aX = t.aX, this.aY = t.aY, this.xRadius = t.xRadius, this.yRadius = t.yRadius, this.aStartAngle = t.aStartAngle, this.aEndAngle = t.aEndAngle, this.aClockwise = t.aClockwise, this.aRotation = t.aRotation, this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.aX = this.aX, t.aY = this.aY, t.xRadius = this.xRadius, t.yRadius = this.yRadius, t.aStartAngle = this.aStartAngle, t.aEndAngle = this.aEndAngle, t.aClockwise = this.aClockwise, t.aRotation = this.aRotation, t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.aX = t.aX, this.aY = t.aY, this.xRadius = t.xRadius, this.yRadius = t.yRadius, this.aStartAngle = t.aStartAngle, this.aEndAngle = t.aEndAngle, this.aClockwise = t.aClockwise, this.aRotation = t.aRotation, this;
    }
}, Fo = class extends Ds {
    constructor(t, e, n, i, r, a){
        super(t, e, n, n, i, r, a), this.isArcCurve = !0, this.type = "ArcCurve";
    }
};
function Hc() {
    let s1 = 0, t = 0, e = 0, n = 0;
    function i(r, a, o, c) {
        s1 = r, t = o, e = -3 * r + 3 * a - 2 * o - c, n = 2 * r - 2 * a + o + c;
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
            return s1 + t * r + e * a + n * o;
        }
    };
}
var vr = new A, Qa = new Hc, ja = new Hc, to = new Hc, Oo = class extends Xe {
    constructor(t = [], e = !1, n = "centripetal", i = .5){
        super(), this.isCatmullRomCurve3 = !0, this.type = "CatmullRomCurve3", this.points = t, this.closed = e, this.curveType = n, this.tension = i;
    }
    getPoint(t, e = new A) {
        let n = e, i = this.points, r = i.length, a = (r - (this.closed ? 0 : 1)) * t, o = Math.floor(a), c = a - o;
        this.closed ? o += o > 0 ? 0 : (Math.floor(Math.abs(o) / r) + 1) * r : c === 0 && o === r - 1 && (o = r - 2, c = 1);
        let l, h;
        this.closed || o > 0 ? l = i[(o - 1) % r] : (vr.subVectors(i[0], i[1]).add(i[0]), l = vr);
        let u = i[o % r], d = i[(o + 1) % r];
        if (this.closed || o + 2 < r ? h = i[(o + 2) % r] : (vr.subVectors(i[r - 1], i[r - 2]).add(i[r - 1]), h = vr), this.curveType === "centripetal" || this.curveType === "chordal") {
            let f = this.curveType === "chordal" ? .5 : .25, m = Math.pow(l.distanceToSquared(u), f), x = Math.pow(u.distanceToSquared(d), f), g = Math.pow(d.distanceToSquared(h), f);
            x < 1e-4 && (x = 1), m < 1e-4 && (m = x), g < 1e-4 && (g = x), Qa.initNonuniformCatmullRom(l.x, u.x, d.x, h.x, m, x, g), ja.initNonuniformCatmullRom(l.y, u.y, d.y, h.y, m, x, g), to.initNonuniformCatmullRom(l.z, u.z, d.z, h.z, m, x, g);
        } else this.curveType === "catmullrom" && (Qa.initCatmullRom(l.x, u.x, d.x, h.x, this.tension), ja.initCatmullRom(l.y, u.y, d.y, h.y, this.tension), to.initCatmullRom(l.z, u.z, d.z, h.z, this.tension));
        return n.set(Qa.calc(c), ja.calc(c), to.calc(c)), n;
    }
    copy(t) {
        super.copy(t), this.points = [];
        for(let e = 0, n = t.points.length; e < n; e++){
            let i = t.points[e];
            this.points.push(i.clone());
        }
        return this.closed = t.closed, this.curveType = t.curveType, this.tension = t.tension, this;
    }
    toJSON() {
        let t = super.toJSON();
        t.points = [];
        for(let e = 0, n = this.points.length; e < n; e++){
            let i = this.points[e];
            t.points.push(i.toArray());
        }
        return t.closed = this.closed, t.curveType = this.curveType, t.tension = this.tension, t;
    }
    fromJSON(t) {
        super.fromJSON(t), this.points = [];
        for(let e = 0, n = t.points.length; e < n; e++){
            let i = t.points[e];
            this.points.push(new A().fromArray(i));
        }
        return this.closed = t.closed, this.curveType = t.curveType, this.tension = t.tension, this;
    }
};
function qh(s1, t, e, n, i) {
    let r = (n - t) * .5, a = (i - e) * .5, o = s1 * s1, c = s1 * o;
    return (2 * e - 2 * n + r + a) * c + (-3 * e + 3 * n - 2 * r - a) * o + r * s1 + e;
}
function X0(s1, t) {
    let e = 1 - s1;
    return e * e * t;
}
function q0(s1, t) {
    return 2 * (1 - s1) * s1 * t;
}
function Y0(s1, t) {
    return s1 * s1 * t;
}
function bs(s1, t, e, n) {
    return X0(s1, t) + q0(s1, e) + Y0(s1, n);
}
function Z0(s1, t) {
    let e = 1 - s1;
    return e * e * e * t;
}
function J0(s1, t) {
    let e = 1 - s1;
    return 3 * e * e * s1 * t;
}
function $0(s1, t) {
    return 3 * (1 - s1) * s1 * s1 * t;
}
function K0(s1, t) {
    return s1 * s1 * s1 * t;
}
function Es(s1, t, e, n, i) {
    return Z0(s1, t) + J0(s1, e) + $0(s1, n) + K0(s1, i);
}
var ea = class extends Xe {
    constructor(t = new J, e = new J, n = new J, i = new J){
        super(), this.isCubicBezierCurve = !0, this.type = "CubicBezierCurve", this.v0 = t, this.v1 = e, this.v2 = n, this.v3 = i;
    }
    getPoint(t, e = new J) {
        let n = e, i = this.v0, r = this.v1, a = this.v2, o = this.v3;
        return n.set(Es(t, i.x, r.x, a.x, o.x), Es(t, i.y, r.y, a.y, o.y)), n;
    }
    copy(t) {
        return super.copy(t), this.v0.copy(t.v0), this.v1.copy(t.v1), this.v2.copy(t.v2), this.v3.copy(t.v3), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.v0 = this.v0.toArray(), t.v1 = this.v1.toArray(), t.v2 = this.v2.toArray(), t.v3 = this.v3.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.v0.fromArray(t.v0), this.v1.fromArray(t.v1), this.v2.fromArray(t.v2), this.v3.fromArray(t.v3), this;
    }
}, Bo = class extends Xe {
    constructor(t = new A, e = new A, n = new A, i = new A){
        super(), this.isCubicBezierCurve3 = !0, this.type = "CubicBezierCurve3", this.v0 = t, this.v1 = e, this.v2 = n, this.v3 = i;
    }
    getPoint(t, e = new A) {
        let n = e, i = this.v0, r = this.v1, a = this.v2, o = this.v3;
        return n.set(Es(t, i.x, r.x, a.x, o.x), Es(t, i.y, r.y, a.y, o.y), Es(t, i.z, r.z, a.z, o.z)), n;
    }
    copy(t) {
        return super.copy(t), this.v0.copy(t.v0), this.v1.copy(t.v1), this.v2.copy(t.v2), this.v3.copy(t.v3), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.v0 = this.v0.toArray(), t.v1 = this.v1.toArray(), t.v2 = this.v2.toArray(), t.v3 = this.v3.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.v0.fromArray(t.v0), this.v1.fromArray(t.v1), this.v2.fromArray(t.v2), this.v3.fromArray(t.v3), this;
    }
}, Ns = class extends Xe {
    constructor(t = new J, e = new J){
        super(), this.isLineCurve = !0, this.type = "LineCurve", this.v1 = t, this.v2 = e;
    }
    getPoint(t, e = new J) {
        let n = e;
        return t === 1 ? n.copy(this.v2) : (n.copy(this.v2).sub(this.v1), n.multiplyScalar(t).add(this.v1)), n;
    }
    getPointAt(t, e) {
        return this.getPoint(t, e);
    }
    getTangent(t, e = new J) {
        return e.subVectors(this.v2, this.v1).normalize();
    }
    getTangentAt(t, e) {
        return this.getTangent(t, e);
    }
    copy(t) {
        return super.copy(t), this.v1.copy(t.v1), this.v2.copy(t.v2), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.v1 = this.v1.toArray(), t.v2 = this.v2.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.v1.fromArray(t.v1), this.v2.fromArray(t.v2), this;
    }
}, zo = class extends Xe {
    constructor(t = new A, e = new A){
        super(), this.isLineCurve3 = !0, this.type = "LineCurve3", this.v1 = t, this.v2 = e;
    }
    getPoint(t, e = new A) {
        let n = e;
        return t === 1 ? n.copy(this.v2) : (n.copy(this.v2).sub(this.v1), n.multiplyScalar(t).add(this.v1)), n;
    }
    getPointAt(t, e) {
        return this.getPoint(t, e);
    }
    getTangent(t, e = new A) {
        return e.subVectors(this.v2, this.v1).normalize();
    }
    getTangentAt(t, e) {
        return this.getTangent(t, e);
    }
    copy(t) {
        return super.copy(t), this.v1.copy(t.v1), this.v2.copy(t.v2), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.v1 = this.v1.toArray(), t.v2 = this.v2.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.v1.fromArray(t.v1), this.v2.fromArray(t.v2), this;
    }
}, na = class extends Xe {
    constructor(t = new J, e = new J, n = new J){
        super(), this.isQuadraticBezierCurve = !0, this.type = "QuadraticBezierCurve", this.v0 = t, this.v1 = e, this.v2 = n;
    }
    getPoint(t, e = new J) {
        let n = e, i = this.v0, r = this.v1, a = this.v2;
        return n.set(bs(t, i.x, r.x, a.x), bs(t, i.y, r.y, a.y)), n;
    }
    copy(t) {
        return super.copy(t), this.v0.copy(t.v0), this.v1.copy(t.v1), this.v2.copy(t.v2), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.v0 = this.v0.toArray(), t.v1 = this.v1.toArray(), t.v2 = this.v2.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.v0.fromArray(t.v0), this.v1.fromArray(t.v1), this.v2.fromArray(t.v2), this;
    }
}, ia = class extends Xe {
    constructor(t = new A, e = new A, n = new A){
        super(), this.isQuadraticBezierCurve3 = !0, this.type = "QuadraticBezierCurve3", this.v0 = t, this.v1 = e, this.v2 = n;
    }
    getPoint(t, e = new A) {
        let n = e, i = this.v0, r = this.v1, a = this.v2;
        return n.set(bs(t, i.x, r.x, a.x), bs(t, i.y, r.y, a.y), bs(t, i.z, r.z, a.z)), n;
    }
    copy(t) {
        return super.copy(t), this.v0.copy(t.v0), this.v1.copy(t.v1), this.v2.copy(t.v2), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.v0 = this.v0.toArray(), t.v1 = this.v1.toArray(), t.v2 = this.v2.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.v0.fromArray(t.v0), this.v1.fromArray(t.v1), this.v2.fromArray(t.v2), this;
    }
}, sa = class extends Xe {
    constructor(t = []){
        super(), this.isSplineCurve = !0, this.type = "SplineCurve", this.points = t;
    }
    getPoint(t, e = new J) {
        let n = e, i = this.points, r = (i.length - 1) * t, a = Math.floor(r), o = r - a, c = i[a === 0 ? a : a - 1], l = i[a], h = i[a > i.length - 2 ? i.length - 1 : a + 1], u = i[a > i.length - 3 ? i.length - 1 : a + 2];
        return n.set(qh(o, c.x, l.x, h.x, u.x), qh(o, c.y, l.y, h.y, u.y)), n;
    }
    copy(t) {
        super.copy(t), this.points = [];
        for(let e = 0, n = t.points.length; e < n; e++){
            let i = t.points[e];
            this.points.push(i.clone());
        }
        return this;
    }
    toJSON() {
        let t = super.toJSON();
        t.points = [];
        for(let e = 0, n = this.points.length; e < n; e++){
            let i = this.points[e];
            t.points.push(i.toArray());
        }
        return t;
    }
    fromJSON(t) {
        super.fromJSON(t), this.points = [];
        for(let e = 0, n = t.points.length; e < n; e++){
            let i = t.points[e];
            this.points.push(new J().fromArray(i));
        }
        return this;
    }
}, Gc = Object.freeze({
    __proto__: null,
    ArcCurve: Fo,
    CatmullRomCurve3: Oo,
    CubicBezierCurve: ea,
    CubicBezierCurve3: Bo,
    EllipseCurve: Ds,
    LineCurve: Ns,
    LineCurve3: zo,
    QuadraticBezierCurve: na,
    QuadraticBezierCurve3: ia,
    SplineCurve: sa
}), ko = class extends Xe {
    constructor(){
        super(), this.type = "CurvePath", this.curves = [], this.autoClose = !1;
    }
    add(t) {
        this.curves.push(t);
    }
    closePath() {
        let t = this.curves[0].getPoint(0), e = this.curves[this.curves.length - 1].getPoint(1);
        t.equals(e) || this.curves.push(new Ns(e, t));
    }
    getPoint(t, e) {
        let n = t * this.getLength(), i = this.getCurveLengths(), r = 0;
        for(; r < i.length;){
            if (i[r] >= n) {
                let a = i[r] - n, o = this.curves[r], c = o.getLength(), l = c === 0 ? 0 : 1 - a / c;
                return o.getPointAt(l, e);
            }
            r++;
        }
        return null;
    }
    getLength() {
        let t = this.getCurveLengths();
        return t[t.length - 1];
    }
    updateArcLengths() {
        this.needsUpdate = !0, this.cacheLengths = null, this.getCurveLengths();
    }
    getCurveLengths() {
        if (this.cacheLengths && this.cacheLengths.length === this.curves.length) return this.cacheLengths;
        let t = [], e = 0;
        for(let n = 0, i = this.curves.length; n < i; n++)e += this.curves[n].getLength(), t.push(e);
        return this.cacheLengths = t, t;
    }
    getSpacedPoints(t = 40) {
        let e = [];
        for(let n = 0; n <= t; n++)e.push(this.getPoint(n / t));
        return this.autoClose && e.push(e[0]), e;
    }
    getPoints(t = 12) {
        let e = [], n;
        for(let i = 0, r = this.curves; i < r.length; i++){
            let a = r[i], o = a.isEllipseCurve ? t * 2 : a.isLineCurve || a.isLineCurve3 ? 1 : a.isSplineCurve ? t * a.points.length : t, c = a.getPoints(o);
            for(let l = 0; l < c.length; l++){
                let h = c[l];
                n && n.equals(h) || (e.push(h), n = h);
            }
        }
        return this.autoClose && e.length > 1 && !e[e.length - 1].equals(e[0]) && e.push(e[0]), e;
    }
    copy(t) {
        super.copy(t), this.curves = [];
        for(let e = 0, n = t.curves.length; e < n; e++){
            let i = t.curves[e];
            this.curves.push(i.clone());
        }
        return this.autoClose = t.autoClose, this;
    }
    toJSON() {
        let t = super.toJSON();
        t.autoClose = this.autoClose, t.curves = [];
        for(let e = 0, n = this.curves.length; e < n; e++){
            let i = this.curves[e];
            t.curves.push(i.toJSON());
        }
        return t;
    }
    fromJSON(t) {
        super.fromJSON(t), this.autoClose = t.autoClose, this.curves = [];
        for(let e = 0, n = t.curves.length; e < n; e++){
            let i = t.curves[e];
            this.curves.push(new Gc[i.type]().fromJSON(i));
        }
        return this;
    }
}, ji = class extends ko {
    constructor(t){
        super(), this.type = "Path", this.currentPoint = new J, t && this.setFromPoints(t);
    }
    setFromPoints(t) {
        this.moveTo(t[0].x, t[0].y);
        for(let e = 1, n = t.length; e < n; e++)this.lineTo(t[e].x, t[e].y);
        return this;
    }
    moveTo(t, e) {
        return this.currentPoint.set(t, e), this;
    }
    lineTo(t, e) {
        let n = new Ns(this.currentPoint.clone(), new J(t, e));
        return this.curves.push(n), this.currentPoint.set(t, e), this;
    }
    quadraticCurveTo(t, e, n, i) {
        let r = new na(this.currentPoint.clone(), new J(t, e), new J(n, i));
        return this.curves.push(r), this.currentPoint.set(n, i), this;
    }
    bezierCurveTo(t, e, n, i, r, a) {
        let o = new ea(this.currentPoint.clone(), new J(t, e), new J(n, i), new J(r, a));
        return this.curves.push(o), this.currentPoint.set(r, a), this;
    }
    splineThru(t) {
        let e = [
            this.currentPoint.clone()
        ].concat(t), n = new sa(e);
        return this.curves.push(n), this.currentPoint.copy(t[t.length - 1]), this;
    }
    arc(t, e, n, i, r, a) {
        let o = this.currentPoint.x, c = this.currentPoint.y;
        return this.absarc(t + o, e + c, n, i, r, a), this;
    }
    absarc(t, e, n, i, r, a) {
        return this.absellipse(t, e, n, n, i, r, a), this;
    }
    ellipse(t, e, n, i, r, a, o, c) {
        let l = this.currentPoint.x, h = this.currentPoint.y;
        return this.absellipse(t + l, e + h, n, i, r, a, o, c), this;
    }
    absellipse(t, e, n, i, r, a, o, c) {
        let l = new Ds(t, e, n, i, r, a, o, c);
        if (this.curves.length > 0) {
            let u = l.getPoint(0);
            u.equals(this.currentPoint) || this.lineTo(u.x, u.y);
        }
        this.curves.push(l);
        let h = l.getPoint(1);
        return this.currentPoint.copy(h), this;
    }
    copy(t) {
        return super.copy(t), this.currentPoint.copy(t.currentPoint), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.currentPoint = this.currentPoint.toArray(), t;
    }
    fromJSON(t) {
        return super.fromJSON(t), this.currentPoint.fromArray(t.currentPoint), this;
    }
}, ra = class s1 extends Vt {
    constructor(t = [
        new J(0, -.5),
        new J(.5, 0),
        new J(0, .5)
    ], e = 12, n = 0, i = Math.PI * 2){
        super(), this.type = "LatheGeometry", this.parameters = {
            points: t,
            segments: e,
            phiStart: n,
            phiLength: i
        }, e = Math.floor(e), i = ae(i, 0, Math.PI * 2);
        let r = [], a = [], o = [], c = [], l = [], h = 1 / e, u = new A, d = new J, f = new A, m = new A, x = new A, g = 0, p = 0;
        for(let v = 0; v <= t.length - 1; v++)switch(v){
            case 0:
                g = t[v + 1].x - t[v].x, p = t[v + 1].y - t[v].y, f.x = p * 1, f.y = -g, f.z = p * 0, x.copy(f), f.normalize(), c.push(f.x, f.y, f.z);
                break;
            case t.length - 1:
                c.push(x.x, x.y, x.z);
                break;
            default:
                g = t[v + 1].x - t[v].x, p = t[v + 1].y - t[v].y, f.x = p * 1, f.y = -g, f.z = p * 0, m.copy(f), f.x += x.x, f.y += x.y, f.z += x.z, f.normalize(), c.push(f.x, f.y, f.z), x.copy(m);
        }
        for(let v = 0; v <= e; v++){
            let _ = n + v * h * i, y = Math.sin(_), b = Math.cos(_);
            for(let w = 0; w <= t.length - 1; w++){
                u.x = t[w].x * y, u.y = t[w].y, u.z = t[w].x * b, a.push(u.x, u.y, u.z), d.x = v / e, d.y = w / (t.length - 1), o.push(d.x, d.y);
                let R = c[3 * w + 0] * y, L = c[3 * w + 1], M = c[3 * w + 0] * b;
                l.push(R, L, M);
            }
        }
        for(let v = 0; v < e; v++)for(let _ = 0; _ < t.length - 1; _++){
            let y = _ + v * t.length, b = y, w = y + t.length, R = y + t.length + 1, L = y + 1;
            r.push(b, w, L), r.push(R, L, w);
        }
        this.setIndex(r), this.setAttribute("position", new _t(a, 3)), this.setAttribute("uv", new _t(o, 2)), this.setAttribute("normal", new _t(l, 3));
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.points, t.segments, t.phiStart, t.phiLength);
    }
}, Vo = class s1 extends ra {
    constructor(t = 1, e = 1, n = 4, i = 8){
        let r = new ji;
        r.absarc(0, -e / 2, t, Math.PI * 1.5, 0), r.absarc(0, e / 2, t, 0, Math.PI * .5), super(r.getPoints(n), i), this.type = "CapsuleGeometry", this.parameters = {
            radius: t,
            length: e,
            capSegments: n,
            radialSegments: i
        };
    }
    static fromJSON(t) {
        return new s1(t.radius, t.length, t.capSegments, t.radialSegments);
    }
}, Ho = class s1 extends Vt {
    constructor(t = 1, e = 32, n = 0, i = Math.PI * 2){
        super(), this.type = "CircleGeometry", this.parameters = {
            radius: t,
            segments: e,
            thetaStart: n,
            thetaLength: i
        }, e = Math.max(3, e);
        let r = [], a = [], o = [], c = [], l = new A, h = new J;
        a.push(0, 0, 0), o.push(0, 0, 1), c.push(.5, .5);
        for(let u = 0, d = 3; u <= e; u++, d += 3){
            let f = n + u / e * i;
            l.x = t * Math.cos(f), l.y = t * Math.sin(f), a.push(l.x, l.y, l.z), o.push(0, 0, 1), h.x = (a[d] / t + 1) / 2, h.y = (a[d + 1] / t + 1) / 2, c.push(h.x, h.y);
        }
        for(let u = 1; u <= e; u++)r.push(u, u + 1, 0);
        this.setIndex(r), this.setAttribute("position", new _t(a, 3)), this.setAttribute("normal", new _t(o, 3)), this.setAttribute("uv", new _t(c, 2));
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.radius, t.segments, t.thetaStart, t.thetaLength);
    }
}, Fs = class s1 extends Vt {
    constructor(t = 1, e = 1, n = 1, i = 32, r = 1, a = !1, o = 0, c = Math.PI * 2){
        super(), this.type = "CylinderGeometry", this.parameters = {
            radiusTop: t,
            radiusBottom: e,
            height: n,
            radialSegments: i,
            heightSegments: r,
            openEnded: a,
            thetaStart: o,
            thetaLength: c
        };
        let l = this;
        i = Math.floor(i), r = Math.floor(r);
        let h = [], u = [], d = [], f = [], m = 0, x = [], g = n / 2, p = 0;
        v(), a === !1 && (t > 0 && _(!0), e > 0 && _(!1)), this.setIndex(h), this.setAttribute("position", new _t(u, 3)), this.setAttribute("normal", new _t(d, 3)), this.setAttribute("uv", new _t(f, 2));
        function v() {
            let y = new A, b = new A, w = 0, R = (e - t) / n;
            for(let L = 0; L <= r; L++){
                let M = [], E = L / r, V = E * (e - t) + t;
                for(let $ = 0; $ <= i; $++){
                    let F = $ / i, O = F * c + o, z = Math.sin(O), K = Math.cos(O);
                    b.x = V * z, b.y = -E * n + g, b.z = V * K, u.push(b.x, b.y, b.z), y.set(z, R, K).normalize(), d.push(y.x, y.y, y.z), f.push(F, 1 - E), M.push(m++);
                }
                x.push(M);
            }
            for(let L = 0; L < i; L++)for(let M = 0; M < r; M++){
                let E = x[M][L], V = x[M + 1][L], $ = x[M + 1][L + 1], F = x[M][L + 1];
                h.push(E, V, F), h.push(V, $, F), w += 6;
            }
            l.addGroup(p, w, 0), p += w;
        }
        function _(y) {
            let b = m, w = new J, R = new A, L = 0, M = y === !0 ? t : e, E = y === !0 ? 1 : -1;
            for(let $ = 1; $ <= i; $++)u.push(0, g * E, 0), d.push(0, E, 0), f.push(.5, .5), m++;
            let V = m;
            for(let $ = 0; $ <= i; $++){
                let O = $ / i * c + o, z = Math.cos(O), K = Math.sin(O);
                R.x = M * K, R.y = g * E, R.z = M * z, u.push(R.x, R.y, R.z), d.push(0, E, 0), w.x = z * .5 + .5, w.y = K * .5 * E + .5, f.push(w.x, w.y), m++;
            }
            for(let $ = 0; $ < i; $++){
                let F = b + $, O = V + $;
                y === !0 ? h.push(O, O + 1, F) : h.push(O + 1, O, F), L += 3;
            }
            l.addGroup(p, L, y === !0 ? 1 : 2), p += L;
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.radiusTop, t.radiusBottom, t.height, t.radialSegments, t.heightSegments, t.openEnded, t.thetaStart, t.thetaLength);
    }
}, Go = class s1 extends Fs {
    constructor(t = 1, e = 1, n = 32, i = 1, r = !1, a = 0, o = Math.PI * 2){
        super(0, t, e, n, i, r, a, o), this.type = "ConeGeometry", this.parameters = {
            radius: t,
            height: e,
            radialSegments: n,
            heightSegments: i,
            openEnded: r,
            thetaStart: a,
            thetaLength: o
        };
    }
    static fromJSON(t) {
        return new s1(t.radius, t.height, t.radialSegments, t.heightSegments, t.openEnded, t.thetaStart, t.thetaLength);
    }
}, di = class s1 extends Vt {
    constructor(t = [], e = [], n = 1, i = 0){
        super(), this.type = "PolyhedronGeometry", this.parameters = {
            vertices: t,
            indices: e,
            radius: n,
            detail: i
        };
        let r = [], a = [];
        o(i), l(n), h(), this.setAttribute("position", new _t(r, 3)), this.setAttribute("normal", new _t(r.slice(), 3)), this.setAttribute("uv", new _t(a, 2)), i === 0 ? this.computeVertexNormals() : this.normalizeNormals();
        function o(v) {
            let _ = new A, y = new A, b = new A;
            for(let w = 0; w < e.length; w += 3)f(e[w + 0], _), f(e[w + 1], y), f(e[w + 2], b), c(_, y, b, v);
        }
        function c(v, _, y, b) {
            let w = b + 1, R = [];
            for(let L = 0; L <= w; L++){
                R[L] = [];
                let M = v.clone().lerp(y, L / w), E = _.clone().lerp(y, L / w), V = w - L;
                for(let $ = 0; $ <= V; $++)$ === 0 && L === w ? R[L][$] = M : R[L][$] = M.clone().lerp(E, $ / V);
            }
            for(let L = 0; L < w; L++)for(let M = 0; M < 2 * (w - L) - 1; M++){
                let E = Math.floor(M / 2);
                M % 2 === 0 ? (d(R[L][E + 1]), d(R[L + 1][E]), d(R[L][E])) : (d(R[L][E + 1]), d(R[L + 1][E + 1]), d(R[L + 1][E]));
            }
        }
        function l(v) {
            let _ = new A;
            for(let y = 0; y < r.length; y += 3)_.x = r[y + 0], _.y = r[y + 1], _.z = r[y + 2], _.normalize().multiplyScalar(v), r[y + 0] = _.x, r[y + 1] = _.y, r[y + 2] = _.z;
        }
        function h() {
            let v = new A;
            for(let _ = 0; _ < r.length; _ += 3){
                v.x = r[_ + 0], v.y = r[_ + 1], v.z = r[_ + 2];
                let y = g(v) / 2 / Math.PI + .5, b = p(v) / Math.PI + .5;
                a.push(y, 1 - b);
            }
            m(), u();
        }
        function u() {
            for(let v = 0; v < a.length; v += 6){
                let _ = a[v + 0], y = a[v + 2], b = a[v + 4], w = Math.max(_, y, b), R = Math.min(_, y, b);
                w > .9 && R < .1 && (_ < .2 && (a[v + 0] += 1), y < .2 && (a[v + 2] += 1), b < .2 && (a[v + 4] += 1));
            }
        }
        function d(v) {
            r.push(v.x, v.y, v.z);
        }
        function f(v, _) {
            let y = v * 3;
            _.x = t[y + 0], _.y = t[y + 1], _.z = t[y + 2];
        }
        function m() {
            let v = new A, _ = new A, y = new A, b = new A, w = new J, R = new J, L = new J;
            for(let M = 0, E = 0; M < r.length; M += 9, E += 6){
                v.set(r[M + 0], r[M + 1], r[M + 2]), _.set(r[M + 3], r[M + 4], r[M + 5]), y.set(r[M + 6], r[M + 7], r[M + 8]), w.set(a[E + 0], a[E + 1]), R.set(a[E + 2], a[E + 3]), L.set(a[E + 4], a[E + 5]), b.copy(v).add(_).add(y).divideScalar(3);
                let V = g(b);
                x(w, E + 0, v, V), x(R, E + 2, _, V), x(L, E + 4, y, V);
            }
        }
        function x(v, _, y, b) {
            b < 0 && v.x === 1 && (a[_] = v.x - 1), y.x === 0 && y.z === 0 && (a[_] = b / 2 / Math.PI + .5);
        }
        function g(v) {
            return Math.atan2(v.z, -v.x);
        }
        function p(v) {
            return Math.atan2(-v.y, Math.sqrt(v.x * v.x + v.z * v.z));
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.vertices, t.indices, t.radius, t.details);
    }
}, Wo = class s1 extends di {
    constructor(t = 1, e = 0){
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
        super(r, a, t, e), this.type = "DodecahedronGeometry", this.parameters = {
            radius: t,
            detail: e
        };
    }
    static fromJSON(t) {
        return new s1(t.radius, t.detail);
    }
}, yr = new A, Mr = new A, eo = new A, Sr = new In, Xo = class extends Vt {
    constructor(t = null, e = 1){
        if (super(), this.type = "EdgesGeometry", this.parameters = {
            geometry: t,
            thresholdAngle: e
        }, t !== null) {
            let i = Math.pow(10, 4), r = Math.cos(ai * e), a = t.getIndex(), o = t.getAttribute("position"), c = a ? a.count : o.count, l = [
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
                let { a: x , b: g , c: p  } = Sr;
                if (x.fromBufferAttribute(o, l[0]), g.fromBufferAttribute(o, l[1]), p.fromBufferAttribute(o, l[2]), Sr.getNormal(eo), u[0] = `${Math.round(x.x * i)},${Math.round(x.y * i)},${Math.round(x.z * i)}`, u[1] = `${Math.round(g.x * i)},${Math.round(g.y * i)},${Math.round(g.z * i)}`, u[2] = `${Math.round(p.x * i)},${Math.round(p.y * i)},${Math.round(p.z * i)}`, !(u[0] === u[1] || u[1] === u[2] || u[2] === u[0])) for(let v = 0; v < 3; v++){
                    let _ = (v + 1) % 3, y = u[v], b = u[_], w = Sr[h[v]], R = Sr[h[_]], L = `${y}_${b}`, M = `${b}_${y}`;
                    M in d && d[M] ? (eo.dot(d[M].normal) <= r && (f.push(w.x, w.y, w.z), f.push(R.x, R.y, R.z)), d[M] = null) : L in d || (d[L] = {
                        index0: l[v],
                        index1: l[_],
                        normal: eo.clone()
                    });
                }
            }
            for(let m in d)if (d[m]) {
                let { index0: x , index1: g  } = d[m];
                yr.fromBufferAttribute(o, x), Mr.fromBufferAttribute(o, g), f.push(yr.x, yr.y, yr.z), f.push(Mr.x, Mr.y, Mr.z);
            }
            this.setAttribute("position", new _t(f, 3));
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
}, Fn = class extends ji {
    constructor(t){
        super(t), this.uuid = Be(), this.type = "Shape", this.holes = [];
    }
    getPointsHoles(t) {
        let e = [];
        for(let n = 0, i = this.holes.length; n < i; n++)e[n] = this.holes[n].getPoints(t);
        return e;
    }
    extractPoints(t) {
        return {
            shape: this.getPoints(t),
            holes: this.getPointsHoles(t)
        };
    }
    copy(t) {
        super.copy(t), this.holes = [];
        for(let e = 0, n = t.holes.length; e < n; e++){
            let i = t.holes[e];
            this.holes.push(i.clone());
        }
        return this;
    }
    toJSON() {
        let t = super.toJSON();
        t.uuid = this.uuid, t.holes = [];
        for(let e = 0, n = this.holes.length; e < n; e++){
            let i = this.holes[e];
            t.holes.push(i.toJSON());
        }
        return t;
    }
    fromJSON(t) {
        super.fromJSON(t), this.uuid = t.uuid, this.holes = [];
        for(let e = 0, n = t.holes.length; e < n; e++){
            let i = t.holes[e];
            this.holes.push(new ji().fromJSON(i));
        }
        return this;
    }
}, Q0 = {
    triangulate: function(s1, t, e = 2) {
        let n = t && t.length, i = n ? t[0] * e : s1.length, r = Td(s1, 0, i, e, !0), a = [];
        if (!r || r.next === r.prev) return a;
        let o, c, l, h, u, d, f;
        if (n && (r = ix(s1, t, r, e)), s1.length > 80 * e) {
            o = l = s1[0], c = h = s1[1];
            for(let m = e; m < i; m += e)u = s1[m], d = s1[m + 1], u < o && (o = u), d < c && (c = d), u > l && (l = u), d > h && (h = d);
            f = Math.max(l - o, h - c), f = f !== 0 ? 32767 / f : 0;
        }
        return Os(r, a, e, o, c, f, 0), a;
    }
};
function Td(s1, t, e, n, i) {
    let r, a;
    if (i === px(s1, t, e, n) > 0) for(r = t; r < e; r += n)a = Yh(r, s1[r], s1[r + 1], a);
    else for(r = e - n; r >= t; r -= n)a = Yh(r, s1[r], s1[r + 1], a);
    return a && ga(a, a.next) && (zs(a), a = a.next), a;
}
function fi(s1, t) {
    if (!s1) return s1;
    t || (t = s1);
    let e = s1, n;
    do if (n = !1, !e.steiner && (ga(e, e.next) || ne(e.prev, e, e.next) === 0)) {
        if (zs(e), e = t = e.prev, e === e.next) break;
        n = !0;
    } else e = e.next;
    while (n || e !== t)
    return t;
}
function Os(s1, t, e, n, i, r, a) {
    if (!s1) return;
    !a && r && cx(s1, n, i, r);
    let o = s1, c, l;
    for(; s1.prev !== s1.next;){
        if (c = s1.prev, l = s1.next, r ? tx(s1, n, i, r) : j0(s1)) {
            t.push(c.i / e | 0), t.push(s1.i / e | 0), t.push(l.i / e | 0), zs(s1), s1 = l.next, o = l.next;
            continue;
        }
        if (s1 = l, s1 === o) {
            a ? a === 1 ? (s1 = ex(fi(s1), t, e), Os(s1, t, e, n, i, r, 2)) : a === 2 && nx(s1, t, e, n, i, r) : Os(fi(s1), t, e, n, i, r, 1);
            break;
        }
    }
}
function j0(s1) {
    let t = s1.prev, e = s1, n = s1.next;
    if (ne(t, e, n) >= 0) return !1;
    let i = t.x, r = e.x, a = n.x, o = t.y, c = e.y, l = n.y, h = i < r ? i < a ? i : a : r < a ? r : a, u = o < c ? o < l ? o : l : c < l ? c : l, d = i > r ? i > a ? i : a : r > a ? r : a, f = o > c ? o > l ? o : l : c > l ? c : l, m = n.next;
    for(; m !== t;){
        if (m.x >= h && m.x <= d && m.y >= u && m.y <= f && Gi(i, o, r, c, a, l, m.x, m.y) && ne(m.prev, m, m.next) >= 0) return !1;
        m = m.next;
    }
    return !0;
}
function tx(s1, t, e, n) {
    let i = s1.prev, r = s1, a = s1.next;
    if (ne(i, r, a) >= 0) return !1;
    let o = i.x, c = r.x, l = a.x, h = i.y, u = r.y, d = a.y, f = o < c ? o < l ? o : l : c < l ? c : l, m = h < u ? h < d ? h : d : u < d ? u : d, x = o > c ? o > l ? o : l : c > l ? c : l, g = h > u ? h > d ? h : d : u > d ? u : d, p = qo(f, m, t, e, n), v = qo(x, g, t, e, n), _ = s1.prevZ, y = s1.nextZ;
    for(; _ && _.z >= p && y && y.z <= v;){
        if (_.x >= f && _.x <= x && _.y >= m && _.y <= g && _ !== i && _ !== a && Gi(o, h, c, u, l, d, _.x, _.y) && ne(_.prev, _, _.next) >= 0 || (_ = _.prevZ, y.x >= f && y.x <= x && y.y >= m && y.y <= g && y !== i && y !== a && Gi(o, h, c, u, l, d, y.x, y.y) && ne(y.prev, y, y.next) >= 0)) return !1;
        y = y.nextZ;
    }
    for(; _ && _.z >= p;){
        if (_.x >= f && _.x <= x && _.y >= m && _.y <= g && _ !== i && _ !== a && Gi(o, h, c, u, l, d, _.x, _.y) && ne(_.prev, _, _.next) >= 0) return !1;
        _ = _.prevZ;
    }
    for(; y && y.z <= v;){
        if (y.x >= f && y.x <= x && y.y >= m && y.y <= g && y !== i && y !== a && Gi(o, h, c, u, l, d, y.x, y.y) && ne(y.prev, y, y.next) >= 0) return !1;
        y = y.nextZ;
    }
    return !0;
}
function ex(s1, t, e) {
    let n = s1;
    do {
        let i = n.prev, r = n.next.next;
        !ga(i, r) && wd(i, n, n.next, r) && Bs(i, r) && Bs(r, i) && (t.push(i.i / e | 0), t.push(n.i / e | 0), t.push(r.i / e | 0), zs(n), zs(n.next), n = s1 = r), n = n.next;
    }while (n !== s1)
    return fi(n);
}
function nx(s1, t, e, n, i, r) {
    let a = s1;
    do {
        let o = a.next.next;
        for(; o !== a.prev;){
            if (a.i !== o.i && ux(a, o)) {
                let c = Ad(a, o);
                a = fi(a, a.next), c = fi(c, c.next), Os(a, t, e, n, i, r, 0), Os(c, t, e, n, i, r, 0);
                return;
            }
            o = o.next;
        }
        a = a.next;
    }while (a !== s1)
}
function ix(s1, t, e, n) {
    let i = [], r, a, o, c, l;
    for(r = 0, a = t.length; r < a; r++)o = t[r] * n, c = r < a - 1 ? t[r + 1] * n : s1.length, l = Td(s1, o, c, n, !1), l === l.next && (l.steiner = !0), i.push(hx(l));
    for(i.sort(sx), r = 0; r < i.length; r++)e = rx(i[r], e);
    return e;
}
function sx(s1, t) {
    return s1.x - t.x;
}
function rx(s1, t) {
    let e = ax(s1, t);
    if (!e) return t;
    let n = Ad(e, s1);
    return fi(n, n.next), fi(e, e.next);
}
function ax(s1, t) {
    let e = t, n = -1 / 0, i, r = s1.x, a = s1.y;
    do {
        if (a <= e.y && a >= e.next.y && e.next.y !== e.y) {
            let d = e.x + (a - e.y) * (e.next.x - e.x) / (e.next.y - e.y);
            if (d <= r && d > n && (n = d, i = e.x < e.next.x ? e : e.next, d === r)) return i;
        }
        e = e.next;
    }while (e !== t)
    if (!i) return null;
    let o = i, c = i.x, l = i.y, h = 1 / 0, u;
    e = i;
    do r >= e.x && e.x >= c && r !== e.x && Gi(a < l ? r : n, a, c, l, a < l ? n : r, a, e.x, e.y) && (u = Math.abs(a - e.y) / (r - e.x), Bs(e, s1) && (u < h || u === h && (e.x > i.x || e.x === i.x && ox(i, e))) && (i = e, h = u)), e = e.next;
    while (e !== o)
    return i;
}
function ox(s1, t) {
    return ne(s1.prev, s1, t.prev) < 0 && ne(t.next, s1, s1.next) < 0;
}
function cx(s1, t, e, n) {
    let i = s1;
    do i.z === 0 && (i.z = qo(i.x, i.y, t, e, n)), i.prevZ = i.prev, i.nextZ = i.next, i = i.next;
    while (i !== s1)
    i.prevZ.nextZ = null, i.prevZ = null, lx(i);
}
function lx(s1) {
    let t, e, n, i, r, a, o, c, l = 1;
    do {
        for(e = s1, s1 = null, r = null, a = 0; e;){
            for(a++, n = e, o = 0, t = 0; t < l && (o++, n = n.nextZ, !!n); t++);
            for(c = l; o > 0 || c > 0 && n;)o !== 0 && (c === 0 || !n || e.z <= n.z) ? (i = e, e = e.nextZ, o--) : (i = n, n = n.nextZ, c--), r ? r.nextZ = i : s1 = i, i.prevZ = r, r = i;
            e = n;
        }
        r.nextZ = null, l *= 2;
    }while (a > 1)
    return s1;
}
function qo(s1, t, e, n, i) {
    return s1 = (s1 - e) * i | 0, t = (t - n) * i | 0, s1 = (s1 | s1 << 8) & 16711935, s1 = (s1 | s1 << 4) & 252645135, s1 = (s1 | s1 << 2) & 858993459, s1 = (s1 | s1 << 1) & 1431655765, t = (t | t << 8) & 16711935, t = (t | t << 4) & 252645135, t = (t | t << 2) & 858993459, t = (t | t << 1) & 1431655765, s1 | t << 1;
}
function hx(s1) {
    let t = s1, e = s1;
    do (t.x < e.x || t.x === e.x && t.y < e.y) && (e = t), t = t.next;
    while (t !== s1)
    return e;
}
function Gi(s1, t, e, n, i, r, a, o) {
    return (i - a) * (t - o) >= (s1 - a) * (r - o) && (s1 - a) * (n - o) >= (e - a) * (t - o) && (e - a) * (r - o) >= (i - a) * (n - o);
}
function ux(s1, t) {
    return s1.next.i !== t.i && s1.prev.i !== t.i && !dx(s1, t) && (Bs(s1, t) && Bs(t, s1) && fx(s1, t) && (ne(s1.prev, s1, t.prev) || ne(s1, t.prev, t)) || ga(s1, t) && ne(s1.prev, s1, s1.next) > 0 && ne(t.prev, t, t.next) > 0);
}
function ne(s1, t, e) {
    return (t.y - s1.y) * (e.x - t.x) - (t.x - s1.x) * (e.y - t.y);
}
function ga(s1, t) {
    return s1.x === t.x && s1.y === t.y;
}
function wd(s1, t, e, n) {
    let i = Er(ne(s1, t, e)), r = Er(ne(s1, t, n)), a = Er(ne(e, n, s1)), o = Er(ne(e, n, t));
    return !!(i !== r && a !== o || i === 0 && br(s1, e, t) || r === 0 && br(s1, n, t) || a === 0 && br(e, s1, n) || o === 0 && br(e, t, n));
}
function br(s1, t, e) {
    return t.x <= Math.max(s1.x, e.x) && t.x >= Math.min(s1.x, e.x) && t.y <= Math.max(s1.y, e.y) && t.y >= Math.min(s1.y, e.y);
}
function Er(s1) {
    return s1 > 0 ? 1 : s1 < 0 ? -1 : 0;
}
function dx(s1, t) {
    let e = s1;
    do {
        if (e.i !== s1.i && e.next.i !== s1.i && e.i !== t.i && e.next.i !== t.i && wd(e, e.next, s1, t)) return !0;
        e = e.next;
    }while (e !== s1)
    return !1;
}
function Bs(s1, t) {
    return ne(s1.prev, s1, s1.next) < 0 ? ne(s1, t, s1.next) >= 0 && ne(s1, s1.prev, t) >= 0 : ne(s1, t, s1.prev) < 0 || ne(s1, s1.next, t) < 0;
}
function fx(s1, t) {
    let e = s1, n = !1, i = (s1.x + t.x) / 2, r = (s1.y + t.y) / 2;
    do e.y > r != e.next.y > r && e.next.y !== e.y && i < (e.next.x - e.x) * (r - e.y) / (e.next.y - e.y) + e.x && (n = !n), e = e.next;
    while (e !== s1)
    return n;
}
function Ad(s1, t) {
    let e = new Yo(s1.i, s1.x, s1.y), n = new Yo(t.i, t.x, t.y), i = s1.next, r = t.prev;
    return s1.next = t, t.prev = s1, e.next = i, i.prev = e, n.next = e, e.prev = n, r.next = n, n.prev = r, n;
}
function Yh(s1, t, e, n) {
    let i = new Yo(s1, t, e);
    return n ? (i.next = n.next, i.prev = n, n.next.prev = i, n.next = i) : (i.prev = i, i.next = i), i;
}
function zs(s1) {
    s1.next.prev = s1.prev, s1.prev.next = s1.next, s1.prevZ && (s1.prevZ.nextZ = s1.nextZ), s1.nextZ && (s1.nextZ.prevZ = s1.prevZ);
}
function Yo(s1, t, e) {
    this.i = s1, this.x = t, this.y = e, this.prev = null, this.next = null, this.z = 0, this.prevZ = null, this.nextZ = null, this.steiner = !1;
}
function px(s1, t, e, n) {
    let i = 0;
    for(let r = t, a = e - n; r < e; r += n)i += (s1[a] - s1[r]) * (s1[r + 1] + s1[a + 1]), a = r;
    return i;
}
var yn = class s1 {
    static area(t) {
        let e = t.length, n = 0;
        for(let i = e - 1, r = 0; r < e; i = r++)n += t[i].x * t[r].y - t[r].x * t[i].y;
        return n * .5;
    }
    static isClockWise(t) {
        return s1.area(t) < 0;
    }
    static triangulateShape(t, e) {
        let n = [], i = [], r = [];
        Zh(t), Jh(n, t);
        let a = t.length;
        e.forEach(Zh);
        for(let c = 0; c < e.length; c++)i.push(a), a += e[c].length, Jh(n, e[c]);
        let o = Q0.triangulate(n, i);
        for(let c = 0; c < o.length; c += 3)r.push(o.slice(c, c + 3));
        return r;
    }
};
function Zh(s1) {
    let t = s1.length;
    t > 2 && s1[t - 1].equals(s1[0]) && s1.pop();
}
function Jh(s1, t) {
    for(let e = 0; e < t.length; e++)s1.push(t[e].x), s1.push(t[e].y);
}
var Zo = class s1 extends Vt {
    constructor(t = new Fn([
        new J(.5, .5),
        new J(-.5, .5),
        new J(-.5, -.5),
        new J(.5, -.5)
    ]), e = {}){
        super(), this.type = "ExtrudeGeometry", this.parameters = {
            shapes: t,
            options: e
        }, t = Array.isArray(t) ? t : [
            t
        ];
        let n = this, i = [], r = [];
        for(let o = 0, c = t.length; o < c; o++){
            let l = t[o];
            a(l);
        }
        this.setAttribute("position", new _t(i, 3)), this.setAttribute("uv", new _t(r, 2)), this.computeVertexNormals();
        function a(o) {
            let c = [], l = e.curveSegments !== void 0 ? e.curveSegments : 12, h = e.steps !== void 0 ? e.steps : 1, u = e.depth !== void 0 ? e.depth : 1, d = e.bevelEnabled !== void 0 ? e.bevelEnabled : !0, f = e.bevelThickness !== void 0 ? e.bevelThickness : .2, m = e.bevelSize !== void 0 ? e.bevelSize : f - .1, x = e.bevelOffset !== void 0 ? e.bevelOffset : 0, g = e.bevelSegments !== void 0 ? e.bevelSegments : 3, p = e.extrudePath, v = e.UVGenerator !== void 0 ? e.UVGenerator : mx, _, y = !1, b, w, R, L;
            p && (_ = p.getSpacedPoints(h), y = !0, d = !1, b = p.computeFrenetFrames(h, !1), w = new A, R = new A, L = new A), d || (g = 0, f = 0, m = 0, x = 0);
            let M = o.extractPoints(l), E = M.shape, V = M.holes;
            if (!yn.isClockWise(E)) {
                E = E.reverse();
                for(let P = 0, at = V.length; P < at; P++){
                    let Z = V[P];
                    yn.isClockWise(Z) && (V[P] = Z.reverse());
                }
            }
            let F = yn.triangulateShape(E, V), O = E;
            for(let P = 0, at = V.length; P < at; P++){
                let Z = V[P];
                E = E.concat(Z);
            }
            function z(P, at, Z) {
                return at || console.error("THREE.ExtrudeGeometry: vec does not exist"), P.clone().addScaledVector(at, Z);
            }
            let K = E.length, X = F.length;
            function Y(P, at, Z) {
                let st, Q, St, mt = P.x - at.x, xt = P.y - at.y, Dt = Z.x - P.x, Xt = Z.y - P.y, ie = mt * mt + xt * xt, C = mt * Xt - xt * Dt;
                if (Math.abs(C) > Number.EPSILON) {
                    let S = Math.sqrt(ie), B = Math.sqrt(Dt * Dt + Xt * Xt), nt = at.x - xt / S, et = at.y + mt / S, it = Z.x - Xt / B, Mt = Z.y + Dt / B, rt = ((it - nt) * Xt - (Mt - et) * Dt) / (mt * Xt - xt * Dt);
                    st = nt + mt * rt - P.x, Q = et + xt * rt - P.y;
                    let k = st * st + Q * Q;
                    if (k <= 2) return new J(st, Q);
                    St = Math.sqrt(k / 2);
                } else {
                    let S = !1;
                    mt > Number.EPSILON ? Dt > Number.EPSILON && (S = !0) : mt < -Number.EPSILON ? Dt < -Number.EPSILON && (S = !0) : Math.sign(xt) === Math.sign(Xt) && (S = !0), S ? (st = -xt, Q = mt, St = Math.sqrt(ie)) : (st = mt, Q = xt, St = Math.sqrt(ie / 2));
                }
                return new J(st / St, Q / St);
            }
            let j = [];
            for(let P = 0, at = O.length, Z = at - 1, st = P + 1; P < at; P++, Z++, st++)Z === at && (Z = 0), st === at && (st = 0), j[P] = Y(O[P], O[Z], O[st]);
            let tt = [], N, q = j.concat();
            for(let P = 0, at = V.length; P < at; P++){
                let Z = V[P];
                N = [];
                for(let st = 0, Q = Z.length, St = Q - 1, mt = st + 1; st < Q; st++, St++, mt++)St === Q && (St = 0), mt === Q && (mt = 0), N[st] = Y(Z[st], Z[St], Z[mt]);
                tt.push(N), q = q.concat(N);
            }
            for(let P = 0; P < g; P++){
                let at = P / g, Z = f * Math.cos(at * Math.PI / 2), st = m * Math.sin(at * Math.PI / 2) + x;
                for(let Q = 0, St = O.length; Q < St; Q++){
                    let mt = z(O[Q], j[Q], st);
                    Tt(mt.x, mt.y, -Z);
                }
                for(let Q = 0, St = V.length; Q < St; Q++){
                    let mt = V[Q];
                    N = tt[Q];
                    for(let xt = 0, Dt = mt.length; xt < Dt; xt++){
                        let Xt = z(mt[xt], N[xt], st);
                        Tt(Xt.x, Xt.y, -Z);
                    }
                }
            }
            let lt = m + x;
            for(let P = 0; P < K; P++){
                let at = d ? z(E[P], q[P], lt) : E[P];
                y ? (R.copy(b.normals[0]).multiplyScalar(at.x), w.copy(b.binormals[0]).multiplyScalar(at.y), L.copy(_[0]).add(R).add(w), Tt(L.x, L.y, L.z)) : Tt(at.x, at.y, 0);
            }
            for(let P = 1; P <= h; P++)for(let at = 0; at < K; at++){
                let Z = d ? z(E[at], q[at], lt) : E[at];
                y ? (R.copy(b.normals[P]).multiplyScalar(Z.x), w.copy(b.binormals[P]).multiplyScalar(Z.y), L.copy(_[P]).add(R).add(w), Tt(L.x, L.y, L.z)) : Tt(Z.x, Z.y, u / h * P);
            }
            for(let P = g - 1; P >= 0; P--){
                let at = P / g, Z = f * Math.cos(at * Math.PI / 2), st = m * Math.sin(at * Math.PI / 2) + x;
                for(let Q = 0, St = O.length; Q < St; Q++){
                    let mt = z(O[Q], j[Q], st);
                    Tt(mt.x, mt.y, u + Z);
                }
                for(let Q = 0, St = V.length; Q < St; Q++){
                    let mt = V[Q];
                    N = tt[Q];
                    for(let xt = 0, Dt = mt.length; xt < Dt; xt++){
                        let Xt = z(mt[xt], N[xt], st);
                        y ? Tt(Xt.x, Xt.y + _[h - 1].y, _[h - 1].x + Z) : Tt(Xt.x, Xt.y, u + Z);
                    }
                }
            }
            ut(), pt();
            function ut() {
                let P = i.length / 3;
                if (d) {
                    let at = 0, Z = K * at;
                    for(let st = 0; st < X; st++){
                        let Q = F[st];
                        wt(Q[2] + Z, Q[1] + Z, Q[0] + Z);
                    }
                    at = h + g * 2, Z = K * at;
                    for(let st = 0; st < X; st++){
                        let Q = F[st];
                        wt(Q[0] + Z, Q[1] + Z, Q[2] + Z);
                    }
                } else {
                    for(let at = 0; at < X; at++){
                        let Z = F[at];
                        wt(Z[2], Z[1], Z[0]);
                    }
                    for(let at = 0; at < X; at++){
                        let Z = F[at];
                        wt(Z[0] + K * h, Z[1] + K * h, Z[2] + K * h);
                    }
                }
                n.addGroup(P, i.length / 3 - P, 0);
            }
            function pt() {
                let P = i.length / 3, at = 0;
                Et(O, at), at += O.length;
                for(let Z = 0, st = V.length; Z < st; Z++){
                    let Q = V[Z];
                    Et(Q, at), at += Q.length;
                }
                n.addGroup(P, i.length / 3 - P, 1);
            }
            function Et(P, at) {
                let Z = P.length;
                for(; --Z >= 0;){
                    let st = Z, Q = Z - 1;
                    Q < 0 && (Q = P.length - 1);
                    for(let St = 0, mt = h + g * 2; St < mt; St++){
                        let xt = K * St, Dt = K * (St + 1), Xt = at + st + xt, ie = at + Q + xt, C = at + Q + Dt, S = at + st + Dt;
                        Yt(Xt, ie, C, S);
                    }
                }
            }
            function Tt(P, at, Z) {
                c.push(P), c.push(at), c.push(Z);
            }
            function wt(P, at, Z) {
                te(P), te(at), te(Z);
                let st = i.length / 3, Q = v.generateTopUV(n, i, st - 3, st - 2, st - 1);
                Pt(Q[0]), Pt(Q[1]), Pt(Q[2]);
            }
            function Yt(P, at, Z, st) {
                te(P), te(at), te(st), te(at), te(Z), te(st);
                let Q = i.length / 3, St = v.generateSideWallUV(n, i, Q - 6, Q - 3, Q - 2, Q - 1);
                Pt(St[0]), Pt(St[1]), Pt(St[3]), Pt(St[1]), Pt(St[2]), Pt(St[3]);
            }
            function te(P) {
                i.push(c[P * 3 + 0]), i.push(c[P * 3 + 1]), i.push(c[P * 3 + 2]);
            }
            function Pt(P) {
                r.push(P.x), r.push(P.y);
            }
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    toJSON() {
        let t = super.toJSON(), e = this.parameters.shapes, n = this.parameters.options;
        return gx(e, n, t);
    }
    static fromJSON(t, e) {
        let n = [];
        for(let r = 0, a = t.shapes.length; r < a; r++){
            let o = e[t.shapes[r]];
            n.push(o);
        }
        let i = t.options.extrudePath;
        return i !== void 0 && (t.options.extrudePath = new Gc[i.type]().fromJSON(i)), new s1(n, t.options);
    }
}, mx = {
    generateTopUV: function(s1, t, e, n, i) {
        let r = t[e * 3], a = t[e * 3 + 1], o = t[n * 3], c = t[n * 3 + 1], l = t[i * 3], h = t[i * 3 + 1];
        return [
            new J(r, a),
            new J(o, c),
            new J(l, h)
        ];
    },
    generateSideWallUV: function(s1, t, e, n, i, r) {
        let a = t[e * 3], o = t[e * 3 + 1], c = t[e * 3 + 2], l = t[n * 3], h = t[n * 3 + 1], u = t[n * 3 + 2], d = t[i * 3], f = t[i * 3 + 1], m = t[i * 3 + 2], x = t[r * 3], g = t[r * 3 + 1], p = t[r * 3 + 2];
        return Math.abs(o - h) < Math.abs(a - l) ? [
            new J(a, 1 - c),
            new J(l, 1 - u),
            new J(d, 1 - m),
            new J(x, 1 - p)
        ] : [
            new J(o, 1 - c),
            new J(h, 1 - u),
            new J(f, 1 - m),
            new J(g, 1 - p)
        ];
    }
};
function gx(s1, t, e) {
    if (e.shapes = [], Array.isArray(s1)) for(let n = 0, i = s1.length; n < i; n++){
        let r = s1[n];
        e.shapes.push(r.uuid);
    }
    else e.shapes.push(s1.uuid);
    return e.options = Object.assign({}, t), t.extrudePath !== void 0 && (e.options.extrudePath = t.extrudePath.toJSON()), e;
}
var Jo = class s1 extends di {
    constructor(t = 1, e = 0){
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
        super(i, r, t, e), this.type = "IcosahedronGeometry", this.parameters = {
            radius: t,
            detail: e
        };
    }
    static fromJSON(t) {
        return new s1(t.radius, t.detail);
    }
}, aa = class s1 extends di {
    constructor(t = 1, e = 0){
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
        super(n, i, t, e), this.type = "OctahedronGeometry", this.parameters = {
            radius: t,
            detail: e
        };
    }
    static fromJSON(t) {
        return new s1(t.radius, t.detail);
    }
}, $o = class s1 extends Vt {
    constructor(t = .5, e = 1, n = 32, i = 1, r = 0, a = Math.PI * 2){
        super(), this.type = "RingGeometry", this.parameters = {
            innerRadius: t,
            outerRadius: e,
            thetaSegments: n,
            phiSegments: i,
            thetaStart: r,
            thetaLength: a
        }, n = Math.max(3, n), i = Math.max(1, i);
        let o = [], c = [], l = [], h = [], u = t, d = (e - t) / i, f = new A, m = new J;
        for(let x = 0; x <= i; x++){
            for(let g = 0; g <= n; g++){
                let p = r + g / n * a;
                f.x = u * Math.cos(p), f.y = u * Math.sin(p), c.push(f.x, f.y, f.z), l.push(0, 0, 1), m.x = (f.x / e + 1) / 2, m.y = (f.y / e + 1) / 2, h.push(m.x, m.y);
            }
            u += d;
        }
        for(let x = 0; x < i; x++){
            let g = x * (n + 1);
            for(let p = 0; p < n; p++){
                let v = p + g, _ = v, y = v + n + 1, b = v + n + 2, w = v + 1;
                o.push(_, y, w), o.push(y, b, w);
            }
        }
        this.setIndex(o), this.setAttribute("position", new _t(c, 3)), this.setAttribute("normal", new _t(l, 3)), this.setAttribute("uv", new _t(h, 2));
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.innerRadius, t.outerRadius, t.thetaSegments, t.phiSegments, t.thetaStart, t.thetaLength);
    }
}, Ko = class s1 extends Vt {
    constructor(t = new Fn([
        new J(0, .5),
        new J(-.5, -.5),
        new J(.5, -.5)
    ]), e = 12){
        super(), this.type = "ShapeGeometry", this.parameters = {
            shapes: t,
            curveSegments: e
        };
        let n = [], i = [], r = [], a = [], o = 0, c = 0;
        if (Array.isArray(t) === !1) l(t);
        else for(let h = 0; h < t.length; h++)l(t[h]), this.addGroup(o, c, h), o += c, c = 0;
        this.setIndex(n), this.setAttribute("position", new _t(i, 3)), this.setAttribute("normal", new _t(r, 3)), this.setAttribute("uv", new _t(a, 2));
        function l(h) {
            let u = i.length / 3, d = h.extractPoints(e), f = d.shape, m = d.holes;
            yn.isClockWise(f) === !1 && (f = f.reverse());
            for(let g = 0, p = m.length; g < p; g++){
                let v = m[g];
                yn.isClockWise(v) === !0 && (m[g] = v.reverse());
            }
            let x = yn.triangulateShape(f, m);
            for(let g = 0, p = m.length; g < p; g++){
                let v = m[g];
                f = f.concat(v);
            }
            for(let g = 0, p = f.length; g < p; g++){
                let v = f[g];
                i.push(v.x, v.y, 0), r.push(0, 0, 1), a.push(v.x, v.y);
            }
            for(let g = 0, p = x.length; g < p; g++){
                let v = x[g], _ = v[0] + u, y = v[1] + u, b = v[2] + u;
                n.push(_, y, b), c += 3;
            }
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    toJSON() {
        let t = super.toJSON(), e = this.parameters.shapes;
        return _x(e, t);
    }
    static fromJSON(t, e) {
        let n = [];
        for(let i = 0, r = t.shapes.length; i < r; i++){
            let a = e[t.shapes[i]];
            n.push(a);
        }
        return new s1(n, t.curveSegments);
    }
};
function _x(s1, t) {
    if (t.shapes = [], Array.isArray(s1)) for(let e = 0, n = s1.length; e < n; e++){
        let i = s1[e];
        t.shapes.push(i.uuid);
    }
    else t.shapes.push(s1.uuid);
    return t;
}
var oa = class s1 extends Vt {
    constructor(t = 1, e = 32, n = 16, i = 0, r = Math.PI * 2, a = 0, o = Math.PI){
        super(), this.type = "SphereGeometry", this.parameters = {
            radius: t,
            widthSegments: e,
            heightSegments: n,
            phiStart: i,
            phiLength: r,
            thetaStart: a,
            thetaLength: o
        }, e = Math.max(3, Math.floor(e)), n = Math.max(2, Math.floor(n));
        let c = Math.min(a + o, Math.PI), l = 0, h = [], u = new A, d = new A, f = [], m = [], x = [], g = [];
        for(let p = 0; p <= n; p++){
            let v = [], _ = p / n, y = 0;
            p === 0 && a === 0 ? y = .5 / e : p === n && c === Math.PI && (y = -.5 / e);
            for(let b = 0; b <= e; b++){
                let w = b / e;
                u.x = -t * Math.cos(i + w * r) * Math.sin(a + _ * o), u.y = t * Math.cos(a + _ * o), u.z = t * Math.sin(i + w * r) * Math.sin(a + _ * o), m.push(u.x, u.y, u.z), d.copy(u).normalize(), x.push(d.x, d.y, d.z), g.push(w + y, 1 - _), v.push(l++);
            }
            h.push(v);
        }
        for(let p = 0; p < n; p++)for(let v = 0; v < e; v++){
            let _ = h[p][v + 1], y = h[p][v], b = h[p + 1][v], w = h[p + 1][v + 1];
            (p !== 0 || a > 0) && f.push(_, y, w), (p !== n - 1 || c < Math.PI) && f.push(y, b, w);
        }
        this.setIndex(f), this.setAttribute("position", new _t(m, 3)), this.setAttribute("normal", new _t(x, 3)), this.setAttribute("uv", new _t(g, 2));
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.radius, t.widthSegments, t.heightSegments, t.phiStart, t.phiLength, t.thetaStart, t.thetaLength);
    }
}, Qo = class s1 extends di {
    constructor(t = 1, e = 0){
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
        super(n, i, t, e), this.type = "TetrahedronGeometry", this.parameters = {
            radius: t,
            detail: e
        };
    }
    static fromJSON(t) {
        return new s1(t.radius, t.detail);
    }
}, jo = class s1 extends Vt {
    constructor(t = 1, e = .4, n = 12, i = 48, r = Math.PI * 2){
        super(), this.type = "TorusGeometry", this.parameters = {
            radius: t,
            tube: e,
            radialSegments: n,
            tubularSegments: i,
            arc: r
        }, n = Math.floor(n), i = Math.floor(i);
        let a = [], o = [], c = [], l = [], h = new A, u = new A, d = new A;
        for(let f = 0; f <= n; f++)for(let m = 0; m <= i; m++){
            let x = m / i * r, g = f / n * Math.PI * 2;
            u.x = (t + e * Math.cos(g)) * Math.cos(x), u.y = (t + e * Math.cos(g)) * Math.sin(x), u.z = e * Math.sin(g), o.push(u.x, u.y, u.z), h.x = t * Math.cos(x), h.y = t * Math.sin(x), d.subVectors(u, h).normalize(), c.push(d.x, d.y, d.z), l.push(m / i), l.push(f / n);
        }
        for(let f = 1; f <= n; f++)for(let m = 1; m <= i; m++){
            let x = (i + 1) * f + m - 1, g = (i + 1) * (f - 1) + m - 1, p = (i + 1) * (f - 1) + m, v = (i + 1) * f + m;
            a.push(x, g, v), a.push(g, p, v);
        }
        this.setIndex(a), this.setAttribute("position", new _t(o, 3)), this.setAttribute("normal", new _t(c, 3)), this.setAttribute("uv", new _t(l, 2));
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.radius, t.tube, t.radialSegments, t.tubularSegments, t.arc);
    }
}, tc = class s1 extends Vt {
    constructor(t = 1, e = .4, n = 64, i = 8, r = 2, a = 3){
        super(), this.type = "TorusKnotGeometry", this.parameters = {
            radius: t,
            tube: e,
            tubularSegments: n,
            radialSegments: i,
            p: r,
            q: a
        }, n = Math.floor(n), i = Math.floor(i);
        let o = [], c = [], l = [], h = [], u = new A, d = new A, f = new A, m = new A, x = new A, g = new A, p = new A;
        for(let _ = 0; _ <= n; ++_){
            let y = _ / n * r * Math.PI * 2;
            v(y, r, a, t, f), v(y + .01, r, a, t, m), g.subVectors(m, f), p.addVectors(m, f), x.crossVectors(g, p), p.crossVectors(x, g), x.normalize(), p.normalize();
            for(let b = 0; b <= i; ++b){
                let w = b / i * Math.PI * 2, R = -e * Math.cos(w), L = e * Math.sin(w);
                u.x = f.x + (R * p.x + L * x.x), u.y = f.y + (R * p.y + L * x.y), u.z = f.z + (R * p.z + L * x.z), c.push(u.x, u.y, u.z), d.subVectors(u, f).normalize(), l.push(d.x, d.y, d.z), h.push(_ / n), h.push(b / i);
            }
        }
        for(let _ = 1; _ <= n; _++)for(let y = 1; y <= i; y++){
            let b = (i + 1) * (_ - 1) + (y - 1), w = (i + 1) * _ + (y - 1), R = (i + 1) * _ + y, L = (i + 1) * (_ - 1) + y;
            o.push(b, w, L), o.push(w, R, L);
        }
        this.setIndex(o), this.setAttribute("position", new _t(c, 3)), this.setAttribute("normal", new _t(l, 3)), this.setAttribute("uv", new _t(h, 2));
        function v(_, y, b, w, R) {
            let L = Math.cos(_), M = Math.sin(_), E = b / y * _, V = Math.cos(E);
            R.x = w * (2 + V) * .5 * L, R.y = w * (2 + V) * M * .5, R.z = w * Math.sin(E) * .5;
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    static fromJSON(t) {
        return new s1(t.radius, t.tube, t.tubularSegments, t.radialSegments, t.p, t.q);
    }
}, ec = class s1 extends Vt {
    constructor(t = new ia(new A(-1, -1, 0), new A(-1, 1, 0), new A(1, 1, 0)), e = 64, n = 1, i = 8, r = !1){
        super(), this.type = "TubeGeometry", this.parameters = {
            path: t,
            tubularSegments: e,
            radius: n,
            radialSegments: i,
            closed: r
        };
        let a = t.computeFrenetFrames(e, r);
        this.tangents = a.tangents, this.normals = a.normals, this.binormals = a.binormals;
        let o = new A, c = new A, l = new J, h = new A, u = [], d = [], f = [], m = [];
        x(), this.setIndex(m), this.setAttribute("position", new _t(u, 3)), this.setAttribute("normal", new _t(d, 3)), this.setAttribute("uv", new _t(f, 2));
        function x() {
            for(let _ = 0; _ < e; _++)g(_);
            g(r === !1 ? e : 0), v(), p();
        }
        function g(_) {
            h = t.getPointAt(_ / e, h);
            let y = a.normals[_], b = a.binormals[_];
            for(let w = 0; w <= i; w++){
                let R = w / i * Math.PI * 2, L = Math.sin(R), M = -Math.cos(R);
                c.x = M * y.x + L * b.x, c.y = M * y.y + L * b.y, c.z = M * y.z + L * b.z, c.normalize(), d.push(c.x, c.y, c.z), o.x = h.x + n * c.x, o.y = h.y + n * c.y, o.z = h.z + n * c.z, u.push(o.x, o.y, o.z);
            }
        }
        function p() {
            for(let _ = 1; _ <= e; _++)for(let y = 1; y <= i; y++){
                let b = (i + 1) * (_ - 1) + (y - 1), w = (i + 1) * _ + (y - 1), R = (i + 1) * _ + y, L = (i + 1) * (_ - 1) + y;
                m.push(b, w, L), m.push(w, R, L);
            }
        }
        function v() {
            for(let _ = 0; _ <= e; _++)for(let y = 0; y <= i; y++)l.x = _ / e, l.y = y / i, f.push(l.x, l.y);
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.path = this.parameters.path.toJSON(), t;
    }
    static fromJSON(t) {
        return new s1(new Gc[t.path.type]().fromJSON(t.path), t.tubularSegments, t.radius, t.radialSegments, t.closed);
    }
}, nc = class extends Vt {
    constructor(t = null){
        if (super(), this.type = "WireframeGeometry", this.parameters = {
            geometry: t
        }, t !== null) {
            let e = [], n = new Set, i = new A, r = new A;
            if (t.index !== null) {
                let a = t.attributes.position, o = t.index, c = t.groups;
                c.length === 0 && (c = [
                    {
                        start: 0,
                        count: o.count,
                        materialIndex: 0
                    }
                ]);
                for(let l = 0, h = c.length; l < h; ++l){
                    let u = c[l], d = u.start, f = u.count;
                    for(let m = d, x = d + f; m < x; m += 3)for(let g = 0; g < 3; g++){
                        let p = o.getX(m + g), v = o.getX(m + (g + 1) % 3);
                        i.fromBufferAttribute(a, p), r.fromBufferAttribute(a, v), $h(i, r, n) === !0 && (e.push(i.x, i.y, i.z), e.push(r.x, r.y, r.z));
                    }
                }
            } else {
                let a = t.attributes.position;
                for(let o = 0, c = a.count / 3; o < c; o++)for(let l = 0; l < 3; l++){
                    let h = 3 * o + l, u = 3 * o + (l + 1) % 3;
                    i.fromBufferAttribute(a, h), r.fromBufferAttribute(a, u), $h(i, r, n) === !0 && (e.push(i.x, i.y, i.z), e.push(r.x, r.y, r.z));
                }
            }
            this.setAttribute("position", new _t(e, 3));
        }
    }
    copy(t) {
        return super.copy(t), this.parameters = Object.assign({}, t.parameters), this;
    }
};
function $h(s1, t, e) {
    let n = `${s1.x},${s1.y},${s1.z}-${t.x},${t.y},${t.z}`, i = `${t.x},${t.y},${t.z}-${s1.x},${s1.y},${s1.z}`;
    return e.has(n) === !0 || e.has(i) === !0 ? !1 : (e.add(n), e.add(i), !0);
}
var Kh = Object.freeze({
    __proto__: null,
    BoxGeometry: Ji,
    CapsuleGeometry: Vo,
    CircleGeometry: Ho,
    ConeGeometry: Go,
    CylinderGeometry: Fs,
    DodecahedronGeometry: Wo,
    EdgesGeometry: Xo,
    ExtrudeGeometry: Zo,
    IcosahedronGeometry: Jo,
    LatheGeometry: ra,
    OctahedronGeometry: aa,
    PlaneGeometry: Zr,
    PolyhedronGeometry: di,
    RingGeometry: $o,
    ShapeGeometry: Ko,
    SphereGeometry: oa,
    TetrahedronGeometry: Qo,
    TorusGeometry: jo,
    TorusKnotGeometry: tc,
    TubeGeometry: ec,
    WireframeGeometry: nc
}), ic = class extends Me {
    constructor(t){
        super(), this.isShadowMaterial = !0, this.type = "ShadowMaterial", this.color = new ft(0), this.transparent = !0, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.fog = t.fog, this;
    }
}, sc = class extends Qe {
    constructor(t){
        super(t), this.isRawShaderMaterial = !0, this.type = "RawShaderMaterial";
    }
}, ca = class extends Me {
    constructor(t){
        super(), this.isMeshStandardMaterial = !0, this.defines = {
            STANDARD: ""
        }, this.type = "MeshStandardMaterial", this.color = new ft(16777215), this.roughness = 1, this.metalness = 0, this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ft(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new J(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.roughnessMap = null, this.metalnessMap = null, this.alphaMap = null, this.envMap = null, this.envMapIntensity = 1, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.defines = {
            STANDARD: ""
        }, this.color.copy(t.color), this.roughness = t.roughness, this.metalness = t.metalness, this.map = t.map, this.lightMap = t.lightMap, this.lightMapIntensity = t.lightMapIntensity, this.aoMap = t.aoMap, this.aoMapIntensity = t.aoMapIntensity, this.emissive.copy(t.emissive), this.emissiveMap = t.emissiveMap, this.emissiveIntensity = t.emissiveIntensity, this.bumpMap = t.bumpMap, this.bumpScale = t.bumpScale, this.normalMap = t.normalMap, this.normalMapType = t.normalMapType, this.normalScale.copy(t.normalScale), this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.roughnessMap = t.roughnessMap, this.metalnessMap = t.metalnessMap, this.alphaMap = t.alphaMap, this.envMap = t.envMap, this.envMapIntensity = t.envMapIntensity, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.wireframeLinecap = t.wireframeLinecap, this.wireframeLinejoin = t.wireframeLinejoin, this.flatShading = t.flatShading, this.fog = t.fog, this;
    }
}, rc = class extends ca {
    constructor(t){
        super(), this.isMeshPhysicalMaterial = !0, this.defines = {
            STANDARD: "",
            PHYSICAL: ""
        }, this.type = "MeshPhysicalMaterial", this.anisotropyRotation = 0, this.anisotropyMap = null, this.clearcoatMap = null, this.clearcoatRoughness = 0, this.clearcoatRoughnessMap = null, this.clearcoatNormalScale = new J(1, 1), this.clearcoatNormalMap = null, this.ior = 1.5, Object.defineProperty(this, "reflectivity", {
            get: function() {
                return ae(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
            },
            set: function(e) {
                this.ior = (1 + .4 * e) / (1 - .4 * e);
            }
        }), this.iridescenceMap = null, this.iridescenceIOR = 1.3, this.iridescenceThicknessRange = [
            100,
            400
        ], this.iridescenceThicknessMap = null, this.sheenColor = new ft(0), this.sheenColorMap = null, this.sheenRoughness = 1, this.sheenRoughnessMap = null, this.transmissionMap = null, this.thickness = 0, this.thicknessMap = null, this.attenuationDistance = 1 / 0, this.attenuationColor = new ft(1, 1, 1), this.specularIntensity = 1, this.specularIntensityMap = null, this.specularColor = new ft(1, 1, 1), this.specularColorMap = null, this._anisotropy = 0, this._clearcoat = 0, this._iridescence = 0, this._sheen = 0, this._transmission = 0, this.setValues(t);
    }
    get anisotropy() {
        return this._anisotropy;
    }
    set anisotropy(t) {
        this._anisotropy > 0 != t > 0 && this.version++, this._anisotropy = t;
    }
    get clearcoat() {
        return this._clearcoat;
    }
    set clearcoat(t) {
        this._clearcoat > 0 != t > 0 && this.version++, this._clearcoat = t;
    }
    get iridescence() {
        return this._iridescence;
    }
    set iridescence(t) {
        this._iridescence > 0 != t > 0 && this.version++, this._iridescence = t;
    }
    get sheen() {
        return this._sheen;
    }
    set sheen(t) {
        this._sheen > 0 != t > 0 && this.version++, this._sheen = t;
    }
    get transmission() {
        return this._transmission;
    }
    set transmission(t) {
        this._transmission > 0 != t > 0 && this.version++, this._transmission = t;
    }
    copy(t) {
        return super.copy(t), this.defines = {
            STANDARD: "",
            PHYSICAL: ""
        }, this.anisotropy = t.anisotropy, this.anisotropyRotation = t.anisotropyRotation, this.anisotropyMap = t.anisotropyMap, this.clearcoat = t.clearcoat, this.clearcoatMap = t.clearcoatMap, this.clearcoatRoughness = t.clearcoatRoughness, this.clearcoatRoughnessMap = t.clearcoatRoughnessMap, this.clearcoatNormalMap = t.clearcoatNormalMap, this.clearcoatNormalScale.copy(t.clearcoatNormalScale), this.ior = t.ior, this.iridescence = t.iridescence, this.iridescenceMap = t.iridescenceMap, this.iridescenceIOR = t.iridescenceIOR, this.iridescenceThicknessRange = [
            ...t.iridescenceThicknessRange
        ], this.iridescenceThicknessMap = t.iridescenceThicknessMap, this.sheen = t.sheen, this.sheenColor.copy(t.sheenColor), this.sheenColorMap = t.sheenColorMap, this.sheenRoughness = t.sheenRoughness, this.sheenRoughnessMap = t.sheenRoughnessMap, this.transmission = t.transmission, this.transmissionMap = t.transmissionMap, this.thickness = t.thickness, this.thicknessMap = t.thicknessMap, this.attenuationDistance = t.attenuationDistance, this.attenuationColor.copy(t.attenuationColor), this.specularIntensity = t.specularIntensity, this.specularIntensityMap = t.specularIntensityMap, this.specularColor.copy(t.specularColor), this.specularColorMap = t.specularColorMap, this;
    }
}, ac = class extends Me {
    constructor(t){
        super(), this.isMeshPhongMaterial = !0, this.type = "MeshPhongMaterial", this.color = new ft(16777215), this.specular = new ft(1118481), this.shininess = 30, this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ft(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new J(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = pa, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.specular.copy(t.specular), this.shininess = t.shininess, this.map = t.map, this.lightMap = t.lightMap, this.lightMapIntensity = t.lightMapIntensity, this.aoMap = t.aoMap, this.aoMapIntensity = t.aoMapIntensity, this.emissive.copy(t.emissive), this.emissiveMap = t.emissiveMap, this.emissiveIntensity = t.emissiveIntensity, this.bumpMap = t.bumpMap, this.bumpScale = t.bumpScale, this.normalMap = t.normalMap, this.normalMapType = t.normalMapType, this.normalScale.copy(t.normalScale), this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.specularMap = t.specularMap, this.alphaMap = t.alphaMap, this.envMap = t.envMap, this.combine = t.combine, this.reflectivity = t.reflectivity, this.refractionRatio = t.refractionRatio, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.wireframeLinecap = t.wireframeLinecap, this.wireframeLinejoin = t.wireframeLinejoin, this.flatShading = t.flatShading, this.fog = t.fog, this;
    }
}, oc = class extends Me {
    constructor(t){
        super(), this.isMeshToonMaterial = !0, this.defines = {
            TOON: ""
        }, this.type = "MeshToonMaterial", this.color = new ft(16777215), this.map = null, this.gradientMap = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ft(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new J(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.alphaMap = null, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.map = t.map, this.gradientMap = t.gradientMap, this.lightMap = t.lightMap, this.lightMapIntensity = t.lightMapIntensity, this.aoMap = t.aoMap, this.aoMapIntensity = t.aoMapIntensity, this.emissive.copy(t.emissive), this.emissiveMap = t.emissiveMap, this.emissiveIntensity = t.emissiveIntensity, this.bumpMap = t.bumpMap, this.bumpScale = t.bumpScale, this.normalMap = t.normalMap, this.normalMapType = t.normalMapType, this.normalScale.copy(t.normalScale), this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.alphaMap = t.alphaMap, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.wireframeLinecap = t.wireframeLinecap, this.wireframeLinejoin = t.wireframeLinejoin, this.fog = t.fog, this;
    }
}, cc = class extends Me {
    constructor(t){
        super(), this.isMeshNormalMaterial = !0, this.type = "MeshNormalMaterial", this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new J(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.wireframe = !1, this.wireframeLinewidth = 1, this.flatShading = !1, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.bumpMap = t.bumpMap, this.bumpScale = t.bumpScale, this.normalMap = t.normalMap, this.normalMapType = t.normalMapType, this.normalScale.copy(t.normalScale), this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.flatShading = t.flatShading, this;
    }
}, lc = class extends Me {
    constructor(t){
        super(), this.isMeshLambertMaterial = !0, this.type = "MeshLambertMaterial", this.color = new ft(16777215), this.map = null, this.lightMap = null, this.lightMapIntensity = 1, this.aoMap = null, this.aoMapIntensity = 1, this.emissive = new ft(0), this.emissiveIntensity = 1, this.emissiveMap = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new J(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.specularMap = null, this.alphaMap = null, this.envMap = null, this.combine = pa, this.reflectivity = 1, this.refractionRatio = .98, this.wireframe = !1, this.wireframeLinewidth = 1, this.wireframeLinecap = "round", this.wireframeLinejoin = "round", this.flatShading = !1, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.color.copy(t.color), this.map = t.map, this.lightMap = t.lightMap, this.lightMapIntensity = t.lightMapIntensity, this.aoMap = t.aoMap, this.aoMapIntensity = t.aoMapIntensity, this.emissive.copy(t.emissive), this.emissiveMap = t.emissiveMap, this.emissiveIntensity = t.emissiveIntensity, this.bumpMap = t.bumpMap, this.bumpScale = t.bumpScale, this.normalMap = t.normalMap, this.normalMapType = t.normalMapType, this.normalScale.copy(t.normalScale), this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.specularMap = t.specularMap, this.alphaMap = t.alphaMap, this.envMap = t.envMap, this.combine = t.combine, this.reflectivity = t.reflectivity, this.refractionRatio = t.refractionRatio, this.wireframe = t.wireframe, this.wireframeLinewidth = t.wireframeLinewidth, this.wireframeLinecap = t.wireframeLinecap, this.wireframeLinejoin = t.wireframeLinejoin, this.flatShading = t.flatShading, this.fog = t.fog, this;
    }
}, hc = class extends Me {
    constructor(t){
        super(), this.isMeshMatcapMaterial = !0, this.defines = {
            MATCAP: ""
        }, this.type = "MeshMatcapMaterial", this.color = new ft(16777215), this.matcap = null, this.map = null, this.bumpMap = null, this.bumpScale = 1, this.normalMap = null, this.normalMapType = mi, this.normalScale = new J(1, 1), this.displacementMap = null, this.displacementScale = 1, this.displacementBias = 0, this.alphaMap = null, this.flatShading = !1, this.fog = !0, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.defines = {
            MATCAP: ""
        }, this.color.copy(t.color), this.matcap = t.matcap, this.map = t.map, this.bumpMap = t.bumpMap, this.bumpScale = t.bumpScale, this.normalMap = t.normalMap, this.normalMapType = t.normalMapType, this.normalScale.copy(t.normalScale), this.displacementMap = t.displacementMap, this.displacementScale = t.displacementScale, this.displacementBias = t.displacementBias, this.alphaMap = t.alphaMap, this.flatShading = t.flatShading, this.fog = t.fog, this;
    }
}, uc = class extends Ee {
    constructor(t){
        super(), this.isLineDashedMaterial = !0, this.type = "LineDashedMaterial", this.scale = 1, this.dashSize = 3, this.gapSize = 1, this.setValues(t);
    }
    copy(t) {
        return super.copy(t), this.scale = t.scale, this.dashSize = t.dashSize, this.gapSize = t.gapSize, this;
    }
};
function Ve(s1, t, e) {
    return Wc(s1) ? new s1.constructor(s1.subarray(t, e !== void 0 ? e : s1.length)) : s1.slice(t, e);
}
function ei(s1, t, e) {
    return !s1 || !e && s1.constructor === t ? s1 : typeof t.BYTES_PER_ELEMENT == "number" ? new t(s1) : Array.prototype.slice.call(s1);
}
function Wc(s1) {
    return ArrayBuffer.isView(s1) && !(s1 instanceof DataView);
}
function Rd(s1) {
    function t(i, r) {
        return s1[i] - s1[r];
    }
    let e = s1.length, n = new Array(e);
    for(let i = 0; i !== e; ++i)n[i] = i;
    return n.sort(t), n;
}
function dc(s1, t, e) {
    let n = s1.length, i = new s1.constructor(n);
    for(let r = 0, a = 0; a !== n; ++r){
        let o = e[r] * t;
        for(let c = 0; c !== t; ++c)i[a++] = s1[o + c];
    }
    return i;
}
function Xc(s1, t, e, n) {
    let i = 1, r = s1[0];
    for(; r !== void 0 && r[n] === void 0;)r = s1[i++];
    if (r === void 0) return;
    let a = r[n];
    if (a !== void 0) if (Array.isArray(a)) do a = r[n], a !== void 0 && (t.push(r.time), e.push.apply(e, a)), r = s1[i++];
    while (r !== void 0)
    else if (a.toArray !== void 0) do a = r[n], a !== void 0 && (t.push(r.time), a.toArray(e, e.length)), r = s1[i++];
    while (r !== void 0)
    else do a = r[n], a !== void 0 && (t.push(r.time), e.push(a)), r = s1[i++];
    while (r !== void 0)
}
function xx(s1, t, e, n, i = 30) {
    let r = s1.clone();
    r.name = t;
    let a = [];
    for(let c = 0; c < r.tracks.length; ++c){
        let l = r.tracks[c], h = l.getValueSize(), u = [], d = [];
        for(let f = 0; f < l.times.length; ++f){
            let m = l.times[f] * i;
            if (!(m < e || m >= n)) {
                u.push(l.times[f]);
                for(let x = 0; x < h; ++x)d.push(l.values[f * h + x]);
            }
        }
        u.length !== 0 && (l.times = ei(u, l.times.constructor), l.values = ei(d, l.values.constructor), a.push(l));
    }
    r.tracks = a;
    let o = 1 / 0;
    for(let c = 0; c < r.tracks.length; ++c)o > r.tracks[c].times[0] && (o = r.tracks[c].times[0]);
    for(let c = 0; c < r.tracks.length; ++c)r.tracks[c].shift(-1 * o);
    return r.resetDuration(), r;
}
function vx(s1, t = 0, e = s1, n = 30) {
    n <= 0 && (n = 30);
    let i = e.tracks.length, r = t / n;
    for(let a = 0; a < i; ++a){
        let o = e.tracks[a], c = o.ValueTypeName;
        if (c === "bool" || c === "string") continue;
        let l = s1.tracks.find(function(p) {
            return p.name === o.name && p.ValueTypeName === c;
        });
        if (l === void 0) continue;
        let h = 0, u = o.getValueSize();
        o.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline && (h = u / 3);
        let d = 0, f = l.getValueSize();
        l.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline && (d = f / 3);
        let m = o.times.length - 1, x;
        if (r <= o.times[0]) {
            let p = h, v = u - h;
            x = Ve(o.values, p, v);
        } else if (r >= o.times[m]) {
            let p = m * u + h, v = p + u - h;
            x = Ve(o.values, p, v);
        } else {
            let p = o.createInterpolant(), v = h, _ = u - h;
            p.evaluate(r), x = Ve(p.resultBuffer, v, _);
        }
        c === "quaternion" && new Pe().fromArray(x).normalize().conjugate().toArray(x);
        let g = l.times.length;
        for(let p = 0; p < g; ++p){
            let v = p * f + d;
            if (c === "quaternion") Pe.multiplyQuaternionsFlat(l.values, v, x, 0, l.values, v);
            else {
                let _ = f - d * 2;
                for(let y = 0; y < _; ++y)l.values[v + y] -= x[y];
            }
        }
    }
    return s1.blendMode = dd, s1;
}
var yv = {
    arraySlice: Ve,
    convertArray: ei,
    isTypedArray: Wc,
    getKeyframeOrder: Rd,
    sortedArray: dc,
    flattenJSON: Xc,
    subclip: xx,
    makeClipAdditive: vx
}, ts = class {
    constructor(t, e, n, i){
        this.parameterPositions = t, this._cachedIndex = 0, this.resultBuffer = i !== void 0 ? i : new e.constructor(n), this.sampleValues = e, this.valueSize = n, this.settings = null, this.DefaultSettings_ = {};
    }
    evaluate(t) {
        let e = this.parameterPositions, n = this._cachedIndex, i = e[n], r = e[n - 1];
        t: {
            e: {
                let a;
                n: {
                    i: if (!(t < i)) {
                        for(let o = n + 2;;){
                            if (i === void 0) {
                                if (t < r) break i;
                                return n = e.length, this._cachedIndex = n, this.copySampleValue_(n - 1);
                            }
                            if (n === o) break;
                            if (r = i, i = e[++n], t < i) break e;
                        }
                        a = e.length;
                        break n;
                    }
                    if (!(t >= r)) {
                        let o = e[1];
                        t < o && (n = 2, r = o);
                        for(let c = n - 2;;){
                            if (r === void 0) return this._cachedIndex = 0, this.copySampleValue_(0);
                            if (n === c) break;
                            if (i = r, r = e[--n - 1], t >= r) break e;
                        }
                        a = n, n = 0;
                        break n;
                    }
                    break t;
                }
                for(; n < a;){
                    let o = n + a >>> 1;
                    t < e[o] ? a = o : n = o + 1;
                }
                if (i = e[n], r = e[n - 1], r === void 0) return this._cachedIndex = 0, this.copySampleValue_(0);
                if (i === void 0) return n = e.length, this._cachedIndex = n, this.copySampleValue_(n - 1);
            }
            this._cachedIndex = n, this.intervalChanged_(n, r, i);
        }
        return this.interpolate_(n, r, t, i);
    }
    getSettings_() {
        return this.settings || this.DefaultSettings_;
    }
    copySampleValue_(t) {
        let e = this.resultBuffer, n = this.sampleValues, i = this.valueSize, r = t * i;
        for(let a = 0; a !== i; ++a)e[a] = n[r + a];
        return e;
    }
    interpolate_() {
        throw new Error("call to abstract method");
    }
    intervalChanged_() {}
}, fc = class extends ts {
    constructor(t, e, n, i){
        super(t, e, n, i), this._weightPrev = -0, this._offsetPrev = -0, this._weightNext = -0, this._offsetNext = -0, this.DefaultSettings_ = {
            endingStart: zi,
            endingEnd: zi
        };
    }
    intervalChanged_(t, e, n) {
        let i = this.parameterPositions, r = t - 2, a = t + 1, o = i[r], c = i[a];
        if (o === void 0) switch(this.getSettings_().endingStart){
            case ki:
                r = t, o = 2 * e - n;
                break;
            case zr:
                r = i.length - 2, o = e + i[r] - i[r + 1];
                break;
            default:
                r = t, o = n;
        }
        if (c === void 0) switch(this.getSettings_().endingEnd){
            case ki:
                a = t, c = 2 * n - e;
                break;
            case zr:
                a = 1, c = n + i[1] - i[0];
                break;
            default:
                a = t - 1, c = e;
        }
        let l = (n - e) * .5, h = this.valueSize;
        this._weightPrev = l / (e - o), this._weightNext = l / (c - n), this._offsetPrev = r * h, this._offsetNext = a * h;
    }
    interpolate_(t, e, n, i) {
        let r = this.resultBuffer, a = this.sampleValues, o = this.valueSize, c = t * o, l = c - o, h = this._offsetPrev, u = this._offsetNext, d = this._weightPrev, f = this._weightNext, m = (n - e) / (i - e), x = m * m, g = x * m, p = -d * g + 2 * d * x - d * m, v = (1 + d) * g + (-1.5 - 2 * d) * x + (-.5 + d) * m + 1, _ = (-1 - f) * g + (1.5 + f) * x + .5 * m, y = f * g - f * x;
        for(let b = 0; b !== o; ++b)r[b] = p * a[h + b] + v * a[l + b] + _ * a[c + b] + y * a[u + b];
        return r;
    }
}, la = class extends ts {
    constructor(t, e, n, i){
        super(t, e, n, i);
    }
    interpolate_(t, e, n, i) {
        let r = this.resultBuffer, a = this.sampleValues, o = this.valueSize, c = t * o, l = c - o, h = (n - e) / (i - e), u = 1 - h;
        for(let d = 0; d !== o; ++d)r[d] = a[l + d] * u + a[c + d] * h;
        return r;
    }
}, pc = class extends ts {
    constructor(t, e, n, i){
        super(t, e, n, i);
    }
    interpolate_(t) {
        return this.copySampleValue_(t - 1);
    }
}, qe = class {
    constructor(t, e, n, i){
        if (t === void 0) throw new Error("THREE.KeyframeTrack: track name is undefined");
        if (e === void 0 || e.length === 0) throw new Error("THREE.KeyframeTrack: no keyframes in track named " + t);
        this.name = t, this.times = ei(e, this.TimeBufferType), this.values = ei(n, this.ValueBufferType), this.setInterpolation(i || this.DefaultInterpolation);
    }
    static toJSON(t) {
        let e = t.constructor, n;
        if (e.toJSON !== this.toJSON) n = e.toJSON(t);
        else {
            n = {
                name: t.name,
                times: ei(t.times, Array),
                values: ei(t.values, Array)
            };
            let i = t.getInterpolation();
            i !== t.DefaultInterpolation && (n.interpolation = i);
        }
        return n.type = t.ValueTypeName, n;
    }
    InterpolantFactoryMethodDiscrete(t) {
        return new pc(this.times, this.values, this.getValueSize(), t);
    }
    InterpolantFactoryMethodLinear(t) {
        return new la(this.times, this.values, this.getValueSize(), t);
    }
    InterpolantFactoryMethodSmooth(t) {
        return new fc(this.times, this.values, this.getValueSize(), t);
    }
    setInterpolation(t) {
        let e;
        switch(t){
            case Or:
                e = this.InterpolantFactoryMethodDiscrete;
                break;
            case Br:
                e = this.InterpolantFactoryMethodLinear;
                break;
            case wa:
                e = this.InterpolantFactoryMethodSmooth;
                break;
        }
        if (e === void 0) {
            let n = "unsupported interpolation for " + this.ValueTypeName + " keyframe track named " + this.name;
            if (this.createInterpolant === void 0) if (t !== this.DefaultInterpolation) this.setInterpolation(this.DefaultInterpolation);
            else throw new Error(n);
            return console.warn("THREE.KeyframeTrack:", n), this;
        }
        return this.createInterpolant = e, this;
    }
    getInterpolation() {
        switch(this.createInterpolant){
            case this.InterpolantFactoryMethodDiscrete:
                return Or;
            case this.InterpolantFactoryMethodLinear:
                return Br;
            case this.InterpolantFactoryMethodSmooth:
                return wa;
        }
    }
    getValueSize() {
        return this.values.length / this.times.length;
    }
    shift(t) {
        if (t !== 0) {
            let e = this.times;
            for(let n = 0, i = e.length; n !== i; ++n)e[n] += t;
        }
        return this;
    }
    scale(t) {
        if (t !== 1) {
            let e = this.times;
            for(let n = 0, i = e.length; n !== i; ++n)e[n] *= t;
        }
        return this;
    }
    trim(t, e) {
        let n = this.times, i = n.length, r = 0, a = i - 1;
        for(; r !== i && n[r] < t;)++r;
        for(; a !== -1 && n[a] > e;)--a;
        if (++a, r !== 0 || a !== i) {
            r >= a && (a = Math.max(a, 1), r = a - 1);
            let o = this.getValueSize();
            this.times = Ve(n, r, a), this.values = Ve(this.values, r * o, a * o);
        }
        return this;
    }
    validate() {
        let t = !0, e = this.getValueSize();
        e - Math.floor(e) !== 0 && (console.error("THREE.KeyframeTrack: Invalid value size in track.", this), t = !1);
        let n = this.times, i = this.values, r = n.length;
        r === 0 && (console.error("THREE.KeyframeTrack: Track is empty.", this), t = !1);
        let a = null;
        for(let o = 0; o !== r; o++){
            let c = n[o];
            if (typeof c == "number" && isNaN(c)) {
                console.error("THREE.KeyframeTrack: Time is not a valid number.", this, o, c), t = !1;
                break;
            }
            if (a !== null && a > c) {
                console.error("THREE.KeyframeTrack: Out of order keys.", this, o, c, a), t = !1;
                break;
            }
            a = c;
        }
        if (i !== void 0 && Wc(i)) for(let o = 0, c = i.length; o !== c; ++o){
            let l = i[o];
            if (isNaN(l)) {
                console.error("THREE.KeyframeTrack: Value is not a valid number.", this, o, l), t = !1;
                break;
            }
        }
        return t;
    }
    optimize() {
        let t = Ve(this.times), e = Ve(this.values), n = this.getValueSize(), i = this.getInterpolation() === wa, r = t.length - 1, a = 1;
        for(let o = 1; o < r; ++o){
            let c = !1, l = t[o], h = t[o + 1];
            if (l !== h && (o !== 1 || l !== t[0])) if (i) c = !0;
            else {
                let u = o * n, d = u - n, f = u + n;
                for(let m = 0; m !== n; ++m){
                    let x = e[u + m];
                    if (x !== e[d + m] || x !== e[f + m]) {
                        c = !0;
                        break;
                    }
                }
            }
            if (c) {
                if (o !== a) {
                    t[a] = t[o];
                    let u = o * n, d = a * n;
                    for(let f = 0; f !== n; ++f)e[d + f] = e[u + f];
                }
                ++a;
            }
        }
        if (r > 0) {
            t[a] = t[r];
            for(let o = r * n, c = a * n, l = 0; l !== n; ++l)e[c + l] = e[o + l];
            ++a;
        }
        return a !== t.length ? (this.times = Ve(t, 0, a), this.values = Ve(e, 0, a * n)) : (this.times = t, this.values = e), this;
    }
    clone() {
        let t = Ve(this.times, 0), e = Ve(this.values, 0), n = this.constructor, i = new n(this.name, t, e);
        return i.createInterpolant = this.createInterpolant, i;
    }
};
qe.prototype.TimeBufferType = Float32Array;
qe.prototype.ValueBufferType = Float32Array;
qe.prototype.DefaultInterpolation = Br;
var zn = class extends qe {
};
zn.prototype.ValueTypeName = "bool";
zn.prototype.ValueBufferType = Array;
zn.prototype.DefaultInterpolation = Or;
zn.prototype.InterpolantFactoryMethodLinear = void 0;
zn.prototype.InterpolantFactoryMethodSmooth = void 0;
var ha = class extends qe {
};
ha.prototype.ValueTypeName = "color";
var es = class extends qe {
};
es.prototype.ValueTypeName = "number";
var mc = class extends ts {
    constructor(t, e, n, i){
        super(t, e, n, i);
    }
    interpolate_(t, e, n, i) {
        let r = this.resultBuffer, a = this.sampleValues, o = this.valueSize, c = (n - e) / (i - e), l = t * o;
        for(let h = l + o; l !== h; l += 4)Pe.slerpFlat(r, 0, a, l - o, a, l, c);
        return r;
    }
}, pi = class extends qe {
    InterpolantFactoryMethodLinear(t) {
        return new mc(this.times, this.values, this.getValueSize(), t);
    }
};
pi.prototype.ValueTypeName = "quaternion";
pi.prototype.DefaultInterpolation = Br;
pi.prototype.InterpolantFactoryMethodSmooth = void 0;
var kn = class extends qe {
};
kn.prototype.ValueTypeName = "string";
kn.prototype.ValueBufferType = Array;
kn.prototype.DefaultInterpolation = Or;
kn.prototype.InterpolantFactoryMethodLinear = void 0;
kn.prototype.InterpolantFactoryMethodSmooth = void 0;
var ns = class extends qe {
};
ns.prototype.ValueTypeName = "vector";
var is = class {
    constructor(t, e = -1, n, i = zc){
        this.name = t, this.tracks = n, this.duration = e, this.blendMode = i, this.uuid = Be(), this.duration < 0 && this.resetDuration();
    }
    static parse(t) {
        let e = [], n = t.tracks, i = 1 / (t.fps || 1);
        for(let a = 0, o = n.length; a !== o; ++a)e.push(Mx(n[a]).scale(i));
        let r = new this(t.name, t.duration, e, t.blendMode);
        return r.uuid = t.uuid, r;
    }
    static toJSON(t) {
        let e = [], n = t.tracks, i = {
            name: t.name,
            duration: t.duration,
            tracks: e,
            uuid: t.uuid,
            blendMode: t.blendMode
        };
        for(let r = 0, a = n.length; r !== a; ++r)e.push(qe.toJSON(n[r]));
        return i;
    }
    static CreateFromMorphTargetSequence(t, e, n, i) {
        let r = e.length, a = [];
        for(let o = 0; o < r; o++){
            let c = [], l = [];
            c.push((o + r - 1) % r, o, (o + 1) % r), l.push(0, 1, 0);
            let h = Rd(c);
            c = dc(c, 1, h), l = dc(l, 1, h), !i && c[0] === 0 && (c.push(r), l.push(l[0])), a.push(new es(".morphTargetInfluences[" + e[o].name + "]", c, l).scale(1 / n));
        }
        return new this(t, -1, a);
    }
    static findByName(t, e) {
        let n = t;
        if (!Array.isArray(t)) {
            let i = t;
            n = i.geometry && i.geometry.animations || i.animations;
        }
        for(let i = 0; i < n.length; i++)if (n[i].name === e) return n[i];
        return null;
    }
    static CreateClipsFromMorphTargetSequences(t, e, n) {
        let i = {}, r = /^([\w-]*?)([\d]+)$/;
        for(let o = 0, c = t.length; o < c; o++){
            let l = t[o], h = l.name.match(r);
            if (h && h.length > 1) {
                let u = h[1], d = i[u];
                d || (i[u] = d = []), d.push(l);
            }
        }
        let a = [];
        for(let o in i)a.push(this.CreateFromMorphTargetSequence(o, i[o], e, n));
        return a;
    }
    static parseAnimation(t, e) {
        if (!t) return console.error("THREE.AnimationClip: No animation in JSONLoader data."), null;
        let n = function(u, d, f, m, x) {
            if (f.length !== 0) {
                let g = [], p = [];
                Xc(f, g, p, m), g.length !== 0 && x.push(new u(d, g, p));
            }
        }, i = [], r = t.name || "default", a = t.fps || 30, o = t.blendMode, c = t.length || -1, l = t.hierarchy || [];
        for(let u = 0; u < l.length; u++){
            let d = l[u].keys;
            if (!(!d || d.length === 0)) if (d[0].morphTargets) {
                let f = {}, m;
                for(m = 0; m < d.length; m++)if (d[m].morphTargets) for(let x = 0; x < d[m].morphTargets.length; x++)f[d[m].morphTargets[x]] = -1;
                for(let x in f){
                    let g = [], p = [];
                    for(let v = 0; v !== d[m].morphTargets.length; ++v){
                        let _ = d[m];
                        g.push(_.time), p.push(_.morphTarget === x ? 1 : 0);
                    }
                    i.push(new es(".morphTargetInfluence[" + x + "]", g, p));
                }
                c = f.length * a;
            } else {
                let f = ".bones[" + e[u].name + "]";
                n(ns, f + ".position", d, "pos", i), n(pi, f + ".quaternion", d, "rot", i), n(ns, f + ".scale", d, "scl", i);
            }
        }
        return i.length === 0 ? null : new this(r, c, i, o);
    }
    resetDuration() {
        let t = this.tracks, e = 0;
        for(let n = 0, i = t.length; n !== i; ++n){
            let r = this.tracks[n];
            e = Math.max(e, r.times[r.times.length - 1]);
        }
        return this.duration = e, this;
    }
    trim() {
        for(let t = 0; t < this.tracks.length; t++)this.tracks[t].trim(0, this.duration);
        return this;
    }
    validate() {
        let t = !0;
        for(let e = 0; e < this.tracks.length; e++)t = t && this.tracks[e].validate();
        return t;
    }
    optimize() {
        for(let t = 0; t < this.tracks.length; t++)this.tracks[t].optimize();
        return this;
    }
    clone() {
        let t = [];
        for(let e = 0; e < this.tracks.length; e++)t.push(this.tracks[e].clone());
        return new this.constructor(this.name, this.duration, t, this.blendMode);
    }
    toJSON() {
        return this.constructor.toJSON(this);
    }
};
function yx(s1) {
    switch(s1.toLowerCase()){
        case "scalar":
        case "double":
        case "float":
        case "number":
        case "integer":
            return es;
        case "vector":
        case "vector2":
        case "vector3":
        case "vector4":
            return ns;
        case "color":
            return ha;
        case "quaternion":
            return pi;
        case "bool":
        case "boolean":
            return zn;
        case "string":
            return kn;
    }
    throw new Error("THREE.KeyframeTrack: Unsupported typeName: " + s1);
}
function Mx(s1) {
    if (s1.type === void 0) throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");
    let t = yx(s1.type);
    if (s1.times === void 0) {
        let e = [], n = [];
        Xc(s1.keys, e, n, "value"), s1.times = e, s1.values = n;
    }
    return t.parse !== void 0 ? t.parse(s1) : new t(s1.name, s1.times, s1.values, s1.interpolation);
}
var ss = {
    enabled: !1,
    files: {},
    add: function(s1, t) {
        this.enabled !== !1 && (this.files[s1] = t);
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
}, ua = class {
    constructor(t, e, n){
        let i = this, r = !1, a = 0, o = 0, c, l = [];
        this.onStart = void 0, this.onLoad = t, this.onProgress = e, this.onError = n, this.itemStart = function(h) {
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
}, Sx = new ua, Le = class {
    constructor(t){
        this.manager = t !== void 0 ? t : Sx, this.crossOrigin = "anonymous", this.withCredentials = !1, this.path = "", this.resourcePath = "", this.requestHeader = {};
    }
    load() {}
    loadAsync(t, e) {
        let n = this;
        return new Promise(function(i, r) {
            n.load(t, i, e, r);
        });
    }
    parse() {}
    setCrossOrigin(t) {
        return this.crossOrigin = t, this;
    }
    setWithCredentials(t) {
        return this.withCredentials = t, this;
    }
    setPath(t) {
        return this.path = t, this;
    }
    setResourcePath(t) {
        return this.resourcePath = t, this;
    }
    setRequestHeader(t) {
        return this.requestHeader = t, this;
    }
};
Le.DEFAULT_MATERIAL_NAME = "__DEFAULT";
var fn = {}, gc = class extends Error {
    constructor(t, e){
        super(t), this.response = e;
    }
}, rn = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        t === void 0 && (t = ""), this.path !== void 0 && (t = this.path + t), t = this.manager.resolveURL(t);
        let r = ss.get(t);
        if (r !== void 0) return this.manager.itemStart(t), setTimeout(()=>{
            e && e(r), this.manager.itemEnd(t);
        }, 0), r;
        if (fn[t] !== void 0) {
            fn[t].push({
                onLoad: e,
                onProgress: n,
                onError: i
            });
            return;
        }
        fn[t] = [], fn[t].push({
            onLoad: e,
            onProgress: n,
            onError: i
        });
        let a = new Request(t, {
            headers: new Headers(this.requestHeader),
            credentials: this.withCredentials ? "include" : "same-origin"
        }), o = this.mimeType, c = this.responseType;
        fetch(a).then((l)=>{
            if (l.status === 200 || l.status === 0) {
                if (l.status === 0 && console.warn("THREE.FileLoader: HTTP Status 0 received."), typeof ReadableStream > "u" || l.body === void 0 || l.body.getReader === void 0) return l;
                let h = fn[t], u = l.body.getReader(), d = l.headers.get("Content-Length") || l.headers.get("X-File-Size"), f = d ? parseInt(d) : 0, m = f !== 0, x = 0, g = new ReadableStream({
                    start (p) {
                        v();
                        function v() {
                            u.read().then(({ done: _ , value: y  })=>{
                                if (_) p.close();
                                else {
                                    x += y.byteLength;
                                    let b = new ProgressEvent("progress", {
                                        lengthComputable: m,
                                        loaded: x,
                                        total: f
                                    });
                                    for(let w = 0, R = h.length; w < R; w++){
                                        let L = h[w];
                                        L.onProgress && L.onProgress(b);
                                    }
                                    p.enqueue(y), v();
                                }
                            });
                        }
                    }
                });
                return new Response(g);
            } else throw new gc(`fetch for "${l.url}" responded with ${l.status}: ${l.statusText}`, l);
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
            ss.add(t, l);
            let h = fn[t];
            delete fn[t];
            for(let u = 0, d = h.length; u < d; u++){
                let f = h[u];
                f.onLoad && f.onLoad(l);
            }
        }).catch((l)=>{
            let h = fn[t];
            if (h === void 0) throw this.manager.itemError(t), l;
            delete fn[t];
            for(let u = 0, d = h.length; u < d; u++){
                let f = h[u];
                f.onError && f.onError(l);
            }
            this.manager.itemError(t);
        }).finally(()=>{
            this.manager.itemEnd(t);
        }), this.manager.itemStart(t);
    }
    setResponseType(t) {
        return this.responseType = t, this;
    }
    setMimeType(t) {
        return this.mimeType = t, this;
    }
}, Qh = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = this, a = new rn(this.manager);
        a.setPath(this.path), a.setRequestHeader(this.requestHeader), a.setWithCredentials(this.withCredentials), a.load(t, function(o) {
            try {
                e(r.parse(JSON.parse(o)));
            } catch (c) {
                i ? i(c) : console.error(c), r.manager.itemError(t);
            }
        }, n, i);
    }
    parse(t) {
        let e = [];
        for(let n = 0; n < t.length; n++){
            let i = is.parse(t[n]);
            e.push(i);
        }
        return e;
    }
}, jh = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = this, a = [], o = new Us, c = new rn(this.manager);
        c.setPath(this.path), c.setResponseType("arraybuffer"), c.setRequestHeader(this.requestHeader), c.setWithCredentials(r.withCredentials);
        let l = 0;
        function h(u) {
            c.load(t[u], function(d) {
                let f = r.parse(d, !0);
                a[u] = {
                    width: f.width,
                    height: f.height,
                    format: f.format,
                    mipmaps: f.mipmaps
                }, l += 1, l === 6 && (f.mipmapCount === 1 && (o.minFilter = pe), o.image = a, o.format = f.format, o.needsUpdate = !0, e && e(o));
            }, n, i);
        }
        if (Array.isArray(t)) for(let u = 0, d = t.length; u < d; ++u)h(u);
        else c.load(t, function(u) {
            let d = r.parse(u, !0);
            if (d.isCubemap) {
                let f = d.mipmaps.length / d.mipmapCount;
                for(let m = 0; m < f; m++){
                    a[m] = {
                        mipmaps: []
                    };
                    for(let x = 0; x < d.mipmapCount; x++)a[m].mipmaps.push(d.mipmaps[m * d.mipmapCount + x]), a[m].format = d.format, a[m].width = d.width, a[m].height = d.height;
                }
                o.image = a;
            } else o.image.width = d.width, o.image.height = d.height, o.mipmaps = d.mipmaps;
            d.mipmapCount === 1 && (o.minFilter = pe), o.format = d.format, o.needsUpdate = !0, e && e(o);
        }, n, i);
        return o;
    }
}, rs = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        this.path !== void 0 && (t = this.path + t), t = this.manager.resolveURL(t);
        let r = this, a = ss.get(t);
        if (a !== void 0) return r.manager.itemStart(t), setTimeout(function() {
            e && e(a), r.manager.itemEnd(t);
        }, 0), a;
        let o = ws("img");
        function c() {
            h(), ss.add(t, this), e && e(this), r.manager.itemEnd(t);
        }
        function l(u) {
            h(), i && i(u), r.manager.itemError(t), r.manager.itemEnd(t);
        }
        function h() {
            o.removeEventListener("load", c, !1), o.removeEventListener("error", l, !1);
        }
        return o.addEventListener("load", c, !1), o.addEventListener("error", l, !1), t.slice(0, 5) !== "data:" && this.crossOrigin !== void 0 && (o.crossOrigin = this.crossOrigin), r.manager.itemStart(t), o.src = t, o;
    }
}, tu = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = new Ki;
        r.colorSpace = Nt;
        let a = new rs(this.manager);
        a.setCrossOrigin(this.crossOrigin), a.setPath(this.path);
        let o = 0;
        function c(l) {
            a.load(t[l], function(h) {
                r.images[l] = h, o++, o === 6 && (r.needsUpdate = !0, e && e(r));
            }, void 0, i);
        }
        for(let l = 0; l < t.length; ++l)c(l);
        return r;
    }
}, eu = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = this, a = new oi, o = new rn(this.manager);
        return o.setResponseType("arraybuffer"), o.setRequestHeader(this.requestHeader), o.setPath(this.path), o.setWithCredentials(r.withCredentials), o.load(t, function(c) {
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
            if (!l) return i();
            l.image !== void 0 ? a.image = l.image : l.data !== void 0 && (a.image.width = l.width, a.image.height = l.height, a.image.data = l.data), a.wrapS = l.wrapS !== void 0 ? l.wrapS : Ce, a.wrapT = l.wrapT !== void 0 ? l.wrapT : Ce, a.magFilter = l.magFilter !== void 0 ? l.magFilter : pe, a.minFilter = l.minFilter !== void 0 ? l.minFilter : pe, a.anisotropy = l.anisotropy !== void 0 ? l.anisotropy : 1, l.colorSpace !== void 0 ? a.colorSpace = l.colorSpace : l.encoding !== void 0 && (a.encoding = l.encoding), l.flipY !== void 0 && (a.flipY = l.flipY), l.format !== void 0 && (a.format = l.format), l.type !== void 0 && (a.type = l.type), l.mipmaps !== void 0 && (a.mipmaps = l.mipmaps, a.minFilter = li), l.mipmapCount === 1 && (a.minFilter = pe), l.generateMipmaps !== void 0 && (a.generateMipmaps = l.generateMipmaps), a.needsUpdate = !0, e && e(a, l);
        }, n, i), a;
    }
}, nu = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = new ye, a = new rs(this.manager);
        return a.setCrossOrigin(this.crossOrigin), a.setPath(this.path), a.load(t, function(o) {
            r.image = o, r.needsUpdate = !0, e !== void 0 && e(r);
        }, n, i), r;
    }
}, bn = class extends Zt {
    constructor(t, e = 1){
        super(), this.isLight = !0, this.type = "Light", this.color = new ft(t), this.intensity = e;
    }
    dispose() {}
    copy(t, e) {
        return super.copy(t, e), this.color.copy(t.color), this.intensity = t.intensity, this;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return e.object.color = this.color.getHex(), e.object.intensity = this.intensity, this.groundColor !== void 0 && (e.object.groundColor = this.groundColor.getHex()), this.distance !== void 0 && (e.object.distance = this.distance), this.angle !== void 0 && (e.object.angle = this.angle), this.decay !== void 0 && (e.object.decay = this.decay), this.penumbra !== void 0 && (e.object.penumbra = this.penumbra), this.shadow !== void 0 && (e.object.shadow = this.shadow.toJSON()), e;
    }
}, _c = class extends bn {
    constructor(t, e, n){
        super(t, n), this.isHemisphereLight = !0, this.type = "HemisphereLight", this.position.copy(Zt.DEFAULT_UP), this.updateMatrix(), this.groundColor = new ft(e);
    }
    copy(t, e) {
        return super.copy(t, e), this.groundColor.copy(t.groundColor), this;
    }
}, no = new Ot, iu = new A, su = new A, ks = class {
    constructor(t){
        this.camera = t, this.bias = 0, this.normalBias = 0, this.radius = 1, this.blurSamples = 8, this.mapSize = new J(512, 512), this.map = null, this.mapPass = null, this.matrix = new Ot, this.autoUpdate = !0, this.needsUpdate = !1, this._frustum = new Ps, this._frameExtents = new J(1, 1), this._viewportCount = 1, this._viewports = [
            new $t(0, 0, 1, 1)
        ];
    }
    getViewportCount() {
        return this._viewportCount;
    }
    getFrustum() {
        return this._frustum;
    }
    updateMatrices(t) {
        let e = this.camera, n = this.matrix;
        iu.setFromMatrixPosition(t.matrixWorld), e.position.copy(iu), su.setFromMatrixPosition(t.target.matrixWorld), e.lookAt(su), e.updateMatrixWorld(), no.multiplyMatrices(e.projectionMatrix, e.matrixWorldInverse), this._frustum.setFromProjectionMatrix(no), n.set(.5, 0, 0, .5, 0, .5, 0, .5, 0, 0, .5, .5, 0, 0, 0, 1), n.multiply(no);
    }
    getViewport(t) {
        return this._viewports[t];
    }
    getFrameExtents() {
        return this._frameExtents;
    }
    dispose() {
        this.map && this.map.dispose(), this.mapPass && this.mapPass.dispose();
    }
    copy(t) {
        return this.camera = t.camera.clone(), this.bias = t.bias, this.radius = t.radius, this.mapSize.copy(t.mapSize), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    toJSON() {
        let t = {};
        return this.bias !== 0 && (t.bias = this.bias), this.normalBias !== 0 && (t.normalBias = this.normalBias), this.radius !== 1 && (t.radius = this.radius), (this.mapSize.x !== 512 || this.mapSize.y !== 512) && (t.mapSize = this.mapSize.toArray()), t.camera = this.camera.toJSON(!1).object, delete t.camera.matrix, t;
    }
}, xc = class extends ks {
    constructor(){
        super(new xe(50, 1, .5, 500)), this.isSpotLightShadow = !0, this.focus = 1;
    }
    updateMatrices(t) {
        let e = this.camera, n = Zi * 2 * t.angle * this.focus, i = this.mapSize.width / this.mapSize.height, r = t.distance || e.far;
        (n !== e.fov || i !== e.aspect || r !== e.far) && (e.fov = n, e.aspect = i, e.far = r, e.updateProjectionMatrix()), super.updateMatrices(t);
    }
    copy(t) {
        return super.copy(t), this.focus = t.focus, this;
    }
}, vc = class extends bn {
    constructor(t, e, n = 0, i = Math.PI / 3, r = 0, a = 2){
        super(t, e), this.isSpotLight = !0, this.type = "SpotLight", this.position.copy(Zt.DEFAULT_UP), this.updateMatrix(), this.target = new Zt, this.distance = n, this.angle = i, this.penumbra = r, this.decay = a, this.map = null, this.shadow = new xc;
    }
    get power() {
        return this.intensity * Math.PI;
    }
    set power(t) {
        this.intensity = t / Math.PI;
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(t, e) {
        return super.copy(t, e), this.distance = t.distance, this.angle = t.angle, this.penumbra = t.penumbra, this.decay = t.decay, this.target = t.target.clone(), this.shadow = t.shadow.clone(), this;
    }
}, ru = new Ot, _s = new A, io = new A, yc = class extends ks {
    constructor(){
        super(new xe(90, 1, .5, 500)), this.isPointLightShadow = !0, this._frameExtents = new J(4, 2), this._viewportCount = 6, this._viewports = [
            new $t(2, 1, 1, 1),
            new $t(0, 1, 1, 1),
            new $t(3, 1, 1, 1),
            new $t(1, 1, 1, 1),
            new $t(3, 0, 1, 1),
            new $t(1, 0, 1, 1)
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
    updateMatrices(t, e = 0) {
        let n = this.camera, i = this.matrix, r = t.distance || n.far;
        r !== n.far && (n.far = r, n.updateProjectionMatrix()), _s.setFromMatrixPosition(t.matrixWorld), n.position.copy(_s), io.copy(n.position), io.add(this._cubeDirections[e]), n.up.copy(this._cubeUps[e]), n.lookAt(io), n.updateMatrixWorld(), i.makeTranslation(-_s.x, -_s.y, -_s.z), ru.multiplyMatrices(n.projectionMatrix, n.matrixWorldInverse), this._frustum.setFromProjectionMatrix(ru);
    }
}, Mc = class extends bn {
    constructor(t, e, n = 0, i = 2){
        super(t, e), this.isPointLight = !0, this.type = "PointLight", this.distance = n, this.decay = i, this.shadow = new yc;
    }
    get power() {
        return this.intensity * 4 * Math.PI;
    }
    set power(t) {
        this.intensity = t / (4 * Math.PI);
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(t, e) {
        return super.copy(t, e), this.distance = t.distance, this.decay = t.decay, this.shadow = t.shadow.clone(), this;
    }
}, Sc = class extends ks {
    constructor(){
        super(new Ls(-5, 5, 5, -5, .5, 500)), this.isDirectionalLightShadow = !0;
    }
}, bc = class extends bn {
    constructor(t, e){
        super(t, e), this.isDirectionalLight = !0, this.type = "DirectionalLight", this.position.copy(Zt.DEFAULT_UP), this.updateMatrix(), this.target = new Zt, this.shadow = new Sc;
    }
    dispose() {
        this.shadow.dispose();
    }
    copy(t) {
        return super.copy(t), this.target = t.target.clone(), this.shadow = t.shadow.clone(), this;
    }
}, Ec = class extends bn {
    constructor(t, e){
        super(t, e), this.isAmbientLight = !0, this.type = "AmbientLight";
    }
}, Tc = class extends bn {
    constructor(t, e, n = 10, i = 10){
        super(t, e), this.isRectAreaLight = !0, this.type = "RectAreaLight", this.width = n, this.height = i;
    }
    get power() {
        return this.intensity * this.width * this.height * Math.PI;
    }
    set power(t) {
        this.intensity = t / (this.width * this.height * Math.PI);
    }
    copy(t) {
        return super.copy(t), this.width = t.width, this.height = t.height, this;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return e.object.width = this.width, e.object.height = this.height, e;
    }
}, wc = class {
    constructor(){
        this.isSphericalHarmonics3 = !0, this.coefficients = [];
        for(let t = 0; t < 9; t++)this.coefficients.push(new A);
    }
    set(t) {
        for(let e = 0; e < 9; e++)this.coefficients[e].copy(t[e]);
        return this;
    }
    zero() {
        for(let t = 0; t < 9; t++)this.coefficients[t].set(0, 0, 0);
        return this;
    }
    getAt(t, e) {
        let n = t.x, i = t.y, r = t.z, a = this.coefficients;
        return e.copy(a[0]).multiplyScalar(.282095), e.addScaledVector(a[1], .488603 * i), e.addScaledVector(a[2], .488603 * r), e.addScaledVector(a[3], .488603 * n), e.addScaledVector(a[4], 1.092548 * (n * i)), e.addScaledVector(a[5], 1.092548 * (i * r)), e.addScaledVector(a[6], .315392 * (3 * r * r - 1)), e.addScaledVector(a[7], 1.092548 * (n * r)), e.addScaledVector(a[8], .546274 * (n * n - i * i)), e;
    }
    getIrradianceAt(t, e) {
        let n = t.x, i = t.y, r = t.z, a = this.coefficients;
        return e.copy(a[0]).multiplyScalar(.886227), e.addScaledVector(a[1], 2 * .511664 * i), e.addScaledVector(a[2], 2 * .511664 * r), e.addScaledVector(a[3], 2 * .511664 * n), e.addScaledVector(a[4], 2 * .429043 * n * i), e.addScaledVector(a[5], 2 * .429043 * i * r), e.addScaledVector(a[6], .743125 * r * r - .247708), e.addScaledVector(a[7], 2 * .429043 * n * r), e.addScaledVector(a[8], .429043 * (n * n - i * i)), e;
    }
    add(t) {
        for(let e = 0; e < 9; e++)this.coefficients[e].add(t.coefficients[e]);
        return this;
    }
    addScaledSH(t, e) {
        for(let n = 0; n < 9; n++)this.coefficients[n].addScaledVector(t.coefficients[n], e);
        return this;
    }
    scale(t) {
        for(let e = 0; e < 9; e++)this.coefficients[e].multiplyScalar(t);
        return this;
    }
    lerp(t, e) {
        for(let n = 0; n < 9; n++)this.coefficients[n].lerp(t.coefficients[n], e);
        return this;
    }
    equals(t) {
        for(let e = 0; e < 9; e++)if (!this.coefficients[e].equals(t.coefficients[e])) return !1;
        return !0;
    }
    copy(t) {
        return this.set(t.coefficients);
    }
    clone() {
        return new this.constructor().copy(this);
    }
    fromArray(t, e = 0) {
        let n = this.coefficients;
        for(let i = 0; i < 9; i++)n[i].fromArray(t, e + i * 3);
        return this;
    }
    toArray(t = [], e = 0) {
        let n = this.coefficients;
        for(let i = 0; i < 9; i++)n[i].toArray(t, e + i * 3);
        return t;
    }
    static getBasisAt(t, e) {
        let n = t.x, i = t.y, r = t.z;
        e[0] = .282095, e[1] = .488603 * i, e[2] = .488603 * r, e[3] = .488603 * n, e[4] = 1.092548 * n * i, e[5] = 1.092548 * i * r, e[6] = .315392 * (3 * r * r - 1), e[7] = 1.092548 * n * r, e[8] = .546274 * (n * n - i * i);
    }
}, Vs = class extends bn {
    constructor(t = new wc, e = 1){
        super(void 0, e), this.isLightProbe = !0, this.sh = t;
    }
    copy(t) {
        return super.copy(t), this.sh.copy(t.sh), this;
    }
    fromJSON(t) {
        return this.intensity = t.intensity, this.sh.fromArray(t.sh), this;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return e.object.sh = this.sh.toArray(), e;
    }
}, Ac = class s1 extends Le {
    constructor(t){
        super(t), this.textures = {};
    }
    load(t, e, n, i) {
        let r = this, a = new rn(r.manager);
        a.setPath(r.path), a.setRequestHeader(r.requestHeader), a.setWithCredentials(r.withCredentials), a.load(t, function(o) {
            try {
                e(r.parse(JSON.parse(o)));
            } catch (c) {
                i ? i(c) : console.error(c), r.manager.itemError(t);
            }
        }, n, i);
    }
    parse(t) {
        let e = this.textures;
        function n(r) {
            return e[r] === void 0 && console.warn("THREE.MaterialLoader: Undefined texture", r), e[r];
        }
        let i = s1.createMaterialFromType(t.type);
        if (t.uuid !== void 0 && (i.uuid = t.uuid), t.name !== void 0 && (i.name = t.name), t.color !== void 0 && i.color !== void 0 && i.color.setHex(t.color), t.roughness !== void 0 && (i.roughness = t.roughness), t.metalness !== void 0 && (i.metalness = t.metalness), t.sheen !== void 0 && (i.sheen = t.sheen), t.sheenColor !== void 0 && (i.sheenColor = new ft().setHex(t.sheenColor)), t.sheenRoughness !== void 0 && (i.sheenRoughness = t.sheenRoughness), t.emissive !== void 0 && i.emissive !== void 0 && i.emissive.setHex(t.emissive), t.specular !== void 0 && i.specular !== void 0 && i.specular.setHex(t.specular), t.specularIntensity !== void 0 && (i.specularIntensity = t.specularIntensity), t.specularColor !== void 0 && i.specularColor !== void 0 && i.specularColor.setHex(t.specularColor), t.shininess !== void 0 && (i.shininess = t.shininess), t.clearcoat !== void 0 && (i.clearcoat = t.clearcoat), t.clearcoatRoughness !== void 0 && (i.clearcoatRoughness = t.clearcoatRoughness), t.iridescence !== void 0 && (i.iridescence = t.iridescence), t.iridescenceIOR !== void 0 && (i.iridescenceIOR = t.iridescenceIOR), t.iridescenceThicknessRange !== void 0 && (i.iridescenceThicknessRange = t.iridescenceThicknessRange), t.transmission !== void 0 && (i.transmission = t.transmission), t.thickness !== void 0 && (i.thickness = t.thickness), t.attenuationDistance !== void 0 && (i.attenuationDistance = t.attenuationDistance), t.attenuationColor !== void 0 && i.attenuationColor !== void 0 && i.attenuationColor.setHex(t.attenuationColor), t.anisotropy !== void 0 && (i.anisotropy = t.anisotropy), t.anisotropyRotation !== void 0 && (i.anisotropyRotation = t.anisotropyRotation), t.fog !== void 0 && (i.fog = t.fog), t.flatShading !== void 0 && (i.flatShading = t.flatShading), t.blending !== void 0 && (i.blending = t.blending), t.combine !== void 0 && (i.combine = t.combine), t.side !== void 0 && (i.side = t.side), t.shadowSide !== void 0 && (i.shadowSide = t.shadowSide), t.opacity !== void 0 && (i.opacity = t.opacity), t.transparent !== void 0 && (i.transparent = t.transparent), t.alphaTest !== void 0 && (i.alphaTest = t.alphaTest), t.alphaHash !== void 0 && (i.alphaHash = t.alphaHash), t.depthTest !== void 0 && (i.depthTest = t.depthTest), t.depthWrite !== void 0 && (i.depthWrite = t.depthWrite), t.colorWrite !== void 0 && (i.colorWrite = t.colorWrite), t.stencilWrite !== void 0 && (i.stencilWrite = t.stencilWrite), t.stencilWriteMask !== void 0 && (i.stencilWriteMask = t.stencilWriteMask), t.stencilFunc !== void 0 && (i.stencilFunc = t.stencilFunc), t.stencilRef !== void 0 && (i.stencilRef = t.stencilRef), t.stencilFuncMask !== void 0 && (i.stencilFuncMask = t.stencilFuncMask), t.stencilFail !== void 0 && (i.stencilFail = t.stencilFail), t.stencilZFail !== void 0 && (i.stencilZFail = t.stencilZFail), t.stencilZPass !== void 0 && (i.stencilZPass = t.stencilZPass), t.wireframe !== void 0 && (i.wireframe = t.wireframe), t.wireframeLinewidth !== void 0 && (i.wireframeLinewidth = t.wireframeLinewidth), t.wireframeLinecap !== void 0 && (i.wireframeLinecap = t.wireframeLinecap), t.wireframeLinejoin !== void 0 && (i.wireframeLinejoin = t.wireframeLinejoin), t.rotation !== void 0 && (i.rotation = t.rotation), t.linewidth !== 1 && (i.linewidth = t.linewidth), t.dashSize !== void 0 && (i.dashSize = t.dashSize), t.gapSize !== void 0 && (i.gapSize = t.gapSize), t.scale !== void 0 && (i.scale = t.scale), t.polygonOffset !== void 0 && (i.polygonOffset = t.polygonOffset), t.polygonOffsetFactor !== void 0 && (i.polygonOffsetFactor = t.polygonOffsetFactor), t.polygonOffsetUnits !== void 0 && (i.polygonOffsetUnits = t.polygonOffsetUnits), t.dithering !== void 0 && (i.dithering = t.dithering), t.alphaToCoverage !== void 0 && (i.alphaToCoverage = t.alphaToCoverage), t.premultipliedAlpha !== void 0 && (i.premultipliedAlpha = t.premultipliedAlpha), t.forceSinglePass !== void 0 && (i.forceSinglePass = t.forceSinglePass), t.visible !== void 0 && (i.visible = t.visible), t.toneMapped !== void 0 && (i.toneMapped = t.toneMapped), t.userData !== void 0 && (i.userData = t.userData), t.vertexColors !== void 0 && (typeof t.vertexColors == "number" ? i.vertexColors = t.vertexColors > 0 : i.vertexColors = t.vertexColors), t.uniforms !== void 0) for(let r in t.uniforms){
            let a = t.uniforms[r];
            switch(i.uniforms[r] = {}, a.type){
                case "t":
                    i.uniforms[r].value = n(a.value);
                    break;
                case "c":
                    i.uniforms[r].value = new ft().setHex(a.value);
                    break;
                case "v2":
                    i.uniforms[r].value = new J().fromArray(a.value);
                    break;
                case "v3":
                    i.uniforms[r].value = new A().fromArray(a.value);
                    break;
                case "v4":
                    i.uniforms[r].value = new $t().fromArray(a.value);
                    break;
                case "m3":
                    i.uniforms[r].value = new kt().fromArray(a.value);
                    break;
                case "m4":
                    i.uniforms[r].value = new Ot().fromArray(a.value);
                    break;
                default:
                    i.uniforms[r].value = a.value;
            }
        }
        if (t.defines !== void 0 && (i.defines = t.defines), t.vertexShader !== void 0 && (i.vertexShader = t.vertexShader), t.fragmentShader !== void 0 && (i.fragmentShader = t.fragmentShader), t.glslVersion !== void 0 && (i.glslVersion = t.glslVersion), t.extensions !== void 0) for(let r in t.extensions)i.extensions[r] = t.extensions[r];
        if (t.lights !== void 0 && (i.lights = t.lights), t.clipping !== void 0 && (i.clipping = t.clipping), t.size !== void 0 && (i.size = t.size), t.sizeAttenuation !== void 0 && (i.sizeAttenuation = t.sizeAttenuation), t.map !== void 0 && (i.map = n(t.map)), t.matcap !== void 0 && (i.matcap = n(t.matcap)), t.alphaMap !== void 0 && (i.alphaMap = n(t.alphaMap)), t.bumpMap !== void 0 && (i.bumpMap = n(t.bumpMap)), t.bumpScale !== void 0 && (i.bumpScale = t.bumpScale), t.normalMap !== void 0 && (i.normalMap = n(t.normalMap)), t.normalMapType !== void 0 && (i.normalMapType = t.normalMapType), t.normalScale !== void 0) {
            let r = t.normalScale;
            Array.isArray(r) === !1 && (r = [
                r,
                r
            ]), i.normalScale = new J().fromArray(r);
        }
        return t.displacementMap !== void 0 && (i.displacementMap = n(t.displacementMap)), t.displacementScale !== void 0 && (i.displacementScale = t.displacementScale), t.displacementBias !== void 0 && (i.displacementBias = t.displacementBias), t.roughnessMap !== void 0 && (i.roughnessMap = n(t.roughnessMap)), t.metalnessMap !== void 0 && (i.metalnessMap = n(t.metalnessMap)), t.emissiveMap !== void 0 && (i.emissiveMap = n(t.emissiveMap)), t.emissiveIntensity !== void 0 && (i.emissiveIntensity = t.emissiveIntensity), t.specularMap !== void 0 && (i.specularMap = n(t.specularMap)), t.specularIntensityMap !== void 0 && (i.specularIntensityMap = n(t.specularIntensityMap)), t.specularColorMap !== void 0 && (i.specularColorMap = n(t.specularColorMap)), t.envMap !== void 0 && (i.envMap = n(t.envMap)), t.envMapIntensity !== void 0 && (i.envMapIntensity = t.envMapIntensity), t.reflectivity !== void 0 && (i.reflectivity = t.reflectivity), t.refractionRatio !== void 0 && (i.refractionRatio = t.refractionRatio), t.lightMap !== void 0 && (i.lightMap = n(t.lightMap)), t.lightMapIntensity !== void 0 && (i.lightMapIntensity = t.lightMapIntensity), t.aoMap !== void 0 && (i.aoMap = n(t.aoMap)), t.aoMapIntensity !== void 0 && (i.aoMapIntensity = t.aoMapIntensity), t.gradientMap !== void 0 && (i.gradientMap = n(t.gradientMap)), t.clearcoatMap !== void 0 && (i.clearcoatMap = n(t.clearcoatMap)), t.clearcoatRoughnessMap !== void 0 && (i.clearcoatRoughnessMap = n(t.clearcoatRoughnessMap)), t.clearcoatNormalMap !== void 0 && (i.clearcoatNormalMap = n(t.clearcoatNormalMap)), t.clearcoatNormalScale !== void 0 && (i.clearcoatNormalScale = new J().fromArray(t.clearcoatNormalScale)), t.iridescenceMap !== void 0 && (i.iridescenceMap = n(t.iridescenceMap)), t.iridescenceThicknessMap !== void 0 && (i.iridescenceThicknessMap = n(t.iridescenceThicknessMap)), t.transmissionMap !== void 0 && (i.transmissionMap = n(t.transmissionMap)), t.thicknessMap !== void 0 && (i.thicknessMap = n(t.thicknessMap)), t.anisotropyMap !== void 0 && (i.anisotropyMap = n(t.anisotropyMap)), t.sheenColorMap !== void 0 && (i.sheenColorMap = n(t.sheenColorMap)), t.sheenRoughnessMap !== void 0 && (i.sheenRoughnessMap = n(t.sheenRoughnessMap)), i;
    }
    setTextures(t) {
        return this.textures = t, this;
    }
    static createMaterialFromType(t) {
        let e = {
            ShadowMaterial: ic,
            SpriteMaterial: Qr,
            RawShaderMaterial: sc,
            ShaderMaterial: Qe,
            PointsMaterial: ta,
            MeshPhysicalMaterial: rc,
            MeshStandardMaterial: ca,
            MeshPhongMaterial: ac,
            MeshToonMaterial: oc,
            MeshNormalMaterial: cc,
            MeshLambertMaterial: lc,
            MeshDepthMaterial: $r,
            MeshDistanceMaterial: Kr,
            MeshBasicMaterial: Mn,
            MeshMatcapMaterial: hc,
            LineDashedMaterial: uc,
            LineBasicMaterial: Ee,
            Material: Me
        };
        return new e[t];
    }
}, da = class {
    static decodeText(t) {
        if (typeof TextDecoder < "u") return new TextDecoder().decode(t);
        let e = "";
        for(let n = 0, i = t.length; n < i; n++)e += String.fromCharCode(t[n]);
        try {
            return decodeURIComponent(escape(e));
        } catch  {
            return e;
        }
    }
    static extractUrlBase(t) {
        let e = t.lastIndexOf("/");
        return e === -1 ? "./" : t.slice(0, e + 1);
    }
    static resolveURL(t, e) {
        return typeof t != "string" || t === "" ? "" : (/^https?:\/\//i.test(e) && /^\//.test(t) && (e = e.replace(/(^https?:\/\/[^\/]+).*/i, "$1")), /^(https?:)?\/\//i.test(t) || /^data:.*,.*$/i.test(t) || /^blob:.*$/i.test(t) ? t : e + t);
    }
}, Rc = class extends Vt {
    constructor(){
        super(), this.isInstancedBufferGeometry = !0, this.type = "InstancedBufferGeometry", this.instanceCount = 1 / 0;
    }
    copy(t) {
        return super.copy(t), this.instanceCount = t.instanceCount, this;
    }
    toJSON() {
        let t = super.toJSON();
        return t.instanceCount = this.instanceCount, t.isInstancedBufferGeometry = !0, t;
    }
}, Cc = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = this, a = new rn(r.manager);
        a.setPath(r.path), a.setRequestHeader(r.requestHeader), a.setWithCredentials(r.withCredentials), a.load(t, function(o) {
            try {
                e(r.parse(JSON.parse(o)));
            } catch (c) {
                i ? i(c) : console.error(c), r.manager.itemError(t);
            }
        }, n, i);
    }
    parse(t) {
        let e = {}, n = {};
        function i(f, m) {
            if (e[m] !== void 0) return e[m];
            let g = f.interleavedBuffers[m], p = r(f, g.buffer), v = Vi(g.type, p), _ = new Is(v, g.stride);
            return _.uuid = g.uuid, e[m] = _, _;
        }
        function r(f, m) {
            if (n[m] !== void 0) return n[m];
            let g = f.arrayBuffers[m], p = new Uint32Array(g).buffer;
            return n[m] = p, p;
        }
        let a = t.isInstancedBufferGeometry ? new Rc : new Vt, o = t.data.index;
        if (o !== void 0) {
            let f = Vi(o.type, o.array);
            a.setIndex(new Kt(f, 1));
        }
        let c = t.data.attributes;
        for(let f in c){
            let m = c[f], x;
            if (m.isInterleavedBufferAttribute) {
                let g = i(t.data, m.data);
                x = new Qi(g, m.itemSize, m.offset, m.normalized);
            } else {
                let g = Vi(m.type, m.array), p = m.isInstancedBufferAttribute ? ui : Kt;
                x = new p(g, m.itemSize, m.normalized);
            }
            m.name !== void 0 && (x.name = m.name), m.usage !== void 0 && x.setUsage(m.usage), m.updateRange !== void 0 && (x.updateRange.offset = m.updateRange.offset, x.updateRange.count = m.updateRange.count), a.setAttribute(f, x);
        }
        let l = t.data.morphAttributes;
        if (l) for(let f in l){
            let m = l[f], x = [];
            for(let g = 0, p = m.length; g < p; g++){
                let v = m[g], _;
                if (v.isInterleavedBufferAttribute) {
                    let y = i(t.data, v.data);
                    _ = new Qi(y, v.itemSize, v.offset, v.normalized);
                } else {
                    let y = Vi(v.type, v.array);
                    _ = new Kt(y, v.itemSize, v.normalized);
                }
                v.name !== void 0 && (_.name = v.name), x.push(_);
            }
            a.morphAttributes[f] = x;
        }
        t.data.morphTargetsRelative && (a.morphTargetsRelative = !0);
        let u = t.data.groups || t.data.drawcalls || t.data.offsets;
        if (u !== void 0) for(let f = 0, m = u.length; f !== m; ++f){
            let x = u[f];
            a.addGroup(x.start, x.count, x.materialIndex);
        }
        let d = t.data.boundingSphere;
        if (d !== void 0) {
            let f = new A;
            d.center !== void 0 && f.fromArray(d.center), a.boundingSphere = new We(f, d.radius);
        }
        return t.name && (a.name = t.name), t.userData && (a.userData = t.userData), a;
    }
}, au = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = this, a = this.path === "" ? da.extractUrlBase(t) : this.path;
        this.resourcePath = this.resourcePath || a;
        let o = new rn(this.manager);
        o.setPath(this.path), o.setRequestHeader(this.requestHeader), o.setWithCredentials(this.withCredentials), o.load(t, function(c) {
            let l = null;
            try {
                l = JSON.parse(c);
            } catch (u) {
                i !== void 0 && i(u), console.error("THREE:ObjectLoader: Can't parse " + t + ".", u.message);
                return;
            }
            let h = l.metadata;
            if (h === void 0 || h.type === void 0 || h.type.toLowerCase() === "geometry") {
                i !== void 0 && i(new Error("THREE.ObjectLoader: Can't load " + t)), console.error("THREE.ObjectLoader: Can't load " + t);
                return;
            }
            r.parse(l, e);
        }, n, i);
    }
    async loadAsync(t, e) {
        let n = this, i = this.path === "" ? da.extractUrlBase(t) : this.path;
        this.resourcePath = this.resourcePath || i;
        let r = new rn(this.manager);
        r.setPath(this.path), r.setRequestHeader(this.requestHeader), r.setWithCredentials(this.withCredentials);
        let a = await r.loadAsync(t, e), o = JSON.parse(a), c = o.metadata;
        if (c === void 0 || c.type === void 0 || c.type.toLowerCase() === "geometry") throw new Error("THREE.ObjectLoader: Can't load " + t);
        return await n.parseAsync(o);
    }
    parse(t, e) {
        let n = this.parseAnimations(t.animations), i = this.parseShapes(t.shapes), r = this.parseGeometries(t.geometries, i), a = this.parseImages(t.images, function() {
            e !== void 0 && e(l);
        }), o = this.parseTextures(t.textures, a), c = this.parseMaterials(t.materials, o), l = this.parseObject(t.object, r, c, o, n), h = this.parseSkeletons(t.skeletons, l);
        if (this.bindSkeletons(l, h), e !== void 0) {
            let u = !1;
            for(let d in a)if (a[d].data instanceof HTMLImageElement) {
                u = !0;
                break;
            }
            u === !1 && e(l);
        }
        return l;
    }
    async parseAsync(t) {
        let e = this.parseAnimations(t.animations), n = this.parseShapes(t.shapes), i = this.parseGeometries(t.geometries, n), r = await this.parseImagesAsync(t.images), a = this.parseTextures(t.textures, r), o = this.parseMaterials(t.materials, a), c = this.parseObject(t.object, i, o, a, e), l = this.parseSkeletons(t.skeletons, c);
        return this.bindSkeletons(c, l), c;
    }
    parseShapes(t) {
        let e = {};
        if (t !== void 0) for(let n = 0, i = t.length; n < i; n++){
            let r = new Fn().fromJSON(t[n]);
            e[r.uuid] = r;
        }
        return e;
    }
    parseSkeletons(t, e) {
        let n = {}, i = {};
        if (e.traverse(function(r) {
            r.isBone && (i[r.uuid] = r);
        }), t !== void 0) for(let r = 0, a = t.length; r < a; r++){
            let o = new Lo().fromJSON(t[r], i);
            n[o.uuid] = o;
        }
        return n;
    }
    parseGeometries(t, e) {
        let n = {};
        if (t !== void 0) {
            let i = new Cc;
            for(let r = 0, a = t.length; r < a; r++){
                let o, c = t[r];
                switch(c.type){
                    case "BufferGeometry":
                    case "InstancedBufferGeometry":
                        o = i.parse(c);
                        break;
                    default:
                        c.type in Kh ? o = Kh[c.type].fromJSON(c, e) : console.warn(`THREE.ObjectLoader: Unsupported geometry type "${c.type}"`);
                }
                o.uuid = c.uuid, c.name !== void 0 && (o.name = c.name), c.userData !== void 0 && (o.userData = c.userData), n[c.uuid] = o;
            }
        }
        return n;
    }
    parseMaterials(t, e) {
        let n = {}, i = {};
        if (t !== void 0) {
            let r = new Ac;
            r.setTextures(e);
            for(let a = 0, o = t.length; a < o; a++){
                let c = t[a];
                n[c.uuid] === void 0 && (n[c.uuid] = r.parse(c)), i[c.uuid] = n[c.uuid];
            }
        }
        return i;
    }
    parseAnimations(t) {
        let e = {};
        if (t !== void 0) for(let n = 0; n < t.length; n++){
            let i = t[n], r = is.parse(i);
            e[r.uuid] = r;
        }
        return e;
    }
    parseImages(t, e) {
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
                data: Vi(c.type, c.data),
                width: c.width,
                height: c.height
            } : null;
        }
        if (t !== void 0 && t.length > 0) {
            let c = new ua(e);
            r = new rs(c), r.setCrossOrigin(this.crossOrigin);
            for(let l = 0, h = t.length; l < h; l++){
                let u = t[l], d = u.url;
                if (Array.isArray(d)) {
                    let f = [];
                    for(let m = 0, x = d.length; m < x; m++){
                        let g = d[m], p = o(g);
                        p !== null && (p instanceof HTMLImageElement ? f.push(p) : f.push(new oi(p.data, p.width, p.height)));
                    }
                    i[u.uuid] = new Ln(f);
                } else {
                    let f = o(u.url);
                    i[u.uuid] = new Ln(f);
                }
            }
        }
        return i;
    }
    async parseImagesAsync(t) {
        let e = this, n = {}, i;
        async function r(a) {
            if (typeof a == "string") {
                let o = a, c = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(o) ? o : e.resourcePath + o;
                return await i.loadAsync(c);
            } else return a.data ? {
                data: Vi(a.type, a.data),
                width: a.width,
                height: a.height
            } : null;
        }
        if (t !== void 0 && t.length > 0) {
            i = new rs(this.manager), i.setCrossOrigin(this.crossOrigin);
            for(let a = 0, o = t.length; a < o; a++){
                let c = t[a], l = c.url;
                if (Array.isArray(l)) {
                    let h = [];
                    for(let u = 0, d = l.length; u < d; u++){
                        let f = l[u], m = await r(f);
                        m !== null && (m instanceof HTMLImageElement ? h.push(m) : h.push(new oi(m.data, m.width, m.height)));
                    }
                    n[c.uuid] = new Ln(h);
                } else {
                    let h = await r(c.url);
                    n[c.uuid] = new Ln(h);
                }
            }
        }
        return n;
    }
    parseTextures(t, e) {
        function n(r, a) {
            return typeof r == "number" ? r : (console.warn("THREE.ObjectLoader.parseTexture: Constant should be in numeric form.", r), a[r]);
        }
        let i = {};
        if (t !== void 0) for(let r = 0, a = t.length; r < a; r++){
            let o = t[r];
            o.image === void 0 && console.warn('THREE.ObjectLoader: No "image" specified for', o.uuid), e[o.image] === void 0 && console.warn("THREE.ObjectLoader: Undefined image", o.image);
            let c = e[o.image], l = c.data, h;
            Array.isArray(l) ? (h = new Ki, l.length === 6 && (h.needsUpdate = !0)) : (l && l.data ? h = new oi : h = new ye, l && (h.needsUpdate = !0)), h.source = c, h.uuid = o.uuid, o.name !== void 0 && (h.name = o.name), o.mapping !== void 0 && (h.mapping = n(o.mapping, bx)), o.channel !== void 0 && (h.channel = o.channel), o.offset !== void 0 && h.offset.fromArray(o.offset), o.repeat !== void 0 && h.repeat.fromArray(o.repeat), o.center !== void 0 && h.center.fromArray(o.center), o.rotation !== void 0 && (h.rotation = o.rotation), o.wrap !== void 0 && (h.wrapS = n(o.wrap[0], ou), h.wrapT = n(o.wrap[1], ou)), o.format !== void 0 && (h.format = o.format), o.internalFormat !== void 0 && (h.internalFormat = o.internalFormat), o.type !== void 0 && (h.type = o.type), o.colorSpace !== void 0 && (h.colorSpace = o.colorSpace), o.encoding !== void 0 && (h.encoding = o.encoding), o.minFilter !== void 0 && (h.minFilter = n(o.minFilter, cu)), o.magFilter !== void 0 && (h.magFilter = n(o.magFilter, cu)), o.anisotropy !== void 0 && (h.anisotropy = o.anisotropy), o.flipY !== void 0 && (h.flipY = o.flipY), o.generateMipmaps !== void 0 && (h.generateMipmaps = o.generateMipmaps), o.premultiplyAlpha !== void 0 && (h.premultiplyAlpha = o.premultiplyAlpha), o.unpackAlignment !== void 0 && (h.unpackAlignment = o.unpackAlignment), o.compareFunction !== void 0 && (h.compareFunction = o.compareFunction), o.userData !== void 0 && (h.userData = o.userData), i[o.uuid] = h;
        }
        return i;
    }
    parseObject(t, e, n, i, r) {
        let a;
        function o(d) {
            return e[d] === void 0 && console.warn("THREE.ObjectLoader: Undefined geometry", d), e[d];
        }
        function c(d) {
            if (d !== void 0) {
                if (Array.isArray(d)) {
                    let f = [];
                    for(let m = 0, x = d.length; m < x; m++){
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
        switch(t.type){
            case "Scene":
                a = new Ao, t.background !== void 0 && (Number.isInteger(t.background) ? a.background = new ft(t.background) : a.background = l(t.background)), t.environment !== void 0 && (a.environment = l(t.environment)), t.fog !== void 0 && (t.fog.type === "Fog" ? a.fog = new wo(t.fog.color, t.fog.near, t.fog.far) : t.fog.type === "FogExp2" && (a.fog = new To(t.fog.color, t.fog.density))), t.backgroundBlurriness !== void 0 && (a.backgroundBlurriness = t.backgroundBlurriness), t.backgroundIntensity !== void 0 && (a.backgroundIntensity = t.backgroundIntensity);
                break;
            case "PerspectiveCamera":
                a = new xe(t.fov, t.aspect, t.near, t.far), t.focus !== void 0 && (a.focus = t.focus), t.zoom !== void 0 && (a.zoom = t.zoom), t.filmGauge !== void 0 && (a.filmGauge = t.filmGauge), t.filmOffset !== void 0 && (a.filmOffset = t.filmOffset), t.view !== void 0 && (a.view = Object.assign({}, t.view));
                break;
            case "OrthographicCamera":
                a = new Ls(t.left, t.right, t.top, t.bottom, t.near, t.far), t.zoom !== void 0 && (a.zoom = t.zoom), t.view !== void 0 && (a.view = Object.assign({}, t.view));
                break;
            case "AmbientLight":
                a = new Ec(t.color, t.intensity);
                break;
            case "DirectionalLight":
                a = new bc(t.color, t.intensity);
                break;
            case "PointLight":
                a = new Mc(t.color, t.intensity, t.distance, t.decay);
                break;
            case "RectAreaLight":
                a = new Tc(t.color, t.intensity, t.width, t.height);
                break;
            case "SpotLight":
                a = new vc(t.color, t.intensity, t.distance, t.angle, t.penumbra, t.decay);
                break;
            case "HemisphereLight":
                a = new _c(t.color, t.groundColor, t.intensity);
                break;
            case "LightProbe":
                a = new Vs().fromJSON(t);
                break;
            case "SkinnedMesh":
                h = o(t.geometry), u = c(t.material), a = new Po(h, u), t.bindMode !== void 0 && (a.bindMode = t.bindMode), t.bindMatrix !== void 0 && a.bindMatrix.fromArray(t.bindMatrix), t.skeleton !== void 0 && (a.skeleton = t.skeleton);
                break;
            case "Mesh":
                h = o(t.geometry), u = c(t.material), a = new ve(h, u);
                break;
            case "InstancedMesh":
                h = o(t.geometry), u = c(t.material);
                let d = t.count, f = t.instanceMatrix, m = t.instanceColor;
                a = new Io(h, u, d), a.instanceMatrix = new ui(new Float32Array(f.array), 16), m !== void 0 && (a.instanceColor = new ui(new Float32Array(m.array), m.itemSize));
                break;
            case "LOD":
                a = new Co;
                break;
            case "Line":
                a = new Sn(o(t.geometry), c(t.material));
                break;
            case "LineLoop":
                a = new Uo(o(t.geometry), c(t.material));
                break;
            case "LineSegments":
                a = new je(o(t.geometry), c(t.material));
                break;
            case "PointCloud":
            case "Points":
                a = new No(o(t.geometry), c(t.material));
                break;
            case "Sprite":
                a = new Ro(c(t.material));
                break;
            case "Group":
                a = new ti;
                break;
            case "Bone":
                a = new jr;
                break;
            default:
                a = new Zt;
        }
        if (a.uuid = t.uuid, t.name !== void 0 && (a.name = t.name), t.matrix !== void 0 ? (a.matrix.fromArray(t.matrix), t.matrixAutoUpdate !== void 0 && (a.matrixAutoUpdate = t.matrixAutoUpdate), a.matrixAutoUpdate && a.matrix.decompose(a.position, a.quaternion, a.scale)) : (t.position !== void 0 && a.position.fromArray(t.position), t.rotation !== void 0 && a.rotation.fromArray(t.rotation), t.quaternion !== void 0 && a.quaternion.fromArray(t.quaternion), t.scale !== void 0 && a.scale.fromArray(t.scale)), t.up !== void 0 && a.up.fromArray(t.up), t.castShadow !== void 0 && (a.castShadow = t.castShadow), t.receiveShadow !== void 0 && (a.receiveShadow = t.receiveShadow), t.shadow && (t.shadow.bias !== void 0 && (a.shadow.bias = t.shadow.bias), t.shadow.normalBias !== void 0 && (a.shadow.normalBias = t.shadow.normalBias), t.shadow.radius !== void 0 && (a.shadow.radius = t.shadow.radius), t.shadow.mapSize !== void 0 && a.shadow.mapSize.fromArray(t.shadow.mapSize), t.shadow.camera !== void 0 && (a.shadow.camera = this.parseObject(t.shadow.camera))), t.visible !== void 0 && (a.visible = t.visible), t.frustumCulled !== void 0 && (a.frustumCulled = t.frustumCulled), t.renderOrder !== void 0 && (a.renderOrder = t.renderOrder), t.userData !== void 0 && (a.userData = t.userData), t.layers !== void 0 && (a.layers.mask = t.layers), t.children !== void 0) {
            let d = t.children;
            for(let f = 0; f < d.length; f++)a.add(this.parseObject(d[f], e, n, i, r));
        }
        if (t.animations !== void 0) {
            let d = t.animations;
            for(let f = 0; f < d.length; f++){
                let m = d[f];
                a.animations.push(r[m]);
            }
        }
        if (t.type === "LOD") {
            t.autoUpdate !== void 0 && (a.autoUpdate = t.autoUpdate);
            let d = t.levels;
            for(let f = 0; f < d.length; f++){
                let m = d[f], x = a.getObjectByProperty("uuid", m.object);
                x !== void 0 && a.addLevel(x, m.distance, m.hysteresis);
            }
        }
        return a;
    }
    bindSkeletons(t, e) {
        Object.keys(e).length !== 0 && t.traverse(function(n) {
            if (n.isSkinnedMesh === !0 && n.skeleton !== void 0) {
                let i = e[n.skeleton];
                i === void 0 ? console.warn("THREE.ObjectLoader: No skeleton found with UUID:", n.skeleton) : n.bind(i, n.bindMatrix);
            }
        });
    }
}, bx = {
    UVMapping: Oc,
    CubeReflectionMapping: Bn,
    CubeRefractionMapping: ci,
    EquirectangularReflectionMapping: Ur,
    EquirectangularRefractionMapping: Dr,
    CubeUVReflectionMapping: Hs
}, ou = {
    RepeatWrapping: Nr,
    ClampToEdgeWrapping: Ce,
    MirroredRepeatWrapping: Fr
}, cu = {
    NearestFilter: fe,
    NearestMipmapNearestFilter: oo,
    NearestMipmapLinearFilter: Ir,
    LinearFilter: pe,
    LinearMipmapNearestFilter: rd,
    LinearMipmapLinearFilter: li
}, lu = class extends Le {
    constructor(t){
        super(t), this.isImageBitmapLoader = !0, typeof createImageBitmap > "u" && console.warn("THREE.ImageBitmapLoader: createImageBitmap() not supported."), typeof fetch > "u" && console.warn("THREE.ImageBitmapLoader: fetch() not supported."), this.options = {
            premultiplyAlpha: "none"
        };
    }
    setOptions(t) {
        return this.options = t, this;
    }
    load(t, e, n, i) {
        t === void 0 && (t = ""), this.path !== void 0 && (t = this.path + t), t = this.manager.resolveURL(t);
        let r = this, a = ss.get(t);
        if (a !== void 0) return r.manager.itemStart(t), setTimeout(function() {
            e && e(a), r.manager.itemEnd(t);
        }, 0), a;
        let o = {};
        o.credentials = this.crossOrigin === "anonymous" ? "same-origin" : "include", o.headers = this.requestHeader, fetch(t, o).then(function(c) {
            return c.blob();
        }).then(function(c) {
            return createImageBitmap(c, Object.assign(r.options, {
                colorSpaceConversion: "none"
            }));
        }).then(function(c) {
            ss.add(t, c), e && e(c), r.manager.itemEnd(t);
        }).catch(function(c) {
            i && i(c), r.manager.itemError(t), r.manager.itemEnd(t);
        }), r.manager.itemStart(t);
    }
}, Tr, fa = class {
    static getContext() {
        return Tr === void 0 && (Tr = new (window.AudioContext || window.webkitAudioContext)), Tr;
    }
    static setContext(t) {
        Tr = t;
    }
}, hu = class extends Le {
    constructor(t){
        super(t);
    }
    load(t, e, n, i) {
        let r = this, a = new rn(this.manager);
        a.setResponseType("arraybuffer"), a.setPath(this.path), a.setRequestHeader(this.requestHeader), a.setWithCredentials(this.withCredentials), a.load(t, function(c) {
            try {
                let l = c.slice(0);
                fa.getContext().decodeAudioData(l, function(u) {
                    e(u);
                }, o);
            } catch (l) {
                o(l);
            }
        }, n, i);
        function o(c) {
            i ? i(c) : console.error(c), r.manager.itemError(t);
        }
    }
}, uu = class extends Vs {
    constructor(t, e, n = 1){
        super(void 0, n), this.isHemisphereLightProbe = !0;
        let i = new ft().set(t), r = new ft().set(e), a = new A(i.r, i.g, i.b), o = new A(r.r, r.g, r.b), c = Math.sqrt(Math.PI), l = c * Math.sqrt(.75);
        this.sh.coefficients[0].copy(a).add(o).multiplyScalar(c), this.sh.coefficients[1].copy(a).sub(o).multiplyScalar(l);
    }
}, du = class extends Vs {
    constructor(t, e = 1){
        super(void 0, e), this.isAmbientLightProbe = !0;
        let n = new ft().set(t);
        this.sh.coefficients[0].set(n.r, n.g, n.b).multiplyScalar(2 * Math.sqrt(Math.PI));
    }
}, fu = new Ot, pu = new Ot, Yn = new Ot, mu = class {
    constructor(){
        this.type = "StereoCamera", this.aspect = 1, this.eyeSep = .064, this.cameraL = new xe, this.cameraL.layers.enable(1), this.cameraL.matrixAutoUpdate = !1, this.cameraR = new xe, this.cameraR.layers.enable(2), this.cameraR.matrixAutoUpdate = !1, this._cache = {
            focus: null,
            fov: null,
            aspect: null,
            near: null,
            far: null,
            zoom: null,
            eyeSep: null
        };
    }
    update(t) {
        let e = this._cache;
        if (e.focus !== t.focus || e.fov !== t.fov || e.aspect !== t.aspect * this.aspect || e.near !== t.near || e.far !== t.far || e.zoom !== t.zoom || e.eyeSep !== this.eyeSep) {
            e.focus = t.focus, e.fov = t.fov, e.aspect = t.aspect * this.aspect, e.near = t.near, e.far = t.far, e.zoom = t.zoom, e.eyeSep = this.eyeSep, Yn.copy(t.projectionMatrix);
            let i = e.eyeSep / 2, r = i * e.near / e.focus, a = e.near * Math.tan(ai * e.fov * .5) / e.zoom, o, c;
            pu.elements[12] = -i, fu.elements[12] = i, o = -a * e.aspect + r, c = a * e.aspect + r, Yn.elements[0] = 2 * e.near / (c - o), Yn.elements[8] = (c + o) / (c - o), this.cameraL.projectionMatrix.copy(Yn), o = -a * e.aspect - r, c = a * e.aspect - r, Yn.elements[0] = 2 * e.near / (c - o), Yn.elements[8] = (c + o) / (c - o), this.cameraR.projectionMatrix.copy(Yn);
        }
        this.cameraL.matrixWorld.copy(t.matrixWorld).multiply(pu), this.cameraR.matrixWorld.copy(t.matrixWorld).multiply(fu);
    }
}, Pc = class {
    constructor(t = !0){
        this.autoStart = t, this.startTime = 0, this.oldTime = 0, this.elapsedTime = 0, this.running = !1;
    }
    start() {
        this.startTime = gu(), this.oldTime = this.startTime, this.elapsedTime = 0, this.running = !0;
    }
    stop() {
        this.getElapsedTime(), this.running = !1, this.autoStart = !1;
    }
    getElapsedTime() {
        return this.getDelta(), this.elapsedTime;
    }
    getDelta() {
        let t = 0;
        if (this.autoStart && !this.running) return this.start(), 0;
        if (this.running) {
            let e = gu();
            t = (e - this.oldTime) / 1e3, this.oldTime = e, this.elapsedTime += t;
        }
        return t;
    }
};
function gu() {
    return (typeof performance > "u" ? Date : performance).now();
}
var Zn = new A, _u = new Pe, Ex = new A, Jn = new A, xu = class extends Zt {
    constructor(){
        super(), this.type = "AudioListener", this.context = fa.getContext(), this.gain = this.context.createGain(), this.gain.connect(this.context.destination), this.filter = null, this.timeDelta = 0, this._clock = new Pc;
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
    setFilter(t) {
        return this.filter !== null ? (this.gain.disconnect(this.filter), this.filter.disconnect(this.context.destination)) : this.gain.disconnect(this.context.destination), this.filter = t, this.gain.connect(this.filter), this.filter.connect(this.context.destination), this;
    }
    getMasterVolume() {
        return this.gain.gain.value;
    }
    setMasterVolume(t) {
        return this.gain.gain.setTargetAtTime(t, this.context.currentTime, .01), this;
    }
    updateMatrixWorld(t) {
        super.updateMatrixWorld(t);
        let e = this.context.listener, n = this.up;
        if (this.timeDelta = this._clock.getDelta(), this.matrixWorld.decompose(Zn, _u, Ex), Jn.set(0, 0, -1).applyQuaternion(_u), e.positionX) {
            let i = this.context.currentTime + this.timeDelta;
            e.positionX.linearRampToValueAtTime(Zn.x, i), e.positionY.linearRampToValueAtTime(Zn.y, i), e.positionZ.linearRampToValueAtTime(Zn.z, i), e.forwardX.linearRampToValueAtTime(Jn.x, i), e.forwardY.linearRampToValueAtTime(Jn.y, i), e.forwardZ.linearRampToValueAtTime(Jn.z, i), e.upX.linearRampToValueAtTime(n.x, i), e.upY.linearRampToValueAtTime(n.y, i), e.upZ.linearRampToValueAtTime(n.z, i);
        } else e.setPosition(Zn.x, Zn.y, Zn.z), e.setOrientation(Jn.x, Jn.y, Jn.z, n.x, n.y, n.z);
    }
}, Lc = class extends Zt {
    constructor(t){
        super(), this.type = "Audio", this.listener = t, this.context = t.context, this.gain = this.context.createGain(), this.gain.connect(t.getInput()), this.autoplay = !1, this.buffer = null, this.detune = 0, this.loop = !1, this.loopStart = 0, this.loopEnd = 0, this.offset = 0, this.duration = void 0, this.playbackRate = 1, this.isPlaying = !1, this.hasPlaybackControl = !0, this.source = null, this.sourceType = "empty", this._startedAt = 0, this._progress = 0, this._connected = !1, this.filters = [];
    }
    getOutput() {
        return this.gain;
    }
    setNodeSource(t) {
        return this.hasPlaybackControl = !1, this.sourceType = "audioNode", this.source = t, this.connect(), this;
    }
    setMediaElementSource(t) {
        return this.hasPlaybackControl = !1, this.sourceType = "mediaNode", this.source = this.context.createMediaElementSource(t), this.connect(), this;
    }
    setMediaStreamSource(t) {
        return this.hasPlaybackControl = !1, this.sourceType = "mediaStreamNode", this.source = this.context.createMediaStreamSource(t), this.connect(), this;
    }
    setBuffer(t) {
        return this.buffer = t, this.sourceType = "buffer", this.autoplay && this.play(), this;
    }
    play(t = 0) {
        if (this.isPlaying === !0) {
            console.warn("THREE.Audio: Audio is already playing.");
            return;
        }
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        this._startedAt = this.context.currentTime + t;
        let e = this.context.createBufferSource();
        return e.buffer = this.buffer, e.loop = this.loop, e.loopStart = this.loopStart, e.loopEnd = this.loopEnd, e.onended = this.onEnded.bind(this), e.start(this._startedAt, this._progress + this.offset, this.duration), this.isPlaying = !0, this.source = e, this.setDetune(this.detune), this.setPlaybackRate(this.playbackRate), this.connect();
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
            for(let t = 1, e = this.filters.length; t < e; t++)this.filters[t - 1].connect(this.filters[t]);
            this.filters[this.filters.length - 1].connect(this.getOutput());
        } else this.source.connect(this.getOutput());
        return this._connected = !0, this;
    }
    disconnect() {
        if (this.filters.length > 0) {
            this.source.disconnect(this.filters[0]);
            for(let t = 1, e = this.filters.length; t < e; t++)this.filters[t - 1].disconnect(this.filters[t]);
            this.filters[this.filters.length - 1].disconnect(this.getOutput());
        } else this.source.disconnect(this.getOutput());
        return this._connected = !1, this;
    }
    getFilters() {
        return this.filters;
    }
    setFilters(t) {
        return t || (t = []), this._connected === !0 ? (this.disconnect(), this.filters = t.slice(), this.connect()) : this.filters = t.slice(), this;
    }
    setDetune(t) {
        if (this.detune = t, this.source.detune !== void 0) return this.isPlaying === !0 && this.source.detune.setTargetAtTime(this.detune, this.context.currentTime, .01), this;
    }
    getDetune() {
        return this.detune;
    }
    getFilter() {
        return this.getFilters()[0];
    }
    setFilter(t) {
        return this.setFilters(t ? [
            t
        ] : []);
    }
    setPlaybackRate(t) {
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        return this.playbackRate = t, this.isPlaying === !0 && this.source.playbackRate.setTargetAtTime(this.playbackRate, this.context.currentTime, .01), this;
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
    setLoop(t) {
        if (this.hasPlaybackControl === !1) {
            console.warn("THREE.Audio: this Audio has no playback control.");
            return;
        }
        return this.loop = t, this.isPlaying === !0 && (this.source.loop = this.loop), this;
    }
    setLoopStart(t) {
        return this.loopStart = t, this;
    }
    setLoopEnd(t) {
        return this.loopEnd = t, this;
    }
    getVolume() {
        return this.gain.gain.value;
    }
    setVolume(t) {
        return this.gain.gain.setTargetAtTime(t, this.context.currentTime, .01), this;
    }
}, $n = new A, vu = new Pe, Tx = new A, Kn = new A, yu = class extends Lc {
    constructor(t){
        super(t), this.panner = this.context.createPanner(), this.panner.panningModel = "HRTF", this.panner.connect(this.gain);
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
    setRefDistance(t) {
        return this.panner.refDistance = t, this;
    }
    getRolloffFactor() {
        return this.panner.rolloffFactor;
    }
    setRolloffFactor(t) {
        return this.panner.rolloffFactor = t, this;
    }
    getDistanceModel() {
        return this.panner.distanceModel;
    }
    setDistanceModel(t) {
        return this.panner.distanceModel = t, this;
    }
    getMaxDistance() {
        return this.panner.maxDistance;
    }
    setMaxDistance(t) {
        return this.panner.maxDistance = t, this;
    }
    setDirectionalCone(t, e, n) {
        return this.panner.coneInnerAngle = t, this.panner.coneOuterAngle = e, this.panner.coneOuterGain = n, this;
    }
    updateMatrixWorld(t) {
        if (super.updateMatrixWorld(t), this.hasPlaybackControl === !0 && this.isPlaying === !1) return;
        this.matrixWorld.decompose($n, vu, Tx), Kn.set(0, 0, 1).applyQuaternion(vu);
        let e = this.panner;
        if (e.positionX) {
            let n = this.context.currentTime + this.listener.timeDelta;
            e.positionX.linearRampToValueAtTime($n.x, n), e.positionY.linearRampToValueAtTime($n.y, n), e.positionZ.linearRampToValueAtTime($n.z, n), e.orientationX.linearRampToValueAtTime(Kn.x, n), e.orientationY.linearRampToValueAtTime(Kn.y, n), e.orientationZ.linearRampToValueAtTime(Kn.z, n);
        } else e.setPosition($n.x, $n.y, $n.z), e.setOrientation(Kn.x, Kn.y, Kn.z);
    }
}, Mu = class {
    constructor(t, e = 2048){
        this.analyser = t.context.createAnalyser(), this.analyser.fftSize = e, this.data = new Uint8Array(this.analyser.frequencyBinCount), t.getOutput().connect(this.analyser);
    }
    getFrequencyData() {
        return this.analyser.getByteFrequencyData(this.data), this.data;
    }
    getAverageFrequency() {
        let t = 0, e = this.getFrequencyData();
        for(let n = 0; n < e.length; n++)t += e[n];
        return t / e.length;
    }
}, Ic = class {
    constructor(t, e, n){
        this.binding = t, this.valueSize = n;
        let i, r, a;
        switch(e){
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
    accumulate(t, e) {
        let n = this.buffer, i = this.valueSize, r = t * i + i, a = this.cumulativeWeight;
        if (a === 0) {
            for(let o = 0; o !== i; ++o)n[r + o] = n[o];
            a = e;
        } else {
            a += e;
            let o = e / a;
            this._mixBufferRegion(n, r, 0, o, i);
        }
        this.cumulativeWeight = a;
    }
    accumulateAdditive(t) {
        let e = this.buffer, n = this.valueSize, i = n * this._addIndex;
        this.cumulativeWeightAdditive === 0 && this._setIdentity(), this._mixBufferRegionAdditive(e, i, 0, t, n), this.cumulativeWeightAdditive += t;
    }
    apply(t) {
        let e = this.valueSize, n = this.buffer, i = t * e + e, r = this.cumulativeWeight, a = this.cumulativeWeightAdditive, o = this.binding;
        if (this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0, r < 1) {
            let c = e * this._origIndex;
            this._mixBufferRegion(n, i, c, 1 - r, e);
        }
        a > 0 && this._mixBufferRegionAdditive(n, i, this._addIndex * e, 1, e);
        for(let c = e, l = e + e; c !== l; ++c)if (n[c] !== n[c + e]) {
            o.setValue(n, i);
            break;
        }
    }
    saveOriginalState() {
        let t = this.binding, e = this.buffer, n = this.valueSize, i = n * this._origIndex;
        t.getValue(e, i);
        for(let r = n, a = i; r !== a; ++r)e[r] = e[i + r % n];
        this._setIdentity(), this.cumulativeWeight = 0, this.cumulativeWeightAdditive = 0;
    }
    restoreOriginalState() {
        let t = this.valueSize * 3;
        this.binding.setValue(this.buffer, t);
    }
    _setAdditiveIdentityNumeric() {
        let t = this._addIndex * this.valueSize, e = t + this.valueSize;
        for(let n = t; n < e; n++)this.buffer[n] = 0;
    }
    _setAdditiveIdentityQuaternion() {
        this._setAdditiveIdentityNumeric(), this.buffer[this._addIndex * this.valueSize + 3] = 1;
    }
    _setAdditiveIdentityOther() {
        let t = this._origIndex * this.valueSize, e = this._addIndex * this.valueSize;
        for(let n = 0; n < this.valueSize; n++)this.buffer[e + n] = this.buffer[t + n];
    }
    _select(t, e, n, i, r) {
        if (i >= .5) for(let a = 0; a !== r; ++a)t[e + a] = t[n + a];
    }
    _slerp(t, e, n, i) {
        Pe.slerpFlat(t, e, t, e, t, n, i);
    }
    _slerpAdditive(t, e, n, i, r) {
        let a = this._workIndex * r;
        Pe.multiplyQuaternionsFlat(t, a, t, e, t, n), Pe.slerpFlat(t, e, t, e, t, a, i);
    }
    _lerp(t, e, n, i, r) {
        let a = 1 - i;
        for(let o = 0; o !== r; ++o){
            let c = e + o;
            t[c] = t[c] * a + t[n + o] * i;
        }
    }
    _lerpAdditive(t, e, n, i, r) {
        for(let a = 0; a !== r; ++a){
            let o = e + a;
            t[o] = t[o] + t[n + a] * i;
        }
    }
}, qc = "\\[\\]\\.:\\/", wx = new RegExp("[" + qc + "]", "g"), Yc = "[^" + qc + "]", Ax = "[^" + qc.replace("\\.", "") + "]", Rx = /((?:WC+[\/:])*)/.source.replace("WC", Yc), Cx = /(WCOD+)?/.source.replace("WCOD", Ax), Px = /(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC", Yc), Lx = /\.(WC+)(?:\[(.+)\])?/.source.replace("WC", Yc), Ix = new RegExp("^" + Rx + Cx + Px + Lx + "$"), Ux = [
    "material",
    "materials",
    "bones",
    "map"
], Uc = class {
    constructor(t, e, n){
        let i = n || Jt.parseTrackName(e);
        this._targetGroup = t, this._bindings = t.subscribe_(e, i);
    }
    getValue(t, e) {
        this.bind();
        let n = this._targetGroup.nCachedObjects_, i = this._bindings[n];
        i !== void 0 && i.getValue(t, e);
    }
    setValue(t, e) {
        let n = this._bindings;
        for(let i = this._targetGroup.nCachedObjects_, r = n.length; i !== r; ++i)n[i].setValue(t, e);
    }
    bind() {
        let t = this._bindings;
        for(let e = this._targetGroup.nCachedObjects_, n = t.length; e !== n; ++e)t[e].bind();
    }
    unbind() {
        let t = this._bindings;
        for(let e = this._targetGroup.nCachedObjects_, n = t.length; e !== n; ++e)t[e].unbind();
    }
}, Jt = class s1 {
    constructor(t, e, n){
        this.path = e, this.parsedPath = n || s1.parseTrackName(e), this.node = s1.findNode(t, this.parsedPath.nodeName), this.rootNode = t, this.getValue = this._getValue_unbound, this.setValue = this._setValue_unbound;
    }
    static create(t, e, n) {
        return t && t.isAnimationObjectGroup ? new s1.Composite(t, e, n) : new s1(t, e, n);
    }
    static sanitizeNodeName(t) {
        return t.replace(/\s/g, "_").replace(wx, "");
    }
    static parseTrackName(t) {
        let e = Ix.exec(t);
        if (e === null) throw new Error("PropertyBinding: Cannot parse trackName: " + t);
        let n = {
            nodeName: e[2],
            objectName: e[3],
            objectIndex: e[4],
            propertyName: e[5],
            propertyIndex: e[6]
        }, i = n.nodeName && n.nodeName.lastIndexOf(".");
        if (i !== void 0 && i !== -1) {
            let r = n.nodeName.substring(i + 1);
            Ux.indexOf(r) !== -1 && (n.nodeName = n.nodeName.substring(0, i), n.objectName = r);
        }
        if (n.propertyName === null || n.propertyName.length === 0) throw new Error("PropertyBinding: can not parse propertyName from trackName: " + t);
        return n;
    }
    static findNode(t, e) {
        if (e === void 0 || e === "" || e === "." || e === -1 || e === t.name || e === t.uuid) return t;
        if (t.skeleton) {
            let n = t.skeleton.getBoneByName(e);
            if (n !== void 0) return n;
        }
        if (t.children) {
            let n = function(r) {
                for(let a = 0; a < r.length; a++){
                    let o = r[a];
                    if (o.name === e || o.uuid === e) return o;
                    let c = n(o.children);
                    if (c) return c;
                }
                return null;
            }, i = n(t.children);
            if (i) return i;
        }
        return null;
    }
    _getValue_unavailable() {}
    _setValue_unavailable() {}
    _getValue_direct(t, e) {
        t[e] = this.targetObject[this.propertyName];
    }
    _getValue_array(t, e) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)t[e++] = n[i];
    }
    _getValue_arrayElement(t, e) {
        t[e] = this.resolvedProperty[this.propertyIndex];
    }
    _getValue_toArray(t, e) {
        this.resolvedProperty.toArray(t, e);
    }
    _setValue_direct(t, e) {
        this.targetObject[this.propertyName] = t[e];
    }
    _setValue_direct_setNeedsUpdate(t, e) {
        this.targetObject[this.propertyName] = t[e], this.targetObject.needsUpdate = !0;
    }
    _setValue_direct_setMatrixWorldNeedsUpdate(t, e) {
        this.targetObject[this.propertyName] = t[e], this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _setValue_array(t, e) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)n[i] = t[e++];
    }
    _setValue_array_setNeedsUpdate(t, e) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)n[i] = t[e++];
        this.targetObject.needsUpdate = !0;
    }
    _setValue_array_setMatrixWorldNeedsUpdate(t, e) {
        let n = this.resolvedProperty;
        for(let i = 0, r = n.length; i !== r; ++i)n[i] = t[e++];
        this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _setValue_arrayElement(t, e) {
        this.resolvedProperty[this.propertyIndex] = t[e];
    }
    _setValue_arrayElement_setNeedsUpdate(t, e) {
        this.resolvedProperty[this.propertyIndex] = t[e], this.targetObject.needsUpdate = !0;
    }
    _setValue_arrayElement_setMatrixWorldNeedsUpdate(t, e) {
        this.resolvedProperty[this.propertyIndex] = t[e], this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _setValue_fromArray(t, e) {
        this.resolvedProperty.fromArray(t, e);
    }
    _setValue_fromArray_setNeedsUpdate(t, e) {
        this.resolvedProperty.fromArray(t, e), this.targetObject.needsUpdate = !0;
    }
    _setValue_fromArray_setMatrixWorldNeedsUpdate(t, e) {
        this.resolvedProperty.fromArray(t, e), this.targetObject.matrixWorldNeedsUpdate = !0;
    }
    _getValue_unbound(t, e) {
        this.bind(), this.getValue(t, e);
    }
    _setValue_unbound(t, e) {
        this.bind(), this.setValue(t, e);
    }
    bind() {
        let t = this.node, e = this.parsedPath, n = e.objectName, i = e.propertyName, r = e.propertyIndex;
        if (t || (t = s1.findNode(this.rootNode, e.nodeName), this.node = t), this.getValue = this._getValue_unavailable, this.setValue = this._setValue_unavailable, !t) {
            console.warn("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
            return;
        }
        if (n) {
            let l = e.objectIndex;
            switch(n){
                case "materials":
                    if (!t.material) {
                        console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
                        return;
                    }
                    if (!t.material.materials) {
                        console.error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.", this);
                        return;
                    }
                    t = t.material.materials;
                    break;
                case "bones":
                    if (!t.skeleton) {
                        console.error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.", this);
                        return;
                    }
                    t = t.skeleton.bones;
                    for(let h = 0; h < t.length; h++)if (t[h].name === l) {
                        l = h;
                        break;
                    }
                    break;
                case "map":
                    if ("map" in t) {
                        t = t.map;
                        break;
                    }
                    if (!t.material) {
                        console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
                        return;
                    }
                    if (!t.material.map) {
                        console.error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.", this);
                        return;
                    }
                    t = t.material.map;
                    break;
                default:
                    if (t[n] === void 0) {
                        console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
                        return;
                    }
                    t = t[n];
            }
            if (l !== void 0) {
                if (t[l] === void 0) {
                    console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, t);
                    return;
                }
                t = t[l];
            }
        }
        let a = t[i];
        if (a === void 0) {
            let l = e.nodeName;
            console.error("THREE.PropertyBinding: Trying to update property for track: " + l + "." + i + " but it wasn't found.", t);
            return;
        }
        let o = this.Versioning.None;
        this.targetObject = t, t.needsUpdate !== void 0 ? o = this.Versioning.NeedsUpdate : t.matrixWorldNeedsUpdate !== void 0 && (o = this.Versioning.MatrixWorldNeedsUpdate);
        let c = this.BindingType.Direct;
        if (r !== void 0) {
            if (i === "morphTargetInfluences") {
                if (!t.geometry) {
                    console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
                    return;
                }
                if (!t.geometry.morphAttributes) {
                    console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
                    return;
                }
                t.morphTargetDictionary[r] !== void 0 && (r = t.morphTargetDictionary[r]);
            }
            c = this.BindingType.ArrayElement, this.resolvedProperty = a, this.propertyIndex = r;
        } else a.fromArray !== void 0 && a.toArray !== void 0 ? (c = this.BindingType.HasFromToArray, this.resolvedProperty = a) : Array.isArray(a) ? (c = this.BindingType.EntireArray, this.resolvedProperty = a) : this.propertyName = i;
        this.getValue = this.GetterByBindingType[c], this.setValue = this.SetterByBindingTypeAndVersioning[c][o];
    }
    unbind() {
        this.node = null, this.getValue = this._getValue_unbound, this.setValue = this._setValue_unbound;
    }
};
Jt.Composite = Uc;
Jt.prototype.BindingType = {
    Direct: 0,
    EntireArray: 1,
    ArrayElement: 2,
    HasFromToArray: 3
};
Jt.prototype.Versioning = {
    None: 0,
    NeedsUpdate: 1,
    MatrixWorldNeedsUpdate: 2
};
Jt.prototype.GetterByBindingType = [
    Jt.prototype._getValue_direct,
    Jt.prototype._getValue_array,
    Jt.prototype._getValue_arrayElement,
    Jt.prototype._getValue_toArray
];
Jt.prototype.SetterByBindingTypeAndVersioning = [
    [
        Jt.prototype._setValue_direct,
        Jt.prototype._setValue_direct_setNeedsUpdate,
        Jt.prototype._setValue_direct_setMatrixWorldNeedsUpdate
    ],
    [
        Jt.prototype._setValue_array,
        Jt.prototype._setValue_array_setNeedsUpdate,
        Jt.prototype._setValue_array_setMatrixWorldNeedsUpdate
    ],
    [
        Jt.prototype._setValue_arrayElement,
        Jt.prototype._setValue_arrayElement_setNeedsUpdate,
        Jt.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate
    ],
    [
        Jt.prototype._setValue_fromArray,
        Jt.prototype._setValue_fromArray_setNeedsUpdate,
        Jt.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate
    ]
];
var Su = class {
    constructor(){
        this.isAnimationObjectGroup = !0, this.uuid = Be(), this._objects = Array.prototype.slice.call(arguments), this.nCachedObjects_ = 0;
        let t = {};
        this._indicesByUUID = t;
        for(let n = 0, i = arguments.length; n !== i; ++n)t[arguments[n].uuid] = n;
        this._paths = [], this._parsedPaths = [], this._bindings = [], this._bindingsIndicesByPath = {};
        let e = this;
        this.stats = {
            objects: {
                get total () {
                    return e._objects.length;
                },
                get inUse () {
                    return this.total - e.nCachedObjects_;
                }
            },
            get bindingsPerObject () {
                return e._bindings.length;
            }
        };
    }
    add() {
        let t = this._objects, e = this._indicesByUUID, n = this._paths, i = this._parsedPaths, r = this._bindings, a = r.length, o, c = t.length, l = this.nCachedObjects_;
        for(let h = 0, u = arguments.length; h !== u; ++h){
            let d = arguments[h], f = d.uuid, m = e[f];
            if (m === void 0) {
                m = c++, e[f] = m, t.push(d);
                for(let x = 0, g = a; x !== g; ++x)r[x].push(new Jt(d, n[x], i[x]));
            } else if (m < l) {
                o = t[m];
                let x = --l, g = t[x];
                e[g.uuid] = m, t[m] = g, e[f] = x, t[x] = d;
                for(let p = 0, v = a; p !== v; ++p){
                    let _ = r[p], y = _[x], b = _[m];
                    _[m] = y, b === void 0 && (b = new Jt(d, n[p], i[p])), _[x] = b;
                }
            } else t[m] !== o && console.error("THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.");
        }
        this.nCachedObjects_ = l;
    }
    remove() {
        let t = this._objects, e = this._indicesByUUID, n = this._bindings, i = n.length, r = this.nCachedObjects_;
        for(let a = 0, o = arguments.length; a !== o; ++a){
            let c = arguments[a], l = c.uuid, h = e[l];
            if (h !== void 0 && h >= r) {
                let u = r++, d = t[u];
                e[d.uuid] = h, t[h] = d, e[l] = u, t[u] = c;
                for(let f = 0, m = i; f !== m; ++f){
                    let x = n[f], g = x[u], p = x[h];
                    x[h] = g, x[u] = p;
                }
            }
        }
        this.nCachedObjects_ = r;
    }
    uncache() {
        let t = this._objects, e = this._indicesByUUID, n = this._bindings, i = n.length, r = this.nCachedObjects_, a = t.length;
        for(let o = 0, c = arguments.length; o !== c; ++o){
            let l = arguments[o], h = l.uuid, u = e[h];
            if (u !== void 0) if (delete e[h], u < r) {
                let d = --r, f = t[d], m = --a, x = t[m];
                e[f.uuid] = u, t[u] = f, e[x.uuid] = d, t[d] = x, t.pop();
                for(let g = 0, p = i; g !== p; ++g){
                    let v = n[g], _ = v[d], y = v[m];
                    v[u] = _, v[d] = y, v.pop();
                }
            } else {
                let d = --a, f = t[d];
                d > 0 && (e[f.uuid] = u), t[u] = f, t.pop();
                for(let m = 0, x = i; m !== x; ++m){
                    let g = n[m];
                    g[u] = g[d], g.pop();
                }
            }
        }
        this.nCachedObjects_ = r;
    }
    subscribe_(t, e) {
        let n = this._bindingsIndicesByPath, i = n[t], r = this._bindings;
        if (i !== void 0) return r[i];
        let a = this._paths, o = this._parsedPaths, c = this._objects, l = c.length, h = this.nCachedObjects_, u = new Array(l);
        i = r.length, n[t] = i, a.push(t), o.push(e), r.push(u);
        for(let d = h, f = c.length; d !== f; ++d){
            let m = c[d];
            u[d] = new Jt(m, t, e);
        }
        return u;
    }
    unsubscribe_(t) {
        let e = this._bindingsIndicesByPath, n = e[t];
        if (n !== void 0) {
            let i = this._paths, r = this._parsedPaths, a = this._bindings, o = a.length - 1, c = a[o], l = t[o];
            e[l] = n, a[n] = c, a.pop(), r[n] = r[o], r.pop(), i[n] = i[o], i.pop();
        }
    }
}, Dc = class {
    constructor(t, e, n = null, i = e.blendMode){
        this._mixer = t, this._clip = e, this._localRoot = n, this.blendMode = i;
        let r = e.tracks, a = r.length, o = new Array(a), c = {
            endingStart: zi,
            endingEnd: zi
        };
        for(let l = 0; l !== a; ++l){
            let h = r[l].createInterpolant(null);
            o[l] = h, h.settings = c;
        }
        this._interpolantSettings = c, this._interpolants = o, this._propertyBindings = new Array(a), this._cacheIndex = null, this._byClipCacheIndex = null, this._timeScaleInterpolant = null, this._weightInterpolant = null, this.loop = Mf, this._loopCount = -1, this._startTime = null, this.time = 0, this.timeScale = 1, this._effectiveTimeScale = 1, this.weight = 1, this._effectiveWeight = 1, this.repetitions = 1 / 0, this.paused = !1, this.enabled = !0, this.clampWhenFinished = !1, this.zeroSlopeAtStart = !0, this.zeroSlopeAtEnd = !0;
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
    startAt(t) {
        return this._startTime = t, this;
    }
    setLoop(t, e) {
        return this.loop = t, this.repetitions = e, this;
    }
    setEffectiveWeight(t) {
        return this.weight = t, this._effectiveWeight = this.enabled ? t : 0, this.stopFading();
    }
    getEffectiveWeight() {
        return this._effectiveWeight;
    }
    fadeIn(t) {
        return this._scheduleFading(t, 0, 1);
    }
    fadeOut(t) {
        return this._scheduleFading(t, 1, 0);
    }
    crossFadeFrom(t, e, n) {
        if (t.fadeOut(e), this.fadeIn(e), n) {
            let i = this._clip.duration, r = t._clip.duration, a = r / i, o = i / r;
            t.warp(1, a, e), this.warp(o, 1, e);
        }
        return this;
    }
    crossFadeTo(t, e, n) {
        return t.crossFadeFrom(this, e, n);
    }
    stopFading() {
        let t = this._weightInterpolant;
        return t !== null && (this._weightInterpolant = null, this._mixer._takeBackControlInterpolant(t)), this;
    }
    setEffectiveTimeScale(t) {
        return this.timeScale = t, this._effectiveTimeScale = this.paused ? 0 : t, this.stopWarping();
    }
    getEffectiveTimeScale() {
        return this._effectiveTimeScale;
    }
    setDuration(t) {
        return this.timeScale = this._clip.duration / t, this.stopWarping();
    }
    syncWith(t) {
        return this.time = t.time, this.timeScale = t.timeScale, this.stopWarping();
    }
    halt(t) {
        return this.warp(this._effectiveTimeScale, 0, t);
    }
    warp(t, e, n) {
        let i = this._mixer, r = i.time, a = this.timeScale, o = this._timeScaleInterpolant;
        o === null && (o = i._lendControlInterpolant(), this._timeScaleInterpolant = o);
        let c = o.parameterPositions, l = o.sampleValues;
        return c[0] = r, c[1] = r + n, l[0] = t / a, l[1] = e / a, this;
    }
    stopWarping() {
        let t = this._timeScaleInterpolant;
        return t !== null && (this._timeScaleInterpolant = null, this._mixer._takeBackControlInterpolant(t)), this;
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
    _update(t, e, n, i) {
        if (!this.enabled) {
            this._updateWeight(t);
            return;
        }
        let r = this._startTime;
        if (r !== null) {
            let c = (t - r) * n;
            c < 0 || n === 0 ? e = 0 : (this._startTime = null, e = n * c);
        }
        e *= this._updateTimeScale(t);
        let a = this._updateTime(e), o = this._updateWeight(t);
        if (o > 0) {
            let c = this._interpolants, l = this._propertyBindings;
            switch(this.blendMode){
                case dd:
                    for(let h = 0, u = c.length; h !== u; ++h)c[h].evaluate(a), l[h].accumulateAdditive(o);
                    break;
                case zc:
                default:
                    for(let h = 0, u = c.length; h !== u; ++h)c[h].evaluate(a), l[h].accumulate(i, o);
            }
        }
    }
    _updateWeight(t) {
        let e = 0;
        if (this.enabled) {
            e = this.weight;
            let n = this._weightInterpolant;
            if (n !== null) {
                let i = n.evaluate(t)[0];
                e *= i, t > n.parameterPositions[1] && (this.stopFading(), i === 0 && (this.enabled = !1));
            }
        }
        return this._effectiveWeight = e, e;
    }
    _updateTimeScale(t) {
        let e = 0;
        if (!this.paused) {
            e = this.timeScale;
            let n = this._timeScaleInterpolant;
            if (n !== null) {
                let i = n.evaluate(t)[0];
                e *= i, t > n.parameterPositions[1] && (this.stopWarping(), e === 0 ? this.paused = !0 : this.timeScale = e);
            }
        }
        return this._effectiveTimeScale = e, e;
    }
    _updateTime(t) {
        let e = this._clip.duration, n = this.loop, i = this.time + t, r = this._loopCount, a = n === Sf;
        if (t === 0) return r === -1 ? i : a && (r & 1) === 1 ? e - i : i;
        if (n === yf) {
            r === -1 && (this._loopCount = 0, this._setEndings(!0, !0, !1));
            t: {
                if (i >= e) i = e;
                else if (i < 0) i = 0;
                else {
                    this.time = i;
                    break t;
                }
                this.clampWhenFinished ? this.paused = !0 : this.enabled = !1, this.time = i, this._mixer.dispatchEvent({
                    type: "finished",
                    action: this,
                    direction: t < 0 ? -1 : 1
                });
            }
        } else {
            if (r === -1 && (t >= 0 ? (r = 0, this._setEndings(!0, this.repetitions === 0, a)) : this._setEndings(this.repetitions === 0, !0, a)), i >= e || i < 0) {
                let o = Math.floor(i / e);
                i -= e * o, r += Math.abs(o);
                let c = this.repetitions - r;
                if (c <= 0) this.clampWhenFinished ? this.paused = !0 : this.enabled = !1, i = t > 0 ? e : 0, this.time = i, this._mixer.dispatchEvent({
                    type: "finished",
                    action: this,
                    direction: t > 0 ? 1 : -1
                });
                else {
                    if (c === 1) {
                        let l = t < 0;
                        this._setEndings(l, !l, a);
                    } else this._setEndings(!1, !1, a);
                    this._loopCount = r, this.time = i, this._mixer.dispatchEvent({
                        type: "loop",
                        action: this,
                        loopDelta: o
                    });
                }
            } else this.time = i;
            if (a && (r & 1) === 1) return e - i;
        }
        return i;
    }
    _setEndings(t, e, n) {
        let i = this._interpolantSettings;
        n ? (i.endingStart = ki, i.endingEnd = ki) : (t ? i.endingStart = this.zeroSlopeAtStart ? ki : zi : i.endingStart = zr, e ? i.endingEnd = this.zeroSlopeAtEnd ? ki : zi : i.endingEnd = zr);
    }
    _scheduleFading(t, e, n) {
        let i = this._mixer, r = i.time, a = this._weightInterpolant;
        a === null && (a = i._lendControlInterpolant(), this._weightInterpolant = a);
        let o = a.parameterPositions, c = a.sampleValues;
        return o[0] = r, c[0] = e, o[1] = r + t, c[1] = n, this;
    }
}, Dx = new Float32Array(1), bu = class extends sn {
    constructor(t){
        super(), this._root = t, this._initMemoryManager(), this._accuIndex = 0, this.time = 0, this.timeScale = 1;
    }
    _bindAction(t, e) {
        let n = t._localRoot || this._root, i = t._clip.tracks, r = i.length, a = t._propertyBindings, o = t._interpolants, c = n.uuid, l = this._bindingsByRootAndName, h = l[c];
        h === void 0 && (h = {}, l[c] = h);
        for(let u = 0; u !== r; ++u){
            let d = i[u], f = d.name, m = h[f];
            if (m !== void 0) ++m.referenceCount, a[u] = m;
            else {
                if (m = a[u], m !== void 0) {
                    m._cacheIndex === null && (++m.referenceCount, this._addInactiveBinding(m, c, f));
                    continue;
                }
                let x = e && e._propertyBindings[u].binding.parsedPath;
                m = new Ic(Jt.create(n, f, x), d.ValueTypeName, d.getValueSize()), ++m.referenceCount, this._addInactiveBinding(m, c, f), a[u] = m;
            }
            o[u].resultBuffer = m.buffer;
        }
    }
    _activateAction(t) {
        if (!this._isActiveAction(t)) {
            if (t._cacheIndex === null) {
                let n = (t._localRoot || this._root).uuid, i = t._clip.uuid, r = this._actionsByClip[i];
                this._bindAction(t, r && r.knownActions[0]), this._addInactiveAction(t, i, n);
            }
            let e = t._propertyBindings;
            for(let n = 0, i = e.length; n !== i; ++n){
                let r = e[n];
                r.useCount++ === 0 && (this._lendBinding(r), r.saveOriginalState());
            }
            this._lendAction(t);
        }
    }
    _deactivateAction(t) {
        if (this._isActiveAction(t)) {
            let e = t._propertyBindings;
            for(let n = 0, i = e.length; n !== i; ++n){
                let r = e[n];
                --r.useCount === 0 && (r.restoreOriginalState(), this._takeBackBinding(r));
            }
            this._takeBackAction(t);
        }
    }
    _initMemoryManager() {
        this._actions = [], this._nActiveActions = 0, this._actionsByClip = {}, this._bindings = [], this._nActiveBindings = 0, this._bindingsByRootAndName = {}, this._controlInterpolants = [], this._nActiveControlInterpolants = 0;
        let t = this;
        this.stats = {
            actions: {
                get total () {
                    return t._actions.length;
                },
                get inUse () {
                    return t._nActiveActions;
                }
            },
            bindings: {
                get total () {
                    return t._bindings.length;
                },
                get inUse () {
                    return t._nActiveBindings;
                }
            },
            controlInterpolants: {
                get total () {
                    return t._controlInterpolants.length;
                },
                get inUse () {
                    return t._nActiveControlInterpolants;
                }
            }
        };
    }
    _isActiveAction(t) {
        let e = t._cacheIndex;
        return e !== null && e < this._nActiveActions;
    }
    _addInactiveAction(t, e, n) {
        let i = this._actions, r = this._actionsByClip, a = r[e];
        if (a === void 0) a = {
            knownActions: [
                t
            ],
            actionByRoot: {}
        }, t._byClipCacheIndex = 0, r[e] = a;
        else {
            let o = a.knownActions;
            t._byClipCacheIndex = o.length, o.push(t);
        }
        t._cacheIndex = i.length, i.push(t), a.actionByRoot[n] = t;
    }
    _removeInactiveAction(t) {
        let e = this._actions, n = e[e.length - 1], i = t._cacheIndex;
        n._cacheIndex = i, e[i] = n, e.pop(), t._cacheIndex = null;
        let r = t._clip.uuid, a = this._actionsByClip, o = a[r], c = o.knownActions, l = c[c.length - 1], h = t._byClipCacheIndex;
        l._byClipCacheIndex = h, c[h] = l, c.pop(), t._byClipCacheIndex = null;
        let u = o.actionByRoot, d = (t._localRoot || this._root).uuid;
        delete u[d], c.length === 0 && delete a[r], this._removeInactiveBindingsForAction(t);
    }
    _removeInactiveBindingsForAction(t) {
        let e = t._propertyBindings;
        for(let n = 0, i = e.length; n !== i; ++n){
            let r = e[n];
            --r.referenceCount === 0 && this._removeInactiveBinding(r);
        }
    }
    _lendAction(t) {
        let e = this._actions, n = t._cacheIndex, i = this._nActiveActions++, r = e[i];
        t._cacheIndex = i, e[i] = t, r._cacheIndex = n, e[n] = r;
    }
    _takeBackAction(t) {
        let e = this._actions, n = t._cacheIndex, i = --this._nActiveActions, r = e[i];
        t._cacheIndex = i, e[i] = t, r._cacheIndex = n, e[n] = r;
    }
    _addInactiveBinding(t, e, n) {
        let i = this._bindingsByRootAndName, r = this._bindings, a = i[e];
        a === void 0 && (a = {}, i[e] = a), a[n] = t, t._cacheIndex = r.length, r.push(t);
    }
    _removeInactiveBinding(t) {
        let e = this._bindings, n = t.binding, i = n.rootNode.uuid, r = n.path, a = this._bindingsByRootAndName, o = a[i], c = e[e.length - 1], l = t._cacheIndex;
        c._cacheIndex = l, e[l] = c, e.pop(), delete o[r], Object.keys(o).length === 0 && delete a[i];
    }
    _lendBinding(t) {
        let e = this._bindings, n = t._cacheIndex, i = this._nActiveBindings++, r = e[i];
        t._cacheIndex = i, e[i] = t, r._cacheIndex = n, e[n] = r;
    }
    _takeBackBinding(t) {
        let e = this._bindings, n = t._cacheIndex, i = --this._nActiveBindings, r = e[i];
        t._cacheIndex = i, e[i] = t, r._cacheIndex = n, e[n] = r;
    }
    _lendControlInterpolant() {
        let t = this._controlInterpolants, e = this._nActiveControlInterpolants++, n = t[e];
        return n === void 0 && (n = new la(new Float32Array(2), new Float32Array(2), 1, Dx), n.__cacheIndex = e, t[e] = n), n;
    }
    _takeBackControlInterpolant(t) {
        let e = this._controlInterpolants, n = t.__cacheIndex, i = --this._nActiveControlInterpolants, r = e[i];
        t.__cacheIndex = i, e[i] = t, r.__cacheIndex = n, e[n] = r;
    }
    clipAction(t, e, n) {
        let i = e || this._root, r = i.uuid, a = typeof t == "string" ? is.findByName(i, t) : t, o = a !== null ? a.uuid : t, c = this._actionsByClip[o], l = null;
        if (n === void 0 && (a !== null ? n = a.blendMode : n = zc), c !== void 0) {
            let u = c.actionByRoot[r];
            if (u !== void 0 && u.blendMode === n) return u;
            l = c.knownActions[0], a === null && (a = l._clip);
        }
        if (a === null) return null;
        let h = new Dc(this, a, e, n);
        return this._bindAction(h, l), this._addInactiveAction(h, o, r), h;
    }
    existingAction(t, e) {
        let n = e || this._root, i = n.uuid, r = typeof t == "string" ? is.findByName(n, t) : t, a = r ? r.uuid : t, o = this._actionsByClip[a];
        return o !== void 0 && o.actionByRoot[i] || null;
    }
    stopAllAction() {
        let t = this._actions, e = this._nActiveActions;
        for(let n = e - 1; n >= 0; --n)t[n].stop();
        return this;
    }
    update(t) {
        t *= this.timeScale;
        let e = this._actions, n = this._nActiveActions, i = this.time += t, r = Math.sign(t), a = this._accuIndex ^= 1;
        for(let l = 0; l !== n; ++l)e[l]._update(i, t, r, a);
        let o = this._bindings, c = this._nActiveBindings;
        for(let l = 0; l !== c; ++l)o[l].apply(a);
        return this;
    }
    setTime(t) {
        this.time = 0;
        for(let e = 0; e < this._actions.length; e++)this._actions[e].time = 0;
        return this.update(t);
    }
    getRoot() {
        return this._root;
    }
    uncacheClip(t) {
        let e = this._actions, n = t.uuid, i = this._actionsByClip, r = i[n];
        if (r !== void 0) {
            let a = r.knownActions;
            for(let o = 0, c = a.length; o !== c; ++o){
                let l = a[o];
                this._deactivateAction(l);
                let h = l._cacheIndex, u = e[e.length - 1];
                l._cacheIndex = null, l._byClipCacheIndex = null, u._cacheIndex = h, e[h] = u, e.pop(), this._removeInactiveBindingsForAction(l);
            }
            delete i[n];
        }
    }
    uncacheRoot(t) {
        let e = t.uuid, n = this._actionsByClip;
        for(let a in n){
            let o = n[a].actionByRoot, c = o[e];
            c !== void 0 && (this._deactivateAction(c), this._removeInactiveAction(c));
        }
        let i = this._bindingsByRootAndName, r = i[e];
        if (r !== void 0) for(let a in r){
            let o = r[a];
            o.restoreOriginalState(), this._removeInactiveBinding(o);
        }
    }
    uncacheAction(t, e) {
        let n = this.existingAction(t, e);
        n !== null && (this._deactivateAction(n), this._removeInactiveAction(n));
    }
}, Eu = class s1 {
    constructor(t){
        this.value = t;
    }
    clone() {
        return new s1(this.value.clone === void 0 ? this.value : this.value.clone());
    }
}, Nx = 0, Tu = class extends sn {
    constructor(){
        super(), this.isUniformsGroup = !0, Object.defineProperty(this, "id", {
            value: Nx++
        }), this.name = "", this.usage = kr, this.uniforms = [];
    }
    add(t) {
        return this.uniforms.push(t), this;
    }
    remove(t) {
        let e = this.uniforms.indexOf(t);
        return e !== -1 && this.uniforms.splice(e, 1), this;
    }
    setName(t) {
        return this.name = t, this;
    }
    setUsage(t) {
        return this.usage = t, this;
    }
    dispose() {
        return this.dispatchEvent({
            type: "dispose"
        }), this;
    }
    copy(t) {
        this.name = t.name, this.usage = t.usage;
        let e = t.uniforms;
        this.uniforms.length = 0;
        for(let n = 0, i = e.length; n < i; n++)this.uniforms.push(e[n].clone());
        return this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, wu = class extends Is {
    constructor(t, e, n = 1){
        super(t, e), this.isInstancedInterleavedBuffer = !0, this.meshPerAttribute = n;
    }
    copy(t) {
        return super.copy(t), this.meshPerAttribute = t.meshPerAttribute, this;
    }
    clone(t) {
        let e = super.clone(t);
        return e.meshPerAttribute = this.meshPerAttribute, e;
    }
    toJSON(t) {
        let e = super.toJSON(t);
        return e.isInstancedInterleavedBuffer = !0, e.meshPerAttribute = this.meshPerAttribute, e;
    }
}, Au = class {
    constructor(t, e, n, i, r){
        this.isGLBufferAttribute = !0, this.name = "", this.buffer = t, this.type = e, this.itemSize = n, this.elementSize = i, this.count = r, this.version = 0;
    }
    set needsUpdate(t) {
        t === !0 && this.version++;
    }
    setBuffer(t) {
        return this.buffer = t, this;
    }
    setType(t, e) {
        return this.type = t, this.elementSize = e, this;
    }
    setItemSize(t) {
        return this.itemSize = t, this;
    }
    setCount(t) {
        return this.count = t, this;
    }
}, Ru = class {
    constructor(t, e, n = 0, i = 1 / 0){
        this.ray = new hi(t, e), this.near = n, this.far = i, this.camera = null, this.layers = new Rs, this.params = {
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
    set(t, e) {
        this.ray.set(t, e);
    }
    setFromCamera(t, e) {
        e.isPerspectiveCamera ? (this.ray.origin.setFromMatrixPosition(e.matrixWorld), this.ray.direction.set(t.x, t.y, .5).unproject(e).sub(this.ray.origin).normalize(), this.camera = e) : e.isOrthographicCamera ? (this.ray.origin.set(t.x, t.y, (e.near + e.far) / (e.near - e.far)).unproject(e), this.ray.direction.set(0, 0, -1).transformDirection(e.matrixWorld), this.camera = e) : console.error("THREE.Raycaster: Unsupported camera type: " + e.type);
    }
    intersectObject(t, e = !0, n = []) {
        return Nc(t, this, n, e), n.sort(Cu), n;
    }
    intersectObjects(t, e = !0, n = []) {
        for(let i = 0, r = t.length; i < r; i++)Nc(t[i], this, n, e);
        return n.sort(Cu), n;
    }
};
function Cu(s1, t) {
    return s1.distance - t.distance;
}
function Nc(s1, t, e, n) {
    if (s1.layers.test(t.layers) && s1.raycast(t, e), n === !0) {
        let i = s1.children;
        for(let r = 0, a = i.length; r < a; r++)Nc(i[r], t, e, !0);
    }
}
var Pu = class {
    constructor(t = 1, e = 0, n = 0){
        return this.radius = t, this.phi = e, this.theta = n, this;
    }
    set(t, e, n) {
        return this.radius = t, this.phi = e, this.theta = n, this;
    }
    copy(t) {
        return this.radius = t.radius, this.phi = t.phi, this.theta = t.theta, this;
    }
    makeSafe() {
        return this.phi = Math.max(1e-6, Math.min(Math.PI - 1e-6, this.phi)), this;
    }
    setFromVector3(t) {
        return this.setFromCartesianCoords(t.x, t.y, t.z);
    }
    setFromCartesianCoords(t, e, n) {
        return this.radius = Math.sqrt(t * t + e * e + n * n), this.radius === 0 ? (this.theta = 0, this.phi = 0) : (this.theta = Math.atan2(t, n), this.phi = Math.acos(ae(e / this.radius, -1, 1))), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Lu = class {
    constructor(t = 1, e = 0, n = 0){
        return this.radius = t, this.theta = e, this.y = n, this;
    }
    set(t, e, n) {
        return this.radius = t, this.theta = e, this.y = n, this;
    }
    copy(t) {
        return this.radius = t.radius, this.theta = t.theta, this.y = t.y, this;
    }
    setFromVector3(t) {
        return this.setFromCartesianCoords(t.x, t.y, t.z);
    }
    setFromCartesianCoords(t, e, n) {
        return this.radius = Math.sqrt(t * t + n * n), this.theta = Math.atan2(t, n), this.y = e, this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Iu = new J, Uu = class {
    constructor(t = new J(1 / 0, 1 / 0), e = new J(-1 / 0, -1 / 0)){
        this.isBox2 = !0, this.min = t, this.max = e;
    }
    set(t, e) {
        return this.min.copy(t), this.max.copy(e), this;
    }
    setFromPoints(t) {
        this.makeEmpty();
        for(let e = 0, n = t.length; e < n; e++)this.expandByPoint(t[e]);
        return this;
    }
    setFromCenterAndSize(t, e) {
        let n = Iu.copy(e).multiplyScalar(.5);
        return this.min.copy(t).sub(n), this.max.copy(t).add(n), this;
    }
    clone() {
        return new this.constructor().copy(this);
    }
    copy(t) {
        return this.min.copy(t.min), this.max.copy(t.max), this;
    }
    makeEmpty() {
        return this.min.x = this.min.y = 1 / 0, this.max.x = this.max.y = -1 / 0, this;
    }
    isEmpty() {
        return this.max.x < this.min.x || this.max.y < this.min.y;
    }
    getCenter(t) {
        return this.isEmpty() ? t.set(0, 0) : t.addVectors(this.min, this.max).multiplyScalar(.5);
    }
    getSize(t) {
        return this.isEmpty() ? t.set(0, 0) : t.subVectors(this.max, this.min);
    }
    expandByPoint(t) {
        return this.min.min(t), this.max.max(t), this;
    }
    expandByVector(t) {
        return this.min.sub(t), this.max.add(t), this;
    }
    expandByScalar(t) {
        return this.min.addScalar(-t), this.max.addScalar(t), this;
    }
    containsPoint(t) {
        return !(t.x < this.min.x || t.x > this.max.x || t.y < this.min.y || t.y > this.max.y);
    }
    containsBox(t) {
        return this.min.x <= t.min.x && t.max.x <= this.max.x && this.min.y <= t.min.y && t.max.y <= this.max.y;
    }
    getParameter(t, e) {
        return e.set((t.x - this.min.x) / (this.max.x - this.min.x), (t.y - this.min.y) / (this.max.y - this.min.y));
    }
    intersectsBox(t) {
        return !(t.max.x < this.min.x || t.min.x > this.max.x || t.max.y < this.min.y || t.min.y > this.max.y);
    }
    clampPoint(t, e) {
        return e.copy(t).clamp(this.min, this.max);
    }
    distanceToPoint(t) {
        return this.clampPoint(t, Iu).distanceTo(t);
    }
    intersect(t) {
        return this.min.max(t.min), this.max.min(t.max), this.isEmpty() && this.makeEmpty(), this;
    }
    union(t) {
        return this.min.min(t.min), this.max.max(t.max), this;
    }
    translate(t) {
        return this.min.add(t), this.max.add(t), this;
    }
    equals(t) {
        return t.min.equals(this.min) && t.max.equals(this.max);
    }
}, Du = new A, wr = new A, Nu = class {
    constructor(t = new A, e = new A){
        this.start = t, this.end = e;
    }
    set(t, e) {
        return this.start.copy(t), this.end.copy(e), this;
    }
    copy(t) {
        return this.start.copy(t.start), this.end.copy(t.end), this;
    }
    getCenter(t) {
        return t.addVectors(this.start, this.end).multiplyScalar(.5);
    }
    delta(t) {
        return t.subVectors(this.end, this.start);
    }
    distanceSq() {
        return this.start.distanceToSquared(this.end);
    }
    distance() {
        return this.start.distanceTo(this.end);
    }
    at(t, e) {
        return this.delta(e).multiplyScalar(t).add(this.start);
    }
    closestPointToPointParameter(t, e) {
        Du.subVectors(t, this.start), wr.subVectors(this.end, this.start);
        let n = wr.dot(wr), r = wr.dot(Du) / n;
        return e && (r = ae(r, 0, 1)), r;
    }
    closestPointToPoint(t, e, n) {
        let i = this.closestPointToPointParameter(t, e);
        return this.delta(n).multiplyScalar(i).add(this.start);
    }
    applyMatrix4(t) {
        return this.start.applyMatrix4(t), this.end.applyMatrix4(t), this;
    }
    equals(t) {
        return t.start.equals(this.start) && t.end.equals(this.end);
    }
    clone() {
        return new this.constructor().copy(this);
    }
}, Fu = new A, Ou = class extends Zt {
    constructor(t, e){
        super(), this.light = t, this.matrix = t.matrixWorld, this.matrixAutoUpdate = !1, this.color = e, this.type = "SpotLightHelper";
        let n = new Vt, i = [
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
        n.setAttribute("position", new _t(i, 3));
        let r = new Ee({
            fog: !1,
            toneMapped: !1
        });
        this.cone = new je(n, r), this.add(this.cone), this.update();
    }
    dispose() {
        this.cone.geometry.dispose(), this.cone.material.dispose();
    }
    update() {
        this.light.updateWorldMatrix(!0, !1), this.light.target.updateWorldMatrix(!0, !1);
        let t = this.light.distance ? this.light.distance : 1e3, e = t * Math.tan(this.light.angle);
        this.cone.scale.set(e, e, t), Fu.setFromMatrixPosition(this.light.target.matrixWorld), this.cone.lookAt(Fu), this.color !== void 0 ? this.cone.material.color.set(this.color) : this.cone.material.color.copy(this.light.color);
    }
}, Cn = new A, Ar = new Ot, so = new Ot, Bu = class extends je {
    constructor(t){
        let e = Cd(t), n = new Vt, i = [], r = [], a = new ft(0, 0, 1), o = new ft(0, 1, 0);
        for(let l = 0; l < e.length; l++){
            let h = e[l];
            h.parent && h.parent.isBone && (i.push(0, 0, 0), i.push(0, 0, 0), r.push(a.r, a.g, a.b), r.push(o.r, o.g, o.b));
        }
        n.setAttribute("position", new _t(i, 3)), n.setAttribute("color", new _t(r, 3));
        let c = new Ee({
            vertexColors: !0,
            depthTest: !1,
            depthWrite: !1,
            toneMapped: !1,
            transparent: !0
        });
        super(n, c), this.isSkeletonHelper = !0, this.type = "SkeletonHelper", this.root = t, this.bones = e, this.matrix = t.matrixWorld, this.matrixAutoUpdate = !1;
    }
    updateMatrixWorld(t) {
        let e = this.bones, n = this.geometry, i = n.getAttribute("position");
        so.copy(this.root.matrixWorld).invert();
        for(let r = 0, a = 0; r < e.length; r++){
            let o = e[r];
            o.parent && o.parent.isBone && (Ar.multiplyMatrices(so, o.matrixWorld), Cn.setFromMatrixPosition(Ar), i.setXYZ(a, Cn.x, Cn.y, Cn.z), Ar.multiplyMatrices(so, o.parent.matrixWorld), Cn.setFromMatrixPosition(Ar), i.setXYZ(a + 1, Cn.x, Cn.y, Cn.z), a += 2);
        }
        n.getAttribute("position").needsUpdate = !0, super.updateMatrixWorld(t);
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
};
function Cd(s1) {
    let t = [];
    s1.isBone === !0 && t.push(s1);
    for(let e = 0; e < s1.children.length; e++)t.push.apply(t, Cd(s1.children[e]));
    return t;
}
var zu = class extends ve {
    constructor(t, e, n){
        let i = new oa(e, 4, 2), r = new Mn({
            wireframe: !0,
            fog: !1,
            toneMapped: !1
        });
        super(i, r), this.light = t, this.color = n, this.type = "PointLightHelper", this.matrix = this.light.matrixWorld, this.matrixAutoUpdate = !1, this.update();
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
    update() {
        this.light.updateWorldMatrix(!0, !1), this.color !== void 0 ? this.material.color.set(this.color) : this.material.color.copy(this.light.color);
    }
}, Fx = new A, ku = new ft, Vu = new ft, Hu = class extends Zt {
    constructor(t, e, n){
        super(), this.light = t, this.matrix = t.matrixWorld, this.matrixAutoUpdate = !1, this.color = n, this.type = "HemisphereLightHelper";
        let i = new aa(e);
        i.rotateY(Math.PI * .5), this.material = new Mn({
            wireframe: !0,
            fog: !1,
            toneMapped: !1
        }), this.color === void 0 && (this.material.vertexColors = !0);
        let r = i.getAttribute("position"), a = new Float32Array(r.count * 3);
        i.setAttribute("color", new Kt(a, 3)), this.add(new ve(i, this.material)), this.update();
    }
    dispose() {
        this.children[0].geometry.dispose(), this.children[0].material.dispose();
    }
    update() {
        let t = this.children[0];
        if (this.color !== void 0) this.material.color.set(this.color);
        else {
            let e = t.geometry.getAttribute("color");
            ku.copy(this.light.color), Vu.copy(this.light.groundColor);
            for(let n = 0, i = e.count; n < i; n++){
                let r = n < i / 2 ? ku : Vu;
                e.setXYZ(n, r.r, r.g, r.b);
            }
            e.needsUpdate = !0;
        }
        this.light.updateWorldMatrix(!0, !1), t.lookAt(Fx.setFromMatrixPosition(this.light.matrixWorld).negate());
    }
}, Gu = class extends je {
    constructor(t = 10, e = 10, n = 4473924, i = 8947848){
        n = new ft(n), i = new ft(i);
        let r = e / 2, a = t / e, o = t / 2, c = [], l = [];
        for(let d = 0, f = 0, m = -o; d <= e; d++, m += a){
            c.push(-o, 0, m, o, 0, m), c.push(m, 0, -o, m, 0, o);
            let x = d === r ? n : i;
            x.toArray(l, f), f += 3, x.toArray(l, f), f += 3, x.toArray(l, f), f += 3, x.toArray(l, f), f += 3;
        }
        let h = new Vt;
        h.setAttribute("position", new _t(c, 3)), h.setAttribute("color", new _t(l, 3));
        let u = new Ee({
            vertexColors: !0,
            toneMapped: !1
        });
        super(h, u), this.type = "GridHelper";
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, Wu = class extends je {
    constructor(t = 10, e = 16, n = 8, i = 64, r = 4473924, a = 8947848){
        r = new ft(r), a = new ft(a);
        let o = [], c = [];
        if (e > 1) for(let u = 0; u < e; u++){
            let d = u / e * (Math.PI * 2), f = Math.sin(d) * t, m = Math.cos(d) * t;
            o.push(0, 0, 0), o.push(f, 0, m);
            let x = u & 1 ? r : a;
            c.push(x.r, x.g, x.b), c.push(x.r, x.g, x.b);
        }
        for(let u = 0; u < n; u++){
            let d = u & 1 ? r : a, f = t - t / n * u;
            for(let m = 0; m < i; m++){
                let x = m / i * (Math.PI * 2), g = Math.sin(x) * f, p = Math.cos(x) * f;
                o.push(g, 0, p), c.push(d.r, d.g, d.b), x = (m + 1) / i * (Math.PI * 2), g = Math.sin(x) * f, p = Math.cos(x) * f, o.push(g, 0, p), c.push(d.r, d.g, d.b);
            }
        }
        let l = new Vt;
        l.setAttribute("position", new _t(o, 3)), l.setAttribute("color", new _t(c, 3));
        let h = new Ee({
            vertexColors: !0,
            toneMapped: !1
        });
        super(l, h), this.type = "PolarGridHelper";
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, Xu = new A, Rr = new A, qu = new A, Yu = class extends Zt {
    constructor(t, e, n){
        super(), this.light = t, this.matrix = t.matrixWorld, this.matrixAutoUpdate = !1, this.color = n, this.type = "DirectionalLightHelper", e === void 0 && (e = 1);
        let i = new Vt;
        i.setAttribute("position", new _t([
            -e,
            e,
            0,
            e,
            e,
            0,
            e,
            -e,
            0,
            -e,
            -e,
            0,
            -e,
            e,
            0
        ], 3));
        let r = new Ee({
            fog: !1,
            toneMapped: !1
        });
        this.lightPlane = new Sn(i, r), this.add(this.lightPlane), i = new Vt, i.setAttribute("position", new _t([
            0,
            0,
            0,
            0,
            0,
            1
        ], 3)), this.targetLine = new Sn(i, r), this.add(this.targetLine), this.update();
    }
    dispose() {
        this.lightPlane.geometry.dispose(), this.lightPlane.material.dispose(), this.targetLine.geometry.dispose(), this.targetLine.material.dispose();
    }
    update() {
        this.light.updateWorldMatrix(!0, !1), this.light.target.updateWorldMatrix(!0, !1), Xu.setFromMatrixPosition(this.light.matrixWorld), Rr.setFromMatrixPosition(this.light.target.matrixWorld), qu.subVectors(Rr, Xu), this.lightPlane.lookAt(Rr), this.color !== void 0 ? (this.lightPlane.material.color.set(this.color), this.targetLine.material.color.set(this.color)) : (this.lightPlane.material.color.copy(this.light.color), this.targetLine.material.color.copy(this.light.color)), this.targetLine.lookAt(Rr), this.targetLine.scale.z = qu.length();
    }
}, Cr = new A, re = new Cs, Zu = class extends je {
    constructor(t){
        let e = new Vt, n = new Ee({
            color: 16777215,
            vertexColors: !0,
            toneMapped: !1
        }), i = [], r = [], a = {};
        o("n1", "n2"), o("n2", "n4"), o("n4", "n3"), o("n3", "n1"), o("f1", "f2"), o("f2", "f4"), o("f4", "f3"), o("f3", "f1"), o("n1", "f1"), o("n2", "f2"), o("n3", "f3"), o("n4", "f4"), o("p", "n1"), o("p", "n2"), o("p", "n3"), o("p", "n4"), o("u1", "u2"), o("u2", "u3"), o("u3", "u1"), o("c", "t"), o("p", "c"), o("cn1", "cn2"), o("cn3", "cn4"), o("cf1", "cf2"), o("cf3", "cf4");
        function o(m, x) {
            c(m), c(x);
        }
        function c(m) {
            i.push(0, 0, 0), r.push(0, 0, 0), a[m] === void 0 && (a[m] = []), a[m].push(i.length / 3 - 1);
        }
        e.setAttribute("position", new _t(i, 3)), e.setAttribute("color", new _t(r, 3)), super(e, n), this.type = "CameraHelper", this.camera = t, this.camera.updateProjectionMatrix && this.camera.updateProjectionMatrix(), this.matrix = t.matrixWorld, this.matrixAutoUpdate = !1, this.pointMap = a, this.update();
        let l = new ft(16755200), h = new ft(16711680), u = new ft(43775), d = new ft(16777215), f = new ft(3355443);
        this.setColors(l, h, u, d, f);
    }
    setColors(t, e, n, i, r) {
        let o = this.geometry.getAttribute("color");
        o.setXYZ(0, t.r, t.g, t.b), o.setXYZ(1, t.r, t.g, t.b), o.setXYZ(2, t.r, t.g, t.b), o.setXYZ(3, t.r, t.g, t.b), o.setXYZ(4, t.r, t.g, t.b), o.setXYZ(5, t.r, t.g, t.b), o.setXYZ(6, t.r, t.g, t.b), o.setXYZ(7, t.r, t.g, t.b), o.setXYZ(8, t.r, t.g, t.b), o.setXYZ(9, t.r, t.g, t.b), o.setXYZ(10, t.r, t.g, t.b), o.setXYZ(11, t.r, t.g, t.b), o.setXYZ(12, t.r, t.g, t.b), o.setXYZ(13, t.r, t.g, t.b), o.setXYZ(14, t.r, t.g, t.b), o.setXYZ(15, t.r, t.g, t.b), o.setXYZ(16, t.r, t.g, t.b), o.setXYZ(17, t.r, t.g, t.b), o.setXYZ(18, t.r, t.g, t.b), o.setXYZ(19, t.r, t.g, t.b), o.setXYZ(20, t.r, t.g, t.b), o.setXYZ(21, t.r, t.g, t.b), o.setXYZ(22, t.r, t.g, t.b), o.setXYZ(23, t.r, t.g, t.b), o.setXYZ(24, e.r, e.g, e.b), o.setXYZ(25, e.r, e.g, e.b), o.setXYZ(26, e.r, e.g, e.b), o.setXYZ(27, e.r, e.g, e.b), o.setXYZ(28, e.r, e.g, e.b), o.setXYZ(29, e.r, e.g, e.b), o.setXYZ(30, e.r, e.g, e.b), o.setXYZ(31, e.r, e.g, e.b), o.setXYZ(32, n.r, n.g, n.b), o.setXYZ(33, n.r, n.g, n.b), o.setXYZ(34, n.r, n.g, n.b), o.setXYZ(35, n.r, n.g, n.b), o.setXYZ(36, n.r, n.g, n.b), o.setXYZ(37, n.r, n.g, n.b), o.setXYZ(38, i.r, i.g, i.b), o.setXYZ(39, i.r, i.g, i.b), o.setXYZ(40, r.r, r.g, r.b), o.setXYZ(41, r.r, r.g, r.b), o.setXYZ(42, r.r, r.g, r.b), o.setXYZ(43, r.r, r.g, r.b), o.setXYZ(44, r.r, r.g, r.b), o.setXYZ(45, r.r, r.g, r.b), o.setXYZ(46, r.r, r.g, r.b), o.setXYZ(47, r.r, r.g, r.b), o.setXYZ(48, r.r, r.g, r.b), o.setXYZ(49, r.r, r.g, r.b), o.needsUpdate = !0;
    }
    update() {
        let t = this.geometry, e = this.pointMap, n = 1, i = 1;
        re.projectionMatrixInverse.copy(this.camera.projectionMatrixInverse), ce("c", e, t, re, 0, 0, -1), ce("t", e, t, re, 0, 0, 1), ce("n1", e, t, re, -n, -i, -1), ce("n2", e, t, re, n, -i, -1), ce("n3", e, t, re, -n, i, -1), ce("n4", e, t, re, n, i, -1), ce("f1", e, t, re, -n, -i, 1), ce("f2", e, t, re, n, -i, 1), ce("f3", e, t, re, -n, i, 1), ce("f4", e, t, re, n, i, 1), ce("u1", e, t, re, n * .7, i * 1.1, -1), ce("u2", e, t, re, -n * .7, i * 1.1, -1), ce("u3", e, t, re, 0, i * 2, -1), ce("cf1", e, t, re, -n, 0, 1), ce("cf2", e, t, re, n, 0, 1), ce("cf3", e, t, re, 0, -i, 1), ce("cf4", e, t, re, 0, i, 1), ce("cn1", e, t, re, -n, 0, -1), ce("cn2", e, t, re, n, 0, -1), ce("cn3", e, t, re, 0, -i, -1), ce("cn4", e, t, re, 0, i, -1), t.getAttribute("position").needsUpdate = !0;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
};
function ce(s1, t, e, n, i, r, a) {
    Cr.set(i, r, a).unproject(n);
    let o = t[s1];
    if (o !== void 0) {
        let c = e.getAttribute("position");
        for(let l = 0, h = o.length; l < h; l++)c.setXYZ(o[l], Cr.x, Cr.y, Cr.z);
    }
}
var Pr = new Ke, Ju = class extends je {
    constructor(t, e = 16776960){
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
        ]), i = new Float32Array(8 * 3), r = new Vt;
        r.setIndex(new Kt(n, 1)), r.setAttribute("position", new Kt(i, 3)), super(r, new Ee({
            color: e,
            toneMapped: !1
        })), this.object = t, this.type = "BoxHelper", this.matrixAutoUpdate = !1, this.update();
    }
    update(t) {
        if (t !== void 0 && console.warn("THREE.BoxHelper: .update() has no longer arguments."), this.object !== void 0 && Pr.setFromObject(this.object), Pr.isEmpty()) return;
        let e = Pr.min, n = Pr.max, i = this.geometry.attributes.position, r = i.array;
        r[0] = n.x, r[1] = n.y, r[2] = n.z, r[3] = e.x, r[4] = n.y, r[5] = n.z, r[6] = e.x, r[7] = e.y, r[8] = n.z, r[9] = n.x, r[10] = e.y, r[11] = n.z, r[12] = n.x, r[13] = n.y, r[14] = e.z, r[15] = e.x, r[16] = n.y, r[17] = e.z, r[18] = e.x, r[19] = e.y, r[20] = e.z, r[21] = n.x, r[22] = e.y, r[23] = e.z, i.needsUpdate = !0, this.geometry.computeBoundingSphere();
    }
    setFromObject(t) {
        return this.object = t, this.update(), this;
    }
    copy(t, e) {
        return super.copy(t, e), this.object = t.object, this;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, $u = class extends je {
    constructor(t, e = 16776960){
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
        ], r = new Vt;
        r.setIndex(new Kt(n, 1)), r.setAttribute("position", new _t(i, 3)), super(r, new Ee({
            color: e,
            toneMapped: !1
        })), this.box = t, this.type = "Box3Helper", this.geometry.computeBoundingSphere();
    }
    updateMatrixWorld(t) {
        let e = this.box;
        e.isEmpty() || (e.getCenter(this.position), e.getSize(this.scale), this.scale.multiplyScalar(.5), super.updateMatrixWorld(t));
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, Ku = class extends Sn {
    constructor(t, e = 1, n = 16776960){
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
        ], a = new Vt;
        a.setAttribute("position", new _t(r, 3)), a.computeBoundingSphere(), super(a, new Ee({
            color: i,
            toneMapped: !1
        })), this.type = "PlaneHelper", this.plane = t, this.size = e;
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
        ], c = new Vt;
        c.setAttribute("position", new _t(o, 3)), c.computeBoundingSphere(), this.add(new ve(c, new Mn({
            color: i,
            opacity: .2,
            transparent: !0,
            depthWrite: !1,
            toneMapped: !1
        })));
    }
    updateMatrixWorld(t) {
        this.position.set(0, 0, 0), this.scale.set(.5 * this.size, .5 * this.size, 1), this.lookAt(this.plane.normal), this.translateZ(-this.plane.constant), super.updateMatrixWorld(t);
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose(), this.children[0].geometry.dispose(), this.children[0].material.dispose();
    }
}, Qu = new A, Lr, ro, ju = class extends Zt {
    constructor(t = new A(0, 0, 1), e = new A(0, 0, 0), n = 1, i = 16776960, r = n * .2, a = r * .2){
        super(), this.type = "ArrowHelper", Lr === void 0 && (Lr = new Vt, Lr.setAttribute("position", new _t([
            0,
            0,
            0,
            0,
            1,
            0
        ], 3)), ro = new Fs(0, .5, 1, 5, 1), ro.translate(0, -.5, 0)), this.position.copy(e), this.line = new Sn(Lr, new Ee({
            color: i,
            toneMapped: !1
        })), this.line.matrixAutoUpdate = !1, this.add(this.line), this.cone = new ve(ro, new Mn({
            color: i,
            toneMapped: !1
        })), this.cone.matrixAutoUpdate = !1, this.add(this.cone), this.setDirection(t), this.setLength(n, r, a);
    }
    setDirection(t) {
        if (t.y > .99999) this.quaternion.set(0, 0, 0, 1);
        else if (t.y < -.99999) this.quaternion.set(1, 0, 0, 0);
        else {
            Qu.set(t.z, 0, -t.x).normalize();
            let e = Math.acos(t.y);
            this.quaternion.setFromAxisAngle(Qu, e);
        }
    }
    setLength(t, e = t * .2, n = e * .2) {
        this.line.scale.set(1, Math.max(1e-4, t - e), 1), this.line.updateMatrix(), this.cone.scale.set(n, e, n), this.cone.position.y = t, this.cone.updateMatrix();
    }
    setColor(t) {
        this.line.material.color.set(t), this.cone.material.color.set(t);
    }
    copy(t) {
        return super.copy(t, !1), this.line.copy(t.line), this.cone.copy(t.cone), this;
    }
    dispose() {
        this.line.geometry.dispose(), this.line.material.dispose(), this.cone.geometry.dispose(), this.cone.material.dispose();
    }
}, td = class extends je {
    constructor(t = 1){
        let e = [
            0,
            0,
            0,
            t,
            0,
            0,
            0,
            0,
            0,
            0,
            t,
            0,
            0,
            0,
            0,
            0,
            0,
            t
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
        ], i = new Vt;
        i.setAttribute("position", new _t(e, 3)), i.setAttribute("color", new _t(n, 3));
        let r = new Ee({
            vertexColors: !0,
            toneMapped: !1
        });
        super(i, r), this.type = "AxesHelper";
    }
    setColors(t, e, n) {
        let i = new ft, r = this.geometry.attributes.color.array;
        return i.set(t), i.toArray(r, 0), i.toArray(r, 3), i.set(e), i.toArray(r, 6), i.toArray(r, 9), i.set(n), i.toArray(r, 12), i.toArray(r, 15), this.geometry.attributes.color.needsUpdate = !0, this;
    }
    dispose() {
        this.geometry.dispose(), this.material.dispose();
    }
}, ed = class {
    constructor(){
        this.type = "ShapePath", this.color = new ft, this.subPaths = [], this.currentPath = null;
    }
    moveTo(t, e) {
        return this.currentPath = new ji, this.subPaths.push(this.currentPath), this.currentPath.moveTo(t, e), this;
    }
    lineTo(t, e) {
        return this.currentPath.lineTo(t, e), this;
    }
    quadraticCurveTo(t, e, n, i) {
        return this.currentPath.quadraticCurveTo(t, e, n, i), this;
    }
    bezierCurveTo(t, e, n, i, r, a) {
        return this.currentPath.bezierCurveTo(t, e, n, i, r, a), this;
    }
    splineThru(t) {
        return this.currentPath.splineThru(t), this;
    }
    toShapes(t) {
        function e(p) {
            let v = [];
            for(let _ = 0, y = p.length; _ < y; _++){
                let b = p[_], w = new Fn;
                w.curves = b.curves, v.push(w);
            }
            return v;
        }
        function n(p, v) {
            let _ = v.length, y = !1;
            for(let b = _ - 1, w = 0; w < _; b = w++){
                let R = v[b], L = v[w], M = L.x - R.x, E = L.y - R.y;
                if (Math.abs(E) > Number.EPSILON) {
                    if (E < 0 && (R = v[w], M = -M, L = v[b], E = -E), p.y < R.y || p.y > L.y) continue;
                    if (p.y === R.y) {
                        if (p.x === R.x) return !0;
                    } else {
                        let V = E * (p.x - R.x) - M * (p.y - R.y);
                        if (V === 0) return !0;
                        if (V < 0) continue;
                        y = !y;
                    }
                } else {
                    if (p.y !== R.y) continue;
                    if (L.x <= p.x && p.x <= R.x || R.x <= p.x && p.x <= L.x) return !0;
                }
            }
            return y;
        }
        let i = yn.isClockWise, r = this.subPaths;
        if (r.length === 0) return [];
        let a, o, c, l = [];
        if (r.length === 1) return o = r[0], c = new Fn, c.curves = o.curves, l.push(c), l;
        let h = !i(r[0].getPoints());
        h = t ? !h : h;
        let u = [], d = [], f = [], m = 0, x;
        d[m] = void 0, f[m] = [];
        for(let p = 0, v = r.length; p < v; p++)o = r[p], x = o.getPoints(), a = i(x), a = t ? !a : a, a ? (!h && d[m] && m++, d[m] = {
            s: new Fn,
            p: x
        }, d[m].s.curves = o.curves, h && m++, f[m] = []) : f[m].push({
            h: o,
            p: x[0]
        });
        if (!d[0]) return e(r);
        if (d.length > 1) {
            let p = !1, v = 0;
            for(let _ = 0, y = d.length; _ < y; _++)u[_] = [];
            for(let _ = 0, y = d.length; _ < y; _++){
                let b = f[_];
                for(let w = 0; w < b.length; w++){
                    let R = b[w], L = !0;
                    for(let M = 0; M < d.length; M++)n(R.p, d[M].p) && (_ !== M && v++, L ? (L = !1, u[M].push(R)) : p = !0);
                    L && u[_].push(R);
                }
            }
            v > 0 && p === !1 && (f = u);
        }
        let g;
        for(let p = 0, v = d.length; p < v; p++){
            c = d[p].s, l.push(c), g = f[p];
            for(let _ = 0, y = g.length; _ < y; _++)c.holes.push(g[_].h);
        }
        return l;
    }
};
typeof __THREE_DEVTOOLS__ < "u" && __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register", {
    detail: {
        revision: Fc
    }
}));
typeof window < "u" && (window.__THREE__ ? console.warn("WARNING: Multiple instances of Three.js being imported.") : window.__THREE__ = Fc);
const mod = {
    ACESFilmicToneMapping: lf,
    AddEquation: Bi,
    AddOperation: rf,
    AdditiveAnimationBlendMode: dd,
    AdditiveBlending: el,
    AlphaFormat: ff,
    AlwaysCompare: Df,
    AlwaysDepth: Kd,
    AlwaysStencilFunc: wf,
    AmbientLight: Ec,
    AmbientLightProbe: du,
    AnimationAction: Dc,
    AnimationClip: is,
    AnimationLoader: Qh,
    AnimationMixer: bu,
    AnimationObjectGroup: Su,
    AnimationUtils: yv,
    ArcCurve: Fo,
    ArrayCamera: yo,
    ArrowHelper: ju,
    Audio: Lc,
    AudioAnalyser: Mu,
    AudioContext: fa,
    AudioListener: xu,
    AudioLoader: hu,
    AxesHelper: td,
    BackSide: De,
    BasicDepthPacking: bf,
    BasicShadowMap: kx,
    Bone: jr,
    BooleanKeyframeTrack: zn,
    Box2: Uu,
    Box3: Ke,
    Box3Helper: $u,
    BoxGeometry: Ji,
    BoxHelper: Ju,
    BufferAttribute: Kt,
    BufferGeometry: Vt,
    BufferGeometryLoader: Cc,
    ByteType: uf,
    Cache: ss,
    Camera: Cs,
    CameraHelper: Zu,
    CanvasTexture: Xh,
    CapsuleGeometry: Vo,
    CatmullRomCurve3: Oo,
    CineonToneMapping: cf,
    CircleGeometry: Ho,
    ClampToEdgeWrapping: Ce,
    Clock: Pc,
    Color: ft,
    ColorKeyframeTrack: ha,
    ColorManagement: Ye,
    CompressedArrayTexture: Gh,
    CompressedCubeTexture: Wh,
    CompressedTexture: Us,
    CompressedTextureLoader: jh,
    ConeGeometry: Go,
    CubeCamera: uo,
    CubeReflectionMapping: Bn,
    CubeRefractionMapping: ci,
    CubeTexture: Ki,
    CubeTextureLoader: tu,
    CubeUVReflectionMapping: Hs,
    CubicBezierCurve: ea,
    CubicBezierCurve3: Bo,
    CubicInterpolant: fc,
    CullFaceBack: tl,
    CullFaceFront: Fd,
    CullFaceFrontBack: zx,
    CullFaceNone: Nd,
    Curve: Xe,
    CurvePath: ko,
    CustomBlending: Bd,
    CustomToneMapping: hf,
    CylinderGeometry: Fs,
    Cylindrical: Lu,
    Data3DTexture: Wr,
    DataArrayTexture: As,
    DataTexture: oi,
    DataTextureLoader: eu,
    DataUtils: vv,
    DecrementStencilOp: Qx,
    DecrementWrapStencilOp: tv,
    DefaultLoadingManager: Sx,
    DepthFormat: ii,
    DepthStencilFormat: Yi,
    DepthTexture: Mo,
    DirectionalLight: bc,
    DirectionalLightHelper: Yu,
    DiscreteInterpolant: pc,
    DisplayP3ColorSpace: pd,
    DodecahedronGeometry: Wo,
    DoubleSide: gn,
    DstAlphaFactor: Xd,
    DstColorFactor: Yd,
    DynamicCopyUsage: mv,
    DynamicDrawUsage: lv,
    DynamicReadUsage: dv,
    EdgesGeometry: Xo,
    EllipseCurve: Ds,
    EqualCompare: Cf,
    EqualDepth: jd,
    EqualStencilFunc: sv,
    EquirectangularReflectionMapping: Ur,
    EquirectangularRefractionMapping: Dr,
    Euler: Xr,
    EventDispatcher: sn,
    ExtrudeGeometry: Zo,
    FileLoader: rn,
    Float16BufferAttribute: Jl,
    Float32BufferAttribute: _t,
    Float64BufferAttribute: $l,
    FloatType: xn,
    Fog: wo,
    FogExp2: To,
    FramebufferTexture: Hh,
    FrontSide: On,
    Frustum: Ps,
    GLBufferAttribute: Au,
    GLSL1: _v,
    GLSL3: Cl,
    GreaterCompare: Lf,
    GreaterDepth: ef,
    GreaterEqualCompare: Uf,
    GreaterEqualDepth: tf,
    GreaterEqualStencilFunc: cv,
    GreaterStencilFunc: av,
    GridHelper: Gu,
    Group: ti,
    HalfFloatType: Ts,
    HemisphereLight: _c,
    HemisphereLightHelper: Hu,
    HemisphereLightProbe: uu,
    IcosahedronGeometry: Jo,
    ImageBitmapLoader: lu,
    ImageLoader: rs,
    ImageUtils: Gr,
    IncrementStencilOp: Kx,
    IncrementWrapStencilOp: jx,
    InstancedBufferAttribute: ui,
    InstancedBufferGeometry: Rc,
    InstancedInterleavedBuffer: wu,
    InstancedMesh: Io,
    Int16BufferAttribute: Yl,
    Int32BufferAttribute: Zl,
    Int8BufferAttribute: Wl,
    IntType: ad,
    InterleavedBuffer: Is,
    InterleavedBufferAttribute: Qi,
    Interpolant: ts,
    InterpolateDiscrete: Or,
    InterpolateLinear: Br,
    InterpolateSmooth: wa,
    InvertStencilOp: ev,
    KeepStencilOp: Aa,
    KeyframeTrack: qe,
    LOD: Co,
    LatheGeometry: ra,
    Layers: Rs,
    LessCompare: Rf,
    LessDepth: Qd,
    LessEqualCompare: Pf,
    LessEqualDepth: ao,
    LessEqualStencilFunc: rv,
    LessStencilFunc: iv,
    Light: bn,
    LightProbe: Vs,
    Line: Sn,
    Line3: Nu,
    LineBasicMaterial: Ee,
    LineCurve: Ns,
    LineCurve3: zo,
    LineDashedMaterial: uc,
    LineLoop: Uo,
    LineSegments: je,
    LinearEncoding: fd,
    LinearFilter: pe,
    LinearInterpolant: la,
    LinearMipMapLinearFilter: Xx,
    LinearMipMapNearestFilter: Wx,
    LinearMipmapLinearFilter: li,
    LinearMipmapNearestFilter: rd,
    LinearSRGBColorSpace: nn,
    LinearToneMapping: af,
    Loader: Le,
    LoaderUtils: da,
    LoadingManager: ua,
    LoopOnce: yf,
    LoopPingPong: Sf,
    LoopRepeat: Mf,
    LuminanceAlphaFormat: mf,
    LuminanceFormat: pf,
    MOUSE: Ox,
    Material: Me,
    MaterialLoader: Ac,
    MathUtils: xv,
    Matrix3: kt,
    Matrix4: Ot,
    MaxEquation: rl,
    Mesh: ve,
    MeshBasicMaterial: Mn,
    MeshDepthMaterial: $r,
    MeshDistanceMaterial: Kr,
    MeshLambertMaterial: lc,
    MeshMatcapMaterial: hc,
    MeshNormalMaterial: cc,
    MeshPhongMaterial: ac,
    MeshPhysicalMaterial: rc,
    MeshStandardMaterial: ca,
    MeshToonMaterial: oc,
    MinEquation: sl,
    MirroredRepeatWrapping: Fr,
    MixOperation: sf,
    MultiplyBlending: il,
    MultiplyOperation: pa,
    NearestFilter: fe,
    NearestMipMapLinearFilter: Gx,
    NearestMipMapNearestFilter: Hx,
    NearestMipmapLinearFilter: Ir,
    NearestMipmapNearestFilter: oo,
    NeverCompare: Af,
    NeverDepth: $d,
    NeverStencilFunc: nv,
    NoBlending: Un,
    NoColorSpace: ri,
    NoToneMapping: Dn,
    NormalAnimationBlendMode: zc,
    NormalBlending: Wi,
    NotEqualCompare: If,
    NotEqualDepth: nf,
    NotEqualStencilFunc: ov,
    NumberKeyframeTrack: es,
    Object3D: Zt,
    ObjectLoader: au,
    ObjectSpaceNormalMap: Tf,
    OctahedronGeometry: aa,
    OneFactor: Hd,
    OneMinusDstAlphaFactor: qd,
    OneMinusDstColorFactor: Zd,
    OneMinusSrcAlphaFactor: sd,
    OneMinusSrcColorFactor: Wd,
    OrthographicCamera: Ls,
    PCFShadowMap: nd,
    PCFSoftShadowMap: Od,
    PMREMGenerator: Jr,
    Path: ji,
    PerspectiveCamera: xe,
    Plane: mn,
    PlaneGeometry: Zr,
    PlaneHelper: Ku,
    PointLight: Mc,
    PointLightHelper: zu,
    Points: No,
    PointsMaterial: ta,
    PolarGridHelper: Wu,
    PolyhedronGeometry: di,
    PositionalAudio: yu,
    PropertyBinding: Jt,
    PropertyMixer: Ic,
    QuadraticBezierCurve: na,
    QuadraticBezierCurve3: ia,
    Quaternion: Pe,
    QuaternionKeyframeTrack: pi,
    QuaternionLinearInterpolant: mc,
    RED_GREEN_RGTC2_Format: Al,
    RED_RGTC1_Format: vf,
    REVISION: Fc,
    RGBADepthPacking: Ef,
    RGBAFormat: He,
    RGBAIntegerFormat: ud,
    RGBA_ASTC_10x10_Format: bl,
    RGBA_ASTC_10x5_Format: yl,
    RGBA_ASTC_10x6_Format: Ml,
    RGBA_ASTC_10x8_Format: Sl,
    RGBA_ASTC_12x10_Format: El,
    RGBA_ASTC_12x12_Format: Tl,
    RGBA_ASTC_4x4_Format: dl,
    RGBA_ASTC_5x4_Format: fl,
    RGBA_ASTC_5x5_Format: pl,
    RGBA_ASTC_6x5_Format: ml,
    RGBA_ASTC_6x6_Format: gl,
    RGBA_ASTC_8x5_Format: _l,
    RGBA_ASTC_8x6_Format: xl,
    RGBA_ASTC_8x8_Format: vl,
    RGBA_BPTC_Format: Ta,
    RGBA_ETC2_EAC_Format: ul,
    RGBA_PVRTC_2BPPV1_Format: ll,
    RGBA_PVRTC_4BPPV1_Format: cl,
    RGBA_S3TC_DXT1_Format: Sa,
    RGBA_S3TC_DXT3_Format: ba,
    RGBA_S3TC_DXT5_Format: Ea,
    RGB_ETC1_Format: xf,
    RGB_ETC2_Format: hl,
    RGB_PVRTC_2BPPV1_Format: ol,
    RGB_PVRTC_4BPPV1_Format: al,
    RGB_S3TC_DXT1_Format: Ma,
    RGFormat: _f,
    RGIntegerFormat: hd,
    RawShaderMaterial: sc,
    Ray: hi,
    Raycaster: Ru,
    RectAreaLight: Tc,
    RedFormat: gf,
    RedIntegerFormat: ld,
    ReinhardToneMapping: of,
    RenderTarget: ho,
    RepeatWrapping: Nr,
    ReplaceStencilOp: $x,
    ReverseSubtractEquation: kd,
    RingGeometry: $o,
    SIGNED_RED_GREEN_RGTC2_Format: Rl,
    SIGNED_RED_RGTC1_Format: wl,
    SRGBColorSpace: Nt,
    Scene: Ao,
    ShaderChunk: zt,
    ShaderLib: en,
    ShaderMaterial: Qe,
    ShadowMaterial: ic,
    Shape: Fn,
    ShapeGeometry: Ko,
    ShapePath: ed,
    ShapeUtils: yn,
    ShortType: df,
    Skeleton: Lo,
    SkeletonHelper: Bu,
    SkinnedMesh: Po,
    Source: Ln,
    Sphere: We,
    SphereGeometry: oa,
    Spherical: Pu,
    SphericalHarmonics3: wc,
    SplineCurve: sa,
    SpotLight: vc,
    SpotLightHelper: Ou,
    Sprite: Ro,
    SpriteMaterial: Qr,
    SrcAlphaFactor: id,
    SrcAlphaSaturateFactor: Jd,
    SrcColorFactor: Gd,
    StaticCopyUsage: pv,
    StaticDrawUsage: kr,
    StaticReadUsage: uv,
    StereoCamera: mu,
    StreamCopyUsage: gv,
    StreamDrawUsage: hv,
    StreamReadUsage: fv,
    StringKeyframeTrack: kn,
    SubtractEquation: zd,
    SubtractiveBlending: nl,
    TOUCH: Bx,
    TangentSpaceNormalMap: mi,
    TetrahedronGeometry: Qo,
    Texture: ye,
    TextureLoader: nu,
    TorusGeometry: jo,
    TorusKnotGeometry: tc,
    Triangle: In,
    TriangleFanDrawMode: Zx,
    TriangleStripDrawMode: Yx,
    TrianglesDrawMode: qx,
    TubeGeometry: ec,
    TwoPassDoubleSide: Vx,
    UVMapping: Oc,
    Uint16BufferAttribute: qr,
    Uint32BufferAttribute: Yr,
    Uint8BufferAttribute: Xl,
    Uint8ClampedBufferAttribute: ql,
    Uniform: Eu,
    UniformsGroup: Tu,
    UniformsLib: ct,
    UniformsUtils: mp,
    UnsignedByteType: Nn,
    UnsignedInt248Type: ni,
    UnsignedIntType: Pn,
    UnsignedShort4444Type: od,
    UnsignedShort5551Type: cd,
    UnsignedShortType: Bc,
    VSMShadowMap: pn,
    Vector2: J,
    Vector3: A,
    Vector4: $t,
    VectorKeyframeTrack: ns,
    VideoTexture: Vh,
    WebGL1Renderer: Eo,
    WebGL3DRenderTarget: Ul,
    WebGLArrayRenderTarget: Il,
    WebGLCoordinateSystem: vn,
    WebGLCubeRenderTarget: fo,
    WebGLMultipleRenderTargets: Dl,
    WebGLRenderTarget: Ge,
    WebGLRenderer: bo,
    WebGLUtils: O0,
    WebGPUCoordinateSystem: Vr,
    WireframeGeometry: nc,
    WrapAroundEnding: zr,
    ZeroCurvatureEnding: zi,
    ZeroFactor: Vd,
    ZeroSlopeEnding: ki,
    ZeroStencilOp: Jx,
    _SRGBAFormat: co,
    sRGBEncoding: si
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
    return new Ot();
}
function in_scene(scene, mouse_event) {
    const [x, y] = events2unitless(scene.screen, mouse_event);
    const [sx, sy, sw, sh] = scene.pixelarea.value;
    return x >= sx && x < sx + sw && y >= sy && y < sy + sh;
}
function attach_3d_camera(canvas, makie_camera, cam3d, light_dir, scene) {
    if (cam3d === undefined) {
        return;
    }
    const [w, h] = makie_camera.resolution.value;
    const camera = new xe(cam3d.fov, w / h, cam3d.near, cam3d.far);
    const center = new A(...cam3d.lookat);
    camera.up = new A(...cam3d.upvector);
    camera.position.set(...cam3d.eyeposition);
    camera.lookAt(center);
    function update() {
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
    }
    cam3d.resolution.on(update);
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
        this.view = new Eu(Identity4x4());
        this.projection = new Eu(Identity4x4());
        this.projectionview = new Eu(Identity4x4());
        this.pixel_space = new Eu(Identity4x4());
        this.pixel_space_inverse = new Eu(Identity4x4());
        this.projectionview_inverse = new Eu(Identity4x4());
        this.relative_space = new Eu(relative_space());
        this.relative_inverse = new Eu(relative_space().invert());
        this.clip_space = new Eu(Identity4x4());
        this.resolution = new Eu(new J());
        this.eyeposition = new Eu(new A());
        this.preprojections = {};
        this.light_direction = new Eu(new A(-1, -1, -1).normalize());
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
        const T = new kt().setFromMatrix4(this.view.value).invert();
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
            const uniform = new Eu(matrix);
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
    console.log(`deleting plots!: ${plot_uuids}`);
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
function linesegments_vertex_shader(uniforms, attributes) {
    const attribute_decl = attributes_to_type_declaration(attributes);
    const uniform_decl = uniforms_to_type_declaration(uniforms);
    const color = attribute_type(attributes.color_start) || uniform_type(uniforms.color_start);
    return `precision mediump int;
        precision highp float;

        ${attribute_decl}
        ${uniform_decl}

        out vec2 f_uv;
        out ${color} f_color;

        vec2 get_resolution() {
            // 2 * px_per_unit doesn't make any sense, but works
            // TODO, figure out what's going on!
            return resolution / 2.0 * px_per_unit;
        }

        vec3 screen_space(vec3 point) {
            vec4 vertex = projectionview * model * vec4(point, 1);
            return vec3(vertex.xy * get_resolution() , vertex.z) / vertex.w;
        }

        vec3 screen_space(vec2 point) {
            return screen_space(vec3(point, 0));
        }

        void main() {
            vec3 p_a = screen_space(linepoint_start);
            vec3 p_b = screen_space(linepoint_end);
            float width = (px_per_unit * (position.x == 1.0 ? linewidth_end : linewidth_start));
            f_color = position.x == 1.0 ? color_end : color_start;
            f_uv = vec2(position.x, position.y + 0.5);

            vec2 pointA = p_a.xy;
            vec2 pointB = p_b.xy;

            vec2 xBasis = pointB - pointA;
            vec2 yBasis = normalize(vec2(-xBasis.y, xBasis.x));
            vec2 point = pointA + xBasis * position.x + yBasis * width * position.y;

            gl_Position = vec4(point.xy / get_resolution(), p_a.z, 1.0);
        }
        `;
}
function lines_fragment_shader(uniforms, attributes) {
    const color = attribute_type(attributes.color_start) || uniform_type(uniforms.color_start);
    const color_uniforms = filter_by_key(uniforms, [
        "colorrange",
        "colormap",
        "nan_color",
        "highclip",
        "lowclip"
    ]);
    const uniform_decl = uniforms_to_type_declaration(color_uniforms);
    return `#extension GL_OES_standard_derivatives : enable

    precision mediump int;
    precision highp float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    in vec2 f_uv;
    in ${color} f_color;
    ${uniform_decl}

    out vec4 fragment_color;

    // Half width of antialiasing smoothstep
    #define ANTIALIAS_RADIUS 0.7071067811865476

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

    float aastep(float threshold, float value) {
        float afwidth = length(vec2(dFdx(value), dFdy(value))) * ANTIALIAS_RADIUS;
        return smoothstep(threshold-afwidth, threshold+afwidth, value);
    }

    float aastep(float threshold1, float threshold2, float dist) {
        return aastep(threshold1, dist) * aastep(threshold2, 1.0 - dist);
    }

    void main(){
        float xalpha = aastep(0.0, 0.0, f_uv.x);
        float yalpha = aastep(0.0, 0.0, f_uv.y);
        vec4 color = get_color(f_color, colormap, colorrange);
        fragment_color = vec4(color.rgb, color.a);
    }
    `;
}
function create_line_material(uniforms, attributes) {
    const uniforms_des = deserialize_uniforms(uniforms);
    return new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        glslVersion: THREE.GLSL3,
        vertexShader: linesegments_vertex_shader(uniforms_des, attributes),
        fragmentShader: lines_fragment_shader(uniforms_des, attributes),
        transparent: true
    });
}
function attach_interleaved_line_buffer(attr_name, geometry, points, ndim, is_segments) {
    const skip_elems = is_segments ? 2 * ndim : ndim;
    const buffer = new THREE.InstancedInterleavedBuffer(points, skip_elems, 1);
    geometry.setAttribute(attr_name + "_start", new THREE.InterleavedBufferAttribute(buffer, ndim, 0));
    geometry.setAttribute(attr_name + "_end", new THREE.InterleavedBufferAttribute(buffer, ndim, ndim));
    return buffer;
}
function create_line_instance_geometry() {
    const geometry = new THREE.InstancedBufferGeometry();
    const instance_positions = [
        0,
        -0.5,
        1,
        -0.5,
        1,
        0.5,
        0,
        -0.5,
        1,
        0.5,
        0,
        0.5
    ];
    geometry.setAttribute("position", new THREE.Float32BufferAttribute(instance_positions, 2));
    geometry.boundingSphere = new THREE.Sphere();
    geometry.boundingSphere.radius = 10000000000000;
    geometry.frustumCulled = false;
    return geometry;
}
function create_line_buffer(geometry, buffers, name, attr, is_segments) {
    const flat_buffer = attr.value.flat;
    const ndims = attr.value.type_length;
    const linebuffer = attach_interleaved_line_buffer(name, geometry, flat_buffer, ndims, is_segments);
    buffers[name] = linebuffer;
    return flat_buffer;
}
function create_line_buffers(geometry, buffers, attributes, is_segments) {
    for(let name in attributes){
        const attr = attributes[name];
        create_line_buffer(geometry, buffers, name, attr, is_segments);
    }
}
function attach_updates(mesh, buffers, attributes, is_segments) {
    let geometry = mesh.geometry;
    for(let name in attributes){
        const attr = attributes[name];
        attr.on((new_points)=>{
            let buff = buffers[name];
            const ndims = new_points.type_length;
            const new_line_points = new_points.flat;
            const old_count = buff.array.length;
            const new_count = new_line_points.length / ndims;
            if (old_count < new_line_points.length) {
                mesh.geometry.dispose();
                geometry = create_line_instance_geometry();
                buff = attach_interleaved_line_buffer(name, geometry, new_line_points, ndims, is_segments);
                mesh.geometry = geometry;
                buffers[name] = buff;
            } else {
                buff.set(new_line_points);
            }
            const ls_factor = is_segments ? 2 : 1;
            const offset = is_segments ? 0 : 1;
            mesh.geometry.instanceCount = new_count / ls_factor - offset;
            buff.needsUpdate = true;
            mesh.needsUpdate = true;
        });
    }
}
function _create_line(line_data, is_segments) {
    const geometry = create_line_instance_geometry();
    const buffers = {};
    create_line_buffers(geometry, buffers, line_data.attributes, is_segments);
    const material = create_line_material(line_data.uniforms, geometry.attributes);
    const mesh = new THREE.Mesh(geometry, material);
    const offset = is_segments ? 0 : 1;
    const new_count = geometry.attributes.linepoint_start.count;
    mesh.geometry.instanceCount = new_count - offset;
    attach_updates(mesh, buffers, line_data.attributes, is_segments);
    return mesh;
}
function create_line(line_data) {
    return _create_line(line_data, false);
}
function create_linesegments(line_data) {
    return _create_line(line_data, true);
}
function deserialize_plot(data) {
    let mesh;
    const update_visible = (v)=>{
        mesh.visible = v;
        return;
    };
    if (data.plot_type === "lines") {
        mesh = create_line(data);
    } else if (data.plot_type === "linesegments") {
        mesh = create_linesegments(data);
    } else if ("instance_attributes" in data) {
        mesh = create_instanced_mesh(data);
    } else {
        mesh = create_mesh(data);
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
        const tex = new mod.Data3DTexture(buffer, data.size[0], data.size[1], data.size[2]);
        tex.format = mod[data.three_format];
        tex.type = mod[data.three_type];
        return tex;
    } else {
        const tex_data = buffer == "texture_atlas" ? TEXTURE_ATLAS[0].value : buffer;
        return new mod.DataTexture(tex_data, data.size[0], data.size[1], mod[data.three_format], mod[data.three_type]);
    }
}
function re_create_texture(old_texture, buffer, size) {
    let tex;
    if (size.length == 3) {
        tex = new mod.DataTexture3D(buffer, size[0], size[1], size[2]);
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
function create_material(program) {
    const is_volume = "volumedata" in program.uniforms;
    return new mod.RawShaderMaterial({
        uniforms: deserialize_uniforms(program.uniforms),
        vertexShader: program.vertex_source,
        fragmentShader: program.fragment_source,
        side: is_volume ? mod.BackSide : mod.DoubleSide,
        transparent: true,
        glslVersion: mod.GLSL3,
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
    scene.camera_relative_light = data.camera_relative_light;
    scene.light_direction = data.light_direction;
    const camera = new MakieCamera();
    scene.wgl_camera = camera;
    function update_cam(camera_matrices) {
        const [view, projection, resolution, eyepos] = camera_matrices;
        camera.update_matrices(view, projection, resolution, eyepos);
    }
    update_cam(data.camera.value);
    camera.update_light_dir(data.light_direction.value);
    if (data.cam3d_state) {
        attach_3d_camera(canvas, camera, data.cam3d_state, data.light_direction, scene);
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
function render_scene(scene, picking = false) {
    const { camera , renderer , px_per_unit  } = scene.screen;
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
    renderer.autoClear = scene.clearscene.value;
    const area = scene.pixelarea.value;
    if (area) {
        const [x, y, w, h] = area.map((x)=>x * px_per_unit);
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
function add_canvas_events(screen, comm, resize_to_body) {
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
        const [width, height] = get_body_size();
        comm.notify({
            resize: [
                width / winscale,
                height / winscale
            ]
        });
    }
    if (resize_to_body) {
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
        powerPreference: "high-performance"
    });
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
function create_scene(wrapper, canvas, canvas_width, scenes, comm, width, height, texture_atlas_obs, fps, resize_to_body, px_per_unit, scalefactor) {
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
        winscale
    };
    add_canvas_events(screen, comm, resize_to_body);
    set_render_size(screen, width, height);
    const three_scene = deserialize_scene(scenes, screen);
    start_renderloop(three_scene);
    canvas_width.on((w_h)=>{
        set_render_size(screen, ...w_h);
    });
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
    render_scene
};
export { deserialize_scene as deserialize_scene, threejs_module as threejs_module, start_renderloop as start_renderloop, delete_plots as delete_plots, insert_plot as insert_plot, find_plots as find_plots, delete_scene as delete_scene, find_scene as find_scene, scene_cache as scene_cache, plot_cache as plot_cache, delete_scenes as delete_scenes, create_scene as create_scene, events2unitless as events2unitless, on_next_insert as on_next_insert };
export { render_scene as render_scene };
export { pick_native as pick_native };
export { pick_closest as pick_closest };
export { pick_sorted as pick_sorted };
export { pick_native_uuid as pick_native_uuid };
export { pick_native_matrix as pick_native_matrix };
export { register_popup as register_popup };

