function Makie.plot!(
        lscene::LScene, P::Makie.PlotFunc,
        attributes::Makie.Attributes, args...;
        kw_attributes...)
    # We store the show_axis attribute in the LScene
    if haskey(attributes, :show_axis)
        lscene.attributes[:show_axis] = pop!(attributes, :show_axis)
    end

    if haskey(attributes, :limits)
        lscene.attributes[:limits] = pop!(attributes, :limits)
    end

    show_axis = get!(lscene.attributes, :show_axis, true)
    plot = Makie.plot!(lscene.scene, P, attributes, args...; kw_attributes...)

    function get_lims()
        return get(lscene.attributes, :limits) do
            return data_limits(lscene.scene, p -> Makie.isaxis(p) || Makie.not_in_data_space(p))
        end
    end

    if isnothing(lscene.scene[OldAxis])
        # Add axis on first plot!, if requested
        to_value(show_axis) && Makie.axis3d!(lscene.scene, get_lims())
    else
        # Update limits when plotting new objects
        axis_plot = lscene.scene[OldAxis]
        axis_plot[1] = get_lims()
    end
    # Make sure axis is always in pos 1
    sort!(lscene.scene.plots, by=!Makie.isaxis)
    center!(lscene.scene)
    plot
end

function Makie.plot!(P::Makie.PlotFunc, ls::LScene, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    Makie.plot!(ls, P, attributes, args...)
end

function block(::Type{LScene}, fig_or_scene; bbox = nothing, scenekw = NamedTuple(), kwargs...)

    topscene = get_topscene(fig_or_scene)
    default_attrs = default_attributes(LScene, topscene).attributes
    theme_attrs = subtheme(topscene, :LScene)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)
    layoutobservables = LayoutObservables(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        attrs.halign, attrs.valign, attrs.alignmode; suggestedbbox = bbox)
    # pick a camera and draw axis.
    scenekw = merge((clear = false, camera=cam3d!), scenekw)
    scene = Scene(topscene, lift(round_to_IRect2D, layoutobservables.computedbbox); scenekw...)
    return LScene(fig_or_scene, layoutobservables, attrs, Dict{Symbol, Any}(), scene)
end

function Base.delete!(ax::LScene, plot::AbstractPlot)
    delete!(ax.scene, plot)
    ax
end

can_be_current_axis(ls::LScene) = true

Makie.cam2d!(ax::LScene; kwargs...) = Makie.cam2d!(ax.scene; kwargs...)
Makie.campixel!(ax::LScene; kwargs...) = Makie.campixel!(ax.scene; kwargs...)
Makie.cam_relative!(ax::LScene; kwargs...) = Makie.cam_relative!(ax.scene; kwargs...)
Makie.cam3d!(ax::LScene; kwargs...) = Makie.cam3d!(ax.scene; kwargs...)
Makie.cam3d_cad!(ax::LScene; kwargs...) = Makie.cam3d_cad!(ax.scene; kwargs...)
Makie.old_cam3d!(ax::LScene; kwargs...) = Makie.old_cam3d!(ax.scene; kwargs...)
Makie.old_cam3d_cad!(ax::LScene; kwargs...) = Makie.old_cam3d_cad!(ax.scene; kwargs...)