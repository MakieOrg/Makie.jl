function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(Legend, (Scene, Node{Vector{Tuple{Optional{String}, Vector{LegendEntry}}}}))
    # @assert precompile(Legend, (Scene, AbstractArray, Vector{String}))
    @assert precompile(Colorbar, (Scene,))
    # @assert precompile(Axis, (Scene,))
    # @assert precompile(Core.kwfunc(Type), (NamedTuple{(:title,), Tuple{String}}, Type{Axis}, Scene))
    @assert precompile(LineAxis, (Scene,))
    @assert precompile(Menu, (Scene,))
    @assert precompile(Button, (Scene,))
    @assert precompile(Slider, (Scene,))
    @assert precompile(Textbox, (Scene,))
end
