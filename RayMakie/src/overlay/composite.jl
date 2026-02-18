# ============================================================================
# Overlay Compositing (KA Kernel Path)
# ============================================================================
# All operations use KernelAbstractions — single code path for CPU and GPU.

# ============================================================================
# Clear
# ============================================================================

function clear_overlay!(overlay::AbstractMatrix{RGBA{Float32}})
    overlay .= RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    return overlay
end

# ============================================================================
# Composite Kernel
# ============================================================================

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

        # Overlay is already premultiplied alpha (from Porter-Duff "over" blending
        # in the per-pixel rasterizers), so use src + dst*(1-alpha)
        dst[i] = RGB{Float32}(
            ov.r + bg.r * inv_alpha,
            ov.g + bg.g * inv_alpha,
            ov.b + bg.b * inv_alpha
        )
    end
end

function composite!(
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

function composite!(
    dst::AbstractMatrix{RGB{Float32}},
    overlay::AbstractMatrix{RGBA{Float32}},
)
    return composite!(dst, dst, overlay)
end

# ============================================================================
# Utility: Create Overlay Buffer
# ============================================================================

function create_overlay_buffer(backend, resolution::Tuple{Int, Int})
    buf = KernelAbstractions.allocate(backend, RGBA{Float32}, resolution...)
    clear_overlay!(buf)
    return buf
end
