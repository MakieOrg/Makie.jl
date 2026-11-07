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
