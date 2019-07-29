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
