// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

var E = Object.create;
var d = Object.defineProperty;
var L = Object.getOwnPropertyDescriptor;
var O = Object.getOwnPropertyNames;
var C = Object.getPrototypeOf, A = Object.prototype.hasOwnProperty;
var k = (n, e)=>()=>(e || n((e = {
            exports: {}
        }).exports, e), e.exports);
var P = (n, e, t, s)=>{
    if (e && typeof e == "object" || typeof e == "function") for (let i of O(e))!A.call(n, i) && i !== t && d(n, i, {
        get: ()=>e[i],
        enumerable: !(s = L(e, i)) || s.enumerable
    });
    return n;
};
var N = (n, e, t)=>(t = n != null ? E(C(n)) : {}, P(e || !n || !n.__esModule ? d(t, "default", {
        value: n,
        enumerable: !0
    }) : t, n));
var m = k((q, x)=>{
    "use strict";
    var S = Object.prototype.hasOwnProperty, l = "~";
    function _() {}
    Object.create && (_.prototype = Object.create(null), new _().__proto__ || (l = !1));
    function T(n, e, t) {
        this.fn = n, this.context = e, this.once = t || !1;
    }
    function w(n, e, t, s, i) {
        if (typeof t != "function") throw new TypeError("The listener must be a function");
        var u = new T(t, s || n, i), o = l ? l + e : e;
        return n._events[o] ? n._events[o].fn ? n._events[o] = [
            n._events[o],
            u
        ] : n._events[o].push(u) : (n._events[o] = u, n._eventsCount++), n;
    }
    function y(n, e) {
        --n._eventsCount === 0 ? n._events = new _ : delete n._events[e];
    }
    function c() {
        this._events = new _, this._eventsCount = 0;
    }
    c.prototype.eventNames = function() {
        var e = [], t, s;
        if (this._eventsCount === 0) return e;
        for(s in t = this._events)S.call(t, s) && e.push(l ? s.slice(1) : s);
        return Object.getOwnPropertySymbols ? e.concat(Object.getOwnPropertySymbols(t)) : e;
    };
    c.prototype.listeners = function(e) {
        var t = l ? l + e : e, s = this._events[t];
        if (!s) return [];
        if (s.fn) return [
            s.fn
        ];
        for(var i = 0, u = s.length, o = new Array(u); i < u; i++)o[i] = s[i].fn;
        return o;
    };
    c.prototype.listenerCount = function(e) {
        var t = l ? l + e : e, s = this._events[t];
        return s ? s.fn ? 1 : s.length : 0;
    };
    c.prototype.emit = function(e, t, s, i, u, o) {
        var a = l ? l + e : e;
        if (!this._events[a]) return !1;
        var r = this._events[a], p = arguments.length, h, f;
        if (r.fn) {
            switch(r.once && this.removeListener(e, r.fn, void 0, !0), p){
                case 1:
                    return r.fn.call(r.context), !0;
                case 2:
                    return r.fn.call(r.context, t), !0;
                case 3:
                    return r.fn.call(r.context, t, s), !0;
                case 4:
                    return r.fn.call(r.context, t, s, i), !0;
                case 5:
                    return r.fn.call(r.context, t, s, i, u), !0;
                case 6:
                    return r.fn.call(r.context, t, s, i, u, o), !0;
            }
            for(f = 1, h = new Array(p - 1); f < p; f++)h[f - 1] = arguments[f];
            r.fn.apply(r.context, h);
        } else {
            var b = r.length, v;
            for(f = 0; f < b; f++)switch(r[f].once && this.removeListener(e, r[f].fn, void 0, !0), p){
                case 1:
                    r[f].fn.call(r[f].context);
                    break;
                case 2:
                    r[f].fn.call(r[f].context, t);
                    break;
                case 3:
                    r[f].fn.call(r[f].context, t, s);
                    break;
                case 4:
                    r[f].fn.call(r[f].context, t, s, i);
                    break;
                default:
                    if (!h) for(v = 1, h = new Array(p - 1); v < p; v++)h[v - 1] = arguments[v];
                    r[f].fn.apply(r[f].context, h);
            }
        }
        return !0;
    };
    c.prototype.on = function(e, t, s) {
        return w(this, e, t, s, !1);
    };
    c.prototype.once = function(e, t, s) {
        return w(this, e, t, s, !0);
    };
    c.prototype.removeListener = function(e, t, s, i) {
        var u = l ? l + e : e;
        if (!this._events[u]) return this;
        if (!t) return y(this, u), this;
        var o = this._events[u];
        if (o.fn) o.fn === t && (!i || o.once) && (!s || o.context === s) && y(this, u);
        else {
            for(var a = 0, r = [], p = o.length; a < p; a++)(o[a].fn !== t || i && !o[a].once || s && o[a].context !== s) && r.push(o[a]);
            r.length ? this._events[u] = r.length === 1 ? r[0] : r : y(this, u);
        }
        return this;
    };
    c.prototype.removeAllListeners = function(e) {
        var t;
        return e ? (t = l ? l + e : e, this._events[t] && y(this, t)) : (this._events = new _, this._eventsCount = 0), this;
    };
    c.prototype.off = c.prototype.removeListener;
    c.prototype.addListener = c.prototype.on;
    c.prefixed = l;
    c.EventEmitter = c;
    typeof x < "u" && (x.exports = c);
});
var g = N(m(), 1);
g.default;
var export_EventEmitter = g.default;
var u = class extends Error {
    constructor(e){
        super(e), this.name = "TimeoutError";
    }
}, d1 = class extends Error {
    constructor(e){
        super(), this.name = "AbortError", this.message = e;
    }
}, E1 = (n)=>globalThis.DOMException === void 0 ? new d1(n) : new DOMException(n), p = (n)=>{
    let e = n.reason === void 0 ? E1("This operation was aborted.") : n.reason;
    return e instanceof Error ? e : E1(e);
};
function T(n, e) {
    let { milliseconds: o , fallback: f , message: a , customTimers: m = {
        setTimeout,
        clearTimeout
    }  } = e, c, i, l = new Promise((s, r)=>{
        if (typeof o != "number" || Math.sign(o) !== 1) throw new TypeError(`Expected \`milliseconds\` to be a positive number, got \`${o}\``);
        if (e.signal) {
            let { signal: t  } = e;
            t.aborted && r(p(t)), i = ()=>{
                r(p(t));
            }, t.addEventListener("abort", i, {
                once: !0
            });
        }
        if (o === Number.POSITIVE_INFINITY) {
            n.then(s, r);
            return;
        }
        let b = new u;
        c = m.setTimeout.call(void 0, ()=>{
            if (f) {
                try {
                    s(f());
                } catch (t) {
                    r(t);
                }
                return;
            }
            typeof n.cancel == "function" && n.cancel(), a === !1 ? s() : a instanceof Error ? r(a) : (b.message = a ?? `Promise timed out after ${o} milliseconds`, r(b));
        }, o), (async ()=>{
            try {
                s(await n);
            } catch (t) {
                r(t);
            }
        })();
    }).finally(()=>{
        l.clear(), i && e.signal && e.signal.removeEventListener("abort", i);
    });
    return l.clear = ()=>{
        m.clearTimeout.call(void 0, c), c = void 0;
    }, l;
}
function a(u, t, e) {
    let i = 0, s = u.length;
    for(; s > 0;){
        let r = Math.trunc(s / 2), n = i + r;
        e(u[n], t) <= 0 ? (i = ++n, s -= r + 1) : s = r;
    }
    return i;
}
var h = class {
    #t = [];
    enqueue(t, e) {
        e = {
            priority: 0,
            ...e
        };
        let i = {
            priority: e.priority,
            id: e.id,
            run: t
        };
        if (this.size === 0 || this.#t[this.size - 1].priority >= e.priority) {
            this.#t.push(i);
            return;
        }
        let s = a(this.#t, i, (r, n)=>n.priority - r.priority);
        this.#t.splice(s, 0, i);
    }
    setPriority(t, e) {
        let i = this.#t.findIndex((r)=>r.id === t);
        if (i === -1) throw new ReferenceError(`No promise function with the id "${t}" exists in the queue.`);
        let [s] = this.#t.splice(i, 1);
        this.enqueue(s.run, {
            priority: e,
            id: t
        });
    }
    dequeue() {
        return this.#t.shift()?.run;
    }
    filter(t) {
        return this.#t.filter((e)=>e.priority === t.priority).map((e)=>e.run);
    }
    get size() {
        return this.#t.length;
    }
};
var l = class extends export_EventEmitter {
    #t;
    #h;
    #n = 0;
    #d;
    #u;
    #m = 0;
    #i;
    #a;
    #e;
    #y;
    #r = 0;
    #l;
    #s;
    #v;
    #g = 1n;
    timeout;
    constructor(t){
        if (super(), t = {
            carryoverConcurrencyCount: !1,
            intervalCap: Number.POSITIVE_INFINITY,
            interval: 0,
            concurrency: Number.POSITIVE_INFINITY,
            autoStart: !0,
            queueClass: h,
            ...t
        }, !(typeof t.intervalCap == "number" && t.intervalCap >= 1)) throw new TypeError(`Expected \`intervalCap\` to be a number from 1 and up, got \`${t.intervalCap?.toString() ?? ""}\` (${typeof t.intervalCap})`);
        if (t.interval === void 0 || !(Number.isFinite(t.interval) && t.interval >= 0)) throw new TypeError(`Expected \`interval\` to be a finite number >= 0, got \`${t.interval?.toString() ?? ""}\` (${typeof t.interval})`);
        this.#t = t.carryoverConcurrencyCount, this.#h = t.intervalCap === Number.POSITIVE_INFINITY || t.interval === 0, this.#d = t.intervalCap, this.#u = t.interval, this.#e = new t.queueClass, this.#y = t.queueClass, this.concurrency = t.concurrency, this.timeout = t.timeout, this.#v = t.throwOnTimeout === !0, this.#s = t.autoStart === !1;
    }
    get #p() {
        return this.#h || this.#n < this.#d;
    }
    get #T() {
        return this.#r < this.#l;
    }
    #C() {
        this.#r--, this.#o(), this.emit("next");
    }
    #E() {
        this.#w(), this.#I(), this.#a = void 0;
    }
    get #b() {
        let t = Date.now();
        if (this.#i === void 0) {
            let e = this.#m - t;
            if (e < 0) this.#n = this.#t ? this.#r : 0;
            else return this.#a === void 0 && (this.#a = setTimeout(()=>{
                this.#E();
            }, e)), !0;
        }
        return !1;
    }
    #o() {
        if (this.#e.size === 0) return this.#i && clearInterval(this.#i), this.#i = void 0, this.emit("empty"), this.#r === 0 && this.emit("idle"), !1;
        if (!this.#s) {
            let t = !this.#b;
            if (this.#p && this.#T) {
                let e = this.#e.dequeue();
                return e ? (this.emit("active"), e(), t && this.#I(), !0) : !1;
            }
        }
        return !1;
    }
    #I() {
        this.#h || this.#i !== void 0 || (this.#i = setInterval(()=>{
            this.#w();
        }, this.#u), this.#m = Date.now() + this.#u);
    }
    #w() {
        this.#n === 0 && this.#r === 0 && this.#i && (clearInterval(this.#i), this.#i = void 0), this.#n = this.#t ? this.#r : 0, this.#c();
    }
    #c() {
        for(; this.#o(););
    }
    get concurrency() {
        return this.#l;
    }
    set concurrency(t) {
        if (!(typeof t == "number" && t >= 1)) throw new TypeError(`Expected \`concurrency\` to be a number from 1 and up, got \`${t}\` (${typeof t})`);
        this.#l = t, this.#c();
    }
    async #x(t) {
        return new Promise((e, i)=>{
            t.addEventListener("abort", ()=>{
                i(t.reason);
            }, {
                once: !0
            });
        });
    }
    setPriority(t, e) {
        this.#e.setPriority(t, e);
    }
    async add(t, e = {}) {
        return e.id ??= (this.#g++).toString(), e = {
            timeout: this.timeout,
            throwOnTimeout: this.#v,
            ...e
        }, new Promise((i, s)=>{
            this.#e.enqueue(async ()=>{
                this.#r++, this.#n++;
                try {
                    e.signal?.throwIfAborted();
                    let r = t({
                        signal: e.signal
                    });
                    e.timeout && (r = T(Promise.resolve(r), {
                        milliseconds: e.timeout
                    })), e.signal && (r = Promise.race([
                        r,
                        this.#x(e.signal)
                    ]));
                    let n = await r;
                    i(n), this.emit("completed", n);
                } catch (r) {
                    if (r instanceof u && !e.throwOnTimeout) {
                        i();
                        return;
                    }
                    s(r), this.emit("error", r);
                } finally{
                    this.#C();
                }
            }, e), this.emit("add"), this.#o();
        });
    }
    async addAll(t, e) {
        return Promise.all(t.map(async (i)=>this.add(i, e)));
    }
    start() {
        return this.#s ? (this.#s = !1, this.#c(), this) : this;
    }
    pause() {
        this.#s = !0;
    }
    clear() {
        this.#e = new this.#y;
    }
    async onEmpty() {
        this.#e.size !== 0 && await this.#f("empty");
    }
    async onSizeLessThan(t) {
        this.#e.size < t || await this.#f("next", ()=>this.#e.size < t);
    }
    async onIdle() {
        this.#r === 0 && this.#e.size === 0 || await this.#f("idle");
    }
    async #f(t, e) {
        return new Promise((i)=>{
            let s = ()=>{
                e && !e() || (this.off(t, s), i());
            };
            this.on(t, s);
        });
    }
    get size() {
        return this.#e.size;
    }
    sizeBy(t) {
        return this.#e.filter(t).length;
    }
    get pending() {
        return this.#r;
    }
    get isPaused() {
        return this.#s;
    }
};
function utf8Count(str) {
    var strLength = str.length;
    var byteLength = 0;
    var pos = 0;
    while(pos < strLength){
        var value = str.charCodeAt(pos++);
        if ((value & 0xffffff80) === 0) {
            byteLength++;
            continue;
        } else if ((value & 0xfffff800) === 0) {
            byteLength += 2;
        } else {
            if (value >= 0xd800 && value <= 0xdbff) {
                if (pos < strLength) {
                    var extra = str.charCodeAt(pos);
                    if ((extra & 0xfc00) === 0xdc00) {
                        ++pos;
                        value = ((value & 0x3ff) << 10) + (extra & 0x3ff) + 0x10000;
                    }
                }
            }
            if ((value & 0xffff0000) === 0) {
                byteLength += 3;
            } else {
                byteLength += 4;
            }
        }
    }
    return byteLength;
}
function utf8EncodeJs(str, output, outputOffset) {
    var strLength = str.length;
    var offset = outputOffset;
    var pos = 0;
    while(pos < strLength){
        var value = str.charCodeAt(pos++);
        if ((value & 0xffffff80) === 0) {
            output[offset++] = value;
            continue;
        } else if ((value & 0xfffff800) === 0) {
            output[offset++] = value >> 6 & 0x1f | 0xc0;
        } else {
            if (value >= 0xd800 && value <= 0xdbff) {
                if (pos < strLength) {
                    var extra = str.charCodeAt(pos);
                    if ((extra & 0xfc00) === 0xdc00) {
                        ++pos;
                        value = ((value & 0x3ff) << 10) + (extra & 0x3ff) + 0x10000;
                    }
                }
            }
            if ((value & 0xffff0000) === 0) {
                output[offset++] = value >> 12 & 0x0f | 0xe0;
                output[offset++] = value >> 6 & 0x3f | 0x80;
            } else {
                output[offset++] = value >> 18 & 0x07 | 0xf0;
                output[offset++] = value >> 12 & 0x3f | 0x80;
                output[offset++] = value >> 6 & 0x3f | 0x80;
            }
        }
        output[offset++] = value & 0x3f | 0x80;
    }
}
var sharedTextEncoder = new TextEncoder();
var TEXT_ENCODER_THRESHOLD = 50;
function utf8EncodeTE(str, output, outputOffset) {
    sharedTextEncoder.encodeInto(str, output.subarray(outputOffset));
}
function utf8Encode(str, output, outputOffset) {
    if (str.length > TEXT_ENCODER_THRESHOLD) {
        utf8EncodeTE(str, output, outputOffset);
    } else {
        utf8EncodeJs(str, output, outputOffset);
    }
}
var CHUNK_SIZE = 4096;
function utf8DecodeJs(bytes, inputOffset, byteLength) {
    var offset = inputOffset;
    var end = offset + byteLength;
    var units = [];
    var result = "";
    while(offset < end){
        var byte1 = bytes[offset++];
        if ((byte1 & 0x80) === 0) {
            units.push(byte1);
        } else if ((byte1 & 0xe0) === 0xc0) {
            var byte2 = bytes[offset++] & 0x3f;
            units.push((byte1 & 0x1f) << 6 | byte2);
        } else if ((byte1 & 0xf0) === 0xe0) {
            var byte2 = bytes[offset++] & 0x3f;
            var byte3 = bytes[offset++] & 0x3f;
            units.push((byte1 & 0x1f) << 12 | byte2 << 6 | byte3);
        } else if ((byte1 & 0xf8) === 0xf0) {
            var byte2 = bytes[offset++] & 0x3f;
            var byte3 = bytes[offset++] & 0x3f;
            var byte4 = bytes[offset++] & 0x3f;
            var unit = (byte1 & 0x07) << 0x12 | byte2 << 0x0c | byte3 << 0x06 | byte4;
            if (unit > 0xffff) {
                unit -= 0x10000;
                units.push(unit >>> 10 & 0x3ff | 0xd800);
                unit = 0xdc00 | unit & 0x3ff;
            }
            units.push(unit);
        } else {
            units.push(byte1);
        }
        if (units.length >= CHUNK_SIZE) {
            result += String.fromCharCode.apply(String, units);
            units.length = 0;
        }
    }
    if (units.length > 0) {
        result += String.fromCharCode.apply(String, units);
    }
    return result;
}
var sharedTextDecoder = new TextDecoder();
var TEXT_DECODER_THRESHOLD = 200;
function utf8DecodeTD(bytes, inputOffset, byteLength) {
    var stringBytes = bytes.subarray(inputOffset, inputOffset + byteLength);
    return sharedTextDecoder.decode(stringBytes);
}
function utf8Decode(bytes, inputOffset, byteLength) {
    if (byteLength > TEXT_DECODER_THRESHOLD) {
        return utf8DecodeTD(bytes, inputOffset, byteLength);
    } else {
        return utf8DecodeJs(bytes, inputOffset, byteLength);
    }
}
var ExtData = function() {
    function ExtData(type, data) {
        this.type = type;
        this.data = data;
    }
    return ExtData;
}();
var __extends = this && this.__extends || function() {
    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf || ({
            __proto__: []
        }) instanceof Array && function(d, b) {
            d.__proto__ = b;
        } || function(d, b) {
            for(var p in b)if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p];
        };
        return extendStatics(d, b);
    };
    return function(d, b) {
        if (typeof b !== "function" && b !== null) throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() {
            this.constructor = d;
        }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
}();
var DecodeError = function(_super) {
    __extends(DecodeError, _super);
    function DecodeError(message) {
        var _this = _super.call(this, message) || this;
        var proto = Object.create(DecodeError.prototype);
        Object.setPrototypeOf(_this, proto);
        Object.defineProperty(_this, "name", {
            configurable: true,
            enumerable: false,
            value: DecodeError.name
        });
        return _this;
    }
    return DecodeError;
}(Error);
var UINT32_MAX = 4294967295;
function setUint64(view, offset, value) {
    var high = value / 4294967296;
    var low = value;
    view.setUint32(offset, high);
    view.setUint32(offset + 4, low);
}
function setInt64(view, offset, value) {
    var high = Math.floor(value / 4294967296);
    var low = value;
    view.setUint32(offset, high);
    view.setUint32(offset + 4, low);
}
function getInt64(view, offset) {
    var high = view.getInt32(offset);
    var low = view.getUint32(offset + 4);
    return high * 4294967296 + low;
}
function getUint64(view, offset) {
    var high = view.getUint32(offset);
    var low = view.getUint32(offset + 4);
    return high * 4294967296 + low;
}
var EXT_TIMESTAMP = -1;
var TIMESTAMP32_MAX_SEC = 0x100000000 - 1;
var TIMESTAMP64_MAX_SEC = 0x400000000 - 1;
function encodeTimeSpecToTimestamp(_a) {
    var sec = _a.sec, nsec = _a.nsec;
    if (sec >= 0 && nsec >= 0 && sec <= TIMESTAMP64_MAX_SEC) {
        if (nsec === 0 && sec <= TIMESTAMP32_MAX_SEC) {
            var rv = new Uint8Array(4);
            var view = new DataView(rv.buffer);
            view.setUint32(0, sec);
            return rv;
        } else {
            var secHigh = sec / 0x100000000;
            var secLow = sec & 0xffffffff;
            var rv = new Uint8Array(8);
            var view = new DataView(rv.buffer);
            view.setUint32(0, nsec << 2 | secHigh & 0x3);
            view.setUint32(4, secLow);
            return rv;
        }
    } else {
        var rv = new Uint8Array(12);
        var view = new DataView(rv.buffer);
        view.setUint32(0, nsec);
        setInt64(view, 4, sec);
        return rv;
    }
}
function encodeDateToTimeSpec(date) {
    var msec = date.getTime();
    var sec = Math.floor(msec / 1e3);
    var nsec = (msec - sec * 1e3) * 1e6;
    var nsecInSec = Math.floor(nsec / 1e9);
    return {
        sec: sec + nsecInSec,
        nsec: nsec - nsecInSec * 1e9
    };
}
function encodeTimestampExtension(object) {
    if (object instanceof Date) {
        var timeSpec = encodeDateToTimeSpec(object);
        return encodeTimeSpecToTimestamp(timeSpec);
    } else {
        return null;
    }
}
function decodeTimestampToTimeSpec(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    switch(data.byteLength){
        case 4:
            {
                var sec = view.getUint32(0);
                var nsec = 0;
                return {
                    sec: sec,
                    nsec: nsec
                };
            }
        case 8:
            {
                var nsec30AndSecHigh2 = view.getUint32(0);
                var secLow32 = view.getUint32(4);
                var sec = (nsec30AndSecHigh2 & 0x3) * 0x100000000 + secLow32;
                var nsec = nsec30AndSecHigh2 >>> 2;
                return {
                    sec: sec,
                    nsec: nsec
                };
            }
        case 12:
            {
                var sec = getInt64(view, 4);
                var nsec = view.getUint32(0);
                return {
                    sec: sec,
                    nsec: nsec
                };
            }
        default:
            throw new DecodeError("Unrecognized data size for timestamp (expected 4, 8, or 12): ".concat(data.length));
    }
}
function decodeTimestampExtension(data) {
    var timeSpec = decodeTimestampToTimeSpec(data);
    return new Date(timeSpec.sec * 1e3 + timeSpec.nsec / 1e6);
}
var timestampExtension = {
    type: EXT_TIMESTAMP,
    encode: encodeTimestampExtension,
    decode: decodeTimestampExtension
};
var ExtensionCodec = function() {
    function ExtensionCodec() {
        this.builtInEncoders = [];
        this.builtInDecoders = [];
        this.encoders = [];
        this.decoders = [];
        this.register(timestampExtension);
    }
    ExtensionCodec.prototype.register = function(_a) {
        var type = _a.type, encode = _a.encode, decode = _a.decode;
        if (type >= 0) {
            this.encoders[type] = encode;
            this.decoders[type] = decode;
        } else {
            var index = 1 + type;
            this.builtInEncoders[index] = encode;
            this.builtInDecoders[index] = decode;
        }
    };
    ExtensionCodec.prototype.tryToEncode = function(object, context) {
        for(var i = 0; i < this.builtInEncoders.length; i++){
            var encodeExt = this.builtInEncoders[i];
            if (encodeExt != null) {
                var data = encodeExt(object, context);
                if (data != null) {
                    var type = -1 - i;
                    return new ExtData(type, data);
                }
            }
        }
        for(var i = 0; i < this.encoders.length; i++){
            var encodeExt = this.encoders[i];
            if (encodeExt != null) {
                var data = encodeExt(object, context);
                if (data != null) {
                    var type = i;
                    return new ExtData(type, data);
                }
            }
        }
        if (object instanceof ExtData) {
            return object;
        }
        return null;
    };
    ExtensionCodec.prototype.decode = function(data, type, context) {
        var decodeExt = type < 0 ? this.builtInDecoders[-1 - type] : this.decoders[type];
        if (decodeExt) {
            return decodeExt(data, type, context);
        } else {
            return new ExtData(type, data);
        }
    };
    ExtensionCodec.defaultCodec = new ExtensionCodec();
    return ExtensionCodec;
}();
function ensureUint8Array(buffer) {
    if (buffer instanceof Uint8Array) {
        return buffer;
    } else if (ArrayBuffer.isView(buffer)) {
        return new Uint8Array(buffer.buffer, buffer.byteOffset, buffer.byteLength);
    } else if (buffer instanceof ArrayBuffer) {
        return new Uint8Array(buffer);
    } else {
        return Uint8Array.from(buffer);
    }
}
function createDataView(buffer) {
    if (buffer instanceof ArrayBuffer) {
        return new DataView(buffer);
    }
    var bufferView = ensureUint8Array(buffer);
    return new DataView(bufferView.buffer, bufferView.byteOffset, bufferView.byteLength);
}
var DEFAULT_MAX_DEPTH = 100;
var DEFAULT_INITIAL_BUFFER_SIZE = 2048;
var Encoder = function() {
    function Encoder(options) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        this.extensionCodec = (_a = options === null || options === void 0 ? void 0 : options.extensionCodec) !== null && _a !== void 0 ? _a : ExtensionCodec.defaultCodec;
        this.context = options === null || options === void 0 ? void 0 : options.context;
        this.useBigInt64 = (_b = options === null || options === void 0 ? void 0 : options.useBigInt64) !== null && _b !== void 0 ? _b : false;
        this.maxDepth = (_c = options === null || options === void 0 ? void 0 : options.maxDepth) !== null && _c !== void 0 ? _c : DEFAULT_MAX_DEPTH;
        this.initialBufferSize = (_d = options === null || options === void 0 ? void 0 : options.initialBufferSize) !== null && _d !== void 0 ? _d : DEFAULT_INITIAL_BUFFER_SIZE;
        this.sortKeys = (_e = options === null || options === void 0 ? void 0 : options.sortKeys) !== null && _e !== void 0 ? _e : false;
        this.forceFloat32 = (_f = options === null || options === void 0 ? void 0 : options.forceFloat32) !== null && _f !== void 0 ? _f : false;
        this.ignoreUndefined = (_g = options === null || options === void 0 ? void 0 : options.ignoreUndefined) !== null && _g !== void 0 ? _g : false;
        this.forceIntegerToFloat = (_h = options === null || options === void 0 ? void 0 : options.forceIntegerToFloat) !== null && _h !== void 0 ? _h : false;
        this.pos = 0;
        this.view = new DataView(new ArrayBuffer(this.initialBufferSize));
        this.bytes = new Uint8Array(this.view.buffer);
    }
    Encoder.prototype.reinitializeState = function() {
        this.pos = 0;
    };
    Encoder.prototype.encodeSharedRef = function(object) {
        this.reinitializeState();
        this.doEncode(object, 1);
        return this.bytes.subarray(0, this.pos);
    };
    Encoder.prototype.encode = function(object) {
        this.reinitializeState();
        this.doEncode(object, 1);
        return this.bytes.slice(0, this.pos);
    };
    Encoder.prototype.doEncode = function(object, depth) {
        if (depth > this.maxDepth) {
            throw new Error("Too deep objects in depth ".concat(depth));
        }
        if (object == null) {
            this.encodeNil();
        } else if (typeof object === "boolean") {
            this.encodeBoolean(object);
        } else if (typeof object === "number") {
            if (!this.forceIntegerToFloat) {
                this.encodeNumber(object);
            } else {
                this.encodeNumberAsFloat(object);
            }
        } else if (typeof object === "string") {
            this.encodeString(object);
        } else if (this.useBigInt64 && typeof object === "bigint") {
            this.encodeBigInt64(object);
        } else {
            this.encodeObject(object, depth);
        }
    };
    Encoder.prototype.ensureBufferSizeToWrite = function(sizeToWrite) {
        var requiredSize = this.pos + sizeToWrite;
        if (this.view.byteLength < requiredSize) {
            this.resizeBuffer(requiredSize * 2);
        }
    };
    Encoder.prototype.resizeBuffer = function(newSize) {
        var newBuffer = new ArrayBuffer(newSize);
        var newBytes = new Uint8Array(newBuffer);
        var newView = new DataView(newBuffer);
        newBytes.set(this.bytes);
        this.view = newView;
        this.bytes = newBytes;
    };
    Encoder.prototype.encodeNil = function() {
        this.writeU8(0xc0);
    };
    Encoder.prototype.encodeBoolean = function(object) {
        if (object === false) {
            this.writeU8(0xc2);
        } else {
            this.writeU8(0xc3);
        }
    };
    Encoder.prototype.encodeNumber = function(object) {
        if (!this.forceIntegerToFloat && Number.isSafeInteger(object)) {
            if (object >= 0) {
                if (object < 0x80) {
                    this.writeU8(object);
                } else if (object < 0x100) {
                    this.writeU8(0xcc);
                    this.writeU8(object);
                } else if (object < 0x10000) {
                    this.writeU8(0xcd);
                    this.writeU16(object);
                } else if (object < 0x100000000) {
                    this.writeU8(0xce);
                    this.writeU32(object);
                } else if (!this.useBigInt64) {
                    this.writeU8(0xcf);
                    this.writeU64(object);
                } else {
                    this.encodeNumberAsFloat(object);
                }
            } else {
                if (object >= -0x20) {
                    this.writeU8(0xe0 | object + 0x20);
                } else if (object >= -0x80) {
                    this.writeU8(0xd0);
                    this.writeI8(object);
                } else if (object >= -0x8000) {
                    this.writeU8(0xd1);
                    this.writeI16(object);
                } else if (object >= -0x80000000) {
                    this.writeU8(0xd2);
                    this.writeI32(object);
                } else if (!this.useBigInt64) {
                    this.writeU8(0xd3);
                    this.writeI64(object);
                } else {
                    this.encodeNumberAsFloat(object);
                }
            }
        } else {
            this.encodeNumberAsFloat(object);
        }
    };
    Encoder.prototype.encodeNumberAsFloat = function(object) {
        if (this.forceFloat32) {
            this.writeU8(0xca);
            this.writeF32(object);
        } else {
            this.writeU8(0xcb);
            this.writeF64(object);
        }
    };
    Encoder.prototype.encodeBigInt64 = function(object) {
        if (object >= BigInt(0)) {
            this.writeU8(0xcf);
            this.writeBigUint64(object);
        } else {
            this.writeU8(0xd3);
            this.writeBigInt64(object);
        }
    };
    Encoder.prototype.writeStringHeader = function(byteLength) {
        if (byteLength < 32) {
            this.writeU8(0xa0 + byteLength);
        } else if (byteLength < 0x100) {
            this.writeU8(0xd9);
            this.writeU8(byteLength);
        } else if (byteLength < 0x10000) {
            this.writeU8(0xda);
            this.writeU16(byteLength);
        } else if (byteLength < 0x100000000) {
            this.writeU8(0xdb);
            this.writeU32(byteLength);
        } else {
            throw new Error("Too long string: ".concat(byteLength, " bytes in UTF-8"));
        }
    };
    Encoder.prototype.encodeString = function(object) {
        var maxHeaderSize = 1 + 4;
        var byteLength = utf8Count(object);
        this.ensureBufferSizeToWrite(maxHeaderSize + byteLength);
        this.writeStringHeader(byteLength);
        utf8Encode(object, this.bytes, this.pos);
        this.pos += byteLength;
    };
    Encoder.prototype.encodeObject = function(object, depth) {
        var ext = this.extensionCodec.tryToEncode(object, this.context);
        if (ext != null) {
            this.encodeExtension(ext);
        } else if (Array.isArray(object)) {
            this.encodeArray(object, depth);
        } else if (ArrayBuffer.isView(object)) {
            this.encodeBinary(object);
        } else if (typeof object === "object") {
            this.encodeMap(object, depth);
        } else {
            throw new Error("Unrecognized object: ".concat(Object.prototype.toString.apply(object)));
        }
    };
    Encoder.prototype.encodeBinary = function(object) {
        var size = object.byteLength;
        if (size < 0x100) {
            this.writeU8(0xc4);
            this.writeU8(size);
        } else if (size < 0x10000) {
            this.writeU8(0xc5);
            this.writeU16(size);
        } else if (size < 0x100000000) {
            this.writeU8(0xc6);
            this.writeU32(size);
        } else {
            throw new Error("Too large binary: ".concat(size));
        }
        var bytes = ensureUint8Array(object);
        this.writeU8a(bytes);
    };
    Encoder.prototype.encodeArray = function(object, depth) {
        var size = object.length;
        if (size < 16) {
            this.writeU8(0x90 + size);
        } else if (size < 0x10000) {
            this.writeU8(0xdc);
            this.writeU16(size);
        } else if (size < 0x100000000) {
            this.writeU8(0xdd);
            this.writeU32(size);
        } else {
            throw new Error("Too large array: ".concat(size));
        }
        for(var _i = 0, object_1 = object; _i < object_1.length; _i++){
            var item = object_1[_i];
            this.doEncode(item, depth + 1);
        }
    };
    Encoder.prototype.countWithoutUndefined = function(object, keys) {
        var count = 0;
        for(var _i = 0, keys_1 = keys; _i < keys_1.length; _i++){
            var key = keys_1[_i];
            if (object[key] !== undefined) {
                count++;
            }
        }
        return count;
    };
    Encoder.prototype.encodeMap = function(object, depth) {
        var keys = Object.keys(object);
        if (this.sortKeys) {
            keys.sort();
        }
        var size = this.ignoreUndefined ? this.countWithoutUndefined(object, keys) : keys.length;
        if (size < 16) {
            this.writeU8(0x80 + size);
        } else if (size < 0x10000) {
            this.writeU8(0xde);
            this.writeU16(size);
        } else if (size < 0x100000000) {
            this.writeU8(0xdf);
            this.writeU32(size);
        } else {
            throw new Error("Too large map object: ".concat(size));
        }
        for(var _i = 0, keys_2 = keys; _i < keys_2.length; _i++){
            var key = keys_2[_i];
            var value = object[key];
            if (!(this.ignoreUndefined && value === undefined)) {
                this.encodeString(key);
                this.doEncode(value, depth + 1);
            }
        }
    };
    Encoder.prototype.encodeExtension = function(ext) {
        var size = ext.data.length;
        if (size === 1) {
            this.writeU8(0xd4);
        } else if (size === 2) {
            this.writeU8(0xd5);
        } else if (size === 4) {
            this.writeU8(0xd6);
        } else if (size === 8) {
            this.writeU8(0xd7);
        } else if (size === 16) {
            this.writeU8(0xd8);
        } else if (size < 0x100) {
            this.writeU8(0xc7);
            this.writeU8(size);
        } else if (size < 0x10000) {
            this.writeU8(0xc8);
            this.writeU16(size);
        } else if (size < 0x100000000) {
            this.writeU8(0xc9);
            this.writeU32(size);
        } else {
            throw new Error("Too large extension object: ".concat(size));
        }
        this.writeI8(ext.type);
        this.writeU8a(ext.data);
    };
    Encoder.prototype.writeU8 = function(value) {
        this.ensureBufferSizeToWrite(1);
        this.view.setUint8(this.pos, value);
        this.pos++;
    };
    Encoder.prototype.writeU8a = function(values) {
        var size = values.length;
        this.ensureBufferSizeToWrite(size);
        this.bytes.set(values, this.pos);
        this.pos += size;
    };
    Encoder.prototype.writeI8 = function(value) {
        this.ensureBufferSizeToWrite(1);
        this.view.setInt8(this.pos, value);
        this.pos++;
    };
    Encoder.prototype.writeU16 = function(value) {
        this.ensureBufferSizeToWrite(2);
        this.view.setUint16(this.pos, value);
        this.pos += 2;
    };
    Encoder.prototype.writeI16 = function(value) {
        this.ensureBufferSizeToWrite(2);
        this.view.setInt16(this.pos, value);
        this.pos += 2;
    };
    Encoder.prototype.writeU32 = function(value) {
        this.ensureBufferSizeToWrite(4);
        this.view.setUint32(this.pos, value);
        this.pos += 4;
    };
    Encoder.prototype.writeI32 = function(value) {
        this.ensureBufferSizeToWrite(4);
        this.view.setInt32(this.pos, value);
        this.pos += 4;
    };
    Encoder.prototype.writeF32 = function(value) {
        this.ensureBufferSizeToWrite(4);
        this.view.setFloat32(this.pos, value);
        this.pos += 4;
    };
    Encoder.prototype.writeF64 = function(value) {
        this.ensureBufferSizeToWrite(8);
        this.view.setFloat64(this.pos, value);
        this.pos += 8;
    };
    Encoder.prototype.writeU64 = function(value) {
        this.ensureBufferSizeToWrite(8);
        setUint64(this.view, this.pos, value);
        this.pos += 8;
    };
    Encoder.prototype.writeI64 = function(value) {
        this.ensureBufferSizeToWrite(8);
        setInt64(this.view, this.pos, value);
        this.pos += 8;
    };
    Encoder.prototype.writeBigUint64 = function(value) {
        this.ensureBufferSizeToWrite(8);
        this.view.setBigUint64(this.pos, value);
        this.pos += 8;
    };
    Encoder.prototype.writeBigInt64 = function(value) {
        this.ensureBufferSizeToWrite(8);
        this.view.setBigInt64(this.pos, value);
        this.pos += 8;
    };
    return Encoder;
}();
function encode(value, options) {
    var encoder = new Encoder(options);
    return encoder.encodeSharedRef(value);
}
function prettyByte(__byte) {
    return "".concat(__byte < 0 ? "-" : "", "0x").concat(Math.abs(__byte).toString(16).padStart(2, "0"));
}
var DEFAULT_MAX_KEY_LENGTH = 16;
var DEFAULT_MAX_LENGTH_PER_KEY = 16;
var CachedKeyDecoder = function() {
    function CachedKeyDecoder(maxKeyLength, maxLengthPerKey) {
        if (maxKeyLength === void 0) {
            maxKeyLength = DEFAULT_MAX_KEY_LENGTH;
        }
        if (maxLengthPerKey === void 0) {
            maxLengthPerKey = DEFAULT_MAX_LENGTH_PER_KEY;
        }
        this.maxKeyLength = maxKeyLength;
        this.maxLengthPerKey = maxLengthPerKey;
        this.hit = 0;
        this.miss = 0;
        this.caches = [];
        for(var i = 0; i < this.maxKeyLength; i++){
            this.caches.push([]);
        }
    }
    CachedKeyDecoder.prototype.canBeCached = function(byteLength) {
        return byteLength > 0 && byteLength <= this.maxKeyLength;
    };
    CachedKeyDecoder.prototype.find = function(bytes, inputOffset, byteLength) {
        var records = this.caches[byteLength - 1];
        FIND_CHUNK: for(var _i = 0, records_1 = records; _i < records_1.length; _i++){
            var record = records_1[_i];
            var recordBytes = record.bytes;
            for(var j = 0; j < byteLength; j++){
                if (recordBytes[j] !== bytes[inputOffset + j]) {
                    continue FIND_CHUNK;
                }
            }
            return record.str;
        }
        return null;
    };
    CachedKeyDecoder.prototype.store = function(bytes, value) {
        var records = this.caches[bytes.length - 1];
        var record = {
            bytes: bytes,
            str: value
        };
        if (records.length >= this.maxLengthPerKey) {
            records[Math.random() * records.length | 0] = record;
        } else {
            records.push(record);
        }
    };
    CachedKeyDecoder.prototype.decode = function(bytes, inputOffset, byteLength) {
        var cachedValue = this.find(bytes, inputOffset, byteLength);
        if (cachedValue != null) {
            this.hit++;
            return cachedValue;
        }
        this.miss++;
        var str = utf8DecodeJs(bytes, inputOffset, byteLength);
        var slicedCopyOfBytes = Uint8Array.prototype.slice.call(bytes, inputOffset, inputOffset + byteLength);
        this.store(slicedCopyOfBytes, str);
        return str;
    };
    return CachedKeyDecoder;
}();
var __awaiter = this && this.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
        return value instanceof P ? value : new P(function(resolve) {
            resolve(value);
        });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
        function fulfilled(value) {
            try {
                step(generator.next(value));
            } catch (e) {
                reject(e);
            }
        }
        function rejected(value) {
            try {
                step(generator["throw"](value));
            } catch (e) {
                reject(e);
            }
        }
        function step(result) {
            result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
        }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = this && this.__generator || function(thisArg, body) {
    var _ = {
        label: 0,
        sent: function() {
            if (t[0] & 1) throw t[1];
            return t[1];
        },
        trys: [],
        ops: []
    }, f, y, t, g;
    return g = {
        next: verb(0),
        "throw": verb(1),
        "return": verb(2)
    }, typeof Symbol === "function" && (g[Symbol.iterator] = function() {
        return this;
    }), g;
    function verb(n) {
        return function(v) {
            return step([
                n,
                v
            ]);
        };
    }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while(g && (g = 0, op[0] && (_ = 0)), _)try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [
                op[0] & 2,
                t.value
            ];
            switch(op[0]){
                case 0:
                case 1:
                    t = op;
                    break;
                case 4:
                    _.label++;
                    return {
                        value: op[1],
                        done: false
                    };
                case 5:
                    _.label++;
                    y = op[1];
                    op = [
                        0
                    ];
                    continue;
                case 7:
                    op = _.ops.pop();
                    _.trys.pop();
                    continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) {
                        _ = 0;
                        continue;
                    }
                    if (op[0] === 3 && (!t || op[1] > t[0] && op[1] < t[3])) {
                        _.label = op[1];
                        break;
                    }
                    if (op[0] === 6 && _.label < t[1]) {
                        _.label = t[1];
                        t = op;
                        break;
                    }
                    if (t && _.label < t[2]) {
                        _.label = t[2];
                        _.ops.push(op);
                        break;
                    }
                    if (t[2]) _.ops.pop();
                    _.trys.pop();
                    continue;
            }
            op = body.call(thisArg, _);
        } catch (e) {
            op = [
                6,
                e
            ];
            y = 0;
        } finally{
            f = t = 0;
        }
        if (op[0] & 5) throw op[1];
        return {
            value: op[0] ? op[1] : void 0,
            done: true
        };
    }
};
var __asyncValues = this && this.__asyncValues || function(o) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var m = o[Symbol.asyncIterator], i;
    return m ? m.call(o) : (o = typeof __values === "function" ? __values(o) : o[Symbol.iterator](), i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function() {
        return this;
    }, i);
    function verb(n) {
        i[n] = o[n] && function(v) {
            return new Promise(function(resolve, reject) {
                v = o[n](v), settle(resolve, reject, v.done, v.value);
            });
        };
    }
    function settle(resolve, reject, d, v) {
        Promise.resolve(v).then(function(v) {
            resolve({
                value: v,
                done: d
            });
        }, reject);
    }
};
var __await = this && this.__await || function(v) {
    return this instanceof __await ? (this.v = v, this) : new __await(v);
};
var __asyncGenerator = this && this.__asyncGenerator || function(thisArg, _arguments, generator) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var g = generator.apply(thisArg, _arguments || []), i, q = [];
    return i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function() {
        return this;
    }, i;
    function verb(n) {
        if (g[n]) i[n] = function(v) {
            return new Promise(function(a, b) {
                q.push([
                    n,
                    v,
                    a,
                    b
                ]) > 1 || resume(n, v);
            });
        };
    }
    function resume(n, v) {
        try {
            step(g[n](v));
        } catch (e) {
            settle(q[0][3], e);
        }
    }
    function step(r) {
        r.value instanceof __await ? Promise.resolve(r.value.v).then(fulfill, reject) : settle(q[0][2], r);
    }
    function fulfill(value) {
        resume("next", value);
    }
    function reject(value) {
        resume("throw", value);
    }
    function settle(f, v) {
        if (f(v), q.shift(), q.length) resume(q[0][0], q[0][1]);
    }
};
var STATE_ARRAY = "array";
var STATE_MAP_KEY = "map_key";
var STATE_MAP_VALUE = "map_value";
var isValidMapKeyType = function(key) {
    return typeof key === "string" || typeof key === "number";
};
var HEAD_BYTE_REQUIRED = -1;
var EMPTY_VIEW = new DataView(new ArrayBuffer(0));
var EMPTY_BYTES = new Uint8Array(EMPTY_VIEW.buffer);
try {
    EMPTY_VIEW.getInt8(0);
} catch (e) {
    if (!(e instanceof RangeError)) {
        throw new Error("This module is not supported in the current JavaScript engine because DataView does not throw RangeError on out-of-bounds access");
    }
}
var DataViewIndexOutOfBoundsError = RangeError;
var MORE_DATA = new DataViewIndexOutOfBoundsError("Insufficient data");
var sharedCachedKeyDecoder = new CachedKeyDecoder();
var Decoder = function() {
    function Decoder(options) {
        var _a, _b, _c, _d, _e, _f, _g;
        this.totalPos = 0;
        this.pos = 0;
        this.view = EMPTY_VIEW;
        this.bytes = EMPTY_BYTES;
        this.headByte = HEAD_BYTE_REQUIRED;
        this.stack = [];
        this.extensionCodec = (_a = options === null || options === void 0 ? void 0 : options.extensionCodec) !== null && _a !== void 0 ? _a : ExtensionCodec.defaultCodec;
        this.context = options === null || options === void 0 ? void 0 : options.context;
        this.useBigInt64 = (_b = options === null || options === void 0 ? void 0 : options.useBigInt64) !== null && _b !== void 0 ? _b : false;
        this.maxStrLength = (_c = options === null || options === void 0 ? void 0 : options.maxStrLength) !== null && _c !== void 0 ? _c : UINT32_MAX;
        this.maxBinLength = (_d = options === null || options === void 0 ? void 0 : options.maxBinLength) !== null && _d !== void 0 ? _d : UINT32_MAX;
        this.maxArrayLength = (_e = options === null || options === void 0 ? void 0 : options.maxArrayLength) !== null && _e !== void 0 ? _e : UINT32_MAX;
        this.maxMapLength = (_f = options === null || options === void 0 ? void 0 : options.maxMapLength) !== null && _f !== void 0 ? _f : UINT32_MAX;
        this.maxExtLength = (_g = options === null || options === void 0 ? void 0 : options.maxExtLength) !== null && _g !== void 0 ? _g : UINT32_MAX;
        this.keyDecoder = (options === null || options === void 0 ? void 0 : options.keyDecoder) !== undefined ? options.keyDecoder : sharedCachedKeyDecoder;
    }
    Decoder.prototype.reinitializeState = function() {
        this.totalPos = 0;
        this.headByte = HEAD_BYTE_REQUIRED;
        this.stack.length = 0;
    };
    Decoder.prototype.setBuffer = function(buffer) {
        this.bytes = ensureUint8Array(buffer);
        this.view = createDataView(this.bytes);
        this.pos = 0;
    };
    Decoder.prototype.appendBuffer = function(buffer) {
        if (this.headByte === HEAD_BYTE_REQUIRED && !this.hasRemaining(1)) {
            this.setBuffer(buffer);
        } else {
            var remainingData = this.bytes.subarray(this.pos);
            var newData = ensureUint8Array(buffer);
            var newBuffer = new Uint8Array(remainingData.length + newData.length);
            newBuffer.set(remainingData);
            newBuffer.set(newData, remainingData.length);
            this.setBuffer(newBuffer);
        }
    };
    Decoder.prototype.hasRemaining = function(size) {
        return this.view.byteLength - this.pos >= size;
    };
    Decoder.prototype.createExtraByteError = function(posToShow) {
        var _a = this, view = _a.view, pos = _a.pos;
        return new RangeError("Extra ".concat(view.byteLength - pos, " of ").concat(view.byteLength, " byte(s) found at buffer[").concat(posToShow, "]"));
    };
    Decoder.prototype.decode = function(buffer) {
        this.reinitializeState();
        this.setBuffer(buffer);
        var object = this.doDecodeSync();
        if (this.hasRemaining(1)) {
            throw this.createExtraByteError(this.pos);
        }
        return object;
    };
    Decoder.prototype.decodeMulti = function(buffer) {
        return __generator(this, function(_a) {
            switch(_a.label){
                case 0:
                    this.reinitializeState();
                    this.setBuffer(buffer);
                    _a.label = 1;
                case 1:
                    if (!this.hasRemaining(1)) return [
                        3,
                        3
                    ];
                    return [
                        4,
                        this.doDecodeSync()
                    ];
                case 2:
                    _a.sent();
                    return [
                        3,
                        1
                    ];
                case 3:
                    return [
                        2
                    ];
            }
        });
    };
    Decoder.prototype.decodeAsync = function(stream) {
        var _a, stream_1, stream_1_1;
        var _b, e_1, _c, _d;
        return __awaiter(this, void 0, void 0, function() {
            var decoded, object, buffer, e_1_1, _e, headByte, pos, totalPos;
            return __generator(this, function(_f) {
                switch(_f.label){
                    case 0:
                        decoded = false;
                        _f.label = 1;
                    case 1:
                        _f.trys.push([
                            1,
                            6,
                            7,
                            12
                        ]);
                        _a = true, stream_1 = __asyncValues(stream);
                        _f.label = 2;
                    case 2:
                        return [
                            4,
                            stream_1.next()
                        ];
                    case 3:
                        if (!(stream_1_1 = _f.sent(), _b = stream_1_1.done, !_b)) return [
                            3,
                            5
                        ];
                        _d = stream_1_1.value;
                        _a = false;
                        try {
                            buffer = _d;
                            if (decoded) {
                                throw this.createExtraByteError(this.totalPos);
                            }
                            this.appendBuffer(buffer);
                            try {
                                object = this.doDecodeSync();
                                decoded = true;
                            } catch (e) {
                                if (!(e instanceof DataViewIndexOutOfBoundsError)) {
                                    throw e;
                                }
                            }
                            this.totalPos += this.pos;
                        } finally{
                            _a = true;
                        }
                        _f.label = 4;
                    case 4:
                        return [
                            3,
                            2
                        ];
                    case 5:
                        return [
                            3,
                            12
                        ];
                    case 6:
                        e_1_1 = _f.sent();
                        e_1 = {
                            error: e_1_1
                        };
                        return [
                            3,
                            12
                        ];
                    case 7:
                        _f.trys.push([
                            7,
                            ,
                            10,
                            11
                        ]);
                        if (!(!_a && !_b && (_c = stream_1.return))) return [
                            3,
                            9
                        ];
                        return [
                            4,
                            _c.call(stream_1)
                        ];
                    case 8:
                        _f.sent();
                        _f.label = 9;
                    case 9:
                        return [
                            3,
                            11
                        ];
                    case 10:
                        if (e_1) throw e_1.error;
                        return [
                            7
                        ];
                    case 11:
                        return [
                            7
                        ];
                    case 12:
                        if (decoded) {
                            if (this.hasRemaining(1)) {
                                throw this.createExtraByteError(this.totalPos);
                            }
                            return [
                                2,
                                object
                            ];
                        }
                        _e = this, headByte = _e.headByte, pos = _e.pos, totalPos = _e.totalPos;
                        throw new RangeError("Insufficient data in parsing ".concat(prettyByte(headByte), " at ").concat(totalPos, " (").concat(pos, " in the current buffer)"));
                }
            });
        });
    };
    Decoder.prototype.decodeArrayStream = function(stream) {
        return this.decodeMultiAsync(stream, true);
    };
    Decoder.prototype.decodeStream = function(stream) {
        return this.decodeMultiAsync(stream, false);
    };
    Decoder.prototype.decodeMultiAsync = function(stream, isArray) {
        return __asyncGenerator(this, arguments, function decodeMultiAsync_1() {
            var isArrayHeaderRequired, arrayItemsLeft, _a, stream_2, stream_2_1, buffer, e_2, e_3_1;
            var _b, e_3, _c, _d;
            return __generator(this, function(_e) {
                switch(_e.label){
                    case 0:
                        isArrayHeaderRequired = isArray;
                        arrayItemsLeft = -1;
                        _e.label = 1;
                    case 1:
                        _e.trys.push([
                            1,
                            15,
                            16,
                            21
                        ]);
                        _a = true, stream_2 = __asyncValues(stream);
                        _e.label = 2;
                    case 2:
                        return [
                            4,
                            __await(stream_2.next())
                        ];
                    case 3:
                        if (!(stream_2_1 = _e.sent(), _b = stream_2_1.done, !_b)) return [
                            3,
                            14
                        ];
                        _d = stream_2_1.value;
                        _a = false;
                        _e.label = 4;
                    case 4:
                        _e.trys.push([
                            4,
                            ,
                            12,
                            13
                        ]);
                        buffer = _d;
                        if (isArray && arrayItemsLeft === 0) {
                            throw this.createExtraByteError(this.totalPos);
                        }
                        this.appendBuffer(buffer);
                        if (isArrayHeaderRequired) {
                            arrayItemsLeft = this.readArraySize();
                            isArrayHeaderRequired = false;
                            this.complete();
                        }
                        _e.label = 5;
                    case 5:
                        _e.trys.push([
                            5,
                            10,
                            ,
                            11
                        ]);
                        _e.label = 6;
                    case 6:
                        if (!true) return [
                            3,
                            9
                        ];
                        return [
                            4,
                            __await(this.doDecodeSync())
                        ];
                    case 7:
                        return [
                            4,
                            _e.sent()
                        ];
                    case 8:
                        _e.sent();
                        if (--arrayItemsLeft === 0) {
                            return [
                                3,
                                9
                            ];
                        }
                        return [
                            3,
                            6
                        ];
                    case 9:
                        return [
                            3,
                            11
                        ];
                    case 10:
                        e_2 = _e.sent();
                        if (!(e_2 instanceof DataViewIndexOutOfBoundsError)) {
                            throw e_2;
                        }
                        return [
                            3,
                            11
                        ];
                    case 11:
                        this.totalPos += this.pos;
                        return [
                            3,
                            13
                        ];
                    case 12:
                        _a = true;
                        return [
                            7
                        ];
                    case 13:
                        return [
                            3,
                            2
                        ];
                    case 14:
                        return [
                            3,
                            21
                        ];
                    case 15:
                        e_3_1 = _e.sent();
                        e_3 = {
                            error: e_3_1
                        };
                        return [
                            3,
                            21
                        ];
                    case 16:
                        _e.trys.push([
                            16,
                            ,
                            19,
                            20
                        ]);
                        if (!(!_a && !_b && (_c = stream_2.return))) return [
                            3,
                            18
                        ];
                        return [
                            4,
                            __await(_c.call(stream_2))
                        ];
                    case 17:
                        _e.sent();
                        _e.label = 18;
                    case 18:
                        return [
                            3,
                            20
                        ];
                    case 19:
                        if (e_3) throw e_3.error;
                        return [
                            7
                        ];
                    case 20:
                        return [
                            7
                        ];
                    case 21:
                        return [
                            2
                        ];
                }
            });
        });
    };
    Decoder.prototype.doDecodeSync = function() {
        DECODE: while(true){
            var headByte = this.readHeadByte();
            var object = void 0;
            if (headByte >= 0xe0) {
                object = headByte - 0x100;
            } else if (headByte < 0xc0) {
                if (headByte < 0x80) {
                    object = headByte;
                } else if (headByte < 0x90) {
                    var size = headByte - 0x80;
                    if (size !== 0) {
                        this.pushMapState(size);
                        this.complete();
                        continue DECODE;
                    } else {
                        object = {};
                    }
                } else if (headByte < 0xa0) {
                    var size = headByte - 0x90;
                    if (size !== 0) {
                        this.pushArrayState(size);
                        this.complete();
                        continue DECODE;
                    } else {
                        object = [];
                    }
                } else {
                    var byteLength = headByte - 0xa0;
                    object = this.decodeUtf8String(byteLength, 0);
                }
            } else if (headByte === 0xc0) {
                object = null;
            } else if (headByte === 0xc2) {
                object = false;
            } else if (headByte === 0xc3) {
                object = true;
            } else if (headByte === 0xca) {
                object = this.readF32();
            } else if (headByte === 0xcb) {
                object = this.readF64();
            } else if (headByte === 0xcc) {
                object = this.readU8();
            } else if (headByte === 0xcd) {
                object = this.readU16();
            } else if (headByte === 0xce) {
                object = this.readU32();
            } else if (headByte === 0xcf) {
                if (this.useBigInt64) {
                    object = this.readU64AsBigInt();
                } else {
                    object = this.readU64();
                }
            } else if (headByte === 0xd0) {
                object = this.readI8();
            } else if (headByte === 0xd1) {
                object = this.readI16();
            } else if (headByte === 0xd2) {
                object = this.readI32();
            } else if (headByte === 0xd3) {
                if (this.useBigInt64) {
                    object = this.readI64AsBigInt();
                } else {
                    object = this.readI64();
                }
            } else if (headByte === 0xd9) {
                var byteLength = this.lookU8();
                object = this.decodeUtf8String(byteLength, 1);
            } else if (headByte === 0xda) {
                var byteLength = this.lookU16();
                object = this.decodeUtf8String(byteLength, 2);
            } else if (headByte === 0xdb) {
                var byteLength = this.lookU32();
                object = this.decodeUtf8String(byteLength, 4);
            } else if (headByte === 0xdc) {
                var size = this.readU16();
                if (size !== 0) {
                    this.pushArrayState(size);
                    this.complete();
                    continue DECODE;
                } else {
                    object = [];
                }
            } else if (headByte === 0xdd) {
                var size = this.readU32();
                if (size !== 0) {
                    this.pushArrayState(size);
                    this.complete();
                    continue DECODE;
                } else {
                    object = [];
                }
            } else if (headByte === 0xde) {
                var size = this.readU16();
                if (size !== 0) {
                    this.pushMapState(size);
                    this.complete();
                    continue DECODE;
                } else {
                    object = {};
                }
            } else if (headByte === 0xdf) {
                var size = this.readU32();
                if (size !== 0) {
                    this.pushMapState(size);
                    this.complete();
                    continue DECODE;
                } else {
                    object = {};
                }
            } else if (headByte === 0xc4) {
                var size = this.lookU8();
                object = this.decodeBinary(size, 1);
            } else if (headByte === 0xc5) {
                var size = this.lookU16();
                object = this.decodeBinary(size, 2);
            } else if (headByte === 0xc6) {
                var size = this.lookU32();
                object = this.decodeBinary(size, 4);
            } else if (headByte === 0xd4) {
                object = this.decodeExtension(1, 0);
            } else if (headByte === 0xd5) {
                object = this.decodeExtension(2, 0);
            } else if (headByte === 0xd6) {
                object = this.decodeExtension(4, 0);
            } else if (headByte === 0xd7) {
                object = this.decodeExtension(8, 0);
            } else if (headByte === 0xd8) {
                object = this.decodeExtension(16, 0);
            } else if (headByte === 0xc7) {
                var size = this.lookU8();
                object = this.decodeExtension(size, 1);
            } else if (headByte === 0xc8) {
                var size = this.lookU16();
                object = this.decodeExtension(size, 2);
            } else if (headByte === 0xc9) {
                var size = this.lookU32();
                object = this.decodeExtension(size, 4);
            } else {
                throw new DecodeError("Unrecognized type byte: ".concat(prettyByte(headByte)));
            }
            this.complete();
            var stack = this.stack;
            while(stack.length > 0){
                var state = stack[stack.length - 1];
                if (state.type === STATE_ARRAY) {
                    state.array[state.position] = object;
                    state.position++;
                    if (state.position === state.size) {
                        stack.pop();
                        object = state.array;
                    } else {
                        continue DECODE;
                    }
                } else if (state.type === STATE_MAP_KEY) {
                    if (!isValidMapKeyType(object)) {
                        throw new DecodeError("The type of key must be string or number but " + typeof object);
                    }
                    if (object === "__proto__") {
                        throw new DecodeError("The key __proto__ is not allowed");
                    }
                    state.key = object;
                    state.type = STATE_MAP_VALUE;
                    continue DECODE;
                } else {
                    state.map[state.key] = object;
                    state.readCount++;
                    if (state.readCount === state.size) {
                        stack.pop();
                        object = state.map;
                    } else {
                        state.key = null;
                        state.type = STATE_MAP_KEY;
                        continue DECODE;
                    }
                }
            }
            return object;
        }
    };
    Decoder.prototype.readHeadByte = function() {
        if (this.headByte === HEAD_BYTE_REQUIRED) {
            this.headByte = this.readU8();
        }
        return this.headByte;
    };
    Decoder.prototype.complete = function() {
        this.headByte = HEAD_BYTE_REQUIRED;
    };
    Decoder.prototype.readArraySize = function() {
        var headByte = this.readHeadByte();
        switch(headByte){
            case 0xdc:
                return this.readU16();
            case 0xdd:
                return this.readU32();
            default:
                {
                    if (headByte < 0xa0) {
                        return headByte - 0x90;
                    } else {
                        throw new DecodeError("Unrecognized array type byte: ".concat(prettyByte(headByte)));
                    }
                }
        }
    };
    Decoder.prototype.pushMapState = function(size) {
        if (size > this.maxMapLength) {
            throw new DecodeError("Max length exceeded: map length (".concat(size, ") > maxMapLengthLength (").concat(this.maxMapLength, ")"));
        }
        this.stack.push({
            type: STATE_MAP_KEY,
            size: size,
            key: null,
            readCount: 0,
            map: {}
        });
    };
    Decoder.prototype.pushArrayState = function(size) {
        if (size > this.maxArrayLength) {
            throw new DecodeError("Max length exceeded: array length (".concat(size, ") > maxArrayLength (").concat(this.maxArrayLength, ")"));
        }
        this.stack.push({
            type: STATE_ARRAY,
            size: size,
            array: new Array(size),
            position: 0
        });
    };
    Decoder.prototype.decodeUtf8String = function(byteLength, headerOffset) {
        var _a;
        if (byteLength > this.maxStrLength) {
            throw new DecodeError("Max length exceeded: UTF-8 byte length (".concat(byteLength, ") > maxStrLength (").concat(this.maxStrLength, ")"));
        }
        if (this.bytes.byteLength < this.pos + headerOffset + byteLength) {
            throw MORE_DATA;
        }
        var offset = this.pos + headerOffset;
        var object;
        if (this.stateIsMapKey() && ((_a = this.keyDecoder) === null || _a === void 0 ? void 0 : _a.canBeCached(byteLength))) {
            object = this.keyDecoder.decode(this.bytes, offset, byteLength);
        } else {
            object = utf8Decode(this.bytes, offset, byteLength);
        }
        this.pos += headerOffset + byteLength;
        return object;
    };
    Decoder.prototype.stateIsMapKey = function() {
        if (this.stack.length > 0) {
            var state = this.stack[this.stack.length - 1];
            return state.type === STATE_MAP_KEY;
        }
        return false;
    };
    Decoder.prototype.decodeBinary = function(byteLength, headOffset) {
        if (byteLength > this.maxBinLength) {
            throw new DecodeError("Max length exceeded: bin length (".concat(byteLength, ") > maxBinLength (").concat(this.maxBinLength, ")"));
        }
        if (!this.hasRemaining(byteLength + headOffset)) {
            throw MORE_DATA;
        }
        var offset = this.pos + headOffset;
        var object = this.bytes.subarray(offset, offset + byteLength);
        this.pos += headOffset + byteLength;
        return object;
    };
    Decoder.prototype.decodeExtension = function(size, headOffset) {
        if (size > this.maxExtLength) {
            throw new DecodeError("Max length exceeded: ext length (".concat(size, ") > maxExtLength (").concat(this.maxExtLength, ")"));
        }
        var extType = this.view.getInt8(this.pos + headOffset);
        var data = this.decodeBinary(size, headOffset + 1);
        return this.extensionCodec.decode(data, extType, this.context);
    };
    Decoder.prototype.lookU8 = function() {
        return this.view.getUint8(this.pos);
    };
    Decoder.prototype.lookU16 = function() {
        return this.view.getUint16(this.pos);
    };
    Decoder.prototype.lookU32 = function() {
        return this.view.getUint32(this.pos);
    };
    Decoder.prototype.readU8 = function() {
        var value = this.view.getUint8(this.pos);
        this.pos++;
        return value;
    };
    Decoder.prototype.readI8 = function() {
        var value = this.view.getInt8(this.pos);
        this.pos++;
        return value;
    };
    Decoder.prototype.readU16 = function() {
        var value = this.view.getUint16(this.pos);
        this.pos += 2;
        return value;
    };
    Decoder.prototype.readI16 = function() {
        var value = this.view.getInt16(this.pos);
        this.pos += 2;
        return value;
    };
    Decoder.prototype.readU32 = function() {
        var value = this.view.getUint32(this.pos);
        this.pos += 4;
        return value;
    };
    Decoder.prototype.readI32 = function() {
        var value = this.view.getInt32(this.pos);
        this.pos += 4;
        return value;
    };
    Decoder.prototype.readU64 = function() {
        var value = getUint64(this.view, this.pos);
        this.pos += 8;
        return value;
    };
    Decoder.prototype.readI64 = function() {
        var value = getInt64(this.view, this.pos);
        this.pos += 8;
        return value;
    };
    Decoder.prototype.readU64AsBigInt = function() {
        var value = this.view.getBigUint64(this.pos);
        this.pos += 8;
        return value;
    };
    Decoder.prototype.readI64AsBigInt = function() {
        var value = this.view.getBigInt64(this.pos);
        this.pos += 8;
        return value;
    };
    Decoder.prototype.readF32 = function() {
        var value = this.view.getFloat32(this.pos);
        this.pos += 4;
        return value;
    };
    Decoder.prototype.readF64 = function() {
        var value = this.view.getFloat64(this.pos);
        this.pos += 8;
        return value;
    };
    return Decoder;
}();
function decode(buffer, options) {
    var decoder = new Decoder(options);
    return decoder.decode(buffer);
}
this && this.__generator || function(thisArg, body) {
    var _ = {
        label: 0,
        sent: function() {
            if (t[0] & 1) throw t[1];
            return t[1];
        },
        trys: [],
        ops: []
    }, f, y, t, g;
    return g = {
        next: verb(0),
        "throw": verb(1),
        "return": verb(2)
    }, typeof Symbol === "function" && (g[Symbol.iterator] = function() {
        return this;
    }), g;
    function verb(n) {
        return function(v) {
            return step([
                n,
                v
            ]);
        };
    }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while(g && (g = 0, op[0] && (_ = 0)), _)try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [
                op[0] & 2,
                t.value
            ];
            switch(op[0]){
                case 0:
                case 1:
                    t = op;
                    break;
                case 4:
                    _.label++;
                    return {
                        value: op[1],
                        done: false
                    };
                case 5:
                    _.label++;
                    y = op[1];
                    op = [
                        0
                    ];
                    continue;
                case 7:
                    op = _.ops.pop();
                    _.trys.pop();
                    continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) {
                        _ = 0;
                        continue;
                    }
                    if (op[0] === 3 && (!t || op[1] > t[0] && op[1] < t[3])) {
                        _.label = op[1];
                        break;
                    }
                    if (op[0] === 6 && _.label < t[1]) {
                        _.label = t[1];
                        t = op;
                        break;
                    }
                    if (t && _.label < t[2]) {
                        _.label = t[2];
                        _.ops.push(op);
                        break;
                    }
                    if (t[2]) _.ops.pop();
                    _.trys.pop();
                    continue;
            }
            op = body.call(thisArg, _);
        } catch (e) {
            op = [
                6,
                e
            ];
            y = 0;
        } finally{
            f = t = 0;
        }
        if (op[0] & 5) throw op[1];
        return {
            value: op[0] ? op[1] : void 0,
            done: true
        };
    }
};
var __await1 = this && this.__await || function(v) {
    return this instanceof __await1 ? (this.v = v, this) : new __await1(v);
};
this && this.__asyncGenerator || function(thisArg, _arguments, generator) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var g = generator.apply(thisArg, _arguments || []), i, q = [];
    return i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function() {
        return this;
    }, i;
    function verb(n) {
        if (g[n]) i[n] = function(v) {
            return new Promise(function(a, b) {
                q.push([
                    n,
                    v,
                    a,
                    b
                ]) > 1 || resume(n, v);
            });
        };
    }
    function resume(n, v) {
        try {
            step(g[n](v));
        } catch (e) {
            settle(q[0][3], e);
        }
    }
    function step(r) {
        r.value instanceof __await1 ? Promise.resolve(r.value.v).then(fulfill, reject) : settle(q[0][2], r);
    }
    function fulfill(value) {
        resume("next", value);
    }
    function reject(value) {
        resume("throw", value);
    }
    function settle(f, v) {
        if (f(v), q.shift(), q.length) resume(q[0][0], q[0][1]);
    }
};
this && this.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
        return value instanceof P ? value : new P(function(resolve) {
            resolve(value);
        });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
        function fulfilled(value) {
            try {
                step(generator.next(value));
            } catch (e) {
                reject(e);
            }
        }
        function rejected(value) {
            try {
                step(generator["throw"](value));
            } catch (e) {
                reject(e);
            }
        }
        function step(result) {
            result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
        }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
this && this.__generator || function(thisArg, body) {
    var _ = {
        label: 0,
        sent: function() {
            if (t[0] & 1) throw t[1];
            return t[1];
        },
        trys: [],
        ops: []
    }, f, y, t, g;
    return g = {
        next: verb(0),
        "throw": verb(1),
        "return": verb(2)
    }, typeof Symbol === "function" && (g[Symbol.iterator] = function() {
        return this;
    }), g;
    function verb(n) {
        return function(v) {
            return step([
                n,
                v
            ]);
        };
    }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while(g && (g = 0, op[0] && (_ = 0)), _)try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [
                op[0] & 2,
                t.value
            ];
            switch(op[0]){
                case 0:
                case 1:
                    t = op;
                    break;
                case 4:
                    _.label++;
                    return {
                        value: op[1],
                        done: false
                    };
                case 5:
                    _.label++;
                    y = op[1];
                    op = [
                        0
                    ];
                    continue;
                case 7:
                    op = _.ops.pop();
                    _.trys.pop();
                    continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) {
                        _ = 0;
                        continue;
                    }
                    if (op[0] === 3 && (!t || op[1] > t[0] && op[1] < t[3])) {
                        _.label = op[1];
                        break;
                    }
                    if (op[0] === 6 && _.label < t[1]) {
                        _.label = t[1];
                        t = op;
                        break;
                    }
                    if (t && _.label < t[2]) {
                        _.label = t[2];
                        _.ops.push(op);
                        break;
                    }
                    if (t[2]) _.ops.pop();
                    _.trys.pop();
                    continue;
            }
            op = body.call(thisArg, _);
        } catch (e) {
            op = [
                6,
                e
            ];
            y = 0;
        } finally{
            f = t = 0;
        }
        if (op[0] & 5) throw op[1];
        return {
            value: op[0] ? op[1] : void 0,
            done: true
        };
    }
};
function _e(e) {
    let i = e.length;
    for(; --i >= 0;)e[i] = 0;
}
var $i = 0, ai = 1, Ci = 2, Fi = 3, Mi = 258, dt = 29, Ae = 256, ge = Ae + 1 + dt, oe = 30, st = 19, ni = 2 * ge + 1, Q = 15, Ge = 16, Hi = 7, ct = 256, li = 16, ri = 17, fi = 18, ft = new Uint8Array([
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    0
]), $e = new Uint8Array([
    0,
    0,
    0,
    0,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    6,
    7,
    7,
    8,
    8,
    9,
    9,
    10,
    10,
    11,
    11,
    12,
    12,
    13,
    13
]), Bi = new Uint8Array([
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    3,
    7
]), oi = new Uint8Array([
    16,
    17,
    18,
    0,
    8,
    7,
    9,
    6,
    10,
    5,
    11,
    4,
    12,
    3,
    13,
    2,
    14,
    1,
    15
]), Ki = 512, B = new Array((ge + 2) * 2);
_e(B);
var ue = new Array(oe * 2);
_e(ue);
var pe = new Array(Ki);
_e(pe);
var xe = new Array(Mi - Fi + 1);
_e(xe);
var ut = new Array(dt);
_e(ut);
var He = new Array(oe);
_e(He);
function je(e, i, t, n, a) {
    this.static_tree = e, this.extra_bits = i, this.extra_base = t, this.elems = n, this.max_length = a, this.has_stree = e && e.length;
}
var _i, hi, di;
function We(e, i) {
    this.dyn_tree = e, this.max_code = 0, this.stat_desc = i;
}
var si = (e)=>e < 256 ? pe[e] : pe[256 + (e >>> 7)], ke = (e, i)=>{
    e.pending_buf[e.pending++] = i & 255, e.pending_buf[e.pending++] = i >>> 8 & 255;
}, N1 = (e, i, t)=>{
    e.bi_valid > Ge - t ? (e.bi_buf |= i << e.bi_valid & 65535, ke(e, e.bi_buf), e.bi_buf = i >> Ge - e.bi_valid, e.bi_valid += t - Ge) : (e.bi_buf |= i << e.bi_valid & 65535, e.bi_valid += t);
}, F = (e, i, t)=>{
    N1(e, t[i * 2], t[i * 2 + 1]);
}, ci = (e, i)=>{
    let t = 0;
    do t |= e & 1, e >>>= 1, t <<= 1;
    while (--i > 0)
    return t >>> 1;
}, Pi = (e)=>{
    e.bi_valid === 16 ? (ke(e, e.bi_buf), e.bi_buf = 0, e.bi_valid = 0) : e.bi_valid >= 8 && (e.pending_buf[e.pending++] = e.bi_buf & 255, e.bi_buf >>= 8, e.bi_valid -= 8);
}, Xi = (e, i)=>{
    let t = i.dyn_tree, n = i.max_code, a = i.stat_desc.static_tree, l = i.stat_desc.has_stree, o = i.stat_desc.extra_bits, f = i.stat_desc.extra_base, c = i.stat_desc.max_length, r, _, E, s, h, u, m = 0;
    for(s = 0; s <= Q; s++)e.bl_count[s] = 0;
    for(t[e.heap[e.heap_max] * 2 + 1] = 0, r = e.heap_max + 1; r < ni; r++)_ = e.heap[r], s = t[t[_ * 2 + 1] * 2 + 1] + 1, s > c && (s = c, m++), t[_ * 2 + 1] = s, !(_ > n) && (e.bl_count[s]++, h = 0, _ >= f && (h = o[_ - f]), u = t[_ * 2], e.opt_len += u * (s + h), l && (e.static_len += u * (a[_ * 2 + 1] + h)));
    if (m !== 0) {
        do {
            for(s = c - 1; e.bl_count[s] === 0;)s--;
            e.bl_count[s]--, e.bl_count[s + 1] += 2, e.bl_count[c]--, m -= 2;
        }while (m > 0)
        for(s = c; s !== 0; s--)for(_ = e.bl_count[s]; _ !== 0;)E = e.heap[--r], !(E > n) && (t[E * 2 + 1] !== s && (e.opt_len += (s - t[E * 2 + 1]) * t[E * 2], t[E * 2 + 1] = s), _--);
    }
}, ui = (e, i, t)=>{
    let n = new Array(Q + 1), a = 0, l, o;
    for(l = 1; l <= Q; l++)n[l] = a = a + t[l - 1] << 1;
    for(o = 0; o <= i; o++){
        let f = e[o * 2 + 1];
        f !== 0 && (e[o * 2] = ci(n[f]++, f));
    }
}, Yi = ()=>{
    let e, i, t, n, a, l = new Array(Q + 1);
    for(t = 0, n = 0; n < dt - 1; n++)for(ut[n] = t, e = 0; e < 1 << ft[n]; e++)xe[t++] = n;
    for(xe[t - 1] = n, a = 0, n = 0; n < 16; n++)for(He[n] = a, e = 0; e < 1 << $e[n]; e++)pe[a++] = n;
    for(a >>= 7; n < oe; n++)for(He[n] = a << 7, e = 0; e < 1 << $e[n] - 7; e++)pe[256 + a++] = n;
    for(i = 0; i <= Q; i++)l[i] = 0;
    for(e = 0; e <= 143;)B[e * 2 + 1] = 8, e++, l[8]++;
    for(; e <= 255;)B[e * 2 + 1] = 9, e++, l[9]++;
    for(; e <= 279;)B[e * 2 + 1] = 7, e++, l[7]++;
    for(; e <= 287;)B[e * 2 + 1] = 8, e++, l[8]++;
    for(ui(B, ge + 1, l), e = 0; e < oe; e++)ue[e * 2 + 1] = 5, ue[e * 2] = ci(e, 5);
    _i = new je(B, ft, Ae + 1, ge, Q), hi = new je(ue, $e, 0, oe, Q), di = new je(new Array(0), Bi, 0, st, Hi);
}, bi = (e)=>{
    let i;
    for(i = 0; i < ge; i++)e.dyn_ltree[i * 2] = 0;
    for(i = 0; i < oe; i++)e.dyn_dtree[i * 2] = 0;
    for(i = 0; i < st; i++)e.bl_tree[i * 2] = 0;
    e.dyn_ltree[ct * 2] = 1, e.opt_len = e.static_len = 0, e.last_lit = e.matches = 0;
}, wi = (e)=>{
    e.bi_valid > 8 ? ke(e, e.bi_buf) : e.bi_valid > 0 && (e.pending_buf[e.pending++] = e.bi_buf), e.bi_buf = 0, e.bi_valid = 0;
}, Gi = (e, i, t, n)=>{
    wi(e), n && (ke(e, t), ke(e, ~t)), e.pending_buf.set(e.window.subarray(i, i + t), e.pending), e.pending += t;
}, xt = (e, i, t, n)=>{
    let a = i * 2, l = t * 2;
    return e[a] < e[l] || e[a] === e[l] && n[i] <= n[t];
}, Ve = (e, i, t)=>{
    let n = e.heap[t], a = t << 1;
    for(; a <= e.heap_len && (a < e.heap_len && xt(i, e.heap[a + 1], e.heap[a], e.depth) && a++, !xt(i, n, e.heap[a], e.depth));)e.heap[t] = e.heap[a], t = a, a <<= 1;
    e.heap[t] = n;
}, kt = (e, i, t)=>{
    let n, a, l = 0, o, f;
    if (e.last_lit !== 0) do n = e.pending_buf[e.d_buf + l * 2] << 8 | e.pending_buf[e.d_buf + l * 2 + 1], a = e.pending_buf[e.l_buf + l], l++, n === 0 ? F(e, a, i) : (o = xe[a], F(e, o + Ae + 1, i), f = ft[o], f !== 0 && (a -= ut[o], N1(e, a, f)), n--, o = si(n), F(e, o, t), f = $e[o], f !== 0 && (n -= He[o], N1(e, n, f)));
    while (l < e.last_lit)
    F(e, ct, i);
}, ot = (e, i)=>{
    let t = i.dyn_tree, n = i.stat_desc.static_tree, a = i.stat_desc.has_stree, l = i.stat_desc.elems, o, f, c = -1, r;
    for(e.heap_len = 0, e.heap_max = ni, o = 0; o < l; o++)t[o * 2] !== 0 ? (e.heap[++e.heap_len] = c = o, e.depth[o] = 0) : t[o * 2 + 1] = 0;
    for(; e.heap_len < 2;)r = e.heap[++e.heap_len] = c < 2 ? ++c : 0, t[r * 2] = 1, e.depth[r] = 0, e.opt_len--, a && (e.static_len -= n[r * 2 + 1]);
    for(i.max_code = c, o = e.heap_len >> 1; o >= 1; o--)Ve(e, t, o);
    r = l;
    do o = e.heap[1], e.heap[1] = e.heap[e.heap_len--], Ve(e, t, 1), f = e.heap[1], e.heap[--e.heap_max] = o, e.heap[--e.heap_max] = f, t[r * 2] = t[o * 2] + t[f * 2], e.depth[r] = (e.depth[o] >= e.depth[f] ? e.depth[o] : e.depth[f]) + 1, t[o * 2 + 1] = t[f * 2 + 1] = r, e.heap[1] = r++, Ve(e, t, 1);
    while (e.heap_len >= 2)
    e.heap[--e.heap_max] = e.heap[1], Xi(e, i), ui(t, c, e.bl_count);
}, vt = (e, i, t)=>{
    let n, a = -1, l, o = i[0 * 2 + 1], f = 0, c = 7, r = 4;
    for(o === 0 && (c = 138, r = 3), i[(t + 1) * 2 + 1] = 65535, n = 0; n <= t; n++)l = o, o = i[(n + 1) * 2 + 1], !(++f < c && l === o) && (f < r ? e.bl_tree[l * 2] += f : l !== 0 ? (l !== a && e.bl_tree[l * 2]++, e.bl_tree[li * 2]++) : f <= 10 ? e.bl_tree[ri * 2]++ : e.bl_tree[fi * 2]++, f = 0, a = l, o === 0 ? (c = 138, r = 3) : l === o ? (c = 6, r = 3) : (c = 7, r = 4));
}, Et = (e, i, t)=>{
    let n, a = -1, l, o = i[0 * 2 + 1], f = 0, c = 7, r = 4;
    for(o === 0 && (c = 138, r = 3), n = 0; n <= t; n++)if (l = o, o = i[(n + 1) * 2 + 1], !(++f < c && l === o)) {
        if (f < r) do F(e, l, e.bl_tree);
        while (--f !== 0)
        else l !== 0 ? (l !== a && (F(e, l, e.bl_tree), f--), F(e, li, e.bl_tree), N1(e, f - 3, 2)) : f <= 10 ? (F(e, ri, e.bl_tree), N1(e, f - 3, 3)) : (F(e, fi, e.bl_tree), N1(e, f - 11, 7));
        f = 0, a = l, o === 0 ? (c = 138, r = 3) : l === o ? (c = 6, r = 3) : (c = 7, r = 4);
    }
}, ji = (e)=>{
    let i;
    for(vt(e, e.dyn_ltree, e.l_desc.max_code), vt(e, e.dyn_dtree, e.d_desc.max_code), ot(e, e.bl_desc), i = st - 1; i >= 3 && e.bl_tree[oi[i] * 2 + 1] === 0; i--);
    return e.opt_len += 3 * (i + 1) + 5 + 5 + 4, i;
}, Wi = (e, i, t, n)=>{
    let a;
    for(N1(e, i - 257, 5), N1(e, t - 1, 5), N1(e, n - 4, 4), a = 0; a < n; a++)N1(e, e.bl_tree[oi[a] * 2 + 1], 3);
    Et(e, e.dyn_ltree, i - 1), Et(e, e.dyn_dtree, t - 1);
}, Vi = (e)=>{
    let i = 4093624447, t;
    for(t = 0; t <= 31; t++, i >>>= 1)if (i & 1 && e.dyn_ltree[t * 2] !== 0) return 0;
    if (e.dyn_ltree[9 * 2] !== 0 || e.dyn_ltree[10 * 2] !== 0 || e.dyn_ltree[13 * 2] !== 0) return 1;
    for(t = 32; t < Ae; t++)if (e.dyn_ltree[t * 2] !== 0) return 1;
    return 0;
}, yt = !1, Ji = (e)=>{
    yt || (Yi(), yt = !0), e.l_desc = new We(e.dyn_ltree, _i), e.d_desc = new We(e.dyn_dtree, hi), e.bl_desc = new We(e.bl_tree, di), e.bi_buf = 0, e.bi_valid = 0, bi(e);
}, gi = (e, i, t, n)=>{
    N1(e, ($i << 1) + (n ? 1 : 0), 3), Gi(e, i, t, !0);
}, Qi = (e)=>{
    N1(e, ai << 1, 3), F(e, ct, B), Pi(e);
}, qi = (e, i, t, n)=>{
    let a, l, o = 0;
    e.level > 0 ? (e.strm.data_type === 2 && (e.strm.data_type = Vi(e)), ot(e, e.l_desc), ot(e, e.d_desc), o = ji(e), a = e.opt_len + 3 + 7 >>> 3, l = e.static_len + 3 + 7 >>> 3, l <= a && (a = l)) : a = l = t + 5, t + 4 <= a && i !== -1 ? gi(e, i, t, n) : e.strategy === 4 || l === a ? (N1(e, (ai << 1) + (n ? 1 : 0), 3), kt(e, B, ue)) : (N1(e, (Ci << 1) + (n ? 1 : 0), 3), Wi(e, e.l_desc.max_code + 1, e.d_desc.max_code + 1, o + 1), kt(e, e.dyn_ltree, e.dyn_dtree)), bi(e), n && wi(e);
}, ea = (e, i, t)=>(e.pending_buf[e.d_buf + e.last_lit * 2] = i >>> 8 & 255, e.pending_buf[e.d_buf + e.last_lit * 2 + 1] = i & 255, e.pending_buf[e.l_buf + e.last_lit] = t & 255, e.last_lit++, i === 0 ? e.dyn_ltree[t * 2]++ : (e.matches++, i--, e.dyn_ltree[(xe[t] + Ae + 1) * 2]++, e.dyn_dtree[si(i) * 2]++), e.last_lit === e.lit_bufsize - 1), ta = Ji, ia = gi, aa = qi, na = ea, la = Qi, ra = {
    _tr_init: ta,
    _tr_stored_block: ia,
    _tr_flush_block: aa,
    _tr_tally: na,
    _tr_align: la
}, fa = (e, i, t, n)=>{
    let a = e & 65535 | 0, l = e >>> 16 & 65535 | 0, o = 0;
    for(; t !== 0;){
        o = t > 2e3 ? 2e3 : t, t -= o;
        do a = a + i[n++] | 0, l = l + a | 0;
        while (--o)
        a %= 65521, l %= 65521;
    }
    return a | l << 16 | 0;
}, ve = fa, oa = ()=>{
    let e, i = [];
    for(var t = 0; t < 256; t++){
        e = t;
        for(var n = 0; n < 8; n++)e = e & 1 ? 3988292384 ^ e >>> 1 : e >>> 1;
        i[t] = e;
    }
    return i;
}, _a = new Uint32Array(oa()), ha = (e, i, t, n)=>{
    let a = _a, l = n + t;
    e ^= -1;
    for(let o = n; o < l; o++)e = e >>> 8 ^ a[(e ^ i[o]) & 255];
    return e ^ -1;
}, I = ha, ee = {
    2: "need dictionary",
    1: "stream end",
    0: "",
    "-1": "file error",
    "-2": "stream error",
    "-3": "data error",
    "-4": "insufficient memory",
    "-5": "buffer error",
    "-6": "incompatible version"
}, ne = {
    Z_NO_FLUSH: 0,
    Z_PARTIAL_FLUSH: 1,
    Z_SYNC_FLUSH: 2,
    Z_FULL_FLUSH: 3,
    Z_FINISH: 4,
    Z_BLOCK: 5,
    Z_TREES: 6,
    Z_OK: 0,
    Z_STREAM_END: 1,
    Z_NEED_DICT: 2,
    Z_ERRNO: -1,
    Z_STREAM_ERROR: -2,
    Z_DATA_ERROR: -3,
    Z_MEM_ERROR: -4,
    Z_BUF_ERROR: -5,
    Z_NO_COMPRESSION: 0,
    Z_BEST_SPEED: 1,
    Z_BEST_COMPRESSION: 9,
    Z_DEFAULT_COMPRESSION: -1,
    Z_FILTERED: 1,
    Z_HUFFMAN_ONLY: 2,
    Z_RLE: 3,
    Z_FIXED: 4,
    Z_DEFAULT_STRATEGY: 0,
    Z_BINARY: 0,
    Z_TEXT: 1,
    Z_UNKNOWN: 2,
    Z_DEFLATED: 8
}, { _tr_init: da , _tr_stored_block: sa , _tr_flush_block: ca , _tr_tally: j , _tr_align: ua  } = ra, { Z_NO_FLUSH: le , Z_PARTIAL_FLUSH: ba , Z_FULL_FLUSH: wa , Z_FINISH: W , Z_BLOCK: St , Z_OK: M , Z_STREAM_END: At , Z_STREAM_ERROR: L1 , Z_DATA_ERROR: ga , Z_BUF_ERROR: Je , Z_DEFAULT_COMPRESSION: pa , Z_FILTERED: xa , Z_HUFFMAN_ONLY: Ie , Z_RLE: ka , Z_FIXED: va , Z_DEFAULT_STRATEGY: Ea , Z_UNKNOWN: ya , Z_DEFLATED: Pe  } = ne, Sa = 9, Aa = 15, Ra = 8, za = 29, Ta = 256, _t = Ta + 1 + za, ma = 30, Da = 19, Za = 2 * _t + 1, Ia = 15, k1 = 3, Y = 258, $ = Y + k1 + 1, Oa = 32, Xe = 42, ht = 69, Ce = 73, Fe = 91, Me = 103, q = 113, se = 666, D = 1, Re = 2, te = 3, he = 4, Na = 3, G = (e, i)=>(e.msg = ee[i], i), Rt = (e)=>(e << 1) - (e > 4 ? 9 : 0), X = (e)=>{
    let i = e.length;
    for(; --i >= 0;)e[i] = 0;
}, La = (e, i, t)=>(i << e.hash_shift ^ t) & e.hash_mask, V = La, P1 = (e)=>{
    let i = e.state, t = i.pending;
    t > e.avail_out && (t = e.avail_out), t !== 0 && (e.output.set(i.pending_buf.subarray(i.pending_out, i.pending_out + t), e.next_out), e.next_out += t, i.pending_out += t, e.total_out += t, e.avail_out -= t, i.pending -= t, i.pending === 0 && (i.pending_out = 0));
}, O1 = (e, i)=>{
    ca(e, e.block_start >= 0 ? e.block_start : -1, e.strstart - e.block_start, i), e.block_start = e.strstart, P1(e.strm);
}, y = (e, i)=>{
    e.pending_buf[e.pending++] = i;
}, de = (e, i)=>{
    e.pending_buf[e.pending++] = i >>> 8 & 255, e.pending_buf[e.pending++] = i & 255;
}, Ua = (e, i, t, n)=>{
    let a = e.avail_in;
    return a > n && (a = n), a === 0 ? 0 : (e.avail_in -= a, i.set(e.input.subarray(e.next_in, e.next_in + a), t), e.state.wrap === 1 ? e.adler = ve(e.adler, i, a, t) : e.state.wrap === 2 && (e.adler = I(e.adler, i, a, t)), e.next_in += a, e.total_in += a, a);
}, pi = (e, i)=>{
    let t = e.max_chain_length, n = e.strstart, a, l, o = e.prev_length, f = e.nice_match, c = e.strstart > e.w_size - $ ? e.strstart - (e.w_size - $) : 0, r = e.window, _ = e.w_mask, E = e.prev, s = e.strstart + Y, h = r[n + o - 1], u = r[n + o];
    e.prev_length >= e.good_match && (t >>= 2), f > e.lookahead && (f = e.lookahead);
    do if (a = i, !(r[a + o] !== u || r[a + o - 1] !== h || r[a] !== r[n] || r[++a] !== r[n + 1])) {
        n += 2, a++;
        do ;
        while (r[++n] === r[++a] && r[++n] === r[++a] && r[++n] === r[++a] && r[++n] === r[++a] && r[++n] === r[++a] && r[++n] === r[++a] && r[++n] === r[++a] && r[++n] === r[++a] && n < s)
        if (l = Y - (s - n), n = s - Y, l > o) {
            if (e.match_start = i, o = l, l >= f) break;
            h = r[n + o - 1], u = r[n + o];
        }
    }
    while ((i = E[i & _]) > c && --t !== 0)
    return o <= e.lookahead ? o : e.lookahead;
}, ie = (e)=>{
    let i = e.w_size, t, n, a, l, o;
    do {
        if (l = e.window_size - e.lookahead - e.strstart, e.strstart >= i + (i - $)) {
            e.window.set(e.window.subarray(i, i + i), 0), e.match_start -= i, e.strstart -= i, e.block_start -= i, n = e.hash_size, t = n;
            do a = e.head[--t], e.head[t] = a >= i ? a - i : 0;
            while (--n)
            n = i, t = n;
            do a = e.prev[--t], e.prev[t] = a >= i ? a - i : 0;
            while (--n)
            l += i;
        }
        if (e.strm.avail_in === 0) break;
        if (n = Ua(e.strm, e.window, e.strstart + e.lookahead, l), e.lookahead += n, e.lookahead + e.insert >= k1) for(o = e.strstart - e.insert, e.ins_h = e.window[o], e.ins_h = V(e, e.ins_h, e.window[o + 1]); e.insert && (e.ins_h = V(e, e.ins_h, e.window[o + k1 - 1]), e.prev[o & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = o, o++, e.insert--, !(e.lookahead + e.insert < k1)););
    }while (e.lookahead < $ && e.strm.avail_in !== 0)
}, $a = (e, i)=>{
    let t = 65535;
    for(t > e.pending_buf_size - 5 && (t = e.pending_buf_size - 5);;){
        if (e.lookahead <= 1) {
            if (ie(e), e.lookahead === 0 && i === le) return D;
            if (e.lookahead === 0) break;
        }
        e.strstart += e.lookahead, e.lookahead = 0;
        let n = e.block_start + t;
        if ((e.strstart === 0 || e.strstart >= n) && (e.lookahead = e.strstart - n, e.strstart = n, O1(e, !1), e.strm.avail_out === 0) || e.strstart - e.block_start >= e.w_size - $ && (O1(e, !1), e.strm.avail_out === 0)) return D;
    }
    return e.insert = 0, i === W ? (O1(e, !0), e.strm.avail_out === 0 ? te : he) : (e.strstart > e.block_start && (O1(e, !1), e.strm.avail_out === 0), D);
}, Qe = (e, i)=>{
    let t, n;
    for(;;){
        if (e.lookahead < $) {
            if (ie(e), e.lookahead < $ && i === le) return D;
            if (e.lookahead === 0) break;
        }
        if (t = 0, e.lookahead >= k1 && (e.ins_h = V(e, e.ins_h, e.window[e.strstart + k1 - 1]), t = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart), t !== 0 && e.strstart - t <= e.w_size - $ && (e.match_length = pi(e, t)), e.match_length >= k1) if (n = j(e, e.strstart - e.match_start, e.match_length - k1), e.lookahead -= e.match_length, e.match_length <= e.max_lazy_match && e.lookahead >= k1) {
            e.match_length--;
            do e.strstart++, e.ins_h = V(e, e.ins_h, e.window[e.strstart + k1 - 1]), t = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart;
            while (--e.match_length !== 0)
            e.strstart++;
        } else e.strstart += e.match_length, e.match_length = 0, e.ins_h = e.window[e.strstart], e.ins_h = V(e, e.ins_h, e.window[e.strstart + 1]);
        else n = j(e, 0, e.window[e.strstart]), e.lookahead--, e.strstart++;
        if (n && (O1(e, !1), e.strm.avail_out === 0)) return D;
    }
    return e.insert = e.strstart < k1 - 1 ? e.strstart : k1 - 1, i === W ? (O1(e, !0), e.strm.avail_out === 0 ? te : he) : e.last_lit && (O1(e, !1), e.strm.avail_out === 0) ? D : Re;
}, re = (e, i)=>{
    let t, n, a;
    for(;;){
        if (e.lookahead < $) {
            if (ie(e), e.lookahead < $ && i === le) return D;
            if (e.lookahead === 0) break;
        }
        if (t = 0, e.lookahead >= k1 && (e.ins_h = V(e, e.ins_h, e.window[e.strstart + k1 - 1]), t = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart), e.prev_length = e.match_length, e.prev_match = e.match_start, e.match_length = k1 - 1, t !== 0 && e.prev_length < e.max_lazy_match && e.strstart - t <= e.w_size - $ && (e.match_length = pi(e, t), e.match_length <= 5 && (e.strategy === xa || e.match_length === k1 && e.strstart - e.match_start > 4096) && (e.match_length = k1 - 1)), e.prev_length >= k1 && e.match_length <= e.prev_length) {
            a = e.strstart + e.lookahead - k1, n = j(e, e.strstart - 1 - e.prev_match, e.prev_length - k1), e.lookahead -= e.prev_length - 1, e.prev_length -= 2;
            do ++e.strstart <= a && (e.ins_h = V(e, e.ins_h, e.window[e.strstart + k1 - 1]), t = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart);
            while (--e.prev_length !== 0)
            if (e.match_available = 0, e.match_length = k1 - 1, e.strstart++, n && (O1(e, !1), e.strm.avail_out === 0)) return D;
        } else if (e.match_available) {
            if (n = j(e, 0, e.window[e.strstart - 1]), n && O1(e, !1), e.strstart++, e.lookahead--, e.strm.avail_out === 0) return D;
        } else e.match_available = 1, e.strstart++, e.lookahead--;
    }
    return e.match_available && (n = j(e, 0, e.window[e.strstart - 1]), e.match_available = 0), e.insert = e.strstart < k1 - 1 ? e.strstart : k1 - 1, i === W ? (O1(e, !0), e.strm.avail_out === 0 ? te : he) : e.last_lit && (O1(e, !1), e.strm.avail_out === 0) ? D : Re;
}, Ca = (e, i)=>{
    let t, n, a, l, o = e.window;
    for(;;){
        if (e.lookahead <= Y) {
            if (ie(e), e.lookahead <= Y && i === le) return D;
            if (e.lookahead === 0) break;
        }
        if (e.match_length = 0, e.lookahead >= k1 && e.strstart > 0 && (a = e.strstart - 1, n = o[a], n === o[++a] && n === o[++a] && n === o[++a])) {
            l = e.strstart + Y;
            do ;
            while (n === o[++a] && n === o[++a] && n === o[++a] && n === o[++a] && n === o[++a] && n === o[++a] && n === o[++a] && n === o[++a] && a < l)
            e.match_length = Y - (l - a), e.match_length > e.lookahead && (e.match_length = e.lookahead);
        }
        if (e.match_length >= k1 ? (t = j(e, 1, e.match_length - k1), e.lookahead -= e.match_length, e.strstart += e.match_length, e.match_length = 0) : (t = j(e, 0, e.window[e.strstart]), e.lookahead--, e.strstart++), t && (O1(e, !1), e.strm.avail_out === 0)) return D;
    }
    return e.insert = 0, i === W ? (O1(e, !0), e.strm.avail_out === 0 ? te : he) : e.last_lit && (O1(e, !1), e.strm.avail_out === 0) ? D : Re;
}, Fa = (e, i)=>{
    let t;
    for(;;){
        if (e.lookahead === 0 && (ie(e), e.lookahead === 0)) {
            if (i === le) return D;
            break;
        }
        if (e.match_length = 0, t = j(e, 0, e.window[e.strstart]), e.lookahead--, e.strstart++, t && (O1(e, !1), e.strm.avail_out === 0)) return D;
    }
    return e.insert = 0, i === W ? (O1(e, !0), e.strm.avail_out === 0 ? te : he) : e.last_lit && (O1(e, !1), e.strm.avail_out === 0) ? D : Re;
};
function C1(e, i, t, n, a) {
    this.good_length = e, this.max_lazy = i, this.nice_length = t, this.max_chain = n, this.func = a;
}
var ce = [
    new C1(0, 0, 0, 0, $a),
    new C1(4, 4, 8, 4, Qe),
    new C1(4, 5, 16, 8, Qe),
    new C1(4, 6, 32, 32, Qe),
    new C1(4, 4, 16, 16, re),
    new C1(8, 16, 32, 32, re),
    new C1(8, 16, 128, 128, re),
    new C1(8, 32, 128, 256, re),
    new C1(32, 128, 258, 1024, re),
    new C1(32, 258, 258, 4096, re)
], Ma = (e)=>{
    e.window_size = 2 * e.w_size, X(e.head), e.max_lazy_match = ce[e.level].max_lazy, e.good_match = ce[e.level].good_length, e.nice_match = ce[e.level].nice_length, e.max_chain_length = ce[e.level].max_chain, e.strstart = 0, e.block_start = 0, e.lookahead = 0, e.insert = 0, e.match_length = e.prev_length = k1 - 1, e.match_available = 0, e.ins_h = 0;
};
function Ha() {
    this.strm = null, this.status = 0, this.pending_buf = null, this.pending_buf_size = 0, this.pending_out = 0, this.pending = 0, this.wrap = 0, this.gzhead = null, this.gzindex = 0, this.method = Pe, this.last_flush = -1, this.w_size = 0, this.w_bits = 0, this.w_mask = 0, this.window = null, this.window_size = 0, this.prev = null, this.head = null, this.ins_h = 0, this.hash_size = 0, this.hash_bits = 0, this.hash_mask = 0, this.hash_shift = 0, this.block_start = 0, this.match_length = 0, this.prev_match = 0, this.match_available = 0, this.strstart = 0, this.match_start = 0, this.lookahead = 0, this.prev_length = 0, this.max_chain_length = 0, this.max_lazy_match = 0, this.level = 0, this.strategy = 0, this.good_match = 0, this.nice_match = 0, this.dyn_ltree = new Uint16Array(Za * 2), this.dyn_dtree = new Uint16Array((2 * ma + 1) * 2), this.bl_tree = new Uint16Array((2 * Da + 1) * 2), X(this.dyn_ltree), X(this.dyn_dtree), X(this.bl_tree), this.l_desc = null, this.d_desc = null, this.bl_desc = null, this.bl_count = new Uint16Array(Ia + 1), this.heap = new Uint16Array(2 * _t + 1), X(this.heap), this.heap_len = 0, this.heap_max = 0, this.depth = new Uint16Array(2 * _t + 1), X(this.depth), this.l_buf = 0, this.lit_bufsize = 0, this.last_lit = 0, this.d_buf = 0, this.opt_len = 0, this.static_len = 0, this.matches = 0, this.insert = 0, this.bi_buf = 0, this.bi_valid = 0;
}
var xi = (e)=>{
    if (!e || !e.state) return G(e, L1);
    e.total_in = e.total_out = 0, e.data_type = ya;
    let i = e.state;
    return i.pending = 0, i.pending_out = 0, i.wrap < 0 && (i.wrap = -i.wrap), i.status = i.wrap ? Xe : q, e.adler = i.wrap === 2 ? 0 : 1, i.last_flush = le, da(i), M;
}, ki = (e)=>{
    let i = xi(e);
    return i === M && Ma(e.state), i;
}, Ba = (e, i)=>!e || !e.state || e.state.wrap !== 2 ? L1 : (e.state.gzhead = i, M), vi = (e, i, t, n, a, l)=>{
    if (!e) return L1;
    let o = 1;
    if (i === pa && (i = 6), n < 0 ? (o = 0, n = -n) : n > 15 && (o = 2, n -= 16), a < 1 || a > Sa || t !== Pe || n < 8 || n > 15 || i < 0 || i > 9 || l < 0 || l > va) return G(e, L1);
    n === 8 && (n = 9);
    let f = new Ha;
    return e.state = f, f.strm = e, f.wrap = o, f.gzhead = null, f.w_bits = n, f.w_size = 1 << f.w_bits, f.w_mask = f.w_size - 1, f.hash_bits = a + 7, f.hash_size = 1 << f.hash_bits, f.hash_mask = f.hash_size - 1, f.hash_shift = ~~((f.hash_bits + k1 - 1) / k1), f.window = new Uint8Array(f.w_size * 2), f.head = new Uint16Array(f.hash_size), f.prev = new Uint16Array(f.w_size), f.lit_bufsize = 1 << a + 6, f.pending_buf_size = f.lit_bufsize * 4, f.pending_buf = new Uint8Array(f.pending_buf_size), f.d_buf = 1 * f.lit_bufsize, f.l_buf = (1 + 2) * f.lit_bufsize, f.level = i, f.strategy = l, f.method = t, ki(e);
}, Ka = (e, i)=>vi(e, i, Pe, Aa, Ra, Ea), Pa = (e, i)=>{
    let t, n;
    if (!e || !e.state || i > St || i < 0) return e ? G(e, L1) : L1;
    let a = e.state;
    if (!e.output || !e.input && e.avail_in !== 0 || a.status === se && i !== W) return G(e, e.avail_out === 0 ? Je : L1);
    a.strm = e;
    let l = a.last_flush;
    if (a.last_flush = i, a.status === Xe) if (a.wrap === 2) e.adler = 0, y(a, 31), y(a, 139), y(a, 8), a.gzhead ? (y(a, (a.gzhead.text ? 1 : 0) + (a.gzhead.hcrc ? 2 : 0) + (a.gzhead.extra ? 4 : 0) + (a.gzhead.name ? 8 : 0) + (a.gzhead.comment ? 16 : 0)), y(a, a.gzhead.time & 255), y(a, a.gzhead.time >> 8 & 255), y(a, a.gzhead.time >> 16 & 255), y(a, a.gzhead.time >> 24 & 255), y(a, a.level === 9 ? 2 : a.strategy >= Ie || a.level < 2 ? 4 : 0), y(a, a.gzhead.os & 255), a.gzhead.extra && a.gzhead.extra.length && (y(a, a.gzhead.extra.length & 255), y(a, a.gzhead.extra.length >> 8 & 255)), a.gzhead.hcrc && (e.adler = I(e.adler, a.pending_buf, a.pending, 0)), a.gzindex = 0, a.status = ht) : (y(a, 0), y(a, 0), y(a, 0), y(a, 0), y(a, 0), y(a, a.level === 9 ? 2 : a.strategy >= Ie || a.level < 2 ? 4 : 0), y(a, Na), a.status = q);
    else {
        let o = Pe + (a.w_bits - 8 << 4) << 8, f = -1;
        a.strategy >= Ie || a.level < 2 ? f = 0 : a.level < 6 ? f = 1 : a.level === 6 ? f = 2 : f = 3, o |= f << 6, a.strstart !== 0 && (o |= Oa), o += 31 - o % 31, a.status = q, de(a, o), a.strstart !== 0 && (de(a, e.adler >>> 16), de(a, e.adler & 65535)), e.adler = 1;
    }
    if (a.status === ht) if (a.gzhead.extra) {
        for(t = a.pending; a.gzindex < (a.gzhead.extra.length & 65535) && !(a.pending === a.pending_buf_size && (a.gzhead.hcrc && a.pending > t && (e.adler = I(e.adler, a.pending_buf, a.pending - t, t)), P1(e), t = a.pending, a.pending === a.pending_buf_size));)y(a, a.gzhead.extra[a.gzindex] & 255), a.gzindex++;
        a.gzhead.hcrc && a.pending > t && (e.adler = I(e.adler, a.pending_buf, a.pending - t, t)), a.gzindex === a.gzhead.extra.length && (a.gzindex = 0, a.status = Ce);
    } else a.status = Ce;
    if (a.status === Ce) if (a.gzhead.name) {
        t = a.pending;
        do {
            if (a.pending === a.pending_buf_size && (a.gzhead.hcrc && a.pending > t && (e.adler = I(e.adler, a.pending_buf, a.pending - t, t)), P1(e), t = a.pending, a.pending === a.pending_buf_size)) {
                n = 1;
                break;
            }
            a.gzindex < a.gzhead.name.length ? n = a.gzhead.name.charCodeAt(a.gzindex++) & 255 : n = 0, y(a, n);
        }while (n !== 0)
        a.gzhead.hcrc && a.pending > t && (e.adler = I(e.adler, a.pending_buf, a.pending - t, t)), n === 0 && (a.gzindex = 0, a.status = Fe);
    } else a.status = Fe;
    if (a.status === Fe) if (a.gzhead.comment) {
        t = a.pending;
        do {
            if (a.pending === a.pending_buf_size && (a.gzhead.hcrc && a.pending > t && (e.adler = I(e.adler, a.pending_buf, a.pending - t, t)), P1(e), t = a.pending, a.pending === a.pending_buf_size)) {
                n = 1;
                break;
            }
            a.gzindex < a.gzhead.comment.length ? n = a.gzhead.comment.charCodeAt(a.gzindex++) & 255 : n = 0, y(a, n);
        }while (n !== 0)
        a.gzhead.hcrc && a.pending > t && (e.adler = I(e.adler, a.pending_buf, a.pending - t, t)), n === 0 && (a.status = Me);
    } else a.status = Me;
    if (a.status === Me && (a.gzhead.hcrc ? (a.pending + 2 > a.pending_buf_size && P1(e), a.pending + 2 <= a.pending_buf_size && (y(a, e.adler & 255), y(a, e.adler >> 8 & 255), e.adler = 0, a.status = q)) : a.status = q), a.pending !== 0) {
        if (P1(e), e.avail_out === 0) return a.last_flush = -1, M;
    } else if (e.avail_in === 0 && Rt(i) <= Rt(l) && i !== W) return G(e, Je);
    if (a.status === se && e.avail_in !== 0) return G(e, Je);
    if (e.avail_in !== 0 || a.lookahead !== 0 || i !== le && a.status !== se) {
        let o = a.strategy === Ie ? Fa(a, i) : a.strategy === ka ? Ca(a, i) : ce[a.level].func(a, i);
        if ((o === te || o === he) && (a.status = se), o === D || o === te) return e.avail_out === 0 && (a.last_flush = -1), M;
        if (o === Re && (i === ba ? ua(a) : i !== St && (sa(a, 0, 0, !1), i === wa && (X(a.head), a.lookahead === 0 && (a.strstart = 0, a.block_start = 0, a.insert = 0))), P1(e), e.avail_out === 0)) return a.last_flush = -1, M;
    }
    return i !== W ? M : a.wrap <= 0 ? At : (a.wrap === 2 ? (y(a, e.adler & 255), y(a, e.adler >> 8 & 255), y(a, e.adler >> 16 & 255), y(a, e.adler >> 24 & 255), y(a, e.total_in & 255), y(a, e.total_in >> 8 & 255), y(a, e.total_in >> 16 & 255), y(a, e.total_in >> 24 & 255)) : (de(a, e.adler >>> 16), de(a, e.adler & 65535)), P1(e), a.wrap > 0 && (a.wrap = -a.wrap), a.pending !== 0 ? M : At);
}, Xa = (e)=>{
    if (!e || !e.state) return L1;
    let i = e.state.status;
    return i !== Xe && i !== ht && i !== Ce && i !== Fe && i !== Me && i !== q && i !== se ? G(e, L1) : (e.state = null, i === q ? G(e, ga) : M);
}, Ya = (e, i)=>{
    let t = i.length;
    if (!e || !e.state) return L1;
    let n = e.state, a = n.wrap;
    if (a === 2 || a === 1 && n.status !== Xe || n.lookahead) return L1;
    if (a === 1 && (e.adler = ve(e.adler, i, t, 0)), n.wrap = 0, t >= n.w_size) {
        a === 0 && (X(n.head), n.strstart = 0, n.block_start = 0, n.insert = 0);
        let c = new Uint8Array(n.w_size);
        c.set(i.subarray(t - n.w_size, t), 0), i = c, t = n.w_size;
    }
    let l = e.avail_in, o = e.next_in, f = e.input;
    for(e.avail_in = t, e.next_in = 0, e.input = i, ie(n); n.lookahead >= k1;){
        let c = n.strstart, r = n.lookahead - (k1 - 1);
        do n.ins_h = V(n, n.ins_h, n.window[c + k1 - 1]), n.prev[c & n.w_mask] = n.head[n.ins_h], n.head[n.ins_h] = c, c++;
        while (--r)
        n.strstart = c, n.lookahead = k1 - 1, ie(n);
    }
    return n.strstart += n.lookahead, n.block_start = n.strstart, n.insert = n.lookahead, n.lookahead = 0, n.match_length = n.prev_length = k1 - 1, n.match_available = 0, e.next_in = o, e.input = f, e.avail_in = l, n.wrap = a, M;
}, Ga = Ka, ja = vi, Wa = ki, Va = xi, Ja = Ba, Qa = Pa, qa = Xa, en = Ya, tn = "pako deflate (from Nodeca project)", be = {
    deflateInit: Ga,
    deflateInit2: ja,
    deflateReset: Wa,
    deflateResetKeep: Va,
    deflateSetHeader: Ja,
    deflate: Qa,
    deflateEnd: qa,
    deflateSetDictionary: en,
    deflateInfo: tn
}, an = (e, i)=>Object.prototype.hasOwnProperty.call(e, i), nn = function(e) {
    let i = Array.prototype.slice.call(arguments, 1);
    for(; i.length;){
        let t = i.shift();
        if (t) {
            if (typeof t != "object") throw new TypeError(t + "must be non-object");
            for(let n in t)an(t, n) && (e[n] = t[n]);
        }
    }
    return e;
}, ln = (e)=>{
    let i = 0;
    for(let n = 0, a = e.length; n < a; n++)i += e[n].length;
    let t = new Uint8Array(i);
    for(let n = 0, a = 0, l = e.length; n < l; n++){
        let o = e[n];
        t.set(o, a), a += o.length;
    }
    return t;
}, Ye = {
    assign: nn,
    flattenChunks: ln
}, Ei = !0;
try {
    String.fromCharCode.apply(null, new Uint8Array(1));
} catch  {
    Ei = !1;
}
var Ee = new Uint8Array(256);
for(let e = 0; e < 256; e++)Ee[e] = e >= 252 ? 6 : e >= 248 ? 5 : e >= 240 ? 4 : e >= 224 ? 3 : e >= 192 ? 2 : 1;
Ee[254] = Ee[254] = 1;
var rn = (e)=>{
    if (typeof TextEncoder == "function" && TextEncoder.prototype.encode) return new TextEncoder().encode(e);
    let i, t, n, a, l, o = e.length, f = 0;
    for(a = 0; a < o; a++)t = e.charCodeAt(a), (t & 64512) === 55296 && a + 1 < o && (n = e.charCodeAt(a + 1), (n & 64512) === 56320 && (t = 65536 + (t - 55296 << 10) + (n - 56320), a++)), f += t < 128 ? 1 : t < 2048 ? 2 : t < 65536 ? 3 : 4;
    for(i = new Uint8Array(f), l = 0, a = 0; l < f; a++)t = e.charCodeAt(a), (t & 64512) === 55296 && a + 1 < o && (n = e.charCodeAt(a + 1), (n & 64512) === 56320 && (t = 65536 + (t - 55296 << 10) + (n - 56320), a++)), t < 128 ? i[l++] = t : t < 2048 ? (i[l++] = 192 | t >>> 6, i[l++] = 128 | t & 63) : t < 65536 ? (i[l++] = 224 | t >>> 12, i[l++] = 128 | t >>> 6 & 63, i[l++] = 128 | t & 63) : (i[l++] = 240 | t >>> 18, i[l++] = 128 | t >>> 12 & 63, i[l++] = 128 | t >>> 6 & 63, i[l++] = 128 | t & 63);
    return i;
}, fn = (e, i)=>{
    if (i < 65534 && e.subarray && Ei) return String.fromCharCode.apply(null, e.length === i ? e : e.subarray(0, i));
    let t = "";
    for(let n = 0; n < i; n++)t += String.fromCharCode(e[n]);
    return t;
}, on = (e, i)=>{
    let t = i || e.length;
    if (typeof TextDecoder == "function" && TextDecoder.prototype.decode) return new TextDecoder().decode(e.subarray(0, i));
    let n, a, l = new Array(t * 2);
    for(a = 0, n = 0; n < t;){
        let o = e[n++];
        if (o < 128) {
            l[a++] = o;
            continue;
        }
        let f = Ee[o];
        if (f > 4) {
            l[a++] = 65533, n += f - 1;
            continue;
        }
        for(o &= f === 2 ? 31 : f === 3 ? 15 : 7; f > 1 && n < t;)o = o << 6 | e[n++] & 63, f--;
        if (f > 1) {
            l[a++] = 65533;
            continue;
        }
        o < 65536 ? l[a++] = o : (o -= 65536, l[a++] = 55296 | o >> 10 & 1023, l[a++] = 56320 | o & 1023);
    }
    return fn(l, a);
}, _n = (e, i)=>{
    i = i || e.length, i > e.length && (i = e.length);
    let t = i - 1;
    for(; t >= 0 && (e[t] & 192) === 128;)t--;
    return t < 0 || t === 0 ? i : t + Ee[e[t]] > i ? t : i;
}, ye = {
    string2buf: rn,
    buf2string: on,
    utf8border: _n
};
function hn() {
    this.input = null, this.next_in = 0, this.avail_in = 0, this.total_in = 0, this.output = null, this.next_out = 0, this.avail_out = 0, this.total_out = 0, this.msg = "", this.state = null, this.data_type = 2, this.adler = 0;
}
var yi = hn, Si = Object.prototype.toString, { Z_NO_FLUSH: dn , Z_SYNC_FLUSH: sn , Z_FULL_FLUSH: cn , Z_FINISH: un , Z_OK: Be , Z_STREAM_END: bn , Z_DEFAULT_COMPRESSION: wn , Z_DEFAULT_STRATEGY: gn , Z_DEFLATED: pn  } = ne;
function ze(e) {
    this.options = Ye.assign({
        level: wn,
        method: pn,
        chunkSize: 16384,
        windowBits: 15,
        memLevel: 8,
        strategy: gn
    }, e || {});
    let i = this.options;
    i.raw && i.windowBits > 0 ? i.windowBits = -i.windowBits : i.gzip && i.windowBits > 0 && i.windowBits < 16 && (i.windowBits += 16), this.err = 0, this.msg = "", this.ended = !1, this.chunks = [], this.strm = new yi, this.strm.avail_out = 0;
    let t = be.deflateInit2(this.strm, i.level, i.method, i.windowBits, i.memLevel, i.strategy);
    if (t !== Be) throw new Error(ee[t]);
    if (i.header && be.deflateSetHeader(this.strm, i.header), i.dictionary) {
        let n;
        if (typeof i.dictionary == "string" ? n = ye.string2buf(i.dictionary) : Si.call(i.dictionary) === "[object ArrayBuffer]" ? n = new Uint8Array(i.dictionary) : n = i.dictionary, t = be.deflateSetDictionary(this.strm, n), t !== Be) throw new Error(ee[t]);
        this._dict_set = !0;
    }
}
ze.prototype.push = function(e, i) {
    let t = this.strm, n = this.options.chunkSize, a, l;
    if (this.ended) return !1;
    for(i === ~~i ? l = i : l = i === !0 ? un : dn, typeof e == "string" ? t.input = ye.string2buf(e) : Si.call(e) === "[object ArrayBuffer]" ? t.input = new Uint8Array(e) : t.input = e, t.next_in = 0, t.avail_in = t.input.length;;){
        if (t.avail_out === 0 && (t.output = new Uint8Array(n), t.next_out = 0, t.avail_out = n), (l === sn || l === cn) && t.avail_out <= 6) {
            this.onData(t.output.subarray(0, t.next_out)), t.avail_out = 0;
            continue;
        }
        if (a = be.deflate(t, l), a === bn) return t.next_out > 0 && this.onData(t.output.subarray(0, t.next_out)), a = be.deflateEnd(this.strm), this.onEnd(a), this.ended = !0, a === Be;
        if (t.avail_out === 0) {
            this.onData(t.output);
            continue;
        }
        if (l > 0 && t.next_out > 0) {
            this.onData(t.output.subarray(0, t.next_out)), t.avail_out = 0;
            continue;
        }
        if (t.avail_in === 0) break;
    }
    return !0;
};
ze.prototype.onData = function(e) {
    this.chunks.push(e);
};
ze.prototype.onEnd = function(e) {
    e === Be && (this.result = Ye.flattenChunks(this.chunks)), this.chunks = [], this.err = e, this.msg = this.strm.msg;
};
function bt(e, i) {
    let t = new ze(i);
    if (t.push(e, !0), t.err) throw t.msg || ee[t.err];
    return t.result;
}
function xn(e, i) {
    return i = i || {}, i.raw = !0, bt(e, i);
}
function kn(e, i) {
    return i = i || {}, i.gzip = !0, bt(e, i);
}
var vn = ze, En = bt, yn = xn, Sn = kn, An = ne, Rn = {
    Deflate: vn,
    deflate: En,
    deflateRaw: yn,
    gzip: Sn,
    constants: An
}, Oe = 30, zn = 12, Tn = function(i, t) {
    let n, a, l, o, f, c, r, _, E, s, h, u, m, v, w, A, x, d, S, Z, b, z, R, g, p = i.state;
    n = i.next_in, R = i.input, a = n + (i.avail_in - 5), l = i.next_out, g = i.output, o = l - (t - i.avail_out), f = l + (i.avail_out - 257), c = p.dmax, r = p.wsize, _ = p.whave, E = p.wnext, s = p.window, h = p.hold, u = p.bits, m = p.lencode, v = p.distcode, w = (1 << p.lenbits) - 1, A = (1 << p.distbits) - 1;
    e: do {
        u < 15 && (h += R[n++] << u, u += 8, h += R[n++] << u, u += 8), x = m[h & w];
        t: for(;;){
            if (d = x >>> 24, h >>>= d, u -= d, d = x >>> 16 & 255, d === 0) g[l++] = x & 65535;
            else if (d & 16) {
                S = x & 65535, d &= 15, d && (u < d && (h += R[n++] << u, u += 8), S += h & (1 << d) - 1, h >>>= d, u -= d), u < 15 && (h += R[n++] << u, u += 8, h += R[n++] << u, u += 8), x = v[h & A];
                i: for(;;){
                    if (d = x >>> 24, h >>>= d, u -= d, d = x >>> 16 & 255, d & 16) {
                        if (Z = x & 65535, d &= 15, u < d && (h += R[n++] << u, u += 8, u < d && (h += R[n++] << u, u += 8)), Z += h & (1 << d) - 1, Z > c) {
                            i.msg = "invalid distance too far back", p.mode = Oe;
                            break e;
                        }
                        if (h >>>= d, u -= d, d = l - o, Z > d) {
                            if (d = Z - d, d > _ && p.sane) {
                                i.msg = "invalid distance too far back", p.mode = Oe;
                                break e;
                            }
                            if (b = 0, z = s, E === 0) {
                                if (b += r - d, d < S) {
                                    S -= d;
                                    do g[l++] = s[b++];
                                    while (--d)
                                    b = l - Z, z = g;
                                }
                            } else if (E < d) {
                                if (b += r + E - d, d -= E, d < S) {
                                    S -= d;
                                    do g[l++] = s[b++];
                                    while (--d)
                                    if (b = 0, E < S) {
                                        d = E, S -= d;
                                        do g[l++] = s[b++];
                                        while (--d)
                                        b = l - Z, z = g;
                                    }
                                }
                            } else if (b += E - d, d < S) {
                                S -= d;
                                do g[l++] = s[b++];
                                while (--d)
                                b = l - Z, z = g;
                            }
                            for(; S > 2;)g[l++] = z[b++], g[l++] = z[b++], g[l++] = z[b++], S -= 3;
                            S && (g[l++] = z[b++], S > 1 && (g[l++] = z[b++]));
                        } else {
                            b = l - Z;
                            do g[l++] = g[b++], g[l++] = g[b++], g[l++] = g[b++], S -= 3;
                            while (S > 2)
                            S && (g[l++] = g[b++], S > 1 && (g[l++] = g[b++]));
                        }
                    } else if (d & 64) {
                        i.msg = "invalid distance code", p.mode = Oe;
                        break e;
                    } else {
                        x = v[(x & 65535) + (h & (1 << d) - 1)];
                        continue i;
                    }
                    break;
                }
            } else if (d & 64) if (d & 32) {
                p.mode = zn;
                break e;
            } else {
                i.msg = "invalid literal/length code", p.mode = Oe;
                break e;
            }
            else {
                x = m[(x & 65535) + (h & (1 << d) - 1)];
                continue t;
            }
            break;
        }
    }while (n < a && l < f)
    S = u >> 3, n -= S, u -= S << 3, h &= (1 << u) - 1, i.next_in = n, i.next_out = l, i.avail_in = n < a ? 5 + (a - n) : 5 - (n - a), i.avail_out = l < f ? 257 + (f - l) : 257 - (l - f), p.hold = h, p.bits = u;
}, fe = 15, zt = 852, Tt = 592, mt = 0, qe = 1, Dt = 2, mn = new Uint16Array([
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    13,
    15,
    17,
    19,
    23,
    27,
    31,
    35,
    43,
    51,
    59,
    67,
    83,
    99,
    115,
    131,
    163,
    195,
    227,
    258,
    0,
    0
]), Dn = new Uint8Array([
    16,
    16,
    16,
    16,
    16,
    16,
    16,
    16,
    17,
    17,
    17,
    17,
    18,
    18,
    18,
    18,
    19,
    19,
    19,
    19,
    20,
    20,
    20,
    20,
    21,
    21,
    21,
    21,
    16,
    72,
    78
]), Zn = new Uint16Array([
    1,
    2,
    3,
    4,
    5,
    7,
    9,
    13,
    17,
    25,
    33,
    49,
    65,
    97,
    129,
    193,
    257,
    385,
    513,
    769,
    1025,
    1537,
    2049,
    3073,
    4097,
    6145,
    8193,
    12289,
    16385,
    24577,
    0,
    0
]), In = new Uint8Array([
    16,
    16,
    16,
    16,
    17,
    17,
    18,
    18,
    19,
    19,
    20,
    20,
    21,
    21,
    22,
    22,
    23,
    23,
    24,
    24,
    25,
    25,
    26,
    26,
    27,
    27,
    28,
    28,
    29,
    29,
    64,
    64
]), On = (e, i, t, n, a, l, o, f)=>{
    let c = f.bits, r = 0, _ = 0, E = 0, s = 0, h = 0, u = 0, m = 0, v = 0, w = 0, A = 0, x, d, S, Z, b, z = null, R = 0, g, p = new Uint16Array(fe + 1), J = new Uint16Array(fe + 1), me = null, gt = 0, pt, De, Ze;
    for(r = 0; r <= fe; r++)p[r] = 0;
    for(_ = 0; _ < n; _++)p[i[t + _]]++;
    for(h = c, s = fe; s >= 1 && p[s] === 0; s--);
    if (h > s && (h = s), s === 0) return a[l++] = 1 << 24 | 64 << 16 | 0, a[l++] = 1 << 24 | 64 << 16 | 0, f.bits = 1, 0;
    for(E = 1; E < s && p[E] === 0; E++);
    for(h < E && (h = E), v = 1, r = 1; r <= fe; r++)if (v <<= 1, v -= p[r], v < 0) return -1;
    if (v > 0 && (e === mt || s !== 1)) return -1;
    for(J[1] = 0, r = 1; r < fe; r++)J[r + 1] = J[r] + p[r];
    for(_ = 0; _ < n; _++)i[t + _] !== 0 && (o[J[i[t + _]]++] = _);
    if (e === mt ? (z = me = o, g = 19) : e === qe ? (z = mn, R -= 257, me = Dn, gt -= 257, g = 256) : (z = Zn, me = In, g = -1), A = 0, _ = 0, r = E, b = l, u = h, m = 0, S = -1, w = 1 << h, Z = w - 1, e === qe && w > zt || e === Dt && w > Tt) return 1;
    for(;;){
        pt = r - m, o[_] < g ? (De = 0, Ze = o[_]) : o[_] > g ? (De = me[gt + o[_]], Ze = z[R + o[_]]) : (De = 32 + 64, Ze = 0), x = 1 << r - m, d = 1 << u, E = d;
        do d -= x, a[b + (A >> m) + d] = pt << 24 | De << 16 | Ze | 0;
        while (d !== 0)
        for(x = 1 << r - 1; A & x;)x >>= 1;
        if (x !== 0 ? (A &= x - 1, A += x) : A = 0, _++, --p[r] === 0) {
            if (r === s) break;
            r = i[t + o[_]];
        }
        if (r > h && (A & Z) !== S) {
            for(m === 0 && (m = h), b += E, u = r - m, v = 1 << u; u + m < s && (v -= p[u + m], !(v <= 0));)u++, v <<= 1;
            if (w += 1 << u, e === qe && w > zt || e === Dt && w > Tt) return 1;
            S = A & Z, a[S] = h << 24 | u << 16 | b - l | 0;
        }
    }
    return A !== 0 && (a[b + A] = r - m << 24 | 64 << 16 | 0), f.bits = h, 0;
}, we = On, Nn = 0, Ai = 1, Ri = 2, { Z_FINISH: Zt , Z_BLOCK: Ln , Z_TREES: Ne , Z_OK: ae , Z_STREAM_END: Un , Z_NEED_DICT: $n , Z_STREAM_ERROR: U , Z_DATA_ERROR: zi , Z_MEM_ERROR: Ti , Z_BUF_ERROR: Cn , Z_DEFLATED: It  } = ne, mi = 1, Ot = 2, Nt = 3, Lt = 4, Ut = 5, $t = 6, Ct = 7, Ft = 8, Mt = 9, Ht = 10, Ke = 11, H = 12, et = 13, Bt = 14, tt = 15, Kt = 16, Pt = 17, Xt = 18, Yt = 19, Le = 20, Ue = 21, Gt = 22, jt = 23, Wt = 24, Vt = 25, Jt = 26, it = 27, Qt = 28, qt = 29, T1 = 30, Di = 31, Fn = 32, Mn = 852, Hn = 592, Bn = 15, Kn = Bn, ei = (e)=>(e >>> 24 & 255) + (e >>> 8 & 65280) + ((e & 65280) << 8) + ((e & 255) << 24);
function Pn() {
    this.mode = 0, this.last = !1, this.wrap = 0, this.havedict = !1, this.flags = 0, this.dmax = 0, this.check = 0, this.total = 0, this.head = null, this.wbits = 0, this.wsize = 0, this.whave = 0, this.wnext = 0, this.window = null, this.hold = 0, this.bits = 0, this.length = 0, this.offset = 0, this.extra = 0, this.lencode = null, this.distcode = null, this.lenbits = 0, this.distbits = 0, this.ncode = 0, this.nlen = 0, this.ndist = 0, this.have = 0, this.next = null, this.lens = new Uint16Array(320), this.work = new Uint16Array(288), this.lendyn = null, this.distdyn = null, this.sane = 0, this.back = 0, this.was = 0;
}
var Zi = (e)=>{
    if (!e || !e.state) return U;
    let i = e.state;
    return e.total_in = e.total_out = i.total = 0, e.msg = "", i.wrap && (e.adler = i.wrap & 1), i.mode = mi, i.last = 0, i.havedict = 0, i.dmax = 32768, i.head = null, i.hold = 0, i.bits = 0, i.lencode = i.lendyn = new Int32Array(Mn), i.distcode = i.distdyn = new Int32Array(Hn), i.sane = 1, i.back = -1, ae;
}, Ii = (e)=>{
    if (!e || !e.state) return U;
    let i = e.state;
    return i.wsize = 0, i.whave = 0, i.wnext = 0, Zi(e);
}, Oi = (e, i)=>{
    let t;
    if (!e || !e.state) return U;
    let n = e.state;
    return i < 0 ? (t = 0, i = -i) : (t = (i >> 4) + 1, i < 48 && (i &= 15)), i && (i < 8 || i > 15) ? U : (n.window !== null && n.wbits !== i && (n.window = null), n.wrap = t, n.wbits = i, Ii(e));
}, Ni = (e, i)=>{
    if (!e) return U;
    let t = new Pn;
    e.state = t, t.window = null;
    let n = Oi(e, i);
    return n !== ae && (e.state = null), n;
}, Xn = (e)=>Ni(e, Kn), ti = !0, at, nt, Yn = (e)=>{
    if (ti) {
        at = new Int32Array(512), nt = new Int32Array(32);
        let i = 0;
        for(; i < 144;)e.lens[i++] = 8;
        for(; i < 256;)e.lens[i++] = 9;
        for(; i < 280;)e.lens[i++] = 7;
        for(; i < 288;)e.lens[i++] = 8;
        for(we(Ai, e.lens, 0, 288, at, 0, e.work, {
            bits: 9
        }), i = 0; i < 32;)e.lens[i++] = 5;
        we(Ri, e.lens, 0, 32, nt, 0, e.work, {
            bits: 5
        }), ti = !1;
    }
    e.lencode = at, e.lenbits = 9, e.distcode = nt, e.distbits = 5;
}, Li = (e, i, t, n)=>{
    let a, l = e.state;
    return l.window === null && (l.wsize = 1 << l.wbits, l.wnext = 0, l.whave = 0, l.window = new Uint8Array(l.wsize)), n >= l.wsize ? (l.window.set(i.subarray(t - l.wsize, t), 0), l.wnext = 0, l.whave = l.wsize) : (a = l.wsize - l.wnext, a > n && (a = n), l.window.set(i.subarray(t - n, t - n + a), l.wnext), n -= a, n ? (l.window.set(i.subarray(t - n, t), 0), l.wnext = n, l.whave = l.wsize) : (l.wnext += a, l.wnext === l.wsize && (l.wnext = 0), l.whave < l.wsize && (l.whave += a))), 0;
}, Gn = (e, i)=>{
    let t, n, a, l, o, f, c, r, _, E, s, h, u, m, v = 0, w, A, x, d, S, Z, b, z, R = new Uint8Array(4), g, p, J = new Uint8Array([
        16,
        17,
        18,
        0,
        8,
        7,
        9,
        6,
        10,
        5,
        11,
        4,
        12,
        3,
        13,
        2,
        14,
        1,
        15
    ]);
    if (!e || !e.state || !e.output || !e.input && e.avail_in !== 0) return U;
    t = e.state, t.mode === H && (t.mode = et), o = e.next_out, a = e.output, c = e.avail_out, l = e.next_in, n = e.input, f = e.avail_in, r = t.hold, _ = t.bits, E = f, s = c, z = ae;
    e: for(;;)switch(t.mode){
        case mi:
            if (t.wrap === 0) {
                t.mode = et;
                break;
            }
            for(; _ < 16;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            if (t.wrap & 2 && r === 35615) {
                t.check = 0, R[0] = r & 255, R[1] = r >>> 8 & 255, t.check = I(t.check, R, 2, 0), r = 0, _ = 0, t.mode = Ot;
                break;
            }
            if (t.flags = 0, t.head && (t.head.done = !1), !(t.wrap & 1) || (((r & 255) << 8) + (r >> 8)) % 31) {
                e.msg = "incorrect header check", t.mode = T1;
                break;
            }
            if ((r & 15) !== It) {
                e.msg = "unknown compression method", t.mode = T1;
                break;
            }
            if (r >>>= 4, _ -= 4, b = (r & 15) + 8, t.wbits === 0) t.wbits = b;
            else if (b > t.wbits) {
                e.msg = "invalid window size", t.mode = T1;
                break;
            }
            t.dmax = 1 << t.wbits, e.adler = t.check = 1, t.mode = r & 512 ? Ht : H, r = 0, _ = 0;
            break;
        case Ot:
            for(; _ < 16;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            if (t.flags = r, (t.flags & 255) !== It) {
                e.msg = "unknown compression method", t.mode = T1;
                break;
            }
            if (t.flags & 57344) {
                e.msg = "unknown header flags set", t.mode = T1;
                break;
            }
            t.head && (t.head.text = r >> 8 & 1), t.flags & 512 && (R[0] = r & 255, R[1] = r >>> 8 & 255, t.check = I(t.check, R, 2, 0)), r = 0, _ = 0, t.mode = Nt;
        case Nt:
            for(; _ < 32;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            t.head && (t.head.time = r), t.flags & 512 && (R[0] = r & 255, R[1] = r >>> 8 & 255, R[2] = r >>> 16 & 255, R[3] = r >>> 24 & 255, t.check = I(t.check, R, 4, 0)), r = 0, _ = 0, t.mode = Lt;
        case Lt:
            for(; _ < 16;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            t.head && (t.head.xflags = r & 255, t.head.os = r >> 8), t.flags & 512 && (R[0] = r & 255, R[1] = r >>> 8 & 255, t.check = I(t.check, R, 2, 0)), r = 0, _ = 0, t.mode = Ut;
        case Ut:
            if (t.flags & 1024) {
                for(; _ < 16;){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                t.length = r, t.head && (t.head.extra_len = r), t.flags & 512 && (R[0] = r & 255, R[1] = r >>> 8 & 255, t.check = I(t.check, R, 2, 0)), r = 0, _ = 0;
            } else t.head && (t.head.extra = null);
            t.mode = $t;
        case $t:
            if (t.flags & 1024 && (h = t.length, h > f && (h = f), h && (t.head && (b = t.head.extra_len - t.length, t.head.extra || (t.head.extra = new Uint8Array(t.head.extra_len)), t.head.extra.set(n.subarray(l, l + h), b)), t.flags & 512 && (t.check = I(t.check, n, h, l)), f -= h, l += h, t.length -= h), t.length)) break e;
            t.length = 0, t.mode = Ct;
        case Ct:
            if (t.flags & 2048) {
                if (f === 0) break e;
                h = 0;
                do b = n[l + h++], t.head && b && t.length < 65536 && (t.head.name += String.fromCharCode(b));
                while (b && h < f)
                if (t.flags & 512 && (t.check = I(t.check, n, h, l)), f -= h, l += h, b) break e;
            } else t.head && (t.head.name = null);
            t.length = 0, t.mode = Ft;
        case Ft:
            if (t.flags & 4096) {
                if (f === 0) break e;
                h = 0;
                do b = n[l + h++], t.head && b && t.length < 65536 && (t.head.comment += String.fromCharCode(b));
                while (b && h < f)
                if (t.flags & 512 && (t.check = I(t.check, n, h, l)), f -= h, l += h, b) break e;
            } else t.head && (t.head.comment = null);
            t.mode = Mt;
        case Mt:
            if (t.flags & 512) {
                for(; _ < 16;){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                if (r !== (t.check & 65535)) {
                    e.msg = "header crc mismatch", t.mode = T1;
                    break;
                }
                r = 0, _ = 0;
            }
            t.head && (t.head.hcrc = t.flags >> 9 & 1, t.head.done = !0), e.adler = t.check = 0, t.mode = H;
            break;
        case Ht:
            for(; _ < 32;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            e.adler = t.check = ei(r), r = 0, _ = 0, t.mode = Ke;
        case Ke:
            if (t.havedict === 0) return e.next_out = o, e.avail_out = c, e.next_in = l, e.avail_in = f, t.hold = r, t.bits = _, $n;
            e.adler = t.check = 1, t.mode = H;
        case H:
            if (i === Ln || i === Ne) break e;
        case et:
            if (t.last) {
                r >>>= _ & 7, _ -= _ & 7, t.mode = it;
                break;
            }
            for(; _ < 3;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            switch(t.last = r & 1, r >>>= 1, _ -= 1, r & 3){
                case 0:
                    t.mode = Bt;
                    break;
                case 1:
                    if (Yn(t), t.mode = Le, i === Ne) {
                        r >>>= 2, _ -= 2;
                        break e;
                    }
                    break;
                case 2:
                    t.mode = Pt;
                    break;
                case 3:
                    e.msg = "invalid block type", t.mode = T1;
            }
            r >>>= 2, _ -= 2;
            break;
        case Bt:
            for(r >>>= _ & 7, _ -= _ & 7; _ < 32;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            if ((r & 65535) !== (r >>> 16 ^ 65535)) {
                e.msg = "invalid stored block lengths", t.mode = T1;
                break;
            }
            if (t.length = r & 65535, r = 0, _ = 0, t.mode = tt, i === Ne) break e;
        case tt:
            t.mode = Kt;
        case Kt:
            if (h = t.length, h) {
                if (h > f && (h = f), h > c && (h = c), h === 0) break e;
                a.set(n.subarray(l, l + h), o), f -= h, l += h, c -= h, o += h, t.length -= h;
                break;
            }
            t.mode = H;
            break;
        case Pt:
            for(; _ < 14;){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            if (t.nlen = (r & 31) + 257, r >>>= 5, _ -= 5, t.ndist = (r & 31) + 1, r >>>= 5, _ -= 5, t.ncode = (r & 15) + 4, r >>>= 4, _ -= 4, t.nlen > 286 || t.ndist > 30) {
                e.msg = "too many length or distance symbols", t.mode = T1;
                break;
            }
            t.have = 0, t.mode = Xt;
        case Xt:
            for(; t.have < t.ncode;){
                for(; _ < 3;){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                t.lens[J[t.have++]] = r & 7, r >>>= 3, _ -= 3;
            }
            for(; t.have < 19;)t.lens[J[t.have++]] = 0;
            if (t.lencode = t.lendyn, t.lenbits = 7, g = {
                bits: t.lenbits
            }, z = we(Nn, t.lens, 0, 19, t.lencode, 0, t.work, g), t.lenbits = g.bits, z) {
                e.msg = "invalid code lengths set", t.mode = T1;
                break;
            }
            t.have = 0, t.mode = Yt;
        case Yt:
            for(; t.have < t.nlen + t.ndist;){
                for(; v = t.lencode[r & (1 << t.lenbits) - 1], w = v >>> 24, A = v >>> 16 & 255, x = v & 65535, !(w <= _);){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                if (x < 16) r >>>= w, _ -= w, t.lens[t.have++] = x;
                else {
                    if (x === 16) {
                        for(p = w + 2; _ < p;){
                            if (f === 0) break e;
                            f--, r += n[l++] << _, _ += 8;
                        }
                        if (r >>>= w, _ -= w, t.have === 0) {
                            e.msg = "invalid bit length repeat", t.mode = T1;
                            break;
                        }
                        b = t.lens[t.have - 1], h = 3 + (r & 3), r >>>= 2, _ -= 2;
                    } else if (x === 17) {
                        for(p = w + 3; _ < p;){
                            if (f === 0) break e;
                            f--, r += n[l++] << _, _ += 8;
                        }
                        r >>>= w, _ -= w, b = 0, h = 3 + (r & 7), r >>>= 3, _ -= 3;
                    } else {
                        for(p = w + 7; _ < p;){
                            if (f === 0) break e;
                            f--, r += n[l++] << _, _ += 8;
                        }
                        r >>>= w, _ -= w, b = 0, h = 11 + (r & 127), r >>>= 7, _ -= 7;
                    }
                    if (t.have + h > t.nlen + t.ndist) {
                        e.msg = "invalid bit length repeat", t.mode = T1;
                        break;
                    }
                    for(; h--;)t.lens[t.have++] = b;
                }
            }
            if (t.mode === T1) break;
            if (t.lens[256] === 0) {
                e.msg = "invalid code -- missing end-of-block", t.mode = T1;
                break;
            }
            if (t.lenbits = 9, g = {
                bits: t.lenbits
            }, z = we(Ai, t.lens, 0, t.nlen, t.lencode, 0, t.work, g), t.lenbits = g.bits, z) {
                e.msg = "invalid literal/lengths set", t.mode = T1;
                break;
            }
            if (t.distbits = 6, t.distcode = t.distdyn, g = {
                bits: t.distbits
            }, z = we(Ri, t.lens, t.nlen, t.ndist, t.distcode, 0, t.work, g), t.distbits = g.bits, z) {
                e.msg = "invalid distances set", t.mode = T1;
                break;
            }
            if (t.mode = Le, i === Ne) break e;
        case Le:
            t.mode = Ue;
        case Ue:
            if (f >= 6 && c >= 258) {
                e.next_out = o, e.avail_out = c, e.next_in = l, e.avail_in = f, t.hold = r, t.bits = _, Tn(e, s), o = e.next_out, a = e.output, c = e.avail_out, l = e.next_in, n = e.input, f = e.avail_in, r = t.hold, _ = t.bits, t.mode === H && (t.back = -1);
                break;
            }
            for(t.back = 0; v = t.lencode[r & (1 << t.lenbits) - 1], w = v >>> 24, A = v >>> 16 & 255, x = v & 65535, !(w <= _);){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            if (A && !(A & 240)) {
                for(d = w, S = A, Z = x; v = t.lencode[Z + ((r & (1 << d + S) - 1) >> d)], w = v >>> 24, A = v >>> 16 & 255, x = v & 65535, !(d + w <= _);){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                r >>>= d, _ -= d, t.back += d;
            }
            if (r >>>= w, _ -= w, t.back += w, t.length = x, A === 0) {
                t.mode = Jt;
                break;
            }
            if (A & 32) {
                t.back = -1, t.mode = H;
                break;
            }
            if (A & 64) {
                e.msg = "invalid literal/length code", t.mode = T1;
                break;
            }
            t.extra = A & 15, t.mode = Gt;
        case Gt:
            if (t.extra) {
                for(p = t.extra; _ < p;){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                t.length += r & (1 << t.extra) - 1, r >>>= t.extra, _ -= t.extra, t.back += t.extra;
            }
            t.was = t.length, t.mode = jt;
        case jt:
            for(; v = t.distcode[r & (1 << t.distbits) - 1], w = v >>> 24, A = v >>> 16 & 255, x = v & 65535, !(w <= _);){
                if (f === 0) break e;
                f--, r += n[l++] << _, _ += 8;
            }
            if (!(A & 240)) {
                for(d = w, S = A, Z = x; v = t.distcode[Z + ((r & (1 << d + S) - 1) >> d)], w = v >>> 24, A = v >>> 16 & 255, x = v & 65535, !(d + w <= _);){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                r >>>= d, _ -= d, t.back += d;
            }
            if (r >>>= w, _ -= w, t.back += w, A & 64) {
                e.msg = "invalid distance code", t.mode = T1;
                break;
            }
            t.offset = x, t.extra = A & 15, t.mode = Wt;
        case Wt:
            if (t.extra) {
                for(p = t.extra; _ < p;){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                t.offset += r & (1 << t.extra) - 1, r >>>= t.extra, _ -= t.extra, t.back += t.extra;
            }
            if (t.offset > t.dmax) {
                e.msg = "invalid distance too far back", t.mode = T1;
                break;
            }
            t.mode = Vt;
        case Vt:
            if (c === 0) break e;
            if (h = s - c, t.offset > h) {
                if (h = t.offset - h, h > t.whave && t.sane) {
                    e.msg = "invalid distance too far back", t.mode = T1;
                    break;
                }
                h > t.wnext ? (h -= t.wnext, u = t.wsize - h) : u = t.wnext - h, h > t.length && (h = t.length), m = t.window;
            } else m = a, u = o - t.offset, h = t.length;
            h > c && (h = c), c -= h, t.length -= h;
            do a[o++] = m[u++];
            while (--h)
            t.length === 0 && (t.mode = Ue);
            break;
        case Jt:
            if (c === 0) break e;
            a[o++] = t.length, c--, t.mode = Ue;
            break;
        case it:
            if (t.wrap) {
                for(; _ < 32;){
                    if (f === 0) break e;
                    f--, r |= n[l++] << _, _ += 8;
                }
                if (s -= c, e.total_out += s, t.total += s, s && (e.adler = t.check = t.flags ? I(t.check, a, s, o - s) : ve(t.check, a, s, o - s)), s = c, (t.flags ? r : ei(r)) !== t.check) {
                    e.msg = "incorrect data check", t.mode = T1;
                    break;
                }
                r = 0, _ = 0;
            }
            t.mode = Qt;
        case Qt:
            if (t.wrap && t.flags) {
                for(; _ < 32;){
                    if (f === 0) break e;
                    f--, r += n[l++] << _, _ += 8;
                }
                if (r !== (t.total & 4294967295)) {
                    e.msg = "incorrect length check", t.mode = T1;
                    break;
                }
                r = 0, _ = 0;
            }
            t.mode = qt;
        case qt:
            z = Un;
            break e;
        case T1:
            z = zi;
            break e;
        case Di:
            return Ti;
        case Fn:
        default:
            return U;
    }
    return e.next_out = o, e.avail_out = c, e.next_in = l, e.avail_in = f, t.hold = r, t.bits = _, (t.wsize || s !== e.avail_out && t.mode < T1 && (t.mode < it || i !== Zt)) && Li(e, e.output, e.next_out, s - e.avail_out), E -= e.avail_in, s -= e.avail_out, e.total_in += E, e.total_out += s, t.total += s, t.wrap && s && (e.adler = t.check = t.flags ? I(t.check, a, s, e.next_out - s) : ve(t.check, a, s, e.next_out - s)), e.data_type = t.bits + (t.last ? 64 : 0) + (t.mode === H ? 128 : 0) + (t.mode === Le || t.mode === tt ? 256 : 0), (E === 0 && s === 0 || i === Zt) && z === ae && (z = Cn), z;
}, jn = (e)=>{
    if (!e || !e.state) return U;
    let i = e.state;
    return i.window && (i.window = null), e.state = null, ae;
}, Wn = (e, i)=>{
    if (!e || !e.state) return U;
    let t = e.state;
    return t.wrap & 2 ? (t.head = i, i.done = !1, ae) : U;
}, Vn = (e, i)=>{
    let t = i.length, n, a, l;
    return !e || !e.state || (n = e.state, n.wrap !== 0 && n.mode !== Ke) ? U : n.mode === Ke && (a = 1, a = ve(a, i, t, 0), a !== n.check) ? zi : (l = Li(e, i, t, t), l ? (n.mode = Di, Ti) : (n.havedict = 1, ae));
}, Jn = Ii, Qn = Oi, qn = Zi, el = Xn, tl = Ni, il = Gn, al = jn, nl = Wn, ll = Vn, rl = "pako inflate (from Nodeca project)", K = {
    inflateReset: Jn,
    inflateReset2: Qn,
    inflateResetKeep: qn,
    inflateInit: el,
    inflateInit2: tl,
    inflate: il,
    inflateEnd: al,
    inflateGetHeader: nl,
    inflateSetDictionary: ll,
    inflateInfo: rl
};
function fl() {
    this.text = 0, this.time = 0, this.xflags = 0, this.os = 0, this.extra = null, this.extra_len = 0, this.name = "", this.comment = "", this.hcrc = 0, this.done = !1;
}
var ol = fl, Ui = Object.prototype.toString, { Z_NO_FLUSH: _l , Z_FINISH: hl , Z_OK: Se , Z_STREAM_END: lt , Z_NEED_DICT: rt , Z_STREAM_ERROR: dl , Z_DATA_ERROR: ii , Z_MEM_ERROR: sl  } = ne;
function Te(e) {
    this.options = Ye.assign({
        chunkSize: 1024 * 64,
        windowBits: 15,
        to: ""
    }, e || {});
    let i = this.options;
    i.raw && i.windowBits >= 0 && i.windowBits < 16 && (i.windowBits = -i.windowBits, i.windowBits === 0 && (i.windowBits = -15)), i.windowBits >= 0 && i.windowBits < 16 && !(e && e.windowBits) && (i.windowBits += 32), i.windowBits > 15 && i.windowBits < 48 && (i.windowBits & 15 || (i.windowBits |= 15)), this.err = 0, this.msg = "", this.ended = !1, this.chunks = [], this.strm = new yi, this.strm.avail_out = 0;
    let t = K.inflateInit2(this.strm, i.windowBits);
    if (t !== Se) throw new Error(ee[t]);
    if (this.header = new ol, K.inflateGetHeader(this.strm, this.header), i.dictionary && (typeof i.dictionary == "string" ? i.dictionary = ye.string2buf(i.dictionary) : Ui.call(i.dictionary) === "[object ArrayBuffer]" && (i.dictionary = new Uint8Array(i.dictionary)), i.raw && (t = K.inflateSetDictionary(this.strm, i.dictionary), t !== Se))) throw new Error(ee[t]);
}
Te.prototype.push = function(e, i) {
    let t = this.strm, n = this.options.chunkSize, a = this.options.dictionary, l, o, f;
    if (this.ended) return !1;
    for(i === ~~i ? o = i : o = i === !0 ? hl : _l, Ui.call(e) === "[object ArrayBuffer]" ? t.input = new Uint8Array(e) : t.input = e, t.next_in = 0, t.avail_in = t.input.length;;){
        for(t.avail_out === 0 && (t.output = new Uint8Array(n), t.next_out = 0, t.avail_out = n), l = K.inflate(t, o), l === rt && a && (l = K.inflateSetDictionary(t, a), l === Se ? l = K.inflate(t, o) : l === ii && (l = rt)); t.avail_in > 0 && l === lt && t.state.wrap > 0 && e[t.next_in] !== 0;)K.inflateReset(t), l = K.inflate(t, o);
        switch(l){
            case dl:
            case ii:
            case rt:
            case sl:
                return this.onEnd(l), this.ended = !0, !1;
        }
        if (f = t.avail_out, t.next_out && (t.avail_out === 0 || l === lt)) if (this.options.to === "string") {
            let c = ye.utf8border(t.output, t.next_out), r = t.next_out - c, _ = ye.buf2string(t.output, c);
            t.next_out = r, t.avail_out = n - r, r && t.output.set(t.output.subarray(c, c + r), 0), this.onData(_);
        } else this.onData(t.output.length === t.next_out ? t.output : t.output.subarray(0, t.next_out));
        if (!(l === Se && f === 0)) {
            if (l === lt) return l = K.inflateEnd(this.strm), this.onEnd(l), this.ended = !0, !0;
            if (t.avail_in === 0) break;
        }
    }
    return !0;
};
Te.prototype.onData = function(e) {
    this.chunks.push(e);
};
Te.prototype.onEnd = function(e) {
    e === Se && (this.options.to === "string" ? this.result = this.chunks.join("") : this.result = Ye.flattenChunks(this.chunks)), this.chunks = [], this.err = e, this.msg = this.strm.msg;
};
function wt(e, i) {
    let t = new Te(i);
    if (t.push(e), t.err) throw t.msg || ee[t.err];
    return t.result;
}
function cl(e, i) {
    return i = i || {}, i.raw = !0, wt(e, i);
}
var ul = Te, bl = wt, wl = cl, gl = wt, pl = ne, xl = {
    Inflate: ul,
    inflate: bl,
    inflateRaw: wl,
    ungzip: gl,
    constants: pl
}, { Deflate: kl , deflate: vl , deflateRaw: El , gzip: yl  } = Rn, { Inflate: Sl , inflate: Al , inflateRaw: Rl , ungzip: zl  } = xl, ml = vl, Ol = Al;
const UpdateObservable = "0";
class Retain {
    constructor(value){
        this.value = value;
    }
}
const OnjsCallback = "1";
const EvalJavascript = "2";
const JavascriptError = "3";
const JavascriptWarning = "4";
const RegisterObservable = "5";
const JSDoneLoading = "8";
const FusedMessage = "9";
const CloseSession = "10";
const PingPong = "11";
const UpdateSession = "12";
function clean_stack(stack) {
    return stack.replaceAll(/(data:\w+\/\w+;base64,)[a-zA-Z0-9\+\/=]+:/g, "$1<<BASE64>>:");
}
const CONNECTION = {
    send_message: undefined,
    queue: [],
    status: "closed",
    compression_enabled: false
};
function on_connection_open(send_message_callback, compression_enabled, enable_pings = true) {
    CONNECTION.send_message = send_message_callback;
    CONNECTION.status = "open";
    CONNECTION.compression_enabled = compression_enabled;
    CONNECTION.queue.forEach((message)=>send_to_julia(message));
    if (enable_pings) {
        send_pings();
    }
}
function on_connection_close() {
    CONNECTION.status = "closed";
}
function can_send_to_julia() {
    return CONNECTION.status === "open";
}
const EXTENSION_CODEC = new ExtensionCodec();
window.EXTENSION_CODEC = EXTENSION_CODEC;
function unpack(uint8array) {
    return decode(uint8array, {
        extensionCodec: EXTENSION_CODEC
    });
}
function pack(object) {
    return encode(object, {
        extensionCodec: EXTENSION_CODEC
    });
}
function reinterpret_array(ArrayType, uint8array) {
    if (ArrayType === Uint8Array) {
        return uint8array;
    } else {
        const bo = uint8array.byteOffset;
        const bpe = ArrayType.BYTES_PER_ELEMENT;
        const new_array_length = uint8array.byteLength / bpe;
        const buffer = uint8array.buffer.slice(bo, bo + uint8array.byteLength);
        return new ArrayType(buffer, 0, new_array_length);
    }
}
function register_ext_array(type_tag, array_type) {
    EXTENSION_CODEC.register({
        type: type_tag,
        decode: (uint8array)=>reinterpret_array(array_type, uint8array),
        encode: (object)=>{
            if (object instanceof array_type) {
                return new Uint8Array(object.buffer, object.byteOffset, object.byteLength);
            } else {
                return null;
            }
        }
    });
}
register_ext_array(0x11, Int8Array);
register_ext_array(0x12, Uint8Array);
register_ext_array(0x13, Int16Array);
register_ext_array(0x14, Uint16Array);
register_ext_array(0x15, Int32Array);
register_ext_array(0x16, Uint32Array);
register_ext_array(0x17, Float32Array);
register_ext_array(0x18, Float64Array);
function register_ext(type_tag, decode, encode) {
    EXTENSION_CODEC.register({
        type: type_tag,
        decode,
        encode
    });
}
class JLArray {
    constructor(size, array){
        this.size = size;
        this.array = array;
    }
}
register_ext(99, (uint_8_array)=>{
    const [size, array] = unpack(uint_8_array);
    return new JLArray(size, array);
}, (object)=>{
    if (object instanceof JLArray) {
        return pack([
            object.size,
            object.array
        ]);
    } else {
        return null;
    }
});
function send_error(message, exception) {
    console.error(message);
    console.error(exception);
    send_to_julia({
        msg_type: JavascriptError,
        message: message,
        exception: String(exception),
        stacktrace: exception === null ? "" : clean_stack(exception.stack)
    });
}
const SESSIONS = {};
const GLOBAL_OBJECT_CACHE = {};
const OBJECT_FREEING_LOCK = new l({
    concurrency: 1
});
function lock_loading(f) {
    OBJECT_FREEING_LOCK.add(f);
}
function lookup_global_object(key) {
    const object = GLOBAL_OBJECT_CACHE[key];
    if (object) {
        if (object instanceof Retain) {
            return object.value;
        } else {
            return object;
        }
    }
    throw new Error(`Key ${key} not found! ${object}`);
}
function is_still_referenced(id) {
    for(const session_id in SESSIONS){
        const [tracked_objects, allow_delete] = SESSIONS[session_id];
        if (allow_delete && tracked_objects.has(id)) {
            return true;
        }
    }
    return false;
}
function free_object(id) {
    const data = GLOBAL_OBJECT_CACHE[id];
    if (data) {
        if (data instanceof Promise) {
            return;
        }
        if (data instanceof Retain) {
            return;
        }
        if (!is_still_referenced(id)) {
            delete GLOBAL_OBJECT_CACHE[id];
        }
        return;
    } else {
        console.warn(`Trying to delete object ${id}, which is not in global session cache.`);
    }
    return;
}
let DELETE_OBSERVER = undefined;
function track_deleted_sessions() {
    if (!DELETE_OBSERVER) {
        const observer = new MutationObserver(function(mutations) {
            let removal_occured = false;
            const to_delete = new Set();
            mutations.forEach((mutation)=>{
                mutation.removedNodes.forEach((x)=>{
                    if (x.id in SESSIONS) {
                        const status = SESSIONS[x.id][1];
                        if (status === "delete") {
                            to_delete.add(x.id);
                        }
                    } else {
                        removal_occured = true;
                    }
                });
            });
            if (removal_occured) {
                Object.keys(SESSIONS).forEach((id)=>{
                    const status = SESSIONS[id][1];
                    if (status === "delete") {
                        if (!document.getElementById(id)) {
                            console.debug(`adding session to delete candidates: ${id}`);
                            to_delete.add(id);
                        }
                    }
                });
            }
            to_delete.forEach((id)=>{
                close_session(id);
            });
        });
        observer.observe(document, {
            attributes: false,
            childList: true,
            characterData: false,
            subtree: true
        });
        DELETE_OBSERVER = observer;
    }
}
function send_pingpong() {
    send_to_julia({
        msg_type: PingPong
    });
}
function send_pings() {
    if (!can_send_to_julia()) {
        return;
    }
    send_pingpong();
    setTimeout(send_pings, 5000);
}
function encode_binary(data, compression_enabled) {
    if (compression_enabled) {
        return ml(pack(data));
    } else {
        return pack(data);
    }
}
function send_to_julia(message) {
    const { send_message , status , compression_enabled  } = CONNECTION;
    if (send_message !== undefined && status === "open") {
        send_message(encode_binary(message, compression_enabled));
    } else if (status === "closed") {
        CONNECTION.queue.push(message);
    } else {
        console.log("Trying to send messages while connection is offline");
    }
}
class Observable {
    #callbacks = [];
    constructor(id, value){
        this.id = id;
        this.value = value;
    }
    notify(value, dont_notify_julia) {
        this.value = value;
        this.#callbacks.forEach((callback)=>{
            try {
                const deregister = callback(value);
                if (deregister == false) {
                    this.#callbacks.splice(this.#callbacks.indexOf(callback), 1);
                }
            } catch (exception) {
                send_error("Error during running onjs callback\n" + "Callback:\n" + callback.toString(), exception);
            }
        });
        if (!dont_notify_julia) {
            send_to_julia({
                msg_type: UpdateObservable,
                id: this.id,
                payload: value
            });
        }
    }
    on(callback) {
        this.#callbacks.push(callback);
    }
}
register_ext(101, (uint_8_array)=>{
    const [id, value] = unpack(uint_8_array);
    return new Observable(id, value);
});
register_ext(102, (uint_8_array)=>{
    const [interpolated_objects, source, julia_file] = unpack(uint_8_array);
    const lookup_interpolated = (id)=>interpolated_objects[id];
    try {
        const eval_func = new Function("__lookup_interpolated", "Bonito", source);
        return ()=>{
            try {
                return eval_func(lookup_interpolated, window.Bonito);
            } catch (err) {
                console.log(`error in closure from: ${julia_file}`);
                console.log(`Source:`);
                console.log(source);
                throw err;
            }
        };
    } catch (err) {
        console.log(`error in closure from: ${julia_file}`);
        console.log(`Source:`);
        console.log(source);
        throw err;
    }
});
register_ext(103, (uint_8_array)=>{
    const real_value = unpack(uint_8_array);
    return new Retain(real_value);
});
register_ext(104, (uint_8_array)=>{
    const key = unpack(uint_8_array);
    return lookup_global_object(key);
});
function create_tag(tag, attributes) {
    if (attributes.juliasvgnode) {
        return document.createElementNS("http://www.w3.org/2000/svg", tag);
    } else {
        return document.createElement(tag);
    }
}
register_ext(105, (uint_8_array)=>{
    const [tag, children, attributes] = unpack(uint_8_array);
    const node = create_tag(tag, attributes);
    Object.keys(attributes).forEach((key)=>{
        if (key == "juliasvgnode") {
            return;
        }
        if (key == "class") {
            node.className = attributes[key];
        } else {
            node.setAttribute(key, attributes[key]);
        }
    });
    children.forEach((child)=>node.append(child));
    return node;
});
register_ext(108, (uint_8_array)=>{
    const html = unpack(uint_8_array);
    const div = document.createElement("div");
    div.innerHTML = html;
    return div;
});
function send_warning(message) {
    console.warn(message);
    send_to_julia({
        msg_type: JavascriptWarning,
        message: message
    });
}
function send_done_loading(session, exception) {
    send_to_julia({
        msg_type: JSDoneLoading,
        session,
        message: "",
        exception: exception === null ? "nothing" : String(exception),
        stacktrace: exception === null ? "" : clean_stack(exception.stack)
    });
}
function send_close_session(session, subsession) {
    send_to_julia({
        msg_type: CloseSession,
        session,
        subsession
    });
}
function process_message(data) {
    try {
        switch(data.msg_type){
            case UpdateObservable:
                lookup_global_object(data.id).notify(data.payload, true);
                break;
            case OnjsCallback:
                data.obs.on(data.payload());
                break;
            case EvalJavascript:
                data.payload();
                break;
            case FusedMessage:
                data.payload.forEach(process_message);
                break;
            case PingPong:
                console.debug("ping");
                break;
            case UpdateSession:
                update_session_dom(data);
                break;
            default:
                throw new Error("Unrecognized message type: " + data.msg_type + ".");
        }
    } catch (e) {
        send_error(`Error while processing message ${JSON.stringify(data)}`, e);
    }
}
const mod = {
    UpdateObservable: UpdateObservable,
    OnjsCallback: OnjsCallback,
    EvalJavascript: EvalJavascript,
    JavascriptError: JavascriptError,
    JavascriptWarning: JavascriptWarning,
    RegisterObservable: RegisterObservable,
    JSDoneLoading: JSDoneLoading,
    FusedMessage: FusedMessage,
    on_connection_open: on_connection_open,
    on_connection_close: on_connection_close,
    can_send_to_julia: can_send_to_julia,
    send_to_julia: send_to_julia,
    send_pingpong: send_pingpong,
    send_error: send_error,
    send_warning: send_warning,
    send_done_loading: send_done_loading,
    send_close_session: send_close_session,
    process_message: process_message
};
function done_initializing_session(session_id) {
    if (!(session_id in SESSIONS)) {
        throw new Error("Session ");
    }
    send_done_loading(session_id, null);
    if (SESSIONS[session_id][1] != "root") {
        SESSIONS[session_id][1] = "delete";
    }
}
function decode_binary(binary, compression_enabled) {
    const serialized_message = unpack_binary(binary, compression_enabled);
    const [session_id, message_data] = serialized_message;
    return message_data;
}
function init_session(session_id, binary_messages, session_status, compression_enabled) {
    track_deleted_sessions();
    lock_loading(()=>{
        try {
            SESSIONS[session_id] = [
                new Set(),
                session_status
            ];
            if (binary_messages) {
                process_message(decode_binary(binary_messages, compression_enabled));
            }
            OBJECT_FREEING_LOCK.onIdle().then(()=>{
                done_initializing_session(session_id);
            });
        } catch (error) {
            send_done_loading(session_id, error);
            console.error(error.stack);
            throw error;
        }
    });
}
function close_session(session_id) {
    const session = SESSIONS[session_id];
    if (!session) {
        console.warn("double freeing session from JS!");
        return;
    }
    const [session_objects, status] = session;
    const root_node = document.getElementById(session_id);
    if (root_node) {
        root_node.style.display = "none";
        root_node.parentNode.removeChild(root_node);
    }
    if (status === "delete") {
        send_close_session(session_id, status);
        SESSIONS[session_id] = [
            session_objects,
            false
        ];
    }
    return;
}
function free_session(session_id) {
    lock_loading(()=>{
        const session = SESSIONS[session_id];
        if (!session) {
            console.warn("double freeing session from Julia!");
            return;
        }
        const [tracked_objects, status] = session;
        delete SESSIONS[session_id];
        tracked_objects.forEach(free_object);
        tracked_objects.clear();
    });
}
function on_node_available(node_id, timeout) {
    return new Promise((resolve)=>{
        function test_node(timeout) {
            const node = document.querySelector(`[data-jscall-id='${node_id}']`);
            if (node) {
                resolve(node);
            } else {
                const new_timeout = 2 * timeout;
                console.log(new_timeout);
                setTimeout(test_node, new_timeout, new_timeout);
            }
        }
        test_node(timeout);
    });
}
function update_or_replace(node, new_html, replace) {
    if (replace) {
        node.parentNode.replaceChild(new_html, node);
    } else {
        while(node.childElementCount > 0){
            node.removeChild(node.firstChild);
        }
        node.append(new_html);
    }
}
function update_session_dom(message) {
    lock_loading(()=>{
        const { session_id , messages , html , dom_node_selector , replace  } = message;
        on_node_available(dom_node_selector, 1).then((dom)=>{
            try {
                update_or_replace(dom, html, replace);
                process_message(messages);
                done_initializing_session(session_id);
            } catch (error) {
                send_done_loading(session_id, error);
                console.error(error.stack);
                throw error;
            }
        });
    });
}
function update_session_cache(session_id, new_jl_objects, session_status) {
    function update_cache(tracked_objects) {
        for(const key in new_jl_objects){
            tracked_objects.add(key);
            const new_object = new_jl_objects[key];
            if (new_object == "tracking-only") {
                if (!(key in GLOBAL_OBJECT_CACHE)) {
                    throw new Error(`Key ${key} only send for tracking, but not already tracked!!!`);
                }
            } else {
                if (key in GLOBAL_OBJECT_CACHE) {
                    console.warn(`${key} in session cache and send again!! ${new_object}`);
                }
                GLOBAL_OBJECT_CACHE[key] = new_object;
            }
        }
    }
    const session = SESSIONS[session_id];
    if (session) {
        update_cache(session[0]);
    } else {
        const tracked_items = new Set();
        SESSIONS[session_id] = [
            tracked_items,
            session_status
        ];
        update_cache(tracked_items);
    }
}
const mod1 = {
    SESSIONS: SESSIONS,
    GLOBAL_OBJECT_CACHE: GLOBAL_OBJECT_CACHE,
    OBJECT_FREEING_LOCK: OBJECT_FREEING_LOCK,
    lock_loading: lock_loading,
    lookup_global_object: lookup_global_object,
    free_object: free_object,
    track_deleted_sessions: track_deleted_sessions,
    done_initializing_session: done_initializing_session,
    init_session: init_session,
    close_session: close_session,
    free_session: free_session,
    on_node_available: on_node_available,
    update_or_replace: update_or_replace,
    update_session_dom: update_session_dom,
    update_session_cache: update_session_cache
};
register_ext(106, (uint_8_array)=>{
    const [session_id, objects, session_status] = unpack(uint_8_array);
    update_session_cache(session_id, objects, session_status);
    return session_id;
});
register_ext(107, (uint_8_array)=>{
    const [session_id, message] = unpack(uint_8_array);
    return message;
});
function base64encode(data_as_uint8array) {
    const base64_promise = new Promise((resolve)=>{
        const reader = new FileReader();
        reader.onload = ()=>{
            const len = 37;
            const base64url = reader.result;
            resolve(base64url.slice(len, base64url.length));
        };
        reader.readAsDataURL(new Blob([
            data_as_uint8array
        ]));
    });
    return base64_promise;
}
function base64decode(base64_str) {
    return new Promise((resolve)=>{
        fetch("data:application/octet-stream;base64," + base64_str).then((response)=>{
            response.arrayBuffer().then((array)=>{
                resolve(new Uint8Array(array));
            });
        });
    });
}
function decode_base64_message(base64_string, compression_enabled) {
    return base64decode(base64_string).then((x)=>decode_binary(x, compression_enabled));
}
function unpack_binary(binary, compression_enabled) {
    if (compression_enabled) {
        return unpack(Ol(binary));
    } else {
        return unpack(binary);
    }
}
const mod2 = {
    Retain: Retain,
    base64encode: base64encode,
    base64decode: base64decode,
    decode_base64_message: decode_base64_message,
    decode_binary: decode_binary,
    unpack_binary: unpack_binary,
    encode_binary: encode_binary
};
function onany(observables, f) {
    const callback = (x)=>f(observables.map((x)=>x.value));
    observables.forEach((obs)=>{
        obs.on(callback);
    });
}
const { send_error: send_error1 , send_warning: send_warning1 , process_message: process_message1 , on_connection_open: on_connection_open1 , on_connection_close: on_connection_close1 , send_close_session: send_close_session1 , send_pingpong: send_pingpong1 , can_send_to_julia: can_send_to_julia1 , send_to_julia: send_to_julia1  } = mod;
const { base64decode: base64decode1 , base64encode: base64encode1 , decode_binary: decode_binary1 , encode_binary: encode_binary1 , decode_base64_message: decode_base64_message1  } = mod2;
const { init_session: init_session1 , free_session: free_session1 , lookup_global_object: lookup_global_object1 , update_or_replace: update_or_replace1 , lock_loading: lock_loading1 , OBJECT_FREEING_LOCK: OBJECT_FREEING_LOCK1 , free_object: free_object1  } = mod1;
function update_node_attribute(node, attribute, value) {
    if (node) {
        if (node[attribute] != value) {
            node[attribute] = value;
        }
        return true;
    } else {
        return false;
    }
}
function update_dom_node(dom, html) {
    if (dom) {
        dom.innerHTML = html;
        return true;
    } else {
        return false;
    }
}
function fetch_binary(url) {
    return fetch(url).then((response)=>{
        if (!response.ok) {
            throw new Error("HTTP error, status = " + response.status);
        }
        return response.arrayBuffer();
    });
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
            future_id = setTimeout(()=>inner_throttle(...args), delay - (now - prev) + 1);
        }
    }
    return inner_throttle;
}
const Bonito = {
    Protocol: mod2,
    base64decode: base64decode1,
    base64encode: base64encode1,
    decode_binary: decode_binary1,
    encode_binary: encode_binary1,
    decode_base64_message: decode_base64_message1,
    fetch_binary,
    Connection: mod,
    send_error: send_error1,
    send_warning: send_warning1,
    process_message: process_message1,
    on_connection_open: on_connection_open1,
    on_connection_close: on_connection_close1,
    send_close_session: send_close_session1,
    send_pingpong: send_pingpong1,
    Sessions: mod1,
    init_session: init_session1,
    free_session: free_session1,
    lock_loading: lock_loading1,
    update_node_attribute,
    update_dom_node,
    lookup_global_object: lookup_global_object1,
    update_or_replace: update_or_replace1,
    OBJECT_FREEING_LOCK: OBJECT_FREEING_LOCK1,
    can_send_to_julia: can_send_to_julia1,
    onany,
    free_object: free_object1,
    send_to_julia: send_to_julia1,
    throttle_function
};
window.Bonito = Bonito;
export { mod2 as Protocol, base64decode1 as base64decode, base64encode1 as base64encode, decode_binary1 as decode_binary, encode_binary1 as encode_binary, decode_base64_message1 as decode_base64_message, mod as Connection, send_error1 as send_error, send_warning1 as send_warning, process_message1 as process_message, on_connection_open1 as on_connection_open, on_connection_close1 as on_connection_close, send_close_session1 as send_close_session, send_pingpong1 as send_pingpong, mod1 as Sessions, init_session1 as init_session, free_session1 as free_session, lock_loading1 as lock_loading, update_node_attribute as update_node_attribute, update_dom_node as update_dom_node, lookup_global_object1 as lookup_global_object, update_or_replace1 as update_or_replace, onany as onany, OBJECT_FREEING_LOCK1 as OBJECT_FREEING_LOCK, can_send_to_julia1 as can_send_to_julia, free_object1 as free_object, send_to_julia1 as send_to_julia, throttle_function as throttle_function };

