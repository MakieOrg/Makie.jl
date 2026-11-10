struct SnapshotEqualityProbe
    comparisons::Base.RefValue{Int}
end
function Base.isequal(a::SnapshotEqualityProbe, b::SnapshotEqualityProbe)
    b.comparisons[] += 1
    return true
end

function capture_resolution(f)
    result = try
        f()
    catch err
        err
    end
    return (result, ComputePipeline.current_resolution())
end

function input_feedback_graph(action)
    graph = ComputeGraph()
    first = Ref(true)
    add_input!(graph, :a, 1) do value
        if first[]
            first[] = false
            action(graph)
        end
        return value
    end
    return graph
end

function binding_feedback_graph()
    graph = ComputeGraph()
    add_input!(graph, :a, 1)
    map!(graph, :a, :b) do value
        value == 1 && (graph.a = 2)
        return value
    end
    map!(identity, graph, :b, :c)
    return graph
end

@testset "Callback lock inversion" begin
    for threaded in (false, true)
        @testset "Cross-component reads (threaded=$threaded)" begin
            a, b = ComputeGraph(), ComputeGraph()
            add_input!(a, :x, 1)
            add_input!(b, :x, 2)
            @test a.x[] == 1
            @test b.x[] == 2
            entered = Channel{Nothing}(2)
            release = Channel{Nothing}(2)
            map!(a, :x, :result) do x
                put!(entered, nothing)
                take!(release)
                return x + b.x[]
            end
            map!(b, :x, :result) do x
                put!(entered, nothing)
                take!(release)
                return x + a.x[]
            end
            t1 = threaded ? Threads.@spawn(capture_resolution(() -> a.result[])) : @async(capture_resolution(() -> a.result[]))
            t2 = threaded ? Threads.@spawn(capture_resolution(() -> b.result[])) : @async(capture_resolution(() -> b.result[]))
            take!(entered)
            take!(entered)
            put!(release, nothing)
            put!(release, nothing)
            wait_for_task(t1)
            wait_for_task(t2)
            @test istaskdone(t1) && istaskdone(t2)
            if istaskdone(t1) && istaskdone(t2)
                results = fetch.((t1, t2))
                @test any(r -> r[1] isa ResolveException && occursin("declare it as an input", sprint(showerror, r[1])), results)
                @test all(r -> r[1] == 3 || r[1] isa ResolveException, results)
                @test all(r -> isnothing(r[2]), results)
            end
            @test a.x[] == 1
            @test b.x[] == 2
        end
    end

    @testset "Callback merge rejects before waiting" begin
        lo, hi = sort([ComputeGraph(), ComputeGraph()]; by = g -> objectid(getfield(g, :state)))
        add_input!(lo, :x, 1)
        add_input!(hi, :x, 2)
        entered = Channel{Nothing}(1)
        release = Channel{Nothing}(1)
        map!(hi, :x, :result) do x
            put!(entered, nothing)
            take!(release)
            map!(identity, hi, [lo.x], :other)
            return x
        end
        reader = @async capture_resolution(() -> hi.result[])
        take!(entered)
        merger = @async ComputePipeline.connect_components!(lo, hi)
        yield()
        @test islocked(getfield(lo, :state).lock)
        put!(release, nothing)
        wait_for_task(reader)
        wait_for_task(merger)
        @test istaskdone(reader) && istaskdone(merger)
        if istaskdone(reader) && istaskdone(merger)
            result, scope = fetch(reader)
            @test result isa ResolveException
            @test occursin("Cannot connect graphs", sprint(showerror, result))
            @test isnothing(scope)
        end
    end

    @testset "Callbacks may build unrelated connected graphs" begin
        graph = ComputeGraph()
        add_input!(graph, :x, 1)
        restored = Ref(false)
        map!(graph, :x, :result) do x
            scope = ComputePipeline.current_resolution()
            source, target = ComputeGraph(), ComputeGraph()
            add_input!(source, :x, x)
            map!(identity, target, source.x, :result)
            value = target.result[]
            restored[] = ComputePipeline.current_resolution() === scope
            return value
        end
        @test graph.result[] == 1
        @test restored[]
        @test isnothing(ComputePipeline.current_resolution())
    end

    @testset "Unrelated merges cannot wait inside callbacks" begin
        graph, a, b = ComputeGraph(), ComputeGraph(), ComputeGraph()
        add_input!(graph, :x, 1)
        entered = Channel{Nothing}(1)
        release = Channel{Nothing}(1)
        holder = @async lock(getfield(b, :state).lock) do
            put!(entered, nothing)
            take!(release)
        end
        take!(entered)
        map!(graph, :x, :result) do x
            ComputePipeline.connect_components!(a, b)
            return x
        end
        reader = @async capture_resolution(() -> graph.result[])
        try
            wait_for_task(reader)
            @test istaskdone(reader)
            if istaskdone(reader)
                result, scope = fetch(reader)
                @test result isa ResolveException
                @test occursin("declare it as an input", sprint(showerror, result))
                @test isnothing(scope)
            end
        finally
            put!(release, nothing)
            wait(holder)
            wait(reader)
        end
    end

    @testset "Uncontended nested graph reads still work" begin
        a, b = ComputeGraph(), ComputeGraph()
        add_input!(a, :x, 1)
        add_input!(b, :x, 2)
        child_scope = Ref{Any}(false)
        map!(a, :x, :result) do x
            child_scope[] = fetch(@async ComputePipeline.current_resolution())
            return x + b.x[]
        end
        @test a.result[] == 3
        @test isnothing(child_scope[])
        @test isnothing(ComputePipeline.current_resolution())
    end
end

@testset "All resolution entry points defer feedback" begin
    for entry in (:mark_resolved, :init), action in (:write, :notify)
        graph = input_feedback_graph(g -> action === :write ? (g.a = 2) : notify(g.a))
        if entry === :mark_resolved
            map!(identity, graph, :a, :b)
            ComputePipeline.mark_resolved!(graph.b)
        else
            map!(identity, graph, :a, :b; init = 0)
        end
        @test isdirty(graph.a)
        @test graph.a[] == (action === :write ? 2 : 1)
        @test !isdirty(graph.a)
        @test isnothing(ComputePipeline.current_resolution())
    end

    @testset "Direct edge resolution notifies after unlocking" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 0)
        add_input!(graph, :trigger, 1)
        obs = ComputePipeline.get_observable!(graph.a)
        values = Int[]
        locks = Bool[]
        listener = on(obs) do value
            push!(values, value)
            push!(locks, islocked(ComputePipeline.component(getfield(graph, :state)).lock))
        end
        map!(graph, :trigger, :b) do x
            graph.a = 2
            return x
        end
        ComputePipeline.resolve!(graph.b.parent)
        @test obs[] == 2
        @test values == [2]
        @test locks == [false]
        @test isempty(ComputePipeline.component(getfield(graph, :state)).notifications)
        off(listener)
    end

    @testset "Input failures restore all entry points" begin
        for entry in (:mark_resolved, :init)
            graph = input_feedback_graph() do g
                g.a = 2
                error("input callback failed")
            end
            if entry === :mark_resolved
                map!(identity, graph, :a, :b)
                @test_throws "input callback failed" ComputePipeline.mark_resolved!(graph.b)
            else
                @test_throws "input callback failed" map!(identity, graph, :a, :b; init = 0)
            end
            @test isnothing(ComputePipeline.current_resolution())
            @test isdirty(graph.a)
            @test graph.a[] == 2
        end
    end

    @testset "Exceptions restore resolution scope" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(x -> error("callback failed"), graph, :a, :b)
        @test_throws "callback failed" graph.b[]
        @test isnothing(ComputePipeline.current_resolution())
        other = ComputeGraph()
        ComputePipeline.connect_components!(graph, other)
        @test ComputePipeline.component(getfield(graph, :state)) === ComputePipeline.component(getfield(other, :state))
    end
end

@testset "Observable initialization consistency" begin
    for binding in (:onany, :map, :map!)
        graph = binding_feedback_graph()
        if binding === :onany
            values = Tuple{Int, Int}[]
            listeners = onany((b, c) -> push!(values, (b, c)), graph.b, graph.c; update = true)
            @test values == [(2, 2)]
            foreach(off, listeners)
        elseif binding === :map
            result = map(tuple, graph.b, graph.c)
            @test result[] == (2, 2)
        else
            result = Observable((0, 0))
            map!(tuple, result, graph.b, graph.c)
            @test result[] == (2, 2)
        end
        @test graph.observables[:b][] == graph.observables[:c][] == 2
    end
    for kind in (:node, :graph, :convert)
        graph = binding_feedback_graph()
        obs = if kind === :node
            ComputePipeline.get_observable!(graph.b)
        elseif kind === :graph
            ComputePipeline.get_observable!(graph, :b)
        else
            convert(Observable, graph.b)
        end
        @test obs[] == 2
        @test !isdirty(graph.b)
        @test ComputePipeline.get_observable!(graph.b) === obs
    end
end

@testset "Cached observables do not scan their values" begin
    graph = ComputeGraph()
    comparisons = Ref(0)
    add_input!(graph, :value, SnapshotEqualityProbe(comparisons))
    obs = ComputePipeline.get_observable!(graph.value)
    @test all(_ -> ComputePipeline.get_observable!(graph.value) === obs, 1:20)
    @test all(_ -> ComputePipeline.get_observable!(graph, :value) === obs, 1:20)
    @test comparisons[] == 0
end
