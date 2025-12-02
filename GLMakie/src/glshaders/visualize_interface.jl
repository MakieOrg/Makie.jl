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

function assemble_shader(data)
    shader = data[:shader]::GLVisualizeShader
    delete!(data, :shader)
    primitive = get(data, :gl_primitive, GL_TRIANGLES)
    pre_fun = get(data, :prerender, nothing)
    post_fun = get(data, :postrender, nothing)

    transp = get(data, :transparency, Observable(false))
    overdraw = get(data, :overdraw, Observable(false))

    pre = if !isnothing(pre_fun)
        _pre_fun = GLAbstraction.StandardPrerender(transp, overdraw)
        () -> (_pre_fun(); pre_fun())
    else
        GLAbstraction.StandardPrerender(transp, overdraw)
    end

    robj = RenderObject(data, shader, pre, nothing, shader.screen.glscreen)

    post = if haskey(data, :instances)
        GLAbstraction.StandardPostrenderInstanced(pop!(data, :instances), robj.vertexarray, primitive)
    else
        GLAbstraction.StandardPostrender(robj.vertexarray, primitive)
    end

    robj.postrenderfunction = if !isnothing(post_fun)
        () -> (post(); post_fun())
    else
        post
    end
    return robj
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

function output_buffers(screen::Screen, transparency = false)
    return if transparency
        """
        layout(location=2) out float coverage;
        """
    elseif screen.config.ssao
        """
        layout(location=2) out vec3 fragment_position;
        layout(location=3) out vec3 fragment_normal_occlusion;
        """
    else
        ""
    end
end

function output_buffer_writes(screen::Screen, transparency = false)
    return if transparency
        scale = screen.config.transparency_weight_scale
        """
        float weight = color.a * max(0.01, $scale * pow((1 - gl_FragCoord.z), 3));
        coverage = 1.0 - clamp(color.a, 0.0, 1.0);
        fragment_color.rgb = weight * color.rgb;
        fragment_color.a = weight;
        """
    elseif screen.config.ssao
        """
        fragment_color = color;
        fragment_position = o_view_pos;
        fragment_normal_occlusion.xyz = o_view_normal;
        """
    else
        "fragment_color = color;"
    end
end
