@testset "Theming" begin
    red = Makie.to_color(:red)
    black = Makie.to_color(:black)

    @testset "with_theme does not leak into other tasks" begin
        entered = Base.Event()
        release = Base.Event()
        themed = Threads.@spawn with_theme(; textcolor = :red) do
            notify(entered)
            wait(release)
        end
        wait(entered)
        @test Axis(Figure()[1, 1]).xlabelcolor[] == black
        notify(release)
        wait(themed)
    end

    @testset "with_theme is inherited by spawned tasks" begin
        color = with_theme(; textcolor = :red) do
            fetch(Threads.@spawn Axis(Figure()[1, 1]).xlabelcolor[])
        end
        @test color == red
    end

    @testset "nested with_theme replaces the outer theme" begin
        with_theme(; textcolor = :red) do
            with_theme(; fontsize = 30) do
                @test theme(:fontsize)[] == 30
                @test theme(:textcolor)[] == :black
            end
            @test theme(:textcolor)[] == :red
        end
    end

    @testset "theme changes inside with_theme are reverted" begin
        with_theme() do
            update_theme!(; textcolor = :red)
            @test theme(:textcolor)[] == :red
            set_theme!(; fontsize = 30)
            @test theme(:fontsize)[] == 30
        end
        @test theme(:textcolor)[] == :black
        @test theme(:fontsize)[] == 14
    end

    @testset "set_theme! never exposes a partially built theme" begin
        stop = Threads.Atomic{Bool}(false)
        setter = Threads.@spawn while !stop[]
            set_theme!()
            yield()
        end
        misses = count(1:2000) do _
            yield()
            !haskey(Makie.current_default_theme(), :CairoMakie)
        end
        stop[] = true
        wait(setter)
        @test misses == 0
    end
end
