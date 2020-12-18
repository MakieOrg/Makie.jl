function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(Legend, (Scene, Node{Vector{Tuple{Optional{String}, Vector{LegendEntry}}}}))
    # @assert precompile(Legend, (Scene, AbstractArray, Vector{String}))
    @assert precompile(Colorbar, (Scene,))
    # @assert precompile(Axis, (Scene,))
    # @assert precompile(Core.kwfunc(Type), (NamedTuple{(:title,), Tuple{String}}, Type{Axis}, Scene))
    @assert precompile(LineAxis, (Scene,))
    @assert precompile(Menu, (Scene,))
    @assert precompile(LButton, (Scene,))
    @assert precompile(LSlider, (Scene,))
    @assert precompile(Textbox, (Scene,))

    @assert precompile(layoutscene, ())  # doesn't fully precompile
    @assert precompile(get_ticklabels, (AbstractPlotting.Automatic, AbstractPlotting.Automatic, Vector{Float64}))
end
