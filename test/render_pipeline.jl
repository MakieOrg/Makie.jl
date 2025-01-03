using Makie
using Makie: BufferFormat, N0f8, is_compatible, BFT
using Makie: Stage, get_input_connection, get_output_connection, get_input_format, get_output_format
using Makie: Connection, Pipeline, connect!
using Makie: generate_buffers, default_pipeline

@testset "Render Pipeline" begin

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
        @test stage.input_connections == Connection[]
        @test stage.output_connections == Connection[]
        @test stage.attributes == NamedTuple()

        stage = Stage(:test,
            inputs = [:a => BufferFormat(), :b => BufferFormat(2)],
            outputs = [:c => BufferFormat(1, Int8)],
            attr = 17f0)
        @test stage.name == :test
        @test stage.inputs == Dict(:a => 1, :b => 2)
        @test stage.outputs == Dict(:c => 1)
        @test stage.input_formats == [BufferFormat(), BufferFormat(2)]
        @test stage.output_formats == [BufferFormat(1, Int8)]
        @test stage.input_connections == Connection[]
        @test stage.output_connections == Connection[]
        @test stage.attributes == (attr = 17f0,)

        @test get_input_format(stage, :a) == stage.input_formats[stage.inputs[:a]]
        @test get_output_format(stage, :c) == stage.output_formats[stage.outputs[:c]]
    end

    @testset "Pipeline & Connections" begin
        pipeline = Pipeline()

        @test isempty(pipeline.stages)
        @test isempty(pipeline.connections)

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
        @test isempty(pipeline.connections)

        connect!(pipeline, stage1, stage2)

        @test length(pipeline.connections) == 1
        c1 = pipeline.connections[end]
        @test c1.format == BufferFormat(2)
        @test c1.inputs == [stage1 => 2]
        @test c1.outputs == [stage2 => 1]
        @test stage1.output_connections[2] == c1
        @test stage2.input_connections[1] == c1

        connect!(pipeline, stage2, stage3, :c)

        @test length(pipeline.connections) == 2
        c2 = pipeline.connections[end]
        @test c2.format == BufferFormat(2, Int16)
        @test c2.inputs == [stage2 => 1]
        @test c2.outputs == [stage3 => 2]
        @test stage2.output_connections[1] == c2
        @test stage3.input_connections[2] == c2

        connect!(pipeline, stage1, stage3, :b)

        @test length(pipeline.connections) == 2
        c3 = pipeline.connections[end]
        @test c1 !== c3
        @test c2 !== c3
        @test c3.format == BufferFormat(4, Float16)
        @test c3.inputs == [stage1 => 2]
        @test c3.outputs == [stage3 => 1, stage2 => 1] # technically order irrelevant
        @test stage1.output_connections[2] == c3
        @test stage2.input_connections[1] == c3
        @test stage3.input_connections[1] == c3

        # Stage 1 incomplete - if output 2 is connected all previous outputs must be connected too
        @test_throws Exception generate_buffers(pipeline)

        connect!(pipeline, stage1, :a, stage4, :x)

        @test length(pipeline.connections) == 3
        c4 = pipeline.connections[end]
        @test c4.format == BufferFormat()
        @test c4.inputs == [stage1 => 1]
        @test c4.outputs == [stage4 => 1]
        @test stage1.output_connections[1] == c4
        @test stage4.input_connections[1] == c4

        connect!(pipeline, stage4, :y, stage5, :z)

        @test length(pipeline.connections) == 4
        c5 = pipeline.connections[end]
        @test c5.format == BufferFormat()
        @test c5.inputs == [stage4 => 1]
        @test c5.outputs == [stage5 => 1]
        @test stage4.output_connections[1] == c5
        @test stage5.input_connections[1] == c5

        #=
        1       2       3    4      5  (stages)
        a -----------------> x ---> z  (inputs outputs)
        b -+----------> b
           '-> b c ---> c
        =#
        buffers, conn2idx = generate_buffers(pipeline)
        @test length(buffers) == 3 # 3 buffer textures are needed for transfers
        @test length(conn2idx) == 4 # 4 connections map to them
        @test buffers[conn2idx[c2]] == c2.format
        @test buffers[conn2idx[c3]] == c3.format
        @test buffers[conn2idx[c4]] == c4.format
        # 1 a --> 4 x not yet available for reuse
        # 1 b --> 2 b, 3b available, upgrades
        # 2 c --> 3 c not allowed, incompatible types
        @test buffers[conn2idx[c5]] == c3.format
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
        @test pipeline.stages[3] == Stage(:TransparentRender, Dict{Symbol, Int}(), BufferFormat[],
            Dict(:weighted_color_sum => 1, :objectid => 2, :alpha_product => 3),
            [BufferFormat(4, Float16), BufferFormat(2, UInt32), BufferFormat(1, N0f8)])
        @test pipeline.stages[4] == Stage(:OIT,
            Dict(:weighted_color_sum => 1, :alpha_product => 2), [BufferFormat(4, Float16), BufferFormat(1, N0f8)],
            Dict(:color => 1), [BufferFormat(4, N0f8)])
        @test pipeline.stages[5] == Stage(:FXAA1,
            Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            Dict(:color_luma => 1), [BufferFormat(4, N0f8)])
        @test pipeline.stages[6] == Stage(:FXAA2,
            Dict(:color_luma => 1), [BufferFormat(4, N0f8, minfilter = :linear)],
            Dict(:color => 1), [BufferFormat(4, N0f8)])
        @test pipeline.stages[7] == Stage(:Display,
            Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            Dict{Symbol, Int}(), BufferFormat[])

        # Note: Order technically irrelevant but it's easier to test with order
        # Same for inputs and outputs here
        @test length(pipeline.connections) == 6
        stage1, stage2, stage3, stage4, stage5, stage6, stage7 = pipeline.stages
        @test pipeline.connections[1] == Connection([stage5 => 1], [stage6 => 1], BufferFormat(4, N0f8, minfilter = :linear))
        @test pipeline.connections[2] == Connection([stage3 => 1], [stage4 => 1], BufferFormat(4, Float16))
        @test pipeline.connections[3] == Connection([stage3 => 3], [stage4 => 2], BufferFormat(1, N0f8))
        @test pipeline.connections[4] == Connection([stage4 => 1, stage2 => 1], [stage5 => 1], BufferFormat(4, N0f8))
        @test pipeline.connections[5] == Connection([stage3 => 2, stage2 => 2], [stage7 => 2, stage5 => 2], BufferFormat(2, UInt32))
        @test pipeline.connections[6] == Connection([stage6 => 1], [stage7 => 1], BufferFormat(4, N0f8))

        # Verify buffer generation with this more complex example
        buffers, conn2idx = generate_buffers(pipeline)

        # Order irrelevant
        @test length(buffers) == 4
        formats = [
            :color => BufferFormat(), :objectid => BufferFormat(2, UInt32), :weight => BufferFormat(1, N0f8),
            :HDR => BufferFormat(4, Float16, minfilter = :linear)
        ]
        lookup = Dict{Symbol, Int}()
        for (name, format) in formats
            idx = findfirst(==(format), buffers)
            @test idx !== nothing
            lookup[name] = idx::Int
        end
        # Sanity check for assumption that none of the formats are equal
        @test sum(values(lookup)) == 1 + 2 + 3 + 4

        @test length(conn2idx) == 6
        @test conn2idx[pipeline.connections[1]] == lookup[:HDR]
        @test conn2idx[pipeline.connections[2]] == lookup[:HDR] # compatible and no overlap with connection (1)
        @test conn2idx[pipeline.connections[3]] == lookup[:weight]
        @test conn2idx[pipeline.connections[4]] == lookup[:color]
        @test conn2idx[pipeline.connections[5]] == lookup[:objectid]
        @test conn2idx[pipeline.connections[6]] == lookup[:color] # compatible and no overlap with (4)
    end
end