

function xlims! end
function ylims! end
function zlims! end

"""
    xlabel!([axis,] xlabel)

Set the x-axis label for the given Axis.
Defaults to using the current Axis.
"""
function xlabel!(axis::Axis, xlabel::AbstractString)
    axis.xlabel = xlabel
end

xlabel(figure::Figure, xlabel::AbstractString) = xlabel!(current_axis(figure), xlabel)
xlabel(xlabel::AbstractString) = xlabel!(current_axis(), xlabel)

"""
    ylabel!([axis,] ylabel)

Set the y-axis label for the given Axis.
Defaults to using the current Axis.
"""
function ylabel!(axis::Axis, ylabel::AbstractString)
    axis.ylabel = ylabel
end

ylabel(figure::Figure, ylabel::AbstractString) = ylabel!(current_axis(figure), ylabel)
ylabel(ylabel::AbstractString) = ylabel!(current_axis(), ylabel)

"""
    zlabel!([axis,] zlabel)

Set the z-axis label for the given Axis.
Defaults to using the current Axis.
!!! warning
    The Scene must have an Axis3D.  If not, then this function will error.
"""
function zlabel!(axis::Axis, zlabel::AbstractString)
    @assert axis isa Axis3D "The scene does not have a z-axis!"
    axis.zlabel = zlabel
    return
end

zlabel(figure::Figure, zlabel::AbstractString) = zlabel!(current_axis(figure), zlabel)
zlabel(zlabel::AbstractString) = zlabel!(current_axis(), zlabel)

################################################################################
"""
    ticklabels(scene)

Returns the all the axis tick labels.
"""
function ticklabels(scene)
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    return axis.ticks.ranges_labels[][2]
end

"""
    xticklabels(scene)

Returns the all the x-axis tick labels. See also `ticklabels`.
"""
xticklabels(scene) = ticklabels(scene)[1]

"""
    yticklabels(scene)

Returns the all the y-axis tick labels. See also `ticklabels`.
"""
yticklabels(scene) = ticklabels(scene)[2]

"""
    zticklabels(scene)

Returns the all the z-axis tick labels. See also `ticklabels`.
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
    axis = scene[OldAxis]
    @assert !isnothing(axis) "The Scene does not have an axis!"
    scene[OldAxis].ticks.ranges_labels[][1]
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
function ticks!(scene::Scene; tickranges=tickranges(scene), ticklabels=ticklabels(scene))
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

Set the tick labels and range along the x-axes. See also `ticks!`.
"""
function xticks!(scene::Scene; xtickrange=xtickrange(scene), xticklabels=xticklabels(scene))
    ticks!(scene, tickranges=(xtickrange, tickranges(scene)[2:end]...), ticklabels=(xticklabels, ticklabels(scene)[2:end]...))
    return nothing
end

"""
    yticks!([scene,]; ytickrange=ytickrange(scene), yticklabels=yticklabel(scene))

Set the tick labels and range along all the y-axis. See also `ticks!`.
"""
function yticks!(scene::Scene; ytickrange=ytickrange(scene), yticklabels=yticklabels(scene))
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

Set the tick labels and range along all z-axis. See also `ticks!`.
"""
function zticks!(scene::Scene; ztickrange=ztickrange(scene), zticklabels=zticklabels(scene))
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
    if is2d(scene)
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
