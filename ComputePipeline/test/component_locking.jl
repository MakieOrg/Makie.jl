@testset "Component synchronization" begin
    @testset "Input read waits for initialization" begin
        entered = Channel{Nothing}(1)
        release = Channel{Nothing}(1)
        g = ComputeGraph()
        add_input!(g, :a, 1) do x
            put!(entered, nothing)
            take!(release)
            return x
        end
        a = @async g.a[]
        take!(entered)
        b = @async g.a[]
        yield()
        @test !istaskdone(b)
        put!(release, nothing)
        @test fetch(a) == fetch(b) == 1
    end
    @testset "Connected components" begin
        gs = [ComputeGraph() for _ in 1:30]
        add_input!(first(gs), :x, 1)
        for i in 2:30
            add_input!(gs[i], :x, gs[i - 1].x)
        end
        shared = ComputePipeline.component(getfield(first(gs), :state))
        @test all(g -> ComputePipeline.component(getfield(g, :state)) === shared, gs)
        @test last(gs).x[] == 1
        first(gs).x = 2
        @test last(gs).x[] == 2
        other = ComputeGraph()
        @test ComputePipeline.component(getfield(other, :state)) !== shared
    end
    @testset "Threaded observable notifications" begin
        g = ComputeGraph()
        add_input!(g, :a, 0)
        add_input!(g, :b, 0)
        map!((a, b) -> (a, b), g, [:a, :b], :pair)
        bad = Threads.Atomic{Int}(0)
        listener = ComputePipeline.Observables.on(g.pair) do pair
            pair[1] == pair[2] || Threads.atomic_add!(bad, 1)
        end
        @sync for sign in (-1, 1)
            Threads.@spawn for i in 1:1000
                update!(g, a = sign * i, b = sign * i)
            end
        end
        @test bad[] == 0
        @test g.pair[][1] == g.pair[][2]
        ComputePipeline.Observables.off(listener)
    end
end

@testset "Component merge synchronization" begin
    @testset "Two parents and two shared children" begin
        a, b, c, d, out = [ComputeGraph() for _ in 1:5]
        add_input!(a, :x, 1)
        add_input!(b, :y, 10)
        map!(+, c, [a.x, b.y], :sum)
        map!(-, d, [a.x, b.y], :difference)
        entered = Channel{Nothing}(1)
        release = Channel{Nothing}(1)
        first_call = Ref(true)
        map!(out, [c.sum, d.difference], :result) do sum, difference
            if first_call[]
                first_call[] = false
                put!(entered, nothing)
                take!(release)
            end
            return (sum, difference)
        end
        reader = @async out.result[]
        take!(entered)
        writer = @async begin
            ComputePipeline.mark_dirty!(b.y)
            b.y = 20
        end
        yield()
        @test !istaskdone(writer)
        put!(release, nothing)
        @test fetch(reader) == (11, -9)
        wait(writer)
        @test out.result[] == (21, -19)
    end

    @testset "Merging waits for an active resolution" begin
        a, b = [ComputeGraph() for _ in 1:2]
        entered = Channel{Nothing}(1)
        release = Channel{Nothing}(1)
        add_input!(a, :x, 1) do x
            put!(entered, nothing)
            take!(release)
            return x
        end
        old_root = ComputePipeline.component(getfield(a, :state))
        reader = @async a.x[]
        take!(entered)
        merger = @async ComputePipeline.connect_components!(a, b)
        yield()
        @test !istaskdone(merger)
        @test ComputePipeline.component(getfield(a, :state)) === old_root
        put!(release, nothing)
        @test fetch(reader) == 1
        wait(merger)
        @test ComputePipeline.component(getfield(a, :state)) === ComputePipeline.component(getfield(b, :state))
    end

    @testset "Waiting readers retry after a root moves" begin
        a, b, c = sort([ComputeGraph(), ComputeGraph(), ComputeGraph()]; by = g -> objectid(getfield(g, :state)))
        ComputePipeline.connect_components!(b, c)
        new_root = getfield(a, :state)
        old_root = getfield(b, :state)
        add_input!(c, :x, 1)
        local reader
        lock(new_root.lock)
        try
            lock(old_root.lock)
            try
                reader = @async c.x[]
                yield()
                @test !istaskdone(reader)
                ComputePipeline.connect_components!(a, b)
            finally
                unlock(old_root.lock)
            end
            yield()
            @test !istaskdone(reader)
        finally
            unlock(new_root.lock)
        end
        @test fetch(reader) == 1
    end

    @testset "Competing threaded merges" begin
        for _ in 1:100
            a, b, c, d = [ComputeGraph() for _ in 1:4]
            @sync begin
                Threads.@spawn ComputePipeline.connect_components!(a, b)
                Threads.@spawn ComputePipeline.connect_components!(c, d)
                Threads.@spawn ComputePipeline.connect_components!(b, c)
                Threads.@spawn ComputePipeline.connect_components!(d, a)
            end
            shared = ComputePipeline.component(getfield(a, :state))
            @test all(g -> ComputePipeline.component(getfield(g, :state)) === shared, (b, c, d))
        end
    end
end

@testset "Callback reentrancy" begin
    @testset "Unsafe operations fail without leaving the component locked" begin
        for operation in (:read, :write, :dirty, :resolved)
            graph = ComputeGraph()
            add_input!(graph, :a, 1)
            map!(graph, :a, :b) do value
                if operation === :read
                    graph.b[]
                elseif operation === :write
                    graph.b[] = 2
                elseif operation === :dirty
                    ComputePipeline.mark_dirty!(graph.b)
                else
                    ComputePipeline.mark_resolved!(graph.b)
                end
                return value
            end
            @test_throws ResolveException graph.b[]
            @test getfield(graph, :state).depth == 0
            graph.a = 3
            @test fetch(@async graph.a[]) == 3
        end
    end

    @testset "Input notification is deferred" begin
        graph = ComputeGraph()
        first_call = Ref(true)
        add_input!(graph, :a, 1) do value
            if first_call[]
                first_call[] = false
                notify(graph.a)
            end
            return value
        end
        @test graph.a[] == 1
        @test isdirty(graph.a)
        @test graph.a[] == 1
        @test !isdirty(graph.a)
    end

    @testset "Observable observes deferred initialization updates" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do value
            value == 1 && (graph.a = 2)
            return value
        end
        values = Int[]
        listener = on(value -> push!(values, value), graph.b; update = true)
        @test values == [1, 2]
        @test !isdirty(graph.b)
        off(listener)
    end
end

@testset "Deferred input feedback" begin

    @testset "Set input from input" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1) do v
            if v == 1
                graph.a = v + 1
            end
            return v
        end
        map!(identity, graph, :a, :b)

        results = Int[]
        task = @async on(x -> push!(results, x), graph.b, update = true)
        wait_for_task(task)

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test results == [1, 2]
        else
            error("Possible deadlock detected.")
        end
    end


    @testset "Set reused Input from indirect dependent" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do v
            if v == 1
                graph.a = v + 1
            end
            return v
        end
        map!(identity, graph, :a, :c)
        map!(+, graph, [:b, :c], :d)

        results = Int[]
        task = @async on(x -> push!(results, x), graph.d, update = true)
        wait_for_task(task)

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test !isdirty(graph.c.parent)
            @test !isdirty(graph.d.parent)
            @test results == [2, 4]
        else
            error("Possible deadlock detected.")
        end
    end


end

@testset "Deferred initialization through observable bindings" begin
    for binding in (:onany, :map, :connect)
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do value
            value == 1 && (graph.a = 2)
            return value
        end
        if binding === :onany
            values = Int[]
            listeners = onany((value, _) -> push!(values, value), graph.b, Observable(0); update = true)
            @test values == [1, 2]
            foreach(off, listeners)
        elseif binding === :map
            result = map(identity, graph.b)
            @test result[] == 2
        else
            result = Observable(0)
            connect!(result, graph.b)
            @test result[] == 2
        end
    end
end

@testset "Nested reads and actual callback cycles" begin
    @testset "Input conversion reads dirty palette inputs" begin
        graph = ComputeGraph()
        add_input!(graph, :palette, [:red, :blue])
        add_input!(graph, :cycle_index, 1)
        add_input!(graph, :color, :cycled) do value
            return value === :cycled ? graph.palette[][graph.cycle_index[]] : value
        end
        @test graph.color[] === :red
        graph.cycle_index = 2
        notify(graph.color)
        @test graph.color[] === :blue
        @test isempty(getfield(graph, :state).active_callbacks)
        @test isnothing(getfield(graph, :state).active_callback)
    end

    @testset "Mutually recursive input conversions" begin
        graph = ComputeGraph()
        add_input!(_ -> graph.b[], graph, :a, 1)
        add_input!(_ -> graph.a[], graph, :b, 1)
        @test_throws r"Recursive resolution" graph.a[]
        @test isempty(getfield(graph, :state).active_callbacks)
        @test isnothing(getfield(graph, :state).active_callback)
        @test getfield(graph, :state).depth == 0
    end

    @testset "Recursive read through a dependent computation" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(_ -> graph.c[], graph, :a, :b)
        map!(identity, graph, :b, :c)
        @test_throws r"Recursive resolution" graph.b[]
        @test isempty(getfield(graph, :state).active_callbacks)
        @test isnothing(getfield(graph, :state).active_callback)
        @test getfield(graph, :state).depth == 0
    end
end
