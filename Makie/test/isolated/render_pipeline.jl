using Makie
using Makie: BufferFormat, N0f8, is_compatible, BFT
using Makie: RenderStage, get_input_format, get_output_format
using Makie: RenderPipeline, connect!
using Makie: generate_buffers, default_pipeline

@testset "Render RenderPipeline" begin

    @testset "BufferFormat" begin
        @testset "Constructors" begin
            f = BufferFormat()
            @test f.dims == 4
            @test f.type == BFT.float8
            @test f.minfilter == :any
            @test f.magfilter == :any
            @test f.repeat == (:clamp_to_edge, :clamp_to_edge)
            @test f.mipmap == false
            @test f.samples == 1

            f = BufferFormat(
                1, Float16, minfilter = :linear, magfilter = :nearest,
                mipmap = true, repeat = :repeat, samples = 4
            )
            @test f.dims == 1
            @test f.type == BFT.float16
            @test f.minfilter == :linear
            @test f.magfilter == :nearest
            @test f.repeat == (:repeat, :repeat)
            @test f.mipmap == true
            @test f.samples == 4
        end

        stencil_types = (BFT.stencil, BFT.depth24_stencil, BFT.depth32_stencil)
        depth_types = (BFT.depth16, BFT.depth24, BFT.depth32, BFT.depth24_stencil, BFT.depth32_stencil)
        types = [
            (N0f8, Float16, Float32),
            (Int8, Int16, Int32),
            (UInt8, UInt16, UInt32),
            depth_types,
        ]

        groups = [[BufferFormat(rand(1:4), T) for T in types[i]] for i in 1:3]
        # more than 1D makes no sense for these
        for i in 4:length(types)
            push!(groups, [BufferFormat(1, T) for T in types[i]])
        end
        stencil_group = [BufferFormat(1, T) for T in stencil_types]

        @testset "is_compatible" begin
            # All types that should or should not be compatible
            for i in eachindex(groups), j in eachindex(groups)
                for a in groups[i], b in groups[j]
                    @test (i == j) == is_compatible(a, b)
                    @test (i == j) == is_compatible(b, a)
                end
            end

            for i in 1:3
                for a in groups[i], b in stencil_group
                    @test !is_compatible(a, b)
                    @test !is_compatible(b, a)
                end
            end
            for a in groups[end][1:3]
                b = BufferFormat(1, BFT.stencil)
                @test !is_compatible(a, b)
                @test !is_compatible(b, a)
            end

            for a in stencil_group, b in stencil_group
                @test is_compatible(a, b)
                @test is_compatible(b, a)
            end

            # extras
            @test  is_compatible(BufferFormat(mipmap = true), BufferFormat(mipmap = false))
            @test !is_compatible(BufferFormat(samples = 1), BufferFormat(samples = 4))

            @test  is_compatible(BufferFormat(repeat = :repeat), BufferFormat(repeat = :repeat))
            @test !is_compatible(BufferFormat(repeat = :repeat), BufferFormat(repeat = :clamp_to_egde))

            @test  is_compatible(BufferFormat(minfilter = :any), BufferFormat(minfilter = :any))
            @test  is_compatible(BufferFormat(minfilter = :any), BufferFormat(minfilter = :linear))
            @test  is_compatible(BufferFormat(minfilter = :linear), BufferFormat(minfilter = :linear))
            @test !is_compatible(BufferFormat(minfilter = :nearest), BufferFormat(minfilter = :linear))

            @test  is_compatible(BufferFormat(magfilter = :any), BufferFormat(magfilter = :any))
            @test  is_compatible(BufferFormat(magfilter = :any), BufferFormat(magfilter = :linear))
            @test  is_compatible(BufferFormat(magfilter = :linear), BufferFormat(magfilter = :linear))
            @test !is_compatible(BufferFormat(magfilter = :nearest), BufferFormat(magfilter = :linear))

            @test  is_compatible(BufferFormat(2, Int8, minfilter = :any, magfilter = :linear), BufferFormat(1, Int32, minfilter = :nearest))
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

            # No merging base type with stencil or depth types
            for i in 1:3
                # base types - stencil types
                for a in groups[i], b in stencil_group
                    @test_throws ErrorException BufferFormat(a, b)
                    @test_throws ErrorException BufferFormat(b, a)
                end
                # base types - depth types
                for a in groups[i], b in groups[end]
                    @test_throws ErrorException BufferFormat(a, b)
                    @test_throws ErrorException BufferFormat(b, a)
                end
            end
            # depth types - stencil types
            for a in groups[end][1:3]
                b = stencil_group[1]
                @test_throws ErrorException BufferFormat(a, b)
                @test_throws ErrorException BufferFormat(b, a)
            end

            # stencil is allowed to become depth_stencil
            for (m, a) in enumerate(stencil_group), (n, b) in enumerate(stencil_group)
                expected = BufferFormat(1, stencil_types[max(m, n)])
                @test BufferFormat(a, b) == expected
                @test BufferFormat(b, a) == expected
            end

            # depth is allowed to become depth_stencil (right types win)
            depth_types = [
                (BFT.depth16, BFT.depth24, BFT.depth24_stencil),
                (BFT.depth16, BFT.depth24, BFT.depth32, BFT.depth32_stencil),
                (BFT.depth24_stencil, BFT.depth32_stencil),
            ]
            depth_groups = [[BufferFormat(1, T) for T in group] for group in depth_types]

            for (i, group) in enumerate(depth_groups)
                for (m, a) in enumerate(group), (n, b) in enumerate(group)
                    expected = BufferFormat(1, depth_types[i][max(m, n)])
                    @test BufferFormat(a, b) == expected
                    @test BufferFormat(b, a) == expected
                end
            end

            a = BufferFormat(minfilter = :any, magfilter = :any, mipmap = false)
            b = BufferFormat(minfilter = :linear, magfilter = :nearest, mipmap = true)
            B = BufferFormat(a, b)
            @test B.minfilter == :linear
            @test B.magfilter == :nearest
            @test B.mipmap

            B = BufferFormat(b, a)
            @test B.minfilter == :linear
            @test B.magfilter == :nearest
            @test B.mipmap

            a = BufferFormat(minfilter = :nearest, magfilter = :linear, mipmap = true, repeat = :repeat)
            b = BufferFormat(minfilter = :nearest, magfilter = :linear, mipmap = true, repeat = :repeat)
            B = BufferFormat(a, b)
            @test B.minfilter == :nearest
            @test B.magfilter == :linear
            @test B.mipmap
            @test B.repeat == (:repeat, :repeat)

            @test_throws ErrorException BufferFormat(BufferFormat(repeat = :a), BufferFormat(repeat = :b))
            @test_throws ErrorException BufferFormat(BufferFormat(minfilter = :a), BufferFormat(minfilter = :b))
            @test_throws ErrorException BufferFormat(BufferFormat(magfilter = :a), BufferFormat(magfilter = :b))
        end
    end


    @testset "RenderStage" begin
        @test_throws MethodError RenderStage()
        @test RenderStage(:name) == RenderStage("name")
        stage = RenderStage(:test)
        @test stage.name == :test
        @test stage.inputs == Dict{Symbol, Int}()
        @test stage.outputs == Dict{Symbol, Int}()
        @test stage.input_formats == BufferFormat[]
        @test stage.output_formats == BufferFormat[]
        @test stage.attributes == Dict{Symbol, Any}()

        stage = RenderStage(
            :test,
            inputs = [:a => BufferFormat(), :b => BufferFormat(2)],
            outputs = [:c => BufferFormat(1, Int8)],
            attr = 17.0f0, samples = 4
        )
        @test stage.name == :test
        @test stage.inputs == Dict(:a => 1, :b => 2)
        @test stage.outputs == Dict(:c => 1)
        @test stage.input_formats == [BufferFormat(), BufferFormat(2)]
        @test stage.output_formats == [BufferFormat(1, Int8, samples = 4)]
        @test stage.attributes == Dict{Symbol, Any}(:attr => 17.0f0)

        @test get_input_format(stage, :a) == stage.input_formats[stage.inputs[:a]]
        @test get_output_format(stage, :c) == stage.output_formats[stage.outputs[:c]]
    end

    function check_lowered_representation(pipeline, buffers, mapping)
        # lowered representation applies the mapping so that backends don't
        # have to deal with it
        lp = Makie.LoweredRenderPipeline(pipeline)
        @test lp.formats == buffers
        @test length(lp.stages) == length(pipeline.stages)

        for (stage_idx, old_stage) in enumerate(pipeline.stages)
            new_stage = lp.stages[stage_idx]

            # Every input and output that is connected should continue to exist
            # in the lowered pipeline. It is connected if it has a format in
            # `pipeline.formats` associated to it via `pipeline.stageio2idx`
            input_names = first.(
                sort!(
                    filter!(collect(pairs(old_stage.inputs))) do (name, idx)
                        haskey(pipeline.stageio2idx, (stage_idx, -idx))
                    end, by = last
                )
            )

            @test length(input_names) == length(new_stage.inputs)

            for (j, (name, new_idx)) in enumerate(new_stage.inputs)
                # `pipeline.stageio2idx[(stage_idx, -j)]` is the index into the
                # unoptimized `pipeline.formats`. `mapping` converts that to an
                # index into the optimized `buffers`, which mirrors the index
                # in the lowered pipeline pointing into `lp.formats`
                @test new_idx == mapping[pipeline.stageio2idx[(stage_idx, -j)]]
                @test name == input_names[j]
            end

            output_names = first.(
                sort!(
                    filter!(collect(pairs(old_stage.outputs))) do (name, idx)
                        haskey(pipeline.stageio2idx, (stage_idx, idx))
                    end, by = last
                )
            )

            @test length(output_names) == length(new_stage.outputs)

            for (j, (name, new_idx)) in enumerate(new_stage.outputs)
                @test new_idx == mapping[pipeline.stageio2idx[(stage_idx, j)]]
                @test name == output_names[j]
            end
        end
        return
    end

    @testset "RenderPipeline & Connections" begin
        pipeline = RenderPipeline()

        @test isempty(pipeline.stages)
        @test isempty(pipeline.stageio2idx)
        @test isempty(pipeline.formats)

        stage1 = RenderStage(:stage1, outputs = [:a => BufferFormat(), :b => BufferFormat(2)])
        stage2 = RenderStage(
            :stage2,
            inputs = [:b => BufferFormat(2)],
            outputs = [:c => BufferFormat(1, Int16)],
            attr = 17.0f0
        )
        stage3 = RenderStage(:stage3, inputs = [:b => BufferFormat(4, Float16), :c => BufferFormat(2, Int8)])
        stage4 = RenderStage(:stage4, inputs = [:x => BufferFormat()], outputs = [:y => BufferFormat()])
        stage5 = RenderStage(:stage5, inputs = [:z => BufferFormat()])

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

        # RenderStage 1 incomplete - if output 2 is connected all previous outputs must be connected too
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
        for (k, v) in [(3, -1) => 1, (1, 2) => 1, (1, 1) => 3, (4, -1) => 3, (5, -1) => 1, (4, 1) => 1, (2, -1) => 1, (2, 1) => 2, (3, -2) => 2]
            @test pipeline.stageio2idx[k] == v
        end

        buffers, remap = generate_buffers(pipeline)
        @test length(buffers) == 3
        @test length(remap) == 3
        @test buffers[remap[1]] == pipeline.formats[1]
        @test buffers[remap[2]] == pipeline.formats[2]
        @test buffers[remap[3]] == pipeline.formats[3]

        check_lowered_representation(pipeline, buffers, remap)
    end

    @testset "RenderPipeline resolution" begin
        @testset "sanity checks" begin
            # Nothing to generate in an empty pipeline
            pipeline = RenderPipeline()
            buffers, mapping = generate_buffers(pipeline)
            @test isempty(buffers)
            @test isempty(mapping)

            # no connections means no buffer usage
            push!(pipeline, Makie.PlotRenderStage())
            push!(pipeline, Makie.DisplayStage())
            buffers, mapping = generate_buffers(pipeline)
            @test isempty(buffers)
            @test isempty(mapping)

            # direct connection between two stages without any type changes or reuse
            pipeline = RenderPipeline()
            render = push!(pipeline, Makie.PlotRenderStage())
            display = push!(pipeline, Makie.DisplayStage())
            connect!(pipeline, render, display)
            buffers, mapping = generate_buffers(pipeline)
            @test length(buffers) == 3
            @test length(mapping) == 3
            @test buffers[mapping[pipeline.stageio2idx[(1, 1)]]] == Makie.get_output_format(render, :depth)
            @test buffers[mapping[pipeline.stageio2idx[(1, 2)]]] == Makie.get_output_format(render, :color)
            @test buffers[mapping[pipeline.stageio2idx[(1, 3)]]] == Makie.get_output_format(render, :objectid)
            @test buffers[mapping[pipeline.stageio2idx[(2, -1)]]] == Makie.get_input_format(display, :depth)
            @test buffers[mapping[pipeline.stageio2idx[(2, -2)]]] == Makie.get_input_format(display, :color)
            @test buffers[mapping[pipeline.stageio2idx[(2, -3)]]] == Makie.get_input_format(display, :objectid)

            check_lowered_representation(pipeline, buffers, mapping)
        end

        @testset "Verify complete-output-usage check" begin
            pipeline = RenderPipeline()
            stage1 = Makie.RenderStage(
                :first,
                outputs = [:dropped => BufferFormat(3, N0f8), :color => BufferFormat(3, N0f8)]
            )
            stage2 = Makie.RenderStage(
                :second,
                inputs = [:color => BufferFormat(3, N0f8)]
            )
            push!(pipeline, stage1, stage2)
            # connects color -> color, leaving dropped. This is not allowed to remain
            connect!(pipeline, stage1, stage2)
            @test_throws ErrorException generate_buffers(pipeline)
        end

        function build_pipeline(connections...)
            pipeline = RenderPipeline()

            stages = [Makie.RenderStage(:stage1, outputs = first(connections))]
            for i in 2:length(connections)
                stage = Makie.RenderStage(
                    Symbol(:stage, i),
                    inputs = connections[i - 1], outputs = connections[i]
                )
                push!(stages, stage)
            end
            push!(stages, Makie.RenderStage(Symbol(:stage, length(connections) + 1), inputs = last(connections)))

            push!(pipeline, stages...)
            for i in eachindex(connections)
                connect!(pipeline, stages[i], stages[i + 1])
            end

            return pipeline
        end

        @testset "Exact type reuse" begin
            conn1 = [:f8 => BufferFormat(3, N0f8), :f16 => BufferFormat(3, Float16), :f32 => BufferFormat(3, Float32)]
            conn2 = [:trans => BufferFormat(3, N0f8)]
            conn3 = [:out => BufferFormat(3, Float16)]

            for _ in 1:2
                pipeline = build_pipeline(conn1, conn2, conn3)
                @test length(pipeline.formats) == 5 # no reuse here

                # trans is not allowed to reuse anything from conn1, but :out is and should
                buffers, mapping = generate_buffers(pipeline)
                @test length(buffers) == 4

                # verify types (specifically the last one which should not pick Float32)
                for i in eachindex(conn1)
                    @test buffers[mapping[pipeline.stageio2idx[(1, i)]]] == conn1[i][2]
                end
                @test buffers[mapping[pipeline.stageio2idx[(2, 1)]]] == conn2[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(3, 1)]]] == conn3[1][2]

                # verify correct reuse
                unique_buffer_idxs = [
                    mapping[pipeline.stageio2idx[(1, 1)]]
                    mapping[pipeline.stageio2idx[(1, 2)]]
                    mapping[pipeline.stageio2idx[(1, 3)]]
                    mapping[pipeline.stageio2idx[(2, 1)]]
                ]
                @test allunique(unique_buffer_idxs) # these do not reuse
                @test mapping[pipeline.stageio2idx[(3, 1)]] in unique_buffer_idxs # :out does
                @test mapping[pipeline.stageio2idx[(3, 1)]] == unique_buffer_idxs[2] # reuses Float16 buffer

                check_lowered_representation(pipeline, buffers, mapping)

                # retest with different buffer order in first stage
                reverse!(conn1)
            end
        end

        # Here the exact match Float16 does not exist, but a buffer with a larger
        # element type still exists (Float32). It should be picked
        @testset "Big type reuse" begin
            conn1 = [:f8 => BufferFormat(3, N0f8), :f32 => BufferFormat(3, Float32)]
            conn2 = [:trans => BufferFormat(3, N0f8)]
            conn3 = [:out => BufferFormat(3, Float16)]

            for picked_idx in (2, 1)
                pipeline = build_pipeline(conn1, conn2, conn3)
                @test length(pipeline.formats) == 4

                buffers, mapping = generate_buffers(pipeline)
                @test length(buffers) == 3

                for i in eachindex(conn1)
                    @test buffers[mapping[pipeline.stageio2idx[(1, i)]]] == conn1[i][2]
                end
                @test buffers[mapping[pipeline.stageio2idx[(2, 1)]]] == conn2[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(3, 1)]]] == BufferFormat(3, Float32)
                # ^ type is now Float32

                unique_buffer_idxs = [
                    mapping[pipeline.stageio2idx[(1, 1)]]
                    mapping[pipeline.stageio2idx[(1, 2)]]
                    mapping[pipeline.stageio2idx[(2, 1)]]
                ]
                @test allunique(unique_buffer_idxs)
                @test mapping[pipeline.stageio2idx[(3, 1)]] in unique_buffer_idxs
                @test mapping[pipeline.stageio2idx[(3, 1)]] == unique_buffer_idxs[picked_idx]
                # ^ reuses Float32 buffer from conn1 (last in iteration 1, first in interation 2)

                check_lowered_representation(pipeline, buffers, mapping)

                reverse!(conn1)
            end
        end

        # Now we target Float32 without an existing Float32 buffer. It is cheaper
        # to expand 3x Float16 -> 3x Float32 (+48 bits per fragment) than to add
        # a new buffer (+96 bits per fragment) so that should happen
        @testset "Type widening reuse" begin
            conn1 = [:f8 => BufferFormat(3, N0f8), :f16 => BufferFormat(3, Float16)]
            conn2 = [:trans => BufferFormat(3, N0f8)]
            conn3 = [:out => BufferFormat(3, Float32)]

            for picked_idx in (2, 1)
                pipeline = build_pipeline(conn1, conn2, conn3)
                @test length(pipeline.formats) == 4

                buffers, mapping = generate_buffers(pipeline)
                @test length(buffers) == 3

                @test buffers[mapping[pipeline.stageio2idx[(1, 3 - picked_idx)]]] == BufferFormat(3, N0f8)
                @test buffers[mapping[pipeline.stageio2idx[(1, picked_idx)]]] == BufferFormat(3, Float32)
                @test buffers[mapping[pipeline.stageio2idx[(2, 1)]]] == conn2[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(3, 1)]]] == conn3[1][2]

                unique_buffer_idxs = [
                    mapping[pipeline.stageio2idx[(1, 1)]]
                    mapping[pipeline.stageio2idx[(1, 2)]]
                    mapping[pipeline.stageio2idx[(2, 1)]]
                ]
                @test allunique(unique_buffer_idxs)
                @test mapping[pipeline.stageio2idx[(3, 1)]] in unique_buffer_idxs
                @test mapping[pipeline.stageio2idx[(3, 1)]] == unique_buffer_idxs[picked_idx]

                check_lowered_representation(pipeline, buffers, mapping)

                reverse!(conn1)
            end
        end

        # Right type but too few channels. Buffer should get another channel
        @testset "element widening reuse" begin
            conn1 = [:f8 => BufferFormat(3, N0f8), :f16 => BufferFormat(3, Float16), :f32 => BufferFormat(3, Float32)]
            conn2 = [:trans => BufferFormat(3, N0f8)]
            conn3 = [:out => BufferFormat(4, Float16)] # 4 channels

            for _ in 1:2
                pipeline = build_pipeline(conn1, conn2, conn3)
                @test length(pipeline.formats) == 5

                buffers, mapping = generate_buffers(pipeline)
                @test length(buffers) == 4

                @test buffers[mapping[pipeline.stageio2idx[(1, 1)]]] == conn1[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(1, 2)]]] == BufferFormat(4, Float16)
                @test buffers[mapping[pipeline.stageio2idx[(1, 3)]]] == conn1[3][2]
                @test buffers[mapping[pipeline.stageio2idx[(2, 1)]]] == conn2[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(3, 1)]]] == conn3[1][2]

                unique_buffer_idxs = [
                    mapping[pipeline.stageio2idx[(1, 1)]]
                    mapping[pipeline.stageio2idx[(1, 2)]]
                    mapping[pipeline.stageio2idx[(1, 3)]]
                    mapping[pipeline.stageio2idx[(2, 1)]]
                ]
                @test allunique(unique_buffer_idxs)
                @test mapping[pipeline.stageio2idx[(3, 1)]] in unique_buffer_idxs
                @test mapping[pipeline.stageio2idx[(3, 1)]] == unique_buffer_idxs[2]

                check_lowered_representation(pipeline, buffers, mapping)

                reverse!(conn1)
            end
        end

        # Two Float16 buffers are needed here, but only one is available. The
        # other one will need to use the FLoat32 buffer
        @testset "no duplicate reuse" begin
            conn1 = [:f8 => BufferFormat(3, N0f8), :f16 => BufferFormat(3, Float16), :f32 => BufferFormat(3, Float32)]
            conn2 = [:trans => BufferFormat(3, N0f8)]
            conn3 = [:out1 => BufferFormat(3, Float16), :out2 => BufferFormat(3, Float16)]

            for picked_idx in (3, 1)
                for _ in 1:2
                    pipeline = build_pipeline(conn1, conn2, conn3)
                    @test length(pipeline.formats) == 6

                    # 2 reused
                    buffers, mapping = generate_buffers(pipeline)
                    @test length(buffers) == 4

                    for i in 1:3
                        @test buffers[mapping[pipeline.stageio2idx[(1, i)]]] == conn1[i][2]
                    end
                    @test buffers[mapping[pipeline.stageio2idx[(2, 1)]]] == conn2[1][2]
                    # Either :out1 must reuse :f32 or :out2 must do it. The other must use :f16
                    out1_buffer = buffers[mapping[pipeline.stageio2idx[(3, 1)]]]
                    out2_buffer = buffers[mapping[pipeline.stageio2idx[(3, 2)]]]
                    @test (out1_buffer == conn1[2][2] && out2_buffer == conn1[picked_idx][2]) ||
                        (out2_buffer == conn1[2][2] && out1_buffer == conn1[picked_idx][2])

                    unique_buffer_idxs = [
                        mapping[pipeline.stageio2idx[(1, 1)]]
                        mapping[pipeline.stageio2idx[(1, 2)]]
                        mapping[pipeline.stageio2idx[(1, 3)]]
                        mapping[pipeline.stageio2idx[(2, 1)]]
                    ]
                    @test allunique(unique_buffer_idxs)
                    @test mapping[pipeline.stageio2idx[(3, 1)]] in unique_buffer_idxs
                    @test mapping[pipeline.stageio2idx[(3, 2)]] in unique_buffer_idxs
                    # Same as above
                    out1_idx = mapping[pipeline.stageio2idx[(3, 1)]]
                    out2_idx = mapping[pipeline.stageio2idx[(3, 2)]]
                    @test (out1_idx == unique_buffer_idxs[2] && out2_idx == unique_buffer_idxs[picked_idx]) ||
                        (out2_idx == unique_buffer_idxs[2] && out1_idx == unique_buffer_idxs[picked_idx])

                    check_lowered_representation(pipeline, buffers, mapping)

                    reverse!(conn3)
                end

                reverse!(conn1)
            end
        end

        # A buffer does not stop being in use once it's used as input. That's
        # controlled by the connections of the pipeline. Here the :f8 and :f16
        # buffers are still in use and :trans is not yet free, so a new buffer is needed
        @testset "don't reuse what's in use" begin
            conn1 = [:f8 => BufferFormat(3, N0f8), :f16 => BufferFormat(3, Float16)]
            conn2 = [:trans => BufferFormat(3, N0f8)]
            conn3 = [:out1 => BufferFormat(3, Float16)]

            for picked_idx in (3, 1)
                pipeline = build_pipeline(conn1, conn2, conn3)
                stage1 = first(pipeline.stages)
                stage5 = push!(pipeline, RenderStage(:stage5, inputs = conn1))
                connect!(pipeline, stage1, stage5)
                # stage5 doesn't add anything new because it connects with stage1
                @test length(pipeline.formats) == 4

                buffers, mapping = generate_buffers(pipeline)
                @test length(buffers) == 4

                @test buffers[mapping[pipeline.stageio2idx[(1, 1)]]] == conn1[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(1, 2)]]] == conn1[2][2]
                @test buffers[mapping[pipeline.stageio2idx[(2, 1)]]] == conn2[1][2]
                @test buffers[mapping[pipeline.stageio2idx[(3, 1)]]] == conn3[1][2]

                # no buffer reuse, so every pipeline.format index maps to a
                # unique index in buffers
                @test allunique(mapping)

                check_lowered_representation(pipeline, buffers, mapping)

                reverse!(conn1)
            end
        end
    end

    @testset "default pipeline" begin
        pipeline = default_pipeline()

        # These directly check what the call should construct. (This indirectly
        # also checks that connect!() works for pipelines)
        @test length(pipeline.stages) == 7
        @test pipeline.stages[1] == RenderStage(:ZSort)
        @test pipeline.stages[2] == RenderStage(
            :Render, Dict{Symbol, Int}(), BufferFormat[],
            Dict(:depth => 1, :color => 2, :objectid => 3),
            [BufferFormat(1, BFT.depth24), BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            transparency = false
        )
        @test pipeline.stages[3] == RenderStage(
            Symbol("OIT Render"), Dict{Symbol, Int}(), BufferFormat[],
            Dict(:depth => 1, :color_sum => 2, :objectid => 3, :transmittance => 4),
            [BufferFormat(1, BFT.depth24), BufferFormat(4, Float16), BufferFormat(2, UInt32), BufferFormat(1, N0f8)]
        )
        @test pipeline.stages[4] == RenderStage(
            :OIT,
            Dict(:color_sum => 1, :transmittance => 2), [BufferFormat(4, Float16), BufferFormat(1, N0f8)],
            Dict(:color => 1), [BufferFormat(4, N0f8)]
        )
        @test pipeline.stages[5] == RenderStage(
            :FXAA1,
            Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            Dict(:color_luma => 1), [BufferFormat(4, N0f8)], filter_in_shader = true
        )
        @test pipeline.stages[6] == RenderStage(
            :FXAA2,
            Dict(:color_luma => 1), [BufferFormat(4, N0f8, minfilter = :linear)],
            Dict(:color => 1), [BufferFormat(4, N0f8)], filter_in_shader = true
        )
        @test pipeline.stages[7] == RenderStage(
            :Display,
            Dict(:depth => 1, :color => 2, :objectid => 3),
            [BufferFormat(1, BFT.depth24), BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
            Dict{Symbol, Int}(), BufferFormat[]
        )

        # Note: Order technically irrelevant but it's easier to test with order
        # Same for inputs and outputs here
        @test length(pipeline.formats) == 7
        @test length(pipeline.stageio2idx) == 18
        @test pipeline.formats[pipeline.stageio2idx[(5, 1)]] == BufferFormat(4, N0f8, minfilter = :linear)
        @test pipeline.formats[pipeline.stageio2idx[(6, -1)]] == BufferFormat(4, N0f8, minfilter = :linear)
        @test pipeline.formats[pipeline.stageio2idx[(3, 2)]] == BufferFormat(4, Float16)
        @test pipeline.formats[pipeline.stageio2idx[(4, -1)]] == BufferFormat(4, Float16)
        @test pipeline.formats[pipeline.stageio2idx[(3, 4)]] == BufferFormat(1, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(4, -2)]] == BufferFormat(1, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(4, 1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(2, 2)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(5, -1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(3, 3)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(2, 3)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(7, -3)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(5, -2)]] == BufferFormat(2, UInt32)
        @test pipeline.formats[pipeline.stageio2idx[(6, 1)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(7, -2)]] == BufferFormat(4, N0f8)
        @test pipeline.formats[pipeline.stageio2idx[(2, 1)]] == BufferFormat(1, BFT.depth24)
        @test pipeline.formats[pipeline.stageio2idx[(3, 1)]] == BufferFormat(1, BFT.depth24)
        @test pipeline.formats[pipeline.stageio2idx[(7, -1)]] == BufferFormat(1, BFT.depth24)

        # Verify buffer generation with this more complex example
        buffers, remap = generate_buffers(pipeline)

        # Order in buffers irrelevant as long as the mapping works
        # Note: all outputs are unique so we don't have to explicitly test
        #       which one we hit
        # Note: Changes to generate_buffers could change how formats get merged
        #       and cause different correct results
        @test length(buffers) == 5
        @test length(remap) == 7

        @test buffers[remap[pipeline.stageio2idx[(5, 1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(6, -1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(3, 2)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(4, -1)]]] == BufferFormat(4, Float16, minfilter = :linear)
        @test buffers[remap[pipeline.stageio2idx[(3, 4)]]] == BufferFormat(1, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(4, -2)]]] == BufferFormat(1, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(4, 1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(2, 2)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(5, -1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(3, 3)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(2, 3)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(7, -3)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(5, -2)]]] == BufferFormat(2, UInt32)
        @test buffers[remap[pipeline.stageio2idx[(6, 1)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(7, -2)]]] == BufferFormat(4, N0f8)
        @test buffers[remap[pipeline.stageio2idx[(2, 1)]]] == BufferFormat(1, BFT.depth24)
        @test buffers[remap[pipeline.stageio2idx[(3, 1)]]] == BufferFormat(1, BFT.depth24)
        @test buffers[remap[pipeline.stageio2idx[(7, -1)]]] == BufferFormat(1, BFT.depth24)

        check_lowered_representation(pipeline, buffers, remap)
    end
end
