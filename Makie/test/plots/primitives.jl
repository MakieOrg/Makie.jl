@testset "ablines" begin
    # Test ablines with 0 dim arrays
    f, ax, pl = ablines(fill(0), fill(1))
    reset_limits!(ax)
    points = pl.plots[1][1]
    @test Point2f.(points[]) == [Point2f(0), Point2f(10)]
    limits!(ax, 5, 15, 6, 17)
    @test Point2f.(points[]) == [Point2f(5), Point2f(15)]
end

@testset "voxels" begin
    data = reshape(collect(range(0.3, 1.8, length = 6 * 5 * 4)), 6, 5, 4)
    f, a, p = voxels(
        data,
        lowclip = RGBf(1, 0, 1), highclip = RGBf(0, 1, 0),
        colormap = [RGBf(0, 0, 0), RGBf(1, 1, 1)], gap = 0.1
    )

    # data conversion pipeline
    @test p.args[][end] === data
    @test p.converted[][1] == (-3.0, 3.0)
    @test p.converted[][2] == (-2.5, 2.5)
    @test p.converted[][3] == (-2.0, 2.0)

    @test p.colorrange[] == Makie.automatic # otherwise no auto _limits
    @test all(p.value_limits[] .≈ (0.3, 1.8)) # controls conversion to voxel ids
    ids = map(data) do val
        trunc(UInt8, clamp(2 + 253 * (val - 0.3) / (1.8 - 0.3), 2, 254))
    end
    @test p.chunk_u8[] == ids

    # colormap
    @test length(p.voxel_colormap[]) == 255
    @test p.voxel_colormap[][1] == RGBAf(1, 0, 1, 1)
    @test p.voxel_colormap[][2] == RGBAf(0, 0, 0, 1)
    @test p.voxel_colormap[][2:(end - 1)] == resample_cmap([RGBAf(0, 0, 0, 1), RGBAf(1, 1, 1, 1)], 253)
    @test p.voxel_colormap[][end - 1] == RGBAf(1, 1, 1, 1)
    @test p.voxel_colormap[][end] == RGBAf(0, 1, 0, 1)

    # voxels-as-meshscatter helpers
    @test Makie.voxel_size(p) ≈ Vec3f(0.9)
    ps = [Point3f(x - 2.5, y - 2.0, z - 1.5) for z in 0:3 for y in 0:4 for x in 0:5]
    @test Makie.voxel_positions(p) ≈ ps
    @test Makie.voxel_colors(p) == p.voxel_colormap[][p.chunk_u8[][:]]

    # raw UInt8 input updates, issue #4912
    data = Observable(zeros(UInt8, 4, 5, 6))
    f, a, p = voxels(data)
    @test p.converted[][1] == Vec2f(-2, 2)
    @test p.converted[][2] == Vec2f(-2.5, 2.5)
    @test p.converted[][3] == Vec2f(-3, 3)
    @test p.converted[][4] == p.args[][end]
    data[] = ones(UInt8, 4, 5, 6)
    @test p.args[][end] == data[]
    @test p.converted[][end] == data[]
end

@testset "barplot errors for three args" begin
    @test_throws ErrorException barplot(1:10, 1:10, 1:10)
end

# https://github.com/MakieOrg/Makie.jl/issues/3551
@testset "scalar color for scatterlines" begin
    colorrange = (1, 5)
    colormap = :Blues
    f, ax, sl = scatterlines(1:10, 1:10, color = 3, colormap = colormap, colorrange = colorrange)
    l = sl.plots[1]::Lines
    sc = sl.plots[2]::Scatter
    @test l.color[] == 3
    @test l.colorrange[] == Vec2f(colorrange)
    @test l.colormap[] == colormap
    @test sc.color[] == 3
    @test sc.colorrange[] == Vec2f(colorrange)
    @test sc.colormap[] == colormap
    sl.markercolor = 4
    sl.markercolormap = :jet
    sl.markercolorrange = (2, 7)
    @test l.color[] == 3
    @test l.colorrange[] == Vec2f(colorrange)
    @test l.colormap[] == colormap
    @test sc.color[] == 4
    @test sc.colorrange[] == Vec2f(2, 7)
    @test sc.colormap[] == :jet
end

@testset "adaptive colorrange one end" begin
    colorrange = (30, Makie.automatic)
    f, ax, sl = heatmap(reshape(1:100, 10, 10), colorrange = colorrange)
    @test sl.scaled_colorrange[] == Vec2f(30, 100)
    f, ax, sl = heatmap(reshape(1:100, 10, 10), colorrange = (Makie.automatic, 30))
    @test sl.scaled_colorrange[] == Vec2f(1, 30)
    f, ax, sl = heatmap(reshape(1:100, 10, 10), colorrange = (Makie.automatic, Makie.automatic))
    @test sl.scaled_colorrange[] == Vec2f(1, 100)
end

@recipe MaybeDict (data,) begin
    arg = nothing
end
function Makie.plot!(p::MaybeDict)
    return scatter!(p, p[:data])
end
@testset "Pass dict to recipe" begin
    @test_nowarn maybedict(rand(3); arg = Dict(1 => "a", 2 => "b")) # conversion error
end

@testset "heatmap transformation" begin
    # See #5385
    f, a, p = heatmap(
        1.0e6 .. 1.0e6 + 1, 1.0e6 .. 1.0e6 + 1, rand(10, 10),
        axis = (xscale = log10, yscale = log10)
    )
    Makie.add_computation!(p.attributes, a.scene, Val(:heatmap_transform))
    @test !any(isnan, p.x_transformed_f32c[])
    @test !any(isnan, p.y_transformed_f32c[])
end

@testset "Scatter" begin
    @testset "marker updates" begin
        img = fill(RGBf(1, 0, 0), 4, 4)
        f, a, p = scatter(rand(Point2f, 10), marker = img)
        Makie.all_marker_computations!(p.attributes)
        @test p.image[] == img
        img = fill(RGBf(0, 1, 0), 2, 2)
        p.marker = img
        @test p.image[] == img

        imgs = [fill(RGBf(1, 0, 0), 4, 4), fill(RGBf(1, 0, 0), 4, 4)]
        f, a, p = scatter(rand(Point2f, 2), marker = imgs)
        Makie.all_marker_computations!(p.attributes)
        @test p.image[] == imgs
        img = [fill(RGBf(0, 1, 0), 2, 2), fill(RGBf(0, 1, 0), 2, 2)]
        p.marker = imgs
        @test p.image[] == imgs

        # Should be consistent since we always add a-z to the texture atlas?
        f, a, p = scatter(rand(Point2f, 2), marker = 'a')
        Makie.all_marker_computations!(p.attributes)
        @test p.sdf_uv[] == Vec4f(0.02758789, 0.8718262, 0.05444336, 0.90063477)
        p.marker = 'b'
        @test p.sdf_uv[] == Vec4f(0.02758789, 0.90112305, 0.053955078, 0.935791)
    end
end

@testset "annotation" begin
    @testset "updates" begin
        f, a, p = annotation(Point2f.(1:10), text = string.(1:10), shrink = (0, 0))
        update!(p, arg1 = Point2f.(1:20), text = string.(1:20))
        boundingbox(p.plots[1]) # shouldn't error
        @test length(p.plots[2].plots) == 20

        update!(p, arg1 = Point2f.(1:5), text = string.(1:5))
        boundingbox(p.plots[1]) # shouldn't error
        @test length(p.plots[2].plots) == 5

        f, a, p = annotation(fill(Vec2f(10), 10), Point2f.(1:10), text = string.(1:10), shrink = (0, 0))
        update!(p, arg1 = fill(Vec2f(10), 20), arg2 = Point2f.(1:20), text = string.(1:20))
        boundingbox(p.plots[1]) # shouldn't error
        @test length(p.plots[2].plots) == 20

        update!(p, arg1 = fill(Vec2f(10), 5), arg2 = Point2f.(1:5), text = string.(1:5))
        boundingbox(p.plots[1]) # shouldn't error
        @test length(p.plots[2].plots) == 5
    end

    @testset "candidate placement layout" begin
        targets = [Point2f(mod(137i, 500), mod(89i, 400)) for i in 1:40]
        text_bbs = [Rect2d(-30, -8, 60, 16) + t for t in targets]
        viewport = Rect2d(0, 0, 500, 400)
        offsets = zeros(Vec2f, 40)
        algorithm = Makie.CandidatePlacement()
        Makie.place_labels!(algorithm, offsets, targets, text_bbs, viewport, fill(Vec2d(NaN), 40); maxiter = Makie.automatic, reset = true)

        boxes = [Makie.pad_rect(bb + o, algorithm.padding) for (bb, o) in zip(text_bbs, offsets)]
        @test all(box -> box in viewport, boxes)
        @test all(iszero(Makie.overlap_area(boxes[i], boxes[j])) for i in 1:40 for j in (i + 1):40)
        @test all(Makie.rect_point_distance(boxes[i], targets[j]) >= algorithm.pointradius for i in 1:40 for j in 1:40 if i != j)

        offsets_again = zeros(Vec2f, 40)
        Makie.place_labels!(algorithm, offsets_again, targets, text_bbs, viewport, fill(Vec2d(NaN), 40); maxiter = Makie.automatic, reset = true)
        @test offsets_again == offsets

        panned = targets .+ Ref(Point2f(3, -2))
        panned_bbs = text_bbs .+ Ref(Vec2f(3, -2))
        warm = copy(offsets)
        Makie.place_labels!(algorithm, warm, panned, panned_bbs, viewport + Vec2d(3, -2), fill(Vec2d(NaN), 40); maxiter = Makie.automatic, reset = false)
        @test all(isapprox.(warm, offsets; atol = 1.0e-6))
    end

    @testset "empty labels stay put as obstacles" begin
        targets = [Point2f(mod(137i, 500), mod(89i, 400)) for i in 1:40]
        text_bbs = [i % 4 == 0 ? Rect2d(-30, -8, 60, 16) + t : Rect2d(t, Vec2d(0, 0)) for (i, t) in enumerate(targets)]
        offsets = zeros(Vec2f, 40)
        algorithm = Makie.CandidatePlacement()
        Makie.place_labels!(algorithm, offsets, targets, text_bbs, Rect2d(0, 0, 500, 400), fill(Vec2d(NaN), 40); maxiter = Makie.automatic, reset = true)

        @test all(i -> i % 4 == 0 || iszero(offsets[i]), 1:40)
        boxes = Dict(i => Makie.pad_rect(text_bbs[i] + offsets[i], algorithm.padding) for i in 4:4:40)
        @test all(Makie.rect_point_distance(boxes[i], targets[j]) >= algorithm.pointradius for i in 4:4:40 for j in 1:40 if i != j)
    end

    @testset "partially fixed labels" begin
        ps = Point2f.(1:10, 1:10)
        given = fill(Vec2f(NaN), 10)
        given[3] = Vec2f(80, -40)
        for algorithm in (Makie.CandidatePlacement(), Makie.CandidatePlacement(seed = 1, restarts = 0))
            f, a, p = annotation(given, ps, text = string.(1:10); algorithm)
            Makie.update_state_before_display!(f)
            @test p.offsets[][3] == Vec2f(80, -40)
            @test all(i -> i == 3 || !iszero(p.offsets[][i]), 1:10)

            f, a, p = annotation(given, ps, text = string.(1:10); algorithm, maxiter = 0)
            Makie.update_state_before_display!(f)
            @test p.offsets[][3] == Vec2f(80, -40)
            @test all(i -> i == 3 || iszero(p.offsets[][i]), 1:10)
        end

        positions = fill(Point2f(NaN), 10)
        positions[3] = Point2f(6, 2)
        f, a, p = annotation(positions, ps, text = string.(1:10), labelspace = :data)
        Makie.update_state_before_display!(f)
        target, label = Makie.shift_project.(Ref(a.scene), [Point2f(3, 3), Point2f(6, 2)])
        @test p.offsets[][3] ≈ Vec2f(label - target)
        @test all(i -> i == 3 || !iszero(p.offsets[][i]), 1:10)

        targets = [Point2f(mod(137i, 500), mod(89i, 400)) for i in 1:40]
        text_bbs = [Rect2d(-30, -8, 60, 16) + t for t in targets]
        fixed = fill(Vec2d(NaN), 40)
        fixed[1] = Vec2d(120, 90)
        offsets = zeros(Vec2f, 40)
        algorithm = Makie.CandidatePlacement()
        Makie.place_labels!(algorithm, offsets, targets, text_bbs, Rect2d(0, 0, 500, 400), fixed; maxiter = Makie.automatic, reset = true)
        @test offsets[1] == Vec2f(120, 90)
        fixed_box = Makie.pad_rect(text_bbs[1] + offsets[1], algorithm.padding)
        @test all(iszero(Makie.overlap_area(Makie.pad_rect(text_bbs[i] + offsets[i], algorithm.padding), fixed_box)) for i in 2:40)
    end

    @testset "leader suppression" begin
        f, a, p = annotation([Vec2f(0, 0)], [Point2f(1, 1)], text = "hello", shrink = (0, 0), align = (:center, :center))
        Makie.update_state_before_display!(f)
        @test isempty(p.plotspecs[])

        f, a, p = annotation([Vec2f(0, 0)], [Point2f(1, 1)], text = "", shrink = (0, 0), style = Ann.Styles.LineArrow())
        Makie.update_state_before_display!(f)
        @test isempty(p.plotspecs[])

        f, a, p = annotation([Vec2f(30, 0)], [Point2f(1, 1)], text = "hello", align = (:left, :center))
        Makie.update_state_before_display!(f)
        @test length(p.plotspecs[]) == 1

        f, a, p = annotation([Vec2f(3, 0)], [Point2f(1, 1)], text = "hello", align = (:left, :center))
        Makie.update_state_before_display!(f)
        @test isempty(p.plotspecs[])
    end

    @testset "placement geometry" begin
        rect = Rect2d(0, 0, 10, 4)
        @test Makie.halfextent_along(rect, normalize(Vec2d(1, 1))) ≈ 2 * sqrt(2)
        @test Makie.leader_start_point(rect, Point2d(20, 2)) == Point2d(10, 2)
        @test Makie.leader_start_point(rect, Point2d(3, 30)) == Point2d(3, 4)
        @test Makie.leader_start_point(rect, Point2d(18, 2 + 10 * sqrt(3))) ≈ Point2d(9, 2 + sqrt(3))
        @test Makie.leader_start_point(rect, Point2d(5, 2)) == Point2d(5, 2)

        @test Makie.rect_point_distance(rect, Point2d(13, 8)) == 5
        @test Makie.rect_point_distance(rect, Point2d(5, 2)) == 0
        @test Makie.segment_point_distance(Point2d(0, 0), Point2d(10, 0), Point2d(5, 3)) == 3
        @test Makie.segment_point_distance(Point2d(0, 0), Point2d(10, 0), Point2d(14, 3)) == 5

        @test Makie.segments_cross(Point2d(0, 0), Point2d(2, 2), Point2d(0, 2), Point2d(2, 0))
        @test !Makie.segments_cross(Point2d(0, 0), Point2d(2, 2), Point2d(3, 0), Point2d(3, 5))
        @test Makie.segment_intersects_rect(Point2d(-5, 2), Point2d(15, 2), rect)
        @test Makie.segment_intersects_rect(Point2d(5, 2), Point2d(15, 20), rect)
        @test !Makie.segment_intersects_rect(Point2d(-5, 5), Point2d(15, 5), rect)
        @test !Makie.rects_disjoint(rect, Rect2d(5, 2, 10, 10))
        @test Makie.rects_disjoint(rect, Rect2d(11, 0, 10, 10))
        @test Makie.LabelCandidate(Vec2d(0, 0), rect, Point2d(-5, 20), Point2d(0, 2), 0.0).extent == Rect2d(-5, 0, 15, 20)
        @test Makie.overlap_area(rect, Rect2d(5, 2, 10, 10)) == 10
        @test Makie.pad_rect(rect, Vec2d(1, 2)) == Rect2d(-1, -2, 12, 8)
    end
end
