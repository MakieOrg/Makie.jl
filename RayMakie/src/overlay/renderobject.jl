# =============================================================================
# RenderObject — Vulkan graphics pipeline render object
# =============================================================================
# Analogous to GLMakie's RenderObject. Holds everything needed to draw in a
# single render pass: compiled pipeline, GPU buffers, texture bindings, draw config.
# Created once inside register_computation!, updated in-place on subsequent calls.

# Uses Lava imports from gfx_pipeline.jl (included before this file)

"""
    RenderObject

Holds a fully compiled Lava graphics pipeline plus all GPU resources needed to draw.
Created once, updated in-place via `update!` on its device arrays.

# Fields
- `pipeline`: The `GraphicsPipeline` (lazily compiled Vulkan pipeline)
- `buffers`: `Dict{Symbol, AbstractGPUArray}` — persistent GPU buffers, updated via `update!`
- `uniforms`: `Dict{Symbol, Any}` — scalar uniforms (Vec2f, Float32, Int32, Mat4f, etc.)
- `bindings`: `Nothing` or `VulkanTextureBindings` — descriptor set for texture sampling
- `vertex_count`: what the draw counts — vertices for a `GraphicsPipeline`,
  and WORKGROUPS for a `MeshPipeline`, which has no vertex stream to count
- `instances`: Number of instances (1 for most, N for instanced draws)
- `visible`: Whether to draw this object
- `viewport`: `Nothing` or `(x, y, w, h)` for per-scene Vulkan dynamic viewport
"""
mutable struct RenderObject
    # Either front end. A mesh pipeline is what a plot whose geometry is
    # generated rather than stored draws through — `Hikari.FEMMaterial` is one —
    # and everything below this field is the same for both, which is why they
    # share the type rather than being two of it.
    pipeline::Union{GraphicsPipeline, Mantle.MeshPipeline}
    # The backend this object's buffers and textures live on. Carried rather
    # than looked up: `update_texture!` and `update_buffer!` are handed only the
    # render object, and they used to name `VulkanTexture2D`/`LavaArray`
    # directly — which is both a driver dependency and a guess about where the
    # existing buffers already are.
    backend::Any
    buffers::Dict{Symbol, AbstractGPUArray}
    uniforms::Dict{Symbol, Any}
    arg_names::Tuple   # ordered names for building args tuple, e.g. (:vertex, :color, ..., :resolution, ...)
    bindings::Any      # Nothing or VulkanTextureBindings
    # The texture the bindings point at, kept so `update_texture!` can upload
    # INTO it rather than making a new one. A recorded plan bakes the descriptor
    # set, so a new set is a texture the frame will not see — see there.
    texture::Any       # Nothing or the backend's Texture2D
    vertex_count::Int
    instances::Int
    visible::Bool
    viewport::Any      # Nothing or (Float32, Float32, Float32, Float32)
    # Persistent arg buffer — avoids per-draw allocation from the global slab.
    # This is a small VkMappedBuffer (typically 256-512 bytes) that holds the
    # packed shader arguments. Written in-place each frame, never freed/reallocated.
    arg_buffer::Any  # Nothing or the backend's mapped buffer (MantleVulkanExt.VkMappedBuffer)
    push_data::Vector{UInt8}  # 8-byte push constant (BDA pointer), reused
end

# `fxaa` is the plot's attribute, and every stage takes it as its last argument,
# `:fxaa`, to write into the frame's fxaa attachment (see overlay/fxaa.jl).
# Required, because an object that forgot it would silently opt out of FXAA. Fixed
# at creation, as GLMakie's is: it lives in the object id there.
function RenderObject(pipeline::Union{GraphicsPipeline, Mantle.MeshPipeline};
                          backend,
                          fxaa::Bool,
                          buffers=Dict{Symbol, AbstractGPUArray}(),
                          uniforms=Dict{Symbol, Any}(),
                          arg_names::Tuple=(),
                          bindings=nothing,
                          vertex_count=0,
                          instances=1,
                          visible=true,
                          viewport=nothing)
    last(arg_names) === :fxaa || throw(ArgumentError(
        "RenderObject: the stages' last argument has to be `:fxaa`, got $(arg_names)"))
    uniforms[:fxaa] = Int32(fxaa)
    RenderObject(pipeline, backend, buffers, uniforms, arg_names, bindings,
                     nothing,   # texture: `update_texture!` fills it
                     vertex_count, instances, visible, viewport,
                     nothing, Vector{UInt8}(undef, 8))
end

wants_fxaa(robj::RenderObject) = robj.uniforms[:fxaa]::Int32 != Int32(0)
plot_fxaa(plot) = Bool(Makie.to_value(plot.fxaa))

"""
    build_args(robj::RenderObject) -> Tuple

Build the args tuple for shader invocation from named buffers and uniforms,
in the order specified by `robj.arg_names`.
"""
function build_args(robj::RenderObject)
    return ntuple(length(robj.arg_names)) do i
        name = robj.arg_names[i]
        if haskey(robj.buffers, name)
            robj.buffers[name]
        elseif haskey(robj.uniforms, name)
            robj.uniforms[name]
        else
            error("RenderObject: missing arg '$name' in buffers or uniforms")
        end
    end
end

"""
    update_buffer!(robj::RenderObject, name::Symbol, data::AbstractArray)

Update a named GPU buffer.  `Base.resize!` on a pooled device array is capacity-aware
(no Vulkan alloc when the new size fits the existing VkBuffer) and retires
the old VkBuffer via deferred-free on genuine growth — no GC pressure, no
per-call CPU sync.
"""
function update_buffer!(robj::RenderObject, name::Symbol, data::AbstractArray)
    if haskey(robj.buffers, name)
        buf = robj.buffers[name]
        resize!(buf, length(data))
        copyto!(buf, data)
    else
        robj.buffers[name] = Mantle.devicearray(robj.backend, data)
    end
    return robj.buffers[name]
end

"""
    update_texture!(robj, image_data; filter, wrap) -> bindings

New pixels for this render object's texture.

**Uploads into the EXISTING texture whenever it fits.** This used to build a new
`Texture2D`, a new `Sampler` and a new descriptor set every time, and the frame
never showed them: a composited frame is a RECORDED Mantle plan, and
`cmd_bind_descriptor_sets` bakes the set handle into the command buffer. Handing
`rebind!` a different set changes a value nothing reads again. The symptom is
an `image!` whose observable updates, whose `trace_renderobject` recomputes,
whose bindings really do change — and whose picture never moves. Measured: a
32x32 image driven red -> blue -> green rendered red three times.

Keeping the same `VkImage` and writing new texels into it leaves the baked
descriptor set pointing at the right thing, so the recorded plan is correct
without being rebuilt. A size or format change still needs a new texture, and
`frame_signature` carries the texture's identity so that case rebuilds the plan.
"""
function update_texture!(robj::RenderObject, image_data; filter=:linear, wrap=:clamp)
    tex = robj.texture
    if tex !== nothing && texturefits(tex, image_data)
        upload_texture_data!(tex, image_data)
        return robj.bindings
    end
    tex = Texture2D(robj.backend, image_data)
    sampler = Sampler(robj.backend; filter, wrap)
    robj.texture = tex
    robj.bindings = bind_textures([SampledTexture(tex, sampler)])
    return robj.bindings
end

"""Whether `data` can be written into `tex` without making a new one."""
texturefits(tex, data) = size(tex) == size(data) && eltype(tex) == eltype(data)

"""
    build_draw_args(robj::RenderObject, arg_names::Tuple)

Build the args tuple for `pack_gfx_args` from named buffers and uniforms.
Order matches the shader function signature.
"""
function build_draw_args(robj::RenderObject, arg_names::NTuple{N, Symbol}) where N
    return ntuple(N) do i
        name = arg_names[i]
        if haskey(robj.buffers, name)
            robj.buffers[name]
        elseif haskey(robj.uniforms, name)
            robj.uniforms[name]
        else
            error("RenderObject: missing arg '$name' — not in buffers or uniforms")
        end
    end
end

# DELETED: `compile_robj!` and `gfx_type_tuple`.
#
# Both were dead — nothing called the first and only the first called the second —
# and between them they held the last two things this package had no business
# holding: a reach into `MantleVulkanExt` for `ensure_compiled_with_shader!`, and
# a hard `Lava.DeviceArray`, which is a name that does not resolve without a
# Vulkan driver.
#
# What they did is `Mantle.compile_draw` in `draw_renderobject!`: it takes the
# RESOLVED arguments and each backend derives its own device signature from them,
# so there is no type tuple to build here and no descriptor-set layout to thread.


# =============================================================================
# update_robj! — mirrors GLMakie's update_robjs! exactly
# =============================================================================
# Iterates ALL args, checks changed[name], updates only what changed.
# If the value is an AbstractArray → update GPU buffer.
# If scalar → update uniform dict.

"""
    update_robj!(robj, args, changed)

Update a RenderObject from changed compute graph outputs.
Mirrors GLMakie's `update_robjs!` — iterates `changed`, updates only what changed.
Arrays → `update!` GPU buffer. Scalars → set uniform.
"""
function update_robj!(robj::RenderObject, args::NamedTuple, changed::NamedTuple)
    for name in keys(args)
        changed[name] || continue
        value = args[name]
        if name === :visible
            robj.visible = value
        elseif haskey(robj.buffers, name)
            # GPU buffer — update in place (capacity-aware resize + copyto)
            if value isa AbstractArray
                if name === :indices
                    robj.buffers[name] = Mantle.indexbuffer(robj.backend, UInt32.(value))
                else
                    buf = robj.buffers[name]
                    resize!(buf, length(value))
                    copyto!(buf, value)
                end
            end
        elseif haskey(robj.uniforms, name)
            # Scalar uniform — just assign
            robj.uniforms[name] = value
        end
    end
end

# =============================================================================
# construct_robj — create a RenderObject from initial args
# =============================================================================
# Called on first render. Separates args into buffers (arrays) vs uniforms (scalars).

"""
    construct_robj(pipeline, args, arg_names; backend, vertex_count, bindings)

Create a RenderObject from initial args NamedTuple.
Arrays become GPU buffers, scalars become uniforms.
"""
# Check if a value should be a GPU buffer (mutable Vector) vs a uniform (scalar/Vec/Mat).
# Vectors of concrete element types → GPU buffer. Everything else → uniform.
is_gpu_buffer(x::Vector) = true
is_gpu_buffer(x) = false

function construct_robj(pipeline::GraphicsPipeline, args::NamedTuple, arg_names::Tuple;
                        backend, fxaa::Bool, vertex_count=0, instances=1, bindings=nothing)
    buffers = Dict{Symbol, AbstractGPUArray}()
    uniforms = Dict{Symbol, Any}()
    for name in keys(args)
        value = args[name]
        if is_gpu_buffer(value)
            if name === :indices
                buffers[name] = Mantle.indexbuffer(backend, UInt32.(value))
            else
                # `Mantle.devicearray`, not `Adapt.adapt`: the backend decides
                # the storage, and on Metal that is the difference between a
                # host write being a `memcpy` and being a staged blit. Adapting
                # went around Mantle to the backend's own default.
                buffers[name] = Mantle.devicearray(backend, value)
            end
        else
            uniforms[name] = value
        end
    end
    RenderObject(pipeline;
        backend, fxaa, buffers, uniforms, arg_names, bindings,
        vertex_count, instances)
end
