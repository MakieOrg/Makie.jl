using Makie
using Makie: BufferFormat, N0f8, is_compatible, BFT
using Makie: Stage, get_input_format, get_output_format
using Makie: RenderPipeline, connect!
using Makie: generate_buffers, default_pipeline

@testset "Render RenderPipeline" begin

    @testset "BufferFormat" begin
        @testset "Constructors" begin
            f = BufferFormat()
            @test f.dims == 4
            @test f.type == BFT.float8
            @test isempty(f.extras)

            f = BufferFormat(1, Float16, a = 1, b = 2)
            @test f.dims == 1
            @test f.type == BFT.float16
            @test haskey(f.extras, :a) && (f.extras[:a] == 1)
            @test haskey(f.extras, :b) && (f.extras[:b] == 2)
            @test length(keys(f.extras)) == 2
        end

        types = [(N0f8, Float16, Float32), (Int8, Int16, Int32), (UInt8, UInt16, UInt32)]
        groups = [[BufferFormat(rand(1:4), T) for T in types[i]] for i in 1:3]

        @testset "is_compatible" begin
            # All types that should or should not be compatible
            for i in 1:3, j in 1:3
                for a in groups[i], b in groups[j]
                    @test (i == j) == is_compatible(a, b)
                    @test (i == j) == is_compatible(b, a)
                end
            end

            # extras
            @test is_compatible(BufferFormat(a = 1), BufferFormat())
            @test is_compatible(BufferFormat(a = 1), BufferFormat(a = 1))
            @test !is_compatible(BufferFormat(a = 1), BufferFormat(a = 2))
            @test is_compatible(BufferFormat(a = 1), BufferFormat(b = 2))
            @test !is_compatible(BufferFormat(2, Int8, a = 1), BufferFormat(b = 2))
            @test is_compatible(BufferFormat(2, Int8, a = 1), BufferFormat(1, Int32, b = 2, c = 3))
        end

        @testset "BufferFormat merging" begin
            for i in 1:3, j in 1:3
                for m in 1:3, n in 1:3
                    a = groups[i][m]; b = groups[j][n]
                    if i == j
                        expected = BufferFormat(max(a.dims, b.dims), types[i][max(m, n)])
                        @test BufferFormat(a, b) == expected
                        @test BufferFormat(b, a) == expected
                    else
                        @test_throws ErrorException BufferFormat(a, b)
                        @test_throws ErrorException BufferFormat(b, a)
                    end
                end
            end

            @test begin
                B = BufferFormat(BufferFormat(a = :a), BufferFormat())
                haskey(B.extras, :a) && (B.extras[:a] == :a)
            end
            @test begin
                B = BufferFormat(BufferFormat(2, N0f8, a = "s"), BufferFormat(3, Float16, a = "s"))
                haskey(B.extras, :a) && (B.extras[:a] == "s")
            end
            @test_throws ErrorException BufferFormat(BufferFormat(a = :a), BufferFormat(a = :b))
            @test_throws ErrorException BufferFormat(BufferFormat(a = :a), BufferFormat(a = 1))
        end
    end


    @testset "Stage" begin
        @test_throws MethodError Stage()
        @test Stage(:name) == Stage("name")
        stage = Stage(:test)
        @test stage.name == :test
        @test stage.inputs == Dict{Symbol, Int}()
        @test stage.outputs == Dict{Symbol, Int}()
        @test stage.input_formats == BufferFormat[]
        @test stage.output_formats == BufferFormat[]
        @test stage.attributes == Dict{Symbol, Any}()

        stage = Stage(:test,
            inputs = [:a => BufferFormat(), :b => BufferFormat(2)],
            outputs = [:c => BufferFormat(1, Int8)],
            attr = 17f0)
        @test stage.name == :test
        @test stage.inputs == Dict(:a => 1, :b => 2)
        @test stage.outputs == Dict(:c => 1)
        @test stage.input_formats == [BufferFormat(), BufferFormat(2)]
        @test stage.output_formats == [BufferFormat(1, Int8)]
        @test stage.attributes == Dict{Symbol, Any}(:attr => 17f0)

        @test get_input_format(stage, :a) == stage.input_formats[stage.inputs[:a]]
        @test get_output_format(stage, :c) == stage.output_formats[stage.outputs[:c]]
    end

    @testset "RenderPipeline & Connections" begin
        pipeline = RenderPipeline()

        @test isempty(pipeline.stages)
        @test isempty(pipeline.stageio2idx)
        @test isempty(pipeline.formats)

        stage1 = Stage(:stage1, outputs = [:a => BufferFormat(), :b => BufferFormat(2)])
        stage2 = Stage(:stage2,
            inputs = [:b => BufferFormat(2)],
            outputs = [:c => BufferFormat(1, Int16)],
            attr = 17f0)
        stage3 = Stage(:stage3, inputs = [:b => BufferFormat(4, Float16), :c => BufferFormat(2, Int8)])
        stage4 = Stage(:stage4, inputs = [:x => BufferFormat()], outputs = [:y => BufferFormat()])
        stage5 = Stage(:stage5, inputs = [:z => BufferFormat()])

        push!(pipeline, stage1)
        push!(pipeline, stage2)
        push!(pipeline, stage3)
        push!(pipeline, stage4)
        push!(pipeline, stage5)

        @test all(pipeline.stages .== [stage1, stage2, stage3, stage4, stage5])
        @test isempty(pipeline.stageio2idx)
        @test isempty(pipeline.formats)

        for _ in 1:2 # also verify that double-connect doesn't ruin things
            connect!(pipeline, stage1, stage2)

            @test length(pipeline.formats) == 1
            @test length(pipeline.stageio2idx) == 2
            @test pipeline.formats[end] == BufferFormat(2)
            @test pipeline.stageio2idx[(1, 2)] == 1
            @test pipeline.stageio2idx[(2, -1)] == 1
        end

        connect!(pipeline, stage2, stage3, :c)

        @test length(pipeline.formats) == 2
        @test length(pipeline.stageio2idx) == 4
        @test pipeline.formats[end] == BufferFormat(2, Int16)
        @test pipeline.stageio2idx[(2, 1)] == 2
        @test pipeline.stageio2idx[(3, -2)] == 2

        connect!(pipeline, stage1, stage3, :b)

        @test length(pipeline.formats) == 2
        @test length(pipeline.stageio2idx) == 5
        @test pipeline.formats[pipeline.stageio2idx[(1, 2)]] == BufferFormat(4, Float16)
        @test pipeline.stageio2idx[(1, 2)] == 1
        @test pipeline.stageio2idx[(2, -1)] == 1
        @test pipeline.stageio2idx[(3, -1)] == 1

        # Stage 1 incomplete - if output 2 is connected all previous outputs must be connected too
        @test_throws Exception generate_buffers(pipeline)

        connect!(pipeline, stage1, :a, stage4, :x)

        @test length(pipeline.formats) == 3
        @test length(pipeline.stageio2idx) == 7
        @test pipeline.formats[end] == BufferFormat()
        @test pipeline.stageio2idx[(1, 1)] == 3
        @test pipeline.stageio2idx[(4, -1)] == 3

        connect!(pipeline, stage4, :y, stage5, :z)

        @test length(pipeline.formats) == 4
        @test length(pipeline.stageio2idx) == 9
        @test pipeline.formats[end] == BufferFormat()
        @test pipeline.stageio2idx[(4, 1)] == 4
        @test pipeline.stageio2idx[(5, -1)] == 4

        #=
        1       2       3    4      5  (stages)
        a -----------------> x ---> z  (inputs outputs)
        b -+----------> b
           '-> b c ---> c
        =#
        buffers, remap = generate_buffers(pipeline)
        @test length(buffers) == 3 # 3 buffer textures are needed for transfers
        @test length(remap) == 4 # 4 connections map to them
        @test buffers[remap[1]] == pipeline.formats[1]
        @test buffers[remap[2]] == pipeline.formats[2]
        @test buffers[remap[3]] == pipeline.formats[3]
        # reuse from (4 x --> 5 z):
        # (1 a --> 4 x)     not yet available for reuse
        # (1 b --> 2 b, 3b) available, upgrades
        # (2 c --> 3 c)     not allowed, incompatible types (int16)
        @test buffers[remap[4]] == pipeline.formats[1]

        # text connecting two nodes that each have connections
        connect!(pipeline, stage1, :b, stage5, :z)

        @test length(pipeline.formats) == 3
        @test length(pipeline.stageio2idx) == 9
        @test pipeline.formats == [BufferFormat(4, Float16), BufferFormat(2, Int16), BufferFormat(4, N0f8)]
        for (k, v) in [(3, -1) => 1, (1, 2)  => 1, (1, 1)  => 3, (4, -1) => 3, (5, -1) => 1, (4, 1)  => 1, (2, -1) => 1, (2, 1)  => 2, (3, -2) => 2]
            @test pipeline.stageio2idx[k] == v
        end

        buffers, remap = generate_buffers(pipeline)
        @test length(buffers) == 3
        @test length(remap) == 3
        @test buffers[remap[1]] == pipeline.formats[1]
        @test buffers[remap[2]] == pipeline.formats[2]
        @test buffers[remap[3]] == pipeline.formats[3]
    end

    @testset "default pipeline" begin
        pipeline = default_pipeline()

        # These directly check what the call should construct. (This indirectly
        # also checks that connect!() works for pipelines)
        @test length(pipeline.stages) == 7
        @test pipeline.stages[1] == Stage(:ZSort)
        @test pipeline.stages[2] == Stage(:Render, Dict{Symbol, Int}(), BufferFormat[],
            Dict(:color => 1, :objectid => 2, :position => 3, :normal => 4),
            [BufferFormat(4, N0f8), BufferFormat(2, UInt32), BufferFormat(3, Float16), BufferFormat(3, Float16)],
            transparency = false)
        @test pipeline.stages[3] == Stage(Symbol("OIT Render"), Dict{Symbol, Int}(), BufferFormat[],
            Dict(:color_sum => 1, :objectid => 2, :transmittance => 3),
            [BufferFormat(4, Float16), BufferFormat(2, UInt32), BufferFormat(1, N0f8)])
        @test pipeline.stages[4] == Stage(:OIT,
            Dict(:color_sum => 1, :transmittance => 2), [BufferFormat(4, Float16), BufferFormat(1, N0f8)],
            Dict(:color => 1), [BufferFormat(4, N0f8)])
        @test pipeline.stages[5] == Stage(:FXAA1,
            Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            Dict(:color_luma => 1), [BufferFormat(4, N0f8)], filter_in_shader = true)
        @test pipeline.stages[6] == Stage(:FXAA2,
            Dict(:color_luma => 1), [BufferFormat(4, N0f8, minfilter = :linear)],
            Dict(:color => 1), [BufferFormat(4, N0f8)], filter_in_shader = true)
        @test pipeline.stages[7] == Stage(:Display,
            Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            Dict{Symbol, Int}(), BufferFormat[])

        # Note: Order technically irrelevant but it's easier to test with order
        # Same for inputs and outputs here
        @test length(pipeline.formats) == 6
        @test length(pipeline.stageio2idx) == 15
        @test pipeline.formats[pipeline.stageio2idx[(5,  1)]] == BufferFormat(4, N0f8, minfilter = :linear)
        @test pipeline.formats[pipeline.stageio2idx[(6, -1)]] == BufferFormat(4, N0f8, minfilter = :linear)
        @test pipeline.formats[pipeline.stageio2idx[(3, 1)]] == BufferFormat(4, Float16)
        @test pipeline.formats[pipeline.stageio2idx[(4, -1)]] == BufferFormat(4, Float16)
        @test pipeline.formats[pipeline.stageio2idx[(3, 3)]] == BufferFormat(1, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(4, -2)]] == BufferFormat(1, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(4, 1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(2, 1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(5, -1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(3, 2)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(2, 2)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(7, -2)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(5, -2)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(6, 1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(7, -1)]] == BufferFormat(4, N0f8)

        # Verify buffer generation with this more complex example
        buffers, remap = generate_buffers(pipeline)

        # Order in buffers irrelevant as long as the mapping works
        # Note: all outputs are unique so we don't have to explicitly test
        #       which one we hit
        # Note: Changes to generate_buffers could change how formats get merged
        #       and cause different correct results
        @test length(buffers) == 4
        @test length(remap) == 6

        @test buffers[remap[pipeline.stageio2idx[(5,  1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(6, -1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(3, 1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(4, -1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(3, 3)]]] == BufferFormat(1, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(4, -2)]]] == BufferFormat(1, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(4, 1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(2, 1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(5, -1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(3, 2)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(2, 2)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(7, -2)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(5, -2)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(6, 1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(7, -1)]]] == BufferFormat(4, N0f8)
    end
end