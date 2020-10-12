function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(Scene, ())
    @assert precompile(update_limits!, (Scene,))
    @assert precompile(update_limits!, (Scene, Automatic))
    @assert precompile(update_limits!, (Scene, FRect3D))
end
