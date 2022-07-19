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

let
    @precompile_calls begin
        precompile(Makie.initialize_block!, (Axis,))
        ax = Axis(Figure()[1,1])
        ax = _block(Axis, Figure())
        initialize_block!(ax)
        LineAxis(Scene(); spinecolor=:red, labelfont="Deja vue", ticklabelfont="Deja Vue", spinevisible=false, endpoints=Observable([Point2f(0), Point2f(0, 1)]), minorticks = IntervalsBetween(5))
        cam = Camera(Observable(Recti(0, 0, 1, 1)))
        convert(ColorTypes.RGBA{Float32}, RGB{N0f8}(0, 0, 0))
        f, ax1, pl = scatter(1:4)
        f, ax2, pl = lines(1:4)
        precompile_obs(ax1)
        precompile_obs(ax2)
        convert_arguments(Mesh{Tuple{Vector{Point{2, Float32}}, Matrix{Int64}}}, rand(Point2f, 10), [1 2 3; 4 3 2])
        @assert precompile(Legend, (Scene, Observable{Vector{Tuple{Optional{String}, Vector{LegendEntry}}}}))
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
end
