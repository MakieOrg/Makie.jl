function get_obs(x::Attributes, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    union!(obs, values(x))
    return obs
end

function get_obs(x::Union{AbstractVector, Tuple}, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    isempty(x) && return
    for e in x
        get_obs(e, visited, obs)
    end
    return obs
end

get_obs(::Nothing, visited, obs=Set()) = obs
get_obs(::DataType, visited, obs=Set()) = obs
get_obs(::Method, visited, obs=Set()) = obs

function get_obs(x, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    for f in fieldnames(typeof(x))
        if isdefined(x, f)
            get_obs(getfield(x, f), visited, obs)
        end
    end
end

function get_obs(x::Union{AbstractDict, NamedTuple}, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    for (k, v) in pairs(x)
        get_obs(v, visited, obs)
    end
    return obs
end

function get_obs(x::Union{Observables.AbstractObservable, Observables.ObserverFunction}, visited, obs=Set())
    push!(obs, x)
    return obs
end

function get_obs(x::Axis, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end

    get_obs(x.attributes, visited, obs)
    get_obs(x.layoutobservables, visited, obs)
    get_obs(x.scene, visited, obs)
    get_obs(x.finallimits, visited, obs)
    get_obs(x.scrollevents, visited, obs)
    get_obs(x.keysevents, visited, obs)
    get_obs(x.mouseeventhandle.obs, visited, obs)
    return obs
end

function precompile_obs(x)
    obsies = get_obs(x, Base.IdSet())
    for obs in obsies
        Base.precompile(obs)
    end
end


function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Makie.backend_display, (CairoBackend, Scene))
    activate!()
    f, ax1, pl = scatter(1:4)
    f, ax2, pl = lines(1:4)
    Makie.colorbuffer(ax1.scene)
    Makie.colorbuffer(ax2.scene)
    precompile_obs(ax1)
    precompile_obs(ax2)
    return
end
