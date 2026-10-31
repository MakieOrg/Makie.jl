function reset_limits!(lscene::LScene)
    notify(lscene.scene.theme.limits)
    center!(lscene.scene)
    return
end
tightlimits!(::LScene) = nothing # TODO implement!?

function initialize_block!(ls::LScene; scenekw = NamedTuple())
    blockscene = ls.blockscene
    # pick a camera and draw axis.
    scenekw = merge((clear = false, camera = cam3d!), scenekw)
    ls.scene = Scene(blockscene, lift(round_to_IRect2D, blockscene, ls.layoutobservables.computedbbox); visible = false, scenekw...)

    on(blockscene, ls.show_axis) do show_axis
        ax = ls.scene[OldAxis]
        if show_axis
            if isnothing(ax)
                # Add axis on first plot!, if requested
                # update limits when scene limits change
                limits = lift(blockscene, ls.scene.theme.limits) do lims
                    if lims === automatic
                        dl = boundingbox(ls.scene, p -> isaxis(p) || not_in_data_space(p))
                        if any(!isfinite, origin(dl)) || any(!isfinite, widths(dl))
                            return Rect3d((0.0, 0.0, 0.0), (1.0, 1.0, 1.0))
                        elseif any(iszero, widths(dl))
                            _mini = minimum(dl)
                            _maxi = maximum(dl)
                            w = 0.2 * sum(widths(dl)) # bit more than mean(widths) / 2
                            w = ifelse(w == 0, 1.0, w)
                            mini = @. ifelse(_mini == _maxi, _mini - w, _mini)
                            maxi = @. ifelse(_mini == _maxi, _maxi + w, _maxi)
                            return Rect3d(mini, maxi .- mini)
                        else
                            return dl
                        end
                    else
                        return lims
                    end
                end
                axis3d!(ls.scene, limits)
                # Make sure axis is always in pos 1
                sort!(ls.scene.plots, by = !isaxis)
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
    return ax
end

cam2d!(ax::LScene; kwargs...) = cam2d!(ax.scene; kwargs...)
campixel!(ax::LScene; kwargs...) = campixel!(ax.scene; kwargs...)
cam_relative!(ax::LScene; kwargs...) = cam_relative!(ax.scene; kwargs...)
cam3d!(ax::LScene; kwargs...) = cam3d!(ax.scene; kwargs...)
cam3d_cad!(ax::LScene; kwargs...) = cam3d_cad!(ax.scene; kwargs...)
old_cam3d!(ax::LScene; kwargs...) = old_cam3d!(ax.scene; kwargs...)
old_cam3d_cad!(ax::LScene; kwargs...) = old_cam3d_cad!(ax.scene; kwargs...)
