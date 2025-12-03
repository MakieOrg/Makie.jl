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
    paths::Tuple
    kw_args::Dict{Symbol, Any}
    function GLVisualizeShader(
            screen::Screen, paths::String...;
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

function GLAbstraction.gl_convert(ctx::GLAbstraction.GLContext, shader::GLVisualizeShader, data)
    return GLAbstraction.gl_convert(ctx, shader.screen.shader_cache, shader, data)
end

function initialize_renderobject!(screen::Screen, robj::RenderObject, plot::Plot)
    for stage in screen.render_pipeline
        initialize_renderobject!(screen, stage, robj, plot)
    end
end

initialize_renderobject!(screen, stage, robj, plot) = nothing


renders_in_stage(robj, ::GLRenderStage) = false
function renders_in_stage(plot::Plot, stage::RenderPlots)
    return compare(to_value(get(plot.attributes, :ssao, false)), stage.ssao) &&
        compare(to_value(get(plot.attributes, :transparency, false)), stage.transparency) &&
        compare(to_value(get(plot.attributes, :fxaa, false)), stage.fxaa)
end

function initialize_renderobject!(screen, stage::RenderPlots, robj, plot)
    renders_in_stage(plot, stage) || return
    name = stage.target
    if name === :forward_render_objectid
        kwargs = ("TARGET_STAGE" => "#define DEFAULT_TARGET",)
    elseif name === :forward_render_objectid_geom
        kwargs = ("TARGET_STAGE" => "#define SSAO_TARGET",)
    elseif name === :forward_render_objectid_oit
        kwargs = ("TARGET_STAGE" => "#define OIT_TARGET",)
    else
        error("Could not define render outputs.")
    end
    default_setup!(screen, robj, plot, name, kwargs)
    return
end

function get_default_prerender(plot, name::Symbol)
    if name === :forward_render_objectid_oit
        return OITPrerender(plot)
    else
        return StandardPrerender(plot)
    end
end

function default_setup!(screen, robj, plot, name, kwargs)
    program_like = default_shader(screen, robj, plot, kwargs)
    pre = get_default_prerender(plot, name)
    add_instructions!(robj, name, program_like, pre = pre)
    return
end

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

# TODO: What's a good place for these?

"""
Represents standard sets of function applied before rendering
"""
struct StandardPrerender
    overdraw::Bool
end

function StandardPrerender(plot::Plot)
    return StandardPrerender(to_value(get(plot.attributes, :overdraw, false)))
end

function enabletransparency()
    glDisable(GL_BLEND)
    glEnablei(GL_BLEND, 0)
    # This does:
    # target.rgb = source.a * source.rgb + (1 - source.a) * target.rgb
    # target.a = 0 * source.a + 1 * target.a
    # the latter is required to keep target.a = 1 for the OIT pass
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ZERO, GL_ONE)
    return
end

function handle_overdraw(overdraw)
    if overdraw
        # Disable depth testing if overdrawing
        glDisable(GL_DEPTH_TEST)
    else
        glEnable(GL_DEPTH_TEST)
        glDepthFunc(GL_LEQUAL)
    end
    return
end

function (sp::StandardPrerender)()
    glDepthMask(GL_TRUE)
    enabletransparency()

    handle_overdraw(sp.overdraw)

    # Disable cullface for now, until all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)

    return
end

struct OITPrerender
    overdraw::Bool
end

function OITPrerender(plot::Plot)
    return OITPrerender(to_value(get(plot.attributes, :overdraw, false)))
end

function (pre::OITPrerender)()
    # disable depth buffer writing
    glDepthMask(GL_FALSE)

    # Blending
    glEnable(GL_BLEND)
    glBlendEquation(GL_FUNC_ADD)

    # buffer 0 contains weight * color.rgba, should do sum
    # destination <- 1 * source + 1 * destination
    glBlendFunci(0, GL_ONE, GL_ONE)

    # buffer 1 is objectid, do nothing
    glDisablei(GL_BLEND, 1)

    # buffer 2 is color.a, should do product
    # destination <- 0 * source + (source) * destination
    glBlendFunci(2, GL_ZERO, GL_SRC_COLOR)

    handle_overdraw(pre.overdraw)

    # Disable cullface for now, until all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)

    return
end