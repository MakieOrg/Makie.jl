function xlims! end
function ylims! end
function zlims! end

"""
    xlabel!(scene, xlabel)

Set the x-axis label for the given Scene.
"""
function xlabel!(scene, xlabel::AbstractString)
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    scene[OldAxis][:names][:axisnames][] = (xlabel, scene[OldAxis][:names][:axisnames][][2:end]...)
    return nothing
end

"""
    ylabel!(scene, ylabel)

Set the y-axis label for the given Scene.
"""
function ylabel!(scene, ylabel::AbstractString)
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    if axis isa Axis3D
        scene[OldAxis][:names][:axisnames][] = (scene[OldAxis][:names][:axisnames][][1], ylabel, scene[OldAxis][:names][:axisnames][][3])
    else
        @error("Unknown axis type $(typeof(axis)).")
    end
    return nothing
end

"""
    zlabel!(scene, zlabel)

Set the z-axis label for the given Scene.

!!! warning
    The Scene must have an Axis3D.  If not, then this function will error.
"""
function zlabel!(scene, zlabel::AbstractString)
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    @assert axis isa Axis3D "The scene does not have a z-axis"
    scene[OldAxis][:names][:axisnames][] = (scene[OldAxis][:names][:axisnames][][1], scene[OldAxis][:names][:axisnames][][2], zlabel)
    return
end

################################################################################
"""
    ticklabels(scene)

Returns all the axis tick labels.
"""
function ticklabels(scene)
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    return axis.ticks.ranges_labels[][2]
end

"""
    xticklabels(scene)

Returns all the x-axis tick labels. See also `ticklabels`.
"""
xticklabels(scene) = ticklabels(scene)[1]

"""
    yticklabels(scene)

Returns all the y-axis tick labels. See also `ticklabels`.
"""
yticklabels(scene) = ticklabels(scene)[2]

"""
    zticklabels(scene)

Returns all the z-axis tick labels. See also `ticklabels`.
"""
function zticklabels(scene)
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    return ticklabels(scene)[3]
end

"""
    tickranges(scene)

Returns the tick ranges along all axes.
"""
function tickranges(scene)
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    return scene[OldAxis].ticks.ranges_labels[][1]
end

"""
    xtickrange(scene)

Returns the tick range along the x-axis. See also `tickranges`.
"""
xtickrange(scene) = tickranges(scene)[1]

"""
    ytickrange(scene)

Returns the tick range along the y-axis. See also `tickranges`.
"""
ytickrange(scene) = tickranges(scene)[2]

"""
    ztickrange(scene)

Returns the tick range along the z-axis. See also `tickranges`.
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
function ticks!(scene::Scene; tickranges = tickranges(scene), ticklabels = ticklabels(scene))
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    # Have to set `ranges_labels` first so that any changes in the length of these
    # is reflected there first.
    axis.ticks.ranges_labels[] = (tickranges, ticklabels)
    axis.ticks.ranges[] = tickranges
    axis.ticks.labels[] = ticklabels
    return nothing
end

"""
    xticks!([scene,]; xtickrange=xtickrange(scene), xticklabels=xticklabel(scene))

Set the tick labels and range along the x-axis. See also `ticks!`.
"""
function xticks!(scene::Scene; xtickrange = xtickrange(scene), xticklabels = xticklabels(scene))
    ticks!(scene, tickranges = (xtickrange, tickranges(scene)[2:end]...), ticklabels = (xticklabels, ticklabels(scene)[2:end]...))
    return nothing
end

"""
    yticks!([scene,]; ytickrange=ytickrange(scene), yticklabels=yticklabel(scene))

Set the tick labels and range along all the y-axis. See also `ticks!`.
"""
function yticks!(scene::Scene; ytickrange = ytickrange(scene), yticklabels = yticklabels(scene))
    r = tickranges(scene)
    l = ticklabels(scene)
    if length(r) == 2
        ticks!(scene, tickranges = (first(r), ytickrange), ticklabels = (first(l), yticklabels))
    else  # length(r) == 3
        ticks!(scene, tickranges = (first(r), ytickrange, last(r)), ticklabels = (first(l), yticklabels, last(l)))
    end
    return nothing
end

"""
    zticks!([scene,]; ztickranges=ztickrange(scene), zticklabels=zticklabel(scene))

Set the tick labels and range along all z-axis. See also `ticks!`.
"""
function zticks!(scene::Scene; ztickrange = ztickrange(scene), zticklabels = zticklabels(scene))
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    ticks!(scene, tickranges = (tickranges(scene)[1:2]..., ztickrange), ticklabels = (ticklabels(scene)[1:2]..., zticklabels))
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
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    return axis.ticks.rotation[]
end

"""
    xtickrotation(scene)

Returns the rotation of tick labels along the x-axis. See also `tickrotations`
"""
xtickrotation(scene) = first(tickrotations(scene))

"""
    ytickrotation(scene)

Returns the rotation of tick labels along the y-axis. See also `tickrotations`
"""
ytickrotation(scene) = tickrotations(scene)[2]

"""
    ztickrotation(scene)

Returns the rotation of tick labels along the z-axis. See also `tickrotations`
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
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    scene[OldAxis].ticks.rotation[] = angles
    return nothing
end

"""
    xtickrotation!([scene,] xangle)

Set the rotation of tick labels along the x-axis. See also `tickrotations!`.
"""
function xtickrotation!(scene::Scene, xangle)
    tickrotations!(scene, (xangle, tickrotations(scene)[2:end]...))
    return nothing
end

"""
    ytickrotation!([scene,] yangle)

Set the rotation of tick labels along the y-axis. See also `tickrotations!`.
"""
function ytickrotation!(scene::Scene, yangle)
    return if is2d(scene)
        tickrotations!(scene, (xtickrotation(scene), yangle))
    else  # length(r) == 3
        tickrotations!(scene, (xtickrotation(scene), yangle, ztickrotation(scene)))
    end
end

"""
    ztickrotation!([scene,] zangle)

Set the rotation of tick labels along the z-axis. See also `tickrotations!`.
"""
function ztickrotation!(scene::Scene, zangle)
    @assert !is2d(scene)  "The Scene does not have a z-axis!"
    tickrotations!(scene, (tickrotations(scene)[1:2]..., zangle))
    return nothing
end
