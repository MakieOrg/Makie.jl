@enum CubeSides TOP BOTTOM FRONT BACK RIGHT LEFT

struct Grid{N, T <: AbstractRange}
    dims::NTuple{N, T}
end
Base.ndims(::Grid{N, T}) where {N, T} = N

Grid(ranges::AbstractRange...) = Grid(ranges)
function Grid(a::Array{T, N}) where {N, T}
    s = Vec{N, Float32}(size(a))
    smax = maximum(s)
    s = s ./ smax
    return Grid(
        ntuple(Val{N}) do i
            range(0, stop = s[i], length = size(a, i))
        end
    )
end

Grid(a::AbstractArray, ranges...) = Grid(a, ranges)

"""
This constructor constructs a grid from ranges given as a tuple.
Due to the approach, the tuple `ranges` can consist of NTuple(2, T)
and all kind of range types. The constructor will make sure that all ranges match
the size of the dimension of the array `a`.
"""
function Grid(a::AbstractArray{T, N}, ranges::Tuple) where {T, N}
    length(ranges) = ! N && throw(
        ArgumentError(
            "You need to supply a range for every dimension of the array. Given: $ranges
        given Array: $(typeof(a))"
        )
    )
    return Grid(
        ntuple(Val(N)) do i
            range(first(ranges[i]), stop = last(ranges[i]), length = size(a, i))
        end
    )
end

Base.length(p::Grid) = prod(size(p))
Base.size(p::Grid) = map(length, p.dims)
function Base.getindex(p::Grid{N, T}, i) where {N, T}
    inds = ind2sub(size(p), i)
    return Point{N, eltype(T)}(
        ntuple(Val(N)) do i
            p.dims[i][inds[i]]
        end
    )
end

Base.iterate(g::Grid, i = 1) = i <= length(g) ? (g[i], i + 1) : nothing

GLAbstraction.isa_gl_struct(x::Grid) = true
GLAbstraction.toglsltype_string(t::Grid{N, T}) where {N, T} = "uniform Grid$(N)D"
function GLAbstraction.gl_convert_struct(::GLAbstraction.GLContext, g::Grid{N, T}, uniform_name::Symbol) where {N, T}
    return Dict{Symbol, Any}(
        Symbol("$uniform_name.start") => Vec{N, Float32}(minimum.(g.dims)),
        Symbol("$uniform_name.stop") => Vec{N, Float32}(maximum.(g.dims)),
        Symbol("$uniform_name.lendiv") => Vec{N, Cint}(length.(g.dims) .- 1),
        Symbol("$uniform_name.dims") => Vec{N, Cint}(map(length, g.dims))
    )
end
function GLAbstraction.gl_convert_struct(::GLAbstraction.GLContext, g::Grid{1, T}, uniform_name::Symbol) where {T}
    x = g.dims[1]
    return Dict{Symbol, Any}(
        Symbol("$uniform_name.start") => Float32(minimum(x)),
        Symbol("$uniform_name.stop") => Float32(maximum(x)),
        Symbol("$uniform_name.lendiv") => Cint(length(x) - 1),
        Symbol("$uniform_name.dims") => Cint(length(x))
    )
end

struct GLVisualizeShader <: AbstractLazyShader
    screen::Screen
    paths::Vector{ShaderSource}
    kw_args::Dict{Symbol, Any}
    function GLVisualizeShader(
            screen::Screen, paths::Vector{String};
            view = Dict{String, String}(), kw_args...
        )
        # TODO properly check what extensions are available
        @static if !Sys.isapple()
            view["GLSL_EXTENSIONS"] = "#extension GL_ARB_conservative_depth: enable"
            view["SUPPORTED_EXTENSIONS"] = "#define DEPTH_LAYOUT"
        end
        args = Dict{Symbol, Any}(kw_args)
        args[:view] = view
        args[:fragdatalocation] = [(0, "fragment_color"), (1, "fragment_groupid")]
        return new(screen, map(x -> loadshader(x), paths), args)
    end
end
function GLVisualizeShader(screen::Screen, path1::String, paths::String...; kw_args...)
    return GLVisualizeShader(screen, String[path1, paths...]; kw_args...)
end

function GLAbstraction.gl_convert(ctx::GLAbstraction.GLContext, shader::GLVisualizeShader, uniforms, buffers)
    return GLAbstraction.gl_convert(ctx, shader.screen.shader_cache, shader, uniforms, buffers)
end

function initialize_renderobject!(screen::Screen, robj::RenderObject, plot::Plot)
    for stage in screen.render_pipeline
        initialize_renderobject!(screen, stage, robj, plot)
    end
    return
end

initialize_renderobject!(screen, stage, robj, plot) = nothing


renders_in_stage(robj, ::GLRenderStage) = false
function renders_in_stage(plot::Plot, stage::RenderPlots)
    ssao = to_value(get(plot.attributes, :ssao, false))::Bool
    transparency = to_value(get(plot.attributes, :transparency, false))::Bool
    fxaa = to_value(get(plot.attributes, :fxaa, false))::Bool

    return compare(ssao, stage.ssao) &&
        compare(transparency, stage.transparency) &&
        compare(fxaa, stage.fxaa)
end

function initialize_renderobject!(screen, stage::RenderPlots, robj, plot)
    renders_in_stage(plot, stage) || return
    name = stage.target
    view = Dict{String, String}()
    if name === :forward_render_objectid
        view["TARGET_STAGE"] = "#define DEFAULT_TARGET"
    elseif name === :forward_render_objectid_geom
        view["TARGET_STAGE"] = "#define SSAO_TARGET"
    elseif name === :forward_render_objectid_oit
        view["TARGET_STAGE"] = "#define OIT_TARGET"
    else
        error("Could not define render outputs.")
    end
    lazy_shader = default_shader(screen, robj, plot, view)::GLVisualizeShader
    pre = get_prerender(plot)
    post = get_postrender(plot)
    add_instructions!(robj, name, lazy_shader, pre = pre, post = post)
    return
end

# TODO: consider splitting RenderPlots stages and dispatch this on them instead
# of using the runtime name?
get_prerender(::Plot) = GLAbstraction.EmptyPrerender()
get_postrender(::Plot) = GLAbstraction.EmptyPostrender()

function reinitialize_renderobjects!(screen::Screen)
    for (_, _, robj) in screen.renderlist
        GLAbstraction.clear_instructions!(robj)
        plot = screen.cache2plot[robj.id]
        initialize_renderobject!(screen, robj, plot)
    end
    return
end

"""
Converts index arrays to the OpenGL equivalent.
"""
to_index_buffer(::GLAbstraction.GLContext, x::GLBuffer) = x
to_index_buffer(::GLAbstraction.GLContext, x::TOrSignal{Int}) = x
to_index_buffer(::GLAbstraction.GLContext, x::VecOrSignal{UnitRange{Int}}) = x
to_index_buffer(::GLAbstraction.GLContext, x::TOrSignal{UnitRange{Int}}) = x
"""
For integers, we transform it to 0 based indices
"""
function to_index_buffer(ctx::GLAbstraction.GLContext, x::AbstractVector{I}) where {I <: Integer}
    return indexbuffer(ctx, Cuint.(x .- 1))
end
function to_index_buffer(ctx::GLAbstraction.GLContext, x::Observable{<:AbstractVector{I}}) where {I <: Integer}
    return indexbuffer(ctx, lift(x -> Cuint.(x .- 1), x))
end

"""
If already GLuint, we assume its 0 based (bad heuristic, should better be solved with some Index type)
"""
function to_index_buffer(ctx::GLAbstraction.GLContext, x::VectorTypes{I}) where {I <: Union{GLuint, LineFace{GLIndex}}}
    return indexbuffer(ctx, x)
end

to_index_buffer(ctx, x) = error(
    "Not a valid index type: $(typeof(x)).
    Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them"
)
