function _precompile_()
    @warn "Precompilation disabled temporarily"
    # ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    # f, ax1, pl = scatter(1:4)
    # f, ax2, pl = lines(1:4)
    # f = Figure()
    # Axis(f[1,1])
    return
end
