# WIP: fail-safe glyph sync (jl_glyphs <-> js_glyphs)

Status: IMPLEMENTED + FULLY VERIFIED (2026-07-15), all uncommitted.
- Chat scenario (the killer case): owner-figure eval NEVER expanded, reuser
  expanded alone -> scene initializes, ALL text/ticks render, zero warns
  (key-not-found 0 / glyph-miss 0 / never-arrived 0). Screenshot-verified.
- Plain pages: 12-figure stress app live reloads + export_static green.
- The fix set spans FOUR layers; the same disease appeared in three organs
  (content-addressed registry + first-owner-ships + owner never delivers =
  dangling reference): glyph SDFs (WGLMakie tracker), session objects
  (Bonito TrackingOnly dedup), proxied assets (Bonito register! kept the
  first RemoteAsset -> dead bridge). Plus the transport: relay drop -> park.
- Also DELETED: WGLMakie's execute_in_order/get_order! page-global init
  sequencer (the old glyph-order workaround; it hung any fragment whose
  predecessor never mounted).
Remaining before merge: committed e2e tests (owner/reuser, collapsed-expand,
worker-restart asset reuse), WGLMakie test suite + runic format + CHANGELOG,
delete this file.

## BLOCKER / next fix: the bridge relay DROPS frames (pinned!)

`BonitoAgents` host relay (`handle_eval_ws` / `remote_app.jl`) logs
"eval relay: no browser connection — frame dropped" and DISCARDS worker→browser
frames whenever `eb.root_conn[] === nothing`. `root_conn` is only set by
`attach_bridge_host!`, which runs on the FIRST EvalResultPlaceholder mount — so
everything emitted between dial-back and first mount is lost (glyph batches at
eval time, session init bundles, ...), and `proxy_fetch` asset reads error out
while the bridge redials ("'asset_read' not sent") leaving fragments without
their JS module -> permanent spinner. Triple-reproduced. Fix direction:
1. attach the bridge to the tab's root at DIAL-BACK/chat-bind time, not first
   mount; rebind `root_conn` on every attach (kill the attach-once guard's
   stale-conn hole);
2. relay must QUEUE (bounded) while no root connection is attached, flush on
   attach — never silently drop;
3. make fragment session-init pull-based/idempotent (page requests the bundle
   on every mount, GetSessionDOM-style with retry) + retry asset fetches across
   a redial.
The GlyphSync pull fail-safe then covers any remaining glyph gap.

UPDATE (relay fix landed, next layer found): park/flush + rebind-on-attach +
call_ctrl redial grace are implemented in remote_app.jl and VERIFIED (frames
park + flush on attach; the mount handshake now completes: fragment session
ready=true both ways). The remaining spinner is ONE LEVEL DEEPER — Bonito's
cross-session object dedup (`cache_object!` in serialization/caching.jl):
a fragment whose object key is already in the worker ROOT's session_objects
ships only `TrackingOnly(key)`, assuming the page already has the full object.
For bridged fragments the page only has what MOUNTED fragments delivered, so
any object first cached by a never-mounted fragment is `undefined` on the page
("Key <prefix>/1291 not found in GLOBAL_OBJECT_CACHE") — the glyph bug
generalized to ALL session objects. Fix: disable cross-session dedup when
`root.connection isa ProxyConnection` (fragments self-contained; plain pages
keep dedup). Open follow-up: object-level pull ("send me key X") as the
principled self-heal, and verify root-session evaljs frames (glyph batches)
apply on pages that never initialized the worker-root session.

## Problem (measured, see chat-harness repro)

- Glyph SDFs ride the FIRST plot that serializes them (`atlas_updates` on plot
  data, dedup'd via a root-session tracker Set). Later plots ship hash-only.
- Serialization order != execution order for bridged/lazy-mounted fragments
  (BonitoAgents eval results), so a consumer can mount before/without its
  owner -> invisible glyphs (JS degrades: warn + zero-UV quads).
- Buffers are baked at construction; a late atlas insert never heals them.
- The tracker lives on the worker's SINGLETON parent session -> ownership leaks
  across chats/pages; ownership by never-mounted fragments is common.
- (Separate bug, not this refactor: the eval-fragment mount handshake can drop
  the init bundle -> permanent spinner. Fix = pull-based idempotent fragment
  init in Bonito/BonitoAgents.)

## Design

Content-addressed glyphs; plots declare needs; one root-owned channel; pull as
fail-safe; no compat shim (serializer + bundled JS always ship together).

Julia (WGLMakie):
- `GlyphSync` per ROOT session (get-or-create, replaces `:wglmakie_scene_atlas`
  metadata Set): `shipped::Set{UInt32}`, `bbox::Dict{UInt32,Tuple{Vec2f,Vec2f}}`
  (w/mini aren't hash-addressable from the atlas; cache at first ship),
  `channel::Observable{Dict{String,Any}}` (batch out),
  `request::Observable{Vector{UInt32}}` (pull in), `lock`.
- Serialization (text + scatter): tracker semantics unchanged (diff vs
  `shipped`), but NEW glyph data goes out as `channel[] = batch` on the root —
  NOT on the plot. Plot data carries ONLY `glyph_hashes` (+ scales). Scatter
  gains a hashes list too (its UVs are baked Julia-side; it only needs the
  texture region present, but must be able to await/pull).
- Pull responder: `on(root_session, request) do hashes` -> re-extract
  `[uv, sdf, w, mini]` per hash: `uv = atlas.uv_rectangles[atlas.mapping[hash]]`,
  `sdf = get_glyph_sdf(atlas, hash)`, `(w, mini)` from sync.bbox (Vec2f(0)s for
  text glyphs, real bbox for markers) -> `channel[] = batch`.
- Wiring: each figure's init script interpolates `$(channel)`/`$(request)` and
  calls `WGL.wire_glyph_channel(channel, request)` (idempotent JS-side by obs
  id). Root-scoped obs => bridged fragments share one stream; prefix routing
  already covers it.

JS (WGLMakie.js / TextureAtlas.js / Plots.js):
- `wire_glyph_channel(channel, request)`: module-Set guard by obs id;
  `channel.on(batch => atlas.insert_glyphs(batch))`.
- `atlas.ensure_glyphs(hashes, on_ready)`: present -> done. Missing ->
  register waiter {missing:Set, cb}, debounce-aggregate one `request.notify`
  (pull). `insert_glyphs` completes waiters -> cb.
- NO async surgery in deserialize: plots build immediately with today's
  `data ?? zero-UV` fallback, then HEAL: text keeps its glyph_hashes; on_ready
  re-runs per_glyph_data + rewrites instance attrs + needsUpdate. Scatter needs
  no buffer patch (texture upload heals) — just poke requires_update.
- Delete `atlas_updates` from plot data + `add_glyphs_from_plots` pre-walk.
- Timeout on waiters -> keep zero-UV + console.warn (degrade, never hang).

export_static: channel updates emitted during export render are queued
UpdateObservable events; Bonito's offline init_session fuses the queue into the
static bundle IN ORDER -> batches apply before plot scripts. Pull never fires;
if it would, degrade path. (Verified against init_session's !isopen branch.)

Reconnect/fresh page: NO batch replay (channel is transient) — ensure_glyphs
misses -> pull -> heal. That's the fail-safe path by construction.

## Repro/verification harness (already built, this session)

- Plain-page stress app: 12 figures incl. closed <details>; 35x reload + 6x CPU
  throttle + export_static all green (order can't invert on plain pages).
- Chat harness: test/evalenv (BonitoAgents) now has WGLMakie [sources] entry
  (uncommitted); TestKit-driven repro of the collapsed/uncollapse hang + the
  ownership leak. After the refactor: add e2e "owner never expanded, reuser
  expanded -> no glyph misses" + keep export_static green.

## Files

- Makie/src/utilities/texture_atlas.jl: get_glyph_data/tracker stays; add
  hash-only re-extraction helper for the pull responder.
- WGLMakie/src/plot-primitives.jl: GlyphSync + serialization changes
  (get_atlas_tracker/get_scatter_data/get_glyph_data/register_text_computation!).
- WGLMakie/src/three_plot.jl: interpolate channel/request into figure init.
- WGLMakie/src/javascript/TextureAtlas.js: ensure_glyphs + waiters + wire fn.
- WGLMakie/src/javascript/Plots.js: hashes kept on plot; heal path; scatter
  hashes; remove atlas_updates consumption.
- WGLMakie/src/javascript/Serialization.js: remove add_glyphs_from_plots.
