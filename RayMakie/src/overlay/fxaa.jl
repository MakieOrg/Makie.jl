# FXAA, as GLMakie applies it: every raster stage writes a second attachment with
# its plot's `fxaa` flag (GLMakie keeps it in the high bit of the object id), and
# after all plots are drawn one fullscreen pass runs NVIDIA's FXAA 3.11 over the
# frame. A pixel of a plot with `fxaa = false` gets luma 1 (postprocess.frag), so
# it and its neighbours of the same kind have no contrast and pass through.
#
# The frame is read from buffers, not a sampled texture: the render graph hands a
# later pass an earlier pass's image by `copy!`, so the bilinear filtering the
# GLSL gets from its sampler is done by hand in `fxaa_tex`.

# The two attachments a raster fragment writes: its colour, and the flag the FXAA
# pass reads. Alpha 1, so the blend a pipeline declares REPLACES the flag rather
# than mixing it, which is GLMakie's unblended object-id target.
@inline raster_output(color::Vec4f, fxaa::Int32) = (color, Vec4f(Float32(fxaa), 0f0, 0f0, 1f0))

# GLSL's `step`, for the stages that leave an edge to FXAA instead of smoothing it
# with `aastep` (lines.frag, distance_shape.frag).
@inline glsl_step(edge::Float32, x::Float32) = x < edge ? 0f0 : 1f0

@inline fxaa_or_aastep(fxaa::Int32, threshold::Float32, dist::Float32, aa::Float32 = ANTIALIAS_RADIUS) =
    fxaa != Int32(0) ? glsl_step(threshold, dist) : aastep(threshold, dist, aa)

# ── The traced image, blitted into both attachments ─────────────────────────

composite_blit_fragment(inputs, source, width::Int32, height::Int32) =
    raster_output(Mantle.blit_fragment(inputs, source, width, height), Int32(0))

function get_composite_blit_pipeline!(screen)
    get!(screen.gfx_pipelines, :composite_blit) do
        GraphicsPipeline(; vertex = VertexShader(Mantle.blit_vertex),
                           fragment = FragmentShader(composite_blit_fragment),
                           blend = Opaque(), cull = NoCull(), depth = DepthOff())
    end
end

# ── The frame FXAA reads ────────────────────────────────────────────────────

@inline unorm(x::N0f8) = Float32(reinterpret(x)) * (1f0 / 255f0)

# One texel as postprocess.frag writes it into `color_luma`: the colour, and in
# alpha its luma (quantised to the 8 bits that buffer has) or 1 where the plot
# asked for no FXAA. `x`, `y` count from the BOTTOM-left, as GL's texture does,
# so the search below breaks ties the way GLMakie's does.
@inline function fxaa_texel(colour, flag, width::Int32, height::Int32, x::Int32, y::Int32)
    x = clamp(x, Int32(0), width - Int32(1))
    y = clamp(y, Int32(0), height - Int32(1))
    i = (height - Int32(1) - y) * width + x + Int32(1)
    @inbounds c = colour[i]
    @inbounds f = flag[i]
    r, g, b = unorm(c.r), unorm(c.g), unorm(c.b)
    luma = unorm(f.r) > 0.5f0 ?
        round(clamp(0.299f0 * r + 0.587f0 * g + 0.114f0 * b, 0f0, 1f0) * 255f0) * (1f0 / 255f0) : 1f0
    return Vec4f(r, g, b, luma)
end

@inline fxaa_luma(colour, flag, width::Int32, height::Int32, x::Int32, y::Int32) =
    fxaa_texel(colour, flag, width, height, x, y)[4]

# `FxaaTexTop`: a linear, clamp-to-edge sample at `pos`, in texel units.
@inline function fxaa_tex(colour, flag, width::Int32, height::Int32, pos::Vec2f)
    tx = pos[1] - 0.5f0
    ty = pos[2] - 0.5f0
    fx = floor(tx); fy = floor(ty)
    ax = tx - fx; ay = ty - fy
    x0 = unsafe_trunc(Int32, fx); y0 = unsafe_trunc(Int32, fy)
    t00 = fxaa_texel(colour, flag, width, height, x0, y0)
    t10 = fxaa_texel(colour, flag, width, height, x0 + Int32(1), y0)
    t01 = fxaa_texel(colour, flag, width, height, x0, y0 + Int32(1))
    t11 = fxaa_texel(colour, flag, width, height, x0 + Int32(1), y0 + Int32(1))
    return (t00 * (1f0 - ax) + t10 * ax) * (1f0 - ay) + (t01 * (1f0 - ax) + t11 * ax) * ay
end

# ── FXAA 3.11 Quality, PC, preset 12 (GLMakie's postprocessing/fxaa.frag) ────
#
# `pos` and `rcpframe` are in TEXEL units: every position in the algorithm is the
# pixel centre plus multiples of `rcpframe`, and every length it compares is a
# ratio along one axis, so scaling both by the frame size changes nothing but the
# rounding of `pos * size`. The early exit returns the centre texel unchanged,
# which is why a frame with no FXAA plot in it can skip the pass.

const FXAA_QUALITY_P0 = 1.0f0
const FXAA_QUALITY_P1 = 1.5f0
const FXAA_QUALITY_P2 = 2.0f0
const FXAA_QUALITY_P3 = 4.0f0
const FXAA_QUALITY_P4 = 12.0f0

# One step of the end-of-edge search: the body each `#if (FXAA_QUALITY__PS > n)`
# block repeats, with that block's distance.
@inline function fxaa_search_step(colour, flag, width, height, posN::Vec2f, posP::Vec2f,
                                  offNP::Vec2f, step::Float32, lumaEndN::Float32, lumaEndP::Float32,
                                  doneN::Bool, doneP::Bool, lumaNN::Float32, gradientScaled::Float32)
    if !doneN
        lumaEndN = fxaa_tex(colour, flag, width, height, posN)[4]
        lumaEndN = lumaEndN - lumaNN * 0.5f0
    end
    if !doneP
        lumaEndP = fxaa_tex(colour, flag, width, height, posP)[4]
        lumaEndP = lumaEndP - lumaNN * 0.5f0
    end
    doneN = abs(lumaEndN) >= gradientScaled
    doneP = abs(lumaEndP) >= gradientScaled
    doneN || (posN = posN - offNP * step)
    doneNP = !doneN || !doneP
    doneP || (posP = posP + offNP * step)
    return posN, posP, lumaEndN, lumaEndP, doneN, doneP, doneNP
end

function fxaa_pixel_shader(colour, flag, width::Int32, height::Int32, pos::Vec2f,
                           rcpframe::Vec2f, subpix::Float32, edge_threshold::Float32,
                           edge_threshold_min::Float32)
    posM = pos
    # `FxaaTexOff` is only ever asked at the centre, so its offsets are whole texels.
    ix = unsafe_trunc(Int32, floor(posM[1]))
    iy = unsafe_trunc(Int32, floor(posM[2]))

    rgbyM = fxaa_tex(colour, flag, width, height, posM)
    lumaM = rgbyM[4]
    lumaS = fxaa_luma(colour, flag, width, height, ix, iy + Int32(1))
    lumaE = fxaa_luma(colour, flag, width, height, ix + Int32(1), iy)
    lumaN = fxaa_luma(colour, flag, width, height, ix, iy - Int32(1))
    lumaW = fxaa_luma(colour, flag, width, height, ix - Int32(1), iy)

    maxSM = max(lumaS, lumaM)
    minSM = min(lumaS, lumaM)
    maxESM = max(lumaE, maxSM)
    minESM = min(lumaE, minSM)
    maxWN = max(lumaN, lumaW)
    minWN = min(lumaN, lumaW)
    rangeMax = max(maxWN, maxESM)
    rangeMin = min(minWN, minESM)
    rangeMaxScaled = rangeMax * edge_threshold
    range = rangeMax - rangeMin
    rangeMaxClamped = max(edge_threshold_min, rangeMaxScaled)
    range < rangeMaxClamped && return rgbyM

    lumaNW = fxaa_luma(colour, flag, width, height, ix - Int32(1), iy - Int32(1))
    lumaSE = fxaa_luma(colour, flag, width, height, ix + Int32(1), iy + Int32(1))
    lumaNE = fxaa_luma(colour, flag, width, height, ix + Int32(1), iy - Int32(1))
    lumaSW = fxaa_luma(colour, flag, width, height, ix - Int32(1), iy + Int32(1))

    lumaNS = lumaN + lumaS
    lumaWE = lumaW + lumaE
    subpixRcpRange = 1f0 / range
    subpixNSWE = lumaNS + lumaWE
    edgeHorz1 = (-2f0 * lumaM) + lumaNS
    edgeVert1 = (-2f0 * lumaM) + lumaWE

    lumaNESE = lumaNE + lumaSE
    lumaNWNE = lumaNW + lumaNE
    edgeHorz2 = (-2f0 * lumaE) + lumaNESE
    edgeVert2 = (-2f0 * lumaN) + lumaNWNE

    lumaNWSW = lumaNW + lumaSW
    lumaSWSE = lumaSW + lumaSE
    edgeHorz4 = (abs(edgeHorz1) * 2f0) + abs(edgeHorz2)
    edgeVert4 = (abs(edgeVert1) * 2f0) + abs(edgeVert2)
    edgeHorz3 = (-2f0 * lumaW) + lumaNWSW
    edgeVert3 = (-2f0 * lumaS) + lumaSWSE
    edgeHorz = abs(edgeHorz3) + edgeHorz4
    edgeVert = abs(edgeVert3) + edgeVert4

    subpixNWSWNESE = lumaNWSW + lumaNESE
    lengthSign = rcpframe[1]
    horzSpan = edgeHorz >= edgeVert
    subpixA = subpixNSWE * 2f0 + subpixNWSWNESE

    if !horzSpan
        lumaN = lumaW
        lumaS = lumaE
    end
    horzSpan && (lengthSign = rcpframe[2])
    subpixB = (subpixA * (1f0 / 12f0)) - lumaM

    gradientN = lumaN - lumaM
    gradientS = lumaS - lumaM
    lumaNN = lumaN + lumaM
    lumaSS = lumaS + lumaM
    pairN = abs(gradientN) >= abs(gradientS)
    gradient = max(abs(gradientN), abs(gradientS))
    pairN && (lengthSign = -lengthSign)
    subpixC = clamp(abs(subpixB) * subpixRcpRange, 0f0, 1f0)

    offNP = Vec2f(!horzSpan ? 0f0 : rcpframe[1], horzSpan ? 0f0 : rcpframe[2])
    posB = !horzSpan ? Vec2f(posM[1] + lengthSign * 0.5f0, posM[2]) :
                       Vec2f(posM[1], posM[2] + lengthSign * 0.5f0)

    posN = posB - offNP * FXAA_QUALITY_P0
    posP = posB + offNP * FXAA_QUALITY_P0
    subpixD = ((-2f0) * subpixC) + 3f0
    lumaEndN = fxaa_tex(colour, flag, width, height, posN)[4]
    subpixE = subpixC * subpixC
    lumaEndP = fxaa_tex(colour, flag, width, height, posP)[4]

    pairN || (lumaNN = lumaSS)
    gradientScaled = gradient * 1f0 / 4f0
    lumaMM = lumaM - lumaNN * 0.5f0
    subpixF = subpixD * subpixE
    lumaMLTZero = lumaMM < 0f0

    lumaEndN -= lumaNN * 0.5f0
    lumaEndP -= lumaNN * 0.5f0
    doneN = abs(lumaEndN) >= gradientScaled
    doneP = abs(lumaEndP) >= gradientScaled
    doneN || (posN = posN - offNP * FXAA_QUALITY_P1)
    doneNP = !doneN || !doneP
    doneP || (posP = posP + offNP * FXAA_QUALITY_P1)

    if doneNP
        posN, posP, lumaEndN, lumaEndP, doneN, doneP, doneNP = fxaa_search_step(
            colour, flag, width, height, posN, posP, offNP, FXAA_QUALITY_P2,
            lumaEndN, lumaEndP, doneN, doneP, lumaNN, gradientScaled)
        if doneNP
            posN, posP, lumaEndN, lumaEndP, doneN, doneP, doneNP = fxaa_search_step(
                colour, flag, width, height, posN, posP, offNP, FXAA_QUALITY_P3,
                lumaEndN, lumaEndP, doneN, doneP, lumaNN, gradientScaled)
            if doneNP
                posN, posP, lumaEndN, lumaEndP, doneN, doneP, doneNP = fxaa_search_step(
                    colour, flag, width, height, posN, posP, offNP, FXAA_QUALITY_P4,
                    lumaEndN, lumaEndP, doneN, doneP, lumaNN, gradientScaled)
            end
        end
    end

    dstN = !horzSpan ? posM[2] - posN[2] : posM[1] - posN[1]
    dstP = !horzSpan ? posP[2] - posM[2] : posP[1] - posM[1]

    goodSpanN = (lumaEndN < 0f0) != lumaMLTZero
    spanLength = (dstP + dstN)
    goodSpanP = (lumaEndP < 0f0) != lumaMLTZero
    spanLengthRcp = 1f0 / spanLength

    directionN = dstN < dstP
    dst = min(dstN, dstP)
    goodSpan = directionN ? goodSpanN : goodSpanP
    subpixG = subpixF * subpixF
    pixelOffset = (dst * (-spanLengthRcp)) + 0.5f0
    subpixH = subpixG * subpix

    pixelOffsetGood = goodSpan ? pixelOffset : 0f0
    pixelOffsetSubpix = max(pixelOffsetGood, subpixH)
    posM = !horzSpan ? Vec2f(posM[1] + pixelOffsetSubpix * lengthSign, posM[2]) :
                       Vec2f(posM[1], posM[2] + pixelOffsetSubpix * lengthSign)
    rgb = fxaa_tex(colour, flag, width, height, posM)
    return Vec4f(rgb[1], rgb[2], rgb[3], lumaM)
end

# fxaa.frag's `main`, with GLMakie's knob values. The fragment coordinate counts
# rows from the top; the shader's texture from the bottom.
function fxaa_fragment(_inputs, colour, flag, width::Int32, height::Int32)
    pos = Vec2f(frag_coord_x(), Float32(height) - frag_coord_y())
    c = fxaa_pixel_shader(colour, flag, width, height, pos, Vec2f(1f0, 1f0),
                          0.75f0,     # fxaaQualitySubpix
                          0.166f0,    # fxaaQualityEdgeThreshold
                          0.0833f0)   # fxaaQualityEdgeThresholdMin
    return Vec4f(c[1], c[2], c[3], 1f0)
end

function get_fxaa_pipeline!(screen)
    get!(screen.gfx_pipelines, :fxaa) do
        GraphicsPipeline(; vertex = VertexShader(Mantle.blit_vertex),
                           fragment = FragmentShader(fxaa_fragment),
                           blend = Opaque(), cull = NoCull(), depth = DepthOff())
    end
end
