# ============================================================================
# Overlay Compositing
# ============================================================================
# Composite overlay buffer onto ray-traced image

"""
    clear_overlay!(overlay)

Clear the overlay buffer to transparent black.
"""
function clear_overlay!(overlay::AbstractMatrix{RGBA{Float32}})
    overlay .= RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    return overlay
end

"""
    composite!(dst, background, overlay)

Composite overlay onto background using Porter-Duff "over" operation.
Result is written to dst (can be same as background for in-place operation).

# Arguments
- `dst`: Output buffer (RGB{Float32})
- `background`: Ray-traced image (RGB{Float32})
- `overlay`: Overlay buffer (RGBA{Float32})
"""
function composite!(
    dst::AbstractMatrix{RGB{Float32}},
    background::AbstractMatrix{RGB{Float32}},
    overlay::AbstractMatrix{RGBA{Float32}},
)
    @assert size(dst) == size(background) == size(overlay)

    for i in eachindex(dst, background, overlay)
        bg = background[i]
        ov = overlay[i]
        alpha = ov.alpha
        inv_alpha = 1f0 - alpha

        dst[i] = RGB{Float32}(
            ov.r * alpha + bg.r * inv_alpha,
            ov.g * alpha + bg.g * inv_alpha,
            ov.b * alpha + bg.b * inv_alpha
        )
    end
    return dst
end

"""
    composite!(dst, overlay)

In-place composite: blend overlay onto dst.
"""
function composite!(
    dst::AbstractMatrix{RGB{Float32}},
    overlay::AbstractMatrix{RGBA{Float32}},
)
    return composite!(dst, dst, overlay)
end

# ============================================================================
# GPU Kernel Version
# ============================================================================

"""
    composite_kernel!

GPU kernel for parallel compositing.
"""
@kernel function composite_kernel!(
    dst,
    @Const(background),
    @Const(overlay),
)
    i = @index(Global, Linear)

    @inbounds begin
        bg = background[i]
        ov = overlay[i]
        alpha = ov.alpha
        inv_alpha = 1f0 - alpha

        dst[i] = RGB{Float32}(
            ov.r * alpha + bg.r * inv_alpha,
            ov.g * alpha + bg.g * inv_alpha,
            ov.b * alpha + bg.b * inv_alpha
        )
    end
end

"""
    composite_gpu!(dst, background, overlay)

GPU-accelerated compositing using KernelAbstractions.
"""
function composite_gpu!(
    dst::AbstractMatrix{RGB{Float32}},
    background::AbstractMatrix{RGB{Float32}},
    overlay::AbstractMatrix{RGBA{Float32}},
)
    backend = KernelAbstractions.get_backend(dst)
    kernel! = composite_kernel!(backend)
    kernel!(dst, background, overlay; ndrange=length(dst))
    KernelAbstractions.synchronize(backend)
    return dst
end

# ============================================================================
# Utility: Create Overlay Buffer
# ============================================================================

"""
    create_overlay_buffer(resolution; backend=Array)

Create an overlay buffer matching the given resolution.
"""
function create_overlay_buffer(resolution::Tuple{Int, Int}; backend::Type=Array)
    return backend{RGBA{Float32}}(undef, resolution...)
end

function create_overlay_buffer(width::Int, height::Int; backend::Type=Array)
    return create_overlay_buffer((height, width); backend=backend)
end
