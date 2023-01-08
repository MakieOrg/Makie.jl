function Makie.plot!(
        lscene::LScene, P::Makie.PlotFunc,
        attributes::Makie.Attributes, args...;
        kw_attributes...)

    plot = Makie.plot!(lscene.scene, P, attributes, args...; kw_attributes...)
    notify(lscene.scene.theme.limits)
    center!(lscene.scene)
    plot
end

function Makie.plot!(P::Makie.PlotFunc, ls::LScene, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    _disallow_keyword(:axis, attributes)
    _disallow_keyword(:figure, attributes)
    Makie.plot!(ls, P, attributes, args...)
end

function initialize_block!(ls::LScene; scenekw = NamedTuple())
    blockscene = ls.blockscene
    # pick a camera and draw axis.
    scenekw = merge((clear = false, camera=cam3d!), scenekw)
    ls.scene = Scene(blockscene, lift(round_to_IRect2D, ls.layoutobservables.computedbbox); scenekw...)

    on(ls.show_axis) do show_axis
        ax = ls.scene[OldAxis]
        if show_axis
            if isnothing(ax)
                # Add axis on first plot!, if requested
                # update limits when scene limits change
                limits = lift(ls.scene.theme.limits) do lims
                    out = if lims === automatic
                        dl = data_limits(ls.scene, p -> Makie.isaxis(p) || Makie.not_in_data_space(p))
                        if any(isinf, widths(dl)) || any(isinf, Makie.origin(dl))
                            Rect3((0.0, 0.0, 0.0), (1.0, 1.0, 1.0))
                        else
                            dl
                        end
                    else
                        lims
                    end
                    Rect3{Float64}(out)
                end
                Makie.axis3d!(ls.scene, limits)
                # Make sure axis is always in pos 1
                sort!(ls.scene.plots, by=!Makie.isaxis)
            else
                ax.visible = true
            end
        else
            if !isnothing(ax)
                ax.visible = false
            end
        end
    end
    notify(ls.show_axis)
    return
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
