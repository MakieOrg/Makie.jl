function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(AbstractPlotting.backend_display, (GLBackend, Scene))
end
