"""
    xlabel!([scene,] xlabel)

Set the x-axis label for the given Scene.
Defaults to using the current Scene.
"""
function xlabel!(scene, xlabel::AbstractString)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    scene[Axis][:names][:axisnames][] = (xlabel, scene[Axis][:names][:axisnames][][2:end]...)
    nothing
end
xlabel!(xlabel::AbstractString) = xlabel!(current_scene(), xlabel)

"""
    ylabel!([scene,] ylabel)

Set the y-axis label for the given Scene.
Defaults to using the current Scene.
"""
function ylabel!(scene, ylabel::AbstractString)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    if axis isa Axis2D
        scene[Axis][:names][:axisnames][] = (scene[Axis][:names][:axisnames][][1], ylabel)
    elseif axis isa Axis3D
        scene[Axis][:names][:axisnames][] = (scene[Axis][:names][:axisnames][][1], ylabel, scene[Axis][:names][:axisnames][][3])
    else
        @error("Unknown axis type $(typeof(axis)).")
    end
    nothing
end
ylabel!(ylabel::AbstractString) = xlabel!(current_scene(), ylabel)

"""
    zlabel!([scene,] zlabel)

Set the z-axis label for the given Scene.
Defaults to using the current Scene.
!!! warning
    The Scene must have an Axis3D.  If not, then this function will error.
"""
function zlabel!(scene, zlabel::AbstractString)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    @assert axis isa Axis3D "The scene does not have a z-axis"
    scene[Axis][:names][:axisnames][] = (scene[Axis][:names][:axisnames][][1], scene[Axis][:names][:axisnames][][2], zlabel)
    nothing
end
zlabel!(zlabel::AbstractString) = zlabel!(current_scene(), zlabel)

################################################################################

function setlims!(scene::Scene, lims::NTuple{2, Real}, dim=1)
    ol = scene.limits[]                          # get the Scene's limits as values
    o_origin = ol.origin                         # get the original origin
    o_widths = ol.widths                         # get the original widths
    n_widths = convert(Vector, o_widths)         # convert to mutable form
    n_origin = convert(Vector, o_origin)         # convert to mutable form
    n_origin[dim] = lims[1]                      # set the new origin in dim
    n_widths[dim] = lims[2] - lims[1]            # set the new width in dim
    scene.limits[] = FRect3D(n_origin, n_widths) # set the limits of the scene
    nothing
end

"""
    xlims!(limits::Real...)
    xlims!(limits::NTuple{2, Real})
    xlims!(scene, limits::Real...)
    xlims!(scene, limits::NTuple{2, Real})

Set the x-limits for the given Scene (defaults to current Scene).
"""
xlims!(scene::Scene, lims::NTuple{2, Real}) = setlims!(scene, lims, 1)

"""
    ylims!(limits::Real...)
    ylims!(limits::NTuple{2, Real})
    ylims!(scene, limits::Real...)
    ylims!(scene, limits::NTuple{2, Real})

Set the y-limits for the given Scene (defaults to current Scene).
"""
ylims!(scene::Scene, lims::NTuple{2, Real}) = setlims!(scene, lims, 2)

"""
    zlims!(limits::Real...)
    zlims!(limits::NTuple{2, Real})
    zlims!(scene, limits::Real...)
    zlims!(scene, limits::NTuple{2, Real})

Set the z-limits for the given Scene (defaults to current Scene).
"""
zlims!(scene::Scene, lims::NTuple{2, Real}) = setlims!(scene, lims, 3)

xlims!(scene::Scene, lims::Real...) = xlims!(current_scene(), lims)
ylims!(scene::Scene, lims::Real...) = ylims!(current_scene(), lims)
zlims!(scene::Scene, lims::Real...) = zlims!(current_scene(), lims)

xlims!(lims::NTuple{2, Real}) = xlims!(current_scene(), lims)
ylims!(lims::NTuple{2, Real}) = ylims!(current_scene(), lims)
zlims!(lims::NTuple{2, Real}) = zlims!(current_scene(), lims)

xlims!(lims::Real...) = xlims!(current_scene(), lims)
ylims!(lims::Real...) = ylims!(current_scene(), lims)
zlims!(lims::Real...) = zlims!(current_scene(), lims)
################################################################################
"""
    ticklabels(scene)

Returns the all the axis tick labels.
"""
function ticklabels(scene)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    return axis.ticks.ranges_labels[][2]
end

"""
    xticklabels(scene)

Returns the all the x-axis tick labels. See also [`ticklabels`](@ref).
"""
xticklabels(scene) = ticklabels(scene)[1]

"""
    yticklabels(scene)

Returns the all the y-axis tick labels. See also [`ticklabels`](@ref).
"""
yticklabels(scene) = ticklabels(scene)[2]

"""
    zticklabels(scene)

Returns the all the z-axis tick labels. See also [`ticklabels`](@ref).
"""
function zticklabels(scene)
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    ticklabels(scene)[3]
end

"""
    tickranges(scene)

Returns the tick ranges along all axes.
"""
function tickranges(scene)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    scene[Axis].ticks.ranges_labels[][1]
end

"""
    xtickrange(scene)

Returns the tick range along the x-axis. See also [`tickranges`](@ref).
"""
xtickrange(scene) = tickranges(scene)[1]

"""
    ytickrange(scene)

Returns the tick range along the y-axis. See also [`tickranges`](@ref).
"""
ytickrange(scene) = tickranges(scene)[2]

"""
    ztickrange(scene)

Returns the tick range along the z-axis. See also [`tickranges`](@ref).
"""
function ztickrange(scene)
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    return tickranges(scene)[3]
end

"""
    ticks!([scene,]; tickranges=tickranges(scene), ticklabels=ticklabels(scene))

Set the tick labels and ranges along all axes. The respective labels and ranges
along each axis must be of the same length.
"""
function ticks!(scene=current_scene(); tickranges=tickranges(scene), ticklabels=ticklabels(scene))
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    # Have to set `ranges_labels` first so that any changes in the length of these
    # is reflected there first.
    axis.ticks.ranges_labels[] = (tickranges, ticklabels)
    axis.ticks.ranges[] = tickranges
    axis.ticks.labels[] = ticklabels
    return nothing
end

"""
    xticks!([scene,]; xtickranges=xtickrange(scene), xticklabels=xticklabel(scene))

Set the tick labels and range along the x-axes. See also [`ticks!`](@ref).
"""
function xticks!(scene=current_scene(); xtickrange=xtickrange(scene), xticklabels=xticklabels(scene))
    ticks!(scene, tickranges=(xtickrange, tickranges(scene)[2:end]...), ticklabels=(xticklabels, ticklabels(scene)[2:end]...))
    return nothing
end

"""
    yticks!([scene,]; ytickranges=ytickrange(scene), yticklabels=yticklabel(scene))

Set the tick labels and range along all the y-axis. See also [`ticks!`](@ref).
"""
function yticks!(scene=current_scene(); ytickrange=ytickrange(scene), yticklabels=yticklabels(scene))
    r = tickranges(scene)
    l = ticklabels(scene)
    if length(r) == 2
        ticks!(scene, tickranges=(first(r), ytickrange), ticklabels=(first(l), yticklabels))
    else  # length(r) == 3
        ticks!(scene, tickranges=(first(r), ytickrange, last(r)), ticklabels =(first(l), yticklabels, last(l)))
    end
    return nothing
end

"""
    zticks!([scene,]; ztickranges=ztickrange(scene), zticklabels=zticklabel(scene))

Set the tick labels and range along all z-axis. See also [`ticks!`](@ref).
"""
function zticks!(scene=current_scene(); ztickrange=ztickrange(scene), zticklabels=zticklabels(scene))
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    ticks!(scene, tickranges=(tickranges(scene)[1:2]..., ztickrange), ticklabels=(ticklabels(scene)[1:2]..., zticklabels))
    return nothing
end

###
### Ticks rotations
###
"""
    tickrotations(scene)

Returns the rotation of all tick labels.
"""
function tickrotations(scene)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    return axis.ticks.rotation[]
end

"""
    xtickrotation(scene)

Returns the rotation of tick labels along the x-axis. See also [`tickrotations`](@ref)
"""
xtickrotation(scene) = first(tickrotations(scene))

"""
    ytickrotation(scene)

Returns the rotation of tick labels along the y-axis. See also [`tickrotations`](@ref)
"""
ytickrotation(scene) = tickrotations(scene)[2]

"""
    ztickrotation(scene)

Returns the rotation of tick labels along the z-axis. See also [`tickrotations`](@ref)
"""
function ztickrotation(scene)
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    return tickrotations(scene)[3]
end

"""
    xtickrotation!([scene,] zangle)

Set the rotation of all tick labels.
"""
function tickrotations!(scene::Scene, angles)
    axis = scene[Axis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    scene[Axis].ticks.rotation[] = angles
    return nothing
end

"""
    xtickrotation!([scene,] xangle)

Set the rotation of tick labels along the x-axis. See also [`tickrotations!`](@ref).
"""
function xtickrotation!(scene::Scene, xangle)
    tickrotations!(scene, (xangle, tickrotations(scene)[2:end]...))
    return nothing
end
xtickrotation!(xangle) = xtickrotation!(current_scene(), xangle)

"""
    ytickrotation!([scene,] yangle)

Set the rotation of tick labels along the y-axis. See also [`tickrotations!`](@ref).
"""
function ytickrotation!(scene::Scene, yangle)
    if is2d(scene)
        tickrotations!(scene, (xtickrotation(scene), yangle))
    else  # length(r) == 3
        tickrotations!(scene, (xtickrotation(scene), yangle, ztickrotation(scene)))
    end
end
ytickrotation!(yangle) = ytickrotation!(current_scene(), yangle)

"""
    ztickrotation!([scene,] zangle)

Set the rotation of tick labels along the z-axis. See also [`tickrotations!`](@ref).
"""
function ztickrotation!(scene::Scene, zangle)
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    tickrotations!(scene, (tickrotations(scene)[1:2]..., zangle))
    return nothing
end
ztickrotation!(zangle) = ztickrotation!(current_scene(), zangle)
