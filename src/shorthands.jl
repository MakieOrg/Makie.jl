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
