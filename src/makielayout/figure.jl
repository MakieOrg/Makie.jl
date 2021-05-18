
"""
    layoutscene(padding = 30; kwargs...)
Create a `Scene` in `campixel!` mode and a `GridLayout` aligned to the scene's pixel area with `alignmode = Outside(padding)`.
"""
function layoutscene(padding = 30; inspectable = false, kwargs...)
    scene = Scene(; camera = campixel!, inspectable = inspectable, kwargs...)
    gl = GridLayout(scene, alignmode = Outside(padding))
    scene, gl
end
"""
    layoutscene(nrows::Int, ncols::Int, padding = 30; kwargs...)
Create a `Scene` in `campixel!` mode and a `GridLayout` aligned to the scene's pixel area with size `nrows` x `ncols` and `alignmode = Outside(padding)`.
"""
function layoutscene(nrows::Int, ncols::Int, padding = 30; inspectable = false, kwargs...)
    scene = Scene(; camera = campixel!, inspectable = inspectable, kwargs...)
    gl = GridLayout(scene, nrows, ncols, alignmode = Outside(padding))
    scene, gl
end
