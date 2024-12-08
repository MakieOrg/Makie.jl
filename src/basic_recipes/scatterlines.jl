"""
    scatterlines(xs, ys, [zs]; kwargs...)

Plots `scatter` markers and `lines` between them.
"""
@recipe ScatterLines begin
    "The color of the line, and by default also of the scatter markers."
    color = @inherit linecolor
    "Sets the pattern of the line e.g. `:solid`, `:dot`, `:dashdot`. For custom patterns look at `Linestyle(Number[...])`"
    linestyle = nothing
    "Sets the width of the line in screen units"
    linewidth = @inherit linewidth
    linecap = @inherit linecap
    joinstyle = @inherit joinstyle
    miter_limit = @inherit miter_limit
    markercolor = automatic
    markercolormap = automatic
    markercolorrange = automatic
    "Sets the size of the marker."
    markersize = @inherit markersize
    "Sets the color of the outline around a marker."
    strokecolor = @inherit markerstrokecolor
    "Sets the width of the outline around a marker."
    strokewidth = @inherit markerstrokewidth
    "Sets the scatter marker."
    marker = @inherit marker
    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
    cycle = [:color]
end

conversion_trait(::Type{<: ScatterLines}) = PointBased()


# function plot!(p::Plot{scatterlines, <:NTuple{N, Any}}) where N

#     # markercolor is the same as linecolor if left automatic
#     real_markercolor = Observable{Any}()
#     lift!(p, real_markercolor, p.color, p.markercolor) do col, mcol
#         if mcol === automatic
#             return to_color(col)
#         else
#             return to_color(mcol)
#         end
#     end

#     real_markercolormap = Observable{Any}()
#     lift!(p, real_markercolormap, p.colormap, p.markercolormap) do col, mcol
#         mcol === automatic ? col : mcol
#     end

#     real_markercolorrange = Observable{Any}()
#     lift!(p, real_markercolorrange, p.colorrange, p.markercolorrange) do col, mcol
#         mcol === automatic ? col : mcol
#     end

#     lines!(p, p[1:N]...;
#         color = p.color,
#         linestyle = p.linestyle,
#         linewidth = p.linewidth,
#         linecap = p.linecap,
#         joinstyle = p.joinstyle,
#         miter_limit = p.miter_limit,
#         colormap = p.colormap,
#         colorscale = p.colorscale,
#         colorrange = p.colorrange,
#         inspectable = p.inspectable
#     )
#     scatter!(p, p[1:N]...;
#         color = real_markercolor,
#         strokecolor = p.strokecolor,
#         strokewidth = p.strokewidth,
#         marker = p.marker,
#         markersize = p.markersize,
#         colormap = real_markercolormap,
#         colorscale = p.colorscale,
#         colorrange = real_markercolorrange,
#         inspectable = p.inspectable
#     )
# end


# Recipe test

# TODO: Bad workaround for now
MakieCore.argument_names(::Type{ScatterLines}, N::Integer) = (:positions,)

Base.getindex(plot::ScatterLines, idx::Integer) = plot.args[1][Symbol(:arg, idx)]
function Base.getindex(plot::ScatterLines, idx::UnitRange{<:Integer})
    return ntuple(i -> plot.converted[Symbol(:arg, i)], idx)
end


# Also needs to avoid normal path
plot!(parent::Scene, plot::ScatterLines) = computed_plot!(parent, plot)

function ScatterLines(args::Tuple, user_kw::Dict{Symbol,Any})
    if !isempty(args) && first(args) isa Attributes
        attr = attributes(first(args))
        merge!(user_kw, attr)
        return ScatterLines(Base.tail(args), user_kw)
    end
    attr = ComputeGraph()
    # no conversions!
    add_attributes!(ScatterLines, attr, user_kw)

    # TODO:
    # We want to do dim converts and convert_arguments
    # for boundingbox also apply_transform(, model) but that wouldn't propagate
    register_arguments!(ScatterLines, attr, user_kw, args...)

    # TODO: How do we do this generically?
    T = typeof(attr[:positions][])
    p = Plot{scatterlines,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])

    add_input!(attr, :clip_planes, Plane3f[])
    p.transformation = Transformation()
    return p
end

function plot!(p::Plot{scatterlines, <:NTuple{N, Any}}) where N
    attr = p.args[1]

    # markercolor is the same as linecolor if left automatic
    register_computation!(attr,
            [:color, :markercolor],
            [:real_markercolor]
        ) do (color, markercolor), changed, last

        return (to_color(markercolor[] === automatic ? color[] : markercolor[]),)
    end

    register_computation!(attr,
            [:colormap, :markercolormap],
            [:real_markercolormap]
        ) do (colormap, markercolormap), changed, last

        return (markercolormap[] === automatic ? colormap[] : markercolormap[],)
    end

    register_computation!(attr,
            [:colorrange, :markercolorrange],
            [:real_markercolorrange]
        ) do (colorrange, markercolorrange), changed, last

        return (markercolorrange[] === automatic ? colorrange[] : markercolorrange[],)
    end

    lines!(p,         attr.outputs[:positions];
        color       = attr.outputs[:color],
        linestyle   = attr.outputs[:linestyle],
        linewidth   = attr.outputs[:linewidth],
        linecap     = attr.outputs[:linecap],
        joinstyle   = attr.outputs[:joinstyle],
        miter_limit = attr.outputs[:miter_limit],
        colormap    = attr.outputs[:colormap],
        colorscale  = attr.outputs[:colorscale],
        colorrange  = attr.outputs[:colorrange],
        inspectable = attr.outputs[:inspectable],
        clip_planes = attr.outputs[:clip_planes],
    )
    scatter!(p,       attr.outputs[:positions];
        color       = attr.outputs[:real_markercolor],
        strokecolor = attr.outputs[:strokecolor],
        strokewidth = attr.outputs[:strokewidth],
        marker      = attr.outputs[:marker],
        markersize  = attr.outputs[:markersize],
        colormap    = attr.outputs[:real_markercolormap],
        colorscale  = attr.outputs[:colorscale],
        colorrange  = attr.outputs[:real_markercolorrange],
        inspectable = attr.outputs[:inspectable],
        clip_planes = attr.outputs[:clip_planes],
    )
end
