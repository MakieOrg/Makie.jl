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

    # get_obs(x.attributes, visited, obs)
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

const verbose = Ref(false)    # if true, prints all the precompiles
const have_inference_tracking = isdefined(Core.Compiler, :__set_measure_typeinf)
const have_force_compile = isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("#@force_compile"))

function precompile_roots(roots)
    @assert have_inference_tracking
    for child in roots
        mi = child.mi_info.mi
        precompile(mi.specTypes) # TODO: Julia should allow one to pass `mi` directly (would handle `invoke` properly)
        verbose[] && println(mi)
    end
end

macro precompile_calls(args...)
    local sym, ex
    if length(args) == 2
        # This is tagged with a Symbol
        isa(args[1], Symbol) || isa(args[1], QuoteNode) || throw(ArgumentError("expected a Symbol as the first argument to @precompile_calls, got $(typeof(args[1]))"))
        isa(args[2], Expr) || throw(ArgumentError("expected an expression as the second argument to @precompile_calls, got $(typeof(args[2]))"))
        sym = isa(args[1], Symbol) ? args[1]::Symbol : (args[1]::QuoteNode).value::Symbol
        sym ∈ (:setup, :all) || throw(ArgumentError("first argument to @precompile_calls must be :setup or :all, got $(QuoteNode(sym))"))
        ex = args[2]::Expr
    else
        length(args) == 1 || throw(ArgumentError("@precompile_calls accepts only one or two arguments"))
        isa(args[1], Expr) || throw(ArgumentError("@precompile_calls expected an expression, got $(typeof(args[1]))"))
        sym = :all
        ex = args[1]::Expr
    end
    if sym == :all
        if have_inference_tracking
            ex = quote
                Core.Compiler.Timings.reset_timings()
                Core.Compiler.__set_measure_typeinf(true)
                try
                    $ex
                finally
                    Core.Compiler.__set_measure_typeinf(false)
                    Core.Compiler.Timings.close_current_timer()
                end
                Makie.precompile_roots(Core.Compiler.Timings._timings[1].children)
            end
        elseif have_force_compile
            ex = quote
                begin
                    Base.Experimental.@force_compile
                    $ex
                end
            end
        end
    end
    ex = quote
        if ccall(:jl_generating_output, Cint, ()) == 1 || Makie.verbose[]
            $ex
        end
    end
    return esc(ex)
end

macro compile(block)
    return quote
        let
            $(esc(block))
        end
    end
end

let
    @precompile_calls begin
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
        empty!(FONT_CACHE)
        empty!(_default_font)
        empty!(_alternative_fonts)
    end
    nothing
end
