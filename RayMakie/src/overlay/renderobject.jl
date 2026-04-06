# =============================================================================
# LavaRenderObject — Vulkan graphics pipeline render object
# =============================================================================
# Analogous to GLMakie's RenderObject. Holds everything needed to draw in a
# single render pass: compiled pipeline, GPU buffers, texture bindings, draw config.
# Created once inside register_computation!, updated in-place on subsequent calls.

# Uses Lava imports from gfx_pipeline.jl (included before this file)

"""
    LavaRenderObject

Holds a fully compiled Lava graphics pipeline plus all GPU resources needed to draw.
Created once, updated in-place via `update!` on LavaArrays.

# Fields
- `pipeline`: The `GraphicsPipeline` (lazily compiled Vulkan pipeline)
- `buffers`: `Dict{Symbol, LavaArray}` — persistent GPU buffers, updated via `update!`
- `uniforms`: `Dict{Symbol, Any}` — scalar uniforms (Vec2f, Float32, Int32, Mat4f, etc.)
- `bindings`: `Nothing` or `TextureBindings` — descriptor set for texture sampling
- `vertex_count`: Number of vertices per draw call
- `instances`: Number of instances (1 for most, N for instanced draws)
- `visible`: Whether to draw this object
- `viewport`: `Nothing` or `(x, y, w, h)` for per-scene Vulkan dynamic viewport
"""
mutable struct LavaRenderObject
    pipeline::GraphicsPipeline
    buffers::Dict{Symbol, LavaArray}
    uniforms::Dict{Symbol, Any}
    arg_names::Tuple   # ordered names for building args tuple, e.g. (:vertex, :color, ..., :resolution, ...)
    bindings::Any      # Nothing or TextureBindings
    vertex_count::Int
    instances::Int
    visible::Bool
    viewport::Any      # Nothing or (Float32, Float32, Float32, Float32)
    # Persistent arg buffer — avoids per-draw allocation from the global slab.
    # This is a small VkMappedBuffer (typically 256-512 bytes) that holds the
    # packed shader arguments. Written in-place each frame, never freed/reallocated.
    arg_buffer::Any  # Nothing or Lava.VkMappedBuffer
    push_data::Vector{UInt8}  # 8-byte push constant (BDA pointer), reused
end

function LavaRenderObject(pipeline::GraphicsPipeline;
                          buffers=Dict{Symbol, LavaArray}(),
                          uniforms=Dict{Symbol, Any}(),
                          arg_names::Tuple=(),
                          bindings=nothing,
                          vertex_count=0,
                          instances=1,
                          visible=true,
                          viewport=nothing)
    LavaRenderObject(pipeline, buffers, uniforms, arg_names, bindings, vertex_count, instances, visible, viewport,
                     nothing, Vector{UInt8}(undef, 8))
end

"""
    build_args(robj::LavaRenderObject) -> Tuple

Build the args tuple for shader invocation from named buffers and uniforms,
in the order specified by `robj.arg_names`.
"""
function build_args(robj::LavaRenderObject)
    return ntuple(length(robj.arg_names)) do i
        name = robj.arg_names[i]
        if haskey(robj.buffers, name)
            robj.buffers[name]
        elseif haskey(robj.uniforms, name)
            robj.uniforms[name]
        else
            error("LavaRenderObject: missing arg '$name' in buffers or uniforms")
        end
    end
end

"""
    update_buffer!(robj::LavaRenderObject, name::Symbol, data::AbstractArray)

Update a named GPU buffer. Uses `Lava.update!` which resizes if needed and frees
the old buffer immediately (no GC pressure).
"""
function update_buffer!(robj::LavaRenderObject, name::Symbol, data::AbstractArray)
    if haskey(robj.buffers, name)
        Lava.update!(robj.buffers[name], data)
    else
        robj.buffers[name] = LavaArray(data)
    end
    return robj.buffers[name]
end

"""
    update_texture!(robj::LavaRenderObject, image_data; filter=:linear, wrap=:clamp)

Update or create the texture bindings on a render object.
"""
function update_texture!(robj::LavaRenderObject, image_data; filter=:linear, wrap=:clamp)
    tex = LavaTexture2D(image_data)
    sampler = LavaSampler(; filter, wrap)
    robj.bindings = bind_textures([SampledTexture(tex, sampler)])
    return robj.bindings
end

"""
    build_draw_args(robj::LavaRenderObject, arg_names::Tuple)

Build the args tuple for `pack_gfx_args` from named buffers and uniforms.
Order matches the shader function signature.
"""
function build_draw_args(robj::LavaRenderObject, arg_names::NTuple{N, Symbol}) where N
    return ntuple(N) do i
        name = arg_names[i]
        if haskey(robj.buffers, name)
            robj.buffers[name]
        elseif haskey(robj.uniforms, name)
            robj.uniforms[name]
        else
            error("LavaRenderObject: missing arg '$name' — not in buffers or uniforms")
        end
    end
end

"""
    compile_robj!(robj::LavaRenderObject, arg_names; color_format, descriptor_set_layout=nothing)

Ensure the pipeline is compiled for the current arg types. Returns (vert_shader, compiled).
"""
function compile_robj!(robj::LavaRenderObject, args::Tuple;
                       color_format=Vulkan.FORMAT_R32G32B32A32_SFLOAT,
                       descriptor_set_layout=nothing)
    pipeline = robj.pipeline
    tt = gfx_type_tuple(args)
    ds_layout = descriptor_set_layout
    if ds_layout === nothing && robj.bindings !== nothing
        ds_layout = robj.bindings.layout
    end
    vert_shader, compiled = Lava._ensure_compiled_with_shader!(pipeline,
        pipeline.vertex, pipeline.fragment, tt, tt;
        color_format, descriptor_set_layout=ds_layout)
    return vert_shader, compiled
end

"""Convert args tuple to device-side types (LavaArray → LavaDeviceArray)."""
function gfx_type_tuple(args)
    types = map(args) do arg
        arg isa Lava.LavaArray ? typeof(Lava.LavaDeviceArray(arg)) : typeof(arg)
    end
    return Tuple{types...}
end

# =============================================================================
# update_robj! — mirrors GLMakie's update_robjs! exactly
# =============================================================================
# Iterates ALL args, checks changed[name], updates only what changed.
# If the value is an AbstractArray → update GPU buffer.
# If scalar → update uniform dict.

"""
    update_robj!(robj, args, changed)

Update a LavaRenderObject from changed compute graph outputs.
Mirrors GLMakie's `update_robjs!` — iterates `changed`, updates only what changed.
Arrays → `update!` GPU buffer. Scalars → set uniform.
"""
function update_robj!(robj::LavaRenderObject, args::NamedTuple, changed::NamedTuple)
    for name in keys(args)
        changed[name] || continue
        value = args[name]
        if name === :visible
            robj.visible = value
        elseif haskey(robj.buffers, name)
            # GPU buffer — update in place (resize if needed)
            if value isa AbstractArray
                if name === :indices
                    robj.buffers[name] = Lava.alloc_index_buffer(UInt32.(value))
                else
                    Lava.update!(robj.buffers[name], value)
                end
            end
        elseif haskey(robj.uniforms, name)
            # Scalar uniform — just assign
            robj.uniforms[name] = value
        end
    end
end

# =============================================================================
# construct_robj — create a LavaRenderObject from initial args
# =============================================================================
# Called on first render. Separates args into buffers (arrays) vs uniforms (scalars).

"""
    construct_robj(pipeline, args, arg_names; backend, vertex_count, bindings)

Create a LavaRenderObject from initial args NamedTuple.
Arrays become GPU buffers, scalars become uniforms.
"""
# Check if a value should be a GPU buffer (mutable Vector) vs a uniform (scalar/Vec/Mat).
# Vectors of concrete element types → GPU buffer. Everything else → uniform.
is_gpu_buffer(x::Vector) = true
is_gpu_buffer(x) = false

function construct_robj(pipeline::GraphicsPipeline, args::NamedTuple, arg_names::Tuple;
                        backend=Lava.LavaBackend(), vertex_count=0, instances=1, bindings=nothing)
    buffers = Dict{Symbol, LavaArray}()
    uniforms = Dict{Symbol, Any}()
    for name in keys(args)
        value = args[name]
        if is_gpu_buffer(value)
            if name === :indices
                buffers[name] = Lava.alloc_index_buffer(UInt32.(value))
            else
                buffers[name] = Adapt.adapt(backend, value)
            end
        else
            uniforms[name] = value
        end
    end
    LavaRenderObject(pipeline;
        buffers, uniforms, arg_names, bindings,
        vertex_count, instances)
end
