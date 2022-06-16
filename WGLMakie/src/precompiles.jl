function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    activate!()
    f1, ax1, pl = scatter(1:4)
    f2, ax2, pl = lines(1:4)
    Makie.precompile_obs(ax1)
    Makie.precompile_obs(ax2)
    serv = JSServe.get_server()
    s = JSServe.Session()
    JSServe.jsrender(s, f1)
    JSServe.jsrender(s, f2)
    return
end
