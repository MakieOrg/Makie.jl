function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Makie.backend_display, (CairoBackend, Scene))
    activate!()
    f, ax1, pl = scatter(1:4)
    f, ax2, pl = lines(1:4)
    Makie.colorbuffer(ax1.scene)
    Makie.colorbuffer(ax2.scene)
    return
end
