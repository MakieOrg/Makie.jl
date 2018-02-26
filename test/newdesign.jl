using Reactive, GeometryTypes, Colors

abstract type AbstractPlot end
const Attributes = Dict{Symbol, Any}

struct Scene
    view::Signal{Mat4f0}
    projection::Signal{Mat4f0}
    resolution::Signal{Vec2f0}
    eyeposition::Signal{Vec3f0}

    limits::Signal{HyperRectangle{3, Float32}}
    scale::Signal{Vec3f0}
    flip::Signal{NTuple{3, Bool}}

    plots::Vector{<: AbstractPlot}
    theme::Attributes
    children::Vector{Scene}
end


Scene() = Scene(
    Signal(eye(Mat4f0)),
    Signal(eye(Mat4f0)),
    Signal(Vec2f0(1)),
    Signal(Vec3f0(1)),

    Signal(AABB(Vec3f0(0), Vec3f0(1))),
    Signal(Vec3f0(1)),
    Signal((false, false, false)),
    AbstractPlot[],
    Attributes(),
    Scene[]
)

struct Scatter{T} <: AbstractPlot
    args::T
    attributes::Attributes
end
struct Billboard end

function merged_get!(defaults, key, scene, input::Attributes)
    theme = get!(defaults, scene.theme, key)
    rest = Attributes()
    merged = Attributes()

    for key in union(keys(input), keys(theme))
        if haskey(input, key) && haskey(theme, key)
            merged[key] = input[key]
        elseif haskey(input, key)
            rest[key] = input[key]
        else # haskey(theme) must be true!
            merged[key] = theme[key]
        end
    end
    merged, rest
end

scatter(args...; kw_args...) = plot(Scatter, args...; kw_args...)
scatter!(args...; kw_args...) = plot!(Scatter, args...; kw_args...)
Theme(; kw_args...) = Attributes(kw_args)

function plot(scene::Scene, ::Type{Scatter}, attributes::Attributes, positions::AbstractVector{<: Point})
    #cmap_or_color!(scene, attributes)
    scatter_attributes, rest = merged_get!(:scatter, scene, attributes) do
        Theme(
            marker = Circle,
            markersize = 0.1,
            strokecolor = RGBA(0, 0, 0, 0),
            strokewidth = 0.0,
            glowcolor = RGBA(0, 0, 0, 0),
            glowwidth = 0.0,
            rotations = Billboard()
        )
    end
    #plot(scene, Scatter(positions, attributes), rest)
    Scatter(positions, scatter_attributes)
end
const RealVector{T} = AbstractVector{T} where T <: Number

convert_arguments(y::RealVector) = convert_arguments(0:length(y), y)
convert_arguments(x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)

plot(args...; kw_args...) = plot(Scatter, args...; kw_args...)
plot(P::Type, args...; kw_args...) = plot(P, Attributes(kw_args), args...)
plot(P::Type, attributes::Attributes, args...) = plot(Scene(), P, attributes, args...)

function plot(scene::Scene, P::Type, attributes::Attributes, args...)
    plot(scene, P, attributes, convert_arguments(args...)...)
end



function data_limits(x::Scatter{<: AbstractArray{Point{N, T}}}) where {N, T}
    map(x.args) do points
        Tuple.(extrema(points))
    end
end

function to_glvisualize_key(k)
    k == :rotations && return :rotation
    k == :markersize && return :scale
    k == :glowwidth && return :glow_width
    k == :glowcolor && return :glow_color
    k == :strokewidth && return :stroke_width
    k == :strokecolor && return :stroke_color
    k == :positions && return :position
    k
end


struct Key{K} end
macro key_str(arg)
    :(Key{$(QuoteNode(Symbol(arg)))})
end

attribute_convert(x, key::Key, ::Key) = attribute_convert(x, key)
attribute_convert(s::Scene, x, key::Key, ::Key) = attribute_convert(s, x, key)
attribute_convert(s::Scene, x, key::Key) = attribute_convert(x, key)
attribute_convert(x, key::Key) = x

attribute_convert(c::Colorant, ::key"color") = RGBA{Float32}(c)
attribute_convert(c::Symbol, ::key"color") = to_color(b, string(c))
attribute_convert(c::String, ::key"color") = parse(RGBA{Float32}, c)
attribute_convert(c::Union{Tuple, AbstractArray}, k::key"color") = attribute_convert.(c, k)
function attribute_convert(c::Tuple{T, F}, k::key"color") where {T, F <: Number}
    col = attribute_convert(c[1], k)
    RGBAf0(Colors.color(col), c[2])
end
attribute_convert(c::Billboard, ::key"rotations") = Vec4f0(0, 0, 0, 1)
attribute_convert(c, ::key"markersize", ::key"scatter") = Vec2f0(c)
attribute_convert(c, ::key"glowcolor") = attribute_convert(c, key"color"())
attribute_convert(c, ::key"strokecolor") = attribute_convert(c, key"color"())

function popkey!(dict::Dict, key)
    val = dict[key]
    delete!(dict, key)
    val
end

using GLAbstraction, GLWindow, GLVisualize
struct Screen
    glscreen::GLWindow.Screen
    cache::Dict{UInt64, RenderObject}
end

function Base.insert!(screen::Screen, x::Scatter, scene)
    robj = get!(screen.cache, object_id(x)) do
        gl_attributes = map(x.attributes) do key_value
            key, value = key_value
            gl_key = to_glvisualize_key(key)
            gl_value = attribute_convert(value, Key{key}(), Key{:scatter}())
            gl_key => gl_value
        end
        marker = popkey!(gl_attributes, :marker)
        robj = visualize((marker, x.args), Style(:default), gl_attributes).children[]
        for key in (:view, :projection, :resolution, :eyeposition)
            robj[key] = getfield(scene, key)
        end
        robj
    end
    push!(screen.glscreen, robj)
    return robj
end

screen = Screen(GLVisualize.glscreen(), Dict{UInt64, RenderObject}())
@async renderloop(screen.glscreen)

mouseinside = screen.glscreen.inputs[:mouseinside]
ishidden = screen.glscreen.hidden
keep = map((a, b) -> !a && b, ishidden, mouseinside)
real_camera = OrthographicPixelCamera(screen.glscreen.inputs, keep = keep)
cam = real_camera
scene = Scene(
    cam.view,
    cam.projection,
    map(a-> Vec2f0(widths(a)), screen.glscreen.area),
    cam.eyeposition,

    Signal(AABB(Vec3f0(0), Vec3f0(1))),
    Signal(Vec3f0(1)),
    Signal((false, false, false)),
    AbstractPlot[],
    Attributes(),
    Scene[]
)
lolo = scatter(rand(10), rand(10))
loli = insert!(screen, lolo, scene)
GLAbstraction.center!(cam, [loli])

function plot(scene::Scene, p::AbstractPlot, attributes::Attributes)
    plot_attributes, rest = merged_get!(:plot, scene, attributes) do
        Attributes(
            show_axis = true,
            show_legend = true,
            scale_plot = true,
            center = true,
            axis = Attributes(),
            legend = Attributes(),
            scale = Vec3f0(1)
        )
    end
    if !isempty(rest) # at this point, there should be no attributes left.
        warn("The following attributes are unused: $(sprint(display, rest))")
    end
    limits = data_limits(p)
    if to_value(plot_attributes, :scale_plot)
        scale = lift_node(window_area(scene), limits) do rect, limits
            xyzfit = Makie.fit_ratio(rect, limits)
            to_ndim(Vec3f0, xyzfit, 1f0)
        end
        p[:scale] = scale
    end
    if to_value(plot_attributes, :show_axis)
        axis_attributes = plot_attributes[:axis]
        axis_attributes[:scale] = scale
        axis(scene, limits, axis_attributes)
    end

    if to_value(plot_attributes, :show_legend)
        legend_attributes = plot_attributes[:legend]
        legend_attributes[:scale] = scale
        legend(scene, limits, legend_attributes)
    end
    Series(Scene, p, plot_attributes)
end
