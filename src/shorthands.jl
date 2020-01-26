"""
    xlabel!([scene,] xlabel)

Set the x-axis label for the given Scene.
Defaults to using the current Scene.
"""
function xlabel!(scene, xlabel::AbstractString)
    axis = scene[Axis]
    @assert !isnothing(axis)
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
    @assert !isnothing(axis)
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
    @assert !isnothing(axis)
    @assert axis isa Axis3D
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
    @assert !isnothing(axis)
    return axis.ticks.ranges_labels[][2]
end

"""
    xticklabels(scene)

Returns the all the x-axis tick labels. See also [`ticklabels`](@ref).
"""
xticklabels(scene) = labels(scene)[1]

"""
    yticklabels(scene)

Returns the all the y-axis tick labels. See also [`ticklabels`](@ref).
"""
yticklabels(scene) = labels(scene)[2]

"""
    zticklabels(scene)

Returns the all the z-axis tick labels. See also [`ticklabels`](@ref).
"""
zticklabels(scene) = labels(scene)[3]

"""
    tickranges(scene)

Returns the tick ranges along all axes.
"""
function tickranges(scene)
    axis = scene[Axis]
    @assert !isnothing(axis)
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
ztickrange(scene) = tickranges(scene)[3]

"""
    ticks!([scene,]; tickranges=tickranges(scene), ticklabels=ticklabels(scene))

Set the tick labels and ranges along all axes. The respective labels and ranges
along each axis must be of the same length.
"""
function ticks!(scene; tickranges=tickranges(scene), ticklabels=ticklabels(scene))
    axis = scene[Axis]
    @assert !isnothing(axis)
    # Have to set `ranges_labels` first so that any changes in the length of these
    # is reflected there first.
    axis.ticks.ranges_labels[] = (tickranges, ticklabels)
    axis.ticks.ranges[] = tickranges
    axis.ticks.labels[] = ticklabels
    return nothing
end
function ticks!(; tickranges=tickranges(scene), ticklabels=ticklabels(scene))
    ticks!(current_scene(), ranges=ranges, labels=labels)
end

"""
    xticks!([scene,]; xtickranges=xtickrange(scene), xticklabels=xticklabel(scene))

Set the tick labels and range along the x-axes. See also [`ticks!`](@ref).
"""
function xticks!(scene; xtickrange=xtickrange(scene), xticklabels=xticklabels(scene))
    ticks!(scene, tickranges=(xtickrange, tickranges(scene)[2:end]...), ticklabels=(xticklabels, ticklabels(scene)[2:end]...))
    return nothing
end
function xticks!(; xtickrange=xtickrange(scene), xticklabels=xticklabels(scene))
    xticks!(current_scene(), xtickranges=xtickrange, xticklabels=xticklabels)
end

"""
    yticks!([scene,]; ytickranges=ytickrange(scene), yticklabels=yticklabel(scene))

Set the tick labels and range along all the y-axis. See also [`ticks!`](@ref).
"""
function yticks!(scene; ytickrange=ytickrange(scene), yticklabels=yticklabels(scene))
    r = tickranges(scene)
    l = ticklabels(scene)
    if length(r) == 2
        ticks!(scene, tickranges=(first(r), ytickrange), ticklabels=(first(l), yticklabels))
    else  # length(r) == 3
        ticks!(scene, tickranges=(first(r), ytickrange, last(r)), ticklabels =(first(l), yticklabels, last(l)))
    end
    return nothing
end
function yticks!(; ytickrange=ytickrange(scene), yticklabels=yticklabels(scene))
    yticks!(current_scene(), ytickrange=ytickrange, yticklabels=yticklabels)
end

"""
    zticks!([scene,]; ztickranges=ztickrange(scene), zticklabels=zticklabel(scene))

Set the tick labels and range along all z-axis. See also [`ticks!`](@ref).
"""
function zticks!(scene; ztickrange=ztickrange(scene), zticklabels=zticklabels(scene))
    ticks!(scene, tickranges=(tickranges(scene)[1:2]..., ztickrange), ticklabels=(ticklabels(scene)[1:2]..., zticklabels))
    return nothing
end
function zticks!(; ztickrange=ztickrange(scene), zticklabels=zticklabels(scene))
    zticks!(current_scene(), ztickrange=ztickrange, zticklabels=zticklabels)
end

###
### Ticks rotations
###
"""
    ticksrotations(scene)

Returns the rotation of all tick labels.
"""
function ticksrotations(scene)
    axis = scene[Axis]
    @assert !isnothing(axis)
    return axis.ticks.rotation[]
end

"""
    xticksrotation(scene)

Returns the rotation of tick labels along the x-axis. See also [`ticksrotations`](@ref)
"""
xticksrotation(scene) = first(ticksrotations(scene))

"""
    yticksrotation(scene)

Returns the rotation of tick labels along the y-axis. See also [`ticksrotations`](@ref)
"""
yticksrotation(scene) = ticksrotations(scene)[2]

"""
    zticksrotation(scene)

Returns the rotation of tick labels along the z-axis. See also [`ticksrotations`](@ref)
"""
zticksrotation(scene) = ticksrotations(scene)[3]

"""
    xticksrotation!([scene,] zangle)

Set the rotation of all tick labels.
"""
function ticksrotations!(scene, angles)
    axis = scene[Axis]
    @assert !isnothing(axis)
    scene[Axis].ticks.rotation[] = angles
    return nothing
end

"""
    xticksrotation!([scene,] xangle)

Set the rotation of tick labels along the x-axis. See also [`ticksrotations!`](@ref).
"""
function xticksrotation!(scene, xangle)
    ticksrotations!(scene, (xangle, ticksrotations(scene)[2:end]...))
    return nothing
end
xticksrotation!(xangle) = xticksrotation!(current_scene(), xangle)

"""
    yticksrotation!([scene,] yangle)

Set the rotation of tick labels along the y-axis. See also [`ticksrotations!`](@ref).
"""
function yticksrotation!(scene, yangle)
    if length(r) == 2
        ticksrotations!(scene, (xticksrotation(scene), yangle))
    else  # length(r) == 3
        ticksrotations!(scene, (xticksrotation(scene), yangle, zticksrotation(scene)))
    end
end
yticksrotation!(yangle) = yticksrotation!(current_scene(), yangle)

"""
    zticksrotation!([scene,] zangle)

Set the rotation of tick labels along the z-axis. See also [`ticksrotations!`](@ref).
"""
function zticksrotation!(scene, zangle)
    ticksrotations!(scene, (ticksrotations(scene)[1:2]..., zangle))
    return nothing
end
zticksrotation!(zangle) = zticksrotation!(current_scene(), zangle)
