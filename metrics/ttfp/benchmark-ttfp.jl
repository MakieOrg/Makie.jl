Package = Symbol(ARGS[1])
results_file = ARGS[2]
run_index = parse(Int, ARGS[3])
mode = ARGS[4]
count_inference = mode == "inference"

# Loaded only for inference runs so that timing runs are not affected by it.
count_inference && @eval using SnoopCompileCore

count_nodes(node) = 1 + sum(count_nodes, node.children; init = 0)

function measure(f)
    if count_inference
        SnoopCompileCore.start_deep_timing()
        try
            f()
        finally
            SnoopCompileCore.stop_deep_timing()
        end
        root = SnoopCompileCore.finish_snoop_inference()
        return ["inferred" => count_nodes(root) - 1]
    end
    bytes = Base.gc_bytes()
    tstart = time_ns()
    f()
    elapsed = time_ns() - tstart
    return ["time" => Float64(elapsed), "alloc" => Float64(Base.gc_bytes() - bytes)]
end

rows = Dict{String, Any}[]
function record!(stage, f)
    for (quantity, value) in measure(f)
        push!(rows, Dict("run" => run_index, "stage" => stage, "quantity" => quantity, "value" => value))
    end
    return
end

record!("using", () -> @eval using $Package)

if Package === :WGLMakie
    import Electron
    # Backwards compatibility for master
    Bonito = isdefined(WGLMakie, :Bonito) ? WGLMakie.Bonito : WGLMakie.JSServe
    Bonito.use_electron_display()
end

set_theme!(size = (800, 600))

GC.gc()
record!("first create", () -> global fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true))
GC.gc()
record!("first display", () -> colorbuffer(fig; px_per_unit = 1))

using JSON
using Statistics: median

macro simple_median_time(expr)
    time_expr = quote
        local elapsedtime = time_ns()
        $expr
        elapsedtime = time_ns() - elapsedtime
        Float64(elapsedtime)
    end

    return quote
        times = Float64[]
        for i in 1:101
            t = Core.eval(Main, $(QuoteNode(time_expr)))
            if i > 1
                push!(times, t)
            end
        end
        median(times)
    end
end

if !count_inference
    @time "creating figure" figure_time = @simple_median_time fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)
    fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)
    @time "colorbuffer" colorbuffer_time = @simple_median_time colorbuffer(fig; px_per_unit = 1)
    for (stage, value) in ["create" => figure_time, "display" => colorbuffer_time]
        push!(rows, Dict("run" => run_index, "stage" => stage, "quantity" => "time", "value" => value))
    end
end

if mode != "warmup"
    old_rows = isfile(results_file) ? JSON.parsefile(results_file) : []
    open(io -> JSON.print(io, [old_rows; rows]), results_file, "w")
end

try
    rm("test.png")
catch e
end
